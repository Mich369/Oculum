import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart' show combatParticipantTeamId;
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test('the four peaceful Orea profiles generate on the neutral side', () {
    for (final id in const [
      'orea_floscocorno',
      'orea_fioripasso',
      'orea_velocilento',
      'orea_gambio',
    ]) {
      final entry = monsterBookEntryById(id)!;
      expect(entry.planeIds, contains('orea_zalira'));
      expect(entry.generationSide, 'neutral', reason: id);
      expect(entry.isNpc, isFalse, reason: id);
    }
    expect(
      monsterBookEntryById('pianta_divoratrice_vetro')!.generationSide,
      'enemy',
    );
  });

  testWidgets('Master can add a neutral Orea sheet to the enemy team', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final source = monsterBookEntryById('orea_fioripasso')!;
    state.quickSheetNameController.text = '';
    state.quickSheetCountController.text = '1';
    final index = state.schedePersonaggio.length as int;
    await probe.generateBookCreatureFromSource(
      source,
      forcedType: source.presetType,
      level: source.stats['level']!,
    );
    expect(state.schedePersonaggio, hasLength(index + 1));
    final generated = state.schedePersonaggio[index] as Map;
    final tag = generated['sheetTag'] as String;
    expect(generated['monsterBookSourceId'], source.id);
    expect(probe.sheetSideAt(index), 'neutral');

    final dialog = probe.showFightCreator();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final row = find.byKey(ValueKey('fight-creator-sheet-$tag'));
    await tester.ensureVisible(row);
    if (tester.widget<CheckboxListTile>(row).value != true) {
      await tester.tap(row);
      await tester.pump();
    }
    final team = find.byKey(ValueKey('creator-team-$tag'));
    await tester.ensureVisible(team);
    expect(tester.state<FormFieldState<String>>(team).value, 'neutral');
    await tester.tap(team);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Nemici').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.state<FormFieldState<String>>(team).value, 'enemy');

    await tester.tap(find.byKey(const ValueKey('fight-creator-prepare')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await dialog;
    final token = (state.masterInitiativeTokens as List)
        .cast<Map>()
        .singleWhere((token) => token['sheetTag'] == tag);
    expect(token['fightTeamId'], 'enemy');
    expect(combatParticipantTeamId(token), 'enemy');
    expect(probe.sheetSideAt(index), 'neutral');
    expect(source.generationSide, 'neutral');
    await closeFixture(tester, probe);
  });
}
