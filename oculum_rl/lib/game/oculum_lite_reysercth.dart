part of 'oculum_lite_run.dart';

enum LiteReysercthMod {
  rinforzo('Rinforzo'),
  propulsore('Rinforzo con propulsore');

  const LiteReysercthMod(this.label);
  final String label;
  static const vitality = 1.08;
  static const power = 1.08;
  static const push = 3.0;
}

extension LiteReysercthEncounter on LiteRun {
  Point<double>? get reysercthPosition =>
      usesExplorableFloor && biome == LiteBiome.postea && !finished
      ? LiteFloorExploration._encounterPoint
      : null;

  bool canSpeakToReysercth([LiteCoopFighter? fighter]) {
    final station = reysercthPosition;
    return station != null &&
        (fighter == null || fighter.connected) &&
        (fighter?.hp ?? hp) > 0 &&
        (fighter?.supply ?? supply).reysercthMod == null &&
        (fighter?.position ?? position).distanceTo(station) < 1.65;
  }

  bool acceptReysercthMod(LiteReysercthMod choice, [LiteCoopFighter? fighter]) {
    if (!canSpeakToReysercth(fighter)) return false;
    final ratio = (fighter?.hp ?? hp) / (fighter?.maxHp ?? maxHp);
    (fighter?.supply ?? supply).reysercthMod = choice;
    if (fighter == null) {
      hp = max(1, maxHp * ratio);
    } else {
      fighter.hp = max(1, fighter.maxHp * ratio);
    }
    message = 'Reysercth · ${choice.label} installato.';
    return true;
  }
}
