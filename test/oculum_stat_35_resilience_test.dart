import 'package:flutter_test/flutter_test.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_protection_wear_test.dart' show prepareProtectionFixture;

void main() {
  testWidgets(
    'Resilienza 35 counts only Life hits and triggers Ricordo Vitale once',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      prepareProtectionFixture(state, probe);
      state.resilienzaController.text = '35';
      probe.setResourceCurrent('resilienza', 35);
      state.currentHpController.text = '100';
      Map currentSheet() =>
          state.schedePersonaggio[state.schedaCorrente] as Map;
      final runtime = currentSheet()['planarRuntime'] as Map;
      const awakeningKey = 'partialAwakeningHalfHpTriggered';
      currentSheet()[awakeningKey] = false;
      runtime['stat35'] = {
        'choices': {'resilienza': 'res_regen'},
      };
      state.scudoController.text = '5';
      await probe.damageResolved(5, bypassDefense: true);
      expect(probe.currentHp(), 100);
      expect(runtime['stat35ResRegen'], isNull);
      expect(currentSheet()[awakeningKey], isFalse);

      // The real Life hits below half Life can trigger a separate random roll.
      currentSheet()[awakeningKey] = true;
      for (final expected in [90, 80, 78]) {
        await probe.damageResolved(
          10,
          bypassDefense: true,
          bypassShields: true,
        );
        expect(probe.currentHp(), expected);
      }
      final threshold = probe.maximumHp() ~/ 5;
      state.currentHpController.text = '${threshold + 5}';
      await probe.damageResolved(5, bypassDefense: true, bypassShields: true);
      final memory = probe.conditions.singleWhere(
        (item) => item.conditionType == 'ricordo_vitale',
      );
      expect(memory.duration, 3);
      expect((runtime['stat35ResRegen'] as Map)['vitalMemoryUsed'], true);
      await closeFixture(tester, probe);
    },
  );
}
