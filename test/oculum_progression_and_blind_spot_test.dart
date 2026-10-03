import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_blind_spot.dart';
import 'package:oculum/services/oculum_progression_surge.dart';

void main() {
  test('localized hits increase damage without changing ordinary damage', () {
    expect(oculumBlindSpotDamage(20, 0, 10), 22);
    expect(oculumBlindSpotDamage(20, 1, 10), 24);
    expect(oculumBlindSpotDamage(20, 3, 10), 28);
    expect(oculumBlindSpotDamage(20, 3, 0), 20);
    expect(oculumBlindSpotDamage(-10, 3, 10), 0);
    expect(oculumBlindSpotDamage(20, -2, -5), 20);
  });
  test(
    'earned rewards survive saves and short rest cannot reduce them twice',
    () {
      final surge = OculumProgressionSurge()
        ..gainLevels(2)
        ..gainGrades(2);
      expect(surge.statBonus, 16);
      expect(surge.shield, 200);
      surge.shortRest();
      expect(surge.statBonus, 9);
      surge.shortRest();
      expect(surge.statBonus, 9);
      final restored = OculumProgressionSurge.fromJson(surge.toJson());
      expect(restored.toJson(), surge.toJson());
      restored.longRest();
      expect(restored.statBonus, 0);
      expect(restored.shield, 100);
      expect(OculumProgressionSurge.fromJson(null).statBonus, 0);
    },
  );
}
