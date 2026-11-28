part of 'oculum_lite_run.dart';

class LiteWeaponFusion {
  const LiteWeaponFusion(this.primary, this.secondary);
  final LiteWeapon primary;
  final LiteWeapon secondary;

  List<String> get frame => [primary.name, secondary.name];

  static LiteWeaponFusion? read(Object? data) {
    if (data is! List || data.length != 2 || data[0] == data[1]) return null;
    final primary = LiteWeapon.values
        .where((item) => item.name == data[0])
        .firstOrNull;
    final secondary = LiteWeapon.values
        .where((item) => item.name == data[1])
        .firstOrNull;
    if (primary == null || secondary == null) return null;
    return LiteWeaponFusion(primary, secondary);
  }
}

bool _hasSwordFusion(LiteWeapon equipped, LiteWeaponFusion? pair) =>
    pair != null &&
    pair.primary == equipped &&
    (equipped.moveset == LiteWeapon.spadaScudo ||
        pair.secondary.moveset == LiteWeapon.spadaScudo);

extension LiteForgeFusion on LiteRun {
  static const fusionPrice = 90;

  List<LiteWeapon> forgeInventory([LiteCoopFighter? fighter]) => fighter == null
      ? List.of(ownedWeapons)
      : {fighter.weapon, ...fighter.ownedWeapons}.toList();

  List<LiteWeapon> get signatureWeapons => {
    for (final hero in LiteHero.values)
      if (hero.fixedWeapon case final weapon? when !hero.bodyOnly) weapon,
    LiteWeapon.chakram,
    LiteWeapon.boomerang,
    LiteWeapon.cheleRasvyr,
    LiteWeapon.piccaVaitern,
    LiteWeapon.vergaCorvina,
    LiteWeapon.martelloForgia,
    LiteWeapon.bobinaPostea,
  }.toList();

  int signaturePrice(LiteWeapon item) => item.frontierWeapon
      ? LiteRestItem.values
            .firstWhere((entry) => entry.weapon == item)
            .basePrice
      : priceForWeapon(item) + (item.isBossLoot ? 18 : 0);

  bool _forgeOpen(LiteCoopFighter? fighter) =>
      canUseRestStation(LiteRestStation.forge, fighter) &&
      hasWeaponArt(fighter);

  bool canBuySignature(LiteWeapon item, [LiteCoopFighter? fighter]) =>
      _forgeOpen(fighter) &&
      signatureWeapons.contains(item) &&
      !forgeInventory(fighter).contains(item) &&
      (fighter?.obser ?? obser) >= signaturePrice(item);

  bool buySignature(LiteWeapon item, [LiteCoopFighter? fighter]) {
    if (!canBuySignature(item, fighter)) return false;
    if (fighter == null) {
      obser -= signaturePrice(item);
      ownedWeapons.add(item);
    } else {
      fighter.obser -= signaturePrice(item);
      fighter.ownedWeapons.add(item);
    }
    message = 'Equipaggiamento · ${item.label} acquistata.';
    return true;
  }

  LiteWeaponFusion? weaponFusion([LiteCoopFighter? fighter]) {
    final pair = (fighter?.supply ?? supply)._fusion;
    if (pair == null || !hasWeaponArt(fighter)) return null;
    if (fighter == null) {
      return ownedWeapons.contains(pair.primary) &&
              ownedWeapons.contains(pair.secondary)
          ? pair
          : null;
    }
    return fighter.ownedWeapons.contains(pair.primary) &&
            fighter.ownedWeapons.contains(pair.secondary)
        ? pair
        : null;
  }

  LiteWeapon? fusedWeapon([LiteCoopFighter? fighter]) {
    final pair = weaponFusion(fighter);
    return pair?.primary == (fighter?.weapon ?? weapon)
        ? pair?.secondary
        : null;
  }

  bool canFuse(
    LiteWeapon primary,
    LiteWeapon secondary, [
    LiteCoopFighter? fighter,
  ]) {
    if (!_forgeOpen(fighter) ||
        primary == secondary ||
        (fighter?.obser ?? obser) < fusionPrice)
      return false;
    final inventory = forgeInventory(fighter);
    final active = weaponFusion(fighter);
    return inventory.contains(primary) &&
        inventory.contains(secondary) &&
        (active?.primary != primary || active?.secondary != secondary);
  }

