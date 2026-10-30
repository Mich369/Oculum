import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

CharacterSkillForm _form(String species, String skillId, {int form = 1}) {
  final art = oculumMonsterBookArt(monsterById(species)!);
  final name = monsterBookConcreteTechnique(skillId)!.name;
  final skill = art.skills.firstWhere((s) => s.nome == name);
  return oculumEquipmentAbilityFromArt(skill).forme[form - 1];
}

Future<(dynamic, OculumPerformanceProbe)> _mount(
  WidgetTester tester, {
  String species = 'armadillo_corazzato',
  bool ownTurn = true,
}) async {
  final (state, probe) = await fixtures.mountFight(tester);
  state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
      species;
  state.livelloController.text = '0';
  state.gradoController.text = '0';
  state.resilienzaController.text = '10';
  state.currentResilienzaController.text = '10';
  state.materiaController.text = '21';
  state.currentMateriaController.text = '21';
  state.currentHpController.text = '60';
  state.arti.clear();
  state.skills.clear();
  state.titoli.clear();
  state.trattiRazziali.clear();
  state.inventario.clear();
  state.activeStructuredEffects.clear();
  state.activeConditions.clear();
  state.masterInitiativeRound = 2;
  state.masterInitiativeActiveIndex = ownTurn ? 0 : 1;
  final token = state.masterInitiativeTokens.first as Map<String, dynamic>;
  token.addAll(<String, dynamic>{
    'actionUsed': false,
    'actionTurnRound': 2,
    'reactionPoolInitialized': true,
    'reactionPoolRound': 2,
    'reactionNormalFirstRoundLocked': false,
    'reactionMax': 1,
    'reactionPoints': 1,
    'reactionUsed': 0,
    'reactionUsedRound': 2,
    'reactionFastMax': 1,
    'fastReactionPoints': 1,
    'reactionFastUsed': 0,
  });
  probe.recordCurrentEncounter();
  probe.invalidateDerivedCaches();
  return (state, probe);
}

