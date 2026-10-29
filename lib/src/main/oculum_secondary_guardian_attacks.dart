part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

String oculumGuardianSecondaryId(String mode, String originalId) =>
    'guardian-secondary:$mode:$originalId';

bool oculumGuardianMeleeAttack(Map request) {
  if (request['ranged'] == true || request['sourceRanged'] == true) {
    return false;
  }
  if (request['melee'] is bool) return request['melee'] == true;
  if (request['sourceMelee'] is bool) return request['sourceMelee'] == true;
  if (request['ranged'] is bool) return request['ranged'] == false;
  if (request['sourceRanged'] is bool) return request['sourceRanged'] == false;
  if (request['guardian_gold_sword'] == true ||
      request['guardianGoldSword'] == true) {
    return true;
  }
  if (request['sourceFirearm'] != null && request['sourceFirearm'] != false ||
      request['sourceRifle'] == true ||
      request['lunarGuardianStone'] == true ||
      request['lunarGuardianEruption'] == true ||
      request['explosiveCards'] == true) {
    return false;
  }
  final text = oculumNormalizeText(
    '${request['abilityName'] ?? ''} ${request['reason'] ?? ''} ${request['choice'] ?? ''} ${request['choiceId'] ?? ''} ${request['attackKind'] ?? ''}',
  );
  if (RegExp(
    r'raggio|frecc(?:ia|e)|lancio|fulmine|proiettile|boomerang|carte|fucile|rifle|pistola',
  ).hasMatch(text)) {
    return false;
  }
  if (RegExp(
    r'ravvicinato|mischia|pugno|mazza|spadone|forza|schianto|corpo.?a.?corpo',
  ).hasMatch(text)) {
    return true;
  }
  return request['baseAttack'] == true &&
      const {
        'vc',
        'attacco',
      }.contains('${request['choice'] ?? request['choiceId'] ?? ''}');
}

/// An authenticated event is still constrained to an already-known original
/// attack. It cannot choose a new victim, amount, difficulty or fight instance.
bool oculumGuardianSecondaryValid(
  Map payload,
  Map original, {
  required String scope,
  required String encounterId,
  required String fightInstanceId,
}) {
  final mode = '${payload['guardianSecondaryKind'] ?? ''}';
  final originalId = '${original['id'] ?? ''}';
  if (originalId.isEmpty ||
      original['guardianSecondaryEvent'] == true ||
      original['lunarGuardianEruption'] == true ||
      !const {'resolved', 'received'}.contains('${original['status']}') ||
      !const {'full', 'reduced'}.contains('${original['outcome']}') ||
      payload['scope'] != scope ||
      original['scope'] != scope ||
      payload['encounterId'] != encounterId ||
      original['encounterId'] != encounterId ||
      fightInstanceId.isEmpty ||
      payload['guardianSecondaryFightInstanceId'] != fightInstanceId ||
      payload['originalAttackId'] != originalId ||
      payload['id'] != oculumGuardianSecondaryId(mode, originalId)) {
    return false;
  }
  final reflecting = mode == 'gold_reflection';
  if (!reflecting && mode != 'lunar_eruption') return false;
  final creator = reflecting ? original['targetTag'] : original['sourceTag'];
  final victim = reflecting ? original['sourceTag'] : original['targetTag'];
  if (payload['sourceTag'] != creator ||
      payload['creatorTag'] != creator ||
      payload['targetTag'] != victim ||
      creator == victim) {
    return false;
  }
  final reflection = original['guardianGoldReflection'];
  if (reflecting && reflection is! Map) return false;
  if (!reflecting && original['lunarGuardianStone'] != true) return false;
  final damage = reflecting
      ? readIntValue((reflection as Map)['damage'])
      : readIntValue(original['lunarGuardianEruptionDamage'], fallback: 10);
  final attack = readIntValue(original['attackTotal'] ?? original['attack']);
  final frozenDamage = readIntValue(
    payload['guardianSecondaryBaseDamage'],
    fallback: readIntValue(payload['damage']),
  );
  final actualDamage = readIntValue(payload['damage']);
  final result = payload['guardianSecondaryStage'] == 'result';
  return damage > 0 &&
      frozenDamage == damage &&
      (actualDamage == damage ||
          result &&
              !reflecting &&
              payload['lunarGuardianElementResolved'] == true &&
              actualDamage == damage * 2) &&
      readIntValue(payload['attack']) == attack;
}

