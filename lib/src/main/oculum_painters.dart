part of '../../main.dart';

// WIDGET E PAINTER FUORI DALLA STATE
// =====================================================

class D20Widget extends StatelessWidget {
  const D20Widget({
    super.key,
    required this.text,
    required this.fillColor,
    required this.textColor,
    required this.glow,
    required this.tertiaryColor,
    this.faces = 20,
    this.size = 130,
  });

  final String text;
  final Color fillColor;
  final Color textColor;
  final bool glow;
  final Color tertiaryColor;
  final int faces;
  final double size;

  double dimensioneTesto() {
    final scale = (size / 130).clamp(0.72, 1.18).toDouble();
    if (text.length > 11) return 15 * scale;
    if (text.length > 8) return 17 * scale;
    if (text.length > 5) return 21 * scale;
    if (text.length > 2) return 26 * scale;
    return 38 * scale;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glow
                ? tertiaryColor.withValues(alpha: 0.20)
                : fillColor.withValues(alpha: 0.14),
            blurRadius: glow ? 10 : 7,
            spreadRadius: glow ? 1.5 : 1,
          ),
        ],
      ),
      child: CustomPaint(
        isComplex: true,
        willChange: false,
        painter: D20Painter(
          fillColor: fillColor,
          lineColor: textColor,
          glow: glow,
          tertiaryColor: tertiaryColor,
          faces: faces,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  color: textColor,
                  fontSize: dimensioneTesto(),
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.85),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HexagonClipper extends CustomClipper<Path> {
  const HexagonClipper();

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final path = Path();

    for (int i = 0; i < 6; i++) {
      final angle = -pi / 2 + (pi / 3 * i);
      final point = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class D20Painter extends CustomPainter {
  D20Painter({
    required this.fillColor,
    required this.lineColor,
    required this.glow,
    required this.tertiaryColor,
    this.faces = 20,
  });

  final Color fillColor;
  final Color lineColor;
  final bool glow;
  final Color tertiaryColor;
  final int faces;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;
    final points = <Offset>[];
    final sides = faces <= 2
        ? 20
        : faces >= 100
        ? 20
        : faces.clamp(3, 20).toInt();
    final spiky = sides >= 12;

    for (int i = 0; i < sides; i++) {
      final angle = -pi / 2 + (2 * pi * i / sides);
      final r = spiky && i.isOdd ? radius * 0.82 : radius;
      points.add(
        Offset(center.dx + cos(angle) * r, center.dy + sin(angle) * r),
      );
    }

    final outerPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      outerPath.lineTo(p.dx, p.dy);
    }
    outerPath.close();

    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          fillColor.withValues(alpha: 0.92),
          fillColor.withValues(alpha: 0.58),
          Colors.black.withValues(alpha: 0.90),
        ],
        stops: const [0.0, 0.56, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final borderPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1;

    final innerPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    if (glow) {
      final glowPaint = Paint()
        ..color = tertiaryColor.withValues(alpha: 0.13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawPath(outerPath, glowPaint);
    }

    canvas.drawPath(outerPath, fillPaint);
    canvas.drawPath(outerPath, borderPaint);

    for (int i = 0; i < points.length; i += spiky ? 2 : 1) {
      canvas.drawLine(center, points[i], innerPaint);
    }

    final triangle1 = Path()
      ..moveTo(center.dx, center.dy - radius * 0.58)
      ..lineTo(center.dx - radius * 0.52, center.dy + radius * 0.34)
      ..lineTo(center.dx + radius * 0.52, center.dy + radius * 0.34)
      ..close();

    final triangle2 = Path()
      ..moveTo(center.dx, center.dy + radius * 0.58)
      ..lineTo(center.dx - radius * 0.52, center.dy - radius * 0.34)
      ..lineTo(center.dx + radius * 0.52, center.dy - radius * 0.34)
      ..close();

    canvas.drawPath(triangle1, innerPaint);
    canvas.drawPath(triangle2, innerPaint);

    canvas.drawCircle(
      Offset(center.dx - radius * 0.22, center.dy - radius * 0.26),
      radius * 0.12,
      Paint()..color = Colors.white.withValues(alpha: 0.11),
    );
  }

  @override
  bool shouldRepaint(covariant D20Painter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.glow != glow ||
        oldDelegate.tertiaryColor != tertiaryColor ||
        oldDelegate.faces != faces;
  }
}

class SmallPlusEyePainter extends CustomPainter {
  SmallPlusEyePainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    // Occhio a sinistra
    final eyeCenter = Offset(size.width * 0.34, centerY);
    final eyeWidth = size.width * 0.52;
    final eyeHeight = size.height * 0.58;

    final eyeRect = Rect.fromCenter(
      center: eyeCenter,
      width: eyeWidth,
      height: eyeHeight,
    );

    final eyePath = Path()
      ..moveTo(eyeRect.left, eyeCenter.dy)
      ..quadraticBezierTo(
        eyeCenter.dx,
        eyeRect.top - 8,
        eyeRect.right,
        eyeCenter.dy,
      )
      ..quadraticBezierTo(
        eyeCenter.dx,
        eyeRect.bottom + 8,
        eyeRect.left,
        eyeCenter.dy,
      )
      ..close();

    // Bagliore esterno
    canvas.drawPath(
      eyePath,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Parte bianca / sclera cupa
    final scleraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.72),
          const Color(0xFF88838E).withValues(alpha: 0.52),
          Colors.black.withValues(alpha: 0.92),
        ],
        stops: const [0.0, 0.58, 1.0],
      ).createShader(eyeRect);

    canvas.drawPath(eyePath, scleraPaint);

    // Contorno occhio
    canvas.drawPath(
      eyePath,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Iride: secondario come sfumatura scura + primario
    final irisRadius = size.height * 0.20;
    final irisRect = Rect.fromCircle(center: eyeCenter, radius: irisRadius);

    final irisPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.92),
          Color.lerp(
            primaryColor,
            secondaryColor,
            0.45,
          )!.withValues(alpha: 0.95),
          secondaryColor.withValues(alpha: 0.98),
          Colors.black.withValues(alpha: 0.92),
        ],
        stops: const [0.0, 0.42, 0.78, 1.0],
      ).createShader(irisRect);

    canvas.drawCircle(eyeCenter, irisRadius, irisPaint);

    canvas.drawCircle(
      eyeCenter,
      irisRadius,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // Pupilla: terziario + primario
    final pupilRadius = irisRadius * 0.42;
    final pupilRect = Rect.fromCircle(center: eyeCenter, radius: pupilRadius);

    final pupilPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          tertiaryColor.withValues(alpha: 0.95),
          Color.lerp(
            tertiaryColor,
            primaryColor,
            0.35,
          )!.withValues(alpha: 0.82),
          Colors.black.withValues(alpha: 0.95),
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(pupilRect);

    canvas.drawCircle(eyeCenter, pupilRadius, pupilPaint);

    // Punto luce
    canvas.drawCircle(
      Offset(
        eyeCenter.dx - irisRadius * 0.28,
        eyeCenter.dy - irisRadius * 0.30,
      ),
      irisRadius * 0.13,
      Paint()..color = Colors.white.withValues(alpha: 0.62),
    );

    // Plus a destra dell'occhio
    final plusCenter = Offset(size.width * 0.78, centerY);

    final plusGlowPaint = Paint()
      ..color = tertiaryColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final plusPaint = Paint()
      ..shader = LinearGradient(colors: [primaryColor, tertiaryColor])
          .createShader(
            Rect.fromCenter(
              center: plusCenter,
              width: size.width * 0.30,
              height: size.height * 0.62,
            ),
          )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final plusHalf = size.height * 0.22;

    canvas.drawLine(
      Offset(plusCenter.dx - plusHalf, plusCenter.dy),
      Offset(plusCenter.dx + plusHalf, plusCenter.dy),
      plusGlowPaint,
    );

    canvas.drawLine(
      Offset(plusCenter.dx, plusCenter.dy - plusHalf),
      Offset(plusCenter.dx, plusCenter.dy + plusHalf),
      plusGlowPaint,
    );

    canvas.drawLine(
      Offset(plusCenter.dx - plusHalf, plusCenter.dy),
      Offset(plusCenter.dx + plusHalf, plusCenter.dy),
      plusPaint,
    );

    canvas.drawLine(
      Offset(plusCenter.dx, plusCenter.dy - plusHalf),
      Offset(plusCenter.dx, plusCenter.dy + plusHalf),
      plusPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SmallPlusEyePainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.tertiaryColor != tertiaryColor;
  }
}

