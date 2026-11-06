import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/pages/oculum_dungeon/monster_registry.dart';
import 'package:oculum/main.dart'
    show
        oculumBlackMarketMonsterBookPageEligible,
        oculumCelestialAllegiance,
        oculumRankBlackMarketMonsterBookPages;

const retiredCycleIds = [
  'ciclo_ragno_fili_giurati',
  'ciclo_rondine_respiro_lieve',
  'ciclo_viandante_ricordi_spenti',
  'ciclo_lepre_fiato_vetro',
];

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

  test('retired cycle sources cannot restore active encounters', () {
    configureMonsterBookEntries(customEntries: oculumCycleMonsterEntries);
    for (final id in retiredCycleIds) {
      final source = oculumCycleMonsterEntries.singleWhere((m) => m.id == id);
      final legacy = oculumSavedMonsterBookEntryById(id)!;
      expect(legacy.stats, source.stats);
      expect(legacy.skillIds, containsAll(source.skillIds));
      for (final retiredId in [
        id,
        '${id}_variante_errante',
        '${id}_variante_corazzata',
        '${id}_variante_rituale',
        '${id}_variante_veterana',
        '${id}_variante_personale',
      ]) {
        expect(oculumIsRetiredMonsterId(' $retiredId '), isTrue);
        expect(monsterById(retiredId), isNull);
      }
      expect(oculumIsRetiredMonsterId('${id}_personale'), isFalse);
      expect(
        defaultMonsterBookEntries.any((m) => m.id.startsWith(id)),
        isFalse,
      );
      expect(monsterBookEntries.any((m) => m.id.startsWith(id)), isFalse);
    }
    expect(monsterById('ciclo_cavaliere_filo_oro'), isNotNull);
    expect(monsterById('ciclo_custode_nastri_sospesi'), isNotNull);
    expect(monsterById('ciclo_larva_nome_vuoto'), isNotNull);
    expect(monsterById('ciclo_golem_brina_profonda'), isNotNull);
  });

  test('retired cycle species keep saved custom and Eye sources', () {
    for (final id in retiredCycleIds) {
      final custom = oculumSavedMonsterBookEntryById(id)!.copyWith(
        nameIt: 'Creatura personale salvata',
        stats: {'level': 9, 'resilienza': 41},
        skillIds: ['saved_cycle_skill'],
        imageBase64: 'c2F2ZWQtaW1hZ2U=',
        encounterRules: {'celestialIdentity': 'lunare', 'savedSetting': 7},
      );
      final variant = custom.copyWith(id: '${id}_variante_personale');
      configureMonsterBookEntries(customEntries: [custom, variant]);
      for (final entry in [custom, variant]) {
        final saved = oculumSavedMonsterBookEntryById(entry.id)!;
        final restored = MonsterBookEntry.fromJson(saved.toJson());
        expect(restored.nameIt, entry.nameIt);
        expect(restored.stats, entry.stats);
        expect(restored.skillIds, entry.skillIds);
        expect(restored.imageBase64, entry.imageBase64);
        expect(restored.encounterRules, entry.encounterRules);
        expect(getStatsForMonster(entry.id), entry.stats);
        expect(
          oculumCelestialAllegiance({'monsterBookSourceId': entry.id}),
          'lunare',
        );
        expect(monsterById(entry.id), isNull);
      }
      expect(monsterBookEntries.any((m) => m.id.startsWith(id)), isFalse);
      configureMonsterBookEntries(removedIds: [id, variant.id]);
      expect(oculumSavedMonsterBookEntryById(id), isNull);
      expect(oculumSavedMonsterBookEntryById(variant.id), isNull);
      resetMonsterBookEntries();
      expect(oculumSavedMonsterBookEntryById(id), isNotNull);
      expect(monsterById(id), isNull);
    }
  });

  test('retired cycle species cannot become new Black Market pages', () {
    for (final id in retiredCycleIds) {
      final retired = oculumSavedMonsterBookEntryById(
        id,
      )!.copyWith(nameIt: 'Creatura Errante personale');
      final control = retired.copyWith(id: 'test_cycle_market_control');
      expect(oculumBlackMarketMonsterBookPageEligible(control), isTrue);
      expect(oculumBlackMarketMonsterBookPageEligible(retired), isFalse);
      expect(
        oculumRankBlackMarketMonsterBookPages(
          entries: [retired, control],
          playerLevel: 9,
          playerStats: const {
            'resilienza': 7,
            'volonta': 8,
            'materia': 10,
            'oculum': 8,
          },
        ).map((entry) => entry.id),
        [control.id],
      );
    }
  });

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
