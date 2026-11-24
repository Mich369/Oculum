part of 'oculum_lite_run.dart';

enum LiteAnimal {
  pollo(LiteHero.pollo, LiteEnemyKind.pollo),
  raganella(LiteHero.raganella, LiteEnemyKind.raganella),
  pipistrello(LiteHero.pipistrello, LiteEnemyKind.pipistrello);

  const LiteAnimal(this.hero, this.creature);
  final LiteHero hero;
  final LiteEnemyKind creature;

  static LiteAnimal? forHero(LiteHero hero) =>
      values.where((animal) => animal.hero == hero).firstOrNull;
  static LiteAnimal? forCreature(LiteEnemyKind kind) =>
      values.where((animal) => animal.creature == kind).firstOrNull;
}

extension LiteFauna on LiteRun {
  bool get faunaAggressive =>
      _provokedRooms.length - (_provokedRooms.contains(stage) ? 1 : 0) >= 6;
  int get provokedFaunaRooms => _provokedRooms.length;
  int get sparedFaunaRooms => _sparedRooms.length;
  Iterable<LiteEnemy> get _attackableCreatures => enemies.followedBy(fauna);

  void _populateFauna() {
    final habitat = switch (biome) {
      LiteBiome.campo || LiteBiome.deserto => LiteAnimal.pollo,
      LiteBiome.foresta || LiteBiome.orea => LiteAnimal.raganella,
      LiteBiome.dungeon || LiteBiome.postea => LiteAnimal.pipistrello,
    };
    final species = <LiteAnimal>{habitat};
    if (stage % 3 == 0) species.add(LiteAnimal.pollo);
    final rng = _LiteRandom(seed ^ (stage + 1) * 7889);
    var lane = 0;
    for (final animal in species) {
      final candidate = Point(
        11.5 + rng.nextDouble() * 8,
        lane++ == 0 ? 4.5 : 17.5,
      );
      final point = _safePoint(
        candidate,
        animal.creature.radius,
        _spawnForFauna,
      );
      fauna.add(
        LiteEnemy(
          20000 + stage * 4 + animal.index,
          animal.creature,
          point,
          animal.creature.health.toDouble(),
        ),
      );
    }
  }

  static const _spawnForFauna = Point<double>(8, 11);

  void _tickFauna(double elapsed) {
    if (restHub || goblinCamp) return;
    for (final animal in fauna) {
      if (animal.hp <= 0) continue;
      final previous = animal.position;
      animal._strikePose = max(0, animal._strikePose - elapsed);
      if (faunaAggressive) {
        final winding = animal.attacking;
        _enemyTick(animal, elapsed);
        if (winding && !animal.attacking) animal._strikePose = .24;
      } else {
        animal.hitFlash = max(0, animal.hitFlash - elapsed);
        final source = animal.shockSource;
        final phase = time * .58 + animal.id * 1.47;
        final direction = source == null
            ? Point(cos(phase), sin(phase))
            : LiteRun._unit(animal.position - source);
        if (source != null || sin(phase * 1.6) > .1) {
          animal.position = _move(
            animal.position,
            direction * (elapsed * (source == null ? .82 : animal.kind.speed)),
            animal.radius,
          );
        }
      }
      animal.stride._track(previous, animal.position, elapsed);
    }
    fauna.removeWhere((animal) => animal.hp <= 0);
  }

  void _noteFaunaHit(LiteEnemy creature, Point<double> from) {
    creature.shockSource = from;
    creature.shockRemaining = 1;
    if (_provokedRooms.add(stage) && _provokedRooms.length == 6) {
      achievements.add('fauna-in-allarme');
      message = 'La fauna ha imparato a temerti. Dalla prossima stanza ti attacca a vista.';
    }
  }

  void _noteFaunaCleared() {
    if (fauna.isEmpty || _provokedRooms.contains(stage) || goblinCamp) return;
    if (!_sparedRooms.add(stage)) return;
    _progressOptionalQuest('fauna');
    for (final animal in fauna) {
      final species = LiteAnimal.forCreature(animal.kind);
      if (species != null)
        achievements.add('fauna-risparmiata-${species.name}');
    }
    if (_sparedRooms.length >= 3) {
      _unlockAnimal(LiteAnimal.pollo, 'Amico di penna');
    }
    if (_sparedRooms.length >= 4 &&
        achievements.contains('fauna-risparmiata-raganella')) {
      _unlockAnimal(LiteAnimal.raganella, 'Sovrana dello stagno');
    }
    if (_sparedRooms.length >= 5 &&
        achievements.contains('fauna-risparmiata-pipistrello')) {
      _unlockAnimal(LiteAnimal.pipistrello, 'Ospite del tramonto');
    }
  }

