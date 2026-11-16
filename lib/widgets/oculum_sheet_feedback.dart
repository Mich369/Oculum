import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'oculum_goth_ornaments.dart';

enum OculumFeedbackKind {
  lifeDamage,
  shield,
  shieldBroken,
  oculumShield,
  oculumShieldBroken,
  criticalShieldBroken,
  heal,
  oculum,
  will,
  matter,
  buff,
  status,
}

typedef OculumFeedbackTarget = ({String scope, String sheet});

class OculumSheetFeedback {
  const OculumSheetFeedback(
    this.kind,
    this.target, {
    this.amount = 1,
    this.tint,
    this.showSkulls = false,
    this.lifeCapacity,
  });

  final OculumFeedbackKind kind;
  final OculumFeedbackTarget target;
  final int amount;
  final Color? tint;
  final bool showSkulls;
  final int? lifeCapacity;

  double get lifeDamageIntensity {
    final capacity = lifeCapacity;
    final total = capacity != null && capacity > 0 ? capacity : amount + 22;
    if (total <= 0) return 0;
    return (amount / total).clamp(0.0, 1.0).toDouble();
  }
}

/// A transient display layer. Listening starts with the next event, so
/// re-enabling effects or opening another sheet never replays an old impact.
class OculumSheetFeedbackLayer extends StatefulWidget {
  const OculumSheetFeedbackLayer({
    super.key,
    required this.events,
    required this.target,
  });

  final ValueListenable<OculumSheetFeedback?> events;
  final OculumFeedbackTarget target;

  @override
  State<OculumSheetFeedbackLayer> createState() =>
      _OculumSheetFeedbackLayerState();
}

class _OculumSheetFeedbackLayerState extends State<OculumSheetFeedbackLayer> {
  final _active = <OculumFeedbackKind, OculumSheetFeedback>{};
  final _awaitingTarget = <OculumFeedbackKind, OculumSheetFeedback>{};

  @override
  void initState() {
    super.initState();
    widget.events.addListener(_receive);
  }

  @override
  void didUpdateWidget(OculumSheetFeedbackLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events) {
      oldWidget.events.removeListener(_receive);
      widget.events.addListener(_receive);
      _active.clear();
      _awaitingTarget.clear();
    } else if (oldWidget.target != widget.target) {
      _active.clear();
      if (_awaitingTarget.values.firstOrNull?.target == widget.target) {
        _active.addAll(_awaitingTarget);
      }
      _awaitingTarget.clear();
    }
  }

  @override
  void dispose() {
    widget.events.removeListener(_receive);
    super.dispose();
  }

  void _receive() {
    final event = widget.events.value;
    if (event == null) {
      _awaitingTarget.clear();
      if (_active.isNotEmpty) setState(_active.clear);
    } else if (event.target == widget.target) {
      _awaitingTarget.clear();
      setState(() => _recordEffect(_active, event));
    } else {
      // The app overlay adopts the new sheet after the sheet's rebuild.
      // Briefly retain live events during that handoff.
      if (_awaitingTarget.values.firstOrNull?.target != event.target) {
        _awaitingTarget.clear();
      }
      _recordEffect(_awaitingTarget, event);
      final binding = WidgetsBinding.instance;
      binding.addPostFrameCallback((_) {
        binding.addPostFrameCallback((_) {
          if (_awaitingTarget[event.kind] == event) {
            _awaitingTarget.remove(event.kind);
          }
        });
      });
    }
  }

  void _recordEffect(
    Map<OculumFeedbackKind, OculumSheetFeedback> effects,
    OculumSheetFeedback event,
  ) {
    // A break replaces a recent light hit on the same shield.
    switch (event.kind) {
      case OculumFeedbackKind.shield:
      case OculumFeedbackKind.shieldBroken:
        effects.remove(OculumFeedbackKind.shield);
        effects.remove(OculumFeedbackKind.shieldBroken);
      case OculumFeedbackKind.oculumShield:
      case OculumFeedbackKind.oculumShieldBroken:
        effects.remove(OculumFeedbackKind.oculumShield);
        effects.remove(OculumFeedbackKind.oculumShieldBroken);
      default:
        break;
    }
    effects[event.kind] = event;
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final event in _active.values)
            RepaintBoundary(
              key: ObjectKey(event),
              child: _FeedbackAnimation(
                event: event,
                onEnd: () {
                  if (_active[event.kind] == event) {
                    setState(() => _active.remove(event.kind));
                  }
                },
              ),
            ),
        ],
      ),
    ),
  );
}

