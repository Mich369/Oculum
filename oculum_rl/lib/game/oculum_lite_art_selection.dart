part of 'oculum_lite_run.dart';

enum LiteLearnedArt {
  plasma('Raggio al plasma', 'Oculum Art', 3, 3.6),
  falci('Falci di Vaitern', 'Oculum Art', 2, 2.9),
  linfa('Linfa verde', 'Oculum Art', 3, 7),
  pattuglia('Affondo della pattuglia', 'Martial Art', 0, 2.3),
  lame('Affondo delle lame lunari', 'Martial Art', 0, 2.8),
  corruzione('Presa della Corruzione Rossa', 'Defiled Art', 4, 8),
  brace('Incisione di brace', 'Oculum Art', 3, 3.2),
  basalto('Piega di basalto', 'Oculum Art', 4, 4.4);

  const LiteLearnedArt(this.label, this.family, this.cost, this.cooldown);
  final String label, family;
  final double cost, cooldown;

  static LiteLearnedArt? fixedFor(LiteHero hero) => switch (hero) {
    LiteHero.guardiaSolare || LiteHero.eliteSolare => pattuglia,
    LiteHero.cavaliereLunare => lame,
    _ => null,
  };

  int get maxRank => this == corruzione ? 5 : 3;
  int rankAt(int level) => (1 + (level - 1) ~/ 3).clamp(1, maxRank);
  int levelForRank(int rank) => 1 + (rank - 1) * 3;

  String formEffect(int rank) => switch (this) {
    plasma =>
      'Raggio da ${17 + rank * 7} Danni, portata ${_metric(11 + .8 * rank)} m.',
    falci => 'Due falci da ${10 + 4 * rank} Danni ciascuna, fino a 10 m.',
    linfa =>
      'Cura il ${_metric(11 + 4.5 * rank)}% della Vita massima e ripristina Resistenza al blocco.',
    pattuglia || lame =>
      'Affondo da ${12 + rank * 4} Danni, portata ${_metric(2.9 + rank * .42)} m.',
    corruzione =>
      'Onda da ${9 + rank * 5} Danni entro ${_metric(3.3 + rank * .25)} m. Stordisce i nemici comuni per ${_metric(.25 + rank * .23)} s.',
    brace =>
      '${rank + 1} braci da ${8 + 3 * rank} Danni ciascuna, fino a ${rank + 1} rimbalzi ciascuna.',
    basalto =>
      'Faglia da ${18 + 6 * rank} Danni, lunga ${_metric(5.6 + .9 * rank)} m. Può spezzare i ripari.',
  };

  static String _metric(double value) => value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'\.?0+$'), '')
      .replaceAll('.', ',');
}

extension LiteArtExecution on LiteRun {
  bool get artDealerOpen => restHub && stage >= 11;
  LiteLearnedArt? activeArt([LiteCoopFighter? fighter]) =>
      LiteLearnedArt.fixedFor(fighter?.hero ?? hero) ??
      (fighter?.supply ?? supply).art;

  LiteLearnedArt? extraArt([LiteCoopFighter? fighter]) {
    final kit = fighter?.supply ?? supply;
    return kit.hasGrimoire &&
            LiteLearnedArt.fixedFor(fighter?.hero ?? hero) != null
        ? kit.art
        : null;
  }

  bool useLearnedArt(
    Point<double> target, [
    LiteCoopFighter? fighter,
    bool extra = false,
  ]) {
    final art = extra ? extraArt(fighter) : activeArt(fighter);
    final kit = fighter?.supply ?? supply;
    if (art == null ||
        (extra ? kit.extraArtCooldown : kit.artCooldown) > 0 ||
        finished ||
        restHub ||
        shopOpen ||
        gripRemaining(fighter) > 0 ||
        (fighter?.hp ?? hp) <= 0 ||
        (fighter?.blocking ?? blocking) ||
        (fighter?._night ?? _night).stun > 0 ||
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
      case LiteLearnedArt.brace:
        _castInkBrace(at, direction, rank, owner: owner);
      case LiteLearnedArt.basalto:
        _fissure(at, direction, 5.6 + .9 * rank, 18 + 6.0 * rank, owner);
    }
    _markArtCast(art, at, direction, rank, casterId: owner ?? 0);
    if (extra) {
      kit.extraArtCooldown = art.cooldown;
    } else {
      kit.artCooldown = art.cooldown;
    }
    if (fighter == null) {
      oculum -= art.cost;
    } else {
      fighter.oculum -= art.cost;
    }
    message = '${art.label} · ${art.family} · Forma $rank';
    return true;
  }

  void _castInkBrace(
    Point<double> at,
    Point<double> direction,
    int rank, {
    int? owner,
    bool hostile = false,
    double damageScale = 1,
  }) {
    final heading = atan2(direction.y, direction.x);
    for (var ray = 0; ray <= rank; ray++) {
      final angle = heading + (ray - rank / 2) * .27;
      projectiles.add(
        LiteProjectile(
          position: at,
          direction: Point(cos(angle), sin(angle)),
          speed: 17,
          remaining: 14,
          damage: (8 + 3 * rank) * damageScale,
          magic: true,
          kind: LiteProjectileKind.inkEmber,
          bounces: rank + 1,
          fromEnemy: hostile,
          ownerCanHeal: owner == null && !hostile,
          sourceCloneId: owner,
        ),
      );
    }
  }

  void _markArtCast(
    LiteLearnedArt art,
    Point<double> at,
    Point<double> direction,
    int rank, {
    required int casterId,
  }) {
    if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
    _combatImpacts.add(
      LiteCombatImpact(
        LiteImpactTarget.artCast,
        casterId,
        at,
        time,
        life: art.index.toDouble(),
        shield: rank.toDouble(),
        end: at + direction,
      ),
    );
  }
}
