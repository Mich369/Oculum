part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

const Set<String> oculumRealtimeMetadataKeys = <String>{
  'id',
  'sheetTag',
  'realtimeSharedSheet',
  'realtimeSourceKey',
  'realtimeSourceSheetTag',
  'realtimeOwnerTag',
  'realtimeOwnerName',
  'realtimeCampaignId',
  'realtimeCampaignName',
  'realtimeSharedAt',
  'realtimeReceivedAt',
  'realtimeLocalSheetTag',
  'realtimeDirtyLocal',
  'realtimeDirtyAt',
  'localUpdatedAt',
  'realtimeRestrictedByMaster',
  'realtimeReadOnlyByMaster',
  'publicTokenSide',
  'publicInitiativeBase',
  'publicInitiativeTotal',
  'publicInitiativeRollHidden',
  'realtimeCoMaster',
  'realtimeShareWithFriends',
};

const Set<String> oculumRealtimeProtectedEmptyFields = <String>{
  'immaginePersonaggioBase64',
  'background',
  'notePersonaggio',
  'textAttachments',
  'inventario',
  'titoli',
  'trattiRazziali',
  'skills',
  'arti',
  'diarioPagine',
};

const Set<String> oculumRealtimeFallbackEditableFields = <String>{
  'nome',
  'tipoScheda',
  'razza',
  'livello',
  'grado',
  'currentHp',
  'hpTemp',
  'scudo',
  'scudoCritico',
  'scudoOculum',
  'scudoOculumMax',
  'currentResilienza',
  'currentVolonta',
  'currentMateria',
  'currentOculum',
  'attaccoRapido',
  'cmRapido',
  'difesaRapida',
  'reazioni',
  'reazioniVeloci',
  'buffMalusRapidi',
  'inventario',
  'titoli',
  'trattiRazziali',
  'skills',
  'notePersonaggio',
  'partyMembri',
  'inMasterParty',
  'masterSideOverride',
};

dynamic oculumRealtimeCloneJsonValue(dynamic value) {
  return jsonDecode(jsonEncode(value));
}

bool oculumRealtimeValueIsEmpty(dynamic value) {
  if (value == null) return true;
  if (value is String) return value.trim().isEmpty;
  if (value is Iterable) return value.isEmpty;
  if (value is Map) return value.isEmpty;
  return false;
}

bool oculumRealtimePatchValueCanApply(
  String key,
  dynamic value,
  Map<String, dynamic> existing, {
  Set<String> allowClearFields = const <String>{},
}) {
  if (oculumRealtimeMetadataKeys.contains(key)) return false;
  if (oculumRealtimeProtectedEmptyFields.contains(key) &&
      !allowClearFields.contains(key) &&
      oculumRealtimeValueIsEmpty(value) &&
      !oculumRealtimeValueIsEmpty(existing[key])) {
    return false;
  }
  return true;
}

Map<String, dynamic> oculumRealtimeBuildSheetPatch(
  Map<String, dynamic> previous,
  Map<String, dynamic> current, {
  Set<String>? onlyKeys,
}) {
  final patch = <String, dynamic>{};
  for (final entry in current.entries) {
    final key = entry.key;
    if (oculumRealtimeMetadataKeys.contains(key)) continue;
    if (onlyKeys != null && !onlyKeys.contains(key)) continue;
    final nextValue = entry.value;
    final previousHasKey = previous.containsKey(key);
    final previousValue = previous[key];
    if (previousHasKey && jsonEncode(previousValue) == jsonEncode(nextValue)) {
      continue;
    }
    patch[key] = oculumRealtimeCloneJsonValue(nextValue);
  }
  return patch;
}

Map<String, dynamic> oculumRealtimeFallbackEditablePatch(
  Map<String, dynamic> current,
) {
  return oculumRealtimeBuildSheetPatch(
    const <String, dynamic>{},
    current,
    onlyKeys: oculumRealtimeFallbackEditableFields,
  );
}

List<String> oculumRealtimeAppliedPatchKeys(
  Map<String, dynamic> existing,
  Map<String, dynamic> patch, {
  Set<String> allowClearFields = const <String>{},
}) {
  final keys = <String>[];
  for (final entry in patch.entries) {
    final key = entry.key;
    if (!oculumRealtimePatchValueCanApply(
      key,
      entry.value,
      existing,
      allowClearFields: allowClearFields,
    )) {
      continue;
    }
    if (jsonEncode(existing[key]) == jsonEncode(entry.value)) continue;
    keys.add(key);
  }
  return keys;
}

Map<String, dynamic> oculumRealtimeMergeSheetPatch(
  Map<String, dynamic> existing,
  Map<String, dynamic> patch, {
  Set<String> allowClearFields = const <String>{},
}) {
  final merged = oculumRealtimeCloneJsonValue(existing) as Map<String, dynamic>;
  for (final entry in patch.entries) {
    final key = entry.key;
    if (!oculumRealtimePatchValueCanApply(
      key,
      entry.value,
      existing,
      allowClearFields: allowClearFields,
    )) {
      continue;
    }
    merged[key] = oculumRealtimeCloneJsonValue(entry.value);
  }
  return merged;
}

extension _OculumRealtimeIntegration on _OculumHomePageState {
  String realtimeDisplayName() {
    final chosen = realtimeNameController.text.trim();
    if (chosen.isNotEmpty) return chosen;

    final sheetName = nomeController.text.trim();
    if (sheetName.isNotEmpty && sheetName != '???') return sheetName;

    return 'Scheda ${schedaCorrente + 1}';
  }

  Future<void> connectRealtimeOculum() async {
    final room = realtimeRoomController.text.trim().isEmpty
        ? 'test'
        : realtimeRoomController.text.trim();
    realtimeRoomController.text = room;
    realtimeMasterClaimId =
        'master_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';

    await realtimeService?.dispose();

    late final OculumRealtimeService service;
    service = OculumRealtimeService(
      roomId: room,
      playerName: realtimeDisplayName(),
      presenceDataProvider: () => <String, dynamic>{
        'role': realtimeLocalRole(),
        'activeSheetTag': sheetTagAt(schedaCorrente),
        'localSheetTags': localOculumTags(),
        'campaignId': activeCampaignId,
        'campaignName': activeCampaignName(),
        'masterClaimId': realtimeMasterClaimId,
      },
      onEvent: (event, payload) {
        if (!mounted || realtimeService != service) return;
        handleRealtimeEvent(event, payload);
      },
      onPresenceChanged: (users) {
        if (!mounted || realtimeService != service) return;
        final blockMaster = realtimeShouldYieldMaster(users);
        setState(() {
          realtimeUsers = users;
          realtimeConnected = service.isConnected;
          realtimeFirstPresenceHandled = true;
          realtimeMasterBlockedByPresence = blockMaster;
          if (blockMaster) {
            realtimeStatus = t(
              'Master gia presente nella stanza: entri come giocatore.',
              'A Master is already in the room: you join as player.',
            );
          }
        });
        if (blockMaster) {
          unawaited(service.refreshPresence());
        }
      },
      onStatusChanged: (status) {
        if (!mounted || realtimeService != service) return;
        setState(() {
          realtimeStatus = status;
          realtimeConnected = service.isConnected;
          realtimeConnecting = false;
        });
      },
    );

    setState(() {
      realtimeService = service;
      realtimeConnecting = true;
      realtimeConnected = false;
      realtimeFirstPresenceHandled = false;
      realtimeMasterBlockedByPresence = false;
      realtimeUsers = [];
      realtimeSharedSheets.clear();
      realtimeVisibleInitiativeSnapshot = <String, dynamic>{};
      realtimeCoMasterTags.clear();
      realtimeSeenEventKeys.clear();
      realtimeRoleUpdateTimestamps.clear();
      realtimeStatus = t('Connessione realtime...', 'Connecting realtime...');
    });

    await service.connect();

    if (!mounted || realtimeService != service) return;
    setState(() {
      realtimeConnecting = false;
      realtimeConnected = service.isConnected;
    });

    if (service.isConnected) {
      sendRealtimeSheetPreview();
      sendRealtimeCurrentSheetToStaff();
    }
  }

  Future<void> disconnectRealtimeOculum() async {
    final service = realtimeService;
    setState(() {
      realtimeConnecting = false;
      realtimeConnected = false;
      realtimeFirstPresenceHandled = false;
      realtimeMasterBlockedByPresence = false;
      realtimeMasterClaimId = '';
      realtimeUsers = [];
      realtimeSharedSheets.clear();
      realtimeVisibleInitiativeSnapshot = <String, dynamic>{};
      realtimeCoMasterTags.clear();
      realtimeSeenEventKeys.clear();
      realtimeRoleUpdateTimestamps.clear();
    });

    await service?.disconnect();

    if (!mounted) return;
    setState(() {
      realtimeConnected = false;
      realtimeStatus = t('Realtime disconnesso.', 'Realtime disconnected.');
    });
  }

