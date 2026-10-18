import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  testWidgets(
    'production damage doubles the difficulty bonus, never base damage',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.oculumController.text = '0';
      for (final dynamic stat in state.hiddenEyeStats) {
        if (stat.id == 'fortuna') stat.valore = 0;
      }
      state.currentHpController.text = '1000';
      state.resilienzaController.text = '100';
      state.materiaController.text = '0';
      state.volontaController.text = '0';
      probe.invalidateDerivedCaches();
      await probe.damageResolved(
        51,
        critical: true,
        criticalMultiplier: 2,
        enemyLevel: 10,
      );
      expect(
        (state.logEventi as List).join('\n'),
        contains('51 + 40 critico = 91'),
      );
      expect((state.logEventi as List).join('\n'), isNot(contains('51 + 51')));
      final expectedDefense = (probe.defense() * 1.5).ceil();
      await probe.damageResolved(51, defenseMultiplier: 1.5);
      expect(
        (state.logEventi as List).join('\n'),
        contains('Difesa $expectedDefense (×1,5 · attacco quasi riuscito)'),
      );
      expect(probe.combatAbilityColor('volonta'), Colors.redAccent);
      expect(probe.combatAbilityColor('materia'), Colors.blueAccent);
      expect(probe.combatAbilityColor('resilienza'), Colors.greenAccent);
      expect(probe.combatAbilityColor('oculum'), state.eyePupilGlowColor);
      state.scudoController.text = '10';
      state.scudoOculumController.text = '0';
      final hpBeforeResistance = state.currentHpController.text;
      await probe.damageResolved(999, resolvedResistance: true);
      expect(state.currentHpController.text, hpBeforeResistance);
      expect(state.scudoController.text, '9');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
