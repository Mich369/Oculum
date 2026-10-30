import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'approved Forest Demon anatomy is reptilian with four legs and three horns',
    () {
      final parts = oculumMonsterPrecisionAnatomy(
        monsterBookEntryById('forest_demon')!,
      );
      expect(parts.where((p) => p['group'] == 'legs'), hasLength(4));
      expect(parts.where((p) => p['group'] == 'horns'), hasLength(3));
      expect(parts.where((p) => p['group'] == 'arms'), isEmpty);
      expect(parts.where((p) => p['group'] == 'wings'), isEmpty);
      final blue = oculumMonsterPrecisionAnatomy(
        monsterBookEntryById('ciclo_forest_demon_blu')!,
      );
      expect(blue.where((p) => p['group'] == 'legs'), hasLength(4));
      expect(blue.where((p) => p['group'] == 'horns'), hasLength(2));
      expect(blue.where((p) => p['group'] == 'wings'), isEmpty);
    },
  );
  test(
    'Pinepine is intact and its softer scale replaces pre-existing wounds',
    () {
      final pine = monsterBookEntryById('pinepine')!;
      expect(pine.weakPointDescriptionIt, contains('squama'));
      expect(pine.weakPointDescriptionIt, contains('integra'));
      expect(pine.descIt, isNot(contains('Ferite Aperte')));
      expect(pine.descEn, isNot(contains('open wounds')));
      expect(pine.descIt, contains('Fuoco'));
      expect(
        pine.copyWith(weakPointIt: 'Scelta del Master').weakPointDescriptionIt,
        'Scelta del Master',
      );
    },
  );

  test(
    'Massiccio redistributes base points without replacing conscious demon',
    () {
      final base = monsterBookEntryById('mezzo_demone_cosciente')!;
      final heavy = monsterBookEntryById('mezzo_demone_massiccio')!;
      const stats = ['resilienza', 'volonta', 'materia', 'oculum'];
      expect(
        heavy.stats['resilienza']!,
        greaterThan(base.stats['resilienza']!),
      );
      for (final key in stats.skip(1)) {
        expect(heavy.stats[key]!, lessThan(base.stats[key]!));
      }
      int sum(MonsterBookEntry e) =>
          stats.fold(0, (v, key) => v + e.stats[key]!);
      expect(sum(heavy), sum(base));
      expect(heavy.stats['level'], base.stats['level']);
      expect(
        heavy.skillIds,
        containsAll(['half_demon_rake', 'half_demon_guard']),
      );
      expect(
        heavy.skillIds.where(
          (id) => id.startsWith('growth__mezzo_demone_massiccio__'),
        ),
        hasLength(12),
      );
      expect(base.descIt, contains('verticale'));
      expect(heavy.descIt, contains('orizzontale'));
      final anatomy = oculumMonsterPrecisionAnatomy(heavy);
      for (final group in ['arms', 'legs', 'eyes', 'horns']) {
        expect(anatomy.where((p) => p['group'] == group), hasLength(2));
      }
    },
  );
}
