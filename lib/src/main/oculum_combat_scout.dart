part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumCombatScout on _OculumHomePageState {
  void forgetCombatDiscoveries(String encounter) {
    combatDiscoveries.removeWhere(
      (key, _) => key.startsWith('$activeCampaignId:$encounter:'),
    );
  }

  void mergeCombatDiscoveries(
    Iterable<String> previousIds,
    String destination,
  ) {
    for (final previous in previousIds) {
      final prefix = '$activeCampaignId:$previous:';
      for (final e in combatDiscoveries.entries.toList()) {
        if (!e.key.startsWith(prefix)) {
          continue;
        }
        final key =
            '$activeCampaignId:$destination:${e.key.substring(prefix.length)}';
        combatDiscoveries[key] = {
          ...?combatDiscoveries[key],
          ...e.value,
          if (combatDiscoveries[key]?['weakPoint'] == true ||
              e.value['weakPoint'] == true)
            'weakPoint': true,
        };
        combatDiscoveries.remove(e.key);
      }
    }
  }

  HiddenEyeStat? bestCombatScoutStat() {
    final candidates = hiddenEyeStats
        .where(
          (s) =>
              s.unlocked &&
              const {'percezione', 'investigazione'}.contains(s.id),
        )
        .toList();
    candidates.sort((a, b) => hiddenEyeTotal(b).compareTo(hiddenEyeTotal(a)));
    return candidates.firstOrNull;
  }

  String combatScoutSide(String tag) =>
      '${onlineCombatTokens().where((t) => onlineCombatTokenTag(t) == tag).firstOrNull?['side'] ?? 'ally'}';
  String combatDiscoveryKey(String target, String side) =>
      '$activeCampaignId:$onlineCombatEncounterId:$side:$target';
  Map<String, dynamic>? discoveredCombatTarget(String target) =>
      combatDiscoveries[combatDiscoveryKey(
        target,
        combatScoutSide(sheetTagAt(schedaCorrente)),
      )];

  Future<void> scoutCombatTarget() async {
    final stat = bestCombatScoutStat();
    if (stat == null) {
      return;
    }
    final origin = currentSheetScrollId();
    final own = sheetTagAt(schedaCorrente);
    final online = realtimeService?.isConnected == true;
    final encounter = onlineCombatEncounterId;
    final tokens = online
        ? onlineAttackTokens()
        : <Map<String, dynamic>>[
            for (var i = 0; i < schedePersonaggio.length; i++)
              if (i != schedaCorrente &&
                  schedePersonaggio[i]['realtimeSharedSheet'] != true)
                {'sheetTag': sheetTagAt(i), 'name': nomeSchedaPersonaggio(i)},
          ];
    final target = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text('${stat.nome} · osserva un bersaglio'),
        children: [
          for (final token in tokens)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, token),
              child: Text(
                '${token['name'] ?? '???'}',
                style: TextStyle(color: combatTargetColor(token)),
              ),
            ),
        ],
      ),
    );
    if (!mounted ||
        target == null ||
        currentSheetScrollId() != origin ||
        online && encounter != onlineCombatEncounterId) {
      return;
    }
    final targetTag = onlineCombatTokenTag(target);
    await tiraSottotrattoOcchio(
      stat,
      actionLabel: '${stat.nome} su ${target['name']}',
      onResolved: (natural, total) {
        final request = <String, dynamic>{
          'id': 'scout:$own:${DateTime.now().microsecondsSinceEpoch}',
          'kind': 'scout',
          'status': 'pending',
          'scope': permissionScope,
          'encounterId': encounter,
          'sourceTag': own,
          'sourceName': realtimeDisplayName(),
          'targetTag': targetTag,
          'targetName': '${target['name'] ?? '???'}',
          'scoutPhase': 'request',
          'natural': natural,
          'total': total,
        };
        if (online) {
          onlineCombatRequests['${request['id']}'] = request;
          unawaited(
            realtimeService!.sendCombatEvent(
              'combat_scout',
              permissionEnvelope(request),
            ),
          );
          aggiungiLog('[OSSERVAZIONE] Richiesta inviata a ${target['name']}.');
        } else {
          final index = localSheetIndexForOculumTag(targetTag);
          if (index < 0) {
            return;
          }
          final success = total >= sheetCriticalLevelAt(index);
          if (success) {
            combatDiscoveries[combatDiscoveryKey(targetTag, 'ally')] = {
              'level': sheetCriticalLevelAt(index),
              'cm': sheetRollBonusAt(index, 'cm'),
              'criticalLevel': sheetCriticalLevelAt(index),
              'grade': sheetIntValueAt(index, 'grado'),
              'rollDifficulty': sheetDifficoltaTiroAt(index),
              'difficulty': normalizedCampaignDifficulty(),
              'weakPoint': natural == 20,
            };
          }
          aggiungiLog(
            '[OSSERVAZIONE] ${target['name']}: ${success ? 'livello ${sheetCriticalLevelAt(index)} scoperto${natural == 20 ? '; punto debole: Fragilità Semi Letale per te e gli alleati fino a fine fight' : ''}' : 'livello non scoperto'}.',
          );
          programmaSalvataggio();
        }
      },
    );
  }

  void receiveCombatScout(Map<String, dynamic> payload) {
    if (!validPermissionSender(payload) ||
        payload['encounterId'] != onlineCombatEncounterId) {
      return;
    }
    final source = '${payload['sourceTag'] ?? ''}',
        target = '${payload['targetTag'] ?? ''}',
        id = '${payload['id'] ?? ''}';
    final tags = onlineCombatTokens().map(onlineCombatTokenTag).toSet();
    if (id.isEmpty ||
        id.length > 160 ||
        source == target ||
        !tags.contains(source) ||
        !tags.contains(target)) {
      return;
    }
    if (payload['scoutPhase'] == 'request') {
      if (payload['senderTag'] != source ||
          target != sheetTagAt(schedaCorrente) ||
          !controlsOnlineCombatSheet(target)) {
        return;
      }
      final previous = onlineCombatRequests[id];
      if (previous?['scoutPhase'] == 'result') {
        unawaited(
          realtimeService?.sendCombatEvent(
            'combat_scout',
            permissionEnvelope(previous!),
          ),
        );
        return;
      }
      final success = readIntValue(payload['total']) >= activeCriticalLevel();
      final weakPoint = success && readIntValue(payload['natural']) == 20;
      final reply = <String, dynamic>{
        ...payload,
        'kind': 'scout',
        'scoutPhase': 'result',
        'status': 'resolved',
        'success': success,
        if (success) 'level': activeCriticalLevel(),
        if (success) 'cm': cm(),
        if (success) 'grade': activeCriticalGrade(),
        if (success) 'difficulty': normalizedCampaignDifficulty(),
        if (success) 'rollDifficulty': difficoltaTiro(),
        'weakPoint': weakPoint,
      };
      for (final key in ['senderTag', 'senderRole', 'sessionId']) {
        reply.remove(key);
      }
      onlineCombatRequests[id] = reply;
      if (weakPoint) {
        combatDiscoveries[combatDiscoveryKey(target, combatScoutSide(source))] =
            {'weakPoint': true};
      }
      aggiungiLog(
        '[OSSERVAZIONE] ${payload['sourceName']} ${success ? 'ha scoperto il tuo livello${weakPoint ? ' e il punto debole fino a fine fight' : ''}' : 'non ha scoperto il tuo livello'}.',
      );
      unawaited(
        realtimeService?.sendCombatEvent(
          'combat_scout',
          permissionEnvelope(reply),
        ),
      );
    } else if (payload['scoutPhase'] == 'result') {
      if (payload['senderTag'] != target) {
        return;
      }
      final side = combatScoutSide(source);
      if (side != combatScoutSide(sheetTagAt(schedaCorrente))) {
        return;
      }
      final key = combatDiscoveryKey(target, side);
      if (payload['success'] == true) {
        final previous = combatDiscoveries[key];
        combatDiscoveries[key] = {
          'level': readIntValue(payload['level']),
          'cm': readIntValue(payload['cm']),
          'criticalLevel': readIntValue(payload['level']),
          'grade': readIntValue(payload['grade']),
          'difficulty': '${payload['difficulty']}',
          'rollDifficulty': readIntValue(payload['rollDifficulty']),
          'weakPoint':
              payload['weakPoint'] == true || previous?['weakPoint'] == true,
        };
      }
      final request = onlineCombatRequests[id];
      if (request != null && request['status'] == 'pending') {
        request['status'] = 'resolved';
        aggiungiLog(
          '[OSSERVAZIONE] ${payload['targetName']}: ${payload['success'] == true ? 'livello ${payload['level']} scoperto${payload['weakPoint'] == true ? '; punto debole: Fragilità Semi Letale fino a fine fight' : ''}' : 'livello non scoperto'}.',
        );
      }
    } else {
      return;
    }
    programmaSalvataggio();
    if (mounted) setState(() {});
  }
}
