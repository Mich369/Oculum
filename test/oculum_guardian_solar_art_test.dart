import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_monster_book_page.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:oculum/widgets/oculum_narrative_background.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';

void main() {
  final monster = monsterBookEntryById('guardiano_solare')!;
  final theme = OculumMonsterTheme(monster, oculumMonsterColors(monster).first);

  for (final width in [320.0, 834.0, 1440.0]) {
    testWidgets(
      'Guardian uses its dedicated background at ${width.toInt()}px without blocking controls',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final previous = oculumSheetRelicSelections.value;
        addTearDown(() => oculumSheetRelicSelections.value = previous);
        oculumSheetRelicSelections.value = {'guardian-art-preview': theme.id};
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(
              extensions: const [
                OculumGothOrnaments(
                  family: OculumGothFamily.crystal,
                  ink: Colors.white,
                  accent: Colors.amber,
                  opacity: .3,
                  themeId: 'classic_reliquary',
                ),
              ],
            ),
            home: Scaffold(
              body: Stack(
                children: [
                  const Positioned.fill(
                    child: OculumNarrativeBackground(
                      sheetId: 'guardian-art-preview',
                    ),
                  ),
                  Center(
                    child: FilledButton(
                      onPressed: () => taps++,
                      child: const Text('Attacco'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        final image = tester.widget<Image>(find.byType(Image).first);
        final provider = image.image;
        final asset = provider is ResizeImage
            ? provider.imageProvider
            : provider;
        expect(
          (asset as AssetImage).assetName,
          width < 600 ? theme.illustrationMobile : theme.illustration,
        );
        await tester.runAsync(
          () => precacheImage(
            image.image,
            tester.element(find.byType(Image).first),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Attacco'));
        expect(taps, 1);
      },
    );

    testWidgets(
      'Guardian relic stays inside margins at ${width.toInt()}px and preserves input',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 240,
                  height: 280,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => taps++,
                          child: const SizedBox.expand(),
                        ),
                      ),
                      OculumMonsterRelic(theme: theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        final image = tester.widget<Image>(find.byType(Image));
        expect((image.image as AssetImage).assetName, theme.relicIllustration);
        expect(image.fit, BoxFit.contain);
        await tester.runAsync(
          () => precacheImage(image.image, tester.element(find.byType(Image))),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(Image)).width, lessThan(240));
        expect(tester.getSize(find.byType(Image)).height, lessThan(280));
        await tester.tapAt(tester.getCenter(find.byType(OculumMonsterRelic)));
        expect(taps, 1);
      },
    );
  }

  testWidgets(
    'Purchased Guardian page contains its background and no portrait',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 500,
                child: OculumMonsterBookPage(
                  monster: monster,
                  purchased: true,
                  child: const Text('Guardiano Solare'),
                ),
              ),
            ),
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, theme.illustration);
      expect(image.fit, BoxFit.contain);
      expect(image.alignment, Alignment.center);
      final clip = tester.widget<ClipRRect>(
        find.byKey(const ValueKey('purchased-monster-page-guardiano_solare')),
      );
      expect(clip.clipBehavior, Clip.hardEdge);
      expect(find.byType(OculumMonsterRelic), findsNothing);
      await tester.runAsync(
        () => precacheImage(image.image, tester.element(find.byType(Image))),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Guardian relic PNG has real transparent margins and a near-opaque subject',
    () async {
      final data = await rootBundle.load(theme.relicIllustration!);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final rgba = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final bytes = rgba.buffer.asUint8List();
      // ImageGen's antialiased PNG has a few edge samples at alpha 1/255.
      // They are visually transparent; require the corners to be exactly zero
      // and a large genuinely zero-alpha background, not a painted backdrop.
      for (var x = 0; x < image.width; x++) {
        expect(bytes[x * 4 + 3], lessThanOrEqualTo(1));
        expect(
          bytes[((image.height - 1) * image.width + x) * 4 + 3],
          lessThanOrEqualTo(1),
        );
      }
      for (var y = 0; y < image.height; y++) {
        expect(bytes[y * image.width * 4 + 3], lessThanOrEqualTo(1));
        expect(
          bytes[(y * image.width + image.width - 1) * 4 + 3],
          lessThanOrEqualTo(1),
        );
      }
      for (final corner in [
        3,
        (image.width - 1) * 4 + 3,
        (image.height - 1) * image.width * 4 + 3,
        (image.height * image.width - 1) * 4 + 3,
      ]) {
        expect(bytes[corner], 0);
      }
      final alphas = [for (var i = 3; i < bytes.length; i += 4) bytes[i]];
      expect(
        alphas.where((a) => a == 0).length / alphas.length,
        greaterThan(.6),
      );
      // The generated cutout quantizes its solid subject to alpha 250–254.
      // Require substantial solid coverage instead of one alpha-255 sample.
      expect(
        alphas.where((a) => a >= 250).length / alphas.length,
        greaterThan(.15),
      );
      image.dispose();
      codec.dispose();
    },
  );
}
