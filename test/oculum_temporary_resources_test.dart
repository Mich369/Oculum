import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:oculum/main.dart';

void main() {
  group('Oculum temporaneo per difficolta', () {
    test('i limiti extra sono 6, 5, 3 e 3', () {
      expect(getTemporaryOculumLimitForDifficulty('facile'), 6);
      expect(getTemporaryOculumLimitForDifficulty('normale'), 5);
      expect(getTemporaryOculumLimitForDifficulty('difficile'), 3);
      expect(getTemporaryOculumLimitForDifficulty('oculum'), 3);
    });

    test('le durate rispettano tutti gli intervalli richiesti', () {
      expect(temporaryOculumDurationForDieRoll('facile', 1), 4);
      expect(temporaryOculumDurationForDieRoll('facile', 9), 12);
      expect(temporaryOculumDurationForDieRoll('normale', 1), 4);
      expect(temporaryOculumDurationForDieRoll('normale', 9), 12);
      expect(temporaryOculumDurationForDieRoll('difficile', 1), 4);
      expect(temporaryOculumDurationForDieRoll('difficile', 6), 9);
      expect(temporaryOculumDurationForDieRoll('oculum', 1), 1);
      expect(temporaryOculumDurationForDieRoll('oculum', 6), 6);
    });

    test('riempie prima il normale e limita il temporaneo', () {
      final easy = addOculumToTemporaryState(
        state: const TemporaryOculumState(
          normalCurrent: 8,
          temporary: 0,
          rollsRemaining: 0,
        ),
        normalMaximum: 10,
        amount: 20,
        difficulty: 'facile',
        rollDie: (_) => 5,
      );
      final normal = addOculumToTemporaryState(
        state: const TemporaryOculumState(
          normalCurrent: 10,
          temporary: 0,
          rollsRemaining: 0,
        ),
        normalMaximum: 10,
        amount: 20,
        difficulty: 'normale',
        rollDie: (_) => 5,
      );

      expect(easy.normalCurrent, 10);
      expect(easy.temporary, 6);
      expect(easy.total, 16);
      expect(normal.temporary, 5);
      expect(normal.total, 15);
    });

    test('un nuovo guadagno non riduce la durata residua maggiore', () {
      final state = addOculumToTemporaryState(
        state: const TemporaryOculumState(
          normalCurrent: 10,
          temporary: 1,
          rollsRemaining: 7,
        ),
        normalMaximum: 10,
        amount: 1,
        difficulty: 'facile',
        rollDie: (_) => 2,
      );
      expect(state.temporary, 2);
      expect(state.rollsRemaining, 7);
    });

    test(
      'un tiro valido riduce di uno e la scadenza rimuove solo il temporaneo',
      () {
        const active = TemporaryOculumState(
          normalCurrent: 7,
          temporary: 3,
          rollsRemaining: 2,
        );
        final afterOne = registerValidTemporaryOculumRoll(active);
        final expired = registerValidTemporaryOculumRoll(afterOne);

        expect(afterOne.rollsRemaining, 1);
        expect(afterOne.temporary, 3);
        expect(expired.rollsRemaining, 0);
        expect(expired.temporary, 0);
        expect(expired.normalCurrent, 7);
        expect(expired.total, 7);
      },
    );

    test('azioni non registrate come tiro non cambiano lo stato', () {
      const state = TemporaryOculumState(
        normalCurrent: 10,
        temporary: 2,
        rollsRemaining: 6,
      );
      final afterDifficultyCheck = handleTemporaryOculumDifficultyChange(
        state: state,
        difficulty: 'facile',
      );
      expect(afterDifficultyCheck.rollsRemaining, 6);
    });

    test('il cambio difficolta limita senza regalare Oculum', () {
      const easy = TemporaryOculumState(
        normalCurrent: 10,
        temporary: 6,
        rollsRemaining: 8,
      );
      final hard = handleTemporaryOculumDifficultyChange(
        state: easy,
        difficulty: 'difficile',
      );
      final easyAgain = handleTemporaryOculumDifficultyChange(
        state: hard,
        difficulty: 'facile',
      );

      expect(hard.temporary, 3);
      expect(hard.rollsRemaining, 8);
      expect(easyAgain.temporary, 3);
      expect(easyAgain.total, 13);
    });

    test('il valore visibile contiene solo il totale Oculum', () {
      const state = TemporaryOculumState(
        normalCurrent: 10,
        temporary: 3,
        rollsRemaining: 9,
      );
      expect(state.visibleValue, '13');
      expect(state.visibleValue, isNot(contains('9')));
    });

    test('la scrittura manuale Oculum imposta il valore esatto', () {
      const state = TemporaryOculumState(
        normalCurrent: 5,
        temporary: 3,
        rollsRemaining: 6,
      );

      final lowered = setTemporaryOculumFromManualVisibleValue(
        state: state,
        visibleValue: 6,
      );
      final raised = setTemporaryOculumFromManualVisibleValue(
        state: state,
        visibleValue: 15,
      );

      expect(lowered.total, 6);
      expect(lowered.normalCurrent, 5);
      expect(lowered.temporary, 1);
      expect(lowered.rollsRemaining, 6);
      expect(raised.total, 15);
      expect(raised.normalCurrent, 12);
      expect(raised.temporary, 3);
    });

    test('la scrittura manuale separa i bonus dal valore salvato', () {
      const state = TemporaryOculumState(
        normalCurrent: 4,
        temporary: 2,
        rollsRemaining: 5,
      );
      final next = setTemporaryOculumFromManualVisibleValue(
        state: state,
        visibleValue: 9,
        visibleBonus: 5,
        minimumNormalCurrent: -5,
      );

      expect(next.total + 5, 9);
      expect(next.normalCurrent, 4);
      expect(next.temporary, 0);
      expect(next.rollsRemaining, 0);
    });

    test('i vecchi salvataggi ricevono temporaneo e durata a zero', () {
      final restored = temporaryOculumStateFromJson(
        json: <String, dynamic>{'currentOculum': '8'},
        normalMaximum: 10,
        difficulty: 'normale',
      );
      expect(restored.normalCurrent, 8);
      expect(restored.temporary, 0);
      expect(restored.rollsRemaining, 0);
    });

    test('i bonus Oculum da testo non sostituiscono l Oculum attuale', () {
      final spent = spendOculumFromTemporaryState(
        state: const TemporaryOculumState(
          normalCurrent: 0,
          temporary: 0,
          rollsRemaining: 0,
        ),
        amount: 5,
        minimumNormalCurrent: 0,
      );

      expect(spent.normalCurrent, 0);
      expect(spent.temporary, 0);
    });

    test(
      'il reset elimina il temporaneo e lascia spendibile il massimo normale',
      () {
        final reset = resetTemporaryOculumState(normalMaximum: 10);
        final afterSkill = spendOculumFromTemporaryState(
          state: reset,
          amount: 3,
        );

        expect(reset.normalCurrent, 10);
        expect(reset.temporary, 0);
        expect(reset.rollsRemaining, 0);
        expect(afterSkill.total, 7);
        expect(afterSkill.temporary, 0);
      },
    );

    test('Oculum addormentato non rende utilizzabili i buff runtime', () {
      expect(
        oculumVisibleTotal(
          storedCurrent: -14,
          runtimeBonus: 38,
          sleeping: true,
        ),
        0,
      );
      expect(
        oculumVisibleTotal(
          storedCurrent: -14,
          runtimeBonus: 38,
          sleeping: false,
        ),
        24,
      );
    });

    test(
      'il risveglio non fa riapparire il bonus presente prima del sonno',
      () {
        const runtimeBonus = 38;

        // Sleeping stores the negative counterpart of an active runtime bonus.
        // Once the condition is lifted, the visible pool therefore remains zero
        // until it is recovered normally.
        expect(
          oculumVisibleTotal(
            storedCurrent: -runtimeBonus,
            runtimeBonus: runtimeBonus,
            sleeping: false,
          ),
          0,
        );

        final calculations = File(
          'lib/src/main/oculum_home_calculations.dart',
        ).readAsStringSync();
        final sleepStart = calculations.indexOf(
          'void attivaStatoOculumAddormentato()',
        );
        final sleepEnd = calculations.indexOf(
          'void risvegliaStatoOculumAddormentato()',
          sleepStart,
        );
        final sleepSource = calculations.substring(sleepStart, sleepEnd);
        expect(
          sleepSource,
          contains('normalCurrent: currentOculumRuntimeFloor()'),
        );
      },
    );

    test('un costo usa l Oculum visibile anche se il controller e zero', () {
      const runtimeBonus = 5;
      final afterCost = spendOculumFromTemporaryState(
        state: const TemporaryOculumState(
          normalCurrent: 0,
          temporary: 0,
          rollsRemaining: 0,
        ),
        amount: 1,
        minimumNormalCurrent: -runtimeBonus,
      );

      expect(
        oculumVisibleTotal(
          storedCurrent: afterCost.total,
          runtimeBonus: runtimeBonus,
          sleeping: false,
        ),
        4,
      );

      final calculations = File(
        'lib/src/main/oculum_home_calculations.dart',
      ).readAsStringSync();
      expect(calculations, contains('final before = oculumTotale();'));
      expect(
        calculations,
        contains('minimumNormalCurrent: currentOculumRuntimeFloor(),'),
      );
      expect(calculations, contains("return currentStatValue('oculum');"));
    });

    test('il pannello Oculum impone zero esplicito mentre dorme', () {
      final sheetPage = File(
        'lib/src/main/oculum_home_sheet_page.dart',
      ).readAsStringSync();

      expect(
        sheetPage,
        contains('final current = sleeping ? 0 : oculumTotale();'),
      );
      expect(
        sheetPage,
        contains('final ratio = sleeping ? 0.0 : oculumRatio();'),
      );
      expect(
        sheetPage,
        contains(
          'final normalCurrent = sleeping ? 0 : max(0, normalCurrentOculum());',
        ),
      );
      expect(sheetPage, contains('Oculum dormiente 0/\$massimo'));
    });

    test('un guadagno ripristina prima il bonus testuale consumato', () {
      final restored = addOculumToTemporaryState(
        state: const TemporaryOculumState(
          normalCurrent: -5,
          temporary: 0,
          rollsRemaining: 0,
        ),
        normalMaximum: 10,
        amount: 3,
        difficulty: 'normale',
        rollDie: (_) => 1,
        minimumNormalCurrent: -5,
      );

      expect(restored.normalCurrent, -2);
      expect(restored.normalCurrent + 5, 3);
      expect(restored.temporary, 0);
    });

    test('il salvataggio conserva il bonus testuale gia consumato', () {
      final restored = temporaryOculumStateFromJson(
        json: <String, dynamic>{
          'currentOculum': '-5',
          'normalCurrentOculum': -5,
          'temporaryOculum': 0,
        },
        normalMaximum: 10,
        difficulty: 'normale',
        minimumNormalCurrent: -5,
      );

      expect(restored.normalCurrent, -5);
      expect(restored.total + 5, 0);
    });

    test('il controller conserva il debito runtime senza bloccarlo a zero', () {
      final source = File(
        'lib/src/main/oculum_home_calculations.dart',
      ).readAsStringSync();

      expect(
        source,
        contains('currentOculumController.text = state.total.toString();'),
      );
      expect(
        source,
        isNot(
          contains(
            'currentOculumController.text = max(0, state.total).toString();',
          ),
        ),
      );
      expect(
        source,
        contains('return min(oculumTiroLimiteRegola(), oculumTotale());'),
      );
    });

    test(
      'togliere Oculum addormentato conserva attuale temporaneo e massimo',
      () {
        final calculations = File(
          'lib/src/main/oculum_home_calculations.dart',
        ).readAsStringSync();
        final wakeStart = calculations.indexOf(
          'void risvegliaStatoOculumAddormentato()',
        );
        final wakeEnd = calculations.indexOf(
          'bool registraRiposoOculumAddormentato',
          wakeStart,
        );
        final wakeSource = calculations.substring(wakeStart, wakeEnd);

        expect(wakeSource, contains('oculumAddormentato = false;'));
        expect(wakeSource, isNot(contains('applyTemporaryOculumState')));
        expect(wakeSource, isNot(contains('currentOculumController')));
        expect(wakeSource, isNot(contains('maxOculum')));

        final sheetPage = File(
          'lib/src/main/oculum_home_sheet_page.dart',
        ).readAsStringSync();
        expect(sheetPage, isNot(contains('Risveglia e azzera')));
        expect(sheetPage, isNot(contains('Wake and clear')));
        expect(
          sheetPage,
          contains(
            'I valori attuali, temporanei e massimi resteranno invariati.',
          ),
        );
        expect(sheetPage, contains('controller: oculumPanelCurrentController'));
        expect(sheetPage, contains('focusNode: oculumPanelCurrentFocusNode'));
      },
    );
  });

  group('HP temporanei', () {
    test('la cura riempie gli HP e converte il resto fino a 20', () {
      final healed = healOculumHp(
        current: 80,
        maximum: 100,
        temporary: 0,
        amount: 50,
      );
      expect(healed.current, 100);
      expect(healed.temporary, 20);
    });

    test('il danno consuma prima gli HP temporanei', () {
      final damaged = damageOculumHp(current: 100, temporary: 20, amount: 25);
      expect(damaged.temporary, 0);
      expect(damaged.current, 95);
    });
  });

  test(
    'la coda salvataggi fonde richieste e non scrive in parallelo',
    () async {
      final queue = OculumSaveRequestQueue();
      var active = 0;
      var maxActive = 0;
      var writes = 0;

      Future<void> write(bool _) async {
        active++;
        maxActive = active > maxActive ? active : maxActive;
        writes++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        active--;
      }

      final first = queue.enqueue(soloLocal: true, write: write);
      final second = queue.enqueue(soloLocal: false, write: write);
      final third = queue.enqueue(soloLocal: true, write: write);
      await Future.wait(<Future<void>>[first, second, third]);

      expect(maxActive, 1);
      expect(writes, 2);
      expect(queue.isRunning, isFalse);
    },
  );
}
