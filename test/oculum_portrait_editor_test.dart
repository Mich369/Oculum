import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:oculum/main.dart';

void main() {
  Uint8List sourceImage({int width = 1600, int height = 900}) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(32, 96, 180));
    return Uint8List.fromList(img.encodePng(image));
  }

  test('portrait preview is bounded before interactive editing', () {
    final prepared = oculumPreparePortraitEditorPreview(<String, dynamic>{
      'bytes': sourceImage(),
      'maxDimension': 512,
    });
    final bytes = prepared['bytes'] as Uint8List;
    final preview = img.decodeImage(bytes);

    expect(preview, isNotNull);
    expect(preview!.width, lessThanOrEqualTo(512));
    expect(preview.height, lessThanOrEqualTo(512));
    expect(prepared['width'], 1600);
    expect(prepared['height'], 900);
  });

  test('final portrait keeps requested quality dimensions off the preview', () {
    final rendered = oculumRenderPortraitEditorCrop(<String, dynamic>{
      'bytes': sourceImage(width: 900, height: 1600),
      'zoom': 1.8,
      'offsetX': 0.35,
      'offsetY': -0.25,
      'rotationDegrees': 90,
      'flipHorizontal': true,
      'contrast': 1.1,
      'saturation': 0.9,
      'brightness': 1.05,
      'outputSize': 960,
      'outputQuality': 92,
    });
    final decoded = img.decodeImage(rendered);

    expect(rendered, isNotEmpty);
    expect(decoded, isNotNull);
    expect(decoded!.width, 960);
    expect(decoded.height, 960);
  });

  test('invalid portrait bytes are rejected without replacing data', () {
    final invalid = Uint8List.fromList(<int>[1, 2, 3, 4]);

    expect(
      oculumPreparePortraitEditorPreview(<String, dynamic>{'bytes': invalid}),
      isEmpty,
    );
    expect(
      oculumRenderPortraitEditorCrop(<String, dynamic>{'bytes': invalid}),
      isEmpty,
    );
  });
}
