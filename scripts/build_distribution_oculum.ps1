param(
  [switch]$FullList,
  [switch]$ForceCloseRunningDistribution,
  [ValidateSet("Auto", "GitHub", "Downloads", "None")]
  [string]$AppleArtifactsSource = "Auto",
  [string]$GitHubRepo = "Mich369/oculum",
  [string]$GitHubBranch = "",
  [string]$GitHubCommit = "",
  [switch]$WaitForGitHubAppleArtifacts,
  [int]$GitHubArtifactTimeoutMinutes = 45
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step {
  param([Parameter(Mandatory = $true)][string]$Message)
  Write-Host ""
  Write-Host "=== $Message ===" -ForegroundColor Cyan
}

function Invoke-CheckedCommand {
  param(
    [Parameter(Mandatory = $true)][string]$Description,
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
  )

  Write-Step $Description
  & $FilePath @Arguments
  $exitCode = if ($null -eq $global:LASTEXITCODE) { 0 } else { $global:LASTEXITCODE }
  if ($exitCode -ne 0) {
    throw "$Description fallito con exit code $exitCode."
  }
}

function Reset-Directory {
  param([Parameter(Mandatory = $true)][string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) {
    throw "Percorso vuoto: reset directory annullato."
  }

  if (Test-Path -LiteralPath $Path) {
    Get-ChildItem -LiteralPath $Path -Force | Remove-Item -Recurse -Force
  } else {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Assert-DistributionPath {
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$Distribution
  )

  $expected = [System.IO.Path]::GetFullPath((Join-Path $Root "build\distribution")).TrimEnd('\')
  $actual = [System.IO.Path]::GetFullPath($Distribution).TrimEnd('\')
  if (-not [string]::Equals($actual, $expected, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Distribution non sicura: attesa $expected, ricevuta $actual."
  }
}

function Assert-DistributionNotRunning {
  param(
    [Parameter(Mandatory = $true)][string]$WindowsDistribution,
    [switch]$ForceClose
  )

  $normalizedPath = [System.IO.Path]::GetFullPath($WindowsDistribution).TrimEnd('\\')
  $runningDistribution = Get-Process -Name "oculum" -ErrorAction SilentlyContinue |
    Where-Object {
      $processPath = $_.Path
      $null -ne $processPath -and
        $processPath.StartsWith($normalizedPath, [System.StringComparison]::OrdinalIgnoreCase)
    }

  if ($null -ne $runningDistribution) {
    $processIds = ($runningDistribution | ForEach-Object { $_.Id }) -join ', '
    if ($ForceClose) {
      Write-Host "Chiudo Oculum dalla distribution (PID: $processIds)." -ForegroundColor Yellow
      $runningDistribution | Stop-Process -Force
      Start-Sleep -Milliseconds 600
      return
    }
    throw "Oculum e in esecuzione dalla distribution (PID: $processIds). Chiudi build\\distribution\\windows\\oculum.exe e rilancia lo script: i file non vengono toccati."
  }
}

function Copy-DirectoryContents {
  param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination
  )

  if (-not (Test-Path -LiteralPath $Source)) {
    throw "Cartella sorgente non trovata: $Source"
  }
  New-Item -ItemType Directory -Path $Destination -Force | Out-Null
  Get-ChildItem -LiteralPath $Source -Force |
    Copy-Item -Destination $Destination -Recurse -Force
}

function Invoke-CheckedCommandInDirectory {
  param(
    [Parameter(Mandatory = $true)][string]$WorkingDirectory,
    [Parameter(Mandatory = $true)][string]$Description,
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
  )

  Push-Location -LiteralPath $WorkingDirectory
  try {
    Invoke-CheckedCommand $Description $FilePath @Arguments
  } finally {
    Pop-Location
  }
}

function New-WindowsEditionZip {
  param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination,
    [Parameter(Mandatory = $true)][string]$Edition,
    [Parameter(Mandatory = $true)][string[]]$DisabledFeatures
  )

  $EditionDir = Join-Path $Dist "windows-$Edition"
  Reset-Directory -Path $EditionDir
  Copy-DirectoryContents -Source $Source -Destination $EditionDir

  $manifest = [ordered]@{
    edition = $Edition
    generatedAt = (Get-Date).ToString("o")
    disabledFeatures = $DisabledFeatures
  } | ConvertTo-Json -Depth 4
  Set-Content -LiteralPath (Join-Path $EditionDir "oculum_edition.json") -Value $manifest -Encoding UTF8

  Compress-Archive -Path (Join-Path $EditionDir "*") -DestinationPath $Destination -Force
  if (-not (Test-Path -LiteralPath $Destination)) {
    throw "Zip $Edition non creato: $Destination"
  }
}

function Find-DownloadedArtifact {
  param(
    [Parameter(Mandatory = $true)][string]$Downloads,
    [Parameter(Mandatory = $true)][string]$FileName
  )

  if (-not (Test-Path -LiteralPath $Downloads)) {
    return $null
  }

  $direct = Join-Path $Downloads $FileName
  if (Test-Path -LiteralPath $direct) {
    return Get-Item -LiteralPath $direct
  }

  return Get-ChildItem -LiteralPath $Downloads -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -eq $FileName } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

function Ensure-LocalNuGet {
  param([Parameter(Mandatory = $true)][string]$Root)

  if (Get-Command nuget -ErrorAction SilentlyContinue) {
    return
  }

  $ToolsDir = Join-Path $Root "build\tools\nuget"
  $NuGetExe = Join-Path $ToolsDir "nuget.exe"
  if (-not (Test-Path -LiteralPath $NuGetExe)) {
    Write-Step "Scarica NuGet locale per build Windows"
    New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
    Invoke-WebRequest `
      -Uri "https://dist.nuget.org/win-x86-commandline/v5.10.0/nuget.exe" `
      -OutFile $NuGetExe
  }

  $env:PATH = "$ToolsDir;$env:PATH"
}

function Format-FileSize {
  param([Parameter(Mandatory = $true)][long]$Bytes)

  if ($Bytes -ge 1GB) {
    return "{0:N2} GB" -f ($Bytes / 1GB)
  }
  if ($Bytes -ge 1MB) {
    return "{0:N1} MB" -f ($Bytes / 1MB)
  }
  if ($Bytes -ge 1KB) {
    return "{0:N1} KB" -f ($Bytes / 1KB)
  }
  return "$Bytes B"
}

function Add-DistributionArtifact {
  param(
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][string]$Path,
    [switch]$Required
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    if ($Required) {
      throw "Artefatto richiesto non trovato: $Path"
    }
    return
  }

  $item = Get-Item -LiteralPath $Path
  if ($item.PSIsContainer) {
    return
  }

  $script:GeneratedArtifacts.Add([pscustomobject]@{
    Tipo = $Label
    Path = $item.FullName.Replace($Dist, "build\distribution")
    Size = Format-FileSize -Bytes $item.Length
    LastWriteTime = $item.LastWriteTime
  }) | Out-Null
}

function Write-DistributionArtifactSummary {
  if ($script:GeneratedArtifacts.Count -eq 0) {
    Write-Host "Nessun artefatto registrato." -ForegroundColor Yellow
    return
  }

  $script:GeneratedArtifacts |
    Sort-Object Tipo, Path |
    Format-Table -AutoSize
}

function Get-GitText {
  param([Parameter(Mandatory = $true)][string[]]$Arguments)

  try {
    $output = & git @Arguments 2>$null
    $exitCode = if ($null -eq $global:LASTEXITCODE) { 0 } else { $global:LASTEXITCODE }
    if ($exitCode -ne 0) {
      return ""
    }
    return ($output | Select-Object -First 1).ToString().Trim()
  } catch {
    return ""
  }
}

function Import-GitHubAppleArtifacts {
  param(
    [Parameter(Mandatory = $true)][string]$SyncScript,
    [Parameter(Mandatory = $true)][string]$Repo,
    [Parameter(Mandatory = $true)][string]$Branch,
    [Parameter(Mandatory = $true)][string]$Commit,
    [Parameter(Mandatory = $true)][int]$TimeoutMinutes,
    [Parameter(Mandatory = $true)][bool]$WaitForArtifacts
  )

  if (-not (Test-Path -LiteralPath $SyncScript)) {
    throw "Script sync GitHub non trovato: $SyncScript"
  }

  & $SyncScript `
    -Repo $Repo `
    -Branch $Branch `
    -Commit $Commit `
    -OutputDir $Dist `
    -TimeoutMinutes $TimeoutMinutes `
    -Wait:$WaitForArtifacts
  $exitCode = if ($null -eq $global:LASTEXITCODE) { 0 } else { $global:LASTEXITCODE }
  if ($exitCode -ne 0) {
    throw "Download artefatti Apple da GitHub fallito con exit code $exitCode."
  }

  $macPath = Join-Path $Dist "Oculum-macOS.zip"
  $iosPath = Join-Path $Dist "Oculum-iOS-unsigned.ipa"
  $macOk = Test-Path -LiteralPath $macPath
  $iosOk = Test-Path -LiteralPath $iosPath
  if ($macOk) {
    Add-DistributionArtifact -Label "macOS zip GitHub" -Path $macPath
  }
  if ($iosOk) {
    Add-DistributionArtifact -Label "iOS ipa GitHub" -Path $iosPath
  }

  return ($macOk -and $iosOk)
}

function Import-DownloadedAppleArtifact {
  param(
    [Parameter(Mandatory = $true)][string]$Downloads,
    [Parameter(Mandatory = $true)][string]$FileName,
    [Parameter(Mandatory = $true)][string]$Subdir,
    [Parameter(Mandatory = $true)][string]$Label
  )

  $artifact = Find-DownloadedArtifact -Downloads $Downloads -FileName $FileName
  if ($null -eq $artifact) {
    Write-Host "Artifact non trovato in Download: $FileName" -ForegroundColor Yellow
    return $false
  }

  $rootTarget = Join-Path $Dist $FileName
  $subTargetDir = Join-Path $Dist $Subdir
  New-Item -ItemType Directory -Path $subTargetDir -Force | Out-Null
  Copy-Item -LiteralPath $artifact.FullName -Destination $rootTarget -Force
  Copy-Item -LiteralPath $artifact.FullName -Destination (Join-Path $subTargetDir $FileName) -Force
  Add-DistributionArtifact -Label $Label -Path $rootTarget
  Write-Host "Copiato artifact da Download: $($artifact.FullName)" -ForegroundColor Green
  return $true
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = (Resolve-Path -LiteralPath (Join-Path $ScriptDir "..")).Path
$Dist = Join-Path $Root "build\distribution"
$WinDist = Join-Path $Dist "windows"
$AndroidDist = Join-Path $Dist "android"
$WebDist = Join-Path $Dist "web"
$MacDist = Join-Path $Dist "macos"
$IosDist = Join-Path $Dist "ios"
$BattleRoot = Join-Path $Root "oculum_battle"
$BattleDist = Join-Path $Dist "oculum_battle"
$BattleWinDist = Join-Path $BattleDist "windows"
$BattleAndroidDist = Join-Path $BattleDist "android"
$script:GeneratedArtifacts = New-Object System.Collections.Generic.List[object]

Write-Host "=== OCULUM DISTRIBUTION BUILDER ===" -ForegroundColor Cyan
Write-Host "Project root: $Root"
Write-Host "Distribution: $Dist"

Set-Location -LiteralPath $Root

if (-not (Test-Path -LiteralPath (Join-Path $Root "pubspec.yaml"))) {
  throw "pubspec.yaml non trovato. Avvia lo script dalla root del progetto Flutter o lascia lo script in scripts/."
}

if (-not (Test-Path -LiteralPath (Join-Path $Root "pubspec_overrides.yaml"))) {
  throw "pubspec_overrides.yaml non trovato. Serve per mantenere connectivity_plus 6.1.5 e non rompere macOS."
}

Assert-DistributionNotRunning -WindowsDistribution $WinDist -ForceClose:$ForceCloseRunningDistribution
Assert-DistributionPath -Root $Root -Distribution $Dist
Reset-Directory -Path $Dist
New-Item -ItemType Directory -Path $WinDist, $AndroidDist, $WebDist, $MacDist, $IosDist -Force | Out-Null

Invoke-CheckedCommand "flutter pub get" "flutter" "pub" "get"

Ensure-LocalNuGet -Root $Root
Invoke-CheckedCommand "flutter build windows --release" "flutter" "build" "windows" "--release"

$WinRelease = Join-Path $Root "build\windows\x64\runner\Release"
if (-not (Test-Path -LiteralPath $WinRelease)) {
  throw "Build Windows non trovata: $WinRelease"
}

Write-Step "Copia Windows Release completa"
Copy-DirectoryContents -Source $WinRelease -Destination $WinDist

$ExeSource = Join-Path $WinRelease "oculum.exe"
if (-not (Test-Path -LiteralPath $ExeSource)) {
  $ExeSource = Get-ChildItem -LiteralPath $WinRelease -Filter "*.exe" -File |
    Select-Object -First 1 |
    ForEach-Object { $_.FullName }
}
if ([string]::IsNullOrWhiteSpace($ExeSource) -or -not (Test-Path -LiteralPath $ExeSource)) {
  throw "Nessun .exe trovato nella build Windows: $WinRelease"
}
$DistExe = Join-Path $Dist "Oculum.exe"
Copy-Item -LiteralPath $ExeSource -Destination $DistExe -Force
(Get-Item -LiteralPath $DistExe).LastWriteTime = Get-Date
Add-DistributionArtifact -Label "Windows exe" -Path $DistExe -Required

$WinZip = Join-Path $Dist "Oculum-Windows.zip"
Compress-Archive -Path (Join-Path $WinRelease "*") -DestinationPath $WinZip -Force
if (-not (Test-Path -LiteralPath $WinZip)) {
  throw "Zip Windows non creato: $WinZip"
}
Add-DistributionArtifact -Label "Windows zip" -Path $WinZip -Required

New-WindowsEditionZip `
  -Source $WinRelease `
  -Destination (Join-Path $Dist "Oculum-Demo-Windows.zip") `
  -Edition "demo" `
  -DisabledFeatures @(
    "dungeon",
    "online-realtime",
    "monster-generator",
    "rgb-theme-plus",
    "mods"
  )
Add-DistributionArtifact -Label "Windows demo zip" -Path (Join-Path $Dist "Oculum-Demo-Windows.zip") -Required

New-WindowsEditionZip `
  -Source $WinRelease `
  -Destination (Join-Path $Dist "Oculum-Standard-Windows.zip") `
  -Edition "standard" `
  -DisabledFeatures @(
    "dungeon",
    "rgb-theme-plus",
    "mods"
  )
Add-DistributionArtifact -Label "Windows standard zip" -Path (Join-Path $Dist "Oculum-Standard-Windows.zip") -Required

Invoke-CheckedCommand "flutter build apk --release" "flutter" "build" "apk" "--release"

$ApkSource = Join-Path $Root "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path -LiteralPath $ApkSource)) {
  throw "APK release non trovato: $ApkSource"
}
Copy-Item -LiteralPath $ApkSource -Destination (Join-Path $Dist "Oculum-Android-release.apk") -Force
Copy-Item -LiteralPath $ApkSource -Destination (Join-Path $AndroidDist "Oculum-Android-release.apk") -Force
Add-DistributionArtifact -Label "Android apk" -Path (Join-Path $Dist "Oculum-Android-release.apk") -Required

Invoke-CheckedCommand "flutter build web --release" "flutter" "build" "web" "--release"

$WebRelease = Join-Path $Root "build\web"
if (-not (Test-Path -LiteralPath (Join-Path $WebRelease "index.html"))) {
  throw "Build Web non trovata: $WebRelease"
}
Write-Step "Copia Web Release completa"
Copy-DirectoryContents -Source $WebRelease -Destination $WebDist
$WebZip = Join-Path $Dist "Oculum-Web.zip"
Compress-Archive -Path (Join-Path $WebRelease "*") -DestinationPath $WebZip -Force
if (-not (Test-Path -LiteralPath $WebZip)) {
  throw "Zip Web non creato: $WebZip"
}
Add-DistributionArtifact -Label "Web zip" -Path $WebZip -Required

if (Test-Path -LiteralPath (Join-Path $BattleRoot "pubspec.yaml")) {
  Write-Step "Build Oculum Battle standalone"
  New-Item -ItemType Directory -Path $BattleWinDist, $BattleAndroidDist -Force | Out-Null
  Invoke-CheckedCommandInDirectory $BattleRoot "Oculum Battle flutter pub get" "flutter" "pub" "get"
  Invoke-CheckedCommandInDirectory $BattleRoot "Oculum Battle flutter build windows --release" "flutter" "build" "windows" "--release"

  $BattleWinRelease = Join-Path $BattleRoot "build\windows\x64\runner\Release"
  if (-not (Test-Path -LiteralPath $BattleWinRelease)) {
    throw "Build Windows Oculum Battle non trovata: $BattleWinRelease"
  }
  Copy-DirectoryContents -Source $BattleWinRelease -Destination $BattleWinDist

  $BattleExeSource = Join-Path $BattleWinRelease "oculum_battle.exe"
  if (-not (Test-Path -LiteralPath $BattleExeSource)) {
    $BattleExeSource = Get-ChildItem -LiteralPath $BattleWinRelease -Filter "*.exe" -File |
      Select-Object -First 1 |
      ForEach-Object { $_.FullName }
  }
  if ([string]::IsNullOrWhiteSpace($BattleExeSource) -or -not (Test-Path -LiteralPath $BattleExeSource)) {
    throw "Nessun .exe trovato nella build Windows Oculum Battle: $BattleWinRelease"
  }
  Copy-Item -LiteralPath $BattleExeSource -Destination (Join-Path $Dist "OculumBattle.exe") -Force
  Add-DistributionArtifact -Label "Battle Windows exe" -Path (Join-Path $Dist "OculumBattle.exe") -Required

  $BattleWinZip = Join-Path $Dist "OculumBattle-Windows.zip"
  Compress-Archive -Path (Join-Path $BattleWinRelease "*") -DestinationPath $BattleWinZip -Force
  if (-not (Test-Path -LiteralPath $BattleWinZip)) {
    throw "Zip Windows Oculum Battle non creato: $BattleWinZip"
  }
  Add-DistributionArtifact -Label "Battle Windows zip" -Path $BattleWinZip -Required

  Invoke-CheckedCommandInDirectory $BattleRoot "Oculum Battle flutter build apk --release" "flutter" "build" "apk" "--release"
  $BattleApkSource = Join-Path $BattleRoot "build\app\outputs\flutter-apk\app-release.apk"
  if (-not (Test-Path -LiteralPath $BattleApkSource)) {
    throw "APK Oculum Battle release non trovato: $BattleApkSource"
  }
  Copy-Item -LiteralPath $BattleApkSource -Destination (Join-Path $Dist "OculumBattle-Android-release.apk") -Force
  Copy-Item -LiteralPath $BattleApkSource -Destination (Join-Path $BattleAndroidDist "OculumBattle-Android-release.apk") -Force
  Add-DistributionArtifact -Label "Battle Android apk" -Path (Join-Path $Dist "OculumBattle-Android-release.apk") -Required
} else {
  Write-Host "Oculum Battle standalone non trovato: $BattleRoot" -ForegroundColor Yellow
}

if ($AppleArtifactsSource -ne "None") {
  $appleArtifactsReady = $false
  if ($AppleArtifactsSource -eq "Auto" -or $AppleArtifactsSource -eq "GitHub") {
    Write-Step "Import artifact macOS/iOS da GitHub Actions"
    $resolvedBranch = if ([string]::IsNullOrWhiteSpace($GitHubBranch)) {
      Get-GitText -Arguments @("branch", "--show-current")
    } else {
      $GitHubBranch
    }
    if ([string]::IsNullOrWhiteSpace($resolvedBranch)) {
      $resolvedBranch = "main"
    }

    $resolvedCommit = if ([string]::IsNullOrWhiteSpace($GitHubCommit)) {
      Get-GitText -Arguments @("rev-parse", "HEAD")
    } else {
      $GitHubCommit
    }

    try {
      $appleArtifactsReady = Import-GitHubAppleArtifacts `
        -SyncScript (Join-Path $ScriptDir "sync_github_apple_artifacts.ps1") `
        -Repo $GitHubRepo `
        -Branch $resolvedBranch `
        -Commit $resolvedCommit `
        -TimeoutMinutes $GitHubArtifactTimeoutMinutes `
        -WaitForArtifacts ([bool]$WaitForGitHubAppleArtifacts)
    } catch {
      if ($AppleArtifactsSource -eq "GitHub") {
        throw
      }
      Write-Host "GitHub Actions non disponibile per Apple artifacts: $($_.Exception.Message)" -ForegroundColor Yellow
    }
  }

  if (-not $appleArtifactsReady -and ($AppleArtifactsSource -eq "Auto" -or $AppleArtifactsSource -eq "Downloads")) {
    Write-Step "Fallback artifact macOS/iOS dai Download"
    $Downloads = Join-Path $env:USERPROFILE "Downloads"
    $macImported = Import-DownloadedAppleArtifact `
      -Downloads $Downloads `
      -FileName "Oculum-macOS.zip" `
      -Subdir "macos" `
      -Label "macOS zip Download"
    $iosImported = Import-DownloadedAppleArtifact `
      -Downloads $Downloads `
      -FileName "Oculum-iOS-unsigned.ipa" `
      -Subdir "ios" `
      -Label "iOS ipa Download"

    if (-not ($macImported -and $iosImported)) {
      Write-Host "Apple artifacts non completi. Per build aggiornate usa GitHub Actions o -AppleArtifactsSource GitHub -WaitForGitHubAppleArtifacts." -ForegroundColor Yellow
    }
  }
}

Write-Step "Artefatti verificati"
Write-DistributionArtifactSummary

if ($FullList) {
  Write-Step "File generati in build\distribution"
  Get-ChildItem -LiteralPath $Dist -Force -Recurse |
    Sort-Object FullName |
    Select-Object @{ Name = "Path"; Expression = { $_.FullName.Replace($Dist, "build\distribution") } }, Length, LastWriteTime |
    Format-Table -AutoSize
} else {
  Write-Host ""
  Write-Host "Lista completa omessa per tenere pulito l'output. Usa -FullList per stamparla." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Distribuzione pronta: $Dist" -ForegroundColor Green
Write-Host "Nota: per Windows distribuisci Oculum-Windows.zip, non solo Oculum.exe." -ForegroundColor Yellow
