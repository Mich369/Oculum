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
