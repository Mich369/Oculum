import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

class Rgba {
  const Rgba(this.r, this.g, this.b, [this.a = 255]);

  final int r;
  final int g;
  final int b;
  final int a;

  img.ColorRgba8 get color => img.ColorRgba8(r, g, b, a);
}

const transparent = Rgba(0, 0, 0, 0);
const outline = Rgba(20, 16, 24);
const spriteExportSize = 512;
const spriteCoordinateSize = 256;
const spriteScale = spriteExportSize ~/ spriteCoordinateSize;

int channel(num value) => value.clamp(0, 255).round();
int sc(num value) => (value * spriteScale).round();

Rgba mixRgba(Rgba a, Rgba b, double t, [int? alpha]) {
  final w = t.clamp(0, 1).toDouble();
  return Rgba(
    channel(a.r * (1 - w) + b.r * w),
    channel(a.g * (1 - w) + b.g * w),
    channel(a.b * (1 - w) + b.b * w),
    alpha ?? channel(a.a * (1 - w) + b.a * w),
  );
}

Rgba shadeRgba(Rgba c, double amount, [int? alpha]) {
  final target = amount >= 0 ? const Rgba(255, 255, 255) : const Rgba(0, 0, 0);
  return mixRgba(c, target, amount.abs(), alpha ?? c.a);
}

Rgba shiftedVariant(Rgba c, int seed, int variant) {
  if (variant <= 0) return c;
  final warm = Rgba(
    channel(128 + seed % 96),
    channel(70 + (seed ~/ 7) % 130),
    channel(190 + (seed ~/ 11) % 55),
  );
  final t = variant == 1 ? 0.32 : 0.52;
  return mixRgba(c, warm, t, c.a);
}

void px(img.Image canvas, int x, int y, Rgba c) {
  if (x < 0 || y < 0 || x >= canvas.width || y >= canvas.height) return;
  canvas.setPixelRgba(x, y, c.r, c.g, c.b, c.a);
}

void blendPx(img.Image canvas, int x, int y, Rgba c) {
  if (x < 0 || y < 0 || x >= canvas.width || y >= canvas.height) return;
  if (c.a >= 255) {
    px(canvas, x, y, c);
    return;
  }
  if (c.a <= 0) return;
  final dst = canvas.getPixel(x, y);
  final a = c.a / 255;
  final inv = 1 - a;
  canvas.setPixelRgba(
    x,
    y,
    channel(c.r * a + dst.r * inv),
    channel(c.g * a + dst.g * inv),
    channel(c.b * a + dst.b * inv),
    255,
  );
}

void fillRect(img.Image canvas, int x, int y, int w, int h, Rgba c) {
  final sx = sc(x);
  final sy = sc(y);
  final sw = sc(w);
  final sh = sc(h);
  for (var yy = sy; yy < sy + sh; yy++) {
    for (var xx = sx; xx < sx + sw; xx++) {
      px(canvas, xx, yy, c);
    }
  }
}

void ellipse(img.Image canvas, int cx, int cy, int rx, int ry, Rgba c) {
  final pcx = sc(cx);
  final pcy = sc(cy);
  final prx = max(1, sc(rx));
  final pry = max(1, sc(ry));
  final rx2 = prx * prx;
  final ry2 = pry * pry;
  for (var y = pcy - pry; y <= pcy + pry; y++) {
    for (var x = pcx - prx; x <= pcx + prx; x++) {
      final dx = x - pcx;
      final dy = y - pcy;
      if (dx * dx * ry2 + dy * dy * rx2 <= rx2 * ry2) px(canvas, x, y, c);
    }
  }
}

void circle(img.Image canvas, int cx, int cy, int r, Rgba c) {
  ellipse(canvas, cx, cy, r, r, c);
}

void line(
  img.Image canvas,
  int x0,
  int y0,
  int x1,
  int y1,
  Rgba c, {
  int w = 1,
}) {
  img.drawLine(
    canvas,
    x1: sc(x0),
    y1: sc(y0),
    x2: sc(x1),
    y2: sc(y1),
    color: c.color,
    antialias: true,
    thickness: max(1, sc(w)),
  );
}

void triangle(
  img.Image canvas,
  Point<int> a,
  Point<int> b,
  Point<int> c,
  Rgba color,
) {
  img.fillPolygon(
    canvas,
    vertices: [
      img.Point(sc(a.x), sc(a.y)),
      img.Point(sc(b.x), sc(b.y)),
      img.Point(sc(c.x), sc(c.y)),
    ],
    color: color.color,
  );
}

void glow(img.Image canvas, int cx, int cy, int r, Rgba c) {
  for (var radius = r; radius > 0; radius--) {
    final alpha = (c.a * radius / r * 0.22).round();
    circle(canvas, cx, cy, radius, Rgba(c.r, c.g, c.b, alpha));
  }
}

img.Image canvas() {
  final image = img.Image(
    width: spriteExportSize,
    height: spriteExportSize,
    numChannels: 4,
  );
  img.fill(image, color: transparent.color);
  return image;
}

img.Image darkFantasyBackdrop(String path, int width, int height) {
  final seed = monsterSpriteStableSeed(path);
  final image = img.Image(width: width, height: height, numChannels: 4);
  final redBias =
      path.contains('blood') ||
      path.contains('sangue') ||
      path.contains('boss') ||
      path.contains('nightmare') ||
      path.contains('vuoto');
  final top = redBias ? const Rgba(32, 14, 22) : const Rgba(16, 19, 30);
  final bottom = redBias ? const Rgba(85, 31, 35) : const Rgba(43, 47, 62);
  for (var y = 0; y < height; y++) {
    final t = y / max(1, height - 1);
    for (var x = 0; x < width; x++) {
      final noise = ((x * 17 + y * 29 + seed) % 17) - 8;
      final c = mixRgba(top, bottom, t);
      image.setPixelRgba(
        x,
        y,
        channel(c.r + noise),
        channel(c.g + noise),
        channel(c.b + noise),
        255,
      );
    }
  }

  final logicalWidth = max(1, width ~/ spriteScale);
  final logicalHeight = max(1, height ~/ spriteScale);
  final haloX = sc(96 + seed % 65);
  final haloY = sc(50 + (seed ~/ 9) % 44);
  for (var r = sc(72); r > 0; r--) {
    final a = channel((r / sc(72)) * 34);
    for (var yy = haloY - r; yy <= haloY + r; yy++) {
      for (var xx = haloX - r; xx <= haloX + r; xx++) {
        final dx = xx - haloX;
        final dy = yy - haloY;
        if (dx * dx + dy * dy <= r * r) {
          blendPx(image, xx, yy, const Rgba(226, 200, 129, 1).copyWith(a));
        }
      }
    }
  }

  for (var n = 0; n < 9; n++) {
    final baseX = (seed + n * 41) % logicalWidth;
    final h = 36 + ((seed ~/ (n + 3)) % 72);
    final w = 8 + n % 4 * 5;
    triangle(
      image,
      Point(baseX - w, logicalHeight - 24),
      Point(baseX, logicalHeight - 24 - h),
      Point(baseX + w, logicalHeight - 24),
      const Rgba(11, 13, 19, 210),
    );
    line(
      image,
      baseX,
      logicalHeight - 24 - h,
      baseX,
      logicalHeight - 16,
      const Rgba(6, 7, 11, 180),
      w: 1,
    );
  }

  for (var n = 0; n < 28; n++) {
    final x0 = (seed * (n + 5) + n * 23) % logicalWidth;
    final y0 = (24 + (seed ~/ (n + 2) + n * 17) % max(1, logicalHeight - 56))
        .toInt();
    final x1 = (x0 + 16 + (seed + n * 13) % 46)
        .clamp(0, logicalWidth - 1)
        .toInt();
    final y1 = (y0 + ((n.isEven ? 1 : -1) * (8 + n % 18)))
        .clamp(0, logicalHeight - 1)
        .toInt();
    line(
      image,
      x0,
      y0,
      x1,
      y1,
      n % 5 == 0 ? const Rgba(159, 39, 55, 80) : const Rgba(235, 225, 194, 38),
    );
  }

  final cx = width / 2;
  final cy = height / 2;
  final maxDist = sqrt(cx * cx + cy * cy);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final d = sqrt(dx * dx + dy * dy) / maxDist;
      if (d > 0.54) {
        blendPx(image, x, y, Rgba(0, 0, 0, channel((d - 0.54) * 210)));
      }
    }
  }
  return image;
}