class _FeedbackAnimation extends StatelessWidget {
  const _FeedbackAnimation({required this.event, required this.onEnd});

  final OculumSheetFeedback event;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final damage = event.kind == OculumFeedbackKind.lifeDamage;
    final damageTint = damage
        ? _lifeDamageTint(
            Theme.of(context).extension<OculumGothOrnaments>()?.accent,
          )
        : null;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
        milliseconds: switch (event.kind) {
          OculumFeedbackKind.lifeDamage ||
          OculumFeedbackKind.heal ||
          OculumFeedbackKind.oculum => 2200,
          OculumFeedbackKind.shieldBroken ||
          OculumFeedbackKind.oculumShieldBroken ||
          OculumFeedbackKind.criticalShieldBroken => 1270,
          _ => 1050,
        },
      ),
      onEnd: onEnd,
      builder: (context, t, _) => CustomPaint(
        painter: _FeedbackPainter(event, t, damageTint),
        child: const SizedBox.expand(),
      ),
    );
  }
}

double _ease(double progress) {
  final t = progress.clamp(0.0, 1.0).toDouble();
  return t * t * (3 - 2 * t);
}

const _defaultLifeDamageTint = Color(0xFFD7344C);

Color _lifeDamageTint(Color? accent) {
  if (accent == null || accent.a < .1) return _defaultLifeDamageTint;
  final hsl = HSLColor.fromColor(accent);
  if (hsl.saturation > .22) {
    if (hsl.hue <= 25 || hsl.hue >= 343) return const Color(0xFF9D1730);
    if (hsl.hue >= 78 && hsl.hue <= 170) return const Color(0xFFFF455E);
  }
  return Color.lerp(
    const Color(0xFFBC203D),
    const Color(0xFFF7485C),
    1 - accent.computeLuminance(),
  )!;
}

class _FeedbackPainter extends CustomPainter {
  _FeedbackPainter(this.event, this.progress, this.damageTint);

  final OculumSheetFeedback event;
  final double progress;
  final Color? damageTint;
  static const _ink = Color(0xFF180F1B);

  double get _lifeInkIntensity {
    final fraction = event.lifeDamageIntensity;
    if (fraction <= .45) return fraction;
    if (fraction <= .60) return .45 + (fraction - .45) * (5 / 3);
    if (fraction <= .70) return .70 + (fraction - .60) * 1.4;
    return .84 + (fraction - .70) * (8 / 15);
  }

  Color get _color =>
      event.tint ??
      switch (event.kind) {
        OculumFeedbackKind.lifeDamage => damageTint ?? _defaultLifeDamageTint,
        OculumFeedbackKind.shield ||
        OculumFeedbackKind.shieldBroken => const Color(0xFF61C5FF),
        OculumFeedbackKind.oculumShield ||
        OculumFeedbackKind.oculumShieldBroken ||
        OculumFeedbackKind.oculum => const Color(0xFFB587FF),
        OculumFeedbackKind.criticalShieldBroken => const Color(0xFFE6BE73),
        OculumFeedbackKind.heal => const Color(0xFF58DFA5),
        OculumFeedbackKind.will => const Color(0xFFD04751),
        OculumFeedbackKind.matter => const Color(0xFF64D6FF),
        OculumFeedbackKind.buff => const Color(0xFFEBC67F),
        OculumFeedbackKind.status => const Color(0xFFD79169),
      };

  @override
  void paint(Canvas canvas, Size size) {
    final fade = _ease(progress / .12) * (1 - _ease((progress - .24) / .74));
    if (fade <= 0 || size.isEmpty) return;
    final unit = math.min(size.width, size.height);
    final center = Offset(size.width * .57, size.height * .45);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _edgeAura(canvas, size, unit, fade);
    switch (event.kind) {
      case OculumFeedbackKind.lifeDamage:
        _lifeDamage(canvas, size, unit);
        if (event.showSkulls) _skulls(canvas, size, unit, progress);
      case OculumFeedbackKind.shield:
      case OculumFeedbackKind.shieldBroken:
      case OculumFeedbackKind.oculumShield:
      case OculumFeedbackKind.oculumShieldBroken:
      case OculumFeedbackKind.criticalShieldBroken:
        _shield(canvas, size, center, unit, fade);
      case OculumFeedbackKind.oculum:
        _oculum(canvas, size, unit, fade);
      case OculumFeedbackKind.matter:
        _matter(canvas, size, unit, fade);
      case OculumFeedbackKind.will:
        _will(canvas, size, fade);
      case OculumFeedbackKind.heal:
        _rise(canvas, center, unit, fade);
      case OculumFeedbackKind.buff:
        _rise(canvas, center, unit, fade);
      case OculumFeedbackKind.status:
        _status(canvas, center, unit, fade);
    }
    canvas.restore();
  }

