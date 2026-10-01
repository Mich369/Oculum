import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saved formulas load without HP / attack recursion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final fixtureDirectory = Directory(
      'build/save-role-regression-${DateTime.now().microsecondsSinceEpoch}',
    )..createSync(recursive: true);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => fixtureDirectory.absolute.path,
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (_) async => ['none'],
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (_) async => null,
    );
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.dark(), home: const OculumHomePage()),
    );
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(seconds: 1));
    final dynamic state = tester.state(find.byType(OculumHomePage));
    final probe = OculumPerformanceProbe(state);
    await tester.runAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      state.sharedPreferencesFuture = Future<SharedPreferences>.value(prefs);
      state.saveBlobDirectoryFuture = Future<Directory>.value(fixtureDirectory);
      final old = jsonEncode({'notes': 'x' * (1024 * 1024), 'unknown': 'old'});
      final updated = jsonEncode({
        'notes': 'y' * (1024 * 1024),
        'unknown': 'new',
      });
      await prefs.setString('large_fixture', old);
      expect(await probe.writeBlob('large_fixture', updated), isTrue);
      expect(prefs.getString('large_fixture'), isNull);
      expect(await probe.readBlob('large_fixture'), updated);
      expect(await probe.readBlob('large_fixture_legacy_preferences'), old);
    });
    final legacySheet = probe.snapshot()
      ..['resilienza'] = '20'
      ..['currentResilienza'] = '20'
      ..['currentHp'] = '100'
      ..['attaccoRapido'] = '20'
      ..['buffMalusRapidi'] = '@Danni+Volonta/2 @Difesa+Materia/2';
    for (final role in ['', 'Tank', 'Glass cannon']) {
      final sheet = {...legacySheet, 'humanoidRole': role};
      state.schedePersonaggio
        ..clear()
        ..add(sheet);
      state.schedaCorrente = 0;
      probe.load(sheet);
      expect(probe.formulaContext()['vc'], isNotNull);
      expect(probe.maximumHp(), greaterThan(0));
      expect(probe.attackBonus(), greaterThanOrEqualTo(20));
    }
    final sheet = {...legacySheet, 'humanoidRole': ''};
    state.schedePersonaggio[0] = sheet;
    probe.load(sheet);
    final originalVc = probe.attackVc();
    final originalDamage = probe.outgoingDamage();
    final increasedAttack = {...sheet, 'attaccoRapido': '37'};
    state.schedePersonaggio[0] = increasedAttack;
    probe.load(increasedAttack);
    expect(
      probe.attackVc(),
      originalVc,
      reason: 'Damage bonus must not change VC',
    );
    expect(probe.outgoingDamage(), originalDamage + 17);
    final increasedVc = {...increasedAttack, 'buffMalusRapidi': '@VC+4'};
    state.schedePersonaggio[0] = increasedVc;
    probe.load(increasedVc);
    expect(probe.attackVc(), originalVc + 4);
    final withoutVcBuff = {...increasedVc, 'buffMalusRapidi': ''};
    state.schedePersonaggio[0] = withoutVcBuff;
    probe.load(withoutVcBuff);
    final damageWithoutVcBuff = probe.outgoingDamage();
    state.schedePersonaggio[0] = increasedVc;
    probe.load(increasedVc);
    // The existing @VC command also grants 3 Will per VC. Preserve this
    // authored rule: +12 Will damage and +4 VC damage, each counted once.
    expect(probe.outgoingDamage(), damageWithoutVcBuff + 16);

    // Optional private recovery copy: never read or write the user's live store.
    const fixturePath = String.fromEnvironment('OculumRecoveryFixture');
    if (fixturePath.isNotEmpty) {
      final data =
          jsonDecode(File(fixturePath).readAsStringSync())
              as Map<String, dynamic>;
      var loaded = 0;
      final sheets = <Map<String, dynamic>>[
        for (final sheet in (data['schedePersonaggio'] as List? ?? []))
          Map<String, dynamic>.from(sheet as Map),
        for (final campaign in (data['campaigns'] as List? ?? []))
          for (final sheet in (campaign['schedePersonaggio'] as List? ?? []))
            Map<String, dynamic>.from(sheet as Map),
      ];
      for (final sheet in sheets) {
        state.schedePersonaggio[0] = sheet;
        probe.load(sheet);
        expect(probe.maximumHp(), greaterThan(0), reason: '${sheet['nome']}');
        expect(probe.formulaContext()['vc'], isNotNull);
        loaded++;
      }
      debugPrint('Recovery fixture: $loaded saved sheets loaded successfully.');
      await tester.runAsync(() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'oculum_save_v9_manual_rgb_opacity_clean',
          jsonEncode(data),
        );
        state.sharedPreferencesFuture = Future<SharedPreferences>.value(prefs);
        state.saveBlobDirectoryFuture = Future<Directory>.value(
          fixtureDirectory,
        );
        await probe.reloadSave();
      });
      expect(state.salvataggioBloccatoPerErrore, isFalse);
      expect(
        state.schedePersonaggio.length,
        (data['schedePersonaggio'] as List).length,
      );
      expect(state.campagneOculum.length, (data['campaigns'] as List).length);
      debugPrint(
        'Full saved campaign startup succeeded: ${state.schedePersonaggio.length} sheets, ${state.campagneOculum.length} campaigns.',
      );
    }
    probe.cancelPendingSave();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
