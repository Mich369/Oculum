part of '../../main.dart';

/// A responsive, animated horror illustration for the startup role chooser.
/// The central region stays deliberately dark so the live controls remain clear.
class OculumHomeHorrorArtwork extends StatelessWidget {
  const OculumHomeHorrorArtwork({required this.animation, super.key});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _OculumHomeGallery(animation: animation),
            Opacity(
              opacity: 0.13,
              child: Image.asset(
                'assets/themes/materials/wood.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
            CustomPaint(
              painter: _OculumHomeHorrorPainter(animation: animation),
              isComplex: true,
              willChange: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _OculumHomeHorrorPainter extends CustomPainter {
  _OculumHomeHorrorPainter({required this.animation})
    : super(repaint: animation);

  final Animation<double> animation;
  double get phase => animation.value;

  static const Color _ink = Color(0xFF050408);
  static const Color _bronze = Color(0xFF735332);
  static const Color _ash = Color(0xFF77808A);
  static const Color _violet = Color(0xFF583B62);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = min(w, h);
    final scene = phase * 3;
    final current = scene.floor() % 3;
    final blend = (scene - scene.floor()).clamp(0.0, 1.0);

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xAD050408), Color(0xA0050408), Color(0xD9050408)],
          stops: [0, 0.55, 1],
        ).createShader(Offset.zero & size),
    );

    _drawScene(canvas, size, current, 1 - blend * 0.32);
    _drawScene(canvas, size, (current + 1) % 3, blend * 0.32);
    _drawEdgeGrain(canvas, size, unit);
    _drawAtmosphere(canvas, size, unit);

