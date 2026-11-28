part of 'oculum_lite_run.dart';

enum LiteGuardMode { ronda, indaga, allerta }

bool _forgetfulBandit(LiteEnemy enemy) =>
    enemy.errato == null &&
    (enemy.kind == LiteEnemyKind.scostubandito ||
        enemy.kind == LiteEnemyKind.granScostumato);

typedef _LiteBanditSighting = ({int subject, Point<double> point});

class LiteGuard {
  LiteGuard(this.post);
  final Point<double> post;
  LiteGuardMode mode = LiteGuardMode.ronda;
  Point<double> facing = const Point(1, 0);
  Point<double>? target;
  double attention = 0;

  Point<double>? lastSeen;
  final _cover = <_LiteObservedCover>[];
  final _bushEntries = <int, int>{};
  final _glimpses = <int, _LiteGlimpse>{};
  final _alertMotion = <int, _LiteAlertMotion>{};
  int _seenHumans = 0;
  int? _attackSubject, _focusSubject;
  _LiteBanditSighting? _banditSighting;
  double _nextScan = 0, _nextPlan = 0;
  double? _arrived;
  Point<double>? _waypoint;
  int get knownObstacleCount => _cover.length;

  List<Object?> get frame => [
    _savePoint(post),
    mode.name,
    _savePoint(facing),
    if (target == null) null else _savePoint(target!),
    attention,
    {
      if (lastSeen case final point?) 'last': _savePoint(point),
      if (_seenHumans != 0) 'seen': _seenHumans,
      if (_attackSubject != null) 'attacking': _attackSubject!,
      if (_focusSubject != null) 'focus': _focusSubject!,
      if (_banditSighting case final sight?)
        'banditSighting': [sight.subject, ..._savePoint(sight.point)],
      if (_alertMotion.isNotEmpty)
        'motion': [
          for (final entry in _alertMotion.entries)
            [entry.key, entry.value.since, entry.value.choice.index],
        ],
      if (_cover.isNotEmpty)
        'cover': _cover.map((stone) => stone.frame).toList(),
      if (_bushEntries.isNotEmpty)
        'bushes': [
          for (final entry in _bushEntries.entries) [entry.key, entry.value],
        ],
      if (_glimpses.isNotEmpty)
        'glimpses': [
          for (final entry in _glimpses.entries)
            [entry.key, ...entry.value.frame],
        ],
      if (_nextScan > 0) 'scan': _nextScan,
      if (_nextPlan > 0) 'plan': _nextPlan,
      if (_arrived != null) 'arrived': _arrived!,
      if (_waypoint case final point?) 'path': _savePoint(point),
    },
  ];

  static LiteGuard? read(Object? state) {
    if (state is! List || state.length < 5) return null;
    final guard = LiteGuard(_point(state[0]))
      ..mode = _enum(LiteGuardMode.values, state[1], LiteGuardMode.ronda)
      ..facing = _point(state[2])
      ..target = state[3] == null ? null : _point(state[3])
      ..attention = _num(state[4]).clamp(0, 16);
    if (state.length < 6 || state[5] is! Map) {
      if (guard.mode == LiteGuardMode.allerta) guard.lastSeen = guard.target;
      return guard;
    }
    final memo = state[5] as Map;
    guard
      ..lastSeen = memo['last'] is List ? _point(memo['last']) : null
      .._seenHumans = _int(memo['seen']) & 63
      .._attackSubject = memo['attacking'] is int
          ? memo['attacking'] as int
          : null
      .._focusSubject = memo['focus'] is int ? memo['focus'] as int : null
      .._nextScan = _num(memo['scan'])
      .._nextPlan = _num(memo['plan'])
      .._arrived = memo['arrived'] is num ? _num(memo['arrived']) : null
      .._waypoint = memo['path'] is List ? _point(memo['path']) : null;
    if (memo['banditSighting'] case [
      final int subject,
      final num x,
      final num y,
    ]) {
      guard._banditSighting = (
        subject: subject,
        point: Point(x.toDouble(), y.toDouble()),
      );
    }
    for (final raw in _list(memo['cover']).take(6)) {
      if (_LiteObservedCover.read(raw) case final stone?)
        guard._cover.add(stone);
    }
    for (final raw in _list(memo['bushes']).take(6)) {
      if (raw is List && raw.length == 2 && raw[0] is int && raw[1] is int) {
        guard._bushEntries[raw[0] as int] = raw[1] as int;
      }
    }
    for (final raw in _list(memo['motion']).take(6)) {
      if (raw is List &&
          raw.length == 3 &&
          raw[0] is int &&
          raw[1] is num &&
          raw[2] is int &&
          (raw[2] as int) >= 0 &&
          (raw[2] as int) < _LiteMotionChoice.values.length) {
        guard._alertMotion[raw[0] as int] = _LiteAlertMotion(_num(raw[1]))
          ..choice = _LiteMotionChoice.values[raw[2] as int];
      }
    }
    for (final raw in _list(memo['glimpses']).take(6)) {
      if (raw is List &&
          raw.length == 3 &&
          raw[0] is int &&
          raw[1] is num &&
          raw[2] is List) {
        guard._glimpses[raw[0] as int] = _LiteGlimpse(
          _num(raw[1]),
          _point(raw[2]),
        );
      }
    }
    return guard;
  }
}

