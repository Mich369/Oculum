<#
.SYNOPSIS
  Aggiorna un'installazione Windows di Oculum dal catalogo GitHub ufficiale.
.EXAMPLE
  .\Oculum-Aggiornamento-Incrementale.ps1 -Executable 'C:\Oculum\oculum.exe' -DryRun
.EXAMPLE
  .\Oculum-Aggiornamento-Incrementale.ps1 -Executable 'C:\Oculum Test\Oculum-Test.exe'
#>
[CmdletBinding()]
param(
  [string]$Executable,
  [string]$CurrentCommit,
  [switch]$DryRun
)

function Open-OculumBootstrapResponse([Uri]$Url, [bool]$ReleaseAsset) {
  for ($redirect = 0; $redirect -lt 5; $redirect++) {
    $allowed = if ($ReleaseAsset) {
      @('github.com', 'release-assets.githubusercontent.com', 'objects.githubusercontent.com')
    } else { @('api.github.com') }
    if (!$Url.IsAbsoluteUri -or $Url.Scheme -cne 'https' -or $Url.Port -ne 443 -or
        $Url.UserInfo -or $Url.Fragment -or $Url.Host -cnotin $allowed) {
      throw 'Indirizzo GitHub non attendibile.'
    }
    $request = [Net.HttpWebRequest]::Create($Url)
    $request.UserAgent = 'Oculum-Incremental-Windows'
    $request.AllowAutoRedirect = $false
    $request.AutomaticDecompression = [Net.DecompressionMethods]::None
    $request.Timeout = 30000
    $request.ReadWriteTimeout = 30000
    if (!$ReleaseAsset) { $request.Accept = 'application/vnd.github+json' }
    $response = $request.GetResponse()
    if ([int]$response.StatusCode -eq 200 -and
        (!$response.ContentEncoding -or $response.ContentEncoding -ieq 'identity')) {
      return $response
    }
    try {
      if (!$ReleaseAsset -or [int]$response.StatusCode -notin @(301,302,303,307,308)) {
        throw 'Risposta GitHub inattesa.'
      }
      $Url = [Uri]::new($Url, $response.Headers['Location'])
    } finally { $response.Dispose() }
  }
  throw 'Troppi reindirizzamenti da GitHub.'
}

function Read-OculumBootstrapApi([string]$Endpoint) {
  $response = Open-OculumBootstrapResponse ([Uri]("https://api.github.com/repos/Mich369/Oculum/$Endpoint")) $false
  try {
    if ($response.ContentLength -gt 2MB) { throw 'Metadati GitHub troppo grandi.' }
    $body = [IO.MemoryStream]::new()
    try {
      $source = $response.GetResponseStream()
      $buffer = [byte[]]::new(32768)
      while (($count = $source.Read($buffer, 0, $buffer.Length)) -gt 0) {
        if ($body.Length + $count -gt 2MB) { throw 'Metadati GitHub troppo grandi.' }
        $body.Write($buffer, 0, $count)
      }
      return ConvertFrom-Json -InputObject ([Text.UTF8Encoding]::new($false, $true).GetString($body.ToArray()))
    } finally { $body.Dispose() }
  } finally { $response.Dispose() }
}

function Get-OculumBootstrapReleaseAsset($Release, [string]$Tag, [string]$Name, [long]$Limit) {
  $expected = "https://github.com/Mich369/Oculum/releases/download/$Tag/$Name"
  $assets = @($Release.assets | Where-Object { $_.name -ceq $Name })
  if ($assets.Count -ne 1) { throw "Asset ufficiale mancante o ambiguo: $Name" }
  $item = $assets[0]
  if ($item.state -cne 'uploaded' -or $item.browser_download_url -cne $expected -or
      !(Test-OculumIncrementalInteger $item.size) -or $item.size -eq 0 -or
      $item.size -gt $Limit -or $item.digest -isnot [string] -or
      $item.digest -cnotmatch '^sha256:[a-f0-9]{64}$') {
    throw "Metadati ufficiali non validi: $Name"
  }
  return [pscustomobject]@{ url = $expected; bytes = $item.size; sha256 = $item.digest.Substring(7) }
}

