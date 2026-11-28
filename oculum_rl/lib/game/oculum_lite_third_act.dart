part of 'oculum_lite_run.dart';

enum LiteThirdRegion {
  oblio('Oblio', 'Cripta della Campana Cieca'),
  sommerso('Regno Sommerso', 'Cappelle di Roccia'),
  nuvole('Nuvole Rocciose', 'Passerelle del Cumulonembo');

  const LiteThirdRegion(this.label, this.place);
  final String label, place;
}

class LiteThirdRoom {
  const LiteThirdRoom(
    this.region,
    this.label,
    this.enemies, {
    this.well = false,
  });
  final LiteThirdRegion region;
  final String label;
  final List<LiteEnemyKind> enemies;
  final bool well;
}

typedef LiteThirdImpact = ({
  Point<double> center,
  double radius,
  double damageScale,
});

extension LiteThirdStrike on LiteEnemy {
  List<LiteThirdImpact> thirdGroundImpacts({bool landed = false}) {
    final mark = attackTarget;
    if (mark == null) return const [];
    return switch (kind) {
      LiteEnemyKind.vegliante => [
        (center: mark, radius: 1.48, damageScale: 1.0),
      ],
      LiteEnemyKind.vesanybel => [
        (center: mark, radius: 2.15, damageScale: 1.0),
        if (hp < maxHp * .5) (center: position, radius: 2.9, damageScale: .68),
      ],
      LiteEnemyKind.gelycryn => [
        (center: landed ? position : mark, radius: 1.85, damageScale: 1.0),
      ],
      LiteEnemyKind.thalvyr => [
        (center: landed ? position : mark, radius: 2.75, damageScale: 1.0),
      ],
      _ => const [],
    };
  }

  List<double> get thirdShotAngles => switch (kind) {
    LiteEnemyKind.nymboryth => const [-.22, 0, .22],
    LiteEnemyKind.aerovyr when hp < maxHp * .5 => const [
      -.72,
      -.36,
      0,
      .36,
      .72,
    ],
    LiteEnemyKind.aerovyr => const [-.44, 0, .44],
    _ => const [],
  };
}

extension LiteThirdAct on LiteRun {
  static const rooms = [
    LiteThirdRoom(LiteThirdRegion.oblio, 'Archi abrasi', [
      LiteEnemyKind.funerys,
      LiteEnemyKind.gablyn,
      LiteEnemyKind.funerys,
    ], well: true),
    LiteThirdRoom(LiteThirdRegion.oblio, 'Navata delle catene', [
      LiteEnemyKind.funerys,
      LiteEnemyKind.vegliante,
      LiteEnemyKind.gablyn,
    ]),
    LiteThirdRoom(LiteThirdRegion.oblio, 'Cappelle senza eco', [
      LiteEnemyKind.vegliante,
      LiteEnemyKind.funerys,
      LiteEnemyKind.funerys,
      LiteEnemyKind.gablyn,
    ], well: true),
    LiteThirdRoom(LiteThirdRegion.oblio, 'Pozzo della Campana Cieca', [
      LiteEnemyKind.vesanybel,
      LiteEnemyKind.funerys,
    ]),
    LiteThirdRoom(LiteThirdRegion.sommerso, 'Cappella allagata', [
      LiteEnemyKind.sacrycrab,
      LiteEnemyKind.rasvyr,
      LiteEnemyKind.sacrycrab,
    ], well: true),
    LiteThirdRoom(LiteThirdRegion.sommerso, 'Scalinata di brina', [
      LiteEnemyKind.sacrycrab,
      LiteEnemyKind.gelycryn,
      LiteEnemyKind.rasvyr,
    ]),
    LiteThirdRoom(LiteThirdRegion.sommerso, 'Altari di bassa marea', [
      LiteEnemyKind.gelycryn,
      LiteEnemyKind.sacrycrab,
      LiteEnemyKind.rasvyr,
      LiteEnemyKind.sacrycrab,
    ], well: true),
    LiteThirdRoom(LiteThirdRegion.sommerso, 'Abside delle maree', [
      LiteEnemyKind.thalvyr,
      LiteEnemyKind.sacrycrab,
    ]),
    LiteThirdRoom(LiteThirdRegion.nuvole, 'Passerelle sospese', [
      LiteEnemyKind.lapysrieth,
      LiteEnemyKind.lapysrieth,
      LiteEnemyKind.dronePostea,
    ], well: true),
    LiteThirdRoom(LiteThirdRegion.nuvole, 'Colonne del temporale', [
      LiteEnemyKind.nymboryth,
      LiteEnemyKind.lapysrieth,
      LiteEnemyKind.lapysrieth,
    ]),
    LiteThirdRoom(LiteThirdRegion.nuvole, 'Occhio del cumulonembo', [
      LiteEnemyKind.aerovyr,
      LiteEnemyKind.lapysrieth,
      LiteEnemyKind.lapysrieth,
    ]),
  ];

