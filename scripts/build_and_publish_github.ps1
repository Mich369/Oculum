param([string]$Repository = 'Mich369/Oculum')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Set-Location -LiteralPath ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')))
function Invoke-Gh([string[]]$Arguments) {
  $result = & gh @Arguments
  if ($LASTEXITCODE -ne 0) { throw "gh failed: $($Arguments[0])" }
  return $result
}
$dirty = @(& git status --porcelain -- lib assets android windows macos linux web test scripts .github docs pubspec.yaml pubspec.lock)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect Git status' }
if ($dirty.Count -gt 0) { throw 'Ci sono modifiche locali non committate. Committale prima: GitHub costruisce soltanto i commit inviati.' }
$branch = (& git branch --show-current).Trim()
$commit = (& git rev-parse HEAD).Trim()
if (!$branch -or $LASTEXITCODE -ne 0) { throw 'Serve un branch Git attivo' }
& git push origin $branch
if ($LASTEXITCODE -ne 0) { throw 'Push non riuscito' }
function Start-And-WaitWorkflow([string]$Workflow,[string]$Ref,[string[]]$Inputs) {
  $start = [DateTimeOffset]::UtcNow.AddSeconds(-2)
  Invoke-Gh (@('workflow','run',$Workflow,'--repo',$Repository,'--ref',$Ref) + $Inputs) | Out-Host
  $run = $null
  for ($attempt=0; $attempt -lt 24; $attempt++) {
    $runs = (Invoke-Gh @('run','list','--repo',$Repository,'--workflow',$Workflow,'--event','workflow_dispatch','--branch',$Ref,'--limit','10','--json','databaseId,createdAt,headSha') | Out-String) | ConvertFrom-Json
    $run = @($runs | Where-Object { [DateTimeOffset]::Parse($_.createdAt) -ge $start } | Sort-Object createdAt -Descending) | Select-Object -First 1
    if ($null -ne $run) { break }
    Start-Sleep -Seconds 5
  }
  if ($null -eq $run) { throw "Run non trovato: $Workflow" }
  Write-Host "Attendo $Workflow / $($run.databaseId)"
  Invoke-Gh @('run','watch',"$($run.databaseId)",'--repo',$Repository,'--exit-status') | Out-Host
  return $run
}
$build = Start-And-WaitWorkflow 'build_distribution.yml' $branch @()
if ($build.headSha -ne $commit) { throw 'La build non corrisponde al commit richiesto' }
# workflow_run also publishes automatically; this explicit pass recovers a missed publication.
$null = Start-And-WaitWorkflow 'public_downloads.yml' 'main' @('-f',"run_id=$($build.databaseId)")
$release = (Invoke-Gh @('api',"repos/$Repository/releases/tags/oculum-downloads") | Out-String) | ConvertFrom-Json
$marker = '<!-- OCULUM_DOWNLOADS:'
$raw = ([string]$release.body).Split(@($marker),[StringSplitOptions]::None)[1].Split(@(' -->'),[StringSplitOptions]::None)[0]
$catalog = $raw | ConvertFrom-Json
$matching = @($catalog.PSObject.Properties.Value | Where-Object { "$($_.runId)" -eq "$($build.databaseId)" -and $_.commit -eq $commit })
if ($matching.Count -eq 0) { throw 'Il canale pubblico non punta alla build richiesta: potrebbe essere stata superata da una build piu recente.' }
Write-Host "Build e download aggiornati per $commit"
Write-Host "https://github.com/$Repository/releases/tag/oculum-downloads"
