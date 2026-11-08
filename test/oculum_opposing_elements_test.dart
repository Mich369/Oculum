import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_oblivion_percentage_parser_test.dart' show cleanFight;
import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_protection_wear_test.dart' show protection;

void main() {
  test(
    'Chaos rolls every statistic independently, including both extremes',
    () {
      final draws = [0, 10, 5, 8].iterator;
      final result = oculumOpposingChaosStatRoll((upperBound) {
        expect(upperBound, 11);
        expect(draws.moveNext(), isTrue);
        return draws.current;
      });
      expect(result, {
        'resilienza': -5,
        'volonta': 5,
        'materia': 0,
        'oculum': 3,
      });
      expect(draws.moveNext(), isFalse);
    },
  );

  testWidgets('opposing Chaos is per turn and cannot raise spendable pools', (
    tester,
  ) async {
    final (state, probe) = await cleanFight(tester);
    state.volontaController.text = '20';
    state.currentVolontaController.text = '10';
    state.materiaController.text = '20';
    state.currentMateriaController.text = '10';
    state.oculumController.text = '20';
    state.currentOculumController.text = '10';
    probe.invalidateDerivedCaches();
    final baseline = probe.formulaContext();
    final baselineSnapshot = probe.snapshot();
    final maxHp = probe.maximumHp();
    final hero = state.masterInitiativeTokens.first as Map<String, dynamic>;
    final firstEnemy = state.masterInitiativeTokens[1] as Map<String, dynamic>;
    final secondEnemy = state.masterInitiativeTokens[2] as Map<String, dynamic>;
    firstEnemy['monsterBookId'] = 'ghoul_errante';
    secondEnemy['monsterBookId'] = 'ghoul_errante';
    probe.recordCurrentEncounter();
    probe.beginRewardPowerTurn(hero);
    final initialRoll = hero['opposingChaosStats'] as Map<String, int>;
    expect(initialRoll, hasLength(4));
    expect(initialRoll.values, everyElement(inInclusiveRange(-5, 5)));

    hero['opposingChaosStats'] = <String, int>{
      'resilienza': -5,
      'volonta': 3,
      'materia': 4,
      'oculum': 5,
    };
    probe.invalidateDerivedCaches();
    probe.beginRewardPowerTurn(hero);
    final context = probe.formulaContext();
    expect(context['resilienza'], baseline['resilienza']! - 5);
    expect(context['volonta'], baseline['volonta']! + 3);
    expect(context['materia'], baseline['materia']! + 4);
    expect(context['oculum'], baseline['oculum']! + 5);
    expect(
      context['oculum_percentage_base'],
      baseline['oculum_percentage_base'],
    );
    expect(state.currentOculumController.text, '10');
    expect(probe.maximumHp(), maxHp);
    final snapshot = probe.snapshot();
    for (final key in [
      'derivedResilienzaTotal',
      'derivedVolontaTotal',
      'derivedMateriaTotal',
      'derivedOculumTotal',
      'derivedDanno',
      'derivedDifesa',
      'derivedCM',
      'derivedVC',
      'derivedRiflessi',
    ]) {
      expect(snapshot[key], baselineSnapshot[key], reason: key);
    }
    expect(probe.formulaContext()['volonta'], context['volonta']);

    firstEnemy['status'] = 'dead';
    secondEnemy['status'] = 'fled';
    state.masterInitiativeRound = (state.masterInitiativeRound as int) + 1;
    probe.beginRewardPowerTurn(hero);
    expect(hero['opposingChaosStats'], isNull);
    expect(probe.formulaContext()['volonta'], baseline['volonta']);
    await closeFixture(tester, probe);
  });

  for (final (description, useTemporaryHp, expectPain) in [
    ('the same blow breaks armor and injures Life', false, true),
    ('temporary Life absorbs the blow that broke armor', true, false),
  ]) {
    testWidgets('Oblivion logs only once when $description', (tester) async {
      final (state, probe) = await cleanFight(tester);
      final armor = protection('Corazza', kind: 'armor', defense: 10);
      armor.craftData['wearUsesRemaining'] = 1;
      state.inventario.add(armor);
      probe.equipItem(armor, true);
      final hero = state.masterInitiativeTokens.first as Map<String, dynamic>;
      final enemy = state.masterInitiativeTokens[1] as Map<String, dynamic>;
      enemy['monsterBookId'] = 'larva_del_grimorio';
      probe.recordCurrentEncounter();
      probe.beginRewardPowerTurn(hero);
      expect(hero['opposingOblivionExposed'], isTrue);
      expect(enemy['opposingOblivionExposed'], isNull);

      if (useTemporaryHp) state.hpTempController.text = '100';
      final beforeHit = int.parse(state.currentHpController.text as String);
      await probe.damageResolved(10, bypassDefense: true);
      expect(oculumEquipmentUses(armor), 0);
      final afterHit = int.parse(state.currentHpController.text as String);
      if (useTemporaryHp) {
        expect(afterHit, beforeHit);
        state.hpTempController.text = '0';
        await probe.damageResolved(10, bypassDefense: true);
        expect(
          int.parse(state.currentHpController.text as String),
          lessThan(beforeHit),
        );
      } else {
        expect(afterHit, lessThan(beforeHit));
      }

      final runtime = probe.planarStateSnapshot();
      final pain = (runtime['oblivionArmorPain'] as List?) ?? [];
      expect(pain, hasLength(expectPain ? 1 : 0));
      if (expectPain) {
        expect(jsonDecode(pain.single as String), [
          probe.permissionCampaignId,
          'legacy:encounter_1:0',
        ]);
      }
      final reward = <String, dynamic>{
        'id': 'fight-ending',
        'endedEncounterId': 'encounter_1',
        'oblivionFightParticipants': {probe.ownerTag(): 'legacy:encounter_1:0'},
      };
      probe.encounterRewards([reward, reward]);
      final messages = (state.logEventi as List<String>)
          .where((line) => line.contains('non ricor'))
          .toList();
      expect(messages, hasLength(1));
      expect(
        messages.single,
        endsWith(
          expectPain
              ? 'non ricordo nulla, perché sento dolore?'
              : 'non ricordi nulla',
        ),
      );
      await closeFixture(tester, probe);
    });
  }
}
