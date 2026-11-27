part of 'oculum_lite_arena.dart';

double? _reactionAge(LiteCombatImpact impact, double time) {
  if (impact.intangible) return null;
  final duration = impact.life > 0
      ? .34
      : impact.shield > 0
      ? .21
      : 0.0;
  final age = time - impact.time;
  return age >= 0 && age < duration ? age / duration : null;
}

double? _playedAttackElapsed(LiteWeapon weapon, double windup, double? age) {
  if (age != null) return weapon.chargeSeconds + age;
  if (windup > 0) {
    return (weapon.chargeSeconds - windup).clamp(0.0, weapon.chargeSeconds);
  }
  return null;
}

void _applyPlayablePose(
  Canvas canvas,
  LiteHero hero,
  LiteWeapon weapon,
  double time,
  LiteStride stride, {
  required bool down,
  required bool phasing,
  required bool blocking,
  required LiteCombatImpact? impact,
  required LiteRescueStatus? rescue,
  required double? riseAge,
  required double openAge,
  required double? releaseAge,
  required double windup,
  required bool compact,
  bool bladeReturn = false,
}) {
  if (down || phasing) return;
  // Keep the dominant foot at the arena anchor. Slime, birds and heavy
  // silhouettes compress differently from a duellist or caster.
  final (weight, lean, breath) = switch (hero) {
    LiteHero.slimeBlu => (.53, .24, .026),
    LiteHero.pollo ||
    LiteHero.polloMeccanico ||
    LiteHero.raganella => (.73, .70, .023),
    LiteHero.pipistrello ||
    LiteHero.veyrth ||
    LiteHero.aerovyr => (.80, .39, .024),
    LiteHero.guardianoSolare ||
    LiteHero.aberrazioneSolare ||
    LiteHero.babyForestDemon ||
    LiteHero.granScostumato ||
    LiteHero.sentinella ||
    LiteHero.lithra => (1.28, .51, .011),
    LiteHero.ombra ||
    LiteHero.doppelganger ||
    LiteHero.vampiro ||
    LiteHero.vesanybel => (.87, 1.20, .015),
    LiteHero.pyrel ||
    LiteHero.luce ||
    LiteHero.vedettaEiva ||
    LiteHero.diavolo => (.93, .91, .014),
    _ => (1.0, .85, .012),
  };

  final reaction = impact == null ? null : _reactionAge(impact, time);
  if (impact != null && reaction != null) {
    final phase = reaction;
    final guard = impact.life <= 0;
    final recoil = math.pow(1 - phase, 2).toDouble();
    final vibration = math.sin(phase * math.pi * 2) * (1 - phase);
    canvas.translate((guard ? -.05 : -.19) * recoil / weight, 0);
    canvas.rotate((guard ? -.047 : -.18) * recoil * lean);
    canvas.scale(1 + .042 * recoil, 1 - (guard ? .033 : .10) * recoil);
    canvas.skew(vibration * (guard ? .017 : .034), 0);
  } else if (riseAge != null) {
    final lift = 1 - _inkEase(riseAge / .42);
    canvas.rotate(.95 * lift);
    canvas.scale(1 - .10 * lift, 1 - .28 * lift);
  } else if (rescue != null) {
    final reach = 1 - math.pow(1 - rescue.progress, 2).toDouble();
    canvas.rotate((.145 + reach * .06) * lean);
    canvas.scale(1 + reach * .04, rescue.paused ? .87 : .79 - reach * .045);
  } else if (blocking) {
    canvas.rotate(.097 * lean);
    canvas.scale(1.025, .93);
  } else if (!compact && openAge >= 0 && openAge < .52) {
    final surge = math.sin(openAge * math.pi / .52);
    final bend = switch (hero) {
      LiteHero.pyrel || LiteHero.luce || LiteHero.vedettaEiva => -.15,
      LiteHero.lithra || LiteHero.guardianoSolare || LiteHero.reGoblin => .19,
      LiteHero.ombra || LiteHero.doppelganger => -.105,
      LiteHero.slimeBlu => .02,
      _ => .08,
    };
    canvas.rotate(bend * surge * lean);
    canvas.scale(1 + .045 * surge, 1 - (.06 + bend * .24) * surge);
  } else if (!compact && windup > 0 && weapon.chargeSeconds > 0) {
    final flex = _inkEase((1 - windup / weapon.chargeSeconds).clamp(0.0, 1.0));
    canvas.rotate(-.085 * flex * lean);
    canvas.scale(1 + .031 * flex, 1 - .063 * flex);
  } else if (releaseAge != null && !compact) {
    final kick =
        (1 - releaseAge / .28).clamp(0.0, 1.0) *
        (1 + .22 * math.sin(releaseAge * math.pi / .095));
    final direction = switch (weapon) {
      LiteWeapon.carabinaImpulsi ||
      LiteWeapon.balestraRunica ||
      LiteWeapon.fucileScostubandito => -1.0,
      LiteWeapon.doppieLame when bladeReturn => -.45,
      _ => 1.0,
    };
    canvas.rotate(direction * .12 * kick * lean);
    canvas.scale(1 + .035 * kick, 1 - .042 * kick / weight);
  } else if (stride.speed < .08 && !compact) {
    final cycle = math.sin(time * 3.3 + hero.index * .61) * breath;
    canvas.scale(1 - cycle * .65, 1 + cycle);
  }
}
