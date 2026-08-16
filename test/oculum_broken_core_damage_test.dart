import 'package:flutter_test/flutter_test.dart';

import 'package:oculum/main.dart';

void main() {
  group('Nucleo Rotto e danni ricevuti', () {
    test('le probabilita seguono la difficolta della campagna', () {
      expect(oculumBrokenCoreDamageProfile('facile').chancePercent, 20);
      expect(oculumBrokenCoreDamageProfile('medio').chancePercent, 33);
      expect(oculumBrokenCoreDamageProfile('normale').chancePercent, 33);
      expect(oculumBrokenCoreDamageProfile('difficile').chancePercent, 50);
      expect(oculumBrokenCoreDamageProfile('oculum').chancePercent, 66);
    });

    test('la perdita usa la frazione della Vita attuale richiesta', () {
      expect(
        oculumBrokenCoreCurrentHpDamage(currentHp: 100, difficulty: 'facile'),
        20,
      );
      expect(
        oculumBrokenCoreCurrentHpDamage(currentHp: 100, difficulty: 'medio'),
        34,
      );
      expect(
        oculumBrokenCoreCurrentHpDamage(
          currentHp: 100,
          difficulty: 'difficile',
        ),
        50,
      );
      expect(
        oculumBrokenCoreCurrentHpDamage(currentHp: 100, difficulty: 'oculum'),
        50,
      );
    });

    test('la perdita arrotonda in alto ed e zero senza Vita', () {
      expect(
        oculumBrokenCoreCurrentHpDamage(currentHp: 7, difficulty: 'facile'),
        2,
      );
      expect(
        oculumBrokenCoreCurrentHpDamage(currentHp: 1, difficulty: 'oculum'),
        1,
      );
      expect(
        oculumBrokenCoreCurrentHpDamage(currentHp: 0, difficulty: 'oculum'),
        0,
      );
    });

    test('il tiro avviene solo se il danno raggiunge davvero la Vita', () {
      expect(
        oculumBrokenCoreCanRoll(
          brokenCore: true,
          hpBeforeDamage: 100,
          hpAfterDamage: 80,
        ),
        isTrue,
      );
      expect(
        oculumBrokenCoreCanRoll(
          brokenCore: true,
          hpBeforeDamage: 100,
          hpAfterDamage: 100,
        ),
        isFalse,
      );
      expect(
        oculumBrokenCoreCanRoll(
          brokenCore: false,
          hpBeforeDamage: 100,
          hpAfterDamage: 80,
        ),
        isFalse,
      );
      expect(
        oculumBrokenCoreCanRoll(
          brokenCore: true,
          hpBeforeDamage: 10,
          hpAfterDamage: 0,
        ),
        isFalse,
      );
    });
  });
}
