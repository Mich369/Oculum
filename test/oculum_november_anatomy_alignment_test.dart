import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'RockShield and Runic Golem use approved limbs on base and variants',
    () {
      for (final id in ['rock_shield', 'golem_runico']) {
        final base = monsterBookEntryById(id)!;
        for (final entry in [base, base.copyWith(id: '${id}_variante_qa')]) {
          final parts = oculumMonsterPrecisionAnatomy(entry);
          expect(parts.where((p) => p['group'] == 'arms'), hasLength(2));
          expect(parts.where((p) => p['group'] == 'legs'), hasLength(2));
          expect(parts.where((p) => p['group'] == 'wings'), isEmpty);
          if (id == 'golem_runico') {
            expect(parts.where((p) => p['group'] == 'eyes'), isEmpty);
          }
        }
      }
    },
  );

  test('saved Master anatomy retains priority over new artwork defaults', () {
    for (final id in ['rock_shield', 'golem_runico']) {
      final base = monsterBookEntryById(id)!;
      final custom = base.copyWith(
        encounterRules: {
          ...base.encounterRules,
          'precisionBodyParts': [
            {
              'id': 'master_part',
              'labelIt': 'Parte personale',
              'group': 'custom',
              'weak': false,
            },
          ],
        },
      );
      final parts = oculumMonsterPrecisionAnatomy(custom);
      expect(parts, hasLength(1));
      expect(parts.single['id'], 'master_part');
    }
  });
}
