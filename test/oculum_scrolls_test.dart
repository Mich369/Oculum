import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('Drop scrolls start at 18 and grow one grade every 10', () {
    expect(oculumScrollDropGrade('forza', 138), isNull);
    expect(oculumScrollDropGrade('drop', 17), isNull);
    for (var grade = 0; grade <= 12; grade++) {
      expect(oculumScrollDropGrade('drop', 18 + grade * 10), grade);
      expect(oculumScrollDropGrade('drop', 27 + grade * 10), grade);
    }
    expect(oculumScrollDropGrade('drop', 999), 12);
  });
  test('Learning requires natural 20, grade threshold and 20 percent', () {
    for (var grade = 0; grade <= 12; grade++) {
      final threshold = 30 + 10 * grade;
      expect(oculumScrollCanLearn(19, threshold, grade, 0), isFalse);
      expect(oculumScrollCanLearn(20, threshold - 1, grade, 0), isFalse);
      expect(oculumScrollCanLearn(20, threshold, grade, 19), isTrue);
      expect(oculumScrollCanLearn(20, threshold, grade, 20), isFalse);
    }
  });
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
