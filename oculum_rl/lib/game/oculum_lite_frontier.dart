part of 'oculum_lite_run.dart';

/// Identifiers carried in the existing combat-impact frame.
enum LiteFrontierEffect { caveCut, shaleFan, shroud, coil, fragment, solder }

const _individualCreatureHeroes = [LiteHero.gablyn, LiteHero.funerys, LiteHero.moscaCampana, LiteHero.armadilloCorazzato];

extension LiteFrontierWeapons on LiteWeapon {
  bool get frontierWeapon => switch (this) {
    LiteWeapon.beccoCaverna ||
    LiteWeapon.falceFunerys ||
    LiteWeapon.bobinaPostea => true,
    _ => false,
  };
}

extension _LiteFrontierCombat on LiteRun {
  static String unlockKey(LiteHero hero, String account) =>
      '${LiteRun.heroUnlockKey(hero)}-ospite-$account';

  void _frontierDefeat(
    LiteEnemyKind defeated,
    LiteCoopFighter? fighter,
    int? sourceCloneId,
    bool ownerCanHeal,
  ) {
    final unlocked = switch (defeated) {
      LiteEnemyKind.gablyn => LiteHero.gablyn,
      LiteEnemyKind.funerys => LiteHero.funerys,
      LiteEnemyKind.moscaCampana => LiteHero.moscaCampana,
      LiteEnemyKind.armadilloCorazzato => LiteHero.armadilloCorazzato,
      _ => null,
    };
    final pet = switch (defeated) {
      LiteEnemyKind.ragnoSaldatore => LiteCompanion.saldino,
      LiteEnemyKind.lapysrieth => LiteCompanion.frammentoLapysrieth,
      _ => null,
    };
    if (unlocked == null && pet == null) return;
    final ally = clones.where((clone) => clone.id == sourceCloneId).firstOrNull;
    final owner = fighter ?? _coopFighterById(ally?.ownerId);
    final account = owner?.account;
    if (account == null && !ownerCanHeal && ally?.ownerId != 0) return;
    if (unlocked != null) {
      achievements.add(
        account == null
            ? LiteRun.heroUnlockKey(unlocked)
            : unlockKey(unlocked, account),
      );
    }
    if (pet != null)
      _discoverPet(pet, owner?.position ?? position, fighter: owner);
  }

  void _frontierCue(
    LiteFrontierEffect effect,
    int actor,
    Point<double> from,
    Point<double> to,
    double size,
  ) {
    if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
    _combatImpacts.add(
      LiteCombatImpact(
        LiteImpactTarget.frontierCast,
        actor,
        from,
        time,
        life: (effect.index + 1).toDouble(),
        shield: size,
        end: to,
      ),
    );
  }

  void _frontierHeroMove(
    LiteHero character,
    Point<double> from,
    Point<double> direction,
    LiteCoopFighter? fighter, {
    required bool powerful,
  }) {
    final owner = fighter?.id;
    final rank = LiteRun.openGradeFor(fighter?.level ?? level);
    final power = powerful ? LiteRun.openPower : 1.0;
    if (character == LiteHero.gablyn) {
      // The attack starts at the end of the projected dash, while travel
      // remains continuous and is bounded by the same collision geometry.
      final limit = powerful ? 4.3 : 2.1;
      final arrived = _playableShadowStep(
        from,
        direction,
        fighter,
        distance: limit,
        protection: powerful ? .36 : .20,
      );
      _melee(
        arrived,
        direction,
        LiteWeapon.beccoCaverna,
        (powerful ? 15 + rank * 4.0 : 14 + rank * 3.0) * power,
        reach: powerful ? 4.5 : 2.45,
        minDot: powerful ? .29 : .63,
        push: powerful ? 2.5 : .65,
        sourceCloneId: owner,
        ownerCanHeal: owner == null,
      );
      _frontierCue(
        powerful ? LiteFrontierEffect.shaleFan : LiteFrontierEffect.caveCut,
        owner ?? 0,
        arrived,
        arrived + direction * (powerful ? 4.5 : 2.45),
        1,
      );
      return;
    }
    final center = _frontierGround(from, direction, powerful ? 4.8 : 3.3);
    final radius = powerful ? 4.8 + rank * .25 : 2.4;
    _frontierShroud(
      center,
      from,
      direction,
      owner,
      radius,
      (powerful ? 13 + rank * 4.0 : 9 + rank * 2.0) * power,
      powerful ? 2.8 : 1.55,
      powerful ? 2.9 : 1.15,
    );
  }

  Point<double> _frontierGround(
    Point<double> from,
    Point<double> direction,
    double reach,
  ) {
    var center = from;
    for (var left = reach; left > 0; left -= .22) {
      final next = center + direction * min(left, .22);
      if (_blocked(next, .07)) break;
      center = next;
    }
    return center;
  }

