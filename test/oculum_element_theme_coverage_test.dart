import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_combat_theme.dart';
import 'package:oculum/widgets/oculum_element_theme_registry.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_theme_asset_packs.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:oculum/widgets/oculum_theme_relic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Canva sources keep original resolution and a real transparent center',
    () async {
      for (final filename in [
        'ice-frame.png',
        'spirit-frame.png',
        'physical-frame.png',
      ]) {
        final codec = await ui.instantiateImageCodec(
          await File('design/materials/canva-20261016/$filename').readAsBytes(),
        );
        final image = (await codec.getNextFrame()).image;
        expect(image.width, 1776, reason: filename);
        expect(image.height, 896, reason: filename);
        final pixels = await image.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        final center =
            ((image.height ~/ 2) * image.width + image.width ~/ 2) * 4 + 3;
        expect(pixels!.getUint8(center), 0, reason: filename);
        image.dispose();
        codec.dispose();
      }
    },
  );
  test('each official Resistance element has a named preset and real art', () {
    expect(
      oculumElementThemePackIds.keys.toSet(),
      oculumDefaultElementIds.toSet(),
    );
    expect(oculumElementPresets, hasLength(oculumDefaultElementIds.length));
    expect(oculumElementThemePackIds.values.toSet(), hasLength(58));
    for (final element in oculumDefaultElementIds) {
      final preset = oculumElementPresets.singleWhere(
        (preset) => preset.id == 'element_$element',
      );
      expect(preset.primary.computeLuminance(), greaterThan(.4));
      final family = oculumCombatElementFamily(element);
      expect(family, isNotNull, reason: element);
      final pack = oculumResolveThemeArt(
        OculumGothOrnaments(
          family: family!,
          ink: Colors.white,
          accent: Colors.blue,
          opacity: .5,
          themeId: preset.id,
        ),
        const OculumThemePresentation(),
      );
      expect(pack.id, oculumElementThemePackIds[element]);
      expect(oculumThemeAssetPacks.containsKey(pack.id), isTrue);
      for (final state in [
        'normal',
        'hover',
        'pressed',
        'selected',
        'disabled',
      ]) {
        expect(
          File(pack.buttonFrame(state)).existsSync(),
          isTrue,
          reason: '$element/$state',
        );
      }
      for (final variant in ['still', 'alive']) {
        expect(
          File(pack.frame('panel', variant: variant)).existsSync(),
          isTrue,
        );
        expect(
          File(pack.scene(mobile: true, variant: variant)).existsSync(),
          isTrue,
        );
      }
    }
  });

  test('Italian ice and spirituality aliases resolve correctly', () {
    expect(oculumCombatElementId('Ghiaccio'), 'gelo');
    expect(oculumCombatElementId('Spiritualità'), 'spirituale');
    expect(oculumCombatElementFamily('cenere'), OculumGothFamily.ash);
  });
}
