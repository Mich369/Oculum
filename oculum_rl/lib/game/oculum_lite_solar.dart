part of 'oculum_lite_run.dart';

enum LiteSolarPhase { courtyard, guard, rest, boss, cleared }

extension LiteSolarDungeon on LiteRun {
  bool get inSolarDungeon => solarPhase != null;
  bool get solarBossWaiting => solarPhase == LiteSolarPhase.rest;

  int get _solarFloor => 2 + seed % 3;

  void _placeSolarGate() {
    if (stage != _solarFloor) return;
    for (final point in const [
      Point<double>(17, 3.1),
      Point<double>(25, 5.2),
      Point<double>(18, 17.8),
      Point<double>(10.5, 3.2),
    ]) {
      if (_blocked(point, 1.6)) continue;
      obstacles.add(
        LiteObstacle(
          point.x - .75,
          point.y - .6,
          1.5,
          1.2,
          breakable: true,
          solarGate: true,
          hp: 30,
        ),
      );
      return;
    }
  }

  bool get canEnterSolarDungeon =>
      !inDesertEye &&
      stageClear &&
      !restHub &&
      !inSolarDungeon &&
      !hostDown &&
      !finished &&
      !shopOpen &&
      (solarStairs?.distanceTo(position) ?? double.infinity) < 1.65;

  bool enterSolarDungeon() {
    if (!canEnterSolarDungeon) return false;
    _noteFaunaCleared();
    fauna.clear();
    loot.clear();
    projectiles.clear();
    groundShots.clear();
    _combatImpacts.clear();
    solarStairs = null;
    achievements.add('dungeon-solare-scoperto');
    _solarWave(LiteSolarPhase.courtyard);
    return true;
  }

  bool enterSolarBoss() {
    if (!solarBossWaiting || !hasPortalNearby || hostDown) return false;
    _consumeMealForVisit();
    _solarWave(LiteSolarPhase.boss);
    return true;
  }

  void _solarWave(LiteSolarPhase phase) {
    _clearArenaActions();
    solarPhase = phase;
    restHub = false;
    stageClear = false;
    _registerOpenRoom();
    projectiles.clear();
    groundShots.clear();
    position = LiteRun._spawn;
    for (var i = 0; i < coopFighters.length; i++) {
      coopFighters[i].position = _coopSpawn(i);
    }
    _dismissRoomWolves();
    for (final clone in clones) {
      clone.position = position + const Point(0, 1.6);
    }
    obstacles
      ..clear()
      ..addAll([
        LiteObstacle(12, 5.1, 2.2, 1.8, breakable: true, hp: 30),
        LiteObstacle(15.5, 14.8, 1.65, 1.6),
        LiteObstacle(22.5, 8.2, 1.7, 1.9, breakable: true, hp: 25),
      ]);
    switch (phase) {
      case LiteSolarPhase.courtyard:
        _spawnEnemy(LiteEnemyKind.guardiaSolare, const Point(23, 8));
        _spawnEnemy(LiteEnemyKind.guardiaSolare, const Point(25.4, 14.8));
        message = 'Dungeon solare · Primo cortile.';
      case LiteSolarPhase.guard:
        _spawnEnemy(LiteEnemyKind.eliteSolare, const Point(26.8, 11));
        _spawnEnemy(LiteEnemyKind.guardiaSolare, const Point(22, 5.5));
        _spawnEnemy(LiteEnemyKind.guardiaSolare, const Point(23.4, 15.5));
        _spawnEnemy(LiteEnemyKind.aberrazioneSolare, const Point(27, 14.8));
        message = 'Dungeon solare · Elité, due Guardie e un’Aberrazione.';
      case LiteSolarPhase.boss:
        _spawnEnemy(LiteEnemyKind.guardianoSolare, const Point(27.8, 11));
        message = 'Il Guardiano Solare si risveglia.';
      case LiteSolarPhase.rest || LiteSolarPhase.cleared:
        break;
    }
  }

  void _awardPartyObser(int reward) {
    obser += reward;
    for (final fighter in coopFighters) {
      if (fighter.connected) fighter.obser += reward;
    }
  }

