part of 'oculum_lite_run.dart';

enum LiteErrato {
  normale(
    'Scostubandito errato',
    LiteHero.scostubanditoErrato,
    LiteCompanion.errato,
  ),
  veterano(
    'Scostubandito veterano dell’errato',
    LiteHero.scostubanditoVeteranoErrato,
    LiteCompanion.erratoVeterano,
  );

  const LiteErrato(this.label, this.hero, this.companion);
  final String label;
  final LiteHero hero;
  final LiteCompanion companion;

  static LiteErrato? rescueRoll(int roll) {
    if (roll < 0 || roll >= 100) return null;
    return roll < 5
        ? veterano
        : roll < 30
        ? normale
        : null;
  }

  static LiteErrato? forHero(LiteHero hero) =>
      values.where((entry) => entry.hero == hero).firstOrNull;
  static LiteErrato? forCompanion(LiteCompanion? actor) =>
      values.where((entry) => entry.companion == actor).firstOrNull;

  double ward(int level) =>
      this == veterano ? 25.0 + 10 * level : 15.0 + 8 * level;
}

class _BanditEscape {
  static const finalRoom = 3;
  static const cannonRadius = 3.85;
  int room = 0;
  final ropes = <int, int>{};
  final guardIds = <int>[];
  int? permanentLoss;
  LiteErrato? rescuer;
  int? warden;
  double reinforcementIn = 60;
  double actionIn = 1.15;
  int volleys = 0;
  bool melee = false;
  Point<double>? target;
  final launches = <int, (Point<double>, double)>{};
  bool won = false;

  Map<String, Object?> get frame => {
    'room': room,
    'ropes': {for (final e in ropes.entries) e.key.toString(): e.value},
    'guards': [...guardIds],
    'permanentLoss': permanentLoss,
    if (rescuer case final ally?) 'rescuer': ally.name,
    'warden': warden,
    'reinforcementIn': reinforcementIn,
    'actionIn': actionIn,
    'volleys': volleys,
    'melee': melee,
    if (target case final mark?) 'target': _savePoint(mark),
    if (launches.isNotEmpty)
      'launches': {
        for (final e in launches.entries)
          e.key.toString(): [_savePoint(e.value.$1), e.value.$2],
      },
    'won': won,
  };

  static _BanditEscape? read(Object? raw) {
    if (raw is! Map || raw['room'] is! int) return null;
    final state = _BanditEscape()
      ..room = _int(raw['room']).clamp(0, finalRoom)
      ..permanentLoss = raw['permanentLoss'] is int
          ? _int(raw['permanentLoss']).clamp(6, 7)
          : null
      ..rescuer = LiteErrato.values
          .where((entry) => entry.name == raw['rescuer'])
          .firstOrNull
      ..warden = raw['warden'] is int ? _int(raw['warden']) : null
      ..reinforcementIn = _num(raw['reinforcementIn'], 60).clamp(0, 60)
      ..actionIn = _num(raw['actionIn']).clamp(0, 3)
      ..volleys = _int(raw['volleys']).clamp(0, 3)
      ..melee = raw['melee'] == true
      ..target = raw['target'] is List ? _point(raw['target']) : null
      ..won = raw['won'] == true;
    state.guardIds.addAll(_list(raw['guards']).take(8).map(_int));
    if (raw['ropes'] case final Map knots) {
      for (final e in knots.entries.take(6)) {
        final id = int.tryParse(e.key.toString());
        if (id != null && id >= 0) {
          state.ropes[id] = _int(e.value).clamp(0, 5);
        }
      }
    }
    if (raw['launches'] case final Map motions) {
      for (final e in motions.entries.take(6)) {
        final id = int.tryParse(e.key.toString());
        if (id != null && e.value is List && (e.value as List).length == 2) {
          final row = e.value as List;
          state.launches[id] = (_point(row[0]), _num(row[1]).clamp(0, 12));
        }
      }
    }
    return state;
  }
}

extension LiteBanditEscape on LiteRun {
  bool get inBanditEscape => _banditEscape != null;
  int get banditEscapeRoom => _banditEscape?.room ?? 0;
  bool get banditEscapeExit => switch (_banditEscape) {
    final camp? =>
      camp.room > 0 && (camp.room < _BanditEscape.finalRoom || camp.won),
    _ => false,
  };
  int get banditReinforcementsIn => _banditEscape?.reinforcementIn.ceil() ?? 0;
  Point<double>? get banditCannonTarget =>
      _banditEscape?.melee == false ? _banditEscape?.target : null;
  double get banditCannonRadius => _BanditEscape.cannonRadius;
  double get banditWardenWindup => _banditEscape?.actionIn ?? 0;

