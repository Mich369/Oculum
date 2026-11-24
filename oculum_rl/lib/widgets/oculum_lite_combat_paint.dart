part of 'oculum_lite_arena.dart';

void _paintBlockGuard(Canvas canvas, Offset feet, double resistance) {
  final at = feet - const Offset(0, .68);
  final outline = Rect.fromCenter(center: at, width: 1.52, height: 1.82);
  const ink = Color(0xff9dd7ed);
  canvas.drawOval(outline, Paint()..color = ink.withValues(alpha: .09));
  canvas.drawArc(
    outline,
    -math.pi / 2,
    math.pi * 2 * resistance,
    false,
    Paint()
      ..color = ink.withValues(alpha: .82)
      ..strokeWidth = .061
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke,
  );
}

void _paintOpenPulse(
  Canvas canvas,
  Offset feet,
  LiteHero hero,
  double cooldown,
  int grade,
) {
  final age = LiteRun.openRecoveryFor(grade) - cooldown;
  if (age < 0 || age >= .62) return;
  final phase = age / .62;
  final color = switch (hero) {
    LiteHero.evasore => const Color(0xff76dfc8),
    LiteHero.duplicatore => _violet,
    LiteHero.ashley => _ember,
    LiteHero.scostubandito => _sand,
    LiteHero.granScostumato || LiteHero.sentinella => _sand,
    LiteHero.dronePostea => const Color(0xff7dddf2),
    LiteHero.babyForestDemon ||
    LiteHero.curatorePeste ||
    LiteHero.lithra => _active,
    LiteHero.pyrel || LiteHero.vampiro || LiteHero.reGoblin => _ember,
    LiteHero.cavaliereLunare => const Color(0xffc0b5f0),
    LiteHero.slimeBlu => const Color(0xff8dd4fb),
    LiteHero.luce => const Color(0xffffdda6),
    LiteHero.ombra || LiteHero.veyrth || LiteHero.doppelganger => _violet,
  };
  _oval(
    canvas,
    feet,
    .68 + phase * 1.9,
    .32 + phase * .65,
    color.withValues(alpha: (1 - phase) * .13),
    stroke: color.withValues(alpha: (1 - phase) * .88),
    strokeWidth: .067,
  );
}

Color _weaponInk(LiteWeapon weapon) => switch (weapon) {
  LiteWeapon.arco => const Color(0xffe6bf81),
  LiteWeapon.spadaScudo => const Color(0xffe6d4b3),
  LiteWeapon.guanti => const Color(0xfff2a364),
  LiteWeapon.scettro => const Color(0xffc49aff),
  LiteWeapon.boomerang => const Color(0xffd3ae7a),
  LiteWeapon.falceRunica => const Color(0xff76dec5),
  LiteWeapon.doppieLame => const Color(0xffa9e3c8),
  LiteWeapon.carabinaImpulsi => const Color(0xff87deff),
  LiteWeapon.piccaOssidiana => const Color(0xffc4a2d5),
  LiteWeapon.balestraRunica => const Color(0xffa9e7ef),
  LiteWeapon.fucileScostubandito => const Color(0xffdfae68),
};