  bool get inThirdAct => thirdRoom > 0;
  String get arenaLabel => switch (thirdEncounter) {
    null when inDesertEye =>
      'Occhio del Deserto · Fortuna $desertEyeFortune/20 · ${desertEyeOutcome!.label}$desertEyeCutLabel',
    final room? when thirdRoom == rooms.length => 'Piano 36 · ${room.label}',
    final room? =>
      'Piano ${LiteRun.finalStage + 1 + thirdRoom} · ${room.region.label} · ${room.label}',
    null when realm != null =>
      'Atto II · ${realm!.label} · $actRoom/${LiteSecondAct.actTwoRooms}',
    _ => 'Piano $stage/$lastStage · ${biome.label}',
  };
  LiteThirdRoom? get thirdEncounter => inThirdAct ? rooms[thirdRoom - 1] : null;
  bool get canEnterThirdAct =>
      victorious &&
      !dead &&
      !inThirdAct &&
      stage == LiteRun.finalStage &&
      achievements.contains('campagna-completata');

  bool enterThirdAct() {
    if (!canEnterThirdAct) return false;
    victorious = false;
    thirdRoom = 1;
    _openThirdRoom();
    return true;
  }

  bool advanceThirdAct({bool remote = false}) {
    if (!inThirdAct ||
        thirdRoom >= rooms.length ||
        finished ||
        !stageClear ||
        (remote ? playerCount < 2 : hostDown || !hasPortalNearby)) {
      return false;
    }
    thirdRoom++;
    _openThirdRoom();
    return true;
  }