typedef _LiteSeenActor = ({
  int id,
  Point<double> at,
  bool quiet,
  bool active,
  double speed,
  int? bush,
});

enum _LiteMotionChoice { observing, point, brush, ignored }

class _LiteAlertMotion {
  _LiteAlertMotion(this.since);
  final double since;
  _LiteMotionChoice choice = _LiteMotionChoice.observing;
}

class _LiteSpotting {
  double? lastSeen;
  double warningUntil = 0;
  bool visible = false;
  int? bush;

  List<Object?> get frame => [lastSeen, warningUntil, visible, bush];
  static _LiteSpotting? read(Object? raw, double now) {
    if (raw is! List || raw.length != 4) return null;
    return _LiteSpotting()
      ..lastSeen = raw[0] is num ? _num(raw[0]).clamp(0.0, now) : null
      ..warningUntil = _num(raw[1]).clamp(0.0, now + 1.3)
      ..visible = raw[2] == true
      ..bush = raw[3] is int ? raw[3] as int : null;
  }
}

class _LiteObservedCover {
  _LiteObservedCover(this.left, this.top, this.right, this.bottom);
  final double left, top, right, bottom;
  int corners = 0;
  int edges = 0;
  List<Object> get frame => [left, top, right, bottom, corners, edges];

  bool same(LiteObstacle wall) =>
      left == wall.left &&
      top == wall.top &&
      right == wall.left + wall.width &&
      bottom == wall.top + wall.height;

  Point<double> point(int index, double pad) => Point(
    index == 0 || index == 3 ? left - pad : right + pad,
    index < 2 ? top - pad : bottom + pad,
  );

  static _LiteObservedCover? read(Object? raw) {
    if (raw is! List || raw.length != 6 || raw.take(4).any((v) => v is! num)) {
      return null;
    }
    return _LiteObservedCover(
        _num(raw[0]),
        _num(raw[1]),
        _num(raw[2]),
        _num(raw[3]),
      )
      ..corners = _int(raw[4]) & 15
      ..edges = _int(raw[5]) & 15;
  }
}

class _LiteGlimpse {
  _LiteGlimpse(this.since, this.point);
  final double since;
  Point<double> point;
  List<Object> get frame => [since, _savePoint(point)];
}

enum _LiteEnemySenses {
  umano(8.2, 4.9, .39, 1.15, 6.7, .9, .53),
  macchina(9.2, 6.2, .70, 1.04, 4.2, .45, .43),
  predatore(6.2, 3.8, .18, 1.35, 8.15, 1.42, .64),
  gel(4.9, 3.2, .12, 1.15, 5.8, 1.04, .55),
  volante(6.8, 4.1, .20, 1.25, 7.4, .88, .46);

  const _LiteEnemySenses(
    this.sight,
    this.quietSight,
    this.cone,
    this.near,
    this.running,
    this.walking,
    this.coverHearing,
  );
  final double sight, quietSight, cone, near, running, walking, coverHearing;

  static _LiteEnemySenses forKind(LiteEnemyKind kind) => switch (kind) {
    LiteEnemyKind.dronePostea ||
    LiteEnemyKind.ragnoSaldatore ||
    LiteEnemyKind.aberrazioneSolare => macchina,
    LiteEnemyKind.rasvyr ||
    LiteEnemyKind.babyForestDemon ||
    LiteEnemyKind.lupoLunare ||
    LiteEnemyKind.sacrycrab => predatore,
    LiteEnemyKind.armadilloCorazzato => predatore,
    LiteEnemyKind.moscaCampana => volante,
    LiteEnemyKind.slime || LiteEnemyKind.orbryx => gel,
    _ => umano,
  };
}

extension LiteCampStealth on LiteRun {
  bool get quietSteps => _walking;

  bool enemyEngagedForMusic(LiteEnemy enemy) {
    if (enemy.hp <= 0 || restHub || finished) return false;
    final guard = enemy.guard;
    if (guard != null) {
      // A Gran Scostumato can spawn pre-alerted with no actual target.
      return guard.mode == LiteGuardMode.allerta &&
          (!_forgetfulBandit(enemy) ||
              guard._focusSubject != null ||
              guard._attackSubject != null ||
              enemy.attacking);
    }
    return enemy.attacking ||
        (enemy.attackTarget != null && enemy.attackTarget != enemy.position) ||
        (_aggressiveSight[enemy.id]?._seenHumans ?? 0) != 0;
  }

  bool banditBossIntroReady(LiteEnemy enemy) =>
      enemy.guard == null || enemy.guard!._banditSighting != null;

  bool companionConcealed(LiteClone ally) {
    if (ally is LiteCoopFighter || ally.hp <= 0 || ally.corrupted) return false;
    if (_assassinVeiled) return true;
    final owner = _coopFighterById(ally.ownerId);
    if (ally.ownerId != 0 && (owner == null || !owner.connected)) return false;
    if ((owner?.hp ?? hp) <= 0 || bossRushActive) return false;
    var patrolled = false;
    for (final enemy in enemies) {
      if (enemy.hp <= 0) continue;
      final guard = enemy.guard;
      if (guard == null && _immediateObserver(enemy)) return false;
      if (guard == null) continue;
      patrolled = true;
      if (guard.mode == LiteGuardMode.allerta &&
          guard._focusSubject == ally.ownerId)
        return false;
    }
    if (!patrolled) return false;
    final sight = _humanSpotting[ally.ownerId];
    return sight?.visible != true ||
        (sight?.warningUntil ?? 0) > _sightClock + 1e-8;
  }

