import 'dart:math';

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
      state.campaignDifficulty = 'normale';
      state.livelloController.text = '0';
      state.gradoController.text = '0';
      state.karmaController.text = '0';
      state.fortuna = 0;
      state.oculumController.text = '0';
      state.currentOculumController.text = '0';
      state.hiddenEyeStats
        ..clear()
        ..addAll([
          HiddenEyeStat(id: 'fortuna', nome: 'Fortuna', descrizione: ''),
          HiddenEyeStat(id: 'resistenza', nome: 'Resistenza', descrizione: ''),
        ]);
      // Keep both hits above the awakening threshold without passive reduction.
      state.resilienzaController.text = '1';
      state.currentResilienzaController.text = '1';
      state.manualHpMaximumAdjustment = 400;
      state.materiaController.text = '8';
      state.currentMateriaController.text = '8';
      state.volontaController.text = '0';
      state.currentVolontaController.text = '0';
      state.scudoController.text = '0';
      state.scudoOculumController.text = '0';
      state.scudoCriticoController.text = '0';
      state.hpTempController.text = '0';
      state.incomingDamagePresets.clear();
      state.dannoSubitoPercentPerTipo.clear();
      probe.invalidateDerivedCaches();
      expect(probe.subtraitValue('fortuna'), 0);
      expect(probe.subtraitValue('resistenza'), 0);
      final fullHp = probe.maximumHp();
      state.currentHpController.text = '$fullHp';
      await probe.damageResolved(
        51,
        critical: true,
        criticalShieldAlreadyBroken: true,
        criticalMultiplier: 2,
        enemyLevel: 10,
        bypassDefense: true,
        bypassShields: true,
      );
      // Normale gives 2 × enemy level. The multiplier applies only to that bonus.
      final hpAfterCritical = fullHp - 91;
      expect(state.currentHpController.text, '$hpAfterCritical');
      final log = (state.logEventi as List).join('\n');
      expect(log, contains('Vita −91'));
      expect(log, isNot(contains('51 + 40')));

      expect(probe.defense(), greaterThan(0));
      final expectedDefense = (probe.defense() * 1.5).ceil();
      await probe.damageResolved(51, defenseMultiplier: 1.5);
      expect(
        state.currentHpController.text,
        '${hpAfterCritical - max(1, 51 - expectedDefense)}',
      );
      expect(probe.combatAbilityColor('volonta'), const Color(0xFFE74C3C));
      expect(probe.combatAbilityColor('materia'), const Color(0xFF44A7FF));
      expect(probe.combatAbilityColor('resilienza'), const Color(0xFF2ECC71));
      expect(probe.combatAbilityColor('oculum'), state.oculumStatFormulaColor);
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
