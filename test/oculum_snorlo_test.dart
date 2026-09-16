import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'Snorlo preserves its base stats when a level zero sheet is created',
    () {
      final monster = defaultMonsterBookEntries.singleWhere(
        (m) => m.id == 'snorlo',
      );
      expect(monster.descIt, contains('quattro braccia'));
      expect(oculumMonsterCreationStats(monster, 0), {
        'resilienza': 5,
        'volonta': 4,
        'materia': 4,
        'oculum': 10,
      });
      final restored = CharacterArt.fromJson(
        oculumMonsterBookArt(monster).toJson(),
      );
      expect(restored.skills, hasLength(3));
      for (final skill in restored.skills) {
        expect(skill.livello, 0);
        expect(skill.oculumMinimiPerLivello.take(3), [1, 5, 11]);
        expect(skill.oculumMassimiPerLivello.take(3), [4, 10, 30]);
      }
    },
  );

  test('Snorlo bonuses use spent Oculum, not the remaining pool', () {
    for (final id in ['snorlo_body', 'snorlo_cm', 'snorlo_will']) {
      final effects = oculumSnorloSkillEffects(id);
      expect(
        effects.map((e) => e.target),
        id == 'snorlo_body'
            ? ['Resilienza', 'Volontà', 'Materia']
            : id == 'snorlo_cm'
            ? ['CM']
            : ['Volontà'],
      );
      for (final effect in effects) {
        expect(effect.duration, '1');
        expect(effect.stackable, isFalse);
        expect(
          oculumEvaluateStructuredEffectValue(
            effect,
            variables: {'oculum': 100},
            spentResources: {'oculum': 4},
          ),
          id == 'snorlo_body'
              ? 4
              : id == 'snorlo_cm'
              ? 8
              : 6,
        );
        expect(
          oculumEvaluateStructuredEffectValue(
            effect,
            variables: {'oculum': 100},
            spentResources: {'oculum': 0},
          ),
          0,
        );
      }
    }
    expect(
      oculumEvaluateStructuredEffectValue(
        oculumSnorloSkillEffects('snorlo_will').single,
        variables: {},
        spentResources: {'oculum': 3},
      ),
      5,
    );
  });
}
