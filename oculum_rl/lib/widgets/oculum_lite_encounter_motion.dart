part of 'oculum_lite_arena.dart';

final _mantisClaw = _InkGripRig(const Offset(.79, .63), .079, .29);
final _mantisWing = _InkGripRig(
  const Offset(.68, .53),
  .074,
  .12,
  behind: true,
);
final _constructFist = _InkGripRig(const Offset(.70, .48), .09, .28);

_InkAttackMotion? _mantisClawMotion(double? windup, double hit) {
  if (windup != null) {
    final draw = _inkEase(1 - windup / .46);
    return _InkAttackMotion(
      _mantisClaw,
      Offset(-.066 * draw, -.044 * draw),
      .26 * draw,
      draw * .75,
    );
  }
  if (hit <= 0) return null;
  final release = _inkEase(hit);
  return _InkAttackMotion(
    _mantisClaw,
    Offset(.145 * release, -.029 * release),
    -.40 * release,
    release,
  );
}

_InkAttackMotion _mantisWingMotion(
  double time,
  double gait,
  double draw,
  double hit,
) {
  final flutter = math.sin(time * (gait > .2 ? 14 : 8));
  final flare = (.11 + gait * .13) * flutter - .15 * draw + .26 * hit;
  return _InkAttackMotion(
    _mantisWing,
    Offset(-.018 * hit, -.035 * (gait + hit)),
    flare,
    0,
  );
}

_InkAttackMotion? _constructArmMotion(double? windup, double hit) {
  if (windup != null) {
    final load = _inkEase(1 - windup / .46);
    return _InkAttackMotion(
      _constructFist,
      Offset(-.075 * load, -.087 * load),
      -.31 * load,
      load,
    );
  }
  if (hit <= 0) return null;
  final release = _inkEase(hit);
  return _InkAttackMotion(
    _constructFist,
    Offset(.095 * release, .082 * release),
    .34 * release,
    release,
  );
}

void _paintMantisEdge(Canvas canvas, Rect body, double hit) {
  final root = Offset(
    body.right - body.width * .07,
    body.top + body.height * .69,
  );
  final flash = math.sin(hit * math.pi) * .82;
  _inkSlash(
    canvas,
    root + Offset(.10, -.25 * hit),
    root + Offset(.61 * hit, .26),
    const Color(0xffe4aa68).withValues(alpha: flash),
    .058 * hit,
  );
  _inkSlash(
    canvas,
    root + const Offset(.10, .02),
    root + Offset(.43 * hit, .42),
    const Color(0xff6c3e42).withValues(alpha: flash),
    .078 * hit,
  );
}

void _paintDroneThrottle(
  Canvas canvas,
  Rect body,
  double tension,
  double hit,
  double time,
) {
  final power = math.max(tension * .58, hit);
  final underside = Offset(
    body.left + body.width * .30,
    body.top + body.height * .87,
  );
  for (var i = 0; i < 3; i++) {
    final jitter = .19 + .15 * math.sin(time * 31 + i * 1.3);
    final start = underside + Offset(i * .18, -.035 * i);
    _inkSlash(
      canvas,
      start,
      start + Offset(-jitter * power, (.19 + jitter) * power),
      const Color(0xff82d1d2).withValues(alpha: power * .72),
      .041,
    );
  }
}

void _applyNightCreaturePose(
  Canvas canvas,
  LiteEnemyKind kind,
  LiteStride? stride,
  double lead, {
  required double? windup,
  required double strike,
  required double hurt,
}) {
  final (pace, crouch, recoil, advance) = switch (kind) {
    LiteEnemyKind.lupoLunare => (1.69, .13, .095, .26),
    LiteEnemyKind.goblinColtello => (1.34, .088, .13, .28),
    LiteEnemyKind.goblinFango ||
    LiteEnemyKind.goblinColla => (1.28, .055, .18, -.12),
    LiteEnemyKind.guardianoLunare ||
    LiteEnemyKind.custodeLunare => (2.14, .064, .053, .19),
    LiteEnemyKind.guardiaLunare ||
    LiteEnemyKind.eliteLunare => (1.67, .043, .075, .17),
    LiteEnemyKind.reGoblin => (1.61, .067, .11, .24),
    _ => (1.43, .055, .10, .12),
  };
  if (hurt > 0) {
    final flinch = _inkEase(hurt / .18);
    canvas.translate(-recoil * flinch, 0);
    canvas.rotate(-.115 * flinch);
  } else if (strike > 0) {
    final drive = _inkEase(strike / .23);
    canvas.translate(advance * drive, 0);
    canvas.rotate(.13 * drive * (advance < 0 ? -1 : 1));
    canvas.scale(1 + .08 * drive, 1 - crouch * drive * .52);
  } else if (windup != null) {
    final load = .35 + .65 * _inkEase(1 - windup / .55);
    canvas.translate(-advance * load * .38, 0);
    canvas.rotate(-.075 * load);
    canvas.scale(1 + crouch * load * .67, 1 - crouch * load);
  } else {
    _groundedMotion(canvas, stride, lead, strideMetres: pace);
  }
}

