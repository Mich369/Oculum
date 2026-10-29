part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member
bool oculumEncounterEnemyKilled(Map token) =>
    token['side'] == 'enemy' && token['status'] == 'dead';

String oculumEncounterFinalKillerTag(Map token, {Map? sheet}) {
  final recordedAttack = '${token['rewardLastDamageRequestId'] ?? ''}';
  final finalAttack = '${token['rewardFinalAttackId'] ?? recordedAttack}';
  final recordedSource = '${token['rewardLastDamageSourceTag'] ?? ''}';
  if (recordedAttack.isNotEmpty &&
      recordedAttack == finalAttack &&
      recordedSource.isNotEmpty) {
    return recordedSource;
  }
  return [
        sheet?['lastDamageSourceTag'],
        token['lastDamageSourceTag'],
      ].map((v) => '${v ?? ''}').where((v) => v.isNotEmpty).firstOrNull ??
      '';
}

const String oculumEncounterRewardMethodDifference = 'stats_level_difference';
const String oculumEncounterRewardMethodLegacy = 'legacy';

String oculumEncounterRewardMethod(Object? raw) =>
    raw == oculumEncounterRewardMethodLegacy
    ? oculumEncounterRewardMethodLegacy
    : oculumEncounterRewardMethodDifference;

bool oculumEncounterHasKnownCoreStats(Map sheet) => const [
  'resilienza',
  'volonta',
  'materia',
  'oculum',
].every((key) => sheet[key] is num || int.tryParse('${sheet[key]}') != null);

int? oculumEncounterExplicitTotalPower(Map sheet) {
  if (oculumEncounterHasKnownCoreStats(sheet)) return null;
  final exactPower = sheet['totalPower'];
  if (exactPower is num || int.tryParse('$exactPower') != null) {
    return max(0, readIntValue(exactPower));
  }
  final coreTotal = sheet['statsTotal'];
  if (coreTotal is num || int.tryParse('$coreTotal') != null) {
    return (max(0, readIntValue(coreTotal)) +
            max(0, readIntValue(sheet['livello'] ?? sheet['level'])) +
            3 * readIntValue(sheet['grado'] ?? sheet['grade']).clamp(0, 12) +
            oculumHpTotalPowerBonusForGrade(
              readIntValue(sheet['grado'] ?? sheet['grade']),
              level: readIntValue(sheet['livello'] ?? sheet['level']),
            ))
        .toInt();
  }
  return null;
}

bool oculumEncounterHasKnownRewardPower(Map sheet) =>
    oculumEncounterHasKnownCoreStats(sheet) ||
    oculumEncounterExplicitTotalPower(sheet) != null;

/// The new method deliberately excludes the legacy category, difficulty,
/// discovery and Chained Fate multipliers. Grade is compared per enemy and
/// recipient, with the same rounding as the established grade calculation.
int oculumEncounterDifferenceExperience(
  Iterable<Map> enemies, {
  required int characterStats,
  required int characterLevel,
  required int characterGrade,
  int? characterAverageTotalPower,
}) {
  final enemyBudget = enemies.fold<int>(0, (sum, enemy) {
    final base = enemy['rewardAverageTotalPower'] is num
        ? max(0, readIntValue(enemy['rewardAverageTotalPower']))
        : enemy['totalPower'] is num
        ? max(0, readIntValue(enemy['totalPower']))
        : oculumScoutPower(max(0, readIntValue(enemy['level'])), [
            max(
              0,
              readIntValue(enemy['permanentStatsTotal'] ?? enemy['statsTotal']),
            ),
          ], grade: readIntValue(enemy['grade']));
    return sum +
        (base *
                oculumExperienceGradeMultiplier(
                  readIntValue(enemy['grade']),
                  characterGrade,
                ))
            .round();
  });
  return max(
    0,
    enemyBudget -
        max(
          0,
          characterAverageTotalPower ??
              oculumScoutPower(characterLevel, [
                characterStats,
              ], grade: characterGrade),
        ),
  ).clamp(0, 100000000).toInt();
}

int oculumEncounterFinishingExperience(
  Iterable<Map> enemies, {
  required String characterTag,
  required int characterTotalPower,
}) {
  if (characterTag.trim().isEmpty) return 0;
  var result = 0;
  for (final enemy in enemies) {
    if (!oculumSameSheetIdentity(enemy['killerTag'], characterTag)) continue;
    final enemyPower = max(
      0,
      readIntValue(enemy['rewardAverageTotalPower'] ?? enemy['totalPower']),
    );
    final recordedPower = readIntValue(
      enemy['killerAverageTotalPower'] ?? enemy['killerTotalPower'],
      fallback: -1,
    );
    final killerPower = max(
      0,
      recordedPower >= 0 ? recordedPower : characterTotalPower,
    );
    result += max(0, enemyPower - killerPower);
  }
  return result.clamp(0, 100000000);
}

String oculumEncounterSettlementId(
  String encounterId,
  String fightInstanceId,
) => 'fight:$encounterId:$fightInstanceId';

final Expando<Set<String>> _oculumEncounterSettlementInFlight =
    Expando<Set<String>>('Oculum encounter settlement');

int oculumEncounterPermanentTotalPower(Map sheet) =>
    (oculumEncounterPermanentCoreStats(
              sheet,
            ).values.fold<int>(0, (a, b) => a + b) +
            max(0, readIntValue(sheet['livello'] ?? sheet['level'])) +
            3 * readIntValue(sheet['grado'] ?? sheet['grade']).clamp(0, 12) +
            oculumHpTotalPowerBonusForGrade(
              readIntValue(sheet['grado'] ?? sheet['grade']),
              level: readIntValue(sheet['livello'] ?? sheet['level']),
            ))
        .toInt();

/// Older snapshots have no sampled combat value. The permanent fallback is
/// explicit, excluding every ordinary equipped object, including Senka's mask.
int oculumEncounterInstantRewardTotalPower(Map sheet) {
  final explicit = oculumEncounterExplicitTotalPower(sheet);
  if (explicit != null) return explicit;
  if (sheet['derivedRewardTotalPower'] is num) {
    return max(0, readIntValue(sheet['derivedRewardTotalPower']));
  }
  final copy = Map<String, dynamic>.from(sheet);
  copy['inventario'] = [
    for (final raw
        in (sheet['inventario'] as List? ?? const []).whereType<Map>())
      if ((raw['craftData'] as Map?)?['titleItem'] == true) raw,
  ];
  return oculumEncounterPermanentTotalPower(copy);
}

Set<String> oculumEncounterWeakestParticipants(Map<String, int> knownPowers) {
  if (knownPowers.isEmpty) return const {};
  final minimum = knownPowers.values.reduce(min);
  return knownPowers.entries
      .where((entry) => entry.value == minimum)
      .map((entry) => entry.key)
      .toSet();
}

bool oculumEncounterResourceExperienceEligible(
  Iterable<Map> enemies, {
  required int characterLevel,
  required int characterGrade,
}) => enemies.any(
  (enemy) =>
      !oculumEncounterEnemyIsSummon(enemy) &&
      (readIntValue(enemy['level']) >= characterLevel + 3 ||
          readIntValue(enemy['grade']) > characterGrade),
);

int oculumEncounterResourceExperience({
  required int oculumSpent,
  required int hpLost,
}) => (max(0, oculumSpent) + max(0, hpLost)) ~/ 5;

int oculumEncounterFinishingObser(
  Iterable<Map> enemies, {
  required String characterTag,
  required int characterAverageTotalPower,
}) => enemies
    .where(
      (e) =>
          e['confirmedMonster'] == true &&
          !oculumEncounterEnemyIsSummon(e) &&
          oculumSameSheetIdentity(e['killerTag'], characterTag),
    )
    .fold<int>(
      0,
      (sum, enemy) =>
          sum +
          max(
            0,
            readIntValue(
                  enemy['rewardAverageTotalPower'] ?? enemy['totalPower'],
                ) -
                characterAverageTotalPower,
          ),
    );

String? oculumEncounterPartyCrystalSize({
  required int deadMonsterPower,
  required int partyPower,
}) {
  final difference = deadMonsterPower - partyPower;
  return difference >= 200
      ? 'grande'
      : difference >= 120
      ? 'medio'
      : difference >= 75
      ? 'piccolo'
      : null;
}

bool _oculumEncounterSupportMatchesEnemy(Map help, Map enemy) {
  final targets = <String>[
    '${help['enemyTag'] ?? ''}',
    ...(help['enemyTags'] as List? ?? const []).map((tag) => '$tag'),
  ].where((tag) => tag.isNotEmpty);
  return targets.any(
    (target) => [
      enemy['id'],
      enemy['monsterSheetTag'],
      enemy['sheetTag'],
    ].any((tag) => tag != null && oculumSameSheetIdentity(target, '$tag')),
  );
}

bool _oculumEncounterRecentHelp(Map help, Map enemy) {
  final death = readIntValue(enemy['deathRound'], fallback: -1);
  final round = readIntValue(help['round'], fallback: -1);
  return death >= 0 && round >= max(0, death - 2) && round <= death;
}

/// A helper gets only the strongest role for one enemy. The killing actor
/// already receives the full PT difference and cannot also receive a share.
int oculumEncounterAssistanceExperience(
  Iterable<Map> enemies, {
  required Iterable<Map> history,
  required String characterTag,
  required int characterTotalPower,
  int? characterAverageTotalPower,
}) {
  if (characterTag.isEmpty) return 0;
  var total = 0;
  final own = history.where(
    (h) => oculumSameSheetIdentity(h['helperTag'], characterTag),
  );
  for (final enemy in enemies) {
    if (oculumSameSheetIdentity(enemy['killerTag'], characterTag)) continue;
    var best = 0;
    for (final help in own) {
      if (!_oculumEncounterSupportMatchesEnemy(help, enemy) ||
          !_oculumEncounterRecentHelp(help, enemy)) {
        continue;
      }
      final kind = '${help['kind']}';
      if (!const {
        'attack',
        'damage',
        'heal',
        'defense',
        'debuff',
      }.contains(kind)) {
        continue;
      }
      if (kind == 'heal' &&
          (readIntValue(help['amount']) <= 0 ||
              readIntValue(help['hpMax']) <= 0 ||
              readIntValue(help['hpBefore']) * 100 >=
                  readIntValue(help['hpMax']) * 51)) {
        continue;
      }
      final recordedPower = readIntValue(
        help['helperTotalPower'],
        fallback: characterTotalPower,
      );
      final power =
          characterAverageTotalPower ??
          (recordedPower >= 0 ? recordedPower : characterTotalPower);
      final difference = max(
        0,
        readIntValue(enemy['rewardAverageTotalPower'] ?? enemy['totalPower']) -
            max(0, power),
      );
      final share = kind == 'heal' || kind == 'defense'
          ? difference ~/ 4
          : kind == 'damage' || kind == 'debuff' || help['finalAttack'] != true
          ? difference ~/ 10
          : help['decisive'] == true
          ? difference ~/ 2
          : difference ~/ 4;
      best = max(best, share);
    }
    total += best;
  }
  return total.clamp(0, 100000000);
}

