import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('monster rank changes stat points earned per level', () {
    expect(oculumMonsterStatPointsPerLevel('Mostro'), 9);
    expect(oculumMonsterStatPointsPerLevel('Mostro Mini Boss'), 12);
    expect(oculumMonsterStatPointsPerLevel('Mostro Boss'), 18);
  });

  test('every guided starter Art has exactly three skills', () {
    for (final art in oculumStarterArtChoices()) {
      expect(art.skills, hasLength(3), reason: art.nome);
    }
  });

  test('water Art keeps the requested three-form Oculum costs', () {
    final water = oculumStarterWaterArt();
    final jet = water.skills.firstWhere(
      (skill) => skill.nome == 'Getto Distruttivo',
    );
    expect(jet.oculumMinimiPerLivello.take(3), [1, 5, 11]);
    expect(jet.oculumMassimiPerLivello.take(3), [4, 10, 60]);
    expect(jet.evo3, contains('+100 danni'));
    expect(jet.effettiPerLivello[2].single.bypassDefense, isTrue);
    expect(jet.effettiPerLivello[2].single.bypassShields, isTrue);
    final rays = water.skills.firstWhere(
      (skill) => skill.nome == 'Raggio Segugio',
    );
    expect(rays.effettiPerLivello[0], hasLength(3));
    expect(water.skills, hasLength(3));
  });

  test('rock Art completes spikes and keeps exactly three skills', () {
    final rock = oculumStarterRockArt();
    final spikes = rock.skills.firstWhere(
      (skill) => skill.nome == 'Spuntoni Rocciosi',
    );
    expect(spikes.evo2, contains('+20 danni'));
    expect(spikes.evo3, contains('+50 danni'));
    expect(rock.skills, hasLength(3));
  });

  test('Martial Arts spend only Will or Materia, never Oculum', () {
    for (final art in oculumStarterArtChoices().where(
      (art) => art.tipo == 'Martial Art',
    )) {
      for (final skill in art.skills) {
        expect(skill.risorseCostoPerLivello.take(3), isNot(contains('oculum')));
        expect(
          skill.risorseCostoPerLivello
              .take(3)
              .every(
                (resource) => resource == 'volonta' || resource == 'materia',
              ),
          isTrue,
        );
      }
    }
  });

  test('starter choices retain the user-defined Postea and Master paths', () {
    expect(
      oculumStarterBackgrounds.any(
        (choice) => choice.nome == 'Umano di Postea',
      ),
      isTrue,
    );
    expect(oculumStarterBackgrounds.any((choice) => choice.conMaster), isTrue);
    expect(oculumStarterRaces.any((choice) => choice.nome == 'Angelo'), isTrue);
  });

  test('initial experience is random but never exceeds 120', () {
    final random = Random(7);
    final rolls = List<int>.generate(
      300,
      (_) => oculumStarterInitialExperience(random),
    );
    expect(rolls.every((value) => value >= 0 && value <= 120), isTrue);
    expect(rolls.toSet().length, greaterThan(1));
  });

  test('Martial bonus is exactly 1d10+2', () {
    final random = Random(9);
    final rolls = List<int>.generate(
      200,
      (_) => oculumStarterMartialBonus(random),
    );
    expect(rolls.every((value) => value >= 3 && value <= 12), isTrue);
  });

  test('creation stat budgets scale by level and grade', () {
    expect(
      oculumStarterFreeStatPoints(monster: true, level: 10, grade: 1),
      100,
    );
    expect(
      oculumStarterFreeStatPoints(monster: false, level: 10, grade: 1),
      20,
    );
  });

  test('Open requires three distinct written third forms', () {
    final art = oculumStarterWaterArt();
    expect(oculumArtHasDistinctThirdForms(art), isTrue);
    art.skills[2].evo3 = art.skills[1].evo3;
    expect(oculumArtHasDistinctThirdForms(art), isFalse);
    art.skills.removeLast();
    expect(oculumArtHasDistinctThirdForms(art), isFalse);
  });

  test('core-roll EXP is deliberately reduced at higher difficulty', () {
    expect(
      oculumCoreRollExperienceGain(
        naturalRoll: 20,
        faces: 20,
        rollSucceeded: true,
        difficulty: 'normale',
      ),
      100,
    );
    expect(
      oculumCoreRollExperienceGain(
        naturalRoll: 19,
        faces: 20,
        rollSucceeded: true,
        difficulty: 'oculum',
      ),
      8,
    );
  });

  test('Bosses progress faster than Mini-Bosses on elite rolls', () {
    expect(
      oculumEliteMonsterRollProgress(
        boss: true,
        miniBoss: false,
        naturalRoll: 20,
      ).levels,
      1,
    );
    expect(
      oculumEliteMonsterRollProgress(
        boss: false,
        miniBoss: true,
        naturalRoll: 18,
      ).experience,
      150,
    );
  });
}