    // Dark vignette and central reading field keep labels and controls crisp.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.08,
          colors: const [
            Color(0xDF050408),
            Color(0x99050408),
            Color(0x10050408),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0x6A050408),
            Color(0x16050408),
            Color(0x16050408),
            Color(0x6A050408),
          ],
          stops: [0, 0.22, 0.78, 1],
        ).createShader(Offset.zero & size),
    );
  }

  void _drawScene(Canvas canvas, Size size, int scene, double opacity) {
    if (opacity <= 0.01) return;
    final w = size.width;
    final h = size.height;
    final alpha = (opacity * 255).round().clamp(0, 255);
    final bronze = _bronze.withAlpha(alpha);
    final ash = _ash.withAlpha((alpha * 0.72).round());
    final violet = _violet.withAlpha((alpha * 0.72).round());
    final dark = _ink.withAlpha((alpha * 0.95).round());

    if (scene == 0) {
      // The drowned chapel: broken towers and a submerged pointed arch.
      _drawTower(canvas, w * 0.045, h * 0.44, w * 0.17, h * 0.31, bronze, dark);
      _drawTower(canvas, w * 0.79, h * 0.38, w * 0.17, h * 0.37, bronze, dark);
      final arch = Path()
        ..moveTo(w * 0.32, h * 0.88)
        ..lineTo(w * 0.32, h * 0.70)
        ..cubicTo(w * 0.34, h * 0.48, w * 0.43, h * 0.40, w * 0.50, h * 0.39)
        ..cubicTo(w * 0.58, h * 0.40, w * 0.66, h * 0.51, w * 0.68, h * 0.70)
        ..lineTo(w * 0.68, h * 0.88);
      canvas.drawPath(
        arch,
        Paint()
          ..color = dark
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        arch,
        Paint()
          ..color = bronze.withAlpha((alpha * 0.60).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.0, min(w, h) * 0.002),
      );
      _drawWaterline(canvas, size, ash);
      _drawRoots(canvas, size, bronze, variant: 0);
    } else if (scene == 1) {
      // Briar manor silhouette, with branches kept on the outer frame.
      final manor = Path()
        ..moveTo(w * 0.16, h * 0.80)
        ..lineTo(w * 0.16, h * 0.39)
        ..lineTo(w * 0.29, h * 0.22)
        ..lineTo(w * 0.40, h * 0.35)
        ..lineTo(w * 0.57, h * 0.19)
        ..lineTo(w * 0.78, h * 0.38)
        ..lineTo(w * 0.78, h * 0.80)
        ..close();
      canvas.drawPath(manor, Paint()..color = dark);
      canvas.drawPath(
        manor,
        Paint()
          ..color = bronze.withAlpha((alpha * 0.62).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.1, min(w, h) * 0.0022),
      );
      for (var i = 0; i < 5; i++) {
        final x = w * (0.25 + i * 0.125);
        final window = Rect.fromLTWH(
          x,
          h * (i.isEven ? 0.49 : 0.56),
          w * 0.024,
          h * 0.11,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(window, Radius.circular(min(w, h) * 0.01)),
          Paint()
            ..color = (i == 3 ? violet : bronze).withAlpha(
              (alpha * 0.42).round(),
            ),
        );
      }
      _drawRoots(canvas, size, bronze, variant: 1);
      _drawGroundThorns(canvas, size, bronze);
    } else {
      // Broken reliquary ring and inset stonework, fading behind the UI.
      final ring = Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.56),
        width: min(w * 0.63, h * 1.16),
        height: min(w * 0.63, h * 1.16),
      );
      canvas.drawArc(
        ring,
        -pi * 0.88,
        pi * 1.72,
        false,
        Paint()
          ..color = bronze.withAlpha((alpha * 0.58).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(3.0, min(w, h) * 0.026),
      );
      canvas.drawArc(
        ring.deflate(min(w, h) * 0.036),
        -pi * 0.76,
        pi * 1.51,
        false,
        Paint()
          ..color = ash.withAlpha((alpha * 0.29).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.0, min(w, h) * 0.002),
      );
      _drawStoneSlabs(canvas, size, bronze);
      _drawRoots(canvas, size, violet, variant: 2);
    }
  }

  void _drawTower(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
    Color line,
    Color fill,
  ) {
    final wall = Path()
      ..moveTo(x, y + height)
      ..lineTo(x, y + height * 0.25)
      ..lineTo(x + width * 0.5, y)
      ..lineTo(x + width, y + height * 0.25)
      ..lineTo(x + width, y + height)
      ..close();
    canvas.drawPath(wall, Paint()..color = fill);
    canvas.drawPath(
      wall,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final slit = Rect.fromLTWH(
      x + width * 0.44,
      y + height * 0.38,
      width * 0.12,
      height * 0.28,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(slit, const Radius.circular(5)),
      Paint()..color = line.withAlpha(65),
    );
  }

  void _drawWaterline(Canvas canvas, Size size, Color color) {
    final w = size.width;
    final h = size.height;
    for (var i = 0; i < 4; i++) {
      final y = h * (0.80 + i * 0.035);
      final path = Path()
        ..moveTo(0, y)
        ..cubicTo(w * 0.22, y - h * 0.025, w * 0.38, y + h * 0.018, w * 0.52, y)
        ..cubicTo(
          w * 0.72,
          y - h * 0.018,
          w * 0.84,
          y + h * 0.02,
          w,
          y - h * 0.008,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withAlpha(28 + i * 8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 + i * 0.3,
      );
    }
  }

  void _drawRoots(
    Canvas canvas,
    Size size,
    Color color, {
    required int variant,
  }) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final paths = <Path>[
      Path()
        ..moveTo(0, h * 0.19)
        ..cubicTo(w * 0.08, h * 0.26, w * 0.03, h * 0.37, w * 0.13, h * 0.49)
        ..cubicTo(w * 0.21, h * 0.58, w * 0.05, h * 0.69, w * 0.17, h * 0.86),
      Path()
        ..moveTo(w, h * 0.15)
        ..cubicTo(w * 0.91, h * 0.24, w * 0.98, h * 0.35, w * 0.87, h * 0.48)
        ..cubicTo(w * 0.79, h * 0.57, w * 0.96, h * 0.72, w * 0.83, h * 0.91),
      Path()
        ..moveTo(w * 0.02, h * 0.96)
        ..cubicTo(w * 0.21, h * 0.84, w * 0.18, h * 0.94, w * 0.29, h * 0.99),
      Path()
        ..moveTo(w * 0.98, h * 0.98)
        ..cubicTo(w * 0.79, h * 0.85, w * 0.82, h * 0.95, w * 0.70, h),
    ];
    for (var i = 0; i < paths.length; i++) {
      paint.strokeWidth = max(1.0, min(w, h) * (i < 2 ? 0.006 : 0.004));
      canvas.drawPath(paths[i], paint);
      if (variant == 1 && i < 2) {
        final branch = Path()
          ..moveTo(i == 0 ? w * 0.08 : w * 0.92, h * 0.52)
          ..quadraticBezierTo(
            i == 0 ? w * 0.18 : w * 0.82,
            h * 0.42,
            i == 0 ? w * 0.12 : w * 0.88,
            h * 0.31,
          );
        canvas.drawPath(
          branch,
          paint..strokeWidth = max(1.0, min(w, h) * 0.003),
        );
      }
    }
  }

  void _drawGroundThorns(Canvas canvas, Size size, Color color) {
    final w = size.width;
    final h = size.height;
    final p = Paint()
      ..color = color.withAlpha(82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, min(w, h) * 0.003);
    for (var side = 0; side < 2; side++) {
      final direction = side == 0 ? 1.0 : -1.0;
      final origin = side == 0 ? 0.0 : w;
      for (var i = 0; i < 7; i++) {
        final x = origin + direction * w * (0.02 + i * 0.023);
        final y = h * (0.97 - (i % 3) * 0.026);
        final thorn = Path()
          ..moveTo(x, y)
          ..lineTo(x + direction * w * 0.04, y - h * 0.05)
          ..lineTo(x + direction * w * 0.07, y - h * 0.02);
        canvas.drawPath(thorn, p);
      }
    }
  }

  void _drawStoneSlabs(Canvas canvas, Size size, Color color) {
    final w = size.width;
    final h = size.height;
    for (var side = 0; side < 2; side++) {
      final x = side == 0 ? w * 0.025 : w * 0.91;
      for (var i = 0; i < 4; i++) {
        final rect = Rect.fromLTWH(
          x,
          h * (0.48 + i * 0.105),
          w * 0.065,
          h * 0.09,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(min(w, h) * 0.008)),
          Paint()..color = _ink.withAlpha(115),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(min(w, h) * 0.008)),
          Paint()
            ..color = color.withAlpha(70)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  void _drawEdgeGrain(Canvas canvas, Size size, double unit) {
    final w = size.width;
    final h = size.height;
    final line = Paint()
      ..color = _bronze.withAlpha(34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 9; i++) {
      final y = h * (0.08 + i * 0.105);
      final sway = sin(i * 1.7) * unit * 0.008;
      final left = Path()
        ..moveTo(0, y)
        ..cubicTo(
          w * 0.055 + sway,
          y - h * 0.018,
          w * 0.022 - sway,
          y + h * 0.02,
          w * 0.105,
          y + h * 0.008,
        );
      final right = Path()
        ..moveTo(w, y + h * 0.02)
        ..cubicTo(
          w * 0.94 - sway,
          y,
          w * 0.98 + sway,
          y - h * 0.018,
          w * 0.895,
          y,
        );
      canvas.drawPath(left, line);
      canvas.drawPath(right, line);
    }
    final border = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        unit * 0.018,
        unit * 0.018,
        max(0.0, w - unit * 0.036),
        max(0.0, h - unit * 0.036),
      ),
      Radius.circular(unit * 0.028),
    );
    canvas.drawRRect(
      border,
      Paint()
        ..color = _bronze.withAlpha(40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, unit * 0.002),
    );
    canvas.drawRRect(
      border.deflate(unit * 0.008),
      Paint()
        ..color = _ash.withAlpha(19)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawAtmosphere(Canvas canvas, Size size, double unit) {
    final w = size.width;
    final h = size.height;
    final drift = phase * 2 * pi;
    for (var i = 0; i < 7; i++) {
      final side = i.isEven ? 1 : -1;
      final x =
          (side == 1 ? w * 0.08 : w * 0.92) + sin(drift + i) * unit * 0.025;
      final y =
          h * (0.24 + (i % 4) * 0.18) + cos(drift * 0.6 + i) * unit * 0.018;
      final radius = unit * (0.0015 + (i % 3) * 0.0008);
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = (i.isEven ? _ash : _bronze).withAlpha(54),
      );
    }
    final haze = Paint()
      ..shader =
          RadialGradient(
            colors: [_violet.withAlpha(14), const Color(0x00050408)],
          ).createShader(
            Rect.fromCenter(
              center: Offset(w * 0.5, h * 0.84),
              width: w * 1.1,
              height: h * 0.4,
            ),
          );
    canvas.drawRect(Offset.zero & size, haze);
  }

  @override
  bool shouldRepaint(covariant _OculumHomeHorrorPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _OculumHomeGallery extends StatefulWidget {
  const _OculumHomeGallery({required this.animation});
  final Animation<double> animation;
  @override
  State<_OculumHomeGallery> createState() => _OculumHomeGalleryState();
}

class _OculumHomeGalleryState extends State<_OculumHomeGallery> {
  static const scenes = ['cathedral_eye', 'solar_islands', 'amber_shore', 'anime_reliquary', 'canva_spirit_duelist'];
  int scene = 0;
  void updateScene() {
    final next = (widget.animation.value * scenes.length).floor().clamp(
      0,
      scenes.length - 1,
    );
    if (next != scene && mounted && !MediaQuery.disableAnimationsOf(context)) {
      setState(() => scene = next);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.animation.addListener(updateScene);
  }

  @override
  void didUpdateWidget(covariant _OculumHomeGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeListener(updateScene);
      widget.animation.addListener(updateScene);
    }
  }

  @override
  void dispose() {
    widget.animation.removeListener(updateScene);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 700),
      child: SizedBox.expand(
        key: ValueKey(scene),
        child: Image.asset(
          'assets/oculum/home_art/${scenes[scene]}.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
        ),
      ),
    ),
  );
}