  void handleRealtimeEvent(String event, Map<String, dynamic> payload) {
    final eventKey =
        '$event|${payload['playerName'] ?? ''}|${payload['sentAt'] ?? ''}|${payload['message'] ?? payload.toString()}';
    if (!realtimeSeenEventKeys.add(eventKey)) return;
    if (realtimeSeenEventKeys.length > 400) {
      realtimeSeenEventKeys.clear();
    }

    var persistRealtimeRemote = false;
    final text = realtimeEventText(event, payload);
    setState(() {
      switch (event) {
        case 'sheet_shared':
          persistRealtimeRemote = receiveRealtimeSharedSheet(payload);
          break;
        case 'initiative_shared':
          receiveRealtimeInitiativeSnapshot(payload);
          break;
        case 'friend_request':
          persistRealtimeRemote = registerIncomingOculumFriendRequest(payload);
          break;
        case 'friend_response':
          persistRealtimeRemote = registerIncomingOculumFriendResponse(payload);
          break;
        case 'role_update':
          applyRealtimeRoleUpdate(payload);
          break;
      }

      realtimeEvents.insert(0, text);
      if (realtimeEvents.length > 30) {
        realtimeEvents.removeRange(30, realtimeEvents.length);
      }

      if (event == 'party_log') {
        aggiungiLog('[Realtime] $text');
      }
    });

    if (persistRealtimeRemote) {
      applyingRealtimeRemoteSheet = true;
      unawaited(
        salvaDatiSoloLocale().whenComplete(() {
          applyingRealtimeRemoteSheet = false;
        }),
      );
    }
  }

  String realtimeEventText(String event, Map<String, dynamic> payload) {
    final player = '${payload['playerName'] ?? '???'}';

    switch (event) {
      case 'hp_changed':
        return '$player HP ${payload['currentHp'] ?? '?'}'
            '/${payload['maxHp'] ?? '?'}'
            ' • Temp ${payload['tempHp'] ?? 0}'
            ' • Scudo ${payload['shield'] ?? 0}';
      case 'oculum_changed':
        return '$player Oculum ${payload['currentOculum'] ?? '?'}'
            '/${payload['maxOculum'] ?? '?'}';
      case 'dice_roll':
        return '$player ${payload['label'] ?? 'tiro'}: '
            '${payload['roll'] ?? '?'}'
            '${readIntValue(payload['bonus']) == 0 ? '' : ' + ${payload['bonus']}'}'
            ' = ${payload['total'] ?? '?'}';
      case 'party_log':
        return '$player: ${payload['message'] ?? ''}';
      case 'sheet_ping':
        return '$player ping';
      case 'sheet_sync_preview':
        final state = payload['smallState'];
        return state is Map
            ? '$player preview: HP ${state['hp'] ?? '?'} • Oculum ${state['oculum'] ?? '?'} • Lv ${state['level'] ?? '?'} • Gr ${state['grade'] ?? '?'}'
            : '$player preview ricevuta';
      case 'sheet_shared':
        return t(
          '$player ha condiviso ${payload['sheetName'] ?? 'una scheda'} da ${payload['campaignName'] ?? 'campagna online'}.',
          '$player shared ${payload['sheetName'] ?? 'a sheet'} from ${payload['campaignName'] ?? 'online campaign'}.',
        );
      case 'initiative_shared':
        if (readBoolValue(payload['closed'])) {
          return t(
            '$player ha chiuso la Fight visibile.',
            '$player closed the visible Fight.',
          );
        }
        final snapshotRaw = payload['snapshot'];
        final snapshot = snapshotRaw is Map ? snapshotRaw : const {};
        return t(
          '$player ha inviato la Fight - Round ${snapshot['round'] ?? '?'} - Turni ${snapshot['turnCount'] ?? '?'}.',
          '$player sent the Fight - Round ${snapshot['round'] ?? '?'} - Turns ${snapshot['turnCount'] ?? '?'}.',
        );
      case 'friend_request':
        return t(
          '${payload['requesterName'] ?? player} ti ha inviato una richiesta amicizia.',
          '${payload['requesterName'] ?? player} sent you a friend request.',
        );
      case 'friend_response':
        final status = '${payload['status'] ?? ''}';
        return t(
          '$player risposta amicizia: $status.',
          '$player friend response: $status.',
        );
      case 'role_update':
        final targetName =
            '${payload['targetName'] ?? payload['targetTag'] ?? '???'}';
        final coMaster = readBoolValue(payload['coMaster']);
        return t(
          '$player ${coMaster ? 'nomina' : 'revoca'} Co-Master: $targetName.',
          '$player ${coMaster ? 'promotes' : 'revokes'} Co-Master: $targetName.',
        );
      default:
        return '$player $event';
    }
  }

  void sendRealtimeHpChanged() {
    final service = realtimeService;
    if (service?.isConnected != true) return;

    unawaited(
      service!.sendHpChanged(
        currentHp: hpCorrenti(),
        maxHp: maxHp(),
        tempHp: hpTemp(),
        shield: scudo(),
      ),
    );
  }

  void scheduleRealtimeOculumChanged() {
    if (realtimeService?.isConnected != true) return;

    realtimeOculumDebounceTimer?.cancel();
    realtimeOculumDebounceTimer = Timer(
      const Duration(milliseconds: 450),
      sendRealtimeOculumChanged,
    );
  }

  void sendRealtimeOculumChanged() {
    final service = realtimeService;
    if (service?.isConnected != true) return;

    unawaited(
      service!.sendOculumChanged(
        currentOculum: oculumTotale(),
        maxOculum: oculumMassimo(),
      ),
    );
  }

  void sendRealtimeDiceRoll({
    required String label,
    required int roll,
    required int bonus,
    required int total,
    bool forceMasterVisible = false,
  }) {
    final service = realtimeService;
    if (service?.isConnected != true) return;
    if ((modalitaMaster || isMasterHost) &&
        !forceMasterVisible &&
        (!masterPublicDiceVisible || masterAskPublicDiceConfirmation)) {
      return;
    }

    unawaited(
      service!.sendDiceRoll(
        label: label,
        roll: roll,
        bonus: bonus,
        total: total,
      ),
    );
  }

  void sendRealtimeSheetPreview() {
    final service = realtimeService;
    if (service?.isConnected != true) return;

    unawaited(
      service!.sendSheetSyncPreview(<String, dynamic>{
        'hp': '${hpCorrenti()}/${maxHp()}',
        'oculum': '${oculumTotale()}/${oculumMassimo()}',
        'level': livelloController.text,
        'grade': gradoController.text,
      }),
    );
  }

  void sendRealtimePing() {
    final service = realtimeService;
    if (service?.isConnected != true) return;

    unawaited(service!.sendPing());
    setState(() {
      realtimeEvents.insert(0, t('Ping inviato.', 'Ping sent.'));
    });
  }

  void sendRealtimeTestLog() {
    final service = realtimeService;
    if (service?.isConnected != true) return;

    final message = t(
      'Log test da ${realtimeDisplayName()}',
      'Test log from ${realtimeDisplayName()}',
    );
    unawaited(service!.sendPartyLog(message));
    setState(() {
      realtimeEvents.insert(0, t('Log test inviato.', 'Test log sent.'));
    });
  }

  bool get realtimeWantsMasterRole => modalitaMaster || isMasterHost;

  bool get realtimeIsMasterRole =>
      realtimeWantsMasterRole && !realtimeMasterBlockedByPresence;

  bool get realtimeIsCoMasterRole => !realtimeIsMasterRole && sonoCoMaster;

  bool get realtimeCanBrowseOtherSheets =>
      realtimeIsMasterRole || realtimeIsCoMasterRole;

  String realtimeLocalRole() {
    if (realtimeIsMasterRole) return 'master';
    if (realtimeIsCoMasterRole) return 'coMaster';
    return 'player';
  }

  bool get canShareRealtimeSheetToStaff {
    return realtimeService?.isConnected == true && !realtimeIsMasterRole;
  }

  bool canReceiveRealtimeSheetFrom(
    String senderRole, {
    String targetAudience = '',
    List<String> targetTags = const <String>[],
    String ownerTag = '',
  }) {
    final localRole = realtimeLocalRole();
    if (senderRole == 'player') {
      return localRole == 'master' || localRole == 'coMaster';
    }
    if (senderRole == 'coMaster') {
      return localRole == 'master';
    }
    if (senderRole == 'master') {
      return localRole != 'master' &&
          (targetAudience == 'players_enemy_tokens' ||
              targetAudience == 'players_party_full');
    }
    if (senderRole == 'sheetEdit') {
      return targetTags.any(
        (tag) => localOculumTags()
            .map((localTag) => localTag.toUpperCase())
            .contains(tag.toUpperCase()),
      );
    }
    if (senderRole == 'friend') {
      return (localRole == 'master' || localRole == 'coMaster') &&
          targetTags.any(
            (tag) => localOculumTags()
                .map((localTag) => localTag.toUpperCase())
                .contains(tag.toUpperCase()),
          ) &&
          isOculumFriendSaved(ownerTag);
    }
    return false;
  }

