import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_auth_service.dart';
import 'package:oculum/services/oculum_save_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('save profile preserves legacy keys or isolates a test build', () {
    final profile = oculumSaveProfile.trim();
    expect(
      oculumProfiledStorageKey('oculum_save_v9_manual_rgb_opacity_clean'),
      profile.isEmpty
          ? 'oculum_save_v9_manual_rgb_opacity_clean'
          : 'oculum_save_v9_manual_rgb_opacity_clean__$profile',
    );
    expect(oculumProfileFileSuffix, profile.isEmpty ? '' : '_$profile');
    expect(oculumUsesIsolatedSaveProfile, profile.isNotEmpty);
    expect(
      oculumAuthSessionStorageKey('project'),
      profile.isEmpty
          ? 'sb-project-auth-token'
          : 'sb-project-auth-token__$profile',
    );
    expect(
      oculumAuthSessionStorageKey('project', browser: true),
      profile.isEmpty
          ? 'sb-project-auth-token-browser'
          : 'sb-project-auth-token-browser__$profile',
    );
    expect(
      oculumAuthSessionStorageKey('project', browser: true),
      isNot(oculumAuthSessionStorageKey('project')),
    );
  });

  test('Supabase Auth session uses the active save profile key', () async {
    SharedPreferences.setMockInitialValues({});
    final profile = oculumSaveProfile.trim();
    final key = oculumAuthSessionStorageKey('project');
    expect(
      OculumSessionStorage.rememberKey,
      profile.isEmpty
          ? 'oculum.auth.remember_access'
          : 'oculum.auth.remember_access__$profile',
    );
    final storage = OculumSessionStorage(persistSessionKey: key);
    await storage.initialize();
    await storage.persistSession('session-for-$profile');

    final prefs = await SharedPreferences.getInstance();
    expect(await storage.hasAccessToken(), isTrue);
    expect(prefs.containsKey(key), isTrue);
    if (profile.isNotEmpty) {
      expect(prefs.containsKey('sb-project-auth-token'), isFalse);
    }
  });
}
