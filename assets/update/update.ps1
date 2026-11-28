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
$createdInstallDirectories = [Collections.Generic.List[string]]::new()
$candidate = $null
$ownsMutex = $false
$mutex = $null
$windowsClosed = $false
$stagedRuntime = $staged
$incremental = !!($config.incrementalManifest -or $config.incrementalManifestSha256 -or
  $config.incrementalRuntime -or $config.incrementalPlan -or $config.incrementalHelper -or
  $config.incrementalHelperSha256 -or $config.incrementalRunId -or $config.incrementalPackageUrl -or
  $config.incrementalPackageBytes -or $config.incrementalPackageSha256 -or $config.incrementalSourceManifest -or
  $config.incrementalSourceManifestSha256 -or $config.incrementalSourceCommit -or $config.incrementalCachedObjectsRoot)

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

function Remove-CompletedUpdateTemporaryPath([string]$Path, [string]$Root) {
  try {
    Assert-Child $Path $Root
    if (Test-Path -LiteralPath $Path -PathType Container) {
      foreach ($entry in @(Get-ChildItem -LiteralPath $Path -Recurse -Force)) {
        Assert-Child $entry.FullName $Path
      }
      Remove-Item -LiteralPath $Path -Recurse -Force
    } elseif (Test-Path -LiteralPath $Path -PathType Leaf) {
      Remove-Item -LiteralPath $Path -Force
    }
  } catch {
    Write-Warning 'An update temporary file could not be removed.'
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

function Get-IncrementalEntryPath([string]$Root, [string]$RelativePath) {
  $path = Get-OculumIncrementalChild $Root $RelativePath
  Assert-Child $path $Root
  Assert-OculumIncrementalOrdinaryPath $path
  if ([IO.Directory]::Exists($path)) {
    throw "A local directory occupies a managed Windows runtime file: $RelativePath"
  }
  return $path
}

function New-IncrementalInstallParents([string]$Path) {
  $missing = [Collections.Generic.Stack[string]]::new()
  for ($parent = [IO.Path]::GetDirectoryName($Path); ![IO.Directory]::Exists($parent);
      $parent = [IO.Path]::GetDirectoryName($parent)) {
    Assert-Child $parent $target
    Assert-OculumIncrementalOrdinaryPath $parent
    if ([IO.File]::Exists($parent)) { throw "A runtime directory path is occupied by a file: $parent" }
    $missing.Push($parent)
  }
  while ($missing.Count -gt 0) {
    $parent = $missing.Pop()
    Assert-Child $parent $target
    Assert-OculumIncrementalOrdinaryPath $parent
    if (![IO.Directory]::Exists($parent)) {
      [void][IO.Directory]::CreateDirectory($parent)
      $createdInstallDirectories.Add($parent)
    }
  }
}

function Get-IncrementalBackupPath([string]$RelativePath) {
  $saved = Get-IncrementalEntryPath $backup $RelativePath
  [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($saved))
  return $saved
}

function Copy-LocalFilesMissingFromFullPackage([string]$InstalledData, [string]$StagedData) {
  Assert-Child $InstalledData $target
  if (![IO.Directory]::Exists($InstalledData)) { return }
  Assert-Child $StagedData $stagedRuntime
  $pending = [Collections.Generic.Stack[string]]::new()
  $pending.Push($InstalledData)
  while ($pending.Count -gt 0) {
    $directory = $pending.Pop()
    Assert-Child $directory $target
    foreach ($entry in [IO.DirectoryInfo]::new($directory).EnumerateFileSystemInfos()) {
      # Linked entries keep their original location in the rollback only.
      if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
      $relative = $entry.FullName.Substring($InstalledData.Length + 1)
      $copy = Join-Path $StagedData $relative
      Assert-Child $copy $StagedData
      if ($entry.Attributes -band [IO.FileAttributes]::Directory) {
        if ([IO.File]::Exists($copy)) { continue }
        [void][IO.Directory]::CreateDirectory($copy)
        $pending.Push($entry.FullName)
      } elseif (![IO.File]::Exists($copy) -and ![IO.Directory]::Exists($copy)) {
        Assert-Child $entry.FullName $InstalledData
        [IO.File]::Copy($entry.FullName, $copy)
      }
    }
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

function Resolve-UpdateWorkFile([string]$Path) {
  Assert-Child $Path $work
  $file = [IO.FileInfo]::new([IO.Path]::GetFullPath($Path))
  if (!$file.Exists) { throw 'An incremental update file is missing' }
  return $file
}

function Read-ApprovedIncrementalUpdate {
  $null = Resolve-UpdateWorkFile $ConfigPath
  if ($config.platform -cne 'windows') { throw 'Incremental update configuration is not for Windows' }
  $helper = Resolve-UpdateWorkFile $config.incrementalHelper
  $manifest = Resolve-UpdateWorkFile $config.incrementalManifest
  $receipt = Resolve-UpdateWorkFile $config.incrementalPlan
  if ($helper.Length -le 0 -or $helper.Length -gt 1MB -or
      $config.incrementalHelperSha256 -cnotmatch '^[a-f0-9]{64}$') {
    throw 'Invalid incremental helper size or SHA-256'
  }
  $helperBytes = [IO.File]::ReadAllBytes($helper.FullName)
  $digest = [Security.Cryptography.SHA256]::Create()
  try { $helperHash = [BitConverter]::ToString($digest.ComputeHash($helperBytes)).Replace('-', '') }
  finally { $digest.Dispose() }
  if ($helperBytes.Length -ne $helper.Length -or $helperHash -ine $config.incrementalHelperSha256) {
    throw 'Incremental helper SHA-256 verification failed'
  }
  $helperScript = [scriptblock]::Create([Text.UTF8Encoding]::new($false, $true).GetString($helperBytes).TrimStart([char]0xfeff))
  if ($receipt.Length -le 0 -or $receipt.Length -gt 48MB) { throw 'Invalid incremental staging receipt size' }
  $receipt = Get-Content -LiteralPath $receipt.FullName -Encoding UTF8 -Raw | ConvertFrom-Json
  if ($receipt.schemaVersion -ne 1 -or $receipt.commit -cne $config.commit -or
      $receipt.edition -cne $config.edition -or $receipt.runId -ne $config.incrementalRunId -or
      $receipt.manifestSha256 -cne $config.incrementalManifestSha256 -or
      $receipt.sourceManifestSha256 -cne $config.incrementalSourceManifestSha256 -or
      $receipt.isNoOp -isnot [bool] -or $receipt.removedPaths -isnot [array] -or
      $receipt.changedPaths -isnot [array] -or $receipt.removedPaths.Count -gt 100000 -or
      $receipt.changedPaths.Count -gt 100000) {
    throw 'The incremental staging receipt does not match the approved update'
  }
  $options = @{
    InstalledRoot = $target; WorkRoot = $work; Edition = $config.edition
    TargetManifestPath = $manifest.FullName; TargetManifestSha256 = $config.incrementalManifestSha256
  }
  if ($config.incrementalSourceManifest -or $config.incrementalSourceManifestSha256 -or $config.incrementalSourceCommit) {
    if ($config.incrementalSourceCommit -cnotmatch '^[a-f0-9]{40}$' -or
        $config.incrementalSourceManifestSha256 -cnotmatch '^[a-f0-9]{64}$') {
      throw 'The optional source manifest has no approved commit and digest'
    }
    $options.SourceManifestPath = (Resolve-UpdateWorkFile $config.incrementalSourceManifest).FullName
    $options.SourceManifestSha256 = $config.incrementalSourceManifestSha256
  }
  if ($config.incrementalCachedObjectsRoot) {
    $options.CachedObjectsRoot = [IO.Path]::GetFullPath([string]$config.incrementalCachedObjectsRoot)
  }
  if ($receipt.isNoOp) {
    if ($config.incrementalRuntime) { throw 'No-op staging cannot include replacement files' }
  } else {
    Assert-Child $config.incrementalRuntime $work
    if (![IO.Directory]::Exists($config.incrementalRuntime)) { throw 'Incremental staging directory is missing' }
  }
  return [pscustomobject]@{ HelperScript = $helperScript; Options = $options; Receipt = $receipt }
}

function Get-VerifiedIncrementalInstallPlan($Approved) {
  $otherExe = if ($config.edition -eq 'test') { 'oculum.exe' } else { 'Oculum-Test.exe' }
  $otherEdition = Join-Path $target $otherExe
  Assert-Child $otherEdition $target
  if (Test-Path -LiteralPath $otherEdition) { throw 'Oculum and Windows Test must have separate runtime folders' }
  $options = $Approved.Options
  $plan = Get-OculumIncrementalPlan @options
  $manifest = $plan.Target.Value
  if ($manifest.commit -cne $config.commit -or $manifest.runId -ne $config.incrementalRunId -or
      $manifest.package.url -cne $config.incrementalPackageUrl -or
      $manifest.package.bytes -ne $config.incrementalPackageBytes -or
      $manifest.package.sha256 -cne $config.incrementalPackageSha256 -or
      ($plan.Source -and $plan.Source.Value.commit -cne $config.incrementalSourceCommit)) {
    throw 'The incremental manifest does not match the approved package'
  }
  $removedPaths = @($plan.Removed | ForEach-Object path | Sort-Object -CaseSensitive)
  $approvedRemovals = @($Approved.Receipt.removedPaths | Sort-Object -CaseSensitive)
  $changedPaths = @($plan.ChangedPaths | Sort-Object -CaseSensitive)
  $approvedChanges = @($Approved.Receipt.changedPaths | Sort-Object -CaseSensitive)
  if ($plan.IsNoOp -ne $Approved.Receipt.isNoOp -or
      $removedPaths.Count -ne $approvedRemovals.Count -or
      ($removedPaths -join "`n") -cne ($approvedRemovals -join "`n") -or
      $changedPaths.Count -ne $approvedChanges.Count -or
      ($changedPaths -join "`n") -cne ($approvedChanges -join "`n")) {
    throw 'The installed runtime changed after the incremental plan was approved'
  }
  return $plan
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
  if ($incremental) {
    Write-UpdateStatus 'validating' 'Checking the approved Windows update'
    $approved = Read-ApprovedIncrementalUpdate
    . $approved.HelperScript
    $plan = Get-VerifiedIncrementalInstallPlan $approved
    if ($plan.IsNoOp) {
      Write-UpdateStatus 'success' 'The verified runtime is already installed; no files changed'
      'success' | Set-Content -LiteralPath (Join-Path $work 'result.txt')
      return
    }
    $preparedStage = [pscustomobject]@{
      IsNoOp = $false; RuntimeRoot = $config.incrementalRuntime
      RemoveRootEntries = @($plan.Removed | Where-Object { $_.path -notlike '*/*' } | ForEach-Object path)
    }
    Assert-OculumIncrementalStageReady $plan $preparedStage
    New-Item -ItemType Directory -Path $staged | Out-Null
    $stagedRuntime = Join-Path $staged ("incremental-runtime-$attempt")
    Assert-Child $stagedRuntime $staged
    if ([IO.Path]::GetPathRoot($preparedStage.RuntimeRoot) -ieq [IO.Path]::GetPathRoot($stagedRuntime)) {
      Move-RuntimeEntry $preparedStage.RuntimeRoot $stagedRuntime
    } else {
      Copy-Item -LiteralPath $preparedStage.RuntimeRoot -Destination $stagedRuntime -Recurse -Force
    }
  } else {
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
    $files = @(Get-ChildItem -LiteralPath $source | Where-Object {
      $_.Name -in 'data', 'native_assets.json' -or $_.Extension -in '.exe', '.dll'
    })
    New-Item -ItemType Directory -Path $staged | Out-Null
    foreach ($file in $files) {
      Assert-Child (Join-Path $target $file.Name) $target
      Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $staged $file.Name) -Recurse
    }
  }
  # A second Oculum instance may still own the same runtime. Never kill it.
  $waitSeconds = if ($null -ne $config.waitTimeoutSeconds) { [Math]::Max(0, [Math]::Min(300, [int]$config.waitTimeoutSeconds)) } else { 120 }
  $timer = [Diagnostics.Stopwatch]::StartNew()
  Write-UpdateStatus 'waiting' 'Waiting for every Oculum instance in this folder to close'
  while (@(Get-InstalledProcesses).Count -gt 0) {
    if ($timer.Elapsed.TotalSeconds -ge $waitSeconds) { throw 'Oculum is still open in this folder; close all its windows and retry the update' }
    Start-Sleep -Milliseconds 250
  }
  $windowsClosed = $true
  if ($incremental) {
    Write-UpdateStatus 'validating' 'Rechecking the approved files after Oculum closed'
    $plan = Get-VerifiedIncrementalInstallPlan $approved
    $installedStage = [pscustomobject]@{
      IsNoOp = $false; RuntimeRoot = $stagedRuntime; RemoveRootEntries = $preparedStage.RemoveRootEntries
    }
    Assert-OculumIncrementalStageReady $plan $installedStage -ExpectedStagingParent $staged
  } else {
    Write-UpdateStatus 'validating' 'Preserving local files outside the new Windows package'
    Copy-LocalFilesMissingFromFullPackage (Join-Path $target 'data') (Join-Path $stagedRuntime 'data')
  }
  New-Item -ItemType Directory -Path $backup | Out-Null
  Write-UpdateStatus 'installing' 'Installing the verified runtime; previous files remain backed up'
  if ($incremental) {
    foreach ($entry in $plan.Removed) {
      $destination = Get-IncrementalEntryPath $target $entry.path
      if (!(Test-OculumIncrementalFile $destination $entry)) {
        throw "An obsolete runtime file changed before removal: $($entry.path)"
      }
      $saved = Get-IncrementalBackupPath $entry.path
      [IO.File]::Move($destination, $saved)
      $moved.Add($entry.path)
    }
    foreach ($name in $plan.ChangedPaths) {
      $sourceFile = Get-IncrementalEntryPath $stagedRuntime $name
      $destination = Get-IncrementalEntryPath $target $name
      New-IncrementalInstallParents $destination
      if ([IO.File]::Exists($destination)) {
        $saved = Get-IncrementalBackupPath $name
        try { [IO.File]::Replace($sourceFile, $destination, $saved) }
        catch {
          # ReplaceFile can report failure after moving the old file to its backup.
          if ([IO.File]::Exists($saved)) { $moved.Add($name) }
          throw
        }
        $moved.Add($name)
      } else {
        [IO.File]::Move($sourceFile, $destination)
      }
      $installed.Add($name)
    }
  } else {
    foreach ($file in $files) {
      $destination = Join-Path $target $file.Name
      if (Test-Path -LiteralPath $destination) {
        Move-RuntimeEntry $destination (Join-Path $backup $file.Name)
        $moved.Add($file.Name)
      }
      Move-RuntimeEntry (Join-Path $stagedRuntime $file.Name) $destination
      $installed.Add($file.Name)
    }
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
  Remove-CompletedUpdateTemporaryPath $unpack $work
  Remove-CompletedUpdateTemporaryPath $inner $work
  Remove-CompletedUpdateTemporaryPath $staged $target
  $download = Join-Path $work 'release.zip'
  if ($incremental) {
    Remove-CompletedUpdateTemporaryPath $preparedStage.RuntimeRoot $work
  } elseif ([string]::Equals([IO.Path]::GetFullPath($config.archive), $download, [StringComparison]::OrdinalIgnoreCase)) {
    Remove-CompletedUpdateTemporaryPath $download $work
  }
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
        if ($incremental) {
          $path = Get-IncrementalEntryPath $target $name
          $previousStagePath = Get-IncrementalEntryPath $stagedRuntime $name
          if ([IO.File]::Exists($path)) { [IO.File]::Move($path, $previousStagePath) }
        } else {
          $path = Join-Path $target $name
          Assert-Child $path $target
          if (Test-Path -LiteralPath $path) { Move-RuntimeEntry $path (Join-Path $stagedRuntime $name) }
        }
      } catch { $rollbackErrors.Add("Could not remove new $name`: $($_.Exception.Message)") }
    }
    foreach ($name in $moved) {
      try {
        if ($incremental) {
          $previous = Get-IncrementalEntryPath $backup $name
          $destination = Get-IncrementalEntryPath $target $name
          [IO.File]::Move($previous, $destination)
        } else {
          Move-RuntimeEntry (Join-Path $backup $name) (Join-Path $target $name)
        }
      } catch { $rollbackErrors.Add("Could not restore $name`: $($_.Exception.Message)") }
    }
    for ($index = $createdInstallDirectories.Count - 1; $index -ge 0; $index--) {
      $directory = $createdInstallDirectories[$index]
      try {
        Assert-Child $directory $target
        Assert-OculumIncrementalOrdinaryPath $directory
        if ([IO.Directory]::Exists($directory) -and
            ![IO.DirectoryInfo]::new($directory).EnumerateFileSystemInfos().GetEnumerator().MoveNext()) {
          [IO.Directory]::Delete($directory)
        }
      } catch { $rollbackErrors.Add("Could not remove new directory $directory`: $($_.Exception.Message)") }
    }
  }
  if ($candidateAlive) { $problem += " The running app was left open. Previous runtime: $backup" }
  if ($rollbackErrors.Count) { $problem += " Recovery needs attention. Previous runtime: $backup. " + ($rollbackErrors -join ' ') }
  try { $problem | Set-Content -LiteralPath (Join-Path $work 'error.txt'); Write-UpdateStatus $(if ($candidateAlive) { 'unconfirmed' } else { 'error' }) $problem } catch { }
  if ($incremental -and $ownsMutex -and !$candidateAlive -and !$rollbackErrors.Count) {
    Remove-CompletedUpdateTemporaryPath $staged $target
  }
  # Do not open another instance when waiting failed or the candidate is alive.
  if ($ownsMutex -and !$candidateAlive -and ($moved.Count -gt 0 -or $windowsClosed) -and
      !$rollbackErrors.Count -and !(Get-InstalledProcesses).Count) {
    try { $null = Start-Oculum $false } catch { }
  }
  exit 1
} finally {
  if ($ownsMutex -and $mutex) { $mutex.ReleaseMutex() }
  if ($mutex) { $mutex.Dispose() }
}
