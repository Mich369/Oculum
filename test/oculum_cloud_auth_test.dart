import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oculum/services/oculum_auth_service.dart';
import 'package:oculum/services/oculum_auth_ui.dart';
import 'package:oculum/services/oculum_cloud_save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthBackend implements OculumAuthBackend {
  final _events = StreamController<OculumBackendAuthEvent>.broadcast();

  OculumBackendUser? user;
  bool launchResult = true;
  Object? launchError;
  int launchCount = 0;
  int signOutCount = 0;
  Completer<bool>? launchConfirmation;
  Completer<void>? signOutConfirmation;

  @override
  OculumBackendUser? get currentUser => user;

  @override
  Stream<OculumBackendAuthEvent> get events => _events.stream;

  @override
  Future<bool> startOAuth(
    OculumAuthProvider provider, {
    required String? redirectTo,
  }) async {
    launchCount++;
    if (launchError != null) throw launchError!;
    final confirmation = launchConfirmation;
    if (confirmation != null) return confirmation.future;
    return launchResult;
  }

  void emit(OculumBackendAuthEvent event, {bool updateCurrentUser = true}) {
    if (updateCurrentUser) user = event.user;
    _events.add(event);
  }

  void emitError(Object error) => _events.addError(error);

  @override
  Future<void> signOut() async {
    signOutCount++;
    user = null;
    _events.add(
      const OculumBackendAuthEvent(OculumBackendAuthEventType.signedOut),
    );
    await signOutConfirmation?.future;
  }

  Future<void> close() => _events.close();
}

class _FakeEmailBackend extends _FakeAuthBackend
    implements OculumEmailAuthBackend {
  bool? linked;
  String? email;
  String? password;
  String? resetEmail;
  Completer<void>? passwordUpdate;
  Completer<void>? emailResponse;
  int emailVerifications = 0;
  int passwordUpdates = 0;
  @override
  Future<void> signInAnonymously() async {
    user = const OculumBackendUser(
      id: 'protected-guest',
      provider: 'anonymous',
    );
  }

  @override
  Future<void> requestEmail(String email, {required bool linkGuest}) async {
    this.email = email;
    linked = linkGuest;
    await emailResponse?.future;
  }

  @override
  Future<void> linkGuestEmailPassword(String email, String password) async {
    this.email = email;
    this.password = password;
    linked = true;
  }

  @override
  Future<void> signInWithEmailPassword(String email, String password) async {
    this.email = email;
    this.password = password;
    user = const OculumBackendUser(id: 'email-account', provider: 'email');
  }

  @override
  Future<void> setPassword(String password) async {
    passwordUpdates++;
    await passwordUpdate?.future;
    this.password = password;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    resetEmail = email;
  }

  @override
  Future<void> verifyEmail(
    String email,
    String token, {
    required bool linkGuest,
  }) async {
    emailVerifications++;
    if (token != '123456') throw const FormatException('Codice non valido');
    user = OculumBackendUser(
      id: linkGuest ? 'protected-guest' : 'email-account',
      provider: 'email',
    );
  }
}