extension _OculumSecondaryGuardianAttacks on _OculumHomePageState {
  Map<String, dynamic>? guardianSecondaryEncounter(String encounterId) {
    final groups = referenceUsesLocalTurnState
        ? masterInitiativeGroups
        : realtimeEncounterSnapshots;
    return groups
        .where((g) => '${g['encounterId'] ?? g['id'] ?? ''}' == encounterId)
        .firstOrNull;
  }

  List<Map<String, dynamic>> guardianSecondaryEncounterTokens(
    String encounterId,
  ) {
    final group = guardianSecondaryEncounter(encounterId);
    if (group == null) return const [];
    final raw =
        referenceUsesLocalTurnState &&
            encounterId == selectedMasterInitiativeGroupId
        ? masterInitiativeTokens
        : (group['tokens'] as List? ?? const []);
    return raw
        .whereType<Map>()
        .map((t) => Map<String, dynamic>.from(t))
        .toList();
  }

  bool guardianSecondarySenderControls(
    Map<String, dynamic> payload,
    String actor,
  ) {
    if (oculumSameSheetIdentity(payload['senderTag'], actor)) return true;
    final sender = realtimeUsers
        .where(
          (u) =>
              u['sessionId'] == payload['sessionId'] &&
              u['role'] == payload['senderRole'],
        )
        .firstOrNull;
    if ((sender?['localSheetTags'] as List? ?? const []).any(
      (tag) => oculumSameSheetIdentity(tag, actor),
    )) {
      return true;
    }
    if (!const {'master', 'coMaster'}.contains('${payload['senderRole']}')) {
      return false;
    }
    final token = guardianSecondaryEncounterTokens(
      '${payload['encounterId']}',
    ).where((t) => combatTokenMatchesSheet(t, actor)).firstOrNull;
    if (token == null || token['outsideFight'] == true) return false;
    final index = localSheetIndexForOculumTag(actor);
    final type = index >= 0
        ? tipoSchedaPersonaggio(index)
        : '${token['type'] ?? ''}';
    return token['side'] != 'party' ||
        token['npc'] == true ||
        type.toLowerCase().contains('mostro') ||
        type.toLowerCase().contains('boss');
  }

  String guardianSecondaryFightId(String encounterId, String creatorTag) =>
      combatSubtraitExperienceFightId(encounterId, ownerTag: creatorTag);

  bool guardianSecondaryCurrent(Map request) {
    final encounter = '${request['encounterId'] ?? ''}',
        creator = '${request['creatorTag'] ?? ''}';
    if (encounter.isEmpty) return false;
    final group = guardianSecondaryEncounter(encounter);
    if (group == null || group['combatEnded'] == true) return false;
    final tokens = guardianSecondaryEncounterTokens(encounter);
    if (!tokens.any((t) => combatTokenMatchesSheet(t, creator)) ||
        !tokens.any(
          (t) => combatTokenMatchesSheet(t, '${request['targetTag']}'),
        )) {
      return false;
    }
    return request['guardianSecondaryFightInstanceId'] ==
        guardianSecondaryFightId(encounter, creator);
  }

