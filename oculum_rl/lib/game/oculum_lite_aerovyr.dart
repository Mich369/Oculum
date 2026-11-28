part of 'oculum_lite_run.dart';

enum LiteStormPattern { ventaglio, croce, corona }

class LiteStormWarning {
  const LiteStormWarning(
    this.pattern,
    this.origin,
    this.target,
    this.phase,
    this.remaining,
  );
  final LiteStormPattern pattern;
  final Point<double> origin, target;
  final int phase;
  final double remaining;

  double get duration => switch (pattern) {
    LiteStormPattern.ventaglio => phase == 1 ? .88 : .68,
    LiteStormPattern.croce => phase == 2 ? 1.0 : .78,
    LiteStormPattern.corona => phase == 2 ? 1.04 : .84,
  };
  double get radius => phase == 3 ? 1.01 : .86;
  double get inner => phase == 3 ? 1.48 : 1.78;
  double get outer => phase == 3 ? 4.35 : 3.78;
  List<double> get spread => phase == 1
      ? const [-.52, -.26, 0, .26, .52]
      : const [-.74, -.49, -.24, 0, .24, .49, .74];

  Point<double> get direction {
    final axis = LiteRun._unit(target - origin);
    return axis.magnitude > .01 ? axis : const Point(1, 0);
  }

  List<Point<double>> get marks {
    final fore = direction;
    final cross = Point(-fore.y, fore.x);
    return [
      target,
      for (final axis in [fore, cross])
        for (final delta in [-4.95, -3.30, -1.65, 1.65, 3.30, 4.95])
          target + axis * delta,
    ];
  }
}

extension on LiteEnemy {
  void _readStormCue(Object? data) {
    if (kind != LiteEnemyKind.aerovyr || data is! List || data.length != 2)
      return;
    _stormPattern = LiteStormPattern.values
        .where((cue) => cue.name == data[0])
        .firstOrNull;
    _stormPhase = _int(data[1], 1).clamp(1, 3);
  }
}

extension LiteAerovyr on LiteRun {
  int aerovyrPhase(LiteEnemy enemy) => enemy.hp > enemy.maxHp * .67
      ? 1
      : enemy.hp > enemy.maxHp * .32
      ? 2
      : 3;

  LiteStormWarning? stormWarning(LiteEnemy enemy) {
    if (enemy.kind != LiteEnemyKind.aerovyr || !enemy.attacking) return null;
    final pattern = enemy._stormPattern;
    final target = enemy.attackTarget;
    return pattern == null || target == null
        ? null
        : LiteStormWarning(
            pattern,
            enemy.position,
            target,
            enemy._stormPhase,
            enemy.windup,
          );
  }

  void _tickAerovyr(LiteEnemy enemy, double elapsed) {
    if (stormWarning(enemy) case final warning?) {
      enemy.windup = max(0, enemy.windup - elapsed);
      if (enemy.windup > 1e-9) return;
      enemy.windup = 0;
      enemy._stormPattern = null;
      enemy.attackTarget = null;
      enemy.combatCycle++;
      enemy.cooldown = switch (warning.phase) {
        1 => 1.48,
        2 => 1.10,
        _ => .76,
      };
      _releaseStorm(enemy, warning);
      return;
    }
    enemy.windup = 0;
    enemy.cooldown = max(0, enemy.cooldown - elapsed);
    final to = _enemyAimFrom(enemy.position);
    final direction = LiteRun._unit(to - enemy.position);
    final distance = enemy.position.distanceTo(to);
    final phase = aerovyrPhase(enemy);
    if (enemy.cooldown == 0 &&
        distance <= 14 &&
        (phase > 1 || !_lineBlocked(enemy.position, to))) {
      final order = switch (phase) {
        1 => const [LiteStormPattern.ventaglio, LiteStormPattern.croce],
        2 => const [
          LiteStormPattern.croce,
          LiteStormPattern.corona,
          LiteStormPattern.ventaglio,
        ],
        _ => const [
          LiteStormPattern.corona,
          LiteStormPattern.ventaglio,
          LiteStormPattern.croce,
          LiteStormPattern.corona,
        ],
      };
      final pattern = order[enemy.combatCycle % order.length];
      enemy
        .._stormPattern = pattern
        .._stormPhase = phase
        ..attackTarget = to
        ..windup = LiteStormWarning(
          pattern,
          enemy.position,
          to,
          phase,
          0,
        ).duration;
      return;
    }
    final travel = distance <= 5.4
        ? _rotate(direction, enemy.combatCycle.isEven ? 1.7 : -1.7)
        : direction;
    enemy.position = _chooseLane(
      enemy.position,
      travel,
      enemy.kind.speed * (1 + (phase - 1) * .18) * elapsed,
      enemy.radius,
      rightFirst: enemy.id.isEven,
    );
  }

  void _releaseStorm(LiteEnemy enemy, LiteStormWarning cue) {
    enemy._strikePose = .24;
    final power =
        (cue.phase == 3 ? 1.76 : 1.43) *
        enemy.attackDamage *
        difficulty.enemyStrength *
        _challengeDamageScale(enemy.kind);
    if (cue.pattern == LiteStormPattern.ventaglio) {
      for (final angle in cue.spread) {
        _thirdShot(
          enemy,
          _rotate(cue.direction, angle),
          power * .77,
          12 + cue.phase.toDouble(),
        );
      }
      return;
    }
    final points = cue.pattern == LiteStormPattern.croce
        ? cue.marks
        : const <Point<double>>[];
    bool inStorm(Point<double> position) {
      if (cue.pattern == LiteStormPattern.corona) {
        final radius = position.distanceTo(cue.target);
        return radius >= cue.inner && radius <= cue.outer;
      }
      return points.any(
        (mark) =>
            mark.distanceTo(position) <= cue.radius &&
            !_lineBlocked(mark, position),
      );
    }

    if (!hostDown && inStorm(position)) _damagePlayer(power);
    for (final ally in _damageableAllies) {
      if (ally.hp > 0 && inStorm(ally.position)) _hitAlly(ally, power);
    }
    final impactMarks = points.isNotEmpty
        ? points
        : [
            for (var i = 0; i < 10; i++)
              cue.target +
                  Point(cos(i * pi / 5), sin(i * pi / 5)) *
                      ((cue.inner + cue.outer) * .5),
          ];
    for (final at in impactMarks.where((point) => !_blocked(point, .10))) {
      _recordImpact(LiteImpactTarget.chamberStrike, _nextId++, at);
    }
  }
}
