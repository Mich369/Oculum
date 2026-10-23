part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int oculumCorruptionDecayHits({
  required int hits,
  required int elapsedTurns,
  int interval = 2,
}) => max(0, hits - max(0, elapsedTurns) ~/ max(1, interval));

bool oculumCorruptionNeedsCritical({
  required int difficulty,
  required int rollBonus,
}) => difficulty > 19 + rollBonus;

extension _OculumCorruptionRuntime on _OculumHomePageState {
  Map<String, dynamic> corruptionInfectionMetadata(
    Map<String, dynamic> request,
    int index,
  ) => {
    'corruptedByTag': request['sourceTag'],
    'sourceLevel': readIntValue(request['level']),
    'encounterId': request['encounterId'],
    'escapeDifficulty': readIntValue(request['attack']),
    'escapeAttempts': 0,
    'nextResistanceTurn':
        (index == schedaCorrente
            ? playerReportedTurn
            : readIntValue(schedePersonaggio[index]['playerReportedTurn'])) +
        3,
    'suicideAtFightEnd':
        readIntValue(request['corruptionDefenseNatural']) == 1 ||
        (index == schedaCorrente
                ? leggiNumero(livelloController)
                : sheetIntValueAt(index, 'livello')) <
            readIntValue(request['level']),
    'resistanceIntervalTurns': 3,
    'difficultyIncreasePerAttempt': 3,
    'revengeDamage': 10,
    'targetControlChancePercent': readIntValue(
      request['targetControlChancePercent'],
      fallback: 90,
    ).clamp(0, 100),
  };

