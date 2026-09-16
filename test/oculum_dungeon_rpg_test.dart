import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/pages/oculum_dungeon_game.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  testWidgets(
    'dungeon choices gate progression and playable monsters are isolated copies',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: OculumDungeonGameDialog(
            key: key,
            linguaInglese: false,
            primaryColor: Colors.blue,
            secondaryColor: Colors.black,
            tertiaryColor: Colors.amber,
            playerName: 'Test',
            playerMaxHp: 100,
            playerVc: 5,
            playerCm: 5,
            playerDefense: 0,
            playerDamage: 0,
            playerInitiative: 0,
            playerLevel: 0,
            playerGrade: 0,
            onReward: ({int obser = 0, int ascensionDust = 0, String? log}) {},
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final dynamic state = key.currentState!;
      state.runActive = true;
      state.room = 3;
      final hpBefore = state.playerMaxHp;
      state.exploreRoom();
      expect(state.room, 3);
      expect(state.runEvolution.offers.length, 3);
      final offers = List<String>.from(state.runEvolution.offers);
      state.exploreRoom();
      expect(state.runEvolution.offers, offers);
      state.runEvolution.offers
        ..clear()
        ..add('vital');
      state.chooseRunEvolution('vital');
      expect(state.playerMaxHp, hpBefore + 20);
      state.chooseRunEvolution('vital');
      expect(state.playerMaxHp, hpBefore + 20);
      final saved = state.buildRunCheckpointData();
      expect(saved['runEvolution']['history'], ['vital']);
      for (final monster in monsterBookEntries) {
        state.activeCharacterOrigin = null;
        state.playerMaxHp = 100;
        state.playerHp = 100;
        state.chooseDungeonMonster(monster);
        expect(state.activeCharacterOrigin.id, 'monster:${monster.id}');
        expect(state.activeCharacterOrigin.hpBonus, inInclusiveRange(3, 54));
        expect(
          state.activeCharacterOrigin.damageBonus,
          inInclusiveRange(1, 18),
        );
        expect(identical(state.dungeonMonster, monster), false);
      }
      state.activeCharacterOrigin = null;
      final snorlo = monsterBookEntries.firstWhere((m) => m.id == 'snorlo');
      state.chooseDungeonMonster(snorlo);
      expect(state.activeCharacterOrigin.id, 'monster:snorlo');
      expect(state.activeCharacterOrigin.hpBonus, 15);
      expect(identical(state.dungeonMonster, snorlo), false);
      expect(state.buildRunCheckpointData()['dungeonMonster']['id'], 'snorlo');
      state.completeCombatVictory();
      expect(state.unlockedTitleIds, contains('rpg_other_skin'));
      state.startRun();
      expect(state.runEvolution.history, isEmpty);
      expect(state.dungeonMonster, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