  void _openThirdRoom() {
    final room = thirdEncounter!;
    _consumeMealForVisit();
    _clearArenaActions();
    stageClear = shopOpen = restHub = restUsed = false;
    _registerOpenRoom();
    arenaTrial = null;
    enemies.clear();
    fauna.clear();
    _chickenTrial.clear();
    _optionalMissions.clear();
    quests
      ..clear()
      ..addAll([
        LiteQuest(
          'iii:$thirdRoom:ondata',
          'Supera lo scontro',
          room.enemies.length,
          4,
        ),
        LiteQuest('iii:$thirdRoom:bottino', 'Raccogli il bottino', 2, 6),
        LiteQuest('iii:$thirdRoom:conquista', 'Conquista la sala', 1, 20),
      ]);
    obstacles.clear();
    loot.clear();
    projectiles.clear();
    groundShots.clear();
    _activeBeam = null;
    _combatImpacts.clear();
    _powerOffers.clear();
    _hitProtectionRemaining = _attackCooldown = 0;
    position = LiteRun._spawn;
    stride._reset();
    if (hostDown) hp = maxHp * .30;
    for (var i = 0; i < coopFighters.length; i++) {
      final fighter = coopFighters[i];
      fighter.position = _coopSpawn(i);
      fighter.stride._reset();
      fighter.restUsed = false;
      if (fighter.hp <= 0) fighter.hp = fighter.maxHp * .30;
    }
    _dismissRoomWolves();
    clones.removeWhere((clone) => clone.expiresAfter != null);
    for (final clone in clones) {
      clone.position = position + const Point(0, 1.15);
      clone.stride._reset();
    }
    // Three paths per room. Fixed cover anchors preserve room geometry on reload.
    final offset = (thirdRoom - 1) % 4 * .84;
    obstacles.addAll(switch (room.region) {
      LiteThirdRegion.oblio => [
        LiteObstacle(10, 5 + offset, 2.1, 1.7),
        LiteObstacle(14.8, 13.4, 2.6, 1.8, breakable: true),
        LiteObstacle(21, 3.1 + offset, 1.8, 2.1),
        LiteObstacle(23.3, 15.3, 2.3, 1.45, breakable: true),
      ],
      LiteThirdRegion.sommerso => [
        LiteObstacle(9, 3.5, 3.6, 2.6, breakable: true),
        LiteObstacle(14.1 + offset, 10.1, 2.4, 2.2),
        LiteObstacle(19, 16.3, 3.4, 2.2, breakable: true),
        LiteObstacle(24, 6.1 - offset, 2.4, 2.4),
      ],
      LiteThirdRegion.nuvole => [
        LiteObstacle(10.6, 2.4, 1.6, 4.8),
        LiteObstacle(15.8, 15.5 - offset, 2.4, 2.4, breakable: true),
        LiteObstacle(21.5, 5.5 + offset, 1.65, 3.4, breakable: true),
        LiteObstacle(26, 16.6, 2.2, 2.0),
      ],
    });
    _openFloorMap();
    _placeSecretRoom();
    // Each region progresses from its local defender to the named final boss.
    final principal = switch (thirdRoom) {
      1 => LiteEnemyKind.funerys,
      2 => LiteEnemyKind.vegliante,
      3 => LiteEnemyKind.gablyn,
      4 => LiteEnemyKind.vesanybel,
      5 => LiteEnemyKind.sacrycrab,
      6 => LiteEnemyKind.gelycryn,
      7 => LiteEnemyKind.rasvyr,
      8 => LiteEnemyKind.thalvyr,
      9 => LiteEnemyKind.lapysrieth,
      10 => LiteEnemyKind.nymboryth,
      _ => LiteEnemyKind.aerovyr,
    };
    final selected = room.enemies.indexOf(principal);
    final championIndex = selected >= 0 ? selected : room.enemies.length - 1;
    for (var i = 0; i < room.enemies.length; i++) {
      final kind = i == championIndex ? principal : room.enemies[i];
      final x = kind.boss || kind.elite ? 24.8 : 17.3 + (i.isEven ? 0 : 3.3);
      final y = kind.boss ? 11.0 : 4.4 + i * 4.25;
      final enemy = _spawnEnemy(
        kind,
        i == championIndex ? chamberCenter : Point(x, y),
      );
      enemy.cooldown += i * .17;
      if (i == championIndex && kind != LiteEnemyKind.aerovyr)
        _seatChampion(enemy);
    }
    _placeBushAmbush();
    message = 'Atto III · ${room.label} · $thirdRoom/${rooms.length}';
  }

  bool _completeThirdRoom() {
    if (!inThirdAct || stageClear) return false;
    stageClear = true;
    _progressQuest(2);
    final major = thirdEncounter!.enemies.any((kind) => kind.boss);
    if (thirdRoom == 7)
      achievements.add(LiteRun.heroUnlockKey(LiteHero.vedettaEiva));
    _awardPartyObser(major ? 45 : 20);
    if (thirdRoom == rooms.length) {
      projectiles.removeWhere((shot) => shot.fromEnemy);
      victorious = true;
      achievements
        ..add('atto-iii-completato')
        ..add(LiteRun.heroUnlockKey(LiteHero.aerovyr));
      message = 'Piano 36 superato · Aerovyr sconfitto. Le Nuvole Rocciose sono libere.';
    } else {
      _offerPowers();
      message = '${thirdEncounter!.label} superata. Raggiungi il portale.';
    }
    return true;
  }

