$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$distRoot = Join-Path $projectRoot 'build\distribution'
$dartRuntime = 'C:\Users\michy\flutter\bin\cache\dart-sdk\bin\dart.exe'
$flutterTool = 'C:\Users\michy\flutter\bin\cache\flutter_tools.snapshot'
Set-Location -LiteralPath $projectRoot
New-Item -ItemType Directory -Force -Path $distRoot | Out-Null

function Build-Edition([string]$Platform, [string]$Profile, [string]$LogName) {
  Write-Output "Compilazione $Platform (profilo '$Profile')"
  $logPath = Join-Path $projectRoot "output\$LogName.log"
  $previousErrorAction = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    & $dartRuntime $flutterTool build $Platform --release --no-pub "--dart-define=OculumSaveProfile=$Profile" *> $logPath
    $exitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorAction
  }
  if ($exitCode -ne 0) { throw "Build $Platform ($Profile) fallita: output\$LogName.log" }
}

function Package-Windows([string]$Folder, [string]$ExeName, [string]$ZipName) {
  $target = [IO.Path]::GetFullPath((Join-Path $distRoot $Folder))
  if (!$target.StartsWith($distRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Percorso fuori distribution' }
  $running = Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -and $_.Path.StartsWith($target + '\', [StringComparison]::OrdinalIgnoreCase)
  }
  if ($running) { throw "App aperta in $target; salva e chiudila prima del packaging." }
  New-Item -ItemType Directory -Force -Path $target | Out-Null
  Copy-Item -Path 'build\windows\x64\runner\Release\*' -Destination $target -Recurse -Force
  Copy-Item -LiteralPath 'docs\DIARI_MAPPA_AGGIORNAMENTO.md' -Destination (Join-Path $target 'LEGGIMI-MODIFICHE.md') -Force
  if ($ExeName -ne 'oculum.exe') {
    Move-Item -LiteralPath (Join-Path $target 'oculum.exe') -Destination (Join-Path $target $ExeName) -Force
  }
  foreach ($name in @($ExeName, 'flutter_windows.dll', 'WebView2Loader.dll', 'vcruntime140.dll', 'msvcp140.dll', 'data\app.so', 'data\icudtl.dat')) {
    if (!(Test-Path -LiteralPath (Join-Path $target $name))) { throw "Runtime mancante: $name" }
  }
  $archive = Join-Path $distRoot $ZipName
  Compress-Archive -Path (Join-Path $target '*') -DestinationPath $archive -Force
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [IO.Compression.ZipFile]::OpenRead($archive)
  try {
    foreach ($payload in @($ExeName, 'data/app.so')) {
    $entry = $zip.Entries | Where-Object { $_.FullName.Replace('\', '/') -eq $payload } | Select-Object -First 1
    if (!$entry) { throw "$payload assente dallo ZIP" }
    $stream = $entry.Open()
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $zipHash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '') } finally { $stream.Dispose(); $sha.Dispose() }
    if ($zipHash -ne (Get-FileHash -LiteralPath (Join-Path $target $payload)).Hash) { throw "$payload ZIP diverso dalla build" }
    }
  } finally { $zip.Dispose() }
}

Build-Edition 'windows' '' 'diary-build-windows'
Package-Windows 'windows' 'oculum.exe' 'Oculum-Windows.zip'
Copy-Item -Path (Join-Path $distRoot 'windows\*') -Destination $distRoot -Recurse -Force
Build-Edition 'windows' 'test' 'diary-build-windows-test'
Package-Windows 'test\windows' 'Oculum-Test.exe' 'Oculum-Test-Windows.zip'
if ((Get-FileHash 'build\distribution\windows\data\app.so').Hash -eq
    (Get-FileHash 'build\distribution\test\windows\data\app.so').Hash) {
  throw 'Le edizioni normale e test devono avere profili compilati distinti.'
}
Build-Edition 'apk' '' 'diary-build-apk'
$apk = Join-Path $distRoot 'Oculum-Android-release.apk'
Copy-Item -LiteralPath 'build\app\outputs\flutter-apk\app-release.apk' -Destination $apk -Force
if ((Get-FileHash -LiteralPath $apk).Hash -ne (Get-FileHash 'build\app\outputs\flutter-apk\app-release.apk').Hash) { throw 'APK diverso dalla build' }
Build-Edition 'appbundle' '' 'diary-build-aab'
$aab = Join-Path $distRoot 'Oculum-Android-release.aab'
Copy-Item -LiteralPath 'build\app\outputs\bundle\release\app-release.aab' -Destination $aab -Force
Build-Edition 'web' '' 'diary-build-web'
$webFolder = Join-Path $distRoot 'web'
New-Item -ItemType Directory -Force -Path $webFolder | Out-Null
Copy-Item -Path 'build\web\*' -Destination $webFolder -Recurse -Force
$webArchive = Join-Path $distRoot 'Oculum-Web.zip'
Compress-Archive -Path (Join-Path $webFolder '*') -DestinationPath $webArchive -Force
Copy-Item -LiteralPath 'docs\DIARI_MAPPA_AGGIORNAMENTO.md' -Destination (Join-Path $distRoot 'LEGGIMI-MODIFICHE.md') -Force
$artifacts = @(
  (Join-Path $distRoot 'oculum.exe'),
  (Join-Path $distRoot 'data\app.so'),
  (Join-Path $distRoot 'windows\oculum.exe'),
  (Join-Path $distRoot 'Oculum-Windows.zip'),
  (Join-Path $distRoot 'test\windows\Oculum-Test.exe'),
  (Join-Path $distRoot 'Oculum-Test-Windows.zip'),
  (Join-Path $distRoot 'windows\data\app.so'),
  (Join-Path $distRoot 'test\windows\data\app.so'),
  $apk,
  $aab,
  $webArchive
)
$report = [ordered]@{
  generatedAt = (Get-Date).ToString('o')
  testProfile = 'test'
  isolatedTestSaves = $true
  artifacts = @($artifacts | ForEach-Object {
    $file = Get-Item -LiteralPath $_
    [ordered]@{ path = $file.FullName; bytes = $file.Length; sha256 = (Get-FileHash -LiteralPath $_).Hash }
  })
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $distRoot 'diari-verifica-distribuzione.json') -Encoding utf8
Write-Output 'Distribution verificata: Windows normale e test con runtime, ZIP, APK, AAB, Web e SHA256.'
