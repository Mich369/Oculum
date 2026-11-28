# Dot-source this helper from the Windows updater. Preview never writes to disk.

function Assert-OculumIncrementalOrdinaryPath([string]$Path) {
  for ($current = $Path; $current; $current = [IO.Path]::GetDirectoryName($current)) {
    try { $attributes = [IO.File]::GetAttributes($current) }
    catch [IO.FileNotFoundException], [IO.DirectoryNotFoundException] { continue }
    if ($attributes -band [IO.FileAttributes]::ReparsePoint) {
      throw "Incremental update cannot use a linked path: $current"
    }
  }
}

function Get-OculumIncrementalChild([string]$Root, [string]$RelativePath) {
  $path = [IO.Path]::GetFullPath([IO.Path]::Combine($Root, $RelativePath.Replace('/', '\')))
  $prefix = $Root.TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
  if (!$path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Path is outside the incremental update root: $RelativePath"
  }
  Assert-OculumIncrementalOrdinaryPath $path
  return $path
}

function Assert-OculumIncrementalRuntimePath([string]$Path, [string]$Executable) {
  if ($Path.Length -eq 0 -or $Path.Length -gt 240 -or $Path -match '[\x00-\x1f\x7f\\:<>"|?*]') {
    throw "Invalid runtime file path: $Path"
  }
  foreach ($part in $Path.Split('/')) {
    if (!$part -or $part -match '[ .]$|^(?:CON|PRN|AUX|NUL|CONIN\$|CONOUT\$|COM[1-9\u00B9\u00B2\u00B3]|LPT[1-9\u00B9\u00B2\u00B3])(?:\.|$)') {
      throw "Invalid Windows runtime path: $Path"
    }
    if ($part -match '^(?:profiles?(?:[-_.].*)?|saves?(?:[-_.].*)?|savegames?|salvataggi|userdata|user[-_]data|oculum_save_blobs.*|shared_preferences.*|oculum_progress_journal.*|oculum_backup.*|\.oculum[-_].*)$') {
      throw "A local data path cannot be managed by the incremental update: $Path"
    }
  }
  if ($Path -ine $Executable -and $Path -ine 'native_assets.json' -and $Path -notmatch '^[^/]+\.dll$|^data/.+') {
    throw "Unexpected file in the Windows runtime manifest: $Path"
  }
}

function Test-OculumIncrementalInteger($Value) {
  return ($Value -is [int] -or $Value -is [long]) -and $Value -ge 0
}

function Read-OculumIncrementalManifest {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$ExpectedSha256,
    [Parameter(Mandatory = $true)][ValidateSet('normal','test')][string]$Edition
  )
  $path = [IO.Path]::GetFullPath($Path)
  Assert-OculumIncrementalOrdinaryPath $path
  $length = [IO.FileInfo]::new($path).Length
  if ($ExpectedSha256 -notmatch '^[a-f0-9]{64}$' -or $length -le 0 -or $length -gt 48MB) {
    throw 'Invalid manifest size or trusted manifest digest'
  }
  $raw = [IO.File]::ReadAllBytes($path)
  $digest = [Security.Cryptography.SHA256]::Create()
  try { $actual = [BitConverter]::ToString($digest.ComputeHash($raw)).Replace('-', '') }
  finally { $digest.Dispose() }
  if ($raw.Length -ne $length -or $actual -ine $ExpectedSha256) { throw 'Manifest SHA-256 verification failed' }
  $json = [Text.UTF8Encoding]::new($false, $true).GetString($raw).TrimStart([char]0xfeff)
  $manifest = ConvertFrom-Json -InputObject $json -ErrorAction Stop
  if (!(Test-OculumIncrementalInteger $manifest.schemaVersion) -or
      $manifest.schemaVersion -ne 1 -or $manifest.platform -isnot [string] -or $manifest.platform -cne 'windows' -or
      $manifest.edition -isnot [string] -or $manifest.edition -cne $Edition -or
      $manifest.commit -isnot [string] -or $manifest.commit -cnotmatch '^[a-f0-9]{40}$' -or
      !(Test-OculumIncrementalInteger $manifest.runId) -or $manifest.runId -eq 0 -or
      !(Test-OculumIncrementalInteger $manifest.package.bytes) -or
      $manifest.package.bytes -le 0 -or $manifest.package.bytes -gt 2GB -or
      $manifest.package.sha256 -isnot [string] -or $manifest.package.sha256 -cnotmatch '^[a-f0-9]{64}$' -or
      $manifest.files -isnot [array] -or
      $manifest.files.Count -eq 0 -or $manifest.files.Count -gt 100000) {
    throw 'Unsupported manifest, Windows edition or ZIP package'
  }
  $exe = if ($Edition -eq 'test') { 'Oculum-Test.exe' } else { 'oculum.exe' }
  $archive = if ($Edition -eq 'test') { 'Oculum-Test-Windows-Folder.zip' } else { 'Oculum-Windows-Folder.zip' }
  $officialUrl = "https://github.com/Mich369/Oculum/releases/download/oculum-build-$($manifest.runId)/$archive"
  if ($manifest.package.url -isnot [string] -or $manifest.package.url -cne $officialUrl) {
    throw 'Expected the official Oculum GitHub release asset for this edition'
  }

  $files = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
  $directories = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $lengths = [Collections.Generic.Dictionary[string,long]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach ($row in $manifest.files) {
    if ($row.path -isnot [string] -or $row.sha256 -isnot [string] -or $row.sha256 -cnotmatch '^[a-f0-9]{64}$' -or
        !(Test-OculumIncrementalInteger $row.bytes) -or $row.bytes -gt 2GB -or
        !(Test-OculumIncrementalInteger $row.offset) -or $row.offset -ge $manifest.package.bytes -or
        !(Test-OculumIncrementalInteger $row.compressedBytes) -or
        $row.compressedBytes -gt ($manifest.package.bytes - $row.offset) -or
        !(Test-OculumIncrementalInteger $row.method) -or $row.method -notin @(0,8) -or
        ($row.method -eq 0 -and $row.compressedBytes -ne $row.bytes) -or
        ($row.method -eq 8 -and $row.compressedBytes -eq 0)) {
      throw "Invalid ZIP record: $($row.path)"
    }
    Assert-OculumIncrementalRuntimePath $row.path $exe
    if ($files.ContainsKey($row.path) -or $directories.Contains($row.path)) {
      throw "Duplicate or conflicting runtime path: $($row.path)"
    }
    $files.Add($row.path, $row)
    for ($parent = [IO.Path]::GetDirectoryName($row.path); $parent; $parent = [IO.Path]::GetDirectoryName($parent)) {
      $parentPath = $parent.Replace('\', '/')
      if ($files.ContainsKey($parentPath)) { throw "File conflicts with directory: $parentPath" }
      [void]$directories.Add($parentPath)
    }
    if ($lengths.ContainsKey($row.sha256) -and $lengths[$row.sha256] -ne $row.bytes) {
      throw 'Inconsistent file length for a SHA-256 digest'
    }
    $lengths[$row.sha256] = $row.bytes
  }
  $end = 0L
  foreach ($row in @($manifest.files | Sort-Object -Property offset)) {
    if ($row.compressedBytes -eq 0) { continue }
    if ($row.offset -lt $end) { throw 'Overlapping ZIP file ranges' }
    $end = $row.offset + $row.compressedBytes
  }
  foreach ($required in @($exe, 'flutter_windows.dll', 'WebView2Loader.dll', 'data/app.so',
      'data/icudtl.dat', 'data/flutter_assets/AssetManifest.bin')) {
    if (!$files.ContainsKey($required) -or $files[$required].bytes -eq 0) {
      throw "Incomplete Windows runtime manifest: $required"
    }
  }
  return [pscustomobject]@{ Path = $path; Sha256 = $ExpectedSha256; Value = $manifest; Files = $files }
}

function Get-OculumIncrementalFileDigest([string]$Path) {
  $stream = [IO.File]::OpenRead($Path)
  try {
    $digest = [Security.Cryptography.SHA256]::Create()
    try { [BitConverter]::ToString($digest.ComputeHash($stream)).Replace('-', '') }
    finally { $digest.Dispose() }
  } finally { $stream.Dispose() }
}

function Test-OculumIncrementalFile([string]$Path, $Record) {
  if (![IO.File]::Exists($Path)) { return $false }
  Assert-OculumIncrementalOrdinaryPath $Path
  return [IO.FileInfo]::new($Path).Length -eq $Record.bytes -and
    (Get-OculumIncrementalFileDigest $Path) -ieq $Record.sha256
}

function Get-OculumIncrementalPlan {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$InstalledRoot,
    [Parameter(Mandatory = $true)][string]$WorkRoot,
    [Parameter(Mandatory = $true)][ValidateSet('normal','test')][string]$Edition,
    [Parameter(Mandatory = $true)][string]$TargetManifestPath,
    [Parameter(Mandatory = $true)][string]$TargetManifestSha256,
    [string]$SourceManifestPath,
    [string]$SourceManifestSha256,
    [string]$CachedObjectsRoot
  )
  $installed = [IO.Path]::GetFullPath($InstalledRoot).TrimEnd([char[]]'\/')
  $work = [IO.Path]::GetFullPath($WorkRoot).TrimEnd([char[]]'\/')
  foreach ($root in @($installed, $work)) {
    if ($root -ieq [IO.Path]::GetPathRoot($root).TrimEnd([char[]]'\/') -or ![IO.Directory]::Exists($root)) {
      throw "Update root must be an existing install or staging folder: $root"
    }
    Assert-OculumIncrementalOrdinaryPath $root
  }
  if ($installed -ieq $work -or $work.StartsWith($installed + '\', [StringComparison]::OrdinalIgnoreCase) -or
      $installed.StartsWith($work + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The install and incremental staging directories must be separate'
  }
  $target = Read-OculumIncrementalManifest $TargetManifestPath $TargetManifestSha256 $Edition
  $source = $null
  if ($SourceManifestPath -or $SourceManifestSha256) {
    if (!$SourceManifestPath -or !$SourceManifestSha256) { throw 'Source manifest requires its trusted digest' }
    $source = Read-OculumIncrementalManifest $SourceManifestPath $SourceManifestSha256 $Edition
  }
  $exe = if ($Edition -eq 'test') { 'Oculum-Test.exe' } else { 'oculum.exe' }
  if (![IO.File]::Exists((Get-OculumIncrementalChild $installed $exe))) {
    throw 'The installed folder does not contain the selected Oculum edition'
  }
  if ($CachedObjectsRoot) {
    $objects = [IO.Path]::GetFullPath($CachedObjectsRoot).TrimEnd([char[]]'\/')
    if ([IO.Path]::GetDirectoryName($objects) -ine [IO.Path]::GetDirectoryName($work) -or
        [IO.Path]::GetFileName($objects) -cnotmatch '^oculum-update-objects-[a-f0-9]{64}$' -or
        $objects -ieq $installed -or $objects -ieq $work -or
        $objects.StartsWith($installed + '\', [StringComparison]::OrdinalIgnoreCase) -or
        $installed.StartsWith($objects + '\', [StringComparison]::OrdinalIgnoreCase)) {
      throw 'Incremental cache must be a separate Oculum folder beside the working directory'
    }
    Assert-OculumIncrementalOrdinaryPath $objects
    if ([IO.File]::Exists($objects)) { throw 'Incremental cache path is already a file' }
  } else {
    $objects = Get-OculumIncrementalChild $work 'objects'
  }
  $changed = [Collections.Generic.List[object]]::new()
  $satisfied = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
  $removed = [Collections.Generic.List[object]]::new()
  $reused = 0
  foreach ($row in $target.Value.files) {
    $local = Get-OculumIncrementalChild $installed $row.path
    if (Test-OculumIncrementalFile $local $row) {
      $satisfied[$row.sha256] = $local
      $reused++
    } else {
      $changed.Add($row)
    }
  }
  $downloads = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
  $downloadBytes = 0L
  foreach ($row in @($changed | Sort-Object -Property compressedBytes)) {
    if ($satisfied.ContainsKey($row.sha256) -or $downloads.ContainsKey($row.sha256)) { continue }
    $cached = Get-OculumIncrementalChild $objects "$($row.sha256).bin"
    if (Test-OculumIncrementalFile $cached $row) {
      $satisfied[$row.sha256] = $cached
    } else {
      $downloads.Add($row.sha256, $row)
      $downloadBytes += $row.compressedBytes
    }
  }
  if ($source) {
    foreach ($row in $source.Value.files) {
      if (!$target.Files.ContainsKey($row.path) -and
          (Test-OculumIncrementalFile (Get-OculumIncrementalChild $installed $row.path) $row)) {
        $removed.Add($row)
      }
    }
  }
  return [pscustomobject]@{
    InstalledRoot = $installed; WorkRoot = $work; ObjectsRoot = $objects; Target = $target; Source = $source
    DownloadCount = @($downloads.Values | Where-Object compressedBytes -gt 0).Count
    DownloadBytes = $downloadBytes; DownloadMB = $downloadBytes / 1000000; DownloadMiB = $downloadBytes / 1MB
    ChangedCount = $changed.Count; ChangedPaths = @($changed | ForEach-Object path)
    ReusedCount = $reused; RemoveCount = $removed.Count
    IsNoOp = $changed.Count -eq 0 -and $removed.Count -eq 0
    Satisfied = $satisfied; Downloads = $downloads; Removed = $removed
  }
}

function Copy-OculumIncrementalExactBytes([IO.Stream]$Source, [IO.Stream]$Destination, [long]$Length) {
  $remaining = $Length
  $buffer = [byte[]]::new(65536)
  while ($remaining -gt 0) {
    $count = $Source.Read($buffer, 0, [int][Math]::Min($remaining, $buffer.Length))
    if ($count -eq 0) { throw 'The ZIP entry ended before its declared size' }
    $Destination.Write($buffer, 0, $count)
    $remaining -= $count
  }
  if ($Source.ReadByte() -ne -1) { throw 'The ZIP entry exceeded its declared size' }
}

function Assert-OculumIncrementalRangeResponse($Status, [string]$Range, $Length, [string]$Encoding, $Package, $Record) {
  $start = $Record.offset
  $end = $start + $Record.compressedBytes - 1
  if ([int]$Status -ne 206 -or $Range -cne "bytes $start-${end}/$($Package.bytes)" -or
      ($Length -ge 0 -and $Length -ne $Record.compressedBytes) -or
      ($Encoding -and $Encoding -ine 'identity')) {
    throw 'GitHub did not return the exact requested ZIP range'
  }
}

function Save-OculumIncrementalRange($Package, $Record, [string]$Destination) {
  $url = [Uri]$Package.url
  $response = $null
  try {
    for ($redirect = 0; $redirect -lt 5; $redirect++) {
      if (!$url.IsAbsoluteUri -or $url.Scheme -cne 'https' -or $url.Port -ne 443 -or
          $url.UserInfo -or $url.Fragment -or
          $url.Host -cnotin @('github.com', 'release-assets.githubusercontent.com', 'objects.githubusercontent.com')) {
        throw 'Untrusted GitHub release asset redirect'
      }
      $request = [Net.HttpWebRequest]::Create($url)
      $request.AllowAutoRedirect = $false
      $request.Timeout = 30000
      $request.ReadWriteTimeout = 30000
      $request.AutomaticDecompression = [Net.DecompressionMethods]::None
      $request.AddRange([long]$Record.offset, [long]($Record.offset + $Record.compressedBytes - 1))
      $response = $request.GetResponse()
      if ([int]$response.StatusCode -notin @(301,302,303,307,308)) { break }
      $location = $response.Headers['Location']
      $response.Dispose()
      $response = $null
      $url = [Uri]::new($url, $location)
    }
    if (!$response) { throw 'GitHub release asset redirect limit reached' }
    Assert-OculumIncrementalRangeResponse $response.StatusCode $response.Headers['Content-Range'] `
      $response.ContentLength $response.ContentEncoding $Package $Record
    $destinationStream = [IO.File]::Open($Destination, 'CreateNew', 'Write', 'None')
    try { Copy-OculumIncrementalExactBytes $response.GetResponseStream() $destinationStream $Record.compressedBytes }
    finally { $destinationStream.Dispose() }
  } finally {
    if ($response) { $response.Dispose() }
  }
}

function Save-OculumIncrementalObject($Package, $Record, [string]$ObjectsRoot, [scriptblock]$ReadRange) {
  $destination = Get-OculumIncrementalChild $ObjectsRoot "$($Record.sha256).bin"
  if (Test-OculumIncrementalFile $destination $Record) { return $destination }
  $nonce = [Guid]::NewGuid().ToString('N')
  $compressed = Get-OculumIncrementalChild $ObjectsRoot "$nonce.range"
  $temporary = Get-OculumIncrementalChild $ObjectsRoot "$nonce.partial"
  try {
    $output = [IO.File]::Open($temporary, 'CreateNew', 'Write', 'None')
    try {
      if ($Record.compressedBytes -gt 0) {
        & $ReadRange $Package $Record $compressed | Out-Null
        Assert-OculumIncrementalOrdinaryPath $compressed
        if ([IO.FileInfo]::new($compressed).Length -ne $Record.compressedBytes) { throw 'Incorrect downloaded ZIP range size' }
        $inputStream = [IO.File]::OpenRead($compressed)
        try {
          if ($Record.method -eq 0) {
            Copy-OculumIncrementalExactBytes $inputStream $output $Record.bytes
          } else {
            $deflate = [IO.Compression.DeflateStream]::new($inputStream, [IO.Compression.CompressionMode]::Decompress, $true)
            try { Copy-OculumIncrementalExactBytes $deflate $output $Record.bytes }
            finally { $deflate.Dispose() }
          }
        } finally { $inputStream.Dispose() }
      }
    } finally { $output.Dispose() }
    if (!(Test-OculumIncrementalFile $temporary $Record)) { throw "SHA-256 verification failed for $($Record.path)" }
    if ([IO.File]::Exists($destination)) { [IO.File]::Delete($destination) }
    [IO.File]::Move($temporary, $destination)
    return $destination
  } finally {
    [IO.File]::Delete($temporary)
    [IO.File]::Delete($compressed)
  }
}

function Get-OculumIncrementalStageEntries([string]$Root) {
  $pending = [Collections.Generic.Stack[string]]::new()
  $pending.Push($Root)
  while ($pending.Count -gt 0) {
    $directory = $pending.Pop()
    foreach ($entry in Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop) {
      if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked staged runtime entry: $($entry.FullName)" }
      [pscustomobject]@{
        Path = $entry.FullName.Substring($Root.Length + 1).Replace('\', '/')
        IsDirectory = $entry.PSIsContainer
      }
      if ($entry.PSIsContainer) { $pending.Push($entry.FullName) }
    }
  }
}

function New-OculumIncrementalStage {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]$Plan,
    [scriptblock]$ReadRange = { param($package, $record, $file) Save-OculumIncrementalRange $package $record $file }
  )
  if ($Plan.IsNoOp) {
    return [pscustomobject]@{
      IsNoOp = $true; RuntimeRoot = $null; RemoveRootEntries = @()
      DownloadCount = 0; DownloadBytes = 0L
    }
  }
  foreach ($root in @($Plan.WorkRoot, $Plan.ObjectsRoot, $Plan.InstalledRoot)) { Assert-OculumIncrementalOrdinaryPath $root }
  $lock = $null
  if ($Plan.ChangedCount -gt 0) {
    [void][IO.Directory]::CreateDirectory($Plan.ObjectsRoot)
    $lockPath = Get-OculumIncrementalChild $Plan.ObjectsRoot 'incremental.lock'
    $lock = [IO.File]::Open($lockPath, 'OpenOrCreate', 'ReadWrite', 'None')
  }
  try {
    $objects = [Collections.Generic.Dictionary[string,string]]::new($Plan.Satisfied, [StringComparer]::OrdinalIgnoreCase)
    $downloadCount = 0
    $downloadBytes = 0L
    foreach ($file in @($Plan.Downloads.Values | Sort-Object -Property compressedBytes, path)) {
      $cached = Get-OculumIncrementalChild $Plan.ObjectsRoot "$($file.sha256).bin"
      if (Test-OculumIncrementalFile $cached $file) {
        $objects[$file.sha256] = $cached
      } else {
        $objects[$file.sha256] = Save-OculumIncrementalObject $Plan.Target.Value.package $file $Plan.ObjectsRoot $ReadRange
        if ($file.compressedBytes -gt 0) {
          $downloadCount++
          $downloadBytes += $file.compressedBytes
        }
      }
    }
    $runtime = Get-OculumIncrementalChild $Plan.WorkRoot ("incremental-runtime-" + [Guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($runtime)
    foreach ($relative in $Plan.ChangedPaths) {
      $file = $Plan.Target.Files[$relative]
      $copy = Get-OculumIncrementalChild $runtime $relative
      $original = $objects[$file.sha256]
      Assert-OculumIncrementalOrdinaryPath $original
      [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($copy))
      [IO.File]::Copy($original, $copy)
    }
    $stage = [pscustomobject]@{
      IsNoOp = $false; RuntimeRoot = $runtime
      RemoveRootEntries = @($Plan.Removed | Where-Object { $_.path -notlike '*/*' } | ForEach-Object path)
      DownloadCount = $downloadCount; DownloadBytes = $downloadBytes
    }
    Assert-OculumIncrementalStageReady $Plan $stage
    return $stage
  } finally { if ($lock) { $lock.Dispose() } }
}

function Assert-OculumIncrementalStageReady($Plan, $Stage, [string]$ExpectedStagingParent = $Plan.WorkRoot) {
  $parent = [IO.Path]::GetFullPath($ExpectedStagingParent)
  if ($parent -ine $Plan.WorkRoot -and (
        [IO.Path]::GetDirectoryName($parent) -ine $Plan.InstalledRoot -or
        [IO.Path]::GetFileName($parent) -notmatch '^\.oculum-update-staged-[a-f0-9]{32}$')) {
    throw 'Invalid alternate incremental staging parent'
  }
  $root = [IO.Path]::GetFullPath($Stage.RuntimeRoot)
  if ([IO.Path]::GetDirectoryName($root) -ine $parent -or
      [IO.Path]::GetFileName($root) -notmatch '^incremental-runtime-[a-f0-9]{32}$') {
    throw 'Invalid incremental runtime staging directory'
  }
  Assert-OculumIncrementalOrdinaryPath $root
  $changed = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $directories = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach ($relative in $Plan.ChangedPaths) {
    [void]$changed.Add($relative)
    for ($part = [IO.Path]::GetDirectoryName($relative); $part; $part = [IO.Path]::GetDirectoryName($part)) {
      [void]$directories.Add($part.Replace('\', '/'))
    }
  }
  Get-OculumIncrementalStageEntries $root | ForEach-Object {
    if (($_.IsDirectory -and !$directories.Contains($_.Path)) -or
        (!$_.IsDirectory -and !$changed.Contains($_.Path))) {
      throw "Unexpected staged runtime entry: $($_.Path)"
    }
  }
  foreach ($file in $Plan.Target.Value.files) {
    $installed = Get-OculumIncrementalChild $Plan.InstalledRoot $file.path
    if ($changed.Contains($file.path)) {
      if ([IO.Directory]::Exists($installed)) { throw "A local folder occupies a managed file path: $($file.path)" }
      if (!(Test-OculumIncrementalFile (Get-OculumIncrementalChild $root $file.path) $file)) {
        throw "Staged runtime file failed verification: $($file.path)"
      }
    } elseif (!(Test-OculumIncrementalFile $installed $file)) {
      throw "Unchanged runtime file changed after preview: $($file.path)"
    }
  }
  foreach ($file in $Plan.Removed) {
    if (!(Test-OculumIncrementalFile (Get-OculumIncrementalChild $Plan.InstalledRoot $file.path) $file)) {
      throw "Obsolete file changed after preview: $($file.path)"
    }
  }
}
