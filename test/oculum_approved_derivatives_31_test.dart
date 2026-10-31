import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pointycastle/digests/sha256.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';

String digest(Uint8List bytes) => SHA256Digest()
    .process(bytes)
    .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
    .join();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final receipt =
      jsonDecode(
            File(
              'design/approved-monster-derivatives-2026-10-31.json',
            ).readAsStringSync(),
          )
          as Map;
  final files = (receipt['files'] as List).cast<Map>();
  test(
    'nineteen approved desktops are byte-identical and select their own theme',
    () {
      final desktops =
          (jsonDecode(
                    File(
                      'design/approved-monster-desktops-2026-10-31.json',
                    ).readAsStringSync(),
                  )['files']
                  as List)
              .cast<Map>();
      expect(desktops, hasLength(19));
      expect(desktops.map((f) => f['id']).toSet(), hasLength(19));
      for (final f in desktops) {
        final bytes = File(f['asset'] as String).readAsBytesSync();
        expect(digest(bytes), f['sha256']);
        final monster = monsterBookEntryById(f['id'] as String)!;
        final theme = OculumMonsterTheme(
          monster,
          oculumMonsterColors(monster).first,
        );
        expect(theme.illustration, f['asset']);
      }
    },
  );
  test(
    'approved sixteen derivatives retain exact bytes, alpha and runtime mappings',
    () async {
      expect(files, hasLength(16));
      expect(files.map((f) => f['species']).toSet(), hasLength(8));
      for (final file in files) {
        final bytes = File(file['asset'] as String).readAsBytesSync();
        expect(digest(bytes), file['sha256']);
        final monster = monsterBookEntryById(file['species'] as String)!;
        final theme = OculumMonsterTheme(
          monster,
          oculumMonsterColors(monster).first,
        );
        expect(
          file['kind'] == 'phone'
              ? theme.illustrationMobile
              : theme.relicIllustration,
          file['asset'],
        );
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final rgba = await frame.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        expect(rgba, isNotNull);
        var transparent = 0;
        var visible = 0;
        for (var i = 3; i < rgba!.lengthInBytes; i += 4) {
          final alpha = rgba.getUint8(i);
          if (alpha == 0) transparent++;
          if (alpha >= 128) visible++;
        }
        expect(visible, greaterThan(0), reason: '${file['asset']}');
        if (file['kind'] == 'relic') {
          expect(
            transparent,
            greaterThan(0),
            reason: 'The relic needs real alpha.',
          );
        } else {
          expect(frame.image.height, greaterThan(frame.image.width));
        }
        frame.image.dispose();
        codec.dispose();
      }
    },
  );
  for (final width in [320.0, 834.0, 1440.0]) {
    testWidgets('new relics preserve taps and layout at width $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final id in files.map((f) => f['species'] as String).toSet()) {
        final monster = monsterBookEntryById(id)!;
        var tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => tapped = true,
                    child: const SizedBox.expand(),
                  ),
                  Center(
                    child: OculumMonsterRelic(
                      theme: OculumMonsterTheme(
                        monster,
                        oculumMonsterColors(monster).first,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.tapAt(Offset(width / 2, 450));
        expect(tapped, true, reason: id);
        expect(tester.takeException(), isNull, reason: id);
      }
    });
  }
}
