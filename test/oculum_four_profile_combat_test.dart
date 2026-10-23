import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';

class _ProfileTransport extends OculumRealtimeService {
  _ProfileTransport(this.profile, this.bus)
    : super(
        roomId: 'four-isolated',
        playerName: 'Profile $profile',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = profile == 0 ? 'master' : 'player';
  }
  final int profile;
  final _ProfileBus bus;
  final sentPermissions = <String>[];
  @override
  bool get isConnected => true;
  @override
  String get channelName => 'four-isolated';
  @override
  Future<bool> sendPermissionEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    sentPermissions.add(event);
    // Duplicate delivery deliberately exercises the production idempotency guard.
    for (var copy = 0; copy < 2; copy++) {
      for (var index = 0; index < bus.probes.length; index++) {
        if (index == profile) continue;
        bus.probes[index].receivePermission(event, {
          ...payload,
          'sessionId': 'profile-$profile',
        });
      }
    }
    return true;
  }

  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    for (var copy = 0; copy < 2; copy++) {
      for (var index = 0; index < bus.probes.length; index++) {
        if (index == profile) continue;
        bus.probes[index].receiveCombat(event, {
          ...payload,
          'sessionId': 'profile-$profile',
        });
      }
    }
    return true;
  }

  @override
  Future<void> sendInitiativeSnapshot({
    required Map<String, dynamic> snapshot,
    required String campaignId,
    required String campaignName,
    required bool closed,
  }) async {
    final copy = jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>;
    for (final dynamic state in bus.states) {
      state.realtimeVisibleInitiativeSnapshot = Map<String, dynamic>.from(copy);
    }
  }
}

class _ProfileBus {
  final probes = <OculumPerformanceProbe>[];
  final states = <dynamic>[];
}

