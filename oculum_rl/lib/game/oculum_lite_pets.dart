part of 'oculum_lite_run.dart';

extension LitePets on LiteRun {
  static List<LiteCompanion> starterOffers(
    Iterable<LiteCompanion> discovered,
    LiteBiome zone,
    int seed,
  ) {
    final rng = _LiteRandom(seed ^ (zone.index + 1) * 73417)
      ..nextDouble()
      ..nextDouble();
    final options =
        discovered.toSet().where((pet) => pet.discovery != null).toList()
          ..sort((a, b) => a.index.compareTo(b.index));
    for (var index = options.length - 1; index > 0; index--) {
      final other = rng.nextInt(index + 1);
      final swap = options[index];
      options[index] = options[other];
      options[other] = swap;
    }
    final native = switch (zone) {
      LiteBiome.campo => const {LiteCompanion.goblinColla},
      LiteBiome.foresta => const {LiteCompanion.bunnys},
      LiteBiome.dungeon => const {
        LiteCompanion.lumin,
        LiteCompanion.divoramituMini,
      },
      LiteBiome.postea => const {LiteCompanion.lumin},
      LiteBiome.deserto => const {LiteCompanion.piccolaMarea},
      LiteBiome.orea => const {LiteCompanion.orbietto, LiteCompanion.bunnys},
    };
    return [
      ...options.where(native.contains),
      ...options.where((pet) => !native.contains(pet)),
    ].take(3).toList(growable: false);
  }

  void _bringPet(
    LiteCompanion pet, {
    LiteCoopFighter? fighter,
    Point<double>? near,
  }) {
    final origin = near ?? fighter?.position ?? position;
    final facing = fighter?.aim ?? aim;
    final beside = origin + Point(-facing.y, facing.x) * 1.15;
    clones.add(
      LiteClone(
        _safePoint(beside, .35, origin),
        pet.life,
        pet.weapon,
        companion: pet,
        ownerId: fighter?.id ?? 0,
        recruitedFloor: stage,
        id: _nextId++,
      ).._growWith(fighter?.level ?? level),
    );
  }

  bool bringStarterPet(LiteCompanion pet, [LiteCoopFighter? fighter]) {
    if (time != 0 ||
        stage != 0 ||
        pet.discovery == null ||
        tradablePets(fighter).isNotEmpty)
      return false;
    _bringPet(pet, fighter: fighter);
    return true;
  }

  Iterable<LiteClone> tradablePets([LiteCoopFighter? fighter]) => clones.where(
    (ally) =>
        ally.ownerId == (fighter?.id ?? 0) &&
        ally.hp > 0 &&
        !ally.corrupted &&
        ally.companion?.discovery != null,
  );

  Point<double>? get petTraderPosition {
    if (!restHub || finished) return null;
    final random = _LiteRandom(seed ^ ((stage + 1) * 27109) ^ 0x03ef5127)
      ..nextDouble()
      ..nextDouble();
    return random.nextInt(100) < 35 ? const Point(9.0, 16.4) : null;
  }

  bool canSpeakToPetTrader([LiteCoopFighter? fighter]) {
    final trader = petTraderPosition;
    return trader != null &&
        (fighter?.connected ?? true) &&
        (fighter?.hp ?? hp) > 0 &&
        (fighter?.position ?? position).distanceTo(trader) < 2.25;
  }

  List<LiteCompanion> petTradeOffers([LiteCoopFighter? fighter]) {
    if (!canSpeakToPetTrader(fighter) ||
        (fighter?.supply ?? supply)._petTradeStage == stage)
      return const [];
    final owned = tradablePets(fighter).map((ally) => ally.companion).toSet();
    if (owned.isEmpty) return const [];
    return LitePets.starterOffers(
      LiteCompanion.values.where((pet) => !owned.contains(pet)),
      biome,
      seed ^ stage * 49139,
    );
  }

  bool tradePet(int giveId, LiteCompanion take, [LiteCoopFighter? fighter]) {
    if (!petTradeOffers(fighter).contains(take)) return false;
    final old = tradablePets(fighter)
        .where((pet) => pet.id == giveId)
        .firstOrNull;
    if (old == null) return false;
    (fighter?.supply ?? supply)._petTradeStage = stage;
    clones.remove(old);
    _bringPet(take, fighter: fighter);
    message = 'Scambio · ' + take.label + ' si unisce alla run.';
    return true;
  }
}
