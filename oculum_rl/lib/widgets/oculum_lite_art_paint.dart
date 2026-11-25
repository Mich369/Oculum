part of 'oculum_lite_arena.dart';

void _paintArtCast(Canvas canvas, LiteCombatImpact cast, double age) {
  if (age < 0 || cast.end == null) return;
  final id = cast.life.toInt();
  if (id < 0 || id >= LiteLearnedArt.values.length) return;
  final art = LiteLearnedArt.values[id];
  final duration = switch (art) {
    LiteLearnedArt.plasma => .39,
    LiteLearnedArt.falci => .49,
    LiteLearnedArt.linfa => .72,
    LiteLearnedArt.pattuglia => .34,
    LiteLearnedArt.lame => .45,
    LiteLearnedArt.corruzione => .68,
    LiteLearnedArt.brace => .42,
    LiteLearnedArt.basalto => .61,
  };
  if (age >= duration) return;
  final start = _offset(cast.position);
  final axis = _offset(cast.end!) - start;
  final form = cast.shield.toInt().clamp(1, art.maxRank);
  final ink = _ArtInk(canvas, age / duration);
  canvas.save();
  canvas.translate(start.dx, start.dy);
  canvas.rotate(math.atan2(axis.dy, axis.dx));
  switch (art) {
    case LiteLearnedArt.plasma:
      _artPlasma(ink, form);
    case LiteLearnedArt.falci:
      _artVaitern(ink);
    case LiteLearnedArt.linfa:
      _artLinfa(ink, form);
    case LiteLearnedArt.pattuglia:
      _artPattuglia(ink, form);
    case LiteLearnedArt.lame:
      _artLame(ink, form);
    case LiteLearnedArt.corruzione:
      _artCorruzione(ink, form);
    case LiteLearnedArt.brace:
      _artBrace(ink, form);
    case LiteLearnedArt.basalto:
      _artBasalto(ink, form);
  }
  canvas.restore();
}

class _ArtInk {
  _ArtInk(this.canvas, this.t);
  final Canvas canvas;
  final double t;
  final brush = Paint();

  double get clear => (1 - t).clamp(0.0, 1.0);
  double get out => 1 - clear * clear;

  void stroke(
    Offset a,
    Offset b,
    double width,
    Color color, {
    double opacity = 1,
  }) => _sweptInk(
    canvas,
    a,
    b,
    width,
    color.withValues(alpha: (clear * opacity).clamp(0.0, 1.0)),
    brush,
  );

  void arc(
    Offset at,
    double radius,
    double from,
    double span,
    double width,
    Color glow,
  ) {
    if (radius <= 0 || span <= 0) return;
    final rect = Rect.fromCircle(center: at, radius: radius);
    brush
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      from,
      span,
      false,
      brush
        ..color = const Color(0xff211523).withValues(alpha: clear * .70)
        ..strokeWidth = width * 2.6,
    );
    canvas.drawArc(
      rect,
      from + .04,
      span * .89,
      false,
      brush
        ..color = glow.withValues(alpha: clear)
        ..strokeWidth = width,
    );
    brush.style = PaintingStyle.fill;
  }
}

const _artCoal = Color(0xff23131d);

void _artPlasma(_ArtInk fx, int rank) {
  const cyan = Color(0xff67c7cf);
  const glint = Color(0xffe3f4d6);
  final draw = _inkEase(fx.t * 4.5);
  final emitter = Offset(.46 - .31 * fx.t, -.37);
  final radius = .13 + .40 * fx.out;
  fx.arc(emitter, radius, -1.52 + fx.t * 2.7, 2.55, .063, cyan);
  fx.arc(emitter, radius * .83, 1.71 + fx.t * 2.7, 1.38, .037, glint);
  fx.stroke(
    emitter - const Offset(.27, .01),
    emitter + Offset((.7 + rank * .11) * draw, -.028),
    .21 * fx.clear,
    _artCoal,
  );
  if (fx.t < .36) {
    final flash = (1 - fx.t / .36).clamp(0.0, 1.0);
    fx.stroke(
      emitter - const Offset(.08, .01),
      emitter + Offset(.29 + .70 * draw, -.024),
      .091 * flash + .025,
      glint,
    );
  }
  for (final side in [-1.0, 1.0]) {
    final edge =
        emitter + Offset(.24 + .28 * draw, side * (.09 + .28 * fx.out));
    fx.stroke(edge, edge - Offset(.23, side * .13), .048, cyan);
    final spark = edge + Offset(.18 * draw, side * .20 * fx.out);
    fx.stroke(spark, spark - Offset(.09, side * .05), .031, glint);
  }
}