extension on Rgba {
  Rgba copyWith([int? alpha]) => Rgba(r, g, b, alpha ?? a);
}

img.Image spriteOnBackdrop(String path, img.Image foreground) {
  final image = darkFantasyBackdrop(path, foreground.width, foreground.height);
  for (var y = 0; y < foreground.height; y++) {
    for (var x = 0; x < foreground.width; x++) {
      final p = foreground.getPixel(x, y);
      final a = channel(p.a);
      if (a <= 0) continue;
      blendPx(image, x, y, Rgba(channel(p.r), channel(p.g), channel(p.b), a));
    }
  }
  return image;
}

void save(String path, img.Image image) {
  final backed = spriteOnBackdrop(path, image);
  final exported = img.copyResize(
    backed,
    width: spriteExportSize,
    height: spriteExportSize,
    interpolation: img.Interpolation.cubic,
  );
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(exported, level: 7));
}

img.Image fetalMan() {
  final i = canvas();
  glow(i, 128, 138, 84, const Rgba(140, 20, 38, 160));
  ellipse(i, 128, 151, 76, 44, outline);
  ellipse(i, 128, 151, 68, 36, const Rgba(78, 55, 65));
  circle(i, 96, 123, 25, outline);
  circle(i, 96, 123, 19, const Rgba(112, 82, 86));
  line(i, 111, 137, 165, 101, const Rgba(34, 28, 36), w: 10);
  line(i, 105, 158, 165, 180, const Rgba(34, 28, 36), w: 12);
  line(i, 141, 137, 83, 174, const Rgba(128, 28, 44), w: 5);
  circle(i, 88, 120, 4, const Rgba(255, 226, 128));
  return i;
}

img.Image headlessBlood() {
  final i = canvas();
  glow(i, 128, 130, 90, const Rgba(180, 25, 40, 155));
  ellipse(i, 128, 141, 46, 70, outline);
  ellipse(i, 128, 145, 36, 60, const Rgba(88, 70, 68));
  fillRect(i, 104, 76, 56, 22, outline);
  fillRect(i, 111, 80, 42, 17, const Rgba(105, 19, 28));
  line(i, 103, 104, 62, 170, const Rgba(70, 55, 60), w: 11);
  line(i, 153, 104, 199, 168, const Rgba(70, 55, 60), w: 11);
  line(i, 116, 109, 111, 192, const Rgba(193, 26, 42), w: 4);
  line(i, 139, 109, 154, 190, const Rgba(193, 26, 42), w: 4);
  line(i, 118, 205, 88, 232, outline, w: 10);
  line(i, 144, 205, 176, 232, outline, w: 10);
  return i;
}

img.Image trueNightmare() {
  final i = canvas();
  glow(i, 128, 120, 108, const Rgba(124, 92, 255, 170));
  ellipse(i, 128, 145, 54, 88, outline);
  ellipse(i, 128, 145, 44, 78, const Rgba(33, 28, 58));
  triangle(
    i,
    const Point(87, 101),
    const Point(120, 32),
    const Point(130, 113),
    outline,
  );
  triangle(
    i,
    const Point(169, 101),
    const Point(138, 32),
    const Point(126, 113),
    outline,
  );
  triangle(
    i,
    const Point(93, 102),
    const Point(119, 45),
    const Point(126, 111),
    const Rgba(58, 40, 96),
  );
  triangle(
    i,
    const Point(163, 102),
    const Point(139, 45),
    const Point(130, 111),
    const Rgba(58, 40, 96),
  );
  ellipse(i, 128, 116, 31, 19, const Rgba(226, 218, 255));
  circle(i, 128, 116, 8, const Rgba(25, 18, 42));
  line(i, 84, 156, 42, 201, const Rgba(70, 48, 112), w: 12);
  line(i, 173, 156, 216, 201, const Rgba(70, 48, 112), w: 12);
  return i;
}

img.Image rockRhino() {
  final i = canvas();
  glow(i, 126, 150, 72, const Rgba(180, 146, 90, 110));
  ellipse(i, 130, 158, 74, 45, outline);
  ellipse(i, 130, 158, 65, 36, const Rgba(121, 111, 98));
  ellipse(i, 184, 142, 35, 30, outline);
  ellipse(i, 184, 142, 28, 23, const Rgba(135, 127, 112));
  triangle(
    i,
    const Point(207, 132),
    const Point(244, 117),
    const Point(211, 150),
    const Rgba(218, 203, 168),
  );
  for (final x in [82, 117, 156, 190]) {
    fillRect(i, x, 190, 16, 38, outline);
    fillRect(i, x + 3, 190, 10, 32, const Rgba(93, 86, 76));
  }
  circle(i, 178, 135, 4, const Rgba(255, 230, 132));
  return i;
}