double oculumEncounterSubtraitExperienceMultiplier(
  Iterable<Map> enemies, {
  required Iterable<Map> history,
  required String characterTag,
}) {
  final ownHistory = history
      .where(
        (help) =>
            help['kind'] != 'damage' &&
            oculumSameSheetIdentity(help['helperTag'], characterTag),
      )
      .toList();
  final unique = <String, Map>{};
  for (final help in ownHistory) {
    if (help['kind'] == 'damage') continue;
    if (!oculumSameSheetIdentity(help['helperTag'], characterTag)) continue;
    final id = '${help['helpReceiptId'] ?? help['id'] ?? ''}';
    if (id.isNotEmpty) unique.putIfAbsent(id, () => help);
  }
  if (unique.isEmpty) return 1.3;
  final recent = ownHistory.any(
    (help) => enemies.any(
      (enemy) =>
          _oculumEncounterSupportMatchesEnemy(help, enemy) &&
          _oculumEncounterRecentHelp(help, enemy),
    ),
  );
  final assistedKills = enemies
      .where(
        (enemy) => ownHistory.any(
          (help) =>
              help['kind'] == 'attack' &&
              help['finalAttack'] == true &&
              _oculumEncounterSupportMatchesEnemy(help, enemy) &&
              _oculumEncounterRecentHelp(help, enemy),
        ),
      )
      .length;
  final tenths =
      (recent ? 13 : 12) + max(0, unique.length - 1) + 2 * assistedKills;
  return tenths / 10;
}

/// Immutable reward comparison, independent from spent resources, Open,
/// conditions and transformations. The title part follows the same permanent
/// progression profile used by unlocks, adding fixed equipped-item bonuses.
Map<String, int> oculumEncounterPermanentCoreStats(Map sheet) {
  const keys = ['resilienza', 'volonta', 'materia', 'oculum'];
  final values = <String, int>{
    for (final key in keys) key: max(0, readIntValue(sheet[key])),
  };
  final context = <String, num>{
    ...values,
    'livello': max(0, readIntValue(sheet['livello'] ?? sheet['level'])),
    'grado': max(0, readIntValue(sheet['grado'] ?? sheet['grade'])),
  };
  void addFixedCommands(String text) {
    for (final command in oculumParseFormulaCommands(text, context)) {
      if (command.valid &&
          command.triggerRaw.isEmpty &&
          values.containsKey(command.key)) {
        values[command.key] = values[command.key]! + command.value;
      }
    }
  }

  final titles = (sheet['titoli'] as List? ?? const [])
      .whereType<Map>()
      .map((raw) => OculumTitle.fromJson(Map<String, dynamic>.from(raw)))
      .toList();
  final racial = (sheet['trattiRazziali'] as List? ?? const [])
      .whereType<Map>()
      .map((raw) => OculumTitle.fromJson(Map<String, dynamic>.from(raw)))
      .toList();
  final allTitles = [...titles, ...racial];
  // Normalization runs only on parsed copies: it must not rewrite the user's
  // saved title selection while calculating a reward comparison.
  oculumNormalizeAlwaysVisibleTitles(
    allTitles,
    racialTraits: racial,
    chooseIndex: (_) => 0,
  );
  final visible = oculumAlwaysVisibleTitle(allTitles);
  for (final title in allTitles) {
    if (!title.equipaggiato) continue;
    final before = Map<String, int>.from(values);
    final fixed = {
      'resilienza': title.resilienza,
      'volonta': title.volonta,
      'materia': title.materia,
      'oculum': title.oculum,
    };
    for (final key in keys) {
      values[key] =
          values[key]! +
          fixed[key]! +
          max(0, title.gradeStatAllocation[key] ?? 0);
    }
    addFixedCommands(title.buff);
    if (identical(title, visible)) {
      for (final key in keys) {
        values[key] =
            values[key]! +
            oculumPublicTitleStatBonus(values[key]! - before[key]!);
      }
    }
  }
  for (final raw
      in (sheet['inventario'] as List? ?? const []).whereType<Map>()) {
    final item = InventoryItem.fromJson(Map<String, dynamic>.from(raw));
    if (!item.equipaggiata ||
        item.gradoRichiesto > readIntValue(sheet['grado']) ||
        item.craftData['senkaMask'] == true) {
      continue;
    }
    if (item.craftData['clothing'] == true) {
      final stat = item.statCrescita;
      if (values.containsKey(stat) &&
          (stat != 'oculum' || readIntValue(sheet['oculum']) > 0)) {
        final every = max(
          1,
          readIntValue(item.craftData['growthEvery'], fallback: 3),
        );
        values[stat] = values[stat]! + max(0, item.livelloOggetto) ~/ every;
      }
    } else if (item.arma || item.protegge) {
      final stat = keys.contains(item.statCrescita)
          ? item.statCrescita
          : item.arma
          ? 'volonta'
          : 'materia';
      if (stat != 'oculum' || readIntValue(sheet['oculum']) > 0) {
        values[stat] =
            values[stat]! +
            max(0, item.livelloOggetto) * item.puntiStatPerLivello.clamp(1, 3);
      }
    }
    addFixedCommands(item.buff);
  }
  if (visible != null) {
    final fixedVisible = oculumVisibleTitleStatBonus(
      grade: readIntValue(sheet['grado'] ?? sheet['grade']),
      evolvedFirstClaim: visible.evoluto && visible.evolvedVisibleBonusActive,
      includeOculum: values['oculum']! > 0,
    );
    for (final key in keys) {
      values[key] = values[key]! + (fixedVisible[key] ?? 0);
    }
  }
  return {for (final key in keys) key: max(0, values[key]!)};
}

Map<String, List<Map<String, dynamic>>> oculumDistributeEncounterLoot({
  required Iterable<InventoryItem> items,
  required Iterable<String> participantTags,
}) {
  final participants =
      participantTags
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  final assignments = <String, List<Map<String, dynamic>>>{
    for (final tag in participants) tag: <Map<String, dynamic>>[],
  };
  if (participants.isEmpty) return assignments;
  var cursor = 0;
  for (final item in items) {
    final tag = participants[cursor++ % participants.length];
    assignments[tag]!.add(item.toJson());
  }
  return assignments;
}

/// A kill can yield at most one Fallen Eye, even when several clients report
/// the same natural-20 Drop. The strongest source goes to the least-developed
/// participant; any remaining eyes are assigned randomly without duplication.
Map<String, List<Map<String, dynamic>>> oculumDistributeFallenEyes({
  required Iterable<Map<String, dynamic>> eyes,
  required Map<String, int> participantStatTotals,
  Random? random,
}) {
  final rng = random ?? Random.secure();
  final tags = participantStatTotals.keys
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .toList();
  final result = <String, List<Map<String, dynamic>>>{
    for (final tag in tags) tag: <Map<String, dynamic>>[],
  };
  if (tags.isEmpty) return result;

  final uniqueEyes = <Map<String, dynamic>>[];
  final seenKillIds = <String>{};
  final seenIds = <String>{};
  for (final eye in eyes) {
    final id = '${eye['id'] ?? ''}';
    final killId = '${eye['sourceKillId'] ?? ''}';
    if (id.isNotEmpty && !seenIds.add(id)) continue;
    if (killId.isNotEmpty && !seenKillIds.add(killId)) continue;
    uniqueEyes.add(eye);
  }
  final orderedEyes = uniqueEyes..shuffle(rng);
  orderedEyes.sort(
    (a, b) => readIntValue(
      b['sourcePower'],
    ).compareTo(readIntValue(a['sourcePower'])),
  );
  if (orderedEyes.isEmpty) return result;

  final lowestStats =
      tags.map((tag) => MapEntry(tag, participantStatTotals[tag] ?? 0)).toList()
        ..sort((a, b) => a.value.compareTo(b.value));
  final weakestTotal = lowestStats.first.value;
  final weakest =
      lowestStats
          .where((entry) => entry.value == weakestTotal)
          .map((entry) => entry.key)
          .toList()
        ..shuffle(rng);
  result[weakest.first]!.add(orderedEyes.removeAt(0));

  final remainingTags = tags.toList()..shuffle(rng);
  var cursor = 0;
  for (final eye in orderedEyes) {
    result[remainingTags[cursor++ % remainingTags.length]]!.add(eye);
  }
  return result;
}

({int obser, int dust}) oculumEncounterResourcesForEnemies(
  Iterable<Map> enemies, {
  required int characterGrade,
  required int characterStats,
  int Function()? percentileRoll,
}) {
  var obser = 0, dust = 0;
  var dustCap = 3;
  var hasDefeatedEnemy = false;
  for (final enemy in enemies) {
    if (!oculumEncounterEnemyIsSummon(enemy)) hasDefeatedEnemy = true;
    final grade = readIntValue(enemy['grade']).clamp(0, 12);
    obser += max(0, readIntValue(enemy['level'])) + grade * 3;
    if (readIntValue(enemy['statsTotal']) > max(0, characterStats)) {
      final source = oculumNormalizeText(
        '${enemy['source'] ?? enemy['type'] ?? ''}',
      );
      final gap = grade - characterGrade.clamp(0, 12);
      final mini = source.contains('mini') && source.contains('boss');
      final boss = source.contains('boss') && !mini;
      final roll = gap == 1 && !mini && !boss
          ? (percentileRoll?.call() ?? Random.secure().nextInt(100))
          : 0;
      final gain = boss
          ? 5
          : mini
          ? 4
          : gap >= 2
          ? 3
          : gap == 1
          ? (roll < 10
                ? 1
                : roll < 70
                ? 2
                : 3)
          : 1;
      dustCap = max(
        dustCap,
        boss
            ? 5
            : mini
            ? 4
            : 3,
      );
      dust = min(dustCap, dust + gain);
    }
  }
  return (
    obser: obser.clamp(0, 100000000),
    dust: hasDefeatedEnemy ? max(1, dust) : dust,
  );
}

