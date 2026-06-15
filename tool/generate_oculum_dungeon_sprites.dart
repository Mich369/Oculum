import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

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

void px(img.Image canvas, int x, int y, Rgba c) {
  if (x < 0 || y < 0 || x >= canvas.width || y >= canvas.height) return;
  canvas.setPixelRgba(x, y, c.r, c.g, c.b, c.a);
}

void fillRect(img.Image canvas, int x, int y, int w, int h, Rgba c) {
  for (var yy = y; yy < y + h; yy++) {
    for (var xx = x; xx < x + w; xx++) {
      px(canvas, xx, yy, c);
    }
  }
}

void ellipse(img.Image canvas, int cx, int cy, int rx, int ry, Rgba c) {
  final rx2 = rx * rx;
  final ry2 = ry * ry;
  for (var y = cy - ry; y <= cy + ry; y++) {
    for (var x = cx - rx; x <= cx + rx; x++) {
      final dx = x - cx;
      final dy = y - cy;
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
  var dx = (x1 - x0).abs();
  var dy = -(y1 - y0).abs();
  final sx = x0 < x1 ? 1 : -1;
  final sy = y0 < y1 ? 1 : -1;
  var err = dx + dy;
  var x = x0;
  var y = y0;
  while (true) {
    for (var oy = -w ~/ 2; oy <= w ~/ 2; oy++) {
      for (var ox = -w ~/ 2; ox <= w ~/ 2; ox++) {
        px(canvas, x + ox, y + oy, c);
      }
    }
    if (x == x1 && y == y1) break;
    final e2 = 2 * err;
    if (e2 >= dy) {
      err += dy;
      x += sx;
    }
    if (e2 <= dx) {
      err += dx;
      y += sy;
    }
  }
}

void triangle(
  img.Image canvas,
  Point<int> a,
  Point<int> b,
  Point<int> c,
  Rgba color,
) {
  final minX = min(a.x, min(b.x, c.x));
  final maxX = max(a.x, max(b.x, c.x));
  final minY = min(a.y, min(b.y, c.y));
  final maxY = max(a.y, max(b.y, c.y));
  int edge(Point<int> p1, Point<int> p2, int x, int y) {
    return (x - p1.x) * (p2.y - p1.y) - (y - p1.y) * (p2.x - p1.x);
  }

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final w0 = edge(b, c, x, y);
      final w1 = edge(c, a, x, y);
      final w2 = edge(a, b, x, y);
      if ((w0 >= 0 && w1 >= 0 && w2 >= 0) || (w0 <= 0 && w1 <= 0 && w2 <= 0)) {
        px(canvas, x, y, color);
      }
    }
  }
}

void glow(img.Image canvas, int cx, int cy, int r, Rgba c) {
  for (var radius = r; radius > 0; radius--) {
    final alpha = (c.a * radius / r * 0.22).round();
    circle(canvas, cx, cy, radius, Rgba(c.r, c.g, c.b, alpha));
  }
}

img.Image canvas() {
  final image = img.Image(width: 256, height: 256, numChannels: 4);
  img.fill(image, color: transparent.color);
  return image;
}

void save(String path, img.Image image) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(image, level: 7));
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

void main() {
  final enemies = 'assets/oculum_dungeon/generated_sprites/enemies';
  final npcs = 'assets/oculum_dungeon/generated_sprites/npc';

  save('$enemies/uomo_in_posizione_fetale_refit.png', fetalMan());
  save('$enemies/headless_man_blood.png', headlessBlood());
  save('$enemies/true_nightmare_without_awakening.png', trueNightmare());
  save('$enemies/rock_rhino.png', rockRhino());
  save('$enemies/postea_scientist.png', posteaScientist());
  save('$npcs/gufus_leviante.png', gufus());
  save('$npcs/postea_elite_guard.png', posteaGuard());
  save('$npcs/kooba_glimmer_moralist.png', kooba());
}
