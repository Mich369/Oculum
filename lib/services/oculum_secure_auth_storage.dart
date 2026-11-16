import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores only the supplied authentication key in the platform vault.
class OculumSecureAuthStorage {
  OculumSecureAuthStorage([FlutterSecureStorage? secure])
    : _secure =
          secure ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: false),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
            mOptions: MacOsOptions(usesDataProtectionKeychain: false),
          );

  final FlutterSecureStorage _secure;

  Future<String?> read(String key, {required SharedPreferences legacy}) async {
    final secured = await _secure.read(key: key);
    if (secured != null) {
      await _removeLegacy(legacy, key);
      return secured;
    }
    final previous = legacy.getString(key);
    if (previous == null) return null;
    await write(key, previous, legacy: legacy);
    return previous;
  }

  Future<void> write(
    String key,
    String value, {
    required SharedPreferences legacy,
  }) async {
    await _secure.write(key: key, value: value);
    if (await _secure.read(key: key) != value) {
      throw StateError('Unable to verify secure authentication storage.');
    }
    await _removeLegacy(legacy, key);
  }

  Future<void> delete(String key, {required SharedPreferences legacy}) async {
    await _removeLegacy(legacy, key);
    await _secure.delete(key: key);
    if (await _secure.read(key: key) != null) {
      throw StateError('Unable to clear secure authentication storage.');
    }
  }

  Future<void> _removeLegacy(SharedPreferences preferences, String key) async {
    if (preferences.containsKey(key) && !await preferences.remove(key)) {
      throw StateError('Unable to clear legacy authentication storage.');
    }
  }
}

/// PKCE survives a native OAuth browser round trip, isolated by app profile.
class OculumSecurePkceStorage extends GotrueAsyncStorage {
  OculumSecurePkceStorage({
    required String namespace,
    OculumSecureAuthStorage? storage,
  }) : _prefix = '$namespace.pkce.',
       _storage = storage ?? OculumSecureAuthStorage();

  final String _prefix;
  final OculumSecureAuthStorage _storage;

  @override
  Future<String?> getItem({required String key}) =>
      _storage._secure.read(key: '$_prefix$key');

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage._secure.write(key: '$_prefix$key', value: value);

  @override
  Future<void> removeItem({required String key}) =>
      _storage._secure.delete(key: '$_prefix$key');
}
