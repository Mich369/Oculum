import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_eye_memory_page.dart';
import 'package:oculum/services/oculum_diary_memory.dart';
import 'package:oculum/widgets/oculum_memory_eye.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets('late final hit cannot replace the current Fight memory', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    try {
      final tokens = state.masterInitiativeTokens as List<Map<String, dynamic>>;
      final victim = tokens[1];
      final homonym = tokens[2];
      victim['name'] = homonym['name'] = 'Guardia omonima';
      for (final token in tokens) {
        token['fightInstanceId'] = 'fight-current';
      }
      probe.recordCurrentEncounter();

      Map<String, dynamic> receipt(
        String id,
        String target, {
        String? targetFight,
        String? sourceFight,
      }) => {
        'id': id,
        'encounterId': 'encounter_1',
        'status': 'resolved',
        'sourceTag': probe.ownerTag(),
        'sourceFightInstance': ?sourceFight,
        'targetTag': target,
        'targetFightInstance': ?targetFight,
        'damageReceipt': {'hpLost': 18, 'targetDownedByHit': true},
      };

      probe.rewardCombatResult(
        receipt('current-final-hit', 'ENEMY', targetFight: 'fight-current'),
      );
      expect(victim['eyeMemoryFinalHit']['attackId'], 'current-final-hit');
      expect(homonym['eyeMemoryFinalHit'], isNull);
      probe.rewardCombatResult(
        receipt('old-target-receipt', 'ENEMY', targetFight: 'fight-previous'),
      );
      final afterOldTarget = victim['eyeMemoryFinalHit']['attackId'];
      probe.rewardCombatResult(
        receipt('old-source-receipt', 'ENEMY', sourceFight: 'fight-previous'),
      );
      expect(
        (afterOldTarget, victim['eyeMemoryFinalHit']['attackId']),
        ('current-final-hit', 'current-final-hit'),
      );
      expect(homonym['eyeMemoryFinalHit'], isNull);

      probe.rewardCombatResult(receipt('legacy-current-hit', 'OTHER'));
      expect(homonym['eyeMemoryFinalHit']['attackId'], 'legacy-current-hit');
    } finally {
      await closeFixture(tester, probe);
    }
  });

  testWidgets(
    'same-name victims have distinct evidence and node power is capped',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 1600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final memory = DiaryMemory({}, [])
        ..addCombatDeaths(const [
          DiaryCombatDeath(
            id: 'attack-a',
            killerName: 'Hoshy',
            victimTag: 'Ocu-NPC-A',
            victimName: 'Guardia omonima',
            day: 7,
          ),
          DiaryCombatDeath(
            id: 'attack-b',
            killerName: 'Hoshy',
            victimTag: 'Ocu-NPC-B',
            victimName: 'Guardia omonima',
            day: 15,
          ),
        ]);
      const firstVictim = 'combat-dead:ocu-npc-a';
      const secondVictim = 'combat-dead:ocu-npc-b';
      expect(memory.entities[firstVictim]!.kind, 'dead');
      expect(memory.entities[secondVictim]!.kind, 'dead');
      expect(oculumMemoryEyeAsset('dead'), endsWith('/oculum_dead_eye.png'));
      expect(
        memory.backlinks(firstVictim).single.evidence.document.id,
        'combat-death:attack-a',
      );
      expect(
        memory.backlinks(secondVictim).single.evidence.document.id,
        'combat-death:attack-b',
      );
      final facts = memory.relations
          .map((link) => (link.to, link.state))
          .toList();
      Future<void> pumpPower(int power) async {
        await tester.pumpWidget(
          MaterialApp(
            home: OculumEyeMemoryPage(
              memory: memory,
              author: 'Hoshy',
              ownerTotalPower: power,
              eyeRole: (_) =>
                  'test', // Use the vector eye in an asset-free fixture.
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      double mainEye() => tester
          .widgetList<OculumMemoryEye>(find.byType(OculumMemoryEye))
          .map((eye) => eye.size)
          .reduce((a, b) => a > b ? a : b);

      await pumpPower(0);
      await tester.tap(find.widgetWithText(ActionChip, 'Hoshy'));
      await tester.pumpAndSettle();
      final base = mainEye();
      expect(base, greaterThan(24));
      await pumpPower(200);
      expect(mainEye(), greaterThan(base));
      await pumpPower(1000000);
      final capped = mainEye();
      expect(capped, closeTo(base + 22, 0.0001));
      await pumpPower(2000000);
      expect(mainEye(), capped);
      expect(memory.relations.map((link) => (link.to, link.state)), facts);
      expect(
        memory.entities.values.where((entity) => entity.kind == 'dead'),
        hasLength(2),
      );

      final firstLink = find.byKey(
        const ValueKey(
          'memory_combat-death:attack-a_0_character:hoshy_combat-dead:ocu-npc-a_killed',
        ),
      );
      await tester.scrollUntilVisible(
        firstLink,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(firstLink);
      await tester.pumpAndSettle();
      expect(find.textContaining('Colpo finale'), findsWidgets);
      expect(find.byType(SelectableText), findsOneWidget);
    },
  );
}