typedef _ArtCastPose = (LiteLearnedArt, double);

_ArtCastPose? _artCastPose(LiteCombatImpact hit, double time) {
  final index = hit.life.toInt();
  final age = time - hit.time;
  if (hit.target == LiteImpactTarget.milestoneCast) {
    if (index < 0 || index >= LiteRelicFamily.values.length) return null;
    if (age < 0 || age >= .34) return null;
    final cue = switch (LiteRelicFamily.values[index]) {
      LiteRelicFamily.orbita => LiteLearnedArt.falci,
      LiteRelicFamily.terramaul => LiteLearnedArt.basalto,
      LiteRelicFamily.segugio => LiteLearnedArt.plasma,
      LiteRelicFamily.canna => LiteLearnedArt.pattuglia,
      LiteRelicFamily.spadaLusier => LiteLearnedArt.lame,
      LiteRelicFamily.mazzaGuardiano => LiteLearnedArt.corruzione,
    };
    return (cue, age / .34);
  }
  if (index < 0 || index >= LiteLearnedArt.values.length) return null;
  final art = LiteLearnedArt.values[index];
  final duration = switch (art) {
    LiteLearnedArt.plasma => .26,
    LiteLearnedArt.falci => .36,
    LiteLearnedArt.linfa => .47,
    LiteLearnedArt.pattuglia => .28,
    LiteLearnedArt.lame => .34,
    LiteLearnedArt.corruzione => .46,
    LiteLearnedArt.brace => .32,
    LiteLearnedArt.basalto => .45,
    LiteLearnedArt.ecoVelata => .57,
    LiteLearnedArt.passoSenzaLuce => .29,
    LiteLearnedArt.filoOmbra => .38,
  };
  return age >= 0 && age < duration ? (art, age / duration) : null;
}

void _applyArtGesture(Canvas canvas, _ArtCastPose cast, {double lean = 1}) {
  final (art, age) = cast;
  final (shift, turn, compression, count) = switch (art) {
    LiteLearnedArt.plasma => (-.16, -.16, .075, 1),
    LiteLearnedArt.falci => (.16, .125, .050, 2),
    LiteLearnedArt.linfa => (.018, -.052, .115, 1),
    LiteLearnedArt.pattuglia => (.32, .17, .060, 1),
    LiteLearnedArt.lame => (.16, .22, .048, 2),
    LiteLearnedArt.corruzione => (.067, -.099, .150, 1),
    LiteLearnedArt.brace => (-.064, -.12, .075, 3),
    LiteLearnedArt.basalto => (.19, .24, .158, 1),
    LiteLearnedArt.ecoVelata => (-.065, -.075, .12, 2),
    LiteLearnedArt.passoSenzaLuce => (.26, .19, .057, 1),
    LiteLearnedArt.filoOmbra => (-.14, -.21, .064, 2),
  };
  final falloff = (1 - age) * (1 - age);
  final beat = falloff * (.80 + .20 * math.cos(age * math.pi * 2 * count));
  canvas.translate(shift * beat, 0);
  canvas.rotate(turn * beat * lean);
  canvas.scale(1 + compression * beat * .65, 1 - compression * beat);
}

final _restFigure = _InkRig(const []);
final _tavernHead = _InkGripRig(const Offset(.51, .20), .11, .08);
final _seerCoin = _InkGripRig(const Offset(.64, .29), .18, .035);

void _forgeCell(Canvas canvas, ui.Image atlas, int frame, Rect target) {
  final cell = atlas.width / 8;
  canvas.drawImageRect(
    atlas,
    Rect.fromLTWH(cell * frame, 0, cell, atlas.height.toDouble()),
    target,
    Paint()..filterQuality = FilterQuality.medium,
  );
}

