import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _SupportMasterTransport extends OculumRealtimeService {
  _SupportMasterTransport({String role = 'master'})
    : super(
        roomId: 'support-test',
        playerName: 'Master',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = role;
  }
  bool connected = true;
  bool delivered = true;
  final sent = <Map<String, dynamic>>[];
  @override
  bool get isConnected => connected;
  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    sent.add({'event': event, ...payload});
    return delivered;
  }
}

void _helper(dynamic state, OculumPerformanceProbe p) {
  state.masterInitiativeRound = 4;
  state.masterInitiativeTokens.add(<String, dynamic>{
    'id': 'CompagnoOcu:3690HELP',
    'sheetTag': 'CompagnoOcu:3690HELP',
    'side': 'party',
    'status': 'ready',
    'fightInstanceId': 'support-fight',
    'name': 'Compagno',
  });
  final helper = p.snapshot()
    ..addAll({
      'id': 'CompagnoOcu:3690HELP',
      'sheetTag': 'CompagnoOcu:3690HELP',
      'tipoScheda': 'Personaggio',
      'resilienza': '3',
      'volonta': '1',
      'materia': '2',
      'oculum': '4',
      'livello': '1',
      'grado': '0',
    });
  state.schedePersonaggio.add(helper);
  p.recordCurrentEncounter();
}

List<Map> _history(dynamic state) =>
    ((state.masterInitiativeGroups as List)
                    .cast<Map>()
                    .first['rewardSupportHistory']
                as List? ??
            const [])
        .whereType<Map>()
        .toList();

Map<String, dynamic> _healingRequest(
  OculumPerformanceProbe p,
  OculumStructuredEffect effect,
) => {
  'id': 'healing-cast',
  'encounterId': 'encounter_1',
  'sourceTag': 'CompagnoOcu:3690HELP',
  'targetTag': p.ownerTag(),
  'effects': [effect.toJson()],
};

