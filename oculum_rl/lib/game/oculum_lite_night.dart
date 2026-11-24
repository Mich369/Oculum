part of 'oculum_lite_run.dart';

abstract interface class LiteNightVisual {
  double get bat;
  double get sanguine;
  double get veil;
  double get absorb;
  double get mud;
  double get stun;
  double get solarMace;
  double get solarMantle;
  int? get targetId;
}

class _NightKit implements LiteNightVisual {
  @override
  double bat = 0, sanguine = 0, veil = 0, absorb = 0;
  double utility = 0, pulse = 0, buildup = 0, aura = 0;
  @override
  double mud = 0, stun = 0;
  @override
  int? targetId;
  @override
  double solarMace = 0, solarMantle = 0;

  bool get active =>
      bat > 0 ||
      sanguine > 0 ||
      veil > 0 ||
      absorb > 0 ||
      utility > 0 ||
      mud > 0 ||
      stun > 0 ||
      solarMace > 0 ||
      solarMantle > 0;
  List<num> get frame => [
    bat,
    sanguine,
    veil,
    absorb,
    utility,
    pulse,
    buildup,
    aura,
    targetId ?? -1,
    mud,
    stun,
    solarMace,
    solarMantle,
  ];

  void reset() {
    bat = sanguine = veil = absorb = utility = pulse = buildup = aura = mud =
        stun = 0;
    solarMace = solarMantle = 0;
    targetId = null;
  }

  void restore(Object? data) {
    if (data is! List || data.length < 9) return;
    bat = _num(data[0]).clamp(0.0, 3.0);
    sanguine = _num(data[1]).clamp(0.0, 8.0);
    veil = _num(data[2]).clamp(0.0, .55);
    absorb = _num(data[3]).clamp(0.0, 1.55);
    utility = _num(data[4]).clamp(0.0, 12.0);
    pulse = _num(data[5]).clamp(0.0, .25);
    buildup = _num(data[6]).clamp(0.0, 4.0);
    aura = _num(data[7]).clamp(0.0, 1.0);
    final id = _int(data[8], -1);
    targetId = id >= 0 ? id : null;
    mud = data.length > 9 ? _num(data[9]).clamp(0.0, .9) : 0;
    stun = data.length > 10 ? _num(data[10]).clamp(0.0, .9) : 0;
    solarMace = data.length > 11 ? _num(data[11]).clamp(0, 8) : 0;
    solarMantle = data.length > 12 ? _num(data[12]).clamp(0, 5) : 0;
  }
}

extension _NightCombat on LiteRun {
  bool _slimeDash(Point<double> target, LiteCoopFighter? fighter) {
    final kit = fighter?._night ?? _night;
    if ((fighter?.hero ?? hero) != LiteHero.slimeBlu ||
        finished ||
        shopOpen ||
        (fighter?.blocking ?? blocking) ||
        (fighter?.hp ?? hp) <= 0 ||
        kit.utility > 0)
      return false;
    final at = fighter?.position ?? position;
    final direction = LiteRun._unit(target - at);
    final heading = direction.magnitude == 0
        ? (fighter?.aim ?? aim)
        : direction;
    kit
      ..veil = .55
      ..utility = 4.2
      ..absorb = 0
      ..targetId = null;
    if (fighter == null) {
      _burstTime = .55;
      _burstSpeed = 13.0;
      _burstDirection = heading;
      _invulnerability = max(_invulnerability, .55);
    } else {
      fighter
        .._dashRemaining = .55
        .._dashSpeed = 13
        .._dashDirection = heading
        .._shadowProtection = max(fighter._shadowProtection, .55);
    }
    _beginBurstTrace(LiteBurstKind.veil, .55, fighter: fighter);
    message = 'Scia invisibile.';
    return true;
  }

  bool _extendAbsorption(
    Point<double> at,
    Point<double> direction,
    LiteCoopFighter? fighter, {
    bool empower = false,
  }) {
    if ((fighter?.blocking ?? blocking) || (fighter?.hp ?? hp) <= 0)
      return false;
    final kit = fighter?._night ?? _night;
    if (kit.veil > 0) return false;
    if (kit.targetId case final id? when kit.absorb > 0) {
      final living = enemies
          .where((enemy) => enemy.id == id && enemy.hp > 0)
          .firstOrNull;
      if (living != null &&
          LiteRun._distanceSquared(at, living.position) <= 10.24 &&
          !_lineBlocked(at, living.position)) {
        kit.absorb = min(
          empower ? 1.55 : .94,
          kit.absorb + (empower ? .90 : .35),
        );
        return true;
      }
    }
    final radius = empower ? 3.4 : 2.7;
    LiteEnemy? victim;
    var distance = radius * radius;
    for (final candidate in enemies) {
      if (candidate.hp <= 0 ||
          candidate.kind.boss ||
          candidate.kind.echo ||
          _enemyIntangible(candidate) ||
          !LiteRun._inArc(
            at,
            direction,
            candidate.position,
            radius,
            minDot: .35,
          ) ||
          _lineBlocked(at, candidate.position))
        continue;
      final delta = LiteRun._distanceSquared(at, candidate.position);
      if (delta >= distance) continue;
      distance = delta;
      victim = candidate;
    }
    if (victim == null) {
      message = 'Mira a un nemico vicino, poi fai clic ripetutamente.';
      return false;
    }
    kit
      ..targetId = victim.id
      ..absorb = empower ? 1.4 : .67
      ..pulse = 0
      ..buildup = empower ? 1.25 : 0;
    message =
        'Assorbimento · continua a fare clic destro per mantenere la presa.';
    return true;
  }

