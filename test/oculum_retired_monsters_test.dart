import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/pages/oculum_dungeon/monster_registry.dart';
import 'package:oculum/main.dart' show oculumCelestialAllegiance;

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
    'retired saved sources retain registry stats and celestial identity',
    () {
      final personal = monsterBookEntryById('errante_con_la_sedia')!.copyWith(
        stats: {'level': 9, 'resilienza': 41},
        skillIds: ['saved_chair_skill'],
        encounterRules: {'celestialIdentity': 'lunare'},
      );
      configureMonsterBookEntries(customEntries: [personal]);
      expect(monsterById(personal.id), isNull);
      expect(oculumSavedMonsterBookEntryById(personal.id)!.skillIds, [
        'saved_chair_skill',
      ]);
      expect(getStatsForMonster(personal.id), personal.stats);
      expect(
        oculumCelestialAllegiance({'monsterBookSourceId': personal.id}),
        'lunare',
      );
      expect(
        monsterBookEntries.any((entry) => entry.id == personal.id),
        isFalse,
      );
      configureMonsterBookEntries(removedIds: [personal.id]);
      expect(oculumSavedMonsterBookEntryById(personal.id), isNull);
    },
  );

  test(
    'Chair Wanderer retires without shifting other variants or losing saved kits',
    () {
      const id = 'errante_con_la_sedia';
      for (final retiredId in [id, '${id}_variante_corazzata']) {
        expect(oculumIsRetiredMonsterId(retiredId), isTrue);
        expect(
          defaultMonsterBookEntries.any((e) => e.id == retiredId),
          isFalse,
        );
        final saved = monsterBookEntryById(retiredId)!;
        final restored = MonsterBookEntry.fromJson(saved.toJson());
        expect(restored.stats, saved.stats);
        expect(restored.skillIds, saved.skillIds);
      }
      final personal = monsterBookEntryById(id)!.copyWith(
        id: '${id}_variante_personale',
        stats: {'level': 9, 'resilienza': 41},
        skillIds: ['saved_chair_skill'],
      );
      configureMonsterBookEntries(customEntries: [personal]);
      expect(monsterBookEntryById(personal.id)!.stats['resilienza'], 41);
      expect(monsterBookEntryById(personal.id)!.skillIds, [
        'saved_chair_skill',
      ]);
      expect(monsterBookEntries.any((e) => e.id.startsWith(id)), isFalse);
      expect(monsterBookEntries.any((e) => e.id == 'fire_shield'), isTrue);
      expect(
        monsterBookEntries.any(
          (e) => e.id == 'specchio_mangiavoce_variante_veterana',
        ),
        isTrue,
      );
    },
  );

  test('Umbrella Wanderer and its Veteran remain saved-only sources', () {
    for (final id in [
      'errante_con_ombrello',
      'errante_con_ombrello_variante_veterana',
    ]) {
      expect(oculumIsRetiredMonsterId(id), isTrue);
      expect(monsterById(id), isNull);
      final source = oculumSavedMonsterBookEntryById(id)!;
      final restored = MonsterBookEntry.fromJson(source.toJson());
      expect(restored.stats, source.stats);
      expect(restored.skillIds, source.skillIds);
      expect(monsterBookEntries.any((entry) => entry.id == id), isFalse);
    }
  });

  test(
    'False Obser Spider is retired while saved sheets remain resolvable',
    () {
      const id = 'ragno_obser_falsi';
      expect(oculumIsRetiredMonsterId(id), isTrue);
      expect(oculumIsRetiredMonsterId(' ${id}_variante_personale '), isTrue);
      expect(oculumIsRetiredMonsterId('${id}_personale'), isFalse);
      expect(
        defaultMonsterBookEntries.any((e) => e.id.startsWith(id)),
        isFalse,
      );
      expect(monsterBookEntries.any((e) => e.id.startsWith(id)), isFalse);

      final legacy = monsterBookEntryById(id)!;
      final restored = MonsterBookEntry.fromJson(legacy.toJson());
      expect(restored.skillIds, legacy.skillIds);
      expect(restored.stats, legacy.stats);

      final custom = legacy.copyWith(
        id: '${id}_variante_personale',
        stats: {'level': 9, 'resilienza': 41},
        skillIds: ['saved_spider_skill'],
      );
      configureMonsterBookEntries(customEntries: [custom]);
      expect(monsterBookEntryById(custom.id)!.stats['resilienza'], 41);
      expect(monsterBookEntryById(custom.id)!.skillIds, ['saved_spider_skill']);
      expect(monsterBookEntries.any((e) => e.id.startsWith(id)), isFalse);

      configureMonsterBookEntries(removedIds: [id]);
      expect(monsterBookEntryById(id), isNull);
      resetMonsterBookEntries();
      expect(monsterBookEntryById(id), isNotNull);
      expect(monsterBookEntries.any((e) => e.id.startsWith(id)), isFalse);
    },
  );

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