  Map<String, dynamic> realtimeSafeSheetJson(
    Map<String, dynamic> source, {
    bool includeImage = false,
  }) {
    final safe = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;

    for (final key in const <String>[
      'relayServerUrl',
      'relayRoomCode',
      'connectedMasterIp',
      'oculumFriends',
      'campaigns',
      'amiciOculum',
      'oculumFriendRequests',
      'oculumSentFriendRequests',
      'blockedOculumFriends',
      'realtimeRevokedAccessTags',
    ]) {
      safe.remove(key);
    }

    if (!includeImage) {
      safe['immaginePersonaggioBase64'] = '';
    }
    safe['logEventi'] = <String>[];
    safe['partyMembri'] = <Map<String, dynamic>>[];
    return safe;
  }

  Map<String, dynamic> realtimePublicSheetJsonAt(int index) {
    final base = sheetRollBonusAt(index, 'iniziativa');
    final tag = sheetTagAt(index);
    final token = masterInitiativeTokens.firstWhere(
      (item) => '${item['sheetTag'] ?? ''}' == tag,
      orElse: () => <String, dynamic>{},
    );

    return <String, dynamic>{
      'nome': nomeSchedaPersonaggio(index),
      'tipoScheda': tipoSchedaPersonaggio(index),
      'id': tag,
      'sheetTag': tag,
      'immaginePersonaggioBase64': sheetImageBase64At(index),
      'inMasterParty': sheetInMasterPartyAt(index),
      'realtimeRestrictedByMaster': true,
      'publicTokenSide': sheetSideAt(index),
      'publicInitiativeBase': base,
      'publicInitiativeTotal': readIntValue(token['initiativeTotal']),
      'publicInitiativeRollHidden': token.isNotEmpty,
    };
  }

  String realtimeSharedSheetKey({
    required String ownerTag,
    required String campaignId,
    required String sheetId,
  }) {
    return '${ownerTag.trim()}|${campaignId.trim()}|${sheetId.trim()}';
  }

  int realtimeLocalSheetIndexForKey(String key) {
    return schedePersonaggio.indexWhere(
      (sheet) => '${sheet['realtimeSourceKey'] ?? ''}' == key,
    );
  }

  int realtimeSharedSheetIndexForKey(String key) {
    return realtimeSharedSheets.indexWhere(
      (sheet) => '${sheet['key'] ?? ''}' == key,
    );
  }

  DateTime? realtimeIsoDate(dynamic value) {
    final raw = '$value'.trim();
    if (raw.isEmpty || raw == 'null') return null;
    return DateTime.tryParse(raw);
  }

  bool realtimeRemoteIsStaleForLocal(
    Map<String, dynamic> existing,
    Map<String, dynamic> payload,
  ) {
    final remoteSheet = payload['sheet'];
    final remoteAt =
        realtimeIsoDate(payload['sentAt']) ??
        (remoteSheet is Map
            ? realtimeIsoDate(remoteSheet['localUpdatedAt'])
            : null);
    final localGuard =
        realtimeIsoDate(existing['realtimeDirtyAt']) ??
        realtimeIsoDate(existing['localUpdatedAt']);
    if (remoteAt == null || localGuard == null) return false;
    return !remoteAt.isAfter(localGuard);
  }

  bool realtimePayloadIsStaleForRecord(
    Map<String, dynamic> existingRecord,
    Map<String, dynamic> payload,
  ) {
    final remoteAt = realtimeIsoDate(payload['sentAt']);
    final existingAt = realtimeIsoDate(existingRecord['sentAt']);
    if (remoteAt == null || existingAt == null) return false;
    return !remoteAt.isAfter(existingAt);
  }

  Map<String, dynamic> prepareRealtimeSheetForLocal(
    Map<String, dynamic> record, {
    int? existingIndex,
  }) {
    final sheetRaw = record['sheet'];
    final sheet = sheetRaw is Map
        ? jsonDecode(jsonEncode(sheetRaw)) as Map<String, dynamic>
        : <String, dynamic>{};

    final key = '${record['key'] ?? ''}';
    final sourceTag = normalizeOculumFriendTag('${record['sheetId'] ?? ''}');
    final usedTags = <String>{};
    for (int i = 0; i < schedePersonaggio.length; i++) {
      if (i == existingIndex) continue;
      usedTags.add('${schedePersonaggio[i]['sheetTag'] ?? ''}'.toUpperCase());
    }

    var localTag = existingIndex != null
        ? normalizeOculumFriendTag(
            '${schedePersonaggio[existingIndex]['sheetTag'] ?? ''}',
          )
        : normalizeOculumFriendTag('${sheet['sheetTag'] ?? sourceTag}');

    if (localTag.isEmpty || usedTags.contains(localTag.toUpperCase())) {
      localTag = generaTagUnicoScheda(schedePersonaggio.length, usedTags);
    }

    sheet['id'] = localTag;
    sheet['sheetTag'] = localTag;
    sheet['inMasterParty'] = existingIndex != null
        ? readBoolValue(schedePersonaggio[existingIndex]['inMasterParty'])
        : false;
    sheet['realtimeSharedSheet'] = true;
    sheet['realtimeSourceKey'] = key;
    sheet['realtimeSourceSheetTag'] = sourceTag;
    sheet['realtimeOwnerTag'] = '${record['ownerTag'] ?? ''}';
    sheet['realtimeOwnerName'] = '${record['ownerName'] ?? ''}';
    sheet['realtimeCampaignId'] = '${record['campaignId'] ?? ''}';
    sheet['realtimeCampaignName'] = '${record['campaignName'] ?? ''}';
    sheet['realtimeSharedAt'] = '${record['sentAt'] ?? ''}';
    sheet['realtimeReceivedAt'] = DateTime.now().toIso8601String();
    sheet['localUpdatedAt'] =
        '${record['sentAt'] ?? DateTime.now().toIso8601String()}';
    sheet['realtimeLocalSheetTag'] = localTag;
    sheet['realtimeCoMaster'] =
        realtimeCoMasterTags.contains(sourceTag.toUpperCase()) ||
        '${record['senderRole'] ?? ''}' == 'coMaster';
    sheet['realtimeDirtyLocal'] = false;
    sheet.remove('realtimeDirtyAt');
    return sheet;
  }

  int localSheetIndexForOculumTag(String tag) {
    final clean = normalizeOculumFriendTag(tag).toUpperCase();
    if (clean.isEmpty) return -1;

    return schedePersonaggio.indexWhere((sheet) {
      final sheetTag = normalizeOculumFriendTag(
        '${sheet['sheetTag'] ?? sheet['id'] ?? ''}',
      ).toUpperCase();
      return sheetTag == clean;
    });
  }

  bool receiveRealtimeSheetEdit(
    Map<String, dynamic> sheet,
    String sheetId,
    Map<String, dynamic> payload,
  ) {
    var localIndex = localSheetIndexForOculumTag(sheetId);
    if (localIndex < 0) {
      final campaignId = '${payload['campaignId'] ?? ''}'.trim().isEmpty
          ? 'online'
          : '${payload['campaignId'] ?? ''}'.trim();
      final key = realtimeSharedSheetKey(
        ownerTag: normalizeOculumFriendTag('${payload['ownerTag'] ?? sheetId}'),
        campaignId: campaignId,
        sheetId: normalizeOculumFriendTag(sheetId),
      );
      localIndex = realtimeLocalSheetIndexForKey(key);
    }
    if (localIndex < 0) return false;

    final existing = Map<String, dynamic>.from(schedePersonaggio[localIndex]);
    final localTag = normalizeOculumFriendTag(
      '${existing['sheetTag'] ?? existing['id'] ?? sheetId}',
    );

    if (realtimeRemoteIsStaleForLocal(existing, payload)) {
      aggiungiLog(
        t(
          'Realtime ignorato: aggiornamento vecchio per ${existing['nome'] ?? '???'}.',
          'Realtime ignored: stale update for ${existing['nome'] ?? '???'}.',
        ),
      );
      return false;
    }

    final allowClearRaw = payload['allowClearFields'];
    final allowClearFields = allowClearRaw is List
        ? allowClearRaw.map((field) => '$field').toSet()
        : const <String>{};
    final appliedKeys = oculumRealtimeAppliedPatchKeys(
      existing,
      sheet,
      allowClearFields: allowClearFields,
    );
    if (appliedKeys.isEmpty) {
      aggiungiLog(
        t(
          'Realtime ignorato: patch vuota o protetta per ${existing['nome'] ?? '???'}.',
          'Realtime ignored: empty or protected patch for ${existing['nome'] ?? '???'}.',
        ),
      );
      return false;
    }

    final updated = oculumRealtimeMergeSheetPatch(
      existing,
      sheet,
      allowClearFields: allowClearFields,
    );

    updated['id'] = localTag;
    updated['sheetTag'] = localTag;
    updated['localUpdatedAt'] =
        '${payload['sentAt'] ?? DateTime.now().toIso8601String()}';
    updated['inMasterParty'] = readBoolValue(existing['inMasterParty']);

    schedePersonaggio[localIndex] = updated;
    if (schedaCorrente == localIndex) {
      if (!applyRealtimePatchToVisibleControllers(updated, appliedKeys)) {
        caricaStatoDaJson(updated);
      }
    }
    aggiungiLog(
      t(
        'Patch online applicata da ${payload['playerName'] ?? 'online'}: ${updated['nome'] ?? '???'} (${appliedKeys.join(', ')}).',
        'Online patch applied by ${payload['playerName'] ?? 'online'}: ${updated['nome'] ?? '???'} (${appliedKeys.join(', ')}).',
      ),
    );
    saveActiveCampaignInMemory();
    if (!realtimeIsMasterRole &&
        !readBoolValue(existing['realtimeSharedSheet'])) {
      sendRealtimeSheetToStaffAt(localIndex);
    }
    return true;
  }

