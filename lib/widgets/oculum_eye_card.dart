import 'dart:math';

import 'package:flutter/material.dart';

class OculumEyeCard extends StatelessWidget {
  const OculumEyeCard({
    super.key,
    required this.onAddImage,
    this.primaryColor = const Color(0xFFB48CFF),
    this.secondaryColor = const Color(0xFF6EE7D8),
    this.tertiaryColor = const Color(0xFFFFB85C),
  });

  final VoidCallback onAddImage;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.55),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.10),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        height: 360,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  isComplex: true,
                  willChange: false,
                  painter: _OculumEyeBackgroundPainter(
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    tertiaryColor: tertiaryColor,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 28,
              right: 28,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onAddImage,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image, color: primaryColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Aggiungi',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                size: const Size(300, 260),
                isComplex: true,
                willChange: false,
                painter: _OculumEyePainter(
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                  tertiaryColor: tertiaryColor,
                ),
              ),
            ),
            Positioned(
              bottom: 34,
              child: Text(
                'PERSONAGGIO - SCHEDA 1/1',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OculumEyeBackgroundPainter extends CustomPainter {
  const _OculumEyeBackgroundPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF05060D),
            Color.lerp(const Color(0xFF080911), primaryColor, 0.05)!,
            Colors.black,
          ],
        ).createShader(Offset.zero & size),
    );

    final dust = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;
    final scratches = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    final rust = Paint()
      ..color = const Color(0xFF9B3B18).withValues(alpha: 0.26)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 72; i++) {
      final random = Random(i);
      final point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      canvas.drawCircle(point, 0.5 + random.nextDouble() * 1.5, dust);
      if (i % 7 == 0) {
        canvas.drawCircle(point, 1.2 + random.nextDouble() * 2.4, rust);
      }
    }

    for (int i = 0; i < 22; i++) {
      final random = Random(200 + i);
      final start = Offset(
        size.width * (0.10 + random.nextDouble() * 0.78),
        size.height * (0.16 + random.nextDouble() * 0.66),
      );
      canvas.drawLine(
        start,
        start +
            Offset(16 + random.nextDouble() * 42, random.nextDouble() * 16 - 8),
        scratches,
      );
    }

    final cx = size.width / 2;
    final topY = size.height * 0.16;
    final ink = Paint()
      ..color = Colors.white.withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final accent = Paint()
      ..color = Color.lerp(
        tertiaryColor,
        const Color(0xFF8B2E18),
        0.35,
      )!.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final crown = Path()
      ..moveTo(cx - size.width * 0.25, topY + 52)
      ..quadraticBezierTo(cx, topY + 6, cx + size.width * 0.25, topY + 52);
    canvas.drawPath(crown, ink);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, topY + 58),
        width: size.width * 0.34,
        height: size.height * 0.13,
      ),
      pi,
      pi,
      false,
      accent,
    );
    canvas.drawLine(Offset(cx, topY - 28), Offset(cx, topY + 52), ink);
    canvas.drawCircle(Offset(cx, topY + 8), 5.5, ink);
    canvas.drawCircle(Offset(cx, topY + 8), 2, accent);
  }

  @override
  bool shouldRepaint(covariant _OculumEyeBackgroundPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.tertiaryColor != tertiaryColor;
  }
}

