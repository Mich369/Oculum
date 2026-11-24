param(
  [Parameter(Mandatory = $true)][string]$Name,
  [Parameter(Mandatory = $true)][ValidateRange(100299, 2100000000)][int]$AndroidBuildNumber,
  [string]$FlutterRoot = 'C:\Users\michy\flutter'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($Name -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]{0,90}$') { throw 'Invalid candidate name' }
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$buildRoot = Join-Path $projectRoot 'build'
$destination = Join-Path $buildRoot "distribution\$Name"
if (Test-Path -LiteralPath $destination) { throw 'Candidate already exists; previous packages are preserved' }
Set-Location -LiteralPath $projectRoot
. (Join-Path $PSScriptRoot 'build_process.ps1')
$dart = Join-Path $FlutterRoot 'bin\cache\dart-sdk\bin\dart.exe'
$tool = Join-Path $FlutterRoot 'bin\cache\flutter_tools.snapshot'
$packages = Join-Path $FlutterRoot 'packages\flutter_tools\.dart_tool\package_config.json'
$commit = (& git rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $commit -notmatch '^[0-9a-f]{40}$') { throw 'Missing source commit' }
$dirty = @(& git status --porcelain -- lib assets windows android web pubspec.yaml pubspec.lock).Count -gt 0
if ($dirty) { throw 'Commit the application sources before building this candidate' }

function Get-SourceFingerprint {
  $paths = @(& git ls-files --cached --others --exclude-standard -- lib assets windows android web pubspec.yaml pubspec.lock)
  if ($LASTEXITCODE -ne 0) { throw 'Cannot enumerate application sources' }
  if (Test-Path -LiteralPath 'pubspec_overrides.yaml') { $paths += 'pubspec_overrides.yaml' }
  $records = @($paths | Sort-Object -Unique | ForEach-Object {
    if (Test-Path -LiteralPath $_ -PathType Leaf) {
      "$_ $((Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash)"
    }
  })
  $hash = [Security.Cryptography.SHA256]::Create()
  try { return [BitConverter]::ToString($hash.ComputeHash([Text.Encoding]::UTF8.GetBytes(($records -join "`n")))).Replace('-', '') }
  finally { $hash.Dispose() }
}
$fingerprint = Get-SourceFingerprint
New-Item -ItemType Directory -Path $destination | Out-Null
$lock = [IO.File]::Open((Join-Path $buildRoot 'distribution-build.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)

function Assert-UnchangedSource {
  if ((& git rev-parse HEAD).Trim() -ne $commit -or
      @(& git status --porcelain -- lib assets windows android web pubspec.yaml pubspec.lock).Count -ne 0 -or
      (Get-SourceFingerprint) -ne $fingerprint) {
    throw 'Application source changed during build; candidate was not certified'
  }
}

function Build-Edition([string]$Edition, [string[]]$BuildArguments, [hashtable]$ExtraEnvironment = @{}) {
  Assert-UnchangedSource
  $arguments = @("--packages=$packages", $tool, '--no-version-check', '--suppress-analytics') +
    $BuildArguments + @("--dart-define=OculumSourceCommit=$commit", "--dart-define=OculumBuildId=$($fingerprint.ToLowerInvariant())")
  $environment = @{ FLUTTER_ROOT = $FlutterRoot; FLUTTER_ALREADY_LOCKED = 'true' }
  foreach ($key in $ExtraEnvironment.Keys) { $environment[$key] = $ExtraEnvironment[$key] }
  Invoke-OculumBuildProcess -FilePath $dart -Arguments $arguments -WorkingDirectory $projectRoot `
    -LogPath (Join-Path $buildRoot "$Name-$Edition.log") -Description "Build $Edition" `
    -TimeoutSeconds 2700 -Environment $environment
  Assert-UnchangedSource
}

function Copy-Edition([string]$Folder, [string]$Executable) {
  $source = Join-Path $buildRoot 'windows\x64\runner\Release'
  $target = Join-Path $destination $Folder
  New-Item -ItemType Directory -Path $target | Out-Null
  Get-ChildItem -LiteralPath $source | Copy-Item -Destination $target -Recurse
  if ($Executable -ne 'oculum.exe') {
    Rename-Item -LiteralPath (Join-Path $target 'oculum.exe') -NewName $Executable
  }
  foreach ($required in @($Executable, 'flutter_windows.dll', 'WebView2Loader.dll', 'vcruntime140.dll', 'msvcp140.dll', 'data/app.so', 'data/icudtl.dat', 'data/flutter_assets')) {
    if (!(Test-Path -LiteralPath (Join-Path $target $required))) { throw "Incomplete runtime: $Folder/$required" }
  }
}

try {
  Build-Edition 'windows' @('build', 'windows', '--release', '--no-pub', '--dart-define=OculumSaveProfile=')
  Copy-Edition 'windows' 'oculum.exe'
  Build-Edition 'windows-test' @('build', 'windows', '--release', '--no-pub', '--dart-define=OculumSaveProfile=test')
  Copy-Edition 'windows-test' 'Oculum-Test.exe'
  if ((Get-FileHash -LiteralPath (Join-Path $destination 'windows/data/app.so')).Hash -eq
      (Get-FileHash -LiteralPath (Join-Path $destination 'windows-test/data/app.so')).Hash) {
    throw 'Normal and Test editions must use different save profiles'
  }
  # Reuse the existing identity. Gradle and the independent verifier both
  # enforce the pinned certificate; no key or credential file is generated.
  $keyPath = if ($env:OCULUM_ANDROID_KEYSTORE_PATH) { $env:OCULUM_ANDROID_KEYSTORE_PATH }
             else { Join-Path $env:USERPROFILE '.android\debug.keystore' }
  if (!(Test-Path -LiteralPath $keyPath -PathType Leaf)) { throw 'Existing signing key is required' }
  $signingEnvironment = @{
    OCULUM_ANDROID_KEYSTORE_PATH = $keyPath
    OCULUM_ANDROID_STORE_PASSWORD = $(if ($env:OCULUM_ANDROID_STORE_PASSWORD) { $env:OCULUM_ANDROID_STORE_PASSWORD } else { 'android' })
    OCULUM_ANDROID_KEY_PASSWORD = $(if ($env:OCULUM_ANDROID_KEY_PASSWORD) { $env:OCULUM_ANDROID_KEY_PASSWORD } else { 'android' })
    OCULUM_ANDROID_KEY_ALIAS = $(if ($env:OCULUM_ANDROID_KEY_ALIAS) { $env:OCULUM_ANDROID_KEY_ALIAS } else { 'androiddebugkey' })
  }
  Build-Edition 'android-release' @('build', 'apk', '--release', '--no-pub', "--build-number=$AndroidBuildNumber", '--dart-define=OculumSaveProfile=') $signingEnvironment
  $apkSource = Join-Path $buildRoot 'app\outputs\flutter-apk\app-release.apk'
  & python (Join-Path $PSScriptRoot 'verify_android_signing.py') --apk $apkSource --min-version-code $AndroidBuildNumber `
    --java 'C:\Program Files\Android\Android Studio\jbr\bin\java.exe' --report (Join-Path $buildRoot "$Name-ANDROID-SIGNATURE.json")
  if ($LASTEXITCODE -ne 0) { throw 'Release APK signing verification failed' }
  Copy-Item -LiteralPath $apkSource -Destination (Join-Path $destination 'Oculum-Android-release.apk')
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  foreach ($edition in @(@('windows', 'Oculum-Windows.zip'), @('windows-test', 'Oculum-Test-Windows.zip'))) {
    [IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $destination $edition[0]),
      (Join-Path $destination $edition[1]), [IO.Compression.CompressionLevel]::Fastest, $false)
  }
  foreach ($doc in @('OCULUM_REGOLE_CONFERMATE.md', 'manuale-consultazione.md', 'REGISTRO_AGGIORNAMENTI.md', 'ULTIMO_AGGIORNAMENTO.md', 'VERIFICA_ARRETRATI_APP_2026-11-23.md', 'VERIFICA_SCHIVATE_2026-11-24.md')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot "docs\$doc") -Destination $destination
  }
  Assert-UnchangedSource
  $manifest = [ordered]@{
    commit = $commit
    buildOrigin = 'local'
    sourceDirty = $false
    buildId = $fingerprint.ToLowerInvariant()
    sourceTreeSha256 = $fingerprint
    localDependencyOverridesPresent = (Test-Path -LiteralPath 'pubspec_overrides.yaml')
    distributionComplete = $false
    androidArtifact = 'Release APK signed with the pinned stable certificate; signature verified independently'
    androidReleaseVersionCode = $AndroidBuildNumber
    androidReleaseSigningVerified = $true
    localWindowsAndroidComplete = $true
    publication = 'Held pending artwork lots and names; no GitHub publication requested'
    builtAtUtc = [DateTime]::UtcNow.ToString('o')
    files = @(Get-ChildItem -LiteralPath $destination -Recurse -File | ForEach-Object {
      @{ path = $_.FullName.Substring($destination.Length + 1); bytes = $_.Length; sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
    })
  }
  $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $destination 'BUILD-VERIFICATE.json') -Encoding utf8
  & python (Join-Path $PSScriptRoot 'audit_local_app_candidate.py') $destination --commit $commit `
    --report (Join-Path $buildRoot "$Name-PACKAGES-VERIFIED.json")
  if ($LASTEXITCODE -ne 0) { throw 'Candidate package integrity failed' }
  Write-Output "LOCAL CANDIDATE VERIFIED: $destination"
} finally {
  # No deletion, swap or cleanup: interrupted work and every previous package
  # remain available for inspection and recovery.
  $lock.Dispose()
}