void _paintBaghestGait(
  Canvas canvas,
  ui.Image atlas,
  LiteEnemy beast,
  double lead,
) {
  final speed = beast.stride.speed;
  final step = ((beast.stride.distance + speed * lead) * 2.35).floor().isOdd;
  final pose = beast.hp <= 0
      ? 7
      : beast.strikePose > 0
      ? 6
      : beast.attacking
      ? 5
      : beast.clashRemaining > 0
      ? 4
      : speed > 3.5
      ? (step ? 3 : 4)
      : speed > .12
      ? (step ? 1 : 2)
      : 0;
  _forgeCell(canvas, atlas, pose, const Rect.fromLTWH(-1.73, -3.3, 3.46, 3.46));
}

void _paintDivoramitu(
  Canvas canvas,
  ui.Image atlas,
  LiteStride stride,
  double lead, {
  double? leap,
  bool fallen = false,
  bool striking = false,
  bool juvenile = false,
}) {
  final distance = stride.distance + stride.speed * lead;
  final crawl = (distance * 3.4).floor().isEven ? 1 : 2;
  final pose = fallen
      ? 7
      : striking
      ? 5
      : switch (leap) {
          null => stride.speed > .1 ? crawl : (juvenile ? 4 : 0),
          < .19 => 0,
          < .68 => 3,
          < .87 => 5,
          _ => 6,
        };
  if (!fallen && leap != null)
    canvas.translate(0, -math.sin(leap * math.pi) * 1.35);
  _forgeCell(
    canvas,
    atlas,
    pose,
    const Rect.fromLTWH(-1.47, -2.55, 2.94, 2.94),
  );
}

void _paintSmithAtWork(
  Canvas canvas,
  ui.Image atlas,
  Offset feet,
  double time, {
  required bool smithPresent,
}) {
  final phase = (time + 1.24) % 1.9;
  final pose = switch (phase) {
    < .40 => 0,
    < .63 => 1,
    < .88 => 2,
    < 1.02 => 3,
    < 1.13 => 4,
    < 1.42 => 5,
    _ => 0,
  };
  _forgeCell(
    canvas,
    atlas,
    7,
    Rect.fromLTWH(feet.dx + .15, feet.dy - 2.65, 2.4, 2.4),
  );
  if (smithPresent) {
    _forgeCell(
      canvas,
      atlas,
      pose,
      Rect.fromLTWH(feet.dx - 1.54, feet.dy - 2.23, 2.55, 2.55),
    );
  }
  _forgeCell(
    canvas,
    atlas,
    6,
    Rect.fromLTWH(feet.dx + .19, feet.dy - .61, 1.39, 1.39),
  );
  if (!smithPresent) return;
  final impact = (phase - 1.02) / .36;
  if (impact < 0 || impact >= 1) return;
  final metal = feet + const Offset(.91, -.30);
  for (var i = 0; i < 8; i++) {
    final ray = Offset((i - 3.6) * .22, -.43 - i % 3 * .116);
    final head = metal + ray * (.20 + impact);
    final fade = 1 - impact;
    _inkSlash(
      canvas,
      head - ray * (.34 * fade),
      head,
      Color.lerp(
        const Color(0xff9e4633),
        const Color(0xffffd680),
        fade,
      )!.withValues(alpha: .96 * fade),
      .073 * fade,
    );
  }
}

bool _enemyIsDashing(LiteEnemy enemy) =>
    enemy.clashRemaining > 0 ||
    enemy.attacking && enemy.stride.speed > enemy.kind.speed * 2.05;

void _paintCreatureGait(
  Canvas canvas,
  ui.Image atlas,
  int base,
  LiteStride? stride,
  double lead, {
  required bool fallen,
  required bool striking,
  required bool winding,
  required bool dashing,
  bool dashFrame = false,
  double height = 2.72,
}) {
  final speed = stride?.speed ?? 0;
  final step =
      (((stride?.distance ?? 0) + speed * lead) * (speed > 4 ? 3.2 : 2.17))
          .floor()
          .isOdd;
  final pose = fallen
      ? 0
      : striking
      ? 3
      : dashing && dashFrame
      ? 2
      : winding && !dashFrame
      ? 2
      : dashing || speed > .1 && step
      ? 1
      : 0;
  if (fallen) {
    canvas.rotate(1.16);
    canvas.scale(.73);
  } else if (dashing) {
    canvas.translate(.11, -.075);
  }
  _forgeCell(
    canvas,
    atlas,
    base + pose,
    Rect.fromLTWH(-height / 2, -height * .94, height, height),
  );
}

