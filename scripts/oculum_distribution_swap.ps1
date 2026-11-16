function Assert-OculumRollbackEnvironment {
  if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT -or
      $PSVersionTable.PSVersion -lt [version]'7.2') {
    throw 'Verified rollback retention requires PowerShell 7.2 or later on Windows to inspect alternate data streams. Run the command again with pwsh.'
  }
}

function Assert-OculumRollbackChild([string]$Root, [string]$Path) {
  $full = [IO.Path]::GetFullPath($Path).TrimEnd([char[]]'\/')
  if (![string]::Equals([IO.Path]::GetDirectoryName($full), $Root, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Rollback path must be a direct child of the build root: $full"
  }
  return $full
}

function Assert-OculumRollbackItem($Item) {
  if ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
    throw "Rollback retention cannot process a linked item: $($Item.FullName)"
  }
  if (@(Get-Item -LiteralPath $Item.FullName -Stream '*' | Where-Object Stream -ne ':$DATA').Count) {
    throw "Rollback retention found alternate data streams: $($Item.FullName)"
  }
}

function Assert-OculumRollbackPayloadPath([string]$RelativePath) {
  if ($RelativePath -match '(?:^|[/\\])(?:profiles?(?:[-_.][^/\\]*)?|saves?(?:[-_.][^/\\]*)?|savegames?|salvataggi|userdata|user[-_]data|oculum_save_blobs[^/\\]*|shared_preferences[^/\\]*|oculum_progress_journal[^/\\]*|oculum_backup[^/\\]*|\.oculum-update-backup[^/\\]*)(?:[/\\]|$)') {
    throw "Rollback contains a user data path: $RelativePath"
  }
}

