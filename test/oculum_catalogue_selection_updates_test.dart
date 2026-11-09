import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

Object? _withoutEffectInstanceIds(Object? value) {
  if (value is List) return value.map(_withoutEffectInstanceIds).toList();
  if (value is Map) {
    final isEffect =
        value.containsKey('type') && value.containsKey('valueExpression');
    return {
      for (final entry in value.entries)
        if (!isEffect || entry.key != 'id')
          entry.key: _withoutEffectInstanceIds(entry.value),
    };
  }
  return value;
}

void main() {
  tearDown(resetMonsterBookEntries);

  test('confirmed nicknames retain their identity and respect custom names', () {
    const id = 'habitat_shadow_hell_caprone_della_memoria_bruciata';
    final entry = monsterById(id)!;
    expect(entry.nameIt, 'Remnath');
    expect(entry.speciesNameIt, 'Caprone della memoria bruciata');
    expect(entry.creationProfileName, startsWith(entry.speciesNameIt));
    expect(monsterById('hero_path_rosso')!.nameIt, 'Baghest Slave');
    expect(monsterById('dalatro')!.nameIt, 'Dalàtro');
    final restored = MonsterBookEntry.fromJson(entry.toJson());
    expect(restored.speciesNameIt, entry.speciesNameIt);
    expect(restored.creationProfileName, entry.creationProfileName);

    configureMonsterBookEntries(
      customEntries: [entry.copyWith(nameIt: 'Caprone personale')],
    );
    expect(monsterById(id)!.nameIt, 'Caprone personale');
  });

  test(
    'new names preserve original identities and historical artwork votes',
    () {
      const dollId = 'habitat_morti_bambola_di_ceneri';
      expect(monsterById(dollId)!.nameIt, 'Cinerstitch');
      expect(monsterById(dollId)!.speciesNameIt, 'Bambola di ceneri');
      expect(oculumNovember8VotedMonsterIds.contains(dollId), isFalse);
      expect(
        monsterById('${dollId}_variante_corazzata')!.nameIt,
        'Little CinerShield',
      );
      expect(
        monsterById('aberrazione_oro_marmo_intermedia_angelica')!.nameIt,
        "Aberrazione d'Oro",
      );
      expect(
        monsterById(
          'habitat_vero_inferno_araldo_della_cenere_eterna_variante_rituale',
        )!.nameIt,
        'Mostro Infernale',
      );
      expect(monsterById('arcangelo')!.nameIt, 'Arcangelo');
    expect(
      monsterById('baby_forest_demon_variante_rituale')!.nameIt,
      'Silvarkrath',
    );
      expect(
        monsterById('arpia_base_variante_veterana')!.nameIt,
        'Arpia Veterana',
      );
      expect(
        monsterById('habitat_postea_automate_infermiere_guasto')!.nameIt,
        'Automate infermiere guasto',
      );
    },
  );

  test('quick creation uses exact aliases and requires a unique identity', () {
    const ardea = 'habitat_isole_airone_delle_correnti_inverse';
    const tombHerald = 'habitat_morti_araldo_delle_tombe_aperte';
    const tombKnight = 'habitat_morti_cavaliere_senza_epitaffio';
    expect(
      oculumMonsterBookEntryForGeneratedEntity('', 'Ardea Upstream')?.id,
      ardea,
    );
    expect(
      oculumMonsterBookEntryForGeneratedEntity('', 'Ardea Upstream Elité')?.id,
      '${ardea}_variante_rituale',
    );
    expect(
      oculumMonsterBookEntryForGeneratedEntity(
        'Incontro con Ardea Upstream Elité',
        '',
      )?.id,
      '${ardea}_variante_rituale',
    );
    expect(monsterById(tombHerald)!.nameIt, 'Tombwake');
    expect(monsterById(tombKnight)!.nameIt, 'Tombwake');
    expect(oculumMonsterBookEntryForGeneratedEntity('', 'Tombwake'), isNull);
    expect(
      oculumMonsterBookEntryForGeneratedEntity('', tombHerald)?.id,
      tombHerald,
    );
    expect(
      oculumMonsterBookEntryForGeneratedEntity(tombKnight, 'Tombwake')?.id,
      tombKnight,
    );
    expect(
      oculumMonsterBookEntryForGeneratedEntity(
        'Araldo delle tombe aperte',
        'Tombwake',
      )?.id,
      tombHerald,
    );
    expect(
      oculumMonsterBookEntryForGeneratedEntity(
        '',
        'Cavaliere senza epitaffio',
      )?.id,
      tombKnight,
    );

    final base = monsterById(ardea)!;
    final variant = monsterById('${ardea}_variante_rituale')!;
    configureMonsterBookEntries(
      customEntries: [
        variant.copyWith(
          encounterRules: {
            ...variant.encounterRules,
            'speciesNameIt': base.nameIt,
            'speciesNameEn': base.nameEn,
          },
        ),
      ],
    );
    expect(
      oculumMonsterBookEntryForGeneratedEntity('', base.nameIt)?.id,
      base.id,
    );
    expect(
      oculumMonsterBookEntryForGeneratedEntity('', variant.nameIt)?.id,
      variant.id,
    );
  });

  test('the three exact new retirements retain saved skill and Open data', () {
    const selected = {
      'hero_path_alce': 'rituale',
      'habitat_morti_araldo_delle_tombe_aperte': 'errante',
      'habitat_postea_automate_infermiere_guasto': 'rituale',
    };
    final custom = <MonsterBookEntry>[];
    for (final row in selected.entries) {
      final id = '${row.key}_variante_${row.value}';
      final saved = oculumSavedMonsterBookEntryById(id)!;
      expect(monsterById(row.key), isNotNull, reason: row.key);
      expect(monsterById(id), isNull, reason: id);
      expect(oculumIsRetiredMonsterId(id), isTrue, reason: id);
      expect(
        oculumMonsterBookEntryForGeneratedEntity('', id),
        isNull,
        reason: id,
      );
      expect(
        oculumBlackMarketMonsterBookPageEligible(saved),
        isFalse,
        reason: id,
      );
      expect(monsterBookUsableSkillIds(saved), isNotEmpty, reason: id);
      custom.add(
        saved.copyWith(
          skillIds: [...saved.skillIds, 'personal_saved_skill'],
          encounterRules: {
            ...saved.encounterRules,
            'savedOpen': 'Open personale',
          },
        ),
      );
    }
    configureMonsterBookEntries(customEntries: custom);
    for (final saved in custom) {
      expect(monsterById(saved.id), isNull);
      expect(
        oculumSavedMonsterBookEntryById(saved.id)!.toJson(),
        saved.toJson(),
      );
    }
  });

  test('manual exclusions preserve playable sources and their skills', () {
    for (final id in const [
      'habitat_mezzano_corvo_delle_monete_false',
      'habitat_mezzano_corvo_delle_monete_false_variante_rituale',
      'habitat_demoniaco_custode_dei_chiodi_roventi',
      'habitat_demoniaco_custode_dei_chiodi_roventi_variante_veterana',
    ]) {
      final entry = monsterById(id)!;
      expect(entry.visibleInMonsterBook, isFalse, reason: id);
      expect(oculumIsRetiredMonsterId(id), isFalse, reason: id);
      expect(monsterBookUsableSkillIds(entry), isNotEmpty, reason: id);
      expect(oculumSavedMonsterBookEntryById(id), same(entry));
      expect(
        oculumBlackMarketMonsterBookPageEligible(
          entry.copyWith(classificationTags: ['Aberrazione']),
        ),
        isFalse,
        reason: id,
      );
    }
  });

  test('only the named Duelist Wanderer retires, keeping its saved kit', () {
    const baseId = 'duellante_senza_palpebre';
    const retiredId = '${baseId}_variante_errante';
    expect(oculumIsRetiredMonsterId(baseId), isFalse);
    expect(oculumIsRetiredMonsterId(' $retiredId '), isTrue);
    expect(oculumIsRetiredMonsterId('${baseId}_variante_personale'), isFalse);
    expect(oculumIsRetiredMonsterId('${baseId}_variante_veterana'), isFalse);
    expect(monsterById(baseId), isNotNull);
    expect(monsterById(retiredId), isNull);
    final saved = oculumSavedMonsterBookEntryById(retiredId)!;
    expect(saved.skillIds, contains('eyelidless_read_variante_errante'));
    expect(oculumBlackMarketMonsterBookPageEligible(saved), isFalse);
    final personal = saved.copyWith(
      nameIt: 'Duellante Errante personale',
      stats: {'level': 8, 'resilienza': 31},
      skillIds: ['saved_duelist_skill'],
      imageBase64: 'saved-art',
    );
    configureMonsterBookEntries(customEntries: [personal]);
    expect(monsterBookEntries.any((entry) => entry.id == retiredId), isFalse);
    expect(
      oculumSavedMonsterBookEntryById(retiredId)!.toJson(),
      personal.toJson(),
    );
  });

  test(
    'Sacristan family is saved-only, including hidden historical variants',
    () {
      const id = 'weak_horror_sagrestano';
      final source = oculumSavedMonsterBookEntryById(id)!;
      for (final suffix in [
        '',
        '_variante_errante',
        '_variante_corazzata',
        '_variante_rituale',
        '_variante_veterana',
      ]) {
        final retiredId = '$id$suffix';
        expect(oculumIsRetiredMonsterId(retiredId), isTrue);
        expect(monsterById(retiredId), isNull);
        final legacy = oculumSavedMonsterBookEntryById(retiredId)!;
        expect(legacy.skillIds, isNotEmpty);
        expect(oculumBlackMarketMonsterBookPageEligible(legacy), isFalse);
      }
      final custom = source.copyWith(
        id: '${id}_variante_personale',
        nameIt: 'Sagrestano salvato',
        stats: {'level': 4, 'volonta': 39},
        skillIds: ['saved_sacristan_skill'],
      );
      configureMonsterBookEntries(customEntries: [custom]);
      expect(
        monsterBookEntries.any((entry) => entry.id.startsWith(id)),
        isFalse,
      );
      expect(
        oculumSavedMonsterBookEntryById(custom.id)!.toJson(),
        custom.toJson(),
      );
      configureMonsterBookEntries(removedIds: ['${id}_variante_rituale']);
      expect(oculumSavedMonsterBookEntryById(id), isNotNull);
      expect(oculumSavedMonsterBookEntryById('${id}_variante_rituale'), isNull);
      configureMonsterBookEntries(removedIds: [id]);
      expect(oculumSavedMonsterBookEntryById(id), isNull);
      expect(oculumSavedMonsterBookEntryById('${id}_variante_rituale'), isNull);
    },
  );

  test('Assassin is an enemy NPC without changing its catalogue build', () {
    final assassin = monsterById('duellante_senza_palpebre')!;
    expect(assassin.nameIt, 'Assassino');
    expect(assassin.isNpc, isTrue);
    expect(assassin.presetType, 'NPC');
    expect(assassin.generationSide, 'enemy');
    expect(assassin.stats, {
      'level': 24,
      'resilienza': 27,
      'volonta': 21,
      'materia': 24,
      'oculum': 17,
    });
    expect(
      assassin.skillIds,
      containsAll([
        'eyelidless_read',
        'eyelidless_crosscut',
        'eyelidless_riposte',
      ]),
    );
    expect(assassin.inventoryItems.first['bonusDanno'], 34);
    expect(assassin.inventoryItems.last['bonusDifesa'], 7);
    final previousRules = Map<String, dynamic>.from(assassin.encounterRules)
      ..remove('generationSide')
      ..remove('creationStatType')
      ..remove('creationProfileName');
    final oldProfile = assassin.copyWith(
      nameIt: 'Duellante Senza Palpebre',
      nameEn: 'Eyelidless Duelist',
      descIt: assassin.descIt.replaceAll(
        'Assassino',
        'Duellante Senza Palpebre',
      ),
      descEn: assassin.descEn.replaceAll(
        'Assassino',
        'Duellante Senza Palpebre',
      ),
      isNpc: false,
      encounterRules: previousRules,
    );
    for (final level in [0, 1, 10, 24, 30]) {
      expect(
        oculumMonsterCreationStats(assassin, level),
        oculumMonsterCreationStats(oldProfile, level),
        reason: 'level $level',
      );
    }
    final custom = assassin.copyWith(
      nameIt: 'Duellante personale',
      isNpc: false,
      encounterRules: const {},
      stats: {'level': 6, 'resilienza': 48},
      skillIds: ['saved_personal_skill'],
    );
    configureMonsterBookEntries(customEntries: [custom]);
    final restored = monsterById(assassin.id)!;
    expect(restored.toJson(), custom.toJson());
    expect(restored.isNpc, isFalse);
    expect(restored.presetType, 'Mostro Mini Boss');
  });

  test(
    'Armorer base and Ritual keep separate IDs and inherit the new name',
    () {
      final base = monsterById('armaiolo_della_fila_lunga')!;
      final ritual = monsterById('armaiolo_della_fila_lunga_variante_rituale')!;
      expect(base.nameIt, 'Armaiolo della spada e scudo');
      expect(ritual.nameIt, 'Armaiolo della spada e scudo Rituale');
      expect(base.id, isNot(ritual.id));
      expect(base.stats['level'], 82);
      expect(base.isBoss, isTrue);
      expect(base.skillIds, contains('longrank_style'));
      expect(ritual.skillIds, contains('longrank_style_variante_rituale'));
      final custom = MonsterBookEntry.fromJson(
        base
            .copyWith(
              nameIt: 'Armaiolo personale',
              imageBase64: 'saved-custom-image',
              skillIds: ['custom_armorer_skill'],
              stats: {'level': 3, 'materia': 44},
            )
            .toJson(),
      );
      configureMonsterBookEntries(customEntries: [custom]);
      expect(monsterById(base.id)!.toJson(), custom.toJson());
    },
  );

  test('Beetle size is descriptive and retains its existing baseline', () {
    final beetle = monsterById('ciclo_scarabeo_sigillo_ardente')!;
    expect(beetle.descIt, contains('grande circa 2 metri'));
    expect(beetle.stats['level'], 1);
    for (final key in ['resilienza', 'volonta', 'materia', 'oculum']) {
      expect(beetle.stats[key], 2, reason: key);
    }
    expect(beetle.elementId, 'solare');
  });

  test('Bruto Sorridente keeps its stable IDs and saved personal name', () {
    const id = 'inspired_bruto_sorriso_cavo';
    final base = monsterById(id)!;
    final variant = monsterById('${id}_variante_corazzata')!;
    expect(base.nameIt, 'Bruto Sorridente');
    expect(variant.nameIt, 'Bruto Sorridente Corazzata');
    expect(base.stats, {
      'level': 0,
      'resilienza': 8,
      'volonta': 2,
      'materia': 3,
      'oculum': 1,
    });
    expect(base.skillIds, contains('inspired_bruto_sorriso_cavo_attack'));
    final custom = MonsterBookEntry.fromJson(
      base
          .copyWith(
            nameIt: 'Bruto personale',
            stats: {'level': 3, 'resilienza': 23},
            imageBase64: 'c2F2ZWQtYXJ0',
          )
          .toJson(),
    );
    configureMonsterBookEntries(customEntries: [custom]);
    expect(monsterById(id)!.toJson(), custom.toJson());
  });

  test('Keeper and Ritual retire while preserving their saved definitions', () {
    const id = 'custode_mani_inverse';
    const ritualId = '${id}_variante_rituale';
    final keeper = oculumSavedMonsterBookEntryById(id)!;
    final ritual = oculumSavedMonsterBookEntryById(ritualId)!;
    expect(keeper.stats, {'hp': 170, 'atk': 29, 'def': 26, 'spd': 10});
    expect(keeper.skillIds, contains('inverse_parry'));
    expect(ritual.skillIds, contains('inverse_parry_variante_rituale'));

    final custom = MonsterBookEntry.fromJson(
      ritual
          .copyWith(
            nameIt: 'Custode salvato dal Master',
            stats: {'level': 8, 'resilienza': 31},
            skillIds: ['saved_keeper_skill'],
            imageBase64: 'c2F2ZWQtYXJ0',
          )
          .toJson(),
    );
    configureMonsterBookEntries(customEntries: [custom]);
    for (final retiredId in [id, ritualId]) {
      expect(oculumIsRetiredMonsterId(retiredId), isTrue);
      expect(monsterById(retiredId), isNull);
      expect(monsterBookEntries.any((entry) => entry.id == retiredId), isFalse);
      expect(
        oculumBlackMarketMonsterBookPageEligible(
          oculumSavedMonsterBookEntryById(retiredId)!,
        ),
        isFalse,
      );
    }
    expect(
      oculumSavedMonsterBookEntryById(ritualId)!.toJson(),
      custom.toJson(),
    );
  });

  test(
    'Magma Heart inherits natural flight without changing its combat pool',
    () {
      const id = 'cuore_lava';
      final magma = monsterById(id)!;
      final variant = monsterById('${id}_variante_corazzata')!;
      expect(magma.nameIt, 'Cuore di Magma');
      expect(magma.nameEn, 'Magma Heart');
      expect(variant.nameIt, 'Armored Emberheart');
      expect(variant.speciesNameIt, 'Cuore di Magma Corazzata');
      expect(magma.hasNaturalFlight, isTrue);
      expect(variant.hasNaturalFlight, isTrue);
      expect(magma.descIt, contains('capace di volo naturale'));
      expect(monsterById('golem_lava')!.hasNaturalFlight, isFalse);
      expect(monsterById('ciclo_solare_siccita')!.hasNaturalFlight, isTrue);
      expect(magma.stats, {
        'level': 0,
        'resilienza': 10,
        'volonta': 6,
        'materia': 8,
        'oculum': 8,
      });
      expect(magma.skillIds.take(3), [
        'lava_heart_burst',
        'lava_regeneration_core',
        'lava_heart_fissure',
      ]);
      expect(magma.dropChances, {
        'lava_tear_core': 80,
        'metallo_runico': 30,
        'corno_forest_demon': 10,
      });

      final previous = magma.copyWith(
        nameIt: 'Cuore della Caldera',
        nameEn: 'Caldera Heart',
        descIt: magma.descIt
            .replaceAll(', capace di volo naturale', '')
            .replaceAll('Cuore di Magma', 'Cuore della Caldera'),
        descEn: magma.descEn
            .replaceAll(' capable of natural flight', '')
            .replaceAll(', capace di volo naturale', '')
            .replaceAll('Cuore di Magma', 'Cuore della Caldera'),
        encounterRules: const {},
      );
      for (final level in [0, 12, 50]) {
        expect(
          oculumMonsterCreationStats(magma, level),
          oculumMonsterCreationStats(previous, level),
        );
      }
      for (var seed = 0; seed < 8; seed++) {
        expect(
          oculumEnemyAbilityVariants(
            magma,
            seed: seed,
          ).map((skill) => skill.nome),
          oculumEnemyAbilityVariants(previous, seed: seed).map(
            (skill) => skill.nome.replaceAll(
              ' — Cuore della Caldera',
              ' — Cuore di Magma',
            ),
          ),
        );
      }

      final custom = MonsterBookEntry.fromJson(
        magma
            .copyWith(
              nameIt: 'Cuore personale',
              encounterRules: const {'naturalFlight': false},
            )
            .toJson(),
      );
      configureMonsterBookEntries(customEntries: [custom]);
      final saved = oculumSavedMonsterBookEntryById(id)!;
      expect(saved.nameIt, 'Cuore personale');
      expect(saved.hasNaturalFlight, isFalse);
      expect(saved.toJson(), custom.toJson());
    },
  );

  testWidgets(
    'the token flight command spends remaining Movement and saves elevation',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1600, 1400),
      );
      final probe = OculumPerformanceProbe(state);
      const tag = '123-TESTFLIGHT';
      final sheet = {
        ...probe.snapshot(),
        'id': tag,
        'sheetTag': tag,
        'nome': 'Cuore di Magma',
        'monsterBookSourceId': 'cuore_lava',
        'planarRuntime': <String, dynamic>{},
      };
      state.schedePersonaggio
        ..clear()
        ..add(sheet);
      state.schedaCorrente = 0;
      probe.load(sheet);
      expect(probe.cycleFlight(), 0);
      sheet['monsterBookSourceId'] = 'ciclo_solare_siccita';
      expect(probe.cycleFlight(), 3);
      sheet['monsterBookSourceId'] = 'cuore_lava';
      final budget = probe.movement().toDouble();
      expect(budget, greaterThan(7));
      final token = <String, dynamic>{
        'id': 'flight-test',
        'sheetTag': tag,
        'ownerTag': tag,
        'x': .5,
        'y': .3,
        'elevationMeters': 2.0,
        'movementUsedMeters': budget - 5,
        'visible': true,
      };
      state.updateOculumHomeUi(() {
        state.modalitaMaster = true;
        state.linguaInglese = false;
        state.mapMode = 'local';
        state.localMapTokens
          ..clear()
          ..add(token);
      });
      final mapReady = state.vaiAllaFunzione(page: 10) as Future<void>;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await mapReady;
      final tokenView = find.byKey(
        const ValueKey('vtt_local_token_flight-test'),
      );
      final mapScroll = find
          .descendant(
            of: find.byKey(state.sheetScrollKey('map') as Key),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(tokenView, 300, scrollable: mapScroll);
      expect(
        find.descendant(of: tokenView, matching: find.text('Cuore di Magma')),
        findsOneWidget,
      );

      Future<void> openMenu() async {
        await tester.ensureVisible(tokenView);
        await tester.pump();
        await tester.longPress(tokenView);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text('Modifica token'), findsOneWidget);
      }

      Future<void> flyTo(String elevation) async {
        await openMenu();
        await tester.tap(find.text('Movimento in volo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.enterText(
          find.byKey(const ValueKey('vtt_natural_flight_elevation')),
          elevation,
        );
        await tester.tap(find.text('Vola'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
      }

      await flyTo('20,5');
      expect(token['elevationMeters'], 7.0);
      expect(token['movementUsedMeters'], budget);
      final vtt = state.vttState as OculumVttState;
      final restored = OculumVttState.fromJson(vtt.toJson());
      expect(restored.activeScene.tokens.single['elevationMeters'], 7.0);
      expect(restored.activeScene.tokens.single['movementUsedMeters'], budget);
      final sharedScene = OculumVttScene.fromJson(
        vtt.activeScene.toJson(includePrivate: false),
      );
      expect(sharedScene.tokens.single['elevationMeters'], 7.0);

      await flyTo('0');
      expect(token['elevationMeters'], 7.0);
      await openMenu();
      await tester.tap(find.text('Reset movimento'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await flyTo('0');
      expect(token['elevationMeters'], 0.0);
      expect(token['movementUsedMeters'], 7.0);

      state.schedePersonaggio[0]['monsterBookSourceId'] = 'golem_lava';
      await openMenu();
      expect(find.text('Movimento in volo'), findsNothing);
      expect(find.text('Modifica token'), findsOneWidget);
      await closeFixture(tester, probe);
    },
  );

  test(
    'Assassin still draws three techniques while other NPC kits stay fixed',
    () {
      final assassin = monsterById('duellante_senza_palpebre')!;
      expect(assassin.encounterRules['loadoutPolicy'], 'sample_three');
      final naturalPool = oculumMonsterBookSkills(assassin);
      final artPool = oculumMonsterBookImportArt(assassin)!;
      final techniqueNames = {
        for (final skill in naturalPool)
          if (!skill.passiva) skill.nome,
        for (final skill in artPool.skills)
          if (!skill.tipoPerLivello(1).toLowerCase().contains('passiv'))
            skill.nome,
      };
      expect(techniqueNames.length, greaterThan(3));
      final openNames = oculumMonsterBookOpenPool(
        assassin,
      ).map((art) => art.openName).toSet();
      expect(openNames, isNotEmpty);
      final selections = <String>{};
      for (var seed = 0; seed < 16; seed++) {
        final loadout = oculumMonsterBookLoadout(
          assassin,
          level: 24,
          random: Random(seed),
        );
        final active = [
          for (final skill in loadout.skills)
            if (!skill.passiva) skill.nome,
          for (final skill in loadout.art!.skills)
            if (!skill.tipoPerLivello(1).toLowerCase().contains('passiv'))
              skill.nome,
        ];
        expect(active, hasLength(3));
        expect(active.toSet(), hasLength(3));
        expect(active, everyElement(isIn(techniqueNames)));
        expect(openNames, contains(loadout.art!.openName));
        selections.add((active..sort()).join('|'));
      }
      expect(selections.length, greaterThan(1));

      for (final fixed in [
        monsterById('meccanio')!,
        assassin.copyWith(nameIt: 'Assassino personale'),
      ]) {
        final loadout = oculumMonsterBookLoadout(fixed, random: Random(1));
        expect(
          loadout.skills.map((skill) => skill.toJson()).toList(),
          oculumMonsterBookSkills(
            fixed,
          ).map((skill) => skill.toJson()).toList(),
        );
        final fixedArt = oculumMonsterBookImportArt(fixed);
        expect(
          _withoutEffectInstanceIds(loadout.art?.toJson()),
          _withoutEffectInstanceIds(fixedArt?.toJson()),
        );
        expect(
          oculumMonsterBookOpenPool(fixed),
          hasLength(fixedArt == null ? 0 : 1),
        );
      }
    },
  );

  test(
    'Undead Cyclops and Spiral Sentinel have a single central Precision target',
    () {
      final cyclops = monsterById('ciclope_non_morto')!;
      final sentinel = monsterById('inspired_sentinella_spirale')!;
      final cyclopsParts = oculumMonsterPrecisionAnatomy(cyclops);
      expect(
        cyclopsParts.where((part) => part['group'] == 'arms'),
        hasLength(2),
      );
      expect(
        cyclopsParts.where((part) => part['group'] == 'legs'),
        hasLength(2),
      );
      for (final (source, label) in [
        (cyclops, 'Occhio centrale'),
        (sentinel, 'Lente centrale'),
      ]) {
        final eyes = oculumMonsterPrecisionAnatomy(
          source,
        ).where((part) => part['group'] == 'eyes').toList();
        expect(eyes, hasLength(1), reason: source.id);
        expect(eyes.single['id'], 'eyes');
        expect(eyes.single['label'], label);
        expect(eyes.single.containsKey('side'), isFalse);

        const personal = [
          {
            'id': 'personal_joint',
            'label': 'Giuntura personale',
            'group': 'joint',
            'weak': true,
            'penalty': 0,
          },
        ];
        final custom = MonsterBookEntry.fromJson(
          source
              .copyWith(
                encounterRules: {
                  ...source.encounterRules,
                  'precisionBodyParts': personal,
                },
              )
              .toJson(),
        );
        configureMonsterBookEntries(customEntries: [custom]);
        expect(
          oculumMonsterPrecisionAnatomy(monsterById(source.id)!),
          personal,
        );
      }
    },
  );

  test(
    'Cyclops description records the approved eye and short spine crest',
    () {
      final cyclops = monsterById('ciclope_del_fato')!;
      for (final detail in [
        'un solo occhio con iride violetta e pupilla verticale',
        'due orecchie appuntite',
        'due braccia robuste e due gambe corte',
        'breve cresta di spine ossee scure',
        'senza capelli',
        'Non è ostile senza motivo',
      ]) {
        expect(cyclops.descIt, contains(detail));
      }
      expect(cyclops.elementId, 'oculum');
      expect(
        cyclops.skillIds,
        containsAll(['fate_attack', 'fate_defense', 'ocular_ray']),
      );
      expect(cyclops.dropIds, ['occhio_del_fato']);
    },
  );

  testWidgets(
    'actual generation creates an enemy NPC and keeps legacy sheets',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.modalitaMaster = true;
      state.datiCaricati = false;
      state.quickSheetNameController.clear();
      state.quickSheetDescriptionController.clear();
      state.quickSheetCountController.text = '1';
      final source = monsterById('duellante_senza_palpebre')!;
      final legacySheet = {
        ...probe.snapshot(),
        'id': 'legacy-assassino-custom',
        'sheetTag': 'legacy-assassino-custom',
        'nome': 'Duellante personale salvato',
        'tipoScheda': 'Mostro Mini Boss',
        'monsterBookSourceId': source.id,
        'resilienza': '43',
        'masterSideOverride': 'neutral',
      };
      state.schedePersonaggio
        ..clear()
        ..add(legacySheet);
      state.schedaCorrente = 0;
      probe.load(legacySheet);
      final beforeCount = state.schedePersonaggio.length as int;
      final spawningDialog = probe.spawnBookCreature(source.id);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.textContaining('· +12 punti per Grado'), findsOneWidget);
      expect(find.textContaining('· +10 punti per Grado'), findsNothing);
      await tester.tap(find.widgetWithText(TextButton, 'Annulla'));
      await tester.pumpAndSettle();
      await spawningDialog;
      final naturalOnlySeed = List.generate(32, (index) => index).firstWhere(
        (seed) => oculumMonsterBookLoadout(
          source,
          level: 24,
          random: Random(seed),
        ).art!.skills.isEmpty,
      );
      debugPrint('Assassino natural-only regression seed: $naturalOnlySeed');
      await tester.runAsync(
        () => probe.generateBookCreatureFromSource(
          source,
          forcedType: 'Mostro Mini Boss',
          level: 24,
          stats: {'resilienza': 27, 'volonta': 21, 'materia': 24, 'oculum': 17},
          loadoutRandom: Random(naturalOnlySeed),
        ),
      );
      await tester.pump();
      final created = probe.snapshot();
      expect(state.schedePersonaggio.length, beforeCount + 1);
      expect(created['nome'], 'Assassino');
      expect(created['tipoScheda'], 'NPC');
      expect((created['oculusModData'] as Map)['entityKind'], 'npc');
      expect(created['masterSideOverride'], 'enemy');
      expect(created['monsterBookSourceId'], source.id);
      expect(created['resilienza'], '27');
      expect(created['volonta'], '21');
      expect(created['materia'], '24');
      expect(created['oculum'], '17');
      final actualSkills = List<CharacterSkill>.from(state.skills);
      final actualArtSkills = [
        for (final art in List<CharacterArt>.from(state.arti)) ...art.skills,
      ];
      final naturalPool = oculumMonsterBookSkills(source);
      final artPool = oculumMonsterBookImportArt(source)!;
      final actualRegular = [
        for (final skill in actualSkills)
          if (!skill.passiva) skill.nome,
        for (final skill in actualArtSkills)
          if (!skill.tipoPerLivello(1).toLowerCase().contains('passiv'))
            skill.nome,
      ];
      expect(actualRegular, hasLength(3));
      expect(actualRegular.toSet(), hasLength(3));
      for (final skill in actualSkills) {
        final expected = CharacterSkill.fromJson(
          naturalPool.singleWhere((s) => s.nome == skill.nome).toJson(),
        )..equipaggiata = false;
        expect(skill.toJson(), expected.toJson());
      }
      for (final skill in actualArtSkills) {
        expect(
          skill.toJson(),
          artPool.skills.singleWhere((s) => s.nome == skill.nome).toJson(),
        );
      }
      final actualArts = List<CharacterArt>.from(state.arti);
      expect(actualArts, hasLength(1));
      expect(actualArts.single.skills, isEmpty);
      expect(actualArts.single.openName, isNotEmpty);
      expect(
        oculumMonsterBookOpenPool(source).map((art) => art.openName),
        contains(actualArts.single.openName),
      );
      final generatedIndex = state.schedaCorrente as int;
      state.schedePersonaggio[generatedIndex]['inMasterParty'] = true;
      state.schedePersonaggio[generatedIndex]['countsForPartyStats'] = true;
      expect(probe.isEnemySheetAt(generatedIndex), isTrue);
      expect(probe.partyStatsCountIndexes(), isNot(contains(generatedIndex)));
      for (final side in ['ally', 'neutral']) {
        state.schedePersonaggio[generatedIndex]['masterSideOverride'] = side;
        expect(probe.isEnemySheetAt(generatedIndex), isFalse, reason: side);
        expect(probe.sheetSideAt(generatedIndex), side);
        expect(probe.partyStatsCountIndexes(), contains(generatedIndex));
      }
      state.schedePersonaggio[generatedIndex]['masterSideOverride'] = 'enemy';
      for (final key in [
        'nome',
        'tipoScheda',
        'monsterBookSourceId',
        'resilienza',
        'masterSideOverride',
      ]) {
        expect(
          state.schedePersonaggio.first[key],
          legacySheet[key],
          reason: key,
        );
      }
      state.schedaCorrente = 0;
      probe.load(legacySheet);
      expect(probe.isEnemySheetAt(0), isFalse);
      expect(probe.sheetSideAt(0), 'neutral');
      final restored = probe.snapshot();
      for (final key in [
        'nome',
        'tipoScheda',
        'monsterBookSourceId',
        'resilienza',
        'masterSideOverride',
      ]) {
        expect(restored[key], legacySheet[key], reason: key);
      }
      expect(tester.takeException(), isNull);
      await closeFixture(tester, probe);
    },
  );
}
