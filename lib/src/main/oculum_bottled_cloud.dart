part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

bool oculumBottledCloudArt(CharacterArt art) =>
    art.openDescriptionEffects.any((e) => e.target == 'bottled_cloud_open');

/// Fresh catalogue instances only: never rewrite a saved or customized Art.
CharacterArt oculumConfigureBottledCloudArt(CharacterArt art) {
  art.monsterOpenSkill = true;
  art.openName = 'Richiamo della tempesta';
  art.openDescription =
      'Costo: 6 Oculum. Una folgore colpisce i ricevitori: Danni attuali + '
      '2d50+25 Danni Fulmine, su massimo 12 avversari con un unico tiro. '
      '+15% Danni per ogni bersaglio dopo il primo; ciascuno si difende. '
      'Il Buff si attiva insieme alla Open e segue il suo recupero.';
  art.openBuff =
      'Una Reazione veloce aggiuntiva a ogni nuovo turno personale. '
      'La propria Open potenzia Fulmine ferma-azione: 60% di interrompere '
      'un’Azione e metà dei Danni attuali. Il potenziamento della Open Skill '
      'segue il proprio ciclo di tre fight oppure due Riposi Brevi e un Lungo.';
  art.openSkill =
      'Fulmine ferma-azione. Costo: 2 Oculum. Cooldown: 3 turni personali. '
      'Sempre utilizzabile, anche con un’altra Open: 20% di interrompere '
      'un’Azione e un quarto dei Danni attuali; con il potenziamento della '
      'propria Open: 60% e metà Danni. La probabilità non cambia i Danni '
      'del fulmine. Se non c’è un’Azione in corso, consuma la prossima '
      'Azione disponibile; Reazioni e Reazioni veloci restano disponibili.';
  art.openDescriptionEffects = [
    OculumStructuredEffect(
      id: 'monster_open_ultimate_bottled_cloud',
      type: 'planar',
      target: 'bottled_cloud_open',
      recipient: 'nemico',
      valueExpression: 'danni+25',
      diceExpression: '2d50',
      elementType: 'fulmine',
      minimumTargets: 1,
      maximumTargets: 12,
      resource: '15',
      customDisplayText:
          'Danni + dadi; risorsa = aumento % dal secondo bersaglio',
    ),
  ];
  art.openBuffEffects = [
    OculumStructuredEffect(
      id: 'bottled_cloud_fast_reaction',
      type: 'modifica_statistica',
      target: 'bottled_cloud_fast_reaction',
      valueExpression: '1',
      mode: 'finche_attivo',
      customDisplayText: 'Reazioni veloci aggiuntive per turno personale',
    ),
  ];
  art.openSkillEffects = [oculumBottledCloudStopEffect()];
  art.openDescriptionCooldown = null;
  art.openBuffCooldown = null;
  art.openSkillCooldown = OculumAbilityCooldown(amount: 3);
  return art;
}

OculumStructuredEffect oculumBottledCloudStopEffect({
  String? id,
}) => OculumStructuredEffect(
  id: id ?? 'bottled_cloud_stop',
  type: 'planar',
  target: 'bottled_cloud_stop',
  recipient: 'nemico',
  valueExpression: '25',
  resource: '20',
  duration: '1',
  elementType: 'fulmine',
  minimumTargets: 1,
  maximumTargets: 1,
  narrativeText: jsonEncode({
    'empoweredDamagePercent': 50,
    'empoweredChancePercent': 60,
  }),
  customDisplayText:
      'Valore = Danni %; risorsa = probabilità %; durata = Azioni interrotte. '
      'Il testo narrativo conserva le percentuali potenziate modificabili.',
);

Map<String, dynamic> oculumBottledCloudEffectData(dynamic raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  try {
    final value = jsonDecode('$raw');
    return value is Map ? Map<String, dynamic>.from(value) : {};
  } on FormatException {
    return {};
  }
}

