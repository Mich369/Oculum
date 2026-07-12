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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
