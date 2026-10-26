part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

bool oculumAuraReadsPower(int aura) => aura >= 20;
bool oculumCombatRequestIsObservation(Map request) =>
    const {'scout', 'power_scanner', 'aura_compare'}.contains(request['kind']);

Map<String, dynamic> oculumMergeKnownPower(
  Map<String, dynamic> previous,
  Map<String, dynamic> reading,
  int order,
) {
  final result = <String, dynamic>{...previous};
  for (final pair in const [
    ('exactPower', 'exactOrder'),
    ('scannerEstimate', 'estimateOrder'),
  ]) {
    final value = reading[pair.$1];
    if (value is num &&
        value >= 0 &&
        order >= readIntValue(previous[pair.$2])) {
      result[pair.$1] = value.toInt();
      result[pair.$2] = order;
    }
  }
  return result;
}

extension _OculumAuraKnowledge on _OculumHomePageState {
  void refreshAuraPowerRevision(Map<String, dynamic> token, int index) {
    if (index < 0) return;
    final power = scoutTotalPowerAt(index);
    if (token['auraPowerInternal'] != power) {
      token['auraPowerInternal'] = power;
      token['auraPowerRevision'] = readIntValue(token['auraPowerRevision']) + 1;
    }
  }

  void syncSavedAuraPowerToMasterEncounters() {
    if (!realtimeIsMasterRole || schedePersonaggio.isEmpty) return;
    final index = schedaCorrente;
    final tag = sheetTagAt(index);
    final power = scoutTotalPowerAt(index);
    bool changed(Map token) =>
        '${token['sheetTag'] ?? token['id'] ?? ''}' == tag &&
        token['auraPowerInternal'] != power;
    final changedHere = masterInitiativeTokens.any(changed);
    final changedElsewhere = masterInitiativeGroups.any(
      (group) =>
          (group['tokens'] as List? ?? const []).whereType<Map>().any(changed),
    );
    if (changedHere || changedElsewhere) {
      syncSharedSheetToMasterEncounters(index);
    }
  }

  int get auraReadingTotal {
    final aura = hiddenEyeStats
        .where((s) => s.id == 'lettura_aura' && s.unlocked)
        .firstOrNull;
    return aura == null ? 0 : hiddenEyeTotal(aura);
  }

  bool get auraCanReadPower => oculumAuraReadsPower(auraReadingTotal);
  String auraKnowledgeKey(String tag) => '$permissionCampaignId:$tag';

  Map<String, dynamic> knownPowerFor(String tag) {
    final all = planarState['knownPowers'];
    final value = all is Map ? all[auraKnowledgeKey(tag)] : null;
    if (value is Map) return Map<String, dynamic>.from(value);
    final own = planarState['knownOwnPower'];
    if (tag == sheetTagAt(schedaCorrente) && own is Map) {
      return Map<String, dynamic>.from(own);
    }
    return <String, dynamic>{};
  }

  bool rememberKnownPower(
    String tag,
    Map<String, dynamic> reading, {
    int? order,
  }) {
    if (tag.isEmpty) return false;
    final previous = knownPowerFor(tag);
    final sequence =
        order ??
        int.tryParse('${reading['id'] ?? ''}'.split(':').last) ??
        DateTime.now().microsecondsSinceEpoch;
    final next = oculumMergeKnownPower(previous, reading, sequence);
    if (jsonEncode(previous) == jsonEncode(next)) return false;
    final all = Map<String, dynamic>.from(
      planarState['knownPowers'] as Map? ?? {},
    );
    all[auraKnowledgeKey(tag)] = next;
    planarState['knownPowers'] = all;
    if (tag == sheetTagAt(schedaCorrente)) planarState['knownOwnPower'] = next;
    programmaSalvataggio(invalidateCaches: false);
    if (mounted) setState(() {});
    return true;
  }

  void rememberAuraBand(String tag, String band) {
    if (!oculumPowerReadPhrases.containsKey(band)) return;
    final record = knownPowerFor(tag);
    if (record['powerBand'] == band) return;
    record['powerBand'] = band;
    final all = Map<String, dynamic>.from(
      planarState['knownPowers'] as Map? ?? {},
    );
    all[auraKnowledgeKey(tag)] = record;
    planarState['knownPowers'] = all;
    programmaSalvataggio(invalidateCaches: false);
    if (mounted) setState(() {});
  }

