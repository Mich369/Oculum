import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _runLive = bool.fromEnvironment('OculumLiveRealtimeTest');

class _LiveNetwork extends HttpOverrides {}

Future<T> _within<T>(Future<T> future, String label) => future.timeout(
  const Duration(seconds: 45),
  onTimeout: () => throw TimeoutException('$label non ricevuto.'),
);

void main() {
  test(
    'player sheet reaches the authenticated Master and gets a receipt ACK',
    () async {
      if (!_runLive) {
        markTestSkipped('Richiede --dart-define=OculumLiveRealtimeTest=true');
      }

      final suffix = DateTime.now().microsecondsSinceEpoch;
      final room = 'sheet_delivery_$suffix';
      final playerTag = 'PLAYER-$suffix';
      final masterTag = 'MASTER-$suffix';
      final masterClient = HttpOverrides.runWithHttpOverrides(
        () => SupabaseClient(
          oculumConfiguredSupabaseUrl,
          oculumConfiguredSupabasePublishableKey,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
        _LiveNetwork(),
      );
      final playerClient = HttpOverrides.runWithHttpOverrides(
        () => SupabaseClient(
          oculumConfiguredSupabaseUrl,
          oculumConfiguredSupabasePublishableKey,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
        _LiveNetwork(),
      );
      final oldAvailable = OculumRealtimeService.supabaseAvailable;
      OculumRealtimeService.supabaseAvailable = true;
      final received = Completer<Map<String, dynamic>>();
      final acknowledged = Completer<Map<String, dynamic>>();
      late final OculumRealtimeService master;
      master = OculumRealtimeService(
        client: masterClient,
        roomId: room,
        playerName: 'Verifica Master',
        presenceDataProvider: () => {
          'role': 'master',
          'activeSheetTag': masterTag,
          'localSheetTags': [masterTag],
          'campaignId': 'live-sheet-$suffix',
        },
        onAccessRequested: (_, _) async => true,
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
        onEvent: (event, payload) {
          if (event == 'sheet_shared' && !received.isCompleted) {
            received.complete(Map<String, dynamic>.from(payload));
          }
        },
      );
      final player = OculumRealtimeService(
        client: playerClient,
        roomId: room,
        playerName: 'Verifica Player',
        presenceDataProvider: () => {
          'role': 'player',
          'activeSheetTag': playerTag,
          'localSheetTags': [playerTag],
          'campaignId': 'live-sheet-$suffix',
        },
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
        onEvent: (event, payload) {
          if (event == 'sheet_received_ack' && !acknowledged.isCompleted) {
            acknowledged.complete(Map<String, dynamic>.from(payload));
          }
        },
      );

      try {
        await master.connect();
        expect(master.isConnected, isTrue);
        await player.connect();
        expect(player.isConnected, isTrue);
        expect(
          masterClient.auth.currentUser!.id,
          isNot(playerClient.auth.currentUser!.id),
        );

        final deliveryId = 'receipt-$suffix';
        expect(
          await player.sendSharedSheetConfirmed(
            sheet: {
              'id': playerTag,
              'sheetTag': playerTag,
              'nome': 'Esploratore online',
              'publicAccountDisplayName': 'Account di prova',
              'publicVisibleTitleName': 'Titolo di prova',
              'currentHp': '42',
            },
            campaignId: 'live-sheet-$suffix',
            campaignName: 'Verifica consegna schede',
            sheetId: playerTag,
            sheetName: 'Esploratore online',
            ownerTag: playerTag,
            senderRole: 'player',
            targetAudience: 'master_coMaster',
            fromMaster: false,
            masterParty: false,
            deliveryId: deliveryId,
          ),
          isTrue,
        );

        final packet = await _within(received.future, 'Scheda del player');
        expect(packet['senderRole'], 'player');
        expect(packet['sheetId'], playerTag);
        expect(packet['deliveryId'], deliveryId);
        expect(
          (packet['sheet'] as Map)['publicAccountDisplayName'],
          'Account di prova',
        );
        await master.sendSheetReceivedAck(
          deliveryId: deliveryId,
          ownerTag: playerTag,
          sheetId: playerTag,
          sheetName: 'Esploratore online',
          campaignId: 'live-sheet-$suffix',
          campaignName: 'Verifica consegna schede',
          receiverRole: 'master',
          receiverTag: masterTag,
        );
        final receipt = await _within(acknowledged.future, 'ACK del Master');
        expect(receipt['deliveryId'], deliveryId);
        expect(receipt['receiverRole'], 'master');
        expect(receipt['ownerTag'], playerTag);
      } finally {
        await player.dispose();
        await master.dispose();
        await playerClient.dispose();
        await masterClient.dispose();
        OculumRealtimeService.supabaseAvailable = oldAvailable;
      }
    },
    skip: !_runLive,
  );
}
