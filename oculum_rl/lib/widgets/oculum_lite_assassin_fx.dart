part of 'oculum_lite_arena.dart';

void _paintAssassinSweep(
  Canvas canvas,
  LiteCombatImpact impact,
  double time, {
  required bool nearSide,
}) {
  final point = impact.end;
  if (point == null) return;
  final axis = point - impact.position;
  final reach = axis.magnitude;
  if (reach < .01) return;
  final open = impact.shield == 1;
  final span = open ? .58 : .37;
  final delay = nearSide ? .048 : 0.0;
  final progress = (time - impact.time - delay) / (span - delay);
  if (progress <= 0 || progress >= 1) return;
  final side = nearSide ? 1.0 : -1.0;
  final fade = math.pow(1 - progress, 1.15).toDouble();
  final swing = 1 - math.pow(1 - progress, 4).toDouble();

  final origin = _offset(impact.position);
  canvas.save();
  canvas.translate(origin.dx, origin.dy - .46);
  canvas.rotate(math.atan2(axis.y, axis.x));
  final curve = Path()
    ..moveTo(-reach * (open ? .69 : .48), side * reach * .50)
    ..cubicTo(
      -reach * .48,
      side * reach * -.06,
      reach * .35,
      side * reach * -.53,
      reach * .99,
      side * reach * -.48,
    );
  final metric = curve.computeMetrics().first;
  final lit = metric.extractPath(0, metric.length * swing);
  void stroke(Color tone, double width) {
    canvas.drawPath(
      lit,
      Paint()
        ..color = tone
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  final outer = <Offset>[];
  final inner = <Offset>[];
  for (var i = 0; i <= 16; i++) {
    final phase = i / 16;
    final tangent = metric.getTangentForOffset(metric.length * swing * phase);
    if (tangent == null) continue;
    final normal = Offset(-tangent.vector.dy, tangent.vector.dx) * side;
    final width = reach * (open ? .19 : .12) * math.sin(phase * math.pi);
    outer.add(tangent.position + normal * width * (i.isEven ? 1 : .71));
    inner.add(tangent.position - normal * width * .09);
  }
  canvas.drawPath(
    Path()..addPolygon([...outer, ...inner.reversed], true),
    Paint()..color = Color.fromRGBO(33, 32, 51, .82 * fade),
  );
  stroke(Color.fromRGBO(91, 132, 130, .90 * fade), reach * .059);
  stroke(Color.fromRGBO(240, 218, 174, .96 * fade), reach * .023);
  if (metric.getTangentForOffset(metric.length * swing) case final edge?) {
    final flick = edge.vector * reach * (.18 + progress * .09);
    _inkSlash(
      canvas,
      edge.position - flick,
      edge.position + flick * .24,
      Color.fromRGBO(250, 236, 195, .78 * fade),
      reach * .035,
    );
  }

  final hairs = Path();
  for (var index = 0; index < 13; index++) {
    final t = .19 + .052 * index;
    if (t > swing) break;
    final tangent = metric.getTangentForOffset(metric.length * t);
    if (tangent == null) continue;
    final drift = Offset(-tangent.vector.dy, tangent.vector.dx) * side;
    final edge = tangent.position + drift * reach * (.041 + .02 * (index % 4));
    hairs.addPolygon([
      edge - tangent.vector * reach * (.10 + .02 * (index % 3)),
      edge + drift * reach * .013,
      edge,
    ], true);
  }
  canvas.drawPath(
    hairs,
    Paint()..color = Color.fromRGBO(187, 166, 125, .60 * fade),
  );
  if (open && progress > .27 && progress < .72) {
    final spark = (.72 - progress) * 1.9;
    final center = Offset(reach * .13, 0);
    for (final ray in const [
      Offset(.28, .37),
      Offset(-.32, .24),
      Offset(.37, -.21),
      Offset(-.27, -.33),
    ]) {
      _inkSlash(
        canvas,
        center,
        center + ray * reach * spark,
        Color.fromRGBO(235, 213, 159, .84 * fade),
        .025 + .04 * fade,
      );
    }
  }
  canvas.restore();
}

void _paintAssassinVeil(Canvas canvas, Offset at, double remaining) {
  final oval = Rect.fromCenter(
    center: at + const Offset(0, .12),
    width: 1.36,
    height: .53,
  );
  canvas.drawArc(
    oval,
    -math.pi / 2,
    2 * math.pi * (remaining / 3).clamp(0.0, 1.0),
    false,
    Paint()
      ..color = const Color(0xc5c1dbc8)
      ..strokeWidth = .039
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke,
  );
}

void _paintMateriaDodge(Canvas canvas, Offset at, double age) {
  if (age < 0 || age >= .34) return;
  final phase = age / .34;
  final fade = 1 - phase;
  final center = at - const Offset(0, .66);
  for (var i = 0; i < 5; i++) {
    final side = i.isEven ? -1 : 1;
    final x = side * (.30 + phase * (1.08 + i * .11));
    final y = (i - 2) * .18;
    final tip = center + Offset(x, y - phase * .17);
    final base = tip - Offset(side * (.24 + fade * .41), -.13);
    _inkSlash(
      canvas,
      base,
      tip,
      Color.fromRGBO(35, 57, 70, .85 * fade),
      .16 * fade,
    );
    _inkSlash(
      canvas,
      base,
      tip,
      Color.fromRGBO(188, 221, 230, .96 * fade),
      .058 * fade,
    );
  }
}

void _paintAssassinBox(
  Canvas canvas,
  ui.Image art,
  Offset at,
  LiteStride stride,
  double time, {
  required bool inBush,
}) {
  final walk = (stride.speed / 2.4).clamp(0.0, 1.0);
  final phase = time * 15;
  final lift = math.sin(phase).abs() * .085 * walk;
  final tilt = math.sin(phase) * .035 * walk;
  const width = 1.72;
  final height = width * art.height / art.width;
  _shadow(canvas, at, .66, .25, alpha: .53 - lift);
  canvas.save();
  canvas.translate(at.dx, at.dy - lift);
  canvas.rotate(tilt);
  canvas.drawImageRect(
    art,
    Rect.fromLTWH(0, 0, art.width.toDouble(), art.height.toDouble()),
    Rect.fromLTWH(-width / 2, -height, width, height),
    Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color(inBush ? 0x8fffffff : 0xffffffff),
  );
  canvas.restore();
}