  void allowAuraExactObserver(int index, String source) {
    if (index < 0 || source.isEmpty) return;
    final runtime = index == schedaCorrente
        ? planarState
        : Map<String, dynamic>.from(
            schedePersonaggio[index]['planarRuntime'] as Map? ?? {},
          );
    final observers = Map<String, dynamic>.from(
      runtime['auraExactObservers'] as Map? ?? {},
    );
    observers[auraKnowledgeKey(source)] = true;
    runtime['auraExactObservers'] = observers;
    if (index != schedaCorrente) {
      schedePersonaggio[index]['planarRuntime'] = runtime;
    }
  }

  bool auraExactObserverAllowed(int index, String source) {
    final runtime = index == schedaCorrente
        ? planarState
        : schedePersonaggio[index]['planarRuntime'];
    if (runtime is Map &&
        (runtime['auraExactObservers'] as Map?)?[auraKnowledgeKey(source)] ==
            true) {
      return true;
    }
    final observerIndex = localSheetIndexForOculumTag(source);
    if (observerIndex < 0) return false;
    final observerRuntime = observerIndex == schedaCorrente
        ? planarState
        : schedePersonaggio[observerIndex]['planarRuntime'];
    final known = observerRuntime is Map
        ? observerRuntime['knownPowers']
        : null;
    final record = known is Map
        ? known[auraKnowledgeKey(sheetTagAt(index))]
        : null;
    return record is Map && record['exactPower'] is num;
  }

  Map<String, dynamic> passiveAuraReply(
    int targetIndex,
    Map<String, dynamic> request,
  ) {
    if (targetIndex < 0 ||
        !oculumAuraReadsPower(readIntValue(request['observerAura']))) {
      return {};
    }
    final power = scoutTotalPowerAt(targetIndex);
    return <String, dynamic>{
      for (final key in [
        'id',
        'scope',
        'encounterId',
        'sourceTag',
        'targetTag',
      ])
        key: request[key],
      'kind': 'aura_compare',
      'scoutPhase': 'result',
      'status': 'resolved',
      'powerBand': oculumScoutPowerBand(
        readIntValue(request['observerPower']),
        power,
      ),
      if (request['refreshKnownPower'] == true &&
          auraExactObserverAllowed(targetIndex, '${request['sourceTag']}'))
        'exactPower': power,
    };
  }

  void trimPassiveAuraHistory() {
    final old = onlineCombatRequests.entries
        .where(
          (e) =>
              e.value['kind'] == 'aura_compare' &&
              e.value['status'] != 'pending',
        )
        .map((e) => e.key)
        .toList();
    for (final key in old.take(max(0, old.length - 64))) {
      onlineCombatRequests.remove(key);
    }
  }