img.Image posteaScientist() {
  final i = canvas();
  glow(i, 128, 130, 88, const Rgba(85, 184, 107, 150));
  ellipse(i, 128, 145, 42, 71, outline);
  ellipse(i, 128, 145, 33, 62, const Rgba(54, 95, 77));
  circle(i, 128, 75, 28, outline);
  circle(i, 128, 75, 21, const Rgba(105, 215, 150));
  line(i, 104, 111, 69, 82, const Rgba(255, 119, 178), w: 10);
  line(i, 156, 111, 198, 84, const Rgba(255, 119, 178), w: 10);
  circle(i, 75, 78, 14, const Rgba(255, 151, 199));
  circle(i, 201, 80, 14, const Rgba(255, 151, 199));
  line(i, 118, 99, 113, 203, const Rgba(120, 232, 156), w: 4);
  line(i, 140, 99, 154, 203, const Rgba(120, 232, 156), w: 4);
  return i;
}

img.Image gufus() {
  final i = canvas();
  glow(i, 128, 142, 74, const Rgba(80, 70, 122, 135));
  ellipse(i, 128, 151, 45, 64, outline);
  ellipse(i, 128, 151, 36, 54, const Rgba(20, 20, 29));
  triangle(
    i,
    const Point(98, 94),
    const Point(82, 29),
    const Point(119, 97),
    outline,
  );
  triangle(
    i,
    const Point(156, 94),
    const Point(176, 29),
    const Point(137, 97),
    outline,
  );
  triangle(
    i,
    const Point(103, 96),
    const Point(86, 42),
    const Point(119, 99),
    const Rgba(232, 237, 226),
  );
  triangle(
    i,
    const Point(153, 96),
    const Point(172, 42),
    const Point(137, 99),
    const Rgba(232, 237, 226),
  );
  circle(i, 128, 111, 34, outline);
  circle(i, 128, 111, 27, const Rgba(238, 241, 232));
  circle(i, 117, 108, 5, const Rgba(248, 240, 145));
  circle(i, 139, 108, 5, const Rgba(248, 240, 145));
  triangle(
    i,
    const Point(126, 116),
    const Point(132, 116),
    const Point(129, 124),
    const Rgba(186, 132, 64),
  );
  line(i, 160, 162, 199, 137, const Rgba(220, 220, 212), w: 5);
  line(i, 191, 134, 206, 127, const Rgba(120, 122, 130), w: 3);
  return i;
}

img.Image posteaGuard() {
  final i = canvas();
  glow(i, 128, 137, 90, const Rgba(143, 183, 255, 145));
  circle(i, 128, 73, 27, outline);
  circle(i, 128, 73, 21, const Rgba(85, 112, 154));
  ellipse(i, 128, 145, 44, 76, outline);
  ellipse(i, 128, 145, 35, 66, const Rgba(58, 78, 112));
  fillRect(i, 101, 116, 54, 16, const Rgba(132, 165, 218));
  line(i, 91, 119, 57, 171, const Rgba(80, 95, 130), w: 11);
  ellipse(i, 67, 176, 19, 31, outline);
  ellipse(i, 67, 176, 14, 25, const Rgba(96, 128, 178));
  line(i, 157, 120, 199, 175, const Rgba(80, 95, 130), w: 10);
  return i;
}

img.Image kooba() {
  final i = canvas();
  glow(i, 128, 148, 72, const Rgba(224, 196, 132, 120));
  triangle(
    i,
    const Point(99, 100),
    const Point(73, 41),
    const Point(119, 106),
    outline,
  );
  triangle(
    i,
    const Point(154, 101),
    const Point(186, 43),
    const Point(137, 106),
    outline,
  );
  triangle(
    i,
    const Point(103, 101),
    const Point(78, 54),
    const Point(119, 108),
    const Rgba(176, 139, 94),
  );
  triangle(
    i,
    const Point(151, 101),
    const Point(181, 55),
    const Point(137, 108),
    const Rgba(176, 139, 94),
  );
  circle(i, 128, 112, 31, outline);
  circle(i, 128, 112, 25, const Rgba(156, 118, 78));
  ellipse(i, 128, 83, 22, 16, outline);
  ellipse(i, 128, 83, 17, 12, const Rgba(224, 218, 196));
  ellipse(i, 128, 158, 39, 56, outline);
  ellipse(i, 128, 158, 31, 48, const Rgba(142, 103, 70));
  circle(i, 118, 108, 4, const Rgba(40, 30, 26));
  circle(i, 139, 108, 4, const Rgba(40, 30, 26));
  fillRect(i, 123, 85, 4, 5, const Rgba(40, 30, 26));
  fillRect(i, 135, 85, 4, 5, const Rgba(40, 30, 26));
  return i;
}

class GeneratedMonsterSpritePlan {
  const GeneratedMonsterSpritePlan({
    required this.id,
    required this.glowColor,
    required this.bodyColor,
    required this.accentColor,
    this.detailColor = const Rgba(236, 226, 182),
    this.form = 'humanoid',
    this.eyeCount = 2,
    this.horns = false,
    this.wings = false,
    this.crown = false,
    this.threads = false,
    this.runes = false,
    this.variant = 0,
    this.horror = false,
    this.peaceful = false,
    this.themeText = '',
  });

  final String id;
  final Rgba glowColor;
  final Rgba bodyColor;
  final Rgba accentColor;
  final Rgba detailColor;
  final String form;
  final int eyeCount;
  final bool horns;
  final bool wings;
  final bool crown;
  final bool threads;
  final bool runes;
  final int variant;
  final bool horror;
  final bool peaceful;
  final String themeText;
}

void drawEyes(
  img.Image i,
  int count,
  Rgba iris, {
  int y = 112,
  int spacing = 18,
}) {
  if (count <= 0) return;
  final totalWidth = (count - 1) * spacing;
  final start = 128 - totalWidth ~/ 2;
  for (var e = 0; e < count; e++) {
    final x = start + e * spacing;
    ellipse(i, x, y, 7, 9, outline);
    ellipse(i, x, y, 4, 6, iris);
  }
}

void drawRunes(img.Image i, Rgba color) {
  for (var n = 0; n < 9; n++) {
    final x = 70 + (n * 23) % 116;
    final y = 62 + (n * 31) % 126;
    line(i, x - 5, y, x + 5, y, color, w: 2);
    line(i, x, y - 5, x, y + 5, color, w: 2);
  }
}

void drawHatching(
  img.Image i,
  int seed,
  Rgba color, {
  int count = 22,
  int xMin = 65,
  int xMax = 190,
  int yMin = 80,
  int yMax = 207,
}) {
  final rng = Random(seed);
  for (var n = 0; n < count; n++) {
    final x = xMin + rng.nextInt(max(1, xMax - xMin));
    final y = yMin + rng.nextInt(max(1, yMax - yMin));
    final len = 6 + rng.nextInt(18);
    final tilt = rng.nextBool() ? 1 : -1;
    line(i, x, y, x + tilt * len, y + 3 + rng.nextInt(9), color);
  }
}

