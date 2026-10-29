import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;

Future<void> closeFixture(WidgetTester tester, OculumPerformanceProbe p) async {
  p.cancelPendingSave();
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 4));
}

void main() {
  for (final cost in [2, 6]) {
    testWidgets('Resilience $cost preserves current HP until the new maximum', (
      tester,
    ) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.resilienzaController.text = '20';
      state.currentResilienzaController.text = '20';
      state.gradoController.text = '0';
      state.livelloController.text = '3';
      state.currentHpController.text = '150';
      expect(p.hpMultiplier(), 10);
      expect(p.availableArtResource('resilienza'), 15);
      expect(p.spendArtResource('resilienza', cost), cost);
      expect(readIntValue(state.currentResilienzaController.text), 20 - cost);
      expect(p.currentHp(), cost == 2 ? 150 : 140);
      expect(p.coreStats()['resilienza'], 20 - cost);
      await closeFixture(tester, p);
    });
  }
  testWidgets(
    'Shadow Devil gratitude grants 3 to the killer and 1 to other participants once',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final owner = p.ownerTag();
      final before = state.fortuna as int;
      final enemy = {
        'id': 'shadow-one',
        'monsterSheetTag': 'shadow-one',
        'monsterBookId': 'shadow_devil',
        'killerTag': owner,
      };
      p.settleMonsterRewards(
        [enemy],
        'gratitude-fight',
        [owner, 'OTHER-PARTICIPANT'],
      );
      expect(state.fortuna, before + 3);
      final rewards = p.partyChestSnapshot()['questRewards'] as Map;
      expect(
        rewards.values
            .whereType<Map>()
            .where((r) => r['recipient'] == 'OTHER-PARTICIPANT')
            .single['bonus'],
        {'fortunaMagica': 1},
      );
      p.settleMonsterRewards(
        [enemy],
        'gratitude-fight',
        [owner, 'OTHER-PARTICIPANT'],
      );
      expect(state.fortuna, before + 3);
      final saved = p.snapshot();
      p.load(saved);
      p.settleMonsterRewards(
        [enemy],
        'gratitude-fight',
        [owner, 'OTHER-PARTICIPANT'],
      );
      expect(state.fortuna, before + 3);
      await closeFixture(tester, p);
    },
  );
  test('completed ordinary fights grant at least one Dust', () {
    expect(
      oculumEncounterResourcesForEnemies(
        [
          {'level': 1, 'grade': 0, 'statsTotal': 1},
        ],
        characterGrade: 4,
        characterStats: 100,
      ).dust,
      1,
    );
    expect(
      oculumEncounterResourcesForEnemies(
        [],
        characterGrade: 4,
        characterStats: 100,
      ).dust,
      0,
    );
  });
  test('reference creatures keep confirmed identity and editable forms', () {
    final sand = monsterBookEntryById('mostro_sabbia')!;
    expect(sand.isMiniBoss, isTrue);
    final demon = monsterBookEntryById('mezzo_demone_cosciente')!;
    expect(demon.weakPointDescriptionIt, contains('bocca dello stomaco'));
    expect(demon.encounterRules['conscious'], isTrue);
    final shadow = monsterBookEntryById('shadow_devil')!;
    expect(shadow.planeIds, contains('shadow_hell'));
    expect(shadow.encounterRules['magicalLuckOnDefeat'], {
      'killer': 3,
      'others': 1,
    });
    for (final monster in [sand, demon, shadow]) {
      expect(monster.spriteAssetPath, isEmpty);
      final art = oculumMonsterBookArt(monster);
      // Sand now has separate attack/parry techniques sharing one tail charge.
      expect(art.skills, hasLength(monster.id == 'mostro_sabbia' ? 16 : 14));
      expect(oculumMonsterEquipmentCatalogue(source: monster), isNotEmpty);
      for (final skill in art.skills) {
        expect(
          skill.effettiPerLivello
              .take(3)
              .every((effects) => effects.isNotEmpty),
          isTrue,
        );
      }
    }
    for (final angel in defaultMonsterBookEntries.where(
      (m) =>
          m.id.startsWith('aberrazione_oro_marmo_') &&
          m.id.endsWith('_angelica'),
    )) {
      expect(angel.descIt, contains('ordini del proprio angelo'));
      expect(angel.encounterRules['followsOwnAngelOrders'], isTrue);
    }
  });
}
