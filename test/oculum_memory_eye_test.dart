import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_diary_links.dart';
import 'package:oculum/services/oculum_diary_memory.dart';
import 'package:oculum/services/oculum_diary_roles.dart';
import 'package:oculum/widgets/oculum_memory_eye.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('role icons keep native dimensions and transparent borders', () async {
    for (final entry in {
      'npc': 512,
      'enemy': 512,
      'dead': 1254,
      'obliterated': 256,
    }.entries) {
      final bytes = await File(oculumMemoryEyeAsset(entry.key)!).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final image = (await codec.getNextFrame()).image;
      expect(image.width, entry.value);
      expect(image.height, entry.value);
      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      expect(pixels.getUint8(3), 0);
      expect(pixels.getUint8((image.width * image.height - 1) * 4 + 3), 0);
      var visible = 0;
      var transparent = 0;
      for (var i = 0; i < pixels.lengthInBytes; i += 4) {
        final alpha = pixels.getUint8(i + 3);
        if (alpha == 0) transparent++;
        if (alpha > 0) {
          visible++;
          if (entry.key == 'obliterated') {
            expect(
              pixels.getUint8(i) < 225 ||
                  pixels.getUint8(i + 1) < 225 ||
                  pixels.getUint8(i + 2) < 225,
              isTrue,
            );
          }
        }
      }
      expect(visible, greaterThan(100));
      expect(transparent, greaterThan(visible));
      image.dispose();
      codec.dispose();
    }
    expect(oculumMemoryEyeAsset('party'), oculumMemoryEyeAsset('npc'));
    expect(oculumMemoryEyeAsset('creature'), oculumMemoryEyeAsset('enemy'));
  });

  test('Oblio classification persists without changing source or identity', () {
    final entities = diaryEntitiesFromLinks(['[[Obliterato:Arven]]']);
    expect(entities.single.kind, 'obliterated');
    final ledger = DiaryRoleLedger();
    const npc = DiaryEntity('npc:arven', 'Arven', 'npc');
    expect(ledger.change(npc, 'obliterated', DateTime(2026, 10, 1)), isTrue);
    final restored = DiaryRoleLedger.fromJson(ledger.toJson());
    expect(restored.roleOf(npc), 'obliterated');
    expect(restored.historyFor(npc).single['from'], 'npc');
    expect(diaryCreationLinkTypes, contains('Obliterato'));
  });

  testWidgets('changing role switches the eye asset immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: OculumMemoryEye(role: 'npc')),
    );
    expect(
      (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName,
      oculumMemoryEyeAsset('npc'),
    );
    await tester.pumpWidget(
      const MaterialApp(home: OculumMemoryEye(role: 'obliterated')),
    );
    expect(
      (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName,
      oculumMemoryEyeAsset('obliterated'),
    );
    expect(tester.takeException(), isNull);
  });
}