  Future<void> dispatchGuardianSecondaryAttack(
    Map original, {
    Map? reflection,
  }) async {
    if (original['guardianSecondaryEvent'] == true ||
        original['lunarGuardianEruption'] == true) {
      return;
    }
    final reflecting = reflection != null;
    final creator = '${original[reflecting ? 'targetTag' : 'sourceTag'] ?? ''}';
    if (!controlsOnlineCombatSheet(creator)) return;
    final canonical = onlineCombatRequests['${original['id']}'];
    if (canonical == null ||
        canonical['sourceTag'] != original['sourceTag'] ||
        canonical['targetTag'] != original['targetTag']) {
      return;
    }
    if (reflecting) {
      canonical['guardianGoldReflection'] = Map<String, dynamic>.from(
        reflection,
      );
    }
    final encounter = '${canonical['encounterId'] ?? ''}';
    final mode = reflecting ? 'gold_reflection' : 'lunar_eruption';
    final id = oculumGuardianSecondaryId(mode, '${canonical['id']}');
    if (onlineCombatRequests.containsKey(id)) return;
    final packet = <String, dynamic>{
      'id': id,
      'kind': 'guardian_secondary',
      'guardianSecondaryEvent': true,
      'guardianSecondaryKind': mode,
      'guardianSecondaryStage': 'offer',
      'status': 'pending',
      'originalAttackId': canonical['id'],
      'creatorTag': creator,
      'sourceTag': creator,
      'targetTag': canonical[reflecting ? 'sourceTag' : 'targetTag'],
      'sourceName': canonical[reflecting ? 'targetName' : 'sourceName'],
      'targetName': canonical[reflecting ? 'sourceName' : 'targetName'],
      'scope': permissionScope,
      'encounterId': encounter,
      'guardianSecondaryFightInstanceId': guardianSecondaryFightId(
        encounter,
        creator,
      ),
      'attack': readIntValue(canonical['attackTotal'] ?? canonical['attack']),
      'damage': reflecting
          ? readIntValue(reflection['damage'])
          : readIntValue(
              canonical['lunarGuardianEruptionDamage'],
              fallback: 10,
            ),
      'element': reflecting ? 'solare' : 'lunare',
      'baseAttack': false,
      'natural': 10,
      'lunarGuardianEruption': !reflecting,
      'lunarGuardianReactionOnly': !reflecting,
      'abilityName': reflecting
          ? 'Riflesso dello scudo d’oro'
          : 'Eruzione degli spuntoni lunari',
      'effects': <dynamic>[],
    };
    packet['guardianSecondaryBaseDamage'] = packet['damage'];
    if (!guardianSecondaryCurrent(packet) ||
        !oculumGuardianSecondaryValid(
          packet,
          canonical,
          scope: permissionScope,
          encounterId: encounter,
          fightInstanceId: guardianSecondaryFightId(encounter, creator),
        )) {
      return;
    }
    onlineCombatRequests[id] = packet;
    await receiveGuardianSecondaryAttack(packet, local: true);
    if (realtimeService?.isConnected == true) {
      final envelope = permissionEnvelope(packet);
      await realtimeService?.sendCombatEvent('combat_scout', envelope);
    }
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
  }

