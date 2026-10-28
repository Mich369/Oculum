function Invoke-OculumDistributionSwap {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$BuildRoot,
    [Parameter(Mandatory = $true)][string]$DistributionRoot,
    [Parameter(Mandatory = $true)][string]$StagingRoot,
    [Parameter(Mandatory = $true)][string]$BackupRoot,
    [Parameter(Mandatory = $true)][scriptblock]$BeforeSwap,
    [Parameter(Mandatory = $true)][scriptblock]$VerifyInstalled
  )

  $ErrorActionPreference = 'Stop'
  $swapBuildRoot = [IO.Path]::GetFullPath($BuildRoot).TrimEnd([char[]]'\/')
  $swapTarget = [IO.Path]::GetFullPath($DistributionRoot).TrimEnd([char[]]'\/')
  $swapStaging = [IO.Path]::GetFullPath($StagingRoot).TrimEnd([char[]]'\/')
  $swapBackup = [IO.Path]::GetFullPath($BackupRoot).TrimEnd([char[]]'\/')
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
  try {
    $swapLock = [IO.File]::Open($swapLockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    & $BeforeSwap
    # Directory.Move is a same-volume directory rename. Unlike PowerShell's
    # Move-Item it cannot move some children before discovering a locked file.
    if (Test-Path -LiteralPath $swapTarget) {
      [IO.Directory]::Move($swapTarget, $swapBackup)
      $swapMovedPrevious = $true
    }
    [IO.Directory]::Move($swapStaging, $swapTarget)
    $swapPromoted = $true
    & $VerifyInstalled
  }
  catch {
    $swapFailure = $_
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
