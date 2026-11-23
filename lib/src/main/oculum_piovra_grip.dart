part of '../../main.dart';

const oculumPiovraGripEffect = 'piovra_presa_succhiasangue';
const oculumPiovraGripDrain = 'piovra_presa_recupero';
const _piovraGripKey = 'piovraGrip';
const _piovraGripCondition = 'piovraGripCondition';
const _piovraTickKey = 'piovraGripTick';
final _piovraGripDrain = Expando<bool>();
final _piovraRemoteSync = Expando<bool>();
final _piovraRemoteDamage = Expando<Future<void>>();

int oculumPiovraGripModifier(
  int level,
  int strength,
  int reflexes,
  int precision,
) {
  final bonus = level >= 6
      ? 15
      : level >= 3
      ? 10
      : 5;
  return bonus + max(strength, max(reflexes, precision));
}

bool oculumPiovraWinsGripContest(int attacker, int defender) =>
    attacker > defender;

int oculumPiovraGripHealing(int hpLost, {int percent = 50}) =>
    max(0, hpLost) * percent.clamp(0, 100) ~/ 100;

extension _OculumPiovraGrip on _OculumHomePageState {
  bool get _piovraGripAuthority =>
      escapeAuthority &&
      _usesLocalMasterInitiative &&
      encounterFightStarted(onlineCombatEncounterId);

  bool _piovraTokenActive(Map<String, dynamic> token) =>
      masterInitiativeTokenCanAct(token) &&
      token['outsideFight'] != true &&
      !masterInitiativeTokenIsTemporary(token);

  Map? _piovraRecord(Map<String, dynamic> holder) {
    final grip = holder[_piovraGripKey];
    if (grip is! Map ||
        grip['encounter'] != onlineCombatEncounterId ||
        grip['scope'] != permissionScope ||
        grip['campaign'] != permissionCampaignId ||
        grip['sourceFight'] != holder['fightInstanceId'] ||
        !_piovraTokenActive(holder)) {
      return null;
    }
    final target = escapeToken('${grip['target']}');
    if (target == null ||
        !_piovraTokenActive(target) ||
        grip['targetFight'] != target['fightInstanceId']) {
      return null;
    }
    return grip;
  }

  Map? _piovraGrip(Map<String, dynamic> holder) {
    final record = _piovraRecord(holder);
    return record?['awaitingReflex'] == true ? null : record;
  }

  Map<String, dynamic>? _piovraHolder(String target) => masterInitiativeTokens
      .where(
        (token) =>
            oculumSameSheetIdentity(_piovraGrip(token)?['target'], target),
      )
      .firstOrNull;

  int _piovraSubtrait(String id) {
    final stat = hiddenEyeStats.where((trait) => trait.id == id).firstOrNull;
    return stat == null ? 0 : hiddenEyeTotal(stat);
  }

  int _piovraOpposedRoll(String tag, int Function() bonus) {
    var total = 0;
    faunaForOwnedSheet(tag, () {
      total = tiraD20(countsAsCooldownRoll: false) + bonus();
    });
    return total;
  }

  int _rollPiovraGrip(String holder) => _piovraOpposedRoll(
    holder,
    () => oculumPiovraGripModifier(
      leggiNumero(livelloController),
      _piovraSubtrait('forza'),
      _piovraSubtrait('riflessi'),
      _piovraSubtrait('precisione'),
    ),
  );

  bool _piovraCanDeclare(String source) =>
      _piovraGripAuthority &&
      source == sheetTagAt(schedaCorrente) &&
      controlsOnlineCombatSheet(source) &&
      !planarCharging &&
      !hasCondition('paralisi_fato') &&
      !elementalSphereFrozen &&
      !elementalSphereSoulSeparated &&
      !stat20OculumChargeActive;

  Iterable<Map<String, dynamic>> _piovraTargets(Map<String, dynamic> holder) {
    final team = combatParticipantTeamId(holder);
    return masterInitiativeTokens.where((token) {
      final tag = onlineCombatTokenTag(token);
      return _piovraTokenActive(token) &&
          _attackTokenIsOpponent(token, team) &&
          (controlsOnlineCombatSheet(tag) ||
              realtimeService?.isConnected == true &&
                  (realtimeIsMasterRole || realtimeIsCoMasterRole) &&
                  realtimeUsers.any((user) {
                    final tags = user['localSheetTags'];
                    return tags is List &&
                            tags.any(
                              (owned) => oculumSameSheetIdentity(owned, tag),
                            ) ||
                        oculumSameSheetIdentity(user['activeSheetTag'], tag);
                  })) &&
          !masterInitiativeTokens.any(
            (source) =>
                oculumSameSheetIdentity(_piovraRecord(source)?['target'], tag),
          );
    });
  }

