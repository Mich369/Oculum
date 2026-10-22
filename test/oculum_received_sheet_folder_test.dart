import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

class _RetryTransport extends OculumRealtimeService {
  _RetryTransport()
    : super(
        roomId: 'retry-online',
        playerName: 'Difensore',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      );

  @override
  bool get isConnected => true;

  final permissionEvents = <String>[];
  final sentSheets = <Map<String, dynamic>>[];
  final receivedAcks = <Map<String, dynamic>>[];

  @override
  Future<void> refreshPresence() async {}

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
    List<String> targetTags = const <String>[],
    List<String> allowClearFields = const <String>[],
    String deliveryId = '',
  }) async {
    sentSheets.add({
      'sheet': Map<String, dynamic>.from(sheet),
      'campaignId': campaignId,
      'campaignName': campaignName,
      'sheetId': sheetId,
      'sheetName': sheetName,
      'ownerTag': ownerTag,
      'senderRole': senderRole,
      'targetAudience': targetAudience,
      'fromMaster': fromMaster,
      'masterParty': masterParty,
      'targetTags': targetTags,
      'deliveryId': deliveryId,
      'sentAt': DateTime.now().toIso8601String(),
    });
    return true;
  }

  @override
  Future<void> sendSheetReceivedAck({
    required String deliveryId,
    required String ownerTag,
    required String sheetId,
    required String sheetName,
    required String campaignId,
    required String campaignName,
    required String receiverRole,
    required String receiverTag,
  }) async {
    receivedAcks.add({
      'deliveryId': deliveryId,
      'ownerTag': ownerTag,
      'sheetId': sheetId,
      'sheetName': sheetName,
      'campaignId': campaignId,
      'campaignName': campaignName,
      'receiverRole': receiverRole,
      'receiverTag': receiverTag,
    });
  }

  @override
  Future<bool> sendPermissionEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    permissionEvents.add(event);
    return true;
  }
}

