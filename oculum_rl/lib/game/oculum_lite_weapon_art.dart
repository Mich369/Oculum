part of 'oculum_lite_run.dart';

extension LiteWeaponTechniques on LiteWeapon {
  String get technique => isMilestone
      ? switch (relicFamily!) {
          LiteRelicFamily.orbita => 'Orbita del Boomerang',
          LiteRelicFamily.terramaul => 'Percossa di Terramaul',
          LiteRelicFamily.segugio => 'Caccia al plasma',
          LiteRelicFamily.canna => 'Canalstryke',
          LiteRelicFamily.spadaLusier => 'Incisione solare',
          LiteRelicFamily.mazzaGuardiano => 'Potere dell’Oro',
        }
      : switch (this) {
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
          LiteWeapon.pistolaRicognitore => 'Punto cieco',
          LiteWeapon.cheleRasvyr => 'Morsa della duna',
          LiteWeapon.piccaVaitern => 'Stoccata di Vaitern',
          LiteWeapon.vergaCorvina => 'Corona corvina',
          LiteWeapon.martelloForgia => 'Frattura della forgia',
          LiteWeapon.beccoCaverna => 'Stoccata di selce',
          LiteWeapon.falceFunerys => 'Raccolta del Sudario',
          LiteWeapon.bobinaPostea => 'Scarica a catena',
          LiteWeapon.armamentoNaturale => 'Talento naturale',
          _ => throw StateError('Arma sconosciuta'),
        };
}

extension LiteWeaponArt on LiteRun {
  static const weaponArtCost = 3.0;
  static const weaponArtRecovery = 4.2;

  bool hasWeaponArt([LiteCoopFighter? fighter]) {
    final character = fighter?.hero ?? hero;
    return !character.bodyOnly &&
        character != LiteHero.doppelganger &&
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
    _openAssassinBox(fighter);
    final owner = fighter?.id;
    final rank = (fighter?.supply ?? supply).forgeRank(item);
    final effectScale = 1 + rank / 12;
    final damage =
        (12 + item.damageBonus + ((fighter?.level ?? level) - 1) * 1.8) *
        (1 + rank * .04) *
        _swordFusionDamage(item, fighter);
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
    if (item == LiteWeapon.martelloForgia) {
      _forgeQuake(
        origin,
        damage,
        owner,
        radius: 4.0 * effectScale,
        push: 4 * effectScale,
      );
      message = item.technique;
      return true;
    }
    if (item.frontierWeapon) {
      _castFrontierWeapon(item, origin, direction, owner, damage, effectScale);
      message = item.technique;
      return true;
    }
    if (item.isMilestone) {
      _castMilestoneWeapon(
        item,
        origin,
        direction,
        damage,
        effectScale,
        fighter,
      );
      message = item.technique;
      return true;
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
          remaining: range * (1 + rank * .025),
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
      double push = 0,
    }) {
      _melee(
        at ?? origin,
        direction,
        item,
        power,
        reach: reach * effectScale,
        minDot: arc,
        push: push,
        sourceCloneId: owner,
        ownerCanHeal: owner == null,
      );
    }

    switch (item.moveset) {
      case LiteWeapon.boomerang || LiteWeapon.chakram:
        final type = item == LiteWeapon.chakram
            ? LiteProjectileKind.chakram
            : LiteProjectileKind.normal;
        shot(-.24, 8, 14, damage * .7, type: type, returns: true);
        shot(.24, 8, 14, damage * .7, type: type, returns: true);
      case LiteWeapon.spadaScudo:
        if (fighter == null) {
          shield = max(shield, 8 + rank.toDouble());
        } else {
          fighter.shield = max(fighter.shield, 8 + rank.toDouble());
        }
        melee(
          3.1,
          damage,
          arc: rank == 12 ? -1e-9 : -.2,
          push: rank.toDouble(),
        );
      case LiteWeapon.guanti:
        _openBurst(
          origin,
          3.15 * effectScale,
          damage,
          owner ?? 0,
          push: 2.1 * effectScale,
        );
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
        final landing = _playableShadowStep(
          origin,
          direction,
          fighter,
          distance: 3.1,
          protection: .23,
        );
        melee(2.4, damage, arc: -.1, at: landing);
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
      case LiteWeapon.pistolaRicognitore:
        _encounterNoise(origin, 2);
        shot(0, 9.5, 27, damage * 1.28, type: LiteProjectileKind.rifleBullet);
      default:
        throw StateError('Tecnica sconosciuta');
    }
    message = '${item.technique} · tecnica dell’arma.';
    return true;
  }
}
