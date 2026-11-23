import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets(
    'an Eye inherits its source creature artwork rather than its owner theme',
    (tester) async {
      final (state, probe) = await fixtures.mountFight(tester);
      final previous = oculumThemePresentation.value;
      final selections = oculumSheetRelicSelections.value;
      final automatic = oculumSheetMonsterThemes.value;
      addTearDown(() {
        oculumThemePresentation.value = previous;
        oculumSheetRelicSelections.value = selections;
        oculumSheetMonsterThemes.value = automatic;
      });
      oculumThemePresentation.value = previous.copyWith(
        artPackId: 'classic_rpg',
      );
      final source = probe.snapshot()
        ..['monsterBookSourceId'] = 'granscostumato'
        ..['relicArtPackId'] = 'monster/granscostumato/rame'
        ..['monsterAppearance'] = {
          'themeId': 'monster/granscostumato/rame',
          'color': 'Rame ossidato',
          'version': 1,
        };
      final body = probe.fallenEyeBodyFromSource(source);
      expect(body['relicArtPackId'], source['relicArtPackId']);
      expect(body['monsterAppearance'], source['monsterAppearance']);
      (body['monsterAppearance'] as Map)['customMarker'] = 'Eye only';
      expect((source['monsterAppearance'] as Map)['customMarker'], isNull);
      body['sheetTag'] = body['id'] = 'qa-source-eye';
      final restored = jsonDecode(jsonEncode(body)) as Map<String, dynamic>;
      probe.restoreCreatureAppearance(restored);
      expect(
        oculumThemePresentationForSheet('qa-source-eye').artPackId,
        'monster/granscostumato/rame',
      );
      final theme = oculumMonsterThemeById(
        oculumThemePresentationForSheet('qa-source-eye').artPackId,
      )!;
      expect(theme.monster.id, 'granscostumato');
      expect(
        theme.illustration,
        contains('theme_granscostumato_canon_20261118_v3'),
      );
      await closeFixture(tester, probe);
    },
  );

  testWidgets('creature selectors display the approved creature image', (
    tester,
  ) async {
    final (state, probe) = await fixtures.mountFight(tester);
    final entry = monsterBookEntryById(
      'mammuth_in_decomposizione_variante_rituale',
    )!;
    final widget = probe.creatureSelectionPreview(entry);
    probe.cancelPendingSave();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
    final preview = find.byKey(ValueKey('creature-recognition-${entry.id}'));
    expect(preview, findsOneWidget);
    final image = tester.widget<Image>(preview);
    expect((image.image as ResizeImage).imageProvider, isA<AssetImage>());
    expect(
      ((image.image as ResizeImage).imageProvider as AssetImage).assetName,
      oculumCreatureRecognitionTheme(entry).illustration,
    );
    expect(find.text('Forma base'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