  bool applyRealtimePatchToVisibleControllers(
    Map<String, dynamic> updated,
    List<String> changedKeys,
  ) {
    final controllers = <String, TextEditingController>{
      'currentHp': currentHpController,
      'hpTemp': hpTempController,
      'scudo': scudoController,
      'scudoCritico': scudoCriticoController,
      'scudoOculum': scudoOculumController,
      'scudoOculumMax': scudoOculumMaxController,
      'currentResilienza': currentResilienzaController,
      'currentVolonta': currentVolontaController,
      'currentMateria': currentMateriaController,
      'currentOculum': currentOculumController,
      'attaccoRapido': attaccoRapidoController,
      'cmRapido': cmRapidoController,
      'difesaRapida': difesaRapidaController,
      'reazioni': reazioniController,
      'reazioniVeloci': reazioniVelociController,
      'buffMalusRapidi': buffMalusRapidiController,
    };
    if (!changedKeys.every(controllers.containsKey)) return false;
    for (final key in changedKeys) {
      controllers[key]!.text = '${updated[key] ?? ''}';
    }
    return true;
  }

  void applyRealtimeRoleUpdate(Map<String, dynamic> payload) {
    final targetTag = normalizeOculumFriendTag('${payload['targetTag'] ?? ''}');
    if (targetTag.isEmpty) return;

    final matchesLocal = localOculumTags()
        .map((tag) => tag.toUpperCase())
        .contains(targetTag.toUpperCase());
    if (!matchesLocal) return;

    final targetKey = targetTag.toUpperCase();
    final sentAt = realtimeIsoDate(payload['sentAt']) ?? DateTime.now();
    final previousSentAt = realtimeRoleUpdateTimestamps[targetKey];
    if (previousSentAt != null && !sentAt.isAfter(previousSentAt)) {
      return;
    }
    realtimeRoleUpdateTimestamps[targetKey] = sentAt;

    final coMaster = readBoolValue(payload['coMaster']);
    sonoCoMaster = coMaster;
    if (coMaster && realtimeWantsMasterRole) {
      realtimeMasterBlockedByPresence = realtimeShouldYieldMaster(
        realtimeUsers,
      );
    }
    risultato = coMaster
        ? t(
            'Sei stato nominato Co-Master in ${payload['campaignName'] ?? 'campagna online'}.',
            'You have been promoted to Co-Master in ${payload['campaignName'] ?? 'online campaign'}.',
          )
        : t(
            'Il ruolo Co-Master e stato revocato.',
            'The Co-Master role has been revoked.',
          );
    aggiungiLog(risultato);
    unawaited(realtimeService?.refreshPresence());
    unawaited(salvaDatiSoloLocale());
  }

  bool realtimeShouldYieldMaster(List<Map<String, dynamic>> users) {
    if (!realtimeWantsMasterRole) return false;
    if (realtimeMasterClaimId.isEmpty) return false;

    final otherClaims = users
        .where((user) => '${user['role'] ?? ''}' == 'master')
        .map((user) => '${user['masterClaimId'] ?? ''}')
        .where((claim) => claim.isNotEmpty)
        .toList();
    if (otherClaims.isEmpty) return false;

    otherClaims.sort();
    return otherClaims.first.compareTo(realtimeMasterClaimId) < 0;
  }

  Map<String, dynamic> buildRealtimeInitiativeSnapshot() {
    normalizeMasterInitiativeTokens();
    final safeActive = masterInitiativeTokens.isEmpty
        ? 0
        : masterInitiativeActiveIndex
              .clamp(0, masterInitiativeTokens.length - 1)
              .toInt();

    return <String, dynamic>{
      'campaignId': activeCampaignId,
      'campaignName': activeCampaignName(),
      'round': masterInitiativeRound,
      'activeIndex': safeActive,
      'turnCount': masterInitiativeTokens.length,
      'manualOrder': masterInitiativeManualOrder,
      'sentAt': DateTime.now().toIso8601String(),
      'tokens': [
        for (int i = 0; i < masterInitiativeTokens.length; i++)
          <String, dynamic>{
            'index': i + 1,
            'turnNumber': i + 1,
            'turnCount': masterInitiativeTokens.length,
            'id': '${masterInitiativeTokens[i]['id'] ?? i}',
            'name': '${masterInitiativeTokens[i]['name'] ?? '???'}',
            'type': '${masterInitiativeTokens[i]['type'] ?? 'Partecipante'}',
            'side': '${masterInitiativeTokens[i]['side'] ?? 'ally'}',
            'status': '${masterInitiativeTokens[i]['status'] ?? 'ready'}',
            'imageBase64': '${masterInitiativeTokens[i]['imageBase64'] ?? ''}',
            'initiativeTotal': readIntValue(
              masterInitiativeTokens[i]['initiativeTotal'],
            ),
            'active': i == safeActive,
          },
      ],
    };
  }

  void receiveRealtimeInitiativeSnapshot(Map<String, dynamic> payload) {
    final senderRole = '${payload['senderRole'] ?? ''}';
    if (realtimeIsMasterRole || senderRole != 'master') return;

    if (readBoolValue(payload['closed'])) {
      realtimeVisibleInitiativeSnapshot = <String, dynamic>{};
      risultato = t('Fight chiusa dal Master.', 'Fight closed by the Master.');
      aggiungiLog(risultato);
      return;
    }

    final snapshotRaw = payload['snapshot'];
    if (snapshotRaw is! Map) return;
    realtimeVisibleInitiativeSnapshot =
        jsonDecode(jsonEncode(snapshotRaw)) as Map<String, dynamic>;
    risultato = t(
      'Fight aggiornata dal Master.',
      'Fight updated by the Master.',
    );
    aggiungiLog(risultato);
  }

  void sendRealtimeInitiativeSnapshot({bool close = false}) {
    final service = realtimeService;
    if (service?.isConnected != true || !realtimeIsMasterRole) return;

    unawaited(
      service!.sendInitiativeSnapshot(
        snapshot: close
            ? <String, dynamic>{}
            : buildRealtimeInitiativeSnapshot(),
        campaignId: activeCampaignId,
        campaignName: activeCampaignName(),
        closed: close,
      ),
    );
  }

