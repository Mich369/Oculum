import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_opposed_attack.dart';
import 'package:oculum/main.dart';

void main() {
  test(
    'positive double critical grants Magical Luck once after JSON restore',
    () {
      var sheet = <String, dynamic>{'fortuna': 2};
      bool resolve(String id, int natural, int total) =>
          oculumGrantDoubleCriticalMagicalLuck(
            sheet,
            receiptId: id,
            natural: natural,
            total: total,
            opposingTotal: 15,
          );
      expect(resolve('attack:one-roll-many-targets', 20, 30), isTrue);
      expect(sheet['fortuna'], 3);
      sheet = Map<String, dynamic>.from(jsonDecode(jsonEncode(sheet)));
      expect(resolve('attack:one-roll-many-targets', 20, 40), isFalse);
      expect(resolve('attack:not-a-critical', 19, 40), isFalse);
      expect(resolve('attack:ordinary-critical', 20, 29), isFalse);
      expect(resolve('defense:other-roll', 20, 31), isTrue);
      expect(sheet['fortuna'], 4);
    },
  );
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
