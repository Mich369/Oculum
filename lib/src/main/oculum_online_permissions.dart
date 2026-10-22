part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

bool oculumActionNeedsApproval({required bool online, required bool staff}) =>
    online && !staff;

extension _OculumOnlinePermissions on _OculumHomePageState {
  bool get onlineMasterApprovalRequired =>
      realtimeService?.isConnected == true ||
      isConnectedToMaster ||
      relayConnected;

  String get permissionScope =>
      '${realtimeService?.normalizedRoomId ?? realtimeRoomController.text.trim()}:$permissionCampaignId';

  String get permissionCampaignId {
    if (realtimeService?.isConnected == true && !realtimeIsMasterRole) {
      // Follow the session that actually published this fight, not the first
      // Presence row of an account that has several Master devices open.
      final sharedCampaign =
          '${realtimeVisibleInitiativeSnapshot['campaignId'] ?? ''}';
      if (realtimeVisibleInitiativeSnapshot.containsKey('campaignId')) {
        return sharedCampaign;
      }
      final master = realtimeUsers
          .where((user) => user['role'] == 'master')
          .firstOrNull;
      final campaign = '${master?['campaignId'] ?? ''}';
      if (campaign.isNotEmpty) return campaign;
      // A restored, database-verified Master snapshot remains authoritative
      // while the Master is temporarily absent from Presence.
    }
    return activeCampaignId;
  }

  Set<String> get ownPermissionTags => schedePersonaggio
      .where((sheet) => !readBoolValue(sheet['realtimeSharedSheet']))
      .map(
        (sheet) => normalizeOculumFriendTag(
          '${sheet['sheetTag'] ?? sheet['id'] ?? ''}',
        ),
      )
      .where((tag) => tag.isNotEmpty)
      .toSet();

  Iterable<Map<String, dynamic>> get currentPermissionRequests =>
      onlinePermissionRequests.values.where(
        (request) =>
            request['scope'] == permissionScope ||
            (const {
                  'room_join',
                  'sheet_identity_conflict',
                }.contains(request['action']) &&
                request['roomCode'] == realtimeService?.normalizedRoomId),
      );

  bool validPermissionSender(
    Map<String, dynamic> payload, {
    bool staff = false,
  }) {
    if (payload['scope'] != permissionScope ||
        payload['campaignId'] != permissionCampaignId) {
      return false;
    }
    final role = '${payload['senderRole'] ?? ''}';
    if (staff && role != 'master' && role != 'coMaster') return false;
    final senderTag = normalizeOculumFriendTag(
      '${payload['senderTag'] ?? ''}',
    ).toUpperCase();
    if (senderTag.isEmpty) return false;
    return realtimeUsers.any((user) {
      if ('${user['sessionId'] ?? ''}' != '${payload['sessionId'] ?? ''}' ||
          '${user['role'] ?? ''}' != role) {
        return false;
      }
      final listedTags = <String>{};
      final rawTags = user['localSheetTags'];
      if (rawTags is List) {
        for (final raw in rawTags) {
          final tag = normalizeOculumFriendTag('$raw').toUpperCase();
          if (tag.isNotEmpty) listedTags.add(tag);
        }
      }
      // Presence from older clients may not yet expose the owned tag list.
      // Keep their active-tag behaviour as a compatibility fallback.  Newer
      // clients are accepted for every locally owned sheet, so a quick sheet
      // switch cannot make an attack disappear before Presence refreshes.
      if (listedTags.isNotEmpty) return listedTags.contains(senderTag);
      return normalizeOculumFriendTag(
            '${user['activeSheetTag'] ?? ''}',
          ).toUpperCase() ==
          senderTag;
    });
  }

  Map<String, dynamic> permissionEnvelope(Map<String, dynamic> request) => {
    ...request,
    'scope': permissionScope,
    'campaignId': permissionCampaignId,
    'senderTag': sheetTagAt(schedaCorrente),
    'senderRole': realtimeLocalRole(),
  };

  void refreshPermissionUi() {
    onlinePermissionRevision.value++;
    if (mounted) setState(() {});
    unawaited(salvaDatiSoloLocale());
  }

  void requestMasterAction(
    String action,
    String description, {
    String? sheetTag,
  }) {
    ensureCampaignsReady();
    final tag = sheetTag ?? sheetTagAt(schedaCorrente);
    if (canActWithoutMasterApproval) {
      applyApprovedMasterAction(action, tag);
      return;
    }
    final id = '$permissionScope:$tag:$action';
    final existing = onlinePermissionRequests[id];
    if (existing != null && existing['status'] == 'pending') {
      unawaited(replayPermissionRequests());
      return;
    }
    final request = <String, dynamic>{
      'id': id,
      'scope': permissionScope,
      'action': action,
      'sheetTag': tag,
      'requesterTag': sheetTagAt(schedaCorrente),
      'requesterName': realtimeDisplayName(),
      'description': description,
      'status': 'pending',
      'unread': true,
      'createdAt': DateTime.now().toIso8601String(),
    };
    onlinePermissionRequests[id] = request;
    aggiungiLog('Richiesta al Master: $description · in attesa.');
    refreshPermissionUi();
    unawaited(replayPermissionRequests());
  }