void drawMouth(img.Image i, int cx, int cy, int width, Rgba accent) {
  line(i, cx - width ~/ 2, cy, cx + width ~/ 2, cy, outline, w: 3);
  for (var t = -width ~/ 2 + 4; t <= width ~/ 2 - 2; t += 7) {
    triangle(
      i,
      Point(cx + t, cy + 1),
      Point(cx + t + 4, cy + 1),
      Point(cx + t + 2, cy + 8),
      const Rgba(236, 226, 204),
    );
  }
  line(i, cx - width ~/ 2, cy + 3, cx + width ~/ 2, cy + 4, accent, w: 1);
}

void drawClaws(img.Image i, int x, int y, int dir, Rgba color) {
  for (var c = 0; c < 3; c++) {
    line(i, x, y + c * 4, x + dir * (12 + c * 2), y + c * 3 - 7, color, w: 2);
  }
}

void drawWingFeathers(img.Image i, bool left, Rgba color) {
  final dir = left ? -1 : 1;
  final rootX = left ? 92 : 164;
  for (var n = 0; n < 8; n++) {
    final y = 94 + n * 9;
    line(i, rootX, y, rootX + dir * (38 + n * 5), y - 20 + n * 6, color, w: 2);
  }
}

void drawRibs(img.Image i, Rgba color) {
  for (var n = 0; n < 5; n++) {
    final y = 124 + n * 10;
    line(i, 109, y, 128, y + 5, color, w: 2);
    line(i, 147, y, 128, y + 5, color, w: 2);
  }
  line(i, 128, 113, 128, 174, color, w: 2);
}

void washEllipse(img.Image i, int cx, int cy, int rx, int ry, Rgba color) {
  final pcx = sc(cx);
  final pcy = sc(cy);
  final prx = max(1, sc(rx));
  final pry = max(1, sc(ry));
  final rx2 = prx * prx;
  final ry2 = pry * pry;
  for (var y = pcy - pry; y <= pcy + pry; y++) {
    for (var x = pcx - prx; x <= pcx + prx; x++) {
      final dx = x - pcx;
      final dy = y - pcy;
      final d = dx * dx * ry2 + dy * dy * rx2;
      if (d <= rx2 * ry2) {
        final edge = d / max(1, rx2 * ry2);
        blendPx(i, x, y, color.copyWith(channel(color.a * (1 - edge * 0.72))));
      }
    }
  }
}

void drawGraphicSmoke(img.Image i, int seed, Rgba color) {
  final rng = Random(seed);
  for (var n = 0; n < 10; n++) {
    final cx = 22 + rng.nextInt(212);
    final cy = 205 + rng.nextInt(34);
    final rx = 22 + rng.nextInt(38);
    final ry = 9 + rng.nextInt(16);
    washEllipse(i, cx, cy, rx, ry, color.copyWith(42 + rng.nextInt(54)));
    line(
      i,
      cx - rx ~/ 2,
      cy,
      cx + rx ~/ 2,
      cy - rng.nextInt(18),
      color.copyWith(80),
      w: 2,
    );
  }
}

void drawFlameLick(img.Image i, Point<int> base, int height, Rgba color) {
  triangle(
    i,
    Point(base.x - height ~/ 8, base.y),
    Point(base.x + height ~/ 8, base.y),
    Point(base.x, base.y - height),
    color.copyWith(130),
  );
  line(i, base.x, base.y, base.x + height ~/ 7, base.y - height, color, w: 2);
  line(
    i,
    base.x,
    base.y - height ~/ 3,
    base.x - height ~/ 8,
    base.y - height * 2 ~/ 3,
    shadeRgba(color, 0.35, 170),
    w: 1,
  );
}

void drawLeaf(img.Image i, int x, int y, int dir, Rgba color) {
  ellipse(i, x, y, 6, 3, color);
  line(i, x - dir * 5, y + 1, x + dir * 5, y - 2, shadeRgba(color, -0.25));
}

void drawWatercolorBlooms(img.Image i, int seed, Rgba body, Rgba accent) {
  final rng = Random(seed);
  for (var n = 0; n < 32; n++) {
    final x = 56 + rng.nextInt(145);
    final y = 58 + rng.nextInt(155);
    final c = n.isEven ? body : accent;
    washEllipse(
      i,
      x,
      y,
      6 + rng.nextInt(15),
      3 + rng.nextInt(10),
      shadeRgba(c, rng.nextBool() ? 0.12 : -0.12, 18 + rng.nextInt(34)),
    );
  }
}

void drawConceptDetails(
  img.Image i,
  GeneratedMonsterSpritePlan plan,
  String form,
  int seed,
  Rgba body,
  Rgba accent,
  Rgba detail,
  bool horror,
) {
  final theme = '${plan.id} ${plan.themeText}'.toLowerCase();
  final nature =
      theme.contains('bosco') ||
      theme.contains('forest') ||
      theme.contains('natura') ||
      theme.contains('radice') ||
      theme.contains('cervo') ||
      theme.contains('foglia');
  final armed =
      theme.contains('goblin') ||
      theme.contains('orco') ||
      theme.contains('cavaliere') ||
      theme.contains('arciere') ||
      theme.contains('guardia') ||
      theme.contains('lama') ||
      theme.contains('bandito');
  final bell = theme.contains('campana') || theme.contains('bell');
  drawGraphicSmoke(i, seed + 91, horror ? accent : shadeRgba(detail, -0.08));
  drawWatercolorBlooms(i, seed + 107, body, accent);

  if (horror) {
    for (var n = 0; n < 9; n++) {
      final x = 76 + n * 13 + (seed ~/ (n + 3)) % 7;
      final top = 38 + (seed ~/ (n + 5)) % 26;
      line(i, 128, 98, x, top, outline.copyWith(210), w: 4);
      drawFlameLick(i, Point(x, top + 25), 30 + n % 3 * 8, accent);
    }
    for (var n = 0; n < min(9, plan.eyeCount + 3); n++) {
      final x = 100 + (n % 3) * 28;
      final y = 122 + (n ~/ 3) * 22;
      ellipse(i, x, y, 10, 6, outline.copyWith(230));
      ellipse(i, x, y, 6, 3, accent);
      circle(i, x, y, 2, detail);
    }
    ellipse(i, 128, 61, 52, 45, accent.copyWith(34));
    ellipse(i, 128, 61, 44, 37, outline.copyWith(70));
  }

  if (nature) {
    for (var n = 0; n < 18; n++) {
      final x = 62 + (seed + n * 19) % 132;
      final y = 72 + (seed ~/ (n + 2) + n * 11) % 120;
      line(
        i,
        x,
        y,
        x + (n.isEven ? 15 : -15),
        y + 16,
        shadeRgba(body, -0.28),
        w: 2,
      );
      drawLeaf(
        i,
        x + (n.isEven ? 9 : -9),
        y + 9,
        n.isEven ? 1 : -1,
        shadeRgba(accent, 0.05),
      );
    }
  }

  if (armed) {
    final weaponColor = shadeRgba(detail, 0.08);
    if (theme.contains('arciere')) {
      line(i, 58, 92, 55, 206, weaponColor, w: 3);
      line(i, 58, 92, 74, 150, outline, w: 1);
      line(i, 55, 206, 74, 150, outline, w: 1);
      line(i, 86, 151, 178, 121, weaponColor, w: 2);
    } else {
      line(i, 188, 75, 73, 217, outline, w: 8);
      line(i, 186, 78, 76, 214, weaponColor, w: 4);
      triangle(
        i,
        const Point(186, 55),
        const Point(202, 83),
        const Point(174, 81),
        weaponColor,
      );
    }
  }

  if (bell) {
    ellipse(i, 128, 92, 47, 31, outline);
    ellipse(i, 128, 95, 38, 23, shadeRgba(accent, -0.03));
    line(i, 88, 103, 168, 103, shadeRgba(detail, 0.1), w: 4);
    circle(i, 128, 138, 13, shadeRgba(accent, -0.18));
    circle(i, 116, 98, 5, detail);
    circle(i, 140, 98, 5, detail);
  }

  if (form == 'humanoid' || form == 'construct') {
    line(i, 101, 112, 155, 112, shadeRgba(detail, 0.02), w: 3);
    line(i, 112, 116, 100, 183, shadeRgba(outline, 0.15), w: 2);
    line(i, 144, 116, 156, 183, shadeRgba(outline, 0.15), w: 2);
    for (var b = 0; b < 5; b++) {
      circle(i, 128, 123 + b * 13, 2, detail);
    }
  }

  drawHatching(
    i,
    seed + 211,
    horror ? outline.copyWith(190) : shadeRgba(outline, 0.15, 135),
    count: horror ? 54 : 34,
    xMin: 46,
    xMax: 208,
    yMin: 36,
    yMax: 218,
  );
}

