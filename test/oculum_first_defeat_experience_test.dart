import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  Map<String, dynamic> enemy(
    String id,
    int grade, {
    String element = 'fisico',
  }) => {
    'monsterBookId': id,
    'grade': grade,
    'element': element,
    'experienceReward': 11,
  };

  test(
    'first type rounds 50 percent up; new variants round 25 percent down',
    () {
      final base = enemy('lupo', 2);
      final first = oculumFirstDefeatExperience([base], {});
      expect(first.bonus, 6);
      final veteran = enemy('lupo_variante_veterano', 2);
      final next = oculumFirstDefeatExperience([veteran], first.history);
      expect(next.bonus, 2);
      final elemental = oculumFirstDefeatExperience([
        enemy('lupo', 2, element: 'fuoco'),
      ], next.history);
      expect(elemental.bonus, 2);
      expect(
        oculumFirstDefeatExperience([veteran], elemental.history).bonus,
        0,
      );
      expect(first.history['lupo']['variants'], hasLength(1));
    },
  );

  test('weaker grade after stronger grants nothing; higher grade is new', () {
    final strongest = oculumFirstDefeatExperience([enemy('lupo', 4)], {});
    final lower = oculumFirstDefeatExperience([
      enemy('lupo_variante_veterano', 2),
    ], strongest.history);
    expect(lower.bonus, 0);
    expect(
      oculumFirstDefeatExperience([enemy('lupo', 5)], lower.history).bonus,
      2,
    );
  });

  test(
    'duplicates, summons and explicit family keep reward history isolated',
    () {
      final monster = {
        ...enemy('lupo_base', 1),
        'experienceFamilyId': 'lupi_cavi',
      };
      final first = oculumFirstDefeatExperience([monster, monster], {});
      expect(first.bonus, 6);
      final alpha = {
        ...enemy('lupo_alfa', 3),
        'experienceFamilyId': 'lupi_cavi',
      };
      expect(oculumFirstDefeatExperience([alpha], first.history).bonus, 2);
      expect(
        oculumFirstDefeatExperience([
          {...monster, 'isSummon': true},
        ], {}).bonus,
        0,
      );
      expect(
        oculumFirstDefeatExperience([monster], {}).bonus,
        6,
        reason: 'Each participant owns an independent history.',
      );
    },
  );
}
