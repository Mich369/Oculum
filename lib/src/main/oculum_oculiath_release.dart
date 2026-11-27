part of '../../main.dart';

final _oculiathEscapeProofs = Expando<Set<String>>();
final _oculiathFallDrainActive = Expando<bool>();
const _oculiathPendingFalls = 'oculiathPendingFalls';

extension _OculumOculiathRelease on _OculumHomePageState {
  bool _matchesOculiathHoldContext(Map hold) =>
      hold['scope'] == permissionScope &&
      hold['fight'] == onlineCombatEncounterId &&
      '${hold['id'] ?? ''}'.isNotEmpty;

  int _oculiathCarrierCurrentWill(Map<String, dynamic> carrier) {
    final tag = onlineCombatTokenTag(carrier);
    final index = localSheetIndexForOculumTag(tag);
    return index >= 0
        ? oculiathCurrentWillAt(index)
        : max(0, readIntValue(carrier['will']));
  }

  Future<void> releaseOculiathHold(
    Map<String, dynamic> carrier, {
    required String reason,
    bool safeLanding = false,
  }) async {
    if (!mounted ||
        realtimeService?.isConnected == true && !realtimeIsMasterRole) {
      return;
    }
    final requested = oculiathHoldFor(carrier);
    if (requested == null || !_matchesOculiathHoldContext(requested)) return;
    final carrierTag = onlineCombatTokenTag(carrier);
    final tokens = _writableOnlineCombatTokens();
    final actualCarrier = tokens.where((token) {
      final hold = oculiathHoldFor(token);
      return combatTokenMatchesSheet(token, carrierTag) &&
          hold?['id'] == requested['id'];
    }).firstOrNull;
    if (actualCarrier == null) return;
    final targetTag = '${requested['targetTag'] ?? ''}';
    final target = tokens
        .where((token) => combatTokenMatchesSheet(token, targetTag))
        .firstOrNull;
    final index = localSheetIndexForOculumTag(targetTag);
    final ownsTarget = index >= 0 && controlsOnlineCombatSheet(targetTag);
    final holdId = '${requested['id']}';

    // Claim the release before updating either sheet or awaiting damage, so a
    // simultaneous voluntary release and destruction of the hook share it.
    actualCarrier.remove('oculiathHold');
    final surface = readDoubleValue(requested['surface'], fallback: double.nan);
    final elevation = readDoubleValue(
      requested['lastElevation'],
      fallback: double.nan,
    );
    final distance =
        oculumOculiathFallDistance(
          elevationMeters: elevation,
          surfaceElevationMeters: surface,
        ) ??
        0;
    if (target != null &&
        !vttShowingRemoteScene &&
        requested['scene'] == activeVttScene.id) {
      final mapToken = localMapTokenForInitiativeToken(target);
      if (mapToken != null && distance > 0) {
        mapToken['elevationMeters'] = surface;
        notifyVttCanvasChanged(save: true, publish: true);
      }
    }
    if (ownsTarget) {
      faunaForOwnedSheet(targetTag, () {
        for (final condition in activeConditions.where((condition) {
          return condition.conditionType == 'afferrato' &&
              condition.metadata['referenceCurseSource'] == holdId;
        }).toList()) {
          removeCondition(condition, force: true);
        }
        if (distance > 0 && safeLanding) {
          aggiungiLog(
            '[UNCINO] Atterri in piedi da ${distance.toStringAsFixed(1)} m.',
          );
        } else if (distance > 0) {
          final reflex = escapeSubtraitAt(schedaCorrente, 'riflessi');
          final roll = Random.secure().nextInt(60) + 1;
          final damage = oculumWingFallDamage(roll, reflex);
          aggiungiLog(
            '[CADUTA] ${distance.toStringAsFixed(1)} m. 1d60 ($roll) − '
            'Riflessi $reflex: $damage Danni prima delle protezioni.',
          );
          if (damage > 0) {
            final pending = Map<String, dynamic>.from(
              planarState[_oculiathPendingFalls] as Map? ?? const {},
            );
            pending[holdId] = {'campaign': activeCampaignId, 'damage': damage};
            planarState[_oculiathPendingFalls] = pending;
          }
        }
      });
    }
    combatLogFor(targetTag, '[UNCINO] $reason');
    captureActiveMasterInitiativeGroup();
    sendRealtimeInitiativeSnapshotIfPublished();
    programmaSalvataggio();
    if (ownsTarget && distance > 0 && !safeLanding) {
      scheduleOculiathDamageDrain();
    }
  }

