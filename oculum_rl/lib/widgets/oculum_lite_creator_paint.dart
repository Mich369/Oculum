part of 'oculum_lite_arena.dart';

ColorFilter _inkDye(Color color, double strength) {
  final r = color.r * strength * 1.7;
  final g = color.g * strength * 1.7;
  final b = color.b * strength * 1.7;
  final original = 1 - strength;
  return ColorFilter.matrix([
    original + .21 * r,
    .72 * r,
    .07 * r,
    0,
    0,
    .21 * g,
    original + .72 * g,
    .07 * g,
    0,
    0,
    .21 * b,
    .72 * b,
    original + .07 * b,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);
}

void _paintCapeDye(
  Canvas canvas,
  ui.Image atlas,
  Rect source,
  Offset neck,
  Color cloth,
  double cell, {
  required _InkRig rig,
  required double phase,
  required double strength,
}) {
  final cape = Path()
    ..addPolygon([
      neck + const Offset(-46, -6),
      neck + const Offset(-25, 14),
      neck + const Offset(-41, 25),
      neck + const Offset(-49, 43),
      neck + const Offset(-66, 48),
      neck + const Offset(-54, 65),
      neck + const Offset(-72, 83),
      neck + const Offset(-126, 101),
      neck + const Offset(-197, 137),
      neck + const Offset(-223, 60),
      neck + const Offset(-117, 12),
    ], true);
  canvas.save();
  canvas.clipPath(cape);
  _inkActorSprite(
    canvas,
    atlas,
    source,
    Rect.fromLTWH(0, 0, cell, cell),
    Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = _inkDye(cloth, .78),
    rig,
    phase: phase,
    strength: strength,
    clothFlow: strength,
  );
  canvas.restore();
}

Offset _inHead(Rect rect, double x, double y) =>
    Offset(rect.left + x * rect.width, rect.top + y * rect.height);

void _paintFaceLayers(
  Canvas canvas,
  ui.Image atlas,
  Rect source,
  Rect head,
  OculumLiteAppearance look, {
  required Offset iris,
  required bool spectral,
}) {
  final goblin = look.lineage == OculumLiteLineage.goblin;
  final accent = spectral ? const Color(0xffad88dd) : look.accent;
  final skin = spectral ? const Color(0xff9877b9) : look.skin;
  final hair = spectral ? const Color(0xff8a6aa6) : look.hair;
  Offset p(double x, double y) => _inHead(head, x, y);
  final imagePaint = Paint()..filterQuality = FilterQuality.medium;
  if (spectral) {
    imagePaint.colorFilter = const ColorFilter.mode(
      Color(0xffa080c6),
      BlendMode.modulate,
    );
  }
  canvas.drawImageRect(atlas, source, head, imagePaint);

  // Keep the engraved values of the head atlas while coloring only painted regions.
  void recolor(List<Offset> outline, Color color, double strength) {
    canvas.save();
    canvas.clipPath(Path()..addPolygon(outline, true));
    canvas.drawImageRect(
      atlas,
      source,
      head,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = _inkDye(color, strength),
    );
    canvas.restore();
  }

  if (spectral || look.skin != const OculumLiteAppearance().skin) {
    recolor(
      [
        p(.50, .44),
        p(.65, .24),
        p(.89, .25),
        p(.97, .53),
        p(.98, .69),
        p(.87, .81),
        p(.74, .82),
        p(.67, .98),
        p(.36, .90),
        p(.46, .66),
      ],
      skin,
      .52,
    );
  }
  if (spectral || look.hair != const OculumLiteAppearance().hair) {
    recolor(
      [
        p(0, 0),
        p(1, 0),
        p(1, .27),
        p(.72, .28),
        p(.55, .40),
        p(.48, .56),
        p(.34, .63),
        p(.28, .96),
        p(0, .96),
      ],
      hair,
      .55,
    );
  }
  if (look.hairstyle.needsPaintedSilhouette) {
    _paintNewHair(canvas, head, look.hairstyle, hair, accent);
  }
  if (goblin && look.ears > .56) {
    final tip = p(-.07 - (look.ears - .56) * .28, .34);
    _poly(
      canvas,
      [p(.23, .51), tip, p(.16, .39), p(.31, .45), p(.35, .60)],
      Color.lerp(skin, _ink, .24)!,
      stroke: _ink,
      width: 1.45,
    );
    _lines(
      canvas,
      [tip + const Offset(4, 2), p(.18, .44), p(.25, .53)],
      Color.lerp(skin, accent, .25)!,
      1.05,
    );
  }
  final eye = p(iris.dx, iris.dy);
  if (spectral || look.eyes != const OculumLiteAppearance().eyes) {
    canvas.drawOval(
      Rect.fromCenter(center: eye, width: 3.5, height: 2.5),
      Paint()..color = spectral ? _violet : look.eyes,
    );
    canvas.drawCircle(eye + const Offset(.5, 0), .7, Paint()..color = _ink);
  }
  switch (look.faceDetail) {
    case OculumLiteFaceDetail.none:
      break;
    case OculumLiteFaceDetail.scar:
      final edge = [p(.62, .36), p(.66, .47), p(.61, .58), p(.57, .65)];
      _lines(canvas, edge, const Color(0xff5e333a), 2.5);
      _lines(
        canvas,
        edge.map((at) => at + const Offset(1.2, .25)).toList(),
        Color.lerp(skin, const Color(0xfff1b094), .62)!,
        .85,
      );
    case OculumLiteFaceDetail.warpaint:
      _poly(
        canvas,
        [
          p(.56, .47),
          p(.77, .50),
          p(.70, .60),
          p(.65, .64),
          p(.69, .54),
          p(.54, .52),
        ],
        Color.lerp(accent, _ink, .24)!,
        stroke: _ink,
        width: .9,
      );
    case OculumLiteFaceDetail.freckles:
      for (final dot in const [
        Offset(.65, .54),
        Offset(.70, .55),
        Offset(.74, .56),
        Offset(.77, .53),
        Offset(.62, .57),
        Offset(.68, .59),
      ]) {
        canvas.drawCircle(
          p(dot.dx, dot.dy),
          1.2,
          Paint()..color = Color.lerp(skin, _ink, .70)!,
        );
      }
    case OculumLiteFaceDetail.blindfold:
      _poly(
        canvas,
        [p(.43, .40), p(.84, .43), p(.81, .54), p(.47, .50)],
        Color.lerp(_ink, look.cloth, .36)!,
        stroke: _ink,
        width: 1.4,
      );
    case OculumLiteFaceDetail.inkRunes:
      _lines(
        canvas,
        [p(.60, .55), p(.69, .62), p(.76, .55)],
        Color.lerp(skin, accent, .75)!,
        1.7,
      );
      _lines(canvas, [p(.67, .53), p(.69, .62), p(.68, .71)], accent, 1.1);
    case OculumLiteFaceDetail.clasp:
      final center = p(goblin ? .31 : .43, goblin ? .57 : .65);
      _oval(
        canvas,
        center,
        7,
        9,
        Colors.transparent,
        stroke: _ink,
        strokeWidth: 3,
      );
      _oval(
        canvas,
        center,
        7,
        9,
        Colors.transparent,
        stroke: accent,
        strokeWidth: 1.6,
      );
  }

  final textile = Color.lerp(look.cloth, _ink, .30)!;
  void piece(List<Offset> points, Color fill) =>
      _poly(canvas, points, fill, stroke: _ink, width: 2);
  switch (look.headgear) {
    case OculumLiteHeadgear.none:
      break;
    case OculumLiteHeadgear.band:
      piece([
        p(.29, .32),
        p(.68, .26),
        p(.88, .29),
        p(.90, .36),
        p(.57, .34),
        p(.35, .40),
        p(.23, .44),
      ], textile);
      _lines(canvas, [p(.35, .35), p(.66, .29), p(.83, .32)], accent, 1.25);
    case OculumLiteHeadgear.circlet:
      piece([
        p(.37, .31),
        p(.55, .23),
        p(.69, .29),
        p(.79, .19),
        p(.88, .33),
        p(.73, .35),
        p(.57, .29),
      ], accent);
      piece([p(.79, .25), p(.84, .31), p(.79, .35), p(.75, .30)], look.eyes);
    case OculumLiteHeadgear.horns:
      for (final (x, y) in [(.35, .23), (.64, .17)]) {
        piece([
          p(x - .09, y),
          p(x - .09, y - .13),
          p(x - .19, y - .29),
          p(x - .04, y - .23),
          p(x + .04, y - .09),
          p(x + .07, y + .03),
        ], Color.lerp(accent, const Color(0xffd8c3a3), .58)!);
        _lines(
          canvas,
          [p(x - .09, y - .14), p(x - .02, y - .11), p(x + .01, y - .04)],
          Color.lerp(accent, _ink, .64)!,
          1.3,
        );
      }
    case OculumLiteHeadgear.goggles:
      _lines(canvas, [p(.29, .43), eye], _ink, 5);
      _lines(canvas, [p(.30, .42), eye], accent, 1.5);
      _oval(
        canvas,
        eye,
        15,
        11,
        const Color(0xff223a3e),
        stroke: _ink,
        strokeWidth: 3,
      );
      _oval(
        canvas,
        eye,
        13,
        9,
        const Color(0xff345f66),
        stroke: accent,
        strokeWidth: 1.5,
      );
      _lines(
        canvas,
        [eye + const Offset(-3, 1), eye + const Offset(1, -2)],
        const Color(0xffa9c7b8),
        1.2,
      );
    case OculumLiteHeadgear.hood:
      piece([
        p(.07, .75),
        p(.15, .24),
        p(.48, .01),
        p(.70, -.06),
        p(.88, .16),
        p(.95, .30),
        p(.70, .24),
        p(.58, .39),
        p(.49, .69),
        p(.62, .90),
        p(.36, .87),
        p(.19, .81),
      ], textile);
      _lines(
        canvas,
        [p(.24, .48), p(.30, .26), p(.50, .10), p(.66, .03)],
        accent,
        1.3,
      );
      _dryBrush(
        canvas,
        p(.31, .33),
        const Offset(-1.4, 3.4),
        const Offset(8, -9),
        Color.lerp(textile, accent, .35)!,
        7,
        width: .8,
      );
  }
}

void _paintNewHair(
  Canvas canvas,
  Rect head,
  OculumLiteHair style,
  Color hair,
  Color accent,
) {
  final shadow = Color.lerp(hair, _ink, .51)!;
  final highlight = Color.lerp(hair, const Color(0xffd4a579), .35)!;
  canvas.save();
  canvas.translate(head.left, head.top);
  canvas.scale(head.width, head.height);
  final outline = switch (style) {
    OculumLiteHair.highPony => const [
      Offset(.13, .31),
      Offset(.15, .08),
      Offset(.36, -.055),
      Offset(.53, -.06),
      Offset(.69, .055),
      Offset(.70, -.16),
      Offset(.50, -.22),
      Offset(.19, -.17),
      Offset(-.02, -.04),
      Offset(-.21, .14),
      Offset(-.24, .51),
      Offset(-.11, .44),
      Offset(-.035, .22),
      Offset(.15, .13),
      Offset(.27, .08),
      Offset(.46, .12),
      Offset(.65, .26),
      Offset(.45, .22),
      Offset(.24, .36),
    ],
    OculumLiteHair.longBraid => const [
      Offset(.08, .33),
      Offset(.13, .12),
      Offset(.33, -.035),
      Offset(.61, -.045),
      Offset(.78, .06),
      Offset(.84, .19),
      Offset(.73, .17),
      Offset(.58, .23),
      Offset(.39, .21),
      Offset(.19, .37),
      Offset(.10, .44),
      Offset(.19, .68),
      Offset(.04, .92),
      Offset(.08, 1.13),
      Offset(-.065, 1.29),
      Offset(-.16, 1.11),
      Offset(-.12, .88),
      Offset(-.02, .66),
      Offset(-.10, .46),
    ],
    OculumLiteHair.curls => const [
      Offset(.06, .32),
      Offset(.015, .21),
      Offset(.07, .11),
      Offset(.05, .02),
      Offset(.16, -.04),
      Offset(.20, -.135),
      Offset(.33, -.12),
      Offset(.43, -.20),
      Offset(.53, -.13),
      Offset(.64, -.165),
      Offset(.72, -.085),
      Offset(.84, -.06),
      Offset(.88, .04),
      Offset(.97, .10),
      Offset(.91, .23),
      Offset(.79, .24),
      Offset(.72, .19),
      Offset(.59, .29),
      Offset(.48, .22),
      Offset(.36, .34),
      Offset(.27, .28),
      Offset(.20, .39),
      Offset(.13, .33),
    ],
    OculumLiteHair.mohawk => const [
      Offset(.12, .235),
      Offset(.19, .055),
      Offset(.22, -.13),
      Offset(.35, -.11),
      Offset(.38, -.26),
      Offset(.50, -.18),
      Offset(.54, -.30),
      Offset(.64, -.185),
      Offset(.77, -.19),
      Offset(.82, .01),
      Offset(.74, .15),
      Offset(.53, .135),
      Offset(.37, .20),
      Offset(.29, .17),
    ],
    OculumLiteHair.swept => const [
      Offset(.09, .34),
      Offset(.10, .09),
      Offset(.26, -.05),
      Offset(.56, -.15),
      Offset(.83, -.11),
      Offset(1.06, -.02),
      Offset(.93, .07),
      Offset(.98, .18),
      Offset(.83, .15),
      Offset(.73, .30),
      Offset(.65, .24),
      Offset(.53, .31),
      Offset(.47, .19),
      Offset(.25, .26),
      Offset(.16, .36),
    ],
    _ => const <Offset>[],
  };
  _poly(canvas, outline, hair, stroke: _ink, width: .034);
  if (style == OculumLiteHair.longBraid) {
    for (final (x, y) in const [
      (.02, .52),
      (.08, .65),
      (.015, .79),
      (-.065, .92),
      (-.055, 1.06),
    ]) {
      _lines(
        canvas,
        [
          Offset(x - .068, y - .03),
          Offset(x, y + .02),
          Offset(x + .086, y - .025),
        ],
        shadow,
        .035,
      );
      _lines(
        canvas,
        [Offset(x - .045, y + .023), Offset(x, y + .056)],
        highlight,
        .019,
      );
    }
    _lines(
      canvas,
      const [Offset(-.104, 1.095), Offset(.047, 1.118)],
      accent,
      .04,
    );
  } else if (style == OculumLiteHair.curls) {
    for (final (x, y) in const [
      (.15, .17),
      (.30, .015),
      (.46, -.065),
      (.63, .0),
      (.76, .09),
    ]) {
      _lines(
        canvas,
        [
          Offset(x - .04, y + .07),
          Offset(x - .016, y - .018),
          Offset(x + .08, y - .031),
          Offset(x + .11, y + .03),
        ],
        shadow,
        .039,
      );
      _lines(
        canvas,
        [Offset(x, y + .002), Offset(x + .07, y - .012)],
        highlight,
        .019,
      );
    }
  } else {
    _lines(
      canvas,
      const [Offset(.25, .13), Offset(.45, .022), Offset(.69, .018)],
      highlight,
      .031,
    );
    _lines(
      canvas,
      const [Offset(.19, .19), Offset(.41, .095), Offset(.62, .08)],
      shadow,
      .034,
    );
    if (style == OculumLiteHair.highPony) {
      _lines(
        canvas,
        const [Offset(.24, -.003), Offset(.32, -.077)],
        accent,
        .046,
      );
      _lines(
        canvas,
        const [Offset(-.17, .32), Offset(-.09, .10), Offset(.13, -.055)],
        highlight,
        .032,
      );
    }
  }
  canvas.restore();
}

void _paintCostumeLayers(
  Canvas canvas,
  Offset center,
  OculumLiteAppearance look, {
  required bool spectral,
  required bool compact,
}) {
  final cloth = spectral ? const Color(0xff594561) : look.cloth;
  final accent = spectral ? const Color(0xffb398de) : look.accent;
  final seam = Color.lerp(cloth, accent, .54)!;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  if (compact) canvas.scale(.74);
  void piece(List<Offset> points, Color color) =>
      _poly(canvas, points, color, stroke: _ink, width: 2.8);
  final backing = [
    const Offset(-29, -14),
    const Offset(-7, -18),
    const Offset(17, -12),
    const Offset(12, 3),
    const Offset(3, 12),
    const Offset(-19, 8),
    const Offset(-36, 4),
  ];
  piece(backing, Color.lerp(cloth, _ink, .27)!);
  canvas.save();
  canvas.clipPath(Path()..addPolygon(backing, true));
  _dryBrush(
    canvas,
    const Offset(-31, -5),
    const Offset(3.8, .65),
    const Offset(7, -4),
    seam.withValues(alpha: .62),
    12,
    width: 1.05,
  );
  canvas.restore();
  switch (look.outfit) {
    case OculumLiteOutfit.cloak:
      _lines(
        canvas,
        const [Offset(-28, 1), Offset(-12, -11), Offset(7, 2)],
        seam,
        2.1,
      );
    case OculumLiteOutfit.cuirass:
      piece(const [
        Offset(-30, -6),
        Offset(-8, -13),
        Offset(12, -8),
        Offset(8, 3),
        Offset(-4, 8),
        Offset(-25, 5),
      ], Color.lerp(cloth, const Color(0xff81909a), .65)!);
      _lines(
        canvas,
        const [Offset(-26, -5), Offset(-9, -9), Offset(6, -6)],
        accent,
        2.8,
      );
    case OculumLiteOutfit.vest:
      _lines(
        canvas,
        const [
          Offset(-24, 0),
          Offset(-16, -8),
          Offset(-10, -9),
          Offset(-11, 2),
        ],
        accent,
        2.5,
      );
    case OculumLiteOutfit.duelist:
      _lines(
        canvas,
        const [Offset(-25, -6), Offset(-11, -12), Offset(4, 5)],
        accent,
        5,
      );
      _lines(
        canvas,
        const [Offset(-25, -6), Offset(-11, -12), Offset(4, 5)],
        seam,
        1.15,
      );
    case OculumLiteOutfit.ritual:
      _lines(
        canvas,
        const [
          Offset(-20, 2),
          Offset(-25, -4),
          Offset(-15, -12),
          Offset(-5, -8),
          Offset(-7, 0),
        ],
        accent,
        2,
      );
      _lines(canvas, const [Offset(-16, -7), Offset(-17, 1)], accent, 1.5);
    case OculumLiteOutfit.forager:
      piece(const [
        Offset(-28, -9),
        Offset(-11, -12),
        Offset(8, -3),
        Offset(7, 3),
        Offset(-10, .5),
        Offset(-23, 6),
      ], Color.lerp(cloth, const Color(0xff756337), .60)!);
      _lines(
        canvas,
        const [Offset(-22, -5), Offset(-10, -8), Offset(3, -2)],
        accent,
        2,
      );
    case OculumLiteOutfit.lamellar:
      for (var i = 0; i < 3; i++) {
        final y = -9.0 + i * 4;
        piece([
          Offset(-27 + i.toDouble(), y),
          Offset(-7, y - 3),
          Offset(9, y - 1),
          Offset(6, y + 3),
          Offset(-19, y + 4),
        ], Color.lerp(cloth, const Color(0xff879293), .24 + .12 * i)!);
      }
    case OculumLiteOutfit.postea:
      for (var i = 0; i < 3; i++) {
        final x = -27.0 + i * 7;
        piece([
          Offset(x, -4),
          Offset(x + 3, -9),
          Offset(x + 8, -7),
          Offset(x + 6, 1),
          Offset(x + 1, 3),
        ], Color.lerp(cloth, const Color(0xff74717a), .55)!);
      }
      _lines(
        canvas,
        const [Offset(-26, -1), Offset(-18, -4), Offset(-9, -3), Offset(-4, 0)],
        accent,
        1.85,
      );
  }

  if (look.emblem != OculumLiteEmblem.none) {
    canvas.translate(5, -1);
    _oval(
      canvas,
      Offset.zero,
      17,
      16,
      Color.lerp(cloth, _ink, .65)!,
      stroke: accent,
      strokeWidth: 1.8,
    );
    final symbol = switch (look.emblem) {
      OculumLiteEmblem.eye => const [
        Offset(-5, 0),
        Offset(0, -3),
        Offset(5, 0),
        Offset(0, 3),
        Offset(-5, 0),
      ],
      OculumLiteEmblem.moon => const [
        Offset(1, -5),
        Offset(-3, -2),
        Offset(-4, 2),
        Offset(-1, 5),
        Offset(3, 4),
        Offset(0, 1),
        Offset(1, -5),
      ],
      OculumLiteEmblem.flame => const [
        Offset(-3, 3),
        Offset(-3, 0),
        Offset(1, -5),
        Offset(2, -1),
        Offset(4, 1),
        Offset(2, 4),
        Offset(-1, 5),
      ],
      OculumLiteEmblem.rune => const [
        Offset(-3, 4),
        Offset(-3, -4),
        Offset(3, -4),
        Offset(1, 0),
        Offset(4, 4),
      ],
      OculumLiteEmblem.feather => const [
        Offset(-4, 5),
        Offset(1, -4),
        Offset(5, -6),
        Offset(4, -1),
        Offset(-2, 3),
        Offset(-1, 0),
      ],
      OculumLiteEmblem.crystal => const [
        Offset(0, -6),
        Offset(5, 0),
        Offset(0, 6),
        Offset(-5, 0),
        Offset(0, -6),
        Offset(1, 2),
        Offset(0, 6),
      ],
      OculumLiteEmblem.none => const <Offset>[],
    };
    _lines(canvas, symbol, accent, 1.25);
    if (look.emblem == OculumLiteEmblem.eye) {
      canvas.drawCircle(Offset.zero, 1.3, Paint()..color = accent);
    }
  }
  canvas.restore();
}
