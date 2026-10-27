import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/game/oculum_combat_scout_rules.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:oculum/widgets/oculum_narrative_background.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:oculum/widgets/oculum_theme_asset_packs.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
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
      expect(oculumScoutPower(3, [5, 2, 1, 0]), 11);
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
        expect(m.skillIds.length, 14); // Two authored + twelve growth techniques.
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
