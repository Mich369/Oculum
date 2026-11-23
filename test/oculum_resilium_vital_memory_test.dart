import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets(
    'Resilium starts Vital Memory on real attack HP loss once per long rest',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      state.razzaController.text = 'Resilium';
      state.resilienzaController.text = '20';
      state.currentResilienzaController.text = '20';
      state.currentHpController.text = '100';
      state.scudoController.text = '60';
      probe.invalidateDerivedCaches();
      await tester.runAsync(
        () => probe.damageResolved(
          20,
          confirmedAttack: true,
          bypassDefense: true,
        ),
      );
      expect(probe.conditions, isEmpty);
      expect(state.currentHpController.text, '100');
      expect(probe.planarStateSnapshot()['resiliumVitalMemoryUsed'], isNull);

      state.scudoController.text = '0';
      probe.applyEffects([
        OculumStructuredEffect(type: 'hp_temporanei', valueExpression: '20'),
      ]);
      await tester.runAsync(
        () => probe.damageResolved(
          10,
          confirmedAttack: true,
          bypassDefense: true,
        ),
      );
      expect(
        probe.conditions.where(
          (condition) => condition.conditionType == 'ricordo_vitale',
        ),
        isEmpty,
      );
      expect(state.currentHpController.text, '100');

      await tester.runAsync(
        () =>
            probe.damageResolved(20, bypassDefense: true, bypassShields: true),
      );
      expect(
        probe.conditions.where(
          (condition) => condition.conditionType == 'ricordo_vitale',
        ),
        isEmpty,
      );
      final before = int.parse(state.currentHpController.text as String);
      await tester.runAsync(
        () => probe.damageResolved(
          20,
          confirmedAttack: true,
          bypassDefense: true,
          bypassShields: true,
        ),
      );
      final memory = probe.conditions.singleWhere(
        (condition) => condition.conditionType == 'ricordo_vitale',
      );
      final after = int.parse(state.currentHpController.text as String);
      expect(before - after, 20);
      expect(memory.duration, 12);
      expect(memory.metadata['pendingHealing'], 10);
      expect(memory.metadata['healingChunk'], 5);
      expect(probe.planarStateSnapshot()['resiliumVitalMemoryUsed'], true);

      probe.reportedTurn(12);
      expect(
        probe.conditions.where(
          (condition) => condition.conditionType == 'ricordo_vitale',
        ),
        isEmpty,
      );
      await tester.runAsync(
        () => probe.damageResolved(
          5,
          confirmedAttack: true,
          bypassDefense: true,
          bypassShields: true,
        ),
      );
      expect(
        probe.conditions.where(
          (condition) => condition.conditionType == 'ricordo_vitale',
        ),
        isEmpty,
      );

      probe.longRest(advanceWorldClock: false);
      await tester.pump(const Duration(milliseconds: 500));
      expect(probe.planarStateSnapshot()['resiliumVitalMemoryUsed'], isNull);
      await tester.runAsync(
        () => probe.damageResolved(
          5,
          confirmedAttack: true,
          bypassDefense: true,
          bypassShields: true,
        ),
      );
      expect(
        probe.conditions
            .singleWhere(
              (condition) => condition.conditionType == 'ricordo_vitale',
            )
            .duration,
        12,
      );
      await closeFixture(tester, probe);
    },
  );
}
