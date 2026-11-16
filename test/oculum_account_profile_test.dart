import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oculum/services/oculum_account_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Backend implements OculumAccountProfileBackend {
  OculumAccountProfile? profile;
  Future<OculumAccountProfile?>? pendingFetch;
  Future<OculumAccountProfile>? pendingSave;
  Object? loadError;
  Object? saveError;
  final writes = <(String, String?, String?)>[];

  @override
  Future<OculumAccountProfile?> fetch(String accountId) async {
    if (loadError case final error?) throw error;
    if (pendingFetch case final pending?) return pending;
    return profile;
  }

  @override
  Future<OculumAccountProfile> claim(
    String accountId, {
    String? username,
    String? publicCode,
  }) async {
    writes.add((accountId, username, publicCode));
    if (saveError case final error?) throw error;
    if (pendingSave case final pending?) return pending;
    return profile = OculumAccountProfile(
      userId: accountId,
      username: username ?? profile!.username,
      publicCode: publicCode ?? profile?.publicCode,
    );
  }
}

Widget _app(
  _Backend backend, {
  String accountId = 'one',
  bool verified = true,
}) => MaterialApp(
  theme: ThemeData(splashFactory: NoSplash.splashFactory),
  home: Scaffold(
    body: SingleChildScrollView(
      child: OculumAccountProfilePanel(
        accountId: accountId,
        canClaimPublicCode: verified,
        backend: backend,
      ),
    ),
  ),
);

const _one = OculumAccountProfile(
  userId: 'one',
  username: 'Primo profilo',
  publicCode: 'PrimoCodice',
);
const _two = OculumAccountProfile(
  userId: 'two',
  username: 'Secondo profilo',
  publicCode: 'SecondoCodice',
);

