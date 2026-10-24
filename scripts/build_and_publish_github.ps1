param([string]$Repository = 'Mich369/Oculum')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Set-Location -LiteralPath ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')))
function Invoke-Gh([string[]]$Arguments) {
  $result = & gh @Arguments
  if ($LASTEXITCODE -ne 0) { throw "gh failed: $($Arguments[0])" }
  return $result
}
$dirty = @(& git status --porcelain -- lib assets android windows macos linux web test scripts supabase .github docs pubspec.yaml pubspec.lock)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect Git status' }
if ($dirty.Count -gt 0) { throw 'Ci sono modifiche locali non committate. Committale prima: GitHub costruisce soltanto i commit inviati.' }
$branch = (& git branch --show-current).Trim()
$commit = (& git rev-parse HEAD).Trim()
if (!$branch -or $LASTEXITCODE -ne 0) { throw 'Serve un branch Git attivo' }
& git push origin $branch
if ($LASTEXITCODE -ne 0) { throw 'Push non riuscito' }
function Start-And-WaitWorkflow([string]$Workflow,[string]$Ref,[string]$ExpectedCommit,[string[]]$Inputs) {
  $before = (Invoke-Gh @('run','list','--repo',$Repository,'--workflow',$Workflow,'--event','workflow_dispatch','--branch',$Ref,'--limit','10','--json','databaseId') | Out-String) | ConvertFrom-Json
  $knownRunIds = @($before | ForEach-Object { "$($_.databaseId)" })
  Invoke-Gh (@('workflow','run',$Workflow,'--repo',$Repository,'--ref',$Ref) + $Inputs) | Out-Host
  $run = $null
  for ($attempt=0; $attempt -lt 24; $attempt++) {
    $runs = (Invoke-Gh @('run','list','--repo',$Repository,'--workflow',$Workflow,'--event','workflow_dispatch','--branch',$Ref,'--limit','10','--json','databaseId,headSha') | Out-String) | ConvertFrom-Json
    $run = @($runs | Where-Object {
      "$($_.databaseId)" -notin $knownRunIds -and $_.headSha -eq $ExpectedCommit
    }) | Select-Object -First 1
    if ($null -ne $run) { break }
    Start-Sleep -Seconds 5
  }
  if ($null -eq $run) { throw "Run non trovato: $Workflow" }
  Write-Host "Attendo $Workflow / $($run.databaseId)"
  Invoke-Gh @('run','watch',"$($run.databaseId)",'--repo',$Repository,'--exit-status') | Out-Host
  return $run
}
$build = Start-And-WaitWorkflow 'build_distribution.yml' $branch $commit @()
if ($build.headSha -ne $commit) { throw 'La build non corrisponde al commit richiesto' }
Write-Host 'La pubblicazione parte automaticamente soltanto dopo la build riuscita. Attendo il catalogo pubblico...'
$matching = $null
$deadline = [DateTimeOffset]::UtcNow.AddMinutes(35)
while ([DateTimeOffset]::UtcNow -lt $deadline) {
  try {
    $release = (Invoke-Gh @('api',"repos/$Repository/releases/tags/oculum-downloads") | Out-String) | ConvertFrom-Json
    $marker = [regex]::Match([string]$release.body, '<!-- OCULUM_DOWNLOADS:(.*?) -->', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($marker.Success) {
      $catalog = $marker.Groups[1].Value | ConvertFrom-Json
      $matching = @($catalog.PSObject.Properties.Value | Where-Object {
        "$($_.runId)" -eq "$($build.databaseId)" -and $_.commit -eq $commit
      }) | Select-Object -First 1
      if ($null -ne $matching -and @($matching.artifacts).Count -gt 0) { break }
    }
  } catch {
    Write-Host 'La pagina pubblica non e ancora aggiornata; ritento.'
  }
  Start-Sleep -Seconds 20
}
if ($null -eq $matching -or @($matching.artifacts).Count -eq 0) {
  throw 'Build riuscita ma pubblicazione automatica non verificata. Controlla l azione Publish public downloads.'
}
foreach ($asset in $matching.artifacts) {
  if (!$asset.url -or [long]$asset.bytes -le 0 -or $asset.sha256 -notmatch '^[0-9a-f]{64}$') {
    throw "Manifest download non valido: $($asset.name)"
  }
}
Write-Host "Build e download aggiornati per $commit"
Write-Host "https://github.com/$Repository/releases/tag/oculum-downloads"
