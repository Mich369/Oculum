part of 'oculum_lite_run.dart';

class LiteGroundShot {
  LiteGroundShot(this.position, this.sticky, this.fromEnemy, this.remaining);
  final Point<double> position;
  final bool sticky, fromEnemy;
  double remaining;
  List<Object> get frame => [
    position.x,
    position.y,
    sticky,
    fromEnemy,
    remaining,
  ];
  static LiteGroundShot? read(Object? data) {
    if (data is! List || data.length != 5) return null;
    return LiteGroundShot(
      Point(_num(data[0]), _num(data[1])),
      data[2] == true,
      data[3] == true,
      _num(data[4]).clamp(0.0, 6.0),
    );
  }
}

extension LiteGoblinCombat on LiteRun {
  bool get goblinCamp => _goblinWave > 0;
  int get goblinWave => _goblinWave;
  bool get goblinCampEntrance =>
      !goblinCamp &&
      !inActTwo &&
      !inThirdAct &&
      secretRoomRevealed &&
      stage >= 6 &&
      stage < 12 &&
      !achievements.contains('campo-goblin:$stage');

  void _checkGoblinEntrance() {
    if (!stageClear ||
        !goblinCampEntrance ||
        hostDown ||
        LiteRun._distanceSquared(position, LiteRun.secretCache) > 1.15 * 1.15)
      return;
    achievements.add('campo-goblin:$stage');
    projectiles.clear();
    groundShots.clear();
    _combatImpacts.clear();
    _burstTraces.clear();
    obstacles
      ..clear()
      ..addAll([
        LiteObstacle(10.2, 5.5, 2.8, 2.1, breakable: true, hp: 35),
        LiteObstacle(10.6, 14.3, 1.9, 1.9),
        LiteObstacle(19.2, 4, 2.0, 2.7),
        LiteObstacle(20.5, 15, 2.4, 2.0, breakable: true, hp: 35),
        LiteObstacle(25.5, 8.9, 2.0, 3.8),
      ]);
    position = LiteRun._spawn;
    for (var i = 0; i < coopFighters.length; i++) {
      coopFighters[i].position = _coopSpawn(i);
    }
    _dismissRoomWolves();
    for (final clone in clones) {
      clone.position = LiteRun._spawn + const Point(0, 1.7);
    }
    _goblinWave = 0;
    stageClear = false;
    _nextGoblinWave();
  }

  void _nextGoblinWave() {
    _goblinWave++;
    switch (_goblinWave) {
      case 1 || 2 || 3 || 4 || 5 || 6:
        final count = 2 + _goblinWave;
        for (var i = 0; i < count; i++) {
          final role = (i + _goblinWave) % 3 == 0
              ? LiteEnemyKind.goblinFango
              : LiteEnemyKind.goblinColtello;
          _spawnEnemy(
            role,
            Point(20.0 + (i % 2) * 4.5, 3 + i * 15.0 / (count - 1)),
          );
        }
        final rare = _LiteRandom(seed ^ stage * 23011 ^ _goblinWave * 25579)
          ..nextDouble()
          ..nextDouble();
        if (rare.nextInt(100) == 0) {
          _spawnEnemy(LiteEnemyKind.goblinColla, const Point(27, 13.5));
        }
        message = 'Campo goblin · Ondata $_goblinWave/6.';
      case 7:
        final king = _spawnEnemy(LiteEnemyKind.reGoblin, const Point(27.8, 11));
        final rare = _LiteRandom(seed ^ stage * 315153)
          ..nextDouble()
          ..nextDouble();
        king.glueRetinue =
            hasGlue ||
            coopFighters.any((fighter) => fighter.allowGlue) ||
            rare.nextInt(100) < 6;
        message = 'Campo goblin · Entra il Re Goblin.';
      case 8:
        stageClear = true;
        loot.add(LiteLoot(const Point(27.5, 11), LiteLootKind.obser, 60));
        loot.add(
          LiteLoot(const Point(27.5, 10.2), LiteLootKind.refinedGreenGem, 1),
        );
        message =
            'Campo goblin conquistato. Raggiungi il portale per proseguire.';
    }
  }

  void _goblinSummons(LiteEnemy king, double elapsed) {
    king.summonIn -= elapsed;
    if (king.summonIn > 0) return;
    king.summonIn = 11;
    for (final (kind, cap) in [
      (LiteEnemyKind.goblinColtello, 2),
      (LiteEnemyKind.goblinFango, 1),
      if (king.glueRetinue) (LiteEnemyKind.goblinColla, 1),
    ]) {
      final active = enemies
          .where((enemy) => enemy.kind == kind && enemy.hp > 0)
          .length;
      for (var i = active; i < cap; i++) {
        _spawnEnemy(kind, king.position + Point(-1.5, i.isEven ? 1.4 : -1.4));
      }
    }
  }

  bool _goblinRetinue(
    Point<double> from,
    Point<double> direction,
    int ownerId,
    int grade,
  ) {
    final knives = _summonCompanions(
      LiteCompanion.goblinColtello,
      2,
      from,
      direction,
      ownerId,
      grade,
    );
    final mud = _summonCompanions(
      LiteCompanion.goblinFango,
      1,
      from,
      direction * -1.0,
      ownerId,
      grade,
    );
    final glue =
        (hasGlue ||
            coopFighters.any(
              (fighter) => fighter.id == ownerId && fighter.allowGlue,
            )) &&
        _summonCompanions(
          LiteCompanion.goblinColla,
          1,
          from,
          direction,
          ownerId,
          grade,
        );
    return knives || mud || glue;
  }

  static const _glueRadius = 1.45;

  double terrainSpeedAt(Point<double> point, {required bool enemy}) =>
      groundShots.any(
        (floor) =>
            floor.sticky &&
            floor.remaining > 0 &&
            floor.fromEnemy != enemy &&
            LiteRun._distanceSquared(point, floor.position) <
                _glueRadius * _glueRadius,
      )
      ? .46
      : _arenaTerrainSpeedAt(point);

  void _leaveGroundShot(LiteProjectile shot) {
    if (groundShots.length >= 28) groundShots.removeAt(0);
    final sticky = shot.kind == LiteProjectileKind.glue;
    groundShots.add(
      LiteGroundShot(shot.position, sticky, shot.fromEnemy, sticky ? 6 : 1.3),
    );
  }

  bool _raiseByRoyalCall(LiteCoopFighter? caller) {
    final kit = caller?._night ?? _night;
    if ((caller?.hero ?? hero) != LiteHero.reGoblin ||
        finished ||
        kit.utility > 0 ||
        kit.stun > 0 ||
        (caller?.hp ?? hp) <= 0 ||
        (caller?.oculum ?? oculum) < 4)
      return false;
    final origin = caller?.position ?? position;
    var raised = false;
    if (caller != null &&
        hostDown &&
        LiteRun._distanceSquared(origin, position) <= 100) {
      hp = maxHp * .5;
      _hitProtectionRemaining = .95;
      raised = true;
    }
    for (final ally in _damageableAllies) {
      if (ally.hp > 0 ||
          ally.expiresAfter != null ||
          LiteRun._distanceSquared(origin, ally.position) > 100)
        continue;
      ally
        ..hp = ally.maxHp * .5
        ..downRemaining = 0;
      if (ally is LiteCoopFighter) ally._protection = .95;
      raised = true;
    }
    if (!raised) return false;
    kit.utility = 12;
    if (caller == null) {
      oculum -= 4;
    } else {
      caller.oculum -= 4;
    }
    message = 'Richiamo del Re · Alleati rialzati al 50% Vita.';
    return true;
  }
}
