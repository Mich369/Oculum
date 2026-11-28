part of 'oculum_lite_run.dart';

const _assassinQuietDelay = 4.0;
const _assassinHealingRate = .08;
const _assassinFollowThrough = .11;

double _assassinLifeScale(LiteHero hero) => hero == LiteHero.assassino ? .5 : 1;

LiteWeapon _assassinPrimary(
  LiteHero hero,
  LiteWeapon weapon, {
  bool tactical = false,
}) => hero == LiteHero.assassino || weapon == LiteWeapon.pistolaRicognitore
    ? hero.startingWeapon(weapon, assassinTactical: tactical)
    : weapon;

double _assassinDamageScale(LiteHero hero, LiteWeapon weapon) =>
    hero == LiteHero.assassino && weapon == LiteWeapon.doppieLame ? 1.6 : 1;

extension _LiteAssassinCombat on LiteRun {
  bool _assassinCanEquip(LiteWeapon item, [LiteCoopFighter? fighter]) =>
      _assassinPrimary(
        fighter?.hero ?? hero,
        item,
        tactical: fighter?.assassinTactical ?? assassinTactical,
      ) ==
      item;

  void _assassinRecovery(double elapsed, [LiteCoopFighter? fighter]) {
    if ((fighter?.hero ?? hero) != LiteHero.assassino ||
        (fighter?.hp ?? hp) <= 0 ||
        fighter?.connected == false) {
      return;
    }
    final quiet = fighter?._assassinQuiet ?? _assassinQuiet;
    final remaining = max(0.0, quiet - elapsed);
    if (fighter == null) {
      _assassinQuiet = remaining;
    } else {
      fighter._assassinQuiet = remaining;
    }
    final hurt = fighter?.hp ?? hp;
    final maximum = fighter?.maxHp ?? maxHp;
    if (hurt >= maximum || quiet >= elapsed) return;
    final restored = min(
      maximum,
      hurt + maximum * _assassinHealingRate * (elapsed - quiet),
    );
    if (fighter == null) {
      hp = restored;
    } else {
      fighter.hp = restored;
    }
  }

  void _assassinBlade(
    Point<double> source,
    Point<double> direction,
    LiteCoopFighter? fighter, {
    required bool followThrough,
  }) {
    final item = fighter?.weapon ?? weapon;
    final damage = fighter == null
        ? _damageFor(item)
        : _guestWeaponDamage(fighter, item);
    final reach = weaponReach(item, fighter) + .42;
    if (!followThrough) {
      _assassinSlashCue(source, direction, reach);
    }
    _melee(
      source,
      direction,
      item,
      damage * .56,
      reach: reach,
      rearReach: followThrough ? reach * .76 : 0,
      minDot: .16,
      ownerCanHeal: fighter == null,
      sourceCloneId: fighter?.id,
    );
  }

  void _assassinLowSlash(
    Point<double> source,
    Point<double> direction,
    LiteCoopFighter? fighter,
  ) {
    final blade = LiteWeapon.doppieLame;
    final damage = fighter == null
        ? _damageFor(blade)
        : _guestWeaponDamage(fighter, blade);
    final reach = weaponReach(blade, fighter) + .78;
    _assassinSlashCue(source, direction, reach);
    _melee(
      source,
      direction,
      blade,
      damage * .93,
      reach: reach,
      rearReach: reach * .70,
      minDot: .22,
      ownerCanHeal: fighter == null,
      sourceCloneId: fighter?.id,
      canClash: false,
    );
    final side = Point(-direction.y, direction.x);
    final steer = fighter?.movement ?? _lastMove;
    final dot = steer.x * side.x + steer.y * side.y;
    final flank = dot < 0 ? side * -1.0 : side;
    _beginTravel(flank, 1.45, .16, fighter);
  }

  void _assassinOpen(
    Point<double> source,
    Point<double> direction,
    LiteCoopFighter? fighter,
    int grade,
  ) {
    final reach = 5.3 + .65 * (grade - 1);
    final owner = fighter?.id ?? 0;
    final flank = Point(-direction.y, direction.x);
    final cloneLife = (fighter?.maxHp ?? maxHp) * .20;
    _assassinSlashCue(source, direction, reach, open: true);
    _melee(
      source,
      direction,
      LiteWeapon.doppieLame,
      (22 + 6 * grade + 2 * ((fighter?.level ?? level) - 1)) *
          LiteRun.openPower,
      reach: reach,
      rearReach: reach,
      minDot: .53,
      ownerCanHeal: fighter == null,
      sourceCloneId: fighter?.id,
      canClash: false,
    );
    clones.removeWhere(
      (clone) => clone.assassinDecoy && clone.ownerId == owner,
    );
    for (final side in [-1, 1]) {
      final beside = source + flank * (side * 1.55) - direction * .65;
      clones.add(
        LiteClone(
          _safePoint(beside, .35, source),
          cloneLife,
          LiteWeapon.doppieLame,
          id: _nextId++,
          ownerId: owner,
          summoned: true,
          assassinDecoy: true,
          damageScale: .6 + .1 * (grade - 1),
        ),
      );
    }
  }

