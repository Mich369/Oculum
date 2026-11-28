part of 'oculum_lite_run.dart';

extension LiteLusierSkill on LiteRun {
  bool callSolarRetinue([LiteCoopFighter? fighter]) {
    final available = fighter?.oculum ?? oculum;
    if ((fighter?.hero ?? hero) != LiteHero.lusierTre ||
        finished ||
        restHub ||
        shopOpen ||
        (fighter?.hp ?? hp) <= 0 ||
        gripRemaining(fighter) > 0 ||
        available < 5)
      return false;
    final source = fighter?.position ?? position;
    final direction = fighter?.aim ?? aim;
    final owner = fighter?.id ?? 0;
    final grade = fighter?.openGrade ?? openGrade;
    final guard = _summonCompanions(
      LiteCompanion.guardiaDiLusier,
      2,
      source,
      direction,
      owner,
      grade,
    );
    final elite = _summonCompanions(
      LiteCompanion.eliteDiLusier,
      1,
      source,
      direction * -1.0,
      owner,
      grade,
    );
    if (!guard && !elite) return false;
    if (fighter == null) {
      oculum -= 5;
    } else {
      fighter.oculum -= 5;
    }
    _milestoneEffect(
      owner,
      source,
      direction,
      LiteRelicFamily.spadaLusier.index.toDouble(),
      3,
    );
    message = 'Scorta di Lusier · Due Guardie e un’Elité.';
    return true;
  }

  void _rechargeLusier(LiteRestLoadout kit, double elapsed) {
    if (kit.lusierCards >= 12) return;
    kit._lusierRecharge += elapsed / arenaSpeed;
    if (kit._lusierRecharge + 1e-9 >= 1) {
      kit.lusierCards = min(12, kit.lusierCards + 3);
      kit._lusierRecharge = max(0, kit._lusierRecharge - 1);
    }
  }

  void _withLusierVolley(
    Point<double> at,
    Point<double> direction,
    LiteCoopFighter? fighter,
    void Function() release,
  ) {
    if ((fighter?.hero ?? hero) != LiteHero.lusierTre) {
      release();
      return;
    }
    final volley = _nextId++;
    _activeLusierAttack = volley;
    try {
      release();
    } finally {
      _activeLusierAttack = null;
    }
    final kit = fighter?.supply ?? supply;
    if (kit.lusierCards < 3 || clashDashing && fighter == null) return;
    kit.lusierCards -= 3;
    final damage =
        4 +
        (fighter?.level ?? level) * 1.25 +
        kit.forgeRank(fighter?.weapon ?? weapon) * .25;
    for (final spread in [-.16, 0.0, .16]) {
      projectiles.add(
        LiteProjectile(
          position: at,
          direction: _rotate(direction, spread),
          speed: 28,
          remaining: 9.5,
          damage: damage,
          magic: true,
          kind: LiteProjectileKind.cartaLusier,
          ownerCanHeal: fighter == null,
          sourceCloneId: fighter?.id,
        )..lusierVolley = volley,
      );
    }
  }

  void _tickBunnys(LiteEnemy helper, double elapsed) {
    helper.cooldown = max(0, helper.cooldown - elapsed);
    final injured =
        enemies
            .where(
              (enemy) =>
                  enemy != helper &&
                  enemy.hp > 0 &&
                  enemy.hp < enemy.maxHp &&
                  enemy.position.distanceTo(helper.position) <= 6.0 &&
                  !_lineBlocked(helper.position, enemy.position),
            )
            .toList()
          ..sort((a, b) => (a.hp / a.maxHp).compareTo(b.hp / b.maxHp));
    final patient = injured.firstOrNull;
    if (helper.windup > 0) {
      helper.windup = max(0, helper.windup - elapsed);
      if (helper.windup == 0) {
        if (patient != null) {
          helper._strikePose = .24;
          _bunnysHeal(patient, .25, helper.position);
        }
        helper.cooldown = 4.7;
      }
      return;
    }
    if (helper.cooldown == 0 && patient != null) {
      helper
        ..attackTarget = patient.position
        ..windup = .41;
      return;
    }
    final player = _enemyAimFrom(helper.position);
    final away = LiteRun._unit(helper.position - player);
    if (helper.position.distanceTo(player) < 4.2) {
      helper.position = _chooseLane(
        helper.position,
        away,
        4.2 * elapsed,
        helper.radius,
        rightFirst: helper.id.isEven,
      );
    } else if (patient == null) {
      final other = enemies
          .where(
            (enemy) =>
                enemy != helper && enemy.hp > 0 && enemy.hp < enemy.maxHp,
          )
          .firstOrNull;
      if (other != null) {
        helper.position = _chooseLane(
          helper.position,
          LiteRun._unit(other.position - helper.position),
          3.1 * elapsed,
          helper.radius,
          rightFirst: true,
        );
      }
    }
  }

