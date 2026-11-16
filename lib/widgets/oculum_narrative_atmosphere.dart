import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'oculum_theme_presentation.dart';

/// Ambient paint only: the illustration and every interactive control stay still.
class OculumNarrativeAtmosphere extends StatefulWidget {
  const OculumNarrativeAtmosphere({
    super.key,
    required this.themeId,
    required this.accent,
    required this.presentation,
  });
  final String themeId;
  final Color accent;
  final OculumThemePresentation presentation;
  @override
  State<OculumNarrativeAtmosphere> createState() => _AtmosphereState();
}

enum _InkAtmosphere {
  solarGuard(7, Color(0xffa7784f), Color(0xff613c30)),
  solarElite(9, Color(0xffd6a665), Color(0xff855c47)),
  solarGuardian(8, Color(0xffb2936d), Color(0xff675046)),
  senka(8, Color(0xff9080a3), Color(0xff302437));

  const _InkAtmosphere(this.count, this.pigment, this.shade);

  final int count;
  final Color pigment, shade;

  static _InkAtmosphere? forTheme(String id) => switch (id) {
    'guardia_solare' => solarGuard,
    'guardia_solare_elite' => solarElite,
    'guardiano_solare' => solarGuardian,
    'senka_kamaria' => senka,
    _ => null,
  };
}

class _AtmosphereState extends State<OculumNarrativeAtmosphere>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  bool foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncMotion();
  }

  @override
  void didUpdateWidget(covariant OculumNarrativeAtmosphere old) {
    super.didUpdateWidget(old);
    syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    syncMotion();
  }

  void syncMotion() {
    final enabled =
        foreground &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context) &&
        widget.presentation.variant == OculumThemeVariant.alive &&
        widget.presentation.motion != OculumThemeMotion.disabled;
    if (enabled && !clock.isAnimating) clock.repeat();
    if (!enabled && clock.isAnimating) clock.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presentation = widget.presentation;
    if (presentation.variant != OculumThemeVariant.alive ||
        presentation.motion == OculumThemeMotion.disabled) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _AtmospherePainter(
              clock,
              widget.themeId,
              widget.accent,
              presentation.motion == OculumThemeMotion.reduced,
              MediaQuery.disableAnimationsOf(context),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  _AtmospherePainter(
    this.clock,
    this.id,
    this.accent,
    this.reduced,
    this.staticFrame,
  ) : ink = _InkAtmosphere.forTheme(id),
      super(repaint: clock);
  final Animation<double> clock;
  final String id;
  final Color accent;
  final bool reduced, staticFrame;
  final _InkAtmosphere? ink;

  @override
  void paint(Canvas canvas, Size size) {
    final profile = ink;
    if (profile != null) {
      _paintInk(canvas, size, profile);
      return;
    }
    final fire = RegExp(
      'fuoch|lava|demoni|hidenas|ember|solare|granscost',
    ).hasMatch(id);
    final snow = RegExp('ghiaccio|gelo|frost|ice').hasMatch(id);
    final mist = RegExp(
      'nuvol|vento|indigo|cloud|aurora|sogno|acqua|affog',
    ).hasMatch(id);
    final phase = clock.value * math.pi * 2;
    final color = fire
        ? const Color(0xffffb45e)
        : snow
        ? const Color(0xffbce5ff)
        : accent;
    final paint = Paint()..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // Sparse, deterministic trails concentrate on the scenic edge, away from text.
    for (var i = 0; i < (reduced ? 4 : 12); i++) {
      final cycle = (clock.value + (i * 0.61803398875)) % 1;
      final fade = math.sin(cycle * math.pi) * (reduced ? .10 : .19);
      final x =
          size.width * (.71 + .25 * ((i * 0.381966) % 1)) +
          math.sin(phase + i) * (mist ? 12 : 3);
      final y = size.height * (fire ? 1 - cycle : cycle);
      paint.color = color.withValues(alpha: fade);
      if (mist) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(x, y), width: 70 + i * 4, height: 9),
          .1,
          1.8,
          false,
          paint,
        );
      } else {
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(x, y),
          (snow ? 1.6 : .8) + (i % 3) * .3,
          paint,
        );
        if (fire) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x - 1, y + 4),
            paint..strokeWidth = .7,
          );
        }
      }
    }
    canvas.restore();
  }

  void _paintInk(Canvas canvas, Size size, _InkAtmosphere profile) {
    final sparse = reduced || staticFrame;
    final phase = staticFrame ? .34 : clock.value;
    final shade = profile.shade;
    final filament = profile == _InkAtmosphere.senka;
    final grounded = profile == _InkAtmosphere.solarGuardian;
    final paint = Paint();
    final stroke = Path();
    final count = sparse ? 3 : profile.count;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var i = 0; i < count; i++) {
      final cycle = (phase + i * .61803398875) % 1;
      final fade = math.sin(cycle * math.pi);
      final side = i.isEven ? 1.0 : -1.0;
      final inward = .045 + .13 * ((i * .381966) % 1);
      final travel = (cycle - .5) * (sparse ? .009 : .054);
      final x = size.width * ((side > 0 ? inward : 1 - inward) + side * travel);
      final heightBand = (i * .292893 + .17) % 1;
      final baseline = grounded
          ? .68 + heightBand * .27
          : .16 + heightBand * .72;
      final lift = ((sparse ? .024 : .13) * (grounded ? .45 : 1)) * cycle;
      final y = size.height * (baseline - lift);
      final span = math.min(
        size.width * .066,
        (filament ? 37.0 : 18.0) + (i % 3) * 3,
      );
      final width = span * (sparse ? .67 : 1) * side;
      final thickness = grounded
          ? 4.0
          : filament
          ? 2.5
          : 2.0;
      final opacity = fade * (sparse ? .3 : .54);

      // Flat, angular strokes and short broken edges keep the center clear.
      stroke
        ..reset()
        ..moveTo(x, y + thickness)
        ..lineTo(x + width * .38, y - thickness)
        ..lineTo(x + width * .61, y - thickness * .82)
        ..lineTo(x + width, y - thickness * (filament ? 2.6 : 1.9))
        ..lineTo(x + width * .7, y - thickness * .12)
        ..lineTo(x + width * .47, y + thickness * .33)
        ..close();
      paint.color = shade.withValues(alpha: opacity);
      canvas.drawPath(stroke, paint);

      paint
        ..color = profile.pigment.withValues(alpha: opacity * .79)
        ..strokeWidth = grounded ? 1.45 : 1.05;
      canvas.drawLine(
        Offset(x + width * .08, y + thickness * .43),
        Offset(x + width * .39, y - thickness * .69),
        paint,
      );
      if (!sparse || filament) {
        canvas.drawLine(
          Offset(x + width * .65, y - thickness * .98),
          Offset(x + width * (filament ? 1.15 : .94), y - thickness * 1.9),
          paint..strokeWidth = .65,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter old) =>
      old.id != id ||
      old.accent != accent ||
      old.reduced != reduced ||
      old.staticFrame != staticFrame;
}
