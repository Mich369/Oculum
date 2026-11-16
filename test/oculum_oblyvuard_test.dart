import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('Oblyvuard has separate tree integrity and alternate spellings', () {
    final monster = monsterBookEntryById(oculumOblyvuardId)!;
    expect(monster.elementId, 'oblio');
    expect(monster.planeIds, ['oblio']);
    expect(
      oculumMonsterNameSearchAliases(monster),
      containsAll(['Oblyvuard', 'Oblivuard', 'Oblivward']),
    );
    final anatomy = oculumMonsterPrecisionAnatomy(monster);
    final tree = anatomy.singleWhere(
      (part) => part['id'] == oculumOblyvuardTreePart,
    );
    expect(tree['material'], 'wood');
    expect(anatomy.where((part) => part['group'] == 'arms'), hasLength(2));
    expect(anatomy.where((part) => part['group'] == 'legs'), hasLength(2));
    expect(
      anatomy.any(
        (part) => const {'weapon', 'shield', 'eyes'}.contains(part['group']),
      ),
      isFalse,
    );
    expect(
      monster.skillIds
          .where((id) => id.startsWith(oculumMonsterProgressionPrefix))
          .length,
      greaterThanOrEqualTo(9),
    );
  });

  test('special skills retain editable rules without inventing a penalty', () {
    final threshold = monsterBookConcreteTechnique(
      oculumOblyvuardSilentThreshold,
    )!;
    final slash = monsterBookConcreteTechnique(oculumOblyvuardOblivionSlash)!;
    expect(threshold.action, contains('vicino alle radici'));
    expect(threshold.action, contains('+4 CM'));
    expect(threshold.forms.first.single.formula, '4');
    expect(slash.action, contains('prossimo tiro di Memoria'));
    expect(slash.forms.first.single.criticalOnly, isTrue);
    expect(slash.forms.first.single.recipient, 'nemico');
    for (final skill in [threshold, slash]) {
      expect(skill.action, contains('Risoluzione manuale del Master'));
      expect(skill.costDescription, 'Costo e recupero da definire.');
    }
  });
}
