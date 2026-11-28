import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon_game.dart';
import 'package:oculum/widgets/oculum_custom_theme.dart';
import 'package:oculum/widgets/oculum_theme_asset_packs.dart';
import 'package:oculum/widgets/oculum_theme_availability.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:oculum/widgets/oculum_theme_relic.dart';

import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (presetId, artPackId) in [
    ('whispering_reliquary', 'whispering_reliquary'),
    ('element_laser', 'element_pack_laser'),
  ]) {
    group(presetId, () => _verifyRetiredTheme(presetId, artPackId));
  }
}

void _verifyRetiredTheme(String presetId, String retiredTheme) {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final presentation = oculumThemePresentation.value;
    final selections = Map<String, String>.of(oculumSheetRelicSelections.value);
    final custom = Map<String, dynamic>.of(oculumCustomArtwork.value);
    addTearDown(() {
      oculumThemePresentation.value = presentation;
      oculumSheetRelicSelections.value = selections;
      oculumCustomArtwork.value = custom;
    });
    oculumThemePresentation.value = const OculumThemePresentation();
    oculumSheetRelicSelections.value = {};
    oculumCustomArtwork.value = {};
  });

  test('retired artwork remains resolvable but cannot be newly selected', () {
    expect(oculumIsThemeSelectable(retiredTheme), isFalse);
    expect(oculumIsThemeSelectable(presetId), isFalse);
    expect(oculumIsThemeSelectable('  $retiredTheme  '), isFalse);
    expect(oculumIsThemeSelectable(retiredTheme.toUpperCase()), isFalse);
    expect(oculumIsThemeSelectable(''), isTrue);
    expect(oculumIsThemeSelectable('abyssal_tide'), isTrue);
    expect(oculumIsThemeSelectable('custom'), isTrue);
    expect(oculumThemeAssetPacks[retiredTheme], isNotNull);
    expect(
      oculumThemeAssetPacks[retiredTheme]!.storyScene,
      contains(retiredTheme),
    );
    expect(
      oculumCanSelectRelic(
        retiredTheme,
        sheetId: 'legacy-sheet',
        master: true,
        assigned: {retiredTheme},
      ),
      isFalse,
    );
    expect(oculumCanSelectRelic('', sheetId: 'legacy-sheet'), isTrue);
  });

  test(
    'loading a legacy pack preserves saved IDs and unrelated custom JSON',
    () async {
      final customSheet = jsonEncode({
        'id': 'legacy-sheet',
        'colorPreset': retiredTheme,
        'colorDecorationPresetId': retiredTheme,
        'colorGuiPresetId': retiredTheme,
        'relicArtPackId': retiredTheme,
        'customImageBase64': 'preserved-custom-image',
        'primaryColor': 0xffc4ad87,
      });
      final relics = jsonEncode({'legacy-sheet': retiredTheme});
      SharedPreferences.setMockInitialValues({
        'oculum.themeArtPack': retiredTheme,
        'oculum.sheetRelicSelections': relics,
        'saved-sheet-sentinel': customSheet,
      });
      await loadOculumThemePresentation();
      expect(oculumThemePresentation.value.artPackId, retiredTheme);
      expect(
        oculumThemePresentationForSheet('legacy-sheet').artPackId,
        retiredTheme,
      );
      await setOculumThemePresentation(
        oculumThemePresentation.value.copyWith(
          motion: OculumThemeMotion.disabled,
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('oculum.themeArtPack'), retiredTheme);
      expect(prefs.getString('oculum.sheetRelicSelections'), relics);
      expect(prefs.getString('saved-sheet-sentinel'), customSheet);
    },
  );

  test(
    'new relic assignments are refused without changing existing preferences',
    () async {
      final relics = jsonEncode({
        'legacy-sheet': retiredTheme,
        'other': 'abyssal_tide',
      });
      SharedPreferences.setMockInitialValues({
        'oculum.themeArtPack': 'abyssal_tide',
        'oculum.sheetRelicSelections': relics,
      });
      await loadOculumThemePresentation();
      await setOculumSheetRelic('new-sheet', retiredTheme);
      await setOculumSheetRelic('other', retiredTheme);
      await setOculumThemePresentation(
        oculumThemePresentation.value.copyWith(artPackId: retiredTheme),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        oculumSheetRelicSelections.value.containsKey('new-sheet'),
        isFalse,
      );
      expect(oculumSheetRelicSelections.value['other'], 'abyssal_tide');
      expect(oculumSheetRelicSelections.value['legacy-sheet'], retiredTheme);
      expect(oculumThemePresentation.value.artPackId, 'abyssal_tide');
      expect(prefs.getString('oculum.themeArtPack'), 'abyssal_tide');
      expect(prefs.getString('oculum.sheetRelicSelections'), relics);
    },
  );

  testWidgets(
    'legacy active pack is absent from dropdown without an assertion',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'oculum.themeArtPack': retiredTheme,
      });
      await loadOculumThemePresentation();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OculumThemePresentationControls(),
            ),
          ),
        ),
      );
      final field = find.byKey(ValueKey('theme-art-pack-$retiredTheme'));
      final dropdown = tester.widget<DropdownButton<String>>(
        find.descendant(
          of: field,
          matching: find.byWidgetPredicate(
            (widget) => widget is DropdownButton<String>,
          ),
        ),
      );
      expect(
        dropdown.items!.any((item) => item.value == retiredTheme),
        isFalse,
      );
      expect(dropdown.value, isNull);
      expect(tester.takeException(), isNull);
      expect(oculumThemePresentation.value.artPackId, retiredTheme);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('oculum.themeArtPack'), retiredTheme);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Master cannot reapply retired theme and legacy sheet IDs survive load',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.updateOculumHomeUi(() {
        state.modalitaMaster = true;
      });
      final legacy = probe.snapshot()
        ..['colorPreset'] = presetId
        ..['colorDecorationPresetId'] = presetId
        ..['colorGuiPresetId'] = presetId;
      probe.load(legacy);
      await tester.pump();
      final loaded = probe.snapshot();
      expect(loaded['colorPreset'], presetId);
      expect(loaded['colorDecorationPresetId'], presetId);
      expect(loaded['colorGuiPresetId'], presetId);
      expect(probe.themes.any((preset) => preset.id == presetId), isFalse);
      final dialog = showDialog<void>(
        context: tester.element(find.byType(OculumHomePage)),
        builder: (_) => AlertDialog(
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(child: probe.colorThemePicker()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      final colorDropdown = tester.widget<DropdownButton<String>>(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byWidgetPredicate(
            (widget) => widget is DropdownButton<String>,
          ),
        ),
      );
      expect(colorDropdown.value, isNull);
      expect(
        colorDropdown.items!.any((item) => item.value == presetId),
        isFalse,
      );
      Navigator.of(tester.element(find.byType(AlertDialog))).pop();
      await dialog;
      await tester.pump();
      probe.applyTheme('classic_rpg');
      final before = probe.snapshot();
      probe.applyTheme(presetId);
      final after = probe.snapshot();
      for (final key in [
        'colorPreset',
        'colorDecorationPresetId',
        'colorGuiPresetId',
        'primaryColor',
        'secondaryColor',
        'tertiaryColor',
      ]) {
        expect(after[key], before[key], reason: key);
      }
      expect((state.masterAssignedThemeIds as Set).contains(presetId), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'Dungeon excludes retired injected rewards and does not charge for them',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'oculumDungeon.unlockedThemePresetIds': [presetId],
      });
      final granted = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: OculumDungeonGameDialog(
            linguaInglese: false,
            primaryColor: Colors.white,
            secondaryColor: Colors.black,
            tertiaryColor: Colors.purple,
            playerName: 'Fixture',
            playerMaxHp: 100,
            playerVc: 10,
            playerCm: 10,
            playerDefense: 10,
            playerDamage: 10,
            playerInitiative: 10,
            playerLevel: 0,
            playerGrade: 0,
            onReward: ({int obser = 0, int ascensionDust = 0, String? log}) {},
            onThemeUnlocked: granted.add,
            availableThemeUnlocks: [
              {
                'id': presetId,
                'nameIt': oculumThemeAssetPacks[retiredTheme]!.name,
              },
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final dynamic state = tester.state(find.byType(OculumDungeonGameDialog));
      final themes = (state.allDungeonThemeUnlocks() as List).cast<dynamic>();
      expect(themes.any((theme) => theme.id == presetId), isFalse);
      (state.unlockedThemePresetIds as Set).addAll(
        themes.map<String>((theme) => theme.id as String),
      );
      state.oculumSpento = 6;
      state.unlockRandomThemeWithSpent();
      expect(state.oculumSpento, 6);
      expect((state.unlockedThemePresetIds as Set).contains(presetId), isTrue);
      expect(granted, isNot(contains(presetId)));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
