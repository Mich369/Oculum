import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets('normal shield break reduces effective stats until recovery', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.updateOculumHomeUi(() {
      state.campaignDifficulty = 'normale';
      state.karmaController.text = '0';
      state.fortuna = 0;
      state.livelloController.text = '0';
      state.gradoController.text = '0';
      state.dannoOltreDifesa = false;
      state.dannoOltreScudi = false;
      state.incomingDamagePresets.clear();
      state.modificatoreDannoSelezionato = 'Normale';
      for (final HiddenEyeStat stat in state.hiddenEyeStats) {
        if (stat.id == 'resistenza') stat.valore = -100;
        if (stat.id == 'fortuna') stat.unlocked = false;
      }
      state.resilienzaController.text = '30';
      state.volontaController.text = '20';
      state.materiaController.text = '20';
      probe.setResourceCurrent('resilienza', 30);
      probe.setResourceCurrent('volonta', 20);
      probe.setResourceCurrent('materia', 20);
      probe.setResourceCurrent('oculum', 0);
      state.currentHpController.text = '100';
      state.scudoController.text = '8';
      state.scudoOculumMaxController.text = '5';
      state.scudoOculumController.text = '5';
      state.invalidateDerivedDataCaches();
    });

    final initialStats = probe.coreStats();
    final initialFormula = probe.formulaContext();
    int penalty() {
      final runtime = probe.snapshot()['planarRuntime'];
      return runtime is Map
          ? runtime['normalShieldBreakPenalty'] as int? ?? 0
          : 0;
    }

    void expectStats(int reduction) {
      final effective = probe.coreStats();
      final formula = probe.formulaContext();
      for (final stat in ['volonta', 'materia']) {
        expect(effective[stat], initialStats[stat]! - reduction, reason: stat);
        expect(formula[stat], initialFormula[stat]! - reduction, reason: stat);
        expect(probe.resourceCurrent(stat), 20, reason: stat);
      }
      expect(penalty(), reduction);
    }

    Future<void> hit(
      int amount, {
      bool critical = false,
      bool bypass = false,
    }) => probe.damageResolved(
      amount,
      bypassDefense: true,
      critical: critical,
      bypassShields: bypass,
    );

    expectStats(0);
    await hit(5); // Oculum Shield only.
    expect(state.scudoOculumController.text, '0', reason: '${state.risultato}');
    expect(probe.shieldTotal(), 8);
    expectStats(0);
    state.scudoCriticoController.text = '1';
    await hit(1, critical: true, bypass: true);
    expect(probe.criticalShieldTotal(), 0);
    expect(probe.shieldTotal(), 8);
    expectStats(0);
    await hit(2);
    expect(probe.shieldTotal(), 6);
    expectStats(0);
    await hit(6);
    expect(probe.shieldTotal(), 0);
    expectStats(2);

    probe.reportedTurn(1);
    expectStats(1);
    probe.reportedTurn(1);
    expectStats(1);
    await hit(1);
    expectStats(1);

    final saved =
        jsonDecode(jsonEncode(probe.snapshot())) as Map<String, dynamic>;
    state.schedePersonaggio[0] = saved;
    probe.load(saved);
    expectStats(1);

    probe.applyEffects([
      OculumStructuredEffect(type: 'scudo', valueExpression: '4'),
    ]);
    expect(probe.shieldTotal(), 4);
    expectStats(0);
    await hit(4);
    expectStats(2);
    probe.reportedTurn(2);
    expectStats(1);
    probe.reportedTurn(3);
    expectStats(0);

    expect(tester.takeException(), isNull);
    await closeFixture(tester, probe);
  });
}
