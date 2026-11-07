import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Bounds the expanded work of imported animations and leaves room in a
/// typical sheet-sharing message after the Base64 expansion.
const oculumPortraitGifMaxBytes = 384 * 1024;

typedef OculumPortraitPosition = ({double x, double y, double zoom});
typedef OculumPortraitGifRequest = ({
  Uint8List source,
  OculumPortraitPosition start,
  OculumPortraitPosition end,
  int milliseconds,
  bool returnTrip,
});

bool oculumIsPortraitGif(List<int> bytes) =>
    bytes.length >= 6 &&
    bytes[0] == 0x47 &&
    bytes[1] == 0x49 &&
    bytes[2] == 0x46 &&
    bytes[3] == 0x38 &&
    (bytes[4] == 0x37 || bytes[4] == 0x39) &&
    bytes[5] == 0x61;

bool oculumCanImportPortraitGif(Uint8List bytes) {
  if (!oculumIsPortraitGif(bytes) ||
      bytes.length > oculumPortraitGifMaxBytes ||
      bytes.last != 0x3b) {
    return false;
  }
  try {
    final decoder = img.GifDecoder();
    final info = decoder.startDecode(bytes);
    if (info == null ||
        info.width <= 0 ||
        info.height <= 0 ||
        info.width > 1024 ||
        info.height > 1024 ||
        info.numFrames <= 0 ||
        info.numFrames > 120 ||
        info.width * info.height * info.numFrames > 16000000 ||
        info.frames.any(
          (frame) =>
              frame.width <= 0 ||
              frame.height <= 0 ||
              frame.x + frame.width > info.width ||
              frame.y + frame.height > info.height,
        )) {
      return false;
    }
    return decoder.decode(bytes)?.numFrames == info.numFrames;
  } catch (_) {
    return false;
  }
}

({String extension, String mimeType}) oculumPortraitFileType(Uint8List bytes) {
  if (oculumIsPortraitGif(bytes)) {
    return (extension: 'gif', mimeType: 'image/gif');
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return (extension: 'jpg', mimeType: 'image/jpeg');
  }
  return (extension: 'png', mimeType: 'image/png');
}

({int x, int y, int side}) oculumPortraitAnimationCrop(
  int width,
  int height,
  OculumPortraitPosition position,
) {
  final available = min(width, height);
  final side = (available / position.zoom.clamp(1.0, 3.0))
      .round()
      .clamp(1, available)
      .toInt();
  return (
    x: ((position.x.clamp(-1.0, 1.0) + 1) * (width - side) / 2).round(),
    y: ((position.y.clamp(-1.0, 1.0) + 1) * (height - side) / 2).round(),
    side: side,
  );
}

OculumPortraitPosition oculumPortraitAnimationPosition(
  OculumPortraitPosition start,
  OculumPortraitPosition end,
  double progress,
) {
  final t = progress.clamp(0.0, 1.0).toDouble();
  final eased = t * t * (3 - 2 * t);
  return (
    x: start.x + (end.x - start.x) * eased,
    y: start.y + (end.y - start.y) * eased,
    zoom: start.zoom + (end.zoom - start.zoom) * eased,
  );
}

img.Image? _decodePortraitSource(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > 16 * 1024 * 1024) return null;
  if (oculumIsPortraitGif(bytes)) {
    final decoder = img.GifDecoder();
    final info = decoder.startDecode(bytes);
    if (info == null ||
        info.numFrames == 0 ||
        info.frames.first.width > info.width ||
        info.frames.first.height > info.height ||
        info.width * info.height > 16000000) {
      return null;
    }
    return decoder.decodeFrame(0);
  }
  final decoder = img.findDecoderForData(bytes);
  final info = decoder?.startDecode(bytes);
  if (decoder == null ||
      info == null ||
      info.width <= 0 ||
      info.height <= 0 ||
      info.width * info.height > 16000000) {
    return null;
  }
  return decoder.decodeFrame(0);
}

img.Image _boundPortraitSource(img.Image image, int maxDimension) {
  final longest = max(image.width, image.height);
  if (longest <= maxDimension) return image;
  return img.copyResize(
    image,
    width: max(1, (maxDimension * image.width / longest).round()),
    height: max(1, (maxDimension * image.height / longest).round()),
    interpolation: img.Interpolation.average,
  );
}

img.Image _portraitGifFrame(img.Image frame) {
  if (!frame.hasAlpha) return frame;
  const transparent = 127;
  final quantized = img.quantize(frame, numberOfColors: transparent);
  final palette = img.PaletteUint8(128, 4);
  final rgb = quantized.palette!;
  for (var index = 0; index < transparent; index++) {
    palette.setRgba(
      index,
      rgb.getRed(index),
      rgb.getGreen(index),
      rgb.getBlue(index),
      255,
    );
  }
  final indexed = img.Image(
    width: frame.width,
    height: frame.height,
    numChannels: 1,
    withPalette: true,
    palette: palette,
  );
  for (final pixel in frame) {
    indexed.setPixelIndex(
      pixel.x,
      pixel.y,
      pixel.aNormalized < .5
          ? transparent
          : quantized.getPixelIndex(pixel.x, pixel.y),
    );
  }
  return indexed;
}

({Uint8List bytes, int width, int height})? oculumPortraitGifPreview(
  Uint8List bytes,
) {
  try {
    final image = _decodePortraitSource(bytes);
    if (image == null) return null;
    final preview = _boundPortraitSource(image, 512);
    return (
      bytes: preview.hasAlpha
          ? img.encodePng(preview, singleFrame: true)
          : img.encodeJpg(preview, quality: 85),
      width: preview.width,
      height: preview.height,
    );
  } catch (_) {
    return null;
  }
}

Future<Uint8List?> oculumRenderPortraitGif(
  OculumPortraitGifRequest request, {
  bool yieldBetweenFrames = false,
}) async {
  try {
    final source = _decodePortraitSource(request.source);
    if (source == null) return null;
    final image = _boundPortraitSource(source, 768);
    final duration = request.milliseconds.clamp(900, 3600);
    final frameCount = ((duration / 250).round() * 2).clamp(8, 20);
    final delay = (duration / frameCount / 10).round();
    for (final resolution in const [192, 144, 112, 80]) {
      final encoder = img.GifEncoder(
        repeat: 0,
        numColors: 128,
        dither: img.DitherKernel.none,
      );
      for (var frame = 0; frame < frameCount; frame++) {
        final phase = request.returnTrip ? frame * 2 / frameCount : 0.0;
        final progress = request.returnTrip
            ? min(phase, 2 - phase)
            : frame / (frameCount - 1);
        final position = oculumPortraitAnimationPosition(
          request.start,
          request.end,
          progress,
        );
        final crop = oculumPortraitAnimationCrop(
          image.width,
          image.height,
          position,
        );
        final square = img.copyCrop(
          image,
          x: crop.x,
          y: crop.y,
          width: crop.side,
          height: crop.side,
        );
        final scaled = img.copyResize(
          square,
          width: resolution,
          height: resolution,
          interpolation: img.Interpolation.average,
        );
        encoder.addFrame(_portraitGifFrame(scaled), duration: delay);
        if (yieldBetweenFrames) {
          await Future<void>.delayed(Duration.zero);
        }
      }
      final encoded = encoder.finish();
      if (encoded != null && encoded.length <= oculumPortraitGifMaxBytes) {
        return encoded;
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}