  Iterable<LiteClone> _bunnysPetPatients(LiteClone healer) =>
      _damageableAllies.where(
        (ally) =>
            ally != healer &&
            ally.hp > 0 &&
            !ally.corrupted &&
            !ally.forgedWeapon,
      );

  void _tickPetBunnys(LiteClone healer, double elapsed) {
    final owner = _coopFighterById(healer.ownerId);
    final ownerPosition = owner?.position ?? position;
    final needsHealing = _bunnysPetPatients(healer)
        .where((ally) => ally.hp < ally.maxHp);
    var target =
        !hostDown &&
            hp < maxHp &&
            !_lineBlocked(healer.position, position) &&
            healer.position.distanceTo(position) <= 6.0
        ? (position, hp / maxHp, null as LiteClone?)
        : null;
    for (final ally in needsHealing) {
      final fraction = ally.hp / ally.maxHp;
      if (fraction < (target?.$2 ?? 1.0) &&
          healer.position.distanceTo(ally.position) <= 6.0 &&
          !_lineBlocked(healer.position, ally.position)) {
        target = (ally.position, fraction, ally);
      }
    }

    if (target != null) {
      final attackRate = _divoramituAllyAttack(healer.position);
      final wasPreparing = healer._preparingPose > 0;
      healer.cooldown = max(0, healer.cooldown - elapsed * attackRate);
      if (wasPreparing && healer.cooldown == 0) {
        _bunnysHealPartyMember(healer, target.$3, .25);
        healer._preparingPose = 0;
        healer.cooldown = 4.7;
      } else if (wasPreparing) {
        healer._preparingPose = (1 - healer.cooldown / .41).clamp(.01, 1);
      } else if (healer.cooldown == 0) {
        healer.cooldown = .41;
        healer._preparingPose = .01;
      }
      healer._poseAim = LiteRun._unit(target.$1 - healer.position);
    } else {
      healer._preparingPose = 0;
      healer.cooldown = max(0, healer.cooldown - elapsed);
    }

    if (healer._preparingPose > 0) return;
    final goal = ownerPosition + const Point(-.9, 1.4);
    if (healer.position.distanceTo(goal) <= 1.0) return;
    healer.position = _chooseLane(
      healer.position,
      LiteRun._unit(goal - healer.position),
      elapsed * 4.2 * _divoramituAllyPace(healer.position),
      .35,
      rightFirst: healer.id.isEven,
    );
  }

  void _bunnysPetDeathHeal(LiteClone healer) {
    _bunnysHealPartyMember(healer, null, .50);
    for (final ally in _bunnysPetPatients(healer)) {
      _bunnysHealPartyMember(healer, ally, .50);
    }
    message = 'Bunnys si congeda con un’ultima cura.';
  }

  void _bunnysHealPartyMember(LiteClone healer, LiteClone? ally, double share) {
    final before = ally?.hp ?? hp;
    final ceiling = ally?.maxHp ?? maxHp;
    if (before <= 0 || before >= ceiling) return;
    final amount = min(ceiling - before, before * share);
    if (ally == null) {
      hp += amount;
    } else {
      ally.hp += amount;
    }
    _recordBunnysHeal(
      ally?.id ?? 0,
      ally?.position ?? position,
      amount,
      healer.position,
    );
  }

  void _bunnysDeathHeal(LiteEnemy helper) {
    for (final enemy in enemies) {
      if (enemy != helper && enemy.hp > 0)
        _bunnysHeal(enemy, .50, helper.position);
    }
  }

  void _bunnysHeal(LiteEnemy enemy, double share, Point<double> from) {
    final amount = min(enemy.maxHp - enemy.hp, enemy.hp * share);
    if (amount <= 0) return;
    enemy.hp += amount;
    _recordBunnysHeal(enemy.id, enemy.position, amount, from);
  }

  void _recordBunnysHeal(
    int id,
    Point<double> at,
    double amount,
    Point<double> from,
  ) {
    if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
    _combatImpacts.add(
      LiteCombatImpact(
        LiteImpactTarget.bunnysHeal,
        id,
        at,
        time,
        life: amount,
        end: from,
      ),
    );
  }
}
