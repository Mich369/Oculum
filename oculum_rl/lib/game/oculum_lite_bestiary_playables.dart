part of 'oculum_lite_run.dart';

extension LiteBestiaryHero on LiteHero {
  bool get bodyOnly =>
      this == LiteHero.moscaCampana || this == LiteHero.armadilloCorazzato;

  double get bodyAttackRecovery => this == LiteHero.moscaCampana ? .49 : .59;
}

extension LiteBestiaryCreature on LiteEnemyKind {
  bool get bellFly => this == LiteEnemyKind.moscaCampana;
  bool get armoredArmadillo => this == LiteEnemyKind.armadilloCorazzato;
}

enum LiteBestiaryCue { bell, roll }

extension _LiteBestiaryCombat on LiteRun {
  void _bestiaryCue(
    LiteBestiaryCue cue,
    Point<double> at,
    Point<double> facing,
    double reach,
    int actor,
  ) {
    if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
    _combatImpacts.add(
      LiteCombatImpact(
        LiteImpactTarget.bestiaryCast,
        actor,
        at,
        time,
        life: (cue.index + 1).toDouble(),
        shield: reach,
        end: at + facing,
      ),
    );
  }

  void _bodyStrike(
    LiteHero character,
    Point<double> from,
    Point<double> direction,
    int level,
    LiteCoopFighter? fighter,
  ) {
    final owner = fighter?.id;
    final extraDamage = _attributeDamage(fighter);
    final reachScale = attributeAttackReach(fighter);
    if (character == LiteHero.moscaCampana) {
      _bestiaryRing(
        from,
        direction,
        2.95 * reachScale,
        8 + level * 1.4 + extraDamage,
        .30,
        owner,
        minDot: .24,
      );
      return;
    }
    _melee(
      from,
      direction,
      LiteWeapon.guanti,
      9 + level * 1.6 + extraDamage,
      reach: 2.2 * reachScale,
      push: .54,
      minDot: .40,
      ownerCanHeal: owner == null,
      sourceCloneId: owner,
    );
  }

  void _bestiaryHeroMove(
    LiteHero character,
    Point<double> from,
    Point<double> direction,
    LiteCoopFighter? fighter, {
    required bool open,
  }) {
    final rank = LiteRun.openGradeFor(fighter?.level ?? level);
    final owner = fighter?.id;
    if (character == LiteHero.moscaCampana) {
      final reach = open ? 5.80 + rank * .36 : 4.1;
      final power = (12 + rank * 3.0) * (open ? LiteRun.openPower : 1);
      final stun = open ? 1.35 + rank * .21 : .66 + rank * .08;
      _bestiaryRing(
        from,
        direction,
        reach,
        power,
        stun,
        owner,
        minDot: open ? -1.1 : .32,
      );
      return;
    }
    final point = _playableShadowStep(
      from,
      direction,
      fighter,
      protection: open ? .43 : .26,
      distance: open ? 5.1 : 3.45,
    );
    final reach = open ? 2.95 : 1.84;
    final force = open ? 2.80 + rank * .6 : 1.45;
    final power = (14.0 + rank * 4) * (open ? LiteRun.openPower : 1);
    _melee(
      point,
      direction,
      LiteWeapon.guanti,
      power,
      reach: reach,
      push: force,
      minDot: open ? -.18 : .45,
      ownerCanHeal: owner == null,
      sourceCloneId: owner,
    );
    if (open) {
      final gained = 13 + rank * 7.0;
      if (fighter == null) {
        shield += gained;
      } else {
        fighter.shield += gained;
      }
    }
    _bestiaryCue(LiteBestiaryCue.roll, point, direction, reach, owner ?? 0);
  }

