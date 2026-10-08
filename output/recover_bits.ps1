$ErrorActionPreference='Stop'
Import-Module BitsTransfer
$root=Join-Path (Get-Location) 'build/github-artifacts-37741874069'
$items=Get-Content output/artifact-transfer.json -Raw | ConvertFrom-Json
foreach($item in $items) {
 if($item.name -eq 'Oculum-Linux') {continue}
 Start-BitsTransfer -Source $item.url -Destination (Join-Path $root "$($item.name).zip") -DisplayName "Oculum-$($item.name)" -Asynchronous | Out-Null
}
for($i=0;$i -lt 200;$i++) {
 $jobs=@(Get-BitsTransfer | Where-Object DisplayName -Like 'Oculum*')
 foreach($job in $jobs) {
  if($job.JobState -eq 'Transferred') {Complete-BitsTransfer -BitsJob $job}
  elseif($job.JobState -eq 'TransientError') {Resume-BitsTransfer -BitsJob $job -Asynchronous | Out-Null}
 }
 if($jobs.Count -eq 0) {break}
 if($i % 10 -eq 0) {$jobs | Select-Object DisplayName,JobState,BytesTransferred,BytesTotal | Format-Table}
 Start-Sleep -Seconds 2
}
