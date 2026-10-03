import 'dart:math';
import 'oculum_diary_memory.dart';

/// New source-backed mentions count once; graph rebuilds never grant rewards.
class OculumMemoryInspiration {
  final Map<String, int> highWater = {};
  int remainder = 0;
  int chance = 10;
  OculumMemoryInspiration();

  int observe(DiaryMemory memory, {Random? random}) {
    final mentions = <String, Set<String>>{};
    final scanned = <String>{};
    for (final relation in memory.relations) {
      final e = relation.evidence;
      final target = memory.entities[relation.to];
      final entity = target?.kind == 'diary'
          ? memory.entities[relation.from]
          : target;
      if (entity == null || entity.kind == 'diary' || entity.kind == 'campaign') {
        continue;
      }
      if (!scanned.add('${e.document.id}:${entity.id}:${e.start}:${e.end}')) {
        continue;
      }
      final names =
          {
              entity.name,
              ...entity.aliases,
            }.where((name) => name.trim().isNotEmpty).toList()
            ..sort((a, b) => b.length.compareTo(a.length));
      if (names.isEmpty) continue;
      final pattern = RegExp(
        '(?<![A-Za-zÀ-ÖØ-öø-ÿ0-9_])(?:${names.map(RegExp.escape).join('|')})(?![A-Za-zÀ-ÖØ-öø-ÿ0-9_])',
        caseSensitive: false,
      );
      for (final match in pattern.allMatches(e.quote)) {
        mentions
            .putIfAbsent(e.document.id, () => {})
            .add(
              '${entity.id}:${e.start + match.start}:${e.start + match.end}',
            );
      }
    }
    for (final entry in mentions.entries) {
      final previous = highWater[entry.key] ?? 0;
      remainder += max(0, entry.value.length - previous);
      highWater[entry.key] = max(previous, entry.value.length);
    }
    var rewards = 0;
    final rng = random ?? Random.secure();
    while (remainder >= 3) {
      remainder -= 3;
      if (rng.nextInt(100) < chance) {
        rewards++;
        chance = 10;
      } else {
        chance = min(100, chance + 10);
      }
    }
    return rewards;
  }

  Map<String, dynamic> toJson() => {
    'highWater': highWater,
    'remainder': remainder,
    'chance': chance,
  };
  factory OculumMemoryInspiration.fromJson(dynamic value) {
    final result = OculumMemoryInspiration();
    if (value is! Map) return result;
    if (value['highWater'] is Map) {
      for (final entry in (value['highWater'] as Map).entries) {
        result.highWater['${entry.key}'] = max(
          0,
          int.tryParse('${entry.value}') ?? 0,
        );
      }
    }
    result.remainder = (int.tryParse('${value['remainder']}') ?? 0).clamp(0, 2);
    result.chance = (int.tryParse('${value['chance']}') ?? 10).clamp(10, 100);
    return result;
  }
}
