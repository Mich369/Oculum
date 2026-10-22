import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

class _ControlTransport extends OculumRealtimeService {
  _ControlTransport()
    : super(
        roomId: 'control-test',
        playerName: 'Controllore',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      );
  @override
  bool get isConnected => true;
  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async => true;
  @override
  Future<void> refreshPresence() async {}
}

void main() {
  test('Redirection preserves the number and multiplicity of attack hits', () {
    expect(oculumRedirectAttackHits(['a', 'b', 'a'], ['c', 'd']), [
      'c',
      'd',
      'c',
    ]);
    expect(oculumRedirectAttackHits(['a', 'a', 'a'], ['c']), ['c', 'c', 'c']);
    expect(oculumRedirectAttackHits(['a', 'b'], ['c', 'c']), isEmpty);
  });
  testWidgets(
    'Only the corruptor can redirect an attack to valid distinct living targets',
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
        'id': 'ControllerOcu:3690FD5G',
        'sheetTag': 'ControllerOcu:3690FD5G',
        'nome': 'Controllore',
      });
      state.schedaCorrente = 0;
      final owner = probe.currentTag();
      state.schedePersonaggio.add(<String, dynamic>{
        'id': 'monster',
        'sheetTag': 'monster',
        'realtimeSharedSheet': true,
        'conditions': [],
      });
      expect(
        probe.corruptor({'id': 'monster', 'corruptedByTag': owner}),
        owner,
      );
      expect(
        probe.corruptionControlChance({
          'id': 'monster',
          'targetControlChancePercent': 65,
        }),
        65,
      );
      state.realtimeService = _ControlTransport();
      state.realtimeVisibleInitiativeSnapshot = {
        'campaignId': state.activeCampaignId,
        'encounterId': 'fight',
        'tokens': [
          {'id': owner, 'status': 'ready'},
          {'id': 'monster', 'status': 'ready', 'corruptedByTag': owner},
          {'id': 'living', 'status': 'ready'},
          {'id': 'dead', 'status': 'dead'},
        ],
      };
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'monster-session',
          'activeSheetTag': 'monster',
          'role': 'master',
        },
        {
          'sessionId': 'owner-session',
          'activeSheetTag': owner,
          'role': 'player',
        },
        {
          'sessionId': 'other-session',
          'activeSheetTag': 'living',
          'role': 'player',
        },
      ];
      final request = <String, dynamic>{
        'id': 'redirect',
        'sourceTag': 'monster',
        'sourceName': 'Mostro Corrotto',
        'targetTag': owner,
        'targetCount': 1,
        'scope': probe.permissionScope,
        'campaignId': state.activeCampaignId,
        'encounterId': 'fight',
        'sessionId': 'monster-session',
        'senderTag': 'monster',
        'senderRole': 'master',
      };
      probe.receiveCombat('corruption_target', {
        ...request,
        'targetTag': 'living',
      });
      expect(state.onlineCombatRequests, isEmpty);
      probe.receiveCombat('corruption_target', request);
      expect(state.onlineCombatRequests['redirect']['status'], 'pending');
      final completer = Completer<List<String>>();
      state.corruptionTargetChoices['redirect'] = completer;
      final choice = {
        ...request,
        'phase': 'choice',
        'sessionId': 'owner-session',
        'senderRole': 'player',
        'senderTag': owner,
      };
      probe.receiveCombat('corruption_target', {
        ...choice,
        'selectedTargets': ['dead'],
      });
      expect(completer.isCompleted, isFalse);
      probe.receiveCombat('corruption_target', {
        ...choice,
        'selectedTargets': ['monster'],
      });
      expect(completer.isCompleted, isFalse);
      probe.receiveCombat('corruption_target', {
        ...choice,
        'sessionId': 'other-session',
        'senderTag': 'living',
        'selectedTargets': ['living'],
      });
      expect(completer.isCompleted, isFalse);
      probe.receiveCombat('corruption_target', {
        ...choice,
        'selectedTargets': ['living', 'living'],
      });
      expect(completer.isCompleted, isFalse);
      probe.receiveCombat('corruption_target', {
        ...choice,
        'selectedTargets': ['living'],
      });
      expect(completer.isCompleted, isTrue);
      expect(await completer.future, ['living']);
      probe.receiveCombat('corruption_target', {
        ...choice,
        'selectedTargets': [owner],
      });
      expect(state.onlineCombatRequests['redirect']['selectedTargets'], [
        'living',
      ]);
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
