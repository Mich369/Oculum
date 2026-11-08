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
      final runtime =
          state.schedePersonaggio[state.schedaCorrente]['planarRuntime'] as Map;
      runtime['stat35'] = {
        'choices': {'resilienza': 'res_regen'},
      };
      state.scudoController.text = '5';
      await probe.damageResolved(5, bypassDefense: true);
      expect(probe.currentHp(), 100);
      expect(runtime['stat35ResRegen'], isNull);

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