  void _bestiaryRing(
    Point<double> source,
    Point<double> direction,
    double reach,
    double damage,
    double stun,
    int? owner, {
    required double minDot,
  }) {
    _encounterNoise(source, reach + 3.5);
    _bestiaryCue(
      LiteBestiaryCue.bell,
      source,
      direction * acos(minDot.clamp(-1, 1)),
      reach,
      owner ?? 0,
    );
    for (final foe in enemies) {
      if (foe.hp <= 0 || _enemyIntangible(foe)) continue;
      final point = foe.closestHitboxPoint(source);
      if ((point != source &&
              !LiteRun._inArc(
                source,
                direction,
                point,
                reach,
                minDot: minDot,
              )) ||
          _lineBlocked(source, point))
        continue;
      _hitEnemy(
        foe,
        damage,
        ownerCanHeal: owner == null,
        sourceCloneId: owner,
        impactFrom: source,
      );
      if (foe.hp <= 0) continue;
      final cap = foe.kind.boss
          ? .22
          : foe.kind.elite
          ? .45
          : stun;
      foe.stunned = max(foe.stunned, min(stun, cap));
      foe.shockRemaining = max(foe.shockRemaining, min(stun * .86, cap));
      foe.windup = 0;
    }
  }

  void _hostileBell(
    LiteEnemy caster,
    Point<double> direction,
    double reach,
    double damage, {
    double stun = .37,
    double minDot = -1.1,
  }) {
    final at = caster.position;
    _bestiaryCue(
      LiteBestiaryCue.bell,
      at,
      direction * acos(minDot.clamp(-1, 1)),
      reach,
      caster.id,
    );
    bool connects(Point<double> target) =>
        (target == at ||
            LiteRun._inArc(at, direction, target, reach, minDot: minDot)) &&
        !_lineBlocked(at, target);

    if (!hostDown && connects(position)) {
      final prior = hp;
      _damagePlayer(damage);
      if (hp > 0 && hp < prior) {
        _night.stun = max(_night.stun, stun);
        _windup = 0;
      }
    }
    for (final ally in _damageableAllies) {
      if (ally.hp <= 0 || !connects(ally.position)) continue;
      final prior = ally.hp;
      _hitAlly(ally, damage);
      if (ally is LiteCoopFighter && ally.hp > 0 && ally.hp < prior) {
        ally._night.stun = max(ally._night.stun, stun);
        ally._windup = 0;
      }
    }
  }

  void _tickTerritorialArmadillo(LiteEnemy animal, double elapsed) {
    animal.shockRemaining = max(0, animal.shockRemaining - elapsed);
    if (animal.shockRemaining <= 0) animal.shockSource = null;
    if (_combatantsSheltered) {
      animal.windup = 0;
      animal.attackTarget = null;
      return;
    }
    final at = animal.position;
    var close = double.infinity;
    Point<double>? threat;
    var chased = false;
    void notice(Point<double> point, LiteStride stride, {required bool dash}) {
      final distance = point.distanceTo(at);
      if (distance >= close || distance > 4.6 || _lineBlocked(at, point))
        return;
      close = distance;
      threat = point;
      chased =
          distance < 1.65 &&
          (dash || stride.speed > 3.85 && stride.walking != true);
    }

    if (!_assassinVeiled) {
      if (!hostDown && !_boxHiddenFrom(0, animal.id)) {
        notice(position, stride, dash: _burstTime > 0);
      }
      for (final fighter in coopFighters) {
        if (fighter.hp <= 0 || !fighter.connected ||
            _boxHiddenFrom(fighter.id, animal.id)) {
          continue;
        }
        notice(
          fighter.position,
          fighter.stride,
          dash: fighter._dashRemaining > 0,
        );
      }
    }
    if (threat != null &&
        (animal.windup > 0 ||
            chased ||
            animal.shockSource != null ||
            faunaAggressive)) {
      _enemyTick(animal, elapsed);
      return;
    }
    // A slow approach makes the creature withdraw without affecting room clearance.
    animal.hitFlash = max(0, animal.hitFlash - elapsed);
    animal.attackTarget = null;
    animal.windup = 0;
    animal.cooldown = max(0, animal.cooldown - elapsed);
    if (threat case final nearby? when close < 2.55) {
      animal.position = _chooseLane(
        at,
        LiteRun._unit(at - nearby),
        elapsed * (close < 1.4 ? 5.7 : 2.1),
        animal.radius,
        rightFirst: animal.id.isEven,
      );
    }
  }

  void _hostileArmadilloCue(LiteEnemy enemy, Point<double> direction) =>
      _bestiaryCue(
        LiteBestiaryCue.roll,
        enemy.position,
        direction,
        1.35 + enemy.radius,
        enemy.id,
      );
}