  void _followWhileHidden(LiteClone ally, double elapsed) {
    final owner = _coopFighterById(ally.ownerId)?.position ?? position;
    final angle = (ally.id % 8) * pi / 4;
    final trail = owner + Point(cos(angle), sin(angle)) * .65;
    final delta = trail - ally.position;
    ally
      .._preparingPose = 0
      .._swing = 0;
    if (delta.magnitude <= .10) return;
    final pace = min(delta.magnitude, _alliedMovementTime(elapsed) * 5.7);
    ally.position = _chooseLane(
      ally.position,
      LiteRun._unit(delta),
      pace,
      .37,
      rightFirst: ally.id.isEven,
    );
  }

  double spottingWarningRemaining([LiteCoopFighter? fighter]) =>
      ((_humanSpotting[fighter?.id ?? 0]?.warningUntil ?? 0) - _sightClock)
          .clamp(0.0, 1.3);

  LiteGuard _sightStateFor(LiteEnemy enemy) =>
      enemy.guard ??
      _aggressiveSight.putIfAbsent(
        enemy.id,
        () => LiteGuard(enemy.position)..mode = LiteGuardMode.allerta,
      );

  Map<String, Object> get _sightFrame {
    final bosses = {
      for (final item in _aggressiveSight.entries)
        if (item.value._seenHumans != 0 ||
            item.value._bushEntries.isNotEmpty ||
            item.value.lastSeen != null)
          item.key.toString(): item.value.frame,
    };
    return {
      'clock': _sightClock,
      if (_sightArena != null) 'arena': _sightArena!,
      if (_humanSpotting.isNotEmpty)
        'actors': {
          for (final item in _humanSpotting.entries)
            item.key.toString(): item.value.frame,
        },
      if (bosses.isNotEmpty) 'bosses': bosses,
    };
  }

  void _restoreSight(Object? raw) {
    if (raw is! Map || raw['arena'] != inputArena) return;
    _sightClock = max(0, _num(raw['clock']));
    _sightArena = inputArena;
    if (raw['actors'] case final Map actors) {
      for (final id in [0, ...coopFighters.map((fighter) => fighter.id)]) {
        if (_LiteSpotting.read(actors[id.toString()], _sightClock)
            case final state?) {
          _humanSpotting[id] = state;
        }
      }
    }
    if (raw['bosses'] case final Map bosses) {
      for (final enemy in enemies.where((enemy) => enemy.guard == null)) {
        if (LiteGuard.read(bosses[enemy.id.toString()]) case final mind?) {
          _aggressiveSight[enemy.id] = mind;
        }
      }
    }
  }

  bool _immediateObserver(LiteEnemy enemy) =>
      enemy.banditWarden ||
      enemy.kind.boss ||
      enemy.kind.elite ||
      enemy.chamberSeat != null;