  Future<bool> selectPiovraGrip({
    required String label,
    required OculumStructuredEffect effect,
    OculumStructuredEffect? drainEffect,
    OculumSkillCost? cost,
    OculumAbilityCooldown? cooldown,
    bool Function()? valid,
  }) async {
    final source = sheetTagAt(schedaCorrente);
    if (!_piovraCanDeclare(source) || cooldown?.ready == false) return false;
    final holder = escapeToken(source);
    if (holder == null ||
        !_piovraTokenActive(holder) ||
        _piovraRecord(holder) != null) {
      return false;
    }
    final encounter = onlineCombatEncounterId;
    final campaign = permissionCampaignId;
    final scope = permissionScope;
    final round = masterInitiativeRound;
    final candidates = _piovraTargets(holder).toList();
    if (candidates.isEmpty) {
      aggiungiLog('[PIOVRA] Nessun bersaglio disponibile per la presa.');
      return false;
    }
    final target = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text(label),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              t(
                'Scegli una preda a portata delle braccia.',
                'Choose a target within reach of the arms.',
              ),
            ),
          ),
          for (final token in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, token),
              child: Text(oculumReferenceEncounterTokenName(token)),
            ),
        ],
      ),
    );
    if (target == null || !mounted) return false;
    final tag = onlineCombatTokenTag(target);
    bool currentSelection() =>
        mounted &&
        _piovraCanDeclare(source) &&
        (valid == null || valid()) &&
        cooldown?.ready != false &&
        encounter == onlineCombatEncounterId &&
        campaign == permissionCampaignId &&
        scope == permissionScope &&
        round == masterInitiativeRound &&
        identical(escapeToken(source), holder) &&
        identical(escapeToken(tag), target) &&
        _piovraTokenActive(holder) &&
        _piovraRecord(holder) == null &&
        _piovraTargets(holder).contains(target);

    bool settle(Map<String, int> payments) {
      if (!currentSelection() ||
          !_consumeLocalCombatTurnResource(
            source,
            'azione',
            advanceMasterTurn: false,
            payForAction: () => spendArtSkillPayments(payments),
          )) {
        return false;
      }
      cooldown?.activate();
      final grip = _rollPiovraGrip(source);
      final id = 'piovra:$source:$tag:${DateTime.now().microsecondsSinceEpoch}';
      final record = <String, dynamic>{
        'id': id,
        'target': tag,
        'encounter': encounter,
        'campaign': campaign,
        'scope': scope,
        'sourceFight': holder['fightInstanceId'],
        'targetFight': target['fightInstanceId'],
        'effect': effect.toJson(),
        if (drainEffect != null) 'drainEffect': drainEffect.toJson(),
      };
      if (!controlsOnlineCombatSheet(tag)) {
        holder[_piovraGripKey] = {
          ...record,
          'awaitingReflex': true,
          'gripRoll': grip,
        };
        _publishPiovraGrip();
        return true;
      }
      final reflexes = _piovraOpposedRoll(
        tag,
        () => _piovraSubtrait('riflessi'),
      );
      var applied = false;
      if (oculumPiovraWinsGripContest(grip, reflexes)) {
        faunaForOwnedSheet(tag, () {
          applied = _applyPiovraGripCondition(record);
        });
        if (applied) holder[_piovraGripKey] = record;
      }
      final outcome = applied ? 'Preda afferrata.' : 'Presa respinta.';
      aggiungiLog('[PIOVRA] Presa $grip contro Riflessi $reflexes. $outcome');
      _publishPiovraGrip();
      advanceMasterInitiativeAfterAction(source);
      return true;
    }

    if (cost == null ||
        (oculumNormalizeEffectResource(cost.resource) == 'nessuna' &&
            cost.additionalCosts.isEmpty)) {
      return settle(const {});
    }
    return useConfiguredAbility(
      source: label,
      effects: const [],
      cost: cost,
      cooldown: cooldown,
      valid: currentSelection,
      paymentOnly: true,
      commitPayment: settle,
    );
  }

  bool _applyPiovraGripCondition(Map record) => applyCondition(
    'afferrato',
    durationType: OculumConditionDurationType.permanent,
    removable: false,
    source: 'Presa succhiasangue',
    metadata: {
      'referenceCurseSource': record['id'],
      _piovraGripCondition: true,
      'encounter': record['encounter'],
      'campaign': record['campaign'],
    },
  );

  Map<String, dynamic>? publicPiovraGrip(Map<String, dynamic> holder) {
    final record = _piovraRecord(holder);
    if (record == null) return null;
    return {
      for (final key in [
        'id',
        'target',
        'encounter',
        'campaign',
        'scope',
        'sourceFight',
        'targetFight',
      ])
        key: record[key],
      'awaitingReflex': record['awaitingReflex'] == true,
    };
  }

  List<Map<String, dynamic>> get _remotePiovraEncounters =>
      realtimeEncounterSnapshots.isEmpty
      ? [realtimeVisibleInitiativeSnapshot]
      : realtimeEncounterSnapshots;

  (Map<String, dynamic>, Map)? _remotePiovraGrip(String tag) {
    if (realtimeService?.isConnected != true ||
        !controlsOnlineCombatSheet(tag)) {
      return null;
    }
    for (final encounter in _remotePiovraEncounters) {
      if (encounter['fightStarted'] != true ||
          encounter['combatEnded'] == true) {
        continue;
      }
      final tokens = (encounter['tokens'] as List? ?? const [])
          .whereType<Map>()
          .map((token) => Map<String, dynamic>.from(token))
          .toList();
      final target = tokens
          .where(
            (token) =>
                oculumSameSheetIdentity(onlineCombatTokenTag(token), tag),
          )
          .firstOrNull;
      if (target == null || !_piovraTokenActive(target)) continue;
      for (final holder in tokens) {
        final record = holder[_piovraGripKey];
        if (record is Map &&
            oculumSameSheetIdentity(record['target'], tag) &&
            record['encounter'] == encounter['encounterId'] &&
            record['campaign'] == permissionCampaignId &&
            record['scope'] == permissionScope &&
            record['sourceFight'] == holder['fightInstanceId'] &&
            record['targetFight'] == target['fightInstanceId'] &&
            _piovraTokenActive(holder)) {
          return (target, record);
        }
      }
    }
    return null;
  }

  Future<void> _replyPiovra(
    Map record,
    String stage,
    Map<String, dynamic> data,
  ) async {
    final target = '${record['target']}';
    await realtimeService?.sendCombatEvent('combat_scout', {
      ...permissionEnvelope({
        'id': '${record['id']}:$stage:${data['tick'] ?? data['round'] ?? ''}',
        'encounterId': record['encounter'],
        'piovraGripReply': stage,
        'gripId': record['id'],
        'targetTag': target,
        'targetFight': record['targetFight'],
        'sourceFight': record['sourceFight'],
        ...data,
      }),
      'senderTag': target,
    });
  }

  void receivePiovraGripReply(Map<String, dynamic> payload) {
    if (!_piovraGripAuthority ||
        !realtimeIsMasterRole ||
        !validPermissionSender(payload) ||
        payload['encounterId'] != onlineCombatEncounterId ||
        !oculumSameSheetIdentity(payload['senderTag'], payload['targetTag'])) {
      return;
    }
    final tag = '${payload['targetTag'] ?? ''}';
    if (controlsOnlineCombatSheet(tag)) return;
    final stage = payload['piovraGripReply'];
    final target = escapeToken(tag);
    if (target == null || stage != 'tick' && !_piovraTokenActive(target)) {
      return;
    }
    final holder = masterInitiativeTokens.where((token) {
      final grip = token[_piovraGripKey];
      return grip is Map &&
          grip['id'] == payload['gripId'] &&
          grip['encounter'] == onlineCombatEncounterId &&
          grip['campaign'] == permissionCampaignId &&
          grip['scope'] == permissionScope &&
          grip['sourceFight'] == token['fightInstanceId'] &&
          grip['sourceFight'] == payload['sourceFight'] &&
          grip['targetFight'] == target['fightInstanceId'] &&
          grip['targetFight'] == payload['targetFight'] &&
          _piovraTokenActive(token) &&
          oculumSameSheetIdentity(grip['target'], tag);
    }).firstOrNull;
    if (holder == null) return;
    final record = holder[_piovraGripKey] as Map;
    final roll = payload['roll'];
    if (record['awaitingReflex'] == true) {
      if (stage != 'reflex' || roll is! int || roll.abs() > 1000000) return;
      if (oculumPiovraWinsGripContest(readIntValue(record['gripRoll']), roll)) {
        record.remove('awaitingReflex');
        record.remove('gripRoll');
        if (masterInitiativeActiveIndex >= 0 &&
            masterInitiativeActiveIndex < masterInitiativeTokens.length &&
            identical(
              masterInitiativeTokens[masterInitiativeActiveIndex],
              target,
            )) {
          startPiovraGripTurn(target, masterInitiativeRound);
        }
        aggiungiLog('[PIOVRA] Preda afferrata.');
      } else {
        _releasePiovraGrip(holder);
        aggiungiLog('[PIOVRA] Presa respinta.');
      }
      advanceMasterInitiativeAfterAction(onlineCombatTokenTag(holder));
    } else if (stage == 'tick') {
      final pending = target[_piovraTickKey];
      final tick = pending is Map ? pending[payload['tick']] : null;
      final lost = payload['hpLost'];
      if (tick is! Map ||
          tick['grip'] != record['id'] ||
          lost is! int ||
          lost < 0 ||
          lost > 100000000 ||
          !_removePiovraTick(target, tick)) {
        return;
      }
      _healPiovraGrip(onlineCombatTokenTag(holder), tick, lost);
    } else if (stage == 'inapplicable') {
      _releasePiovraGrip(holder);
    } else if (stage == 'escape') {
      if (roll is! int ||
          roll.abs() > 1000000 ||
          payload['round'] != masterInitiativeRound ||
          record['lastEscapeRound'] == masterInitiativeRound ||
          !_consumeLocalCombatTurnResource(
            tag,
            'azione',
            advanceMasterTurn: false,
          )) {
        return;
      }
      record['lastEscapeRound'] = masterInitiativeRound;
      final maintain = _rollPiovraGrip(onlineCombatTokenTag(holder));
      final freed = oculumPiovraWinsGripContest(roll, maintain);
      if (freed) _releasePiovraGrip(holder);
      final outcome = freed ? 'Preda liberata.' : 'La presa continua.';
      aggiungiLog(
        '[PIOVRA] Liberazione $roll contro Presa $maintain. $outcome',
      );
      advanceMasterInitiativeAfterAction(tag);
    } else {
      return;
    }
    _publishPiovraGrip();
  }

  void syncRemotePiovraGrip() {
    if (!mounted ||
        realtimeService?.isConnected != true ||
        realtimeIsMasterRole ||
        _piovraRemoteSync[this] == true) {
      return;
    }
    final service = realtimeService;
    final scope = permissionScope;
    final campaign = permissionCampaignId;
    final revision = realtimeInitiativeRevision;
    final sequence = realtimeInitiativeServerSequence;
    final host = realtimeInitiativeSession;
    final knownEncounters = _remotePiovraEncounters
        .map((encounter) => encounter['encounterId'])
        .toSet();
    bool sameRoom() =>
        mounted &&
        identical(realtimeService, service) &&
        service?.isConnected == true &&
        permissionScope == scope &&
        permissionCampaignId == campaign;

    _piovraRemoteSync[this] = true;
    unawaited(() async {
      try {
        for (final tag in ownPermissionTags) {
          if (!sameRoom()) return;
          final remote = _remotePiovraGrip(tag);
          final record = remote?.$2;
          final index = localSheetIndexForOculumTag(tag);
          if (index < 0 || !controlsOnlineCombatSheet(tag)) continue;
          final currentId = record != null && record['awaitingReflex'] == false
              ? record['id']
              : null;

          final sheet = schedePersonaggio[index];
          bool expired(Map metadata) =>
              metadata[_piovraGripCondition] == true &&
              metadata['campaign'] == campaign &&
              knownEncounters.contains(metadata['encounter']) &&
              metadata['referenceCurseSource'] != currentId;
          final conditions = index == schedaCorrente
              ? activeConditions.map((item) => item.metadata)
              : ((sheet['conditions'] ?? sheet['activeConditions']) as List? ??
                        const [])
                    .whereType<Map>()
                    .map((item) => item['metadata'])
                    .whereType<Map>();
          final hasExpired = conditions.any(expired);
          final hasGrip =
              currentId != null &&
              conditions.any(
                (metadata) =>
                    metadata[_piovraGripCondition] == true &&
                    metadata['referenceCurseSource'] == currentId,
              );
          if (record == null && !hasExpired) continue;

          String? reply;
          int? roll;
          if (hasExpired || !hasGrip) {
            faunaForOwnedSheet(tag, () {
              for (final condition
                  in activeConditions
                      .where((item) => expired(item.metadata))
                      .toList()) {
                removeCondition(condition, force: true, expired: true);
              }
              if (record == null) return;
              final id = '${record['id']}';
              if (record['awaitingReflex'] == true) {
                final saved = _piovraRemoteReceipt(id);
                roll =
                    saved ??
                    tiraD20(countsAsCooldownRoll: false) +
                        _piovraSubtrait('riflessi');
                if (saved == null) _savePiovraRemoteReceipt(id, roll!);
                reply = 'reflex';
              } else if (!activeConditions.any(
                    (item) =>
                        item.metadata[_piovraGripCondition] == true &&
                        item.metadata['referenceCurseSource'] == id,
                  ) &&
                  !_applyPiovraGripCondition(record)) {
                reply = 'inapplicable';
              }
            });
          }

          if (remote == null || record == null || !sameRoom()) continue;
          if (reply != null) {
            await _replyPiovra(record, reply!, {'roll': ?roll});
            continue;
          }
          final pending = remote.$1[_piovraTickKey];
          if (pending is! Map) continue;
          for (final tick in pending.values.whereType<Map>()) {
            if (!sameRoom() ||
                _remotePiovraGrip(tag)?.$2['id'] != record['id']) {
              break;
            }
            if (tick['grip'] != record['id']) continue;
            final tickId = '${tick['id'] ?? ''}';
            if (tickId.isEmpty) continue;
            final saved = index == schedaCorrente
                ? _piovraRemoteReceipt(tickId)
                : ((schedePersonaggio[index]['planarRuntime']
                              as Map?)?['piovraRemoteReceipts']
                          as Map?)?[tickId]
                      as int?;
            if (saved == null && pawnPendingDamage.isNotEmpty) break;
            final hpLost = saved ?? await _applyRemotePiovraTick(tag, tick);
            if (!sameRoom()) return;
            if (hpLost == null) break;
            await _replyPiovra(record, 'tick', {
              'tick': tickId,
              'hpLost': hpLost,
            });
          }
        }
      } finally {
        _piovraRemoteSync[this] = null;
        if (sameRoom() &&
            (realtimeInitiativeRevision != revision ||
                realtimeInitiativeServerSequence != sequence ||
                realtimeInitiativeSession != host)) {
          syncRemotePiovraGrip();
        }
      }
    }());
  }

  int? _piovraRemoteReceipt(String id) =>
      (planarState['piovraRemoteReceipts'] as Map?)?[id] as int?;

  void _savePiovraRemoteReceipt(String id, int value) {
    final receipts = Map<String, dynamic>.from(
      planarState['piovraRemoteReceipts'] as Map? ?? const {},
    );
    while (receipts.length >= 100 && !receipts.containsKey(id)) {
      receipts.remove(receipts.keys.first);
    }
    receipts[id] = value;
    planarState['piovraRemoteReceipts'] = receipts;
    salvaSchedaCorrenteInMemoria();
    programmaSalvataggio();
  }

  Future<int?> _applyRemotePiovraTick(String tag, Map tick) async {
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0 || !controlsOnlineCombatSheet(tag)) return null;
    final original = sheetTagAt(schedaCorrente);
    final campaign = activeCampaignId;
    final savedGlobal = catturaImpostazioniGlobali();
    // The damage engine works on sheet controllers and can await Pawn.
    // Keep the target context until impact, then restore the selected sheet.
    final damage = Completer<void>();
    _piovraRemoteDamage[this] = damage.future;
    bool onTarget() =>
        mounted &&
        activeCampaignId == campaign &&
        oculumSameSheetIdentity(sheetTagAt(schedaCorrente), tag);

    try {
      if (index != schedaCorrente) {
        salvaSchedaCorrenteInMemoria();
        schedaCorrente = index;
        caricaStatoDaJson(schedePersonaggio[index]);
        ripristinaImpostazioniGlobali(savedGlobal);
      }
      if (pawnPendingDamage.isNotEmpty) return null;
      final tickId = '${tick['id']}';
      final previousElement = incomingDamageElement;
      final element = '${tick['element'] ?? ''}';
      incomingDamageElement = element.isEmpty ? 'perforante' : element;
      int? hpLost;
      try {
        await applicaDannoSubito(
          dannoEsplicito: readIntValue(tick['damage']),
          damagePacketId: tickId,
          attackKind: incomingDamageElement,
          enemyLevel: readIntValue(tick['sourceLevel']),
          enemyGrade: readIntValue(tick['sourceGrade']),
          bypassDefense: tick['bypassDefense'] == true,
          bypassShields: tick['bypassShields'] == true,
          onImpact: (impact) {
            if (!onTarget()) return;
            hpLost = impact.hpLost;
            aggiungiLog(
              combatImpactLog('[PIOVRA] Presa succhiasangue', impact),
            );
            if (impact.hpLost > 0) {
              schedePersonaggio[schedaCorrente]['lastDamageSourceTag'] =
                  tick['source'];
            }
            _savePiovraRemoteReceipt(tickId, impact.hpLost);
          },
        );
      } finally {
        if (onTarget()) incomingDamageElement = previousElement;
      }
      if (!onTarget() || pawnPendingDamage.isNotEmpty) return hpLost;
      if (hpLost == null) _savePiovraRemoteReceipt(tickId, 0);
      return hpLost ?? 0;
    } finally {
      try {
        if (onTarget()) {
          salvaSchedaCorrenteInMemoria();
          if (!oculumSameSheetIdentity(original, tag)) {
            final originalIndex = localSheetIndexForOculumTag(original);
            if (originalIndex >= 0) {
              final global = catturaImpostazioniGlobali();
              schedaCorrente = originalIndex;
              caricaStatoDaJson(schedePersonaggio[originalIndex]);
              ripristinaImpostazioniGlobali(global);
            }
          }
        }
      } finally {
        _piovraRemoteDamage[this] = null;
        damage.complete();
      }
    }
  }

  void _healPiovraGrip(String source, Map tick, int hpLost) {
    final healing = oculumPiovraGripHealing(
      hpLost,
      percent: readIntValue(tick['drainPercent'], fallback: 50),
    );
    if (healing <= 0) return;
    faunaForOwnedSheet(source, () {
      if (hpCorrenti() <= 0 || !faunaReceipt('${tick['id']}:cura')) return;
      applyStructuredHealing('vita', healing);
      sendRealtimeHpChanged();
    });
  }

  void _publishPiovraGrip() {
    captureActiveMasterInitiativeGroup();
    sendRealtimeInitiativeSnapshotIfPublished();
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
  }

  void _releasePiovraGrip(Map<String, dynamic> holder) {
    final grip = holder.remove(_piovraGripKey);
    if (grip is! Map) return;
    final tag = '${grip['target']}';
    final target = escapeToken(tag);
    final pending = target?[_piovraTickKey];
    if (pending is Map) {
      pending.removeWhere(
        (_, tick) => tick is Map && tick['grip'] == grip['id'],
      );
      if (pending.isEmpty) target?.remove(_piovraTickKey);
    }
    faunaForOwnedSheet(tag, () {
      final condition = activeConditions.where((condition) {
        return condition.metadata[_piovraGripCondition] == true &&
            condition.metadata['referenceCurseSource'] == grip['id'];
      }).firstOrNull;
      if (condition != null) {
        removeCondition(condition, force: true, expired: true);
      }
    });
  }

  void clearRemovedPiovraGrip(OculumConditionInstance condition) {
    if (!_piovraGripAuthority ||
        condition.metadata[_piovraGripCondition] != true) {
      return;
    }
    final id = condition.metadata['referenceCurseSource'];
    if (id == null) return;
    final holder = masterInitiativeTokens.where((token) {
      final grip = token[_piovraGripKey];
      return grip is Map &&
          grip['id'] == id &&
          grip['scope'] == permissionScope &&
          grip['campaign'] == permissionCampaignId;
    }).firstOrNull;
    if (holder == null) return;
    _releasePiovraGrip(holder);
    _publishPiovraGrip();
  }

  void expirePiovraGrips(String fight, {String? campaignId}) {
    if (fight.isEmpty) return;
    final campaign = campaignId ?? permissionCampaignId;
    for (final token in masterInitiativeTokens) {
      final grip = token[_piovraGripKey];
      if (grip is Map &&
          grip['encounter'] == fight &&
          grip['campaign'] == campaign) {
        _releasePiovraGrip(token);
      }
    }
    // Fight-end receipts may arrive after another initiative group was selected.
    for (var index = 0; index < schedePersonaggio.length; index++) {
      final tag = sheetTagAt(index);
      faunaForOwnedSheet(tag, () {
        final conditions = activeConditions.where((condition) {
          final metadata = condition.metadata;
          return metadata[_piovraGripCondition] == true &&
              metadata['encounter'] == fight &&
              metadata['campaign'] == campaign;
        }).toList();
        for (final condition in conditions) {
          removeCondition(condition, force: true, expired: true);
        }
      });
    }
  }

  Iterable<Widget> piovraGripControls(
    void Function(VoidCallback) select,
  ) sync* {
    final tag = sheetTagAt(schedaCorrente);
    if (!_piovraGripAuthority &&
            _remotePiovraGrip(tag)?.$2['awaitingReflex'] != false ||
        _piovraGripAuthority && _piovraHolder(tag) == null) {
      return;
    }
    yield ListTile(
      leading: const Icon(Icons.link_off),
      title: Text(t('Liberati dalla presa', 'Break free from the grip')),
      subtitle: Text(
        t(
          'Forza o Controllo corporeo · 1 Azione',
          'Strength or Body control · 1 Action',
        ),
      ),
      onTap: () => select(() => unawaited(_attemptPiovraEscape())),
    );
  }

  Future<void> _attemptPiovraEscape() async {
    final target = sheetTagAt(schedaCorrente);
    final holder = _piovraHolder(target);
    final remote = _piovraGripAuthority ? null : _remotePiovraGrip(target);
    final record = holder == null ? remote?.$2 : _piovraGrip(holder);
    if (record == null || !controlsOnlineCombatSheet(target)) {
      return;
    }
    final skill = await showDialog<String>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text(t('Liberati dalla presa', 'Break free from the grip')),
        children: [
          for (final (id, label) in [
            ('forza', t('Forza', 'Strength')),
            ('controllo_corporeo', t('Controllo corporeo', 'Body control')),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, id),
              child: Text(label),
            ),
        ],
      ),
    );
    if (remote != null) {
      if (skill == null || !mounted || target != sheetTagAt(schedaCorrente)) {
        return;
      }
      final current = _remotePiovraGrip(target);
      if (current != null &&
          current.$2['id'] == record['id'] &&
          corruptionCanSpendToken(current.$1, 'azione')) {
        await _replyPiovra(record, 'escape', {
          'roll': _piovraOpposedRoll(target, () => _piovraSubtrait(skill)),
          'round': _onlineCombatRound(),
        });
      }
      return;
    }
    if (holder == null) return;
    bool isCurrent() =>
        mounted &&
        target == sheetTagAt(schedaCorrente) &&
        _piovraGripAuthority &&
        identical(_piovraHolder(target), holder) &&
        identical(_piovraGrip(holder), record);

    if (skill == null ||
        !isCurrent() ||
        !await requestUtilitySpend(
          'azione',
          preferFreeReaction: false,
          deferMasterTurn: true,
        )) {
      return;
    }
    if (isCurrent()) {
      final escape = _piovraOpposedRoll(target, () => _piovraSubtrait(skill));
      final maintain = _rollPiovraGrip(onlineCombatTokenTag(holder));
      final freed = oculumPiovraWinsGripContest(escape, maintain);
      if (freed) _releasePiovraGrip(holder);
      final outcome = freed ? 'Ti liberi.' : 'La presa continua.';
      aggiungiLog(
        '[PIOVRA] Liberazione $escape contro Presa $maintain. $outcome',
      );
      _publishPiovraGrip();
    }
    if (mounted) {
      advanceMasterInitiativeAfterAction(target);
      await flushPendingCombatTurnResources();
    }
  }

  void startPiovraGripTurn(Map<String, dynamic> token, int round) {
    if (!_piovraGripAuthority) return;
    for (final holder in masterInitiativeTokens) {
      if (holder[_piovraGripKey] != null &&
          (_piovraRecord(holder) == null ||
              identical(token, holder) &&
                  _piovraRecord(holder)?['awaitingReflex'] == true)) {
        _releasePiovraGrip(holder);
      }
    }
    if (!_piovraTokenActive(token)) return;
    final tag = publicInitiativeSourceTag(token);
    final holder = _piovraHolder(tag);
    final record = holder == null ? null : _piovraGrip(holder);
    final effect = record?['effect'];
    if (holder == null || record == null || effect is! Map) return;
    if (token['piovraGripTickId'] == '${record['id']}:$round') return;
    final tickId = '${record['id']}:$round';
    final source = onlineCombatTokenTag(holder);
    final damageEffect = OculumStructuredEffect.fromJson(
      Map<String, dynamic>.from(effect),
    );
    final drainData = record['drainEffect'];
    final drainEffect = drainData is Map
        ? OculumStructuredEffect.fromJson(Map<String, dynamic>.from(drainData))
        : null;
    var damage = 0;
    var drainPercent = 50;
    faunaForOwnedSheet(source, () {
      final variables = formulaValueContext();
      damage = oculumResolveStructuredEffectRoll(
        damageEffect,
        variables: variables,
        subtraits: hiddenEyeStats,
        level: leggiNumero(livelloController),
        grade: leggiNumero(gradoController),
        random: Random.secure(),
      ).value;
      if (drainEffect != null) {
        drainPercent = drainEffect.enabled
            ? oculumEvaluateStructuredEffectValue(
                drainEffect,
                variables: variables,
                subtraits: hiddenEyeStats,
              )
            : 0;
      }
    });
    token['piovraGripTickId'] = tickId;
    if (damage <= 0) return;
    final pending = Map<String, dynamic>.from(
      token[_piovraTickKey] as Map? ?? const {},
    );
    pending[tickId] = {
      'id': tickId,
      'grip': record['id'],
      'source': source,
      'damage': damage,
      'element': damageEffect.elementType.trim(),
      'drainPercent': drainPercent,
      'bypassDefense': damageEffect.bypassDefense,
      'bypassShields': damageEffect.bypassShields,
      'sourceLevel': masterInitiativeTokenLevel(holder),
      'sourceGrade': masterInitiativeTokenGrade(holder),
    };
    token[_piovraTickKey] = pending;
    schedulePiovraGripTicks();
  }

  void schedulePiovraGripTicks() {
    if (!_piovraGripAuthority || _piovraGripDrain[this] == true) return;
    if (!masterInitiativeTokens.any((token) => token[_piovraTickKey] is Map)) {
      return;
    }
    _piovraGripDrain[this] = true;
    unawaited(
      Future<void>.delayed(Duration.zero, () async {
        try {
          if (!mounted || !_piovraGripAuthority) return;
          for (final token in masterInitiativeTokens.toList()) {
            final pending = token[_piovraTickKey];
            if (pending is! Map) continue;
            for (final entry in pending.values.whereType<Map>().toList()) {
              await _applyPiovraGripTick(token, entry);
            }
          }
        } finally {
          _piovraGripDrain[this] = null;
        }
      }),
    );
  }

  bool _removePiovraTick(Map<String, dynamic> token, Map tick) {
    final pending = token[_piovraTickKey];
    if (pending is! Map || !identical(pending[tick['id']], tick)) return false;
    pending.remove(tick['id']);
    if (pending.isEmpty) token.remove(_piovraTickKey);
    return true;
  }

  Future<void> _applyPiovraGripTick(
    Map<String, dynamic> token,
    Map tick,
  ) async {
    final tag = onlineCombatTokenTag(token);
    final originalTag = sheetTagAt(schedaCorrente);
    final campaign = activeCampaignId;
    final encounter = onlineCombatEncounterId;
    if (!mounted ||
        !_piovraGripAuthority ||
        !identical(escapeToken(tag), token)) {
      return;
    }
    final source = '${tick['source']}';
    final holder = _piovraHolder(tag);
    if (holder == null || _piovraGrip(holder)?['id'] != tick['grip']) {
      if (_removePiovraTick(token, tick)) _publishPiovraGrip();
      return;
    }
    final targetIndex = localSheetIndexForOculumTag(tag);
    if (targetIndex < 0 || !controlsOnlineCombatSheet(tag)) return;
    final originalGlobal = catturaImpostazioniGlobali();
    salvaSchedaCorrenteInMemoria();
    var hpLost = 0;
    var attempted = false;
    try {
      if (tag != originalTag) {
        schedaCorrente = targetIndex;
        caricaStatoDaJson(schedePersonaggio[targetIndex]);
        ripristinaImpostazioniGlobali(originalGlobal);
      }
      if (pawnPendingDamage.isNotEmpty || !_removePiovraTick(token, tick)) {
        return;
      }
      attempted = true;
      final previousElement = incomingDamageElement;
      final element = '${tick['element']}';
      incomingDamageElement = element.isEmpty ? 'perforante' : element;
      try {
        await applicaDannoSubito(
          dannoEsplicito: readIntValue(tick['damage']),
          damagePacketId: '${tick['id']}',
          attackKind: incomingDamageElement,
          enemyLevel: masterInitiativeTokenLevel(holder),
          enemyGrade: masterInitiativeTokenGrade(holder),
          bypassDefense: tick['bypassDefense'] == true,
          bypassShields: tick['bypassShields'] == true,
          onImpact: (impact) {
            hpLost = impact.hpLost;
            aggiungiLog(
              combatImpactLog('[PIOVRA] Presa succhiasangue', impact),
            );
            if (hpLost > 0) {
              schedePersonaggio[schedaCorrente]['lastDamageSourceTag'] = source;
            }
          },
        );
      } finally {
        if (mounted &&
            campaign == activeCampaignId &&
            sheetTagAt(schedaCorrente) == tag) {
          incomingDamageElement = previousElement;
          salvaSchedaCorrenteInMemoria();
        }
      }
    } finally {
      if (mounted &&
          campaign == activeCampaignId &&
          tag != originalTag &&
          sheetTagAt(schedaCorrente) == tag) {
        final index = localSheetIndexForOculumTag(originalTag);
        if (index >= 0) {
          final global = catturaImpostazioniGlobali();
          schedaCorrente = index;
          caricaStatoDaJson(schedePersonaggio[index]);
          ripristinaImpostazioniGlobali(global);
        }
      }
    }
    if (!attempted ||
        !mounted ||
        campaign != activeCampaignId ||
        encounter != onlineCombatEncounterId) {
      return;
    }
    _healPiovraGrip(source, tick, hpLost);
    if (_piovraGrip(holder) == null) _releasePiovraGrip(holder);
    _publishPiovraGrip();
  }
}
