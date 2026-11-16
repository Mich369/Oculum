import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  const wolfId = 'lupo_delle_nevi';

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
