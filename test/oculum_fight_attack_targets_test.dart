import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _ConnectedCombat extends OculumRealtimeService {
  _ConnectedCombat()
    : super(
        roomId: 'targets',
        playerName: 'Eroe',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      );
  @override
  bool get isConnected => true;
}

void main() {
  for (final online in [false, true]) {
    testWidgets(
      'attack selects its own fight and a real target ${online ? 'online' : 'offline'}',
      (tester) async {
        final (state, p) = await fixtures.mountFight(tester);
        final ownTag = p.ownerTag();
        final own = Map<String, dynamic>.from(p.combatTurnEncounter());
        own['tokens'] = [
          {
            'id': ownTag.toLowerCase(),
            'sheetTag': ' $ownTag ',
            'name': 'Eroe',
            'side': 'party',
            'status': 'active',
          },
          {
            'id': 'enemy-own',
            'sheetTag': 'enemy-own',
            'name': 'Bersaglio corretto',
            'side': 'enemy',
            'status': 'ready',
          },
        ];
        final other = <String, dynamic>{
          'id': 'other-fight',
          'encounterId': 'other-fight',
          'fightStarted': true,
          'tokens': [
            {
              'id': 'stranger',
              'name': 'Altro fight',
              'side': 'enemy',
              'status': 'active',
            },
          ],
          'activeIndex': 0,
          'round': 1,
        };
        if (online) {
          state.modalitaMaster = false;
          state.isMasterHost = false;
          state.realtimeService = _ConnectedCombat();
          state.realtimeEncounterSnapshots = <Map<String, dynamic>>[own, other];
          state.realtimeSelectedEncounterId = 'other-fight';
          state.realtimeVisibleInitiativeSnapshot = other;
        } else {
          state.masterInitiativeGroups.first['tokens'] = own['tokens'];
          state.masterInitiativeTokens
            ..clear()
            ..addAll((own['tokens'] as List).cast<Map<String, dynamic>>());
          p.recordCurrentEncounter();
          state.masterInitiativeGroups.add(other);
          p.selectEncounter('other-fight');
        }
        expect(p.attackTargetTags(), ['enemy-own']);
        final opening = p.useCombatRoll(OculumCombatAbilityRole.attack);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(OculumAttackPlanner), findsOneWidget);
        expect(find.text('Bersaglio corretto'), findsOneWidget);
        expect(find.text('Altro fight'), findsNothing);
        expect(
          online
              ? state.realtimeSelectedEncounterId
              : state.selectedMasterInitiativeGroupId,
          own['encounterId'],
        );
        Navigator.of(tester.element(find.byType(OculumAttackPlanner))).pop();
        await opening;
        if (!online) {
          expect(await p.utilitySpend('azione'), isTrue);
          expect(state.masterInitiativeTokens.first['actionUsed'], isTrue);
        }
        state.realtimeService = null;
        await closeFixture(tester, p);
      },
    );
  }
  testWidgets(
    'empty fight cannot silently fall back to a generic attack roll',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.masterInitiativeTokens.removeWhere((t) => t['side'] == 'enemy');
      p.recordCurrentEncounter();
      final before = p.combatTurnResources();
      final opening = p.useCombatRoll(OculumCombatAbilityRole.attack);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Nessun bersaglio disponibile'), findsOneWidget);
      expect(p.combatTurnResources(), before);
      await tester.tap(find.text('Chiudi'));
      await opening;
      await closeFixture(tester, p);
    },
  );
}
