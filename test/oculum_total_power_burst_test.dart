import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;

void main() {
  test(
    'fatigue steps at 160, lasts 1d3 and hit bonus has a minimum of two',
    () {
      for (final power in [0, 159, 160, 319, 320, 1600]) {
        expect(oculumPowerBurstTurns(power, 1), 1 + power ~/ 160);
        expect(oculumPowerBurstTurns(power, 3), 3 + power ~/ 160);
      }
      expect(oculumPowerBurstAccuracy(0), 10);
      expect(oculumPowerBurstAccuracy(7), 3);
      expect(oculumPowerBurstAccuracy(8), 2);
      expect(oculumPowerBurstAccuracy(25), 2);
      for (final will in [false, true]) {
        final skill = oculumTotalPowerBurstSkill(will: will);
        expect(skill.oculumMinimoPerLivello(1), 5);
        expect(skill.cooldownPerLivello.first.amount, 3);
        final copy = ArtSkill.fromJson(jsonDecode(jsonEncode(skill.toJson())));
        copy.effettiPerLivello.first.first.valueExpression =
            'potenza_totale+30';
        expect(
          ArtSkill.fromJson(
            copy.toJson(),
          ).effettiPerLivello.first.first.valueExpression,
          'potenza_totale+30',
        );
        expect(
          oculumTotalPowerBurstSkill(
            will: will,
          ).effettiPerLivello.first.first.valueExpression,
          'potenza_totale',
        );
      }
      expect(
        oculumAbilityCatalogueEntries().where(
          (e) => e.id.startsWith('total_power_'),
        ),
        hasLength(2),
      );
    },
  );

  testWidgets(
    'one outgoing hit and one incoming enemy hit survive JSON without duplication',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final token = state.masterInitiativeTokens.first as Map<String, dynamic>;
      token.addAll({
        'reactionMax': 5,
        'reactionFastMax': 4,
        'extraNormalReactionCurrent': 3,
        'extraFastReactionCurrent': 8,
        'reactionPoolInitialized': true,
      });
      p.totalPowerBurst(320, 2);
      expect(p.exhausted(), true);
      expect(p.normalReactions(), 0);
      expect(p.fastReactions(), 0);
      expect(p.availableReactions(token), 0);
      final saved =
          jsonDecode(jsonEncode(p.snapshot())) as Map<String, dynamic>;
      p.load(saved);
      expect(p.planarStateSnapshot()['totalPowerExhaustionTurns'], 4);
      final packet = <String, dynamic>{
        'id': 'one',
        'sourceTag': p.ownerTag(),
        'targetTag': 'ENEMY',
        'attack': 25,
        'damage': 20,
        'damageTotal': 60,
      };
      p.burstAttack(packet);
      p.burstAttack(packet);
      expect(packet['damage'], 340);
      expect(packet['damageTotal'], 380);
      expect(packet['attack'], 25 + packet['totalPowerBurstAccuracy']);
      final next = <String, dynamic>{
        'sourceTag': p.ownerTag(),
        'targetTag': 'OTHER',
        'attack': 25,
        'damage': 20,
      };
      p.burstAttack(next);
      expect(next['damage'], 20);
      expect(next['attack'], 25);
      final ally = <String, dynamic>{
        'sourceTag': p.ownerTag(),
        'targetTag': p.ownerTag(),
        'attack': 10,
      };
      p.burstExposure(ally);
      expect(ally.containsKey('totalPowerExposureAccuracy'), false);
      final enemy = <String, dynamic>{
        'id': 'enemy-one',
        'sourceTag': 'ENEMY',
        'targetTag': p.ownerTag(),
        'attack': 10,
      };
      p.burstExposure(enemy);
      p.burstExposure(enemy);
      expect(enemy['attack'], 10 + enemy['totalPowerExposureAccuracy']);
      final enemyTwo = <String, dynamic>{
        'sourceTag': 'OTHER',
        'targetTag': p.ownerTag(),
        'attack': 10,
      };
      p.burstExposure(enemyTwo);
      expect(enemyTwo['attack'], 10);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'exhaustion rejects new skill, extra and free reactions and does not refund erased pools',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final token = state.masterInitiativeTokens.first as Map<String, dynamic>;
      state.reazioniController.text = '7';
      state.reazioniVelociController.text = '8';
      token.addAll({
        'reactionMax': 7,
        'reactionFastMax': 8,
        'reactionPoolInitialized': true,
        'reactionPoolRound': 0,
        'extraNormalReactionQueued': 10,
        'outsideNormal': 3,
        'outsideFast': 4,
      });
      state.onlineCombatRequests['free-one'] = <String, dynamic>{
        'targetTag': p.ownerTag(),
        'freeReaction': true,
        'criticalReaction': true,
      };
      p.totalPowerBurst(159, 2);
      expect(state.onlineCombatRequests['free-one']['freeReaction'], false);
      expect(token['extraNormalReactionQueued'], 0);
      expect(await p.utilitySpend('speed_grant_fast'), false);
      expect(await p.utilitySpend('speed_queue_normal'), false);
      expect(await p.utilitySpend('reazione'), false);
      p.applyEffects([
        OculumStructuredEffect(
          type: 'statistica',
          target: 'reazione',
          valueExpression: '99',
          duration: '7',
        ),
      ]);
      expect(
        p.structuredEffects().where((e) => e['target'] == 'reazione'),
        isEmpty,
      );
      token['extraNormalReactionQueued'] = 9;
      token['extraFastReactionCurrent'] = 9;
      p.refreshTurnResources(token);
      expect(p.availableReactions(token), 0);
      expect(token['extraNormalReactionQueued'], 0);
      p.tickPlanar();
      expect(p.exhausted(), true);
      p.totalPowerBurst(0, 1);
      expect(p.planarStateSnapshot()['totalPowerExhaustionTurns'], 1);
      p.tickPlanar();
      expect(p.exhausted(), false);
      expect(token['extraFastReactionCurrent'], 0);
      expect(token['extraNormalReactionQueued'], 0);
      expect(p.normalReactions(), greaterThan(0));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'catalogue formula uses current total power and one rolled fatigue duration',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final before = p.coreStats();
      final expected =
          before.values.fold<int>(0, (sum, v) => sum + v) +
          int.parse(state.livelloController.text) +
          int.parse(state.gradoController.text) * 3;
      p.applyEffects(oculumTotalPowerBurstSkill().effettiEvoluzione(1));
      expect(p.planarStateSnapshot()['totalPowerBurstDamage'], expected);
      expect(
        p.planarStateSnapshot()['totalPowerExhaustionTurns'],
        inInclusiveRange(1 + expected ~/ 160, 3 + expected ~/ 160),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
