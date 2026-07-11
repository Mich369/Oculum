import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  group('Fatica da Cenere', () {
    test('i primi 3 piu Grado punti non applicano malus', () {
      expect(oculumFatigueRollPenalty(ash: 0, grade: 0), 0);
      expect(oculumFatigueRollPenalty(ash: 3, grade: 0), 0);
      expect(oculumFatigueRollPenalty(ash: 5, grade: 2), 0);
      expect(oculumFatigueRollPenalty(ash: -4, grade: -2), 0);
    });

    test('ogni punto oltre la soglia applica meno uno', () {
      expect(oculumFatigueRollPenalty(ash: 4, grade: 0), -1);
      expect(oculumFatigueRollPenalty(ash: 7, grade: 0), -4);
      expect(oculumFatigueRollPenalty(ash: 6, grade: 2), -1);
      expect(oculumFatigueRollPenalty(ash: 9, grade: 2), -4);
    });

    test('Azzeramento Vulnerabilita sopprime tutto il malus', () {
      expect(
        oculumFatigueRollPenalty(ash: 30, grade: 0, suppressPenalty: true),
        0,
      );
    });

    test('anteprima e tiro sommano il modificatore rapido una sola volta', () {
      expect(
        oculumStatRollBonus(statValue: 10, levelGradeBonus: 7, quickBonus: -2),
        10,
      );
      expect(
        oculumStatRollBonus(
          statValue: 10,
          levelGradeBonus: 7,
          quickBonus: -2,
          extraBonus: 3,
        ),
        13,
      );
    });
  });
}
