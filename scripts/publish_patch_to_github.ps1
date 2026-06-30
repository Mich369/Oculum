param(
  [Parameter(Mandatory = $true)]
  [string]$Message,
  [switch]$All,
  [string[]]$Path = @(),
  [switch]$SkipChecks,
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

if (-not $All -and $Path.Count -eq 0) {
  throw "Scegli cosa pubblicare: usa -All oppure passa uno o piu -Path. Questo evita push accidentali di modifiche non legate alla patch."
}

if ([string]::IsNullOrWhiteSpace($Branch)) {
  $Branch = Get-GitText -Arguments @("branch", "--show-current")
}
if ([string]::IsNullOrWhiteSpace($Branch)) {
  throw "Branch Git non determinato."
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
} else {
  & git add -- @Path
}
$exitCode = if ($null -eq $global:LASTEXITCODE) { 0 } else { $global:LASTEXITCODE }
if ($exitCode -ne 0) {
  throw "git add fallito con exit code $exitCode."
}

& git diff --cached --quiet
$diffExit = if ($null -eq $global:LASTEXITCODE) { 0 } else { $global:LASTEXITCODE }
if ($diffExit -eq 0) {
  throw "Nessuna modifica staged da committare."
}

Invoke-CheckedCommand "git commit" "git" "commit" "-m" $Message
$commit = Get-GitText -Arguments @("rev-parse", "HEAD")
Invoke-CheckedCommand "git push $Remote $Branch" "git" "push" $Remote $Branch

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
