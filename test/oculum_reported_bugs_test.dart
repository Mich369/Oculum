import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;

class _MasterTransport extends OculumRealtimeService {
  _MasterTransport()
    : super(
        roomId: 'escape-room',
        playerName: 'Master',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = 'master';
  }
  @override
  bool get isConnected => true;
  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async => true;
  @override
  Future<void> sendInitiativeSnapshot({
    required Map<String, dynamic> snapshot,
    required String campaignId,
    required String campaignName,
    required bool closed,
  }) async {}
}

Future<void> closeSheet(WidgetTester tester, OculumPerformanceProbe p) async {
  p.cancelPendingSave();
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 4));
}

void main() {
  testWidgets('a blocked Master roll stays pending and can be retried', (
    tester,
  ) async {
    final (state, p) = await fixtures.mountFight(tester);
    final token = state.masterInitiativeTokens.first as Map<String, dynamic>;
    final request = <String, dynamic>{
      'id': 'requested-reflex',
      'targetTag': p.ownerTag(),
      'rollKey': 'riflessi',
      'rollName': 'Riflessi',
      'dt': 5,
      'encounterId': 'encounter_1',
      'scope': p.permissionScope,
      'status': 'awaiting',
    };
    token['status'] = 'dead';
    await p.requestedRoll(request);
    expect(request['status'], 'awaiting');
    expect(request['natural'], isNull);
    token['status'] = 'active';
    token['actionUsed'] = false;
    state.masterInitiativeActiveIndex = 0;
    await p.requestedRoll(request);
    expect(request['status'], 'completed');
    expect(request['natural'], inInclusiveRange(1, 20));
    expect(request['total'], isA<int>());
    expect(state.difficoltaTiroController.text, '0');
    await closeSheet(tester, p);
  });

  testWidgets(
    'a Master perception request rolls without opening target selection',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.masterInitiativeActiveIndex = 0;
      final request = <String, dynamic>{
        'id': 'requested-perception',
        'targetTag': p.ownerTag(),
        'rollKey': 'percezione',
        'rollName': 'Percezione',
        'dt': 0,
        'encounterId': 'encounter_1',
        'scope': p.permissionScope,
        'status': 'awaiting',
      };
      await p.requestedRoll(request);
      expect(request['status'], 'completed');
      expect(request['natural'], inInclusiveRange(1, 20));
      expect(find.byType(SimpleDialog), findsNothing);
      await closeSheet(tester, p);
    },
  );

  testWidgets('extra actions can pay for subtrait and escape rolls', (
    tester,
  ) async {
    final (state, p) = await fixtures.mountFight(tester);
    state.masterInitiativeActiveIndex = 0;
    final token = state.masterInitiativeTokens.first as Map<String, dynamic>;
    token.addAll({'actionUsed': true, 'kiExtraActions': 1});
    await p.rollSubtrait('riflessi');
    expect(token['kiExtraActions'], 0);
    expect(state.dadoMostrato, isNotEmpty);
    await closeSheet(tester, p);
  });

  testWidgets('a fled participant rolls and pays the action to return', (
    tester,
  ) async {
    final (state, p) = await fixtures.mountFight(tester);
    state.masterInitiativeActiveIndex = 0;
    final token = state.masterInitiativeTokens.first as Map<String, dynamic>;
    token.addAll({'outsideFight': true, 'status': 'fled'});
    p.escapeTurn(token, 90);
    await p.returnToFight('riflessi');
    expect(token['outsideFight'], isFalse);
    expect(token['actionUsed'], isTrue);
    expect(token['extraFastReactionCurrent'], 1);
    expect(
      state.onlineCombatRequests['escape-return:${p.ownerTag()}']['total'],
      isA<int>(),
    );
    await closeSheet(tester, p);
  });

  testWidgets(
    'escape launches a real roll and stale offers close on a new fight',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.masterInitiativeActiveIndex = 0;
      await p.attemptEscape();
      final request = (state.onlineCombatRequests as Map).values
          .whereType<Map>()
          .firstWhere((r) => r['kind'] == 'escape');
      expect(request['natural'], inInclusiveRange(1, 20));
      expect(request['status'], 'pending');
      p.startFight('encounter_1');
      expect(request['status'], 'closed');
      await closeSheet(tester, p);
    },
  );

  testWidgets(
    'exhaustion preserves an available action despite a stale free reaction',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.masterInitiativeActiveIndex = 0;
      p.totalPowerBurst(159, 2);
      state.onlineCombatRequests['late-free'] = <String, dynamic>{
        'targetTag': p.ownerTag(),
        'freeReaction': true,
      };
      expect(await p.spendCombatRoll(), isTrue);
      expect(state.masterInitiativeTokens.first['actionUsed'], isTrue);
      await closeSheet(tester, p);
    },
  );

  testWidgets('Master applies escape resource packets exactly once', (
    tester,
  ) async {
    final (state, p) = await fixtures.mountFight(tester);
    final transport = _MasterTransport();
    state.realtimeService = transport;
    state.masterInitiativeActiveIndex = 0;
    state.realtimeUsers.add(<String, dynamic>{
      'sessionId': 'player-session',
      'role': 'player',
      'localSheetTags': [p.ownerTag()],
    });
    final packet = <String, dynamic>{
      'id': 'escape-network',
      'escapeEvent': true,
      'kind': 'escape',
      'stage': 'offer',
      'scope': p.permissionScope,
      'campaignId': state.activeCampaignId,
      'encounterId': 'encounter_1',
      'sourceTag': p.ownerTag(),
      'senderTag': p.ownerTag(),
      'targetTag': p.ownerTag(),
      'senderRole': 'player',
      'sessionId': 'player-session',
      'total': 30,
      'natural': 15,
      'movement': 5,
      'turnResourceSpends': [
        {'id': 'escape-action', 'sheetTag': p.ownerTag(), 'resource': 'azione'},
      ],
    };
    p.receiveCombat('combat_scout', packet);
    expect(state.masterInitiativeTokens.first['actionUsed'], isTrue);
    final active = state.masterInitiativeActiveIndex;
    expect(active, isNot(0));
    p.receiveCombat('combat_scout', packet);
    expect(state.masterInitiativeActiveIndex, active);
    state.realtimeService = null;
    await transport.dispose();
    await closeSheet(tester, p);
  });

  testWidgets(
    'a player snapshot for a new fight does not keep an old escape blocked',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.masterInitiativeActiveIndex = 0;
      final token = state.masterInitiativeTokens.first as Map<String, dynamic>;
      token['fightInstanceId'] = 'fight-a';
      await p.attemptEscape();
      token['fightInstanceId'] = 'fight-b';
      token['actionUsed'] = false;
      state.masterInitiativeActiveIndex = 0;
      await p.attemptEscape();
      final records = (state.onlineCombatRequests as Map).values
          .whereType<Map>()
          .where((r) => r['kind'] == 'escape')
          .toList();
      expect(records, hasLength(2));
      expect(records.last['fightInstanceId'], 'fight-b');
      await closeSheet(tester, p);
    },
  );

  testWidgets('escape EXP is actually assigned once and survives JSON reload', (
    tester,
  ) async {
    final (state, p) = await fixtures.mountFight(tester);
    final before = readIntValue(state.expController.text);
    final reward = <String, dynamic>{
      'id': 'escaped-exp',
      'amount': 73,
      'name': 'Fuga',
      'participants': [p.ownerTag()],
      'escapeExperience': {p.ownerTag(): 73},
      'defeated': <Map>[],
    };
    p.encounterRewards([reward]);
    expect(readIntValue(state.expController.text), before + 73);
    p.encounterRewards([reward]);
    expect(readIntValue(state.expController.text), before + 73);
    final saved = p.snapshot();
    p.load(saved);
    p.encounterRewards([reward]);
    expect(readIntValue(state.expController.text), before + 73);
    await closeSheet(tester, p);
  });
}
