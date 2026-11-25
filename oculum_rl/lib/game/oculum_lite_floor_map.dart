part of 'oculum_lite_run.dart';

enum LiteMapSector { ingresso, fianco, cuore, retro, uscita }

class LiteFloorRoom {
  const LiteFloorRoom(
    this.sector,
    this.label,
    this.left,
    this.top,
    this.right,
    this.bottom,
  );
  final LiteMapSector sector;
  final String label;
  final double left, top, right, bottom;
  bool contains(Point<double> at) =>
      at.x >= left && at.x < right && at.y >= top && at.y < bottom;
  Point<double> get center => Point((left + right) / 2, (top + bottom) / 2);
}

extension LiteFloorExploration on LiteRun {
  bool get hasFloorMap => _mappedFloor == inputArena;
  bool hasMapped(LiteMapSector room) =>
      (_mappedSectors & (1 << room.index)) != 0;
  int get mappedSectors => _mappedSectors;
  bool get mapShortcutOpen =>
      hasFloorMap &&
      mapHasShortcut &&
      !obstacles.any((wall) => wall.mapShortcut);
  bool get mapHasShortcut =>
      !usesSubArena &&
      biome == LiteBiome.dungeon &&
      !isVeyrthArena &&
      !isFinalFloor;
  bool get hasDrownedCrossing =>
      thirdEncounter?.region == LiteThirdRegion.sommerso;

  double get _mapForkX => 8.4 + (seed % 5) * .17;
  double get _mapNorth =>
      7.4 + ((seed + stage + actRoom + thirdRoom) % 4) * .46;
  double get _mapSouth => 14.8 + ((seed + stage + thirdRoom) % 3) * .44;
  double get _mapExitX => 24.4 + ((seed + stage * 3) % 4) * .32;

  List<LiteFloorRoom> get floorRooms {
    final (
      entry,
      upper,
      center,
      lower,
      exit,
    ) = switch (thirdEncounter?.region) {
      LiteThirdRegion.oblio => (
        'Soglia',
        'Cappelle',
        'Navata',
        'Cripte',
        'Passaggio',
      ),
      LiteThirdRegion.sommerso => (
        'Approdo',
        'Sentiero emerso',
        'Acque basse',
        'Altari sommersi',
        'Abside',
      ),
      LiteThirdRegion.nuvole => (
        'Pilone',
        'Passerella alta',
        'Terrazza',
        'Binari bassi',
        'Varco',
      ),
      _ => switch (realm) {
        LiteRealm.inferno => (
          'Soglia',
          'Galleria di scorie',
          'Faglia',
          'Terrazza di cenere',
          'Varco',
        ),
        LiteRealm.caramella => (
          'Sponda',
          'Costone di zucchero',
          'Piana dello sciroppo',
          'Lembi di crosta',
          'Varco',
        ),
        LiteRealm.postea => (
          'Ingresso',
          'Manutenzione',
          'Linea di montaggio',
          'Deposito',
          'Varco',
        ),
        null => switch (biome) {
          LiteBiome.campo => (
            'Bivio',
            'Sentiero del mercante',
            'Accampamento',
            'Fianco della palizzata',
            'Uscita',
          ),
          LiteBiome.foresta => (
            'Ingresso',
            'Sentiero dei rovi',
            'Radura',
            'Sentiero delle radici',
            'Uscita',
          ),
          LiteBiome.dungeon => (
            'Atrio',
            'Galleria alta',
            'Sala delle colonne',
            'Galleria bassa',
            'Uscita',
          ),
          LiteBiome.postea => (
            'Ingresso',
            'Manutenzione',
            'Fonderia',
            'Condotto basso',
            'Uscita',
          ),
          LiteBiome.deserto => (
            'Sponda',
            'Costone azzurro',
            'Sabbia cristallina',
            'Margine umido',
            'Uscita',
          ),
          LiteBiome.orea => (
            'Soglia',
            'Colline lilla',
            'Conca dei due soli',
            'Sentiero delle sfere',
            'Uscita',
          ),
        },
      },
    };
    return [
      LiteFloorRoom(LiteMapSector.ingresso, entry, 0, 0, _mapForkX, height),
      LiteFloorRoom(
        LiteMapSector.fianco,
        upper,
        _mapForkX,
        0,
        _mapExitX,
        _mapNorth,
      ),
      LiteFloorRoom(
        LiteMapSector.cuore,
        center,
        _mapForkX,
        _mapNorth,
        _mapExitX,
        _mapSouth,
      ),
      LiteFloorRoom(
        LiteMapSector.retro,
        lower,
        _mapForkX,
        _mapSouth,
        _mapExitX,
        height,
      ),
      LiteFloorRoom(
        LiteMapSector.uscita,
        hasChamber ? '$chamberGrade · $chamberTitle' : exit,
        _mapExitX,
        0,
        width,
        height,
      ),
    ];
  }

