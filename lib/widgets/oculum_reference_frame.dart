import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'oculum_reference_art.dart';

/// The author's frame artwork is drawn around live controls, with open center.
class OculumReferenceFrame extends StatelessWidget {
  const OculumReferenceFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => FutureBuilder<ui.Image>(
    future: OculumReferenceArt.loadArtwork(),
    builder: (context, snapshot) => CustomPaint(
      foregroundPainter: snapshot.hasData
          ? _ReferenceFramePainter(snapshot.data!)
          : null,
      child: child,
    ),
  );
}

class _ReferenceFramePainter extends CustomPainter {
  const _ReferenceFramePainter(this.image);
  final ui.Image image;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 48 || size.height < 48) return;
    const box = Rect.fromLTWH(582, 147, 484, 482);
    const corner = 20.0;
    const edge = 5.0;
    final sx = image.width / 1536, sy = image.height / 1024;
    void piece(Rect source, Rect destination) => canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        source.left * sx,
        source.top * sy,
        source.width * sx,
        source.height * sy,
      ),
      destination,
      Paint()..filterQuality = FilterQuality.medium,
    );
    for (final right in [false, true]) {
      for (final bottom in [false, true]) {
        piece(
          Rect.fromLTWH(
            right ? box.right - corner : box.left,
            bottom ? box.bottom - corner : box.top,
            corner,
            corner,
          ),
          Rect.fromLTWH(
            right ? size.width - corner : 0,
            bottom ? size.height - corner : 0,
            corner,
            corner,
          ),
        );
      }
    }
    piece(
      Rect.fromLTWH(box.left + corner, box.top, box.width - corner * 2, edge),
      Rect.fromLTWH(corner, 0, size.width - corner * 2, edge),
    );
    piece(
      Rect.fromLTWH(
        box.left + corner,
        box.bottom - edge,
        box.width - corner * 2,
        edge,
      ),
      Rect.fromLTWH(corner, size.height - edge, size.width - corner * 2, edge),
    );
    piece(
      Rect.fromLTWH(box.left, box.top + corner, edge, box.height - corner * 2),
      Rect.fromLTWH(0, corner, edge, size.height - corner * 2),
    );
    piece(
      Rect.fromLTWH(
        box.right - edge,
        box.top + corner,
        edge,
        box.height - corner * 2,
      ),
      Rect.fromLTWH(size.width - edge, corner, edge, size.height - corner * 2),
    );
  }

  @override
  bool shouldRepaint(_ReferenceFramePainter old) => old.image != image;
}