  void _edgeAura(Canvas canvas, Size size, double unit, double fade) {
    // Pigment settles along the edges, leaving the sheet legible.
    final lifeDamage = event.kind == OculumFeedbackKind.lifeDamage;
    final severity = lifeDamage ? _lifeInkIntensity : 0.0;
    final (depth, strength) = switch (event.kind) {
      OculumFeedbackKind.lifeDamage => (
        .12 + .18 * severity,
        .26 + .52 * severity,
      ),
      OculumFeedbackKind.shieldBroken ||
      OculumFeedbackKind.oculumShieldBroken ||
      OculumFeedbackKind.criticalShieldBroken => (.22, .32),
      OculumFeedbackKind.matter => (.19, .33),
      OculumFeedbackKind.heal => (.17, .29),
      OculumFeedbackKind.will => (.16, .26),
      _ => (.14, .24),
    };
    final bounds = Offset.zero & size;
    final paint = Paint();
    final edgeColor = switch (event.kind) {
      OculumFeedbackKind.lifeDamage => Color.lerp(
        _color,
        Color.lerp(
          const Color(0xFF510B24),
          const Color(0xFF310516),
          _ease((severity - .70) / .30),
        )!,
        severity * .89,
      )!,
      OculumFeedbackKind.shield ||
      OculumFeedbackKind.shieldBroken ||
      OculumFeedbackKind.oculumShield ||
      OculumFeedbackKind.oculumShieldBroken ||
      OculumFeedbackKind.criticalShieldBroken => _color,
      _ => Color.lerp(_ink, _color, .73)!,
    };
    for (final (start, end, span, opacity) in [
      (Alignment.centerLeft, Alignment.centerRight, size.width, strength),
      (
        Alignment.topCenter,
        Alignment.bottomCenter,
        size.height,
        strength * .85,
      ),
    ]) {
      final inset = unit * depth / span;
      final tint = Color.lerp(
        _ink,
        edgeColor,
        .65,
      )!.withValues(alpha: opacity * fade);
      paint.shader = LinearGradient(
        begin: start,
        end: end,
        colors: [tint, Colors.transparent, Colors.transparent, tint],
        stops: [0, inset, 1 - inset, 1],
      ).createShader(bounds);
      canvas.drawRect(bounds, paint);
    }

    // Different geometry and rhythm at the perimeter. Oculum's frame uses
    // paths only, so the particle count is still entirely decided by _oculum.
    final (speed, reach, bend, angular) = switch (event.kind) {
      OculumFeedbackKind.lifeDamage => (.60, .055, .029, true),
      OculumFeedbackKind.shieldBroken ||
      OculumFeedbackKind.oculumShieldBroken ||
      OculumFeedbackKind.criticalShieldBroken => (.66, .08, .027, true),
      OculumFeedbackKind.shield ||
      OculumFeedbackKind.oculumShield => (.39, .12, .012, true),
      OculumFeedbackKind.heal => (.38, .17, .026, false),
      OculumFeedbackKind.oculum => (.48, .13, .016, false),
      OculumFeedbackKind.will => (.36, .19, .034, false),
      OculumFeedbackKind.matter => (.49, .15, .010, true),
      OculumFeedbackKind.buff => (.37, .09, .018, true),
      OculumFeedbackKind.status => (.56, .055, .025, true),
    };
    final topRight = Offset(size.width, 0);
    final bottomRight = Offset(size.width, size.height);
    final bottomLeft = Offset(0, size.height);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    for (final (start, end, inward, phase) in [
      (Offset.zero, topRight, const Offset(0, 1), 0.0),
      (topRight, bottomRight, const Offset(-1, 0), .09),
      (bottomRight, bottomLeft, const Offset(0, -1), .18),
      (bottomLeft, Offset.zero, const Offset(1, 0), .27),
    ]) {
      final strands = (end - start).distance < 580 ? 2 : 3;
      for (var band = 0; band < 2; band++) {
        final inset = unit * (.016 + band * .025);
        for (var strand = 0; strand < strands; strand++) {
          final tip =
              (progress * speed + phase + strand / strands + band * .15) % 1;
          final tail = math.max(0.0, tip - reach);
          final peak = math.sin(math.pi * tip) * fade;
          final from = Offset.lerp(start, end, tail)! + inward * inset;
          final to = Offset.lerp(start, end, tip)! + inward * (inset * .6);
          final turn = Offset.lerp(from, to, .54)! + inward * (unit * bend);
          final filament = Path()..moveTo(from.dx, from.dy);
          if (angular) {
            filament
              ..lineTo(turn.dx, turn.dy)
              ..lineTo(to.dx, to.dy);
          } else {
            filament.quadraticBezierTo(turn.dx, turn.dy, to.dx, to.dy);
          }
          canvas.drawPath(
            filament,
            linePaint
              ..strokeWidth = math.max(3.0, unit * .009)
              ..color = _ink.withValues(alpha: .41 * peak),
          );
          canvas.drawPath(
            filament,
            linePaint
              ..strokeWidth = math.max(1.0, unit * .0028)
              ..color = edgeColor.withValues(alpha: .42 * peak),
          );
          canvas.drawLine(
            turn + inward * (unit * .008),
            Offset.lerp(turn, to, .38)! + inward * (unit * .004),
            linePaint
              ..strokeWidth = 1
              ..color = edgeColor.withValues(alpha: .27 * peak),
          );
        }
      }
    }
  }

