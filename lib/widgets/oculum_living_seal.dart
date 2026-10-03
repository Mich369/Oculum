import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'oculum_memory_eye.dart';

/// The small campaign seal used by Oculum's shell.
///
/// It deliberately exposes the active story state instead of looking like a
/// generic assistant/avatar: the eye, the current sheet and the number of
/// recorded entries are always visible in one compact mark.
class OculumLivingSeal extends StatelessWidget {
  const OculumLivingSeal({
    super.key,
    required this.pageLabel,
    required this.campaignLabel,
    required this.sheetLabel,
    required this.entryCount,
    required this.online,
    this.compact = false,
    this.iconOnly = false,
    this.onPressed,
    this.accent = const Color(0xffc3a46b),
    this.secondary = const Color(0xff6b8b82),
  });

  final String pageLabel;
  final String campaignLabel;
  final String sheetLabel;
  final int entryCount;
  final bool online;
  final bool compact;
  final bool iconOnly;
  final VoidCallback? onPressed;
  final Color accent;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 31.0 : 37.0;
    final label = '$campaignLabel · $sheetLabel · $pageLabel';
    final eye = CustomPaint(
      size: Size.square(size),
      painter: _OculumSealPainter(
        accent: accent,
        secondary: secondary,
        entryCount: entryCount,
        online: online,
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 6 : 7),
        child: OculumMemoryEye(role: 'unknown', size: 22, color: accent),
      ),
    );
    final child = Semantics(
      button: onPressed != null,
      label: label,
      child: iconOnly
          ? eye
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                eye,
                const SizedBox(width: 7),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? 122 : 220),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaignLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accent,
                          fontSize: compact ? 8.5 : 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        '${online ? '●' : '○'}  $sheetLabel  ·  $entryCount ${entryCount == 1 ? 'pagina' : 'pagine'}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: online
                              ? secondary
                              : secondary.withValues(alpha: .7),
                          fontSize: compact ? 7.5 : 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .55,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );

    return onPressed == null
        ? child
        : Tooltip(
            message: label,
            child: InkWell(onTap: onPressed, child: child),
          );
  }
}

class _OculumSealPainter extends CustomPainter {
  const _OculumSealPainter({
    required this.accent,
    required this.secondary,
    required this.entryCount,
    required this.online,
  });

  final Color accent;
  final Color secondary;
  final int entryCount;
  final bool online;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final glow = Paint()
      ..color = accent.withValues(alpha: .12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, radius * .72, glow);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = online
          ? secondary.withValues(alpha: .9)
          : accent.withValues(alpha: .65);
    canvas.drawCircle(center, radius * .84, ring);

    final marks = math.min(12, math.max(3, entryCount));
    final markPaint = Paint()
      ..color = accent.withValues(alpha: online ? .9 : .55)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < marks; i++) {
      final angle = (math.pi * 2 * i / marks) - math.pi / 2;
      final start =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * .92;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(start, end, markPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OculumSealPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.secondary != secondary ||
        oldDelegate.entryCount != entryCount ||
        oldDelegate.online != online;
  }
}
