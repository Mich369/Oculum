import 'package:flutter/material.dart';

String? oculumMemoryEyeAsset(String role) => switch (role) {
  'npc' || 'party' => 'assets/oculum/icons/oculum_npc_eye.png',
  'enemy' || 'creature' => 'assets/icon/oculum_eye.png',
  'dead' => 'assets/oculum/icons/oculum_dead_eye.png',
  'obliterated' => 'assets/oculum/icons/oculum_obliterated_eye.png',
  _ => null,
};

class OculumMemoryEye extends StatefulWidget {
  const OculumMemoryEye({
    super.key,
    required this.role,
    this.size = 24,
    this.color = const Color(0xffc3a46b),
  });
  final String role;
  final double size;
  final Color color;

  @override
  State<OculumMemoryEye> createState() => _OculumMemoryEyeState();
}

class _OculumMemoryEyeState extends State<OculumMemoryEye> {
  Offset gaze = Offset.zero;
  @override
  Widget build(BuildContext context) {
    final asset = oculumMemoryEyeAsset(widget.role);
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: asset != null
            ? Image.asset(
                asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                semanticLabel: widget.role,
              )
            : MouseRegion(
                onHover: (event) {
                  if (MediaQuery.disableAnimationsOf(context)) {
                    return;
                  }
                  final half = widget.size / 2;
                  final next = Offset(
                    ((event.localPosition.dx - half) / half).clamp(-1.0, 1.0),
                    ((event.localPosition.dy - half) / half).clamp(-1.0, 1.0),
                  );
                  if ((next - gaze).distance > .08) setState(() => gaze = next);
                },
                onExit: (_) => setState(() => gaze = Offset.zero),
                child: TweenAnimationBuilder<Offset>(
                  tween: Tween<Offset>(begin: Offset.zero, end: gaze),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 140),
                  builder: (context, value, _) => CustomPaint(
                    painter: _OculumGazePainter(widget.color, value),
                  ),
                ),
              ),
      ),
    );
  }
}

class _OculumGazePainter extends CustomPainter {
  _OculumGazePainter(this.color, this.gaze);
  final Color color;
  final Offset gaze;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final outline = Path()
      ..moveTo(w * .06, h * .5)
      ..quadraticBezierTo(w * .5, h * .02, w * .94, h * .5)
      ..quadraticBezierTo(w * .5, h * .98, w * .06, h * .5);
    canvas.drawPath(outline, Paint()..color = color.withValues(alpha: .14));
    canvas.drawPath(
      outline,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.save();
    canvas.clipPath(outline);
    final pupil = Offset(w * .5 + gaze.dx * w * .1, h * .5 + gaze.dy * h * .08);
    canvas.drawCircle(
      pupil,
      w * .16,
      Paint()..color = color.withValues(alpha: .78),
    );
    canvas.drawOval(
      Rect.fromCenter(center: pupil, width: w * .065, height: h * .26),
      Paint()..color = const Color(0xff08090e),
    );
    canvas.drawCircle(
      pupil + Offset(-w * .035, -h * .045),
      w * .024,
      Paint()..color = Colors.white.withValues(alpha: .8),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OculumGazePainter old) =>
      old.color != color || old.gaze != gaze;
}
