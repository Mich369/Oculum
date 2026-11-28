part of 'oculum_lite_run.dart';

extension LiteMirrorSkills on LiteRun {
  double get _mirrorSkillPace => switch (difficulty) {
    LiteDifficulty.moltoFacile => .62,
    LiteDifficulty.facile => .80,
    LiteDifficulty.medio => 1,
    LiteDifficulty.difficile => 1.28,
    LiteDifficulty.oculum => 1.65,
  };

  void _spawnMirrorWave(LiteEnemyKind kind) {
    const arrivals = [
      Point<double>(28.3, 11),
      Point<double>(27, 7),
      Point<double>(27, 15),
      Point<double>(23, 11),
      Point<double>(25, 4.6),
      Point<double>(25, 17.4),
    ];
    final seats = <LiteCoopFighter?>[null, ...coopFighters];
    for (final (index, copy) in seats.indexed) {
      _seatChampion(_spawnEnemy(kind, arrivals[index], mirrorOf: copy));
    }
  }

  bool _mirrorExtraTalent(
    LiteEnemy boss,
    Point<double> direction,
    double distance,
  ) {
    final build = boss.mirror!;
    final damage =
        (12 + build.sourceLevel * 1.7) *
        difficulty.enemyStrength *
        _challengeDamageScale(boss.kind);
    switch (build.hero) {
      case LiteHero.moscaCampana:
        if (distance > 4.1) return false;
        _hostileBell(boss, direction, 4.1, damage, stun: .46, minDot: .32);
      case LiteHero.armadilloCorazzato:
        if (distance > 3.9) return false;
        _mirrorMelee(boss, direction, 3.9, damage, minDot: .45);
        _hostileArmadilloCue(boss, direction);
      case LiteHero.gablyn:
        if (distance > 4.2) return false;
        _mirrorMelee(boss, direction, 4.2, damage, minDot: .62);
        _frontierCue(
          LiteFrontierEffect.caveCut,
          boss.id,
          boss.position,
          boss.position + direction * 4.2,
          1,
        );
      case LiteHero.funerys:
        if (distance > 5.65) return false;
        _mirrorMelee(boss, direction, 5.65, damage * .72, minDot: .62);
        final center = _frontierGround(boss.position, direction, 3.3);
        _frontierCue(
          LiteFrontierEffect.shroud,
          boss.id,
          center,
          center + direction,
          2.4,
        );
      case LiteHero.fabbro:
        if (distance > 5.2) return false;
        _mirrorMelee(boss, direction, 5.2, damage * 1.1, minDot: -1.1);
        _recordImpact(LiteImpactTarget.explosion, boss.id, boss.position);
      case LiteHero.ashley:
        if (distance > LiteRun.springRange) return false;
        _mirrorMelee(boss, direction, LiteRun.springRange, damage, minDot: .79);
      case LiteHero.scostubandito:
        if (distance > 8) return false;
        if (distance <= 2.1) {
          _mirrorMelee(boss, direction, 2.1, damage);
        } else {
          projectiles.add(
            LiteProjectile(
              position: boss.position,
              direction: direction,
              speed: 11,
              remaining: 7,
              damage: damage,
              fromEnemy: true,
              kind: LiteProjectileKind.bomb,
            ),
          );
        }
      case LiteHero.curatorePeste || LiteHero.granScostumato:
        if (distance > 10 || !_summonMirrorEcho(boss, summoned: true))
          return false;
      default:
        return false;
    }
    build.talentCooldown = 4.8;
    boss._strikePose = .24;
    return true;
  }