img.Image generatedMonster(GeneratedMonsterSpritePlan plan) {
  final seed = monsterSpriteStableSeed('${plan.id}:${plan.variant}');
  final body = shiftedVariant(plan.bodyColor, seed, plan.variant);
  final accent = shiftedVariant(plan.accentColor, seed + 17, plan.variant);
  final glowColor = shiftedVariant(plan.glowColor, seed + 31, plan.variant);
  final detail = shiftedVariant(plan.detailColor, seed + 47, plan.variant);
  final horror = plan.horror || plan.eyeCount >= 4 || plan.form == 'eye';
  final form = plan.variant == 2 && plan.form == 'humanoid'
      ? 'construct'
      : plan.variant == 2 && plan.form == 'beast'
      ? 'eye'
      : plan.form;
  final i = canvas();
  glow(i, 128, 137, horror ? 108 : 92, glowColor);
  ellipse(i, 128, 219, 77, 14, const Rgba(0, 0, 0, 118));

  if (plan.threads) {
    for (var x = 70; x <= 186; x += 24) {
      line(i, x, 18, 128 + (x - 128) ~/ 3, 190, accent, w: 2);
      line(i, x + 4, 15, 128 + (x - 128) ~/ 5, 160, detail, w: 1);
    }
  }

  if (plan.wings) {
    triangle(
      i,
      const Point(94, 120),
      const Point(28, 78),
      const Point(67, 172),
      outline,
    );
    triangle(
      i,
      const Point(162, 120),
      const Point(228, 78),
      const Point(189, 172),
      outline,
    );
    triangle(
      i,
      const Point(91, 123),
      const Point(40, 85),
      const Point(72, 163),
      shadeRgba(detail, -0.08),
    );
    triangle(
      i,
      const Point(165, 123),
      const Point(216, 85),
      const Point(184, 163),
      shadeRgba(detail, -0.08),
    );
    drawWingFeathers(i, true, shadeRgba(outline, 0.2));
    drawWingFeathers(i, false, shadeRgba(outline, 0.2));
  }

  switch (form) {
    case 'slime':
      for (var d = 0; d < 6; d++) {
        ellipse(i, 92 + d * 15, 188 + d % 2 * 4, 9, 15, shadeRgba(body, -0.18));
      }
      ellipse(i, 128, 166, 68, 46, outline);
      ellipse(i, 128, 164, 58, 37, body);
      ellipse(i, 128, 130, 40, 35, outline);
      ellipse(i, 128, 130, 31, 27, shadeRgba(body, 0.1));
      ellipse(i, 111, 115, 11, 7, shadeRgba(detail, 0.08, 210));
      ellipse(i, 146, 151, 16, 10, shadeRgba(detail, 0.04, 150));
      drawHatching(i, seed, shadeRgba(accent, -0.2, 120), count: 12);
      break;
    case 'beast':
      line(i, 78, 152, 42, 126, outline, w: 12);
      line(i, 76, 152, 43, 129, body, w: 7);
      line(i, 62, 128, 45, 101, outline, w: 5);
      ellipse(i, 126, 159, 74, 39, outline);
      ellipse(i, 126, 159, 64, 31, body);
      ellipse(i, 184, 139, 30, 24, outline);
      ellipse(i, 184, 139, 23, 18, shadeRgba(body, 0.07));
      triangle(
        i,
        const Point(172, 121),
        const Point(164, 93),
        const Point(184, 124),
        outline,
      );
      triangle(
        i,
        const Point(193, 121),
        const Point(207, 94),
        const Point(199, 126),
        outline,
      );
      for (final x in [82, 118, 154, 190]) {
        line(i, x, 186, x - 5, 224, outline, w: 9);
        line(i, x, 186, x - 5, 220, accent, w: 5);
        drawClaws(i, x - 9, 224, -1, detail);
      }
      drawHatching(i, seed, shadeRgba(outline, 0.08, 185), count: 26);
      break;
    case 'eye':
      for (var n = 0; n < 8; n++) {
        final angle = n * pi / 4;
        final x = 128 + cos(angle) * 62;
        final y = 132 + sin(angle) * 42;
        line(i, 128, 132, x.round(), y.round(), shadeRgba(body, -0.25), w: 5);
        line(
          i,
          x.round(),
          y.round(),
          (x + cos(angle) * 34).round(),
          (y + sin(angle) * 23).round(),
          outline,
          w: 3,
        );
      }
      ellipse(i, 128, 132, 71, 48, outline);
      ellipse(i, 128, 132, 61, 38, detail);
      circle(i, 128, 132, 27, accent);
      circle(i, 128, 132, 12, outline);
      line(i, 128, 180, 128, 219, outline, w: 8);
      line(i, 128, 180, 128, 213, body, w: 4);
      line(i, 90, 108, 166, 157, shadeRgba(outline, 0.12), w: 2);
      line(i, 167, 108, 91, 157, shadeRgba(outline, 0.12), w: 2);
      break;
    case 'construct':
      triangle(
        i,
        const Point(84, 112),
        const Point(45, 207),
        const Point(104, 176),
        shadeRgba(outline, 0.06),
      );
      triangle(
        i,
        const Point(172, 112),
        const Point(211, 207),
        const Point(152, 176),
        shadeRgba(outline, 0.06),
      );
      fillRect(i, 84, 102, 88, 86, outline);
      fillRect(i, 94, 112, 68, 66, body);
      ellipse(i, 128, 86, 42, 25, outline);
      ellipse(i, 128, 86, 33, 18, accent);
      for (var p = 0; p < 4; p++) {
        line(
          i,
          96 + p * 18,
          114,
          93 + p * 20,
          177,
          shadeRgba(detail, -0.1),
          w: 2,
        );
      }
      line(i, 96, 193, 82, 225, outline, w: 11);
      line(i, 160, 193, 174, 225, outline, w: 11);
      line(i, 100, 195, 86, 222, accent, w: 5);
      line(i, 156, 195, 170, 222, accent, w: 5);
      break;
    default:
      triangle(
        i,
        const Point(91, 113),
        const Point(47, 220),
        const Point(116, 183),
        shadeRgba(outline, 0.07),
      );
      triangle(
        i,
        const Point(165, 113),
        const Point(209, 220),
        const Point(140, 183),
        shadeRgba(outline, 0.07),
      );
      ellipse(i, 128, 151, 48, 73, outline);
      ellipse(i, 128, 151, 38, 63, body);
      circle(i, 128, 83, 31, outline);
      circle(i, 128, 83, 24, shadeRgba(body, 0.05));
      line(i, 96, 121, 58, 173, outline, w: 10);
      line(i, 160, 121, 198, 173, outline, w: 10);
      line(i, 97, 121, 62, 170, accent, w: 5);
      line(i, 159, 121, 194, 170, accent, w: 5);
      drawClaws(i, 54, 174, -1, detail);
      drawClaws(i, 202, 174, 1, detail);
      line(i, 110, 210, 91, 232, outline, w: 9);
      line(i, 146, 210, 165, 232, outline, w: 9);
      line(i, 113, 211, 96, 230, accent, w: 4);
      line(i, 143, 211, 160, 230, accent, w: 4);
      if (horror) drawRibs(i, shadeRgba(detail, -0.05));
      drawHatching(i, seed, shadeRgba(outline, 0.15, 160), count: 20);
      break;
  }

  if (plan.horns) {
    triangle(
      i,
      const Point(105, 63),
      const Point(86, 24),
      const Point(117, 73),
      outline,
    );
    triangle(
      i,
      const Point(151, 63),
      const Point(170, 24),
      const Point(139, 73),
      outline,
    );
    triangle(
      i,
      const Point(108, 61),
      const Point(91, 31),
      const Point(116, 71),
      detail,
    );
    triangle(
      i,
      const Point(148, 61),
      const Point(165, 31),
      const Point(140, 71),
      detail,
    );
  }

  if (plan.crown) {
    triangle(
      i,
      const Point(102, 67),
      const Point(112, 36),
      const Point(122, 67),
      outline,
    );
    triangle(
      i,
      const Point(122, 67),
      const Point(128, 31),
      const Point(136, 67),
      outline,
    );
    triangle(
      i,
      const Point(136, 67),
      const Point(146, 36),
      const Point(154, 67),
      outline,
    );
    line(i, 101, 67, 155, 67, detail, w: 8);
    for (final x in [112, 128, 146]) {
      circle(i, x, 61, 3, accent);
    }
  }

  drawEyes(
    i,
    form == 'eye' ? 0 : plan.eyeCount,
    detail,
    y: form == 'beast' ? 137 : 91,
    spacing: plan.eyeCount > 3 ? 12 : 18,
  );

  if (horror) {
    drawMouth(
      i,
      form == 'beast' ? 184 : 128,
      form == 'beast' ? 150 : 103,
      31,
      accent,
    );
    for (var n = 0; n < 5; n++) {
      line(
        i,
        102 + n * 13,
        176,
        99 + n * 12,
        205,
        const Rgba(133, 24, 38, 150),
        w: 2,
      );
    }
  } else {
    line(i, 107, 143, 149, 143, accent, w: 3);
    if (plan.peaceful) {
      for (var n = 0; n < 5; n++) {
        circle(
          i,
          88 + n * 21,
          65 + n % 2 * 11,
          3,
          shadeRgba(detail, 0.08, 190),
        );
      }
    }
  }
  drawConceptDetails(i, plan, form, seed, body, accent, detail, horror);
  if (plan.runes) drawRunes(i, detail);
  return i;
}

