import 'dart:async';
import 'dart:convert';
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
    'four authenticated clients share combat and confirmed idempotent party rest',
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
      const playerAppKey = ValueKey('authenticated-player-app');
      const masterAppKey = ValueKey('authenticated-master-app');
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Stack(
            fit: StackFit.expand,
            children: [
              OculumHomePage(key: playerAppKey),
              Offstage(child: OculumHomePage(key: masterAppKey)),
            ],
          ),
        ),
      );
      final dynamic state = tester.state(find.byKey(playerAppKey));
      final dynamic masterState = tester.state(
        find.byKey(masterAppKey, skipOffstage: false),
      );
      state.tutorialDialogPending = true;
      masterState.tutorialDialogPending = true;
      final probe = OculumPerformanceProbe(state);
      final masterProbe = OculumPerformanceProbe(masterState);
      await tester.runAsync(() async {
        state.saveBlobDirectoryFuture = Future<Directory>.value(directory);
        state.sharedPreferencesFuture = Future<SharedPreferences>.value(
          await SharedPreferences.getInstance(),
        );
        await probe.reloadSave();
        masterState.saveBlobDirectoryFuture = Future<Directory>.value(
          directory,
        );
        masterState.sharedPreferencesFuture = Future<SharedPreferences>.value(
          await SharedPreferences.getInstance(),
        );
        await masterProbe.reloadSave();
      });
      expect(state.datiCaricati, isTrue);
      expect(masterState.datiCaricati, isTrue);
      masterState.datiCaricati = false;
      state.datiCaricati =
          false; // Do not write synthetic combat to user saves.
      state.schedePersonaggio.clear();
      state.schedePersonaggio.addAll(<Map<String, dynamic>>[
        {
          'id': 'LIVE_PLAYER',
          'sheetTag': 'LIVE_PLAYER',
          'nome': 'Player',
          'livello': '0',
          'grado': '0',
        },
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
      state.livelloController.text = '0';
      state.gradoController.text = '0';
      state.resilienzaController.text = '100';
      state.currentResilienzaController.text = '100';
      state.materiaController.text = '0';
      state.currentMateriaController.text = '0';
      state.volontaController.text = '0';
      state.currentVolontaController.text = '0';
      state.oculumController.text = '0';
      state.currentOculumController.text = '0';
      state.currentHpController.text = '600';
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
      expect(
        probe.maximumHp(),
        600,
        reason: 'Level 0 / Grade 0 gives 6 HP per Resilience point.',
      );
      expect(probe.currentHp(), 600);
      final playerTag = probe.ownerTag();
      final masterSheet =
          jsonDecode(jsonEncode(probe.snapshot())) as Map<String, dynamic>;
      masterSheet.addAll(<String, dynamic>{
        'id': 'LIVE_MASTER',
        'sheetTag': 'LIVE_MASTER',
        'nome': 'Master',
        'realtimeSharedSheet': false,
      });
      masterState.schedePersonaggio
        ..clear()
        ..add(masterSheet);
      masterState.schedaCorrente = 0;
      masterProbe.load(masterSheet);
      final masterTag = masterProbe.ownerTag().toUpperCase();
      expect(masterTag, isNotEmpty);
      masterState.activeCampaignId = state.activeCampaignId;
      masterState.modalitaMaster = true;
      masterState.isMasterHost = true;
      masterState.sonoCoMaster = false;
      state.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
        'encounterId': 'live-fight',
        'tokens': [
          {'id': playerTag},
          {'id': masterTag},
          {'id': 'Live_Attacker'},
        ],
      };
      final room = 'combat_${DateTime.now().microsecondsSinceEpoch}';
      late SupabaseClient masterClient;
      late SupabaseClient playerClient;
      late SupabaseClient attackerClient;
      late SupabaseClient helperClient;
      await tester.runAsync(() async {
        helperClient = HttpOverrides.runWithHttpOverrides(
          () => SupabaseClient(
            oculumConfiguredSupabaseUrl,
            oculumConfiguredSupabasePublishableKey,
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
          _LiveNetwork(),
        );
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
        attackerClient = HttpOverrides.runWithHttpOverrides(
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
        await attackerClient.dispose();
        await helperClient.dispose();
        await masterClient.dispose();
      }

      final oldAvailable = OculumRealtimeService.supabaseAvailable;
      OculumRealtimeService.supabaseAvailable = true;
      final receipts = <Map<String, dynamic>>[];
      bool? masterPatchApplied;
      Map<String, dynamic>? attackerInitiative;
      final attackerReceipts = <Map<String, dynamic>>[];
      Map<String, dynamic>? helperInitiative;
      final masterRestRequests = <Map<String, dynamic>>[];
      final playerRestSnapshots = <Map<String, dynamic>>[];
      final attackerRestSnapshots = <Map<String, dynamic>>[];
      final helperRestSnapshots = <Map<String, dynamic>>[];
      bool containsGrant(Map<String, dynamic> payload, String id) =>
          ((payload['worldClockSnapshot'] as Map?)?['restGrants'] as List? ??
                  [])
              .whereType<Map>()
              .any((row) => row['id'] == id && row['status'] == 'confirmed');
      final helper = OculumRealtimeService(
        client: helperClient,
        roomId: room,
        playerName: 'Synthetic Companion',
        presenceDataProvider: () => {
          'role': 'player',
          'activeSheetTag': 'Live_Helper',
          'localSheetTags': ['Live_Helper'],
          'campaignId': state.activeCampaignId,
        },
        onPresenceChanged: (_) {},
        onStatusChanged: (s) => debugPrint('Companion: $s'),
        onEvent: (event, payload) {
          if (event == 'initiative_shared') helperInitiative = payload;
          if (event == 'initiative_control' &&
              payload['worldClockSnapshot'] is Map) {
            helperRestSnapshots.add(payload);
          }
        },
      );
      final attacker = OculumRealtimeService(
        client: attackerClient,
        roomId: room,
        playerName: 'Synthetic Attacker',
        httpPollingOnly: true,
        presenceDataProvider: () => {
          'role': 'player',
          'activeSheetTag': 'Live_Attacker',
          'localSheetTags': ['Live_Attacker'],
          'campaignId': state.activeCampaignId,
        },
        onPresenceChanged: (_) {},
        onStatusChanged: (s) => debugPrint('Attacker: $s'),
        onEvent: (event, payload) {
          if (event == 'initiative_shared') attackerInitiative = payload;
          if (event == 'combat_defense') attackerReceipts.add(payload);
          if (event == 'initiative_control' &&
              payload['worldClockSnapshot'] is Map) {
            attackerRestSnapshots.add(payload);
          }
        },
      );
      final master = OculumRealtimeService(
        client: masterClient,
        roomId: room,
        playerName: 'Synthetic Master',
        presenceDataProvider: () => {
          'role': 'master',
          'activeSheetTag': masterTag,
          'localSheetTags': [masterTag],
          'campaignId': state.activeCampaignId,
        },
        onAccessRequested: (_, _) async => true,
        onPresenceChanged: (users) => masterState.realtimeUsers = users,
        onStatusChanged: (s) => debugPrint('Master: $s'),
        onEvent: (event, payload) {
          if (event == 'combat_defense') receipts.add(payload);
          if (event == 'initiative_control') {
            masterProbe.receiveEncounterControl(payload);
          }
          if (event == 'permission_request') {
            if (payload['worldClockCommand'] == 'rest_request') {
              masterRestRequests.add(payload);
            }
            masterProbe.receivePermission(event, payload);
          }
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
          if (event == 'initiative_shared') probe.receiveInitiative(payload);
          if (event == 'initiative_control') {
            if (payload['worldClockSnapshot'] is Map) {
              playerRestSnapshots.add(payload);
            }
            probe.receiveEncounterControl(payload);
          }
          if (event.startsWith('combat_')) probe.receiveCombat(event, payload);
          if (event == 'sheet_shared') {
            final applied = probe.receiveStaffSheet(payload);
            if (payload['senderRole'] == 'sheetEdit') {
              masterPatchApplied = applied;
              debugPrint(
                'Master patch received: applied=$applied, '
                'HP=${probe.currentHp()}, sentAt=${payload['sentAt']}, '
                'localUpdatedAt=${state.schedePersonaggio[0]['localUpdatedAt']}, '
                'dirtyAt=${state.schedePersonaggio[0]['realtimeDirtyAt']}',
              );
            }
          }
        },
      );
      state.realtimeService = player;
      masterState.realtimeService = master;
      addTearDown(() async {
        await helper.dispose();
        await player.dispose();
        await attacker.dispose();
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

      Future<void> connectWithRetry(
        OculumRealtimeService service,
        String label,
      ) async {
        const retryDelays = <Duration>[
          Duration.zero,
          Duration(seconds: 2),
          Duration(seconds: 5),
        ];
        for (var attempt = 0; attempt < retryDelays.length; attempt++) {
          if (retryDelays[attempt] > Duration.zero) {
            await Future<void>.delayed(retryDelays[attempt]);
          }
          await service.connect();
          if (service.isConnected) return;
          debugPrint(
            '$label non connesso al tentativo ${attempt + 1}/'
            '${retryDelays.length}; riprovo se il servizio è disponibile.',
          );
        }
        fail('$label non si è connesso dopo tentativi limitati.');
      }

      await tester.runAsync(
        () => HttpOverrides.runWithHttpOverrides(() async {
          // Connect the room owner first and retry transient Auth/Postgres
          // timeouts before asking the player to join a room that may not
          // have been created yet.
          await connectWithRetry(master, 'Master');
          await connectWithRetry(player, 'Player');
          await connectWithRetry(attacker, 'Attacker');
          await connectWithRetry(helper, 'Companion');
          expect(master.isConnected, isTrue);
          expect(player.isConnected, isTrue);
          expect(attacker.isConnected, isTrue);
          expect(
            {
              masterClient.auth.currentUser!.id,
              playerClient.auth.currentUser!.id,
              attackerClient.auth.currentUser!.id,
              helperClient.auth.currentUser!.id,
            },
            hasLength(4),
            reason: 'Four separate authenticated identities are required.',
          );
          await waitFor(
            () => (state.realtimeUsers as List).any(
              (dynamic p) => p['activeSheetTag'] == masterTag,
            ),
          );
          final sharedFight = <String, dynamic>{
            'campaignId': state.activeCampaignId,
            'encounterId': 'live-fight',
            'round': 4,
            'activeIndex': 2,
            'tokens': [
              {'id': playerTag},
              {'id': masterTag},
              {'id': 'Live_Attacker'},
              {'id': 'Live_Helper'},
            ],
          };
          await master.sendInitiativeSnapshot(
            snapshot: sharedFight,
            campaignId: state.activeCampaignId,
            campaignName: 'Synthetic verification',
            closed: false,
          );
          await waitFor(
            () =>
                state.realtimeVisibleInitiativeSnapshot['round'] == 4 &&
                attackerInitiative?['snapshot']?['round'] == 4 &&
                helperInitiative?['snapshot']?['round'] == 4,
          );
          expect(attackerInitiative!['authenticatedRole'], 'master');
          expect(attackerInitiative!['snapshot'], sharedFight);
          final packet = <String, dynamic>{
            'id': 'live-damage',
            'scope': probe.permissionScope,
            'campaignId': state.activeCampaignId,
            'encounterId': 'live-fight',
            'senderTag': 'Live_Attacker',
            'sourceTag': 'Live_Attacker',
            'sourceName': 'Attacker',
            'targetTag': playerTag,
            'choice': 'vc',
            'attack': 100,
            'damage': probe.defense() + 100,
            'level': 1,
            'difficulty': 'normale',
            'element': 'fisico',
          };
          expect(
            await attacker.sendCombatEvent('combat_attack', packet),
            isTrue,
          );
          await waitFor(
            () =>
                state.onlineCombatRequests['live-damage']?['received'] == true,
          );
          expect((state.logEventi as List).join('\n'), contains('[DIFESA]'));
          final request =
              state.onlineCombatRequests['live-damage'] as Map<String, dynamic>;
          expect(
            await helper.sendCombatEvent('combat_help', {
              ...packet,
              'id': 'live-defense-help',
              'senderTag': 'Live_Helper',
              'sourceTag': 'Live_Helper',
              'sourceName': 'Companion',
              'kind': 'help',
              'helpBonus': 4,
              'targetName': 'Player',
            }),
            isTrue,
          );
          await waitFor(
            () => state.schedePersonaggio[0]['combatHelpPending'] == 4,
          );
          probe.applyEffects([
            OculumStructuredEffect(
              id: 'live-defense-shield',
              type: 'scudo',
              valueExpression: '30',
              duration: '0',
              recipient: 'se_stesso',
            ),
          ], source: 'Skill difensiva di prova');
          expect(
            state.scudoController.text,
            '50',
            reason: 'The defense skill adds its shield before the response.',
          );
          await probe.resolveCombatDefense(
            request,
            'cm',
            10 + probe.consumeHelp(),
          );
          expect(probe.consumeHelp(), 0);
          expect(request['outcome'], 'full');
          expect(state.scudoOculumController.text, '0');
          expect(state.scudoController.text, '0');
          expect(state.hpTempController.text, '0');
          await waitFor(() => receipts.isNotEmpty);
          await waitFor(() => attackerReceipts.isNotEmpty);
          expect(
            attackerReceipts.last['damageReceipt'],
            receipts.last['damageReceipt'],
          );
          final damageReceipt = Map<String, dynamic>.from(
            receipts.last['damageReceipt'] as Map,
          );
          expect(
            probe.currentHp(),
            600 - readIntValue(damageReceipt['hpLost']),
            reason:
                'Only damage left after the ordered protection layers may reduce HP.',
          );
          expect(
            readIntValue(damageReceipt['oculumShieldLost']),
            lessThanOrEqualTo(10),
          );
          expect(
            readIntValue(damageReceipt['shieldLost']),
            lessThanOrEqualTo(50),
          );
          expect(
            readIntValue(damageReceipt['temporaryHpLost']),
            lessThanOrEqualTo(20),
          );
          expect(damageReceipt['pawnPending'], false);
          expect(
            probe.incomingDamagePreset('fisico'),
            'Bassa Fragilità',
            reason:
                'A critical hit advances the target resistance for its damage element.',
          );
          expect(
            (state.logEventi as List).join('\n'),
            contains('Critico nemico'),
            reason:
                'The critical damage bonus must be logged on the target sheet.',
          );
          if (readIntValue(damageReceipt['shieldLost']) > 0) {
            expect(readIntValue(damageReceipt['oculumShieldLost']), 10);
          }
          if (readIntValue(damageReceipt['temporaryHpLost']) > 0) {
            expect(readIntValue(damageReceipt['shieldLost']), 50);
          }
          await probe.resolveCombatDefense(request, 'cm', 10);
          expect(
            probe.currentHp(),
            600 - readIntValue(damageReceipt['hpLost']),
            reason: 'Duplicate defense must not repeat damage',
          );
          final support = <String, dynamic>{
            ...packet,
            'senderTag': masterTag,
            'sourceTag': masterTag,
            'sourceName': 'Master',
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
          expect(
            await master.sendCombatEvent('combat_help', {
              ...support,
              'id': 'live-help-positive',
              'helpBonus': 4,
            }),
            isTrue,
          );
          await waitFor(
            () => state.schedePersonaggio[0]['combatHelpPending'] == 4,
          );
          expect(probe.consumeHelp(), 4);
          expect(probe.consumeHelp(), 0);
          final hpBeforeHealing = probe.currentHp();
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
          expect(probe.currentHp(), hpBeforeHealing + 10);
          await master.sendCombatEvent('combat_help', healing);
          await Future<void>.delayed(const Duration(seconds: 1));
          expect(
            probe.currentHp(),
            hpBeforeHealing + 10,
            reason: 'Duplicate support must not heal twice',
          );
          expect(
            await master.sendSharedSheetConfirmed(
              sheet: {'currentHp': '11', 'scudo': '7', 'hpTemp': '3'},
              campaignId: state.activeCampaignId,
              campaignName: 'Synthetic verification',
              sheetId: playerTag,
              sheetName: 'Player',
              ownerTag: playerTag,
              senderRole: 'sheetEdit',
              targetAudience: 'owner',
              fromMaster: true,
              masterParty: false,
              targetTags: [playerTag],
            ),
            isTrue,
          );
          await waitFor(() => masterPatchApplied != null);
          expect(
            masterPatchApplied,
            isTrue,
            reason: (state.logEventi as List).take(8).join('\n'),
          );
          expect(probe.currentHp(), 11);
          expect(
            state.scudoController.text,
            '7',
            reason: 'The room Master can edit the online owner sheet',
          );
          expect(state.hpTempController.text, '3');
          expect(
            probe.ownerTag(),
            playerTag,
            reason: 'Master editing does not transfer character ownership',
          );
          // New protocol phase in this same fourth authenticated test.
          // Both sides execute real application handlers, not a fabricated
          // grant applied directly to the player. Other clients observe the
          // authenticated Master publication as well.
          await master.refreshPresence();
          expect(
            (masterState.realtimeUsers as List).any(
              (dynamic row) =>
                  [
                    row['activeSheetTag'],
                    ...(row['localSheetTags'] as List? ?? const []),
                  ].any(
                    (tag) =>
                        '${tag ?? ''}'.toUpperCase() == playerTag.toUpperCase(),
                  ),
            ),
            true,
            reason:
                'The actual authenticated Master presence must own the player tag: '
                '${(masterState.realtimeUsers as List).map((dynamic row) => {'tag': row['activeSheetTag'], 'tags': row['localSheetTags'], 'campaign': row['campaignId']}).toList()}',
          );
          masterProbe.setWorldClock(<String, dynamic>{
            'seconds': 0,
            'revision': 0,
            'calendarOriginDay': 1,
            'calendarOriginOrdinal': 0,
          });
          final hpBeforeRest = probe.currentHp();
          expect(hpBeforeRest, 11);
          expect(probe.maximumHp(), 600);
          probe.requestSleepRest();
          final outgoingRequests =
              probe.needsSnapshot()['restRequests'] as List;
          expect(outgoingRequests, hasLength(1));
          final originalRestRequest = Map<String, dynamic>.from(
            outgoingRequests.single as Map,
          );
          final restId = '${originalRestRequest['id']}';
          expect(originalRestRequest['effectsAlreadyApplied'], false);
          expect(
            probe.currentHp(),
            hpBeforeRest,
            reason:
                'Requesting sleep never grants recovery before Master confirmation.',
          );
          await probe.flushRestRequests();
          await waitFor(
            () => (masterProbe.worldClockPrivate()['rests'] as List? ?? [])
                .whereType<Map>()
                .any(
                  (row) => row['id'] == restId && row['status'] == 'pending',
                ),
          );
          expect(
            masterRestRequests.any(
              (row) =>
                  row['id'] == restId && row['authenticatedRole'] == 'player',
            ),
            true,
          );
          expect(masterProbe.worldSeconds(), 0);
          expect(probe.currentHp(), hpBeforeRest);
          expect(masterProbe.worldConfirmRest(restId, 89), false);
          expect(masterProbe.worldConfirmRest(restId, 90), true);
          await waitFor(
            () =>
                (probe.needsSnapshot()['restReceipts'] as List? ?? []).contains(
                  restId,
                ) &&
                playerRestSnapshots.any((row) => containsGrant(row, restId)) &&
                attackerRestSnapshots.any(
                  (row) => containsGrant(row, restId),
                ) &&
                helperRestSnapshots.any((row) => containsGrant(row, restId)),
          );
          expect(probe.worldSeconds(), 5400);
          expect(masterProbe.worldSeconds(), 5400);
          expect(
            probe.currentHp(),
            450,
            reason:
                'Confirmed 90 minute sleep recovers to 75% of actual maximum HP.',
          );
          expect(probe.needsSnapshot()['restRequests'], isEmpty);
          expect(playerRestSnapshots.last['authenticatedRole'], 'master');
          // Persist the real grant receipt, lower HP, then force a new network
          // envelope containing the SAME rest ID. A backend/message deduper
          // alone must not make this idempotency assertion pass.
          final afterRest =
              jsonDecode(jsonEncode(probe.snapshot())) as Map<String, dynamic>;
          state.schedePersonaggio[state.schedaCorrente] = afterRest;
          probe.load(afterRest);
          state.currentHpController.text = '400';
          state.longRestInProgress = false;
          final beforeReplayCount = playerRestSnapshots.length;
          expect(
            await player.sendPermissionEvent('permission_request', {
              ...originalRestRequest,
              'action': 'world_clock',
            }),
            true,
          );
          expect(masterProbe.worldConfirmRest(restId, 90), false);
          expect(
            await master
                .sendCombatEvent('initiative_control', <String, dynamic>{
                  'id': 'rest-live-replay:$restId',
                  'scope': masterProbe.permissionScope,
                  'campaignId': state.activeCampaignId,
                  'senderTag': masterTag,
                  'senderRole': 'master',
                  'worldClockSnapshot': masterProbe.worldClockPublic(),
                }),
            true,
          );
          await waitFor(
            () =>
                playerRestSnapshots.length > beforeReplayCount &&
                containsGrant(playerRestSnapshots.last, restId),
          );
          expect(
            probe.currentHp(),
            400,
            reason:
                'A repeated confirmed rest must not recover HP again after JSON reload.',
          );
          expect(probe.worldSeconds(), 5400);
          expect(masterProbe.worldSeconds(), 5400);
          expect(
            (probe.needsSnapshot()['restReceipts'] as List).where(
              (receipt) => receipt == restId,
            ),
            hasLength(1),
          );
          expect(
            (masterProbe.worldClockPrivate()['rests'] as List)
                .whereType<Map>()
                .where((row) => row['id'] == restId),
            hasLength(1),
          );
          debugPrint(
            'LIVE REST VERIFIED: pending without recovery; Master confirmed90min; '
            'four authenticated clients received grant; reload/replay gave no second recovery.',
          );
          await player.dispose();
          await helper.dispose();
          await attacker.dispose();
          await master.dispose();
          await closeClients();
        }, _LiveNetwork()),
      );
      state.realtimeService = null;
      masterState.realtimeService = null;
      state.realtimeAutoReconnectEnabled = false;
      masterState.realtimeAutoReconnectEnabled = false;
      state.autosaveTimer?.cancel();
      masterState.autosaveTimer?.cancel();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
    skip: !_runLive,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
