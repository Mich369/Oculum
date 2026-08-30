import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_save_profile.dart';

void main() {
  test('default save profile preserves the historical storage key', () {
    expect(oculumSaveProfile, isEmpty);
    expect(
      oculumProfiledStorageKey('oculum_save_v9_manual_rgb_opacity_clean'),
      'oculum_save_v9_manual_rgb_opacity_clean',
    );
    expect(oculumProfileFileSuffix, isEmpty);
  });
}