void _paintPlasmaBolt(
  Canvas canvas,
  Offset at,
  Offset direction,
  double age,
  bool hostile,
) {
  final flank = Offset(-direction.dy, direction.dx);
  final core = hostile ? const Color(0xffd9f0ac) : const Color(0xffe4fcdb);
  final edge = hostile ? const Color(0xff83bd9a) : const Color(0xff67c7cf);
  // The painted point follows the simulated projectile. Only the wake trails.
  final tail = at - direction * (.64 + .64 * _inkEase(age * 12));
  final shake = math.sin(age * 34) * .06;
  _inkSlash(canvas, tail, at + direction * .12, _artCoal, .23);
  _inkSlash(canvas, tail + flank * shake, at + direction * .10, edge, .15);
  _inkSlash(canvas, at - direction * .58, at + direction * .13, core, .061);
  for (final side in [-1.0, 1.0]) {
    final streak =
        at - direction * (.48 + .18 * side) + flank * (side * .14 + shake);
    _inkSlash(canvas, streak - direction * .25, streak, edge, .037);
  }
  _oval(canvas, at, .22, .16, core, stroke: edge, strokeWidth: .038);
}

void _artVaitern(_ArtInk fx) {
  const moon = Color(0xffbdabdf);
  final draw = fx.out;
  for (final side in [-1.0, 1.0]) {
    final radius = .42 + .38 * draw;
    final origin = Offset(.23 + 1.03 * draw, side * (.29 + .48 * draw));
    final sweep = side > 0 ? -.88 + .40 * draw : -1.88 - .40 * draw;
    fx.arc(
      origin,
      radius,
      sweep,
      1.73 - .40 * fx.t,
      .12 * fx.clear + .025,
      moon,
    );
    final tail = origin + Offset(-radius * .37, side * .53);
    fx.stroke(tail, tail - Offset(.61, side * .20), .078, moon, opacity: .42);
  }
}

void _artLinfa(_ArtInk fx, int rank) {
  const moss = Color(0xff72a872);
  const spring = Color(0xffbed19a);
  final growth = fx.out;
  // Leaves move across the silhouette without rotating with the facing.
  for (var shoot = 0; shoot < 3 + rank; shoot++) {
    final angle = shoot * 2.399963;
    final radial = Offset(math.cos(angle), math.sin(angle));
    final spread = .32 + .58 * growth + .08 * (shoot % 2);
    final rise = (.44 + .12 * (shoot % 3)) * growth;
    final root = radial * .18;
    final knee = radial * spread * .52 - Offset(0, rise * .35);
    final tip = radial * spread - Offset(0, rise);
    fx.stroke(root, knee, .072, _artCoal);
    fx.stroke(knee, tip, .055, moss);
    if (growth > .19) {
      final leaf = knee + (tip - knee) * (.42 + .22 * growth);
      final side = Offset(-radial.dy, radial.dx);
      fx.stroke(leaf, tip + side * (.15 * growth), .091, spring);
      fx.stroke(knee, leaf - side * (.19 * growth), .068, moss);
    }
  }
}

void _artPattuglia(_ArtInk fx, int rank) {
  const gold = Color(0xffe9bf78);
  final advance = math.min(1.0, fx.t * 5);
  final retreat = math.max(0.0, (fx.t - .33) * 1.49);
  final reach = 2.9 + rank * .42;
  final back = Offset(.15 + retreat * reach * .61, -.40);
  final tip = Offset(.73 + (reach - .73) * advance, -.31);
  fx.stroke(back, tip, .22, _artCoal);
  fx.stroke(back + const Offset(.14, -.034), tip, .092, gold);
  final cross = Offset(.42 + advance * 1.12, -.39);
  fx.stroke(
    cross - const Offset(.12, .32),
    cross + const Offset(.27, .27),
    .11,
    gold,
    opacity: .80,
  );
}

