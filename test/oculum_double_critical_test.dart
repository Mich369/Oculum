import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_opposed_attack.dart';
import 'package:oculum/main.dart';

void main() {
  test(
    'double critical requires natural twenty and twice the opposing total',
    () {
      expect(
        oculumIsDoubleCritical(natural: 20, total: 32, opposingTotal: 15),
        isTrue,
      );
      expect(
        oculumIsDoubleCritical(natural: 19, total: 32, opposingTotal: 15),
        isFalse,
      );
      expect(
        oculumIsDoubleCritical(natural: 20, total: 29, opposingTotal: 15),
        isFalse,
      );
      expect(
        oculumIsDoubleCritical(natural: 20, total: 30, opposingTotal: 15),
        isTrue,
      );
      expect(oculumDoubleCriticalDamageBonus(0, 0), 2);
      expect(oculumDoubleCriticalDamageBonus(3, 2), 21);
    },
  );
  test('difficulty Drop bonus is additive and bounded to confirmed modes', () {
    expect(oculumDropDifficultyBonus('facile'), 0);
    expect(oculumDropDifficultyBonus('normale'), 0);
    expect(oculumDropDifficultyBonus('difficile'), 3);
    expect(oculumDropDifficultyBonus('oculum'), 6);
  });
}