class _OculumEyePainter extends CustomPainter {
  const _OculumEyePainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.49);
    final eyeRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.82,
      height: size.height * 0.36,
    );
    final eyePath = Path()
      ..moveTo(eyeRect.left, center.dy)
      ..cubicTo(
        eyeRect.left + eyeRect.width * 0.22,
        eyeRect.top - eyeRect.height * 0.42,
        eyeRect.right - eyeRect.width * 0.22,
        eyeRect.top - eyeRect.height * 0.42,
        eyeRect.right,
        center.dy,
      )
      ..cubicTo(
        eyeRect.right - eyeRect.width * 0.20,
        eyeRect.bottom + eyeRect.height * 0.34,
        eyeRect.left + eyeRect.width * 0.20,
        eyeRect.bottom + eyeRect.height * 0.34,
        eyeRect.left,
        center.dy,
      )
      ..close();

    canvas.drawPath(
      eyePath,
      Paint()
        ..isAntiAlias = true
        ..shader = RadialGradient(
          colors: [
            Color.lerp(const Color(0xFFEAF7F4), primaryColor, 0.18)!,
            const Color(0xFFD6D8C9),
            const Color(0xFF6C7470),
          ],
          stops: const [0.0, 0.68, 1.0],
        ).createShader(eyeRect),
    );
    canvas.drawPath(
      eyePath,
      Paint()
        ..isAntiAlias = true
        ..color = Colors.black.withValues(alpha: 0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.8,
    );

    final veinPaint = Paint()
      ..color = Color.lerp(
        secondaryColor,
        Colors.black,
        0.35,
      )!.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final random = Random(600 + i);
      final side = i.isEven ? -1.0 : 1.0;
      final sx =
          center.dx + side * size.width * (0.12 + random.nextDouble() * .25);
      final sy = center.dy + (random.nextDouble() - .5) * size.height * .22;
      final path = Path()
        ..moveTo(sx, sy)
        ..quadraticBezierTo(
          sx - side * (8 + random.nextDouble() * 18),
          sy + (random.nextDouble() - .5) * 18,
          sx - side * (22 + random.nextDouble() * 24),
          sy + (random.nextDouble() - .5) * 24,
        );
      canvas.drawPath(path, veinPaint);
    }

    final irisRadius = min(size.width, size.height) * 0.18;
    final irisRect = Rect.fromCircle(center: center, radius: irisRadius);
    canvas.drawCircle(
      center,
      irisRadius,
      Paint()
        ..isAntiAlias = true
        ..shader = RadialGradient(
          colors: [
            Color.lerp(primaryColor, const Color(0xFFE3A347), 0.36)!,
            Color.lerp(primaryColor, const Color(0xFFB84A28), 0.55)!,
            Color.lerp(secondaryColor, const Color(0xFF27120F), 0.42)!,
            Colors.black.withValues(alpha: 0.92),
          ],
        ).createShader(irisRect),
    );
    for (int i = 0; i < 36; i++) {
      final angle = (pi * 2 / 36) * i;
      canvas.drawLine(
        Offset(
          center.dx + cos(angle) * irisRadius * 0.42,
          center.dy + sin(angle) * irisRadius * 0.42,
        ),
        Offset(
          center.dx + cos(angle) * irisRadius * 0.88,
          center.dy + sin(angle) * irisRadius * 0.88,
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: i.isEven ? 0.36 : 0.20)
          ..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(
      center,
      irisRadius * 0.36,
      Paint()..color = Colors.black.withValues(alpha: 0.94),
    );
    canvas.drawCircle(
      Offset(center.dx + irisRadius * 0.25, center.dy - irisRadius * 0.34),
      irisRadius * 0.13,
      Paint()
        ..isAntiAlias = true
        ..color = const Color(0xFFFFF5D7).withValues(alpha: 0.78),
    );

    final dripPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.74)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    final beadPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.54)
      ..style = PaintingStyle.fill;
    for (final x in <double>[0.16, 0.27, 0.39, 0.50, 0.62, 0.73, 0.84]) {
      final side = (x - 0.5).abs() / 0.5;
      final startY = center.dy + eyeRect.height * 0.58 - side * 12;
      final endY = startY + 72 - side * 22;
      final dx = size.width * x;
      canvas.drawLine(Offset(dx, startY), Offset(dx, endY), dripPaint);
      canvas.drawCircle(Offset(dx, endY + 5), 4.0, beadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OculumEyePainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.tertiaryColor != tertiaryColor;
  }
}