void _paintAuthoredGait(
  Canvas canvas,
  ui.Image atlas,
  LiteStride? stride,
  double lead, {
  required bool fallen,
  required bool dashing,
  required bool windup,
  required bool striking,
  double height = 2.70,
}) {
  final speed = stride?.speed ?? 0;
  final step = (((stride?.distance ?? 0) + speed * lead) * 2.65).floor().isOdd;
  final frame = fallen
      ? 0
      : striking
      ? 7
      : dashing
      ? 5
      : windup
      ? 6
      : speed > 4.1
      ? (step ? 3 : 4)
      : speed > .1
      ? (step ? 1 : 2)
      : 0;
  if (fallen) {
    canvas.rotate(1.20);
    canvas.scale(.76);
  }
  _forgeCell(
    canvas,
    atlas,
    frame,
    Rect.fromLTWH(-height * .49, -height * .944, height, height),
  );
}

void _paintForgedWeapon(
  Canvas canvas,
  LiteClone arm,
  Offset feet,
  double time,
) {
  final sway = math.sin(time * 7.1 + arm.id) * .11;
  final swing = arm.swing > 0 ? 1 - arm.swing / .23 : 0.0;
  final (hue, edge) = switch (arm.weapon) {
    LiteWeapon.chakram => (const Color(0xff6ddbf0), const Color(0xffd9ffff)),
    LiteWeapon.falceRunica => (
      const Color(0xffaf8afd),
      const Color(0xfff2d6ff),
    ),
    LiteWeapon.doppieLame => (const Color(0xff7ae6b3), const Color(0xffe1fff5)),
    _ => (const Color(0xffffa05b), const Color(0xffffefd0)),
  };

  canvas.save();
  canvas.translate(feet.dx, feet.dy - .70 + sway);
  final flip = arm.poseAim.x < 0 ? -1.0 : 1.0;
  canvas.scale(flip, 1);
  canvas.rotate(-.67 + math.sin(swing * math.pi) * 1.55);
  canvas.scale(.69);

  final blade = Path();
  final grip = Path();
  switch (arm.weapon) {
    case LiteWeapon.chakram:
      blade.fillType = PathFillType.evenOdd;
      blade.addOval(
        Rect.fromCenter(center: Offset(0, -.05), width: 1.05, height: .82),
      );
      blade.addOval(
        Rect.fromCenter(center: Offset(0, -.05), width: .65, height: .47),
      );
    case LiteWeapon.falceRunica:
      grip
        ..moveTo(0, .74)
        ..lineTo(0, -.45);
      blade
        ..moveTo(-.45, -.35)
        ..quadraticBezierTo(.18, -.92, .83, -.48)
        ..quadraticBezierTo(.23, -.55, .02, -.16)
        ..close();
    case LiteWeapon.martelloForgia:
      grip
        ..moveTo(0, .68)
        ..lineTo(0, -.34);
      blade.addPolygon(const [
        Offset(-.48, -.46),
        Offset(.28, -.55),
        Offset(.48, -.24),
        Offset(.45, .04),
        Offset(-.45, .11),
      ], true);
    case LiteWeapon.piccaOssidiana:
      grip
        ..moveTo(0, .78)
        ..lineTo(0, -.17);
      blade.addPolygon(const [
        Offset(0, -.86),
        Offset(.21, -.37),
        Offset(.08, -.14),
        Offset(-.16, -.29),
      ], true);
    case LiteWeapon.doppieLame:
      grip
        ..moveTo(-.27, .38)
        ..lineTo(-.13, .15)
        ..moveTo(.32, .46)
        ..lineTo(.33, .14);
      blade.addPolygon(const [
        Offset(-.31, .20),
        Offset(-.40, -.31),
        Offset(-.11, -.72),
        Offset(-.18, -.19),
        Offset(-.04, .13),
      ], true);
      blade.addPolygon(const [
        Offset(.24, .17),
        Offset(.16, -.12),
        Offset(.43, -.53),
        Offset(.47, -.13),
        Offset(.41, .20),
      ], true);
    default:
      grip
        ..moveTo(0, .63)
        ..lineTo(0, .20)
        ..moveTo(-.30, .21)
        ..lineTo(.30, .21);
      blade.addPolygon(const [
        Offset(0, -.83),
        Offset(.16, -.60),
        Offset(.13, .18),
        Offset(-.13, .18),
        Offset(-.16, -.60),
      ], true);
  }

  final aura = Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
  canvas.drawPath(
    blade,
    aura
      ..strokeWidth = .22
      ..color = hue.withValues(alpha: .12),
  );
  canvas.drawPath(
    grip,
    aura
      ..strokeWidth = .16
      ..color = hue.withValues(alpha: .27),
  );
  canvas.drawPath(blade, Paint()..color = hue.withValues(alpha: .61));
  canvas.drawPath(
    grip,
    aura
      ..strokeWidth = .055
      ..color = edge.withValues(alpha: .86),
  );
  canvas.drawPath(
    blade,
    aura
      ..strokeWidth = .071
      ..color = edge.withValues(alpha: .94),
  );
  if (arm.forgedProtected) {
    final halo = Rect.fromCenter(
      center: Offset.zero,
      width: 1.88,
      height: 1.67,
    );
    final angle = time * 2.1 + arm.id;
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(
        halo,
        angle + i * 2.094,
        1.1,
        false,
        aura
          ..strokeWidth = .04
          ..color = hue.withValues(alpha: .46),
      );
    }
  }
  if (arm.swing > 0) {
    _inkSlash(
      canvas,
      const Offset(-.37, -.34),
      Offset(.98 + .35 * swing, -.73),
      edge.withValues(alpha: (1 - swing) * .92),
      .09,
    );
  }
  canvas.restore();
}