  bool _advanceSolarEncounter() {
    switch (solarPhase) {
      case LiteSolarPhase.courtyard:
        achievements.add(LiteRun.heroUnlockKey(LiteHero.guardiaSolare));
        _solarWave(LiteSolarPhase.guard);
        return true;
      case LiteSolarPhase.guard:
        achievements.add(LiteRun.heroUnlockKey(LiteHero.eliteSolare));
        _awardPartyObser(72);
        solarPhase = LiteSolarPhase.rest;
        stageClear = true;
        _openSupplyRoom();
        message = 'Guardie sconfitte · +72 Obser. Ristoro prima del Guardiano Solare.';
        return true;
      case LiteSolarPhase.boss:
        achievements.add(LiteRun.heroUnlockKey(LiteHero.guardianoSolare));
        achievements.add(LiteRun.heroUnlockKey(LiteHero.aberrazioneSolare));
        _awardPartyObser(96);
        solarPhase = LiteSolarPhase.cleared;
        stageClear = true;
        achievements.add('guardiano-solare-sconfitto');
        message = 'Guardiano Solare sconfitto · +96 Obser. Il portale riporta alla run.';
        return true;
      case LiteSolarPhase.rest || LiteSolarPhase.cleared || null:
        return false;
    }
  }

  void _solarVolley(LiteEnemy enemy, Point<double> direction, double damage) {
    if (enemy.kind == LiteEnemyKind.eliteSolare) {
      _fireSun(enemy.position, direction, damage, enemy: true, ray: true);
      return;
    }
    final mode = enemy.combatCycle % 3;
    enemy.combatCycle++;
    if (mode == 2) {
      _astralImpact(enemy.position + direction * 1.1, 2.9, damage * 1.3);
      return;
    }
    _fireSun(
      enemy.position,
      direction,
      damage * (mode == 1 ? 1.05 : .72),
      enemy: true,
      ray: mode == 1,
    );
  }

  void _fireSun(
    Point<double> origin,
    Point<double> direction,
    double damage, {
    int? owner,
    bool enemy = false,
    bool ray = false,
  }) {
    final heading = atan2(direction.y, direction.x);
    final offsets = ray ? const [0.0] : const [-.115, .115];
    for (final spread in offsets) {
      final angle = heading + spread;
      projectiles.add(
        LiteProjectile(
          position: origin,
          direction: Point(cos(angle), sin(angle)),
          speed: ray ? 32 : 16,
          remaining: ray ? 16 : 13,
          damage: damage,
          fromEnemy: enemy,
          magic: true,
          kind: ray
              ? LiteProjectileKind.solarRay
              : LiteProjectileKind.solarBolt,
          ownerCanHeal: !enemy && owner == null,
          sourceCloneId: owner,
        ),
      );
    }
  }

  void _astralImpact(
    Point<double> at,
    double radius,
    double damage, {
    bool paint = true,
  }) {
    if (paint) _recordImpact(LiteImpactTarget.explosion, _nextId++, at);
    if (at.distanceTo(position) < radius && !_lineBlocked(at, position)) {
      _damagePlayer(damage);
    }
    for (final ally in _damageableAllies) {
      if (ally.hp > 0 &&
          at.distanceTo(ally.position) < radius &&
          !_lineBlocked(at, ally.position)) {
        _hitAlly(ally, damage);
      }
    }
  }

  void _solarPlayerGuard(
    LiteHero character,
    Point<double> at,
    Point<double> direction,
    LiteCoopFighter? fighter,
    int grade, {
    bool open = false,
  }) {
    final power = open ? LiteRun.openPower : 1.0;
    var landing = at;
    if (character == LiteHero.aberrazioneSolare) {
      (fighter?._night ?? _night).solarMantle = 2.25 + grade * .5;
      if (fighter == null) {
        shield += (8 + 5 * grade) * power;
      } else {
        fighter.shield += (8 + 5 * grade) * power;
      }
    } else {
      landing = _playableShadowStep(
        at,
        direction,
        fighter,
        distance: 2.1 + grade * .32,
        protection: .25,
      );
    }
    _openBurst(
      landing,
      2.2,
      (12 + grade * 5) * power,
      fighter?.id ?? 0,
      push: 1.2,
    );
  }

  void _sunGlare(Point<double> at, Point<double> direction, int? owner) {
    for (final enemy in enemies) {
      if (enemy.hp <= 0 ||
          enemy.kind.boss ||
          !LiteRun._inArc(at, direction, enemy.position, 3.4, minDot: .55) ||
          _lineBlocked(at, enemy.position))
        continue;
      enemy.stunned = max(.65, enemy.stunned);
      _hitEnemy(enemy, 11, ownerCanHeal: owner == null, sourceCloneId: owner);
    }
    _recordImpact(LiteImpactTarget.explosion, _nextId++, at + direction);
  }
}
