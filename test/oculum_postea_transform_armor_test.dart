import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_protection_wear_test.dart' show prepareProtectionFixture;

void main() {
  testWidgets('Postea transformation spends and expires its own buffers', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    prepareProtectionFixture(state, probe);
    state.resilienzaController.text = '20';
    state.volontaController.text = '20';
    state.materiaController.text = '20';
    state.oculumController.text = '20';
    const stats = ['resilienza', 'volonta', 'materia', 'oculum'];
    for (final key in stats) {
      probe.setResourceCurrent(key, 20);
    }
    state.currentHpController.text = '80';
    state.scudoController.text = '25';
    final armor = InventoryItem(
      nome: 'Ferrum Mutabile',
      peso: 3,
      quantita: 1,
      note: '',
      protegge: true,
      livelloOggetto: 12,
      bonusDifesa: 12,
      craftData: {'posteaTransformArmor': true, 'wearProtectionKind': 'armor'},
    );
    state.inventario
      ..clear()
      ..add(armor);
    probe.equipItem(armor, true);
    expect(probe.equipmentDefense(armor), 12);
    for (final key in stats) {
      expect(probe.visibleResourceCurrent(key), 20, reason: key);
    }
    final initialMaximum = probe.maximumHp();

    final home = tester.element(find.byType(OculumHomePage));
    unawaited(
      showDialog<void>(
        context: home,
        builder: (context) => Dialog(
          child: SizedBox(
            width: 1000,
            height: 500,
            child: SingleChildScrollView(child: probe.combatAbilityBar()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(
      find.byKey(const PageStorageKey('combat_abilities_support')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Trasformazione Postea'));
    await tester.pump();
    Navigator.of(home).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(probe.currentHp(), 120);
    expect(probe.maximumHp(), initialMaximum + 40);
    expect(probe.shieldTotal(), 425);
    for (final key in stats) {
      expect(probe.resourceCurrent(key), 26, reason: key);
    }
    await probe.damageResolved(250, bypassDefense: true);
    expect(probe.currentHp(), 120);
    expect(probe.shieldTotal(), 175);
    await probe.damageResolved(30, bypassDefense: true, bypassShields: true);
    expect(probe.currentHp(), 90);
    expect(probe.maximumHp(), initialMaximum + 10);
    expect(probe.payArtResources({'resilienza': 2, 'hp': 4}), true);
    expect(probe.spendArtResource('oculum', 3), 3);
    expect(probe.resourceCurrent('oculum'), 23);
    probe.setResourceCurrent('volonta', 17);

    final saved = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(probe.snapshot())) as Map,
    );
    state.schedePersonaggio[state.schedaCorrente] = saved;
    probe.load(saved);
    expect(probe.resourceCurrent('oculum'), 23);
    final equipped = (state.inventario as List)
        .whereType<InventoryItem>()
        .single;
    probe.equipItem(equipped, false);
    probe.equipItem(equipped, true);
    expect(probe.currentHp(), 86);
    expect(probe.shieldTotal(), 175);

    final start = state.playerReportedTurn as int;
    probe.reportedTurn(start + 2);
    expect(probe.shieldTotal(), 175);
    probe.reportedTurn(start + 3);
    expect(probe.currentHp(), 80);
    expect(probe.maximumHp(), initialMaximum);
    expect(probe.shieldTotal(), 25);
    expect(probe.resourceCurrent('resilienza'), 20);
    expect(probe.resourceCurrent('volonta'), 17);
    expect(probe.resourceCurrent('materia'), 20);
    expect(probe.resourceCurrent('oculum'), 20);
    final used =
        (probe.snapshot()['planarRuntime']
                as Map)['posteaTransformArmorRuntime']
            as Map;
    expect(used['used'], true);
    probe.longRest(advanceWorldClock: false);
    expect(
      (probe.snapshot()['planarRuntime'] as Map)['posteaTransformArmorRuntime'],
      isNull,
    );
    await closeFixture(tester, probe);
  });
}
