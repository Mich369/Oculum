param([Parameter(Mandatory)][string]$Source, [Parameter(Mandatory)][string]$Target)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;

public static class OculumRlSpritePack {
    public static void Pack(string sourcePath, string outputPath) {
        using (var source = new Bitmap(sourcePath))
        using (var rgba = source.Clone(new Rectangle(0, 0, source.Width, source.Height), PixelFormat.Format32bppArgb))
        using (var atlas = new Bitmap(1536, 768, PixelFormat.Format32bppArgb))
        using (var canvas = Graphics.FromImage(atlas)) {
            if (rgba.Width != 1774 || rgba.Height != 887) {
                throw new ArgumentException("Atlas dimensions do not match the approved reference");
            }
            var ankles = new[] {177, 650, 1095, 1546, 172, 658, 1061, 1558};
            var ground = new[] {414, 418, 415, 418, 853, 843, 848, 849};
            var heads = new[] {114, 67, 67, 81, 543, 530, 511, 511};
            int baseY = 350;
            canvas.InterpolationMode = InterpolationMode.HighQualityBicubic;
            canvas.PixelOffsetMode = PixelOffsetMode.HighQuality;
            canvas.CompositingMode = CompositingMode.SourceCopy;
            for (var index = 0; index < 8; index++) {
                int column = index % 4, row = index / 4;
                using (var sprite = new Bitmap(rgba.Width, rgba.Height, PixelFormat.Format32bppArgb)) {
                    int y0 = row == 0 ? 0 : 450, y1 = row == 0 ? 450 : rgba.Height;
                    for (int y = y0; y < y1; y++) {
                        int b1 = row == 0 ? 472 : y < 591 ? 484 : 426;
                        int b2 = row == 0 ? 894 : 887;
                        int b3 = row == 0 ? 1329 : 1321;
                        int x0 = column == 0 ? 0 : column == 1 ? b1 : column == 2 ? b2 : b3;
                        int x1 = column == 0 ? b1 : column == 1 ? b2 : column == 2 ? b3 : rgba.Width;
                        for (int x = x0; x < x1; x++) {
                            var pixel = rgba.GetPixel(x, y);
                            if (pixel.A > 7) sprite.SetPixel(x, y, pixel);
                        }
                    }
                    double scale = (index == 0 || index == 4 ? 195.0 : 225.0) / (ground[index] - heads[index]);
                    int left = column * 384 + 183 - (int)Math.Round(ankles[index] * scale);
                    int top = row * 384 + baseY - (int)Math.Round(ground[index] * scale);
                    var clip = new Rectangle(column * 384, row * 384, 384, 384);
                    canvas.SetClip(clip);
                    canvas.DrawImage(sprite, left, top, (int)Math.Round(sprite.Width * scale),
                        (int)Math.Round(sprite.Height * scale));
                    canvas.ResetClip();
                }
            }
            atlas.Save(outputPath, ImageFormat.Png);
        }
    }
}
'@
[OculumRlSpritePack]::Pack($Source, $Target)
