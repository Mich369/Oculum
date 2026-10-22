import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Channel implements RealtimeChannel {
  ChannelResponse response = ChannelResponse.ok;
  Function? subscription;
  Completer<ChannelResponse>? pendingSend;
  final broadcasts = <Map<String, dynamic>>[];
  final callbacks = <String, Function>{};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #subscribe:
        final callback = invocation.positionalArguments.first as Function;
        subscription = callback;
        callback(RealtimeSubscribeStatus.subscribed, null);
        return this;
      case #track:
      case #untrack:
        return Future.value(ChannelResponse.ok);
      case #sendBroadcastMessage:
        broadcasts.add({
          'event': invocation.namedArguments[#event],
          'payload': invocation.namedArguments[#payload],
        });
        return pendingSend?.future ?? Future.value(response);
      case #presenceState:
        return <SinglePresenceState>[];
      case #onBroadcast:
        callbacks[invocation.namedArguments[#event] as String] =
            invocation.namedArguments[#callback] as Function;
        return this;
      case #onPresenceSync:
      case #onPresenceJoin:
      case #onPresenceLeave:
        return this;
    }
    return super.noSuchMethod(invocation);
  }
}

// Exercise the production authenticated RPC transport against an in-memory
// HTTP backend. Raw unsigned broadcasts must never bypass the event journal.
class _Client extends SupabaseClient {
  factory _Client([_Backend? backend]) =>
      _Client._(_Channel(), backend ?? _Backend());
  _Client._(this.testChannel, this.backend)
    : super(
        'https://isolated-test.supabase.co',
        'public-test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          dynamic body;
          final path = request.url.path;
          if (path.endsWith('/signup')) {
            body = {
              'access_token': 'test-session',
              'refresh_token': 'test-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': 'owner',
                'aud': 'authenticated',
                'created_at': '2026-10-19T00:00:00Z',
                'is_anonymous': true,
              },
            };
          } else if (path.endsWith('/oculum_open_room') ||
              path.endsWith('/oculum_open_room_with_password')) {
            final input = jsonDecode(request.body) as Map;
            backend.openRoomCalls++;
            backend.lastRoomInput = input;
            if (backend.roomAccessError != null) {
              return http.Response(
                jsonEncode({
                  'message': backend.roomAccessError,
                  'code': '42501',
                }),
                403,
                request: request,
                headers: {'content-type': 'application/json'},
              );
            }
            body = {
              'roomId': 'room',
              'role':
                  backend.roomRole ??
                  (input['p_as_master'] == true ? 'master' : 'player'),
              'status': backend.roomStatus,
            };
          } else if (path.endsWith('/oculum_room_members')) {
            backend.membershipReads++;
            body = request.url.queryParameters['status'] == 'eq.pending'
                ? backend.pendingAccess
                : [
                    {
                      'role': backend.roomRole ?? 'player',
                      'status': backend.roomStatus,
                    },
                  ];
          } else if (path.endsWith('/oculum_set_room_password')) {
            backend.passwordWrites++;
            body = null;
          } else if (path.endsWith('/oculum_touch_room_session')) {
            backend.presenceWrites++;
            final input = jsonDecode(request.body) as Map;
            backend.sessions['${input['p_session']}'] =
                Map<String, dynamic>.from(input['p_presence'] as Map);
            backend.sessions['${input['p_session']}']!['role'] ??= 'player';
            if (backend.foreignTags.isNotEmpty) {
              final presence = backend.sessions['${input['p_session']}']!;
              final tags = (presence['localSheetTags'] as List? ?? const [])
                  .where((tag) => !backend.foreignTags.contains(tag))
                  .toList();
              presence['localSheetTags'] = tags;
              if (!tags.contains(presence['activeSheetTag'])) {
                presence['activeSheetTag'] = '';
              }
            }
            final delayedReply = backend.delayedPresenceReply;
            backend.delayedPresenceReply = null;
            if (delayedReply != null) {
              backend.presenceReplyStarted?.complete();
              await delayedReply.future;
            }
            body = null;
          } else if (path.endsWith('/oculum_emit_room_event')) {
            final input = jsonDecode(request.body) as Map;
            final result =
                await (testChannel.pendingSend?.future ??
                    Future.value(testChannel.response));
            if (result != ChannelResponse.ok) {
              return http.Response(
                jsonEncode({'message': result.name, 'code': 'TEST'}),
                503,
                request: request,
              );
            }
            if (!backend.sessions.containsKey('${input['p_session']}')) {
              return http.Response(
                jsonEncode({
                  'message': 'session not registered',
                  'code': 'TEST',
                }),
                403,
                request: request,
              );
            }
            final id = 'event-${backend.events.length}';
            final session = backend.sessions['${input['p_session']}']!;
            final payload = Map<String, dynamic>.from(
              input['p_payload'] as Map,
            );
            final routing = payload['_routing'] as Map? ?? payload;
            payload.addAll({
              'authenticatedSheetId': routing['sheetId'] ?? payload['sheetId'],
              'authenticatedRole': session['role'],
              'senderRole': session['role'],
              'targetAudience': routing['targetAudience'],
              'senderTag': session['activeSheetTag'],
              'sessionId': input['p_session'],
            });
            backend.events.add({
              'id': id,
              'sequence': backend.events.length + 1,
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'room_id': 'room',
              'event': input['p_event'],
              'payload': payload,
            });
            testChannel.broadcasts.add({
              'id': id,
              'event': input['p_event'],
              'payload': payload,
            });
            body = id;
          } else if (path.endsWith('/oculum_room_events')) {
            final eventId = request.url.queryParameters['id']?.replaceFirst(
              'eq.',
              '',
            );
            if (eventId != null) {
              body = backend.events
                  .where((event) => event['id'] == eventId)
                  .firstOrNull;
            } else if (request.url.queryParameters['event'] ==
                'eq.initiative_shared') {
              backend.initiativeSnapshotReads++;
              body =
                  backend.events
                      .where(
                        (event) =>
                            event['event'] == 'initiative_shared' &&
                            event['room_id'] ==
                                request.url.queryParameters['room_id']
                                    ?.replaceFirst('eq.', ''),
                      )
                      .toList()
                    ..sort(
                      (a, b) => (b['sequence'] as int).compareTo(
                        a['sequence'] as int,
                      ),
                    );
              body = (body as List).firstOrNull;
            } else {
              final after =
                  int.tryParse(
                    request.url.queryParameters['sequence']?.replaceFirst(
                          'gt.',
                          '',
                        ) ??
                        '',
                  ) ??
                  0;
              body = backend.events
                  .where((event) => (event['sequence'] as int) > after)
                  .toList();
              final from = request.url.queryParameters['created_at']
                  ?.replaceFirst('gte.', '');
              if (from != null) {
                body = (body as List)
                    .where(
                      (event) => '${event['created_at']}'.compareTo(from) >= 0,
                    )
                    .toList();
              }
            }
          } else if (path.endsWith('/oculum_room_presence')) {
            backend.presenceReads++;
            final stalledRead = backend.stalledPresenceRead;
            backend.stalledPresenceRead = null;
            if (stalledRead != null) await stalledRead.future;
            body = backend.sessions.values.toList();
          } else {
            body = null;
          }
          return http.Response(
            jsonEncode(body),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
  final _Channel testChannel;
  final _Backend backend;
  int channelCount = 0;

  @override
  RealtimeChannel channel(
    String name, {
    RealtimeChannelConfig opts = const RealtimeChannelConfig(),
  }) {
    channelCount++;
    return testChannel;
  }

  @override
  Future<String> removeChannel(RealtimeChannel channel) async => 'ok';
}

class _Backend {
  String roomStatus = 'approved';
  String? roomRole;
  String? roomAccessError;
  int openRoomCalls = 0;
  int membershipReads = 0;
  int passwordWrites = 0;
  final foreignTags = <String>{};
  final pendingAccess = <Map<String, dynamic>>[];
  Map? lastRoomInput;
  Completer<void>? delayedPresenceReply;
  Completer<void>? presenceReplyStarted;
  int presenceWrites = 0;
  int presenceReads = 0;
  Completer<void>? stalledPresenceRead;
  final sessions = <String, Map<String, dynamic>>{};
  final events = <Map<String, dynamic>>[];
  int initiativeSnapshotReads = 0;
}

void main() {
  test(
    'a stalled presence read releases refresh and permits recovery',
    () async {
      final previous = OculumRealtimeService.supabaseAvailable;
      OculumRealtimeService.supabaseAvailable = true;
      final backend = _Backend();
      final client = _Client(backend);
      var deliveredPresence = 0;
      final service = OculumRealtimeService(
        client: client,
        roomId: 'stalled-read',
        playerName: 'Player',
        httpPollingOnly: true,
        presenceDataProvider: () => {'role': 'player'},
        onEvent: (_, _) {},
        onPresenceChanged: (_) => deliveredPresence++,
        onStatusChanged: printOnFailure,
      );
      final stalledRead = Completer<void>();
      addTearDown(() async {
        if (!stalledRead.isCompleted) stalledRead.complete();
        await service.dispose();
        await client.dispose();
        OculumRealtimeService.supabaseAvailable = previous;
      });
      await service.connect();
      backend.stalledPresenceRead = stalledRead;
      await service.refreshPresence().timeout(const Duration(seconds: 12));
      expect(stalledRead.isCompleted, isFalse);
      final beforeRecovery = deliveredPresence;
      await service.refreshPresence().timeout(const Duration(seconds: 3));
      expect(deliveredPresence, greaterThan(beforeRecovery));
      expect(service.isConnected, isTrue);
    },
  );

  test(
    'concurrent large party sheets finish before the next transfer starts',
    () async {
      final previous = OculumRealtimeService.supabaseAvailable;
      OculumRealtimeService.supabaseAvailable = true;
      final client = _Client();
      final received = <String>{};
      final service = OculumRealtimeService(
        client: client,
        roomId: 'party',
        playerName: 'Master',
        presenceDataProvider: () => {'role': 'master'},
        onEvent: (event, payload) {
          if (event == 'sheet_shared') received.add('${payload['sheetId']}');
        },
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      );
      addTearDown(() async {
        await service.dispose();
        await client.dispose();
        OculumRealtimeService.supabaseAvailable = previous;
      });
      await service.connect();
      final results = await Future.wait([
        for (var i = 0; i < 12; i++)
          service.sendSharedSheetConfirmed(
            sheet: {'nome': 'Party $i', 'imageBase64': 'x' * 70000},
            campaignId: 'campaign',
            campaignName: 'Campaign',
            sheetId: 'PARTY_$i',
            sheetName: 'Party $i',
            ownerTag: 'PARTY_$i',
            senderRole: 'master',
            targetAudience: 'players_party_full',
            fromMaster: true,
            masterParty: true,
          ),
      ]);
      expect(results, everyElement(isTrue));
      final completed = <String>{};
      String? active;
      for (final part in client.testChannel.broadcasts) {
        final payload = part['payload'] as Map;
        final transfer = '${payload['transferId']}';
        if (active != transfer) {
          expect(
            completed,
            isNot(contains(transfer)),
            reason: 'Chunks must not interleave',
          );
          if (active != null) completed.add(active);
          active = transfer;
        }
        client.testChannel.callbacks['sheet_shared_chunk']!({
          'serverEventId': part['id'],
        });
      }
      for (var i = 0; i < 100 && received.length < 12; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(
        received.length,
        12,
        reason:
            'The bounded eight-transfer receiver must import the whole party',
      );
    },
  );
  test(
    'pending join stays busy, cannot become Master and cancels immediately',
    () async {
      final previous = OculumRealtimeService.supabaseAvailable;
      OculumRealtimeService.supabaseAvailable = true;
      addTearDown(() => OculumRealtimeService.supabaseAvailable = previous);
      final backend = _Backend()
        ..roomStatus = 'pending'
        ..roomRole = 'player';
      final client = _Client(backend);
      final waiting = Completer<void>();
      late OculumRealtimeService service;
      service = OculumRealtimeService(
        client: client,
        roomId: 'test',
        playerName: 'Another account',
        presenceDataProvider: () => {'role': 'master'},
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (status) {
          if (service.isAwaitingApproval && !waiting.isCompleted) {
            expect(service.isConnecting, isTrue);
            expect(status, contains('altro account'));
            waiting.complete();
          }
        },
      );
      addTearDown(() async {
        await service.dispose();
        await client.dispose();
      });
      final attempt = service.connect();
      await waiting.future.timeout(const Duration(seconds: 3));
      expect(service.masterRoleUnavailable, isTrue);
      expect(service.isConnected, isFalse);
      expect(identical(service.connect(), attempt), isTrue);
      expect(await service.setRoomPassword('forbidden'), isFalse);
      expect(backend.passwordWrites, 0);
      await service.disconnect();
      await attempt.timeout(const Duration(seconds: 1));
      expect(service.isAwaitingApproval, isFalse);
      expect(service.isConnecting, isFalse);
      expect(backend.openRoomCalls, 1);
      expect(client.channelCount, 0);
    },
  );

  test(
    'approval polling reads own membership without repeating the write RPC',
    () async {
      final previous = OculumRealtimeService.supabaseAvailable;
      OculumRealtimeService.supabaseAvailable = true;
      addTearDown(() => OculumRealtimeService.supabaseAvailable = previous);
      final backend = _Backend()..roomStatus = 'pending';
      final client = _Client(backend);
      final waiting = Completer<void>();
      final service = OculumRealtimeService(
        client: client,
        roomId: 'test',
        playerName: 'Player',
        roomPassword: 'session-secret',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {
          if (!waiting.isCompleted) waiting.complete();
        },
      );
      addTearDown(() async {
        await service.dispose();
        await client.dispose();
      });
      final attempt = service.connect();
      await waiting.future.timeout(const Duration(seconds: 3));
      backend.roomStatus = 'approved';
      await attempt.timeout(const Duration(seconds: 15));
      expect(service.isConnected, isTrue);
      expect(service.authenticatedRole, 'player');
      expect(backend.openRoomCalls, 1);
      expect(backend.membershipReads, 1);
      expect(backend.lastRoomInput!['p_password'], 'session-secret');
      expect(await service.setRoomPassword('forbidden'), isFalse);
    },
  );

  test(
    'incorrect password requires user input instead of automatic retries',
    () async {
      final previous = OculumRealtimeService.supabaseAvailable;
      OculumRealtimeService.supabaseAvailable = true;
      addTearDown(() => OculumRealtimeService.supabaseAvailable = previous);
      final backend = _Backend()..roomAccessError = 'Password non corretta';
      final client = _Client(backend);
      final statuses = <String>[];
      final service = OculumRealtimeService(
        client: client,
        roomId: 'test',
        playerName: 'Player',
        roomPassword: 'wrong',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: statuses.add,
      );
      addTearDown(() async {
        await service.dispose();
        await client.dispose();
      });
      await service.connect();
      expect(service.requiresUserAction, isTrue, reason: statuses.join('\n'));
      expect(service.isConnected, isFalse);
      expect(backend.openRoomCalls, 1);
      expect(client.channelCount, 0);
    },
  );

  test('realtime recovery intervals stay bounded on an unhealthy backend', () {
    expect(
      OculumRealtimeService.roomRefreshInterval,
      const Duration(seconds: 15),
    );
    expect(
      OculumRealtimeService.httpPollingInterval,
      const Duration(seconds: 5),
    );
    expect(oculumRealtimeSheetAckRetryDelay(1), const Duration(seconds: 8));
    expect(oculumRealtimeSheetAckRetryDelay(2), const Duration(seconds: 15));
    expect(oculumRealtimeSheetAckRetryDelay(3), const Duration(seconds: 30));
    expect(oculumRealtimeSheetAckRetryDelay(4), const Duration(seconds: 60));
    expect(oculumRealtimeSheetAckRetryDelay(10), const Duration(seconds: 120));
  });

  test(
    'waiting for a Master decision does not block the room heartbeat',
    () async {
      final previous = OculumRealtimeService.supabaseAvailable;
      OculumRealtimeService.supabaseAvailable = true;
      addTearDown(() => OculumRealtimeService.supabaseAvailable = previous);
      final backend = _Backend()
        ..pendingAccess.add({'user_id': 'new-player', 'display_name': 'Rose'});
      final client = _Client(backend);
      final decision = Completer<bool?>();
      final received = Completer<void>();
      final service = OculumRealtimeService(
        client: client,
        roomId: 'master',
        playerName: 'Master',
        presenceDataProvider: () => {'role': 'master'},
        onAccessRequested: (_, _) {
          if (!received.isCompleted) received.complete();
          return decision.future;
        },
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      );
      addTearDown(() async {
        if (!decision.isCompleted) decision.complete(null);
        await service.dispose();
        await client.dispose();
      });
      await service.connect().timeout(const Duration(seconds: 3));
      await received.future.timeout(const Duration(seconds: 3));
      expect(service.isConnected, isTrue);
      await service.refreshPresence().timeout(const Duration(seconds: 3));
      expect(
        await service.sendPermissionEvent('permission_decision', {
          'id': 'other-action',
        }),
        isTrue,
      );
    },
  );

  test(
    'foreign active sheet is explained and cannot be sent as an owned sheet',
    () async {
      final previous = OculumRealtimeService.supabaseAvailable;
      OculumRealtimeService.supabaseAvailable = true;
      addTearDown(() => OculumRealtimeService.supabaseAvailable = previous);
      final backend = _Backend()..foreignTags.add('FOREIGN');
      final client = _Client(backend);
      var activeTag = 'FOREIGN';
      final service = OculumRealtimeService(
        client: client,
        roomId: 'test',
        playerName: 'Player',
        presenceDataProvider: () => {
          'role': 'player',
          'activeSheetTag': activeTag,
          'localSheetTags': [activeTag],
        },
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      );
      addTearDown(() async {
        await service.dispose();
        await client.dispose();
      });
      await service.connect();
      expect(service.unavailableActiveSheetTag, 'FOREIGN');
      expect(
        await service.sendSharedSheetConfirmed(
          sheet: {'nome': 'Foreign'},
          campaignId: 'campaign',
          campaignName: 'Campaign',
          sheetId: 'FOREIGN',
          sheetName: 'Foreign',
          ownerTag: 'FOREIGN',
          senderRole: 'player',
          targetAudience: 'master_coMaster',
          fromMaster: false,
          masterParty: false,
        ),
        isFalse,
      );
      expect(
        backend.events.where((event) => event['event'] == 'sheet_shared'),
        isEmpty,
      );
      await Future<void>.delayed(Duration.zero);
      expect(backend.events.single['event'], 'permission_request');
      expect(
        backend.events.single['payload']['action'],
        'sheet_identity_conflict',
      );
      expect(backend.events.single['payload'].containsKey('sheet'), isFalse);
      activeTag = 'LOCAL';
      await service.refreshPresence();
      expect(service.unavailableActiveSheetTag, isNull);
    },
  );

  test(
    'sheet switch during a presence request registers the new sender before sending',
    () async {
      final previous = OculumRealtimeService.supabaseAvailable;
      OculumRealtimeService.supabaseAvailable = true;
      addTearDown(() => OculumRealtimeService.supabaseAvailable = previous);
      final backend = _Backend();
      final client = _Client(backend);
      var activeTag = 'INITIAL';
      final service = OculumRealtimeService(
        client: client,
        roomId: 'race',
        playerName: 'Player',
        presenceDataProvider: () => {
          'role': 'player',
          'activeSheetTag': activeTag,
          'localSheetTags': [activeTag],
        },
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      );
      addTearDown(() async {
        await service.dispose();
        await client.dispose();
      });
      await service.connect();
      final delayed = Completer<void>();
      backend.delayedPresenceReply = delayed;
      backend.presenceReplyStarted = Completer<void>();
      activeTag = 'OLD';
      final refresh = service.refreshPresence();
      await backend.presenceReplyStarted!.future;
      activeTag = 'NEW';
      final sent = service.sendPermissionEvent('permission_request', {
        'senderTag': 'NEW',
      });
      delayed.complete();
      await refresh;
      expect(await sent, isTrue);
      expect(backend.sessions.values.single['activeSheetTag'], 'NEW');
      expect(backend.events.single['payload']['senderTag'], 'NEW');
    },
  );

  test('reconnect does not await an obsolete presence reply', () async {
    final previous = OculumRealtimeService.supabaseAvailable;
    OculumRealtimeService.supabaseAvailable = true;
    addTearDown(() => OculumRealtimeService.supabaseAvailable = previous);
    final backend = _Backend();
    final client = _Client(backend);
    var activeTag = 'PLAYER';
    final service = OculumRealtimeService(
      client: client,
      roomId: 'presence-reconnect',
      playerName: 'Player',
      httpPollingOnly: true,
      presenceDataProvider: () => {
        'role': 'player',
        'activeSheetTag': activeTag,
        'localSheetTags': [activeTag],
      },
      onEvent: (_, _) {},
      onPresenceChanged: (_) {},
      onStatusChanged: printOnFailure,
    );
    final delayedReply = Completer<void>();
    addTearDown(() async {
      if (!delayedReply.isCompleted) delayedReply.complete();
      await service.dispose();
      await client.dispose();
    });
    await service.connect();
    activeTag = 'OLD';
    backend.delayedPresenceReply = delayedReply;
    backend.presenceReplyStarted = Completer<void>();
    final obsoleteRefresh = service.refreshPresence();
    await backend.presenceReplyStarted!.future;
    await service.disconnect();
    activeTag = 'NEW';
    await service.connect().timeout(const Duration(seconds: 3));
    expect(service.isConnected, isTrue);
    expect(backend.sessions.values.single['activeSheetTag'], 'NEW');
    final writesBeforeObsoleteReply = backend.presenceWrites;
    delayedReply.complete();
    await obsoleteRefresh;
    await service.refreshPresence();
    expect(backend.presenceWrites, writesBeforeObsoleteReply);
  });

  test(
    'unchanged presence coalesces refreshes but new active sheets register immediately',
    () async {
      final previous = OculumRealtimeService.supabaseAvailable;
      OculumRealtimeService.supabaseAvailable = true;
      addTearDown(() => OculumRealtimeService.supabaseAvailable = previous);
      final backend = _Backend();
      final client = _Client(backend);
      var activeTag = 'PLAYER';
      final service = OculumRealtimeService(
        client: client,
        roomId: 'presence-io',
        playerName: 'Player',
        httpPollingOnly: true,
        presenceDataProvider: () => {
          'role': 'player',
          'activeSheetTag': activeTag,
          'localSheetTags': [activeTag],
        },
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: printOnFailure,
      );
      addTearDown(() async {
        await service.dispose();
        await client.dispose();
      });
      await service.connect();
      final initialWrites = backend.presenceWrites;
      expect(initialWrites, greaterThan(0));
      final initialReads = backend.presenceReads;
      for (var i = 0; i < 10; i++) {
        expect(
          await service.sendPermissionEvent('permission_request', {
            'senderTag': 'PLAYER',
            'id': 'action-$i',
          }),
          isTrue,
        );
      }
      expect(backend.presenceReads, initialReads);
      expect(backend.presenceWrites, initialWrites);
      await Future.wait(List.generate(10, (_) => service.refreshPresence()));
      expect(backend.presenceWrites, initialWrites);
      activeTag = 'SUMMON';
      await service.refreshPresence();
      expect(backend.presenceWrites, initialWrites + 1);
      expect(backend.sessions.values.single['activeSheetTag'], 'SUMMON');
    },
  );

  test('an explicit close closes even a complete saved fight snapshot', () {
    expect(
      oculumInitiativePayloadClosesFight({
        'closed': true,
        'snapshot': {'encounters': []},
      }),
      isTrue,
    );
    expect(
      oculumInitiativePayloadClosesFight({
        'closed': false,
        'snapshot': {'encounters': []},
      }),
      isFalse,
    );
  });

  test(
    'HTTPS polling delivers a sheet and peer receipt after session registration',
    () async {
      final previous = OculumRealtimeService.supabaseAvailable;
      OculumRealtimeService.supabaseAvailable = true;
      addTearDown(() => OculumRealtimeService.supabaseAvailable = previous);
      final backend = _Backend();
      final playerClient = _Client(backend);
      final masterClient = _Client(backend);
      final playerReady = Completer<void>();
      final masterReady = Completer<void>();
      final sheetReceived = Completer<void>();
      final ackReceived = Completer<void>();
      late OculumRealtimeService master;
      master = OculumRealtimeService(
        client: masterClient,
        roomId: 'cross-network',
        playerName: 'Master',
        httpPollingOnly: true,
        presenceDataProvider: () => {
          'role': 'master',
          'activeSheetTag': 'MASTER',
          'localSheetTags': ['MASTER'],
        },
        onConnected: () {
          expect(
            backend.sessions.values.any((value) => value['role'] == 'master'),
            isTrue,
          );
          if (!masterReady.isCompleted) masterReady.complete();
        },
        onEvent: (event, payload) {
          if (event == 'sheet_shared' && payload['deliveryId'] == 'receipt-1') {
            if (!sheetReceived.isCompleted) sheetReceived.complete();
            unawaited(
              master.sendSheetReceivedAck(
                deliveryId: 'receipt-1',
                ownerTag: 'PLAYER',
                sheetId: 'PLAYER',
                sheetName: 'Player',
                campaignId: 'cross-network',
                campaignName: 'Test',
                receiverRole: 'master',
                receiverTag: 'MASTER',
              ),
            );
          }
        },
        onPresenceChanged: (_) {},
        onStatusChanged: printOnFailure,
      );
      final player = OculumRealtimeService(
        client: playerClient,
        roomId: 'cross-network',
        playerName: 'Player',
        httpPollingOnly: true,
        presenceDataProvider: () => {
          'role': 'player',
          'activeSheetTag': 'PLAYER',
          'localSheetTags': ['PLAYER'],
        },
        onConnected: () {
          expect(
            backend.sessions.values.any((value) => value['role'] == 'player'),
            isTrue,
          );
          if (!playerReady.isCompleted) playerReady.complete();
        },
        onEvent: (event, payload) {
          if (event == 'sheet_received_ack' &&
              payload['deliveryId'] == 'receipt-1' &&
              payload['authenticatedRole'] == 'master' &&
              !ackReceived.isCompleted) {
            ackReceived.complete();
          }
        },
        onPresenceChanged: (_) {},
        onStatusChanged: printOnFailure,
      );
      addTearDown(() async {
        await player.dispose();
        await master.dispose();
        await playerClient.dispose();
        await masterClient.dispose();
      });

      await Future.wait([master.connect(), player.connect()]);
      await Future.wait([
        masterReady.future,
        playerReady.future,
      ]).timeout(const Duration(seconds: 5));
      expect(playerClient.channelCount, 0);
      expect(masterClient.channelCount, 0);
      expect(
        await player.sendSharedSheetConfirmed(
          sheet: {'nome': 'Player', 'hp': 24, 'diario': 'Scheda di prova'},
          campaignId: 'cross-network',
          campaignName: 'Test',
          sheetId: 'PLAYER',
          sheetName: 'Player',
          ownerTag: 'PLAYER',
          senderRole: 'player',
          targetAudience: 'master_coMaster',
          fromMaster: false,
          masterParty: false,
          deliveryId: 'receipt-1',
        ),
        isTrue,
      );
      await Future.wait([
        sheetReceived.future,
        ackReceived.future,
      ]).timeout(const Duration(seconds: 15));
    },
  );

  test('fresh session restores the last durable initiative snapshot', () async {
    final previous = OculumRealtimeService.supabaseAvailable;
    OculumRealtimeService.supabaseAvailable = true;
    addTearDown(() => OculumRealtimeService.supabaseAvailable = previous);
    final backend = _Backend();
    backend.events.add({
      'id': 'old-fight',
      'sequence': 8,
      'created_at': '2026-01-01T00:00:00Z',
      'room_id': 'room',
      'event': 'initiative_shared',
      'payload': {
        'sessionId': 'old-master-session',
        'senderRole': 'master',
        'authenticatedRole': 'master',
        'authenticatedUserId': 'owner',
        'revision': 12,
        'campaignId': 'campaign',
        'snapshot': {'round': 4, 'turnCount': 3},
      },
    });
    final client = _Client(backend);
    final restored = Completer<Map<String, dynamic>>();
    final service = OculumRealtimeService(
      client: client,
      roomId: 'room',
      playerName: 'Player',
      httpPollingOnly: true,
      presenceDataProvider: () => {
        'role': 'player',
        'activeSheetTag': 'PLAYER',
        'localSheetTags': ['PLAYER'],
      },
      onEvent: (event, payload) {
        if (event == 'initiative_shared' && !restored.isCompleted) {
          restored.complete(payload);
        }
      },
      onPresenceChanged: (_) {},
      onStatusChanged: printOnFailure,
    );
    addTearDown(service.dispose);

    await service.connect();
    final payload = await restored.future.timeout(const Duration(seconds: 5));
    expect(payload['restoredSnapshot'], isTrue);
    expect(payload['snapshot'], {'round': 4, 'turnCount': 3});
    expect(payload['authenticatedUserId'], 'owner');
    await service.refreshPresence();
    expect(backend.initiativeSnapshotReads, 1);
  });

  test(
    'large sheets travel in bounded chunks and import only when complete',
    () async {
      final previous = OculumRealtimeService.supabaseAvailable;
      OculumRealtimeService.supabaseAvailable = true;
      addTearDown(() => OculumRealtimeService.supabaseAvailable = previous);
      final client = _Client();
      await client.auth.signInAnonymously();
      final received = <Map<String, dynamic>>[];
      final service = OculumRealtimeService(
        client: client,
        roomId: 'large',
        playerName: 'Hoshy',
        onEvent: (event, payload) {
          if (event == 'sheet_shared') received.add(payload);
        },
        onPresenceChanged: (_) {},
        onStatusChanged: (status) => printOnFailure(status),
      );
      addTearDown(service.dispose);
      await service.connect();
      final sheet = {'nome': 'Hoshy', 'imageBase64': 'x' * 300000};
      expect(
        await service.sendSharedSheetConfirmed(
          sheet: sheet,
          campaignId: 'campaign',
          campaignName: 'Campaign',
          sheetId: 'OWNER',
          sheetName: 'Hoshy',
          ownerTag: 'OWNER',
          senderRole: 'player',
          targetAudience: 'master_coMaster',
          fromMaster: false,
          masterParty: false,
          deliveryId: 'receipt',
        ),
        isTrue,
      );
      final parts = client.testChannel.broadcasts;
      expect(parts.length, greaterThan(1));
      expect(
        parts.every((part) => part['event'] == 'sheet_shared_chunk'),
        isTrue,
      );
      for (final part in parts.skip(1).toList().reversed) {
        client.testChannel.callbacks['sheet_shared_chunk']!({
          'serverEventId': part['id'],
        });
        await Future<void>.delayed(Duration.zero);
        expect(received, isEmpty);
      }
      client.testChannel.callbacks['sheet_shared_chunk']!({
        'serverEventId': parts.first['id'],
      });
      final assemblyDeadline = DateTime.now().add(const Duration(seconds: 3));
      while (received.isEmpty && DateTime.now().isBefore(assemblyDeadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(received, hasLength(1));
      expect(received.single['sheet'], sheet);
      expect(received.single['deliveryId'], 'receipt');
      client.testChannel.response = ChannelResponse.error;
      expect(
        await service.sendSharedSheetConfirmed(
          sheet: sheet,
          campaignId: 'campaign',
          campaignName: 'Campaign',
          sheetId: 'OWNER',
          sheetName: 'Hoshy',
          ownerTag: 'OWNER',
          senderRole: 'player',
          targetAudience: 'master_coMaster',
          fromMaster: false,
          masterParty: false,
        ),
        isFalse,
      );
    },
  );
  test('friend reconnect changes signature without presence refresh churn', () {
    const user = {
      'localSheetTags': ['ABC'],
      'sessionId': 'one',
    };
    expect(
      oculumRealtimePresenceTagSignature([user]),
      oculumRealtimePresenceTagSignature([
        {...user, 'joinedAt': 'later'},
      ]),
    );
    expect(
      oculumRealtimePresenceTagSignature([user]),
      isNot(
        oculumRealtimePresenceTagSignature([
          {...user, 'sessionId': 'two'},
        ]),
      ),
    );
  });

  test(
    'changing from player to summon changes delivery identity without refresh churn',
    () {
      const user = {
        'sessionId': 'same',
        'localSheetTags': ['PG', 'EYE'],
        'activeSheetTag': 'PG',
      };
      final before = oculumRealtimePresenceTagSignature([user]);
      expect(
        oculumRealtimePresenceTagSignature([
          {...user, 'activeSheetTag': 'EYE'},
        ]),
        isNot(before),
      );
      expect(
        oculumRealtimePresenceTagSignature([
          {...user, 'joinedAt': 'later'},
        ]),
        before,
      );
    },
  );

  test('concurrent connect is shared and resubscribe publishes once', () async {
    final previous = OculumRealtimeService.supabaseAvailable;
    OculumRealtimeService.supabaseAvailable = true;
    addTearDown(() => OculumRealtimeService.supabaseAvailable = previous);
    final client = _Client();
    var connected = 0;
    final service = OculumRealtimeService(
      client: client,
      roomId: 'test',
      playerName: 'Test',
      onEvent: (_, _) {},
      onPresenceChanged: (_) {},
      onStatusChanged: (_) {},
      onConnected: () => connected++,
    );
    addTearDown(service.dispose);
    await Future.wait([service.connect(), service.connect()]);
    expect(client.channelCount, 1);
    expect(connected, 1);
    client.testChannel.subscription!(RealtimeSubscribeStatus.subscribed, null);
    await Future<void>.delayed(Duration.zero);
    expect(connected, 1);
    client.testChannel.subscription!(
      RealtimeSubscribeStatus.channelError,
      'offline',
    );
    client.testChannel.subscription!(RealtimeSubscribeStatus.subscribed, null);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(connected, 2);
    client.testChannel.pendingSend = Completer<ChannelResponse>();
    final sending = service.sendSharedSheetConfirmed(
      sheet: {'nome': 'Test'},
      campaignId: 'test',
      campaignName: 'Test',
      sheetId: 'test',
      sheetName: 'Test',
      ownerTag: 'test',
      senderRole: 'player',
      targetAudience: 'master_coMaster',
      fromMaster: false,
      masterParty: false,
    );
    await Future<void>.delayed(Duration.zero);
    await service.disconnect();
    client.testChannel.pendingSend!.complete(ChannelResponse.ok);
    expect(await sending, isFalse);
  });

  test('Master promotion and a returning session trigger a new delivery', () {
    const player = {'role': 'player', 'sessionId': 'one'};
    const master = {'role': 'master', 'sessionId': 'one'};
    const returning = {'role': 'master', 'sessionId': 'two'};
    expect(oculumRealtimeStaffPresenceSignature([player]), isEmpty);
    expect(oculumRealtimeStaffPresenceSignature([master]), isNotEmpty);
    expect(
      oculumRealtimeStaffPresenceSignature([master]),
      isNot(oculumRealtimeStaffPresenceSignature([returning])),
    );
    expect(
      oculumRealtimeStaffPresenceSignature([master, returning]),
      oculumRealtimeStaffPresenceSignature([returning, master, master]),
    );
    expect(
      oculumRealtimeStaffPresenceSignature([
        {...master, 'joinedAt': 'later'},
      ]),
      oculumRealtimeStaffPresenceSignature([master]),
    );
  });

  test(
    'sheet delivery rejects channel errors and timeouts, then recovers',
    () async {
      final previousAvailability = OculumRealtimeService.supabaseAvailable;
      OculumRealtimeService.supabaseAvailable = true;
      addTearDown(
        () => OculumRealtimeService.supabaseAvailable = previousAvailability,
      );
      final client = _Client();
      final statuses = <String>[];
      final service = OculumRealtimeService(
        client: client,
        roomId: 'isolated-test',
        playerName: 'Test',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: statuses.add,
      );
      addTearDown(service.dispose);
      await service.connect();
      expect(service.isConnected, isTrue, reason: statuses.join('\n'));
      for (final response in [
        ChannelResponse.error,
        ChannelResponse.timedOut,
        ChannelResponse.ok,
      ]) {
        client.testChannel.response = response;
        final delivered = await service.sendSharedSheetConfirmed(
          sheet: {'nome': 'Test'},
          campaignId: 'test',
          campaignName: 'Test',
          sheetId: 'test',
          sheetName: 'Test',
          ownerTag: 'test',
          senderRole: 'player',
          targetAudience: 'master_coMaster',
          fromMaster: false,
          masterParty: false,
        );
        expect(delivered, response == ChannelResponse.ok);
      }
      expect(
        statuses.where((s) => s.startsWith('Invio realtime fallito')),
        hasLength(2),
      );
    },
  );
}
