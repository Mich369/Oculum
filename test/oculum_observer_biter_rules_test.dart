import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_observer_biter_rules.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test('the third resolved hit is tracked per source and target', () {
    final targetOne = <String, dynamic>{};
    final targetTwo = <String, dynamic>{};
    bool hit(Map<String, dynamic> target, String source, String packet) =>
        oculumRecordSolarObserverHit(
          target,
          fightKey: 'room:first',
          sourceTag: source,
          packetId: packet,
          hit: true,
          doubleCritical: false,
        );

    expect(hit(targetOne, 'a', '1'), false);
    expect(hit(targetOne, 'b', '2'), false);
    expect(hit(targetTwo, 'a', '3'), false);
    expect(hit(targetOne, 'a', '4'), false);
    expect(hit(targetOne, 'a', '4'), false);
    expect(hit(targetOne, 'a', '5'), true);
    expect(hit(targetOne, 'a', '6'), false);
    expect(hit(targetOne, 'b', '7'), false);
    expect(hit(targetTwo, 'a', '8'), false);
  });

  test('misses and repeated packets cannot trigger gold after reload', () {
    var target = <String, dynamic>{};
    bool record(
      String fight,
      String packet, {
      bool hit = true,
      bool critical = false,
    }) => oculumRecordSolarObserverHit(
      target,
      fightKey: fight,
      sourceTag: 'a',
      packetId: packet,
      hit: hit,
      doubleCritical: critical,
    );

    expect(record('one', 'miss', hit: false, critical: true), false);
    expect(record('one', '1', critical: true), true);
    target = jsonDecode(jsonEncode(target)) as Map<String, dynamic>;
    expect(record('one', '1', critical: true), false);
    expect(record('one', '2'), false);
    expect(record('two', '3'), false);
    expect(record('two', '4'), false);
    expect(record('two', '5'), true);
  });

  test('gold escape and Sanguifang healing use the confirmed quantities', () {
    expect(oculumSolarGoldTurns, 3);
    expect(oculumSolarGoldReleaseDifficulty(7, 2), 21);
    expect(oculumSanguifangHealing(100), 15);
    expect(oculumSanguifangHealing(13), 1);
    expect(oculumSanguifangHealing(50, percent: 20), 10);
    expect(oculumSanguifangHealing(-15), 0);
  });

  test('both authored species and their configurable techniques exist', () {
    final biter = defaultMonsterBookEntries.singleWhere(
      (entry) => entry.id == oculumBitingWandererId,
    );
    final solar = defaultMonsterBookEntries.singleWhere(
      (entry) => entry.id == oculumSolarObserverId,
    );
    expect(biter.hasNaturalFlight, true);
    expect(solar.encounterRules['celestialIdentity'], 'solare');
    final bite = monsterBookConcreteTechnique(oculumBiterBiteEffect)!;
    expect(bite.forms.map((form) => form.single.formula), ['15', '15', '15']);
    expect(bite.forms.first.single.maximumTargets, 1);
    expect(monsterBookConcreteTechnique('solgaze_sguardo'), isNotNull);
    final generatedBite = oculumMonsterBookSkills(
      biter,
    ).singleWhere((skill) => skill.nome == 'Morso dell’Errante');
    expect(
      oculumCombatAbilityRoles(generatedBite.forme.first.effettiStrutturati),
      {OculumCombatAbilityRole.attack},
    );
  });

  testWidgets('resolved attacks apply gold and heal a critical biter once', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.resilienzaController.text = '20';
    state.currentResilienzaController.text = '20';
    state.currentHpController.text = '100';
    state.scudoController.text = '0';
    state.scudoCriticoController.text = '0';
    probe.invalidateDerivedCaches();
    probe.saveSheet();
    final targetTag = probe.ownerTag();
    final target = Map<String, dynamic>.from(probe.snapshot());
    Map<String, dynamic> source(String tag, String species) => {
      ...target,
      'id': tag,
      'sheetTag': tag,
      'monsterBookSourceId': species,
      'realtimeSharedSheet': false,
      'livello': '7',
      'grado': '2',
      'currentHp': '30',
      'logEventi': <String>[],
      'conditions': <Map<String, dynamic>>[],
      'planarRuntime': <String, dynamic>{},
    };
    state.schedePersonaggio.addAll(<Map<String, dynamic>>[
      source('SolgazeOcu:3690FD5G', oculumSolarObserverId),
      source('SanguifangOcu:3690FD5G', oculumBitingWandererId),
    ]);
    probe.ensureSheetTags();
    final solarTag = '${state.schedePersonaggio[1]['sheetTag']}';
    final biterTag = '${state.schedePersonaggio[2]['sheetTag']}';
    state.masterInitiativeTokens[1]['id'] =
        state.masterInitiativeTokens[1]['sheetTag'] = solarTag;
    state.masterInitiativeTokens[2]['id'] =
        state.masterInitiativeTokens[2]['sheetTag'] = biterTag;
    probe.recordCurrentEncounter();
    final encounter = probe.activeCombatEncounterId;
    Map<String, dynamic> packet(
      String id,
      String attacker, {
      bool bite = false,
    }) => {
      'id': id,
      'sourceTag': attacker,
      'sourceName': attacker,
      'sourceMonsterBookId': bite
          ? oculumBitingWandererId
          : oculumSolarObserverId,
      'targetTag': targetTag,
      'targetName': 'Target',
      'scope': probe.permissionScope,
      'encounterId': encounter,
      'status': 'pending',
      'kind': 'attack',
      'attack': 30,
      'natural': bite ? 20 : 10,
      'damage': 1,
      'choice': 'vc',
      'element': 'fisico',
      'level': 7,
      'grade': 2,
      'difficulty': 'normale',
      if (bite) ...{
        'sanguifangTotalDamage': 100,
        'effects': [
          {
            'type': 'planar',
            'target': oculumBiterBiteEffect,
            'valueExpression': '15',
          },
        ],
      },
    };
    Future<void> resolve(Map<String, dynamic> attack) async {
      state.onlineCombatRequests[attack['id']] = attack;
      await tester.runAsync(() => probe.resolveCombatDefense(attack, 'cm', 20));
      expect(attack['status'], 'resolved', reason: '${attack['id']}');
    }

    await resolve(packet('sun-1', solarTag));
    await resolve(packet('sun-2', solarTag));
    expect(
      (state.activeConditions as List)
          .whereType<OculumConditionInstance>()
          .where((c) => c.conditionType == oculumSolarGoldCondition),
      isEmpty,
    );
    await resolve(packet('sun-3', solarTag));
    final gold = (state.activeConditions as List)
        .whereType<OculumConditionInstance>()
        .singleWhere((c) => c.conditionType == oculumSolarGoldCondition);
    expect(gold.duration, 3);
    expect(gold.metadata['releaseDifficulty'], 21);
    for (var turn = 0; turn < 3; turn++) {
      probe.tickConditions(OculumConditionTickTrigger.endTurn);
    }
    expect(state.activeConditions, isNot(contains(gold)));

    final bite = packet('bite-1', biterTag, bite: true);
    await resolve(bite);
    expect(bite['sanguifangHit'], true);
    expect('${(state.schedePersonaggio as List).last['currentHp']}', '45');
    expect(
      (state.activeConditions as List)
          .whereType<OculumConditionInstance>()
          .where((c) => c.conditionType == 'sanguinamento'),
      hasLength(1),
    );
    await resolve(packet('bite-1', biterTag, bite: true));
    expect('${(state.schedePersonaggio as List).last['currentHp']}', '45');
    expect(
      (state.activeConditions as List)
          .whereType<OculumConditionInstance>()
          .singleWhere((c) => c.conditionType == 'sanguinamento')
          .stage,
      1,
    );
    await closeFixture(tester, probe);
  });
}