  static const _leapDistance = 3.7;
  static const _leapTravelSeconds = .22;

  Point<double> _thirdLeapLanding(
    LiteEnemy enemy,
    Point<double> toward,
    double distance,
  ) {
    final start = enemy.position;
    final landing = _chooseLane(
      start,
      toward,
      min(_leapDistance, distance),
      enemy.radius,
      rightFirst: enemy.id.isEven,
    );
    final offset = landing - start;
    final steps = (offset.magnitude / .08).ceil();
    var reachable = start;
    for (var i = 1; i <= steps; i++) {
      final point = start + offset * (i / steps);
      if (_blocked(point, enemy.radius)) break;
      reachable = point;
    }
    return reachable;
  }

  bool _tickThirdEnemy(LiteEnemy enemy, double elapsed) {
    final kind = enemy.kind;
    if (kind == LiteEnemyKind.aerovyr && thirdRoom == rooms.length) {
      _tickAerovyr(enemy, elapsed);
      return true;
    }
    final profile = switch (kind) {
      LiteEnemyKind.vegliante => (6.0, .67, 2.05),
      LiteEnemyKind.vesanybel => (8.2, .92, 2.55),
      LiteEnemyKind.gelycryn => (4.4, .59, 1.75),
      LiteEnemyKind.thalvyr => (6.6, .8, 2.10),
      LiteEnemyKind.nymboryth => (7.2, .63, 1.75),
      LiteEnemyKind.aerovyr => (9.1, .84, 1.95),
      _ => null,
    };
    if (profile == null) return false;
    final leaps =
        kind == LiteEnemyKind.gelycryn || kind == LiteEnemyKind.thalvyr;
    if (enemy.windup > 0 && enemy.attackTarget == null) enemy.windup = 0;
    if (enemy.windup > 0) {
      final center = enemy.attackTarget!;
      final offset = center - enemy.position;
      final direction = LiteRun._unit(offset);
      if (leaps && enemy.windup <= _leapTravelSeconds) {
        // Older checkpoints can store the final windup with the body
        // still at the takeoff point. Give it enough time to travel.
        final travel = offset.magnitude * _leapTravelSeconds / _leapDistance;
        enemy.windup = max(enemy.windup, min(_leapTravelSeconds, travel));
      }
      final travelLeft = min(enemy.windup, _leapTravelSeconds);
      enemy.windup = max(0, enemy.windup - elapsed);
      if (leaps && enemy.windup < travelLeft) {
        final advance = (travelLeft - enemy.windup) / travelLeft;
        final point = enemy.position + offset * advance;
        if (_blocked(point, enemy.radius)) {
          enemy.attackTarget = enemy.position;
        } else {
          enemy.position = point;
        }
      }
      if (enemy.windup > 0) return true;
      enemy._strikePose = .24;
      final damage =
          enemy.attackDamage *
          difficulty.enemyStrength *
          _challengeDamageScale(kind) *
          1.9;
      final enraged = enemy.hp < enemy.maxHp * .5;
      enemy.cooldown = profile.$3 * (enraged ? .74 : 1);
      for (final hit in enemy.thirdGroundImpacts(landed: true)) {
        _astralImpact(hit.center, hit.radius, damage * hit.damageScale);
      }
      if (kind == LiteEnemyKind.thalvyr) {
        for (final spread in const [-.55, 0.0, .55]) {
          _thirdShot(enemy, _rotate(direction, spread), damage * .56, 7.5);
        }
      }
      for (final spread in enemy.thirdShotAngles) {
        _thirdShot(enemy, _rotate(direction, spread), damage * .78, 11);
      }
      return true;
    }
    enemy.cooldown = max(0, enemy.cooldown - elapsed);
    final target = _enemyAimFrom(enemy.position);
    final distance = LiteRun._distance(enemy.position, target);
    final toward = LiteRun._unit(target - enemy.position);
    if (enemy.cooldown <= 0 &&
        distance < profile.$1 &&
        !_lineBlocked(enemy.position, target)) {
      enemy.attackTarget = leaps
          ? _thirdLeapLanding(enemy, toward, distance)
          : target;
      enemy.windup = profile.$2;
      return true;
    }
    final heading = enemy.cooldown > 0 && distance < profile.$1 * .85
        ? _rotate(toward, enemy.id.isEven ? 1.3 : -1.3)
        : toward;
    enemy.position = _chooseLane(
      enemy.position,
      heading,
      elapsed * kind.speed * .88,
      enemy.radius,
      rightFirst: enemy.id.isEven,
    );
    return true;
  }