  double banditAirborne([int id = 0]) {
    final forced = _banditEscape?.launches[id];
    return forced == null ? 0 : .93 * sin((1 - forced.$2 / 12) * pi);
  }

  bool _canBanditCapture() =>
      !usesSubArena && !bossRushActive && !baghestFight && stage < lastStage;

  bool _isFromTheBand(LiteHero actor) =>
      actor == LiteHero.scostubandito || actor == LiteHero.granScostumato;

  int banditRopes([LiteCoopFighter? fighter]) =>
      _banditEscape?.ropes[fighter?.id ?? 0] ?? 0;

  bool fightBanditRopes([LiteCoopFighter? fighter]) {
    final camp = _banditEscape;
    if (camp == null || camp.room != 0) return false;
    final id = fighter?.id ?? 0;
    final knots = camp.ropes[id] ?? 0;
    if (knots <= 0 || fighter?.connected == false) return false;
    camp.ropes[id] = knots - 1;
    _freeBanditPartyIfReady();
    return true;
  }

  void _captureBanditParty() {
    _pendingBanditCapture = false;
    final camp = _banditEscape = _BanditEscape()
      ..rescuer = LiteErrato.rescueRoll(_rng.nextInt(100));
    hp = maxHp * .25;
    shield = 0;
    camp.ropes[0] = _isFromTheBand(hero) ? 1 : 5;
    if (!_isFromTheBand(hero)) {
      obser -= (obser * .60).round();
      crystals -= (crystals * .60).round();
      _stealBanditPacks(supply, ownedWeapons, weapon, legacyScrolls: scrolls);
    }
    for (final guest in coopFighters) {
      guest.hp = guest.maxHp * .25;
      guest.shield = 0;
      camp.ropes[guest.id] = _isFromTheBand(guest.hero) ? 1 : 5;
      if (!_isFromTheBand(guest.hero)) {
        guest.obser -= (guest.obser * .60).round();
        _stealBanditPacks(guest.supply, guest.ownedWeapons, guest.weapon);
      }
    }
    if (camp.rescuer case final ally?) {
      clones.add(
        LiteClone(
          const Point(5.6, 10.8),
          ally.companion.life,
          ally.companion.weapon,
          companion: ally.companion,
          id: _nextId++,
        ),
      );
      _seeErrato(ally);
      camp.ropes.updateAll((id, knots) => 1);
    }
    _loadBanditRoom(0);
  }

  void _stealBanditPacks(
    LiteRestLoadout pack,
    Iterable<LiteWeapon> owned,
    LiteWeapon equipped, {
    List<int>? legacyScrolls,
  }) {
    final stock = <Object, int>{
      if (legacyScrolls != null)
        for (var i = 0; i < legacyScrolls.length; i++) i: legacyScrolls[i],
      ...pack.scrolls,
    };
    _stealBanditStacks(stock);
    if (legacyScrolls != null) {
      for (var i = 0; i < legacyScrolls.length; i++) {
        legacyScrolls[i] = stock[i] ?? 0;
      }
    }
    pack.scrolls
      ..clear()
      ..addEntries(
        stock.entries
            .where((e) => e.key is LiteScroll)
            .map((e) => MapEntry(e.key as LiteScroll, e.value)),
      );
    pack.lunarPieces -= (pack.lunarPieces * .60).round();
    final spare = owned.where((item) => item != equipped).toList();
    final lost = spare.take((spare.length * .60).round()).toSet();
    if (owned is List<LiteWeapon>) owned.removeWhere(lost.contains);
    if (owned is Set<LiteWeapon>) owned.removeAll(lost);
    for (final item in lost) {
      pack._forgeRanks.remove(item);
    }
    if (pack._fusion case final pair?
        when lost.contains(pair.primary) || lost.contains(pair.secondary)) {
      pack._fusion = null;
    }
  }