  void _assassinSlashCue(
    Point<double> source,
    Point<double> direction,
    double reach, {
    bool open = false,
  }) {
    if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
    _combatImpacts.add(
      LiteCombatImpact(
        LiteImpactTarget.assassinSlash,
        _nextId++,
        source,
        time,
        shield: open ? 1 : 0,
        end: source + direction * reach,
      ),
    );
  }

  void _tickAssassinDecoy(LiteClone clone, double elapsed) {
    clone._preparingPose = 0;
    final owner = _coopFighterById(clone.ownerId);
    if (owner?.connected == false) return;
    final pace =
        _alliedMovementTime(elapsed) *
        this.terrainSpeedAt(clone.position, enemy: false) *
        _divoramituAllyPace(clone.position);
    final before = clone.position;
    final dodge = _assassinEvadeDirection(clone);
    clone.cooldown = max(0.0, clone.cooldown - elapsed);
    if (dodge != null) {
      clone.position = _chooseLane(
        before,
        dodge,
        8.3 * pace,
        .35,
        rightFirst: clone.id.isEven,
      );
      if (clone.position != before) return;
    }

    final ownerPosition = owner?.position ?? position;
    final target = _companionTarget(clone, ownerPosition);
    final reach = clone.weapon.range + .1;
    if (dodge == null &&
        target != null &&
        LiteRun._distance(before, target.position) <=
            reach + target.hitboxRadius &&
        !_lineBlocked(before, target.position)) {
      if (clone.cooldown == 0) {
        final aim = LiteRun._unit(target.position - before);
        clone
          .._poseAim = aim
          .._swing = .24
          ..cooldown = .64;
        _melee(
          before,
          aim,
          clone.weapon,
          (6 + (clone.level - 1) * 1.3) * clone.damageScale,
          reach: reach,
          ownerCanHeal: false,
          sourceCloneId: clone.id,
        );
      }
      return;
    }

    final angle = ((clone.id % 6) + .5) * pi / 3;
    final beside = ownerPosition + Point(cos(angle), sin(angle)) * 1.65;
    if (LiteRun._distanceSquared(before, beside) > .4) {
      clone.position = _chooseLane(
        before,
        LiteRun._unit(beside - before),
        5.1 * pace,
        .35,
        rightFirst: clone.id.isEven,
      );
    }
  }

  Point<double>? _assassinEvadeDirection(LiteClone clone) {
    final at = clone.position;
    final side = clone.id.isEven ? 1.0 : -1.0;
    for (final shot in projectiles) {
      if (!shot.fromEnemy || shot.remaining <= 0) continue;
      final heading = LiteRun._unit(shot.direction);
      final delta = at - shot.position;
      final ahead = delta.x * heading.x + delta.y * heading.y;
      final across = delta.x * heading.y - delta.y * heading.x;
      if (ahead >= -.10 &&
          ahead < min(shot.remaining, max(.4, shot.speed * .32)) &&
          across.abs() < .58 &&
          !_lineBlocked(shot.position, at)) {
        final away = across.abs() < .04 ? side : (across < 0 ? -1.0 : 1.0);
        return Point(heading.y, -heading.x) * away;
      }
    }
    for (final enemy in enemies) {
      if (enemy.hp <= 0 ||
          enemy.windup <= 0 ||
          _lineBlocked(enemy.position, at)) {
        continue;
      }
      final delta = at - enemy.position;
      if (!LiteRun._usesRangedWeapon(enemy)) {
        if (delta.magnitude <= 2.1 + enemy.hitboxRadius) {
          return delta.magnitude > .05 ? LiteRun._unit(delta) : Point(0, side);
        }
        continue;
      }
      final target = enemy.attackTarget;
      if (target == null) continue;
      final heading = LiteRun._unit(target - enemy.position);
      final ahead = delta.x * heading.x + delta.y * heading.y;
      final across = delta.x * heading.y - delta.y * heading.x;
      if (ahead <= 0 || ahead > 9 || across.abs() > .9) continue;
      final away = across.abs() < .04 ? side : (across < 0 ? -1.0 : 1.0);
      return Point(heading.y, -heading.x) * away;
    }
    return null;
  }
}