  void _lifeDamage(Canvas canvas, Size size, double unit) {
    final severity = _lifeInkIntensity;
    final reveal = _ease(progress / .13);
    final swipe = _ease(progress / .05) * (1 - _ease((progress - .19) / .43));
    final red = Color.lerp(_color, const Color(0xFF54101E), .74)!;
    final paint = Paint();
    // Three cuts have the same direction. The middle one spans the impact.
    for (final row in [-1, 0, 1]) {
      final spread = row * size.height * .082;
      final short = row.abs() * size.width * .092;
      final from = Offset(
        size.width * .132 + short,
        size.height * .67 + spread,
      );
      final tip = Offset(size.width * .868 - short, size.height * .33 + spread);
      final end = Offset.lerp(from, tip, reveal)!;
      final stroke = end - from;
      final normal =
          Offset(-stroke.dy, stroke.dx) / math.max(1.0, stroke.distance);
      final thickness = unit * (row == 0 ? .019 : .012) * (.8 + .5 * severity);
      final left = from + stroke * .23 - normal * (thickness * .40);
      final ridge = from + stroke * .57 - normal * (thickness * .60);
      final nick = from + stroke * .72 + normal * (thickness * .05);
      final shoulder = from + stroke * .86 - normal * (thickness * .31);
      final lip = from + stroke * .46 + normal * (thickness * .63);
      final cut = Path()
        ..addPolygon([from, left, ridge, nick, shoulder, end, lip], true);
      canvas.drawPath(
        cut.shift(normal * (thickness * .26)),
        paint..color = const Color(0xFF310916).withValues(alpha: .78 * swipe),
      );
      canvas.drawPath(cut, paint..color = red.withValues(alpha: .78 * swipe));
      canvas.drawLine(
        left,
        ridge,
        paint
          ..strokeWidth = math.max(1.0, thickness * .095)
          ..color = const Color(0xFF9E3546).withValues(alpha: .72 * swipe),
      );
    }

    final fall = _ease((progress - .08) / .62);
    final blood =
        _ease((progress - .04) / .10) * (1 - _ease((progress - .42) / .51));
    final count = 5 + (8 * severity).round();
    for (var i = 0; i < count; i++) {
      final lane = i ~/ 2;
      final inset = .024 + (lane % 4) * .032;
      final side = i.isEven ? inset : 1 - inset;
      final drift = math.sin(i * 2.3) * unit * .014 * fall;
      final x = size.width * side + drift;
      final y =
          size.height * (.034 + lane * .045 + fall * (.55 + (lane % 3) * .061));
      final drop = unit * (.005 + (i % 4) * .002 + severity * .005);
      final shape = Path()
        ..moveTo(x + drop * .34, y - drop * 1.58)
        ..quadraticBezierTo(
          x - drop * 1.73,
          y + drop * .93,
          x - drop * .32,
          y + drop,
        )
        ..quadraticBezierTo(
          x + drop * 1.23,
          y + drop * .99,
          x + drop * .34,
          y - drop * 1.58,
        )
        ..close();
      canvas.drawPath(
        shape.shift(Offset(drop * .25, drop * .22)),
        paint..color = _ink.withValues(alpha: .69 * blood),
      );
      canvas.drawPath(
        shape,
        paint..color = const Color(0xFF6A172D).withValues(alpha: .86 * blood),
      );
    }
  }

