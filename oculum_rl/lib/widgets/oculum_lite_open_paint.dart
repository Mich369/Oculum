part of 'oculum_lite_arena.dart';

enum _OpenGlyph {
  trail,
  echo,
  spring,
  portal,
  spark,
  ward,
  claw,
  feather,
  fire,
  fissure,
  ring,
  jaw,
  card,
}

(Color, _OpenGlyph, int) _openInk(LiteHero hero) => switch (hero) {
  LiteHero.evasore => (const Color(0xffd9c4ff), _OpenGlyph.trail, 5),
  LiteHero.duplicatore => (const Color(0xffcbb3ed), _OpenGlyph.echo, 3),
  LiteHero.ashley => (const Color(0xffffc07c), _OpenGlyph.spring, 7),
  LiteHero.scostubandito => (const Color(0xffd7a466), _OpenGlyph.portal, 1),
  LiteHero.granScostumato => (const Color(0xffefbd79), _OpenGlyph.portal, 2),
  LiteHero.dronePostea => (const Color(0xff7ee5d9), _OpenGlyph.spark, 8),
  LiteHero.sentinella => (const Color(0xffd2c5a2), _OpenGlyph.ward, 4),
  LiteHero.babyForestDemon => (const Color(0xffbad076), _OpenGlyph.claw, 4),
  LiteHero.curatorePeste => (const Color(0xffcfb6ec), _OpenGlyph.feather, 11),
  LiteHero.pyrel => (const Color(0xffff9b62), _OpenGlyph.fire, 3),
  LiteHero.lithra => (const Color(0xffedb68a), _OpenGlyph.fissure, 3),
  LiteHero.luce => (const Color(0xffffe4a0), _OpenGlyph.ward, 9),
  LiteHero.ombra => (const Color(0xffbda1e7), _OpenGlyph.trail, 9),
  LiteHero.veyrth => (const Color(0xffbcd5ff), _OpenGlyph.ring, 9),
  LiteHero.doppelganger => (const Color(0xffd8b2e4), _OpenGlyph.echo, 2),
  LiteHero.cavaliereLunare => (const Color(0xffa4cdff), _OpenGlyph.portal, 3),
  LiteHero.slimeBlu => (const Color(0xff7ee4dd), _OpenGlyph.jaw, 6),
  LiteHero.vampiro => (const Color(0xffee848d), _OpenGlyph.feather, 8),
  LiteHero.reGoblin => (const Color(0xffceb05e), _OpenGlyph.portal, 4),
  LiteHero.pollo => (const Color(0xffffdfa1), _OpenGlyph.ring, 3),
  LiteHero.raganella => (const Color(0xff9fe0a5), _OpenGlyph.trail, 3),
  LiteHero.pipistrello => (const Color(0xffc0a3d9), _OpenGlyph.ring, 6),
  LiteHero.guardiaSolare => (const Color(0xffffcb79), _OpenGlyph.trail, 4),
  LiteHero.eliteSolare => (const Color(0xffffdf9d), _OpenGlyph.spark, 5),
  LiteHero.guardianoSolare => (const Color(0xffffd485), _OpenGlyph.ward, 6),
  LiteHero.aberrazioneSolare => (const Color(0xffe5c078), _OpenGlyph.ward, 5),
  LiteHero.demoneMinore => (const Color(0xffed8d63), _OpenGlyph.claw, 3),
  LiteHero.demoneIntermedio => (const Color(0xffff9761), _OpenGlyph.fissure, 5),
  LiteHero.demoneMaggiore => (const Color(0xffed8cae), _OpenGlyph.ward, 7),
  LiteHero.diavolo => (const Color(0xffff9467), _OpenGlyph.fire, 5),
  LiteHero.polloMeccanico => (const Color(0xff9df3e6), _OpenGlyph.ring, 5),
  LiteHero.vesanybel => (const Color(0xffd1a3df), _OpenGlyph.ring, 4),
  LiteHero.aerovyr => (const Color(0xff9ad8ff), _OpenGlyph.spark, 7),
  LiteHero.vedettaEiva => (const Color(0xff94dedf), _OpenGlyph.trail, 7),
  LiteHero.ragnoSaldatore => (const Color(0xff97e7fb), _OpenGlyph.spark, 4),
  LiteHero.rasvyr => (const Color(0xffacd6f2), _OpenGlyph.jaw, 2),
  LiteHero.lupoDiVaitern => (const Color(0xffb9ceff), _OpenGlyph.claw, 2),
  LiteHero.pysciwarden => (const Color(0xff84dfd6), _OpenGlyph.trail, 6),
  LiteHero.lusierTre => (const Color(0xffffce89), _OpenGlyph.card, 6),
  LiteHero.fabbro => (const Color(0xffb5d8ff), _OpenGlyph.portal, 12),
};

