import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'oculum_element_theme_registry.dart';

String? oculumElementForArtPack(String id) {
  if (id.startsWith('element_pack_')) {
    final element = id.substring(13);
    return oculumElementThemeMotions.containsKey(element) ? element : null;
  }
  for (final entry in oculumElementThemePackIds.entries) {
    if (entry.value == id) return entry.key;
  }
  return null;
}

enum OculumElementAnimationKind {
  glint,
  dust,
  sparks,
  wind,
  waves,
  sound,
  pulse,
  drips,
  lightning,
  vapor,
  prism,
  shadow,
  orbit,
  clouds,
  roots,
  bubbles,
  stars,
  feathers,
  runes,
  burst,
  radiation,
  circuit,
  beam,
  clock,
  petals,
  leaves,
  chains,
  halo,
  healing,
  clarity,
  rays,
  unknown,
}

OculumElementAnimationKind oculumElementAnimationKind(String mode) =>
    switch (mode) {
      'glint' || 'tracks' => OculumElementAnimationKind.glint,
      'dust' || 'ash' || 'grave' || 'spores' => OculumElementAnimationKind.dust,
      'sparks' || 'embers' || 'plasma' => OculumElementAnimationKind.sparks,
      'wind' || 'steam' => OculumElementAnimationKind.wind,
      'waves' => OculumElementAnimationKind.waves,
      'sound' => OculumElementAnimationKind.sound,
      'pulse' || 'iris' => OculumElementAnimationKind.pulse,
      'molten' || 'blood' || 'acid' => OculumElementAnimationKind.drips,
      'lightning' => OculumElementAnimationKind.lightning,
      'vapor' => OculumElementAnimationKind.vapor,
      'prism' || 'frost' => OculumElementAnimationKind.prism,
      'shadow' ||
      'void' ||
      'corruption' ||
      'chaos' => OculumElementAnimationKind.shadow,
      'orbit' ||
      'gravity' ||
      'space' ||
      'souls' => OculumElementAnimationKind.orbit,
      'clouds' => OculumElementAnimationKind.clouds,
      'roots' => OculumElementAnimationKind.roots,
      'bubbles' => OculumElementAnimationKind.bubbles,
      'stars' => OculumElementAnimationKind.stars,
      'feathers' => OculumElementAnimationKind.feathers,
      'runes' => OculumElementAnimationKind.runes,
      'burst' => OculumElementAnimationKind.burst,
      'radiation' => OculumElementAnimationKind.radiation,
      'circuit' => OculumElementAnimationKind.circuit,
      'beam' => OculumElementAnimationKind.beam,
      'clock' => OculumElementAnimationKind.clock,
      'petals' => OculumElementAnimationKind.petals,
      'leaves' => OculumElementAnimationKind.leaves,
      'chains' => OculumElementAnimationKind.chains,
      'halo' => OculumElementAnimationKind.halo,
      'healing' => OculumElementAnimationKind.healing,
      'clarity' => OculumElementAnimationKind.clarity,
      'rays' => OculumElementAnimationKind.rays,
      _ => OculumElementAnimationKind.unknown,
    };

