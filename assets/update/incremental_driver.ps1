param(
  [Parameter(Mandatory=$true)][ValidateSet('Plan','Stage')][string]$Mode,
  [Parameter(Mandatory=$true)][string]$ConfigPath
)
$ErrorActionPreference = 'Stop'

function Assert-DriverOrdinaryPath([string]$Path) {
  for ($part = $Path; $part; $part = [IO.Path]::GetDirectoryName($part)) {
    try { $attributes = [IO.File]::GetAttributes($part) }
    catch [IO.FileNotFoundException], [IO.DirectoryNotFoundException] { continue }
    if ($attributes -band [IO.FileAttributes]::ReparsePoint) {
      throw "Update cannot read or write linked paths: $part"
    }
  }
}

function Write-DriverJson([string]$Path, $Value) {
  Assert-DriverOrdinaryPath $Path
  $temporary = "$Path-$([Guid]::NewGuid().ToString('N')).tmp"
  $previous = "$temporary.previous"
  try {
    [IO.File]::WriteAllText($temporary, (ConvertTo-Json -InputObject $Value -Compress), [Text.UTF8Encoding]::new($false))
    if ([IO.File]::Exists($Path)) { [IO.File]::Replace($temporary, $Path, $previous) }
    else { [IO.File]::Move($temporary, $Path) }
  } finally {
    [IO.File]::Delete($temporary)
    [IO.File]::Delete($previous)
  }
}

$ConfigPath = [IO.Path]::GetFullPath($ConfigPath)
Assert-DriverOrdinaryPath $ConfigPath
if ([IO.FileInfo]::new($ConfigPath).Length -gt 64KB) { throw 'Update configuration is too large' }
$config = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($ConfigPath))
$work = [IO.Path]::GetFullPath([string]$config.work)
if ([IO.Path]::GetDirectoryName($ConfigPath) -ine $work) { throw 'Update configuration must be inside its working folder' }
$planPath = Join-Path $work 'incremental-preview.json'
$receiptPath = Join-Path $work 'incremental-stage.json'
$targetManifest = Join-Path $work 'incremental-target.json'
$sourceManifest = Join-Path $work 'incremental-source.json'
$executable = [IO.Path]::GetFullPath([string]$config.executable)
$installed = [IO.Path]::GetDirectoryName($executable)
$exe = if ($config.edition -eq 'test') { 'Oculum-Test.exe' } else { 'oculum.exe' }
if ($config.edition -notin @('normal','test') -or
    [IO.Path]::GetFileName($executable) -ine $exe -or
    ![IO.File]::Exists($executable)) {
  throw 'The current Windows installation does not match this edition'
}
$core = Join-Path $work 'oculum_incremental_windows.ps1'
if ($core -ine [IO.Path]::GetFullPath([string]$config.incrementalHelper) -or
    $targetManifest -ine [IO.Path]::GetFullPath([string]$config.incrementalManifest) -or
    $receiptPath -ine [IO.Path]::GetFullPath([string]$config.incrementalPlan) -or
    $config.incrementalHelperSha256 -cnotmatch '^[a-f0-9]{64}$') {
  throw 'Invalid update helper or manifest path'
}
foreach ($path in @($core, $targetManifest, $planPath, $receiptPath, $executable)) { Assert-DriverOrdinaryPath $path }
$helperStream = [IO.File]::OpenRead($core)
try {
  if ($helperStream.Length -le 0 -or $helperStream.Length -gt 1MB) { throw 'Invalid update helper size' }
  $sha = [Security.Cryptography.SHA256]::Create()
  try { $hash = [BitConverter]::ToString($sha.ComputeHash($helperStream)).Replace('-', '') }
  finally { $sha.Dispose() }
  if ($hash -ine $config.incrementalHelperSha256) { throw 'Update helper SHA-256 verification failed' }
  $helperStream.Position = 0
  $helperReader = [IO.StreamReader]::new($helperStream, [Text.UTF8Encoding]::new($false, $true))
  try { $helperText = $helperReader.ReadToEnd() }
  finally { $helperReader.Dispose() }
} finally { $helperStream.Dispose() }
. ([scriptblock]::Create($helperText))
$parameters = @{
  InstalledRoot = $installed
  WorkRoot = $work
  Edition = [string]$config.edition
  TargetManifestPath = $targetManifest
  TargetManifestSha256 = [string]$config.incrementalManifestSha256
}
if ($config.incrementalSourceManifestSha256) {
  if ($sourceManifest -ine [IO.Path]::GetFullPath([string]$config.incrementalSourceManifest)) { throw 'Invalid previous manifest path' }
  Assert-DriverOrdinaryPath $sourceManifest
  $parameters.SourceManifestPath = $sourceManifest
  $parameters.SourceManifestSha256 = [string]$config.incrementalSourceManifestSha256
}
if ($config.incrementalCachedObjectsRoot) {
  $parameters.CachedObjectsRoot = [IO.Path]::GetFullPath([string]$config.incrementalCachedObjectsRoot)
}
$plan = Get-OculumIncrementalPlan @parameters
$release = $plan.Target.Value
if ($release.commit -cne $config.commit -or $release.runId -ne $config.incrementalRunId -or
    $release.package.url -cne $config.incrementalPackageUrl -or
    $release.package.bytes -ne $config.incrementalPackageBytes -or
    $release.package.sha256 -cne $config.incrementalPackageSha256 -or
    ($plan.Source -and $plan.Source.Value.commit -cne $config.incrementalSourceCommit)) {
  throw 'The index does not match the release verified by Oculum'
}
$preview = [ordered]@{
  commit = $release.commit
  edition = $release.edition
  downloadCount = [int]$plan.DownloadCount
  downloadBytes = [long]$plan.DownloadBytes
  changedCount = [int]$plan.ChangedCount
  removeCount = [int]$plan.RemoveCount
  changedPaths = @($plan.ChangedPaths | Sort-Object)
  removedPaths = @($plan.Removed | ForEach-Object path | Sort-Object)
}
if ($Mode -eq 'Plan') {
  Write-DriverJson $planPath $preview
  return
}
if ([IO.FileInfo]::new($planPath).Length -gt 24MB) { throw 'Approved update preview is too large' }
$confirmed = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($planPath))
foreach ($name in @('commit','edition','changedCount','removeCount','changedPaths','removedPaths')) {
  if ((ConvertTo-Json -Compress -InputObject $preview[$name]) -cne (ConvertTo-Json -Compress -InputObject $confirmed.$name)) {
    throw 'The installation changed since the preview. Check it again.'
  }
}
foreach ($name in @('downloadCount','downloadBytes')) {
  if (!(Test-OculumIncrementalInteger $confirmed.$name) -or $preview[$name] -gt $confirmed.$name) {
    throw 'The download grew since the preview. Check it again before downloading.'
  }
}
$stage = New-OculumIncrementalStage -Plan $plan
if ($stage.IsNoOp) { throw 'The installation is already up to date' }
Write-DriverJson $receiptPath ([ordered]@{
  schemaVersion = 1; commit = $release.commit; edition = $release.edition; runId = $release.runId
  manifestSha256 = $config.incrementalManifestSha256
  sourceManifestSha256 = $config.incrementalSourceManifestSha256
  isNoOp = $false; changedPaths = $preview.changedPaths; removedPaths = $preview.removedPaths
  downloadCount = [int]$stage.DownloadCount; downloadBytes = [long]$stage.DownloadBytes
  runtimeDirectoryName = [IO.Path]::GetFileName($stage.RuntimeRoot)
})
