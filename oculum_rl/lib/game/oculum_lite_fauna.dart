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
    _ensureChickenFlock();
  }

  static String _mechanicalChickenGuestKey(String account) =>
      'pollo-meccanico-ospite-$account';

  bool get _hasChickenTrialParticipant =>
      allowMechanicalChicken ||
      coopFighters.any((fighter) => fighter.allowMechanicalChicken);

  void _ensureChickenFlock() {
    if (!_hasChickenTrialParticipant ||
        _provokedRooms.isNotEmpty ||
        restHub ||
        goblinCamp ||
        inActTwo ||
        inSolarDungeon) {
      return;
    }
    final chickens = fauna
        .where((animal) => animal.kind == LiteEnemyKind.pollo)
        .toList();
    if (chickens.length != 1) return;
    final first = chickens.single;
    final center = first.position;
    const edges = [Point<double>(-1.15, .92), Point<double>(1.15, .92)];
    for (var i = 0; i < edges.length; i++) {
      fauna.add(
        LiteEnemy(
          21000 + stage * 2 + i,
          first.kind,
          _safePoint(center + edges[i], first.kind.radius, center),
          first.kind.health.toDouble(),
        ),
      );
    }
  }

  void _tickMechanicalChickenTrial(double seconds, Point<double> movement) {
    if (!_hasChickenTrialParticipant ||
        _provokedRooms.isNotEmpty ||
        restHub ||
        goblinCamp ||
        inSolarDungeon ||
        inActTwo) {
      _chickenTrial.clear();
      return;
    }
    final chickens = fauna
        .where((animal) => animal.kind == LiteEnemyKind.pollo && animal.hp > 0)
        .toList();
    if (chickens.length < 3) {
      _chickenTrial.clear();
      return;
    }
    final center =
        chickens.fold(
          const Point<double>(0, 0),
          (sum, animal) => sum + animal.position,
        ) *
        (1 / chickens.length);
    void count(int id, Point<double> at, bool still, String unlock) {
      if (achievements.contains(unlock)) return;
      if (!still ||
          LiteRun._distance(at, center) > 1.4 ||
          chickens
                  .where(
                    (animal) => LiteRun._distance(at, animal.position) <= 3,
                  )
                  .length <
              3) {
        _chickenTrial.remove(id);
        return;
      }
      final elapsed = (_chickenTrial[id] ?? 0) + seconds;
      if (elapsed >= 10 - 1e-8) {
        achievements.add(unlock);
        _chickenTrial.remove(id);
        message = 'Circuito del pollaio · Pollo Meccanico giocabile.';
      } else {
        _chickenTrial[id] = elapsed;
      }
    }

    if (allowMechanicalChicken) {
      count(
        0,
        position,
        movement.magnitude == 0 &&
            !hostDown &&
            !clashDashing &&
            _burstTime <= 0,
        LiteRun.heroUnlockKey(LiteHero.polloMeccanico),
      );
    }
    for (final fighter in coopFighters) {
      if (fighter.allowMechanicalChicken &&
          fighter.connected &&
          fighter.hp > 0) {
        count(
          fighter.id,
          fighter.position,
          fighter.stride.speed <= .05 && fighter._dashRemaining <= 0,
          _mechanicalChickenGuestKey(fighter.account),
        );
      } else {
        _chickenTrial.remove(fighter.id);
      }
    }
  }

  static const _spawnForFauna = Point<double>(8, 11);

  void _tickFauna(double elapsed) {
    if (restHub || goblinCamp) return;
    _ensureChickenFlock();
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
        if (_hasChickenTrialParticipant &&
            animal.kind == LiteEnemyKind.pollo &&
            (stageClear || _chickenTrial.isNotEmpty) &&
            _provokedRooms.isEmpty) {
          animal.stride._track(previous, animal.position, elapsed);
          continue;
        }
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
    if (animal == LiteHero.polloMeccanico) {
      final forward = LiteRun._unit(direction);
      final side = Point(-forward.y, forward.x);
      for (var index = -1; index <= 1; index++) {
        final at = origin + forward * .36 + side * (.23 * index);
        projectiles.add(
          LiteProjectile(
            position: _blocked(at, .1) ? origin : at,
            direction: _rotate(forward, index * .16),
            speed: 18,
            remaining: 11.5,
            damage: 7 + level * .75,
            magic: true,
            kind: LiteProjectileKind.posteaRay,
            ownerCanHeal: owner == null,
            sourceCloneId: owner,
          ),
        );
      }
      return true;
    }
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

  bool _ownsPosteaEgg(LiteProjectile ray, LiteProjectile egg) =>
      egg.kind == LiteProjectileKind.posteaEgg &&
      egg.eggFuse != null &&
      egg.remaining > 0 &&
      ray.sourceCloneId == egg.sourceCloneId;

  void _steerPosteaRay(LiteProjectile shot, double elapsed) {
    Point<double>? target;
    var best = 100.0;
    for (final egg in projectiles) {
      if (!_ownsPosteaEgg(shot, egg)) continue;
      final offset = egg.position - shot.position;
      final direction = LiteRun._unit(offset);
      final aim = shot.direction;
      if (offset.magnitude > 10 ||
          aim.x * direction.x + aim.y * direction.y < .93 ||
          _lineBlocked(shot.position, egg.position)) {
        continue;
      }
      final distance = offset.magnitude * offset.magnitude;
      if (distance < best) {
        best = distance;
        target = egg.position;
      }
    }
    if (target == null) {
      for (final enemy in enemies) {
        if (enemy.hp <= 0 || _enemyIntangible(enemy)) continue;
        final distance = LiteRun._distanceSquared(
          shot.position,
          enemy.position,
        );
        if (distance >= best || _lineBlocked(shot.position, enemy.position))
          continue;
        best = distance;
        target = enemy.position;
      }
    }
    if (target == null) return;
    final desired = LiteRun._unit(target - shot.position);
    // Turn at a limited angle, keeping the three trajectories readable.
    final direction = shot.direction;
    final angle = atan2(
      direction.x * desired.y - direction.y * desired.x,
      direction.x * desired.x + direction.y * desired.y,
    );
    final limit = 5.4 * elapsed;
    shot.direction = _rotate(direction, angle.clamp(-limit, limit));
  }

  bool _ignitePosteaEgg(LiteProjectile ray, Point<double> at) {
    for (final egg in projectiles) {
      if (_ownsPosteaEgg(ray, egg) &&
          LiteRun._distanceSquared(at, egg.position) <= .34 * .34) {
        _explodeEgg(egg);
        return true;
      }
    }
    return false;
  }

  void _throwEggs(
    Point<double> origin,
    Point<double> direction,
    int? owner, {
    required double damage,
    required double spread,
    bool mechanical = false,
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
          speed: mechanical ? 14 : 12,
          remaining: mechanical ? 6.8 : 4.2,
          damage: damage,
          kind: mechanical
              ? LiteProjectileKind.posteaEgg
              : LiteProjectileKind.egg,
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
      shot.kind == LiteProjectileKind.posteaEgg ? 2.25 : 1.65,
      shot.damage,
      shot.sourceCloneId ?? 0,
      push: .48,
    );
    _recordImpact(LiteImpactTarget.explosion, _nextId++, shot.position);
    shot.remaining = 0;
  }
}