({int phase, int hp, int healed, bool bottleBroken})
oculumBottledCloudPhaseTransition({
  required int phase,
  required int hpAfter,
  required int maximumHp,
  required int hpLost,
  required bool bottleCritical,
  int thresholdPercent = 15,
  int thresholdHealPercent = 75,
  int bottleHealPercent = 40,
}) {
  final unchanged = (phase: phase, hp: hpAfter, healed: 0, bottleBroken: false);
  // Phase changes do not resurrect a lethal hit or respond to shield-only hits.
  if (phase >= 2 || hpAfter <= 0 || hpLost <= 0 || maximumHp <= 0) {
    return unchanged;
  }
  if (!bottleCritical &&
      hpAfter * 100 > maximumHp * thresholdPercent.clamp(0, 100)) {
    return unchanged;
  }
  final percent = (bottleCritical ? bottleHealPercent : thresholdHealPercent)
      .clamp(0, 100);
  final hp = min(maximumHp, hpAfter + maximumHp * percent ~/ 100);
  return (
    phase: 2,
    hp: hp,
    healed: max(0, hp - hpAfter),
    bottleBroken: bottleCritical,
  );
}

/// The original attack carries the already rolled chance. Replays do not reroll.
Map<String, dynamic>? oculumBottledCloudStopData(Map request) {
  final effect = (request['effects'] as List? ?? const [])
      .whereType<Map>()
      .where((e) => e['target'] == 'bottled_cloud_stop')
      .firstOrNull;
  if (effect == null) return null;
  final data = oculumBottledCloudEffectData(effect['narrativeText']);
  final roll = readIntValue(data['stopRoll'], fallback: -1);
  if (data['bottledCloudPrepared'] != true || roll < 0 || roll >= 100) {
    return null;
  }
  return {
    ...data,
    'succeeded': roll < readIntValue(data['chancePercent']).clamp(0, 100),
    'actions': readIntValue(effect['duration'], fallback: 1).clamp(1, 10),
  };
}

/// Token receipts are part of the existing campaign initiative snapshot.
/// The function touches no reaction pool and never advances the turn.
bool oculumApplyBottledCloudActionLoss(
  Map<String, dynamic> token, {
  required String receiptId,
  required bool ownTurn,
  bool interruptedAction = false,
  int actions = 1,
}) {
  if (receiptId.isEmpty) return false;
  final receipts = (token['bottledCloudActionReceipts'] as List? ?? const [])
      .map((e) => '$e')
      .toSet();
  if (!receipts.add(receiptId)) return false;
  token['bottledCloudActionReceipts'] = receipts.toList();
  var remaining = actions.clamp(1, 10);
  if (interruptedAction) {
    // A reordered original attack may not have mirrored its spend yet.
    // Preserve that already-paid action, without charging the next one.
    token['actionUsed'] = true;
    remaining--;
  }
  if (remaining > 0 && ownTurn && token['meccanioReactionsOnly'] != true) {
    if (!readBoolValue(token['actionUsed'])) {
      token['actionUsed'] = true;
      remaining--;
    }
    final extra = max(0, readIntValue(token['kiExtraActions']));
    final spent = min(extra, remaining);
    token['kiExtraActions'] = extra - spent;
    remaining -= spent;
  }
  token['bottledCloudPendingActions'] =
      max(0, readIntValue(token['bottledCloudPendingActions'])) + remaining;
  return true;
}

int oculumConsumeBottledCloudPendingActions(Map<String, dynamic> token) {
  var pending = max(0, readIntValue(token['bottledCloudPendingActions']));
  if (pending <= 0 || token['meccanioReactionsOnly'] == true) return 0;
  final before = pending;
  if (!readBoolValue(token['actionUsed'])) {
    token['actionUsed'] = true;
    pending--;
  }
  final extra = max(0, readIntValue(token['kiExtraActions']));
  final spent = min(extra, pending);
  token['kiExtraActions'] = extra - spent;
  pending -= spent;
  token['bottledCloudPendingActions'] = pending;
  return before - pending;
}

