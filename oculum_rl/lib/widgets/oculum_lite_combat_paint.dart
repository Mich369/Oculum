part of 'oculum_lite_arena.dart';

void _paintInkFinish(
  Canvas canvas,
  Offset feet,
  LiteInkFinish finish,
  double motion,
) {
  if (finish == LiteInkFinish.canonica) return;
  final tone = finish.color;
  final center = feet + const Offset(0, .13);
  final extension = motion.clamp(0.0, 1.0) * .39;
  _inkSlash(
    canvas,
    center - Offset(.43 + extension, .04),
    center - const Offset(.19, .01),
    tone.withValues(alpha: .43),
    .065,
  );
  _inkSlash(
    canvas,
    center + const Offset(.18, .015),
    center + Offset(.43 + extension, -.01),
    tone.withValues(alpha: .57),
    .065,
  );
  _poly(
    canvas,
    [
      center - const Offset(0, .095),
      center + const Offset(.112, 0),
      center + const Offset(0, .095),
      center - const Offset(.112, 0),
    ],
    tone.withValues(alpha: .72),
    stroke: _ink,
    width: .030,
  );
}

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
    LiteHero.dronePostea || LiteHero.polloMeccanico => const Color(0xff7dddf2),
    LiteHero.babyForestDemon ||
    LiteHero.curatorePeste ||
    LiteHero.lithra => _active,
    LiteHero.pyrel || LiteHero.vampiro || LiteHero.reGoblin => _ember,
    LiteHero.cavaliereLunare => const Color(0xffc0b5f0),
    LiteHero.slimeBlu => const Color(0xff8dd4fb),
    LiteHero.luce ||
    LiteHero.guardiaSolare ||
    LiteHero.eliteSolare ||
    LiteHero.guardianoSolare ||
    LiteHero.aberrazioneSolare => const Color(0xffffdda6),
    LiteHero.pollo ||
    LiteHero.demoneMinore ||
    LiteHero.demoneIntermedio ||
    LiteHero.demoneMaggiore ||
    LiteHero.diavolo => _ember,
    LiteHero.raganella => _active,
    LiteHero.pipistrello => _violet,
    LiteHero.ombra || LiteHero.veyrth || LiteHero.doppelganger => _violet,
    LiteHero.vesanybel => const Color(0xffdca66c),
    LiteHero.aerovyr => const Color(0xffa6d8ff),
    LiteHero.vedettaEiva => const Color(0xff90d8c6),
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
  LiteWeapon.chakram => const Color(0xffa0e7d3),
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

