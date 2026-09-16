import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'owner long rest revives only its dead eyes; eye rest cannot heal death',
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
      final directory = Directory(
        'build/afona-test-${DateTime.now().microsecondsSinceEpoch}',
      )..createSync(recursive: true);
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
      final homeKey = GlobalKey();
      await tester.pumpWidget(MaterialApp(home: OculumHomePage(key: homeKey)));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump(const Duration(seconds: 1));
      final dynamic state = homeKey.currentState!;
      final probe = OculumPerformanceProbe(homeKey.currentState!);
      state.schedePersonaggio.add(<String, dynamic>{
        'sheetTag': 'owner-test',
        'nome': 'Owner',
      });
      state.schedaCorrente = 0;
      final ownerTag = probe.ownerTag();
      Map<String, dynamic> dead(String id, String owner, int bond) => {
        'id': id,
        'name': id,
        'ownerSheetId': owner,
        'rarity': 'raro',
        'originalRarity': 'raro',
        'bond': bond,
        'rebirthsUsed': 0,
        'perdutoPerSempre': true,
        'deathWounds': 3,
        'currentHp': 0,
        'sheetData': {'currentHp': '0', 'feriteMorte': 3, 'derivedMaxHp': 200},
      };
      final own = dead('own', ownerTag, 300);
      final other = dead('other', 'another-owner', 600);
      final empty = dead('empty', ownerTag, 0);
      state.occhiCaduti
        ..clear()
        ..addAll([own, other, empty]);
      probe.shortRest();
      expect(oculumFallenEyeIsDead(own), true);
      probe.longRest();
      expect(own['currentHp'], 20);
      expect(own['rebirthsUsed'], 1);
      expect(own['bond'], 300);
      expect(oculumFallenEyeIsDead(other), true);
      expect(oculumFallenEyeIsDead(empty), true);
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump(const Duration(seconds: 1));
      state.schedePersonaggio[state.schedaCorrente]['occhioCadutoId'] = 'empty';
      state.currentHpController.text = '0';
      probe.longRest();
      expect(state.currentHpController.text, '0');
      expect(oculumFallenEyeIsDead(empty), true);
      probe.cancelPendingSave();
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