  bool _castMirrorLearnedArt(
    LiteEnemy boss,
    Point<double> direction,
    double distance, {
    bool secondary = false,
  }) {
    final build = boss.mirror!;
    final art = secondary ? build.secondaryArt : build.chosenArt;
    if (art == null || build.oculum < art.cost) return false;
    final rank = art.rankAt(build.sourceLevel);
    final modifier =
        difficulty.enemyStrength * _challengeDamageScale(boss.kind);
    switch (art) {
      case LiteLearnedArt.plasma:
        if (distance > 11 + rank * .8) return false;
        projectiles.add(
          LiteProjectile(
            position: boss.position,
            direction: direction,
            speed: 40,
            remaining: 11 + rank * .8,
            damage: (17 + rank * 7) * modifier,
            fromEnemy: true,
            magic: true,
            kind: LiteProjectileKind.plasma,
          ),
        );
      case LiteLearnedArt.falci:
        if (distance > 10) return false;
        _lunarVolley(
          boss.position,
          direction,
          (10 + 4 * rank) * modifier,
          enemy: true,
        );
      case LiteLearnedArt.linfa:
        if (boss.hp >= boss.maxHp * .79) return false;
        boss.hp = min(boss.maxHp, boss.hp + boss.maxHp * (.11 + .045 * rank));
      case LiteLearnedArt.pattuglia || LiteLearnedArt.lame:
        final reach = 2.9 + rank * .42;
        if (distance > reach + LiteRun._playerRadius) return false;
        _mirrorMelee(
          boss,
          direction,
          reach,
          (12 + rank * 4) * modifier,
          minDot: art == LiteLearnedArt.lame ? .11 : .68,
        );
      case LiteLearnedArt.corruzione:
        if (distance > 3.3 + rank * .25) return false;
        _mirrorMelee(
          boss,
          direction,
          3.3 + rank * .25,
          (9 + rank * 5) * modifier,
          minDot: -.16,
        );
      case LiteLearnedArt.brace:
        if (distance > 10) return false;
        _castInkBrace(
          boss.position,
          direction,
          rank,
          hostile: true,
          damageScale: modifier,
        );
      case LiteLearnedArt.basalto:
        final reach = 5.6 + .9 * rank;
        if (distance > reach) return false;
        _mirrorMelee(
          boss,
          direction,
          reach,
          (18 + 6 * rank) * modifier,
          minDot: .97,
        );
      case LiteLearnedArt.ecoVelata:
        if (!_summonMirrorEcho(boss, summoned: true, usingOpen: true))
          return false;
        _summonMirrorEcho(boss, summoned: true, usingOpen: true);
      case LiteLearnedArt.passoSenzaLuce:
        if (distance > 9 || boss.clashRemaining > 0) return false;
        boss
          ..clashDirection = direction
          ..clashRemaining = .29 + .055 * rank;
        build.intangible = boss.clashRemaining;
      case LiteLearnedArt.filoOmbra:
        if (distance > 7 + rank * 1.2) return false;
        _beginShadowRay(
          boss.id,
          boss.position,
          direction,
          rank,
          hostile: true,
          strength: modifier,
        );
    }
    _markArtCast(art, boss.position, direction, rank, casterId: boss.id);
    build.oculum -= art.cost;
    if (secondary) {
      build.secondaryArtCooldown = art.cooldown;
    } else {
      build.artCooldown = art.cooldown;
    }
    build.learnedUses++;
    boss._strikePose = .24;
    return true;
  }

  bool _tryMirrorTechnique(
    LiteEnemy boss,
    Point<double> direction,
    double distance,
  ) {
    final build = boss.mirror!;
    final item = build.weapon.moveset;
    if (build.techniqueCooldown > 0 ||
        build.oculum < LiteWeaponArt.weaponArtCost ||
        build.hero.bodyOnly || build.hero == LiteHero.doppelganger ||
        LiteAnimal.forHero(build.hero) != null)
      return false;
    final reach = item == LiteWeapon.spadaScudo
        ? 3.1 * (1 + build.forgeRank / 12)
        : item.range * (1 + build.forgeRank * .025);
    if (distance > reach + LiteRun._playerRadius) return false;
    if (item == LiteWeapon.spadaScudo) {
      build.shield = max(build.shield, 8 + build.forgeRank.toDouble());
      _mirrorMelee(
        boss,
        direction,
        reach,
        build.damage * .82 * difficulty.enemyStrength,
        minDot: build.forgeRank == 12 ? -1e-9 : -.2,
      );
    } else if (LiteRun._usesRangedWeapon(boss) &&
        item != LiteWeapon.falceRunica) {
      _fireMirrorWeapon(boss, _rotate(direction, -.14), .62);
      _fireMirrorWeapon(boss, _rotate(direction, .14), .62);
    } else {
      _fireMirrorWeapon(boss, direction, 1.15);
    }
    build.oculum -= LiteWeaponArt.weaponArtCost;
    build.techniqueCooldown = LiteWeaponArt.weaponArtRecovery;
    boss._strikePose = .24;
    return true;
  }
}

