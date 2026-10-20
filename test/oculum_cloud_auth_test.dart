import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_auth_service.dart';
import 'package:oculum/services/oculum_cloud_save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthBackend implements OculumAuthBackend {
  final _events = StreamController<OculumBackendAuthEvent>.broadcast();

  OculumBackendUser? user;
  bool launchResult = true;
  Object? launchError;
  int launchCount = 0;
  int signOutCount = 0;

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
    return launchResult;
  }

  void emit(OculumBackendAuthEvent event) {
    user = event.user;
    _events.add(event);
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    user = null;
    _events.add(
      const OculumBackendAuthEvent(OculumBackendAuthEventType.signedOut),
    );
  }

  Future<void> close() => _events.close();
}

class _FakeEmailBackend extends _FakeAuthBackend
    implements OculumEmailAuthBackend {
  bool? linked;
  String? email;
  String? password;
  String? resetEmail;
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
    if (token != '123456') throw const FormatException('Codice non valido');
    user = OculumBackendUser(
      id: linkGuest ? 'protected-guest' : 'email-account',
      provider: 'email',
    );
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

  test(
    'mantieni accesso falso non conserva sessioni né token aggiornati',
    () async {
      final storage = OculumSessionStorage(
        persistSessionKey: 'test-auth-token',
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

  test('logout globale ripulisce lo stato locale e torna Guest', () async {
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
