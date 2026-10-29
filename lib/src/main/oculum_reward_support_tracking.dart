part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

bool _rewardSupportMatchesTag(Object? a, Object? b) =>
    a != null && b != null && oculumSameSheetIdentity('$a', '$b');

bool _rewardSupportMatchesEnemy(Map support, Map enemy) =>
    <Object?>[
      support['enemyTag'],
      ...(support['enemyTags'] as List? ?? const []),
    ].any(
      (tag) => <Object?>[
        enemy['id'],
        enemy['sheetTag'],
        enemy['monsterSheetTag'],
      ].any((enemyTag) => _rewardSupportMatchesTag(tag, enemyTag)),
    );

/// A heal is one help event even when its beneficiary later helps defeat more
/// than one enemy. Keep its original ID while attaching the related enemies.
List<Map<String, dynamic>> prepareEncounterRewardSupportHistory(
  Iterable<Map> enemies,
  Iterable<Map> history,
) {
  final unique = <String, Map<String, dynamic>>{};
  for (final row in history) {
    final id = '${row['id'] ?? ''}';
    if (id.isNotEmpty) {
      unique.putIfAbsent(id, () => Map<String, dynamic>.from(row));
    }
  }
  final rows = unique.values.toList();
  for (final enemy in enemies) {
    final tag =
        '${enemy['sheetTag'] ?? enemy['monsterSheetTag'] ?? enemy['id'] ?? ''}';
    final finalId =
        '${enemy['lastAttackId'] ?? enemy['rewardFinalAttackId'] ?? enemy['rewardLastDamageRequestId'] ?? ''}';
    for (final row in rows) {
      if (row['kind'] == 'attack' &&
          finalId.isNotEmpty &&
          row['requestId'] == finalId &&
          _rewardSupportMatchesEnemy(row, enemy)) {
        row['finalAttack'] = true;
      }
    }
    final beneficiaries = <String>{
      if ('${enemy['killerTag'] ?? ''}'.isNotEmpty) '${enemy['killerTag']}',
      for (final row in rows)
        if (row['kind'] != 'heal' && _rewardSupportMatchesEnemy(row, enemy))
          '${row['helperTag'] ?? ''}',
    }..remove('');
    for (final row in rows.where((row) => row['kind'] == 'heal')) {
      if (!beneficiaries.any(
        (beneficiary) =>
            _rewardSupportMatchesTag(beneficiary, row['beneficiaryTag']),
      )) {
        continue;
      }
      row['enemyTags'] = <String>{
        ...(row['enemyTags'] as List? ?? const []).map((value) => '$value'),
        if (tag.isNotEmpty) tag,
      }.toList();
    }
  }
  return rows;
}

String _rewardSupportReceiptId(String original, String target, String effect) {
  var hash = 0x811c9dc5;
  for (final code in '$original|$target|$effect'.codeUnits) {
    hash = ((hash ^ code) * 0x01000193) & 0xffffffff;
  }
  return 'reward-support:${hash.toRadixString(16)}';
}

extension _OculumRewardSupportTracking on _OculumHomePageState {
  Map<String, dynamic>? rewardSupportEncounter(String id) =>
      masterInitiativeGroups
          .where((group) => '${group['id']}' == id)
          .firstOrNull;

  List<Map<String, dynamic>> rewardSupportTokens(Map<String, dynamic> group) =>
      '${group['id']}' == selectedMasterInitiativeGroupId
      ? masterInitiativeTokens
      : (group['tokens'] as List? ?? const [])
            .whereType<Map>()
            .map((token) => Map<String, dynamic>.from(token))
            .toList();