extension _OculumBottledCloud on _OculumHomePageState {
  String get bottledCloudFightKey {
    final group = masterInitiativeGroups
        .where((g) => g['id'] == selectedMasterInitiativeGroupId)
        .firstOrNull;
    final instance =
        realtimeService?.isConnected == true && !realtimeIsMasterRole
        ? realtimeVisibleInitiativeSnapshot['completedFightCount']
        : group?['completedFightCount'];
    return '$permissionScope:$permissionCampaignId:$onlineCombatEncounterId:${readIntValue(instance)}';
  }

  int get bottledCloudFastReactionBonus => arti
      .where(
        (a) =>
            a.sbloccata &&
            a.inUso &&
            oculumBottledCloudArt(a) &&
            artOpenBuffActive(a),
      )
      .expand((a) => a.openBuffEffects)
      .where((e) => e.enabled && e.target == 'bottled_cloud_fast_reaction')
      .fold<int>(
        0,
        (n, e) =>
            n +
            max(
              0,
              oculumEvaluateStructuredEffectValue(
                e,
                variables: formulaValueContext(),
                subtraits: hiddenEyeStats,
              ),
            ),
      );

  int get bottledCloudPhaseNumber {
    final state = planarState['bottledCloud'];
    return state is Map && state['fight'] == bottledCloudFightKey
        ? readIntValue(state['phase'], fallback: 1)
        : 1;
  }

  void refreshBottledCloudTokenFight(Map<String, dynamic> token) {
    final key = bottledCloudFightKey;
    if (token['bottledCloudActionEncounter'] == key) return;
    token['bottledCloudActionEncounter'] = key;
    token['bottledCloudPendingActions'] = 0;
    token['bottledCloudActionReceipts'] = <String>[];
    token['bottledCloudInterruptedGroups'] = <String>[];
    token.remove('bottledCloudFastReactionTurn');
  }

  Future<void> useBottledCloudOpen(CharacterArt art, int index) async {
    if (!arti.contains(art) || !art.inUso || !artOpenSbloccata(art)) return;
    if (art.openAttiva) {
      deactivateArtOpenBuffCycle(art);
      art.openAttiva = false;
      invalidateDerivedDataCaches();
      programmaSalvataggio();
      scheduleRealtimeOculumChanged();
      if (mounted) setState(() {});
      return;
    }
    if (!canStartArtOpenCycle(art)) return;
    final origin = currentSheetScrollId();
    final encounter = onlineCombatEncounterId;
    ensureArtIntegrityValue(index);
    final integrityCost =
        !art.hasIntegrity || oculumRecognizedArtKind(art) == 'emblem'
        ? 0
        : artUseCost(oculumArtActivationCost);
    if (art.hasIntegrity &&
        !oculumArtCanActivate(art.integritaCorrente, cost: integrityCost)) {
      return;
    }
    final parsed = oculumParseAbilityCost(art.openDescription);
    final used = await useConfiguredAbility(
      source: artOpenDisplayName(art, index),
      effects: [...art.openDescriptionEffects, ...art.openBuffEffects],
      cost: OculumSkillCost(
        resource: parsed?.resource ?? 'oculum',
        amountExpression: '${parsed?.minimum ?? 6}',
        minimum: parsed?.minimum ?? 6,
        maximum: parsed?.maximum ?? 6,
        variable: parsed != null && parsed.minimum != parsed.maximum,
      ),
      cooldown: art.openDescriptionCooldown,
      valid: () =>
          currentSheetScrollId() == origin &&
          onlineCombatEncounterId == encounter &&
          arti.contains(art) &&
          art.sbloccata &&
          art.inUso &&
          !art.openAttiva &&
          artOpenSbloccata(art) &&
          canStartArtOpenCycle(art),
      onPaid: (_) {
        recordArtOpenCycleActivation(art);
        if (art.hasIntegrity) {
          consumeArtIntegrityAndResolveDebuff(
            index,
            integrityCost,
            skillLevel: 3,
          );
        }
        disattivaTutteLeOpen(exceptArt: art);
        art.openAttiva = true;
        art.openUsedSinceLongRest = true;
      },
    );
    if (!used || !mounted || currentSheetScrollId() != origin) return;
    tagOpenLifecycleBuffEffects(
      artOpenLifecycle(art).id,
      artOpenDisplayName(art, index),
    );
    invalidateDerivedDataCaches();
    notifyArtIntegrityChanged(index);
    scheduleArtIntegritySave(<int>[index], immediate: true);
    programmaSalvataggio();
    await finishParsedAbilityTargets(art.openDescription);
  }