  Future<void> _drainOculiathFalls() async {
    final campaign = activeCampaignId;
    final queued = <(String, String)>[];
    for (var index = 0; index < schedePersonaggio.length; index++) {
      final state = index == schedaCorrente
          ? planarState
          : schedePersonaggio[index]['planarRuntime'] as Map?;
      final pending = state?[_oculiathPendingFalls];
      if (pending is! Map) continue;
      final tag = sheetTagAt(index);
      if (!controlsOnlineCombatSheet(tag)) continue;
      for (final entry in pending.entries) {
        final row = entry.value;
        if (entry.key is String && row is Map && row['campaign'] == campaign) {
          queued.add((tag, entry.key as String));
        }
      }
    }
    for (final (tag, id) in queued) {
      if (!mounted || activeCampaignId != campaign) return;
      await _applyPendingOculiathFall(tag, id);
    }
  }

  Future<void> _applyPendingOculiathFall(String tag, String id) async {
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0 || !controlsOnlineCombatSheet(tag)) return;
    final original = schedaCorrente;
    final originalTag = sheetTagAt(original);
    final campaign = activeCampaignId;
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    try {
      if (index != original) {
        schedaCorrente = index;
        caricaStatoDaJson(schedePersonaggio[index]);
        ripristinaImpostazioniGlobali(global);
      }
      if (pawnPendingDamage.isNotEmpty) return;
      final pending = Map<String, dynamic>.from(
        planarState[_oculiathPendingFalls] as Map? ?? const {},
      );
      final row = pending[id];
      if (row is! Map || row['campaign'] != campaign) return;
      final damage = readIntValue(row['damage']);
      pending.remove(id);
      if (pending.isEmpty) {
        planarState.remove(_oculiathPendingFalls);
      } else {
        planarState[_oculiathPendingFalls] = pending;
      }
      salvaSchedaCorrenteInMemoria();
      programmaSalvataggio();
      if (damage <= 0) return;
      final element = incomingDamageElement;
      incomingDamageElement = 'contundente';
      try {
        await applicaDannoSubito(
          dannoEsplicito: damage,
          damagePacketId: 'oculiath-fall:$id',
        );
      } finally {
        if (mounted &&
            activeCampaignId == campaign &&
            sheetTagAt(schedaCorrente) == tag) {
          incomingDamageElement = element;
          salvaSchedaCorrenteInMemoria();
        }
      }
    } finally {
      if (mounted &&
          activeCampaignId == campaign &&
          sheetTagAt(schedaCorrente) == tag &&
          originalTag != tag) {
        final restore = localSheetIndexForOculumTag(originalTag);
        if (restore >= 0) {
          schedaCorrente = restore;
          caricaStatoDaJson(schedePersonaggio[restore]);
          ripristinaImpostazioniGlobali(global);
        }
      }
    }
  }

  Future<void> tryOculiathEscape(String trait, String resource) async {
    if (!const {'forza', 'controllo_corporeo'}.contains(trait) ||
        !const {'azione', 'reazione'}.contains(resource) ||
        !currentTurnTrackerIsActive() ||
        realtimeService?.isConnected == true && !realtimeIsMasterRole) {
      return;
    }
    final tag = sheetTagAt(schedaCorrente);
    if (!controlsOnlineCombatSheet(tag)) return;
    final carrier = oculiathCarrierHolding(tag);
    if (carrier == null) return;
    final hold = oculiathHoldFor(carrier);
    if (hold == null) return;
    final holdId = '${hold['id']}';
    final inFlight = _oculiathEscapeProofs[this] ??= <String>{};
    if (!inFlight.add(holdId)) return;
    final origin = currentSheetScrollId();
    try {
      if (!await requestUtilitySpend(resource, preferFreeReaction: false) ||
          !mounted ||
          origin != currentSheetScrollId() ||
          !_matchesOculiathHoldContext(hold)) {
        return;
      }
      final current = oculiathCarrierHolding(tag);
      if (current == null || oculiathHoldFor(current)?['id'] != holdId) return;
      final stat = hiddenEyeStats.where((stat) => stat.id == trait).firstOrNull;
      final natural = tiraD20();
      final total = rollTotalWithCritical(natural, 20, [
        stat == null ? 0 : hiddenEyeTotal(stat),
        tiroGlobaleBonus(),
      ]);
      final difficulty = _oculiathCarrierCurrentWill(current);
      final freed = total >= difficulty;
      final label = trait == 'forza' ? 'Forza' : 'Controllo corporeo';
      aggiungiLog(
        '[UNCINO] $label $total contro Volontà $difficulty. '
        '${freed ? 'Ti liberi.' : 'La presa continua.'}',
      );
      if (freed) {
        await releaseOculiathHold(
          current,
          reason: 'Ti liberi dalla presa.',
          safeLanding: natural == 20,
        );
      }
      if (mounted) {
        programmaSalvataggio();
        updateOculumHomeUi(() {});
        if (origin == currentSheetScrollId()) {
          await flushPendingCombatTurnResources();
        }
      }
    } finally {
      inFlight.remove(holdId);
    }
  }
}
