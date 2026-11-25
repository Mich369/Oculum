part of 'oculum_lite_arena.dart';

enum _GroundGrain { dust, bark, slate, brass, crystal, silt }

typedef _GroundFinish = ({_GroundGrain grain, Color shade, Color pigment});

_GroundFinish _groundFinish(LiteRun run) {
  if (run.restHub) {
    return (
      grain: _GroundGrain.bark,
      shade: const Color(0xff2b151b),
      pigment: const Color(0xffb98157),
    );
  }
  if (run.inSolarDungeon) {
    return (
      grain: _GroundGrain.slate,
      shade: const Color(0xff34221f),
      pigment: const Color(0xffd1a05f),
    );
  }
  return switch ((run.thirdEncounter?.region, run.realm, run.biome)) {
    (LiteThirdRegion.sommerso, _, _) => (
      grain: _GroundGrain.silt,
      shade: const Color(0xff101f2c),
      pigment: const Color(0xff5f928b),
    ),
    (LiteThirdRegion.nuvole, _, _) => (
      grain: _GroundGrain.crystal,
      shade: const Color(0xff222334),
      pigment: const Color(0xff9cacc5),
    ),
    (LiteThirdRegion.oblio, _, _) => (
      grain: _GroundGrain.slate,
      shade: const Color(0xff201322),
      pigment: const Color(0xff917488),
    ),
    (_, LiteRealm.inferno, _) => (
      grain: _GroundGrain.slate,
      shade: const Color(0xff241318),
      pigment: const Color(0xffad7156),
    ),
    (_, LiteRealm.caramella, _) => (
      grain: _GroundGrain.dust,
      shade: const Color(0xff442329),
      pigment: const Color(0xffd1a391),
    ),
    (_, LiteRealm.postea, _) || (_, _, LiteBiome.postea) => (
      grain: _GroundGrain.brass,
      shade: const Color(0xff102029),
      pigment: const Color(0xff9e8c69),
    ),
    (_, _, LiteBiome.campo) => (
      grain: _GroundGrain.dust,
      shade: const Color(0xff24161d),
      pigment: const Color(0xffbf9670),
    ),
    (_, _, LiteBiome.foresta) => (
      grain: _GroundGrain.bark,
      shade: const Color(0xff14211f),
      pigment: const Color(0xff959b65),
    ),
    (_, _, LiteBiome.dungeon) => (
      grain: _GroundGrain.slate,
      shade: const Color(0xff221721),
      pigment: const Color(0xffa88291),
    ),
    (_, _, LiteBiome.deserto) => (
      grain: _GroundGrain.crystal,
      shade: const Color(0xff192b44),
      pigment: const Color(0xffa7c3ce),
    ),
    (_, _, LiteBiome.orea) => (
      grain: _GroundGrain.silt,
      shade: const Color(0xff391a36),
      pigment: const Color(0xffac9aac),
    ),
  };
}

// Record this with the floor. The veining is anchored in world coordinates
// and cannot flicker as the camera follows the player or a co-op guest.
void _paintInkWorldGround(Canvas canvas, LiteRun run) {
  final room = Rect.fromLTWH(0, 0, run.width.toDouble(), run.height.toDouble());
  final finish = _groundFinish(run);
  final rng = math.Random(
    run.seed ^ (run.stage * 4831) ^ (run.thirdRoom * 139) ^ run.actRoom,
  );
  final debris = Path();
  final facets = Path();
  final fibres = Path();
  for (var i = 0; i < 47; i++) {
    final x = room.width * rng.nextDouble();
    final y = room.height * rng.nextDouble();
    final edge = math.min(
      math.min(x, room.width - x),
      math.min(y, room.height - y),
    );
    final limit = finish.grain == _GroundGrain.silt ? 4.6 : 3.3;
    if (edge > limit && i % 5 != 0) continue;
    final span = (.32 + rng.nextDouble() * 1.60) * (edge < limit ? 1 : .62);
    final (tilt, width) = switch (finish.grain) {
      _GroundGrain.dust => (.27, .18),
      _GroundGrain.bark => (.62, .20),
      _GroundGrain.slate => (-.26, .23),
      _GroundGrain.brass => (0.0, .075),
      _GroundGrain.crystal => (-.52, .16),
      _GroundGrain.silt => (.12, .12),
    };
    final runOfStone = Offset(span, span * tilt);
    final at = Offset(x, y);
    final skew = .10 + rng.nextDouble() * width;
    final step = Offset(-tilt, 1) * skew;
    final chip = at + runOfStone * .52;
    debris.addPolygon([
      at - step * .12,
      at + runOfStone * .23 - step,
      chip - step * .35,
      at + runOfStone - step * .76,
      at + runOfStone * .72 + step * .44,
      at + runOfStone * .14 + step * .81,
    ], true);
    facets.addPolygon([
      at + runOfStone * .14 - step * .76,
      chip - step * .35,
      at + runOfStone * .84 - step * .65,
      chip + step * .15,
    ], true);

    // Short, interrupted dry-brush grain. Keep the centre comparatively
    // quiet so coloured attacks retain their silhouette.
    if (edge > limit) continue;
    for (var stroke = 0; stroke < 4; stroke++) {
      final tip = chip + runOfStone * (.04 * stroke) + step * (.19 * stroke);
      final tooth = tip + runOfStone * (.07 + .018 * stroke);
      fibres.addPolygon([
        tip,
        tip + step * .21,
        tooth + step * .11,
        tooth,
      ], true);
    }
  }

  canvas.save();
  canvas.clipRect(room);
  canvas.drawPath(debris, Paint()..color = finish.shade.withValues(alpha: .39));
  canvas.drawPath(
    facets,
    Paint()..color = finish.pigment.withValues(alpha: .20),
  );
  canvas.drawPath(
    fibres,
    Paint()..color = finish.pigment.withValues(alpha: .28),
  );
  canvas.restore();
}

