param(
  [string]$Repo = "Mich369/oculum",
  [string]$Workflow = "build_distribution.yml",
  [string]$Branch = "main",
  [string]$Commit = "",
  [string]$OutputDir = "",
  [switch]$Wait,
  [int]$TimeoutMinutes = 45,
  [int]$PollSeconds = 30
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step {
  param([Parameter(Mandatory = $true)][string]$Message)
  Write-Host ""
  Write-Host "=== $Message ===" -ForegroundColor Cyan
}

function New-GitHubHeaders {
  $headers = @{
    Accept = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "User-Agent" = "OculumDistributionSync"
  }

  $token = $env:GH_TOKEN
  if ([string]::IsNullOrWhiteSpace($token)) {
    $token = $env:GITHUB_TOKEN
  }
  if (-not [string]::IsNullOrWhiteSpace($token)) {
    $headers.Authorization = "Bearer $token"
  }

  return $headers
}

function Invoke-GitHubApi {
  param([Parameter(Mandatory = $true)][string]$Uri)
  return Invoke-RestMethod -Uri $Uri -Headers $script:GitHubHeaders
}

function Get-OculumWorkflowRun {
  $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
  $encodedWorkflow = [System.Uri]::EscapeDataString($Workflow)
  $runsUri = "https://api.github.com/repos/$Repo/actions/workflows/$encodedWorkflow/runs?branch=$Branch&per_page=30"

  while ($true) {
    $runsResponse = Invoke-GitHubApi -Uri $runsUri
    $runs = @($runsResponse.workflow_runs)
    if (-not [string]::IsNullOrWhiteSpace($Commit)) {
      $runs = @($runs | Where-Object { $_.head_sha -eq $Commit })
    }

    $completedSuccess = @($runs | Where-Object {
        $_.status -eq "completed" -and $_.conclusion -eq "success"
      } | Sort-Object created_at -Descending)
    if ($completedSuccess.Count -gt 0) {
      return $completedSuccess[0]
    }

    $completedFailure = @($runs | Where-Object {
        $_.status -eq "completed" -and $_.conclusion -ne "success"
      } | Sort-Object created_at -Descending)
    if ($completedFailure.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($Commit)) {
      $run = $completedFailure[0]
      throw "Workflow GitHub concluso con '$($run.conclusion)' per commit $Commit. Run: $($run.html_url)"
    }

    $latest = @($runs | Sort-Object created_at -Descending | Select-Object -First 1)
    if (-not $Wait) {
      if ($latest.Count -gt 0) {
        $run = $latest[0]
        throw "Workflow GitHub non ancora pronto: status=$($run.status), conclusion=$($run.conclusion), run=$($run.html_url). Rilancia con -Wait."
      }
      throw "Nessuna run GitHub trovata per workflow $Workflow su branch $Branch."
    }

    if ((Get-Date) -gt $deadline) {
      throw "Timeout: nessuna run GitHub riuscita entro $TimeoutMinutes minuti."
    }

    $target = if ([string]::IsNullOrWhiteSpace($Commit)) { $Branch } else { $Commit }
    Write-Host "Attendo artefatti GitHub per $target..." -ForegroundColor DarkGray
    Start-Sleep -Seconds $PollSeconds
  }
}

function Copy-DownloadedArtifactFile {
  param(
    [Parameter(Mandatory = $true)]$Run,
    [Parameter(Mandatory = $true)][string]$ArtifactName,
    [Parameter(Mandatory = $true)][string]$ExpectedFileName,
    [Parameter(Mandatory = $true)][string]$Subdir
  )

  $artifactsUri = "https://api.github.com/repos/$Repo/actions/runs/$($Run.id)/artifacts?per_page=100"
  $artifactsResponse = Invoke-GitHubApi -Uri $artifactsUri
  $artifact = @($artifactsResponse.artifacts | Where-Object {
      $_.name -eq $ArtifactName -and -not $_.expired
    } | Select-Object -First 1)

  if ($artifact.Count -eq 0) {
    throw "Artefatto GitHub mancante o scaduto: $ArtifactName nella run $($Run.id)."
  }

  $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("oculum-github-artifact-" + [System.Guid]::NewGuid().ToString("N"))
  $zipPath = Join-Path $tempRoot "$ArtifactName.zip"
  $extractDir = Join-Path $tempRoot "extract"
  New-Item -ItemType Directory -Path $tempRoot, $extractDir -Force | Out-Null

  try {
    Invoke-WebRequest -Uri $artifact[0].archive_download_url -Headers $script:GitHubHeaders -OutFile $zipPath
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force

    $downloaded = Get-ChildItem -LiteralPath $extractDir -Recurse -File |
      Where-Object { $_.Name -eq $ExpectedFileName } |
      Select-Object -First 1
    if ($null -eq $downloaded) {
      throw "Il pacchetto $ArtifactName non contiene $ExpectedFileName."
    }

    $rootTarget = Join-Path $OutputDir $ExpectedFileName
    $subTargetDir = Join-Path $OutputDir $Subdir
    $subTarget = Join-Path $subTargetDir $ExpectedFileName
    New-Item -ItemType Directory -Path $OutputDir, $subTargetDir -Force | Out-Null
    Copy-Item -LiteralPath $downloaded.FullName -Destination $rootTarget -Force
    Copy-Item -LiteralPath $downloaded.FullName -Destination $subTarget -Force

    $item = Get-Item -LiteralPath $rootTarget
    Write-Host "Scaricato $ExpectedFileName ($([math]::Round($item.Length / 1MB, 1)) MB)." -ForegroundColor Green
  } finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = (Resolve-Path -LiteralPath (Join-Path $ScriptDir "..")).Path
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
  $OutputDir = Join-Path $Root "build\distribution"
}

$script:GitHubHeaders = New-GitHubHeaders

Write-Step "Sincronizza artefatti Apple da GitHub Actions"
$run = Get-OculumWorkflowRun
Write-Host "Run GitHub: $($run.html_url)" -ForegroundColor DarkGray

Copy-DownloadedArtifactFile `
  -Run $run `
  -ArtifactName "Oculum-macOS" `
  -ExpectedFileName "Oculum-macOS.zip" `
  -Subdir "macos"

Copy-DownloadedArtifactFile `
  -Run $run `
  -ArtifactName "Oculum-iOS-unsigned" `
  -ExpectedFileName "Oculum-iOS-unsigned.ipa" `
  -Subdir "ios"

Write-Host "Artefatti Apple aggiornati in $OutputDir" -ForegroundColor Green
