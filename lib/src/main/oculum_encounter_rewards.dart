part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member
bool oculumEncounterEnemyKilled(Map token) =>
    token['side'] == 'enemy' && token['status'] == 'dead';

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
  void receiveEncounterRewards(Iterable<Map> rewards) {
    for (final reward in rewards) {
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
      final legacyAmount = readIntValue(reward['amount']).clamp(0, 100000000);
      final rawDefeated = reward['defeated'];
      final defeated = rawDefeated is List
          ? rawDefeated.whereType<Map>().toList()
          : <Map>[];
      if (id.isEmpty || legacyAmount <= 0 && defeated.isEmpty) continue;
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
        final amount = escapeAmounts != null
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
        if (amount <= 0 &&
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
            'amount': amount,
            'discoveryEnemies': [
              for (final enemy in escapeAmounts != null ? <Map>[] : defeated)
                {
                  ...enemy,
                  'experienceReward': oculumEncounterExperienceForEnemies(
                    [enemy],
                    characterGrade: i == schedaCorrente
                        ? leggiNumero(gradoController)
                        : sheetIntValueAt(i, 'grado'),
                    rebirth: i == schedaCorrente
                        ? rebirthato
                        : readBoolValue(schedePersonaggio[i]['rebirthato']),
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
      final amount =
          (readIntValue(reward['amount']) + discovery.bonus) *
          readIntValue(reward['multiplier'], fallback: 1);
      final message = applicaEsperienzaFlat(
        amount,
        motivo: 'Fine scontro ${reward['encounterName'] ?? ''}',
        applyChainedFate: false,
      );
      aggiungiLog(message);
      if (discovery.bonus > 0) {
        aggiungiLog(
          '[PRIMA SCONFITTA / VARIANTE] +${discovery.bonus} EXP prima del moltiplicatore del Fato.',
        );
      }
      final obser = readIntValue(reward['obser']).clamp(0, 100000000);
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
      if (obser > 0 || awardedDust > 0) {
        aggiungiLog(
          '[DROP FINE SCONTRO] +$obser Obser · +$awardedDust Ascension Dust (massimo 3 prima di riposare o aprire il mercante).',
        );
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
    selectMasterInitiativeGroup(id);
    captureActiveMasterInitiativeGroup();
    final group = masterInitiativeGroups
        .where((g) => g['id'] == id)
        .firstOrNull;
    if (group == null || masterInitiativeTokens.isEmpty) return;
    var amount = 0;
    final defeated = <Map<String, dynamic>>[];
    final participants = <String>{};
    final countedEnemies = <String>{};
    for (final token in masterInitiativeTokens) {
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
      final enemyTag = publicInitiativeSourceTag(token);
      if (enemyTag.isNotEmpty && !countedEnemies.add(enemyTag)) continue;
      final index = localSheetIndexForOculumTag(
        '${token['sheetTag'] ?? token['id']}',
      );
      final level = max(0, readIntValue(token['level']));
      var statsTotal = 0;
      if (index >= 0) {
        for (final stat in ['resilienza', 'volonta', 'materia', 'oculum']) {
          statsTotal += max(0, sheetIntValueAt(index, stat));
        }
      } else {
        statsTotal = max(0, readIntValue(token['statsTotal']));
      }
      amount += level + statsTotal;
      final monsterSource = index >= 0
          ? monsterLootSourceForSheet(schedePersonaggio[index])
          : null;
      defeated.add({
        'id': token['id'],
        'name': token['name'],
        'monsterBookId': monsterSource?.id ?? '${token['monsterBookId'] ?? ''}',
        'element': monsterSource?.elementId ?? '${token['element'] ?? ''}',
        if (index >= 0 &&
            '${schedePersonaggio[index]['experienceFamilyId'] ?? ''}'
                .trim()
                .isNotEmpty)
          'experienceFamilyId': schedePersonaggio[index]['experienceFamilyId'],
        'monsterSheetTag': index >= 0 ? sheetTagAt(index) : '',
        if(index >= 0 && (schedePersonaggio[index]['planarRuntime'] as Map?)?['canonicalNpc']=='lusier_iii')
          'canonicalNpc':'lusier_iii',
        'level': level,
        'killerTag': index >= 0
            ? schedePersonaggio[index]['lastDamageSourceTag']
            : token['lastDamageSourceTag'],
        'titleItemIds': index >= 0
            ? schedePersonaggio[index]['lastDamageTitleItemIds'] ?? const []
            : token['lastDamageTitleItemIds'] ?? const [],
        'totalPower': index >= 0
            ? readIntValue((schedePersonaggio[index]['lastDamagePowerRecord'] as Map?)?['totalPower'], fallback: scoutTotalPowerAt(index))
            : readIntValue(token['totalPower'], fallback: -1),
        'killerTotalPower': index >= 0
            ? readIntValue((schedePersonaggio[index]['lastDamagePowerRecord'] as Map?)?['killerTotalPower'], fallback: -1)
            : readIntValue(token['killerTotalPower'], fallback: -1),
        'finisher': index >= 0
            ? schedePersonaggio[index]['lastPlanarFinisher']
            : token['lastPlanarFinisher'],
        'statsTotal': statsTotal,
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
    final ok = automatic
        ? true
        : await showDialog<bool>(
            context: context,
            builder: (dialog) => AlertDialog(
              title: const Text('Termina scontro'),
              content: SingleChildScrollView(
                child: Text(
                  '${defeated.length} nemici sconfitti · $amount EXP base. '
                  'Il premio di ciascun partecipante usa categoria e Grado di ogni nemico, '
                  'confrontato con il proprio Grado. I Drop dei mostri uccisi presenti '
                  'in turnistica vengono tirati e distribuiti ora. Party e NPC alleati restano sulla board; i nemici vengono rimossi. La '
                  'condivisione chiusa. Gli scontri uniti tornano separati.\n\n'
                  '${defeated.map((enemy) => '${enemy['name'] ?? 'Nemico'} · '
                      '${enemy['source']} · Grado ${oculumExperienceGradeLabel(readIntValue(enemy['grade']))} · '
                      '${readIntValue(enemy['level']) + readIntValue(enemy['statsTotal'])} EXP base').join('\n')}',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialog),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialog, true),
                  child: const Text('Termina, tira i Drop e assegna EXP'),
                ),
              ],
            ),
          );
    if (!mounted || ok != true) return;
    resolveCorruptionFightEnd(id);
    final cooldownFightSequence =
        max(0, readIntValue(group['completedFightCount'])) + 1;
    group['completedFightCount'] = cooldownFightSequence;
    final cooldownFightId = '$id:$cooldownFightSequence';
    for (final enemy in defeated) {
      await resolveMartyrDeath(enemy, '$cooldownFightId:${enemy['id']}');
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
    final partyTags = participants.toList()..sort();
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
    final participantLevels = <String, int>{
      for (final tag in partyTags)
        tag: (() {
          final index = localSheetIndexForOculumTag(tag);
          return index < 0 ? 0 : max(0, sheetIntValueAt(index, 'livello'));
        })(),
    };
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
      if(enemy['canonicalNpc']=='lusier_iii' && !oculumEncounterEnemyIsSummon(enemy)) {
        final sourceIndex=localSheetIndexForOculumTag('${enemy['monsterSheetTag'] ?? ''}');
        final sourceDeck=sourceIndex<0?null:
          (schedePersonaggio[sourceIndex]['inventario'] as List? ?? []).whereType<Map>()
            .where((i)=>(i['craftData'] as Map?)?['explosiveCards']==true).firstOrNull;
        final deck=sourceDeck==null?oculumExplosiveCards(lusier:true):
          InventoryItem.fromJson(Map<String,dynamic>.from(sourceDeck));
        deck.equipaggiata=false;
        deck.craftData['namedDropKillId']=killId;
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
      'won':
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
      'id': '$id:${DateTime.now().microsecondsSinceEpoch}',
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
      '[FINE SCONTRO] ${group['name']}: $amount EXP base per partecipante.',
    );
    programmaSalvataggio();
    setState(() {});
  }
}
