part of 'oculum_lite_run.dart';

enum LiteGuardMode { ronda, indaga, allerta }

class LiteGuard {
  LiteGuard(this.post);
  final Point<double> post;
  LiteGuardMode mode = LiteGuardMode.ronda;
  Point<double> facing = const Point(1, 0);
  Point<double>? target;
  double attention = 0;

  List<Object?> get frame => [
    _savePoint(post),
    mode.name,
    _savePoint(facing),
    if (target == null) null else _savePoint(target!),
    attention,
  ];

  static LiteGuard? read(Object? state) {
    if (state is! List || state.length != 5) return null;
    return LiteGuard(_point(state[0]))
      ..mode = _enum(LiteGuardMode.values, state[1], LiteGuardMode.ronda)
      ..facing = _point(state[2])
      ..target = state[3] == null ? null : _point(state[3])
      ..attention = _num(state[4]).clamp(0, 6);
  }
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
    final kind = enemy.kind;
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
    if (campPatrols && enemy.kind == LiteEnemyKind.scostubandito) return;
    final lane = ((seed ^ (enemy.id * 11)) % 3) - 1;
    guard.facing = LiteRun._unit(Point(-.84, lane * .54));
    if (enemy.attackTarget case final target? when restoring) {
      _rallyGuard(enemy, target, LiteGuardMode.allerta);
    }
  }

  bool _guardSees(LiteEnemy enemy, Point<double> at, {bool quiet = false}) {
    final delta = at - enemy.position;
    final distance = delta.magnitude;
    final senses = _LiteEnemySenses.forKind(enemy.kind);
    if (distance > (quiet ? senses.quietSight : senses.sight)) return false;
    final facing = enemy.guard!.facing;
    if (distance >= senses.near &&
        (delta.x * facing.x + delta.y * facing.y) / distance < senses.cone) {
      return false;
    }
    return !_lineBlocked(enemy.position, at);
  }

  void _rallyGuard(LiteEnemy enemy, Point<double> at, LiteGuardMode mode) {
    final guard = enemy.guard;
    if (guard == null ||
        guard.mode == LiteGuardMode.allerta && mode != LiteGuardMode.allerta)
      return;
    guard
      ..mode = mode
      ..attention = mode == LiteGuardMode.allerta ? 5 : 2.2
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

  Point<double>? _encounterTarget(LiteEnemy enemy, double elapsed) {
    final guard = enemy.guard!;
    final senses = _LiteEnemySenses.forKind(enemy.kind);
    Point<double>? seen, heard;
    var sightDistance = double.infinity, soundDistance = double.infinity;
    void sense(Point<double> at, bool quiet, double speed) {
      if (inExplorationAtrium(at)) return;
      final distance = enemy.position.distanceTo(at);
      if (distance < sightDistance && _guardSees(enemy, at, quiet: quiet)) {
        seen = at;
        sightDistance = distance;
      }
      final reach = quiet ? senses.walking : senses.running;
      if (speed <= .12 || distance >= soundDistance || distance > reach) return;
      if (distance <= reach * senses.coverHearing ||
          !_lineBlocked(enemy.position, at)) {
        heard = at;
        soundDistance = distance;
      }
    }

    if (!hostDown) sense(position, _walking, stride.speed);
    for (final ally in _damageableAllies) {
      if (ally.hp <= 0 || ally.corrupted) continue;
      sense(ally.position, ally.stride.walking == true, ally.stride.speed);
    }
    if (seen case final target?) {
      if (guard.mode != LiteGuardMode.allerta) {
        _encounterNoise(enemy.position, 6.5, except: enemy);
      }
      _rallyGuard(enemy, target, LiteGuardMode.allerta);
      final direction = LiteRun._unit(target - enemy.position);
      if (direction.magnitude > 0) guard.facing = direction;
      return target;
    }
    if (heard case final target?) {
      _rallyGuard(enemy, target, LiteGuardMode.indaga);
    }
    guard.attention = max(0, guard.attention - elapsed);
    if (guard.attention == 0 && guard.mode != LiteGuardMode.ronda) {
      guard.mode = LiteGuardMode.ronda;
      guard.target = guard.post;
    }
    if (guard.target case final target?) {
      final shift = target - enemy.position;
      if (shift.magnitude > .35) {
        final heading = LiteRun._unit(shift);
        guard.facing = heading;
        enemy.position = _chooseLane(
          enemy.position,
          heading,
          elapsed * enemy.kind.speed * .73,
          enemy.radius,
          rightFirst: enemy.id.isEven,
        );
      } else if (guard.mode == LiteGuardMode.ronda) {
        guard.target = null;
        guard.facing = const Point(1, 0);
      } else if (guard.mode == LiteGuardMode.indaga) {
        final angle = (2.2 - guard.attention) * 6;
        guard.facing = Point(cos(angle), sin(angle));
      }
    }
    return null;
  }

  bool _encounterImpact(
    LiteEnemy victim,
    Point<double> from,
    bool force,
    bool walking,
  ) {
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
      if (_guardSees(other, victim.position) ||
          _guardSees(other, from, quiet: walking)) {
        _rallyGuard(other, from, LiteGuardMode.allerta);
        witnessed = true;
      }
    }
    if (quiet) {
      message = witnessed
          ? 'Un testimone ha visto il colpo.'
          : 'Abbattimento silenzioso.';
    }
    return quiet;
  }
}
