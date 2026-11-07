import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

InventoryItem weapon(String name, {int level = 6, bool title = false}) =>
    InventoryItem(
      nome: name,
      peso: 1,
      quantita: 1,
      note: '',
      arma: true,
      equipaggiata: true,
      bonusDanno: 101,
      livelloOggetto: level,
      craftData: {if (title) 'titleItem': true, 'custom': 'conservato'},
    );

void main() {
  test('wear survives JSON and rolls the break percentage once', () {
    final blade = weapon('Lama');
    expect(oculumEquipmentUses(blade), 1000);
    expect(oculumWeaponWearDamage(blade), 101);
    expect(oculumSpendEquipmentWear(blade, 500), 500);
    expect(oculumWeaponWearDamage(blade), 50);
    expect(oculumSpendEquipmentWear(blade, 499), 499);
    expect(oculumWeaponWearDamage(blade), 30);
    var rolls = 0;
    int roll() {
      rolls++;
      return 27;
    }

    expect(oculumSpendEquipmentWear(blade, 6, rollBrokenPercent: roll), 1);
    final restored = InventoryItem.fromJson(blade.toJson());
    expect(oculumEquipmentUses(restored), 0);
    expect(oculumEquipmentBrokenPercent(restored), 27);
    expect(oculumWeaponWearDamage(restored), 27);
    expect(oculumSpendEquipmentWear(restored, 4, rollBrokenPercent: roll), 0);
    expect(rolls, 1);
    expect(restored.craftData['custom'], 'conservato');
    expect(restored.bonusDanno, 101);
    expect(oculumRepairEquipmentWear(restored), isTrue);
    expect(oculumWeaponWearDamage(restored), 101);

    final title = weapon('Titolo', title: true);
    expect(oculumSpendEquipmentWear(title, 1000, rollBrokenPercent: roll), 0);
    expect(oculumWeaponWearDamage(title), 101);
    expect(rolls, 1);
  });

  test('capacity follows item level and preserves worn fraction on edits', () {
    for (final (level, capacity) in [(0, 250), (1, 500), (2, 750), (3, 1000)]) {
      final blade = weapon('Lama', level: level);
      final armor = weapon('Armatura', level: level)
        ..arma = false
        ..protegge = true;
      final shield = weapon('Scudo offensivo', level: level)..protegge = true;
      expect(oculumEquipmentUses(blade), capacity);
      expect(oculumEquipmentUses(armor), capacity);
      expect(oculumEquipmentUses(shield), capacity);
    }

    final blade = weapon('Lama', level: 0);
    expect(oculumSpendEquipmentWear(blade, 125), 125);
    final upgraded = InventoryItem.fromJson(blade.toJson())..livelloOggetto = 1;
    expect(oculumEquipmentUses(upgraded), 250);
    expect(oculumWeaponWearDamage(upgraded), 50);
    expect(oculumRestoreEquipmentWear(upgraded, 100), 100);
    expect(oculumEquipmentUses(upgraded), 350);
    expect(oculumSpendEquipmentWear(upgraded, 349), 349);
    upgraded.livelloOggetto = 0;
    expect(oculumEquipmentUses(upgraded), 1);
    expect(
      oculumSpendEquipmentWear(upgraded, 1, rollBrokenPercent: () => 21),
      1,
    );
    upgraded.livelloOggetto = 3;
    expect(oculumEquipmentUses(upgraded), 0);
    expect(oculumEquipmentBrokenPercent(upgraded), 21);
    expect(oculumRestoreEquipmentWear(upgraded, 1000), 0);
    expect(oculumRepairEquipmentWear(upgraded), isTrue);
    expect(oculumEquipmentUses(upgraded), 1000);
  });

  test('item level, boost and actual opponent size compose', () {
    int base(int weaponLevel, {bool boosted = false}) => oculumWeaponBaseWear(
      wearerLevel: 10,
      weaponLevel: weaponLevel,
      boosted: boosted,
    );
    expect(base(11, boosted: true), 0);
    expect(base(10), 1);
    expect(base(10, boosted: true), 3);
    expect(base(9), 2);
    expect(base(9, boosted: true), 5);

    int cost(int targetLevel, int targetGrade) => oculumWearAgainstOpponent(
      base(9, boosted: true),
      wearerLevel: 10,
      wearerGrade: 2,
      opponentLevel: targetLevel,
      opponentGrade: targetGrade,
    );
    expect(cost(9, 1), 5);
    expect(cost(11, 2), 7);
    expect(cost(13, 3), 10);
    expect(cost(14, 4), 19);
    expect(oculumEquipmentWearHostileCombatant('Mostro', 'enemy'), isTrue);
    expect(oculumEquipmentWearHostileCombatant('NPC nemico', 'enemy'), isTrue);
    expect(
      oculumEquipmentWearHostileCombatant('Personaggio', 'enemy'),
      isFalse,
    );
    expect(
      oculumEquipmentWearHostileCombatant('NPC neutrale', 'neutral'),
      isFalse,
    );
  });

  testWidgets('a multi-target enemy attack wears its equipment once', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final main = weapon('Lama')..bonusDanno = 103;
    final secondary = weapon('Pugnale', level: 5);
    final title = weapon('Titolo', title: true);
    state.schedePersonaggio[0]['masterSideOverride'] = 'enemy';
    state.tipoSchedaController.text = 'Mostro';
    state.livelloController.text = '6';
    state.gradoController.text = '0';
    state.attaccoRapidoController.clear();
    state.buffMalusRapidiController.clear();
    state.titoli.clear();
    state.arti.clear();
    state.skills.clear();
    state.activeStructuredEffects.clear();
    state.inventario
      ..clear()
      ..addAll([main, secondary, title]);
    state.masterInitiativeTokens[0]['side'] = 'enemy';
    state.masterInitiativeTokens[1].addAll({
      'level': 7,
      'grade': 0,
      'side': 'ally',
    });
    state.masterInitiativeTokens[2].addAll({
      'level': 10,
      'grade': 1,
      'side': 'ally',
    });
    probe.recordCurrentEncounter();
    probe.invalidateDerivedCaches();
    state.currentHpController.text = '${probe.maximumHp()}';

    Future<void> plan({required bool confirm}) async {
      final attack = probe.planAttack(
        minimum: 2,
        maximum: 2,
        total: 30,
        natural: 10,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final planner = find.byType(OculumAttackPlanner);
      expect(planner, findsOneWidget);
      Navigator.of(tester.element(planner)).pop(
        confirm
            ? OculumAttackPlan(
                'ENEMY',
                'vc',
                '',
                additionalTargetIds: ['OTHER'],
              )
            : null,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await attack;
    }

    await plan(confirm: false);
    expect(oculumEquipmentUses(main), 1000);
    expect(oculumEquipmentUses(secondary), 1000);

    final damageBeforeWear = probe.damageTotal();
    await plan(confirm: true);
    final packets = (state.onlineCombatRequests as Map).values
        .whereType<Map>()
        .where((request) => request['attackGroupId'] != null);
    expect(packets, hasLength(2));
    expect(
      packets.map((packet) => packet['damageBasePacket']),
      everyElement(damageBeforeWear),
    );
    expect(oculumEquipmentUses(main), 997);
    expect(oculumEquipmentUses(secondary), 994);
    expect(oculumEquipmentUses(title), 1000);
    expect(probe.damageTotal(), lessThan(damageBeforeWear));
    final savedItems = (probe.snapshot()['inventario'] as List)
        .cast<Map<String, dynamic>>()
        .map(InventoryItem.fromJson);
    expect(savedItems.map(oculumEquipmentUses), [997, 994, 1000]);
    await closeFixture(tester, probe);
  });
}
