import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

/// A connected authoritative Master transport with an in-memory outbox.
/// Production sender paths run; no live room, HTTP or database is used.
class _ConnectedMaster extends OculumRealtimeService {
  _ConnectedMaster()
    : super(
        roomId: 'private-creator-fixture',
        playerName: 'Master',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = 'master';
  }
  @override
  bool get isConnected => true;
  final snapshots = <Map<String, dynamic>>[];
  final sheets = <Map<String, dynamic>>[];
  @override
  Future<void> sendInitiativeSnapshot({
    required Map<String, dynamic> snapshot,
    required String campaignId,
    required String campaignName,
    required bool closed,
  }) async {
    snapshots.add(jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>);
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
    sheets.add({
      'id': sheetId,
      'audience': targetAudience,
      'sheet': jsonDecode(jsonEncode(sheet)),
    });
    return true;
  }
}

void main() {
  for (final alreadyPublished in [false, true]) {
    testWidgets(
      'connected creator stays private with existing published encounter=$alreadyPublished',
      (tester) async {
        final (state, probe) = await mountFight(tester);
        state.masterInitiativePublished = alreadyPublished;
        probe.recordCurrentEncounter();
        final source = probe.snapshot();
        const secret = 'SecretOcu:3690FC03';
        state.schedePersonaggio.add({
          ...source,
          'id': secret,
          'sheetTag': secret,
          'nome': 'Secret monster QA',
          'inMasterParty': false,
          'masterSideOverride': 'enemy',
        });
        final transport = _ConnectedMaster();
        state.realtimeService = transport;
        state.realtimeUsers.add(<String, dynamic>{
          'role': 'coMaster',
          'sessionId': 'fixture-comaster',
        });
        expect(probe.fightCreatorAllowed, true);
        expect(probe.prepareFightCreator(assignments: {secret: 'enemy'}), true);
        final group = state.masterInitiativeGroups.last as Map;
        expect(
          group['published'],
          false,
          reason: 'A connected Creator must not auto-publish',
        );
        expect(transport.snapshots, isEmpty);
        expect(transport.sheets, isEmpty);

        // Campaign serialization and the production reconnect reset must not
        // remove the private designation. Another published fight may resend,
        // but it must never contain the draft's identity or new creature.
        final campaign =
            jsonDecode(jsonEncode(probe.campaignSnapshot()))
                as Map<String, dynamic>;
        probe.loadCampaign(campaign);
        state.realtimeHiddenEncounterIds.clear();
        state.realtimeLastSentSheetHashes.clear();
        final reconnected = _ConnectedMaster();
        state.realtimeService = reconnected;
        probe.autoPublishTurnOrder();
        probe.sendMasterPartyForTest();
        probe.resendTurnOrderForTest();
        expect(state.masterInitiativeGroups.last['published'], false);
        expect(
          jsonEncode(probe.initiativeSnapshot()),
          isNot(contains('Secret monster QA')),
        );
        expect(jsonEncode(reconnected.snapshots), isNot(contains(secret)));
        expect(
          reconnected.sheets.where((sheet) => sheet['id'] == secret),
          isEmpty,
        );

        // Explicit publication is the only transition for the private draft.
        reconnected.snapshots.clear();
        reconnected.sheets.clear();
        probe.publishTurnOrder();
        expect(state.masterInitiativePublished, true);
        expect(jsonEncode(reconnected.snapshots), contains(secret));
        expect(
          reconnected.sheets.where((sheet) => sheet['id'] == secret),
          isNotEmpty,
        );
        state.realtimeService = null;
        await closeFixture(tester, probe);
      },
    );
  }

  testWidgets('ordinary encounter auto-publication remains available', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final transport = _ConnectedMaster();
    state.realtimeService = transport;
    probe.addOrdinaryEncounterForTest();
    probe.addInitiativeSheetForTest(0);
    expect(state.masterInitiativePublished, true);
    expect(transport.snapshots, isNotEmpty);
    state.realtimeService = null;
    await closeFixture(tester, probe);
  });

  testWidgets(
    'newly generated private sheet is protected before assignment to a draft',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final transport = _ConnectedMaster();
      state.realtimeService = transport;
      state.realtimeUsers.add(<String, dynamic>{
        'role': 'coMaster',
        'sessionId': 'fixture-comaster',
      });
      await probe.createPrivateSheetForTest();
      final tag = probe.ownerTag();
      expect(state.schedePersonaggio.last['masterOnlyDraft'], true);
      probe.sendMasterPartyForTest();
      expect(transport.sheets.where((sheet) => sheet['id'] == tag), isEmpty);
      state.realtimeService = null;
      await closeFixture(tester, probe);
    },
  );
}
