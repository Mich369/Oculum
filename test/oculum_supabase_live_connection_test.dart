import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

const bool _runLiveSupabaseTest = bool.fromEnvironment(
  'OculumLiveSupabaseTest',
);

void main() {
  test(
    'la configurazione compilata raggiunge Supabase Auth',
    () async {
      final baseUri = Uri.parse(oculumConfiguredSupabaseUrl);
      int? responseStatus;
      String responseBody = '';
      Object? transportFailure;
      for (var attempt = 0; attempt < 3; attempt++) {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 20);
        try {
          final result = await (() async {
            final request = await client.getUrl(
              baseUri.resolve('/auth/v1/settings'),
            );
            request.headers.set(
              'apikey',
              oculumConfiguredSupabasePublishableKey,
            );
            final response = await request.close();
            final body = await utf8.decoder.bind(response).join();
            return (status: response.statusCode, body: body);
          })().timeout(const Duration(seconds: 25));
          responseStatus = result.status;
          responseBody = result.body;
          transportFailure = null;
          break;
        } on TimeoutException catch (error) {
          transportFailure = error;
        } on IOException catch (error) {
          transportFailure = error;
        } finally {
          // Future.timeout alone does not cancel the underlying socket.
          client.close(force: true);
        }
        if (attempt < 2) {
          await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
        }
      }

      expect(
        responseStatus,
        isNotNull,
        reason:
            'Supabase Auth non ha risposto dopo 3 tentativi. '
            'Ultimo errore di trasporto: $transportFailure',
      );

      expect(
        responseStatus,
        HttpStatus.ok,
        reason:
            'Supabase Auth non raggiungibile con la configurazione compilata. '
            'Risposta: $responseBody',
      );
      expect(
        jsonDecode(responseBody),
        isA<Map<String, dynamic>>(),
        reason: 'Supabase Auth deve restituire impostazioni JSON valide.',
      );
    },
    timeout: const Timeout(Duration(seconds: 100)),
    skip: _runLiveSupabaseTest
        ? false
        : 'Abilitare con --dart-define=OculumLiveSupabaseTest=true.',
  );
}
