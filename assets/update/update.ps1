param([Parameter(Mandatory=$true)][string]$ConfigPath)
$ErrorActionPreference='Stop'
$config=Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$work=[IO.Path]::GetFullPath($config.work)
$target=[IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($config.executable))
$unpack=Join-Path $work 'unpacked'
$backup=Join-Path $work 'previous-runtime'
$packageExe=if($config.edition -eq 'test'){'Oculum-Test.exe'}else{'oculum.exe'}
$installed=[Collections.Generic.List[string]]::new()
$moved=[Collections.Generic.List[string]]::new()
function Assert-Child([string]$Path,[string]$Root) {
 $full=[IO.Path]::GetFullPath($Path)
 if(!$full.StartsWith([IO.Path]::GetFullPath($Root)+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw "Unsafe update path: $full"}
 if((Test-Path -LiteralPath $full) -and ((Get-Item -LiteralPath $full).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Update cannot replace a linked directory'}
}
try {
 Assert-Child $unpack $work
 Add-Type -AssemblyName System.IO.Compression.FileSystem
 # Validate archive paths before extracting. Nested packages are unpacked separately.
 function Expand-Checked([string]$Archive,[string]$Destination) {
  $zip=[IO.Compression.ZipFile]::OpenRead($Archive)
  try {foreach($entry in $zip.Entries){Assert-Child (Join-Path $Destination $entry.FullName) $Destination}} finally {$zip.Dispose()}
  [IO.Compression.ZipFile]::ExtractToDirectory($Archive,$Destination)
 }
 Expand-Checked $config.archive $unpack
 $executables=@(Get-ChildItem -LiteralPath $unpack -Filter $packageExe -Recurse -File)
 if($executables.Count -eq 0){
  $nested=@(Get-ChildItem -LiteralPath $unpack -Filter '*.zip' -Recurse -File)
  if($nested.Count -ne 1){throw 'Windows package is ambiguous'}
  $inner=Join-Path $work 'runtime';Assert-Child $inner $work
  Expand-Checked $nested[0].FullName $inner
  $executables=@(Get-ChildItem -LiteralPath $inner -Filter $packageExe -Recurse -File)
 }
 if($executables.Count -ne 1){throw 'Expected one Oculum executable'}
 $source=$executables[0].Directory.FullName
 if(!(Test-Path -LiteralPath (Join-Path $source 'flutter_windows.dll')) -or !(Test-Path -LiteralPath (Join-Path $source 'data'))){throw 'Incomplete Windows runtime'}
 $files=@(Get-ChildItem -LiteralPath $source | Where-Object {$_.Name -eq 'data' -or $_.Extension -in '.exe','.dll'})
 foreach($file in $files){Assert-Child (Join-Path $target $file.Name) $target}
 Wait-Process -Id ([int]$config.pid) -Timeout 120 -ErrorAction SilentlyContinue
 if(Get-Process -Id ([int]$config.pid) -ErrorAction SilentlyContinue){throw 'Oculum has not closed'}
 New-Item -ItemType Directory -Path $backup -Force | Out-Null
 foreach($file in $files){
  $destination=Join-Path $target $file.Name
  if(Test-Path -LiteralPath $destination){Move-Item -LiteralPath $destination -Destination (Join-Path $backup $file.Name);$moved.Add($file.Name)}
  $installed.Add($file.Name)
  Copy-Item -LiteralPath $file.FullName -Destination $destination -Recurse
 }
 Start-Process -WindowStyle Hidden -FilePath (Join-Path $target $packageExe) -WorkingDirectory $target
 'success' | Set-Content -LiteralPath (Join-Path $work 'result.txt')
} catch {
 # Only the explicitly staged runtime entries are reverted. Saved user files are untouched.
 foreach($name in $installed){$path=Join-Path $target $name;Assert-Child $path $target;Remove-Item -LiteralPath $path -Recurse -Force}
 foreach($name in $moved){Move-Item -LiteralPath (Join-Path $backup $name) -Destination (Join-Path $target $name)}
 $_ | Out-String | Set-Content -LiteralPath (Join-Path $work 'error.txt')
 if(Test-Path -LiteralPath $config.executable){Start-Process -WindowStyle Hidden -FilePath $config.executable -WorkingDirectory $target}
 exit 1
}
