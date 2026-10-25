import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test(
    'kingdom reserves available space, affects percentages and never creates negative bonuses',
    () {
      expect(oculumWillKingdomWeight(1500, 100), 375);
      expect(oculumWillKingdomWeight(1500, 1400), 100);
      expect(oculumWillKingdomWeight(1500, 1600), 0);
      expect(oculumWillKingdomValue(1000, 375), 1037);
      expect(oculumWillKingdomValue(1000, 375, subtrait: true), 1018);
      expect(oculumWillKingdomValue(-3, 375), -3);
    },
  );
  testWidgets(
    'roleplay keeps tracker resources and start fight rerolls everyone; kingdom can be destroyed',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.modalitaMaster = true;
      state.isMasterHost = true;
      if (state.schedePersonaggio.isEmpty) {
        state.schedePersonaggio.add(
          Map<String, dynamic>.from(probe.snapshot())
            ..['id'] = 'RoleplayOcu:3690TEST'
            ..['sheetTag'] = 'RoleplayOcu:3690TEST',
        );
        state.schedaCorrente = 0;
      }
      state.volontaController.text = '499';
      state.currentVolontaController.text = '499';
      expect(probe.toggleWillKingdom(), isFalse);
      state.volontaController.text = '500';
      state.currentVolontaController.text = '500';
      state.inventario.clear();
      final damageBeforeKingdom = probe.damageTotal();
      final statsBeforeKingdom = probe.coreStats();
      expect(probe.toggleWillKingdom(), isTrue);
      expect(probe.willKingdomWeight(), 375);
      expect(probe.kingdomValue(1000), 1037);
      expect(probe.kingdomValue(1000, subtrait: true), 1018);
      expect(probe.damageTotal(), (damageBeforeKingdom * 1.0375).floor());
      expect(probe.coreStats(), statsBeforeKingdom);
      expect(probe.toggleWillKingdom(), isTrue);
      expect(probe.willKingdomWeight(), 0);
      expect(probe.kingdomValue(1000), 1000);
      expect(probe.damageTotal(), damageBeforeKingdom);
      probe.ensureEncounters();
      final id = state.selectedMasterInitiativeGroupId as String;
      state.masterInitiativeTokens.clear();
      final tag = probe.ownerTag();
      state.masterInitiativeTokens.addAll(<Map<String, dynamic>>[
        {
          'id': tag,
          'sheetTag': tag,
          'name': 'Player',
          'side': 'party',
          'status': 'active',
          'initiativeRoll': 0,
          'initiativeBase': 0,
          'initiativeTotal': 0,
          'actionUsed': false,
        },
        {
          'id': 'npc',
          'sheetTag': 'npc',
          'name': 'Compagno',
          'side': 'ally',
          'status': 'ready',
          'initiativeRoll': 0,
          'initiativeBase': 0,
          'initiativeTotal': 0,
          'actionUsed': false,
        },
      ]);
      expect(probe.fightActive(), isFalse);
      expect(probe.trackerActive(), isTrue);
      state.masterInitiativeActiveIndex = 0;
      expect(await probe.utilitySpend('azione'), isTrue);
      expect(await probe.utilitySpend('azione'), isFalse);
      probe.startFight(id);
      expect(probe.fightActive(), isTrue);
      for (final token in state.masterInitiativeTokens as List) {
        expect(token['initiativeRoll'], inInclusiveRange(1, 20));
        expect(token['initiativeRevision'], isNotEmpty);
      }
      final group = (state.masterInitiativeGroups as List)
          .cast<Map>()
          .singleWhere((g) => g['id'] == id);
      group['fightStarted'] = false;
      group['combatEnded'] = true;
      expect(probe.fightActive(), isFalse);
      expect(probe.trackerActive(), isTrue);
      expect((state.masterInitiativeTokens as List).length, 2);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
