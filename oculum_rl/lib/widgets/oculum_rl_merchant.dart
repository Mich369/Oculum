import 'dart:math' as math;

import 'package:flutter/material.dart';

class OculumRlMerchant extends StatefulWidget {
  const OculumRlMerchant({super.key, required this.goblin});
  final bool goblin;

  @override
  State<OculumRlMerchant> createState() => _OculumRlMerchantState();
}

class _OculumRlMerchantState extends State<OculumRlMerchant>
    with SingleTickerProviderStateMixin {
  late final _flies = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();
  final _cancel = ValueNotifier<Offset>(Offset.zero);

  @override
  void dispose() {
    _flies.dispose();
    _cancel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      height: 174,
      child: AspectRatio(
        aspectRatio: widget.goblin ? 1.118 : 1.2,
        child: LayoutBuilder(
          builder: (context, limits) => MouseRegion(
            onHover: (event) => _lookAt(event.localPosition, limits.biggest),
            onExit: (_) => _cancel.value = Offset.zero,
            child: Listener(
              onPointerDown: (event) =>
                  _lookAt(event.localPosition, limits.biggest),
              onPointerMove: (event) =>
                  _lookAt(event.localPosition, limits.biggest),
              onPointerUp: (_) => _cancel.value = Offset.zero,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _cancel,
                  builder: (context, art) => Transform.translate(
                    offset: widget.goblin ? Offset.zero : _cancel.value * 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        art!,
                        CustomPaint(
                          painter: _Gaze(
                            goblin: widget.goblin,
                            look: _cancel.value,
                            flies: _flies,
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: Image.asset(
                    widget.goblin
                        ? 'assets/oculum/lite/mercante-goblin.png'
                        : 'assets/oculum/lite/mercante-armaiola.png',
                    fit: BoxFit.fill,
                    semanticLabel: widget.goblin
                        ? 'Goblin annoiato con entrambi gli occhi gialli'
                        : 'Armaiola della run',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  void _lookAt(Offset at, Size size) {
    if (size.isEmpty) return;
    _cancel.value = Offset(
      (at.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
      (at.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
    );
  }
}

class _Gaze extends CustomPainter {
  _Gaze({required this.goblin, required this.look, required this.flies})
    : super(repaint: goblin ? flies : null);
  final bool goblin;
  final Offset look;
  final Animation<double> flies;

  @override
  void paint(Canvas canvas, Size size) {
    Offset at(double x, double y) => Offset(size.width * x, size.height * y);
    final pigment = Paint();
    if (goblin) {
      // The second yellow eye is baked in the portrait and remains fixed.
      final fixedSclera = Rect.fromCenter(
        center: at(.446, .195),
        width: size.width * .046,
        height: size.height * .014,
      );
      canvas.drawOval(fixedSclera, pigment..color = const Color(0xffe9b745));
      final pupil = fixedSclera.center + at(look.dx * .020, look.dy * .005);
      canvas.drawOval(
        Rect.fromCenter(
          center: pupil,
          width: size.width * .021,
          height: size.height * .014,
        ),
        pigment..color = const Color(0xff1d1517),
      );
      canvas.drawCircle(
        pupil - const Offset(0.6, .35),
        .6,
        pigment..color = const Color(0xffe7d99b),
      );
      for (var i = 0; i < 5; i++) {
        final tick = flies.value * math.pi * 2;
        final angle = tick * (i.isEven ? 2 : -3) + i * 1.17;
        final point = at(
          .50 + math.cos(angle) * (.29 + .02 * i),
          .29 + math.sin(angle * 1.5) * (.10 + .015 * i),
        );
        final flutter = 1 + math.sin(tick * 41 + i).abs();
        canvas.drawOval(
          Rect.fromCenter(
            center: point + Offset(-1.7, -flutter),
            width: 4.1,
            height: 1.4,
          ),
          pigment..color = const Color(0xbcddc6aa),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: point + Offset(1.7, -flutter),
            width: 4.1,
            height: 1.4,
          ),
          pigment,
        );
        canvas.drawCircle(
          point,
          1.65,
          pigment..color = const Color(0xff201714),
        );
      }
    } else {
      final movement = at(look.dx * .006, look.dy * .003);
      for (final centre in [at(.308, .267), at(.407, .217)]) {
        canvas.drawCircle(
          centre + movement,
          size.width * .007,
          pigment..color = const Color(0xff302019),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Gaze oldDelegate) =>
      goblin != oldDelegate.goblin || look != oldDelegate.look;
}
