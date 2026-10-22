import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('monster relic catalog contains at least 500 skill-based variants', () {
    final catalog = oculumMonsterEquipmentCatalogue();
    expect(catalog.length, greaterThanOrEqualTo(500));
    expect(
      catalog.map((item) => item.monsterLoot['id']).toSet().length,
      catalog.length,
    );
    expect(catalog.every((item) => item.ability != null), isTrue);
    expect(
      catalog.every(
        (item) =>
            readIntValue(item.craftData['monsterRelicMarketPrice']) > 0 &&
            '${item.craftData['sourceSkillId']}'.isNotEmpty &&
            item.monsterLoot['rareMonsterEquipment'] == true,
      ),
      isTrue,
    );
  });

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
      expect(oculumGeneratedMonsterBudget('Mostro Mini Boss', 30), 444);
      expect(oculumGeneratedMonsterBudget('Mostro Boss', 30), 510);
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
        final context =
            'budget=$budget, hasSkills=${powers.$1}, '
            'hasOculumArt=${powers.$2}, stats=$stats';
        expect(
          stats.values.fold<int>(0, (a, b) => a + b),
          budget,
          reason: 'Monster allocation must conserve every point: $context',
        );
        expect(
          stats.values.every((value) => value >= 0),
          isTrue,
          reason: 'Monster stats cannot be negative: $context',
        );
        if (powers.$2) {
          if (budget > 0) {
            expect(
              stats['oculum'],
              greaterThan(0),
              reason: 'Oculum Art needs Oculum points: $context',
            );
          }
          if (budget >= 20) {
            expect(
              stats['resilienza'],
              greaterThan(stats['volonta']!),
              reason: 'Expected Resilienza > Volontà: $context',
            );
            expect(
              stats['resilienza'],
              greaterThan(stats['materia']!),
              reason: 'Expected Resilienza > Materia: $context',
            );
            expect(
              stats['volonta'],
              greaterThan(stats['oculum']!),
              reason: 'Expected Volontà > Oculum: $context',
            );
            expect(
              stats['oculum'],
              greaterThan(stats['materia']!),
              reason: 'Expected Oculum > Materia: $context',
            );
          }
        } else {
          expect(
            stats['oculum'],
            0,
            reason: 'Without Oculum Art, Oculum must stay unused: $context',
          );
          if (budget >= 3) {
            expect(
              stats.values.take(3).every((value) => value > 0),
              isTrue,
              reason: 'Each core stat needs points at budget >= 3: $context',
            );
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
        final base = oculumMonsterCreationStats(monster, 0);
        for (final level in [0, 1, 10, 30, 200]) {
          final stats = oculumMonsterCreationStats(monster, level);
          for (final key in base.keys) {
            expect(
              stats[key],
              greaterThanOrEqualTo(base[key]!),
              reason: '${monster.id}: $key',
            );
            if (monster.stats.containsKey(key)) {
              expect(
                base[key],
                monster.stats[key],
                reason: '${monster.id}: base $key',
              );
            }
          }
          if (level > 0) {
            expect(
              stats.values.fold<int>(0, (a, b) => a + b),
              base.values.fold<int>(0, (a, b) => a + b) +
                  oculumGeneratedMonsterBudget(monster.presetType, level),
            );
          }
        }
        expect(monster.toJson(), before);
      }
    },
  );
  test(
    'each non-NPC monster rolls one saved area technique with balanced stages',
    () {
      for (final monster in defaultMonsterBookEntries.where(
        (entry) => !entry.isNpc && !entry.id.startsWith('pawn_guardiano'),
      )) {
        final first = oculumEnemyAbilityVariants(monster, seed: 2419);
        final second = oculumEnemyAbilityVariants(monster, seed: 2419);
        final area = first
            .where(
              (skill) =>
                  !skill.nome.startsWith('Raggi del') &&
                  skill.forme.first.effettiStrutturati.any(
                    (effect) => effect.minimumTargets > 1,
                  ),
            )
            .toList();
        expect(area, hasLength(1), reason: monster.id);
        expect(
          first.map((skill) => skill.toJson()).toList(),
          second.map((skill) => skill.toJson()).toList(),
          reason:
              'The same spawn seed must preserve the same abilities: ${monster.id}',
        );
        final skill = area.single;
        expect(skill.forme, hasLength(3), reason: monster.id);
        final firstHitCount =
            skill.forme.first.effettiStrutturati.single.minimumTargets;
        expect(
          firstHitCount,
          anyOf(2, 3),
          reason: '${monster.id} ${skill.nome}',
        );
        for (var form = 0; form < skill.forme.length; form++) {
          final hitCount = firstHitCount + form;
          final effect = skill.forme[form].effettiStrutturati.single;
          expect(effect.type, 'danno', reason: '${monster.id} ${skill.nome}');
          expect(
            effect.minimumTargets,
            hitCount,
            reason: '${monster.id} forma $form',
          );
          expect(
            effect.maximumTargets,
            hitCount,
            reason: '${monster.id} forma $form',
          );
          expect(
            effect.elementType,
            isNotEmpty,
            reason: '${monster.id} forma $form',
          );
          expect(
            skill.forme[form].cooldownStrutturato!.amount,
            greaterThanOrEqualTo(4),
          );
        }
        final restored = CharacterSkill.fromJson(skill.toJson());
        expect(
          restored.forme[2].effettiStrutturati.single.maximumTargets,
          firstHitCount + 2,
        );
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
      expect(art.openBuff, '@Stats+4');
      expect(art.openDescriptionEffects.single.valueExpression, '1d50+25');
      expect(art.openDescription, contains('danni inflitti di base'));
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
