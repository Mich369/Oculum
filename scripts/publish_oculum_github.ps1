# Run only when ready to build and publish the source already pushed to GitHub.
param(
  [string]$Repository = 'Mich369/Oculum',
  [string]$Branch = 'main'
)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path $PSScriptRoot -Parent)
if (!(Get-Command gh -ErrorAction SilentlyContinue)) {
  throw 'Installa GitHub CLI: winget install --id GitHub.cli; riapri PowerShell e usa gh auth login.'
}
function Invoke-GitHubJson([string[]]$Arguments) {
  $raw = & gh @Arguments
  if ($LASTEXITCODE -ne 0) { throw ('Comando GitHub fallito: gh ' + ($Arguments -join ' ')) }
  return ($raw | ConvertFrom-Json)
}
function Start-VerifiedWorkflow([string]$Workflow, [string[]]$Fields = @()) {
  $since = [DateTimeOffset]::UtcNow.AddSeconds(-5)
  & gh workflow run $Workflow --repo $Repository --ref $Branch @Fields | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "Impossibile avviare $Workflow" }
  $run = $null
  for ($attempt = 0; $attempt -lt 60; $attempt++) {
    $runs = @(Invoke-GitHubJson -Arguments @('run','list','--repo',$Repository,'--workflow',$Workflow,
      '--branch',$Branch,'--event','workflow_dispatch','--limit','20',
      '--json','databaseId,headSha,createdAt,url'))
    $run = $runs | Where-Object {
      $_.headSha -eq $script:sourceCommit -and [DateTimeOffset]$_.createdAt -ge $since
    } | Sort-Object createdAt -Descending | Select-Object -First 1
    if ($run) { break }
    Start-Sleep -Seconds 5
  }
  if (!$run) { throw "Run $Workflow non individuata: controlla GitHub Actions prima di riprovare." }
  Write-Host $run.url
  & gh run watch $run.databaseId --repo $Repository --exit-status | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "Workflow fallito: $($run.url). Nessuna pubblicazione successiva avviata." }
  return $run
}
& gh auth status --hostname github.com
if ($LASTEXITCODE -ne 0) { throw 'Autenticati con gh auth login e riprova.' }
$branchInfo = Invoke-GitHubJson -Arguments @('api',"repos/$Repository/commits/$Branch")
$script:sourceCommit = $branchInfo.sha
Write-Host "Build del commit remoto $script:sourceCommit ($Branch). I file locali non pubblicati non sono inclusi."
$distribution = Start-VerifiedWorkflow 'build_distribution.yml'
# Publication accepts only successful, verified distribution runs.
$null = Start-VerifiedWorkflow -Workflow 'public_downloads.yml' -Fields @('-f',"run_id=$($distribution.databaseId)")
# The successful distribution also triggers Pages automatically. Dispatch explicitly
# here so this command waits for a fresh, successful web deployment as well.
$null = Start-VerifiedWorkflow 'play_web.yml'
Write-Host 'Build, download pubblici e pagina web completati su GitHub.'
Write-Host "https://github.com/$Repository/releases/tag/oculum-downloads"
