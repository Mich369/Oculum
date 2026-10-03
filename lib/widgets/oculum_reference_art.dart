import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// The artwork is the user's own reference, displayed without recoloring.
// Cropping is a viewport operation; the original asset stays intact.
class OculumReferenceArt extends StatelessWidget {
  const OculumReferenceArt({
    super.key,
    this.combat = false,
    this.logo = false,
    this.height = 160,
  });
  final bool combat;
  final bool logo;
  final double height;
  static Future<ui.Image>? _image;
  static Future<ui.Image> loadArtwork() => _image ??= () async {
    final bytes = await rootBundle.load('assets/oculum/campaign_reference.png');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: FutureBuilder<ui.Image>(
        future: loadArtwork(),
        builder: (context, snapshot) => snapshot.hasData
            ? CustomPaint(
                painter: _ReferenceArtPainter(snapshot.data!, combat, logo),
                child: const SizedBox.expand(),
              )
            : const ColoredBox(color: Color(0xff0a0a0e)),
      ),
    ),
  );
}

class _ReferenceArtPainter extends CustomPainter {
  const _ReferenceArtPainter(this.image, this.combat, this.logo);
  final ui.Image image;
  final bool combat;
  final bool logo;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = logo
        ? const Rect.fromLTWH(24, 155, 105, 36)
        : combat
        ? const Rect.fromLTWH(1100, 199, 406, 81)
        : const Rect.fromLTWH(152, 205, 404, 245);
    final scaleX = image.width / 1536;
    final scaleY = image.height / 1024;
    final source = Rect.fromLTWH(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.width * scaleX,
      rect.height * scaleY,
    );
    final fitted = applyBoxFit(
      logo ? BoxFit.contain : BoxFit.cover,
      source.size,
      size,
    );
    final crop = Alignment.center.inscribe(fitted.source, source);
    canvas.drawImageRect(
      image,
      crop,
      logo
          ? Alignment.center.inscribe(fitted.destination, Offset.zero & size)
          : Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_ReferenceArtPainter old) =>
      old.image != image || old.combat != combat || old.logo != logo;
}
