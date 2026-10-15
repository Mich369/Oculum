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
  dream,
  wood,
  ash,
  acid,
  spirit,
}

String oculumMaterialTexture(OculumGothOrnaments spec) {
  final id = spec.themeId;
  final material = id.contains('ivory') || id.contains('bone')
      ? 'ivory'
      : switch (spec.family) {
          OculumGothFamily.botanical => 'bark',
          OculumGothFamily.crystal => 'crystal',
          OculumGothFamily.forged => 'metal',
          OculumGothFamily.astral => 'astral',
          OculumGothFamily.tide => 'water',
          OculumGothFamily.ember => 'charred',
          OculumGothFamily.dream => 'dream',
          OculumGothFamily.wood => 'wood',
          OculumGothFamily.ash => 'ash',
          OculumGothFamily.acid => 'acid',
          OculumGothFamily.spirit => 'spirit',
          _ => 'stone',
        };
  return 'assets/themes/materials/$material.png';
}

/// Decorative strokes stay in the button's outer frame, leaving its label,
/// icon and hit area untouched.
class OculumButtonFrame extends RoundedRectangleBorder {
  const OculumButtonFrame({
    required this.family,
    required this.ink,
    required this.accent,
    this.opacity = .45,
    this.variant = OculumThemeVariant.still,
    super.side,
    super.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  final OculumGothFamily family;
  final Color ink;
  final Color accent;
  final double opacity;
  final OculumThemeVariant variant;

  @override
  OculumButtonFrame copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
    OculumThemeVariant? variant,
  }) => OculumButtonFrame(
    family: family,
    ink: ink,
    accent: accent,
    opacity: opacity,
    variant: variant ?? this.variant,
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
  );

