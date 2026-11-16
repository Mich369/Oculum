import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_narrative_atmosphere.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';

const _profiles = [
  'guardia_solare',
  'guardia_solare_elite',
  'guardiano_solare',
  'senka_kamaria',
];

Future<void> _showInk(
  WidgetTester tester,
  String id, {
  OculumThemeMotion motion = OculumThemeMotion.complete,
  OculumThemeVariant variant = OculumThemeVariant.alive,
  bool disableAnimations = false,
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap),
          OculumNarrativeAtmosphere(
            key: ValueKey(id),
            themeId: id,
            accent: Colors.amber,
            presentation: OculumThemePresentation(
              motion: motion,
              variant: variant,
            ),
          ),
        ],
      ),
    ),
  ),
);

Future<({int marks, int center, int signature})> _ink(
  WidgetTester tester,
) async {
  final layer = find.descendant(
    of: find.byType(OculumNarrativeAtmosphere),
    matching: find.byType(CustomPaint),
  );
  final painter = tester.widget<CustomPaint>(layer).painter!;
  final sample = await tester.runAsync(() async {
    const width = 320;
    const height = 180;
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), const Size(320, 180));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    var marks = 0;
    var center = 0;
    var signature = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = (y * width + x) * 4;
        final alpha = bytes.getUint8(index + 3);
        if (alpha == 0) continue;
        marks++;
        if (x >= width * .29 && x <= width * .71) center++;
        signature = Object.hash(signature, index, bytes.getUint32(index));
      }
    }
    image.dispose();
    picture.dispose();
    return (marks: marks, center: center, signature: signature);
  });
  return sample!;
}

void main() {
  testWidgets('solar ranks and Senka paint distinct ink at the edges', (
    tester,
  ) async {
    final signatures = <int>{};
    var taps = 0;
    for (final id in _profiles) {
      await _showInk(tester, id, onTap: () => taps++);
      await tester.pump(const Duration(seconds: 3));
      final sample = await _ink(tester);
      expect(sample.marks, greaterThan(0), reason: id);
      expect(sample.center, 0, reason: id);
      signatures.add(sample.signature);
    }
    expect(signatures, hasLength(_profiles.length));
    await tester.tapAt(const Offset(40, 80));
    expect(taps, 1);
  });

  testWidgets('theme motion reduces marks and system motion freezes the ink', (
    tester,
  ) async {
    const id = 'senka_kamaria';
    await _showInk(tester, id);
    await tester.pump(const Duration(seconds: 4));
    final complete = await _ink(tester);
    await tester.pump(const Duration(seconds: 3));
    expect((await _ink(tester)).signature, isNot(complete.signature));

    await _showInk(tester, id, motion: OculumThemeMotion.reduced);
    expect((await _ink(tester)).marks, lessThan(complete.marks));

    await _showInk(tester, id, disableAnimations: true);
    final frozen = await _ink(tester);
    expect(frozen.marks, greaterThan(0));
    await tester.pump(const Duration(seconds: 8));
    expect(await _ink(tester), frozen);

    await _showInk(tester, id, motion: OculumThemeMotion.disabled);
    expect(find.byType(CustomPaint), findsNothing);
    await _showInk(tester, id, variant: OculumThemeVariant.still);
    expect(find.byType(CustomPaint), findsNothing);
  });
}
