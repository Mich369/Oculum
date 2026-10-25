part of '../../main.dart';

Map<String, dynamic> oculumRecordMonsterKills(
  Map previous,
  Iterable<Map> enemies,
  String encounter,
) {
  final result = <String, dynamic>{
    for (final e in previous.entries) '${e.key}': oculumCopyJsonTree(e.value),
  };
  for (final enemy in enemies) {
    if (oculumEncounterEnemyIsSummon(enemy)) continue;
    final id = '${enemy['monsterBookId'] ?? ''}';
    if (id.isEmpty) continue;
    final current = Map<String, dynamic>.from(result[id] as Map? ?? {});
    final ids = (current['killIds'] as List? ?? []).map((e) => '$e').toSet();
    final key = '$encounter:${enemy['monsterSheetTag'] ?? enemy['id']}';
    if (!ids.add(key)) continue;
    result[id] = {
      ...current,
      'killIds': ids.toList(),
      'count': readIntValue(current['count']) + 1,
    };
  }
  return result;
}

extension _OculumMonsterKillCounts on _OculumHomePageState {
  int monsterKillsRecorded(String id) {
    final exact = (partyChest['monsterKillCounts'] as Map?)?[id];
    if (exact is Map) return max(0, readIntValue(exact['count']));
    if (oculumPartyHuntSpeciesId(id) != id) return 0;
    // Older saves have partial hunt ledgers; reuse their recorded history.
    final planar = (partyChest['planarHunts'] as Map?)?[id];
    final historical = partyHuntsForMonster(
      id,
    ).map((r) => readIntValue(r['count']));
    return max(
      planar is Map ? readIntValue(planar['count']) : 0,
      historical.isEmpty ? 0 : historical.reduce(max),
    );
  }

  String monsterKillCountLabel(String id) {
    final family = oculumPartyHuntSpeciesId(id);
    final ledger = partyChest['monsterKillCounts'] as Map? ?? {};
    final familyIds = <String>{
      id,
      for (final key in ledger.keys)
        if (oculumPartyHuntSpeciesId('$key') == family) '$key',
    };
    final exact = monsterKillsRecorded(id);
    final total = familyIds.fold<int>(
      0,
      (n, key) => n + monsterKillsRecorded(key),
    );
    return 'Uccisioni registrate: $exact${total > exact ? ' · Totale specie: $total' : ''}';
  }

  void recordAllMonsterKills(Iterable<Map> enemies, String encounter) {
    final old = Map<String, dynamic>.from(
      partyChest['monsterKillCounts'] as Map? ?? {},
    );
    for (final enemy in enemies) {
      final id = '${enemy['monsterBookId'] ?? ''}';
      if (id.isNotEmpty && !old.containsKey(id)) {
        old[id] = {'count': monsterKillsRecorded(id), 'killIds': <String>[]};
      }
    }
    partyChest['monsterKillCounts'] = oculumRecordMonsterKills(
      old,
      enemies,
      encounter,
    );
  }
}
