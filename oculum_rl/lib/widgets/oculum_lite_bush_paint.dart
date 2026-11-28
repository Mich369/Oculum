part of 'oculum_lite_arena.dart';

typedef _BushInk = ({Color dark, Color body, Color light});

_BushInk _bushParchment(LiteBushKind kind) {
  final colors = switch (kind) {
    LiteBushKind.sterpi => (0xff34231f, 0xff62513a, 0xff9c794d),
    LiteBushKind.felci => (0xff1a2725, 0xff3e5a40, 0xff9b965e),
    LiteBushKind.funghi => (0xff32232e, 0xff73505e, 0xffb98981),
    LiteBushKind.vapori => (0xff26333e, 0xff4b686b, 0xff86bab0),
    LiteBushKind.cristalli => (0xff213c50, 0xff48748a, 0xff8cc2ca),
    LiteBushKind.bulbi => (0xff372237, 0xff754965, 0xffc390a3),
    LiteBushKind.marshmallow => (0xff63394d, 0xffbf8294, 0xffffe4c7),
    LiteBushKind.cenere => (0xff341e24, 0xff69403b, 0xffcc7960),
    LiteBushKind.ombra => (0xff251a2d, 0xff4e3b5c, 0xff8e7198),
    LiteBushKind.corallo => (0xff282e41, 0xff5b5d79, 0xffba8194),
    LiteBushKind.nuvola => (0xff353447, 0xff6e7297, 0xffb5b9ce),
  };
  return (
    dark: Color(colors.$1),
    body: Color(colors.$2),
    light: Color(colors.$3),
  );
}

final _bushStamps = <(LiteBushKind, int, bool), ui.Picture>{};

void _paintBush(Canvas canvas, LiteBush bush, {bool foreground = false}) {
  final picture = _bushStamps.putIfAbsent((bush.kind, bush.id, foreground), () {
    final recorder = ui.PictureRecorder();
    _recordBushStamp(Canvas(recorder), bush, foreground: foreground);
    return recorder.endRecording();
  });
  final at = _offset(bush.center);
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.scale(bush.radiusX, bush.radiusY);
  canvas.drawPicture(picture);
  canvas.restore();
}

void _recordBushStamp(
  Canvas canvas,
  LiteBush bush, {
  required bool foreground,
}) {
  final ink = _bushParchment(bush.kind);
  canvas.save();
  if (!foreground) {
    _oval(canvas, const Offset(0, .04), 2.13, 1.96, const Color(0x6b19131e));
    _oval(canvas, const Offset(0, .13), 1.90, 1.49, ink.dark);
    _dryBrush(
      canvas,
      const Offset(-.74, .48),
      const Offset(.135, .055),
      const Offset(.24, -.09),
      ink.light.withValues(alpha: .42),
      11,
    );
  }
  final brush = math.Random(613 * (bush.kind.index + 1) + bush.id * 57);
  final mask = Path()
    ..addOval(Rect.fromCenter(center: Offset.zero, width: 2.14, height: 2.02));
  canvas.clipPath(mask);
  if (bush.kind == LiteBushKind.marshmallow) {
    _paintMarshmallowPatch(canvas, bush.id, brush, ink, foreground);
    canvas.restore();
    return;
  }
  for (var index = 0; index < 12; index++) {
    final front = index >= 8;
    final x = front ? -.79 + (index - 8) * .46 : -.86 + (index % 6) * .33;
    final y = front ? .52 + (index % 3) * .10 : -.43 + (index % 4) * .19;
    final at = Offset(x + (brush.nextDouble() - .5) * .15, y);
    final size = .76 + brush.nextDouble() * .39;
    if (front != foreground || (front && index == 10 && bush.id.isOdd)) {
      continue;
    }
    final lean = (index.isEven ? -1.0 : 1.0) * (.14 + brush.nextDouble() * .13);
    switch (bush.kind) {
      case LiteBushKind.funghi || LiteBushKind.bulbi:
        _paintBushCaps(
          canvas,
          at,
          ink,
          lean,
          size,
          mushroom: bush.kind == LiteBushKind.funghi,
        );
      case LiteBushKind.cristalli:
        _paintBushShard(canvas, at, ink, lean, size);
      case LiteBushKind.vapori || LiteBushKind.nuvola:
        _paintBushVapor(
          canvas,
          at,
          ink,
          lean,
          size,
          metal: bush.kind == LiteBushKind.vapori,
        );
      default:
        _paintBushFrond(
          canvas,
          at,
          ink,
          lean,
          size,
          branch: bush.kind != LiteBushKind.felci,
        );
    }
  }
  canvas.restore();
}

