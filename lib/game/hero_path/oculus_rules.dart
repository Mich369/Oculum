import 'dart:math';

enum EntityKind { player, npc, monster }

enum HeroDifficulty { easy, medium, hard, oculum }

enum HeroMode { normal, aging, roguelite }

enum EyeRarity { common, uncommon, rare, oculum }

/// Shared Oculus progression: title missions advance Power, never scene count.
int oculusPowerDieForTitleLevel(int level) {
  final n = level.clamp(0, 12);
  return n >= 12
      ? 20
      : n >= 10
      ? 12
      : n >= 7
      ? 10
      : n >= 4
      ? 8
      : n >= 2
      ? 6
      : 4;
}

class OculusRules {
  static const baseActions = 2;
  static const questSceneLimit = 4;
  static const scenarioEventBoost = 20;
  static const maxActions = 8;
  static const dice = [4, 6, 8, 10, 12, 20];
  static const stats = ['resilienza', 'volonta', 'materia', 'oculum'];
  static const inspirations = [3, 2, 1];
  static const deathThresholds = [8, 10, 12, 15];
  static const reforge = [
    [70, 50, 30, 0],
    [60, 40, 20, 0],
    [50, 30, 12, 0],
    [40, 20, 7, 0],
  ];
  static const dustBond = 20;
  static const rareBond350 = 5;
  static const rareBond250 = 15;
  static const maxBond = 1000;
  static const miniBossGrowth = 6;
  static const bossGrowth = 12;
  static const growth = 3;
  static const defendCm = 3;
  static const beamShieldNatural = 18;
  static const beamDefenseNatural = 20;
  static const antlerDamage = 20;
  static const antlerCooldown = 2;
  static const antlerEquipment = 15;
  static const adaptationCap = .15;
  static const adaptationHit = .0005;
  static const adaptationHandled = .0015;
  static const adaptationPerScene = 3;
  static const sleepCost = 2;
  static const scenesPerDay = 6;
  static const ageInterval = 18;
  static const oldAgeScene = 240;
  static const forestUnlock = 12;
  static const bleedDamage = 1;
  static const strainDamage = 1;
  static const bleedProtection = 2;
  static const protectionScenes = 3;
  static const enemyTierScenes = 12;
  static const captureChance = 20;
  static const companionTargetChance = 25;
  static const maxEyes = 3;
  static const healCost = 4;
  static const upgradeCost = 2;
  static const mineralCost = 2;
  static const titleInterval = 4;
  static const fightReward = [4, 5, 6, 8];
  static const encounterPressure = [0, 1, 2, 3];
  static const escapeTarget = [3, 4, 5, 6];

  static bool critical(int total, int enemy) => total >= 2 * enemy;
  static bool deathSuccess(
    EntityKind kind,
    HeroDifficulty difficulty,
    int natural,
  ) =>
      kind == EntityKind.player && natural >= deathThresholds[difficulty.index];
  static int rebirthLife(
    HeroDifficulty difficulty,
    Map<String, int> stats,
    int medicine,
  ) =>
      medicine +
      switch (difficulty) {
        HeroDifficulty.easy => stats.values.fold(0, (a, b) => a + b),
        HeroDifficulty.medium =>
          (stats['resilienza'] ?? 0) + (stats['volonta'] ?? 0),
        HeroDifficulty.hard => stats['resilienza'] ?? 0,
        HeroDifficulty.oculum => 0,
      };
  static int growthAt(int level, {bool boss = false, bool miniBoss = false}) =>
      level * growth +
      level ~/
          3 *
          (boss
              ? bossGrowth
              : miniBoss
              ? miniBossGrowth
              : 0);
  static int initialBond(EyeRarity rarity, int percentile) =>
      rarity != EyeRarity.oculum
      ? 0
      : percentile < rareBond350
      ? 350
      : percentile < rareBond250
      ? 250
      : 0;
  static int reforgeCost(EyeRarity rarity) => rarity.index + 1;
}

/// Serializable RNG: replay continues identically after saving, including on web.
class HeroRandom {
  HeroRandom(int seed) : state = seed % 2147483647 == 0 ? 1 : seed % 2147483647;
  int state;
  int nextInt(int upper) {
    if (upper <= 0) throw ArgumentError.value(upper);
    state = (state * 48271) % 2147483647;
    return state % upper;
  }

  int die(int sides) => nextInt(sides) + 1;
  T weighted<T>(List<T> values, int Function(T) weight) {
    final eligible = values.where((v) => weight(v) > 0).toList();
    final total = eligible.fold<int>(0, (n, v) => n + weight(v));
    if (total == 0) throw StateError('No eligible event');
    var roll = nextInt(total);
    for (final v in eligible) {
      roll -= weight(v);
      if (roll < 0) return v;
    }
    return eligible.last;
  }
}

int heroInt(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
Map<String, dynamic> heroMap(Object? value) =>
    value is Map ? value.map((k, v) => MapEntry('$k', v)) : {};
List<String> heroStrings(Object? value) =>
    value is List ? value.map((e) => '$e').toList() : [];
int heroClamp(int value, int upper) => max(0, min(value, upper));
