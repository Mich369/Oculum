import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test('mecha construction requires a strict success even on a critical', () {
    expect(oculumMechaDifficulty(8, 5), 37);
    expect(oculumMechaDifficulty(5, 8), 31);
    String outcome(
      int die,
      int total, {
      int attempts = 0,
      bool crafting = false,
    }) => oculumMechaBuildOutcome(
      natural: die,
      total: total,
      robotLevel: 8,
      ownerLevel: 5,
      attempts: attempts,
      crafting: crafting,
    );
    expect(outcome(20, 37), 'retry');
    expect(outcome(20, 38), 'critical');
    expect(outcome(19, 38), 'built');
    expect(outcome(19, 39, crafting: true), 'retry');
    expect(outcome(19, 40, crafting: true), 'built');
    expect(outcome(1, 100), 'wreck');
    expect(outcome(10, 20, attempts: 2), 'wreck');
    expect(oculumMechaStat(19, false), 15);
    expect(oculumMechaStat(19, true), 19);
    expect(oculumMechaSoloDamage(19), 7);
    expect(oculumMechaEscapeTotal(die: 10, reflexes: 9, level: 8), 16);
    expect(
      oculumMechaEscapeTotal(
        die: 10,
        reflexes: 9,
        level: 8,
        resource: 'reazione',
      ),
      28,
    );
    expect(
      oculumMechaEscapeTotal(
        die: 10,
        reflexes: 9,
        level: 8,
        resource: 'reazione_veloce',
      ),
      33,
    );
    expect(oculumMechaExplosionDamage(4), 32);
    expect(oculumMechaExplosionDamage(4, fastReaction: true), 24);
  });

  test('robot scraps always drop and costume requires the total 43', () {
    final robot = defaultMonsterBookEntries.singleWhere(
      (m) => m.id == 'pupazzo_robotico_postea',
    );
    final doll = defaultMonsterBookEntries.singleWhere(
      (m) => m.id == 'pupazzo_artigliato',
    );
    List<InventoryItem> loot(MonsterBookEntry m, int total) =>
        oculumGenerateMonsterLoot(
          monster: m,
          level: 3,
          grade: 0,
          random: Random(3),
          killId: 'test:$total',
          naturalDropRoll: 1,
          dropTotal: total,
        );
    expect(loot(robot, 1).single.craftData['mechaScraps'], isTrue);
    expect(
      loot(doll, 42).where((i) => i.craftData['dollCostume'] == true),
      isEmpty,
    );
    final costume = loot(
      doll,
      43,
    ).singleWhere((i) => i.craftData['dollCostume'] == true);
    expect(costume.ability, isNotNull);
    expect(
      CharacterSkill.fromJson(
        Map<String, dynamic>.from(costume.craftData['jumpAbility'] as Map),
      ).nome,
      'Scatto a molla',
    );
    expect(robot.incomingDamageResistancePresets['fulmine'], isNotNull);
  });

  testWidgets(
    'mecha keeps pilot health, construction state and temporary matter separate',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.resilienzaController.text = '20';
      state.currentResilienzaController.text = '20';
      state.currentHpController.text = '137';
      state.materiaController.text = '10';
      state.currentMateriaController.text = '8';
      state.livelloController.text = '5';
      state.gradoController.text = '0';
      if (state.schedePersonaggio.isEmpty) {
        state.schedePersonaggio.add(
          Map<String, dynamic>.from(probe.snapshot())
            ..['sheetTag'] = 'PilotOcu:3690TEST'
            ..['id'] = 'PilotOcu:3690TEST',
        );
        state.schedaCorrente = 0;
      }
      final recharge = probe.rechargeMatter(3, 12);
      expect(recharge.restored, 2);
      expect(recharge.temporary, 5);
      expect(probe.spendMatter(7), 7);
      expect(state.currentMateriaController.text, '8');
      expect(probe.planarStateSnapshot()['plasmaTemporaryMatter'], 0);
      probe.rechargeMatter(2, 8);
      expect(probe.planarStateSnapshot()['plasmaTemporaryMatter'], 3);
      probe.finishPlanarFight();
      expect(probe.planarStateSnapshot()['plasmaTemporaryMatter'], isNull);

      final robot = defaultMonsterBookEntries.singleWhere(
        (m) => m.id == 'pupazzo_robotico_postea',
      );
      final scraps = oculumDollRobotScraps(robot, 3, 0, 'robot:1');
      (scraps.craftData['robotSource'] as Map).addAll(<String, dynamic>{
        'resilienza': '10',
        'volonta': '10',
        'materia': '10',
        'currentHp': '100',
        'mechaMaxHp': 100,
      });
      state.inventario.add(scraps);
      expect(probe.buildMecha(scraps, 19, 30), 'built');
      expect(scraps.craftData['mechaItem'], isTrue);
      await probe.enterMecha(scraps);
      expect(probe.planarStateSnapshot()['mountedMecha'], isA<Map>());
      expect(state.currentHpController.text, '100');
      expect(oculumSheetHpMaximum(probe.snapshot()), 100);
      expect(state.materiaController.text, '8');
      state.currentHpController.text = '42';
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'bonus',
          target: 'difesa',
          valueExpression: '11',
          duration: '3 turni',
        ),
      ]);
      await probe.exitMecha();
      expect(state.currentHpController.text, '137');
      expect(state.materiaController.text, '10');
      expect(probe.planarStateSnapshot()['mountedMecha'], isNull);
      final freshItem = (state.inventario as List)
          .cast<InventoryItem>()
          .singleWhere((i) => i.craftData['mechaItem'] == true);
      expect(probe.snapshot()['skills'], isEmpty);
      expect(probe.snapshot()['activeStructuredEffects'], isNull);
      await probe.enterMecha(freshItem);
      expect(state.currentHpController.text, '42');
      await probe.exitMecha(destroyed: true, explosionPercentile: 0);
      expect(probe.planarStateSnapshot()['mechaExplosion'], isA<Map>());
      expect(await probe.escapeMecha('none', 24), isTrue);
      expect(probe.planarStateSnapshot()['mechaExplosion'], isNull);

      final wreck = oculumDollRobotScraps(robot, 3, 0, 'robot:2');
      state.inventario.add(wreck);
      expect(probe.buildMecha(wreck, 1, 100), 'wreck');
      expect(probe.destroyMechaWreck(wreck, 64), isTrue);
      expect(probe.destroyMechaWreck(wreck, 0), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
