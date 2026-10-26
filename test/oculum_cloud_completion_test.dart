import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;

void main() {
  testWidgets(
    'cloud draws monster attacks and the best element is chosen individually',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.schedePersonaggio.first['monsterBookSourceId'] = 'rock_cloud_golem';
      state.masterInitiativeTokens[1]['cloudLifeActive'] = true;
      const plan = OculumAttackPlan('OTHER', 'vc', '');
      expect(p.provoke(plan, 99).targetId, 'ENEMY');
      state.schedePersonaggio.first.remove('monsterBookSourceId');
      expect(p.provoke(plan, 0).targetId, 'OTHER');
      p.setIncomingDamagePreset('nuvola', 'Resistenza');
      p.setIncomingDamagePreset('roccia', 'Fragilità');
      p.setIncomingDamagePreset('fulmine', 'Normale');
      expect(p.bestIncomingElement(['nuvola', 'roccia', 'fulmine']), 'roccia');
      p.setIncomingDamagePreset('roccia', 'Normale');
      expect(
        p.bestIncomingElement(['roccia', 'fulmine'], tieIndex: 0),
        'roccia',
      );
      expect(
        p.bestIncomingElement(['roccia', 'fulmine'], tieIndex: 1),
        'fulmine',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'barrier reply and critical propagation are free and idempotent',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      p.applyEffects([
        OculumStructuredEffect(
          type: 'planar',
          target: 'barrier',
          valueExpression: '2',
          duration: '3',
        ),
      ]);
      final attack = <String, dynamic>{
        'id': 'enemy-hit',
        'sourceTag': 'ENEMY',
        'targetTag': p.ownerTag(),
      };
      p.barrierResponse(attack, {'shieldLost': 0}, 20);
      expect(state.onlineCombatRequests['cloud-barrier:enemy-hit'], isNull);
      p.barrierResponse(attack, {'shieldLost': 5}, 20);
      p.barrierResponse(attack, {'shieldLost': 5}, 20);
      final response =
          state.onlineCombatRequests['cloud-barrier:enemy-hit']
              as Map<String, dynamic>;
      expect(response['natural'], 20);
      expect(response['cloudBarrierResponse'], true);
      response.addAll({
        'status': 'resolved',
        'attack': 100,
        'defense': 1,
        'outcome': 'full',
      });
      p.barrierCritical(response);
      final count = state.onlineCombatRequests.length;
      p.barrierCritical(response);
      expect(state.onlineCombatRequests.length, count);
      final splash = state.onlineCombatRequests.values
          .where((dynamic r) => r['cloudBarrierSplash'] == true)
          .toList();
      expect(splash, hasLength(1));
      expect(splash.single['targetTag'], 'OTHER');
      expect(
        (splash.single['effects'] as List).single['appliedState'],
        'stordito',
      );
      expect(
        (splash.single['effects'] as List).single['durationUnit'],
        'azioni',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
