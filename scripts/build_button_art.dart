import 'dart:io';
import 'package:image/image.dart' as img;

/// Export dedicated transparent button states from the retained theme art.
/// Corners retain their original pixel geometry for Flutter nine-slice use.
void main() {
  for (final folder in Directory(
    'assets/themes',
  ).listSync().whereType<Directory>()) {
    final frame = File('${folder.path}/frames/panel.png');
    if (!frame.existsSync()) continue;
    final original = img.decodePng(frame.readAsBytesSync())!;
    final image = img.copyResize(original, width: 1024, height: 512);
    for (final state in [
      'normal',
      'hover',
      'pressed',
      'selected',
      'disabled',
    ]) {
      final output = img.Image.from(image);
      final factor = switch (state) {
        'hover' => 1.25,
        'pressed' => .65,
        'selected' => 1.4,
        'disabled' => .45,
        _ => 1.0,
      };
      for (final pixel in output) {
        if (pixel.a == 0) continue;
        pixel.r = (pixel.r * factor).clamp(0, 255);
        pixel.g = (pixel.g * factor).clamp(0, 255);
        pixel.b = (pixel.b * factor).clamp(0, 255);
        if (state == 'disabled') pixel.a = pixel.a * .5;
      }
      File(
        '${folder.path}/frames/button-$state.png',
      ).writeAsBytesSync(img.encodePng(output));
    }
    stdout.writeln('Exported ${folder.path} button states');
  }
}
