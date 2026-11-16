import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets('separation blocks the body and grants its caster one attack', (
    tester,
  ) async {
    final (_, probe) = await mountFight(tester);
    final initialMovement = probe.movement();
    expect(initialMovement, greaterThan(0));
    final target = probe.ownerTag();
    final request = <String, dynamic>{
      'id': 'spiritual-primary',
      'sourceTag': 'ENEMY',
      'targetTag': target,
      'encounterId': probe.activeCombatEncounterId,
      'scope': probe.permissionScope,
    };
    bool apply({String id = 'spiritual-primary'}) =>
        probe.applyElementalSphereSoulSeparation(
          {...request, 'id': id},
          durationTurns: 3,
          difficulty: 'facile',
        );

    expect(apply(), isTrue);
    expect(apply(), isFalse, reason: 'Same successful packet cannot reapply');
    expect(probe.movement(), 0);
    expect(await probe.spendCombatRoll(), isFalse);
    final condition = (probe.snapshot()['conditions'] as List)
        .whereType<Map>()
        .singleWhere(
          (row) => row['conditionType'] == oculumElementalSphereSoulCondition,
        );
    expect(condition['duration'], 2);
    final opportunity = probe.elementalSphereOpportunity(target, 'ENEMY');
    expect(opportunity, condition['id']);
    expect(probe.elementalSphereOpportunity(target, 'OTHER'), isNull);
    expect(
      probe.claimElementalSphereOpportunity(target, 'OTHER', opportunity!),
      isFalse,
    );
    expect(
      probe.claimElementalSphereOpportunity(target, 'ENEMY', opportunity),
      isTrue,
    );
    expect(
      probe.claimElementalSphereOpportunity(target, 'ENEMY', opportunity),
      isFalse,
    );
    expect(probe.movement(), 0);
    final saved = probe.snapshot();
    probe.load(saved);
    expect(probe.elementalSphereOpportunity(target, 'ENEMY'), isNull);

    probe.tickConditions(OculumConditionTickTrigger.endTurn);
    expect(probe.movement(), 0);
    probe.tickConditions(OculumConditionTickTrigger.endTurn);
    expect(probe.movement(), initialMovement);
    expect(probe.elementalSphereOpportunity(target, 'ENEMY'), isNull);
    expect(apply(), isFalse, reason: 'Expired requests cannot reapply');

    await closeFixture(tester, probe);
  });

  testWidgets(
    'free attack fixes the target and claims only after confirmation',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final source = probe.ownerTag();
      final sourceSheet = probe.snapshot();
      final targetSheet = probe.snapshot()
        ..['id'] = 'ENEMY'
        ..['sheetTag'] = 'ENEMY'
        ..['nome'] = 'Bersaglio';
      state.schedePersonaggio.add(targetSheet);
      state.schedaCorrente = 1;
      probe.load(targetSheet);
      final target = probe.ownerTag();
      (state.masterInitiativeTokens as List).whereType<Map>().firstWhere(
        (token) => token['sheetTag'] == 'ENEMY',
      )
        ..['sheetTag'] = target
        ..['id'] = target;
      probe.recordCurrentEncounter();
      expect(
        probe.applyElementalSphereSoulSeparation(
          {
            'id': 'spiritual-free-attack',
            'sourceTag': source,
            'targetTag': target,
            'encounterId': probe.activeCombatEncounterId,
            'scope': probe.permissionScope,
          },
          durationTurns: 3,
          difficulty: 'normale',
        ),
        isTrue,
      );
      state.schedePersonaggio[1] = probe.snapshot();
      state.schedaCorrente = 0;
      probe.load(sourceSheet);
      final grant = probe.elementalSphereOpportunity(target, source);
      expect(grant, isNotNull);
      final before = probe.combatTurnResources();
      Future<void> open() => probe.planAttack(
        targetId: target,
        sphereSoulOpportunityId: grant,
        total: 25,
        natural: 15,
      );
      final planner = find.byType(OculumAttackPlanner);
      final cancelled = open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.widget<OculumAttackPlanner>(planner).targets.keys, [
        target,
      ]);
      Navigator.of(tester.element(planner)).pop();
      await tester.pump(const Duration(milliseconds: 400));
      await cancelled;
      expect(probe.elementalSphereOpportunity(target, source), grant);

      final committed = open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      Navigator.of(
        tester.element(planner),
      ).pop(OculumAttackPlan(target, 'vc', 'Attacco di opportunità'));
      await tester.pump(const Duration(milliseconds: 400));
      await committed;
      expect(probe.elementalSphereOpportunity(target, source), isNull);
      expect(probe.combatTurnResources(), before);
      final requests = (state.onlineCombatRequests as Map).values
          .whereType<Map>();
      expect(
        requests.where((request) => request['targetTag'] == target),
        hasLength(1),
      );
      await closeFixture(tester, probe);
    },
  );
}
