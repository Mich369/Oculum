import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CombatService extends OculumRealtimeService {
  @override
  String get channelName => 'oculum_secure_synthetic-room';
  _CombatService()
    : super(
        roomId: 'combat_test',
        playerName: 'Rose',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      );
  @override
  bool get isConnected => true;
  final turnSnapshots = <Map<String, dynamic>>[];
  int sheetRequests = 0;
  @override
  Future<bool> requestSharedSheetsConfirmed({
    String targetSheetTag = '',
  }) async {
    sheetRequests++;
    return true;
  }

  @override
  Future<void> sendInitiativeSnapshot({
    required Map<String, dynamic> snapshot,
    required String campaignId,
    required String campaignName,
    required bool closed,
  }) async {
    turnSnapshots.add(snapshot);
  }

  final staffSheets = <Map<String, dynamic>>[];
  @override
  Future<void> sendSharedSheet({
    required Map<String, dynamic> sheet,
    required String campaignId,
    required String campaignName,
    required String sheetId,
    required String sheetName,
    required String ownerTag,
    required String senderRole,
    required String targetAudience,
    required bool fromMaster,
    required bool masterParty,
    List<String> targetTags = const [],
    List<String> allowClearFields = const [],
    String deliveryId = '',
  }) async {
    staffSheets.add({
      'sheet': sheet,
      'sheetId': sheetId,
      'sheetName': sheetName,
      'ownerTag': ownerTag,
      'senderRole': senderRole,
      'targetAudience': targetAudience,
      'fromMaster': fromMaster,
      'masterParty': masterParty,
      'campaignId': campaignId,
      'campaignName': campaignName,
      'allowClearFields': allowClearFields,
    });
  }

  final joins = <Map<String, dynamic>>[];
  @override
  Future<void> refreshPresence() async {}
  @override
  Future<void> sendInitiativeTurnAdjusted({
    required String senderRole,
    required String campaignId,
    required String campaignName,
    required String sheetTag,
    required int turn,
    String encounterId = '',
    bool joinEncounter = false,
    bool leaveEncounter = false,
  }) async {
    joins.add({
      'sheetTag': sheetTag,
      'encounterId': encounterId,
      'campaignId': campaignId,
      'joinEncounter': joinEncounter,
    });
  }

  @override
  Future<bool> sendSharedSheetConfirmed({
    required Map<String, dynamic> sheet,
    required String campaignId,
    required String campaignName,
    required String sheetId,
    required String sheetName,
    required String ownerTag,
    required String senderRole,
    required String targetAudience,
    required bool fromMaster,
    required bool masterParty,
    List<String> targetTags = const [],
    List<String> allowClearFields = const [],
    String deliveryId = '',
  }) async {
    await sendSharedSheet(
      sheet: sheet,
      campaignId: campaignId,
      campaignName: campaignName,
      sheetId: sheetId,
      sheetName: sheetName,
      ownerTag: ownerTag,
      senderRole: senderRole,
      targetAudience: targetAudience,
      fromMaster: fromMaster,
      masterParty: masterParty,
      targetTags: targetTags,
      allowClearFields: allowClearFields,
      deliveryId: deliveryId,
    );
    return true;
  }

  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async => true;
}

