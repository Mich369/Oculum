import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_combat_scout_rules.dart';

void main() {
  test('automatic visibility follows all confirmed grade boundaries', () {
    for (var grade = 0; grade <= 11; grade++) {
      final threshold = (grade ~/ 3 + 1) * 3;
      expect(
        oculumSeesVeilAutomatically(
          conditionType: 'invisibile',
          targetGrade: grade,
          observerGrade: threshold - 1,
        ),
        false,
      );
      expect(
        oculumSeesVeilAutomatically(
          conditionType: 'invisibile',
          targetGrade: grade,
          observerGrade: threshold,
        ),
        true,
      );
      expect(
        oculumSeesVeilAutomatically(
          conditionType: 'trasparenza',
          targetGrade: grade,
          observerGrade: grade,
        ),
        false,
      );
      expect(
        oculumSeesVeilAutomatically(
          conditionType: 'trasparenza',
          targetGrade: grade,
          observerGrade: grade + 1,
        ),
        true,
      );
    }
  });
  test(
    'personal defense uses observer level only against identified transparency',
    () {
      expect(
        oculumTransparencyDefenseBonus(
          observerLevel: 17,
          transparent: true,
          identified: true,
        ),
        17,
      );
      expect(
        oculumTransparencyDefenseBonus(
          observerLevel: 17,
          transparent: true,
          identified: false,
        ),
        0,
      );
      expect(
        oculumTransparencyDefenseBonus(
          observerLevel: 17,
          transparent: false,
          identified: true,
        ),
        0,
      );
      expect(
        oculumCombatScoutVeilBonus(
          conditions: [
            {'conditionType': 'invisibile'},
          ],
          level: 20,
          targetGrade: 2,
          observerGrade: 3,
        ),
        0,
      );
      expect(
        oculumCombatScoutVeilBonus(
          conditions: [
            {'conditionType': 'invisibile'},
          ],
          level: 20,
          targetGrade: 3,
          observerGrade: 3,
        ),
        38,
      );
    },
  );
}