  void recordEncounterRewardSupport({
    required String encounterId,
    required String helperTag,
    required String beneficiaryTag,
    required String kind,
    String enemyTag = '',
    String receiptId = '',
    String requestId = '',
    String helpReceiptId = '',
    int? round,
    double healedHp = 0,
    double hpBefore = 0,
    double maxHp = 0,
    bool decisive = false,
    bool finalAttack = false,
  }) {
    if (!haPermessiMaster ||
        realtimeService?.isConnected == true && !realtimeIsMasterRole ||
        !const {
          'damage',
          'attack',
          'defense',
          'debuff',
          'heal',
        }.contains(kind)) {
      return;
    }
    final group = rewardSupportEncounter(encounterId);
    if (group == null ||
        group['combatEnded'] == true ||
        group['fightStarted'] == false) {
      return;
    }
    final tokens = rewardSupportTokens(group);
    final helper = tokens
        .where((token) => combatTokenMatchesSheet(token, helperTag))
        .firstOrNull;
    final beneficiary = tokens
        .where((token) => combatTokenMatchesSheet(token, beneficiaryTag))
        .firstOrNull;
    final enemy = tokens
        .where((token) => combatTokenMatchesSheet(token, enemyTag))
        .firstOrNull;
    if (helper == null ||
        helper['side'] == 'enemy' ||
        helper['encounterObject'] == true ||
        masterInitiativeTokenIsTemporary(helper)) {
      return;
    }
    if (kind == 'heal') {
      if (beneficiary == null ||
          beneficiary['side'] == 'enemy' ||
          _rewardSupportMatchesTag(helperTag, beneficiaryTag) ||
          !healedHp.isFinite ||
          !hpBefore.isFinite ||
          !maxHp.isFinite ||
          healedHp <= 0 ||
          hpBefore < 0 ||
          maxHp <= 0 ||
          hpBefore * 100 >= maxHp * 51) {
        return;
      }
    } else if (enemy == null || enemy['side'] != 'enemy') {
      return;
    }
    if ((kind == 'attack' || kind == 'defense') &&
        (beneficiary == null ||
            beneficiary['side'] == 'enemy' ||
            _rewardSupportMatchesTag(helperTag, beneficiaryTag))) {
      return;
    }
    final id = receiptId.isNotEmpty
        ? receiptId
        : '$requestId:$kind:$helperTag:$beneficiaryTag:$enemyTag';
    if (id.isEmpty || id.length > 600) return;
    final history = (group['rewardSupportHistory'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    if (history.any((row) => row['id'] == id)) return;
    final index = localSheetIndexForOculumTag(helperTag);
    final sheet = index < 0
        ? null
        : index == schedaCorrente
        ? statoCorrenteJson()
        : schedePersonaggio[index];
    final power = sheet == null
        ? oculumEncounterPermanentTotalPower(helper)
        : oculumEncounterPermanentTotalPower(sheet);
    final fight =
        '${helper['fightInstanceId'] ?? group['rewardFightInstanceId'] ?? ''}';
    history.add({
      'id': id,
      'helperTag': helperTag,
      'beneficiaryTag': beneficiaryTag,
      'enemyTag': enemyTag,
      'kind': kind,
      'round':
          round ??
          ('${group['id']}' == selectedMasterInitiativeGroupId
              ? masterInitiativeRound
              : readIntValue(group['round'])),
      'fightInstanceId': fight,
      'helperTotalPower': power,
      'decisive': decisive,
      'finalAttack': finalAttack,
      'amount': max(0, healedHp.floor()),
      'hpBefore': max(0, hpBefore.floor()),
      'hpMax': max(0, maxHp.floor()),
      'requestId': requestId,
      if (helpReceiptId.isNotEmpty) 'helpReceiptId': helpReceiptId,
    });
    group['rewardSupportHistory'] = history;
    programmaSalvataggio(invalidateCaches: false);
  }

  void recordEncounterRewardCombatResult(Map<String, dynamic> request) {
    if (!haPermessiMaster ||
        realtimeService?.isConnected == true && !realtimeIsMasterRole) {
      return;
    }
    if (request['status'] != 'resolved' || request['damageReceipt'] is! Map) {
      return;
    }
    final id = '${request['id'] ?? ''}',
        encounterId = '${request['encounterId'] ?? ''}';
    if (id.isEmpty) return;
    final group = rewardSupportEncounter(encounterId);
    if (group == null) return;
    final tokens = rewardSupportTokens(group);
    final source = '${request['sourceTag'] ?? ''}',
        target = '${request['targetTag'] ?? ''}';
    final attacker = tokens
        .where((token) => combatTokenMatchesSheet(token, source))
        .firstOrNull;
    final defender = tokens
        .where((token) => combatTokenMatchesSheet(token, target))
        .firstOrNull;
    if (attacker == null || defender == null) return;
    final receipt = request['damageReceipt'] as Map;
    final damage = const [
      'hpLost',
      'temporaryHpLost',
      'shieldLost',
      'oculumShieldLost',
    ].fold<int>(0, (sum, key) => sum + max(0, readIntValue(receipt[key])));
    if (defender['side'] == 'enemy' &&
        attacker['side'] != 'enemy' &&
        damage > 0) {
      defender['rewardLastDamageRequestId'] = id;
      defender['rewardLastDamageSourceTag'] = source;
      defender['rewardLastDamageRound'] =
          '${group['id']}' == selectedMasterInitiativeGroupId
          ? masterInitiativeRound
          : readIntValue(group['round']);
      if ('${group['id']}' != selectedMasterInitiativeGroupId) {
        group['tokens'] = tokens;
      }
      recordEncounterRewardSupport(
        encounterId: encounterId,
        helperTag: source,
        beneficiaryTag: source,
        enemyTag: target,
        kind: 'damage',
        requestId: id,
        receiptId: '$id:damage:$source',
      );
    }
    List<Map<String, dynamic>> contributions(String key, String fallback) {
      final detailed = (request[key] as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      if (detailed.isNotEmpty) return detailed;
      return (request[fallback] as List? ?? const [])
          .map(
            (tag) => <String, dynamic>{
              'sourceTag': '$tag',
              'id': '${request['attackGroupId'] ?? id}:$fallback:$tag',
            },
          )
          .toList();
    }

    final attack = readIntValue(request['attack']),
        defense = readIntValue(request['defense']);
    final hit = request['outcome'] != OculumAttackOutcome.avoided.name;
    if (defender['side'] == 'enemy' && attacker['side'] != 'enemy' && hit) {
      for (final help in contributions(
        'sourceHelpersContributions',
        'sourceHelpers',
      )) {
        final helper = '${help['sourceTag'] ?? help['helperTag'] ?? ''}';
        if (help.containsKey('bonus') && readIntValue(help['bonus']) <= 0) {
          continue;
        }
        final bonus = max(0, readIntValue(help['bonus']));
        final decisive =
            bonus > 0 &&
            oculumAttackOutcome(
                  attack - bonus,
                  defense,
                  difficulty: '${request['difficulty'] ?? 'normale'}',
                ) ==
                OculumAttackOutcome.avoided;
        recordEncounterRewardSupport(
          encounterId: encounterId,
          helperTag: helper,
          beneficiaryTag: source,
          enemyTag: target,
          kind: 'attack',
          requestId: id,
          receiptId: '${help['id'] ?? id}:attack:$helper:$target',
          helpReceiptId: '${help['id'] ?? id}:attack:$helper',
          decisive: decisive,
        );
      }
    }
    if (attacker['side'] == 'enemy' && defender['side'] != 'enemy') {
      for (final help in contributions(
        'defenseHelpersContributions',
        'defenseHelpers',
      )) {
        final helper = '${help['sourceTag'] ?? help['helperTag'] ?? ''}';
        if (help.containsKey('bonus') && readIntValue(help['bonus']) <= 0) {
          continue;
        }
        recordEncounterRewardSupport(
          encounterId: encounterId,
          helperTag: helper,
          beneficiaryTag: target,
          enemyTag: source,
          kind: 'defense',
          requestId: id,
          receiptId: '${help['id'] ?? id}:defense:$helper:$source',
          helpReceiptId: '${help['id'] ?? id}:defense:$helper',
        );
      }
    }
  }

  String rewardSupportEffectFingerprint() => jsonEncode({
    'hp': hpCorrenti(),
    'oculum': oculumTotale(),
    'res': currentResilienza(),
    'vol': currentVolonta(),
    'mat': currentMateria(),
    'conditions': activeConditions
        .map((condition) => condition.toJson())
        .toList(),
    'stress': sottoStress,
    'effects': activeStructuredEffects,
    'planar': planarState,
  });

  bool rewardSupportEffectIsDebuff(OculumStructuredEffect effect, int value) {
    if (effect.type == 'stato') {
      return oculumConditionDefinition(
            effect.appliedState.isEmpty ? 'sotto_stress' : effect.appliedState,
          )?.polarity ==
          OculumConditionPolarity.negative;
    }
    if (value == 0) return false;
    if (effect.type.startsWith('rimuovi_') ||
        effect.mode == 'diminuzione' ||
        value < 0) {
      return true;
    }
    return effect.type == 'planar' &&
        (effect.target.contains('malicious_shaman_') ||
            const {
              'strange_presence_push',
              'rabbit_chains',
              'oblivion_memory',
              'bell_paralysis',
            }.contains(effect.target));
  }

  void recordRewardSupportAppliedEffect({
    required Map<String, dynamic> request,
    required OculumStructuredEffect effect,
    required int value,
    required int hpBefore,
    required int hpMaximum,
    required String beforeFingerprint,
  }) {
    final target = sheetTagAt(schedaCorrente);
    if (!_rewardSupportMatchesTag(target, request['targetTag'])) return;
    final id = '${request['id'] ?? ''}';
    if (id.isEmpty) return;
    final heal =
        effect.type == 'cura' &&
        oculumNormalizeEffectResource(effect.resource) != 'oculum' &&
        hpCorrenti() > hpBefore;
    var stateChanged = beforeFingerprint != rewardSupportEffectFingerprint();
    if (effect.type == 'stato' && beforeFingerprint.isNotEmpty) {
      final before = jsonDecode(beforeFingerprint) as Map;
      stateChanged =
          jsonEncode(before['conditions']) !=
              jsonEncode(
                activeConditions
                    .map((condition) => condition.toJson())
                    .toList(),
              ) ||
          before['stress'] != sottoStress;
    }
    final debuff = rewardSupportEffectIsDebuff(effect, value) && stateChanged;
    if (!heal && !debuff) return;
    final kind = heal ? 'heal' : 'debuff';
    final key = _rewardSupportReceiptId(
      id,
      target,
      '${effect.id}:${effect.type}:${effect.target}:$kind',
    );
    final receipt = <String, dynamic>{
      'id': key,
      'kind': 'help',
      'helpMode': 'reward_receipt',
      'scope': permissionScope,
      'encounterId': request['encounterId'],
      'sourceTag': request['sourceTag'],
      'targetTag': target,
      'receiptFor': id,
      'rewardSupportKind': kind,
      'effectId': effect.id,
      'effectType': effect.type,
      'effectTarget': effect.target,
      'amount': heal ? hpCorrenti() - hpBefore : 0,
      'hpBefore': hpBefore,
      'hpMax': hpMaximum,
      'fightInstanceId': combatSubtraitExperienceFightId(
        '${request['encounterId'] ?? ''}',
        ownerTag: target,
      ),
    };
    final role = realtimeService?.authenticatedRole;
    if (realtimeService != null &&
        (role == null ? !realtimeIsMasterRole : role != 'master')) {
      queueRewardSupportReceipt(receipt);
      unawaited(replayRewardSupportReceipts());
    } else {
      applyRewardSupportReceipt(receipt, request);
    }
  }

  Map<String, dynamic>? _rewardSupportOwnerRuntime(String owner) {
    final index = localSheetIndexForOculumTag(owner);
    if (index < 0 || schedePersonaggio[index]['realtimeSharedSheet'] == true) {
      return null;
    }
    if (index == schedaCorrente) return planarState;
    final runtime = Map<String, dynamic>.from(
      schedePersonaggio[index]['planarRuntime'] as Map? ?? const {},
    );
    schedePersonaggio[index]['planarRuntime'] = runtime;
    return runtime;
  }

  Map<String, dynamic> rewardSupportOutbox(String owner) =>
      Map<String, dynamic>.from(
        _rewardSupportOwnerRuntime(owner)?['rewardSupportOutbox'] as Map? ??
            const {},
      );

  void queueRewardSupportReceipt(Map<String, dynamic> receipt) {
    final owner = '${receipt['targetTag'] ?? ''}';
    final runtime = _rewardSupportOwnerRuntime(owner);
    final id = '${receipt['id'] ?? ''}';
    if (runtime == null || id.isEmpty || receipt['scope'] != permissionScope) {
      return;
    }
    final pending = rewardSupportOutbox(owner);
    pending.putIfAbsent(id, () => Map<String, dynamic>.from(receipt));
    runtime['rewardSupportOutbox'] = pending;
    final original = onlineCombatRequests['${receipt['receiptFor'] ?? ''}'];
    if (original != null) attachRewardSupportReceipts(original);
    programmaSalvataggio(invalidateCaches: false);
  }

  /// The same receipt travels with the already durable defense reply as well
  /// as the standalone help event. Both routes share one deterministic ID.
  void attachRewardSupportReceipts(Map<String, dynamic> request) {
    final owner = '${request['targetTag'] ?? ''}';
    final pending = rewardSupportOutbox(owner).values.whereType<Map>().where(
      (receipt) =>
          receipt['receiptFor'] == request['id'] &&
          receipt['scope'] == permissionScope &&
          receipt['encounterId'] == request['encounterId'] &&
          receipt['sourceTag'] == request['sourceTag'],
    );
    final receipts = pending
        .map((receipt) => Map<String, dynamic>.from(receipt))
        .take(32)
        .toList();
    if (receipts.isEmpty) {
      request.remove('rewardSupportReceipts');
    } else {
      request['rewardSupportReceipts'] = receipts;
    }
  }

  Future<void> replayRewardSupportReceipts() async {
    final service = realtimeService;
    if (service == null || !service.isConnected || realtimeIsMasterRole) return;
    final owner = sheetTagAt(schedaCorrente);
    final runtime = _rewardSupportOwnerRuntime(owner);
    if (runtime == null) return;
    for (final item in rewardSupportOutbox(owner).entries.toList()) {
      if (!mounted ||
          realtimeService != service ||
          !service.isConnected ||
          sheetTagAt(schedaCorrente) != owner) {
        return;
      }
      if (item.value is! Map) continue;
      final receipt = Map<String, dynamic>.from(item.value as Map);
      final encounter = '${receipt['encounterId'] ?? ''}';
      // A different board/campaign is a pause, not a reason to lose a receipt.
      if (receipt['scope'] != permissionScope ||
          encounter != onlineCombatEncounterId ||
          !_rewardSupportMatchesTag(receipt['targetTag'], owner)) {
        continue;
      }
      final currentFight = combatSubtraitExperienceFightId(
        encounter,
        ownerTag: owner,
      );
      final recordedFight = '${receipt['fightInstanceId'] ?? ''}';
      if (recordedFight.isNotEmpty &&
          currentFight.isNotEmpty &&
          recordedFight != currentFight) {
        final pending = rewardSupportOutbox(owner)..remove(item.key);
        runtime['rewardSupportOutbox'] = pending;
        programmaSalvataggio(invalidateCaches: false);
        continue;
      }
      final original = onlineCombatRequests['${receipt['receiptFor'] ?? ''}'];
      if (original != null) attachRewardSupportReceipts(original);
      try {
        await service.sendCombatEvent(
          'combat_help',
          permissionEnvelope(receipt),
        );
      } catch (_) {
        // Keep the original, unapplied receipt for the existing reconnect replay.
      }
    }
  }

  void receiveRewardSupportReceiptsFromReply(Map<String, dynamic> reply) {
    if (!realtimeIsMasterRole || !validPermissionSender(reply)) return;
    final receipts = (reply['rewardSupportReceipts'] as List? ?? const [])
        .whereType<Map>()
        .take(32);
    for (final receipt in receipts) {
      // Authentication belongs to the enclosing packet, never to nested data.
      receiveRewardSupportReceipt({
        ...Map<String, dynamic>.from(receipt),
        'receiptFor': reply['id'],
        'sourceTag': reply['sourceTag'],
        'targetTag': reply['targetTag'],
        'encounterId': reply['encounterId'],
        'helpMode': 'reward_receipt',
        for (final key in const [
          'scope',
          'campaignId',
          'senderTag',
          'senderRole',
          'sessionId',
        ])
          key: reply[key],
      });
    }
  }

  void receiveRewardSupportAcknowledgement(Map<String, dynamic> payload) {
    if (payload['phase'] != 'reward_support' ||
        payload['senderRole'] != 'master' ||
        !validPermissionSender(payload)) {
      return;
    }
    final owner = '${payload['targetTag'] ?? ''}';
    final runtime = _rewardSupportOwnerRuntime(owner);
    if (runtime == null) return;
    final pending = rewardSupportOutbox(owner);
    final id = '${payload['id'] ?? ''}';
    final receipt = pending[id];
    if (receipt is! Map ||
        receipt['sourceTag'] != payload['sourceTag'] ||
        receipt['targetTag'] != payload['targetTag'] ||
        receipt['encounterId'] != payload['encounterId'] ||
        receipt['receiptFor'] != payload['receiptFor'] ||
        receipt['scope'] != payload['scope']) {
      return;
    }
    pending.remove(id);
    runtime['rewardSupportOutbox'] = pending;
    final original = onlineCombatRequests['${receipt['receiptFor']}'];
    if (original != null) attachRewardSupportReceipts(original);
    programmaSalvataggio(invalidateCaches: false);
  }

  void applyRewardSupportReceipt(
    Map<String, dynamic> payload,
    Map<String, dynamic> original,
  ) {
    final kind = '${payload['rewardSupportKind'] ?? ''}';
    final target = '${original['targetTag'] ?? ''}',
        source = '${original['sourceTag'] ?? ''}';
    recordEncounterRewardSupport(
      encounterId: '${original['encounterId'] ?? ''}',
      helperTag: source,
      beneficiaryTag: kind == 'heal' ? target : source,
      enemyTag: kind == 'debuff' ? target : '',
      kind: kind,
      receiptId: '${payload['id']}',
      requestId: '${original['id']}',
      healedHp: readIntValue(payload['amount']).toDouble(),
      hpBefore: readIntValue(payload['hpBefore']).toDouble(),
      maxHp: readIntValue(payload['hpMax']).toDouble(),
    );
  }

  void receiveRewardSupportReceipt(Map<String, dynamic> payload) {
    if (!realtimeIsMasterRole ||
        !validPermissionSender(payload) ||
        payload['scope'] != permissionScope ||
        payload['helpMode'] != 'reward_receipt') {
      return;
    }
    final original = onlineCombatRequests['${payload['receiptFor'] ?? ''}'];
    if (original == null ||
        original['encounterId'] != payload['encounterId'] ||
        original['sourceTag'] != payload['sourceTag'] ||
        original['targetTag'] != payload['targetTag']) {
      return;
    }
    final group = rewardSupportEncounter('${original['encounterId'] ?? ''}');
    if (group == null ||
        group['combatEnded'] == true ||
        group['fightStarted'] == false) {
      return;
    }
    final targetToken = rewardSupportTokens(group)
        .where(
          (token) => combatTokenMatchesSheet(token, '${original['targetTag']}'),
        )
        .firstOrNull;
    final expectedFight = '${targetToken?['fightInstanceId'] ?? ''}';
    final receivedFight = '${payload['fightInstanceId'] ?? ''}';
    if (expectedFight.isNotEmpty &&
        receivedFight.isNotEmpty &&
        expectedFight != receivedFight) {
      return;
    }
    final staff = const {'master', 'coMaster'}.contains(payload['senderRole']);
    if (!staff &&
        !_rewardSupportMatchesTag(
          payload['senderTag'],
          original['targetTag'],
        )) {
      return;
    }
    final kind = '${payload['rewardSupportKind']}';
    if (!const {'heal', 'debuff'}.contains(kind)) return;
    if (kind == 'debuff' &&
        original['kind'] != 'help' &&
        original['status'] != 'resolved') {
      return;
    }
    final effects = (original['effects'] as List? ?? const [])
        .whereType<Map>()
        .where(
          (effect) =>
              '${effect['id'] ?? ''}' == '${payload['effectId'] ?? ''}' &&
              effect['type'] == payload['effectType'] &&
              '${effect['target'] ?? ''}' == '${payload['effectTarget'] ?? ''}',
        )
        .map(
          (effect) => OculumStructuredEffect.fromJson(
            Map<String, dynamic>.from(effect),
          ),
        )
        .toList();
    if (effects.isEmpty) return;
    final expectedIds = effects
        .map(
          (effect) => _rewardSupportReceiptId(
            '${original['id']}',
            '${original['targetTag']}',
            '${effect.id}:${effect.type}:${effect.target}:$kind',
          ),
        )
        .toSet();
    if (!expectedIds.contains('${payload['id']}')) return;
    if (kind == 'heal') {
      final before = readIntValue(payload['hpBefore'], fallback: -1);
      final maximum = readIntValue(payload['hpMax']);
      final amount = readIntValue(payload['amount']);
      final budget = effects
          .where(
            (effect) =>
                effect.type == 'cura' &&
                oculumNormalizeEffectResource(effect.resource) != 'oculum',
          )
          .fold<int>(
            0,
            (sum, effect) =>
                sum + max(0, int.tryParse(effect.valueExpression) ?? 0),
          );
      if (before < 0 ||
          maximum <= 0 ||
          maximum > 100000000 ||
          before >= maximum ||
          amount <= 0 ||
          amount > budget ||
          amount > maximum - before) {
        return;
      }
    } else if (!effects.any(
          (effect) => rewardSupportEffectIsDebuff(
            effect,
            int.tryParse(effect.valueExpression) ?? 0,
          ),
        ) ||
        original['outcome'] == OculumAttackOutcome.avoided.name) {
      return;
    }
    applyRewardSupportReceipt(payload, original);
    unawaited(
      realtimeService?.sendCombatEvent(
        'combat_ack',
        permissionEnvelope({
          'id': payload['id'],
          'phase': 'reward_support',
          'receiptFor': original['id'],
          'sourceTag': original['sourceTag'],
          'targetTag': original['targetTag'],
          'encounterId': original['encounterId'],
        }),
      ),
    );
  }
}
