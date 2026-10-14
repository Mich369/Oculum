import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'oculum_theme_presentation.dart';

enum OculumGothFamily {
  none,
  botanical,
  crystal,
  forged,
  astral,
  tide,
  ember,
  cathedral,
}

/// Decorative strokes stay in the button's outer frame, leaving its label,
/// icon and hit area untouched.
class OculumButtonFrame extends RoundedRectangleBorder {
  const OculumButtonFrame({
    required this.family,
    required this.ink,
    required this.accent,
    this.opacity = .45,
    super.side,
    super.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  final OculumGothFamily family;
  final Color ink;
  final Color accent;
  final double opacity;

  @override
  OculumButtonFrame copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) => OculumButtonFrame(
    family: family,
    ink: ink,
    accent: accent,
    opacity: opacity,
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
  );

  @override
  ShapeBorder scale(double t) => OculumButtonFrame(
    family: family,
    ink: ink,
    accent: accent,
    opacity: opacity,
    side: side.scale(t),
    borderRadius: borderRadius * t,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is RoundedRectangleBorder) {
      return OculumButtonFrame(
        family: family,
        ink: ink,
        accent: accent,
        opacity: opacity,
        side: BorderSide.lerp(a.side, side, t),
        borderRadius: BorderRadiusGeometry.lerp(
          a.borderRadius,
          borderRadius,
          t,
        )!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is RoundedRectangleBorder) {
      return OculumButtonFrame(
        family: family,
        ink: ink,
        accent: accent,
        opacity: opacity,
        side: BorderSide.lerp(side, b.side, t),
        borderRadius: BorderRadiusGeometry.lerp(
          borderRadius,
          b.borderRadius,
          t,
        )!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    super.paint(canvas, rect, textDirection: textDirection);
    if (family == OculumGothFamily.none ||
        rect.width < 52 ||
        rect.height < 36) {
      return;
    }
    final alpha = (opacity * .62).clamp(.08, .42);
    final line = Paint()
      ..color = accent.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .85
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final detail = Paint()
      ..color = ink.withValues(alpha: alpha * .82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Keep all ornament inside the button's existing padding. The expanded
    // corners make the theme visible at a glance without covering its label.
    const inset = 3.5;
    const reach = 11.0;
    for (final right in [false, true]) {
      for (final bottom in [false, true]) {
        final x = right ? rect.right - inset : rect.left + inset;
        final y = bottom ? rect.bottom - inset : rect.top + inset;
        final sx = right ? -1.0 : 1.0;
        final sy = bottom ? -1.0 : 1.0;
        canvas.save();
        canvas.translate(x, y);
        canvas.scale(sx, sy);
        switch (family) {
          case OculumGothFamily.botanical:
            final stem = Path()
              ..moveTo(0, reach)
              ..cubicTo(1, 5, 5, 7, 7, 3)
              ..quadraticBezierTo(9, 1, reach, 0);
            canvas.drawPath(stem, line);
            for (final leaf in [
              Path()
                ..moveTo(3, 7)
                ..quadraticBezierTo(2, 3, 6, 4)
                ..quadraticBezierTo(7, 7, 3, 7)
                ..close(),
              Path()
                ..moveTo(7, 4)
                ..quadraticBezierTo(7, 0, 10, 1)
                ..quadraticBezierTo(11, 4, 7, 4)
                ..close(),
            ]) {
              canvas.drawPath(leaf, detail);
            }
            canvas.drawCircle(const Offset(4, 8), .8, line);
          case OculumGothFamily.crystal:
            final shard = Path()
              ..moveTo(1, 2)
              ..lineTo(4, 0)
              ..lineTo(reach, 3)
              ..lineTo(4, reach)
              ..lineTo(1, 2);
            canvas.drawPath(shard, line);
            canvas.drawLine(const Offset(4, 1), const Offset(4, 9), detail);
            canvas.drawLine(const Offset(4, 5), const Offset(9, 3), detail);
          case OculumGothFamily.forged:
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                const Rect.fromLTWH(1, 1, 9, 9),
                const Radius.circular(2),
              ),
              line,
            );
            canvas.drawCircle(const Offset(5.5, 5.5), 2.1, detail);
            canvas.drawLine(const Offset(4, 5.5), const Offset(7, 5.5), line);
            canvas.drawCircle(const Offset(2.5, 2.5), .7, detail);
          case OculumGothFamily.astral:
            final star = Path()
              ..moveTo(5.5, 0)
              ..lineTo(6.8, 4.2)
              ..lineTo(reach, 5.5)
              ..lineTo(6.8, 6.8)
              ..lineTo(5.5, reach)
              ..lineTo(4.2, 6.8)
              ..lineTo(0, 5.5)
              ..lineTo(4.2, 4.2)
              ..close();
            canvas.drawPath(star, line);
            canvas.drawCircle(const Offset(5.5, 5.5), 1.5, detail);
            canvas.drawCircle(const Offset(5.5, 5.5), .65, line);
          case OculumGothFamily.tide:
            final curl = Path()
              ..moveTo(0, 2)
              ..cubicTo(3, 0, 3, 6, 6, 6)
              ..cubicTo(9, 6, 8, 2, reach, 2);
            canvas.drawPath(curl, line);
            canvas.drawPath(
              Path()
                ..moveTo(1, 9)
                ..quadraticBezierTo(5, 6, 9, 9),
              detail,
            );
            canvas.drawCircle(const Offset(8, 7), .9, line);
          case OculumGothFamily.ember:
            final flame = Path()
              ..moveTo(2, reach)
              ..quadraticBezierTo(0, 7, 4, 4)
              ..quadraticBezierTo(4, 2, 6, 0)
              ..quadraticBezierTo(6, 4, reach, 5)
              ..quadraticBezierTo(10, 9, 7, reach)
              ..close();
            canvas.drawPath(flame, line);
            canvas.drawPath(
              Path()
                ..moveTo(5, 9)
                ..quadraticBezierTo(4, 7, 7, 5)
                ..quadraticBezierTo(8, 8, 5, 9),
              detail,
            );
          case OculumGothFamily.cathedral:
            final arch = Path()
              ..moveTo(0, reach)
              ..lineTo(0, 5)
              ..quadraticBezierTo(0, 1, 5, 1)
              ..lineTo(reach, 1);
            canvas.drawPath(arch, line);
            canvas.drawPath(
              Path()
                ..moveTo(3, 9)
                ..lineTo(3, 6)
                ..quadraticBezierTo(3, 3, 6, 3)
                ..quadraticBezierTo(9, 3, 9, 6)
                ..lineTo(9, 9),
              detail,
            );
            canvas.drawLine(const Offset(6, 4), const Offset(6, 9), detail);
          case OculumGothFamily.none:
            break;
        }
        canvas.restore();
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      other is OculumButtonFrame &&
      other.family == family &&
      other.ink == ink &&
      other.accent == accent &&
      other.opacity == opacity &&
      other.side == side &&
      other.borderRadius == borderRadius;

  @override
  int get hashCode =>
      Object.hash(family, ink, accent, opacity, side, borderRadius);
}

OculumGothFamily oculumGothFamily(String style) => switch (style) {
  'none' => OculumGothFamily.none,
  'vervain' ||
  'thorn' ||
  'wild_companion' ||
  'slime' ||
  'botanical' => OculumGothFamily.botanical,
  'frost' || 'storm' => OculumGothFamily.crystal,
  'kingi' ||
  'medieval' ||
  'fortress_oculum' ||
  'bolted_metal' ||
  'postea' => OculumGothFamily.forged,
  'lunar' || 'hoshy' || 'shadow_gate' || 'sigil' => OculumGothFamily.astral,
  'tide' => OculumGothFamily.tide,
  'ember' || 'souls' => OculumGothFamily.ember,
  _ => OculumGothFamily.cathedral,
};

@immutable
class OculumGothOrnaments extends ThemeExtension<OculumGothOrnaments> {
  const OculumGothOrnaments({
    required this.family,
    required this.ink,
    required this.accent,
    required this.opacity,
    this.motion = false,
    this.themeId = '',
  });
  final OculumGothFamily family;
  final Color ink, accent;
  final double opacity;
  final bool motion;
  final String themeId;
  @override
  OculumGothOrnaments copyWith({
    OculumGothFamily? family,
    Color? ink,
    Color? accent,
    double? opacity,
    bool? motion,
    String? themeId,
  }) => OculumGothOrnaments(
    family: family ?? this.family,
    ink: ink ?? this.ink,
    accent: accent ?? this.accent,
    opacity: opacity ?? this.opacity,
    motion: motion ?? this.motion,
    themeId: themeId ?? this.themeId,
  );
  @override
  OculumGothOrnaments lerp(covariant OculumGothOrnaments? other, double t) =>
      other == null
      ? this
      : OculumGothOrnaments(
          family: t < .5 ? family : other.family,
          ink: Color.lerp(ink, other.ink, t)!,
          accent: Color.lerp(accent, other.accent, t)!,
          opacity: opacity + (other.opacity - opacity) * t,
          motion: other.motion,
          themeId: other.themeId,
        );
}

/// One animation for the screen; artwork never receives pointer events.
class OculumGothAmbience extends StatefulWidget {
  const OculumGothAmbience({
    super.key,
    required this.child,
    required this.spec,
  });
  final Widget child;
  final OculumGothOrnaments spec;
  @override
  State<OculumGothAmbience> createState() => _OculumGothAmbienceState();
}

class _OculumGothAmbienceState extends State<OculumGothAmbience>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool foreground = true;
  late final AnimationController clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    _motion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion();
  }

  @override
  void didUpdateWidget(OculumGothAmbience old) {
    super.didUpdateWidget(old);
    _motion();
  }

  void _motion() {
    final enabled =
        widget.spec.motion &&
        foreground &&
        TickerMode.valuesOf(context).enabled &&
        oculumThemePresentation.value.motion == OculumThemeMotion.complete &&
        !MediaQuery.disableAnimationsOf(context) &&
        widget.spec.family != OculumGothFamily.none;
    if (enabled && !clock.isAnimating) {
      clock.repeat();
    }
    if (!enabled && clock.isAnimating) {
      clock.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      widget.child,
      if (widget.spec.family != OculumGothFamily.none &&
          widget.spec.opacity > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(painter: OculumGothPainter(widget.spec)),
                  ),
                  if (widget.spec.motion &&
                      !MediaQuery.disableAnimationsOf(context))
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: OculumGothPainter(
                          widget.spec,
                          clock: clock,
                          particles: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

/// Engraved frames and organic ornaments; all geometry stays in the gutter.
class OculumGothPainter extends CustomPainter {
  OculumGothPainter(
    this.spec, {
    this.panel = false,
    this.particles = false,
    this.clock,
  }) : super(repaint: clock);
  final OculumGothOrnaments spec;
  final bool panel, particles;
  final Animation<double>? clock;
  Paint _paint(Color color, {bool stroke = false, double width = 1}) => Paint()
    ..color = color.withValues(
      alpha: (spec.opacity * (panel ? 1.7 : 2)).clamp(0, .85),
    )
    ..style = stroke ? PaintingStyle.stroke : PaintingStyle.fill
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || spec.opacity <= 0) return;
    canvas.save();
    if (panel) {
      final border = Rect.fromLTWH(
        2,
        2,
        math.max(0, size.width - 4),
        math.max(0, size.height - 4),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(border, const Radius.circular(9)),
        _paint(spec.ink, stroke: true),
      );
      canvas.drawLine(
        const Offset(20, 5),
        Offset(size.width - 20, 5),
        _paint(spec.accent, stroke: true, width: .5),
      );
      // The corners carry the theme motif; the text and control area stays clear.
      for (final right in [false, true]) {
        for (final bottom in [false, true]) {
          canvas.save();
          canvas.translate(right ? size.width : 0, bottom ? size.height : 0);
          canvas.scale(right ? -1 : 1, bottom ? -1 : 1);
          final corner = Path()
            ..moveTo(3, 13)
            ..lineTo(3, 7)
            ..quadraticBezierTo(3, 3, 7, 3)
            ..lineTo(13, 3);
          canvas.drawPath(corner, _paint(spec.accent, stroke: true, width: .8));
          _paintPanelCornerMotif(canvas);
          canvas.restore();
        }
      }
      canvas.restore();
      return;
    }
    final band = panel ? 12.0 : (size.width < 600 ? 10.0 : 18.0);
    for (final right in [false, true]) {
      canvas.save();
      if (right) {
        canvas.translate(size.width, 0);
        canvas.scale(-1, 1);
        canvas.translate(0, -17);
      }
      canvas.clipRect(Rect.fromLTWH(0, 0, band, size.height));
      if (particles) {
        for (var i = 0; i < 7; i++) {
          final t = ((clock?.value ?? 0) + i / 7) % 1;
          final y = t * (size.height + 20) - 10;
          final x = band * .5 + math.sin(t * math.pi * 6 + i) * band * .25;
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(t * math.pi * 3 + i);
          if (spec.family == OculumGothFamily.botanical) {
            canvas.drawOval(
              const Rect.fromLTWH(-2, -4, 4, 8),
              _paint(spec.accent),
            );
            canvas.drawLine(
              const Offset(0, -3),
              const Offset(0, 3),
              _paint(spec.ink, stroke: true, width: .4),
            );
          } else {
            canvas.drawCircle(
              Offset.zero,
              i.isEven ? 1.5 : .8,
              _paint(spec.accent),
            );
          }
          canvas.restore();
        }
      } else {
        switch (spec.family) {
          case OculumGothFamily.botanical:
            _vine(canvas, band, size.height);
            break;
          case OculumGothFamily.crystal:
            _crystals(canvas, band, size.height);
            break;
          case OculumGothFamily.forged:
            _metal(canvas, band, size.height);
            break;
          case OculumGothFamily.tide:
            _waves(canvas, band, size.height);
            break;
          case OculumGothFamily.astral:
            _stars(canvas, band, size.height);
            break;
          case OculumGothFamily.ember:
            _candles(canvas, band, size.height);
            break;
          case OculumGothFamily.cathedral:
            _arches(canvas, band, size.height);
            break;
          case OculumGothFamily.none:
            break;
        }
      }
      canvas.restore();
    }
    canvas.restore();
  }

  void _paintPanelCornerMotif(Canvas canvas) {
    final stroke = _paint(spec.accent, stroke: true, width: .7);
    final detail = _paint(spec.ink, stroke: true, width: .55);
    switch (spec.family) {
      case OculumGothFamily.botanical:
        canvas.drawLine(const Offset(4, 10), const Offset(10, 4), stroke);
        for (final point in [const Offset(6, 7), const Offset(9, 5)]) {
          canvas.drawOval(
            Rect.fromCenter(center: point, width: 3, height: 1.8),
            detail,
          );
        }
      case OculumGothFamily.crystal:
        final shard = Path()
          ..moveTo(5, 10)
          ..lineTo(5, 6)
          ..lineTo(8, 4)
          ..lineTo(11, 7)
          ..lineTo(8, 10)
          ..close();
        canvas.drawPath(shard, stroke);
        canvas.drawLine(const Offset(8, 5), const Offset(8, 9), detail);
      case OculumGothFamily.forged:
        canvas.drawCircle(const Offset(8, 8), 2.2, stroke);
        canvas.drawLine(const Offset(6.5, 8), const Offset(9.5, 8), detail);
      case OculumGothFamily.astral:
        canvas.drawLine(const Offset(8, 4), const Offset(8, 12), stroke);
        canvas.drawLine(const Offset(4, 8), const Offset(12, 8), stroke);
        canvas.drawCircle(const Offset(8, 8), 1.4, detail);
      case OculumGothFamily.tide:
        canvas.drawPath(
          Path()
            ..moveTo(4, 7)
            ..quadraticBezierTo(6, 4, 8, 7)
            ..quadraticBezierTo(10, 10, 12, 7),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(4, 10)
            ..quadraticBezierTo(6, 7, 8, 10),
          detail,
        );
      case OculumGothFamily.ember:
        canvas.drawPath(
          Path()
            ..moveTo(6, 11)
            ..quadraticBezierTo(4, 8, 8, 4)
            ..quadraticBezierTo(7, 8, 11, 8)
            ..quadraticBezierTo(11, 11, 6, 11),
          stroke,
        );
      case OculumGothFamily.cathedral:
        canvas.drawPath(
          Path()
            ..moveTo(5, 11)
            ..lineTo(5, 8)
            ..quadraticBezierTo(5, 5, 8, 5)
            ..quadraticBezierTo(11, 5, 11, 8)
            ..lineTo(11, 11),
          stroke,
        );
        canvas.drawLine(const Offset(8, 6), const Offset(8, 11), detail);
      case OculumGothFamily.none:
        break;
    }
  }

  void _vine(Canvas c, double w, double h) {
    final path = Path()..moveTo(w * .5, 0);
    for (var y = 0.0; y < h; y += 64) {
      path.cubicTo(w * 1.1, y + 19, -w * .2, y + 45, w * .5, y + 64);
    }
    c.drawPath(path, _paint(spec.ink, stroke: true, width: 2.1));
    c.drawPath(
      path.shift(const Offset(1, 0)),
      _paint(spec.accent, stroke: true, width: .5),
    );
    for (var i = 0; i * 39 < h; i++) {
      final y = i * 39.0 + 13;
      final side = i.isEven ? 1.0 : -1.0;
      final leaf = Path()
        ..moveTo(w * .5, y)
        ..cubicTo(
          w * .5 + side * 9,
          y - 12,
          w * .5 + side * 10,
          y - 5,
          w * .5,
          y,
        )
        ..close();
      c.drawPath(leaf, _paint(spec.ink));
      c.drawPath(leaf, _paint(spec.accent, stroke: true, width: .5));
      c.drawLine(
        Offset(w * .5, y),
        Offset(w * .5 + side * 6, y - 7),
        _paint(spec.accent, stroke: true, width: .5),
      );
      if (i % 3 == 1) {
        c.save();
        c.translate(w * .45, y + 5);
        for (var p = 0; p < 5; p++) {
          c.rotate(math.pi * 2 / 5);
          c.drawOval(const Rect.fromLTWH(-2, -7, 4, 7), _paint(spec.accent));
          c.drawOval(const Rect.fromLTWH(-.7, -5, 1.4, 4), _paint(spec.ink));
        }
        c.drawCircle(Offset.zero, 1.3, _paint(spec.ink));
        c.restore();
      }
    }
  }

  void _crystals(Canvas c, double w, double h) {
    for (var y = 20.0; y < h; y += 74) {
      final shard = Path()
        ..moveTo(w * .5, y - 14)
        ..lineTo(w - 2, y + 7)
        ..lineTo(w * .5, y + 24)
        ..lineTo(2, y + 7)
        ..close();
      c.drawPath(shard, _paint(spec.accent));
      c.drawPath(shard, _paint(spec.ink, stroke: true));
      c.drawLine(
        Offset(w * .5, y - 12),
        Offset(w * .5, y + 22),
        _paint(spec.ink, stroke: true, width: .6),
      );
    }
  }

  void _metal(Canvas c, double w, double h) {
    c.drawLine(
      Offset(w * .4, 0),
      Offset(w * .4, h),
      _paint(spec.ink, stroke: true, width: 2),
    );
    c.drawLine(
      Offset(w * .7, 0),
      Offset(w * .7, h),
      _paint(spec.accent, stroke: true, width: .5),
    );
    for (var y = 17.0; y < h; y += 62) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(2, y, w - 4, 25),
          const Radius.circular(3),
        ),
        _paint(spec.accent, stroke: true),
      );
      c.drawCircle(Offset(w * .5, y + 12), 2.4, _paint(spec.ink));
      c.drawLine(
        Offset(w * .5 - 1, y + 11),
        Offset(w * .5 + 1, y + 13),
        _paint(spec.accent, stroke: true, width: .6),
      );
    }
  }

  void _waves(Canvas c, double w, double h) {
    for (var y = 0.0; y < h; y += 40) {
      final curl = Path()
        ..moveTo(0, y)
        ..cubicTo(w * 2, y + 4, w * 1.8, y + 29, 0, y + 40);
      c.drawPath(curl, _paint(spec.ink, stroke: true));
      c.drawPath(
        curl.shift(const Offset(-3, 4)),
        _paint(spec.accent, stroke: true, width: .6),
      );
      c.drawCircle(Offset(w * .45, y + 19), 2, _paint(spec.accent));
    }
  }

  void _stars(Canvas c, double w, double h) {
    Offset? previous;
    for (var i = 0; i * 48 < h; i++) {
      final p = Offset(w * (i.isEven ? .3 : .7), i * 48.0 + 18);
      if (previous != null) {
        c.drawLine(previous, p, _paint(spec.ink, stroke: true, width: .5));
      }
      c.drawCircle(p, 1.7, _paint(spec.accent));
      c.drawLine(
        p - const Offset(0, 5),
        p + const Offset(0, 5),
        _paint(spec.ink, stroke: true, width: .5),
      );
      c.drawLine(
        p - const Offset(4, 0),
        p + const Offset(4, 0),
        _paint(spec.ink, stroke: true, width: .5),
      );
      previous = p;
    }
  }

  void _candles(Canvas c, double w, double h) {
    for (var y = 30.0; y < h; y += 98) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .25, y, w * .5, 27),
          const Radius.circular(2),
        ),
        _paint(spec.ink, stroke: true),
      );
      final flame = Path()
        ..moveTo(w * .5, y - 13)
        ..quadraticBezierTo(w, y - 1, w * .5, y - 1)
        ..quadraticBezierTo(0, y - 4, w * .5, y - 13);
      c.drawPath(flame, _paint(spec.accent));
    }
  }

  void _arches(Canvas c, double w, double h) {
    for (var y = 12.0; y < h; y += 78) {
      final arch = Path()
        ..moveTo(2, y + 40)
        ..lineTo(2, y + 13)
        ..quadraticBezierTo(2, y + 6, w * .5, y)
        ..quadraticBezierTo(w - 2, y + 6, w - 2, y + 13)
        ..lineTo(w - 2, y + 40);
      c.drawPath(arch, _paint(spec.ink, stroke: true));
      c.drawCircle(
        Offset(w * .5, y + 21),
        3,
        _paint(spec.accent, stroke: true, width: .6),
      );
      c.drawLine(
        Offset(w * .5, y + 16),
        Offset(w * .5, y + 26),
        _paint(spec.accent, stroke: true, width: .6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant OculumGothPainter old) =>
      old.spec != spec || old.panel != panel || old.particles != particles;
}
