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
