part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

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
    r'(?:da\s+)?(\d+)\s*(?:a|o|[-–])\s*(\d+)\s+(?:bersagli|avversari|nemici|creature)',
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
    r'fino\s+ad?\s+oculum\s+(?:bersagli|avversari|nemici|creature)',
  ).hasMatch(normalized)) {
    return (minimum: 1, maximum: oculum.clamp(1, 100));
  }
  final count = RegExp(
    r'(?:fino\s+a|massimo|max)\s+(\d+)\s+(?:bersagli|avversari|nemici|creature)',
  ).firstMatch(normalized);
  if (count != null) {
    return (
      minimum: 1,
      maximum: (int.tryParse(count.group(1)!) ?? 1).clamp(1, 100),
    );
  }
  final exact = RegExp(
    r'(\d+)\s+(?:bersagli|avversari|nemici|creature)',
  ).firstMatch(normalized);
  if (exact != null) {
    final count = (int.tryParse(exact.group(1)!) ?? 1).clamp(1, 100);
    return (minimum: count, maximum: count);
  }
  return (minimum: 1, maximum: 1);
}

extension _OculumOnlineAttacks on _OculumHomePageState {
  Future<Map<String, dynamic>?> chooseHelpTarget({String? sourceTag}) async {
    final own = sourceTag ?? sheetTagAt(schedaCorrente);
    final online = realtimeService?.isConnected == true;
    final candidates = online
        ? onlineCombatTokens()
              .where(
                (t) => onlineCombatTokenTag(t) != own && t['status'] != 'dead',
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

  int consumeCombatHelp() {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return 0;
    }
    final sheet = schedePersonaggio[schedaCorrente];
    final bonus = readIntValue(sheet['combatHelpPending']).clamp(0, 1000000);
    if (bonus > 0) {
      sheet['combatHelpPending'] = 0;
      aggiungiLog('[AIUTO CONSUMATO] +$bonus nel prossimo tiro.');
      programmaSalvataggio();
    }
    return bonus;
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
        source == target ||
        !tags.contains(source) ||
        !tags.contains(target)) {
      return;
    }
    if (!controlsOnlineCombatSheet(target)) return;
    final existing = onlineCombatRequests[id];
    if (existing?['received'] == true) return;
    final bonus = readIntValue(payload['helpBonus']).clamp(0, 1000000);
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
        ).clamp(0, 1000000) +
        bonus;
    combatLogFor(
      target,
      '[AIUTA COMPAGNO] ${payload['sourceName']} aiuta ${payload['targetName']}: +$bonus al prossimo tiro.',
    );
    programmaSalvataggio();
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
      '[AIUTA COMPAGNO] $helperName → $name: +$bonus al prossimo tiro.',
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
        'helpBonus': max(0, bonus),
      };
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
            ).clamp(0, 1000000) +
            max(0, bonus);
        combatLogFor(
          tag,
          '[AIUTA COMPAGNO] $helperName: +${max(0, bonus)} al prossimo tiro.',
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

  String get onlineCombatEncounterId => realtimeIsMasterRole
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
      '${token['sheetTag'] ?? token['id'] ?? ''}';

  List<Map<String, dynamic>> onlineAttackTokens() {
    final tokens = onlineCombatTokens();
    final own = sheetTagAt(schedaCorrente);
    if (!tokens.any(
      (t) => onlineCombatTokenTag(t) == own && t['status'] != 'dead',
    )) {
      return [];
    }
    return tokens
        .where(
          (t) =>
              onlineCombatTokenTag(t).isNotEmpty &&
              onlineCombatTokenTag(t) != own &&
              t['status'] != 'dead',
        )
        .toList();
  }

  Future<void> planOnlineAttack({
    String? targetId,
    String? freeReactionId,
    String initialChoice = 'vc',
    int minimumTargets = 1,
    int maximumTargets = 1,
  }) async {
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
    if (freeReactionId != null &&
        (freeReaction?['freeReaction'] != true ||
            freeReaction?['reactionUsed'] == true ||
            freeReaction?['targetTag'] != sheetTagAt(schedaCorrente))) {
      return;
    }
    final byId = {
      for (final token in tokens) '${token['sheetTag'] ?? token['id']}': token,
    };
    final subs = hiddenEyeStats
        .where(
          (s) =>
              s.unlocked && !const {'nodo', 'fortuna', 'drop'}.contains(s.id),
        )
        .toList();
    const first = ['schianto', 'forza', 'riflessi'];
    subs.sort((a, b) {
      final ai = first.indexOf(a.id), bi = first.indexOf(b.id);
      return (ai < 0 ? 99 : ai).compareTo(bi < 0 ? 99 : bi);
    });
    final choices = [
      OculumAttackChoice('vc', 'VC · attacco', vc(), color: Colors.redAccent),
      for (final stat in subs)
        OculumAttackChoice(
          stat.id,
          stat.nome,
          hiddenEyeTotal(stat) +
              hiddenEyeStatRollQuickBonus(stat) +
              tiroGlobaleBonus(),
          color: hiddenEyeStatIdentityColor(stat),
        ),
    ];
    final plan = await showDialog<OculumAttackPlan>(
      context: context,
      builder: (_) => OculumAttackPlanner(
        targets: {
          for (final e in byId.entries) e.key: '${e.value['name'] ?? '???'}',
        },
        initialTarget: targetId,
        initialChoice: initialChoice,
        minimumTargets: minimumTargets.clamp(1, 100),
        maximumTargets: maximumTargets.clamp(1, 100),
        choices: choices,
        chance: (tag, option) {
          // Never derive hidden enemy statistics from a replicated private sheet.
          if (!haPermessiMaster || slotMachineRollsEnabled) return null;
          final index = masterInitiativeSheetIndexForToken(byId[tag]!);
          if (index < 0) return null;
          final defense = sheetRollBonusAt(index, 'cm');
          return OculumAttackForecast.fromRolls(
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
                  level: sheetCriticalLevelAt(index),
                  grade: sheetIntValueAt(index, 'grado'),
                  difficulty: sheetDifficoltaTiroAt(index),
                ),
            ],
            difficulty: normalizedCampaignDifficulty(),
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
    if (freeReactionId != null &&
        (plan.targetIds.length != 1 ||
            plan.targetId != freeReaction?['sourceTag'])) {
      return;
    }
    final currentIds = {
      for (final token in onlineAttackTokens())
        '${token['sheetTag'] ?? token['id']}',
    };
    if (plan.targetIds.any((id) => !currentIds.contains(id)) ||
        plan.targetIds.length < minimumTargets ||
        plan.targetIds.length > maximumTargets) {
      return;
    }
    final target = plan.targetIds
        .map((tag) => '${byId[tag]!['name'] ?? '???'}')
        .join(', ');
    final label =
        'Attacco contro $target${plan.reason.isEmpty ? '' : ' · ${plan.reason}'}';
    final preparedDamage = dannoTotale();
    final element = elementoDannoDominante();
    final targetEffects = [
      for (final e in activeStructuredEffects)
        if (e['type'] == 'pending_target' &&
            e['effect'] is Map &&
            (e['effect'] as Map)['recipient'] != 'alleato')
          Map<String, dynamic>.from(e['effect'] as Map),
    ];
    final directDamage = targetEffects
        .where((e) => e['type'] == 'danno')
        .toList();
    final damage = directDamage.isEmpty
        ? preparedDamage
        : directDamage.fold<int>(
            0,
            (sum, e) => sum + max(0, readIntValue(e['valueExpression'])),
          );
    final sourceTag = sheetTagAt(schedaCorrente);
    final id = '$sourceTag:${DateTime.now().microsecondsSinceEpoch}';
    if (freeReaction != null) {
      freeReaction['reactionUsed'] = true;
      freeReaction['counterAttackId'] = id;
    }
    aggiungiLog(
      '[ATTACCO] $label · ${choices.firstWhere((c) => c.id == plan.choiceId).name}.${plan.choiceId == 'vc' ? '' : ' Motivazione inviata al Master.'}',
    );
    void resolved(int natural, int total) {
      if (!mounted ||
          currentSheetScrollId() != origin ||
          encounter != onlineCombatEncounterId) {
        return;
      }
      for (final selectedTag in plan.targetIds) {
        final requestId = plan.targetIds.length == 1 ? id : '$id:$selectedTag';
        final request = <String, dynamic>{
          'id': requestId,
          'scope': permissionScope,
          'encounterId': encounter,
          'sourceTag': sourceTag,
          'sourceName': realtimeDisplayName(),
          'targetTag': selectedTag,
          'targetName': '${byId[selectedTag]!['name'] ?? '???'}',
          'attackGroupId': id,
          'choice': plan.choiceId,
          'reason': plan.reason,
          'attack': total,
          'natural': natural,
          'damage': damage,
          'effects': targetEffects,
          'element': element,
          'level': activeCriticalLevel(),
          'difficulty': normalizedCampaignDifficulty(),
          'forcedCritical':
              freeReactionId != null &&
              freeReaction?['criticalReaction'] == true,
          'reactionOf': freeReactionId,
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        };
        onlineCombatRequests[requestId] = request;
        receiveLocalCombatAttack(request);
        unawaited(sendOnlineCombatRequest(request));
      }
      programmaSalvataggio();
    }

    if (plan.choiceId == 'vc') {
      await tiraValoreSpeciale(
        'VC',
        vc(),
        applyGlobalRollModifier: false,
        actionLabel: label,
        onResolved: resolved,
      );
    } else {
      final stat = hiddenEyeStats
          .where((s) => s.id == plan.choiceId && s.unlocked)
          .firstOrNull;
      if (stat == null || plan.reason.trim().isEmpty) return;
      await tiraSottotrattoOcchio(
        stat,
        actionLabel: label,
        onResolved: resolved,
      );
      if (!mounted || currentSheetScrollId() != origin) return;
      if (consumeNextAttackStructuredEffects()) {
        aggiungiLog(
          '$label · Danni preparati $damage, bonus del prossimo attacco consumati una sola volta.',
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

  Future<void> replayOnlineCombatRequests() async {
    if (realtimeService?.isConnected != true) return;
    final tag = sheetTagAt(schedaCorrente);
    for (final request in onlineCombatRequests.values.toList()) {
      if (request['scope'] != permissionScope ||
          request['encounterId'] != onlineCombatEncounterId) {
        continue;
      }
      if (request['kind'] == 'help') {
        if (request['sourceTag'] == tag) {
          await realtimeService?.sendCombatEvent(
            'combat_help',
            permissionEnvelope(request),
          );
        }
        continue;
      }
      if (request['sourceTag'] == tag && request['status'] == 'pending') {
        await sendOnlineCombatRequest(request);
      } else if (request['targetTag'] == tag &&
          request['status'] == 'resolved') {
        await realtimeService?.sendCombatEvent(
          'combat_defense',
          permissionEnvelope(request),
        );
      }
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
      '[DIFESA RICHIESTA] ${request['sourceName']} attacca con ${request['choice']}: ${request['attack']}. ${request['reason'] ?? ''} Tira CM, Riflessi, Resistenza o Manifestazione del Potere dal riquadro Difese in attesa.',
    );
  }

  void receiveOnlineCombatEvent(String event, Map<String, dynamic> payload) {
    if (event == 'combat_help') {
      receiveCombatHelp(payload);
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
    if (!tags.contains(source) || !tags.contains(target) || source == target) {
      return;
    }
    if (event == 'combat_attack') {
      if (payload['senderTag'] != source ||
          (payload['choice'] != 'vc' &&
              '${payload['reason'] ?? ''}'.trim().isEmpty) ||
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
      receiveLocalCombatAttack(request);
    } else {
      final request = onlineCombatRequests[id];
      if (request == null ||
          payload['senderTag'] != request['targetTag'] ||
          payload['sourceTag'] != request['sourceTag'] ||
          payload['targetTag'] != request['targetTag'] ||
          request['status'] != 'pending') {
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
      request['outcome'] = outcome.name;
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
      request['freeReaction'] =
          request['reactionOf'] == null &&
          (oculumDefenseGrantsFreeReaction(attack, defense) ||
              payload['defenseChoice'] == 'resistenza' && defense >= attack);
      request['criticalReaction'] = oculumDefenseGrantsFreeReaction(
        attack,
        defense,
      );
      combatLogFor(
        source,
        '[ESITO ATTACCO] $attack contro ${payload['defenseChoice']} $defense: ${outcome.label}.${request['damageReceipt'] is Map<String, dynamic> ? ' ${combatDamageReceiptText(request['damageReceipt'] as Map<String, dynamic>)}.' : ''}${request['freeReaction'] == true ? ' Il difensore ottiene una reazione gratuita contro di te.' : ''}',
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
    final tag = sheetTagAt(schedaCorrente);
    final id = '${request['id']}';
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
                  onPressed: description.isEmpty
                      ? null
                      : () => Navigator.pop(dialog, true),
                  child: const Text('Descrivi e tira'),
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
      void resolved(int natural, int total) => defense = total;
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
            .where((s) => s.id == choice && s.unlocked)
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
      await applyResolvedOnlineDefense(request, choice, defense!);
    } finally {
      onlineCombatResolving.remove(id);
    }
  }

  Future<void> applyResolvedOnlineDefense(
    Map<String, dynamic> request,
    String choice,
    int defense,
  ) async {
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
    final resisted = choice == 'resistenza' && defense >= attack;
    request['status'] = 'resolved';
    request['defense'] = defense;
    request['defenseChoice'] = choice;
    request['outcome'] = outcome.name;
    request['freeReaction'] =
        request['reactionOf'] == null &&
        (oculumDefenseGrantsFreeReaction(attack, defense) || resisted);
    request['criticalReaction'] = oculumDefenseGrantsFreeReaction(
      attack,
      defense,
    );
    aggiungiLog(
      '[ESITO DIFESA] $choice $defense contro $attack: ${outcome.label}.${request['freeReaction'] == true ? ' Reazione gratuita su chi ha provato a colpirti.${request['criticalReaction'] == true ? ' Il contrattacco è critico: bonus critico ×2 e Fragilità secondo le regole del bersaglio.' : ' Contrattacco ordinario.'}' : ''}',
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
      try {
        await applicaDannoSubito(
          dannoEsplicito: damage,
          critico: critical,
          criticalBonusMultiplier: critical ? 2 : 1,
          defenseMultiplier: !critical && outcome == OculumAttackOutcome.reduced
              ? 1.5
              : 1,
          enemyLevel: readIntValue(request['level']),
          enemyDifficulty: '${request['difficulty']}',
          resolvedResistance: resisted,
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
      'hpLost': max(0, beforeHp - hpCorrenti()),
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
        }
      }
    }
    final reply = {...request, 'defense': defense, 'defenseChoice': choice};
    await realtimeService?.sendCombatEvent(
      'combat_defense',
      permissionEnvelope(reply),
    );
    if (mounted) setState(() {});
    programmaSalvataggio();
  }

  Widget onlineCombatRequestsPanel() {
    if (realtimeService?.isConnected != true) return const SizedBox.shrink();
    final tag = sheetTagAt(schedaCorrente);
    final requests = onlineCombatRequests.values
        .where(
          (r) =>
              r['scope'] == permissionScope &&
              r['encounterId'] == onlineCombatEncounterId &&
              r['targetTag'] == tag &&
              r['kind'] != 'help' &&
              (r['status'] == 'pending' ||
                  (r['freeReaction'] == true && r['reactionUsed'] != true)),
        )
        .toList();
    if (requests.isEmpty) return const SizedBox.shrink();
    return gothicPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Difese e reazioni in attesa',
            style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
          ),
          for (final request in requests)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${request['sourceName']} · ${request['choice']} ${request['attack']} · ${request['reason'] ?? ''}',
                  ),
                  if (request['status'] == 'pending')
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in <String, String>{
                          'cm': 'CM',
                          'riflessi': 'Riflessi',
                          'resistenza': 'Resistenza',
                          'manifestazione_potere': 'Manifestazione del Potere',
                        }.entries)
                          OutlinedButton(
                            onPressed:
                                onlineCombatResolving.contains(
                                      '${request['id']}',
                                    ) ||
                                    (option.key != 'cm' &&
                                        !hiddenEyeStats.any(
                                          (s) =>
                                              s.id == option.key && s.unlocked,
                                        ))
                                ? null
                                : () => defendOnlineAttack(request, option.key),
                            child: Text(option.value),
                          ),
                      ],
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