const generatedEnemySpritePlans = <GeneratedMonsterSpritePlan>[
  GeneratedMonsterSpritePlan(
    id: 'forest_demon',
    glowColor: Rgba(48, 170, 90, 150),
    bodyColor: Rgba(45, 92, 53),
    accentColor: Rgba(129, 76, 39),
    form: 'humanoid',
    eyeCount: 3,
    horns: true,
    runes: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'plomp_piccolo',
    glowColor: Rgba(114, 185, 255, 120),
    bodyColor: Rgba(74, 145, 186),
    accentColor: Rgba(230, 212, 112),
    form: 'slime',
    eyeCount: 2,
  ),
  GeneratedMonsterSpritePlan(
    id: 'plomp_adulto',
    glowColor: Rgba(90, 156, 235, 140),
    bodyColor: Rgba(43, 104, 161),
    accentColor: Rgba(244, 229, 130),
    form: 'slime',
    eyeCount: 3,
    crown: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'elementale_aria_minore',
    glowColor: Rgba(173, 228, 255, 150),
    bodyColor: Rgba(153, 198, 212, 190),
    accentColor: Rgba(230, 248, 255),
    form: 'humanoid',
    eyeCount: 1,
    wings: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'elementale_fuoco_minore',
    glowColor: Rgba(255, 96, 40, 170),
    bodyColor: Rgba(155, 44, 30),
    accentColor: Rgba(255, 196, 62),
    form: 'humanoid',
    eyeCount: 2,
    horns: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'elementale_acqua_minore',
    glowColor: Rgba(70, 165, 255, 150),
    bodyColor: Rgba(45, 118, 172),
    accentColor: Rgba(160, 235, 255),
    form: 'slime',
    eyeCount: 2,
  ),
  GeneratedMonsterSpritePlan(
    id: 'elementale_terra_minore',
    glowColor: Rgba(170, 135, 85, 130),
    bodyColor: Rgba(112, 91, 69),
    accentColor: Rgba(89, 155, 72),
    form: 'construct',
    eyeCount: 2,
    runes: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'elementale_gelo_minore',
    glowColor: Rgba(155, 226, 255, 160),
    bodyColor: Rgba(115, 174, 201),
    accentColor: Rgba(238, 253, 255),
    form: 'construct',
    eyeCount: 1,
  ),
  GeneratedMonsterSpritePlan(
    id: 'elementale_fulmine_minore',
    glowColor: Rgba(251, 238, 74, 160),
    bodyColor: Rgba(95, 82, 160),
    accentColor: Rgba(255, 245, 95),
    form: 'humanoid',
    eyeCount: 3,
  ),
  GeneratedMonsterSpritePlan(
    id: 'elementale_ombra_minore',
    glowColor: Rgba(92, 64, 160, 150),
    bodyColor: Rgba(30, 28, 50),
    accentColor: Rgba(123, 88, 210),
    form: 'humanoid',
    eyeCount: 1,
    horns: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'elementale_sangue_minore',
    glowColor: Rgba(200, 24, 54, 160),
    bodyColor: Rgba(92, 36, 48),
    accentColor: Rgba(230, 50, 72),
    form: 'slime',
    eyeCount: 4,
  ),
  GeneratedMonsterSpritePlan(
    id: 'elementale_suono_minore',
    glowColor: Rgba(223, 145, 255, 150),
    bodyColor: Rgba(93, 65, 139),
    accentColor: Rgba(242, 202, 255),
    form: 'humanoid',
    eyeCount: 2,
    runes: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'pelle_sorridente',
    glowColor: Rgba(238, 116, 92, 130),
    bodyColor: Rgba(173, 95, 86),
    accentColor: Rgba(55, 28, 35),
    form: 'humanoid',
    eyeCount: 0,
  ),
  GeneratedMonsterSpritePlan(
    id: 'mago_zombie_contrasto',
    glowColor: Rgba(125, 220, 150, 140),
    bodyColor: Rgba(55, 92, 72),
    accentColor: Rgba(204, 62, 228),
    form: 'humanoid',
    eyeCount: 2,
    runes: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'bestia_invisibile_del_vantaggio',
    glowColor: Rgba(205, 226, 255, 110),
    bodyColor: Rgba(105, 122, 145, 150),
    accentColor: Rgba(246, 246, 255),
    form: 'beast',
    eyeCount: 1,
  ),
  GeneratedMonsterSpritePlan(
    id: 'monaco_bocca_cucita',
    glowColor: Rgba(186, 120, 92, 130),
    bodyColor: Rgba(83, 62, 48),
    accentColor: Rgba(28, 22, 25),
    form: 'humanoid',
    eyeCount: 2,
    threads: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'angelo_palpebra_sporca',
    glowColor: Rgba(238, 225, 156, 150),
    bodyColor: Rgba(172, 156, 117),
    accentColor: Rgba(88, 64, 54),
    form: 'humanoid',
    eyeCount: 1,
    wings: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'ragno_obser_falsi',
    glowColor: Rgba(95, 210, 190, 130),
    bodyColor: Rgba(34, 48, 55),
    accentColor: Rgba(95, 230, 204),
    form: 'beast',
    eyeCount: 6,
  ),
  GeneratedMonsterSpritePlan(
    id: 'fabbro_senza_lingua',
    glowColor: Rgba(255, 132, 60, 145),
    bodyColor: Rgba(72, 67, 62),
    accentColor: Rgba(224, 84, 45),
    form: 'construct',
    eyeCount: 1,
  ),
  GeneratedMonsterSpritePlan(
    id: 'cane_di_cenere',
    glowColor: Rgba(180, 168, 150, 125),
    bodyColor: Rgba(70, 66, 62),
    accentColor: Rgba(205, 108, 62),
    form: 'beast',
    eyeCount: 2,
  ),
  GeneratedMonsterSpritePlan(
    id: 'pellegrino_senza_volto',
    glowColor: Rgba(120, 105, 170, 130),
    bodyColor: Rgba(64, 58, 80),
    accentColor: Rgba(215, 198, 150),
    form: 'humanoid',
    eyeCount: 0,
  ),
  GeneratedMonsterSpritePlan(
    id: 'bambola_vapium',
    glowColor: Rgba(92, 210, 220, 140),
    bodyColor: Rgba(72, 116, 126),
    accentColor: Rgba(238, 106, 170),
    form: 'humanoid',
    eyeCount: 2,
    threads: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'occhio_caduto',
    glowColor: Rgba(180, 68, 230, 150),
    bodyColor: Rgba(165, 128, 152),
    accentColor: Rgba(92, 34, 140),
    form: 'eye',
    eyeCount: 1,
  ),
  GeneratedMonsterSpritePlan(
    id: 'custode_mani_inverse',
    glowColor: Rgba(112, 92, 190, 140),
    bodyColor: Rgba(77, 68, 98),
    accentColor: Rgba(218, 194, 158),
    form: 'humanoid',
    eyeCount: 4,
  ),
  GeneratedMonsterSpritePlan(
    id: 'santo_vuoto_piccolo',
    glowColor: Rgba(210, 210, 245, 120),
    bodyColor: Rgba(54, 52, 70),
    accentColor: Rgba(245, 232, 180),
    form: 'humanoid',
    eyeCount: 1,
    crown: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'prince_slime',
    glowColor: Rgba(120, 196, 255, 150),
    bodyColor: Rgba(54, 126, 190),
    accentColor: Rgba(254, 220, 82),
    form: 'slime',
    eyeCount: 2,
    crown: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'king_slime',
    glowColor: Rgba(70, 166, 255, 165),
    bodyColor: Rgba(42, 96, 170),
    accentColor: Rgba(255, 214, 70),
    form: 'slime',
    eyeCount: 3,
    crown: true,
    runes: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'cuore_filo',
    glowColor: Rgba(222, 44, 86, 150),
    bodyColor: Rgba(132, 36, 62),
    accentColor: Rgba(35, 24, 32),
    form: 'humanoid',
    eyeCount: 1,
    threads: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'lanterniere_osso',
    glowColor: Rgba(255, 195, 96, 150),
    bodyColor: Rgba(103, 88, 70),
    accentColor: Rgba(242, 216, 156),
    form: 'construct',
    eyeCount: 2,
  ),
  GeneratedMonsterSpritePlan(
    id: 'specchio_mangiavoce',
    glowColor: Rgba(170, 210, 245, 140),
    bodyColor: Rgba(85, 108, 130),
    accentColor: Rgba(235, 248, 255),
    form: 'eye',
    eyeCount: 0,
    runes: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'sentinella_lava_lacrime',
    glowColor: Rgba(255, 84, 38, 165),
    bodyColor: Rgba(98, 58, 48),
    accentColor: Rgba(255, 170, 54),
    form: 'construct',
    eyeCount: 2,
    horns: true,
  ),
  GeneratedMonsterSpritePlan(
    id: 'obliterato_null',
    glowColor: Rgba(230, 230, 255, 120),
    bodyColor: Rgba(20, 20, 28),
    accentColor: Rgba(245, 245, 255),
    form: 'humanoid',
    eyeCount: 0,
    runes: true,
  ),
];

