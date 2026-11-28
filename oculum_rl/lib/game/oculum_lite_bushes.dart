part of 'oculum_lite_run.dart';

enum LiteBushKind {
  sterpi('Sterpi di rovo'),
  felci('Felci del sottobosco'),
  funghi('Funghi della galleria'),
  vapori('Sfiati runici'),
  cristalli('Cristalli della duna'),
  bulbi('Bulbi di Orea'),
  marshmallow('Cespuglio di marshmallow'),
  cenere('Cespuglio di cenere'),
  ombra('Rovi d’Oblio'),
  corallo('Coralli sommersi'),
  nuvola('Nubi basse');

  const LiteBushKind(this.label);
  final String label;
}

class LiteBush {
  const LiteBush(this.id, this.kind, this.center, this.radiusX, this.radiusY);
  final int id;
  final LiteBushKind kind;
  final Point<double> center;
  final double radiusX, radiusY;

  bool contains(Point<double> at) {
    final x = (at.x - center.x) / radiusX;
    final y = (at.y - center.y) / radiusY;
    return x * x + y * y < 1;
  }

  /// Finds the first intersection on a finite ray through the oval footprint.
  double? entryFraction(Point<double> from, Point<double> to) {
    final x = (from.x - center.x) / radiusX;
    final y = (from.y - center.y) / radiusY;
    final dx = (to.x - from.x) / radiusX;
    final dy = (to.y - from.y) / radiusY;
    final a = dx * dx + dy * dy;
    if (a < 1e-12) return null;
    final b = x * dx + y * dy;
    final discriminant = b * b - a * (x * x + y * y - 1);
    if (discriminant <= 0) return null;
    final entry = (-b - sqrt(discriminant)) / a;
    final exit = (-b + sqrt(discriminant)) / a;
    if (exit <= 0 || entry >= 1) return null;
    return max(0, entry);
  }
}

extension LiteConcealment on LiteRun {
  static final _patterns = <(LiteBushKind, bool, bool), List<LiteBush>>{};

  bool get _hasConcealmentTerrain =>
      explorationRoutes &&
      !restHub &&
      !goblinCamp &&
      !inSolarDungeon &&
      !inDesertEye &&
      !baghestFight &&
      !isVeyrthArena &&
      !isFinalFloor;

  LiteBushKind get _concealmentKind => switch (thirdEncounter?.region) {
    LiteThirdRegion.oblio => LiteBushKind.ombra,
    LiteThirdRegion.sommerso => LiteBushKind.corallo,
    LiteThirdRegion.nuvole => LiteBushKind.nuvola,
    null => switch (realm) {
      LiteRealm.caramella => LiteBushKind.marshmallow,
      LiteRealm.inferno => LiteBushKind.cenere,
      LiteRealm.postea => LiteBushKind.vapori,
      null => switch (biome) {
        LiteBiome.campo => LiteBushKind.sterpi,
        LiteBiome.foresta => LiteBushKind.felci,
        LiteBiome.dungeon => LiteBushKind.funghi,
        LiteBiome.postea => LiteBushKind.vapori,
        LiteBiome.deserto => LiteBushKind.cristalli,
        LiteBiome.orea => LiteBushKind.bulbi,
      },
    },
  };

  List<LiteBush> get concealmentBushes {
    if (!_hasConcealmentTerrain) return const [];
    final kind = _concealmentKind;
    final floor = usesExplorableFloor;
    final alternate = (seed ^ stage ^ actRoom ^ thirdRoom).isOdd;
    return _patterns.putIfAbsent((kind, floor, alternate), () {
      // The two routes remain open and the central atrium never needs cover.
      final points = floor
          ? [
              Point<double>(7.8, alternate ? 5.65 : 16.1),
              Point<double>(16.7, alternate ? 17.9 : 3.65),
              Point<double>(26.8, alternate ? 5.25 : 18.4),
            ]
          : [
              Point<double>(8.1, alternate ? 5.9 : 15.9),
              Point<double>(16.9, alternate ? 17.3 : 4.8),
              Point<double>(26.0, alternate ? 6.1 : 16.1),
            ];
      return List.unmodifiable([
        LiteBush(0, kind, points[0], 1.31, .86),
        LiteBush(1, kind, points[1], 1.58, 1.08),
        LiteBush(2, kind, points[2], 1.32, .94),
      ]);
    });
  }

  int? bushAt(Point<double> at) {
    for (final bush in concealmentBushes) {
      if (bush.contains(at)) return bush.id;
    }
    return null;
  }

  double bushSightFraction(
    Point<double> from,
    Point<double> to, {
    int? ignoreBush,
  }) {
    var first = 1.0;
    for (final bush in concealmentBushes) {
      if (bush.id == ignoreBush || bush.contains(from)) continue;
      final entry = bush.entryFraction(from, to);
      if (entry != null && entry < first) first = entry;
    }
    return first;
  }

  bool bushBlocksSight(
    Point<double> from,
    Point<double> to, {
    int? ignoreBush,
  }) => bushSightFraction(from, to, ignoreBush: ignoreBush) < 1;

  void _placeBushAmbush() {
    if (stage == 0) return;
    final number = seed ^ (stage * 617) ^ (actRoom * 181) ^ (thirdRoom * 29);
    if (number % 4 != 0) return;
    final patches = concealmentBushes;
    if (patches.isEmpty) return;
    final candidates = enemies.where(
      (enemy) =>
          enemy.guard != null && enemy.chamberSeat == null && enemy.hp > 0,
    );
    for (final bush in patches) {
      if (bush.center.distanceTo(position) < 4.5 ||
          inExplorationAtrium(bush.center)) {
        continue;
      }
      LiteEnemy? chosen;
      var best = 9.0;
      for (final candidate in candidates) {
        final distance = candidate.position.distanceTo(bush.center);
        if (distance >= best || _blocked(bush.center, candidate.radius))
          continue;
        if (enemies.any(
          (other) =>
              other != candidate &&
              other.hp > 0 &&
              other.position.distanceTo(bush.center) < 2.2,
        )) {
          continue;
        }
        chosen = candidate;
        best = distance;
      }
      if (chosen != null) {
        chosen
          ..position = bush.center
          ..guard = (LiteGuard(bush.center)
            ..facing = LiteRun._unit(position - bush.center));
        chosen.stride._reset();
        return;
      }
    }
  }
}
