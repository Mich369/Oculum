import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/pages/oculum_dungeon_game.dart';

void main() {
  testWidgets(
    'Postea shop stats, set bonuses and shield do not stack on swapping',
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
      state.obserInRun = 500;
      final int damageBefore = state.totalDamage;
      final int defenseBefore = state.totalDefense;
      state.merchantEvent();
      final choices = (state.eventChoices as List).toList();
      final rifleChoice = choices.firstWhere(
        (dynamic choice) => (choice.labelIt as String).contains('112 Obser'),
      );
      rifleChoice.onPressed();
      expect(state.totalDamage, damageBefore + 15);
      state.merchantActionUsedThisRoom = false;
      state.buyPosteaArmorFromMerchant(96);
      expect(state.obserInRun, 292);
      expect(state.totalDamage, damageBefore + 40);
      expect(state.totalDefense, defenseBefore + 15);
      expect(state.playerShield, 25);
      final armor = state.activeCostume;
      final rifle = state.starterWeapon;
      state.consumePosteaEquipmentShield(7);
      state.playerShield -= 7;
      state.activeCostume = null;
      state.grantPosteaEquipmentShield();
      expect(state.playerShield, 0);
      expect(state.totalDamage, damageBefore + 15);
      state.equipRunCostume(armor);
      expect(state.playerShield, 18);
      state.equipRunWeapon(rifle);
      expect(state.playerShield, 18);
      expect(state.posteaLowFlight, true);
      state.activeCostume = null;
      expect(state.posteaLowFlight, false);
      state.equipRunCostume(armor);
    state.inCombat = true;
    state.enemyTurnPending = false;
    state.spawnEnemy();
    final dynamic target = state.firstAliveEnemy();
    target.hp = 1000;
    target.shield = 12;
    state.posteaArmedChain();
    final match = RegExp(r'1d6 = (\d)').firstMatch(state.textIt as String);
    expect(match, isNotNull);
    final shots = int.parse(match!.group(1)!);
    expect(shots, inInclusiveRange(1, 6));
    expect(1000 - (target.hp as int) + 12 - (target.shield as int), shots * 5);
    await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