  bool fuseWeapons(
    LiteWeapon primary,
    LiteWeapon secondary, [
    LiteCoopFighter? fighter,
  ]) {
    if (!canFuse(primary, secondary, fighter)) return false;
    (fighter?.supply ?? supply)._fusion = LiteWeaponFusion(primary, secondary);
    if (fighter == null) {
      weapon = primary;
      obser -= fusionPrice;
    } else {
      fighter.weapon = primary;
      fighter.obser -= fusionPrice;
    }
    message = 'Fusione · ${primary.label} e ${secondary.label}.';
    return true;
  }

  bool splitWeapons([LiteCoopFighter? fighter]) {
    if (!_forgeOpen(fighter) || weaponFusion(fighter) == null) return false;
    (fighter?.supply ?? supply)._fusion = null;
    message = 'Fusione rimossa. Entrambe le armi sono nell’equipaggiamento.';
    return true;
  }

  bool equipFromForge(LiteWeapon item, [LiteCoopFighter? fighter]) {
    if (!_forgeOpen(fighter) ||
        !forgeInventory(fighter).contains(item) ||
        (fighter?.weapon ?? weapon) == item)
      return false;
    if (fighter == null) {
      weapon = item;
    } else {
      fighter.weapon = item;
    }
    return true;
  }

  double _swordFusionDamage(LiteWeapon item, [LiteCoopFighter? fighter]) =>
      item.moveset == LiteWeapon.spadaScudo &&
          _hasSwordFusion(fighter?.weapon ?? weapon, weaponFusion(fighter))
      ? 1.15
      : 1.0;

  bool hasBow([LiteCoopFighter? fighter]) =>
      (fighter?.weapon ?? weapon).moveset == LiteWeapon.arco ||
      fusedWeapon(fighter)?.moveset == LiteWeapon.arco;

  void setAttackHeld(bool held) {
    _attackHeld = held;
    if (!held) _heldRecovery = .30;
  }

  double _heldAttackDelay(double elapsed, [LiteCoopFighter? fighter]) {
    final main = fighter?.weapon ?? weapon;
    final second = fusedWeapon(fighter);
    final character = fighter?.hero ?? hero;
    final attackingInstantly =
        main.chargeSeconds == 0 || character.bodyOnly ||
        character == LiteHero.doppelganger ||
        character == LiteHero.slimeBlu ||
        LiteAnimal.forHero(character) != null ||
        (fighter?._night ?? _night).solarMace > 0;
    final recovering =
        (fighter?.cooldown ?? _attackCooldown) > 1e-9 ||
        (fighter?._windup ?? _windup) > 1e-9;
    if (restHub ||
        !attackingInstantly ||
        (second?.chargeSeconds ?? 0) > 0 ||
        recovering)
      return .30;
    if ((main.returns || second?.returns == true) &&
        projectiles.any(
          (shot) =>
              shot.boomerang &&
              !shot.fromEnemy &&
              shot.sourceCloneId == fighter?.id &&
              shot.remaining > 0,
        ))
      return .30;
    return max(
      0,
      (fighter?._heldRecovery ?? _heldRecovery) - elapsed / arenaSpeed,
    );
  }

  bool _activeChakrams([LiteCoopFighter? fighter]) => projectiles.any(
    (shot) =>
        shot.kind == LiteProjectileKind.chakram &&
        shot.boomerang &&
        !shot.fromEnemy &&
        shot.sourceCloneId == fighter?.id &&
        shot.remaining > 0,
  );

  bool chakramInFlight([LiteCoopFighter? fighter]) => _activeChakrams(fighter);

  bool _chakramReady([LiteCoopFighter? fighter]) =>
      (fighter?._chakramRecovery ?? _chakramRecovery) <= 1e-9 &&
      !_activeChakrams(fighter);

