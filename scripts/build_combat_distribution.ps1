param(
  [switch]$StageOnly,
  [string]$FlutterRoot = 'C:\Users\michy\flutter',
  [ValidateRange(1, 180)][int]$BuildTimeoutMinutes = 45
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$buildRoot = Join-Path $projectRoot 'build'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$staging = Join-Path $buildRoot "distribution-combat-$stamp"
$distribution = Join-Path $buildRoot 'distribution'
$backup = Join-Path $buildRoot "distribution-backup-$stamp"
$dartRuntime = Join-Path $FlutterRoot 'bin/cache/dart-sdk/bin/dart.exe'
$flutterTool = Join-Path $FlutterRoot 'bin/cache/flutter_tools.snapshot'
$flutterPackages = Join-Path $FlutterRoot 'packages/flutter_tools/.dart_tool/package_config.json'
$verifier = Join-Path $PSScriptRoot 'verify_distribution.ps1'
foreach ($requiredTool in @($dartRuntime, $flutterTool, $flutterPackages, $verifier)) {
  if (!(Test-Path -LiteralPath $requiredTool -PathType Leaf)) { throw "Missing build tool: $requiredTool" }
}
. (Join-Path $PSScriptRoot 'build_process.ps1')
Set-Location -LiteralPath $projectRoot
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Assert-BuildFolder([string]$Path) {
  $full = [IO.Path]::GetFullPath($Path)
  if ([IO.Path]::GetDirectoryName($full) -ne $buildRoot) {
    throw "Unsafe build destination: $full"
  }
  if ((Test-Path -LiteralPath $full) -and
      ((Get-Item -LiteralPath $full).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw "Build destination is a link: $full"
  }
}

function Get-SourceFingerprint {
  $paths = @(& git ls-files --cached --others --exclude-standard -- lib assets windows android web pubspec.yaml pubspec.lock pubspec_overrides.yaml)
  if ($LASTEXITCODE -ne 0) { throw 'Cannot enumerate build sources' }
  $records = @($paths | Sort-Object -Unique | ForEach-Object {
    if (Test-Path -LiteralPath $_ -PathType Leaf) {
      "$_ $((Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash)"
    }
  })
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($records -join "`n")))).Replace('-', '') }
  finally { $sha.Dispose() }
}

function Invoke-FlutterBuild([string]$Name, [string[]]$BuildArguments) {
  $log = Join-Path $buildRoot "combat-build-$Name-$stamp.log"
  Write-Output "BUILD $Name -> $log"
  # The SDK and platform artifacts are already installed. Invoke the cached
  # tool directly to avoid flutter.bat's silent bootstrap lock retry and the
  # nested PowerShell/cmd PTY deadlock. Builds run sequentially in this script.
  $arguments = @("--packages=$flutterPackages", $flutterTool, '--no-version-check', '--suppress-analytics') + $BuildArguments
  Invoke-OculumBuildProcess -FilePath $dartRuntime -Arguments $arguments -WorkingDirectory $projectRoot `
    -LogPath $log -Description "Build $Name" -TimeoutSeconds ($BuildTimeoutMinutes * 60) `
    -Environment @{ FLUTTER_ROOT = $FlutterRoot; FLUTTER_ALREADY_LOCKED = 'true' }
  Write-Output "BUILT $Name"
}

