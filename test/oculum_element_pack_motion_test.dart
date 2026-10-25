import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_element_ambient_art.dart';
import 'package:oculum/widgets/oculum_element_theme_registry.dart';
import 'package:oculum/widgets/oculum_theme_asset_packs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    '55 new packs have distinct original silhouettes and complete exports',
    () async {
      final specs =
          jsonDecode(
                await File(
                  'docs/design/element-pack-specs.json',
                ).readAsString(),
              )
              as List;
      expect(specs, hasLength(55));
      final signatures = <int>{};
      for (final spec in specs) {
        final pack = oculumThemeAssetPacks[spec['id']]!;
        expect(oculumElementThemePackIds[spec['element']], pack.id);
        expect(
          File('design/themes/${pack.id}/panel-alive.svg').existsSync(),
          isTrue,
        );
        final codec = await ui.instantiateImageCodec(
          await File(pack.frame('panel', variant: 'alive')).readAsBytes(),
          targetWidth: 1024,
        );
        final image = (await codec.getNextFrame()).image;
        final pixels = await image.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        final alpha = <int>[
          for (var i = 3; i < pixels!.lengthInBytes; i += 4) pixels.getUint8(i),
        ];
        var hash = 0x811c9dc5;
        for (final value in alpha) {
          hash = ((hash ^ value) * 0x01000193) & 0xffffffff;
        }
        signatures.add(hash);
        expect(
          alpha[(image.height ~/ 2) * image.width + image.width ~/ 2],
          0,
          reason: pack.id,
        );
        image.dispose();
        codec.dispose();
        for (final role in [
          'panel',
          'mobile',
          'portrait',
          'statistics',
          'separator',
        ]) {
          for (final variant in ['still', 'alive']) {
            expect(
              File(pack.frame(role, variant: variant)).existsSync(),
              isTrue,
              reason: '${pack.id}/$role/$variant',
            );
          }
        }
        for (final state in [
          'normal',
          'hover',
          'pressed',
          'selected',
          'disabled',
        ]) {
          expect(File(pack.buttonFrame(state)).existsSync(), isTrue);
        }
      }
      expect(
        signatures.length,
        55,
        reason: 'Different geometry, not only different color',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'every element has matching motion confined to reading-safe margins',
    () async {
      for (final entry in oculumElementThemeMotions.entries) {
        expect(
          oculumElementForArtPack(oculumElementThemePackIds[entry.key]!),
          entry.key,
        );
        final frames = <String>[];
        for (final phase in [.11, .37]) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          OculumElementAmbientPainter(
            clock: AlwaysStoppedAnimation(phase),
            element: entry.key,
            color: Colors.white,
          ).paint(canvas, const Size(200, 100));
          final picture = recorder.endRecording();
          final image = await picture.toImage(200, 100);
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawStraightRgba,
          ))!;
          for (var y = 17; y < 83; y++) {
            for (var x = 17; x < 183; x++) {
              expect(
                pixels.getUint8((y * 200 + x) * 4 + 3),
                0,
                reason: '${entry.key} covered the reading center',
              );
            }
          }
          frames.add(base64Encode(pixels.buffer.asUint8List()));
          image.dispose();
          picture.dispose();
        }
        expect(
          frames[0],
          isNot(frames[1]),
          reason: '${entry.key} has no visible animation',
        );
      }
      expect(oculumElementThemeMotions, hasLength(61));
    },
  );
}