  void _launchChakrams(
    Point<double> from,
    Point<double> direction,
    double damage,
    double rangeScale,
    bool ownerCanHeal,
    int? id,
  ) {
    final fighter = _coopFighterById(id);
    final player = ownerCanHeal || fighter != null;
    if (player && !_chakramReady(fighter)) return;
    final orbit = player && fusedWeapon(fighter) != null;
    if (player) {
      if (fighter == null) {
        _chakramRecovery = .30;
      } else {
        fighter._chakramRecovery = .30;
      }
    }
    for (final side in [1, -1]) {
      projectiles.add(
        LiteProjectile(
            position: from,
            direction: _rotate(direction, side * .39),
            speed: 35,
            remaining: 75 * rangeScale,
            damage: damage,
            boomerang: true,
            ownerCanHeal: ownerCanHeal,
            kind: LiteProjectileKind.chakram,
            sourceCloneId: id,
          )
          ..chakramAim = direction
          ..chakramSide = side
          ..chakramOrbit = orbit
          ..age = orbit && side == -1 ? -.30 * arenaSpeed : 0,
      );
    }
  }

  Point<double>? _chakramPoint(LiteProjectile shot, double elapsed) {
    final owner = projectileReturnTarget(shot);
    final aim = shot.chakramAim!;
    final side = shot.chakramSide;
    final duration = shot.chakramOrbit ? 1.04 : .88;
    final progress = (shot.age / duration).clamp(0.0, 1.0);
    if (progress >= 1 && shot.position.distanceTo(owner) <= .52) return null;
    shot.returning = progress >= (shot.chakramOrbit ? .79 : .50);
    final arch = max(0.0, sin(pi * progress));
    final centered = shot.chakramOrbit
        ? owner +
              _rotate(aim, side * (.35 + progress * 2 * pi)) *
                  (2.7 +
                      (_weaponRangeScale(_coopFighterById(shot.sourceCloneId)) -
                              1) *
                          .6) *
                  pow(arch, .72).toDouble()
        : shot.origin +
              (owner - shot.origin) * progress +
              aim *
                  (arch *
                      (4.6 +
                          _weaponRangeScale(
                            _coopFighterById(shot.sourceCloneId),
                          ) -
                          1)) +
              Point(-aim.y, aim.x) * (side * arch * (1.15 + progress));
    var target = centered;
    if (shot.chakramOrbit && progress > .10 && progress < .87) {
      final pursued = _nearestEnemy(centered, skip: shot.hit);
      if (pursued != null &&
          centered.distanceTo(pursued.position) < 2.8 &&
          !_lineBlocked(centered, pursued.position)) {
        target =
            centered +
            LiteRun._unit(pursued.position - centered) *
                (arch * min(.85, centered.distanceTo(pursued.position)));
      }
    }
    final travel = target - shot.position;
    if (travel.magnitude <= .001) return shot.position;
    shot.direction = LiteRun._unit(travel);
    return shot.position +
        shot.direction * min(travel.magnitude, elapsed * shot.speed);
  }

  void _castFusedAttack(
    Point<double> at,
    Point<double> direction, [
    LiteCoopFighter? fighter,
  ]) {
    final item = fusedWeapon(fighter);
    if (item == null || restHub || (fighter?.hp ?? hp) <= 0) return;
    if (item.moveset == LiteWeapon.arco) {
      if ((fighter?.arrows ?? _arrows) <= 0 ||
          (fighter?._reload ?? _reloadRemaining) > 0)
        return;
      if (fighter == null) {
        _arrows--;
      } else {
        fighter.arrows--;
      }
    }
    _weaponAction(
      at,
      direction,
      item,
      fighter == null ? _damageFor(item) : _guestWeaponDamage(fighter, item),
      ownerCanHeal: fighter == null,
      sourceCloneId: fighter?.id,
    );
    if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
    _combatImpacts.add(
      LiteCombatImpact(
        LiteImpactTarget.fusionStrike,
        fighter?.id ?? 0,
        at,
        time,
        end: at + direction,
      ),
    );
  }
}

extension on LiteProjectile {
  void _readChakram(Object? frame) {
    if (kind != LiteProjectileKind.chakram ||
        frame is! List ||
        frame.length != 3 ||
        (frame[1] != 1 && frame[1] != -1))
      return;
    chakramAim = _point(frame[0]);
    chakramSide = frame[1] as int;
    chakramOrbit = frame[2] == true;
  }
}
