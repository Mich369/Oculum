import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'oculum_theme_presentation.dart';

enum OculumResourceFxKind { embers, acid, souls }

/// Health colour is interpolated continuously, including at danger thresholds.
Color oculumHealthColor(double fraction) {
  final value = fraction.isFinite ? fraction.clamp(0.0, 1.0) : 0.0;
  const stops = [0.0, .15, .30, .50, .75, 1.0];
  const colors = [
    Color(0xFF6D1028),
    Color(0xFFE53935),
    Color(0xFFFF8C22),
    Color(0xFFF1C40F),
    Color(0xFF2ECC71),
    Color(0xFF66D99A),
  ];
  for (var i = 1; i < stops.length; i++) {
    if (value <= stops[i]) {
      return Color.lerp(
        colors[i - 1],
        colors[i],
        (value - stops[i - 1]) / (stops[i] - stops[i - 1]),
      )!;
    }
  }
  return colors.last;
}

class OculumAnimatedResourceFill extends StatelessWidget {
  const OculumAnimatedResourceFill({
    super.key,
    required this.fraction,
    required this.child,
  });
  final double fraction;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final motion = oculumThemePresentation.value.motion;
    final disabled =
        MediaQuery.disableAnimationsOf(context) ||
        motion == OculumThemeMotion.disabled;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: fraction.isFinite ? fraction.clamp(0.0, 1.0) : 0.0),
      duration: disabled
          ? Duration.zero
          : Duration(
              milliseconds: motion == OculumThemeMotion.reduced ? 140 : 380,
            ),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, content) =>
          FractionallySizedBox(widthFactor: value, child: content),
    );
  }
}

/// Small clipped particles for resource gauges. Decorative only: the painter
/// never handles input and is constrained to the bar's own bounds.
class OculumResourceBarFx extends StatefulWidget {
  const OculumResourceBarFx({
    super.key,
    required this.kind,
    required this.color,
  });

  final OculumResourceFxKind kind;
  final Color color;

  @override
  State<OculumResourceBarFx> createState() => _OculumResourceBarFxState();
}

