import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'Nine weak horror monsters retain six to ten core points and usable skills',
    () {
      final monsters = defaultMonsterBookEntries
          .where((entry) => entry.id.startsWith('weak_horror_'))
          .toList();
      expect(monsters, hasLength(9));
      for (final monster in monsters) {
        final total = [
          'resilienza',
          'volonta',
          'materia',
          'oculum',
        ].fold<int>(0, (sum, stat) => sum + monster.stats[stat]!);
        expect(total, inInclusiveRange(6, 10), reason: monster.id);
        expect(monster.stats['level'], 0);
        expect(monster.id, isNot(contains('_variante_')));
        expect(monster.isBoss || monster.isMiniBoss, false);
        final art = oculumMonsterBookArt(monster);
        expect(art.skills, hasLength(2));
        for (final skill in art.skills) {
          for (var form = 0; form < 3; form++) {
            expect(skill.oculumMinimoPerLivello(form + 1), form + 1);
            expect(skill.oculumMassimoPerLivello(form + 1), form + 1);
            expect(skill.cooldownPerLivello[form].amount, 3);
            expect(
              skill.testoEvoluzione(form + 1),
              contains('Richiede livello ${form * 3}'),
            );
            final effect = skill.effettiPerLivello[form].single;
            expect(
              oculumEvaluateStructuredEffectValue(
                effect,
                variables: {'danni': 5},
              ),
              effect.type == 'danno' ? 6 + form : 1 + form,
            );
            if (effect.type != 'danno') expect(effect.duration, '1');
          }
        }
        expect(monster.dropIds, hasLength(2));
        expect(monster.dropChances.values, unorderedEquals([60, 35]));
        expect(
          MonsterBookEntry.fromJson(monster.toJson()).stats,
          monster.stats,
        );
      }
    },
  );
}
