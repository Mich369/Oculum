import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_save_profile.dart';

void main() {
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
  });
}
