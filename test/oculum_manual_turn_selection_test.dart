import 'package:flutter_test/flutter_test.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  for (final legacy in [true, false]) {
    testWidgets(
      'manual active selection preserves consumed resources and movement ${legacy ? 'on legacy saves' : 'on current saves'}',
      (tester) async {
        final (state, p) = await fixtures.mountFight(tester);
        state.masterInitiativeRound = 2;
        for (final token in state.masterInitiativeTokens as List) {
          token.addAll(<String, dynamic>{
            'fightInstanceId': 'manual-selector-fight',
            'reactionPoolInitialized': true,
            'reactionPoolRound': 2,
            'reactionNormalFirstRoundLocked': false,
            'reactionMax': 1,
            'reactionFastMax': 1,
            'reactionUsedRound': 2,
            'currentHp': 100,
            'maxHp': 100,
          });
        }
        final enemy = state.masterInitiativeTokens[1] as Map<String, dynamic>;
        enemy.addAll(<String, dynamic>{
          'actionTurnRound': legacy ? -1 : 2,
          'totalPower': 50,
          'actionUsed': true,
          'reactionUsed': 1,
          'reactionFastUsed': 1,
          'fastReactionPersonalTurnRound': 1,
          'mapTokenId': 'spent-movement',
          'mechaPilotExtra': true,
          'extraNormalReactionCurrent': 2,
        });
        final mapToken = <String, dynamic>{
          'id': 'spent-movement',
          'movementUsedMeters': 4.0,
          'movementRound': 2,
        };
        state.localMapTokens.add(mapToken);
        p.normalizeInitiative();
        final beforeWorld = p.worldSeconds();
        final beforeTurnBuckets =
            (enemy['rewardPowerTurnMaxima'] as Map?)?.length ?? 0;
        p.activateInitiative(1);
        p.activateInitiative(0);
        p.activateInitiative(1);
        expect(state.masterInitiativeActiveIndex, 1);
        expect(enemy['actionUsed'], true);
        expect(enemy['reactionUsed'], 1);
        expect(enemy['reactionFastUsed'], 1);
        expect(enemy['extraNormalReactionCurrent'], 2);
        expect(enemy['fastReactionPersonalTurnRound'], 1);
        expect(enemy['actionTurnRound'], 2);
        expect(mapToken['movementUsedMeters'], 4.0);
        expect(p.worldSeconds(), beforeWorld);
        expect(
          (enemy['rewardPowerTurnMaxima'] as Map?)?.length ?? 0,
          beforeTurnBuckets,
        );
        // A genuine next personal turn still restores the ordinary resources.
        p.turn();
        p.turn();
        p.turn();
        expect(state.masterInitiativeRound, 3);
        expect(state.masterInitiativeActiveIndex, 1);
        expect(enemy['actionUsed'], false);
        expect(enemy['actionTurnRound'], 3);
        expect(enemy['reactionUsed'], 0);
        expect(mapToken['movementUsedMeters'], 0.0);
        await closeFixture(tester, p);
      },
    );
  }
}
