param(
  [Parameter(Mandatory = $true)][string]$ExpectedCommit,
  [string]$DistributionRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'build/distribution')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$distRoot = [IO.Path]::GetFullPath($DistributionRoot).TrimEnd([char[]]'\/')
$rootPrefix = $distRoot + [IO.Path]::DirectorySeparatorChar
if ((Get-Item -LiteralPath $distRoot -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
  throw 'Distribution root cannot be a link'
}
$manifest = Get-Content -LiteralPath (Join-Path $distRoot 'BUILD-VERIFICATE.json') -Raw | ConvertFrom-Json
if ($manifest.commit -ne $ExpectedCommit) { throw 'Wrong distribution commit' }
$seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$records = @($manifest.files)
foreach ($record in $records) {
  $relative = [string]$record.path
  $filePath = [IO.Path]::GetFullPath((Join-Path $distRoot $relative))
  if ([IO.Path]::IsPathRooted($relative) -or !$filePath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -or !$seen.Add($filePath)) {
    throw "Unsafe or duplicate manifest path: $relative"
  }
  if ($record.sha256 -notmatch '^[a-fA-F0-9]{64}$' -or $record.bytes -lt 0) { throw "Invalid manifest record: $relative" }
  $file = Get-Item -LiteralPath $filePath -Force
  if ($file.PSIsContainer -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $file.Length -ne $record.bytes -or
      (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash -ne $record.sha256) {
    throw "Distribution payload mismatch: $relative"
  }
}
$actual = @(Get-ChildItem -LiteralPath $distRoot -Recurse -File).Count
if ($actual -ne $records.Count + 1) { throw "Distribution file count mismatch: $actual" }
foreach ($required in @('oculum.exe', 'windows/oculum.exe', 'windows-test/Oculum-Test.exe', 'Oculum-Windows.zip', 'Oculum-Test-Windows.zip', 'Oculum-Android-release.apk')) {
  if (!(Test-Path -LiteralPath (Join-Path $distRoot $required) -PathType Leaf)) { throw "Missing $required" }
}
Write-Host "VERIFIED commit=$($manifest.commit) files=$actual mismatches=0"
Get-ChildItem -LiteralPath $distRoot -File | Where-Object Extension -in @('.zip', '.apk', '.aab', '.ipa', '.gz', '.exe') | Select-Object Name, Length