void main() {
  testWidgets(
    'four isolated profiles spend actions without approval and mirror combat resources once per delivery',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => Directory('build/four-profile-isolation').absolute.path,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (_) async => ['none'],
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
        (_) async => null,
      );
      final keys = List.generate(4, (_) => GlobalKey());
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              for (var i = 0; i < 4; i++)
                Offstage(
                  offstage: i != 0,
                  child: OculumHomePage(key: keys[i]),
                ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      debugPrint('Four application states mounted');
      final states = keys.map((key) => key.currentState as dynamic).toList();
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(seconds: 1)),
      );
      final bus = _ProfileBus();
      final tags = [
        'MasterOcu:3690FD5G',
        'AttaccoOcu:3690FD5G',
        'DifesaOcu:3690FD5G',
        'AiutoOcu:413FD5G',
      ];
      final transports = List.generate(4, (i) => _ProfileTransport(i, bus));
      final tokens = [
        for (var i = 0; i < 4; i++)
          <String, dynamic>{
            'id': tags[i],
            'sheetTag': tags[i],
            'name': 'Profile $i',
            'side': i == 2 ? 'enemy' : 'ally',
            'status': 'ready',
            'currentHp': 1000,
            'maxHp': 1000,
            'reactionMax': 1,
            'reactionUsed': 0,
            'reactionFastMax': 0,
            'actionUsed': false,
          },
      ];
      Map<String, dynamic> clone(Map<String, dynamic> map) =>
          Map<String, dynamic>.from(jsonDecode(jsonEncode(map)) as Map);
      for (var i = 0; i < 4; i++) {
        final dynamic state = states[i];
        state.datiCaricati = false;
        state.saveBlobDirectoryFuture = Future<Directory>.value(
          Directory('build/four-profile-isolation/profile-$i')
            ..createSync(recursive: true),
        );
        state.tutorialCompletato = true;
        state.tutorialDialogPending = true;
        state.modalitaMaster = i == 0;
        state.isMasterHost = i == 0;
        state.activeCampaignId = 'four-campaign';
        state.realtimeService = transports[i];
        state.schedePersonaggio.clear();
        state.schedePersonaggio.addAll([
          for (var j = 0; j < 4; j++)
            {
              'id': tags[j],
              'sheetTag': tags[j],
              'nome': 'Profile $j',
              'realtimeSharedSheet': j != i,
            },
        ]);
        state.schedaCorrente = i;
        state.currentHpController.text = '1000';
        state.resilienzaController.text = '100';
        state.currentResilienzaController.text = '100';
        state.currentMateriaController.text = '0';
        state.materiaController.text = '0';
        state.skills.clear();
        state.arti.clear();
        state.titoli.clear();
        state.trattiRazziali.clear();
        state.inventario.clear();
        state.activeStructuredEffects.clear();
        state.activeConditions.clear();
        state.pawnGuardians.clear();
        state.realtimeUsers = [
          for (var j = 0; j < 4; j++)
            {
              'sessionId': 'profile-$j',
              'role': j == 0 ? 'master' : 'player',
              'localSheetTags': [tags[j]],
              'activeSheetTag': tags[j],
              'campaignId': 'four-campaign',
            },
        ];
        final probe = OculumPerformanceProbe(state);
        probe.ensureEncounters();
        state.selectedMasterInitiativeGroupId = 'encounter_1';
        state.masterInitiativePublished = i == 0;
        state.masterInitiativeTokens.clear();
        state.masterInitiativeTokens.addAll(tokens.map(clone));
        state.masterInitiativeActiveIndex = 1;
        state.realtimeVisibleInitiativeSnapshot = {
          'encounterId': 'encounter_1',
          'campaignId': 'four-campaign',
          'activeIndex': 1,
          'tokens': tokens.map(clone).toList(),
        };
        bus.probes.add(probe);
        bus.states.add(state);
      }
      for (final probe in bus.probes) {
        expect(probe.permissionScope, bus.probes.first.permissionScope);
      }
      debugPrint('Four isolated profiles configured');
      var spendSequence = 0;
      Future<bool> spend(int profile) async =>
          await tester.runAsync(() async {
            final allowed = await bus.probes[profile].spendCombatRoll();
            if (allowed) {
              final packet = bus.probes[profile].turnResourceTestPacket(
                'turn-resource-${spendSequence++}',
              );
              await transports[profile].sendCombatEvent('combat_help', packet);
            }
            return allowed;
          }) ??
          false;
      Future<bool> spendResource(int profile, String resource) async =>
          await tester.runAsync(() async {
            final allowed = await bus.probes[profile].utilitySpend(resource);
            if (allowed) {
              final packet = bus.probes[profile].turnResourceTestPacket(
                'turn-resource-${spendSequence++}',
              );
              await transports[profile].sendCombatEvent('combat_help', packet);
            }
            return allowed;
          }) ??
          false;
      final dynamic master = states[0];
      expect(bus.probes[0].canUseInitiativeAction(3), isFalse);
      bus.probes[0].toggleInitiativeAction(3);
      expect(master.masterInitiativeTokens[3]['actionUsed'], isFalse);
      expect(master.masterInitiativeActiveIndex, 1);
      // A's action advances to B; A's next attack uses its quick reaction.
      expect(await spend(1), isTrue);
      expect(master.masterInitiativeTokens[1]['actionUsed'], isTrue);
      expect(master.masterInitiativeActiveIndex, 2);
      expect(
        states.every(
          (dynamic state) =>
              state.realtimeVisibleInitiativeSnapshot['activeIndex'] == 2,
        ),
        isTrue,
      );
      expect(master.masterInitiativeTokens[1]['reactionUsed'], 0);
      expect(await spend(1), isTrue);
      expect(master.masterInitiativeTokens[1]['reactionUsed'], 0);
      expect(master.masterInitiativeTokens[1]['reactionFastUsed'], 1);
      expect(master.masterInitiativeActiveIndex, 2);
      expect(await spend(1), isFalse);
      // C helps A outside C's turn and spends its quick reaction. B can use
      // both its quick reaction and its action during its own turn.
      expect(await spend(3), isTrue);
      expect(master.masterInitiativeTokens[3]['reactionUsed'], 0);
      expect(master.masterInitiativeTokens[3]['reactionFastUsed'], 1);
      expect(await spendResource(2, 'reazione'), isTrue);
      expect(master.masterInitiativeActiveIndex, 2);
      expect(master.masterInitiativeTokens[2]['actionUsed'], isFalse);
      expect(master.masterInitiativeTokens[2]['reactionUsed'], 0);
      expect(master.masterInitiativeTokens[2]['reactionFastUsed'], 1);
      expect(
        transports.every((transport) => transport.sentPermissions.isEmpty),
        isTrue,
      );
      final help = {
        'id': 'four-help',
        'kind': 'help',
        'helpBonus': 4,
        'status': 'pending',
        'scope': bus.probes[3].permissionScope,
        'campaignId': 'four-campaign',
        'encounterId': 'encounter_1',
        'sourceTag': tags[3],
        'senderTag': tags[3],
        'sourceName': 'Helper',
        'targetTag': tags[1],
        'senderRole': 'player',
      };
      await transports[3].sendCombatEvent('combat_help', help);
      expect(states[1].schedePersonaggio[1]['combatHelpPending'], 4);
      // B uses its own-turn action after the reaction without advancing early.
      expect(await spend(2), isTrue);
      expect(master.masterInitiativeTokens[2]['actionUsed'], isTrue);
      expect(master.masterInitiativeActiveIndex, 3);
      final attack = {
        'id': 'four-attack',
        'scope': bus.probes[1].permissionScope,
        'campaignId': 'four-campaign',
        'encounterId': 'encounter_1',
        'sourceTag': tags[1],
        'senderTag': tags[1],
        'sourceName': 'Attacker',
        'targetTag': tags[2],
        'senderRole': 'player',
        'attack': 15,
        'damage': 20,
        'choice': 'vc',
        'status': 'pending',
      };
      await transports[1].sendCombatEvent('combat_attack', attack);
      final dynamic request = states[2].onlineCombatRequests['four-attack'];
      expect(request, isNotNull);
      await bus.probes[2].resolveCombatDefense(
        Map<String, dynamic>.from(request),
        'cm',
        20,
      );
      // Resolve using the canonical stored object; a detached copy must be rejected.
      expect(request['status'], 'pending');
      await bus.probes[2].resolveCombatDefense(
        request as Map<String, dynamic>,
        'cm',
        20,
      );
      expect(request['status'], 'resolved');
      expect(bus.probes[2].currentHp(), 1000);
      expect(master.masterInitiativeTokens[2]['reactionUsed'], 0);
      expect(master.masterInitiativeTokens[2]['reactionFastUsed'], 1);
      // B's action advances to C; C can use an action after its quick reaction.
      expect(await spend(3), isTrue);
      expect(master.masterInitiativeTokens[3]['actionUsed'], isTrue);
      for (var i = 0; i < 4; i++) {
        expect(states[i].schedePersonaggio[i]['realtimeSharedSheet'], isFalse);
        bus.probes[i].cancelPendingSave();
        states[i].realtimeService = null;
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
