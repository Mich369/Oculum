part of 'oculum_lite_arena.dart';

void _paintErratoMotion(
  Canvas canvas,
  ui.Image atlas,
  LiteErrato kind,
  LiteStride stride,
  double time, {
  required bool casting,
  bool fallen = false,
  double ward = 0,
}) {
  final pose = casting
      ? 3
      : stride.speed < .1
      ? 0
      : (time * (stride.speed > 4 ? 10 : 6.8)).floor() % 2 + 1;
  final frame = Rect.fromLTWH(pose * 240.0, kind.index * 224.0, 240, 224);
  if (fallen) canvas.rotate(-.8);
  canvas.drawImageRect(
    atlas,
    frame,
    Rect.fromLTWH(-1.48, -2.62, 2.92, 2.73),
    Paint()..filterQuality = FilterQuality.medium,
  );
  if (ward > 0) {
    final radius = kind == LiteErrato.veterano ? 1.16 : .87;
    final arc = Rect.fromCenter(
      center: Offset(kind == LiteErrato.veterano ? 0 : .55, -.96),
      width: radius * 2,
      height: 2.28,
    );
    final brush = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final full = kind == LiteErrato.veterano ? 2 * math.pi : 2.22;
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(
        arc.deflate(i * .045),
        -full / 2 + math.sin(time * 4) * .07,
        full - i * .1,
        false,
        brush
          ..strokeWidth = i == 0 ? .10 : .032
          ..color = i == 0 ? const Color(0x974e2b77) : const Color(0xcad4aaf4),
      );
    }
  }
}

void _paintBanditFireMark(Canvas canvas, Offset at, double range, double left) {
  final pulse = (1 - left / .82).clamp(0.0, 1.0);
  final mark = Rect.fromCircle(center: at, radius: range);
  canvas.drawOval(
    mark,
    Paint()..color = Color.fromRGBO(144, 45, 39, .13 + .12 * pulse),
  );
  final rim = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = .075
    ..color = const Color(0xdbe88e64);
  for (var i = 0; i < 8; i++) {
    canvas.drawArc(mark, i * math.pi / 4 + .08, .51 + .12 * pulse, false, rim);
    final theta = i * math.pi / 4;
    final axis = Offset(math.cos(theta), math.sin(theta));
    _inkSlash(
      canvas,
      at + axis * range * .82,
      at + axis * range * .94,
      const Color(0xc5f2b98b),
      .09,
    );
  }
}

void _paintWardenStrike(
  Canvas canvas,
  LiteCombatImpact impact,
  double time,
  double blastRadius,
) {
  final q = ((time - impact.time) / .55).clamp(0.0, 1.0);
  if (q >= 1) return;
  final at = _offset(impact.position);
  final fade = 1 - q;
  if (impact.target == LiteImpactTarget.wardenSwing) {
    final axis = _offset(impact.end ?? impact.position) - at;
    final rect = Rect.fromCircle(
      center: at,
      radius: axis.distance * (.74 + .25 * q),
    );
    final angle = axis.direction;
    final brush = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = .29 * fade
      ..color = Color.fromRGBO(44, 26, 29, .93 * fade);
    canvas.drawArc(rect, angle - 1.59, 3.18, false, brush);
    canvas.drawArc(
      rect,
      angle - 1.58,
      3.16,
      false,
      brush
        ..strokeWidth = .078 * fade
        ..color = Color.fromRGBO(249, 188, 117, .88 * fade),
    );
    return;
  }

  final radius = blastRadius * (.26 + .74 * math.sqrt(q));
  final rim = Rect.fromCircle(center: at, radius: radius);
  final soot = Color.fromRGBO(50, 30, 28, .82 * fade);
  final ember = Color.fromRGBO(246, 156, 91, .94 * fade);
  final brush = Paint()
    ..color = soot
    ..strokeCap = StrokeCap.round
    ..strokeWidth = .25 * fade
    ..style = PaintingStyle.stroke;
  for (var i = 0; i < 7; i++) {
    final angle = i * math.pi * 2 / 7 + q * .22;
    canvas.drawArc(rim, angle, .66 + .11 * q, false, brush..color = soot);
    canvas.drawArc(
      rim.deflate(.16),
      angle + .08,
      .44,
      false,
      brush..color = ember,
    );
    final shaft = Offset(math.cos(angle), math.sin(angle));
    _inkSlash(
      canvas,
      at + shaft * radius * (.52 + .16 * q),
      at + shaft * radius * (1.12 - .10 * (i % 3)),
      i.isEven ? ember : soot,
      (.08 + (i % 3) * .04) * fade,
    );
  }
  if (q < .35) _bombBurst(canvas, at, q);
}

void _paintBanditRopes(Canvas canvas, Offset at, int knots) {
  if (knots <= 0) return;
  final center = at - const Offset(0, .63);
  for (var i = 0; i < math.min(knots + 1, 5); i++) {
    final y = center.dy - i * .082;
    final rope = Path()
      ..moveTo(center.dx - .47, y - .06)
      ..quadraticBezierTo(center.dx, y + .25, center.dx + .48, y - .07);
    final brush = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = .11
      ..color = const Color(0xff241819);
    canvas.drawPath(rope, brush);
    canvas.drawPath(
      rope,
      brush
        ..strokeWidth = .057
        ..color = i.isEven ? const Color(0xffd3a161) : const Color(0xffa5794d),
    );
  }
}