void _paintBurstTrace(
  Canvas canvas,
  LiteBurstTrace trace,
  double time,
  Rect visible,
) {
  final fade = (1 - (time - trace.fadeStart) / LiteBurstTrace.fadeDuration)
      .clamp(0.0, 1.0);
  if (fade <= 0 || trace.direction.magnitude < .01) return;
  final start = _offset(trace.origin);
  final end = _offset(trace.end);
  if (!visible.overlaps(Rect.fromPoints(start, end).inflate(2.0))) return;

  final axis = _offset(trace.direction);
  final normal = Offset(-axis.dy, axis.dx);
  final (pigment, light, width) = switch (trace.kind) {
    LiteBurstKind.dash => (
      const Color(0xffba895f),
      const Color(0xfff7dcb2),
      .12,
    ),
    LiteBurstKind.phase => (
      const Color(0xff8569aa),
      const Color(0xffe0c2fc),
      .18,
    ),
    LiteBurstKind.open => (
      const Color(0xff9355bf),
      const Color(0xffffda87),
      .25,
    ),
    LiteBurstKind.veil => (
      const Color(0xff3b8b90),
      const Color(0xffa0e5dc),
      .15,
    ),
    LiteBurstKind.clash => (
      const Color(0xffa95846),
      const Color(0xffffac85),
      .13,
    ),
  };

  // Build a tapered brush edge from the movement samples. Each side keeps
  // small irregularities rather than following a constant-width pen stroke.
  if (trace.pointCount > 1) {
    for (var lane = -1; lane <= 1; lane++) {
      final centers = <Offset>[];
      final edges = <Offset>[];
      for (var i = 0; i < trace.pointCount; i++) {
        final at = _offset(trace.pointAt(i));
        final along = i / (trace.pointCount - 1);
        final grain = (i * 7 + lane + 6) % 5 / 5 - .4;
        final spread = (.20 + along * .15) * lane;
        centers.add(
          at +
              normal * (spread + grain * .09) -
              Offset(0, .14 + (lane + 1) * (.14 + along * .07)),
        );
        final taper = math.sin(math.pi * along).abs();
        edges.add(
          normal * (width * (.05 + taper * .75) * (lane == 0 ? 1.4 : .74)) -
              Offset(0, width * taper * (.24 + grain * .35)),
        );
      }
      final body = Path()
        ..addPolygon([
          for (var i = 0; i < centers.length; i++) centers[i] + edges[i],
          for (var i = centers.length - 1; i >= 0; i--) centers[i] - edges[i],
        ], true);
      canvas.drawPath(
        body,
        Paint()..color = _ink.withValues(alpha: fade * .76),
      );
      final inner = Path()
        ..addPolygon([
          for (var i = 0; i < centers.length; i++) centers[i] + edges[i] * .58,
          for (var i = centers.length - 1; i >= 0; i--)
            centers[i] - edges[i] * .58,
        ], true);
      canvas.drawPath(
        inner,
        Paint()
          ..color = (lane == 0 ? pigment : light).withValues(alpha: fade * .83),
      );
    }
  }

  if (trace.kind == LiteBurstKind.phase || trace.kind == LiteBurstKind.open) {
    // Torn, translucent marks suggest the previous pose without reading as actors.
    for (var i = trace.pointCount - 4; i > 0; i -= 4) {
      final at = _offset(trace.pointAt(i)) - const Offset(0, .43);
      final ghost = Path()
        ..moveTo(at.dx - axis.dx * .37, at.dy - axis.dy * .37)
        ..lineTo(at.dx - .10, at.dy - .63)
        ..lineTo(at.dx + .13, at.dy - .73)
        ..lineTo(at.dx + axis.dx * .28, at.dy + axis.dy * .28 - .30)
        ..lineTo(at.dx + .10, at.dy + .14)
        ..close();
      canvas.drawPath(
        ghost,
        Paint()..color = pigment.withValues(alpha: .22 * fade),
      );
    }
  }

  // Short dry-brush cuts leave gaps around the moving figure and its weapon.
  for (var i = 1; i < trace.pointCount; i += 2) {
    final step = _offset(trace.pointAt(i) - trace.pointAt(i - 1));
    if (step.distanceSquared < .002) continue;
    final tangent = step / step.distance;
    final cross = Offset(-tangent.dy, tangent.dx);
    final side = i % 4 == 1 ? 1.0 : -1.0;
    final at =
        _offset(trace.pointAt(i)) - const Offset(0, .51) + cross * (.24 * side);
    final intensity = fade * (.34 + .52 * i / trace.pointCount);
    _inkSlash(
      canvas,
      at - tangent * (.16 + (i % 3) * .06),
      at + cross * (.08 * side),
      light.withValues(alpha: intensity),
      width * .50,
    );
  }

  _paintBurstFlare(canvas, start, axis, time - trace.startedAt, pigment, light);
  if (trace.finished && (end - start).distanceSquared >= .06) {
    _paintBurstFlare(
      canvas,
      end,
      -axis,
      time - trace.fadeStart,
      pigment,
      light,
    );
  }
}

