part of 'oculum_lite_run.dart';

enum LiteRelicFamily {
  orbita,
  terramaul,
  segugio,
  canna,
  spadaLusier,
  mazzaGuardiano,
}

typedef LiteMilestoneReward = ({
  int floors,
  LiteDifficulty difficulty,
  LiteHero? hero,
  LiteWeapon? weapon,
});

const liteMilestoneHeirs = [
  LiteHero.ragnoSaldatore,
  LiteHero.rasvyr,
  LiteHero.lupoDiVaitern,
  LiteHero.pysciwarden,
  LiteHero.lusierTre,
];

const _liteMilestoneArms = [
  [
    LiteWeapon.orbita1,
    LiteWeapon.orbita2,
    LiteWeapon.orbita3,
    LiteWeapon.orbita4,
    LiteWeapon.orbita5,
  ],
  [
    LiteWeapon.terramaul1,
    LiteWeapon.terramaul2,
    LiteWeapon.terramaul3,
    LiteWeapon.terramaul4,
    LiteWeapon.terramaul5,
  ],
  [
    LiteWeapon.segugio1,
    LiteWeapon.segugio2,
    LiteWeapon.segugio3,
    LiteWeapon.segugio4,
    LiteWeapon.segugio5,
  ],
  [
    LiteWeapon.canna1,
    LiteWeapon.canna2,
    LiteWeapon.canna3,
    LiteWeapon.canna4,
    LiteWeapon.canna5,
  ],
  [
    LiteWeapon.spadaLusier1,
    LiteWeapon.spadaLusier2,
    LiteWeapon.spadaLusier3,
    LiteWeapon.spadaLusier4,
    LiteWeapon.spadaLusier5,
  ],
  [
    LiteWeapon.mazzaGuardiano1,
    LiteWeapon.mazzaGuardiano2,
    LiteWeapon.mazzaGuardiano3,
    LiteWeapon.mazzaGuardiano4,
    LiteWeapon.mazzaGuardiano5,
  ],
];

final liteMilestoneRewards = List<LiteMilestoneReward>.unmodifiable([
  for (final difficulty in LiteDifficulty.values)
    (
      floors: 5,
      difficulty: difficulty,
      hero: liteMilestoneHeirs[difficulty.index],
      weapon: null,
    ),
  for (final (index, weapons) in _liteMilestoneArms.indexed)
    for (final difficulty in LiteDifficulty.values)
      (
        floors: 10 + index * 5,
        difficulty: difficulty,
        hero: null,
        weapon: weapons[difficulty.index],
      ),
]);

extension LiteMilestoneRun on LiteRun {
  // Ristori and side rooms retain the already cleared main floor.
  int get milestoneFloors {
    if (_desertEye case final eye?) {
      return stage + (eye.origin['stageClear'] == true ? 1 : 0);
    }
    if (inThirdAct) {
      return LiteRun.finalStage +
          thirdRoom +
          (stageClear || victorious ? 1 : 0);
    }
    return stage + (stageClear || victorious || usesSubArena ? 1 : 0);
  }
}

void _milestoneWave(
  LiteRun run,
  Point<double> from,
  Point<double> direction,
  double power,
  int? owner, {
  required LiteProjectileKind kind,
  required double range,
  double speed = 20,
  bool returns = false,
  bool hostile = false,
}) {
  run.projectiles.add(
    LiteProjectile(
      position: from,
      direction: direction,
      speed: speed,
      remaining: range,
      damage: power,
      magic: kind != LiteProjectileKind.chakram,
      kind: kind,
      boomerang: returns,
      fromEnemy: hostile,
      ownerCanHeal: owner == null && !hostile,
      sourceCloneId: owner,
    ),
  );
}

extension _LiteMilestoneCombat on LiteRun {
  void _milestoneEffect(
    int id,
    Point<double> from,
    Point<double> direction,
    double cue,
    double form,
  ) {
    if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
    _combatImpacts.add(
      LiteCombatImpact(
        LiteImpactTarget.milestoneCast,
        id,
        from,
        time,
        life: cue,
        shield: form,
        end: from + direction,
      ),
    );
  }