void _paintInkCoverContact(
  Canvas canvas,
  Rect bounds,
  LiteObstacle obstacle,
  LiteBiome biome,
) {
  final foot = bounds.bottom;
  final start = bounds.left;
  final width = bounds.width;
  final shade = _palette(biome);
  final strip = Path()
    ..moveTo(start, foot - .10)
    ..lineTo(start + width * .28, foot - .18)
    ..lineTo(start + width * .56, foot - .13)
    ..lineTo(bounds.right, foot - .07)
    ..lineTo(bounds.right, foot)
    ..lineTo(start + width * .70, foot + .075)
    ..lineTo(start + width * .31, foot + .033)
    ..close();
  canvas.drawPath(strip, Paint()..color = _ink.withValues(alpha: .78));
  if (obstacle.secretGate || width < .65) return;
  final nick = Offset(start + width * .38, foot - .02);
  _lines(
    canvas,
    [
      nick,
      nick + Offset(width * .16, -.032),
      nick + Offset(width * .29, -.024),
    ],
    shade.light.withValues(alpha: obstacle.breakable ? .58 : .36),
    .034,
  );
}

void _paintInkDashGap(Canvas canvas, Rect gap, LiteBiome biome) {
  final metal = biome == LiteBiome.postea;
  final lip = metal ? const Color(0xff9b7864) : const Color(0xff9a7188);
  final rock = metal ? const Color(0xff3e3539) : const Color(0xff463245);
  final inner = metal ? const Color(0xff171923) : const Color(0xff1e1524);
  canvas.save();
  canvas.clipRect(gap);
  canvas.drawRect(gap, Paint()..color = const Color(0xff100d16));

  for (final (side, edge) in [(1.0, gap.left), (-1.0, gap.right)]) {
    final ledge = Path()..moveTo(edge, gap.top);
    final boundary = Path()..moveTo(edge + .022 * side, gap.top);
    for (var i = 0; i < 10; i++) {
      final unit = gap.height / 10;
      final y = gap.top + i * unit;
      final reach = (.10 + ((i * 7 + (side > 0 ? 3 : 0)) % 5) * .032) * side;
      ledge
        ..lineTo(edge + reach, y + unit * .25)
        ..lineTo(edge + reach * .73, y + unit * .76)
        ..lineTo(edge + reach * .95, y + unit);
      boundary
        ..lineTo(edge + side * .028, y + unit * .22)
        ..lineTo(edge + side * .052, y + unit * .54)
        ..lineTo(edge + side * .017, y + unit);
      if (i.isEven) {
        _lines(
          canvas,
          [
            Offset(edge + side * .27, y + unit * .23),
            Offset(edge + side * .44, y + unit * .41),
            Offset(edge + side * .36, y + unit * .85),
          ],
          inner,
          .11,
        );
      }
    }
    ledge
      ..lineTo(edge, gap.bottom)
      ..close();
    canvas.drawPath(ledge, Paint()..color = rock);
    canvas.drawPath(
      boundary,
      Paint()
        ..color = lip
        ..style = PaintingStyle.stroke
        ..strokeWidth = .045
        ..strokeJoin = StrokeJoin.bevel,
    );
  }
  canvas.restore();
}

void _paintInkDashPadBase(Canvas canvas, Offset centre, LiteBiome biome) {
  final (body, bevel) = biome == LiteBiome.postea
      ? (const Color(0xff352c35), const Color(0xffa68168))
      : (const Color(0xff3e2c40), const Color(0xff8b6883));
  _poly(
    canvas,
    [
      centre + const Offset(-.55, .13),
      centre + const Offset(-.46, -.20),
      centre + const Offset(.34, -.28),
      centre + const Offset(.56, -.09),
      centre + const Offset(.46, .24),
      centre + const Offset(-.33, .29),
    ],
    body,
    stroke: _ink,
    width: .067,
  );
  _lines(
    canvas,
    [
      centre + const Offset(-.42, -.16),
      centre + const Offset(.29, -.23),
      centre + const Offset(.43, -.14),
    ],
    bevel,
    .052,
  );
}
