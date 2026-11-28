part of 'oculum_lite_arena.dart';

class OculumLiteWeaponIcon extends StatelessWidget {
  const OculumLiteWeaponIcon({
    super.key,
    required this.weapon,
    required this.size,
  });

  final LiteWeapon weapon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final art = OculumLiteArena.weaponArt(weapon);
    return SizedBox.square(
      dimension: size,
      child: art == null
          ? CustomPaint(painter: _BossWeaponIcon(weapon))
          : Image(
              image: ResizeImage(art, width: (size * 2).round()),
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
    );
  }
}

class _BossWeaponIcon extends CustomPainter {
  const _BossWeaponIcon(this.weapon);

  final LiteWeapon weapon;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * .43, size.height / 2);
    canvas.rotate(-.28);
    canvas.scale(size.shortestSide / 3);
    _weapon(canvas, weapon, _sand, _ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BossWeaponIcon oldDelegate) =>
      oldDelegate.weapon != weapon;
}

Path _oldWeaponSilhouette(LiteWeapon weapon, bool feminine) {
  final path = Path();
  if (weapon == LiteWeapon.piccaOssidiana) {
    path.addPolygon(
      feminine
          ? const [
              Offset(205, 79),
              Offset(351, 80),
              Offset(383, 212),
              Offset(337, 227),
              Offset(269, 147),
              Offset(235, 137),
            ]
          : const [
              Offset(192, 83),
              Offset(349, 91),
              Offset(363, 208),
              Offset(325, 220),
              Offset(243, 145),
              Offset(217, 131),
            ],
      true,
    );
  } else {
    path.addRect(
      Rect.fromLTRB(
        feminine ? 299 : 264,
        feminine ? 144 : 159,
        383,
        feminine ? 186 : 199,
      ),
    );
  }
  return path;
}

void _paintBossWeaponAtGrip(Canvas canvas, LiteWeapon weapon, bool feminine) {
  if (weapon == LiteWeapon.piccaOssidiana) {
    canvas.save();
    canvas.translate(feminine ? 244 : 229, feminine ? 142 : 144);
    canvas.rotate(-1.06);
    canvas.scale(43);
    _obsidianSpearHead(canvas);
    canvas.restore();
  } else {
    canvas.save();
    canvas.translate(feminine ? 297 : 263, feminine ? 166 : 178);
    canvas.rotate(feminine ? .065 : .026);
    canvas.scale(40);
    _runeCrossbowFront(canvas);
    canvas.restore();
  }
}

void _obsidianSpearHead(Canvas canvas) {
  _poly(
    canvas,
    const [
      Offset(-.14, -.11),
      Offset(.32, -.12),
      Offset(.40, -.26),
      Offset(.78, -.32),
      Offset(1.95, 0),
      Offset(.96, .20),
      Offset(.48, .19),
      Offset(.31, .10),
      Offset(-.15, .11),
    ],
    const Color(0xff222032),
    stroke: _ink,
    width: .10,
  );
  _poly(canvas, const [
    Offset(.40, -.25),
    Offset(.78, -.30),
    Offset(1.91, -.015),
    Offset(.91, .013),
    Offset(.53, -.06),
  ], const Color(0xff695a79));
  _lines(
    canvas,
    const [Offset(.55, -.22), Offset(.76, -.25), Offset(1.54, -.07)],
    const Color(0xffba98bd),
    .042,
  );
  _lines(
    canvas,
    const [
      Offset(-.04, -.13),
      Offset(.21, -.10),
      Offset(.20, .13),
      Offset(-.04, .11),
    ],
    const Color(0xffae7754),
    .066,
  );
}

