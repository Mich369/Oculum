import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const room = String.fromEnvironment('CrossPlatformRoom');
  test(
    'Windows realtime and Chrome HTTPS polling exchange a sheet and reconnect',
    () async {
      final client = SupabaseClient(
        oculumConfiguredSupabaseUrl,
        oculumConfiguredSupabasePublishableKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      OculumRealtimeService.supabaseAvailable = true;
      final received = <String, Completer<void>>{
        'first': Completer<void>(),
        'again': Completer<void>(),
      };
      final sheet = {
        'nome': 'Prova Windows ↔ web',
        'imageBase64': 'x' * 300000,
        'diario': 'Occhio, città e volontà — 保存',
        'inventario': [
          {'nome': 'Scudo', 'quantita': 2},
        ],
      };
      late OculumRealtimeService service;
      service = OculumRealtimeService(
        client: client,
        roomId: room,
        playerName: kIsWeb ? 'Chrome Player' : 'Windows Master',
        httpPollingOnly: kIsWeb,
        onAccessRequested: (_, _) async => true,
        presenceDataProvider: () => {
          'role': kIsWeb ? 'player' : 'master',
          'platform': kIsWeb ? 'web' : 'windows',
          'protocolVersion': 3,
          'activeSheetTag': kIsWeb ? 'WEB_PLAYER' : 'WINDOWS_MASTER',
          'localSheetTags': [kIsWeb ? 'WEB_PLAYER' : 'WINDOWS_MASTER'],
        },
        onPresenceChanged: (_) {},
        onStatusChanged: debugPrint,
        onEvent: (event, payload) {
          final id = '${payload['deliveryId']}';
          if (!received.containsKey(id)) return;
          if (!kIsWeb && event == 'sheet_shared') {
            expect(payload['sheet'], sheet);
            unawaited(
              service.sendSheetReceivedAck(
                deliveryId: id,
                ownerTag: 'WEB_PLAYER',
                sheetId: 'WEB_PLAYER',
                sheetName: 'Cross',
                campaignId: room,
                campaignName: 'Synthetic verification',
                receiverRole: 'master',
                receiverTag: 'WINDOWS_MASTER',
              ),
            );
            if (!received[id]!.isCompleted) received[id]!.complete();
          } else if (kIsWeb && event == 'sheet_received_ack') {
            expect(payload['authenticatedRole'], 'master');
            if (!received[id]!.isCompleted) received[id]!.complete();
          }
        },
      );
      addTearDown(() async {
        await service.dispose();
        await client.dispose();
      });
      await service.connect();
      expect(service.isConnected, isTrue);
      if (kIsWeb) {
        for (final id in ['first', 'again']) {
          expect(
            await service.sendSharedSheetConfirmed(
              sheet: sheet,
              campaignId: room,
              campaignName: 'Synthetic verification',
              sheetId: 'WEB_PLAYER',
              sheetName: 'Cross',
              ownerTag: 'WEB_PLAYER',
              senderRole: 'player',
              targetAudience: 'master_coMaster',
              fromMaster: false,
              masterParty: false,
              deliveryId: id,
            ),
            isTrue,
          );
          await received[id]!.future.timeout(const Duration(seconds: 45));
          if (id == 'first') {
            await service.disconnect();
            await service.connect();
          }
        }
      } else {
        await Future.wait(
          received.values.map((value) => value.future),
        ).timeout(const Duration(minutes: 4));
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
    skip: room.isEmpty
        ? 'Imposta CrossPlatformRoom per eseguire la prova online reale.'
        : false,
  );
}
