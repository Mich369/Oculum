import 'dart:math';
import 'oculus_rules.dart';

class HeroActor {
  HeroActor({
    required this.id,
    required this.name,
    this.kind = EntityKind.player,
  });
  String id, name;
  EntityKind kind;
  int level = 0,
      titleLevel = 0,
      hp = 8,
      oculum = 8,
      volonta = 4,
      materia = 4,
      shield = 4;
  int points = 0, dieSteps = 0, cm = 0;
  bool boss = false, miniBoss = false;
  Map<String, int> dice = {for (final k in OculusRules.stats) k: 4};
  Map<String, int> stats = {for (final k in OculusRules.stats) k: 0};
  Map<String, int> conditions = {};
  List<int> inspirations = List.of(OculusRules.inspirations);
  int get powerDie => oculusPowerDieForTitleLevel(titleLevel);
  int get maxHp => dice['resilienza']! + powerDie + stats['resilienza']!;
  int get maxOculum => dice['oculum']! + powerDie + stats['oculum']!;
  int get maxShield => dice['materia']! + stats['materia']!;
  int get maxVolonta => dice['volonta']! + stats['volonta']!;
  int get maxMateria => dice['materia']! + stats['materia']!;
  int get defense => maxMateria + powerDie;
  int get baseDamage => maxVolonta + powerDie;
  void replenish() {
    hp = maxHp;
    oculum = maxOculum;
    volonta = maxVolonta;
    materia = maxMateria;
    shield = maxShield;
  }

  void levelUp() {
    if (level >= 12) return;
    level++;
    points +=
        OculusRules.growth +
        (level % 3 == 0
            ? (boss
                  ? OculusRules.bossGrowth
                  : miniBoss
                  ? OculusRules.miniBossGrowth
                  : 0)
            : 0);
    dieSteps++;
  }

  bool allocate(String key) {
    if (points <= 0 || !stats.containsKey(key)) return false;
    stats[key] = stats[key]! + 1;
    points--;
    return true;
  }

  bool advanceDie(String key) {
    if (dieSteps <= 0 || !dice.containsKey(key)) return false;
    final index = OculusRules.dice.indexOf(dice[key]!);
    if (index < 0 || index == OculusRules.dice.length - 1) return false;
    dice[key] = OculusRules.dice[index + 1];
    dieSteps--;
    return true;
  }

  void quickAllocate() {
    while (points > 0) {
      final key = OculusRules.stats.reduce(
        (a, b) => stats[a]! <= stats[b]! ? a : b,
      );
      allocate(key);
    }
    while (dieSteps > 0 && dice.values.any((d) => d < 20)) {
      final key = OculusRules.stats.reduce(
        (a, b) => dice[a]! <= dice[b]! ? a : b,
      );
      advanceDie(key);
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'level': level,
    'titleLevel': titleLevel,
    'hp': hp,
    'oculum': oculum,
    'volonta': volonta,
    'materia': materia,
    'shield': shield,
    'points': points,
    'dieSteps': dieSteps,
    'cm': cm,
    'boss': boss,
    'miniBoss': miniBoss,
    'dice': dice,
    'stats': stats,
    'conditions': conditions,
    'inspirations': inspirations,
  };
  factory HeroActor.fromJson(Map<String, dynamic> d) {
    final a = HeroActor(
      id: '${d['id'] ?? 'player'}',
      name: '${d['name'] ?? 'Senza nome'}',
      kind: EntityKind.values.firstWhere(
        (e) => e.name == d['kind'],
        orElse: () => EntityKind.player,
      ),
    );
    a.level = heroInt(d['level']).clamp(0, 12);
    a.titleLevel = heroInt(d['titleLevel']).clamp(0, 12);
    a.boss = d['boss'] == true;
    a.miniBoss = d['miniBoss'] == true;
    for (final k in OculusRules.stats) {
      final die = heroInt(heroMap(d['dice'])[k], 4);
      a.dice[k] = OculusRules.dice.contains(die) ? die : 4;
      a.stats[k] = max(0, heroInt(heroMap(d['stats'])[k]));
    }
    a.hp = max(0, heroInt(d['hp'], a.maxHp));
    a.oculum = heroClamp(heroInt(d['oculum'], a.maxOculum), a.maxOculum);
    a.volonta = heroClamp(heroInt(d['volonta'], a.maxVolonta), a.maxVolonta);
    a.materia = heroClamp(heroInt(d['materia'], a.maxMateria), a.maxMateria);
    a.shield = max(0, heroInt(d['shield'], a.maxShield));
    a.points = max(0, heroInt(d['points']));
    a.dieSteps = max(0, heroInt(d['dieSteps']));
    a.cm = max(0, heroInt(d['cm']));
    a.conditions = heroMap(
      d['conditions'],
    ).map((k, v) => MapEntry(k, heroInt(v)));
    if (d['inspirations'] is List) {
      final list = d['inspirations'] as List;
      a.inspirations = List.generate(
        3,
        (i) => i < list.length
            ? max(0, heroInt(list[i]))
            : OculusRules.inspirations[i],
      );
    }
    return a;
  }
}

class HeroEye {
  HeroEye({required this.actor, this.rarity = EyeRarity.common});
  String sourceId = 'ossa';
  HeroActor actor;
  EyeRarity rarity;
  int bond = 0,
      reforgeAttempts = 0,
      failures = 0,
      rebirthsUsed = 0,
      lastSummon = -1;
  bool summoned = false;
  bool get awakened =>
      rarity == EyeRarity.oculum && bond >= OculusRules.maxBond;
  int get growthLimit => [3, 6, 9, 12][rarity.index];
  void summon(int scene) {
    if (actor.hp <= 0) return;
    summoned = true;
    if (lastSummon == scene) return;
    lastSummon = scene;
    bond = min(OculusRules.maxBond, bond + 10 + actor.level);
    final target = min(growthLimit, bond ~/ 80);
    while (actor.level < target) {
      actor.levelUp();
    }
  }

