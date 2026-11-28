part of 'oculum_lite_arena.dart';

void _paintBestiaryBody(
  Canvas canvas,
  ui.Image atlas,
  LiteEnemyKind kind,
  LiteStride? stride,
  double time,
  double lead, {
  required bool fallen,
  required bool dashing,
  required bool striking,
  bool quiet = false,
}) {
  final speed = stride?.speed ?? 0;
  final travel = (stride?.distance ?? 0) + speed * lead;
  final rolled = kind.armoredArmadillo && (dashing || quiet && speed > 4.6);
  final running = speed > 3.45 && !quiet;
  final strideB = (travel * (running ? 3.2 : 2.2)).floor().isOdd;
  final index = fallen
      ? 7
      : rolled || dashing
      ? 5
      : striking
      ? 6
      : speed < .08
      ? 0
      : running
      ? 3 + (strideB ? 1 : 0)
      : 1 + (strideB ? 1 : 0);
  final size = kind.bellFly ? 2.30 : 2.55;
  final rise = !fallen && kind.bellFly
      ? (.15 + .031 * math.sin(time * 10))
      : 0.0;
  const side = 256.0;
  final region = Rect.fromLTWH(
    (index % 4) * side,
    (index ~/ 4) * side,
    side,
    side,
  );
  final target = Rect.fromLTWH(
    -size / 2,
    -size * (236 / side) - rise,
    size,
    size,
  );
  canvas.save();
  if (rolled && !fallen) {
    final center = -size * .242;
    canvas.translate(0, center);
    canvas.rotate(travel * 3.8);
    canvas.translate(0, -center);
  }
  canvas.drawImageRect(
    atlas,
    region,
    target,
    Paint()..filterQuality = FilterQuality.medium,
  );
  canvas.restore();
}

void _paintBestiaryCue(Canvas canvas, LiteCombatImpact impact, double age) {
  if (age < 0 || age >= .50) return;
  final at = _offset(impact.position);
  final facing = _offset(impact.end ?? impact.position) - at;
  final t = age / .50;
  final fade = 1 - t;
  if (impact.life == 1) {
    final cone = facing.distance.clamp(.15, math.pi);
    final direction = facing.direction;
    for (var band = 0; band < 3; band++) {
      final phase = (t - band * .12).clamp(0.0, 1.0);
      if (phase <= 0) continue;
      final reach = impact.shield * (.18 + .82 * phase);
      final circle = Rect.fromCircle(center: at, radius: reach);
      for (var brush = 0; brush < 6; brush++) {
        final step = cone * 2 / 6;
        final start = direction - cone + brush * step;
        final off = math.sin(brush * 4.15 + band) * .05;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (.11 + off) * fade + .012
          ..color = const Color(0xff382024).withValues(alpha: fade * .77);
        canvas.drawArc(circle, start, step * .91, false, paint);
        paint
          ..strokeWidth = .036 + .027 * fade
          ..color = const Color(0xffdaa064).withValues(alpha: fade * .86);
        canvas.drawArc(circle, start + step * .03, step * .78, false, paint);
        final middle = start + step * .44;
        final ray = Offset(math.cos(middle), math.sin(middle));
        final glyph = at + ray * (reach + .13 * fade);
        _lines(
          canvas,
          [glyph - ray * .05, glyph + ray * (.17 + band * .035)],
          const Color(0xffffe5ad).withValues(alpha: fade * .68),
          .036,
        );
      }
    }
    return;
  }
  if (facing.distance < .01) return;
  final angle = facing.direction;
  for (var stroke = 0; stroke < 7; stroke++) {
    final skew = (stroke - 3) * .22;
    final ray = Offset(math.cos(angle + skew), math.sin(angle + skew));
    final across = Offset(-ray.dy, ray.dx);
    final chip = at + ray * impact.shield * (.25 + t * .7);
    final taper = .25 + (stroke % 3) * .095;
    _poly(canvas, [
      chip - ray * .16,
      chip + across * .11,
      chip + ray * taper,
      chip - across * .08,
    ], const Color(0xff492e29).withValues(alpha: fade * .85));
    _lines(
      canvas,
      [chip + across * .11, chip + ray * taper],
      const Color(0xffd6a479).withValues(alpha: fade),
      .039,
    );
  }
}
