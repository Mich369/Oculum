import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _ProgressTransport extends OculumRealtimeService {
  _ProgressTransport({String room = 'progress-log-test'})
    : super(
        roomId: room,
        playerName: 'Master',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = 'master';
  }
  bool delivered = true;
  final attempts = <Map<String, dynamic>>[];
  @override
  bool get isConnected => true;
  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async => true;
  @override
  Future<bool> sendProgressionLog(Map<String, dynamic> payload) async {
    attempts.add({...payload, 'delivered': delivered});
    return delivered;
  }
}

Future<(dynamic, OculumPerformanceProbe, _ProgressTransport)> _mount(
  WidgetTester tester,
) async {
  final (state, p) = await fixtures.mountFight(tester);
  state.extraTopLevelSaveFields.remove('progressionLogState');
  state.expController.text = '0';
  state.livelloController.text = '0';
  state.scalaExpAutomatica = true;
  state.logEventi.clear();
  final service = _ProgressTransport();
  state.realtimeService = service;
  return (state, p, service);
}

Map _logs(OculumPerformanceProbe p) => p.progressionLogSnapshot();
List _pending(OculumPerformanceProbe p) =>
    _logs(p)['pending'] as List? ?? const [];

Future<void> _roundTripSave(
  WidgetTester tester,
  dynamic state,
  OculumPerformanceProbe p,
) async {
  final saved = Map<String, dynamic>.from(
    jsonDecode(jsonEncode(p.progressionSaveEnvelope())) as Map,
  );
  expect(saved['progressionLogState'], isA<Map>());
  expect(
    p.snapshot().containsKey('progressionLogState'),
    false,
    reason: 'Private outbox is not part of an exported character sheet',
  );
  state.extraTopLevelSaveFields.remove('progressionLogState');
  p.restoreProgressionSaveEnvelope(saved);
}

Map<String, dynamic> _remote(dynamic state, OculumPerformanceProbe p) {
  const tag = 'CompagnoOcu:3690PROG';
  state.realtimeUsers = <Map<String, dynamic>>[
    {
      'sessionId': 'remote-session',
      'role': 'player',
      'activeSheetTag': tag,
      'localSheetTags': [tag],
    },
  ];
  return {
    'id': 'remote-exp-once',
    'progressionLog': true,
    'sheetTag': tag,
    'sheetName': 'Compagno',
    'senderTag': tag,
    'senderRole': 'player',
    'sessionId': 'remote-session',
    'scope': p.permissionScope,
    'campaignId': p.permissionCampaignId,
    'amount': 1000,
    'beforeLevel': 0,
    'afterLevel': 1,
    'reason': 'Fine fight',
  };
}

