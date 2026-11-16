import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

const _opponents = ['ENEMY', 'OTHER', 'THIRD'];
const _ally = 'ALLY';

Future<(dynamic, OculumPerformanceProbe, int)> _setup(
  WidgetTester tester, {
  bool prepareThroughArt = false,
}) async {
  final (state, probe) = await mountFight(tester);
  state.schedePersonaggio[0]['monsterBookSourceId'] = oculumSoulFighterEliteId;
  state.tipoSchedaController.text = 'Mostro';
  state.titoli.clear();
  state.arti.clear();
  state.skills.clear();
  state.inventario.clear();
  state.buffMalusRapidiController.clear();
  state.activeStructuredEffects.clear();
  state.masterInitiativeTokens.addAll([
    <String, dynamic>{
      'id': _opponents.last,
      'sheetTag': _opponents.last,
      'name': 'Terzo nemico',
      'side': 'enemy',
      'status': 'ready',
    },
    <String, dynamic>{
      'id': _ally,
      'sheetTag': _ally,
      'name': 'Alleato',
      'side': 'party',
      'status': 'ready',
    },
  ]);
  state.masterInitiativeActiveIndex = 0;
  state.masterInitiativeTokens.first['actionUsed'] = false;
  probe.recordCurrentEncounter();
  state.attaccoRapidoController.text = '30';
  probe.invalidateDerivedCaches();
  final damage = probe.damageTotal();
  // Leave a rounding remainder for both two- and three-target casts.
  state.attaccoRapidoController.text = '${30 + (1 - damage) % 6}';
  probe.invalidateDerivedCaches();
  final baseDamage = probe.damageTotal();
  expect(baseDamage, greaterThan(0));
  expect(baseDamage % 6, 1);

  final art = oculumAnymareapArt();
  final skill = art.skills.firstWhere(
    (skill) => skill
        .effettiEvoluzione(1)
        .any((effect) => effect.id == oculumAnymareapEffect),
  );
  if (prepareThroughArt) {
    state.oculumController.text = '8';
    state.currentOculumController.text = '8';
    art.integritaCorrente = 30;
    state.arti.add(art);
    probe.invalidateDerivedCaches();
    final before = probe.availableArtResource('oculum');
    final activation = probe.useArtSkill(0, 0, 1, again: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Attiva e spendi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await activation;
    expect(probe.availableArtResource('oculum'), before - 4);
    expect(skill.cooldownPerLivello.first.remaining, 4);
  } else {
    probe.applyEffects(
      skill.effettiEvoluzione(1),
      source: '${art.nome} / ${skill.nome}',
    );
  }
  expect(probe.combatTurnResources()['actions'], 1);
  return (state, probe, baseDamage);
}

Future<void> _declare(
  WidgetTester tester,
  OculumPerformanceProbe probe,
  List<String> targetTags,
) async {
  final pending = probe.planAttack(total: 30, natural: 10);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  final planner = find.byType(OculumAttackPlanner);
  expect(planner, findsOneWidget);
  final widget = tester.widget<OculumAttackPlanner>(planner);
  expect(widget.minimumTargets, 1);
  expect(widget.maximumTargets, 3);
  expect(widget.targets.keys, unorderedEquals(_opponents));
  Navigator.of(tester.element(planner)).pop(
    OculumAttackPlan(
      targetTags.first,
      'vc',
      '',
      additionalTargetIds: targetTags.skip(1).toList(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await pending;
}

List<Map> _packets(dynamic state) => (state.onlineCombatRequests as Map).values
    .whereType<Map>()
    .where((request) => request['attackGroupId'] != null)
    .toList();

void main() {
  for (final count in [1, 2, 3]) {
    testWidgets('Anymareap splits one attack across $count enemies', (
      tester,
    ) async {
      final (state, probe, baseDamage) = await _setup(
        tester,
        prepareThroughArt: count == 3,
      );
      final targets = _opponents.take(count).toList();
      await _declare(tester, probe, targets);
      final packets = _packets(state);
      expect(
        packets.map((request) => request['targetTag']),
        unorderedEquals(targets),
      );
      expect(
        packets.map((request) => request['attackGroupId']).toSet(),
        hasLength(1),
      );
      expect(
        packets.map((request) => request['element']),
        everyElement('spirituale'),
      );
      expect(
        packets.map((request) => request['damage']),
        everyElement((baseDamage + count - 1) ~/ count),
      );
      expect(
        packets
            .expand(
              (request) => (request['turnResourceSpends'] as List? ?? const [])
                  .whereType<Map>(),
            )
            .map((spend) => spend['activityResource']),
        ['azione'],
      );
      expect(probe.combatTurnResources()['actions'], 0);
      await closeFixture(tester, probe);
    });
  }

  testWidgets(
    'Anymareap rejects allies and duplicate targets before spending',
    (tester) async {
      final (state, probe, _) = await _setup(tester);
      final before = probe.combatTurnResources();

      await _declare(tester, probe, [_opponents.first, _ally]);
      expect(_packets(state), isEmpty);
      expect(probe.combatTurnResources(), before);

      await _declare(tester, probe, [_opponents.first, _opponents.first]);
      expect(_packets(state), isEmpty);
      expect(probe.combatTurnResources(), before);
      await closeFixture(tester, probe);
    },
  );
}
