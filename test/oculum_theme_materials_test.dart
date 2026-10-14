import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:oculum/main.dart' show oculumDefaultElementIds;
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_resource_bar_fx.dart';
import 'package:oculum/widgets/oculum_theme_asset_packs.dart';

void main() {
  testWidgets('Wood and ash textures leave underlying controls clickable', (
    tester,
  ) async {
    for (final entry in <(String, OculumGothFamily)>[
      ('restyle_legno', OculumGothFamily.wood),
      ('restyle_cenere', OculumGothFamily.ash),
    ]) {
      var taps = 0;
      final spec = OculumGothOrnaments(
        family: entry.$2,
        ink: Colors.brown,
        accent: Colors.amber,
        opacity: .3,
        themeId: entry.$1,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: OculumGothAmbience(
            spec: spec,
            child: Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => taps++,
                  child: const Text('VC · Attacco'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(ValueKey('theme-material-${entry.$1}-${entry.$2.name}')),
        findsOneWidget,
      );
      await tester.tap(find.text('VC · Attacco'));
      expect(taps, 1, reason: entry.$1);
      expect(tester.takeException(), isNull, reason: entry.$1);
    }
  });

  testWidgets('every built-in resistance element gets an animated motif', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OculumElementMotifClock(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final element in oculumDefaultElementIds)
                    Row(
                      children: [
                        OculumElementSigil(
                          elementId: element,
                          color: Colors.lightGreen,
                        ),
                        Text(element),
                        TextButton(
                          onPressed: () => taps++,
                          child: const Text('resistenza'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      find.byType(OculumElementSigil),
      findsNWidgets(oculumDefaultElementIds.length),
    );
    await tester.tap(find.text('resistenza').first);
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  test(
    'Acid and Spirituality presets have registered texture and art packs',
    () async {
      for (final id in ['restyle_acido', 'restyle_spiritualita']) {
        expect(oculumThemeAssetPacks, contains(id));
        final pack = oculumThemeAssetPacks[id]!;
        expect(await rootBundle.load(pack.relic), isNotNull);
      }
      expect(
        await rootBundle.load('assets/themes/materials/acid.png'),
        isNotNull,
      );
      expect(
        await rootBundle.load('assets/themes/materials/spirit.png'),
        isNotNull,
      );
    },
  );

  test(
    'Falling flames animate and remain within the decorative gutter',
    () async {
      const spec = OculumGothOrnaments(
        family: OculumGothFamily.ember,
        ink: Colors.brown,
        accent: Colors.amber,
        opacity: .4,
        themeId: 'ember_rite',
      );
      final frames = <List<int>>[];
      for (final phase in [.04, .12]) {
        final recorder = ui.PictureRecorder();
        OculumGothPainter(
          spec,
          particles: true,
          clock: AlwaysStoppedAnimation(phase),
        ).paint(Canvas(recorder), const Size(320, 600));
        final picture = recorder.endRecording();
        final image = await picture.toImage(320, 600);
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        frames.add(pixels.buffer.asUint8List().toList());
        for (var y = 0; y < 600; y++) {
          expect(
            pixels.getUint8((y * 320 + 160) * 4 + 3),
            0,
            reason: 'Flames must never cover the center controls.',
          );
        }
        expect(frames.last.any((value) => value > 0), isTrue);
        image.dispose();
        picture.dispose();
      }
      expect(
        frames[0],
        isNot(frames[1]),
        reason: 'The particles must move over time.',
      );
    },
  );
}
