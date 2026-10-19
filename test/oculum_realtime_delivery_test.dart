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
  factory _Client() => _Client._(_Channel());
  _Client._(this.testChannel)
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
            body = {'roomId': 'room', 'role': 'player', 'status': 'approved'};
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
            final id = 'event-${testChannel.broadcasts.length}';
            final payload = Map<String, dynamic>.from(
              input['p_payload'] as Map,
            );
            final routing = payload['_routing'] as Map? ?? payload;
            payload.addAll({
              'authenticatedSheetId': routing['sheetId'],
              'authenticatedRole': 'player',
              'senderRole': 'player',
              'targetAudience': routing['targetAudience'],
            });
            testChannel.broadcasts.add({
              'id': id,
              'event': input['p_event'],
              'payload': payload,
            });
            body = id;
          } else if (path.endsWith('/oculum_room_events')) {
            final eventId = request.url.queryParameters['id'];
            body = eventId == null
                ? <dynamic>[]
                : testChannel.broadcasts.firstWhere(
                    (event) => 'eq.${event['id']}' == eventId,
                  );
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

void main() {
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
