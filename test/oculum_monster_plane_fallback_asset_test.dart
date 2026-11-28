import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:oculum/widgets/oculum_narrative_background.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';

const _iceScene = 'assets/oculum/theme_stories/webp/plane_ghiaccio.webp';
const _iceCreatures = [
  'base_ghiaccio_01',
  'base_ghiaccio_03',
  'base_ghiaccio_06',
  'base_ghiaccio_07',
  'base_ghiaccio_08',
  'base_ghiaccio_09',
  'gnoll_delle_nevi',
];

OculumMonsterTheme _themeFor(String id) {
  final creature = monsterBookEntryById(id)!;
  return OculumMonsterTheme(creature, oculumMonsterColors(creature).first);
}

String _shownAsset(WidgetTester tester, OculumMonsterTheme monster) {
  final finder = find.byKey(ValueKey('narrative-background-${monster.id}'));
  expect(finder, findsOneWidget);
  final image = tester.widget<Image>(finder).image;
  final source = image is ResizeImage ? image.imageProvider : image;
  return (source as AssetImage).assetName;
}

void main() {
  test('ordinary plane IDs and the default retain their asset paths', () {
    expect(
      oculumMonsterPlaneFallbackAsset(null),
      'assets/oculum/theme_stories/webp/plane_mezzano.webp',
    );
    expect(
      oculumMonsterPlaneFallbackAsset('carne_viva'),
      'assets/oculum/theme_stories/webp/plane_carne_viva.webp',
    );
  });

  for (final size in const [Size(1440, 900), Size(390, 844)]) {
    testWidgets('bundled ice background and sheet art priority at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final presentation = oculumThemePresentation.value;
      final monsterThemes = oculumSheetMonsterThemes.value;
      final relicSelections = oculumSheetRelicSelections.value;
      addTearDown(() {
        oculumThemePresentation.value = presentation;
        oculumSheetMonsterThemes.value = monsterThemes;
        oculumSheetRelicSelections.value = relicSelections;
      });
      oculumThemePresentation.value = presentation.copyWith(
        motion: OculumThemeMotion.disabled,
      );
      oculumSheetRelicSelections.value = {};

      await tester.runAsync(() async {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        expect(manifest.listAssets(), contains(_iceScene));
        final bytes = await rootBundle.load(_iceScene);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThan(0));
        expect(frame.image.height, greaterThan(0));
        frame.image.dispose();
        codec.dispose();
      });

      const sheetId = 'ice-plane-fallback';
      oculumSheetMonsterThemes.value = {
        sheetId: _themeFor(_iceCreatures.first).id,
      };
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
          home: const OculumNarrativeBackground(sheetId: sheetId),
        ),
      );

      for (final id in _iceCreatures) {
        final themed = _themeFor(id);
        expect(themed.monster.planeIds.first, 'terre_di_ghiaccio');
        expect(themed.illustration, isNull);
        expect(themed.illustrationMobile, isNull);
        oculumSheetMonsterThemes.value = {sheetId: themed.id};
        await tester.pump();
        expect(_shownAsset(tester, themed), _iceScene, reason: id);
      }

      final bramble = _themeFor('bramble');
      expect(bramble.illustration, isNotNull);
      expect(bramble.illustrationMobile, isNotNull);
      expect(bramble.illustrationMobile, isNot(bramble.illustration));
      final expected = size.width < 600
          ? bramble.illustrationMobile
          : bramble.illustration;
      oculumSheetMonsterThemes.value = {sheetId: bramble.id};
      await tester.pump();
      expect(_shownAsset(tester, bramble), expected);

      final ice = _themeFor(_iceCreatures.first);
      oculumSheetMonsterThemes.value = {sheetId: ice.id};
      oculumSheetRelicSelections.value = {sheetId: bramble.id};
      await tester.pump();
      expect(_shownAsset(tester, bramble), expected);

      oculumSheetRelicSelections.value = {};
      await tester.pump();
      expect(_shownAsset(tester, ice), _iceScene);
      expect(tester.takeException(), isNull);
    });
  }
}