  void _stealBanditStacks<T>(Map<T, int> packs) {
    // Round the sum rather than each slot so singleton scrolls count too.
    final total = packs.values.fold(0, (sum, count) => sum + count);
    var removed = 0;
    var carried = 0;
    for (final key in packs.keys.toList()) {
      carried += packs[key]!;
      final debit = (carried * .60).round() - removed;
      removed += debit;
      final kept = packs[key]! - debit;
      if (kept == 0) {
        packs.remove(key);
      } else {
        packs[key] = kept;
      }
    }
    assert(removed == (total * .60).round());
  }

  LiteEnemy _banditGuardSpawn(int seat, Point<double> at) {
    final kind = seat < 6
        ? LiteEnemyKind.scostubandito
        : LiteEnemyKind.granScostumato;
    return _spawnEnemy(kind, at, alternateLivery: false);
  }

  void _loadBanditRoom(int room) {
    final camp = _banditEscape!;
    camp.room = room;
    camp.launches.clear();
    _clearArenaActions();
    _redGrips.clear();
    _activeBeam = null;
    _hitProtectionRemaining = 0;
    _invulnerability = 0;
    _arenaEventStart = time;
    position = LiteRun._spawn;
    stride._reset();
    stageClear = false;
    enemies.clear();
    fauna.clear();
    loot.clear();
    obstacles.clear();
    projectiles.clear();
    groundShots.clear();
    _combatImpacts.clear();
    for (final clone in clones) {
      clone.position = const Point(4.25, 12.6);
      clone.stride._reset();
    }
    for (final (index, guest) in coopFighters.indexed) {
      guest.position = _coopSpawn(index);
      guest._protection = 0;
      guest.stride._reset();
    }
    if (room == 0) {
      message = camp.rescuer == null
          ? 'Legato al Campo degli Scostubanditi. Premi R per liberarti.'
          : '${camp.rescuer!.label} ti ha svegliato e allentato le corde. Premi R.';
      return;
    }
    if (clones.any(
      (actor) =>
          actor.companion == LiteCompanion.erratoVeterano && actor.hp > 0,
    )) {
      for (final y in [8.2, 13.8]) {
        _spawnEnemy(
            LiteEnemyKind.scostubandito,
            Point(10.3, y),
            alternateLivery: false,
          )
          ..errato = LiteErrato.normale
          ..erratoWard = LiteErrato.normale.ward(1);
      }
    }
    if (room < _BanditEscape.finalRoom) {
      obstacles.addAll([
        LiteObstacle(11, room == 1 ? 7 : 12, 2, 3.2, breakable: true),
        LiteObstacle(18, room == 1 ? 13 : 6.5, 2.1, 3.1, breakable: true),
        LiteObstacle(24.4, 9.4, 1.2, 3.4, breakable: true),
      ]);
      for (var i = 0; i < 3 + room; i++) {
        _banditGuardSpawn(
          i < 3 ? i : 6,
          Point(9.5 + 3.35 * i, i.isEven ? 7 : 15),
        );
      }
      message = 'Fuga dalla palizzata · $room/2 · Raggiungi l’uscita.';
      return;
    }
    obstacles.addAll([
      LiteObstacle(9, 4.2, 1.6, 3.5),
      LiteObstacle(9, 14.3, 1.6, 3.5),
      LiteObstacle(28, 7.3, 1.2, 2.1, breakable: true),
      LiteObstacle(28, 13.0, 1.2, 2.1, breakable: true),
      LiteObstacle(15, 5.4, 1.4, 2.2, breakable: true),
      LiteObstacle(15, 14.9, 1.4, 2.2, breakable: true),
    ]);
    final warden =
        _spawnEnemy(
            LiteEnemyKind.granScostumato,
            const Point(22, 11),
            maxHealth:
                410 *
                difficulty.enemyStrength *
                (1 + stage * .10) *
                monsterLifeMultiplier,
            alternateLivery: false,
          )
          .._banditWarden = true
          ..guard = null;
    camp.warden = warden.id;
    camp.guardIds.addAll([
      for (var seat = 0; seat < 8; seat++)
        _banditGuardSpawn(seat, _banditGuardPost(seat)).id,
    ]);
    message = 'Gran Scostumato Elité · La fuga si apre quando cade.';
  }

  Point<double> _banditGuardPost(int seat) => Point(
    seat < 6 ? 11.0 + (seat ~/ 2) * 3.5 : 25.4,
    seat.isEven ? 7.4 : 14.5,
  );

