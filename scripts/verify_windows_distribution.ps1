param(
  [Parameter(Mandatory = $true)][string]$NormalFolder,
  [Parameter(Mandatory = $true)][string]$TestFolder,
  [Parameter(Mandatory = $true)][string]$NormalZip,
  [Parameter(Mandatory = $true)][string]$TestZip,
  [Parameter(Mandatory = $true)][string]$OutputParent,
  [Parameter(Mandatory = $true)][ValidatePattern('^[a-fA-F0-9]{40}$')][string]$Commit
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-TreeFiles([string]$Folder) {
  $root = [IO.Path]::GetFullPath($Folder).TrimEnd([char[]]'\/')
  if (!(Test-Path -LiteralPath $root -PathType Container)) { throw "Windows folder missing: $root" }
  return @(Get-ChildItem -LiteralPath $root -Recurse -File | ForEach-Object {
    [pscustomobject]@{
      relative = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
      path = $_.FullName
      bytes = $_.Length
      hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    }
  })
}

function Assert-Runtime([string]$Folder, [string]$Executable) {
  foreach ($required in @($Executable, 'flutter_windows.dll', 'WebView2Loader.dll', 'vcruntime140.dll', 'msvcp140.dll', 'data/app.so', 'data/icudtl.dat', 'data/flutter_assets')) {
    if (!(Test-Path -LiteralPath (Join-Path $Folder $required))) { throw "Windows runtime missing: $Folder/$required" }
  }
}

function Assert-ZipMatchesFolder([string]$ArchivePath, [string]$Folder, [string]$Executable) {
  if (!(Test-Path -LiteralPath $ArchivePath -PathType Leaf) -or (Get-Item -LiteralPath $ArchivePath).Length -eq 0) {
    throw "Windows archive missing or empty: $ArchivePath"
  }
  $files = Get-TreeFiles $Folder
  $archive = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
  try {
    $entries = @{}
    foreach ($entry in $archive.Entries) {
      if (!$entry.Name) { continue }
      $relative = $entry.FullName.Replace('\', '/')
      if ($entries.ContainsKey($relative)) { throw "Duplicate Windows ZIP entry: $relative" }
      $entries[$relative] = $entry
    }
    if ($entries.Count -ne $files.Count) { throw "Windows ZIP file count differs from folder: $ArchivePath" }
    foreach ($file in $files) {
      $entry = $entries[$file.relative]
      if (!$entry -or $entry.Length -ne $file.bytes) { throw "Windows ZIP payload missing or truncated: $($file.relative)" }
      $stream = $entry.Open()
      $sha = [Security.Cryptography.SHA256]::Create()
      try {
        $hash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '')
      } finally {
        $stream.Dispose()
        $sha.Dispose()
      }
      if ($hash -ne $file.hash) { throw "Windows ZIP payload hash mismatch: $($file.relative)" }
    }
    if (!$entries.ContainsKey($Executable)) { throw "Windows ZIP executable missing: $Executable" }
  } finally {
    $archive.Dispose()
  }
}

$normal = [IO.Path]::GetFullPath($NormalFolder)
$test = [IO.Path]::GetFullPath($TestFolder)
Assert-Runtime $normal 'oculum.exe'
Assert-Runtime $test 'Oculum-Test.exe'
Assert-ZipMatchesFolder $NormalZip $normal 'oculum.exe'
Assert-ZipMatchesFolder $TestZip $test 'Oculum-Test.exe'

$normalApp = Join-Path $normal 'data/app.so'
$testApp = Join-Path $test 'data/app.so'
if ((Get-FileHash -LiteralPath $normalApp -Algorithm SHA256).Hash -eq
    (Get-FileHash -LiteralPath $testApp -Algorithm SHA256).Hash) {
  throw 'Windows and Windows Test contain the same compiled app; the test save profile was not isolated.'
}

$parent = [IO.Path]::GetFullPath($OutputParent)
$versioned = Join-Path $parent "Oculum-$Commit"
if (Test-Path -LiteralPath $versioned) { throw "Versioned Windows output already exists: $versioned" }
$windowsOutput = Join-Path $versioned 'Windows'
$testOutput = Join-Path $versioned 'Windows Test'
New-Item -ItemType Directory -Path $windowsOutput, $testOutput -Force | Out-Null
Get-ChildItem -LiteralPath $normal -Force | Copy-Item -Destination $windowsOutput -Recurse -Force
Get-ChildItem -LiteralPath $test -Force | Copy-Item -Destination $testOutput -Recurse -Force

$nestedPackages = @(Get-ChildItem -LiteralPath $versioned -Recurse -File | Where-Object Extension -in @('.zip', '.apk', '.aab'))
if ($nestedPackages.Count) { throw 'The versioned Windows folder must contain only the unpacked Windows editions.' }
Write-Host "VERIFIED Windows and Windows Test runtime, archive contents, and isolated profiles for $Commit"