  void applyApprovedMasterAction(String action, String tag) {
    if (action == 'monster_entry') {
      final index = localSheetIndexForOculumTag(tag);
      if (index >= 0) {
        schedePersonaggio[index]['monsterBookApproved'] = true;
        schedePersonaggio[index]['monsterBookApprovedScope'] = permissionScope;
      }
    } else if (action == 'encounter_reset') {
      resetMasterInitiativeRound();
    }
  }

  Future<void> replayPermissionRequests() async {
    final service = realtimeService;
    if (service?.isConnected != true) return;
    for (final request in currentPermissionRequests.toList()) {
      if (request['status'] == 'pending' &&
          ownPermissionTags.contains('${request['requesterTag']}')) {
        await service!.sendPermissionEvent(
          'permission_request',
          permissionEnvelope(request),
        );
      } else if (request['status'] != 'pending' &&
          haPermessiMaster &&
          request['decidedByTag'] == sheetTagAt(schedaCorrente)) {
        await service!.sendPermissionEvent(
          'permission_decision',
          permissionEnvelope(request),
        );
      }
    }
  }

  void startPermissionRetry() {
    // A room can contain profiles with different local campaign IDs. Requests
    // use the Master campaign identity, while local saves retain their own IDs.
    final roomPrefix =
        '${realtimeService?.normalizedRoomId ?? realtimeRoomController.text.trim()}:';
    for (final request in onlinePermissionRequests.values.toList()) {
      if (request['status'] == 'pending' &&
          ownPermissionTags.contains('${request['requesterTag']}') &&
          '${request['scope']}'.startsWith(roomPrefix) &&
          request['scope'] != permissionScope) {
        onlinePermissionRequests.remove(request['id']);
        request['scope'] = permissionScope;
        request['id'] =
            '$permissionScope:${request['sheetTag']}:${request['action']}';
        onlinePermissionRequests['${request['id']}'] = request;
      }
    }
    onlinePermissionRetryTimer?.cancel();
    var sheetRefreshTicks = 0;
    onlinePermissionRetryTimer = Timer.periodic(const Duration(seconds: 5), (
      _,
    ) {
      if (mounted && realtimeService?.isConnected == true) {
        if (++sheetRefreshTicks >= 12) {
          sheetRefreshTicks = 0;
          // Check hashes locally once per minute; unchanged sheets send nothing.
          if (!realtimeIsMasterRole && realtimeHasMasterOnline) {
            unawaited(sendRealtimeActiveSheetToStaff());
          }
        }
        unawaited(replayPermissionRequests());
        unawaited(replayOnlineCombatRequests(retryOnly: true));
      }
    });
    unawaited(replayPermissionRequests());
  }

  void setTrustedCoMaster(Map<String, dynamic> record) {
    if (!realtimeIsMasterRole || realtimeService?.isConnected != true) return;
    final tag = normalizeOculumFriendTag('${record['sheetId'] ?? ''}');
    if (tag.isEmpty) return;
    final key = '$permissionScope:$tag';
    if (!trustedCoMasterTags.remove(key)) trustedCoMasterTags.add(key);
    aggiungiLog(
      '${record['sheetName'] ?? tag}: Co-Master ${trustedCoMasterTags.contains(key) ? 'fidato' : 'non fidato'}.',
    );
    setRealtimeCoMasterForRecord(record, true);
    refreshPermissionUi();
  }

