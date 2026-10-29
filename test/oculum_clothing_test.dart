import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';

void main() {
  testWidgets(
    'clothes preserve growth and halve only their own broken shield bonuses',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final regular = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      for (final family in [
        'Poppins',
        'Roboto',
        'serif',
        'Segoe UI',
        'Garamond',
        'Georgia',
      ]) {
        await (FontLoader(family)..addFont(Future.value(regular))).load();
      }
      final icons = File(
        'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
      );
      if (icons.existsSync()) {
        await (FontLoader('MaterialIcons')..addFont(
              Future.value(ByteData.sublistView(icons.readAsBytesSync())),
            ))
            .load();
      }
      final directory = Directory('build/layout-test-data')
        ..createSync(recursive: true);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => directory.absolute.path,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (_) async => ['none'],
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
        (_) async => null,
      );
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final capture = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: RepaintBoundary(key: capture, child: const OculumHomePage()),
        ),
      );
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump(const Duration(seconds: 1));
      final dynamic state = tester.state(find.byType(OculumHomePage));
      final probe = OculumPerformanceProbe(state);

      final item = probe.merchantItem({
        'kind': 'clothing',
        'name': 'Veste prova',
        'level': 12,
        'growthStat': 'materia',
        'growthEvery': 3,
        'shield': 6,
        'tempHp': 10,
        'damage': 2,
        'defence': 2,
        'desc': 'test',
      });
      item.equipaggiata = true;
      expect(item.ability, isNotNull);
      expect(probe.itemBonuses(item)['materia'], 4);
      expect(probe.itemBonuses(item)['hp_temp'], 10);
      item.scudoIntegritaCorrente = 0;
      expect(probe.itemBonuses(item)['materia'], 2);
      expect(probe.itemBonuses(item)['hp_temp'], 5);
      final restored = InventoryItem.fromJson(item.toJson());
      expect(probe.itemBonuses(restored)['materia'], 2);
      restored.scudoIntegritaCorrente = 6;
      expect(probe.itemBonuses(restored)['materia'], 4);
      expect(probe.planeId, 'mezzano');
      final cyber = probe.merchantItem({
        'kind': 'postea_cyber_armor',
        'name': 'Corazza test',
        'variant': 2,
        'desc': 'test',
      });
      expect(cyber.craftData['purchaseShield'], probe.itemShield(cyber));
      cyber.equipaggiata = true;
      final oldDamage = probe.itemBonuses(cyber)['danni'] ?? 0;
      cyber.craftData['cyberWorn'] = true;
      cyber.scudoIntegritaCorrente = 0;
      expect(probe.itemShield(cyber), 0);
      expect(probe.itemBonuses(cyber)['danni'], oldDamage ~/ 2);
      final savedCyber = InventoryItem.fromJson(cyber.toJson());
      savedCyber.scudoIntegritaCorrente = 999;
      expect(
        probe.itemShield(savedCyber),
        0,
        reason: 'worn cyber shield cannot recharge automatically',
      );
      state.ascensionDustController.text = '100';
      state.inventario.add(item);
      probe.convertItemTitle(item);
      expect(item.craftData['titleItem'], isTrue);
      expect(item.buff, restored.buff);
      expect(state.ascensionDustController.text, '97');
      final convertedJson = InventoryItem.fromJson(item.toJson());
      expect(convertedJson.craftData['evolvable'], isTrue);
      if (state.schedePersonaggio.isEmpty) {
        state.schedePersonaggio.add(<String, dynamic>{
          'id': 'AMULET_OWNER',
          'sheetTag': 'AMULET_OWNER',
          'nome': 'Prova',
        });
        state.schedaCorrente = 0;
      }
      final amulet = InventoryItem(
        nome: 'Amuleto Teschio',
        peso: .1,
        quantita: 1,
        note: '',
        equipaggiata: true,
        craftData: {'necromancyKind': 'skull_amulet'},
      );
      state.inventario.add(amulet);
      final originalMaximumHp = probe.maximumHp();
      // Use valid wounded HP. The raw startup controller can still contain the
      // old 30 HP while Level 0 / Grade 0 / Resilience 3 now has 18 maximum HP.
      final originalHp = (originalMaximumHp - 3)
          .clamp(1, originalMaximumHp)
          .toString();
      state.currentHpController.text = originalHp;
      final originalTag = probe.ownerTag();
      await probe.useNecromancy(amulet);
      expect(
        state.schedePersonaggio[state.schedaCorrente]['skullFormOriginal'],
        isA<Map>(),
      );
      expect(probe.ownerTag(), originalTag);
      state.currentHpController.text = '0';
      probe.skullHit();
      expect(state.currentHpController.text, originalHp);
      expect(probe.maximumHp(), originalMaximumHp);
      expect(probe.ownerTag(), originalTag);
      expect(
        state.schedePersonaggio[state.schedaCorrente]['skullFormOriginal'],
        isNull,
      );
      expect(
        state.inventario.any(
          (dynamic i) => i.craftData['usedSinceLongRest'] == true,
        ),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
