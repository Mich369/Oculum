import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final files = <Map>[
    for (final receipt in [
      'design/approved-meccanio-packs-2026-11-01.json',
      'design/approved-fire-shield-pack-2026-11-01.json',
    ])
      ...((jsonDecode(File(receipt).readAsStringSync()) as Map)['files']
              as List)
          .cast<Map>(),
  ];
  final ids = [
    'meccanio',
    'meccanio_ammaccato',
    'meccanio_primordiale',
    'fire_shield',
  ];
  OculumMonsterTheme themeFor(String id) {
    final entry = monsterBookEntryById(id)!;
    return OculumMonsterTheme(entry, oculumMonsterColors(entry).first);
  }

  test('four approved packs bind all twelve exact PNG revisions', () {
    expect(files, hasLength(12));
    expect(files.map((f) => f['asset']).toSet(), hasLength(12));
    expect(files.map((f) => f['species']).toSet(), ids.toSet());
    for (final id in ids) {
      final theme = themeFor(id);
      expect(theme.preserveIllustrationFraming, isTrue);
      final pack = files.where((f) => f['species'] == id);
      expect(pack.map((f) => f['kind']).toSet(), {'desktop', 'phone', 'relic'});
      for (final file in pack) {
        expect(file['user_approved'], isTrue);
        final bytes = File(file['asset'] as String).readAsBytesSync();
        final hash = SHA256Digest()
            .process(bytes)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        expect(hash, file['sha256']);
        final binding = switch (file['kind']) {
          'desktop' => theme.illustration,
          'phone' => theme.illustrationMobile,
          'relic' => theme.relicIllustration,
          _ => null,
        };
        expect(binding, file['asset']);
      }
    }
  });

  test('relics have real alpha and visible margins on every edge', () async {
    for (final file in files.where((f) => f['kind'] == 'relic')) {
      final codec = await ui.instantiateImageCodec(
        File(file['asset'] as String).readAsBytesSync(),
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      var visible = 0;
      var minX = image.width, minY = image.height, maxX = -1, maxY = -1;
      var edgeAlpha = 0;
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final alpha = data.getUint8((y * image.width + x) * 4 + 3);
          if (alpha > 8) {
            visible++;
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
          if (x == 0 ||
              y == 0 ||
              x == image.width - 1 ||
              y == image.height - 1) {
            if (alpha > edgeAlpha) edgeAlpha = alpha;
          }
        }
      }
      expect(visible, greaterThan(100));
      expect(minX, greaterThanOrEqualTo(image.width * .12));
      expect(maxX, lessThanOrEqualTo(image.width * .88));
      expect(minY, greaterThanOrEqualTo(image.height * .12));
      expect(maxY, lessThanOrEqualTo(image.height * .88));
      // Native cutouts may retain invisible alpha1 pixels; visible margins
      // above use alpha>8, while fully opaque edge pixels remain forbidden.
      expect(edgeAlpha, lessThanOrEqualTo(1));
      image.dispose();
      codec.dispose();
    }
  });

  for (final id in ids) {
    for (final width in [320.0, 834.0, 1440.0]) {
      testWidgets('$id relic leaves controls clickable at $width px', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final theme = themeFor(id);
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
        final widget = tester.widget<Image>(find.byType(Image));
        expect(widget.fit, BoxFit.contain);
        expect((widget.image as AssetImage).assetName, theme.relicIllustration);
        await tester.runAsync(
          () => precacheImage(widget.image, tester.element(find.byType(Image))),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(tester.getRect(find.byType(Image)).width, lessThan(240));
        expect(tester.getRect(find.byType(Image)).height, lessThan(280));
        await tester.tapAt(tester.getCenter(find.byType(OculumMonsterRelic)));
        expect(taps, 1);
      });
    }
  }
}