  void _sampleRoomSight(double elapsed, bool sheltered) {
    _sightClock += elapsed;
    if (_sightArena != inputArena) {
      _sightArena = inputArena;
      _humanSpotting.clear();
      _aggressiveSight.clear();
    }
    final previousRoster = _humanEyes;
    final boxes = {
      if (assassinBoxActive) 0: _assassinBox,
      for (final fighter in coopFighters)
        if (fighter.assassinBoxActive) fighter.id: fighter._assassinBox,
    };
    _humanEyes = [
      (
        id: 0,
        at: position,
        quiet: _walking,
        speed: stride.speed,
        active: !hostDown && _night.bat <= 0 && !inExplorationAtrium(position),
        bush: bushAt(position),
      ),
      for (final fighter in coopFighters)
        (
          id: fighter.id,
          at: fighter.position,
          quiet: fighter.stride.walking == true,
          speed: fighter.stride.speed,
          active:
              fighter.connected &&
              fighter.hp > 0 &&
              fighter._night.bat <= 0 &&
              !inExplorationAtrium(fighter.position),
          bush: bushAt(fighter.position),
        ),
    ];
    final rosterChanged =
        previousRoster.isNotEmpty &&
        (previousRoster.length != _humanEyes.length ||
            _humanEyes.indexed.any(
              (seat) => previousRoster[seat.$1].id != seat.$2.id,
            ));
    if (rosterChanged) {
      _humanSpotting.removeWhere(
        (id, _) => !_humanEyes.any((actor) => actor.id == id),
      );
    }
    var seenByAnyone = 0, seenByImmediate = 0;
    _aggressiveSight.removeWhere(
      (id, _) => !enemies.any((enemy) => enemy.hp > 0 && enemy.id == id),
    );
    for (final enemy in enemies) {
      if (enemy.hp <= 0 ||
          (enemy.guard == null &&
              !_immediateObserver(enemy) &&
              (boxes.isEmpty || enemy.kind.echo))) {
        continue;
      }
      final mind = _sightStateFor(enemy);
      if (enemy.guard == null) {
        if (enemy.attackTarget case final aim?) {
          final facing = LiteRun._unit(aim - enemy.position);
          if (facing.magnitude > 0) mind.facing = facing;
        }
      }
      final previous = rosterChanged ? 0 : mind._seenHumans;
      mind._seenHumans = 0;
      if (rosterChanged) {
        mind._bushEntries.removeWhere(
          (id, _) => !_humanEyes.any((actor) => actor.id == id),
        );
        mind._glimpses.removeWhere(
          (id, _) => !_humanEyes.any((actor) => actor.id == id),
        );
        mind._alertMotion.removeWhere(
          (id, _) => !_humanEyes.any((actor) => actor.id == id),
        );
        if (!_humanEyes.any((actor) => actor.id == mind._focusSubject)) {
          mind._focusSubject = null;
        }
      }
      if (!sheltered) {
        for (final (seat, actor) in _humanEyes.indexed) {
          final previousBush = _humanSpotting[actor.id]?.bush;
          final entered = actor.bush != null && actor.bush != previousBush;
          if (!actor.active || mind._bushEntries[actor.id] != actor.bush) {
            mind._bushEntries.remove(actor.id);
          }
          final box = boxes[actor.id];
          if (!actor.active || _assassinVeiled) {
            box?.witnesses.remove(enemy.id);
            continue;
          }
          if (box != null && !box.witnesses.contains(enemy.id)) continue;
          if (entered &&
              mind.mode == LiteGuardMode.allerta &&
              (previous & (1 << seat)) != 0 &&
              _observerSees(
                enemy,
                mind,
                actor.at,
                actor.quiet,
                ignoreBush: actor.bush,
              )) {
            mind._bushEntries[actor.id] = actor.bush!;
          }
          if (_observerSees(
            enemy,
            mind,
            actor.at,
            box == null && actor.quiet,
            ignoreBush: mind._bushEntries[actor.id],
          )) {
            mind._seenHumans |= 1 << seat;
            if (enemy.guard == null) mind.lastSeen = actor.at;
          } else {
            box?.witnesses.remove(enemy.id);
          }
        }
      } else {
        for (final box in boxes.values) {
          box.witnesses.remove(enemy.id);
        }
      }
      if (enemy.guard != null) _observeAlertMotion(enemy, mind, previous);
      seenByAnyone |= mind._seenHumans;
      if (_immediateObserver(enemy) &&
          (!_forgetfulBandit(enemy) || mind.mode == LiteGuardMode.allerta)) {
        seenByImmediate |= mind._seenHumans;
      }
    }

    for (final (seat, actor) in _humanEyes.indexed) {
      final state = _humanSpotting.putIfAbsent(actor.id, _LiteSpotting.new);
      final observed = (seenByAnyone & (1 << seat)) != 0;
      final urgent = (seenByImmediate & (1 << seat)) != 0;
      if (observed) {
        if (!state.visible &&
            !urgent &&
            state.lastSeen != null &&
            _sightClock - state.lastSeen! >= 10 - 1e-8) {
          state.warningUntil = _sightClock + 1.3;
        }
        if (urgent) state.warningUntil = 0;
        state.lastSeen = _sightClock;
      }
      if (!observed || state.warningUntil <= _sightClock + 1e-8) {
        state.warningUntil = 0;
      }
      state.visible = observed;
      state.bush = actor.bush;
    }
    // A last unresolved glimpse is evaluated once, before the guard acts.
    for (final enemy in enemies) {
      if (enemy.guard case final mind? when enemy.hp > 0) {
        final forgetful = _forgetfulBandit(enemy);
        if (forgetful &&
            mind._focusSubject != null &&
            mind.mode == LiteGuardMode.allerta) {
          final last = _humanSpotting[mind._focusSubject]?.lastSeen;
          if (last != null && _sightClock - last >= 3 - 1e-8) {
            _forgetGuardTarget(mind);
            _alertSignals.enemyTimers.remove(enemy.id);
            enemy.windup = 0;
            enemy.attackTarget = null;
          }
        }
        for (final (seat, actor) in _humanEyes.indexed) {
          final seen = (mind._seenHumans & (1 << seat)) != 0;
          final glimpse = mind._glimpses[actor.id];
          if (seen &&
              (_humanSpotting[actor.id]?.warningUntil ?? 0) > _sightClock &&
              mind.mode != LiteGuardMode.allerta) {
            (mind._glimpses[actor.id] ??= _LiteGlimpse(
              _sightClock,
              actor.at,
            )).point = actor.at;
            continue;
          }
          if (glimpse == null) continue;
          mind._glimpses.remove(actor.id);
          if (seen ||
              mind.mode == LiteGuardMode.allerta ||
              _sightClock - elapsed - glimpse.since < .9 - 1e-8)
            continue;
          final odds =
              _LiteRandom(
                  seed ^
                      (enemy.id * 7253) ^
                      (actor.id * 18859) ^
                      ((glimpse.since * 1000).round() * 3643),
                )
                ..nextDouble()
                ..nextDouble();
          if (odds.nextInt(100) < (forgetful ? 35 : 60)) {
            mind.lastSeen = glimpse.point;
            _rallyGuard(enemy, glimpse.point, LiteGuardMode.indaga);
          }
        }
      }
    }
  }