function New-CheckedZip([string]$Folder, [string]$Name) {
  $archive = Join-Path $staging $Name
  [IO.Compression.ZipFile]::CreateFromDirectory($Folder, $archive, [IO.Compression.CompressionLevel]::Optimal, $false)
  $zip = [IO.Compression.ZipFile]::OpenRead($archive)
  try {
    $files = @(Get-ChildItem -LiteralPath $Folder -Recurse -File)
    $entries = @{}
    foreach ($entry in $zip.Entries) {
      if (!$entry.Name) { continue }
      $entries[$entry.FullName.Replace('\', '/')] = $entry
    }
    if ($entries.Count -ne $files.Count) { throw "ZIP file count mismatch: $Name" }
    foreach ($file in $files) {
      $relative = $file.FullName.Substring($Folder.Length + 1).Replace('\', '/')
      $entry = $entries[$relative]
      if (!$entry -or $entry.Length -ne $file.Length) { throw "ZIP payload missing: $Name/$relative" }
      $stream = $entry.Open()
      $sha = [Security.Cryptography.SHA256]::Create()
      try { $hash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '') }
      finally { $stream.Dispose(); $sha.Dispose() }
      if ($hash -ne (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash) {
        throw "ZIP hash mismatch: $Name/$relative"
      }
    }
  } finally { $zip.Dispose() }
  Write-Output "VERIFIED ZIP $Name"
}

function Copy-WindowsEdition([string]$Name, [string]$Executable, [string]$Zip) {
  $release = Join-Path $buildRoot 'windows\x64\runner\Release'
  $folder = Join-Path $staging $Name
  New-Item -ItemType Directory -Path $folder | Out-Null
  Get-ChildItem -LiteralPath $release | Copy-Item -Destination $folder -Recurse -Force
  if ($Executable -ne 'oculum.exe') {
    Rename-Item -LiteralPath (Join-Path $folder 'oculum.exe') -NewName $Executable
  }
  foreach ($required in @($Executable, 'flutter_windows.dll', 'WebView2Loader.dll', 'vcruntime140.dll', 'msvcp140.dll', 'data/app.so', 'data/icudtl.dat', 'data/flutter_assets')) {
    if (!(Test-Path -LiteralPath (Join-Path $folder $required))) { throw "Missing runtime: $Name/$required" }
  }
  New-CheckedZip $folder $Zip
}

foreach ($folder in @($staging, $distribution, $backup)) { Assert-BuildFolder $folder }
New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
$buildLock = [IO.File]::Open((Join-Path $buildRoot 'distribution-build.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
try {
New-Item -ItemType Directory -Path $staging | Out-Null
$sourceFingerprint = Get-SourceFingerprint
$baseCommit = (& git rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Cannot read base commit' }
$dirty = @(& git status --porcelain -- lib assets windows android web pubspec.yaml pubspec.lock).Count -gt 0

Invoke-FlutterBuild 'web' @('build', 'web', '--release', '--no-pub', '--base-href', '/Oculum/')
$web = Join-Path $staging 'web'
New-Item -ItemType Directory -Path $web | Out-Null
Get-ChildItem -LiteralPath (Join-Path $buildRoot 'web') | Copy-Item -Destination $web -Recurse -Force
New-CheckedZip $web 'Oculum-Web.zip'

Invoke-FlutterBuild 'windows' @('build', 'windows', '--release', '--no-pub', '--dart-define=OculumSaveProfile=')
Copy-WindowsEdition 'windows' 'oculum.exe' 'Oculum-Windows.zip'
Get-ChildItem -LiteralPath (Join-Path $staging 'windows') | Copy-Item -Destination $staging -Recurse -Force

Invoke-FlutterBuild 'windows-test' @('build', 'windows', '--release', '--no-pub', '--dart-define=OculumSaveProfile=test')
Copy-WindowsEdition 'windows-test' 'Oculum-Test.exe' 'Oculum-Test-Windows.zip'
if ((Get-FileHash -LiteralPath (Join-Path $staging 'windows/data/app.so')).Hash -eq
    (Get-FileHash -LiteralPath (Join-Path $staging 'windows-test/data/app.so')).Hash) {
  throw 'Windows and Windows Test must use different compiled save profiles'
}

Invoke-FlutterBuild 'android' @('build', 'apk', '--release', '--no-pub', '--dart-define=OculumSaveProfile=')
$apkSource = Join-Path $buildRoot 'app\outputs\flutter-apk\app-release.apk'
$apk = Join-Path $staging 'Oculum-Android-release.apk'
Copy-Item -LiteralPath $apkSource -Destination $apk
if ((Get-FileHash -LiteralPath $apkSource).Hash -ne (Get-FileHash -LiteralPath $apk).Hash) { throw 'APK copy mismatch' }
$apkZip = [IO.Compression.ZipFile]::OpenRead($apk)
try {
  foreach ($required in @('AndroidManifest.xml', 'classes.dex', 'lib/arm64-v8a/libapp.so')) {
    if (!$apkZip.GetEntry($required)) { throw "APK missing $required" }
  }
} finally { $apkZip.Dispose() }

# Keep an easy-to-copy edition containing only the unpacked Windows folders.
# This satisfies the separate-folder handoff without mixing ZIP/APK files into it.
$unpacked = Join-Path $staging "Oculum-$stamp"
New-Item -ItemType Directory -Path $unpacked | Out-Null
Copy-Item -LiteralPath (Join-Path $staging 'windows') -Destination (Join-Path $unpacked 'Windows') -Recurse
Copy-Item -LiteralPath (Join-Path $staging 'windows-test') -Destination (Join-Path $unpacked 'Windows Test') -Recurse

if ((Get-SourceFingerprint) -ne $sourceFingerprint) { throw 'Build sources changed during compilation; staged packages not installed' }
foreach ($doc in @('OCULUM_REGOLE_CONFERMATE.md', 'manuale-consultazione.md', 'AGGIORNAMENTI_2026-10-19.md')) {
  Copy-Item -LiteralPath (Join-Path $projectRoot "docs/$doc") -Destination $staging
}
$manifest = [ordered]@{
  commit = $baseCommit
  buildOrigin = 'local'
  sourceDirty = $dirty
  sourceTreeSha256 = $sourceFingerprint
  builtAtUtc = [DateTime]::UtcNow.ToString('o')
  files = @(Get-ChildItem -LiteralPath $staging -Recurse -File | ForEach-Object {
    @{ path = $_.FullName.Substring($staging.Length + 1); bytes = $_.Length; sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
  })
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $staging 'BUILD-VERIFICATE.json') -Encoding utf8
Write-Output "STAGED $staging"
& $verifier -ExpectedCommit $baseCommit -DistributionRoot $staging
if ($StageOnly) { return }
$active = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
  $_.Path -and $_.Path.StartsWith($distribution + '\', [StringComparison]::OrdinalIgnoreCase)
})
if ($active.Count) { throw "Save and close Oculum before replacement. Verified packages remain in $staging" }
foreach ($folder in @($staging, $distribution, $backup)) { Assert-BuildFolder $folder }
if (Test-Path -LiteralPath $distribution) { Move-Item -LiteralPath $distribution -Destination $backup }
try {
  Move-Item -LiteralPath $staging -Destination $distribution
  & $verifier -ExpectedCommit $baseCommit -DistributionRoot $distribution
}
catch {
  if ((Test-Path -LiteralPath $distribution) -and !(Test-Path -LiteralPath $staging)) {
    Move-Item -LiteralPath $distribution -Destination $staging
  }
  if (!(Test-Path -LiteralPath $distribution) -and (Test-Path -LiteralPath $backup)) {
    Move-Item -LiteralPath $backup -Destination $distribution
  }
  throw
}
Write-Output "INSTALLED $distribution; previous release preserved in $backup"
} finally {
  $buildLock.Dispose()
}
