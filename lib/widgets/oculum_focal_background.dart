import 'package:flutter/material.dart';

/// A point in source-image coordinates, not a fixed left/right crop alignment.
/// This keeps a subject centered as the viewport aspect ratio changes.
Alignment oculumBackgroundFocalAlignment(
  Size image,
  Size viewport,
  Offset focus,
) {
  if (image.isEmpty || viewport.isEmpty) return Alignment.center;
  final fitted = applyBoxFit(BoxFit.cover, image, viewport).source;
  double axis(double source, double visible, double point) {
    final overflow = source - visible;
    if (overflow <= .001) return 0;
    return ((point.clamp(0, 1) * source - visible / 2) / overflow * 2 - 1)
        .clamp(-1.0, 1.0);
  }

  return Alignment(
    axis(image.width, fitted.width, focus.dx),
    axis(image.height, fitted.height, focus.dy),
  );
}

Offset oculumNarrativeSubjectFocus(
  String? monsterId, {
  required bool dedicatedMobile,
}) {
  // Explicit phone compositions keep their own composition. The overrides
  // below describe the approved wide paintings used when no phone art exists.
  if (dedicatedMobile) return const Offset(.5, .5);
  return switch (monsterId) {
    'guardia_solare' ||
    'guardia_solare_elite' ||
    'guardiano_solare' => const Offset(.66, .5),
    'baby_forest_demon_variante_rituale' => const Offset(.31, .5),
    'forest_demon' || 'forest_demon_errato' => const Offset(.64, .5),
    'baby_forest_demon' => const Offset(.45, .5),
    'goblin_king' => const Offset(.33, .5),
    'ciclo_forest_demon_blu' => const Offset(.5, .5),
    _ => const Offset(.5, .5),
  };
}

/// Resolves the same cached provider as [Image] to obtain its real dimensions.
/// It creates no derivative files or additional decoded image-cache entries.
class OculumFocalBackground extends StatefulWidget {
  const OculumFocalBackground({
    super.key,
    required this.image,
    required this.imageKey,
    required this.focus,
  });

  final ImageProvider image;
  final Key imageKey;
  final Offset focus;

  @override
  State<OculumFocalBackground> createState() => _OculumFocalBackgroundState();
}

class _OculumFocalBackgroundState extends State<OculumFocalBackground> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  Size? _imageSize;

  void _resolve() {
    final stream = widget.image.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _detach();
    _imageSize = null;
    _stream = stream;
    _listener = ImageStreamListener((info, synchronousCall) {
      final size = Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      );
      info.dispose();
      if (!mounted || _imageSize == size) return;
      if (synchronousCall) {
        _imageSize = size;
      } else {
        setState(() => _imageSize = size);
      }
    }, onError: (Object error, StackTrace? stack) {});
    stream.addListener(_listener!);
  }

  void _detach() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _listener = null;
    _stream = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(OculumFocalBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) _resolve();
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Image(
      image: widget.image,
      key: widget.imageKey,
      fit: BoxFit.cover,
      alignment: _imageSize == null
          ? Alignment.center
          : oculumBackgroundFocalAlignment(
              _imageSize!,
              constraints.biggest,
              widget.focus,
            ),
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
  );
}
