part of 'oculum_lite_run.dart';

extension LiteWeaponTechniques on LiteWeapon {
  String get technique => switch (this) {
    LiteWeapon.boomerang => 'Doppio rimbalzo',
    LiteWeapon.chakram => 'Doppia orbita',
    LiteWeapon.spadaScudo => 'Riposta di ferro',
    LiteWeapon.guanti => 'Pugno tellurico',
    LiteWeapon.arco => 'Ventaglio a tre frecce',
    LiteWeapon.scettro => 'Corona folgorante',
    LiteWeapon.falceRunica => 'Richiamo di falce',
    LiteWeapon.doppieLame => 'Taglio di passaggio',
    LiteWeapon.carabinaImpulsi => 'Doppio impulso',
    LiteWeapon.piccaOssidiana => 'Stoccata lunga',
    LiteWeapon.balestraRunica => 'Doppio quadrello',
    LiteWeapon.fucileScostubandito => 'Colpo concentrato',
  };
}

extension LiteWeaponArt on LiteRun {
  static const weaponArtCost = 3.0;
  static const weaponArtRecovery = 4.2;

  bool hasWeaponArt([LiteCoopFighter? fighter]) {
    final character = fighter?.hero ?? hero;
    return character != LiteHero.doppelganger &&
        LiteAnimal.forHero(character) == null;
  }

  LiteWeapon techniqueWeapon([LiteCoopFighter? fighter]) =>
      (fighter?._night ?? _night).solarMace > 0
      ? LiteWeapon.guanti
      : fighter?.weapon ?? weapon;

  String weaponArtLabel([LiteCoopFighter? fighter]) =>
      (fighter?.hero ?? hero) == LiteHero.scostubandito
      ? 'Fucile schivata'
      : techniqueWeapon(fighter).technique;

  bool useWeaponArt(Point<double> target, [LiteCoopFighter? fighter]) {
    final origin = fighter?.position ?? position;
    final kind = fighter?.hero ?? hero;
    final item = techniqueWeapon(fighter);
    final available = fighter?.oculum ?? oculum;
    final motion = fighter?._night ?? _night;
    final facing = LiteRun._unit(target - origin);
    final direction = facing.magnitude > 0 ? facing : fighter?.aim ?? aim;
    if (!hasWeaponArt(fighter) ||
        finished ||
        shopOpen ||
        restHub ||
        (fighter?.hp ?? hp) <= 0 ||
        (fighter?.blocking ?? blocking) ||
        motion.bat > 0 ||
        motion.stun > 0 ||
        (fighter?._windup ?? _windup) > 0 ||
        _rescueFor(fighter) != null) {
      return false;
    }
    if (kind == LiteHero.scostubandito) return _armBanditRifle(fighter);
    if (available < weaponArtCost ||
        (fighter?.weaponArtCooldown ?? weaponArtCooldown) > 0)
      return false;
    if (item == LiteWeapon.arco && (fighter?.arrows ?? arrows) < 3) {
      message = 'Il ventaglio richiede tre frecce.';
      return false;
    }
    final owner = fighter?.id;
    final damage =
        12 + item.damageBonus + ((fighter?.level ?? level) - 1) * 1.8;
    if (fighter == null) {
      aim = direction;
      oculum -= weaponArtCost;
      weaponArtCooldown = weaponArtRecovery;
    } else {
      fighter
        ..aim = direction
        ..oculum -= weaponArtCost
        ..weaponArtCooldown = weaponArtRecovery;
    }
    void shot(
      double angle,
      double range,
      double speed,
      double power, {
      LiteProjectileKind type = LiteProjectileKind.normal,
      bool returns = false,
    }) {
      projectiles.add(
        LiteProjectile(
          position: origin,
          direction: _rotate(direction, angle),
          speed: speed,
          remaining: range,
          damage: power,
          magic: item == LiteWeapon.scettro,
          kind: type,
          boomerang: returns,
          sourceCloneId: owner,
          ownerCanHeal: owner == null,
        ),
      );
    }

    void melee(
      double reach,
      double power, {
      double arc = .32,
      Point<double>? at,
    }) {
      _melee(
        at ?? origin,
        direction,
        item,
        power,
        reach: reach,
        minDot: arc,
        sourceCloneId: owner,
        ownerCanHeal: owner == null,
      );
    }

    switch (item) {
      case LiteWeapon.boomerang || LiteWeapon.chakram:
        final type = item == LiteWeapon.chakram
            ? LiteProjectileKind.chakram
            : LiteProjectileKind.normal;
        shot(-.24, 8, 14, damage * .7, type: type, returns: true);
        shot(.24, 8, 14, damage * .7, type: type, returns: true);
      case LiteWeapon.spadaScudo:
        if (fighter == null) {
          shield = max(shield, 8);
        } else {
          fighter.shield = max(fighter.shield, 8);
        }
        melee(3.1, damage, arc: -.2);
      case LiteWeapon.guanti:
        _openBurst(origin, 3.15, damage, owner ?? 0, push: 2.1);
      case LiteWeapon.arco:
        if (fighter == null) {
          _arrows -= 3;
        } else {
          fighter.arrows -= 3;
        }
        for (final angle in [-.24, 0.0, .24]) {
          shot(angle, 10, 20, damage * .65);
        }
      case LiteWeapon.scettro:
        _staffShock(origin, damage, sourceFighterId: owner);
        for (final angle in [-.20, 0.0, .20]) {
          shot(
            angle,
            7.8,
            14.5,
            damage * .64,
            type: LiteProjectileKind.frostBolt,
          );
        }
      case LiteWeapon.falceRunica:
        melee(3.2, damage * .63, arc: .02);
        shot(
          0,
          LiteWeapon.scytheReturnRange,
          15,
          damage,
          type: LiteProjectileKind.scythe,
          returns: true,
        );
      case LiteWeapon.doppieLame:
        _playableShadowStep(
          origin,
          direction,
          fighter,
          distance: 3.1,
          protection: .23,
        );
        melee(2.4, damage, arc: -.1, at: fighter?.position ?? position);
      case LiteWeapon.carabinaImpulsi:
        shot(-.07, 13, 21, damage, type: LiteProjectileKind.pulse);
        shot(.07, 13, 21, damage, type: LiteProjectileKind.pulse);
      case LiteWeapon.piccaOssidiana:
        melee(5.3, damage * 1.2, arc: .88);
      case LiteWeapon.balestraRunica:
        shot(-.11, 11, 22, damage * .88, type: LiteProjectileKind.pulse);
        shot(.11, 11, 22, damage * .88, type: LiteProjectileKind.pulse);
      case LiteWeapon.fucileScostubandito:
        shot(0, 12, 24, damage * 1.25, type: LiteProjectileKind.rifleBullet);
    }
    message = '${item.technique} · tecnica dell’arma.';
    return true;
  }
}