double oculumExperienceGradeMultiplier(int enemyGrade, int characterGrade) =>
    pow(
      1.2,
      max(0, enemyGrade.clamp(0, 12) - characterGrade.clamp(0, 12)),
    ).toDouble();

bool oculumEncounterEnemyIsSummon(Map enemy) {
  final source = oculumNormalizeText(
    '${enemy['source'] ?? enemy['type'] ?? ''}',
  );
  return readBoolValue(enemy['isSummon']) ||
      source.contains('summon') ||
      source.contains('evocaz');
}

Map<String, int> oculumSummonExperienceShares({
  required Map enemy,
  required Map<String, int> participantLevels,
}) {
  if (!oculumEncounterEnemyIsSummon(enemy)) return const {};
  final summonLevel = max(0, readIntValue(enemy['level']));
  final summonerTag = '${enemy['summonerTag'] ?? ''}'.trim();
  final fateAllowsExp = readBoolValue(enemy['fateAllowsExp']);
  final eligible =
      participantLevels.entries
          .where((entry) => entry.value <= summonLevel)
          .where((entry) => fateAllowsExp || entry.key != summonerTag)
          .map((entry) => entry.key)
          .where((tag) => tag.trim().isNotEmpty)
          .toList()
        ..sort();
  if (eligible.isEmpty) return const {};

  // The party receives one pool per summon, rather than 5 + Grade for every
  // participant. Divide it among eligible characters to keep that cap global.
  final basePool = 5 + readIntValue(enemy['grade']).clamp(0, 12).toInt();
  final multiplier = readIntValue(
    enemy['summonExpMultiplier'],
    fallback: 1,
  ).clamp(1, 10);
  final pool = basePool * multiplier;
  final baseShare = pool ~/ eligible.length;
  final remainder = pool % eligible.length;
  return {
    for (var index = 0; index < eligible.length; index++)
      eligible[index]: baseShare + (index < remainder ? 1 : 0),
  };
}

String oculumExperienceGradeLabel(int grade) => const [
  '0',
  'I',
  'II',
  'III',
  'IV',
  'V',
  'VI',
  'VII',
  'VIII',
  'IX',
  'X',
  'XI',
  'XII',
][grade.clamp(0, 12)];

int oculumEncounterExperienceForEnemies(
  Iterable<Map> enemies, {
  required int characterGrade,
  required bool rebirth,
  required String difficulty,
  String characterTag = '',
  int characterLevel = 0,
  Map<String, int> participantLevels = const {},
}) {
  var total = 0;
  final handledSummons = <String>{};
  for (final enemy in enemies) {
    if (oculumEncounterEnemyIsSummon(enemy)) {
      final summonId =
          '${enemy['summonInstanceId'] ?? enemy['id'] ?? enemy['name'] ?? ''}';
      if (summonId.isNotEmpty && !handledSummons.add(summonId)) continue;
      final shares = oculumSummonExperienceShares(
        enemy: enemy,
        participantLevels: participantLevels.isEmpty
            ? {if (characterTag.isNotEmpty) characterTag: characterLevel}
            : participantLevels,
      );
      total +=
          shares[characterTag] ??
          (participantLevels.isEmpty && characterTag.isEmpty
              ? shares.values.firstOrNull ?? 0
              : 0);
      continue;
    }
    final base =
        max(0, readIntValue(enemy['level'])) +
        max(0, readIntValue(enemy['statsTotal']));
    if (base == 0) continue;
    final grade = readIntValue(enemy['grade']).clamp(0, 12);
    final type = oculumNormalizeText(
      '${enemy['source'] ?? enemy['type'] ?? ''}',
    );
    final source = type.contains('mini') && type.contains('boss')
        ? 'miniboss'
        : type.contains('boss')
        ? 'boss'
        : 'normale';
    total +=
        ((('${enemy['monsterBookId'] ?? ''}'.startsWith('martire_mortale'))
                    ? .5
                    : 1) *
                (base *
                        oculumEnemyExpMultiplier(
                          source: source,
                          difficulty: difficulty,
                        ) *
                        oculumExperienceGradeMultiplier(grade, characterGrade) +
                    oculumGradeExperienceBonus(
                      enemyGrade: grade,
                      rebirth: rebirth,
                      difficulty: difficulty,
                    )))
            .round();
  }
  return total.clamp(0, 100000000);
}

({int bonus, Map<String, dynamic> history}) oculumFirstDefeatExperience(
  Iterable<Map> enemies,
  Map previous,
) {
  final history = <String, dynamic>{
    for (final entry in previous.entries) '${entry.key}': entry.value,
  };
  var bonus = 0;
  for (final enemy in enemies) {
    if (oculumEncounterEnemyIsSummon(enemy)) continue;
    final book = '${enemy['monsterBookId'] ?? ''}'.trim();
    final family = '${enemy['experienceFamilyId'] ?? ''}'.trim();
    final key = family.isNotEmpty
        ? family
        : book.isNotEmpty
        ? book.replaceFirst(RegExp(r'_variante_[a-z]+$'), '')
        : oculumNormalizeText('${enemy['name'] ?? ''}');
    if (key.isEmpty) continue;
    final grade = readIntValue(enemy['grade']).clamp(0, 12);
    final variant = jsonEncode([
      book.isEmpty ? oculumNormalizeText('${enemy['name'] ?? ''}') : book,
      oculumNormalizeElementId('${enemy['element'] ?? ''}'),
      grade,
    ]);
    final old = history[key];
    final record = old is Map
        ? Map<String, dynamic>.from(old)
        : <String, dynamic>{};
    final seen = (record['variants'] as List? ?? []).map((v) => '$v').toSet();
    final exp = max(0, readIntValue(enemy['experienceReward']));
    if (old == null) {
      bonus += (exp / 2).ceil();
    } else if (!seen.contains(variant) &&
        grade >= readIntValue(record['highestGrade'])) {
      bonus += (exp / 4).floor();
    }
    seen.add(variant);
    record['variants'] = seen.toList();
    record['highestGrade'] = max(grade, readIntValue(record['highestGrade']));
    history[key] = record;
  }
  return (bonus: bonus, history: history);
}

extension _OculumEncounterRewards on _OculumHomePageState {
  int currentEncounterRewardTotalPower() {
    final disabled = <InventoryItem>[];
    try {
      for (final item in inventario) {
        if (item.equipaggiata && item.craftData['titleItem'] != true) {
          item.equipaggiata = false;
          disabled.add(item);
        }
      }
      invalidateDerivedDataCaches(notifyHiddenEyeCards: false);
      return (resilienzaTotale() +
              volontaTotale() +
              materiaTotale() +
              oculumTotale() +
              max(0, leggiNumero(livelloController)) +
              3 * max(0, leggiNumero(gradoController)) +
              oculumHpTotalPowerBonusForGrade(
                leggiNumero(gradoController),
                level: leggiNumero(livelloController),
              ))
          .toInt();
    } finally {
      for (final item in disabled) {
        item.equipaggiata = true;
      }
      invalidateDerivedDataCaches(notifyHiddenEyeCards: false);
    }
  }

