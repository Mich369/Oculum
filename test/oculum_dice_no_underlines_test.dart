import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all die shapes keep the result area free of yellow facet lines', () async {
    for (final faces in [4, 6, 8, 10, 12, 20, 100]) {
      const size = Size(130, 130);
      final recorder = ui.PictureRecorder();
      D20Painter(
        fillColor: Colors.black,
        lineColor: Colors.yellow,
        glow: false,
        tertiaryColor: Colors.orange,
        faces: faces,
      ).paint(Canvas(recorder), size);
      final image = await recorder.endRecording().toImage(130, 130);
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(pixels, isNotNull);

      var yellowPixels = 0;
      for (var y = 40; y < 90; y++) {
        for (var x = 45; x < 85; x++) {
          final offset = (y * 130 + x) * 4;
          final red = pixels!.getUint8(offset);
          final green = pixels.getUint8(offset + 1);
          final blue = pixels.getUint8(offset + 2);
          if (red > 180 && green > 150 && blue < 100) yellowPixels++;
        }
      }
      expect(
        yellowPixels,
        0,
        reason: 'd$faces should not draw yellow facet lines through its result',
      );
      image.dispose();
    }
  });
}
