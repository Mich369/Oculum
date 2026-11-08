import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_protection_wear_test.dart' show prepareProtectionFixture;

void main() {
  test('physical resistance loses a tier for every six points short', () {
    const expectedTiers = {
      -1: 'Alta Resistenza',
      0: 'Alta Resistenza',
      5: 'Alta Resistenza',
      6: 'Resistenza',
      11: 'Resistenza',
      12: 'Resistenza Leggera',
      17: 'Resistenza Leggera',
      18: 'Normale',
    };
    for (final entry in expectedTiers.entries) {
      expect(
        oculumStat20PhysicalResistanceTier(
          attackTotal: 25,
          resistanceTotal: 25 - entry.key,
        ),
        entry.value,
      );
    }
  });

  testWidgets(
    'waking Life absorbs damage and cannot be refilled the same day',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      prepareProtectionFixture(state, probe);
      state.resilienzaController.text = '20';
      probe.setResourceCurrent('resilienza', 20);
      probe.setWorldClock({'seconds': 0, 'calendarOriginDay': 15});
      final runtime =
          state.schedePersonaggio[state.schedaCorrente]['planarRuntime'] as Map;
      runtime['stat35'] = {
        'choices20': {'resilienza': 'res_vital_wake'},
      };
      probe.longRest(advanceWorldClock: false);
      final wakingLife = probe.currentTemporaryHp();
      expect(wakingLife, inInclusiveRange(51, 100));
      final life = probe.currentHp();
      await probe.damageResolved(10, bypassDefense: true, bypassShields: true);
      expect(probe.currentHp(), life);
      expect(probe.currentTemporaryHp(), wakingLife - 10);

      await tester.pump(const Duration(milliseconds: 451));
      probe.longRest(advanceWorldClock: false);
      expect(probe.currentTemporaryHp(), wakingLife - 10);

      await tester.pump(const Duration(milliseconds: 451));
      probe.setWorldClock({
        'seconds': oculumWorldDaySeconds,
        'calendarOriginDay': 15,
      });
      probe.longRest(advanceWorldClock: false);
      expect(runtime['stat20WakingLife']['day'], 'clock:1');
      expect(probe.currentTemporaryHp(), inInclusiveRange(51, 100));
      await closeFixture(tester, probe);
    },
  );
}
