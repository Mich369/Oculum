param([Parameter(Mandatory = $true)][ValidateSet('Windows', 'Android', 'TestWindows')][string]$Target)

# Run the matching Flutter build first, then package its complete output:
# flutter build windows --release --no-pub
# .\scripts\package_current_oculum.ps1 -Target Windows
# flutter build apk --release --no-pub
# .\scripts\package_current_oculum.ps1 -Target Android
# flutter build windows --release --no-pub --dart-define=OculumSaveProfile=test
# .\scripts\package_current_oculum.ps1 -Target TestWindows

$ErrorActionPreference = 'Stop'
$oculumRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Set-Location -LiteralPath $oculumRoot
$oculumDist = Join-Path $oculumRoot 'build\distribution'
$oculumRelease = Join-Path $oculumRoot 'build\windows\x64\runner\Release'

function Copy-OculumBundle([string]$Destination) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Get-ChildItem -LiteralPath $oculumRelease -Force | Copy-Item -Destination $Destination -Recurse -Force
}

if ($Target -eq 'Windows') {
Copy-OculumBundle (Join-Path $oculumDist 'windows')
Copy-OculumBundle $oculumDist
Copy-Item -LiteralPath (Join-Path $oculumRoot 'docs\items-pergamene-e-tiri.md') -Destination (Join-Path $oculumDist 'windows\LEGGIMI-MODIFICHE.md') -Force
Compress-Archive -Path "$oculumDist\windows\*" -DestinationPath (Join-Path $oculumDist 'Oculum-Windows.zip') -Force
Copy-Item -LiteralPath (Join-Path $oculumRelease 'oculum.exe') -Destination (Join-Path $oculumDist 'Oculum.exe') -Force
}

if ($Target -eq 'Android') {
New-Item -ItemType Directory -Path (Join-Path $oculumDist 'android') -Force | Out-Null
$oculumApk = Join-Path $oculumRoot 'build\app\outputs\flutter-apk\app-release.apk'
Copy-Item -LiteralPath $oculumApk -Destination (Join-Path $oculumDist 'Oculum-Android-release.apk') -Force
Copy-Item -LiteralPath $oculumApk -Destination (Join-Path $oculumDist 'android\Oculum-Android-release.apk') -Force
}

if ($Target -eq 'TestWindows') {
$oculumTestDist = Join-Path $oculumDist 'test\windows'
Copy-OculumBundle $oculumTestDist
Copy-Item -LiteralPath (Join-Path $oculumRelease 'oculum.exe') -Destination (Join-Path $oculumTestDist 'Oculum-Test.exe') -Force
Copy-Item -LiteralPath (Join-Path $oculumRoot 'docs\items-pergamene-e-tiri.md') -Destination (Join-Path $oculumTestDist 'LEGGIMI-MODIFICHE.md') -Force
Compress-Archive -Path "$oculumTestDist\*" -DestinationPath (Join-Path $oculumDist 'Oculum-Test-Windows.zip') -Force
}
Copy-Item -LiteralPath (Join-Path $oculumRoot 'docs\items-pergamene-e-tiri.md') -Destination (Join-Path $oculumDist 'LEGGIMI-MODIFICHE.md') -Force
Write-Output "Pacchetto $Target completato."
