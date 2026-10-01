param(
  [Parameter(Mandatory=$true)][string]$SourcePath,
  [Parameter(Mandatory=$true)][string]$DestinationPath,
  [switch]$RemoveAllWhite,
  [double]$EyeCenterX = 0.5,
  [double]$EyeCenterY = 0.46,
  [double]$EyeRadiusX = 0.29,
  [double]$EyeRadiusY = 0.13,
  [int]$EdgeWhiteThreshold = 190
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
# Work on copies, keep source geometry and every retained pixel's RGB.
$source = [Drawing.Bitmap]::new([IO.Path]::GetFullPath($SourcePath))
$target = [Drawing.Bitmap]::new($source.Width, $source.Height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
try {
  $removed = 0
  for ($y = 0; $y -lt $source.Height; $y++) {
    for ($x = 0; $x -lt $source.Width; $x++) {
      $pixel = $source.GetPixel($x, $y)
      $minimum = [Math]::Min($pixel.R, [Math]::Min($pixel.G, $pixel.B))
      $maximum = [Math]::Max($pixel.R, [Math]::Max($pixel.G, $pixel.B))
      $ellipse = [Math]::Pow(($x / $source.Width - $EyeCenterX) / $EyeRadiusX, 2) + [Math]::Pow(($y / $source.Height - $EyeCenterY) / $EyeRadiusY, 2)
      $alpha = [int]$pixel.A
      if (($RemoveAllWhite -or $ellipse -gt 1) -and $minimum -ge 225 -and ($maximum - $minimum) -le 18) {
        $alpha = 0
        if ($pixel.A -gt 0) { $removed++ }
      }
      $target.SetPixel($x, $y, [Drawing.Color]::FromArgb($alpha, $pixel.R, $pixel.G, $pixel.B))
    }
  }
  # Remove the pale one-pixel matte left by JPEG/clipboard antialiasing.
  # Inspect only borders next to transparent pixels; internal metal stays intact.
  if (!$RemoveAllWhite) {
    $edges = [Collections.Generic.List[Drawing.Point]]::new()
    for ($y = 1; $y -lt $target.Height - 1; $y++) {
      for ($x = 1; $x -lt $target.Width - 1; $x++) {
        $pixel = $target.GetPixel($x, $y)
        if ($pixel.A -eq 0) { continue }
        $minimum = [Math]::Min($pixel.R, [Math]::Min($pixel.G, $pixel.B))
        $maximum = [Math]::Max($pixel.R, [Math]::Max($pixel.G, $pixel.B))
        if ($minimum -lt $EdgeWhiteThreshold -or $maximum - $minimum -gt 18) { continue }
        if ($target.GetPixel($x-1,$y).A -eq 0 -or $target.GetPixel($x+1,$y).A -eq 0 -or $target.GetPixel($x,$y-1).A -eq 0 -or $target.GetPixel($x,$y+1).A -eq 0) {
          $edges.Add([Drawing.Point]::new($x,$y))
        }
      }
    }
    foreach ($point in $edges) {
      $pixel = $target.GetPixel($point.X,$point.Y)
      $target.SetPixel($point.X,$point.Y,[Drawing.Color]::FromArgb(0,$pixel.R,$pixel.G,$pixel.B))
    }
    $removed += $edges.Count
  }
  $destination = [IO.Path]::GetFullPath($DestinationPath)
  if ($destination -eq [IO.Path]::GetFullPath($SourcePath)) { throw 'Non sovrascrivere il sorgente.' }
  $target.Save($destination, [Drawing.Imaging.ImageFormat]::Png)
  Write-Output "$destination : $($source.Width)x$($source.Height), $removed pixel bianchi resi trasparenti"
} finally { $target.Dispose(); $source.Dispose() }
