part of 'oculum_lite_run.dart';

typedef _RushBoss = ({LiteEnemyKind kind, int floor});

class _LiteBossRush {
  _LiteBossRush(this.arena, this.roster);

  final String arena;
  final List<_RushBoss> roster;
  final deployed = <int>[];
  double elapsed = 0;
  double? firstDefeat;
  bool completed = false;

  double get thirdAt =>
      firstDefeat != null && firstDefeat! <= 16 + 1e-8 ? 45 : 60;

  Map<String, Object?> get frame => {
    'arena': arena,
    'roster': [
      for (final boss in roster) [boss.kind.name, boss.floor],
    ],
    'elapsed': elapsed,
    'deployed': deployed,
    if (firstDefeat != null) 'firstDefeat': firstDefeat,
    if (completed) 'completed': true,
  };

  static _LiteBossRush? read(Object? raw) {
    if (raw is! Map || raw['arena'] is! String) return null;
    final roster = <_RushBoss>[];
    for (final row in _list(raw['roster']).take(3)) {
      if (row is! List || row.length != 2 || row[1] is! int) return null;
      final kind = LiteEnemyKind.values
          .where((entry) => entry.name == row[0])
          .firstOrNull;
      if (kind == null) return null;
      roster.add((kind: kind, floor: _int(row[1]).clamp(0, 35)));
    }
    if (roster.length != 3) return null;
    final state = _LiteBossRush(raw['arena'] as String, roster)
      ..elapsed = _num(raw['elapsed']).clamp(0, 60)
      ..completed = raw['completed'] == true;
    if (raw['firstDefeat'] case final num first) {
      state.firstDefeat = first.toDouble().clamp(0, 60);
    }
    state.deployed.addAll(_list(raw['deployed']).whereType<int>().take(3));
    if (state.deployed.toSet().length != state.deployed.length ||
        state.deployed.isEmpty)
      return null;
    return state;
  }
}

extension LiteBossRush on LiteRun {
  Point<double> get bossRushGate => const Point(6.35, 11.0);

  bool get bossRushActive =>
      _bossRush?.arena == inputArena && _bossRush?.completed == false;

  bool get hasBossRushGate =>
      explorationRoutes &&
      stage > 12 &&
      stageClear &&
      !finished &&
      !inSolarDungeon &&
      !goblinCamp &&
      !inDesertEye &&
      !restHub &&
      !baghestFight &&
      _bossRush?.arena != inputArena &&
      (seed ^ stage ^ (thirdRoom * 29) ^ (actRoom * 167)) % 4 == 0;

  bool get canEnterBossRush =>
      hasBossRushGate &&
      !hostDown &&
      !shopOpen &&
      position.distanceTo(bossRushGate) <= 2;

  int get bossRushDeployed => bossRushActive ? _bossRush!.deployed.length : 0;

  int? get bossRushSecondsToNext {
    if (!bossRushActive || _bossRush!.deployed.length == 3) return null;
    final rush = _bossRush!;
    final next = rush.deployed.length == 1 ? 30 : rush.thirdAt;
    return max(0, (next - rush.elapsed).ceil());
  }

  List<_RushBoss> _bossesOfPriorAct() {
    final priorRealm = inThirdAct
        ? LiteRealm.values
              .where((realm) => achievements.contains('atto-ii-${realm.name}'))
              .firstOrNull
        : null;
    if (priorRealm == null) {
      return [
        for (final floor in [3, 6, 9])
          (kind: _specialKind(floor), floor: floor),
      ];
    }
    final kinds = switch (priorRealm) {
      LiteRealm.inferno => const [
        LiteEnemyKind.demoneIntermedio,
        LiteEnemyKind.demoneMaggiore,
        LiteEnemyKind.diavolo,
      ],
      LiteRealm.caramella => const [
        LiteEnemyKind.divoramitu,
        LiteEnemyKind.orbryx,
        LiteEnemyKind.divoramituBoss,
      ],
      LiteRealm.postea => const [
        LiteEnemyKind.ragnoSaldatore,
        LiteEnemyKind.miruscyrus,
        LiteEnemyKind.costrutto,
      ],
    };
    return [
      for (final kind in kinds)
        (kind: kind, floor: LiteRun.secondActEntranceFloor),
    ];
  }

