part of 'oculum_lite_run.dart';

enum LiteVampirePact {
  ferocia('Ferocia antica', '+60% ai Danni degli attacchi personali.'),
  passo('Passo predatore', '+45% alla velocità di camminata e corsa.'),
  fame(
    'Fame rossa',
    'Ogni nemico abbattuto personalmente cura il 12% della tua Vita massima.',
  );

  const LiteVampirePact(this.label, this.description);
  final String label;
  final String description;
}

String _vampirePactKey(String account) => 'patto-vampiro:' + account;

extension LiteVampireEncounter on LiteRun {
  static const price = .35;

  Point<double>? get vampirePosition {
    if (stage < 3 || usesSubArena || finished || !stageClear) return null;
    final rng = _LiteRandom(seed ^ (stage * 7297) ^ 0x18481)
      ..nextDouble()
      ..nextDouble();
    if (rng.nextInt(1000) >= 6) return null;
    return _safePoint(const Point(8.1, 17.4), .45, const Point(6, 19));
  }

  bool canSpeakToVampire([LiteCoopFighter? fighter]) {
    final at = vampirePosition;
    return at != null &&
        (fighter?.supply ?? supply).vampirePact == null &&
        (fighter?.hp ?? hp) > 0 &&
        (fighter?.position ?? position).distanceTo(at) < 2.35;
  }

  bool acceptVampirePact(LiteVampirePact choice, [LiteCoopFighter? fighter]) {
    if (!canSpeakToVampire(fighter)) return false;
    final kit = fighter?.supply ?? supply;
    final ratio = (fighter?.hp ?? hp) / (fighter?.maxHp ?? maxHp);
    kit.vampirePact = choice;
    if (fighter == null) {
      hp = max(1, maxHp * ratio);
      achievements.add(LiteRun.heroUnlockKey(LiteHero.vampiro));
    } else {
      fighter.hp = max(1, fighter.maxHp * ratio);
      achievements.add(_vampirePactKey(fighter.account));
    }
    message = 'Patto del Vampiro · ${choice.label}. Achievement sbloccato.';
    return true;
  }
}
