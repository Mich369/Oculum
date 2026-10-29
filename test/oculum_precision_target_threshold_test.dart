import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  for (final precision in [2, 3]) {
    testWidgets(
      'real planner body target threshold at Precisione +$precision, cancellation spends nothing',
      (tester) async {
        final (state, p) = await fixtures.mountFight(tester);
        final stat = (state.hiddenEyeStats as List)
            .cast<HiddenEyeStat>()
            .firstWhere((stat) => stat.id == 'precisione');
        stat.valore += precision - p.subtraitValue('precisione');
        p.invalidateDerivedCaches();
        expect(p.subtraitValue('precisione'), precision);
        final target = p.attackTargetTags().first;
        for (final token
            in (state.masterInitiativeTokens as List).whereType<Map>()) {
          if (token['id'] == target || token['sheetTag'] == target) {
            token['monsterBookId'] = 'guardia_solare';
            token['monsterBookSourceId'] = 'guardia_solare';
          }
        }
        final before = Map<String, dynamic>.from(p.combatTurnResources());
        final opening = p.planAttack(total: 20, natural: 10);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final finder = find.byType(OculumAttackPlanner);
        expect(finder, findsOneWidget);
        final planner = tester.widget<OculumAttackPlanner>(finder);
        expect(
          planner.choices.any(
            (choice) => choice.id == 'precisione_punto_debole',
          ),
          precision == 3,
        );
        if (precision == 3) {
          Navigator.of(
            tester.element(finder),
          ).pop(OculumAttackPlan(target, 'precisione', ''));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(
            find.textContaining('Scegli una parte del corpo'),
            findsOneWidget,
          );
          Navigator.of(tester.element(find.byType(SimpleDialog).last)).pop();
        } else {
          Navigator.of(tester.element(finder)).pop();
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await opening;
        expect(p.combatTurnResources(), before);
        await closeFixture(tester, p);
      },
    );
  }
}
