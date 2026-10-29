import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  const budgets = {
    'guardia_lunare': 10,
    'guardia_lunare_elite': 68,
    'guardiano_lunare': 126,
    'guardia_infernale_ik': 68,
    'guardia_infernale_ik_elite': 100,
    'guardian_devil_moon': 156,
  };
  test(
    'six Lunar families have coherent exact bases, existing level/Grade growth and owned skill pools',
    () {
      for (final row in budgets.entries) {
        final entry = monsterById(row.key)!;
        final base = oculumMonsterCreationStats(entry, 0);
        expect(
          base.values.fold<int>(0, (a, b) => a + b),
          row.value,
          reason: row.key,
        );
        final grown = oculumMonsterCreationStats(entry, 13);
        expect(
          grown.values.fold<int>(0, (a, b) => a + b),
          row.value + oculumGeneratedMonsterBudget(entry.presetType, 13),
        );
        expect(
          monsterBookUsableSkillIds(entry).length,
          greaterThanOrEqualTo(16),
        );
        expect(
          oculumMonsterBookArt(entry).skills.length,
          greaterThanOrEqualTo(16),
        );
        expect(
          oculumCelestialAllegiance({'monsterBookSourceId': entry.id}),
          'lunare',
        );
        expect(entry.imageBase64, isEmpty);
        expect(entry.spriteAssetPath, isEmpty);
        expect(entry.encounterRules['canonicalMetal'], 'argento annerito');
      }
    },
  );
  test(
    'canonical palettes and anatomy distinguish stone guardians, human guards and Ik lore',
    () {
      for (final id in budgets.keys) {
        final entry = monsterById(id)!;
        final infernal = entry.encounterRules['infernalIk'] == true;
        expect(
          oculumMonsterColors(entry).single.color,
          infernal ? const Color(0xff8f1b5b) : const Color(0xff6a4cb0),
        );
        expect(entry.descIt, contains(infernal ? '#8f1b5b' : '#6a4cb0'));
        if (entry.encounterRules['lunarGuardian'] == true) {
          expect(entry.descIt, contains('pietra'));
          expect(entry.encounterRules['slowColossus'], true);
          expect(entry.inventoryItems, isEmpty);
        } else {
          expect(entry.descIt.toLowerCase(), contains('elmo'));
          expect(entry.inventoryItems, hasLength(2));
          expect(
            entry.inventoryItems.every(
              (i) => '${i['note']}'.contains('argento annerito'),
            ),
            true,
          );
        }
        if (infernal) {
          expect(entry.encounterRules['ikQueen'], 'Iris StarEyes');
          expect(entry.encounterRules['ikLore'], contains('non il Sole'));
        }
      }
    },
  );
  test(
    'fresh Guardian Arts carry editable Open/Skill definitions without rewriting saved custom Arts',
    () {
      for (final id in ['guardiano_lunare', 'guardian_devil_moon']) {
        final art = oculumMonsterBookArt(monsterById(id)!);
        expect(oculumLunarGuardianArt(art), true);
        expect(art.monsterOpenSkill, true);
        final stones = art.openDescriptionEffects.firstWhere(
          (e) => e.target == 'lunar_guardian_stones',
        );
        expect(stones.diceExpression, '1d20');
        expect(stones.valueExpression, '5');
        expect(oculumParseAbilityCost(art.openDescription)!.minimum, 7);
        expect(oculumParseAbilityCost(art.openSkill)!.minimum, 4);
        expect(art.openBuff, contains('@Danni+20'));
        expect(art.openBuff, contains('@Difesa+15'));
        final commands = oculumParseFormulaCommands(art.openBuff, const {
          'livello': 8,
          'grado': 1,
        }).where((command) => command.valid);
        expect(commands.singleWhere((c) => c.key == 'danni').value, 20);
        expect(commands.singleWhere((c) => c.key == 'difesa').value, 15);
        stones.valueExpression = '7';
        stones.diceExpression = '1d12';
        art.openSkillCooldown!.amount = 5;
        final saved = CharacterArt.fromJson(art.toJson());
        expect(saved.openDescriptionEffects.first.valueExpression, '7');
        expect(saved.openDescriptionEffects.first.diceExpression, '1d12');
        expect(saved.openSkillCooldown!.amount, 5);
        expect(
          oculumMonsterBookArt(
            monsterById(id)!,
          ).openDescriptionEffects.first.valueExpression,
          '5',
        );
      }
    },
  );
  testWidgets(
    'actual Lunar Open button pays its cost and prepares one editable fixed-damage volley',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final sheet = p.snapshot()
        ..['livello'] = '8'
        ..['oculum'] = '50'
        ..['currentOculum'] = '50'
        ..['normalCurrentOculum'] = 50
        ..['maxOculum'] = 50;
      p.load(sheet);
      final art = oculumMonsterBookArt(monsterById('guardiano_lunare')!)
        ..hasIntegrity = false;
      state.arti
        ..clear()
        ..add(art);
      state.skills.clear();
      state.activeStructuredEffects.clear();
      state.masterInitiativeRound = 2;
      state.masterInitiativeActiveIndex = 0;
      final token = state.masterInitiativeTokens.first as Map;
      token['actionUsed'] = false;
      token['actionTurnRound'] = 2;
      p.recordCurrentEncounter();
      final before = p.availableArtResource('oculum');
      final damage = p.damageTotal();
      final activation = p.useOpen(0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Conferma').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final planner = find.byType(OculumAttackPlanner);
      expect(planner, findsOneWidget);
      Navigator.of(tester.element(planner)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await activation;
      expect(art.openAttiva, true);
      expect(p.availableArtResource('oculum'), before - 7);
      expect(p.damageTotal(), damage + 20);
      expect(p.lunarGuardianVolley()!['cuts'], inInclusiveRange(1, 20));
      expect(p.lunarGuardianVolley()!['damagePerCut'], 5);
      final saved = p.snapshot();
      p.load(saved);
      expect(p.lunarGuardianVolley()!['damagePerCut'], 5);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'stone count rolls once, damage stays fixed and a pending volley survives reload',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final art = oculumMonsterBookArt(monsterById('guardiano_lunare')!);
      state.arti
        ..clear()
        ..add(art);
      state.activeStructuredEffects.clear();
      final original = jsonEncode(
        art.openDescriptionEffects.map((e) => e.toJson()).toList(),
      );
      final prepared = p.prepareLunarGuardian(
        art.openDescriptionEffects,
        random: Random(8),
      );
      final stone = prepared.first;
      final payload = jsonDecode(stone.narrativeText) as Map;
      expect(payload['cuts'], inInclusiveRange(1, 20));
      expect(payload['damagePerCut'], 5);
      expect(payload['eruptionDamage'], 10);
      expect(stone.diceExpression, isEmpty);
      expect(stone.valueExpression, '0');
      expect(
        jsonEncode(art.openDescriptionEffects.map((e) => e.toJson()).toList()),
        original,
      );
      p.applyEffects(prepared);
      expect(p.lunarGuardianVolley()!['cuts'], payload['cuts']);
      p.load(p.snapshot());
      expect(p.lunarGuardianVolley()!['cuts'], payload['cuts']);
      expect(p.lunarGuardianVolley()!['damagePerCut'], 5);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'only own Open lifecycle empowers the reusable crest, even after toggling Open off',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final art = oculumMonsterBookArt(monsterById('guardiano_lunare')!);
      state.arti
        ..clear()
        ..add(art);
      final cold = p.prepareLunarGuardian(art.openSkillEffects).single;
      expect(cold.valueExpression, '12');
      expect(cold.maximumTargets, 1);
      p.recordArtOpenCycle(0);
      art.openAttiva = false;
      final hot = p.prepareLunarGuardian(art.openSkillEffects).single;
      expect(oculumEvaluateFormula(hot.valueExpression, {}), 20);
      expect(hot.maximumTargets, 2);
      expect(art.openSkillEffects.single.valueExpression, '12');
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'owner resolves Solar doubling once and creates one separate reaction-only eruption per hit',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.razzaController.text = 'Solare';
      final incoming = <String, dynamic>{
        'id': 'stone-one',
        'sourceTag': 'ENEMY',
        'targetTag': p.ownerTag(),
        'damage': 5,
        'attack': 30,
        'natural': 10,
        'kind': 'attack',
        'status': 'pending',
        'lunarGuardianStone': true,
        'lunarGuardianEruptionDamage': 10,
        'element': 'lunare',
      };
      p.lunarGuardianIncoming(incoming);
      p.lunarGuardianIncoming(incoming);
      expect(incoming['damage'], 10);
      expect(incoming['element'], 'lunare');
      expect(p.lunarGuardianEruption(incoming, hit: false), isNull);
      final eruption = p.lunarGuardianEruption(incoming, hit: true)!;
      expect(eruption['damage'], 10);
      expect(eruption['lunarGuardianReactionOnly'], true);
      expect(eruption['lunarGuardianStone'], false);
      expect(eruption['lunarGuardianEruption'], true);
      expect(p.lunarGuardianEruption(incoming, hit: true), isNull);
      p.lunarGuardianIncoming(eruption);
      p.lunarGuardianIncoming(eruption);
      expect(eruption['damage'], 20);
      expect(p.lunarGuardianEruption(eruption, hit: true), isNull);
      await closeFixture(tester, p);
    },
  );
}