Rgba colorForElement(String element, int channel) {
  final id = element.toLowerCase();
  final palettes = <String, List<Rgba>>{
    'fuoco': [Rgba(255, 86, 32, 170), Rgba(135, 44, 28), Rgba(255, 184, 58)],
    'gelo': [
      Rgba(162, 226, 255, 160),
      Rgba(105, 156, 190),
      Rgba(238, 252, 255),
    ],
    'acqua': [Rgba(70, 165, 255, 150), Rgba(45, 118, 172), Rgba(158, 235, 255)],
    'fulmine': [Rgba(250, 238, 74, 165), Rgba(92, 82, 160), Rgba(255, 246, 90)],
    'natura': [Rgba(58, 176, 96, 145), Rgba(49, 92, 54), Rgba(126, 206, 91)],
    'sangue': [Rgba(205, 22, 54, 165), Rgba(100, 34, 46), Rgba(232, 48, 74)],
    'osso': [Rgba(230, 220, 190, 135), Rgba(108, 101, 84), Rgba(238, 230, 200)],
    'oscuro': [Rgba(94, 58, 155, 150), Rgba(26, 23, 42), Rgba(126, 86, 210)],
    'vuoto': [Rgba(230, 230, 255, 120), Rgba(18, 18, 27), Rgba(245, 245, 255)],
    'ruggine': [Rgba(210, 104, 50, 135), Rgba(94, 59, 45), Rgba(198, 88, 42)],
    'cristallo': [
      Rgba(170, 216, 245, 140),
      Rgba(75, 108, 132),
      Rgba(232, 248, 255),
    ],
    'slime': [Rgba(90, 190, 255, 150), Rgba(52, 126, 178), Rgba(240, 225, 100)],
    'cenere': [Rgba(180, 166, 145, 130), Rgba(66, 63, 60), Rgba(214, 112, 64)],
    'psichico': [
      Rgba(196, 90, 235, 150),
      Rgba(88, 54, 124),
      Rgba(238, 190, 255),
    ],
    'sonoro': [
      Rgba(224, 150, 255, 145),
      Rgba(92, 64, 136),
      Rgba(240, 205, 255),
    ],
    'metallo': [
      Rgba(170, 190, 210, 135),
      Rgba(78, 88, 98),
      Rgba(220, 230, 238),
    ],
    'specchio': [
      Rgba(185, 218, 246, 140),
      Rgba(72, 100, 130),
      Rgba(244, 250, 255),
    ],
  };
  final fallback = [
    Rgba(136, 110, 210, 140),
    Rgba(70, 58, 96),
    Rgba(230, 214, 170),
  ];
  return (palettes[id] ?? fallback)[channel.clamp(0, 2).toInt()];
}

