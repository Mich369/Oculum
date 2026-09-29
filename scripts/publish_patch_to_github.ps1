param(
  [Parameter(Mandatory = $true)]
  [string]$Message,
  [switch]$All,
  [string[]]$Path = @(),
  [switch]$SkipChecks,
  [switch]$SubmitActions,
  [switch]$WaitForActions,
  [switch]$BuildLocalDistribution,
  [switch]$WaitForAppleArtifacts,
  [switch]$ForceCloseRunningDistribution,
  [string]$Remote = "origin",
  [string]$Branch = "",
  [string]$GitHubRepo = "Mich369/oculum"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step {
  param([Parameter(Mandatory = $true)][string]$Message)
  Write-Host ""
  Write-Host "=== $Message ===" -ForegroundColor Cyan
}

function Invoke-CheckedCommand {
  param(
    [Parameter(Mandatory = $true)][string]$Description,
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
  )

  Write-Step $Description
  & $FilePath @Arguments
  $exitCode = if ($null -eq $global:LASTEXITCODE) { 0 } else { $global:LASTEXITCODE }
  if ($exitCode -ne 0) {
    throw "$Description fallito con exit code $exitCode."
  }
}

function Get-GitText {
  param([Parameter(Mandatory = $true)][string[]]$Arguments)

  $output = & git @Arguments
  $exitCode = if ($null -eq $global:LASTEXITCODE) { 0 } else { $global:LASTEXITCODE }
  if ($exitCode -ne 0) {
    throw "git $($Arguments -join ' ') fallito."
  }
  return ($output | Select-Object -First 1).ToString().Trim()
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = (Resolve-Path -LiteralPath (Join-Path $ScriptDir "..")).Path
Set-Location -LiteralPath $Root

if (-not $All -and $Path.Count -eq 0 -and -not $SubmitActions) {
  throw "Scegli cosa pubblicare: usa -All oppure passa uno o piu -Path. Questo evita push accidentali di modifiche non legate alla patch."
}

if ([string]::IsNullOrWhiteSpace($Branch)) {
  $Branch = Get-GitText -Arguments @("branch", "--show-current")
}
if ([string]::IsNullOrWhiteSpace($Branch)) {
  throw "Branch Git non determinato."
}
$currentBranch = Get-GitText -Arguments @("branch", "--show-current")
if ($currentBranch -ne $Branch) {
  throw "Il branch richiesto ($Branch) non coincide con quello aperto ($currentBranch)."
}
if ($WaitForActions -and -not $SubmitActions) {
  throw "-WaitForActions richiede -SubmitActions."
}
if ($SubmitActions) {
  Invoke-CheckedCommand "Verifica accesso GitHub" "gh" "api" "repos/$GitHubRepo" "--jq" ".full_name"
}
# Never include previously staged unrelated work in a selective publication.
$staged = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw "Impossibile verificare lo stage Git." }
if ($staged.Count -gt 0) {
  throw "Sono presenti modifiche gia staged. Completa quel commit prima di pubblicare questa patch."
}

if (-not $SkipChecks) {
  Invoke-CheckedCommand "flutter analyze" "flutter" "analyze"
  if (Test-Path -LiteralPath "test\oculus_subtrait_mastery_test.dart") {
    Invoke-CheckedCommand "flutter test sottotratti" "flutter" "test" "test\oculus_subtrait_mastery_test.dart"
  }
}

Write-Step "Stage patch"
if ($All) {
  & git add -A
} elseif ($Path.Count -gt 0) {
  & git add -- @Path
}
$exitCode = if ($null -eq $global:LASTEXITCODE) { 0 } else { $global:LASTEXITCODE }
if ($exitCode -ne 0) {
  throw "git add fallito con exit code $exitCode."
}

& git diff --cached --quiet
$diffExit = if ($null -eq $global:LASTEXITCODE) { 0 } else { $global:LASTEXITCODE }
if ($diffExit -gt 1) { throw "Impossibile controllare le modifiche staged." }
if ($diffExit -eq 1) {
  Invoke-CheckedCommand "git commit" "git" "commit" "-m" $Message
} else {
  Write-Host "Nessuna nuova modifica: pubblico il commit corrente."
}
$commit = Get-GitText -Arguments @("rev-parse", "HEAD")
Invoke-CheckedCommand "git push $Remote $Branch" "git" "push" $Remote $Branch

if ($SubmitActions) {
  foreach ($workflow in @("build_distribution.yml", "build_macos.yml")) {
    # Reuse the push run for this exact commit; avoid cancelling it with a duplicate.
    $runsJson = & gh run list --repo $GitHubRepo --workflow $workflow --branch $Branch --commit $commit --limit 10 --json databaseId,status,conclusion,url
    if ($LASTEXITCODE -ne 0) { throw "Impossibile leggere le Actions per $workflow." }
    $run = @($runsJson | ConvertFrom-Json) | Where-Object { $_.status -ne 'completed' -or $_.conclusion -eq 'success' } | Select-Object -First 1
    if ($null -eq $run) {
      Invoke-CheckedCommand "Avvia $workflow" "gh" "workflow" "run" $workflow "--repo" $GitHubRepo "--ref" $Branch
      for ($attempt = 0; $attempt -lt 12 -and $null -eq $run; $attempt++) {
        Start-Sleep -Seconds 5
        $runsJson = & gh run list --repo $GitHubRepo --workflow $workflow --branch $Branch --commit $commit --event workflow_dispatch --limit 10 --json databaseId,status,conclusion,url
        if ($LASTEXITCODE -ne 0) { throw "Impossibile trovare la nuova Action." }
        $run = @($runsJson | ConvertFrom-Json) | Where-Object { $_.status -ne 'completed' -or $_.conclusion -eq 'success' } | Select-Object -First 1
      }
    }
    if ($null -eq $run) { throw "Action avviata ma non individuata per ${commit}: controlla GitHub." }
    Write-Host "Action: $($run.url)"
    if ($WaitForActions) {
      Invoke-CheckedCommand "Attendi $workflow" "gh" "run" "watch" "$($run.databaseId)" "--repo" $GitHubRepo "--exit-status" "--interval" "30"
    }
  }
}

if ($BuildLocalDistribution) {
  $distributionArgs = @(
    "-AppleArtifactsSource", "GitHub",
    "-GitHubRepo", $GitHubRepo,
    "-GitHubBranch", $Branch,
    "-GitHubCommit", $commit
  )
  if ($WaitForAppleArtifacts) {
    $distributionArgs += "-WaitForGitHubAppleArtifacts"
  }
  if ($ForceCloseRunningDistribution) {
    $distributionArgs += "-ForceCloseRunningDistribution"
  }

  Invoke-CheckedCommand "build distribution locale con Apple artifacts GitHub" `
    "powershell" `
    "-ExecutionPolicy" "Bypass" `
    "-File" "scripts\build_distribution_oculum.ps1" `
    @distributionArgs
} elseif ($WaitForAppleArtifacts) {
  Invoke-CheckedCommand "scarica Apple artifacts GitHub" `
    "powershell" `
    "-ExecutionPolicy" "Bypass" `
    "-File" "scripts\sync_github_apple_artifacts.ps1" `
    "-Repo" $GitHubRepo `
    "-Branch" $Branch `
    "-Commit" $commit `
    "-OutputDir" "build\distribution" `
    "-Wait"
}

Write-Host ""
Write-Host "Patch pubblicata su GitHub: $Remote/$Branch @ $commit" -ForegroundColor Green
