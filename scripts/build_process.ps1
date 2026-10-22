function ConvertTo-OculumNativeArgument([string]$Value) {
  if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') { return $Value }
  # Windows command-line quoting: double backslashes before quotes and at
  # the end of a quoted argument. ProcessStartInfo.ArgumentList is preferred.
  return '"' + [regex]::Replace($Value, '(\\*)("|$)', {
    param($match)
    $slashes = $match.Groups[1].Value
    if ($match.Groups[2].Value -eq '"') { return $slashes + $slashes + '\"' }
    return $slashes + $slashes
  }) + '"'
}

function Invoke-OculumBuildProcess {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][string[]]$Arguments,
    [Parameter(Mandatory = $true)][string]$WorkingDirectory,
    [Parameter(Mandatory = $true)][string]$LogPath,
    [Parameter(Mandatory = $true)][string]$Description,
    [ValidateRange(1, 10800)][int]$TimeoutSeconds = 2700,
    [hashtable]$Environment = @{}
  )

  $startInfo = [Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = $FilePath
  $startInfo.WorkingDirectory = $WorkingDirectory
  $startInfo.UseShellExecute = $false
  $startInfo.CreateNoWindow = $true
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  if ($startInfo.PSObject.Properties['ArgumentList']) {
    foreach ($argument in $Arguments) { $startInfo.ArgumentList.Add($argument) }
  } else {
    $startInfo.Arguments = ($Arguments | ForEach-Object { ConvertTo-OculumNativeArgument $_ }) -join ' '
  }
  foreach ($key in $Environment.Keys) { $startInfo.EnvironmentVariables[$key] = [string]$Environment[$key] }

  $writer = [IO.StreamWriter]::new($LogPath, $false, [Text.UTF8Encoding]::new($false))
  $writer.AutoFlush = $true
  $process = [Diagnostics.Process]::new()
  $process.StartInfo = $startInfo
  $started = $false
  $timer = [Diagnostics.Stopwatch]::StartNew()
  $nextProgress = 30
  try {
    $writer.WriteLine("$Description started at $([DateTime]::UtcNow.ToString('o'))")
    if (!$process.Start()) { throw "Cannot start $Description" }
    $started = $true
    $stdout = $process.StandardOutput.ReadLineAsync()
    $stderr = $process.StandardError.ReadLineAsync()
    while ($null -ne $stdout -or $null -ne $stderr -or !$process.HasExited) {
      if ($timer.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
        throw "$Description exceeded its timeout of $TimeoutSeconds seconds"
      }
      if ($null -ne $stdout -and $stdout.IsCompleted) {
        $line = $stdout.GetAwaiter().GetResult()
        if ($null -eq $line) { $stdout = $null } else {
          $writer.WriteLine($line)
          Write-Host $line
          $stdout = $process.StandardOutput.ReadLineAsync()
        }
      }
      if ($null -ne $stderr -and $stderr.IsCompleted) {
        $line = $stderr.GetAwaiter().GetResult()
        if ($null -eq $line) { $stderr = $null } else {
          $writer.WriteLine($line)
          Write-Host $line
          $stderr = $process.StandardError.ReadLineAsync()
        }
      }
      if ($timer.Elapsed.TotalSeconds -ge $nextProgress -and !$process.HasExited) {
        $progress = "$Description in progress ($([int]$timer.Elapsed.TotalSeconds)s); log: $LogPath"
        Write-Host $progress
        $writer.WriteLine($progress)
        $nextProgress += 30
      }
      if ($null -ne $stdout -or $null -ne $stderr -or !$process.HasExited) {
        Start-Sleep -Milliseconds 20
      }
    }
    $process.WaitForExit()
    $exitCode = $process.ExitCode
    $writer.WriteLine("$Description completed with exit code $exitCode at $([DateTime]::UtcNow.ToString('o'))")
    if ($exitCode -ne 0) { throw "$Description failed with exit code $exitCode; see $LogPath" }
  } catch {
    $writer.WriteLine("FAILED: $($_.Exception.Message)")
    throw
  } finally {
    if ($started -and !$process.HasExited) {
      # Only terminate the process tree started by this invocation. A failed
      # or timed-out build must never keep writing after packaging has stopped.
      if ($process.GetType().GetMethod('Kill', [type[]]@([bool]))) { $process.Kill($true) } else { $process.Kill() }
      $null = $process.WaitForExit(5000)
    }
    $timer.Stop()
    $writer.Dispose()
    $process.Dispose()
  }
}