void _paintRestStation(
  Canvas canvas,
  ui.Image art,
  int index,
  Offset feet,
  double time,
  Offset visitor, {
  ui.Image? forge,
  bool smithPresent = true,
}) {
  final cell = art.width / 4;
  final dest = Rect.fromLTWH(feet.dx - 1.45, feet.dy - 2.9, 2.9, 2.9);
  if (index == 1) {
    if (forge != null) {
      _paintSmithAtWork(canvas, forge, feet, time, smithPresent: smithPresent);
    } else if (smithPresent) {
      canvas.drawImageRect(
        art,
        Rect.fromLTWH(cell, 0, cell, cell),
        dest,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    return;
  }
  final close = (visitor - feet).distanceSquared < 8;
  final timeOffset = time + 1.24 + index * .83;
  final breath = math.sin(timeOffset * 2.8);
  final read = .5 + .5 * math.sin(timeOffset * 3.0);
  final motion = switch (index) {
    0 => _InkAttackMotion(
      _tavernHead,
      Offset(breath * .006, close ? -.012 : -.003 * breath),
      close ? .036 : .016 * breath,
      0,
    ),
    _ => _InkAttackMotion(
      _seerCoin,
      Offset(read * .018, -.019 * read),
      -.13 * read,
      0,
    ),
  };
  final source = Rect.fromLTWH(index * cell, 0, cell, cell);
  final paint = Paint()..filterQuality = FilterQuality.medium;
  _inkActorSprite(
    canvas,
    art,
    source,
    dest,
    paint,
    _restFigure,
    phase: time,
    strength: 0,
    handMotion: motion,
  );
  switch (index) {
    case 0:
      final cup = Offset(dest.left + .76, dest.top + 1.45);
      for (var i = 0; i < 3; i++) {
        final rise = (timeOffset * .57 + i * .33) % 1;
        final a = cup + Offset(math.sin(rise * 6.4) * .11, -.48 * rise);
        _inkSlash(
          canvas,
          a,
          a + const Offset(.06, -.14),
          const Color(0xffd9c1a4)
              .withValues(alpha: math.sin(rise * math.pi) * .61),
          .046 * (1 - rise),
        );
      }
    case 2:
      final coin = Offset(
        dest.left + 2.24 + .051 * read,
        dest.top + .50 - .055 * read,
      );
      final gleam = math.pow(read, 5).toDouble() * (close ? .91 : .63);
      _inkSlash(
        canvas,
        coin - const Offset(.09, .01),
        coin + const Offset(.10, -.01),
        const Color(0xffe4ca8b).withValues(alpha: gleam),
        .031,
      );
      _inkSlash(
        canvas,
        coin - const Offset(0, .08),
        coin + const Offset(0, .08),
        const Color(0xffe4ca8b).withValues(alpha: gleam),
        .031,
      );
  }
}

void _paintMilestoneTechnique(
  Canvas canvas,
  LiteCombatImpact cast,
  double age,
) {
  if (age < 0 || age >= .45 || cast.end == null) return;
  final index = cast.life.toInt();
  if (index < 0 || index >= LiteRelicFamily.values.length) return;
  final form = cast.shield.toInt().clamp(1, 5);
  final from = _offset(cast.position);
  final heading = _offset(cast.end!) - from;
  final family = LiteRelicFamily.values[index];
  final gain = _inkEase(age / .20);
  final alpha = (1 - age / .45) * .86;
  final arc = (heading.distanceSquared < .001 ? 0.0 : heading.direction);
  final (color, reach, spread) = switch (family) {
    LiteRelicFamily.orbita => (const Color(0xffa7d1df), 1.65, .90),
    LiteRelicFamily.terramaul => (const Color(0xffb38b73), 1.45, 1.85),
    LiteRelicFamily.segugio => (const Color(0xff75d7d7), 2.18, .35),
    LiteRelicFamily.canna => (const Color(0xff86d9bb), 2.3, .48),
    LiteRelicFamily.spadaLusier => (const Color(0xffffc286), 1.65, 1.1),
    LiteRelicFamily.mazzaGuardiano => (const Color(0xffdda768), 1.52, 1.48),
  };
  final pigment = color.withValues(alpha: alpha);
  final base = (reach + form * .13) * (.55 + gain * .45);
  canvas.save();
  canvas.translate(from.dx, from.dy - .20);
  canvas.rotate(arc);
  switch (family) {
    case LiteRelicFamily.orbita:
      for (final sign in [-1, 1]) {
        _bladeRibbon(
          canvas,
          Offset.zero,
          const Offset(1, 0),
          base * (sign == 1 ? 1 : .79),
          age * .75,
          pigment,
          sign.toDouble(),
        );
      }
    case LiteRelicFamily.terramaul || LiteRelicFamily.mazzaGuardiano:
      final center = family == LiteRelicFamily.terramaul ? 0.0 : .6 + gain;
      final rays = 6 + form * 2;
      for (var i = 0; i < rays; i++) {
        final turn = i * math.pi * 2 / rays;
        final direction = Offset(math.cos(turn), .73 * math.sin(turn));
        final tip = Offset(center, 0) + direction * (base + (i % 4) * .09);
        final corner = Offset(-direction.dy, direction.dx);
        _poly(
          canvas,
          [
            tip - direction * (.50 + .24 * gain),
            tip + corner * .08,
            tip + direction * .16,
            tip - corner * .075,
          ],
          pigment,
          stroke: _ink.withValues(alpha: alpha),
          width: .048,
        );
      }
    case LiteRelicFamily.segugio || LiteRelicFamily.canna:
      final teeth = family == LiteRelicFamily.segugio ? 3 + form : 3;
      for (var i = 0; i < teeth; i++) {
        final lateral = (i - (teeth - 1) * .5) * spread * .49;
        final tail = Offset(.34 + .48 * gain, lateral * .38 - .53);
        final tip = Offset(base + (i.isEven ? .23 : -.20), lateral - .55);
        _inkSlash(canvas, tail, tip, pigment, .058 + .016 * form);
      }
    case LiteRelicFamily.spadaLusier:
      _bladeRibbon(
        canvas,
        const Offset(.16, -.51),
        const Offset(1, 0),
        base,
        age * .68,
        pigment,
        1,
      );
      for (var card = 0; card < 1 + (form + 1) ~/ 2; card++) {
        final at = Offset(
          .72 + .40 * card + .49 * gain,
          -.68 + (card.isEven ? -.26 : .26) * gain,
        );
        _poly(
          canvas,
          [
            at + const Offset(-.11, .08),
            at + const Offset(.08, -.16),
            at + const Offset(.26, -.02),
            at + const Offset(.08, .17),
          ],
          pigment,
          stroke: _ink.withValues(alpha: alpha),
          width: .043,
        );
      }
  }
  canvas.restore();
}

void _paintStormWarning(Canvas canvas, LiteStormWarning cue) {
  final origin = _offset(cue.origin);
  final target = _offset(cue.target);
  final drive = (1 - cue.remaining / cue.duration).clamp(0.0, 1.0);
  final shade = cue.phase == 3
      ? const Color(0xfff3b9ff)
      : const Color(0xff99d1fc);
  final line = shade.withValues(alpha: .50 + drive * .43);
  switch (cue.pattern) {
    case LiteStormPattern.ventaglio:
      final axis = _offset(cue.direction);
      for (final angle in cue.spread) {
        final angleOnFloor = axis.direction + angle;
        final vector = Offset(math.cos(angleOnFloor), math.sin(angleOnFloor));
        for (var dash = 0; dash < 7; dash++) {
          final start = origin + vector * (.68 + dash * 1.37);
          final end = start + vector * (.45 + drive * .36);
          _inkSlash(canvas, start, end, line, .025 + drive * .04);
        }
      }
    case LiteStormPattern.croce:
      for (final mark in cue.marks) {
        final at = _offset(mark);
        _oval(
          canvas,
          at,
          cue.radius * 2,
          cue.radius * 2,
          shade.withValues(alpha: .07 + drive * .20),
          stroke: line,
          strokeWidth: .042 + .025 * drive,
        );
        _inkSlash(
          canvas,
          at - const Offset(.18, .12),
          at + const Offset(.15, .16),
          line,
          .041,
        );
      }
    case LiteStormPattern.corona:
      final bands = Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(Rect.fromCircle(center: target, radius: cue.outer))
        ..addOval(Rect.fromCircle(center: target, radius: cue.inner));
      canvas.drawPath(
        bands,
        Paint()..color = shade.withValues(alpha: .11 + drive * .26),
      );
      for (final radius in [cue.inner, cue.outer]) {
        _oval(
          canvas,
          target,
          radius * 2,
          radius * 2,
          Colors.transparent,
          stroke: line,
          strokeWidth: .062,
        );
      }
      for (var i = 0; i < 16; i++) {
        final angle = i * math.pi / 8;
        final direction = Offset(math.cos(angle), math.sin(angle));
        _inkSlash(
          canvas,
          target + direction * (cue.inner + .12),
          target + direction * (cue.inner + .60 + .48 * drive),
          line,
          .041,
        );
      }
  }
}

void _paintFusionStrike(Canvas canvas, LiteCombatImpact hit, double age) {
  if (age < 0 || age > .26 || hit.end == null) return;
  final origin = _offset(hit.position);
  final direction = _offset(hit.end!) - origin;
  final normal = Offset(-direction.dy, direction.dx);
  final strength = 1 - age / .26;
  const gold = Color(0xffe6ac69);
  const teal = Color(0xff80c3b8);
  for (final (index, color) in [gold, teal].indexed) {
    final side = index == 0 ? -1 : 1;
    final start = origin + normal * (side * (.18 + age)) - const Offset(0, .75);
    final end = start + direction * (.85 + age * 3) + normal * (side * .21);
    _inkSlash(
      canvas,
      start,
      end,
      color.withValues(alpha: strength * .88),
      .10 * strength,
    );
  }
}

void _paintInfernalCrown(
  Canvas canvas,
  Offset feet,
  double time,
  double power,
) {
  for (var i = 0; i < 5; i++) {
    final angle = i * math.pi * 2 / 5 + time * 1.25;
    final flame =
        feet + Offset(math.cos(angle) * 1.2, -2.35 + math.sin(angle) * .37);
    final flicker = math.sin(time * 17 + i * 1.25);
    final tip = flame + Offset(.19 * flicker, -.58 - .09 * flicker);
    canvas.drawPath(
      Path()
        ..moveTo(flame.dx - .22, flame.dy)
        ..quadraticBezierTo(flame.dx - .31, flame.dy - .32, tip.dx, tip.dy)
        ..quadraticBezierTo(
          tip.dx - .04,
          tip.dy + .27,
          flame.dx + .17,
          flame.dy - .13,
        )
        ..quadraticBezierTo(
          flame.dx + .20,
          flame.dy + .16,
          flame.dx - .22,
          flame.dy,
        )
        ..close(),
      Paint()..color = const Color(0xff301220).withValues(alpha: power * .85),
    );
    _inkSlash(
      canvas,
      flame,
      tip + const Offset(-.03, .11),
      const Color(0xfff16d50).withValues(alpha: power * .91),
      .135,
    );
    _inkSlash(
      canvas,
      flame + const Offset(0, -.02),
      tip + const Offset(-.03, .27),
      const Color(0xfff6cf8b).withValues(alpha: power),
      .073,
    );
  }
}

void _paintSixPose(Canvas canvas, ui.Image atlas, int pose, Rect quad) {
  final cell = atlas.width / 3;
  canvas.drawImageRect(
    atlas,
    Rect.fromLTWH(pose % 3 * cell, pose ~/ 3 * cell, cell, cell),
    quad,
    Paint()..filterQuality = FilterQuality.medium,
  );
}

void _paintLusier(
  Canvas canvas,
  ui.Image atlas,
  LiteStride? stride,
  double time,
  bool strike,
  bool fallen,
) {
  final speed = stride?.speed ?? 0;
  final distance = stride?.distance ?? 0;
  final run = speed >= 3.35;
  final step = (distance / (run ? .76 : .38)).floor().isEven;
  final pose = strike || speed > 10
      ? 5
      : speed < .08
      ? 0
      : run
      ? (step ? 3 : 4)
      : (step ? 1 : 2);
  if (fallen) {
    canvas.translate(-.35, -.07);
    canvas.rotate(1.27);
  }
  final bob = pose == 0 ? math.sin(time * 2.0) * .024 : 0.0;
  _paintSixPose(
    canvas,
    atlas,
    pose,
    Rect.fromLTWH(-1.55, -3.1 + bob, 3.1, 3.1),
  );
}

void _paintBunnysHeal(
  Canvas canvas,
  Offset at,
  LiteCombatImpact hit,
  double age,
) {
  if (age < 0 || age >= .68) return;
  final fade = 1 - age / .68;
  final leaf = const Color(0xff91cf86).withValues(alpha: fade);
  final core = const Color(0xfff1e5b2).withValues(alpha: fade);
  final ink = const Color(0xff203b2e).withValues(alpha: .9 * fade);
  final from = _offset(hit.end ?? hit.position) - const Offset(0, .65);
  final destination = at - const Offset(0, 1.02);
  final axis = destination - from;
  final trail = Path()
    ..moveTo(from.dx, from.dy)
    ..cubicTo(
      from.dx + axis.dx * .14,
      from.dy - .98,
      from.dx + axis.dx * .77,
      destination.dy - .92,
      destination.dx,
      destination.dy,
    );
  final metric = trail.computeMetrics().first;
  final head = (age / .30).clamp(0.0, 1.0);
  final tail = ((age - .22) / .34).clamp(0.0, 1.0);
  if (head > tail) {
    final arc = metric.extractPath(metric.length * tail, metric.length * head);
    final brush = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = ink
      ..strokeWidth = .16 * fade;
    canvas.drawPath(arc, brush);
    canvas.drawPath(
      arc,
      brush
        ..color = leaf
        ..strokeWidth = .055 + .055 * fade,
    );
    for (var i = 0; i < 7; i++) {
      final along = head - i * .098;
      if (along < tail) break;
      final section = metric.getTangentForOffset(along * metric.length);
      if (section == null) continue;
      final direction = section.vector;
      final side = Offset(-direction.dy, direction.dx) * (i.isEven ? 1 : -1);
      final base = section.position + side * (.067 + i * .009);
      final tip = base + direction * .17 + side * .16;
      final sprout = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
          base.dx + side.dx * .19,
          base.dy + side.dy * .19,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          tip.dx + direction.dx * .035,
          tip.dy + direction.dy * .035,
          base.dx,
          base.dy,
        )
        ..close();
      canvas.drawPath(sprout, Paint()..color = i % 3 == 0 ? core : leaf);
    }
  }
  if (age < .21) return;
  final burst = (age - .21) / .47;
  final radius = .35 + 1.15 * burst;
  final ring = Rect.fromCenter(
    center: at,
    width: radius * 2,
    height: radius * .65,
  );
  final brush = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = .085 * (1 - burst);
  for (var i = 0; i < 4; i++) {
    canvas.drawArc(
      ring,
      i * math.pi / 2 + burst * .7,
      .98 + burst * .27,
      false,
      brush..color = i.isEven ? core : leaf,
    );
    final rise = .23 + burst * .86;
    final x = (i - 1.5) * (.25 + burst * .23);
    final glint = at + Offset(x, -rise - (i.isEven ? .21 : 0));
    _inkSlash(
      canvas,
      glint + const Offset(-.09, .14),
      glint,
      leaf,
      .075 * fade,
    );
  }
}

void _paintLusierCard(Canvas canvas, Offset p, Offset heading, double age) {
  final at = p - const Offset(0, .65);
  _inkSlash(canvas, at - heading * .93, at, const Color(0xa1b1713d), .15);
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.rotate(heading.direction + math.sin(age * 24) * .27);
  canvas.scale(1, .69 + .26 * math.cos(age * 31));
  _poly(
    canvas,
    const [
      Offset(-.21, -.13),
      Offset(.20, -.14),
      Offset(.22, .12),
      Offset(-.19, .14),
    ],
    const Color(0xffecbc70),
    stroke: _ink,
    width: .040,
  );
  _poly(canvas, const [
    Offset(-.12, 0),
    Offset(.01, -.07),
    Offset(.13, 0),
    Offset(0, .07),
  ], const Color(0xff812f35));
  _oval(canvas, Offset.zero, .072, .074, const Color(0xfff7e1a5));
  canvas.restore();
}
