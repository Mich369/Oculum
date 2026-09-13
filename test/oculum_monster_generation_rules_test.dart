import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'all grade boundaries come from level, including the gap at level 20',
    () {
      const thresholds = [10, 30, 40, 50, 60, 70, 80, 90, 100, 120, 150, 200];
      for (var i = 0; i < thresholds.length; i++) {
        expect(oculumGradeForLevel(thresholds[i] - 1), i);
        expect(oculumGradeForLevel(thresholds[i]), i + 1);
      }
      expect(oculumGradeForLevel(20), 1);
      expect(oculumGeneratedMonsterBudget('Mostro', 30), 380);
      expect(oculumGeneratedMonsterBudget('Mostro Mini Boss', 30), 480);
      expect(oculumGeneratedMonsterBudget('Mostro Boss', 30), 680);
    },
  );
  test('allocation conserves every point and powers decide Oculum', () {
    for (var budget = 0; budget <= 5000; budget++) {
      for (final powers in [
        (false, false),
        (true, false),
        (false, true),
        (true, true),
      ]) {
        final stats = oculumDistributeMonsterStats(
          budget,
          hasSkills: powers.$1,
          hasOculumArt: powers.$2,
        );
        expect(stats.values.fold<int>(0, (a, b) => a + b), budget);
        expect(stats.values.every((value) => value >= 0), isTrue);
        if (powers.$1 || powers.$2) {
          if (budget > 0) expect(stats['oculum'], greaterThan(0));
          if (budget >= 20) {
            expect(stats['resilienza'], greaterThan(stats['volonta']!));
            expect(stats['resilienza'], greaterThan(stats['materia']!));
            expect(stats['oculum'], greaterThan(stats['volonta']!));
            expect(stats['oculum'], greaterThan(stats['materia']!));
          }
        } else {
          expect(stats['oculum'], 0);
          if (budget >= 3) {
            expect(stats.values.take(3).every((value) => value > 0), isTrue);
          }
        }
      }
    }
  });
  test(
    'every Book creature generates from its powers without changing its source',
    () {
      for (final monster in defaultMonsterBookEntries) {
        final before = monster.toJson();
        for (final level in [0, 1, 10, 30, 200]) {
          final stats = oculumMonsterCreationStats(monster, level);
          expect(
            stats['oculum'],
            monster.skillIds.isEmpty ? 0 : greaterThan(0),
            reason: monster.id,
          );
          if (level > 0) {
            expect(
              stats.values.fold<int>(0, (a, b) => a + b),
              oculumGeneratedMonsterBudget(monster.presetType, level),
            );
          }
        }
        expect(monster.toJson(), before);
      }
    },
  );
  test(
    'monster Open has a buff and an independent persisted skill cooldown',
    () {
      final art = CharacterArt(
        nome: 'Art di prova',
        tipo: 'Art Mostro',
        descrizione: '',
        skills: [
          ArtSkill(
            nome: 'Prova',
            livello: 1,
            evo1: 'I',
            evo2: 'II',
            evo3: 'III',
          ),
        ],
      );
      oculumCompleteMonsterOpen(art, name: 'Guardiano', level: 30, grade: 2);
      expect(art.openAttiva, isFalse);
      expect(art.openBuff, contains('@Difesa+'));
      expect(art.openSkillEffects.single.duration, '1');
      expect(art.openSkillCooldown!.ready, isTrue);
      art.openSkillCooldown!.activate();
      expect(art.openSkillCooldown!.activate(), isFalse);
      final restored = CharacterArt.fromJson(art.toJson());
      expect(restored.monsterOpenSkill, isTrue);
      expect(restored.openSkillCooldown!.remaining, 3);
      for (var i = 0; i < 3; i++) {
        restored.openSkillCooldown!.tick('turni');
      }
      expect(restored.openSkillCooldown!.ready, isTrue);
      final custom = restored
        ..openBuff = '@Materia+17'
        ..openSkill = 'La mia capacità';
      oculumCompleteMonsterOpen(
        custom,
        name: 'Guardiano',
        level: 200,
        grade: 12,
      );
      expect(custom.openBuff, '@Materia+17');
      expect(custom.openSkill, 'La mia capacità');
    },
  );
}
