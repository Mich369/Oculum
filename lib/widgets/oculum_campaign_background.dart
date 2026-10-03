import 'package:flutter/material.dart';

const oculumBackgroundModes = <String, String>{
  'vertical': 'Sfumatura verticale',
  'horizontal': 'Sfumatura orizzontale',
  'diagonal': 'Sfumatura diagonale',
  'radial': 'Sfumatura radiale',
  'solid': 'Colore uniforme',
  'checker': 'Scacchi · due colori',
};

Gradient oculumBackgroundGradient(String mode, List<Color> colors) {
  if (mode == 'radial') return RadialGradient(radius: 1.2, colors: colors);
  return LinearGradient(
    colors: mode == 'solid' ? [colors.first, colors.first] : colors,
    begin: mode == 'horizontal'
        ? Alignment.centerLeft
        : mode == 'diagonal'
        ? Alignment.topLeft
        : Alignment.topCenter,
    end: mode == 'horizontal'
        ? Alignment.centerRight
        : mode == 'diagonal'
        ? Alignment.bottomRight
        : Alignment.bottomCenter,
  );
}

class OculumCheckerBackground extends CustomPainter {
  const OculumCheckerBackground(this.first, this.second);
  final Color first;
  final Color second;
  @override
  void paint(Canvas canvas, Size size) {
    const side = 48.0;
    canvas.drawRect(Offset.zero & size, Paint()..color = first);
    final paint = Paint()..color = second;
    for (var y = 0; y < (size.height / side).ceil(); y++) {
      for (var x = 0; x < (size.width / side).ceil(); x++) {
        if ((x + y).isOdd) {
          canvas.drawRect(Rect.fromLTWH(x * side, y * side, side, side), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(OculumCheckerBackground oldDelegate) =>
      oldDelegate.first != first || oldDelegate.second != second;
}
