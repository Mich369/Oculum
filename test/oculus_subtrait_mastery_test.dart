import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
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
}
