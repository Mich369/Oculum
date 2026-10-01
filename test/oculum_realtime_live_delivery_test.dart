import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _runLive = bool.fromEnvironment('OculumLiveRealtimeTest');

void main() {
  test(
    'two real Supabase clients deliver large sheets, peer ACK and reconnect',
    () async {
      final room = 'verify_${DateTime.now().microsecondsSinceEpoch}';
      final playerClient = SupabaseClient(
        oculumConfiguredSupabaseUrl,
        oculumConfiguredSupabasePublishableKey,
      );
      final masterClient = SupabaseClient(
        oculumConfiguredSupabaseUrl,
        oculumConfiguredSupabasePublishableKey,
      );
      final previous = OculumRealtimeService.supabaseAvailable;
      OculumRealtimeService.supabaseAvailable = true;
      final firstReceived = Completer<Map<String, dynamic>>();
      final acknowledged = Completer<void>();
      final reconnectedReceived = Completer<Map<String, dynamic>>();
      var sendPeerAck = false;
      late OculumRealtimeService master;
      master = OculumRealtimeService(
        client: masterClient,
        roomId: room,
        playerName: 'Synthetic Master',
        presenceDataProvider: () => {'role': 'master'},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
        onEvent: (event, payload) {
          if (event != 'sheet_shared') return;
          if (payload['deliveryId'] == 'after_reconnect') {
            if (!reconnectedReceived.isCompleted) {
              reconnectedReceived.complete(payload);
            }
          } else {
            if (!firstReceived.isCompleted) firstReceived.complete(payload);
            if (sendPeerAck) {
              unawaited(
                master.sendSheetReceivedAck(
                  deliveryId: 'synthetic_receipt',
                  ownerTag: 'SYNTHETIC_PLAYER',
                  sheetId: 'SYNTHETIC_PLAYER',
                  sheetName: 'Synthetic sheet',
                  campaignId: room,
                  campaignName: 'Disposable verification',
                  receiverRole: 'master',
                  receiverTag: 'SYNTHETIC_MASTER',
                ),
              );
            }
          }
        },
      );
      final player = OculumRealtimeService(
        client: playerClient,
        roomId: room,
        playerName: 'Synthetic Player',
        presenceDataProvider: () => {'role': 'player'},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
        onEvent: (event, payload) {
          if (event == 'sheet_received_ack' &&
              payload['deliveryId'] == 'synthetic_receipt' &&
              !acknowledged.isCompleted) {
            acknowledged.complete();
          }
        },
      );
      addTearDown(() async {
        await player.dispose();
        await master.dispose();
        await playerClient.dispose();
        await masterClient.dispose();
        OculumRealtimeService.supabaseAvailable = previous;
      });
      await Future.wait([master.connect(), player.connect()]);
      expect(master.isConnected, isTrue);
      expect(player.isConnected, isTrue);
      final sheet = <String, dynamic>{
        'nome': 'Synthetic sheet',
        'imageBase64': 'x' * 500000,
        'inventario': [
          {'nome': 'Synthetic item', 'quantita': 3},
        ],
        'derivedCM': 12,
        'derivedVC': 7,
        'derivedDifesa': 9,
        'derivedDanno': 14,
      };
      Future<bool> send(String deliveryId) => player.sendSharedSheetConfirmed(
        sheet: sheet,
        campaignId: room,
        campaignName: 'Disposable verification',
        sheetId: 'SYNTHETIC_PLAYER',
        sheetName: 'Synthetic sheet',
        ownerTag: 'SYNTHETIC_PLAYER',
        senderRole: 'player',
        targetAudience: 'master_coMaster',
        fromMaster: false,
        masterParty: false,
        deliveryId: deliveryId,
      );
      expect(await send('synthetic_receipt'), isTrue);
      final received = await firstReceived.future.timeout(
        const Duration(seconds: 20),
      );
      expect(received['sheet'], sheet);
      expect(
        acknowledged.isCompleted,
        isFalse,
        reason: 'Server ACK is not peer receipt.',
      );
      sendPeerAck = true;
      expect(await send('synthetic_receipt'), isTrue);
      await acknowledged.future.timeout(const Duration(seconds: 20));
      await master.disconnect();
      await master.connect();
      expect(master.isConnected, isTrue);
      expect(await send('after_reconnect'), isTrue);
      expect(
        (await reconnectedReceived.future.timeout(
          const Duration(seconds: 20),
        ))['sheet'],
        sheet,
      );
    },
    skip: _runLive
        ? false
        : 'Opt in with OculumLiveRealtimeTest=true; synthetic temporary room only.',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