  void _milestoneHeroMove(
    LiteHero character,
    Point<double> from,
    Point<double> direction,
    LiteCoopFighter? fighter, {
    required bool powerful,
  }) {
    final owner = fighter?.id;
    final rank = LiteRun.openGradeFor(fighter?.level ?? level);
    final power = powerful ? LiteRun.openPower : 1.0;
    final damage = ((powerful ? 19 : 11) + rank * 4) * power;
    final context = switch (character) {
      LiteHero.ragnoSaldatore => LiteRelicFamily.segugio,
      LiteHero.rasvyr => LiteRelicFamily.terramaul,
      LiteHero.lupoDiVaitern => LiteRelicFamily.orbita,
      LiteHero.pysciwarden => LiteRelicFamily.canna,
      LiteHero.lusierTre => LiteRelicFamily.spadaLusier,
      _ => throw ArgumentError.value(character),
    };
    switch (character) {
      case LiteHero.ragnoSaldatore:
        _milestoneWave(
          this,
          from,
          direction,
          damage * 1.4,
          owner,
          kind: LiteProjectileKind.plasma,
          range: powerful ? 13 : 8,
          speed: 37,
        );
      case LiteHero.rasvyr:
        _openBurst(
          from,
          powerful ? 4.1 : 2.65,
          damage,
          owner ?? 0,
          push: powerful ? 2.9 : .57,
        );
      case LiteHero.lupoDiVaitern:
        if (powerful) {
          _lunarVolley(from, direction, damage, owner: owner);
        } else {
          final arrived = _playableShadowStep(
            from,
            direction,
            fighter,
            distance: 2.25,
            protection: .18,
          );
          _melee(
            arrived,
            direction,
            LiteWeapon.guanti,
            damage,
            reach: 2.35,
            ownerCanHeal: owner == null,
            sourceCloneId: owner,
          );
        }
      case LiteHero.pysciwarden:
        if (powerful) {
          for (final side in [-.22, 0.0, .22]) {
            _milestoneWave(
              this,
              from,
              _rotate(direction, side),
              damage * .66,
              owner,
              kind: LiteProjectileKind.frostBolt,
              range: 8,
            );
          }
        } else {
          _melee(
            from,
            direction,
            LiteWeapon.piccaOssidiana,
            damage,
            reach: 4.1,
            minDot: .84,
            ownerCanHeal: owner == null,
            sourceCloneId: owner,
          );
        }
      case LiteHero.lusierTre:
        if (powerful) {
          if (fighter == null) {
            shield += (12 + 3 * rank) * power;
          } else {
            fighter.shield += (12 + 3 * rank) * power;
          }
          _openBurst(from, 3.35, damage, owner ?? 0, push: 1.4);
        } else {
          _milestoneWave(
            this,
            from,
            direction,
            damage,
            owner,
            kind: LiteProjectileKind.inkEmber,
            range: 7,
          );
        }
      default:
        return;
    }
    _milestoneEffect(
      owner ?? 0,
      from,
      direction,
      context.index.toDouble(),
      (powerful ? 5 : 2).toDouble(),
    );
  }

  void _castMilestoneWeapon(
    LiteWeapon item,
    Point<double> from,
    Point<double> facing,
    double damage,
    double effectScale,
    LiteCoopFighter? fighter,
  ) {
    final family = item.relicFamily!;
    final form = item.form;
    final level = form - 1;
    final owner = fighter?.id;

    void hit(double range, double arc, {double push = 0, double scale = 1}) {
      _melee(
        from,
        facing,
        item,
        damage * scale,
        reach: range * effectScale,
        minDot: arc,
        push: push,
        ownerCanHeal: owner == null,
        sourceCloneId: owner,
      );
    }

    void protect(double ward) {
      if (fighter == null) {
        shield = max(shield, ward);
      } else {
        fighter.shield = max(fighter.shield, ward);
      }
    }

    switch (family) {
      case LiteRelicFamily.orbita:
        protect(3.0 + level * 2);
        for (var i = 0; i < (form >= 4 ? 3 : 2); i++) {
          _milestoneWave(
            this,
            from,
            _rotate(facing, (i - .5) * (.18 + level * .032)),
            damage * (.60 + level * .045),
            owner,
            kind: form.isOdd
                ? LiteProjectileKind.frostBolt
                : LiteProjectileKind.chakram,
            range: 7.5 + level * .65,
            returns: true,
          );
        }
      case LiteRelicFamily.terramaul:
        _openBurst(
          from,
          (2.35 + level * .32) * effectScale,
          damage * (1 + level * .07),
          owner ?? 0,
          push: 1.5 + level * .55,
          shock: level * .13,
        );
      case LiteRelicFamily.segugio:
        final count = form >= 3 ? 2 : 1;
        for (var i = 0; i < count; i++) {
          _milestoneWave(
            this,
            from,
            _rotate(facing, (i - (count - 1) * .5) * (.12 + level * .035)),
            damage * (1.03 - .18 * (count - 1) + level * .045),
            owner,
            kind: LiteProjectileKind.plasma,
            range: 8.8 + level * .65,
            speed: 24 + level * 2.0,
            returns: form >= 2,
          );
        }
      case LiteRelicFamily.canna:
        hit(4.4 + level * .35, .86 - level * .067, push: level * .31);
        if (form >= 2) {
          _milestoneWave(
            this,
            from + facing * 2.1,
            facing,
            damage * (.33 + level * .048),
            owner,
            kind: LiteProjectileKind.frostBolt,
            range: 4.2 + level * .65,
          );
        }
      case LiteRelicFamily.spadaLusier:
        protect(6.5 + level * 2.3);
        hit(2.9 + level * .34, .46 - level * .13, push: level * .70);
        if (form >= 3) {
          _milestoneWave(
            this,
            from,
            facing,
            damage * (.25 + level * .065),
            owner,
            kind: LiteProjectileKind.inkEmber,
            range: 5.5 + level * .42,
          );
        }
      case LiteRelicFamily.mazzaGuardiano:
        protect(8 + level * 3.0);
        _openBurst(
          from + facing * (1.0 + level * .29),
          (2.0 + level * .25) * effectScale,
          damage * (1.12 + level * .10),
          owner ?? 0,
          push: 1.85 + level * .48,
          shock: .13 * form,
        );
    }
    _milestoneEffect(
      owner ?? 0,
      from,
      facing,
      family.index.toDouble(),
      form.toDouble(),
    );
  }
}
