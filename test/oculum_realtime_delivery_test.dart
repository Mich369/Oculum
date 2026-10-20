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
          } else if (path.endsWith('/oculum_open_room')) {
            final input = jsonDecode(request.body) as Map;
            body = {
              'roomId': 'room',
              'role': input['p_as_master'] == true ? 'master' : 'player',
              'status': 'approved',
            };
          } else if (path.endsWith('/oculum_touch_room_session')) {
            final input = jsonDecode(request.body) as Map;
            backend.sessions['${input['p_session']}'] =
                Map<String, dynamic>.from(input['p_presence'] as Map);
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
            body = <dynamic>[];
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
  final sessions = <String, Map<String, dynamic>>{};
  final events = <Map<String, dynamic>>[];
  int initiativeSnapshotReads = 0;
}

void main() {
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
      ]).timeout(const Duration(seconds: 8));
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
      await Future<void>.delayed(const Duration(milliseconds: 20));
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