  void rest() {
    if (actor.hp > 0) {
      actor.replenish();
      return;
    }
    if (awakened || min(3, bond ~/ 300) > rebirthsUsed) {
      if (!awakened) rebirthsUsed++;
      actor.hp = max(1, (actor.maxHp * .1).ceil());
    }
  }

  Map<String, dynamic> toJson() => {
    'sourceId': sourceId,
    'actor': actor.toJson(),
    'rarity': rarity.name,
    'bond': bond,
    'reforgeAttempts': reforgeAttempts,
    'failures': failures,
    'rebirthsUsed': rebirthsUsed,
    'lastSummon': lastSummon,
    'summoned': summoned,
  };
  factory HeroEye.fromJson(Map<String, dynamic> d) {
    final legacy = !d.containsKey('actor');
    final e = HeroEye(
      actor: HeroActor.fromJson(
        legacy ? {...d, 'kind': 'monster'} : heroMap(d['actor']),
      ),
      rarity: EyeRarity.values.firstWhere(
        (e) => e.name == d['rarity'],
        orElse: () =>
            d['oculumRarity'] == true ? EyeRarity.oculum : EyeRarity.common,
      ),
    );
    e.bond = heroInt(d['bond']).clamp(0, OculusRules.maxBond);
    e.sourceId = '${d['sourceId'] ?? 'ossa'}';
    e.reforgeAttempts = max(0, heroInt(d['reforgeAttempts']));
    e.failures = max(0, heroInt(d['failures']));
    e.rebirthsUsed = max(0, heroInt(d['rebirthsUsed']));
    e.lastSummon = heroInt(d['lastSummon'], -1);
    e.summoned = d['summoned'] == true;
    return e;
  }
}

class HeroRoll {
  HeroRoll(
    this.label,
    this.faces,
    this.natural,
    this.powerFaces,
    this.power,
    this.bonus,
  );
  final String label;
  final int faces, natural, powerFaces, power, bonus;
  int get total => natural + power + bonus;
  Map<String, dynamic> toJson() => {
    'label': label,
    'faces': faces,
    'natural': natural,
    'powerFaces': powerFaces,
    'power': power,
    'bonus': bonus,
  };
  factory HeroRoll.fromJson(Map<String, dynamic> d) => HeroRoll(
    '${d['label']}',
    heroInt(d['faces'], 4),
    heroInt(d['natural']),
    heroInt(d['powerFaces'], 4),
    heroInt(d['power']),
    heroInt(d['bonus']),
  );
}