  Future<void> receiveGuardianSecondaryAttack(
    Map<String, dynamic> payload, {
    bool local = false,
  }) async {
    if (payload['guardianSecondaryEvent'] != true ||
        (!local && !validPermissionSender(payload))) {
      return;
    }
    final original =
        onlineCombatRequests['${payload['originalAttackId'] ?? ''}'];
    if (original == null || !guardianSecondaryCurrent(payload)) return;
    final creator = '${payload['creatorTag'] ?? ''}';
    final stage = '${payload['guardianSecondaryStage'] ?? 'offer'}';
    if (stage == 'offer' &&
        (!local && !guardianSecondarySenderControls(payload, creator))) {
      return;
    }
    if (stage == 'offer' &&
        !local &&
        original['guardianGoldReflection'] is! Map &&
        payload['guardianSecondaryKind'] == 'gold_reflection' &&
        original['targetTag'] == creator &&
        payload['sourceTag'] == creator &&
        payload['targetTag'] == original['sourceTag'] &&
        payload['id'] ==
            oculumGuardianSecondaryId('gold_reflection', '${original['id']}') &&
        payload['scope'] == original['scope']) {
      onlineCombatRequests.putIfAbsent(
        '${payload['id']}',
        () => {
          ...payload,
          'kind': 'guardian_secondary_waiting',
          'status': 'waiting_original',
          'guardianSecondaryOriginalOffer': Map<String, dynamic>.from(payload),
        },
      );
      programmaSalvataggio();
      return;
    }
    if (!oculumGuardianSecondaryValid(
      payload,
      original,
      scope: permissionScope,
      encounterId: '${payload['encounterId']}',
      fightInstanceId: guardianSecondaryFightId(
        '${payload['encounterId']}',
        creator,
      ),
    )) {
      return;
    }
    final id = '${payload['id']}';
    final existing = onlineCombatRequests[id];
    if (stage == 'result') {
      if (!local &&
          !guardianSecondarySenderControls(
            payload,
            '${payload['targetTag']}',
          )) {
        return;
      }
      if (existing == null || existing['status'] == 'resolved') return;
      existing['status'] = 'resolved';
      existing['guardianSecondaryReceipt'] =
          payload['guardianSecondaryReceipt'];
      programmaSalvataggio();
      notifyActiveSheetSummaryChanged();
      return;
    }
    if (stage != 'offer') return;
    if (existing?['kind'] == 'guardian_secondary_waiting') {
      onlineCombatRequests[id] = Map<String, dynamic>.from(payload)
        ..['status'] = 'pending';
    } else {
      onlineCombatRequests.putIfAbsent(
        id,
        () => Map<String, dynamic>.from(payload)..['status'] = 'pending',
      );
    }
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
  }

  Future<void> retryGuardianSecondaryOffers() async {
    for (final waiting
        in onlineCombatRequests.values
            .where((r) => r['kind'] == 'guardian_secondary_waiting')
            .toList()) {
      final original = onlineCombatRequests['${waiting['originalAttackId']}'];
      final offer = waiting['guardianSecondaryOriginalOffer'];
      if (original == null ||
          offer is! Map ||
          original['guardianGoldReflection'] is! Map) {
        continue;
      }
      await receiveGuardianSecondaryAttack(
        Map<String, dynamic>.from(offer),
        local: true,
      );
    }
  }