void _artLame(_ArtInk fx, int rank) {
  const stone = Color(0xff9b93cc);
  const silver = Color(0xffded7ed);
  for (final (i, side) in [-1.0, 1.0].indexed) {
    final phase = ((fx.t - i * .10) / .90).clamp(0.0, 1.0);
    if (phase <= 0) continue;
    final at = Offset(.82 + .56 * phase, side * .40);
    final radius = .91 + rank * .16 + .26 * phase;
    final rotation = side > 0 ? -.67 - .82 * phase : -1.94 + .53 * phase;
    fx.arc(
      at,
      radius,
      rotation,
      .96 + .32 * phase,
      .15 * (1 - phase) + .04,
      stone,
    );
    final trace = at + Offset(math.cos(rotation), math.sin(rotation)) * radius;
    fx.stroke(
      trace,
      trace + Offset(.43 * (1 - phase), side * .19),
      .065,
      silver,
    );
  }
}

void _artCorruzione(_ArtInk fx, int rank) {
  const blood = Color(0xffbb405d);
  const tracer = Color(0xffeb8479);
  final radius = (3.3 + rank * .25) * fx.out;
  for (var claw = 0; claw < 5; claw++) {
    final angle = claw * 2 * math.pi / 5 + fx.t * .33;
    final arm = Offset(math.cos(angle), math.sin(angle));
    final hand = Offset(-arm.dy, arm.dx);
    final at = arm * radius;
    final bend = arm * (radius * .58) + hand * (.44 + .35 * fx.t);
    fx.stroke(arm * (.20 + radius * .11), bend, .23, _artCoal);
    fx.stroke(bend, at, .26, _artCoal);
    fx.stroke(bend - hand * .065, at, .10, blood);
    fx.stroke(
      at - arm * .48 + hand * .14,
      at + hand * .20,
      .062,
      tracer,
      opacity: fx.clear,
    );
  }
}

void _artBrace(_ArtInk fx, int rank) {
  const amber = Color(0xffe77e43);
  const hot = Color(0xfffee0a5);
  final origin = const Offset(.32, -.28);
  for (var ray = 0; ray <= rank; ray++) {
    final angle = (ray - rank / 2) * .27;
    final axis = Offset(math.cos(angle), math.sin(angle));
    final drift = .38 + 1.90 * fx.out;
    final tip = origin + axis * drift;
    final root = origin + axis * (drift * .34);
    fx.stroke(root, tip, .22 - fx.t * .10, _artCoal);
    fx.stroke(root + const Offset(.09, -.04), tip, .097, amber);
    fx.stroke(tip - axis * .27, tip, .060, hot, opacity: fx.clear);
  }
}

void _artBasalto(_ArtInk fx, int rank) {
  const shale = Color(0xff7c655e);
  const rubble = Color(0xffddba95);
  for (var chip = 0; chip < 4 + rank; chip++) {
    final step = chip * .062;
    final lift = ((fx.t - step) / (1 - step)).clamp(0.0, 1.0);
    if (lift <= 0) continue;
    final x = .38 + chip * .47 + lift * .30;
    final y = (chip.isEven ? -.17 : .17) * (1 + lift * 1.35);
    final root = Offset(x, y);
    final point =
        root + Offset(.20 + lift * .29, -.14 - math.sin(lift * math.pi) * .46);
    fx.stroke(
      root - const Offset(.15, .03),
      root + const Offset(.33, -.04),
      .105,
      shale,
      opacity: .65,
    );
    fx.stroke(root, point, .15 - lift * .063, _artCoal);
    fx.stroke(
      root + const Offset(.062, -.021),
      point,
      .051,
      rubble,
      opacity: 1 - lift,
    );
  }
}