  bool _advanceBanditEscape(LiteBiome? destination) {
    if (!banditEscapeExit) return false;
    final camp = _banditEscape!;
    if (!camp.won) {
      _loadBanditRoom(camp.room + 1);
      return true;
    }
    _banditEscape = null;
    achievements.add('fuga-dalla-palizzata');
    return _nextFloor(destination);
  }

  void _banditEscapeDefeat(LiteEnemy enemy) {
    final camp = _banditEscape;
    if (camp == null || camp.room != _BanditEscape.finalRoom) return;
    if (enemy.id == camp.warden) {
      camp
        ..won = true
        ..target = null
        ..volleys = 0;
      stageClear = true;
      message = 'Gran Scostumato Elité abbattuto. Raggiungi l’uscita.';
      return;
    }
    if (enemy.kind == LiteEnemyKind.granScostumato &&
        camp.permanentLoss == null) {
      final seat = camp.guardIds.indexOf(enemy.id);
      if (seat >= 6) camp.permanentLoss = seat;
    }
  }

  void _tickBanditReinforcements(double elapsed) {
    final camp = _banditEscape!;
    for (final enemy in enemies) {
      if (enemy.errato case final wrong? when enemy.hp > 0) {
        if (position.distanceTo(enemy.position) <= 8.8 &&
            !_lineBlocked(position, enemy.position))
          _seeErrato(wrong);
        for (final guest in coopFighters) {
          if (guest.connected &&
              guest.hp > 0 &&
              guest.position.distanceTo(enemy.position) <= 8.8 &&
              !_lineBlocked(guest.position, enemy.position)) {
            _seeErrato(wrong, guest: guest);
          }
        }
      }
    }
    if (camp.room != _BanditEscape.finalRoom || camp.won) return;
    camp.reinforcementIn -= elapsed;
    if (camp.reinforcementIn > 1e-8) return;
    camp.reinforcementIn += 60;
    for (var seat = 0; seat < camp.guardIds.length; seat++) {
      if (seat != camp.permanentLoss &&
          !enemies.any(
            (enemy) => enemy.id == camp.guardIds[seat] && enemy.hp > 0,
          )) {
        camp.guardIds[seat] = _banditGuardSpawn(
          seat,
          _banditGuardPost(seat),
        ).id;
      }
    }
  }

  void _seeErrato(LiteErrato actor, {LiteCoopFighter? guest}) {
    final key = LiteRun.heroUnlockKey(actor.hero);
    if (guest != null) {
      achievements.add('$key:${guest.account}');
      return;
    }
    achievements.add(key);
    if (_banditEscape?.room == 0) {
      for (final fighter in coopFighters) {
        if (fighter.connected) achievements.add('$key:${fighter.account}');
      }
    }
  }

  bool _raiseErratoWard(LiteErrato actor, LiteCoopFighter? fighter) {
    final reserve = fighter?.oculum ?? oculum;
    if (reserve < 3 ||
        (fighter?.shield ?? shield) >= actor.ward(fighter?.level ?? level))
      return false;
    if (fighter == null) {
      oculum -= 3;
      shield = actor.ward(level);
    } else {
      fighter.oculum -= 3;
      fighter.shield = actor.ward(fighter.level);
    }
    message = 'Scudo spirituale · ${actor.label}.';
    return true;
  }

  void _erratoOpen(
    LiteHero actor,
    Point<double> at,
    Point<double> direction,
    LiteCoopFighter? fighter,
  ) {
    final wrong = LiteErrato.forHero(actor)!;
    if (wrong == LiteErrato.normale) {
      if (fighter == null) {
        shield = 0;
      } else {
        fighter.shield = 0;
      }
    }
    _melee(
      at,
      direction,
      LiteWeapon.spadaScudo,
      (22 + 3.0 * (fighter?.level ?? level)) * LiteRun.openPower,
      reach: 3.15,
      minDot: .18,
      ownerCanHeal: fighter == null,
      sourceCloneId: fighter?.id,
    );
    projectiles.add(
      LiteProjectile(
        position: at,
        direction: direction,
        speed: 13,
        remaining: 9,
        damage: (18 + 2.0 * (fighter?.level ?? level)) * LiteRun.openPower,
        magic: true,
        sourceCloneId: fighter?.id,
        ownerCanHeal: fighter == null,
        kind: LiteProjectileKind.inkEmber,
      ),
    );
  }