void main() {
  testWidgets(
    'selected player sheet reaches Master without a second approval',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.modalitaMaster = false;
      state.isMasterHost = false;
      state.schedePersonaggio.clear();
      state.schedePersonaggio.add(<String, dynamic>{
        'id': 'PlayerOcu:3690FD5G',
        'sheetTag': 'PlayerOcu:3690FD5G',
        'nome': 'Viandante',
        'monsterBookSourceId': 'catalog-entry',
        'monsterBookApprovalRequired': true,
        'monsterBookApproved': false,
      });
      state.schedaCorrente = 0;
      state.nomeController.text = 'Viandante';
      state.realtimeNameController.text = 'Account Player';
      final transport = _RetryTransport();
      state.realtimeService = transport;

      await probe.sendCurrentSheet();

      expect(transport.sentSheets, hasLength(1));
      final sent = transport.sentSheets.single;
      expect(sent['senderRole'], 'player');
      expect(sent['targetAudience'], 'master_coMaster');
      expect(sent['sheetId'], 'PlayerOcu:3690FD5G');
      expect(
        (sent['sheet'] as Map<String, dynamic>)['publicAccountDisplayName'],
        'Account Player',
      );
      expect(transport.permissionEvents, isEmpty);

      // Switch this isolated profile into the receiving Master role and apply
      // the exact packet emitted by the player transport.
      state.modalitaMaster = true;
      state.isMasterHost = true;
      transport.authenticatedRole = 'master';
      state.schedePersonaggio.clear();
      expect(probe.receiveStaffSheet(sent), isTrue);
      expect(state.schedePersonaggio, hasLength(1));
      expect(state.sheetSidebarFolders.last['name'], 'Online');
      final receivedTag = state.schedePersonaggio.single['sheetTag'];
      final folderId = state.sheetSidebarFolders.last['id'];
      expect(state.sheetSidebarPlacements[receivedTag]['folder'], folderId);
      expect(transport.receivedAcks.single['receiverRole'], 'master');

      final renamed = Map<String, dynamic>.from(sent);
      final renamedSheet = Map<String, dynamic>.from(sent['sheet'] as Map)
        ..['publicAccountDisplayName'] = 'Account Aggiornato'
        ..['publicVisibleTitleName'] = 'Titolo Aggiornato';
      renamed['sheet'] = renamedSheet;
      renamed['sentAt'] = DateTime.now()
          .add(const Duration(seconds: 1))
          .toIso8601String();
      expect(probe.receiveStaffSheet(renamed), isTrue);
      expect(state.schedePersonaggio, hasLength(1));
      expect(state.schedePersonaggio.single['sheetTag'], receivedTag);
      expect(
        state.schedePersonaggio.single['realtimeOwnerName'],
        'Account Aggiornato',
      );

      probe.cancelPendingSave();
      state.realtimeService = null;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'one defensive retry consumes one Master fast reaction and no HP',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.modalitaMaster = true;
      state.isMasterHost = true;
      if (state.schedePersonaggio.isEmpty) {
        state.schedePersonaggio.add(<String, dynamic>{
          'id': 'DifensoreOcu:3690FD5G',
          'sheetTag': 'DifensoreOcu:3690FD5G',
          'nome': 'Difensore',
        });
        state.schedaCorrente = 0;
      }
      final tag = probe.ownerTag();
      probe.ensureEncounters();
      final encounter = '${state.selectedMasterInitiativeGroupId}';
      state.masterInitiativeTokens.clear();
      final token = <String, dynamic>{
        'id': tag,
        'sheetTag': tag,
        'name': 'Difensore',
        'status': 'ready',
        'currentHp': 100,
        'maxHp': 100,
        'reactionMax': 1,
        'reactionUsed': 0,
        'reactionFastMax': 0,
      };
      state.masterInitiativeTokens.add(token);
      final request = <String, dynamic>{
        'id': 'retry-attack',
        'targetTag': tag,
        'sourceTag': 'enemy',
        'scope': probe.permissionScope,
        'encounterId': encounter,
        'status': 'pending',
        'firstDefense': 5,
      };
      state.onlineCombatRequests['retry-attack'] = request;
      final hp = probe.currentHp();
      await probe.requestDefenseRetry(request);
      expect(token['reactionFastUsed'], 1);
      expect(request['defenseRetryApproved'], isTrue);
      expect(probe.currentHp(), hp);
      await probe.requestDefenseRetry(request);
      expect(token['reactionFastUsed'], 1);
      expect(request['status'], 'pending');
      token['reactionFastUsed'] = 0;
      expect(await probe.utilitySpend('reazione'), isTrue);
      expect(token['reactionFastUsed'], 1);
      expect(await probe.utilitySpend('reazione'), isFalse);
      expect(token['reactionFastUsed'], 1);
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
  testWidgets('player retries one failed defense without Master approval', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 900),
    );
    final probe = OculumPerformanceProbe(state);
    state.datiCaricati = false;
    state.modalitaMaster = false;
    state.isMasterHost = false;
    if (state.schedePersonaggio.isEmpty) {
      state.schedePersonaggio.add(<String, dynamic>{
        'id': 'DifensoreOcu:3690FD5G',
        'sheetTag': 'DifensoreOcu:3690FD5G',
        'nome': 'Difensore',
      });
      state.schedaCorrente = 0;
    }
    final tag = probe.ownerTag();
    probe.ensureEncounters();
    final transport = _RetryTransport();
    state.realtimeService = transport;
    final encounter = '${state.selectedMasterInitiativeGroupId}';
    state.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
      'encounterId': encounter,
      'campaignId': state.activeCampaignId,
      'round': 1,
      'activeIndex': 0,
      'tokens': <Map<String, dynamic>>[
        {
          'id': tag,
          'sheetTag': tag,
          'name': 'Difensore',
          'status': 'ready',
          'currentHp': 100,
          'maxHp': 100,
          'actionUsed': false,
          'reactionMax': 2,
          'reactionUsed': 0,
          'reactionFastMax': 0,
        },
      ],
    };
    final request = <String, dynamic>{
      'id': 'player-retry-attack',
      'targetTag': tag,
      'sourceTag': 'enemy',
      'scope': probe.permissionScope,
      'encounterId': encounter,
      'status': 'pending',
      'firstDefense': 5,
    };
    state.onlineCombatRequests['player-retry-attack'] = request;
    final hp = probe.currentHp();

    expect(await probe.spendCombatRoll(), isTrue);
    final token = state.realtimeVisibleInitiativeSnapshot['tokens'].single;
    expect(token['actionUsed'], isTrue);
    await probe.requestDefenseRetry(request);
    expect(token['reactionFastUsed'], 1);
    expect(request['defenseRetryApproved'], isTrue);
    expect(probe.currentHp(), hp);
    await probe.requestDefenseRetry(request);
    expect(token['reactionFastUsed'], 1);
    expect(transport.permissionEvents, isEmpty);

    probe.cancelPendingSave();
    state.realtimeService = null;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
  testWidgets(
    'same-tag sheets from different players stay separate in the Online folder',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.modalitaMaster = true;
      state.isMasterHost = true;
      final before = state.schedePersonaggio.length as int;
      Map<String, dynamic> packet(
        String account,
        String title,
        int hp,
        int second,
      ) => {
        'senderRole': 'player',
        'authenticatedUserId': account == 'Account Uno'
            ? 'auth-account-one'
            : 'auth-account-two',
        'sheetId': 'ViandanteOcu:3690FD5G',
        'ownerTag': 'ViandanteOcu:3690FD5G',
        'campaignId': 'player-campaign',
        'sentAt': '2026-10-21T10:00:0$second.000Z',
        'sheetName': 'Viandante',
        'playerName': account,
        'sheet': {
          'id': 'ViandanteOcu:3690FD5G',
          'sheetTag': 'ViandanteOcu:3690FD5G',
          'nome': 'Viandante',
          'currentHp': '$hp',
          'immaginePersonaggioBase64': 'retained-portrait',
          'publicAccountDisplayName': account,
          'publicVisibleTitleName': title,
        },
      };
      expect(
        probe.receiveStaffSheet(packet('Account Uno', 'Primo', 100, 1)),
        isTrue,
      );
      expect(state.schedePersonaggio.length, before + 1);
      final firstIndex = state.schedePersonaggio.length - 1;
      final firstLocalTag = state.schedePersonaggio[firstIndex]['sheetTag'];
      final folderId = state.sheetSidebarFolders.last['id'];
      expect(state.sheetSidebarFolders.last['name'], 'Online');
      expect(state.sheetSidebarPlacements[firstLocalTag]['folder'], folderId);
      expect(
        probe.receiveStaffSheet(packet('Account Due', 'Secondo', 75, 2)),
        isTrue,
      );
      expect(state.schedePersonaggio.length, before + 2);
      final secondIndex = state.schedePersonaggio.length - 1;
      final secondLocalTag = state.schedePersonaggio[secondIndex]['sheetTag'];
      expect(secondLocalTag, isNot(firstLocalTag));
      expect(state.schedePersonaggio[firstIndex]['currentHp'], '100');
      expect(state.schedePersonaggio[secondIndex]['currentHp'], '75');
      expect(state.sheetSidebarPlacements[secondLocalTag]['folder'], folderId);
      final compact = packet('Account Due', 'Secondo', 65, 3);
      final compactSheet = compact['sheet'] as Map<String, dynamic>;
      compactSheet['immaginePersonaggioBase64'] = '';
      compactSheet['realtimePortraitReference'] =
          oculumRealtimeSheetContentSignature({
            'portrait': 'retained-portrait',
          });
      expect(probe.receiveStaffSheet(compact), isTrue);
      expect(
        state.schedePersonaggio[secondIndex]['immaginePersonaggioBase64'],
        'retained-portrait',
      );
      expect(state.schedePersonaggio[secondIndex]['currentHp'], '65');
      expect(
        state.schedePersonaggio[secondIndex]['realtimeOwnerName'],
        'Account Due',
      );
      expect(
        state.sheetSidebarFolders
            .where((dynamic f) => f['id'] == folderId)
            .length,
        1,
      );
      expect(
        probe.receiveStaffSheet(packet('Account Uno', 'Primo', 100, 1)),
        isFalse,
      );
      expect(state.schedePersonaggio[firstIndex]['currentHp'], '100');
      expect(state.schedePersonaggio[secondIndex]['currentHp'], '65');
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