void _paintOpenCutscene(
  Canvas canvas,
  Size size,
  _ArenaCamera camera,
  _ArenaPaint arena,
  LiteOpenScene scene,
) {
  final mobile = size.width < 580;
  final coop = arena.run.playerCount > 1;
  final reduceMotion = arena.reduceOpenMotion;
  final progress = scene.progress(lead: arena.openSceneLead);
  final fade = _inkEase(progress / .16) * _inkEase((1 - progress) / .24);
  if (fade < .002) return;
  final (ink, glyph, strokes) = _openInk(scene.hero);
  final hue = scene.hostile
      ? Color.lerp(ink, scene.shadow ? _violet : _sand, .48)!
      : ink;
  final direction = _offset(scene.direction);
  final at = camera.worldToScreen(_offset(scene.at));
  final rect = Offset.zero & size;
  final focal = Offset(
    at.dx.clamp(0.0, size.width),
    at.dy.clamp(0.0, size.height),
  );
  final veil = coop ? .40 : .85;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.radial(
        focal,
        size.shortestSide * .57,
        [
          _ink.withValues(alpha: fade * veil * .10),
          _ink.withValues(alpha: fade * veil),
        ],
        [.19, .91],
      ),
  );

  final panel = coop
      ? Offset(size.width - (mobile ? 78 : 121), size.height * .26)
      : Offset(size.width * (mobile ? .71 : .73), size.height * .64);
  final spread = math.min(
    size.shortestSide * (coop ? .095 : .24),
    coop ? 66.0 : 164.0,
  );
  final energy = reduceMotion ? .46 : progress;
  if (!coop) {
    final wedge = Path()
      ..moveTo(0, size.height * .35)
      ..lineTo(size.width * .92, size.height * .25)
      ..lineTo(size.width * .78, size.height * .70)
      ..lineTo(0, size.height * .79)
      ..close();
    canvas.drawPath(wedge, Paint()..color = _ink.withValues(alpha: fade * .86));
  }
  if (!reduceMotion || !coop) {
    canvas.save();
    canvas.translate(panel.dx, panel.dy - spread * .43);
    canvas.rotate(direction.dx < 0 ? -.12 : .12);
    _openGesture(canvas, glyph, strokes, spread, hue, fade, energy);
    canvas.restore();
  }

  // The vignette shows the same equipment, appearance and pose renderer as combat.
  if (!coop || !reduceMotion) {
    final run = arena.run;
    final fighter = run.coopFighters
        .where((member) => member.id == scene.actorId)
        .firstOrNull;
    final rival = run.enemies
        .where((enemy) => enemy.id == scene.enemyId)
        .firstOrNull;
    final look = fighter == null
        ? arena.appearance
        : arena.guestAppearances[fighter.account] ??
              oculumLiteDefaultAppearance(scene.hero);
    final equipment = rival?.mirror?.weapon ?? fighter?.weapon ?? run.weapon;
    final facing = direction.dx < 0 ? -1.0 : 1.0;
    final scale = spread * (coop ? .37 : .57);
    canvas.saveLayer(
      Rect.fromCenter(center: panel, width: spread * 3.4, height: spread * 4),
      Paint()..color = Colors.white.withValues(alpha: fade),
    );
    canvas.translate(panel.dx, panel.dy);
    canvas.scale(scale * facing, scale * _isometricY);
    _hero(
      canvas,
      look,
      equipment,
      run.time,
      hero: scene.hero,
      sprites: arena._heroSprites,
      figureArt: scene.actorId == 0 && scene.hero == run.hero
          ? arena.heroFrames
          : null,
      poseArt: arena._poses(look),
      heads: arena._heads(look),
      gearArt: arena.weapons[equipment],
      mimic: fighter?.mimic ?? run.mimic,
      night: fighter?.night ?? run.night,
      giant: fighter?.plagueForm ?? run.plagueForm,
      preparingTalent:
          scene.hero == LiteHero.ashley && energy > .38 && energy < .87,
      springRemaining: energy < .74 ? .22 : .049,
      dashing: glyph == _OpenGlyph.trail && energy > .42,
      attackElapsed: energy > .35 && energy < .78 ? (energy - .35) * .48 : null,
      releaseAge: energy > .35 && energy < .78 ? (energy - .35) * .48 : null,
      openAge: energy * .39,
      aiming: Offset(direction.dx.abs(), direction.dy * facing),
    );
    canvas.restore();
  }

  final margin = mobile ? 15.0 : 35.0;
  final maxTitle =
      size.width *
      (coop
          ? .64
          : mobile
          ? .54
          : .56);
  final left = coop ? math.max(margin, panel.dx - maxTitle - spread) : margin;
  final y = coop ? panel.dy - (mobile ? 41.0 : 50.0) : size.height * .50;
  final smallText = TextPainter(
    text: TextSpan(
      text: 'OPEN',
      style: TextStyle(
        color: hue.withValues(alpha: fade),
        fontSize: mobile ? 9 : 11,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w800,
        letterSpacing: 3.2,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  smallText.paint(canvas, Offset(left + 7, y));
  final title = TextPainter(
    text: TextSpan(
      text: scene.title,
      style: TextStyle(
        color: const Color(0xffffefe2).withValues(alpha: fade),
        fontSize: coop ? (mobile ? 13 : 20) : (mobile ? 19 : 34),
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w800,
        height: 1.08,
        shadows: const [Shadow(color: Color(0xff110a12), blurRadius: 8)],
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: maxTitle);
  title.paint(canvas, Offset(left + 7, y + smallText.height + 5));
  final rule = Offset(left + 8, y + smallText.height + title.height + 12);
  canvas.drawLine(
    rule,
    rule +
        Offset(
          math.min(title.width, spread * 1.5) *
              (reduceMotion ? 1 : _inkEase(progress * 3)),
          0,
        ),
    Paint()
      ..strokeWidth = 1.5
      ..color = hue.withValues(alpha: fade * .87),
  );
  smallText.dispose();
  title.dispose();
}

void _openGesture(
  Canvas canvas,
  _OpenGlyph glyph,
  int strokes,
  double spread,
  Color hue,
  double fade,
  double time,
) {
  final sweep = _inkEase(time * 1.8);
  final paint = Paint()
    ..color = hue.withValues(alpha: fade * .68)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = math.max(1.0, spread * .019);
  for (var index = 0; index < strokes; index++) {
    final theta = math.pi * 2 * index / strokes - math.pi / 2;
    final axis = Offset(math.cos(theta), math.sin(theta));
    final perpendicular = Offset(-axis.dy, axis.dx);
    final start = axis * spread * (.10 + sweep * .18);
    final end = axis * spread * (.52 + sweep * .57);
    switch (glyph) {
      case _OpenGlyph.ring || _OpenGlyph.portal || _OpenGlyph.ward:
        final radius = spread * (glyph == _OpenGlyph.portal ? .67 : .82);
        final ring = Rect.fromCenter(
          center: Offset.zero,
          width: radius * 2,
          height: radius * 1.5,
        );
        canvas.drawArc(
          ring,
          theta + sweep * .40,
          sweep * (glyph == _OpenGlyph.ward ? .71 : .43),
          false,
          paint,
        );
        final rune = axis * radius;
        if (glyph == _OpenGlyph.ring) {
          canvas.drawCircle(
            rune,
            spread * (.033 + sweep * .02),
            Paint()..color = hue.withValues(alpha: fade),
          );
        } else {
          final serration = spread * (glyph == _OpenGlyph.portal ? .13 : .24);
          canvas.drawLine(
            rune - perpendicular * serration,
            rune + axis * serration,
            paint,
          );
        }
      case _OpenGlyph.spring:
        final x = spread * (-.75 + index * .19 + sweep * .28);
        final size = spread * (.65 - index * .042);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, 0),
            width: size * .36,
            height: size,
          ),
          paint,
        );
      case _OpenGlyph.card:
        final corner = axis * spread * (.25 + sweep * .64);
        canvas.save();
        canvas.translate(corner.dx, corner.dy);
        canvas.rotate(theta + time);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: spread * .22,
              height: spread * .36,
            ),
            const Radius.circular(3),
          ),
          paint,
        );
        canvas.drawCircle(Offset.zero, spread * .037, paint);
        canvas.restore();
      case _OpenGlyph.spark || _OpenGlyph.fissure:
        final turn = index.isEven ? 1.0 : -1.0;
        final path = Path()..moveTo(start.dx, start.dy);
        for (var i = 1; i <= 4; i++) {
          final at =
              Offset.lerp(start, end, i / 4)! +
              perpendicular * (i.isEven ? -turn : turn) * spread * .11;
          path.lineTo(at.dx, at.dy);
        }
        canvas.drawPath(path, paint);
      case _OpenGlyph.feather ||
          _OpenGlyph.fire ||
          _OpenGlyph.claw ||
          _OpenGlyph.jaw ||
          _OpenGlyph.trail ||
          _OpenGlyph.echo:
        final direction = glyph == _OpenGlyph.jaw ? -1.0 : 1.0;
        final rib =
            perpendicular *
            spread *
            (glyph == _OpenGlyph.trail ? .27 : .43) *
            direction;
        final finish = end + rib * (glyph == _OpenGlyph.echo ? -.7 : .28);
        final blade = Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(
            end.dx + rib.dx,
            end.dy + rib.dy,
            finish.dx,
            finish.dy,
          )
          ..quadraticBezierTo(
            end.dx - rib.dx * .55,
            end.dy - rib.dy * .55,
            start.dx,
            start.dy,
          )
          ..close();
        canvas.drawPath(
          blade,
          Paint()
            ..color = hue.withValues(
              alpha: fade * (glyph == _OpenGlyph.fire ? .42 : .28),
            ),
        );
        canvas.drawPath(blade, paint);
    }
  }
}
