import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  const wolfId = 'lupo_delle_nevi';

  testWidgets(
    'Artwork unlocks for a participating owned sheet in the background',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final participating = probe.ownerTag();
      state.schedePersonaggio.add(
        probe.snapshot()
          ..remove('id')
          ..remove('sheetTag'),
      );
      state.schedaCorrente = 1;
      state.modalitaMaster = false;
      probe.ensureSheetTags();
      expect(probe.ownerTag(), isNot(participating));
      final campaign = probe.permissionCampaignId;
      Map<String, dynamic> fight(
        String id,
        String owner,
        String monster, {
        bool started = true,
        bool private = false,
      }) => {
        'encounterId': id,
        'fightStarted': started,
        if (private) 'masterOnlyDraft': true,
        'tokens': [
          {'id': owner, 'sheetTag': owner, 'side': 'ally'},
          {'id': 'token-$monster', 'monsterBookId': monster, 'side': 'enemy'},
        ],
      };
      const encountered = 'mammuth_in_decomposizione';
      Map<String, dynamic> packet({bool closed = false}) => {
        'senderRole': 'master',
        'campaignId': campaign,
        'closed': closed,
        'snapshot': {
          'encounters': [
            fight('participating-fight', participating, encountered),
            fight('other-fight', 'unowned', wolfId),
            fight(
              'private-fight',
              participating,
              'piranha_mortale',
              private: true,
            ),
            fight(
              'unstarted-fight',
              participating,
              'piovra_succhiasangue',
              started: false,
            ),
          ],
        },
      };
      probe.receiveInitiative(packet());
      expect(
        state.realtimeVisibleInitiativeSnapshot['encounterId'],
        isNot('participating-fight'),
      );
      final known = (state.monsterBookPartyDiscoveries as Map).values;
      expect(known, hasLength(1));
      expect(known.single, containsPair('monsterBookId', encountered));
      expect(known.single, containsPair('seen', true));
      expect(known.single, containsPair('nameKnown', false));
      expect(known.single, containsPair('weakPoint', false));
      probe.receiveInitiative(packet(closed: true));
      expect(known, hasLength(1));
      state.updateOculumHomeUi(() {
        state.datiCaricati = true;
        state.paginaCorrente = 18;
      });
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('enlarge-creature-$encountered')),
        findsOneWidget,
      );
      expect(
        find.text(monsterBookEntryById(encountered)!.nameIt),
        findsNothing,
      );
      await closeFixture(tester, probe);
    },
  );

  testWidgets('A player sees creature artwork as the shared Fight starts', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    const id = 'mammuth_in_decomposizione';
    probe.ensureSheetTags();
    final owner = probe.ownerTag();
    final campaign = probe.permissionCampaignId;
    state.updateOculumHomeUi(() {
      state.datiCaricati = true;
      state.modalitaMaster = false;
      state.paginaCorrente = 18;
    });
    await tester.pumpAndSettle();
    final preview = find.byKey(const ValueKey('enlarge-creature-$id'));
    expect(preview, findsNothing);

    Map<String, dynamic> snapshot({required bool started}) => {
      'senderRole': 'master',
      'campaignId': campaign,
      'snapshot': {
        'encounterId': 'player-artwork-encounter',
        'fightStarted': started,
        'tokens': [
          {'id': owner, 'sheetTag': owner, 'name': 'Party', 'side': 'ally'},
          {'id': 'unidentified-creature', 'monsterBookId': id, 'side': 'enemy'},
        ],
      },
    };
    probe.receiveInitiative(snapshot(started: false));
    await tester.pump();
    expect(preview, findsNothing);
    probe.receiveInitiative(snapshot(started: true));
    expect(state.realtimeVisibleInitiativeSnapshot['fightStarted'], isTrue);
    expect(
      (state.monsterBookPartyDiscoveries as Map).values,
      contains(
        allOf(
          containsPair('monsterBookId', id),
          containsPair('seen', true),
          containsPair('nameKnown', false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(preview, findsOneWidget);
    await tester.tap(preview);
    await tester.pumpAndSettle();
    final viewer = find.byKey(const ValueKey('enlarged-creature-artwork'));
    expect(viewer, findsOneWidget);
    expect(
      find.descendant(
        of: viewer,
        matching: find.text('Creatura non identificata'),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: viewer, matching: find.text('Chiudi')),
    );
    await tester.pumpAndSettle();
    await closeFixture(tester, probe);
  });

  testWidgets(
    'character loading and undo cannot restore another Monster Book',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      addTearDown(resetMonsterBookEntries);
      final wolf = defaultMonsterBookEntries.firstWhere((e) => e.id == wolfId);
      final primary = wolf.copyWith(nameIt: 'Lupo della campagna');
      final foreign = wolf.copyWith(nameIt: 'Lupo importato');
      final sheet = probe.snapshot()..['nome'] = 'Personaggio';
      probe.loadCampaign({
        'id': 'campaign_primary',
        'schedePersonaggio': [sheet],
        'monsterBookCustomEntries': [primary.toJson()],
      });
      final imported = {
        ...sheet,
        'nome': 'Importato',
        'monsterBookCustomEntries': [foreign.toJson()],
        'monsterBookRemovedIds': [wolfId],
        'realtimeSharedSheet': true,
      };
      state.schedePersonaggio[0] = imported;
      probe.load(imported);
      expect(probe.snapshot()['nome'], 'Importato');
      expect(probe.snapshot().containsKey('monsterBookCustomEntries'), isFalse);
      expect(probe.lookup(wolfId)?.nameIt, primary.nameIt);

      final undo = state.undoHistory as List;
      undo.clear();
      undo.add({
        'index': 0,
        'sheet': {...imported, 'nome': 'Prima della modifica'},
      });
      // Set the active sheet to the current snapshot to avoid creating a new
      // undo entry while `undo` first flushes the current sheet.
      state.schedePersonaggio[0] = probe.snapshot();
      probe.undo();
      expect(probe.snapshot()['nome'], 'Prima della modifica');
      expect(probe.lookup(wolfId)?.nameIt, primary.nameIt);
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'Monster Book round trips by campaign and migrates local legacy',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      addTearDown(resetMonsterBookEntries);
      final wolf = defaultMonsterBookEntries.firstWhere((e) => e.id == wolfId);
      final legacy = wolf.copyWith(nameIt: 'Lupo del vecchio salvataggio');
      final foreign = wolf.copyWith(nameIt: 'Lupo di un altro proprietario');
      final another = defaultMonsterBookEntries.firstWhere(
        (e) => e.id != wolf.id,
      );
      final sheet = probe.snapshot();
      probe.loadCampaign({
        'id': 'legacy_campaign',
        'schedaCorrente': 0,
        'schedePersonaggio': [
          {
            ...sheet,
            'realtimeSharedSheet': true,
            'monsterBookCustomEntries': [foreign.toJson()],
          },
          {
            ...sheet,
            'monsterBookCustomEntries': [legacy.toJson()],
            'monsterBookRemovedIds': [another.id],
          },
        ],
      });
      expect(probe.lookup(wolf.id)?.nameIt, legacy.nameIt);
      expect(probe.lookup(another.id), isNull);
      final saved = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(probe.campaignSnapshot())) as Map,
      );
      expect(saved['monsterBookRemovedIds'], [another.id]);

      // An authoritative empty campaign reflects an explicit reset even if
      // its archived character JSON still contains old duplicated data.
      probe.loadCampaign({
        ...saved,
        'id': 'other_campaign',
        'monsterBookCustomEntries': [],
        'monsterBookRemovedIds': [],
      });
      expect(probe.lookup(wolf.id)?.nameIt, wolf.nameIt);
      expect(probe.lookup(another.id)?.id, another.id);
      probe.loadCampaign(saved);
      expect(probe.lookup(wolf.id)?.nameIt, legacy.nameIt);
      expect(probe.lookup(another.id), isNull);
      await closeFixture(tester, probe);
    },
  );
}