  List<OculumStructuredEffect> prepareBottledCloudEffects(
    List<OculumStructuredEffect> effects, {
    Random? random,
  }) {
    if (!effects.any(
      (e) =>
          const {'bottled_cloud_stop', 'bottled_cloud_open'}.contains(e.target),
    )) {
      return effects;
    }
    final ownBoost = arti.any(
      (art) =>
          art.sbloccata &&
          art.inUso &&
          oculumBottledCloudArt(art) &&
          artOwnOpenSkillEmpowered(art),
    );
    return [
      for (final original in effects)
        if (!const {
          'bottled_cloud_stop',
          'bottled_cloud_open',
        }.contains(original.target))
          original
        else
          (() {
            final legacyStop =
                original.target == 'bottled_cloud_stop' &&
                RegExp(
                  r'^bottled_cloud_stop_forma_[123]_0$',
                ).hasMatch(original.id) &&
                original.recipient == 'se_stesso' &&
                original.resource.isEmpty &&
                original.valueExpression == '1' &&
                original.narrativeText.startsWith('20% di fermare un’Azione,');
            final effect = legacyStop
                ? (oculumBottledCloudStopEffect(id: original.id)
                    ..enabled = original.enabled)
                : OculumStructuredEffect.fromJson(original.toJson());
            final data = oculumBottledCloudEffectData(effect.narrativeText);
            if (data['bottledCloudPrepared'] == true) return effect;
            if (effect.target == 'bottled_cloud_open') {
              final roll = oculumResolveStructuredEffectRoll(
                effect,
                variables: {...formulaValueContext(), 'danni': dannoTotale()},
                subtraits: hiddenEyeStats,
                random: random,
              );
              effect.valueExpression = '${max(0, roll.value)}';
              effect.narrativeText = jsonEncode({
                ...data,
                'bottledCloudPrepared': true,
                'perExtraTargetPercent': readIntValue(
                  effect.resource,
                  fallback: 15,
                ),
              });
            } else {
              final boundBoost = data['ownOpenEmpowered'] is bool
                  ? data['ownOpenEmpowered'] == true
                  : ownBoost;
              final chance = boundBoost
                  ? readIntValue(data['empoweredChancePercent'], fallback: 60)
                  : oculumEvaluateFormula(
                      effect.resource,
                      formulaValueContext(),
                    ).floor();
              final percent = boundBoost
                  ? readIntValue(data['empoweredDamagePercent'], fallback: 50)
                  : oculumEvaluateFormula(
                      effect.valueExpression,
                      formulaValueContext(),
                    ).floor();
              effect.valueExpression =
                  '${max(0, dannoTotale()) * percent.clamp(0, 100) ~/ 100}';
              effect.narrativeText = jsonEncode({
                ...data,
                'bottledCloudPrepared': true,
                'ownOpenEmpowered': boundBoost,
                'chancePercent': chance.clamp(0, 100),
                'damagePercent': percent.clamp(0, 100),
                'stopRoll': (random ?? Random.secure()).nextInt(100),
              });
            }
            effect.diceExpression = '';
            effect.includeLevel = effect.includeGrade = false;
            return effect;
          })(),
    ];
  }

  void claimBottledCloudAttack(Map<String, dynamic> request, int targets) {
    if (request['bottledCloudAttackPrepared'] == true) return;
    final effect = (request['effects'] as List? ?? const [])
        .whereType<Map>()
        .where(
          (e) => const {
            'bottled_cloud_open',
            'bottled_cloud_stop',
          }.contains(e['target']),
        )
        .firstOrNull;
    if (effect == null) return;
    final data = oculumBottledCloudEffectData(effect['narrativeText']);
    if (data['bottledCloudPrepared'] != true) return;
    final damage = max(0, readIntValue(effect['valueExpression']));
    request['damage'] = effect['target'] == 'bottled_cloud_open'
        ? oculumCloudOpenDamage(
            damage,
            targets,
            percentPerExtraTarget: readIntValue(
              data['perExtraTargetPercent'],
              fallback: 15,
            ),
            maximumTargets: readIntValue(
              effect['maximumTargets'],
              fallback: 12,
            ),
          )
        : damage;
    request['baseAttack'] = false;
    request['element'] = effect['elementType'] ?? 'fulmine';
    request['bottledCloudAttackPrepared'] = true;
  }

