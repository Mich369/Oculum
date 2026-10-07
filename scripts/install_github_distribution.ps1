param(
  [Parameter(Mandatory = $true)][long]$RunId,
  [string]$GitHubRepo = 'Mich369/Oculum'
)

$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$buildRoot = Join-Path $projectRoot 'build'
$distRoot = [IO.Path]::GetFullPath((Join-Path $buildRoot 'distribution'))
$stagingRoot = Join-Path $buildRoot "distribution-fresh-$RunId"
$downloadRoot = Join-Path $buildRoot "distribution-download-$RunId"

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

$runJson = & gh api "repos/$GitHubRepo/actions/runs/$RunId"
if ($LASTEXITCODE -ne 0) { throw 'Cannot read GitHub run' }
$run = $runJson | ConvertFrom-Json
$commit = (& git -C $projectRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $run.head_sha -ne $commit -or $run.conclusion -ne 'success') {
  throw 'Only a successful build of the current commit can be installed'
}
foreach ($path in @($distRoot, $stagingRoot, $downloadRoot)) { Assert-BuildChild $path }
if ((Test-Path -LiteralPath $stagingRoot) -or (Test-Path -LiteralPath $downloadRoot)) {
  throw 'Fresh staging path already exists; inspect it before retrying'
}
New-Item -ItemType Directory -Path $stagingRoot, $downloadRoot | Out-Null
# Download every artifact of this successful run, including UI evidence.
$downloadArgs = @('run', 'download', "$RunId", '--repo', $GitHubRepo, '--dir', $downloadRoot)
& gh @downloadArgs
if ($LASTEXITCODE -ne 0) {
  # Some Windows TLS intermediaries reject the Go client's artifact download.
  # Obtain a signed redirect from GitHub, then download with curl over TLS 1.2.
  # Authentication remains only in process memory.
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
        $taskClient.DefaultRequestHeaders.Add('Authorization', "Bearer $taskToken")
        $taskClient.DefaultRequestHeaders.Add('User-Agent', 'Oculum-distribution')
        $taskResponse = $taskClient.GetAsync($artifact.archive_download_url).GetAwaiter().GetResult()
        $taskDownloadUri = $taskResponse.Headers.Location.AbsoluteUri
        if (!$taskDownloadUri) { throw 'Artifact download redirect missing' }
        & curl.exe --fail --silent --show-error --location --http1.1 --tls-max 1.2 --retry 3 --output $archivePath $taskDownloadUri
        if ($LASTEXITCODE -ne 0) { throw 'Artifact download failed' }
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
$packages = @('Oculum-Windows.zip', 'Oculum-Test-Windows.zip', 'Oculum-Android-release.apk', 'Oculum-Android-release.aab', 'Oculum-macOS.zip', 'Oculum-iOS-unsigned.ipa', 'Oculum-Linux-x64.tar.gz', 'Oculum-Web.zip')
foreach ($package in $packages) {
  $matches = @(Get-ChildItem -LiteralPath $downloadRoot -Recurse -File | Where-Object Name -eq $package)
  if ($matches.Count -ne 1 -or $matches[0].Length -eq 0) { throw "Missing/ambiguous package: $package" }
  Copy-Item -LiteralPath $matches[0].FullName -Destination (Join-Path $stagingRoot $package)
}
Expand-Archive -LiteralPath (Join-Path $stagingRoot 'Oculum-Windows.zip') -DestinationPath (Join-Path $stagingRoot 'windows')
Expand-Archive -LiteralPath (Join-Path $stagingRoot 'Oculum-Test-Windows.zip') -DestinationPath (Join-Path $stagingRoot 'windows-test')
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
  Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $stagingRoot $_.Name) -Recurse
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/titoli-statistiche-critici.md') -Destination (Join-Path $stagingRoot 'LEGGIMI-MODIFICHE.md')
$manifest = [ordered]@{
  commit = $commit
  githubRun = $run.html_url
  installedAtUtc = [DateTime]::UtcNow.ToString('o')
  files = @(Get-ChildItem -LiteralPath $stagingRoot -Recurse -File | ForEach-Object {
    @{ path = $_.FullName.Substring($stagingRoot.Length + 1); bytes = $_.Length; sha256 = (Get-FileHash -LiteralPath $_.FullName).Hash }
  })
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $stagingRoot 'BUILD-VERIFICATE.json') -Encoding utf8
$active = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
  $_.Path -and $_.Path.StartsWith($distRoot + '\', [StringComparison]::OrdinalIgnoreCase)
})
if ($active.Count) { throw 'Save and close the app running from distribution before replacing it. Fresh packages are ready in staging.' }
Assert-BuildChild $distRoot
if (Test-Path -LiteralPath $distRoot) { Remove-Item -LiteralPath $distRoot -Recurse -Force }
Assert-BuildChild $stagingRoot
Move-Item -LiteralPath $stagingRoot -Destination $distRoot
Assert-BuildChild $downloadRoot
Remove-Item -LiteralPath $downloadRoot -Recurse -Force
Write-Host "Installed only fresh GitHub builds for $commit in $distRoot"
