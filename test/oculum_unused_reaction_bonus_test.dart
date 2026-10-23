import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test(
    'unused fast reactions give only six or nine and normal gives three',
    () {
      final outcomes = <int>{};
      for (var seed = 0; seed < 100; seed++) {
        final bonus = oculumReactionRefreshRollBonus(
          pendingBonus: 0,
          normalMaximum: 0,
          normalUsed: 0,
          fastMaximum: 1,
          fastUsed: 0,
          random: Random(seed),
        );
        expect(bonus, anyOf(6, 9));
        outcomes.add(bonus);
      }
      expect(outcomes, {6, 9});
      expect(
        oculumReactionRefreshRollBonus(
          pendingBonus: 0,
          normalMaximum: 1,
          normalUsed: 0,
          fastMaximum: 0,
          fastUsed: 0,
        ),
        3,
      );
      expect(
        oculumReactionRefreshRollBonus(
          pendingBonus: 9,
          normalMaximum: 1,
          normalUsed: 0,
          fastMaximum: 1,
          fastUsed: 0,
        ),
        12,
      );
      expect(
        oculumReactionRefreshRollBonus(
          pendingBonus: 0,
          normalMaximum: 1,
          normalUsed: 1,
          fastMaximum: 1,
          fastUsed: 1,
        ),
        0,
      );
    },
  );
}
