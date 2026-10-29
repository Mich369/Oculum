part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumCombatScout on _OculumHomePageState {
  String monsterBookPartyDiscoveryKey(String monsterId) =>
      '$permissionCampaignId:${monsterId.trim()}';

  Map<String, dynamic>? monsterBookPartyKnowledge(String monsterId) =>
      monsterBookPartyDiscoveries[monsterBookPartyDiscoveryKey(monsterId)];

  List<Map<String, dynamic>> monsterBookPartyDiscoverySnapshotEntries() {
    final prefix = '$permissionCampaignId:';
    final entries = <Map<String, dynamic>>[];
    for (final entry in monsterBookPartyDiscoveries.entries) {
      if (!entry.key.startsWith(prefix)) continue;
      final id = entry.key.substring(prefix.length).trim();
      if (id.isEmpty || monsterBookEntryById(id) == null) continue;
      final knowledge = entry.value;
      final seen = knowledge['seen'] == true;
      final nameKnown = knowledge['nameKnown'] == true;
      final weakPoint = knowledge['weakPoint'] == true;
      final pagePurchased = knowledge['pagePurchased'] == true;
      final themeUnlocked = knowledge['themeUnlocked'] == true || pagePurchased;
      if (!seen &&
          !nameKnown &&
          !weakPoint &&
          !pagePurchased &&
          !themeUnlocked) {
        continue;
      }
      entries.add({
        'monsterBookId': id,
        'seen': seen,
        'nameKnown': nameKnown || pagePurchased,
        'weakPoint': weakPoint || pagePurchased,
        'pagePurchased': pagePurchased,
        'themeUnlocked': themeUnlocked,
      });
    }
    entries.sort(
      (a, b) => '${a['monsterBookId']}'.compareTo('${b['monsterBookId']}'),
    );
    return entries;
  }

  Future<void> sendMonsterBookPartyDiscoverySnapshot() async {
    final service = realtimeService;
    if (service?.isConnected != true) return;
    final entries = monsterBookPartyDiscoverySnapshotEntries();
    const batchSize = 50;
    for (var start = 0; start < entries.length; start += batchSize) {
      if (!mounted || realtimeService != service || !service!.isConnected) {
        return;
      }
      final batch = entries.skip(start).take(batchSize).toList();
      final batchIndex = start ~/ batchSize;
      final sent = await service.sendMonsterBookDiscoverySnapshot(
        permissionEnvelope({
          'id':
              'book-snapshot:$permissionCampaignId:$batchIndex:${batch.length}',
          'discoveries': batch,
        }),
      );
      if (!sent) return;
      if (start + batchSize < entries.length) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
    }
  }

  bool monsterBookPartyKnowsName(String monsterId) =>
      !(partyChest['forgottenMonsterIds'] as List? ?? []).contains(
        oculumPartyHuntSpeciesId(monsterId),
      ) &&
      oculumMonsterBookNameIsDiscovered(monsterBookPartyKnowledge(monsterId));

  bool monsterBookPartyKnowsWeakPoint(String monsterId) =>
      monsterBookPartyKnowledge(monsterId)?['weakPoint'] == true;
  bool monsterBookPartyKnowsAny(String monsterId) {
    final knowledge = monsterBookPartyKnowledge(monsterId);
    return const [
          'seen',
          'nameKnown',
          'weakPoint',
          'pagePurchased',
        ].any((key) => knowledge?[key] == true) ||
        partyHuntsForMonster(monsterId).isNotEmpty;
  }

  void rememberMonsterBookPartyDiscovery(
    String monsterId, {
    bool nameKnown = false,
    bool seen = false,
    bool weakPoint = false,
    bool pagePurchased = false,
    bool themeUnlocked = false,
    bool broadcast = false,
  }) {
    final id = monsterId.trim();
    if (id.isEmpty || monsterBookEntryById(id) == null) return;
    if ((nameKnown || pagePurchased) && canManagePartyQuests) {
      final forgotten = List<dynamic>.from(
        partyChest['forgottenMonsterIds'] as List? ?? [],
      );
      if (forgotten.remove(oculumPartyHuntSpeciesId(id))) {
        partyChest['forgottenMonsterIds'] = forgotten;
        partyChest['revision'] = readIntValue(partyChest['revision']) + 1;
        unawaited(sendPartyChestState());
      }
    }
    final key = monsterBookPartyDiscoveryKey(id);
    final previous = monsterBookPartyDiscoveries[key] ?? const {};
    final next = <String, dynamic>{
      ...previous,
      'monsterBookId': id,
      'seen': previous['seen'] == true || seen,
      'nameKnown': previous['nameKnown'] == true || nameKnown || pagePurchased,
      'weakPoint': previous['weakPoint'] == true || weakPoint || pagePurchased,
      'pagePurchased': previous['pagePurchased'] == true || pagePurchased,
      'themeUnlocked':
          previous['themeUnlocked'] == true || themeUnlocked || pagePurchased,
      'discoveredAt':
          previous['discoveredAt'] ?? DateTime.now().toIso8601String(),
    };
    if (mapEquals(previous, next)) return;
    monsterBookPartyDiscoveries[key] = next;
    syncMonsterThemeUnlocks();
    combatKnowledgeRevision.value++;
    programmaSalvataggio();
    if (broadcast && realtimeService?.isConnected == true) {
      unawaited(
        realtimeService!.sendMonsterBookDiscovery(
          permissionEnvelope({
            'id': 'book:$permissionCampaignId:$id:${next['discoveredAt']}',
            'monsterBookId': id,
            'nameKnown': nameKnown || pagePurchased,
            'seen': seen,
            'weakPoint': weakPoint || pagePurchased,
            'pagePurchased': pagePurchased,
            'themeUnlocked': next['themeUnlocked'] == true,
          }),
        ),
      );
    }
    if (mounted) setState(() {});
  }

  void receiveMonsterBookPartyDiscovery(Map<String, dynamic> payload) {
    if (!validPermissionSender(payload) ||
        payload['campaignId'] != permissionCampaignId) {
      return;
    }
    final monsterId = '${payload['monsterBookId'] ?? ''}'.trim();
    if (monsterId.isEmpty || monsterBookEntryById(monsterId) == null) return;
    rememberMonsterBookPartyDiscovery(
      monsterId,
      nameKnown: payload['nameKnown'] == true,
      seen: payload['seen'] == true,
      weakPoint: payload['weakPoint'] == true,
      pagePurchased: payload['pagePurchased'] == true,
      themeUnlocked: payload['themeUnlocked'] == true,
    );
  }

  void receiveMonsterBookPartyDiscoverySnapshot(Map<String, dynamic> payload) {
    if (payload['monsterBookDiscoverySnapshot'] != true ||
        !validPermissionSender(payload) ||
        payload['campaignId'] != permissionCampaignId ||
        payload['discoveries'] is! List) {
      return;
    }
    final incoming = payload['discoveries'] as List;
    if (incoming.length > 50) return;
    var changed = false;
    for (final raw in incoming) {
      if (raw is! Map) continue;
      final id = '${raw['monsterBookId'] ?? ''}'.trim();
      if (id.isEmpty || monsterBookEntryById(id) == null) continue;
      final key = monsterBookPartyDiscoveryKey(id);
      final previous = monsterBookPartyDiscoveries[key] ?? const {};
      final pagePurchased =
          previous['pagePurchased'] == true || raw['pagePurchased'] == true;
      final next = <String, dynamic>{
        ...previous,
        'monsterBookId': id,
        'seen': previous['seen'] == true || raw['seen'] == true,
        'nameKnown':
            previous['nameKnown'] == true ||
            raw['nameKnown'] == true ||
            pagePurchased,
        'weakPoint':
            previous['weakPoint'] == true ||
            raw['weakPoint'] == true ||
            pagePurchased,
        'pagePurchased': pagePurchased,
        'themeUnlocked':
            previous['themeUnlocked'] == true ||
            raw['themeUnlocked'] == true ||
            pagePurchased,
        'discoveredAt':
            previous['discoveredAt'] ?? DateTime.now().toIso8601String(),
      };
      if (mapEquals(previous, next)) continue;
      monsterBookPartyDiscoveries[key] = next;
      changed = true;
    }
    if (!changed) return;
    syncMonsterThemeUnlocks();
    combatKnowledgeRevision.value++;
    programmaSalvataggio();
    if (mounted) setState(() {});
  }

  String monsterBookIdForCombatToken(Map<String, dynamic> token) {
    final fromToken =
        '${token['monsterBookId'] ?? token['monsterBookSourceId'] ?? ''}'
            .trim();
    if (fromToken.isNotEmpty) return fromToken;
    final index = localSheetIndexForOculumTag(onlineCombatTokenTag(token));
    if (index < 0 || index >= schedePersonaggio.length) return '';
    return '${schedePersonaggio[index]['monsterBookSourceId'] ?? ''}'.trim();
  }

  bool combatTokenWeakPointKnown(Map<String, dynamic> token) {
    if (!combatTokenHasAccessibleAnatomicalWeakPoint(token)) {
      return false;
    }
    final targetTag = onlineCombatTokenTag(token);
    final discovery =
        combatDiscoveries[combatDiscoveryKey(
          targetTag,
          combatScoutSide(sheetTagAt(schedaCorrente)),
        )];
    return discovery?['weakPoint'] == true ||
        monsterBookPartyKnowsWeakPoint(monsterBookIdForCombatToken(token));
  }

  void forgetCombatDiscoveries(String encounter) {
    final previousCount = combatDiscoveries.length;
    combatDiscoveries.removeWhere(
      (key, _) => key.startsWith('$activeCampaignId:$encounter:'),
    );
    if (combatDiscoveries.length != previousCount) {
      combatKnowledgeRevision.value++;
    }
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
        combatKnowledgeRevision.value++;
      }
    }
  }

  HiddenEyeStat? bestCombatScoutStat() {
    final candidates = hiddenEyeStats
        .where(
          (s) =>
              oculumScoutReadingStatIds.contains(s.id) &&
              (s.id != 'lettura_aura' || s.unlocked),
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

  bool combatScoutVeilBuffHalvedForSheet(String tag, String observerSide) =>
      combatDiscoveries[combatDiscoveryKey(
        tag,
        observerSide,
      )]?['veilBuffHalved'] ==
      true;

  bool sheetCombatScoutHasVeilAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return false;
    final conditions = index == schedaCorrente
        ? activeConditions.map((condition) => condition.toJson())
        : (schedePersonaggio[index]['conditions'] as List? ?? const [])
              .whereType<Map>();
    return conditions.any((condition) {
      final type = '${condition['conditionType'] ?? condition['type'] ?? ''}';
      return type == 'invisibile' || type == 'trasparenza';
    });
  }

  int sheetCombatScoutVeloAt(
    int index, {
    String? observerSide,
    int? observerGrade,
  }) {
    if (index < 0 || index >= schedePersonaggio.length) return 0;
    final halveVeil =
        observerSide != null &&
        combatScoutVeilBuffHalvedForSheet(sheetTagAt(index), observerSide);
    if (index == schedaCorrente) {
      final fullVelo = activeCombatScoutVelo();
      if (!halveVeil && observerGrade == null) return fullVelo;
      final fullVeilBonus = conditionSubtraitBonus('velo');
      return max(
        0,
        fullVelo -
            fullVeilBonus +
            oculumCombatScoutVeilBonus(
              conditions: activeConditions.map((c) => c.toJson()),
              level: activeCriticalLevel(),
              exactPerceptionReading: halveVeil,
              observerGrade: observerGrade,
              targetGrade: activeCriticalGrade(),
            ),
      );
    }
    final sheet = schedePersonaggio[index];
    final raw = (sheet['hiddenEyeStats'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .where((candidate) => candidate['id'] == 'velo')
        .firstOrNull;
    if (raw == null || raw['unlocked'] == false) return 0;
    final level = sheetIntValueAt(index, 'livello');
    final conditions = (sheet['conditions'] as List? ?? const [])
        .whereType<Map>();
    final veilBonus = oculumCombatScoutVeilBonus(
      conditions: conditions,
      level: level,
      exactPerceptionReading: halveVeil,
      observerGrade: observerGrade,
      targetGrade: sheetIntValueAt(index, 'grado'),
    );
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
              0) +
          veilBonus,
    );
  }

  String combatScoutReadText(OculumCombatScoutRead read) {
    return switch (read.reveal) {
      OculumCombatScoutReveal.exact => 'lettura esatta',
      OculumCombatScoutReveal.approximate => 'lettura approssimata',
      OculumCombatScoutReveal.insufficient => 'non senti abbastanza',
    };
  }

  Map<String, int> scoutCoreStatsAt(int index) => {
    for (final key in ['resilienza', 'volonta', 'materia', 'oculum'])
      key: sheetIntValueAt(index, key),
  };

  Map<String, dynamic> scoutAdditionalReading(
    int index,
    int natural,
    bool success,
    int observerPower, {
    int total = 0,
    bool perception = false,
    int? observationRequirement,
  }) => {
    if (!success)
      'blockedByStat': oculumScoutDominantStat(scoutCoreStatsAt(index)),
    if (success && natural >= 18)
      'powerBand': oculumScoutPowerBand(
        observerPower,
        scoutTotalPowerAt(index),
      ),
    if (perception &&
        oculumExactPowerChance(
              total,
              success: success,
              targetPower: scoutTotalPowerAt(index),
              observationRequirement: observationRequirement,
            ) >
            Random.secure().nextInt(100))
      'exactPower': scoutTotalPowerAt(index),
  };

  String scoutLogReading(Map<String, dynamic> payload, String fallback) {
    if (payload['scannerOutOfRange'] == true) return 'oltre la portata';
    if (payload['scannerEstimate'] is num) {
      return 'potere totale stimato ${readIntValue(payload['scannerEstimate'])} (±10%)';
    }
    if (payload['exactPower'] is num) {
      return 'potere totale ${readIntValue(payload['exactPower'])}';
    }
    final power = oculumPowerReadPhrases['${payload['powerBand'] ?? ''}'];
    if (power != null) return power;
    final blocked = '${payload['blockedByStat'] ?? ''}';
    return const [
          'resilienza',
          'volonta',
          'materia',
          'oculum',
        ].contains(blocked)
        ? oculumScoutFailurePhrase(blocked)
        : fallback;
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
      'veilBuffHalved':
          previous?['veilBuffHalved'] == true || read['veilBuffHalved'] == true,
      'bodyObservers': <String>{
        ...((previous?['bodyObservers'] as List?) ?? const [])
            .whereType<String>(),
        ...((read['bodyObservers'] as List?) ?? const []).whereType<String>(),
      }.toList(),
    };
    combatKnowledgeRevision.value++;
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
    final locallyVisibleSheets = <Map<String, dynamic>>[
      for (var i = 0; i < schedePersonaggio.length; i++)
        if (i != schedaCorrente)
          {'sheetTag': sheetTagAt(i), 'name': nomeSchedaPersonaggio(i)},
    ];
    final activeEncounterTargets = online ? onlineAttackTokens() : const [];
    // Percezione is an exploration action too: when the Master has not
    // published an initiative order, use the sheets already visible to this
    // client instead of requiring combat tokens.
    final tokens = activeEncounterTargets.isNotEmpty
        ? activeEncounterTargets
        : locallyVisibleSheets;
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
    if (currentTurnTrackerIsActive() &&
        !(target['general'] == true
            ? await spendCombatRollResource()
            : await spendScoutObservationResource(hiddenEyeTotal(stat)))) {
      return;
    }
    if (target['general'] == true) {
      await tiraSottotrattoOcchio(
        stat,
        actionLabel: '${stat.nome} · lettura generale',
        onResolved: (natural, total) {
          discoverLavastrelloNest(total);
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
          'observerGrade': activeCriticalGrade(),
          'observerPower': oculumScoutPower(activeCriticalLevel(), [
            resilienzaTotale(),
            volontaTotale(),
            materiaTotale(),
            oculumTotale(),
          ], grade: activeCriticalGrade()),
          'scoutStat': stat.id,
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
            targetVelo: sheetCombatScoutVeloAt(
              index,
              observerSide: 'ally',
              observerGrade: activeCriticalGrade(),
            ),
            targetGrade: sheetIntValueAt(index, 'grado'),
            targetCm: sheetRollBonusAt(index, 'cm'),
            targetPower: scoutTotalPowerAt(index),
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
            'veilBuffHalved': read.isExact && sheetCombatScoutHasVeilAt(index),
            'weakPoint': oculumScoutRevealsWeakPoint(
              natural: natural,
              rollTotal: total,
              targetPower: scoutTotalPowerAt(index),
              read: read,
            ),
            if (read.isExact) 'bodyObservers': [sheetTagAt(schedaCorrente)],
          });
          final monsterBookId = monsterBookIdForCombatToken(target);
          if (read.isExact && monsterBookId.isNotEmpty) {
            rememberMonsterBookPartyDiscovery(
              monsterBookId,
              seen: true,
              nameKnown: true,
              themeUnlocked: oculumScoutUnlocksTheme(
                true,
                Random.secure().nextInt(100),
              ),
              broadcast: true,
            );
          }
          if (oculumScoutRevealsWeakPoint(
                natural: natural,
                rollTotal: total,
                targetPower: scoutTotalPowerAt(index),
                read: read,
              ) &&
              monsterBookId.isNotEmpty) {
            rememberMonsterBookPartyDiscovery(
              monsterBookId,
              seen: true,
              weakPoint: true,
              broadcast: true,
            );
          } else if (monsterBookId.isNotEmpty) {
            rememberMonsterBookPartyDiscovery(
              monsterBookId,
              seen: true,
              broadcast: true,
            );
          }
          final extra = scoutAdditionalReading(
            index,
            natural,
            read.isExact,
            readIntValue(request['observerPower']),
            total: total,
            perception: oculumScoutReadingStatIds.contains(stat.id),
            observationRequirement: read.requirement,
          );
          rememberKnownPower(
            targetTag,
            extra,
            order: int.tryParse('${request['id']}'.split(':').last),
          );
          if (extra['exactPower'] is num) allowAuraExactObserver(index, own);
          aggiungiLog(
            '[PERCEZIONE] ${scoutLogReading(extra, combatScoutReadText(read))}.',
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
    final combatTokens = onlineCombatTokens();
    final tags = combatTokens.isNotEmpty
        ? combatTokens.map(onlineCombatTokenTag).toSet()
        : <String>{
            for (var i = 0; i < schedePersonaggio.length; i++) sheetTagAt(i),
          };
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
      if (payload['kind'] == 'aura_compare') {
        final previous = onlineCombatRequests[id];
        final reply = previous?['scoutPhase'] == 'result'
            ? previous!
            : passiveAuraReply(targetIndex, payload);
        if (reply.isEmpty) return;
        trimPassiveAuraHistory();
        onlineCombatRequests[id] = reply;
        unawaited(
          realtimeService?.sendCombatEvent('combat_scout', {
            ...permissionEnvelope(reply),
            'senderTag': target,
          }),
        );
        return;
      }
      if (payload['kind'] == 'power_scanner') {
        receivePowerScanner(payload, targetIndex);
        return;
      }
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
        targetVelo: sheetCombatScoutVeloAt(
          targetIndex,
          observerSide: combatScoutSide(source),
          observerGrade: readIntValue(payload['observerGrade']),
        ),
        targetGrade: sheetIntValueAt(targetIndex, 'grado'),
        targetCm: sheetRollBonusAt(targetIndex, 'cm'),
        targetPower: scoutTotalPowerAt(targetIndex),
      );
      final natural = readIntValue(payload['natural']);
      final weakPoint = oculumScoutRevealsWeakPoint(
        natural: natural,
        rollTotal: readIntValue(payload['total']),
        targetPower: scoutTotalPowerAt(targetIndex),
        read: read,
      );
      final veilBuffHalved =
          read.isExact && sheetCombatScoutHasVeilAt(targetIndex);
      final targetSheet = schedePersonaggio[targetIndex];
      final monsterBookId =
          '${payload['monsterBookId'] ?? targetSheet['monsterBookSourceId'] ?? ''}'
              .trim();
      final reply = <String, dynamic>{
        ...payload,
        'kind': 'scout',
        'scoutPhase': 'result',
        'status': 'resolved',
        'success': read.isExact,
        ...scoutAdditionalReading(
          targetIndex,
          readIntValue(payload['natural']),
          read.isExact,
          readIntValue(payload['observerPower']),
          total: readIntValue(payload['total']),
          perception: oculumScoutReadingStatIds.contains(payload['scoutStat']),
          observationRequirement: read.requirement,
        ),
        'themeUnlocked':
            monsterBookId.isNotEmpty &&
            oculumScoutUnlocksTheme(read.isExact, Random.secure().nextInt(100)),
        'reveal': read.reveal.name,
        if (read.showsProbabilities) 'level': read.targetLevel,
        if (read.showsProbabilities) 'cm': read.targetCm,
        if (read.showsProbabilities) 'grade': read.targetGrade,
        if (read.showsProbabilities)
          'difficulty': normalizedCampaignDifficulty(),
        if (read.showsProbabilities)
          'rollDifficulty': sheetDifficoltaTiroAt(targetIndex),
        'weakPoint': weakPoint,
        'veilBuffHalved': veilBuffHalved,
        if (read.isExact) 'bodyObservers': [source],
        if (monsterBookId.isNotEmpty) 'monsterBookId': monsterBookId,
      };
      for (final key in ['senderTag', 'senderRole', 'sessionId']) {
        reply.remove(key);
      }
      onlineCombatRequests[id] = reply;
      if (reply['exactPower'] is num) {
        allowAuraExactObserver(targetIndex, source);
      }
      if (read.isExact && monsterBookId.isNotEmpty) {
        rememberMonsterBookPartyDiscovery(
          monsterBookId,
          seen: true,
          nameKnown: true,
          themeUnlocked: reply['themeUnlocked'] == true,
        );
      }
      if (read.showsProbabilities) {
        rememberCombatScoutRead(
          combatDiscoveryKey(target, combatScoutSide(source)),
          {
            'reveal': read.reveal.name,
            'veilBuffHalved': veilBuffHalved,
            if (read.isExact) 'bodyObservers': [source],
            'weakPoint': weakPoint,
          },
        );
      }
      if (weakPoint) {
        if (monsterBookId.isNotEmpty) {
          rememberMonsterBookPartyDiscovery(
            monsterBookId,
            seen: true,
            weakPoint: true,
          );
        }
        rememberCombatScoutRead(
          combatDiscoveryKey(target, combatScoutSide(source)),
          {'weakPoint': true},
        );
      }
      aggiungiLog(
        '[PERCEZIONE] ${payload['sourceName']} ha ottenuto ${combatScoutReadText(read)}${veilBuffHalved ? '; bonus Velo di Invisibilità/Trasparenza dimezzato per difetto' : ''}${weakPoint ? ' e il punto debole fino a fine fight' : ''}.',
      );
      unawaited(
        realtimeService?.sendCombatEvent('combat_scout', {
          ...permissionEnvelope(reply),
          'senderTag': target,
        }),
      );
    } else if (payload['scoutPhase'] == 'result') {
      if (payload['kind'] == 'aura_compare') {
        final request = onlineCombatRequests[id];
        if (payload['senderTag'] != target ||
            request == null ||
            request['kind'] != 'aura_compare' ||
            request['targetTag'] != target ||
            request['sourceTag'] != source ||
            !controlsOnlineCombatSheet(source)) {
          return;
        }
        request['status'] = 'resolved';
        faunaForOwnedSheet(source, () {
          rememberAuraBand(target, '${payload['powerBand'] ?? ''}');
          rememberKnownPower(target, payload);
        });
        return;
      }
      if (payload['kind'] == 'power_scanner') {
        receivePowerScanner(payload, -1);
        return;
      }
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
        'veilBuffHalved': payload['veilBuffHalved'] == true,
        if (reveal == 'exact') 'bodyObservers': [source],
      });
      final monsterBookId = '${payload['monsterBookId'] ?? ''}'.trim();
      if (monsterBookId.isNotEmpty) {
        rememberMonsterBookPartyDiscovery(
          monsterBookId,
          seen: true,
          weakPoint: payload['weakPoint'] == true,
          nameKnown: payload['success'] == true,
          themeUnlocked: payload['themeUnlocked'] == true,
        );
      }
      final request = onlineCombatRequests[id];
      if (request != null && request['status'] == 'pending') {
        faunaForOwnedSheet(source, () => rememberKnownPower(target, payload));
        if (reveal == 'exact') {
          faunaForOwnedSheet(source, () => ogorCoreSuccessfulRoll('scout:$id'));
        }
        request['status'] = 'resolved';
        aggiungiLog(
          '[PERCEZIONE] ${scoutLogReading(payload, reveal == 'exact'
              ? 'lettura esatta'
              : reveal == 'approximate'
              ? 'lettura approssimata'
              : 'non senti abbastanza')}.',
        );
      }
    } else {
      return;
    }
    programmaSalvataggio();
    if (mounted) setState(() {});
  }
}