void _runeCrossbowFront(Canvas canvas) {
  const brass = Color(0xffa1714c);
  const inlay = Color(0xffa9d6de);
  const body = Color(0xff354752);
  _poly(
    canvas,
    const [
      Offset(-.20, -.19),
      Offset(.64, -.17),
      Offset(.89, -.02),
      Offset(.63, .17),
      Offset(-.16, .14),
    ],
    body,
    stroke: _ink,
    width: .10,
  );
  const limbs = [
    Offset(.15, -.88),
    Offset(.56, -.70),
    Offset(.72, -.35),
    Offset(.85, .0),
    Offset(.72, .35),
    Offset(.54, .64),
    Offset(.19, .80),
  ];
  _lines(canvas, limbs, _ink, .17);
  _lines(canvas, limbs, brass, .105);
  _lines(
    canvas,
    const [Offset(.15, -.88), Offset(-.44, 0), Offset(.19, .80)],
    const Color(0xffd5b89a),
    .042,
  );
  _lines(canvas, const [Offset(-.36, -.018), Offset(1.08, -.018)], inlay, .047);
  _poly(
    canvas,
    const [Offset(1.14, -.019), Offset(.92, -.115), Offset(.93, .078)],
    inlay,
    stroke: _ink,
    width: .039,
  );
  _lines(
    canvas,
    const [Offset(.34, .046), Offset(.43, .10), Offset(.52, .027)],
    brass,
    .041,
  );
}

void _paintBossWeaponItem(Canvas canvas, LiteWeapon weapon) {
  canvas.save();
  if (weapon == LiteWeapon.piccaOssidiana) {
    _lines(canvas, const [Offset(-.92, .046), Offset(.66, -.01)], _ink, .138);
    _lines(
      canvas,
      const [Offset(-.92, .046), Offset(.66, -.01)],
      const Color(0xff8b664e),
      .082,
    );
    canvas.translate(.63, -.02);
    canvas.scale(.52);
    _obsidianSpearHead(canvas);
  } else {
    _poly(
      canvas,
      const [
        Offset(-.68, .064),
        Offset(-.44, -.19),
        Offset(.30, -.14),
        Offset(.48, .09),
        Offset(.06, .17),
        Offset(-.04, .32),
        Offset(-.23, .26),
        Offset(-.20, .10),
      ],
      const Color(0xff65463d),
      stroke: _ink,
      width: .080,
    );
    canvas.translate(.46, -.06);
    canvas.scale(.63);
    _runeCrossbowFront(canvas);
  }
  canvas.restore();
}

void _paintDropSignal(
  Canvas canvas,
  Offset at,
  Offset tip,
  LiteLoot loot,
  double time,
) {
  final rare =
      loot.weapon?.isBossLoot == true ||
      loot.kind == LiteLootKind.refinedGreenGem;
  final hue = switch (loot.kind) {
    LiteLootKind.weapon =>
      rare ? const Color(0xffe5b778) : const Color(0xffaabbd6),
    LiteLootKind.scroll =>
      loot.scroll == LiteScroll.raggioAlPlasma
          ? const Color(0xffa1dfd4)
          : const Color(0xffd0ace9),
    LiteLootKind.refinedGreenGem ||
    LiteLootKind.greenStone ||
    LiteLootKind.healing => const Color(0xff8ddb9e),
    LiteLootKind.obser => const Color(0xffd1a66d),
    LiteLootKind.lunarSymbol => const Color(0xffbacaff),
  };
  if (loot.kind == LiteLootKind.obser) {
    final flicker = (math.sin(time * 6 + at.dx) + 1) / 2;
    _inkSlash(
      canvas,
      tip + const Offset(.10, -.10),
      tip + const Offset(.22, -.24),
      hue.withValues(alpha: .35 + .50 * flicker),
      .049,
    );
    return;
  }
  final extent = rare ? .73 : .44;
  final phase = (math.sin(time * 3.2 + at.dx) + 1) / 2;
  _oval(
    canvas,
    at,
    extent,
    extent * .35,
    hue.withValues(alpha: .08 + .07 * phase),
    stroke: hue.withValues(alpha: .31 + .28 * phase),
    strokeWidth: .028,
  );
  if (rare) {
    for (var i = 0; i < 3; i++) {
      final lift = (time * .88 + i / 3 + at.dx) % 1;
      final atMark = at + Offset((i - 1) * .24, -lift * .94 - .13);
      _inkSlash(
        canvas,
        atMark + const Offset(-.025, .075),
        atMark + const Offset(.035, -.065),
        hue.withValues(alpha: (1 - lift) * .91),
        .047,
      );
    }
  }
}