  void _skulls(Canvas canvas, Size size, double unit, double t) {
    final rise = _ease((t - .045) / .49);
    final fade = _ease((t - .035) / .07) * (1 - _ease((t - .21) / .35));
    if (fade <= 0) return;
    final scale = (unit * .032).clamp(7.0, 22.0).toDouble();
    for (var index = 0; index < 6; index++) {
      final left = index.isEven;
      final fraction = index ~/ 2;
      final x =
          (left ? .055 : .945) * size.width +
          (left ? 1 : -1) * unit * (.020 * fraction - .032 * rise);
      final y =
          size.height * (.54 + .105 * fraction) -
          unit * rise * (.18 + .04 * fraction);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((left ? -.31 : .31) + .19 * rise);
      canvas.scale(scale, scale);
      final skull = Path()
        ..moveTo(-.56, .26)
        ..cubicTo(-1.02, -.10, -.84, -.80, -.41, -.93)
        ..quadraticBezierTo(.04, -1.13, .48, -.86)
        ..cubicTo(.92, -.67, .92, -.08, .57, .24)
        ..lineTo(.38, .37)
        ..lineTo(.34, .70)
        ..quadraticBezierTo(0, .84, -.36, .69)
        ..lineTo(-.40, .38)
        ..close();
      canvas.drawPath(
        skull,
        Paint()..color = _color.withValues(alpha: .27 * fade),
      );
      canvas.drawPath(
        skull,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .065
          ..color = Color.lerp(
            _color,
            const Color(0xFFE66870),
            .30,
          )!.withValues(alpha: .26 * fade),
      );
      final sockets = Paint()
        ..color = const Color(0xFF3F1021).withValues(alpha: .35 * fade);
      for (final eye in [-.29, .29]) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(eye, -.13), width: .41, height: .31),
          sockets,
        );
      }
      canvas.drawPath(
        Path()
          ..moveTo(0, .01)
          ..lineTo(-.12, .27)
          ..lineTo(.12, .27)
          ..close(),
        sockets,
      );
      for (final tooth in [-.16, 0.0, .16]) {
        canvas.drawLine(
          Offset(tooth, .50),
          Offset(tooth, .68),
          sockets..strokeWidth = .045,
        );
      }
      canvas.restore();
    }
  }

  void _shield(
    Canvas canvas,
    Size size,
    Offset center,
    double unit,
    double fade,
  ) {
    final offset = switch (event.kind) {
      OculumFeedbackKind.oculumShield ||
      OculumFeedbackKind.oculumShieldBroken => const Offset(.10, 0),
      OculumFeedbackKind.criticalShieldBroken => const Offset(0, -.13),
      _ => const Offset(-.10, 0),
    };
    final broken =
        event.kind != OculumFeedbackKind.shield &&
        event.kind != OculumFeedbackKind.oculumShield;
    final anchor = center + offset * unit;
    final light = Color.lerp(_color, const Color(0xFFFFEFD8), .47)!;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.bevel;
    final fill = Paint();
    final plateFade = fade * (broken ? 1 - _ease((progress - .19) / .23) : 1);
    final radius = unit * (.19 + .13 * _ease(progress / .44));
    const panel = [
      Offset(-.87, -.45),
      Offset(-.37, -.77),
      Offset(.46, -.73),
      Offset(.98, -.31),
      Offset(.88, .28),
      Offset(.39, .63),
      Offset(-.15, .78),
      Offset(-.76, .52),
      Offset(-.96, .06),
    ];
    final rim = [for (final corner in panel) anchor + corner * radius];
    final plate = Path()..addPolygon(rim, true);
    canvas.drawPath(
      plate,
      fill..color = _ink.withValues(alpha: .14 * plateFade),
    );
    canvas.drawPath(
      plate,
      stroke
        ..strokeWidth = math.max(2.5, unit * .008)
        ..color = _ink.withValues(alpha: .63 * plateFade),
    );
    canvas.drawPath(
      plate,
      stroke
        ..strokeWidth = math.max(1.0, unit * .002)
        ..color = light.withValues(alpha: .59 * plateFade),
    );
    for (final i in [0, 2, 5, 7]) {
      final edge = rim[(i + 1) % rim.length];
      canvas.drawLine(
        Offset.lerp(rim[i], edge, .2)!,
        Offset.lerp(rim[i], edge, .8)!,
        stroke
          ..strokeWidth = math.max(1.0, unit * .003)
          ..color = _color.withValues(alpha: .62 * plateFade),
      );
    }
    if (!broken) return;

    final crack =
        _ease((progress - .025) / .09) * (1 - _ease((progress - .22) / .19));
    for (var i = 0; i < rim.length; i++) {
      final edge = rim[i];
      final direction = edge - anchor;
      final normal = Offset(-direction.dy, direction.dx);
      final notch = anchor + direction * .36 + normal * .12;
      final join = anchor + direction * .70 - normal * .09;
      final path = Path()..moveTo(anchor.dx, anchor.dy);
      final branch = Offset.lerp(edge, rim[(i + 1) % rim.length], .39)!;
      path
        ..lineTo(notch.dx, notch.dy)
        ..lineTo(join.dx, join.dy)
        ..lineTo(edge.dx, edge.dy)
        ..moveTo(join.dx, join.dy)
        ..lineTo(branch.dx, branch.dy);
      canvas.drawPath(
        path,
        stroke
          ..strokeWidth = math.max(2.5, unit * .008)
          ..color = _ink.withValues(alpha: .91 * crack),
      );
      canvas.drawPath(
        path,
        stroke
          ..strokeWidth = math.max(1.0, unit * .002)
          ..color = light.withValues(alpha: .88 * crack),
      );
    }
    final flight = _ease((progress - .17) / .79);
    final shardFade = _ease((progress - .15) / .13) * fade;
    for (var i = 0; i < 24; i++) {
      final direction = i * 2.4;
      final distance = .24 + (i % 7) * .035;
      final radiusX = unit * .06 + size.width * flight * distance;
      final radiusY = unit * .06 + size.height * flight * distance;
      final position = anchor.translate(
        radiusX * math.cos(direction),
        radiusY * math.sin(direction) + size.height * .09 * flight * flight,
      );
      final tip = unit * (.012 + (i % 5) * .009) * (1 - .29 * flight);
      final angle = direction + ((i % 5) - 2) * flight;
      final point = position + Offset.fromDirection(angle, tip * 1.58);
      final shoulder = position + Offset.fromDirection(angle + 2.14, tip * .67);
      final heel = position + Offset.fromDirection(angle + 3.50, tip);
      final chip = position + Offset.fromDirection(angle + 4.87, tip * .36);
      final path = Path()..addPolygon([point, shoulder, heel, chip], true);
      canvas.drawPath(
        path,
        fill
          ..color = Color.lerp(
            _ink,
            _color,
            .52,
          )!.withValues(alpha: .72 * shardFade),
      );
      canvas.drawPath(
        Path()..addPolygon([point, shoulder, position], true),
        fill..color = light.withValues(alpha: .61 * shardFade),
      );
      canvas.drawPath(
        path,
        stroke
          ..strokeWidth = math.max(1.0, unit * .003)
          ..color = _ink.withValues(alpha: .83 * shardFade),
      );
      canvas.drawLine(
        point,
        Offset.lerp(point, shoulder, .56)!,
        stroke
          ..strokeWidth = 1
          ..color = light.withValues(alpha: .74 * shardFade),
      );
    }
  }

  void _oculum(Canvas canvas, Size size, double unit, double fade) {
    final count = event.amount.clamp(1, 20);
    final parents = (count + 1) ~/ 2;
    final ascent = _ease(progress);
    final split = _ease((progress - .35) / .35);
    for (var i = 0; i < parents; i++) {
      final x = size.width * (.12 + .76 * (i + .5) / parents);
      final y =
          size.height * (1.06 - 1.26 * ascent) + unit * .08 * math.sin(i * 2.4);
      final offset = unit * split * (.023 + (i % 4) * .008);
      final position = Offset(x + unit * .03 * math.sin(i + progress * 4), y);
      _spark(canvas, position.translate(-offset, 0), unit * .011, fade);
      if (i * 2 + 1 < count && split > 0) {
        _spark(
          canvas,
          position.translate(offset, -offset),
          unit * .010,
          fade * split,
        );
      }
    }
  }

  void _matter(Canvas canvas, Size size, double unit, double fade) {
    final width = math.max(2.0, unit * .007);
    final length = unit * .17;
    final top = size.height * (.92 - .84 * _ease(progress));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.butt
      ..color = Color.lerp(_ink, _color, .73)!.withValues(alpha: .64 * fade);
    for (final x in [size.width * .055, size.width * .945]) {
      canvas.drawLine(
        Offset(x + width, top + width),
        Offset(x + width, top + length),
        Paint()
          ..strokeWidth = width * 1.5
          ..color = _ink.withValues(alpha: .63 * fade),
      );
      canvas.drawLine(Offset(x, top), Offset(x, top + length), paint);
      canvas.drawPath(
        Path()
          ..moveTo(x - length * .20, top + length * .22)
          ..lineTo(x, top)
          ..lineTo(x + length * .20, top + length * .22),
        paint,
      );
    }
  }

  void _will(Canvas canvas, Size size, double fade) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color.lerp(_ink, _color, .60)!.withValues(alpha: .55 * fade),
            Colors.transparent,
          ],
          stops: [0, .28 + .43 * _ease(progress)],
        ).createShader(rect),
    );
  }

  void _rise(Canvas canvas, Offset center, double unit, double fade) {
    final rise = _ease(progress);
    final healing = event.kind == OculumFeedbackKind.heal;
    for (var i = 0; i < 15; i++) {
      final angle = i * 2.4 + rise * (healing ? 5.6 : 1.6);
      final radius = unit * (.10 + (i % 5) * .047);
      final position = center.translate(
        radius * math.cos(angle),
        radius * .50 * math.sin(angle) - unit * (.32 * rise - .10),
      );
      final size = unit * (.008 + (i % 3) * .004);
      _spark(canvas, position, size, fade);
      if (!healing && i % 2 == 0) {
        final rune = Path()
          ..moveTo(position.dx - size, position.dy)
          ..relativeLineTo(size, -size * 1.6)
          ..relativeLineTo(size, size * 1.6)
          ..relativeLineTo(-size, size * 1.6)
          ..close();
        canvas.drawPath(
          rune,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = _color.withValues(alpha: .58 * fade),
        );
      }
    }
  }

  void _status(Canvas canvas, Offset center, double unit, double fade) {
    final rise = _ease(progress);
    for (var i = 0; i < 15; i++) {
      final x =
          center.dx +
          unit * ((i - 7) * .045 + .03 * math.sin(i * 2.3 + progress * 7));
      final y = center.dy + unit * (.31 - .57 * rise + .10 * math.sin(i * 1.8));
      final tail = unit * (.018 + (i % 3) * .012);
      final ember = Path()
        ..moveTo(x - tail * .16, y + tail)
        ..quadraticBezierTo(x - tail * .20, y + tail * .40, x, y)
        ..quadraticBezierTo(
          x + tail * .20,
          y + tail * .40,
          x - tail * .16,
          y + tail,
        );
      canvas.drawPath(
        ember,
        Paint()
          ..color = Color.lerp(
            _ink,
            _color,
            .68,
          )!.withValues(alpha: .54 * fade),
      );
      _spark(canvas, Offset(x, y), tail * .22, fade);
    }
  }

  void _spark(Canvas canvas, Offset position, double radius, double opacity) {
    final top = position.translate(radius * .32, -radius * 1.65);
    final tip = position.translate(radius, radius * -.13);
    final base = position.translate(-radius * .38, radius * 1.36);
    final edge = position.translate(-radius * .93, radius * .12);
    final flake = Path()..addPolygon([top, tip, base, edge], true);
    canvas.drawPath(
      flake.shift(Offset(radius * .29, radius * .32)),
      Paint()..color = _ink.withValues(alpha: .67 * opacity),
    );
    canvas.drawPath(
      flake,
      Paint()
        ..color = Color.lerp(
          _ink,
          _color,
          .71,
        )!.withValues(alpha: .75 * opacity),
    );
    canvas.drawPath(
      Path()..addPolygon([top, tip, position], true),
      Paint()..color = const Color(0xFFBEA17C).withValues(alpha: .43 * opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _FeedbackPainter oldDelegate) =>
      oldDelegate.event != event ||
      oldDelegate.progress != progress ||
      oldDelegate.damageTint != damageTint;
}