  void _unlockAnimal(LiteAnimal animal, String title) {
    if (achievements.add(LiteRun.heroUnlockKey(animal.hero))) {
      achievements.add('fauna-premio-${animal.name}');
      message = '$title · ${animal.creature.label} giocabile.';
    }
  }

  bool _tryAnimalRebirth([LiteCoopFighter? fighter]) {
    final former = fighter?.hero ?? hero;
    if (LiteAnimal.forHero(former) == null || _rng.nextInt(100) >= 12) {
      return false;
    }
    final fraction = difficulty.index >= LiteDifficulty.difficile.index
        ? .30
        : .65;
    achievements.add(LiteRun.heroUnlockKey(LiteHero.doppelganger));
    if (fighter == null) {
      hero = LiteHero.doppelganger;
      weapon = LiteWeapon.guanti;
      hp = maxHp * fraction;
      _invulnerability = 1.9;
      _windup = _burstTime = 0;
      _block.held = false;
      endRescue();
    } else {
      fighter
        ..hero = LiteHero.doppelganger
        ..weapon = LiteWeapon.guanti
        ..hp = fighter.maxHp * fraction
        .._protection = 1.9
        .._windup = 0
        .._dashRemaining = 0;
      fighter._block.held = false;
      endRescue(fighter);
    }
    message =
        'Muta del Doppelganger · ritorni con il ${(fraction * 100).round()}% della Vita.';
    return true;
  }

  bool _animalStrike(
    LiteHero animal,
    Point<double> origin,
    Point<double> direction,
    int level,
    int? owner,
  ) {
    if (LiteAnimal.forHero(animal) == null) return false;
    _melee(
      origin,
      direction,
      LiteWeapon.guanti,
      (animal == LiteHero.pollo ? 11.0 : 9.0) + level,
      ownerCanHeal: owner == null,
      sourceCloneId: owner,
      reach: animal == LiteHero.raganella ? 3.1 : 1.85,
      minDot: .42,
    );
    return true;
  }

  void _throwEggs(
    Point<double> origin,
    Point<double> direction,
    int? owner, {
    required double damage,
    required double spread,
  }) {
    final heading = LiteRun._unit(direction);
    final away = heading * -1.0;
    final side = Point(-heading.y, heading.x);
    for (var i = -1; i <= 1; i++) {
      final at = origin + away * .42 + side * (.13 * i);
      projectiles.add(
        LiteProjectile(
          position: _blocked(at, .1) ? origin : at,
          direction: _rotate(away, spread * i),
          speed: 12,
          remaining: 4.2,
          damage: damage,
          kind: LiteProjectileKind.egg,
          ownerCanHeal: owner == null,
          sourceCloneId: owner,
        ),
      );
    }
  }

  void _tickEgg(LiteProjectile shot, double elapsed) {
    if (shot.eggFuse case final end?) {
      shot.eggFuse = end - elapsed;
      if (shot.eggFuse! <= 1e-9) _explodeEgg(shot);
      return;
    }
    final distance = min(shot.remaining, shot.speed * elapsed);
    final next = shot.position + shot.direction * distance;
    if (_blocked(next, .14)) {
      shot.eggFuse = .9;
      return;
    }
    shot.position = next;
    if (_attackableCreatures.any(
      (enemy) =>
          enemy.hp > 0 &&
          LiteRun._distance(next, enemy.position) <= enemy.radius + .14,
    )) {
      _explodeEgg(shot);
      return;
    }
    shot.remaining -= distance;
    if (shot.remaining <= 1e-9) {
      shot.remaining = 1;
      shot.eggFuse = .9;
    }
  }

  void _explodeEgg(LiteProjectile shot) {
    _openBurst(
      shot.position,
      1.65,
      shot.damage,
      shot.sourceCloneId ?? 0,
      push: .48,
    );
    _recordImpact(LiteImpactTarget.explosion, _nextId++, shot.position);
    shot.remaining = 0;
  }
}
