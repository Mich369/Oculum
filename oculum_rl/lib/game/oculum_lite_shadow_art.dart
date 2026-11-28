part of 'oculum_lite_run.dart';

/// A sustained Shadow Art. The renderer uses the same line as the pulses.
class LiteShadowRay {
  LiteShadowRay._(
    this.casterId,
    this.hostile,
    this.rank,
    this.start,
    this.direction,
    this.remaining, {
    this.strength = 1,
    this.pulseIn = 0,
    Point<double>? end,
  }) : end = end ?? start;

  final int casterId, rank;
  final bool hostile;
  final double strength;
  Point<double> start, direction, end;
  double remaining, pulseIn;
  double get width => .24 + rank * .06;
  double get range => 7 + rank * 1.2;
  double get opacity => min(1, remaining * 7);

  List<Object> _frame() => [
    casterId,
    hostile,
    rank,
    _savePoint(start),
    _savePoint(direction),
    remaining,
    strength,
    pulseIn,
    _savePoint(end),
  ];

  static LiteShadowRay? _read(Object? data) {
    if (data is! List || data.length != 9) return null;
    final time = _num(data[5]);
    final direction = LiteRun._unit(_point(data[4]));
    if (!time.isFinite || time <= 0 || direction.magnitude < .1) return null;
    return LiteShadowRay._(
      max(0, _int(data[0])),
      data[1] == true,
      _int(data[2]).clamp(1, 3),
      _point(data[3]),
      direction,
      time.clamp(0.0, 1.75),
      strength: _num(data[6], 1).clamp(.0, 4.0),
      pulseIn: _num(data[7]).clamp(.0, .18),
      end: _point(data[8]),
    );
  }
}

extension _LiteShadowArts on LiteRun {
  bool _castVeiledEcho(
    int owner,
    Point<double> at,
    Point<double> heading,
    int rank,
    LiteWeapon equipment,
  ) {
    final count = clones
        .where(
          (ally) =>
              ally.ownerId == owner &&
              ally.companion == null &&
              !ally.summoned &&
              ally.hp > 0,
        )
        .length;
    if (count > 1) return false;
    final lateral = Point(-heading.y, heading.x);
    if (lateral.magnitude < .1) return false;
    for (final side in [-1, 1]) {
      clones.add(
        LiteClone(
          _safePoint(at + lateral * (1.35 * side), .35, at),
          16.0 + rank * 6,
          equipment,
          expiresAfter: 6.0 + rank * 2,
          id: _nextId++,
          damageScale: .66 + .16 * rank,
          ownerId: owner,
        ),
      );
    }
    return true;
  }

  bool _castLightlessStep(
    Point<double> heading,
    int rank,
    LiteCoopFighter? fighter,
  ) {
    if ((fighter?._dashRemaining ?? _burstTime) > 0) return false;
    final duration = .29 + .055 * rank;
    final speed = 11.5 + rank * 1.3;
    if (fighter == null) {
      _burstDirection = aim = heading;
      _burstSpeed = speed;
      _burstTime = duration;
      _invulnerability = max(_invulnerability, duration);
    } else {
      fighter
        ..aim = heading
        .._dashDirection = heading
        .._dashSpeed = speed
        .._dashRemaining = duration
        .._protection = max(fighter._protection, duration);
    }
    _beginBurstTrace(LiteBurstKind.phase, duration, fighter: fighter);
    return true;
  }

  void _beginShadowRay(
    int actor,
    Point<double> at,
    Point<double> direction,
    int rank, {
    bool hostile = false,
    double strength = 1,
  }) {
    final beam = LiteShadowRay._(
      actor,
      hostile,
      rank,
      at,
      direction,
      .94 + .24 * rank,
      strength: strength,
    );
    _setShadowRayEnd(beam);
    _shadowRays[(hostile, actor)] = beam;
  }

  void _setShadowRayEnd(LiteShadowRay beam) {
    var length = 0.0;
    while (length < beam.range) {
      final check = min(beam.range, length + .10);
      final point = beam.start + beam.direction * check;
      if (_blockedAt(point.x, point.y, beam.width)) break;
      length = check;
    }
    beam.end = beam.start + beam.direction * length;
  }

  void _tickShadowRays(double elapsed) {
    // Damage can end another ray, so iterate the live entries through a copy.
    for (final ray in _shadowRays.values.toList(growable: false)) {
      final key = (ray.hostile, ray.casterId);
      if (!_shadowRays.containsKey(key)) continue;
      final fighter = ray.hostile ? null : _coopFighterById(ray.casterId);
      if (!ray.hostile && ray.casterId != 0 && fighter == null) {
        _shadowRays.remove(key);
        continue;
      }
      final foe = ray.hostile
          ? enemies.where((enemy) => enemy.id == ray.casterId).firstOrNull
          : null;
      if ((ray.hostile
              ? foe == null || foe.hp <= 0 || foe.stunned > 0
              : fighter != null
              ? fighter.hp <= 0 ||
                    !fighter.connected ||
                    fighter.blocking ||
                    fighter._night.stun > 0 ||
                    fighter.burstRemaining > 0
              : hp <= 0 || blocking || _night.stun > 0 || _burstTime > 0) ||
          ray.remaining <= 0) {
        _shadowRays.remove(key);
        continue;
      }
      ray.start = foe?.position ?? fighter?.position ?? position;
      final wanted = foe != null
          ? LiteRun._unit(_enemyAimFrom(foe.position) - foe.position)
          : fighter?.aim ?? aim;
      final angle = atan2(ray.direction.y, ray.direction.x);
      final aimAngle = atan2(wanted.y, wanted.x);
      final turn = atan2(sin(aimAngle - angle), cos(aimAngle - angle));
      ray.direction = _rotate(
        ray.direction,
        turn.clamp(-.84 * elapsed, .84 * elapsed),
      );
      _setShadowRayEnd(ray);
      ray.remaining -= elapsed;
      ray.pulseIn -= elapsed;
      if (ray.pulseIn > 0) continue;
      ray.pulseIn += .18;
      final damage = (5 + 2 * ray.rank) * ray.strength;
      Point<double> onRay(Point<double> point) {
        final delta = point - ray.start;
        final projection =
            delta.x * ray.direction.x + delta.y * ray.direction.y;
        return ray.start +
            ray.direction * projection.clamp(0, ray.start.distanceTo(ray.end));
      }

      if (ray.hostile) {
        bool reached(Point<double> at) =>
            onRay(at).distanceTo(at) <= ray.width + .36;
        if (reached(position)) _damagePlayer(damage);
        for (final ally in _damageableAllies) {
          if (ally.hp > 0 && reached(ally.position)) _hitAlly(ally, damage);
        }
      } else {
        for (final enemy in enemies.toList(growable: false)) {
          if (enemy.hp > 0 &&
              enemy.hitboxContains(onRay(enemy.position), extra: ray.width)) {
            _hitEnemy(
              enemy,
              damage,
              ownerCanHeal: ray.casterId == 0,
              sourceCloneId: ray.casterId == 0 ? null : ray.casterId,
              impactFrom: ray.start,
            );
          }
        }
      }
    }
  }
}
