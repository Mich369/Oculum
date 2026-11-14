import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets(
    'the Master manages teams from the Fight on the character sheet',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      state.updateOculumHomeUi(() {
        state.paginaCorrente = 0;
        state.activeGameMod = '';
        state.temiOldSchool = false;
        state.nuovoDesignOculum = 'cattedrale';
        state.referenceSheetSection = 'general';
        state.datiCaricati = true;
      });
      await tester.pump();

      Finder keyed(String key) => find.byKey(ValueKey(key));
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target.first);
        await tester.tap(target.hitTestable().first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
      }

      Map token(String id) => (probe.combatTurnEncounter()['tokens'] as List)
          .whereType<Map>()
          .singleWhere((token) => token['id'] == id);

      final fightMenu = keyed('reference_fight_teams');
      await tap(fightMenu);
      await tap(keyed('reference_fight_team_add'));
      await tester.enterText(keyed('reference_fight_team_name'), 'Fendenti');
      await tester.enterText(keyed('reference_fight_team_hex_0'), '#4E74BD');
      await tester.pump();
      await tap(find.widgetWithText(FilledButton, 'Salva'));

      await tap(keyed('reference_fight_team_participant_ENEMY'));
      await tap(find.widgetWithText(SimpleDialogOption, 'Fendenti'));

      final foe = token('ENEMY');
      final teamId = foe['fightTeamId'];
      expect(teamId, startsWith('team:'));
      expect(foe['teamName'], 'Fendenti');
      expect(foe['fightTeamColorArgb'], 0xFF4E74BD);
      expect(foe['side'], 'enemy');
      expect(token('OTHER')['fightTeamId'], isNull);

      await tap(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.widgetWithText(ListTile, 'Fendenti'),
            )
            .first,
      );
      await tester.enterText(keyed('reference_fight_team_hex_0'), '#B542C0');
      await tester.pump();
      await tap(find.widgetWithText(FilledButton, 'Salva'));
      expect(token('ENEMY')['fightTeamId'], teamId);
      expect(token('ENEMY')['fightTeamColorArgb'], 0xFFB542C0);
      expect(token('ENEMY')['side'], 'enemy');

      await tap(find.widgetWithText(TextButton, 'Chiudi'));
      state.updateOculumHomeUi(() => state.modalitaMaster = false);
      await tester.pump();
      expect(fightMenu, findsNothing);
      await closeFixture(tester, probe);
    },
  );
}