/// A single existing scene clock repaints only this decorative layer. Frames,
/// text and input controls stay stationary. All marks are clipped to the edge.
class OculumElementAmbientPainter extends CustomPainter {
  OculumElementAmbientPainter({
    required this.clock,
    required this.element,
    required this.color,
    this.motion,
    this.reduced = false,
  }) : super(repaint: clock);
  final Animation<double> clock;
  final String element;
  final Color color;
  final String? motion;
  final bool reduced;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final mode = motion ?? oculumElementThemeMotions[element];
    if (mode == null) return;
    final kind = oculumElementAnimationKind(mode);
    final band = math.min(16.0, size.shortestSide * .22);
    final clip = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(
        Rect.fromLTRB(band, band, size.width - band, size.height - band),
      );
    canvas.save();
    canvas.clipPath(clip);
    final count = reduced ? 3 : 10;
    final phase = clock.value;
    for (var i = 0; i < count; i++) {
      final t = (phase * (reduced ? 1 : 3) + i * .137) % 1;
      final fade = math.sin(t * math.pi).abs();
      final left = i.isEven;
      final edge = left ? band * .5 : size.width - band * .5;
      final point = Offset(
        edge + math.sin(t * math.pi * 2 + i) * 2,
        size.height * t,
      );
      final paint = Paint()
        ..color = color.withValues(alpha: (reduced ? .22 : .45) * fade)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      switch (kind) {
        case OculumElementAnimationKind.sparks:
          // The flame descends, shrinks, and is fully extinguished at the foot.
          final radius = (1 - t) * 3 + .4;
          paint.color = color.withValues(alpha: fade * (1 - t) * .7);
          paint.style = PaintingStyle.fill;
          final flame = Path()
            ..moveTo(point.dx, point.dy - 6 * radius / 3)
            ..quadraticBezierTo(
              point.dx - radius * 2,
              point.dy + radius,
              point.dx,
              point.dy + radius * 2,
            )
            ..quadraticBezierTo(
              point.dx + radius * 2,
              point.dy,
              point.dx,
              point.dy - 6 * radius / 3,
            );
          canvas.drawPath(flame, paint);
        case OculumElementAnimationKind.dust:
          paint.style = PaintingStyle.fill;
          canvas.drawCircle(
            Offset(point.dx + math.sin(t * 5 + i) * 3, point.dy),
            .5 + i % 3 * .3,
            paint,
          );
        case OculumElementAnimationKind.drips:
          final path = Path()
            ..moveTo(point.dx, point.dy - 4)
            ..quadraticBezierTo(
              point.dx - 3,
              point.dy + 3,
              point.dx,
              point.dy + 4,
            )
            ..quadraticBezierTo(
              point.dx + 3,
              point.dy + 3,
              point.dx,
              point.dy - 4,
            );
          paint.style = PaintingStyle.fill;
          canvas.drawPath(path, paint);
        case OculumElementAnimationKind.wind:
        case OculumElementAnimationKind.clouds:
          final x = size.width * t;
          final y = i.isEven ? band * .5 : size.height - band * .5;
          if (kind == OculumElementAnimationKind.clouds) {
            paint
              ..style = PaintingStyle.fill
              ..color = Color.lerp(
                const Color(0xFF8AA6D5),
                const Color(0xFFE3B7D5),
                i / count,
              )!.withValues(alpha: .16 * fade);
            canvas.drawOval(
              Rect.fromCenter(
                center: Offset(x, y),
                width: 38.0 + i % 3 * 8,
                height: 8,
              ),
              paint,
            );
            canvas.drawOval(
              Rect.fromCenter(
                center: Offset(x - 9, y - 3),
                width: 16,
                height: 10,
              ),
              paint,
            );
          } else {
            final path = Path()
              ..moveTo(x - 15, y)
              ..quadraticBezierTo(x, y - 5, x + 15, y);
            canvas.drawPath(path, paint);
          }
        case OculumElementAnimationKind.waves:
          final path = Path()
            ..moveTo(edge - 4, point.dy - 12)
            ..cubicTo(
              edge + 5,
              point.dy - 6,
              edge - 5,
              point.dy + 6,
              edge + 4,
              point.dy + 12,
            );
          canvas.drawPath(path, paint);
        case OculumElementAnimationKind.sound:
          canvas.drawCircle(
            Offset(edge, size.height * (i + .5) / count),
            2 + 10 * t,
            paint,
          );
        case OculumElementAnimationKind.lightning:
          if (t < .10 && !reduced) {
            final path = Path()
              ..moveTo(edge, point.dy - 12)
              ..lineTo(edge - 4, point.dy - 2)
              ..lineTo(edge + 4, point.dy)
              ..lineTo(edge, point.dy + 12);
            canvas.drawPath(path, paint..color = color.withValues(alpha: .4));
          }
        case OculumElementAnimationKind.vapor:
        case OculumElementAnimationKind.shadow:
          final path = Path()
            ..moveTo(edge, size.height - point.dy)
            ..cubicTo(
              edge - 6,
              size.height - point.dy - 8,
              edge + 6,
              size.height - point.dy - 16,
              edge,
              size.height - point.dy - 23,
            );
          canvas.drawPath(
            path,
            paint
              ..strokeWidth = kind == OculumElementAnimationKind.vapor ? 2 : 4,
          );
        case OculumElementAnimationKind.orbit:
          final center = Offset(edge, size.height * (i + .5) / count);
          final angle = phase * math.pi * 2 + i;
          final orb = Offset(
            center.dx + math.cos(angle) * 5,
            center.dy + math.sin(angle) * 10,
          );
          paint.style = PaintingStyle.fill;
          canvas.drawCircle(orb, mode == 'souls' ? 1.8 : 1.2, paint);
          if (mode == 'souls') {
            paint.style = PaintingStyle.stroke;
            canvas.drawArc(
              Rect.fromCenter(center: center, width: 10, height: 20),
              angle,
              .9,
              false,
              paint,
            );
          }
        case OculumElementAnimationKind.bubbles:
          canvas.drawCircle(
            Offset(edge, size.height - point.dy),
            1.5 + t * 3,
            paint,
          );
        case OculumElementAnimationKind.prism:
        case OculumElementAnimationKind.stars:
        case OculumElementAnimationKind.runes:
          final center = Offset(edge, size.height * (i + .5) / count);
          final r = 2 + fade * 2;
          final path = Path()
            ..moveTo(center.dx, center.dy - r * 2)
            ..lineTo(center.dx + r, center.dy)
            ..lineTo(center.dx, center.dy + r * 2)
            ..lineTo(center.dx - r, center.dy)
            ..close();
          canvas.drawPath(path, paint);
          if (kind == OculumElementAnimationKind.stars) {
            canvas.drawLine(
              center - Offset(r * 2, 0),
              center + Offset(r * 2, 0),
              paint,
            );
          }
        case OculumElementAnimationKind.petals:
        case OculumElementAnimationKind.leaves:
        case OculumElementAnimationKind.feathers:
          final path = Path()
            ..moveTo(point.dx - 2, point.dy - 4)
            ..quadraticBezierTo(
              point.dx + 5,
              point.dy - 2,
              point.dx + 2,
              point.dy + 4,
            )
            ..quadraticBezierTo(
              point.dx - 5,
              point.dy + 2,
              point.dx - 2,
              point.dy - 4,
            );
          canvas.drawPath(path, paint..style = PaintingStyle.fill);
        case OculumElementAnimationKind.roots:
          final y = size.height * (i + .5) / count;
          final path = Path()
            ..moveTo(edge, y - 8)
            ..lineTo(edge + 3, y)
            ..lineTo(edge - 3, y + 8);
          canvas.drawPath(path, paint);
        case OculumElementAnimationKind.beam:
        case OculumElementAnimationKind.glint:
        case OculumElementAnimationKind.circuit:
          final x = size.width * t,
              y = i.isEven ? band * .5 : size.height - band * .5;
          canvas.drawLine(Offset(x - 8, y), Offset(x + 8, y), paint);
          if (kind == OculumElementAnimationKind.circuit) {
            canvas.drawCircle(Offset(x, y), 2, paint);
          }
        case OculumElementAnimationKind.clock:
          final center = Offset(edge, size.height * (i + .5) / count);
          final hourglass = Path()
            ..moveTo(center.dx - 4, center.dy - 7)
            ..lineTo(center.dx + 4, center.dy - 7)
            ..lineTo(center.dx - 4, center.dy + 7)
            ..lineTo(center.dx + 4, center.dy + 7)
            ..close();
          canvas.drawPath(hourglass, paint);
          canvas.drawCircle(
            Offset(center.dx, center.dy - 2 + t * 5),
            .7,
            paint..style = PaintingStyle.fill,
          );
        case OculumElementAnimationKind.chains:
          final y = size.height * (i + .5) / count;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(edge, y + math.sin(phase * math.pi * 2) * 1.5),
              width: 4,
              height: 9,
            ),
            paint,
          );
        case OculumElementAnimationKind.burst:
        case OculumElementAnimationKind.radiation:
        case OculumElementAnimationKind.rays:
          // Handled as a small radial trace; never a full-screen flash.
          final center = Offset(edge, size.height * (i + .5) / count);
          for (var ray = 0; ray < 3; ray++) {
            final angle = ray * math.pi * 2 / 3 + phase;
            canvas.drawLine(
              center + Offset(math.cos(angle) * 2, math.sin(angle) * 2),
              center + Offset(math.cos(angle) * 7, math.sin(angle) * 7),
              paint,
            );
          }
        case OculumElementAnimationKind.pulse:
        case OculumElementAnimationKind.halo:
        case OculumElementAnimationKind.healing:
        case OculumElementAnimationKind.clarity:
        case OculumElementAnimationKind.unknown:
          final center = Offset(edge, size.height * (i + .5) / count);
          canvas.drawOval(
            Rect.fromCenter(
              center: center,
              width: 4 + fade * 3,
              height: 9 + fade * 4,
            ),
            paint,
          );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OculumElementAmbientPainter old) =>
      old.clock != clock ||
      old.element != element ||
      old.color != color ||
      old.motion != motion ||
      old.reduced != reduced;
}
