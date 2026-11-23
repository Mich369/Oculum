import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test('the original Welder Spider imports its editable Plasma beam', () {
    final monster = monsterBookEntryById(oculumWeldSpiderId)!;
    expect(monster.skillIds, contains(oculumWeldSpiderBeamSkill));
    expect(
      monsterBookEntryById('ragno_saldatore_recuperatore')!.skillIds,
      isNot(contains(oculumWeldSpiderBeamSkill)),
    );
    expect(
      monsterBookEntryById('${oculumWeldSpiderId}_variante_errante')!.skillIds,
      isNot(contains(oculumWeldSpiderBeamSkill)),
    );
    final beam = oculumMonsterBookSkills(
      monster,
    ).singleWhere((skill) => skill.nome == 'Raggio al plasma');
    expect(beam.forme.map((form) => form.livello), ['6', '9', '12']);
    expect(beam.forme.map((form) => form.costoStrutturato!.resource), [
      'materia',
      'materia',
      'materia',
    ]);
    expect(beam.forme.map((form) => form.costoStrutturato!.minimum), [1, 2, 3]);
    expect(beam.forme.map((form) => form.cooldownStrutturato!.openingDelay), [
      2,
      3,
      3,
    ]);
    final damage = beam.forme.map(
      (form) => form.effettiStrutturati.singleWhere(
        (effect) => effect.type == 'danno',
      ),
    );
    expect(damage.map((effect) => effect.valueExpression), ['6', '11', '16']);
    expect(damage.every((effect) => effect.elementType == 'plasma'), isTrue);
    for (final form in beam.forme) {
      final settings = {
        for (final effect in form.effettiStrutturati)
          if (oculumWeldSpiderSustainTargets.contains(effect.target))
            effect.target: effect.valueExpression,
      };
      expect(settings, {
        oculumWeldSpiderAttackPerTurn: '3',
        oculumWeldSpiderPrimaryPercent: '50',
        oculumWeldSpiderSecondaryPercent: '60',
        oculumWeldSpiderLocksPerTurn: '1',
      });
    }
    final anatomy = oculumMonsterPrecisionAnatomy(monster);
    expect(
      anatomy.map((part) => part['id']),
      contains(oculumWeldSpiderTailPart),
    );
  });

  test('tail integrity uses the actual saved limb damage', () {
    expect(oculumWeldSpiderTailIsBroken({}), isFalse);
    Map<String, dynamic> anatomy(int damage) => {
      'parts': {
        oculumWeldSpiderTailPart: {'maximumHp': 10, 'damageTaken': damage},
      },
    };
    expect(oculumWeldSpiderTailIsBroken(anatomy(9)), isFalse);
    expect(oculumWeldSpiderTailIsBroken(anatomy(10)), isTrue);
  });

  test('only a natural 20 from the original spider yields its scroll', () {
    List<InventoryItem> drops(String id, int natural, int total) =>
        oculumGenerateMonsterLoot(
              monster: monsterBookEntryById(id)!,
              level: 6,
              grade: 1,
              random: Random(0),
              killId: 'weld-spider-fight',
              naturalDropRoll: natural,
              dropTotal: total,
            )
            .where(
              (item) =>
                  item.monsterLoot['sourceSkillId'] ==
                  oculumWeldSpiderBeamSkill,
            )
            .toList();
    expect(drops(oculumWeldSpiderId, 19, 100), isEmpty);
    expect(drops('${oculumWeldSpiderId}_variante_errante', 20, 20), isEmpty);
    final item = drops(oculumWeldSpiderId, 20, 20).single;
    final data = item.craftData['scroll'] as Map;
    expect(data['element'], 'plasma');
    expect(data['skillLevel'], 6);
    final damage = (data['effects'] as List).singleWhere(
      (effect) => effect['type'] == 'danno',
    );
    expect(damage['valueExpression'], '6');
    expect(data['authoredSkill'], isA<Map>());
    expect(item.monsterLoot['naturalDropRoll'], 20);
  });

  test('complete turns add accuracy and independent lock damage', () {
    expect(oculumWeldSpiderSustainedAttack(35, 0), 35);
    expect(oculumWeldSpiderSustainedAttack(35, 1), 38);
    expect(oculumWeldSpiderSustainedAttack(35, 2), 41);
    expect(oculumWeldSpiderSustainedDamage(61, primaryLocks: 0), 61);
    expect(oculumWeldSpiderSustainedDamage(61, primaryLocks: 1), 92);
    expect(oculumWeldSpiderSustainedDamage(61, primaryLocks: 2), 122);
    expect(oculumWeldSpiderSustainedDamage(61), 37);
    expect(oculumWeldSpiderSustainedDamage(61, secondaryPercent: 80), 49);
    expect(oculumWeldSpiderSustainedAttack(35, 2, bonusPerTurn: 4), 43);
  });

  testWidgets(
    'a saved spider gains its beam once and a broken tail clears it',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final sheet = <String, dynamic>{
        ...probe.snapshot(),
        'monsterBookSourceId': oculumWeldSpiderId,
        'planarRuntime': {
          'anatomicalParts': {
            'parts': {
              oculumWeldSpiderTailPart: {'maximumHp': 10, 'damageTaken': 10},
            },
          },
        },
      };
      state.schedePersonaggio[0] = sheet;
      probe.load(sheet);
      final rawSkills = (sheet['skills'] as List).whereType<Map>();
      final raw = rawSkills.singleWhere(
        (skill) => skill['nome'] == 'Raggio al plasma',
      );
      final skill = CharacterSkill.fromJson(Map<String, dynamic>.from(raw));
      probe.load(sheet);
      expect(
        rawSkills.where((entry) => entry['nome'] == 'Raggio al plasma'),
        hasLength(1),
      );
      probe.applyEffects(skill.forme.first.effettiStrutturati);
      expect(
        probe.structuredEffects().any((raw) => raw['type'] == 'pending_target'),
        isTrue,
      );
      await probe.planAttack(targetId: 'ENEMY', natural: 16, total: 31);
      expect(state.onlineCombatRequests, isEmpty);
      expect(
        probe.structuredEffects().any((raw) => raw['type'] == 'pending_target'),
        isFalse,
      );
      expect(state.logEventi, contains(contains('coda è rotta')));
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'a learned beam can focus after launch and resolves each target once',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final owner = probe.ownerTag();
      state.currentHpController.text = '20';
      final sheet = state.schedePersonaggio[0] as Map;
      final requests = state.onlineCombatRequests as Map;
      final opening = <String, dynamic>{
        'id': 'plasma-opening',
        'sourceTag': owner,
        'targetTag': 'ENEMY',
        'sourceName': 'Eroe',
        'scope': probe.permissionScope,
        'encounterId': probe.activeCombatEncounterId,
        'damage': 61,
        'attack': 35,
        'natural': 17,
        'dieFaces': 20,
        'element': 'plasma',
      };
      probe.startWeldSpiderBeamForTest(opening);
      await probe.advanceWeldSpiderBeamForTest(owner, 1);
      expect(find.byType(SimpleDialog), findsNothing);
      sheet['combatConcentrationPending'] = true;
      probe.focusWeldSpiderBeamForTest(1);
      await probe.advanceWeldSpiderBeamForTest(owner, 2);
      expect(requests, isEmpty);

      Future<void> nextTurn(int turn, String option) async {
        final advance = probe.advanceWeldSpiderBeamForTest(owner, turn);
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining(option));
        await tester.pumpAndSettle();
        await advance;
      }

      await nextTurn(3, '60% Danni base');
      expect(
        requests.values.map((raw) => raw['damage']),
        unorderedEquals([61, 37]),
      );
      expect(
        requests.values.every(
          (raw) => raw['attack'] == 38 && raw['natural'] == 17,
        ),
        isTrue,
      );
      await probe.advanceWeldSpiderBeamForTest(owner, 3);
      expect(requests, hasLength(2));
      final restored = probe.snapshot();
      expect(restored['combatConcentrationPending'], isTrue);
      state.schedePersonaggio[0] = restored;
      probe.load(restored);
      await probe.advanceWeldSpiderBeamForTest(owner, 3);
      expect(requests, hasLength(2));
      await nextTurn(4, '+50% Danni base');
      final second = requests.values.where((raw) => raw['attack'] == 41);
      expect(second.map((raw) => raw['damage']), unorderedEquals([92, 37]));

      restored['combatConcentrationPending'] = false;
      await probe.advanceWeldSpiderBeamForTest(owner, 5);
      expect(requests, hasLength(4));
      expect(find.byType(SimpleDialog), findsNothing);
      await closeFixture(tester, probe);
    },
  );
}