  void receivePermissionEvent(String event, Map<String, dynamic> payload) {
    if (payload['action'] == 'utility_spend') {
      receiveUtilitySpend(event, payload);
      return;
    }
    if (payload['action'] == 'defense_retry') {
      receiveDefenseRetryPermission(event, payload);
      return;
    }
    if (event == 'permission_request' &&
        payload['action'] == 'sheet_identity_conflict') {
      // This is a diagnostic request from a database-verified room member,
      // not a claim of ownership or permission to act on the named sheet.
      final userId = '${payload['authenticatedUserId'] ?? ''}';
      if (!haPermessiMaster ||
          userId.isEmpty ||
          payload['authenticatedRole'] != 'player') {
        return;
      }
      final id = '${payload['id'] ?? ''}';
      final tag = '${payload['requestedSheetTag'] ?? ''}';
      if (id != 'sheet_identity:$userId:$tag' || tag.isEmpty) return;
      if (onlinePermissionRequests.containsKey(id)) return;
      onlinePermissionRequests[id] = {
        'id': id,
        'action': 'sheet_identity_conflict',
        'scope': permissionScope,
        'roomCode': realtimeService?.normalizedRoomId,
        'requesterName':
            '${payload['requesterName'] ?? payload['playerName'] ?? 'Player'}',
        'description':
            'Scheda $tag da collegare: il tag risulta di un altro account. Il giocatore deve usare l’account originale o una copia con nuovo tag.',
        'status': 'pending',
        'unread': true,
        'createdAt': payload['createdAt'],
      };
      refreshPermissionUi();
      notifyMasterOfPendingRequest();
      return;
    }
    if (!validPermissionSender(
      payload,
      staff: event == 'permission_decision',
    )) {
      return;
    }
    final id = '${payload['id'] ?? ''}';
    final action = '${payload['action'] ?? ''}';
    if (id.isEmpty ||
        !const {'monster_entry', 'encounter_reset'}.contains(action)) {
      return;
    }
    if (event == 'permission_request') {
      if (!haPermessiMaster ||
          payload['requesterTag'] != payload['senderTag']) {
        return;
      }
      final existing = onlinePermissionRequests[id];
      if (existing != null && existing['createdAt'] == payload['createdAt']) {
        if (existing['status'] != 'pending') {
          unawaited(replayPermissionRequests());
        }
        return;
      }
      onlinePermissionRequests[id] = {
        ...payload,
        'status': 'pending',
        'unread': true,
      };
      aggiungiLog(
        '${payload['requesterName']}: richiesta ${payload['description']} · in attesa.',
      );
      notifyMasterOfPendingRequest();
    } else {
      final existing = onlinePermissionRequests[id];
      if (existing == null ||
          existing['createdAt'] != payload['createdAt'] ||
          existing['status'] != 'pending') {
        return;
      }
      final allowed = payload['status'] == 'approved';
      if (!allowed && payload['status'] != 'rejected') return;
      onlinePermissionRequests[id] = {...existing, ...payload, 'unread': false};
      if (allowed &&
          ownPermissionTags.contains('${existing['requesterTag']}')) {
        applyApprovedMasterAction(action, '${existing['sheetTag']}');
      }
      if (allowed &&
          haPermessiMaster &&
          !ownPermissionTags.contains('${existing['requesterTag']}')) {
        if (action == 'encounter_reset') resetMasterInitiativeRound();
        if (action == 'monster_entry') {
          final index = schedePersonaggio.indexWhere(
            (sheet) =>
                sheet['realtimeSourceSheetTag'] == existing['sheetTag'] ||
                sheet['sheetTag'] == existing['sheetTag'],
          );
          if (index >= 0) {
            schedePersonaggio[index]['monsterBookApproved'] = true;
          }
        }
      }
      aggiungiLog(
        '${existing['requesterName']}: ${existing['description']} · ${allowed ? 'consentito' : 'rifiutato'} da ${payload['decidedByName']}.',
      );
    }
    refreshPermissionUi();
  }

  Future<bool> requestUtilitySpend(String resource) async {
    if (!currentCombatIsActive()) return true;
    final tag = sheetTagAt(schedaCorrente);
    final freeReaction = const {'azione', 'reazione'}.contains(resource)
        ? onlineCombatRequests.entries
              .where(
                (entry) =>
                    entry.value['targetTag'] == tag &&
                    entry.value['freeReaction'] == true &&
                    entry.value['reactionUsed'] != true,
              )
              .firstOrNull
        : null;
    final selectedResource = freeReaction?.key ?? resource;
    if (!_consumeLocalCombatTurnResource(tag, selectedResource)) return false;
    final spendId =
        '$tag:${DateTime.now().microsecondsSinceEpoch}:${pendingOnlineCombatTurnResourceSpends.length}';
    appliedOnlineCombatTurnResourceSpendIds.add(spendId);
    if (realtimeService?.isConnected == true) {
      pendingOnlineCombatTurnResourceSpends.add({
        'id': spendId,
        'sheetTag': tag,
        'resource': selectedResource,
      });
      if (pendingOnlineCombatTurnResourceSpends.length > 16) {
        pendingOnlineCombatTurnResourceSpends.removeAt(0);
      }
    }
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
    return true;
  }

  bool get _usesLocalMasterInitiative => realtimeService?.isConnected == true
      ? realtimeIsMasterRole
      : modalitaMaster || isMasterHost || sonoCoMaster;