  void _observeAlertMotion(LiteEnemy enemy, LiteGuard mind, int previousSight) {
    if (mind.mode != LiteGuardMode.allerta || mind._focusSubject == null) {
      mind._alertMotion.clear();
      return;
    }
    for (final (seat, actor) in _humanEyes.indexed) {
      final bit = 1 << seat;
      if (mind._seenHumans & bit == 0) {
        mind._alertMotion.remove(actor.id);
        continue;
      }
      final existing = mind._alertMotion[actor.id];
      if (existing != null && existing.choice != _LiteMotionChoice.observing) {
        continue;
      }
      if (actor.speed <= .12) {
        mind._alertMotion.remove(actor.id);
        continue;
      }
      // Keep following a target the guard already sees continuously.
      if (existing == null &&
          mind._focusSubject == actor.id &&
          previousSight & bit != 0) {
        continue;
      }
      final trace = existing ?? _LiteAlertMotion(_sightClock);
      mind._alertMotion[actor.id] = trace;
      if (_sightClock - trace.since < .9 - 1e-8) continue;
      final roll =
          _LiteRandom(
              seed ^
                  (enemy.id * 19727) ^
                  (actor.id * 7757) ^
                  ((trace.since * 1000).round() * 3511),
            )
            ..nextDouble()
            ..nextDouble();
      final outcome = roll.nextInt(10);
      final forgetful = _forgetfulBandit(enemy);
      if (outcome != 0) {
        trace.choice = forgetful && outcome >= 7
            ? _LiteMotionChoice.ignored
            : _LiteMotionChoice.point;
        continue;
      }

      LiteBush? suspected;
      var closest = 4.0;
      for (final bush in concealmentBushes) {
        final distance = actor.at.distanceTo(bush.center);
        if (distance >= closest ||
            _blocked(bush.center, enemy.radius) ||
            !_observerSees(
              enemy,
              mind,
              bush.center,
              false,
              ignoreBush: bush.id,
            )) {
          continue;
        }
        closest = distance;
        suspected = bush;
      }
      if (suspected == null) {
        trace.choice = forgetful
            ? _LiteMotionChoice.ignored
            : _LiteMotionChoice.point;
        continue;
      }
      trace.choice = _LiteMotionChoice.brush;
      mind
        ..lastSeen = actor.at
        ..target = suspected.center
        ..attention = max(mind.attention, 3)
        .._arrived = null
        .._waypoint = null
        .._nextPlan = 0;
    }
  }

  bool _observerSees(
    LiteEnemy enemy,
    LiteGuard mind,
    Point<double> at,
    bool quiet, {
    int? ignoreBush,
  }) {
    final delta = at - enemy.position;
    final distance = delta.magnitude;
    final senses = _LiteEnemySenses.forKind(enemy.kind);
    if (distance > (quiet ? senses.quietSight : senses.sight)) return false;
    final ownBush = bushAt(enemy.position);
    // Participants sharing a bush still need the cone even at close range.
    if ((ownBush != null || distance >= senses.near) &&
        distance > 1e-9 &&
        (delta.x * mind.facing.x + delta.y * mind.facing.y) / distance <
            senses.cone) {
      return false;
    }
    return !_lineBlocked(enemy.position, at) &&
        !bushBlocksSight(enemy.position, at, ignoreBush: ignoreBush);
  }

  bool _guardCanCompleteAttack(LiteEnemy enemy) {
    if (_assassinVeiled) return false;
    final mind = enemy.guard!;
    final id = mind._attackSubject;
    for (final (seat, actor) in _humanEyes.indexed) {
      if (id != null && actor.id != id) continue;
      if (_boxHiddenFrom(actor.id, enemy.id)) continue;
      if ((mind._seenHumans & (1 << seat)) != 0 &&
          (_humanSpotting[actor.id]?.warningUntil ?? 0) <= _sightClock) {
        return true;
      }
    }
    return clones.any(
      (clone) =>
          clone.hp > 0 &&
          (id == null || clone.id == id) &&
          !clone.corrupted &&
          !companionConcealed(clone) &&
          _guardSees(
            enemy,
            clone.position,
            quiet: clone.stride.walking == true,
          ),
    );
  }

  bool get campPatrols =>
      _mappedFloor != null &&
      biome == LiteBiome.campo &&
      !usesSubArena &&
      !isVeyrthArena &&
      !isFinalFloor;

  bool get campFork =>
      campPatrols &&
      stage == 0 &&
      position.x < 8.8 &&
      position.y >= 7.4 &&
      position.y <= 15.4;

  bool _canPatrol(LiteEnemy enemy) {
    if (enemy.banditWarden) return false;
    if (inBanditEscape && banditEscapeRoom < 3) return true;
    final kind = enemy.kind;
    if (kind == LiteEnemyKind.granScostumato &&
        explorationRoutes &&
        !bossRushActive &&
        enemy.chamberSeat == null) {
      return true;
    }
    if (kind.boss || kind.elite || kind.echo || enemy.chamberSeat != null) {
      return false;
    }
    if (campPatrols && kind == LiteEnemyKind.scostubandito) return true;
    return explorationRoutes &&
        !restHub &&
        !goblinCamp &&
        !inSolarDungeon &&
        !inDesertEye &&
        !baghestFight &&
        kind != LiteEnemyKind.cuccioloDivoramitu &&
        kind != LiteEnemyKind.bunnys &&
        kind != LiteEnemyKind.corrottoRosso &&
        LiteAnimal.forCreature(kind) == null;
  }

