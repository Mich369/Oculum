part of '../oculum_dungeon_game.dart';

class _OculumSpritePainter extends CustomPainter {
  const _OculumSpritePainter({
    required this.color,
    required this.seed,
    required this.kind,
    this.eyeColor = Colors.white,
    this.layers = 0,
    this.weaponKind = '',
    this.weaponColor = Colors.white,
    this.weaponSeed = 0,
    this.armorKind = '',
    this.armorColor = Colors.transparent,
    this.armorSeed = 0,
  });

  final Color color;
  final int seed;
  final String kind;
  final Color eyeColor;
  final int layers;
  final String weaponKind;
  final Color weaponColor;
  final int weaponSeed;
  final String armorKind;
  final Color armorColor;
  final int armorSeed;

  double _unit(int salt, [int base = 0]) {
    final raw =
        ((base == 0 ? seed : base) * 1103515245 + salt * 12345) & 0x7fffffff;
    return raw / 0x7fffffff;
  }

  int _variant(int count, [int base = 0]) {
    return (((base == 0 ? seed : base).abs()) % count).toInt();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final p = Paint()..isAntiAlias = true;
    final dark = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFF070812);
    final layerCount = layers.clamp(0, 5).toInt();

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(w * .12)),
    );

    p.color = color.withValues(alpha: 0.22);
    canvas.drawOval(Rect.fromLTWH(w * .16, h * .74, w * .68, h * .16), p);

    if (kind == 'gadget_weapon') {
      _paintHideanGadget(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'pawn') {
      _paintPawn(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'weapon') {
      _paintWeapon(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'armor') {
      _paintArmor(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'relic') {
      _paintRelic(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'art') {
      _paintArt(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'drop') {
      _paintDrop(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'eye') {
      _paintEye(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'dotted_eye') {
      _paintDottedEye(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'legendary_eye_knight') {
      _paintLegendaryEyeKnight(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'cultist') {
      _paintCultist(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'valley') {
      _paintValley(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'vitalium') {
      _paintVitalium(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'slime_helmeted') {
      _paintSlimeHelmeted(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'patalpa') {
      _paintPatalpa(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'mimic') {
      _paintMimic(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'nightmare') {
      _paintNightmare(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'rock_rhino') {
      _paintRockRhino(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'merchant') {
      _paintMerchant(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'alchemist') {
      _paintAlchemist(canvas, size, p, dark);
      canvas.restore();
      return;
    }
    if (kind == 'warrior') {
      _paintWarrior(canvas, size, p, dark);
      canvas.restore();
      return;
    }

    p.color = color.withValues(alpha: 0.92);
    final body = Rect.fromCenter(
      center: Offset(cx, cy + h * .05),
      width: kind == 'slime' ? w * .70 : w * .58,
      height: kind == 'beast' ? h * .72 : h * .58,
    );
    if (kind == 'construct') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(body, Radius.circular(w * .08)),
        p,
      );
    } else if (kind == 'winged') {
      canvas.drawOval(body.inflate(w * .02), p);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - w * .32, cy),
          width: w * .34,
          height: h * .38,
        ),
        p,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + w * .32, cy),
          width: w * .34,
          height: h * .38,
        ),
        p,
      );
    } else {
      canvas.drawOval(body, p);
    }

    p.color = color.withValues(alpha: 0.65);
    if (kind == 'horned' || kind == 'beast') {
      final leftHorn = Path()
        ..moveTo(cx - w * .20, cy - h * .25)
        ..lineTo(cx - w * .34, cy - h * .42)
        ..lineTo(cx - w * .08, cy - h * .31)
        ..close();
      final rightHorn = Path()
        ..moveTo(cx + w * .20, cy - h * .25)
        ..lineTo(cx + w * .34, cy - h * .42)
        ..lineTo(cx + w * .08, cy - h * .31)
        ..close();
      canvas.drawPath(leftHorn, p);
      canvas.drawPath(rightHorn, p);
    }

    final humanHair = kind.startsWith('human_');
    if (kind == 'humanoid' || humanHair) {
      p.color = color.withValues(alpha: 0.82);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .25, h * .70, w * .18, h * .18),
          Radius.circular(w * .04),
        ),
        p,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .57, h * .70, w * .18, h * .18),
          Radius.circular(w * .04),
        ),
        p,
      );
    }

    if (humanHair) {
      final hair = Color.lerp(
        color,
        const Color(0xFF070812),
        .55,
      )!.withValues(alpha: .92);
      p.color = hair;
      final longHair =
          kind.contains('long') ||
          kind.contains('fem') ||
          kind.contains('female');
      final sharpHair = kind.contains('masc');
      if (longHair) {
        final back = Path()
          ..moveTo(cx - w * .24, cy - h * .24)
          ..quadraticBezierTo(cx, cy - h * .42, cx + w * .24, cy - h * .24)
          ..lineTo(cx + w * .30, cy + h * .20)
          ..quadraticBezierTo(cx, cy + h * .34, cx - w * .30, cy + h * .20)
          ..close();
        canvas.drawPath(back, p);
      } else {
        final cap = Path()
          ..moveTo(cx - w * .24, cy - h * .18)
          ..quadraticBezierTo(cx, cy - h * .40, cx + w * .24, cy - h * .18)
          ..lineTo(cx + w * .18, cy - h * .03)
          ..quadraticBezierTo(cx, cy - h * .13, cx - w * .18, cy - h * .03)
          ..close();
        canvas.drawPath(cap, p);
      }
      if (sharpHair) {
        for (var i = 0; i < 3; i++) {
          final x = cx - w * .18 + i * w * .18;
          final spike = Path()
            ..moveTo(x, cy - h * .17)
            ..lineTo(x + w * .07, cy - h * .32)
            ..lineTo(x + w * .13, cy - h * .15)
            ..close();
          canvas.drawPath(spike, p);
        }
      }
    }

    if (armorKind.isNotEmpty) {
      _paintEquippedArmor(canvas, size, p, dark);
    }

    if (weaponKind.isNotEmpty) {
      _paintHeldWeapon(canvas, size, p, dark);
    }

    if (layerCount >= 1) {
      p.color = Colors.white.withValues(alpha: 0.16);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy + h * .17),
            width: w * .16,
            height: h * .026,
          ),
          Radius.circular(w * .012),
        ),
        p,
      );
    }

    if (layerCount >= 2 && armorKind.isEmpty) {
      p.color = color.withValues(alpha: 0.38);
      final cloak = Path()
        ..moveTo(cx - w * .26, cy - h * .12)
        ..lineTo(cx + w * .26, cy - h * .12)
        ..lineTo(cx + w * .34, cy + h * .36)
        ..quadraticBezierTo(cx, cy + h * .48, cx - w * .34, cy + h * .36)
        ..close();
      canvas.drawPath(cloak, p);
    }

    if (layerCount >= 3) {
      p
        ..color = Colors.white.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .014;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy + h * .10),
            width: w * .44,
            height: h * .34,
          ),
          Radius.circular(w * .14),
        ),
        p,
      );
      p.style = PaintingStyle.fill;
    }

    if (layerCount >= 4) {
      p.color = Color.lerp(color, Colors.white, .42)!.withValues(alpha: .58);
      for (var i = 0; i < 3; i++) {
        final angle = pi * .12 + i * pi * .38;
        canvas.drawCircle(
          Offset(
            cx + cos(angle) * w * .30,
            cy + h * .12 + sin(angle) * h * .16,
          ),
          w * .028,
          p,
        );
      }
    }

    p.color = eyeColor;
    final eyeY = cy - h * .05;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx - w * .13, eyeY),
        width: w * .10,
        height: h * .08,
      ),
      p,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx + w * .13, eyeY),
        width: w * .10,
        height: h * .08,
      ),
      p,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, cy + h * .17),
        width: w * .20,
        height: h * .035,
      ),
      dark,
    );

    if (seed % 3 == 0) {
      p.color = Colors.white.withValues(alpha: 0.14);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy + h * .25),
            width: w * .14,
            height: h * .024,
          ),
          Radius.circular(w * .012),
        ),
        p,
      );
    }

    for (var i = 0; i < layerCount; i++) {
      p.color = Color.lerp(
        color,
        Colors.white,
        .25 + i * .08,
      )!.withValues(alpha: .46);
      final y = h * (.43 + i * .065);
      canvas.drawRect(
        Rect.fromLTWH(w * (.24 + i * .035), y, w * (.14 + i * .02), h * .024),
        p,
      );
      canvas.drawRect(
        Rect.fromLTWH(w * (.62 - i * .025), y + h * .045, w * .13, h * .024),
        p,
      );
    }
    canvas.restore();
  }

  void _paintWeapon(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final variant = _variant(5);
    p.color = color.withValues(alpha: .94);

    if (variant == 1) {
      p
        ..strokeWidth = w * .07
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w * .36, h * .74), Offset(w * .62, h * .16), p);
      p
        ..color = Colors.white.withValues(alpha: .34)
        ..strokeWidth = w * .025;
      canvas.drawLine(Offset(w * .47, h * .54), Offset(w * .68, h * .22), p);
      p.strokeCap = StrokeCap.butt;
    } else if (variant == 2) {
      p.style = PaintingStyle.stroke;
      p.strokeWidth = w * .055;
      canvas.drawCircle(Offset(w * .52, h * .43), w * .24, p);
      p.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(w * .52, h * .43), w * .07, p);
      canvas.drawRect(Rect.fromLTWH(w * .47, h * .63, w * .10, h * .20), p);
    } else if (variant == 3) {
      final axe = Path()
        ..moveTo(w * .50, h * .18)
        ..lineTo(w * .76, h * .32)
        ..quadraticBezierTo(w * .65, h * .49, w * .50, h * .45)
        ..quadraticBezierTo(w * .34, h * .48, w * .25, h * .32)
        ..close();
      canvas.drawPath(axe, p);
      dark.color = const Color(0xFF070812).withValues(alpha: .46);
      canvas.drawRect(Rect.fromLTWH(w * .47, h * .36, w * .08, h * .43), dark);
    } else if (variant == 4) {
      final wand = Path()
        ..moveTo(w * .35, h * .76)
        ..lineTo(w * .62, h * .16)
        ..lineTo(w * .69, h * .22)
        ..lineTo(w * .43, h * .80)
        ..close();
      canvas.drawPath(wand, p);
      p.color = Colors.white.withValues(alpha: .42);
      canvas.drawCircle(Offset(w * .65, h * .17), w * .07, p);
    } else {
      final blade = Path()
        ..moveTo(w * .58, h * .10)
        ..lineTo(w * .73, h * .22)
        ..lineTo(w * .42, h * .72)
        ..lineTo(w * .31, h * .64)
        ..close();
      canvas.drawPath(blade, p);
      p.color = Colors.white.withValues(alpha: .32);
      canvas.drawLine(
        Offset(w * .61, h * .19),
        Offset(w * .42, h * .58),
        p..strokeWidth = w * .035,
      );
    }

    dark.color = const Color(0xFF070812);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * .33, h * .72),
          width: w * .38,
          height: h * .10,
        ),
        Radius.circular(w * .03),
      ),
      dark,
    );
    p.color = color.withValues(alpha: .85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .20, h * .77, w * .20, h * .10),
        Radius.circular(w * .03),
      ),
      p,
    );
    _paintSeedMarks(
      canvas,
      size,
      p,
      color,
      seed,
      Rect.fromLTWH(w * .18, h * .12, w * .64, h * .72),
    );
  }

  void _paintHeldWeapon(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final c = weaponColor == Colors.white ? color : weaponColor;
    final equippedSeed = weaponSeed == 0 ? seed : weaponSeed;
    final variant = _variant(5, equippedSeed);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(w * .50, h * .16, w * .42, h * .62));

    if (weaponKind == 'gadget_weapon') {
      p.color = Color.lerp(c, Colors.white, .38)!.withValues(alpha: .94);
      final blade = Path()
        ..moveTo(w * .70, h * .24)
        ..lineTo(w * .84, h * .32)
        ..lineTo(w * .64, h * .58)
        ..lineTo(w * .56, h * .53)
        ..close();
      canvas.drawPath(blade, p);
      p.color = c.withValues(alpha: .78);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .54, h * .61, w * .20, h * .07),
          Radius.circular(w * .03),
        ),
        p,
      );
      dark.color = const Color(0xFF070812).withValues(alpha: .38);
      canvas.drawOval(Rect.fromLTWH(w * .58, h * .68, w * .28, h * .07), dark);
      _paintSeedMarks(
        canvas,
        size,
        p,
        c,
        equippedSeed,
        Rect.fromLTWH(w * .63, h * .31, w * .16, h * .25),
      );
      canvas.restore();
      return;
    }

    if (weaponKind == 'blade_shield') {
      p.color = Color.lerp(c, Colors.white, .32)!.withValues(alpha: .92);
      final blade = Path()
        ..moveTo(w * .72, h * .18)
        ..lineTo(w * .88, h * .30)
        ..lineTo(w * .70, h * .62)
        ..lineTo(w * .61, h * .57)
        ..close();
      canvas.drawPath(blade, p);
      p
        ..color = Colors.white.withValues(alpha: .35)
        ..strokeWidth = w * .018
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w * .74, h * .28), Offset(w * .66, h * .54), p);

      p.color = c.withValues(alpha: .88);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(w * .69, h * .61),
            width: w * .23,
            height: h * .20,
          ),
          Radius.circular(w * .05),
        ),
        p,
      );
      dark.color = const Color(0xFF070812).withValues(alpha: .55);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(w * .69, h * .60),
            width: w * .13,
            height: h * .035,
          ),
          Radius.circular(w * .015),
        ),
        dark,
      );
      _paintSeedMarks(
        canvas,
        size,
        p,
        c,
        equippedSeed,
        Rect.fromLTWH(w * .62, h * .46, w * .16, h * .20),
      );
      canvas.restore();
      return;
    }

    if (variant == 1) {
      p
        ..color = c.withValues(alpha: .82)
        ..strokeWidth = w * .045
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w * .70, h * .23), Offset(w * .82, h * .68), p);
      p
        ..color = Colors.white.withValues(alpha: .44)
        ..strokeWidth = w * .022;
      canvas.drawCircle(Offset(w * .70, h * .24), w * .045, p);
    } else if (variant == 2) {
      p
        ..color = c.withValues(alpha: .78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .032;
      canvas.drawCircle(Offset(w * .75, h * .43), w * .12, p);
      p.style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .64, h * .58, w * .18, h * .06),
          Radius.circular(w * .03),
        ),
        p,
      );
    } else if (variant == 3) {
      p.color = Color.lerp(c, Colors.white, .24)!.withValues(alpha: .90);
      final axe = Path()
        ..moveTo(w * .72, h * .24)
        ..lineTo(w * .88, h * .34)
        ..quadraticBezierTo(w * .81, h * .46, w * .70, h * .40)
        ..close();
      canvas.drawPath(axe, p);
      p
        ..color = c.withValues(alpha: .74)
        ..strokeWidth = w * .035
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w * .68, h * .37), Offset(w * .80, h * .69), p);
    } else {
      p
        ..color = Color.lerp(c, Colors.white, .28)!.withValues(alpha: .88)
        ..strokeWidth = w * .035
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w * .72, h * .24), Offset(w * .82, h * .69), p);
      p
        ..color = c.withValues(alpha: .82)
        ..strokeWidth = w * .050;
      canvas.drawLine(Offset(w * .60, h * .61), Offset(w * .73, h * .68), p);
    }
    p.strokeCap = StrokeCap.butt;
    p.style = PaintingStyle.fill;
    _paintSeedMarks(
      canvas,
      size,
      p,
      c,
      equippedSeed,
      Rect.fromLTWH(w * .68, h * .28, w * .15, h * .34),
    );
    canvas.restore();
  }

  void _paintEquippedArmor(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final armor = armorColor == Colors.transparent ? color : armorColor;
    final id = armorKind.toLowerCase();
    final equippedSeed = armorSeed == 0 ? seed : armorSeed;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(w * .18, h * .38, w * .64, h * .38));

    if (id.contains('bone') || id.contains('button')) {
      p.color = Color.lerp(armor, Colors.white, .32)!.withValues(alpha: .86);
      final chest = Path()
        ..moveTo(cx - w * .23, cy - h * .10)
        ..lineTo(cx + w * .23, cy - h * .10)
        ..lineTo(cx + w * .18, cy + h * .28)
        ..lineTo(cx - w * .18, cy + h * .28)
        ..close();
      canvas.drawPath(chest, p);
      dark.color = const Color(0xFF070812).withValues(alpha: .40);
      for (var i = 0; i < 3; i++) {
        canvas.drawRect(
          Rect.fromLTWH(w * .39, h * (.48 + i * .07), w * .22, h * .025),
          dark,
        );
      }
      _paintSeedMarks(
        canvas,
        size,
        p,
        armor,
        equippedSeed,
        Rect.fromLTWH(w * .36, h * .48, w * .28, h * .18),
      );
      canvas.restore();
      return;
    }

    if (id.contains('oculian') || id.contains('oculum')) {
      p.color = Color.lerp(
        armor,
        const Color(0xFFE8DEC7),
        .20,
      )!.withValues(alpha: .88);
      final plate = Path()
        ..moveTo(cx - w * .24, cy - h * .16)
        ..quadraticBezierTo(cx, cy - h * .24, cx + w * .24, cy - h * .16)
        ..lineTo(cx + w * .20, cy + h * .28)
        ..quadraticBezierTo(cx, cy + h * .38, cx - w * .20, cy + h * .28)
        ..close();
      canvas.drawPath(plate, p);
      dark.color = const Color(0xFF070812).withValues(alpha: .46);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy + h * .02),
          width: w * .18,
          height: h * .095,
        ),
        dark,
      );
      p.color = Colors.white.withValues(alpha: .70);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy + h * .02),
          width: w * .13,
          height: h * .06,
        ),
        p,
      );
      p.color = armor.withValues(alpha: .74);
      for (var i = 0; i < 3; i++) {
        canvas.drawRect(
          Rect.fromLTWH(w * (.34 + i * .11), h * .57, w * .08, h * .025),
          p,
        );
      }
      _paintSeedMarks(
        canvas,
        size,
        p,
        armor,
        equippedSeed,
        Rect.fromLTWH(w * .34, h * .48, w * .32, h * .20),
      );
      canvas.restore();
      return;
    }

    if (id.contains('hidenas') || id.contains('hidean')) {
      p.color = armor.withValues(alpha: .88);
      final coat = Path()
        ..moveTo(cx - w * .26, cy - h * .18)
        ..lineTo(cx + w * .26, cy - h * .18)
        ..lineTo(cx + w * .34, cy + h * .34)
        ..quadraticBezierTo(cx, cy + h * .45, cx - w * .34, cy + h * .34)
        ..close();
      canvas.drawPath(coat, p);
      p
        ..color = const Color(0xFFFFD36A).withValues(alpha: .72)
        ..strokeWidth = w * .018;
      canvas.drawLine(Offset(cx, cy - h * .13), Offset(cx, cy + h * .32), p);
      canvas.drawLine(
        Offset(cx - w * .20, cy - h * .03),
        Offset(cx + w * .20, cy - h * .03),
        p,
      );
      _paintSeedMarks(
        canvas,
        size,
        p,
        armor,
        equippedSeed,
        Rect.fromLTWH(w * .32, h * .50, w * .36, h * .20),
      );
      canvas.restore();
      return;
    }

    p.color = armor.withValues(alpha: .56);
    final robe = Path()
      ..moveTo(cx - w * .28, cy - h * .14)
      ..lineTo(cx + w * .28, cy - h * .14)
      ..lineTo(cx + w * .32, cy + h * .36)
      ..quadraticBezierTo(cx, cy + h * .48, cx - w * .32, cy + h * .36)
      ..close();
    canvas.drawPath(robe, p);
    p
      ..color = Colors.white.withValues(alpha: .24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .016;
    canvas.drawPath(robe, p);
    p.style = PaintingStyle.fill;
    _paintSeedMarks(
      canvas,
      size,
      p,
      armor,
      equippedSeed,
      Rect.fromLTWH(w * .32, h * .50, w * .36, h * .22),
    );
    canvas.restore();
  }

  void _paintHideanGadget(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    p.color = color.withValues(alpha: .92);
    final handle = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .26, h * .68, w * .26, h * .10),
      Radius.circular(w * .04),
    );
    canvas.drawRRect(handle, p);

    p.color = Color.lerp(color, Colors.white, .36)!.withValues(alpha: .92);
    final blade = Path()
      ..moveTo(w * .40, h * .63)
      ..lineTo(w * .62, h * .16)
      ..lineTo(w * .75, h * .27)
      ..lineTo(w * .52, h * .66)
      ..close();
    canvas.drawPath(blade, p);

    p
      ..color = Colors.white.withValues(alpha: .30)
      ..strokeWidth = w * .035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * .61, h * .25), Offset(w * .48, h * .57), p);

    dark.color = const Color(0xFF070812).withValues(alpha: .72);
    canvas.drawOval(Rect.fromLTWH(w * .32, h * .70, w * .54, h * .13), dark);
  }

  void _paintPawn(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final cx = w * .5;
    final baseY = h * .76;

    p.color = color.withValues(alpha: .24);
    canvas.drawOval(Rect.fromLTWH(w * .20, h * .76, w * .60, h * .14), p);

    p.color = color.withValues(alpha: .72);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * .33),
        width: w * .46,
        height: h * .32,
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .29, h * .38, w * .42, h * .34),
        Radius.circular(w * .17),
      ),
      p,
    );

    p.color = Color.lerp(color, Colors.black, .28)!.withValues(alpha: .78);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY),
        width: w * .56,
        height: h * .15,
      ),
      p,
    );

    p.color = eyeColor;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * .36),
        width: w * .36,
        height: h * .18,
      ),
      p,
    );
    dark.color = const Color(0xFF070812);
    canvas.drawCircle(Offset(cx + w * .04, h * .36), w * .075, dark);
    p.color = Colors.white.withValues(alpha: .76);
    canvas.drawCircle(Offset(cx + w * .08, h * .32), w * .025, p);
  }

  void _paintArmor(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final variant = _variant(4);
    p.color = color.withValues(alpha: .9);

    final chest = Path();
    if (variant == 1) {
      chest
        ..moveTo(w * .24, h * .24)
        ..lineTo(w * .76, h * .18)
        ..lineTo(w * .70, h * .80)
        ..lineTo(w * .30, h * .86)
        ..close();
    } else if (variant == 2) {
      chest
        ..moveTo(w * .34, h * .18)
        ..lineTo(w * .66, h * .18)
        ..lineTo(w * .78, h * .50)
        ..lineTo(w * .62, h * .84)
        ..lineTo(w * .38, h * .84)
        ..lineTo(w * .22, h * .50)
        ..close();
    } else if (variant == 3) {
      chest
        ..moveTo(w * .24, h * .20)
        ..quadraticBezierTo(w * .50, h * .10, w * .76, h * .20)
        ..lineTo(w * .66, h * .82)
        ..quadraticBezierTo(w * .50, h * .90, w * .34, h * .82)
        ..close();
    } else {
      chest
        ..moveTo(w * .28, h * .20)
        ..lineTo(w * .72, h * .20)
        ..lineTo(w * .64, h * .82)
        ..lineTo(w * .36, h * .82)
        ..close();
    }
    canvas.drawPath(chest, p);
    dark.color = const Color(0xFF070812).withValues(alpha: .7);
    canvas.drawRect(Rect.fromLTWH(w * .35, h * .32, w * .30, h * .07), dark);
    p.color = Colors.white.withValues(alpha: .28);
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(w * .34, h * (.48 + i * .10), w * .32, h * .035),
        p,
      );
    }
    _paintSeedMarks(
      canvas,
      size,
      p,
      color,
      seed,
      Rect.fromLTWH(w * .31, h * .30, w * .38, h * .45),
    );
  }

  void _paintRelic(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * .5, h * .52);
    final variant = _variant(4);
    p.color = color.withValues(alpha: .25);
    if (variant == 1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: w * .54, height: h * .54),
          Radius.circular(w * .10),
        ),
        p,
      );
    } else if (variant == 2) {
      final diamond = Path()
        ..moveTo(center.dx, h * .16)
        ..lineTo(w * .80, center.dy)
        ..lineTo(center.dx, h * .88)
        ..lineTo(w * .20, center.dy)
        ..close();
      canvas.drawPath(diamond, p);
    } else {
      canvas.drawCircle(center, w * .30, p);
    }
    p.color = color.withValues(alpha: .86);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w * .58, height: h * .34),
      p,
    );
    dark.color = const Color(0xFF070812);
    canvas.drawCircle(center, w * .12, dark);
    p.color = Colors.white.withValues(alpha: .72);
    canvas.drawCircle(
      Offset(center.dx + w * .06, center.dy - h * .06),
      w * .04,
      p,
    );
    for (var i = 0; i < 3 + seed % 4; i++) {
      final angle = i * 2 * pi / (3 + seed % 4) + seed * .03;
      p.color = color.withValues(alpha: .42);
      canvas.drawCircle(
        Offset(
          center.dx + cos(angle) * w * .34,
          center.dy + sin(angle) * h * .24,
        ),
        w * (.018 + _unit(i + 4) * .018),
        p,
      );
    }
  }

  void _paintArt(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * .5, h * .5);
    final spokeCount = 4 + seed % 7;
    final innerRing = .14 + _unit(2) * .08;
    p
      ..color = color.withValues(alpha: .88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .035;
    canvas.drawCircle(center, w * .30, p);
    canvas.drawCircle(center, w * innerRing, p);
    if (seed.isEven) {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: w * .48, height: h * .22),
        p,
      );
    }
    for (var i = 0; i < spokeCount; i++) {
      final angle = i * 2 * pi / spokeCount + seed * .01;
      canvas.drawLine(
        center,
        Offset(
          center.dx + cos(angle) * w * .34,
          center.dy + sin(angle) * w * .34,
        ),
        p,
      );
    }
    p.style = PaintingStyle.fill;
    dark.color = const Color(0xFF070812);
    canvas.drawCircle(center, w * .08, dark);
    p.color = Color.lerp(color, Colors.white, .45)!.withValues(alpha: .70);
    canvas.drawCircle(
      Offset(
        center.dx + (_unit(7) - .5) * w * .18,
        center.dy + (_unit(8) - .5) * h * .16,
      ),
      w * .025,
      p,
    );
  }

  void _paintDrop(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final variant = _variant(4);
    p.color = color.withValues(alpha: .88);
    final gem = Path();
    if (variant == 1) {
      gem
        ..moveTo(w * .50, h * .10)
        ..lineTo(w * .80, h * .48)
        ..lineTo(w * .50, h * .86)
        ..lineTo(w * .20, h * .48)
        ..close();
    } else if (variant == 2) {
      gem
        ..moveTo(w * .36, h * .14)
        ..lineTo(w * .70, h * .18)
        ..lineTo(w * .80, h * .54)
        ..lineTo(w * .58, h * .84)
        ..lineTo(w * .22, h * .70)
        ..lineTo(w * .18, h * .34)
        ..close();
    } else if (variant == 3) {
      gem
        ..moveTo(w * .50, h * .10)
        ..lineTo(w * .72, h * .28)
        ..lineTo(w * .78, h * .62)
        ..lineTo(w * .50, h * .86)
        ..lineTo(w * .22, h * .62)
        ..lineTo(w * .28, h * .28)
        ..close();
    } else {
      gem
        ..moveTo(w * .50, h * .12)
        ..lineTo(w * .76, h * .36)
        ..lineTo(w * .62, h * .84)
        ..lineTo(w * .28, h * .74)
        ..lineTo(w * .22, h * .32)
        ..close();
    }
    canvas.drawPath(gem, p);
    p.color = Colors.white.withValues(alpha: .30);
    canvas.drawRect(Rect.fromLTWH(w * .40, h * .30, w * .18, h * .05), p);
    dark.color = const Color(0xFF070812).withValues(alpha: .36);
    canvas.drawLine(Offset(w * .50, h * .14), Offset(w * .50, h * .82), dark);
    _paintSeedMarks(
      canvas,
      size,
      p,
      color,
      seed,
      Rect.fromLTWH(w * .28, h * .28, w * .44, h * .45),
    );
  }

  void _paintEye(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * .5, h * .5);
    p.color = color.withValues(alpha: .90);
    final eye = Path()
      ..moveTo(w * .12, center.dy)
      ..quadraticBezierTo(w * .5, h * .18, w * .88, center.dy)
      ..quadraticBezierTo(w * .5, h * .82, w * .12, center.dy)
      ..close();
    canvas.drawPath(eye, p);
    dark.color = const Color(0xFF070812);
    canvas.drawCircle(center, w * .16, dark);
    p.color = Colors.white.withValues(alpha: .75);
    canvas.drawCircle(
      Offset(center.dx + w * .06, center.dy - h * .07),
      w * .04,
      p,
    );
  }

  void _paintDottedEye(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * .5, h * .48);
    final eyePath = Path()
      ..moveTo(w * .13, center.dy)
      ..quadraticBezierTo(w * .5, h * .17, w * .87, center.dy)
      ..quadraticBezierTo(w * .5, h * .80, w * .13, center.dy)
      ..close();

    p.color = const Color(0xFFEDEDED).withValues(alpha: .90);
    canvas.drawPath(eyePath, p);
    dark.color = const Color(0xFF050505);
    canvas.drawPath(eyePath, dark..style = PaintingStyle.stroke);
    dark.style = PaintingStyle.fill;

    p.color = const Color(0xFF050505);
    canvas.drawCircle(center, w * .17, p);
    p.color = const Color(0xFFEDEDED);
    canvas.drawCircle(
      Offset(center.dx + w * .06, center.dy - h * .07),
      w * .04,
      p,
    );

    final dotPaint = Paint()..isAntiAlias = false;
    for (var i = 0; i < 82; i++) {
      final x = w * (.08 + _unit(i + 41) * .84);
      final y = h * (.12 + _unit(i + 93) * .74);
      final dx = (x - center.dx).abs() / (w * .43);
      final dy = (y - center.dy).abs() / (h * .34);
      if (dx + dy > 1.15 && i.isEven) continue;
      final sizePx = w * (.012 + _unit(i + 7) * .018);
      dotPaint.color = i % 5 == 0
          ? Colors.white.withValues(alpha: .55)
          : Colors.black.withValues(alpha: .72);
      canvas.drawRect(Rect.fromLTWH(x, y, sizePx, sizePx), dotPaint);
    }

    for (var i = 0; i < 9; i++) {
      final x = w * (.22 + i * .07 + _unit(i + 19) * .03);
      final top = h * (.66 + _unit(i + 3) * .04);
      final bottom = h * (.82 + _unit(i + 5) * .13);
      p
        ..color = Colors.black.withValues(alpha: .78)
        ..strokeWidth = max(1.0, w * .018)
        ..strokeCap = StrokeCap.square;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), p);
      canvas.drawCircle(Offset(x, bottom), w * .022, p);
    }
  }

  void _paintCultist(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final cx = w * .5;
    p.color = color.withValues(alpha: .88);
    final robe = Path()
      ..moveTo(cx, h * .16)
      ..lineTo(w * .74, h * .78)
      ..lineTo(w * .26, h * .78)
      ..close();
    canvas.drawPath(robe, p);
    dark.color = const Color(0xFF070812).withValues(alpha: .65);
    canvas.drawCircle(Offset(cx, h * .41), w * .18, dark);
    p.color = eyeColor.withValues(alpha: .95);
    canvas.drawCircle(Offset(cx, h * .41), w * .07, p);
    dark.color = const Color(0xFF050505);
    canvas.drawCircle(Offset(cx, h * .41), w * .032, dark);
    _paintSeedMarks(
      canvas,
      size,
      p,
      color,
      seed,
      Rect.fromLTWH(w * .30, h * .52, w * .40, h * .18),
    );
  }

  void _paintValley(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final cx = w * .5;
    final cy = h * .5;
    const leaf = Color(0xFF55B86B);
    const deepLeaf = Color(0xFF173F2A);
    const flower = Color(0xFFB86B8F);
    const flesh = Color(0xFF8D5A54);

    p.color = deepLeaf.withValues(alpha: .72);
    final hair = Path()
      ..moveTo(cx - w * .22, cy - h * .30)
      ..quadraticBezierTo(cx, cy - h * .48, cx + w * .22, cy - h * .30)
      ..lineTo(cx + w * .30, cy + h * .18)
      ..quadraticBezierTo(cx, cy + h * .32, cx - w * .30, cy + h * .18)
      ..close();
    canvas.drawPath(hair, p);

    p.color = leaf.withValues(alpha: .95);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - h * .05),
        width: w * .42,
        height: h * .55,
      ),
      p,
    );

    p.color = const Color(0xFF7AD66E);
    for (var i = 0; i < 7; i++) {
      final angle = -pi * .88 + i * pi * .29;
      final start = Offset(cx + cos(angle) * w * .18, cy - h * .30);
      final tip = Offset(cx + cos(angle) * w * .28, cy - h * .43);
      final side = Offset(cx + cos(angle + .26) * w * .20, cy - h * .34);
      final leafPath = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(tip.dx, tip.dy, side.dx, side.dy)
        ..quadraticBezierTo(start.dx, start.dy, start.dx, start.dy);
      canvas.drawPath(leafPath, p);
    }

    p.color = const Color(0xFF224F32);
    final skirt = Path()
      ..moveTo(cx - w * .25, cy + h * .14)
      ..lineTo(cx + w * .25, cy + h * .14)
      ..lineTo(cx + w * .31, cy + h * .45)
      ..lineTo(cx + w * .10, cy + h * .34)
      ..lineTo(cx, cy + h * .48)
      ..lineTo(cx - w * .10, cy + h * .34)
      ..lineTo(cx - w * .31, cy + h * .45)
      ..close();
    canvas.drawPath(skirt, p);

    p.color = Colors.white.withValues(alpha: .82);
    canvas.drawRect(
      Rect.fromLTWH(cx - w * .12, cy - h * .12, w * .07, h * .035),
      p,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx + w * .05, cy - h * .12, w * .07, h * .035),
      p,
    );
    dark.color = const Color(0xFF050505);
    canvas.drawRect(
      Rect.fromLTWH(cx - w * .07, cy + h * .04, w * .14, h * .025),
      dark,
    );

    for (var i = 0; i < 3; i++) {
      final x = cx - w * .36 + i * w * .36;
      p.color = flesh.withValues(alpha: .62);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, cy + h * .36),
          width: w * .18,
          height: h * .24,
        ),
        p,
      );
      p
        ..color = deepLeaf.withValues(alpha: .86)
        ..strokeWidth = max(1, w * .018);
      canvas.drawLine(
        Offset(x, cy + h * .25),
        Offset(x + w * .05, cy + h * .06),
        p,
      );
      p.color = flower.withValues(alpha: .82);
      canvas.drawCircle(Offset(x + w * .03, cy + h * .32), w * .035, p);
      p.color = leaf.withValues(alpha: .8);
      canvas.drawCircle(Offset(x - w * .05, cy + h * .23), w * .025, p);
    }

    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, w * .018)
      ..color = const Color(0xFF9EF0A1).withValues(alpha: .42);
    canvas.drawCircle(Offset(cx, cy + h * .02), w * .30, p);
    p.style = PaintingStyle.fill;
  }

  void _paintVitalium(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final cx = w * .5;
    final cy = h * .50;
    const stone = Color(0xFF47D16E);
    const deep = Color(0xFF123E28);
    const glow = Color(0xFFB8FFD0);

    p.color = stone.withValues(alpha: .92);
    final gem = Path()
      ..moveTo(cx, h * .12)
      ..lineTo(w * .78, h * .32)
      ..lineTo(w * .72, h * .72)
      ..lineTo(cx, h * .90)
      ..lineTo(w * .24, h * .72)
      ..lineTo(w * .18, h * .32)
      ..close();
    canvas.drawPath(gem, p);

    p.color = glow.withValues(alpha: .35);
    canvas.drawPath(
      Path()
        ..moveTo(cx, h * .12)
        ..lineTo(w * .78, h * .32)
        ..lineTo(cx, h * .42)
        ..lineTo(w * .18, h * .32)
        ..close(),
      p,
    );

    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, w * .018)
      ..color = deep.withValues(alpha: .75);
    canvas.drawLine(Offset(cx, h * .16), Offset(cx, h * .86), p);
    canvas.drawLine(Offset(w * .22, h * .34), Offset(w * .70, h * .72), p);
    canvas.drawLine(Offset(w * .76, h * .34), Offset(w * .30, h * .72), p);
    p.style = PaintingStyle.fill;

    dark.color = const Color(0xFF05140D);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: w * .30, height: h * .16),
      dark,
    );
    p.color = glow.withValues(alpha: .9);
    canvas.drawCircle(Offset(cx + w * .05, cy - h * .03), w * .025, p);
  }

  void _paintSlimeHelmeted(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final cx = w * .5;
    p.color = color.withValues(alpha: .88);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .18, h * .35, w * .64, h * .44),
        Radius.circular(w * .20),
      ),
      p,
    );
    p.color = const Color(0xFF9AA1AE).withValues(alpha: .86);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, h * .37),
        width: w * .54,
        height: h * .34,
      ),
      pi,
      pi,
      false,
      p,
    );
    dark.color = const Color(0xFF07101A);
    canvas.drawRect(Rect.fromLTWH(w * .28, h * .37, w * .44, h * .06), dark);
    p.color = Colors.white.withValues(alpha: .85);
    canvas.drawRect(Rect.fromLTWH(w * .34, h * .50, w * .08, h * .05), p);
    canvas.drawRect(Rect.fromLTWH(w * .58, h * .50, w * .08, h * .05), p);
    dark.color = const Color(0xFF050505);
    canvas.drawRect(Rect.fromLTWH(w * .42, h * .66, w * .16, h * .025), dark);
  }

  void _paintPatalpa(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final cx = w * .5;
    p.color = const Color(0xFF8E5B35).withValues(alpha: .9);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * .55),
        width: w * .62,
        height: h * .46,
      ),
      p,
    );
    p.color = const Color(0xFF55B86B).withValues(alpha: .9);
    final sprout = Path()
      ..moveTo(cx, h * .34)
      ..quadraticBezierTo(w * .36, h * .20, w * .26, h * .30)
      ..quadraticBezierTo(cx, h * .28, cx, h * .39)
      ..quadraticBezierTo(w * .64, h * .20, w * .76, h * .31)
      ..quadraticBezierTo(cx, h * .31, cx, h * .39);
    canvas.drawPath(sprout, p);
    p.color = Colors.white.withValues(alpha: .78);
    canvas.drawRect(Rect.fromLTWH(w * .35, h * .51, w * .08, h * .05), p);
    canvas.drawRect(Rect.fromLTWH(w * .58, h * .51, w * .08, h * .05), p);
    dark.color = const Color(0xFF050505);
    canvas.drawRect(Rect.fromLTWH(w * .43, h * .66, w * .16, h * .03), dark);
    _paintSeedMarks(
      canvas,
      size,
      p,
      const Color(0xFFC49A5A),
      seed,
      Rect.fromLTWH(w * .26, h * .43, w * .48, h * .28),
    );
  }

  void _paintMimic(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final cx = w * .5;
    p.color = const Color(0xFF181124).withValues(alpha: .94);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .18, h * .34, w * .64, h * .38),
        Radius.circular(w * .08),
      ),
      p,
    );
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, w * .02)
      ..color = color.withValues(alpha: .72);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .18, h * .34, w * .64, h * .38),
        Radius.circular(w * .08),
      ),
      p,
    );
    p.style = PaintingStyle.fill;
    p.color = eyeColor.withValues(alpha: .92);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * .48),
        width: w * .32,
        height: h * .17,
      ),
      p,
    );
    dark.color = const Color(0xFF050505);
    canvas.drawCircle(Offset(cx + w * .03, h * .48), w * .055, dark);
    p.color = const Color(0xFFC5283D).withValues(alpha: .74);
    canvas.drawRect(Rect.fromLTWH(w * .28, h * .63, w * .44, h * .035), p);
  }

  void _paintNightmare(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final cx = w * .5;
    p.color = const Color(0xFF21173B).withValues(alpha: .94);
    final body = Path()
      ..moveTo(w * .22, h * .66)
      ..quadraticBezierTo(cx, h * .12, w * .78, h * .66)
      ..quadraticBezierTo(cx, h * .82, w * .22, h * .66)
      ..close();
    canvas.drawPath(body, p);
    p.color = const Color(0xFFD7B9FF).withValues(alpha: .70);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, h * .42),
        width: w * .38,
        height: h * .34,
      ),
      -pi * .15,
      pi * 1.25,
      false,
      p..style = PaintingStyle.stroke,
    );
    p.style = PaintingStyle.fill;
    p.color = Colors.white.withValues(alpha: .84);
    canvas.drawRect(Rect.fromLTWH(w * .36, h * .50, w * .08, h * .045), p);
    canvas.drawRect(Rect.fromLTWH(w * .57, h * .50, w * .08, h * .045), p);
    dark.color = const Color(0xFF050505);
    canvas.drawRect(Rect.fromLTWH(w * .42, h * .64, w * .18, h * .03), dark);
  }

  void _paintRockRhino(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    p.color = const Color(0xFF777066).withValues(alpha: .92);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .20, h * .42, w * .56, h * .30),
        Radius.circular(w * .08),
      ),
      p,
    );
    final horn = Path()
      ..moveTo(w * .74, h * .49)
      ..lineTo(w * .92, h * .42)
      ..lineTo(w * .78, h * .57)
      ..close();
    canvas.drawPath(horn, p);
    p.color = const Color(0xFF3E3A35).withValues(alpha: .82);
    canvas.drawRect(Rect.fromLTWH(w * .28, h * .68, w * .08, h * .14), p);
    canvas.drawRect(Rect.fromLTWH(w * .58, h * .68, w * .08, h * .14), p);
    dark.color = const Color(0xFF050505);
    canvas.drawCircle(Offset(w * .64, h * .50), w * .025, dark);
    _paintSeedMarks(
      canvas,
      size,
      p,
      const Color(0xFFC49A5A),
      seed,
      Rect.fromLTWH(w * .24, h * .44, w * .45, h * .20),
    );
  }

  void _paintMerchant(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final cx = w * .5;
    p.color = const Color(0xFF2D2430).withValues(alpha: .92);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * .42),
        width: w * .44,
        height: h * .34,
      ),
      p,
    );
    final cloak = Path()
      ..moveTo(w * .26, h * .48)
      ..lineTo(w * .74, h * .48)
      ..lineTo(w * .82, h * .82)
      ..lineTo(w * .18, h * .82)
      ..close();
    canvas.drawPath(cloak, p);
    p.color = const Color(0xFFFFD36A).withValues(alpha: .9);
    canvas.drawCircle(Offset(w * .72, h * .62), w * .075, p);
    dark.color = const Color(0xFF050505);
    canvas.drawRect(Rect.fromLTWH(w * .39, h * .42, w * .22, h * .035), dark);
    p.color = Colors.white.withValues(alpha: .65);
    canvas.drawCircle(Offset(w * .75, h * .60), w * .022, p);
  }

  void _paintAlchemist(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final cx = w * .5;
    p.color = const Color(0xFF26343A).withValues(alpha: .92);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .26, h * .24, w * .48, h * .58),
        Radius.circular(w * .12),
      ),
      p,
    );
    p.color = const Color(0xFF55B86B).withValues(alpha: .86);
    canvas.drawCircle(Offset(w * .70, h * .64), w * .085, p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, w * .018)
      ..color = const Color(0xFFEDE9FE).withValues(alpha: .62);
    canvas.drawLine(Offset(w * .67, h * .52), Offset(w * .74, h * .64), p);
    p.style = PaintingStyle.fill;
    p.color = Colors.white.withValues(alpha: .78);
    canvas.drawRect(Rect.fromLTWH(cx - w * .10, h * .39, w * .07, h * .04), p);
    canvas.drawRect(Rect.fromLTWH(cx + w * .03, h * .39, w * .07, h * .04), p);
    dark.color = const Color(0xFF050505);
    canvas.drawRect(
      Rect.fromLTWH(cx - w * .07, h * .54, w * .14, h * .025),
      dark,
    );
  }

  void _paintWarrior(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final cx = w * .5;
    p.color = color.withValues(alpha: .88);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * .34),
        width: w * .38,
        height: h * .30,
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .29, h * .46, w * .42, h * .34),
        Radius.circular(w * .08),
      ),
      p,
    );
    p.color = const Color(0xFF9AA1AE).withValues(alpha: .88);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .18, h * .50, w * .20, h * .24),
        Radius.circular(w * .05),
      ),
      p,
    );
    p
      ..strokeWidth = max(1, w * .028)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * .76, h * .28), Offset(w * .64, h * .73), p);
    p.strokeCap = StrokeCap.butt;
    p.color = Colors.white.withValues(alpha: .82);
    canvas.drawRect(Rect.fromLTWH(w * .37, h * .34, w * .08, h * .04), p);
    canvas.drawRect(Rect.fromLTWH(w * .56, h * .34, w * .08, h * .04), p);
    dark.color = const Color(0xFF050505);
    canvas.drawRect(Rect.fromLTWH(w * .43, h * .43, w * .14, h * .025), dark);
  }

  void _paintLegendaryEyeKnight(Canvas canvas, Size size, Paint p, Paint dark) {
    final w = size.width;
    final h = size.height;
    final cx = w * .5;
    p.color = color.withValues(alpha: .88);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, h * .56),
          width: w * .52,
          height: h * .52,
        ),
        Radius.circular(w * .10),
      ),
      p,
    );
    dark.color = const Color(0xFF070812).withValues(alpha: .82);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * .38),
        width: w * .43,
        height: h * .24,
      ),
      dark,
    );
    p.color = eyeColor;
    canvas.drawCircle(Offset(cx, h * .38), w * .08, p);
    dark.color = const Color(0xFF050505);
    canvas.drawCircle(Offset(cx, h * .38), w * .035, dark);
    p.color = color.withValues(alpha: .75);
    canvas.drawPath(
      Path()
        ..moveTo(cx, h * .08)
        ..lineTo(w * .60, h * .24)
        ..lineTo(w * .40, h * .24)
        ..close(),
      p,
    );
    _paintHeldWeapon(canvas, size, p, dark);
  }

  void _paintSeedMarks(
    Canvas canvas,
    Size size,
    Paint p,
    Color baseColor,
    int baseSeed,
    Rect bounds,
  ) {
    final count = 2 + baseSeed.abs() % 4;
    for (var i = 0; i < count; i++) {
      final local = ((baseSeed + i * 97) * 1103515245 + 12345) & 0x7fffffff;
      final x = bounds.left + (local % 1000) / 1000 * bounds.width;
      final y = bounds.top + ((local ~/ 1000) % 1000) / 1000 * bounds.height;
      final markVariant = (local ~/ 1000000) % 3;
      p
        ..color = Color.lerp(
          baseColor,
          Colors.white,
          .52,
        )!.withValues(alpha: .42)
        ..style = PaintingStyle.fill;
      if (markVariant == 0) {
        canvas.drawCircle(Offset(x, y), size.width * .018, p);
      } else if (markVariant == 1) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: size.width * .045,
            height: size.height * .015,
          ),
          p,
        );
      } else {
        final tri = Path()
          ..moveTo(x, y - size.height * .018)
          ..lineTo(x + size.width * .018, y + size.height * .016)
          ..lineTo(x - size.width * .018, y + size.height * .016)
          ..close();
        canvas.drawPath(tri, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OculumSpritePainter oldDelegate) {
    return color != oldDelegate.color ||
        seed != oldDelegate.seed ||
        kind != oldDelegate.kind ||
        eyeColor != oldDelegate.eyeColor ||
        layers != oldDelegate.layers ||
        weaponKind != oldDelegate.weaponKind ||
        weaponColor != oldDelegate.weaponColor ||
        weaponSeed != oldDelegate.weaponSeed ||
        armorKind != oldDelegate.armorKind ||
        armorColor != oldDelegate.armorColor ||
        armorSeed != oldDelegate.armorSeed;
  }
}

// ignore: unused_element
class _OculumFightBackdropPainter extends CustomPainter {
  const _OculumFightBackdropPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF10111F),
          Color.lerp(const Color(0xFF090A13), color, 0.08)!,
          const Color(0xFF05060C),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final floorY = size.height * .72;
    final floorPaint = Paint()
      ..color = color.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < 7; i++) {
      final y = floorY + i * size.height * .045;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), floorPaint);
    }

    final spotlight = Paint()
      ..shader =
          RadialGradient(
            colors: [color.withValues(alpha: .20), Colors.transparent],
          ).createShader(
            Rect.fromCenter(
              center: Offset(size.width * .50, size.height * .58),
              width: size.width * .9,
              height: size.height * .55,
            ),
          );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .50, size.height * .76),
        width: size.width * .88,
        height: size.height * .24,
      ),
      spotlight,
    );

    final lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: .045)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * .50, size.height * .12),
      Offset(size.width * .50, size.height * .94),
      lanePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OculumFightBackdropPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