  void _thirdShot(
    LiteEnemy enemy,
    Point<double> direction,
    double damage,
    double speed,
  ) {
    projectiles.add(
      LiteProjectile(
        position: enemy.position,
        direction: direction,
        speed: speed,
        remaining: 21,
        damage: damage,
        fromEnemy: true,
        magic: true,
        kind: enemy.kind == LiteEnemyKind.thalvyr
            ? LiteProjectileKind.frostBolt
            : LiteProjectileKind.veyrthSphere,
      ),
    );
  }

  void _thirdHeroMove(
    LiteHero actor,
    Point<double> source,
    Point<double> direction,
    LiteCoopFighter? fighter,
    int grade, {
    required bool open,
  }) {
    final owner = fighter?.id;
    final power = open ? LiteRun.openPower : 1.0;
    switch (actor) {
      case LiteHero.vesanybel:
        if (!open) {
          final ward = 5 + 3.0 * grade;
          if (fighter == null) {
            shield += ward;
          } else {
            fighter.shield += ward;
          }
        }
        _openBurst(
          source,
          open ? 3.6 + grade * .4 : 2.1,
          ((open ? 24 : 10) + grade * 5.0) * power,
          owner ?? 0,
          push: open ? 2.4 : .7,
        );
      case LiteHero.aerovyr:
        final arcs = open ? [-.54, -.27, .0, .27, .54] : [-.13, .13];
        for (final arc in arcs) {
          _launchSphere(
            source,
            _rotate(direction, arc),
            (10 + grade * 3.0) * power,
            owner,
          );
        }
      case LiteHero.vedettaEiva:
        var at = source;
        if (open) {
          at = _playableShadowStep(
            source,
            direction,
            fighter,
            distance: 4.1 + grade * .4,
            protection: .28,
          );
        }
        _melee(
          at,
          direction,
          LiteWeapon.piccaOssidiana,
          ((open ? 26 : 13) + grade * 5.0) * power,
          sourceCloneId: owner,
          ownerCanHeal: owner == null,
          reach: open ? 4.8 : 3.6,
          minDot: open ? .30 : .68,
        );
      default:
        break;
    }
  }

  // The party's allegiance is stable during a room, even while a fighter
  // is down or briefly disconnected.
  bool get _wolfHostility =>
      hero.solar || coopFighters.any((member) => member.hero.solar);
  LiteCoopFighter? get _wolfLunarGuest =>
      coopFighters.where((member) => member.hero.lunar).firstOrNull;