  void advanceCorruptionPersonalTurn(int turn) {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return;
    }
    final sheet = schedePersonaggio[schedaCorrente];
    final progress = sheet['corruptionMasteryProgress'];
    if (progress is Map) {
      for (final entry in progress.entries.toList()) {
        if (entry.value is! Map) continue;
        final row = Map<String, dynamic>.from(entry.value);
        final since = readIntValue(
          row['lastDecayTurn'],
          fallback: readIntValue(row['lastHitTurn'], fallback: turn),
        );
        final elapsed = max(0, turn - since);
        final interval = max(
          1,
          readIntValue(row['decayIntervalTurns'], fallback: 2),
        );
        if (elapsed < interval) continue;
        final before = readIntValue(row['hits']);
        row['hits'] = oculumCorruptionDecayHits(
          hits: before,
          elapsedTurns: elapsed,
          interval: interval,
        );
        row['lastDecayTurn'] = since + (elapsed ~/ interval) * interval;
        progress[entry.key] = row;
        if (before != row['hits']) {
          aggiungiLog(
            '[CORRUZIONE] Nessun nuovo colpo: accumulo di ${entry.key} $before → ${row['hits']}.',
          );
        }
      }
    }
    final condition = getCondition('corruzione');
    if (condition == null ||
        condition.metadata['suicideAtFightEnd'] == true ||
        condition.metadata['endResolved'] == true) {
      return;
    }
    final metadata = condition.metadata;
    if (metadata['pendingResistanceId'] != null) return;
    if (turn <
        readIntValue(metadata['nextResistanceTurn'], fallback: turn + 3)) {
      return;
    }
    final attempt = readIntValue(metadata['escapeAttempts']) + 1;
    final difficulty =
        readIntValue(metadata['escapeDifficulty']) +
        max(
          0,
          readIntValue(metadata['difficultyIncreasePerAttempt'], fallback: 3),
        );
    final id = 'corruption-escape:${condition.id}:$attempt';
    metadata['escapeDifficulty'] = difficulty;
    metadata['escapeAttempts'] = attempt;
    metadata['pendingResistanceId'] = id;
    onlineCombatRequests[id] = <String, dynamic>{
      'id': id,
      'kind': 'corruption',
      'status': 'pending',
      'scope': permissionScope,
      'encounterId': onlineCombatEncounterId,
      'sourceTag': metadata['corruptedByTag'],
      'sourceName': condition.source,
      'targetTag': sheetTagAt(schedaCorrente),
      'targetName': nomeController.text,
      'level': readIntValue(metadata['sourceLevel']),
      'attack': difficulty,
      'isCorruptionEscape': true,
      'conditionId': condition.id,
    };
    aggiungiLog(
      '[CORRUZIONE] Nuovo tentativo per liberarti: scegli Crepa o Fermezza. La prova è più difficile della precedente.',
    );
    notifyActiveSheetSummaryChanged();
  }

  int corruptionBestResistanceBonus(Map<String, dynamic> request) {
    final bonuses = hiddenEyeStats
        .where((stat) => const {'crepa', 'fermezza'}.contains(stat.id))
        .map(
          (stat) =>
              hiddenEyeTotal(stat) +
              hiddenEyeStatRollQuickBonus(stat) +
              tiroGlobaleBonus() +
              modificatoreDifficoltaTiro(),
        );
    final base = bonuses.isEmpty ? 0 : bonuses.reduce(max);
    return base -
        oculumCorruptionDefensePenalty(
          targetLevel: leggiNumero(livelloController),
          sourceLevel: readIntValue(request['level']),
        );
  }

  void completeCorruptionEscape(Map<String, dynamic> request) {
    if (request['status'] != 'pending') return;
    final condition = getCondition('corruzione');
    if (condition == null ||
        condition.id != request['conditionId'] ||
        condition.metadata['pendingResistanceId'] != request['id']) {
      return;
    }
    final metadata = condition.metadata;
    request['status'] = 'resolved';
    metadata.remove('pendingResistanceId');
    if (request['corruptionResisted'] == true) {
      final sheet = schedePersonaggio[schedaCorrente];
      final raw = sheet['corruptionRevenge'];
      final revenge = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      revenge['${metadata['corruptedByTag']}'] = {
        'damage': max(0, readIntValue(metadata['revengeDamage'], fallback: 10)),
        'encounterId': onlineCombatEncounterId,
      };
      sheet['corruptionRevenge'] = revenge;
      final bonus = readIntValue(
        (revenge['${metadata['corruptedByTag']}'] as Map)['damage'],
      );
      removeCondition(condition, force: true);
      aggiungiLog(
        '[CORRUZIONE] Ti liberi: +$bonus Danni soltanto contro il precedente corruttore, fino a fine fight.',
      );
    } else {
      if (readIntValue(request['corruptionDefenseNatural']) == 1 ||
          request['corruptionImpossibleAttempt'] == true) {
        metadata['suicideAtFightEnd'] = true;
        aggiungiLog(
          '[CORRUZIONE] Totalmente succube: suicidio a fine fight. Nessun ulteriore tentativo impossibile.',
        );
      } else {
        metadata['nextResistanceTurn'] =
            playerReportedTurn +
            max(
              1,
              readIntValue(metadata['resistanceIntervalTurns'], fallback: 3),
            );
        aggiungiLog(
          '[CORRUZIONE] Resistenza fallita: prossimo tentativo fra ${readIntValue(metadata['resistanceIntervalTurns'], fallback: 3)} turni personali.',
        );
      }
    }
    salvaSchedaCorrenteInMemoria();
    programmaSalvataggio();
    sendRealtimeMasterVisibleTokenAt(schedaCorrente);
    sendRealtimeInitiativeSnapshotIfPublished();
    notifyActiveSheetSummaryChanged();
  }

  int corruptionRevengeDamage(String target) {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return 0;
    }
    final raw = schedePersonaggio[schedaCorrente]['corruptionRevenge'];
    final row = raw is Map ? raw[target] : null;
    return row is Map && row['encounterId'] == onlineCombatEncounterId
        ? max(0, readIntValue(row['damage']))
        : 0;
  }

  bool corruptionSuicideDueAt(int index, String encounter) {
    if (index < 0 || index >= schedePersonaggio.length) return false;
    final conditions = index == schedaCorrente
        ? activeConditions.map((c) => c.toJson()).toList()
        : schedePersonaggio[index]['conditions'];
    if (conditions is! List) return false;
    return conditions.whereType<Map>().any((condition) {
      final metadata = condition['metadata'];
      return condition['conditionType'] == 'corruzione' &&
          metadata is Map &&
          metadata['encounterId'] == encounter &&
          metadata['suicideAtFightEnd'] == true &&
          metadata['endResolved'] != true;
    });
  }

  void resolveCorruptionFightEnd(String encounter) {
    if (encounter.isEmpty) return;
    for (var index = 0; index < schedePersonaggio.length; index++) {
      final sheet = schedePersonaggio[index];
      final current = index == schedaCorrente;
      if (current) {
        sheet['conditions'] = activeConditions.map((c) => c.toJson()).toList();
      }
      final revenge = sheet['corruptionRevenge'];
      if (revenge is Map) {
        revenge.removeWhere(
          (_, row) => row is Map && row['encounterId'] == encounter,
        );
      }
      if (!corruptionSuicideDueAt(index, encounter)) continue;
      if (realtimeService?.isConnected == true &&
          !realtimeIsMasterRole &&
          !controlsOnlineCombatSheet(sheetTagAt(index))) {
        continue;
      }
      for (final raw in (sheet['conditions'] as List).whereType<Map>()) {
        final metadata = raw['metadata'];
        if (raw['conditionType'] != 'corruzione' ||
            metadata is! Map ||
            metadata['encounterId'] != encounter) {
          continue;
        }
        metadata['endResolved'] = true;
      }
      sheet['currentHp'] = '0';
      sheet['feriteMorte'] = 3;
      sheet['personaggioCaduto'] = true;
      if (current) {
        final condition = getCondition('corruzione');
        condition?.metadata['endResolved'] = true;
        currentHpController.text = '0';
        feriteMorte = 3;
        personaggioCaduto = true;
      }
      for (final token in masterInitiativeTokens.where(
        (t) => publicInitiativeSourceTag(t) == sheetTagAt(index),
      )) {
        token.addAll({'currentHp': 0, 'deathWounds': 3, 'status': 'dead'});
      }
      combatLogFor(
        sheetTagAt(index),
        '[CORRUZIONE] Fine fight: il dominio totale causa il suicidio.',
      );
      sendRealtimeMasterVisibleTokenAt(index);
    }
  }
}