Future<bool> _use(
  WidgetTester tester,
  OculumPerformanceProbe probe,
  CharacterSkillForm form,
) async {
  final pending = probe.useConfiguredForTest(form);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  final confirm = find.widgetWithText(FilledButton, 'Conferma');
  if (confirm.evaluate().isNotEmpty) {
    await tester.tap(confirm.last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
  return pending;
}

void main() {
  testWidgets(
    'closed shell rejects stale exposed-body targets on the defender',
    (tester) async {
      final (state, probe) = await _mount(tester);
      expect(probe.anatomicalTargetAvailable('belly'), isTrue);
      probe.applyEffects(
        _form('armadillo_corazzato', 'armadillo_roll_up').effettiStrutturati,
      );
      expect(probe.anatomicalTargetAvailable('belly'), isFalse);
      expect(probe.anatomicalTargetAvailable('shell'), isTrue);
      final before = probe.currentHp();
      final packet = <String, dynamic>{
        'id': 'stale-armadillo-belly',
        'scope': probe.permissionScope,
        'encounterId': 'encounter_1',
        'sourceTag': 'enemy',
        'targetTag': probe.ownerTag(),
        'targetBodyPart': 'belly',
        'status': 'pending',
        'attack': 100000,
        'choice': 'precisione_punto_debole',
        'natural': 20,
        'dieFaces': 20,
        'damage': 1000,
        'element': 'fisico',
        'level': 0,
        'grade': 0,
        'effects': <Map<String, dynamic>>[],
      };
      state.onlineCombatRequests[packet['id']] = packet;
      await probe.resolveCombatDefense(packet, 'cm', 20, natural: 10);
      expect(packet['referenceAnatomicalTargetUnavailable'], isTrue);
      expect(probe.currentHp(), before);
      await closeFixture(tester, probe);
    },
  );
  test(
    'four distinct low-level species have biological anatomy and real pools',
    () {
      expect(oculumArmadilloSpeciesIds, hasLength(4));
      for (final id in oculumArmadilloSpeciesIds) {
        final monster = monsterById(id)!;
        expect(monster.stats['level'], lessThanOrEqualTo(2));
        expect(monster.spriteAssetPath, isEmpty);
        expect(monster.imageBase64, isEmpty);
        expect(monster.canWieldWeapons, isFalse);
        expect(
          monsterBookUsableSkillIds(monster).length,
          greaterThanOrEqualTo(16),
        );
        final parts = oculumMonsterPrecisionAnatomy(monster);
        expect(parts.where((p) => p['group'] == 'legs'), hasLength(4));
        expect(parts.where((p) => p['group'] == 'eyes'), hasLength(2));
        expect(parts.any((p) => p['group'] == 'arms'), isFalse);
        expect(parts.any((p) => p['group'] == 'core'), isFalse);
        expect(monster.dropIds, hasLength(1));
        expect(
          monster.incomingDamageResistancePresets.values,
          isNot(contains('Immunità')),
        );
      }
      expect(
        monsterById(
          'armadillo_legno',
        )!.incomingDamageResistancePresets['fuoco'],
        'Fragilità',
      );
      expect(
        monsterById(
          'armadillo_cristallo',
        )!.incomingDamageResistancePresets['contundente'],
        'Fragilità',
      );
    },
  );

  test(
    'three close forms use exact confirmed CM and editable costs/effects',
    () {
      final technique = monsterBookConcreteTechnique('armadillo_roll_up')!;
      expect(technique.forms.map((f) => f.single.formula), ['6', '9', '16']);
      expect(technique.costResource, 'materia');
      expect(technique.minimums, [1, 2, 3]);
      expect(technique.maximums, [1, 2, 3]);
      final art = oculumMonsterBookArt(monsterById('armadillo_corazzato')!);
      final skill = art.skills.firstWhere((s) => s.nome == 'Appallottolamento');
      skill.effettiPerLivello[0].single.valueExpression = '7';
      skill.impostaRisorsaCostoPerLivello(1, 'volonta');
      final restored = CharacterArt.fromJson(
        jsonDecode(jsonEncode(art.toJson())),
      );
      final custom = restored.skills.firstWhere((s) => s.nome == skill.nome);
      expect(custom.effettiEvoluzione(1).single.valueExpression, '7');
      expect(custom.risorsaCostoPerLivello(1), 'volonta');
      expect(technique.forms.first.single.formula, '6');
    },
  );

  test(
    'curling state belongs to one encounter and grants no bonus at zero HP',
    () {
      const state = {'closed': true, 'fightKey': 'fight-A', 'cmBonus': 16};
      expect(
        oculumArmadilloStateIsClosed(state, fightKey: 'fight-A', currentHp: 1),
        true,
      );
      expect(
        oculumArmadilloStateIsClosed(state, fightKey: 'fight-B', currentHp: 10),
        false,
      );
      expect(
        oculumArmadilloStateIsClosed(state, fightKey: 'fight-A', currentHp: 0),
        false,
      );
      expect(
        oculumArmadilloStateIsClosed({}, fightKey: '', currentHp: 10),
        false,
      );
      final parts = oculumMonsterPrecisionAnatomy(
        monsterById('armadillo_sabbia')!,
      );
      expect(
        oculumArmadilloPrecisionParts(parts, closed: true).map((p) => p['id']),
        ['shell'],
      );
      expect(
        oculumArmadilloPrecisionParts(parts, closed: false),
        hasLength(10),
      );
      // A Master's added row lacking the catalogue flag remains available.
      expect(
        oculumArmadilloPrecisionParts([
          {'id': 'custom'},
        ], closed: true),
        hasLength(1),
      );
    },
  );

  test(
    'four drops have positive weight and survive JSON with forge metadata',
    () {
      for (final material in oculumArmadilloMaterials) {
        final item = oculumArmadilloMaterialDrop(
          material.name,
          level: 2,
          grade: 0,
          receiptId: 'receipt-${material.id}',
          metadata: {'monsterId': 'source'},
        )!;
        expect(item.peso, .2);
        expect(oculumBlacksmithMaterial(item)?.id, material.id);
        expect(item.craftData['inlayMinimumGrams'], 50);
        expect(item.monsterLoot['id'], 'receipt-${material.id}');
        final saved = InventoryItem.fromJson(
          jsonDecode(jsonEncode(item.toJson())),
        );
        expect(saved.craftData, item.craftData);
        expect(saved.peso, item.peso);
      }
      expect(
        oculumArmadilloMaterialDrop(
          'Zanne di goblin',
          level: 0,
          grade: 0,
          receiptId: 'other',
          metadata: {},
        ),
        isNull,
      );
    },
  );

  for (final species in oculumArmadilloSpeciesIds) {
    testWidgets('$species stays closed while rolling/ramming; uncurl ends CM', (
      tester,
    ) async {
      final (state, probe) = await _mount(tester, species: species);
      final before = probe.defenseCm();
      final close = _form(species, 'armadillo_roll_up');
      probe.applyEffects(close.effettiStrutturati);
      expect(probe.defenseCm(), before + 6);
      final runtime =
          state.schedePersonaggio[state.schedaCorrente]['planarRuntime'] as Map;
      expect((runtime['armadillo'] as Map)['closed'], true);
      // Refusing a repeated activation avoids stacking and repeated spending.
      expect(await probe.useConfiguredForTest(close), false);
      for (final id in ['armadillo_roll', '${species}_ram']) {
        probe.applyEffects(_form(species, id).effettiStrutturati);
        expect(probe.defenseCm(), before + 6);
        expect((runtime['armadillo'] as Map)['closed'], true);
      }
      final saved =
          jsonDecode(jsonEncode(probe.snapshot())) as Map<String, dynamic>;
      expect(
        ((saved['planarRuntime'] as Map)['armadillo'] as Map)['cmBonus'],
        6,
      );
      probe.applyEffects(_form(species, 'armadillo_uncurl').effettiStrutturati);
      expect(probe.defenseCm(), before);
      await closeFixture(tester, probe);
    });
  }

  for (final ownTurn in [true, false]) {
    testWidgets(
      'close pays exactly one ${ownTurn ? 'Action' : 'Reaction'} and real MAT',
      (tester) async {
        final (state, probe) = await _mount(tester, ownTurn: ownTurn);
        final beforeCm = probe.defenseCm();
        final beforeMatter = probe.availableArtResource('materia');
        final close = _form('armadillo_corazzato', 'armadillo_roll_up');
        expect(await _use(tester, probe, close), true);
        expect(probe.availableArtResource('materia'), beforeMatter - 1);
        expect(probe.defenseCm(), beforeCm + 6); // MAT21 ->20 has same half.
        final token = (state.masterInitiativeTokens as List).first as Map;
        expect(token['lastTurnResource'], ownTurn ? 'azione' : 'reazione');
        expect(token['reactionFastUsed'], 0);
        if (!ownTurn) {
          expect(token['actionUsed'], false);
          expect(state.masterInitiativeActiveIndex, 1);
        }
        await closeFixture(tester, probe);
      },
    );
  }
}
