import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

const _ownerUid = 'google-owner';
const _pcSession = 'master-pc';
const _phoneSession = 'master-phone';
const _pcCampaign = 'pc-campaign';
const _phoneCampaign = 'phone-campaign';
const _encounter = 'encounter_1';
const _turnTag = 'ACTIVE';

class _MasterDevice extends OculumRealtimeService {
  _MasterDevice(this.roomSessionId)
    : super(
        roomId: 'dual-master',
        playerName: 'Master',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = 'master';
  }

  @override
  final String roomSessionId;

  @override
  String get authenticatedUserId => _ownerUid;

  @override
  bool get isConnected => true;

  final commands = <(String, Map<String, dynamic>)>[];

  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    commands.add((
      event,
      {
        ...payload,
        'sessionId': roomSessionId,
        'authenticatedUserId': authenticatedUserId,
        'authenticatedRole': authenticatedRole,
      },
    ));
    return true;
  }

  @override
  Future<void> sendInitiativeSnapshot({
    required Map<String, dynamic> snapshot,
    required String campaignId,
    required String campaignName,
    required bool closed,
  }) async {}
}

Map<String, dynamic> _presence(
  String session,
  String claim,
  String campaign,
  String tag,
) => {
  'role': 'master',
  'userId': _ownerUid,
  'sessionId': session,
  'masterClaimId': claim,
  'campaignId': campaign,
  'activeSheetTag': tag,
  'localSheetTags': [tag],
};

void _publishFixture(dynamic state, OculumPerformanceProbe probe) {
  state.masterInitiativeTokens.first['id'] = _turnTag;
  state.masterInitiativeTokens.first['sheetTag'] = _turnTag;
  state.masterInitiativeRound = 4;
  state.masterInitiativeActiveIndex = 0;
  state.masterInitiativePublished = true;
  probe.recordCurrentEncounter();
}

void main() {
  testWidgets('a second Master device can step the same account Fight once', (
    tester,
  ) async {
    final (phoneState, phone) = await mountFight(tester);
    final phoneTransport = _MasterDevice(_phoneSession);
    final phoneTag = phone.ownerTag();
    final phonePresence = _presence(
      _phoneSession,
      'master_2_phone',
      _phoneCampaign,
      phoneTag,
    );
    final pcPresence = _presence(
      _pcSession,
      'master_1_pc',
      _pcCampaign,
      _turnTag,
    );
    phoneState.realtimeService = phoneTransport;
    phoneState.activeCampaignId = _phoneCampaign;
    phoneState.realtimeMasterClaimId = 'master_2_phone';
    phoneState.realtimeUsers = <Map<String, dynamic>>[
      phonePresence,
      pcPresence,
    ];
    _publishFixture(phoneState, phone);
    phone.reconcileRealtimeMasterControl();
    expect(phone.realtimeLocalRole, 'master');
    expect(phone.realtimeUsesSameAccountMaster, isTrue);

    final snapshot = <String, dynamic>{
      'senderRole': 'master',
      'authenticatedRole': 'master',
      'authenticatedUserId': _ownerUid,
      'sessionId': _pcSession,
      'revision': 1,
      'serverSequence': 10,
      'campaignId': _pcCampaign,
      'snapshot': {
        'campaignId': _pcCampaign,
        'encounterId': _encounter,
        'round': 4,
        'activeIndex': 0,
        'tokens': [
          {'id': _turnTag, 'name': 'Eroe', 'status': 'active'},
          {'id': 'ENEMY', 'name': 'Nemico', 'status': 'ready'},
        ],
      },
    };
    phone.receiveInitiative({
      ...snapshot,
      'authenticatedUserId': 'another-owner',
      'serverSequence': 20,
    });
    phone.receiveInitiative({
      ...snapshot,
      'authenticatedRole': 'player',
      'serverSequence': 21,
    });
    await phone.requestVisibleEncounterStep(1);
    expect(phoneTransport.commands, isEmpty);

    phone.receiveInitiative(snapshot);
    expect(phone.permissionCampaignId, _pcCampaign);
    await phone.requestVisibleEncounterStep(1);
    final (event, packet) = phoneTransport.commands.single;
    expect(event, 'initiative_control');
    expect(packet['scope'], '${phoneTransport.normalizedRoomId}:$_pcCampaign');
    expect(packet['campaignId'], _pcCampaign);
    expect(packet['masterControlSession'], _pcSession);
    expect(packet['senderRole'], 'master');
    expect(packet['encounterId'], _encounter);
    expect(packet['expectedRound'], 4);
    expect(packet['expectedActiveTag'], _turnTag);
    phone.receiveEncounterControl(packet);
    expect(phoneState.masterInitiativeActiveIndex, 0);
    expect(phoneState.onlineCombatRequests.containsKey(packet['id']), isFalse);

    phoneState.realtimeUsers = <Map<String, dynamic>>[phonePresence];
    phone.reconcileRealtimeMasterControl();
    await phone.requestVisibleEncounterStep(1);
    expect(phoneTransport.commands, hasLength(1));

    const returningPc = 'master-pc-new-session';
    phoneState.realtimeUsers = <Map<String, dynamic>>[
      phonePresence,
      _presence(returningPc, 'master_3_pc', _pcCampaign, _turnTag),
    ];
    phone.reconcileRealtimeMasterControl();
    await phone.requestVisibleEncounterStep(1);
    expect(phoneTransport.commands, hasLength(1));
    phone.receiveInitiative({
      ...snapshot,
      'sessionId': returningPc,
      'serverSequence': 11,
    });
    await phone.requestVisibleEncounterStep(1);
    expect(phoneTransport.commands, hasLength(2));
    expect(
      phoneTransport.commands.last.$2['masterControlSession'],
      returningPc,
    );

    phoneState.realtimeService = null;
    await closeFixture(tester, phone);

    final (pcState, pc) = await mountFight(tester);
    pcState.realtimeService = _MasterDevice(_pcSession);
    pcState.activeCampaignId = _pcCampaign;
    pcState.realtimeMasterClaimId = 'master_1_pc';
    pcState.realtimeUsers = <Map<String, dynamic>>[phonePresence, pcPresence];
    _publishFixture(pcState, pc);
    pc.reconcileRealtimeMasterControl();
    expect(pc.realtimeLocalRole, 'master');
    expect(pc.realtimeUsesSameAccountMaster, isFalse);

    pc.receiveEncounterControl({
      ...packet,
      'authenticatedUserId': 'another-owner',
    });
    pc.receiveEncounterControl({...packet, 'campaignId': _phoneCampaign});
    expect(pcState.masterInitiativeActiveIndex, 0);
    expect(pcState.onlineCombatRequests.containsKey(packet['id']), isFalse);

    pc.receiveEncounterControl(packet);
    expect(pcState.masterInitiativeActiveIndex, 1);
    expect(pcState.onlineCombatRequests.containsKey(packet['id']), isTrue);
    pc.receiveEncounterControl(packet);
    expect(pcState.masterInitiativeActiveIndex, 1);
    pcState.realtimeService = null;
    await closeFixture(tester, pc);
  });
}
