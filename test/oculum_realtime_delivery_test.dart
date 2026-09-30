import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Channel implements RealtimeChannel {
  ChannelResponse response = ChannelResponse.ok;
  Function? subscription;
  Completer<ChannelResponse>? pendingSend;

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
        return pendingSend?.future ?? Future.value(response);
      case #presenceState:
        return <SinglePresenceState>[];
      case #onBroadcast:
      case #onPresenceSync:
      case #onPresenceJoin:
      case #onPresenceLeave:
        return this;
    }
    return super.noSuchMethod(invocation);
  }
}

class _Client implements SupabaseClient {
  final testChannel = _Channel();
  int channelCount = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #channel) {
      channelCount++;
      return testChannel;
    }
    if (invocation.memberName == #removeChannel) return Future.value('ok');
    return super.noSuchMethod(invocation);
  }
}

void main() {
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
    expect(connected, 1);
    client.testChannel.subscription!(
      RealtimeSubscribeStatus.channelError,
      'offline',
    );
    client.testChannel.subscription!(RealtimeSubscribeStatus.subscribed, null);
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
      expect(service.isConnected, isTrue);
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