  void _setEnemyPerception(LiteEnemy enemy, {bool restoring = false}) {
    if (!_canPatrol(enemy)) {
      enemy.guard = null;
      return;
    }
    if (enemy.guard != null) return;
    final guard = LiteGuard(enemy.position);
    enemy.guard = guard;
    if (enemy.kind == LiteEnemyKind.granScostumato && !inBanditEscape) {
      final direction = LiteRun._unit(position - enemy.position);
      if (direction.magnitude > 0) guard.facing = direction;
      guard
        ..mode = LiteGuardMode.allerta
        ..attention = 12;
      if (restoring && enemy.attackTarget != null) {
        guard.lastSeen = enemy.attackTarget;
        guard.target = enemy.attackTarget;
      }
      return;
    }
    if (campPatrols && enemy.kind == LiteEnemyKind.scostubandito) return;
    final lane = ((seed ^ (enemy.id * 11)) % 3) - 1;
    guard.facing = LiteRun._unit(Point(-.84, lane * .54));
    if (enemy.attackTarget case final target? when restoring) {
      guard.lastSeen = target;
      _rallyGuard(enemy, target, LiteGuardMode.allerta);
    }
  }

  bool _guardSees(LiteEnemy enemy, Point<double> at, {bool quiet = false}) {
    return _observerSees(enemy, enemy.guard!, at, quiet);
  }

  void _rallyGuard(LiteEnemy enemy, Point<double> at, LiteGuardMode mode) {
    final guard = enemy.guard;
    if (guard == null ||
        guard.mode == LiteGuardMode.allerta && mode != LiteGuardMode.allerta)
      return;
    guard
      ..mode = mode
      ..attention = mode == LiteGuardMode.allerta ? 12 : 3.8
      ..target = at;
  }

  void _encounterNoise(Point<double> at, double radius, {LiteEnemy? except}) {
    for (final witness in enemies) {
      if (witness == except || witness.hp <= 0 || witness.guard == null)
        continue;
      final senses = _LiteEnemySenses.forKind(witness.kind);
      final reach = radius * senses.running / _LiteEnemySenses.umano.running;
      final distance = witness.position.distanceTo(at);
      if (distance > reach) continue;
      if (distance <= reach * senses.coverHearing ||
          !_lineBlocked(witness.position, at)) {
        _rallyGuard(witness, at, LiteGuardMode.indaga);
      }
    }
  }

  void _forgetGuardTarget(LiteGuard guard) {
    guard
      ..mode = LiteGuardMode.ronda
      ..attention = 0
      .._focusSubject = null
      .._attackSubject = null
      .._banditSighting = null
      .._alertMotion.clear()
      ..lastSeen = null
      ..target = guard.post
      .._arrived = null
      .._waypoint = null;
  }

  void _relayBanditSighting(LiteEnemy source, _LiteBanditSighting sight) {
    for (final other in enemies) {
      if (other == source || other.hp <= 0 || other.kind.echo) continue;
      final guard = other.guard;
      if (guard == null) {
        if (_immediateObserver(other)) {
          _sightStateFor(other).lastSeen ??= sight.point;
        }
        continue;
      }
      if (guard._seenHumans != 0) continue;
      _rallyGuard(other, sight.point, LiteGuardMode.allerta);
      guard
        ..lastSeen = sight.point
        .._focusSubject = sight.subject
        .._arrived = null
        .._waypoint = null;
    }
  }

