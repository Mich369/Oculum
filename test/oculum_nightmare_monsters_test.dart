import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'Nightmare monsters have three usable skills with saved effects and costs',
    () {
      for (final id in [
        'larva_del_vespro',
        'custode_campana_cieca',
        'sposa_marea_nera',
      ]) {
        final monster = defaultMonsterBookEntries.singleWhere(
          (m) => m.id == id,
        );
        final art = CharacterArt.fromJson(
          oculumMonsterBookArt(monster).toJson(),
        );
        expect(art.skills, hasLength(3));
        for (final skill in art.skills) {
          expect(skill.livello, 0);
          expect(skill.oculumMinimiPerLivello.take(3), [1, 5, 11]);
          for (final effects in skill.effettiPerLivello.take(3)) {
            expect(effects, hasLength(1));
            expect(
              oculumEvaluateStructuredEffectValue(
                effects.single,
                variables: {'danni': 10},
                spentResources: {'oculum': 4},
              ),
              greaterThan(0),
            );
          }
        }
      }
    },
  );
}
