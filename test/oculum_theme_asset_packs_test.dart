import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_theme_asset_packs.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
          relicScale: 99,
          relicOpacity: -1,
          artPackId: 'vervain_gothic',
        ),
      );
      oculumThemePresentation.value = const OculumThemePresentation();
      await loadOculumThemePresentation();
      expect(oculumThemePresentation.value.motion, OculumThemeMotion.disabled);
      expect(oculumThemePresentation.value.relicScale, 1.3);
      expect(oculumThemePresentation.value.relicOpacity, .25);
      expect(oculumThemePresentation.value.artPackId, 'vervain_gothic');
    },
  );
}
