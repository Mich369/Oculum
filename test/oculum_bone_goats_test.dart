import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_opposed_attack.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';

import 'oculum_oblivion_percentage_parser_test.dart' show cleanFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

const _baseId = 'caprone_d_ossa';
const _blackId = 'caprone_scheletrico_nero';
const _charge = 'Carica di Fuoco';

void main() {
  test('independent Caproni keep Carica in every generated loadout', () {
    final base = monsterById(_baseId)!;
    final black = monsterById(_blackId)!;
    expect(black.stats['resilienza'], greaterThan(base.stats['resilienza']!));
    expect(base.encounterRules[oculumBoneGoatAphoniaRule], isNull);
    expect(black.encounterRules[oculumBoneGoatAphoniaRule], 3);
    expect(
      MonsterBookEntry.fromJson(
        black.toJson(),
      ).encounterRules[oculumBoneGoatAphoniaRule],
      3,
    );
    for (final goat in [base, black]) {
      expect(goat.elementId, 'fuoco');
      for (var seed = 0; seed < 10; seed++) {
        final loadout = oculumMonsterBookLoadout(goat, random: Random(seed));
        expect(loadout.art?.skills.map((s) => s.nome), contains(_charge));
        expect(loadout.art!.skills.length + loadout.skills.length, 3);
      }
    }
  });

  for (final (form, bonus, maximum, spent) in [
    (1, 5, 1, 2),
    (2, 10, 3, 4),
    (3, 20, 5, 7),
  ]) {
    testWidgets('Carica form $form uses the opposed attack path', (
      tester,
    ) async {
      final (state, p) = await cleanFight(tester);
      final art = oculumMonsterBookArt(monsterById(_baseId)!);
      final charge = art.skills.singleWhere((skill) => skill.nome == _charge);
      final effects = charge.effettiEvoluzione(form);
      expect(effects.first.maximumTargets, maximum);
      expect(effects.first.elementType, 'fuoco');
      state.volontaController.text = '11';
      state.currentVolontaController.text = '11';
      p.invalidateDerivedCaches();

      if (form > 1) {
        state.masterInitiativeTokens.add(<String, dynamic>{
          'id': 'THIRD',
          'sheetTag': 'THIRD',
          'name': 'Terzo nemico',
          'side': 'enemy',
          'status': 'ready',
        });
      }
      p.recordCurrentEncounter();
      final baseDamage = p.damageTotal();
      expect(baseDamage, greaterThan(0));
      p.applyEffects(effects, spentResources: {'oculum': spent});
      final attack = p.planAttack(total: 30, natural: 10, maximum: maximum);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final planner = find.byType(OculumAttackPlanner);
      expect(planner, findsOneWidget);
      expect(
        tester.widget<OculumAttackPlanner>(planner).maximumTargets,
        maximum,
      );
      Navigator.of(tester.element(planner)).pop(
        OculumAttackPlan(
          'ENEMY',
          'vc',
          _charge,
          additionalTargetIds: form == 1 ? [] : ['OTHER', 'THIRD'],
          element: 'fuoco',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await attack;

      final requests = (state.onlineCombatRequests as Map).values
          .whereType<Map>()
          .where((request) => request['sourceTag'] == p.ownerTag());
      expect(requests, hasLength(form == 1 ? 1 : 3));
      expect(
        requests.map((request) => request['attack']),
        everyElement(form == 1 ? 35 : 30),
      );
      expect(
        requests.map((request) => request['damage']),
        everyElement(
          oculumDamagePerTarget(
            baseDamage,
            requests.length,
            flatBonusPerTarget: bonus + spent,
          ),
        ),
      );
      await closeFixture(tester, p);
    });
  }

  testWidgets('Nero critical applies scoped Vita Afona after the shield gate', (
    tester,
  ) async {
    final (state, p) = await cleanFight(tester);
    final endOfTurn = state.masterInitiativeTokens.first as Map;
    endOfTurn['actionUsed'] = true;
    state.masterInitiativeActiveIndex = 1;
    p.recordCurrentEncounter();

    List<Map> conditions() =>
        (state.activeConditions as List).map((c) => c.toJson() as Map).toList();
    Future<void> hit(
      String id, {
      String species = _blackId,
      int natural = 20,
      int attack = 30,
      int defense = 25,
    }) async {
      final request = <String, dynamic>{
        'id': id,
        'scope': p.permissionScope,
        'encounterId': 'encounter_1',
        'status': 'pending',
        'sourceTag': 'ENEMY',
        'sourceName': 'Caprone',
        'sourceMonsterBookId': species,
        'targetTag': p.ownerTag(),
        'attack': attack,
        'damage': 10,
        'natural': natural,
        'choice': 'vc',
        'level': 0,
        'grade': 0,
        'element': 'fuoco',
        'difficulty': 'normale',
      };
      state.onlineCombatRequests[id] = request;
      await tester.runAsync(
        () => p.resolveCombatDefense(request, 'cm', defense),
      );
      expect(request['status'], 'resolved');
    }

    await hit('base', species: _baseId);
    await hit('ordinary', natural: 10);
    await hit('avoided', defense: 31);
    expect(conditions(), isEmpty);
    state.scudoCriticoController.text = '1';
    p.invalidateDerivedCaches();
    await hit('shielded');
    expect(conditions(), isEmpty);
    state.scudoCriticoController.text = '0';
    p.invalidateDerivedCaches();
    await hit('normal-critical');
    expect(conditions().single['conditionType'], 'vita_afona');
    expect(conditions().single['duration'], 3);
    final otherCampaign = Map<String, dynamic>.from(conditions().single)
      ..['id'] = 'vita_afona_other_campaign'
      ..['metadata'] = {
        'referenceCurseSource': 'bone-goat:other:encounter_1',
        'boneGoatAphoniaEncounter': 'encounter_1',
        'boneGoatAphoniaCampaign': 'other',
      };
    state.activeConditions.add(OculumConditionInstance.fromJson(otherCampaign));
    p.addCondition('vita_afona');
    expect(conditions(), hasLength(3));

    p.encounterRewards([
      {'id': 'another-fight', 'endedEncounterId': 'encounter_2'},
    ]);
    expect(conditions(), hasLength(3));
    p.encounterRewards([
      {'id': 'bone-goat-fight', 'endedEncounterId': 'encounter_1'},
    ]);
    expect(conditions(), hasLength(2));
    expect(
      conditions().map((c) => c['conditionType']),
      everyElement('vita_afona'),
    );
    expect(
      conditions().map((c) => c['metadata']),
      unorderedEquals([null, otherCampaign['metadata']]),
    );
    await closeFixture(tester, p);
  });
}