  List<Map<String, dynamic>> _writableOnlineCombatTokens() {
    final raw = _usesLocalMasterInitiative
        ? masterInitiativeTokens
        : realtimeVisibleInitiativeSnapshot['tokens'];
    if (raw is! List) return [];
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < raw.length; i++) {
      final value = raw[i];
      if (value is Map<String, dynamic>) {
        result.add(value);
      } else if (value is Map) {
        final mutable = Map<String, dynamic>.from(value);
        raw[i] = mutable;
        result.add(mutable);
      }
    }
    return result;
  }

  int _onlineCombatRound() => _usesLocalMasterInitiative
      ? masterInitiativeRound
      : readIntValue(realtimeVisibleInitiativeSnapshot['round']);

  String _onlineCombatTurnKey(
    List<Map<String, dynamic>> tokens,
    int activeIndex,
    int round,
  ) => '$round';

  bool _consumeLocalCombatTurnResource(
    String tag,
    String resource, {
    bool advanceMasterTurn = true,
    String? requestId,
    int amount = 0,
  }) {
    final freeReaction = onlineCombatRequests[resource];
    if (freeReaction != null &&
        freeReaction['targetTag'] == tag &&
        freeReaction['freeReaction'] == true &&
        freeReaction['reactionUsed'] != true) {
      freeReaction['reactionUsed'] = true;
      final tokens = _writableOnlineCombatTokens();
      final index = tokens.indexWhere(
        (token) =>
            (_usesLocalMasterInitiative
                ? publicInitiativeSourceTag(token)
                : '${token['sheetTag'] ?? token['id'] ?? ''}') ==
            tag,
      );
      if (index >= 0) {
        tokens[index]['freeReactionUsed'] = true;
        tokens[index]['freeReactionUsedRound'] = _onlineCombatRound();
        tokens[index]['updatedAt'] = DateTime.now().toIso8601String();
      }
      final activeIndex = _usesLocalMasterInitiative
          ? masterInitiativeActiveIndex
          : readIntValue(realtimeVisibleInitiativeSnapshot['activeIndex']);
      final activeName = activeIndex >= 0 && activeIndex < tokens.length
          ? oculumReferenceEncounterTokenName(tokens[activeIndex])
          : 'turno attivo';
      aggiungiLog(
        '[TURNISTICA] Reazione gratuita usata da ${index >= 0 ? oculumReferenceEncounterTokenName(tokens[index]) : tag}; resta il turno di $activeName.',
      );
      if (_usesLocalMasterInitiative) {
        captureActiveMasterInitiativeGroup();
        if (!advanceMasterTurn && requestId != null) {
          final request = onlineCombatRequests[requestId];
          if (request != null) request['masterTurnResourcesApplied'] = true;
        }
      }
      if (mounted) setState(() {});
      return true;
    }
    final tokens = _writableOnlineCombatTokens();
    final index = tokens.indexWhere(
      (token) =>
          (_usesLocalMasterInitiative
              ? publicInitiativeSourceTag(token)
              : '${token['sheetTag'] ?? token['id'] ?? ''}') ==
          tag,
    );
    if (index < 0) return false;
    final token = tokens[index];
    if (const {'dead', 'fled', 'expired'}.contains(token['status']) ||
        masterInitiativeTokenIsTemporary(token)) {
      return false;
    }
    final activeIndex = _usesLocalMasterInitiative
        ? masterInitiativeActiveIndex
        : readIntValue(realtimeVisibleInitiativeSnapshot['activeIndex']);
    final round = _onlineCombatRound();
    final turnKey = _onlineCombatTurnKey(tokens, activeIndex, round);
    var usedFastReaction = false;
    if (resource == 'azione') {
      if (index != activeIndex ||
          readBoolValue(token['actionUsed']) ||
          artDebtForToken(token, 'action') > 0) {
        return false;
      }
      token['actionUsed'] = true;
    } else if (resource == 'reazione' || resource == 'reazione_veloce') {
      if (artDebtForToken(token, 'reaction') > 0) return false;
      final normalUsed = masterInitiativeReactionUsed(token, round: round);
      final fastMax = masterInitiativeFastReactionMax(token);
      final fastUsed = masterInitiativeFastReactionUsedThisTurn(
        token,
        turnKey: turnKey,
      );
      final normalAvailable = masterInitiativeNormalReactionRemaining(
        token,
        round: round,
      );
      final canUseNormal = normalAvailable > 0;
      final canUseFast = fastUsed < fastMax;
      if ((resource == 'reazione' && canUseNormal) ||
          (resource == 'reazione' && !canUseNormal && canUseFast)) {
        if (canUseNormal) {
          token['reactionUsed'] = normalUsed + 1;
          token['reactionUsedRound'] = round;
        } else {
          token['reactionFastUsed'] = fastUsed + 1;
          token['reactionFastTurnKey'] = turnKey;
          usedFastReaction = true;
        }
      } else if (resource == 'reazione_veloce' && canUseFast) {
        token['reactionFastUsed'] = fastUsed + 1;
        token['reactionFastTurnKey'] = turnKey;
        usedFastReaction = true;
      } else {
        return false;
      }
    } else if (resource == 'reaction_roll_bonus') {
      final currentBonus = readIntValue(
        token['pendingReactionRollBonus'],
      ).clamp(0, 12);
      final consumed = min(max(0, amount), currentBonus);
      if (consumed <= 0) return false;
      token['pendingReactionRollBonus'] = currentBonus - consumed;
      token['reactionRollBonusUpdatedAt'] = DateTime.now().toIso8601String();
    } else {
      return false;
    }
    token['updatedAt'] = DateTime.now().toIso8601String();
    final tokenName = oculumReferenceEncounterTokenName(token);
    if (resource == 'azione') {
      aggiungiLog('[TURNISTICA] Azione usata da $tokenName.');
    } else if (resource == 'reaction_roll_bonus') {
      aggiungiLog(
        '[TURNISTICA] Bonus di reazioni inutilizzate consumato da $tokenName.',
      );
    } else {
      final activeName = activeIndex >= 0 && activeIndex < tokens.length
          ? oculumReferenceEncounterTokenName(tokens[activeIndex])
          : 'turno attivo';
      aggiungiLog(
        '[TURNISTICA] Reazione ${usedFastReaction ? 'veloce ' : 'normale '}usata da $tokenName; resta il turno di $activeName.',
      );
    }
    if (_usesLocalMasterInitiative) captureActiveMasterInitiativeGroup();
    if (mounted) setState(() {});
    if (resource == 'azione' && _usesLocalMasterInitiative) {
      if (advanceMasterTurn) {
        advanceMasterInitiativeAfterAction(tag);
      } else {
        final request = requestId == null
            ? null
            : onlineCombatRequests[requestId];
        if (request != null) {
          request['masterActionResourceApplied'] = true;
          request['masterActionResourceTag'] = tag;
          request['masterTurnResourcesApplied'] = true;
        }
      }
    } else if (_usesLocalMasterInitiative &&
        !advanceMasterTurn &&
        requestId != null) {
      final request = onlineCombatRequests[requestId];
      if (request != null) request['masterTurnResourcesApplied'] = true;
    }
    return true;
  }

  int consumePendingReactionRollBonus() {
    final tag = sheetTagAt(schedaCorrente);
    if (tag.isEmpty) return 0;
    final tokens = _writableOnlineCombatTokens();
    final index = tokens.indexWhere(
      (token) =>
          (_usesLocalMasterInitiative
              ? publicInitiativeSourceTag(token)
              : '${token['sheetTag'] ?? token['id'] ?? ''}') ==
          tag,
    );
    if (index < 0) return 0;
    final token = tokens[index];
    final bonus = readIntValue(token['pendingReactionRollBonus']).clamp(0, 12);
    if (bonus <= 0) return 0;
    token['pendingReactionRollBonus'] = 0;
    token['reactionRollBonusUpdatedAt'] = DateTime.now().toIso8601String();
    token['updatedAt'] = DateTime.now().toIso8601String();
    if (_usesLocalMasterInitiative) {
      captureActiveMasterInitiativeGroup();
      sendRealtimeInitiativeSnapshotIfPublished();
    } else if (realtimeService?.isConnected == true) {
      final spendId =
          '$tag:reaction-roll-bonus:${DateTime.now().microsecondsSinceEpoch}';
      appliedOnlineCombatTurnResourceSpendIds.add(spendId);
      pendingOnlineCombatTurnResourceSpends.add({
        'id': spendId,
        'sheetTag': tag,
        'resource': 'reaction_roll_bonus',
        'amount': bonus,
      });
      if (pendingOnlineCombatTurnResourceSpends.length > 16) {
        pendingOnlineCombatTurnResourceSpends.removeAt(0);
      }
      unawaited(flushPendingCombatTurnResources().catchError((Object _) {}));
    }
    aggiungiLog(
      '[TURNISTICA] Bonus di reazioni inutilizzate +$bonus applicato a questo tiro; bonus in attesa azzerato.',
    );
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
    return bonus;
  }

  void attachPendingCombatTurnResources(Map<String, dynamic> payload) {
    if (payload['turnResourceSpends'] is List) return;
    final senderTag = sheetTagAt(schedaCorrente);
    final matched = pendingOnlineCombatTurnResourceSpends
        .where((spend) => spend['sheetTag'] == senderTag)
        .toList();
    if (matched.isEmpty) return;
    payload['turnResourceSpends'] = matched
        .map((spend) => Map<String, dynamic>.from(spend))
        .toList();
    pendingOnlineCombatTurnResourceSpends.removeWhere(matched.contains);
  }

  Future<void> flushPendingCombatTurnResources() async {
    if (realtimeService?.isConnected != true ||
        pendingOnlineCombatTurnResourceSpends.isEmpty) {
      return;
    }
    final tag = sheetTagAt(schedaCorrente);
    final request = <String, dynamic>{
      'id': 'turn-resource:$tag:${DateTime.now().microsecondsSinceEpoch}',
      'kind': 'help',
      'helpMode': 'turn_resource',
      'scope': permissionScope,
      'encounterId': onlineCombatEncounterId,
      'sourceTag': tag,
      'targetTag': tag,
      'sourceName': realtimeDisplayName(),
      'helpBonus': 0,
    };
    attachPendingCombatTurnResources(request);
    if (request['turnResourceSpends'] is List) {
      await realtimeService!.sendCombatEvent(
        'combat_help',
        permissionEnvelope(request),
      );
    }
  }

  bool _applyIncomingCombatTurnResources(
    String event,
    Map<String, dynamic> payload,
  ) {
    if (payload['turnResourceSpends'] is! List) return true;
    final senderTag = normalizeOculumFriendTag('${payload['senderTag'] ?? ''}');
    final requestId = '${payload['id'] ?? ''}';
    if (senderTag.isEmpty || requestId.isEmpty) return false;
    final master = realtimeIsMasterRole;
    final eventMarker = '${event}TurnResourceSpendIds';
    final request = onlineCombatRequests.putIfAbsent(
      requestId,
      () => {
        ...payload,
        'id': requestId,
        'status': event == 'combat_help' ? 'resolved' : 'pending',
      },
    );
    final seen = request[eventMarker] is List
        ? List<String>.from(
            (request[eventMarker] as List).map((value) => '$value'),
          )
        : <String>[];
    for (final raw in (payload['turnResourceSpends'] as List).take(16)) {
      if (raw is! Map) continue;
      final spend = Map<String, dynamic>.from(raw);
      final spendId = '${spend['id'] ?? ''}';
      final spendTag = normalizeOculumFriendTag('${spend['sheetTag'] ?? ''}');
      final resource = '${spend['resource'] ?? ''}';
      final amount = readIntValue(spend['amount']);
      if (spendId.isEmpty || spendTag != senderTag || resource.isEmpty) {
        continue;
      }
      if (seen.contains(spendId) ||
          appliedOnlineCombatTurnResourceSpendIds.contains(spendId)) {
        seen.add(spendId);
        continue;
      }
      if (master) {
        final applied = _consumeLocalCombatTurnResource(
          spendTag,
          resource,
          advanceMasterTurn: false,
          requestId: requestId,
          amount: amount,
        );
        if (applied) request['masterTurnResourcesApplied'] = true;
      } else {
        // Other profiles mirror the already-authorized combat event into
        // their local initiative view without another backend write.
        _consumeLocalCombatTurnResource(spendTag, resource, amount: amount);
      }
      appliedOnlineCombatTurnResourceSpendIds.add(spendId);
      seen.add(spendId);
    }
    request[eventMarker] = seen.take(32).toList();
    if (master) programmaSalvataggio();
    return true;
  }

  Future<bool> spendCombatRollResource({bool forceReaction = false}) async {
    if (!currentCombatIsActive()) return true;
    if (realtimeService?.isConnected != true && !_usesLocalMasterInitiative) {
      return true;
    }
    final tokens = _writableOnlineCombatTokens();
    final index = tokens.indexWhere(
      (token) =>
          (_usesLocalMasterInitiative
              ? publicInitiativeSourceTag(token)
              : onlineCombatTokenTag(token)) ==
          sheetTagAt(schedaCorrente),
    );
    final active = _usesLocalMasterInitiative
        ? masterInitiativeActiveIndex
        : readIntValue(realtimeVisibleInitiativeSnapshot['activeIndex']);
    final useAction =
        !forceReaction &&
        index >= 0 &&
        index == active &&
        !readBoolValue(tokens[index]['actionUsed']);
    final freeReaction = onlineCombatRequests.entries
        .where(
          (entry) =>
              entry.value['targetTag'] == sheetTagAt(schedaCorrente) &&
              entry.value['freeReaction'] == true &&
              entry.value['reactionUsed'] != true,
        )
        .firstOrNull;
    final resource = freeReaction != null
        ? freeReaction.key
        : useAction
        ? 'azione'
        : 'reazione';
    final allowed = await requestUtilitySpend(
      resource,
    );
    if (!allowed) {
      aggiungiLog(
        'Tiro non eseguito: non hai un’Azione o una Reazione (anche veloce o gratuita) disponibile.',
      );
    }
    return allowed;
  }

  void receiveUtilitySpend(
    String event,
    Map<String, dynamic> payload, {
    bool local = false,
  }) {
    if (!local &&
        !validPermissionSender(
          payload,
          staff: event == 'permission_decision',
        )) {
      return;
    }
    if (payload['scope'] != permissionScope ||
        payload['encounterId'] != onlineCombatEncounterId) {
      return;
    }
    final id = '${payload['id']}';
    final tag = '${payload['sheetTag']}';
    if (event == 'permission_request') {
      if ((!realtimeIsMasterRole && !local) || payload['senderTag'] != tag) {
        return;
      }
      final old = onlinePermissionRequests[id];
      final cached = old?['utilityDecision'];
      Map<String, dynamic> decision;
      if (cached is Map) {
        decision = Map<String, dynamic>.from(cached);
      } else {
        final index = masterInitiativeTokens.indexWhere(
          (t) => publicInitiativeSourceTag(t) == tag,
        );
        var allowed = false;
        if (index >= 0) {
          final token = masterInitiativeTokens[index];
          switch (payload['resource']) {
            case 'azione':
              if (index == masterInitiativeActiveIndex &&
                  masterInitiativeCanToggleAction(index) &&
                  !masterInitiativeActionUsed(token)) {
                token['actionUsed'] = true;
                allowed = true;
              }
              break;
            case 'reazione':
              allowed = consumeMasterReactionForSheetTag(tag);
              break;
            case 'reazione_veloce':
              if (masterInitiativeTokenCanAct(token) &&
                  masterInitiativeFastReactionMax(token) >
                      masterInitiativeFastReactionUsedThisTurn(token)) {
                token['reactionFastUsed'] =
                    masterInitiativeFastReactionUsedThisTurn(token) + 1;
                token['reactionFastTurnKey'] = masterInitiativeTurnKey();
                allowed = true;
              }
              break;
            default:
              final reaction = onlineCombatRequests['${payload['resource']}'];
              if (reaction?['targetTag'] == tag &&
                  reaction?['freeReaction'] == true &&
                  reaction?['reactionUsed'] != true) {
                reaction!['reactionUsed'] = true;
                allowed = true;
              }
          }
        }
        decision = {
          ...payload,
          'status': allowed ? 'approved' : 'rejected',
          if (index >= 0)
            'turnState': {
              for (final key in [
                'actionUsed',
                'reactionUsed',
                'reactionUsedRound',
                'reactionFastUsed',
                'reactionFastTurnKey',
                'reactionPoolInitialized',
                'reactionPoolRound',
                'reactionNormalFirstRoundLocked',
                'actionTurnRound',
                'pendingReactionRollBonus',
              ])
                key: masterInitiativeTokens[index][key],
            },
        };
        onlinePermissionRequests[id] = {
          ...payload,
          'status': decision['status'],
          'utilityDecision': decision,
        };
        programmaSalvataggio();
        sendRealtimeInitiativeSnapshotIfPublished();
      }
      final envelope = permissionEnvelope(decision);
      if (controlsOnlineCombatSheet(tag)) {
        receiveUtilitySpend('permission_decision', envelope, local: true);
      }
      unawaited(
        realtimeService?.sendPermissionEvent('permission_decision', envelope),
      );
    } else if (event == 'permission_decision' &&
        controlsOnlineCombatSheet(tag)) {
      final request = onlinePermissionRequests[id];
      if (request == null ||
          request['redeemed'] == true ||
          request['utilityDecisionApplied'] == true) {
        return;
      }
      request['utilityDecisionApplied'] = true;
      request['status'] = payload['status'];
      final turnState = payload['turnState'];
      if (!realtimeIsMasterRole &&
          payload['status'] == 'approved' &&
          turnState is Map) {
        final ownToken = onlineCombatTokens()
            .where((t) => onlineCombatTokenTag(t) == tag)
            .firstOrNull;
        final rawTokens = realtimeVisibleInitiativeSnapshot['tokens'];
        if (ownToken != null && rawTokens is List) {
          for (final token in rawTokens.whereType<Map>().where(
            (t) => '${t['sheetTag'] ?? t['id']}' == tag,
          )) {
            for (final key in [
              'actionUsed',
              'reactionUsed',
              'reactionUsedRound',
              'reactionFastUsed',
              'reactionFastTurnKey',
              'reactionPoolInitialized',
              'reactionPoolRound',
              'reactionNormalFirstRoundLocked',
              'actionTurnRound',
              'pendingReactionRollBonus',
            ]) {
              if (turnState.containsKey(key)) token[key] = turnState[key];
            }
          }
        }
      }
      final waiter = onlineUtilitySpendWaiters[id];
      if (waiter != null && !waiter.isCompleted) {
        waiter.complete(payload['status'] == 'approved');
      }
      notifyActiveSheetSummaryChanged();
    }
  }

  Future<void> decideMasterRequest(
    Map<String, dynamic> request,
    bool allowed,
  ) async {
    if (!haPermessiMaster ||
        request['status'] != 'pending' ||
        (request['scope'] != permissionScope &&
            !(request['action'] == 'room_join' &&
                request['roomCode'] == realtimeService?.normalizedRoomId))) {
      return;
    }
    final service = realtimeService;
    if (service?.isConnected != true) return;
    if (request['action'] == 'room_join') {
      final succeeded = await service!.decideRoomAccess(
        '${request['userId']}',
        allowed,
      );
      if (succeeded && mounted) {
        onlinePermissionRequests['${request['id']}'] = {
          ...request,
          'status': allowed ? 'approved' : 'rejected',
          'unread': false,
        };
        refreshPermissionUi();
      }
      return;
    }
    final decision = {
      ...request,
      'status': allowed ? 'approved' : 'rejected',
      'unread': false,
      'decidedByTag': sheetTagAt(schedaCorrente),
      'decidedByName': realtimeDisplayName(),
    };
    if (!await service!.sendPermissionEvent(
      'permission_decision',
      permissionEnvelope(decision),
    )) {
      aggiungiLog('Risposta non inviata: richiesta ancora in attesa.');
      return;
    }
    if (!mounted) return;
    // The self broadcast may already have applied this decision.
    if (request['status'] == 'pending' &&
        onlinePermissionRequests[request['id']]?['status'] == 'pending') {
      onlinePermissionRequests['${request['id']}'] = decision;
      if (allowed && request['action'] == 'monster_entry') {
        final index = schedePersonaggio.indexWhere(
          (sheet) =>
              sheet['realtimeSourceSheetTag'] == request['sheetTag'] ||
              sheet['sheetTag'] == request['sheetTag'],
        );
        if (index >= 0) schedePersonaggio[index]['monsterBookApproved'] = true;
      }
      if (allowed && request['action'] == 'encounter_reset') {
        resetMasterInitiativeRound();
      }
      aggiungiLog(
        '${request['requesterName']}: ${request['description']} · ${allowed ? 'consentito' : 'rifiutato'} da ${realtimeDisplayName()}.',
      );
      refreshPermissionUi();
    }
  }

  Widget onlinePermissionButton() => IconButton(
    key: const ValueKey('online_permission_button'),
    tooltip: t('Richieste al Master', 'Master requests'),
    onPressed: showMasterRequests,
    icon: Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.mark_email_unread_outlined, color: tertiaryColor),
        if (currentPermissionRequests.any(
          (request) =>
              request['status'] == 'pending' && request['unread'] == true,
        ))
          const Positioned(
            right: -2,
            top: -2,
            child: Icon(Icons.circle, size: 8, color: Colors.greenAccent),
          ),
      ],
    ),
  );

  Future<void> showMasterRequests() async {
    if (!haPermessiMaster || masterRequestsDialogOpen) return;
    masterRequestsDialogOpen = true;
    for (final request in currentPermissionRequests) {
      request['unread'] = false;
    }
    refreshPermissionUi();
    try {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => Dialog(
          alignment: Alignment.topRight,
          backgroundColor: backgroundBottomColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: tertiaryColor),
          ),
          child: SizedBox(
            width: 440,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * .75,
              ),
              child: ValueListenableBuilder<int>(
                valueListenable: onlinePermissionRevision,
                builder: (_, revision, child) => ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t('Richieste al Master', 'Master requests'),
                            style: TextStyle(
                              color: tertiaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close, color: primaryColor),
                        ),
                      ],
                    ),
                    if (currentPermissionRequests.isEmpty)
                      Text(
                        t('Nessuna richiesta.', 'No requests.'),
                        style: TextStyle(color: primaryColor),
                      ),
                    for (final request
                        in currentPermissionRequests.toList().reversed)
                      gothicPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${request['requesterName']}',
                              style: TextStyle(
                                color: tertiaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${request['description']}',
                              style: TextStyle(color: primaryColor),
                            ),
                            if (request['status'] == 'pending' &&
                                request['action'] == 'sheet_identity_conflict')
                              TextButton(
                                onPressed: () {
                                  request['status'] = 'reviewed';
                                  refreshPermissionUi();
                                },
                                child: Text(t('Ricevuto', 'Acknowledge')),
                              )
                            else if (request['status'] == 'pending')
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        decideMasterRequest(request, true),
                                    child: Text(
                                      request['action'] == 'room_join'
                                          ? t('Ammetti', 'Admit')
                                          : t('Consenti', 'Allow'),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        decideMasterRequest(request, false),
                                    child: Text(t('Rifiuta', 'Reject')),
                                  ),
                                ],
                              )
                            else
                              Text(
                                request['status'] == 'reviewed'
                                    ? t('Segnalazione letta', 'Report read')
                                    : request['status'] == 'approved'
                                    ? t('Consentito', 'Allowed')
                                    : t('Rifiutato', 'Rejected'),
                                style: TextStyle(color: tertiaryColor),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      masterRequestsDialogOpen = false;
    }
  }

  void notifyMasterOfPendingRequest() {
    if (!mounted ||
        !haPermessiMaster ||
        masterRequestsDialogOpen ||
        masterRequestPopupScheduled ||
        !currentPermissionRequests.any(
          (request) =>
              request['status'] == 'pending' && request['unread'] == true,
        )) {
      return;
    }
    masterRequestPopupScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      masterRequestPopupScheduled = false;
      if (!mounted ||
          !haPermessiMaster ||
          masterRequestsDialogOpen ||
          !currentPermissionRequests.any(
            (request) =>
                request['status'] == 'pending' && request['unread'] == true,
          )) {
        return;
      }
      unawaited(showMasterRequests());
    });
  }
}
