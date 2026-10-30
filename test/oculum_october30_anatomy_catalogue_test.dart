import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('new approved themes keep anatomy and materials of each species', () {
    final keeper = oculumMonsterPrecisionAnatomy(
      monsterBookEntryById('custode_campana_cieca')!,
    );
    expect(keeper.where((p) => p['group'] == 'eyes'), isEmpty);
    expect(keeper.where((p) => p['group'] == 'arms'), hasLength(2));
    expect(keeper.where((p) => p['group'] == 'legs'), hasLength(2));
    expect(
      keeper.singleWhere((p) => p['group'] == 'head')['material'],
      'metal',
    );
    final shaman = oculumMonsterPrecisionAnatomy(
      monsterBookEntryById('sciamano_malizioso')!,
    );
    expect(shaman.where((p) => p['group'] == 'arms'), hasLength(2));
    expect(shaman.where((p) => p['group'] == 'legs'), hasLength(2));
    expect(shaman.where((p) => p['group'] == 'eyes'), isEmpty);
    expect(shaman.singleWhere((p) => p['id'] == 'mask')['weak'], isTrue);
    final mammoth = oculumMonsterPrecisionAnatomy(
      monsterBookEntryById('mammuth_in_decomposizione')!,
    );
    expect(mammoth.where((p) => p['group'] == 'legs'), hasLength(4));
    expect(mammoth.where((p) => p['group'] == 'arms'), isEmpty);
    for (final group in ['eyes', 'ears', 'tusks']) {
      expect(mammoth.where((p) => p['group'] == group), hasLength(2));
    }
    expect(mammoth.where((p) => p['group'] == 'trunk'), hasLength(1));
    expect(mammoth.where((p) => p['group'] == 'tail'), hasLength(1));
    expect(
      mammoth
          .where((p) => p['group'] == 'tusks')
          .every((p) => p['material'] == 'bone'),
      isTrue,
    );
  });
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
      final anatomy = oculumMonsterPrecisionAnatomy(pine);
      expect(anatomy.where((p) => p['group'] == 'arms'), hasLength(2));
      expect(anatomy.where((p) => p['group'] == 'legs'), hasLength(2));
      final weak = anatomy.where((p) => p['weak'] == true).toList();
      expect(weak, hasLength(1));
      expect(weak.single['id'], 'soft_scale');
      expect(weak.single['material'], 'wood');
      expect(anatomy.where((p) => p['group'] == 'wound'), isEmpty);
      final variant = pine.copyWith(id: 'pinepine_variante_gelo');
      final variantAnatomy = oculumMonsterPrecisionAnatomy(variant);
      expect(variantAnatomy.where((p) => p['group'] == 'legs'), hasLength(2));
      expect(
        variantAnatomy.where((p) => p['id'] == 'soft_scale'),
        hasLength(1),
      );
      final custom = pine.copyWith(
        encounterRules: {
          ...pine.encounterRules,
          'precisionBodyParts': [
            {'id': 'master_scale', 'label': 'Squama scelta', 'weak': true},
          ],
        },
      );
      expect(oculumMonsterPrecisionAnatomy(custom), [
        {'id': 'master_scale', 'label': 'Squama scelta', 'weak': true},
      ]);
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
