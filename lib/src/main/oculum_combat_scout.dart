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
          (s) => const {
            'percezione',
            'investigazione',
            'furbizia',
            'valutazione',
          }.contains(s.id),
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

  int activeCombatScoutVelo() {
    final stat = hiddenEyeStats
        .where((candidate) => candidate.id == 'velo' && candidate.unlocked)
        .firstOrNull;
    return stat == null ? 0 : max(0, hiddenEyeTotal(stat));
  }

  int sheetCombatScoutVeloAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return 0;
    if (index == schedaCorrente) return activeCombatScoutVelo();
    final sheet = schedePersonaggio[index];
    final raw = (sheet['hiddenEyeStats'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .where((candidate) => candidate['id'] == 'velo')
        .firstOrNull;
    if (raw == null || raw['unlocked'] == false) return 0;
    final level = sheetIntValueAt(index, 'livello');
    return max(
      0,
      readIntValue(raw['valore']) +
          oculumHiddenEyeDerivedBonusFor(
            level: level,
            id: 'velo',
            resilienza: sheetIntValueAt(index, 'resilienza'),
            volonta: sheetIntValueAt(index, 'volonta'),
            materia: sheetIntValueAt(index, 'materia'),
            oculum: sheetIntValueAt(index, 'oculum'),
            karma: readIntValue(sheet['karma']),
          ) +
          (oculumRoleSubtraitBonuses(
                '${sheet['humanoidRole'] ?? ''}',
                level,
              )['velo'] ??
              0),
    );
  }

  String combatScoutReadText(OculumCombatScoutRead read) {
    return switch (read.reveal) {
      OculumCombatScoutReveal.exact => 'lettura esatta',
      OculumCombatScoutReveal.approximate => 'lettura approssimata',
      OculumCombatScoutReveal.insufficient => 'non senti abbastanza',
    };
  }

  void rememberCombatScoutRead(String key, Map<String, dynamic> read) {
    final previous = combatDiscoveries[key];
    int rank(Map<String, dynamic>? value) => switch (value?['reveal']) {
      'exact' => 2,
      'approximate' => 1,
      _ => 0,
    };
    combatDiscoveries[key] = {
      ...?(rank(previous) > rank(read) ? previous : read),
      'weakPoint': previous?['weakPoint'] == true || read['weakPoint'] == true,
    };
  }

  Future<void> scoutCombatTarget({
    Map<String, dynamic>? selectedTarget,
    HiddenEyeStat? requestedStat,
  }) async {
    final stat = requestedStat ?? bestCombatScoutStat();
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
    final target =
        selectedTarget ??
        await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (dialog) => SimpleDialog(
            title: Text('${stat.nome} · osserva'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialog, {'general': true}),
                child: const Text('Lancia senza bersaglio · lettura generale'),
              ),
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
    if (target['general'] == true) {
      await tiraSottotrattoOcchio(
        stat,
        actionLabel: '${stat.nome} · lettura generale',
        onResolved: (natural, total) {
          aggiungiLog(
            '[PERCEZIONE] Lettura generale $total: nessun bersaglio scelto, quindi nessuna probabilità individuale rivelata.',
          );
        },
      );
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
          final read = oculumCombatScoutRead(
            rollTotal: total,
            targetLevel: sheetCriticalLevelAt(index),
            targetVelo: sheetCombatScoutVeloAt(index),
            targetGrade: sheetIntValueAt(index, 'grado'),
            targetCm: sheetRollBonusAt(index, 'cm'),
          );
          rememberCombatScoutRead(combatDiscoveryKey(targetTag, 'ally'), {
            'reveal': read.reveal.name,
            if (read.showsProbabilities) 'level': read.targetLevel,
            if (read.showsProbabilities) 'cm': read.targetCm,
            if (read.showsProbabilities) 'criticalLevel': read.targetLevel,
            if (read.showsProbabilities) 'grade': read.targetGrade,
            if (read.showsProbabilities)
              'rollDifficulty': sheetDifficoltaTiroAt(index),
            if (read.showsProbabilities)
              'difficulty': normalizedCampaignDifficulty(),
            'weakPoint': read.isExact && natural == 20,
          });
          aggiungiLog(
            '[PERCEZIONE] ${target['name']}: ${combatScoutReadText(read)}${read.showsProbabilities ? '; livello ${read.targetLevel}, grado ${read.targetGrade}' : ''}${read.isExact && natural == 20 ? '; punto debole: Fragilità Semi Letale per te e gli alleati fino a fine fight' : ''}.',
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
    final incomingRequest =
        payload['scoutPhase'] == 'request' && controlsOnlineCombatSheet(target);
    if (id.isEmpty ||
        id.length > 160 ||
        source == target ||
        !tags.contains(target) ||
        (!tags.contains(source) && !incomingRequest)) {
      return;
    }
    if (payload['scoutPhase'] == 'request') {
      if (payload['senderTag'] != source ||
          !controlsOnlineCombatSheet(target)) {
        return;
      }
      final targetIndex = localSheetIndexForOculumTag(target);
      if (targetIndex < 0) return;
      final previous = onlineCombatRequests[id];
      if (previous?['scoutPhase'] == 'result') {
        unawaited(
          realtimeService?.sendCombatEvent('combat_scout', {
            ...permissionEnvelope(previous!),
            'senderTag': target,
          }),
        );
        return;
      }
      final read = oculumCombatScoutRead(
        rollTotal: readIntValue(payload['total']),
        targetLevel: sheetCriticalLevelAt(targetIndex),
        targetVelo: sheetCombatScoutVeloAt(targetIndex),
        targetGrade: sheetIntValueAt(targetIndex, 'grado'),
        targetCm: sheetRollBonusAt(targetIndex, 'cm'),
      );
      final weakPoint = read.isExact && readIntValue(payload['natural']) == 20;
      final reply = <String, dynamic>{
        ...payload,
        'kind': 'scout',
        'scoutPhase': 'result',
        'status': 'resolved',
        'success': read.isExact,
        'reveal': read.reveal.name,
        if (read.showsProbabilities) 'level': read.targetLevel,
        if (read.showsProbabilities) 'cm': read.targetCm,
        if (read.showsProbabilities) 'grade': read.targetGrade,
        if (read.showsProbabilities)
          'difficulty': normalizedCampaignDifficulty(),
        if (read.showsProbabilities)
          'rollDifficulty': sheetDifficoltaTiroAt(targetIndex),
        'weakPoint': weakPoint,
      };
      for (final key in ['senderTag', 'senderRole', 'sessionId']) {
        reply.remove(key);
      }
      onlineCombatRequests[id] = reply;
      if (weakPoint) {
        rememberCombatScoutRead(
          combatDiscoveryKey(target, combatScoutSide(source)),
          {'weakPoint': true},
        );
      }
      aggiungiLog(
        '[PERCEZIONE] ${payload['sourceName']} ha ottenuto ${combatScoutReadText(read)}${weakPoint ? ' e il punto debole fino a fine fight' : ''}.',
      );
      unawaited(
        realtimeService?.sendCombatEvent('combat_scout', {
          ...permissionEnvelope(reply),
          'senderTag': target,
        }),
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
      final reveal =
          '${payload['reveal'] ?? (payload['success'] == true ? 'exact' : 'insufficient')}';
      if (!OculumCombatScoutReveal.values.any((v) => v.name == reveal)) return;
      rememberCombatScoutRead(key, {
        'reveal': reveal,
        if (reveal != OculumCombatScoutReveal.insufficient.name)
          'level': readIntValue(payload['level']),
        if (reveal != OculumCombatScoutReveal.insufficient.name)
          'cm': readIntValue(payload['cm']),
        if (reveal != OculumCombatScoutReveal.insufficient.name)
          'criticalLevel': readIntValue(payload['level']),
        if (reveal != OculumCombatScoutReveal.insufficient.name)
          'grade': readIntValue(payload['grade']),
        if (reveal != OculumCombatScoutReveal.insufficient.name)
          'difficulty': '${payload['difficulty']}',
        if (reveal != OculumCombatScoutReveal.insufficient.name)
          'rollDifficulty': readIntValue(payload['rollDifficulty']),
        'weakPoint': payload['weakPoint'] == true,
      });
      final request = onlineCombatRequests[id];
      if (request != null && request['status'] == 'pending') {
        request['status'] = 'resolved';
        aggiungiLog(
          '[PERCEZIONE] ${payload['targetName']}: ${reveal == OculumCombatScoutReveal.exact.name
              ? 'lettura esatta; livello ${payload['level']}'
              : reveal == OculumCombatScoutReveal.approximate.name
              ? 'lettura approssimata; livello ${payload['level']}, grado ${payload['grade']}'
              : 'non senti abbastanza'}${payload['weakPoint'] == true ? '; punto debole: Fragilità Semi Letale per te e gli alleati fino a fine fight' : ''}.',
        );
      }
    } else {
      return;
    }
    programmaSalvataggio();
    if (mounted) setState(() {});
  }
}
