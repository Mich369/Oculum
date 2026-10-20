import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oculum/services/oculum_chunk_recovery.dart';

class _TrackedClient extends MockClient {
  _TrackedClient(super.handler);
  bool closed = false;
  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  final parameters = <String, dynamic>{
    'p_event': 'sheet_shared_chunk',
    'p_room': 'room',
    'p_session': 'device-session',
    'p_payload': {
      'transferId': 'same-transfer',
      'chunkIndex': 7,
      'data': 'part',
    },
  };
  test(
    'chunk recovery preserves identity, chunk and current authentication',
    () async {
      final client = _TrackedClient((request) async {
        expect(
          request.url.toString(),
          'https://example.supabase.co/rest/v1/rpc/oculum_emit_room_event',
        );
        expect(request.headers['Authorization'], 'Bearer current-session');
        expect(request.headers['apikey'], 'publishable');
        expect(jsonDecode(request.body), parameters);
        return http.Response('"server-confirmation"', 200);
      });
      expect(
        await oculumRecoverSheetChunk(
          restUrl: 'https://example.supabase.co/rest/v1',
          headers: {
            'apikey': 'publishable',
            'Authorization': 'Bearer old-session',
          },
          accessToken: 'current-session',
          parameters: parameters,
          clientFactory: () => client,
        ),
        'server-confirmation',
      );
      expect(client.closed, isTrue);
    },
  );
  test(
    'fresh connection closes on timeout and denial is never success',
    () async {
      final client = _TrackedClient((_) => Completer<http.Response>().future);
      await expectLater(
        oculumRecoverSheetChunk(
          restUrl: 'https://example.supabase.co/rest/v1',
          headers: {},
          accessToken: 'session',
          parameters: parameters,
          clientFactory: () => client,
          timeout: const Duration(milliseconds: 5),
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(client.closed, isTrue);
      final denied = _TrackedClient((_) async => http.Response('{}', 403));
      await expectLater(
        oculumRecoverSheetChunk(
          restUrl: 'https://example.supabase.co/rest/v1',
          headers: {},
          accessToken: 'session',
          parameters: parameters,
          clientFactory: () => denied,
        ),
        throwsA(isA<http.ClientException>()),
      );
      expect(denied.closed, isTrue);
    },
  );
  test(
    'combat actions and unauthenticated requests cannot use chunk recovery',
    () async {
      for (final event in ['combat_attack', 'combat_help', 'combat_defense']) {
        await expectLater(
          oculumRecoverSheetChunk(
            restUrl: 'https://example.supabase.co/rest/v1',
            headers: {},
            accessToken: 'session',
            parameters: {...parameters, 'p_event': event},
          ),
          throwsArgumentError,
        );
      }
      await expectLater(
        oculumRecoverSheetChunk(
          restUrl: 'https://example.supabase.co/rest/v1',
          headers: {},
          accessToken: '',
          parameters: parameters,
        ),
        throwsArgumentError,
      );
    },
  );
}
