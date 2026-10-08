Import-Module BitsTransfer
for($i=0;$i -lt 200;$i++) {
 $jobs=@(Get-BitsTransfer | Where-Object DisplayName -Like 'Oculum*')
 foreach($job in $jobs) {
  if($job.JobState -eq 'Transferred') {Complete-BitsTransfer -BitsJob $job}
  elseif($job.JobState -in @('TransientError','Error')) {Resume-BitsTransfer -BitsJob $job -Asynchronous | Out-Null}
 }
 if($jobs.Count -eq 0) {break}
 if($i % 10 -eq 0) {$jobs | Select-Object DisplayName,JobState,BytesTransferred,BytesTotal | Format-Table}
 Start-Sleep -Seconds 2
}
