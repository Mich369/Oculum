import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_theme_asset_packs.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('every theme frame has a fully transparent reading center', () async {
    for (final pack in oculumThemeAssetPacks.values) {
      for (final role in [
        'panel',
        'mobile',
        'portrait',
        'statistics',
        'separator',
      ]) {
        final codec = await ui.instantiateImageCodec(
          await File(pack.frame(role)).readAsBytes(),
          targetWidth: 64,
        );
        final image = (await codec.getNextFrame()).image;
        final pixels = await image.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        final center =
            ((image.height ~/ 2) * image.width + image.width ~/ 2) * 4 + 3;
        expect(
          pixels!.getUint8(center),
          0,
          reason: '${pack.id}/$role reading center',
        );
        expect(pixels.buffer.asUint8List().where((v) => v > 0), isNotEmpty);
        image.dispose();
        codec.dispose();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
  test(
    'both art variants ship transparent PNGs for every theme role',
    () async {
      for (final pack in oculumThemeAssetPacks.values) {
        for (final variant in ['still', 'alive']) {
          for (final role in [
            'panel',
            'mobile',
            'portrait',
            'statistics',
            'separator',
          ]) {
            final file = File(pack.frame(role, variant: variant));
            expect(
              file.existsSync(),
              isTrue,
              reason: '${pack.id}/$role/$variant',
            );
            final codec = await ui.instantiateImageCodec(
              await file.readAsBytes(),
              targetWidth: 64,
            );
            final image = (await codec.getNextFrame()).image;
            final pixels = await image.toByteData(
              format: ui.ImageByteFormat.rawStraightRgba,
            );
            final center =
                ((image.height ~/ 2) * image.width + image.width ~/ 2) * 4 + 3;
            expect(
              pixels!.getUint8(center),
              0,
              reason: '${pack.id}/$role/$variant reading center',
            );
            image.dispose();
            codec.dispose();
          }
        }
      }
    },
  );
  test(
    'every registered theme relic is a real PNG with transparent pixels',
    () async {
      for (final pack in oculumThemeAssetPacks.values) {
        final bytes = await File(pack.relic).readAsBytes();
        expect(bytes.length, greaterThan(100), reason: pack.id);
        expect(bytes.take(8), [
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
        ], reason: pack.id);
        final codec = await ui.instantiateImageCodec(bytes, targetWidth: 64);
        final image = (await codec.getNextFrame()).image;
        final pixels = await image.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        var transparent = 0;
        var visible = 0;
        for (var index = 3; index < pixels!.lengthInBytes; index += 4) {
          final alpha = pixels.getUint8(index);
          if (alpha < 5) transparent++;
          if (alpha > 100) visible++;
        }
        expect(transparent, greaterThan(10), reason: pack.id);
        expect(visible, greaterThan(10), reason: pack.id);
        image.dispose();
        codec.dispose();
      }
    },
  );

  test(
    'theme presentation survives reload and clamps decorative scale',
    () async {
      SharedPreferences.setMockInitialValues({});
      final original = oculumThemePresentation.value;
      addTearDown(() => oculumThemePresentation.value = original);
      await setOculumThemePresentation(
        const OculumThemePresentation().copyWith(
          motion: OculumThemeMotion.disabled,
          variant: OculumThemeVariant.alive,
          relicScale: 99,
          relicOpacity: -1,
          artPackId: 'vervain_gothic',
        ),
      );
      oculumThemePresentation.value = const OculumThemePresentation();
      await loadOculumThemePresentation();
      expect(oculumThemePresentation.value.motion, OculumThemeMotion.disabled);
      expect(oculumThemePresentation.value.variant, OculumThemeVariant.alive);
      expect(oculumThemePresentation.value.relicScale, 1.3);
      expect(oculumThemePresentation.value.relicOpacity, .25);
      expect(oculumThemePresentation.value.artPackId, 'vervain_gothic');
    },
  );

  test('relic artwork selections are isolated per sheet', () async {
    SharedPreferences.setMockInitialValues({});
    final before = Map<String, String>.of(oculumSheetRelicSelections.value);
    final globalPresentation = oculumThemePresentation.value;
    addTearDown(() {
      oculumSheetRelicSelections.value = before;
      oculumThemePresentation.value = globalPresentation;
    });

    await setOculumSheetRelic('sheet-a', 'abyssal_tide');
    await setOculumSheetRelic('sheet-b', 'ember_rite');

    expect(oculumSheetRelicSelections.value['sheet-a'], 'abyssal_tide');
    expect(oculumSheetRelicSelections.value['sheet-b'], 'ember_rite');
    expect(
      oculumThemePresentationForSheet('sheet-a').artPackId,
      'abyssal_tide',
    );
    expect(oculumThemePresentationForSheet('sheet-b').artPackId, 'ember_rite');
    expect(oculumThemePresentation.value, globalPresentation);

    await setOculumSheetRelic('sheet-a', '');
    expect(oculumSheetRelicSelections.value.containsKey('sheet-a'), isFalse);
    expect(oculumThemePresentationForSheet('sheet-a'), globalPresentation);
    expect(oculumSheetRelicSelections.value['sheet-b'], 'ember_rite');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('oculum.sheetRelicSelections'), contains('sheet-b'));
  });
}