class _FakeGoogleLinkBackend extends _FakeAuthBackend
    implements OculumIdentityLinkBackend {
  int linkCount = 0;

  @override
  Future<bool> linkGoogle({required String redirectTo}) async {
    linkCount++;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'ospite protetto collega email mantenendo la propria identità',
    () async {
      final backend = _FakeEmailBackend();
      final auth = OculumAuthService.forTesting(
        backend: backend,
        connectivityCheck: () async => true,
      );
      await auth.initialize();
      expect(await auth.signInAsProtectedGuest(), isTrue);
      expect(auth.state.isAuthenticated, isTrue);
      expect(auth.state.isGuest, isTrue);
      expect(auth.state.canSyncToCloud, isFalse);
      expect(
        await auth.linkGuestEmailPassword(
          ' player@example.com ',
          'safe-password',
        ),
        isTrue,
      );
      expect(backend.email, 'player@example.com');
      expect(backend.linked, isTrue);
      expect(backend.password, 'safe-password');
      expect(await auth.verifyEmailAccess('wrong'), isFalse);
      expect(auth.state.userId, 'protected-guest');
      expect(await auth.verifyEmailAccess('123456'), isTrue);
      expect(auth.state.userId, 'protected-guest');
      expect(auth.state.canSyncToCloud, isTrue);
      auth.dispose();
      await backend.close();
    },
  );

  test('email e password permettono accesso multi-dispositivo', () async {
    final backend = _FakeEmailBackend();
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => true,
    );
    await auth.initialize();

    expect(
      await auth.signInWithEmailPassword(
        ' player@example.com ',
        'safe-password',
      ),
      isTrue,
    );
    expect(auth.state.userId, 'email-account');
    expect(auth.state.canSyncToCloud, isTrue);
    expect(backend.email, 'player@example.com');

    auth.dispose();
    await backend.close();
  });

  test('password e reset email restano lato Supabase Auth', () async {
    final backend = _FakeEmailBackend()
      ..user = const OculumBackendUser(id: 'email-account', provider: 'email');
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => true,
    );
    await auth.initialize();

    expect(await auth.setAccountPassword('new-safe-password'), isTrue);
    expect(backend.password, 'new-safe-password');
    expect(await auth.requestPasswordReset(' player@example.com '), isTrue);
    expect(backend.resetEmail, 'player@example.com');
    expect(await auth.setAccountPassword('short'), isFalse);

    auth.dispose();
    await backend.close();
  });

  test('recupero legato al profilo e completabile una sola volta', () async {
    const account = OculumBackendUser(id: 'account', provider: 'email');
    const other = OculumBackendUser(id: 'other', provider: 'email');
    const recovery = OculumBackendAuthEventType.passwordRecovery;
    final backend = _FakeEmailBackend()..user = account;
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => true,
    );
    addTearDown(backend.close);
    addTearDown(auth.dispose);
    await auth.initialize();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('test-local-save', '{"level":7}');
    expect(
      await auth.completePasswordRecovery(account.id, 'password-1'),
      false,
    );
    backend.emit(const OculumBackendAuthEvent(recovery, user: account));
    await pumpEventQueue();
    expect(auth.passwordRecovery.value, account.id);
    expect(await auth.completePasswordRecovery(other.id, 'password-1'), false);
    expect(await auth.completePasswordRecovery(account.id, 'short'), false);
    expect(auth.passwordRecovery.value, account.id);
    backend.passwordUpdate = Completer<void>();
    final update = auth.completePasswordRecovery(account.id, 'password-1');
    expect(
      await auth.completePasswordRecovery(account.id, 'password-2'),
      false,
    );
    auth.dismissPasswordRecovery();
    expect(auth.passwordRecovery.value, account.id);
    backend.passwordUpdate!.complete();
    expect(await update, true);
    expect(auth.passwordRecovery.value, isNull);
    expect(backend.passwordUpdates, 1);
    expect(backend.password, 'password-1');
    expect(prefs.getString('test-local-save'), '{"level":7}');

    backend.emit(const OculumBackendAuthEvent(recovery, user: account));
    await pumpEventQueue();
    backend.emit(
      const OculumBackendAuthEvent(
        OculumBackendAuthEventType.signedIn,
        user: other,
      ),
    );
    await pumpEventQueue();
    expect(auth.passwordRecovery.value, isNull);
    expect(
      await auth.completePasswordRecovery(account.id, 'password-3'),
      false,
    );
    expect(backend.passwordUpdates, 1);
  });

  testWidgets('il link di recupero apre il dialogo dalla pagina corrente', (
    tester,
  ) async {
    const account = OculumBackendUser(id: 'account', provider: 'email');
    final backend = _FakeEmailBackend();
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => true,
    );
    addTearDown(backend.close);
    addTearDown(auth.dispose);
    await tester.runAsync(auth.initialize);
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: ThemeData(splashFactory: InkRipple.splashFactory),
        builder: (context, child) => OculumPasswordRecoveryHost(
          auth: auth,
          navigatorKey: navigatorKey,
          child: child!,
        ),
        home: const Scaffold(body: Text('Scheda locale')),
      ),
    );
    expect(find.text('Reimposta password'), findsNothing);
    backend.emitError(
      const AuthException(
        'Expired',
        statusCode: 'otp_expired',
        code: 'access_denied',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(OculumAuthService.invalidAuthLinkMessage), findsOneWidget);
    expect(find.text('Reimposta password'), findsNothing);
    ScaffoldMessenger.of(
      tester.element(find.text('Scheda locale')),
    ).removeCurrentSnackBar();
    await tester.runAsync(() async {
      backend.emit(
        const OculumBackendAuthEvent(
          OculumBackendAuthEventType.passwordRecovery,
          user: account,
        ),
      );
      await pumpEventQueue();
    });
    await tester.pumpAndSettle();
    expect(find.text('Reimposta password'), findsOneWidget);
    final fields = find.byType(TextField);
    final save = find.text('Aggiorna password');
    await tester.enterText(fields.at(0), 'password-1');
    await tester.enterText(fields.at(1), 'password-2');
    await tester.tap(save);
    await tester.pump();
    expect(find.text('Le password devono coincidere.'), findsOneWidget);
    expect(backend.passwordUpdates, 0);
    await tester.enterText(fields.at(1), 'password-1');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Reimposta password'), findsNothing);
    expect(find.text('Password aggiornata.'), findsOneWidget);
    expect(find.text('Scheda locale'), findsOneWidget);
    expect(backend.passwordUpdates, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
    'mantieni accesso falso non conserva sessioni né token aggiornati',
    () async {
      final storage = OculumSessionStorage(
        persistSessionKey: 'test-auth-token',
        useBrowserStorage: true,
      );
      await storage.initialize();
      await storage.persistSession('synthetic-session');
      expect(await storage.hasAccessToken(), isTrue);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(OculumSessionStorage.rememberKey, false);
      await storage.persistSession('synthetic-refreshed-session');
      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);
      expect(prefs.getString('test-auth-token'), isNull);
    },
  );

  test('avvio Guest senza Supabase resta local-only', () async {
    final auth = OculumAuthService.forTesting(
      connectivityCheck: () async => true,
    );

    await auth.initialize();

    expect(auth.state.isGuest, isTrue);
    expect(auth.state.isAuthenticated, isFalse);
    expect(auth.isSupabaseReady, isFalse);
    auth.dispose();
  });

  test('login riuscito si completa solo dopo evento sessione', () async {
    final backend = _FakeAuthBackend();
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => true,
    );
    await auth.initialize();

    expect(await auth.signInWithGoogle(), isTrue);
    expect(auth.state.isLoading, isTrue);
    expect(auth.state.isAuthenticated, isFalse);

    backend.emit(
      const OculumBackendAuthEvent(
        OculumBackendAuthEventType.signedIn,
        user: OculumBackendUser(id: 'user-1', provider: 'google'),
      ),
    );
    await pumpEventQueue();

    expect(auth.state.isAuthenticated, isTrue);
    expect(auth.state.provider, 'google');
    auth.dispose();
    await backend.close();
  });

  test('login annullato torna a uno stato recuperabile', () async {
    final backend = _FakeAuthBackend();
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => true,
    );
    await auth.initialize();
    await auth.signInWithApple();

    auth.cancelPendingSignIn();

    expect(auth.state.isLoading, isFalse);
    expect(auth.state.errorMessage, contains('annullato'));
    auth.dispose();
    await backend.close();
  });

  test('annullare durante il controllo rete evita di aprire Google', () async {
    final connection = Completer<bool>();
    final backend = _FakeAuthBackend();
    addTearDown(backend.close);
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () => connection.future,
    );
    addTearDown(auth.dispose);
    await auth.initialize();

    final attempt = auth.signInWithGoogle();
    auth.cancelPendingSignIn();
    connection.complete(true);

    expect(await attempt, isFalse);
    expect(backend.launchCount, 0);
    expect(auth.state.errorMessage, contains('annullato'));
  });

  test(
    'un esito del browser precedente lascia attivo il nuovo tentativo',
    () async {
      final oldLaunch = Completer<bool>();
      final backend = _FakeAuthBackend()..launchConfirmation = oldLaunch;
      addTearDown(backend.close);
      final auth = OculumAuthService.forTesting(
        backend: backend,
        connectivityCheck: () async => true,
        oauthTimeout: const Duration(minutes: 1),
      );
      addTearDown(auth.dispose);
      await auth.initialize();

      final oldAttempt = auth.signInWithGoogle();
      await pumpEventQueue();
      expect(backend.launchCount, 1);
      auth.cancelPendingSignIn();
      backend.launchConfirmation = null;
      expect(await auth.retryLastSignIn(), isTrue);
      expect(backend.launchCount, 2);
      oldLaunch.completeError(StateError('Browser precedente chiuso'));

      expect(await oldAttempt, isFalse);
      expect(auth.canCancelSignIn, isTrue);
      expect(auth.state.errorMessage, isNull);
    },
  );

  testWidgets('una sessione Google tardiva dopo il timeout resta locale', (
    tester,
  ) async {
    final backend = _FakeAuthBackend();
    addTearDown(backend.close);
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => true,
      oauthTimeout: const Duration(seconds: 1),
    );
    addTearDown(auth.dispose);
    await auth.initialize();
    expect(await auth.signInWithGoogle(), isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(auth.state.errorMessage, contains('non completato'));

    backend.emit(
      const OculumBackendAuthEvent(
        OculumBackendAuthEventType.signedIn,
        user: OculumBackendUser(id: 'late-user', provider: 'google'),
      ),
    );
    await tester.pump();

    expect(auth.state.isAuthenticated, isFalse);
    expect(backend.signOutCount, 1);
  });

  test('un tentativo Google annullato conserva i rientri email', () async {
    final backend = _FakeAuthBackend();
    addTearDown(backend.close);
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => true,
    );
    addTearDown(auth.dispose);
    await auth.initialize();
    expect(await auth.signInWithGoogle(), isTrue);
    auth.cancelPendingSignIn();

    const emailUser = OculumBackendUser(
      id: 'linked-profile',
      provider: 'email',
      hasVerifiedEmail: true,
      identityProviders: {'email', 'google'},
    );
    backend.emit(
      const OculumBackendAuthEvent(
        OculumBackendAuthEventType.signedIn,
        user: emailUser,
      ),
    );
    await pumpEventQueue();

    expect(auth.state.userId, 'linked-profile');
    expect(auth.state.isAuthenticated, isTrue);
    expect(auth.hasVerifiedEmail, isTrue);
    expect(backend.signOutCount, 0);
  });

  test('provider non configurato non apre il browser', () async {
    final backend = _FakeAuthBackend();
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => true,
      googleConfigured: false,
    );
    await auth.initialize();

    expect(await auth.signInWithGoogle(), isFalse);
    expect(backend.launchCount, 0);
    expect(auth.state.errorMessage, contains('prossimamente'));
    auth.dispose();
    await backend.close();
  });

  test('legge solo le impostazioni pubbliche Google dal progetto', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(
        request.url.toString(),
        'https://fixture.supabase.co/auth/v1/settings',
      );
      expect(request.headers['apikey'], 'sb_publishable_fixture');
      expect(request.headers.containsKey('authorization'), isFalse);
      expect(request.followRedirects, isFalse);
      return http.Response('{"external":{"google":false}}', 200);
    });
    addTearDown(client.close);

    expect(
      await oculumGoogleOAuthExplicitlyDisabled(
        projectUrl: Uri.parse('https://fixture.supabase.co'),
        publishableKey: 'sb_publishable_fixture',
        client: client,
      ),
      isTrue,
    );
  });

  test('risposte sconosciute non bloccano Google', () async {
    for (final (status, body) in [
      (200, '{"external":{"google":true},"disable_signup":true}'),
      (200, '{"external":{}}'),
      (200, '{"external":{"google":null}}'),
      (200, 'pagina temporanea'),
      (503, '{"external":{"google":false}}'),
    ]) {
      final client = MockClient((_) async => http.Response(body, status));
      addTearDown(client.close);
      expect(
        await oculumGoogleOAuthExplicitlyDisabled(
          projectUrl: Uri.parse('https://fixture.supabase.co'),
          publishableKey: 'sb_publishable_fixture',
          client: client,
        ),
        isFalse,
        reason: '$status $body',
      );
    }
  });

  test(
    'il backend ferma OAuth prima del browser se Google è disabilitato',
    () async {
      var requests = 0;
      await http.runWithClient(
        () async {
          final backend = SupabaseOculumAuthBackend(
            projectUrl: Uri.parse('https://fixture.supabase.co'),
            publishableKey: 'sb_publishable_fixture',
          );
          await expectLater(
            backend.startOAuth(
              OculumAuthProvider.google,
              redirectTo: 'com.mich.oculum://login-callback',
            ),
            throwsA(
              isA<AuthException>().having(
                (error) => error.code,
                'code',
                'oculum_google_provider_disabled',
              ),
            ),
          );
        },
        () => MockClient((request) async {
          requests++;
          return http.Response('{"external":{"google":false}}', 200);
        }),
      );
      expect(requests, 1);
    },
  );

  test(
    'Google disabilitato spiega il blocco e mantiene disponibile email',
    () async {
      final backend = _FakeEmailBackend()
        ..launchError = const AuthException(
          'Google disabled',
          code: 'oculum_google_provider_disabled',
        );
      addTearDown(backend.close);
      final auth = OculumAuthService.forTesting(
        backend: backend,
        connectivityCheck: () async => true,
      );
      addTearDown(auth.dispose);
      await auth.initialize();

      expect(await auth.signInWithGoogle(), isFalse);
      expect(auth.state.errorMessage, contains('Google non abilitato'));
      expect(auth.isBusy, isFalse);
      expect(
        await auth.signInWithEmailPassword('user@example.com', 'pw'),
        isTrue,
      );
      expect(auth.state.provider, 'email');
    },
  );

  test(
    'callback web conserva il percorso esatto e scarta codice e fragment',
    () {
      final page = Uri.parse(
        'https://mich369.github.io/Oculum/?code=old#ignored',
      );
      expect(oculumWebAuthRedirect(page), 'https://mich369.github.io/Oculum/');
      expect(
        oculumWebAuthRedirect(Uri.parse('http://localhost:8080/?code=old')),
        'http://localhost:8080/',
      );
    },
  );

  test('Collega Google conserva UUID e salvataggio del profilo', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('oculum-local-fixture', 'existing sheets');
    final backend = _FakeGoogleLinkBackend()
      ..user = const OculumBackendUser(id: 'original-id', provider: 'email');
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => true,
    );
    await auth.initialize();
    expect(await auth.linkGoogle(), isTrue);
    expect(backend.linkCount, 1);
    expect(backend.launchCount, 0);
    backend.emit(
      const OculumBackendAuthEvent(
        OculumBackendAuthEventType.userUpdated,
        user: OculumBackendUser(
          id: 'original-id',
          provider: 'email',
          identityProviders: {'email', 'google'},
        ),
      ),
    );
    await pumpEventQueue();
    expect(auth.state.userId, 'original-id');
    expect(auth.hasGoogleIdentity, isTrue);
    expect(auth.canLinkGoogle, isFalse);
    await auth.signOut();
    expect(prefs.getString('oculum-local-fixture'), 'existing sheets');
    auth.dispose();
    await backend.close();
  });

  test(
    'un evento precedente non scollega il profilo corrente da Google',
    () async {
      final backend = _FakeGoogleLinkBackend()
        ..user = const OculumBackendUser(id: 'current-id', provider: 'email');
      addTearDown(backend.close);
      final auth = OculumAuthService.forTesting(
        backend: backend,
        connectivityCheck: () async => true,
        oauthTimeout: const Duration(minutes: 1),
      );
      addTearDown(auth.dispose);
      await auth.initialize();
      expect(await auth.linkGoogle(), isTrue);
      backend.emit(
        const OculumBackendAuthEvent(
          OculumBackendAuthEventType.tokenRefreshed,
          user: OculumBackendUser(id: 'previous-id', provider: 'google'),
        ),
        updateCurrentUser: false,
      );
      await pumpEventQueue();

      expect(auth.state.userId, 'current-id');
      expect(auth.canCancelSignIn, isTrue);
      expect(backend.signOutCount, 0);
      backend.emit(
        const OculumBackendAuthEvent(
          OculumBackendAuthEventType.userUpdated,
          user: OculumBackendUser(
            id: 'current-id',
            provider: 'email',
            identityProviders: {'email', 'google'},
          ),
        ),
      );
      await pumpEventQueue();
      expect(auth.hasGoogleIdentity, isTrue);
      expect(auth.isBusy, isFalse);
    },
  );

  test('il collegamento Google rifiuta un UUID corrente diverso', () async {
    final backend = _FakeGoogleLinkBackend()
      ..user = const OculumBackendUser(id: 'original-id', provider: 'email');
    addTearDown(backend.close);
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => true,
    );
    addTearDown(auth.dispose);
    await auth.initialize();
    expect(await auth.linkGoogle(), isTrue);

    backend.emit(
      const OculumBackendAuthEvent(
        OculumBackendAuthEventType.signedIn,
        user: OculumBackendUser(id: 'different-id', provider: 'google'),
      ),
    );
    await pumpEventQueue();
    expect(auth.state.isAuthenticated, isFalse);
    expect(auth.state.userId, isNull);
    expect(backend.signOutCount, 1);
    expect(auth.state.errorMessage, contains('tentativo di accesso'));
  });

  test('assenza di rete mostra offline e non apre il browser', () async {
    final backend = _FakeAuthBackend();
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => false,
    );
    await auth.initialize();

    expect(await auth.signInWithGoogle(), isFalse);
    expect(auth.state.isOffline, isTrue);
    expect(backend.launchCount, 0);
    auth.dispose();
    await backend.close();
  });

  test('sessione persistita viene ripristinata all’avvio', () async {
    final backend = _FakeAuthBackend()
      ..user = const OculumBackendUser(id: 'restored', provider: 'apple');
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => true,
    );

    await auth.initialize();

    expect(auth.state.isAuthenticated, isTrue);
    expect(auth.state.userId, 'restored');
    auth.dispose();
    await backend.close();
  });

  test('l’uscita ripulisce lo stato locale e torna Guest', () async {
    final backend = _FakeAuthBackend()
      ..user = const OculumBackendUser(id: 'user-2', provider: 'google');
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => true,
    );
    await auth.initialize();

    expect(await auth.signOut(), isTrue);
    expect(backend.signOutCount, 1);
    expect(auth.state.isGuest, isTrue);
    expect(auth.state.isAuthenticated, isFalse);
    auth.dispose();
    await backend.close();
  });

  test('l’uscita resta esclusiva anche dopo l’evento signedOut', () async {
    final confirmation = Completer<void>();
    final backend = _FakeEmailBackend()
      ..user = const OculumBackendUser(id: 'signed-in', provider: 'google')
      ..signOutConfirmation = confirmation;
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => true,
    );
    await auth.initialize();
    final signOut = auth.signOut();
    await pumpEventQueue();
    expect(auth.isBusy, isTrue);
    expect(auth.state.canSyncToCloud, isFalse);
    expect(auth.canCancelSignIn, isFalse);
    auth.cancelPendingSignIn();
    expect(await auth.signInWithApple(), isFalse);
    expect(await auth.signInAsProtectedGuest(), isFalse);
    expect(backend.launchCount, 0);
    confirmation.complete();
    expect(await signOut, isTrue);
    expect(auth.isBusy, isFalse);
    expect(auth.state.isAuthenticated, isFalse);
    auth.dispose();
    await backend.close();
  });

  test('registrazione in corso e codice restano legati all’ospite', () async {
    final response = Completer<void>();
    final backend = _FakeEmailBackend()..emailResponse = response;
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => true,
    );
    await auth.initialize();
    expect(await auth.signInAsProtectedGuest(), isTrue);
    final registration = auth.requestEmailAccess('guest@example.com');
    expect(
      await auth.signInWithEmailPassword('other@example.com', 'password'),
      isFalse,
    );
    expect(await auth.signOut(), isFalse);
    response.complete();
    expect(await registration, isTrue);
    expect(auth.pendingEmail, 'guest@example.com');
    backend.emit(
      const OculumBackendAuthEvent(
        OculumBackendAuthEventType.signedIn,
        user: OculumBackendUser(id: 'new-guest', provider: 'anonymous'),
      ),
    );
    await pumpEventQueue();
    expect(await auth.verifyEmailAccess('123456'), isFalse);
    expect(backend.emailVerifications, 0);
    expect(auth.pendingEmail, isNull);
    expect(auth.state.userId, 'new-guest');
    auth.dispose();
    await backend.close();
  });

  test('doppio clic avvia una sola richiesta OAuth', () async {
    final backend = _FakeAuthBackend();
    final auth = OculumAuthService.forTesting(
      backend: backend,
      connectivityCheck: () async => true,
    );
    await auth.initialize();

    final first = auth.signInWithGoogle();
    final second = auth.signInWithGoogle();

    expect(await first, isTrue);
    expect(await second, isFalse);
    expect(backend.launchCount, 1);
    auth.dispose();
    await backend.close();
  });

  group('cloud save non distruttivo', () {
    test('richiede conferma quando locale e cloud esistono', () {
      expect(
        OculumCloudSaveService.chooseMigrationAction(
          hasLocalSave: true,
          hasCloudSave: true,
        ),
        CloudMigrationAction.askUser,
      );
    });

    test('un conflitto conserva entrambe le versioni', () {
      final resolution = OculumCloudSaveService.resolveConflict(
        localRevision: 3,
        remoteRevision: 2,
        localSignature: 'local-hash',
        remoteSignature: 'remote-hash',
      );
      expect(resolution.action, CloudConflictAction.keepBoth);
      expect(resolution.newId, isNotNull);
    });
  });
}