extension LiteMirrorOpen on LiteRun {
  bool _copyOpen(LiteEnemy boss, Point<double> direction, double distance) {
    final build = boss.mirror!;
    if (_openScenes.isNotEmpty ||
        build.openCooldown > 0 ||
        build.oculum < LiteRun.granSummonCost ||
        distance > 10.5 ||
        build.hero == LiteHero.doppelganger)
      return false;
    final at = boss.position;
    final grade = LiteRun.openGradeFor(build.sourceLevel);
    final strength =
        difficulty.enemyStrength * _challengeDamageScale(boss.kind);
    void fan(
      int count,
      double spread,
      double damage, {
      double range = 10,
      double speed = 15,
      LiteProjectileKind type = LiteProjectileKind.normal,
    }) {
      for (var i = 0; i < count; i++) {
        final angle = (i - (count - 1) / 2) * spread;
        projectiles.add(
          LiteProjectile(
            position: boss.position,
            direction: _rotate(direction, angle),
            speed: speed,
            remaining: range,
            damage: damage * strength,
            fromEnemy: true,
            magic: true,
            kind: type,
          ),
        );
      }
    }

    void dash(double metres, double protection) {
      var remaining = metres;
      while (remaining > 0) {
        final step = min(.2, remaining);
        final next = _move(boss.position, direction * step, boss.radius);
        if (next == boss.position) break;
        boss.position = next;
        remaining -= step;
      }
      build.intangible = max(build.intangible, protection);
    }

    void strike(double reach, double damage, {double dot = -.2}) {
      _mirrorMelee(boss, direction, reach, damage * strength, minDot: dot);
    }

    void burst(double radius, double power) {
      if (!hostDown &&
          position.distanceTo(boss.position) <= radius &&
          !_lineBlocked(boss.position, position)) {
        _damagePlayer(power * strength);
      }
      for (final ally in _damageableAllies) {
        if (ally.hp > 0 &&
            ally.position.distanceTo(boss.position) <= radius &&
            !_lineBlocked(boss.position, ally.position))
          _hitAlly(ally, power * strength);
      }
      _recordImpact(LiteImpactTarget.explosion, boss.id, boss.position);
    }

    switch (build.hero) {
      case LiteHero.moscaCampana:
        final reach = 5.80 + grade * .36;
        if (distance > reach) return false;
        _hostileBell(boss, direction, reach, (19 + grade * 5) * strength, stun: .74);
      case LiteHero.armadilloCorazzato:
        if (distance > 6.3) return false;
        boss..clashDirection = direction..clashRemaining = .31;
        build.intangible = max(build.intangible, .31);
        build.shield += 13 + grade * 7;
        strike(3.8, 18 + grade * 5, dot: -.18);
        _hostileArmadilloCue(boss, direction);
      case LiteHero.gablyn:
        if (distance > 8.8) return false;
        boss
          ..clashDirection = direction
          ..clashRemaining = .30;
        build.intangible = max(build.intangible, .30);
        fan(3, .27, 16 + grade * 4, range: 8.8, speed: 16);
        _frontierCue(
          LiteFrontierEffect.shaleFan,
          boss.id,
          at,
          at + direction * 8.8,
          1,
        );
      case LiteHero.funerys:
        final center = _frontierGround(at, direction, 4.8);
        final radius = 4.8 + grade * .25;
        final damage = (14 + 4 * grade) * strength;
        bool inShroud(Point<double> target) =>
            center.distanceTo(target) <= radius &&
            !_lineBlocked(center, target) &&
            !_lineBlocked(at, target);
        if (!hostDown && inShroud(position)) _damagePlayer(damage);
        for (final ally in _damageableAllies) {
          if (ally.hp > 0 && inShroud(ally.position)) _hitAlly(ally, damage);
        }
        _frontierCue(
          LiteFrontierEffect.shroud,
          boss.id,
          center,
          center + direction,
          radius,
        );
      case LiteHero.ragnoSaldatore:
        _milestoneWave(
          this,
          boss.position,
          direction,
          25 * strength,
          null,
          kind: LiteProjectileKind.plasma,
          range: 11,
          speed: 33,
          hostile: true,
        );
      case LiteHero.rasvyr:
        burst(3.1 + grade * .32, 21 + grade * 6);
      case LiteHero.lupoDiVaitern:
        _lunarVolley(boss.position, direction, 16 + grade * 4, enemy: true);
      case LiteHero.pysciwarden:
        for (final side in [-.22, 0.0, .22]) {
          _milestoneWave(
            this,
            boss.position,
            _rotate(direction, side),
            14 * strength,
            null,
            kind: LiteProjectileKind.frostBolt,
            range: 8,
            hostile: true,
          );
        }
      case LiteHero.lusierTre:
        burst(3.35, 23 + grade * 4);
      case LiteHero.fabbro:
        if (distance > 8) return false;
        burst(4.6, 19 + grade * 4);
        for (final offset in [-.52, -.26, 0.0, .26, .52]) {
          projectiles.add(
            LiteProjectile(
              position: boss.position,
              direction: _rotate(direction, offset),
              speed: 8.6,
              remaining: 8.5,
              damage: (10 + grade * 2) * strength,
              fromEnemy: true,
              kind: LiteProjectileKind.normal,
            ),
          );
        }
      case LiteHero.evasore:
        dash(4.1 + grade, .48 + (grade - 1) * .10);
      case LiteHero.ombra:
        dash(4.6 + grade * .65, 3);
      case LiteHero.duplicatore:
        if (!_summonMirrorEcho(boss, usingOpen: true)) return false;
        _summonMirrorEcho(boss, usingOpen: true);
      case LiteHero.ashley:
        if (distance > 5.5 + .45 * (grade - 1)) return false;
        strike(
          5 + .45 * (grade - 1),
          29 + 3.8 * build.sourceLevel + grade * 7,
          dot: .69,
        );
      case LiteHero.scostubandito:
        if (!_summonMirrorEcho(
          boss,
          summoned: true,
          usingOpen: true,
          echoHero: LiteHero.granScostumato,
          echoWeapon: LiteWeapon.fucileScostubandito,
        ))
          return false;
      case LiteHero.granScostumato || LiteHero.reGoblin:
        if (!_summonMirrorEcho(
          boss,
          summoned: true,
          usingOpen: true,
          echoHero: LiteHero.scostubandito,
          echoWeapon: LiteWeapon.fucileScostubandito,
        ))
          return false;
        _summonMirrorEcho(
          boss,
          summoned: true,
          usingOpen: true,
          echoHero: LiteHero.scostubandito,
          echoWeapon: LiteWeapon.fucileScostubandito,
        );
      case LiteHero.cavaliereLunare:
        if (!_summonMirrorEcho(
          boss,
          summoned: true,
          usingOpen: true,
          echoHero: LiteHero.cavaliereLunare,
          echoWeapon: LiteWeapon.spadaScudo,
        ))
          return false;
      case LiteHero.pyrel || LiteHero.diavolo:
        fan(
          build.hero == LiteHero.pyrel ? 3 : 5,
          .31,
          17 + grade * 5,
          type: LiteProjectileKind.fireball,
        );
      case LiteHero.lithra:
        fan(3, .32, 17 + grade * 6, range: 6.5 + grade * .7);
        _recordImpact(LiteImpactTarget.explosion, boss.id, at);
      case LiteHero.veyrth:
        fan(5 + grade * 2, 2 * pi / (5 + grade * 2), 12 + grade * 3, speed: 12);
      case LiteHero.aerovyr:
        fan(5, .31, 14 + grade * 6, speed: 13);
      case LiteHero.pollo || LiteHero.polloMeccanico:
        fan(
          3,
          .31,
          16 + grade * (build.hero == LiteHero.polloMeccanico ? 7 : 5),
          range: 6,
          speed: 9,
          type: LiteProjectileKind.bomb,
        );
      case LiteHero.raganella ||
          LiteHero.pipistrello ||
          LiteHero.vedettaEiva ||
          LiteHero.demoneMinore ||
          LiteHero.demoneMaggiore:
        dash(3.8 + grade * .35, build.hero == LiteHero.pipistrello ? .85 : .40);
        burst(2.6 + grade * .25, 14 + grade * 7);
      case LiteHero.eliteSolare:
        fan(
          1,
          0,
          24 + grade * 7,
          range: 13,
          speed: 42,
          type: LiteProjectileKind.plasma,
        );
      case LiteHero.guardiaSolare:
        dash(3.4 + grade * .35, .43);
        build.shield += 8 + grade * 4;
        strike(3.3, 17 + grade * 6);
      case LiteHero.babyForestDemon:
        if (distance > 5.6) return false;
        strike(
          3.9 + grade * .50,
          25.0 + grade * 12 + 2 * build.sourceLevel,
          dot: .25,
        );
      case LiteHero.luce || LiteHero.sentinella || LiteHero.aberrazioneSolare:
        build.shield += 12 + grade * 6;
        burst(3.20 + grade * .45, 19 + grade * 6);
      case LiteHero.slimeBlu:
        if (distance > 3.3) return false;
        build.shield += 12 + grade * 4;
        strike(3.3, 16 + grade * 6);
        boss.hp = min(boss.maxHp, boss.hp + 11 + grade * 2);
      case LiteHero.guardianoSolare:
        build.formRemaining = 4 + grade.toDouble();
      case LiteHero.vampiro || LiteHero.curatorePeste:
        build.formRemaining = 4.5 + grade * .5;
        build.shield += boss.maxHp * .42;
      case LiteHero.demoneIntermedio ||
          LiteHero.vesanybel ||
          LiteHero.dronePostea:
        if (distance > 4.5 + grade * .4) return false;
        burst(3.3 + grade * .5, 18 + grade * 8);
      case LiteHero.doppelganger:
        return false;
    }
    build.openCooldown = LiteRun.openRecoveryFor(grade);
    build.oculum -= LiteRun.granSummonCost;
    build.artCooldown = max(build.artCooldown, .72);
    boss._strikePose = .24;
    build.openUses++;
    if (_presentingFrame) {
      _openScenes.add(
        LiteOpenScene._(
          build.hero,
          at,
          direction,
          build.playerId,
          enemyId: boss.id,
          shadow: boss.kind == LiteEnemyKind.ombra,
        ),
      );
    }
    return true;
  }
}
