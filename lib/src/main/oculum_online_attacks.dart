part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Preserve repeated hits when the corruptor replaces the distinct targets.
List<String> oculumRedirectAttackHits(
  List<String> original,
  List<String> selected,
) {
  final distinct = original.toSet().toList();
  if (distinct.length != selected.length ||
      selected.toSet().length != selected.length) {
    return const [];
  }
  final replacements = Map<String, String>.fromIterables(distinct, selected);
  return original.map((target) => replacements[target]!).toList();
}

({int minimum, int maximum}) oculumAttackTargetLimits(String text, int oculum) {
  var normalized = oculumNormalizeText(text);
  const words = {
    'uno': '1',
    'un': '1',
    'una': '1',
    'due': '2',
    'tre': '3',
    'quattro': '4',
    'cinque': '5',
    'sei': '6',
  };
  for (final entry in words.entries) {
    normalized = normalized.replaceAll(
      RegExp('\\b${entry.key}\\b'),
      entry.value,
    );
  }
  final range = RegExp(
    r'(?:da\s+)?(\d+)\s*(?:a|o|[-–])\s*(\d+)\s+(?:bersagli|avversari|nemici|creature|alleati|compagni)',
  ).firstMatch(normalized);
  if (range != null) {
    final minimum = (int.tryParse(range.group(1)!) ?? 1).clamp(1, 100);
    return (
      minimum: minimum,
      maximum: max(
        minimum,
        int.tryParse(range.group(2)!) ?? minimum,
      ).clamp(1, 100),
    );
  }
  if (RegExp(
    r'fino\s+ad?\s+oculum\s+(?:bersagli|avversari|nemici|creature|alleati|compagni)',
  ).hasMatch(normalized)) {
    return (minimum: 1, maximum: oculum.clamp(1, 100));
  }
  final count = RegExp(
    r'(?:fino\s+a|massimo|max)\s+(\d+)\s+(?:bersagli|avversari|nemici|creature|alleati|compagni)',
  ).firstMatch(normalized);
  if (count != null) {
    return (
      minimum: 1,
      maximum: (int.tryParse(count.group(1)!) ?? 1).clamp(1, 100),
    );
  }
  final exact = RegExp(
    r'(\d+)\s+(?:bersagli|avversari|nemici|creature|alleati|compagni)',
  ).firstMatch(normalized);
  if (exact != null) {
    final count = (int.tryParse(exact.group(1)!) ?? 1).clamp(1, 100);
    return (minimum: count, maximum: count);
  }
  return (minimum: 1, maximum: 1);
}