  @override
  ShapeBorder scale(double t) => OculumButtonFrame(
    family: family,
    ink: ink,
    accent: accent,
    opacity: opacity,
    variant: variant,
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
        variant: variant,
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
        variant: variant,
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
          case OculumGothFamily.dream:
            final cloud = Path()
              ..moveTo(1, 9)
              ..cubicTo(0, 7, 2, 5, 4, 6)
              ..cubicTo(4, 2, 9, 2, 9, 6)
              ..cubicTo(12, 5, 13, 9, 10, 10)
              ..lineTo(2, 10)
              ..close();
            canvas.drawPath(cloud, line);
            canvas.drawLine(const Offset(4, 8), const Offset(10, 8), detail);
          case OculumGothFamily.wood:
            for (var i = 0; i < 3; i++) {
              canvas.drawPath(
                Path()
                  ..moveTo(1, 3 + i * 3)
                  ..cubicTo(5, i * 3, 7, 6 + i * 2, 11, 3 + i * 3),
                i.isEven ? line : detail,
              );
            }
            canvas.drawOval(const Rect.fromLTWH(4, 3, 3, 5), detail);
          case OculumGothFamily.ash:
            for (var i = 0; i < 12; i++) {
              final x = 1.0 + (i * 7 % 11);
              final y = 1.0 + (i * 5 % 10);
              canvas.drawCircle(
                Offset(x, y),
                i % 3 == 0 ? .9 : .4,
                i.isEven ? line : detail,
              );
            }
          case OculumGothFamily.acid:
            final drip = Path()
              ..moveTo(1, 2)
              ..quadraticBezierTo(5, 5, 4, 9)
              ..quadraticBezierTo(3, 12, 6, 12)
              ..quadraticBezierTo(9, 11, 7, 8)
              ..quadraticBezierTo(6, 4, 11, 1);
            canvas.drawPath(drip, line);
            canvas.drawCircle(const Offset(6, 11), .8, detail);
          case OculumGothFamily.spirit:
            canvas.drawOval(const Rect.fromLTWH(3, 1, 6, 10), line);
            canvas.drawCircle(const Offset(6, 4), .7, detail);
            canvas.drawPath(
              Path()
                ..moveTo(4, 8)
                ..quadraticBezierTo(6, 10, 8, 8),
              detail,
            );
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
      other.variant == variant &&
      other.side == side &&
      other.borderRadius == borderRadius;

  @override
  int get hashCode =>
      Object.hash(family, ink, accent, opacity, variant, side, borderRadius);
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
  'dream' || 'sogno' => OculumGothFamily.dream,
  'wood' => OculumGothFamily.wood,
  'ash' => OculumGothFamily.ash,
  'acid' || 'restyle_acido' => OculumGothFamily.acid,
  'spirit' || 'restyle_spiritualita' => OculumGothFamily.spirit,
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
    this.variant = OculumThemeVariant.still,
  });
  final OculumGothFamily family;
  final Color ink, accent;
  final double opacity;
  final bool motion;
  final String themeId;
  final OculumThemeVariant variant;
  @override
  OculumGothOrnaments copyWith({
    OculumGothFamily? family,
    Color? ink,
    Color? accent,
    double? opacity,
    bool? motion,
    String? themeId,
    OculumThemeVariant? variant,
  }) => OculumGothOrnaments(
    family: family ?? this.family,
    ink: ink ?? this.ink,
    accent: accent ?? this.accent,
    opacity: opacity ?? this.opacity,
    motion: motion ?? this.motion,
    themeId: themeId ?? this.themeId,
    variant: variant ?? this.variant,
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
          variant: other.variant,
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

  Duration _themeTransitionDuration(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return Duration.zero;
    return switch (oculumThemePresentation.value.motion) {
      OculumThemeMotion.complete => const Duration(milliseconds: 360),
      OculumThemeMotion.reduced => const Duration(milliseconds: 170),
      OculumThemeMotion.disabled => Duration.zero,
    };
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
              child: RepaintBoundary(
                child: Opacity(
                  opacity: switch (widget.spec.family) {
                    OculumGothFamily.ash => .13,
                    OculumGothFamily.wood => .11,
                    _ => .06,
                  },
                  child: AnimatedSwitcher(
                    duration: _themeTransitionDuration(context),
                    child: Image.asset(
                      oculumMaterialTexture(widget.spec),
                      width: double.infinity,
                      height: double.infinity,
                      key: ValueKey(
                        'theme-material-${widget.spec.themeId}-${widget.spec.family.name}',
                      ),
                      repeat: ImageRepeat.repeat,
                      fit: BoxFit.none,
                      scale: 2,
                      cacheWidth: 512,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      if (widget.spec.family != OculumGothFamily.none &&
          widget.spec.opacity > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: AnimatedSwitcher(
                duration: _themeTransitionDuration(context),
                child: RepaintBoundary(
                  key: ValueKey(
                    'theme-art-${widget.spec.family.name}-${widget.spec.variant.name}-${widget.spec.accent.toARGB32()}',
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: OculumGothPainter(widget.spec),
                        ),
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
        if (spec.family == OculumGothFamily.dream) {
          _driftingClouds(canvas, band, size.height);
        } else if (spec.family == OculumGothFamily.ember) {
          _fallingFlames(canvas, band, size.height);
        } else if (spec.family == OculumGothFamily.acid) {
          _drippingAcid(canvas, band, size.height);
        } else {
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
            _scorchedEdges(canvas, band, size.height);
            break;
          case OculumGothFamily.cathedral:
            _arches(canvas, band, size.height);
            break;
          case OculumGothFamily.dream:
            _clouds(canvas, band, size.height);
            break;
          case OculumGothFamily.wood:
            _woodGrain(canvas, band, size.height);
            break;
          case OculumGothFamily.ash:
            _ashDust(canvas, band, size.height);
            break;
          case OculumGothFamily.acid:
            _acidEdge(canvas, band, size.height);
            break;
          case OculumGothFamily.spirit:
            _spiritMotes(canvas, band, size.height);
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
      case OculumGothFamily.dream:
        for (var i = 0; i < 3; i++) {
          canvas.drawPath(
            Path()
              ..moveTo(3, 9 - i * 2.3)
              ..cubicTo(3, 5 - i * 2.3, 10, 5 - i * 2.3, 11, 8 - i * 2.3),
            stroke,
          );
        }
      case OculumGothFamily.wood:
        for (var i = 0; i < 3; i++) {
          canvas.drawPath(
            Path()
              ..moveTo(3, 5 + i * 3)
              ..quadraticBezierTo(7, 3 + i * 2, 12, 6 + i * 2),
            detail,
          );
        }
      case OculumGothFamily.ash:
        for (var i = 0; i < 12; i++) {
          canvas.drawCircle(
            Offset(3.0 + (i * 7 % 10), 3.0 + (i * 3 % 10)),
            i.isEven ? .65 : .35,
            detail,
          );
        }
      case OculumGothFamily.acid:
        final drip = Path()
          ..moveTo(2, 3)
          ..quadraticBezierTo(6, 6, 5, 10)
          ..quadraticBezierTo(4, 13, 7, 13)
          ..quadraticBezierTo(10, 12, 8, 9)
          ..quadraticBezierTo(7, 5, 12, 2);
        canvas.drawPath(drip, stroke);
        canvas.drawCircle(const Offset(7, 12), 1, detail);
      case OculumGothFamily.spirit:
        canvas.drawOval(const Rect.fromLTWH(4, 3, 7, 10), stroke);
        canvas.drawCircle(const Offset(7.5, 6), .7, detail);
        canvas.drawPath(
          Path()
            ..moveTo(5, 11)
            ..quadraticBezierTo(7.5, 13, 10, 11),
          detail,
        );
      case OculumGothFamily.none:
        break;
    }
  }

  void _fallingFlames(Canvas c, double w, double h) {
    for (var i = 0; i < 6; i++) {
      final t = ((clock?.value ?? 0) + i / 6) % 1;
      final extinction = ((1 - t) / .22).clamp(0.0, 1.0);
      final entry = (t / .06).clamp(0.0, 1.0);
      final visibility = extinction * entry;
      final x = w * .5 + math.sin(t * math.pi * 4 + i) * w * .2;
      final y = t * h;
      c.save();
      c.translate(x, y);
      c.scale(.7 + extinction * .6);
      final flame = Path()
        ..moveTo(0, 5)
        ..cubicTo(-7, 3, -4, -3, -1, -8)
        ..cubicTo(0, -3, 5, -3, 4, 2)
        ..quadraticBezierTo(3, 6, 0, 5)
        ..close();
      c.drawPath(
        flame,
        Paint()
          ..color = const Color(
            0xffe89c4c,
          ).withValues(alpha: spec.opacity * visibility * .8),
      );
      c.drawPath(
        Path()
          ..moveTo(0, 4)
          ..quadraticBezierTo(-3, 0, 0, -3)
          ..quadraticBezierTo(3, 2, 0, 4),
        Paint()
          ..color = const Color(
            0xffffd18a,
          ).withValues(alpha: spec.opacity * visibility),
      );
      c.restore();
    }
  }

  void _scorchedEdges(Canvas c, double w, double h) {
    for (var y = 12.0; y < h; y += 54) {
      c.drawPath(
        Path()
          ..moveTo(w * .25, y)
          ..lineTo(w * .7, y + 11)
          ..lineTo(w * .3, y + 25),
        _paint(spec.ink, stroke: true, width: 2),
      );
    }
  }

  void _woodGrain(Canvas c, double w, double h) {
    for (var i = 0; i < 4; i++) {
      final path = Path()..moveTo(2 + i * w / 5, 0);
      for (var y = 0.0; y < h; y += 30) {
        path.quadraticBezierTo(
          2 + i * w / 5 + math.sin(y / 85) * 3,
          y + 15,
          2 + i * w / 5,
          y + 30,
        );
      }
      c.drawPath(path, _paint(spec.ink, stroke: true, width: .65));
    }
  }

  void _ashDust(Canvas c, double w, double h) {
    for (var i = 0; i < h / 6; i++) {
      c.drawCircle(
        Offset((i * 7 % 19) / 19 * w, i * 6.0),
        i % 3 == 0 ? 1.4 : .5,
        _paint(spec.accent),
      );
    }
  }

  void _acidEdge(Canvas c, double w, double h) {
    for (var y = 14.0; y < h; y += 58) {
      final x = w * (.35 + ((y ~/ 58) % 2) * .2);
      final drop = Path()
        ..moveTo(x - 2.4, y)
        ..quadraticBezierTo(x, y + 3, x + 2.4, y)
        ..lineTo(x + .9, y + 7)
        ..quadraticBezierTo(x, y + 10, x - .9, y + 7)
        ..close();
      c.drawPath(drop, _paint(spec.accent.withValues(alpha: .48)));
      c.drawPath(
        drop,
        _paint(spec.ink.withValues(alpha: .7), stroke: true, width: .55),
      );
      c.drawLine(
        Offset(x - .4, y + 2),
        Offset(x - .2, y + 5),
        _paint(Colors.white.withValues(alpha: .4), stroke: true, width: .4),
      );
    }
  }

  void _drippingAcid(Canvas c, double w, double h) {
    final phase = clock?.value ?? 0;
    for (var i = 0; i < 5; i++) {
      final t = (phase + i / 5) % 1;
      final y = t * (h + 28) - 14;
      final x = w * (.3 + (i % 3) * .2);
      final radius = i.isEven ? 1.7 : 1.1;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: radius * .9,
          height: radius * 2.6,
        ),
        _paint(spec.accent),
      );
      c.drawCircle(
        Offset(x - .4, y - radius * .4),
        radius * .32,
        _paint(Colors.white.withValues(alpha: .65)),
      );
    }
  }

  void _spiritMotes(Canvas c, double w, double h) {
    final phase = clock?.value ?? 0;
    for (var i = 0; i < 8; i++) {
      final t = (phase + i / 8) % 1;
      final y = t * h;
      final x = w * (.5 + math.sin(t * math.pi * 2 + i * .8) * .24);
      final alpha = i.isEven ? .42 : .25;
      final radius = i % 3 == 0 ? 1.6 : .9;
      c.drawCircle(
        Offset(x, y),
        radius,
        _paint(Colors.white.withValues(alpha: alpha)),
      );
      c.drawCircle(
        Offset(x - .3, y - .3),
        radius * .35,
        _paint(Colors.white.withValues(alpha: alpha * .7)),
      );
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

  void _clouds(Canvas c, double w, double h) {
    // Layered cloud contours stay inside the narrow edge gutter.
    final heightStep = spec.variant == OculumThemeVariant.alive ? 48.0 : 62.0;
    for (var y = 12.0; y < h; y += heightStep) {
      final cloud = Path()
        ..moveTo(1, y + 18)
        ..cubicTo(4, y + 8, 10, y + 9, w * .44, y + 12)
        ..cubicTo(w * .5, y - 1, w * .8, y + 1, w - 1, y + 12)
        ..cubicTo(w + 4, y + 24, w * .6, y + 26, 1, y + 18);
      c.drawPath(cloud, _paint(spec.ink, stroke: true, width: 1.8));
      c.drawPath(
        cloud.shift(
          Offset(-1, spec.variant == OculumThemeVariant.alive ? 5 : 3),
        ),
        _paint(spec.accent, stroke: true, width: .75),
      );
      if (spec.variant == OculumThemeVariant.alive) {
        for (var i = 0; i < 3; i++) {
          final x = w * (.22 + i * .27);
          c.drawCircle(
            Offset(x, y + 28),
            i.isEven ? 1.6 : 1,
            _paint(spec.accent),
          );
        }
      }
    }
  }

  void _driftingClouds(Canvas c, double w, double h) {
    // A restrained horizontal drift keeps the Dream theme alive without
    // pulling focus from the sheet or moving any interactive element.
    final phase = (clock?.value ?? 0) * math.pi * 2;
    final step = spec.variant == OculumThemeVariant.alive ? 86.0 : 112.0;
    for (var i = 0, y = 28.0; y < h + step; i++, y += step) {
      final drift =
          math.sin(phase + i * .9) *
          (spec.variant == OculumThemeVariant.alive ? 2.4 : 1.4);
      final cloud = Path()
        ..moveTo(1, y + 7 + drift)
        ..quadraticBezierTo(w * .18, y - 1 + drift, w * .42, y + 6 + drift)
        ..quadraticBezierTo(w * .72, y - 3 + drift, w - 1, y + 8 + drift);
      c.drawPath(cloud, _paint(spec.accent, stroke: true, width: 1.1));
      if (spec.variant == OculumThemeVariant.alive) {
        c.drawCircle(Offset(w * .42, y + 12 + drift), 1.1, _paint(spec.ink));
      }
    }
  }

  @override
  bool shouldRepaint(covariant OculumGothPainter old) =>
      old.spec != spec || old.panel != panel || old.particles != particles;
}
