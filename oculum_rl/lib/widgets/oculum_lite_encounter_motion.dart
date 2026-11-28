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
  if (index < 0 || index >= LiteLearnedArt.values.length) return null;
  final age = time - hit.time;
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
  };
  final falloff = (1 - age) * (1 - age);
  final beat = falloff * (.80 + .20 * math.cos(age * math.pi * 2 * count));
  canvas.translate(shift * beat, 0);
  canvas.rotate(turn * beat * lean);
  canvas.scale(1 + compression * beat * .65, 1 - compression * beat);
}

final _restFigure = _InkRig(const []);
final _tavernHead = _InkGripRig(const Offset(.51, .20), .11, .08);
final _smithHammer = _InkGripRig(
  const Offset(.40, .49),
  .040,
  .043,
  behind: true,
);
final _seerCoin = _InkGripRig(const Offset(.64, .29), .18, .035);

void _paintRestStation(
  Canvas canvas,
  ui.Image art,
  int index,
  Offset feet,
  double time,
  Offset visitor,
) {
  final cell = art.width / 4;
  final dest = Rect.fromLTWH(feet.dx - 1.45, feet.dy - 2.9, 2.9, 2.9);
  final close = (visitor - feet).distanceSquared < 8;
  final timeOffset = time + 1.24 + index * .83;
  final breath = math.sin(timeOffset * 2.8);
  final forgePhase = (timeOffset % 2.1) / 2.1;
  final upswing =
      _inkEase(forgePhase / .31) * (1 - _inkEase((forgePhase - .32) / .15));
  final read = .5 + .5 * math.sin(timeOffset * 3.0);
  final motion = switch (index) {
    0 => _InkAttackMotion(
      _tavernHead,
      Offset(breath * .006, close ? -.012 : -.003 * breath),
      close ? .036 : .016 * breath,
      0,
    ),
    1 => _InkAttackMotion(
      _smithHammer,
      Offset(-.021 * upswing, -.098 * upswing),
      .86 * upswing,
      0,
    ),
    _ => _InkAttackMotion(
      _seerCoin,
      Offset(read * .018, -.019 * read),
      -.13 * read,
      0,
    ),
  };
  _inkActorSprite(
    canvas,
    art,
    Rect.fromLTWH(index * cell, 0, cell, cell),
    dest,
    Paint()..filterQuality = FilterQuality.medium,
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
    case 1:
      final hit = (forgePhase - .47) / .23;
      if (hit < 0 || hit >= 1) return;
      final at = Offset(dest.left + 1.37, dest.top + 1.66);
      for (var i = 0; i < 6; i++) {
        final ray = Offset((i - 2.5) * .23, -.28 - (i % 3) * .081);
        final head = at + ray * (.38 + hit);
        _inkSlash(
          canvas,
          head - ray * .39,
          head,
          const Color(0xffffc87f).withValues(alpha: (1 - hit) * .92),
          .045 * (1 - hit),
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
