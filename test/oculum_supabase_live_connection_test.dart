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
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      try {
        final baseUri = Uri.parse(oculumConfiguredSupabaseUrl);
        final request = await client
            .getUrl(baseUri.resolve('/auth/v1/settings'))
            .timeout(const Duration(seconds: 15));
        request.headers.set('apikey', oculumConfiguredSupabasePublishableKey);

        final response = await request.close().timeout(
          const Duration(seconds: 15),
        );
        final responseBody = await utf8.decoder.bind(response).join();

        expect(
          response.statusCode,
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
      } finally {
        client.close(force: true);
      }
    },
    skip: _runLiveSupabaseTest
        ? false
        : 'Abilitare con --dart-define=OculumLiveSupabaseTest=true.',
  );
}