  void _erratoAllyStrike(
    LiteClone ally,
    LiteErrato wrong,
    LiteEnemy enemy,
    Point<double> direction,
    double training,
  ) {
    ally
      ..cooldown = 1.45
      .._poseAim = direction
      .._swing = .25;
    if (ally.erratoWard == 0 && ally.hp < ally.maxHp * .75) {
      ally.erratoWard = wrong.ward(ally.level);
      return;
    }
    final damage = wrong.companion.damage * (1 + training);
    if (ally.position.distanceTo(enemy.position) <= 2.25) {
      _melee(
        ally.position,
        direction,
        LiteWeapon.spadaScudo,
        damage,
        ownerCanHeal: false,
        sourceCloneId: ally.id,
        reach: 2.25,
      );
      return;
    }
    if (wrong == LiteErrato.normale) ally.erratoWard = 0;
    projectiles.add(
      LiteProjectile(
        position: ally.position,
        direction: direction,
        speed: 12,
        remaining: 8,
        damage: damage,
        magic: true,
        kind: LiteProjectileKind.inkEmber,
        ownerCanHeal: false,
        sourceCloneId: ally.id,
      ),
    );
  }

  void _tickHostileErrato(LiteEnemy enemy, double elapsed) {
    enemy.cooldown = max(0, enemy.cooldown - elapsed);
    final target = enemy.guard == null
        ? _enemyAimFrom(enemy.position)
        : _encounterTarget(enemy, elapsed);
    if (target == null) {
      enemy.attackTarget = null;
      return;
    }
    final direction = LiteRun._unit(target - enemy.position);
    final distance = target.distanceTo(enemy.position);
    if (enemy.windup > 0) {
      enemy.windup = max(0, enemy.windup - elapsed);
      if (enemy.windup != 0) return;
      enemy._strikePose = .24;
      final wrong = enemy.errato!;
      if (enemy.combatCycle++ % 3 == 0 && enemy.erratoWard == 0) {
        enemy.erratoWard = wrong.ward(max(1, stage ~/ 3));
      } else {
        if (wrong == LiteErrato.normale) enemy.erratoWard = 0;
        if (distance <= 2.3) {
          _astralImpact(
            enemy.position + direction * .75,
            1.6,
            enemy.attackDamage * difficulty.enemyStrength,
          );
        } else {
          projectiles.add(
            LiteProjectile(
              position: enemy.position,
              direction: direction,
              speed: 10,
              remaining: 9,
              damage: enemy.attackDamage * difficulty.enemyStrength,
              fromEnemy: true,
              magic: true,
              kind: LiteProjectileKind.inkEmber,
            ),
          );
        }
      }
      enemy.cooldown = 1.55;
      return;
    }
    enemy.attackTarget = target;
    if (distance <= 7 && !_lineBlocked(enemy.position, target)) {
      if (enemy.cooldown == 0) enemy.windup = .43;
    } else {
      enemy.position = _chooseLane(
        enemy.position,
        direction,
        elapsed * enemy.kind.speed,
        enemy.radius,
        rightFirst: enemy.id.isEven,
      );
    }
  }

  void _tickBanditWarden(LiteEnemy enemy, double elapsed) {
    final camp = _banditEscape!;
    final aim = _enemyAimFrom(enemy.position);
    camp.actionIn -= elapsed;
    if (camp.actionIn > 0) {
      enemy.windup = camp.target != null ? camp.actionIn : 0;
      return;
    }
    final attack = camp.target;
    if (attack != null) {
      camp.target = null;
      enemy.windup = 0;
      enemy._strikePose = .37;
      final damage =
          (camp.melee ? 28 : 24) * difficulty.enemyStrength * (1 + stage * .07);
      if (camp.melee) {
        _wardenSweep(enemy, attack, damage);
        camp
          ..melee = false
          ..actionIn = 1.12;
      } else {
        _emitWardenImpact(
          LiteImpactTarget.wardenCannon,
          enemy.id,
          attack,
          end: enemy.position,
        );
        _astralImpact(attack, _BanditEscape.cannonRadius, damage, paint: false);
        for (final cover in obstacles.toList()) {
          if (cover.breakable &&
              cover.visibleAt(attack, _BanditEscape.cannonRadius)) {
            _destroyCover(cover);
          }
        }
        camp.volleys--;
        camp.actionIn = camp.volleys > 0 ? .24 : 1.15;
      }
      return;
    }
    if (camp.volleys > 0) {
      camp.target = aim;
      camp.actionIn = .62;
    } else if (enemy.combatCycle.isEven) {
      enemy.combatCycle++;
      camp
        ..volleys = 3
        ..target = aim
        ..actionIn = .82;
    } else if (enemy.position.distanceTo(aim) <= enemy.radius + 2.2) {
      enemy.combatCycle++;
      camp
        ..melee = true
        ..target = aim
        ..actionIn = .48;
    } else {
      enemy.position = _chooseLane(
        enemy.position,
        LiteRun._unit(aim - enemy.position),
        elapsed * 2.65,
        enemy.radius,
        rightFirst: enemy.id.isEven,
      );
    }
    enemy.attackTarget = aim;
    enemy.windup = camp.target != null ? camp.actionIn : 0;
  }

