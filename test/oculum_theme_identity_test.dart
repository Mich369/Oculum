import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_theme_asset_packs.dart';
import 'package:oculum/widgets/oculum_theme_identity.dart';
import 'package:oculum/widgets/oculum_element_theme_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'every art pack has an authored material and a readable identity frame',
    () async {
      expect(
        oculumThemeIdentities.keys.toSet(),
        oculumThemeAssetPacks.keys.toSet(),
      );
      final silhouettes = <String>{};
      for (final identity in oculumThemeIdentities.values) {
        expect(identity.motif.trim(), isNotEmpty, reason: identity.id);
        expect(identity.motion.trim(), isNotEmpty, reason: identity.id);
        expect(
          File(identity.surface).existsSync(),
          isTrue,
          reason: identity.id,
        );
        final states = <String>{};
        for (final state in [
          'normal',
          'hover',
          'pressed',
          'selected',
          'disabled',
        ]) {
          final bytes = File(identity.frame(state)).readAsBytesSync();
          states.add(bytes.join(','));
          final codec = await ui.instantiateImageCodec(bytes, targetWidth: 128);
          final image = (await codec.getNextFrame()).image;
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawStraightRgba,
          ))!;
          for (var y = image.height ~/ 4; y < image.height * 3 ~/ 4; y++) {
            for (var x = image.width ~/ 4; x < image.width * 3 ~/ 4; x++) {
              expect(
                pixels.getUint8((y * image.width + x) * 4 + 3),
                0,
                reason: '${identity.id}/$state must leave labels unobscured',
              );
            }
          }
          if (state == 'normal') {
            silhouettes.add(
              [
                for (var i = 3; i < pixels.lengthInBytes; i += 4)
                  pixels.getUint8(i),
              ].join(','),
            );
          }
          image.dispose();
          codec.dispose();
        }
        expect(
          states.length,
          5,
          reason: '${identity.id} must expose distinct interaction states',
        );
      }
      expect(
        silhouettes.length,
        oculumThemeIdentities.length,
        reason: 'Material recolors alone cannot define an identity',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('Moon and Sun have opposing materials, symbols and motion', () {
    final moon = oculumThemeIdentities['element_pack_lunare']!;
    final sun = oculumThemeIdentities['element_pack_solare']!;
    expect(moon.material, isNot(sun.material));
    expect(moon.motion, 'orbit');
    expect(sun.motion, 'rays');
    expect(oculumElementThemeStyles['solare'], 'ember');
    expect(oculumElementThemeStyles['lunare'], 'lunar');
    expect(
      File(moon.frame('normal')).readAsBytesSync(),
      isNot(File(sun.frame('normal')).readAsBytesSync()),
    );
  });
}