function Get-OculumVerifiedRollbackHash([string]$Root, [scriptblock]$Verify) {
  $directory = Get-Item -LiteralPath $Root -Force
  if (!$directory.PSIsContainer) { throw "Rollback is not a directory: $Root" }
  $files = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $pending = [Collections.Generic.Stack[IO.DirectoryInfo]]::new()
  $pending.Push($directory)
  while ($pending.Count) {
    $parent = $pending.Pop()
    Assert-OculumRollbackItem $parent
    foreach ($item in Get-ChildItem -LiteralPath $parent.FullName -Force) {
      $relative = $item.FullName.Substring($Root.Length + 1).Replace('\', '/')
      Assert-OculumRollbackPayloadPath $relative
      if ($item.PSIsContainer) {
        $pending.Push($item)
      } else {
        Assert-OculumRollbackItem $item
        if (!$files.Add($relative)) {
          throw "Duplicate rollback path: $($item.FullName)"
        }
      }
    }
  }
  $manifestName = 'BUILD-VERIFICATE.json'
  $manifestPath = Join-Path $Root $manifestName
  if (!$files.Remove($manifestName)) { throw "Rollback manifest missing: $Root" }
  $manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
  $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
  if (@($manifest.files).Count -eq 0) { throw "Rollback manifest lists no files: $Root" }
  foreach ($record in $manifest.files) {
    if (!$files.Remove(([string]$record.path).Replace('\', '/'))) {
      throw "Rollback manifest path is missing or duplicate: $($record.path)"
    }
  }
  if ($files.Count) { throw "Rollback contains untracked files: $Root" }
  $null = & $Verify $Root
  if ((Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash -ne $manifestHash) {
    throw "Rollback manifest changed during verification: $Root"
  }
  return $manifestHash
}

function Read-OculumVerifiedRollbackReceipt([string]$Path) {
  $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
  if (!$item) { return $null }
  Assert-OculumRollbackItem $item
  if ($item.PSIsContainer) { throw 'Verified rollback receipt must be an ordinary file' }
  $receipt = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  if ($receipt.schema -ne 1) { throw 'Unsupported verified rollback receipt' }
  foreach ($record in @($receipt, $receipt.retired)) {
    if ($null -eq $record) { continue }
    if ([string]$record.backupName -notmatch '^distribution-backup-[a-zA-Z0-9_-]+$' -or
        [string]$record.manifestSha256 -notmatch '^[A-Fa-f0-9]{64}$') {
      throw 'Invalid verified rollback receipt'
    }
  }
  if ($receipt.retired -and $receipt.retired.backupName -eq $receipt.backupName) {
    throw 'Verified rollback receipt refers to the same tree twice'
  }
  return $receipt
}

function Write-OculumVerifiedRollbackReceipt([string]$Path, $Record, $Retired) {
  $content = @{ schema = 1; backupName = $Record.backupName; manifestSha256 = $Record.manifestSha256; retired = $Retired }
  $temporary = $Path + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
  $ownsTemporary = $false
  try {
    $stream = [IO.File]::Open($temporary, [IO.FileMode]::CreateNew)
    $ownsTemporary = $true
    try {
      $bytes = [Text.Encoding]::UTF8.GetBytes(($content | ConvertTo-Json -Compress))
      $stream.Write($bytes, 0, $bytes.Length)
      $stream.Flush($true)
    } finally { $stream.Dispose() }
    [IO.File]::Move($temporary, $Path, $true)
  } finally {
    if ($ownsTemporary -and (Test-Path -LiteralPath $temporary -PathType Leaf)) {
      [IO.File]::Delete($temporary)
    }
  }
}

function Set-OculumVerifiedRollbackReceipt {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$BuildRoot,
    [Parameter(Mandatory = $true)][string]$DistributionRoot,
    [Parameter(Mandatory = $true)][string]$RollbackRoot,
    [Parameter(Mandatory = $true)][scriptblock]$VerifyRollback
  )

  $ErrorActionPreference = 'Stop'
  Assert-OculumRollbackEnvironment
  $root = [IO.Path]::GetFullPath($BuildRoot).TrimEnd([char[]]'\/')
  $rootItem = Get-Item -LiteralPath $root -Force
  if (!$rootItem.PSIsContainer -or ($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw 'Rollback build root must be an ordinary directory'
  }
  $target = Assert-OculumRollbackChild $root $DistributionRoot
  $rollback = Assert-OculumRollbackChild $root $RollbackRoot
  $name = [IO.Path]::GetFileName($rollback)
  if ($target -eq $rollback -or $name -notmatch '^distribution-backup-[a-zA-Z0-9_-]+$') {
    throw 'Managed rollback requires a separate distribution-backup directory'
  }
  $prefix = Join-Path $root ('.' + [IO.Path]::GetFileName($target))
  $lockPath = "$prefix.swap.lock"
  $existingLock = Get-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue
  if ($existingLock -and ($existingLock.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw 'Distribution swap lock cannot be a link'
  }
  $lock = [IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
  try {
    $receiptPath = "$prefix.verified-rollback.json"
    $existing = Read-OculumVerifiedRollbackReceipt $receiptPath
    $hash = Get-OculumVerifiedRollbackHash $rollback $VerifyRollback
    if ($existing) {
      if ($existing.backupName -ne $name -or $existing.manifestSha256 -ne $hash) {
        throw 'Verified rollback receipt already names a different tree'
      }
      return
    }
    Write-OculumVerifiedRollbackReceipt $receiptPath @{ backupName = $name; manifestSha256 = $hash } $null
  } finally { $lock.Dispose() }
}

function Invoke-OculumDistributionSwap {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$BuildRoot,
    [Parameter(Mandatory = $true)][string]$DistributionRoot,
    [Parameter(Mandatory = $true)][string]$StagingRoot,
    [Parameter(Mandatory = $true)][string]$BackupRoot,
    [Parameter(Mandatory = $true)][scriptblock]$BeforeSwap,
    [Parameter(Mandatory = $true)][scriptblock]$VerifyInstalled,
    [switch]$RetainSingleVerifiedBackup,
    [scriptblock]$VerifyRollback
  )

  $ErrorActionPreference = 'Stop'
  $swapBuildRoot = [IO.Path]::GetFullPath($BuildRoot).TrimEnd([char[]]'\/')
  $swapTarget = [IO.Path]::GetFullPath($DistributionRoot).TrimEnd([char[]]'\/')
  $swapStaging = [IO.Path]::GetFullPath($StagingRoot).TrimEnd([char[]]'\/')
  $swapBackup = [IO.Path]::GetFullPath($BackupRoot).TrimEnd([char[]]'\/')
  if ($RetainSingleVerifiedBackup) {
    Assert-OculumRollbackEnvironment
    if (!$VerifyRollback -or [IO.Path]::GetFileName($swapBackup) -notmatch '^distribution-backup-[a-zA-Z0-9_-]+$') {
      throw 'Verified rollback retention requires a verifier and a distribution-backup directory'
    }
  }
  if (!(Test-Path -LiteralPath $swapBuildRoot -PathType Container) -or
      ((Get-Item -LiteralPath $swapBuildRoot -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw 'Distribution build root must be an existing ordinary directory'
  }
  $swapPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach ($swapPath in @($swapTarget, $swapStaging, $swapBackup)) {
    if (![string]::Equals([IO.Path]::GetDirectoryName($swapPath), $swapBuildRoot, [StringComparison]::OrdinalIgnoreCase) -or
        !$swapPaths.Add($swapPath)) {
      throw 'Distribution, staging and backup must be distinct siblings inside the build root'
    }
    if ((Test-Path -LiteralPath $swapPath) -and
        ((Get-Item -LiteralPath $swapPath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
      throw "Distribution swap cannot rename a linked directory: $swapPath"
    }
  }
  if (!(Test-Path -LiteralPath $swapStaging -PathType Container) -or (Test-Path -LiteralPath $swapBackup)) {
    throw 'Verified staging must exist and the backup path must be unused'
  }

  # Keep concurrent installers out of the two-rename transaction. Do not delete
  # this lock file on release: another installer may already have opened it.
  $swapLockPath = Join-Path $swapBuildRoot ('.' + [IO.Path]::GetFileName($swapTarget) + '.swap.lock')
  if ((Test-Path -LiteralPath $swapLockPath) -and
      ((Get-Item -LiteralPath $swapLockPath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw 'Distribution swap lock cannot be a link'
  }
  $swapLock = $null
  $swapMovedPrevious = $false
  $swapPromoted = $false
  $receiptCommitted = $false
  try {
    $swapLock = [IO.File]::Open($swapLockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    & $BeforeSwap
    $previousRecord = $null
    $previousPath = $null
    $newRecord = $null
    if ($RetainSingleVerifiedBackup) {
      $receiptPath = Join-Path $swapBuildRoot ('.' + [IO.Path]::GetFileName($swapTarget) + '.verified-rollback.json')
      $receipt = Read-OculumVerifiedRollbackReceipt $receiptPath
      if ($receipt) {
        $previousPath = Join-Path $swapBuildRoot $receipt.backupName
        if ($swapPaths.Contains($previousPath) -or
            (Get-OculumVerifiedRollbackHash $previousPath $VerifyRollback) -ne $receipt.manifestSha256) {
          throw 'The existing verified rollback no longer matches its receipt'
        }
        $previousRecord = @{ backupName = $receipt.backupName; manifestSha256 = $receipt.manifestSha256 }
        if ($receipt.retired) {
          $retiredPath = Join-Path $swapBuildRoot $receipt.retired.backupName
          if ($swapPaths.Contains($retiredPath)) { throw 'The retired rollback overlaps the new swap' }
          if (Get-Item -LiteralPath $retiredPath -Force -ErrorAction SilentlyContinue) {
            throw "A retired rollback still needs inspection before the next swap: $retiredPath"
          }
          Write-OculumVerifiedRollbackReceipt $receiptPath $previousRecord $null
        }
      }
      if (Test-Path -LiteralPath $swapTarget) {
        $newRecord = @{
          backupName = [IO.Path]::GetFileName($swapBackup)
          manifestSha256 = Get-OculumVerifiedRollbackHash $swapTarget $VerifyRollback
        }
      }
    }
    # Directory.Move is a same-volume directory rename. Unlike PowerShell's
    # Move-Item it cannot move some children before discovering a locked file.
    if (Test-Path -LiteralPath $swapTarget) {
      [IO.Directory]::Move($swapTarget, $swapBackup)
      $swapMovedPrevious = $true
    }
    [IO.Directory]::Move($swapStaging, $swapTarget)
    $swapPromoted = $true
    & $VerifyInstalled
    if ($RetainSingleVerifiedBackup -and $newRecord) {
      $newManifestPath = Join-Path $swapBackup 'BUILD-VERIFICATE.json'
      if ((Get-FileHash -LiteralPath $newManifestPath -Algorithm SHA256).Hash -ne $newRecord.manifestSha256) {
        throw 'The previous distribution changed during the swap'
      }
      Write-OculumVerifiedRollbackReceipt $receiptPath $newRecord $previousRecord
      $receiptCommitted = $true
      if ($previousRecord) {
        if ((Get-OculumVerifiedRollbackHash $previousPath $VerifyRollback) -ne $previousRecord.manifestSha256) {
          throw 'The retired verified rollback changed before cleanup'
        }
        Remove-Item -LiteralPath $previousPath -Recurse -Force
        Write-OculumVerifiedRollbackReceipt $receiptPath $newRecord $null
      }
    }
  }
  catch {
    $swapFailure = $_
    if ($receiptCommitted) {
      Write-Warning "New distribution and rollback are verified. Inspect the retired rollback recorded in $receiptPath. $($swapFailure.Exception.Message)"
      return
    }
    $swapRecoveryErrors = [Collections.Generic.List[string]]::new()
    if ($swapPromoted) {
      try { [IO.Directory]::Move($swapTarget, $swapStaging) }
      catch { $swapRecoveryErrors.Add("Cannot return the new runtime to staging: $($_.Exception.Message)") }
    }
    if ($swapMovedPrevious -and !(Test-Path -LiteralPath $swapTarget)) {
      try { [IO.Directory]::Move($swapBackup, $swapTarget) }
      catch { $swapRecoveryErrors.Add("Cannot restore the previous runtime: $($_.Exception.Message)") }
    }
    if ($swapRecoveryErrors.Count) {
      throw "Distribution swap failed: $($swapFailure.Exception.Message). No runtime was deleted. $($swapRecoveryErrors -join '; '). Inspect installed=$swapTarget; verified staging=$swapStaging; previous backup=$swapBackup"
    }
    throw $swapFailure
  }
  finally {
    if ($swapLock) { $swapLock.Dispose() }
  }
}
