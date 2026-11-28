import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_secure_auth_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const key = 'sb-project-auth-token';
  const otherProfile = 'sb-project-auth-token-test';
  const pkceKey = 'supabase.auth.token-code-verifier';

  setUp(() {
    SharedPreferences.setMockInitialValues({
      key: 'previous-session',
      otherProfile: 'other-session',
      pkceKey: 'unscoped-verifier',
      'campaign-save': 'untouched',
    });
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('migrates and clears only the exact profile session key', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = OculumSecureAuthStorage();
    expect(await storage.read(key, legacy: prefs), 'previous-session');
    expect(
      await const FlutterSecureStorage().read(key: key),
      'previous-session',
    );
    expect(prefs.containsKey(key), isFalse);
    expect(prefs.getString(otherProfile), 'other-session');
    expect(prefs.getString('campaign-save'), 'untouched');

    await storage.write(key, 'new-session', legacy: prefs);
    expect(await storage.read(key, legacy: prefs), 'new-session');
    await storage.delete(key, legacy: prefs);
    expect(await storage.read(key, legacy: prefs), isNull);
    expect(prefs.getString(otherProfile), 'other-session');
  });

  test('a failed secure write retains the previous session', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = OculumSecureAuthStorage(const UnavailableAuthVault());
    await expectLater(
      storage.read(key, legacy: prefs),
      throwsA(isA<PlatformException>()),
    );
    expect(prefs.getString(key), 'previous-session');
  });

  test('an unverifiable secure write retains the previous session', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = OculumSecureAuthStorage(const UnverifiableAuthVault());
    await expectLater(storage.read(key, legacy: prefs), throwsStateError);
    expect(prefs.getString(key), 'previous-session');
  });

  test('PKCE verifiers are scoped and removed independently', () async {
    final prefs = await SharedPreferences.getInstance();
    final normal = OculumSecurePkceStorage(namespace: key);
    final testProfile = OculumSecurePkceStorage(namespace: otherProfile);
    expect(await normal.getItem(key: pkceKey), isNull);
    await normal.setItem(key: pkceKey, value: 'normal-verifier');
    await testProfile.setItem(key: pkceKey, value: 'test-verifier');
    expect(
      await OculumSecurePkceStorage(namespace: key).getItem(key: pkceKey),
      'normal-verifier',
    );
    await normal.removeItem(key: pkceKey);
    expect(await normal.getItem(key: pkceKey), isNull);
    expect(await testProfile.getItem(key: pkceKey), 'test-verifier');
    expect(prefs.getString(pkceKey), 'unscoped-verifier');
  });

  test('cancelling OAuth removes only the verifier it prepared', () async {
    final normal = OculumOAuthPkceStorage(
      OculumSecurePkceStorage(namespace: key),
    );
    final testProfile = OculumSecurePkceStorage(namespace: otherProfile);
    await testProfile.setItem(key: pkceKey, value: 'other-profile');
    await normal.prepareOAuth(
      () => normal.setItem(key: pkceKey, value: 'oauth-verifier'),
    );
    await normal.cancelOAuth();
    expect(await normal.getItem(key: pkceKey), isNull);
    expect(await testProfile.getItem(key: pkceKey), 'other-profile');

    await normal.prepareOAuth(
      () => normal.setItem(key: pkceKey, value: 'old-oauth-verifier'),
    );
    await normal.setItem(key: pkceKey, value: 'email-recovery-verifier');
    await normal.cancelOAuth();
    expect(await normal.getItem(key: pkceKey), 'email-recovery-verifier');
  });

  test('cancelled preparation cannot overwrite a newer verifier', () async {
    final storage = OculumOAuthPkceStorage(
      OculumSecurePkceStorage(namespace: key),
    );
    final resumeOldAttempt = Completer<void>();
    final oldAttempt = storage.prepareOAuth(() async {
      await resumeOldAttempt.future;
      await storage.setItem(key: pkceKey, value: 'previous-verifier');
    });
    final oldFailure = expectLater(oldAttempt, throwsStateError);
    await storage.cancelOAuth();
    await storage.prepareOAuth(
      () => storage.setItem(key: pkceKey, value: 'fresh-verifier'),
    );
    resumeOldAttempt.complete();
    await oldFailure;
    expect(await storage.getItem(key: pkceKey), 'fresh-verifier');
  });
}

class UnverifiableAuthVault extends FlutterSecureStorage {
  const UnverifiableAuthVault();

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {}
}

class UnavailableAuthVault extends FlutterSecureStorage {
  const UnavailableAuthVault();

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw PlatformException(code: 'unavailable');
}
