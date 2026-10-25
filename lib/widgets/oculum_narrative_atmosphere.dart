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
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _AtmospherePainter(
            clock,
            widget.themeId,
            widget.accent,
            widget.presentation.motion == OculumThemeMotion.reduced,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _AtmospherePainter extends CustomPainter {
  _AtmospherePainter(this.clock, this.id, this.accent, this.reduced)
    : super(repaint: clock);
  final Animation<double> clock;
  final String id;
  final Color accent;
  final bool reduced;
  @override
  void paint(Canvas canvas, Size size) {
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

  @override
  bool shouldRepaint(covariant _AtmospherePainter old) =>
      old.id != id || old.accent != accent || old.reduced != reduced;
}
