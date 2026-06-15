import 'monster_book.dart';
import 'skills.dart';
import 'drops.dart';

Map<String, Map<String, String>> getSkillsForMonster(String monsterId) {
  final m = monsterById(monsterId);
  if (m == null) return {};
  final Map<String, Map<String, String>> out = {};
  for (final sid in m.skillIds) {
    if (monsterSkillDefinitions.containsKey(sid)) {
      out[sid] = monsterSkillDefinitions[sid]!;
    }
  }
  return out;
}

Map<String, Map<String, Object>> getDropsForMonster(String monsterId) {
  final m = monsterById(monsterId);
  if (m == null) return {};
  final Map<String, Map<String, Object>> out = {};
  for (final did in m.dropIds) {
    if (monsterDropDefinitions.containsKey(did)) {
      out[did] = monsterDropDefinitions[did]!;
    }
  }
  return out;
}

Map<String, int> getStatsForMonster(String monsterId) {
  final m = monsterById(monsterId);
  if (m == null) return {};
  return m.stats;
}