void main() {
  final username = find.widgetWithText(TextFormField, 'Nome utente');
  final code = find.widgetWithText(
    TextFormField,
    'Codice pubblico del profilo',
  );
  final save = find.widgetWithText(OutlinedButton, 'Salva profilo pubblico');
  final reload = find.widgetWithText(OutlinedButton, 'Ricarica profilo');

  testWidgets('invalid fields never write and valid values keep their case', (
    tester,
  ) async {
    final backend = _Backend();
    await tester.pumpWidget(_app(backend));
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Inserisci un nome utente.'), findsOneWidget);
    await tester.enterText(username, '  Nómé Oculum  ');
    await tester.enterText(code, '-bad');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(backend.writes, isEmpty);
    await tester.enterText(code, '  Codice_1-3  ');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(backend.writes, [('one', 'Nómé Oculum', 'Codice_1-3')]);
    expect(find.text('Nome utente: Nómé Oculum'), findsOneWidget);
    expect(
      find.text('Codice pubblico del profilo: Codice_1-3'),
      findsOneWidget,
    );
    expect(username, findsNothing);
    expect(code, findsNothing);
    expect(save, findsNothing);
  });

  testWidgets('verification unlocks only the unclaimed public code', (
    tester,
  ) async {
    final backend = _Backend();
    await tester.pumpWidget(_app(backend, verified: false));
    await tester.pumpAndSettle();
    expect(code, findsNothing);
    expect(
      find.text('Verifica l’email per scegliere il codice pubblico.'),
      findsOneWidget,
    );
    await tester.enterText(username, 'Nome fisso');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(backend.writes, [('one', 'Nome fisso', null)]);

    await tester.pumpWidget(_app(backend));
    await tester.pumpAndSettle();
    expect(username, findsNothing);
    await tester.enterText(code, 'Nuovo_1');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(backend.writes.last, ('one', null, 'Nuovo_1'));
  });

  testWidgets('duplicate code can be corrected without losing draft', (
    tester,
  ) async {
    final backend = _Backend()
      ..saveError = const PostgrestException(message: 'private', code: '23505');
    await tester.pumpWidget(_app(backend));
    await tester.pumpAndSettle();
    await tester.enterText(username, 'Nome riservato');
    await tester.enterText(code, 'Esistente');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Questo codice pubblico è già in uso.'), findsOneWidget);
    expect(find.text('private'), findsNothing);
    expect(reload, findsNothing);

    backend.saveError = null;
    await tester.enterText(code, 'Libero');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(backend.writes.last, ('one', 'Nome riservato', 'Libero'));
  });

  testWidgets('a lost save response is reconciled before another write', (
    tester,
  ) async {
    final backend = _Backend()..saveError = TimeoutException('test');
    await tester.pumpWidget(_app(backend));
    await tester.pumpAndSettle();
    await tester.enterText(username, _one.username);
    await tester.enterText(code, _one.publicCode!);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(save, findsNothing);
    backend.profile = _one;
    await tester.tap(reload);
    await tester.pumpAndSettle();
    expect(find.text('Nome utente: ${_one.username}'), findsOneWidget);
    expect(backend.writes, hasLength(1));
  });

  testWidgets('missing migration allows a retry without exposing error text', (
    tester,
  ) async {
    final backend = _Backend()
      ..loadError = const PostgrestException(
        message: 'private',
        code: 'PGRST205',
      );
    await tester.pumpWidget(_app(backend));
    await tester.pumpAndSettle();
    expect(
      find.text('Il profilo pubblico è temporaneamente indisponibile.'),
      findsOneWidget,
    );
    expect(find.text('private'), findsNothing);
    expect(save, findsNothing);
    backend.loadError = null;
    backend.profile = _one;
    await tester.tap(reload);
    await tester.pumpAndSettle();
    expect(find.text('Nome utente: ${_one.username}'), findsOneWidget);
  });

  testWidgets('a late read from the previous account is ignored', (
    tester,
  ) async {
    final pending = Completer<OculumAccountProfile?>();
    final backend = _Backend()..pendingFetch = pending.future;
    await tester.pumpWidget(_app(backend));
    await tester.pump();
    backend.pendingFetch = null;
    backend.profile = _two;
    await tester.pumpWidget(_app(backend, accountId: 'two'));
    await tester.pumpAndSettle();
    pending.complete(_one);
    await tester.pumpAndSettle();
    expect(find.text('Nome utente: ${_two.username}'), findsOneWidget);
    expect(find.text('Nome utente: ${_one.username}'), findsNothing);
  });

  testWidgets('a repeated tap and a late write cannot cross account views', (
    tester,
  ) async {
    final pending = Completer<OculumAccountProfile>();
    final backend = _Backend()..pendingSave = pending.future;
    await tester.pumpWidget(_app(backend));
    await tester.pumpAndSettle();
    await tester.enterText(username, _one.username);
    await tester.tap(save);
    await tester.tap(save);
    await tester.pump();
    expect(backend.writes, hasLength(1));
    backend.profile = _two;
    await tester.pumpWidget(_app(backend, accountId: 'two'));
    await tester.pumpAndSettle();
    pending.complete(_one);
    await tester.pumpAndSettle();
    expect(find.text('Nome utente: ${_two.username}'), findsOneWidget);
    expect(find.text('Nome utente: ${_one.username}'), findsNothing);
  });

  test(
    'production transport restricts reads and passes expected UUID',
    () async {
      final calls = <http.Request>[];
      const profile = {
        'user_id': 'account-uuid',
        'username': 'Nome scelto',
        'public_code': 'Codice_1',
      };
      final client = SupabaseClient(
        'https://isolated-test.supabase.co',
        'public-test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          calls.add(request);
          final body = switch (request.url.path) {
            '/auth/v1/token' => {
              'access_token': 'test-session',
              'refresh_token': 'test-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': 'account-uuid',
                'aud': 'authenticated',
                'created_at': '2026-11-14T00:00:00Z',
              },
            },
            '/rest/v1/oculum_account_profiles' => [profile],
            _ => profile,
          };
          return http.Response(
            jsonEncode(body),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'owner@example.test',
        password: 'only-test-password',
      );
      final backend = SupabaseOculumAccountProfileBackend(client);
      expect((await backend.fetch('account-uuid'))?.username, 'Nome scelto');
      final result = await backend.claim(
        'account-uuid',
        publicCode: 'Codice_1',
      );
      expect(result.publicCode, 'Codice_1');
      expect(calls[1].url.queryParameters['user_id'], 'eq.account-uuid');
      expect(calls[2].url.path, '/rest/v1/rpc/oculum_claim_account_profile');
      expect(jsonDecode(calls[2].body), {
        'p_expected_user_id': 'account-uuid',
        'p_username': null,
        'p_public_code': 'Codice_1',
      });
      await expectLater(backend.claim('wrong-uuid'), throwsException);
      expect(calls, hasLength(3));
    },
  );
}