  void _syncLunarWolves() {
    if (_wolfHostility) {
      final neutrals = fauna.where(_liveLunarWolf).toList();
      if (neutrals.isNotEmpty) {
        fauna.removeWhere(_liveLunarWolf);
        enemies.addAll(neutrals);
        stageClear = false;
        _powerOffers.clear();
      }
      final allies = clones
          .where(
            (wolf) =>
                wolf.companion == LiteCompanion.lupoAlleato && wolf.hp > 0,
          )
          .toList();
      if (allies.isNotEmpty) {
        _dismissRoomWolves();
        for (final wolf in allies) {
          enemies.add(
            LiteEnemy(
              wolf.id,
              LiteEnemyKind.lupoLunare,
              wolf.position,
              wolf.maxHp,
            )..hp = wolf.hp,
          );
        }
        stageClear = false;
        _powerOffers.clear();
      }
      return;
    }

    final moved = enemies.where(_liveLunarWolf).toList();
    if (moved.isNotEmpty) {
      enemies.removeWhere(_liveLunarWolf);
      fauna.addAll(moved);
      for (final _ in moved) {
        _progressQuest(0);
      }
    }
    final lunar = hero.lunar ? null : _wolfLunarGuest;
    if (!hero.lunar && lunar == null) return;
    final pack = fauna.where(_liveLunarWolf).toList();
    if (pack.isEmpty) return;
    fauna.removeWhere(_liveLunarWolf);
    for (final wolf in pack) {
      clones.add(
        LiteClone(
          wolf.position,
          wolf.hp,
          LiteWeapon.guanti,
          companion: LiteCompanion.lupoAlleato,
          id: wolf.id,
          ownerId: lunar?.id ?? 0,
          maxHp: wolf.maxHp,
          damageScale: 1 + .10 * stage,
        ),
      );
    }
    message = 'I Lupi Lunari combatteranno al vostro fianco in questa sala.';
  }

  bool _liveLunarWolf(LiteEnemy enemy) =>
      enemy.kind == LiteEnemyKind.lupoLunare && enemy.hp > 0;

  void _dismissRoomWolves() => clones.removeWhere(
    (clone) => clone.companion == LiteCompanion.lupoAlleato,
  );

  bool get hasPowerWell {
    if (restHub || inSolarDungeon || goblinCamp || inDesertEye || finished)
      return false;
    if (thirdEncounter case final room?) return room.well;
    if (inActTwo) return actRoom == 1 || actRoom == 3;
    return stage >= 2 && stage < lastStage && (stage - 2) % 3 == 0;
  }

  Point<double> get powerWellPosition => const Point(5.7, 10.5);
  bool get powerWellClaimed => _claimedWell == inputArena;
  bool get canClaimPowerWell => hasPowerWell && stageClear && !powerWellClaimed;
  bool powerWellAt(Point<double> at) =>
      hasPowerWell && at.distanceTo(powerWellPosition) <= 1.1;

  List<LitePowerUp> get powerWellOffers {
    if (!hasPowerWell || powerWellClaimed) return const [];
    final rng = _LiteRandom(
      seed ^ stage * 263 ^ actRoom * 823 ^ thirdRoom * 313,
    );
    final categories = [
      [
        LitePowerUp.lama,
        LitePowerUp.prisma,
        LitePowerUp.occhioLungo,
        LitePowerUp.braci,
      ],
      [
        LitePowerUp.cuore,
        LitePowerUp.pelleRunica,
        LitePowerUp.ferroVivo,
        LitePowerUp.riflusso,
      ],
      [
        LitePowerUp.condotto,
        LitePowerUp.risonanza,
        LitePowerUp.irideVorace,
        LitePowerUp.legameVigile,
        LitePowerUp.passo,
      ],
    ];
    return [
      for (final category in categories)
        if (category
                .where(
                  (power) =>
                      (playerCount == 1 || power.shared) &&
                      powerRank(power) < LitePowerUp.maxRank,
                )
                .toList()
            case final eligible when eligible.isNotEmpty)
          eligible[rng.nextInt(eligible.length)],
    ];
  }

  bool claimPowerWell(LitePowerUp power, {required String arena}) {
    if (hostDown ||
        inputArena != arena ||
        !canClaimPowerWell ||
        !powerWellOffers.contains(power)) {
      return false;
    }
    _claimedWell = inputArena;
    if (powerRank(power) == LitePowerUp.maxRank - 1) _powerOffers.remove(power);
    _grantPower(power);
    message = 'Pozzo · $message';
    return true;
  }
}