void _paintAttackInk(
  Canvas canvas,
  Offset feet,
  Offset aim,
  LiteWeapon weapon,
  double cooldown, {
  required bool preparing,
  required bool spring,
  bool guest = false,
}) {
  if (cooldown <= 0 && !spring) return;
  if (aim.distanceSquared < .001) return;
  final forward = aim / aim.distance;
  final perpendicular = Offset(-forward.dy, forward.dx);
  final pigment = _weaponInk(spring ? LiteWeapon.guanti : weapon);
  final raised = feet - const Offset(0, .81);
  final elapsed = (weapon.cooldown - cooldown).clamp(0.0, weapon.cooldown);
  final chargeTime = weapon.chargeSeconds;
  if (preparing && chargeTime > 0 && !spring) {
    final charged = (elapsed / chargeTime).clamp(0.0, 1.0);
    final at = raised + forward * (.48 + charged * .32);
    for (var i = -1; i <= 1; i++) {
      final side = perpendicular * (i * (.30 - charged * .16));
      _inkSlash(
        canvas,
        at - forward * (.52 + charged * .23) + side,
        at + side * .35,
        pigment,
        .034 + charged * .028,
      );
    }
    _oval(
      canvas,
      at,
      .12 + charged * .27,
      .08 + charged * .16,
      pigment.withValues(alpha: .38 + charged * .60),
      stroke: _ink,
      strokeWidth: .045,
    );
    return;
  }

  final age = spring ? cooldown : math.max(0.0, elapsed - chargeTime);
  final sweep = switch (weapon) {
    LiteWeapon.spadaScudo ||
    LiteWeapon.doppieLame ||
    LiteWeapon.falceRunica => true,
    _ => false,
  };
  if (sweep && !spring) {
    if (weapon == LiteWeapon.doppieLame) {
      _bladeRibbon(canvas, raised, forward, 1.35, age, pigment, -1);
      if (guest || age >= .11) {
        _bladeRibbon(
          canvas,
          raised + forward * .20,
          forward,
          1.28,
          guest ? age : age - .11,
          pigment,
          1,
        );
      }
    } else {
      _bladeRibbon(
        canvas,
        raised,
        forward,
        weapon == LiteWeapon.falceRunica ? 2.06 : 1.76,
        age,
        pigment,
        1,
      );
    }
    return;
  }

  final phase = age / (spring ? .28 : .20);
  if (phase >= 1) return;
  final opacity = (1 - phase).clamp(0.0, 1.0);
  final leverage = switch (weapon) {
    LiteWeapon.carabinaImpulsi => 1.72,
    LiteWeapon.balestraRunica => 1.35,
    LiteWeapon.piccaOssidiana => 2.35,
    LiteWeapon.guanti => 1.33,
    LiteWeapon.boomerang => .98,
    _ => 1.14,
  };
  final tip = raised + forward * (spring ? 1.50 + phase * 1.55 : leverage);
  for (var i = -1; i <= 1; i++) {
    final spread = perpendicular * (i * (.15 + phase * .14));
    final shard = tip + forward * (.37 + phase * .38) + spread;
    _inkSlash(
      canvas,
      tip - forward * (spring ? .63 : .20) + spread * .30,
      shard,
      pigment.withValues(alpha: opacity * .88),
      .057 * opacity,
    );
  }
  if (phase < .56) {
    _oval(
      canvas,
      tip,
      .24 + phase * .45,
      .19 + phase * .18,
      pigment.withValues(alpha: .58 * opacity),
      stroke: _ink,
      strokeWidth: .043,
    );
  }
}

void _bladeRibbon(
  Canvas canvas,
  Offset origin,
  Offset forward,
  double reach,
  double age,
  Color color,
  double sign,
) {
  final phase = age / .23;
  if (phase >= 1) return;
  final fade = (1 - phase) * (1 - phase);
  final direction = math.atan2(forward.dy, forward.dx);
  final turn = direction + sign * (phase * .57 - .21);
  final points = <Offset>[];
  for (var index = 0; index <= 8; index++) {
    final a = turn + sign * (-1.04 + index * .24);
    points.add(
      origin + Offset(math.cos(a), math.sin(a) * .73) * (reach + phase * .23),
    );
  }
  for (var index = 8; index >= 0; index--) {
    final a = turn + sign * (-1.04 + index * .24);
    final depth = math.sin(index * math.pi / 8) * (.31 - phase * .20);
    points.add(
      origin +
          Offset(math.cos(a), math.sin(a) * .73) *
              (reach + phase * .23 - depth),
    );
  }
  _poly(
    canvas,
    points,
    color.withValues(alpha: .83 * fade),
    stroke: _ink.withValues(alpha: .80 * fade),
    width: .065,
  );
  for (var index = 1; index < 8; index += 2) {
    _inkSlash(
      canvas,
      points[index],
      points[index + 1] + forward * (phase * .18),
      color.withValues(alpha: fade),
      .021,
    );
  }
}