  void _openFloorMap() {
    _mappedFloor = inputArena;
    _mappedSectors = 1;
    _mapWaypoint = null;
    _placeCrossing();
    final camp = campPatrols;
    // External paths both reconnect to the battle room. The sideways gaps
    // leave clearance for enemies and allies alike.
    if (camp || mapHasShortcut) {
      obstacles.add(
        LiteObstacle(
          _mapForkX,
          _mapNorth,
          .66,
          _mapSouth - _mapNorth,
          fixedMap: true,
        ),
      );
      if (mapHasShortcut) {
        obstacles.add(
          LiteObstacle(
            11,
            4.4,
            1.3,
            2.34,
            breakable: true,
            mapShortcut: true,
            hp: 17,
          ),
        );
      }
    } else if (!isVeyrthArena &&
        (!isFinalFloor || inThirdAct) &&
        !hasDrownedCrossing) {
      obstacles.add(
        LiteObstacle(
          _mapForkX + .7,
          _mapNorth + .85,
          1.1,
          max(1.7, _mapSouth - _mapNorth - 2.05),
          fixedMap: true,
        ),
      );
    }
    if (!isVeyrthArena &&
        (!isFinalFloor || inThirdAct) &&
        !hasDrownedCrossing) {
      // Two real openings around each side cell. The shorter divider switches
      // ends with the seed so the middle lane doesn't have one fixed approach.
      final flip = (seed ^ stage ^ actRoom ^ thirdRoom ^ biome.index).isOdd;
      obstacles.addAll([
        LiteObstacle(
          flip ? 17 : 13.1,
          _mapNorth - .22,
          2.45,
          .52,
          fixedMap: true,
        ),
        LiteObstacle(
          flip ? 13.1 : 17,
          _mapSouth - .27,
          2.25,
          .50,
          fixedMap: true,
        ),
        if (dashPads.isEmpty)
          LiteObstacle(_mapExitX - .18, 1.7, .66, 2.2, fixedMap: true),
        LiteObstacle(_mapExitX, 6.6, .46, 1.3, fixedMap: true),
        LiteObstacle(_mapExitX, 14.55, .46, 1.3, fixedMap: true),
        LiteObstacle(_mapExitX - .18, height - 4, .66, 2.4, fixedMap: true),
      ]);
    }
  }

  void _discoverFloorMap() {
    if (!hasFloorMap || _mappedSectors == 31) return;
    void discover(Point<double> at) {
      final sector = at.x < _mapForkX
          ? LiteMapSector.ingresso
          : at.x >= _mapExitX
          ? LiteMapSector.uscita
          : at.y < _mapNorth
          ? LiteMapSector.fianco
          : at.y >= _mapSouth
          ? LiteMapSector.retro
          : LiteMapSector.cuore;
      _mappedSectors |= 1 << sector.index;
    }

    discover(position);
    for (final guest in coopFighters) {
      if (guest.connected && guest.hp > 0) discover(guest.position);
    }
  }

  Point<double>? get mapWaypoint => _mapWaypoint;
  void markMapPoint(Point<double>? point) {
    if (point == null ||
        (point.x.isFinite &&
            point.y.isFinite &&
            floorRooms.any(
              (room) => hasMapped(room.sector) && room.contains(point),
            ))) {
      _mapWaypoint = point;
    }
  }

  List<(double, double, double, double)> get drownedPools => hasDrownedCrossing
      ? [(8, _mapNorth, 15.3, _mapSouth), (17.2, _mapNorth, 25, _mapSouth)]
      : const [];

  int drownedPoolAt(Point<double> at) => drownedPools.indexWhere(
    (pool) =>
        at.x >= pool.$1 && at.y >= pool.$2 && at.x < pool.$3 && at.y < pool.$4,
  );

  bool isInDrownedWater(Point<double> at) => drownedPoolAt(at) >= 0;

  double _explorationTerrainSpeedAt(Point<double> point) =>
      isInDrownedWater(point) ? .77 : 1;
}