  Point<double>? _encounterTarget(LiteEnemy enemy, double elapsed) {
    final guard = enemy.guard!;
    final senses = _LiteEnemySenses.forKind(enemy.kind);
    _observeCover(enemy, guard);
    Point<double>? seen, warningPoint, heard;
    int? seenSubject;
    var seenHuman = false;
    var sightDistance = double.infinity, warningDistance = double.infinity;
    var soundDistance = double.infinity;
    void observe(
      int id,
      Point<double> at, {
      bool warning = false,
      bool human = false,
    }) {
      final distance = enemy.position.distanceTo(at);
      if (warning) {
        if (distance < warningDistance) {
          warningDistance = distance;
          warningPoint = at;
        }
      } else if (distance < sightDistance) {
        sightDistance = distance;
        seen = at;
        seenSubject = id;
        seenHuman = human;
      }
    }

    void hear(Point<double> at, bool quiet, double speed) {
      if (inExplorationAtrium(at)) return;
      final bush = bushAt(at);
      if (bush != null && bush != bushAt(enemy.position)) return;
      final distance = enemy.position.distanceTo(at);
      final reach = quiet ? senses.walking : senses.running;
      if (speed <= .12 || distance >= soundDistance || distance > reach) return;
      if (distance <= reach * senses.coverHearing ||
          !_lineBlocked(enemy.position, at)) {
        heard = at;
        soundDistance = distance;
      }
    }

    for (final (seat, actor) in _humanEyes.indexed) {
      if (!actor.active) continue;
      final motion = guard._alertMotion[actor.id]?.choice;
      if (guard._seenHumans & (1 << seat) != 0 &&
          (motion == null || motion == _LiteMotionChoice.point)) {
        observe(
          actor.id,
          actor.at,
          human: true,
          warning: (_humanSpotting[actor.id]?.warningUntil ?? 0) > _sightClock,
        );
      }
      hear(actor.at, actor.quiet, actor.speed);
    }
    final confirmingHuman =
        seenHuman &&
        (guard.mode != LiteGuardMode.allerta ||
            (_forgetfulBandit(enemy) && guard._banditSighting == null));
    for (final clone in clones) {
      if (clone.hp <= 0 ||
          clone.corrupted ||
          companionConcealed(clone) ||
          inExplorationAtrium(clone.position))
        continue;
      if (!confirmingHuman &&
          !_assassinVeiled &&
          _guardSees(enemy, clone.position)) {
        observe(clone.id, clone.position);
      }
      hear(clone.position, false, clone.stride.speed);
    }
    if (seen case final target?) {
      _rallyGuard(enemy, target, LiteGuardMode.allerta);
      guard
        ..lastSeen = target
        .._attackSubject = seenSubject
        .._arrived = null;
      if (seenHuman) {
        guard._focusSubject = seenSubject;
        if (_forgetfulBandit(enemy)) {
          final viewer = seenSubject!;
          if (guard._banditSighting == null) {
            if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
            _combatImpacts.add(
              LiteCombatImpact(
                LiteImpactTarget.banditSpotted,
                viewer,
                enemy.position,
                time,
                enemyKind: enemy.kind,
                end: target,
              ),
            );
          }
          guard._banditSighting = (subject: viewer, point: target);
        }
      }
      final direction = LiteRun._unit(target - enemy.position);
      if (direction.magnitude > 0) guard.facing = direction;
      return target;
    }
    guard._attackSubject = null;
    if (warningPoint case final point?) {
      final direction = LiteRun._unit(point - enemy.position);
      if (direction.magnitude > 0) guard.facing = direction;
      if (guard.mode == LiteGuardMode.allerta) {
        guard.lastSeen = point;
        guard.target = point;
      }
      return null;
    }
    if (heard case final target?
        when guard.lastSeen == null || guard.mode == LiteGuardMode.ronda) {
      _rallyGuard(enemy, target, LiteGuardMode.indaga);
    }
    guard.attention = max(0, guard.attention - elapsed);
    final tracksBanditTarget =
        _forgetfulBandit(enemy) && guard._focusSubject != null;
    if (!tracksBanditTarget &&
        guard.mode != LiteGuardMode.ronda &&
        (guard.attention == 0 ||
            guard._arrived != null && time - guard._arrived! >= 1.7)) {
      _forgetGuardTarget(guard);
    }
    if (guard.target case final goal?) {
      if (goal.distanceTo(enemy.position) > .35) {
        guard._arrived = null;
        _followBelief(enemy, guard, goal, elapsed);
      } else if (guard.mode == LiteGuardMode.ronda) {
        guard.target = null;
      } else {
        guard._arrived ??= time;
        final angle = (time - guard._arrived!) * 3.7 + enemy.id;
        guard.facing = Point(cos(angle), sin(angle));
      }
    }
    return null;
  }

  void _observeCover(LiteEnemy enemy, LiteGuard mind) {
    if (time < mind._nextScan) return;
    mind._nextScan = time + .27;
    final at = enemy.position;
    final sense = _LiteEnemySenses.forKind(enemy.kind);
    bool visible(Point<double> point) {
      final offset = point - at;
      final distance = offset.magnitude;
      if (distance > sense.sight || distance <= .01) return false;
      if (distance > sense.near &&
          (offset.x * mind.facing.x + offset.y * mind.facing.y) / distance <
              sense.cone) {
        return false;
      }
      return !_lineBlocked(at, point) && !bushBlocksSight(at, point);
    }

    // Forget removed cover only if the place it occupied is visible again.
    mind._cover.removeWhere(
      (stone) =>
          !obstacles.any(stone.same) &&
          List.generate(4, (index) => stone.point(index, .20)).any(visible),
    );
    for (final wall in obstacles) {
      if (wall.center.distanceTo(at) >
          sense.sight + max(wall.width, wall.height) * .72)
        continue;
      final remembered = mind._cover
          .where((entry) => entry.same(wall))
          .firstOrNull;
      final stone =
          remembered ??
          _LiteObservedCover(
            wall.left,
            wall.top,
            wall.left + wall.width,
            wall.top + wall.height,
          );
      final oldCorners = stone.corners, oldEdges = stone.edges;
      for (var i = 0; i < 4; i++) {
        final point = stone.point(i, .19);
        if (visible(point)) stone.corners |= 1 << i;
        final mid = (point + stone.point((i + 1) % 4, .19)) * .5;
        if (visible(mid) &&
            // A back face cannot be learned through the stone's near edge.
            (i == 0 && at.y < stone.top ||
                i == 1 && at.x > stone.right ||
                i == 2 && at.y > stone.bottom ||
                i == 3 && at.x < stone.left)) {
          stone.edges |= 1 << i;
        }
      }
      if (oldCorners == stone.corners && oldEdges == stone.edges) continue;
      if (remembered == null) {
        if (mind._cover.length >= 6) mind._cover.removeAt(0);
        mind._cover.add(stone);
      }
      // New visual evidence will be used on the next permitted route update.
    }
  }

