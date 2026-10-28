part of '../../main.dart';

bool oculumProgressionEnemyPowerEligible(int enemyPower, int ownerPower) =>
    enemyPower >= 0 && ownerPower >= 0 && enemyPower >= ownerPower - 25;

/// Only a confirmed death delivered to a participant can call this recorder.
/// Unknown power is not silently treated as an eligible enemy.
Map<String, dynamic> oculumRecordPersonalProgressionKills(
  Map previous,
  Iterable<Map> enemies,
  String encounter,
  int ownerPower,
) => oculumRecordMonsterKills(
  previous,
  enemies.where(
    (enemy) =>
        oculumProgressionEnemyPowerEligible(
          readIntValue(enemy['totalPower'], fallback: -1),
          ownerPower,
        ) &&
        ('${enemy['monsterSheetTag'] ?? ''}'.trim().isNotEmpty ||
            '${enemy['id'] ?? ''}'.trim().isNotEmpty),
  ),
  encounter,
);

/// Named objectives use authored identity metadata, never a display name or
/// the generic monster species that the NPC was built from.
Map<String, dynamic> oculumRecordNamedNpcProgressionKills(
  Map previous,
  Iterable<Map> enemies,
  String encounter,
  int ownerPower,
) => oculumRecordMonsterKills(previous, [
  for (final enemy in enemies)
    if ('${enemy['canonicalNpc'] ?? ''}'.trim().isNotEmpty &&
        // Authored exception: Erik's death unlocks Senka's technique even when
        // she has already surpassed his power. Other named NPCs retain the gate.
        ('${enemy['canonicalNpc']}'.trim() == 'erik_i' ||
            oculumProgressionEnemyPowerEligible(
              readIntValue(enemy['totalPower'], fallback: -1),
              ownerPower,
            )))
      {...enemy, 'monsterBookId': '${enemy['canonicalNpc']}'.trim()},
], encounter);

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
    final sheetTag = '${enemy['monsterSheetTag'] ?? ''}'.trim();
    final enemyId = sheetTag.isNotEmpty
        ? sheetTag
        : '${enemy['id'] ?? ''}'.trim();
    if (enemyId.isEmpty) continue;
    final key = '$encounter:$enemyId';
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
