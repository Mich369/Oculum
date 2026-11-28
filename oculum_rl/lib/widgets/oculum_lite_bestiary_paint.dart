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

void _paintMiruscyrus(
  Canvas canvas,
  ui.Image atlas,
  LiteStride? stride,
  double lead, {
  required bool fallen,
  required double fallProgress,
  required bool dashing,
  required bool winding,
  required double release,
  double hurt = 0,
}) {
  const slowSteps = [1, 0, 2, 0];
  const fastSteps = [3, 4, 11, 4];
  final speed = stride?.speed ?? 0;
  final fast =
      speed >= LiteEnemyKind.miruscyrus.speed * .87 && stride?.walking != true;
  final travel = (stride?.distance ?? 0) + speed * lead;
  final step = (travel * (fast ? 4.5 : 3.8)).floor() % 4;
  final strike = math.max(0.0, release - lead);
  final frame = switch ((fallen, dashing, winding, strike)) {
    (true, _, _, _) => fallProgress < .62 ? 9 : 7,
    (_, _, _, > .115) => 6,
    (_, _, _, > 0) => 10,
    (_, true, _, _) => 8,
    (_, _, true, _) => 5,
    _ when hurt > lead => 9,
    _ when speed < .08 => 0,
    _ => (fast ? fastSteps : slowSteps)[step],
  };

  const cell = 256.0;
  const size = 3.45;
  final source = Rect.fromLTWH(
    (frame % 4) * cell,
    (frame ~/ 4) * cell,
    cell,
    cell,
  );
  const destination = Rect.fromLTWH(-size / 2, -size * 235 / cell, size, size);
  canvas.drawImageRect(atlas, source, destination, _monsterSampler);
  if (!fallen && frame == 6) {
    _paintMantisEdge(
      canvas,
      const Rect.fromLTRB(-1.47, -2.05, 1.47, -.12),
      (strike / .24).clamp(0, 1),
    );
  }
}

void _paintCostruttoMinore(
  Canvas canvas,
  ui.Image atlas,
  LiteEnemy enemy,
  double lead, {
  required double fallProgress,
}) {
  const walking = [1, 0, 2, 0];
  const running = [1, 3, 2, 3];
  final speed = enemy.stride.speed;
  final hurrying = speed >= enemy.kind.speed * .9;
  final travel = enemy.stride.distance + speed * lead;
  final step = (travel * (hurrying ? 3.8 : 3.1)).floor() % 4;
  final frame = switch (enemy) {
    _ when enemy.hp <= 0 => fallProgress < .57 ? 6 : 7,
    _ when enemy.strikePose > lead => 5,
    _ when enemy.attacking => 4,
    _ when enemy.hitFlash > lead => 6,
    _ when _enemyIsDashing(enemy) => 3,
    _ when speed < .065 => 0,
    _ => (hurrying ? running : walking)[step],
  };
  const cell = 256.0;
  const size = 2.68;
  final source = Rect.fromLTWH(
    (frame % 4) * cell,
    (frame ~/ 4) * cell,
    cell,
    cell,
  );
  const destination = Rect.fromLTWH(-size / 2, -size * 235 / cell, size, size);
  canvas.drawImageRect(atlas, source, destination, _monsterSampler);
}
