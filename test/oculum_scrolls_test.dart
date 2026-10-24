import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'Corruption defense matches source roll with minus three only at equal level',
    () {
      expect(
        oculumCanResistCorruption(targetLevel: 9, sourceLevel: 10),
        isFalse,
      );
      expect(
        oculumCanResistCorruption(targetLevel: 10, sourceLevel: 10),
        isTrue,
      );
      expect(
        oculumCorruptionDefensePenalty(targetLevel: 10, sourceLevel: 10),
        3,
      );
      expect(
        oculumCorruptionDefensePenalty(targetLevel: 11, sourceLevel: 10),
        0,
      );
      expect(
        oculumCorruptionDefenseSucceeds(
          targetLevel: 10,
          sourceLevel: 10,
          defenseTotal: 22,
          sourceTotal: 20,
        ),
        isFalse,
      );
      expect(
        oculumCorruptionDefenseSucceeds(
          targetLevel: 10,
          sourceLevel: 10,
          defenseTotal: 23,
          sourceTotal: 20,
        ),
        isTrue,
      );
      expect(
        oculumCorruptionDefenseSucceeds(
          targetLevel: 11,
          sourceLevel: 10,
          defenseTotal: 20,
          sourceTotal: 20,
        ),
        isTrue,
      );
      expect(
        oculumCorruptionDefenseSucceeds(
          targetLevel: 9,
          sourceLevel: 10,
          defenseTotal: 999,
          sourceTotal: 20,
        ),
        isFalse,
      );
    },
  );
  test(
    'Corruption mastery adds percentage points and preserves custom bonuses',
    () {
      final data = Map<String, dynamic>.from(
        oculumCorruptionScrollItem(0).craftData['scroll'] as Map,
      );
      final skill = CharacterSkill(
        nome: 'Padrone della Corruzione',
        tipo: 'Passiva',
        costo: '0',
        cooldown: '2',
        descrizione: '',
        scrollData: data,
      );
      expect(oculumCorruptionMasteryBonus([]), 0);
      expect(oculumCorruptionMasteryBonus([skill]), 50);
      final total = oculumCorruptionTotalResistance(
        existingResistancePercent: 20,
        masteryBonusPercent: oculumCorruptionMasteryBonus([skill]),
      );
      expect(total, 70);
      expect(
        oculumCorruptionChanceAfterResistance(
          chancePercent: 100,
          resistancePercent: total,
        ),
        30,
      );
      expect(
        oculumCorruptionChanceAfterResistance(
          chancePercent: 60,
          resistancePercent: total,
        ),
        18,
      );
      final overOneHundred = oculumCorruptionTotalResistance(
        existingResistancePercent: 75,
        masteryBonusPercent: 50,
      );
      expect(overOneHundred, 125);
      expect(
        oculumCorruptionChanceAfterResistance(
          chancePercent: 100,
          resistancePercent: overOneHundred,
        ),
        0,
      );
      data['resistancePercent'] = 35;
      final restored = CharacterSkill.fromJson(skill.toJson());
      expect(oculumCorruptionMasteryBonus([restored]), 35);
      expect(
        oculumCorruptionTotalResistance(
          existingResistancePercent: 20,
          masteryBonusPercent: oculumCorruptionMasteryBonus([restored]),
        ),
        55,
      );
      expect(restored.forme, hasLength(1));
    },
  );

  test(
    'Corruption scroll grade chance and fight-start cooldown are explicit',
    () {
      for (var scrollGrade = 0; scrollGrade <= 12; scrollGrade++) {
        for (var difference = 0; difference <= 6; difference++) {
          expect(
            oculumCorruptionScrollChance(
              scrollGrade: scrollGrade,
              targetGrade: scrollGrade + difference,
            ),
            difference >= 5 ? 0 : 100 - 20 * difference,
          );
        }
      }
      expect(
        oculumCorruptionChanceAfterResistance(
          chancePercent: 100,
          resistancePercent: 50,
        ),
        50,
      );

      final started = DateTime.utc(2026, 10, 22, 10);
      expect(
        oculumFightStartCooldownSecondsRemaining(
          fightStartedAt: started,
          cooldownTurns: 2,
          secondsPerTurn: 6,
          now: started.add(const Duration(seconds: 5)),
        ),
        7,
      );
      expect(
        oculumFightStartCooldownSecondsRemaining(
          fightStartedAt: started,
          cooldownTurns: 2,
          secondsPerTurn: 6,
          now: started.add(const Duration(seconds: 12)),
        ),
        0,
      );

      final item = InventoryItem.fromJson(
        oculumCorruptionScrollItem(3).toJson(),
      );
      final scroll = Map<String, dynamic>.from(item.craftData['scroll'] as Map);
      expect(scroll['kind'], 'corruption');
      expect(scroll['grade'], 3);
      expect(scroll['cooldownStart'], 'fight_start');
      expect(scroll['preselectOutsideFight'], isTrue);
      expect(scroll['cooldownSecondsPerTurn'], 6);
      expect(scroll['willCost'], 0);
      expect(scroll['scrollCategory'], 'attack');
    },
  );

  test(
    'Shadow Alive scroll preserves its formula and grade duration in JSON',
    () {
      for (var grade = 0; grade <= 12; grade++) {
        final item = oculumShadowLivingScrollItem(grade);
        final restored = InventoryItem.fromJson(item.toJson());
        final scroll = restored.craftData['scroll'] as Map;
        final effect = oculumScrollCombatEffects(
          Map<String, dynamic>.from(scroll),
        ).single;
        expect(scroll['kind'], 'shadow_clone');
        expect(scroll['grade'], grade);
        expect(effect.type, 'evocazione');
        expect(effect.target, 'clone_ombra');
        expect(effect.valueExpression, 'livello*5');
        expect(effect.duration, '${grade * 2 + 3}');
        expect(effect.durationUnit, 'turni');
        expect(effect.recipient, 'se_stesso');
      }
    },
  );

  test(
    'Technique scroll catalogue contains at least 100 distinct learnable skills',
    () {
      expect(oculumTechniqueScrolls.length, greaterThanOrEqualTo(100));
      for (final monster in defaultMonsterBookEntries.where(
        (entry) => entry.id.startsWith('base_'),
      )) {
        for (final id in monsterBookUsableSkillIds(monster)) {
          expect(
            oculumTechniqueScrolls.any(
              (profile) => profile.id.endsWith('_$id'),
            ),
            isTrue,
            reason: '${monster.nameIt}: $id must have a learnable scroll.',
          );
        }
      }
      expect(
        oculumTechniqueScrolls.map((p) => p.id).toSet().length,
        oculumTechniqueScrolls.length,
      );
      expect(
        oculumTechniqueScrolls.map((p) => p.name.toLowerCase()).toSet().length,
        oculumTechniqueScrolls.length,
      );
      for (final profile in oculumTechniqueScrolls) {
        final item = oculumTechniqueScrollItem(profile, 0);
        final scroll = item.craftData['scroll'] as Map;
        expect(scroll['effects'], isNotEmpty, reason: profile.id);
        expect(scroll['willCost'], greaterThan(0), reason: profile.id);
        expect(scroll['cooldownTurns'], greaterThan(0), reason: profile.id);
        expect(
          InventoryItem.fromJson(item.toJson()).craftData['scroll'],
          scroll,
        );
      }
    },
  );
  test('Drop scrolls start at 18 and grow one grade every 10', () {
    expect(oculumScrollDropGrade('forza', 138), isNull);
    expect(oculumScrollDropGrade('drop', 17), isNull);
    for (var grade = 0; grade <= 12; grade++) {
      expect(oculumScrollDropGrade('drop', 18 + grade * 10), grade);
      expect(oculumScrollDropGrade('drop', 27 + grade * 10), grade);
    }
    expect(oculumScrollDropGrade('drop', 999), 12);
  });
  test(
    'Learning requires natural 20, grade threshold and difficulty chance',
    () {
      for (var grade = 0; grade <= 12; grade++) {
        final threshold = 30 + 10 * grade;
        expect(oculumScrollCanLearn(19, threshold, grade, 0), isFalse);
        expect(oculumScrollCanLearn(20, threshold - 1, grade, 0), isFalse);
        for (final entry in {
          'facile': 20,
          'normale': 15,
          'difficile': 10,
          'oculum': 5,
        }.entries) {
          expect(oculumScrollLearningChance(entry.key), entry.value);
          expect(
            oculumScrollCanLearn(
              20,
              threshold,
              grade,
              entry.value - 1,
              difficulty: entry.key,
            ),
            isTrue,
          );
          expect(
            oculumScrollCanLearn(
              20,
              threshold,
              grade,
              entry.value,
              difficulty: entry.key,
            ),
            isFalse,
          );
          expect(
            oculumScrollCanLearn(
              19,
              threshold,
              grade,
              0,
              difficulty: entry.key,
            ),
            isFalse,
          );
          expect(
            oculumScrollCanLearn(
              20,
              threshold - 1,
              grade,
              0,
              difficulty: entry.key,
            ),
            isFalse,
          );
        }
      }
    },
  );
  test(
    'Every default element has attacks, control and buffs at every grade',
    () {
      for (final element in oculumDefaultElementIds) {
        for (var grade = 0; grade <= 12; grade++) {
          for (final kind in ['attack', 'control', 'ward']) {
            final item = oculumScrollItem(element, element, grade, kind);
            final loaded = InventoryItem.fromJson(item.toJson());
            expect(loaded.craftData['scroll'], item.craftData['scroll']);
            expect(loaded.gradoOggetto, grade);
            expect(loaded.elementoDanno, element);
            expect(
              loaded.buff,
              isEmpty,
              reason: 'A scroll must not grant permanent equipment bonuses',
            );
            expect(oculumScrollValue(grade), greaterThanOrEqualTo(300));
          }
        }
      }
      expect(
        oculumScrollItem('gelo', 'Ghiaccio', 0, 'attack').note,
        contains('1d8'),
      );
      expect(
        oculumScrollItem('gelo', 'Ghiaccio', 1, 'attack').note,
        contains('1d14'),
      );
      expect(
        oculumScrollItem('pianta', 'Pianta', 1, 'control').note,
        contains('50%'),
      );
    },
  );
  test(
    'Elemental scrolls have distinct roles and stronger grades cost more',
    () {
      expect(oculumScrollKindForElement('terra'), 'imprison');
      expect(oculumScrollKindForElement('acqua'), 'heal');
      expect(oculumScrollKindForElement('luce'), 'ward');
      expect(oculumScrollKindForElement('ombra'), 'weaken');
      expect(oculumScrollKindForElement('fulmine'), 'stun');
      final cage = oculumScrollItem('terra', 'Terra', 0, 'auto');
      final improvedCage = oculumScrollItem('terra', 'Terra', 3, 'auto');
      expect(cage.nome, contains('Gabbia d’Ossa'));
      expect(cage.note, contains('un turno'));
      expect(improvedCage.note, contains('20 danni'));
      expect(oculumScrollDifficulty(3), greaterThan(oculumScrollDifficulty(0)));
      expect(oculumScrollWillCost(3), greaterThan(oculumScrollWillCost(0)));
      expect(oculumScrollCooldown(3), greaterThan(oculumScrollCooldown(0)));
    },
  );
  test('Learned scroll data survives saves and cannot add an evolution', () {
    final item = oculumScrollItem('gelo', 'Ghiaccio', 1, 'attack');
    final skill = CharacterSkill(
      nome: 'Dardo',
      tipo: 'Attiva',
      costo: '0',
      cooldown: '0',
      descrizione: item.note,
      scrollData: Map<String, dynamic>.from(item.craftData['scroll'] as Map),
    );
    skill.forme.add(
      CharacterSkillForm.fromLegacy(
        nome: 'Forma 2',
        tipo: 'Attiva',
        costo: '0',
        cooldown: '0',
        descrizione: '',
      ),
    );
    final loaded = CharacterSkill.fromJson(skill.toJson());
    expect(loaded.nonEvolvibile, isTrue);
    expect(loaded.forme.length, 1);
    expect(loaded.scrollData, skill.scrollData);
    final old = CharacterSkill.fromJson({'nome': 'Vecchia', 'tipo': 'Attiva'});
    expect(old.nonEvolvibile, isFalse);
  });
}
