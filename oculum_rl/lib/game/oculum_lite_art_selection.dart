part of 'oculum_lite_run.dart';

enum LiteLearnedArt {
  plasma('Raggio al plasma', 'Oculum Art', 3, 3.6),
  falci('Falci di Vaitern', 'Oculum Art', 2, 2.9),
  linfa('Linfa verde', 'Oculum Art', 3, 7),
  pattuglia('Affondo della pattuglia', 'Martial Art', 0, 2.3),
  lame('Affondo delle lame lunari', 'Martial Art', 0, 2.8),
  corruzione('Presa della Corruzione Rossa', 'Defiled Art', 4, 8);

  const LiteLearnedArt(this.label, this.family, this.cost, this.cooldown);
  final String label, family;
  final double cost, cooldown;

  static LiteLearnedArt? fixedFor(LiteHero hero) => switch (hero) {
    LiteHero.guardiaSolare || LiteHero.eliteSolare => pattuglia,
    LiteHero.cavaliereLunare => lame,
    _ => null,
  };

  int rankAt(int level) =>
      (1 + (level - 1) ~/ 3).clamp(1, this == corruzione ? 5 : 3);
}

extension LiteArtExecution on LiteRun {
  bool get artDealerOpen => restHub && stage >= 11;
  LiteLearnedArt? activeArt([LiteCoopFighter? fighter]) =>
      LiteLearnedArt.fixedFor(fighter?.hero ?? hero) ??
      (fighter?.supply ?? supply).art;

  bool useLearnedArt(Point<double> target, [LiteCoopFighter? fighter]) {
    final art = activeArt(fighter);
    final kit = fighter?.supply ?? supply;
    if (art == null ||
        kit.artCooldown > 0 ||
        finished ||
        restHub ||
        shopOpen ||
        gripRemaining(fighter) > 0 ||
        (fighter?.hp ?? hp) <= 0 ||
        (fighter?.blocking ?? blocking) ||
        !target.x.isFinite ||
        !target.y.isFinite ||
        (fighter?.oculum ?? oculum) < art.cost)
      return false;
    final at = fighter?.position ?? position;
    final heading = LiteRun._unit(target - at);
    final direction = heading.magnitude == 0 ? fighter?.aim ?? aim : heading;
    final rank = art.rankAt(fighter?.level ?? level);
    final owner = fighter?.id;
    switch (art) {
      case LiteLearnedArt.plasma:
        projectiles.add(
          LiteProjectile(
            position: at,
            direction: direction,
            speed: 40,
            remaining: 11 + .8 * rank,
            damage: 17 + rank * 7,
            magic: true,
            kind: LiteProjectileKind.plasma,
            sourceCloneId: owner,
            ownerCanHeal: owner == null,
          ),
        );
      case LiteLearnedArt.falci:
        _lunarVolley(at, direction, 10 + 4.0 * rank, owner: owner);
      case LiteLearnedArt.linfa:
        if ((fighter?.hp ?? hp) >= (fighter?.maxHp ?? maxHp)) return false;
        _healFighter((fighter?.maxHp ?? maxHp) * (.11 + .045 * rank), fighter);
        (fighter?._block ?? _block).recover(fighter?.weapon ?? weapon);
      case LiteLearnedArt.pattuglia || LiteLearnedArt.lame:
        final reach = 2.9 + rank * .42;
        _melee(
          at,
          direction,
          fighter?.weapon ?? weapon,
          12 + rank * 4,
          reach: reach,
          minDot: art == LiteLearnedArt.lame ? .11 : .68,
          sourceCloneId: owner,
          ownerCanHeal: owner == null,
        );
      case LiteLearnedArt.corruzione:
        if (!enemies.any(
          (enemy) =>
              enemy.hp > 0 &&
              enemy.position.distanceTo(at) <= 3.3 + rank * .25 &&
              !_lineBlocked(at, enemy.position),
        ))
          return false;
        _openBurst(
          at,
          3.3 + rank * .25,
          9.0 + rank * 5,
          owner ?? 0,
          push: .5 + rank * .22,
        );
        for (final enemy in enemies) {
          if (!enemy.kind.boss &&
              enemy.hp > 0 &&
              enemy.position.distanceTo(at) <= 3.5 + rank * .35 &&
              !_lineBlocked(at, enemy.position)) {
            enemy.stunned = max(enemy.stunned, .25 + rank * .23);
          }
        }
    }
    kit.artCooldown = art.cooldown;
    if (fighter == null) {
      oculum -= art.cost;
    } else {
      fighter.oculum -= art.cost;
    }
    message = '${art.label} · ${art.family} · Forma $rank';
    return true;
  }
}