function Get-OculumBootstrapLatest([string]$Edition) {
  $channel = Read-OculumBootstrapApi 'releases/tags/oculum-downloads'
  if ($channel.tag_name -cne 'oculum-downloads' -or $channel.draft -ne $false -or $channel.prerelease -ne $false) {
    throw 'Canale pubblico Oculum non disponibile.'
  }
  $catalogs = [regex]::Matches([string]$channel.body, '(?s)<!-- OCULUM_DOWNLOADS:(.*?) -->')
  if ($catalogs.Count -ne 1) { throw 'Catalogo degli aggiornamenti non valido.' }
  $catalog = ConvertFrom-Json -InputObject $catalogs[0].Groups[1].Value
  $builds = @($catalog.PSObject.Properties.Value | Where-Object { $_.workflow -ceq 'Build distribution' })
  if ($builds.Count -ne 1) { throw 'Il catalogo non individua una build pubblica univoca.' }
  $build = $builds[0]
  if (!(Test-OculumIncrementalInteger $build.runId) -or $build.runId -eq 0 -or
      $build.commit -isnot [string] -or $build.commit -cnotmatch '^[a-f0-9]{40}$') {
    throw 'Commit GitHub del catalogo non valido.'
  }

  $artifact = if ($Edition -eq 'test') { 'Oculum-Test-Windows' } else { 'Oculum-Windows' }
  $entry = @($build.incremental | Where-Object { $_.artifact -ceq $artifact -and $_.edition -ceq $Edition })
  if ($entry.Count -ne 1) { throw 'Il catalogo non offre ancora un aggiornamento incrementale per questa edizione.' }
  $archives = @($build.artifacts | Where-Object { $_.name -ceq "$artifact-Folder" })
  if ($archives.Count -ne 1) { throw 'Il catalogo non identifica il pacchetto Windows corrispondente.' }

  $tag = "oculum-build-$($build.runId)"
  $release = Read-OculumBootstrapApi "releases/tags/$tag"
  # The stable channel points to verified archives under versioned prerelease tags.
  if ($release.tag_name -cne $tag -or $release.target_commitish -cne $build.commit -or
      $release.draft -ne $false) {
    throw 'La release GitHub non corrisponde al commit del catalogo.'
  }
  $manifest = Get-OculumBootstrapReleaseAsset $release $tag "$artifact-Incrementale.json" 12MB
  $package = Get-OculumBootstrapReleaseAsset $release $tag "$artifact-Folder.zip" 2GB
  foreach ($pair in @(
    @{ published = $manifest; listed = $entry[0] },
    @{ published = $package; listed = $archives[0] }
  )) {
    if ($pair.published.url -cne $pair.listed.url -or
        !(Test-OculumIncrementalInteger $pair.listed.bytes) -or
        $pair.published.bytes -ne $pair.listed.bytes -or
        "sha256:$($pair.published.sha256)" -cne $pair.listed.sha256) {
      throw 'Dimensione, impronta o URL non corrispondono al catalogo.'
    }
  }
  return [pscustomobject]@{
    Commit = $build.commit; RunId = $build.runId; Manifest = $manifest; Package = $package
  }
}

function Find-OculumBootstrapPrevious([string]$Commit, [string]$Edition, [long]$BeforeRun) {
  if (!$Commit) { return }
  $runs = Read-OculumBootstrapApi (
    'actions/workflows/build_distribution.yml/runs?head_sha=' + $Commit + '&branch=main&status=success&per_page=5'
  )
  $artifact = if ($Edition -eq 'test') { 'Oculum-Test-Windows' } else { 'Oculum-Windows' }
  foreach ($build in @($runs.workflow_runs | Select-Object -First 5)) {
    if (!(Test-OculumIncrementalInteger $build.id) -or $build.id -eq 0 -or
        $build.id -ge $BeforeRun -or $build.head_sha -cne $Commit -or
        $build.head_branch -cne 'main' -or $build.conclusion -cne 'success') { continue }
    $tag = "oculum-build-$($build.id)"
    try {
      $release = Read-OculumBootstrapApi "releases/tags/$tag"
      if ($release.tag_name -cne $tag -or $release.target_commitish -cne $Commit -or
          $release.draft -ne $false) { continue }
      return Get-OculumBootstrapReleaseAsset $release $tag "$artifact-Incrementale.json" 12MB
    } catch {
      # A historical index is optional. Only a verified one grants removals.
      continue
    }
  }
}

function Save-OculumBootstrapManifest($Asset, [string]$Destination) {
  Assert-OculumIncrementalOrdinaryPath $Destination
  if (Test-OculumIncrementalFile $Destination $Asset) { return }
  $temporary = "$Destination-$([Guid]::NewGuid().ToString('N')).partial"
  Assert-OculumIncrementalOrdinaryPath $temporary
  $response = Open-OculumBootstrapResponse ([Uri]$Asset.url) $true
  try {
    if ($response.ContentLength -ge 0 -and $response.ContentLength -ne $Asset.bytes) {
      throw 'Il manifesto GitHub ha una dimensione inattesa.'
    }
    $writer = [IO.File]::Open($temporary, 'CreateNew', 'Write', 'None')
    try { Copy-OculumIncrementalExactBytes $response.GetResponseStream() $writer $Asset.bytes }
    finally { $writer.Dispose() }
    if (!(Test-OculumIncrementalFile $temporary $Asset)) { throw 'Il manifesto non coincide con lo SHA-256 pubblicato.' }
    if ([IO.File]::Exists($Destination)) { [IO.File]::Delete($Destination) }
    [IO.File]::Move($temporary, $Destination)
  } finally {
    $response.Dispose()
    [IO.File]::Delete($temporary)
  }
}