  Future<void> guardianSecondaryDefense(
    Map<String, dynamic> request, {
    bool retry = false,
    bool acceptDamage = false,
    int? naturalOverride,
  }) async {
    final target = sheetTagAt(schedaCorrente), id = '${request['id']}';
    if (request['kind'] != 'guardian_secondary' ||
        request['status'] != 'pending' ||
        request['encounterId'] != onlineCombatEncounterId ||
        referenceUsesLocalTurnState &&
            request['encounterId'] != selectedMasterInitiativeGroupId ||
        request['targetTag'] != target ||
        !controlsOnlineCombatSheet(target) ||
        !guardianSecondaryCurrent(request) ||
        !onlineCombatResolving.add(id)) {
      return;
    }
    try {
      final original = onlineCombatRequests['${request['originalAttackId']}'];
      if (original == null ||
          !oculumGuardianSecondaryValid(
            request,
            original,
            scope: permissionScope,
            encounterId: onlineCombatEncounterId,
            fightInstanceId: guardianSecondaryFightId(
              onlineCombatEncounterId,
              '${request['creatorTag']}',
            ),
          )) {
        return;
      }
      final reflection = request['guardianSecondaryKind'] == 'gold_reflection';
      if (retry &&
          (!reflection ||
              request['firstSecondaryDefense'] == null ||
              request['secondaryRetryUsed'] == true)) {
        return;
      }
      if (!retry && !acceptDamage && request['firstSecondaryDefense'] != null) {
        return;
      }
      if (!acceptDamage && (!reflection || retry)) {
        if (!await requestUtilitySpend('reazione', preferFreeReaction: false)) {
          return;
        }
        if (!mounted ||
            sheetTagAt(schedaCorrente) != target ||
            !guardianSecondaryCurrent(request)) {
          return;
        }
        if (retry) request['secondaryRetryUsed'] = true;
      }
      var avoided = false;
      if (!acceptDamage) {
        final reflex = hiddenEyeStats
            .where((s) => s.id == 'riflessi')
            .firstOrNull;
        if (reflex == null) return;
        int natural = naturalOverride ?? 0, total = 0;
        if (naturalOverride != null) {
          total = rollTotalWithCritical(natural, 20, [
            hiddenEyeTotal(reflex),
            hiddenEyeStatRollQuickBonus(reflex),
            tiroGlobaleBonus(),
          ]);
        } else {
          await tiraSottotrattoOcchio(
            reflex,
            resourceAlreadySpent: true,
            opposingTotal: readIntValue(request['attack']),
            actionLabel: 'Riflessi · ${request['abilityName']}',
            onResolved: (rolled, resolved) {
              natural = rolled;
              total = resolved;
            },
          );
          if (!mounted ||
              sheetTagAt(schedaCorrente) != target ||
              !guardianSecondaryCurrent(request)) {
            return;
          }
        }
        request['secondaryDefenseTotal'] = total;
        request['secondaryDefenseNatural'] = natural;
        request['firstSecondaryDefense'] ??= {
          'total': total,
          'natural': natural,
        };
        avoided = total >= readIntValue(request['attack']);
        aggiungiLog(
          '[DIFESA SECONDARIA] Riflessi $total / DT${request['attack']}: ${avoided ? 'evitato' : 'fallito'}.',
        );
        if (reflection && !avoided && !retry) {
          request['secondaryRetryOffered'] = true;
          programmaSalvataggio();
          notifyActiveSheetSummaryChanged();
          return;
        }
      }
      request['guardianSecondaryStage'] = 'result';
      if (avoided) {
        request['status'] = 'resolved';
        request['outcome'] = 'avoided';
        request['guardianSecondaryReceipt'] = {'avoided': true, 'hpLost': 0};
      } else {
        lunarGuardianResolveIncomingElement(request);
        await applyResolvedOnlineDefense(
          request,
          'guardian_secondary',
          -1000000,
        );
        request['status'] = 'resolved';
        request['guardianSecondaryReceipt'] = request['damageReceipt'];
      }
      if (realtimeService?.isConnected == true) {
        attachPendingCombatTurnResources(request);
        final envelope = permissionEnvelope(request);
        await realtimeService?.sendCombatEvent('combat_scout', envelope);
      }
      programmaSalvataggio();
      notifyActiveSheetSummaryChanged();
    } finally {
      onlineCombatResolving.remove(id);
    }
  }

  Widget guardianSecondaryPanel() {
    final tag = sheetTagAt(schedaCorrente);
    final pending = onlineCombatRequests.values
        .where(
          (r) =>
              r['kind'] == 'guardian_secondary' &&
              r['status'] == 'pending' &&
              r['encounterId'] == onlineCombatEncounterId &&
              (!referenceUsesLocalTurnState ||
                  r['encounterId'] == selectedMasterInitiativeGroupId) &&
              r['targetTag'] == tag &&
              guardianSecondaryCurrent(r),
        )
        .toList();
    if (pending.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final request in pending)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${request['abilityName']} · ${request['damage']} Danni · Riflessi DT${request['attack']}',
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (request['firstSecondaryDefense'] == null)
                        FilledButton(
                          onPressed: () => guardianSecondaryDefense(request),
                          child: Text(
                            request['guardianSecondaryKind'] ==
                                    'gold_reflection'
                                ? 'Riflessi gratuiti'
                                : 'Schiva con una Reazione',
                          ),
                        ),
                      if (request['secondaryRetryOffered'] == true &&
                          request['secondaryRetryUsed'] != true)
                        FilledButton(
                          onPressed: () =>
                              guardianSecondaryDefense(request, retry: true),
                          child: const Text('Riprova · Reazione'),
                        ),
                      TextButton(
                        onPressed: () => guardianSecondaryDefense(
                          request,
                          acceptDamage: true,
                        ),
                        child: const Text('Subisci il danno'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