void _paintMarshmallowPatch(
  Canvas canvas,
  int id,
  math.Random brush,
  _BushInk ink,
  bool foreground,
) {
  const back = [
    Offset(-.72, .01),
    Offset(-.42, -.20),
    Offset(-.07, -.28),
    Offset(.31, -.25),
    Offset(.64, -.05),
    Offset(-.58, .27),
    Offset(-.23, .19),
    Offset(.16, .20),
    Offset(.54, .27),
  ];
  const front = [
    Offset(-.75, .47),
    Offset(-.40, .63),
    Offset(-.02, .68),
    Offset(.32, .60),
    Offset(.70, .44),
  ];
  final points = foreground ? front : back;
  for (final (index, at) in points.indexed) {
    final pink = (index + id) % 4 == 2;
    final tint = pink
        ? (
            dark: const Color(0xff4a2936),
            body: const Color(0xffac6680),
            light: const Color(0xffeab7ad),
          )
        : ink;
    final lean = (brush.nextDouble() - .5) * (foreground ? .91 : .65);
    final size = (foreground ? .78 : .99) + brush.nextDouble() * .23;
    _paintMarshmallow(canvas, at, tint, size, lean);
  }
}

void _paintMarshmallow(
  Canvas canvas,
  Offset at,
  _BushInk ink,
  double size,
  double lean,
) {
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.rotate(lean);
  canvas.scale(size);
  final shape = RRect.fromRectAndRadius(
    const Rect.fromLTWH(-.24, -.55, .48, .64),
    const Radius.circular(.14),
  );
  canvas.drawRRect(shape, Paint()..color = ink.body);
  canvas.drawRRect(
    shape,
    Paint()
      ..color = ink.dark
      ..strokeWidth = .052
      ..style = PaintingStyle.stroke,
  );
  final cap = Path()
    ..moveTo(-.19, -.43)
    ..quadraticBezierTo(-.21, -.57, -.02, -.548)
    ..quadraticBezierTo(.16, -.58, .20, -.445)
    ..quadraticBezierTo(.07, -.365, -.015, -.387)
    ..quadraticBezierTo(-.137, -.365, -.19, -.43);
  canvas.drawPath(cap, Paint()..color = ink.light);
  _dryBrush(
    canvas,
    const Offset(-.16, -.25),
    const Offset(.004, .049),
    const Offset(.28, -.04),
    ink.dark.withValues(alpha: .58),
    5,
    width: .007,
  );
  _lines(
    canvas,
    const [Offset(.172, -.34), Offset(.168, -.13), Offset(.129, -.072)],
    ink.light.withValues(alpha: .59),
    .018,
  );
  canvas.restore();
}

void _paintBushCaps(
  Canvas canvas,
  Offset at,
  _BushInk ink,
  double lean,
  double size, {
  required bool mushroom,
}) {
  final neck = at + Offset(lean * .50, -.31 * size);
  _lines(canvas, [at, neck], ink.dark, .10 * size);
  _lines(
    canvas,
    [at - const Offset(.025, 0), neck],
    ink.light.withValues(alpha: .55),
    .029,
  );
  _oval(
    canvas,
    neck + const Offset(0, -.04),
    (mushroom ? .51 : .39) * size,
    (mushroom ? .26 : .37) * size,
    ink.body,
    stroke: ink.dark,
    strokeWidth: .041,
  );
  _dryBrush(
    canvas,
    neck + const Offset(-.13, -.08),
    const Offset(.045, .026),
    const Offset(.115, -.038),
    ink.light,
    4,
    width: .012,
  );
}

void _paintBushShard(
  Canvas canvas,
  Offset at,
  _BushInk ink,
  double lean,
  double size,
) {
  final tip = at + Offset(lean * .68, -.72 * size);
  final base = at + const Offset(.15, .04);
  final shoulder = Offset.lerp(at, tip, .63)! + const Offset(.13, -.025);
  _poly(
    canvas,
    [
      at - const Offset(.15, .05),
      tip - const Offset(.14, -.05),
      tip,
      shoulder,
      base,
    ],
    ink.body,
    stroke: ink.dark,
    width: .038,
  );
  _poly(canvas, [
    base,
    at - const Offset(.038, .02),
    tip,
    shoulder,
  ], ink.light.withValues(alpha: .57));
  _lines(canvas, [tip, at + const Offset(.02, -.03)], ink.dark, .026);
}

void _paintBushVapor(
  Canvas canvas,
  Offset at,
  _BushInk ink,
  double lean,
  double size, {
  required bool metal,
}) {
  if (metal) {
    _poly(
      canvas,
      [
        at + const Offset(-.24, .045),
        at + const Offset(-.14, -.10),
        at + const Offset(.15, -.10),
        at + const Offset(.25, .025),
        at + const Offset(.11, .14),
        at + const Offset(-.15, .11),
      ],
      ink.dark,
      stroke: const Color(0xff151920),
      width: .045,
    );
    _dryBrush(
      canvas,
      at + const Offset(-.15, .015),
      const Offset(.06, -.014),
      const Offset(.09, .08),
      ink.light,
      5,
      width: .009,
    );
  }
  final tip = at + Offset(lean, -.65 * size);
  final cloud = Path()
    ..moveTo(at.dx - .10, at.dy)
    ..quadraticBezierTo(at.dx - .38, at.dy - .28, tip.dx - .20, tip.dy + .16)
    ..quadraticBezierTo(tip.dx - .24, tip.dy - .08, tip.dx + .025, tip.dy)
    ..quadraticBezierTo(tip.dx + .31, tip.dy - .02, tip.dx + .27, tip.dy + .14)
    ..quadraticBezierTo(at.dx + .30, at.dy - .13, at.dx + .10, at.dy)
    ..close();
  canvas.drawPath(cloud, Paint()..color = ink.body.withValues(alpha: .83));
  _dryBrush(
    canvas,
    tip + const Offset(-.13, .13),
    const Offset(.035, .065),
    const Offset(.29, .01),
    ink.light.withValues(alpha: .74),
    5,
    width: .01,
  );
}

