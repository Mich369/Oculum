const oculumLamaOrbitaId = 'lama_orbita';
const oculumLamaOrbitaGauntletId = 'guanto_d_arme_di_orbita';
const oculumLamaOrbitaElements = ['acqua', 'metallo', 'vento'];
const oculumLamaOrbitaMaximumAffinity = 300;
const oculumLamaOrbitaFumbleMaximumAffinity = 60;

int oculumLamaOrbitaStartingAffinity({
  required Iterable<String> ownedElements,
  required bool killedPreviousOwner,
}) {
  final hasMatch = ownedElements.any(
    (element) =>
        oculumLamaOrbitaElements.contains(element.trim().toLowerCase()),
  );
  return (hasMatch ? 10 : 0) - (killedPreviousOwner ? 5 : 0);
}

int oculumLamaOrbitaDamageBonus(int affinity) =>
    affinity > oculumLamaOrbitaMaximumAffinity
    ? oculumLamaOrbitaMaximumAffinity
    : affinity;

({double five, int three, int two}) oculumLamaOrbitaLoopChances(int affinity) {
  final positive = affinity.clamp(0, oculumLamaOrbitaMaximumAffinity);
  return (
    five: (positive / 2).clamp(0, 100),
    three: positive.clamp(0, 100),
    two: (positive * 2).clamp(0, 100),
  );
}

int oculumLamaOrbitaRollLoops(int affinity, int d100) {
  RangeError.checkValueInInterval(d100, 1, 100, 'd100');
  final chances = oculumLamaOrbitaLoopChances(affinity);
  if (d100 <= chances.five) return 5;
  final three = chances.five + chances.three;
  if (d100 <= three) return 3;
  if (d100 <= three + chances.two) return 2;
  return 1;
}

bool oculumLamaOrbitaFumblesReturn(int affinity, int natural) =>
    affinity <= oculumLamaOrbitaFumbleMaximumAffinity && natural == 1;

int oculumLamaOrbitaAffinityAfterHit(int affinity, int completedLoops) {
  if (completedLoops <= 0) return affinity;
  return oculumLamaOrbitaDamageBonus(affinity + completedLoops * 10);
}
