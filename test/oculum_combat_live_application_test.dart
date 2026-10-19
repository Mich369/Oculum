import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _runLive = bool.fromEnvironment('OculumLiveRealtimeTest');

class _LiveNetwork extends HttpOverrides {}

void main() {
  testWidgets(
    'real authenticated transport applies defense, damage, healing and signed help to the player',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final directory = Directory('build/live-combat-verification')
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
      final probe = OculumPerformanceProbe(state);
      await tester.runAsync(() async {
        state.saveBlobDirectoryFuture = Future<Directory>.value(directory);
        state.sharedPreferencesFuture = Future<SharedPreferences>.value(
          await SharedPreferences.getInstance(),
        );
        await probe.reloadSave();
      });
      expect(state.datiCaricati, isTrue);
      state.datiCaricati =
          false; // Do not write synthetic combat to user saves.
      state.schedePersonaggio.clear();
      state.schedePersonaggio.addAll(<Map<String, dynamic>>[
        {'id': 'LIVE_PLAYER', 'sheetTag': 'LIVE_PLAYER', 'nome': 'Player'},
        {
          'id': 'LIVE_MASTER',
          'sheetTag': 'LIVE_MASTER',
          'nome': 'Master',
          'realtimeSharedSheet': true,
        },
      ]);
      state.schedaCorrente = 0;
      state.modalitaMaster = false;
      state.isMasterHost = false;
      state.sonoCoMaster = false;
      state.tutorialCompletato = true;
      state.titoli.clear();
      state.trattiRazziali.clear();
      state.skills.clear();
      state.arti.clear();
      state.inventario.clear();
      state.pawnGuardians.clear();
      state.activeConditions.clear();
      state.activeStructuredEffects.clear();
      state.resilienzaController.text = '100';
      state.currentResilienzaController.text = '100';
      state.materiaController.text = '0';
      state.currentMateriaController.text = '0';
      state.volontaController.text = '0';
      state.currentVolontaController.text = '0';
      state.oculumController.text = '0';
      state.currentOculumController.text = '0';
      state.currentHpController.text = '1000';
      state.scudoOculumMaxController.text = '10';
      state.scudoOculumController.text = '10';
      state.scudoController.text = '20';
      state.hpTempController.text = '20';
      state.scudoSalvataggioAttivo = false;
      state.incomingDamagePresets.clear();
      state.modificatoreDannoSelezionato = 'Normale';
      for (final dynamic stat in state.hiddenEyeStats) {
        stat.valore = stat.id == 'resistenza' ? -50 : 0;
        if (stat.id == 'fortuna') stat.unlocked = false;
      }
      probe.invalidateDerivedCaches();
      final playerTag = probe.ownerTag();
      state.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
        'encounterId': 'live-fight',
        'tokens': [
          {'id': playerTag},
          {'id': 'LIVE_MASTER'},
        ],
      };
      final room = 'combat_${DateTime.now().microsecondsSinceEpoch}';
      late SupabaseClient masterClient;
      late SupabaseClient playerClient;
      await tester.runAsync(() async {
        masterClient = HttpOverrides.runWithHttpOverrides(
          () => SupabaseClient(
            oculumConfiguredSupabaseUrl,
            oculumConfiguredSupabasePublishableKey,
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
          _LiveNetwork(),
        );
        playerClient = HttpOverrides.runWithHttpOverrides(
          () => SupabaseClient(
            oculumConfiguredSupabaseUrl,
            oculumConfiguredSupabasePublishableKey,
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
          _LiveNetwork(),
        );
      });
      var clientsClosed = false;
      Future<void> closeClients() async {
        if (clientsClosed) return;
        clientsClosed = true;
        await playerClient.dispose();
        await masterClient.dispose();
      }

      final oldAvailable = OculumRealtimeService.supabaseAvailable;
      OculumRealtimeService.supabaseAvailable = true;
      final receipts = <Map<String, dynamic>>[];
      final master = OculumRealtimeService(
        client: masterClient,
        roomId: room,
        playerName: 'Synthetic Master',
        presenceDataProvider: () => {
          'role': 'master',
          'activeSheetTag': 'LIVE_MASTER',
          'localSheetTags': ['LIVE_MASTER'],
          'campaignId': state.activeCampaignId,
        },
        onAccessRequested: (_, _) async => true,
        onPresenceChanged: (_) {},
        onStatusChanged: (s) => debugPrint('Master: $s'),
        onEvent: (event, payload) {
          if (event == 'combat_defense') receipts.add(payload);
        },
      );
      final player = OculumRealtimeService(
        client: playerClient,
        roomId: room,
        playerName: 'Synthetic Player',
        presenceDataProvider: () => {
          'role': 'player',
          'activeSheetTag': playerTag,
          'localSheetTags': [playerTag],
          'campaignId': state.activeCampaignId,
        },
        onPresenceChanged: (users) => state.realtimeUsers = users,
        onStatusChanged: (s) => debugPrint('Player: $s'),
        onEvent: (event, payload) {
          if (event.startsWith('combat_')) probe.receiveCombat(event, payload);
        },
      );
      state.realtimeService = player;
      addTearDown(() async {
        await player.dispose();
        await master.dispose();
        await closeClients();
        OculumRealtimeService.supabaseAvailable = oldAvailable;
      });
      Future<void> waitFor(bool Function() done) async {
        final deadline = DateTime.now().add(const Duration(seconds: 25));
        while (!done()) {
          if (DateTime.now().isAfter(deadline)) {
            throw TimeoutException('Expected combat delivery did not arrive');
          }
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }

      await tester.runAsync(
        () => HttpOverrides.runWithHttpOverrides(() async {
          await master.connect();
          await player.connect();
          expect(master.isConnected, isTrue);
          expect(player.isConnected, isTrue);
          await waitFor(
            () => (state.realtimeUsers as List).any(
              (dynamic p) => p['activeSheetTag'] == 'LIVE_MASTER',
            ),
          );
          final packet = <String, dynamic>{
            'id': 'live-damage',
            'scope': probe.permissionScope,
            'campaignId': state.activeCampaignId,
            'encounterId': 'live-fight',
            'senderTag': 'LIVE_MASTER',
            'sourceTag': 'LIVE_MASTER',
            'sourceName': 'Master',
            'targetTag': playerTag,
            'choice': 'vc',
            'attack': 18,
            'damage': probe.defense() + 100,
            'level': 0,
            'difficulty': 'normale',
            'element': 'fisico',
          };
          expect(await master.sendCombatEvent('combat_attack', packet), isTrue);
          await waitFor(
            () =>
                state.onlineCombatRequests['live-damage']?['received'] == true,
          );
          expect(
            (state.logEventi as List).join('\n'),
            contains('[DIFESA RICHIESTA]'),
          );
          final request =
              state.onlineCombatRequests['live-damage'] as Map<String, dynamic>;
          await probe.resolveCombatDefense(request, 'cm', 10);
          expect(request['outcome'], 'full');
          expect(state.scudoOculumController.text, '0');
          expect(state.scudoController.text, '0');
          expect(state.hpTempController.text, '0');
          expect(probe.currentHp(), 950);
          await waitFor(() => receipts.isNotEmpty);
          expect((receipts.last['damageReceipt'] as Map)['hpLost'], 50);
          await probe.resolveCombatDefense(request, 'cm', 10);
          expect(
            probe.currentHp(),
            950,
            reason: 'Duplicate defense must not repeat damage',
          );
          final support = <String, dynamic>{
            ...packet,
            'id': 'live-help',
            'kind': 'help',
            'helpBonus': -3,
            'targetName': 'Player',
          };
          expect(await master.sendCombatEvent('combat_help', support), isTrue);
          await waitFor(
            () => state.schedePersonaggio[0]['combatHelpPending'] == -3,
          );
          expect(probe.consumeHelp(), -3);
          expect(probe.consumeHelp(), 0);
          final healing = <String, dynamic>{
            ...support,
            'id': 'live-heal',
            'helpMode': 'effects',
            'effects': [
              OculumStructuredEffect(
                id: 'live-heal-effect',
                type: 'cura',
                resource: 'vita',
                valueExpression: '10',
                duration: '0',
                recipient: 'se_stesso',
              ).toJson(),
            ],
          };
          expect(await master.sendCombatEvent('combat_help', healing), isTrue);
          await waitFor(
            () => state.onlineCombatRequests['live-heal']?['received'] == true,
          );
          expect(probe.currentHp(), 960);
          await master.sendCombatEvent('combat_help', healing);
          await Future<void>.delayed(const Duration(seconds: 1));
          expect(
            probe.currentHp(),
            960,
            reason: 'Duplicate support must not heal twice',
          );
          await player.dispose();
          await master.dispose();
          await closeClients();
        }, _LiveNetwork()),
      );
      state.realtimeService = null;
      state.realtimeAutoReconnectEnabled = false;
      state.autosaveTimer?.cancel();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
    skip: !_runLive,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