class _OculumResourceBarFxState extends State<OculumResourceBarFx>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    oculumThemePresentation.addListener(_updateMotion);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  void _updateMotion() {
    final enabled =
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context) &&
        oculumThemePresentation.value.motion == OculumThemeMotion.complete;
    if (enabled && !_clock.isAnimating) {
      _clock.repeat();
    } else if (!enabled && _clock.isAnimating) {
      _clock.stop();
    }
  }

  @override
  void didUpdateWidget(covariant OculumResourceBarFx oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMotion();
  }

  @override
  void dispose() {
    oculumThemePresentation.removeListener(_updateMotion);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: AnimatedBuilder(
          animation: _clock,
          builder: (context, _) => CustomPaint(
            painter: _ResourceFxPainter(
              widget.kind,
              widget.color,
              _clock.value,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
}

class _ResourceFxPainter extends CustomPainter {
  const _ResourceFxPainter(this.kind, this.color, this.phase);

  final OculumResourceFxKind kind;
  final Color color;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (kind == OculumResourceFxKind.souls) {
      for (var i = 0; i < 9; i++) {
        final t = (phase + i / 9) % 1;
        final x = t * size.width;
        final lane = i.isEven ? .25 : .75;
        final y =
            size.height *
            (lane +
                .16 *
                    (i.isEven ? 1 : -1) *
                    (0.5 + 0.5 * math.sin(t * math.pi * 2)));
        final alpha = i.isEven ? .34 : .20;
        final radius = i % 3 == 0 ? 1.25 : .8;
        canvas.drawCircle(
          Offset(x, y),
          radius,
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
        canvas.drawCircle(
          Offset(x - .25, y - .25),
          radius * .35,
          Paint()..color = Colors.white.withValues(alpha: alpha * .7),
        );
      }
      return;
    }
    if (kind == OculumResourceFxKind.embers) {
      for (var i = 0; i < 7; i++) {
        final t = (phase + i / 7) % 1;
        final x = (i * 37.0 + 9) % size.width;
        final y = size.height * (1 - t);
        final fade = (1 - (t - .5).abs() * 2).clamp(.15, .9);
        final paint = Paint()..color = color.withValues(alpha: fade);
        canvas.drawCircle(Offset(x, y), i.isEven ? 1.15 : .75, paint);
        if (i % 3 == 0) {
          canvas.drawLine(
            Offset(x - 1.4, y),
            Offset(x + 1.4, y - 1.3),
            Paint()
              ..color = const Color(0xffffd18a).withValues(alpha: fade * .8)
              ..strokeWidth = .7,
          );
        }
      }
      return;
    }
    for (var i = 0; i < 5; i++) {
      final t = (phase + i / 5) % 1;
      final x = size.width * (.12 + (i * .19) % .78);
      final y = t * size.height;
      final height = (1.2 + size.height * .35).clamp(1.2, 3.5);
      final path = Path()
        ..moveTo(x - .75, y - height * .25)
        ..quadraticBezierTo(x, y, x + .75, y - height * .25)
        ..lineTo(x + .25, y + height * .35)
        ..quadraticBezierTo(x, y + height * .55, x - .25, y + height * .35)
        ..close();
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: .88));
      canvas.drawLine(
        Offset(x - .2, y - height * .1),
        Offset(x - .1, y + height * .2),
        Paint()
          ..color = Colors.white.withValues(alpha: .72)
          ..strokeWidth = .35,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ResourceFxPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.color != color ||
      oldDelegate.phase != phase;
}

class OculumElementMotifClock extends StatefulWidget {
  const OculumElementMotifClock({super.key, required this.child});
  final Widget child;

  @override
  State<OculumElementMotifClock> createState() =>
      _OculumElementMotifClockState();
}

class _OculumElementMotifClockState extends State<OculumElementMotifClock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void initState() {
    super.initState();
    oculumThemePresentation.addListener(_syncMotion);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _syncMotion() {
    final enabled =
        mounted &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context) &&
        oculumThemePresentation.value.motion == OculumThemeMotion.complete;
    if (enabled && !_clock.isAnimating) {
      _clock.repeat();
    } else if (!enabled && _clock.isAnimating) {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    oculumThemePresentation.removeListener(_syncMotion);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _OculumElementMotifScope(clock: _clock, child: widget.child);
}

class _OculumElementMotifScope extends InheritedWidget {
  const _OculumElementMotifScope({required this.clock, required super.child});
  final Animation<double> clock;

  static Animation<double>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_OculumElementMotifScope>()
      ?.clock;

  @override
  bool updateShouldNotify(_OculumElementMotifScope oldWidget) =>
      oldWidget.clock != clock;
}

class OculumElementSigil extends StatelessWidget {
  const OculumElementSigil({
    super.key,
    required this.elementId,
    required this.color,
  });

  final String elementId;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clock = _OculumElementMotifScope.maybeOf(context);
    return Tooltip(
      message: 'Motivo $elementId: animazione solo decorativa',
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: SizedBox(
            width: 24,
            height: 20,
            child: clock == null
                ? CustomPaint(
                    painter: _ElementSigilPainter(elementId, color, 0),
                  )
                : AnimatedBuilder(
                    animation: clock,
                    builder: (context, _) => CustomPaint(
                      painter: _ElementSigilPainter(
                        elementId,
                        color,
                        clock.value,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ElementSigilPainter extends CustomPainter {
  const _ElementSigilPainter(this.rawId, this.color, this.phase);

  final String rawId;
  final Color color;
  final double phase;

  String get id => rawId
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[àáâä]'), 'a')
      .replaceAll(RegExp('[èéêë]'), 'e')
      .replaceAll(RegExp('[ìíîï]'), 'i')
      .replaceAll(RegExp('[òóôö]'), 'o')
      .replaceAll(RegExp('[ùúûü]'), 'u')
      .replaceAll(RegExp('[^a-z0-9]+'), '');

  String get family => switch (id) {
    'fuoco' ||
    'fiamma' ||
    'fire' ||
    'flame' ||
    'lava' ||
    'plasma' ||
    'esplosivo' => 'ember',
    'gelo' ||
    'ghiaccio' ||
    'freddo' ||
    'ice' ||
    'frost' ||
    'cristallo' ||
    'crystal' => 'crystal',
    'acqua' || 'water' || 'vento' || 'wind' => 'tide',
    'acido' ||
    'acid' ||
    'corrosivo' ||
    'veleno' ||
    'poison' ||
    'tossico' ||
    'slime' => 'acid',
    'spirituale' ||
    'spirit' ||
    'sacro' ||
    'holy' ||
    'angelico' ||
    'benedizione' ||
    'cura' ||
    'healing' => 'spirit',
    'sangue' || 'blood' => 'blood',
    'cenere' || 'ash' => 'ash',
    'osso' ||
    'bone' ||
    'necrotico' ||
    'necrotic' ||
    'nonmorto' ||
    'undead' ||
    'morte' => 'bone',
    'oscuro' ||
    'ombra' ||
    'dark' ||
    'shadow' ||
    'vuoto' ||
    'void' ||
    'caos' ||
    'chaos' ||
    'corrotto' ||
    'maledizione' => 'void',
    'natura' ||
    'nature' ||
    'pianta' ||
    'plant' ||
    'radice' ||
    'root' ||
    'flora' ||
    'bestiale' ||
    'beast' => 'leaf',
    'psichico' || 'psychic' || 'sogno' || 'dream' => 'dream',
    'sonoro' || 'suono' || 'sonico' || 'sound' => 'sound',
    'fulmine' ||
    'elettrico' ||
    'lightning' ||
    'tuono' ||
    'radiazione' ||
    'laser' => 'spark',
    'lunare' ||
    'solare' ||
    'luna' ||
    'sole' ||
    'stella' ||
    'star' ||
    'gravita' ||
    'tempo' ||
    'spazio' ||
    'energia' ||
    'magia' ||
    'oculum' ||
    'vapium' ||
    'vero' => 'astral',
    'terra' || 'earth' || 'pietra' => 'stone',
    'metallo' ||
    'metal' ||
    'fisico' ||
    'physical' ||
    'taglio' ||
    'perforante' ||
    'contundente' ||
    'proiettile' ||
    'tecnologia' ||
    'postea' => 'metal',
    _ => 'rune',
  };

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final ink = Paint()..color = color.withValues(alpha: .82);
    final pale = Paint()..color = color.withValues(alpha: .34);
    final phaseAngle = phase * math.pi * 2;
    switch (family) {
      case 'ember':
        for (var i = 0; i < 4; i++) {
          final x = 3 + i * 5.7;
          final y = 3 + ((phase * 12 + i * 4) % 14);
          canvas.drawCircle(Offset(x, y), i.isEven ? 1.3 : .8, ink);
          canvas.drawLine(Offset(x, y + 1), Offset(x - .7, y + 3), pale);
        }
      case 'crystal':
        final path = Path()
          ..moveTo(cx, 1)
          ..lineTo(size.width - 2, cy)
          ..lineTo(cx, size.height - 1)
          ..lineTo(2, cy)
          ..close();
        canvas.drawPath(path, Paint()..color = color.withValues(alpha: .25));
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: .8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .8,
        );
        canvas.drawLine(Offset(cx, 2), Offset(cx, size.height - 2), pale);
      case 'tide':
        for (var row = 0; row < 2; row++) {
          final y = 7.0 + row * 6;
          final p = Path()..moveTo(1, y);
          for (var x = 1.0; x <= size.width + 1; x += 4) {
            p.quadraticBezierTo(x + 1, y - 3, x + 3, y);
          }
          canvas.drawPath(
            p,
            Paint()
              ..color = color.withValues(alpha: row == 0 ? .76 : .36)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }
      case 'acid':
        for (var i = 0; i < 3; i++) {
          final x = 5 + i * 7.0;
          final y = ((phase + i / 3) % 1) * 17;
          final p = Path()
            ..moveTo(x, y)
            ..quadraticBezierTo(x - 2, y + 3, x, y + 6)
            ..quadraticBezierTo(x + 2, y + 3, x, y);
          canvas.drawPath(p, ink);
        }
      case 'spirit':
        for (var i = 0; i < 4; i++) {
          final a = phaseAngle + i * math.pi / 2;
          final x = cx + math.cos(a) * 7.5;
          final y = cy + math.sin(a) * 4.7;
          canvas.drawCircle(Offset(x, y), i.isEven ? 1.35 : .8, pale);
          canvas.drawCircle(Offset(x - .3, y - .3), .45, ink);
        }
      case 'blood':
        final y = 2 + (phase * 14);
        canvas.drawCircle(Offset(cx, y), 2.2, ink);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, y + 2.5), width: 1.8, height: 3),
          pale,
        );
      case 'ash':
        for (var i = 0; i < 8; i++) {
          final x = (i * 7 + phase * 18) % size.width;
          final y = (i * 5 + phase * 12) % size.height;
          canvas.drawCircle(
            Offset(x, y),
            i.isEven ? .9 : .45,
            i.isEven ? ink : pale,
          );
        }
      case 'bone':
        canvas.drawLine(
          Offset(4, cy),
          Offset(size.width - 4, cy),
          ink..strokeWidth = 2,
        );
        for (final x in [4.0, size.width - 4]) {
          canvas.drawCircle(Offset(x, cy), 2.1, pale);
        }
      case 'void':
        canvas.drawCircle(
          Offset(cx, cy),
          6,
          Paint()
            ..color = color.withValues(alpha: .16)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        canvas.drawCircle(
          Offset(cx + math.cos(phaseAngle) * 6, cy + math.sin(phaseAngle) * 5),
          1.4,
          ink,
        );
      case 'leaf':
        for (var i = 0; i < 3; i++) {
          final x = 4 + i * 8.0;
          final y = cy + math.sin(phaseAngle + i) * 3;
          canvas.drawOval(
            Rect.fromCenter(center: Offset(x, y), width: 4.5, height: 2.4),
            i.isEven ? ink : pale,
          );
        }
      case 'dream':
        final p = Path()
          ..moveTo(1, 12)
          ..cubicTo(4, 4, 8, 5, 10, 9)
          ..cubicTo(12, 2, 18, 4, 22, 8);
        canvas.drawPath(
          p,
          Paint()
            ..color = color.withValues(alpha: .66)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        canvas.drawCircle(Offset(8 + math.sin(phaseAngle) * 5, 4), 1, pale);
      case 'sound':
        for (var i = 0; i < 3; i++) {
          final extent = 3 + ((phase + i / 3) % 1) * 7;
          canvas.drawArc(
            Rect.fromCircle(center: Offset(2, cy), radius: extent),
            -math.pi / 3,
            math.pi * 2 / 3,
            false,
            Paint()
              ..color = color.withValues(alpha: .7 - i * .16)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .8,
          );
        }
      case 'spark':
        final x = (phase * size.width) % size.width;
        canvas.drawLine(
          Offset(x, 2),
          Offset(size.width - x * .3, size.height - 3),
          ink..strokeWidth = 1.2,
        );
        canvas.drawCircle(Offset(x, 2), 1.2, pale);
      case 'astral':
        canvas.drawCircle(
          Offset(cx, cy),
          5.5,
          Paint()
            ..color = color.withValues(alpha: .36)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .7,
        );
        final x = cx + math.cos(phaseAngle) * 5.5,
            y = cy + math.sin(phaseAngle) * 5;
        canvas.drawCircle(Offset(x, y), 1.5, ink);
        canvas.drawCircle(Offset(cx, cy), 1, pale);
      case 'stone':
        final p = Path()
          ..moveTo(3, 4)
          ..lineTo(17, 2)
          ..lineTo(22, 10)
          ..lineTo(14, 18)
          ..lineTo(2, 15)
          ..close();
        canvas.drawPath(p, Paint()..color = color.withValues(alpha: .22));
        canvas.drawPath(
          p,
          Paint()
            ..color = color.withValues(alpha: .72)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .8,
        );
      case 'metal':
        final x = 3 + (phase * 18);
        canvas.drawLine(Offset(2, cy), Offset(22, cy), pale..strokeWidth = 2);
        canvas.drawCircle(Offset(x, cy), 2, ink);
        canvas.drawLine(Offset(x - 2, cy - 3), Offset(x + 2, cy + 3), ink);
      default:
        canvas.drawCircle(
          Offset(cx, cy),
          5,
          Paint()
            ..color = color.withValues(alpha: .22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .8,
        );
        canvas.drawLine(Offset(cx - 3, cy), Offset(cx + 3, cy), ink);
        canvas.drawCircle(
          Offset(cx + math.cos(phaseAngle) * 5, cy + math.sin(phaseAngle) * 5),
          1.1,
          ink,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _ElementSigilPainter oldDelegate) =>
      oldDelegate.rawId != rawId ||
      oldDelegate.color != color ||
      oldDelegate.phase != phase;
}
