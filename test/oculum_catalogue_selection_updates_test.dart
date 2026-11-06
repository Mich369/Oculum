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