  void _emitWardenImpact(
    LiteImpactTarget target,
    int id,
    Point<double> at, {
    required Point<double> end,
  }) {
    if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
    _combatImpacts.add(LiteCombatImpact(target, id, at, time, end: end));
  }

  bool _freeBanditPartyIfReady() {
    final camp = _banditEscape!;
    if (banditRopes() > 0 ||
        coopFighters.any(
          (fighter) => fighter.connected && (camp.ropes[fighter.id] ?? 0) > 0,
        ))
      return false;
    _loadBanditRoom(1);
    return true;
  }

  void _wardenSweep(LiteEnemy enemy, Point<double> target, double damage) {
    final facing = LiteRun._unit(target - enemy.position);
    final reach = enemy.radius + 2.2;
    bool inSwing(Point<double> at) {
      final delta = at - enemy.position;
      final unit = LiteRun._unit(delta);
      return delta.magnitude <= reach &&
          unit.x * facing.x + unit.y * facing.y >= -.06 &&
          !_lineBlocked(enemy.position, at);
    }

    _emitWardenImpact(
      LiteImpactTarget.wardenSwing,
      enemy.id,
      enemy.position,
      end: enemy.position + facing * reach,
    );
    if (!invulnerable && hp > 0 && inSwing(position)) {
      final before = hp + shield;
      _damagePlayer(damage);
      if (hp > 0 && hp + shield < before) {
        _banditEscape!.launches[0] = (
          LiteRun._unit(position - enemy.position),
          12,
        );
      }
    }
    for (final ally in _damageableAllies) {
      if (ally.hp <= 0 || !inSwing(ally.position)) continue;
      final before = ally.hp + (ally is LiteCoopFighter ? ally.shield : 0);
      _hitAlly(ally, damage);
      if (ally is LiteCoopFighter &&
          ally.hp > 0 &&
          ally.hp + ally.shield < before) {
        ally
          .._dashRemaining = 0
          .._windup = 0
          ..movement = const Point(0, 0)
          ..firing = false;
        _banditEscape!.launches[ally.id] = (
          LiteRun._unit(ally.position - enemy.position),
          12,
        );
      }
    }
  }

  void _tickBanditLaunch(double elapsed) {
    final launches = _banditEscape!.launches;
    for (final id in launches.keys.toList()) {
      final fighter = id == 0 ? null : _coopFighterById(id);
      if ((id != 0 && fighter == null) || (fighter?.hp ?? hp) <= 0) {
        launches.remove(id);
        continue;
      }
      final (direction, remaining) = launches[id]!;
      final origin = fighter?.position ?? position;
      final travel = min(remaining, elapsed * 24);
      final next = origin + direction * travel;
      if (_blocked(next, LiteRun._playerRadius)) {
        final impact = obstacles
            .where((wall) => wall.visibleAt(next, LiteRun._playerRadius))
            .firstOrNull;
        if (impact?.breakable == true) _destroyCover(impact!);
        final collision = 12 * difficulty.enemyStrength;
        if (fighter == null) {
          _damagePlayer(collision, banditCollision: true);
        } else {
          _hitAlly(fighter, collision, banditCollision: true);
        }
        launches.remove(id);
      } else {
        if (fighter == null) {
          position = next;
        } else {
          fighter.position = next;
        }
        if (remaining <= travel + 1e-8) {
          launches.remove(id);
        } else {
          launches[id] = (direction, remaining - travel);
        }
      }
    }
  }
}
