import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets('ice locks the sheet and only the accepted escape uses Action', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final initialMovement = probe.movement();
    expect(initialMovement, greaterThan(0));
    expect(oculumElementalSphereIceReleaseDifficulty(4, 2), 18);

    expect(
      probe.applyElementalSphereFreeze(
        {'level': 4, 'grade': 2},
        durationTurns: 3,
        difficulty: 'difficile',
      ),
      isTrue,
    );
    final condition = (probe.snapshot()['conditions'] as List)
        .whereType<Map>()
        .singleWhere(
          (value) =>
              value['conditionType'] == oculumElementalSphereIceCondition,
        );
    expect(condition['duration'], 4);
    expect(condition['metadata']['releaseDifficulty'], 18);
    expect(probe.movement(), 0);
    expect(await probe.spendCombatRoll(), isFalse);

    final active = state.masterInitiativeTokens.first as Map;
    active['actionUsed'] = true;
    await probe.releaseElementalSphereIce(natural: 20);
    expect(probe.movement(), 0);

    active['actionUsed'] = false;
    await probe.releaseElementalSphereIce(natural: 1);
    expect(active['actionUsed'], isTrue);
    expect(probe.movement(), 0);
    await probe.releaseElementalSphereIce(natural: 20);
    expect(probe.movement(), 0);

    state.masterInitiativeActiveIndex = 0;
    state.masterInitiativeTokens.first['actionUsed'] = false;
    await probe.releaseElementalSphereIce(natural: 20);
    expect(state.masterInitiativeTokens.first['actionUsed'], isTrue);
    expect(probe.movement(), initialMovement);
    expect(probe.shatterElementalSphereIce(), isFalse);

    await closeFixture(tester, probe);
  });

  testWidgets(
    'a fire-using ally shatters only the selected ice with an Action',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final sourceSheet = probe.snapshot();
      final targetSheet = probe.snapshot()
        ..['id'] = 'ENEMY'
        ..['sheetTag'] = 'ENEMY'
        ..['nome'] = 'Alleato';
      state.schedePersonaggio.add(targetSheet);
      state.schedaCorrente = 1;
      probe.load(targetSheet);
      final target = probe.ownerTag();
      (state.masterInitiativeTokens as List).whereType<Map>().firstWhere(
          (token) => token['sheetTag'] == 'ENEMY',
        )
        ..['sheetTag'] = target
        ..['id'] = target
        ..['name'] = 'Alleato'
        ..['side'] = 'party';
      probe.recordCurrentEncounter();
      expect(
        probe.applyElementalSphereFreeze(
          {'level': 4, 'grade': 2},
          durationTurns: 3,
          difficulty: 'normale',
        ),
        isTrue,
      );
      final frozenSheet = probe.snapshot();
      state.schedePersonaggio[1] = frozenSheet;
      state.schedaCorrente = 0;
      probe.load(sourceSheet);

      final choices = find.byType(SimpleDialog);
      Future<void> finishPicker(Future<void> operation) async {
        var done = false;
        final observed = operation.then((_) => done = true);
        for (var frames = 0; !done && frames < 12; frames++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(done, isTrue, reason: 'The picker must finish closing');
        await observed;
      }

      final unavailable = probe.selectElementalSphereIceAlly();
      await tester.pump();
      expect(choices, findsNothing);
      await finishPicker(unavailable);
      expect(state.masterInitiativeTokens.first['actionUsed'], isNot(true));
      state.inventario.add(
        InventoryItem(
          nome: 'Lama di prova',
          peso: 1,
          quantita: 1,
          note: '',
          arma: true,
          equipaggiata: true,
          elementoDanno: 'fuoco',
        ),
      );
      final cancelled = probe.selectElementalSphereIceAlly();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(choices, findsOneWidget);
      Navigator.of(tester.element(choices)).pop();
      await finishPicker(cancelled);
      expect(state.masterInitiativeTokens.first['actionUsed'], isNot(true));
      expect(
        (state.schedePersonaggio[1]['conditions'] as List)
            .whereType<Map>()
            .single['conditionType'],
        oculumElementalSphereIceCondition,
      );

      final committed = probe.selectElementalSphereIceAlly();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(
        find.descendant(of: choices, matching: find.text('Alleato')),
      );
      await finishPicker(committed);
      expect(state.masterInitiativeTokens.first['actionUsed'], isTrue);
      final thawed = state.schedePersonaggio[1] as Map;
      expect(frozenSheet['currentHp'], isNotNull);
      expect(thawed['currentHp'], frozenSheet['currentHp']);
      expect(thawed['conditions'], isEmpty);

      await closeFixture(tester, probe);
    },
  );

  testWidgets('only the Master receipt for the current ice removes it, once', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    const source = 'IceCaster:413FD5G';
    final target = probe.ownerTag();
    final sourceToken = state.masterInitiativeTokens[1] as Map;
    sourceToken
      ..['id'] = source
      ..['sheetTag'] = source
      ..['side'] = 'party';
    probe.recordCurrentEncounter();
    state.realtimeUsers.add({
      'sessionId': 'ice-test-master',
      'role': 'master',
      'localSheetTags': [target],
    });

    String freeze(int duration) {
      expect(
        probe.applyElementalSphereFreeze(
          {'level': 4, 'grade': 2},
          durationTurns: duration,
          difficulty: 'normale',
        ),
        isTrue,
      );
      final data = probe.snapshot()['faunaPublic'] as Map;
      return data['elementalSphereIceInstance'] as String;
    }

    final initialIce = freeze(3);
    await tester.pump(const Duration(milliseconds: 1));
    final freshIce = freeze(4);
    expect(freshIce, isNot(initialIce));
    final initialHp = probe.snapshot()['currentHp'];
    final receipt = <String, dynamic>{
      ...probe.turnResourceTestPacket('sphere-ice:test-receipt'),
      'sessionId': 'ice-test-master',
      'senderRole': 'master',
      'sourceTag': source,
      'targetTag': target,
      'helpMode': 'elemental_sphere_ice_shatter',
      'fightInstanceId': probe.subtraitFightId('encounter_1'),
      'iceApproved': true,
    };
    probe.receiveCombat('combat_help', {...receipt, 'iceInstance': initialIce});
    probe.receiveCombat('combat_help', {
      ...receipt,
      'sessionId': 'wrong-session',
      'iceInstance': freshIce,
    });
    expect(probe.movement(), 0);
    final approved = {...receipt, 'iceInstance': freshIce};
    probe.receiveCombat('combat_help', approved);
    expect(probe.movement(), greaterThan(0));
    probe.receiveCombat('combat_help', approved);
    expect(probe.snapshot()['currentHp'], initialHp);
    expect(probe.snapshot()['conditions'], isEmpty);
    await closeFixture(tester, probe);
  });
}
