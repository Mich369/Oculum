$ErrorActionPreference = 'Stop'
$global:oculumPublishTestCommands = [Collections.Generic.List[string]]::new()
$global:oculumPublishTestFailWatch = $false
function gh {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$CommandArgs)
  $global:oculumPublishTestCommands.Add(($CommandArgs -join ' '))
  $global:LASTEXITCODE = 0
  if ($CommandArgs[0] -eq 'api') { return '{"sha":"verified-source"}' }
  if ($CommandArgs[0] -eq 'run' -and $CommandArgs[1] -eq 'list') {
    return (@{databaseId = 42; headSha = 'verified-source'; createdAt = [DateTimeOffset]::UtcNow.ToString('o'); url = 'https://example.invalid/run/42'} | ConvertTo-Json -Compress)
  }
  if ($CommandArgs[0] -eq 'run' -and $CommandArgs[1] -eq 'watch' -and $global:oculumPublishTestFailWatch) {
    $global:LASTEXITCODE = 1
  }
}
$publisher = Join-Path (Split-Path $PSScriptRoot -Parent) 'publish_oculum_github.ps1'
& $publisher
if (@($global:oculumPublishTestCommands | Where-Object { $_ -like 'workflow run *' }).Count -ne 3) { throw 'Expected distribution, publication and Pages workflows' }
if (!($global:oculumPublishTestCommands | Where-Object { $_ -like '*public_downloads.yml*run_id=42*' })) { throw 'Publication must use the exact verified distribution run' }
if (@($global:oculumPublishTestCommands | Where-Object { $_ -like 'run watch 42*--exit-status' }).Count -ne 3) { throw 'Every workflow must be checked' }
$global:oculumPublishTestCommands.Clear()
$global:oculumPublishTestFailWatch = $true
$failed = $false
try { & $publisher } catch { $failed = $true }
if (!$failed) { throw 'Failed build must throw' }
if (@($global:oculumPublishTestCommands | Where-Object { $_ -like 'workflow run *' }).Count -ne 1) { throw 'Failed build must not dispatch publication' }
Write-Host 'PASS: exact build run publication, workflow verification and stop on failure. No real GitHub commands executed.'
# The negative case intentionally leaves the mock's native exit status at 1.
# GitHub's pwsh wrapper forwards LASTEXITCODE, so successful assertions must
# reset that status after confirming that publication was correctly stopped.
$global:LASTEXITCODE = 0
exit 0
