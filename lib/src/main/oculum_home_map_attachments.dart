part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

class OculumThemeDecorationSpec {
  const OculumThemeDecorationSpec({
    required this.presetId,
    required this.style,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.backgroundTop,
    required this.backgroundMid,
    required this.backgroundBottom,
    required this.opacity,
    required this.usesBaseColors,
  });

  final String presetId;
  final String style;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color backgroundTop;
  final Color backgroundMid;
  final Color backgroundBottom;
  final double opacity;
  final bool usesBaseColors;
}

class OculumMainSheetGuiStyle {
  const OculumMainSheetGuiStyle({
    required this.id,
    required this.sheetLayoutId,
    required this.cardRadius,
    required this.compactCardRadius,
    required this.borderWidth,
    required this.compactBorderWidth,
    required this.densityLevel,
    required this.panelMood,
  });

  final String id;
  final String sheetLayoutId;
  final double cardRadius;
  final double compactCardRadius;
  final double borderWidth;
  final double compactBorderWidth;
  final double densityLevel;
  final String panelMood;
}

class OculumThemeVisualIdentity {
  const OculumThemeVisualIdentity({
    required this.colorPaletteId,
    required this.decorationIdentityId,
    required this.mainSheetGuiStyle,
    required this.decorationTint,
    required this.decorationOpacity,
    required this.decorationGlow,
  });

  final String colorPaletteId;
  final String decorationIdentityId;
  final OculumMainSheetGuiStyle mainSheetGuiStyle;
  final Color decorationTint;
  final double decorationOpacity;
  final double decorationGlow;
}

class _OculumThemePanelClipper extends CustomClipper<Path> {
  const _OculumThemePanelClipper({
    required this.guiStyle,
    required this.compact,
  });

  final String guiStyle;
  final bool compact;

  @override
  Path getClip(Size size) {
    if (size.isEmpty || size.width < 2 || size.height < 2) {
      return Path()..addRect(Offset.zero & size);
    }
    final minSide = min(size.width, size.height);
    final cut = min(compact ? 10.0 : 16.0, max(2.0, minSide * 0.22));
    final path = Path();
    switch (guiStyle) {
      case 'phobia':
        path
          ..moveTo(cut * 1.8, 0)
          ..lineTo(size.width - cut * 0.7, 0)
          ..lineTo(size.width, cut * 1.4)
          ..lineTo(size.width - cut * 0.5, size.height * 0.52)
          ..lineTo(size.width, size.height - cut * 1.8)
          ..lineTo(size.width - cut * 2.2, size.height)
          ..lineTo(cut * 0.8, size.height)
          ..lineTo(0, size.height - cut * 0.9)
          ..lineTo(cut * 0.6, size.height * 0.48)
          ..lineTo(0, cut * 1.4)
          ..close();
        return path;
      case 'postea':
      case 'kingi':
      case 'medieval':
      case 'bolted_metal':
        path
          ..moveTo(cut * 1.4, 0)
          ..lineTo(size.width - cut * 2.0, 0)
          ..lineTo(size.width, cut * 2.0)
          ..lineTo(size.width, size.height - cut)
          ..lineTo(size.width - cut, size.height)
          ..lineTo(cut * 2.2, size.height)
          ..lineTo(0, size.height - cut * 2.0)
          ..lineTo(0, cut)
          ..close();
        return path;
      case 'roguelike':
        path
          ..moveTo(cut * 0.8, 0)
          ..lineTo(size.width - cut * 2.4, 0)
          ..lineTo(size.width - cut * 0.7, cut * 0.8)
          ..lineTo(size.width, size.height - cut * 1.2)
          ..lineTo(size.width - cut * 1.3, size.height)
          ..lineTo(cut * 2.0, size.height)
          ..lineTo(0, size.height - cut * 1.6)
          ..lineTo(cut * 0.4, size.height * 0.48)
          ..lineTo(0, cut * 1.0)
          ..close();
        return path;
      case 'rank_hud':
      case 'sigil':
      case 'relic':
      case 'archive':
      case 'jrpg':
      case 'souls':
        path
          ..moveTo(cut, 0)
          ..lineTo(size.width - cut, 0)
          ..lineTo(size.width, cut)
          ..lineTo(size.width, size.height - cut)
          ..lineTo(size.width - cut, size.height)
          ..lineTo(cut, size.height)
          ..lineTo(0, size.height - cut)
          ..lineTo(0, cut)
          ..close();
        return path;
      default:
        return Path()..addRRect(
          RRect.fromRectAndRadius(
            Offset.zero & size,
            Radius.circular(compact ? 10 : 14),
          ),
        );
    }
  }

  @override
  bool shouldReclip(covariant _OculumThemePanelClipper oldClipper) {
    return oldClipper.guiStyle != guiStyle || oldClipper.compact != compact;
  }
}

class _OculumThemePanelChromePainter extends CustomPainter {
  const _OculumThemePanelChromePainter({
    required this.spec,
    required this.guiStyle,
    required this.borderColor,
    required this.compact,
    required this.clipped,
  });

  final OculumThemeDecorationSpec spec;
  final String guiStyle;
  final Color borderColor;
  final bool compact;
  final bool clipped;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final alpha = (spec.opacity <= 0 ? 0.22 : spec.opacity * 1.55)
        .clamp(compact ? 0.08 : 0.13, compact ? 0.28 : 0.56)
        .toDouble();
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = compact ? 0.78 : 1.25
      ..color = borderColor.withValues(alpha: alpha);
    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = compact ? 0.70 : 1.10
      ..color = spec.accent.withValues(
        alpha: compact ? alpha * 0.74 : alpha * 0.92,
      );
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.secondary.withValues(
        alpha: compact ? alpha * 0.22 : alpha * 0.36,
      );

    Path diamond(Offset c, double r) => Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.72, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r * 0.72, c.dy)
      ..close();

    if (clipped) {
      final clipPath = _OculumThemePanelClipper(
        guiStyle: guiStyle,
        compact: compact,
      ).getClip(size);
      canvas.drawPath(clipPath, stroke);
    }

    switch (guiStyle) {
      case 'phobia':
        for (var i = 0; i < 5; i++) {
          final x = 14 + i * 34.0;
          canvas.drawLine(Offset(x, 4), Offset(x + 24, 34), accent);
          canvas.drawLine(
            Offset(size.width - x, size.height - 4),
            Offset(size.width - x - 28, size.height - 38),
            stroke,
          );
        }
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width - 34, compact ? 24 : 30),
            width: compact ? 44 : 58,
            height: compact ? 16 : 22,
          ),
          accent,
        );
        canvas.drawCircle(Offset(size.width - 34, compact ? 24 : 30), 4, fill);
        break;
      case 'postea':
      case 'kingi':
      case 'medieval':
        for (var x = 18.0; x < size.width - 18; x += compact ? 42 : 54) {
          final y = compact ? 11.0 : 14.0;
          canvas.drawLine(Offset(x, y), Offset(x + 24, y), accent);
          canvas.drawLine(Offset(x + 24, y), Offset(x + 34, y + 10), stroke);
          canvas.drawCircle(Offset(x + 34, y + 10), 2.2, fill);
        }
        for (var i = 0; i < 3; i++) {
          final c = Offset(size.width - 22 - i * 30, size.height - 18);
          canvas.drawPath(diamond(c, 5.5), i.isEven ? fill : accent);
        }
        break;
      case 'botanical':
        final vine = Path()..moveTo(10, size.height - 18);
        for (var x = 10.0; x < size.width - 10; x += 48) {
          vine.cubicTo(
            x + 12,
            size.height - 36,
            x + 32,
            size.height - 4,
            x + 48,
            size.height - 18,
          );
        }
        canvas.drawPath(vine, accent);
        for (var i = 0; i < 4; i++) {
          final c = Offset(size.width - 24 - i * 28, 18 + (i % 2) * 8);
          final leaf = Path()
            ..moveTo(c.dx - 10, c.dy)
            ..quadraticBezierTo(c.dx, c.dy - 13, c.dx + 14, c.dy - 2)
            ..quadraticBezierTo(c.dx + 1, c.dy + 10, c.dx - 10, c.dy);
          canvas.drawPath(leaf, i.isEven ? fill : accent);
        }
        break;
      case 'lunar':
      case 'soft_orbital':
        for (var i = 0; i < 3; i++) {
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(size.width - 34, 28),
              width: 48 + i * 22,
              height: 34 + i * 14,
            ),
            -pi * 0.22,
            pi * 1.28,
            false,
            i.isEven ? accent : stroke,
          );
        }
        canvas.drawCircle(const Offset(24, 22), compact ? 5 : 7, fill);
        break;
      case 'cathedral':
        for (var i = 0; i < 4; i++) {
          final rect = Rect.fromLTWH(size.width - 28 - i * 28, 8, 18, 38);
          canvas.drawArc(rect, pi, pi, false, i.isEven ? stroke : accent);
          canvas.drawLine(rect.topCenter, rect.bottomCenter, accent);
        }
        break;
      case 'archive':
      case 'relic':
        canvas.drawLine(
          const Offset(14, 8),
          Offset(14, size.height - 8),
          accent,
        );
        canvas.drawLine(
          const Offset(20, 14),
          Offset(20, size.height - 14),
          stroke,
        );
        for (var i = 0; i < 4; i++) {
          canvas.drawPath(diamond(Offset(14, 24 + i * 24), 4.5), fill);
        }
        break;
      case 'jrpg':
        for (final c in <Offset>[
          const Offset(24, 22),
          Offset(size.width - 24, 22),
          Offset(24, size.height - 22),
          Offset(size.width - 24, size.height - 22),
        ]) {
          canvas.drawPath(diamond(c, compact ? 5.0 : 7.0), accent);
          canvas.drawCircle(c, compact ? 7.0 : 9.0, stroke);
        }
        for (var x = 54.0; x < size.width - 48; x += compact ? 54 : 68) {
          final y = compact ? 12.0 : 15.0;
          canvas.drawLine(Offset(x, y), Offset(x + 26, y), accent);
          _paintTinyPanelStar(
            canvas,
            Offset(x + 36, y),
            compact ? 3.0 : 4.0,
            stroke,
          );
        }
        break;
      case 'roguelike':
        for (var i = 0; i < 7; i++) {
          final x = 16 + i * 31.0;
          canvas.drawLine(
            Offset(x, 7 + (i % 2) * 8),
            Offset(x + 24, 21 + (i % 3) * 6),
            i.isEven ? accent : stroke,
          );
          canvas.drawLine(
            Offset(size.width - x, size.height - 8),
            Offset(size.width - x - 20, size.height - 25),
            i.isEven ? stroke : accent,
          );
        }
        canvas.drawCircle(Offset(size.width - 24, 24), 7, fill);
        canvas.drawCircle(Offset(size.width - 24, 24), 11, accent);
        break;
      case 'souls':
        canvas.drawLine(
          const Offset(16, 10),
          Offset(size.width - 16, 10),
          stroke,
        );
        canvas.drawLine(
          Offset(16, size.height - 10),
          Offset(size.width - 16, size.height - 10),
          accent,
        );
        for (final c in <Offset>[
          const Offset(22, 22),
          Offset(size.width - 22, 22),
          Offset(22, size.height - 22),
          Offset(size.width - 22, size.height - 22),
        ]) {
          canvas.drawCircle(c, compact ? 6 : 8, fill);
          canvas.drawArc(
            Rect.fromCircle(center: c, radius: compact ? 9 : 12),
            -pi * 0.72,
            pi * 1.44,
            false,
            accent,
          );
        }
        break;
      case 'bolted_metal':
        for (final c in <Offset>[
          const Offset(18, 18),
          Offset(size.width - 18, 18),
          Offset(18, size.height - 18),
          Offset(size.width - 18, size.height - 18),
        ]) {
          canvas.drawCircle(c, compact ? 5.5 : 7.0, fill);
          canvas.drawCircle(c, compact ? 8.5 : 10.5, stroke);
          canvas.drawLine(c.translate(-4, 0), c.translate(4, 0), accent);
        }
        for (var x = 40.0; x < size.width - 40; x += compact ? 46 : 58) {
          canvas.drawLine(Offset(x, 8), Offset(x + 22, 8), stroke);
          canvas.drawLine(
            Offset(x + 7, size.height - 8),
            Offset(x + 29, size.height - 8),
            accent,
          );
        }
        break;
      case 'wild_companion':
        final vine = Path()..moveTo(12, size.height - 20);
        for (var x = 12.0; x < size.width - 12; x += compact ? 42 : 56) {
          vine.cubicTo(
            x + 12,
            size.height - 36,
            x + 34,
            size.height - 6,
            x + 56,
            size.height - 20,
          );
        }
        canvas.drawPath(vine, accent);
        for (var i = 0; i < 5; i++) {
          final c = Offset(24 + i * 28.0, 18 + (i % 2) * 6);
          canvas.drawCircle(c, 3.2, fill);
          _paintTinyPanelStar(canvas, c.translate(8, 0), 3.2, stroke);
        }
        break;
      case 'modern_school':
        for (
          var y = compact ? 15.0 : 18.0;
          y < size.height - 10;
          y += compact ? 13 : 17
        ) {
          canvas.drawLine(Offset(14, y), Offset(size.width - 12, y), stroke);
        }
        canvas.drawLine(
          const Offset(24, 8),
          Offset(24, size.height - 8),
          accent,
        );
        for (var i = 0; i < 4; i++) {
          final c = Offset(size.width - 24 - i * (compact ? 23.0 : 30.0), 18);
          final note = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: c.translate(0, (i % 2) * 6),
              width: compact ? 15 : 19,
              height: compact ? 10 : 12,
            ),
            const Radius.circular(3),
          );
          canvas.drawRRect(note, i.isEven ? fill : accent);
          canvas.drawRRect(note, i.isEven ? accent : stroke);
        }
        break;
      case 'rank_hud':
      case 'sigil':
        for (final c in <Offset>[
          const Offset(22, 22),
          Offset(size.width - 22, 22),
          Offset(22, size.height - 22),
          Offset(size.width - 22, size.height - 22),
        ]) {
          canvas.drawCircle(c, compact ? 9 : 12, stroke);
          canvas.drawPath(diamond(c, compact ? 5 : 7), accent);
        }
        break;
      case 'elemental':
        for (var i = 0; i < 5; i++) {
          final x = 20 + i * 38.0;
          canvas.drawLine(
            Offset(x, 8),
            Offset(x + 10, compact ? 28 : 38),
            i.isEven ? accent : stroke,
          );
        }
        break;
      default:
        canvas.drawLine(const Offset(12, 12), const Offset(46, 12), stroke);
        canvas.drawLine(const Offset(12, 12), const Offset(12, 46), accent);
        canvas.drawLine(
          Offset(size.width - 12, size.height - 12),
          Offset(size.width - 46, size.height - 12),
          accent,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _OculumThemePanelChromePainter oldDelegate) {
    return oldDelegate.spec.presetId != spec.presetId ||
        oldDelegate.spec.opacity != spec.opacity ||
        oldDelegate.guiStyle != guiStyle ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.compact != compact ||
        oldDelegate.clipped != clipped;
  }
}

class _OculumGuiModePanelPainter extends CustomPainter {
  const _OculumGuiModePanelPainter({
    required this.spec,
    required this.panelMood,
    required this.borderColor,
    required this.compact,
  });

  final OculumThemeDecorationSpec spec;
  final String panelMood;
  final Color borderColor;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final baseAlpha = (spec.opacity * (compact ? 0.24 : 0.36))
        .clamp(0.045, compact ? 0.16 : 0.24)
        .toDouble();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = compact ? 0.65 : 0.9
      ..color = borderColor.withValues(alpha: baseAlpha);
    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = compact ? 0.75 : 1.05
      ..color = spec.accent.withValues(alpha: baseAlpha * 1.15);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.primary.withValues(alpha: baseAlpha * 0.18);

    switch (panelMood) {
      case 'arcade_party_hud':
        for (var y = 8.0; y < size.height; y += compact ? 9 : 12) {
          canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), line);
        }
        for (var i = 0; i < 3; i++) {
          final x = size.width - 18 - i * (compact ? 22.0 : 30.0);
          canvas.drawCircle(Offset(x, 16), compact ? 2.4 : 3.2, fill);
          canvas.drawLine(Offset(x - 7, 16), Offset(x + 7, 16), accent);
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(8, 8, min(72, size.width * 0.28), compact ? 13 : 17),
            Radius.circular(compact ? 3 : 4),
          ),
          accent,
        );
        break;
      case 'crystal_command_menu':
        final rail = Path()
          ..moveTo(12, 14)
          ..lineTo(size.width - 32, 14)
          ..lineTo(size.width - 14, 32)
          ..lineTo(size.width - 14, size.height - 14)
          ..lineTo(32, size.height - 14)
          ..lineTo(14, size.height - 32)
          ..close();
        canvas.drawPath(rail, line);
        for (
          var y = compact ? 15.0 : 18.0;
          y < size.height - 12;
          y += compact ? 13 : 17
        ) {
          canvas.drawLine(Offset(18, y), Offset(size.width - 20, y), line);
        }
        for (var i = 0; i < 4; i++) {
          final c = Offset(22 + i * (compact ? 22.0 : 30.0), 16);
          canvas.drawCircle(c, compact ? 2.4 : 3.2, fill);
          _paintTinyPanelStar(
            canvas,
            c.translate(9, 0),
            compact ? 2.6 : 3.4,
            accent,
          );
        }
        final crystal = Path()
          ..moveTo(size.width - 30, size.height - 38)
          ..lineTo(size.width - 16, size.height - 22)
          ..lineTo(size.width - 30, size.height - 8)
          ..lineTo(size.width - 44, size.height - 22)
          ..close();
        canvas.drawPath(crystal, fill);
        canvas.drawPath(crystal, accent);
        break;
      case 'scrap_run_board':
        for (var y = 10.0; y < size.height - 8; y += compact ? 15 : 19) {
          canvas.drawLine(
            Offset(10, y),
            Offset(size.width - 10, y + ((y.round().isEven) ? 2 : -2)),
            line,
          );
        }
        for (var i = 0; i < 6; i++) {
          final c = Offset(size.width - 18 - i * (compact ? 19.0 : 26.0), 18);
          canvas.drawCircle(c, compact ? 2.8 : 3.6, i.isEven ? fill : accent);
          canvas.drawLine(c.translate(-8, 5), c.translate(8, -5), accent);
        }
        break;
      case 'ashen_boss_frame':
        final bossBar = Rect.fromLTWH(
          16,
          12,
          size.width - 32,
          compact ? 8 : 10,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bossBar, const Radius.circular(2)),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bossBar, const Radius.circular(2)),
          accent,
        );
        for (var i = 0; i < 4; i++) {
          final x = 22 + i * (compact ? 26.0 : 36.0);
          canvas.drawLine(
            Offset(x, size.height - 14),
            Offset(x + 18, size.height - 28),
            i.isEven ? accent : line,
          );
        }
        break;
      case 'bolted_status_rig':
        final step = compact ? 28.0 : 36.0;
        for (var x = step; x < size.width; x += step) {
          canvas.drawLine(Offset(x, 8), Offset(x, size.height - 8), line);
        }
        for (final c in <Offset>[
          const Offset(17, 17),
          Offset(size.width - 17, 17),
          Offset(17, size.height - 17),
          Offset(size.width - 17, size.height - 17),
        ]) {
          canvas.drawCircle(c, compact ? 4.5 : 6.0, fill);
          canvas.drawCircle(c, compact ? 7.5 : 9.0, accent);
        }
        break;
      case 'wild_story_panel':
        final leafLine = Path()..moveTo(10, size.height - 16);
        for (var x = 10.0; x < size.width - 10; x += compact ? 42 : 58) {
          leafLine.cubicTo(
            x + 14,
            size.height - 34,
            x + 36,
            size.height - 2,
            x + 58,
            size.height - 16,
          );
        }
        canvas.drawPath(leafLine, accent);
        for (var i = 0; i < 5; i++) {
          final c = Offset(size.width - 22 - i * 24.0, 18 + (i % 2) * 8);
          canvas.drawCircle(c, 3.4, fill);
          _paintTinyPanelStar(canvas, c, compact ? 3.0 : 4.0, line);
        }
        break;
      case 'school_notebook':
        for (
          var y = compact ? 16.0 : 20.0;
          y < size.height - 10;
          y += compact ? 14 : 18
        ) {
          canvas.drawLine(Offset(14, y), Offset(size.width - 12, y), line);
        }
        canvas.drawLine(
          const Offset(22, 8),
          Offset(22, size.height - 8),
          accent,
        );
        for (var i = 0; i < 4; i++) {
          final c = Offset(
            size.width - 26 - i * (compact ? 22.0 : 30.0),
            18 + (i % 2) * 7,
          );
          _paintTinyPanelStar(
            canvas,
            c,
            compact ? 3.2 : 4.2,
            i.isEven ? accent : line,
          );
        }
        break;
      case 'tactical_command_board':
        final step = compact ? 24.0 : 32.0;
        for (var x = step; x < size.width; x += step) {
          canvas.drawLine(Offset(x, 7), Offset(x, size.height - 7), line);
        }
        for (var y = step; y < size.height; y += step) {
          canvas.drawLine(Offset(7, y), Offset(size.width - 7, y), line);
        }
        for (final c in <Offset>[
          Offset(size.width * 0.28, size.height * 0.42),
          Offset(size.width * 0.72, size.height * 0.58),
        ]) {
          canvas.drawCircle(c, compact ? 8 : 11, accent);
          canvas.drawLine(c.translate(-13, 0), c.translate(13, 0), accent);
          canvas.drawLine(c.translate(0, -13), c.translate(0, 13), accent);
        }
        break;
      case 'combat_first_console':
        final left = Path()
          ..moveTo(9, 9)
          ..lineTo(42, 9)
          ..lineTo(27, 24)
          ..lineTo(9, 24);
        final right = Path()
          ..moveTo(size.width - 9, size.height - 9)
          ..lineTo(size.width - 42, size.height - 9)
          ..lineTo(size.width - 27, size.height - 24)
          ..lineTo(size.width - 9, size.height - 24);
        canvas.drawPath(left, fill);
        canvas.drawPath(left, accent);
        canvas.drawPath(right, fill);
        canvas.drawPath(right, accent);
        for (var x = 20.0; x < size.width - 20; x += compact ? 34 : 46) {
          canvas.drawLine(
            Offset(x, size.height - 10),
            Offset(x + 16, size.height - 10),
            line,
          );
        }
        break;
      case 'indexed_grimoire':
        for (var y = 16.0; y < size.height - 8; y += compact ? 13 : 16) {
          canvas.drawLine(Offset(18, y), Offset(size.width - 18, y), line);
        }
        canvas.drawLine(
          const Offset(14, 8),
          Offset(14, size.height - 8),
          accent,
        );
        for (var i = 0; i < 4; i++) {
          final r = Rect.fromLTWH(size.width - 19, 12 + i * 13, 10, 7);
          canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(2)),
            i.isEven ? fill : accent,
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _OculumGuiModePanelPainter oldDelegate) {
    return oldDelegate.spec.presetId != spec.presetId ||
        oldDelegate.spec.opacity != spec.opacity ||
        oldDelegate.panelMood != panelMood ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.compact != compact;
  }
}

Color _oculumDecorationGradientColor(Color base, Color tint, double alpha) {
  return Color.lerp(base, tint, 0.28)!.withValues(alpha: alpha);
}

Shader _oculumReverseBackgroundShader(
  OculumThemeDecorationSpec spec,
  Size size,
  Color tint,
  double alpha,
) {
  return LinearGradient(
    colors: [
      _oculumDecorationGradientColor(spec.backgroundBottom, tint, alpha),
      _oculumDecorationGradientColor(spec.backgroundMid, tint, alpha * 0.92),
      _oculumDecorationGradientColor(spec.backgroundTop, tint, alpha),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ).createShader(Offset.zero & size);
}

void _paintTinyPanelStar(
  Canvas canvas,
  Offset center,
  double radius,
  Paint paint,
) {
  canvas.drawLine(
    Offset(center.dx - radius, center.dy),
    Offset(center.dx + radius, center.dy),
    paint,
  );
  canvas.drawLine(
    Offset(center.dx, center.dy - radius),
    Offset(center.dx, center.dy + radius),
    paint,
  );
  canvas.drawLine(
    Offset(center.dx - radius * 0.48, center.dy - radius * 0.48),
    Offset(center.dx + radius * 0.48, center.dy + radius * 0.48),
    paint,
  );
  canvas.drawLine(
    Offset(center.dx - radius * 0.48, center.dy + radius * 0.48),
    Offset(center.dx + radius * 0.48, center.dy - radius * 0.48),
    paint,
  );
}

String _oculumTrimUrlCandidate(String value) {
  var candidate = value.trim();
  const leading = '<([{\'"';
  const trailing = '>)]}\'".,;';
  while (candidate.isNotEmpty && leading.contains(candidate[0])) {
    candidate = candidate.substring(1).trimLeft();
  }
  while (candidate.isNotEmpty &&
      trailing.contains(candidate[candidate.length - 1])) {
    candidate = candidate.substring(0, candidate.length - 1).trimRight();
  }
  return candidate;
}

Uri? _oculumUriFromUserText(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  final candidates = <String>[];
  final absoluteMatch = RegExp(
    r'''https?://[^\s<>"']+''',
    caseSensitive: false,
  ).firstMatch(text);
  if (absoluteMatch != null) candidates.add(absoluteMatch.group(0)!);

  final domainMatch = RegExp(
    r'''(?:(?:[a-z0-9-]+\.)+[a-z]{2,})(?::[0-9]{2,5})?(?:/[^\s<>"']*)?''',
    caseSensitive: false,
  ).firstMatch(text);
  if (domainMatch != null) candidates.add(domainMatch.group(0)!);

  candidates.add(text);

  for (final rawCandidate in candidates) {
    var candidate = _oculumTrimUrlCandidate(rawCandidate);
    if (candidate.isEmpty) continue;
    if (!candidate.contains('://')) candidate = 'https://$candidate';
    final uri = Uri.tryParse(candidate);
    if (uri == null || uri.host.trim().isEmpty) continue;
    if (uri.scheme != 'http' && uri.scheme != 'https') continue;
    return uri;
  }

  return null;
}

bool _oculumUsesNgrokWarning(Uri uri) {
  final host = uri.host.toLowerCase();
  return host == 'ngrok-free.dev' ||
      host.endsWith('.ngrok-free.dev') ||
      host.endsWith('.ngrok.io') ||
      host.contains('.ngrok.');
}

Map<String, String> _oculumBrowserHeadersFor(Uri uri) {
  if (!_oculumUsesNgrokWarning(uri)) return const <String, String>{};
  return const <String, String>{'ngrok-skip-browser-warning': 'true'};
}

const String _oculumNgrokBypassScript = r'''
(() => {
  const clickWarning = () => {
    const labels = ['visit site', 'continue to site', 'continue', 'proceed'];
    const nodes = Array.from(document.querySelectorAll('button, a, input[type="submit"]'));
    for (const node of nodes) {
      const text = `${node.innerText || node.value || node.textContent || ''}`.trim().toLowerCase();
      if (labels.some(label => text.includes(label))) {
        node.click();
        return true;
      }
    }
    return false;
  };
  clickWarning();
  let tries = 0;
  const timer = setInterval(() => {
    tries += 1;
    if (clickWarning() || tries > 8) clearInterval(timer);
  }, 350);
})();
''';

class OculumEmbeddedBrowser extends StatefulWidget {
  const OculumEmbeddedBrowser({
    super.key,
    required this.initialUrl,
    required this.title,
    required this.accentColor,
    required this.backgroundColor,
    required this.english,
  });

  final String initialUrl;
  final String title;
  final Color accentColor;
  final Color backgroundColor;
  final bool english;

  @override
  State<OculumEmbeddedBrowser> createState() => _OculumEmbeddedBrowserState();
}

class _OculumEmbeddedBrowserState extends State<OculumEmbeddedBrowser> {
  mobile_webview.WebViewController? _mobileController;
  windows_webview.WebviewController? _windowsController;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _loading = true;
  bool _ready = false;
  bool _canGoBack = false;
  bool _canGoForward = false;
  String _error = '';

  bool get _usesWindowsWebView => !kIsWeb && Platform.isWindows;

  bool get _usesMobileWebView =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  String _tr(String it, String en) => widget.english ? en : it;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    final windowsController = _windowsController;
    if (windowsController != null) {
      unawaited(windowsController.dispose());
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    final uri = _oculumUriFromUserText(widget.initialUrl);
    if (uri == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _ready = false;
        _error = _tr('Link non valido.', 'Invalid link.');
      });
      return;
    }

    if (_usesWindowsWebView) {
      await _initializeWindows(uri);
      return;
    }
    if (_usesMobileWebView) {
      _initializeMobile(uri);
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _ready = false;
      _error = _tr(
        'Browser interno non supportato su questa piattaforma.',
        'Internal browser is not supported on this platform.',
      );
    });
  }

  Future<void> _initializeWindows(Uri uri) async {
    final controller = windows_webview.WebviewController();
    _windowsController = controller;
    final bypassNgrok = _oculumUsesNgrokWarning(uri);
    try {
      await controller.initialize();
      await controller.setBackgroundColor(Colors.transparent);
      if (bypassNgrok) {
        await controller.addScriptToExecuteOnDocumentCreated(
          _oculumNgrokBypassScript,
        );
      }
      await controller.setPopupWindowPolicy(
        windows_webview.WebviewPopupWindowPolicy.sameWindow,
      );
      _subscriptions.add(
        controller.loadingState.listen((state) {
          if (!mounted) return;
          setState(() {
            _loading = state == windows_webview.LoadingState.loading;
          });
          if (bypassNgrok && state != windows_webview.LoadingState.loading) {
            unawaited(
              controller
                  .executeScript(_oculumNgrokBypassScript)
                  .catchError((_) => null),
            );
          }
        }),
      );
      _subscriptions.add(
        controller.historyChanged.listen((history) {
          if (!mounted) return;
          setState(() {
            _canGoBack = history.canGoBack;
            _canGoForward = history.canGoForward;
          });
        }),
      );
      await controller.loadUrl(uri.toString());
      if (!mounted) return;
      setState(() {
        _ready = true;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _ready = false;
        _loading = false;
        _error = _tr(
          'WebView2 non disponibile o pagina non caricabile: $error',
          'WebView2 is unavailable or the page cannot be loaded: $error',
        );
      });
    }
  }

  void _initializeMobile(Uri uri) {
    final controller = mobile_webview.WebViewController()
      ..setJavaScriptMode(mobile_webview.JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        mobile_webview.NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _loading = progress < 100);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
            unawaited(_refreshMobileHistory());
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) return;
            setState(() {
              _loading = false;
              _error = error.description;
            });
          },
        ),
      );
    _mobileController = controller;
    setState(() {
      _ready = true;
      _loading = true;
    });
    unawaited(
      controller.loadRequest(uri, headers: _oculumBrowserHeadersFor(uri)),
    );
  }

  Future<void> _refreshMobileHistory() async {
    final controller = _mobileController;
    if (controller == null) return;
    final canBack = await controller.canGoBack();
    final canForward = await controller.canGoForward();
    if (!mounted) return;
    setState(() {
      _canGoBack = canBack;
      _canGoForward = canForward;
    });
  }

  Future<void> _goBack() async {
    if (!_canGoBack) return;
    if (_usesWindowsWebView) {
      await _windowsController?.goBack();
    } else {
      await _mobileController?.goBack();
      await _refreshMobileHistory();
    }
  }

  Future<void> _goForward() async {
    if (!_canGoForward) return;
    if (_usesWindowsWebView) {
      await _windowsController?.goForward();
    } else {
      await _mobileController?.goForward();
      await _refreshMobileHistory();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _error = '';
      _loading = true;
    });
    if (_usesWindowsWebView) {
      await _windowsController?.reload();
    } else {
      await _mobileController?.reload();
    }
  }

  Future<void> _openExternal() async {
    final uri = _oculumUriFromUserText(widget.initialUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _body() {
    if (_error.isNotEmpty && !_ready) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.public_off, color: widget.accentColor, size: 42),
              const SizedBox(height: 10),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _openExternal,
                icon: const Icon(Icons.open_in_browser),
                label: Text(_tr('Browser esterno', 'External browser')),
              ),
            ],
          ),
        ),
      );
    }

    if (_usesWindowsWebView) {
      final controller = _windowsController;
      if (controller == null || !controller.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }
      return windows_webview.Webview(controller);
    }

    final mobileController = _mobileController;
    if (mobileController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return mobile_webview.WebViewWidget(controller: mobileController);
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.accentColor.withValues(alpha: 0.42);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.backgroundColor.withValues(alpha: 0.92),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.black.withValues(alpha: 0.28),
            child: SizedBox(
              height: 42,
              child: Row(
                children: [
                  IconButton(
                    tooltip: _tr('Indietro', 'Back'),
                    onPressed: _canGoBack ? _goBack : null,
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                  ),
                  IconButton(
                    tooltip: _tr('Avanti', 'Forward'),
                    onPressed: _canGoForward ? _goForward : null,
                    icon: const Icon(Icons.arrow_forward),
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.accentColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _tr('Ricarica', 'Reload'),
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    color: Colors.white,
                  ),
                  IconButton(
                    tooltip: _tr('Browser esterno', 'External browser'),
                    onPressed: _openExternal,
                    icon: const Icon(Icons.open_in_browser),
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          if (_loading) LinearProgressIndicator(color: widget.accentColor),
          if (_error.isNotEmpty && _ready)
            Material(
              color: Colors.red.shade900.withValues(alpha: 0.72),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _error = ''),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(child: _body()),
        ],
      ),
    );
  }
}

class OculumInAppBrowserPage extends StatefulWidget {
  const OculumInAppBrowserPage({
    super.key,
    required this.initialUrl,
    required this.title,
    required this.accentColor,
    required this.backgroundColor,
    required this.english,
  });

  final String initialUrl;
  final String title;
  final Color accentColor;
  final Color backgroundColor;
  final bool english;

  @override
  State<OculumInAppBrowserPage> createState() => _OculumInAppBrowserPageState();
}

class _OculumInAppBrowserPageState extends State<OculumInAppBrowserPage> {
  final TextEditingController _urlController = TextEditingController();
  mobile_webview.WebViewController? _mobileController;
  windows_webview.WebviewController? _windowsController;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _loading = true;
  bool _ready = false;
  bool _canGoBack = false;
  bool _canGoForward = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.initialUrl;
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _urlController.dispose();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    final windowsController = _windowsController;
    if (windowsController != null) {
      unawaited(windowsController.dispose());
    }
    super.dispose();
  }

  bool get _usesWindowsWebView => !kIsWeb && Platform.isWindows;

  bool get _usesMobileWebView =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  String _tr(String it, String en) => widget.english ? en : it;

  Future<void> _initialize() async {
    if (_usesWindowsWebView) {
      await _initializeWindows();
      return;
    }
    if (_usesMobileWebView) {
      _initializeMobile();
      return;
    }
    setState(() {
      _loading = false;
      _ready = false;
      _error = _tr(
        'Browser interno non supportato su questa piattaforma. Usa il browser esterno.',
        'Internal browser is not supported on this platform. Use the external browser.',
      );
    });
  }

  Future<void> _initializeWindows() async {
    final controller = windows_webview.WebviewController();
    _windowsController = controller;
    final initialUri =
        _oculumUriFromUserText(widget.initialUrl) ??
        Uri.tryParse(widget.initialUrl);
    final bypassNgrok =
        initialUri != null && _oculumUsesNgrokWarning(initialUri);
    try {
      await controller.initialize();
      await controller.setBackgroundColor(Colors.transparent);
      if (bypassNgrok) {
        await controller.addScriptToExecuteOnDocumentCreated(
          _oculumNgrokBypassScript,
        );
      }
      await controller.setPopupWindowPolicy(
        windows_webview.WebviewPopupWindowPolicy.sameWindow,
      );
      _subscriptions.add(
        controller.url.listen((url) {
          if (!mounted) return;
          setState(() => _urlController.text = url);
        }),
      );
      _subscriptions.add(
        controller.loadingState.listen((state) {
          if (!mounted) return;
          setState(() {
            _loading = state == windows_webview.LoadingState.loading;
          });
          if (bypassNgrok && state != windows_webview.LoadingState.loading) {
            unawaited(
              controller
                  .executeScript(_oculumNgrokBypassScript)
                  .catchError((_) => null),
            );
          }
        }),
      );
      _subscriptions.add(
        controller.historyChanged.listen((history) {
          if (!mounted) return;
          setState(() {
            _canGoBack = history.canGoBack;
            _canGoForward = history.canGoForward;
          });
        }),
      );
      await controller.loadUrl(widget.initialUrl);
      if (!mounted) return;
      setState(() {
        _ready = true;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _ready = false;
        _loading = false;
        _error = _tr(
          'WebView2 non disponibile o pagina non caricabile: $error. Puoi aprire il link nel browser esterno.',
          'WebView2 is unavailable or the page cannot be loaded: $error. You can open the link in the external browser.',
        );
      });
    }
  }

  void _initializeMobile() {
    final controller = mobile_webview.WebViewController()
      ..setJavaScriptMode(mobile_webview.JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        mobile_webview.NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _loading = progress < 100);
          },
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _urlController.text = url;
              _loading = true;
            });
            unawaited(_refreshMobileHistory());
          },
          onPageFinished: (url) {
            if (!mounted) return;
            setState(() {
              _urlController.text = url;
              _loading = false;
            });
            unawaited(_refreshMobileHistory());
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) return;
            setState(() {
              _loading = false;
              _error = error.description;
            });
          },
          onUrlChange: (change) {
            final url = change.url;
            if (!mounted || url == null) return;
            setState(() => _urlController.text = url);
          },
        ),
      );
    _mobileController = controller;
    setState(() {
      _ready = true;
      _loading = true;
    });
    final uri = _oculumUriFromUserText(widget.initialUrl);
    if (uri == null) {
      setState(() {
        _ready = false;
        _loading = false;
        _error = _tr('Link non valido.', 'Invalid link.');
      });
      return;
    }
    unawaited(
      controller.loadRequest(uri, headers: _oculumBrowserHeadersFor(uri)),
    );
  }

  Future<void> _refreshMobileHistory() async {
    final controller = _mobileController;
    if (controller == null) return;
    final canBack = await controller.canGoBack();
    final canForward = await controller.canGoForward();
    if (!mounted) return;
    setState(() {
      _canGoBack = canBack;
      _canGoForward = canForward;
    });
  }

  Uri? _normalizedTypedUri() {
    return _oculumUriFromUserText(_urlController.text);
  }

  Future<void> _loadTypedUrl() async {
    final uri = _normalizedTypedUri();
    if (uri == null) return;
    setState(() {
      _error = '';
      _loading = true;
      _urlController.text = uri.toString();
    });
    if (_usesWindowsWebView) {
      await _windowsController?.loadUrl(uri.toString());
    } else {
      await _mobileController?.loadRequest(
        uri,
        headers: _oculumBrowserHeadersFor(uri),
      );
    }
  }

  Future<void> _goBack() async {
    if (!_canGoBack) return;
    if (_usesWindowsWebView) {
      await _windowsController?.goBack();
    } else {
      await _mobileController?.goBack();
      await _refreshMobileHistory();
    }
  }

  Future<void> _goForward() async {
    if (!_canGoForward) return;
    if (_usesWindowsWebView) {
      await _windowsController?.goForward();
    } else {
      await _mobileController?.goForward();
      await _refreshMobileHistory();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _error = '';
      _loading = true;
    });
    if (_usesWindowsWebView) {
      await _windowsController?.reload();
    } else {
      await _mobileController?.reload();
    }
  }

  Future<void> _openExternal() async {
    final uri = _normalizedTypedUri() ?? Uri.tryParse(widget.initialUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _browserBody() {
    if (_error.isNotEmpty && !_ready) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.public_off, color: widget.accentColor, size: 44),
              const SizedBox(height: 12),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _openExternal,
                icon: const Icon(Icons.open_in_browser),
                label: Text(
                  _tr('Apri nel browser esterno', 'Open in external browser'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_usesWindowsWebView) {
      final controller = _windowsController;
      if (controller == null || !controller.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }
      return windows_webview.Webview(controller);
    }

    final mobileController = _mobileController;
    if (mobileController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return mobile_webview.WebViewWidget(controller: mobileController);
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.accentColor.withValues(alpha: 0.48);
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.backgroundColor,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: _tr('Browser esterno', 'External browser'),
            onPressed: _openExternal,
            icon: const Icon(Icons.open_in_browser),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(57),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: _tr('Indietro', 'Back'),
                  onPressed: _canGoBack ? _goBack : null,
                  icon: const Icon(Icons.arrow_back),
                ),
                IconButton(
                  tooltip: _tr('Avanti', 'Forward'),
                  onPressed: _canGoForward ? _goForward : null,
                  icon: const Icon(Icons.arrow_forward),
                ),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _loadTypedUrl(),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: widget.accentColor,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.30),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: border),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _tr('Vai', 'Go'),
                  onPressed: _loadTypedUrl,
                  icon: const Icon(Icons.keyboard_return),
                ),
                IconButton(
                  tooltip: _tr('Ricarica', 'Reload'),
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_loading) LinearProgressIndicator(color: widget.accentColor),
          if (_error.isNotEmpty && _ready)
            Material(
              color: Colors.red.shade900.withValues(alpha: 0.78),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _error = ''),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(child: _browserBody()),
        ],
      ),
    );
  }
}

bool oculumThemeStartsUnlocked(String id) {
  return id.trim().isNotEmpty;
}

extension _OculumHomeMapAttachments on _OculumHomePageState {
  // =====================================================
  // DECORAZIONI TEMA
  // =====================================================

  bool hoshySecretThemeCondition() {
    final currentName = cleanUiText(nomeController.text).trim().toLowerCase();
    if (currentName == 'hoshy') return true;
    return schedePersonaggio.any(
      (sheet) =>
          cleanUiText('${sheet['nome'] ?? ''}').trim().toLowerCase() == 'hoshy',
    );
  }

  bool phobiaSecretThemeCondition() {
    final currentName = cleanUiText(nomeController.text).trim().toLowerCase();
    if (currentName == 'vergil') return true;
    return schedePersonaggio.any(
      (sheet) =>
          cleanUiText('${sheet['nome'] ?? ''}').trim().toLowerCase() ==
          'vergil',
    );
  }

  bool ensureSecretThemeUnlocks({bool announce = false}) {
    var unlocked = false;
    if (hoshySecretThemeCondition() &&
        !unlockedColorThemeIds.contains('hoshy_cosmic_cat')) {
      unlockedColorThemeIds.add('hoshy_cosmic_cat');
      unlocked = true;
      if (announce) {
        risultato = t(
          'Achievement segreto: tema Hoshy gatto cosmico sbloccato.',
          'Secret achievement: Hoshy cosmic cat theme unlocked.',
        );
        aggiungiLog(risultato);
      }
    }
    if (phobiaSecretThemeCondition() &&
        !unlockedColorThemeIds.contains('phobia_dark')) {
      unlockedColorThemeIds.add('phobia_dark');
      unlocked = true;
      if (announce) {
        risultato = t(
          'Achievement segreto: tema Phobia sbloccato da Vergil.',
          'Secret achievement: Phobia theme unlocked by Vergil.',
        );
        aggiungiLog(risultato);
      }
    }
    return unlocked;
  }

  String themeDecorationStyleForPreset(String id) {
    switch (id) {
      case 'none':
      case 'classic_reliquary':
      case 'classic_low_detail':
        return 'none';
      case 'lunar_eclipse':
      case 'moon_iron':
      case 'moon_rot':
        return 'lunar';
      case 'cathedral_rose':
      case 'witch_glass':
      case 'blood_chapel':
      case 'bone_saint':
      case 'verdigris_mourning':
        return 'cathedral';
      case 'medieval_keep':
        return 'medieval';
      case 'fortezza_oculum':
        return 'fortress_oculum';
      case 'postea_bloom':
        return 'postea';
      case 'vervain_gothic':
        return 'vervain';
      case 'kingi_wrong_future':
        return 'kingi';
      case 'jrpg_legend':
        return 'jrpg';
      case 'rogue_mutation':
      case 'cell_crimson_run':
      case 'darkest_stagecoach':
        return 'roguelike';
      case 'ashen_covenant':
      case 'eclipse_bonfire':
        return 'souls';
      case 'bolted_black_iron':
      case 'bolted_gold_plate':
      case 'bolted_copper_oxide':
      case 'bolted_silver_plate':
        return 'bolted_metal';
      case 'meadow_sprite':
      case 'aurora_moth':
        return 'wild_companion';
      case 'modern_school_day':
        return 'modern_school';
      case 'vtt_arcane_table':
      case 'vtt_master_overlay':
        return 'sigil';
      case 'vtt_obsidian_grid':
        return 'shadow_gate';
      case 'vtt_parchment_layers':
        return 'archive';
      case 'thorn_vigil':
      case 'blood_court':
      case 'monster_lantern':
      case 'deep_forest_demon':
        return 'thorn';
      case 'obsidian_sigil':
      case 'void_liturgy':
      case 'karma_duality':
      case 'null_crown':
        return 'sigil';
      case 'phobia_dark':
      case 'whispering_reliquary':
        return 'phobia';
      case 'black_briar_kingdom':
        return 'souls';
      case 'shadow_gate_rank':
        return 'shadow_gate';
      case 'frost_chapel':
        return 'frost';
      case 'storm_cathedral':
        return 'storm';
      case 'abyssal_tide':
        return 'tide';
      case 'ember_rite':
        return 'ember';
      case 'ivory_archive':
      case 'astral_ink':
        return 'archive';
      case 'slime_prince':
        return 'slime';
      case 'obser_relic':
        return 'obser';
      case 'hoshy_cosmic_cat':
        return 'hoshy';
      case 'solar_reliquary':
      case 'ash_oracle':
      default:
        return 'reliquary';
    }
  }

  String themeDecorationLabel(String id) {
    if (themeDecorationStyleForPreset(id) == 'none') {
      return t('senza decorazioni', 'no decorations');
    }
    switch (id) {
      case 'blood_court':
        return t('corona e gocce di sangue', 'blood drops and crown');
      case 'witch_glass':
        return t('schegge di vetro strega', 'witch-glass shards');
      case 'moon_iron':
        return t('lame di ferro lunare', 'moon-iron blades');
      case 'lunar_eclipse':
        return t('eclissi e fasi lunari', 'eclipse and moon phases');
      case 'cathedral_rose':
        return t('rosone da cattedrale', 'cathedral rose window');
      case 'thorn_vigil':
        return t('veglia di rovi vivi', 'living thorn vigil');
      case 'frost_chapel':
        return t('cristalli da cappella fredda', 'cold chapel crystals');
      case 'obsidian_sigil':
        return t('sigilli di ossidiana', 'obsidian sigils');
      case 'solar_reliquary':
        return t('sole reliquiario', 'reliquary sun');
      case 'storm_cathedral':
        return t('fulmini da cattedrale', 'cathedral lightning');
      case 'abyssal_tide':
        return t('onde e perle abissali', 'abyssal waves and pearls');
      case 'ember_rite':
        return t('candele e brace rituale', 'ritual candles and embers');
      case 'ivory_archive':
        return t('libro e glifi d archivio', 'archive book and glyphs');
      case 'vervain_gothic':
        return t('fiori Vervain e rovi', 'Vervain flowers and thorns');
      case 'kingi_wrong_future':
        return t('motore runico Kingi', 'Kingi runic engine');
      case 'blood_chapel':
        return t(
          'rosone e teschi da cappella',
          'rose window and chapel skulls',
        );
      case 'null_crown':
        return t('corona del vuoto', 'void crown');
      case 'whispering_reliquary':
        return t(
          'reliquiario incrinato, graffi e sussurri',
          'cracked reliquary, scratches and whispers',
        );
      case 'black_briar_kingdom':
        return t(
          'rovi neri, corona consunta e brace regale',
          'black briars, worn crown and royal embers',
        );
      case 'slime_prince':
        return t('corona gelatinosa regale', 'royal slime crown');
      case 'moon_rot':
        return t('luna marcia e spore', 'rotten moon and spores');
      case 'obser_relic':
        return t('occhi incisi Obser', 'carved Obser eyes');
      case 'deep_forest_demon':
        return t('radici e lanterne profonde', 'deep roots and lanterns');
      case 'astral_ink':
        return t('inchiostro astrale e stelle', 'astral ink and stars');
      case 'bone_saint':
        return t('aureole e ossa sante', 'haloes and saint bones');
      case 'medieval_keep':
        return t(
          'torri, scudi e spade medievali',
          'medieval towers, shields and swords',
        );
      case 'fortezza_oculum':
        return t(
          'fortezza nera, cornici ferrate e Occhio viola',
          'black fortress, iron frames and violet Eye',
        );
      case 'ash_oracle':
        return t('oracolo di cenere stellare', 'star-ash oracle');
      case 'void_liturgy':
        return t('vuoti liturgici', 'liturgical voids');
      case 'shadow_gate_rank':
        return t('porta d ombra e rango', 'shadow gate and rank');
      case 'postea_bloom':
        return t(
          'circuiti, rune e fiori sintetici Postea',
          'Postea circuits, runes and synthetic flowers',
        );
      case 'karma_duality':
        return t(
          'bilancia, lune e sigillo karma',
          'karma scales, moons and sigil',
        );
      case 'monster_lantern':
        return t('lanterne da mostro e rovi', 'monster lanterns and thorns');
      case 'vtt_arcane_table':
        return t(
          'griglia arcana da tavolo virtuale',
          'arcane virtual-table grid',
        );
      case 'vtt_obsidian_grid':
        return t(
          'overlay ossidiana da mappa digitale',
          'obsidian digital-map overlay',
        );
      case 'vtt_parchment_layers':
        return t(
          'strati di pergamena e indici',
          'parchment layers and indexes',
        );
      case 'vtt_master_overlay':
        return t(
          'marcatori del Master e note critiche',
          'Master markers and critical notes',
        );
      case 'jrpg_legend':
        return t(
          'cristalli, stelle e bestiario JRPG',
          'crystals, stars and JRPG bestiary',
        );
      case 'rogue_mutation':
        return t(
          'mutazioni, scarti e run sporche',
          'mutations, scrap and dirty runs',
        );
      case 'cell_crimson_run':
        return t(
          'celle cremisi e scatti laterali',
          'crimson cells and side dashes',
        );
      case 'darkest_stagecoach':
        return t(
          'carrozza, lanterna e pergamena cupa',
          'stagecoach, lantern and dark parchment',
        );
      case 'ashen_covenant':
        return t(
          'cenere, brace e patto inciso',
          'ash, embers and carved covenant',
        );
      case 'eclipse_bonfire':
        return t(
          'falò d eclissi e acciaio sacro',
          'eclipse bonfire and sacred steel',
        );
      case 'bolted_black_iron':
        return t('placche nere e bulloni', 'black plates and bolts');
      case 'bolted_gold_plate':
        return t('placche dorate e bulloni', 'gold plates and bolts');
      case 'bolted_copper_oxide':
        return t(
          'rame ossidato e zolle verdi',
          'oxidized copper and green chunks',
        );
      case 'bolted_silver_plate':
        return t('argento freddo e bulloni', 'cold silver and bolts');
      case 'meadow_sprite':
        return t('spirito di prato in basso', 'meadow spirit at the corner');
      case 'aurora_moth':
        return t('falena aurora e rugiada', 'aurora moth and dew');
      case 'modern_school_day':
        return t(
          'quaderno, penne e graffiti leggeri',
          'notebook, pens and light graffiti',
        );
      case 'verdigris_mourning':
        return t(
          'rame verde e fiori funebri',
          'verdigris and mourning flowers',
        );
    }
    switch (themeDecorationStyleForPreset(id)) {
      case 'lunar':
        return t('lune laterali', 'side moons');
      case 'cathedral':
        return t('vetrate sottili', 'thin stained glass');
      case 'medieval':
        return t('mastio e armi medievali', 'keep and medieval arms');
      case 'fortress_oculum':
        return t('fortezza dell Occhio', 'Eye fortress');
      case 'postea':
        return t('rune e circuiti Postea', 'Postea rune circuits');
      case 'thorn':
        return t('rovi rituali', 'ritual thorns');
      case 'vervain':
        return t('rovi Vervain e fiori', 'Vervain thorns and flowers');
      case 'kingi':
        return t('metallo runico Kingi', 'Kingi runic metal');
      case 'phobia':
        return t('incubi Phobia', 'Phobia nightmares');
      case 'shadow_gate':
        return t('porta di rango', 'rank gate');
      case 'sigil':
        return t('sigilli ai margini', 'edge sigils');
      case 'frost':
        return t('cristalli freddi', 'cold crystals');
      case 'storm':
        return t('fulmini e pioggia rituale', 'lightning and ritual rain');
      case 'tide':
        return t('onde abissali e perle', 'abyssal waves and pearls');
      case 'ember':
        return t('candele e scintille', 'candles and sparks');
      case 'archive':
        return t('glifi e manoscritti', 'glyphs and manuscripts');
      case 'slime':
        return t('gelatina regale', 'royal slime');
      case 'obser':
        return t('reliquia Obser incisa', 'carved Obser relic');
      case 'hoshy':
        return t('orecchie feline e luna indaco', 'cat ears and indigo moon');
      case 'jrpg':
        return t(
          'menu cristallini e bestiario da avventura',
          'crystal menus and adventure bestiary',
        );
      case 'roguelike':
        return t(
          'run sporche e HUD da sopravvivenza',
          'dirty runs and survival HUD',
        );
      case 'souls':
        return t('boss frame, cenere e reliquia', 'boss frame, ash and relic');
      case 'bolted_metal':
        return t('placche metalliche bullonate', 'bolted metal plates');
      case 'wild_companion':
        return t(
          'natura viva e compagno illustrato',
          'living nature and illustrated companion',
        );
      case 'modern_school':
        return t('diario scolastico moderno', 'modern school diary');
      default:
        return t('cornici reliquia', 'reliquary frames');
    }
  }

  bool themeDecorationUsesBaseColors(String id) {
    switch (id) {
      case 'kingi_wrong_future':
      case 'phobia_dark':
      case 'whispering_reliquary':
      case 'black_briar_kingdom':
      case 'hoshy_cosmic_cat':
      case 'postea_bloom':
      case 'shadow_gate_rank':
      case 'karma_duality':
      case 'monster_lantern':
      case 'slime_prince':
      case 'obser_relic':
      case 'deep_forest_demon':
      case 'vervain_gothic':
      case 'medieval_keep':
      case 'jrpg_legend':
      case 'rogue_mutation':
      case 'cell_crimson_run':
      case 'darkest_stagecoach':
      case 'ashen_covenant':
      case 'eclipse_bonfire':
      case 'bolted_black_iron':
      case 'bolted_gold_plate':
      case 'bolted_copper_oxide':
      case 'bolted_silver_plate':
      case 'meadow_sprite':
      case 'aurora_moth':
      case 'modern_school_day':
        return false;
      default:
        return true;
    }
  }

  OculumThemeDecorationSpec currentThemeDecorationSpec() {
    final decorationId = visualThemeDecorationPresetId();
    final style = themeDecorationStyleForPreset(decorationId);
    final light = modalitaLeggera || modalitaVeloce;
    final kingiWorn = kingiEquippedVisualEffect();
    final usesBaseColors = themeDecorationUsesBaseColors(decorationId);
    final fixedPreset = usesBaseColors ? null : colorPresetById(decorationId);
    final sourcePrimary = fixedPreset?.primary ?? primaryColor;
    final sourceSecondary = fixedPreset?.tertiary ?? tertiaryColor;
    final sourceAccent = fixedPreset?.eyePupilGlow ?? eyePupilGlowColor;
    final sourceTop = fixedPreset?.backgroundTop ?? backgroundTopColor;
    final sourceMid = fixedPreset?.backgroundMid ?? backgroundMidColor;
    final sourceBottom = fixedPreset?.backgroundBottom ?? backgroundBottomColor;
    final opacity =
        (light ? 0.155 : 0.315) *
        (kingiWorn ? 1.24 : 1.0) *
        themeDecorationOpacityScale *
        themeDecorationIntensityScale;
    final kingiColorTint = kingiWorn && decorationId != 'kingi_wrong_future';
    final metalPrimary = Color.lerp(
      sourcePrimary,
      const Color(0xFF8FE6FF),
      kingiColorTint ? 0.62 : 0.0,
    )!;
    final metalSecondary = Color.lerp(
      sourceSecondary,
      const Color(0xFF35435A),
      kingiColorTint ? 0.58 : 0.0,
    )!;
    final electricBlue = Color.lerp(
      sourceAccent,
      const Color(0xFF16C8FF),
      kingiColorTint ? 0.78 : 0.0,
    )!;
    final metalTop = Color.lerp(
      sourceTop,
      const Color(0xFF050B16),
      kingiColorTint ? 0.44 : 0.0,
    )!;
    final metalMid = Color.lerp(
      sourceMid,
      const Color(0xFF142032),
      kingiColorTint ? 0.48 : 0.0,
    )!;
    final metalBottom = Color.lerp(
      sourceBottom,
      const Color(0xFF020611),
      kingiColorTint ? 0.52 : 0.0,
    )!;
    return OculumThemeDecorationSpec(
      presetId: kingiWorn ? '${decorationId}_worn' : decorationId,
      style: style,
      primary: metalPrimary,
      secondary: metalSecondary,
      accent: electricBlue,
      backgroundTop: metalTop,
      backgroundMid: metalMid,
      backgroundBottom: metalBottom,
      opacity: style == 'none' ? 0 : opacity.clamp(0.080, 0.68).toDouble(),
      usesBaseColors: usesBaseColors,
    );
  }

  OculumThemeVisualIdentity currentThemeVisualIdentity() {
    final light = modalitaLeggera || modalitaVeloce;
    final decorationId = visualThemeDecorationPresetId();
    final kingiWorn = kingiEquippedVisualEffect();
    return OculumThemeVisualIdentity(
      colorPaletteId: colorPresetSelezionato,
      decorationIdentityId: kingiWorn ? '${decorationId}_worn' : decorationId,
      mainSheetGuiStyle: guiStyleForPreset(visualThemeGuiPresetId()),
      decorationTint: kingiWorn ? const Color(0xFF16C8FF) : eyePupilGlowColor,
      decorationOpacity: themeDecorationStyleForPreset(decorationId) == 'none'
          ? 0
          : ((light ? 0.110 : 0.215) *
                    (kingiWorn ? 1.24 : 1.0) *
                    themeDecorationOpacityScale)
                .clamp(0.055, 0.52)
                .toDouble(),
      decorationGlow:
          ((light ? 0.55 : 1.0) *
                  (kingiWorn ? 1.35 : 1.0) *
                  themeDecorationGlowScale)
              .clamp(0.0, 2.5)
              .toDouble(),
    );
  }

  bool kingiEquippedVisualEffect() {
    final resolvedGui = activeThemeGuiPresetId();
    final classicGui =
        resolvedGui == 'classic_reliquary' ||
        resolvedGui == 'classic_low_detail';
    final originalBaseSelected =
        colorPresetSelezionato == 'classic_reliquary' &&
        colorDecorationPresetId == 'none' &&
        classicGui;
    final undecoratedClassicGui =
        colorDecorationPresetId == 'none' && classicGui;
    if (originalBaseSelected ||
        undecoratedClassicGui ||
        colorPresetSelezionato == 'classic_low_detail' ||
        resolvedGui == 'classic_low_detail') {
      return false;
    }
    bool hasKingi(String value) {
      final clean = cleanUiText(value).toLowerCase();
      return RegExp(r'(^|[^a-z0-9])kingi([^a-z0-9]|$)').hasMatch(clean);
    }

    for (final titolo in titoliCalcolabili) {
      if (!titolo.equipaggiato) continue;
      if (hasKingi(
        [
          titolo.nome,
          titolo.tipo,
          titolo.buff,
          titolo.skill,
          titolo.openName,
          titolo.openDescription,
          titolo.chiaveSistema,
        ].join(' '),
      )) {
        return true;
      }
    }
    for (final item in inventario) {
      if (!item.equipaggiata) continue;
      if (hasKingi('${item.nome} ${item.buff} ${item.note}')) {
        return true;
      }
    }
    for (final skill in skills) {
      if (!skill.equipaggiata) continue;
      final formText = skill.forme
          .map(
            (form) =>
                '${form.nome} ${form.tipo} ${form.descrizione} ${form.buff} ${form.note}',
          )
          .join(' ');
      if (hasKingi(
        '${skill.nome} ${skill.tipo} ${skill.descrizione} $formText',
      )) {
        return true;
      }
    }
    return false;
  }

  bool isBuiltInGuiModeId(String id) {
    return const <String>{
      'gui_auto',
      'gui_classic',
      'gui_low_detail',
      'gui_videogame_hud',
      'gui_tactical_board',
      'gui_battle_focus',
      'gui_quick_grimoire',
      'gui_soft_orbit',
      'gui_medieval_armory',
      'gui_living_vines',
    }.contains(id.trim());
  }

  String guiModeBasePresetId(String id) {
    switch (id.trim()) {
      case 'gui_classic':
        return 'classic_reliquary';
      case 'gui_low_detail':
        return 'classic_low_detail';
      case 'gui_videogame_hud':
        return 'shadow_gate_rank';
      case 'gui_tactical_board':
        return 'obsidian_sigil';
      case 'gui_battle_focus':
        return 'phobia_dark';
      case 'gui_quick_grimoire':
        return 'ivory_archive';
      case 'gui_soft_orbit':
        return 'slime_prince';
      case 'gui_medieval_armory':
        return 'medieval_keep';
      case 'gui_living_vines':
        return 'vervain_gothic';
      default:
        return 'classic_reliquary';
    }
  }

  String resolveGuiChoiceToPresetId(String id) {
    final clean = id.trim();
    if (clean == 'gui_auto') {
      final decoration = activeThemeDecorationPresetId();
      if (decoration != 'none') return decoration;
      if (colorPresetSelezionato != 'custom' &&
          colorPresets.any((preset) => preset.id == colorPresetSelezionato)) {
        return colorPresetSelezionato;
      }
      return 'classic_reliquary';
    }
    if (isBuiltInGuiModeId(clean)) return guiModeBasePresetId(clean);
    return clean;
  }

  String activeGuiChoiceId() {
    final clean = colorGuiPresetId.trim();
    if (isBuiltInGuiModeId(clean)) return clean;
    if (clean.isNotEmpty &&
        clean != 'custom' &&
        colorPresets.any((preset) => preset.id == clean) &&
        isColorThemeUnlocked(clean)) {
      return clean;
    }
    final decoration = activeThemeDecorationPresetId();
    if (decoration != 'none') return decoration;
    return 'classic_reliquary';
  }

  String sheetLayoutIdForPreset(String id) {
    switch (id.trim()) {
      case 'gui_videogame_hud':
        return 'video_hud';
      case 'gui_tactical_board':
        return 'tactical_board';
      case 'gui_battle_focus':
        return 'battle_focus';
      case 'gui_quick_grimoire':
        return 'quick_grimoire';
      case 'gui_soft_orbit':
        return 'soft_orbit';
      case 'gui_medieval_armory':
        return 'medieval';
      case 'gui_living_vines':
        return 'botanical';
      case 'gui_classic':
      case 'gui_low_detail':
        return 'classic';
    }
    switch (id) {
      case 'classic_rpg':
        return 'medieval';
      case 'classic_low_detail':
      case 'classic_reliquary':
        return 'classic';
      case 'blood_court':
      case 'blood_chapel':
      case 'ember_rite':
      case 'solar_reliquary':
        return 'altar';
      case 'cathedral_rose':
      case 'witch_glass':
      case 'bone_saint':
      case 'verdigris_mourning':
        return 'chapel';
      case 'medieval_keep':
        return 'medieval';
      case 'lunar_eclipse':
      case 'moon_iron':
      case 'moon_rot':
      case 'hoshy_cosmic_cat':
        return 'orbital';
      case 'thorn_vigil':
      case 'vervain_gothic':
      case 'deep_forest_demon':
        return 'botanical';
      case 'monster_lantern':
        return 'lantern';
      case 'jrpg_legend':
        return 'video_hud';
      case 'rogue_mutation':
      case 'cell_crimson_run':
      case 'darkest_stagecoach':
        return 'battle_focus';
      case 'ashen_covenant':
      case 'eclipse_bonfire':
        return 'quick_grimoire';
      case 'bolted_black_iron':
      case 'bolted_gold_plate':
      case 'bolted_copper_oxide':
      case 'bolted_silver_plate':
        return 'video_hud';
      case 'meadow_sprite':
      case 'aurora_moth':
        return 'soft_orbit';
      case 'modern_school_day':
        return 'video_hud';
      case 'vtt_arcane_table':
      case 'vtt_master_overlay':
        return 'tactical_board';
      case 'vtt_obsidian_grid':
        return 'battle_focus';
      case 'vtt_parchment_layers':
        return 'quick_grimoire';
      case 'postea_bloom':
        return 'machine';
      case 'obsidian_sigil':
      case 'void_liturgy':
      case 'karma_duality':
      case 'shadow_gate_rank':
      case 'null_crown':
        return 'sigil';
      case 'frost_chapel':
      case 'storm_cathedral':
      case 'abyssal_tide':
        return 'elemental';
      case 'ivory_archive':
      case 'astral_ink':
      case 'ash_oracle':
        return 'archive';
      case 'kingi_wrong_future':
        return 'machine';
      case 'phobia_dark':
        return 'phobia';
      case 'slime_prince':
        return 'slime';
      case 'obser_relic':
        return 'relic';
      default:
        return 'reliquary';
    }
  }

  OculumMainSheetGuiStyle guiStyleForPreset(String id) {
    final requestedId = id.trim();
    final resolvedId = resolveGuiChoiceToPresetId(requestedId);
    final layoutSource =
        isBuiltInGuiModeId(requestedId) && requestedId != 'gui_auto'
        ? requestedId
        : resolvedId;
    final layoutId = sheetLayoutIdForPreset(layoutSource);
    if (resolvedId == 'classic_low_detail') {
      return const OculumMainSheetGuiStyle(
        id: 'low_detail',
        sheetLayoutId: 'classic',
        cardRadius: 8,
        compactCardRadius: 6,
        borderWidth: 0.9,
        compactBorderWidth: 0.8,
        densityLevel: 1.34,
        panelMood: 'low_detail',
      );
    }
    if (resolvedId == 'classic_rpg') {
      return OculumMainSheetGuiStyle(
        id: 'classic_rpg',
        sheetLayoutId: 'medieval',
        cardRadius: 8,
        compactCardRadius: 6,
        borderWidth: 1.8,
        compactBorderWidth: 1.25,
        densityLevel: 0.98,
        panelMood: 'indexed_grimoire',
      );
    }
    if (requestedId == 'gui_videogame_hud') {
      return OculumMainSheetGuiStyle(
        id: 'rank_hud',
        sheetLayoutId: layoutId,
        cardRadius: 6,
        compactCardRadius: 4,
        borderWidth: 1.65,
        compactBorderWidth: 1.20,
        densityLevel: 1.22,
        panelMood: 'arcade_party_hud',
      );
    }
    if (requestedId == 'gui_tactical_board') {
      return OculumMainSheetGuiStyle(
        id: 'sigil',
        sheetLayoutId: layoutId,
        cardRadius: 8,
        compactCardRadius: 6,
        borderWidth: 1.46,
        compactBorderWidth: 1.10,
        densityLevel: 1.12,
        panelMood: 'tactical_command_board',
      );
    }
    if (requestedId == 'gui_battle_focus') {
      return OculumMainSheetGuiStyle(
        id: 'phobia',
        sheetLayoutId: layoutId,
        cardRadius: 5,
        compactCardRadius: 4,
        borderWidth: 1.72,
        compactBorderWidth: 1.26,
        densityLevel: 1.28,
        panelMood: 'combat_first_console',
      );
    }
    if (requestedId == 'gui_quick_grimoire') {
      return OculumMainSheetGuiStyle(
        id: 'archive',
        sheetLayoutId: layoutId,
        cardRadius: 8,
        compactCardRadius: 7,
        borderWidth: 1.20,
        compactBorderWidth: 1.0,
        densityLevel: 1.16,
        panelMood: 'indexed_grimoire',
      );
    }
    final style = themeDecorationStyleForPreset(resolvedId);
    switch (style) {
      case 'fortress_oculum':
        return OculumMainSheetGuiStyle(
          id: 'fortress_oculum',
          sheetLayoutId: layoutId,
          cardRadius: 6,
          compactCardRadius: 4,
          borderWidth: 1.82,
          compactBorderWidth: 1.34,
          densityLevel: 1.18,
          panelMood: 'black_fortress_hud',
        );
      case 'postea':
        return OculumMainSheetGuiStyle(
          id: 'postea',
          sheetLayoutId: layoutId,
          cardRadius: 8,
          compactCardRadius: 6,
          borderWidth: 1.48,
          compactBorderWidth: 1.16,
          densityLevel: 1.10,
          panelMood: 'errant_rune_tech',
        );
      case 'shadow_gate':
        return OculumMainSheetGuiStyle(
          id: 'rank_hud',
          sheetLayoutId: layoutId,
          cardRadius: 7,
          compactCardRadius: 5,
          borderWidth: 1.62,
          compactBorderWidth: 1.22,
          densityLevel: 1.18,
          panelMood: 'shadow_rank_gate',
        );
      case 'phobia':
        return OculumMainSheetGuiStyle(
          id: 'phobia',
          sheetLayoutId: layoutId,
          cardRadius: 6,
          compactCardRadius: 4,
          borderWidth: 1.75,
          compactBorderWidth: 1.35,
          densityLevel: 1.24,
          panelMood: 'compressed_shadow',
        );
      case 'kingi':
        return OculumMainSheetGuiStyle(
          id: 'kingi',
          sheetLayoutId: layoutId,
          cardRadius: 7,
          compactCardRadius: 5,
          borderWidth: 1.55,
          compactBorderWidth: 1.20,
          densityLevel: 1.12,
          panelMood: 'metal_plate',
        );
      case 'jrpg':
        return OculumMainSheetGuiStyle(
          id: 'jrpg',
          sheetLayoutId: layoutId,
          cardRadius: 9,
          compactCardRadius: 7,
          borderWidth: 1.46,
          compactBorderWidth: 1.14,
          densityLevel: 1.14,
          panelMood: 'crystal_command_menu',
        );
      case 'roguelike':
        return OculumMainSheetGuiStyle(
          id: 'roguelike',
          sheetLayoutId: layoutId,
          cardRadius: 5,
          compactCardRadius: 4,
          borderWidth: 1.62,
          compactBorderWidth: 1.18,
          densityLevel: 1.24,
          panelMood: 'scrap_run_board',
        );
      case 'souls':
        return OculumMainSheetGuiStyle(
          id: 'souls',
          sheetLayoutId: layoutId,
          cardRadius: 7,
          compactCardRadius: 5,
          borderWidth: 1.50,
          compactBorderWidth: 1.14,
          densityLevel: 1.10,
          panelMood: 'ashen_boss_frame',
        );
      case 'bolted_metal':
        return OculumMainSheetGuiStyle(
          id: 'bolted_metal',
          sheetLayoutId: layoutId,
          cardRadius: 4,
          compactCardRadius: 3,
          borderWidth: 1.82,
          compactBorderWidth: 1.32,
          densityLevel: 1.20,
          panelMood: 'bolted_status_rig',
        );
      case 'wild_companion':
        return OculumMainSheetGuiStyle(
          id: 'wild_companion',
          sheetLayoutId: layoutId,
          cardRadius: 15,
          compactCardRadius: 11,
          borderWidth: 1.26,
          compactBorderWidth: 1.02,
          densityLevel: 0.98,
          panelMood: 'wild_story_panel',
        );
      case 'modern_school':
        return OculumMainSheetGuiStyle(
          id: 'modern_school',
          sheetLayoutId: layoutId,
          cardRadius: 7,
          compactCardRadius: 5,
          borderWidth: 1.12,
          compactBorderWidth: 0.90,
          densityLevel: 1.12,
          panelMood: 'school_notebook',
        );
      case 'lunar':
        return OculumMainSheetGuiStyle(
          id: 'lunar',
          sheetLayoutId: layoutId,
          cardRadius: 15,
          compactCardRadius: 11,
          borderWidth: 1.18,
          compactBorderWidth: 1.0,
          densityLevel: 0.98,
          panelMood: 'moon_orbit',
        );
      case 'vervain':
      case 'thorn':
        return OculumMainSheetGuiStyle(
          id: 'botanical',
          sheetLayoutId: layoutId,
          cardRadius: 13,
          compactCardRadius: 10,
          borderWidth: 1.28,
          compactBorderWidth: 1.08,
          densityLevel: 0.96,
          panelMood: 'living_vine',
        );
      case 'cathedral':
        return OculumMainSheetGuiStyle(
          id: 'cathedral',
          sheetLayoutId: layoutId,
          cardRadius: 11,
          compactCardRadius: 8,
          borderWidth: 1.48,
          compactBorderWidth: 1.18,
          densityLevel: 1.0,
          panelMood: 'stained_arch',
        );
      case 'medieval':
        return OculumMainSheetGuiStyle(
          id: 'medieval',
          sheetLayoutId: layoutId,
          cardRadius: 8,
          compactCardRadius: 6,
          borderWidth: 1.55,
          compactBorderWidth: 1.18,
          densityLevel: 1.12,
          panelMood: 'stone_keep',
        );
      case 'archive':
        return OculumMainSheetGuiStyle(
          id: 'archive',
          sheetLayoutId: layoutId,
          cardRadius: 8,
          compactCardRadius: 7,
          borderWidth: 1.25,
          compactBorderWidth: 1.05,
          densityLevel: 1.06,
          panelMood: 'grimoire_page',
        );
      case 'frost':
        return OculumMainSheetGuiStyle(
          id: 'frost',
          sheetLayoutId: layoutId,
          cardRadius: 9,
          compactCardRadius: 7,
          borderWidth: 1.35,
          compactBorderWidth: 1.12,
          densityLevel: 1.02,
          panelMood: 'ice_edge',
        );
      case 'sigil':
        return OculumMainSheetGuiStyle(
          id: 'sigil',
          sheetLayoutId: layoutId,
          cardRadius: 9,
          compactCardRadius: 7,
          borderWidth: 1.42,
          compactBorderWidth: 1.12,
          densityLevel: 1.10,
          panelMood: 'angular_sigil',
        );
      case 'storm':
      case 'tide':
      case 'ember':
        return OculumMainSheetGuiStyle(
          id: 'elemental',
          sheetLayoutId: layoutId,
          cardRadius: 10,
          compactCardRadius: 8,
          borderWidth: 1.36,
          compactBorderWidth: 1.10,
          densityLevel: 1.04,
          panelMood: 'elemental_edge',
        );
      case 'obser':
        return OculumMainSheetGuiStyle(
          id: 'relic',
          sheetLayoutId: layoutId,
          cardRadius: 8,
          compactCardRadius: 6,
          borderWidth: 1.52,
          compactBorderWidth: 1.18,
          densityLevel: 1.08,
          panelMood: 'carved_relic',
        );
      case 'slime':
      case 'hoshy':
        return OculumMainSheetGuiStyle(
          id: 'soft_orbital',
          sheetLayoutId: layoutId,
          cardRadius: 16,
          compactCardRadius: 12,
          borderWidth: 1.20,
          compactBorderWidth: 1.0,
          densityLevel: 0.94,
          panelMood: 'soft_glow',
        );
      default:
        return OculumMainSheetGuiStyle(
          id: 'reliquary',
          sheetLayoutId: layoutId,
          cardRadius: 12,
          compactCardRadius: 9,
          borderWidth: 1.15,
          compactBorderWidth: 1.0,
          densityLevel: 1.0,
          panelMood: 'reliquary',
        );
    }
  }

  String activeThemeDecorationPresetId() {
    if (colorDecorationPresetId == 'none') return 'none';
    if (colorDecorationPresetId.trim().isNotEmpty &&
        colorDecorationPresetId != 'custom' &&
        colorPresets.any((preset) => preset.id == colorDecorationPresetId) &&
        isColorThemeUnlocked(colorDecorationPresetId)) {
      return colorDecorationPresetId;
    }
    if (colorPresetSelezionato != 'custom' &&
        colorPresetSelezionato != 'classic_reliquary' &&
        colorPresetSelezionato != 'classic_low_detail' &&
        colorPresets.any((preset) => preset.id == colorPresetSelezionato) &&
        isColorThemeUnlocked(colorPresetSelezionato)) {
      return colorPresetSelezionato;
    }
    return 'none';
  }

  String visualThemeDecorationPresetId() {
    if (kingiEquippedVisualEffect()) return 'kingi_wrong_future';
    return activeThemeDecorationPresetId();
  }

  String activeThemeGuiPresetId() {
    final clean = colorGuiPresetId.trim();
    if (isBuiltInGuiModeId(clean)) {
      return resolveGuiChoiceToPresetId(clean);
    }
    if (clean.isNotEmpty &&
        clean != 'custom' &&
        colorPresets.any((preset) => preset.id == clean) &&
        isColorThemeUnlocked(clean)) {
      return clean;
    }
    final decoration = activeThemeDecorationPresetId();
    if (decoration != 'none') return decoration;
    return 'classic_reliquary';
  }

  String visualThemeGuiPresetId() {
    final explicitGui =
        colorGuiPresetId.trim().isNotEmpty &&
        colorGuiPresetId.trim() != 'gui_auto';
    if (!explicitGui && kingiEquippedVisualEffect()) {
      return 'kingi_wrong_future';
    }
    if (isBuiltInGuiModeId(colorGuiPresetId.trim())) {
      return colorGuiPresetId.trim();
    }
    return activeThemeGuiPresetId();
  }

  Widget themeDecorationBackdrop() {
    final spec = currentThemeDecorationSpec();
    if (spec.opacity <= 0) {
      return const SizedBox.expand();
    }
    final desktopPainting = themeUsesDesktopPainting();
    return LayoutBuilder(
      builder: (context, constraints) {
        final robotWidth =
            (constraints.maxWidth * (desktopPainting ? 0.26 : 0.46))
                .clamp(150.0, desktopPainting ? 390.0 : 260.0)
                .toDouble();
        final robotCacheWidth = oculumImageCacheDimension(
          context,
          robotWidth,
          max: desktopPainting ? 960 : 640,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: _OculumThemeDecorationPainter(
                  spec,
                  desktop: desktopPainting,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            if (spec.style == 'kingi')
              Positioned(
                right: -robotWidth * 0.08,
                bottom: -robotWidth * 0.04,
                width: robotWidth,
                child: Opacity(
                  opacity: (0.34 * themeDecorationOpacityScale)
                      .clamp(0.16, 0.48)
                      .toDouble(),
                  child: Image.asset(
                    'assets/oculum/kingi_robot.png',
                    fit: BoxFit.contain,
                    cacheWidth: robotCacheWidth,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            if (spec.style == 'jrpg')
              Positioned(
                right: -robotWidth * 0.06,
                bottom: -robotWidth * 0.03,
                width: robotWidth,
                height: robotWidth * 1.08,
                child: Opacity(
                  opacity: (0.38 * themeDecorationOpacityScale)
                      .clamp(0.16, 0.52)
                      .toDouble(),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _OculumJrpgCompanionPainter(spec: spec),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget themePanelDecoration(Color borderColor) {
    final spec = currentThemeDecorationSpec();
    if (spec.opacity <= 0 || modalitaLeggera || modalitaVeloce) {
      return const SizedBox.expand();
    }
    return RepaintBoundary(
      child: CustomPaint(
        painter: _OculumThemePanelDecorationPainter(
          spec,
          borderColor,
          modalitaLeggera || modalitaVeloce,
          desktop: themeUsesDesktopPainting(),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  bool themeUsesDesktopPainting() {
    final media = MediaQuery.maybeOf(context);
    final width = media?.size.width ?? 1280;
    return !modalitaLeggera &&
        !modalitaVeloce &&
        !phoneCompactUi &&
        width >= 860;
  }

  bool themeUsesStackedVitalsHud() {
    return const <String>{
      'rank_hud',
      'jrpg',
      'roguelike',
      'souls',
      'bolted_metal',
      'modern_school',
    }.contains(currentThemeVisualIdentity().mainSheetGuiStyle.id);
  }

  double themePanelRadiusValue({bool compact = false}) {
    final gui = currentThemeVisualIdentity().mainSheetGuiStyle;
    return compact ? gui.compactCardRadius : gui.cardRadius;
  }

  double themePanelBorderWidth({bool compact = false}) {
    final gui = currentThemeVisualIdentity().mainSheetGuiStyle;
    return compact ? gui.compactBorderWidth : gui.borderWidth;
  }

  LinearGradient themePanelSurfaceGradient(
    Color borderColor, {
    bool compact = false,
  }) {
    final spec = currentThemeDecorationSpec();
    final gui = currentThemeVisualIdentity().mainSheetGuiStyle;
    final guiStyle = gui.id;
    final panelMood = gui.panelMood;
    final minReadableAlpha = compact ? 0.97 : 0.965;
    Color mix(Color base, Color tint, double t, double alpha) => Color.lerp(
      base,
      tint,
      t,
    )!.withValues(alpha: alpha.clamp(minReadableAlpha, 1.0).toDouble());

    switch (panelMood) {
      case 'arcade_party_hud':
        return LinearGradient(
          colors: [
            mix(spec.backgroundBottom, const Color(0xFF071523), 0.62, 0.98),
            mix(spec.backgroundMid, spec.accent, 0.22, 0.95),
            mix(spec.backgroundBottom, const Color(0xFF02050A), 0.70, 0.98),
          ],
          stops: const [0.0, 0.52, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'tactical_command_board':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, const Color(0xFF102018), 0.42, 0.96),
            mix(spec.backgroundMid, spec.primary, 0.12, 0.94),
            mix(spec.backgroundBottom, const Color(0xFF050B10), 0.46, 0.97),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        );
      case 'combat_first_console':
        return LinearGradient(
          colors: [
            mix(spec.backgroundBottom, const Color(0xFF160409), 0.62, 0.99),
            mix(spec.backgroundMid, spec.accent, 0.18, 0.95),
            mix(spec.backgroundBottom, Colors.black, 0.54, 0.99),
          ],
          stops: const [0.0, 0.48, 1.0],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'indexed_grimoire':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, const Color(0xFF241D12), 0.32, 0.96),
            mix(spec.backgroundMid, spec.secondary, 0.11, 0.94),
            mix(spec.backgroundBottom, const Color(0xFF090705), 0.34, 0.97),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
        );
      case 'crystal_command_menu':
        return LinearGradient(
          colors: [
            mix(spec.backgroundBottom, const Color(0xFF081138), 0.66, 0.98),
            mix(spec.backgroundMid, spec.accent, 0.14, 0.95),
            mix(spec.backgroundTop, const Color(0xFF18265F), 0.40, 0.96),
            mix(spec.backgroundBottom, spec.primary, 0.07, 0.99),
          ],
          stops: const [0.0, 0.42, 0.76, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'scrap_run_board':
        return LinearGradient(
          colors: [
            mix(spec.backgroundBottom, const Color(0xFF0B0705), 0.62, 0.99),
            mix(spec.backgroundMid, spec.primary, 0.10, 0.95),
            mix(spec.backgroundTop, spec.accent, 0.16, 0.96),
          ],
          stops: const [0.0, 0.52, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'ashen_boss_frame':
        return LinearGradient(
          colors: [
            mix(spec.backgroundBottom, Colors.black, 0.34, 0.99),
            mix(spec.backgroundMid, const Color(0xFF2A1B12), 0.36, 0.95),
            mix(spec.backgroundTop, spec.accent, 0.10, 0.97),
          ],
          stops: const [0.0, 0.58, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        );
      case 'bolted_status_rig':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, spec.primary, 0.13, 0.98),
            mix(spec.backgroundMid, const Color(0xFF111417), 0.34, 0.97),
            mix(spec.backgroundBottom, Colors.black, 0.26, 0.99),
          ],
          stops: const [0.0, 0.44, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'wild_story_panel':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, spec.primary, 0.12, 0.94),
            mix(spec.backgroundMid, spec.accent, 0.10, 0.91),
            mix(spec.backgroundBottom, spec.secondary, 0.12, 0.95),
          ],
          stops: const [0.0, 0.54, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'school_notebook':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, const Color(0xFF152B35), 0.38, 0.96),
            mix(spec.backgroundMid, spec.primary, 0.08, 0.94),
            mix(spec.backgroundBottom, spec.accent, 0.10, 0.97),
          ],
          stops: const [0.0, 0.54, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }

    switch (guiStyle) {
      case 'low_detail':
        return LinearGradient(
          colors: [
            mix(spec.backgroundMid, Colors.black, 0.10, 0.96),
            mix(spec.backgroundBottom, Colors.black, 0.18, 0.97),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'phobia':
        return LinearGradient(
          colors: [
            mix(spec.backgroundBottom, Colors.black, 0.35, 0.98),
            mix(spec.backgroundMid, const Color(0xFF21080D), 0.56, 0.96),
            mix(spec.backgroundTop, spec.accent, 0.16, 0.94),
          ],
          stops: const [0.0, 0.55, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'kingi':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, const Color(0xFF8EA4B8), 0.16, 0.96),
            mix(spec.backgroundMid, const Color(0xFF202A36), 0.54, 0.94),
            mix(spec.backgroundBottom, const Color(0xFF0C1E32), 0.54, 0.97),
            mix(spec.backgroundBottom, spec.accent, 0.18, 0.96),
          ],
          stops: const [0.0, 0.36, 0.78, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'jrpg':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, const Color(0xFF1C2A64), 0.40, 0.96),
            mix(spec.backgroundMid, spec.accent, 0.12, 0.94),
            mix(spec.backgroundBottom, const Color(0xFF070817), 0.52, 0.98),
          ],
          stops: const [0.0, 0.50, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'roguelike':
        return LinearGradient(
          colors: [
            mix(spec.backgroundBottom, Colors.black, 0.20, 0.98),
            mix(spec.backgroundMid, spec.primary, 0.09, 0.95),
            mix(spec.backgroundTop, spec.accent, 0.14, 0.97),
          ],
          stops: const [0.0, 0.56, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'souls':
        return LinearGradient(
          colors: [
            mix(spec.backgroundBottom, Colors.black, 0.28, 0.99),
            mix(spec.backgroundMid, const Color(0xFF25160E), 0.30, 0.96),
            mix(spec.backgroundTop, spec.accent, 0.09, 0.97),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        );
      case 'bolted_metal':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, spec.primary, 0.12, 0.98),
            mix(spec.backgroundMid, const Color(0xFF15171A), 0.32, 0.97),
            mix(spec.backgroundBottom, Colors.black, 0.22, 0.99),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'wild_companion':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, spec.primary, 0.12, 0.92),
            mix(spec.backgroundMid, spec.secondary, 0.18, 0.90),
            mix(spec.backgroundBottom, spec.accent, 0.09, 0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'modern_school':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, const Color(0xFF1A2B34), 0.30, 0.96),
            mix(spec.backgroundMid, spec.primary, 0.07, 0.93),
            mix(spec.backgroundBottom, spec.accent, 0.08, 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'postea':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, const Color(0xFF7AA6C8), 0.18, 0.95),
            mix(spec.backgroundMid, const Color(0xFF172331), 0.52, 0.93),
            mix(spec.backgroundBottom, spec.accent, 0.18, 0.96),
          ],
          stops: const [0.0, 0.52, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'medieval':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, const Color(0xFF534636), 0.30, 0.96),
            mix(spec.backgroundMid, const Color(0xFF17120C), 0.46, 0.95),
            mix(spec.backgroundBottom, spec.accent, 0.10, 0.97),
          ],
          stops: const [0.0, 0.58, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'rank_hud':
        return LinearGradient(
          colors: [
            mix(spec.backgroundBottom, const Color(0xFF17134A), 0.42, 0.98),
            mix(spec.backgroundMid, spec.accent, 0.18, 0.95),
            mix(spec.backgroundTop, spec.primary, 0.10, 0.94),
          ],
          stops: const [0.0, 0.58, 1.0],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'sigil':
        return LinearGradient(
          colors: [
            mix(spec.backgroundBottom, spec.accent, 0.10, 0.97),
            mix(spec.backgroundMid, Colors.black, 0.28, 0.95),
            mix(spec.backgroundTop, spec.primary, 0.14, 0.93),
          ],
          stops: const [0.0, 0.58, 1.0],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'elemental':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, spec.accent, 0.18, 0.93),
            mix(spec.backgroundMid, spec.secondary, 0.20, 0.92),
            mix(spec.backgroundBottom, spec.primary, 0.12, 0.96),
          ],
          stops: const [0.0, 0.46, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        );
      case 'relic':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, spec.primary, 0.10, 0.95),
            mix(spec.backgroundMid, const Color(0xFF11100B), 0.42, 0.94),
            mix(spec.backgroundBottom, spec.accent, 0.08, 0.97),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
        );
      case 'vervain':
      case 'botanical':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, spec.secondary, 0.36, 0.88),
            mix(spec.backgroundMid, const Color(0xFF160A12), 0.48, 0.90),
            mix(spec.backgroundBottom, spec.primary, 0.10, 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'lunar':
      case 'soft_orbital':
      case 'hoshy':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, spec.accent, 0.12, 0.90),
            mix(spec.backgroundMid, spec.primary, 0.07, 0.91),
            mix(spec.backgroundBottom, spec.secondary, 0.18, 0.95),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        );
      case 'slime':
        return LinearGradient(
          colors: [
            mix(spec.backgroundTop, spec.primary, 0.13, 0.92),
            mix(spec.backgroundMid, spec.secondary, 0.30, 0.90),
            mix(spec.backgroundBottom, spec.accent, 0.14, 0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: compact
              ? [
                  mix(spec.backgroundMid, borderColor, 0.07, 0.94),
                  mix(spec.backgroundBottom, Colors.black, 0.18, 0.95),
                ]
              : [
                  mix(spec.backgroundTop, borderColor, 0.07, 0.92),
                  mix(spec.backgroundMid, Colors.black, 0.18, 0.93),
                  mix(spec.backgroundBottom, borderColor, 0.05, 0.96),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  List<BoxShadow> themePanelBoxShadows(Color color, {bool compact = false}) {
    if (compact) return const <BoxShadow>[];
    final identity = currentThemeVisualIdentity();
    if (identity.mainSheetGuiStyle.id == 'low_detail') {
      return const <BoxShadow>[];
    }
    final spec = currentThemeDecorationSpec();
    final glowScale = identity.decorationGlow;
    final glow = spec.style == 'phobia' || spec.style == 'shadow_gate'
        ? spec.accent
        : spec.style == 'kingi' || spec.style == 'postea'
        ? const Color(0xFF16C8FF)
        : spec.style == 'jrpg'
        ? const Color(0xFFE7B84A)
        : spec.style == 'roguelike'
        ? const Color(0xFFE6543A)
        : spec.style == 'souls'
        ? const Color(0xFFFF8A3D)
        : spec.style == 'bolted_metal'
        ? spec.primary
        : spec.style == 'wild_companion'
        ? spec.accent
        : spec.style == 'modern_school'
        ? const Color(0xFFFF6B8A)
        : spec.style == 'medieval'
        ? const Color(0xFFE0A84A)
        : color;
    return [
      BoxShadow(
        color: glow.withValues(
          alpha:
              (spec.style == 'phobia' || spec.style == 'shadow_gate'
                  ? 0.11
                  : spec.style == 'kingi' || spec.style == 'postea'
                  ? 0.14
                  : spec.style == 'jrpg'
                  ? 0.12
                  : spec.style == 'roguelike' ||
                        spec.style == 'souls' ||
                        spec.style == 'bolted_metal'
                  ? 0.13
                  : spec.style == 'wild_companion'
                  ? 0.10
                  : spec.style == 'modern_school'
                  ? 0.11
                  : spec.style == 'medieval'
                  ? 0.14
                  : 0.08) *
              glowScale,
        ),
        blurRadius:
            (spec.style == 'phobia' || spec.style == 'shadow_gate'
                ? 14
                : spec.style == 'kingi' || spec.style == 'postea'
                ? 18
                : spec.style == 'jrpg'
                ? 16
                : spec.style == 'roguelike' ||
                      spec.style == 'souls' ||
                      spec.style == 'bolted_metal'
                ? 15
                : spec.style == 'wild_companion'
                ? 13
                : spec.style == 'modern_school'
                ? 14
                : spec.style == 'medieval'
                ? 18
                : 9) *
            max(0.2, glowScale),
        spreadRadius:
            spec.style == 'kingi' ||
                spec.style == 'postea' ||
                spec.style == 'medieval' ||
                spec.style == 'jrpg' ||
                spec.style == 'bolted_metal'
            ? 0.6
            : spec.style == 'roguelike' || spec.style == 'souls'
            ? 0.35
            : spec.style == 'phobia' || spec.style == 'shadow_gate'
            ? 0.1
            : 0.2,
      ),
      const BoxShadow(
        color: Colors.black54,
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ];
  }

  Color themeFieldFillColor() {
    final spec = currentThemeDecorationSpec();
    final gui = currentThemeVisualIdentity().mainSheetGuiStyle.id;
    if (spec.style == 'none' || gui == 'low_detail') {
      return const Color(0xFF09070D);
    }

    Color mix(Color base, Color tint, double amount, double alpha) {
      return Color.lerp(base, tint, amount)!.withValues(alpha: alpha);
    }

    switch (spec.style) {
      case 'phobia':
      case 'shadow_gate':
        return mix(spec.backgroundBottom, spec.accent, 0.13, 0.96);
      case 'vervain':
      case 'thorn':
        return mix(spec.backgroundMid, spec.secondary, 0.22, 0.94);
      case 'kingi':
      case 'postea':
        return mix(spec.backgroundBottom, spec.primary, 0.10, 0.95);
      case 'jrpg':
        return mix(spec.backgroundBottom, spec.accent, 0.08, 0.96);
      case 'roguelike':
        return mix(spec.backgroundBottom, spec.accent, 0.09, 0.96);
      case 'souls':
        return mix(spec.backgroundBottom, const Color(0xFF3A1A0D), 0.24, 0.96);
      case 'bolted_metal':
        return mix(spec.backgroundMid, spec.primary, 0.10, 0.97);
      case 'wild_companion':
        return mix(spec.backgroundBottom, spec.secondary, 0.18, 0.93);
      case 'modern_school':
        return mix(spec.backgroundBottom, spec.primary, 0.06, 0.95);
      case 'medieval':
        return mix(spec.backgroundBottom, spec.primary, 0.08, 0.95);
      case 'cathedral':
        return mix(spec.backgroundBottom, spec.secondary, 0.16, 0.94);
      case 'lunar':
      case 'hoshy':
        return mix(spec.backgroundBottom, spec.accent, 0.12, 0.94);
      case 'archive':
        return mix(spec.backgroundMid, spec.primary, 0.08, 0.95);
      case 'slime':
        return mix(spec.backgroundBottom, spec.primary, 0.10, 0.94);
      default:
        return mix(spec.backgroundBottom, spec.primary, 0.06, 0.94);
    }
  }

  double themeFieldRadiusValue({bool compact = false}) {
    final gui = currentThemeVisualIdentity().mainSheetGuiStyle.id;
    if (gui == 'low_detail') return compact ? 6 : 8;
    if (gui == 'phobia') return compact ? 4 : 6;
    if (gui == 'kingi') return compact ? 5 : 7;
    if (gui == 'postea') return compact ? 5 : 8;
    if (gui == 'medieval') return compact ? 5 : 8;
    if (gui == 'rank_hud') return compact ? 4 : 7;
    if (gui == 'jrpg') return compact ? 7 : 9;
    if (gui == 'roguelike') return compact ? 4 : 5;
    if (gui == 'souls') return compact ? 5 : 7;
    if (gui == 'bolted_metal') return compact ? 3 : 4;
    if (gui == 'wild_companion') return compact ? 11 : 14;
    if (gui == 'modern_school') return compact ? 5 : 7;
    if (gui == 'soft_orbital') return compact ? 12 : 14;
    if (gui == 'botanical') return compact ? 10 : 12;
    if (gui == 'sigil') return compact ? 6 : 9;
    if (gui == 'elemental') return compact ? 7 : 10;
    if (gui == 'relic') return compact ? 5 : 8;
    if (gui == 'lunar') return compact ? 11 : 15;
    return compact ? 8 : 11;
  }

  BorderSide themeFieldBorderSide(
    Color color, {
    bool focused = false,
    bool compact = false,
  }) {
    final spec = currentThemeDecorationSpec();
    final gui = currentThemeVisualIdentity().mainSheetGuiStyle.id;
    final alpha = focused
        ? (gui == 'low_detail' ? 0.95 : 1.0)
        : (gui == 'low_detail' ? 0.62 : 0.74);
    final extra =
        spec.style == 'phobia' ||
            spec.style == 'kingi' ||
            spec.style == 'postea' ||
            spec.style == 'medieval' ||
            spec.style == 'shadow_gate' ||
            spec.style == 'roguelike' ||
            spec.style == 'souls' ||
            spec.style == 'bolted_metal' ||
            spec.style == 'modern_school'
        ? 0.25
        : 0.0;
    final width =
        (focused ? (compact ? 1.35 : 1.75) : (compact ? 0.9 : 1.1)) + extra;
    return BorderSide(
      color: color.withValues(alpha: alpha),
      width: width,
    );
  }

  Widget themeSectionTitleShell({
    required String text,
    required bool compact,
    required Widget child,
  }) {
    final spec = currentThemeDecorationSpec();
    final gui = currentThemeVisualIdentity().mainSheetGuiStyle.id;
    if (spec.opacity <= 0 || gui == 'low_detail') {
      return child;
    }

    Color mix(Color base, Color tint, double amount, double alpha) {
      return Color.lerp(base, tint, amount)!.withValues(alpha: alpha);
    }

    final clipped = <String>{
      'phobia',
      'postea',
      'kingi',
      'medieval',
      'rank_hud',
      'sigil',
      'archive',
      'relic',
      'jrpg',
      'roguelike',
      'souls',
      'bolted_metal',
      'modern_school',
    }.contains(gui);
    final radius = BorderRadius.circular(switch (gui) {
      'phobia' => compact ? 4.0 : 6.0,
      'postea' || 'kingi' || 'medieval' => compact ? 5.0 : 8.0,
      'botanical' => compact ? 11.0 : 14.0,
      'lunar' || 'soft_orbital' => compact ? 13.0 : 16.0,
      _ => compact ? 8.0 : 12.0,
    });
    final glow = currentThemeVisualIdentity().decorationGlow;
    final borderAlpha = (compact ? 0.18 : 0.28) * glow.clamp(0.35, 1.45);
    final titleBody = Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _OculumThemeSectionTitlePainter(
                spec: spec,
                compact: compact,
                desktop: themeUsesDesktopPainting(),
                labelHash: text.hashCode,
              ),
            ),
          ),
        ),
        if (clipped)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _OculumThemePanelChromePainter(
                  spec: spec,
                  guiStyle: gui,
                  borderColor: spec.primary,
                  compact: true,
                  clipped: true,
                ),
              ),
            ),
          ),
        child,
      ],
    );
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 1 : 3),
      decoration: BoxDecoration(
        borderRadius: clipped ? null : radius,
        gradient: LinearGradient(
          colors: [
            mix(
              spec.backgroundBottom,
              spec.accent,
              0.16,
              compact ? 0.34 : 0.46,
            ),
            mix(spec.backgroundMid, spec.primary, 0.07, compact ? 0.20 : 0.30),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: clipped
            ? null
            : Border.all(
                color: spec.primary.withValues(alpha: borderAlpha),
                width: compact ? 0.7 : 0.9,
              ),
      ),
      child: clipped
          ? ClipPath(
              clipper: _OculumThemePanelClipper(guiStyle: gui, compact: true),
              child: titleBody,
            )
          : ClipRRect(borderRadius: radius, child: titleBody),
    );
  }

  double _mapContrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final lighter = max(l1, l2);
    final darker = min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  Color _readableOnMapTheme(
    Color color, {
    Color? background,
    double minRatio = 4.5,
  }) {
    final bg = background ?? backgroundMidColor;
    var candidate = color.withValues(alpha: 1);
    if (_mapContrastRatio(candidate, bg) >= minRatio) return color;

    final backgroundIsLight = bg.computeLuminance() > 0.42;
    var hsl = HSLColor.fromColor(candidate);
    for (var i = 0; i < 14; i++) {
      final nextLightness = backgroundIsLight
          ? (hsl.lightness - 0.055).clamp(0.0, 1.0)
          : (hsl.lightness + 0.055).clamp(0.0, 1.0);
      hsl = hsl.withLightness(nextLightness);
      candidate = hsl.toColor();
      if (_mapContrastRatio(candidate, bg) >= minRatio) {
        return candidate.withValues(alpha: color.a);
      }
    }

    final blackRatio = _mapContrastRatio(Colors.black, bg);
    final whiteRatio = _mapContrastRatio(Colors.white, bg);
    return (whiteRatio >= blackRatio ? Colors.white : Colors.black).withValues(
      alpha: color.a,
    );
  }

  String normalizedThemeSearchQuery() {
    return cleanUiText(themeSearchController.text).trim().toLowerCase();
  }

  bool themeSearchMatchesText(String text) {
    final query = normalizedThemeSearchQuery();
    if (query.isEmpty) return true;
    final haystack = cleanUiText(text).toLowerCase();
    final tokens = query.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return tokens.every(haystack.contains);
  }

  String themeSearchHaystackForPreset(OculumColorPreset preset) {
    return [
      preset.id.replaceAll('_', ' '),
      preset.nameIt,
      preset.nameEn,
      preset.descriptionIt,
      preset.descriptionEn,
      themeDecorationLabel(preset.id),
      themeDecorationStyleForPreset(preset.id),
      guiSkinLabel(preset.id),
      guiSkinDescription(preset.id),
    ].join(' ');
  }

  bool themeSearchMatchesPreset(OculumColorPreset preset) {
    return themeSearchMatchesText(themeSearchHaystackForPreset(preset));
  }

  bool themeSearchMatchesGuiId(String id) {
    final presetId = resolveGuiChoiceToPresetId(id);
    final preset = colorPresetById(presetId);
    return themeSearchMatchesText(
      [
        id.replaceAll('_', ' '),
        guiSkinLabel(id),
        guiSkinDescription(id),
        if (preset != null) themeSearchHaystackForPreset(preset),
      ].join(' '),
    );
  }

  Widget themeSearchField() {
    final hasQuery = normalizedThemeSearchQuery().isNotEmpty;
    return TextField(
      controller: themeSearchController,
      textInputAction: TextInputAction.search,
      style: TextStyle(fontSize: uiScale(15), color: Colors.white),
      decoration:
          fieldDecoration(
            t('Cerca temi sbloccati', 'Search unlocked themes'),
            helper: t(
              'Cerca per nome o parole chiave. I temi non sbloccati restano nascosti.',
              'Search by name or keywords. Locked themes stay hidden.',
            ),
          ).copyWith(
            prefixIcon: Icon(Icons.search, color: tertiaryColor),
            suffixIcon: hasQuery
                ? IconButton(
                    tooltip: t('Pulisci ricerca', 'Clear search'),
                    onPressed: () {
                      setState(() {
                        themeSearchController.clear();
                      });
                    },
                    icon: const Icon(Icons.close),
                  )
                : null,
          ),
      onChanged: (_) => scheduleInputUiRefresh(),
    );
  }

  Widget settingsThemeShowcasePanel() {
    final allUnlockedPresets = orderedColorPresets(unlockedOnly: true);
    final presets = [
      for (final preset in allUnlockedPresets)
        if (themeSearchMatchesPreset(preset)) preset,
    ];

    return gothicPanel(
      borderColor: eyePupilGlowColor,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(lightweightUi ? 9 : 12),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _OculumThemeDecorationPainter(
                    OculumThemeDecorationSpec(
                      presetId: activeThemeDecorationPresetId(),
                      style: themeDecorationStyleForPreset(
                        activeThemeDecorationPresetId(),
                      ),
                      primary: primaryColor,
                      secondary: tertiaryColor,
                      accent: eyePupilGlowColor,
                      backgroundTop: backgroundTopColor,
                      backgroundMid: backgroundMidColor,
                      backgroundBottom: backgroundBottomColor,
                      opacity: 0.10,
                      usesBaseColors: true,
                    ),
                    desktop: themeUsesDesktopPainting(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: eyePupilGlowColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t(
                            'Temi gotici decorativi',
                            'Decorative gothic themes',
                          ),
                          style: TextStyle(
                            color: eyePupilGlowColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  smallInfoText(
                    t(
                      'Ogni tema porta palette e ornamenti coerenti: fasi lunari, vetrate, rovi, sigilli, cristalli, tempeste, maree, brace o glifi. Le decorazioni restano ai margini e non coprono testi o pulsanti.',
                      'Each theme brings a coherent palette and ornaments: lunar phases, stained glass, thorns, sigils, crystals, storms, tides, embers or glyphs. Decorations stay at the edges and do not cover text or buttons.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  themeSearchField(),
                  const SizedBox(height: 10),
                  smallInfoText(
                    t(
                      'Mostrati ${presets.length}/${allUnlockedPresets.length} temi sbloccati.',
                      'Showing ${presets.length}/${allUnlockedPresets.length} unlocked themes.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 760;
                      if (presets.isEmpty) {
                        return smallInfoText(
                          t(
                            'Nessun tema sbloccato corrisponde alla ricerca.',
                            'No unlocked theme matches the search.',
                          ),
                        );
                      }
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final preset in presets)
                            SizedBox(
                              width: narrow
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 20) / 3,
                              child: _themeMiniCard(preset),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> decorationGalleryPresetIds() {
    final result = <String>[];
    for (final preset in orderedColorPresets(unlockedOnly: true)) {
      if (preset.id == 'classic_reliquary' ||
          preset.id == 'classic_low_detail') {
        continue;
      }
      result.add(preset.id);
    }
    return result;
  }

  Widget settingsDecorationsGalleryPanel() {
    final allIds = decorationGalleryPresetIds();
    final ids = [
      for (final id in allIds)
        if (themeSearchMatchesPreset(colorPresetById(id)!)) id,
    ];
    final activeId = activeThemeDecorationPresetId();
    final activeStyle = themeDecorationStyleForPreset(activeId);
    final showNoDecoration =
        normalizedThemeSearchQuery().isEmpty ||
        themeSearchMatchesText(
          t(
            'nessun disegno decorazione classica none no',
            'none no drawings classic decoration',
          ),
        );

    return gothicPanel(
      borderColor: tertiaryColor,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(lightweightUi ? 9 : 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                secondaryColor.withValues(alpha: 0.82),
                backgroundMidColor.withValues(alpha: 0.58),
                backgroundBottomColor.withValues(alpha: 0.88),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wallpaper, color: tertiaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('Decorazioni', 'Decorations'),
                      style: TextStyle(
                        color: tertiaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.check_circle, size: 16),
                    label: Text(themeDecorationLabel(activeId)),
                    backgroundColor: tertiaryColor.withValues(alpha: 0.18),
                    side: BorderSide(color: tertiaryColor),
                    labelStyle: TextStyle(
                      color: tertiaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              smallInfoText(
                t(
                  'Qui scegli solo i disegni: runici, lune, vetrate, rovi, cristalli, tempesta, marea, brace, archivio o tema segreto. I colori restano quelli attuali.',
                  'Choose only the drawings here: runes, moons, stained glass, thorns, crystals, storm, tide, embers, archive or the secret theme. Current colors stay unchanged.',
                ),
              ),
              const SizedBox(height: 12),
              themeSearchField(),
              const SizedBox(height: 10),
              smallInfoText(
                t(
                  'Mostrate ${ids.length}/${allIds.length} decorazioni sbloccate.',
                  'Showing ${ids.length}/${allIds.length} unlocked decorations.',
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth < 640
                      ? 1
                      : constraints.maxWidth < 980
                      ? 2
                      : 3;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 10) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (showNoDecoration)
                        SizedBox(
                          width: width,
                          child: noDecorationChoiceCard(
                            active:
                                themeDecorationStyleForPreset(activeId) ==
                                'none',
                          ),
                        ),
                      for (final id in ids)
                        SizedBox(
                          width: width,
                          child: decorationChoiceCard(
                            colorPresetById(id)!,
                            active:
                                activeId == id ||
                                themeDecorationStyleForPreset(id) ==
                                    activeStyle,
                          ),
                        ),
                      if (!showNoDecoration && ids.isEmpty)
                        SizedBox(
                          width: constraints.maxWidth,
                          child: smallInfoText(
                            t(
                              'Nessuna decorazione sbloccata corrisponde alla ricerca.',
                              'No unlocked decoration matches the search.',
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget noDecorationChoiceCard({required bool active}) {
    final border = active ? eyePupilGlowColor : tertiaryColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: applicaDecorazioneNessuna,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: secondaryColor.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: border.withValues(alpha: active ? 0.95 : 0.55),
              width: active ? 1.7 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 88,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              backgroundTopColor,
                              backgroundMidColor,
                              backgroundBottomColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.layers_clear,
                        color: border.withValues(alpha: 0.85),
                        size: 30,
                      ),
                    ),
                    if (active)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Icon(Icons.check_circle, color: border),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      themeDecorationLabel('none'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('Classic: nessun disegno', 'Classic: no drawings'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: eyePupilGlowColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: active ? null : applicaDecorazioneNessuna,
                      icon: Icon(active ? Icons.done : Icons.layers),
                      label: Text(
                        active
                            ? t('Attiva', 'Active')
                            : t('Disattiva disegni', 'Disable drawings'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget decorationChoiceCard(
    OculumColorPreset preset, {
    required bool active,
  }) {
    final spec = OculumThemeDecorationSpec(
      presetId: preset.id,
      style: themeDecorationStyleForPreset(preset.id),
      primary: preset.primary,
      secondary: preset.tertiary,
      accent: preset.eyePupilGlow,
      backgroundTop: preset.backgroundTop,
      backgroundMid: preset.backgroundMid,
      backgroundBottom: preset.backgroundBottom,
      opacity: 0.18,
      usesBaseColors: themeDecorationUsesBaseColors(preset.id),
    );
    final activeBorder = active ? preset.eyePupilGlow : preset.tertiary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => applicaDecorazioneColorPreset(preset.id),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: preset.secondary.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: activeBorder.withValues(alpha: active ? 0.95 : 0.55),
              width: active ? 1.7 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 88,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              preset.backgroundTop,
                              preset.backgroundMid,
                              preset.backgroundBottom,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _OculumThemeDecorationPainter(
                          spec,
                          desktop: false,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _OculumThemePanelDecorationPainter(
                          spec,
                          activeBorder,
                          false,
                          desktop: false,
                        ),
                      ),
                    ),
                    if (active)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Icon(
                          Icons.check_circle,
                          color: preset.eyePupilGlow,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      themeDecorationLabel(preset.id),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: preset.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      colorPresetName(preset),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: preset.eyePupilGlow,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: active
                          ? null
                          : () => applicaDecorazioneColorPreset(preset.id),
                      icon: Icon(active ? Icons.done : Icons.wallpaper),
                      label: Text(
                        active
                            ? t('Attiva', 'Active')
                            : t('Usa decorazione', 'Use decoration'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> guiSkinPresetIds() {
    final modeIds = <String>[
      'gui_classic',
      'gui_low_detail',
      'gui_auto',
      'gui_videogame_hud',
      'gui_tactical_board',
      'gui_battle_focus',
      'gui_quick_grimoire',
      'gui_soft_orbit',
      'gui_medieval_armory',
      'gui_living_vines',
    ];
    final presetIds = [
      for (final preset in orderedColorPresets(unlockedOnly: true))
        if (preset.id != 'classic_reliquary' &&
            preset.id != 'classic_low_detail')
          preset.id,
    ];
    return [
      ...modeIds,
      for (final id in presetIds)
        if (colorPresetById(id) != null && isColorThemeUnlocked(id)) id,
    ];
  }

  String guiSkinLabel(String id) {
    switch (id.trim()) {
      case 'gui_auto':
        return t('Automatica dal tema', 'Automatic from theme');
      case 'gui_classic':
        return t('Classica', 'Classic');
      case 'gui_low_detail':
        return t('Leggera', 'Lightweight');
      case 'gui_videogame_hud':
        return t('Videogioco HUD', 'Videogame HUD');
      case 'gui_tactical_board':
        return t('Plancia tattica', 'Tactical board');
      case 'gui_battle_focus':
        return t('Focus battaglia', 'Battle focus');
      case 'gui_quick_grimoire':
        return t('Grimorio rapido', 'Quick grimoire');
      case 'gui_soft_orbit':
        return t('Orbita morbida', 'Soft orbit');
      case 'gui_medieval_armory':
        return t('Armeria medievale', 'Medieval armory');
      case 'gui_living_vines':
        return t('Rovi viventi', 'Living vines');
    }
    final resolvedId = resolveGuiChoiceToPresetId(id);
    switch (guiStyleForPreset(resolvedId).id) {
      case 'classic_rpg':
        return t('Classic RPG', 'Classic RPG');
      case 'low_detail':
        return t('Classic low detail', 'Classic low detail');
      case 'phobia':
        return t('Phobia compact', 'Phobia compact');
      case 'kingi':
        return t('Kingi runic engine', 'Kingi runic engine');
      case 'postea':
        return t('Postea rune-tech', 'Postea rune-tech');
      case 'jrpg':
        return t('Leggenda JRPG', 'JRPG legend');
      case 'roguelike':
        return t('Run roguelike', 'Roguelike run');
      case 'souls':
        return t('Patto di cenere', 'Ash covenant');
      case 'bolted_metal':
        return t('Metallo bullonato', 'Bolted metal');
      case 'wild_companion':
        return t('Compagno naturale', 'Natural companion');
      case 'modern_school':
        return t('Giorno di scuola', 'School day');
      case 'medieval':
        return t('Mastio medievale', 'Medieval keep');
      case 'fortress_oculum':
        return t('Fortezza Oculum', 'Oculum Fortress');
      case 'rank_hud':
        return t('Porta di rango', 'Rank gate');
      case 'botanical':
        return id == 'vervain_gothic'
            ? t('Vervain Bloom', 'Vervain Bloom')
            : t('Radici gotiche', 'Gothic roots');
      case 'cathedral':
        return t('Cathedral glass', 'Cathedral glass');
      case 'archive':
        return t('Archive manuscript', 'Archive manuscript');
      case 'frost':
        return t('Frost crystal frame', 'Frost crystal frame');
      case 'lunar':
        return t('Lunar orbit', 'Lunar orbit');
      case 'sigil':
        return t('Sigil grid', 'Sigil grid');
      case 'elemental':
        return t('Elemental frame', 'Elemental frame');
      case 'relic':
        return t('Relic carving', 'Relic carving');
      case 'soft_orbital':
        return id == 'hoshy_cosmic_cat'
            ? t('Hoshy cosmic', 'Hoshy cosmic')
            : t('Soft orbital', 'Soft orbital');
      default:
        return id == 'classic_reliquary'
            ? t('Classic Oculum', 'Classic Oculum')
            : colorPresetName(colorPresetById(resolvedId)!);
    }
  }

  String guiSkinDescription(String id) {
    switch (id.trim()) {
      case 'gui_auto':
        return t(
          'Segue la GUI del tema/decorazione attiva. Utile se vuoi un tema completo coerente.',
          'Follows the active theme/drawing GUI. Useful when you want a coherent full theme.',
        );
      case 'gui_classic':
        return t(
          'Disposizione classica stabile: leggibile, prevedibile e senza effetti speciali invadenti.',
          'Stable classic arrangement: readable, predictable and without invasive effects.',
        );
      case 'gui_low_detail':
        return t(
          'Versione super leggera per telefono o PC lenti: pochi effetti e pannelli puliti.',
          'Very light version for phones or slow PCs: fewer effects and clean panels.',
        );
      case 'gui_videogame_hud':
        return t(
          'HUD da gioco: comandi, vita e combattimento sempre davanti, con barre compatte e look da interfaccia.',
          'Game HUD: commands, vitals and combat stay forward, with compact bars and interface-like visuals.',
        );
      case 'gui_tactical_board':
        return t(
          'Plancia da tavolo tattica: tre zone bilanciate per identita, centro partita e strumenti.',
          'Tactical table board: three balanced zones for identity, live play and tools.',
        );
      case 'gui_battle_focus':
        return t(
          'Modalita aggressiva da combattimento: tiri, danni, HP e risorse prima di tutto.',
          'Aggressive combat mode: rolls, damage, HP and resources first.',
        );
      case 'gui_quick_grimoire':
        return t(
          'Scheda-indice: valori e modifiche vicini, ordine da manuale consultabile al volo.',
          'Index-sheet: values and edits close together, manual-like order for quick lookup.',
        );
      case 'gui_soft_orbit':
        return t(
          'Visuale piu morbida: identita e risorse al centro, strumenti intorno senza colonne pesanti.',
          'Softer view: identity and resources centered, tools around it without heavy columns.',
        );
      case 'gui_medieval_armory':
        return t(
          'Armeria funzionale: scheda compatta, blocchi da equipaggiamento e ritmo da sala d armi.',
          'Functional armory: compact sheet, equipment-like blocks and an armory rhythm.',
        );
      case 'gui_living_vines':
        return t(
          'Disposizione organica: statistiche e vita scorrono prima, dettagli e strumenti chiudono ordinati.',
          'Organic arrangement: stats and vitals flow first, details and tools close neatly.',
        );
    }
    final resolvedId = resolveGuiChoiceToPresetId(id);
    switch (guiStyleForPreset(resolvedId).id) {
      case 'low_detail':
        return t(
          'Pannelli semplici, meno ombre, niente disegni: ideale per telefono o PC lenti.',
          'Simple panels, fewer shadows, no drawings: ideal for phones or slower PCs.',
        );
      case 'phobia':
        return t(
          'Scheda scura, compressa e densa: meno spazio vuoto, blu/nero e bordi duri.',
          'Dark, compressed dense sheet: less empty space, blue/black and hard borders.',
        );
      case 'kingi':
        return t(
          'Placche metalliche, cornici strette e sensazione runico-industriale.',
          'Metal plates, tighter frames and a runic industrial feel.',
        );
      case 'postea':
        return t(
          'Futuro errante: pannelli tecnici, rune-circuito e ritmo da console rituale.',
          'Wandering future: technical panels, rune-circuits and ritual-console rhythm.',
        );
      case 'jrpg':
        return t(
          'Menu comando cristallini, ritmo da party RPG e cornici luminose da avventura.',
          'Crystal command menus, party-RPG rhythm and bright adventure frames.',
        );
      case 'roguelike':
        return t(
          'Scheda da run skill based: pannelli densi, tagli sporchi e lettura immediata di HP, scudi e risorse.',
          'Skill-run sheet: dense panels, dirty cuts and immediate reading of HP, shields and resources.',
        );
      case 'souls':
        return t(
          'Interfaccia cupa da boss: cornici di cenere, barre nette e spazio ridotto per non perdere il combattimento.',
          'Gloomy boss interface: ash frames, sharp bars and reduced empty space so combat stays readable.',
        );
      case 'bolted_metal':
        return t(
          'HUD industriale con placche, bulloni e indicatori compatti per vita, HP temporanei, scudo e Scudo Oculum.',
          'Industrial HUD with plates, bolts and compact gauges for life, temp HP, shield and Oculum Shield.',
        );
      case 'wild_companion':
        return t(
          'Scheda naturale illustrata: colori vivi o notturni, pannelli morbidi e disegno nell angolo senza coprire i dati.',
          'Illustrated natural sheet: lively or night colors, softer panels and a corner drawing without covering data.',
        );
      case 'modern_school':
        return t(
          'Scheda moderna da diario scolastico: quaderno scuro, penne neon, appunti rapidi e HUD leggibile da telefono.',
          'Modern school diary sheet: dark notebook, neon pens, quick notes and a phone-readable HUD.',
        );
      case 'medieval':
        return t(
          'Scheda da sala d armi: pietra compatta, scudi, torri e bordi ferrati.',
          'Armory sheet: compact stone, shields, towers and iron-edged borders.',
        );
      case 'fortress_oculum':
        return t(
          'HUD da fortezza gotica: pannelli neri densi, cornici ferrate, accenti viola e oro antico.',
          'Gothic fortress HUD: dense black panels, iron frames, violet accents and antique gold.',
        );
      case 'rank_hud':
        return t(
          'Scheda scura a gate: HUD vita a quattro linee e bordi da rango inciso.',
          'Dark gate sheet: four-line vitals HUD and carved-rank borders.',
        );
      case 'botanical':
        return t(
          'Pannelli vegetali, angoli organici e cornici piu morbide.',
          'Botanical panels, organic corners and softer frames.',
        );
      case 'cathedral':
        return t(
          'Pannelli ad arco, bordi da vetrata e separatori solenni.',
          'Arched panels, stained-glass borders and solemn separators.',
        );
      case 'archive':
        return t(
          'Scheda da grimorio: bordi sobri, pannelli ordinati e ritmo da manoscritto.',
          'Grimoire sheet: restrained borders, ordered panels and manuscript rhythm.',
        );
      case 'frost':
        return t(
          'Cornici sottili e fredde, cristalli e tagli piu netti.',
          'Thin cold frames, crystals and sharper cuts.',
        );
      case 'lunar':
        return t(
          'Scheda piu ariosa, angoli morbidi e ritmo orbitale.',
          'Airier sheet, softer corners and orbital rhythm.',
        );
      case 'sigil':
        return t(
          'Bordi angolari, campi densi e disposizione da cerchio rituale.',
          'Angular borders, dense fields and ritual-circle layout.',
        );
      case 'elemental':
        return t(
          'Pannelli reattivi, bordi energici e blocchi di controllo in evidenza.',
          'Reactive panels, energetic borders and emphasized control blocks.',
        );
      case 'relic':
        return t(
          'Aspetto inciso, compatto e da reliquia antica.',
          'Carved, compact ancient-relic look.',
        );
      default:
        return t(
          'Layout classico con lo stesso contenuto e massima compatibilita.',
          'Classic layout with the same content and maximum compatibility.',
        );
    }
  }

  Widget settingsGuiSkinGalleryPanel() {
    final allIds = guiSkinPresetIds();
    final ids = [
      for (final id in allIds)
        if (themeSearchMatchesGuiId(id)) id,
    ];
    final activeId = activeGuiChoiceId();

    return gothicPanel(
      borderColor: tertiaryColor,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_customize, color: tertiaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('GUI Skin scheda', 'Sheet GUI skins'),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Chip(
                label: Text(guiSkinLabel(activeId)),
                backgroundColor: secondaryColor,
                labelStyle: TextStyle(
                  color: _readableOnMapTheme(
                    tertiaryColor,
                    background: secondaryColor,
                  ),
                  fontWeight: FontWeight.w900,
                ),
                side: BorderSide(color: tertiaryColor.withValues(alpha: 0.58)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Questa scelta cambia solo contenitori, densita, bordi e ritmo della scheda. Palette, parser, calcoli e dati restano invariati.',
              'This changes only containers, density, borders and sheet rhythm. Palette, parser, calculations and data stay unchanged.',
            ),
          ),
          const SizedBox(height: 12),
          themeSearchField(),
          const SizedBox(height: 10),
          smallInfoText(
            t(
              'Mostrate ${ids.length}/${allIds.length} GUI sbloccate o base.',
              'Showing ${ids.length}/${allIds.length} unlocked or base GUIs.',
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 640
                  ? 1
                  : constraints.maxWidth < 980
                  ? 2
                  : 3;
              final width =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final id in ids)
                    SizedBox(
                      width: width,
                      child: guiSkinChoiceCard(id, active: activeId == id),
                    ),
                  if (ids.isEmpty)
                    SizedBox(
                      width: constraints.maxWidth,
                      child: smallInfoText(
                        t(
                          'Nessuna GUI sbloccata corrisponde alla ricerca.',
                          'No unlocked GUI matches the search.',
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget guiSkinChoiceCard(String id, {required bool active}) {
    final previewPresetId = resolveGuiChoiceToPresetId(id);
    final preset =
        colorPresetById(previewPresetId) ??
        colorPresetById('classic_reliquary')!;
    final gui = guiStyleForPreset(id);
    final background = preset.secondary;
    final accent = _readableOnMapTheme(
      preset.eyePupilGlow,
      background: background,
      minRatio: 3.2,
    );
    final radius = BorderRadius.circular(gui.compactCardRadius);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: () => applicaGuiColorPreset(id),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: background.withValues(alpha: 0.88),
            borderRadius: radius,
            border: Border.all(
              color: active ? accent : preset.tertiary.withValues(alpha: 0.55),
              width: active
                  ? gui.compactBorderWidth + 0.6
                  : gui.compactBorderWidth,
            ),
            boxShadow: gui.id == 'low_detail'
                ? const <BoxShadow>[]
                : [
                    BoxShadow(
                      color: accent.withValues(
                        alpha: 0.08 * themeDecorationGlowScale,
                      ),
                      blurRadius: gui.id == 'phobia' ? 12 : 8,
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    id == 'gui_videogame_hud'
                        ? Icons.videogame_asset
                        : id == 'gui_tactical_board'
                        ? Icons.grid_view
                        : id == 'gui_battle_focus'
                        ? Icons.sports_martial_arts
                        : id == 'gui_quick_grimoire'
                        ? Icons.menu_book
                        : gui.id == 'low_detail'
                        ? Icons.speed
                        : gui.id == 'kingi'
                        ? Icons.precision_manufacturing
                        : gui.id == 'phobia'
                        ? Icons.visibility_off
                        : gui.id == 'jrpg'
                        ? Icons.auto_awesome
                        : gui.id == 'roguelike'
                        ? Icons.casino
                        : gui.id == 'souls'
                        ? Icons.local_fire_department
                        : gui.id == 'bolted_metal'
                        ? Icons.settings
                        : gui.id == 'wild_companion'
                        ? Icons.park
                        : gui.id == 'modern_school'
                        ? Icons.school
                        : Icons.dashboard_customize,
                    color: accent,
                    size: 19,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      guiSkinLabel(id),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _readableOnMapTheme(
                          preset.primary,
                          background: background,
                        ),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (active) Icon(Icons.check_circle, color: accent, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(preset.backgroundTop, preset.primary, 0.08)!,
                      Color.lerp(preset.backgroundMid, preset.tertiary, 0.18)!,
                      Color.lerp(
                        preset.backgroundBottom,
                        preset.eyePupilGlow,
                        0.08,
                      )!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(gui.compactCardRadius),
                  border: Border.all(color: accent.withValues(alpha: 0.42)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 42,
                          height: 20,
                          decoration: BoxDecoration(
                            color: preset.secondary.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(
                              gui.compactCardRadius,
                            ),
                            border: Border.all(
                              color: preset.primary.withValues(alpha: 0.42),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 64,
                          height: 24,
                          decoration: BoxDecoration(
                            color: preset.secondary.withValues(alpha: 0.68),
                            borderRadius: BorderRadius.circular(
                              gui.compactCardRadius,
                            ),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.48),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 42,
                          height: 20,
                          decoration: BoxDecoration(
                            color: preset.secondary.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(
                              gui.compactCardRadius,
                            ),
                            border: Border.all(
                              color: preset.tertiary.withValues(alpha: 0.42),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                guiSkinDescription(id),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11.5,
                  height: 1.18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget themeCustomizationSlidersPanel() {
    Widget sliderRow({
      required String label,
      required IconData icon,
      required double value,
      required double min,
      required double max,
      required ValueChanged<double> onChanged,
      required String shownValue,
    }) {
      return Row(
        children: [
          Icon(icon, color: eyePupilGlowColor, size: 20),
          const SizedBox(width: 8),
          SizedBox(
            width: phoneCompactUi ? 86 : 132,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _readableOnMapTheme(
                  primaryColor,
                  background: secondaryColor,
                ),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max).toDouble(),
              min: min,
              max: max,
              divisions: 20,
              activeColor: _readableOnMapTheme(
                eyePupilGlowColor,
                background: secondaryColor,
              ),
              inactiveColor: tertiaryColor.withValues(alpha: 0.25),
              onChanged: (next) {
                setState(() => onChanged(next));
                programmaSalvataggio();
              },
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              shownValue,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _readableOnMapTheme(
                  tertiaryColor,
                  background: secondaryColor,
                ),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }

    return gothicPanel(
      borderColor: eyePupilGlowColor,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: eyePupilGlowColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Customizzazione skin', 'Skin customization'),
                  style: TextStyle(
                    color: eyePupilGlowColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    themeDecorationOpacityScale = 1.0;
                    themeDecorationGlowScale = 1.0;
                    themeDecorationIntensityScale = 1.0;
                    risultato = t(
                      'Customizzazione skin ripristinata.',
                      'Skin customization reset.',
                    );
                    aggiungiLog(risultato);
                  });
                  programmaSalvataggio();
                },
                icon: const Icon(Icons.restart_alt),
                label: Text(t('Reset', 'Reset')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Questi controlli agiscono solo su disegni, glow e presenza visiva. Classic Oculum e Low Detail restano senza decorazioni.',
              'These controls affect only drawings, glow and visual presence. Classic Oculum and Low Detail stay decoration-free.',
            ),
          ),
          const SizedBox(height: 10),
          sliderRow(
            label: t('Opacita', 'Opacity'),
            icon: Icons.opacity,
            value: themeDecorationOpacityScale,
            min: 0.25,
            max: 2.5,
            shownValue: '${(themeDecorationOpacityScale * 100).round()}%',
            onChanged: (next) => themeDecorationOpacityScale = next,
          ),
          sliderRow(
            label: 'Glow',
            icon: Icons.auto_awesome,
            value: themeDecorationGlowScale,
            min: 0.0,
            max: 2.5,
            shownValue: '${(themeDecorationGlowScale * 100).round()}%',
            onChanged: (next) => themeDecorationGlowScale = next,
          ),
          sliderRow(
            label: t('Intensita', 'Intensity'),
            icon: Icons.blur_on,
            value: themeDecorationIntensityScale,
            min: 0.35,
            max: 2.5,
            shownValue: '${(themeDecorationIntensityScale * 100).round()}%',
            onChanged: (next) => themeDecorationIntensityScale = next,
          ),
        ],
      ),
    );
  }

  Widget _themeMiniCard(OculumColorPreset preset) {
    final selected = colorPresetSelezionato == preset.id;
    final decorationSelected = activeThemeDecorationPresetId() == preset.id;
    final guiSelected = activeThemeGuiPresetId() == preset.id;
    final decoration = themeDecorationLabel(preset.id);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => applicaColorPreset(preset.id),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: preset.secondary.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? preset.eyePupilGlow
                  : preset.tertiary.withValues(alpha: 0.55),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (preset.iconAssetPath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.asset(
                        preset.iconAssetPath!,
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                        cacheWidth: 68,
                        cacheHeight: 68,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      colorPresetName(preset),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: preset.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, color: preset.eyePupilGlow),
                  if (!selected && decorationSelected)
                    Icon(Icons.wallpaper, color: preset.eyePupilGlow),
                  if (!selected && !decorationSelected && guiSelected)
                    Icon(Icons.dashboard_customize, color: preset.eyePupilGlow),
                ],
              ),
              const SizedBox(height: 6),
              colorPresetSwatches(preset, size: 13),
              const SizedBox(height: 8),
              Text(
                decorationSelected && !selected
                    ? '${t('Disegno attivo', 'Active drawing')}: $decoration'
                    : decoration,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: preset.eyePupilGlow,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                colorPresetDescription(preset),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11.5,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: t('Applica solo disegni', 'Apply drawings only'),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      onPressed: () => applicaDecorazioneColorPreset(preset.id),
                      icon: Icon(
                        Icons.wallpaper,
                        color: decorationSelected
                            ? preset.eyePupilGlow
                            : preset.primary,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: t('Applica solo GUI', 'Apply GUI only'),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      onPressed: () => applicaGuiColorPreset(preset.id),
                      icon: Icon(
                        Icons.dashboard_customize,
                        color: guiSelected
                            ? preset.eyePupilGlow
                            : preset.primary,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: t('Applica solo colori', 'Apply colors only'),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      onPressed: () => applicaSoloColoriPreset(preset.id),
                      icon: Icon(
                        Icons.format_paint,
                        color: selected ? preset.eyePupilGlow : preset.primary,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: t('Applica tema completo', 'Apply full theme'),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      onPressed: () => applicaColorPreset(preset.id),
                      icon: Icon(
                        Icons.palette,
                        color: selected ? preset.eyePupilGlow : preset.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // MAPPA CAMPAGNA
  // =====================================================

  String sanitizeStoredFileName(String sourceName, String fallbackExtension) {
    final safeFallback = fallbackExtension.startsWith('.')
        ? fallbackExtension
        : '.$fallbackExtension';
    final segments = sourceName.replaceAll('\\', '/').split('/');
    final rawName = segments.isEmpty ? sourceName : segments.last;
    final dot = rawName.lastIndexOf('.');
    final rawBase = dot > 0 ? rawName.substring(0, dot) : rawName;
    final rawExt = dot > 0 ? rawName.substring(dot).toLowerCase() : '';
    final ext = RegExp(r'^\.[a-z0-9]{1,8}$').hasMatch(rawExt)
        ? rawExt
        : safeFallback;
    final base = rawBase
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final cleanBase = base.isEmpty ? 'oculum_file' : base;
    return '${DateTime.now().microsecondsSinceEpoch}_$cleanBase$ext';
  }

  Future<Directory> oculumStorageDirectory(String child) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}Oculum$child');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> saveBytesToOculumStorage({
    required Uint8List bytes,
    required String directoryName,
    required String sourceName,
    String fallbackExtension = '.png',
  }) async {
    final dir = await oculumStorageDirectory(
      '${Platform.pathSeparator}$directoryName',
    );
    final fileName = sanitizeStoredFileName(sourceName, fallbackExtension);
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String> copyFileToOculumStorage({
    required File source,
    required String directoryName,
    required String sourceName,
    String fallbackExtension = '.png',
  }) async {
    final dir = await oculumStorageDirectory(
      '${Platform.pathSeparator}$directoryName',
    );
    final fileName = sanitizeStoredFileName(sourceName, fallbackExtension);
    final target = File('${dir.path}${Platform.pathSeparator}$fileName');
    await source.copy(target.path);
    return target.path;
  }

  bool fileLooksLikeImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.gif');
  }

  Future<void> scegliImmagineMappa() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final sourceName = picked.name.trim().isEmpty ? 'mappa.png' : picked.name;
    if (kIsWeb) {
      final prepared = await prepareVttImportedImage(
        await picked.readAsBytes(),
        maxDimension: 1920,
        quality: 72,
      );
      if (!mounted || '${prepared['base64'] ?? ''}'.isEmpty) return;
      setState(() {
        mapMode = 'image';
        mapImagePath = '';
        mapImageName = sourceName;
        activeVttScene.imageDataBase64 = '${prepared['base64']}';
        risultato = t(
          'Mappa importata nel sito.',
          'Map imported in the web app.',
        );
        aggiungiLog(risultato);
      });
      markVttLegacyMapChanged(includeAsset: true);
      programmaSalvataggio();
      return;
    }
    final savedPath = await copyFileToOculumStorage(
      source: File(picked.path),
      directoryName: 'maps',
      sourceName: sourceName,
    );
    if (!mounted) return;
    setState(() {
      mapMode = 'image';
      mapImagePath = savedPath;
      mapImageName = sourceName;
      activeVttScene.imageDataBase64 = '';
      risultato = t('Mappa importata.', 'Map imported.');
      aggiungiLog(risultato);
    });
    markVttLegacyMapChanged(includeAsset: true);
    programmaSalvataggio();
  }

  Future<void> incollaImmagineMappa() async {
    final hasExistingLocalMap =
        mapMode == 'image' &&
        (activeVttScene.imageDataBase64.isNotEmpty ||
            (!kIsWeb &&
                mapImagePath.trim().isNotEmpty &&
                File(mapImagePath.trim()).existsSync()));
    if (hasExistingLocalMap) {
      await incollaTokenImmagineMappa();
      return;
    }

    try {
      final clipboardImage = await Pasteboard.image;
      if (!mounted) return;
      if (clipboardImage != null && clipboardImage.isNotEmpty) {
        var savedPath = '';
        var embedded = '';
        if (kIsWeb) {
          final prepared = await prepareVttImportedImage(
            clipboardImage,
            maxDimension: 1920,
            quality: 72,
          );
          embedded = '${prepared['base64'] ?? ''}';
        } else {
          savedPath = await saveBytesToOculumStorage(
            bytes: clipboardImage,
            directoryName: 'maps',
            sourceName: 'mappa_appunti.png',
          );
        }
        if (!mounted) return;
        setState(() {
          mapMode = 'image';
          mapImagePath = savedPath;
          mapImageName = t('Appunti', 'Clipboard');
          activeVttScene.imageDataBase64 = embedded;
          risultato = t('Mappa incollata dagli appunti.', 'Map pasted.');
          aggiungiLog(risultato);
        });
        markVttLegacyMapChanged(includeAsset: true);
        programmaSalvataggio();
        return;
      }

      if (kIsWeb) {
        setState(() {
          risultato = t(
            'Nessuna immagine leggibile negli appunti del browser.',
            'No readable image in the browser clipboard.',
          );
          aggiungiLog(risultato);
        });
        return;
      }

      final files = await Pasteboard.files();
      if (!mounted) return;
      for (final rawPath in files) {
        final path = rawPath.startsWith('file:')
            ? Uri.parse(rawPath).toFilePath()
            : rawPath;
        if (!fileLooksLikeImagePath(path)) continue;
        final source = File(path);
        if (!await source.exists()) continue;
        final name = source.uri.pathSegments.isEmpty
            ? 'mappa.png'
            : Uri.decodeComponent(source.uri.pathSegments.last);
        final savedPath = await copyFileToOculumStorage(
          source: source,
          directoryName: 'maps',
          sourceName: name,
        );
        if (!mounted) return;
        setState(() {
          mapMode = 'image';
          mapImagePath = savedPath;
          mapImageName = name;
          activeVttScene.imageDataBase64 = '';
          risultato = t('Mappa incollata da file.', 'Map pasted from file.');
          aggiungiLog(risultato);
        });
        markVttLegacyMapChanged(includeAsset: true);
        programmaSalvataggio();
        return;
      }

      setState(() {
        risultato = t(
          'Nessuna immagine mappa trovata negli appunti.',
          'No map image found in the clipboard.',
        );
        aggiungiLog(risultato);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        risultato = t(
          'Impossibile leggere la mappa dagli appunti.',
          'Could not read the map from the clipboard.',
        );
        aggiungiLog('$risultato ($error)');
      });
    }
  }

  Color predominantImageColor(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
      return tertiaryColor;
    }
    final resized = img.copyResize(
      decoded,
      width: min(72, decoded.width),
      height: min(72, decoded.height),
      interpolation: img.Interpolation.average,
    );
    final rgba = resized.getBytes(order: img.ChannelOrder.rgba);
    final buckets = <int, int>{};
    for (var i = 0; i + 3 < rgba.length; i += 4) {
      final alpha = rgba[i + 3];
      if (alpha < 32) continue;
      final r = rgba[i];
      final g = rgba[i + 1];
      final b = rgba[i + 2];
      final saturation = max(r, max(g, b)) - min(r, min(g, b));
      if (r + g + b < 45 || (r + g + b > 720 && saturation < 28)) continue;
      final key = ((r >> 5) << 10) | ((g >> 5) << 5) | (b >> 5);
      buckets[key] = (buckets[key] ?? 0) + 1 + saturation ~/ 20;
    }
    if (buckets.isEmpty) return tertiaryColor;
    final key = buckets.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    final r = (((key >> 10) & 0x1F) * 32 + 16).clamp(0, 255).toInt();
    final g = (((key >> 5) & 0x1F) * 32 + 16).clamp(0, 255).toInt();
    final b = ((key & 0x1F) * 32 + 16).clamp(0, 255).toInt();
    return Color.fromARGB(255, r, g, b);
  }

  Future<Uint8List?> readMapTokenImageFromClipboard() async {
    Uint8List? bytes = await Pasteboard.image;
    if (bytes != null && bytes.isNotEmpty && img.decodeImage(bytes) != null) {
      return bytes;
    }

    if (kIsWeb) return null;
    final files = await Pasteboard.files();
    for (final rawPath in files) {
      final path = rawPath.startsWith('file:')
          ? Uri.parse(rawPath).toFilePath()
          : rawPath;
      if (!fileLooksLikeImagePath(path)) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      final fileBytes = await file.readAsBytes();
      if (img.decodeImage(fileBytes) == null) continue;
      return fileBytes;
    }

    return null;
  }

  Future<void> incollaTokenImmagineMappa() async {
    final hasMap =
        activeVttScene.imageDataBase64.isNotEmpty ||
        (!kIsWeb &&
            mapImagePath.trim().isNotEmpty &&
            File(mapImagePath.trim()).existsSync());
    if (!hasMap) {
      setState(() {
        risultato = t(
          'Prima genera o importa una mappa locale, poi incolla il token.',
          'Generate or import a local map first, then paste the token.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    try {
      final bytes = await readMapTokenImageFromClipboard();

      if (!mounted) return;
      if (bytes == null || bytes.isEmpty || img.decodeImage(bytes) == null) {
        setState(() {
          risultato = t(
            'Nessuna immagine token trovata negli appunti.',
            'No token image found in the clipboard.',
          );
          aggiungiLog(risultato);
        });
        return;
      }

      final color = predominantImageColor(bytes);
      final ownerTag = currentLocalMapOwnerTag();
      setState(() {
        localMapTokens.add(<String, dynamic>{
          'id': 'map_image_${DateTime.now().microsecondsSinceEpoch}',
          'sheetTag': '',
          'ownerTag': ownerTag,
          'name': t('Token immagine', 'Image token'),
          'type': t('Token libero', 'Free token'),
          'side': 'neutral',
          'imageBase64': base64Encode(bytes),
          'colorArgb': color.toARGB32(),
          'shape': 'hex',
          'level': 0,
          'grade': 0,
          'initiativeBase': 0,
          'reactionMax': 1,
          'reactionFastMax': 0,
          'x': 0.5,
          'y': 0.5,
          'size': mapTokenDefaultSize(),
          'movementMaxMeters': mapFreeTokenMovementValue(),
          'movementUsedMeters': 0.0,
        });
        risultato = t(
          'Token immagine creato dagli appunti.',
          'Image token created from clipboard.',
        );
        aggiungiLog(risultato);
      });
      markVttLegacyMapChanged();
      programmaSalvataggio();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        risultato = t(
          'Impossibile creare il token dagli appunti.',
          'Could not create token from clipboard.',
        );
        aggiungiLog('$risultato ($error)');
      });
    }
  }

  void resetMapView() {
    setState(() {
      mapTransformationController.value = Matrix4.identity();
      risultato = t('Vista mappa resettata.', 'Map view reset.');
      aggiungiLog(risultato);
    });
  }

  void removeMapImage() {
    setState(() {
      mapImagePath = '';
      mapImageName = '';
      activeVttScene.imageDataBase64 = '';
      mapTransformationController.value = Matrix4.identity();
      risultato = t('Mappa rimossa.', 'Map removed.');
      aggiungiLog(risultato);
    });
    markVttLegacyMapChanged(includeAsset: true);
    programmaSalvataggio();
  }

  bool normalizeOnlineMapLink({bool announce = false}) {
    final uri = _oculumUriFromUserText(mapUrlController.text);
    if (uri == null) {
      if (announce) {
        setState(() {
          risultato = t(
            'Inserisci o incolla un link http/https valido.',
            'Enter or paste a valid http/https link.',
          );
          aggiungiLog(risultato);
        });
      }
      return false;
    }

    setState(() {
      mapMode = 'online';
      mapUrlController.text = uri.toString();
      if (announce) {
        risultato = t(
          'Link mappa caricato nel riquadro: puoi navigare qui dentro e continuare a usare la scheda.',
          'Map link loaded in the frame: you can browse inside it and keep using the sheet.',
        );
        aggiungiLog(risultato);
      }
    });
    markVttLegacyMapChanged(includeAsset: true);
    programmaSalvataggio();
    return true;
  }

  Future<void> pasteOnlineMapLink() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      final text = data?.text ?? '';
      final uri = _oculumUriFromUserText(text);
      if (uri == null) {
        setState(() {
          risultato = t(
            'Nessun link valido negli appunti.',
            'No valid link in the clipboard.',
          );
          aggiungiLog(risultato);
        });
        return;
      }

      setState(() {
        mapMode = 'online';
        mapUrlController.text = uri.toString();
        risultato = t(
          'Link online incollato e pronto nel riquadro mappa.',
          'Online link pasted and ready in the map frame.',
        );
        aggiungiLog(risultato);
      });
      markVttLegacyMapChanged(includeAsset: true);
      programmaSalvataggio();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        risultato = t(
          'Impossibile leggere il link dagli appunti.',
          'Could not read the link from the clipboard.',
        );
        aggiungiLog('$risultato ($error)');
      });
    }
  }

  Uri? safeMapUri() {
    return _oculumUriFromUserText(mapUrlController.text);
  }

  Future<bool> askMapSessionPreferenceIfNeeded() async {
    if (mapSessionChoiceAsked || !mounted) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF10121A),
        title: Text(
          t('Sessione mappa online', 'Online map session'),
          style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          t(
            'Oculum puo aprire la mappa online nel browser in-app quando supportato, oppure nel browser esterno. L app salva solo il link e la tua preferenza, non password, cookie o token VTT.',
            'Oculum can open the online map in the in-app browser when supported, or in the external browser. The app saves only the link and your preference, not passwords, cookies or VTT tokens.',
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'no'),
            child: Text(t('Non salvare preferenza', 'Do not save')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'yes'),
            child: Text(t('Ricorda', 'Remember')),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    setState(() {
      mapSaveSession = choice == 'yes';
      mapSessionChoiceAsked = true;
    });
    programmaSalvataggio();
    return choice != null;
  }

  Future<void> openOnlineMapExternal() async {
    normalizeOnlineMapLink();
    final uri = safeMapUri();
    if (uri == null) {
      setState(() {
        risultato = t(
          'Inserisci un link http/https valido per la mappa online.',
          'Enter a valid http/https link for the online map.',
        );
        aggiungiLog(risultato);
      });
      return;
    }
    final proceed = await askMapSessionPreferenceIfNeeded();
    if (!proceed) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    setState(() {
      risultato = launched
          ? t('Mappa online aperta nel browser.', 'Online map opened.')
          : t('Browser non disponibile per la mappa.', 'Browser unavailable.');
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  Future<bool> openUriInOculumBrowser(Uri uri, {String? title}) async {
    final supported =
        !kIsWeb &&
        (Platform.isWindows ||
            Platform.isAndroid ||
            Platform.isIOS ||
            Platform.isMacOS);
    if (!supported) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!mounted) return false;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OculumInAppBrowserPage(
          initialUrl: uri.toString(),
          title: title ?? uri.host,
          accentColor: tertiaryColor,
          backgroundColor: backgroundBottomColor,
          english: linguaInglese,
        ),
      ),
    );
    if (!mounted) return false;
    return true;
  }

  Future<void> openOnlineMapInApp() async {
    normalizeOnlineMapLink();
    final uri = safeMapUri();
    if (uri == null) {
      setState(() {
        risultato = t(
          'Inserisci un link http/https valido per la mappa online.',
          'Enter a valid http/https link for the online map.',
        );
        aggiungiLog(risultato);
      });
      return;
    }
    final proceed = await askMapSessionPreferenceIfNeeded();
    if (!proceed) return;
    if (!mounted) return;

    var opened = false;
    try {
      opened = await openUriInOculumBrowser(
        uri,
        title: t('Mappa online', 'Online map'),
      );
    } catch (_) {
      opened = false;
    }

    if (!opened) {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!mounted) return;

    setState(() {
      risultato = opened
          ? t(
              'Mappa online aperta dentro Oculum.',
              'Online map opened inside Oculum.',
            )
          : t(
              'Browser interno non disponibile per la mappa.',
              'Internal browser unavailable for the map.',
            );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void clearMapSessionPreference() {
    setState(() {
      mapSaveSession = false;
      mapSessionChoiceAsked = false;
      risultato = t(
        'Preferenza sessione mappa cancellata. I cookie restano nel browser esterno.',
        'Map session preference cleared. Cookies remain in the external browser.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  Widget mapPage() {
    return responsivePageList(
      pageKey: 'map',
      maxColumns: 2,
      minColumnWidth: 360,
      fullWidthIndexes: const <int>{0, 3, 4, 5},
      children: [
        functionAnchor('map_root', sectionTitle(t('Mappa', 'Map'))),
        vttSceneManagerPanel(),
        mapControlPanel(),
        vttToolbarPanel(),
        mapViewerPanel(),
        mapSplitWorkspacePanel(),
        localMapMiniInitiativePanel(),
        mapNotesPanel(),
      ],
    );
  }

  Widget mapSplitWorkspacePanel() {
    while (mapSplitPanels.length < mapSplitPanelCount) {
      mapSplitPanels.add(<String, dynamic>{
        'kind': 'sheet',
        'sheetTag': '',
        'url': '',
      });
    }
    final localSheets = schedePersonaggio
        .where((sheet) => !readBoolValue(sheet['occhioCaduto']))
        .toList(growable: false);
    final shared = realtimeSharedSheets.toList(growable: false);
    return gothicPanel(
      borderColor: tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view_rounded, color: tertiaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Riquadri Mappa — $mapSplitPanelCount/4',
                  style: TextStyle(
                    color: tertiaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              DropdownButton<int>(
                value: mapSplitPanelCount,
                items: const [1, 2, 3, 4]
                    .map(
                      (count) =>
                          DropdownMenuItem(value: count, child: Text('$count')),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => mapSplitPanelCount = value);
                  programmaSalvataggio();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          smallInfoText(
            'Fino a quattro riquadri: tue schede, schede condivise RealTime o siti web. La mappa e i token restano attivi sopra.',
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: mapSplitPanelCount == 1 ? 1 : 2,
              childAspectRatio: mapSplitPanelCount == 1 ? 2.5 : 1.35,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: mapSplitPanelCount,
            itemBuilder: (_, index) => _mapSplitPanelCard(
              index: index,
              panel: mapSplitPanels[index],
              localSheets: localSheets,
              shared: shared,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapSplitPanelCard({
    required int index,
    required Map<String, dynamic> panel,
    required List<Map<String, dynamic>> localSheets,
    required List<Map<String, dynamic>> shared,
  }) {
    final kind = '${panel['kind'] ?? 'sheet'}';
    final selectedTag = '${panel['sheetTag'] ?? ''}';
    final local = localSheets
        .where((sheet) => '${sheet['sheetTag'] ?? ''}' == selectedTag)
        .firstOrNull;
    final remote = shared
        .where((record) => '${record['key'] ?? ''}' == selectedTag)
        .firstOrNull;
    final remoteSheet = remote?['sheet'];
    final displaySheet =
        local ??
        (remoteSheet is Map ? Map<String, dynamic>.from(remoteSheet) : null);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tertiaryColor.withValues(alpha: .45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButton<String>(
            value: const {'sheet', 'shared', 'web'}.contains(kind)
                ? kind
                : 'sheet',
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'sheet', child: Text('Mia scheda')),
              DropdownMenuItem(
                value: 'shared',
                child: Text('Scheda condivisa'),
              ),
              DropdownMenuItem(value: 'web', child: Text('Sito web')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                panel['kind'] = value;
                panel['sheetTag'] = '';
              });
              programmaSalvataggio();
            },
          ),
          if (kind == 'sheet')
            DropdownButton<String>(
              value: local == null ? '' : selectedTag,
              isExpanded: true,
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Scegli la tua scheda'),
                ),
                ...localSheets.map(
                  (sheet) => DropdownMenuItem(
                    value: '${sheet['sheetTag'] ?? ''}',
                    child: Text('${sheet['nome'] ?? '???'}'),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => panel['sheetTag'] = value ?? '');
                programmaSalvataggio();
              },
            )
          else if (kind == 'shared')
            DropdownButton<String>(
              value: remote == null ? '' : selectedTag,
              isExpanded: true,
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Scegli scheda condivisa'),
                ),
                ...shared.map(
                  (record) => DropdownMenuItem(
                    value: '${record['key'] ?? ''}',
                    child: Text(
                      '${record['ownerName'] ?? '???'} — ${record['sheetName'] ?? 'Scheda'}',
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => panel['sheetTag'] = value ?? '');
                programmaSalvataggio();
              },
            ),
          Expanded(
            child: kind == 'web'
                ? _mapSplitWebPanel(panel)
                : _mapSplitSheetSummary(displaySheet),
          ),
        ],
      ),
    );
  }

  Widget _mapSplitWebPanel(Map<String, dynamic> panel) {
    final raw = '${panel['url'] ?? ''}'.trim();
    final uri = _oculumUriFromUserText(raw);
    return Column(
      children: [
        TextFormField(
          key: ValueKey('map_split_url_$raw'),
          initialValue: raw,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(labelText: 'https:// sito web'),
          onFieldSubmitted: (value) {
            panel['url'] = value.trim();
            setState(() {});
            programmaSalvataggio();
          },
        ),
        const SizedBox(height: 6),
        Expanded(
          child: uri == null
              ? const Center(child: Text('Inserisci un sito http/https'))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: OculumEmbeddedBrowser(
                    key: ValueKey('map-split-site-${uri.toString()}'),
                    initialUrl: uri.toString(),
                    title: uri.host,
                    accentColor: tertiaryColor,
                    backgroundColor: backgroundBottomColor,
                    english: linguaInglese,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _mapSplitSheetSummary(Map<String, dynamic>? sheet) {
    if (sheet == null) {
      return const Center(child: Text('Nessuna scheda selezionata'));
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_pin, size: 32),
          Text(
            '${sheet['nome'] ?? '???'}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          Text(
            '${sheet['tipoScheda'] ?? 'Scheda'} • Lv ${sheet['livello'] ?? 0}',
          ),
          Text(
            'HP ${sheet['currentHp'] ?? 0} • RES ${sheet['resilienza'] ?? 0} • VOL ${sheet['volonta'] ?? 0}',
          ),
        ],
      ),
    );
  }

  double mapTokenDefaultSize() {
    final raw = mapTokenSizeController.text.trim().replaceAll(',', '.');
    return (double.tryParse(raw) ?? 64).clamp(24.0, 240.0).toDouble();
  }

  double mapMetersControllerValue(
    TextEditingController controller,
    double fallback,
  ) {
    final raw = controller.text.trim().replaceAll(',', '.');
    return (double.tryParse(raw) ?? fallback).clamp(1.0, 5000.0).toDouble();
  }

  double mapWidthMetersValue() {
    return mapMetersControllerValue(mapWidthMetersController, 30);
  }

  double mapHeightMetersValue() {
    return mapMetersControllerValue(mapHeightMetersController, 20);
  }

  double mapFreeTokenMovementValue() {
    return mapMetersControllerValue(mapFreeTokenMovementController, 6);
  }

  List<int> localMapTokenSheetIndexes() {
    if (schedePersonaggio.isEmpty) return const [];
    if (!vttCanManageTokens) return const [];
    final canManageShared = canUseSharedSheetsForMasterInitiative();
    if (!canManageShared && !mapPlayersCanManageOwnToken) return const [];
    final indexes = <int>[];
    for (var i = 0; i < schedePersonaggio.length; i++) {
      if (canManageShared || sheetIsOwnLocalSheetAt(i)) {
        indexes.add(i);
      }
    }
    return indexes;
  }

  int safeLocalMapTokenSheetIndex() {
    final indexes = localMapTokenSheetIndexes();
    if (indexes.isEmpty) return -1;
    if (indexes.contains(mapTokenSheetIndex)) return mapTokenSheetIndex;
    mapTokenSheetIndex = indexes.first;
    return mapTokenSheetIndex;
  }

  int indexForLocalMapToken(Map<String, dynamic> token) {
    final tag = normalizeOculumFriendTag('${token['sheetTag'] ?? ''}');
    if (tag.isEmpty) return -1;
    return schedePersonaggio.indexWhere(
      (sheet) =>
          normalizeOculumFriendTag(
            '${sheet['sheetTag'] ?? sheet['id'] ?? ''}',
          ) ==
          tag,
    );
  }

  String localMapTokenOwnerTag(Map<String, dynamic> token) {
    final ownerTag = normalizeOculumFriendTag('${token['ownerTag'] ?? ''}');
    if (ownerTag.isNotEmpty) return ownerTag;
    return normalizeOculumFriendTag('${token['sheetTag'] ?? ''}');
  }

  String currentLocalMapOwnerTag() {
    if (schedaCorrente >= 0 && schedaCorrente < schedePersonaggio.length) {
      return sheetTagAt(schedaCorrente);
    }
    final tags = localOculumTags();
    return tags.isEmpty ? '' : tags.first;
  }

  bool canManageLocalMapToken(Map<String, dynamic> token) {
    if (!vttCanManageTokens) return false;
    if (canUseSharedSheetsForMasterInitiative()) return true;
    if (!mapPlayersCanManageOwnToken) return false;
    final tag = localMapTokenOwnerTag(token);
    if (tag.isEmpty) return false;
    return localOculumTags().map(normalizeOculumFriendTag).contains(tag);
  }

  bool canSendLocalMapTokenToInitiative(Map<String, dynamic> token) {
    final index = indexForLocalMapToken(token);
    if (index >= 0) return sheetCanBeAddedToMasterInitiative(index);
    return canManageLocalMapToken(token);
  }

  int localMapTokenIndexForSheet(int sheetIndex) {
    if (sheetIndex < 0 || sheetIndex >= schedePersonaggio.length) return -1;
    final tag = normalizeOculumFriendTag(sheetTagAt(sheetIndex));
    return localMapTokens.indexWhere(
      (token) => normalizeOculumFriendTag('${token['sheetTag'] ?? ''}') == tag,
    );
  }

  bool selectedSheetHasLocalMapToken() {
    final index = safeLocalMapTokenSheetIndex();
    return index >= 0 && localMapTokenIndexForSheet(index) >= 0;
  }

  Map<String, dynamic> localMapTokenFromSheet(
    int index, {
    double x = 0.5,
    double y = 0.5,
  }) {
    return <String, dynamic>{
      'id': 'map_${sheetTagAt(index)}_${DateTime.now().microsecondsSinceEpoch}',
      'sheetTag': sheetTagAt(index),
      'ownerTag': sheetTagAt(index),
      'name': nomeSchedaPersonaggio(index),
      'type': tipoSchedaPersonaggio(index),
      'side': sheetSideAt(index),
      'imageBase64': sheetImageBase64At(index),
      'shape': 'hex',
      'level': max(0, sheetIntValueAt(index, 'livello')),
      'grade': max(0, sheetIntValueAt(index, 'grado')),
      'initiativeBase': sheetRollBonusAt(index, 'iniziativa'),
      'reactionMax': sheetReazioniAt(index),
      'reactionFastMax': sheetReazioniVelociAt(index),
      'currentHp': max(0, sheetCurrentHpForDeathAt(index)),
      'maxHp': max(0, sheetMaxHpForDeathAt(index)),
      'tempHp': max(0, sheetIntValueAt(index, 'hpTemp')),
      'shield': max(0, sheetIntValueAt(index, 'scudo')),
      'conditions': <String>[],
      'visionMeters': 0.0,
      'auraMeters': 0.0,
      'elevationMeters': 0.0,
      'rotationDegrees': 0.0,
      'visible': true,
      'hidden': false,
      'defeated': false,
      'dead': false,
      'publicNotes': '',
      'privateNotes': '',
      'x': x.clamp(0.0, 1.0),
      'y': y.clamp(0.0, 1.0),
      'size': mapTokenDefaultSize(),
      'movementUsedMeters': 0.0,
    };
  }

  void toggleSelectedLocalMapToken() {
    final index = safeLocalMapTokenSheetIndex();
    if (index < 0) return;

    final existingIndex = localMapTokenIndexForSheet(index);
    if (existingIndex >= 0) {
      final token = localMapTokens[existingIndex];
      if (!canManageLocalMapToken(token)) return;
      setState(() {
        localMapTokens.removeAt(existingIndex);
        risultato = t(
          'Token rimosso dalla mappa: ${nomeSchedaPersonaggio(index)}.',
          'Token removed from map: ${nomeSchedaPersonaggio(index)}.',
        );
        aggiungiLog(risultato);
      });
    } else {
      if (!canUseSharedSheetsForMasterInitiative() &&
          !mapPlayersCanManageOwnToken) {
        return;
      }
      setState(() {
        localMapTokens.add(localMapTokenFromSheet(index));
        risultato = t(
          'Token messo sulla mappa: ${nomeSchedaPersonaggio(index)}.',
          'Token placed on map: ${nomeSchedaPersonaggio(index)}.',
        );
        aggiungiLog(risultato);
      });
    }

    markVttLegacyMapChanged();
    programmaSalvataggio();
  }

  void placeAllAvailableSheetTokensOnLocalMap() {
    final indexes = localMapTokenSheetIndexes()
        .where((index) => localMapTokenIndexForSheet(index) < 0)
        .toList();
    if (indexes.isEmpty) {
      setState(() {
        risultato = t(
          'Tutte le schede disponibili hanno gia un token sulla mappa.',
          'Every available sheet already has a token on the map.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    setState(() {
      for (var slot = 0; slot < indexes.length; slot++) {
        final column = slot % 5;
        final row = slot ~/ 5;
        localMapTokens.add(
          localMapTokenFromSheet(
            indexes[slot],
            x: ((column + 1) / 6).clamp(0.08, 0.92).toDouble(),
            y: (0.16 + row * 0.13).clamp(0.08, 0.92).toDouble(),
          ),
        );
      }
      risultato = t(
        'Token creati dalle schede: ${indexes.length}.',
        'Tokens created from sheets: ${indexes.length}.',
      );
      aggiungiLog(risultato);
    });
    markVttLegacyMapChanged();
    programmaSalvataggio();
  }

  void updateLocalMapTokenFromSheet(Map<String, dynamic> token) {
    final index = indexForLocalMapToken(token);
    if (index < 0 || !canManageLocalMapToken(token)) return;
    setState(() {
      token['name'] = nomeSchedaPersonaggio(index);
      token['type'] = tipoSchedaPersonaggio(index);
      token['side'] = sheetSideAt(index);
      token['imageBase64'] = sheetImageBase64At(index);
      token['level'] = max(0, sheetIntValueAt(index, 'livello'));
      token['grade'] = max(0, sheetIntValueAt(index, 'grado'));
      token['initiativeBase'] = sheetRollBonusAt(index, 'iniziativa');
      token['reactionMax'] = sheetReazioniAt(index);
      token['reactionFastMax'] = sheetReazioniVelociAt(index);
      token['currentHp'] = max(0, sheetCurrentHpForDeathAt(index));
      token['maxHp'] = max(0, sheetMaxHpForDeathAt(index));
      token['tempHp'] = max(0, sheetIntValueAt(index, 'hpTemp'));
      token['shield'] = max(0, sheetIntValueAt(index, 'scudo'));
      token['size'] = mapTokenDefaultSize();
      risultato = t(
        'Token aggiornato dalla scheda: ${nomeSchedaPersonaggio(index)}.',
        'Token refreshed from sheet: ${nomeSchedaPersonaggio(index)}.',
      );
      aggiungiLog(risultato);
    });
    markVttLegacyMapChanged();
    programmaSalvataggio();
  }

  void resizeLocalMapToken(Map<String, dynamic> token, double delta) {
    if (!canManageLocalMapToken(token)) return;
    setState(() {
      final next = (readDoubleValue(token['size']) + delta)
          .clamp(24.0, 240.0)
          .toDouble();
      token['size'] = next;
    });
    markVttLegacyMapChanged();
    programmaSalvataggio();
  }

  void removeLocalMapToken(Map<String, dynamic> token) {
    if (!canManageLocalMapToken(token)) return;
    vttSelectedTokenIds.remove(localMapTokenStableId(token));
    setState(() {
      localMapTokens.removeWhere((item) => identical(item, token));
      risultato = t('Token rimosso dalla mappa.', 'Token removed from map.');
      aggiungiLog(risultato);
    });
    markVttLegacyMapChanged();
    programmaSalvataggio();
  }

  int localMapTokenLevel(Map<String, dynamic> token) {
    return max(0, readIntValue(token['level']));
  }

  int localMapTokenGrade(Map<String, dynamic> token) {
    return max(0, readIntValue(token['grade']));
  }

  int localMapTokenInitiativeBase(Map<String, dynamic> token) {
    return readIntValue(token['initiativeBase']);
  }

  int localMapTokenReactionMax(Map<String, dynamic> token) {
    return max(1, readIntValue(token['reactionMax'], fallback: 1));
  }

  int localMapTokenFastReactionMax(Map<String, dynamic> token) {
    return max(0, readIntValue(token['reactionFastMax']));
  }

  void syncLocalMapTokenInitiativeMirror(Map<String, dynamic> token) {
    final mapTokenId = '${token['id'] ?? ''}'.trim();
    if (mapTokenId.isEmpty) return;
    final initiativeIndex = masterInitiativeTokens.indexWhere(
      (item) => '${item['mapTokenId'] ?? ''}' == mapTokenId,
    );
    if (initiativeIndex < 0) return;

    final initiativeToken = masterInitiativeTokens[initiativeIndex];
    final roll = readIntValue(initiativeToken['initiativeRoll']);
    final base = localMapTokenInitiativeBase(token);
    final level = localMapTokenLevel(token);
    final grade = localMapTokenGrade(token);
    final difficulty = readIntValue(
      token['rollDifficulty'] ?? token['difficoltaTiro'],
    );
    initiativeToken['name'] = localMapTokenDisplayName(token);
    initiativeToken['type'] =
        '${token['type'] ?? t('Token libero', 'Free token')}';
    initiativeToken['side'] = '${token['side'] ?? 'neutral'}';
    initiativeToken['imageBase64'] = '${token['imageBase64'] ?? ''}';
    initiativeToken['colorArgb'] = readIntValue(token['colorArgb']);
    initiativeToken['level'] = level;
    initiativeToken['grade'] = grade;
    initiativeToken['initiativeBase'] = base;
    initiativeToken['initiativeTotal'] = roll > 0
        ? rollTotalWithCritical(
            roll,
            20,
            [base],
            level: level,
            grade: grade,
            difficulty: difficulty,
          )
        : base;
    initiativeToken['reactionMax'] = localMapTokenReactionMax(token);
    initiativeToken['reactionFastMax'] = localMapTokenFastReactionMax(token);
    initiativeToken['reactionManual'] = true;
    initiativeToken['reactionFastManual'] = true;
    initiativeToken['updatedAt'] = DateTime.now().toIso8601String();
    sortMasterInitiativeTokens(forceInitiative: true);
  }

  void sendLocalMapTokenToInitiative(Map<String, dynamic> token) {
    final index = indexForLocalMapToken(token);
    if (index >= 0) {
      if (!sheetCanBeAddedToMasterInitiative(index)) {
        setState(() {
          risultato = t(
            'Solo il Master/Co-Master puo mettere in turnistica token non propri.',
            'Only the Master/Co-Master can add non-owned tokens to initiative.',
          );
          aggiungiLog(risultato);
        });
        return;
      }
      addSheetToMasterInitiative(index);
      return;
    }

    if (!canManageLocalMapToken(token)) {
      setState(() {
        risultato = t(
          'Non puoi mettere in turnistica questo token libero.',
          'You cannot add this free token to initiative.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    setState(() {
      var mapTokenId = '${token['id'] ?? ''}'.trim();
      if (mapTokenId.isEmpty) {
        mapTokenId =
            'map_token_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';
        token['id'] = mapTokenId;
      }
      final roll = tiraD20();
      final base = localMapTokenInitiativeBase(token);
      final level = localMapTokenLevel(token);
      final grade = localMapTokenGrade(token);
      final difficulty = readIntValue(
        token['rollDifficulty'] ?? token['difficoltaTiro'],
      );
      final total = rollTotalWithCritical(
        roll,
        20,
        [base],
        level: level,
        grade: grade,
        difficulty: difficulty,
      );
      final existingIndex = masterInitiativeTokens.indexWhere(
        (item) => '${item['mapTokenId'] ?? ''}' == mapTokenId,
      );
      final initiativeToken = <String, dynamic>{
        'id': 'initiative_$mapTokenId',
        'mapTokenId': mapTokenId,
        'sheetTag': '',
        'name': localMapTokenDisplayName(token),
        'type': '${token['type'] ?? t('Token libero', 'Free token')}',
        'side': '${token['side'] ?? 'neutral'}',
        'imageBase64': '${token['imageBase64'] ?? ''}',
        'colorArgb': readIntValue(token['colorArgb']),
        'level': level,
        'grade': grade,
        'rollDifficulty': difficulty,
        'initiativeRoll': roll,
        'initiativeBase': base,
        'initiativeTotal': total,
        'tieBreaker': Random().nextInt(1 << 31),
        'status': 'ready',
        'notes': t('Token libero dalla mappa locale.', 'Free local map token.'),
        'reactionMax': localMapTokenReactionMax(token),
        'reactionFastMax': localMapTokenFastReactionMax(token),
        'reactionManual': true,
        'reactionFastManual': true,
        'reactionUsed': 0,
        'reactionUsedRound': 0,
        'reactionFastUsed': 0,
        'reactionFastTurnKey': '',
        'actionUsed': false,
        'temporaryTurn': false,
        'duplicateAction': false,
        'manualOrder': masterInitiativeManualCounter++,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (existingIndex >= 0) {
        final previous = masterInitiativeTokens[existingIndex];
        initiativeToken['id'] = previous['id'] ?? initiativeToken['id'];
        initiativeToken['tieBreaker'] =
            previous['tieBreaker'] ?? initiativeToken['tieBreaker'];
        initiativeToken['status'] = previous['status'] ?? 'ready';
        initiativeToken['notes'] =
            previous['notes'] ?? initiativeToken['notes'];
        initiativeToken['manualOrder'] =
            previous['manualOrder'] ?? existingIndex;
        initiativeToken['reactionUsed'] = previous['reactionUsed'] ?? 0;
        initiativeToken['reactionUsedRound'] =
            previous['reactionUsedRound'] ?? 0;
        initiativeToken['reactionFastUsed'] = previous['reactionFastUsed'] ?? 0;
        initiativeToken['reactionFastTurnKey'] =
            previous['reactionFastTurnKey'] ?? '';
        initiativeToken['actionUsed'] = previous['actionUsed'] ?? false;
        masterInitiativeTokens[existingIndex] = initiativeToken;
      } else {
        masterInitiativeTokens.add(initiativeToken);
      }

      sortMasterInitiativeTokens(forceInitiative: true);
      risultato = t(
        'Token libero in turnistica: ${localMapTokenDisplayName(token)}.',
        'Free token added to initiative: ${localMapTokenDisplayName(token)}.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  Future<void> showFreeLocalMapTokenEditor(Map<String, dynamic> token) async {
    if (!canManageLocalMapToken(token)) return;

    final nameController = TextEditingController(
      text: localMapTokenDisplayName(token),
    );
    final typeController = TextEditingController(
      text: '${token['type'] ?? t('Token libero', 'Free token')}',
    );
    final initiativeController = TextEditingController(
      text: localMapTokenInitiativeBase(token).toString(),
    );
    final levelController = TextEditingController(
      text: localMapTokenLevel(token).toString(),
    );
    final gradeController = TextEditingController(
      text: localMapTokenGrade(token).toString(),
    );
    final reactionsController = TextEditingController(
      text: localMapTokenReactionMax(token).toString(),
    );
    final fastReactionsController = TextEditingController(
      text: localMapTokenFastReactionMax(token).toString(),
    );
    final sizeController = TextEditingController(
      text: localMapTokenSize(token).round().toString(),
    );
    final movementController = TextEditingController(
      text: localMapTokenMovementBudget(token).toStringAsFixed(0),
    );
    final linkedSheetIndex = indexForLocalMapToken(token);
    final currentHpController = TextEditingController(
      text:
          '${token['currentHp'] ?? (linkedSheetIndex >= 0 ? sheetCurrentHpForDeathAt(linkedSheetIndex) : 0)}',
    );
    final maxHpController = TextEditingController(
      text:
          '${token['maxHp'] ?? (linkedSheetIndex >= 0 ? sheetMaxHpForDeathAt(linkedSheetIndex) : 0)}',
    );
    final tempHpController = TextEditingController(
      text:
          '${token['tempHp'] ?? (linkedSheetIndex >= 0 ? sheetIntValueAt(linkedSheetIndex, 'hpTemp') : 0)}',
    );
    final shieldController = TextEditingController(
      text:
          '${token['shield'] ?? (linkedSheetIndex >= 0 ? sheetIntValueAt(linkedSheetIndex, 'scudo') : 0)}',
    );
    final visionController = TextEditingController(
      text: '${token['visionMeters'] ?? 0}',
    );
    final auraController = TextEditingController(
      text: '${token['auraMeters'] ?? 0}',
    );
    final elevationController = TextEditingController(
      text: '${token['elevationMeters'] ?? 0}',
    );
    final rotationController = TextEditingController(
      text: '${token['rotationDegrees'] ?? 0}',
    );
    final conditionsController = TextEditingController(
      text: token['conditions'] is List
          ? (token['conditions'] as List).join(', ')
          : '${token['conditions'] ?? ''}',
    );
    final publicNotesController = TextEditingController(
      text: '${token['publicNotes'] ?? ''}',
    );
    final privateNotesController = TextEditingController(
      text: '${token['privateNotes'] ?? ''}',
    );
    var visible = _oculumVttBool(token['visible'], true);
    var hidden = _oculumVttBool(token['hidden']);
    var defeated = _oculumVttBool(token['defeated']);
    var dead = _oculumVttBool(token['dead']);
    var side = '${token['side'] ?? 'neutral'}'.toLowerCase();
    if (side != 'ally' && side != 'enemy' && side != 'neutral') {
      side = 'neutral';
    }
    var previewImageBase64 = '${token['imageBase64'] ?? ''}';
    var previewColor = localMapTokenColor(token);

    try {
      await showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            final previewToken = <String, dynamic>{
              ...token,
              'imageBase64': previewImageBase64,
              'colorArgb': previewColor.toARGB32(),
              'side': side,
            };

            return AlertDialog(
              backgroundColor: const Color(0xFF10121A),
              title: Text(
                t('Proprieta pedina', 'Token properties'),
                style: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          localMapTokenAvatar(previewToken, 76),
                          const SizedBox(width: 14),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final bytes =
                                    await readMapTokenImageFromClipboard();
                                if (!mounted) return;
                                if (bytes == null || bytes.isEmpty) {
                                  setState(() {
                                    risultato = t(
                                      'Nessuna immagine token trovata negli appunti.',
                                      'No token image found in the clipboard.',
                                    );
                                    aggiungiLog(risultato);
                                  });
                                  return;
                                }
                                setDialogState(() {
                                  previewImageBase64 = base64Encode(bytes);
                                  previewColor = predominantImageColor(bytes);
                                });
                              },
                              icon: const Icon(Icons.image_search),
                              label: Text(
                                t(
                                  'Cambia immagine dagli appunti',
                                  'Change image from clipboard',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nameController,
                        decoration: fieldDecoration(t('Nome', 'Name')),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: typeController,
                        decoration: fieldDecoration(t('Tipo', 'Type')),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: side,
                        decoration: fieldDecoration(t('Lato', 'Side')),
                        dropdownColor: const Color(0xFF10121A),
                        items: [
                          DropdownMenuItem(
                            value: 'ally',
                            child: Text(t('Alleato', 'Ally')),
                          ),
                          DropdownMenuItem(
                            value: 'enemy',
                            child: Text(t('Nemico', 'Enemy')),
                          ),
                          DropdownMenuItem(
                            value: 'neutral',
                            child: Text(t('Neutrale', 'Neutral')),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => side = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: 150,
                            child: TextField(
                              controller: initiativeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: true,
                                  ),
                              decoration: fieldDecoration(
                                t('Iniziativa', 'Initiative'),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: levelController,
                              keyboardType: TextInputType.number,
                              decoration: fieldDecoration(
                                t('Livello', 'Level'),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: gradeController,
                              keyboardType: TextInputType.number,
                              decoration: fieldDecoration(t('Grado', 'Grade')),
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: TextField(
                              controller: reactionsController,
                              keyboardType: TextInputType.number,
                              decoration: fieldDecoration(
                                t('Reazioni', 'Reactions'),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: TextField(
                              controller: fastReactionsController,
                              keyboardType: TextInputType.number,
                              decoration: fieldDecoration(
                                t('Reaz. rapide', 'Fast react.'),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: TextField(
                              controller: sizeController,
                              keyboardType: TextInputType.number,
                              decoration: fieldDecoration(
                                t('Grandezza', 'Size'),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: TextField(
                              controller: movementController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: fieldDecoration(
                                t('Movimento m', 'Move m'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          for (final field
                              in <
                                ({
                                  TextEditingController controller,
                                  String label,
                                })
                              >[
                                (
                                  controller: currentHpController,
                                  label: t('HP attuali', 'Current HP'),
                                ),
                                (
                                  controller: maxHpController,
                                  label: t('HP massimi', 'Max HP'),
                                ),
                                (
                                  controller: tempHpController,
                                  label: t('HP temporanei', 'Temporary HP'),
                                ),
                                (
                                  controller: shieldController,
                                  label: t('Scudo', 'Shield'),
                                ),
                                (
                                  controller: visionController,
                                  label: t('Visione m', 'Vision m'),
                                ),
                                (
                                  controller: auraController,
                                  label: t('Aura m', 'Aura m'),
                                ),
                                (
                                  controller: elevationController,
                                  label: t('Elevazione m', 'Elevation m'),
                                ),
                                (
                                  controller: rotationController,
                                  label: t(
                                    'Rotazione gradi',
                                    'Rotation degrees',
                                  ),
                                ),
                              ])
                            SizedBox(
                              width: 150,
                              child: TextField(
                                controller: field.controller,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      signed: true,
                                      decimal: true,
                                    ),
                                decoration: fieldDecoration(field.label),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: conditionsController,
                        decoration: fieldDecoration(
                          t(
                            'Condizioni separate da virgola',
                            'Comma-separated conditions',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: publicNotesController,
                        maxLines: 2,
                        decoration: fieldDecoration(
                          t('Note pubbliche', 'Public notes'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: privateNotesController,
                        maxLines: 2,
                        decoration: fieldDecoration(
                          t('Note private Master', 'Private Master notes'),
                        ),
                      ),
                      SwitchListTile.adaptive(
                        value: visible,
                        onChanged: (value) =>
                            setDialogState(() => visible = value),
                        title: Text(
                          t('Visibile ai giocatori', 'Visible to players'),
                        ),
                      ),
                      SwitchListTile.adaptive(
                        value: hidden,
                        onChanged: (value) =>
                            setDialogState(() => hidden = value),
                        title: Text(t('Nascosta', 'Hidden')),
                      ),
                      SwitchListTile.adaptive(
                        value: defeated,
                        onChanged: (value) =>
                            setDialogState(() => defeated = value),
                        title: Text(t('Sconfitta', 'Defeated')),
                      ),
                      SwitchListTile.adaptive(
                        value: dead,
                        onChanged: (value) =>
                            setDialogState(() => dead = value),
                        title: Text(t('Morta', 'Dead')),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t('Annulla', 'Cancel')),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      token['name'] = cleanUiText(nameController.text).trim();
                      token['type'] = cleanUiText(typeController.text).trim();
                      token['side'] = side;
                      token['imageBase64'] = previewImageBase64;
                      token['colorArgb'] = previewColor.toARGB32();
                      token['level'] = max(
                        0,
                        readIntValue(levelController.text),
                      );
                      token['grade'] = max(
                        0,
                        readIntValue(gradeController.text),
                      );
                      token['initiativeBase'] = readIntValue(
                        initiativeController.text,
                      );
                      token['reactionMax'] = max(
                        1,
                        readIntValue(reactionsController.text, fallback: 1),
                      );
                      token['reactionFastMax'] = max(
                        0,
                        readIntValue(fastReactionsController.text),
                      );
                      token['size'] = readDoubleValue(
                        sizeController.text,
                      ).clamp(24.0, 240.0);
                      final movement = readDoubleValue(movementController.text);
                      token['movementMaxMeters'] = movement > 0
                          ? movement
                          : mapFreeTokenMovementValue();
                      token['currentHp'] = max(
                        0,
                        readIntValue(currentHpController.text),
                      );
                      token['maxHp'] = max(
                        0,
                        readIntValue(maxHpController.text),
                      );
                      token['tempHp'] = max(
                        0,
                        readIntValue(tempHpController.text),
                      );
                      token['shield'] = max(
                        0,
                        readIntValue(shieldController.text),
                      );
                      token['visionMeters'] = max(
                        0.0,
                        readDoubleValue(visionController.text),
                      );
                      token['auraMeters'] = max(
                        0.0,
                        readDoubleValue(auraController.text),
                      );
                      token['elevationMeters'] = readDoubleValue(
                        elevationController.text,
                      );
                      token['rotationDegrees'] = readDoubleValue(
                        rotationController.text,
                      ).clamp(-180.0, 180.0);
                      token['conditions'] = conditionsController.text
                          .split(',')
                          .map((value) => cleanUiText(value).trim())
                          .where((value) => value.isNotEmpty)
                          .toSet()
                          .take(24)
                          .toList();
                      token['publicNotes'] = cleanUiText(
                        publicNotesController.text,
                      ).trim();
                      token['privateNotes'] = cleanUiText(
                        privateNotesController.text,
                      ).trim();
                      token['visible'] = visible;
                      token['hidden'] = hidden;
                      token['defeated'] = defeated;
                      token['dead'] = dead;
                      syncLocalMapTokenInitiativeMirror(token);
                      risultato = t(
                        'Token aggiornato: ${localMapTokenDisplayName(token)}.',
                        'Token updated: ${localMapTokenDisplayName(token)}.',
                      );
                      aggiungiLog(risultato);
                    });
                    markVttLegacyMapChanged();
                    programmaSalvataggio();
                    sendRealtimeInitiativeSnapshotIfPublished();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save),
                  label: Text(t('Salva', 'Save')),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      nameController.dispose();
      typeController.dispose();
      initiativeController.dispose();
      levelController.dispose();
      gradeController.dispose();
      reactionsController.dispose();
      fastReactionsController.dispose();
      sizeController.dispose();
      movementController.dispose();
      currentHpController.dispose();
      maxHpController.dispose();
      tempHpController.dispose();
      shieldController.dispose();
      visionController.dispose();
      auraController.dispose();
      elevationController.dispose();
      rotationController.dispose();
      conditionsController.dispose();
      publicNotesController.dispose();
      privateNotesController.dispose();
    }
  }

  Future<void> showLocalMapTokenMenu(
    Map<String, dynamic> token,
    Offset globalPosition,
  ) async {
    final canManage = canManageLocalMapToken(token);
    final canSend = canSendLocalMapTokenToInitiative(token);
    final hasLinkedSheet = indexForLocalMapToken(token) >= 0;
    final selected = localMapTokenIsSelected(token);
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'initiative',
          enabled: canSend,
          child: Row(
            children: [
              Icon(Icons.sports_martial_arts, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t('Metti in turnistica', 'Add to initiative')),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'edit',
          enabled: canManage,
          child: Row(
            children: [
              Icon(Icons.tune, color: tertiaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(t('Modifica token', 'Edit token'))),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'refresh',
          enabled: canManage && hasLinkedSheet,
          child: Row(
            children: [
              Icon(Icons.sync, color: tertiaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t('Aggiorna dalla scheda', 'Refresh from sheet')),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'select',
          enabled: canManage,
          child: Row(
            children: [
              Icon(
                selected ? Icons.deselect : Icons.select_all,
                color: tertiaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected
                      ? t('Deseleziona', 'Deselect')
                      : t('Seleziona per il gruppo', 'Select for group'),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'select_side',
          enabled: canManage,
          child: Row(
            children: [
              Icon(Icons.groups, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t('Seleziona stesso lato', 'Select same side')),
              ),
            ],
          ),
        ),
        if (vttSelectedTokenIds.isNotEmpty)
          PopupMenuItem<String>(
            value: 'clear_selection',
            child: Row(
              children: [
                const Icon(Icons.clear_all, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(t('Azzera selezione', 'Clear selection'))),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'bigger',
          enabled: canManage,
          child: Row(
            children: [
              Icon(Icons.zoom_in, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(t('Piu grande', 'Bigger')),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'smaller',
          enabled: canManage,
          child: Row(
            children: [
              Icon(Icons.zoom_out, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(t('Piu piccolo', 'Smaller')),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'resetMovement',
          enabled: canManage,
          child: Row(
            children: [
              Icon(Icons.directions_run, color: tertiaryColor, size: 18),
              const SizedBox(width: 8),
              Text(t('Reset movimento', 'Reset movement')),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'remove',
          enabled: canManage,
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(t('Togli token', 'Remove token')),
            ],
          ),
        ),
      ],
    );

    if (!mounted || choice == null) return;
    switch (choice) {
      case 'initiative':
        sendLocalMapTokenToInitiative(token);
        break;
      case 'edit':
        await showFreeLocalMapTokenEditor(token);
        break;
      case 'refresh':
        updateLocalMapTokenFromSheet(token);
        break;
      case 'select':
        toggleLocalMapTokenSelection(token);
        break;
      case 'select_side':
        final side = '${token['side'] ?? ''}';
        vttSelectedTokenIds
          ..clear()
          ..addAll(
            localMapTokens
                .where(
                  (candidate) =>
                      '${candidate['side'] ?? ''}' == side &&
                      canManageLocalMapToken(candidate),
                )
                .map(localMapTokenStableId)
                .where((id) => id.isNotEmpty),
          );
        vttCanvasRevision.value++;
        break;
      case 'clear_selection':
        vttSelectedTokenIds.clear();
        vttCanvasRevision.value++;
        break;
      case 'bigger':
        resizeLocalMapToken(token, 12);
        break;
      case 'smaller':
        resizeLocalMapToken(token, -12);
        break;
      case 'resetMovement':
        setState(() {
          resetLocalMapTokenMovement(token);
          risultato = t('Movimento token resettato.', 'Token movement reset.');
          aggiungiLog(risultato);
        });
        programmaSalvataggio();
        break;
      case 'remove':
        removeLocalMapToken(token);
        break;
    }
  }

  Widget localMapTokenControlPanel() {
    final indexes = localMapTokenSheetIndexes();
    final selected = safeLocalMapTokenSheetIndex();
    final hasSelectedToken = selectedSheetHasLocalMapToken();
    final canManageShared = canUseSharedSheetsForMasterInitiative();
    final canUseTokens = indexes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Divider(color: primaryColor.withValues(alpha: 0.28)),
        const SizedBox(height: 10),
        Text(
          t('Token mappa locale', 'Local map tokens'),
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: mapPlayersCanManageOwnToken,
          activeThumbColor: tertiaryColor,
          title: Text(
            t(
              'I player possono mettere/togliere il proprio token',
              'Players can place/remove their own token',
            ),
          ),
          subtitle: Text(
            canManageShared
                ? t(
                    'Il Master puo comunque gestire tutti i token e mandarli in turnistica.',
                    'The Master can still manage every token and send it to initiative.',
                  )
                : t(
                    'Se disattivo, solo Master/Co-Master puo gestire token sulla mappa.',
                    'If disabled, only Master/Co-Master can manage map tokens.',
                  ),
          ),
          onChanged: (value) {
            setState(() => mapPlayersCanManageOwnToken = value);
            programmaSalvataggio();
          },
        ),
        const SizedBox(height: 8),
        if (!canUseTokens)
          smallInfoText(
            t(
              'Nessuna scheda disponibile per creare token.',
              'No sheet available to create tokens.',
            ),
          )
        else ...[
          DropdownButtonFormField<int>(
            initialValue: selected < 0 ? indexes.first : selected,
            decoration: fieldDecoration(t('Scheda token', 'Token sheet')),
            dropdownColor: const Color(0xFF10121A),
            items: [
              for (final index in indexes)
                DropdownMenuItem<int>(
                  value: index,
                  child: Text(
                    '${nomeSchedaPersonaggio(index)} - ${tipoSchedaPersonaggio(index)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => mapTokenSheetIndex = value);
              programmaSalvataggio();
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 150,
                child: campoTesto(
                  label: t('Grandezza token', 'Token size'),
                  controller: mapTokenSizeController,
                  helper: '24-240',
                ),
              ),
              SizedBox(
                width: 170,
                child: campoTesto(
                  label: t('Larghezza mappa m', 'Map width m'),
                  controller: mapWidthMetersController,
                  helper: t('Scala movimento', 'Movement scale'),
                ),
              ),
              SizedBox(
                width: 160,
                child: campoTesto(
                  label: t('Altezza mappa m', 'Map height m'),
                  controller: mapHeightMetersController,
                  helper: t('Metri verticali', 'Vertical meters'),
                ),
              ),
              SizedBox(
                width: 190,
                child: campoTesto(
                  label: t('Movimento token libero', 'Free token movement'),
                  controller: mapFreeTokenMovementController,
                  helper: t('Metri per turno', 'Meters per turn'),
                ),
              ),
              ElevatedButton.icon(
                onPressed: toggleSelectedLocalMapToken,
                icon: Icon(
                  hasSelectedToken ? Icons.visibility_off : Icons.add_location,
                ),
                label: Text(
                  hasSelectedToken
                      ? t('Togli token', 'Remove token')
                      : t('Metti token', 'Place token'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: placeAllAvailableSheetTokensOnLocalMap,
                icon: const Icon(Icons.group_add),
                label: Text(t('Metti schede', 'Place sheets')),
              ),
              if (canManageShared && localMapTokens.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      localMapTokens.clear();
                      risultato = t(
                        'Token mappa locale rimossi.',
                        'Local map tokens removed.',
                      );
                      aggiungiLog(risultato);
                    });
                    programmaSalvataggio();
                  },
                  icon: const Icon(Icons.layers_clear),
                  label: Text(t('Pulisci token', 'Clear tokens')),
                ),
            ],
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Trascina i token sulla mappa. Tasto destro o pressione lunga: turnistica, modifica, dimensione, aggiorna o rimuovi.',
              'Drag tokens on the map. Right-click or long press: initiative, edit, size, refresh or remove.',
            ),
          ),
        ],
      ],
    );
  }

  double localMapTokenAxis(Map<String, dynamic> token, String key) {
    final value = token[key];
    if (value == null) return 0.5;
    return readDoubleValue(value).clamp(0.0, 1.0).toDouble();
  }

  double localMapTokenSize(Map<String, dynamic> token) {
    final size = readDoubleValue(token['size']);
    if (size <= 0) return mapTokenDefaultSize();
    return size.clamp(24.0, 240.0).toDouble();
  }

  int sheetMovementAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return 0;
    if (index == schedaCorrente) return movimento();
    final derived = readIntValue(
      schedePersonaggio[index]['derivedMovimento'],
      fallback: -1,
    );
    if (derived >= 0) return derived;
    return max(0, 30 + sheetIntValueAt(index, 'materia') ~/ 6);
  }

  Map<String, dynamic>? initiativeTokenForLocalMapToken(
    Map<String, dynamic> token,
  ) {
    final mapTokenId = '${token['id'] ?? ''}'.trim();
    if (mapTokenId.isNotEmpty) {
      for (final initiativeToken in masterInitiativeTokens) {
        if ('${initiativeToken['mapTokenId'] ?? ''}' == mapTokenId) {
          return initiativeToken;
        }
      }
    }

    final sheetTag = normalizeOculumFriendTag('${token['sheetTag'] ?? ''}');
    final tag = sheetTag.isNotEmpty ? sheetTag : localMapTokenOwnerTag(token);
    if (tag.isEmpty) return null;
    for (final initiativeToken in masterInitiativeTokens) {
      final candidate = normalizeOculumFriendTag(
        '${initiativeToken['sheetTag'] ?? initiativeToken['sheetId'] ?? ''}',
      );
      if (candidate == tag) return initiativeToken;
    }
    return null;
  }

  double localMapTokenMovementUsed(Map<String, dynamic> token) {
    return readDoubleValue(token['movementUsedMeters']);
  }

  double localMapTokenMovementBudget(Map<String, dynamic> token) {
    final index = indexForLocalMapToken(token);
    if (index < 0) {
      final custom = readDoubleValue(token['movementMaxMeters']);
      return custom > 0 ? custom : mapFreeTokenMovementValue();
    }
    return sheetMovementAt(index).toDouble();
  }

  void resetLocalMapTokenMovement(Map<String, dynamic> token) {
    token['movementUsedMeters'] = 0.0;
    token['movementTurnKey'] = masterInitiativeTurnKey();
    token['movementRound'] = masterInitiativeRound;
  }

  void resetLocalMapMovementForInitiativeToken(Map<String, dynamic> token) {
    final mapTokenId = '${token['mapTokenId'] ?? ''}'.trim();
    if (mapTokenId.isNotEmpty) {
      for (final mapToken in localMapTokens) {
        if ('${mapToken['id'] ?? ''}' == mapTokenId) {
          resetLocalMapTokenMovement(mapToken);
          return;
        }
      }
    }

    final tag = normalizeOculumFriendTag(
      '${token['sheetTag'] ?? token['sheetId'] ?? ''}',
    );
    if (tag.isEmpty) return;
    for (final mapToken in localMapTokens) {
      final mapSheetTag = normalizeOculumFriendTag(
        '${mapToken['sheetTag'] ?? ''}',
      );
      final mapOwnerTag = localMapTokenOwnerTag(mapToken);
      if (mapSheetTag == tag || mapOwnerTag == tag) {
        resetLocalMapTokenMovement(mapToken);
      }
    }
  }

  double localMapTokenMovementRemaining(Map<String, dynamic> token) {
    final budget = localMapTokenMovementBudget(token);
    if (budget.isInfinite) return double.infinity;
    return max(0.0, budget - localMapTokenMovementUsed(token)).toDouble();
  }

  bool prepareLocalMapTokenMovement(Map<String, dynamic> token) {
    final initiativeToken = initiativeTokenForLocalMapToken(token);
    if (initiativeToken != null &&
        masterInitiativeReactionUsedTotal(initiativeToken) > 0) {
      return false;
    }

    if (initiativeToken != null) {
      final movementKey =
          '${initiativeToken['id'] ?? initiativeToken['sheetTag'] ?? ''}:$masterInitiativeRound';
      if ('${initiativeToken['status'] ?? ''}' == 'active' &&
          '${token['movementTurnKey'] ?? ''}' != movementKey) {
        token['movementTurnKey'] = movementKey;
        token['movementUsedMeters'] = 0.0;
      } else {
        token['movementTurnKey'] = '${token['movementTurnKey'] ?? movementKey}';
      }
    } else {
      token['movementTurnKey'] =
          '${token['movementTurnKey'] ?? masterInitiativeTurnKey()}';
    }
    return true;
  }

  double localMapTokenMovementScale(
    Map<String, dynamic> token,
    Offset requested,
    double canvasWidth,
    double canvasHeight,
  ) {
    return oculumVttMovementTranslationScale(
      requested,
      remainingMeters: localMapTokenMovementRemaining(token),
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      mapWidthMeters: mapWidthMetersValue(),
      mapHeightMeters: mapHeightMetersValue(),
    );
  }

  void consumeLocalMapTokenMovement(
    Map<String, dynamic> token,
    Offset delta,
    double canvasWidth,
    double canvasHeight,
  ) {
    final meters = oculumVttDistanceMetersForDelta(
      delta,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      mapWidthMeters: mapWidthMetersValue(),
      mapHeightMeters: mapHeightMetersValue(),
    );
    if (meters <= 0 || localMapTokenMovementBudget(token).isInfinite) return;
    token['movementUsedMeters'] = localMapTokenMovementUsed(token) + meters;
  }

  Offset allowedLocalMapTokenDelta(
    Map<String, dynamic> token,
    Offset requested,
    double canvasWidth,
    double canvasHeight,
  ) {
    if (!prepareLocalMapTokenMovement(token)) return Offset.zero;
    final allowed =
        requested *
        localMapTokenMovementScale(token, requested, canvasWidth, canvasHeight);
    consumeLocalMapTokenMovement(token, allowed, canvasWidth, canvasHeight);
    return allowed;
  }

  Color localMapTokenColor(Map<String, dynamic> token) {
    final custom = readIntValue(token['colorArgb']);
    if (custom != 0) return Color(custom);
    final side = '${token['side'] ?? ''}'.toLowerCase();
    if (side == 'enemy') return Colors.redAccent;
    if (side == 'neutral') return Colors.blueGrey.shade200;
    return primaryColor;
  }

  String localMapTokenDisplayName(Map<String, dynamic> token) {
    final index = indexForLocalMapToken(token);
    if (index >= 0) return nomeSchedaPersonaggio(index);
    final name = '${token['name'] ?? ''}'.trim();
    return name.isEmpty ? t('Token', 'Token') : name;
  }

  String localMapTokenStableId(Map<String, dynamic> token) {
    return '${token['id'] ?? token['sheetTag'] ?? ''}'.trim();
  }

  bool localMapTokenIsSelected(Map<String, dynamic> token) {
    final id = localMapTokenStableId(token);
    return id.isNotEmpty && vttSelectedTokenIds.contains(id);
  }

  void toggleLocalMapTokenSelection(Map<String, dynamic> token) {
    if (!canManageLocalMapToken(token)) return;
    final id = localMapTokenStableId(token);
    if (id.isEmpty) return;
    if (vttSelectedTokenIds.contains(id)) {
      vttSelectedTokenIds.remove(id);
    } else {
      vttSelectedTokenIds.add(id);
    }
    vttCanvasRevision.value++;
  }

  List<Map<String, dynamic>> localMapTokenDragGroup(
    Map<String, dynamic> anchor,
  ) {
    if (!localMapTokenIsSelected(anchor) || vttSelectedTokenIds.length < 2) {
      return <Map<String, dynamic>>[anchor];
    }
    final selected = localMapTokens
        .where(
          (token) =>
              localMapTokenIsSelected(token) && canManageLocalMapToken(token),
        )
        .toList(growable: false);
    return selected.isEmpty ? <Map<String, dynamic>>[anchor] : selected;
  }

  void moveLocalMapTokenGroup(
    Map<String, dynamic> anchor,
    Offset requested,
    double canvasWidth,
    double canvasHeight,
  ) {
    final group = localMapTokenDragGroup(anchor);
    if (requested == Offset.zero || group.isEmpty) return;

    var commonScale = 1.0;
    for (final token in group) {
      if (!prepareLocalMapTokenMovement(token)) return;
      commonScale = min(
        commonScale,
        oculumVttBoundaryTranslationScale(
          x: localMapTokenAxis(token, 'x'),
          y: localMapTokenAxis(token, 'y'),
          delta: requested,
          canvasWidth: canvasWidth,
          canvasHeight: canvasHeight,
        ),
      );
      commonScale = min(
        commonScale,
        localMapTokenMovementScale(token, requested, canvasWidth, canvasHeight),
      );
    }
    if (commonScale <= 0) return;

    final allowedDelta = requested * commonScale;
    for (final token in group) {
      if (vttConstrainTokenDelta(
            token,
            allowedDelta,
            canvasWidth,
            canvasHeight,
          ) !=
          allowedDelta) {
        return;
      }
    }

    for (final token in group) {
      token['x'] =
          (localMapTokenAxis(token, 'x') +
                  allowedDelta.dx / max(1.0, canvasWidth))
              .clamp(0.0, 1.0);
      token['y'] =
          (localMapTokenAxis(token, 'y') +
                  allowedDelta.dy / max(1.0, canvasHeight))
              .clamp(0.0, 1.0);
      consumeLocalMapTokenMovement(
        token,
        allowedDelta,
        canvasWidth,
        canvasHeight,
      );
    }
    notifyVttCanvasChanged();
  }

  void finishLocalMapTokenGroupMove(
    Map<String, dynamic> anchor,
    double canvasWidth,
    double canvasHeight,
  ) {
    final group = localMapTokenDragGroup(anchor);
    if (activeVttScene.snapToGrid && activeVttScene.gridType != 'none') {
      final anchorPoint = Offset(
        localMapTokenAxis(anchor, 'x') * canvasWidth,
        localMapTokenAxis(anchor, 'y') * canvasHeight,
      );
      final snappedAnchor = oculumVttSnapPoint(
        anchorPoint,
        gridType: activeVttScene.gridType,
        cellSize: activeVttScene.gridSizePx,
      );
      final requestedSnap = snappedAnchor - anchorPoint;
      var snapScale = 1.0;
      for (final token in group) {
        snapScale = min(
          snapScale,
          oculumVttBoundaryTranslationScale(
            x: localMapTokenAxis(token, 'x'),
            y: localMapTokenAxis(token, 'y'),
            delta: requestedSnap,
            canvasWidth: canvasWidth,
            canvasHeight: canvasHeight,
          ),
        );
      }
      final snapDelta = requestedSnap * snapScale;
      final blocked = group.any(
        (token) =>
            vttConstrainTokenDelta(
              token,
              snapDelta,
              canvasWidth,
              canvasHeight,
            ) !=
            snapDelta,
      );
      if (!blocked) {
        for (final token in group) {
          token['x'] =
              (localMapTokenAxis(token, 'x') +
                      snapDelta.dx / max(1.0, canvasWidth))
                  .clamp(0.0, 1.0);
          token['y'] =
              (localMapTokenAxis(token, 'y') +
                      snapDelta.dy / max(1.0, canvasHeight))
                  .clamp(0.0, 1.0);
        }
      }
    }
    notifyVttCanvasChanged(save: true);
    for (final token in group) {
      if (modalitaMaster && realtimeService?.isConnected == true) {
        unawaited(sendAuthoritativeVttTokenPosition(token));
      }
      evaluateVttTriggersForToken(token);
    }
  }

  Widget localMapTokenAvatar(Map<String, dynamic> token, double size) {
    final imageRaw = '${token['imageBase64'] ?? ''}';
    final color = localMapTokenColor(token);
    Widget child;
    final bytes = decodedBase64ImageCached(imageRaw);
    if (bytes != null) {
      child = Image.memory(
        bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        cacheWidth: max(1, (size * 2).round()),
        cacheHeight: max(1, (size * 2).round()),
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.person_pin_circle, color: color, size: size * 0.54),
      );
    } else {
      child = Icon(Icons.person_pin_circle, color: color, size: size * 0.54);
    }

    final border = max(3, size / 18).toDouble();
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.34),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipPath(
          clipper: const HexagonClipper(),
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.88),
            child: Padding(
              padding: EdgeInsets.all(border),
              child: ClipPath(
                clipper: const HexagonClipper(),
                child: ColoredBox(
                  color: color,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: ClipPath(
                      clipper: const HexagonClipper(),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> localMapTokenConditions(Map<String, dynamic> token) {
    final raw = token['conditions'];
    if (raw is List) {
      return raw
          .map((value) => cleanUiText('$value').trim())
          .where((value) => value.isNotEmpty)
          .take(24)
          .toList(growable: false);
    }
    return '$raw'
        .split(',')
        .map((value) => cleanUiText(value).trim())
        .where((value) => value.isNotEmpty && value != 'null')
        .take(24)
        .toList(growable: false);
  }

  Widget localMapTokenStateAvatar(Map<String, dynamic> token, double size) {
    final color = localMapTokenColor(token);
    final selected = localMapTokenIsSelected(token);
    final visible = _oculumVttBool(token['visible'], true);
    final hidden = _oculumVttBool(token['hidden']);
    final defeated = _oculumVttBool(token['defeated']);
    final dead = _oculumVttBool(token['dead']);
    final auraMeters = max(0.0, readDoubleValue(token['auraMeters']));
    final rotation = readDoubleValue(token['rotationDegrees']) * pi / 180;
    final opacity = dead
        ? 0.38
        : defeated
        ? 0.52
        : (!visible || hidden)
        ? 0.58
        : 1.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: <Widget>[
          if (auraMeters > 0)
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.72),
                  width: 2,
                ),
                color: color.withValues(alpha: 0.08),
              ),
            ),
          Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: rotation,
              child: localMapTokenAvatar(token, size),
            ),
          ),
          if (selected)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: Colors.cyanAccent, width: 3),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(color: Colors.cyanAccent, blurRadius: 8),
                  ],
                ),
              ),
            ),
          if (dead || defeated)
            IgnorePointer(
              child: Center(
                child: Icon(
                  dead ? Icons.close : Icons.heart_broken,
                  color: dead ? Colors.redAccent : Colors.orangeAccent,
                  size: size * 0.48,
                  shadows: const <Shadow>[
                    Shadow(color: Colors.black, blurRadius: 5),
                  ],
                ),
              ),
            ),
          if (!visible || hidden)
            Align(
              alignment: Alignment.topRight,
              child: Icon(
                hidden ? Icons.visibility_off : Icons.hide_source,
                color: Colors.white,
                size: max(14.0, size * 0.24),
                shadows: const <Shadow>[
                  Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget localMapTokenVitals(
    Map<String, dynamic> token,
    double width,
    Color color,
  ) {
    final currentHp = max(0, readIntValue(token['currentHp']));
    final maxHp = max(0, readIntValue(token['maxHp']));
    final tempHp = max(0, readIntValue(token['tempHp']));
    final shield = max(0, readIntValue(token['shield']));
    final elevation = readDoubleValue(token['elevationMeters']);
    final conditions = localMapTokenConditions(token);
    final hpRatio = maxHp <= 0 ? 0.0 : (currentHp / maxHp).clamp(0.0, 1.0);
    final detailParts = <String>[
      ...conditions.take(2),
      if (elevation != 0) 'H ${elevation.toStringAsFixed(1)} m',
    ];

    return SizedBox(
      width: width,
      height: 25,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: hpRatio,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                color: currentHp <= 0 && maxHp > 0 ? Colors.redAccent : color,
              ),
            ),
          ),
          SizedBox(
            height: 10,
            child: Text(
              maxHp > 0
                  ? 'HP $currentHp/$maxHp${tempHp > 0 ? ' T$tempHp' : ''}${shield > 0 ? ' S$shield' : ''}'
                  : '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 8,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 10,
            child: Text(
              detailParts.join(' | '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color.withValues(alpha: 0.92),
                fontSize: 8,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget localMapTokenWidget(
    Map<String, dynamic> token,
    double canvasWidth,
    double canvasHeight,
  ) {
    final size = localMapTokenSize(token);
    final boxWidth = max(size + 40, 92).toDouble();
    final movementBudget = localMapTokenMovementBudget(token);
    final movementRemaining = localMapTokenMovementRemaining(token);
    final hasMovementLabel = movementBudget.isFinite && movementBudget > 0;
    final movementLabel = hasMovementLabel
        ? '${movementRemaining.toStringAsFixed(movementRemaining < 10 ? 1 : 0)}/${movementBudget.toStringAsFixed(movementBudget < 10 ? 1 : 0)} m'
        : '';
    final canDrag =
        canManageLocalMapToken(token) &&
        (vttTool == OculumVttTool.select || vttTool == OculumVttTool.pan);
    final infoHeight = hasMovementLabel ? 57.0 : 45.0;
    final boxHeight = size + infoHeight + 3 + (canDrag ? 24 : 0);
    final x = localMapTokenAxis(token, 'x');
    final y = localMapTokenAxis(token, 'y');
    final left = (x * canvasWidth - boxWidth / 2)
        .clamp(0.0, max(0, canvasWidth - boxWidth))
        .toDouble();
    final top = (y * canvasHeight - boxHeight / 2)
        .clamp(0.0, max(0, canvasHeight - boxHeight))
        .toDouble();
    final color = localMapTokenColor(token);
    final name = localMapTokenDisplayName(token);

    return Positioned(
      left: left,
      top: top,
      width: boxWidth,
      height: boxHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: canDrag
            ? (details) => moveLocalMapTokenGroup(
                token,
                details.delta,
                canvasWidth,
                canvasHeight,
              )
            : null,
        onPanEnd: canDrag
            ? (_) =>
                  finishLocalMapTokenGroupMove(token, canvasWidth, canvasHeight)
            : null,
        onTap: canDrag && vttTool == OculumVttTool.select
            ? () => toggleLocalMapTokenSelection(token)
            : null,
        onSecondaryTapDown: (details) =>
            showLocalMapTokenMenu(token, details.globalPosition),
        onLongPressStart: (details) =>
            showLocalMapTokenMenu(token, details.globalPosition),
        child: Tooltip(
          message: t(
            '$name${hasMovementLabel ? '\nMovimento: $movementLabel' : ''}\nTasto destro: turnistica e opzioni.',
            '$name${hasMovementLabel ? '\nMovement: $movementLabel' : ''}\nRight-click: initiative and options.',
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canDrag)
                SizedBox(
                  height: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        tooltip: t('Rimpicciolisci token', 'Shrink token'),
                        onPressed: () => resizeLocalMapToken(token, -8),
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 22,
                        ),
                        padding: EdgeInsets.zero,
                        iconSize: 14,
                        icon: const Icon(Icons.remove),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        tooltip: t('Ingrandisci token', 'Enlarge token'),
                        onPressed: () => resizeLocalMapToken(token, 8),
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 22,
                        ),
                        padding: EdgeInsets.zero,
                        iconSize: 14,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              localMapTokenStateAvatar(token, size),
              const SizedBox(height: 3),
              Container(
                width: boxWidth,
                height: infoHeight,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.74),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.55)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (hasMovementLabel)
                      Text(
                        movementLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    localMapTokenVitals(token, boxWidth - 8, color),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget localImageMapViewer(File imageFile, double width, double height) {
    return vttMapCanvas(
      width: width,
      height: height,
      imageProvider: FileImage(imageFile),
    );
  }

  int sheetIndexForInitiativeToken(Map<String, dynamic> token) {
    final tag = normalizeOculumFriendTag(
      '${token['sheetTag'] ?? token['sheetId'] ?? ''}',
    );
    if (tag.isEmpty) return -1;
    return schedePersonaggio.indexWhere(
      (sheet) =>
          normalizeOculumFriendTag(
            '${sheet['sheetTag'] ?? sheet['id'] ?? ''}',
          ) ==
          tag,
    );
  }

  Map<String, dynamic>? localMapTokenForInitiativeToken(
    Map<String, dynamic> token,
  ) {
    final mapTokenId = '${token['mapTokenId'] ?? ''}'.trim();
    if (mapTokenId.isNotEmpty) {
      for (final mapToken in localMapTokens) {
        if ('${mapToken['id'] ?? ''}' == mapTokenId) return mapToken;
      }
    }

    final tag = normalizeOculumFriendTag(
      '${token['sheetTag'] ?? token['sheetId'] ?? ''}',
    );
    if (tag.isEmpty) return null;
    for (final mapToken in localMapTokens) {
      final mapSheetTag = normalizeOculumFriendTag(
        '${mapToken['sheetTag'] ?? ''}',
      );
      final mapOwnerTag = localMapTokenOwnerTag(mapToken);
      if (mapSheetTag == tag || mapOwnerTag == tag) {
        return mapToken;
      }
    }
    return null;
  }

  Widget localMapMiniInitiativePanel() {
    if (masterInitiativeTokens.isEmpty) {
      return smallInfoText(
        t(
          'Mini turnistica: aggiungi token alla turnistica con tasto destro sulla mappa.',
          'Mini initiative: add tokens to initiative with right-click on the map.',
        ),
      );
    }

    final active = masterInitiativeActiveIndex
        .clamp(0, masterInitiativeTokens.length - 1)
        .toInt();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_martial_arts, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${t('Mini turnistica', 'Mini initiative')} - ${t('Round', 'Round')} $masterInitiativeRound',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: t('Turno precedente', 'Previous turn'),
                onPressed: () => nextMasterInitiativeTurn(delta: -1),
                icon: const Icon(Icons.chevron_left),
                color: primaryColor,
              ),
              IconButton(
                tooltip: t('Turno successivo', 'Next turn'),
                onPressed: () => nextMasterInitiativeTurn(),
                icon: const Icon(Icons.chevron_right),
                color: primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < masterInitiativeTokens.length; i++)
                Builder(
                  builder: (context) {
                    final token = masterInitiativeTokens[i];
                    final mapToken = localMapTokenForInitiativeToken(token);
                    final sheetIndex = sheetIndexForInitiativeToken(token);
                    final budget = sheetIndex >= 0
                        ? sheetMovementAt(sheetIndex)
                        : 0;
                    final remaining = mapToken == null
                        ? budget.toDouble()
                        : localMapTokenMovementRemaining(mapToken);
                    final reactionUsed =
                        masterInitiativeReactionUsedTotal(token) > 0;
                    final isActive = i == active;
                    final sideColor = '${token['side'] ?? ''}' == 'enemy'
                        ? Colors.redAccent
                        : isActive
                        ? tertiaryColor
                        : primaryColor;
                    return ActionChip(
                      avatar: Icon(
                        reactionUsed
                            ? Icons.bolt
                            : isActive
                            ? Icons.play_arrow
                            : Icons.circle,
                        size: 16,
                        color: sideColor,
                      ),
                      label: Text(
                        '${token['name'] ?? '???'}'
                        '${budget > 0 ? ' ${remaining.isInfinite ? '' : '${remaining.round()}/$budget m'}' : ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      tooltip: reactionUsed
                          ? t(
                              'Reazione usata: movimento token bloccato.',
                              'Reaction used: token movement locked.',
                            )
                          : t(
                              'Tocca per renderlo turno attivo.',
                              'Tap to make this the active turn.',
                            ),
                      backgroundColor: sideColor.withValues(
                        alpha: isActive ? 0.24 : 0.12,
                      ),
                      side: BorderSide(color: sideColor.withValues(alpha: 0.6)),
                      onPressed: () => setMasterInitiativeActiveIndex(i),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget mapControlPanel() {
    final onlineSelected = mapMode == 'online';
    final hasLocalImage =
        !onlineSelected &&
        (activeVttScene.imageDataBase64.isNotEmpty ||
            (!kIsWeb &&
                mapImagePath.trim().isNotEmpty &&
                File(mapImagePath.trim()).existsSync()));
    return gothicPanel(
      borderColor: onlineSelected ? tertiaryColor : primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.map,
                color: onlineSelected ? tertiaryColor : primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Controlli mappa', 'Map controls'),
                  style: TextStyle(
                    color: onlineSelected ? tertiaryColor : primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                selected: mapMode == 'image',
                label: Text(t('Immagine locale', 'Local image')),
                avatar: const Icon(Icons.image, size: 18),
                onSelected: (_) {
                  setState(() => mapMode = 'image');
                  markVttLegacyMapChanged(includeAsset: true);
                  programmaSalvataggio();
                },
              ),
              ChoiceChip(
                selected: onlineSelected,
                label: Text(t('Mappa online', 'Online map')),
                avatar: const Icon(Icons.public, size: 18),
                onSelected: (_) {
                  setState(() => mapMode = 'online');
                  markVttLegacyMapChanged(includeAsset: true);
                  programmaSalvataggio();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!onlineSelected) ...[
            smallInfoText(
              t(
                'Importa una mappa immagine per usarla offline con zoom, pan e reset vista.',
                'Import an image map for offline zoom, pan and view reset.',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: scegliImmagineMappa,
                  icon: const Icon(Icons.upload_file),
                  label: Text(t('Importa', 'Import')),
                ),
                OutlinedButton.icon(
                  onPressed: incollaImmagineMappa,
                  icon: Icon(
                    hasLocalImage ? Icons.hexagon : Icons.content_paste,
                  ),
                  label: Text(
                    hasLocalImage
                        ? t('Incolla token', 'Paste token')
                        : t('Incolla', 'Paste'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: incollaTokenImmagineMappa,
                  icon: const Icon(Icons.hexagon),
                  label: Text(t('Incolla token', 'Paste token')),
                ),
                OutlinedButton.icon(
                  onPressed: resetMapView,
                  icon: const Icon(Icons.center_focus_strong),
                  label: Text(t('Reset vista', 'Reset view')),
                ),
                TextButton.icon(
                  onPressed: mapImagePath.trim().isEmpty
                      ? null
                      : removeMapImage,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(t('Rimuovi', 'Remove')),
                ),
              ],
            ),
            localMapTokenControlPanel(),
          ] else ...[
            smallInfoText(
              t(
                'Per Foundry, Roll20, Owlbear o altri VTT: Oculum salva il link e prova il browser in-app quando supportato. Non salva credenziali o cookie.',
                'For Foundry, Roll20, Owlbear or other VTTs: Oculum saves the link and tries the in-app browser when supported. It does not save credentials or cookies.',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: mapUrlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              style: TextStyle(fontSize: uiScale(16), color: Colors.white),
              decoration: fieldDecoration(
                t('Link mappa online', 'Online map link'),
                helper: 'https://uningrafted-delma-fiendishly.ngrok-free.dev',
              ),
              onSubmitted: (_) => normalizeOnlineMapLink(announce: true),
              onChanged: (_) => programmaSalvataggio(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => normalizeOnlineMapLink(announce: true),
                  icon: const Icon(Icons.web_asset),
                  label: Text(t('Carica riquadro', 'Load frame')),
                ),
                OutlinedButton.icon(
                  onPressed: openOnlineMapInApp,
                  icon: const Icon(Icons.fullscreen),
                  label: Text(t('Fullscreen', 'Fullscreen')),
                ),
                OutlinedButton.icon(
                  onPressed: pasteOnlineMapLink,
                  icon: const Icon(Icons.content_paste_go),
                  label: Text(t('Incolla link', 'Paste link')),
                ),
                OutlinedButton.icon(
                  onPressed: openOnlineMapExternal,
                  icon: const Icon(Icons.open_in_browser),
                  label: Text(t('Browser', 'Browser')),
                ),
                OutlinedButton.icon(
                  onPressed: () => normalizeOnlineMapLink(announce: true),
                  icon: const Icon(Icons.save),
                  label: Text(t('Salva link', 'Save link')),
                ),
                TextButton.icon(
                  onPressed: clearMapSessionPreference,
                  icon: const Icon(Icons.lock_reset),
                  label: Text(t('Privacy', 'Privacy')),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget mapViewerPanel() {
    final onlineSelected = mapMode == 'online';
    final remoteSelected = vttShowingRemoteScene;
    final remoteScene = remoteSelected ? vttSceneForDisplay() : null;
    ImageProvider? remoteImageProvider;
    if (remoteSelected && realtimeVisibleVttImageBytes != null) {
      remoteImageProvider = MemoryImage(realtimeVisibleVttImageBytes!);
    } else if (remoteScene != null) {
      final uri = Uri.tryParse(remoteScene.mapUrl.trim());
      final lowerPath = uri?.path.toLowerCase() ?? '';
      if (uri != null &&
          (lowerPath.endsWith('.png') ||
              lowerPath.endsWith('.jpg') ||
              lowerPath.endsWith('.jpeg') ||
              lowerPath.endsWith('.webp'))) {
        remoteImageProvider = NetworkImage(uri.toString());
      }
    }
    final onlineUri = safeMapUri();
    final imagePath = mapImagePath.trim();
    final imageFile = kIsWeb || imagePath.isEmpty ? null : File(imagePath);
    final hasImage = imageFile != null && imageFile.existsSync();
    ImageProvider? embeddedImageProvider;
    final embedded = activeVttScene.imageDataBase64.trim();
    if (embedded.isNotEmpty) {
      final bytes = decodedBase64ImageCached(embedded);
      if (bytes != null) embeddedImageProvider = MemoryImage(bytes);
    }
    return gothicPanel(
      borderColor: onlineSelected ? tertiaryColor : primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                onlineSelected ? Icons.public : Icons.travel_explore,
                color: onlineSelected ? tertiaryColor : primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  remoteSelected
                      ? remoteScene!.name
                      : onlineSelected
                      ? t('Mappa online', 'Online map')
                      : (mapImageName.trim().isEmpty
                            ? t('Mappa locale', 'Local map')
                            : mapImageName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onlineSelected ? tertiaryColor : primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (!remoteSelected && onlineSelected && onlineUri != null) ...[
                IconButton(
                  tooltip: t('Apri fullscreen', 'Open fullscreen'),
                  onPressed: openOnlineMapInApp,
                  icon: const Icon(Icons.fullscreen),
                  color: tertiaryColor,
                ),
                IconButton(
                  tooltip: t('Browser esterno', 'External browser'),
                  onPressed: openOnlineMapExternal,
                  icon: const Icon(Icons.open_in_browser),
                  color: tertiaryColor,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.clamp(300.0, 640.0).toDouble();
              final height = onlineSelected && !remoteSelected
                  ? (width * 0.74).clamp(360.0, 560.0).toDouble()
                  : (width * 0.62).clamp(260.0, 520.0).toDouble();
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: height,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.40),
                    border: Border.all(
                      color: (onlineSelected ? tertiaryColor : primaryColor)
                          .withValues(alpha: 0.48),
                    ),
                  ),
                  child: remoteSelected
                      ? vttMapCanvas(
                          width: constraints.maxWidth,
                          height: height,
                          imageProvider: remoteImageProvider,
                          sceneOverride: remoteScene,
                          readOnly: true,
                        )
                      : onlineSelected
                      ? onlineMapViewer(onlineUri)
                      : embeddedImageProvider != null
                      ? vttMapCanvas(
                          width: constraints.maxWidth,
                          height: height,
                          imageProvider: embeddedImageProvider,
                        )
                      : hasImage
                      ? localImageMapViewer(
                          imageFile,
                          constraints.maxWidth,
                          height,
                        )
                      : vttMapCanvas(
                          width: constraints.maxWidth,
                          height: height,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget onlineMapViewer(Uri? uri) {
    if (uri == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_browser, color: tertiaryColor, size: 42),
              const SizedBox(height: 12),
              Text(
                t('Nessun link mappa', 'No map link'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              smallInfoText(
                t(
                  'Incolla un link ngrok, Foundry, Roll20 o VTT sopra: verra caricato nel riquadro mappa dentro Oculum.',
                  'Paste an ngrok, Foundry, Roll20 or VTT link above: it will load in the map frame inside Oculum.',
                ),
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      );
    }

    return OculumEmbeddedBrowser(
      key: ValueKey('embedded-map-${uri.toString()}'),
      initialUrl: uri.toString(),
      title: uri.host,
      accentColor: tertiaryColor,
      backgroundColor: backgroundBottomColor,
      english: linguaInglese,
    );
  }

  Widget mapEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, color: primaryColor, size: 44),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget mapNotesPanel() {
    return gothicPanel(
      borderColor: tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, color: tertiaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Note mappa', 'Map notes'),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: mapNotesController,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: TextStyle(fontSize: uiScale(16), color: Colors.white),
            decoration: fieldDecoration(
              t(
                'Luoghi, pericoli, stanze, segreti',
                'Places, dangers, rooms, secrets',
              ),
            ),
            onChanged: (_) => programmaSalvataggio(),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ALLEGATI CAMPI LUNGHI
  // =====================================================

  String attachmentSlug(String value) {
    final clean = cleanUiText(value)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return clean.isEmpty ? 'campo' : clean;
  }

  String attachmentFieldIdForController(
    TextEditingController controller,
    String label,
  ) {
    if (identical(controller, backgroundController)) return 'story_background';
    if (identical(controller, notePersonaggioController)) {
      return 'story_character_notes';
    }
    if (identical(controller, skillDescrizioneController)) {
      return 'skill_editor_description';
    }
    if (identical(controller, titoloOttenimentoController)) {
      return 'title_editor_obtain';
    }
    if (identical(controller, titoloBuffController)) return 'title_editor_buff';
    if (identical(controller, titoloPuntoCiecoController)) {
      return 'title_editor_blindspot';
    }
    if (identical(controller, titoloSkillController)) {
      return 'title_editor_skill';
    }
    if (identical(controller, titoloRichiedeController)) {
      return 'title_editor_requirements';
    }
    if (identical(controller, titoloOpenDescriptionController)) {
      return 'title_open_description';
    }
    if (identical(controller, titoloOpenBuffController)) {
      return 'title_open_buff';
    }
    if (identical(controller, titoloOpenSkillController)) {
      return 'title_open_skill';
    }
    if (identical(controller, itemNoteController)) return 'item_editor_notes';
    if (identical(controller, itemBuffController)) return 'item_editor_buff';
    if (identical(controller, partyNoteController)) return 'party_editor_notes';
    if (identical(controller, masterSessionController)) {
      return 'master_session_notes';
    }
    if (identical(controller, masterInitiativeNotesController)) {
      return 'master_initiative_new_notes';
    }
    return 'field_${attachmentSlug(label)}';
  }

  String attachmentFieldIdFromKey(Key? key, String label) {
    final raw = key == null ? label : key.toString();
    return 'model_${attachmentSlug(raw)}';
  }

  List<Map<String, dynamic>> attachmentsForField(String fieldId) {
    return textAttachments.putIfAbsent(fieldId, () => <Map<String, dynamic>>[]);
  }

  void removeTextAttachment(String fieldId, int index) {
    final list = attachmentsForField(fieldId);
    if (index < 0 || index >= list.length) return;
    setState(() {
      list.removeAt(index);
      if (list.isEmpty) textAttachments.remove(fieldId);
      risultato = t('Allegato rimosso.', 'Attachment removed.');
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  Future<void> addAttachmentLink(String fieldId) async {
    final urlController = TextEditingController();
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF10121A),
        title: Text(
          t('Aggiungi link', 'Add link'),
          style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                keyboardType: TextInputType.url,
                style: const TextStyle(color: Colors.white),
                decoration: fieldDecoration('URL', helper: 'https://...'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: fieldDecoration(t('Titolo', 'Title')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: fieldDecoration(t('Note', 'Notes')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Annulla', 'Cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, {
              'url': urlController.text,
              'title': titleController.text,
              'notes': notesController.text,
            }),
            icon: const Icon(Icons.link),
            label: Text(t('Aggiungi', 'Add')),
          ),
        ],
      ),
    );
    urlController.dispose();
    titleController.dispose();
    notesController.dispose();
    if (result == null || !mounted) return;
    final rawUrl = result['url']?.trim() ?? '';
    final uri = Uri.tryParse(rawUrl);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      setState(() {
        risultato = t('Link non valido.', 'Invalid link.');
        aggiungiLog(risultato);
      });
      return;
    }
    setState(() {
      attachmentsForField(fieldId).add({
        'type': 'link',
        'url': uri.toString(),
        'title': cleanUiText(result['title'] ?? '').trim().isEmpty
            ? uri.host
            : cleanUiText(result['title'] ?? '').trim(),
        'notes': cleanUiText(result['notes'] ?? '').trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      risultato = t('Link allegato.', 'Link attached.');
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  Future<void> addAttachmentImage(String fieldId) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    var savedPath = '';
    var imageBase64 = '';
    if (kIsWeb) {
      final prepared = await prepareVttImportedImage(
        await picked.readAsBytes(),
        maxDimension: 1440,
        quality: 70,
      );
      imageBase64 = '${prepared['base64'] ?? ''}';
    } else {
      savedPath = await copyFileToOculumStorage(
        source: File(picked.path),
        directoryName: 'attachments',
        sourceName: picked.name.trim().isEmpty ? 'allegato.png' : picked.name,
      );
    }
    if (!mounted) return;
    setState(() {
      attachmentsForField(fieldId).add({
        'type': 'image',
        'path': savedPath,
        'imageBase64': imageBase64,
        'title': picked.name.trim().isEmpty
            ? t('Immagine', 'Image')
            : picked.name,
        'createdAt': DateTime.now().toIso8601String(),
      });
      risultato = t('Immagine allegata.', 'Image attached.');
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  Future<void> pasteAttachmentFromClipboard(String fieldId) async {
    try {
      final clipboardImage = await Pasteboard.image;
      if (!mounted) return;
      if (clipboardImage != null && clipboardImage.isNotEmpty) {
        var path = '';
        var imageBase64 = '';
        if (kIsWeb) {
          final prepared = await prepareVttImportedImage(
            clipboardImage,
            maxDimension: 1440,
            quality: 70,
          );
          imageBase64 = '${prepared['base64'] ?? ''}';
        } else {
          path = await saveBytesToOculumStorage(
            bytes: clipboardImage,
            directoryName: 'attachments',
            sourceName: 'allegato_appunti.png',
          );
        }
        if (!mounted) return;
        setState(() {
          attachmentsForField(fieldId).add({
            'type': 'image',
            'path': path,
            'imageBase64': imageBase64,
            'title': t('Immagine incollata', 'Pasted image'),
            'createdAt': DateTime.now().toIso8601String(),
          });
          risultato = t(
            'Immagine allegata dagli appunti.',
            'Pasted image attached.',
          );
          aggiungiLog(risultato);
        });
        programmaSalvataggio();
        return;
      }

      if (!kIsWeb) {
        final files = await Pasteboard.files();
        if (!mounted) return;
        for (final rawPath in files) {
          final path = rawPath.startsWith('file:')
              ? Uri.parse(rawPath).toFilePath()
              : rawPath;
          if (!fileLooksLikeImagePath(path)) continue;
          final source = File(path);
          if (!await source.exists()) continue;
          final name = source.uri.pathSegments.isEmpty
              ? 'allegato.png'
              : Uri.decodeComponent(source.uri.pathSegments.last);
          final savedPath = await copyFileToOculumStorage(
            source: source,
            directoryName: 'attachments',
            sourceName: name,
          );
          if (!mounted) return;
          setState(() {
            attachmentsForField(fieldId).add({
              'type': 'image',
              'path': savedPath,
              'title': name,
              'createdAt': DateTime.now().toIso8601String(),
            });
            risultato = t('File immagine allegato.', 'Image file attached.');
            aggiungiLog(risultato);
          });
          programmaSalvataggio();
          return;
        }
      }

      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      final text = data?.text ?? '';
      final match = RegExp(r'https?://[^\s]+').firstMatch(text);
      if (match != null) {
        final uri = Uri.tryParse(match.group(0)!);
        if (uri != null) {
          setState(() {
            attachmentsForField(fieldId).add({
              'type': 'link',
              'url': uri.toString(),
              'title': uri.host,
              'notes': '',
              'createdAt': DateTime.now().toIso8601String(),
            });
            risultato = t(
              'Link allegato dagli appunti.',
              'Clipboard link attached.',
            );
            aggiungiLog(risultato);
          });
          programmaSalvataggio();
          return;
        }
      }

      setState(() {
        risultato = t(
          'Nessun allegato valido negli appunti.',
          'No valid attachment in the clipboard.',
        );
        aggiungiLog(risultato);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        risultato = t(
          'Impossibile leggere gli appunti.',
          'Could not read the clipboard.',
        );
        aggiungiLog('$risultato ($error)');
      });
    }
  }

  Future<void> openTextAttachment(Map<String, dynamic> item) async {
    final type = '${item['type'] ?? ''}';
    if (type == 'link') {
      final uri = Uri.tryParse('${item['url'] ?? ''}');
      if (uri != null) {
        await openUriInOculumBrowser(
          uri,
          title: '${item['title'] ?? uri.host}',
        );
      }
      return;
    }

    final path = '${item['path'] ?? ''}';
    final embedded = '${item['imageBase64'] ?? ''}';
    final embeddedBytes = embedded.isEmpty
        ? null
        : decodedBase64ImageCached(embedded);
    final file = kIsWeb || path.isEmpty ? null : File(path);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF10121A),
        title: Text(
          '${item['title'] ?? t('Allegato', 'Attachment')}',
          style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780, maxHeight: 620),
          child: embeddedBytes != null
              ? InteractiveViewer(
                  child: Image.memory(embeddedBytes, fit: BoxFit.contain),
                )
              : file?.existsSync() == true
              ? InteractiveViewer(child: Image.file(file!, fit: BoxFit.contain))
              : Text(
                  t('File non trovato.', 'File not found.'),
                  style: const TextStyle(color: Colors.white),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Chiudi', 'Close')),
          ),
        ],
      ),
    );
  }

  Widget textAttachmentsPanel(String fieldId) {
    final list = attachmentsForField(fieldId);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, color: primaryColor, size: 17),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  list.isEmpty
                      ? t('Allegati testo', 'Text attachments')
                      : '${t('Allegati', 'Attachments')} ${list.length}',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Tooltip(
                message: t('Aggiungi immagine', 'Add image'),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => addAttachmentImage(fieldId),
                  icon: const Icon(Icons.image),
                  color: tertiaryColor,
                ),
              ),
              Tooltip(
                message: t('Aggiungi link', 'Add link'),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => addAttachmentLink(fieldId),
                  icon: const Icon(Icons.link),
                  color: tertiaryColor,
                ),
              ),
              Tooltip(
                message: t('Incolla allegato', 'Paste attachment'),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => pasteAttachmentFromClipboard(fieldId),
                  icon: const Icon(Icons.content_paste),
                  color: tertiaryColor,
                ),
              ),
            ],
          ),
          if (list.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (int i = 0; i < list.length; i++)
                  InputChip(
                    avatar: Icon(
                      '${list[i]['type'] ?? ''}' == 'link'
                          ? Icons.link
                          : Icons.image,
                      size: 16,
                    ),
                    label: Text(
                      '${list[i]['title'] ?? list[i]['url'] ?? t('Allegato', 'Attachment')}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    backgroundColor: secondaryColor.withValues(alpha: 0.75),
                    side: BorderSide(
                      color: tertiaryColor.withValues(alpha: 0.55),
                    ),
                    onPressed: () => openTextAttachment(list[i]),
                    onDeleted: () => removeTextAttachment(fieldId, i),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

void _paintOculumMoonPhase(
  Canvas canvas,
  Offset center,
  double radius,
  int phase,
  Paint outline,
  Paint litPaint,
  Paint shadowPaint,
) {
  final oval = Rect.fromCircle(center: center, radius: radius);
  final clip = Path()..addOval(oval);
  canvas.drawCircle(center, radius, shadowPaint);

  canvas.save();
  canvas.clipPath(clip);
  switch (phase % 8) {
    case 0:
      break;
    case 1:
      canvas.drawCircle(center, radius, litPaint);
      canvas.drawCircle(
        center.translate(-radius * 0.48, 0),
        radius * 0.98,
        shadowPaint,
      );
      break;
    case 2:
      canvas.drawRect(
        Rect.fromLTWH(center.dx, center.dy - radius, radius, radius * 2),
        litPaint,
      );
      break;
    case 3:
      canvas.drawCircle(center, radius, litPaint);
      canvas.drawCircle(
        center.translate(-radius * 0.72, 0),
        radius * 0.96,
        shadowPaint,
      );
      break;
    case 4:
      canvas.drawCircle(center, radius, litPaint);
      break;
    case 5:
      canvas.drawCircle(center, radius, litPaint);
      canvas.drawCircle(
        center.translate(radius * 0.72, 0),
        radius * 0.96,
        shadowPaint,
      );
      break;
    case 6:
      canvas.drawRect(
        Rect.fromLTWH(
          center.dx - radius,
          center.dy - radius,
          radius,
          radius * 2,
        ),
        litPaint,
      );
      break;
    default:
      canvas.drawCircle(center, radius, litPaint);
      canvas.drawCircle(
        center.translate(radius * 0.48, 0),
        radius * 0.98,
        shadowPaint,
      );
  }
  canvas.restore();

  canvas.drawCircle(center, radius, outline);
  if (phase == 2 || phase == 6) {
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      outline,
    );
  }
}

void _paintOculumMoonPhaseRow(
  Canvas canvas,
  double startX,
  double endX,
  double y,
  double radius,
  Paint outline,
  Paint litPaint,
  Paint shadowPaint,
) {
  if (endX <= startX) return;
  final spacing = (endX - startX) / 7;
  final phaseRadius = min(radius, max(2.4, spacing * 0.34));
  for (var i = 0; i < 8; i++) {
    _paintOculumMoonPhase(
      canvas,
      Offset(startX + spacing * i, y),
      phaseRadius,
      i,
      outline,
      litPaint,
      shadowPaint,
    );
  }
}

class _OculumThemeSectionTitlePainter extends CustomPainter {
  const _OculumThemeSectionTitlePainter({
    required this.spec,
    required this.compact,
    required this.desktop,
    required this.labelHash,
  });

  final OculumThemeDecorationSpec spec;
  final bool compact;
  final bool desktop;
  final int labelHash;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || spec.opacity <= 0 || spec.style == 'none') return;
    final detailBoost = desktop ? 1.14 : 0.86;
    final alpha = (spec.opacity * (compact ? 0.82 : 1.16) * detailBoost)
        .clamp(0.040, compact ? 0.15 : (desktop ? 0.34 : 0.24))
        .toDouble();
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 0.75 : (desktop ? 1.25 : 0.95)
      ..shader = _oculumReverseBackgroundShader(
        spec,
        size,
        spec.primary,
        alpha,
      );
    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 0.70 : (desktop ? 1.12 : 0.88)
      ..shader = _oculumReverseBackgroundShader(
        spec,
        size,
        spec.accent,
        alpha * 1.08,
      );
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..shader = _oculumReverseBackgroundShader(
        spec,
        size,
        spec.secondary,
        alpha * 0.78,
      );
    final softFill = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.accent.withValues(alpha: alpha * 0.28);

    canvas.drawLine(
      Offset(size.width * 0.18, size.height - 2),
      Offset(size.width - 18, size.height - 2),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.46, 2),
      Offset(size.width - 12, 2),
      accent,
    );

    switch (spec.style) {
      case 'lunar':
        _paintLunarHeader(canvas, size, stroke, accent, fill);
        break;
      case 'cathedral':
        _paintCathedralHeader(canvas, size, stroke, accent, fill);
        break;
      case 'thorn':
        _paintThornHeader(canvas, size, stroke, accent, fill);
        break;
      case 'vervain':
        _paintVervainHeader(canvas, size, stroke, accent, fill);
        break;
      case 'kingi':
        _paintKingiHeader(canvas, size, stroke, accent, fill);
        break;
      case 'postea':
        _paintPosteaHeader(canvas, size, stroke, accent, fill);
        break;
      case 'medieval':
        _paintMedievalHeader(canvas, size, stroke, accent, fill);
        break;
      case 'phobia':
        _paintPhobiaHeader(canvas, size, stroke, accent, fill);
        break;
      case 'shadow_gate':
        _paintShadowGateHeader(canvas, size, stroke, accent, fill);
        break;
      case 'sigil':
        _paintSigilHeader(canvas, size, stroke, accent, fill);
        break;
      case 'frost':
        _paintFrostHeader(canvas, size, stroke, accent);
        break;
      case 'storm':
        _paintStormHeader(canvas, size, stroke, accent);
        break;
      case 'tide':
        _paintTideHeader(canvas, size, stroke, accent, fill);
        break;
      case 'ember':
        _paintEmberHeader(canvas, size, stroke, accent, fill);
        break;
      case 'archive':
        _paintArchiveHeader(canvas, size, stroke, accent, fill);
        break;
      case 'slime':
        _paintSlimeHeader(canvas, size, stroke, accent, fill);
        break;
      case 'obser':
        _paintObserHeader(canvas, size, stroke, accent, fill);
        break;
      case 'hoshy':
        _paintHoshyHeader(canvas, size, stroke, accent, fill, softFill);
        break;
      default:
        _paintReliquaryHeader(canvas, size, stroke, accent, fill);
    }
  }

  double get _rightStartFactor => compact ? 0.62 : 0.52;

  void _star(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawLine(
      center.translate(-radius, 0),
      center.translate(radius, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(0, -radius),
      center.translate(0, radius),
      paint,
    );
    canvas.drawLine(
      center.translate(-radius * 0.48, -radius * 0.48),
      center.translate(radius * 0.48, radius * 0.48),
      paint,
    );
    canvas.drawLine(
      center.translate(-radius * 0.48, radius * 0.48),
      center.translate(radius * 0.48, -radius * 0.48),
      paint,
    );
  }

  void _diamond(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * 0.72, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius * 0.72, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _moon(
    Canvas canvas,
    Offset center,
    double radius,
    int phase,
    Paint stroke,
    Paint fill,
  ) {
    canvas.drawCircle(center, radius, stroke);
    final offset = (phase - 3.5) / 3.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(offset * radius * 0.52, 0),
        width: radius * (1.10 + offset.abs() * 0.34),
        height: radius * 1.85,
      ),
      fill,
    );
  }

  void _leaf(
    Canvas canvas,
    Offset base,
    double dir,
    double scale,
    Paint fill,
    Paint stroke,
  ) {
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
        base.dx + dir * scale * 0.34,
        base.dy - scale * 0.48,
        base.dx + dir * scale * 0.82,
        base.dy - scale * 0.22,
        base.dx + dir * scale,
        base.dy,
      )
      ..cubicTo(
        base.dx + dir * scale * 0.70,
        base.dy + scale * 0.38,
        base.dx + dir * scale * 0.26,
        base.dy + scale * 0.28,
        base.dx,
        base.dy,
      )
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawLine(
      base.translate(dir * 3, 0),
      base.translate(dir * scale, 0),
      stroke,
    );
  }

  void _flower(
    Canvas canvas,
    Offset center,
    double radius,
    Paint fill,
    Paint accent,
  ) {
    for (var i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      final petalCenter = center.translate(
        cos(angle) * radius * 0.64,
        sin(angle) * radius * 0.42,
      );
      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 0.95,
          height: radius * 0.42,
        ),
        i.isEven ? fill : accent,
      );
      canvas.restore();
    }
    canvas.drawCircle(center, radius * 0.18, accent);
  }

  void _eye(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    final path = Path()
      ..moveTo(center.dx - width / 2, center.dy)
      ..quadraticBezierTo(
        center.dx,
        center.dy - height,
        center.dx + width / 2,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + height,
        center.dx - width / 2,
        center.dy,
      );
    canvas.drawPath(path, stroke);
    canvas.drawCircle(center, min(width, height * 2) * 0.20, fill);
    canvas.drawCircle(center, min(width, height * 2) * 0.07, accent);
  }

  void _bolt(
    Canvas canvas,
    Offset base,
    double scale,
    double dir,
    Paint paint,
  ) {
    final path = Path()
      ..moveTo(base.dx, base.dy - scale)
      ..lineTo(base.dx + dir * scale * 0.42, base.dy - scale * 0.12)
      ..lineTo(base.dx + dir * scale * 0.16, base.dy - scale * 0.12)
      ..lineTo(base.dx + dir * scale * 0.56, base.dy + scale)
      ..lineTo(base.dx + dir * scale * 0.24, base.dy + scale * 0.22)
      ..lineTo(base.dx + dir * scale * 0.46, base.dy + scale * 0.22);
    canvas.drawPath(path, paint);
  }

  void _paintLunarHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    final start = size.width * _rightStartFactor;
    final width = max(92.0, size.width - start - 14);
    final count = compact ? 5 : 8;
    for (var i = 0; i < count; i++) {
      final x = start + width * i / max(1, count - 1);
      _moon(
        canvas,
        Offset(x, size.height * 0.50),
        compact ? 6.0 : 8.0,
        i,
        accent,
        fill,
      );
    }
    for (var i = 0; i < 4; i++) {
      _star(
        canvas,
        Offset(start - 34 - i * 22, 12 + (i % 2) * 10),
        3.4,
        stroke,
      );
    }
  }

  void _paintCathedralHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    final rose = Offset(size.width - (compact ? 34 : 46), size.height * 0.50);
    canvas.drawCircle(rose, compact ? 13 : 18, stroke);
    canvas.drawCircle(rose, compact ? 6 : 8, fill);
    for (var i = 0; i < 10; i++) {
      final angle = i * pi / 5;
      canvas.drawLine(
        rose,
        rose.translate(
          cos(angle) * (compact ? 13 : 18),
          sin(angle) * (compact ? 13 : 18),
        ),
        i.isEven ? accent : stroke,
      );
    }
    for (var x = size.width * _rightStartFactor; x < size.width - 78; x += 32) {
      canvas.drawLine(Offset(x, 5), Offset(x + 14, size.height - 6), accent);
    }
  }

  void _paintThornHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    final y = size.height * 0.55;
    final vine = Path()..moveTo(size.width * _rightStartFactor, y);
    for (var x = size.width * _rightStartFactor; x < size.width - 12; x += 42) {
      vine.cubicTo(x + 12, y - 18, x + 28, y + 14, x + 42, y);
    }
    canvas.drawPath(vine, stroke);
    for (var i = 0; i < 8; i++) {
      final x = size.width - 22 - i * 28;
      final base = Offset(x, y + (i.isEven ? -3 : 5));
      canvas.drawLine(base, base.translate(i.isEven ? -18 : 16, -13), accent);
      if (i % 3 == 0) {
        _leaf(canvas, base.translate(-10, 4), -1, 18, fill, stroke);
      }
    }
  }

  void _paintVervainHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    _paintThornHeader(canvas, size, stroke, accent, fill);
    for (var i = 0; i < (compact ? 3 : 5); i++) {
      _flower(
        canvas,
        Offset(size.width - 28 - i * 42, size.height * (0.42 + (i % 2) * 0.18)),
        compact ? 7 : 9,
        fill,
        accent,
      );
    }
  }

  void _paintKingiHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && !compact && size.width >= 260;
    final electric = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1.05 : (detailed ? 1.85 : 1.35)
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF16C8FF).withValues(
        alpha: (spec.opacity * (detailed ? 1.70 : 1.10))
            .clamp(0.08, detailed ? 0.36 : 0.22)
            .toDouble(),
      );
    final start = size.width * _rightStartFactor;
    for (var x = start; x < size.width - 18; x += detailed ? 30 : 46) {
      final rect = Rect.fromCenter(
        center: Offset(x + 14, size.height * 0.52),
        width: detailed ? 34 : 24,
        height: compact ? 13 : (detailed ? 22 : 17),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        x.toInt().isEven ? stroke : accent,
      );
      canvas.drawCircle(rect.topLeft.translate(5, 5), 2.5, fill);
      canvas.drawLine(
        rect.centerLeft.translate(5, 0),
        rect.centerRight.translate(-5, 0),
        electric,
      );
    }
    for (var i = 0; i < (detailed ? 6 : 3); i++) {
      _bolt(
        canvas,
        Offset(size.width - 28 - i * (detailed ? 34 : 42), size.height * 0.48),
        compact ? 12 : (detailed ? 19 : 15),
        -1,
        i.isEven ? electric : accent,
      );
    }
    for (var i = 0; i < (detailed ? 4 : 2); i++) {
      final c = Offset(
        size.width - 38 - i * (detailed ? 44 : 56),
        size.height * 0.50,
      );
      _diamond(canvas, c, compact ? 5.5 : 7.5, fill);
      canvas.drawCircle(c, compact ? 9 : (detailed ? 13 : 10), electric);
    }
  }

  void _paintPhobiaHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    _eye(
      canvas,
      Offset(size.width - (compact ? 42 : 58), size.height * 0.52),
      compact ? 62 : 88,
      compact ? 14 : 18,
      stroke,
      accent,
      fill,
    );
    for (var i = 0; i < 7; i++) {
      final x = size.width * _rightStartFactor + i * 28;
      final claw = Path()
        ..moveTo(x, 5)
        ..quadraticBezierTo(x + 15, size.height * 0.42, x + 5, size.height - 5)
        ..quadraticBezierTo(x + 22, size.height * 0.54, x + 22, 8);
      canvas.drawPath(claw, i.isEven ? accent : stroke);
    }
  }

  void _paintPosteaHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    final start = size.width * _rightStartFactor;
    final railY = size.height * 0.52;
    for (var x = start; x < size.width - 20; x += compact ? 34 : 42) {
      final node = Offset(x, railY + ((x ~/ 40).isEven ? -7 : 7));
      canvas.drawLine(node.translate(-16, 0), node.translate(16, 0), accent);
      canvas.drawLine(node, node.translate(0, compact ? 12 : 17), stroke);
      _diamond(canvas, node, compact ? 4.5 : 6.0, fill);
    }
    for (var i = 0; i < (compact ? 3 : 5); i++) {
      final c = Offset(size.width - 24 - i * 40, size.height * 0.35);
      canvas.drawArc(
        Rect.fromCenter(center: c, width: compact ? 22 : 30, height: 18),
        pi * 0.08,
        pi * 1.45,
        false,
        i.isEven ? stroke : accent,
      );
    }
  }

  void _paintMedievalHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    final start = size.width * _rightStartFactor;
    final baseY = size.height * 0.72;
    for (var x = start; x < size.width - 16; x += compact ? 24 : 30) {
      final brick = Rect.fromLTWH(x, baseY - 14, compact ? 17 : 22, 11);
      canvas.drawRRect(
        RRect.fromRectAndRadius(brick, const Radius.circular(2)),
        (x ~/ 10).isEven ? stroke : accent,
      );
    }
    for (var i = 0; i < (compact ? 3 : 4); i++) {
      final c = Offset(size.width - 28 - i * 38, size.height * 0.43);
      final shield = Path()
        ..moveTo(c.dx, c.dy - 15)
        ..lineTo(c.dx + 13, c.dy - 7)
        ..quadraticBezierTo(c.dx + 9, c.dy + 16, c.dx, c.dy + 23)
        ..quadraticBezierTo(c.dx - 9, c.dy + 16, c.dx - 13, c.dy - 7)
        ..close();
      canvas.drawPath(shield, i.isEven ? fill : stroke);
      canvas.drawPath(shield, accent);
      canvas.drawLine(c.translate(0, -10), c.translate(0, 14), stroke);
      canvas.drawLine(c.translate(-8, -1), c.translate(8, -1), accent);
    }
    for (var i = 0; i < (compact ? 2 : 3); i++) {
      final x = size.width - 22 - i * 54;
      canvas.drawLine(Offset(x, 7), Offset(x - 28, size.height - 7), stroke);
      canvas.drawLine(Offset(x - 12, 16), Offset(x + 10, 31), accent);
      _diamond(canvas, Offset(x - 28, size.height - 7), 4.5, fill);
    }
  }

  void _paintShadowGateHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    final gate = Offset(size.width - (compact ? 38 : 56), size.height * 0.52);
    canvas.drawArc(
      Rect.fromCenter(
        center: gate,
        width: compact ? 48 : 70,
        height: compact ? 38 : 54,
      ),
      -pi * 0.12,
      pi * 1.24,
      false,
      accent,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: gate,
        width: compact ? 28 : 44,
        height: compact ? 24 : 38,
      ),
      pi * 0.20,
      pi * 1.18,
      false,
      stroke,
    );
    _diamond(canvas, gate, compact ? 5 : 8, fill);
    for (var i = 0; i < (compact ? 4 : 7); i++) {
      final x = size.width * _rightStartFactor + i * 28;
      canvas.drawLine(Offset(x, 8), Offset(x + 14, size.height - 8), accent);
      canvas.drawLine(Offset(x + 14, 8), Offset(x, size.height - 8), stroke);
    }
  }

  void _paintSigilHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    for (var i = 0; i < (compact ? 4 : 6); i++) {
      final c = Offset(size.width - 24 - i * 34, size.height * 0.50);
      canvas.drawCircle(c, compact ? 9 : 12, i.isEven ? stroke : accent);
      _diamond(canvas, c, compact ? 5 : 7, i.isEven ? accent : fill);
    }
  }

  void _paintFrostHeader(Canvas canvas, Size size, Paint stroke, Paint accent) {
    for (var i = 0; i < (compact ? 5 : 8); i++) {
      final c = Offset(size.width - 20 - i * 32, size.height * 0.50);
      final r = compact ? 9.0 : 12.0;
      canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), stroke);
      canvas.drawLine(c.translate(0, -r), c.translate(0, r), accent);
      canvas.drawLine(
        c.translate(-r * .7, -r * .7),
        c.translate(r * .7, r * .7),
        stroke,
      );
      canvas.drawLine(
        c.translate(-r * .7, r * .7),
        c.translate(r * .7, -r * .7),
        accent,
      );
    }
  }

  void _paintStormHeader(Canvas canvas, Size size, Paint stroke, Paint accent) {
    for (var i = 0; i < (compact ? 4 : 6); i++) {
      _bolt(
        canvas,
        Offset(size.width - 28 - i * 42, size.height * 0.45),
        compact ? 13 : 18,
        -1,
        i.isEven ? accent : stroke,
      );
    }
    for (var i = 0; i < 10; i++) {
      final x = size.width * _rightStartFactor + i * 28;
      canvas.drawLine(Offset(x, 6), Offset(x + 7, size.height - 5), stroke);
    }
  }

  void _paintTideHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    for (var row = 0; row < 2; row++) {
      final y = size.height * (0.48 + row * 0.22);
      final wave = Path()..moveTo(size.width * _rightStartFactor, y);
      for (
        var x = size.width * _rightStartFactor;
        x < size.width + 30;
        x += 34
      ) {
        wave.quadraticBezierTo(x + 17, y - 13, x + 34, y);
      }
      canvas.drawPath(wave, row.isEven ? accent : stroke);
    }
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width - 24 - i * 36, size.height * 0.30),
        3.5 + i % 2,
        fill,
      );
    }
  }

  void _paintEmberHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    for (var i = 0; i < (compact ? 4 : 6); i++) {
      final base = Offset(size.width - 24 - i * 35, size.height - 7);
      canvas.drawRect(
        Rect.fromCenter(center: base, width: 7, height: 18),
        stroke,
      );
      final flame = Path()
        ..moveTo(base.dx, base.dy - 28)
        ..quadraticBezierTo(base.dx + 10, base.dy - 12, base.dx, base.dy - 4)
        ..quadraticBezierTo(base.dx - 8, base.dy - 13, base.dx, base.dy - 28)
        ..close();
      canvas.drawPath(flame, i.isEven ? accent : fill);
    }
  }

  void _paintArchiveHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    for (var i = 0; i < 5; i++) {
      final y = 9 + i * (compact ? 6.0 : 8.0);
      canvas.drawLine(
        Offset(size.width * _rightStartFactor, y),
        Offset(size.width - 18, y),
        i.isEven ? stroke : accent,
      );
    }
    for (var i = 0; i < 5; i++) {
      final c = Offset(size.width - 28 - i * 34, size.height - 12);
      canvas.drawLine(c.translate(0, -10), c.translate(0, 10), stroke);
      canvas.drawLine(c, c.translate(-10, -8), accent);
      if (i.isEven) {
        _diamond(canvas, c.translate(0, -14), 4.5, fill);
      }
    }
  }

  void _paintSlimeHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    final drip = Path()..moveTo(size.width * _rightStartFactor, 7);
    for (var x = size.width * _rightStartFactor; x < size.width + 28; x += 28) {
      drip.quadraticBezierTo(
        x + 13,
        22 + ((x ~/ 28).isEven ? 10 : 0),
        x + 28,
        7,
      );
    }
    canvas.drawPath(drip, fill);
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(size.width - 22 - i * 34, size.height - 13),
        5 + i % 2,
        i.isEven ? accent : stroke,
      );
    }
  }

  void _paintObserHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    for (var i = 0; i < (compact ? 3 : 5); i++) {
      _eye(
        canvas,
        Offset(size.width - 26 - i * 42, size.height * 0.50),
        compact ? 34 : 42,
        compact ? 8 : 10,
        i.isEven ? stroke : accent,
        accent,
        fill,
      );
    }
  }

  void _paintHoshyHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
    Paint softFill,
  ) {
    final moon = Offset(size.width - (compact ? 42 : 55), size.height * 0.48);
    canvas.drawCircle(moon, compact ? 13 : 17, stroke);
    canvas.drawCircle(moon.translate(6, -1), compact ? 12 : 16, fill);
    final ear = compact ? 22.0 : 30.0;
    for (final dir in <double>[-1, 1]) {
      final baseX = moon.dx + dir * (ear * 1.05);
      final path = Path()
        ..moveTo(baseX - dir * ear * 0.46, size.height - 5)
        ..lineTo(baseX, 6)
        ..lineTo(baseX + dir * ear * 0.46, size.height - 5);
      canvas.drawPath(path, dir < 0 ? accent : stroke);
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.72, size.height * 0.50),
        width: compact ? 82 : 132,
        height: compact ? 26 : 36,
      ),
      softFill,
    );
    for (var i = 0; i < 7; i++) {
      _star(
        canvas,
        Offset(size.width * 0.55 + i * 31, 10 + (i % 2) * 14),
        3.6,
        i.isEven ? accent : stroke,
      );
    }
  }

  void _paintReliquaryHeader(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill,
  ) {
    final c = Offset(size.width - 36, size.height * 0.50);
    canvas.drawArc(
      Rect.fromCenter(
        center: c,
        width: compact ? 32 : 44,
        height: compact ? 32 : 44,
      ),
      -pi / 2,
      pi * 1.65,
      false,
      stroke,
    );
    _diamond(canvas, c, compact ? 7 : 9, accent);
    for (var i = 0; i < 4; i++) {
      _diamond(
        canvas,
        Offset(size.width - 82 - i * 34, size.height * 0.50),
        4.5,
        i.isEven ? fill : stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OculumThemeSectionTitlePainter oldDelegate) {
    return oldDelegate.spec.presetId != spec.presetId ||
        oldDelegate.spec.style != spec.style ||
        oldDelegate.spec.primary != spec.primary ||
        oldDelegate.spec.secondary != spec.secondary ||
        oldDelegate.spec.accent != spec.accent ||
        oldDelegate.spec.backgroundTop != spec.backgroundTop ||
        oldDelegate.spec.backgroundMid != spec.backgroundMid ||
        oldDelegate.spec.backgroundBottom != spec.backgroundBottom ||
        oldDelegate.spec.opacity != spec.opacity ||
        oldDelegate.spec.usesBaseColors != spec.usesBaseColors ||
        oldDelegate.compact != compact ||
        oldDelegate.desktop != desktop ||
        oldDelegate.labelHash != labelHash;
  }
}

class _OculumThemePanelDecorationPainter extends CustomPainter {
  _OculumThemePanelDecorationPainter(
    this.spec,
    this.borderColor,
    this.light, {
    required this.desktop,
  });

  final OculumThemeDecorationSpec spec;
  final Color borderColor;
  final bool light;
  final bool desktop;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || spec.style == 'none' || spec.opacity <= 0) return;
    final detailed = desktop && !light;
    final opacity = (spec.opacity * (light ? 1.02 : (detailed ? 1.72 : 1.30)))
        .clamp(light ? 0.075 : 0.12, detailed ? 0.58 : 0.36)
        .toDouble();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = light ? 0.8 : (detailed ? 1.32 : 1.02)
      ..color = spec.primary.withValues(alpha: opacity)
      ..shader = _oculumReverseBackgroundShader(
        spec,
        size,
        spec.primary,
        opacity,
      );
    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = light ? 0.75 : (detailed ? 1.18 : 0.96)
      ..color = spec.accent.withValues(alpha: opacity * 0.92)
      ..shader = _oculumReverseBackgroundShader(
        spec,
        size,
        spec.accent,
        opacity * 0.96,
      );
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.secondary.withValues(alpha: opacity * 0.45)
      ..shader = _oculumReverseBackgroundShader(
        spec,
        size,
        spec.secondary,
        opacity * 0.52,
      );
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = detailed ? 1.15 : 0.9
      ..color = borderColor.withValues(alpha: opacity * 0.9)
      ..shader = _oculumReverseBackgroundShader(
        spec,
        size,
        borderColor,
        opacity * 0.90,
      );

    _paintPanelCorners(canvas, size, border, accent);

    switch (spec.style) {
      case 'lunar':
        _paintPanelLunar(canvas, size, paint, accent, fill);
        break;
      case 'cathedral':
        _paintPanelCathedral(canvas, size, paint, accent);
        break;
      case 'thorn':
        _paintPanelThorn(canvas, size, paint, accent);
        break;
      case 'vervain':
        _paintPanelVervain(canvas, size, paint, accent, fill);
        break;
      case 'kingi':
        _paintPanelKingi(canvas, size, paint, accent, fill);
        break;
      case 'postea':
        _paintPanelPostea(canvas, size, paint, accent, fill);
        break;
      case 'medieval':
        _paintPanelMedieval(canvas, size, paint, accent, fill);
        break;
      case 'phobia':
        _paintPanelPhobia(canvas, size, paint, accent, fill);
        break;
      case 'shadow_gate':
        _paintPanelShadowGate(canvas, size, paint, accent, fill);
        break;
      case 'sigil':
        _paintPanelSigil(canvas, size, paint, accent);
        break;
      case 'frost':
        _paintPanelFrost(canvas, size, paint, accent);
        break;
      case 'storm':
        _paintPanelStorm(canvas, size, paint, accent);
        break;
      case 'tide':
        _paintPanelTide(canvas, size, paint, accent, fill);
        break;
      case 'ember':
        _paintPanelEmber(canvas, size, paint, accent, fill);
        break;
      case 'archive':
        _paintPanelArchive(canvas, size, paint, accent, fill);
        break;
      case 'slime':
        _paintPanelSlime(canvas, size, paint, accent, fill);
        break;
      case 'obser':
        _paintPanelObser(canvas, size, paint, accent, fill);
        break;
      case 'hoshy':
        _paintPanelHoshy(canvas, size, paint, accent, fill);
        break;
      default:
        _paintPanelReliquary(canvas, size, paint, accent);
    }
    _paintPanelSceneAnchor(canvas, size, paint, accent, fill);
    if (detailed) {
      _paintPanelDesktopMicroDetails(canvas, size, paint, accent, fill);
    }
  }

  void _paintPanelSceneAnchor(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    if (size.width < 160 || size.height < 70) return;
    switch (spec.style) {
      case 'vervain':
        _paintPanelSceneVervain(canvas, size, paint, accent, fill);
        break;
      case 'kingi':
        _paintPanelSceneKingi(canvas, size, paint, accent, fill);
        break;
      case 'postea':
        _paintPanelScenePostea(canvas, size, paint, accent, fill);
        break;
      case 'medieval':
        _paintPanelSceneMedieval(canvas, size, paint, accent, fill);
        break;
      case 'phobia':
        _paintPanelScenePhobia(canvas, size, paint, accent, fill);
        break;
      case 'shadow_gate':
        _paintPanelSceneShadowGate(canvas, size, paint, accent, fill);
        break;
      case 'lunar':
        _paintPanelSceneLunar(canvas, size, paint, accent, fill);
        break;
      case 'cathedral':
        _paintPanelSceneCathedral(canvas, size, paint, accent, fill);
        break;
      case 'thorn':
        _paintPanelSceneThorn(canvas, size, paint, accent, fill);
        break;
      case 'storm':
        _paintPanelSceneStorm(canvas, size, paint, accent);
        break;
      case 'tide':
        _paintPanelSceneTide(canvas, size, paint, accent, fill);
        break;
      case 'ember':
        _paintPanelSceneEmber(canvas, size, paint, accent, fill);
        break;
      case 'archive':
        _paintPanelSceneArchive(canvas, size, paint, accent, fill);
        break;
      case 'hoshy':
        _paintPanelSceneHoshy(canvas, size, paint, accent, fill);
        break;
      case 'slime':
        _paintPanelSceneSlime(canvas, size, paint, accent, fill);
        break;
      case 'obser':
      case 'sigil':
        _paintPanelSceneSigil(canvas, size, paint, accent, fill);
        break;
      case 'frost':
        _paintPanelSceneFrost(canvas, size, paint, accent);
        break;
      default:
        _paintPanelSceneReliquary(canvas, size, paint, accent, fill);
    }
  }

  void _paintPanelDesktopMicroDetails(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    if (size.width < 220 || size.height < 88) return;
    final alphaBoost = spec.usesBaseColors ? 0.78 : 1.0;
    final fine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 0.72
      ..color = spec.primary.withValues(
        alpha: (spec.opacity * alphaBoost).clamp(0.06, 0.20).toDouble(),
      );
    final bright = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 0.82
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * 0.86 * alphaBoost).clamp(0.06, 0.22).toDouble(),
      );
    final mote = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.secondary.withValues(
        alpha: (spec.opacity * 0.36).clamp(0.03, 0.11).toDouble(),
      );

    final top = Path()..moveTo(28, 12);
    for (var x = 28.0; x < size.width - 28; x += 56) {
      top.cubicTo(x + 14, 4, x + 40, 22, x + 56, 12);
    }
    canvas.drawPath(top, fine);
    final bottom = Path()..moveTo(28, size.height - 12);
    for (var x = 28.0; x < size.width - 28; x += 56) {
      bottom.cubicTo(
        x + 14,
        size.height - 22,
        x + 40,
        size.height - 4,
        x + 56,
        size.height - 12,
      );
    }
    canvas.drawPath(bottom, bright);

    for (var i = 0; i < 5; i++) {
      final c = Offset(34 + i * 42.0, size.height - 28 - (i % 2) * 7);
      switch (spec.style) {
        case 'phobia':
          canvas.drawLine(c.translate(-8, -12), c.translate(8, 12), fine);
          canvas.drawLine(c.translate(7, -10), c.translate(-6, 8), bright);
          break;
        case 'kingi':
          canvas.drawCircle(c, 5, bright);
          canvas.drawLine(c.translate(-14, 0), c.translate(14, 0), fine);
          break;
        case 'postea':
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: c, width: 16, height: 9),
              const Radius.circular(3),
            ),
            bright,
          );
          canvas.drawLine(c.translate(-18, 0), c.translate(18, 0), fine);
          break;
        case 'medieval':
          final shield = Path()
            ..moveTo(c.dx, c.dy - 8)
            ..lineTo(c.dx + 8, c.dy - 3)
            ..quadraticBezierTo(c.dx + 5, c.dy + 8, c.dx, c.dy + 12)
            ..quadraticBezierTo(c.dx - 5, c.dy + 8, c.dx - 8, c.dy - 3)
            ..close();
          canvas.drawPath(shield, i.isEven ? bright : fine);
          canvas.drawLine(c.translate(-12, -10), c.translate(12, 10), fine);
          break;
        case 'shadow_gate':
          canvas.drawArc(
            Rect.fromCenter(center: c, width: 20, height: 24),
            -pi * 0.15,
            pi * 1.30,
            false,
            bright,
          );
          _diamond(canvas, c, 4.5, fine);
          break;
        case 'vervain':
        case 'thorn':
          final leaf = Path()
            ..moveTo(c.dx - 8, c.dy)
            ..quadraticBezierTo(c.dx, c.dy - 13, c.dx + 13, c.dy - 2)
            ..quadraticBezierTo(c.dx + 1, c.dy + 10, c.dx - 8, c.dy);
          canvas.drawPath(leaf, i.isEven ? bright : fine);
          break;
        default:
          _diamond(canvas, c, 5.5, i.isEven ? bright : fine);
      }
    }

    final moteWidth = max(1, (size.width - 54).round());
    final moteHeight = max(1, (size.height - 50).round());
    for (var i = 0; i < 8; i++) {
      final x = 27.0 + (i * 67 % moteWidth).toDouble();
      final y = 24.0 + (i * 31 % moteHeight).toDouble();
      canvas.drawCircle(Offset(x, y), 1.1 + (i % 2) * 0.5, mote);
    }
  }

  void _paintMiniGear(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final gear = Path();
    for (var i = 0; i < 16; i++) {
      final angle = -pi / 2 + i * pi / 8;
      final r = i.isEven ? radius : radius * 0.78;
      final point = center.translate(cos(angle) * r, sin(angle) * r);
      if (i == 0) {
        gear.moveTo(point.dx, point.dy);
      } else {
        gear.lineTo(point.dx, point.dy);
      }
    }
    gear.close();
    canvas.drawPath(gear, fill);
    canvas.drawPath(gear, paint);
    canvas.drawCircle(center, radius * 0.42, accent);
    canvas.drawCircle(center, radius * 0.18, fill);
  }

  void _paintSceneFlower(
    Canvas canvas,
    Offset center,
    double radius,
    Paint fill,
    Paint accent,
    Paint line,
  ) {
    for (var i = 0; i < 7; i++) {
      final angle = i * pi * 2 / 7;
      final petalCenter = center.translate(
        cos(angle) * radius * 0.62,
        sin(angle) * radius * 0.44,
      );
      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 0.88,
          height: radius * 0.38,
        ),
        i.isEven ? fill : accent,
      );
      canvas.restore();
    }
    canvas.drawCircle(center, radius * 0.16, line);
  }

  void _paintSceneLeaf(
    Canvas canvas,
    Offset base,
    double dir,
    double scale,
    Paint fill,
    Paint line,
  ) {
    final leaf = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
        base.dx + dir * scale * 0.32,
        base.dy - scale * 0.50,
        base.dx + dir * scale * 0.86,
        base.dy - scale * 0.25,
        base.dx + dir * scale,
        base.dy,
      )
      ..cubicTo(
        base.dx + dir * scale * 0.72,
        base.dy + scale * 0.38,
        base.dx + dir * scale * 0.24,
        base.dy + scale * 0.30,
        base.dx,
        base.dy,
      )
      ..close();
    canvas.drawPath(leaf, fill);
    canvas.drawLine(
      base.translate(dir * 3, 0),
      base.translate(dir * scale * 0.92, 0),
      line,
    );
  }

  void _paintPanelSceneVervain(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final dir = -1.0;
    final root = Offset(size.width - 12, size.height - 14);
    final vine = Path()..moveTo(root.dx, root.dy);
    for (var i = 0; i < 5; i++) {
      final x = size.width - 22 - i * min(42.0, size.width * 0.11);
      final y = size.height - 18 - (i.isEven ? 20 : 5);
      vine.cubicTo(x + 20, y + 16, x - 16, y - 20, x - 38, y - 2);
    }
    canvas.drawPath(vine, paint);
    for (var i = 0; i < 6; i++) {
      final base = Offset(
        size.width - 26 - i * min(34.0, size.width * 0.09),
        size.height - 24 - (i % 2) * 15,
      );
      _paintSceneLeaf(canvas, base, dir, 22 + (i % 3) * 5, fill, accent);
      canvas.drawLine(base, base.translate(-16, -16 - (i % 2) * 4), accent);
      if (i.isEven) {
        _paintSceneFlower(
          canvas,
          base.translate(-18, -18),
          8.5,
          fill,
          accent,
          paint,
        );
      }
    }
    _paintSceneFlower(
      canvas,
      Offset(size.width - 36, 30),
      11,
      fill,
      accent,
      paint,
    );
  }

  void _paintPanelSceneKingi(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && !light && size.width >= 280;
    final electric = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = detailed ? 1.7 : 1.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF16C8FF).withValues(
        alpha: (spec.opacity * (detailed ? 1.62 : 1.04))
            .clamp(0.09, detailed ? 0.38 : 0.20)
            .toDouble(),
      );
    final metalFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          spec.primary.withValues(alpha: spec.opacity * 0.34),
          const Color(0xFF192431).withValues(alpha: spec.opacity * 0.58),
          spec.backgroundBottom.withValues(alpha: spec.opacity * 0.48),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    final bottom = size.height - 22;
    final right = size.width - 26;
    final gearCount = detailed ? 4 : 2;
    for (var i = 0; i < gearCount; i++) {
      final center = Offset(right - i * 44, bottom - (i % 2) * 18);
      _paintMiniGear(
        canvas,
        center,
        max(9, 18 - i * 1.7).toDouble(),
        paint,
        electric,
        metalFill,
      );
      if (detailed && i < 3) {
        canvas.drawLine(center, center.translate(-34, -10), electric);
        canvas.drawLine(
          center.translate(0, -8),
          center.translate(-38, -21),
          paint,
        );
      }
    }
    final pipeY = min(size.height - 12, 42.0);
    final pipe = Path()
      ..moveTo(size.width - 18, pipeY)
      ..lineTo(size.width - 88, pipeY)
      ..quadraticBezierTo(size.width - 112, pipeY, size.width - 112, pipeY + 22)
      ..lineTo(size.width - 112, size.height - 18);
    canvas.drawPath(pipe, paint);
    canvas.drawPath(pipe.shift(const Offset(-4, 3)), electric);
    _paintMiniGear(
      canvas,
      Offset(size.width - 118, pipeY + 25),
      10,
      electric,
      paint,
      metalFill,
    );
    final boltCount = detailed ? 3 : 1;
    for (var i = 0; i < boltCount; i++) {
      final x = 20 + i * 34.0;
      final y = 20 + (i % 2) * 14.0;
      final bolt = Path()
        ..moveTo(x, y - 18)
        ..lineTo(x + 15, y + 5)
        ..lineTo(x + 5, y + 5)
        ..lineTo(x + 22, y + 32);
      canvas.drawPath(bolt, electric);
    }
  }

  void _paintPanelScenePostea(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && !light && size.width >= 260;
    final hub = Offset(size.width - 40, size.height - 32);
    _paintMiniGear(canvas, hub, detailed ? 16 : 12, accent, paint, fill);
    for (var i = 0; i < (detailed ? 5 : 3); i++) {
      final node = Offset(size.width - 92 - i * 30, size.height - 24);
      canvas.drawLine(node, hub.translate(-10, -4), i.isEven ? paint : accent);
      _diamond(canvas, node, 5.5, i.isEven ? accent : fill);
      if (i.isEven) {
        canvas.drawLine(node, node.translate(0, -20), accent);
        _paintSceneFlower(
          canvas,
          node.translate(0, -26),
          5.5,
          fill,
          accent,
          paint,
        );
      }
    }
    final rune = Path()
      ..moveTo(size.width - 72, 22)
      ..lineTo(size.width - 46, 22)
      ..lineTo(size.width - 58, 46)
      ..lineTo(size.width - 82, 46);
    canvas.drawPath(rune, paint);
    final flowerCore = Offset(size.width - (detailed ? 148 : 118), 34);
    _paintSceneFlower(
      canvas,
      flowerCore,
      detailed ? 10 : 8,
      fill,
      accent,
      paint,
    );
    canvas.drawLine(flowerCore.translate(-28, 0), flowerCore, accent);
    canvas.drawLine(flowerCore, flowerCore.translate(20, 18), paint);
    _diamond(canvas, flowerCore.translate(-32, 0), 4.5, fill);
  }

  void _paintPanelSceneMedieval(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && !light && size.width >= 260;
    final c = Offset(size.width - 42, size.height - 40);
    final shield = Path()
      ..moveTo(c.dx, c.dy - 28)
      ..lineTo(c.dx + 25, c.dy - 14)
      ..quadraticBezierTo(c.dx + 20, c.dy + 28, c.dx, c.dy + 42)
      ..quadraticBezierTo(c.dx - 20, c.dy + 28, c.dx - 25, c.dy - 14)
      ..close();
    canvas.drawPath(shield, fill);
    canvas.drawPath(shield, paint);
    canvas.drawLine(c.translate(0, -20), c.translate(0, 30), accent);
    canvas.drawLine(c.translate(-15, -3), c.translate(15, -3), accent);

    for (final dir in <double>[-1, 1]) {
      final start = c.translate(dir * 45, -33);
      final end = c.translate(dir * 10, 26);
      canvas.drawLine(start, end, dir < 0 ? accent : paint);
      canvas.drawLine(
        start.translate(-dir * 6, 10),
        start.translate(dir * 6, 10),
        fill,
      );
      _diamond(canvas, end, 4.5, fill);
    }

    final brickTop = max(10.0, size.height - (detailed ? 98 : 78));
    for (var row = 0; row < (detailed ? 3 : 2); row++) {
      final y = brickTop + row * 18;
      for (
        var x = size.width - 150.0 + row * 13;
        x < size.width - 18;
        x += 30
      ) {
        final rect = Rect.fromLTWH(x, y, 22, 10);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          row.isEven ? paint : accent,
        );
      }
    }
    if (detailed) {
      final tower = Rect.fromLTWH(size.width - 140, 20, 34, 62);
      canvas.drawRect(tower, fill);
      canvas.drawRect(tower, paint);
      for (var i = 0; i < 3; i++) {
        canvas.drawRect(
          Rect.fromLTWH(tower.left + 2 + i * 11, tower.top - 10, 8, 12),
          i.isEven ? fill : accent,
        );
      }
      canvas.drawLine(tower.centerLeft, tower.centerRight, accent);
      canvas.drawLine(
        Offset(tower.center.dx, tower.top + 12),
        Offset(tower.center.dx, tower.bottom - 8),
        paint,
      );
    }
  }

  void _paintPanelSceneShadowGate(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final gate = Offset(size.width - 38, size.height - 34);
    canvas.drawArc(
      Rect.fromCenter(center: gate, width: 58, height: 70),
      -pi * 0.18,
      pi * 1.36,
      false,
      accent,
    );
    canvas.drawArc(
      Rect.fromCenter(center: gate, width: 34, height: 46),
      pi * 0.06,
      pi * 1.48,
      false,
      paint,
    );
    _diamond(canvas, gate, 10, fill);
    for (var i = 0; i < 4; i++) {
      final c = Offset(size.width - 92 - i * 24, size.height - 24 - i % 2 * 8);
      canvas.drawLine(c.translate(-8, -12), c.translate(8, 12), accent);
      canvas.drawLine(c.translate(8, -12), c.translate(-8, 12), paint);
    }
  }

  void _paintPanelScenePhobia(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final eye = Offset(size.width - 44, size.height - 36);
    final shape = Path()
      ..moveTo(eye.dx - 42, eye.dy)
      ..quadraticBezierTo(eye.dx, eye.dy - 22, eye.dx + 42, eye.dy)
      ..quadraticBezierTo(eye.dx, eye.dy + 22, eye.dx - 42, eye.dy);
    canvas.drawPath(shape, paint);
    canvas.drawCircle(eye, 12, fill);
    canvas.drawCircle(eye.translate(2, -1), 4, accent);
    for (var i = 0; i < 9; i++) {
      final angle = -pi * 0.85 + i * pi * 0.22;
      canvas.drawLine(
        eye.translate(cos(angle) * 40, sin(angle) * 17),
        eye.translate(cos(angle) * 55, sin(angle) * 30),
        i.isEven ? accent : paint,
      );
    }
    for (var i = 0; i < 4; i++) {
      final x = 22 + i * 28.0;
      final claw = Path()
        ..moveTo(x, size.height - 8)
        ..quadraticBezierTo(x + 17, size.height - 42, x + 6, size.height - 66)
        ..quadraticBezierTo(x + 25, size.height - 48, x + 24, size.height - 14);
      canvas.drawPath(claw, i.isEven ? accent : paint);
    }
  }

  void _paintPanelSceneLunar(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final moon = Offset(size.width - 32, size.height - 28);
    _paintOculumMoonPhase(
      canvas,
      moon,
      18,
      labelHashSafe(size),
      accent,
      fill,
      paint,
    );
    for (var i = 0; i < 5; i++) {
      _star(
        canvas,
        Offset(size.width - 78 - i * 23, size.height - 18 - (i % 2) * 10),
        3.5,
        paint,
      );
    }
  }

  int labelHashSafe(Size size) {
    return (size.width + size.height).round() % 8;
  }

  void _paintPanelSceneCathedral(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final c = Offset(size.width - 35, size.height - 34);
    canvas.drawCircle(c, 20, paint);
    canvas.drawCircle(c, 9, fill);
    for (var i = 0; i < 10; i++) {
      final angle = i * pi / 5;
      canvas.drawLine(c, c.translate(cos(angle) * 21, sin(angle) * 21), accent);
    }
  }

  void _paintPanelSceneThorn(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final branch = Path()..moveTo(10, size.height - 12);
    for (var i = 0; i < 5; i++) {
      final x = 12 + i * min(38.0, size.width * 0.10);
      branch.cubicTo(
        x + 12,
        size.height - 34,
        x + 32,
        size.height - 6,
        x + 48,
        size.height - 24,
      );
    }
    canvas.drawPath(branch, paint);
    for (var i = 0; i < 5; i++) {
      final base = Offset(24 + i * 32, size.height - 22 - (i % 2) * 8);
      canvas.drawLine(base, base.translate(18, -16), accent);
      _paintSceneLeaf(canvas, base.translate(8, -3), 1, 18, fill, paint);
    }
  }

  void _paintPanelSceneStorm(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
  ) {
    for (var i = 0; i < 3; i++) {
      final bolt = Path()
        ..moveTo(size.width - 28 - i * 34, 10)
        ..lineTo(size.width - 8 - i * 34, 42)
        ..lineTo(size.width - 21 - i * 34, 42)
        ..lineTo(size.width - 2 - i * 34, 76);
      canvas.drawPath(bolt, i.isEven ? accent : paint);
    }
  }

  void _paintPanelSceneTide(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    for (var row = 0; row < 2; row++) {
      final y = size.height - 16 - row * 18;
      final wave = Path()..moveTo(size.width * 0.45, y);
      for (var x = size.width * 0.45; x < size.width + 28; x += 28) {
        wave.quadraticBezierTo(x + 14, y - 14, x + 28, y);
      }
      canvas.drawPath(wave, row.isEven ? accent : paint);
    }
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(size.width - 20 - i * 24, 28 + (i % 2) * 9),
        4,
        fill,
      );
    }
  }

  void _paintPanelSceneEmber(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    for (var i = 0; i < 4; i++) {
      final base = Offset(size.width - 22 - i * 25, size.height - 18);
      canvas.drawRect(
        Rect.fromCenter(center: base, width: 8, height: 20),
        paint,
      );
      final flame = Path()
        ..moveTo(base.dx, base.dy - 30)
        ..quadraticBezierTo(base.dx + 11, base.dy - 13, base.dx, base.dy - 4)
        ..quadraticBezierTo(base.dx - 9, base.dy - 14, base.dx, base.dy - 30)
        ..close();
      canvas.drawPath(flame, i.isEven ? accent : fill);
    }
  }

  void _paintPanelSceneArchive(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final book = Rect.fromLTWH(size.width - 94, size.height - 58, 76, 42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(book, const Radius.circular(5)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(book, const Radius.circular(5)),
      paint,
    );
    canvas.drawLine(
      book.center.translate(0, -18),
      book.center.translate(0, 18),
      accent,
    );
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(
        book.topLeft.translate(10, 9 + i * 7),
        book.centerLeft.translate(28, -12 + i * 7),
        accent,
      );
    }
  }

  void _paintPanelSceneHoshy(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final moon = Offset(size.width - 36, 32);
    canvas.drawCircle(moon, 18, paint);
    canvas.drawCircle(moon.translate(7, -1), 17, fill);
    for (final dir in <double>[-1, 1]) {
      final ear = Path()
        ..moveTo(moon.dx + dir * 26, moon.dy + 22)
        ..lineTo(moon.dx + dir * 42, moon.dy - 12)
        ..lineTo(moon.dx + dir * 58, moon.dy + 22);
      canvas.drawPath(ear, dir < 0 ? accent : paint);
    }
    for (var i = 0; i < 5; i++) {
      _star(
        canvas,
        Offset(size.width - 90 - i * 28, size.height - 22 - (i % 2) * 12),
        4,
        i.isEven ? accent : paint,
      );
    }
  }

  void _paintPanelSceneSlime(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final drip = Path()..moveTo(size.width * 0.52, 8);
    for (var x = size.width * 0.52; x < size.width + 28; x += 28) {
      drip.quadraticBezierTo(
        x + 14,
        28 + ((x ~/ 28).isEven ? 10 : 0),
        x + 28,
        8,
      );
    }
    canvas.drawPath(drip, fill);
    _paintMiniGear(
      canvas,
      Offset(size.width - 35, size.height - 30),
      12,
      accent,
      paint,
      fill,
    );
  }

  void _paintPanelSceneSigil(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final c = Offset(size.width - 34, size.height - 30);
    canvas.drawCircle(c, 19, paint);
    _diamond(canvas, c, 11, accent);
    canvas.drawCircle(c, 4, fill);
    canvas.drawCircle(c.translate(-42, -8), 12, accent);
  }

  void _paintPanelSceneFrost(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
  ) {
    for (var i = 0; i < 5; i++) {
      final c = Offset(
        size.width - 22 - i * 28,
        size.height - 22 - (i % 2) * 8,
      );
      canvas.drawLine(c.translate(-12, 0), c.translate(12, 0), accent);
      canvas.drawLine(c.translate(0, -12), c.translate(0, 12), paint);
      canvas.drawLine(c.translate(-8, -8), c.translate(8, 8), accent);
    }
  }

  void _paintPanelSceneReliquary(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final c = Offset(size.width - 32, size.height - 30);
    _diamond(canvas, c, 16, fill);
    _diamond(canvas, c, 10, accent);
    canvas.drawArc(
      Rect.fromCenter(center: c.translate(-34, -4), width: 42, height: 42),
      -pi / 2,
      pi * 1.4,
      false,
      paint,
    );
  }

  void _paintPanelCorners(Canvas canvas, Size size, Paint paint, Paint accent) {
    final corner = min(54.0, max(26.0, size.shortestSide * 0.16));
    for (final origin in <Offset>[
      const Offset(8, 8),
      Offset(size.width - 8, 8),
      Offset(8, size.height - 8),
      Offset(size.width - 8, size.height - 8),
    ]) {
      final sx = origin.dx < size.width / 2 ? 1.0 : -1.0;
      final sy = origin.dy < size.height / 2 ? 1.0 : -1.0;
      canvas.drawLine(origin, origin.translate(sx * corner, 0), paint);
      canvas.drawLine(origin, origin.translate(0, sy * corner), paint);
      canvas.drawLine(
        origin.translate(sx * 10, sy * 10),
        origin.translate(sx * corner * 0.62, sy * corner * 0.62),
        accent,
      );
    }
  }

  void _star(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
  }

  void _diamond(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * 0.72, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius * 0.72, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _paintPanelLunar(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final r = min(24.0, max(14.0, size.shortestSide * 0.08));
    final moon = Offset(size.width - 34, 30);
    final lit = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.accent.withValues(alpha: light ? 0.050 : 0.082);
    _paintOculumMoonPhase(canvas, moon, r, 1, paint, lit, fill);
    _paintOculumMoonPhaseRow(
      canvas,
      24,
      max(28, size.width - 74),
      min(size.height - 20, 54),
      5.8,
      accent,
      lit,
      fill,
    );
    for (var i = 0; i < 5; i++) {
      _star(
        canvas,
        Offset(28 + i * 32, size.height - 24 - (i % 2) * 8),
        4.5,
        accent,
      );
    }
  }

  void _paintPanelCathedral(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
  ) {
    final center = Offset(size.width - 38, 38);
    canvas.drawCircle(center, 20, paint);
    canvas.drawCircle(center, 9, accent);
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      canvas.drawLine(
        center,
        Offset(center.dx + cos(angle) * 20, center.dy + sin(angle) * 20),
        i.isEven ? paint : accent,
      );
    }
    for (var x = 34.0; x < size.width - 72; x += 42) {
      canvas.drawLine(Offset(x, 10), Offset(x + 16, 44), paint);
    }
  }

  void _paintPanelThorn(Canvas canvas, Size size, Paint paint, Paint accent) {
    final vine = Path()..moveTo(14, size.height + 8);
    for (var i = 0; i < 5; i++) {
      final y = size.height - i * size.height / 4;
      vine.quadraticBezierTo(58, y - 24, 18, y - 52);
    }
    canvas.drawPath(vine, paint);
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.18 + i * 0.16);
      canvas.drawLine(Offset(28, y), Offset(52, y - 14), accent);
      canvas.drawLine(
        Offset(size.width - 26, y),
        Offset(size.width - 54, y + 16),
        paint,
      );
    }
  }

  void _paintPanelVervain(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final vine = Path()..moveTo(8, size.height + 8);
    for (var i = 0; i < 7; i++) {
      final y = size.height - i * size.height / 6;
      vine.cubicTo(58, y - 16, 18, y - 34, 68, y - 58);
    }
    canvas.drawPath(vine, paint..strokeWidth = paint.strokeWidth + 0.35);
    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.10 + i * 0.13);
      final left = Offset(26 + (i % 2) * 13, y);
      final leaf = Path()
        ..moveTo(left.dx, left.dy)
        ..cubicTo(
          left.dx + 15,
          left.dy - 16,
          left.dx + 31,
          left.dy - 10,
          left.dx + 43,
          left.dy,
        )
        ..cubicTo(
          left.dx + 28,
          left.dy + 15,
          left.dx + 12,
          left.dy + 12,
          left.dx,
          left.dy,
        )
        ..close();
      canvas.drawPath(leaf, i.isEven ? fill : accent);
      canvas.drawLine(left.translate(4, 0), left.translate(39, -1), paint);
      canvas.drawLine(left.translate(16, -4), left.translate(27, -11), accent);
      canvas.drawLine(left.translate(20, 4), left.translate(31, 10), accent);
      for (var p = 0; p < 5; p++) {
        final angle = p * pi * 2 / 5;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(
              size.width - 32 + cos(angle) * 9,
              24 + i * 11 + sin(angle) * 6,
            ),
            width: 9,
            height: 5,
          ),
          p.isEven ? accent : fill,
        );
      }
      final thornBase = Offset(18 + (i % 2) * 8, y + 6);
      final thorn = Path()
        ..moveTo(thornBase.dx, thornBase.dy)
        ..quadraticBezierTo(
          thornBase.dx + 18,
          thornBase.dy - 8,
          thornBase.dx + 28,
          thornBase.dy - 21,
        )
        ..quadraticBezierTo(
          thornBase.dx + 18,
          thornBase.dy - 8,
          thornBase.dx + 9,
          thornBase.dy + 3,
        );
      canvas.drawPath(thorn, i.isEven ? accent : paint);
    }

    final topVine = Path()..moveTo(18, 14);
    for (var x = 18.0; x < size.width - 18; x += 54) {
      topVine.cubicTo(x + 14, 28, x + 34, 2, x + 54, 14);
    }
    canvas.drawPath(topVine, accent);
    for (var i = 0; i < 4; i++) {
      final center = Offset(size.width - 34 - i * 23, size.height - 24);
      for (var p = 0; p < 6; p++) {
        final angle = p * pi / 3;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(
              center.dx + cos(angle) * 7,
              center.dy + sin(angle) * 5,
            ),
            width: 8,
            height: 4.5,
          ),
          p.isEven ? fill : accent,
        );
      }
      canvas.drawCircle(center, 2.4, paint);
    }
  }

  void _paintPanelKingi(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && !light && size.width >= 260;
    final electric = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = detailed ? 1.55 : 1.05
      ..color = const Color(0xFF16C8FF).withValues(
        alpha: (spec.opacity * (detailed ? 1.75 : 1.10))
            .clamp(0.10, detailed ? 0.42 : 0.22)
            .toDouble(),
      );
    final metalFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          spec.primary.withValues(alpha: detailed ? 0.16 : 0.08),
          const Color(0xFF9BB4C8).withValues(alpha: detailed ? 0.20 : 0.10),
          spec.backgroundBottom.withValues(alpha: 0.0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    final plateCount = detailed ? 4 : 2;
    for (var i = 0; i < plateCount; i++) {
      final y = 14 + i * (detailed ? 18.0 : 23.0);
      final plate = Rect.fromLTWH(
        size.width - (detailed ? 126 : 86) - i * 12,
        y,
        detailed ? 96 : 62,
        detailed ? 13 : 9,
      );
      final rr = RRect.fromRectAndRadius(
        plate,
        Radius.circular(detailed ? 4 : 3),
      );
      canvas.drawRRect(rr, metalFill);
      canvas.drawRRect(rr, i.isEven ? paint : accent);
      if (detailed) {
        canvas.drawCircle(plate.centerLeft.translate(8, 0), 1.9, fill);
        canvas.drawCircle(plate.centerRight.translate(-8, 0), 1.9, fill);
        canvas.drawLine(
          plate.centerLeft.translate(18, 0),
          plate.centerRight.translate(-18, 0),
          electric,
        );
      }
    }

    final gearCount = detailed ? 5 : 3;
    for (var i = 0; i < gearCount; i++) {
      final center = Offset(size.width - 34 - i * 38, 34 + (i % 2) * 20);
      final radius = detailed ? 17.0 : 13.0;
      canvas.drawCircle(center, radius, paint);
      canvas.drawCircle(center, radius * 0.43, fill);
      for (var s = 0; s < (detailed ? 12 : 8); s++) {
        final angle = s * 2 * pi / (detailed ? 12 : 8);
        canvas.drawLine(
          Offset(
            center.dx + cos(angle) * radius * 0.60,
            center.dy + sin(angle) * radius * 0.60,
          ),
          Offset(
            center.dx + cos(angle) * (radius + (detailed ? 6 : 4)),
            center.dy + sin(angle) * (radius + (detailed ? 6 : 4)),
          ),
          s.isEven ? electric : paint,
        );
      }
    }
    final boltCount = detailed ? 7 : 3;
    for (var i = 0; i < boltCount; i++) {
      final x = 20 + i * 42.0;
      final y = size.height - 20 - (i % 2) * 12;
      final bolt = Path()
        ..moveTo(x, y - 28)
        ..lineTo(x + 16, y - 5)
        ..lineTo(x + 5, y - 5)
        ..lineTo(x + 20, y + 22);
      canvas.drawPath(bolt, i.isEven ? electric : accent);
    }
    final step = detailed ? 30.0 : 44.0;
    for (var x = 18.0; x < size.width - 18; x += step) {
      canvas.drawLine(Offset(x, 10), Offset(x, detailed ? 40 : 30), paint);
      canvas.drawCircle(
        Offset(x, detailed ? 40 : 30),
        detailed ? 3.8 : 3,
        accent,
      );
      canvas.drawLine(Offset(x, 22), Offset(x + 14, 22), electric);
      if (((x - 18) ~/ 34).isEven) {
        _diamond(canvas, Offset(x + 20, 22), 4, fill);
      }
    }
    if (detailed) {
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.95
        ..color = const Color(0xFFB7C9D7).withValues(alpha: 0.22);
      for (var i = 0; i < 3; i++) {
        final rect = Rect.fromLTWH(18 + i * 38, size.height - 68, 86, 42);
        canvas.drawArc(rect, pi * 1.02, pi * 0.86, false, arcPaint);
      }
    }
  }

  void _paintPanelPostea(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && !light && size.width >= 260;
    final circuit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = detailed ? 1.42 : 1.0
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * (detailed ? 1.55 : 1.05))
            .clamp(0.09, detailed ? 0.36 : 0.22)
            .toDouble(),
      );
    final railCount = detailed ? 5 : 3;
    for (var i = 0; i < railCount; i++) {
      final y = 14 + i * (detailed ? 17.0 : 23.0);
      final path = Path()
        ..moveTo(18, y)
        ..lineTo(size.width * 0.42, y)
        ..lineTo(size.width * 0.52, y + 12)
        ..lineTo(size.width - 22, y + 12);
      canvas.drawPath(path, i.isEven ? circuit : paint);
      _diamond(
        canvas,
        Offset(size.width * 0.52, y + 12),
        detailed ? 5.5 : 4.5,
        fill,
      );
    }
    for (var i = 0; i < (detailed ? 4 : 2); i++) {
      final c = Offset(size.width - 34 - i * 34, size.height - 28);
      _paintMiniGear(canvas, c, detailed ? 12 : 9, paint, circuit, fill);
    }
    final rune = Path()
      ..moveTo(size.width - 94, 20)
      ..lineTo(size.width - 62, 20)
      ..lineTo(size.width - 76, 45)
      ..lineTo(size.width - 106, 45)
      ..close();
    canvas.drawPath(rune, accent);
  }

  void _paintPanelMedieval(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && !light && size.width >= 260;
    final topY = 12.0;
    for (var i = 0; i < (detailed ? 8 : 5); i++) {
      final x = 16 + i * (detailed ? 34.0 : 42.0);
      final rect = Rect.fromLTWH(x, topY + (i.isEven ? 0 : 11), 26, 12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        i.isEven ? paint : accent,
      );
    }

    final shieldCenter = Offset(size.width - 44, size.height - 36);
    final shield = Path()
      ..moveTo(shieldCenter.dx, shieldCenter.dy - 28)
      ..lineTo(shieldCenter.dx + 25, shieldCenter.dy - 13)
      ..quadraticBezierTo(
        shieldCenter.dx + 18,
        shieldCenter.dy + 26,
        shieldCenter.dx,
        shieldCenter.dy + 40,
      )
      ..quadraticBezierTo(
        shieldCenter.dx - 18,
        shieldCenter.dy + 26,
        shieldCenter.dx - 25,
        shieldCenter.dy - 13,
      )
      ..close();
    canvas.drawPath(shield, fill);
    canvas.drawPath(shield, paint);
    canvas.drawLine(
      shieldCenter.translate(0, -20),
      shieldCenter.translate(0, 28),
      accent,
    );
    canvas.drawLine(
      shieldCenter.translate(-15, -1),
      shieldCenter.translate(15, -1),
      accent,
    );

    for (final dir in <double>[-1, 1]) {
      final hilt = shieldCenter.translate(dir * 48, -28);
      final tip = shieldCenter.translate(dir * 11, 24);
      canvas.drawLine(hilt, tip, dir < 0 ? accent : paint);
      canvas.drawLine(
        hilt.translate(-dir * 8, 8),
        hilt.translate(dir * 8, 8),
        fill,
      );
      _diamond(canvas, tip, 4.5, fill);
    }

    if (detailed) {
      final tower = Rect.fromLTWH(18, size.height - 82, 38, 68);
      canvas.drawRect(tower, fill);
      canvas.drawRect(tower, paint);
      for (var i = 0; i < 3; i++) {
        final merlon = Rect.fromLTWH(
          tower.left + 3 + i * 12,
          tower.top - 10,
          8,
          13,
        );
        canvas.drawRect(merlon, i.isEven ? fill : accent);
      }
      canvas.drawLine(tower.centerLeft, tower.centerRight, accent);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(tower.center.dx, tower.bottom - 4),
          width: 22,
          height: 34,
        ),
        pi,
        pi,
        false,
        paint,
      );
    }
  }

  void _paintPanelShadowGate(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final gate = Offset(size.width - 42, 36);
    canvas.drawArc(
      Rect.fromCenter(center: gate, width: 76, height: 62),
      -pi * 0.18,
      pi * 1.36,
      false,
      accent,
    );
    canvas.drawArc(
      Rect.fromCenter(center: gate, width: 42, height: 36),
      pi * 0.08,
      pi * 1.32,
      false,
      paint,
    );
    _diamond(canvas, gate, 10, fill);
    for (var i = 0; i < 5; i++) {
      final x = 18 + i * 32.0;
      canvas.drawLine(Offset(x, size.height - 12), Offset(x + 18, 12), paint);
      canvas.drawLine(
        Offset(x + 18, size.height - 12),
        Offset(x, 12),
        i.isEven ? accent : paint,
      );
    }
  }

  void _paintPanelPhobia(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final eyeCenter = Offset(size.width - 42, 34);
    canvas.drawOval(
      Rect.fromCenter(center: eyeCenter, width: 68, height: 30),
      paint,
    );
    canvas.drawCircle(eyeCenter, 10, fill);
    canvas.drawCircle(eyeCenter, 3.5, accent);
    for (var i = 0; i < 9; i++) {
      final angle = -pi * 0.88 + i * pi * 0.22;
      canvas.drawLine(
        Offset(eyeCenter.dx + cos(angle) * 34, eyeCenter.dy + sin(angle) * 15),
        Offset(eyeCenter.dx + cos(angle) * 48, eyeCenter.dy + sin(angle) * 26),
        i.isEven ? accent : paint,
      );
    }

    for (var i = 0; i < 6; i++) {
      final x = 18 + i * 31.0;
      final top = 8 + (i % 2) * 7.0;
      final claw = Path()
        ..moveTo(x, top)
        ..quadraticBezierTo(x + 13, top + 22, x + 3, top + 52)
        ..quadraticBezierTo(x + 20, top + 34, x + 22, top + 10);
      canvas.drawPath(claw, i.isEven ? paint : accent);
    }

    for (var i = 0; i < 7; i++) {
      final base = Offset(size.width - 28 - i * 24, size.height - 15);
      final tooth = Path()
        ..moveTo(base.dx - 7, base.dy)
        ..lineTo(base.dx, base.dy - 22 - (i % 3) * 5)
        ..lineTo(base.dx + 7, base.dy)
        ..close();
      canvas.drawPath(tooth, i.isEven ? fill : paint);
    }
  }

  void _paintPanelSigil(Canvas canvas, Size size, Paint paint, Paint accent) {
    for (var i = 0; i < 3; i++) {
      final center = Offset(size.width - 28 - i * 34, size.height - 28);
      canvas.drawCircle(center, 14, i.isEven ? paint : accent);
      _diamond(canvas, center, 7, i.isEven ? accent : paint);
    }
    for (var i = 0; i < 5; i++) {
      final x = 24 + i * 38.0;
      canvas.drawLine(Offset(x, 12), Offset(x, 38), paint);
      canvas.drawLine(Offset(x, 25), Offset(x + 15, 13), accent);
    }
  }

  void _paintPanelFrost(Canvas canvas, Size size, Paint paint, Paint accent) {
    for (var i = 0; i < 7; i++) {
      final x = 24 + i * 34.0;
      final len = 14.0 + (i % 3) * 7;
      final shard = Path()
        ..moveTo(x, 0)
        ..lineTo(x + 6, len)
        ..lineTo(x - 5, len * 0.82)
        ..close();
      canvas.drawPath(shard, i.isEven ? paint : accent);
      _star(canvas, Offset(size.width - x, size.height - 22), 5, accent);
    }
  }

  void _paintPanelStorm(Canvas canvas, Size size, Paint paint, Paint accent) {
    for (var i = 0; i < 4; i++) {
      final x = size.width - 34 - i * 38;
      final bolt = Path()
        ..moveTo(x, 10)
        ..lineTo(x + 16, 34)
        ..lineTo(x + 5, 34)
        ..lineTo(x + 20, 62);
      canvas.drawPath(bolt, i.isEven ? accent : paint);
    }
    for (var i = 0; i < 12; i++) {
      final x = 22 + (i * 37 % max(40, size.width.toInt() - 44)).toDouble();
      canvas.drawLine(
        Offset(x, size.height - 46),
        Offset(x + 10, size.height - 20),
        paint,
      );
    }
  }

  void _paintPanelTide(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    for (var row = 0; row < 2; row++) {
      final y = size.height - 18 - row * 18;
      final wave = Path()..moveTo(0, y);
      for (var x = 0.0; x < size.width + 32; x += 32) {
        wave.quadraticBezierTo(x + 16, y - 14, x + 32, y);
      }
      canvas.drawPath(wave, row.isEven ? paint : accent);
    }
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(size.width - 24 - i * 26, 22 + (i % 2) * 10),
        4 + (i % 3),
        fill,
      );
    }
  }

  void _paintPanelEmber(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    for (var i = 0; i < 4; i++) {
      final base = Offset(22 + i * 28.0, size.height - 22);
      canvas.drawRect(
        Rect.fromCenter(center: base, width: 10, height: 24),
        paint,
      );
      final flame = Path()
        ..moveTo(base.dx, base.dy - 34)
        ..quadraticBezierTo(base.dx + 12, base.dy - 16, base.dx, base.dy - 5)
        ..quadraticBezierTo(base.dx - 10, base.dy - 16, base.dx, base.dy - 34)
        ..close();
      canvas.drawPath(flame, i.isEven ? accent : fill);
    }
    for (var i = 0; i < 8; i++) {
      _star(
        canvas,
        Offset(size.width - 24 - i * 23, 22 + (i % 3) * 10),
        3.5,
        accent,
      );
    }
  }

  void _paintPanelArchive(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    for (var i = 0; i < 5; i++) {
      final y = 18 + i * 10.0;
      canvas.drawLine(
        Offset(22, y),
        Offset(min(size.width - 24, 220), y),
        i.isEven ? paint : accent,
      );
    }
    for (var i = 0; i < 5; i++) {
      final center = Offset(size.width - 28 - i * 24, size.height - 22);
      canvas.drawLine(center.translate(0, -12), center.translate(0, 12), paint);
      canvas.drawLine(center, center.translate(-10, -10), accent);
      if (i.isEven) _diamond(canvas, center.translate(0, -18), 4, fill);
    }
  }

  void _paintPanelSlime(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final drip = Path()..moveTo(0, 12);
    for (var x = 0.0; x <= size.width + 28; x += 28) {
      final extraDrop = (x ~/ 28).isEven ? 12.0 : 0.0;
      drip.quadraticBezierTo(x + 13, 34 + extraDrop, x + 28, 12);
    }
    canvas.drawPath(drip, fill);
    for (var i = 0; i < 7; i++) {
      canvas.drawCircle(
        Offset(24 + i * 31, size.height - 22 - (i % 3) * 9),
        5 + (i % 2) * 2,
        i.isEven ? accent : paint,
      );
    }
    final crown = Path()
      ..moveTo(size.width - 82, 48)
      ..lineTo(size.width - 72, 22)
      ..lineTo(size.width - 58, 42)
      ..lineTo(size.width - 44, 20)
      ..lineTo(size.width - 34, 48);
    canvas.drawPath(crown, accent);
  }

  void _paintPanelObser(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final center = Offset(size.width - 44, 42);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 64, height: 32),
      paint,
    );
    canvas.drawCircle(center, 12, fill);
    canvas.drawCircle(center, 5, accent);
    for (var i = 0; i < 5; i++) {
      final x = 24 + i * 34.0;
      _diamond(
        canvas,
        Offset(x, size.height - 22),
        7,
        i.isEven ? paint : accent,
      );
      canvas.drawLine(Offset(x - 9, 18), Offset(x + 9, 18), accent);
    }
  }

  void _paintPanelHoshy(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final moon = Offset(size.width - 32, 30);
    canvas.drawCircle(moon, 18, paint);
    canvas.drawCircle(moon.translate(8, -1), 17, fill);
    final leftEar = Path()
      ..moveTo(size.width - 86, 45)
      ..lineTo(size.width - 68, 11)
      ..lineTo(size.width - 50, 45);
    final rightEar = Path()
      ..moveTo(size.width - 48, 45)
      ..lineTo(size.width - 30, 11)
      ..lineTo(size.width - 12, 45);
    canvas.drawPath(leftEar, accent);
    canvas.drawPath(rightEar, paint);
    for (var i = 0; i < 8; i++) {
      _star(
        canvas,
        Offset(24 + i * 30, size.height - 22 - (i % 2) * 9),
        4,
        i.isEven ? accent : paint,
      );
    }
  }

  void _paintPanelReliquary(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accent,
  ) {
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width - 28, 28),
        width: 42,
        height: 42,
      ),
      -pi / 2,
      pi,
      false,
      accent,
    );
    _diamond(canvas, const Offset(28, 28), 8, paint);
    _diamond(canvas, Offset(size.width - 28, size.height - 28), 8, accent);
  }

  @override
  bool shouldRepaint(covariant _OculumThemePanelDecorationPainter oldDelegate) {
    return oldDelegate.spec.style != spec.style ||
        oldDelegate.spec.presetId != spec.presetId ||
        oldDelegate.spec.primary != spec.primary ||
        oldDelegate.spec.secondary != spec.secondary ||
        oldDelegate.spec.accent != spec.accent ||
        oldDelegate.spec.backgroundTop != spec.backgroundTop ||
        oldDelegate.spec.backgroundMid != spec.backgroundMid ||
        oldDelegate.spec.backgroundBottom != spec.backgroundBottom ||
        oldDelegate.spec.opacity != spec.opacity ||
        oldDelegate.spec.usesBaseColors != spec.usesBaseColors ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.light != light ||
        oldDelegate.desktop != desktop;
  }
}

class _OculumJrpgCompanionPainter extends CustomPainter {
  const _OculumJrpgCompanionPainter({required this.spec});

  final OculumThemeDecorationSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = min(size.width / 260.0, size.height / 280.0);
    canvas.save();
    canvas.translate(
      (size.width - 260 * scale) / 2,
      (size.height - 280 * scale) * 0.82,
    );
    canvas.scale(scale);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = spec.primary.withValues(alpha: 0.72);
    final fine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = spec.accent.withValues(alpha: 0.72);
    final body = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          Color.lerp(
            spec.backgroundMid,
            const Color(0xFF3957B8),
            0.52,
          )!.withValues(alpha: 0.92),
          Color.lerp(
            spec.backgroundBottom,
            const Color(0xFF090A22),
            0.44,
          )!.withValues(alpha: 0.96),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(0, 0, 260, 280));
    final belly = Paint()
      ..style = PaintingStyle.fill
      ..shader =
          RadialGradient(
            colors: [
              spec.primary.withValues(alpha: 0.78),
              spec.accent.withValues(alpha: 0.32),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: const Offset(132, 158), radius: 50),
          );
    final gold = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE7B84A).withValues(alpha: 0.78);
    final coral = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFF8B78).withValues(alpha: 0.70);
    final glow = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.accent.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    canvas.drawOval(const Rect.fromLTWH(52, 238, 152, 26), glow);
    canvas.drawCircle(const Offset(136, 146), 86, glow);

    final tail = Path()
      ..moveTo(177, 177)
      ..cubicTo(226, 171, 237, 214, 203, 224)
      ..cubicTo(178, 231, 179, 202, 199, 204);
    canvas.drawPath(tail, outline);
    canvas.drawPath(tail, fine);

    final leftWing = Path()
      ..moveTo(72, 142)
      ..cubicTo(32, 122, 30, 167, 52, 192)
      ..cubicTo(67, 178, 76, 160, 72, 142)
      ..close();
    final rightWing = Path()
      ..moveTo(188, 142)
      ..cubicTo(229, 126, 228, 170, 207, 194)
      ..cubicTo(192, 181, 183, 160, 188, 142)
      ..close();
    canvas.drawPath(leftWing, body);
    canvas.drawPath(rightWing, body);
    canvas.drawPath(leftWing, outline);
    canvas.drawPath(rightWing, outline);
    canvas.drawLine(const Offset(50, 181), const Offset(70, 158), fine);
    canvas.drawLine(const Offset(210, 181), const Offset(190, 158), fine);

    final torso = Path()
      ..moveTo(130, 98)
      ..cubicTo(80, 100, 66, 142, 75, 185)
      ..cubicTo(82, 228, 112, 247, 139, 239)
      ..cubicTo(181, 228, 195, 190, 187, 151)
      ..cubicTo(181, 115, 159, 98, 130, 98)
      ..close();
    canvas.drawPath(torso, body);
    canvas.drawPath(torso, outline);

    final head = RRect.fromRectAndRadius(
      const Rect.fromLTWH(78, 42, 105, 78),
      const Radius.circular(30),
    );
    canvas.drawRRect(head, body);
    canvas.drawRRect(head, outline);

    final crest = Path()
      ..moveTo(112, 43)
      ..lineTo(124, 16)
      ..lineTo(138, 42)
      ..lineTo(152, 19)
      ..lineTo(158, 47);
    canvas.drawPath(crest, outline);
    canvas.drawCircle(const Offset(124, 18), 5.5, gold);
    canvas.drawCircle(const Offset(152, 20), 4.8, coral);

    canvas.drawCircle(const Offset(108, 76), 13, fine);
    canvas.drawCircle(const Offset(154, 78), 10, gold);
    canvas.drawCircle(
      const Offset(111, 73),
      4.2,
      spec.primary.withValues(alpha: 0.94).toPaint(),
    );
    canvas.drawCircle(
      const Offset(157, 75),
      3.4,
      spec.secondary.withValues(alpha: 0.92).toPaint(),
    );

    final mouth = Path()
      ..moveTo(111, 100)
      ..quadraticBezierTo(132, 112, 154, 101);
    canvas.drawPath(mouth, fine);
    canvas.drawCircle(const Offset(132, 107), 3.6, coral);

    canvas.drawOval(const Rect.fromLTWH(96, 128, 73, 66), belly);
    canvas.drawOval(const Rect.fromLTWH(96, 128, 73, 66), fine);
    final core = Path()
      ..moveTo(133, 138)
      ..lineTo(156, 160)
      ..lineTo(133, 183)
      ..lineTo(110, 160)
      ..close();
    canvas.drawPath(core, spec.accent.withValues(alpha: 0.58).toPaint());
    canvas.drawPath(core, outline);

    for (final foot in <Offset>[
      const Offset(99, 237),
      const Offset(157, 235),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: foot, width: 44, height: 20),
        body,
      );
      canvas.drawOval(
        Rect.fromCenter(center: foot, width: 44, height: 20),
        outline,
      );
    }

    final charmLine = Path()
      ..moveTo(198, 206)
      ..quadraticBezierTo(206, 220, 198, 236);
    canvas.drawPath(charmLine, fine);
    _paintTinyPanelStar(canvas, const Offset(197, 246), 10, gold);

    for (final star in <Offset>[
      const Offset(62, 58),
      const Offset(202, 71),
      const Offset(218, 142),
      const Offset(45, 219),
    ]) {
      _paintTinyPanelStar(canvas, star, 5.5, fine);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OculumJrpgCompanionPainter oldDelegate) {
    return oldDelegate.spec.presetId != spec.presetId ||
        oldDelegate.spec.primary != spec.primary ||
        oldDelegate.spec.secondary != spec.secondary ||
        oldDelegate.spec.accent != spec.accent;
  }
}

extension _OculumColorPaint on Color {
  Paint toPaint() => Paint()
    ..style = PaintingStyle.fill
    ..color = this;
}

class _OculumThemeDecorationPainter extends CustomPainter {
  _OculumThemeDecorationPainter(this.spec, {required this.desktop});

  final OculumThemeDecorationSpec spec;
  final bool desktop;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty ||
        size.width < 2 ||
        size.height < 2 ||
        spec.style == 'none' ||
        spec.opacity <= 0) {
      return;
    }
    final rawEdge = min(desktop ? 220.0 : 156.0, max(72.0, size.width * 0.16));
    final edge = min(rawEdge, max(24.0, size.width * 0.42));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = spec.primary.withValues(alpha: spec.opacity)
      ..shader = _oculumReverseBackgroundShader(
        spec,
        size,
        spec.primary,
        spec.opacity,
      );
    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = spec.accent.withValues(alpha: spec.opacity * 0.82)
      ..shader = _oculumReverseBackgroundShader(
        spec,
        size,
        spec.accent,
        spec.opacity * 0.92,
      );
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.secondary.withValues(alpha: spec.opacity * 0.45)
      ..shader = _oculumReverseBackgroundShader(
        spec,
        size,
        spec.secondary,
        spec.opacity * 0.56,
      );

    _paintThemeBackdropWash(canvas, size);

    switch (spec.style) {
      case 'lunar':
        _paintLunar(canvas, size, edge, paint, accent, fill);
        break;
      case 'cathedral':
        _paintCathedral(canvas, size, edge, paint, accent);
        break;
      case 'thorn':
        _paintThorns(canvas, size, edge, paint, accent);
        break;
      case 'vervain':
        _paintVervain(canvas, size, edge, paint, accent, fill);
        break;
      case 'kingi':
        _paintKingi(canvas, size, edge, paint, accent, fill);
        break;
      case 'jrpg':
        _paintJrpg(canvas, size, edge, paint, accent, fill);
        break;
      case 'roguelike':
        _paintRoguelike(canvas, size, edge, paint, accent, fill);
        break;
      case 'souls':
        _paintSouls(canvas, size, edge, paint, accent, fill);
        break;
      case 'bolted_metal':
        _paintBoltedMetal(canvas, size, edge, paint, accent, fill);
        break;
      case 'wild_companion':
        _paintWildCompanion(canvas, size, edge, paint, accent, fill);
        break;
      case 'modern_school':
        _paintModernSchool(canvas, size, edge, paint, accent, fill);
        break;
      case 'postea':
        _paintPostea(canvas, size, edge, paint, accent, fill);
        break;
      case 'fortress_oculum':
        _paintOculumFortress(canvas, size, edge, paint, accent, fill);
        break;
      case 'medieval':
        _paintMedieval(canvas, size, edge, paint, accent, fill);
        break;
      case 'phobia':
        _paintPhobia(canvas, size, edge, paint, accent, fill);
        break;
      case 'shadow_gate':
        _paintShadowGate(canvas, size, edge, paint, accent, fill);
        break;
      case 'sigil':
        _paintSigils(canvas, size, edge, paint, accent);
        break;
      case 'frost':
        _paintFrost(canvas, size, edge, paint, accent);
        break;
      case 'storm':
        _paintStorm(canvas, size, edge, paint, accent, fill);
        break;
      case 'tide':
        _paintTide(canvas, size, edge, paint, accent, fill);
        break;
      case 'ember':
        _paintEmber(canvas, size, edge, paint, accent, fill);
        break;
      case 'archive':
        _paintArchive(canvas, size, edge, paint, accent, fill);
        break;
      case 'slime':
        _paintSlime(canvas, size, edge, paint, accent, fill);
        break;
      case 'obser':
        _paintObser(canvas, size, edge, paint, accent, fill);
        break;
      case 'hoshy':
        _paintHoshy(canvas, size, edge, paint, accent, fill);
        break;
      default:
        _paintReliquary(canvas, size, edge, paint, accent);
    }
    _paintResponsiveDetailLayer(canvas, size, edge, paint, accent, fill);
    _paintPresetSignature(canvas, size, edge, paint, accent, fill);
    _paintBottomRightThemeDoodle(canvas, size, edge);
  }

  void _paintBottomRightThemeDoodle(Canvas canvas, Size size, double edge) {
    final scale = min(
      desktop ? 184.0 : 128.0,
      max(desktop ? 118.0 : 82.0, min(size.width, size.height) * 0.22),
    );
    final margin = desktop ? 34.0 : 18.0;
    final center = Offset(
      size.width - margin - scale * 0.48,
      size.height - margin - scale * 0.42,
    );
    final alpha = (spec.opacity * (desktop ? 2.05 : 1.72))
        .clamp(0.16, desktop ? 0.46 : 0.34)
        .toDouble();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = desktop ? 1.85 : 1.28
      ..color = spec.primary.withValues(alpha: alpha);
    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = desktop ? 1.55 : 1.08
      ..color = spec.accent.withValues(alpha: alpha * 0.95);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.secondary.withValues(alpha: alpha * 0.46);
    final glow = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.accent.withValues(alpha: alpha * 0.13)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    canvas.drawCircle(center, scale * 0.56, glow);

    switch (spec.style) {
      case 'lunar':
        _paintOculumMoonPhase(
          canvas,
          center,
          scale * 0.22,
          3,
          accent,
          fill,
          line,
        );
        for (var i = 0; i < 6; i++) {
          _paintStar(
            canvas,
            center.translate(-scale * 0.42 + i * scale * 0.15, -scale * 0.28),
            scale * (0.026 + (i % 2) * 0.008),
            i.isEven ? line : accent,
          );
        }
        break;
      case 'hoshy':
        _paintOculumMoonPhase(
          canvas,
          center.translate(0, -scale * 0.06),
          scale * 0.18,
          2,
          accent,
          fill,
          line,
        );
        for (final dir in <double>[-1, 1]) {
          final ear = Path()
            ..moveTo(center.dx + dir * scale * 0.18, center.dy + scale * 0.05)
            ..lineTo(center.dx + dir * scale * 0.36, center.dy - scale * 0.26)
            ..lineTo(center.dx + dir * scale * 0.52, center.dy + scale * 0.08);
          canvas.drawPath(ear, dir < 0 ? line : accent);
        }
        for (var i = 0; i < 5; i++) {
          _paintStar(
            canvas,
            center.translate(-scale * 0.34 + i * scale * 0.17, scale * 0.30),
            scale * 0.030,
            i.isEven ? accent : line,
          );
        }
        break;
      case 'cathedral':
        _paintRoseWindow(canvas, center, scale * 0.24, line, accent);
        canvas.drawLine(
          center.translate(0, -scale * 0.42),
          center.translate(0, scale * 0.42),
          accent,
        );
        canvas.drawLine(
          center.translate(-scale * 0.42, 0),
          center.translate(scale * 0.42, 0),
          line,
        );
        break;
      case 'fortress_oculum':
        final shield = Path()
          ..moveTo(center.dx, center.dy - scale * 0.48)
          ..lineTo(center.dx + scale * 0.42, center.dy - scale * 0.20)
          ..lineTo(center.dx + scale * 0.34, center.dy + scale * 0.34)
          ..lineTo(center.dx, center.dy + scale * 0.52)
          ..lineTo(center.dx - scale * 0.34, center.dy + scale * 0.34)
          ..lineTo(center.dx - scale * 0.42, center.dy - scale * 0.20)
          ..close();
        canvas.drawPath(shield, fill);
        canvas.drawPath(shield, line);
        canvas.drawOval(
          Rect.fromCenter(
            center: center.translate(0, -scale * 0.04),
            width: scale * 0.56,
            height: scale * 0.30,
          ),
          accent,
        );
        canvas.drawCircle(
          center.translate(0, -scale * 0.04),
          scale * 0.08,
          line,
        );
        for (var i = 0; i < 5; i++) {
          _paintDiamond(
            canvas,
            center.translate(-scale * 0.28 + i * scale * 0.14, scale * 0.34),
            scale * 0.026,
            i.isEven ? accent : line,
          );
        }
        break;
      case 'thorn':
      case 'vervain':
        final vine = Path()
          ..moveTo(center.dx - scale * 0.52, center.dy + scale * 0.38);
        vine.cubicTo(
          center.dx - scale * 0.22,
          center.dy - scale * 0.06,
          center.dx + scale * 0.10,
          center.dy + scale * 0.18,
          center.dx + scale * 0.42,
          center.dy - scale * 0.36,
        );
        canvas.drawPath(vine, line);
        for (var i = 0; i < 4; i++) {
          final base = center.translate(
            -scale * 0.34 + i * scale * 0.22,
            scale * (0.18 - i * 0.09),
          );
          _paintBotanicalLeaf(
            canvas,
            base,
            i.isEven ? 1 : -1,
            scale * 0.18,
            fill,
            accent,
          );
          if (spec.style == 'thorn') {
            canvas.drawLine(
              base,
              base.translate(scale * 0.12, -scale * 0.16),
              accent,
            );
          }
        }
        break;
      case 'kingi':
        final head = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center.translate(0, -scale * 0.16),
            width: scale * 0.58,
            height: scale * 0.42,
          ),
          Radius.circular(scale * 0.11),
        );
        final body = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center.translate(0, scale * 0.22),
            width: scale * 0.42,
            height: scale * 0.46,
          ),
          Radius.circular(scale * 0.08),
        );
        canvas.drawRRect(head, fill);
        canvas.drawRRect(head, line);
        canvas.drawRRect(body, fill);
        canvas.drawRRect(body, line);
        canvas.drawCircle(
          center.translate(-scale * 0.15, -scale * 0.18),
          scale * 0.055,
          accent,
        );
        canvas.drawCircle(
          center.translate(scale * 0.15, -scale * 0.18),
          scale * 0.055,
          accent,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: center.translate(0, -scale * 0.07),
            width: scale * 0.34,
            height: scale * 0.16,
          ),
          0,
          pi,
          false,
          accent,
        );
        canvas.drawCircle(
          center.translate(0, scale * 0.20),
          scale * 0.10,
          accent,
        );
        canvas.drawLine(
          center.translate(0, -scale * 0.38),
          center.translate(scale * 0.08, -scale * 0.55),
          line,
        );
        canvas.drawCircle(
          center.translate(scale * 0.10, -scale * 0.58),
          scale * 0.035,
          accent,
        );
        break;
      case 'postea':
        _paintSyntheticBloom(canvas, center, scale * 0.24, line, accent, fill);
        for (var i = 0; i < 4; i++) {
          final y = center.dy - scale * 0.36 + i * scale * 0.20;
          canvas.drawLine(
            Offset(center.dx - scale * 0.50, y),
            Offset(center.dx + scale * 0.42, y + scale * 0.08),
            i.isEven ? line : accent,
          );
          _paintDiamond(
            canvas,
            Offset(center.dx + scale * 0.46, y + scale * 0.08),
            scale * 0.035,
            fill,
          );
        }
        break;
      case 'jrpg':
        _paintDiamond(
          canvas,
          center.translate(0, -scale * 0.08),
          scale * 0.22,
          fill,
        );
        _paintDiamond(
          canvas,
          center.translate(0, -scale * 0.08),
          scale * 0.15,
          accent,
        );
        for (var i = 0; i < 7; i++) {
          _paintStar(
            canvas,
            center.translate(-scale * 0.42 + i * scale * 0.14, scale * 0.28),
            scale * (0.026 + (i % 2) * 0.008),
            i.isEven ? line : accent,
          );
        }
        final cursor = Path()
          ..moveTo(center.dx - scale * 0.54, center.dy - scale * 0.24)
          ..lineTo(center.dx - scale * 0.34, center.dy - scale * 0.10)
          ..lineTo(center.dx - scale * 0.54, center.dy + scale * 0.04)
          ..close();
        canvas.drawPath(cursor, fill);
        canvas.drawPath(cursor, line);
        break;
      case 'roguelike':
        final head = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center.translate(0, -scale * 0.06),
            width: scale * 0.58,
            height: scale * 0.44,
          ),
          Radius.circular(scale * 0.08),
        );
        canvas.drawRRect(head, fill);
        canvas.drawRRect(head, line);
        canvas.drawCircle(
          center.translate(-scale * 0.15, -scale * 0.08),
          scale * 0.050,
          accent,
        );
        canvas.drawCircle(
          center.translate(scale * 0.14, -scale * 0.06),
          scale * 0.034,
          line,
        );
        for (var i = 0; i < 4; i++) {
          final x = center.dx - scale * 0.20 + i * scale * 0.13;
          canvas.drawLine(
            Offset(x, center.dy + scale * 0.06),
            Offset(x + scale * 0.05, center.dy + scale * 0.18),
            i.isEven ? line : accent,
          );
        }
        final scrap = Path()
          ..moveTo(center.dx - scale * 0.45, center.dy + scale * 0.35)
          ..lineTo(center.dx + scale * 0.44, center.dy + scale * 0.26)
          ..lineTo(center.dx + scale * 0.34, center.dy + scale * 0.44)
          ..lineTo(center.dx - scale * 0.36, center.dy + scale * 0.48)
          ..close();
        canvas.drawPath(scrap, fill);
        canvas.drawPath(scrap, accent);
        break;
      case 'souls':
        final sword = Path()
          ..moveTo(center.dx, center.dy - scale * 0.54)
          ..lineTo(center.dx + scale * 0.06, center.dy + scale * 0.08)
          ..lineTo(center.dx, center.dy + scale * 0.48)
          ..lineTo(center.dx - scale * 0.06, center.dy + scale * 0.08)
          ..close();
        canvas.drawPath(sword, fill);
        canvas.drawPath(sword, line);
        canvas.drawLine(
          center.translate(-scale * 0.28, scale * 0.05),
          center.translate(scale * 0.28, scale * 0.05),
          accent,
        );
        for (var i = 0; i < 5; i++) {
          final ember = center.translate(
            -scale * 0.28 + i * scale * 0.14,
            scale * (0.36 - (i % 2) * 0.12),
          );
          canvas.drawCircle(ember, scale * 0.024, i.isEven ? accent : fill);
        }
        break;
      case 'bolted_metal':
        final plate = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: scale * 0.78,
            height: scale * 0.56,
          ),
          Radius.circular(scale * 0.05),
        );
        canvas.drawRRect(plate, fill);
        canvas.drawRRect(plate, line);
        for (final bolt in <Offset>[
          center.translate(-scale * 0.28, -scale * 0.18),
          center.translate(scale * 0.28, -scale * 0.18),
          center.translate(-scale * 0.28, scale * 0.18),
          center.translate(scale * 0.28, scale * 0.18),
        ]) {
          canvas.drawCircle(bolt, scale * 0.052, accent);
          canvas.drawLine(
            bolt.translate(-scale * 0.035, 0),
            bolt.translate(scale * 0.035, 0),
            line,
          );
        }
        if (spec.presetId.contains('copper')) {
          for (var i = 0; i < 3; i++) {
            _paintDiamond(
              canvas,
              center.translate(-scale * 0.18 + i * scale * 0.17, scale * 0.02),
              scale * 0.055,
              accent,
            );
          }
        } else {
          _paintDesktopMiniGear(
            canvas,
            center,
            scale * 0.15,
            line,
            accent,
            fill,
          );
        }
        break;
      case 'wild_companion':
        if (spec.presetId.contains('moth')) {
          final leftWing = Path()
            ..moveTo(center.dx, center.dy)
            ..cubicTo(
              center.dx - scale * 0.42,
              center.dy - scale * 0.36,
              center.dx - scale * 0.54,
              center.dy + scale * 0.18,
              center.dx - scale * 0.08,
              center.dy + scale * 0.22,
            )
            ..close();
          final rightWing = Path()
            ..moveTo(center.dx, center.dy)
            ..cubicTo(
              center.dx + scale * 0.42,
              center.dy - scale * 0.36,
              center.dx + scale * 0.54,
              center.dy + scale * 0.18,
              center.dx + scale * 0.08,
              center.dy + scale * 0.22,
            )
            ..close();
          canvas.drawPath(leftWing, fill);
          canvas.drawPath(rightWing, fill);
          canvas.drawPath(leftWing, line);
          canvas.drawPath(rightWing, line);
          canvas.drawLine(
            center.translate(0, -scale * 0.24),
            center.translate(0, scale * 0.34),
            accent,
          );
        } else {
          canvas.drawCircle(center, scale * 0.18, fill);
          canvas.drawCircle(center, scale * 0.18, line);
          for (final dir in <double>[-1, 1]) {
            _paintBotanicalLeaf(
              canvas,
              center.translate(dir * scale * 0.10, -scale * 0.03),
              dir,
              scale * 0.34,
              fill,
              accent,
            );
          }
          _paintTinyPanelStar(
            canvas,
            center.translate(0, -scale * 0.30),
            scale * 0.055,
            accent,
          );
        }
        break;
      case 'modern_school':
        final notebook = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center.translate(-scale * 0.02, scale * 0.02),
            width: scale * 0.72,
            height: scale * 0.52,
          ),
          Radius.circular(scale * 0.06),
        );
        canvas.drawRRect(notebook, fill);
        canvas.drawRRect(notebook, line);
        canvas.drawLine(
          center.translate(-scale * 0.22, -scale * 0.24),
          center.translate(-scale * 0.22, scale * 0.28),
          accent,
        );
        for (var i = 0; i < 5; i++) {
          final y = center.dy - scale * 0.17 + i * scale * 0.09;
          canvas.drawLine(
            Offset(center.dx - scale * 0.14, y),
            Offset(center.dx + scale * 0.30, y),
            i.isEven ? line : accent,
          );
        }
        final pen = Path()
          ..moveTo(center.dx + scale * 0.14, center.dy - scale * 0.42)
          ..lineTo(center.dx + scale * 0.42, center.dy - scale * 0.14)
          ..lineTo(center.dx + scale * 0.36, center.dy - scale * 0.08)
          ..lineTo(center.dx + scale * 0.08, center.dy - scale * 0.36)
          ..close();
        canvas.drawPath(pen, fill);
        canvas.drawPath(pen, accent);
        _paintTinyPanelStar(
          canvas,
          center.translate(-scale * 0.36, scale * 0.30),
          scale * 0.050,
          accent,
        );
        break;
      case 'medieval':
        _paintMedievalShield(canvas, center, scale * 0.24, fill, line);
        canvas.drawLine(
          center.translate(-scale * 0.40, -scale * 0.44),
          center.translate(scale * 0.26, scale * 0.40),
          accent,
        );
        canvas.drawLine(
          center.translate(scale * 0.34, -scale * 0.40),
          center.translate(-scale * 0.28, scale * 0.34),
          line,
        );
        break;
      case 'phobia':
        final eye = Path()
          ..moveTo(center.dx - scale * 0.48, center.dy)
          ..quadraticBezierTo(
            center.dx,
            center.dy - scale * 0.25,
            center.dx + scale * 0.48,
            center.dy,
          )
          ..quadraticBezierTo(
            center.dx,
            center.dy + scale * 0.25,
            center.dx - scale * 0.48,
            center.dy,
          );
        canvas.drawPath(eye, line);
        canvas.drawCircle(center, scale * 0.13, fill);
        canvas.drawCircle(
          center.translate(scale * 0.025, -scale * 0.015),
          scale * 0.045,
          accent,
        );
        for (var i = 0; i < 8; i++) {
          final angle = -pi * 0.78 + i * pi * 0.22;
          canvas.drawLine(
            center.translate(
              cos(angle) * scale * 0.44,
              sin(angle) * scale * 0.18,
            ),
            center.translate(
              cos(angle) * scale * 0.60,
              sin(angle) * scale * 0.30,
            ),
            i.isEven ? accent : line,
          );
        }
        break;
      case 'shadow_gate':
        canvas.drawArc(
          Rect.fromCenter(
            center: center,
            width: scale * 0.66,
            height: scale * 0.88,
          ),
          -pi * 0.16,
          pi * 1.34,
          false,
          accent,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: center,
            width: scale * 0.40,
            height: scale * 0.58,
          ),
          pi * 0.08,
          pi * 1.46,
          false,
          line,
        );
        _paintDiamond(canvas, center, scale * 0.11, fill);
        break;
      case 'frost':
        for (var i = 0; i < 6; i++) {
          final angle = i * pi / 3;
          canvas.drawLine(
            center.translate(
              cos(angle) * scale * 0.10,
              sin(angle) * scale * 0.10,
            ),
            center.translate(
              cos(angle) * scale * 0.42,
              sin(angle) * scale * 0.42,
            ),
            i.isEven ? line : accent,
          );
        }
        _paintStar(canvas, center, scale * 0.16, accent);
        break;
      case 'storm':
        final bolt = Path()
          ..moveTo(center.dx - scale * 0.12, center.dy - scale * 0.46)
          ..lineTo(center.dx + scale * 0.18, center.dy - scale * 0.06)
          ..lineTo(center.dx + scale * 0.03, center.dy - scale * 0.05)
          ..lineTo(center.dx + scale * 0.30, center.dy + scale * 0.42);
        canvas.drawPath(bolt, accent);
        canvas.drawCircle(
          center.translate(-scale * 0.20, scale * 0.22),
          scale * 0.07,
          fill,
        );
        break;
      case 'tide':
        for (var row = 0; row < 3; row++) {
          final y = center.dy - scale * 0.12 + row * scale * 0.16;
          final wave = Path()..moveTo(center.dx - scale * 0.52, y);
          for (
            var x = center.dx - scale * 0.52;
            x < center.dx + scale * 0.54;
            x += scale * 0.20
          ) {
            wave.quadraticBezierTo(
              x + scale * 0.10,
              y - scale * 0.09,
              x + scale * 0.20,
              y,
            );
          }
          canvas.drawPath(wave, row.isEven ? accent : line);
        }
        break;
      case 'ember':
        final flame = Path()
          ..moveTo(center.dx, center.dy - scale * 0.46)
          ..cubicTo(
            center.dx + scale * 0.34,
            center.dy - scale * 0.12,
            center.dx + scale * 0.18,
            center.dy + scale * 0.36,
            center.dx,
            center.dy + scale * 0.42,
          )
          ..cubicTo(
            center.dx - scale * 0.28,
            center.dy + scale * 0.16,
            center.dx - scale * 0.16,
            center.dy - scale * 0.18,
            center.dx,
            center.dy - scale * 0.46,
          )
          ..close();
        canvas.drawPath(flame, fill);
        canvas.drawPath(flame, accent);
        break;
      case 'archive':
        final book = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: scale * 0.72,
            height: scale * 0.46,
          ),
          Radius.circular(scale * 0.05),
        );
        canvas.drawRRect(book, fill);
        canvas.drawRRect(book, line);
        canvas.drawLine(
          center.translate(0, -scale * 0.22),
          center.translate(0, scale * 0.22),
          accent,
        );
        for (var i = 0; i < 4; i++) {
          canvas.drawLine(
            center.translate(-scale * 0.28, -scale * 0.14 + i * scale * 0.09),
            center.translate(-scale * 0.04, -scale * 0.20 + i * scale * 0.09),
            accent,
          );
        }
        break;
      case 'slime':
        canvas.drawOval(
          Rect.fromCenter(
            center: center.translate(0, scale * 0.08),
            width: scale * 0.78,
            height: scale * 0.52,
          ),
          fill,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: center.translate(0, scale * 0.08),
            width: scale * 0.78,
            height: scale * 0.52,
          ),
          line,
        );
        _paintCrown(
          canvas,
          center.translate(0, -scale * 0.20),
          scale * 0.42,
          scale * 0.24,
          accent,
          line,
          fill,
        );
        canvas.drawCircle(
          center.translate(-scale * 0.15, scale * 0.02),
          scale * 0.035,
          accent,
        );
        canvas.drawCircle(
          center.translate(scale * 0.15, scale * 0.02),
          scale * 0.035,
          accent,
        );
        break;
      case 'obser':
      case 'sigil':
        canvas.drawCircle(center, scale * 0.26, line);
        _paintDiamond(canvas, center, scale * 0.19, accent);
        _paintDiamond(canvas, center, scale * 0.09, fill);
        break;
      default:
        _paintDiamond(canvas, center, scale * 0.28, fill);
        _paintDiamond(canvas, center, scale * 0.18, accent);
        canvas.drawArc(
          Rect.fromCenter(
            center: center.translate(-scale * 0.18, -scale * 0.04),
            width: scale * 0.56,
            height: scale * 0.56,
          ),
          -pi * 0.50,
          pi * 1.35,
          false,
          line,
        );
    }
  }

  void _paintResponsiveDetailLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    if (!desktop || size.width < 720) {
      if (spec.style == 'lunar' || spec.style == 'hoshy') {
        for (var i = 0; i < 4; i++) {
          _paintStar(
            canvas,
            Offset(size.width - edge * 0.30, 70 + i * 58),
            4 + i % 2,
            i.isEven ? accent : paint,
          );
        }
      } else if (spec.style == 'postea') {
        for (var i = 0; i < 4; i++) {
          final c = Offset(size.width - edge * 0.34, 74 + i * 48);
          canvas.drawLine(c.translate(-18, 0), c.translate(18, 0), accent);
          _paintDiamond(canvas, c, 5, i.isEven ? fill : paint);
        }
      } else if (spec.style == 'medieval') {
        for (var i = 0; i < 3; i++) {
          final c = Offset(size.width - edge * 0.32, 76 + i * 56);
          _paintMedievalShield(canvas, c, 18, i.isEven ? fill : paint, accent);
          canvas.drawLine(c.translate(-20, -20), c.translate(16, 24), paint);
        }
      } else if (spec.style == 'shadow_gate') {
        final c = Offset(size.width - edge * 0.34, size.height * 0.36);
        canvas.drawArc(
          Rect.fromCenter(center: c, width: 54, height: 72),
          -pi * 0.18,
          pi * 1.36,
          false,
          accent,
        );
        _paintDiamond(canvas, c, 6, fill);
      } else if (spec.style == 'jrpg') {
        for (var i = 0; i < 5; i++) {
          final c = Offset(size.width - edge * 0.34, 66 + i * 46);
          _paintStar(canvas, c, 4.2 + i % 2, i.isEven ? accent : paint);
          _paintDiamond(canvas, c.translate(-18, 18), 5, fill);
        }
      } else if (spec.style == 'roguelike') {
        for (var i = 0; i < 5; i++) {
          final c = Offset(size.width - edge * 0.34, 70 + i * 46);
          canvas.drawLine(c.translate(-18, -8), c.translate(18, 8), accent);
          canvas.drawCircle(c.translate(-8, 12), 3.5, fill);
        }
      } else if (spec.style == 'souls') {
        for (var i = 0; i < 4; i++) {
          final c = Offset(size.width - edge * 0.34, 76 + i * 58);
          canvas.drawLine(c.translate(0, -22), c.translate(0, 24), paint);
          canvas.drawArc(
            Rect.fromCircle(center: c, radius: 15),
            -pi * 0.7,
            pi * 1.4,
            false,
            accent,
          );
        }
      } else if (spec.style == 'bolted_metal') {
        for (var i = 0; i < 5; i++) {
          final c = Offset(size.width - edge * 0.34, 66 + i * 46);
          canvas.drawCircle(c, 7, fill);
          canvas.drawCircle(c, 11, accent);
          canvas.drawLine(c.translate(-7, 0), c.translate(7, 0), paint);
        }
      } else if (spec.style == 'wild_companion') {
        for (var i = 0; i < 5; i++) {
          final c = Offset(size.width - edge * 0.34, 66 + i * 45);
          _paintBotanicalLeaf(canvas, c, i.isEven ? 1 : -1, 18, fill, accent);
          if (i % 2 == 0) _paintStar(canvas, c.translate(-18, 18), 3.8, paint);
        }
      } else if (spec.style == 'modern_school') {
        for (var i = 0; i < 5; i++) {
          final y = 62 + i * 44.0;
          canvas.drawLine(
            Offset(size.width - edge * 0.48, y),
            Offset(size.width - edge * 0.18, y + (i.isEven ? 3 : -3)),
            i.isEven ? accent : paint,
          );
          _paintTinyPanelStar(
            canvas,
            Offset(size.width - edge * 0.52, y + 6),
            3.8,
            i.isEven ? paint : accent,
          );
        }
      }
      return;
    }

    switch (spec.style) {
      case 'vervain':
        _paintDesktopVervainLayer(canvas, size, edge, paint, accent, fill);
        break;
      case 'kingi':
        _paintDesktopKingiLayer(canvas, size, edge, paint, accent, fill);
        break;
      case 'postea':
        _paintDesktopPosteaLayer(canvas, size, edge, paint, accent, fill);
        break;
      case 'jrpg':
        _paintDesktopJrpgLayer(canvas, size, edge, paint, accent, fill);
        break;
      case 'roguelike':
        _paintDesktopRoguelikeLayer(canvas, size, edge, paint, accent, fill);
        break;
      case 'souls':
        _paintDesktopSoulsLayer(canvas, size, edge, paint, accent, fill);
        break;
      case 'bolted_metal':
        _paintDesktopBoltedMetalLayer(canvas, size, edge, paint, accent, fill);
        break;
      case 'wild_companion':
        _paintDesktopWildCompanionLayer(
          canvas,
          size,
          edge,
          paint,
          accent,
          fill,
        );
        break;
      case 'modern_school':
        _paintDesktopModernSchoolLayer(canvas, size, edge, paint, accent, fill);
        break;
      case 'medieval':
        _paintDesktopMedievalLayer(canvas, size, edge, paint, accent, fill);
        break;
      case 'phobia':
        _paintDesktopPhobiaLayer(canvas, size, edge, paint, accent, fill);
        break;
      case 'shadow_gate':
        _paintDesktopShadowGateLayer(canvas, size, edge, paint, accent, fill);
        break;
      case 'lunar':
        _paintDesktopLunarLayer(canvas, size, edge, paint, accent, fill);
        break;
      case 'cathedral':
        _paintDesktopCathedralLayer(canvas, size, edge, paint, accent, fill);
        break;
      case 'storm':
        _paintDesktopStormLayer(canvas, size, edge, paint, accent);
        break;
      case 'archive':
        _paintDesktopArchiveLayer(canvas, size, edge, paint, accent, fill);
        break;
      case 'frost':
        _paintDesktopFrostLayer(canvas, size, edge, paint, accent);
        break;
      case 'tide':
        _paintDesktopTideLayer(canvas, size, edge, paint, accent, fill);
        break;
      case 'ember':
        _paintDesktopEmberLayer(canvas, size, edge, paint, accent, fill);
        break;
      default:
        _paintDesktopOrnamentLayer(canvas, size, edge, paint, accent, fill);
    }
    _paintDesktopFiligreeLayer(canvas, size, edge, paint, accent, fill);
  }

  void _paintThemeBackdropWash(Canvas canvas, Size size) {
    final baseAlpha = (spec.opacity * (desktop ? 1.08 : 0.78))
        .clamp(0.055, desktop ? 0.30 : 0.18)
        .toDouble();
    final rect = Offset.zero & size;
    final center = switch (spec.style) {
      'postea' || 'kingi' || 'medieval' => Alignment.topRight,
      'jrpg' => Alignment.bottomRight,
      'roguelike' => Alignment.centerRight,
      'souls' => Alignment.center,
      'bolted_metal' => Alignment.topCenter,
      'wild_companion' => Alignment.bottomRight,
      'modern_school' => Alignment.centerRight,
      'phobia' || 'shadow_gate' => Alignment.center,
      'vervain' || 'thorn' => Alignment.bottomLeft,
      'hoshy' || 'slime' => Alignment.bottomRight,
      'lunar' => Alignment.topCenter,
      _ => Alignment.bottomCenter,
    };
    final accentWash = Paint()
      ..shader = RadialGradient(
        center: center,
        radius: desktop ? 0.95 : 1.15,
        colors: [
          spec.accent.withValues(alpha: baseAlpha),
          spec.secondary.withValues(alpha: baseAlpha * 0.34),
          Colors.transparent,
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, accentWash);

    final sideWash = Paint()
      ..shader = LinearGradient(
        colors: [
          spec.primary.withValues(alpha: baseAlpha * 0.36),
          Colors.transparent,
          spec.secondary.withValues(alpha: baseAlpha * 0.42),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, sideWash);

    if (desktop) {
      final horizon = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..color = spec.primary.withValues(alpha: baseAlpha * 0.72);
      final y = size.height - min(96.0, max(54.0, size.height * 0.09));
      final line = Path()..moveTo(size.width * 0.08, y);
      for (var x = size.width * 0.08; x < size.width * 0.92; x += 72) {
        line.cubicTo(x + 18, y - 18, x + 48, y + 16, x + 72, y);
      }
      canvas.drawPath(line, horizon);
    }
  }

  void _paintDesktopVervainLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final botanical = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = _oculumReverseBackgroundShader(
        spec,
        size,
        spec.secondary,
        (spec.opacity * 1.32).clamp(0.10, 0.34).toDouble(),
      );
    final flowerFill = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * 1.18).clamp(0.08, 0.24).toDouble(),
      );
    final vine = Path()..moveTo(edge * 0.18, size.height - 48);
    for (var x = edge * 0.18; x < size.width - edge * 0.18; x += 92) {
      vine.cubicTo(
        x + 28,
        size.height - 92,
        x + 54,
        size.height - 8,
        x + 92,
        size.height - 46,
      );
    }
    canvas.drawPath(vine, botanical);
    final canopy = Path()..moveTo(edge * 0.22, 34);
    for (var x = edge * 0.22; x < size.width - edge * 0.20; x += 86) {
      canopy.cubicTo(x + 18, 66, x + 58, 10, x + 86, 38);
    }
    canvas.drawPath(canopy, botanical);
    for (var i = 0; i < 11; i++) {
      final x = edge * 0.28 + i * 84;
      if (x > size.width - edge * 0.20) break;
      final y = size.height - 52 - (i % 3) * 12;
      _paintBotanicalLeaf(
        canvas,
        Offset(x, y),
        i.isEven ? 1 : -1,
        26,
        botanical,
        accent,
      );
      if (i % 2 == 0) {
        _paintVervainFlower(
          canvas,
          Offset(x + 28, y - 15),
          11,
          flowerFill,
          accent,
          fill,
        );
      }
      _paintFineThorn(
        canvas,
        Offset(x + 16, y + 8),
        i.isEven ? 1 : -1,
        18,
        paint,
      );
    }
    for (var i = 0; i < 8; i++) {
      final x = edge * 0.36 + i * 96;
      if (x > size.width - edge * 0.28) break;
      final y = 42.0 + (i % 3) * 12.0;
      _paintBotanicalLeaf(
        canvas,
        Offset(x, y),
        i.isEven ? 1 : -1,
        22,
        botanical,
        accent,
      );
      _paintVervainFlower(
        canvas,
        Offset(x + (i.isEven ? 22 : -22), y + 12),
        8.5,
        flowerFill,
        accent,
        fill,
      );
    }
  }

  void _paintDesktopKingiLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final electric = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.45
      ..color = const Color(
        0xFF16C8FF,
      ).withValues(alpha: (spec.opacity * 1.48).clamp(0.10, 0.36).toDouble());
    for (var y = size.height * 0.18; y < size.height * 0.82; y += 94) {
      final left = Path()
        ..moveTo(edge * 0.58, y)
        ..lineTo(edge * 0.84, y - 24)
        ..lineTo(edge * 0.74, y - 24)
        ..lineTo(edge * 1.05, y - 58);
      final right = Path()
        ..moveTo(size.width - edge * 0.58, y + 14)
        ..lineTo(size.width - edge * 0.86, y - 8)
        ..lineTo(size.width - edge * 0.75, y - 9)
        ..lineTo(size.width - edge * 1.06, y - 42);
      canvas.drawPath(left, electric);
      canvas.drawPath(right, electric);
    }
    for (var i = 0; i < 6; i++) {
      final center = Offset(
        edge * 0.30 + i * 42,
        size.height - 44 - (i % 2) * 12,
      );
      _paintDesktopMiniGear(
        canvas,
        center,
        13 + (i % 2) * 3,
        paint,
        electric,
        fill,
      );
    }
  }

  void _paintDesktopPosteaLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final circuit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.24
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * 1.42).clamp(0.10, 0.33).toDouble(),
      );
    for (var row = 0; row < 5; row++) {
      final y = size.height * (0.16 + row * 0.14);
      final left = Path()
        ..moveTo(edge * 0.24, y)
        ..lineTo(edge * 0.62, y)
        ..lineTo(edge * 0.78, y + 24)
        ..lineTo(edge * 1.12, y + 24);
      final right = Path()
        ..moveTo(size.width - edge * 0.24, y + 18)
        ..lineTo(size.width - edge * 0.62, y + 18)
        ..lineTo(size.width - edge * 0.78, y - 8)
        ..lineTo(size.width - edge * 1.10, y - 8);
      canvas.drawPath(left, row.isEven ? circuit : paint);
      canvas.drawPath(right, row.isEven ? paint : circuit);
      _paintDiamond(canvas, Offset(edge * 0.78, y + 24), 7, fill);
      _paintDiamond(canvas, Offset(size.width - edge * 0.78, y - 8), 7, fill);
      if (row.isEven) {
        _paintSyntheticBloom(
          canvas,
          Offset(edge * 1.20, y + 24),
          12,
          circuit,
          accent,
          fill,
        );
        _paintSyntheticBloom(
          canvas,
          Offset(size.width - edge * 1.18, y - 8),
          10,
          paint,
          circuit,
          fill,
        );
      }
    }
    for (var i = 0; i < 6; i++) {
      _paintDesktopMiniGear(
        canvas,
        Offset(size.width - edge * 0.34, 76 + i * 52),
        11 + i % 2 * 3,
        paint,
        circuit,
        fill,
      );
    }
    for (var i = 0; i < 4; i++) {
      final c = Offset(edge * 0.42 + i * 34, size.height - 42 - (i % 2) * 18);
      canvas.drawLine(c.translate(-18, 0), c.translate(18, 0), circuit);
      _paintSyntheticBloom(canvas, c, 9, paint, accent, fill);
    }
  }

  void _paintDesktopJrpgLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final crystal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.22
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * 1.30).clamp(0.09, 0.30).toDouble(),
      );
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.05
      ..color = const Color(
        0xFFE7B84A,
      ).withValues(alpha: (spec.opacity * 1.10).clamp(0.08, 0.24).toDouble());

    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < 7; i++) {
        final c = Offset(side + dir * edge * 0.42, 68 + i * 58);
        _paintDiamond(canvas, c, 12 + i % 2 * 3, i.isEven ? fill : accent);
        canvas.drawLine(
          c.translate(-dir * 24, -16),
          c,
          i.isEven ? crystal : gold,
        );
        canvas.drawLine(
          c,
          c.translate(dir * 22, 18),
          i.isEven ? gold : crystal,
        );
        if (i % 2 == 0) {
          _paintStar(canvas, c.translate(dir * 36, -22), 5, crystal);
        }
      }
    }

    final bottom = Path()..moveTo(edge * 0.26, size.height - 46);
    for (var x = edge * 0.26; x < size.width - edge * 0.26; x += 82) {
      bottom.cubicTo(
        x + 20,
        size.height - 76,
        x + 58,
        size.height - 18,
        x + 82,
        size.height - 46,
      );
    }
    canvas.drawPath(bottom, crystal);
    for (var i = 0; i < 9; i++) {
      final x = edge * 0.36 + i * ((size.width - edge * 0.72) / 8);
      _paintStar(
        canvas,
        Offset(x, size.height - 42 - (i % 3) * 16),
        4.5 + i % 2,
        i.isEven ? gold : crystal,
      );
    }
  }

  void _paintDesktopRoguelikeLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final scratch = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.12
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * 1.18).clamp(0.08, 0.27).toDouble(),
      );
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < 8; i++) {
        final y = size.height * (0.10 + i * 0.105);
        final c = Offset(side + dir * edge * (0.28 + (i % 3) * 0.08), y);
        canvas.drawLine(
          c.translate(-dir * 14, -16),
          c.translate(dir * 28, 12),
          i.isEven ? scratch : paint,
        );
        canvas.drawCircle(c.translate(dir * 22, 16), 3.6 + i % 3, fill);
      }
    }
    for (var i = 0; i < 10; i++) {
      final c = Offset(edge * 0.28 + i * 44, size.height - 46 - (i % 3) * 15);
      canvas.drawLine(c.translate(-16, 5), c.translate(16, -5), scratch);
      canvas.drawCircle(c, 3.0, i.isEven ? fill : accent);
    }
  }

  void _paintDesktopSoulsLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final ember = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.18
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * 1.16).clamp(0.08, 0.26).toDouble(),
      );
    canvas.drawLine(
      Offset(edge * 0.30, 42),
      Offset(size.width - edge * 0.30, 42),
      ember,
    );
    canvas.drawLine(
      Offset(edge * 0.30, size.height - 42),
      Offset(size.width - edge * 0.30, size.height - 42),
      paint,
    );
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < 6; i++) {
        final c = Offset(
          side + dir * edge * 0.40,
          size.height * (0.15 + i * 0.13),
        );
        canvas.drawLine(
          c.translate(0, -28),
          c.translate(0, 34),
          i.isEven ? ember : paint,
        );
        canvas.drawLine(
          c.translate(-dir * 18, 4),
          c.translate(dir * 18, 4),
          i.isEven ? paint : ember,
        );
        canvas.drawCircle(c.translate(0, 36), 3.2, fill);
      }
    }
  }

  void _paintDesktopBoltedMetalLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final metal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.05
      ..color = spec.primary.withValues(
        alpha: (spec.opacity * 1.16).clamp(0.08, 0.28).toDouble(),
      );
    for (var x = edge * 0.26; x < size.width - edge * 0.22; x += 92) {
      canvas.drawLine(Offset(x, 30), Offset(x, size.height - 30), metal);
    }
    for (var y = 38.0; y < size.height - 30; y += 76) {
      canvas.drawLine(
        Offset(edge * 0.20, y),
        Offset(size.width - edge * 0.20, y),
        accent,
      );
    }
    for (var i = 0; i < 16; i++) {
      final c = Offset(
        edge * 0.24 +
            (i * 101 % max(1, (size.width - edge).round())).toDouble(),
        54.0 + (i * 59 % max(1, (size.height - 108).round())).toDouble(),
      );
      canvas.drawCircle(c, 5.2, fill);
      canvas.drawCircle(c, 8.4, metal);
      canvas.drawLine(c.translate(-5, 0), c.translate(5, 0), accent);
    }
  }

  void _paintDesktopWildCompanionLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final vine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.20
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * 1.10).clamp(0.08, 0.25).toDouble(),
      );
    final bottom = Path()..moveTo(edge * 0.22, size.height - 48);
    for (var x = edge * 0.22; x < size.width - edge * 0.22; x += 88) {
      bottom.cubicTo(
        x + 26,
        size.height - 88,
        x + 62,
        size.height - 12,
        x + 88,
        size.height - 48,
      );
    }
    canvas.drawPath(bottom, vine);
    for (var i = 0; i < 12; i++) {
      final c = Offset(edge * 0.30 + i * 72, 54 + (i % 4) * 13);
      if (c.dx > size.width - edge * 0.28) break;
      _paintBotanicalLeaf(canvas, c, i.isEven ? 1 : -1, 22, fill, vine);
      if (i % 3 == 0) _paintStar(canvas, c.translate(26, 10), 4.2, accent);
    }
  }

  void _paintDesktopModernSchoolLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final notebookLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.05
      ..color = spec.primary.withValues(
        alpha: (spec.opacity * 1.05).clamp(0.08, 0.25).toDouble(),
      );
    final pinkInk = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.18
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * 1.20).clamp(0.08, 0.28).toDouble(),
      );

    for (var y = 54.0; y < size.height - 42; y += 46) {
      canvas.drawLine(
        Offset(edge * 0.22, y),
        Offset(size.width - edge * 0.22, y + ((y ~/ 46).isEven ? 2 : -2)),
        notebookLine,
      );
    }
    canvas.drawLine(
      Offset(edge * 0.42, 32),
      Offset(edge * 0.42, size.height - 34),
      pinkInk,
    );
    for (var i = 0; i < 7; i++) {
      final c = Offset(size.width - edge * 0.34, 58 + i * 54.0);
      final sticker = RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: 34, height: 22),
        const Radius.circular(5),
      );
      canvas.drawRRect(sticker, i.isEven ? fill : accent);
      canvas.drawRRect(sticker, i.isEven ? pinkInk : notebookLine);
      canvas.drawLine(c.translate(-10, 2), c.translate(10, -3), pinkInk);
    }
    for (var i = 0; i < 8; i++) {
      final x = edge * 0.58 + i * ((size.width - edge * 1.16) / 7);
      final y = size.height - 46 - (i % 3) * 14.0;
      _paintTinyPanelStar(
        canvas,
        Offset(x, y),
        4.0 + (i % 2),
        i.isEven ? pinkInk : notebookLine,
      );
    }
  }

  void _paintDesktopMedievalLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final stone = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.18
      ..color = spec.primary.withValues(
        alpha: (spec.opacity * 1.25).clamp(0.08, 0.30).toDouble(),
      );
    final banner = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(
        0xFF7F2630,
      ).withValues(alpha: (spec.opacity * 0.92).clamp(0.05, 0.18).toDouble());
    for (var row = 0; row < 5; row++) {
      final y = size.height * (0.16 + row * 0.13);
      for (final side in <double>[0, size.width]) {
        final dir = side == 0 ? 1.0 : -1.0;
        final x = side + dir * edge * (0.30 + (row % 3) * 0.11);
        final shieldCenter = Offset(x, y);
        _paintMedievalShield(
          canvas,
          shieldCenter,
          20 + (row % 2) * 4,
          row.isEven ? fill : banner,
          row.isEven ? accent : stone,
        );
        canvas.drawLine(
          shieldCenter.translate(-dir * 28, -26),
          shieldCenter.translate(dir * 20, 30),
          row.isEven ? stone : accent,
        );
      }
    }

    final keepBase = Rect.fromLTWH(
      size.width / 2 - 72,
      size.height - 116,
      144,
      92,
    );
    canvas.drawRect(keepBase, fill);
    canvas.drawRect(keepBase, stone);
    for (var i = 0; i < 6; i++) {
      final merlon = Rect.fromLTWH(
        keepBase.left + 5 + i * 23,
        keepBase.top - 18,
        14,
        20,
      );
      canvas.drawRect(merlon, i.isEven ? fill : banner);
      canvas.drawRect(merlon, stone);
    }
    for (var row = 0; row < 4; row++) {
      final y = keepBase.top + 12 + row * 18;
      for (
        var x = keepBase.left + 10 + (row.isEven ? 0 : 18);
        x < keepBase.right - 18;
        x += 34
      ) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x + 22, y),
          row.isEven ? accent : stone,
        );
      }
    }
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(keepBase.center.dx, keepBase.bottom),
        width: 38,
        height: 58,
      ),
      pi,
      pi,
      false,
      accent,
    );
  }

  void _paintDesktopShadowGateLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * 1.52).clamp(0.09, 0.32).toDouble(),
      );
    for (var i = 0; i < 5; i++) {
      final w = size.width * (0.20 + i * 0.045);
      final h = size.height * (0.34 + i * 0.05);
      canvas.drawArc(
        Rect.fromCenter(center: center, width: w, height: h),
        -pi * (0.17 + i * 0.02),
        pi * 1.34,
        false,
        i.isEven ? glow : paint,
      );
    }
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < 8; i++) {
        final y = size.height * (0.10 + i * 0.105);
        final c = Offset(side + dir * edge * 0.46, y);
        canvas.drawLine(
          c.translate(-dir * 20, -18),
          c.translate(dir * 20, 18),
          accent,
        );
        canvas.drawLine(
          c.translate(dir * 20, -18),
          c.translate(-dir * 20, 18),
          paint,
        );
        _paintDiamond(canvas, c, 6, i.isEven ? fill : accent);
      }
    }
  }

  void _paintDesktopMiniGear(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.40, fill);
    for (var i = 0; i < 12; i++) {
      final angle = i * pi / 6;
      canvas.drawLine(
        center.translate(
          cos(angle) * radius * 0.62,
          sin(angle) * radius * 0.62,
        ),
        center.translate(cos(angle) * (radius + 5), sin(angle) * (radius + 5)),
        i.isEven ? accent : paint,
      );
    }
  }

  void _paintDesktopPhobiaLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    for (var i = 0; i < 6; i++) {
      final eye = Offset(
        size.width - edge * 0.44,
        size.height * (0.16 + i * 0.12),
      );
      final path = Path()
        ..moveTo(eye.dx - 30, eye.dy)
        ..quadraticBezierTo(eye.dx, eye.dy - 14, eye.dx + 30, eye.dy)
        ..quadraticBezierTo(eye.dx, eye.dy + 14, eye.dx - 30, eye.dy);
      canvas.drawPath(path, i.isEven ? paint : accent);
      canvas.drawCircle(eye, 6, fill);
    }
    for (var i = 0; i < 9; i++) {
      final x = edge * 0.24 + i * 18;
      final claw = Path()
        ..moveTo(x, size.height - 12)
        ..quadraticBezierTo(x + 26, size.height - 88, x + 10, size.height - 138)
        ..quadraticBezierTo(x + 40, size.height - 86, x + 34, size.height - 20);
      canvas.drawPath(claw, i.isEven ? accent : paint);
    }
  }

  void _paintDesktopLunarLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    for (var i = 0; i < 8; i++) {
      _paintOculumMoonPhase(
        canvas,
        Offset(size.width - edge * 0.40, 82 + i * 44),
        13,
        i,
        accent,
        fill,
        paint,
      );
    }
    for (var i = 0; i < 22; i++) {
      _paintStar(
        canvas,
        Offset(
          edge * 0.34 + (i * 73 % (size.width - edge).round()),
          50 + (i * 37 % 250),
        ),
        2.8 + (i % 3),
        i.isEven ? accent : paint,
      );
    }
  }

  void _paintDesktopCathedralLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    for (var i = 0; i < 4; i++) {
      final rect = Rect.fromCenter(
        center: Offset(edge * 0.42 + i * 42, size.height * 0.50),
        width: 34,
        height: 128,
      );
      canvas.drawArc(rect, pi, pi, false, i.isEven ? paint : accent);
      canvas.drawLine(rect.topCenter, rect.bottomCenter, accent);
      canvas.drawLine(rect.centerLeft, rect.centerRight, paint);
    }
    for (var i = 0; i < 5; i++) {
      final c = Offset(size.width - edge * 0.42, 90 + i * 74);
      canvas.drawCircle(c, 18, paint);
      canvas.drawCircle(c, 8, fill);
      _paintDiamond(canvas, c, 12, accent);
    }
  }

  void _paintDesktopStormLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
  ) {
    for (var i = 0; i < 9; i++) {
      final x = edge * 0.36 + i * 54;
      final bolt = Path()
        ..moveTo(x, 34)
        ..lineTo(x + 30, 86)
        ..lineTo(x + 12, 86)
        ..lineTo(x + 42, 154);
      canvas.drawPath(bolt, i.isEven ? accent : paint);
    }
  }

  void _paintDesktopArchiveLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    for (var i = 0; i < 8; i++) {
      final book = Rect.fromLTWH(
        edge * 0.18 + i * 18,
        size.height - 118,
        12,
        86,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(book, const Radius.circular(2)),
        i.isEven ? fill : paint,
      );
      canvas.drawLine(
        book.topCenter.translate(0, 8),
        book.bottomCenter.translate(0, -8),
        accent,
      );
    }
    for (var i = 0; i < 10; i++) {
      _paintDiamond(
        canvas,
        Offset(size.width - edge * 0.38, 70 + i * 44),
        5,
        i.isEven ? accent : paint,
      );
    }
  }

  void _paintDesktopFrostLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
  ) {
    for (var i = 0; i < 10; i++) {
      final c = Offset(size.width - edge * 0.38, 56 + i * 50);
      final r = 12.0 + (i % 3) * 4;
      canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), paint);
      canvas.drawLine(c.translate(0, -r), c.translate(0, r), accent);
      canvas.drawLine(
        c.translate(-r * .7, -r * .7),
        c.translate(r * .7, r * .7),
        paint,
      );
      canvas.drawLine(
        c.translate(-r * .7, r * .7),
        c.translate(r * .7, -r * .7),
        accent,
      );
    }
  }

  void _paintDesktopTideLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    for (var row = 0; row < 3; row++) {
      final y = size.height - 42 - row * 34;
      final wave = Path()..moveTo(edge * 0.20, y);
      for (var x = edge * 0.20; x < size.width - edge * 0.20; x += 48) {
        wave.quadraticBezierTo(x + 24, y - 22, x + 48, y);
      }
      canvas.drawPath(wave, row.isEven ? accent : paint);
    }
    for (var i = 0; i < 12; i++) {
      canvas.drawCircle(
        Offset(size.width - edge * 0.36, 52 + i * 34),
        3 + i % 3,
        fill,
      );
    }
  }

  void _paintDesktopEmberLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    for (var i = 0; i < 9; i++) {
      final base = Offset(edge * 0.22 + i * 26, size.height - 36);
      canvas.drawRect(
        Rect.fromCenter(center: base, width: 9, height: 34),
        paint,
      );
      final flame = Path()
        ..moveTo(base.dx, base.dy - 54)
        ..quadraticBezierTo(base.dx + 18, base.dy - 24, base.dx, base.dy - 8)
        ..quadraticBezierTo(base.dx - 18, base.dy - 26, base.dx, base.dy - 54);
      canvas.drawPath(flame, i.isEven ? accent : fill);
    }
  }

  void _paintDesktopOrnamentLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    for (var i = 0; i < 12; i++) {
      final c = Offset(size.width - edge * 0.38, 58 + i * 36);
      canvas.drawCircle(c, 10 + i % 3, i.isEven ? paint : accent);
      _paintDiamond(canvas, c, 6, i.isEven ? accent : fill);
    }
  }

  void _paintDesktopFiligreeLayer(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final paletteBoost = spec.usesBaseColors ? 0.88 : 1.08;
    final fine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 0.72
      ..color = spec.primary.withValues(
        alpha: (spec.opacity * paletteBoost).clamp(0.08, 0.24).toDouble(),
      );
    final bright = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 0.88
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * 0.92 * paletteBoost)
            .clamp(0.07, 0.22)
            .toDouble(),
      );
    final dust = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.secondary.withValues(
        alpha: (spec.opacity * 0.42).clamp(0.035, 0.12).toDouble(),
      );

    for (final side in <double>[1, -1]) {
      final x = side > 0 ? edge * 0.22 : size.width - edge * 0.22;
      final path = Path()..moveTo(x, size.height * 0.08);
      for (var y = size.height * 0.08; y < size.height * 0.92; y += 96) {
        path.cubicTo(x + side * 22, y + 32, x - side * 18, y + 64, x, y + 96);
      }
      canvas.drawPath(path, fine);
      for (var i = 0; i < 7; i++) {
        final y = size.height * (0.14 + i * 0.115);
        final c = Offset(x + side * (18 + (i % 3) * 8), y);
        if (spec.style == 'phobia') {
          canvas.drawLine(c.translate(-side * 16, -12), c, bright);
          canvas.drawLine(c, c.translate(side * 10, 18), fine);
        } else if (spec.style == 'kingi') {
          canvas.drawCircle(c, 5.5, bright);
          canvas.drawLine(c.translate(-side * 24, 0), c, fine);
          canvas.drawLine(
            c,
            c.translate(side * 18, (i.isEven ? -1 : 1) * 16),
            bright,
          );
        } else if (spec.style == 'vervain' || spec.style == 'thorn') {
          _paintBotanicalLeaf(canvas, c, side, 16, fine, bright);
        } else {
          _paintDiamond(canvas, c, 5.5, i.isEven ? bright : fine);
        }
      }
    }

    final topRail = Path()..moveTo(edge * 0.38, 26);
    for (var x = edge * 0.38; x < size.width - edge * 0.38; x += 72) {
      topRail.cubicTo(x + 18, 8, x + 52, 44, x + 72, 26);
    }
    final bottomRail = Path()..moveTo(edge * 0.38, size.height - 26);
    for (var x = edge * 0.38; x < size.width - edge * 0.38; x += 72) {
      bottomRail.cubicTo(
        x + 18,
        size.height - 44,
        x + 52,
        size.height - 8,
        x + 72,
        size.height - 26,
      );
    }
    canvas.drawPath(topRail, fine);
    canvas.drawPath(bottomRail, bright);

    final speckCount = spec.usesBaseColors ? 18 : 26;
    final speckWidth = max(1, (size.width - edge * 0.68).round());
    final speckHeight = max(1, (size.height - 88).round());
    for (var i = 0; i < speckCount; i++) {
      final x = edge * 0.34 + (i * 97 % speckWidth).toDouble();
      final y = 44.0 + (i * 61 % speckHeight).toDouble();
      canvas.drawCircle(Offset(x, y), 1.2 + (i % 3) * 0.45, dust);
    }
  }

  void _paintStar(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.52, center.dy - radius * 0.52),
      Offset(center.dx + radius * 0.52, center.dy + radius * 0.52),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.52, center.dy + radius * 0.52),
      Offset(center.dx + radius * 0.52, center.dy - radius * 0.52),
      paint,
    );
  }

  void _paintDiamond(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * 0.68, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius * 0.68, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _paintBotanicalLeaf(
    Canvas canvas,
    Offset base,
    double dir,
    double length,
    Paint fill,
    Paint vein,
  ) {
    final tip = base.translate(dir * length, -length * 0.08);
    final leaf = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
        base.dx + dir * length * 0.34,
        base.dy - length * 0.34,
        base.dx + dir * length * 0.76,
        base.dy - length * 0.24,
        tip.dx,
        tip.dy,
      )
      ..cubicTo(
        base.dx + dir * length * 0.74,
        base.dy + length * 0.28,
        base.dx + dir * length * 0.32,
        base.dy + length * 0.34,
        base.dx,
        base.dy,
      )
      ..close();
    canvas.drawPath(leaf, fill);
    canvas.drawLine(base.translate(dir * 4, 0), tip, vein);
    for (var i = 1; i <= 4; i++) {
      final t = i / 5;
      final mid = Offset(
        base.dx + (tip.dx - base.dx) * t,
        base.dy + (tip.dy - base.dy) * t,
      );
      canvas.drawLine(
        mid,
        mid.translate(dir * length * 0.12, -length * (0.09 + i * 0.01)),
        vein,
      );
      canvas.drawLine(
        mid,
        mid.translate(dir * length * 0.11, length * (0.08 + i * 0.01)),
        vein,
      );
    }
  }

  void _paintVervainFlower(
    Canvas canvas,
    Offset center,
    double radius,
    Paint petal,
    Paint accent,
    Paint core,
  ) {
    for (var p = 0; p < 8; p++) {
      final angle = p * pi / 4;
      final petalRect = Rect.fromCenter(
        center: Offset(
          center.dx + cos(angle) * radius * 0.72,
          center.dy + sin(angle) * radius * 0.50,
        ),
        width: radius * 0.80,
        height: radius * 0.34,
      );
      canvas.save();
      canvas.translate(petalRect.center.dx, petalRect.center.dy);
      canvas.rotate(angle);
      canvas.translate(-petalRect.center.dx, -petalRect.center.dy);
      canvas.drawOval(petalRect, p.isEven ? petal : accent);
      canvas.restore();
    }
    canvas.drawCircle(center, radius * 0.22, core);
    canvas.drawCircle(center, radius * 0.10, accent);
  }

  void _paintSmallSkull(
    Canvas canvas,
    Offset center,
    double size,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size * 1.05, height: size * 1.15),
      fill,
    );
    canvas.drawCircle(
      center.translate(-size * 0.20, -size * 0.10),
      size * 0.10,
      accent,
    );
    canvas.drawCircle(
      center.translate(size * 0.20, -size * 0.10),
      size * 0.10,
      accent,
    );
    final nose = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - size * 0.08, center.dy + size * 0.16)
      ..lineTo(center.dx + size * 0.08, center.dy + size * 0.16)
      ..close();
    canvas.drawPath(nose, paint);
    for (var i = -2; i <= 2; i++) {
      canvas.drawLine(
        center.translate(i * size * 0.08, size * 0.34),
        center.translate(i * size * 0.08, size * 0.47),
        accent,
      );
    }
  }

  void _paintBook(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final left = Rect.fromCenter(
      center: center.translate(-width * 0.24, 0),
      width: width * 0.48,
      height: height,
    );
    final right = Rect.fromCenter(
      center: center.translate(width * 0.24, 0),
      width: width * 0.48,
      height: height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(left, const Radius.circular(4)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(right, const Radius.circular(4)),
      fill,
    );
    canvas.drawLine(
      center.translate(0, -height * 0.48),
      center.translate(0, height * 0.48),
      paint,
    );
    for (var i = 0; i < 4; i++) {
      final y = center.dy - height * 0.30 + i * height * 0.18;
      canvas.drawLine(
        Offset(left.left + 7, y),
        Offset(left.right - 5, y + 2),
        accent,
      );
      canvas.drawLine(
        Offset(right.left + 5, y + 2),
        Offset(right.right - 7, y),
        accent,
      );
    }
  }

  void _paintMedievalShield(
    Canvas canvas,
    Offset center,
    double scale,
    Paint fill,
    Paint line,
  ) {
    final shield = Path()
      ..moveTo(center.dx, center.dy - scale)
      ..lineTo(center.dx + scale * 0.80, center.dy - scale * 0.48)
      ..quadraticBezierTo(
        center.dx + scale * 0.62,
        center.dy + scale * 0.90,
        center.dx,
        center.dy + scale * 1.25,
      )
      ..quadraticBezierTo(
        center.dx - scale * 0.62,
        center.dy + scale * 0.90,
        center.dx - scale * 0.80,
        center.dy - scale * 0.48,
      )
      ..close();
    canvas.drawPath(shield, fill);
    canvas.drawPath(shield, line);
    canvas.drawLine(
      center.translate(0, -scale * 0.70),
      center.translate(0, scale * 0.82),
      line,
    );
    canvas.drawLine(
      center.translate(-scale * 0.52, -scale * 0.08),
      center.translate(scale * 0.52, -scale * 0.08),
      line,
    );
  }

  void _paintLantern(
    Canvas canvas,
    Offset center,
    double scale,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(0, -scale * 0.34),
        width: scale,
        height: scale * 0.74,
      ),
      pi,
      pi,
      false,
      paint,
    );
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: scale * 0.72,
        height: scale * 0.92,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, paint);
    final flame = Path()
      ..moveTo(center.dx, center.dy - scale * 0.22)
      ..quadraticBezierTo(
        center.dx + scale * 0.18,
        center.dy,
        center.dx,
        center.dy + scale * 0.22,
      )
      ..quadraticBezierTo(
        center.dx - scale * 0.14,
        center.dy,
        center.dx,
        center.dy - scale * 0.22,
      )
      ..close();
    canvas.drawPath(flame, accent);
    canvas.drawLine(
      center.translate(-scale * 0.36, -scale * 0.10),
      center.translate(scale * 0.36, -scale * 0.10),
      paint,
    );
    canvas.drawLine(
      center.translate(-scale * 0.36, scale * 0.12),
      center.translate(scale * 0.36, scale * 0.12),
      paint,
    );
  }

  void _paintCrown(
    Canvas canvas,
    Offset base,
    double width,
    double height,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final crown = Path()
      ..moveTo(base.dx - width / 2, base.dy)
      ..lineTo(base.dx - width * 0.33, base.dy - height * 0.82)
      ..lineTo(base.dx - width * 0.10, base.dy - height * 0.30)
      ..lineTo(base.dx, base.dy - height)
      ..lineTo(base.dx + width * 0.10, base.dy - height * 0.30)
      ..lineTo(base.dx + width * 0.33, base.dy - height * 0.82)
      ..lineTo(base.dx + width / 2, base.dy)
      ..close();
    canvas.drawPath(crown, fill);
    canvas.drawPath(crown, paint);
    for (final x in <double>[-0.33, 0, 0.33]) {
      canvas.drawCircle(
        base.translate(width * x, x == 0 ? -height : -height * 0.82),
        3.5,
        accent,
      );
    }
  }

  void _paintGlassShard(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final shard = Path()
      ..moveTo(center.dx, center.dy - height / 2)
      ..lineTo(center.dx + width * 0.38, center.dy - height * 0.08)
      ..lineTo(center.dx + width * 0.18, center.dy + height / 2)
      ..lineTo(center.dx - width * 0.42, center.dy + height * 0.18)
      ..close();
    canvas.drawPath(shard, fill);
    canvas.drawPath(shard, paint);
    canvas.drawLine(
      center.translate(-width * 0.20, -height * 0.20),
      center.translate(width * 0.22, height * 0.18),
      accent,
    );
  }

  void _paintSyntheticBloom(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    canvas.drawCircle(center, radius * 0.28, fill);
    canvas.drawCircle(center, radius * 0.42, paint);
    for (var i = 0; i < 6; i++) {
      final angle = -pi / 2 + i * pi / 3;
      final tip = center.translate(cos(angle) * radius, sin(angle) * radius);
      final left = center.translate(
        cos(angle - 0.36) * radius * 0.38,
        sin(angle - 0.36) * radius * 0.38,
      );
      final right = center.translate(
        cos(angle + 0.36) * radius * 0.38,
        sin(angle + 0.36) * radius * 0.38,
      );
      final petal = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(left.dx, left.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(right.dx, right.dy, center.dx, center.dy)
        ..close();
      canvas.drawPath(petal, i.isEven ? fill : accent);
      canvas.drawLine(
        center,
        center.translate(
          cos(angle) * radius * 0.72,
          sin(angle) * radius * 0.72,
        ),
        paint,
      );
    }

    final circuitNodes = <Offset>[
      center.translate(-radius * 1.55, 0),
      center.translate(radius * 1.55, 0),
      center.translate(0, -radius * 1.38),
      center.translate(0, radius * 1.38),
    ];
    for (final node in circuitNodes) {
      final mid = Offset(
        node.dx == center.dx ? center.dx : (center.dx + node.dx) / 2,
        node.dy == center.dy ? center.dy : (center.dy + node.dy) / 2,
      );
      canvas.drawLine(center, mid, paint);
      canvas.drawLine(mid, node, accent);
      _paintDiamond(canvas, node, radius * 0.15, fill);
    }
  }

  void _paintKarmaScalesDoodle(
    Canvas canvas,
    Offset center,
    double scale,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final top = center.translate(0, -scale * 0.55);
    canvas.drawLine(top, center.translate(0, scale * 0.72), paint);
    canvas.drawLine(
      top.translate(-scale * 0.92, scale * 0.18),
      top.translate(scale * 0.92, -scale * 0.18),
      accent,
    );
    for (final dir in <double>[-1, 1]) {
      final chainTop = top.translate(dir * scale * 0.70, dir * -scale * 0.14);
      final pan = chainTop.translate(0, scale * 0.55);
      canvas.drawLine(chainTop, pan.translate(-dir * scale * 0.22, 0), paint);
      canvas.drawLine(chainTop, pan.translate(dir * scale * 0.22, 0), paint);
      canvas.drawArc(
        Rect.fromCenter(center: pan, width: scale * 0.66, height: scale * 0.30),
        0,
        pi,
        false,
        dir < 0 ? fill : accent,
      );
      canvas.drawCircle(
        pan.translate(dir * scale * 0.12, -scale * 0.18),
        scale * 0.18,
        dir < 0 ? paint : fill,
      );
    }
    _paintDiamond(
      canvas,
      center.translate(0, scale * 0.82),
      scale * 0.22,
      accent,
    );
  }

  void _paintMonsterLanternDoodle(
    Canvas canvas,
    Offset center,
    double scale,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    _paintLantern(canvas, center, scale, paint, accent, fill);
    final eyeY = center.dy - scale * 0.03;
    for (final dir in <double>[-1, 1]) {
      final horn = Path()
        ..moveTo(center.dx + dir * scale * 0.28, center.dy - scale * 0.48)
        ..quadraticBezierTo(
          center.dx + dir * scale * 0.50,
          center.dy - scale * 0.82,
          center.dx + dir * scale * 0.66,
          center.dy - scale * 0.36,
        );
      canvas.drawPath(horn, paint);
      canvas.drawCircle(
        Offset(center.dx + dir * scale * 0.16, eyeY),
        scale * 0.055,
        fill,
      );
    }
    final grin = Path()
      ..moveTo(center.dx - scale * 0.20, center.dy + scale * 0.16)
      ..quadraticBezierTo(
        center.dx,
        center.dy + scale * 0.28,
        center.dx + scale * 0.20,
        center.dy + scale * 0.16,
      );
    canvas.drawPath(grin, accent);
  }

  void _paintPresetSignature(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final id = spec.presetId;
    if (id == 'none' ||
        id == 'classic_reliquary' ||
        id == 'classic_low_detail') {
      return;
    }
    final top = min(92.0, max(54.0, size.height * 0.11));
    final bottom = size.height - min(72.0, max(46.0, size.height * 0.075));
    final left = edge * 0.42;
    final right = size.width - edge * 0.42;

    switch (id) {
      case 'blood_court':
        for (var i = 0; i < 6; i++) {
          final x = left + i * ((right - left) / 5);
          final drop = Path()
            ..moveTo(x, top - 18)
            ..quadraticBezierTo(x + 11, top + 4, x, top + 24)
            ..quadraticBezierTo(x - 11, top + 4, x, top - 18)
            ..close();
          canvas.drawPath(drop, i.isEven ? fill : accent);
        }
        _paintCrown(
          canvas,
          Offset(size.width / 2, bottom + 12),
          86,
          44,
          paint,
          accent,
          fill,
        );
        break;
      case 'witch_glass':
        for (var i = 0; i < 8; i++) {
          _paintGlassShard(
            canvas,
            Offset(left + i * ((right - left) / 7), i.isEven ? top : bottom),
            28,
            56,
            paint,
            accent,
            fill,
          );
        }
        break;
      case 'moon_iron':
        for (var i = 0; i < 8; i++) {
          final x = left + i * ((right - left) / 7);
          canvas.drawOval(
            Rect.fromCenter(center: Offset(x, top), width: 30, height: 20),
            i.isEven ? paint : accent,
          );
          canvas.drawLine(
            Offset(x + 15, top),
            Offset(x + 34, top + 10),
            accent,
          );
          final blade = Path()
            ..moveTo(x - 7, bottom - 28)
            ..lineTo(x + 5, bottom - 2)
            ..lineTo(x + 14, bottom - 34)
            ..quadraticBezierTo(x + 2, bottom - 22, x - 7, bottom - 28)
            ..close();
          canvas.drawPath(blade, i.isEven ? fill : paint);
        }
        break;
      case 'lunar_eclipse':
        final eclipse = Offset(size.width / 2, top);
        canvas.drawCircle(eclipse, 34, fill);
        canvas.drawCircle(eclipse.translate(13, -2), 34, paint);
        _paintOculumMoonPhaseRow(
          canvas,
          left,
          right,
          bottom,
          10,
          accent,
          fill,
          paint,
        );
        break;
      case 'cathedral_rose':
        for (final c in <Offset>[
          Offset(left, top),
          Offset(right, top),
          Offset(size.width / 2, bottom),
        ]) {
          _paintRoseWindow(canvas, c, 26, paint, accent);
        }
        break;
      case 'thorn_vigil':
        for (final c in <Offset>[
          Offset(left, top),
          Offset(right, top),
          Offset(left, bottom),
          Offset(right, bottom),
        ]) {
          _paintBotanicalLeaf(
            canvas,
            c,
            c.dx < size.width / 2 ? 1 : -1,
            34,
            fill,
            accent,
          );
          _paintFineThorn(
            canvas,
            c.translate(c.dx < size.width / 2 ? 12 : -12, 10),
            c.dx < size.width / 2 ? 1 : -1,
            24,
            paint,
          );
        }
        break;
      case 'frost_chapel':
        for (var i = 0; i < 9; i++) {
          final c = Offset(
            left + i * ((right - left) / 8),
            i.isEven ? top : bottom,
          );
          canvas.drawLine(c.translate(-18, 0), c.translate(18, 0), accent);
          canvas.drawLine(c.translate(0, -18), c.translate(0, 18), paint);
          canvas.drawLine(c.translate(-13, -13), c.translate(13, 13), accent);
          canvas.drawLine(c.translate(-13, 13), c.translate(13, -13), paint);
        }
        break;
      case 'obsidian_sigil':
        for (final c in <Offset>[
          Offset(left, top),
          Offset(right, top),
          Offset(left, bottom),
          Offset(right, bottom),
        ]) {
          canvas.drawCircle(c, 25, paint);
          _paintDiamond(canvas, c, 15, accent);
          canvas.drawCircle(c, 5, fill);
        }
        break;
      case 'solar_reliquary':
        final sun = Offset(size.width / 2, top);
        canvas.drawCircle(sun, 22, fill);
        for (var i = 0; i < 16; i++) {
          final angle = i * pi / 8;
          canvas.drawLine(
            sun.translate(cos(angle) * 30, sin(angle) * 30),
            sun.translate(cos(angle) * 52, sin(angle) * 52),
            i.isEven ? accent : paint,
          );
        }
        break;
      case 'storm_cathedral':
        for (var i = 0; i < 7; i++) {
          final x = left + i * ((right - left) / 6);
          final bolt = Path()
            ..moveTo(x, top - 30)
            ..lineTo(x + 22, top)
            ..lineTo(x + 7, top)
            ..lineTo(x + 32, top + 42)
            ..lineTo(x + 14, top + 14)
            ..lineTo(x + 28, top + 14);
          canvas.drawPath(bolt, i.isEven ? accent : paint);
        }
        break;
      case 'abyssal_tide':
        for (var row = 0; row < 3; row++) {
          final y = bottom - row * 25;
          final wave = Path()..moveTo(left, y);
          for (var x = left; x < right + 44; x += 44) {
            wave.quadraticBezierTo(x + 22, y - 21, x + 44, y);
          }
          canvas.drawPath(wave, row.isEven ? fill : accent);
        }
        break;
      case 'ember_rite':
        for (var i = 0; i < 8; i++) {
          final base = Offset(left + i * ((right - left) / 7), bottom);
          canvas.drawRect(
            Rect.fromCenter(center: base, width: 10, height: 30),
            paint,
          );
          final flame = Path()
            ..moveTo(base.dx, base.dy - 48)
            ..quadraticBezierTo(
              base.dx + 16,
              base.dy - 22,
              base.dx,
              base.dy - 8,
            )
            ..quadraticBezierTo(
              base.dx - 13,
              base.dy - 24,
              base.dx,
              base.dy - 48,
            )
            ..close();
          canvas.drawPath(flame, i.isEven ? accent : fill);
        }
        break;
      case 'ivory_archive':
      case 'astral_ink':
        _paintBook(
          canvas,
          Offset(size.width / 2, top),
          92,
          54,
          paint,
          accent,
          fill,
        );
        for (var i = 0; i < 7; i++) {
          final c = Offset(left + i * ((right - left) / 6), bottom);
          canvas.drawLine(c.translate(0, -16), c.translate(0, 16), paint);
          canvas.drawLine(c, c.translate(15, -15), accent);
        }
        break;
      case 'vervain_gothic':
        for (final c in <Offset>[
          Offset(left, top),
          Offset(right, top),
          Offset(left, bottom),
          Offset(right, bottom),
        ]) {
          _paintVervainFlower(canvas, c, 16, fill, accent, paint);
        }
        break;
      case 'kingi_wrong_future':
        for (var i = 0; i < 5; i++) {
          final c = Offset(left + i * ((right - left) / 4), bottom);
          canvas.drawCircle(c, 20, paint);
          canvas.drawCircle(c, 8, fill);
          for (var t = 0; t < 10; t++) {
            final angle = t * pi / 5;
            canvas.drawLine(
              c.translate(cos(angle) * 14, sin(angle) * 14),
              c.translate(cos(angle) * 26, sin(angle) * 26),
              accent,
            );
          }
        }
        break;
      case 'blood_chapel':
        _paintRoseWindow(
          canvas,
          Offset(size.width / 2, top),
          30,
          paint,
          accent,
        );
        for (var i = 0; i < 5; i++) {
          _paintSmallSkull(
            canvas,
            Offset(left + i * ((right - left) / 4), bottom),
            30,
            paint,
            accent,
            fill,
          );
        }
        break;
      case 'null_crown':
        _paintCrown(
          canvas,
          Offset(size.width / 2, top + 34),
          92,
          52,
          paint,
          accent,
          fill,
        );
        for (final c in <Offset>[Offset(left, bottom), Offset(right, bottom)]) {
          canvas.drawCircle(c, 30, paint);
          canvas.drawCircle(c, 14, fill);
        }
        break;
      case 'phobia_dark':
        for (final c in <Offset>[
          Offset(left, top),
          Offset(right, top),
          Offset(left, bottom),
          Offset(right, bottom),
        ]) {
          canvas.drawOval(
            Rect.fromCenter(center: c, width: 66, height: 30),
            paint,
          );
          canvas.drawCircle(c, 10, fill);
          canvas.drawCircle(c, 4, accent);
        }
        break;
      case 'slime_prince':
        _paintCrown(
          canvas,
          Offset(size.width / 2, top + 34),
          78,
          42,
          paint,
          accent,
          fill,
        );
        for (var i = 0; i < 10; i++) {
          canvas.drawCircle(
            Offset(left + i * ((right - left) / 9), bottom + (i % 2) * 12),
            8 + (i % 3),
            i.isEven ? fill : accent,
          );
        }
        break;
      case 'moon_rot':
        _paintOculumMoonPhase(
          canvas,
          Offset(size.width / 2, top),
          34,
          6,
          paint,
          fill,
          accent,
        );
        for (var i = 0; i < 8; i++) {
          final base = Offset(left + i * ((right - left) / 7), bottom);
          canvas.drawLine(base, base.translate(0, -22 - (i % 3) * 5), paint);
          canvas.drawOval(
            Rect.fromCenter(
              center: base.translate(0, -30 - (i % 3) * 5),
              width: 22,
              height: 12,
            ),
            fill,
          );
        }
        break;
      case 'obser_relic':
        for (var i = 0; i < 5; i++) {
          final c = Offset(
            left + i * ((right - left) / 4),
            i.isEven ? top : bottom,
          );
          canvas.drawOval(
            Rect.fromCenter(center: c, width: 58, height: 28),
            paint,
          );
          canvas.drawCircle(c, 10, fill);
          canvas.drawCircle(c, 4, accent);
        }
        break;
      case 'deep_forest_demon':
        for (final c in <Offset>[
          Offset(left, top),
          Offset(right, top),
          Offset(left, bottom),
          Offset(right, bottom),
        ]) {
          _paintBotanicalLeaf(
            canvas,
            c,
            c.dx < size.width / 2 ? 1 : -1,
            42,
            fill,
            accent,
          );
          _paintLantern(
            canvas,
            c.translate(c.dx < size.width / 2 ? 36 : -36, 12),
            38,
            paint,
            accent,
            fill,
          );
        }
        break;
      case 'bone_saint':
        for (var i = 0; i < 7; i++) {
          _paintSmallSkull(
            canvas,
            Offset(left + i * ((right - left) / 6), i.isEven ? top : bottom),
            28,
            paint,
            accent,
            fill,
          );
        }
        break;
      case 'medieval_keep':
        final keep = Rect.fromCenter(
          center: Offset(size.width / 2, bottom - 8),
          width: 96,
          height: 70,
        );
        canvas.drawRect(keep, fill);
        canvas.drawRect(keep, paint);
        for (var i = 0; i < 5; i++) {
          final merlon = Rect.fromLTWH(
            keep.left + 5 + i * 18,
            keep.top - 14,
            11,
            16,
          );
          canvas.drawRect(merlon, i.isEven ? fill : accent);
          canvas.drawRect(merlon, paint);
        }
        _paintMedievalShield(
          canvas,
          Offset(size.width / 2, top + 6),
          25,
          fill,
          accent,
        );
        for (final dir in <double>[-1, 1]) {
          final hilt = Offset(size.width / 2 + dir * 60, top - 18);
          final tip = Offset(size.width / 2 + dir * 14, top + 48);
          canvas.drawLine(hilt, tip, dir < 0 ? paint : accent);
          canvas.drawLine(
            hilt.translate(-dir * 11, 14),
            hilt.translate(dir * 11, 14),
            fill,
          );
        }
        for (var i = 0; i < 6; i++) {
          final c = Offset(left + i * ((right - left) / 5), bottom + 10);
          canvas.drawLine(c.translate(-10, 0), c.translate(10, 0), accent);
        }
        break;
      case 'hoshy_cosmic_cat':
        final moon = Offset(size.width / 2, top);
        canvas.drawCircle(moon, 28, paint);
        canvas.drawCircle(moon.translate(12, 0), 28, fill);
        for (final dir in <double>[-1, 1]) {
          final ear = Path()
            ..moveTo(moon.dx + dir * 44, moon.dy + 32)
            ..lineTo(moon.dx + dir * 66, moon.dy - 16)
            ..lineTo(moon.dx + dir * 88, moon.dy + 32);
          canvas.drawPath(ear, accent);
        }
        break;
      case 'ash_oracle':
        final oracle = Offset(size.width / 2, top + 8);
        final hood = Path()
          ..moveTo(oracle.dx, oracle.dy - 34)
          ..quadraticBezierTo(
            oracle.dx + 44,
            oracle.dy + 4,
            oracle.dx + 18,
            oracle.dy + 46,
          )
          ..quadraticBezierTo(
            oracle.dx,
            oracle.dy + 34,
            oracle.dx - 18,
            oracle.dy + 46,
          )
          ..quadraticBezierTo(
            oracle.dx - 44,
            oracle.dy + 4,
            oracle.dx,
            oracle.dy - 34,
          )
          ..close();
        canvas.drawPath(hood, fill);
        canvas.drawPath(hood, paint);
        canvas.drawOval(
          Rect.fromCenter(center: oracle, width: 46, height: 18),
          accent,
        );
        canvas.drawCircle(oracle, 5, fill);
        for (var i = 0; i < 10; i++) {
          _paintStar(
            canvas,
            Offset(
              left + i * ((right - left) / 9),
              i.isEven ? top - 4 : bottom,
            ),
            5 + (i % 3),
            i.isEven ? paint : accent,
          );
        }
        break;
      case 'void_liturgy':
        for (var i = 0; i < 3; i++) {
          final c = <Offset>[
            Offset(size.width / 2, top),
            Offset(left, bottom),
            Offset(right, bottom),
          ][i];
          canvas.drawCircle(c, 28, paint);
          canvas.drawCircle(c, 17, fill);
          canvas.drawCircle(c, 5, accent);
          final chantY = c.dy + (i == 0 ? 42 : -42);
          canvas.drawLine(
            c.translate(0, i == 0 ? 22 : -22),
            Offset(c.dx, chantY),
            accent,
          );
          for (var tick = 0; tick < 3; tick++) {
            canvas.drawLine(
              Offset(c.dx - 14 + tick * 14, chantY),
              Offset(c.dx - 8 + tick * 14, chantY + (tick.isEven ? 8 : -8)),
              tick.isEven ? paint : accent,
            );
          }
        }
        break;
      case 'postea_bloom':
        final core = Offset(size.width / 2, top);
        _paintSyntheticBloom(canvas, core, 26, paint, accent, fill);
        for (var i = 0; i < 7; i++) {
          final c = Offset(
            left + i * ((right - left) / 6),
            i.isEven ? bottom : bottom - 26,
          );
          canvas.drawLine(
            c.translate(-16, 0),
            c.translate(16, i.isEven ? -10 : 10),
            i.isEven ? accent : paint,
          );
          _paintSyntheticBloom(
            canvas,
            c,
            10 + (i % 2) * 2,
            paint,
            accent,
            fill,
          );
        }
        for (var i = 0; i < 4; i++) {
          final gear = Offset(left + i * ((right - left) / 3), top + 38);
          _paintDesktopMiniGear(canvas, gear, 8, paint, accent, fill);
          canvas.drawLine(gear, core, i.isEven ? accent : paint);
        }
        break;
      case 'karma_duality':
        final balance = Offset(size.width / 2, bottom - 6);
        _paintKarmaScalesDoodle(canvas, balance, 54, paint, accent, fill);
        for (final c in <Offset>[
          balance.translate(-48, -88),
          balance.translate(48, -88),
        ]) {
          canvas.drawCircle(c, 26, paint);
          canvas.drawCircle(
            c.translate(c.dx < size.width / 2 ? 8 : -8, 0),
            18,
            fill,
          );
        }
        _paintDiamond(canvas, Offset(size.width / 2, top + 2), 20, accent);
        canvas.drawLine(
          Offset(size.width / 2, top + 22),
          balance.translate(0, -72),
          paint,
        );
        break;
      case 'monster_lantern':
        for (var i = 0; i < 5; i++) {
          final c = Offset(
            left + i * ((right - left) / 4),
            i.isEven ? top : bottom,
          );
          _paintMonsterLanternDoodle(canvas, c, 40, paint, accent, fill);
          _paintFineThorn(
            canvas,
            c.translate(i.isEven ? -30 : 30, i.isEven ? 24 : -24),
            i.isEven ? 1 : -1,
            30,
            i.isEven ? accent : paint,
          );
        }
        break;
      case 'verdigris_mourning':
        for (var i = 0; i < 6; i++) {
          final c = Offset(left + i * ((right - left) / 5), bottom);
          canvas.drawLine(c.translate(-12, 18), c.translate(12, -18), paint);
          canvas.drawLine(c.translate(12, 18), c.translate(-12, -18), accent);
          _paintVervainFlower(
            canvas,
            c.translate(0, -30),
            10,
            fill,
            accent,
            paint,
          );
        }
        break;
    }
  }

  void _paintFineThorn(
    Canvas canvas,
    Offset base,
    double dir,
    double length,
    Paint paint,
  ) {
    final thorn = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        base.dx + dir * length * 0.62,
        base.dy - length * 0.22,
        base.dx + dir * length,
        base.dy - length * 0.76,
      )
      ..quadraticBezierTo(
        base.dx + dir * length * 0.58,
        base.dy - length * 0.18,
        base.dx + dir * length * 0.20,
        base.dy + length * 0.06,
      );
    canvas.drawPath(thorn, paint);
  }

  void _paintCornerFlourishes(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent, {
    bool diamonds = true,
  }) {
    final corner = min(edge * 0.58, 92.0);
    final points = <Offset>[
      const Offset(12, 12),
      Offset(size.width - 12, 12),
      Offset(12, size.height - 12),
      Offset(size.width - 12, size.height - 12),
    ];

    for (final origin in points) {
      final sx = origin.dx < size.width / 2 ? 1.0 : -1.0;
      final sy = origin.dy < size.height / 2 ? 1.0 : -1.0;
      final path = Path()
        ..moveTo(origin.dx + sx * 8, origin.dy)
        ..quadraticBezierTo(
          origin.dx + sx * corner * 0.40,
          origin.dy + sy * 4,
          origin.dx + sx * corner,
          origin.dy + sy * corner * 0.30,
        )
        ..quadraticBezierTo(
          origin.dx + sx * corner * 0.48,
          origin.dy + sy * corner * 0.42,
          origin.dx + sx * corner * 0.36,
          origin.dy + sy * corner,
        );
      canvas.drawPath(path, paint);
      canvas.drawLine(
        Offset(origin.dx, origin.dy + sy * 18),
        Offset(origin.dx + sx * corner * 0.66, origin.dy + sy * 18),
        accent,
      );
      canvas.drawLine(
        Offset(origin.dx + sx * 18, origin.dy),
        Offset(origin.dx + sx * 18, origin.dy + sy * corner * 0.66),
        accent,
      );
      if (diamonds) {
        _paintDiamond(
          canvas,
          Offset(
            origin.dx + sx * corner * 0.46,
            origin.dy + sy * corner * 0.46,
          ),
          7,
          accent,
        );
      }
    }
  }

  void _paintEdgeBeads(Canvas canvas, Size size, double edge, Paint paint) {
    final count = size.width < 760 ? 5 : 8;
    for (var i = 0; i < count; i++) {
      final x = size.width * (i + 1) / (count + 1);
      final top = 18.0 + (i.isEven ? 0 : 8);
      final bottom = size.height - top;
      _paintDiamond(canvas, Offset(x, top), 4.5, paint);
      _paintDiamond(canvas, Offset(x, bottom), 4.5, paint);
    }
  }

  void _paintSideGlyphs(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent, {
    required String glyph,
  }) {
    final count = size.height < 680 ? 4 : 6;
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < count; i++) {
        final center = Offset(
          side + dir * edge * (0.54 + (i.isEven ? 0.08 : -0.05)),
          size.height * (0.12 + i * 0.16),
        );
        switch (glyph) {
          case 'star':
            _paintStar(canvas, center, 7 + (i % 2) * 2, accent);
            break;
          case 'diamond':
            _paintDiamond(canvas, center, 8 + (i % 2) * 2, paint);
            break;
          case 'circle':
            canvas.drawCircle(center, 8 + (i % 3) * 2, paint);
            canvas.drawCircle(center, 3.5, accent);
            break;
          default:
            canvas.drawCircle(center, 3.5, accent);
        }
      }
    }
  }

  void _paintRoseWindow(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    Paint accent,
  ) {
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.56, accent);
    for (var i = 0; i < 12; i++) {
      final angle = i * pi / 6;
      final start = Offset(
        center.dx + cos(angle) * radius * 0.18,
        center.dy + sin(angle) * radius * 0.18,
      );
      final end = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );
      canvas.drawLine(start, end, i.isEven ? paint : accent);
    }
    for (var i = 0; i < 6; i++) {
      final angle = i * pi / 3 + pi / 6;
      final petal = Rect.fromCenter(
        center: Offset(
          center.dx + cos(angle) * radius * 0.42,
          center.dy + sin(angle) * radius * 0.42,
        ),
        width: radius * 0.52,
        height: radius * 0.26,
      );
      canvas.save();
      canvas.translate(petal.center.dx, petal.center.dy);
      canvas.rotate(angle);
      canvas.translate(-petal.center.dx, -petal.center.dy);
      canvas.drawOval(petal, accent);
      canvas.restore();
    }
  }

  void _paintTopCurtain(Canvas canvas, Size size, double edge, Paint paint) {
    final path = Path()
      ..moveTo(edge * 0.42, 0)
      ..quadraticBezierTo(size.width * 0.34, 54, size.width / 2, 32)
      ..quadraticBezierTo(size.width * 0.66, 54, size.width - edge * 0.42, 0);
    canvas.drawPath(path, paint);
  }

  void _paintLunar(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final moonLit = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.accent.withValues(alpha: spec.opacity * 0.58);
    final moonShadow = fill;
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < 5; i++) {
        final y = size.height * (0.12 + i * 0.19);
        final x = side + dir * (edge * (0.23 + (i.isEven ? 0.08 : 0.0)));
        _paintOculumMoonPhase(
          canvas,
          Offset(x, y),
          20 + i * 2.5,
          side == 0 ? i : 7 - i,
          paint,
          moonLit,
          moonShadow,
        );
        canvas.drawLine(
          Offset(side + dir * 10, y + 38),
          Offset(side + dir * edge * 0.72, y + 16),
          accent,
        );
      }
    }
    _paintCornerFlourishes(canvas, size, edge, paint, accent);
    _paintEdgeBeads(canvas, size, edge, accent);
    _paintSideGlyphs(canvas, size, edge, paint, accent, glyph: 'star');
    _paintTopCurtain(canvas, size, edge, accent);
    _paintOculumMoonPhaseRow(
      canvas,
      edge * 0.86,
      size.width - edge * 0.86,
      min(98.0, max(58.0, size.height * 0.095)),
      9.8,
      accent,
      moonLit,
      moonShadow,
    );
    if (size.height > 520) {
      _paintOculumMoonPhaseRow(
        canvas,
        edge * 0.92,
        size.width - edge * 0.92,
        size.height - min(82.0, max(54.0, size.height * 0.075)),
        8.4,
        paint,
        moonLit,
        moonShadow,
      );
    }
    for (var i = 0; i < 7; i++) {
      final x = size.width * (0.20 + i * 0.10);
      final y = 46.0 + (i.isEven ? 0 : 16);
      _paintStar(canvas, Offset(x, y), 4.5 + (i % 3), paint);
      if (i > 0) {
        final previous = Offset(
          size.width * (0.20 + (i - 1) * 0.10),
          46.0 + ((i - 1).isEven ? 0 : 16),
        );
        canvas.drawLine(previous, Offset(x, y), accent);
      }
    }
  }

  void _paintCathedral(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
  ) {
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      final left = side == 0 ? 10.0 : size.width - edge + 10;
      final right = side == 0 ? edge - 10 : size.width - 10;
      for (var i = 0; i < 4; i++) {
        final top = size.height * (0.05 + i * 0.24);
        final rect = Rect.fromLTWH(left, top, edge - 20, size.height * 0.18);
        final path = Path()
          ..moveTo((left + right) / 2, top)
          ..quadraticBezierTo(
            side + dir * edge * 0.96,
            top + rect.height * 0.45,
            right,
            top + rect.height,
          )
          ..lineTo(left, top + rect.height)
          ..quadraticBezierTo(
            side + dir * edge * 0.04,
            top + rect.height * 0.45,
            (left + right) / 2,
            top,
          );
        canvas.drawPath(path, paint);
        canvas.drawLine(
          Offset((left + right) / 2, top + 8),
          Offset((left + right) / 2, top + rect.height),
          accent,
        );
        canvas.drawLine(
          Offset(left + rect.width * 0.28, top + rect.height),
          Offset(right - rect.width * 0.28, top + rect.height * 0.28),
          accent,
        );
      }
    }
    _paintRoseWindow(canvas, Offset(size.width / 2, 58), 34, paint, accent);
    _paintRoseWindow(
      canvas,
      Offset(size.width / 2, size.height - 38),
      24,
      accent,
      paint,
    );
    _paintCornerFlourishes(canvas, size, edge, paint, accent);
    _paintEdgeBeads(canvas, size, edge, accent);
    for (var x = edge * 0.72; x < size.width - edge * 0.72; x += 58) {
      canvas.drawLine(Offset(x, 12), Offset(x + 22, 74), paint);
      canvas.drawLine(Offset(x + 22, 74), Offset(x + 44, 12), accent);
    }
  }

  void _paintThorns(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
  ) {
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      final path = Path()..moveTo(side + dir * 18, -20);
      for (var i = 0; i < 12; i++) {
        final y = size.height * i / 11;
        path.quadraticBezierTo(
          side + dir * (edge * (i.isEven ? 0.70 : 0.28)),
          y + 24,
          side + dir * 18,
          y + 58,
        );
      }
      canvas.drawPath(path, paint);
      for (var i = 0; i < 9; i++) {
        final y = size.height * (0.08 + i * 0.11);
        final x = side + dir * (edge * (i.isEven ? 0.36 : 0.58));
        _paintFineThorn(canvas, Offset(x, y), dir, 18 + (i % 3) * 5, accent);
        _paintFineThorn(
          canvas,
          Offset(x + dir * 8, y + 18),
          dir,
          12 + (i % 2) * 4,
          paint,
        );
        if (i % 3 == 0) {
          _paintBotanicalLeaf(
            canvas,
            Offset(x + dir * 12, y + 8),
            dir,
            23,
            paint,
            accent,
          );
        }
      }
    }
    _paintCornerFlourishes(canvas, size, edge, paint, accent, diamonds: false);
    _paintSideGlyphs(canvas, size, edge, paint, accent, glyph: 'diamond');
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < 6; i++) {
        final y = size.height * (0.14 + i * 0.13);
        final center = Offset(side + dir * edge * 0.72, y);
        canvas.drawCircle(center, 8 + (i % 2) * 2, paint);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: 14 + (i % 2) * 3),
          dir > 0 ? -pi / 2 : pi / 2,
          dir * pi,
          false,
          accent,
        );
      }
    }
  }

  void _paintVervain(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    _paintCornerFlourishes(canvas, size, edge, paint, accent, diamonds: false);
    _paintEdgeBeads(canvas, size, edge, accent);

    final flowerPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = _oculumReverseBackgroundShader(
        spec,
        size,
        spec.primary,
        spec.opacity * 0.72,
      );
    final leafPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = _oculumReverseBackgroundShader(
        spec,
        size,
        spec.secondary,
        spec.opacity * 0.54,
      );
    final vinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = desktop ? 1.65 : 1.12
      ..color = spec.secondary.withValues(
        alpha: (spec.opacity * (desktop ? 1.16 : 0.82))
            .clamp(0.08, desktop ? 0.28 : 0.18)
            .toDouble(),
      );

    _paintVervainHangingVines(
      canvas,
      size,
      edge,
      vinePaint,
      accent,
      leafPaint,
      flowerPaint,
      fill,
    );

    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      final mainVine = Path()..moveTo(side + dir * 20, -30);
      for (var i = 0; i < 13; i++) {
        final y = size.height * i / 12;
        final swayA = edge * (0.24 + (i % 3) * 0.08);
        final swayB = edge * (0.64 - (i % 2) * 0.12);
        mainVine.cubicTo(
          side + dir * swayB,
          y + 12,
          side + dir * swayA,
          y + 44,
          side + dir * edge * 0.46,
          y + 68,
        );
      }
      canvas.drawPath(mainVine, paint);

      for (var i = 0; i < 11; i++) {
        final y = size.height * (0.065 + i * 0.088);
        final x = side + dir * edge * (0.30 + (i % 4) * 0.095);
        final node = Offset(x, y);
        _paintFineThorn(
          canvas,
          node.translate(dir * 2, 0),
          dir,
          18 + (i % 3) * 5,
          i.isEven ? accent : paint,
        );
        _paintFineThorn(
          canvas,
          node.translate(dir * 5, 14),
          dir,
          13 + (i % 2) * 5,
          i.isEven ? paint : accent,
        );

        _paintBotanicalLeaf(
          canvas,
          node.translate(dir * 15, 17),
          dir,
          32 + (i % 3) * 7,
          i.isEven ? leafPaint : fill,
          accent,
        );
        if (i % 2 == 1) {
          _paintBotanicalLeaf(
            canvas,
            node.translate(dir * 8, -16),
            dir,
            24 + (i % 2) * 8,
            fill,
            paint,
          );
        }

        if (i % 3 != 1) {
          _paintVervainFlower(
            canvas,
            node.translate(dir * (36 + (i % 2) * 8), -3),
            11 + (i % 3) * 1.5,
            flowerPaint,
            accent,
            fill,
          );
        }
      }
    }

    for (final bottom in <bool>[false, true]) {
      final y = bottom
          ? size.height - min(44.0, max(26.0, size.height * 0.055))
          : min(48.0, max(28.0, size.height * 0.060));
      final vine = Path()..moveTo(edge * 0.46, y);
      for (var x = edge * 0.46; x < size.width - edge * 0.46; x += 78) {
        vine.cubicTo(
          x + 22,
          y + (bottom ? -18 : 18),
          x + 48,
          y + (bottom ? 14 : -14),
          x + 78,
          y,
        );
      }
      canvas.drawPath(vine, bottom ? accent : paint);
      for (var i = 0; i < 7; i++) {
        final x = edge * 0.58 + i * ((size.width - edge * 1.16) / 6);
        if (x < edge * 0.52 || x > size.width - edge * 0.52) continue;
        _paintBotanicalLeaf(
          canvas,
          Offset(x, y),
          i.isEven ? 1 : -1,
          22 + (i % 3) * 5,
          leafPaint,
          accent,
        );
        if (i.isEven) {
          _paintVervainFlower(
            canvas,
            Offset(x + (i.isEven ? 16 : -16), y + (bottom ? -10 : 10)),
            8.5,
            flowerPaint,
            accent,
            fill,
          );
        }
      }
    }

    final bramblePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = desktop ? 1.85 : 1.25
      ..color = const Color(0xFF0B120A).withValues(
        alpha: (spec.opacity * (desktop ? 1.35 : 0.95))
            .clamp(0.10, desktop ? 0.34 : 0.22)
            .toDouble(),
      );
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < (desktop ? 6 : 4); i++) {
        final start = Offset(side + dir * 12, size.height * (0.14 + i * 0.14));
        final end = Offset(
          side + dir * edge * (0.72 + (i % 2) * 0.10),
          start.dy + 42,
        );
        final branch = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(
            start.dx + dir * edge * 0.24,
            start.dy - 18,
            end.dx - dir * edge * 0.18,
            end.dy + 18,
            end.dx,
            end.dy,
          );
        canvas.drawPath(branch, bramblePaint);
        for (var thorn = 0; thorn < 4; thorn++) {
          final t = thorn / 4;
          final thornBase = Offset(
            start.dx + (end.dx - start.dx) * t,
            start.dy + (end.dy - start.dy) * t + (thorn.isEven ? -6 : 8),
          );
          _paintFineThorn(
            canvas,
            thornBase,
            dir * (thorn.isEven ? 1 : -1),
            13 + thorn * 2,
            thorn.isEven ? accent : bramblePaint,
          );
        }
      }
    }

    final bouquetCenters = <Offset>[
      Offset(edge * 0.38, 58),
      Offset(size.width - edge * 0.38, 58),
      Offset(edge * 0.38, size.height - 58),
      Offset(size.width - edge * 0.38, size.height - 58),
    ];
    for (final center in bouquetCenters) {
      final dir = center.dx < size.width / 2 ? 1.0 : -1.0;
      final verticalDir = center.dy < size.height / 2 ? 1.0 : -1.0;
      for (var i = 0; i < 4; i++) {
        final base = center.translate(dir * i * 8, verticalDir * i * 7);
        _paintBotanicalLeaf(canvas, base, dir, 28 - i * 2, leafPaint, accent);
        _paintFineThorn(
          canvas,
          base.translate(0, verticalDir * 8),
          dir,
          18,
          paint,
        );
      }
      _paintVervainFlower(canvas, center, 13, flowerPaint, accent, fill);
    }

    _paintVervainLettuceFrog(
      canvas,
      size,
      edge,
      paint,
      accent,
      fill,
      leafPaint,
      flowerPaint,
    );
  }

  void _paintVervainHangingVines(
    Canvas canvas,
    Size size,
    double edge,
    Paint vinePaint,
    Paint accent,
    Paint leafPaint,
    Paint flowerPaint,
    Paint fill,
  ) {
    final count = desktop ? 7 : 4;
    for (var i = 0; i < count; i++) {
      final x = edge * 0.44 + i * ((size.width - edge * 0.88) / max(1, count));
      final drop = min(size.height * 0.30, 92.0 + (i % 3) * 24.0);
      final path = Path()..moveTo(x, 0);
      path.cubicTo(x - 18, drop * 0.28, x + 20, drop * 0.62, x - 8, drop);
      canvas.drawPath(path, i.isEven ? vinePaint : accent);
      final dir = i.isEven ? 1.0 : -1.0;
      _paintBotanicalLeaf(
        canvas,
        Offset(x + dir * 8, drop * 0.46),
        dir,
        18 + (i % 2) * 5,
        leafPaint,
        vinePaint,
      );
      if (i % 2 == 0) {
        _paintVervainFlower(
          canvas,
          Offset(x - dir * 12, drop * 0.72),
          7.5,
          flowerPaint,
          accent,
          fill,
        );
      }
    }
  }

  void _paintVervainLettuceFrog(
    Canvas canvas,
    Size size,
    double edge,
    Paint line,
    Paint accent,
    Paint fill,
    Paint leafPaint,
    Paint flowerPaint,
  ) {
    if (size.width < 260 || size.height < 260) return;
    final frogSize = min(
      desktop ? 104.0 : 74.0,
      max(46.0, min(size.width, size.height) * (desktop ? 0.125 : 0.115)),
    );
    final center = Offset(
      size.width - max(edge * 0.33, frogSize * 0.62),
      size.height - max(42.0, frogSize * 0.50),
    );
    final alpha = (spec.opacity * (desktop ? 1.55 : 1.18))
        .clamp(0.10, desktop ? 0.38 : 0.26)
        .toDouble();
    final darkLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = max(0.9, frogSize * 0.018)
      ..color = const Color(0xFF061009).withValues(alpha: alpha * 1.20);
    final body = Paint()
      ..style = PaintingStyle.fill
      ..shader =
          RadialGradient(
            center: const Alignment(-0.28, -0.34),
            radius: 0.92,
            colors: [
              const Color(0xFF9CCB6F).withValues(alpha: alpha * 0.86),
              spec.secondary.withValues(alpha: alpha * 0.92),
              spec.backgroundBottom.withValues(alpha: alpha * 0.62),
            ],
          ).createShader(
            Rect.fromCenter(
              center: center,
              width: frogSize * 1.46,
              height: frogSize * 1.05,
            ),
          );
    final eye = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFD7C48A).withValues(alpha: alpha * 1.18);
    final pupil = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF1A211A).withValues(alpha: alpha * 1.35);
    final shine = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.primary.withValues(alpha: alpha * 0.74);

    final bodyRect = Rect.fromCenter(
      center: center.translate(0, frogSize * 0.04),
      width: frogSize * 1.24,
      height: frogSize * 0.82,
    );
    canvas.drawOval(bodyRect, body);
    canvas.drawOval(bodyRect, darkLine);

    final crownLeaf = Path()
      ..moveTo(center.dx - frogSize * 0.44, center.dy - frogSize * 0.12)
      ..quadraticBezierTo(
        center.dx - frogSize * 0.10,
        center.dy - frogSize * 0.66,
        center.dx + frogSize * 0.48,
        center.dy - frogSize * 0.28,
      )
      ..quadraticBezierTo(
        center.dx + frogSize * 0.24,
        center.dy + frogSize * 0.02,
        center.dx - frogSize * 0.44,
        center.dy - frogSize * 0.12,
      );
    canvas.drawPath(crownLeaf, leafPaint);
    canvas.drawPath(crownLeaf, darkLine);
    canvas.drawLine(
      center.translate(-frogSize * 0.30, -frogSize * 0.15),
      center.translate(frogSize * 0.38, -frogSize * 0.24),
      darkLine,
    );

    for (final side in <double>[-1, 1]) {
      final eyeCenter = center.translate(
        side * frogSize * 0.31,
        -frogSize * 0.21,
      );
      canvas.drawCircle(eyeCenter, frogSize * 0.17, eye);
      canvas.drawCircle(eyeCenter, frogSize * 0.17, darkLine);
      canvas.drawOval(
        Rect.fromCenter(
          center: eyeCenter.translate(side * frogSize * 0.02, frogSize * 0.02),
          width: frogSize * 0.12,
          height: frogSize * 0.16,
        ),
        pupil,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: eyeCenter.translate(
            -side * frogSize * 0.04,
            -frogSize * 0.05,
          ),
          width: frogSize * 0.07,
          height: frogSize * 0.04,
        ),
        shine,
      );
      canvas.drawLine(
        center.translate(side * frogSize * 0.34, frogSize * 0.30),
        center.translate(side * frogSize * 0.50, frogSize * 0.43),
        darkLine,
      );
      canvas.drawCircle(
        center.translate(side * frogSize * 0.54, frogSize * 0.45),
        frogSize * 0.035,
        fill,
      );
    }

    for (var i = 0; i < 4; i++) {
      final veinX = center.dx - frogSize * 0.34 + i * frogSize * 0.22;
      final vein = Path()
        ..moveTo(veinX, center.dy - frogSize * 0.16)
        ..quadraticBezierTo(
          veinX + frogSize * 0.10,
          center.dy + frogSize * 0.04,
          veinX + frogSize * 0.02,
          center.dy + frogSize * 0.26,
        );
      canvas.drawPath(vein, darkLine);
    }

    final cover = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = max(1.1, frogSize * 0.020)
      ..color = spec.secondary.withValues(alpha: alpha * 0.92);
    final coverVine = Path()
      ..moveTo(center.dx - frogSize * 0.78, center.dy + frogSize * 0.38)
      ..cubicTo(
        center.dx - frogSize * 0.36,
        center.dy + frogSize * 0.14,
        center.dx + frogSize * 0.14,
        center.dy + frogSize * 0.52,
        center.dx + frogSize * 0.70,
        center.dy + frogSize * 0.23,
      );
    canvas.drawPath(coverVine, cover);
    _paintVervainFlower(
      canvas,
      center.translate(-frogSize * 0.62, frogSize * 0.22),
      frogSize * 0.075,
      flowerPaint,
      accent,
      fill,
    );
    _paintBotanicalLeaf(
      canvas,
      center.translate(frogSize * 0.55, frogSize * 0.18),
      -1,
      frogSize * 0.24,
      leafPaint,
      cover,
    );
  }

  void _paintKingi(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && size.width >= 720;
    final electric = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = detailed ? 1.75 : 1.05
      ..color = const Color(0xFF16C8FF).withValues(
        alpha: (spec.opacity * (detailed ? 1.72 : 1.02))
            .clamp(0.08, detailed ? 0.42 : 0.20)
            .toDouble(),
      );
    final electricSoft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = detailed ? 4.8 : 2.2
      ..color = const Color(0xFF16C8FF).withValues(
        alpha: (spec.opacity * (detailed ? 0.46 : 0.20))
            .clamp(0.025, detailed ? 0.18 : 0.08)
            .toDouble(),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final metalFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFB8C4CE).withValues(alpha: detailed ? 0.16 : 0.07),
          spec.secondary.withValues(alpha: detailed ? 0.20 : 0.10),
          spec.backgroundBottom.withValues(alpha: 0.0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    _paintCornerFlourishes(canvas, size, edge, paint, accent);
    _paintTopCurtain(canvas, size, edge, paint);

    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      final plateCount = detailed ? 7 : 4;
      for (var i = 0; i < plateCount; i++) {
        final y = size.height * (0.08 + i * (detailed ? 0.125 : 0.20));
        final plate = Rect.fromCenter(
          center: Offset(side + dir * edge * (detailed ? 0.50 : 0.44), y),
          width: edge * (detailed ? 0.60 : 0.46),
          height: detailed ? 52 : 36,
        );
        final rr = RRect.fromRectAndRadius(
          plate,
          Radius.circular(detailed ? 7 : 5),
        );
        canvas.drawRRect(rr, metalFill);
        canvas.drawRRect(rr, i.isEven ? paint : accent);
        canvas.drawCircle(
          plate.topLeft.translate(9, 9),
          detailed ? 3.6 : 2.8,
          fill,
        );
        canvas.drawCircle(
          plate.bottomRight.translate(-9, -9),
          detailed ? 3.6 : 2.8,
          fill,
        );
        if (detailed) {
          canvas.drawCircle(plate.topRight.translate(-12, 10), 2.6, accent);
          canvas.drawCircle(plate.bottomLeft.translate(12, -10), 2.6, accent);
        }
        canvas.drawLine(
          plate.centerLeft.translate(8, -8),
          plate.centerRight.translate(-8, -8),
          electric,
        );
        canvas.drawLine(
          plate.centerLeft.translate(8, 8),
          plate.center.translate(dir * 18, 8),
          fill,
        );
        final runeCount = detailed ? 5 : 3;
        for (var rune = 0; rune < runeCount; rune++) {
          final rx = plate.left + 16 + rune * plate.width / 4;
          canvas.drawLine(Offset(rx, y - 8), Offset(rx + dir * 8, y), paint);
          canvas.drawLine(Offset(rx + dir * 8, y), Offset(rx, y + 8), electric);
        }

        final bolt = Path()
          ..moveTo(side + dir * edge * 0.22, y - 52)
          ..lineTo(side + dir * edge * 0.52, y - 16)
          ..lineTo(side + dir * edge * 0.40, y - 15)
          ..lineTo(side + dir * edge * 0.70, y + 36)
          ..lineTo(side + dir * edge * 0.52, y + 8)
          ..lineTo(side + dir * edge * 0.64, y + 8);
        if (detailed || i.isEven) {
          canvas.drawPath(bolt, electricSoft);
          canvas.drawPath(bolt, electric);
        }
      }
    }

    final gearCount = detailed ? 9 : 5;
    for (var i = 0; i < gearCount; i++) {
      final center = Offset(
        size.width * (0.12 + i * (detailed ? 0.095 : 0.16)),
        size.height - (detailed ? 70 - (i % 3) * 8 : 62),
      );
      final radius = (detailed ? 17.0 : 15.0) + (i % 2) * 5;
      canvas.drawCircle(center, radius + (detailed ? 3 : 0), metalFill);
      canvas.drawCircle(center, radius, paint);
      canvas.drawCircle(center, radius * 0.42, fill);
      final toothCount = detailed ? 14 : 10;
      for (var tooth = 0; tooth < toothCount; tooth++) {
        final angle = tooth * 2 * pi / toothCount;
        canvas.drawLine(
          Offset(
            center.dx + cos(angle) * radius * 0.72,
            center.dy + sin(angle) * radius * 0.72,
          ),
          Offset(
            center.dx + cos(angle) * (radius + 8),
            center.dy + sin(angle) * (radius + 8),
          ),
          tooth.isEven ? electric : paint,
        );
      }
    }

    final railStep = detailed ? 38.0 : 54.0;
    for (var x = edge * 0.74; x < size.width - edge * 0.74; x += railStep) {
      final rail = Rect.fromLTWH(
        x - 6,
        14,
        detailed ? 11 : 8,
        detailed ? 48 : 34,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rail, const Radius.circular(4)),
        metalFill,
      );
      canvas.drawLine(Offset(x, 18), Offset(x, detailed ? 62 : 52), paint);
      canvas.drawCircle(
        Offset(x, detailed ? 62 : 52),
        detailed ? 4.4 : 3.5,
        accent,
      );
      canvas.drawLine(Offset(x, 36), Offset(x + 18, 24), electric);
      if (detailed && ((x / railStep).round()).isEven) {
        final arc = Rect.fromCenter(
          center: Offset(x + 20, 46),
          width: 42,
          height: 24,
        );
        canvas.drawArc(arc, -pi * 0.88, pi * 0.72, false, electric);
      }
    }

    final core = Offset(size.width / 2, min(size.height * 0.18, 132.0));
    final coreRadius = detailed ? 34.0 : 24.0;
    canvas.drawCircle(core, coreRadius, metalFill);
    canvas.drawCircle(core, coreRadius, paint);
    canvas.drawCircle(core, coreRadius * 0.52, electric);
    _paintDiamond(canvas, core, coreRadius * 0.30, fill);
    for (var i = 0; i < (detailed ? 12 : 8); i++) {
      final angle = i * 2 * pi / (detailed ? 12 : 8);
      final start = core.translate(
        cos(angle) * coreRadius * 0.74,
        sin(angle) * coreRadius * 0.74,
      );
      final end = core.translate(
        cos(angle) * coreRadius * 1.44,
        sin(angle) * coreRadius * 1.02,
      );
      canvas.drawLine(start, end, i.isEven ? electric : paint);
    }
    for (var i = 0; i < (detailed ? 6 : 4); i++) {
      final angle = -pi * 0.78 + i * pi * 0.31;
      final runeCenter = core.translate(
        cos(angle) * coreRadius * 1.95,
        sin(angle) * coreRadius * 1.35,
      );
      canvas.drawLine(
        runeCenter.translate(-7, -7),
        runeCenter.translate(7, 7),
        electric,
      );
      canvas.drawLine(
        runeCenter.translate(-5, 5),
        runeCenter.translate(8, -6),
        paint,
      );
    }

    if (detailed) {
      for (var i = 0; i < 4; i++) {
        final y = size.height * (0.22 + i * 0.14);
        final path = Path()
          ..moveTo(edge * 0.55, y)
          ..lineTo(edge * 0.86, y - 20)
          ..lineTo(edge * 0.76, y - 20)
          ..lineTo(edge * 1.04, y - 50)
          ..moveTo(size.width - edge * 0.55, y + 12)
          ..lineTo(size.width - edge * 0.88, y - 6)
          ..lineTo(size.width - edge * 0.76, y - 7)
          ..lineTo(size.width - edge * 1.08, y - 34);
        canvas.drawPath(path, electricSoft);
        canvas.drawPath(path, electric);
      }
    }
  }

  void _paintJrpg(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && size.width >= 720;
    final crystalLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = detailed ? 1.42 : 1.02
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * (detailed ? 1.36 : 0.96))
            .clamp(0.08, detailed ? 0.34 : 0.20)
            .toDouble(),
      );
    final goldLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = detailed ? 1.20 : 0.92
      ..color = const Color(0xFFE7B84A).withValues(
        alpha: (spec.opacity * (detailed ? 1.20 : 0.86))
            .clamp(0.07, detailed ? 0.28 : 0.18)
            .toDouble(),
      );
    final soft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = detailed ? 4.2 : 2.0
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * 0.22).clamp(0.02, 0.10).toDouble(),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    _paintCornerFlourishes(canvas, size, edge, paint, accent);

    for (var row = 0; row < (detailed ? 6 : 4); row++) {
      final y = size.height * (0.12 + row * (detailed ? 0.12 : 0.18));
      final left = Path()
        ..moveTo(edge * 0.18, y)
        ..lineTo(edge * 0.54, y)
        ..lineTo(edge * 0.68, y + 18)
        ..lineTo(edge * 0.96, y + 18);
      final right = Path()
        ..moveTo(size.width - edge * 0.18, y + 10)
        ..lineTo(size.width - edge * 0.54, y + 10)
        ..lineTo(size.width - edge * 0.68, y - 8)
        ..lineTo(size.width - edge * 0.98, y - 8);
      canvas.drawPath(left, soft);
      canvas.drawPath(right, soft);
      canvas.drawPath(left, row.isEven ? crystalLine : goldLine);
      canvas.drawPath(right, row.isEven ? goldLine : crystalLine);
      _paintDiamond(canvas, Offset(edge * 0.68, y + 18), 7, fill);
      _paintDiamond(canvas, Offset(size.width - edge * 0.68, y - 8), 7, fill);
    }

    final topRail = Path()..moveTo(edge * 0.42, 34);
    for (var x = edge * 0.42; x < size.width - edge * 0.42; x += 74) {
      topRail.cubicTo(x + 18, 14, x + 54, 54, x + 74, 34);
    }
    canvas.drawPath(topRail, goldLine);

    for (var i = 0; i < (detailed ? 18 : 10); i++) {
      final x = edge * 0.28 + (i * 73 % max(1, (size.width - edge).round()));
      final y = 58.0 + (i * 41 % max(1, (size.height - 120).round()));
      _paintStar(
        canvas,
        Offset(x.toDouble(), y.toDouble()),
        3.0 + (i % 3),
        i.isEven ? crystalLine : goldLine,
      );
    }

    final menuCenter = Offset(size.width / 2, min(size.height * 0.18, 126.0));
    final menu = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: menuCenter,
        width: detailed ? 154 : 112,
        height: detailed ? 58 : 42,
      ),
      Radius.circular(detailed ? 12 : 9),
    );
    canvas.drawRRect(menu, fill);
    canvas.drawRRect(menu, crystalLine);
    for (var i = 0; i < 3; i++) {
      final y = menuCenter.dy - (detailed ? 16 : 11) + i * (detailed ? 16 : 11);
      canvas.drawLine(
        Offset(menu.left + 22, y),
        Offset(menu.right - 16, y),
        i.isEven ? goldLine : paint,
      );
    }
    final cursor = Path()
      ..moveTo(menu.left + 10, menuCenter.dy - 9)
      ..lineTo(menu.left + 24, menuCenter.dy)
      ..lineTo(menu.left + 10, menuCenter.dy + 9)
      ..close();
    canvas.drawPath(cursor, fill);
    canvas.drawPath(cursor, accent);
  }

  void _paintRoguelike(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && size.width >= 720;
    final scratch = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = detailed ? 1.34 : 0.95
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * (detailed ? 1.26 : 0.96))
            .clamp(0.08, detailed ? 0.30 : 0.20)
            .toDouble(),
      );
    final grime = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = detailed ? 3.6 : 1.8
      ..color = spec.primary.withValues(
        alpha: (spec.opacity * 0.16).clamp(0.02, 0.08).toDouble(),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    _paintCornerFlourishes(canvas, size, edge, paint, accent);
    for (var row = 0; row < (detailed ? 7 : 4); row++) {
      final y = size.height * (0.10 + row * (detailed ? 0.12 : 0.20));
      final left = Path()
        ..moveTo(edge * 0.18, y + (row.isEven ? 0 : 8))
        ..lineTo(edge * 0.58, y - 8)
        ..lineTo(edge * 0.92, y + 18);
      final right = Path()
        ..moveTo(size.width - edge * 0.18, y)
        ..lineTo(size.width - edge * 0.56, y + 12)
        ..lineTo(size.width - edge * 0.88, y - 12);
      canvas.drawPath(left, grime);
      canvas.drawPath(right, grime);
      canvas.drawPath(left, row.isEven ? scratch : paint);
      canvas.drawPath(right, row.isEven ? paint : scratch);
    }

    for (var i = 0; i < (detailed ? 18 : 10); i++) {
      final x = edge * 0.22 + (i * 79 % max(1, (size.width - edge).round()));
      final y = 48.0 + (i * 47 % max(1, (size.height - 96).round()));
      canvas.drawCircle(Offset(x.toDouble(), y.toDouble()), 2.2 + i % 3, fill);
      if (i % 3 == 0) {
        canvas.drawLine(
          Offset(x.toDouble() - 9, y.toDouble() + 7),
          Offset(x.toDouble() + 12, y.toDouble() - 6),
          scratch,
        );
      }
    }
  }

  void _paintSouls(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && size.width >= 720;
    final ember = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = detailed ? 1.38 : 1.0
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * (detailed ? 1.22 : 0.92))
            .clamp(0.08, detailed ? 0.28 : 0.19)
            .toDouble(),
      );
    final ash = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.primary.withValues(
        alpha: (spec.opacity * 0.26).clamp(0.025, 0.11).toDouble(),
      );

    canvas.drawLine(
      Offset(edge * 0.24, 36),
      Offset(size.width - edge * 0.24, 36),
      ember,
    );
    canvas.drawLine(
      Offset(edge * 0.24, size.height - 36),
      Offset(size.width - edge * 0.24, size.height - 36),
      paint,
    );
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < (detailed ? 6 : 4); i++) {
        final y = size.height * (0.14 + i * (detailed ? 0.13 : 0.19));
        final sword = Path()
          ..moveTo(side + dir * edge * 0.34, y - 30)
          ..lineTo(side + dir * edge * 0.41, y + 16)
          ..lineTo(side + dir * edge * 0.34, y + 44)
          ..lineTo(side + dir * edge * 0.27, y + 16)
          ..close();
        canvas.drawPath(sword, ash);
        canvas.drawPath(sword, i.isEven ? ember : paint);
      }
    }
    for (var i = 0; i < (detailed ? 22 : 12); i++) {
      final x = edge * 0.28 + (i * 91 % max(1, (size.width - edge).round()));
      final y = size.height - 54 - (i * 37 % 160);
      canvas.drawCircle(
        Offset(x.toDouble(), y.toDouble()),
        1.8 + (i % 3) * 0.6,
        i.isEven ? ash : fill,
      );
    }
  }

  void _paintBoltedMetal(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && size.width >= 720;
    final metal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = detailed ? 1.25 : 0.95
      ..color = spec.primary.withValues(
        alpha: (spec.opacity * (detailed ? 1.16 : 0.92))
            .clamp(0.08, detailed ? 0.30 : 0.20)
            .toDouble(),
      );
    final oxide = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * 0.32).clamp(0.03, 0.12).toDouble(),
      );

    for (var y = 42.0; y < size.height - 28; y += detailed ? 78 : 96) {
      canvas.drawLine(
        Offset(edge * 0.18, y),
        Offset(size.width - edge * 0.18, y),
        metal,
      );
    }
    for (
      var x = edge * 0.28;
      x < size.width - edge * 0.20;
      x += detailed ? 98 : 120
    ) {
      canvas.drawLine(Offset(x, 26), Offset(x, size.height - 26), accent);
    }
    for (var i = 0; i < (detailed ? 16 : 10); i++) {
      final x = edge * 0.24 + (i * 103 % max(1, (size.width - edge).round()));
      final y = 46.0 + (i * 67 % max(1, (size.height - 92).round()));
      final c = Offset(x.toDouble(), y.toDouble());
      canvas.drawCircle(c, 5.0 + i % 2, fill);
      canvas.drawCircle(c, 8.0 + i % 2, metal);
      if (spec.presetId.contains('copper') && i % 3 == 0) {
        _paintDiamond(canvas, c.translate(15, 4), 6, oxide);
      }
    }
  }

  void _paintWildCompanion(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && size.width >= 720;
    final vinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = detailed ? 1.28 : 0.92
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * (detailed ? 1.14 : 0.84))
            .clamp(0.07, detailed ? 0.27 : 0.18)
            .toDouble(),
      );

    final top = Path()..moveTo(edge * 0.24, 42);
    for (var x = edge * 0.24; x < size.width - edge * 0.24; x += 86) {
      top.cubicTo(x + 24, 14, x + 60, 70, x + 86, 42);
    }
    canvas.drawPath(top, vinePaint);
    final bottom = Path()..moveTo(edge * 0.22, size.height - 44);
    for (var x = edge * 0.22; x < size.width - edge * 0.22; x += 92) {
      bottom.cubicTo(
        x + 24,
        size.height - 78,
        x + 62,
        size.height - 14,
        x + 92,
        size.height - 44,
      );
    }
    canvas.drawPath(bottom, paint);

    for (var i = 0; i < (detailed ? 12 : 7); i++) {
      final x = edge * 0.30 + (i * 83 % max(1, (size.width - edge).round()));
      final y = 58.0 + (i * 53 % max(1, (size.height - 128).round()));
      final c = Offset(x.toDouble(), y.toDouble());
      if (i.isEven) {
        _paintBotanicalLeaf(
          canvas,
          c,
          i % 4 == 0 ? 1 : -1,
          20,
          fill,
          vinePaint,
        );
      } else {
        _paintTinyPanelStar(canvas, c, 4, accent);
      }
    }
  }

  void _paintModernSchool(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && size.width >= 720;
    final notebookLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = detailed ? 1.12 : 0.82
      ..color = spec.primary.withValues(
        alpha: (spec.opacity * (detailed ? 1.05 : 0.78))
            .clamp(0.06, detailed ? 0.24 : 0.16)
            .toDouble(),
      );
    final pinkInk = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = detailed ? 1.28 : 0.92
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * (detailed ? 1.18 : 0.90))
            .clamp(0.07, detailed ? 0.27 : 0.18)
            .toDouble(),
      );
    final blueWash = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.secondary.withValues(
        alpha: (spec.opacity * 0.20).clamp(0.025, 0.09).toDouble(),
      );

    _paintCornerFlourishes(canvas, size, edge, paint, accent);

    for (var y = detailed ? 48.0 : 56.0; y < size.height - 36; y += 42) {
      canvas.drawLine(
        Offset(edge * 0.18, y),
        Offset(size.width - edge * 0.18, y + ((y.round().isEven) ? 2 : -2)),
        notebookLine,
      );
    }
    canvas.drawLine(
      Offset(edge * 0.36, 32),
      Offset(edge * 0.36, size.height - 32),
      pinkInk,
    );

    for (var i = 0; i < (detailed ? 10 : 6); i++) {
      final x = edge * 0.52 + (i * 89 % max(1, (size.width - edge).round()));
      final y = 58.0 + (i * 47 % max(1, (size.height - 116).round()));
      final c = Offset(x.toDouble(), y.toDouble());
      if (i.isEven) {
        final note = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: c,
            width: detailed ? 42 : 30,
            height: detailed ? 24 : 18,
          ),
          Radius.circular(detailed ? 5 : 4),
        );
        canvas.drawRRect(note, blueWash);
        canvas.drawRRect(note, pinkInk);
        canvas.drawLine(c.translate(-12, 1), c.translate(12, -3), notebookLine);
      } else {
        _paintTinyPanelStar(canvas, c, detailed ? 4.8 : 3.6, pinkInk);
      }
    }

    final penBase = Offset(size.width - edge * 0.44, size.height - 72);
    final pen = Path()
      ..moveTo(penBase.dx - 26, penBase.dy - 44)
      ..lineTo(penBase.dx + 28, penBase.dy + 10)
      ..lineTo(penBase.dx + 18, penBase.dy + 22)
      ..lineTo(penBase.dx - 36, penBase.dy - 34)
      ..close();
    canvas.drawPath(pen, blueWash);
    canvas.drawPath(pen, pinkInk);
    canvas.drawLine(
      penBase.translate(-18, -34),
      penBase.translate(20, 6),
      notebookLine,
    );
  }

  void _paintPostea(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && size.width >= 720;
    final circuit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = detailed ? 1.45 : 1.02
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * (detailed ? 1.42 : 1.02))
            .clamp(0.08, detailed ? 0.34 : 0.20)
            .toDouble(),
      );
    final soft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = detailed ? 4.2 : 2.0
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * 0.28).clamp(0.02, 0.10).toDouble(),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    _paintCornerFlourishes(canvas, size, edge, paint, accent);
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < (detailed ? 7 : 4); i++) {
        final y = size.height * (0.10 + i * (detailed ? 0.12 : 0.20));
        final path = Path()
          ..moveTo(side + dir * edge * 0.16, y)
          ..lineTo(side + dir * edge * 0.50, y)
          ..lineTo(side + dir * edge * 0.66, y + 22)
          ..lineTo(side + dir * edge * 0.98, y + 22);
        canvas.drawPath(path, soft);
        canvas.drawPath(path, i.isEven ? circuit : paint);
        _paintDiamond(
          canvas,
          Offset(side + dir * edge * 0.66, y + 22),
          detailed ? 8 : 6,
          fill,
        );
        if (detailed || i.isEven) {
          _paintSyntheticBloom(
            canvas,
            Offset(side + dir * edge * 1.06, y + 22),
            detailed ? 13 : 9,
            i.isEven ? circuit : paint,
            accent,
            fill,
          );
        }
      }
    }
    final bloomCount = detailed ? 5 : 3;
    for (var i = 0; i < bloomCount; i++) {
      final x =
          edge * 0.68 +
          i * ((size.width - edge * 1.36) / max(1, bloomCount - 1));
      final y = min(size.height - 50, 46 + (i % 2) * 18).toDouble();
      canvas.drawLine(
        Offset(x - 24, y + 12),
        Offset(x + 24, y - 12),
        i.isEven ? circuit : accent,
      );
      _paintSyntheticBloom(
        canvas,
        Offset(x, y),
        detailed ? 12 : 8,
        paint,
        i.isEven ? accent : circuit,
        fill,
      );
    }
    for (var i = 0; i < (detailed ? 11 : 6); i++) {
      final x =
          edge * 0.55 +
          i * ((size.width - edge * 1.10) / max(1, detailed ? 10 : 5));
      final y = size.height - (detailed ? 54 : 42) - (i % 3) * 9;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(x, y),
          width: detailed ? 42 : 30,
          height: 24,
        ),
        pi * 0.12,
        pi * 1.35,
        false,
        i.isEven ? accent : circuit,
      );
      _paintDiamond(canvas, Offset(x, y), detailed ? 5.5 : 4.5, fill);
      if (i % 3 == 1) {
        _paintSyntheticBloom(
          canvas,
          Offset(x, y - (detailed ? 24 : 18)),
          detailed ? 10 : 7,
          circuit,
          accent,
          fill,
        );
      }
    }
  }

  void _paintMedieval(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && size.width >= 720;
    final stoneFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          spec.primary.withValues(alpha: detailed ? 0.12 : 0.07),
          spec.backgroundMid.withValues(alpha: detailed ? 0.30 : 0.15),
          spec.backgroundBottom.withValues(alpha: 0.0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    final banner = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF7F2630).withValues(
        alpha: (spec.opacity * (detailed ? 0.86 : 0.55))
            .clamp(0.05, detailed ? 0.22 : 0.14)
            .toDouble(),
      );

    _paintCornerFlourishes(canvas, size, edge, paint, accent);
    _paintTopCurtain(canvas, size, edge, paint);

    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      final columnWidth = edge * (detailed ? 0.50 : 0.38);
      final x = side == 0 ? 0.0 : size.width - columnWidth;
      final column = Rect.fromLTWH(x, 0, columnWidth, size.height);
      canvas.drawRect(column, stoneFill);
      for (var row = 0; row < (detailed ? 13 : 8); row++) {
        final y = row * size.height / (detailed ? 12 : 7);
        final brickCount = detailed ? 4 : 3;
        for (var brick = 0; brick < brickCount; brick++) {
          final bx =
              side +
              dir *
                  (10 +
                      brick * columnWidth / brickCount +
                      (row.isEven ? 0 : columnWidth * 0.08));
          final rect = Rect.fromCenter(
            center: Offset(bx, y + 18),
            width: columnWidth * 0.28,
            height: detailed ? 13 : 10,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            row.isEven ? paint : accent,
          );
        }
      }

      for (var i = 0; i < (detailed ? 5 : 3); i++) {
        final c = Offset(
          side + dir * edge * (0.23 + (i % 2) * 0.16),
          size.height * (0.14 + i * (detailed ? 0.16 : 0.24)),
        );
        _paintMedievalShield(canvas, c, detailed ? 24 : 18, fill, accent);
        canvas.drawLine(
          c.translate(-dir * 28, -30),
          c.translate(dir * 18, 34),
          paint,
        );
        canvas.drawLine(
          c.translate(dir * 28, -30),
          c.translate(-dir * 18, 34),
          accent,
        );
      }
    }

    final keepWidth = min(size.width * 0.34, detailed ? 260.0 : 150.0);
    final keepHeight = detailed ? 150.0 : 96.0;
    final keep = Rect.fromCenter(
      center: Offset(size.width / 2, size.height - keepHeight * 0.34),
      width: keepWidth,
      height: keepHeight,
    );
    canvas.drawRect(keep, stoneFill);
    canvas.drawRect(keep, paint);
    final merlonCount = detailed ? 8 : 5;
    for (var i = 0; i < merlonCount; i++) {
      final merlon = Rect.fromLTWH(
        keep.left + 8 + i * ((keep.width - 16) / merlonCount),
        keep.top - keepHeight * 0.16,
        keep.width / (merlonCount * 1.7),
        keepHeight * 0.20,
      );
      canvas.drawRect(merlon, i.isEven ? fill : banner);
      canvas.drawRect(merlon, accent);
    }
    for (var row = 0; row < (detailed ? 6 : 4); row++) {
      final y = keep.top + 18 + row * keep.height / (detailed ? 7 : 5);
      for (
        var x = keep.left + 14 + (row.isEven ? 0 : 18);
        x < keep.right - 24;
        x += detailed ? 42 : 34
      ) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x + 24, y),
          row.isEven ? accent : paint,
        );
      }
    }
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(keep.center.dx, keep.bottom),
        width: keep.width * 0.20,
        height: keep.height * 0.40,
      ),
      pi,
      pi,
      false,
      accent,
    );
    for (final dx in <double>[-0.26, 0.26]) {
      final bannerPath = Path()
        ..moveTo(keep.center.dx + keep.width * dx, keep.top + 18)
        ..lineTo(keep.center.dx + keep.width * dx + 22, keep.top + 30)
        ..lineTo(keep.center.dx + keep.width * dx + 12, keep.top + 70)
        ..lineTo(keep.center.dx + keep.width * dx, keep.top + 58)
        ..close();
      canvas.drawPath(bannerPath, banner);
      canvas.drawPath(bannerPath, accent);
    }
  }

  void _paintShadowGate(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final detailed = desktop && size.width >= 720;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = detailed ? 3.4 : 2.0
      ..color = spec.accent.withValues(
        alpha: (spec.opacity * (detailed ? 1.40 : 0.92))
            .clamp(0.07, detailed ? 0.30 : 0.17)
            .toDouble(),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    _paintCornerFlourishes(canvas, size, edge, paint, accent, diamonds: false);
    final center = Offset(size.width / 2, size.height * 0.43);
    for (var i = 0; i < (detailed ? 6 : 3); i++) {
      final rect = Rect.fromCenter(
        center: center,
        width: size.width * (0.18 + i * 0.050),
        height: size.height * (0.28 + i * 0.055),
      );
      canvas.drawArc(
        rect,
        -pi * (0.15 + i * 0.018),
        pi * 1.32,
        false,
        i.isEven ? glow : accent,
      );
    }

    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < (detailed ? 9 : 5); i++) {
        final c = Offset(
          side + dir * edge * (0.22 + (i % 3) * 0.12),
          size.height * (0.10 + i * (detailed ? 0.09 : 0.16)),
        );
        canvas.drawLine(
          c.translate(-dir * 18, -18),
          c.translate(dir * 18, 18),
          paint,
        );
        canvas.drawLine(
          c.translate(dir * 18, -18),
          c.translate(-dir * 18, 18),
          accent,
        );
        _paintDiamond(canvas, c, detailed ? 7 : 5.5, fill);
      }
    }
  }

  void _paintPhobia(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final smoke = Paint()
      ..style = PaintingStyle.fill
      ..shader =
          RadialGradient(
            colors: [
              _oculumDecorationGradientColor(
                spec.accent,
                spec.backgroundBottom,
                spec.opacity * 0.46,
              ),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCenter(
              center: Offset(size.width / 2, size.height * 0.45),
              width: size.width * 0.92,
              height: size.height * 0.72,
            ),
          );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.46),
        width: size.width * 0.86,
        height: size.height * 0.64,
      ),
      smoke,
    );

    _paintCornerFlourishes(canvas, size, edge, paint, accent, diamonds: false);
    _paintEdgeBeads(canvas, size, edge, accent);

    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      final spine = Path()..moveTo(side + dir * 16, -28);
      for (var i = 0; i < 12; i++) {
        final y = size.height * i / 11;
        spine.cubicTo(
          side + dir * edge * 0.62,
          y + 10,
          side + dir * edge * 0.18,
          y + 34,
          side + dir * edge * 0.46,
          y + 66,
        );
      }
      canvas.drawPath(spine, paint);

      for (var i = 0; i < 8; i++) {
        final y = size.height * (0.08 + i * 0.115);
        final x = side + dir * edge * (0.22 + (i % 3) * 0.12);
        final claw = Path()
          ..moveTo(x, y - 30)
          ..quadraticBezierTo(
            x + dir * (36 + i % 2 * 10),
            y - 10,
            x + dir * 12,
            y + 50,
          )
          ..quadraticBezierTo(
            x + dir * (34 + i % 3 * 7),
            y + 16,
            x + dir * 44,
            y - 24,
          );
        canvas.drawPath(claw, i.isEven ? accent : paint);

        if (i % 2 == 0) {
          final eye = Offset(side + dir * edge * 0.66, y + 12);
          canvas.drawOval(
            Rect.fromCenter(center: eye, width: 52, height: 24),
            paint,
          );
          canvas.drawCircle(eye, 8, fill);
          canvas.drawCircle(eye.translate(dir * 1.5, -1), 3.2, accent);
          for (var ray = 0; ray < 7; ray++) {
            final angle = -pi * 0.72 + ray * pi * 0.24;
            canvas.drawLine(
              Offset(eye.dx + dir * cos(angle) * 27, eye.dy + sin(angle) * 12),
              Offset(eye.dx + dir * cos(angle) * 41, eye.dy + sin(angle) * 23),
              ray.isEven ? accent : paint,
            );
          }
        }
      }
    }

    final topY = min(70.0, max(38.0, size.height * 0.08));
    final jawTop = Path()..moveTo(edge * 0.64, topY);
    for (var x = edge * 0.64; x < size.width - edge * 0.64; x += 48) {
      jawTop
        ..quadraticBezierTo(x + 18, topY + 20, x + 34, topY)
        ..lineTo(x + 42, topY + 24)
        ..quadraticBezierTo(x + 30, topY + 8, x + 48, topY);
    }
    canvas.drawPath(jawTop, accent);

    final bottomY = size.height - min(56.0, max(34.0, size.height * 0.07));
    for (var i = 0; i < 14; i++) {
      final x = edge * 0.62 + i * ((size.width - edge * 1.24) / 13);
      final tooth = Path()
        ..moveTo(x - 8, bottomY)
        ..quadraticBezierTo(
          x - 2,
          bottomY - 16 - (i % 4) * 5,
          x,
          bottomY - 34 - (i % 3) * 7,
        )
        ..quadraticBezierTo(x + 4, bottomY - 15 - (i % 2) * 6, x + 9, bottomY)
        ..close();
      canvas.drawPath(tooth, i.isEven ? fill : paint);
    }

    final center = Offset(size.width / 2, min(size.height * 0.18, 128));
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 120, height: 46),
      paint,
    );
    canvas.drawCircle(center, 16, fill);
    canvas.drawCircle(center, 5, accent);
    for (var i = 0; i < 10; i++) {
      final angle = i * pi / 5;
      canvas.drawLine(
        Offset(center.dx + cos(angle) * 62, center.dy + sin(angle) * 24),
        Offset(center.dx + cos(angle) * 86, center.dy + sin(angle) * 36),
        i.isEven ? accent : paint,
      );
    }

    for (var i = 0; i < 16; i++) {
      final x = size.width * (0.18 + (i % 8) * 0.09);
      final y = size.height * (0.24 + (i ~/ 8) * 0.46) + (i % 3) * 10;
      canvas.drawLine(Offset(x, y), Offset(x + 24, y + 8), accent);
      canvas.drawLine(Offset(x + 8, y + 14), Offset(x + 31, y + 25), paint);
    }
  }

  void _paintOculumFortress(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    _paintMedieval(canvas, size, edge, paint, accent, fill);

    final detailed = desktop && size.width >= 720;
    final fortressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = detailed ? 1.65 : 1.20
      ..color = spec.accent.withValues(alpha: spec.opacity * 1.28);
    final metalFill = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.secondary.withValues(alpha: spec.opacity * 0.72);
    final glow = Paint()
      ..style = PaintingStyle.fill
      ..color = spec.accent.withValues(alpha: spec.opacity * 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    final topY = detailed ? 78.0 : 54.0;
    final center = Offset(size.width / 2, topY);
    final width = min(size.width * 0.34, detailed ? 230.0 : 150.0);
    final gate = Path()
      ..moveTo(center.dx - width * 0.48, center.dy + width * 0.18)
      ..lineTo(center.dx - width * 0.40, center.dy - width * 0.08)
      ..lineTo(center.dx - width * 0.18, center.dy - width * 0.28)
      ..lineTo(center.dx, center.dy - width * 0.16)
      ..lineTo(center.dx + width * 0.18, center.dy - width * 0.28)
      ..lineTo(center.dx + width * 0.40, center.dy - width * 0.08)
      ..lineTo(center.dx + width * 0.48, center.dy + width * 0.18)
      ..close();
    canvas.drawPath(gate, glow);
    canvas.drawPath(gate, metalFill);
    canvas.drawPath(gate, fortressPaint);

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: width * 0.58,
        height: width * 0.30,
      ),
      fortressPaint,
    );
    canvas.drawCircle(center, width * 0.095, fill);
    canvas.drawCircle(center, width * 0.040, accent);

    for (final side in <double>[-1, 1]) {
      final x = side < 0 ? edge * 0.34 : size.width - edge * 0.34;
      final tower = Rect.fromCenter(
        center: Offset(x, size.height * 0.50),
        width: edge * 0.20,
        height: size.height * (detailed ? 0.56 : 0.46),
      );
      canvas.drawRect(tower, metalFill);
      canvas.drawRect(tower, fortressPaint);
      for (var i = 0; i < 4; i++) {
        final y = tower.top + tower.height * (0.18 + i * 0.20);
        _paintDiamond(
          canvas,
          Offset(x, y),
          detailed ? 10 : 7,
          i.isEven ? accent : fill,
        );
      }
    }

    _paintSigils(canvas, size, edge * 0.82, paint, accent);
  }

  void _paintSigils(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
  ) {
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < 4; i++) {
        final center = Offset(
          side + dir * edge * 0.42,
          size.height * (0.16 + i * 0.24),
        );
        final radius = 28.0 + i * 3;
        canvas.drawCircle(center, radius, paint);
        canvas.drawCircle(center, radius * 0.56, accent);
        final path = Path();
        for (var p = 0; p < 6; p++) {
          final angle = -pi / 2 + p * pi / 3;
          final point = Offset(
            center.dx + cos(angle) * radius,
            center.dy + sin(angle) * radius,
          );
          if (p == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, accent);
      }
    }
    _paintCornerFlourishes(canvas, size, edge, paint, accent);
    _paintEdgeBeads(canvas, size, edge, paint);
    _paintSideGlyphs(canvas, size, edge, paint, accent, glyph: 'circle');
    for (var i = 0; i < 9; i++) {
      final x = size.width * (0.16 + i * 0.085);
      final top = 32.0 + (i % 3) * 7;
      final bottom = size.height - top;
      _paintDiamond(canvas, Offset(x, top), 10, accent);
      canvas.drawCircle(Offset(x, bottom), 10, paint);
      canvas.drawLine(Offset(x - 9, top), Offset(x + 9, top), paint);
      canvas.drawLine(Offset(x, bottom - 9), Offset(x, bottom + 9), accent);
    }
  }

  void _paintFrost(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
  ) {
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < 8; i++) {
        final center = Offset(
          side + dir * edge * (0.22 + (i % 3) * 0.16),
          size.height * (0.08 + i * 0.12),
        );
        final r = 18.0 + (i % 3) * 5;
        canvas.drawLine(
          Offset(center.dx - dir * r, center.dy),
          Offset(center.dx + dir * r, center.dy),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - r),
          Offset(center.dx, center.dy + r),
          accent,
        );
        canvas.drawLine(
          Offset(center.dx - dir * r * .7, center.dy - r * .7),
          Offset(center.dx + dir * r * .7, center.dy + r * .7),
          paint,
        );
      }
    }
    _paintCornerFlourishes(canvas, size, edge, paint, accent, diamonds: false);
    _paintEdgeBeads(canvas, size, edge, accent);
    _paintSideGlyphs(canvas, size, edge, paint, accent, glyph: 'star');
    for (var i = 0; i < 10; i++) {
      final x = size.width * (0.10 + i * 0.085);
      final length = 18.0 + (i % 4) * 7;
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + 7, length)
        ..lineTo(x - 6, length * 0.82)
        ..close();
      canvas.drawPath(path, i.isEven ? paint : accent);
    }
  }

  void _paintStorm(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    _paintCornerFlourishes(canvas, size, edge, paint, accent);
    _paintEdgeBeads(canvas, size, edge, accent);
    _paintTopCurtain(canvas, size, edge, paint);

    for (var i = 0; i < 9; i++) {
      final x = size.width * (0.10 + i * 0.095);
      final y = 20.0 + (i % 3) * 9;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(x, y), width: 62, height: 30),
        pi,
        pi,
        false,
        i.isEven ? paint : accent,
      );
    }

    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < 5; i++) {
        final startY = size.height * (0.12 + i * 0.17);
        final x = side + dir * edge * 0.60;
        final bolt = Path()
          ..moveTo(x, startY)
          ..lineTo(x + dir * 24, startY + 34)
          ..lineTo(x + dir * 9, startY + 34)
          ..lineTo(x + dir * 34, startY + 82)
          ..lineTo(x + dir * 18, startY + 50)
          ..lineTo(x + dir * 34, startY + 50);
        canvas.drawPath(bolt, i.isEven ? accent : paint);
      }
    }

    final rain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = spec.primary.withValues(alpha: spec.opacity * 0.62);
    for (var i = 0; i < 34; i++) {
      final side = i.isEven ? 0.0 : size.width;
      final dir = side == 0 ? 1.0 : -1.0;
      final y = size.height * ((i * 37 % 100) / 100);
      final x = side + dir * (18 + (i * 29 % edge).toDouble());
      canvas.drawLine(Offset(x, y), Offset(x + dir * 14, y + 28), rain);
    }
    _paintSideGlyphs(canvas, size, edge, paint, accent, glyph: 'star');
  }

  void _paintTide(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    _paintCornerFlourishes(canvas, size, edge, paint, accent, diamonds: false);
    for (var row = 0; row < 3; row++) {
      final y = size.height - 30 - row * 32;
      final wave = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width + 42; x += 42) {
        wave.quadraticBezierTo(x + 21, y - 22, x + 42, y);
      }
      canvas.drawPath(wave, row.isEven ? paint : accent);
    }

    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < 7; i++) {
        final y = size.height * (0.10 + i * 0.12);
        final path = Path()
          ..moveTo(side + dir * 10, y)
          ..quadraticBezierTo(
            side + dir * edge * 0.52,
            y - 34,
            side + dir * edge * 0.82,
            y + 4,
          )
          ..quadraticBezierTo(
            side + dir * edge * 0.48,
            y + 32,
            side + dir * 18,
            y + 48,
          );
        canvas.drawPath(path, i.isEven ? paint : accent);
        canvas.drawCircle(
          Offset(side + dir * edge * (0.36 + (i % 3) * 0.12), y + 18),
          4 + (i % 3) * 1.5,
          fill,
        );
      }
    }

    _paintEdgeBeads(canvas, size, edge, accent);
    _paintSideGlyphs(canvas, size, edge, paint, accent, glyph: 'circle');
  }

  void _paintEmber(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    _paintCornerFlourishes(canvas, size, edge, paint, accent);
    _paintEdgeBeads(canvas, size, edge, accent);
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < 6; i++) {
        final base = Offset(
          side + dir * edge * (0.34 + (i % 2) * 0.18),
          size.height * (0.16 + i * 0.13),
        );
        final candle = Rect.fromCenter(
          center: base.translate(0, 24),
          width: 14,
          height: 36,
        );
        canvas.drawRect(candle, paint);
        final flame = Path()
          ..moveTo(base.dx, base.dy - 18)
          ..quadraticBezierTo(
            base.dx + dir * 18,
            base.dy + 4,
            base.dx,
            base.dy + 18,
          )
          ..quadraticBezierTo(
            base.dx - dir * 16,
            base.dy + 2,
            base.dx,
            base.dy - 18,
          )
          ..close();
        canvas.drawPath(flame, i.isEven ? accent : fill);
      }
    }

    for (var i = 0; i < 30; i++) {
      final x = i.isEven
          ? 16 + (i * 31 % edge).toDouble()
          : size.width - 16 - (i * 31 % edge).toDouble();
      final y = size.height * ((i * 17 % 100) / 100);
      _paintStar(
        canvas,
        Offset(x, y),
        3.5 + (i % 3),
        i.isEven ? accent : paint,
      );
    }

    for (var x = edge * 0.6; x < size.width - edge * 0.6; x += 72) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(x, 34), width: 44, height: 70),
        -pi * 0.05,
        -pi * 0.90,
        false,
        paint,
      );
    }
  }

  void _paintArchive(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    _paintCornerFlourishes(canvas, size, edge, paint, accent);
    _paintEdgeBeads(canvas, size, edge, paint);

    for (var i = 0; i < 7; i++) {
      final yTop = 22.0 + i * 11;
      final yBottom = size.height - 22.0 - i * 11;
      canvas.drawLine(
        Offset(edge * 0.75, yTop),
        Offset(size.width - edge * 0.75, yTop),
        i.isEven ? paint : accent,
      );
      canvas.drawLine(
        Offset(edge * 0.75, yBottom),
        Offset(size.width - edge * 0.75, yBottom),
        i.isEven ? accent : paint,
      );
    }

    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < 8; i++) {
        final center = Offset(
          side + dir * edge * (0.30 + (i % 2) * 0.20),
          size.height * (0.10 + i * 0.105),
        );
        final rune = Path()
          ..moveTo(center.dx, center.dy - 14)
          ..lineTo(center.dx, center.dy + 14)
          ..moveTo(center.dx, center.dy - 4)
          ..lineTo(center.dx + dir * 16, center.dy - 14)
          ..moveTo(center.dx, center.dy + 4)
          ..lineTo(center.dx + dir * 14, center.dy + 14);
        canvas.drawPath(rune, i.isEven ? paint : accent);
        if (i % 3 == 0) {
          _paintDiamond(canvas, center.translate(dir * 28, 0), 6, fill);
        }
      }
    }

    _paintRoseWindow(canvas, Offset(size.width / 2, 58), 18, accent, paint);
  }

  void _paintSlime(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    _paintCornerFlourishes(canvas, size, edge, paint, accent, diamonds: false);
    final drip = Path()..moveTo(0, 22);
    for (var x = 0.0; x <= size.width + 42; x += 42) {
      final extraDrop = (x ~/ 42).isEven ? 28.0 : 10.0;
      drip.quadraticBezierTo(x + 20, 22 + extraDrop, x + 42, 22);
    }
    canvas.drawPath(drip, fill);

    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < 9; i++) {
        final y = size.height * (0.10 + i * 0.10);
        final center = Offset(side + dir * edge * (0.28 + (i % 3) * 0.12), y);
        canvas.drawCircle(center, 8 + (i % 3) * 3, i.isEven ? fill : paint);
        canvas.drawCircle(center.translate(dir * 4, -3), 2.4, accent);
      }
    }

    final crownTop = min(88.0, size.height * 0.12);
    final crown = Path()
      ..moveTo(size.width / 2 - 48, crownTop + 42)
      ..lineTo(size.width / 2 - 30, crownTop)
      ..lineTo(size.width / 2 - 8, crownTop + 32)
      ..lineTo(size.width / 2 + 16, crownTop - 4)
      ..lineTo(size.width / 2 + 42, crownTop + 42);
    canvas.drawPath(crown, accent);
    _paintSlimePrinceDoodle(canvas, size);
    _paintEdgeBeads(canvas, size, edge, accent);
  }

  void _paintSlimePrinceDoodle(Canvas canvas, Size size) {
    final bodyWidth = min(
      desktop ? 250.0 : 154.0,
      max(desktop ? 176.0 : 112.0, size.width * (desktop ? 0.19 : 0.34)),
    );
    final bodyHeight = bodyWidth * 0.72;
    final groundY = size.height - (desktop ? 34.0 : 22.0);
    final center = Offset(
      size.width - bodyWidth * 0.60 - (desktop ? 32.0 : 16.0),
      groundY - bodyHeight * 0.44,
    );
    final alpha = (spec.opacity * (desktop ? 1.82 : 1.45))
        .clamp(0.16, desktop ? 0.54 : 0.38)
        .toDouble();
    final slime = Paint()
      ..style = PaintingStyle.fill
      ..shader =
          RadialGradient(
            center: const Alignment(-0.28, -0.64),
            radius: 0.92,
            colors: [
              const Color(0xFFE9FFD8).withValues(alpha: alpha * 0.95),
              const Color(0xFF68E85C).withValues(alpha: alpha * 0.82),
              const Color(0xFF1E8A38).withValues(alpha: alpha * 0.62),
            ],
            stops: const [0.0, 0.54, 1.0],
          ).createShader(
            Rect.fromCenter(
              center: center,
              width: bodyWidth,
              height: bodyHeight,
            ),
          );
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = desktop ? 2.1 : 1.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF9BFF86).withValues(alpha: alpha);
    final gold = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE7C45A).withValues(alpha: alpha * 0.92);
    final violet = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF7C63DD).withValues(alpha: alpha * 0.70);
    final white = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: alpha * 0.76);
    final dark = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF183322).withValues(alpha: alpha * 1.08);

    final cape = Path()
      ..moveTo(center.dx + bodyWidth * 0.05, center.dy + bodyHeight * 0.02)
      ..quadraticBezierTo(
        center.dx + bodyWidth * 0.54,
        center.dy + bodyHeight * 0.08,
        center.dx + bodyWidth * 0.50,
        center.dy + bodyHeight * 0.50,
      )
      ..quadraticBezierTo(
        center.dx + bodyWidth * 0.22,
        center.dy + bodyHeight * 0.54,
        center.dx + bodyWidth * 0.12,
        center.dy + bodyHeight * 0.23,
      )
      ..close();
    canvas.drawPath(cape, violet);
    canvas.drawCircle(
      center.translate(bodyWidth * 0.36, bodyHeight * 0.46),
      bodyWidth * 0.055,
      white,
    );
    canvas.drawCircle(
      center.translate(bodyWidth * 0.22, bodyHeight * 0.45),
      bodyWidth * 0.050,
      white,
    );

    final body = Path()
      ..moveTo(center.dx - bodyWidth * 0.44, center.dy + bodyHeight * 0.18)
      ..cubicTo(
        center.dx - bodyWidth * 0.50,
        center.dy - bodyHeight * 0.22,
        center.dx - bodyWidth * 0.20,
        center.dy - bodyHeight * 0.46,
        center.dx + bodyWidth * 0.02,
        center.dy - bodyHeight * 0.43,
      )
      ..cubicTo(
        center.dx + bodyWidth * 0.40,
        center.dy - bodyHeight * 0.40,
        center.dx + bodyWidth * 0.54,
        center.dy - bodyHeight * 0.05,
        center.dx + bodyWidth * 0.42,
        center.dy + bodyHeight * 0.23,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + bodyHeight * 0.38,
        center.dx - bodyWidth * 0.44,
        center.dy + bodyHeight * 0.18,
      )
      ..close();
    canvas.drawPath(body, slime);
    canvas.drawPath(body, outline);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-bodyWidth * 0.18, -bodyHeight * 0.25),
        width: bodyWidth * 0.30,
        height: bodyHeight * 0.08,
      ),
      white,
    );
    for (final dir in <double>[-1, 1]) {
      final eye = center.translate(dir * bodyWidth * 0.15, -bodyHeight * 0.02);
      canvas.drawOval(
        Rect.fromCenter(
          center: eye,
          width: bodyWidth * 0.095,
          height: bodyHeight * 0.18,
        ),
        dark,
      );
      canvas.drawCircle(eye.translate(dir * 2, -3), bodyWidth * 0.018, white);
    }
    final expression = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = desktop ? 2.2 : 1.45
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF183322).withValues(alpha: alpha * 0.92);
    final cheek = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE7C45A).withValues(alpha: alpha * 0.34);
    final smile = Path()
      ..moveTo(center.dx - bodyWidth * 0.11, center.dy + bodyHeight * 0.11)
      ..quadraticBezierTo(
        center.dx,
        center.dy + bodyHeight * 0.22,
        center.dx + bodyWidth * 0.11,
        center.dy + bodyHeight * 0.11,
      );
    canvas.drawPath(smile, expression);
    canvas.drawCircle(
      center.translate(-bodyWidth * 0.25, bodyHeight * 0.10),
      bodyWidth * 0.026,
      cheek,
    );
    canvas.drawCircle(
      center.translate(bodyWidth * 0.25, bodyHeight * 0.10),
      bodyWidth * 0.026,
      cheek,
    );

    final crownBase = center.translate(0, -bodyHeight * 0.43);
    final crown = Path()
      ..moveTo(
        crownBase.dx - bodyWidth * 0.22,
        crownBase.dy + bodyHeight * 0.16,
      )
      ..lineTo(
        crownBase.dx - bodyWidth * 0.16,
        crownBase.dy - bodyHeight * 0.14,
      )
      ..lineTo(
        crownBase.dx - bodyWidth * 0.05,
        crownBase.dy + bodyHeight * 0.07,
      )
      ..lineTo(
        crownBase.dx + bodyWidth * 0.05,
        crownBase.dy - bodyHeight * 0.17,
      )
      ..lineTo(
        crownBase.dx + bodyWidth * 0.16,
        crownBase.dy + bodyHeight * 0.07,
      )
      ..lineTo(
        crownBase.dx + bodyWidth * 0.23,
        crownBase.dy + bodyHeight * 0.16,
      )
      ..close();
    canvas.drawPath(crown, gold);
    canvas.drawPath(crown, outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: crownBase.translate(0, bodyHeight * 0.14),
          width: bodyWidth * 0.44,
          height: bodyHeight * 0.075,
        ),
        Radius.circular(bodyHeight * 0.035),
      ),
      gold,
    );
    canvas.drawCircle(
      crownBase.translate(bodyWidth * 0.05, -bodyHeight * 0.04),
      bodyWidth * 0.025,
      violet,
    );

    final staffTop = center.translate(bodyWidth * 0.56, -bodyHeight * 0.24);
    final staffBottom = center.translate(bodyWidth * 0.34, bodyHeight * 0.38);
    canvas.drawLine(staffTop, staffBottom, outline);
    canvas.drawCircle(staffTop, bodyWidth * 0.075, white);
    _paintDiamond(canvas, staffTop, bodyWidth * 0.052, gold);
  }

  void _paintObser(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    _paintReliquary(canvas, size, edge, paint, accent);
    _paintEdgeBeads(canvas, size, edge, paint);
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < 5; i++) {
        final center = Offset(
          side + dir * edge * (0.36 + (i % 2) * 0.20),
          size.height * (0.14 + i * 0.16),
        );
        canvas.drawOval(
          Rect.fromCenter(center: center, width: 58, height: 30),
          i.isEven ? paint : accent,
        );
        canvas.drawCircle(center, 11, fill);
        canvas.drawCircle(center, 4, i.isEven ? accent : paint);
        for (var ray = 0; ray < 6; ray++) {
          final angle = ray * pi / 3;
          canvas.drawLine(
            Offset(center.dx + cos(angle) * 34, center.dy + sin(angle) * 18),
            Offset(center.dx + cos(angle) * 45, center.dy + sin(angle) * 24),
            accent,
          );
        }
      }
    }
  }

  void _paintHoshy(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
    Paint fill,
  ) {
    final galaxyPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _oculumDecorationGradientColor(
            spec.backgroundBottom,
            spec.accent,
            spec.opacity * 2.4,
          ),
          _oculumDecorationGradientColor(
            spec.backgroundMid,
            spec.primary,
            spec.opacity * 1.45,
          ),
          _oculumDecorationGradientColor(
            spec.backgroundTop,
            spec.accent,
            spec.opacity * 0.82,
          ),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), galaxyPaint);

    final topCenter = Offset(size.width / 2, 18);
    final moonRadius = min(48.0, max(28.0, size.width * 0.035));
    canvas.drawCircle(
      topCenter.translate(0, moonRadius * 0.85),
      moonRadius,
      paint,
    );
    canvas.drawCircle(
      topCenter.translate(moonRadius * 0.35, moonRadius * 0.78),
      moonRadius * 0.92,
      fill,
    );

    _paintHoshySlimeCat(canvas, size);

    final earWidth = min(96.0, max(54.0, size.width * 0.075));
    final earHeight = earWidth * 0.92;
    for (final dir in <double>[-1, 1]) {
      final baseX = size.width / 2 + dir * (moonRadius + earWidth * 0.54);
      final path = Path()
        ..moveTo(baseX - dir * earWidth * 0.48, 28 + earHeight)
        ..lineTo(baseX, 24)
        ..lineTo(baseX + dir * earWidth * 0.48, 28 + earHeight)
        ..quadraticBezierTo(
          baseX,
          28 + earHeight * 0.72,
          baseX - dir * earWidth * 0.48,
          28 + earHeight,
        );
      canvas.drawPath(path, paint);
      final inner = Path()
        ..moveTo(baseX - dir * earWidth * 0.24, 38 + earHeight * 0.68)
        ..lineTo(baseX, 38)
        ..lineTo(baseX + dir * earWidth * 0.24, 38 + earHeight * 0.68);
      canvas.drawPath(inner, accent);
    }

    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < 13; i++) {
        final y = size.height * (0.08 + i * 0.075);
        final x = side + dir * (22 + (i * 37 % edge).toDouble());
        final r = 1.6 + (i % 4) * 0.8;
        canvas.drawCircle(Offset(x, y), r, fill);
        if (i % 3 == 0) {
          canvas.drawLine(
            Offset(x - dir * 7, y),
            Offset(x + dir * 7, y),
            accent,
          );
          canvas.drawLine(Offset(x, y - 7), Offset(x, y + 7), accent);
        }
      }
    }
    _paintCornerFlourishes(canvas, size, edge, paint, accent);
    _paintEdgeBeads(canvas, size, edge, accent);
    for (var i = 0; i < 4; i++) {
      final start = Offset(size.width * (0.12 + i * 0.10), size.height - 32);
      final end = Offset(
        size.width * (0.17 + i * 0.10),
        size.height - 74 - (i.isEven ? 0 : 18),
      );
      canvas.drawLine(start, end, paint);
      _paintStar(canvas, end, 5.5, accent);
    }
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      final y = min(156.0, size.height * 0.18);
      canvas.drawLine(
        Offset(side + dir * 18, y),
        Offset(side + dir * edge * 0.75, y + 18),
        accent,
      );
      canvas.drawLine(
        Offset(side + dir * 18, y + 24),
        Offset(side + dir * edge * 0.68, y + 38),
        paint,
      );
    }
  }

  void _paintHoshySlimeCat(Canvas canvas, Size size) {
    final catWidth = min(
      desktop ? 260.0 : 150.0,
      max(desktop ? 180.0 : 112.0, size.width * (desktop ? 0.20 : 0.36)),
    );
    final catHeight = catWidth * 0.66;
    final groundY = size.height - (desktop ? 38.0 : 24.0);
    final center = Offset(
      size.width - catWidth * 0.58 - (desktop ? 28.0 : 14.0),
      groundY - catHeight * 0.42,
    );
    final alpha = (spec.opacity * (desktop ? 1.92 : 1.55))
        .clamp(0.18, desktop ? 0.58 : 0.42)
        .toDouble();
    final slimeFill = Paint()
      ..style = PaintingStyle.fill
      ..shader =
          RadialGradient(
            center: const Alignment(-0.22, -0.62),
            radius: 0.96,
            colors: [
              const Color(0xFFE8FBFF).withValues(alpha: alpha * 0.90),
              const Color(0xFF8FD6FF).withValues(alpha: alpha * 0.76),
              const Color(0xFF4A9ED8).withValues(alpha: alpha * 0.58),
            ],
            stops: const [0.0, 0.54, 1.0],
          ).createShader(
            Rect.fromCenter(center: center, width: catWidth, height: catHeight),
          );
    final slimeStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = desktop ? 2.2 : 1.45
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFBDEEFF).withValues(alpha: alpha);
    final glass = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: alpha * 0.72);
    final eyePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF1F5670).withValues(alpha: alpha * 1.14);
    final grassPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF66D672).withValues(alpha: alpha * 0.70);
    final grassDark = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF2E8D5E).withValues(alpha: alpha * 0.62);

    final grassBase = Rect.fromCenter(
      center: Offset(center.dx, groundY - catHeight * 0.10),
      width: catWidth * 1.12,
      height: catHeight * 0.34,
    );
    for (var i = 0; i < 18; i++) {
      final t = i / 17;
      final x = grassBase.left + grassBase.width * t;
      final bladeHeight = catHeight * (0.17 + (i % 4) * 0.032);
      final blade = Path()
        ..moveTo(x, grassBase.bottom)
        ..quadraticBezierTo(
          x + (i.isEven ? -10 : 10),
          grassBase.bottom - bladeHeight * 0.54,
          x + (i.isEven ? -4 : 4),
          grassBase.bottom - bladeHeight,
        )
        ..quadraticBezierTo(
          x + (i.isEven ? 8 : -8),
          grassBase.bottom - bladeHeight * 0.34,
          x + 3,
          grassBase.bottom,
        )
        ..close();
      canvas.drawPath(blade, i.isEven ? grassPaint : grassDark);
    }

    final tail = Path()
      ..moveTo(center.dx - catWidth * 0.40, center.dy + catHeight * 0.03)
      ..cubicTo(
        center.dx - catWidth * 0.75,
        center.dy - catHeight * 0.04,
        center.dx - catWidth * 0.64,
        center.dy - catHeight * 0.44,
        center.dx - catWidth * 0.38,
        center.dy - catHeight * 0.26,
      )
      ..cubicTo(
        center.dx - catWidth * 0.54,
        center.dy - catHeight * 0.12,
        center.dx - catWidth * 0.54,
        center.dy + catHeight * 0.08,
        center.dx - catWidth * 0.39,
        center.dy + catHeight * 0.13,
      )
      ..close();
    canvas.drawPath(tail, slimeFill);
    canvas.drawPath(tail, slimeStroke);

    for (final dir in <double>[-1, 1]) {
      final ear = Path()
        ..moveTo(
          center.dx + dir * catWidth * 0.18,
          center.dy - catHeight * 0.28,
        )
        ..quadraticBezierTo(
          center.dx + dir * catWidth * 0.26,
          center.dy - catHeight * 0.62,
          center.dx + dir * catWidth * 0.38,
          center.dy - catHeight * 0.31,
        )
        ..quadraticBezierTo(
          center.dx + dir * catWidth * 0.28,
          center.dy - catHeight * 0.22,
          center.dx + dir * catWidth * 0.18,
          center.dy - catHeight * 0.28,
        );
      canvas.drawPath(ear, slimeFill);
      canvas.drawPath(ear, slimeStroke);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            center.dx + dir * catWidth * 0.30,
            center.dy - catHeight * 0.38,
          ),
          width: catWidth * 0.055,
          height: catHeight * 0.18,
        ),
        glass,
      );
    }

    final body = Path()
      ..moveTo(center.dx - catWidth * 0.42, center.dy + catHeight * 0.15)
      ..cubicTo(
        center.dx - catWidth * 0.48,
        center.dy - catHeight * 0.20,
        center.dx - catWidth * 0.24,
        center.dy - catHeight * 0.42,
        center.dx,
        center.dy - catHeight * 0.43,
      )
      ..cubicTo(
        center.dx + catWidth * 0.32,
        center.dy - catHeight * 0.44,
        center.dx + catWidth * 0.49,
        center.dy - catHeight * 0.17,
        center.dx + catWidth * 0.43,
        center.dy + catHeight * 0.16,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + catHeight * 0.32,
        center.dx - catWidth * 0.42,
        center.dy + catHeight * 0.15,
      )
      ..close();
    canvas.drawPath(body, slimeFill);
    canvas.drawPath(body, slimeStroke);

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(catWidth * 0.10, -catHeight * 0.26),
        width: catWidth * 0.26,
        height: catHeight * 0.07,
      ),
      glass,
    );
    canvas.drawCircle(
      center.translate(-catWidth * 0.30, -catHeight * 0.22),
      catWidth * 0.045,
      glass,
    );
    for (final dir in <double>[-1, 1]) {
      final eye = Offset(center.dx + dir * catWidth * 0.13, center.dy - 2);
      canvas.drawOval(
        Rect.fromCenter(
          center: eye,
          width: catWidth * 0.052,
          height: catHeight * 0.16,
        ),
        eyePaint,
      );
      canvas.drawCircle(
        eye.translate(dir * catWidth * 0.010, -catHeight * 0.040),
        catWidth * 0.010,
        glass,
      );
    }
    canvas.drawCircle(
      center.translate(0, catHeight * 0.07),
      catWidth * 0.012,
      eyePaint,
    );

    final whisker = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = desktop ? 1.45 : 1.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: alpha * 0.72);
    for (final dir in <double>[-1, 1]) {
      for (var i = 0; i < 3; i++) {
        final y = center.dy + catHeight * (0.03 + (i - 1) * 0.055);
        canvas.drawLine(
          Offset(center.dx + dir * catWidth * 0.18, y),
          Offset(
            center.dx + dir * catWidth * (0.40 + i * 0.035),
            y - (i - 1) * 7,
          ),
          whisker,
        );
      }
    }
  }

  void _paintReliquary(
    Canvas canvas,
    Size size,
    double edge,
    Paint paint,
    Paint accent,
  ) {
    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    canvas.drawRect(rect, paint);
    canvas.drawLine(const Offset(10, 70), Offset(edge, 10), accent);
    canvas.drawLine(
      Offset(size.width - 10, 70),
      Offset(size.width - edge, 10),
      accent,
    );
    canvas.drawLine(
      Offset(10, size.height - 70),
      Offset(edge, size.height - 10),
      accent,
    );
    canvas.drawLine(
      Offset(size.width - 10, size.height - 70),
      Offset(size.width - edge, size.height - 10),
      accent,
    );
    _paintCornerFlourishes(canvas, size, edge, paint, accent);
    _paintEdgeBeads(canvas, size, edge, accent);
    _paintRoseWindow(canvas, Offset(size.width / 2, 46), 22, paint, accent);
    for (final side in <double>[0, size.width]) {
      final dir = side == 0 ? 1.0 : -1.0;
      for (var i = 0; i < 5; i++) {
        final y = size.height * (0.18 + i * 0.15);
        final x = side + dir * edge * 0.56;
        final rect = Rect.fromCenter(
          center: Offset(x, y),
          width: 24,
          height: 38,
        );
        canvas.drawArc(rect, -pi / 2, pi * 2, false, i.isEven ? paint : accent);
        _paintDiamond(canvas, Offset(x, y), 5, accent);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OculumThemeDecorationPainter oldDelegate) {
    return oldDelegate.spec.presetId != spec.presetId ||
        oldDelegate.spec.style != spec.style ||
        oldDelegate.spec.primary != spec.primary ||
        oldDelegate.spec.secondary != spec.secondary ||
        oldDelegate.spec.accent != spec.accent ||
        oldDelegate.spec.backgroundTop != spec.backgroundTop ||
        oldDelegate.spec.backgroundMid != spec.backgroundMid ||
        oldDelegate.spec.backgroundBottom != spec.backgroundBottom ||
        oldDelegate.spec.opacity != spec.opacity ||
        oldDelegate.spec.usesBaseColors != spec.usesBaseColors ||
        oldDelegate.desktop != desktop;
  }
}
