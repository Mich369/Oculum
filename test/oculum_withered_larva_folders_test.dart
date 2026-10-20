import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('monster base profiles and free cooldown larva skills are saved', () {
    final construct = monsterById('costrutto_rinsecchito')!;
    final larva = monsterById('larva_bianca')!;
    expect(
      [
        construct.stats['resilienza'],
        construct.stats['volonta'],
        construct.stats['materia'],
        construct.stats['oculum'],
      ],
      [2, 3, 1, 3],
    );
    expect(
      [
        larva.stats['resilienza'],
        larva.stats['volonta'],
        larva.stats['materia'],
        larva.stats['oculum'],
      ],
      [1, 2, 0, 0],
    );
    final skills = oculumMonsterBookSkills(larva);
    expect(skills, hasLength(3));
    for (final skill in skills) {
      final restored = CharacterSkill.fromJson(skill.toJson());
      expect(restored.forme.first.livello, '0');
      for (final form in restored.forme) {
        expect(form.costoStrutturato!.amountExpression, '0');
        expect(form.cooldownStrutturato!.amount, greaterThan(0));
      }
    }
    final burrow = skills.last.forme.first.effettiStrutturati;
    expect(burrow.map((e) => e.activationOption), ['Fuga', 'Attacco']);
    expect(burrow.first.target, 'velo');
  });

  test('explicit rounding handles forms and preserves default formulas', () {
    int value(String id, int form) => oculumEvaluateStructuredEffectValue(
      oculumWitheredLarvaEffects(id, form).first,
      variables: {'oculum': 3},
    );
    expect(value('withered_strike', 0), 7);
    expect(value('withered_strike', 1), 22);
    expect(value('withered_strike', 2), 74);
    expect(value('white_larva_assault', 0), 8);
    expect(value('white_larva_assault', 1), 19);
    expect(value('white_larva_assault', 2), 51);
  });

  test('natural 20 gives a consumable brood scroll at the monster form', () {
    final larva = monsterById('larva_bianca')!;
    expect(
      oculumGenerateMonsterLoot(
        monster: larva,
        level: 6,
        grade: 1,
        random: Random(1),
        killId: 'none',
        naturalDropRoll: 19,
      ),
      isEmpty,
    );
    for (var form = 0; form < 3; form++) {
      final item = oculumGenerateMonsterLoot(
        monster: larva,
        level: form * 3,
        grade: form,
        random: Random(1),
        killId: 'form-$form',
        naturalDropRoll: 20,
      ).single;
      final data = Map<String, dynamic>.from(item.craftData['scroll'] as Map);
      expect(data['willCost'], 0);
      expect(data['id'], 'white_larva_brood_rank_${form + 1}');
      final effect = oculumScrollCombatEffects(data).single;
      expect(
        effect.valueExpression,
        ['20+livello', '30+livello', '50+livello'][form],
      );
      expect(effect.diceExpression, ['1d50', '1d100', '1d120'][form]);
      expect(effect.mode, 'nidiata');
      expect(item.monsterLoot['learnableMonsterSkill'], isNot(true));
    }
  });

  test(
    'all nine brood scroll ranks add the user level to the specified dice',
    () {
      const dice = [
        '1d50',
        '1d100',
        '1d120',
        '1d200',
        '1d200',
        '1d250',
        '1d250',
        '1d250',
        '2d250',
      ];
      const bases = [20, 30, 50, 60, 100, 120, 150, 200, 200];
      for (var rank = 0; rank < 9; rank++) {
        final effect = oculumLarvalBroodScrollEffect(rank);
        expect(effect.diceExpression, dice[rank]);
        expect(effect.valueExpression, '${bases[rank]}+livello');
        expect(effect.includeLevel, isFalse);
        final expectedDice = oculumRollEffectDice(
          dice[rank],
          random: Random(rank),
        );
        final roll = oculumResolveStructuredEffectRoll(
          effect,
          variables: {'livello': 12},
          level: 12,
          grade: 0,
          random: Random(rank),
        );
        expect(roll.value, bases[rank] + 12 + expectedDice.total);
      }
    },
  );

  test('scroll learning stays a separate rare natural-20 check', () {
    expect(oculumScrollCanLearn(19, 100, 0, 0), isFalse);
    expect(oculumScrollCanLearn(20, 29, 0, 0), isFalse);
    expect(oculumScrollCanLearn(20, 30, 0, 14), isTrue);
    expect(oculumScrollCanLearn(20, 30, 0, 15), isFalse);
  });

  test('nested folders reject cycles without moving physical sheets', () {
    final folders = <Map<String, dynamic>>[
      {'id': 'a', 'parent': ''},
      {'id': 'b', 'parent': 'a'},
      {'id': 'c', 'parent': 'b'},
    ];
    expect(oculumSheetFolderCanMove(folders, 'a', 'c'), isFalse);
    expect(oculumSheetFolderCanMove(folders, 'b', 'b'), isFalse);
    expect(oculumSheetFolderCanMove(folders, 'c', ''), isTrue);
    expect(oculumSheetFolderCanMove(folders, 'a', 'missing'), isFalse);
  });

  testWidgets(
    'brood sacrifices, vital memory upkeep and folder persistence use production runtime',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final dir = Directory(
        'build/withered-larva-${DateTime.now().microsecondsSinceEpoch}',
      )..createSync(recursive: true);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => dir.absolute.path,
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
      final dynamic state = tester.state(find.byType(OculumHomePage));
      state.tutorialDialogPending = true;
      final probe = OculumPerformanceProbe(state);
      await tester.runAsync(() async {
        state.saveBlobDirectoryFuture = Future<Directory>.value(dir);
        state.sharedPreferencesFuture = Future<SharedPreferences>.value(
          await SharedPreferences.getInstance(),
        );
        await probe.reloadSave();
      });
      state.datiCaricati = false;
      state.schedePersonaggio.clear();
      state.schedePersonaggio.addAll(<Map<String, dynamic>>[
        {'id': '001-TEST', 'sheetTag': '001-TEST', 'nome': 'Test'},
        {'id': '002-ALLY', 'sheetTag': '002-ALLY', 'nome': 'Alleato'},
      ]);
      state.schedaCorrente = 0;
      state.activeStructuredEffects.clear();
      state.activeConditions.clear();
      probe.applyEffects([
        OculumStructuredEffect(
          id: 'brood-one',
          type: 'costrutto',
          mode: 'nidiata',
          valueExpression: '10',
          duration: '-1',
        ),
      ]);
      expect(probe.broodHp(), 10);
      expect(probe.broodMaxHp(), 10);
      expect(probe.absorbBroodDamage(7), 0);
      expect(probe.broodHp(), 3);
      expect(probe.absorbBroodDamage(8), 5);
      expect(probe.broodHp(), 0);
      probe.applyEffects([
        OculumStructuredEffect(
          id: 'brood-one',
          type: 'costrutto',
          mode: 'nidiata',
          valueExpression: '10',
          duration: '-1',
        ),
      ]);
      probe.applyEffects([
        OculumStructuredEffect(
          id: 'brood-two',
          type: 'costrutto',
          mode: 'nidiata',
          valueExpression: '20',
          duration: '-1',
        ),
      ]);
      expect(probe.broodHp(), 20, reason: 'New brood replaces the old form');
      expect(probe.broodMaxHp(), 20);
      state.oculumController.text = '3';
      state.currentOculumController.text = '2';
      probe.invalidateDerivedCaches();
      probe.applyEffects(
        oculumWitheredLarvaEffects('withered_memory', 0),
        spentResources: {'oculum': 1},
      );
      expect(
        probe.conditions
            .singleWhere((c) => c.conditionType == 'ricordo_vitale')
            .duration,
        3,
      );
      probe.tickConditions(OculumConditionTickTrigger.endTurn);
      probe.tickConditions(OculumConditionTickTrigger.startTurn);
      expect(probe.resourceCurrent('oculum'), 1);
      probe.setResourceCurrent('oculum', 0);
      probe.tickConditions(OculumConditionTickTrigger.startTurn);
      expect(
        probe.conditions.where((c) => c.conditionType == 'ricordo_vitale'),
        isEmpty,
      );
      final tags = [
        for (var i = 0; i < 2; i++) '${state.schedePersonaggio[i]['sheetTag']}',
      ];
      state.sheetSidebarFolders.addAll(<Map<String, dynamic>>[
        {'id': 'root', 'name': 'Città', 'parent': ''},
        {'id': 'child', 'name': 'Mostri', 'parent': 'root'},
      ]);
      probe.moveSheetFolderEntry(probe.ownerTag(), 'child');
      state.sheetSidebarFolders[1]['name'] = 'Rinsecchiti';
      final saved =
          jsonDecode(jsonEncode(probe.campaignSnapshot()))
              as Map<String, dynamic>;
      state.sheetSidebarFolders.clear();
      state.sheetSidebarPlacements.clear();
      probe.loadCampaign(saved);
      expect(state.sheetSidebarFolders[1]['name'], 'Rinsecchiti');
      expect(state.sheetSidebarPlacements[probe.ownerTag()]['folder'], 'child');
      expect([
        for (var i = 0; i < 2; i++) '${state.schedePersonaggio[i]['sheetTag']}',
      ], tags);
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
