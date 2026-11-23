param(
  [Parameter(Mandatory = $true)][string]$CandidateRoot,
  [string]$ExpectedCommit = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$candidate = (Get-Item -LiteralPath $CandidateRoot).FullName
$distribution = [IO.Path]::GetFullPath((Join-Path $projectRoot 'build\distribution')).TrimEnd('\') + '\'
if (!$candidate.StartsWith($distribution, [StringComparison]::OrdinalIgnoreCase)) { throw 'Candidate must be inside build/distribution' }
$manifestPath = Join-Path $candidate 'BUILD-VERIFICATE.json'
if (Test-Path -LiteralPath $manifestPath) {
  $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
  if ($ExpectedCommit -and $manifest.commit -ne $ExpectedCommit) { throw 'Wrong candidate source commit' }
} elseif ($ExpectedCommit -match '^[0-9a-f]{40}$') {
  # Bootstrap can run after the two Windows builds while Android/ZIP work
  # continues. It never certifies package integrity or creates a manifest.
  $manifest = @{ commit = $ExpectedCommit }
} else { throw 'A candidate manifest or explicit source commit is required' }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'
$qaRoot = Join-Path $projectRoot "build\native-app-smoke-$stamp"
New-Item -ItemType Directory -Path $qaRoot | Out-Null
$results = @()
foreach ($edition in @(@('normal', 'windows\oculum.exe', ''), @('test', 'windows-test\Oculum-Test.exe', 'test'))) {
  $root = Join-Path $qaRoot $edition[0]
  New-Item -ItemType Directory -Path $root | Out-Null
  [IO.File]::WriteAllText((Join-Path $root 'OCULUM_SMOKE_STORAGE_ROOT'), "oculum-smoke-storage-v1`n", [Text.UTF8Encoding]::new($false))
  $executable = Join-Path $candidate $edition[1]
  $process = Start-Process -FilePath $executable -WorkingDirectory (Split-Path -Parent $executable) `
    -ArgumentList @('--desktop', ('"--oculum-smoke-data-dir={0}"' -f $root)) `
    -WindowStyle Hidden -PassThru
  try {
    $statusPath = Join-Path $root 'SMOKE-STATUS.json'
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $status = $null
    while ($timer.Elapsed.TotalSeconds -lt 30) {
      if ($process.HasExited) { throw "Smoke $($edition[0]) exited before validation: $($process.ExitCode)" }
      if (Test-Path -LiteralPath $statusPath) {
        $status = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
        if ($status.firstFrameSeen -eq $true) { break }
      }
      Start-Sleep -Milliseconds 250
    }
    if ($null -eq $status -or $status.firstFrameSeen -ne $true) { throw "No first frame for $($edition[0])" }
    Start-Sleep -Seconds 3
    if ($process.HasExited) { throw "Smoke $($edition[0]) exited after its first frame" }
    $status = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
    if ($status.offline -ne $true -or $status.frameworkErrorCount -ne 0 -or $status.saveProfile -ne $edition[2]) {
      throw "Invalid isolated bootstrap for $($edition[0])"
    }
    $results += @{
      edition = $edition[0]
      firstFrameSeen = $status.firstFrameSeen
      frameworkErrorCount = $status.frameworkErrorCount
      saveProfile = $status.saveProfile
      offline = $status.offline
      storageRoot = $root
      localSaveLoadVerified = $false
    }
    Write-Output "BOOTSTRAP VERIFIED: $($edition[0]), isolated offline storage, profile=$($status.saveProfile)"
  } finally {
    if (!$process.HasExited) {
      $null = $process.CloseMainWindow()
      if (!$process.WaitForExit(3000)) { $process.Kill(); $process.WaitForExit() }
    }
    $process.Dispose()
  }
}
@{
  sourceCommit = $manifest.commit
  candidate = $candidate
  scope = 'Native offline bootstrap with empty isolated storage; no live profile, full saved-campaign load or online flow certified'
  editions = $results
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $qaRoot 'NATIVE-BOOTSTRAP-VERIFIED.json') -Encoding utf8
Write-Output "NATIVE REPORT: $qaRoot\NATIVE-BOOTSTRAP-VERIFIED.json"