class ObserStonePainter extends CustomPainter {
  ObserStonePainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    final stonePath = Path()
      ..moveTo(center.dx - radius * 0.75, center.dy - radius * 0.52)
      ..quadraticBezierTo(
        center.dx - radius * 1.05,
        center.dy + radius * 0.02,
        center.dx - radius * 0.62,
        center.dy + radius * 0.72,
      )
      ..quadraticBezierTo(
        center.dx - radius * 0.05,
        center.dy + radius * 1.02,
        center.dx + radius * 0.64,
        center.dy + radius * 0.70,
      )
      ..quadraticBezierTo(
        center.dx + radius * 1.08,
        center.dy + radius * 0.10,
        center.dx + radius * 0.74,
        center.dy - radius * 0.58,
      )
      ..quadraticBezierTo(
        center.dx + radius * 0.10,
        center.dy - radius * 1.02,
        center.dx - radius * 0.75,
        center.dy - radius * 0.52,
      )
      ..close();

    canvas.drawPath(
      stonePath,
      Paint()
        ..shader = RadialGradient(
          colors: [
            tertiaryColor.withValues(alpha: 0.95),
            const Color(0xFF6B4A19),
            const Color(0xFF1C1308),
          ],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    canvas.drawPath(
      stonePath,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final eyeRect = Rect.fromCenter(
      center: center,
      width: radius * 1.05,
      height: radius * 0.55,
    );

    final eyePath = Path()
      ..moveTo(eyeRect.left, center.dy)
      ..quadraticBezierTo(center.dx, eyeRect.top, eyeRect.right, center.dy)
      ..quadraticBezierTo(center.dx, eyeRect.bottom, eyeRect.left, center.dy)
      ..close();

    canvas.drawPath(
      eyePath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    canvas.drawCircle(
      center,
      radius * 0.18,
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );

    canvas.drawCircle(
      center,
      radius * 0.08,
      Paint()..color = primaryColor.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant ObserStonePainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.tertiaryColor != tertiaryColor;
  }
}

class OculumEyePainter extends CustomPainter {
  OculumEyePainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.pupilGlowColor,
  });

  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final Color pupilGlowColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height * 0.51);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(const Color(0xFF050307), secondaryColor, 0.22)!,
            Color.lerp(const Color(0xFF12070C), primaryColor, 0.09)!,
            Color.lerp(const Color(0xFF080302), tertiaryColor, 0.08)!,
            const Color(0xFF000000),
          ],
          stops: const [0.0, 0.38, 0.72, 1.0],
        ).createShader(Offset.zero & size),
    );
    _drawFog(canvas, size);
    _drawAura(canvas, size, center);
    _drawOccultFrame(canvas, size);
    _drawEye(canvas, size, center);
    _drawScratches(canvas, size);
    _drawBloodLikeDrips(canvas, size, center);
    canvas.restore();
  }

  void _drawEye(Canvas canvas, Size size, Offset center) {
    final eyeWidth = size.width * 0.76;
    final eyeHeight = size.height * 0.32;
    final curveTop = eyeHeight * 0.58;
    final curveBottom = eyeHeight * 0.42;
    final outerRect = Rect.fromCenter(
      center: center,
      width: eyeWidth,
      height: eyeHeight,
    );

    final eyePath = Path()
      ..moveTo(outerRect.left, center.dy)
      ..cubicTo(
        outerRect.left + outerRect.width * 0.22,
        outerRect.top - curveTop,
        outerRect.right - outerRect.width * 0.22,
        outerRect.top - curveTop,
        outerRect.right,
        center.dy,
      )
      ..cubicTo(
        outerRect.right - outerRect.width * 0.20,
        outerRect.bottom + curveBottom,
        outerRect.left + outerRect.width * 0.20,
        outerRect.bottom + curveBottom,
        outerRect.left,
        center.dy,
      )
      ..close();

    final shadowPath = eyePath.shift(Offset(0, size.height * 0.018));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..isAntiAlias = true
        ..color = Colors.black.withValues(alpha: 0.80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    final lidPaint = Paint()
      ..isAntiAlias = true
      ..shader =
          LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.96),
              Color.lerp(
                secondaryColor,
                Colors.black,
                0.42,
              )!.withValues(alpha: 0.90),
              Color.lerp(
                tertiaryColor,
                Colors.black,
                0.55,
              )!.withValues(alpha: 0.58),
            ],
          ).createShader(
            Rect.fromCenter(
              center: center,
              width: eyeWidth * 1.22,
              height: eyeHeight * 1.75,
            ),
          );
    final upperLid = Path()
      ..moveTo(outerRect.left - eyeWidth * 0.06, center.dy - eyeHeight * 0.02)
      ..cubicTo(
        outerRect.left + eyeWidth * 0.16,
        outerRect.top - eyeHeight * 0.74,
        outerRect.right - eyeWidth * 0.16,
        outerRect.top - eyeHeight * 0.72,
        outerRect.right + eyeWidth * 0.06,
        center.dy - eyeHeight * 0.01,
      )
      ..lineTo(outerRect.right + eyeWidth * 0.02, center.dy - eyeHeight * 0.16)
      ..cubicTo(
        outerRect.right - eyeWidth * 0.20,
        outerRect.top - eyeHeight * 0.98,
        outerRect.left + eyeWidth * 0.20,
        outerRect.top - eyeHeight * 0.98,
        outerRect.left - eyeWidth * 0.02,
        center.dy - eyeHeight * 0.16,
      )
      ..close();
    final lowerLid = Path()
      ..moveTo(outerRect.left - eyeWidth * 0.04, center.dy + eyeHeight * 0.03)
      ..cubicTo(
        outerRect.left + eyeWidth * 0.18,
        outerRect.bottom + eyeHeight * 0.55,
        outerRect.right - eyeWidth * 0.18,
        outerRect.bottom + eyeHeight * 0.54,
        outerRect.right + eyeWidth * 0.04,
        center.dy + eyeHeight * 0.03,
      )
      ..lineTo(outerRect.right + eyeWidth * 0.01, center.dy + eyeHeight * 0.16)
      ..cubicTo(
        outerRect.right - eyeWidth * 0.20,
        outerRect.bottom + eyeHeight * 0.80,
        outerRect.left + eyeWidth * 0.20,
        outerRect.bottom + eyeHeight * 0.80,
        outerRect.left - eyeWidth * 0.01,
        center.dy + eyeHeight * 0.16,
      )
      ..close();
    canvas.drawPath(upperLid, lidPaint);
    canvas.drawPath(lowerLid, lidPaint);

    canvas.drawPath(
      eyePath,
      Paint()
        ..isAntiAlias = true
        ..shader = RadialGradient(
          colors: [
            Color.lerp(const Color(0xFFF1E4C8), primaryColor, 0.30)!,
            Color.lerp(const Color(0xFFB8AF9A), secondaryColor, 0.18)!,
            Color.lerp(const Color(0xFF4A4038), tertiaryColor, 0.16)!,
            const Color(0xFF14100F),
          ],
          stops: const [0.0, 0.52, 0.82, 1.0],
        ).createShader(outerRect),
    );

    canvas.drawPath(
      eyePath,
      Paint()
        ..isAntiAlias = true
        ..color = Colors.black.withValues(alpha: 0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.8,
    );

    canvas.drawPath(
      eyePath,
      Paint()
        ..isAntiAlias = true
        ..color = Color.lerp(
          primaryColor,
          Colors.white,
          0.72,
        )!.withValues(alpha: 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    final veinPaint = Paint()
      ..color = Color.lerp(
        tertiaryColor,
        Colors.black,
        0.22,
      )!.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 24; i++) {
      final random = Random(300 + i);
      final side = i.isEven ? -1.0 : 1.0;
      final sx =
          center.dx + side * eyeWidth * (0.10 + random.nextDouble() * 0.32);
      final sy = center.dy + (random.nextDouble() - 0.5) * eyeHeight * 0.48;
      final path = Path()
        ..moveTo(sx, sy)
        ..cubicTo(
          sx - side * (8 + random.nextDouble() * 15),
          sy + (random.nextDouble() - 0.5) * 18,
          sx - side * (22 + random.nextDouble() * 26),
          sy + (random.nextDouble() - 0.5) * 30,
          sx - side * (38 + random.nextDouble() * 38),
          sy + (random.nextDouble() - 0.5) * 34,
        );
      canvas.drawPath(path, veinPaint);
    }

    final irisRadius = min(size.width, size.height) * 0.215;
    final irisRect = Rect.fromCircle(center: center, radius: irisRadius);

    canvas.drawCircle(
      center,
      irisRadius * 1.28,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    canvas.drawCircle(
      center,
      irisRadius,
      Paint()
        ..shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle: 3 * pi / 2,
          colors: [
            Color.lerp(primaryColor, pupilGlowColor, 0.45)!,
            Color.lerp(secondaryColor, Colors.black, 0.48)!,
            Color.lerp(tertiaryColor, pupilGlowColor, 0.24)!,
            Colors.black,
            Color.lerp(primaryColor, pupilGlowColor, 0.45)!,
          ],
        ).createShader(irisRect),
    );

    canvas.drawCircle(
      center,
      irisRadius,
      Paint()
        ..isAntiAlias = true
        ..shader = RadialGradient(
          colors: [
            Color.lerp(
              primaryColor,
              Color.lerp(pupilGlowColor, Colors.white, 0.18)!,
              0.34,
            )!.withValues(alpha: 0.98),
            Color.lerp(
              primaryColor,
              pupilGlowColor,
              0.58,
            )!.withValues(alpha: 0.98),
            Color.lerp(secondaryColor, pupilGlowColor, 0.20)!,
            Colors.black.withValues(alpha: 0.92),
          ],
          stops: const [0.0, 0.42, 0.78, 1.0],
        ).createShader(irisRect),
    );

    canvas.drawCircle(
      center,
      irisRadius * 0.52,
      Paint()
        ..isAntiAlias = true
        ..color = pupilGlowColor.withValues(alpha: 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawCircle(
      center,
      irisRadius,
      Paint()
        ..isAntiAlias = true
        ..color = Colors.black.withValues(alpha: 0.52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    for (int i = 0; i < 42; i++) {
      final angle = (pi * 2 / 42) * i;
      final inner = Offset(
        center.dx + cos(angle) * irisRadius * 0.38,
        center.dy + sin(angle) * irisRadius * 0.38,
      );
      final outer = Offset(
        center.dx + cos(angle) * irisRadius * (0.82 + (i % 4) * 0.03),
        center.dy + sin(angle) * irisRadius * (0.82 + (i % 4) * 0.03),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = Colors.black.withValues(alpha: i.isEven ? 0.38 : 0.22)
          ..strokeWidth = 0.85
          ..strokeCap = StrokeCap.round,
      );
    }

    for (int i = 0; i < 9; i++) {
      final angle = -pi / 2 + i * pi / 4;
      final notch = Path()
        ..moveTo(
          center.dx + cos(angle) * irisRadius * 0.94,
          center.dy + sin(angle) * irisRadius * 0.94,
        )
        ..lineTo(
          center.dx + cos(angle + 0.08) * irisRadius * 1.13,
          center.dy + sin(angle + 0.08) * irisRadius * 1.13,
        );
      canvas.drawPath(
        notch,
        Paint()
          ..color = Color.lerp(
            tertiaryColor,
            Colors.black,
            0.18,
          )!.withValues(alpha: 0.58)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }

    final pupilRadius = irisRadius * 0.40;
    final pupilRect = Rect.fromCenter(
      center: center,
      width: pupilRadius * 1.18,
      height: pupilRadius * 2.18,
    );

    canvas.drawOval(
      pupilRect,
      Paint()
        ..isAntiAlias = true
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF090909).withValues(alpha: 0.98),
            Color.lerp(
              Colors.black,
              tertiaryColor,
              0.18,
            )!.withValues(alpha: 0.96),
            Colors.black.withValues(alpha: 0.96),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(pupilRect),
    );

    canvas.drawOval(
      pupilRect.inflate(irisRadius * 0.04),
      Paint()
        ..color = pupilGlowColor.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawCircle(
      Offset(center.dx + irisRadius * 0.25, center.dy - irisRadius * 0.35),
      irisRadius * 0.14,
      Paint()
        ..isAntiAlias = true
        ..color = const Color(0xFFFFF5D7).withValues(alpha: 0.78),
    );

    canvas.drawCircle(
      Offset(center.dx - irisRadius * 0.18, center.dy + irisRadius * 0.10),
      irisRadius * 0.055,
      Paint()
        ..isAntiAlias = true
        ..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  void _drawOccultFrame(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final topY = size.height * 0.12;

    final thin = Paint()
      ..color = Color.lerp(
        primaryColor,
        Colors.white,
        0.35,
      )!.withValues(alpha: 0.56)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round;

    final accent = Paint()
      ..color = Color.lerp(
        tertiaryColor,
        secondaryColor,
        0.24,
      )!.withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final crown = Path()
      ..moveTo(cx - size.width * 0.28, topY + 58)
      ..quadraticBezierTo(cx, topY + 10, cx + size.width * 0.28, topY + 58);

    canvas.drawPath(crown, thin);
    canvas.drawPath(
      crown.shift(const Offset(0, 10)),
      Paint()
        ..color = primaryColor.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final needle = Path()
      ..moveTo(cx, topY - 36)
      ..lineTo(cx - 4, topY - 14)
      ..lineTo(cx + 3, topY + 6)
      ..lineTo(cx - 2, topY + 30)
      ..lineTo(cx, topY + 58);
    canvas.drawPath(needle, thin);

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, topY + 64),
        width: size.width * 0.38,
        height: size.height * 0.16,
      ),
      pi,
      pi,
      false,
      thin,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, topY + 64),
        width: size.width * 0.27,
        height: size.height * 0.09,
      ),
      pi,
      pi,
      false,
      accent,
    );

    canvas.drawCircle(Offset(cx, topY + 8), 6, thin);
    canvas.drawCircle(Offset(cx, topY + 8), 2.2, accent);
    canvas.drawLine(Offset(cx - 24, topY + 8), Offset(cx + 24, topY + 8), thin);
    canvas.drawCircle(Offset(cx - size.width * 0.18, topY + 62), 9, thin);
    canvas.drawCircle(Offset(cx + size.width * 0.18, topY + 62), 9, thin);
    canvas.drawLine(
      Offset(cx - size.width * 0.18, topY + 62),
      Offset(cx + size.width * 0.18, topY + 62),
      accent,
    );

    final sigilPaint = Paint()
      ..color = tertiaryColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (int i = 0; i < 8; i++) {
      final angle = -pi / 2 + i * pi / 4;
      final outer = Offset(
        cx + cos(angle) * size.width * 0.39,
        size.height * 0.53 + sin(angle) * size.height * 0.30,
      );
      final inner = Offset(
        cx + cos(angle) * size.width * 0.31,
        size.height * 0.53 + sin(angle) * size.height * 0.22,
      );
      canvas.drawLine(inner, outer, sigilPaint);
      canvas.drawCircle(outer, 2.2, sigilPaint);
    }
  }

  void _drawBloodLikeDrips(Canvas canvas, Size size, Offset center) {
    // Ciglia/lacrime rituali corrette:
    // non partono più dentro l'occhio, ma sotto la palpebra inferiore.
    final halfEyeWidth = size.width * 0.76 / 2;
    final eyeHeight = size.height * 0.32;

    final lashPaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.86),
              Color.lerp(
                tertiaryColor,
                Colors.black,
                0.28,
              )!.withValues(alpha: 0.76),
              Colors.black.withValues(alpha: 0.12),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(
            Rect.fromLTWH(
              center.dx - halfEyeWidth,
              center.dy,
              halfEyeWidth * 2,
              size.height * 0.42,
            ),
          )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final beadPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.58)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final lashes = <Map<String, double>>[
      {'x': -0.78, 'len': 52, 'curve': -12},
      {'x': -0.58, 'len': 92, 'curve': -6},
      {'x': -0.36, 'len': 116, 'curve': -3},
      {'x': -0.12, 'len': 150, 'curve': -1},
      {'x': 0.08, 'len': 140, 'curve': 2},
      {'x': 0.29, 'len': 112, 'curve': 5},
      {'x': 0.54, 'len': 92, 'curve': 8},
      {'x': 0.76, 'len': 58, 'curve': 12},
    ];

    for (final lash in lashes) {
      final normalizedX = lash['x']!;
      final length = lash['len']!;
      final curve = lash['curve']!;

      final x = center.dx + normalizedX * halfEyeWidth;

      // Calcolo morbido del bordo inferiore dell'occhio.
      // Al centro è più basso, ai lati è più alto.
      final sideAmount = normalizedX.abs();
      final lowerLidY =
          center.dy +
          (eyeHeight * 0.50) -
          (sideAmount * sideAmount * eyeHeight * 0.32);

      final start = Offset(x, lowerLidY + 9);
      final control = Offset(x + curve, lowerLidY + length * 0.48);
      final end = Offset(x + curve * 0.45, lowerLidY + length);

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, lashPaint);

      canvas.drawCircle(Offset(end.dx, end.dy + 4), 3.7, beadPaint);
    }
  }

  void _drawScratches(Canvas canvas, Size size) {
    final scratch = Paint()
      ..color = primaryColor.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round;

    final rust = Paint()
      ..color = tertiaryColor.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final random = Random(i * 9);
      final x = size.width * (0.10 + random.nextDouble() * 0.8);
      final y = size.height * (0.18 + random.nextDouble() * 0.64);
      final len = 10 + random.nextDouble() * 52;

      canvas.drawLine(
        Offset(x, y),
        Offset(x + len, y + random.nextDouble() * 18 - 9),
        scratch,
      );

      if (i % 3 == 0) {
        canvas.drawCircle(
          Offset(x + random.nextDouble() * 24, y + random.nextDouble() * 18),
          1.2 + random.nextDouble() * 2.2,
          rust,
        );
      }
    }
  }

  void _drawFog(Canvas canvas, Size size) {
    final paperLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < 26; i++) {
      final random = Random(900 + i);
      final y = random.nextDouble() * size.height;
      canvas.drawLine(
        Offset(random.nextDouble() * size.width * 0.2, y),
        Offset(size.width * (0.75 + random.nextDouble() * 0.25), y + 18),
        paperLine,
      );
    }

    final dustPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 72; i++) {
      final random = Random(i);

      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        0.5 + random.nextDouble() * 1.5,
        dustPaint,
      );
    }
  }

  void _drawAura(Canvas canvas, Size size, Offset center) {
    final auraRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.96,
      height: size.height * 0.78,
    );
    canvas.drawOval(
      auraRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            primaryColor.withValues(alpha: 0.18),
            tertiaryColor.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(auraRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawOval(
      auraRect.deflate(size.width * 0.05),
      Paint()
        ..color = tertiaryColor.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant OculumEyePainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.tertiaryColor != tertiaryColor ||
        oldDelegate.pupilGlowColor != pupilGlowColor;
  }
}
