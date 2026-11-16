import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oculum/game/oculum_resurrection_stone.dart';
import 'package:oculum/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  for (final inFight in [false, true]) {
    testWidgets('a local stone revives an allied token (Fight: $inFight)', (
      tester,
    ) async {
      final (state, probe) = await fixtures.mountFight(tester);
      state.activeCampaignId = 'resurrection-fixture';
      state.masterInitiativeGroups.first['fightStarted'] = inFight;
      state.currentHpController.text = '20';
      state.inventario.clear();
      state.inventario.add(oculumResurrectionStone());
      final actor = state.masterInitiativeTokens[0] as Map<String, dynamic>;
      final target = state.masterInitiativeTokens[1] as Map<String, dynamic>;
      target.addAll({
        'name': 'Creatura alleata',
        'side': 'party',
        'maxHp': 11,
        'currentHp': 11,
        'currentOculum': 2,
        'shield': 4,
      });
      state.masterInitiativeActiveIndex = 0;
      probe.recordCurrentEncounter();
      await probe.participantCommand('encounter_1', target, 'toggleDead');
      expect(target['status'], 'dead');
      expect(target['resurrectionStoneWindow'], isA<Map>());

      await probe.participantCommand('encounter_1', target, 'resurrectionStone');
      expect(target['status'], inFight ? anyOf('ready', 'active') : 'ready');
      expect(target['currentHp'], 6);
      expect(target['currentOculum'], 2);
      expect(target['shield'], 4);
      expect(state.inventario, isEmpty);
      expect(actor['actionUsed'] == true, inFight);
      await probe.participantCommand('encounter_1', target, 'resurrectionStone');
      expect(target['currentHp'], 6);
      await closeFixture(tester, probe);
    });
  }

  testWidgets('a token-only corpse can be resurrected after Fight and reload', (
    tester,
  ) async {
    final (state, probe) = await fixtures.mountFight(tester);
    state.activeCampaignId = 'resurrection-corpse-fixture';
    probe.setWorldClock({'seconds': 120});
    state.currentHpController.text = '20';
    state.inventario
      ..clear()
      ..add(oculumResurrectionStone()..quantita = 2);
    probe.saveSheet();

    final board = state.masterInitiativeTokens as List<Map<String, dynamic>>;
    board.first['fightTeamId'] = 'team:resurrection';
    final corpse = board[1];
    corpse.addAll({
      'name': 'Mostro senza scheda',
      'monsterBookId': 'goblin_base',
      'fightTeamId': 'team:resurrection',
      'maxHp': 11,
      'currentHp': 11,
      'level': 0,
      'grade': 0,
      'statsTotal': 3,
    });
    board[2]['status'] = 'fled';
    probe.recordCurrentEncounter();
    await probe.participantCommand('encounter_1', corpse, 'toggleDead');
    final window = OculumResurrectionWindow.fromJson(
      corpse['resurrectionStoneWindow'],
    )!;

    final finish = probe.finishEncounter('encounter_1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Termina, tira i Drop e assegna EXP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await finish;
    expect(board.any((token) => token['id'] == corpse['id']), isFalse);

    Map<String, dynamic> origin() =>
        (state.masterInitiativeGroups as List<Map<String, dynamic>>).firstWhere(
          (group) => group['id'] == 'encounter_1',
        );
    Map<String, dynamic> savedCampaign() =>
        jsonDecode(jsonEncode(probe.campaignSnapshot())) as Map<String, dynamic>;
    final snapshot = savedCampaign()
      ..['selectedMasterInitiativeGroupId'] = 'encounter_2';
    probe.loadCampaign(snapshot);
    final inventory = state.inventario as List<InventoryItem>;
    InventoryItem stone() => inventory.singleWhere(
      (item) => item.craftData['resurrectionStone'] == true,
    );
    final originalActor = (origin()['tokens'] as List).whereType<Map>().single;

    Future<void> pumpDialogTransition() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
    }

    Future<void> expectUnavailable() async {
      final use = probe.useMerchantItem(stone());
      await pumpDialogTransition();
      expect(find.text('Nessun alleato morto entro la finestra.'), findsOneWidget);
      Navigator.of(tester.element(find.byType(SimpleDialog))).pop();
      await pumpDialogTransition();
      await use;
      expect(stone().quantita, 2);
    }

    originalActor['fightTeamId'] = 'team:unrelated';
    await expectUnavailable();
    originalActor['fightTeamId'] = 'team:resurrection';
    state.activeCampaignId = 'another-campaign';
    await expectUnavailable();
    state.activeCampaignId = window.campaignId;
    probe.setWorldClock({'seconds': window.expiresAtSeconds + 1});
    await expectUnavailable();
    probe.setWorldClock({'seconds': window.expiresAtSeconds});

    final use = probe.useMerchantItem(stone());
    await pumpDialogTransition();
    await tester.tap(find.text('Mostro senza scheda'));
    await pumpDialogTransition();
    await use;
    expect(stone().quantita, 1);
    expect(state.selectedMasterInitiativeGroupId, 'encounter_2');

    probe.loadCampaign(savedCampaign());
    final restored = (origin()['tokens'] as List).whereType<Map>().singleWhere(
      (token) => token['id'] == corpse['id'],
    );
    expect(restored['currentHp'], 6);
    expect(restored['status'], 'ready');
    expect(restored['side'], 'enemy');
    expect(restored['outsideFight'], isTrue);
    expect(restored['actionUsed'], isFalse);
    expect(origin()['fightStarted'], isFalse);
    expect(origin()['resurrectionCorpses'], isNull);
    final receipt = OculumResurrectionWindow.fromJson(
      restored['resurrectionStoneWindow'],
    )!;
    expect(receipt.stoneUseId, 'stone:${window.deathId}');
    expect(receipt.closed, isTrue);
    expect(stone().quantita, 1);
    await probe.finishEncounter('encounter_1');
    expect(origin()['rewards'], hasLength(1));
    expect(origin()['settlementReceiptIds'], hasLength(1));
    await closeFixture(tester, probe);
  });

  test('Resurrection Stone clock, state and current use preflight', () {
    OculumResurrectionWindow? start(
      String level, {
      OculumResurrectionWindow? current,
      bool transition = true,
      int seconds = 17,
      String death = 'death.1',
    }) => OculumResurrectionWindow.recordDeath(
      current: current,
      isNewConfirmedDeath: transition,
      campaignId: 'campaign.1',
      deathId: death,
      worldClockSeconds: seconds,
      normalizedDifficulty: level,
    );

    for (final entry in {
      'facile': 18,
      'normale': 18,
      'difficile': 9,
      'oculum': 3,
    }.entries) {
      final window = start(entry.key)!;
      assert(window.expiresAtSeconds == 17 + entry.value * 3600, entry.key);
    }
    assert(start('oculum', transition: false) == null);
    final initial = start('facile', seconds: 0)!;
    assert(identical(start('oculum', current: initial, seconds: 140), initial));
    final loaded = OculumResurrectionWindow.fromJson(initial.toJson())!;
    assert(loaded.startedAtSeconds == 0);
    assert(loaded.expiresAtSeconds == 64800);
    assert(
      OculumResurrectionWindow.fromJson({'campaignId': 'campaign.1'}) == null,
    );
    assert(oculumResurrectionStoneHp(1) == 1);
    assert(oculumResurrectionStoneHp(2) == 1);
    assert(oculumResurrectionStoneHp(3) == 2);
    assert(oculumResurrectionStoneHp(83) == 42);

    OculumResurrectionStoneResult check({
      OculumResurrectionWindow? window,
      String campaign = 'campaign.1',
      String death = 'death.1',
      String useId = 'use.1',
      int now = 64800,
      bool dead = true,
      bool ally = true,
      int stones = 1,
      bool fight = false,
      bool action = false,
    }) => oculumCheckResurrectionStone(
      window: window,
      campaignId: campaign,
      expectedDeathId: death,
      useId: useId,
      worldClockSeconds: now,
      targetIsConfirmedDead: dead,
      alliedLivingActor: ally,
      availableStoneCount: stones,
      inFight: fight,
      hasAvailableAction: action,
    );
    assert(check() == OculumResurrectionStoneResult.unrecordedDeath);
    assert(check(window: loaded) == OculumResurrectionStoneResult.eligible);
    assert(
      check(window: loaded, now: 64801) ==
          OculumResurrectionStoneResult.outsideWindow,
    );
    assert(
      check(window: loaded, fight: true) ==
          OculumResurrectionStoneResult.missingAction,
    );
    assert(
      check(window: loaded, fight: true, action: true) ==
          OculumResurrectionStoneResult.eligible,
    );
    assert(
      check(window: loaded, campaign: 'campaign.2') ==
          OculumResurrectionStoneResult.wrongDeath,
    );
    assert(
      check(window: loaded, dead: false) ==
          OculumResurrectionStoneResult.closedDeath,
    );
    assert(
      check(window: loaded, stones: 0) ==
          OculumResurrectionStoneResult.missingStone,
    );
    assert(
      check(window: loaded, ally: false) ==
          OculumResurrectionStoneResult.ineligibleAlly,
    );
    final used = OculumResurrectionWindow.fromJson(
      loaded.close(useId: 'use.1').toJson(),
    )!;
    assert(
      check(window: used, now: 99999, dead: false, stones: 0) ==
          OculumResurrectionStoneResult.alreadyApplied,
    );
    assert(
      check(window: used, useId: 'use.2') ==
          OculumResurrectionStoneResult.closedDeath,
    );
    assert(identical(start('oculum', current: used), used));
    final next = start('oculum', current: used, death: 'death.2')!;
    assert(next.expiresAtSeconds == 17 + 10800);
    assert(
      check(window: next, death: 'death.1') ==
          OculumResurrectionStoneResult.wrongDeath,
    );
  });
}
