import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'necromancers retain summon and gain six distinct editable techniques',
    () {
      final ids = <String>{};
      final names = <String>{};
      for (final monster in defaultMonsterBookEntries.where(
        (m) => m.id.startsWith('necromante_'),
      )) {
        final art = oculumMonsterBookArt(monster);
        expect(art.skills, hasLength(15));
        for (final (index, id) in monster.skillIds.indexed) {
          final canonical = oculumMonsterBookSkillBaseId(id);
          if (!canonical.startsWith('necromancer_') ||
              canonical == 'necromancer_raise_dead') {
            continue;
          }
          ids.add(canonical);
          final skill = art.skills[index];
          names.add(skill.nome);
          expect(skill.nome, isNot(contains('Tecnica necromantica')));
          final copy = ArtSkill.fromJson(skill.toJson());
          for (var form = 1; form <= 3; form++) {
            expect(
              copy.effettiEvoluzione(form),
              isNotEmpty,
              reason: '$id/$form',
            );
            expect(
              copy.effettiEvoluzione(form).map((e) => e.toJson()),
              skill.effettiEvoluzione(form).map((e) => e.toJson()),
            );
            final scaling = skill
                .effettiEvoluzione(form)
                .any((e) => e.valueExpression.contains('oculum_spent'));
            if (!scaling) {
              expect(
                skill.oculumMinimoPerLivello(form),
                skill.oculumMassimoPerLivello(form),
              );
            }
            expect(skill.cooldownPerLivello[form - 1].toJson(), isNotEmpty);
          }
        }
      }
      expect(ids, hasLength(6));
      expect(names, hasLength(6));
      final ash = monsterBookConcreteTechnique('necromancer_ash_bind')!;
      expect(ash.minimums, [3, 6, 10]);
      expect(ash.cooldowns, [3, 4, 5]);
      expect(ash.forms.first.single.recipient, 'bersaglio');
    },
  );
}
