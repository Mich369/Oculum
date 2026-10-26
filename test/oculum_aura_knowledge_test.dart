import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/game/oculum_combat_scout_rules.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;

void main() {
  test(
    'all observation packets stay out of attack UI and replay as observations',
    () {
      for (final kind in ['scout', 'power_scanner', 'aura_compare']) {
        expect(oculumCombatRequestIsObservation({'kind': kind}), true);
      }
      expect(oculumCombatRequestIsObservation({'kind': 'attack'}), false);
      expect(oculumCombatRequestIsObservation({'kind': 'help'}), false);
    },
  );
  test(
    'Aura threshold and exact-reading chance respect 99/100 target boundary',
    () {
      expect(oculumAuraReadsPower(19), false);
      expect(oculumAuraReadsPower(20), true);
      expect(oculumExactPowerChance(20, success: true, targetPower: 99), 0);
      expect(oculumExactPowerChance(21, success: true, targetPower: 99), 5);
      expect(oculumExactPowerChance(40, success: true, targetPower: 99), 100);
      expect(oculumExactPowerChance(40, success: true, targetPower: 100), 0);
      expect(oculumExactPowerChance(41, success: true, targetPower: 100), 5);
      expect(oculumExactPowerChance(60, success: true, targetPower: 100), 100);
      expect(oculumExactPowerChance(100, success: false, targetPower: 1), 0);
      expect(oculumScoutNoSpendChance(-1), 0);
      expect(oculumScoutNoSpendChance(32), 32);
      expect(oculumScoutNoSpendChance(95), 95);
      expect(oculumScoutNoSpendChance(110), 95);
    },
  );

  test(
    'new discoveries replace the number, old replies and estimates preserve exact knowledge',
    () {
      var record = oculumMergeKnownPower({}, {'exactPower': 83}, 10);
      record = oculumMergeKnownPower(record, {'exactPower': 94}, 20);
      record = oculumMergeKnownPower(record, {'exactPower': 70}, 15);
      record = oculumMergeKnownPower(record, {'scannerEstimate': 100}, 30);
      record = oculumMergeKnownPower(record, {'powerBand': 'stronger'}, 40);
      expect(record['exactPower'], 94);
      expect(record['scannerEstimate'], 100);
      expect(oculumMergeKnownPower(record, {'exactPower': -1}, 50), record);
    },
  );

  testWidgets(
    'automatic Aura replies reveal only a category until exact knowledge is authorized',
    (tester) async {
      final (_, p) = await fixtures.mountFight(tester);
      final request = <String, dynamic>{
        'id': 'aura:test:100',
        'sourceTag': 'OTHER',
        'targetTag': p.ownerTag(),
        'observerAura': 19,
        'observerPower': 50,
        'refreshKnownPower': true,
      };
      expect(p.auraReply(0, request), isEmpty);
      request['observerAura'] = 20;
      final qualitative = p.auraReply(0, request);
      expect(qualitative['powerBand'], isNotNull);
      expect(qualitative.containsKey('exactPower'), false);
      expect(qualitative.containsKey('observerPower'), false);
      expect(qualitative.containsKey('stats'), false);
      p.auraPermit(0, 'OTHER');
      expect(p.auraReply(0, request)['exactPower'], isA<int>());
      request['refreshKnownPower'] = false;
      expect(p.auraReply(0, request).containsKey('exactPower'), false);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'power knowledge survives saves and encounter changes without sharing internal power',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      p.learnPower('ENEMY', {'exactPower': 83}, order: 10);
      p.learnPower('ENEMY', {'exactPower': 97}, order: 20);
      p.learnPower('ENEMY', {'exactPower': 40}, order: 15);
      p.auraBand('ENEMY', 'stronger');
      final saved = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(p.snapshot())) as Map,
      );
      p.load(saved);
      state.selectedMasterInitiativeGroupId = 'another-encounter';
      expect(p.knownPower('ENEMY')['exactPower'], 97);
      expect(p.knownPower('ENEMY')['powerBand'], 'stronger');
      state.selectedMasterInitiativeGroupId = 'encounter_1';
      state.masterInitiativeTokens.first['auraPowerInternal'] = 999;
      state.masterInitiativeTokens.first['auraPowerRevision'] = 3;
      p.recordCurrentEncounter();
      final public = p.publicEncounter(
        Map<String, dynamic>.from(state.masterInitiativeGroups.first as Map),
      );
      expect(jsonEncode(public), isNot(contains('auraPowerInternal')));
      expect(jsonEncode(public), isNot(contains('knownPowers')));
      expect(jsonEncode(public), contains('auraPowerRevision'));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'Aura20 automatically discovers and refreshes own power, retained below the threshold',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final aura = state.hiddenEyeStats.firstWhere(
        (dynamic s) => s.id == 'lettura_aura',
      );
      aura.unlocked = true;
      aura.valore = 20;
      p.invalidateDerivedCaches();
      p.observeAura();
      await tester.pump();
      final own = p.ownerTag();
      final first = p.knownPower(own)['exactPower'] as int;
      state.currentResilienzaController.text =
          '${int.parse(state.currentResilienzaController.text) + 3}';
      p.invalidateDerivedCaches();
      p.observeAura();
      await tester.pump();
      expect(p.knownPower(own)['exactPower'], first + 3);
      aura.unlocked = false;
      p.invalidateDerivedCaches();
      p.observeAura();
      await tester.pump();
      expect(p.knownPower(own)['exactPower'], first + 3);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    '95 percent free observation does not spend a resource and exhaustion still blocks reactions',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.masterInitiativeActiveIndex = 0;
      state.masterInitiativeRound = 2;
      final token = state.masterInitiativeTokens.first as Map<String, dynamic>;
      p.refreshTurnResources(token);
      expect(await p.spendScout(110, percentile: 94), true);
      expect(token['actionUsed'], false);
      expect(await p.spendScout(110, percentile: 95), true);
      expect(token['actionUsed'], true);
      state.masterInitiativeActiveIndex = 1;
      p.totalPowerBurst(100, 3);
      expect(await p.spendScout(110, percentile: 0), false);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  for (final width in [320.0, 1440.0]) {
    testWidgets(
      'small power badges fit and distinguish exact numbers from estimates at $width',
      (tester) async {
        final (_, p) = await fixtures.mountFight(tester);
        p.learnPower('ENEMY', {'exactPower': 97}, order: 20);
        p.learnPower('ALLY', {'scannerEstimate': 83}, order: 30);
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final widgets = [p.powerBadge('ENEMY'), p.powerBadge('ALLY')];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Column(children: widgets)),
          ),
        );
        await tester.pump();
        expect(find.text('Potenza 97'), findsOneWidget);
        expect(find.text('Potenza ≈ 83'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }
}