void main() {
  testWidgets(
    'real applied heal is retained across failed send, reload and acknowledged replay',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _helper(state, p);
      for (final token in state.masterInitiativeTokens as List) {
        token['fightInstanceId'] = 'outbox-fight';
      }
      state.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
        'encounterId': 'encounter_1',
        'fightStarted': true,
        'tokens': jsonDecode(jsonEncode(state.masterInitiativeTokens)),
      };
      state.realtimeEncounterSnapshots.clear();
      final transport = _SupportMasterTransport(role: 'player')
        ..delivered = false;
      state.realtimeService = transport;
      state.resilienzaController.text = '10';
      state.currentResilienzaController.text = '10';
      state.currentHpController.text = '40';
      final effect = OculumStructuredEffect(
        id: 'outbox-heal',
        type: 'cura',
        resource: 'vita',
        recipient: 'se_stesso',
        valueExpression: '20',
        duration: '0',
      );
      final request = _healingRequest(p, effect)..['scope'] = p.permissionScope;
      state.onlineCombatRequests[request['id']] = request;
      p.applyRewardEffects([effect], request);
      await tester.pump();
      expect(p.currentHp(), 60);
      expect(p.rewardSupportOutbox(), hasLength(1));
      expect(
        transport.sent.where((e) => e['helpMode'] == 'reward_receipt'),
        hasLength(1),
      );
      p.attachRewardSupportReceipts(request);
      expect(request['rewardSupportReceipts'], hasLength(1));
      final saved = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(p.snapshot())) as Map,
      );
      state.schedePersonaggio[0] = saved;
      p.load(saved);
      transport.sent.clear();
      transport.delivered = true;
      await p.replayRewardSupportReceipts();
      expect(transport.sent, hasLength(1));
      expect(
        transport.sent.single.containsKey('turnResourceSpends'),
        false,
        reason: 'Proof replay cannot spend or replay an Action/Reacion',
      );
      expect(
        p.currentHp(),
        60,
        reason: 'Replaying proof never applies healing twice',
      );
      final receipt = p.rewardSupportOutbox().values.single as Map;
      const master = 'MasterOcu:3690ACKK';
      state.realtimeUsers.add(<String, dynamic>{
        'sessionId': 'master-session',
        'role': 'master',
        'localSheetTags': [master],
      });
      final ack = <String, dynamic>{
        ...Map<String, dynamic>.from(receipt),
        'phase': 'reward_support',
        'senderRole': 'master',
        'senderTag': master,
        'sessionId': 'master-session',
        'campaignId': state.activeCampaignId,
      };
      p.rewardSupportAck({...ack, 'senderRole': 'player'});
      expect(p.rewardSupportOutbox(), hasLength(1));
      p.rewardSupportAck(ack);
      p.rewardSupportAck(ack);
      expect(p.rewardSupportOutbox(), isEmpty);
      state.realtimeService = null;
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'support proof waits off board and rejects a superseded fight without new traffic',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _helper(state, p);
      for (final token in state.masterInitiativeTokens as List) {
        token['fightInstanceId'] = 'old-fight';
      }
      final tokens =
          jsonDecode(jsonEncode(state.masterInitiativeTokens)) as List;
      state.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
        'encounterId': 'encounter_1',
        'fightStarted': true,
        'tokens': tokens,
      };
      state.realtimeEncounterSnapshots.clear();
      final transport = _SupportMasterTransport(role: 'player')
        ..connected = false;
      state.realtimeService = transport;
      state.resilienzaController.text = '10';
      state.currentResilienzaController.text = '10';
      state.currentHpController.text = '40';
      final effect = OculumStructuredEffect(
        id: 'waiting-heal',
        type: 'cura',
        resource: 'vita',
        recipient: 'se_stesso',
        valueExpression: '20',
        duration: '0',
      );
      final request = _healingRequest(p, effect)..['scope'] = p.permissionScope;
      state.onlineCombatRequests[request['id']] = request;
      p.applyRewardEffects([effect], request);
      expect(p.rewardSupportOutbox(), hasLength(1));
      expect(transport.sent, isEmpty);
      transport.connected = true;
      state.realtimeVisibleInitiativeSnapshot['encounterId'] = 'other-board';
      await p.replayRewardSupportReceipts();
      expect(p.rewardSupportOutbox(), hasLength(1));
      expect(transport.sent, isEmpty);
      state.realtimeVisibleInitiativeSnapshot['encounterId'] = 'encounter_1';
      for (final token in tokens) {
        token['fightInstanceId'] = 'new-fight';
      }
      await p.replayRewardSupportReceipts();
      expect(p.rewardSupportOutbox(), isEmpty);
      expect(transport.sent, isEmpty);
      state.realtimeService = null;
      await closeFixture(tester, p);
    },
  );
  test(
    'healing keeps one ID and follows its beneficiary into several real contributions',
    () {
      final enemies = <Map>[
        {'id': 'E1', 'killerTag': 'HERO', 'lastAttackId': 'kill-1'},
        {'id': 'E2', 'killerTag': 'OTHER', 'lastAttackId': 'kill-2'},
        {'id': 'E3', 'killerTag': 'UNRELATED'},
      ];
      final history = <Map>[
        {
          'id': 'heal-one',
          'kind': 'heal',
          'helperTag': 'HEALER',
          'beneficiaryTag': 'HERO',
        },
        {
          'id': 'assist-2',
          'kind': 'attack',
          'helperTag': 'HERO',
          'enemyTag': 'E2',
          'requestId': 'kill-2',
          'decisive': true,
        },
      ];
      final rows = prepareEncounterRewardSupportHistory(enemies, history);
      final heal = rows.singleWhere((r) => r['kind'] == 'heal');
      expect(heal['id'], 'heal-one');
      expect(heal['enemyTags'], unorderedEquals(['E1', 'E2']));
      expect(
        rows.singleWhere((r) => r['kind'] == 'attack')['finalAttack'],
        true,
      );
      expect(
        history.first['enemyTags'],
        isNull,
        reason: 'saved source history remains editable',
      );
    },
  );

  test(
    'only the help used for the actual final attack becomes lethal assistance',
    () {
      final rows = prepareEncounterRewardSupportHistory(
        [
          {'id': 'E', 'lastAttackId': 'last'},
        ],
        [
          {
            'id': 'old-help',
            'kind': 'attack',
            'enemyTag': 'E',
            'requestId': 'old',
          },
          {
            'id': 'final-help',
            'kind': 'attack',
            'enemyTag': 'E',
            'requestId': 'last',
          },
        ],
      );
      expect(rows.first['finalAttack'], isNot(true));
      expect(rows.last['finalAttack'], true);
    },
  );

  testWidgets(
    'actual damage and consumed attack help are recorded once with permanent helper PT',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _helper(state, p);
      final request = <String, dynamic>{
        'id': 'actual-hit',
        'encounterId': 'encounter_1',
        'sourceTag': p.ownerTag(),
        'targetTag': 'ENEMY',
        'status': 'resolved',
        'outcome': 'full',
        'attack': 23,
        'defense': 20,
        'difficulty': 'normale',
        'sourceHelpersContributions': [
          {'id': 'help-used', 'sourceTag': 'CompagnoOcu:3690HELP', 'bonus': 4},
        ],
        'damageReceipt': {
          'hpLost': 5,
          'shieldLost': 7,
          'temporaryHpLost': 2,
          'oculumShieldLost': 3,
        },
        'helperTotalPower': 999999,
      };
      p.rewardCombatResult(request);
      p.rewardCombatResult(request);
      final history = _history(state);
      expect(history, hasLength(2));
      expect(
        history.singleWhere((r) => r['kind'] == 'damage')['helperTag'],
        p.ownerTag(),
      );
      final help = history.singleWhere((r) => r['kind'] == 'attack');
      expect(help['helperTag'], 'CompagnoOcu:3690HELP');
      expect(help['decisive'], true);
      expect(help['round'], 4);
      expect(help['helpReceiptId'], 'help-used:attack:CompagnoOcu:3690HELP');
      expect(
        help['helperTotalPower'],
        oculumEncounterPermanentTotalPower(
          (state.schedePersonaggio as List).last as Map,
        ),
      );
      expect(
        state.masterInitiativeTokens[1]['rewardLastDamageRequestId'],
        'actual-hit',
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'consumed defense help is attributed against the enemy even if it avoids all damage',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _helper(state, p);
      p.rewardCombatResult({
        'id': 'avoided-hit',
        'encounterId': 'encounter_1',
        'sourceTag': 'ENEMY',
        'targetTag': p.ownerTag(),
        'status': 'resolved',
        'outcome': 'avoided',
        'attack': 20,
        'defense': 24,
        'defenseHelpersContributions': [
          {'id': 'def-help', 'sourceTag': 'CompagnoOcu:3690HELP', 'bonus': 5},
        ],
        'damageReceipt': {'hpLost': 0, 'shieldLost': 0},
      });
      expect(_history(state), hasLength(1));
      expect(_history(state).single['kind'], 'defense');
      expect(_history(state).single['enemyTag'], 'ENEMY');
      expect(_history(state).single['beneficiaryTag'], p.ownerTag());
      await closeFixture(tester, p);
    },
  );

  for (final percentBefore in [40, 51, 100]) {
    testWidgets(
      'healing support records only effective ally HP below 51 percent: $percentBefore',
      (tester) async {
        final (state, p) = await fixtures.mountFight(tester);
        _helper(state, p);
        state.resilienzaController.text = '10';
        state.currentResilienzaController.text = '10';
        state.livelloController.text = '0';
        state.gradoController.text = '0';
        // RES10 / Level0 has60 maximum HP. Ceil keeps51% above the cutoff.
        final hpBefore = (60 * percentBefore / 100).ceil();
        state.currentHpController.text = '$hpBefore';
        p.invalidateDerivedCaches();
        expect(p.maximumHp(), 60);
        final effect = OculumStructuredEffect(
          id: 'healing',
          type: 'cura',
          resource: 'vita',
          recipient: 'se_stesso',
          valueExpression: '20',
          duration: '0',
        );
        p.applyRewardEffects([effect], _healingRequest(p, effect));
        final history = _history(state);
        if (percentBefore == 40) {
          expect(history, hasLength(1));
          expect(history.single['kind'], 'heal');
          expect(history.single['amount'], 20);
          expect(history.single['hpBefore'], 24);
          expect(history.single['hpMax'], 60);
        } else {
          expect(history, isEmpty);
        }
        await closeFixture(tester, p);
      },
    );
  }

  testWidgets(
    'an actually applied hostile penalty counts but a zero penalty does not',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _helper(state, p);
      state.masterInitiativeTokens.first['side'] = 'enemy';
      p.recordCurrentEncounter();
      for (final amount in [0, 2]) {
        final effect = OculumStructuredEffect(
          id: 'debuff-$amount',
          type: 'modifica_statistica',
          target: 'materia',
          mode: 'diminuzione',
          recipient: 'se_stesso',
          valueExpression: '$amount',
          duration: '3',
        );
        p.applyRewardEffects(
          [effect],
          {
            'id': 'penalty-$amount',
            'sourceTag': 'CompagnoOcu:3690HELP',
            'targetTag': p.ownerTag(),
            'encounterId': 'encounter_1',
            'effects': [effect.toJson()],
          },
        );
      }
      expect(_history(state), hasLength(1));
      expect(_history(state).single['kind'], 'debuff');
      expect(_history(state).single['enemyTag'], p.ownerTag());
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'authenticated receipt cannot forge a new id, excessive heal or helper PT',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _helper(state, p);
      state.resilienzaController.text = '10';
      state.currentResilienzaController.text = '10';
      state.livelloController.text = '0';
      state.gradoController.text = '0';
      state.currentHpController.text = '24';
      p.invalidateDerivedCaches();
      expect(p.maximumHp(), 60);
      final effect = OculumStructuredEffect(
        id: 'heal-auth',
        type: 'cura',
        resource: 'vita',
        recipient: 'se_stesso',
        valueExpression: '20',
        duration: '0',
      );
      final original = _healingRequest(p, effect);
      p.applyRewardEffects([effect], original);
      final id = '${_history(state).single['id']}';
      state.masterInitiativeGroups.first['rewardSupportHistory'] =
          <Map<String, dynamic>>[];
      state.onlineCombatRequests[original['id']] = original;
      state.realtimeService = _SupportMasterTransport();
      state.realtimeUsers.add(<String, dynamic>{
        'sessionId': 'owner-session',
        'role': 'player',
        'localSheetTags': [p.ownerTag()],
      });
      final packet = <String, dynamic>{
        'id': id,
        'scope': p.permissionScope,
        'campaignId': state.activeCampaignId,
        'sessionId': 'owner-session',
        'senderRole': 'player',
        'senderTag': p.ownerTag(),
        'helpMode': 'reward_receipt',
        'sourceTag': 'CompagnoOcu:3690HELP',
        'targetTag': p.ownerTag(),
        'receiptFor': original['id'],
        'encounterId': 'encounter_1',
        'rewardSupportKind': 'heal',
        'effectId': effect.id,
        'effectType': effect.type,
        'effectTarget': effect.target,
        'hpBefore': 24,
        'hpMax': 60,
        'amount': 20,
        'helperTotalPower': 999999,
      };
      p.rewardSupportReceipt({...packet, 'id': 'made-up-id'});
      p.rewardSupportReceipt({...packet, 'amount': 1000});
      p.rewardSupportReceipt({...packet, 'senderTag': 'ANOTHER'});
      p.rewardSupportReply({
        ...packet,
        'id': original['id'],
        'senderTag': 'ANOTHER',
        'rewardSupportReceipts': [
          {...packet, 'senderRole': 'master'},
        ],
      });
      expect(_history(state), isEmpty);
      p.rewardSupportReply({
        ...packet,
        'id': original['id'],
        'rewardSupportReceipts': [
          {...packet, 'senderRole': 'master', 'senderTag': 'FORGED'},
        ],
      });
      p.rewardSupportReceipt(packet);
      p.rewardSupportReceipt(packet);
      expect(_history(state), hasLength(1));
      expect(
        _history(state).single['helperTotalPower'],
        oculumEncounterPermanentTotalPower(
          (state.schedePersonaggio as List).last as Map,
        ),
      );
      state.realtimeService = null;
      await closeFixture(tester, p);
    },
  );
}
