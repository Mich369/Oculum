import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _FixedRoll implements Random {
  _FixedRoll(this.value);
  final int value;
  int draws = 0;

  @override
  int nextInt(int max) {
    draws++;
    return value % max;
  }

  @override
  bool nextBool() => nextInt(2) == 1;

  @override
  double nextDouble() => nextInt(100) / 100;
}

Future<(dynamic, OculumPerformanceProbe)> _sheet(
  WidgetTester tester, {
  required _FixedRoll natural,
  required _FixedRoll rescue,
  int base = 0,
  int superInspiration = 0,
  int oculum = 0,
  int fortune = 0,
  bool pactUsed = true,
}) async {
  final (state, probe) = await mountFight(tester);
  state.updateOculumHomeUi(() {
    state.paginaCorrente = 0;
    state.activeGameMod = '';
    state.temiOldSchool = false;
    state.nuovoDesignOculum = 'cattedrale';
    state.referenceSheetSection = 'general';
    state.datiCaricati = true;
    state.difficoltaTiroController.text = '100';
    state.ispirazioniController.text = '$base';
    state.superIspirazioniController.text = '$superInspiration';
    state.ispirazioniOculumController.text = '$oculum';
    state.fortuna = fortune;
    state.fatePactUsed = pactUsed;
    state.proponiFortunaDopoTiro = false;
    state.slotMachineRollsEnabled = false;
  });
  probe.setSheetRollRandom(natural: natural, rescue: rescue);
  await tester.pump();
  return (state, probe);
}

Future<void> _rollFromSheet(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('sheet_stat_roll_resilienza'));
  await tester.ensureVisible(button.first);
  await tester.tap(button.hitTestable().first);
  await tester.pump();
}

Finder _review() => find.byKey(const ValueKey('sheet_roll_review'));

Finder _action(String label) =>
    find.descendant(of: _review(), matching: find.text(label));

void main() {
  testWidgets('ordinary failure offers only the owned applicable resources', (
    tester,
  ) async {
    final (state, probe) = await _sheet(
      tester,
      natural: _FixedRoll(7),
      rescue: _FixedRoll(49),
      base: 1,
      oculum: 1,
      fortune: 3,
      pactUsed: false,
    );
    await _rollFromSheet(tester);
    expect(_action('Ispirazione'), findsWidgets);
    expect(_action('Ispirazione Oculum'), findsNothing);
    expect(_action('Super Ispirazione'), findsNothing);
    expect(_action('Patto del Fato'), findsWidgets);
    expect(_action('Fortuna magica +1'), findsWidgets);
    final fortuneButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Fortuna magica +1').first,
    );
    fortuneButton.onPressed!();
    await tester.pump();
    expect(state.fortuna, 2);
    expect(_action('Fortuna magica +1'), findsNothing);
    expect(_action('Ispirazione'), findsWidgets);
    final confirm = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Conferma tiro').first,
    );
    confirm.onPressed!();
    await tester.pump();
    expect(state.risultato, contains('Fortuna +1'));
    await closeFixture(tester, probe);
  });

  for (final percentile in [49, 50]) {
    testWidgets('Oculum resolves only once at percentile $percentile', (
      tester,
    ) async {
      final natural = _FixedRoll(0);
      final rescue = _FixedRoll(percentile);
      final (state, probe) = await _sheet(
        tester,
        natural: natural,
        rescue: rescue,
        base: 2,
        oculum: 2,
      );
      await _rollFromSheet(tester);
      expect(_action('Ispirazione'), findsNothing);
      final use = tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Ispirazione Oculum').first,
          )
          .onPressed!;
      use();
      use();
      await tester.pump();
      expect(state.ispirazioniOculumController.text, '1');
      expect(rescue.draws, 1);
      expect(natural.draws, 1);
      expect(_review(), findsNothing);
      expect(state.tiroCriticoVenti, percentile == 49);
      expect(state.tiroCriticoUno, percentile == 50);
      expect(
        state.risultato,
        contains(percentile == 49 ? 'Critico positivo' : 'Critico negativo'),
      );
      await closeFixture(tester, probe);
    });
  }

  testWidgets('a failed sheet roll resolves when resources are unavailable', (
    tester,
  ) async {
    final (state, probe) = await _sheet(
      tester,
      natural: _FixedRoll(0),
      rescue: _FixedRoll(49),
    );
    await _rollFromSheet(tester);
    expect(_review(), findsNothing);
    expect(state.tiroCriticoUno, isTrue);
    expect(state.ispirazioniOculumController.text, '0');
    await closeFixture(tester, probe);
  });

  testWidgets('switching sheets waits until the player confirms the roll', (
    tester,
  ) async {
    final (state, probe) = await _sheet(
      tester,
      natural: _FixedRoll(7),
      rescue: _FixedRoll(49),
      base: 1,
    );
    state.schedePersonaggio.add({
      ...probe.snapshot(),
      'id': 'OTHER-HERO',
      'sheetTag': 'OTHER-HERO',
      'nome': 'Altra scheda',
    });
    await _rollFromSheet(tester);

    final switcher = tester.widget<PopupMenuButton<int>>(
      find
          .byWidgetPredicate(
            (widget) =>
                widget is PopupMenuButton<int> &&
                widget.tooltip == 'Cambia scheda',
          )
          .first,
    );
    switcher.onSelected!(1);
    await tester.pump();
    expect(state.schedaCorrente, 0);
    expect(_review(), findsWidgets);

    tester
        .widget<TextButton>(
          find.widgetWithText(TextButton, 'Conferma tiro').first,
        )
        .onPressed!();
    await tester.pump();
    expect(_review(), findsNothing);
    switcher.onSelected!(1);
    await tester.pump();
    expect(state.schedaCorrente, 1);
    await closeFixture(tester, probe);
  });
}