extension _OculumOnlineAttacks on _OculumHomePageState {
  Map<String, dynamic> corruptionMetadataForToken(Map<String, dynamic> token) {
    final tag = onlineCombatTokenTag(token);
    final index = localSheetIndexForOculumTag(tag);
    // Received sheets may lag behind the authoritative encounter snapshot.
    if (index < 0 ||
        readBoolValue(schedePersonaggio[index]['realtimeSharedSheet'])) {
      return token;
    }
    if (index == schedaCorrente && index >= 0) {
      return activeConditions
              .where((condition) => condition.conditionType == 'corruzione')
              .firstOrNull
              ?.metadata ??
          <String, dynamic>{};
    }
    if (index >= 0) {
      final conditions = schedePersonaggio[index]['conditions'];
      if (conditions is List) {
        final metadata = conditions
            .whereType<Map>()
            .where((condition) => condition['conditionType'] == 'corruzione')
            .firstOrNull?['metadata'];
        return metadata is Map
            ? Map<String, dynamic>.from(metadata)
            : <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }

  String corruptionOwnerForToken(Map<String, dynamic> token) =>
      '${corruptionMetadataForToken(token)['corruptedByTag'] ?? ''}';

  int corruptionControlChanceForToken(Map<String, dynamic> token) =>
      readIntValue(
        corruptionMetadataForToken(token)['targetControlChancePercent'],
        fallback: oculumCorruptionMasteryTargetControlPercent,
      ).clamp(0, 100);

  bool recordCorruptionMasteryHit(Map<String, dynamic> request) {
    if (request['outcome'] != OculumAttackOutcome.full.name ||
        schedaCorrente < 0 ||
        schedaCorrente >= schedePersonaggio.length)
      return false;
    final required = oculumCorruptionRequiredFullHits(
      sourceLevel: readIntValue(request['level']),
      targetLevel: leggiNumero(livelloController),
    );
    if (required == 0) return false;
    final source = '${request['sourceTag'] ?? ''}';
    final id = '${request['id'] ?? ''}';
    if (source.isEmpty || id.isEmpty) return false;
    final sheet = schedePersonaggio[schedaCorrente];
    final raw = sheet['corruptionMasteryProgress'];
    final encounter = '${request['encounterId']}';
    final progress = raw is Map && raw['encounterId'] == encounter
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{'encounterId': encounter};
    final previous = progress[source];
    final row = previous is Map
        ? Map<String, dynamic>.from(previous)
        : <String, dynamic>{};
    final seen = (row['requests'] is List ? row['requests'] as List : const [])
        .map((id) => '$id')
        .toSet();
    if (!seen.add(id)) return false;
    final hits = min(required, readIntValue(row['hits']) + 1);
    // A completed attempt spends the accumulated hits, even if resisted.
    progress[source] = {
      'hits': hits >= required ? 0 : hits,
      'required': required,
      'requests': seen.toList(),
      'lastHitTurn': playerReportedTurn,
      'lastDecayTurn': playerReportedTurn,
      'decayIntervalTurns': readIntValue(
        row['decayIntervalTurns'],
        fallback: 2,
      ),
    };
    sheet['corruptionMasteryProgress'] = progress;
    request['corruptionFullHits'] = hits;
    request['corruptionRequiredHits'] = required;
    aggiungiLog(
      '[CORRUZIONE] ${request['sourceName'] ?? source}: $hits/$required colpi pieni. I mezzi successi non contano.',
    );
    programmaSalvataggio(invalidateCaches: false);
    return hits >= required;
  }

  void claimCorruptionMasteryCooldown(Map<String, dynamic> request) {
    if (request['corruptionApplicationId'] == null ||
        request['corruptionCooldownClaimed'] == true ||
        !controlsOnlineCombatSheet('${request['sourceTag']}'))
      return;
    final index = localSheetIndexForOculumTag('${request['sourceTag']}');
    if (index < 0) return;
    final original = schedaCorrente;
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    try {
      if (index != original) {
        schedaCorrente = index;
        caricaStatoDaJson(schedePersonaggio[index]);
        ripristinaImpostazioniGlobali(global);
      }
      final skill = skills.where(oculumIsCorruptionMastery).firstOrNull;
      if (skill != null) {
        corruptionSkillCooldown(skill).activate();
        aggiungiLog(
          '[CORRUZIONE] Tentativo effettuato: ricarica ${corruptionSkillCooldown(skill).amount} turni. In ricarica i colpi non contano.',
        );
      }
      request['corruptionCooldownClaimed'] = true;
      salvaSchedaCorrenteInMemoria();
    } finally {
      if (index != original) {
        schedaCorrente = original;
        caricaStatoDaJson(schedePersonaggio[original]);
        ripristinaImpostazioniGlobali(global);
      }
    }
    programmaSalvataggio(invalidateCaches: false);
  }

  Future<List<String>?> chooseCorruptedTargets(
    Map<String, dynamic> request,
  ) async {
    final source = '${request['sourceTag']}';
    final candidates = onlineCombatTokens()
        .where(
          (token) =>
              onlineCombatTokenTag(token) != source &&
              !const {'dead', 'fled', 'expired'}.contains(token['status']),
        )
        .toList();
    final count = readIntValue(
      request['targetCount'],
      fallback: 1,
    ).clamp(1, candidates.length.clamp(1, 1000));
    if (candidates.length < count) return null;
    final selected = <String>[];
    return showDialog<List<String>>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text('Corruzione · guida ${request['sourceName']}'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Scegli $count bersagli reali dell’attacco.'),
                  for (final token in candidates)
                    CheckboxListTile(
                      title: Text('${token['name'] ?? 'Partecipante'}'),
                      value: selected.contains(onlineCombatTokenTag(token)),
                      onChanged: (checked) => update(() {
                        final tag = onlineCombatTokenTag(token);
                        if (checked == true && selected.length < count) {
                          selected.add(tag);
                        }
                        if (checked != true) selected.remove(tag);
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: selected.length == count
                  ? () => Navigator.pop(dialog, selected.toList())
                  : null,
              child: const Text('Conferma bersagli'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> answerCorruptionTargetRequest(
    Map<String, dynamic> request,
  ) async {
    if (request['status'] != 'pending' ||
        request['targetTag'] != sheetTagAt(schedaCorrente) ||
        request['scope'] != permissionScope ||
        request['encounterId'] != onlineCombatEncounterId) {
      return;
    }
    final origin = currentSheetScrollId();
    final selected = await chooseCorruptedTargets(request);
    if (!mounted ||
        selected == null ||
        currentSheetScrollId() != origin ||
        request['status'] != 'pending') {
      return;
    }
    final reply = {...request, 'phase': 'choice', 'selectedTargets': selected};
    final sent = await realtimeService?.sendCombatEvent(
      'corruption_target',
      permissionEnvelope(reply),
    );
    if (sent == true) {
      request['status'] = 'resolved';
      request['selectedTargets'] = selected;
      aggiungiLog(
        '[CORRUZIONE] Hai scelto i bersagli dell’attacco di ${request['sourceName']}.',
      );
      notifyActiveSheetSummaryChanged();
      programmaSalvataggio();
    }
  }

  void receiveCorruptionTarget(Map<String, dynamic> payload) {
    if (!validPermissionSender(payload) ||
        payload['encounterId'] != onlineCombatEncounterId) {
      return;
    }
    final id = '${payload['id'] ?? ''}';
    final source = '${payload['sourceTag'] ?? ''}';
    final controller = '${payload['targetTag'] ?? ''}';
    if (id.isEmpty || id.length > 160) return;
    if (payload['phase'] == 'choice') {
      final request = onlineCombatRequests[id];
      if (request == null ||
          request['kind'] != 'corruption_target' ||
          request['status'] != 'pending' ||
          request['sourceTag'] != source ||
          request['targetTag'] != controller ||
          payload['senderTag'] != controller) {
        return;
      }
      final raw = payload['selectedTargets'];
      if (raw is! List || raw.length != readIntValue(request['targetCount'])) {
        return;
      }
      final choices = raw.map((tag) => '$tag').toList();
      final alive =
          onlineCombatTokens()
              .where(
                (token) => !const {
                  'dead',
                  'fled',
                  'expired',
                }.contains(token['status']),
              )
              .map(onlineCombatTokenTag)
              .toSet()
            ..remove(source);
      if (choices.toSet().length != choices.length ||
          !choices.every(alive.contains)) {
        return;
      }
      request['status'] = 'resolved';
      request['selectedTargets'] = choices;
      final completer = corruptionTargetChoices[id];
      if (completer != null && !completer.isCompleted) {
        completer.complete(choices);
      }
      return;
    }
    final token = onlineCombatTokens()
        .where((token) => onlineCombatTokenTag(token) == source)
        .firstOrNull;
    if (payload['senderTag'] != source ||
        token == null ||
        corruptionOwnerForToken(token) != controller ||
        !controlsOnlineCombatSheet(controller)) {
      return;
    }
    final previous = onlineCombatRequests[id];
    if (previous != null) {
      if (previous['status'] == 'resolved' &&
          previous['selectedTargets'] is List) {
        unawaited(
          realtimeService?.sendCombatEvent(
            'corruption_target',
            permissionEnvelope({...previous, 'phase': 'choice'}),
          ),
        );
      }
      return;
    }
    onlineCombatRequests[id] = {
      ...payload,
      'kind': 'corruption_target',
      'status': 'pending',
    };
    combatLogFor(
      controller,
      '[CORRUZIONE] ${payload['sourceName']} vuole attaccare: scegli i suoi ${payload['targetCount']} bersagli reali.',
    );
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
  }

  Future<OculumAttackPlan?> redirectCorruptedAttack(
    OculumAttackPlan plan,
  ) async {
    final source = sheetTagAt(schedaCorrente);
    final token = onlineCombatTokens()
        .where((token) => onlineCombatTokenTag(token) == source)
        .firstOrNull;
    if (token == null) return plan;
    final controller = corruptionOwnerForToken(token);
    if (controller.isEmpty) return plan;
    final roll = Random.secure().nextInt(100) + 1;
    final chance = corruptionControlChanceForToken(token);
    if (roll > chance) {
      aggiungiLog(
        '[CORRUZIONE] d100 $roll > $chance: scegli liberamente il bersaglio di questo attacco.',
      );
      return plan;
    }
    final id =
        'corruption-target:$source:${DateTime.now().microsecondsSinceEpoch}';
    final request = <String, dynamic>{
      'id': id,
      'kind': 'corruption_target',
      'status': 'pending',
      'scope': permissionScope,
      'encounterId': onlineCombatEncounterId,
      'sourceTag': source,
      'sourceName': realtimeDisplayName(),
      'targetTag': controller,
      'targetCount': plan.targetIds.toSet().length,
    };
    List<String>? targets;
    if (controlsOnlineCombatSheet(controller)) {
      targets = await chooseCorruptedTargets(request);
    } else {
      onlineCombatRequests[id] = request;
      final completer = Completer<List<String>>();
      corruptionTargetChoices[id] = completer;
      try {
        final sent = await realtimeService?.sendCombatEvent(
          'corruption_target',
          permissionEnvelope(request),
        );
        if (sent != true) return null;
        aggiungiLog(
          '[CORRUZIONE] d100 $roll ≤ $chance: attendo i bersagli dal proprietario della Corruzione.',
        );
        targets = await completer.future.timeout(
          const Duration(seconds: 45),
          onTimeout: () => <String>[],
        );
      } finally {
        corruptionTargetChoices.remove(id);
        request['status'] = 'resolved';
      }
    }
    if (!mounted ||
        targets == null ||
        targets.isEmpty ||
        source != sheetTagAt(schedaCorrente)) {
      return null;
    }
    aggiungiLog(
      '[CORRUZIONE] Il proprietario sceglie i bersagli reali: ${targets.join(', ')}.',
    );
    final redirected = oculumRedirectAttackHits(plan.targetIds, targets);
    return OculumAttackPlan(
      redirected.first,
      plan.choiceId,
      plan.reason,
      additionalTargetIds: redirected.skip(1).toList(),
      element: plan.element,
    );
  }

  void queueCorruptionApplication({
    required String targetTag,
    required int scrollGrade,
    required String sourceTag,
    required String sourceName,
    required int sourceTotal,
    required int sourceLevel,
    String? requestId,
    bool fromMastery = false,
    String? attackRequestId,
    int controlChancePercent = oculumCorruptionMasteryTargetControlPercent,
  }) {
    final index = localSheetIndexForOculumTag(targetTag);
    if (index < 0) return;
    final id =
        requestId ??
        'corruption:$sourceTag:${DateTime.now().microsecondsSinceEpoch}';
    if (onlineCombatRequests.containsKey(id)) return;
    final request = <String, dynamic>{
      'id': id,
      'kind': 'corruption',
      'status': 'pending',
      'scope': permissionScope,
      'encounterId': onlineCombatEncounterId,
      'sourceTag': sourceTag,
      'sourceName': sourceName,
      'targetTag': targetTag,
      'targetName': nomeSchedaPersonaggio(index),
      'scrollGrade': scrollGrade,
      'level': sourceLevel,
      'attack': sourceTotal,
      'damage': 0,
      'received': true,
      'fromMastery': fromMastery,
      if (attackRequestId != null) 'attackRequestId': attackRequestId,
      'targetControlChancePercent': controlChancePercent.clamp(0, 100),
    };
    onlineCombatRequests[id] = request;
    combatLogFor(
      targetTag,
      '[CORRUZIONE] $sourceName tenta il contagio. Puoi scegliere Crepa o Fermezza se il tuo livello è pari o superiore.',
    );
    final targetLevel = index == schedaCorrente
        ? leggiNumero(livelloController)
        : sheetIntValueAt(index, 'livello');
    if (!oculumCanResistCorruption(
      targetLevel: targetLevel,
      sourceLevel: sourceLevel,
    )) {
      completeCorruptionApplication(request);
    }
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
  }

  Future<int?> rollCorruptionResistance(
    Map<String, dynamic> request,
    String choice,
  ) async {
    if (!const {'crepa', 'fermezza'}.contains(choice)) return null;
    final targetLevel = leggiNumero(livelloController);
    final sourceLevel = readIntValue(request['level']);
    if (!oculumCanResistCorruption(
      targetLevel: targetLevel,
      sourceLevel: sourceLevel,
    )) {
      return null;
    }
    final stat = hiddenEyeStats.where((stat) => stat.id == choice).firstOrNull;
    if (stat == null) return null;
    final origin = currentSheetScrollId();
    int? result;
    int? natural;
    request['corruptionImpossibleAttempt'] =
        request['isCorruptionEscape'] == true &&
        oculumCorruptionNeedsCritical(
          difficulty: readIntValue(request['attack']),
          rollBonus: corruptionBestResistanceBonus(request),
        );
    await tiraSottotrattoOcchio(
      stat,
      actionLabel: 'Resistenza alla Corruzione',
      opposingTotal: readIntValue(request['attack']),
      logPenalty: oculumCorruptionDefensePenalty(
        targetLevel: targetLevel,
        sourceLevel: sourceLevel,
      ),
      onResolved: (roll, total) {
        natural = roll;
        result = total;
      },
    );
    if (!mounted || currentSheetScrollId() != origin || result == null) {
      return null;
    }
    final penalty = oculumCorruptionDefensePenalty(
      targetLevel: targetLevel,
      sourceLevel: sourceLevel,
    );
    final adjusted = result! - penalty;
    request['corruptionDefense'] = adjusted;
    request['corruptionDefenseNatural'] = natural;
    request['corruptionDefenseChoice'] = choice;
    request['corruptionDefensePenalty'] = penalty;
    request['corruptionResisted'] = adjusted >= readIntValue(request['attack']);
    aggiungiLog(
      '[RESISTENZA CORRUZIONE] ${request['corruptionResisted'] == true ? 'Riuscito' : 'Fallito'}: $adjusted contro ${request['attack']}.',
    );
    return adjusted;
  }

  Future<void> defendCorruptionApplication(
    Map<String, dynamic> request,
    String choice,
  ) async {
    final id = '${request['id']}';
    if (request['status'] != 'pending' ||
        request['targetTag'] != sheetTagAt(schedaCorrente) ||
        request['scope'] != permissionScope ||
        request['encounterId'] != onlineCombatEncounterId ||
        !onlineCombatResolving.add(id)) {
      return;
    }
    try {
      if (choice != 'accept' &&
          await rollCorruptionResistance(request, choice) == null) {
        return;
      }
      if (!mounted ||
          request['targetTag'] != sheetTagAt(schedaCorrente) ||
          request['encounterId'] != onlineCombatEncounterId) {
        return;
      }
      if (request['isCorruptionEscape'] == true) {
        completeCorruptionEscape(request);
      } else {
        completeCorruptionApplication(request);
      }
    } finally {
      onlineCombatResolving.remove(id);
    }
  }

  void completeCorruptionApplication(Map<String, dynamic> request) {
    if (request['status'] != 'pending') return;
    final targetTag = '${request['targetTag']}';
    final index = localSheetIndexForOculumTag(targetTag);
    if (index < 0) return;
    final sheet = schedePersonaggio[index];
    final tokens = realtimeService?.isConnected == true
        ? onlineCombatTokens()
        : masterInitiativeTokens;
    final token = tokens
        .where(
          (token) =>
              onlineCombatTokenTag(token) == targetTag ||
              '${token['sheetTag'] ?? token['id']}' == targetTag,
        )
        .firstOrNull;
    final chance = oculumCorruptionChanceAfterResistance(
      chancePercent: request['fromMastery'] == true
          ? 100
          : oculumCorruptionScrollChance(
              scrollGrade: readIntValue(request['scrollGrade']),
              targetGrade: readIntValue(
                token?['grade'],
                fallback: sheetIntValueAt(index, 'grado'),
              ),
            ),
      resistancePercent: index == schedaCorrente
          ? currentCorruptionResistancePercent()
          : oculumCorruptionResistanceInSheet(sheet),
    );
    final roll = Random.secure().nextInt(100) + 1;
    final infected = request['corruptionResisted'] != true && roll <= chance;
    request.addAll({
      'phase': 'result',
      'status': 'resolved',
      'infected': infected,
      'roll': roll,
      'chancePercent': chance,
      'corruptorTag': request['sourceTag'],
    });
    if (infected) {
      if (index == schedaCorrente) {
        applyCondition(
          'corruzione',
          source: '${request['sourceName']}',
          metadata: corruptionInfectionMetadata(request, index),
        );
        salvaSchedaCorrenteInMemoria();
      } else {
        _writeCorruptionConditionToSheet(
          sheet,
          corruptorTag: '${request['sourceTag']}',
          chancePercent: chance,
          sourceName: '${request['sourceName']}',
          controlChancePercent: readIntValue(
            request['targetControlChancePercent'],
            fallback: oculumCorruptionMasteryTargetControlPercent,
          ),
          metadata: corruptionInfectionMetadata(request, index),
        );
      }
      final masterToken = masterInitiativeTokens
          .where((token) => publicInitiativeSourceTag(token) == targetTag)
          .firstOrNull;
      if (masterToken != null) {
        masterToken['corruptedByTag'] = request['sourceTag'];
        masterToken['targetControlChancePercent'] = readIntValue(
          request['targetControlChancePercent'],
          fallback: oculumCorruptionMasteryTargetControlPercent,
        ).clamp(0, 100);
      }
      sendRealtimeMasterVisibleTokenAt(index);
      sendRealtimeInitiativeSnapshotIfPublished();
    }
    final message = request['corruptionResisted'] == true
        ? '[CORRUZIONE] ${request['targetName']} resiste con ${request['corruptionDefenseChoice']} ${request['corruptionDefense']} contro ${request['attack']}.'
        : '[CORRUZIONE] ${request['targetName']}: d100 $roll / $chance% · ${infected ? 'infettato' : 'resiste'}.';
    combatLogFor(targetTag, message);
    if ('${request['sourceTag']}' != targetTag) {
      combatLogFor('${request['sourceTag']}', message);
    }
    if (realtimeService?.isConnected == true) {
      unawaited(
        realtimeService!.sendCombatEvent(
          'corruption_apply',
          permissionEnvelope(request),
        ),
      );
    }
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
  }

  Future<bool> offerCorruptionResistance(Map<String, dynamic> request) async {
    if (request.containsKey('corruptionResisted')) {
      return request['corruptionResisted'] == true;
    }
    if (!oculumCanResistCorruption(
      targetLevel: leggiNumero(livelloController),
      sourceLevel: readIntValue(request['level']),
    )) {
      return false;
    }
    final tag = sheetTagAt(schedaCorrente);
    final penalty = oculumCorruptionDefensePenalty(
      targetLevel: leggiNumero(livelloController),
      sourceLevel: readIntValue(request['level']),
    );
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => PopScope(
        canPop: false,
        child: SimpleDialog(
          title: Text('Resisti alla Corruzione · DT ${request['attack']}'),
          children: [
            for (final id in ['crepa', 'fermezza'])
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialog, id),
                child: Text(
                  '${id == 'crepa' ? 'Crepa' : 'Fermezza'}${penalty > 0 ? ' −3 · livello pari' : ''}',
                ),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, 'accept'),
              child: const Text('Non tentare · applica la resistenza passiva'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || tag != sheetTagAt(schedaCorrente)) return true;
    if (choice == null) return true;
    if (choice == 'accept') {
      request['corruptionResisted'] = false;
      return false;
    }
    if (await rollCorruptionResistance(request, choice) == null) return true;
    return request['corruptionResisted'] == true;
  }

  Widget corruptionApplicationPanel(Map<String, dynamic> request) {
    final canRoll = oculumCanResistCorruption(
      targetLevel: leggiNumero(livelloController),
      sourceLevel: readIntValue(request['level']),
    );
    final penalty = oculumCorruptionDefensePenalty(
      targetLevel: leggiNumero(livelloController),
      sourceLevel: readIntValue(request['level']),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${request['sourceName']} → ${request['targetName']} · Corruzione · DT ${request['attack']}',
          ),
          Text(
            canRoll
                ? 'Resisti con Crepa o Fermezza${penalty > 0 ? ' (−3 a livello pari)' : ''}. Il primo tiro è gratuito.'
                : 'Livello inferiore alla fonte: si applica la resistenza percentuale.',
          ),
          Wrap(
            spacing: 8,
            children: [
              if (canRoll)
                for (final entry in {
                  'crepa': 'Crepa',
                  'fermezza': 'Fermezza',
                }.entries)
                  OutlinedButton(
                    onPressed:
                        onlineCombatResolving.contains('${request['id']}')
                        ? null
                        : () => defendCorruptionApplication(request, entry.key),
                    child: Text('${entry.value}${penalty > 0 ? ' −3' : ''}'),
                  ),
              TextButton(
                onPressed: onlineCombatResolving.contains('${request['id']}')
                    ? null
                    : () => defendCorruptionApplication(request, 'accept'),
                child: const Text('Applica solo resistenza passiva'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> manualPartyHealing() async {
    final origin = currentSheetScrollId();
    final controller = TextEditingController();
    final amount = await showDialog<int>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Cura · valore concordato con il Master'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Vita da recuperare'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0 && value <= 1000000) {
                Navigator.pop(dialog, value);
              }
            },
            child: const Text('Scegli destinatario'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || amount == null || currentSheetScrollId() != origin) return;
    activeStructuredEffects.add({
      'type': 'pending_target',
      'source': 'Cura concordata',
      'effect': OculumStructuredEffect(
        type: 'cura',
        recipient: 'alleato',
        valueExpression: '$amount',
        duration: '0',
      ).toJson(),
    });
    await deliverPendingSupport();
  }

  Future<Map<String, dynamic>?> chooseHelpTarget({String? sourceTag}) async {
    final own = sourceTag ?? sheetTagAt(schedaCorrente);
    final online = realtimeService?.isConnected == true;
    final candidates = online
        ? onlineCombatTokens()
              .where(
                (t) =>
                    onlineCombatTokenTag(t) != own &&
                    !const {'dead', 'fled', 'expired'}.contains(t['status']),
              )
              .toList()
        : [
            for (var i = 0; i < schedePersonaggio.length; i++)
              if (sheetTagAt(i) != own &&
                  schedePersonaggio[i]['realtimeSharedSheet'] != true)
                {'sheetTag': sheetTagAt(i), 'name': nomeSchedaPersonaggio(i)},
          ];
    if (candidates.isEmpty) return null;
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: const Text('Chi vuoi aiutare?'),
        children: [
          for (final token in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, token),
              child: Text('${token['name'] ?? '???'}'),
            ),
        ],
      ),
    );
  }

  Color combatTargetColor(Map<String, dynamic> token) {
    final tag = onlineCombatTokenTag(token);
    if (tag == sheetTagAt(schedaCorrente)) return Colors.greenAccent;
    final own = onlineCombatTokens()
        .where((t) => onlineCombatTokenTag(t) == sheetTagAt(schedaCorrente))
        .firstOrNull;
    return '${token['side'] ?? 'ally'}' == '${own?['side'] ?? 'ally'}'
        ? Colors.lightBlueAccent
        : Colors.redAccent;
  }

  Future<void> deliverPendingSupport({
    int minimum = 1,
    int maximum = 1,
    List<String>? selectedTags,
    bool excludeSelf = false,
    String? sourcePrefix,
  }) async {
    final origin = currentSheetScrollId();
    final pending = activeStructuredEffects
        .where(
          (e) =>
              e['type'] == 'pending_target' &&
              e['effect'] is Map &&
              (e['effect'] as Map)['recipient'] == 'alleato' &&
              (sourcePrefix == null ||
                  '${e['source'] ?? ''}'.startsWith(sourcePrefix)),
        )
        .toList();
    if (pending.isEmpty) {
      return;
    }
    final online = realtimeService?.isConnected == true;
    final encounter = onlineCombatEncounterId;
    final own = sheetTagAt(schedaCorrente);
    final candidates = online
        ? onlineCombatTokens()
              .where(
                (t) => !const {'dead', 'fled', 'expired'}.contains(t['status']),
              )
              .toList()
        : <Map<String, dynamic>>[
            for (var i = 0; i < schedePersonaggio.length; i++)
              if (schedePersonaggio[i]['realtimeSharedSheet'] != true)
                {
                  'sheetTag': sheetTagAt(i),
                  'name': nomeSchedaPersonaggio(i),
                  'side': 'ally',
                },
          ];
    if (!candidates.any((t) => onlineCombatTokenTag(t) == own)) {
      return;
    }
    final selectable = excludeSelf
        ? candidates.where((t) => onlineCombatTokenTag(t) != own).toList()
        : candidates;
    if (selectable.isEmpty) return;
    final counts = <String, int>{};
    final selected =
        selectedTags ??
        await showDialog<List<String>>(
          context: context,
          builder: (dialog) => StatefulBuilder(
            builder: (context, update) {
              final count = counts.values.fold<int>(0, (a, b) => a + b);
              return AlertDialog(
                title: const Text('Supporto · scegli i destinatari'),
                content: SizedBox(
                  width: 480,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .6,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Selezionati $count · da $minimum a $maximum. I destinatari mancanti saranno scelti tra quelli segnati.',
                          ),
                          for (final token in selectable)
                            Builder(
                              builder: (_) {
                                final tag = onlineCombatTokenTag(token);
                                final n = counts[tag] ?? 0;
                                return ListTile(
                                  leading: Icon(
                                    Icons.person_outline,
                                    color: combatTargetColor(token),
                                  ),
                                  title: Text(
                                    tag == own
                                        ? 'Se stessi'
                                        : '${token['name'] ?? '???'}',
                                  ),
                                  subtitle: n > 0
                                      ? Text('Applicazioni: $n')
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Rimuovi destinatario',
                                        onPressed: n == 0
                                            ? null
                                            : () => update(() {
                                                if (n == 1) {
                                                  counts.remove(tag);
                                                } else {
                                                  counts[tag] = n - 1;
                                                }
                                              }),
                                        icon: const Icon(Icons.remove),
                                      ),
                                      IconButton(
                                        tooltip: 'Aggiungi destinatario',
                                        onPressed: count >= maximum
                                            ? null
                                            : () => update(
                                                () => counts[tag] = n + 1,
                                              ),
                                        icon: const Icon(Icons.add),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: const Text('Annulla'),
                  ),
                  FilledButton(
                    onPressed: count == 0
                        ? null
                        : () {
                            final result = [
                              for (final e in counts.entries)
                                for (var i = 0; i < e.value; i++) e.key,
                            ];
                            final keys = counts.keys.toList();
                            final random = Random();
                            while (result.length < minimum) {
                              result.add(keys[random.nextInt(keys.length)]);
                            }
                            Navigator.pop(dialog, result);
                          },
                    child: const Text('Applica supporto'),
                  ),
                ],
              );
            },
          ),
        );
    if (!mounted ||
        selected == null ||
        selected.length < minimum ||
        selected.length > maximum ||
        currentSheetScrollId() != origin ||
        online && encounter != onlineCombatEncounterId) {
      return;
    }
    final valid = (online ? onlineCombatTokens() : candidates)
        .map(onlineCombatTokenTag)
        .toSet();
    if (selected.any(
      (tag) => !valid.contains(tag) || (excludeSelf && tag == own),
    )) {
      return;
    }
    final effects = [
      for (final e in pending) Map<String, dynamic>.from(e['effect'] as Map),
    ];
    final group = 'support:$own:${DateTime.now().microsecondsSinceEpoch}';
    activeStructuredEffects.removeWhere((e) => pending.contains(e));
    for (var hit = 0; hit < selected.length; hit++) {
      final tag = selected[hit];
      final target = candidates.firstWhere(
        (t) => onlineCombatTokenTag(t) == tag,
      );
      if (online) {
        final request = <String, dynamic>{
          'id': '$group:$hit',
          'kind': 'help',
          'helpMode': 'effects',
          'helpBonus': 0,
          'effects': effects,
          'status': 'pending',
          'scope': permissionScope,
          'encounterId': encounter,
          'sourceTag': own,
          'sourceName': realtimeDisplayName(),
          'targetTag': tag,
          'targetName': '${target['name'] ?? '???'}',
        };
        attachPendingCombatTurnResources(request);
        onlineCombatRequests['${request['id']}'] = request;
        receiveCombatHelp(permissionEnvelope(request));
        await realtimeService?.sendCombatEvent(
          'combat_help',
          permissionEnvelope(request),
        );
      } else {
        final index = localSheetIndexForOculumTag(tag);
        if (index < 0) {
          continue;
        }
        for (final effect in effects) {
          final temporary = <String, dynamic>{
            'effect': effect,
            'source': 'Supporto',
            'type': 'pending_target',
          };
          activeStructuredEffects.add(temporary);
          await applyPendingTargetEffectLocally(
            temporary,
            selectedIndex: index,
          );
          if (!mounted || currentSheetScrollId() != origin) return;
        }
      }
      aggiungiLog('[SUPPORTO] ${target['name'] ?? tag}: effetti inviati.');
    }
    programmaSalvataggio();
    if (mounted) setState(() {});
  }

  int consumeCombatHelp() {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return 0;
    }
    final sheet = schedePersonaggio[schedaCorrente];
    var bonus = readIntValue(
      sheet['combatHelpPending'],
    ).clamp(-1000000, 1000000);
    final gratitudeEffects = activeStructuredEffects
        .where(
          (effect) =>
              effect['mode'] == 'prossima_azione' &&
              normalizedStructuredTarget('${effect['target'] ?? ''}') ==
                  'tiro_globale' &&
              ('${effect['source'] ?? ''}'.startsWith('Reazione Fulminea') ||
                  '${effect['effectId'] ?? ''}'.startsWith(
                    'gratitudine_next_action_',
                  )),
        )
        .toList();
    for (final effect in gratitudeEffects) {
      bonus += readIntValue(effect['value']);
    }
    if (gratitudeEffects.isNotEmpty) {
      activeStructuredEffects.removeWhere(gratitudeEffects.contains);
      invalidateDerivedDataCaches(notifyHiddenEyeCards: false);
    }
    if (bonus != 0) {
      sheet['combatHelpPending'] = 0;
      aggiungiLog(
        '[AIUTO CONSUMATO] ${bonus >= 0 ? '+' : ''}$bonus nel prossimo tiro.',
      );
      programmaSalvataggio();
    }
    return bonus;
  }

  void applySupportToOwnedSheet(
    int index,
    List<OculumStructuredEffect> effects,
    String source,
  ) {
    final original = schedaCorrente;
    final switching = index != original;
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    try {
      if (switching) {
        schedaCorrente = index;
        caricaStatoDaJson(schedePersonaggio[index]);
        ripristinaImpostazioniGlobali(global);
        selectSharedEncounterForCurrentSheet();
      }
      for (final message in applyStructuredEffectsOnActivation(
        effects,
        source: source,
      )) {
        aggiungiLog('[SUPPORTO RICEVUTO] $message');
      }
      salvaSchedaCorrenteInMemoria();
    } finally {
      if (switching) {
        schedaCorrente = original;
        caricaStatoDaJson(schedePersonaggio[original]);
        ripristinaImpostazioniGlobali(global);
      }
    }
    sendRealtimeSheetToStaffAt(index, force: true, ensureMasterReceipt: true);
    syncSharedSheetToMasterEncounters(index);
  }

  void receiveCombatHelp(Map<String, dynamic> payload) {
    if (!validPermissionSender(payload) ||
        payload['encounterId'] != onlineCombatEncounterId) {
      return;
    }
    final tags = onlineCombatTokens().map(onlineCombatTokenTag).toSet();
    final id = '${payload['id'] ?? ''}';
    final source = '${payload['sourceTag'] ?? ''}',
        target = '${payload['targetTag'] ?? ''}';
    if (id.isEmpty ||
        id.length > 160 ||
        (payload['senderTag'] != source &&
            !const {'master', 'coMaster'}.contains(payload['senderRole'])) ||
        (source == target && payload['helpMode'] != 'effects') ||
        !tags.contains(source) ||
        !tags.contains(target)) {
      return;
    }
    if (!controlsOnlineCombatSheet(target)) return;
    final existing = onlineCombatRequests[id];
    if (existing?['received'] == true) {
      unawaited(sendCombatAcknowledgement(existing!, 'help'));
      return;
    }
    if (payload['helpMode'] == 'effects') {
      if (payload['effects'] is! List) {
        return;
      }
      final effects = (payload['effects'] as List)
          .whereType<Map>()
          .take(30)
          .map(
            (raw) =>
                OculumStructuredEffect.fromJson(Map<String, dynamic>.from(raw))
                  ..recipient = 'se_stesso',
          )
          .toList();
      // Only frozen numeric formulas are accepted; do not roll or reevaluate caster stats.
      if (effects.any(
        (e) =>
            num.tryParse(e.valueExpression) == null ||
            e.diceExpression.isNotEmpty ||
            int.tryParse(e.duration) == null,
      )) {
        return;
      }
      onlineCombatRequests[id] = {
        ...payload,
        'kind': 'help',
        'received': true,
        'status': 'resolved',
      };
      applySupportToOwnedSheet(
        localSheetIndexForOculumTag(target),
        effects,
        '${payload['sourceName']} · supporto $id',
      );
      unawaited(sendCombatAcknowledgement(onlineCombatRequests[id]!, 'help'));
      programmaSalvataggio();
      if (mounted) setState(() {});
      return;
    }
    final bonus = readIntValue(payload['helpBonus']).clamp(-1000000, 1000000);
    final index = localSheetIndexForOculumTag(target);
    if (index < 0) return;
    onlineCombatRequests[id] = {
      ...payload,
      'kind': 'help',
      'status': 'resolved',
      'received': true,
    };
    schedePersonaggio[index]['combatHelpPending'] =
        readIntValue(
          schedePersonaggio[index]['combatHelpPending'],
        ).clamp(-1000000, 1000000) +
        bonus;
    combatLogFor(
      target,
      '[AIUTA COMPAGNO] ${payload['sourceName']} aiuta ${payload['targetName']}: ${bonus >= 0 ? '+' : ''}$bonus al prossimo tiro.',
    );
    unawaited(sendCombatAcknowledgement(onlineCombatRequests[id]!, 'help'));
    programmaSalvataggio();
    if (mounted) setState(() {});
  }

  void receiveCorruptionApplication(Map<String, dynamic> payload) {
    if (!validPermissionSender(payload) ||
        payload['encounterId'] != onlineCombatEncounterId) {
      return;
    }
    final phase = '${payload['phase'] ?? 'request'}';
    if (phase == 'result') {
      if (!validPermissionSender(payload, staff: true)) return;
      var ownRequest = onlineCombatRequests['${payload['id']}'];
      if (ownRequest == null && payload['fromMastery'] == true) {
        final parent = onlineCombatRequests['${payload['attackRequestId']}'];
        if (parent != null &&
            parent['sourceTag'] == payload['sourceTag'] &&
            parent['targetTag'] == payload['targetTag'] &&
            payload['id'] == 'mastery:${parent['id']}' &&
            (parent['effects'] as List? ?? const []).whereType<Map>().any(
              (effect) =>
                  effect['appliedState'] == 'corruzione' &&
                  '${effect['resource']}'.startsWith('corruption_mastery:'),
            )) {
          ownRequest = <String, dynamic>{
            ...parent,
            'id': payload['id'],
            'kind': 'corruption',
            'status': 'pending',
          };
          onlineCombatRequests['${payload['id']}'] = ownRequest;
        }
      }
      if (ownRequest == null ||
          ownRequest['sourceTag'] != payload['corruptorTag'] ||
          ownRequest['targetTag'] != payload['targetTag'] ||
          ownRequest['status'] == 'resolved') {
        return;
      }
      ownRequest.addAll({...payload, 'status': 'resolved'});
      if (realtimeIsMasterRole ||
          '${payload['corruptorTag'] ?? ''}' != sheetTagAt(schedaCorrente)) {
        return;
      }
      final targetName = '${payload['targetName'] ?? payload['targetTag']}';
      final roll = readIntValue(payload['roll']);
      final chance = readIntValue(payload['chancePercent']);
      combatLogFor(
        '${payload['corruptorTag']}',
        payload['corruptionResisted'] == true
            ? '[CORRUZIONE] $targetName resiste con ${payload['corruptionDefenseChoice']} ${payload['corruptionDefense']} contro ${payload['attack']}.'
            : payload['infected'] == true
            ? '[CORRUZIONE] $targetName infettato: d100 $roll ≤ $chance%.'
            : '[CORRUZIONE] $targetName resiste: d100 $roll > $chance%.',
      );
      return;
    }
    if (!realtimeIsMasterRole || phase != 'request') return;
    final senderTag = '${payload['senderTag'] ?? ''}';
    final corruptorTag = '${payload['sourceTag'] ?? ''}';
    final targetTag = '${payload['targetTag'] ?? ''}';
    final requestId = '${payload['id'] ?? ''}';
    if (senderTag != corruptorTag ||
        requestId.isEmpty ||
        requestId.length > 160 ||
        targetTag.isEmpty) {
      return;
    }
    final existing = onlineCombatRequests[requestId];
    if (existing != null) {
      if (existing['sourceTag'] == corruptorTag &&
          existing['targetTag'] == targetTag &&
          existing['status'] == 'resolved') {
        unawaited(
          realtimeService?.sendCombatEvent(
            'corruption_apply',
            permissionEnvelope(existing),
          ),
        );
      }
      return;
    }
    final tokens = onlineCombatTokens();
    final sourceToken = tokens
        .where((token) => onlineCombatTokenTag(token) == corruptorTag)
        .firstOrNull;
    final targetToken = tokens
        .where((token) => onlineCombatTokenTag(token) == targetTag)
        .firstOrNull;
    if (sourceToken == null ||
        targetToken == null ||
        targetToken['side'] == sourceToken['side'] ||
        const {'dead', 'fled', 'expired'}.contains(targetToken['status'])) {
      return;
    }
    // Mastery is generated by the defender from a resolved attack, never by
    // sending a scroll request with a client-supplied hit counter.
    if (payload['fromMastery'] == true) return;
    final targetIndex = localSheetIndexForOculumTag(targetTag);
    if (targetIndex < 0) return;
    if (!_applyIncomingCombatTurnResources('corruption_apply', payload)) return;
    queueCorruptionApplication(
      targetTag: targetTag,
      scrollGrade: readIntValue(payload['scrollGrade']).clamp(0, 12),
      sourceTag: corruptorTag,
      sourceName: '${payload['sourceName'] ?? 'Pergamena Nera'}',
      sourceTotal: readIntValue(payload['attack']),
      sourceLevel: readIntValue(sourceToken['level']),
      requestId: requestId,
    );
    if (mounted) setState(() {});
  }

  Future<void> deliverCombatHelp(
    Map<String, dynamic> target,
    int bonus, {
    String? sourceTag,
    String? sourceName,
  }) async {
    final helperTag = sourceTag ?? sheetTagAt(schedaCorrente);
    final helperName = sourceName ?? realtimeDisplayName();
    final tag = onlineCombatTokenTag(target);
    final name = '${target['name'] ?? '???'}';
    aggiungiLog(
      '[AIUTA COMPAGNO] $helperName → $name: ${bonus >= 0 ? '+' : ''}$bonus al prossimo tiro.',
    );
    if (realtimeService?.isConnected == true) {
      final request = <String, dynamic>{
        'id': 'help:$helperTag:${DateTime.now().microsecondsSinceEpoch}',
        'kind': 'help',
        'status': 'pending',
        'scope': permissionScope,
        'encounterId': onlineCombatEncounterId,
        'sourceTag': helperTag,
        'sourceName': helperName,
        'targetTag': tag,
        'targetName': name,
        'helpBonus': bonus.clamp(-1000000, 1000000),
      };
      attachPendingCombatTurnResources(request);
      onlineCombatRequests['${request['id']}'] = request;
      receiveCombatHelp(permissionEnvelope(request));
      await realtimeService?.sendCombatEvent(
        'combat_help',
        permissionEnvelope(request),
      );
    } else {
      final index = localSheetIndexForOculumTag(tag);
      if (index >= 0) {
        schedePersonaggio[index]['combatHelpPending'] =
            readIntValue(
              schedePersonaggio[index]['combatHelpPending'],
            ).clamp(-1000000, 1000000) +
            bonus.clamp(-1000000, 1000000);
        combatLogFor(
          tag,
          '[AIUTA COMPAGNO] $helperName: ${bonus >= 0 ? '+' : ''}$bonus al prossimo tiro.',
        );
      }
    }
    programmaSalvataggio();
  }

  String combatDamageReceiptText(Map<String, dynamic> receipt) {
    int amount(String key) => readIntValue(receipt[key]).clamp(0, 100000000);
    return 'Scudo Oculum −${amount('oculumShieldLost')} · '
        'Scudo −${amount('shieldLost')} · '
        'HP temporanei −${amount('temporaryHpLost')} · '
        'Vita −${amount('hpLost')}'
        '${receipt['pawnPending'] == true ? ' · intercettazione Pawn in attesa' : ''}';
  }

  String get onlineCombatEncounterId =>
      realtimeService?.isConnected != true || realtimeIsMasterRole
      ? selectedMasterInitiativeGroupId
      : '${realtimeVisibleInitiativeSnapshot['encounterId'] ?? ''}';

  List<Map<String, dynamic>> onlineCombatTokens() {
    if (realtimeService?.isConnected != true) return [];
    final raw = realtimeIsMasterRole
        ? masterInitiativeTokens
        : realtimeVisibleInitiativeSnapshot['tokens'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((t) => Map<String, dynamic>.from(t))
        .toList();
  }

  String onlineCombatTokenTag(Map<String, dynamic> token) =>
      realtimeIsMasterRole
      ? publicInitiativeSourceTag(token)
      : '${token['sheetTag'] ?? token['id'] ?? ''}';

  List<Map<String, dynamic>> onlineAttackTokens() {
    final tokens = onlineCombatTokens();
    final own = sheetTagAt(schedaCorrente);
    if (!tokens.any(
      (t) =>
          onlineCombatTokenTag(t) == own &&
          !const {'dead', 'fled', 'expired'}.contains(t['status']),
    )) {
      return [];
    }
    return tokens
        .where(
          (t) =>
              onlineCombatTokenTag(t).isNotEmpty &&
              onlineCombatTokenTag(t) != own &&
              !const {'dead', 'fled', 'expired'}.contains(t['status']),
        )
        .toList();
  }

  Future<void> planOnlineAttack({
    String? targetId,
    String? freeReactionId,
    String? schiantoReactionId,
    String initialChoice = 'vc',
    int minimumTargets = 1,
    int maximumTargets = 1,
    int? preparedAttackTotal,
    int? preparedAttackNatural,
  }) async {
    synchronizeFightStartCooldowns();
    if (freeReactionId == null && maximumTargets == 1) {
      for (final effect in activeStructuredEffects.where(
        (e) => e['type'] == 'pending_target',
      )) {
        minimumTargets = max(
          minimumTargets,
          readIntValue(effect['minimumTargets'], fallback: 1),
        );
        maximumTargets = max(
          maximumTargets,
          readIntValue(effect['maximumTargets'], fallback: 1),
        );
      }
    }
    final tokens = onlineAttackTokens();
    if (tokens.isEmpty) return;
    final origin = currentSheetScrollId();
    final encounter = onlineCombatEncounterId;
    final freeReaction = onlineCombatRequests[freeReactionId];
    final counterBonus = freeReaction?['doubleDefense'] == true ? 9 : 0;
    if (freeReactionId != null &&
        (freeReaction?['freeReaction'] != true ||
            freeReaction?['reactionUsed'] == true ||
            freeReaction?['targetTag'] != sheetTagAt(schedaCorrente))) {
      return;
    }
    final schiantoReaction = onlineCombatRequests[schiantoReactionId];
    final schiantoBonus =
        schiantoReactionId != null &&
            schiantoReaction?['schiantoActionSkipped'] == true &&
            schiantoReaction?['schiantoReactionUsed'] != true &&
            schiantoReaction?['targetTag'] == sheetTagAt(schedaCorrente) &&
            readIntValue(
                  schedePersonaggio[schedaCorrente]['combatSchiantoReactionBonusPending'],
                ) >=
                10
        ? 10
        : 0;
    if (schiantoReactionId != null && schiantoBonus == 0) return;
    final byId = {
      for (final token in tokens) onlineCombatTokenTag(token): token,
    };
    final subs = hiddenEyeStats.where(oculumCombatSubtraitSelectable).toList();
    const first = ['schianto', 'forza', 'riflessi'];
    subs.sort((a, b) {
      final ai = first.indexOf(a.id), bi = first.indexOf(b.id);
      return (ai < 0 ? 99 : ai).compareTo(bi < 0 ? 99 : bi);
    });
    final choices = [
      OculumAttackChoice(
        'vc',
        'VC · attacco',
        vc() + counterBonus,
        color: Colors.redAccent,
      ),
      for (final stat in subs)
        OculumAttackChoice(
          stat.id,
          stat.nome,
          hiddenEyeTotal(stat) +
              hiddenEyeStatRollQuickBonus(stat) +
              tiroGlobaleBonus() +
              counterBonus +
              (stat.id == 'schianto' ? schiantoBonus : 0),
          color: hiddenEyeStatIdentityColor(stat),
        ),
    ];
    final sourceSheet = schedePersonaggio[schedaCorrente];
    final sourceMonsterId = '${sourceSheet['monsterBookSourceId'] ?? ''}';
    final preparedIds = activeStructuredEffects
        .where((e) => e['type'] == 'pending_target' && e['effect'] is Map)
        .map((e) => '${(e['effect'] as Map)['id']}')
        .toList();
    final preparedEffects = activeStructuredEffects
        .where((e) => e['type'] == 'pending_target' && e['effect'] is Map)
        .map((e) => e['effect'] as Map)
        .toList();
    final suicideExplosion =
        preparedEffects.any((e) => readBoolValue(e['killSource'])) ||
        preparedIds.any((id) => id.startsWith('goblin_kamikaze_explosion_'));
    final independentTargetDamage =
        preparedEffects.any((e) => readBoolValue(e['damagePerTarget'])) ||
        suicideExplosion ||
        preparedIds.contains('runic_open_current_hp');
    final allOpponents =
        preparedEffects.any((e) => readBoolValue(e['allOpponents'])) ||
        suicideExplosion;
    final isElementCollector = oculumIsElementCollector(sourceMonsterId);
    final adaptationState = sourceSheet['combatElementalAdaptation'] is Map
        ? Map<String, dynamic>.from(
            sourceSheet['combatElementalAdaptation'] as Map,
          )
        : const <String, dynamic>{};
    final collectedElements = oculumMonsterCollectedElements(adaptationState);
    final attackElements = isElementCollector && collectedElements.isNotEmpty
        ? collectedElements
        : allDamageElementIds();
    final replayElement = isElementCollector
        ? oculumMonsterCollectedElement(adaptationState)
        : '';
    final ownSide =
        onlineCombatTokens()
            .where((t) => onlineCombatTokenTag(t) == sheetTagAt(schedaCorrente))
            .firstOrNull?['side'] ??
        'ally';
    final explosionTargets = tokens
        .where((t) => (t['side'] ?? 'ally') != ownSide)
        .map(onlineCombatTokenTag)
        .toList();
    if (allOpponents && explosionTargets.isEmpty) return;
    final plan = allOpponents
        ? OculumAttackPlan(
            explosionTargets.first,
            'vc',
            'Esplosione suicida',
            additionalTargetIds: explosionTargets.skip(1).toList(),
            element: 'fuoco',
          )
        : await showDialog<OculumAttackPlan>(
            context: context,
            builder: (_) => OculumAttackPlanner(
              targets: {
                for (final e in byId.entries)
                  e.key: '${e.value['name'] ?? '???'}',
              },
              elements: [
                for (final element in attackElements)
                  OculumCombatElement(
                    element,
                    elementDisplayName(element),
                    elementColor(element),
                  ),
              ],
              initialElement: replayElement.isNotEmpty
                  ? replayElement
                  : elementoDannoDominante(),
              initialTarget: targetId,
              initialChoice: initialChoice,
              minimumTargets: minimumTargets.clamp(1, 100),
              maximumTargets: maximumTargets.clamp(1, 100),
              choices: choices,
              chance: (tag, option) {
                // Never derive hidden enemy statistics from a replicated private
                // sheet. Even Master views use the Percezione result shown to the
                // acting participant, rather than silently revealing a target.
                final known = discoveredCombatTarget(tag);
                if (slotMachineRollsEnabled) {
                  return const OculumAttackChanceEstimate.hidden(
                    'Probabilità nascoste con i tiri casuali.',
                  );
                }
                if (known == null) {
                  return const OculumAttackChanceEstimate.hidden(
                    'Usa Percezione sul bersaglio per leggere le probabilità.',
                  );
                }
                final reveal = '${known['reveal'] ?? 'insufficient'}';
                if (reveal != OculumCombatScoutReveal.exact.name &&
                    reveal != OculumCombatScoutReveal.approximate.name) {
                  return const OculumAttackChanceEstimate.hidden(
                    'Non senti abbastanza del bersaglio.',
                  );
                }
                final defense = readIntValue(known['cm']);
                final forecast = OculumAttackForecast.fromRolls(
                  [
                    for (var die = 1; die <= 20; die++)
                      rollTotalWithCritical(die, 20, [option.bonus]),
                  ],
                  [
                    for (var die = 1; die <= 20; die++)
                      rollTotalWithCritical(
                        die,
                        20,
                        [defense],
                        level: readIntValue(known['level']),
                        grade: readIntValue(known['grade']),
                        difficulty: readIntValue(known['rollDifficulty']),
                      ),
                  ],
                  difficulty: normalizedCampaignDifficulty(),
                );
                return OculumAttackChanceEstimate(
                  forecast,
                  approximate:
                      reveal == OculumCombatScoutReveal.approximate.name,
                );
              },
            ),
          );
    if (!mounted ||
        plan == null ||
        currentSheetScrollId() != origin ||
        realtimeService?.isConnected != true ||
        encounter != onlineCombatEncounterId) {
      return;
    }
    final requiredReactionTarget = freeReactionId != null
        ? (freeReaction == null ? null : freeReaction['sourceTag'])
        : (schiantoReaction == null ? null : schiantoReaction['sourceTag']);
    if ((freeReactionId != null || schiantoReactionId != null) &&
        (plan.targetIds.length != 1 ||
            plan.targetId != requiredReactionTarget)) {
      return;
    }
    final controlledPlan = await redirectCorruptedAttack(plan);
    if (!mounted ||
        controlledPlan == null ||
        currentSheetScrollId() != origin ||
        encounter != onlineCombatEncounterId) {
      return;
    }
    final currentIds = {
      for (final token in onlineAttackTokens()) onlineCombatTokenTag(token),
    };
    if (controlledPlan.targetIds.any((id) => !currentIds.contains(id)) ||
        controlledPlan.targetIds.length < minimumTargets ||
        controlledPlan.targetIds.length > maximumTargets) {
      return;
    }
    if (freeReactionId == null &&
        schiantoReactionId == null &&
        !await spendCombatRollResource()) {
      return;
    }
    if (!mounted ||
        currentSheetScrollId() != origin ||
        encounter != onlineCombatEncounterId) {
      return;
    }
    final target = controlledPlan.targetIds
        .map((tag) => '${byId[tag]!['name'] ?? '???'}')
        .join(', ');
    final label =
        'Attacco contro $target${controlledPlan.reason.isEmpty ? '' : ' · ${controlledPlan.reason}'}';
    final preparedDamage = dannoTotale();
    final element = oculumNormalizeElementId(controlledPlan.element);
    final sourceTag = sheetTagAt(schedaCorrente);
    final corruptionMastery = skills
        .where(
          (skill) =>
              skill.scrollData['kind'] == 'corruption' ||
              oculumNormalizeText(skill.nome) == 'padrone della corruzione',
        )
        .firstOrNull;
    final targetEffects = [
      if (activeStructuredEffectBonus('runic_wound_penalty') > 0)
        OculumStructuredEffect(
          id: 'runic_wound_on_hp',
          type: 'difesa',
          target: 'difesa',
          valueExpression:
              '${-activeStructuredEffectBonus('runic_wound_penalty')}',
          duration: '1',
          mode: 'temporaneo',
        ).toJson(),
      for (final e in activeStructuredEffects)
        if (e['type'] == 'pending_target' &&
            e['effect'] is Map &&
            (e['effect'] as Map)['recipient'] != 'alleato')
          {
            ...Map<String, dynamic>.from(e['effect'] as Map),
            'areaDamageBonusPerTarget': readIntValue(e['damageBonusPerTarget']),
          },
    ];
    final directDamage = targetEffects
        .where((e) => e['type'] == 'danno')
        .toList();
    final manifestationTotal = hiddenEyeStats
        .where((stat) => stat.id == 'manifestazione_potere')
        .firstOrNull;
    final manifestationDamageBonus =
        controlledPlan.choiceId == 'manifestazione_potere'
        ? oculumManifestationAttackDamageBonus(
            manifestationTotal: manifestationTotal == null
                ? 0
                : hiddenEyeTotal(manifestationTotal),
            level: leggiNumero(livelloController),
          )
        : 0;
    var attackOculumDamageBonus = 0;
    final flatDamageBonus =
        bonusDannoPiatto() +
        manifestationDamageBonus +
        directDamage.fold<int>(
          0,
          (sum, e) => sum + readIntValue(e['areaDamageBonusPerTarget']),
        );
    final abilityDamageBonus = directDamage.fold<int>(
      0,
      (sum, e) => sum + max(0, readIntValue(e['valueExpression'])),
    );
    final baseDamage = oculumAttackDamageWithAbilityBonus(
      preparedDamage: preparedDamage,
      fixedBonuses: flatDamageBonus,
      abilityDamageBonus: abilityDamageBonus,
    );
    final concentrationSheet = schedePersonaggio[schedaCorrente];
    final concentrationPending =
        concentrationSheet['combatConcentrationPending'] == true;
    final unboostedDamagePerTarget = oculumDamagePerTarget(
      baseDamage,
      controlledPlan.targetIds.length,
      flatBonusPerTarget: flatDamageBonus,
    );
    final damagePerTarget = concentrationPending
        ? (unboostedDamagePerTarget * 1.10).ceil()
        : unboostedDamagePerTarget;
    if (controlledPlan.targetIds.length > 1) {
      aggiungiLog(
        '[DANNI AD AREA] Danno base $baseDamage ÷ ${controlledPlan.targetIds.length} colpi, arrotondato per eccesso, + bonus piatto $flatDamageBonus per ogni bersaglio = $damagePerTarget danni a bersaglio. Ogni bersaglio risolve la propria difesa e le proprie resistenze.',
      );
    }
    if (manifestationDamageBonus > 0) {
      aggiungiLog(
        '[MANIFESTAZIONE DEL POTERE] +$manifestationDamageBonus danni per bersaglio (+3 × livello), applicati una volta a ogni bersaglio colpito.',
      );
    }
    final precisionStat = controlledPlan.choiceId == 'precisione'
        ? hiddenEyeStats.where((stat) => stat.id == 'precisione').firstOrNull
        : null;
    final precisionTotal = precisionStat == null
        ? 0
        : hiddenEyeTotal(precisionStat);
    final id = '$sourceTag:${DateTime.now().microsecondsSinceEpoch}';
    if (freeReaction != null) {
      freeReaction['reactionUsed'] = true;
      freeReaction['counterAttackId'] = id;
    }
    aggiungiLog(
      '[ATTACCO] $label · ${choices.firstWhere((c) => c.id == controlledPlan.choiceId).name}.${controlledPlan.choiceId == 'vc' ? '' : ' Descrivi l’attacco al Master, anche a voce.'}',
    );
    void resolved(int natural, int total) {
      total +=
          counterBonus +
          (controlledPlan.choiceId == 'schianto' ? schiantoBonus : 0);
      if (!mounted ||
          currentSheetScrollId() != origin ||
          encounter != onlineCombatEncounterId) {
        return;
      }
      if (concentrationPending) {
        concentrationSheet['combatConcentrationPending'] = false;
        aggiungiLog(
          '[CONCENTRAZIONE] +10% Danni applicato una sola volta alla quota di questo attacco.',
        );
      }
      if (schiantoReactionId != null && schiantoReaction != null) {
        schiantoReaction['schiantoReactionUsed'] = true;
        concentrationSheet.remove('combatSchiantoReactionBonusPending');
        aggiungiLog(
          '[SCHIANTO] Reazione consumata: +10 a Schianto contro l’attaccante.',
        );
      }
      final attackRollDamageBonus = oculumAttackRollDamageBonus(
        sourceTexts: <String>[
          for (final title in titoliCalcolabili)
            if (title.equipaggiato) ...activeTitleQuickTexts(title),
          for (final art in arti)
            if (art.sbloccata && art.inUso) ...activeArtQuickTexts(art),
          for (final item in inventario)
            if (item.equipaggiata) ...activeItemQuickTexts(item),
          for (final skill in skills)
            if (skill.equipaggiata) ...skillQuickCommandTexts(skill),
          buffMalusRapidiController.text,
        ],
        attackChoiceId: controlledPlan.choiceId,
        rollTotal: total,
      );
      final resolvedFlatDamageBonus =
          flatDamageBonus + attackRollDamageBonus + attackOculumDamageBonus;
      final resolvedDamagePerTarget = independentTargetDamage
          ? abilityDamageBonus + attackOculumDamageBonus
          : concentrationPending
          ? (oculumDamagePerTarget(
                      baseDamage,
                      controlledPlan.targetIds.length,
                      flatBonusPerTarget: resolvedFlatDamageBonus,
                    ) *
                    1.10)
                .ceil()
          : oculumDamagePerTarget(
              baseDamage,
              controlledPlan.targetIds.length,
              flatBonusPerTarget: resolvedFlatDamageBonus,
            );
      if (attackRollDamageBonus > 0) {
        aggiungiLog(
          '[FORMULA DEL TIRO] $controlledPlan.choiceId $total: +$attackRollDamageBonus Danni per bersaglio dalla formula del dado, arrotondata per difetto. Attacco multiplo: il bonus si applica a ogni bersaglio.',
        );
      }
      if (attackOculumDamageBonus > 0) {
        aggiungiLog(
          '[POTENZIAMENTO] +$attackOculumDamageBonus Danni per bersaglio dal Potenziamento Oculum speso nel tiro.',
        );
      }
      for (var hit = 0; hit < controlledPlan.targetIds.length; hit++) {
        final selectedTag = controlledPlan.targetIds[hit];
        final selectedToken = byId[selectedTag]!;
        final eligibleCorruptionPassive =
            corruptionMastery != null &&
            corruptionSkillCooldown(corruptionMastery).ready &&
            readIntValue(selectedToken['level']) >
                leggiNumero(livelloController) &&
            !targetEffects.any(
              (effect) =>
                  effect['type'] == 'stato' &&
                  effect['appliedState'] == 'corruzione',
            );
        final effectsForTarget = <Map<String, dynamic>>[
          ...targetEffects,
          if (eligibleCorruptionPassive)
            OculumStructuredEffect(
              id: 'corruption_mastery_on_hit',
              type: 'stato',
              recipient: 'nemico',
              appliedState: 'corruzione',
              valueExpression: '1',
              duration: '0',
              resource: 'corruption_mastery:$sourceTag',
              stackable: false,
            ).toJson(),
        ];
        final requestId = controlledPlan.targetIds.length == 1
            ? id
            : '$id:$hit:$selectedTag';
        final precisionHit = precisionStat == null
            ? const OculumPrecisionHitResult(
                fragilityStages: 0,
                receivedDamagePercent: 100,
              )
            : oculumPrecisionHitResult(
                precisionTotal: precisionTotal,
                percentileRoll: Random.secure().nextInt(100),
                customDamagePercent: 260 + Random.secure().nextInt(91),
              );
        final request = <String, dynamic>{
          'id': requestId,
          'scope': permissionScope,
          'encounterId': encounter,
          'sourceTag': sourceTag,
          if (eligibleCorruptionPassive)
            'corruptionControlChancePercent': readIntValue(
              corruptionMastery.scrollData['targetControlPercent'],
              fallback: oculumCorruptionMasteryTargetControlPercent,
            ).clamp(0, 100),
          if (isElementCollector) 'sourceMonsterBookId': sourceMonsterId,
          'sourceName': realtimeDisplayName(),
          'sourceMovement': movimento(),
          'targetTag': selectedTag,
          'targetName': '${byId[selectedTag]!['name'] ?? '???'}',
          'attackGroupId': id,
          'choice': controlledPlan.choiceId,
          if (effectsForTarget.isNotEmpty)
            'abilityName': activeStructuredEffects
                .where((effect) => effect['type'] == 'pending_target')
                .map((effect) => '${effect['source'] ?? ''}')
                .where((name) => name.isNotEmpty)
                .toSet()
                .join(' + '),
          'reason': controlledPlan.reason,
          'attack': total,
          'natural': natural,
          'damage':
              resolvedDamagePerTarget + corruptionRevengeDamage(selectedTag),
          'damageTotal':
              resolvedDamagePerTarget * controlledPlan.targetIds.length,
          'damageBasePacket': baseDamage,
          'damageBonusPerTarget':
              resolvedFlatDamageBonus + corruptionRevengeDamage(selectedTag),
          'damageTargetCount': controlledPlan.targetIds.length,
          if (precisionStat != null) ...{
            'precisionTotal': precisionTotal,
            'precisionFragilityStages': precisionHit.fragilityStages,
            'precisionDamagePercent': precisionHit.receivedDamagePercent,
          },
          'effects': effectsForTarget,
          'element': element,
          'level': activeCriticalLevel(),
          'grade': activeCriticalGrade(),
          'difficulty': normalizedCampaignDifficulty(),
          'forcedCritical':
              freeReactionId != null &&
              freeReaction?['criticalReaction'] == true,
          'reactionOf': freeReactionId,
          if (schiantoReactionId != null) ...{
            'schiantoReactionOf': schiantoReactionId,
            'schiantoReactionBonus': schiantoBonus,
          },
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        };
        onlineCombatRequests[requestId] = request;
        receiveLocalCombatAttack(request);
        unawaited(sendOnlineCombatRequest(request));
      }
      if (suicideExplosion) {
        currentHpController.text = '0';
        feriteMorte = _OculumHomeDeathRules.deathWoundLimit;
        sourceSheet['currentHp'] = '0';
        sourceSheet['feriteMorte'] = _OculumHomeDeathRules.deathWoundLimit;
        aggiungiLog(
          '[ESPLOSIONE SUICIDA] Il Goblin Kamikaze muore dopo aver lanciato l’attacco contro tutti gli avversari.',
        );
        syncCurrentSheetDeathStateToInitiative();
        sendRealtimeHpChanged();
      }
      programmaSalvataggio();
    }

    if (preparedAttackTotal != null) {
      resolved(preparedAttackNatural ?? 0, preparedAttackTotal);
    } else if (controlledPlan.choiceId == 'vc') {
      await tiraValoreSpeciale(
        'VC',
        vc(),
        applyGlobalRollModifier: false,
        actionLabel: label,
        onOculumDamageBonus: (bonus) => attackOculumDamageBonus = bonus,
        onResolved: resolved,
      );
    } else {
      final stat = hiddenEyeStats
          .where(
            (s) =>
                s.id == controlledPlan.choiceId &&
                oculumCombatSubtraitSelectable(s),
          )
          .firstOrNull;
      if (stat == null) return;
      await tiraSottotrattoOcchio(
        stat,
        actionLabel: label,
        appliesAttackDamageBonus: true,
        onOculumDamageBonus: (bonus) => attackOculumDamageBonus = bonus,
        onResolved: resolved,
      );
      if (!mounted || currentSheetScrollId() != origin) return;
      if (consumeNextAttackStructuredEffects()) {
        aggiungiLog(
          '$label · Danni per bersaglio $damagePerTarget, bonus del prossimo attacco consumati una sola volta.',
        );
      }
    }
  }

  bool controlsOnlineCombatSheet(String tag) {
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0 ||
        readBoolValue(schedePersonaggio[index]['realtimeSharedSheet'])) {
      return false;
    }
    return ownPermissionTags.contains(normalizeOculumFriendTag(tag));
  }

  void combatLogFor(String tag, String message) {
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0) return;
    if (index == schedaCorrente) {
      aggiungiLog(message);
    } else {
      final sheet = schedePersonaggio[index];
      final log = List<String>.from(sheet['logEventi'] as List? ?? []);
      log.insert(0, '[${DateTime.now().toIso8601String()}] $message');
      sheet['logEventi'] = log.take(250).toList();
    }
  }

  Future<void> sendOnlineCombatRequest(Map<String, dynamic> request) async {
    attachPendingCombatTurnResources(request);
    final delivered = await realtimeService?.sendCombatEvent(
      'combat_attack',
      permissionEnvelope(request),
    );
    if (!mounted) return;
    final previousDelivery = request['sent'];
    request['sent'] = delivered == true;
    if (delivered != true && previousDelivery != false) {
      combatLogFor(
        '${request['sourceTag']}',
        '[INVIO COMBATTIMENTO] Invio a ${request['targetName'] ?? request['targetTag']} non confermato da Supabase. La richiesta resta in attesa e sarà ritentata alla riconnessione.',
      );
    }
    setState(() {});
    programmaSalvataggio();
  }

  Future<void> sendCombatAcknowledgement(
    Map<String, dynamic> request,
    String phase,
  ) async {
    final expected =
        '${phase == 'defense' ? request['sourceTag'] : request['targetTag']}';
    if (!controlsOnlineCombatSheet(expected)) {
      return;
    }
    await realtimeService?.sendCombatEvent('combat_ack', {
      ...permissionEnvelope({
        'id': request['id'],
        'sourceTag': request['sourceTag'],
        'targetTag': request['targetTag'],
        'encounterId': request['encounterId'],
        'phase': phase,
      }),
      'senderTag': expected,
    });
  }

  void receiveCombatAcknowledgement(Map<String, dynamic> payload) {
    if (!validPermissionSender(payload) ||
        payload['encounterId'] != onlineCombatEncounterId) {
      return;
    }
    final request = onlineCombatRequests['${payload['id']}'];
    if (request == null ||
        request['scope'] != permissionScope ||
        request['sourceTag'] != payload['sourceTag'] ||
        request['targetTag'] != payload['targetTag']) {
      return;
    }
    final phase = '${payload['phase']}';
    final expected = phase == 'defense'
        ? request['sourceTag']
        : request['targetTag'];
    if (payload['senderTag'] != expected ||
        !const {'attack', 'defense', 'help'}.contains(phase)) {
      return;
    }
    final key = '${phase}Acknowledged';
    if (request[key] == true) {
      return;
    }
    request[key] = true;
    if (phase == 'attack') {
      combatLogFor(
        '${request['sourceTag']}',
        '[ATTACCO RICEVUTO] ${request['targetName'] ?? request['targetTag']}: in attesa del tiro difensivo.',
      );
    }
    if (phase == 'help') request['status'] = 'resolved';
    if (mounted) setState(() {});
    programmaSalvataggio();
  }

  void claimOnlineVampirism(Map<String, dynamic> request) {
    if (request['status'] != 'resolved' ||
        const {
          'help',
          'scout',
          'corruption',
          'corruption_target',
        }.contains(request['kind']) ||
        request['vampirismClaimed'] == true)
      return;
    final source = '${request['sourceTag'] ?? ''}';
    if (!controlsOnlineCombatSheet(source)) return;
    if (source != sheetTagAt(schedaCorrente)) {
      final index = localSheetIndexForOculumTag(source);
      if (index < 0) return;
      final original = schedaCorrente;
      salvaSchedaCorrenteInMemoria();
      final global = catturaImpostazioniGlobali();
      try {
        schedaCorrente = index;
        caricaStatoDaJson(schedePersonaggio[index]);
        ripristinaImpostazioniGlobali(global);
        claimOnlineVampirism(request);
        salvaSchedaCorrenteInMemoria();
      } finally {
        schedaCorrente = original;
        caricaStatoDaJson(schedePersonaggio[original]);
        ripristinaImpostazioniGlobali(global);
      }
      return;
    }
    final receipt = request['damageReceipt'];
    if (receipt is! Map) return; // Older clients cannot certify actual HP loss.
    request['vampirismClaimed'] = true;
    final instance = getCondition('vampirismo');
    if (instance == null ||
        request['outcome'] == OculumAttackOutcome.avoided.name) {
      programmaSalvataggio();
      return;
    }
    final hpDamage = max(0, readIntValue(receipt['hpLost']));
    if (hpDamage <= 0) {
      programmaSalvataggio();
      return;
    }
    final groupKey =
        '${request['encounterId']}:${request['attackGroupId'] ?? request['id']}';
    final ledger = instance.metadata['onlineVampirismClaims'] is Map
        ? Map<String, dynamic>.from(
            instance.metadata['onlineVampirismClaims'] as Map,
          )
        : <String, dynamic>{};
    final group = ledger[groupKey] is Map
        ? Map<String, dynamic>.from(ledger[groupKey] as Map)
        : <String, dynamic>{};
    final seen =
        (group['receipts'] is List ? group['receipts'] as List : const [])
            .map((id) => '$id')
            .toSet();
    if (!seen.add('${request['id']}')) return;
    final totalDamage = min(
      100000000,
      readIntValue(group['damage']) + hpDamage,
    );
    final config = {
      ...?conditionDefinitionOverrides['vampirismo'],
      ...instance.metadata,
    };
    final factors = config['onlineDifficultyFactors'];
    final difficulty =
        '${request['difficulty'] ?? normalizedCampaignDifficulty()}';
    final factorRaw = factors is Map
        ? factors[normalizeTemporaryOculumDifficulty(difficulty)]
        : null;
    final potential = oculumOnlineVampirismHealing(
      confirmedHpDamage: totalDamage,
      maximumHp: maxHp(),
      stage: instance.stage,
      difficulty: difficulty,
      percentPerStage:
          double.tryParse('${config['onlinePercentPerStage'] ?? 3}') ?? 3,
      maxHpPercentPerStage:
          double.tryParse('${config['onlineMaxHpPercentPerStage'] ?? 3}') ?? 3,
      difficultyFactor: factorRaw == null
          ? null
          : double.tryParse('$factorRaw'),
    );
    final incremental = max(0, potential - readIntValue(group['potential']));
    ledger[groupKey] = {
      'damage': totalDamage,
      'potential': potential,
      'receipts': seen.take(128).toList(),
    };
    while (ledger.length > 64) {
      ledger.remove(ledger.keys.first);
    }
    instance.metadata['onlineVampirismClaims'] = ledger;
    final before = hpCorrenti();
    final restored = min(
      max(0, maxHp() - before),
      applyConditionHealingAmount(incremental),
    );
    if (restored > 0) {
      currentHpController.text = '${before + restored}';
      sendRealtimeHpChanged();
    }
    request['vampirismHealing'] = restored;
    aggiungiLog(
      '[VAMPIRISMO ONLINE] +$restored HP da $hpDamage Vita effettiva sottratta a ${request['targetName'] ?? request['targetTag']}. Stadio ${instance.stage}, ${campaignDifficultyLabel(difficulty)}; limite condiviso per attacco, HP ${before + restored}/${maxHp()}.',
    );
    notifyConditionsChanged(conditionTargetsFor(instance));
    programmaSalvataggio(invalidateCaches: false);
  }

  Future<void> replayOnlineCombatRequests({bool retryOnly = false}) async {
    if (realtimeService?.isConnected != true || onlineCombatReplayInFlight) {
      return;
    }
    onlineCombatReplayInFlight = true;
    try {
      final tag = sheetTagAt(schedaCorrente);
      final prefix =
          '${realtimeService?.normalizedRoomId ?? realtimeRoomController.text.trim()}:';
      for (final request in onlineCombatRequests.values.toList()) {
        if (!mounted ||
            realtimeService?.isConnected != true ||
            sheetTagAt(schedaCorrente) != tag) {
          break;
        }
        if (request['sourceTag'] == tag &&
            request['status'] == 'pending' &&
            '${request['scope']}'.startsWith(prefix) &&
            request['encounterId'] == onlineCombatEncounterId) {
          request['scope'] = permissionScope;
        }
        if (request['scope'] != permissionScope ||
            request['encounterId'] != onlineCombatEncounterId) {
          continue;
        }
        if (request['kind'] == 'scout') {
          if (request['sourceTag'] == tag && request['status'] == 'pending') {
            await realtimeService?.sendCombatEvent(
              'combat_scout',
              permissionEnvelope(request),
            );
          }
          continue;
        }
        if (request['kind'] == 'corruption') {
          if (request['sourceTag'] == tag && request['status'] == 'pending') {
            attachPendingCombatTurnResources(request);
            await realtimeService?.sendCombatEvent(
              'corruption_apply',
              permissionEnvelope(request),
            );
          }
          continue;
        }
        claimOnlineVampirism(request);
        if (request['kind'] == 'help') {
          if (request['sourceTag'] == tag &&
              (!retryOnly || request['helpAcknowledged'] != true)) {
            attachPendingCombatTurnResources(request);
            await realtimeService?.sendCombatEvent(
              'combat_help',
              permissionEnvelope(request),
            );
          }
          continue;
        }
        if (request['sourceTag'] == tag &&
            request['status'] == 'pending' &&
            (!retryOnly || request['attackAcknowledged'] != true)) {
          await sendOnlineCombatRequest(request);
        } else if (request['targetTag'] == tag &&
            request['status'] == 'resolved' &&
            (!retryOnly || request['defenseAcknowledged'] != true)) {
          attachPendingCombatTurnResources(request);
          await realtimeService?.sendCombatEvent(
            'combat_defense',
            permissionEnvelope(request),
          );
        }
      }
    } finally {
      onlineCombatReplayInFlight = false;
    }
  }

  void receiveLocalCombatAttack(Map<String, dynamic> request) {
    if (request['received'] == true ||
        !controlsOnlineCombatSheet('${request['targetTag']}')) {
      return;
    }
    request['received'] = true;
    combatLogFor(
      '${request['targetTag']}',
      '[DIFESA RICHIESTA · ${request['targetName'] ?? 'bersaglio'}] ${request['sourceName']} usa ${request['abilityName'] ?? request['choice']}. Tiro nemico ${request['attack']} · DT da superare: ${request['attack']} · danni dichiarati ${request['damage']} (${request['element'] ?? 'fisico'}). Tira CM, Riflessi, Resistenza, Manifestazione del Potere o un sottotratto difensivo configurato. La skill difensiva può essere usata prima del tiro; questo bersaglio applicherà in automatico condizioni, resistenze ed effetti, poi Difesa, Scudo Oculum, Scudo, HP temporanei e Vita in base all’esito. ${request['reason'] ?? ''}',
    );
  }

  void receiveOnlineCombatEvent(String event, Map<String, dynamic> payload) {
    final requested = '${payload['encounterId'] ?? ''}';
    final previous = selectedMasterInitiativeGroupId;
    if (!realtimeIsMasterRole &&
        requested.isNotEmpty &&
        requested != onlineCombatEncounterId) {
      if (!controlsOnlineCombatSheet('${payload['targetTag']}') &&
          !controlsOnlineCombatSheet('${payload['sourceTag']}')) {
        return;
      }
      final encounter = realtimeEncounterSnapshots
          .where((group) => group['encounterId'] == requested)
          .firstOrNull;
      if (encounter == null) return;
      final previousSnapshot = realtimeVisibleInitiativeSnapshot;
      final previousSelection = realtimeSelectedEncounterId;
      realtimeVisibleInitiativeSnapshot = encounter;
      realtimeSelectedEncounterId = requested;
      try {
        receiveOnlineCombatEventForSelectedEncounter(event, payload);
      } finally {
        realtimeVisibleInitiativeSnapshot = previousSnapshot;
        realtimeSelectedEncounterId = previousSelection;
      }
      return;
    }
    if (realtimeIsMasterRole && requested.isNotEmpty && requested != previous) {
      captureActiveMasterInitiativeGroup();
      final group = masterInitiativeGroups
          .where(
            (group) =>
                group['id'] == requested && readBoolValue(group['published']),
          )
          .firstOrNull;
      if (group == null) return;
      selectMasterInitiativeGroup(requested);
      try {
        receiveOnlineCombatEventForSelectedEncounter(event, payload);
      } finally {
        captureActiveMasterInitiativeGroup();
        selectMasterInitiativeGroup(previous);
      }
      return;
    }
    receiveOnlineCombatEventForSelectedEncounter(event, payload);
  }

  void receiveOnlineCombatEventForSelectedEncounter(
    String event,
    Map<String, dynamic> payload,
  ) {
    final requestId = '${payload['id'] ?? ''}';
    try {
      _receiveOnlineCombatEventForSelectedEncounter(event, payload);
    } finally {
      final request = onlineCombatRequests[requestId];
      if (realtimeIsMasterRole &&
          request?['masterActionResourceApplied'] == true) {
        final tag = '${request?['masterActionResourceTag'] ?? ''}';
        request!['masterActionResourceApplied'] = false;
        request['masterTurnResourcesApplied'] = false;
        advanceMasterInitiativeAfterAction(tag);
      } else if (realtimeIsMasterRole &&
          request?['masterTurnResourcesApplied'] == true) {
        request!['masterTurnResourcesApplied'] = false;
        sendRealtimeInitiativeSnapshotIfPublished();
      }
    }
  }

  void _receiveOnlineCombatEventForSelectedEncounter(
    String event,
    Map<String, dynamic> payload,
  ) {
    if (const {
          'combat_help',
          'combat_attack',
          'combat_defense',
        }.contains(event) &&
        payload['turnResourceSpends'] is List) {
      if (!validPermissionSender(payload) ||
          !_applyIncomingCombatTurnResources(event, payload)) {
        return;
      }
    }
    if (event == 'combat_scout') {
      receiveCombatScout(payload);
      return;
    }
    if (event == 'combat_ack') {
      receiveCombatAcknowledgement(payload);
      return;
    }
    if (event == 'combat_help') {
      receiveCombatHelp(payload);
      return;
    }
    if (event == 'corruption_apply') {
      receiveCorruptionApplication(payload);
      return;
    }
    if (event == 'corruption_target') {
      receiveCorruptionTarget(payload);
      return;
    }
    if (event != 'combat_attack' && event != 'combat_defense') return;
    if (!validPermissionSender(payload)) return;
    final id = '${payload['id'] ?? ''}';
    if (id.isEmpty ||
        id.length > 160 ||
        payload['encounterId'] != onlineCombatEncounterId) {
      return;
    }
    final tags = onlineCombatTokens().map(onlineCombatTokenTag).toSet();
    final source = '${payload['sourceTag'] ?? ''}',
        target = '${payload['targetTag'] ?? ''}';
    // A player can receive a packet just before the source token reaches its
    // local initiative snapshot.  The sender was already authenticated by
    // Presence and the selected recipient is still required to be in this
    // fight, so retain the request instead of silently dropping its defense.
    if (!tags.contains(target) ||
        source == target ||
        (!tags.contains(source) && !controlsOnlineCombatSheet(target))) {
      return;
    }
    if (event == 'combat_attack') {
      if (payload['senderTag'] != source ||
          readIntValue(payload['damage']) < 0 ||
          readIntValue(payload['damage']) > 100000000) {
        return;
      }
      if (!onlineCombatRequests.containsKey(id) &&
          onlineCombatRequests.length >= 200) {
        final old = onlineCombatRequests.entries
            .where((e) => e.value['status'] != 'pending')
            .firstOrNull;
        if (old == null) return;
        onlineCombatRequests.remove(old.key);
      }
      final request = onlineCombatRequests[id] ??= {
        ...payload,
        'status': 'pending',
        'received': false,
      };
      // A free critical counterattack must refer to an actual resolved defense.
      if (request['forcedCritical'] == true || request['reactionOf'] != null) {
        final original = onlineCombatRequests['${request['reactionOf']}'];
        if (original == null ||
            original['targetTag'] != source ||
            original['sourceTag'] != target ||
            (original['counterAttackId'] != null &&
                original['counterAttackId'] != id) ||
            !(oculumDefenseGrantsFreeReaction(
                  readIntValue(original['attack']),
                  readIntValue(original['defense']),
                ) ||
                original['defenseChoice'] == 'resistenza' &&
                    readIntValue(original['defense']) >=
                        readIntValue(original['attack'])) ||
            request['forcedCritical'] == true &&
                !oculumDefenseGrantsFreeReaction(
                  readIntValue(original['attack']),
                  readIntValue(original['defense']),
                )) {
          onlineCombatRequests.remove(id);
          return;
        }
        original['counterAttackId'] = id;
      }
      if (request['schiantoReactionOf'] != null) {
        final original =
            onlineCombatRequests['${request['schiantoReactionOf']}'];
        if (original == null ||
            original['schiantoActionSkipped'] != true ||
            original['schiantoReactionAvailable'] != true ||
            original['schiantoReactionUsed'] == true ||
            original['targetTag'] != source ||
            original['sourceTag'] != target ||
            request['choice'] != 'schianto' ||
            readIntValue(request['schiantoReactionBonus']) != 10) {
          onlineCombatRequests.remove(id);
          return;
        }
        if (realtimeIsMasterRole && !consumeMasterReactionForSheetTag(source)) {
          original['schiantoReactionRejected'] = true;
          onlineCombatRequests.remove(id);
          combatLogFor(
            source,
            '[SCHIANTO] Reazione non accettata: il Master non trova una Reazione disponibile nella turnistica.',
          );
          return;
        }
        original['schiantoReactionUsed'] = true;
      }
      receiveLocalCombatAttack(request);
      unawaited(sendCombatAcknowledgement(request, 'attack'));
      if (request['status'] == 'resolved' &&
          controlsOnlineCombatSheet(target) &&
          sheetTagAt(schedaCorrente) == target) {
        attachPendingCombatTurnResources(request);
        unawaited(
          realtimeService?.sendCombatEvent(
            'combat_defense',
            permissionEnvelope(request),
          ),
        );
      }
    } else {
      final request = onlineCombatRequests[id];
      if (request == null ||
          payload['senderTag'] != request['targetTag'] ||
          payload['sourceTag'] != request['sourceTag'] ||
          payload['targetTag'] != request['targetTag']) {
        return;
      }
      unawaited(sendCombatAcknowledgement(request, 'defense'));
      if (request['status'] != 'pending') {
        return;
      }
      final defense = readIntValue(payload['defense']);
      final attack = readIntValue(request['attack']);
      final outcome = oculumAttackOutcome(
        attack,
        defense,
        difficulty: '${request['difficulty'] ?? 'normale'}',
      );
      request['status'] = 'resolved';
      request['defense'] = defense;
      request['defenseChoice'] = payload['defenseChoice'];
      request['doubleDefense'] = payload['doubleDefense'] == true;
      final reflected = readIntValue(
        payload['runicReflectedDamage'],
      ).clamp(0, max(0, readIntValue(request['damage']))).toInt();
      if (reflected > 0 &&
          controlsOnlineCombatSheet('${request['sourceTag']}')) {
        unawaited(
          applyRunicReflectedDamage('${request['sourceTag']}', reflected),
        );
      }
      request['outcome'] = outcome.name;
      for (final key in const [
        'corruptionFullHits',
        'corruptionRequiredHits',
        'corruptionApplicationId',
      ]) {
        if (payload.containsKey(key)) request[key] = payload[key];
      }
      claimCorruptionMasteryCooldown(request);
      request['schiantoActionSkipped'] =
          payload['schiantoActionSkipped'] == true;
      request['schiantoReactionBonus'] = readIntValue(
        payload['schiantoReactionBonus'],
      );
      request['schiantoReactionAvailable'] =
          payload['schiantoReactionAvailable'] == true;
      final rawReceipt = payload['damageReceipt'];
      if (rawReceipt is Map) {
        request['damageReceipt'] = <String, dynamic>{
          for (final key in const [
            'oculumShieldLost',
            'shieldLost',
            'temporaryHpLost',
            'hpLost',
          ])
            key: readIntValue(rawReceipt[key]).clamp(0, 100000000),
          'pawnPending': rawReceipt['pawnPending'] == true,
        };
      }
      final reflexBonusReaction =
          payload['defenseChoice'] == 'riflessi' &&
          oculumReflexGrantsCounterReaction(
            reflexesTotal: readIntValue(payload['defenseSubtraitTotal']),
            naturalRoll: readIntValue(payload['defenseNatural']),
            targetMovement: readIntValue(
              request['sourceMovement'],
              fallback: -1,
            ),
            characterMovement: readIntValue(
              payload['targetMovement'],
              fallback: -1,
            ),
          );
      request['reflexBonusReaction'] = reflexBonusReaction;
      request['freeReaction'] =
          request['reactionOf'] == null &&
          (oculumDefenseGrantsFreeReaction(attack, defense) ||
              payload['defenseChoice'] == 'resistenza' && defense >= attack ||
              reflexBonusReaction);
      request['criticalReaction'] = oculumDefenseGrantsFreeReaction(
        attack,
        defense,
      );
      if (realtimeIsMasterRole || realtimeIsCoMasterRole) {
        applyOnlineSchiantoActionSkip(payload);
      }
      claimOnlineVampirism(request);
      combatLogFor(
        source,
        '${oculumResolvedRollLog(label: '[ESITO ATTACCO]', total: attack, opposingTotal: defense, succeeded: outcome != OculumAttackOutcome.avoided)} ${outcome.label}.${request['damageReceipt'] is Map<String, dynamic> ? ' ${combatDamageReceiptText(request['damageReceipt'] as Map<String, dynamic>)}.' : ''}${request['freeReaction'] == true ? ' Il difensore ottiene una reazione gratuita contro di te.' : ''}',
      );
    }
    while (onlineCombatRequests.length > 200) {
      final old = onlineCombatRequests.entries
          .where((e) => e.value['status'] != 'pending')
          .firstOrNull;
      if (old == null) break;
      onlineCombatRequests.remove(old.key);
    }
    setState(() {});
    programmaSalvataggio();
  }

  Future<void> defendOnlineAttack(
    Map<String, dynamic> request,
    String choice,
  ) async {
    if (request['kind'] == 'corruption') {
      await defendCorruptionApplication(request, choice);
      return;
    }
    final tag = sheetTagAt(schedaCorrente);
    final id = '${request['id']}';
    if (request['firstDefense'] != null &&
        request['defenseRetryApproved'] != true) {
      return;
    }
    if (request['status'] != 'pending' ||
        request['targetTag'] != tag ||
        request['scope'] != permissionScope ||
        request['encounterId'] != onlineCombatEncounterId ||
        !controlsOnlineCombatSheet(tag) ||
        pawnPendingDamage.isNotEmpty ||
        !onlineCombatResolving.add(id)) {
      return;
    }
    try {
      if (request['firstDefense'] == null) {
        aggiungiLog(
          '[TURNISTICA] Il primo tiro di difesa non consuma Azione o Reazione.',
        );
      }
      if (!mounted ||
          sheetTagAt(schedaCorrente) != tag ||
          request['status'] != 'pending') {
        return;
      }
      if (choice == 'manifestazione_potere') {
        var description = '';
        final accepted = await showDialog<bool>(
          context: context,
          builder: (dialog) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
              title: const Text('Manifestazione del Potere · Difesa'),
              content: TextField(
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Come usi il potere per difenderti?',
                ),
                onChanged: (value) => update(() => description = value.trim()),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialog, false),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialog, true),
                  child: const Text('Tira · descrizione anche a voce'),
                ),
              ],
            ),
          ),
        );
        if (accepted != true ||
            !mounted ||
            sheetTagAt(schedaCorrente) != tag ||
            request['status'] != 'pending') {
          return;
        }
        request['defenseReason'] = description;
        aggiungiLog('[DIFESA · MANIFESTAZIONE] $description');
      }
      int? defense;
      int defenseNatural = 0;
      final concentrationPending =
          schedePersonaggio[schedaCorrente]['combatConcentrationPending'] ==
          true;
      final collectorDefensePenalty = oculumElementCollectorDefensePenalty(
        sourceMonsterBookId: '${request['sourceMonsterBookId'] ?? ''}',
        incomingElement: '${request['element'] ?? ''}',
        defenseElement: '${request['defenseElement'] ?? ''}',
      );
      void resolved(int natural, int total) {
        defenseNatural = natural;
        final penalized = total - collectorDefensePenalty;
        if (collectorDefensePenalty > 0) {
          request['collectorDefensePenalty'] = collectorDefensePenalty;
          aggiungiLog(
            '[COLLEZIONISTA DI ELEMENTI] Parare con ${elementDisplayName('${request['defenseElement']}')} il suo stesso elemento: -$collectorDefensePenalty al tiro difensivo ($total → $penalized).',
          );
        }
        if (!concentrationPending) {
          defense = penalized;
          return;
        }
        final bonus = (penalized * 0.12).ceil();
        request['concentrationDefenseBonus'] = bonus;
        defense = penalized + bonus;
        schedePersonaggio[schedaCorrente]['combatConcentrationPending'] = false;
        aggiungiLog(
          '[CONCENTRAZIONE] Difesa +$bonus (+12%) per questa risposta.',
        );
        programmaSalvataggio();
      }

      if (choice == 'cm') {
        await tiraValoreSpeciale(
          'CM',
          cm(),
          applyGlobalRollModifier: false,
          actionLabel: 'Difesa contro ${request['sourceName']}',
          onResolved: resolved,
        );
      } else {
        final stat = hiddenEyeStats
            .where((s) => s.id == choice && oculumCombatSubtraitSelectable(s))
            .firstOrNull;
        if (stat == null) return;
        await tiraSottotrattoOcchio(
          stat,
          actionLabel: 'Difesa contro ${request['sourceName']}',
          onResolved: resolved,
        );
      }
      if (!mounted || defense == null || sheetTagAt(schedaCorrente) != tag) {
        return;
      }
      if (request['firstDefense'] == null &&
          readIntValue(request['damage']) > 0 &&
          oculumAttackOutcome(
                readIntValue(request['attack']),
                defense!,
                difficulty: '${request['difficulty'] ?? 'normale'}',
              ) !=
              OculumAttackOutcome.avoided) {
        request['firstDefense'] = defense;
        request['firstDefenseChoice'] = choice;
        request['firstDefenseNatural'] = defenseNatural;
        aggiungiLog(
          '[DIFESA NON RIUSCITA] $defense contro ${request['attack']}: scegli se ricevere i danni o spendere una Reazione per un solo nuovo tentativo.',
        );
        notifyActiveSheetSummaryChanged();
        programmaSalvataggio();
        return;
      }
      request['defenseRetryApproved'] = false;
      await applyResolvedOnlineDefense(
        request,
        choice,
        defense!,
        defenseNatural: defenseNatural,
      );
    } finally {
      onlineCombatResolving.remove(id);
    }
  }

  Future<void> requestDefenseRetry(Map<String, dynamic> request) async {
    if (request['firstDefense'] == null ||
        request['status'] != 'pending' ||
        request['defenseRetryUsed'] == true ||
        request['targetTag'] != sheetTagAt(schedaCorrente)) {
      return;
    }
    if (!await spendCombatRollResource(forceReaction: true)) return;
    request['defenseRetryUsed'] = true;
    request['defenseRetryApproved'] = true;
    aggiungiLog(
      '[REAZIONE] Secondo tentativo disponibile: tira una volta ancora prima dei danni.',
    );
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
  }

  void receiveDefenseRetryPermission(
    String event,
    Map<String, dynamic> payload, {
    bool local = false,
  }) {
    if (!local &&
        !validPermissionSender(
          payload,
          staff: event == 'permission_decision',
        )) {
      return;
    }
    if (payload['scope'] != permissionScope ||
        payload['encounterId'] != onlineCombatEncounterId) {
      return;
    }
    final request = onlineCombatRequests['${payload['attackId']}'];
    if (request == null ||
        request['status'] != 'pending' ||
        request['targetTag'] != payload['targetTag'] ||
        payload['id'] != 'defense_retry:${request['id']}') {
      return;
    }
    if (event == 'permission_request') {
      if (!realtimeIsMasterRole ||
          payload['senderTag'] != request['targetTag']) {
        return;
      }
      final existing = request['defenseRetryDecision'];
      Map<String, dynamic> decision;
      if (existing is Map) {
        decision = Map<String, dynamic>.from(existing);
      } else {
        final allowed =
            request['defenseRetryUsed'] != true &&
            consumeMasterReactionForSheetTag('${request['targetTag']}');
        decision = {...payload, 'status': allowed ? 'approved' : 'rejected'};
        request['defenseRetryDecision'] = decision;
        if (allowed) request['defenseRetryUsed'] = true;
      }
      final envelope = permissionEnvelope(decision);
      if (controlsOnlineCombatSheet('${request['targetTag']}')) {
        receiveDefenseRetryPermission(
          'permission_decision',
          envelope,
          local: true,
        );
      }
      unawaited(
        realtimeService?.sendPermissionEvent('permission_decision', envelope),
      );
      programmaSalvataggio();
    } else if (event == 'permission_decision' &&
        controlsOnlineCombatSheet('${request['targetTag']}')) {
      if (request['defenseRetryDecisionApplied'] == true) return;
      request['defenseRetryDecisionApplied'] = true;
      request['defenseRetryUsed'] = true;
      request['defenseRetryApproved'] = payload['status'] == 'approved';
      aggiungiLog(
        request['defenseRetryApproved'] == true
            ? '[REAZIONE] Secondo tentativo autorizzato: puoi usare un tiro o una skill difensiva prima dei danni.'
            : '[REAZIONE] Nessuna reazione disponibile: conferma il danno del primo tiro.',
      );
      notifyActiveSheetSummaryChanged();
      programmaSalvataggio();
    }
  }

  Future<void> applyResolvedOnlineDefense(
    Map<String, dynamic> request,
    String choice,
    int defense, {
    int defenseNatural = 0,
  }) async {
    final tag = sheetTagAt(schedaCorrente);
    final id = '${request['id']}';
    if (!mounted ||
        request['status'] != 'pending' ||
        request['targetTag'] != tag ||
        request['scope'] != permissionScope ||
        request['encounterId'] != onlineCombatEncounterId ||
        !identical(onlineCombatRequests[id], request) ||
        !controlsOnlineCombatSheet(tag) ||
        pawnPendingDamage.isNotEmpty) {
      return;
    }
    final attack = readIntValue(request['attack']);
    final outcome = oculumAttackOutcome(
      attack,
      defense,
      difficulty: '${request['difficulty'] ?? 'normale'}',
    );
    final critical =
        request['forcedCritical'] == true ||
        oculumAttackIsCritical(attack, defense);
    final doubleCritical = oculumIsDoubleCritical(
      natural: readIntValue(request['natural']),
      total: attack,
      opposingTotal: defense,
    );
    final doubleDefense = oculumIsDoubleCritical(
      natural: defenseNatural,
      total: defense,
      opposingTotal: attack,
    );
    request['doubleCritical'] = doubleCritical;
    request['doubleDefense'] = doubleDefense;
    if (doubleDefense) {
      request['counterAttackRollBonus'] = 9;
      aggiungiLog(
        '[DOPPIO CRITICO DIFESA] +9 al tiro della reazione di attacco contro ${request['sourceName']}.',
      );
    }
    final resisted = choice == 'resistenza' && defense >= attack;
    final reflexStat = choice == 'riflessi'
        ? hiddenEyeStats.where((stat) => stat.id == 'riflessi').firstOrNull
        : null;
    final reflexesTotal = reflexStat == null ? 0 : hiddenEyeTotal(reflexStat);
    final reflexBonusReaction = oculumReflexGrantsCounterReaction(
      reflexesTotal: reflexesTotal,
      naturalRoll: defenseNatural,
      targetMovement: readIntValue(request['sourceMovement'], fallback: -1),
      characterMovement: movimento(),
    );
    request['status'] = 'resolved';
    request['defense'] = defense;
    request['defenseChoice'] = choice;
    request['defenseNatural'] = defenseNatural;
    request['defenseSubtraitTotal'] = reflexesTotal;
    request['targetMovement'] = movimento();
    request['reflexBonusReaction'] = reflexBonusReaction;
    final schiantoActionSkipped =
        request['choice'] == 'schianto' &&
        oculumSchiantoSkipsAction(
          targetGrade: activeCriticalGrade(),
          attackAvoided: outcome == OculumAttackOutcome.avoided,
          resisted: resisted,
        );
    if (schiantoActionSkipped) {
      request['schiantoActionSkipped'] = true;
      request['schiantoReactionBonus'] = 10;
      request['schiantoReactionAvailable'] = true;
      schedePersonaggio[schedaCorrente]['combatSchiantoReactionBonusPending'] =
          10;
      aggiungiLog(
        '[SCHIANTO] Bersaglio di Grado ${activeCriticalGrade()} salta l’azione ma conserva la Reazione: può rispondere con Schianto +10 contro l’attaccante.',
      );
      programmaSalvataggio();
    }
    request['outcome'] = outcome.name;
    request['freeReaction'] =
        request['reactionOf'] == null &&
        (oculumDefenseGrantsFreeReaction(attack, defense) ||
            resisted ||
            reflexBonusReaction);
    request['criticalReaction'] = oculumDefenseGrantsFreeReaction(
      attack,
      defense,
    );
    aggiungiLog(
      '${oculumResolvedRollLog(label: '[ESITO DIFESA] $choice', total: defense, opposingTotal: attack, succeeded: outcome == OculumAttackOutcome.avoided)} ${outcome.label}.${request['freeReaction'] == true ? ' Reazione gratuita su chi ha provato a colpirti.${reflexBonusReaction ? ' Riflessi concede una Reazione aggiuntiva.' : ''}' : ''}',
    );
    if (resisted) {
      aggiungiLog(
        '[RESISTENZA] 1 danno prima degli Scudi; reazione gratuita contro chi ha attaccato, senza concatenazione.',
      );
    }
    final damage = resisted
        ? 1
        : oculumOpposedDamage(
            readIntValue(request['damage']),
            attack,
            defense,
            forcedCritical: request['forcedCritical'] == true,
            difficulty: '${request['difficulty'] ?? 'normale'}',
          );
    final incomingElement = oculumNormalizeElementId(
      '${request['element'] ?? 'fisico'}',
    );
    final defenseElement = oculumNormalizeElementId(
      '${request['defenseElement'] ?? elementoDannoDominante()}',
    );
    final elementalDefenseMultiplier = oculumElementalDefenseMultiplier(
      incomingElement: incomingElement,
      defenseElement: defenseElement,
      currentHp: hpCorrenti(),
      maximumHp: maxHp(),
    );
    request['defenseElement'] = defenseElement;
    request['elementalDefenseMultiplier'] = elementalDefenseMultiplier;
    if (damage > 0 && elementalDefenseMultiplier < 1) {
      aggiungiLog(
        '[DIFESA ELEMENTALE] ${elementDisplayName(defenseElement)} protegge da ${elementDisplayName(incomingElement)}: -25% danni in ingresso${defenseElement == 'angelico' || defenseElement == 'diabolico' ? ', finché la Vita resta almeno al 30% del massimo' : ''}.',
      );
    }
    final precisionStages =
        request['choice'] == 'precisione' &&
            !resisted &&
            outcome != OculumAttackOutcome.avoided
        ? readIntValue(request['precisionFragilityStages']).clamp(0, 3).toInt()
        : 0;
    final precisionDamagePercent =
        request['choice'] == 'precisione' &&
            !resisted &&
            outcome != OculumAttackOutcome.avoided
        ? readIntValue(
            request['precisionDamagePercent'],
          ).clamp(100, 350).toInt()
        : 100;
    // Persist the decision before applying damage: duplicate broadcasts cannot
    // replay the mutation, including while a Pawn interception is pending.
    await salvaDatiSoloLocale();
    if (!mounted || sheetTagAt(schedaCorrente) != tag) return;
    final beforeOculumShield = scudoOculum();
    final beforeShield = scudo();
    final beforeTemporaryHp = hpTemp();
    final beforeHp = hpCorrenti();
    if (damage > 0) {
      final previousElement = incomingDamageElement;
      incomingDamageElement = '${request['element'] ?? 'fisico'}';
      final discoveredWeakPoint =
          combatDiscoveries[combatDiscoveryKey(
            tag,
            combatScoutSide('${request['sourceTag']}'),
          )]?['weakPoint'] ==
          true;
      final precisionBasePreset = discoveredWeakPoint
          ? 'Fragilità Semi Letale'
          : configuredIncomingDamagePreset();
      final precisionPreset = precisionStages > 0
          ? oculumAdvanceDamagePreset(
              precisionBasePreset,
              precisionStages,
              scalaCriticaDanno(),
            )
          : null;
      final precisionAdjustedDamage = (damage * precisionDamagePercent / 100)
          .ceil();
      if (precisionStages > 0 || precisionDamagePercent > 100) {
        aggiungiLog(
          '[PRECISIONE] ${precisionStages > 0 ? '+$precisionStages stadi di Fragilità' : ''}${precisionStages > 0 && precisionDamagePercent > 100 ? ' · ' : ''}${precisionDamagePercent > 100 ? '$precisionDamagePercent% del danno' : ''}, applicati solo a questo colpo.',
        );
      }
      try {
        await applicaDannoSubito(
          dannoEsplicito: precisionAdjustedDamage,
          critico: critical,
          criticalBonusMultiplier: critical ? 2 : 1,
          criticalDamageBonusOverride: doubleCritical
              ? oculumDoubleCriticalDamageBonus(
                  readIntValue(request['level']),
                  readIntValue(request['grade']),
                )
              : null,
          extraFragilityPercent: doubleCritical ? 10 : 0,
          incomingDamageMultiplier: elementalDefenseMultiplier,
          bypassDefense: (request['effects'] as List? ?? const [])
              .whereType<Map>()
              .any(
                (effect) =>
                    effect['type'] == 'danno' &&
                    readBoolValue(effect['bypassDefense']),
              ),
          bypassShields: (request['effects'] as List? ?? const [])
              .whereType<Map>()
              .any(
                (effect) =>
                    effect['type'] == 'danno' &&
                    readBoolValue(effect['bypassShields']),
              ),
          shieldDamageBonusPercent: (request['effects'] as List? ?? const [])
              .whereType<Map>()
              .where((effect) => effect['type'] == 'danno')
              .fold<int>(
                0,
                (total, effect) => max(
                  total,
                  readIntValue(
                    effect['shieldDamageBonusPercent'],
                  ).clamp(0, 1000),
                ),
              ),
          defenseMultiplier: !critical && outcome == OculumAttackOutcome.reduced
              ? 1.5
              : 1,
          enemyLevel: readIntValue(request['level']),
          enemyDifficulty: '${request['difficulty']}',
          resolvedResistance: resisted,
          resistancePresetOverride:
              precisionPreset ??
              (discoveredWeakPoint ? 'Fragilità Semi Letale' : null),
        );
      } finally {
        if (mounted && sheetTagAt(schedaCorrente) == tag) {
          incomingDamageElement = previousElement;
        }
      }
    }
    if (!mounted || sheetTagAt(schedaCorrente) != tag) return;
    final receipt = <String, dynamic>{
      'oculumShieldLost': max(0, beforeOculumShield - scudoOculum()),
      'shieldLost': max(0, beforeShield - scudo()),
      'temporaryHpLost': max(0, beforeTemporaryHp - hpTemp()),
      'hpLost': min(max(0, beforeHp), max(0, beforeHp - hpCorrenti())),
      'pawnPending': pawnPendingDamage.isNotEmpty,
    };
    request['damageReceipt'] = receipt;
    aggiungiLog(
      '[DANNO RISOLTO] ${request['sourceName']} → ${request['targetName'] ?? nomeController.text}: ${combatDamageReceiptText(receipt)}.',
    );
    if (!resisted &&
        outcome != OculumAttackOutcome.avoided &&
        mounted &&
        sheetTagAt(schedaCorrente) == tag) {
      final rawEffects = request['effects'];
      if (rawEffects is List) {
        for (final raw in rawEffects.take(30).whereType<Map>()) {
          final effect = OculumStructuredEffect.fromJson(
            Map<String, dynamic>.from(raw),
          )..recipient = 'se_stesso';
          if (effect.type == 'danno') {
            continue; // Included in the single damage packet.
          }
          if (effect.type == 'stato' &&
              effect.appliedState == 'corruzione' &&
              effect.resource.startsWith('corruption_mastery:')) {
            if (outcome != OculumAttackOutcome.full) {
              aggiungiLog(
                '[CORRUZIONE] Il colpo non è pieno: non conta per il contagio.',
              );
            } else if (recordCorruptionMasteryHit(request)) {
              final applicationId = 'mastery:$id';
              request['corruptionApplicationId'] = applicationId;
              claimCorruptionMasteryCooldown(request);
              queueCorruptionApplication(
                targetTag: tag,
                scrollGrade: readIntValue(request['grade']),
                sourceTag: '${request['sourceTag']}',
                sourceName: '${request['sourceName']}',
                sourceTotal: attack,
                sourceLevel: readIntValue(request['level']),
                requestId: applicationId,
                fromMastery: true,
                attackRequestId: id,
                controlChancePercent: readIntValue(
                  request['corruptionControlChancePercent'],
                  fallback: oculumCorruptionMasteryTargetControlPercent,
                ),
              );
            }
            continue;
          }
          if (request['kind'] == 'corruption_target') continue;
          if (effect.type == 'stato' &&
              effect.appliedState == 'corruzione' &&
              await offerCorruptionResistance(request)) {
            if (!mounted || sheetTagAt(schedaCorrente) != tag) return;
            continue;
          }
          if (effect.id == 'runic_wound_on_hp' &&
              readIntValue(receipt['hpLost']) <= 0) {
            continue;
          }
          if (outcome == OculumAttackOutcome.reduced) {
            final duration = int.tryParse(effect.duration);
            if (duration != null || effect.type == 'stato') {
              final reduced = oculumOpposedEffectDuration(
                duration ?? 1,
                outcome,
              );
              if (reduced == 0) {
                aggiungiLog(
                  '[EFFETTO RIDOTTO] ${effect.appliedState.isEmpty ? effect.type : effect.appliedState}: durata 0, non applicato.',
                );
                continue;
              }
              effect.duration = '$reduced';
            }
          }
          final messages = applyStructuredEffectsOnActivation([
            effect,
          ], source: '${request['sourceName']} · attacco $id');
          for (final message in messages) {
            aggiungiLog('[EFFETTO ${outcome.label}] $message');
          }
          if (effect.type == 'stato' && effect.appliedState == 'corruzione') {
            sendRealtimeInitiativeSnapshotIfPublished();
          }
        }
      }
    }
    final reply = {
      ...request,
      'runicReflectedDamage': defense > attack
          ? (readIntValue(request['damage']) *
                    activeStructuredEffectBonus('runic_reflection_percent') /
                    100)
                .floor()
          : 0,
      'defense': defense,
      'defenseChoice': choice,
      'defenseElement': defenseElement,
      'elementalDefenseMultiplier': elementalDefenseMultiplier,
    };
    if (readIntValue(reply['runicReflectedDamage']) > 0 &&
        controlsOnlineCombatSheet('${request['sourceTag']}')) {
      await applyRunicReflectedDamage(
        '${request['sourceTag']}',
        readIntValue(reply['runicReflectedDamage']),
      );
    }
    attachPendingCombatTurnResources(reply);
    await realtimeService?.sendCombatEvent(
      'combat_defense',
      permissionEnvelope(reply),
    );
    if (mounted) setState(() {});
    programmaSalvataggio();
  }

  Future<void> applyRunicReflectedDamage(String target, int damage) async {
    final index = localSheetIndexForOculumTag(target);
    if (index < 0) return;
    final original = schedaCorrente;
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    try {
      if (index != original) {
        schedaCorrente = index;
        caricaStatoDaJson(schedePersonaggio[index]);
        ripristinaImpostazioniGlobali(global);
      }
      aggiungiLog(
        '[SPECCHIO RUNICO] $damage danni riflessi; si applicano Difesa e Scudi.',
      );
      await applicaDannoSubito(dannoEsplicito: damage);
      salvaSchedaCorrenteInMemoria();
    } finally {
      if (index != original && mounted) {
        schedaCorrente = original;
        caricaStatoDaJson(schedePersonaggio[original]);
        ripristinaImpostazioniGlobali(global);
      }
    }
    programmaSalvataggio();
  }

  void applyOnlineSchiantoActionSkip(Map<String, dynamic> result) {
    if (result['schiantoActionSkipped'] != true ||
        result['choice'] != 'schianto' ||
        '${result['encounterId'] ?? ''}' != onlineCombatEncounterId ||
        '${result['outcome'] ?? ''}' == OculumAttackOutcome.avoided.name) {
      return;
    }
    final targetTag = '${result['targetTag'] ?? ''}';
    final token = masterInitiativeTokens
        .where(
          (entry) => '${entry['sheetTag'] ?? entry['id'] ?? ''}' == targetTag,
        )
        .firstOrNull;
    if (token == null || masterInitiativeTokenGrade(token) > 2) return;
    token['actionUsed'] = true;
    token['schiantoActionSkipped'] = true;
    token['schiantoReactionBonus'] = 10;
    token['updatedAt'] = DateTime.now().toIso8601String();
    risultato =
        '[SCHIANTO] ${token['name'] ?? targetTag} salta l’azione; Reazione disponibile con Schianto +10.';
    aggiungiLog(risultato);
    final autoAdvanced = advanceMasterInitiativeAfterAction(targetTag);
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
    if (!autoAdvanced) sendRealtimeInitiativeSnapshotIfPublished();
  }

  Future<void> chooseDefenseElement(Map<String, dynamic> request) async {
    final options = allDamageElementIds();
    if (options.isEmpty) return;
    final selected = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Affinità elementale · Difesa'),
        content: SizedBox(
          width: 360,
          height: MediaQuery.sizeOf(dialog).height * .6,
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              final id = options[index];
              return ListTile(
                leading: Icon(Icons.circle, color: elementColor(id), size: 16),
                title: Text(elementDisplayName(id)),
                selected: id == request['defenseElement'],
                onTap: () => Navigator.pop(dialog, id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Annulla'),
          ),
        ],
      ),
    );
    if (selected == null || !mounted || request['status'] != 'pending') return;
    request['defenseElement'] = selected;
    setState(() {});
  }

  Widget onlineCombatRequestsPanel() {
    if (realtimeService?.isConnected != true &&
        !onlineCombatRequests.values.any(
          (r) => r['kind'] == 'corruption' && r['status'] == 'pending',
        )) {
      return const SizedBox.shrink();
    }
    final tag = sheetTagAt(schedaCorrente);
    final helpBonus =
        schedaCorrente >= 0 && schedaCorrente < schedePersonaggio.length
        ? readIntValue(schedePersonaggio[schedaCorrente]['combatHelpPending'])
        : 0;
    final outgoing = onlineCombatRequests.values
        .where(
          (r) =>
              r['scope'] == permissionScope &&
              r['encounterId'] == onlineCombatEncounterId &&
              r['sourceTag'] == tag &&
              r['status'] == 'pending' &&
              r['kind'] != 'help' &&
              r['kind'] != 'scout',
        )
        .toList();
    final requests = onlineCombatRequests.values
        .where(
          (r) =>
              r['scope'] == permissionScope &&
              r['encounterId'] == onlineCombatEncounterId &&
              r['targetTag'] == tag &&
              r['kind'] != 'help' &&
              r['kind'] != 'scout' &&
              (r['status'] == 'pending' ||
                  (r['freeReaction'] == true && r['reactionUsed'] != true) ||
                  (r['schiantoReactionAvailable'] == true &&
                      r['schiantoReactionUsed'] != true)),
        )
        .toList();
    final otherTargets = <String, Map<String, dynamic>>{
      for (final request in onlineCombatRequests.values)
        if (request['scope'] == permissionScope &&
            request['encounterId'] == onlineCombatEncounterId &&
            request['status'] == 'pending' &&
            request['targetTag'] != tag &&
            request['kind'] != 'help' &&
            request['kind'] != 'scout' &&
            controlsOnlineCombatSheet('${request['targetTag']}'))
          '${request['targetTag']}': request,
    };
    if (requests.isEmpty &&
        outgoing.isEmpty &&
        otherTargets.isEmpty &&
        helpBonus == 0) {
      return const SizedBox.shrink();
    }
    return gothicPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (helpBonus != 0)
            Text(
              'Aiuta compagno: ${helpBonus > 0 ? '+' : ''}$helpBonus al prossimo tiro · applicazione automatica',
              style: TextStyle(
                color: helpBonus > 0
                    ? Colors.lightBlueAccent
                    : Colors.redAccent,
              ),
            ),
          for (final entry in otherTargets.entries)
            OutlinedButton.icon(
              onPressed: () async {
                final index = localSheetIndexForOculumTag(entry.key);
                if (index >= 0) await cambiaSchedaPersonaggio(index);
              },
              icon: const Icon(Icons.shield_outlined),
              label: Text(
                '${entry.value['targetName'] ?? entry.key} · attaccato: apri la scheda per difenderti',
              ),
            ),
          for (final request in outgoing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '${request['targetName'] ?? request['targetTag']} · ${request['attackAcknowledged'] == true ? 'Attacco ricevuto: attende la difesa' : 'Consegna in attesa: reinvio automatico'}',
                style: TextStyle(color: primaryColor),
              ),
            ),
          Text(
            'Difese e reazioni in attesa',
            style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
          ),
          for (final request in requests)
            if (request['kind'] == 'corruption_target')
              FilledButton.icon(
                onPressed: () => answerCorruptionTargetRequest(request),
                icon: const Icon(Icons.visibility),
                label: Text(
                  'Corruzione · scegli i bersagli di ${request['sourceName']}',
                ),
              )
            else if (request['kind'] == 'corruption')
              corruptionApplicationPanel(request)
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${request['sourceName']} → ${request['targetName'] ?? nomeController.text} · ${request['abilityName'] ?? request['choice']} · tiro nemico ${request['attack']} · DT da superare ${request['attack']} · ${request['reason'] ?? ''}',
                    ),
                    if (request['firstDefense'] != null &&
                        request['status'] == 'pending')
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Text(
                            'Prima difesa: ${request['firstDefense']} · danni ancora sospesi',
                          ),
                          if (request['defenseRetryUsed'] != true)
                            OutlinedButton.icon(
                              onPressed: () => requestDefenseRetry(request),
                              icon: const Icon(Icons.refresh),
                              label: const Text(
                                'Spendi Reazione · seconda difesa',
                              ),
                            ),
                          if (request['defenseRetryApproved'] == true)
                            const Text(
                              'Reazione consumata: scegli un nuovo tiro o una skill e poi tira.',
                            ),
                          FilledButton(
                            onPressed:
                                onlineCombatResolving.contains(
                                  '${request['id']}',
                                )
                                ? null
                                : () async {
                                    final id = '${request['id']}';
                                    if (!onlineCombatResolving.add(id)) return;
                                    try {
                                      await applyResolvedOnlineDefense(
                                        request,
                                        '${request['firstDefenseChoice']}',
                                        readIntValue(request['firstDefense']),
                                        defenseNatural: readIntValue(
                                          request['firstDefenseNatural'],
                                        ),
                                      );
                                    } finally {
                                      onlineCombatResolving.remove(id);
                                    }
                                  },
                            child: const Text('Conferma danni · prima difesa'),
                          ),
                        ],
                      ),
                    if (request['status'] == 'pending')
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => chooseDefenseElement(request),
                          icon: Icon(
                            Icons.water_drop_outlined,
                            color: elementColor(
                              '${request['defenseElement'] ?? elementoDannoDominante()}',
                            ),
                          ),
                          label: Text(
                            'Difesa · ${elementDisplayName('${request['defenseElement'] ?? elementoDannoDominante()}')} · attacco ${elementDisplayName('${request['element'] ?? 'fisico'}')}',
                            style: TextStyle(
                              color: elementColor(
                                '${request['defenseElement'] ?? elementoDannoDominante()}',
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (request['status'] == 'pending')
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Tooltip(
                            message:
                                'Applica prima una skill difensiva a questa scheda. Poi scegli qui il tiro per questo specifico bersaglio.',
                            child: OutlinedButton.icon(
                              onPressed:
                                  onlineCombatResolving.contains(
                                    '${request['id']}',
                                  )
                                  ? null
                                  : () => showCombatActionPanel(
                                      OculumCombatAbilityRole.defense,
                                    ),
                              icon: const Icon(Icons.shield_moon_outlined),
                              label: const Text('Skill e protezioni'),
                            ),
                          ),
                          if (schivataOculumPronta() ||
                              schivateOculumDisponibili() > 0)
                            OutlinedButton.icon(
                              onPressed:
                                  onlineCombatResolving.contains(
                                    '${request['id']}',
                                  )
                                  ? null
                                  : mostraMenuSchivataOculum,
                              icon: Icon(
                                Icons.visibility,
                                color: eyePupilGlowColor,
                              ),
                              label: Text(
                                schivataOculumPronta()
                                    ? 'Schivata pronta · ${schivataOculumProntaLabel()}'
                                    : 'Prepara Schivata Oculum',
                              ),
                            ),
                          for (final option in <String, String>{
                            'cm': 'CM',
                            for (final stat in hiddenEyeStats)
                              if (oculumCombatSubtraitSelectable(stat) &&
                                  combatDefenseRollIds.contains(stat.id))
                                stat.id: stat.nome,
                          }.entries)
                            OutlinedButton(
                              onPressed:
                                  onlineCombatResolving.contains(
                                        '${request['id']}',
                                      ) ||
                                      (option.key != 'cm' &&
                                          !hiddenEyeStats.any(
                                            (s) =>
                                                s.id == option.key &&
                                                oculumCombatSubtraitSelectable(
                                                  s,
                                                ),
                                          ))
                                  ? null
                                  : () =>
                                        defendOnlineAttack(request, option.key),
                              child: Text(option.value),
                            ),
                        ],
                      )
                    else if (request['schiantoReactionAvailable'] == true &&
                        request['schiantoReactionUsed'] != true &&
                        readIntValue(
                              schedePersonaggio[schedaCorrente]['combatSchiantoReactionBonusPending'],
                            ) >=
                            10)
                      FilledButton.icon(
                        onPressed: () => planOnlineAttack(
                          targetId: '${request['sourceTag']}',
                          initialChoice: 'schianto',
                          schiantoReactionId: '${request['id']}',
                        ),
                        icon: const Icon(Icons.flash_on),
                        label: const Text('Reazione Schianto +10'),
                      )
                    else
                      FilledButton.icon(
                        onPressed: () => planOnlineAttack(
                          targetId: '${request['sourceTag']}',
                          freeReactionId: '${request['id']}',
                        ),
                        icon: const Icon(Icons.flash_on),
                        label: Text(
                          request['criticalReaction'] == true
                              ? 'Reazione gratuita · contrattacco critico'
                              : 'Reazione gratuita · contrattacco',
                        ),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget onlineAttackButton() => onlineAttackTokens().isEmpty
      ? const SizedBox.shrink()
      : OutlinedButton.icon(
          onPressed: planOnlineAttack,
          icon: const Icon(Icons.gps_fixed),
          label: const Text('Attacca un bersaglio'),
        );
}
