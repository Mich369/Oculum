param([Parameter(Mandatory=$true)][string]$ConfigPath)
$ErrorActionPreference = 'Stop'
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$work = [IO.Path]::GetFullPath($config.work)
$target = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($config.executable))
$packageExe = if ($config.edition -eq 'test') { 'Oculum-Test.exe' } else { 'oculum.exe' }
$attempt = [Guid]::NewGuid().ToString('N')
$unpack = Join-Path $work "unpacked-$attempt"
$inner = Join-Path $work "runtime-$attempt"
# Keep both rename destinations on the installed volume, including USB installs.
$staged = Join-Path $target ".oculum-update-staged-$attempt"
$backup = Join-Path $target ".oculum-update-backup-$attempt"
$ack = Join-Path $work 'startup-ack.json'
$token = [Guid]::NewGuid().ToString('N')
$installed = [Collections.Generic.List[string]]::new()
$moved = [Collections.Generic.List[string]]::new()
$candidate = $null
$ownsMutex = $false
$mutex = $null

function Assert-Child([string]$Path, [string]$Root) {
  $rootPath = [IO.Path]::GetFullPath($Root).TrimEnd([char[]]'\/')
  $full = [IO.Path]::GetFullPath($Path)
  if (!$full.StartsWith($rootPath + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Unsafe update path: $full"
  }
  # Checking ancestors also prevents an existing directory link escaping Root.
  for ($part = $full; $part -and $part.Length -ge $rootPath.Length; $part = [IO.Path]::GetDirectoryName($part)) {
    if ((Test-Path -LiteralPath $part) -and ((Get-Item -LiteralPath $part -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
      throw 'Update cannot use a linked directory'
    }
  }
}

function Write-UpdateStatus([string]$State, [string]$Message) {
  $candidateId = if ($candidate) { $candidate.Id } else { $null }
  $record = [ordered]@{
    state = $State; message = $Message; commit = [string]$config.commit
    edition = [string]$config.edition; attemptId = $attempt
    backup = $backup; candidatePid = $candidateId; updatedAtUtc = [DateTime]::UtcNow.ToString('o')
  }
  $record | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $work 'update-status.json') -Encoding UTF8
}

function Move-RuntimeEntry([string]$Source, [string]$Destination) {
  if ((Get-Item -LiteralPath $Source -Force).PSIsContainer) {
    [IO.Directory]::Move($Source, $Destination)
  } else {
    [IO.File]::Move($Source, $Destination)
  }
}

function Get-InstalledProcesses {
  $prefix = $target.TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
  @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    try {
      $processPath = $_.Path
      $processPath -and $processPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
    } catch { $false }
  })
}

