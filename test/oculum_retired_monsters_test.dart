import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'custom legacy variants stay compatible without entering the manual',
    () {
      final custom = monsterBookEntryById('cuore_filo')!.copyWith(
        id: 'cuore_filo_variante_personale',
        stats: {'resilienza': 37},
      );
      configureMonsterBookEntries(customEntries: [custom]);
      expect(monsterBookEntryById(custom.id)!.stats['resilienza'], 37);
      expect(monsterBookEntries.any((e) => e.id == custom.id), isFalse);
    },
  );
  tearDown(resetMonsterBookEntries);

  test(
    'rejected Thread Heart and its variants leave the active manual catalogue',
    () {
      expect(
        defaultMonsterBookEntries.any((e) => oculumIsRetiredMonsterId(e.id)),
        isFalse,
      );
      expect(
        monsterBookEntries.any((e) => oculumIsRetiredMonsterId(e.id)),
        isFalse,
      );
      expect(monsterBookEntryById('specchio_mangiavoce'), isNotNull);
      // Retirement must not shift index-based variant styles of other species.
      expect(
        defaultMonsterBookEntries.any(
          (e) => e.id == 'specchio_mangiavoce_variante_veterana',
        ),
        isTrue,
      );
      expect(
        defaultMonsterBookEntries.any(
          (e) => e.id == 'scheletro_bombarolo_variante_corazzata',
        ),
        isTrue,
      );
    },
  );

  test(
    'legacy sheets still resolve the original definitions without reintroducing encounters',
    () {
      for (final id in ['cuore_filo', 'cuore_filo_variante_veterana']) {
        final legacy = monsterBookEntryById(id);
        expect(legacy, isNotNull, reason: id);
        expect(legacy!.skillIds, isNotEmpty);
        final restored = MonsterBookEntry.fromJson(legacy.toJson());
        expect(restored.id, id);
        expect(restored.stats, legacy.stats);
        expect(restored.skillIds, legacy.skillIds);
      }
      configureMonsterBookEntries();
      expect(monsterBookEntryById('cuore_filo'), isNotNull);
      expect(
        monsterBookEntries.any((e) => oculumIsRetiredMonsterId(e.id)),
        isFalse,
      );
    },
  );

  test(
    'saved custom legacy stats and abilities survive while the entry stays retired',
    () {
      final custom = monsterBookEntryById('cuore_filo')!.copyWith(
        nameIt: 'Nome personalizzato salvato',
        stats: {'level': 7, 'resilienza': 23},
        skillIds: ['custom_saved_skill'],
      );
      configureMonsterBookEntries(customEntries: [custom]);
      expect(monsterBookEntries.any((e) => e.id == custom.id), isFalse);
      expect(monsterBookEntryById(custom.id)!.stats['resilienza'], 23);
      expect(monsterBookEntryById(custom.id)!.skillIds, ['custom_saved_skill']);
      expect(custom.toJson()['nameIt'], 'Nome personalizzato salvato');
    },
  );

  test(
    'explicit removed IDs still prevent legacy lookups, reset restores compatibility only',
    () {
      configureMonsterBookEntries(
        removedIds: ['cuore_filo', 'cuore_filo_variante_veterana'],
      );
      expect(monsterBookEntryById('cuore_filo'), isNull);
      expect(monsterBookEntryById('cuore_filo_variante_veterana'), isNull);
      resetMonsterBookEntries();
      expect(monsterBookEntryById('cuore_filo'), isNotNull);
      expect(
        monsterBookEntries.any((e) => oculumIsRetiredMonsterId(e.id)),
        isFalse,
      );
    },
  );
}