  void publishRealtimeInitiativeSnapshot() {
    if (realtimeService?.isConnected != true || !realtimeIsMasterRole) {
      setState(() {
        risultato = t(
          'Connetti il realtime come Master prima di pubblicare la turnistica.',
          'Connect realtime as Master before publishing turn order.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    setState(() {
      masterInitiativePublished = true;
      risultato = t(
        'Fight pubblicata a player e Co-Master.',
        'Fight published to players and Co-Masters.',
      );
      aggiungiLog(risultato);
    });
    sendRealtimeInitiativeSnapshot();
    programmaSalvataggio();
  }

  void closeRealtimeInitiativeSnapshot() {
    if (realtimeService?.isConnected != true || !realtimeIsMasterRole) {
      setState(() => masterInitiativePublished = false);
      programmaSalvataggio();
      return;
    }

    setState(() {
      masterInitiativePublished = false;
      risultato = t('Fight chiusa per i player.', 'Fight closed for players.');
      aggiungiLog(risultato);
    });
    sendRealtimeInitiativeSnapshot(close: true);
    programmaSalvataggio();
  }

  void sendRealtimeInitiativeSnapshotIfPublished() {
    if (!masterInitiativePublished) return;
    sendRealtimeInitiativeSnapshot();
  }

  bool receiveRealtimeSharedSheet(Map<String, dynamic> payload) {
    final sheetRaw = payload['sheet'];
    if (sheetRaw is! Map) return false;
    final senderRole = '${payload['senderRole'] ?? ''}'.trim().isNotEmpty
        ? '${payload['senderRole']}'.trim()
        : readBoolValue(payload['fromMaster'])
        ? 'master'
        : 'player';
    final targetAudience = '${payload['targetAudience'] ?? ''}';
    final rawTargetTags = payload['targetTags'];
    final targetTags = rawTargetTags is List
        ? rawTargetTags
              .map((tag) => normalizeOculumFriendTag('$tag'))
              .where((tag) => tag.isNotEmpty)
              .toList()
        : <String>[];
    final ownerTag = normalizeOculumFriendTag(
      '${payload['ownerTag'] ?? payload['sheetId'] ?? ''}',
    );
    if (!canReceiveRealtimeSheetFrom(
      senderRole,
      targetAudience: targetAudience,
      targetTags: targetTags,
      ownerTag: ownerTag,
    )) {
      return false;
    }

    final sheet = senderRole == 'sheetEdit'
        ? jsonDecode(jsonEncode(Map<String, dynamic>.from(sheetRaw)))
              as Map<String, dynamic>
        : realtimeSafeSheetJson(
            Map<String, dynamic>.from(sheetRaw),
            includeImage: true,
          );
    final sheetId = normalizeOculumFriendTag(
      '${payload['sheetId'] ?? sheet['sheetTag'] ?? sheet['id'] ?? ''}',
    );
    if (sheetId.isEmpty) return false;

    if (senderRole == 'sheetEdit') {
      return receiveRealtimeSheetEdit(sheet, sheetId, payload);
    }

    if (senderRole == 'master' &&
        targetAudience != 'players_party_full' &&
        !readBoolValue(sheet['realtimeRestrictedByMaster'])) {
      return false;
    }

    final normalizedOwnerTag = normalizeOculumFriendTag(
      '${payload['ownerTag'] ?? sheetId}',
    );
    final campaignId = '${payload['campaignId'] ?? ''}'.trim().isEmpty
        ? 'online'
        : '${payload['campaignId'] ?? ''}'.trim();
    final key = realtimeSharedSheetKey(
      ownerTag: normalizedOwnerTag,
      campaignId: campaignId,
      sheetId: sheetId,
    );
    final record = <String, dynamic>{
      'key': key,
      'ownerName': '${payload['playerName'] ?? '???'}',
      'ownerTag': normalizedOwnerTag,
      'campaignId': campaignId,
      'campaignName': '${payload['campaignName'] ?? 'Online'}',
      'sheetId': sheetId,
      'sheetName': '${payload['sheetName'] ?? sheet['nome'] ?? '???'}',
      'fromMaster': readBoolValue(payload['fromMaster']),
      'masterParty': readBoolValue(payload['masterParty']),
      'senderRole': senderRole,
      'targetAudience': targetAudience,
      'targetTags': targetTags,
      'sentAt': '${payload['sentAt'] ?? DateTime.now().toIso8601String()}',
      'sheet': sheet,
    };

    final remoteIndex = realtimeSharedSheetIndexForKey(key);
    if (remoteIndex >= 0 &&
        realtimePayloadIsStaleForRecord(
          realtimeSharedSheets[remoteIndex],
          payload,
        )) {
      aggiungiLog(
        t(
          'Realtime ignorato: record online vecchio per ${record['sheetName']}.',
          'Realtime ignored: stale online record for ${record['sheetName']}.',
        ),
      );
      return false;
    }
    if (remoteIndex >= 0) {
      realtimeSharedSheets[remoteIndex] = record;
    } else {
      realtimeSharedSheets.add(record);
    }

    final localIndex = realtimeLocalSheetIndexForKey(key);
    if (localIndex < 0) {
      if (senderRole == 'player' ||
          senderRole == 'coMaster' ||
          (senderRole == 'master' &&
              readBoolValue(payload['masterParty']) &&
              !readBoolValue(sheet['realtimeRestrictedByMaster']))) {
        final prepared = prepareRealtimeSheetForLocal(record);
        schedePersonaggio.add(prepared);
        saveActiveCampaignInMemory();
        aggiungiLog(
          t(
            'Scheda online ricevuta: ${record['sheetName']}.',
            'Online sheet received: ${record['sheetName']}.',
          ),
        );
        return true;
      }

      return false;
    }

    final existingLocal = Map<String, dynamic>.from(
      schedePersonaggio[localIndex],
    );

    if (readBoolValue(existingLocal['realtimeDirtyLocal']) &&
        !readBoolValue(existingLocal['realtimeReadOnlyByMaster'])) {
      aggiungiLog(
        t(
          'Realtime ignorato: copia locale modificata per ${existingLocal['nome'] ?? '???'}.',
          'Realtime ignored: local edited copy for ${existingLocal['nome'] ?? '???'}.',
        ),
      );
      return false;
    }

    if (realtimeRemoteIsStaleForLocal(existingLocal, payload)) {
      aggiungiLog(
        t(
          'Realtime ignorato: aggiornamento vecchio per ${existingLocal['nome'] ?? '???'}.',
          'Realtime ignored: stale update for ${existingLocal['nome'] ?? '???'}.',
        ),
      );
      return false;
    }

    final prepared = prepareRealtimeSheetForLocal(
      record,
      existingIndex: localIndex,
    );
    schedePersonaggio[localIndex] = prepared;
    if (schedaCorrente == localIndex) {
      caricaStatoDaJson(prepared);
    }
    aggiungiLog(
      t(
        'Scheda online aggiornata: ${record['sheetName']}.',
        'Online sheet updated: ${record['sheetName']}.',
      ),
    );
    saveActiveCampaignInMemory();
    return true;
  }

  void sendRealtimeMasterPartySheets() {
    sendRealtimeMasterVisiblePartyTokens();
  }

  void sendRealtimeCurrentPartySheet() {
    if (realtimeIsMasterRole) {
      sendRealtimeMasterVisiblePartyTokens();
    } else {
      sendRealtimeCurrentSheetToStaff();
    }
  }

  void sendRealtimeCurrentSheetToStaff() {
    if (!canShareRealtimeSheetToStaff) return;

    realtimeSheetShareDebounceTimer?.cancel();
    realtimeSheetShareDebounceTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || !canShareRealtimeSheetToStaff) return;
      salvaSchedaCorrenteInMemoria();
      sendRealtimeSheetToStaffAt(schedaCorrente);
    });
  }

  bool shouldSendRealtimeSheetHash(String key, Map<String, dynamic> sheet) {
    final hash = jsonEncode(sheet);
    if (realtimeLastSentSheetHashes[key] == hash) return false;
    realtimeLastSentSheetHashes[key] = hash;
    if (realtimeLastSentSheetHashes.length > 80) {
      realtimeLastSentSheetHashes.remove(
        realtimeLastSentSheetHashes.keys.first,
      );
    }
    return true;
  }

  void sendRealtimeCurrentSheetToFriends() {
    sendRealtimeCurrentSheetToFriendsInternal(
      manual: true,
      sheetIndex: schedaCorrente,
    );
  }

  void sendRealtimeCurrentSheetToFriendsIfEnabled() {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return;
    }
    if (!readBoolValue(
      schedePersonaggio[schedaCorrente]['realtimeShareWithFriends'],
    )) {
      return;
    }
    sendRealtimeCurrentSheetToFriendsInternal(
      manual: false,
      sheetIndex: schedaCorrente,
    );
  }

  void sendRealtimeCurrentSheetToFriendsInternal({
    required bool manual,
    required int sheetIndex,
    List<String>? targetTagsOverride,
    String? targetLabel,
  }) {
    final service = realtimeService;
    if (service?.isConnected != true) return;
    if (realtimeIsMasterRole) return;
    if (sheetIndex < 0 || sheetIndex >= schedePersonaggio.length) return;
    if (amiciOculum.isEmpty && targetTagsOverride == null) return;
    if (readBoolValue(schedePersonaggio[sheetIndex]['realtimeSharedSheet'])) {
      return;
    }

    salvaSchedaCorrenteInMemoria();
    schedePersonaggio[sheetIndex]['realtimeShareWithFriends'] = true;
    saveActiveCampaignInMemory();
    final revokedTags = sheetRevokedAccessTagsAt(
      sheetIndex,
    ).map((tag) => tag.toUpperCase()).toSet();
    final targetTags =
        targetTagsOverride ??
        amiciOculum
            .map((friend) => normalizeOculumFriendTag('${friend['tag'] ?? ''}'))
            .where((tag) => tag.isNotEmpty && !isOculumFriendBlocked(tag))
            .toList();
    final allowedTargetTags = targetTags
        .where((tag) => !revokedTags.contains(tag.toUpperCase()))
        .toList();
    if (allowedTargetTags.isEmpty) return;

    final sheet = realtimeSafeSheetJson(
      schedaJsonAt(sheetIndex),
      includeImage: true,
    );
    final sheetId = normalizeOculumFriendTag(
      '${sheet['sheetTag'] ?? sheet['id'] ?? sheetTagAt(sheetIndex)}',
    );
    if (sheetId.isEmpty) return;
    if (!shouldSendRealtimeSheetHash('friend:$sheetId', sheet)) return;

    unawaited(
      service!.sendSharedSheet(
        sheet: sheet,
        campaignId: activeCampaignId,
        campaignName: activeCampaignName(),
        sheetId: sheetId,
        sheetName: nomeSchedaPersonaggio(sheetIndex),
        ownerTag: sheetId,
        senderRole: 'friend',
        targetAudience: 'friends',
        fromMaster: false,
        masterParty: false,
        targetTags: allowedTargetTags,
      ),
    );

    if (manual) {
      setState(() {
        risultato = targetLabel == null
            ? t(
                'Scheda condivisa agli amici online. Le modifiche future verranno reinviate finche Realtime resta connesso.',
                'Sheet shared to online friends. Future edits will be resent while Realtime stays connected.',
              )
            : t(
                'Scheda "${nomeSchedaPersonaggio(sheetIndex)}" condivisa a $targetLabel.',
                'Sheet "${nomeSchedaPersonaggio(sheetIndex)}" shared with $targetLabel.',
              );
        aggiungiLog(risultato);
      });
    }
  }

  void sendRealtimeSharedSheetAt(int index) {
    if (realtimeIsMasterRole) {
      sendRealtimeMasterVisibleTokenAt(index);
    } else {
      sendRealtimeSheetToStaffAt(index);
    }
  }

  void sendRealtimeSheetToStaffAt(int index) {
    final service = realtimeService;
    if (service?.isConnected != true || !canShareRealtimeSheetToStaff) return;
    if (index < 0 || index >= schedePersonaggio.length) return;
    if (readBoolValue(schedePersonaggio[index]['realtimeSharedSheet'])) return;

    salvaSchedaCorrenteInMemoria();
    final role = realtimeLocalRole();
    final sheet = realtimeSafeSheetJson(
      schedaJsonAt(index),
      includeImage: true,
    );
    final sheetId = normalizeOculumFriendTag(
      '${sheet['sheetTag'] ?? sheet['id'] ?? sheetTagAt(index)}',
    );
    if (sheetId.isEmpty) return;
    if (!shouldSendRealtimeSheetHash('staff:$sheetId', sheet)) return;

    unawaited(
      service!.sendSharedSheet(
        sheet: sheet,
        campaignId: activeCampaignId,
        campaignName: activeCampaignName(),
        sheetId: sheetId,
        sheetName: nomeSchedaPersonaggio(index),
        ownerTag: sheetId,
        senderRole: role,
        targetAudience: role == 'coMaster' ? 'master' : 'master_coMaster',
        fromMaster: false,
        masterParty: false,
      ),
    );
  }

  Future<bool> sendRealtimeEditedSharedSheetBack() async {
    final service = realtimeService;
    if (service?.isConnected != true) return false;
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return false;
    }

    final current = schedePersonaggio[schedaCorrente];
    if (!readBoolValue(current['realtimeSharedSheet'])) return false;
    if (!readBoolValue(current['realtimeDirtyLocal'])) return false;
    if (readBoolValue(current['realtimeRestrictedByMaster'])) return false;
    if (readBoolValue(current['realtimeReadOnlyByMaster'])) return false;

    final sourceTag = normalizeOculumFriendTag(
      '${current['realtimeSourceSheetTag'] ?? current['realtimeOwnerTag'] ?? ''}',
    );
    if (sourceTag.isEmpty) return false;

    final fullSheet = realtimeSafeSheetJson(
      schedaJsonAt(schedaCorrente),
      includeImage: true,
    );
    final sourceKey = '${current['realtimeSourceKey'] ?? ''}';
    final sourceRecord = sourceKey.isEmpty
        ? <String, dynamic>{}
        : realtimeSharedSheets.firstWhere(
            (record) => '${record['key'] ?? ''}' == sourceKey,
            orElse: () => <String, dynamic>{},
          );
    final baseRaw = sourceRecord['sheet'];
    final baseSheet = baseRaw is Map
        ? jsonDecode(jsonEncode(baseRaw)) as Map<String, dynamic>
        : <String, dynamic>{};
    final patch = baseSheet.isNotEmpty
        ? oculumRealtimeBuildSheetPatch(baseSheet, fullSheet)
        : oculumRealtimeFallbackEditablePatch(fullSheet);
    patch['id'] = sourceTag;
    patch['sheetTag'] = sourceTag;
    if (oculumRealtimeAppliedPatchKeys(
      baseSheet,
      patch,
      allowClearFields: const <String>{},
    ).isEmpty) {
      return false;
    }
    if (!shouldSendRealtimeSheetHash('edit:$sourceTag', patch)) return false;

    final sent = await service!.sendSharedSheetConfirmed(
      sheet: patch,
      campaignId: '${current['realtimeCampaignId'] ?? activeCampaignId}',
      campaignName:
          '${current['realtimeCampaignName'] ?? activeCampaignName()}',
      sheetId: sourceTag,
      sheetName: nomeSchedaPersonaggio(schedaCorrente),
      ownerTag: sourceTag,
      senderRole: 'sheetEdit',
      targetAudience: 'owner',
      fromMaster: realtimeIsMasterRole,
      masterParty: false,
      targetTags: <String>[sourceTag],
    );
    if (!sent) return false;

    if (sourceRecord.isNotEmpty && baseSheet.isNotEmpty) {
      sourceRecord['sheet'] = oculumRealtimeMergeSheetPatch(baseSheet, patch);
      sourceRecord['sentAt'] = DateTime.now().toIso8601String();
    }
    current['realtimeDirtyLocal'] = false;
    current.remove('realtimeDirtyAt');
    saveActiveCampaignInMemory();
    aggiungiLog(
      t(
        'Modifiche inviate al proprietario della scheda online.',
        'Edits sent to the owner of the online sheet.',
      ),
    );
    return true;
  }

  void setRealtimeCoMasterForRecord(
    Map<String, dynamic> record,
    bool coMaster,
  ) {
    final service = realtimeService;
    final canAssignCoMaster =
        realtimeIsMasterRole ||
        (realtimeIsCoMasterRole && coMasterCanSetCoMaster);
    if (service?.isConnected != true || !canAssignCoMaster) return;

    final targetTag = normalizeOculumFriendTag('${record['sheetId'] ?? ''}');
    if (targetTag.isEmpty) return;
    final targetName =
        '${record['sheetName'] ?? record['ownerName'] ?? targetTag}';

    setState(() {
      if (coMaster) {
        realtimeCoMasterTags.add(targetTag.toUpperCase());
      } else {
        realtimeCoMasterTags.remove(targetTag.toUpperCase());
      }

      final localIndex = realtimeLocalSheetIndexForKey(
        '${record['key'] ?? ''}',
      );
      if (localIndex >= 0) {
        schedePersonaggio[localIndex]['realtimeCoMaster'] = coMaster;
      }
      record['senderRole'] = coMaster ? 'coMaster' : 'player';
      risultato = coMaster
          ? t(
              '$targetName nominato Co-Master.',
              '$targetName promoted to Co-Master.',
            )
          : t(
              'Co-Master revocato a $targetName.',
              '$targetName is no longer Co-Master.',
            );
      aggiungiLog(risultato);
    });

    unawaited(
      service!.sendRoleUpdate(
        targetTag: targetTag,
        targetName: targetName,
        coMaster: coMaster,
        campaignId: activeCampaignId,
        campaignName: activeCampaignName(),
      ),
    );
    unawaited(salvaDatiSoloLocale());
  }

  void sendRealtimeMasterVisiblePartyTokens() {
    if (realtimeService?.isConnected != true || !realtimeIsMasterRole) return;

    salvaSchedaCorrenteInMemoria();
    for (final index in masterPartyIndexes()) {
      sendRealtimeMasterVisibleTokenAt(index);
    }
  }

  void sendRealtimeMasterVisibleTokenAt(int index) {
    final service = realtimeService;
    if (service?.isConnected != true || !realtimeIsMasterRole) return;
    if (index < 0 || index >= schedePersonaggio.length) return;
    if (!sheetInMasterPartyAt(index)) return;

    final sheet = masterEnemyFullSheetVisibility
        ? realtimeSafeSheetJson(schedaJsonAt(index), includeImage: true)
        : realtimePublicSheetJsonAt(index);
    if (masterEnemyFullSheetVisibility) {
      sheet['realtimeRestrictedByMaster'] = false;
      sheet['realtimeReadOnlyByMaster'] = true;
    }
    final sheetId = normalizeOculumFriendTag(
      '${sheet['sheetTag'] ?? sheet['id'] ?? sheetTagAt(index)}',
    );
    if (sheetId.isEmpty) return;

    unawaited(
      service!.sendSharedSheet(
        sheet: sheet,
        campaignId: activeCampaignId,
        campaignName: activeCampaignName(),
        sheetId: sheetId,
        sheetName: nomeSchedaPersonaggio(index),
        ownerTag: sheetId,
        senderRole: 'master',
        targetAudience: masterEnemyFullSheetVisibility
            ? 'players_party_full'
            : 'players_enemy_tokens',
        fromMaster: true,
        masterParty: true,
      ),
    );
  }

  Future<void> sendRealtimeDiceRollWithMasterConsent({
    required String label,
    required int roll,
    required int bonus,
    required int total,
  }) async {
    if (!realtimeIsMasterRole) {
      sendRealtimeDiceRoll(
        label: label,
        roll: roll,
        bonus: bonus,
        total: total,
      );
      return;
    }

    final canShowPublic = await confirmMasterPublicDiceRoll();
    if (!canShowPublic) return;

    sendRealtimeDiceRoll(
      label: label,
      roll: roll,
      bonus: bonus,
      total: total,
      forceMasterVisible: true,
    );
  }

  Future<void> apriSchedaRealtimeCondivisa(
    int remoteIndex, {
    bool forceRemote = false,
  }) async {
    if (!realtimeConnected) return;
    if (remoteIndex < 0 || remoteIndex >= realtimeSharedSheets.length) return;

    final record = realtimeSharedSheets[remoteIndex];
    final key = '${record['key'] ?? ''}';
    if (key.isEmpty) return;

    var localIndex = realtimeLocalSheetIndexForKey(key);
    var openedDirtyCopy = false;

    applyingRealtimeRemoteSheet = true;
    try {
      setState(() {
        if (localIndex < 0) {
          final prepared = prepareRealtimeSheetForLocal(record);
          schedePersonaggio.add(prepared);
          localIndex = schedePersonaggio.length - 1;
        } else {
          final dirty = readBoolValue(
            schedePersonaggio[localIndex]['realtimeDirtyLocal'],
          );
          if (!dirty || forceRemote) {
            schedePersonaggio[localIndex] = prepareRealtimeSheetForLocal(
              record,
              existingIndex: localIndex,
            );
          } else {
            openedDirtyCopy = true;
          }
        }

        schedaCorrente = localIndex;
        caricaStatoDaJson(schedePersonaggio[schedaCorrente]);
        paginaCorrente = 0;
        risultato = openedDirtyCopy
            ? t(
                'Aperta la tua copia modificata: gli aggiornamenti online restano disponibili.',
                'Opened your edited copy: online updates remain available.',
              )
            : t(
                'Scheda online aperta: ${record['sheetName'] ?? '???'}.',
                'Online sheet opened: ${record['sheetName'] ?? '???'}.',
              );
        aggiungiLog(risultato);
        saveActiveCampaignInMemory();
      });

      await salvaDatiSoloLocale();
    } finally {
      applyingRealtimeRemoteSheet = false;
    }
  }

  Widget realtimeSheetAccessDropdown() {
    if (!realtimeConnected) {
      return smallInfoText(
        t(
          'Accesso schede online disponibile solo quando Realtime Oculum e connesso.',
          'Online sheet access is available only while Realtime Oculum is connected.',
        ),
      );
    }

    if (!realtimeCanBrowseOtherSheets) {
      return smallInfoText(
        t(
          'Stai usando la tua scheda attiva. Master e Co-Master vedono le altre schede nella pagina Online.',
          'You are using your active sheet. Masters and Co-Masters can see other sheets on the Online page.',
        ),
        color: tertiaryColor,
      );
    }

    final importedKeys = schedePersonaggio
        .map((sheet) => '${sheet['realtimeSourceKey'] ?? ''}')
        .where((key) => key.isNotEmpty)
        .toSet();
    final items = <DropdownMenuItem<String>>[
      for (int i = 0; i < schedePersonaggio.length; i++)
        DropdownMenuItem<String>(
          value: 'local:$i',
          child: Text(
            readBoolValue(schedePersonaggio[i]['realtimeSharedSheet'])
                ? 'Online copia - ${schedePersonaggio[i]['realtimeOwnerName'] ?? '???'} - ${nomeSchedaPersonaggio(i)}'
                : '${i + 1}. ${nomeSchedaPersonaggio(i)}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      for (int i = 0; i < realtimeSharedSheets.length; i++)
        if (!importedKeys.contains('${realtimeSharedSheets[i]['key'] ?? ''}'))
          DropdownMenuItem<String>(
            value: 'remote:$i',
            child: Text(
              'Online - ${realtimeSharedSheets[i]['ownerName'] ?? '???'} - ${realtimeSharedSheets[i]['sheetName'] ?? '???'}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
    ];

    return DropdownButtonFormField<String>(
      initialValue: 'local:$schedaCorrente',
      dropdownColor: const Color(0xFF11131A),
      decoration: fieldDecoration('${activeCampaignName()} - online'),
      items: items,
      onChanged: (value) {
        if (value == null) return;
        final parts = value.split(':');
        if (parts.length != 2) return;
        final index = int.tryParse(parts[1]);
        if (index == null) return;

        if (parts.first == 'local') {
          cambiaSchedaPersonaggio(index);
        } else if (parts.first == 'remote') {
          final record = index >= 0 && index < realtimeSharedSheets.length
              ? realtimeSharedSheets[index]
              : <String, dynamic>{};
          final sheet = record['sheet'] is Map
              ? Map<String, dynamic>.from(record['sheet'] as Map)
              : <String, dynamic>{};
          if (readBoolValue(sheet['realtimeRestrictedByMaster'])) {
            setState(() {
              risultato = t(
                'Questa scheda e un token nemico visivo: immagine e iniziativa soltanto.',
                'This sheet is a visual enemy token: image and initiative only.',
              );
              aggiungiLog(risultato);
            });
            return;
          }
          apriSchedaRealtimeCondivisa(index);
        }
      },
    );
  }

  Widget realtimeSharedSheetsPanel() {
    if (!realtimeConnected) return const SizedBox.shrink();
    if (!realtimeCanBrowseOtherSheets) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Schede online condivise', 'Shared online sheets'),
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (realtimeSharedSheets.isEmpty)
          smallInfoText(
            t(
              'Nessuna scheda condivisa ricevuta in questa stanza.',
              'No shared sheet received in this room.',
            ),
          )
        else
          ...realtimeSharedSheets.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            final key = '${record['key'] ?? ''}';
            final sheet = record['sheet'] is Map
                ? Map<String, dynamic>.from(record['sheet'] as Map)
                : <String, dynamic>{};
            final restricted = readBoolValue(
              sheet['realtimeRestrictedByMaster'],
            );
            final localIndex = realtimeLocalSheetIndexForKey(key);
            final dirty =
                localIndex >= 0 &&
                readBoolValue(
                  schedePersonaggio[localIndex]['realtimeDirtyLocal'],
                );
            final sheetId = normalizeOculumFriendTag(
              '${record['sheetId'] ?? ''}',
            );
            final coMasterMarked =
                realtimeCoMasterTags.contains(sheetId.toUpperCase()) ||
                '${record['senderRole'] ?? ''}' == 'coMaster' ||
                (localIndex >= 0 &&
                    readBoolValue(
                      schedePersonaggio[localIndex]['realtimeCoMaster'],
                    ));
            final canManageCoMaster =
                (realtimeIsMasterRole ||
                    (realtimeIsCoMasterRole && coMasterCanSetCoMaster)) &&
                !restricted &&
                sheetId.isNotEmpty &&
                ('${record['senderRole'] ?? ''}' == 'player' ||
                    '${record['senderRole'] ?? ''}' == 'coMaster');

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: dirty
                      ? tertiaryColor.withValues(alpha: 0.75)
                      : primaryColor.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record['sheetName'] ?? '???'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  smallInfoText(
                    '${record['ownerName'] ?? '???'} - ${record['campaignName'] ?? 'Online'}'
                    '${coMasterMarked ? ' - Co-Master' : ''}'
                    '${dirty ? ' - copia modificata localmente' : ''}',
                    color: dirty ? tertiaryColor : Colors.grey.shade300,
                  ),
                  if (restricted) ...[
                    const SizedBox(height: 4),
                    smallInfoText(
                      t(
                        'Scheda nemica limitata: visibili immagine e iniziativa. Base ${sheet['publicInitiativeBase'] ?? 0}, lanciata ${sheet['publicInitiativeTotal'] ?? 0}.',
                        'Restricted enemy sheet: image and initiative visible. Base ${sheet['publicInitiativeBase'] ?? 0}, rolled ${sheet['publicInitiativeTotal'] ?? 0}.',
                      ),
                      color: tertiaryColor,
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (!restricted)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => apriSchedaRealtimeCondivisa(index),
                          icon: const Icon(Icons.edit),
                          label: Text(t('Apri / modifica', 'Open / edit')),
                        ),
                        if (dirty)
                          OutlinedButton.icon(
                            onPressed: () => apriSchedaRealtimeCondivisa(
                              index,
                              forceRemote: true,
                            ),
                            icon: const Icon(Icons.cloud_download),
                            label: Text(
                              t('Aggiorna da online', 'Update from online'),
                            ),
                          ),
                        if (canManageCoMaster)
                          OutlinedButton.icon(
                            onPressed: () => setRealtimeCoMasterForRecord(
                              record,
                              !coMasterMarked,
                            ),
                            icon: const Icon(Icons.admin_panel_settings),
                            label: Text(
                              coMasterMarked
                                  ? t('Revoca Co-Master', 'Revoke Co-Master')
                                  : t('Nomina Co-Master', 'Make Co-Master'),
                            ),
                          ),
                      ],
                    )
                  else
                    smallInfoText(
                      t(
                        'Token visivo: non importabile finche il Master non consente i dettagli.',
                        'Visual token: not importable until the Master allows details.',
                      ),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget realtimeVisibleInitiativePanel() {
    if (!realtimeConnected || realtimeIsMasterRole) {
      return const SizedBox.shrink();
    }
    if (realtimeVisibleInitiativeSnapshot.isEmpty) {
      return const SizedBox.shrink();
    }

    final tokensRaw = realtimeVisibleInitiativeSnapshot['tokens'];
    final tokens = tokensRaw is List
        ? tokensRaw
              .whereType<Map>()
              .map((x) => Map<String, dynamic>.from(x))
              .toList()
        : <Map<String, dynamic>>[];
    final round = readIntValue(
      realtimeVisibleInitiativeSnapshot['round'],
      fallback: 1,
    );
    final activeIndex = readIntValue(
      realtimeVisibleInitiativeSnapshot['activeIndex'],
    );
    final turnCount = readIntValue(
      realtimeVisibleInitiativeSnapshot['turnCount'],
      fallback: tokens.length,
    );

    return gothicPanel(
      borderColor: tertiaryColor,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: tertiaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fight - ${t('Round', 'Round')} $round - ${t('Turni', 'Turns')} $turnCount',
                  style: TextStyle(
                    color: tertiaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    realtimeVisibleInitiativeSnapshot = <String, dynamic>{};
                  });
                },
                icon: const Icon(Icons.close, size: 16),
                label: Text(t('Nascondi', 'Hide')),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (tokens.isEmpty)
            smallInfoText(
              t('Nessun partecipante visibile.', 'No visible participant.'),
            )
          else
            Column(
              children: [
                for (int i = 0; i < tokens.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color:
                          i == activeIndex || readBoolValue(tokens[i]['active'])
                          ? tertiaryColor.withValues(alpha: 0.16)
                          : Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            i == activeIndex ||
                                readBoolValue(tokens[i]['active'])
                            ? tertiaryColor
                            : primaryColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 26,
                          child: Text(
                            '${tokens[i]['index'] ?? i + 1}',
                            style: TextStyle(
                              color: tertiaryColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 38,
                          height: 38,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: initiativeTokenAvatar(tokens[i]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${tokens[i]['name'] ?? '???'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              smallInfoText(
                                '${t('Turno', 'Turn')} ${tokens[i]['turnNumber'] ?? tokens[i]['index'] ?? i + 1}/${tokens[i]['turnCount'] ?? turnCount} - ${masterInitiativeSideLabel('${tokens[i]['side'] ?? 'ally'}')} - ${masterInitiativeStatusLabel('${tokens[i]['status'] ?? 'ready'}')}',
                                color: masterInitiativeStatusColor(
                                  '${tokens[i]['status'] ?? 'ready'}',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${tokens[i]['initiativeTotal'] ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget realtimeOculumPanel() {
    final connectedLabel = realtimeConnected
        ? t(
            'Connesso a oculum_room_${realtimeRoomController.text.trim().isEmpty ? 'test' : realtimeRoomController.text.trim()}',
            'Connected to oculum_room_${realtimeRoomController.text.trim().isEmpty ? 'test' : realtimeRoomController.text.trim()}',
          )
        : realtimeStatus;

    return gothicPanel(
      borderColor: Colors.greenAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Realtime Oculum',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Live leggero con Supabase Broadcast e Presence: invia eventi di gioco, nickname, ruolo e tag scheda necessari alla condivisione. Non invia IP.',
              'Light live mode with Supabase Broadcast and Presence: sends game events, nicknames, role and sheet tags needed for sharing. It does not send IPs.',
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: realtimeWantsMasterRole,
            activeThumbColor: tertiaryColor,
            title: Text(
              t('Entra come Master della campagna', 'Join as campaign Master'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              realtimeMasterBlockedByPresence
                  ? t(
                      'Master gia presente: ruolo attuale Giocatore.',
                      'Master already present: current role Player.',
                    )
                  : t(
                      'Ruolo attuale: ${realtimeLocalRole() == 'master'
                          ? 'Master'
                          : realtimeLocalRole() == 'coMaster'
                          ? 'Co-Master'
                          : 'Giocatore'}. Solo il primo Master resta Master.',
                      'Current role: ${realtimeLocalRole() == 'master'
                          ? 'Master'
                          : realtimeLocalRole() == 'coMaster'
                          ? 'Co-Master'
                          : 'Player'}. Only the first Master stays Master.',
                    ),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
            ),
            onChanged: (value) {
              setState(() {
                modalitaMaster = value;
                realtimeMasterBlockedByPresence =
                    value && realtimeShouldYieldMaster(realtimeUsers);
                if (!value) {
                  realtimeMasterBlockedByPresence = false;
                }
                risultato = realtimeMasterBlockedByPresence
                    ? t(
                        'Master gia presente nella stanza: resti giocatore.',
                        'A Master is already in the room: you stay player.',
                      )
                    : t('Ruolo realtime aggiornato.', 'Realtime role updated.');
                aggiungiLog(risultato);
              });
              unawaited(realtimeService?.refreshPresence());
              programmaSalvataggio();
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: campoTesto(
                  label: 'Room ID',
                  controller: realtimeRoomController,
                  numero: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: campoTesto(
                  label: t('Nome visibile', 'Visible name'),
                  controller: realtimeNameController,
                  numero: false,
                  helper: realtimeDisplayName(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          realtimeSheetAccessDropdown(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: realtimeConnecting || realtimeConnected
                    ? null
                    : connectRealtimeOculum,
                icon: const Icon(Icons.link),
                label: Text(t('Connetti', 'Connect')),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: realtimeConnected || realtimeConnecting
                    ? disconnectRealtimeOculum
                    : null,
                icon: const Icon(Icons.link_off),
                label: Text(t('Disconnetti', 'Disconnect')),
              ),
              ElevatedButton.icon(
                onPressed: realtimeConnected ? sendRealtimePing : null,
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Ping'),
              ),
              ElevatedButton.icon(
                onPressed: realtimeConnected ? sendRealtimeTestLog : null,
                icon: const Icon(Icons.notes),
                label: Text(t('Log test', 'Test log')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          smallInfoText(
            connectedLabel,
            color: realtimeConnected ? Colors.greenAccent : tertiaryColor,
          ),
          const SizedBox(height: 14),
          Text(
            t('Utenti online', 'Online users'),
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (realtimeUsers.isEmpty)
            smallInfoText(t('Nessun utente online.', 'No online users.'))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: realtimeUsers.map((user) {
                return Chip(
                  backgroundColor: const Color(0xFF10121A),
                  side: BorderSide(
                    color: Colors.greenAccent.withValues(alpha: 0.5),
                  ),
                  label: Text(
                    '${user['playerName'] ?? '???'}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 14),
          realtimeVisibleInitiativePanel(),
          if (realtimeVisibleInitiativeSnapshot.isNotEmpty)
            const SizedBox(height: 14),
          realtimeSharedSheetsPanel(),
          const SizedBox(height: 14),
          Text(
            t('Eventi realtime', 'Realtime events'),
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (realtimeEvents.isEmpty)
            smallInfoText(t('Nessun evento ricevuto.', 'No events received.'))
          else
            ...realtimeEvents
                .take(8)
                .map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      event,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
