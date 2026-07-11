import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('Forza usa sempre meta della Volonta e resta serializzabile', () {
    expect(
      oculumHiddenEyeDerivedBonusFor(
        id: 'forza',
        resilienza: 99,
        volonta: 11,
        materia: 80,
        oculum: 70,
        karma: 60,
      ),
      5,
    );
    expect(
      oculumHiddenEyeDerivedBonusFor(
        id: 'forza',
        resilienza: 0,
        volonta: 12,
        materia: 0,
        oculum: 0,
        karma: 0,
      ),
      6,
    );

    final restored = HiddenEyeStat.fromJson(
      HiddenEyeStat(
        id: 'forza',
        nome: 'Forza',
        descrizione: 'Bonus base: Volonta/2.',
        valore: 3,
        masteryProgress: 17,
      ).toJson(),
    );
    expect(restored.id, 'forza');
    expect(restored.valore, 3);
    expect(restored.masteryProgress, 17);
  });

  test('calcola soglia e guadagno maestria dei sottotratti Oculus', () {
    expect(oculusSubtraitMasteryTargetForGrade(0), 36);
    expect(oculusSubtraitMasteryTargetForGrade(1), 63);
    expect(oculusSubtraitMasteryTargetForGrade(2), 69);
    expect(oculusSubtraitMasteryTargetForGrade(3), 96);
    expect(oculusSubtraitMasteryTargetForGrade(4), 100);
    expect(oculusSubtraitMasteryTargetForGrade(5), 150);
    expect(oculusSubtraitMasteryTargetForGrade(6), 160);
    expect(oculusSubtraitMasteryTargetForGrade(7), 369);
    expect(oculusSubtraitMasteryTargetForGrade(8), 500);
    expect(oculusSubtraitMasteryTargetForGrade(9), 693);
    expect(oculusSubtraitMasteryTargetForGrade(10), 963);
    expect(oculusSubtraitMasteryTargetForGrade(11), 1000);
    expect(oculusSubtraitMasteryTargetForGrade(99), 1000);
    expect(oculusSubtraitMasteryTargetForGrade(-1), 36);

    expect(oculusSubtraitMasteryGainForDie(14), 0);
    expect(oculusSubtraitMasteryGainForDie(15), 15);
    expect(oculusSubtraitMasteryGainForDie(19), 19);
    expect(oculusSubtraitMasteryGainForDie(20), 60);
  });

  test('mantiene avanzo quando la barra maestria si completa', () {
    final stat = HiddenEyeStat(
      id: 'velo',
      nome: 'Velo',
      descrizione: 'Test',
      valore: 0,
      masteryProgress: 30,
    );

    final completed = oculusSubtraitMasteryApplyGain(stat, 60);

    expect(completed, 1);
    expect(stat.valore, 1);
    expect(stat.masteryProgress, 54);
    expect(
      oculusSubtraitMasteryFraction(
        progress: stat.masteryProgress,
        grade: stat.valore,
      ),
      closeTo(54 / 63, 0.0001),
    );
  });

  test('salva il progresso maestria senza perdere il sottotratto', () {
    final stat = HiddenEyeStat(
      id: 'velo',
      nome: 'Velo',
      descrizione: 'Test',
      valore: 2,
      masteryProgress: 600,
    );

    final restored = HiddenEyeStat.fromJson(stat.toJson());

    expect(restored.id, 'velo');
    expect(restored.valore, 2);
    expect(restored.masteryProgress, 600);
    expect(
      oculusSubtraitMasteryFraction(progress: 18, grade: 0),
      closeTo(0.5, 0.0001),
    );
  });

  test('carica il vecchio campo maestria dei salvataggi legacy', () {
    final restored = HiddenEyeStat.fromJson({
      'id': 'velo',
      'nome': 'Velo',
      'descrizione': 'Test',
      'valore': 3,
      'unlocked': true,
      'maestria': 42,
    });

    expect(restored.id, 'velo');
    expect(restored.valore, 3);
    expect(restored.masteryProgress, 42);
    expect(restored.toJson()['oculusSubtraitMasteryProgress'], 42);
  });

  test('non serializza cache o stato UI volatile nei sottotratti', () {
    final stat = HiddenEyeStat(
      id: 'velo',
      nome: 'Velo',
      descrizione: 'Test',
      valore: 4,
      masteryProgress: 99,
    );

    final json = stat.toJson();

    expect(
      json.keys,
      containsAll(<String>[
        'id',
        'nome',
        'descrizione',
        'valore',
        'unlocked',
        'oculusSubtraitMasteryProgress',
      ]),
    );
    expect(
      json.keys.any((key) => key.toLowerCase().contains('cache')),
      isFalse,
    );
    expect(
      json.keys.any((key) => key.toLowerCase().contains('revision')),
      isFalse,
    );
  });

  test('gestisce guadagni rapidi ripetuti senza perdere avanzo', () {
    final stat = HiddenEyeStat(
      id: 'velo',
      nome: 'Velo',
      descrizione: 'Test',
      valore: 0,
    );

    var completed = 0;
    for (var i = 0; i < 40; i++) {
      completed += oculusSubtraitMasteryApplyGain(stat, 60);
      final target = oculusSubtraitMasteryTargetForValue(stat.valore);
      expect(stat.masteryProgress, inInclusiveRange(0, target - 1));
    }

    expect(completed, greaterThan(1));
    expect(stat.valore, completed);
  });

  test('accoda gli effetti remoti senza perdere eventi', () async {
    final queue = OculumActionQueue();
    final firstGate = Completer<void>();
    final started = <int>[];

    final first = queue.enqueue('dice', () async {
      started.add(1);
      await firstGate.future;
    });
    final second = queue.enqueue('dice', () async {
      started.add(2);
    });

    await Future<void>.delayed(Duration.zero);
    expect(started, <int>[1]);

    firstGate.complete();
    await Future.wait(<Future<void>>[first, second]);
    expect(started, <int>[1, 2]);
  });
}