  void scheduleAuraObservations() {
    if (!auraCanReadPower ||
        auraObservationPending ||
        schedePersonaggio.isEmpty) {
      return;
    }
    final own = sheetTagAt(schedaCorrente),
        power = scoutTotalPowerAt(schedaCorrente);
    final targets = onlineAttackTokens();
    final signature =
        '$own:$power:$permissionCampaignId:$onlineCombatEncounterId:${realtimeService?.isConnected}:${targets.map((t) => '${onlineCombatTokenTag(t)}:${t['auraPowerRevision']}:${knownPowerFor(onlineCombatTokenTag(t))['exactPower'] is num}').join('|')}';
    if (signature == auraObservationSignature) return;
    auraObservationSignature = signature;
    auraObservationPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted ||
            sheetTagAt(schedaCorrente) != own ||
            !auraCanReadPower) {
          return;
        }
        if (knownPowerFor(own)['exactPower'] != power) {
          rememberKnownPower(own, {'exactPower': power});
        }
        for (final target in targets) {
          if (!mounted || sheetTagAt(schedaCorrente) != own) break;
          final tag = onlineCombatTokenTag(target);
          final refreshExact = knownPowerFor(tag)['exactPower'] is num;
          final key =
              '$permissionCampaignId:$onlineCombatEncounterId:$own:$tag:$power:${target['auraPowerRevision']}:$refreshExact';
          if (auraObservedTargets.contains(key)) continue;
          final index = localSheetIndexForOculumTag(tag);
          if (index >= 0) {
            auraObservedTargets.add(key);
            rememberAuraBand(
              tag,
              oculumScoutPowerBand(power, scoutTotalPowerAt(index)),
            );
            if (refreshExact) {
              rememberKnownPower(tag, {'exactPower': scoutTotalPowerAt(index)});
            }
          } else if (realtimeService?.isConnected == true) {
            auraObservedTargets.add(key);
            final request = <String, dynamic>{
              'id': 'aura:$own:${DateTime.now().microsecondsSinceEpoch}',
              'kind': 'aura_compare',
              'status': 'pending',
              'scoutPhase': 'request',
              'scope': permissionScope,
              'encounterId': onlineCombatEncounterId,
              'sourceTag': own,
              'targetTag': tag,
              'sourceName': realtimeDisplayName(),
              'observerAura': auraReadingTotal,
              'observerPower': power,
              'refreshKnownPower': refreshExact,
            };
            onlineCombatRequests.removeWhere(
              (_, old) =>
                  old['kind'] == 'aura_compare' &&
                  old['status'] == 'pending' &&
                  old['sourceTag'] == own &&
                  old['targetTag'] == tag,
            );
            trimPassiveAuraHistory();
            onlineCombatRequests['${request['id']}'] = request;
            await realtimeService?.sendCombatEvent(
              'combat_scout',
              permissionEnvelope(request),
            );
          }
          if (auraObservedTargets.length > 512) {
            auraObservedTargets.remove(auraObservedTargets.first);
          }
        }
      } finally {
        auraObservationPending = false;
      }
    });
  }

  Future<bool> spendScoutObservationResource(
    int subtrait, {
    int? percentile,
  }) async {
    if (!currentTurnTrackerIsActive()) return true;
    final tokens = _writableOnlineCombatTokens();
    final tag = sheetTagAt(schedaCorrente);
    final index = tokens.indexWhere((t) => publicInitiativeSourceTag(t) == tag);
    final active = _usesLocalMasterInitiative
        ? masterInitiativeActiveIndex
        : readIntValue(realtimeVisibleInitiativeSnapshot['activeIndex']);
    final ownAction =
        index >= 0 &&
        index == active &&
        !readBoolValue(tokens[index]['actionUsed']);
    final availableReaction =
        index >= 0 && masterInitiativeReactionAvailable(tokens[index]) > 0;
    if (totalPowerExhausted && !ownAction) return false;
    if (!ownAction && !availableReaction) return spendCombatRollResource();
    final chance = oculumScoutNoSpendChance(subtrait);
    final rolled = percentile ?? Random.secure().nextInt(100);
    if (rolled < chance) {
      aggiungiLog(
        '[OSSERVAZIONE] Sottotratto +$subtrait: tiro ${rolled + 1}/100, probabilità $chance%. Nessuna Azione/Reazione consumata.',
      );
      return true;
    }
    return spendCombatRollResource();
  }

  Widget knownPowerBadge(String tag) {
    final record = knownPowerFor(tag);
    final exact = record['exactPower'], estimate = record['scannerEstimate'];
    final band = oculumPowerReadPhrases['${record['powerBand'] ?? ''}'];
    if (exact is! num && estimate is! num && band == null) {
      return const SizedBox.shrink();
    }
    final label = exact is num
        ? 'Potenza ${exact.toInt()}'
        : estimate is num
        ? 'Potenza ≈ ${estimate.toInt()}'
        : band!;
    final detail = exact is num
        ? 'Ultima Potenza totale esatta scoperta'
        : estimate is num
        ? 'Ultima stima del rilevatore (±10%)'
        : 'Confronto qualitativo: il numero non è stato scoperto';
    return Tooltip(
      message:
          '$detail${auraCanReadPower ? ' · Aura +20: aggiornamento automatico dei valori scoperti' : ''}',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Container(
          margin: const EdgeInsets.only(top: 3, bottom: 3),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1525),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (exact is num ? Colors.amberAccent : Colors.purpleAccent)
                  .withValues(alpha: .4),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: exact is num
                  ? const Color(0xFFE9D299)
                  : const Color(0xFFD1B7ED),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: .15,
            ),
          ),
        ),
      ),
    );
  }
}