  void resolveBottledCloudPhase(
    Map<String, dynamic> request, {
    required bool critical,
  }) {
    if (faunaCurrentMonsterId != 'nuvola_in_bottiglia' ||
        request['targetTag'] != sheetTagAt(schedaCorrente) ||
        request['scope'] != permissionScope ||
        request['encounterId'] != onlineCombatEncounterId) {
      return;
    }
    final receipt = request['damageReceipt'];
    if (receipt is! Map ||
        structuralHpLostForRequest(request, readIntValue(receipt['hpLost'])) <=
            0 ||
        structuralDamageReceiptFor(request)?['lethalBeforeRecovery'] == true) {
      return;
    }
    final fight = bottledCloudFightKey;
    final raw = planarState['bottledCloud'];
    final state = raw is Map && raw['fight'] == fight
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{'fight': fight, 'phase': 1};
    final seen = (state['receipts'] as List? ?? const [])
        .map((e) => '$e')
        .toSet();
    if (!seen.add('${request['id']}')) return;
    state['receipts'] = seen.toList();
    final result = oculumBottledCloudPhaseTransition(
      phase: readIntValue(state['phase'], fallback: 1),
      hpAfter: hpCorrenti(),
      maximumHp: maxHp(),
      hpLost: structuralHpLostForRequest(
        request,
        readIntValue(receipt['hpLost']),
      ),
      bottleCritical:
          request['targetBodyPart'] == 'bottle' &&
          critical &&
          !criticalShieldBlocksDebuffs(request),
      thresholdPercent: referenceRule('secondPhaseHpPercent', 15),
      thresholdHealPercent: referenceRule('secondPhaseHealPercent', 75),
      bottleHealPercent: referenceRule('bottleCriticalHealPercent', 40),
    );
    final changed = result.phase > readIntValue(state['phase'], fallback: 1);
    state['phase'] = result.phase;
    if (changed) {
      state['bottleBroken'] = true;
      currentHpController.text = '${result.hp}';
      request['bottledCloudPhaseReceipt'] = {
        'phase': result.phase,
        'healed': result.healed,
        'earlyBottle': result.bottleBroken,
        'hp': result.hp,
      };
      aggiungiLog(
        '[NUVOLA] Seconda fase: +${result.healed} Vita '
        '(${result.bottleBroken ? 'bottiglia infranta' : 'soglia Vita raggiunta'}).',
      );
      invalidateDerivedDataCaches();
    }
    planarState['bottledCloud'] = state;
    if (changed) publishReferenceCreatureAnatomyState();
    programmaSalvataggio();
  }

