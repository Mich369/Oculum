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

const _complete = [
  'funghetto_cappuccio_rosso',
  'costrutto_minore',
  'shadow_devil',
  'mostro_sabbia',
  'gigante_sabbia',
  'mezzo_demone_cosciente',
  'nuvola_in_bottiglia',
  'il_doppione',
  'aberrazione_metallica_angelica',
  'aberrazione_metallica_solare',
  'mezzo_demone_massiccio',
  'weak_horror_mastino',
  'forest_demon',
  'ciclo_forest_demon_blu',
  'sciamano_malizioso',
];
const _desktopOnly = [
  'sharp',
  'topino_avventuroso',
  'mosca_campana',
  'custode_campana_cieca',
  'mammuth_in_decomposizione',
  'armadillo_corazzato',
];

void main() {
  for (final id in [..._complete, ..._desktopOnly]) {
    final monster = monsterBookEntryById(id)!;
    final theme = OculumMonsterTheme(
      monster,
      oculumMonsterColors(monster).first,
    );
    for (final width in [320.0, 834.0, 1440.0]) {
      testWidgets(
        '$id approved theme at $width preserves controls and margins',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final previous = oculumSheetRelicSelections.value;
          addTearDown(() => oculumSheetRelicSelections.value = previous);
          oculumSheetRelicSelections.value = {'approved-preview': theme.id};
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
                        sheetId: 'approved-preview',
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
          final provider = image.image is ResizeImage
              ? (image.image as ResizeImage).imageProvider
              : image.image;
          expect(
            (provider as AssetImage).assetName,
            width < 600
                ? theme.illustrationMobile ?? theme.illustration
                : theme.illustration,
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

          if (_complete.contains(id)) {
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
            final relic = tester.widget<Image>(find.byType(Image));
            expect(
              (relic.image as AssetImage).assetName,
              theme.relicIllustration,
            );
            expect(relic.fit, BoxFit.contain);
            await tester.runAsync(
              () => precacheImage(
                relic.image,
                tester.element(find.byType(Image)),
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            expect(tester.getSize(find.byType(Image)).width, lessThan(240));
            expect(tester.getSize(find.byType(Image)).height, lessThan(280));
            await tester.tapAt(
              tester.getCenter(find.byType(OculumMonsterRelic)),
            );
            expect(taps, 2);
          } else {
            expect(
              theme.illustrationMobile,
              isNull,
              reason: 'Unapproved derivatives must stay out',
            );
            expect(theme.relicIllustration, isNull);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
        },
      );
    }
    testWidgets(
      '$id purchased page keeps illustration inside the page without a portrait',
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
                    child: Text(monster.nameIt),
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
          find.byKey(ValueKey('purchased-monster-page-$id')),
        );
        expect(clip.clipBehavior, Clip.hardEdge);
        expect(find.byType(OculumMonsterRelic), findsNothing);
      },
    );
    if (_complete.contains(id)) {
      test(
        '$id relic has real alpha and a contained visible subject',
        () async {
          final data = await rootBundle.load(theme.relicIllustration!);
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
          );
          final image = (await codec.getNextFrame()).image;
          final rgba = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List();
          var transparent = 0;
          var opaque = 0;
          var visibleMargin = image.width;
          for (var y = 0; y < image.height; y++) {
            for (var x = 0; x < image.width; x++) {
              final alpha = rgba[(y * image.width + x) * 4 + 3];
              if (alpha == 0) transparent++;
              if (alpha >= 250) opaque++;
              if (alpha >= 32) {
                for (final margin in [
                  x,
                  y,
                  image.width - 1 - x,
                  image.height - 1 - y,
                ]) {
                  if (margin < visibleMargin) visibleMargin = margin;
                }
              }
            }
          }
          expect(transparent, greaterThan(image.width * image.height ~/ 3));
          expect(opaque, greaterThan(100));
          expect(visibleMargin, greaterThanOrEqualTo(20));
          for (final index in [
            3,
            (image.width - 1) * 4 + 3,
            (image.height - 1) * image.width * 4 + 3,
            (image.width * image.height - 1) * 4 + 3,
          ]) {
            expect(rgba[index], lessThanOrEqualTo(1));
          }
          image.dispose();
          codec.dispose();
        },
      );
    }
  }
}
