import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CombatService extends OculumRealtimeService {
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
        {'id': 'ROSE', 'sheetTag': 'ROSE', 'nome': 'Rose'},
        {
          'id': 'ENEMY',
          'sheetTag': 'ENEMY',
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
          {'id': 'ROSE', 'name': 'Rose'},
          {'id': 'ENEMY', 'name': 'Slime'},
        ],
      };
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'enemy-session',
          'activeSheetTag': 'ENEMY',
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
        'senderTag': 'ENEMY',
        'senderRole': 'player',
        'sourceTag': 'ENEMY',
        'sourceName': 'Slime',
        'targetTag': 'ROSE',
        'choice': 'vc',
        'attack': 12,
        'damage': 30,
      };
      probe.receiveCombat('combat_attack', {...packet, 'sessionId': 'forged'});
      expect(state.onlineCombatRequests, isEmpty);
      probe.receiveCombat('combat_attack', packet);
      expect(state.onlineCombatRequests.length, 1);
      final before = (state.logEventi as List)
          .where((e) => '$e'.contains('[DIFESA RICHIESTA]'))
          .length;
      probe.receiveCombat('combat_attack', packet);
      expect(
        (state.logEventi as List)
            .where((e) => '$e'.contains('[DIFESA RICHIESTA]'))
            .length,
        before,
      );
      expect(before, 1);
      final Map request = state.onlineCombatRequests['attack-one'];
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
        isFalse,
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
      state.realtimeService = null;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