void _paintBurstFlare(
  Canvas canvas,
  Offset feet,
  Offset axis,
  double age,
  Color pigment,
  Color light,
) {
  if (age < 0 || age >= .18) return;
  final phase = age / .18;
  final fade = 1 - phase;
  final normal = Offset(-axis.dy, axis.dx);
  for (var i = -2; i <= 2; i++) {
    final root = feet - const Offset(0, .16) + normal * (i * .12);
    final outward = -axis * (.30 + (2 - i.abs()) * .10) + normal * (i * .22);
    final at = root + outward * (phase * .70);
    _inkSlash(
      canvas,
      at,
      at + outward * (.52 + fade * .62),
      pigment.withValues(alpha: fade * .88),
      .092 * fade,
    );
    _inkSlash(
      canvas,
      at,
      at + outward * .62,
      light.withValues(alpha: fade * .88),
      .039 * fade,
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

int? _solarRow(LiteEnemyKind kind) => switch (kind) {
  LiteEnemyKind.guardiaSolare => 0,
  LiteEnemyKind.eliteSolare => 1,
  LiteEnemyKind.guardianoSolare => 2,
  LiteEnemyKind.aberrazioneSolare => 3,
  _ => null,
};

void _solarActor(
  Canvas canvas,
  ui.Image atlas,
  int row,
  double animationLead,
  LiteStride? stride,
  double windup,
  double strike,
  double hit, {
  bool hero = false,
  bool fallen = false,
  int columns = 4,
}) {
  final cell = atlas.width / columns;
  final size = hero ? 3.05 : (row == 2 ? 3.33 : 2.80);
  final anticipation = windup > 0 ? .17 + (1 - windup.clamp(0, 1)) * .05 : 0.0;
  final recoil = strike * .85;
  canvas.save();
  if (fallen) {
    canvas.rotate(-1.18);
  } else if (windup <= 0 && strike <= 0) {
    _groundedMotion(canvas, stride, animationLead, strideMetres: 1.72);
  }
  canvas.translate(recoil - anticipation, 0);
  canvas.rotate((anticipation - recoil) * .28);
  final dest = Rect.fromLTWH(-size / 2, -size, size, size);
  final ink = Paint()..filterQuality = FilterQuality.medium;
  if (hit > 0) {
    ink.colorFilter = const ColorFilter.mode(
      Color(0x47ffdc8d),
      BlendMode.srcATop,
    );
  }
  final attackRow = atlas.height >= cell * 2 && (windup > 0 || strike > 0);
  canvas.drawImageRect(
    atlas,
    Rect.fromLTWH(row * cell, attackRow ? cell : 0, cell, cell),
    dest,
    ink,
  );
  canvas.restore();
}

void _solarStairPaint(Canvas canvas, Offset at, double time) {
  final shaft = [
    at + const Offset(-1.05, -.65),
    at + const Offset(1.05, -.65),
    at + const Offset(.70, .84),
    at + const Offset(-.73, .84),
  ];
  _poly(
    canvas,
    shaft,
    const Color(0xff21181a),
    stroke: const Color(0xffa27742),
    width: .07,
  );
  for (var i = 0; i < 5; i++) {
    final width = 1.03 - i * .10;
    final center = at + Offset(0, -.64 + i * .30);
    _inkSlash(
      canvas,
      center - Offset(width, 0),
      center + Offset(width, 0),
      Color.lerp(const Color(0xfff0c16e), const Color(0xff785332), i / 5)!,
      .09,
    );
  }
  final glimmer = .38 + math.sin(time * 4.2) * .15;
  _inkSlash(
    canvas,
    shaft.first,
    shaft.last,
    const Color(0xfff7c779).withValues(alpha: glimmer),
    .07,
  );
}

void _astralWarning(Canvas canvas, LiteEnemy enemy) {
  final solar = _solarRow(enemy.kind) != null;
  final lunar =
      enemy.kind == LiteEnemyKind.custodeLunare ||
      enemy.kind == LiteEnemyKind.eliteLunare;
  if (!solar && !lunar) return;
  final start = _offset(enemy.position);
  final delta = _offset(enemy.attackTarget!) - start;
  if (delta.distance < .01) return;
  final direction = delta / delta.distance;
  final side = Offset(-direction.dy, direction.dx);
  final pigment = solar ? const Color(0xffefb45d) : const Color(0xffad95ed);
  final phase = (1 - enemy.windup / (solar ? 1.10 : .86)).clamp(0.0, 1.0);
  final slam =
      enemy.kind == LiteEnemyKind.custodeLunare ||
      enemy.kind == LiteEnemyKind.guardianoSolare && enemy.combatCycle % 3 == 2;
  if (slam) {
    final at = start + direction * (solar ? 1.1 : .9);
    final r = solar ? 2.9 : 2.7;
    _oval(
      canvas,
      at,
      r * 2,
      r * 2,
      pigment.withValues(alpha: .07 + phase * .08),
    );
    final rect = Rect.fromCircle(center: at, radius: r);
    for (var i = 0; i < 8; i++) {
      canvas.drawArc(
        rect,
        i * math.pi / 4 + .03,
        .48,
        false,
        Paint()
          ..color = pigment.withValues(alpha: .39 + phase * .59)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .08,
      );
    }
    return;
  }
  final ranged =
      enemy.kind == LiteEnemyKind.guardianoSolare ||
      enemy.kind == LiteEnemyKind.eliteSolare;
  final span = ranged
      ? (enemy.kind == LiteEnemyKind.guardianoSolare &&
                enemy.combatCycle % 3 == 0
            ? 13.0
            : 16.0)
      : 2.3;
  final both =
      enemy.kind == LiteEnemyKind.guardianoSolare && enemy.combatCycle % 3 == 0;
  final half = both ? span * .116 : (ranged ? .23 : .53);
  final end = start + direction * span;
  _poly(canvas, [
    start - side * .09,
    start + side * .09,
    end + side * half,
    end - side * half,
  ], pigment.withValues(alpha: .055 + phase * .08));
  for (final sign in [-1.0, 1.0]) {
    final from = start + side * (sign * .09);
    final to = end + side * (sign * half);
    for (var i = 0; i < 7; i++) {
      _inkSlash(
        canvas,
        Offset.lerp(from, to, i / 7)!,
        Offset.lerp(from, to, (i + .68) / 7)!,
        pigment.withValues(alpha: .36 + .52 * phase),
        .045 + .032 * phase,
      );
    }
  }
}

int? _infernalRow(LiteEnemyKind kind) => switch (kind) {
  LiteEnemyKind.demoneMinore => 0,
  LiteEnemyKind.demoneIntermedio => 1,
  LiteEnemyKind.demoneMaggiore => 2,
  LiteEnemyKind.diavolo => 3,
  LiteEnemyKind.divoramitu => 4,
  LiteEnemyKind.divoramituBoss => 5,
  _ => null,
};

void _burrowWarning(Canvas canvas, LiteEnemy enemy, LiteBurrow track) {
  const pigment = Color(0xffe7b582);
  if (track.exposed) {
    final at = _offset(enemy.position);
    final axis = _offset(enemy.hitboxAxis);
    final half = enemy.hitboxHalfLength;
    final radius = enemy.hitboxRadius;
    final contact = RRect.fromRectAndRadius(
      Rect.fromLTRB(-half - radius, -radius, half + radius, radius),
      Radius.circular(radius),
    );
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(math.atan2(axis.dy, axis.dx));
    canvas.drawRRect(contact, Paint()..color = const Color(0x39b85236));
    canvas.drawRRect(
      contact,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .062
        ..color = const Color(0xffc98155),
    );
    for (final side in [-1.0, 1.0]) {
      _inkSlash(
        canvas,
        Offset(side * half - .17, -radius),
        Offset(side * half + .17, radius),
        const Color(0x92edbd86),
        .065,
      );
    }
    canvas.restore();
    return;
  }
  if (track.warning <= 0) return;
  final axis = _offset(enemy.hitboxAxis);
  final extent = enemy.hitboxHalfLength + enemy.hitboxRadius;
  final start = _offset(track.start) - axis * extent;
  final end = _offset(track.end) + axis * extent;
  final line = end - start;
  if (line.distance < .001) return;
  final f = line / line.distance;
  final side = Offset(-f.dy, f.dx);
  final heat = (1 - track.warning / .82).clamp(0.0, 1.0);
  for (var sign in [-1.0, 1.0]) {
    final edge = side * (enemy.hitboxRadius * sign);
    _inkSlash(
      canvas,
      start + edge,
      end + edge,
      pigment.withValues(alpha: .23 + .45 * heat),
      .055,
    );
  }
  for (var i = 1; i < 10; i++) {
    final center = start + line * (i / 10);
    final jog = side * (i % 2 == 0 ? .31 : -.29);
    _inkSlash(
      canvas,
      center - f * .28 + jog,
      center + f * .27 - jog,
      pigment.withValues(alpha: .31 + .46 * heat),
      .092,
    );
  }
  _oval(
    canvas,
    end,
    .62 + heat * .31,
    .38,
    pigment.withValues(alpha: .15 + heat * .27),
    stroke: pigment,
    strokeWidth: .064,
  );
}

void _paintWeaponArtPulse(
  Canvas canvas,
  Offset at,
  Offset direction,
  LiteWeapon weapon,
  double cooldown, {
  int rank = 0,
}) {
  final time = LiteWeaponArt.weaponArtRecovery - cooldown;
  if (time < 0 || time >= .27 || direction.distance < .01) return;
  final phase = time / .27;
  final pigment = _weaponInk(weapon);
  final heading = math.atan2(direction.dy, direction.dx);
  if (weapon == LiteWeapon.spadaScudo && rank == 12) {
    final radius = 2.6 + phase * 3.6;
    final circle = Rect.fromCircle(center: at, radius: radius);
    final ink = Paint()
      ..color = pigment.withValues(alpha: 1 - phase)
      ..strokeWidth = .28 * (1 - phase) + .035
      ..style = PaintingStyle.stroke;
    canvas.drawArc(circle, heading - math.pi / 2, math.pi, false, ink);
    canvas.drawArc(
      circle.deflate(.25),
      heading - 1.45,
      2.90,
      false,
      ink..strokeWidth *= .24,
    );
    return;
  }
  final radius = (.63 + phase * 1.15) * (1 + rank * .036);
  final fan = Rect.fromCircle(
    center: at - const Offset(0, .12),
    radius: radius,
  );
  for (var i = -1; i <= 1; i++) {
    final start = heading + i * .57 - .28;
    canvas.drawArc(
      fan,
      start,
      .49,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .09 - phase * .055
        ..color = pigment.withValues(alpha: (1 - phase) * .9),
    );
  }
}
