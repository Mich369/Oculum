import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_auth_service.dart';
import 'package:oculum/services/oculum_cloud_save_service.dart';
import 'package:oculum/services/oculum_save_profile.dart';
import 'package:oculum/services/oculum_secure_auth_storage.dart';
import 'package:oculum/services/oculum_smoke_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CountingVault extends OculumSecureAuthStorage {
  int reads = 0;
  int writes = 0;
  int deletes = 0;

  int get calls => reads + writes + deletes;

  @override
  Future<String?> read(String key, {required SharedPreferences legacy}) async {
    reads++;
    return 'synthetic-vault-session';
  }

  @override
  Future<void> write(
    String key,
    String value, {
    required SharedPreferences legacy,
  }) async {
    writes++;
  }

  @override
  Future<void> delete(String key, {required SharedPreferences legacy}) async {
    deletes++;
  }
}

class _CountingAuthBackend
    implements OculumAuthBackend, OculumEmailAuthBackend {
  int calls = 0;

  @override
  OculumBackendUser? get currentUser {
    calls++;
    return const OculumBackendUser(id: 'synthetic-user');
  }

  @override
  Stream<OculumBackendAuthEvent> get events {
    calls++;
    return const Stream<OculumBackendAuthEvent>.empty();
  }

  @override
  Future<bool> startOAuth(
    OculumAuthProvider provider, {
    required String? redirectTo,
  }) async {
    calls++;
    return true;
  }

  @override
  Future<void> signOut() async {
    calls++;
  }

  @override
  Future<void> signInAnonymously() async {
    calls++;
  }

  @override
  Future<void> requestEmail(String email, {required bool linkGuest}) async {
    calls++;
  }

  @override
  Future<void> linkGuestEmailPassword(String email, String password) async {
    calls++;
  }

  @override
  Future<void> signInWithEmailPassword(String email, String password) async {
    calls++;
  }

  @override
  Future<void> setPassword(String password) async {
    calls++;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    calls++;
  }

  @override
  Future<void> verifyEmail(
    String email,
    String token, {
    required bool linkGuest,
  }) async {
    calls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    OculumAuthService.sessionStorage = null;
    oculumSetSmokeStorageActiveForTesting(true);
  });

  tearDown(() {
    OculumAuthService.sessionStorage = null;
    oculumSetSmokeStorageActiveForTesting(false);
  });

  test(
    'smoke session operations never enter the vault or migrate copied auth',
    () async {
      final sessionKey = oculumAuthSessionStorageKey('synthetic-project');
      final saveKey = oculumProfiledStorageKey('synthetic-save');
      SharedPreferences.setMockInitialValues(<String, Object>{
        sessionKey: 'synthetic-legacy-session',
        saveKey: 'synthetic-save-must-stay',
        OculumSessionStorage.rememberKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final before = <String, Object?>{
        for (final key in prefs.getKeys()) key: prefs.get(key),
      };
      final vault = _CountingVault();
      final storage = OculumSessionStorage(
        persistSessionKey: sessionKey,
        secureStorage: vault,
        useBrowserStorage: false,
      );

      await storage.initialize();
      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);
      await storage.persistSession('synthetic-new-session');
      await storage.removePersistedSession();

      expect(vault.calls, 0);
      expect(<String, Object?>{
        for (final key in prefs.getKeys()) key: prefs.get(key),
      }, before);
    },
  );

  test(
    'without smoke the session storage retains its existing vault behavior',
    () async {
      oculumSetSmokeStorageActiveForTesting(false);
      final vault = _CountingVault();
      final storage = OculumSessionStorage(
        persistSessionKey: oculumAuthSessionStorageKey('synthetic-project'),
        secureStorage: vault,
        useBrowserStorage: false,
      );

      await storage.initialize();
      expect(await storage.accessToken(), 'synthetic-vault-session');
      await storage.persistSession('synthetic-new-session');
      await storage.removePersistedSession();

      expect(vault.reads, 1);
      expect(vault.writes, 1);
      expect(vault.deletes, 1);
    },
  );

  test(
    'smoke auth remains local even with an injected online backend',
    () async {
      final backend = _CountingAuthBackend();
      var connectivityCalls = 0;
      final auth = OculumAuthService.forTesting(
        backend: backend,
        connectivityCheck: () async {
          connectivityCalls++;
          return true;
        },
      );
      addTearDown(auth.dispose);
      final vault = _CountingVault();
      final session = OculumSessionStorage(
        persistSessionKey: oculumAuthSessionStorageKey('synthetic-project'),
        secureStorage: vault,
        useBrowserStorage: false,
      );
      OculumAuthService.sessionStorage = session;

      await auth.initialize(supabaseReady: true);
      expect(auth.isSupabaseReady, isFalse);
      expect(auth.state.isAuthenticated, isFalse);
      expect(auth.state.userId, isNull);
      expect(await auth.signInWithGoogle(), isFalse);
      expect(await auth.signInWithApple(), isFalse);
      expect(await auth.signInAsProtectedGuest(), isFalse);
      expect(
        await auth.signInWithEmailPassword(
          'synthetic@example.invalid',
          'synthetic-password',
        ),
        isFalse,
      );
      await auth.setRememberAccess(false);
      await auth.signOut();

      expect(backend.calls, 0);
      expect(connectivityCalls, 0);
      expect(vault.calls, 0);
      expect(auth.state.isAuthenticated, isFalse);
      expect(auth.state.userId, isNull);
    },
  );

  test(
    'smoke cloud operations stay Offline without creating a Supabase client',
    () async {
      final cloud = OculumCloudSaveService.instance;
      await cloud.initialize();
      expect(cloud.status, 'Offline');
      expect(await cloud.fetchLatestSnapshot('synthetic-user'), isNull);
      expect(
        await cloud.uploadSnapshot('synthetic-user', <String, dynamic>{}),
        isFalse,
      );
      expect(
        await cloud.downloadSnapshot('synthetic-user', <String, dynamic>{}),
        isFalse,
      );
      await cloud.clearCloudData('synthetic-user');
      expect(cloud.status, 'Offline');
    },
  );
}
