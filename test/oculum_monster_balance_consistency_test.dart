import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('passive monster forms cost nothing, including combat variants', () {
    for (final monster in defaultMonsterBookEntries) {
      final ids = monsterBookUsableSkillIds(monster);
      final art = CharacterArt.fromJson(oculumMonsterBookArt(monster).toJson());
      for (var i = 0; i < ids.length; i++) {
        if (!oculumMonsterBookSkillIsPassive(ids[i])) continue;
        final skill = art.skills[i];
        for (var form = 1; form <= 3; form++) {
          expect(skill.tipoPerLivello(form), contains('Passiva'));
          expect(skill.risorsaCostoPerLivello(form), 'nessuna');
          expect(skill.oculumMinimoPerLivello(form), 0);
          expect(skill.oculumMassimoPerLivello(form), 0);
          expect(skill.testoEvoluzione(form), isNot(contains('Costo:')));
        }
      }
    }
  });

  test(
    'precise spines preserve the authored costs in every material variant',
    () {
      for (final monster in defaultMonsterBookEntries.where(
        (entry) => entry.id.startsWith('riccio_aculeo'),
      )) {
        final skill = oculumMonsterBookArt(
          monster,
        ).skills.singleWhere((skill) => skill.nome == 'Aculei precisi');
        expect(skill.oculumMinimiPerLivello.take(3), [
          2,
          5,
          10,
        ], reason: monster.id);
        expect(skill.oculumMassimiPerLivello.take(3), [
          2,
          5,
          11,
        ], reason: monster.id);
        expect(skill.evo3, contains('10/11 Oculum'));
      }
    },
  );

  test('lava regeneration actually increases with the described forms', () {
    for (final (id, values) in [
      ('larva_lava', [3, 5, 8]),
      ('golem_lava', [8, 12, 16]),
      ('cuore_lava', [15, 20, 25]),
    ]) {
      final monster = defaultMonsterBookEntries.singleWhere((m) => m.id == id);
      final skill = oculumMonsterBookArt(
        monster,
      ).skills.singleWhere((skill) => skill.nome == 'Rigenerazione di lava');
      for (var form = 0; form < 3; form++) {
        expect(
          oculumEvaluateStructuredEffectValue(
            skill.effettiPerLivello[form].single,
            variables: const {},
          ),
          values[form],
        );
      }
    }
  });

  test('minor-monster cost labels match actual fixed costs', () {
    for (final monster in defaultMonsterBookEntries.where(
      (entry) => entry.id.startsWith('weak_horror_'),
    )) {
      final art = oculumMonsterBookArt(monster);
      for (final skill in art.skills) {
        for (var form = 1; form <= 3; form++) {
          expect(
            skill.testoEvoluzione(form),
            contains('($form/$form Oculum fisso'),
          );
          expect(skill.oculumMinimoPerLivello(form), form);
          expect(skill.oculumMassimoPerLivello(form), form);
        }
      }
    }
  });

  test(
    'generic monster attacks grant a bonus once, never duplicate base damage',
    () {
      for (final monster in defaultMonsterBookEntries.where(
        (m) => m.id.startsWith('generated_') || m.id.startsWith('weak_horror_'),
      )) {
        for (final skill in oculumMonsterBookArt(monster).skills) {
          for (final form in skill.effettiPerLivello.take(3)) {
            for (final effect in form.where(
              (effect) => effect.type == 'danno',
            )) {
              expect(effect.mode, 'prossima_azione', reason: monster.id);
              expect(
                effect.valueExpression,
                isNot(contains('danni')),
                reason: monster.id,
              );
            }
          }
        }
      }
    },
  );
}
