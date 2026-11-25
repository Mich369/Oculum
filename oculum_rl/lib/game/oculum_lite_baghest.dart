part of 'oculum_lite_run.dart';

extension LiteRedCorruption on LiteRun {
  bool get showsBaghestAltar =>
      !finished &&
      !usesSubArena &&
      stage >= 6 &&
      biome == LiteBiome.dungeon &&
      secretRoomRevealed &&
      !achievements.contains('baghest-sfidato');

  bool get canChallengeBaghest =>
      showsBaghestAltar &&
      stageClear &&
      !hostDown &&
      position.distanceTo(LiteRun.secretCache) < 1.6;

  bool get baghestFight => _baghestEncounter == inputArena;

  bool challengeBaghest() {
    if (!canChallengeBaghest || !achievements.add('baghest-sfidato'))
      return false;
    _baghestEncounter = inputArena;
    stageClear = false;
    _spawnEnemy(LiteEnemyKind.baghest, const Point(20, 10.5)).cooldown = 1.6;
    _spawnEnemy(LiteEnemyKind.corrottoRosso, const Point(18, 8.4));
    _spawnEnemy(LiteEnemyKind.corrottoRosso, const Point(19, 13.6));
    message = 'Baghest · Eiva della Corruzione Rossa.';
    return true;
  }

  int gripRemaining([LiteCoopFighter? fighter]) =>
      _redGrips[fighter?.id ?? 0] ?? 0;

  bool shakeRedGrip([LiteCoopFighter? fighter]) {
    final id = fighter?.id ?? 0;
    final presses = _redGrips[id] ?? 0;
    if (presses == 0 || (fighter?.hp ?? hp) <= 0) return false;
    if (presses == 1) {
      _redGrips.remove(id);
      message = 'Presa di Baghest spezzata.';
    } else {
      _redGrips[id] = presses - 1;
    }
    return true;
  }

  void _completeBaghest() {
    if (clones.any((ally) => ally.corrupted && ally.hp > 0)) return;
    _baghestEncounter = null;
    _redGrips.clear();
    stageClear = true;
    if (achievements.add('baghest-sconfitto')) {
      _awardPartyObser(45);
      crystals++;
      message = 'Baghest sconfitto · 45 Obser e un Sigillo.';
    }
  }

  void _gripTick(double elapsed) {
    if (_redGrips.isEmpty ||
        ((time - elapsed) / .72).floor() == (time / .72).floor())
      return;
    for (final id in _redGrips.keys.toList()) {
      final held = _coopFighterById(id);
      if ((held?.hp ?? (id == 0 ? hp : 0)) <= 0) {
        _redGrips.remove(id);
        continue;
      }
      final at = held?.position ?? position;
      final nearby = coopFighters
          .where(
            (guest) =>
                guest.id != id &&
                guest.connected &&
                guest.hp > 0 &&
                at.distanceTo(guest.position) < 4.5 &&
                !_lineBlocked(at, guest.position),
          )
          .firstOrNull;
      if (nearby != null) {
        _hitAlly(nearby, 10);
      } else if (id != 0 &&
          !hostDown &&
          at.distanceTo(position) < 4.5 &&
          !_lineBlocked(at, position)) {
        _damagePlayer(10);
      } else if (held != null) {
        _hitAlly(held, 6);
      } else {
        _damagePlayer(6);
      }
    }
  }

  void _redShock(LiteEnemy boss, Point<double> mark) {
    final recruit = clones
        .where(
          (ally) =>
              ally.hp > 0 &&
              ally.companion != null &&
              ally.expiresAfter == null &&
              !ally.corrupted &&
              ally.position.distanceTo(mark) < 4.8 &&
              !_lineBlocked(boss.position, ally.position),
        )
        .firstOrNull;
    if (recruit != null) {
      recruit.corrupted = true;
      message =
          'Corruzione Rossa · Abbatti il compagno e poi tieni R per rialzarlo.';
      return;
    }
    void hold(int id, Point<double> at, bool protected) {
      if (!protected &&
          at.distanceTo(mark) < 1.65 &&
          !_lineBlocked(boss.position, at))
        _redGrips.putIfAbsent(id, () => 5);
    }

    if (!hostDown) hold(0, position, invulnerable);
    for (final guest in coopFighters) {
      if (guest.connected && guest.hp > 0)
        hold(guest.id, guest.position, guest.protected);
    }
    if (_redGrips.isNotEmpty)
      message = 'Presa di Baghest · Premi R ripetutamente.';
  }

  void _baghestTick(LiteEnemy boss, double elapsed) {
    final target = _closestRedTarget(boss.position);
    final delta = target - boss.position;
    if (boss.windup > 0) {
      boss.windup = max(0, boss.windup - elapsed);
      if (boss.windup > 0) return;
      final mark = boss.attackTarget ?? target;
      boss._strikePose = .24;
      boss.cooldown = 2.0;
      if (boss.combatCycle % 3 == 1) {
        _redShock(boss, mark);
      } else {
        for (var i = -2; i <= 2; i++) {
          projectiles.add(
            LiteProjectile(
              position: boss.position,
              direction: _rotate(LiteRun._unit(mark - boss.position), i * .23),
              speed: 10.8,
              remaining: 11,
              damage: boss.kind.damage * .72,
              fromEnemy: true,
              magic: true,
            ),
          );
        }
      }
      return;
    }
    boss.cooldown = max(0, boss.cooldown - elapsed);
    if (boss.cooldown <= 0 &&
        delta.magnitude <= 7.5 &&
        !_lineBlocked(boss.position, target)) {
      boss.combatCycle++;
      boss.attackTarget = target;
      boss.windup = boss.combatCycle % 3 == 1 ? 1.12 : .68;
    } else if (delta.magnitude > 3.8) {
      boss.position = _chooseLane(
        boss.position,
        LiteRun._unit(delta),
        elapsed * boss.kind.speed,
        boss.radius,
        rightFirst: boss.id.isEven,
      );
    }
  }

  Point<double> _closestRedTarget(Point<double> from) {
    Point<double>? nearest = hostDown ? null : position;
    for (final guest in coopFighters) {
      if (!guest.connected || guest.hp <= 0) continue;
      if (nearest == null ||
          guest.position.distanceTo(from) < nearest.distanceTo(from)) {
        nearest = guest.position;
      }
    }
    return nearest ?? position;
  }

  void _redAllyTick(LiteClone clone, double elapsed) {
    final target = _closestRedTarget(clone.position);
    final delta = target - clone.position;
    final direction = LiteRun._unit(delta);
    clone.cooldown = max(0, clone.cooldown - elapsed);
    if (delta.magnitude > 3.2 || _lineBlocked(clone.position, target)) {
      clone.position = _chooseLane(
        clone.position,
        direction,
        elapsed * 4.1,
        .35,
        rightFirst: clone.id.isEven,
      );
    } else if (clone.cooldown <= 0) {
      clone.cooldown = 1.0;
      clone._poseAim = direction;
      clone._swing = .21;
      projectiles.add(
        LiteProjectile(
          position: clone.position,
          direction: direction,
          speed: 14,
          remaining: 3.8,
          damage: 11,
          fromEnemy: true,
        ),
      );
    }
  }

  void _hitRedAlly(LiteClone clone, double damage) {
    final life = min(clone.hp, damage);
    clone._takeDamage(damage);
    _recordImpact(LiteImpactTarget.ally, clone.id, clone.position, life: life);
    if (clone.hp > 0) return;
    clone.corrupted = false;
    clone.downRemaining = max(clone.downRemaining, 18);
    message = 'Presa spezzata · Tieni R per rialzare il compagno.';
  }
}
