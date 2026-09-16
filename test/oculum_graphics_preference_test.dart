import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('graphics preference is persistent and reversible', () async {
    SharedPreferences.setMockInitialValues({});
    await loadOculumGraphicsPreference(); expect(oculumGraphicsEnabled.value, false);
    await setOculumGraphicsPreference(true); await loadOculumGraphicsPreference();
    expect(oculumGraphicsEnabled.value, true);
    await setOculumGraphicsPreference(false); expect(oculumGraphicsEnabled.value, false);
    expect(TestWidgetsFlutterBinding.instance.imageCache.maximumSizeBytes, 40 * 1024 * 1024);
  });
}
