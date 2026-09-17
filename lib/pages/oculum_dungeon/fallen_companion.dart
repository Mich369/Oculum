import 'dart:math';

bool dungeonFallenCaptureSucceeds(int roll) => roll >= 0 && roll < 20;

class DungeonFallenCompanion {
  DungeonFallenCompanion({
    required this.id,
    required this.name,
    required this.maxHp,
    required this.hp,
    required this.damage,
    required this.defense,
    required this.level,
    this.oculumRarity = false,
  });
  final String id, name;
  final int maxHp, damage, defense, level;
  final bool oculumRarity;
  int hp;
  int bond = 0;
  int rebirthsUsed = 0;
  String lastSummon = '';
  final Set<String> restEvents = {};
  bool get dead => hp <= 0;
  bool get awakened => oculumRarity && bond >= 1000;
  int get rebirths => max(0, min(3, bond ~/ 300) - rebirthsUsed);
  void summon(String encounter) {
    if (dead || lastSummon == encounter) return;
    lastSummon = encounter;
    bond = min(1000, bond + 10 + level);
  }

  bool ownerLongRest(String event) {
    if (!dead || restEvents.contains(event) || (!awakened && rebirths == 0)) {
      return false;
    }
    restEvents.add(event);
    if (!awakened) rebirthsUsed++;
    hp = max(1, (maxHp * .1).ceil());
    return true;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'maxHp': maxHp,
    'hp': hp,
    'damage': damage,
    'defense': defense,
    'level': level,
    'oculumRarity': oculumRarity,
    'bond': bond,
    'rebirthsUsed': rebirthsUsed,
    'lastSummon': lastSummon,
    'restEvents': restEvents.toList(),
  };
  factory DungeonFallenCompanion.fromJson(Map<String, dynamic> data) {
    int number(String key, [int fallback = 0]) =>
        (data[key] as num?)?.toInt() ?? fallback;
    final maxHp = max(1, number('maxHp', 20));
    final result = DungeonFallenCompanion(
      id: '${data['id']}',
      name: '${data['name']}',
      maxHp: maxHp,
      hp: number('hp').clamp(0, maxHp),
      damage: max(1, number('damage', 2)),
      defense: max(0, number('defense')),
      level: max(0, number('level')),
      oculumRarity: data['oculumRarity'] == true,
    );
    result.bond = number('bond').clamp(0, 1000);
    result.rebirthsUsed = max(0, number('rebirthsUsed'));
    result.lastSummon = '${data['lastSummon'] ?? ''}';
    result.restEvents.addAll(
      (data['restEvents'] as List? ?? const []).whereType<String>(),
    );
    return result;
  }
}