function Get-OculumBootstrapCache {
  # path_provider_windows takes LocalAppData and appends CompanyName/ProductName
  # from Windows VERSIONINFO. Runner.rc uses the same values in both editions.
  $local = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
  if (!$local) { throw 'Cartella LocalAppData non disponibile.' }
  return [IO.Path]::Combine($local, 'com.example', 'oculum')
}

function Write-OculumBootstrapJson([string]$Path, $Value) {
  Assert-OculumIncrementalOrdinaryPath $Path
  $json = ConvertTo-Json -InputObject $Value -Depth 8 -Compress
  $temporary = "$Path-$([Guid]::NewGuid().ToString('N')).tmp"
  $previous = "$temporary.previous"
  Assert-OculumIncrementalOrdinaryPath $temporary
  try {
    [IO.File]::WriteAllText($temporary, $json, [Text.UTF8Encoding]::new($false))
    if ([IO.File]::Exists($Path)) { [IO.File]::Replace($temporary, $Path, $previous) }
    else { [IO.File]::Move($temporary, $Path) }
  } finally {
    [IO.File]::Delete($temporary)
    [IO.File]::Delete($previous)
  }
}

function Invoke-OculumIncrementalBootstrap {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Executable,
    [string]$CurrentCommit,
    [switch]$DryRun
  )
  $ErrorActionPreference = 'Stop'
  if ($CurrentCommit -and $CurrentCommit -cnotmatch '^[a-f0-9]{40}$') { throw 'CurrentCommit richiede lo SHA completo in minuscolo.' }
  $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Executable)
  $name = [IO.Path]::GetFileName($resolved)
  $edition = switch ($name.ToLowerInvariant()) {
    'oculum.exe' { 'normal' }
    'oculum-test.exe' { 'test' }
    default { throw 'Indica oculum.exe oppure Oculum-Test.exe.' }
  }
  if (![IO.File]::Exists($resolved)) { throw 'Eseguibile selezionato non trovato.' }
  $coreBundled = Join-Path $PSScriptRoot 'oculum_incremental_windows.ps1'
  $driver = Join-Path $PSScriptRoot 'incremental_driver.ps1'
  $installer = Join-Path $PSScriptRoot 'update.ps1'
  for ($directory = $PSScriptRoot; $directory; $directory = [IO.Path]::GetDirectoryName($directory)) {
    if ([IO.File]::GetAttributes($directory) -band [IO.FileAttributes]::ReparsePoint) {
      throw 'Il pacchetto locale non puo essere avviato da una cartella collegata.'
    }
  }
  foreach ($localScript in @($coreBundled, $driver, $installer)) {
    $item = Get-Item -LiteralPath $localScript -Force -ErrorAction Stop
    if ($item.PSIsContainer -or $item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
      throw 'Servono i tre helper locali originali del pacchetto.'
    }
  }
  . $coreBundled
  foreach ($localScript in @($coreBundled, $driver, $installer)) { Assert-OculumIncrementalOrdinaryPath $localScript }
  Assert-OculumIncrementalOrdinaryPath $resolved
  $release = Get-OculumBootstrapLatest $edition
  if ($CurrentCommit -and $CurrentCommit -cne $release.Commit) {
    $comparison = Read-OculumBootstrapApi "compare/${CurrentCommit}...$($release.Commit)"
    if ($comparison.status -cne 'ahead') {
      throw 'La release pubblicata non e un aggiornamento della versione installata indicata.'
    }
  }
  $cache = [IO.Path]::GetFullPath((Get-OculumBootstrapCache))
  Assert-OculumIncrementalOrdinaryPath $cache
  [void][IO.Directory]::CreateDirectory($cache)
  $context = [Text.Encoding]::UTF8.GetBytes("$($resolved.ToLowerInvariant())|${edition}|$($release.Manifest.sha256)")
  $hasher = [Security.Cryptography.SHA256]::Create()
  try { $id = [BitConverter]::ToString($hasher.ComputeHash($context)).Replace('-', '').Substring(0, 24).ToLowerInvariant() }
  finally { $hasher.Dispose() }
  $work = Get-OculumIncrementalChild $cache "oculum-update-$($release.RunId)-$edition-$id"
  [void][IO.Directory]::CreateDirectory($work)
  $lock = [IO.File]::Open((Get-OculumIncrementalChild $work 'bootstrap.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
  try {
    $core = Get-OculumIncrementalChild $work 'oculum_incremental_windows.ps1'
    $manifest = Get-OculumIncrementalChild $work 'incremental-target.json'
    $config = [ordered]@{
      work = $work; executable = $resolved; platform = 'windows'; edition = $edition; commit = $release.Commit
      incrementalHelper = $core; incrementalHelperSha256 = (Get-OculumIncrementalFileDigest $coreBundled).ToLowerInvariant()
      incrementalManifest = $manifest; incrementalManifestSha256 = $release.Manifest.sha256
      incrementalPlan = Get-OculumIncrementalChild $work 'incremental-stage.json'
      incrementalRunId = $release.RunId; incrementalPackageUrl = $release.Package.url
      incrementalPackageBytes = $release.Package.bytes; incrementalPackageSha256 = $release.Package.sha256
    }
    [IO.File]::Copy($coreBundled, $core, $true)
    Save-OculumBootstrapManifest $release.Manifest $manifest
    if ($CurrentCommit -and $CurrentCommit -cne $release.Commit) {
      try {
        $previous = Find-OculumBootstrapPrevious $CurrentCommit $edition $release.RunId
        if (!$previous) { throw 'Indice precedente non trovato.' }
        $source = Get-OculumIncrementalChild $work 'incremental-source.json'
        Save-OculumBootstrapManifest $previous $source
        $sourceRelease = Read-OculumIncrementalManifest $source $previous.sha256 $edition
        if ($sourceRelease.Value.commit -cne $CurrentCommit -or $sourceRelease.Value.runId -ge $release.RunId) {
          throw 'Indice della versione di partenza non corrispondente.'
        }
        $config.incrementalSourceManifest = $source
        $config.incrementalSourceManifestSha256 = $previous.sha256
        $config.incrementalSourceCommit = $CurrentCommit
      } catch {
        Write-Host 'Indice della versione di partenza non disponibile. I file obsoleti restano al loro posto.'
      }
    }
    $attempt = [Guid]::NewGuid().ToString('N')
    $configPath = Get-OculumIncrementalChild $work "bootstrap-preview-$attempt.json"
    Write-OculumBootstrapJson $configPath $config
    & $driver -Mode Plan -ConfigPath $configPath
    $previewPath = Get-OculumIncrementalChild $work 'incremental-preview.json'
    $preview = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($previewPath))
    if ($preview.commit -cne $release.Commit -or $preview.edition -cne $edition -or
        !(Test-OculumIncrementalInteger $preview.downloadCount) -or
        !(Test-OculumIncrementalInteger $preview.downloadBytes) -or
        !(Test-OculumIncrementalInteger $preview.changedCount) -or
        !(Test-OculumIncrementalInteger $preview.removeCount)) {
      throw 'Anteprima non valida.'
    }
    $megabytes = $preview.downloadBytes / 1000000
    Write-Host ("Build {0} ({1}) - {2} file da aggiornare, {3} richieste per {4:N2} MB ({5:N0} byte), {6} file obsoleti verificati." -f `
      $release.Commit.Substring(0, 12), $edition, $preview.changedCount, $preview.downloadCount, $megabytes, $preview.downloadBytes, $preview.removeCount)
    if ($DryRun -or ($preview.changedCount -eq 0 -and $preview.removeCount -eq 0)) {
      return $preview
    }
    if ((Read-Host 'Scaricare e preparare questi file? Digita SI per confermare') -ine 'SI') { return }
    & $driver -Mode Stage -ConfigPath $configPath
    $receipt = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($config.incrementalPlan))
    if ($receipt.runtimeDirectoryName -cnotmatch '^incremental-runtime-[a-f0-9]{32}$') {
      throw 'Cartella preparata non valida.'
    }
    $config.incrementalRuntime = Get-OculumIncrementalChild $work $receipt.runtimeDirectoryName
    $installConfig = Get-OculumIncrementalChild $work "bootstrap-install-$attempt.json"
    Write-OculumBootstrapJson $installConfig $config
    Write-Host 'Download verificato. Salva e chiudi tutte le finestre di Oculum da questa cartella.'
    if ((Read-Host 'Premi Invio quando hai chiuso; digita ANNULLA per uscire') -ine '') { return }
    $latest = Get-OculumIncrementalChild $cache "oculum-update-latest-$edition.json"
    Write-OculumBootstrapJson $latest @{ work = $work; edition = $edition; commit = $release.Commit }
    & $installer $installConfig
  } finally { $lock.Dispose() }
}

if ($MyInvocation.InvocationName -ne '.') {
  if (!$Executable) { throw 'Specificare -Executable con il percorso di oculum.exe o Oculum-Test.exe.' }
  Invoke-OculumIncrementalBootstrap -Executable $Executable -CurrentCommit $CurrentCommit -DryRun:$DryRun
}
