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
  });

  final OculumFeedbackKind kind;
  final OculumFeedbackTarget target;
  final int amount;
  final Color? tint;
  final bool showSkulls;
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
    }
    if (oldWidget.events != widget.events ||
        oldWidget.target != widget.target) {
      _active.clear();
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
      if (_active.isNotEmpty) setState(_active.clear);
    } else if (event.target == widget.target) {
      setState(() {
        // Each shield has one effect. A break replaces a recent light hit.
        switch (event.kind) {
          case OculumFeedbackKind.shield:
          case OculumFeedbackKind.shieldBroken:
            _active.remove(OculumFeedbackKind.shield);
            _active.remove(OculumFeedbackKind.shieldBroken);
          case OculumFeedbackKind.oculumShield:
          case OculumFeedbackKind.oculumShieldBroken:
            _active.remove(OculumFeedbackKind.oculumShield);
            _active.remove(OculumFeedbackKind.oculumShieldBroken);
          default:
            break;
        }
        _active[event.kind] = event;
      });
    }
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
          OculumFeedbackKind.oculumShieldBroken => 1270,
          _ => 1050,
        },
      ),
      onEnd: onEnd,
      // This is the approved stand-alone scratch texture. It is decoded only
      // when an enabled feedback layer receives a real Life impact.
      child: damage
          ? FractionallySizedBox(
              widthFactor: .90,
              heightFactor: .80,
              child: Image.asset(
                'assets/oculum/home_art/sheet_damage_scratch.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                color: damageTint?.withValues(alpha: .35),
                colorBlendMode: BlendMode.srcATop,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            )
          : null,
      builder: (context, t, scratch) => CustomPaint(
        painter: _FeedbackPainter(event, t, damageTint),
        child: scratch == null
            ? const SizedBox.expand()
            : Opacity(
                opacity: _ease(t / .06) * (1 - _ease((t - .12) / .45)),
                child: scratch,
              ),
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

  Color get _color =>
      event.tint ??
      switch (event.kind) {
        OculumFeedbackKind.lifeDamage => damageTint ?? _defaultLifeDamageTint,
        OculumFeedbackKind.shield ||
        OculumFeedbackKind.shieldBroken => const Color(0xFF61C5FF),
        OculumFeedbackKind.oculumShield ||
        OculumFeedbackKind.oculumShieldBroken ||
        OculumFeedbackKind.oculum => const Color(0xFFB587FF),
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
        if (event.showSkulls) _skulls(canvas, size, unit, progress);
      case OculumFeedbackKind.shield:
      case OculumFeedbackKind.shieldBroken:
      case OculumFeedbackKind.oculumShield:
      case OculumFeedbackKind.oculumShieldBroken:
        _shield(canvas, center, unit, fade);
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
    // Four softly lit edges, with a transparent center under the sheet.
    final (depth, strength) = switch (event.kind) {
      OculumFeedbackKind.lifeDamage => (.18, .29),
      OculumFeedbackKind.matter => (.19, .33),
      OculumFeedbackKind.heal => (.17, .29),
      OculumFeedbackKind.will => (.16, .26),
      _ => (.14, .24),
    };
    final bounds = Offset.zero & size;
    final paint = Paint();
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
      final tint = _color.withValues(alpha: opacity * fade);
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
      OculumFeedbackKind.oculumShieldBroken => (.66, .08, .027, true),
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
      ..strokeCap = StrokeCap.round;
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
              ..color = _color.withValues(alpha: .11 * peak),
          );
          canvas.drawPath(
            filament,
            linePaint
              ..strokeWidth = math.max(1.0, unit * .0028)
              ..color = _color.withValues(alpha: .42 * peak),
          );
        }
      }
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

  void _shield(Canvas canvas, Offset center, double unit, double fade) {
    final oculum =
        event.kind == OculumFeedbackKind.oculumShield ||
        event.kind == OculumFeedbackKind.oculumShieldBroken;
    final broken =
        event.kind == OculumFeedbackKind.shieldBroken ||
        event.kind == OculumFeedbackKind.oculumShieldBroken;
    final light = Color.lerp(_color, Colors.white, .42)!;
    final anchor = center.translate((oculum ? 1 : -1) * unit * .09, 0);
    final ringFade = fade * (broken ? 1 - _ease((progress - .20) / .23) : 1);
    for (var ring = 0; ring < 3; ring++) {
      final radius =
          unit *
          (.13 + .24 * _ease(progress / (.52 + ring * .10)) + ring * .018);
      final bounds = Rect.fromCenter(
        center: anchor,
        width: radius * 2,
        height: radius * 1.48,
      );
      canvas.drawOval(
        bounds,
        Paint()..color = _color.withValues(alpha: .035 * ringFade),
      );
      canvas.drawOval(
        bounds,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, unit * .004)
          ..color = light.withValues(alpha: (.64 - ring * .11) * ringFade),
      );
    }
    if (!broken) return;

    final crack =
        _ease((progress - .05) / .12) * (1 - _ease((progress - .23) / .15));
    for (var i = 0; i < 10; i++) {
      final angle = 2 * math.pi * i / 10 + .19;
      final path = Path()..moveTo(anchor.dx, anchor.dy);
      for (var j = 1; j <= 3; j++) {
        final bend = angle + .11 * math.sin(i + j * 1.9);
        final distance = unit * j * (.047 + (i % 5) * .005);
        path.lineTo(
          anchor.dx + math.cos(bend) * distance,
          anchor.dy + math.sin(bend) * distance * .76,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = light.withValues(alpha: .86 * crack),
      );
    }
    final flight = _ease((progress - .23) / .75);
    final shardFade = _ease((progress - .20) / .14) * fade;
    for (var i = 0; i < 28; i++) {
      final direction = 2 * math.pi * i / 28;
      final radius = unit * (.055 + flight * (.28 + (i % 7) * .034));
      final position = anchor.translate(
        radius * math.cos(direction),
        radius * .73 * math.sin(direction) + unit * .08 * flight * flight,
      );
      final tip = unit * (.016 + (i % 4) * .006) * (1 - .35 * flight);
      final angle = direction + ((i % 5) - 2) * flight;
      final points = [
        for (final offset in [0.0, 2.26, 4.4])
          position + Offset.fromDirection(angle + offset, tip),
      ];
      final path = Path()..addPolygon(points, true);
      canvas.drawPath(
        path,
        Paint()..color = _color.withValues(alpha: .28 * shardFade),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
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
      ..strokeCap = StrokeCap.round
      ..color = _color.withValues(alpha: .66 * fade);
    for (final x in [size.width * .055, size.width * .945]) {
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
            _color.withValues(alpha: .54 * fade),
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
        Paint()..color = _color.withValues(alpha: .46 * fade),
      );
      _spark(canvas, Offset(x, y), tail * .22, fade);
    }
  }

  void _spark(Canvas canvas, Offset position, double radius, double opacity) {
    canvas.drawCircle(
      position,
      radius * 2.4,
      Paint()..color = _color.withValues(alpha: .16 * opacity),
    );
    canvas.drawCircle(
      position,
      radius,
      Paint()..color = _color.withValues(alpha: .71 * opacity),
    );
    canvas.drawCircle(
      position,
      radius * .45,
      Paint()..color = Colors.white.withValues(alpha: .58 * opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _FeedbackPainter oldDelegate) =>
      oldDelegate.event != event ||
      oldDelegate.progress != progress ||
      oldDelegate.damageTint != damageTint;
}