void _inkSlash(
  Canvas canvas,
  Offset start,
  Offset tip,
  Color pigment,
  double width,
) {
  final delta = tip - start;
  final side = delta.distanceSquared > .0001
      ? Offset(-delta.dy, delta.dx) / delta.distance * width
      : Offset.zero;
  _poly(canvas, [
    start,
    start + delta * .33 + side,
    tip,
    start + delta * .66 - side * .57,
  ], pigment);
}

void _paintDodgeInk(
  Canvas canvas,
  Offset feet,
  Offset direction,
  double remaining,
) {
  if (remaining <= 0 || direction.distanceSquared < .001) return;
  final axis = direction / direction.distance;
  final normal = Offset(-axis.dy, axis.dx);
  final intensity = (remaining / .21).clamp(0.0, 1.0);
  for (var i = 0; i < 6; i++) {
    final at =
        feet + normal * ((i - 2.5) * .11) - Offset(0, .15 + (i % 3) * .20);
    final length = .59 + ((i * 3) % 5) * .16;
    _inkSlash(
      canvas,
      at - axis * (length * (1.55 - intensity)),
      at,
      (i.isEven ? const Color(0xffbeb0df) : _ink).withValues(
        alpha: .64 * intensity,
      ),
      .035 + intensity * .039,
    );
  }
}

void _paintHitInk(
  Canvas canvas,
  Offset feet,
  LiteCombatImpact impact,
  double age,
) {
  final phase = (age / .39).clamp(0.0, 1.0);
  if (phase == 1) return;
  final fade = (1 - phase) * (1 - phase);
  final height = impact.enemyKind == null
      ? 1.16
      : _enemyHeight(impact.enemyKind!) * _enemyScale(impact.enemyKind!) * .64;
  final at = feet - Offset(0, height);
  if (impact.intangible) {
    _inkSlash(
      canvas,
      at + Offset(-.65 - phase * .59, .22),
      at + const Offset(-.14, -.04),
      const Color(0xffc19af4).withValues(alpha: fade),
      .063,
    );
    _inkSlash(
      canvas,
      at + Offset(.72 + phase * .65, -.27),
      at + const Offset(.11, .03),
      const Color(0xffc19af4).withValues(alpha: fade),
      .063,
    );
    return;
  }
  if (impact.life > 0) {
    for (var i = -1; i <= 1; i++) {
      final diagonal = i == 0 ? .65 : .38;
      final center = at + Offset(i * .18, i * .20);
      final travel = Offset(diagonal * (1 + phase * .48), -diagonal * .51);
      _inkSlash(
        canvas,
        center - travel,
        center + travel,
        const Color(0xff2c131a).withValues(alpha: .93 * fade),
        .093,
      );
      _inkSlash(
        canvas,
        center - travel * .83,
        center + travel * .91,
        const Color(0xffd55761).withValues(alpha: .91 * fade),
        .046,
      );
    }
    for (final sign in [-1.0, 1.0]) {
      final drift =
          at + Offset(sign * (.30 + phase * .77), .16 + phase * phase * .66);
      _inkSlash(
        canvas,
        drift,
        drift + Offset(sign * .12, .03 + phase * .20),
        const Color(0xffa73950).withValues(alpha: fade),
        .045,
      );
    }
  }
  if (impact.shield <= 0) return;
  for (var i = 0; i < 7; i++) {
    final a = i * math.pi * 2 / 7 + .14;
    final direction = Offset(math.cos(a), math.sin(a) * .76);
    final center = at + direction * (.44 + phase * (i.isEven ? 1.41 : 1.15));
    final side = Offset(-direction.dy, direction.dx) * (.08 + (i % 3) * .034);
    _poly(
      canvas,
      [
        center + direction * .24,
        center + side,
        center - direction * .17,
        center - side * .65,
      ],
      const Color(0xffa7dafa).withValues(alpha: fade * .93),
      stroke: const Color(0xff142d43).withValues(alpha: fade),
      width: .049,
    );
  }
}
