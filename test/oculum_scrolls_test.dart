import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
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