  bool enterBossRush() {
    if (!canEnterBossRush) return false;
    _bossRush = _LiteBossRush(inputArena, _bossesOfPriorAct());
    stageClear = false;
    _clearArenaActions();
    projectiles.clear();
    groundShots.clear();
    _bringRushBoss(_bossRush!, 0);
    message = 'Boss Rush · Le uscite sono sigillate.';
    return true;
  }

  void _bringRushBoss(_LiteBossRush rush, int index) {
    final source = rush.roster[index];
    final kind = source.kind;
    final floor = source.floor;
    final earlierHp =
        (kind.health *
                difficulty.enemyStrength *
                (1 + .10 * floor) *
                (1 +
                    LiteRun.enemyLifeBonusAt(floor, late: !_legacyVeyrthFinal) /
                        100) *
                (1 + LiteRun.challengeBonus(floor, kind).life / 100) *
                monsterLifeMultiplier)
            .roundToDouble();
    const arrival = [
      Point<double>(27.65, 8.8),
      Point<double>(27.65, 12.8),
      Point<double>(25.70, 10.8),
    ];
    final enemy = _spawnEnemy(
      kind,
      arrival[index],
      maxHealth: earlierHp,
      alternateLivery: false,
      originFloor: floor,
      applyEnemyBalance: false,
    );
    _seatChampion(enemy, boost: false, originalSeat: floor);
    rush.deployed.add(enemy.id);
  }

  int? _rushOriginalFloor(LiteEnemy enemy) {
    if (!bossRushActive) return null;
    final rush = _bossRush!;
    final index = rush.deployed.indexOf(enemy.id);
    return index < 0 ? null : rush.roster[index].floor;
  }

  double _rushDamageRatio(LiteEnemy enemy) {
    final floor = _rushOriginalFloor(enemy);
    if (floor == null) return 1;
    return (1 +
            LiteRun.enemyDamageBonusAt(floor, late: !_legacyVeyrthFinal) /
                100) /
        _floorDamageScale;
  }

  void _tickBossRush(double elapsed) {
    final rush = _bossRush!;
    rush.elapsed = min(60.0, rush.elapsed + elapsed);
    bool alive(int id) =>
        enemies.any((enemy) => enemy.id == id && enemy.hp > 0);
    final firstDead = !alive(rush.deployed.first);
    if (firstDead) rush.firstDefeat ??= rush.elapsed;
    if (rush.deployed.length == 1 && (firstDead || rush.elapsed >= 30 - 1e-8)) {
      _bringRushBoss(rush, 1);
    }
    if (rush.deployed.length == 2 &&
        (!alive(rush.deployed[1]) || rush.elapsed >= rush.thirdAt - 1e-8)) {
      _bringRushBoss(rush, 2);
    }
    if (rush.deployed.length == 3 && enemies.every((enemy) => enemy.hp <= 0)) {
      rush.completed = true;
      stageClear = true;
      projectiles.removeWhere((shot) => shot.fromEnemy);
      achievements.add('boss-rush-completata');
      _awardBossRushLevel();
      message = 'Boss Rush superata · +1 livello. Le uscite sono aperte.';
    }
  }

  void _awardBossRushLevel() {
    level++;
    if (!hostDown) {
      hp = maxHp;
      oculum = maxOculum;
    }
    for (final fighter in coopFighters) {
      if (!fighter.connected) continue;
      fighter.experience += 45 * fighter.level;
      if (fighter.hp > 0) {
        fighter
          ..hp = fighter.maxHp
          ..oculum = fighter.maxOculum;
      }
    }
  }
}
