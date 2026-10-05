import 'dart:math';
import 'oculum_diary_memory.dart';

/// Count explicitly classified links once; rebuilding the map grants nothing.
class OculumMemoryInspiration {
  final Map<String, int> highWater = {};
  int remainder = 0;
  int chance = 50;
  bool failed = false;
  String difficulty = 'normale';
  int get baseChance => difficulty == 'oculum' ? 25 : 50;
  int get maximumChance => switch (difficulty) {
    'facile' => 95,
    'difficile' => 60,
    'oculum' => 50,
    _ => 75,
  };
  OculumMemoryInspiration();

  int observe(DiaryMemory memory, {Random? random}) =>
      observeRewards(memory, random: random).length;

  List<String> observeRewards(
    DiaryMemory memory, {
    Random? random,
    String? difficulty,
  }) {
    if (difficulty != null && difficulty != this.difficulty) {
      this.difficulty = difficulty;
      chance = failed ? chance.clamp(baseChance, maximumChance) : baseChance;
    }
    final documents = <String, DiaryDocument>{};
    for (final relation in memory.relations) {
      final doc = relation.evidence.document;
      if (!doc.id.startsWith('eye_note:')) documents[doc.id] = doc;
    }
    return observeDocuments(
      documents.values,
      random: random,
      difficulty: difficulty,
    );
  }

  List<String> observeDocuments(
    Iterable<DiaryDocument> documents, {
    Random? random,
    String? difficulty,
  }) {
    if (difficulty != null && difficulty != this.difficulty) {
      this.difficulty = difficulty;
      chance = failed ? chance.clamp(baseChance, maximumChance) : baseChance;
    }
    var newMarks = 0;
    for (final doc in documents) {
      final count = RegExp(r'\[\[([^:\]\n]+):([^\]\n]+)\]\]')
          .allMatches(doc.text)
          .where(
            (match) =>
                diaryLinkKindByType.containsKey(diaryKey(match[1]!)) &&
                match[2]!.split('|').first.trim().isNotEmpty,
          )
          .length;
      final previous = highWater[doc.id] ?? 0;
      newMarks += max(0, count - previous);
      highWater[doc.id] = max(previous, count);
    }
    final rewards = <String>[];
    final rng = random ?? Random.secure();
    for (var mark = 0; mark < newMarks; mark++) {
      if (failed) chance = min(maximumChance, chance + 5);
      remainder++;
      if (remainder < 10) continue;
      remainder -= 10;
      if (rng.nextInt(100) < chance) {
        final type = rng.nextInt(100);
        rewards.add(
          type < 70
              ? 'base'
              : type < 90
              ? 'super'
              : 'oculum',
        );
        chance = baseChance;
        failed = false;
      } else {
        failed = true;
      }
    }
    return rewards;
  }

  Map<String, dynamic> toJson() => {
    'version': 2,
    'highWater': highWater,
    'remainder': remainder,
    'chance': chance,
    'failed': failed,
    'difficulty': difficulty,
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
    result.remainder = (int.tryParse('${value['remainder']}') ?? 0).clamp(0, 9);
    if (value['version'] == 2) {
      result.difficulty = '${value['difficulty'] ?? 'normale'}';
      result.chance = (int.tryParse('${value['chance']}') ?? result.baseChance)
          .clamp(result.baseChance, result.maximumChance);
      result.failed = value['failed'] == true;
    }
    return result;
  }
}
