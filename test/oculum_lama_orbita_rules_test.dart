import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_lama_orbita_rules.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'starting affinity adds one elemental match and subtracts the kill penalty',
    () {
      expect(
        oculumLamaOrbitaStartingAffinity(
          ownedElements: ['Acqua', 'vento'],
          killedPreviousOwner: false,
        ),
        10,
      );
      expect(
        oculumLamaOrbitaStartingAffinity(
          ownedElements: ['Metallo'],
          killedPreviousOwner: true,
        ),
        5,
      );
      expect(
        oculumLamaOrbitaStartingAffinity(
          ownedElements: ['buio'],
          killedPreviousOwner: true,
        ),
        -5,
      );
    },
  );

  test('one d100 assigns five, three, two, or one loop in priority order', () {
    expect(
      [30, 31, 90, 91, 100].map((roll) => oculumLamaOrbitaRollLoops(60, roll)),
      [5, 3, 3, 2, 2],
    );
    expect([5, 15, 35, 36].map((roll) => oculumLamaOrbitaRollLoops(10, roll)), [
      5,
      3,
      2,
      1,
    ]);
    expect(oculumLamaOrbitaRollLoops(-5, 1), 1);
    expect(oculumLamaOrbitaRollLoops(300, 100), 5);
    expect(oculumLamaOrbitaFumblesReturn(20, 1), isTrue);
    expect(oculumLamaOrbitaFumblesReturn(60, 1), isTrue);
    expect(oculumLamaOrbitaFumblesReturn(61, 1), isFalse);
    expect(oculumLamaOrbitaFumblesReturn(60, 2), isFalse);
  });

  test('Affinity can recover from negative values and caps at 300', () {
    expect(oculumLamaOrbitaAffinityAfterHit(-5, 0), -5);
    expect(oculumLamaOrbitaAffinityAfterHit(-5, 1), 5);
    expect(oculumLamaOrbitaAffinityAfterHit(20, 3), 50);
    expect(oculumLamaOrbitaAffinityAfterHit(280, 5), 300);
    expect(oculumLamaOrbitaDamageBonus(400), 300);
  });

  test(
    'the three percentages retain halves and stay within probability bounds',
    () {
      expect(oculumLamaOrbitaLoopChances(-5), (five: 0.0, three: 0, two: 0));
      expect(oculumLamaOrbitaLoopChances(21), (five: 10.5, three: 21, two: 42));
      expect(oculumLamaOrbitaLoopChances(60), (
        five: 30.0,
        three: 60,
        two: 100,
      ));
      expect(oculumLamaOrbitaLoopChances(300), (
        five: 100.0,
        three: 100,
        two: 100,
      ));
    },
  );

  test('Predone has the armaments and protection of its authored preset', () {
    final monster = monsterBookEntryById(oculumPredoneBoomerangId)!;
    final byName = {
      for (final item in monster.inventoryItems) item['nome']: item,
    };
    final sword = byName['Spada corta del Predone']!;
    final gauntlet = byName['Guanto d’arme di Orbita']!;
    final orbit = byName['Lama Orbita']!;
    expect(sword['bonusDanno'], 3);
    expect(
      [gauntlet['bonusDanno'], gauntlet['bonusDifesa'], gauntlet['bonusScudo']],
      [3, 4, 10],
    );
    final affinity = (orbit['craftData'] as Map)[oculumLamaOrbitaId] as Map;
    expect(affinity['elements'], ['acqua', 'metallo', 'vento']);
    expect(affinity['maximumAffinity'], 300);
  });
}