  void receiveEncounterRewards(Iterable<Map> rewards) {
    for (final reward in rewards) {
      receiveScostuFightSettlements(reward);
      resolveCorruptionFightEnd('${reward['endedEncounterId'] ?? ''}');
      for (final pawn in pawnGuardians.where(
        (p) => (reward['participants'] as List? ?? []).contains(p.ownerTag),
      )) {
        pawn.finishPosteaFight(
          '${reward['id'] ?? ''}',
          won: reward['won'] == true,
        );
        updatePawnInitiativeToken(pawn);
      }
      final id = '${reward['id'] ?? ''}';
      final newMethod =
          reward['rewardMethod'] == oculumEncounterRewardMethodDifference;
      final legacyAmount = readIntValue(reward['amount']).clamp(0, 100000000);
      final rawDefeated = reward['defeated'];
      final defeated = rawDefeated is List
          ? rawDefeated.whereType<Map>().toList()
          : <Map>[];
      final closesWholeFight = '${reward['endedEncounterId'] ?? ''}'.isNotEmpty;
      if (id.isEmpty ||
          !newMethod &&
              legacyAmount <= 0 &&
              defeated.isEmpty &&
              !closesWholeFight) {
        continue;
      }
      var importedFallenEye = false;
      final rawEyes = reward['fallenEyesByParticipant'];
      if (rawEyes is Map) {
        final seenIds = occhiCaduti
            .map((eye) => '${eye['id'] ?? ''}')
            .where((eyeId) => eyeId.isNotEmpty)
            .toSet();
        final seenKills = occhiCaduti
            .map((eye) => '${eye['sourceKillId'] ?? ''}')
            .where((killId) => killId.isNotEmpty)
            .toSet();
        for (final rawForParticipant in rawEyes.values) {
          if (rawForParticipant is! List) continue;
          for (final rawEye in rawForParticipant.whereType<Map>()) {
            final eye = Map<String, dynamic>.from(rawEye);
            final eyeId = '${eye['id'] ?? ''}';
            final sourceKillId = '${eye['sourceKillId'] ?? ''}';
            if (eyeId.isEmpty ||
                seenIds.contains(eyeId) ||
                sourceKillId.isNotEmpty && seenKills.contains(sourceKillId)) {
              continue;
            }
            eye['ownerSheetId'] = '${eye['ownerSheetId'] ?? ''}';
            occhiCaduti.add(eye);
            seenIds.add(eyeId);
            if (sourceKillId.isNotEmpty) seenKills.add(sourceKillId);
            importedFallenEye = true;
          }
        }
      }
      if (importedFallenEye) _touchFallenEyes();
      for (var i = 0; i < schedePersonaggio.length; i++) {
        if (schedePersonaggio[i]['realtimeSharedSheet'] == true) continue;
        final tag = sheetTagAt(i);
        if (!(reward['participants'] as List? ?? []).contains(tag)) continue;
        final key = 'reward:$id:$tag';
        if (onlineCombatRequests.containsKey(key)) continue;
        if ((schedePersonaggio[i]['claimedEncounterRewardIds'] as List? ?? [])
            .contains(key)) {
          continue;
        }
        final escapeAmounts = reward['escapeExperience'] as Map?;
        final amount = newMethod
            ? readIntValue(
                (reward['experienceByParticipant'] as Map?)?[tag],
              ).clamp(0, 100000000)
            : escapeAmounts != null
            ? readIntValue(escapeAmounts[tag])
            : defeated.isEmpty
            ? legacyAmount
            : oculumEncounterExperienceForEnemies(
                defeated,
                characterGrade: i == schedaCorrente
                    ? leggiNumero(gradoController)
                    : sheetIntValueAt(i, 'grado'),
                rebirth: i == schedaCorrente
                    ? rebirthato
                    : readBoolValue(schedePersonaggio[i]['rebirthato']),
                difficulty: normalizedCampaignDifficulty(),
                characterTag: tag,
                characterLevel: i == schedaCorrente
                    ? leggiNumero(livelloController)
                    : sheetIntValueAt(i, 'livello'),
                participantLevels: {
                  for (final entry
                      in (reward['participantLevels'] as Map? ?? {}).entries)
                    '${entry.key}': readIntValue(entry.value),
                },
              );
        final stats = i == schedaCorrente
            ? leggiNumero(resilienzaController) +
                  leggiNumero(volontaController) +
                  leggiNumero(materiaController) +
                  leggiNumero(oculumController)
            : ['resilienza', 'volonta', 'materia', 'oculum'].fold<int>(
                0,
                (sum, stat) => sum + max(0, sheetIntValueAt(i, stat)),
              );
        final resources = oculumEncounterResourcesForEnemies(
          defeated,
          characterGrade: i == schedaCorrente
              ? leggiNumero(gradoController)
              : sheetIntValueAt(i, 'grado'),
          characterStats: stats,
        );
        final participantLoot =
            ((reward['lootByParticipant'] as Map?)?[tag] as List? ?? []);
        if (!newMethod &&
            !closesWholeFight &&
            amount <= 0 &&
            resources.obser == 0 &&
            resources.dust == 0 &&
            participantLoot.isEmpty) {
          continue;
        }
        onlineCombatRequests.putIfAbsent(
          key,
          () => {
            'id': key,
            'kind': 'encounter_reward',
            'status': 'queued',
            'targetTag': tag,
            'endedEncounterId': reward['endedEncounterId'],
            if (newMethod) ...{
              'rewardMethod': oculumEncounterRewardMethodDifference,
              'subtraitFightInstanceId':
                  (reward['subtraitFightInstanceIds'] as Map?)?[tag] ??
                  reward['subtraitFightInstanceId'],
              'subtraitExperienceMultiplier':
                  (reward['subtraitMultipliersByParticipant'] as Map?)?[tag] ??
                  1.3,
              'commonExperience':
                  (reward['commonExperienceByParticipant'] as Map?)?[tag] ?? 0,
              'finishingExperience':
                  (reward['finishingExperienceByParticipant'] as Map?)?[tag] ??
                  0,
              'assistanceExperience':
                  (reward['assistanceExperienceByParticipant'] as Map?)?[tag] ??
                  0,
              'finishingObser':
                  (reward['finishingObserByParticipant'] as Map?)?[tag] ?? 0,
              'eligiblePowerExpenseBonus':
                  (reward['eligiblePowerExpenseBonusByParticipant']
                      as Map?)?[tag] ==
                  true,
              'settlementHpMissing': i == schedaCorrente
                  ? max(0, maxHp() - hpCorrenti())
                  : max(
                      0,
                      sheetMaxHpForDeathAt(i) -
                          readIntValue(schedePersonaggio[i]['currentHp']),
                    ),
              'resourceExperienceEligible':
                  (reward['resourceEligibleByParticipant'] as Map?)?[tag] ==
                  true,
              'weakestVictoryBonus':
                  reward['outcome'] == 'victory' &&
                  (reward['weakestParticipantTags'] as List? ?? const [])
                      .contains(tag),
              'weakestEscapeBonus':
                  reward['outcome'] == 'escape' &&
                  (reward['weakestParticipantTags'] as List? ?? const [])
                      .contains(tag),
            },
            'participantTotalPower': readIntValue(
              (reward['participantPowers'] as Map?)?[tag],
              fallback: scoutTotalPowerAt(i),
            ),
            'participantQuestPower': readIntValue(
              (reward['participantQuestPowers'] as Map?)?[tag],
              fallback: scoutTotalPowerAt(i),
            ),
            'amount': amount,
            'discoveryEnemies': [
              for (final enemy
                  in !newMethod && escapeAmounts != null ? <Map>[] : defeated)
                {
                  ...enemy,
                  'experienceReward': newMethod
                      ? 0
                      : oculumEncounterExperienceForEnemies(
                          [enemy],
                          characterGrade: i == schedaCorrente
                              ? leggiNumero(gradoController)
                              : sheetIntValueAt(i, 'grado'),
                          rebirth: i == schedaCorrente
                              ? rebirthato
                              : readBoolValue(
                                  schedePersonaggio[i]['rebirthato'],
                                ),
                          difficulty: normalizedCampaignDifficulty(),
                          characterTag: tag,
                        ),
                },
            ],
            'obser': resources.obser,
            'dust': resources.dust,
            'items':
                ((reward['lootByParticipant'] as Map?)?[tag] as List? ?? [])
                    .whereType<Map>()
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList(),
            'enemyStatsTotal': defeated.fold<int>(
              0,
              (sum, enemy) => sum + max(0, readIntValue(enemy['statsTotal'])),
            ),
            'encounterName': reward['name'],
            'multiplier':
                !newMethod &&
                    escapeAmounts == null &&
                    reward['fateActive'] == true &&
                    (reward['fateParticipants'] == null ||
                        (reward['fateParticipants'] as List).contains(tag))
                ? ((i == schedaCorrente
                              ? chainedFateCompletedIds.length
                              : (schedePersonaggio[i]['chainedFateCompletedIds']
                                            as List? ??
                                        [])
                                    .length) >=
                          3
                      ? 3
                      : 2)
                : 1,
          },
        );
      }
    }
    claimQueuedEncounterRewards();
    programmaSalvataggio();
  }