  bool _mentalSegmentClear(
    LiteGuard mind,
    Point<double> from,
    Point<double> to,
    double radius,
  ) {
    for (final stone in mind._cover) {
      for (var edge = 0; edge < 4; edge++) {
        if (stone.edges & (1 << edge) == 0) continue;
        final a = stone.point(edge, radius + .04);
        final b = stone.point((edge + 1) % 4, radius + .04);
        final p = edge.isEven ? from.y : from.x;
        final q = edge.isEven ? to.y : to.x;
        final fence = edge.isEven ? a.y : a.x;
        if ((p < fence) == (q < fence) || (q - p).abs() < 1e-9) continue;
        final fraction = (fence - p) / (q - p);
        final axis = edge.isEven
            ? from.x + (to.x - from.x) * fraction
            : from.y + (to.y - from.y) * fraction;
        final first = edge.isEven ? a.x : a.y;
        final second = edge.isEven ? b.x : b.y;
        if (axis > min(first, second) && axis < max(first, second))
          return false;
      }
    }
    return true;
  }

  void _followBelief(
    LiteEnemy enemy,
    LiteGuard mind,
    Point<double> goal,
    double elapsed, {
    double? travel,
  }) {
    final at = enemy.position;
    if (time >= mind._nextPlan) {
      mind._nextPlan = time + .24;
      mind._waypoint = null;
      if (!_mentalSegmentClear(mind, at, goal, enemy.radius)) {
        var best = double.infinity;
        for (final stone in mind._cover) {
          for (var i = 0; i < 4; i++) {
            if (stone.corners & (1 << i) == 0) continue;
            final corner = stone.point(i, enemy.radius + .22);
            final distance = at.distanceTo(corner);
            if (distance < .31 ||
                corner.x < enemy.radius ||
                corner.y < enemy.radius ||
                corner.x > width - enemy.radius ||
                corner.y > height - enemy.radius ||
                !_mentalSegmentClear(mind, at, corner, enemy.radius))
              continue;
            final caseCost =
                distance +
                corner.distanceTo(goal) +
                (_mentalSegmentClear(mind, corner, goal, enemy.radius)
                    ? 0
                    : 1.4);
            if (caseCost >= best) continue;
            best = caseCost;
            mind._waypoint = corner;
          }
        }
      }
    }
    final heading = LiteRun._unit((mind._waypoint ?? goal) - at);
    mind.facing = heading;
    enemy.position = _move(
      at,
      heading * (travel ?? elapsed * enemy.kind.speed * .73),
      enemy.radius,
    );
  }

  List<Point<double>> guardVisionOutline(
    LiteEnemy enemy, {
    required bool quiet,
  }) {
    final mind = enemy.guard;
    if (mind == null || enemy.hp <= 0) return const [];
    final senses = _LiteEnemySenses.forKind(enemy.kind);
    final start = enemy.position;
    final heading = atan2(mind.facing.y, mind.facing.x);
    final half = acos(senses.cone);
    final range = quiet ? senses.quietSight : senses.sight;
    return [
      for (var ray = 0; ray < 7; ray++)
        _guardVisionRay(start, heading + half * (ray / 3 - 1), range),
    ];
  }

  Point<double> _guardVisionRay(
    Point<double> start,
    double angle,
    double length,
  ) {
    final vector = Point(cos(angle), sin(angle)) * length;
    var stop = bushSightFraction(start, start + vector);
    final samples = max(1, (length / .20).ceil());
    for (var step = 1; step <= samples; step++) {
      final fraction = step / samples;
      if (fraction >= stop) break;
      if (_blocked(start + vector * fraction, .12)) {
        stop = (step - 1) / samples;
        break;
      }
    }
    return start + vector * stop;
  }

  bool _encounterImpact(
    LiteEnemy victim,
    Point<double> from,
    bool force,
    bool walking, {
    String? finisherAccount,
  }) {
    final guard = victim.guard;
    if (guard == null) return false;
    final quiet =
        force &&
        walking &&
        victim.hp <= 0 &&
        guard.mode != LiteGuardMode.allerta;
    if (victim.hp > 0) _rallyGuard(victim, from, LiteGuardMode.allerta);
    if (!quiet) _encounterNoise(victim.position, 8.2, except: victim);
    var witnessed = false;
    for (final other in enemies) {
      if (other == victim || other.hp <= 0 || other.guard == null) continue;
      final sawFinisher =
          !_assassinVeiled && _guardSees(other, from, quiet: walking);
      if (_guardSees(other, victim.position) || sawFinisher) {
        _rallyGuard(
          other,
          sawFinisher ? from : victim.position,
          LiteGuardMode.allerta,
        );
        witnessed = true;
      }
    }
    if (quiet) {
      if (!witnessed && finisherAccount != null) {
        _creditAssassinKill(victim, finisherAccount);
      }
      message = witnessed
          ? 'Un testimone ha visto il colpo.'
          : 'Abbattimento silenzioso.';
    }
    return quiet;
  }
}