void _paintBushFrond(
  Canvas canvas,
  Offset at,
  _BushInk ink,
  double lean,
  double size, {
  required bool branch,
}) {
  final tip = at + Offset(lean * 1.22, -.76 * size);
  final root = at + const Offset(.015, .05);
  final narrow = branch ? .102 : .18;
  final path = Path()
    ..moveTo(root.dx, root.dy)
    ..quadraticBezierTo(at.dx - narrow, at.dy - .32, tip.dx, tip.dy)
    ..quadraticBezierTo(
      at.dx + narrow + lean * .5,
      at.dy - .26,
      root.dx,
      root.dy,
    )
    ..close();
  canvas.drawPath(path, Paint()..color = ink.body);
  canvas.drawPath(
    path,
    Paint()
      ..color = ink.dark
      ..strokeWidth = .035
      ..style = PaintingStyle.stroke,
  );
  _lines(
    canvas,
    [root, Offset.lerp(root, tip, .53)!, tip],
    ink.light.withValues(alpha: .68),
    .026,
  );
  for (var index = 1; index < 5; index++) {
    final point = Offset.lerp(root, tip, index / 5)!;
    final angle = (index.isEven ? -1 : 1);
    final spread = (.24 - index * .032) * angle;
    final twig = point + Offset(spread, -.13 - (branch ? .04 : 0));
    _poly(
      canvas,
      [point, twig, point + Offset(spread * .54, .028)],
      index.isEven ? ink.body : ink.light.withValues(alpha: .72),
      stroke: ink.dark,
      width: .019,
    );
  }
}

void _paintBushCoverMark(Canvas canvas, Offset foot) {
  final outline = Rect.fromCenter(
    center: foot + const Offset(0, .08),
    width: .93,
    height: .49,
  );
  final line = Paint()
    ..color = const Color(0xd9c5dca4)
    ..style = PaintingStyle.stroke
    ..strokeWidth = .038
    ..strokeCap = StrokeCap.round;
  canvas.drawArc(outline, .32, 1.45, false, line);
  canvas.drawArc(outline, 3.47, 1.45, false, line);
}

void _paintVisionFan(
  Canvas canvas,
  Offset origin,
  List<math.Point<double>> rim,
) {
  if (rim.length < 2) return;
  final tips = rim.map(_offset).toList(growable: false);
  final fan = Path()..addPolygon([origin, ...tips], true);
  canvas.drawPath(fan, Paint()..color = const Color(0x205f3a23));
  final dryEdge = Path();
  for (var index = 1; index < tips.length; index++) {
    final start = Offset.lerp(tips[index - 1], tips[index], .20)!;
    final end = Offset.lerp(tips[index - 1], tips[index], .72)!;
    dryEdge
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
  }
  canvas.drawPath(
    dryEdge,
    Paint()
      ..color = const Color(0x719b704c)
      ..strokeWidth = .036
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round,
  );
}

void _paintSpottingWarning(Canvas canvas, Offset foot, double remaining) {
  final at = foot - const Offset(0, 2.3);
  final circle = Rect.fromCircle(center: at, radius: .35);
  const tint = Color(0xffffcc86);
  canvas.drawCircle(at, .38, Paint()..color = const Color(0xc12d1c23));
  canvas.drawArc(
    circle,
    -math.pi / 2,
    math.pi * 2 * (remaining / 1.3).clamp(0.0, 1.0),
    false,
    Paint()
      ..color = tint
      ..style = PaintingStyle.stroke
      ..strokeWidth = .046
      ..strokeCap = StrokeCap.round,
  );
  _lines(
    canvas,
    [
      at + const Offset(-.20, .005),
      at + const Offset(0, -.11),
      at + const Offset(.20, .005),
      at + const Offset(0, .11),
      at + const Offset(-.20, .005),
    ],
    tint,
    .026,
  );
  _oval(canvas, at, .075, .113, tint);
}

Paint? _concealedHeroPigment(
  Paint? livery,
  bool concealed, {
  bool veil = false,
}) {
  if (!concealed && !veil) return livery;
  return (livery ?? Paint())..color = Color(veil ? 0x37ffffff : 0x73ffffff);
}