  void claimQueuedEncounterRewards() {
    if (schedaCorrente < 0 ||
        schedaCorrente >= schedePersonaggio.length ||
        schedePersonaggio[schedaCorrente]['realtimeSharedSheet'] == true) {
      return;
    }
    final tag = sheetTagAt(schedaCorrente);
    for (final reward
        in onlineCombatRequests.values
            .where(
              (r) =>
                  r['kind'] == 'encounter_reward' &&
                  r['status'] == 'queued' &&
                  r['targetTag'] == tag,
            )
            .toList()) {
      final claimed =
          (schedePersonaggio[schedaCorrente]['claimedEncounterRewardIds']
                      as List? ??
                  [])
              .map((id) => '$id')
              .toSet();
      if (claimed.contains(reward['id'])) {
        reward['status'] = 'granted';
        continue;
      }
      reward['status'] = 'granted';
      final newMethod =
          reward['rewardMethod'] == oculumEncounterRewardMethodDifference;
      schedePersonaggio[schedaCorrente]['dustLastFightEnemyStats'] =
          readIntValue(reward['enemyStatsTotal']);
      final discovery = oculumFirstDefeatExperience(
        (reward['discoveryEnemies'] as List? ?? []).whereType<Map>(),
        schedePersonaggio[schedaCorrente]['firstDefeatExperienceHistory']
                as Map? ??
            {},
      );
      schedePersonaggio[schedaCorrente]['firstDefeatExperienceHistory'] =
          discovery.history;
      final resourcesSpent =
          newMethod &&
              (reward['resourceExperienceEligible'] == true ||
                  reward['eligiblePowerExpenseBonus'] == true)
          ? combatResourceExperienceSnapshot(
              encounterId: '${reward['endedEncounterId'] ?? ''}',
              fightInstanceId: '${reward['subtraitFightInstanceId'] ?? ''}',
            )
          : const <String, int>{};
      final resourceExperience = reward['resourceExperienceEligible'] == true
          ? oculumEncounterResourceExperience(
              oculumSpent: resourcesSpent['oculumSpent'] ?? 0,
              hpLost: resourcesSpent['hpLost'] ?? 0,
            )
          : 0;
      final expenseExperience =
          newMethod && reward['eligiblePowerExpenseBonus'] == true
          ? max(0, readIntValue(resourcesSpent['statsSpent']))
          : 0;
      final missingHpExperience =
          newMethod && reward['eligiblePowerExpenseBonus'] == true
          ? max(0, readIntValue(reward['settlementHpMissing'])) ~/ 10
          : 0;
      final beforeWeakest =
          (readIntValue(reward['amount']) + (newMethod ? 0 : discovery.bonus)) *
              (newMethod
                  ? 1
                  : readIntValue(reward['multiplier'], fallback: 1)) +
          resourceExperience +
          expenseExperience +
          missingHpExperience;
      final weakestBonus = newMethod && reward['weakestVictoryBonus'] == true
          ? beforeWeakest ~/ 5
          : 0;
      final amount = beforeWeakest + weakestBonus;
      reward['resourceExperience'] = resourceExperience;
      reward['expenseExperience'] = expenseExperience;
      reward['missingHpExperience'] = missingHpExperience;
      reward['weakestExperienceBonus'] = weakestBonus;
      reward['awardedExperience'] = amount;
      recordPersonalProgressionKills(
        (reward['discoveryEnemies'] as List? ?? []).whereType<Map>(),
        '${reward['id']}',
        ownerPower: readIntValue(
          reward['participantQuestPower'],
          fallback: scoutTotalPowerAt(schedaCorrente),
        ),
      );
      final message = applicaEsperienzaFlat(
        amount,
        motivo: 'Fine scontro ${reward['encounterName'] ?? ''}',
        applyChainedFate: false,
        progressionReceiptId: '${reward['id']}',
      );
      aggiungiLog(message);
      if (!newMethod && discovery.bonus > 0) {
        aggiungiLog(
          '[PRIMA SCONFITTA / VARIANTE] +${discovery.bonus} EXP prima del moltiplicatore del Fato.',
        );
      }
      final obser =
          (readIntValue(reward['obser']) +
                  (newMethod ? readIntValue(reward['finishingObser']) : 0))
              .clamp(0, 100000000);
      final dust = readIntValue(reward['dust']).clamp(0, 5);
      final awardedDust = min(
        dust,
        max(0, 3 - readIntValue(planarState['ascensionDustFightWindowEarned'])),
      );
      planarState['ascensionDustFightWindowEarned'] =
          readIntValue(planarState['ascensionDustFightWindowEarned']) +
          awardedDust;
      advanceOwnedItemTitles(
        (reward['discoveryEnemies'] as List? ?? []).whereType<Map>(),
        '${reward['id']}',
      );
      final items = (reward['items'] as List? ?? [])
          .whereType<Map>()
          .map(
            (item) => InventoryItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      if (items.isNotEmpty) {
        if (schedaCorrente >= 0 && schedaCorrente < schedePersonaggio.length) {
          final current = schedePersonaggio[schedaCorrente];
          if (current['realtimeSharedSheet'] == true) {
            final rawInventory = List<dynamic>.from(
              current['inventario'] as List? ?? const [],
            );
            rawInventory.addAll(items.map((item) => item.toJson()));
            current['inventario'] = rawInventory;
          } else {
            inventario.addAll(items);
          }
        }
      }
      obserController.text = '${max(0, leggiNumero(obserController)) + obser}';
      ascensionDustController.text =
          '${max(0, leggiNumero(ascensionDustController)) + awardedDust}';
      claimed.add('${reward['id']}');
      schedePersonaggio[schedaCorrente]['claimedEncounterRewardIds'] = claimed
          .toList();
      if ('${reward['endedEncounterId'] ?? ''}'.isNotEmpty) {
        completeOpenLifecycleFight('${reward['id']}');
      }
      if (obser > 0 || awardedDust > 0) {
        aggiungiLog(
          '[DROP FINE SCONTRO] +$obser Obser · +$awardedDust Ascension Dust (massimo 3 prima di riposare o aprire il mercante).',
        );
      }
      if (newMethod) {
        final multiplierRaw = reward['subtraitExperienceMultiplier'];
        final multiplier = multiplierRaw is num
            ? multiplierRaw.toDouble()
            : double.tryParse('$multiplierRaw') ?? 1.3;
        final bonuses = grantCombatSubtraitExperienceBonus(
          settlementId: '${reward['id']}',
          encounterId: '${reward['endedEncounterId'] ?? ''}',
          fightInstanceId: '${reward['subtraitFightInstanceId'] ?? ''}',
          multiplier: multiplier,
          escapeBonusTraits: reward['weakestEscapeBonus'] == true
              ? combatEscapeSubtraitsSnapshot(
                  encounterId: '${reward['endedEncounterId'] ?? ''}',
                  fightInstanceId: '${reward['subtraitFightInstanceId'] ?? ''}',
                )
              : const <String>{},
        );
        if (bonuses.isNotEmpty) {
          aggiungiLog(
            '[EXP SOTTOTRATTI FINE FIGHT] ×${multiplier.toStringAsFixed(1)} sul guadagno effettivo: '
            '${bonuses.entries.map((e) => '${e.key} +${e.value} EXP').join(', ')}.',
          );
        }
      }
      if (items.isNotEmpty) {
        aggiungiLog(
          '[DROP PARTY] ${items.map((item) => item.nome).join(', ')} assegnato a ${nomeSchedaPersonaggio(schedaCorrente)}.',
        );
      }
    }
  }

  void collectObserverTearCurrency(Map enemy, String cooldownFightId) {
    if (const {
          'observers_tear',
          'obser_sunshine',
        }.contains('${enemy['monsterBookId']}') &&
        !oculumEncounterEnemyIsSummon(enemy)) {
      final receipts = (partyChest['observerTearLootReceipts'] as List? ?? [])
          .map((e) => '$e')
          .toSet();
      final receipt = '$cooldownFightId:${enemy['id']}';
      if (receipts.add(receipt)) {
        final sourceIndex = localSheetIndexForOculumTag(
          '${enemy['monsterSheetTag'] ?? ''}',
        );
        final remaining = sourceIndex < 0
            ? 0
            : max(
                0,
                sourceIndex == schedaCorrente
                    ? leggiNumero(obserController)
                    : sheetIntValueAt(sourceIndex, 'obser'),
              );
        if (sourceIndex >= 0) {
          schedePersonaggio[sourceIndex]['obser'] = '0';
          if (sourceIndex == schedaCorrente) obserController.text = '0';
        }
        partyChest['observerTearLootReceipts'] = receipts.toList();
        partyChest['obser'] =
            max(0, readIntValue(partyChest['obser'])) + remaining;
        partyChest['revision'] = readIntValue(partyChest['revision']) + 1;
        aggiungiLog(
          '[DROP] ${enemy['name']}: +$remaining Obser non spesi nella cassa comune.',
        );
        unawaited(sendPartyChestState());
      }
    }
  }

  Future<void> finishEncounter(
    String id, {
    Random? random,
    bool automatic = false,
  }) async {
    if (realtimeService?.isConnected == true && !realtimeIsMasterRole) return;
    final inFlight = _oculumEncounterSettlementInFlight[this] ??= <String>{};
    if (!inFlight.add(id)) return;
    try {
      await finishEncounterSettlement(id, random: random, automatic: automatic);
    } finally {
      inFlight.remove(id);
    }
  }

  Future<void> finishEncounterSettlement(
    String id, {
    Random? random,
    bool automatic = false,
  }) async {
    selectMasterInitiativeGroup(id);
    captureActiveMasterInitiativeGroup();
    final group = masterInitiativeGroups
        .where((g) => g['id'] == id)
        .firstOrNull;
    if (group == null ||
        masterInitiativeTokens.isEmpty ||
        group['combatEnded'] == true) {
      return;
    }
    final fightInstanceId =
        '${group['rewardFightInstanceId'] ?? masterInitiativeTokens.map((t) => t['fightInstanceId']).whereType<String>().where((s) => s.isNotEmpty).firstOrNull ?? fightRewardInstanceId(group, masterInitiativeTokens.first)}';
    final settlementId =
        '${group['pendingRewardSettlementId'] ?? oculumEncounterSettlementId(id, fightInstanceId)}';
    if ((group['settlementReceiptIds'] as List? ?? const []).contains(
          settlementId,
        ) ||
        (group['rewards'] as List? ?? const []).whereType<Map>().any(
          (r) => r['id'] == settlementId,
        )) {
      return;
    }
    group['rewardFightInstanceId'] = fightInstanceId;
    final currentTag = sheetTagAt(schedaCorrente);
    if (masterInitiativeTokens.any(
      (t) =>
          combatTokenMatchesSheet(t, currentTag) && t['outsideFight'] != true,
    )) {
      recordFightRewardPowerSample(
        currentTag,
        currentEncounterRewardTotalPower(),
        encounterId: id,
      );
    }
    for (final token in masterInitiativeTokens) {
      if (token['outsideFight'] != true) sampleFightRewardPowerToken(token);
    }
    final tokens = masterInitiativeTokens
        .map((t) => Map<String, dynamic>.from(t))
        .toList();
    final tokenFingerprint = jsonEncode(tokens);
    String outcomeFingerprint(Iterable<Map> entries) => jsonEncode([
      for (final token in entries)
        [
          token['id'],
          token['sheetTag'],
          token['side'],
          token['status'],
          token['fightInstanceId'],
        ],
    ]);
    final settledOutcomeFingerprint = outcomeFingerprint(tokens);
    final capturedRound = masterInitiativeRound;
    var rewardMethod = oculumEncounterRewardMethod(
      group['rewardAssignmentMethod'],
    );
    final partyAlive = tokens.any(
      (t) =>
          t['side'] != 'enemy' &&
          !const {'dead', 'fled', 'expired'}.contains('${t['status']}'),
    );
    final partyEscaped =
        !partyAlive &&
        tokens.any((t) => t['side'] != 'enemy' && t['status'] == 'fled');
    final enemiesResolved = !tokens.any(
      (t) =>
          t['side'] == 'enemy' &&
          !const {'dead', 'fled', 'expired'}.contains('${t['status']}'),
    );
    var outcome =
        '${group['rewardOutcome'] ?? (partyEscaped
                ? 'escape'
                : partyAlive && enemiesResolved
                ? 'victory'
                : 'defeat')}';
    if (!const {'victory', 'escape', 'defeat'}.contains(outcome)) {
      outcome = partyEscaped
          ? 'escape'
          : partyAlive && enemiesResolved
          ? 'victory'
          : 'defeat';
    }
    final preexistingDead =
        (group['rewardPreexistingDeadTokenIds'] as List? ?? const [])
            .map((e) => '$e')
            .toSet();
    var amount = 0;
    final defeated = <Map<String, dynamic>>[];
    final participants = <String>{};
    final countedEnemies = <String>{};
    for (final token in tokens) {
      if (masterInitiativeTokenIsTemporary(token)) continue;
      if (token['encounterObject'] == true) continue;
      if (token['side'] != 'enemy') {
        participants.add(publicInitiativeSourceTag(token));
        continue;
      }
      final corruptionIndex = localSheetIndexForOculumTag(
        publicInitiativeSourceTag(token),
      );
      if (!oculumEncounterEnemyKilled(token) &&
          !corruptionSuicideDueAt(corruptionIndex, id)) {
        continue;
      }
      if (preexistingDead.contains('${token['id']}') &&
          token['rewardDeathFightInstanceId'] != fightInstanceId) {
        continue;
      }
      final enemyTag = publicInitiativeSourceTag(token);
      if (enemyTag.isNotEmpty && !countedEnemies.add(enemyTag)) continue;
      final index = localSheetIndexForOculumTag(
        '${token['sheetTag'] ?? token['id']}',
      );
      final level = max(
        0,
        index >= 0
            ? sheetIntValueAt(index, 'livello')
            : readIntValue(token['level']),
      );
      final sourceSheet = index >= 0
          ? schedePersonaggio[index]
          : token['rewardPermanentCoreStats'] is Map
          ? {
              ...token,
              ...Map<String, dynamic>.from(
                token['rewardPermanentCoreStats'] as Map,
              ),
            }
          : token;
      final explicitCores = oculumEncounterHasKnownCoreStats(sourceSheet);
      final permanentCores = oculumEncounterPermanentCoreStats(sourceSheet);
      final manualTotal =
          index < 0 &&
          token['manualLevelGradeOverride'] == true &&
          (token['statsTotal'] is num ||
              int.tryParse('${token['statsTotal']}') != null);
      final permanentStatsTotal = explicitCores && !manualTotal
          ? permanentCores.values.fold<int>(0, (a, b) => a + b)
          : max(0, readIntValue(token['statsTotal']));
      final statsTotal = index >= 0
          ? const ['resilienza', 'volonta', 'materia', 'oculum'].fold<int>(
              0,
              (sum, stat) => sum + max(0, sheetIntValueAt(index, stat)),
            )
          : max(
              0,
              readIntValue(token['statsTotal'], fallback: permanentStatsTotal),
            );
      amount += level + statsTotal;
      final monsterSource = index >= 0
          ? monsterLootSourceForSheet(schedePersonaggio[index])
          : null;
      defeated.add({
        'id': token['id'],
        'sheetTag': enemyTag,
        'lastAttackId':
            token['rewardFinalAttackId'] ?? token['rewardLastDamageRequestId'],
        'deathRound': readIntValue(
          token['rewardDeathRound'],
          fallback: readIntValue(
            token['rewardLastDamageRound'],
            fallback: capturedRound,
          ),
        ),
        'name': token['name'],
        'monsterBookId': monsterSource?.id ?? '${token['monsterBookId'] ?? ''}',
        'element': monsterSource?.elementId ?? '${token['element'] ?? ''}',
        if (index >= 0 &&
            '${schedePersonaggio[index]['experienceFamilyId'] ?? ''}'
                .trim()
                .isNotEmpty)
          'experienceFamilyId': schedePersonaggio[index]['experienceFamilyId'],
        'monsterSheetTag': index >= 0 ? sheetTagAt(index) : '',
        'canonicalNpc': index >= 0
            ? '${(schedePersonaggio[index]['planarRuntime'] as Map?)?['canonicalNpc'] ?? ''}'
            : '${token['canonicalNpc'] ?? ''}',
        'level': level,
        'killerTag': oculumEncounterFinalKillerTag(
          token,
          sheet: index >= 0 ? schedePersonaggio[index] : null,
        ),
        'titleItemIds': index >= 0
            ? schedePersonaggio[index]['lastDamageTitleItemIds'] ?? const []
            : token['lastDamageTitleItemIds'] ?? const [],
        'totalPower': index >= 0
            ? readIntValue(
                (schedePersonaggio[index]['lastDamagePowerRecord']
                    as Map?)?['totalPower'],
                fallback: scoutTotalPowerAt(index),
              )
            : readIntValue(
                token['totalPower'],
                fallback:
                    permanentStatsTotal +
                    level +
                    3 * readIntValue(token['grade']).clamp(0, 12).toInt() +
                    oculumHpTotalPowerBonusForGrade(
                      readIntValue(token['grade']),
                      level: level,
                    ),
              ),
        'killerTotalPower': index >= 0
            ? readIntValue(
                (schedePersonaggio[index]['lastDamagePowerRecord']
                    as Map?)?['killerTotalPower'],
                fallback: -1,
              )
            : readIntValue(token['killerTotalPower'], fallback: -1),
        'finisher': index >= 0
            ? schedePersonaggio[index]['lastPlanarFinisher'] ??
                  token['lastPlanarFinisher']
            : token['lastPlanarFinisher'],
        'statsTotal': statsTotal,
        'permanentStatsTotal': permanentStatsTotal,
        'rewardAverageTotalPower': oculumFightRewardAverageTotalPower(
          token,
          fallback: index == schedaCorrente
              ? currentEncounterRewardTotalPower()
              : oculumEncounterInstantRewardTotalPower(sourceSheet),
        ),
        'confirmedMonster': index >= 0
            ? (tipoSchedaPersonaggio(index).toLowerCase().contains('mostro') ||
                  tipoSchedaPersonaggio(index).toLowerCase().contains('boss'))
            : monsterSource != null ||
                  '${token['type'] ?? ''}'.toLowerCase().contains('mostro') ||
                  '${token['type'] ?? ''}'.toLowerCase().contains('boss'),
        'permanentStatsKnown':
            explicitCores ||
            token['statsTotal'] is num ||
            int.tryParse('${token['statsTotal']}') != null,
        'grade':
            (index >= 0
                    ? sheetIntValueAt(index, 'grado')
                    : readIntValue(token['grade']))
                .clamp(0, 12),
        'isSummon': oculumEncounterEnemyIsSummon(token),
        if (oculumEncounterEnemyIsSummon(token)) ...{
          'summonInstanceId': '${token['summonInstanceId'] ?? token['id']}',
          'summonerTag': '${token['summonerTag'] ?? ''}',
          'fateAllowsExp': readBoolValue(token['fateAllowsExp']),
          'summonExpMultiplier': readIntValue(
            token['summonExpMultiplier'],
            fallback: 1,
          ).clamp(1, 10),
        },
        'source': index >= 0
            ? tipoSchedaPersonaggio(index)
            : '${token['type'] ?? 'Mostro'}',
      });
    }
    final unknownStats = defeated
        .where((enemy) => enemy['permanentStatsKnown'] != true)
        .toList();
    if (automatic &&
        rewardMethod == oculumEncounterRewardMethodDifference &&
        unknownStats.isNotEmpty) {
      aggiungiLog(
        '[FINE SCONTRO] Premi in attesa: completa le statistiche permanenti di ${unknownStats.map((e) => e['name']).join(', ')} da Livello e Grado, oppure scegli il metodo precedente.',
      );
      return;
    }
    final ok = automatic
        ? true
        : await showDialog<bool>(
            context: context,
            builder: (dialog) => StatefulBuilder(
              builder: (dialog, updateDialog) => AlertDialog(
                title: const Text('Termina scontro'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: rewardMethod,
                        decoration: const InputDecoration(
                          labelText: 'Assegnazione EXP',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: oculumEncounterRewardMethodDifference,
                            child: Text('Differenza PT media'),
                          ),
                          DropdownMenuItem(
                            value: oculumEncounterRewardMethodLegacy,
                            child: Text('Metodo precedente'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            updateDialog(() => rewardMethod = value);
                          }
                        },
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: outcome,
                        decoration: const InputDecoration(
                          labelText: 'Esito del party',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'victory',
                            child: Text('Vittoria'),
                          ),
                          DropdownMenuItem(
                            value: 'escape',
                            child: Text('Fuga del party'),
                          ),
                          DropdownMenuItem(
                            value: 'defeat',
                            child: Text('Sconfitta'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            updateDialog(() => outcome = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (rewardMethod ==
                              oculumEncounterRewardMethodDifference &&
                          unknownStats.isNotEmpty)
                        Text(
                          'Statistiche permanenti mancanti: ${unknownStats.map((e) => e['name']).join(', ')}. Completa i quattro valori o il totale da Livello e Grado, oppure seleziona il metodo precedente.',
                        ),
                      Text(
                        '${defeated.length} nemici sconfitti. '
                        '${rewardMethod == oculumEncounterRewardMethodDifference ? 'La PT media usa il massimo di ogni turno personale, escludendo equipaggiamento non Titolo Item e maschera di Senka. Si sommano le medie dei nemici morti, con Grado +20% per differenza, e si sottrae una volta la propria media. Reazioni e Reazioni veloci non creano turni aggiuntivi. I bonus personali si assegnano soltanto ora.' : '$amount EXP base. Il metodo precedente conserva categoria, difficoltà, prime sconfitte e Fato.'} I Drop dei mostri uccisi presenti '
                        'in turnistica vengono tirati e distribuiti ora. Party e NPC alleati restano sulla board; i nemici vengono rimossi. La '
                        'condivisione chiusa. Gli scontri uniti tornano separati.\n\n'
                        '${defeated.map((enemy) => '${enemy['name'] ?? 'Nemico'} · '
                            '${enemy['source']} · Grado ${oculumExperienceGradeLabel(readIntValue(enemy['grade']))} · '
                            '${rewardMethod == oculumEncounterRewardMethodDifference ? 'PT media ${readIntValue(enemy['rewardAverageTotalPower'])}' : '${readIntValue(enemy['level']) + readIntValue(enemy['statsTotal'])} EXP base'}').join('\n')}',
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: const Text('Annulla'),
                  ),
                  FilledButton(
                    onPressed:
                        rewardMethod == oculumEncounterRewardMethodDifference &&
                            unknownStats.isNotEmpty
                        ? null
                        : () => Navigator.pop(dialog, true),
                    child: const Text('Termina, tira i Drop e assegna EXP'),
                  ),
                ],
              ),
            ),
          );
    if (!mounted || ok != true) return;
    // A second client, an escape or a board edit may have changed the fight
    // while the confirmation was open. Do not settle a stale snapshot.
    if (!masterInitiativeGroups.contains(group) ||
        group['combatEnded'] == true) {
      return;
    }
    selectMasterInitiativeGroup(id);
    if (jsonEncode(masterInitiativeTokens) != tokenFingerprint) {
      aggiungiLog(
        '[FINE SCONTRO] La turnistica è cambiata: riapri la conferma per assegnare i premi aggiornati.',
      );
      return;
    }
    group['rewardAssignmentMethod'] = rewardMethod;
    group['rewardOutcome'] = outcome;
    group['pendingRewardSettlementId'] = settlementId;
    final partyTags = participants.toList()..sort();
    final participantFightIds = <String, String>{
      for (final tag in partyTags)
        tag: combatSubtraitExperienceFightId(id, ownerTag: tag),
    };
    final profiles = <String, Map<String, dynamic>>{};
    for (final tag in partyTags) {
      final index = localSheetIndexForOculumTag(tag);
      if (index >= 0) {
        final data = Map<String, dynamic>.from(schedePersonaggio[index]);
        if (oculumEncounterHasKnownRewardPower(data)) {
          profiles[tag] = data;
        }
      } else {
        final token = tokens
            .where(
              (t) => oculumSameSheetIdentity(publicInitiativeSourceTag(t), tag),
            )
            .firstOrNull;
        if (token != null) {
          final data = token['rewardPermanentCoreStats'] is Map
              ? {
                  ...token,
                  ...Map<String, dynamic>.from(
                    token['rewardPermanentCoreStats'] as Map,
                  ),
                }
              : token;
          if (oculumEncounterHasKnownRewardPower(data)) profiles[tag] = data;
        }
      }
    }
    // Quest eligibility retains its canonical sheet power. The new average
    // and ordinary-equipment exclusion are reward rules, not unlock rules.
    final questPowers = <String, int>{
      for (final entry in profiles.entries)
        entry.key: localSheetIndexForOculumTag(entry.key) >= 0
            ? scoutTotalPowerAt(localSheetIndexForOculumTag(entry.key))
            : readIntValue(
                entry.value['totalPower'],
                fallback: oculumEncounterPermanentTotalPower(entry.value),
              ),
    };
    final permanentPowers = <String, int>{
      for (final entry in profiles.entries)
        entry.key: oculumFightRewardAverageTotalPower(
          tokens.firstWhere(
            (t) => oculumSameSheetIdentity(
              publicInitiativeSourceTag(t),
              entry.key,
            ),
          ),
          fallback: localSheetIndexForOculumTag(entry.key) == schedaCorrente
              ? currentEncounterRewardTotalPower()
              : oculumEncounterInstantRewardTotalPower(entry.value),
        ),
    };
    for (final enemy in defeated) {
      final killer = '${enemy['killerTag'] ?? ''}';
      if (permanentPowers.containsKey(killer)) {
        enemy['killerAverageTotalPower'] = permanentPowers[killer];
      }
    }
    final realPartyPowers = <String, int>{
      for (final token in tokens)
        if (token['side'] != 'enemy' &&
            !oculumEncounterEnemyIsSummon(token) &&
            !masterInitiativeTokenIsTemporary(token) &&
            permanentPowers.containsKey(publicInitiativeSourceTag(token)))
          publicInitiativeSourceTag(token):
              permanentPowers[publicInitiativeSourceTag(token)]!,
    };
    final weakest = oculumEncounterWeakestParticipants(realPartyPowers);
    final supportHistory = prepareEncounterRewardSupportHistory(
      defeated,
      (group['rewardSupportHistory'] as List? ?? const []).whereType<Map>(),
    );
    final commonExperience = <String, int>{};
    final finishingExperience = <String, int>{};
    final assistanceExperience = <String, int>{};
    final experience = <String, int>{};
    final resourceEligible = <String, bool>{};
    final eligiblePowerExpenseBonus = <String, bool>{};
    final finishingObser = <String, int>{};
    final subtraitMultipliers = <String, double>{};
    final participantLevels = <String, int>{
      for (final tag in partyTags)
        tag: max(
          0,
          readIntValue(profiles[tag]?['livello'] ?? profiles[tag]?['level']),
        ),
    };
    for (final tag in partyTags) {
      final profile = profiles[tag];
      if (profile == null) continue;
      final stats = oculumEncounterPermanentCoreStats(
        profile,
      ).values.fold<int>(0, (a, b) => a + b);
      final grade = readIntValue(profile['grado'] ?? profile['grade']);
      final level = participantLevels[tag]!;
      commonExperience[tag] =
          oculumEncounterDifferenceExperience(
            defeated.where((enemy) => !oculumEncounterEnemyIsSummon(enemy)),
            characterStats: stats,
            characterLevel: level,
            characterGrade: grade,
            characterAverageTotalPower: permanentPowers[tag],
          ) +
          defeated
              .where(oculumEncounterEnemyIsSummon)
              .fold<int>(
                0,
                (sum, enemy) =>
                    sum +
                    (oculumSummonExperienceShares(
                          enemy: enemy,
                          participantLevels: participantLevels,
                        )[tag] ??
                        0),
              );
      finishingExperience[tag] = oculumEncounterFinishingExperience(
        defeated.where((enemy) => !oculumEncounterEnemyIsSummon(enemy)),
        characterTag: tag,
        characterTotalPower: permanentPowers[tag]!,
      );
      assistanceExperience[tag] = oculumEncounterAssistanceExperience(
        defeated.where((enemy) => !oculumEncounterEnemyIsSummon(enemy)),
        history: supportHistory,
        characterTag: tag,
        characterTotalPower: permanentPowers[tag]!,
        characterAverageTotalPower: permanentPowers[tag],
      );
      experience[tag] =
          commonExperience[tag]! +
          finishingExperience[tag]! +
          assistanceExperience[tag]!;
      finishingObser[tag] = oculumEncounterFinishingObser(
        defeated,
        characterTag: tag,
        characterAverageTotalPower: permanentPowers[tag]!,
      );
      eligiblePowerExpenseBonus[tag] = defeated.any(
        (e) =>
            !oculumEncounterEnemyIsSummon(e) &&
            readIntValue(e['rewardAverageTotalPower']) >=
                permanentPowers[tag]! - 25,
      );
      resourceEligible[tag] = oculumEncounterResourceExperienceEligible(
        defeated,
        characterLevel: level,
        characterGrade: grade,
      );
      subtraitMultipliers[tag] = oculumEncounterSubtraitExperienceMultiplier(
        defeated,
        history: supportHistory,
        characterTag: tag,
      );
    }
    resolveCorruptionFightEnd(id);
    final cooldownFightSequence = readIntValue(
      group['rewardSettlementSequence'],
      fallback: max(0, readIntValue(group['completedFightCount'])) + 1,
    );
    group['rewardSettlementSequence'] = cooldownFightSequence;
    group['completedFightCount'] = cooldownFightSequence;
    final cooldownFightId = settlementId;
    for (final enemy in defeated) {
      await resolveMartyrDeath(enemy, '$cooldownFightId:${enemy['id']}');
      if (!mounted ||
          !masterInitiativeGroups.contains(group) ||
          group['rewardFightInstanceId'] != fightInstanceId ||
          realtimeService?.isConnected == true && !realtimeIsMasterRole) {
        return;
      }
      selectMasterInitiativeGroup(id);
      if (outcomeFingerprint(masterInitiativeTokens) !=
          settledOutcomeFingerprint) {
        aggiungiLog(
          '[FINE SCONTRO] Partecipanti o esiti modificati durante la conferma: premi non assegnati, ripeti la chiusura aggiornata.',
        );
        return;
      }
    }
    recordAllMonsterKills(defeated, cooldownFightId);
    faunaConfirmedKills(defeated, cooldownFightId);
    recordPlanarMonsterRewards(
      defeated,
      cooldownFightId,
      participantTags: participants,
    );
    advancePartyQuestKills(defeated, cooldownFightId);
    recordPartySpeciesHunts(defeated, cooldownFightId);
    for (final tag in partyTags) {
      final index = localSheetIndexForOculumTag(tag);
      if (index < 0) continue;
      final sheet = schedePersonaggio[index];
      final planar = sheet['planarRuntime'];
      if (planar is Map) {
        for (final key in const [
          'maxPower',
          'scalesTurns',
          'flightTurns',
          'vanishTurns',
          'illusionTurns',
          'illusionCopies',
          'armorHits',
          'barrierTurns',
          'barrierPower',
          'chargePower',
          'chargeNeeded',
          'chargeSteps',
          'attackRollBonus',
          'defenseRollPenalty',
        ]) {
          planar.remove(key);
        }
      }
      final remaining = max(
        0,
        readIntValue(sheet['patalpaSummonCooldownFightsRemaining']),
      );
      if (!oculumTickPatalpaSummonCooldown(
        sheet,
        encounterId: cooldownFightId,
      )) {
        continue;
      }
      if (remaining == 1) {
        aggiungiLog(
          'Richiamo del Patalpa: cooldown terminato per ${nomeSchedaPersonaggio(index)}.',
        );
      }
    }
    if (rewardMethod == oculumEncounterRewardMethodDifference) {
      var partyPower = 0;
      for (final token in tokens.where((t) => t['side'] != 'enemy')) {
        final index = localSheetIndexForOculumTag(
          publicInitiativeSourceTag(token),
        );
        final source = index >= 0 ? schedePersonaggio[index] : token;
        final eye =
            source['occhioCaduto'] == true || token['occhioCaduto'] == true;
        final clone =
            '${token['summonKind'] ?? ''}'.contains('clone') ||
            (source['planarRuntime'] as Map?)?['doppioneCopy'] == true;
        if (clone ||
            !eye &&
                (masterInitiativeTokenIsTemporary(token) ||
                    oculumEncounterEnemyIsSummon(token) ||
                    '${token['summonKind'] ?? ''}'.isNotEmpty)) {
          continue;
        }
        partyPower += oculumFightRewardAverageTotalPower(
          token,
          fallback: index == schedaCorrente
              ? currentEncounterRewardTotalPower()
              : oculumEncounterInstantRewardTotalPower(source),
        );
      }
      final monsterPower = defeated
          .where(
            (e) =>
                e['confirmedMonster'] == true &&
                !oculumEncounterEnemyIsSummon(e),
          )
          .fold<int>(
            0,
            (sum, e) =>
                sum + max(0, readIntValue(e['rewardAverageTotalPower'])),
          );
      final size = oculumEncounterPartyCrystalSize(
        deadMonsterPower: monsterPower,
        partyPower: partyPower,
      );
      final crystalReceipts =
          (partyChest['encounterCrystalReceipts'] as List? ?? const [])
              .map((e) => '$e')
              .toSet();
      if (size != null && crystalReceipts.add(settlementId)) {
        final item = oculumDustCrystal(size, killId: settlementId);
        partyChest['pendingLoot'] = [
          ...(partyChest['pendingLoot'] as List? ?? const []),
          {'id': 'fight-crystal:$settlementId', 'item': item.toJson()},
        ];
        partyChest['encounterCrystalReceipts'] = crystalReceipts.toList();
        oculumPromotePendingChestLoot(partyChest);
        partyChest['revision'] = readIntValue(partyChest['revision']) + 1;
        aggiungiLog(
          '[CRISTALLO PARTY] Differenza PT media $monsterPower−$partyPower: Cristallo di Ascension Dust $size nella cassa, senza romperlo.',
        );
        unawaited(sendPartyChestState());
      }
    }
    final pooledLoot = <InventoryItem>[];
    final fallenEyeCandidates = <Map<String, dynamic>>[];
    final encounterRandom = random ?? Random.secure();
    final knownEyeKillIds = occhiCaduti
        .map((eye) => '${eye['sourceKillId'] ?? ''}')
        .where((killId) => killId.isNotEmpty)
        .toSet();
    final candidateEyeKillIds = <String>{};
    var rollerCursor = 0;
    for (final enemy in defeated) {
      collectObserverTearCurrency(enemy, cooldownFightId);
      final monsterId = '${enemy['monsterBookId'] ?? ''}';
      final monster = monsterId.isEmpty
          ? null
          : monsterBookEntryById(monsterId);
      if (monster == null || partyTags.isEmpty) continue;
      final rollerTag = partyTags[rollerCursor++ % partyTags.length];
      final rollerIndex = localSheetIndexForOculumTag(rollerTag);
      if (rollerIndex < 0) continue;
      final rollerSheet = schedePersonaggio[rollerIndex];
      final rawDropStats = (rollerSheet['hiddenEyeStats'] as List? ?? const [])
          .whereType<Map>()
          .where((stat) => stat['id'] == 'drop')
          .firstOrNull;
      final bonus =
          readIntValue(rawDropStats?['valore']) +
          oculumHiddenEyeDerivedBonusFor(
            id: 'drop',
            level: readIntValue(rollerSheet['livello']),
            resilienza: readIntValue(rollerSheet['resilienza']),
            volonta: readIntValue(rollerSheet['volonta']),
            materia: readIntValue(rollerSheet['materia']),
            oculum: readIntValue(rollerSheet['oculum']),
            karma: readIntValue(rollerSheet['karma']),
          );
      final natural = encounterRandom.nextInt(20) + 1;
      final level = max(0, readIntValue(enemy['level']));
      final grade = readIntValue(enemy['grade']).clamp(0, 12).toInt();
      final difficulty = oculumMonsterDropDifficulty(
        level: level,
        grade: grade,
      );
      final total = rollTotalWithCritical(natural, 20, [bonus]);
      final killId = '${enemy['id'] ?? monsterId}:$cooldownFightId';
      final dropped = oculumGenerateMonsterLoot(
        monster: monster,
        level: level,
        grade: grade,
        random: Random.secure(),
        killId: killId,
        naturalDropRoll: natural,
        dropTotal: total,
        finishingElement: '${(enemy['finisher'] as Map?)?['element'] ?? ''}',
        finishingSkillId: '${(enemy['finisher'] as Map?)?['skillId'] ?? ''}',
        combatHistory: enemy['finisher'] as Map? ?? const {},
      );
      if (enemy['canonicalNpc'] == 'lusier_iii' &&
          !oculumEncounterEnemyIsSummon(enemy)) {
        final sourceIndex = localSheetIndexForOculumTag(
          '${enemy['monsterSheetTag'] ?? ''}',
        );
        final sourceDeck = sourceIndex < 0
            ? null
            : (schedePersonaggio[sourceIndex]['inventario'] as List? ?? [])
                  .whereType<Map>()
                  .where(
                    (i) => (i['craftData'] as Map?)?['explosiveCards'] == true,
                  )
                  .firstOrNull;
        final deck = sourceDeck == null
            ? oculumExplosiveCards(lusier: true)
            : InventoryItem.fromJson(Map<String, dynamic>.from(sourceDeck));
        deck.equipaggiata = false;
        deck.craftData['namedDropKillId'] = killId;
        dropped.add(deck);
      }
      final rollerLevel = participantLevels[rollerTag] ?? 0;
      // Do not consume a percentile roll when a crystal cannot drop. Besides
      // avoiding needless RNG, this keeps deterministic Drop sequences stable
      // for subsequent defeated monsters.
      final crystalEligible =
          level >= rollerLevel + 3 && total >= 20 + level + 2 * grade;
      final crystal = crystalEligible
          ? oculumDustCrystalDrop(
              monsterLevel: level,
              monsterGrade: grade,
              rollerLevel: rollerLevel,
              dropTotal: total,
              percentile: encounterRandom.nextInt(100),
              killId: killId,
            )
          : null;
      if (crystal != null && !oculumEncounterEnemyIsSummon(enemy)) {
        dropped.add(crystal);
      }
      if (monster.id == 'pupazzo_robotico_postea') {
        final sourceIndex = localSheetIndexForOculumTag(
          '${enemy['monsterSheetTag'] ?? ''}',
        );
        if (sourceIndex >= 0) {
          final body = schedePersonaggio[sourceIndex];
          for (final item in dropped.where(
            (i) => i.craftData['mechaScraps'] == true,
          )) {
            final source = Map<String, dynamic>.from(
              item.craftData['robotSource'] as Map,
            );
            for (final key in _mechaBodyFields) {
              if (body.containsKey(key)) source[key] = body[key];
            }
            source['mechaMaxHp'] = sheetMaxHpForDeathAt(sourceIndex);
            source['currentHp'] = '${source['mechaMaxHp']}';
            item.craftData['robotSource'] = source;
          }
        }
      }
      pooledLoot.addAll(dropped);
      if (oculumFallenEyeDropCreatesOnNaturalTwenty(
            subtraitId: 'drop',
            naturalRoll: natural,
          ) &&
          !knownEyeKillIds.contains(killId) &&
          candidateEyeKillIds.add(killId)) {
        final monsterTagForEye = '${enemy['monsterSheetTag'] ?? ''}';
        final sourceIndexForEye = localSheetIndexForOculumTag(monsterTagForEye);
        final eyeSource = sourceIndexForEye >= 0
            ? _cloneJsonMap(schedePersonaggio[sourceIndexForEye])
            : _fallenEyeSourceFromMonsterBook(
                monster,
                name: '${monster.nameIt} — Occhio Caduto',
                level: level,
              );
        eyeSource['nome'] = '${monster.nameIt} — Occhio Caduto';
        eyeSource['tipoScheda'] = monster.isBoss
            ? 'Boss'
            : monster.isMiniBoss
            ? 'Mini Boss'
            : 'Mostro';
        eyeSource['grado'] = grade;
        eyeSource['livello'] = level;
        final eye = _newFallenEye(
          eyeSource,
          name: '${monster.nameIt} — Occhio Caduto',
        );
        oculumFallenEyeApplyInheritedPowers(eye);
        eye
          ..['ownerSheetId'] = ''
          ..['sourceKillId'] = killId
          ..['sourcePower'] =
              grade * 100000 + readIntValue(enemy['statsTotal']) * 100 + level
          ..['sourceMonsterGrade'] = grade
          ..['sourceMonsterLevel'] = level;
        fallenEyeCandidates.add(eye);
      }
      final monsterTag = '${enemy['monsterSheetTag'] ?? ''}';
      final monsterIndex = localSheetIndexForOculumTag(monsterTag);
      if (monsterIndex >= 0) {
        final monsterSheet = schedePersonaggio[monsterIndex];
        monsterSheet['monsterLootPending'] = false;
        monsterSheet['monsterLootGenerated'] = true;
        monsterSheet['monsterLootRoll'] = {
          'natural': natural,
          'bonus': bonus,
          'total': total,
          'difficulty': difficulty,
          'rollerTag': rollerTag,
          'itemsDistributed': dropped.map((item) => item.nome).toList(),
        };
      }
      aggiungiLog(
        '[DROP] ${enemy['name']}: $natural + $bonus = $total contro DT $difficulty${dropped.isEmpty ? ' · nessun bottino' : ' · ${dropped.length} oggetti'}; tiro di ${nomeSchedaPersonaggio(rollerIndex)}.',
      );
    }
    final lootByParticipant = oculumDistributeEncounterLoot(
      items: pooledLoot,
      participantTags: partyTags,
    );
    final participantStatTotals = <String, int>{
      for (final tag in partyTags)
        tag: (() {
          final index = localSheetIndexForOculumTag(tag);
          if (index < 0) return 0;
          return ['resilienza', 'volonta', 'materia', 'oculum'].fold<int>(
            0,
            (total, stat) => total + max(0, sheetIntValueAt(index, stat)),
          );
        })(),
    };
    final fallenEyesByParticipant = oculumDistributeFallenEyes(
      eyes: fallenEyeCandidates,
      participantStatTotals: participantStatTotals,
    );
    for (final entry in fallenEyesByParticipant.entries) {
      for (final eye in entry.value) {
        eye['ownerSheetId'] = entry.key;
      }
    }
    final reward = <String, dynamic>{
      if (group['escapeExperience'] is Map)
        'escapeExperience': Map<String, dynamic>.from(
          group['escapeExperience'] as Map,
        ),
      'won': outcome == 'victory',
      'legacyWon':
          defeated.isNotEmpty &&
          !(group['tokens'] as List? ?? []).whereType<Map>().any(
            (token) =>
                token['side'] == 'enemy' &&
                !const {
                  'dead',
                  'fled',
                  'expired',
                }.contains('${token['status']}'),
          ),
      'endedEncounterId': id,
      'scostuSettlements': scostuFightSettlements(masterInitiativeTokens),
      'id': settlementId,
      'rewardMethod': rewardMethod,
      'outcome': outcome,
      'subtraitFightInstanceIds': participantFightIds,
      'commonExperienceByParticipant': commonExperience,
      'finishingExperienceByParticipant': finishingExperience,
      'assistanceExperienceByParticipant': assistanceExperience,
      'experienceByParticipant': experience,
      'resourceEligibleByParticipant': resourceEligible,
      'eligiblePowerExpenseBonusByParticipant': eligiblePowerExpenseBonus,
      'finishingObserByParticipant': finishingObser,
      'subtraitMultipliersByParticipant': subtraitMultipliers,
      'weakestParticipantTags': weakest.toList(),
      'name': group['name'],
      'amount': group['escapeExperience'] is Map
          ? (group['escapeExperience'] as Map).values.fold<int>(
              0,
              (n, v) => n + readIntValue(v),
            )
          : amount,
      'defeated': defeated,
      'participants': participants.toList(),
      'participantLevels': participantLevels,
      'participantPowers': permanentPowers,
      'participantQuestPowers': questPowers,
      'lootByParticipant': lootByParticipant,
      'fallenEyesByParticipant': fallenEyesByParticipant,
      'fateActive':
          group['chainedFate'] is Map &&
          (group['chainedFate'] as Map)['status'] == 'active',
      'fateParticipants': group['chainedFate'] is Map
          ? List<dynamic>.from(
              (group['chainedFate'] as Map)['participants'] as List? ?? [],
            )
          : <dynamic>[],
    };
    final rewards = (group['rewards'] as List? ?? []).whereType<Map>().toList()
      ..add(reward);
    group['rewards'] = rewards;
    group['settlementReceiptIds'] = {
      ...(group['settlementReceiptIds'] as List? ?? const []).map((e) => '$e'),
      settlementId,
    }.toList();
    group.remove('pendingRewardSettlementId');
    receiveEncounterRewards([reward]);
    expireSummoningEmblems(id);
    clearTemporaryCombatResistanceEffects();
    for (final request in onlineCombatRequests.values) {
      if (request['encounterId'] == id &&
          request['kind'] != 'encounter_reward') {
        request['status'] = 'closed';
        request['freeReaction'] = false;
      }
    }
    final allies = oculumBoardAfterFight(masterInitiativeTokens);
    masterInitiativeTokens
      ..clear()
      ..addAll(allies);
    for (final token in masterInitiativeTokens) {
      token['outsideFight'] = true;
    }
    group['combatEnded'] = true;
    group['fightStarted'] = false;
    reindexMasterInitiativeTokens();
    masterInitiativeRound = 0;
    masterInitiativeActiveIndex = 0;
    masterInitiativeManualOrder = false;
    masterInitiativeManualCounter = 0;
    group['mergedEncounterIds'] = <String>[];
    group['rollRequests'] = <Map<String, dynamic>>[];
    if (group['chainedFate'] is Map) {
      (group['chainedFate'] as Map)['status'] = 'ended';
    }
    forgetCombatDiscoveries(id);
    captureActiveMasterInitiativeGroup();
    sendRealtimeInitiativeSnapshot();
    aggiungiLog(
      '[FINE SCONTRO] ${group['name']}: ${rewardMethod == oculumEncounterRewardMethodDifference ? 'premi individuali calcolati dalla PT media e dai bonus personali.' : '$amount EXP base per partecipante.'}',
    );
    programmaSalvataggio();
    setState(() {});
  }
}