  void _tickNight(LiteCoopFighter? fighter, double elapsed) {
    final character = fighter?.hero ?? hero;
    final kit = fighter?._night ?? _night;
    kit.mud = max(0, kit.mud - elapsed);
    kit.stun = max(0, kit.stun - elapsed);
    kit.utility = max(0, kit.utility - elapsed);
    if (character != LiteHero.slimeBlu && character != LiteHero.vampiro) return;
    final at = fighter?.position ?? position;
    kit.bat = max(0, kit.bat - elapsed);
    kit.veil = max(0, kit.veil - elapsed);

    if (kit.sanguine > 0) {
      kit.sanguine = max(0, kit.sanguine - elapsed);
      if (kit.sanguine <= 0) {
        if (fighter == null) {
          hp /= 2;
        } else {
          fighter.hp /= 2;
        }
      } else {
        kit.aura -= elapsed;
        if (kit.aura <= 0) {
          kit.aura = 1;
          for (final enemy in enemies) {
            if (enemy.hp <= 0 ||
                LiteRun._distanceSquared(at, enemy.position) > 4 ||
                _lineBlocked(at, enemy.position))
              continue;
            _hitEnemy(
              enemy,
              enemy.maxHp * .05,
              ownerCanHeal: fighter == null,
              sourceCloneId: fighter?.id,
              vampireStrike: false,
            );
          }
        }
      }
    }

    if (kit.absorb <= 0 || kit.targetId == null) return;
    final enemy = enemies
        .where((enemy) => enemy.id == kit.targetId)
        .firstOrNull;
    if (enemy == null ||
        enemy.hp <= 0 ||
        LiteRun._distanceSquared(at, enemy.position) > 10.24 ||
        _lineBlocked(at, enemy.position)) {
      kit
        ..absorb = 0
        ..targetId = null;
      return;
    }
    kit.absorb = max(0, kit.absorb - elapsed);
    if (kit.absorb <= 0) {
      kit.targetId = null;
      return;
    }
    kit.buildup = min(4.0, kit.buildup + elapsed);
    kit.pulse -= elapsed;
    if (kit.pulse > 0) return;
    kit.pulse = .25;
    final before = enemy.hp;
    _hitEnemy(
      enemy,
      3.25 + kit.buildup * 1.9,
      ownerCanHeal: fighter == null,
      sourceCloneId: fighter?.id,
    );
    final lost = max(0.0, before - enemy.hp);
    if (lost <= 0) return;
    if (fighter == null) {
      hp = min(maxHp, hp + lost * .55);
      oculum = min(maxOculum, oculum + .42);
    } else {
      fighter.hp = min(fighter.maxHp, fighter.hp + lost * .55);
      fighter.oculum = min(fighter.maxOculum, fighter.oculum + .42);
    }
  }

  bool _answerSlime(LiteEnemy enemy, double elapsed) {
    if (enemy.kind
        case LiteEnemyKind.dronePostea ||
            LiteEnemyKind.ragnoSaldatore ||
            LiteEnemyKind.miruscyrus ||
            LiteEnemyKind.costrutto ||
            LiteEnemyKind.guardianoLunare)
      return false;
    Point<double>? at;
    var distance = 100.0;
    bool pinned = false;
    void consider(_NightKit kit, Point<double> source, double life) {
      if (life <= 0 || kit.absorb <= 0) return;
      if (kit.targetId == enemy.id) pinned = true;
      final dist = LiteRun._distanceSquared(source, enemy.position);
      if (dist >= distance || _lineBlocked(source, enemy.position)) return;
      distance = dist;
      at = source;
    }

    if (hero == LiteHero.slimeBlu) consider(_night, position, hp);
    for (final fighter in coopFighters) {
      if (fighter.hero == LiteHero.slimeBlu)
        consider(fighter._night, fighter.position, fighter.hp);
    }
    if (!pinned && at == null) return false;
    enemy.windup = 0;
    if (pinned) return true;
    final radial = LiteRun._unit(enemy.position - at!);
    final tangent = Point(-radial.y, radial.x) * (enemy.id.isEven ? 1.0 : -1.0);
    final orbit = LiteRun._unit(
      tangent + radial * ((3.15 - sqrt(distance)) * .62),
    );
    enemy.position = _move(
      enemy.position,
      orbit * (elapsed * enemy.kind.speed),
      enemy.radius,
    );
    enemy.attackTarget = at;
    return true;
  }

  bool _ram(LiteEnemy enemy, Point<double> source, double metres) {
    final direction = LiteRun._unit(enemy.position - source);
    if (direction.magnitude <= 0) return false;
    for (var left = metres; left > 0; left -= .22) {
      final candidate = enemy.position + direction * min(.22, left);
      final wall = obstacles
          .where((obstacle) => obstacle.visibleAt(candidate, enemy.radius))
          .firstOrNull;
      if (wall != null) {
        if (wall.breakable) _destroyCover(wall);
        return true;
      }
      final next = _move(
        enemy.position,
        candidate - enemy.position,
        enemy.radius,
      );
      if (next == enemy.position) return false;
      enemy.position = next;
    }
    return false;
  }
}
