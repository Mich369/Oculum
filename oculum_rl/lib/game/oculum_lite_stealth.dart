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

  bool _guardSees(LiteEnemy enemy, Point<double> at, {bool quiet = false}) {
    final delta = at - enemy.position;
    final distance = delta.magnitude;
    if (distance > (quiet ? 4.9 : 8.2) || _lineBlocked(enemy.position, at))
      return false;
    if (distance < 1.15) return true;
    final facing = enemy.guard!.facing;
    return (delta.x * facing.x + delta.y * facing.y) / distance >= .39;
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

  void _campNoise(Point<double> at, double radius, {LiteEnemy? except}) {
    if (!campPatrols) return;
    for (final witness in enemies) {
      if (witness == except || witness.hp <= 0 || witness.guard == null)
        continue;
      final reach = _lineBlocked(witness.position, at) ? radius * .53 : radius;
      if (witness.position.distanceTo(at) <= reach) {
        _rallyGuard(witness, at, LiteGuardMode.indaga);
      }
    }
  }

  Point<double>? _campTarget(LiteEnemy enemy, double elapsed) {
    final guard = enemy.guard!;
    Point<double>? seen, heard;
    var sightDistance = double.infinity, soundDistance = double.infinity;
    void sense(Point<double> at, bool quiet, double speed) {
      final distance = enemy.position.distanceTo(at);
      if (distance < sightDistance && _guardSees(enemy, at, quiet: quiet)) {
        seen = at;
        sightDistance = distance;
      }
      if (speed <= .12 || distance >= soundDistance) return;
      final clear = !_lineBlocked(enemy.position, at);
      if (distance <= (quiet ? .9 : 6.7) * (clear ? 1 : .53)) {
        heard = at;
        soundDistance = distance;
      }
    }

    if (!hostDown) sense(position, _walking, stride.speed);
    for (final ally in _damageableAllies) {
      if (ally.hp <= 0) continue;
      sense(
        ally.position,
        ally is LiteCoopFighter && ally._slow,
        ally.stride.speed,
      );
    }
    if (seen case final target?) {
      if (guard.mode != LiteGuardMode.allerta) {
        _campNoise(enemy.position, 6.5, except: enemy);
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

  bool _campImpact(
    LiteEnemy victim,
    Point<double> from,
    bool force,
    bool walking,
  ) {
    final guard = victim.guard;
    if (!campPatrols || guard == null) return false;
    final quiet =
        force &&
        walking &&
        victim.hp <= 0 &&
        guard.mode != LiteGuardMode.allerta;
    if (victim.hp > 0) _rallyGuard(victim, from, LiteGuardMode.allerta);
    if (!quiet) _campNoise(victim.position, 8.2, except: victim);
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