void main() {
  testWidgets(
    'two authenticated authors with the same event ID cannot suppress each other',
    (tester) async {
      final (state, p, _) = await _mount(tester);
      final first = _remote(state, p);
      const other = 'AltraOcu:3690PROG';
      state.realtimeUsers.add(<String, dynamic>{
        'sessionId': 'another-session',
        'role': 'player',
        'localSheetTags': [other],
      });
      final second = <String, dynamic>{
        ...first,
        'sheetTag': other,
        'senderTag': other,
        'sheetName': 'Altro',
        'sessionId': 'another-session',
      };
      for (final payload in [first, second, first, second]) {
        p.receiveRealtime('party_log', payload);
      }
      final rows = (state.logEventi as List).map((row) => '$row');
      expect(
        rows.where((row) => row.contains('[Realtime] [EXP] Compagno')),
        hasLength(1),
      );
      expect(
        rows.where((row) => row.contains('[Realtime] [EXP] Altro')),
        hasLength(1),
      );
      expect(_logs(p)['receivedIds'], hasLength(2));
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'an explicit award receipt stays consumed after more than 1000 newer logs and reload',
    (tester) async {
      final (state, p, _) = await _mount(tester);
      state.realtimeService = null;
      p.awardExperience(5, receiptId: 'durable-award');
      for (var i = 0; i < 1005; i++) {
        p.awardExperience(0, receiptId: 'newer-log:$i');
      }
      final exp = state.expController.text;
      expect((_logs(p)['recordedIds'] as List).length, lessThanOrEqualTo(1000));
      await _roundTripSave(tester, state, p);
      expect(p.awardExperience(5, receiptId: 'durable-award'), isEmpty);
      expect(state.expController.text, exp);
      await closeFixture(tester, p);
    },
  );
  testWidgets('actual EXP award announces its real level-up exactly once', (
    tester,
  ) async {
    final (state, p, service) = await _mount(tester);
    p.awardExperience(
      3000,
      reason: 'Premio verificato',
      receiptId: 'real-award',
    );
    await tester.pump();
    await p.flushProgressionLogs();
    final success = service.attempts
        .where((r) => r['delivered'] == true)
        .toList();
    expect(success, hasLength(1));
    expect(success.single['amount'], 3000);
    expect(success.single['beforeLevel'], 0);
    expect(
      success.single['afterLevel'],
      int.parse(state.livelloController.text),
    );
    expect(success.single['afterLevel'], greaterThan(0));
    expect(success.single['message'], contains('[LIVELLO]'));
    expect(
      (state.logEventi as List).where((r) => '$r'.contains('[LIVELLO]')),
      hasLength(1),
    );
    final after = state.expController.text;
    expect(p.awardExperience(3000, receiptId: 'real-award'), isEmpty);
    expect(state.expController.text, after);
    await p.flushProgressionLogs();
    expect(service.attempts.where((r) => r['delivered'] == true), hasLength(1));
    await closeFixture(tester, p);
  });
  testWidgets(
    'zero EXP whole-fight settlement is logged locally without inventing a level or network work',
    (tester) async {
      final (state, p, service) = await _mount(tester);
      state.realtimeService = null;
      p.encounterRewards([
        {
          'id': 'zero-settlement',
          'rewardMethod': oculumEncounterRewardMethodDifference,
          'endedEncounterId': 'encounter_1',
          'name': 'Scontro senza EXP',
          'participants': [p.ownerTag()],
          'experienceByParticipant': {p.ownerTag(): 0},
          'defeated': <Map<String, dynamic>>[],
        },
      ]);
      expect(state.expController.text, '0');
      expect(state.livelloController.text, '0');
      expect(
        (state.logEventi as List).any((r) => '$r'.contains('+0 EXP')),
        true,
      );
      expect(
        (state.logEventi as List).any((r) => '$r'.contains('[LIVELLO]')),
        false,
      );
      expect(_pending(p), isEmpty);
      expect(service.attempts, isEmpty);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'failed online delivery survives save reload and retries without granting EXP again',
    (tester) async {
      final (state, p, service) = await _mount(tester);
      service.delivered = false;
      p.awardExperience(
        25,
        reason: 'Premio in attesa',
        receiptId: 'retry-once',
      );
      await tester.pump();
      await p.flushProgressionLogs();
      expect(_pending(p), hasLength(1));
      await _roundTripSave(tester, state, p);
      expect(_pending(p), hasLength(1));
      final exp = state.expController.text;
      service.delivered = true;
      await p.flushProgressionLogs();
      expect(_pending(p), isEmpty);
      expect(state.expController.text, exp);
      expect(
        service.attempts.where((r) => r['delivered'] == true),
        hasLength(1),
      );
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'changing room never spills a queued private progression message to the new scope',
    (tester) async {
      final (state, p, first) = await _mount(tester);
      first.delivered = false;
      p.awardExperience(15, receiptId: 'old-room');
      await tester.pump();
      await p.flushProgressionLogs();
      expect(_pending(p), hasLength(1));
      final second = _ProgressTransport(room: 'different-progress-room');
      state.realtimeService = second;
      await p.flushProgressionLogs();
      expect(second.attempts, isEmpty);
      expect(_pending(p), hasLength(1));
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'remote progression log is displayed once across duplicate broadcasts and save reload',
    (tester) async {
      final (state, p, _) = await _mount(tester);
      final payload = _remote(state, p);
      p.receiveRealtime('party_log', payload);
      p.receiveRealtime('party_log', payload);
      expect(
        (state.logEventi as List).where(
          (r) => '$r'.contains('[Realtime] [EXP] Compagno'),
        ),
        hasLength(1),
      );
      await _roundTripSave(tester, state, p);
      _remote(state, p);
      final before = (state.logEventi as List).length;
      p.receiveRealtime('party_log', payload);
      expect((state.logEventi as List).length, before);
      expect((_logs(p)['receivedIds'] as List), hasLength(1));
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'receiving EXP reports cannot grant EXP and forged sheet or session reports are rejected',
    (tester) async {
      final (state, p, _) = await _mount(tester);
      final payload = _remote(state, p);
      final exp = state.expController.text;
      final level = state.livelloController.text;
      p.receiveRealtime('party_log', payload);
      expect(state.expController.text, exp);
      expect(state.livelloController.text, level);
      final count = (state.logEventi as List).length;
      p.receiveRealtime('party_log', {
        ...payload,
        'id': 'forged-sheet',
        'sheetTag': p.ownerTag(),
        'amount': 999999,
      });
      p.receiveRealtime('party_log', {
        ...payload,
        'id': 'forged-session',
        'sessionId': 'unknown-session',
        'amount': 999999,
      });
      expect((state.logEventi as List).length, count);
      expect(state.expController.text, exp);
      expect(state.livelloController.text, level);
      await closeFixture(tester, p);
    },
  );
}