function Start-Oculum([bool]$RequireAck) {
  $startInfo = [Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = Join-Path $target $packageExe
  $startInfo.WorkingDirectory = $target
  $startInfo.UseShellExecute = $false
  $startInfo.CreateNoWindow = $true
  if ($RequireAck) {
    $startInfo.EnvironmentVariables['OCULUM_UPDATE_ACK_PATH'] = $ack
    $startInfo.EnvironmentVariables['OCULUM_UPDATE_ACK_TOKEN'] = $token
  } else {
    $startInfo.EnvironmentVariables.Remove('OCULUM_UPDATE_ACK_PATH')
    $startInfo.EnvironmentVariables.Remove('OCULUM_UPDATE_ACK_TOKEN')
  }
  [Diagnostics.Process]::Start($startInfo)
}

try {
  foreach ($path in @($unpack, $inner, $ack)) { Assert-Child $path $work }
  foreach ($path in @($staged, $backup)) { Assert-Child $path $target }
  if ([string]$config.commit -notmatch '^[a-f0-9]{40}$' -or $config.edition -notin @('normal', 'test')) {
    throw 'The update has no valid source or edition'
  }
  if (![string]::Equals([IO.Path]::GetFileName($config.executable), $packageExe, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The package edition does not match the installed executable'
  }
  $keyHash = [Security.Cryptography.SHA256]::Create()
  try { $mutexKey = [BitConverter]::ToString($keyHash.ComputeHash([Text.Encoding]::UTF8.GetBytes($target.ToLowerInvariant()))).Replace('-', '') }
  finally { $keyHash.Dispose() }
  $mutex = [Threading.Mutex]::new($false, "Local\OculumUpdate-$mutexKey")
  try { $ownsMutex = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $ownsMutex = $true }
  if (!$ownsMutex) { throw 'Another update is already installing into this folder' }
  foreach ($name in @('result.txt', 'error.txt', 'startup-ack.json')) {
    $oldResult = Join-Path $work $name
    if (Test-Path -LiteralPath $oldResult -PathType Leaf) { Remove-Item -LiteralPath $oldResult -Force }
  }
  Write-UpdateStatus 'validating' 'Checking the complete Windows runtime'
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  function Expand-Checked([string]$Archive, [string]$Destination) {
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    try {
      foreach ($entry in $zip.Entries) {
        Assert-Child (Join-Path $Destination $entry.FullName) $Destination
        if ((($entry.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000) { throw 'Archive links are unsupported' }
      }
    } finally { $zip.Dispose() }
    [IO.Compression.ZipFile]::ExtractToDirectory($Archive, $Destination)
  }
  Expand-Checked $config.archive $unpack
  $executables = @(Get-ChildItem -LiteralPath $unpack -Filter $packageExe -Recurse -File)
  if ($executables.Count -eq 0) {
    $nested = @(Get-ChildItem -LiteralPath $unpack -Filter '*.zip' -Recurse -File)
    if ($nested.Count -ne 1) { throw 'Windows package is ambiguous' }
    Expand-Checked $nested[0].FullName $inner
    $executables = @(Get-ChildItem -LiteralPath $inner -Filter $packageExe -Recurse -File)
  }
  if ($executables.Count -ne 1) { throw 'Expected one Oculum executable' }
  $source = $executables[0].Directory.FullName
  foreach ($required in @($packageExe, 'flutter_windows.dll', 'WebView2Loader.dll', 'data/app.so', 'data/icudtl.dat', 'data/flutter_assets/AssetManifest.bin')) {
    $requiredPath = Join-Path $source $required
    if (!(Test-Path -LiteralPath $requiredPath -PathType Leaf) -or (Get-Item -LiteralPath $requiredPath).Length -eq 0) {
      throw "Incomplete Windows runtime: $required"
    }
  }
  foreach ($file in @(Get-ChildItem -LiteralPath $source -Recurse -Force)) { Assert-Child $file.FullName $source }
  $files = @(Get-ChildItem -LiteralPath $source | Where-Object { $_.Name -eq 'data' -or $_.Extension -in '.exe', '.dll' })
  New-Item -ItemType Directory -Path $staged | Out-Null
  foreach ($file in $files) {
    Assert-Child (Join-Path $target $file.Name) $target
    Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $staged $file.Name) -Recurse
  }
  # A second Oculum instance may still own the same runtime. Never kill it.
  $waitSeconds = if ($null -ne $config.waitTimeoutSeconds) { [Math]::Max(0, [Math]::Min(300, [int]$config.waitTimeoutSeconds)) } else { 120 }
  $timer = [Diagnostics.Stopwatch]::StartNew()
  Write-UpdateStatus 'waiting' 'Waiting for every Oculum instance in this folder to close'
  while (@(Get-InstalledProcesses).Count -gt 0) {
    if ($timer.Elapsed.TotalSeconds -ge $waitSeconds) { throw 'Oculum is still open in this folder; close all its windows and retry the update' }
    Start-Sleep -Milliseconds 250
  }
  New-Item -ItemType Directory -Path $backup | Out-Null
  Write-UpdateStatus 'installing' 'Installing the verified runtime; previous files remain backed up'
  foreach ($file in $files) {
    $destination = Join-Path $target $file.Name
    if (Test-Path -LiteralPath $destination) {
      Move-RuntimeEntry $destination (Join-Path $backup $file.Name)
      $moved.Add($file.Name)
    }
    Move-RuntimeEntry (Join-Path $staged $file.Name) $destination
    $installed.Add($file.Name)
  }
  $candidate = Start-Oculum $true
  Write-UpdateStatus 'starting' 'Waiting for Oculum to confirm its source and first frame'
  $startupSeconds = if ($null -ne $config.startupTimeoutSeconds) { [Math]::Max(0, [Math]::Min(300, [int]$config.startupTimeoutSeconds)) } else { 45 }
  $timer.Restart()
  $confirmed = $false
  while ($timer.Elapsed.TotalSeconds -lt $startupSeconds) {
    $candidate.Refresh()
    if ($candidate.HasExited) { throw 'The updated Oculum closed before confirming startup' }
    if (Test-Path -LiteralPath $ack -PathType Leaf) {
      # The app writes after its first frame; a partial file can be retried.
      try { $ready = Get-Content -LiteralPath $ack -Raw | ConvertFrom-Json } catch { $ready = $null }
      if ($ready -and $ready.token -eq $token -and $ready.commit -eq $config.commit -and $ready.edition -eq $config.edition) {
        $confirmed = $true
        break
      }
    }
    Start-Sleep -Milliseconds 100
  }
  if (!$confirmed) { throw 'Oculum started but did not confirm its source and first frame; backup retained' }
  Write-UpdateStatus 'success' 'Oculum confirmed the installed version and startup'
  'success' | Set-Content -LiteralPath (Join-Path $work 'result.txt')
} catch {
  $problem = $_.Exception.Message
  $rollbackErrors = [Collections.Generic.List[string]]::new()
  $candidateAlive = $false
  if ($candidate) { try { $candidate.Refresh(); $candidateAlive = !$candidate.HasExited } catch { $candidateAlive = $true } }
  if ($ownsMutex -and !$candidateAlive) {
    # Each operation is independent: one locked file must not skip all restores.
    for ($index = $installed.Count - 1; $index -ge 0; $index--) {
      $name = $installed[$index]
      try {
        $path = Join-Path $target $name
        Assert-Child $path $target
        if (Test-Path -LiteralPath $path) { Move-RuntimeEntry $path (Join-Path $staged $name) }
      } catch { $rollbackErrors.Add("Could not remove new $name`: $($_.Exception.Message)") }
    }
    foreach ($name in $moved) {
      try { Move-RuntimeEntry (Join-Path $backup $name) (Join-Path $target $name) }
      catch { $rollbackErrors.Add("Could not restore $name`: $($_.Exception.Message)") }
    }
  }
  if ($candidateAlive) { $problem += " The running app was left open. Previous runtime: $backup" }
  if ($rollbackErrors.Count) { $problem += " Recovery needs attention. Previous runtime: $backup. " + ($rollbackErrors -join ' ') }
  try { $problem | Set-Content -LiteralPath (Join-Path $work 'error.txt'); Write-UpdateStatus $(if ($candidateAlive) { 'unconfirmed' } else { 'error' }) $problem } catch { }
  # Do not open another instance when waiting failed or the candidate is alive.
  if ($ownsMutex -and !$candidateAlive -and $moved.Count -gt 0 -and !$rollbackErrors.Count -and !(Get-InstalledProcesses).Count) {
    try { $null = Start-Oculum $false } catch { }
  }
  exit 1
} finally {
  if ($ownsMutex -and $mutex) { $mutex.ReleaseMutex() }
  if ($mutex) { $mutex.Dispose() }
}
