import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Decorative eyes: isolated paint, no semantics and no input capture.
class OculumWatchingEyes extends StatefulWidget {
  const OculumWatchingEyes({
    super.key,
    required this.animation,
    this.child,
    this.reverseGaze = false,
    this.onGazeChanged,
  });
  final Animation<double> animation;
  final Widget? child;
  final bool reverseGaze;
  @visibleForTesting
  final ValueChanged<Offset>? onGazeChanged;
  @override
  State<OculumWatchingEyes> createState() => _OculumWatchingEyesState();
}

class _OculumWatchingEyesState extends State<OculumWatchingEyes> {
  final gaze = ValueNotifier<Offset>(const Offset(-1000, -1000));

  void updateGaze(Offset value) {
    gaze.value = value;
    widget.onGazeChanged?.call(value);
  }

  @override
  void dispose() {
    gaze.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    opaque: false,
    hitTestBehavior: HitTestBehavior.translucent,
    onHover: (e) => updateGaze(e.localPosition),
    onEnter: (e) => updateGaze(e.localPosition),
    onExit: (_) => updateGaze(const Offset(-1000, -1000)),
    child: Listener(
      onPointerDown: (e) => updateGaze(e.localPosition),
      onPointerMove: (e) => updateGaze(e.localPosition),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _EyesPainter(
                    widget.animation,
                    gaze,
                    MediaQuery.disableAnimationsOf(context),
                    widget.reverseGaze,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    ),
  );
}

class _EyesPainter extends CustomPainter {
  _EyesPainter(this.animation, this.gaze, this.reduced, this.reverseGaze)
    : super(repaint: Listenable.merge([animation, gaze]));
  final Animation<double> animation;
  final ValueNotifier<Offset> gaze;
  final bool reduced;
  final bool reverseGaze;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xff08090e),
    );
    final phase = reduced ? 0.0 : animation.value * math.pi * 2;
    for (var i = 0; i < 24; i++) {
      final col = i % 6, row = i ~/ 6;
      final moving = i % 4 == 0;
      final x =
          size.width * ((col + .5) / 6) +
          (moving ? math.sin(phase + i) * 16 : 0);
      final y =
          size.height * ((row + .5) / 4) +
          (moving ? math.cos(phase + i) * 12 : 0);
      final center = Offset(x, y);
      final w = (size.width / 20).clamp(18.0, 44.0);
      final path = Path()
        ..moveTo(x - w, y)
        ..quadraticBezierTo(x, y - w * .65, x + w, y)
        ..quadraticBezierTo(x, y + w * .65, x - w, y);
      final color = Color.lerp(
        const Color(0xffa99ac8),
        const Color(0xffad8a58),
        (i % 3) / 2,
      )!;
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: .22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      var delta = gaze.value.dx < -500 ? Offset.zero : gaze.value - center;
      if (reverseGaze) delta = -delta;
      if (delta.distance > 0) delta = delta / delta.distance * w * .16;
      canvas.save();
      canvas.clipPath(path);
      canvas.drawCircle(
        center + delta,
        w * .23,
        Paint()..color = color.withValues(alpha: .28),
      );
      canvas.drawOval(
        Rect.fromCenter(center: center + delta, width: w * .12, height: w * .4),
        Paint()..color = const Color(0xff020306),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _EyesPainter old) =>
      old.reduced != reduced ||
      old.gaze != gaze ||
      old.animation != animation ||
      old.reverseGaze != reverseGaze;
}
