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
    LiteThirdRoom(LiteThirdRegion.nuvole, 'Versante dei parafulmini', [
      LiteEnemyKind.nymboryth,
      LiteEnemyKind.lapysrieth,
      LiteEnemyKind.lapysrieth,
      LiteEnemyKind.dronePostea,
    ], well: true),
    LiteThirdRoom(LiteThirdRegion.nuvole, 'Occhio del cumulonembo', [
      LiteEnemyKind.aerovyr,
      LiteEnemyKind.lapysrieth,
      LiteEnemyKind.lapysrieth,
    ]),
  ];

  bool get inThirdAct => thirdRoom > 0;
  String get arenaLabel => switch (thirdEncounter) {
    final room? =>
      'Atto III · $thirdRoom/${rooms.length} · ${room.region.label} · ${room.label}',
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
      11 => LiteEnemyKind.dronePostea,
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
      if (i == championIndex) _seatChampion(enemy);
    }
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
      message = 'Aerovyr sconfitto. Le Nuvole Rocciose sono libere.';
    } else {
      _offerPowers();
      message = '${thirdEncounter!.label} superata. Raggiungi il portale.';
    }
    return true;
  }

  bool _tickThirdEnemy(LiteEnemy enemy, double elapsed) {
    final kind = enemy.kind;
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
    if (enemy.windup > 0) {
      enemy.windup = max(0, enemy.windup - elapsed);
      if (enemy.windup > 0) return true;
      final center = enemy.attackTarget!;
      final direction = LiteRun._unit(center - enemy.position);
      final damage =
          kind.damage *
          difficulty.enemyStrength *
          _challengeDamageScale(kind) *
          1.9;
      final enraged = enemy.hp < enemy.maxHp * .5;
      enemy.cooldown = profile.$3 * (enraged ? .74 : 1);
      switch (kind) {
        case LiteEnemyKind.vegliante:
        case LiteEnemyKind.vesanybel:
          _astralImpact(center, kind.boss ? 2.15 : 1.48, damage);
          if (kind.boss && enraged) {
            _astralImpact(enemy.position, 2.9, damage * .68);
          }
        case LiteEnemyKind.gelycryn:
        case LiteEnemyKind.thalvyr:
          final swim = center;
          enemy.position = swim;
          _astralImpact(swim, kind.boss ? 2.75 : 1.85, damage);
          if (kind.boss) {
            for (final spread in [-.55, .0, .55]) {
              _thirdShot(enemy, _rotate(direction, spread), damage * .56, 7.5);
            }
          }
        case LiteEnemyKind.nymboryth:
        case LiteEnemyKind.aerovyr:
          final arcs = kind.boss
              ? (enraged ? [-.72, -.36, .0, .36, .72] : [-.44, .0, .44])
              : [-.22, .0, .22];
          for (final spread in arcs) {
            _thirdShot(enemy, _rotate(direction, spread), damage * .78, 11);
          }
        default:
          break;
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
      enemy.attackTarget =
          kind == LiteEnemyKind.gelycryn || kind == LiteEnemyKind.thalvyr
          ? _chooseLane(
              enemy.position,
              toward,
              min(3.7, distance),
              enemy.radius,
              rightFirst: enemy.id.isEven,
            )
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
          (open ? 24 : 10) + grade * 5.0,
          owner ?? 0,
          push: open ? 2.4 : .7,
        );
      case LiteHero.aerovyr:
        final arcs = open ? [-.54, -.27, .0, .27, .54] : [-.13, .13];
        for (final arc in arcs) {
          _launchSphere(
            source,
            _rotate(direction, arc),
            10 + grade * 3.0,
            owner,
          );
        }
      case LiteHero.vedettaEiva:
        if (open) {
          _playableShadowStep(
            source,
            direction,
            fighter,
            distance: 4.1 + grade * .4,
            protection: .28,
          );
        }
        final at = fighter?.position ?? position;
        _melee(
          at,
          direction,
          LiteWeapon.piccaOssidiana,
          (open ? 26 : 13) + grade * 5.0,
          sourceCloneId: owner,
          ownerCanHeal: owner == null,
          reach: open ? 4.8 : 3.6,
          minDot: open ? .30 : .68,
        );
      default:
        break;
    }
  }

  bool _eliteCanBefriend(LiteHero character) =>
      character == LiteHero.cavaliereLunare ||
      character == LiteHero.eliteSolare;

  void _befriendWolves() {
    if (!enemies.any(
      (enemy) => enemy.kind == LiteEnemyKind.lupoLunare && enemy.hp > 0,
    )) {
      return;
    }
    final hostQualifies = !hostDown && _eliteCanBefriend(hero);
    final guest = coopFighters
        .where(
          (fighter) =>
              fighter.connected &&
              fighter.hp > 0 &&
              _eliteCanBefriend(fighter.hero),
        )
        .firstOrNull;
    if (!hostQualifies && guest == null) return;
    for (final wolf in enemies.where(
      (enemy) => enemy.kind == LiteEnemyKind.lupoLunare && enemy.hp > 0,
    )) {
      clones.add(
        LiteClone(
          wolf.position,
          wolf.hp,
          LiteWeapon.guanti,
          companion: LiteCompanion.lupoAlleato,
          id: wolf.id,
          maxHp: wolf.maxHp,
          damageScale: 1 + .10 * stage,
        ),
      );
      _progressQuest(0);
    }
    enemies.removeWhere(
      (enemy) => enemy.kind == LiteEnemyKind.lupoLunare && enemy.hp > 0,
    );
    message = 'I Lupi Lunari vi seguono fino all’uscita di questa sala.';
  }

  void _dismissRoomWolves() => clones.removeWhere(
    (clone) => clone.companion == LiteCompanion.lupoAlleato,
  );

  bool get hasPowerWell {
    if (restHub || inSolarDungeon || goblinCamp || finished) return false;
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