  void _frontierShroud(
    Point<double> center,
    Point<double> from,
    Point<double> direction,
    int? owner,
    double radius,
    double damage,
    double bind,
    double pull,
  ) {
    _frontierCue(
      LiteFrontierEffect.shroud,
      owner ?? 0,
      center,
      center + direction,
      radius,
    );
    for (final enemy in _attackableCreatures) {
      final hitAt = enemy.closestHitboxPoint(center);
      if (enemy.hp <= 0 ||
          _enemyIntangible(enemy) ||
          hitAt.distanceTo(center) > radius ||
          _lineBlocked(center, hitAt) ||
          _lineBlocked(from, enemy.closestHitboxPoint(from)))
        continue;
      _hitEnemy(
        enemy,
        damage,
        ownerCanHeal: owner == null,
        sourceCloneId: owner,
        impactFrom: center,
      );
      if (enemy.hp <= 0) continue;
      final reduced = enemy.kind.boss || enemy.kind.elite;
      enemy.shockRemaining = max(
        enemy.shockRemaining,
        bind * (reduced ? .42 : 1),
      );
      // Sweep in small pieces so the shroud cannot pull a creature through cover.
      final old = enemy.position;
      final toward = LiteRun._unit(center - old);
      final amount = min(old.distanceTo(center), pull * (reduced ? .24 : 1));
      var at = old;
      for (var left = amount; left > 0; left -= .18) {
        final next = _move(at, toward * min(left, .18), enemy.radius);
        if (next == at) break;
        at = next;
      }
      enemy.position = at;
    }
  }

  void _castFrontierWeapon(
    LiteWeapon item,
    Point<double> origin,
    Point<double> direction,
    int? owner,
    double damage,
    double scale,
  ) {
    if (item == LiteWeapon.beccoCaverna) {
      final reach = 4.9 * scale;
      _melee(
        origin,
        direction,
        item,
        damage * 1.18,
        reach: reach,
        minDot: .82,
        push: 1.8 * scale,
        sourceCloneId: owner,
        ownerCanHeal: owner == null,
      );
      _frontierCue(
        LiteFrontierEffect.caveCut,
        owner ?? 0,
        origin,
        origin + direction * reach,
        scale,
      );
      return;
    }
    if (item == LiteWeapon.falceFunerys) {
      final center = _frontierGround(origin, direction, 2.8 * scale);
      _frontierShroud(
        center,
        origin,
        direction,
        owner,
        2.8 * scale,
        damage * .90,
        1.1 * scale,
        2.4 * scale,
      );
      return;
    }
    _frontierArc(
      origin,
      direction,
      owner,
      damage,
      scale,
      firstRange: 9 * scale,
      links: 3,
      effect: LiteFrontierEffect.coil,
    );
  }

  void _frontierArc(
    Point<double> origin,
    Point<double> direction,
    int? owner,
    double damage,
    double scale, {
    required double firstRange,
    required int links,
    required LiteFrontierEffect effect,
  }) {
    final struck = <int>{};
    var from = origin;
    for (var link = 0; link < links; link++) {
      final reach = link == 0 ? firstRange : 3.5 * scale;
      LiteEnemy? chosen;
      var shortest = reach;
      for (final enemy in enemies) {
        if (enemy.hp <= 0 ||
            struck.contains(enemy.id) ||
            _enemyIntangible(enemy))
          continue;
        final to = enemy.closestHitboxPoint(from);
        final delta = to - from;
        final distance = delta.magnitude;
        if (distance > shortest ||
            _lineBlocked(from, to) ||
            (link == 0 &&
                distance > .05 &&
                LiteRun._unit(delta).x * direction.x +
                        LiteRun._unit(delta).y * direction.y <
                    .82))
          continue;
        shortest = distance;
        chosen = enemy;
      }
      if (chosen == null) {
        if (link == 0) {
          _frontierCue(
            effect,
            owner ?? 0,
            from,
            _frontierGround(from, direction, firstRange),
            scale,
          );
        }
        break;
      }
      final target = chosen.closestHitboxPoint(from);
      _frontierCue(effect, owner ?? 0, from, target, scale);
      _hitEnemy(
        chosen,
        damage * pow(.74, link),
        ownerCanHeal: owner == null,
        sourceCloneId: owner,
        impactFrom: from,
      );
      if (chosen.hp > 0) {
        chosen.shockRemaining = max(chosen.shockRemaining, .40 * scale);
      }
      struck.add(chosen.id);
      from = target;
    }
  }

  void _frontierPetWard(LiteClone pet, LiteCoopFighter? owner) {
    if (pet.companion != LiteCompanion.frammentoLapysrieth ||
        pet._burrowCooldown > 0 ||
        (owner?.hp ?? hp) <= 0 ||
        (owner?.shield ?? shield) >= 4)
      return;
    final at = owner?.position ?? position;
    if (at.distanceTo(pet.position) > 3.7 ||
        _lineBlocked(pet.position, at) ||
        !enemies.any(
          (enemy) =>
              enemy.hp > 0 &&
              enemy.position.distanceTo(at) <= 7 &&
              !_lineBlocked(at, enemy.position),
        ))
      return;
    final amount = 6.0 + min(7, pet.level - 1);
    if (owner == null) {
      shield += amount;
    } else {
      owner.shield += amount;
    }
    pet._burrowCooldown = 7.2;
    _frontierCue(
      LiteFrontierEffect.fragment,
      pet.id,
      pet.position,
      at,
      amount / 8,
    );
  }

  bool _frontierPetStrike(
    LiteClone pet,
    Point<double> direction,
    double training,
  ) {
    if (pet.companion != LiteCompanion.saldino) return false;
    pet
      ..cooldown = 1.5
      .._poseAim = direction
      .._swing = .24;
    _frontierArc(
      pet.position,
      direction,
      pet.id,
      LiteCompanion.saldino.damage * pet.damageScale * (1 + training),
      1,
      firstRange: 8,
      links: 2,
      effect: LiteFrontierEffect.solder,
    );
    return true;
  }
}
