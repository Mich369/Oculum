param(
  [Parameter(Mandatory = $true)][long]$RunId,
  [string]$GitHubRepo = 'Mich369/Oculum',
  [switch]$UseRangeDownload,
  [switch]$DeduplicateWindowsRuntime = $true
)

$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$buildRoot = Join-Path $projectRoot 'build'
$distRoot = [IO.Path]::GetFullPath((Join-Path $buildRoot 'distribution'))
$stagingRoot = Join-Path $buildRoot "distribution-fresh-$RunId"
$downloadRoot = Join-Path $buildRoot "distribution-download-$RunId"
$verifier = Join-Path $PSScriptRoot 'verify_distribution.ps1'
if (!(Test-Path -LiteralPath $verifier -PathType Leaf)) { throw 'Distribution verifier missing' }
$swapHelper = Join-Path $PSScriptRoot 'oculum_distribution_swap.ps1'
if (!(Test-Path -LiteralPath $swapHelper -PathType Leaf)) { throw 'Distribution swap helper missing' }
. $swapHelper

function Assert-BuildChild([string]$Path) {
  $resolved = [IO.Path]::GetFullPath($Path)
  if (![string]::Equals([IO.Path]::GetDirectoryName($resolved), $buildRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Unsafe build path: $Path"
  }
  if ((Test-Path -LiteralPath $resolved) -and
      ((Get-Item -LiteralPath $resolved -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw "Build path is a link: $Path"
  }
}

function Join-VerifiedRuntimeFile([string]$Root, [string]$Relative) {
  $path = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
  $prefix = $Root + [IO.Path]::DirectorySeparatorChar
  if ([IO.Path]::IsPathRooted($Relative) -or !$path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Unsafe runtime path: $Relative"
  }
  $item = Get-Item -LiteralPath $path -Force
  if ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw "Expected a regular runtime file: $Relative"
  }
  for ($parent = $item.Directory; $null -ne $parent; $parent = $parent.Parent) {
    if ($parent.Attributes -band [IO.FileAttributes]::ReparsePoint) {
      throw "Runtime path passes through a reparse point: $Relative"
    }
    if ($parent.FullName -eq $Root) { return $item }
  }
  throw "Runtime file is outside staging: $Relative"
}

function Optimize-VerifiedWindowsRuntime([string]$StagingRoot, [object[]]$Files) {
  $root = [IO.Path]::GetFullPath($StagingRoot).TrimEnd([char[]]'\/')
  $records = @{}
  foreach ($record in $Files) {
    $records[([string]$record.path).Replace('\', '/')] = $record
  }
  $linked = 0
  [long]$linkedBytes = 0
  $copyFallback = 0
  foreach ($path in $records.Keys) {
    if ($path -notmatch '^windows/((?:[^/]+\.dll|oculum\.exe)|data/(?:app\.so|icudtl\.dat|flutter_assets/.+))$') { continue }
    $relative = $Matches[1]
    $sourceRecord = $records[$path]
    $source = $null
    foreach ($destination in @($relative, "windows-test/$relative")) {
      $targetRecord = $records[$destination]
      if ($null -eq $targetRecord -or $targetRecord.bytes -ne $sourceRecord.bytes -or $targetRecord.sha256 -ne $sourceRecord.sha256) { continue }
      if ($null -eq $source) {
        $source = Join-VerifiedRuntimeFile $root $path
        if ($source.LinkType -or $source.Length -ne $sourceRecord.bytes -or
            (Get-FileHash -LiteralPath $source.FullName -Algorithm SHA256).Hash -ne $sourceRecord.sha256) {
          throw "Runtime source changed before deduplication: $path"
        }
      }
      $target = Join-VerifiedRuntimeFile $root $destination
      if ($target.LinkType -or $target.Length -ne $targetRecord.bytes -or
          (Get-FileHash -LiteralPath $target.FullName -Algorithm SHA256).Hash -ne $targetRecord.sha256) {
        throw "Runtime destination changed before deduplication: $destination"
      }
      $temporary = Join-Path $target.DirectoryName ('.oculum-link-' + [guid]::NewGuid().ToString('N'))
      $backup = "$temporary-original"
      try {
        New-Item -ItemType HardLink -Path $temporary -Value $source.FullName -ErrorAction Stop | Out-Null
      } catch {
        if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
        $copyFallback++
        continue
      }
      try {
        [IO.File]::Move($target.FullName, $backup)
        try {
          [IO.File]::Move($temporary, $target.FullName)
        } catch {
          [IO.File]::Move($backup, $target.FullName)
          throw
        }
        [IO.File]::Delete($backup)
      } finally {
        if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
      }
      $linked++
      $linkedBytes += $sourceRecord.bytes
    }
  }
  return [pscustomobject]@{ files = $linked; bytes = $linkedBytes; copiesRetained = $copyFallback }
}

function Get-CommitDistributionDocuments([string]$ProjectRoot, [string]$Commit) {
  $documents = [ordered]@{
    'titoli-statistiche-critici.md' = 'LEGGIMI-MODIFICHE.md'
    'temi-oculum.md' = 'LEGGIMI-TEMI.md'
    'pawn-catalogo-permessi.md' = 'LEGGIMI-PAWN-CATALOGO.md'
    'skill-art-dadi-turni.md' = 'LEGGIMI-SKILL-ART.md'
  }
  foreach ($name in @('OCULUM_REGOLE_CONFERMATE.md', 'manuale-consultazione.md', 'combattimento-parser-2026-10-18.md', 'REGISTRO_AGGIORNAMENTI.md', 'VERIFICA_MOSTRI_AGGIUNTI.md', 'ULTIMO_AGGIORNAMENTO.md')) {
    $documents[$name] = $name
  }

  $git = (Get-Command git -CommandType Application -TotalCount 1).Source
  $contents = [ordered]@{}
  foreach ($document in $documents.GetEnumerator()) {
    $process = [Diagnostics.Process]::new()
    $process.StartInfo.FileName = $git
    $process.StartInfo.WorkingDirectory = $ProjectRoot
    $process.StartInfo.Arguments = "cat-file blob ${Commit}:docs/$($document.Key)"
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.RedirectStandardOutput = $true
    $output = [IO.MemoryStream]::new()
    try {
      if (!$process.Start()) { throw 'Cannot start Git to read release documentation' }
      # Stream the blob bytes directly to preserve encoding and line endings.
      $process.StandardOutput.BaseStream.CopyTo($output)
      $process.WaitForExit()
      if ($process.ExitCode -ne 0) { throw "Cannot read docs/$($document.Key) from commit $Commit" }
      $contents[$document.Value] = $output.ToArray()
    } finally {
      $output.Dispose()
      $process.Dispose()
    }
  }
  return $contents
}

function Test-InstalledReleaseDocumentation([string]$Root, [System.Collections.IDictionary]$Documents) {
  # Older installers copied checked-out files, which could have CRLF line endings.
  # Decode one byte per character so the comparison permits only that conversion.
  $byteEncoding = [Text.Encoding]::GetEncoding(28591)
  foreach ($document in $Documents.GetEnumerator()) {
    $path = Join-Path $Root $document.Key
    if (![IO.File]::Exists($path)) { return $false }
    $installedText = $byteEncoding.GetString([IO.File]::ReadAllBytes($path)).Replace("`r`n", "`n")
    $committedText = $byteEncoding.GetString($document.Value).Replace("`r`n", "`n")
    if (![string]::Equals($installedText, $committedText, [StringComparison]::Ordinal)) { return $false }
  }
  return $true
}

$runJson = & gh api "repos/$GitHubRepo/actions/runs/$RunId"
if ($LASTEXITCODE -ne 0) { throw 'Cannot read GitHub run' }
$run = $runJson | ConvertFrom-Json
$commit = (& git -C $projectRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $run.head_sha -ne $commit -or $run.conclusion -ne 'success') {
  throw 'Only a successful build of the current commit can be installed'
}
function Assert-CurrentBuildSources {
  $currentCommit = (& git -C $projectRoot rev-parse HEAD).Trim()
  if ($LASTEXITCODE -ne 0 -or $currentCommit -ne $commit) {
    throw 'Repository commit changed while preparing distribution; verified packages remain in staging'
  }
  $pendingSources = @(& git -C $projectRoot status --porcelain -- lib assets windows android ios macos linux web pubspec.yaml pubspec.lock)
  if ($LASTEXITCODE -ne 0 -or $pendingSources.Count) { throw 'Commit the current build sources before installing GitHub packages' }
}
Assert-CurrentBuildSources
foreach ($path in @($distRoot, $stagingRoot, $downloadRoot)) { Assert-BuildChild $path }
$releaseDocuments = $null
$installedReceipt = Join-Path $distRoot 'BUILD-VERIFICATE.json'
if (Test-Path -LiteralPath $installedReceipt -PathType Leaf) {
  $receiptFile = Get-Item -LiteralPath $installedReceipt -Force
  if ($receiptFile.Attributes -band [IO.FileAttributes]::ReparsePoint) {
    throw 'Installed distribution receipt is a link'
  }
  $installed = Get-Content -LiteralPath $installedReceipt -Raw | ConvertFrom-Json
  if ($installed.commit -eq $commit -and $installed.githubRun -eq $run.html_url) {
    & $verifier -ExpectedCommit $commit -DistributionRoot $distRoot
    $releaseDocuments = Get-CommitDistributionDocuments $projectRoot $commit
    if (Test-InstalledReleaseDocumentation $distRoot $releaseDocuments) {
      Write-Host "GitHub run $RunId is already installed and verified. No new stage or backup was created."
      return
    }
  }
}
Assert-OculumRollbackEnvironment
if ((Test-Path -LiteralPath $stagingRoot) -or (Test-Path -LiteralPath $downloadRoot)) {
  throw 'Fresh staging path already exists; inspect it before retrying'
}
New-Item -ItemType Directory -Path $stagingRoot, $downloadRoot | Out-Null
# Download every artifact of this successful run, including UI evidence.
$downloadArgs = @('run', 'download', "$RunId", '--repo', $GitHubRepo, '--dir', $downloadRoot)
if (!$UseRangeDownload) { & gh @downloadArgs }
if ($UseRangeDownload -or $LASTEXITCODE -ne 0) {
  # Some Windows TLS intermediaries reject the Go client's artifact download.
  # Download smaller ranges from signed URLs to avoid interrupted TLS streams.
  # Authentication remains only in process memory.
  Add-Type -AssemblyName System.Net.Http
  $artifactsJson = & gh api "repos/$GitHubRepo/actions/runs/$RunId/artifacts" --paginate
  if ($LASTEXITCODE -ne 0) { throw 'Cannot list GitHub artifacts' }
  $artifacts = ($artifactsJson | ConvertFrom-Json).artifacts
  $taskToken = (& gh auth token).Trim()
  if (!$taskToken) { throw 'GitHub artifact authentication unavailable' }
  try {
    foreach ($artifact in $artifacts) {
      if ($artifact.expired -or $artifact.name -notmatch '^[A-Za-z0-9_-]+$') {
        throw 'Invalid or expired artifact'
      }
      $archivePath = Join-Path $downloadRoot "$($artifact.name).download.zip"
      $taskHandler = [System.Net.Http.HttpClientHandler]::new()
      $taskHandler.AllowAutoRedirect = $false
      $taskClient = [System.Net.Http.HttpClient]::new($taskHandler)
      try {
        $taskClient.Timeout = [TimeSpan]::FromMinutes(5)
        $taskClient.DefaultRequestHeaders.Add('User-Agent', 'Oculum-distribution')
        $taskRequest = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Get, $artifact.archive_download_url)
        $taskRequest.Headers.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $taskToken)
        try {
          $taskResponse = $taskClient.SendAsync($taskRequest).GetAwaiter().GetResult()
          if ([int]$taskResponse.StatusCode -ne 302) { throw 'Artifact download redirect failed' }
        } finally { $taskRequest.Dispose() }
        $taskDownloadUri = $taskResponse.Headers.Location.AbsoluteUri
        $taskResponse.Dispose()
        if (!$taskDownloadUri) { throw 'Artifact download redirect missing' }
        Write-Host "Downloading $($artifact.name) with verified ranges"
        $taskTotal = [long]$artifact.size_in_bytes
        $taskArchive = [IO.File]::Open($archivePath, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try {
          for ($taskStart = 0L; $taskStart -lt $taskTotal; $taskStart += 4MB) {
            $taskEnd = [Math]::Min($taskTotal - 1, $taskStart + 4MB - 1)
            for ($taskAttempt = 1; $taskAttempt -le 4; $taskAttempt++) {
              $taskRangeRequest = $null
              $taskRangeResponse = $null
              try {
                # The GitHub token is used only for the API redirect, never
                # sent to the artifact storage host.
                $taskRangeRequest = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Get, $taskDownloadUri)
                $taskRangeRequest.Headers.Range = [System.Net.Http.Headers.RangeHeaderValue]::new($taskStart, $taskEnd)
                $taskRangeResponse = $taskClient.SendAsync($taskRangeRequest).GetAwaiter().GetResult()
                if ([int]$taskRangeResponse.StatusCode -ne 206) { throw 'Artifact range request failed' }
                $taskContentRange = $taskRangeResponse.Content.Headers.ContentRange
                if ($taskContentRange.From -ne $taskStart -or $taskContentRange.To -ne $taskEnd -or $taskContentRange.Length -ne $taskTotal) {
                  throw 'Artifact range boundaries mismatch'
                }
                $taskBytes = $taskRangeResponse.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
                if ($taskBytes.LongLength -ne $taskEnd - $taskStart + 1) { throw 'Artifact range length mismatch' }
                $taskArchive.Write($taskBytes, 0, $taskBytes.Length)
                break
              } catch {
                if ($taskAttempt -eq 4) { throw }
                Start-Sleep -Seconds (2 * $taskAttempt)
              } finally {
                if ($taskRangeResponse) { $taskRangeResponse.Dispose() }
                if ($taskRangeRequest) { $taskRangeRequest.Dispose() }
              }
            }
          }
        } finally { $taskArchive.Dispose() }
        if ((Get-Item -LiteralPath $archivePath).Length -ne $taskTotal) { throw 'Artifact archive size mismatch' }
        if ($artifact.digest -match '^sha256:([0-9a-fA-F]{64})$') {
          if ((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash -ne $Matches[1]) { throw 'Artifact SHA256 mismatch' }
        }
      } finally {
        $taskClient.Dispose()
        $taskHandler.Dispose()
      }
      Expand-Archive -LiteralPath $archivePath -DestinationPath (Join-Path $downloadRoot $artifact.name) -Force
      Remove-Item -LiteralPath $archivePath -Force
    }
  } finally {
    $taskToken = $null
  }
}
function Assert-DownloadedItem([string]$Path) {
  $resolved = [IO.Path]::GetFullPath($Path)
  if (!$resolved.StartsWith($downloadRoot + '\', [StringComparison]::OrdinalIgnoreCase) -or
      ((Get-Item -LiteralPath $resolved -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw "Unsafe downloaded artifact path: $Path"
  }
}

$packages = @('Oculum-Windows.zip', 'Oculum-Test-Windows.zip', 'Oculum-Android-release.apk', 'Oculum-Android-release.aab', 'Oculum-macOS.zip', 'Oculum-iOS-unsigned.ipa', 'Oculum-Linux-x64.tar.gz', 'Oculum-Web.zip')
foreach ($package in $packages) {
  $matches = @(Get-ChildItem -LiteralPath $downloadRoot -Recurse -File | Where-Object Name -eq $package)
  if ($matches.Count -ne 1 -or $matches[0].Length -eq 0) { throw "Missing/ambiguous package: $package" }
  Assert-DownloadedItem $matches[0].FullName
  Move-Item -LiteralPath $matches[0].FullName -Destination (Join-Path $stagingRoot $package)
}
# Reuse the verified folder artifacts rather than storing duplicate runtimes.
foreach ($edition in @('windows', 'windows-test')) {
  $artifact = if ($edition -eq 'windows') { 'Oculum-Windows-Folder' } else { 'Oculum-Test-Windows-Folder' }
  $folder = Join-Path $downloadRoot $artifact
  if (Test-Path -LiteralPath $folder -PathType Container) {
    Assert-DownloadedItem $folder
    Move-Item -LiteralPath $folder -Destination (Join-Path $stagingRoot $edition)
  } else {
    $archive = if ($edition -eq 'windows') { 'Oculum-Windows.zip' } else { 'Oculum-Test-Windows.zip' }
    Expand-Archive -LiteralPath (Join-Path $stagingRoot $archive) -DestinationPath (Join-Path $stagingRoot $edition)
  }
}
foreach ($edition in @('windows', 'windows-test')) {
  $folder = Join-Path $stagingRoot $edition
  $exe = if ($edition -eq 'windows') { 'oculum.exe' } else { 'Oculum-Test.exe' }
  foreach ($required in @($exe, 'flutter_windows.dll', 'WebView2Loader.dll', 'data/app.so', 'data/icudtl.dat', 'data/flutter_assets')) {
    if (!(Test-Path -LiteralPath (Join-Path $folder $required))) { throw "$edition missing $required" }
  }
}
if ((Get-FileHash (Join-Path $stagingRoot 'windows/data/app.so')).Hash -eq
    (Get-FileHash (Join-Path $stagingRoot 'windows-test/data/app.so')).Hash) {
  throw 'Windows Test payload must use an isolated save profile'
}
# The standalone EXE needs the full Flutter runtime alongside it.
Get-ChildItem -LiteralPath (Join-Path $stagingRoot 'windows') | Copy-Item -Destination $stagingRoot -Recurse
Get-ChildItem -LiteralPath $downloadRoot -Directory | Where-Object Name -NotIn @('Oculum-Windows', 'Oculum-Test-Windows', 'Oculum-Android', 'Oculum-macOS', 'Oculum-iOS-unsigned', 'Oculum-Linux', 'Oculum-Web') | ForEach-Object {
  Assert-DownloadedItem $_.FullName
  Move-Item -LiteralPath $_.FullName -Destination (Join-Path $stagingRoot $_.Name)
}
if ($null -eq $releaseDocuments) {
  $releaseDocuments = Get-CommitDistributionDocuments $projectRoot $commit
}
foreach ($document in $releaseDocuments.GetEnumerator()) {
  [IO.File]::WriteAllBytes((Join-Path $stagingRoot $document.Key), $document.Value)
}
$manifest = [ordered]@{
  commit = $commit
  githubRun = $run.html_url
  installedAtUtc = [DateTime]::UtcNow.ToString('o')
  files = @(Get-ChildItem -LiteralPath $stagingRoot -Recurse -File | ForEach-Object {
    @{ path = $_.FullName.Substring($stagingRoot.Length + 1); bytes = $_.Length; sha256 = (Get-FileHash -LiteralPath $_.FullName).Hash }
  })
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $stagingRoot 'BUILD-VERIFICATE.json') -Encoding utf8
& $verifier -ExpectedCommit $commit -DistributionRoot $stagingRoot
if ($DeduplicateWindowsRuntime) {
  # Same-build runtime files only. ZIPs, mutable settings and previous
  # distributions retain independent files. Disable if independent copies of
  # the same runtime are needed in each folder.
  $dedup = Optimize-VerifiedWindowsRuntime $stagingRoot $manifest.files
  Write-Host "Windows staging hard links=$($dedup.files) duplicate logical bytes=$($dedup.bytes) copies retained=$($dedup.copiesRetained)"
}
$active = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
  $_.Path -and $_.Path.StartsWith($distRoot + '\', [StringComparison]::OrdinalIgnoreCase)
})
if ($active.Count) { throw 'Save and close the app running from distribution before replacing it. Fresh packages are ready in staging.' }
foreach ($record in $manifest.files) {
  $verifiedFile = Join-Path $stagingRoot $record.path
  if ((Get-FileHash -LiteralPath $verifiedFile -Algorithm SHA256).Hash -ne $record.sha256) {
    throw "Staging changed before replacement: $($record.path)"
  }
}
$backupRoot = Join-Path $buildRoot ("distribution-backup-$RunId-" + (Get-Date -Format 'yyyyMMdd-HHmmssfff'))
foreach ($path in @($distRoot, $stagingRoot, $backupRoot)) { Assert-BuildChild $path }
Invoke-OculumDistributionSwap -BuildRoot $buildRoot -DistributionRoot $distRoot -StagingRoot $stagingRoot -BackupRoot $backupRoot -RetainSingleVerifiedBackup -VerifyRollback {
  param($rollbackPath)
  $receipt = Get-Content -LiteralPath (Join-Path $rollbackPath 'BUILD-VERIFICATE.json') -Raw | ConvertFrom-Json
  & $verifier -ExpectedCommit $receipt.commit -DistributionRoot $rollbackPath | Out-Null
} -BeforeSwap {
  Assert-CurrentBuildSources
  $activeBeforeSwap = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -and $_.Path.StartsWith($distRoot + '\', [StringComparison]::OrdinalIgnoreCase)
  })
  if ($activeBeforeSwap.Count) { throw 'Save and close the app running from distribution before replacing it. Fresh packages are ready in staging.' }
} -VerifyInstalled {
  & $verifier -ExpectedCommit $commit -DistributionRoot $distRoot
  Assert-CurrentBuildSources
}
Assert-BuildChild $downloadRoot
Remove-Item -LiteralPath $downloadRoot -Recurse -Force
Write-Host "Installed only fresh GitHub builds for $commit in $distRoot; previous distribution preserved in $backupRoot"
