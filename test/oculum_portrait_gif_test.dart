import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:oculum/game/oculum_portrait_gif.dart';
import 'package:oculum/widgets/oculum_portrait_gif_editor.dart';

Uint8List portraitSource() {
  final source = img.Image(width: 112, height: 200, numChannels: 3);
  for (final pixel in source) {
    pixel.setRgb(pixel.y, pixel.x, 12);
  }
  return img.encodePng(source);
}

const bottom = (x: 0.0, y: 1.0, zoom: 1.25);
const top = (x: 0.0, y: -1.0, zoom: 1.25);

void main() {
  test(
    'a bottom-to-top portrait GIF moves the crop at constant zoom',
    () async {
      final bytes = await oculumRenderPortraitGif((
        source: portraitSource(),
        start: bottom,
        end: top,
        milliseconds: 1500,
        returnTrip: false,
      ));
      expect(bytes, isNotNull);
      expect(oculumCanImportPortraitGif(bytes!), isTrue);
      expect(bytes.length, lessThanOrEqualTo(oculumPortraitGifMaxBytes));
      expect(oculumPortraitFileType(bytes), (
        extension: 'gif',
        mimeType: 'image/gif',
      ));

      final decoded = img.decodeGif(bytes)!;
      expect(decoded.numFrames, 12);
      expect(
        decoded.frames.every((frame) => frame.frameDuration == 130),
        isTrue,
      );
      final x = decoded.width ~/ 2;
      final y = decoded.height ~/ 2;
      final first = decoded.frames.first.getPixel(x, y).r;
      final last = decoded.frames.last.getPixel(x, y).r;
      expect(first - last, greaterThan(80));
      expect(oculumPortraitAnimationCrop(112, 200, bottom).side, 90);
      expect(oculumPortraitAnimationCrop(112, 200, top).side, 90);
    },
  );

  test('a return trip reaches the other end and comes back', () async {
    final bytes = await oculumRenderPortraitGif((
      source: portraitSource(),
      start: bottom,
      end: top,
      milliseconds: 1000,
      returnTrip: true,
    ));
    final decoded = img.decodeGif(bytes!)!;
    final x = decoded.width ~/ 2;
    final y = decoded.height ~/ 2;
    final first = decoded.frames.first.getPixel(x, y).r;
    final middle = decoded.frames[decoded.numFrames ~/ 2].getPixel(x, y).r;
    final last = decoded.frames.last.getPixel(x, y).r;
    expect(first - middle, greaterThan(80));
    expect(last - middle, greaterThan(65));
  });

  test('GIF import rejects truncated, oversized and invalid canvas data', () {
    final encoder = img.GifEncoder();
    encoder.addFrame(img.Image(width: 24, height: 24));
    encoder.addFrame(img.Image(width: 24, height: 24));
    final bytes = encoder.finish()!;
    expect(oculumCanImportPortraitGif(bytes), isTrue);
    expect(
      oculumCanImportPortraitGif(bytes.sublist(0, bytes.length - 1)),
      isFalse,
    );
    final oversized = Uint8List(oculumPortraitGifMaxBytes + 1)
      ..setAll(0, bytes)
      ..[oculumPortraitGifMaxBytes] = 0x3b;
    expect(oculumCanImportPortraitGif(oversized), isFalse);
    final largeCanvas = Uint8List.fromList(bytes)
      ..[6] = 1
      ..[7] = 5;
    expect(oculumCanImportPortraitGif(largeCanvas), isFalse);
    expect(oculumIsPortraitGif(portraitSource()), isFalse);
    expect(oculumPortraitFileType(portraitSource()), (
      extension: 'png',
      mimeType: 'image/png',
    ));
    expect(oculumPortraitFileType(Uint8List.fromList([0xff, 0xd8, 0xff])), (
      extension: 'jpg',
      mimeType: 'image/jpeg',
    ));
  });

  test('the generated GIF preserves a fully transparent background', () async {
    final source = img.Image(width: 96, height: 128, numChannels: 4);
    img.fillRect(
      source,
      x1: 28,
      y1: 35,
      x2: 62,
      y2: 91,
      color: img.ColorRgba8(224, 52, 80, 255),
    );
    final gif = await oculumRenderPortraitGif((
      source: img.encodePng(source),
      start: bottom,
      end: top,
      milliseconds: 1000,
      returnTrip: false,
    ));
    final decoded = img.decodeGif(gif!)!;
    for (final frame in decoded.frames) {
      expect(frame.getPixel(0, 0).a, 0);
      expect(frame.getPixel(frame.width ~/ 2, frame.height ~/ 2).a, 255);
    }
  });

  testWidgets('a compact portrait GIF editor offers framing and presets', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final source = portraitSource();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OculumPortraitGifEditor(
            source: source,
            preview: oculumPortraitGifPreview(source)!,
            english: false,
          ),
        ),
      ),
    );

    expect(find.text('Dal basso verso l’alto'), findsOneWidget);
    expect(find.text('Inizio'), findsOneWidget);
    await tester.tap(find.text('Fine'));
    await tester.pump();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Fine'))
          .selected,
      isTrue,
    );
    await tester.tap(find.text('Dal basso verso l’alto'));
    await tester.pumpAndSettle();
    expect(find.text('Scorrimento laterale'), findsOneWidget);
    expect(find.text('Scorrimento diagonale'), findsOneWidget);
    expect(find.text('Dal dettaglio all’insieme'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