void main() {
  testWidgets(
    'attack requests validate sender, log once, and cannot reopen resolved damage',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final directory = Directory('build/combat-delivery-test')
        ..createSync(recursive: true);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => directory.absolute.path,
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
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && !state.datiCaricati; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      state.schedePersonaggio.clear();
      state.schedePersonaggio.addAll(<Map<String, dynamic>>[
        {'id': '001-ROSE', 'sheetTag': '001-ROSE', 'nome': 'Rose'},
        {
          'id': '002-ENEMY',
          'sheetTag': '002-ENEMY',
          'nome': 'Slime',
          'realtimeSharedSheet': true,
        },
      ]);
      state.schedaCorrente = 0;
      state.modalitaMaster = false;
      state.sonoCoMaster = false;
      state.tutorialCompletato = true;
      state.realtimeService = _CombatService();
      state.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
        'encounterId': 'fight',
        'tokens': [
          {'id': '001-ROSE', 'name': 'Rose'},
          {'id': '002-ENEMY', 'name': 'Slime'},
        ],
      };
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'enemy-session',
          'activeSheetTag': '002-ENEMY',
          'role': 'player',
        },
      ];
      final probe = OculumPerformanceProbe(state);
      final packet = <String, dynamic>{
        'id': 'attack-one',
        'scope': probe.permissionScope,
        'campaignId': state.activeCampaignId,
        'encounterId': 'fight',
        'sessionId': 'enemy-session',
        'senderTag': '002-ENEMY',
        'senderRole': 'player',
        'sourceTag': '002-ENEMY',
        'sourceName': 'Slime',
        'targetTag': '001-ROSE',
        'choice': 'vc',
        'attack': 12,
        'damage': 30,
      };
      probe.receiveCombat('combat_attack', {...packet, 'sessionId': 'forged'});
      expect(state.onlineCombatRequests, isEmpty);
      probe.receiveCombat('combat_attack', {
        ...packet,
        'targetTag': 'OUTSIDE_FIGHT',
      });
      expect(state.onlineCombatRequests, isEmpty);
      probe.receiveCombat('combat_attack', packet);
      expect(state.onlineCombatRequests.length, 1);
      final before = (state.logEventi as List)
          .where((e) => '$e'.contains('[DIFESA RICHIESTA ·'))
          .length;
      probe.receiveCombat('combat_attack', packet);
      expect(
        (state.logEventi as List)
            .where((e) => '$e'.contains('[DIFESA RICHIESTA ·'))
            .length,
        before,
      );
      expect(before, 1);
      // Switching the attacker's sheet must not invalidate a packet already
      // in flight, nor must a late source token hide the defender's request.
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'enemy-session',
          'activeSheetTag': 'ANOTHER_OWNED_SHEET',
          'localSheetTags': ['002-ENEMY', 'ANOTHER_OWNED_SHEET'],
          'role': 'player',
        },
      ];
      final readyTokens = state.realtimeVisibleInitiativeSnapshot['tokens'];
      state.realtimeVisibleInitiativeSnapshot['tokens'] = [
        {'id': '001-ROSE', 'name': 'Rose'},
      ];
      probe.receiveCombat('combat_attack', {...packet, 'id': 'during-switch'});
      expect(state.onlineCombatRequests['during-switch']['received'], isTrue);
      probe.receiveCombat('combat_attack', {
        ...packet,
        'id': 'unowned-source',
        'senderTag': 'UNOWNED',
        'sourceTag': 'UNOWNED',
      });
      expect(state.onlineCombatRequests.containsKey('unowned-source'), isFalse);
      state.realtimeVisibleInitiativeSnapshot['tokens'] = readyTokens;
      state.schedePersonaggio.add(<String, dynamic>{
        'id': '003-TARGET',
        'sheetTag': '003-TARGET',
        'nome': 'Compagno osservato',
        'livello': 12,
        'grado': 3,
        'materia': 10,
        'derivedCM': 35,
        'hiddenEyeStats': [
          {'id': 'velo', 'valore': 0, 'unlocked': true},
        ],
      });
      state.realtimeVisibleInitiativeSnapshot['tokens'] = [
        ...(readyTokens as List),
        {'id': '003-TARGET', 'name': 'Compagno osservato'},
      ];
      // Reading an owned participant resolves even while another sheet is
      // open. The reply publishes only the information earned by the roll.
      for (final reading in [
        (29, 'exact', 12),
        (26, 'approximate', 9),
        (23, 'insufficient', null),
      ]) {
        final scoutId = 'scout-${reading.$2}';
        probe.receiveCombat('combat_scout', {
          ...packet,
          'id': scoutId,
          'kind': 'scout',
          'targetTag': '003-TARGET',
          'targetName': 'Compagno osservato',
          'scoutPhase': 'request',
          'natural': 15,
          'total': reading.$1,
        });
        final reply = state.onlineCombatRequests[scoutId];
        expect(reply['scoutPhase'], 'result');
        expect(reply['reveal'], reading.$2);
        expect(reply['level'], reading.$3);
        if (reading.$2 == 'insufficient') {
          expect(reply.containsKey('cm'), isFalse);
          expect(reply.containsKey('grade'), isFalse);
        } else {
          expect(reply['grade'], 3);
        }
      }
      final Map request = state.onlineCombatRequests['attack-one'];
      state.onlineCombatRequests['outgoing'] = <String, dynamic>{
        ...packet,
        'id': 'outgoing',
        'sourceTag': '001-ROSE',
        'targetTag': '002-ENEMY',
        'status': 'pending',
      };
      probe.receiveCombat('unsupported_event', {
        ...packet,
        'id': 'outgoing',
        'sourceTag': '001-ROSE',
        'targetTag': '002-ENEMY',
        'defense': 30,
      });
      expect(state.onlineCombatRequests['outgoing']['status'], 'pending');
      state.onlineCombatRequests.remove('outgoing');
      request['status'] = 'resolved';
      probe.receiveCombat('combat_attack', packet);
      expect(state.onlineCombatRequests['attack-one']['status'], 'resolved');
      probe.receiveCombat('combat_attack', {
        ...packet,
        'id': 'invalid-alternative',
        'choice': 'forza',
        'reason': '',
      });
      expect(
        state.onlineCombatRequests.containsKey('invalid-alternative'),
        isTrue,
      );
      probe.receiveCombat('combat_attack', {
        ...packet,
        'id': 'fake-counter',
        'forcedCritical': true,
        'reactionOf': 'missing',
      });
      expect(state.onlineCombatRequests.containsKey('fake-counter'), isFalse);
      probe.receiveCombat('combat_attack', {
        ...packet,
        'id': 'fake-ordinary-counter',
        'forcedCritical': false,
        'reactionOf': 'missing',
      });
      expect(
        state.onlineCombatRequests.containsKey('fake-ordinary-counter'),
        isFalse,
      );
      state.modalitaMaster = true;
      state.isMasterHost = true;
      probe.ensureEncounters();
      state.masterInitiativePublished = false;
      state.masterInitiativeRound = 3;
      state.masterInitiativeActiveIndex = 0;
      state.masterInitiativeTokens.clear();
      state.masterInitiativeTokens.addAll(<Map<String, dynamic>>[
        {
          'id': 'first',
          'name': 'Primo',
          'status': 'active',
          'currentHp': 30,
          'maxHp': 100,
          'imageBase64': 'x' * 1200000,
        },
        {'id': 'second', 'name': 'Secondo', 'status': 'ready'},
      ]);
      probe.syncMasterTurnOrder();
      expect(
        state.masterInitiativePublished,
        isTrue,
        reason:
            'Online fights publish automatically without the manual Publish button',
      );
      final automaticallyShared =
          (state.realtimeService as _CombatService).turnSnapshots.last;
      expect((automaticallyShared['tokens'] as List).length, 2);
      expect(
        (automaticallyShared['tokens'] as List).first['healthLabel'],
        'Morente',
      );
      expect(
        (automaticallyShared['tokens'] as List).first.containsKey('currentHp'),
        isFalse,
        reason: 'The shared label must not disclose hidden numeric HP',
      );
      expect(
        '$automaticallyShared'.length,
        lessThan(1000000),
        reason:
            'Full portraits must not make the turn snapshot exceed the RPC limit',
      );
      await probe.requestPlayerSheets();
      expect((state.realtimeService as _CombatService).sheetRequests, 1);
      expect('${state.risultato}', contains('Richiesta schede consegnata'));
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'co-session',
          'activeSheetTag': '002-ENEMY',
          'role': 'coMaster',
        },
      ];
      final control = <String, dynamic>{
        'id': 'initiative:test-control',
        'scope': probe.permissionScope,
        'campaignId': state.activeCampaignId,
        'encounterId': state.selectedMasterInitiativeGroupId,
        'expectedRound': 3,
        'expectedActiveTag': 'first',
        'sessionId': 'co-session',
        'senderTag': '002-ENEMY',
        'senderRole': 'coMaster',
        'delta': 1,
      };
      probe.receiveEncounterControl({...control, 'sessionId': 'forged'});
      expect(state.masterInitiativeActiveIndex, 0);
      probe.receiveEncounterControl(control);
      expect(state.masterInitiativeActiveIndex, 1);
      probe.receiveEncounterControl(control);
      expect(
        state.masterInitiativeActiveIndex,
        1,
        reason: 'A repeated control must not advance twice',
      );
      probe.receiveEncounterControl({
        ...control,
        'id': 'initiative:stale-control',
      });
      expect(
        state.masterInitiativeActiveIndex,
        1,
        reason: 'A stale view must not change a later turn',
      );
      final transport = state.realtimeService as _CombatService;
      state.masterInitiativeTokens.addAll(<Map<String, dynamic>>[
        {'id': '001-ROSE', 'sheetTag': '001-ROSE', 'name': 'Rose'},
        {'id': '002-ENEMY', 'sheetTag': '002-ENEMY', 'name': 'Slime'},
      ]);
      state.realtimeSharedSheets.addAll(<Map<String, dynamic>>[
        {
          'sheetId': '002-ENEMY',
          'ownerTag': '002-ENEMY',
          'senderRole': 'player',
          'campaignId': 'campaign-local-to-player',
          'sheet': {
            'id': '002-ENEMY',
            'sheetTag': '002-ENEMY',
            'nome': 'Slime',
            'immaginePersonaggioBase64': 'shared-portrait',
          },
        },
        {
          'sheetId': '004-OUTSIDE',
          'ownerTag': '004-OUTSIDE',
          'senderRole': 'player',
          'campaignId': 'campaign-local-to-player',
          'sheet': {'id': '004-OUTSIDE', 'sheetTag': '004-OUTSIDE'},
        },
      ]);
      probe.shareStaffTurnOrderSheets();
      expect(
        probe.encounterPortrait({'id': '002-enemy'}),
        'shared-portrait',
        reason: 'Compact turn snapshots reuse the separately shared portrait',
      );
      final initialRelays = transport.staffSheets.length;
      probe.shareStaffTurnOrderSheets();
      expect(
        transport.staffSheets.length,
        initialRelays,
        reason:
            'Unchanged participant sheets are not retransmitted on every Presence refresh',
      );
      expect(
        transport.staffSheets.map((sheet) => sheet['sheetId']),
        containsAll(['001-ROSE', '002-ENEMY']),
      );
      expect(
        transport.staffSheets.any((sheet) => sheet['sheetId'] == '004-OUTSIDE'),
        isFalse,
        reason: 'Only participants are relayed to staff turn-order views.',
      );
      final relayed = transport.staffSheets.firstWhere(
        (sheet) => sheet['sheetId'] == '002-ENEMY',
      );
      state.modalitaMaster = false;
      state.isMasterHost = false;
      state.sonoCoMaster = false;
      expect(probe.receiveStaffSheet(relayed), isFalse);
      state.sonoCoMaster = true;
      expect(probe.receiveStaffSheet(relayed), isTrue);
      expect(probe.ownedPresenceTags(), isNot(contains('002-ENEMY')));
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'role': 'master',
          'sessionId': 'other-device-of-master',
          'campaignId': 'other-local-campaign',
        },
        {
          'role': 'master',
          'sessionId': 'master-session',
          'campaignId': state.activeCampaignId,
        },
      ];
      final snapshot = <String, dynamic>{
        'senderRole': 'master',
        'sessionId': 'master-session',
        'revision': 2,
        'campaignId': state.activeCampaignId,
        'snapshot': {
          'campaignId': state.activeCampaignId,
          'encounters': [
            {
              'encounterId': 'authoritative',
              'round': 4,
              'activeIndex': 0,
              'tokens': [
                {'id': '001-ROSE', 'reportedTurn': 0},
              ],
            },
          ],
        },
      };
      probe.receiveInitiative(snapshot);
      expect(state.realtimeVisibleInitiativeSnapshot['round'], 4);
      expect(
        probe.permissionScope,
        endsWith(':${state.activeCampaignId}'),
        reason:
            'Turn and action permissions follow the publishing Master session',
      );
      probe.receiveInitiative({
        ...snapshot,
        'revision': 1,
        'closed': true,
        'snapshot': null,
      });
      expect(
        state.realtimeVisibleInitiativeSnapshot['round'],
        4,
        reason: 'An old close packet must not replace a newer Master snapshot.',
      );
      probe.receiveInitiative({
        ...snapshot,
        'revision': 3,
        'sessionId': 'stranger',
        'closed': true,
        'snapshot': null,
      });
      expect(
        state.realtimeVisibleInitiativeSnapshot['round'],
        4,
        reason: 'Only the room Master session controls online initiative.',
      );
      state.sonoCoMaster = false;
      state.schedePersonaggio.add(<String, dynamic>{
        'id': '003-ALLY',
        'sheetTag': '003-ALLY',
        'nome': 'Ally',
      });
      final transportForJoin = state.realtimeService as _CombatService;
      transportForJoin.staffSheets.clear();
      await probe.syncOwnedStaffSheets();
      final beforeRequest = transportForJoin.staffSheets.length;
      await probe.sendCurrentSheet();
      expect(transportForJoin.staffSheets.length, greaterThan(beforeRequest));
      expect('${state.risultato}', contains('Attendo la conferma'));
      final beforeMasterRequest = transportForJoin.staffSheets.length;
      probe.receiveRealtime('sheet_ping', {
        'requestSharedSheets': true,
        'senderRole': 'master',
        'sessionId': 'master-session',
        'sentAt': 'manual-request',
      });
      await tester.pump();
      expect(
        transportForJoin.staffSheets.length,
        greaterThan(beforeMasterRequest),
        reason:
            'A Master request retries even when the previous peer ACK is still pending',
      );
      expect(
        transportForJoin.staffSheets.map((s) => s['sheetId']),
        isNot(contains('003-ALLY')),
      );
      expect(
        transportForJoin.staffSheets.map((s) => s['sheetId']),
        isNot(contains('002-ENEMY')),
      );
      state.schedaCorrente = state.schedePersonaggio.length - 1;
      probe.load(
        Map<String, dynamic>.from(state.schedePersonaggio.last as Map),
      );
      await probe.joinMasterEncounter({
        'encounterId': 'join-test',
        'campaignId': state.activeCampaignId,
        'name': 'Fight',
      });
      expect(transportForJoin.joins.last['sheetTag'], '003-ALLY');
      final initialJoins = transportForJoin.joins.length;
      await probe.retryEncounterJoins();
      expect(transportForJoin.joins.length, initialJoins + 1);
      probe.receiveInitiative({
        ...snapshot,
        'revision': 4,
        'snapshot': {
          'campaignId': state.activeCampaignId,
          'encounters': [
            {
              'encounterId': 'join-test',
              'tokens': [
                {'sheetTag': '003-ALLY', 'id': '003-ALLY'},
              ],
            },
          ],
        },
      });
      await tester.pump();
      await probe.retryEncounterJoins();
      expect(state.realtimeOutgoingEncounterJoins, isEmpty);
      expect(transportForJoin.joins.length, initialJoins + 1);
      // A Master edit may arrive after an unrelated autosave advanced the
      // owner's local wall clock. Database sequence, not that clock, orders it.
      state.realtimeService = _CombatService();
      state.modalitaMaster = false;
      state.sonoCoMaster = false;
      state.schedaCorrente = 0;
      probe.load(Map<String, dynamic>.from(state.schedePersonaggio[0] as Map));
      state.schedePersonaggio[0]['localUpdatedAt'] = '2099-01-01T00:00:00Z';
      final edit = <String, dynamic>{
        'senderRole': 'sheetEdit',
        'authenticatedRole': 'master',
        'serverSequence': 100,
        'sheetId': probe.ownerTag(),
        'ownerTag': probe.ownerTag(),
        'targetTags': [probe.ownerTag()],
        'sentAt': '2026-01-01T00:00:00Z',
        'sheet': {'currentHp': '11'},
      };
      expect(probe.receiveStaffSheet(edit), isTrue);
      expect(probe.currentHp(), 11);
      expect(state.schedePersonaggio[0]['realtimeOwnerEditSequence'], 100);
      state.currentHpController.text = '22';
      expect(probe.receiveStaffSheet(edit), isFalse);
      expect(probe.receiveStaffSheet({...edit, 'serverSequence': 99}), isFalse);
      expect(probe.currentHp(), 22, reason: 'A replay cannot restore old HP');
      expect(
        probe.receiveStaffSheet({
          ...edit,
          'serverSequence': 101,
          'sheet': {'currentHp': '13'},
        }),
        isTrue,
      );
      expect(probe.currentHp(), 13);
      expect(
        probe.receiveStaffSheet({
          ...edit,
          'serverSequence': 99,
          'sheet': {'scudo': '7', 'currentHp': '90'},
        }),
        isTrue,
        reason: 'An older shield edit must not be lost to a newer HP edit',
      );
      expect(state.scudoController.text, '7');
      expect(
        probe.currentHp(),
        13,
        reason: 'Only the older HP field is rejected',
      );
      expect(state.schedePersonaggio[0]['realtimeOwnerEditSequence'], 101);
      expect(
        probe.receiveStaffSheet({
          ...edit,
          'serverSequence': 102,
          'sheet': {'currentHp': '13'},
        }),
        isTrue,
        reason: 'An unchanged authoritative value still advances its revision',
      );
      expect(
        probe.receiveStaffSheet({
          ...edit,
          'serverSequence': 101,
          'sheet': {'currentHp': '90'},
        }),
        isFalse,
      );
      expect(probe.currentHp(), 13);
      state.schedePersonaggio[0]['localUpdatedAt'] = '2099-01-01T00:00:00Z';
      expect(
        probe.receiveStaffSheet({
          ...edit,
          'authenticatedRole': 'player',
          'serverSequence': 200,
        }),
        isFalse,
        reason: 'A claimed role cannot bypass the local guard',
      );
      state.realtimeService = null;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
