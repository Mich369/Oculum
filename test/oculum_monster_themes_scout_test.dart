import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/game/oculum_combat_scout_rules.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:oculum/widgets/oculum_narrative_background.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:oculum/widgets/oculum_theme_asset_packs.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  testWidgets('Both large lots bundle the twelve exact selected WebPs', (
    tester,
  ) async {
    const expected = {
      'marionettista_boss':
          '59b9407f92f64c75a2f03b9e4bcd48eb5adcf71c4e347e2cac6288447e14b8dc',
      'mammuth_in_decomposizione':
          '05ff8c991c6fe2e488e15193e1d4167ed0da4ef5869edf9e8e0c2d14d2a24c36',
      'scheletro_bombarolo':
          '176a534f09f90cc8e15e5e7505151d47b6d70717b7925d70d8daaa6c2700a591',
      'armaiolo_della_fila_lunga_variante_rituale':
          'e576f17257a955cb850e738e543c0ba87b726757eac82eda220ff8b612ee3619',
      'lupo_infernale_del_ghiaccio':
          '506cd23d6479a7a52628bbe05ff6faeff38fc822aab443bb30abd809fd63da56',
      'aberrazione_oro_marmo_superiore_angelica':
          'f13fa2696997eefa705bdb0892a350a4c6a69a4697b86acd603ba929e00cf3cc',
      'pawn_guardiano':
          '29fd72341ec787ca60217e416d97a9807336b957533d338197097d37e6f9be37',
      'pinepine':
          'b12c7b3f23713366f290c68e5b24f9060f4076a8c6a5668997fff79e53c98a92',
      'bambola_vapium_variante_veterana':
          'cdce4b9d8f5563a67179166275a4203fe4c1779c64162b599d9886952e493db7',
      'demone_glaciale_minore':
          'a2e323e0e063fd07f82eaca443bbc108453368db8de3d656d9a1f3f825c79e8b',
      'larva_del_vespro_variante_errante':
          '7dc284c14022b0fa516c0be863e4455934c494058456bda38d668acc812e377a',
      'snorlo':
          '140bbb9539b8859c48b90930877872b10815198c98e1fdb07aa524907fc8a078',
    };
    for (final entry in expected.entries) {
      final id = entry.key;
      final monster = monsterBookEntryById(id)!;
      final theme = OculumMonsterTheme(
        monster,
        oculumMonsterColors(monster).first,
      );
      final asset =
          'assets/oculum/home_art_authored/theme_${id}_canon_20261115.webp';
      expect(theme.illustration, asset, reason: id);
      expect(theme.preserveIllustrationFraming, isTrue, reason: id);
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final sha256 = SHA256Digest()
          .process(bytes)
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      expect(sha256, entry.value, reason: id);
    }

    for (final (id, stem) in [
      ('mammuth_in_decomposizione', 'mammuth_decomposizione'),
      ('pawn_guardiano', 'pawn'),
      ('pinepine', 'pinepine'),
    ]) {
      final monster = monsterBookEntryById(id)!;
      final theme = OculumMonsterTheme(
        monster,
        oculumMonsterColors(monster).first,
      );
      expect(
        theme.illustrationMobile,
        'assets/oculum/home_art_webp/theme_${stem}_mobile_v1.webp',
      );
      expect(
        theme.relicIllustration,
        'assets/oculum/home_art_webp/relic_${stem}_v1.webp',
      );
      expect(theme.preserveMobileIllustrationFraming, isFalse);
    }
    final aurybone = monsterBookEntryById(
      'aberrazione_oro_marmo_superiore_angelica',
    )!;
    final solar = OculumMonsterTheme.desktopIllustrationForId(
      'aberrazione_oro_marmo_superiore_solare',
    );
    expect(solar, endsWith('_canon_20261109_votes7.png'));
    expect(
      oculumMonsterPrecisionAnatomy(
        aurybone,
      ).where((part) => part['group'] == 'wings').map((part) => part['side']),
      unorderedEquals(['left', 'right']),
    );
  });

  testWidgets('November 15 approved backgrounds load by exact monster ID', (
    tester,
  ) async {
    for (final id in [
      'aberrazione_oro_marmo_intermedia_angelica',
      'aberrazione_oro_marmo_intermedia_solare',
      'acuagoblin_variante_curioso',
      'acuagoblin_variante_predatore',
      'acuagoblin_variante_territoriale',
      'agla_variante_corazzata',
      'air_navigator',
      'ammasso_carne_ossa_errante_variante_rituale',
      'ammasso_pustoloso',
      'angelo_fustigatore_variante_rituale',
      'arcangelo_variante_errante',
      'armadillo_cristallo',
      'armadillo_legno',
      'arpia_base_variante_veterana',
      'baby_forest_demon_variante_rituale',
      'baby_rock_rhino',
      oculumIntermediateRockRhynoId,
      'baby_rock_rhino_variante_veterana',
      'bandito_base_variante_veterana',
      'bunnys_variante_veterana',
      'corvo_della_morte_evoluto',
      'cuore_lava_variante_corazzata',
      'distruttor_caramella',
      'divoramitu',
      'divoramitu_elite',
      'golem_runico_variante_veterana',
      'guardia_solare',
      'guardia_solare_elite',
      'guardiano_solare',
      'habitat_demoniaco_regina_delle_gole_vulcaniche',
      'habitat_foresta_elementale_ragno_della_linfa_acida',
      'larva_lava_variante_corazzata',
      'lignobark',
      'meccanio_ammaccato_variante_errante',
      'oblyvuard',
      'ombra_ignota',
      'snorlo_variante_corazzata',
      'topo_mutante',
      'troll_base_variante_veterana',
    ]) {
      final monster = monsterBookEntryById(id)!;
      final theme = OculumMonsterTheme(
        monster,
        oculumMonsterColors(monster).first,
      );
      final asset =
          'assets/oculum/home_art_authored/theme_${id}_canon_20261115.webp';
      expect(theme.illustration, asset);
      expect(theme.preserveIllustrationFraming, isTrue);
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
    }
    expect(
      monsterBookEntryById('agla_variante_corazzata')!.nameIt,
      'Lorica Gleaner',
    );
    for (final (id, name, alias) in [
      ('ammasso_pustoloso', 'Ossyblayn', 'Caro Blisterhide'),
      ('angelo_fustigatore_variante_rituale', 'Miruslash', 'Flagellum Vow'),
      ('arcangelo_variante_errante', 'Vagarwyngh', 'Ordinwing Wingstray'),
      ('base_ghiaccio_05', 'Nyvowl', 'Gufo di Neve Blu'),
      ('troll_base_variante_veterana', 'Visbark', 'Troll Veterana'),
      ('idra_base', 'Tryjaw', 'Idra'),
      ('cuore_lava_variante_corazzata', 'Ignyshell', 'Cuore di Lava Corazzato'),
      (
        'meccanio_ammaccato_variante_errante',
        'Vaghyuil',
        'Meccanio Malconcio Errante',
      ),
      (
        'bandito_base_variante_veterana',
        'Bandita Veterana',
        'Bandito Veterana',
      ),
    ]) {
      final monster = monsterBookEntryById(id)!;
      expect(monster.nameIt, name);
      expect(oculumMonsterNameSearchAliases(monster), contains(alias));
    }
    expect(
      oculumMonsterNameSearchAliases(
        monsterBookEntryById('arcangelo_variante_errante')!,
      ),
      containsAll(['Vagawyng', 'Vagarwingh']),
    );
    for (final (id, approvedVariant) in [
      ('acuagoblin_variante_predatore', 'acuagoblin_variante_territoriale'),
      ('acuagoblin_variante_curioso', 'acuagoblin_variante_territoriale'),
      ('corvo_della_morte', 'corvo_della_morte_evoluto'),
      ('divoramitu_elite', 'divoramitu'),
      ('baby_rock_rhino_variante_veterana', 'baby_rock_rhino'),
      ('snorlo', 'snorlo_variante_corazzata'),
      ('troll_base', 'troll_base_variante_veterana'),
      ('meccanio_ammaccato', 'meccanio_ammaccato_variante_errante'),
      (
        'aberrazione_oro_marmo_intermedia_angelica',
        'aberrazione_oro_marmo_intermedia_solare',
      ),
    ]) {
      expect(
        OculumMonsterTheme.desktopIllustrationForId(id),
        isNot(OculumMonsterTheme.desktopIllustrationForId(approvedVariant)),
      );
    }
  });

  testWidgets('ink selections resolve to the exact approved artwork', (
    tester,
  ) async {
    const expected = {
      'affogato_faldavela':
          '6164f6cda3101d313159d5d118e3d8a8db44f5615cfaf6788aca5992c781d6af',
      'armadillo_sabbia':
          '034fe6c89b41718b3870978341d58b2df1693abf9ea32d5279c53dc3bc11799c',
      'balena_dai_mille_occhi':
          '44047a480291affb0ac198d086ea379a28b19bab48899767774b081ea27ec7ce',
      'base_ghiaccio_05':
          '8cbeca98b5e893a24788d5b009345f29dd8ba97b2721cfef3547ad35849a2200',
      'habitat_caramella_medusa_di_confettura':
          '2a4f69f0cf45ac6a149f56313d19af503a8b5634363e8d36716bb470cf692c91',
      'habitat_nuvole_rocciose_cinghiale_delle_creste_volanti_variante_errante':
          '5fed06388c0d4661c0529fe87b8a43d69ff23404585310a0209274238935109e',
      'habitat_nuvole_rocciose_golem_delle_ghiaie_orbitanti':
          '7db5fcfc67d04e1976adb542837911dcdb7106641b7b4193cdd62c60c79e9888',
      'hero_path_diverso_ascia_variante_corazzata':
          'b67f3e05b5533869ef192f34a80f20484891d157a18ad787cf45a035571fe720',
      'idra_base':
          '4ff7617c21317018a62bf2f0caee3d638170e0bc2c80054f1710e2ec27aab175',
      'piovra_succhiasangue':
          'd8ec42496f74445611fe3f4b92fc18438fab598aaeb3a53930e8882662b9ab74',
      'ragno_putrido':
          'b3931171653aa459875ae2d04435851baf500b6566fda8b5b2c660b87a58a1f1',
    };
    for (final MapEntry(key: id, value: digest) in expected.entries) {
      final monster = monsterBookEntryById(id)!;
      final theme = OculumMonsterTheme(
        monster,
        oculumMonsterColors(monster).first,
      );
      final suffix = switch (id) {
        'habitat_caramella_medusa_di_confettura' ||
        'hero_path_diverso_ascia_variante_corazzata' ||
        'ragno_putrido' => '20261116',
        _ => '20261116_riallineamento',
      };
      final asset =
          'assets/oculum/home_art_authored/theme_${id}_canon_$suffix.webp';
      expect(theme.illustration, asset, reason: id);
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final sha256 = SHA256Digest()
          .process(bytes)
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      expect(sha256, digest, reason: id);
    }
  });

  test(
    'newly illustrated variants keep their search and anatomy identities',
    () {
      for (final (id, name, aliases) in [
        (
          'aberrazione_oro_marmo_intermedia_solare',
          'Aurystride',
          ['Sunwalker', 'Auristride'],
        ),
        (
          'arpia_base_variante_veterana',
          'Ventyclaw',
          ['Arpia Veterana', 'Veteran Harpy', 'Venticlaw'],
        ),
        (
          'larva_lava_variante_corazzata',
          'Syntermoltys',
          ['Larva di Lava Corazzata', 'Armored Lava Larva', 'Syntermoltis'],
        ),
        (
          'golem_runico_variante_veterana',
          'Viscuprum',
          ['Golem Runico Veterano', 'Golem Runico Veterana', 'Vis Cuprum'],
        ),
        (
          'baby_rock_rhino_variante_veterana',
          'Visrhyno',
          ['Baby Rock Rhino Veterana', 'Veteran Baby Rock Rhino', 'Visrhino'],
        ),
        (
          oculumIntermediateRockRhynoId,
          'RockRhyno',
          ['Rock Rhino Intermedio', 'Intermediate Rock Rhino'],
        ),
      ]) {
        final entry = monsterBookEntryById(id)!;
        expect([entry.nameIt, entry.nameEn], [name, name]);
        expect(oculumMonsterNameSearchAliases(entry), containsAll(aliases));
        for (final alias in aliases) {
          expect(oculumLookupMonsterId(alias).exact?.id, id, reason: alias);
        }
      }

      final arpia = monsterBookEntryById('arpia_base_variante_veterana')!;
      final arpiaParts = oculumMonsterPrecisionAnatomy(arpia);
      final wings = arpiaParts.where((part) => part['group'] == 'wings');
      expect(
        wings.map((part) => part['id']),
        unorderedEquals(['wings_1', 'wings_2']),
      );
      expect(wings.every((part) => part['weak'] == true), isTrue);
      expect(arpiaParts.where((part) => part['group'] == 'arms'), hasLength(2));

      final larva = monsterBookEntryById('larva_lava_variante_corazzata')!;
      final larvaParts = oculumMonsterPrecisionAnatomy(larva);
      expect(
        larvaParts.singleWhere((part) => part['id'] == 'joint')['weak'],
        isTrue,
      );

      const golemId = 'golem_runico_variante_veterana';
      final golemParts = oculumMonsterPrecisionAnatomy(
        monsterBookEntryById(golemId)!,
      );
      List<Object?> targetsAfterPlateDamage(int damage) {
        final exposed = oculumRunicGolemPlatesBroken({
          'anatomicalParts': {
            'parts': {
              'chest_plates': {'maximumHp': 10, 'damageTaken': damage},
            },
          },
        });
        return oculumReferenceCreaturePrecisionParts(
          golemParts,
          monsterId: golemId,
          runicGolemCoreExposed: exposed,
        ).map((part) => part['id']).toList();
      }

      expect(targetsAfterPlateDamage(9), contains('chest_plates'));
      expect(targetsAfterPlateDamage(9), isNot(contains('core')));
      expect(targetsAfterPlateDamage(10), contains('core'));
    },
  );

  testWidgets(
    'Home second option follows the current theme and preserves the manual image choice',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      final p = OculumPerformanceProbe(state);
      final tag = tester
          .widget<OculumNarrativeBackground>(
            find.byType(OculumNarrativeBackground),
          )
          .sheetId;
      state.updateOculumHomeUi(() {
        state.paginaCorrente = 17;
        state.homeArtworkChoice = 'amber_shore';
        state.homeArtworkFollowsTheme = false;
      });
      oculumSheetRelicSelections.value = {tag: 'hidenas'};
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(p.homeHeroArtwork(), 'assets/oculum/home_art/amber_shore.png');
      await tester.tap(find.text('Usa il tema attuale'));
      await tester.pump();
      expect(
        p.homeHeroArtwork(),
        'assets/oculum/theme_stories/webp/hidenas.webp',
      );
      expect(p.snapshot()['homeArtworkFollowsTheme'], isTrue);
      expect(state.homeArtworkChoice, 'amber_shore');
      oculumSheetRelicSelections.value = {tag: 'dedicated_indigo'};
      await tester.pump();
      expect(
        p.homeHeroArtwork(),
        'assets/oculum/theme_stories/webp/dedicated_indigo.webp',
      );
      await tester.tap(find.text('Immagini Home'));
      await tester.pump();
      expect(p.homeHeroArtwork(), 'assets/oculum/home_art/amber_shore.png');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      oculumSheetRelicSelections.value = {};
    },
  );
  test(
    'power reading exposes only categories and failed reading only the dominant stat',
    () {
      expect(
        oculumScoutPower(3, [5, 2, 1, 0]),
        11,
      ); // Grade 0, HP multiplier 9 adds 0.
      expect(oculumScoutPower(4, [5, 2, 1, 0]), 13);
      expect(oculumScoutPowerBand(0, 0), 'equal');
      expect(oculumScoutPowerBand(0, 1), 'impossible');
      for (final (target, expected) in [
        (64, 'much_stronger'),
        (65, 'stronger'),
        (90, 'equal'),
        (110, 'equal'),
        (135, 'weaker'),
        (136, 'much_weaker'),
        (200, 'impossible'),
      ]) {
        expect(oculumScoutPowerBand(100, target), expected);
        expect(
          oculumPowerReadPhrases[expected],
          isNot(contains(RegExp(r'\d'))),
        );
      }
      for (final stat in ['resilienza', 'volonta', 'materia', 'oculum']) {
        expect(oculumScoutDominantStat({stat: 10}), stat);
        expect(
          oculumScoutFailurePhrase(stat),
          contains('non mi permette di percepire'),
        );
      }
      expect(oculumScoutUnlocksTheme(false, 0), isFalse);
      expect(oculumScoutUnlocksTheme(true, 89), isTrue);
      expect(oculumScoutUnlocksTheme(true, 90), isFalse);
    },
  );

  test(
    'every species and exact variant has a stable identity and valid weighted colours',
    () {
      final identifiers = <String>{};
      for (final monster in monsterBookEntries) {
        final colors = oculumMonsterColors(monster);
        expect(
          colors.fold<int>(0, (n, c) => n + c.weight),
          100,
          reason: monster.id,
        );
        for (final color in colors) {
          final theme = OculumMonsterTheme(monster, color);
          expect(identifiers.add(theme.id), isTrue, reason: theme.id);
          expect(oculumMonsterThemeById(theme.id)?.name, theme.name);
        }
        expect(
          oculumRollMonsterColor(monster, random: Random(42)).id,
          oculumRollMonsterColor(monster, random: Random(42)).id,
        );
      }
      for (final id in [
        'vendulo',
        'rascalume',
        'brumilio',
        'guravo',
        'mirula',
      ]) {
        final m = monsterById(id)!;
        expect(
          [
            'resilienza',
            'volonta',
            'materia',
            'oculum',
          ].fold<int>(0, (n, k) => n + (m.stats[k] ?? 0)),
          3,
        );
        expect(
          m.skillIds.length,
          14,
        ); // Two authored + twelve growth techniques.
        expect(m.dropIds, isNotEmpty);
        expect(m.planeIds.every(oculumMonsterHabitats.containsKey), isTrue);
      }
    },
  );

  testWidgets('full-page art leaves desktop and phone controls clickable', (
    tester,
  ) async {
    final previous = oculumSheetRelicSelections.value;
    addTearDown(() => oculumSheetRelicSelections.value = previous);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in [const Size(390, 844), const Size(1440, 900)]) {
      tester.view.physicalSize = size;
      var taps = 0;
      oculumSheetRelicSelections.value = {'preview': 'hidenas'};
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [
              OculumGothOrnaments(
                family: OculumGothFamily.forged,
                ink: Colors.white,
                accent: Colors.amber,
                opacity: .3,
                themeId: 'classic_reliquary',
              ),
            ],
          ),
          home: Scaffold(
            body: Stack(
              children: [
                const Positioned.fill(
                  child: OculumNarrativeBackground(sheetId: 'preview'),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Vita 100/100 · Oculum 10/10'),
                      FilledButton(
                        onPressed: () => taps++,
                        child: const Text('Attacco'),
                      ),
                      OutlinedButton(
                        onPressed: () => taps++,
                        child: const Text('Difesa'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      for (final id in oculumStoryThemePacks.keys) {
        oculumSheetRelicSelections.value = {'preview': id};
        await tester.pump();
        expect(
          find.byKey(ValueKey('narrative-background-$id')),
          findsOneWidget,
        );
        await tester.tap(find.text('Attacco'));
        await tester.tap(find.text('Difesa'));
      }
      expect(taps, oculumStoryThemePacks.length * 2);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'appearance survives JSON and exact-variant unlocks stay separate and per sheet',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      final p = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      final sheet = <String, dynamic>{
        'sheetTag': 'AppearanceOcu:3690AAAA',
        'monsterBookSourceId': 'nuvi',
      };
      p.restoreCreatureAppearance(sheet);
      final appearance = Map<String, dynamic>.from(sheet['monsterAppearance']);
      p.restoreCreatureAppearance(sheet);
      expect(sheet['monsterAppearance'], appearance);
      oculumSheetRelicSelections.value = {'AppearanceOcu:3690AAAA': 'hidenas'};
      expect(
        oculumThemePresentationForSheet('AppearanceOcu:3690AAAA').artPackId,
        'hidenas',
      );
      expect(
        oculumThemePresentationForSheet('another-sheet').artPackId,
        isNot('hidenas'),
      );
      p.unlockCreatureTheme('uomo_maschera', page: true);
      expect(p.creatureKnowledge('uomo_maschera')?['themeUnlocked'], isTrue);
      expect(
        p.creatureKnowledge('uomo_maschera_viola')?['themeUnlocked'],
        isNot(isTrue),
      );
      p.unlockCreatureTheme('uomo_maschera_viola', theme: true);
      p.unlockCreatureTheme('uomo_maschera_viola');
      expect(
        p.creatureKnowledge('uomo_maschera_viola')?['themeUnlocked'],
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      oculumSheetRelicSelections.value = {};
    },
  );
}