  void applyBottledCloudStopResult(
    Map<String, dynamic> request, {
    required bool hit,
    Map<String, dynamic>? resolution,
  }) {
    if (!hit ||
        request['scope'] != permissionScope ||
        request['encounterId'] != onlineCombatEncounterId ||
        request['campaignId'] != null &&
            request['campaignId'] != permissionCampaignId) {
      return;
    }
    final data = oculumBottledCloudStopData(request);
    if (data == null || data['succeeded'] != true) return;
    final tag = '${request['targetTag'] ?? ''}';
    final tokens = _writableOnlineCombatTokens();
    final index = tokens.indexWhere((t) => combatTokenMatchesSheet(t, tag));
    if (index < 0 ||
        const {'dead', 'fled', 'expired'}.contains(tokens[index]['status'])) {
      return;
    }
    refreshBottledCloudTokenFight(tokens[index]);
    final active = _usesLocalMasterInitiative
        ? masterInitiativeActiveIndex
        : readIntValue(realtimeVisibleInitiativeSnapshot['activeIndex']);
    final receiptId = '${request['encounterId']}:${request['id']}';
    final receipts =
        tokens[index]['bottledCloudActionReceipts'] as List? ?? const [];
    if (receipts.contains(receiptId)) return;
    final pending = onlineCombatRequests.values
        .where(
          (r) =>
              r['sourceTag'] == tag &&
              r['status'] == 'pending' &&
              r['scope'] == permissionScope &&
              r['encounterId'] == onlineCombatEncounterId &&
              (r['activityResource'] == 'azione' ||
                  (r['turnResourceSpends'] as List? ?? const [])
                      .whereType<Map>()
                      .any(
                        (s) =>
                            s['sheetTag'] == tag &&
                            (s['activityResource'] ?? s['resource']) ==
                                'azione',
                      )),
        )
        .toList();
    String? group =
        resolution?['id'] == receiptId &&
            resolution?['targetTag'] == tag &&
            resolution?['interruptedGroup'] is String
        ? '${resolution!['interruptedGroup']}'
        : null;
    if (group == null && resolution == null && pending.isNotEmpty) {
      final action = pending.last;
      group = '${action['attackGroupId'] ?? action['id']}';
    }
    if (group != null && group.isNotEmpty) {
      final groups =
          (tokens[index]['bottledCloudInterruptedGroups'] as List? ?? const [])
              .map((e) => '$e')
              .toSet()
            ..add(group);
      tokens[index]['bottledCloudInterruptedGroups'] = groups.toList();
      for (final candidate in pending.where(
        (r) => '${r['attackGroupId'] ?? r['id']}' == group,
      )) {
        candidate['status'] = 'cancelled';
        candidate['bottledCloudInterruptedBy'] = request['id'];
      }
    }
    if (!oculumApplyBottledCloudActionLoss(
      tokens[index],
      receiptId: receiptId,
      ownTurn: index == active,
      interruptedAction: group != null,
      actions: readIntValue(data['actions'], fallback: 1),
    )) {
      return;
    }
    request['bottledCloudStopReceipt'] = {
      'id': receiptId,
      'targetTag': tag,
      'interruptedGroup': group,
      'pendingActions': tokens[index]['bottledCloudPendingActions'],
    };
    combatLogFor(
      tag,
      '[FULMINE] Azione ${group == null ? 'consumata o bloccata alla prossima disponibilità' : 'interrotta'}; Reazioni conservate.',
    );
    if (_usesLocalMasterInitiative) {
      captureActiveMasterInitiativeGroup();
      sendRealtimeInitiativeSnapshotIfPublished();
    }
    programmaSalvataggio();
  }

  bool bottledCloudAttackInterrupted(Map<String, dynamic> request) {
    if (request['scope'] != permissionScope ||
        request['encounterId'] != onlineCombatEncounterId) {
      return false;
    }
    final token = onlineCombatTokens()
        .where((t) => combatTokenMatchesSheet(t, '${request['sourceTag']}'))
        .firstOrNull;
    final groups = token?['bottledCloudInterruptedGroups'] as List? ?? const [];
    if (!groups.contains('${request['attackGroupId'] ?? request['id']}')) {
      return false;
    }
    request['status'] = 'cancelled';
    return true;
  }

  void bottledCloudPersonalTurn(Map<String, dynamic> token, String stamp) {
    if (token['bottledCloudFastReactionTurn'] == stamp) return;
    var bonus = readIntValue(
      (token['faunaPublic'] as Map?)?['bottledCloudFastReactions'],
    );
    faunaForOwnedSheet(publicInitiativeSourceTag(token), () {
      bonus = bottledCloudFastReactionBonus;
    });
    token['bottledCloudFastReactionTurn'] = stamp;
    token['extraFastReactionCurrent'] =
        readIntValue(token['extraFastReactionCurrent']) + bonus;
    if (bonus > 0) {
      aggiungiLog(
        '[NUVOLA] +$bonus Reazione veloce per questo turno personale.',
      );
    }
  }
}
