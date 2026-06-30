param(
  [switch]$FullList,
  [switch]$ForceCloseRunningDistribution,
  [ValidateSet("Auto", "GitHub", "Downloads", "None")]
  [string]$AppleArtifactsSource = "Auto",
  [string]$GitHubRepo = "Mich369/oculum",
  [string]$GitHubBranch = "",
  [string]$GitHubCommit = "",
  [switch]$WaitForGitHubAppleArtifacts,
  [int]$GitHubArtifactTimeoutMinutes = 45
)

$ErrorActionPreference = "Stop"
$Script = Join-Path $PSScriptRoot "scripts\build_distribution_oculum.ps1"
if (-not (Test-Path -LiteralPath $Script)) {
  throw "Script distribution principale non trovato: $Script"
}

& $Script @PSBoundParameters