void _paintChakramRing(
  Canvas canvas, {
  required double tilt,
  required double spin,
}) {
  const steel = Color(0xff7cadad);
  const bevel = Color(0xffcbe9e2);
  const dark = Color(0xff334d55);
  const outer = Rect.fromLTRB(-.34, -.34, .34, .34);
  const inner = Rect.fromLTRB(-.20, -.20, .20, .20);
  canvas.save();
  canvas.scale(1, tilt);
  canvas.rotate(spin);
  final ring = Path()
    ..fillType = PathFillType.evenOdd
    ..addOval(outer)
    ..addOval(inner);
  canvas.drawPath(ring, Paint()..color = steel);
  canvas.drawPath(
    ring,
    Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = .048,
  );
  final shadow = Paint()
    ..color = dark
    ..style = PaintingStyle.stroke
    ..strokeWidth = .065;
  final rim = Paint()
    ..color = bevel
    ..style = PaintingStyle.stroke
    ..strokeWidth = .048;
  for (var i = 0; i < 3; i++) {
    final angle = i * math.pi * 2 / 3;
    canvas.drawArc(outer.deflate(.045), angle + .15, .95, false, rim);
    canvas.drawArc(inner.inflate(.038), angle + .54, 1.11, false, shadow);
    final rune = Offset(math.cos(angle), math.sin(angle));
    _inkSlash(canvas, rune * .229, rune * .302, const Color(0xffe9f3c6), .029);
  }
  canvas.restore();
}

void _paintCanonicalChakram(
  Canvas canvas,
  ui.Image? art, {
  required double tilt,
  required double spin,
}) {
  if (art == null) {
    _paintChakramRing(canvas, tilt: tilt, spin: spin);
    return;
  }
  canvas.save();
  canvas.scale(1, tilt);
  canvas.rotate(spin);
  // Read the foreground ring of the canonical paired inventory image.
  const bounds = Rect.fromLTRB(-.41, -.41, .41, .41);
  canvas.save();
  canvas.clipPath(
    Path()
      ..moveTo(-.41, .01)
      ..quadraticBezierTo(-.33, -.35, .06, -.39)
      ..quadraticBezierTo(.30, -.37, .40, -.07)
      ..quadraticBezierTo(.46, .28, .11, .41)
      ..quadraticBezierTo(-.27, .48, -.41, .01)
      ..close(),
  );
  canvas.drawImageRect(
    art,
    Rect.fromLTRB(
      art.width * .025,
      art.height * .323,
      art.width * .657,
      art.height * .991,
    ),
    bounds,
    Paint()..filterQuality = FilterQuality.medium,
  );
  canvas.restore();
  canvas.restore();
}

void _paintChakramFlight(
  Canvas canvas,
  Offset feet,
  Offset direction,
  double age,
  Offset? returnTarget, {
  ui.Image? art,
}) {
  final launch = (1 - age / .11).clamp(0.0, 1.0);
  final catchEase = returnTarget == null
      ? 0.0
      : (1 - ((returnTarget - feet).distance - .58) / 1.35).clamp(0.0, 1.0);
  final grip = math.max(launch, catchEase);
  final at =
      feet +
      direction * (.37 * launch) -
      Offset(0, .72 + grip * .49 + math.sin(age * 12) * .055);
  final fadeTail = (age / .07).clamp(0.0, 1.0) * (1 - catchEase * .62);
  final normal = Offset(-direction.dy, direction.dx);
  final wake = at - direction * (1.05 * fadeTail);
  _shadow(canvas, feet, .25, .10, alpha: .30);
  _inkSlash(
    canvas,
    wake + normal * .16,
    at - direction * .12,
    const Color(0x885d918e),
    .125 * fadeTail,
  );
  _inkSlash(
    canvas,
    wake + direction * .25 - normal * .11,
    at - direction * .21,
    const Color(0xb6b7eadf),
    .058 * fadeTail,
  );
  _actor(canvas, at, 1 - catchEase * .28, 1 - catchEase * .28, () {
    canvas.rotate(direction.direction * .64 + math.sin(age * 15) * .11);
    final tilt = .60 + math.sin(age * 14) * .17;
    final spin = age * 29 + math.sin(age * 14) * .1;
    _paintCanonicalChakram(canvas, art, tilt: tilt, spin: spin);
  });
}
