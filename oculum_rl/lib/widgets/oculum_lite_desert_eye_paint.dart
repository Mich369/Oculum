part of 'oculum_lite_arena.dart';

void _paintDesertEyeTerrain(Canvas canvas, LiteRun run, Rect visible) {
  if (run.desertEyeOutcome case final outcome?) {
    final floor = Rect.fromLTWH(0, 0, run.width, run.height);
    final glow = outcome.positive
        ? const Color(0x536cdec7)
        : const Color(0x568e5782);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(17, 11),
          18,
          [glow, const Color(0x73301f3d), const Color(0xb61a122a)],
          [0, .74, 1],
        ),
    );
    _paintCrystalScar(
      canvas,
      const Offset(17, 11),
      radius: 8.1,
      accent: outcome.positive
          ? const Color(0xff81d4bd)
          : const Color(0xffbc8cca),
      alpha: .29,
      phase: run.time,
    );
    return;
  }
  final eye = run.desertEyePosition;
  if (eye == null) return;
  final at = Offset(eye.x, eye.y);
  if (!visible.inflate(2.4).contains(at)) return;
  _paintCrystalScar(
    canvas,
    at,
    radius: 1.45,
    accent: const Color(0xff8cb7dd),
    alpha: 1,
    phase: run.time,
  );
}

void _paintCrystalScar(
  Canvas canvas,
  Offset at, {
  required double radius,
  required Color accent,
  required double alpha,
  required double phase,
}) {
  final depth = radius * .58;
  canvas.save();
  canvas.translate(at.dx, at.dy);
  Path rim(double scale, double sink) => Path()
    ..moveTo(-radius * scale, sink)
    ..lineTo(-radius * .38 * scale, -depth * scale + sink)
    ..lineTo(radius * .72 * scale, -depth * .68 * scale + sink)
    ..lineTo(radius * scale, depth * .13 * scale + sink)
    ..lineTo(radius * .26 * scale, depth * scale + sink)
    ..lineTo(-radius * .78 * scale, depth * .56 * scale + sink)
    ..close();
  final outer = rim(1, 0);
  canvas.drawPath(
    outer,
    Paint()..color = const Color(0xff151320).withValues(alpha: alpha),
  );
  for (var level = 1; level <= 5; level++) {
    final shrink = 1 - level * .147;
    final ring = rim(shrink, depth * level * .074);
    canvas.drawPath(
      ring,
      Paint()
        ..color = Color.lerp(
          accent,
          const Color(0xff111222),
          .45 + level * .10,
        )!.withValues(alpha: alpha),
    );
    canvas.drawPath(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .024
        ..color = accent.withValues(alpha: alpha * (.62 - level * .073)),
    );
  }
  final flicker = .63 + math.sin(phase * 3.2) * .11;
  final pupil = Offset(radius * .026, depth * .29);
  canvas.drawOval(
    Rect.fromCenter(center: pupil, width: radius * .46, height: depth * .43),
    Paint()
      ..color = accent.withValues(alpha: alpha * flicker)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * .15),
  );
  canvas.drawOval(
    Rect.fromCenter(center: pupil, width: radius * .32, height: depth * .32),
    Paint()..color = const Color(0xff0a0b16).withValues(alpha: alpha),
  );
  for (var line = 0; line < 7; line++) {
    final angle = line * math.pi / 3.5 + .11;
    final axis = Offset(math.cos(angle) * radius, math.sin(angle) * depth);
    canvas.drawLine(
      axis * .72,
      axis * (.87 + (line % 3) * .08),
      Paint()
        ..strokeWidth = radius * .026
        ..color = accent.withValues(alpha: alpha * .38),
    );
  }
  canvas.restore();
}
