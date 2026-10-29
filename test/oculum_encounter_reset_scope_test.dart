import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _ResetTransport extends OculumRealtimeService {
  _ResetTransport({String role = 'master'})
    : super(
        roomId: 'reset-scope',
        playerName: 'Master',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = role;
  }
  @override
  bool get isConnected => true;
  @override
  Future<bool> sendPermissionEvent(
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

void _prepareBoards(dynamic state, OculumPerformanceProbe p) {
  // Both simulated roles belong to the same established campaign. Without
  // this, the Player captures an empty campaign ID and requestMasterAction
  // then creates another scope before the fixture switches to Master.
  state.activeCampaignId = 'reset_scope_campaign';
  state.masterInitiativeRound = 7;
  state.masterInitiativePublished = true;
  p.recordCurrentEncounter();
  // ensureEncounters already creates encounter_2; replace that fixture board
  // instead of adding a duplicate that the real selector cannot distinguish.
  state.masterInitiativeGroups.removeWhere(
    (group) => group['id'] == 'encounter_2',
  );
  state.masterInitiativeGroups.add(<String, dynamic>{
    'id': 'encounter_2',
    'name': 'Seconda Fight',
    'round': 11,
    'activeIndex': 0,
    'published': true,
    'fightStarted': true,
    'tokens': <Map<String, dynamic>>[
      {
        'id': 'OTHER',
        'sheetTag': 'OTHER',
        'name': 'Altro',
        'side': 'party',
        'status': 'active',
      },
    ],
  });
}

void main() {
  testWidgets(
    'approving a reset after changing boards resets only the requested fight',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _prepareBoards(state, p);
      final transport = _ResetTransport(role: 'player');
      state.realtimeService = transport;
      state.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
        'encounterId': 'encounter_1',
        'campaignId': state.activeCampaignId,
        'tokens': [
          {'id': p.ownerTag(), 'sheetTag': p.ownerTag()},
        ],
      };
      p.requestAction('encounter_reset', 'Reset prima Fight');
      final request = Map<String, dynamic>.from(
        state.onlinePermissionRequests.values.single as Map,
      );
      expect(request['encounterId'], 'encounter_1');
      expect(state.masterInitiativeRound, 7);
      transport.authenticatedRole = 'master';
      p.selectEncounter('encounter_2');
      expect(state.masterInitiativeRound, 11);
      expect(request['scope'], p.permissionScope);
      await p.decideRequest(request, true);
      expect(state.selectedMasterInitiativeGroupId, 'encounter_2');
      expect(state.masterInitiativeRound, 11);
      final first = (state.masterInitiativeGroups as List).singleWhere(
        (g) => g['id'] == 'encounter_1',
      );
      expect(first['round'], 0);
      expect(
        state.onlinePermissionRequests[request['id']]['status'],
        'approved',
      );
      // Repeating an already answered decision cannot reset the selected board.
      await p.decideRequest(request, true);
      expect(state.masterInitiativeRound, 11);
      state.realtimeService = null;
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'legacy reset binds to its unique party board and cannot name another fight',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _prepareBoards(state, p);
      state.realtimeService = _ResetTransport();
      state.realtimeUsers.add(<String, dynamic>{
        'sessionId': 'player-session',
        'role': 'player',
        'localSheetTags': [p.ownerTag()],
      });
      Map<String, dynamic> packet(String id) => {
        'id': id,
        'action': 'encounter_reset',
        'scope': p.permissionScope,
        'campaignId': p.permissionCampaignId,
        'sheetTag': p.ownerTag(),
        'requesterTag': p.ownerTag(),
        'requesterName': 'Eroe',
        'senderTag': p.ownerTag(),
        'senderRole': 'player',
        'sessionId': 'player-session',
        'createdAt': '2026-10-29T12:00:00',
        'description': 'Reset richiesto',
      };
      p.receivePermission('permission_request', {
        ...packet('wrong-fight'),
        'encounterId': 'encounter_2',
      });
      expect(state.onlinePermissionRequests.containsKey('wrong-fight'), false);
      p.receivePermission('permission_request', packet('legacy-reset'));
      final request =
          state.onlinePermissionRequests['legacy-reset']
              as Map<String, dynamic>;
      expect(request['encounterId'], 'encounter_1');
      p.selectEncounter('encounter_2');
      await p.decideRequest(request, true);
      expect(state.masterInitiativeRound, 11);
      expect(
        (state.masterInitiativeGroups as List).singleWhere(
          (g) => g['id'] == 'encounter_1',
        )['round'],
        0,
      );
      state.realtimeService = null;
      await closeFixture(tester, p);
    },
  );
}
