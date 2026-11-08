import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('Schianto Pesante scales the ordinary damage once', () {
    expect(oculumStat20WillSlamDamage(20), 30);
    expect(oculumStat20WillSlamDamage(9), 14);
    expect(oculumStat20WillSlamDamage(20, percent: 175), 35);
    expect(oculumStat20WillSlamDamage(0), 0);
  });

  test('Pressione Pesante uses the signed Power gap and the minimum', () {
    expect(
      oculumStat20WillPressureModifiers(casterPower: 62, targetPower: 50),
      (bonus: 12, criticalMin: 18),
    );
    expect(
      oculumStat20WillPressureModifiers(casterPower: 62, targetPower: 60),
      (bonus: 9, criticalMin: 18),
    );
    expect(
      oculumStat20WillPressureModifiers(casterPower: 62, targetPower: 77),
      (bonus: 9, criticalMin: 18),
    );
  });

  test('Pressione Pesante targets at most one Grade above the caster', () {
    expect(oculumStat20WillPressureGradeAllowed(2, 0), isTrue);
    expect(oculumStat20WillPressureGradeAllowed(2, 3), isTrue);
    expect(oculumStat20WillPressureGradeAllowed(2, 4), isFalse);
    expect(oculumStat20WillPressureGradeAllowed(0, 1), isTrue);
  });
}
