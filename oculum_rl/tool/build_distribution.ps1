param(
  [ValidateSet('Windows', 'Android', 'Web', 'All')]
  [string]$Target = 'All',
  [string]$FlutterRoot = 'C:\Users\michy\flutter',
  [string]$Distribution = (Join-Path (Split-Path -Parent $PSScriptRoot) 'build/distribution'),
  [string]$Stage
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$versionLine = Select-String -LiteralPath (Join-Path $project 'pubspec.yaml') -Pattern '^version:\s+(\d+\.\d+\.\d+)\+\d+$'
if (!$versionLine) { throw 'Missing release version in pubspec.yaml.' }
$version = $versionLine.Matches[0].Groups[1].Value
$dart = Join-Path $FlutterRoot 'bin/cache/dart-sdk/bin/dart.exe'
$tool = Join-Path $FlutterRoot 'bin/cache/flutter_tools.snapshot'
$packages = Join-Path $FlutterRoot 'packages/flutter_tools/.dart_tool/package_config.json'
$env:FLUTTER_ROOT = $FlutterRoot
$env:FLUTTER_ALREADY_LOCKED = 'true'
Set-Location -LiteralPath $project
if (!$Stage) {
  $Stage = Join-Path $Distribution (Get-Date -Format 'yyyyMMdd-HHmmss')
}
$root = [IO.Path]::GetFullPath($Distribution)
$stagePath = [IO.Path]::GetFullPath($Stage)
if ([IO.Path]::GetDirectoryName($stagePath) -ne $root) {
  throw "Use a version directory directly inside $root."
}
if (Test-Path -LiteralPath $root) {
  if ((Get-Item -LiteralPath $root -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
    throw "Distribution must be a normal directory: $root"
  }
}
New-Item -ItemType Directory -Path $stagePath -Force | Out-Null
if ((Get-Item -LiteralPath $stagePath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
  throw "Stage must be a normal directory: $stagePath"
}
. (Join-Path $PSScriptRoot 'build_process.ps1')
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Build([string]$Label, [string[]]$Options) {
  $argsForTool = @("--packages=$packages", $tool, '--no-version-check', '--suppress-analytics') +
    $Options + @("--dart-define=OculumRlVersion=$version")
  $environment = @{FLUTTER_ROOT=$FlutterRoot; FLUTTER_ALREADY_LOCKED='true'}
  Invoke-OculumBuildProcess -FilePath $dart -Arguments $argsForTool -WorkingDirectory $project -LogPath (Join-Path $stagePath "build-$Label.log") -Description $Label -TimeoutSeconds 2700 -Environment $environment
}

function ExportEdition([string]$Folder, [string]$Executable, [string]$Archive) {
  $runtime = Join-Path $stagePath $Folder
  if (Test-Path -LiteralPath $runtime) { throw "Runtime already exists: $runtime" }
  New-Item -ItemType Directory -Path $runtime | Out-Null
  $release = Join-Path $project 'build/windows/x64/runner/Release'
  Get-ChildItem -LiteralPath $release | Copy-Item -Destination $runtime -Recurse
  Rename-Item -LiteralPath (Join-Path $runtime 'oculum_rl.exe') -NewName $Executable
  foreach ($runtimeDll in @('vcruntime140.dll','vcruntime140_1.dll','msvcp140.dll','concrt140.dll')) {
    $fromSystem = Join-Path $env:WINDIR "System32/$runtimeDll"
    $toRuntime = Join-Path $runtime $runtimeDll
    if (!(Test-Path -LiteralPath $toRuntime) -and (Test-Path -LiteralPath $fromSystem)) {
      Copy-Item -LiteralPath $fromSystem -Destination $toRuntime
    }
  }
  foreach ($file in @($Executable,'flutter_windows.dll','audioplayers_windows_plugin.dll',
      'data/icudtl.dat','data/app.so','data/flutter_assets/assets/oculum/lite/clonatore-armi.png',
      'data/flutter_assets/assets/oculum/lite/clonatrice-armi.png',
      'data/flutter_assets/assets/oculum/lite/clonatrice-volti.png',
      'data/flutter_assets/assets/oculum/lite/ashley-sprite.png',
      'data/flutter_assets/assets/oculum/lite/arene-inchiostro.png',
      'data/flutter_assets/assets/oculum/lite/oggetti-inchiostro.png',
      'data/flutter_assets/assets/oculum/lite/curatore-e-combattenti.png',
      'data/flutter_assets/assets/oculum/lite/lunari-e-forme.png',
      'data/flutter_assets/assets/oculum/lite/arena-deserto.jpg',
      'data/flutter_assets/assets/oculum/lite/bottino-ink.png',
      'data/flutter_assets/assets/oculum/lite/sala-npc.png',
      'data/flutter_assets/assets/oculum/lite/sala-riposo.jpg',
      'data/flutter_assets/assets/oculum/lite/arma-chakram.png',
      'data/flutter_assets/assets/oculum/lite/fauna-ink.png',
      'data/flutter_assets/assets/oculum/lite/pollo-meccanico-ink.png',
      'data/flutter_assets/assets/oculum/lite/pollo-meccanico-cremisi.png',
      'data/flutter_assets/assets/oculum/lite/pollo-meccanico-patina.png',
      'data/flutter_assets/assets/oculum/lite/solari-ink.png',
      'data/flutter_assets/assets/oculum/lite/dungeon-solare.jpg',
      'data/flutter_assets/assets/oculum/lite/infernali-ink.png',
      'data/flutter_assets/assets/oculum/lite/inferno.jpg',
      'data/flutter_assets/assets/oculum/lite/realm-caramella.jpg',
      'data/flutter_assets/assets/oculum/lite/arena-orea.jpg',
      'data/flutter_assets/assets/oculum/lite/act-three-ink.webp',
      'data/flutter_assets/assets/oculum/lite/act-three-encounters.webp')) {
    if (!(Test-Path -LiteralPath (Join-Path $runtime $file) -PathType Leaf)) {
      throw "Required runtime file is missing: $Folder/$file"
    }
  }
  $zip = Join-Path $stagePath $Archive
  [IO.Compression.ZipFile]::CreateFromDirectory($runtime, $zip, [IO.Compression.CompressionLevel]::Fastest, $false)
  $reader = [IO.Compression.ZipFile]::OpenRead($zip)
  try {
    foreach ($file in (Get-ChildItem -LiteralPath $runtime -Recurse -File)) {
      $relative = [IO.Path]::GetRelativePath($runtime, $file.FullName).Replace('\','/')
      $item = $reader.GetEntry($relative)
      if ($null -eq $item -or $item.Length -ne $file.Length) { throw "Invalid ZIP member: $relative" }
      $stream = $item.Open()
      try {
        $hash = (Get-FileHash -InputStream $stream -Algorithm SHA256).Hash
      } finally { $stream.Dispose() }
      if ($hash -ne (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash) {
        throw "ZIP content differs: $relative"
      }
    }
  } finally { $reader.Dispose() }
}

switch ($Target) {
  { $_ -in 'All','Windows' } {
    Build 'windows' @('build','windows','--release','--no-pub')
    ExportEdition 'Windows' 'Oculum RL.exe' 'Oculum-RL-Windows.zip'
    Build 'windows-test' @('build','windows','--release','--no-pub','--dart-define=OculumSaveProfile=test')
    ExportEdition 'Windows Test' 'Oculum RL Test.exe' 'Oculum-RL-Windows-Test.zip'
    if ((Get-FileHash -LiteralPath (Join-Path $stagePath 'Windows/data/app.so')).Hash -eq
        (Get-FileHash -LiteralPath (Join-Path $stagePath 'Windows Test/data/app.so')).Hash) {
      throw 'Both releases use the same save profile.'
    }
  }
  { $_ -in 'All','Android' } {
    Build 'android' @('build','apk','--debug','--no-pub')
    $source = Join-Path $project 'build/app/outputs/flutter-apk/app-debug.apk'
    Copy-Item -LiteralPath $source -Destination (Join-Path $stagePath 'Oculum-RL-Android-debug.apk')
  }
  { $_ -in 'All','Web' } {
    Build 'web' @('build','web','--release','--no-pub')
    Copy-Item -LiteralPath (Join-Path $project 'build/web') -Destination (Join-Path $stagePath 'Web') -Recurse
  }
}
Write-Output $stagePath
