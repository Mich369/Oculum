param(
    [string]$WebSource = "",
    [string]$DistributionRoot = ""
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
if ([string]::IsNullOrWhiteSpace($WebSource)) {
    $WebSource = Join-Path $projectRoot "build\web"
}
if ([string]::IsNullOrWhiteSpace($DistributionRoot)) {
    $DistributionRoot = Join-Path $projectRoot "build\distribution"
}

$resolvedWebSource = (Resolve-Path -LiteralPath $WebSource).Path
$resolvedDistributionRoot = (Resolve-Path -LiteralPath $DistributionRoot).Path
$packageRoot = Join-Path $resolvedDistributionRoot "Oculum-Linux-Portable-Web"
$archivePath = Join-Path $resolvedDistributionRoot "Oculum-Linux-Portable-Web.zip"

if (-not $packageRoot.StartsWith(
    $resolvedDistributionRoot,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw "Percorso del pacchetto fuori dalla distribution."
}
if (-not (Test-Path -LiteralPath (Join-Path $resolvedWebSource "index.html"))) {
    throw "Build Web non trovata: $resolvedWebSource"
}

if (Test-Path -LiteralPath $packageRoot) {
    Remove-Item -LiteralPath $packageRoot -Recurse -Force
}
New-Item -ItemType Directory -Path (Join-Path $packageRoot "app") -Force |
    Out-Null
Copy-Item -Path (Join-Path $resolvedWebSource "*") `
    -Destination (Join-Path $packageRoot "app") -Recurse -Force
Copy-Item -LiteralPath (
    Join-Path $projectRoot "linux\portable\Avvia-Oculum-Linux.sh"
) -Destination $packageRoot -Force
Copy-Item -LiteralPath (
    Join-Path $projectRoot "linux\portable\LEGGIMI.txt"
) -Destination $packageRoot -Force

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (Test-Path -LiteralPath $archivePath) {
    Remove-Item -LiteralPath $archivePath -Force
}

$fileStream = [System.IO.File]::Open(
    $archivePath,
    [System.IO.FileMode]::CreateNew
)
try {
    $archive = [System.IO.Compression.ZipArchive]::new(
        $fileStream,
        [System.IO.Compression.ZipArchiveMode]::Create,
        $false
    )
    try {
        $packageBaseUri = [System.Uri]::new(
            $packageRoot.TrimEnd("\") + "\"
        )
        foreach ($file in Get-ChildItem -LiteralPath $packageRoot -File -Recurse) {
            $fileUri = [System.Uri]::new($file.FullName)
            $relativePath = [System.Uri]::UnescapeDataString(
                $packageBaseUri.MakeRelativeUri($fileUri).ToString()
            )
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive,
                $file.FullName,
                $relativePath,
                [System.IO.Compression.CompressionLevel]::Optimal
            ) | Out-Null
        }
    }
    finally {
        $archive.Dispose()
    }
}
finally {
    $fileStream.Dispose()
}

$item = Get-Item -LiteralPath $archivePath
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $archivePath).Hash
Write-Output (
    "Pacchetto Linux portatile: {0}`nDimensione: {1}`nSHA256: {2}" -f
    $item.FullName,
    $item.Length,
    $hash
)
