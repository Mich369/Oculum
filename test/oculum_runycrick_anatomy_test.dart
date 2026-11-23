import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  MonsterBookEntry runycrick() => monsterBookEntryById('base_postea_02')!;

  test('Runycrick G has six separate legs and two separate membrane wings', () {
    final entry = runycrick();
    final before = entry.toJson();
    final parts = oculumMonsterPrecisionAnatomy(entry);
    expect(parts.map((part) => part['id']).toSet(), {
      'body',
      'joint',
      'legs_1',
      'legs_2',
      'legs_3',
      'legs_4',
      'legs_5',
      'legs_6',
      'wings_1',
      'wings_2',
    });
    final legs = parts.where((part) => part['group'] == 'legs').toList();
    final wings = parts.where((part) => part['group'] == 'wings').toList();
    expect(legs, hasLength(6));
    expect(wings, hasLength(2));
    for (var pair = 0; pair < 3; pair++) {
      expect(legs[pair * 2]['side'], 'right');
      expect(legs[pair * 2 + 1]['side'], 'left');
      expect(legs[pair * 2]['sideIndex'], pair + 1);
      expect(legs[pair * 2 + 1]['sideIndex'], pair + 1);
    }
    expect(wings.map((part) => part['side']), ['right', 'left']);
    expect(
      parts.where((part) => part['weak'] == true).map((part) => part['id']),
      ['joint'],
    );
    for (final part in [...legs, ...wings]) {
      expect(part['weak'], isFalse);
      expect(part['penalty'], 0);
    }
    expect(entry.toJson(), before);
  });

  test('A saved Master anatomy wins and survives its JSON round trip', () {
    final customParts = <Map<String, dynamic>>[
      {
        'id': 'master_left_leg',
        'label': 'Zampa personale',
        'group': 'legs',
        'side': 'left',
        'weak': true,
        'penalty': 4,
        'material': 'crystal',
      },
    ];
    final custom = runycrick().copyWith(
      encounterRules: {
        ...runycrick().encounterRules,
        'precisionBodyParts': customParts,
      },
    );
    final saved = custom.toJson();
    final restored = MonsterBookEntry.fromJson(saved);
    final parts = oculumMonsterPrecisionAnatomy(restored);
    expect(parts, customParts);
    expect(parts, hasLength(1));
    expect(restored.toJson(), saved);
    parts.single['label'] = 'Local copy only';
    expect(
      (restored.encounterRules['precisionBodyParts'] as List).single['label'],
      'Zampa personale',
    );
  });

  test(
    'The selected base does not impose limbs on unreviewed Postea entries',
    () {
      for (final id in [
        'qa_other_postea',
        'base_postea_02_variante_unreviewed',
      ]) {
        final other = runycrick().copyWith(id: id);
        final parts = oculumMonsterPrecisionAnatomy(other);
        expect(parts.where((part) => part['group'] == 'legs'), isEmpty);
        expect(parts.where((part) => part['group'] == 'wings'), isEmpty);
        expect(
          parts.where((part) => part['weak'] == true).map((part) => part['id']),
          ['joint'],
        );
      }
    },
  );
}
