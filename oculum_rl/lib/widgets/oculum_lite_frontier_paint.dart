part of 'oculum_lite_arena.dart';

void _paintFrontierHeld(
  Canvas canvas,
  LiteWeapon equipment,
  ui.Image? art,
  Offset grip,
  double aim,
  double strike,
) {
  if (!equipment.frontierWeapon || art == null) return;
  final wrist = grip + Offset(strike * 1.2, -.08 * strike);
  _drawInkPart(
    canvas,
    art,
    _inkWeapons[equipment]!,
    at: wrist,
    angle: aim.clamp(-.47, .47) - strike,
  );
}

void _paintFrontierCast(Canvas canvas, LiteCombatImpact impact, double age) {
  final choice = impact.life.toInt() - 1;
  if (age < 0 ||
      age > .56 ||
      choice < 0 ||
      choice >= LiteFrontierEffect.values.length)
    return;
  final kind = LiteFrontierEffect.values[choice];
  final origin = _offset(impact.position);
  final end = _offset(impact.end ?? impact.position);
  final t = age / .56;
  final alpha = (1 - t * t).clamp(0.0, 1.0);

  switch (kind) {
    case LiteFrontierEffect.caveCut || LiteFrontierEffect.shaleFan:
      final direction = end - origin;
      if (direction.distance < .05) return;
      final count = kind == LiteFrontierEffect.shaleFan ? 5 : 3;
      final angle = math.atan2(direction.dy, direction.dx);
      final paintedReach =
          direction.distance * (.56 + .44 * math.min(1, t * 3.8));
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      for (var i = 0; i < count; i++) {
        final skew = (i - (count - 1) / 2) * (count == 5 ? .39 : .26);
        final reach = paintedReach * (1 - skew.abs() * .32);
        canvas.save();
        canvas.rotate(angle + skew);
        _poly(canvas, [
          const Offset(.08, .045),
          Offset(reach * .46, -.24 - .16 * alpha),
          Offset(reach, -.045),
          Offset(reach * .73, .055),
          Offset(reach * .35, .11),
        ], const Color(0xff4d2825).withValues(alpha: alpha * .82));
        _poly(canvas, [
          Offset(reach * .19, 0),
          Offset(reach * .53, -.16),
          Offset(reach, -.045),
          Offset(reach * .57, -.012),
        ], const Color(0xffe9b167).withValues(alpha: alpha));
        for (var fleck = 1; fleck < 4; fleck++) {
          final x = reach * (.23 + fleck * .17);
          final y = -.22 - .28 * t - fleck * .024;
          _lines(
            canvas,
            [Offset(x, y), Offset(x + .14 + fleck * .035, y - .04)],
            const Color(0xffffd8ab).withValues(alpha: alpha * .67),
            .034,
          );
        }
        canvas.restore();
      }
      canvas.restore();
    case LiteFrontierEffect.shroud:
      final radius = impact.shield * (.8 + .20 * math.min(t * 3, 1));
      final bounds = Rect.fromCircle(center: origin, radius: radius);
      final rotating = t * 1.3;
      canvas.drawOval(
        bounds,
        Paint()..color = const Color(0xff301c43).withValues(alpha: alpha * .22),
      );
      for (var i = 0; i < 6; i++) {
        final start = i * math.pi / 3 + rotating;
        final body = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .18 * alpha + .025
          ..color = const Color(0xff695180).withValues(alpha: alpha * .64);
        canvas.drawArc(bounds, start, .72, false, body);
        body
          ..strokeWidth = .034
          ..color = const Color(0xffefd8fb).withValues(alpha: alpha * .83);
        canvas.drawArc(bounds.deflate(.05), start + .07, .52, false, body);
        final unit = Offset(math.cos(start), math.sin(start));
        final across = Offset(-unit.dy, unit.dx);
        final tip = origin + unit * (radius * (1 - t * .63));
        _poly(canvas, [
          tip,
          tip + unit * .52 + across * .12,
          tip + unit * .84 - across * .22,
          tip + unit * .29 - across * .10,
        ], const Color(0xffc5aad2).withValues(alpha: alpha * .77));
      }
    case LiteFrontierEffect.coil || LiteFrontierEffect.solder:
      final vector = end - origin;
      if (vector.distance <= .04) return;
      final sideways = Offset(-vector.dy, vector.dx) / vector.distance;
      final segmented = <Offset>[origin];
      for (var k = 1; k <= 8; k++) {
        final zig = .17 * (k.isEven ? 1 : -1) * math.sin(k * .6);
        segmented.add(origin + vector * (k / 9) + sideways * zig);
      }
      segmented.add(end);
      final pigment = kind == LiteFrontierEffect.solder
          ? const Color(0xffff9b5b)
          : const Color(0xff65e6ce);
      _lines(
        canvas,
        segmented,
        const Color(0xff192831).withValues(alpha: alpha),
        .19 * alpha + .016,
      );
      _lines(
        canvas,
        segmented,
        pigment.withValues(alpha: alpha),
        .068 * alpha + .012,
      );
      if (t < .23) {
        _lines(
          canvas,
          segmented,
          const Color(0xfffff7d3).withValues(alpha: alpha),
          .022,
        );
      }
      for (var k = 0; k < 5; k++) {
        final angle = k * math.pi * .4 + t * .7;
        final ray = Offset(math.cos(angle), math.sin(angle));
        _lines(
          canvas,
          [end + ray * t * .46, end + ray * (t * .46 + .23 * alpha)],
          pigment.withValues(alpha: alpha * .8),
          .036,
        );
      }
    case LiteFrontierEffect.fragment:
      final tint = const Color(0xffbfd8f1).withValues(alpha: alpha);
      final radius = .64 + t * .77;
      for (var i = 0; i < 6; i++) {
        final angle = i * math.pi / 3 + t * .90;
        final radial = Offset(math.cos(angle), math.sin(angle));
        final tangent = Offset(-radial.dy, radial.dx);
        final center = end + radial * radius;
        _poly(canvas, [
          center - tangent * .22,
          center + radial * .15,
          center + tangent * .19,
          center - radial * .068,
        ], const Color(0xff4b617a).withValues(alpha: alpha * .66));
        _lines(
          canvas,
          [
            center - tangent * .22,
            center + radial * .15,
            center + tangent * .19,
          ],
          tint,
          .051,
        );
      }
  }
}
