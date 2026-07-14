import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test(
    'la configurazione Supabase predefinita è valida e pronta alle build',
    () {
      expect(
        oculumSupabaseConfigurationIsValid(
          url: oculumConfiguredSupabaseUrl,
          publishableKey: oculumConfiguredSupabasePublishableKey,
        ),
        isTrue,
      );
    },
  );

  test('rifiuta endpoint non HTTPS e chiavi client non riconosciute', () {
    expect(
      oculumSupabaseConfigurationIsValid(
        url: 'http://example.com',
        publishableKey: 'not-a-client-key',
      ),
      isFalse,
    );
  });

  test('mantiene compatibilità con le vecchie anon key JWT', () {
    expect(
      oculumSupabaseConfigurationIsValid(
        url: 'https://project-ref.supabase.co',
        publishableKey: 'eyJheader.payload.signature',
      ),
      isTrue,
    );
  });
}