GeneratedMonsterSpritePlan planFromMonster(
  MonsterBookEntry monster, {
  int variant = 0,
}) {
  final name = '${monster.nameIt} ${monster.id}'.toLowerCase();
  final form = name.contains('slime') || name.contains('plomp')
      ? 'slime'
      : name.contains('cane') ||
            name.contains('capra') ||
            name.contains('ragno') ||
            name.contains('cervo') ||
            name.contains('topo') ||
            name.contains('corvo')
      ? 'beast'
      : name.contains('occhio') || name.contains('specchio')
      ? 'eye'
      : name.contains('sentinella') ||
            name.contains('guardia') ||
            name.contains('cavaliere') ||
            name.contains('lama') ||
            name.contains('costrutto')
      ? 'construct'
      : 'humanoid';
  final hash = monster.id.codeUnits.fold<int>(0, (sum, c) => sum + c);
  final horror =
      monster.isBoss ||
      monster.isMiniBoss ||
      name.contains('sangue') ||
      name.contains('vuoto') ||
      name.contains('scala') ||
      name.contains('sorriso') ||
      name.contains('torace') ||
      name.contains('fauce');
  final peaceful =
      name.contains('pacifico') ||
      monster.descIt.toLowerCase().contains('non ostile');
  return GeneratedMonsterSpritePlan(
    id: monster.id,
    glowColor: colorForElement(monster.elementId, 0),
    bodyColor: colorForElement(monster.elementId, 1),
    accentColor: colorForElement(monster.elementId, 2),
    detailColor: horror ? const Rgba(244, 238, 220) : const Rgba(255, 232, 150),
    form: form,
    eyeCount: monster.isBoss
        ? 5 + hash % 4
        : monster.isMiniBoss
        ? 3 + hash % 3
        : 1 + hash % 3,
    horns: horror || name.contains('orco') || name.contains('demone'),
    wings:
        name.contains('angelo') ||
        name.contains('falena') ||
        name.contains('ushrin'),
    crown: monster.isBoss || name.contains('king') || name.contains('prince'),
    threads: name.contains('filo') || name.contains('bambola') || hash % 7 == 0,
    runes: monster.isBoss || monster.isMiniBoss || hash % 5 == 0,
    variant: variant,
    horror: horror,
    peaceful: peaceful,
    themeText:
        '${monster.nameIt} ${monster.nameEn} ${monster.descIt} ${monster.elementId} ${monster.weaponTags.join(' ')} ${monster.armorTags.join(' ')}',
  );
}

void main() {
  final enemies = 'assets/oculum_dungeon/generated_sprites/enemies';
  final npcs = 'assets/oculum_dungeon/generated_sprites/npc';

  save('$enemies/uomo_in_posizione_fetale_refit.png', fetalMan());
  save('$enemies/headless_man_blood.png', headlessBlood());
  save('$enemies/true_nightmare_without_awakening.png', trueNightmare());
  save('$enemies/rock_rhino.png', rockRhino());
  save('$enemies/postea_scientist.png', posteaScientist());
  for (final plan in generatedEnemySpritePlans) {
    save('$enemies/${plan.id}.png', generatedMonster(plan));
  }
  for (final monster in monsterBookEntries) {
    final path = monster.spriteAssetPath;
    if (!path.startsWith(enemies) || !path.endsWith('.png')) continue;
    save(path, generatedMonster(planFromMonster(monster)));
    for (
      var variant = 1;
      variant <= monsterSpriteVariantCount(monster.id);
      variant++
    ) {
      save(
        monsterSpriteVariantAssetPath(path, variant),
        generatedMonster(planFromMonster(monster, variant: variant)),
      );
    }
  }
  save('$npcs/gufus_leviante.png', gufus());
  save('$npcs/postea_elite_guard.png', posteaGuard());
  save('$npcs/kooba_glimmer_moralist.png', kooba());
}
