part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

Duration oculumRealtimeSheetAckRetryDelay(int attempt) => Duration(
  seconds: attempt <= 1
      ? 8
      : attempt == 2
      ? 15
      : attempt == 3
      ? 30
      : attempt == 4
      ? 60
      : 120,
);

int oculumDropDifficultyBonus(String difficulty) => switch (difficulty) {
  'difficile' => 3,
  'oculum' => 6,
  _ => 0,
};

/// Offers and purchase counters belong to the local character. Merchant roster
/// metadata is shared separately, while purchased goods sync in the inventory.
const Set<String> oculumRealtimePrivateMerchantFields = <String>{
  'merchantStock',
  'merchantStockSessionId',
  'merchantActiveProfileId',
  'merchantDustPurchasedSinceLongRest',
  'merchantDustPurchaseCount',
};

List<Map<String, dynamic>> oculumRealtimeMerchantRosterProjection(
  dynamic rawProfiles,
) {
  if (rawProfiles is! List) return <Map<String, dynamic>>[];
  final profiles = <String, Map<String, dynamic>>{};
  for (final raw in rawProfiles.whereType<Map>()) {
    final profile = Map<String, dynamic>.from(raw);
    final id = '${profile['id'] ?? ''}'.trim();
    if (id.isEmpty) continue;
    profiles[id] = <String, dynamic>{
      'id': id,
      'name': '${profile['name'] ?? 'Mercante di fiducia'}',
      'shopType': '${profile['shopType'] ?? 'tutti'}',
      'pricePercent': readIntValue(
        profile['pricePercent'],
        fallback: 100,
      ).clamp(70, 160),
    };
    if (profiles.length >= 128) break;
  }
  return profiles.values.toList(growable: false)
    ..sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
}

List<Map<String, dynamic>> oculumRealtimeMergeMerchantRoster(
  List<Map<String, dynamic>> localProfiles,
  dynamic incomingProfiles,
) {
  final merged = <String, Map<String, dynamic>>{};
  for (final profile in localProfiles) {
    final id = '${profile['id'] ?? ''}'.trim();
    if (id.isEmpty) continue;
    merged[id] = Map<String, dynamic>.from(profile);
  }
  for (final profile in oculumRealtimeMerchantRosterProjection(
    incomingProfiles,
  )) {
    final id = '${profile['id']}';
    final existing = merged[id];
    if (existing == null) {
      merged[id] = <String, dynamic>{...profile, 'stock': <dynamic>[]};
      continue;
    }
    final personalStock = existing['stock'];
    existing.addAll(profile);
    if (personalStock is List) existing['stock'] = personalStock;
  }
  return merged.values.toList(growable: false)
    ..sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
}

Map<String, dynamic> oculumRealtimeStripPrivateMerchantState(
  Map<String, dynamic> sheet,
) {
  final profiles = oculumRealtimeMerchantRosterProjection(
    sheet['merchantProfiles'],
  );
  for (final key in oculumRealtimePrivateMerchantFields) {
    sheet.remove(key);
  }
  if (profiles.isEmpty) {
    sheet.remove('merchantProfiles');
  } else {
    sheet['merchantProfiles'] = profiles;
  }
  return sheet;
}

const Set<String> oculumRealtimeMetadataKeys = <String>{
  'relayServerUrl',
  'relayRoomCode',
  'connectedMasterIp',
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
  'realtimeOwnerEditSequence',
  'realtimeOwnerEditRoom',
  'realtimeOwnerEditFieldSequences',
  'claimedEncounterRewardIds',
  'localUpdatedAt',
  'realtimeRestrictedByMaster',
  'realtimeReadOnlyByMaster',
  'publicTokenSide',
  'publicInitiativeBase',
  'publicInitiativeTotal',
  'publicInitiativeRollHidden',
  'realtimeCoMaster',
  'realtimeShareWithFriends',
  'realtimeVisibleInitiativeSnapshot',
  'encounterPlayerIdentities',
  'diaryEntityRoles',
  'diaryKnowledgeSync',
  ...oculumRealtimePrivateMerchantFields,
};

List<int> oculumSelectedSheetDeliveryIndexes(
  List<Map<String, dynamic>> sheets,
  int selected,
  Iterable<Map<String, dynamic>> eyes,
) {
  if (selected < 0 || selected >= sheets.length) return [];
  if (readBoolValue(sheets[selected]['realtimeSharedSheet'])) return [];
  String tag(Map sheet) =>
      '${sheet['sheetTag'] ?? sheet['id'] ?? ''}'.toUpperCase();
  final selectedSheet = sheets[selected];
  final owner =
      '${selectedSheet['summonerTag'] ?? selectedSheet['shadowCloneOwnerTag'] ?? ''}'
          .toUpperCase();
  final owners = {tag(selectedSheet), if (owner.isNotEmpty) owner};
  final activeEyes = eyes.where(
    (eye) => readBoolValue(eye['active']) && !oculumFallenEyeIsDead(eye),
  );
  for (final eye in activeEyes) {
    if ('${eye['summonedSheetTag'] ?? ''}'.toUpperCase() ==
        tag(selectedSheet)) {
      owners.add('${eye['ownerSheetId'] ?? ''}'.toUpperCase());
    }
  }
  final eyeTags = activeEyes
      .where(
        (eye) => owners.contains('${eye['ownerSheetId'] ?? ''}'.toUpperCase()),
      )
      .map((eye) => '${eye['summonedSheetTag'] ?? ''}'.toUpperCase())
      .toSet();
  return [
    selected,
    for (var i = 0; i < sheets.length; i++)
      if (i != selected &&
          !readBoolValue(sheets[i]['realtimeSharedSheet']) &&
          (owners.contains(tag(sheets[i])) ||
              eyeTags.contains(tag(sheets[i])) ||
              ((readBoolValue(sheets[i]['isSummon']) ||
                      readBoolValue(sheets[i]['oculumShadowClone'])) &&
                  !readBoolValue(sheets[i]['summonExpired']) &&
                  !readBoolValue(sheets[i]['shadowCloneExpired']) &&
                  owners.contains(
                    '${sheets[i]['summonerTag'] ?? sheets[i]['shadowCloneOwnerTag'] ?? ''}'
                        .toUpperCase(),
                  ))))
        i,
  ];
}

int? oculumRealtimeStaffOwnerEditSequence(
  Map<String, dynamic> existing,
  Map<String, dynamic> payload,
  String channelName,
) {
  if (readBoolValue(existing['realtimeSharedSheet']) ||
      !const {'master', 'coMaster'}.contains(payload['authenticatedRole']) ||
      !channelName.startsWith('oculum_secure_')) {
    return null;
  }
  final sequence = readIntValue(payload['serverSequence']);
  return sequence > 0 ? sequence : null;
}

bool oculumInitiativePayloadClosesFight(Map<String, dynamic> payload) =>
    readBoolValue(payload['closed']);

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
  'journalEntries',
  'partyMembri',
  'merchantProfiles',
};

/// Una condivisione diretta fra amici deve arrivare anche ai player, non solo
/// a Master e Co-Master. Usiamo il formato completo, già gestito dal ricevente
/// con import automatico e filtri per tag destinatario.
const String oculumRealtimeFriendShareSenderRole = 'fullShare';

bool oculumRealtimeShouldImportSharedSheet({
  required String senderRole,
  required bool masterParty,
  required bool restrictedByMaster,
}) {
  return senderRole == 'fullShare' ||
      senderRole == 'player' ||
      senderRole == 'coMaster' ||
      (senderRole == 'master' && masterParty && !restrictedByMaster);
}

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
    final nextValue = key == 'merchantProfiles'
        ? oculumRealtimeMerchantRosterProjection(entry.value)
        : entry.value;
    final previousHasKey = previous.containsKey(key);
    final previousValue = key == 'merchantProfiles'
        ? oculumRealtimeMerchantRosterProjection(previous[key])
        : previous[key];
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
  final patch = oculumRealtimeBuildSheetPatch(
    const <String, dynamic>{},
    current,
  );
  // A base64 portrait can dominate a patch. Portraits already use the
  // dedicated chunked sheet transfer and hash-based refresh path.
  patch.remove('immaginePersonaggioBase64');
  return patch;
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
    final currentValue = key == 'merchantProfiles'
        ? oculumRealtimeMerchantRosterProjection(existing[key])
        : existing[key];
    if (jsonEncode(currentValue) == jsonEncode(entry.value)) continue;
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
    final currentValue = key == 'merchantProfiles'
        ? oculumRealtimeMerchantRosterProjection(existing[key])
        : existing[key];
    if (jsonEncode(currentValue) == jsonEncode(entry.value)) continue;
    merged[key] = key == 'merchantProfiles' && entry.value is List
        ? oculumRealtimeMergeMerchantRoster(
            existing[key] is List
                ? (existing[key] as List)
                      .whereType<Map>()
                      .map((profile) => Map<String, dynamic>.from(profile))
                      .toList()
                : <Map<String, dynamic>>[],
            entry.value,
          )
        : oculumRealtimeCloneJsonValue(entry.value);
  }
  return merged;
}

String oculumRealtimeSheetDeliveryHashKey(
  String audience,
  String sheetId,
  Iterable<String> targetTags,
) {
  final targets =
      targetTags
          .map((tag) => tag.trim().toUpperCase())
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  return '$audience:${sheetId.trim().toUpperCase()}:${targets.join(',')}';
}

String oculumRealtimePresenceTagSignature(
  Iterable<Map<String, dynamic>> users,
) {
  final tags = <String>{};
  for (final user in users) {
    final active = '${user['activeSheetTag'] ?? ''}'.trim().toUpperCase();
    if (active.isNotEmpty) {
      tags.add('active:${user['sessionId'] ?? ''}:$active');
    }
    final rawTags = user['localSheetTags'];
    if (rawTags is! List) continue;
    for (final raw in rawTags) {
      final tag = '$raw'.trim().toUpperCase();
      final session = '${user['sessionId'] ?? ''}';
      if (tag.isNotEmpty) tags.add(session.isEmpty ? tag : '$tag:$session');
    }
  }
  final ordered = tags.toList()..sort();
  return ordered.join('|');
}

/// Roles and sessions matter even when a returning Master owns the same tags.
/// Do not use joinedAt: it changes whenever Presence is refreshed.
String oculumRealtimeStaffPresenceSignature(
  Iterable<Map<String, dynamic>> users,
) {
  final staff = <String>{};
  for (final user in users) {
    final role = '${user['role'] ?? ''}';
    if (role != 'master' && role != 'coMaster') continue;
    staff.add(
      jsonEncode([
        role,
        user['sessionId'] ??
            user['masterClaimId'] ??
            user['activeSheetTag'] ??
            '',
      ]),
    );
  }
  return (staff.toList()..sort()).join('|');
}

String oculumRealtimeSheetContentSignature(Map<String, dynamic> sheet) {
  final content = Map<String, dynamic>.from(sheet);
  for (final key in [
    'localUpdatedAt',
    'realtimeReceivedAt',
    'realtimeSharedAt',
  ]) {
    content.remove(key);
  }
  // Store a digest, not another copy of every embedded portrait in memory.
  return SHA256Digest()
      .process(Uint8List.fromList(utf8.encode(jsonEncode(content))))
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}

bool oculumRealtimePresenceOwnsSheet(
  Iterable<Map<String, dynamic>> users,
  Map<String, dynamic> payload,
  String sheetTag,
) {
  final tag = sheetTag.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();
  if (tag.isEmpty) return false;
  final session = '${payload['sessionId'] ?? ''}';
  return users.any((user) {
    if (session.isNotEmpty) {
      if (user['sessionId'] != session) return false;
    } else if (user['playerName'] != payload['playerName']) {
      return false;
    }
    return [
      user['activeSheetTag'],
      ...(user['localSheetTags'] as List? ?? []),
    ].any(
      (raw) =>
          '${raw ?? ''}'.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase() ==
          tag,
    );
  });
}

/// Choose only Master-published encounters. A sheet switch must not keep the
/// previous character's fight; staff may inspect any explicitly selected one.
Map<String, dynamic> oculumSelectSharedEncounter(
  List<Map<String, dynamic>> encounters, {
  required String sheetTag,
  required String selectedId,
  bool staff = false,
}) {
  String normalizedTag(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();
  bool containsSheet(Map<String, dynamic> encounter) =>
      (encounter['tokens'] as List? ?? const []).whereType<Map>().any(
        (token) =>
            normalizedTag('${token['sheetTag'] ?? token['id'] ?? ''}') ==
            normalizedTag(sheetTag),
      );
  final selected = encounters.where(
    (encounter) =>
        encounter['encounterId'] == selectedId ||
        (encounter['mergedEncounterIds'] as List? ?? const []).contains(
          selectedId,
        ),
  );
  for (final encounter in selected) {
    if (staff || containsSheet(encounter)) return encounter;
  }
  for (final encounter in encounters) {
    if (containsSheet(encounter)) return encounter;
  }
  return <String, dynamic>{'tokens': [], 'round': 0, 'activeIndex': 0};
}

extension _OculumRealtimeIntegration on _OculumHomePageState {
  void replayPendingEncounterJoins(String sheetTag) {
    for (final entry in realtimePendingEncounterJoins.entries.toList()) {
      if (sheetTag.isEmpty || entry.value['sheetTag'] == sheetTag) {
        realtimePendingEncounterJoins.remove(entry.key);
        receiveRealtimeReportedTurn(entry.value);
      }
    }
  }

  Future<void> joinSharedMasterEncounter(
    Map<String, dynamic> group, {
    int? sheetIndex,
  }) async {
    final id = '${group['encounterId'] ?? ''}';
    final service = realtimeService;
    if (id.isEmpty || service?.isConnected != true) return;
    if (realtimeIsCoMasterRole) {
      realtimeSelectedEncounterId = id;
      selectSharedEncounterForCurrentSheet();
      setState(() {});
      return;
    }
    final joiningIndex = sheetIndex ?? schedaCorrente;
    if (joiningIndex < 0 || joiningIndex >= schedePersonaggio.length) return;
    if (joiningIndex == schedaCorrente) salvaSchedaCorrenteInMemoria();
    final tag = sheetTagAt(joiningIndex);
    realtimeOutgoingEncounterJoins['$id:$tag'] = {
      'sheetTag': tag,
      'encounterId': id,
      'campaignId': group['campaignId'] ?? permissionCampaignId,
      'campaignName': group['campaignName'] ?? activeCampaignName(),
      'turn': readIntValue(
        schedePersonaggio[joiningIndex]['playerReportedTurn'],
        fallback: joiningIndex == schedaCorrente ? playerReportedTurn : 0,
      ),
    };
    await service!.refreshPresence();
    await retryPendingEncounterJoins();
    realtimeEncounterJoinRetryTimer ??= Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(retryPendingEncounterJoins()),
    );
    if (!mounted) return;
    aggiungiLog(
      '[TURNISTICA] Ingresso richiesto al Master: ${group['name'] ?? id}. La conferma arriva con la turnistica condivisa.',
    );
    setState(() {});
  }

  Future<void> retryPendingEncounterJoins() async {
    final service = realtimeService;
    if (!mounted ||
        service?.isConnected != true ||
        realtimeIsMasterRole ||
        realtimeEncounterJoinSending) {
      return;
    }
    realtimeEncounterJoinSending = true;
    try {
      for (final entry in realtimeOutgoingEncounterJoins.entries.toList()) {
        final request = entry.value;
        final tag = '${request['sheetTag']}';
        final encounter = realtimeEncounterSnapshots
            .where(
              (group) =>
                  group['encounterId'] == request['encounterId'] ||
                  (group['mergedEncounterIds'] as List? ?? []).contains(
                    request['encounterId'],
                  ),
            )
            .firstOrNull;
        if (encounter != null &&
            (encounter['tokens'] as List? ?? []).whereType<Map>().any(
              (token) =>
                  normalizeOculumFriendTag(
                    '${token['sheetTag'] ?? token['id'] ?? ''}',
                  ).toUpperCase() ==
                  tag.toUpperCase(),
            )) {
          realtimeOutgoingEncounterJoins.remove(entry.key);
          continue;
        }
        final index = localSheetIndexForOculumTag(tag);
        if (index < 0 ||
            readBoolValue(schedePersonaggio[index]['realtimeSharedSheet'])) {
          realtimeOutgoingEncounterJoins.remove(entry.key);
          continue;
        }
        await sendRealtimeSheetToStaffAt(index, ensureMasterReceipt: true);
        if (!mounted ||
            realtimeService != service ||
            service?.isConnected != true) {
          break;
        }
        await service!.sendInitiativeTurnAdjusted(
          senderRole: realtimeLocalRole(),
          campaignId: '${request['campaignId']}',
          campaignName: '${request['campaignName']}',
          sheetTag: tag,
          turn: readIntValue(request['turn']),
          encounterId: '${encounter?['encounterId'] ?? request['encounterId']}',
          joinEncounter: true,
        );
      }
    } finally {
      realtimeEncounterJoinSending = false;
      if (realtimeOutgoingEncounterJoins.isEmpty) {
        realtimeEncounterJoinRetryTimer?.cancel();
        realtimeEncounterJoinRetryTimer = null;
      }
    }
  }

  Future<void> sendRealtimeActiveSheetToStaff({bool force = false}) {
    realtimeOwnedSheetResyncRequested = true;
    realtimeOwnedSheetForceRequested |= force;
    return realtimeOwnedSheetSync ??= _sendRealtimeActiveSheetToStaff()
        .whenComplete(() {
          realtimeOwnedSheetSync = null;
        });
  }

  Future<void> _sendRealtimeActiveSheetToStaff() async {
    final service = realtimeService;
    while (realtimeOwnedSheetResyncRequested &&
        mounted &&
        canShareRealtimeSheetToStaff) {
      realtimeOwnedSheetResyncRequested = false;
      final force = realtimeOwnedSheetForceRequested;
      realtimeOwnedSheetForceRequested = false;
      salvaSchedaCorrenteInMemoria();
      if (!mounted ||
          realtimeService != service ||
          !canShareRealtimeSheetToStaff) {
        return;
      }
      repairMissingFallenEyeSheets();
      final indexes = oculumSelectedSheetDeliveryIndexes(
        schedePersonaggio,
        schedaCorrente,
        occhiCaduti,
      );
      for (final index in indexes) {
        if (!mounted ||
            realtimeService != service ||
            !canShareRealtimeSheetToStaff) {
          return;
        }
        await sendRealtimeSheetToStaffAt(
          index,
          force: force,
          ensureMasterReceipt: true,
        );
      }
    }
  }

  void selectSharedEncounterForCurrentSheet() {
    if (realtimeService?.isConnected != true || realtimeIsMasterRole) return;
    final selected = oculumSelectSharedEncounter(
      realtimeEncounterSnapshots,
      sheetTag: sheetTagAt(schedaCorrente),
      selectedId: realtimeSelectedEncounterId,
      staff: realtimeIsCoMasterRole,
    );
    realtimeSelectedEncounterId = '${selected['encounterId'] ?? ''}';
    realtimeVisibleInitiativeSnapshot = Map<String, dynamic>.from(selected);
    syncCurrentSheetEncounterTurn();
  }

  void shareOwnedEncounterSheetsToStaff() {
    if (!canShareRealtimeSheetToStaff) return;
    unawaited(sendRealtimeActiveSheetToStaff());
  }

  void syncOwnedEncounterTurns() {
    if (realtimeService?.isConnected != true || realtimeIsMasterRole) return;
    for (var index = 0; index < schedePersonaggio.length; index++) {
      if (index == schedaCorrente ||
          readBoolValue(schedePersonaggio[index]['realtimeSharedSheet'])) {
        continue;
      }
      final selected = oculumSelectSharedEncounter(
        realtimeEncounterSnapshots,
        sheetTag: sheetTagAt(index),
        selectedId: '',
      );
      final tokens = (selected['tokens'] as List? ?? const []).whereType<Map>();
      final participant = tokens
          .where(
            (token) =>
                '${token['sheetTag'] ?? token['id'] ?? ''}' ==
                sheetTagAt(index),
          )
          .firstOrNull;
      if (participant != null &&
          readIntValue(participant['reportedTurn']) >
              readIntValue(schedePersonaggio[index]['playerReportedTurn'])) {
        applySupportToOwnedSheet(
          index,
          const [],
          'Progressione turnistica Master',
        );
      }
    }
  }

  void syncSharedSheetToMasterEncounters(int index) {
    if (!realtimeIsMasterRole) return;
    syncMasterInitiativeTokenDeathFromSheet(index);
    final tag = sheetTagAt(index);
    captureActiveMasterInitiativeGroup();
    for (final group in masterInitiativeGroups) {
      for (final token
          in (group['tokens'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()) {
        if ('${token['sheetTag'] ?? token['id'] ?? ''}' == tag) {
          syncMasterInitiativeTokenDeathFromSheet(index, participant: token);
        }
      }
    }
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  String realtimeDisplayName() {
    final chosen = realtimeNameController.text.trim();
    if (chosen.isNotEmpty) return chosen;

    final sheetName = nomeController.text.trim();
    if (sheetName.isNotEmpty && sheetName != '???') {
      final visibleTitle = titoli
          .where((title) => title.equipaggiato && title.sempreVisibile)
          .map((title) => title.nome.trim())
          .where((title) => title.isNotEmpty)
          .firstOrNull;
      return visibleTitle == null || visibleTitle == sheetName
          ? sheetName
          : '$sheetName | $visibleTitle';
    }

    return 'Scheda ${schedaCorrente + 1}';
  }

  void publishRealtimeStateAfterConnection() {
    if (realtimeService?.isConnected != true) return;
    unawaited(sendRealtimeMerchantRosterSnapshot());
    unawaited(flushDiaryKnowledge());
    sendRealtimeSheetPreview();
    unawaited(sendRealtimeActiveSheetToStaff());
    unawaited(retryPendingEncounterJoins());
    if (!realtimeIsMasterRole) {
      resendRealtimeFriendSheetsForPresence();
    } else {
      sendRealtimeMonsterBookSnapshot();
      sendRealtimeMasterVisiblePartyTokens();
      sendRealtimeInitiativeSnapshotIfPublished();
      unawaited(realtimeService!.requestSharedSheets());
    }
    syncStorySessionNotesRealtime();
    syncRealtimeRecipes();
    if (modalitaMaster) {
      scheduleVttRealtimePublish(includeAsset: true);
    } else {
      requestRealtimeVttScene();
    }
  }

  void scheduleRealtimeReconnect(OculumRealtimeService service) {
    if (!mounted ||
        !realtimeAutoReconnectEnabled ||
        realtimeService != service ||
        service.isConnected ||
        service.isConnecting ||
        service.requiresUserAction ||
        (realtimeReconnectTimer?.isActive ?? false)) {
      return;
    }

    realtimeReconnectAttempt = (realtimeReconnectAttempt + 1)
        .clamp(1, 8)
        .toInt();
    const delays = <int>[2, 4, 8, 12, 18, 25, 30, 30];
    final delaySeconds = delays[realtimeReconnectAttempt - 1];
    realtimeReconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      realtimeReconnectTimer = null;
      if (!mounted ||
          !realtimeAutoReconnectEnabled ||
          realtimeService != service ||
          service.isConnected ||
          service.isConnecting ||
          service.requiresUserAction) {
        return;
      }
      setState(() {
        realtimeConnecting = true;
        realtimeStatus = t(
          'Riconnessione realtime $realtimeReconnectAttempt/8...',
          'Realtime reconnect $realtimeReconnectAttempt/8...',
        );
      });
      await service.connect();
      if (!mounted || realtimeService != service) return;
      setState(() {
        realtimeConnecting = false;
        realtimeConnected = service.isConnected;
      });
      if (service.isConnected) {
        realtimeReconnectAttempt = 0;
      } else {
        scheduleRealtimeReconnect(service);
      }
    });
  }

  Future<void> connectRealtimeOculum() async {
    if (realtimeConnecting) return;

    realtimeAutoReconnectEnabled = true;
    realtimeReconnectAttempt = 0;
    realtimeReconnectTimer?.cancel();
    realtimeReconnectTimer = null;

    setState(() {
      realtimeConnecting = true;
      realtimeStatus = t('Preparazione realtime...', 'Preparing realtime...');
    });
    final supabaseReady = await ensureOculumSupabaseInitialized();
    if (!mounted) return;
    if (!supabaseReady) {
      setState(() {
        realtimeConnecting = false;
        realtimeConnected = false;
        realtimeStatus = OculumRealtimeService.startupStatus;
      });
      return;
    }

    final room = realtimeRoomController.text.trim().isEmpty
        ? 'test'
        : realtimeRoomController.text.trim();
    realtimeRoomController.text = room;
    realtimeMasterClaimId =
        'master_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';

    await realtimeService?.dispose();

    late final OculumRealtimeService service;
    diaryKnowledgeSync.ensureIdentity();
    await forzaSalvataggioImmediato(soloLocale: true);
    if (!mounted) return;
    service = OculumRealtimeService(
      roomId: room,
      playerName: realtimeDisplayName(),
      roomPassword: realtimeRoomPasswordController.text,
      onAccessRequested: (userId, displayName) async {
        if (!mounted || realtimeService != service) return null;
        final id = 'room_join:${service.normalizedRoomId}:$userId';
        if (onlinePermissionRequests[id]?['status'] != 'pending') {
          onlinePermissionRequests[id] = {
            'id': id,
            'action': 'room_join',
            'scope': permissionScope,
            'roomCode': service.normalizedRoomId,
            'userId': userId,
            'requesterName': displayName,
            'description': t(
              'Chiede di entrare nella stanza.',
              'Requests access to the room.',
            ),
            'status': 'pending',
            'unread': true,
            'createdAt': DateTime.now().toIso8601String(),
          };
          refreshPermissionUi();
          notifyMasterOfPendingRequest();
        }
        // The top request panel sends the decision directly to the backend.
        return null;
      },
      onConnected: () {
        if (!mounted || realtimeService != service) return;
        realtimeStaffTransfersInFlight.clear();
        clearRealtimeMasterAckTracking();
        realtimeLastSentSheetHashes.clear();
        realtimeLastSentMerchantRosterSignature = '';
        publishRealtimeStateAfterConnection();
        syncPawnPresence();
        startPermissionRetry();
        unawaited(replayOnlineCombatRequests());
      },
      presenceDataProvider: () => <String, dynamic>{
        'role': realtimeLocalRole(),
        'activeSheetTag': sheetTagAt(schedaCorrente),
        'localSheetTags': ownedOculumTags(),
        'revokedSheetAccess': [
          for (final friend in blockedOculumFriends)
            {'targetTag': '${friend['tag'] ?? ''}'},
          for (var i = 0; i < schedePersonaggio.length; i++)
            if (!readBoolValue(schedePersonaggio[i]['realtimeSharedSheet']))
              for (final tag in sheetRevokedAccessTagsAt(i))
                {'targetTag': tag, 'sheetTag': sheetTagAt(i)},
        ],
        'campaignId': activeCampaignId,
        'campaignName': activeCampaignName(),
        'masterClaimId': realtimeMasterClaimId,
        'platform': oculumClientPlatformLabel(),
        'protocolVersion': 4,
        'knowledgePublicKey': diaryKnowledgeSync.publicKey,
        'knowledgeSenderTag': diaryKnowledgeSenderTag(),
      },
      onEvent: (event, payload) {
        if (!mounted || realtimeService != service) return;
        handleRealtimeEvent(event, payload);
      },
      onPresenceChanged: (users) {
        if (!mounted || realtimeService != service) return;
        final blockMaster = realtimeShouldYieldMaster(users);
        final presenceSignature = oculumRealtimePresenceTagSignature(users);
        final friendPresenceChanged =
            presenceSignature != realtimeFriendPresenceSignature;
        final staffPresenceChanged =
            oculumRealtimeStaffPresenceSignature(users) !=
            oculumRealtimeStaffPresenceSignature(realtimeUsers);
        setState(() {
          realtimeUsers = users;
          realtimeFriendPresenceSignature = presenceSignature;
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
        final conflict = service.unavailableActiveSheetTag;
        if (service.isConnected &&
            !realtimeIsMasterRole &&
            conflict != null &&
            realtimeShownSheetConflicts.add(conflict)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && realtimeService == service) {
              unawaited(showRealtimeSheetIdentityConflict(conflict));
            }
          });
        }
        if (blockMaster) {
          unawaited(service.refreshPresence());
        }
        if (service.isConnected &&
            (friendPresenceChanged || staffPresenceChanged)) {
          unawaited(sendRealtimeMerchantRosterSnapshot(force: true));
          unawaited(sendPartyChestState());
        }
        if (service.isConnected &&
            !realtimeIsMasterRole &&
            (friendPresenceChanged || staffPresenceChanged)) {
          realtimeLastSentSheetHashes.removeWhere(
            (key, _) => key.startsWith('staff:'),
          );
          unawaited(sendRealtimeActiveSheetToStaff());
          unawaited(retryPendingEncounterJoins());
          if (staffPresenceChanged) {
            unawaited(sendMonsterBookPartyDiscoverySnapshot());
          }
        }
        if (service.isConnected &&
            (friendPresenceChanged || staffPresenceChanged)) {
          syncPawnPresence();
          startPermissionRetry();
          unawaited(replayOnlineCombatRequests());
          if (realtimeIsMasterRole) {
            replayPendingEncounterJoins('');
            for (final record in realtimeSharedSheets) {
              if (realtimeCoMasterTags.contains(
                normalizeOculumFriendTag(
                  '${record['sheetId'] ?? ''}',
                ).toUpperCase(),
              )) {
                setRealtimeCoMasterForRecord(record, true);
              }
            }
          }
        }
        if (service.isConnected && friendPresenceChanged) {
          unawaited(flushDiaryKnowledge());
          realtimeLastSentSheetHashes.removeWhere(
            (key, _) => key.startsWith('friend:'),
          );
          resendRealtimeFriendSheetsForPresence();
          if (realtimeIsMasterRole) {
            unawaited(sendMonsterBookPartyDiscoverySnapshot());
            sendRealtimeMasterVisiblePartyTokens();
            sendRealtimeInitiativeSnapshotIfPublished();
          }
        }
      },
      onStatusChanged: (status) {
        if (!mounted || realtimeService != service) return;
        final connected = service.isConnected;
        if (connected) {
          realtimeReconnectTimer?.cancel();
          realtimeReconnectTimer = null;
          realtimeReconnectAttempt = 0;
        }
        setState(() {
          realtimeStatus = status;
          realtimeConnected = connected;
          realtimeConnecting = !connected && service.isConnecting;
        });
        if (!connected) scheduleRealtimeReconnect(service);
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
      realtimeInitiativeSession = '';
      realtimeInitiativeRevision = 0;
      realtimeInitiativeServerSequence = 0;
      realtimeHiddenEncounterIds.clear();
      realtimeShownSheetConflicts.clear();
      realtimePendingEncounterJoins.clear();
      realtimeVisibleInitiativeSnapshot = <String, dynamic>{};
      realtimeLoggedInitiativeTurnKey = '';
      realtimeEncounterSnapshots = <Map<String, dynamic>>[];
      realtimeSelectedEncounterId = '';
      realtimeCoMasterTags.clear();
      realtimeSeenEventKeys.clear();
      realtimeRoleUpdateTimestamps.clear();
      realtimeLastSentSheetHashes.clear();
      realtimeFriendPresenceSignature = '';
      clearRealtimeMasterAckTracking();
      realtimeStatus = t('Connessione realtime...', 'Connecting realtime...');
    });

    await service.connect();

    if (!mounted || realtimeService != service) return;
    setState(() {
      realtimeConnecting = false;
      realtimeConnected = service.isConnected;
    });

    if (!service.isConnected) {
      scheduleRealtimeReconnect(service);
    }
  }

  Future<void> disconnectRealtimeOculum() async {
    onlinePermissionRetryTimer?.cancel();
    final service = realtimeService;
    realtimeAutoReconnectEnabled = false;
    realtimeReconnectAttempt = 0;
    realtimeReconnectTimer?.cancel();
    realtimeReconnectTimer = null;
    setState(() {
      realtimeConnecting = false;
      realtimeConnected = false;
      realtimeFirstPresenceHandled = false;
      realtimeMasterBlockedByPresence = false;
      realtimeMasterClaimId = '';
      realtimeUsers = [];
      realtimeSharedSheets.clear();
      realtimeVisibleInitiativeSnapshot = <String, dynamic>{};
      realtimeEncounterSnapshots = <Map<String, dynamic>>[];
      realtimeSelectedEncounterId = '';
      realtimeVisibleVttSnapshot = <String, dynamic>{};
      realtimeVisibleVttScene = null;
      realtimeVisibleVttImageBytes = null;
      realtimeVisibleVttAssetId = '';
      realtimeVttAssetProgress = 0;
      realtimeVttAssetAssemblers.clear();
      realtimeCoMasterTags.clear();
      realtimeSeenEventKeys.clear();
      realtimeRoleUpdateTimestamps.clear();
      realtimeLastSentSheetHashes.clear();
      realtimeFriendPresenceSignature = '';
      clearRealtimeMasterAckTracking();
    });

    await service?.disconnect();

    if (!mounted) return;
    setState(() {
      realtimeConnected = false;
      realtimeOutgoingEncounterJoins.clear();
      realtimeEncounterJoinRetryTimer?.cancel();
      realtimeEncounterJoinRetryTimer = null;
      realtimeStatus = t('Realtime disconnesso.', 'Realtime disconnected.');
    });
  }

  Future<void> createRealtimeMasterRoom() async {
    await disconnectRealtimeOculum();
    if (!mounted) return;
    final random = Random.secure();
    final code = List.generate(
      2,
      (_) => random.nextInt(0x100000000).toRadixString(16).padLeft(8, '0'),
    ).join();
    setState(() {
      modalitaMaster = true;
      realtimeRoomController.text = 'oculum_$code';
    });
    programmaSalvataggio();
    await connectRealtimeOculum();
  }

  void handleRealtimeEvent(String event, Map<String, dynamic> payload) {
    if (event == 'party_log' && payload['merchantRosterSnapshot'] == true) {
      final merged = receiveRealtimeMerchantRosterSnapshot(payload);
      if (merged) unawaited(sendRealtimeMerchantRosterSnapshot());
      return;
    }
    if (event == 'party_log' &&
        payload['monsterBookDiscoverySnapshot'] == true) {
      receiveMonsterBookPartyDiscoverySnapshot(payload);
      return;
    }
    if (event == 'party_log' && payload['monsterBookDiscovery'] == true) {
      receiveMonsterBookPartyDiscovery(payload);
      return;
    }
    if (event == 'initiative_control') {
      receiveEncounterControl(payload);
      return;
    }
    if (event == 'combat_attack' ||
        event == 'combat_defense' ||
        event == 'combat_help' ||
        event == 'combat_ack' ||
        event == 'combat_scout' ||
        event == 'corruption_apply' ||
        event == 'corruption_target') {
      receiveOnlineCombatEvent(event, payload);
      return;
    }
    if (event == 'permission_request' || event == 'permission_decision') {
      receivePermissionEvent(event, payload);
      return;
    }
    if (event.startsWith('pawn_')) {
      receivePawnEvent(event, payload);
      return;
    }
    if (event == 'diary_knowledge' || event == 'diary_knowledge_ack') {
      diaryKnowledgeReceiving =
          (diaryKnowledgeReceiving ?? Future<void>.value())
              .then((_) => receiveDiaryKnowledge(event, payload))
              .catchError((Object error) {});
      return;
    }
    final eventKey =
        '$event|${payload['playerName'] ?? ''}'
        '|${payload['id'] ?? payload['noteId'] ?? payload['syncId'] ?? ''}'
        '|${payload['chunkIndex'] ?? ''}'
        '|${payload['sheetId'] ?? ''}|${payload['ownerTag'] ?? ''}'
        '|${payload['deliveryId'] ?? ''}|${payload['receiverTag'] ?? ''}'
        '|${payload['sentAt'] ?? ''}'
        '|${payload['message'] ?? ''}';
    if (!realtimeSeenEventKeys.add(eventKey)) return;
    if (realtimeSeenEventKeys.length > 400) {
      realtimeSeenEventKeys.remove(realtimeSeenEventKeys.first);
    }

    var persistRealtimeRemote = false;
    var persistStoryNotes = false;
    var persistRecipes = false;
    var showInRealtimeEvents = true;
    var storyNotesRequesterTag = '';
    var recipesRequesterTag = '';
    final text = realtimeEventText(event, payload);
    setState(() {
      switch (event) {
        case 'session_note':
          persistStoryNotes = mergeStorySessionNotePayload(payload);
          break;
        case 'session_notes_snapshot':
          persistStoryNotes = mergeStorySessionNotesSnapshot(payload);
          showInRealtimeEvents = false;
          break;
        case 'session_notes_request':
          showInRealtimeEvents = false;
          if (realtimeIsMasterRole) {
            storyNotesRequesterTag = '${payload['requesterTag'] ?? ''}'.trim();
          }
          break;
        case 'recipes_snapshot':
          persistRecipes = receiveRealtimeRecipesSnapshot(payload);
          showInRealtimeEvents = false;
          break;
        case 'monster_book_snapshot':
          persistRealtimeRemote = receiveRealtimeMonsterBookSnapshot(payload);
          showInRealtimeEvents = false;
          break;
        case 'recipes_request':
          showInRealtimeEvents = false;
          if (haPermessiMaster &&
              '${payload['campaignId'] ?? ''}'.trim() == activeCampaignId) {
            recipesRequesterTag = '${payload['requesterTag'] ?? ''}'.trim();
          }
          break;
        case 'vtt_scene_request':
          showInRealtimeEvents = false;
          receiveRealtimeVttSceneRequest(payload);
          break;
        case 'vtt_scene_shared':
          receiveRealtimeVttSceneSnapshot(payload);
          break;
        case 'vtt_asset_chunk':
          showInRealtimeEvents = false;
          receiveRealtimeVttAssetChunk(payload);
          break;
        case 'vtt_token_patch':
          showInRealtimeEvents = false;
          receiveRealtimeVttTokenPatch(payload);
          break;
        case 'vtt_door_patch':
          showInRealtimeEvents = false;
          receiveRealtimeVttDoorPatch(payload);
          break;
        case 'vtt_ping':
          showInRealtimeEvents = false;
          receiveRealtimeVttPing(payload);
          break;
        case 'sheet_shared':
          persistRealtimeRemote = receiveRealtimeSharedSheet(payload);
          break;
        case 'item_gift':
          if (!realtimeIsMasterRole &&
              !realtimeIsCoMasterRole &&
              (payload['senderRole'] == 'master' ||
                  payload['senderRole'] == 'coMaster') &&
              realtimeUsers.any(
                (user) =>
                    '${user['activeSheetTag'] ?? ''}' ==
                        '${payload['senderTag'] ?? ''}' &&
                    '${user['campaignId'] ?? ''}' == activeCampaignId &&
                    '${user['role'] ?? ''}'.toLowerCase() ==
                        '${payload['senderRole'] ?? ''}'.toLowerCase(),
              ) &&
              '${payload['campaignId'] ?? ''}' == activeCampaignId &&
              '${payload['receiverTag'] ?? ''}' == sheetTagAt(schedaCorrente) &&
              payload['item'] is Map) {
            final item = InventoryItem.fromJson(
              Map<String, dynamic>.from(payload['item'] as Map),
            )..equipaggiata = false;
            if (item.nome.trim().isNotEmpty) {
              inventario.add(item);
              persistRealtimeRemote = true;
              final giftService = realtimeService;
              if (giftService != null) {
                unawaited(
                  giftService
                      .sendItemGift({
                        'deliveryId': payload['deliveryId'],
                        'campaignId': activeCampaignId,
                        'receiverTag': sheetTagAt(schedaCorrente),
                        'receiverName': realtimeDisplayName(),
                        'itemName': item.nome,
                      }, acknowledgement: true)
                      .then<void>((_) {}),
                );
              }
              aggiungiLog('Hai ricevuto ${item.nome} dal Master.');
            }
          }
          break;
        case 'item_gift_ack':
          if (realtimeIsMasterRole &&
              '${payload['campaignId'] ?? ''}' == activeCampaignId) {
            aggiungiLog(
              'Il giocatore ${payload['receiverName'] ?? ''} ha ricevuto ${payload['itemName'] ?? 'un oggetto'}.',
            );
          }
          break;
        case 'sheet_ping':
          if (payload['requestSharedSheets'] == true &&
              (payload['senderRole'] == 'master' ||
                  payload['senderRole'] == 'coMaster') &&
              !realtimeIsMasterRole) {
            final requestedTag = '${payload['targetSheetTag'] ?? ''}';
            final selectedTags =
                oculumSelectedSheetDeliveryIndexes(
                      schedePersonaggio,
                      schedaCorrente,
                      occhiCaduti,
                    )
                    .map(sheetTagAt)
                    .map((tag) => normalizeOculumFriendTag(tag).toUpperCase())
                    .toSet();
            if (requestedTag.isEmpty ||
                selectedTags.contains(
                  normalizeOculumFriendTag(requestedTag).toUpperCase(),
                )) {
              // A manual retry must bypass both the last hash and a missing
              // peer ACK, but never disclose the player's inactive archive.
              unawaited(sendRealtimeActiveSheetToStaff(force: true));
            }
          }
          break;
        case 'sheet_received_ack':
          receiveRealtimeSheetReceivedAck(payload);
          break;
        case 'initiative_shared':
          receiveRealtimeInitiativeSnapshot(payload);
          break;
        case 'initiative_turn_adjusted':
          receiveRealtimeReportedTurn(payload);
          break;
        case 'damage_report':
          if (haPermessiMaster) {
            realtimeDamageReportPopup = Map<String, dynamic>.from(payload);
          }
          aggiungiLog('[Realtime] $text');
          break;
        case 'dungeon_shared':
          realtimeDungeonMessage.value = Map<String, dynamic>.from(payload);
          rememberRealtimeDungeonHost(payload);
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

      if (showInRealtimeEvents) {
        realtimeEvents.insert(0, text);
        if (realtimeEvents.length > 30) {
          realtimeEvents.removeRange(30, realtimeEvents.length);
        }
      }

      if (event == 'party_log') {
        aggiungiLog('[Realtime] $text');
      }
    });

    if (storyNotesRequesterTag.isNotEmpty) {
      unawaited(
        sendRealtimeStorySessionNotesSnapshot(
          targetTag: storyNotesRequesterTag,
        ),
      );
    }
    if (recipesRequesterTag.isNotEmpty) {
      unawaited(sendRealtimeRecipesSnapshot(targetTag: recipesRequesterTag));
    }
    if (persistStoryNotes) scheduleStorySessionNotesSave();
    if (persistRecipes) {
      programmaSalvataggio(invalidateCaches: false);
    }

    if (persistRealtimeRemote) {
      applyingRealtimeRemoteSheet = true;
      unawaited(
        salvaDatiSoloLocale().whenComplete(() {
          applyingRealtimeRemoteSheet = false;
        }),
      );
    }
  }

  void rememberRealtimeDungeonHost(Map<String, dynamic> payload) {
    final kind = '${payload['kind'] ?? ''}';
    final sessionId = '${payload['sessionId'] ?? ''}'.trim();
    final hostId = '${payload['hostId'] ?? ''}'.trim();
    if (kind == 'session_close') {
      realtimeDungeonHosts.removeWhere(
        (key, host) =>
            key == sessionId ||
            (hostId.isNotEmpty && '${host['hostId'] ?? ''}' == hostId),
      );
      return;
    }
    if ((kind != 'session_open' && kind != 'session_state') ||
        sessionId.isEmpty ||
        hostId.isEmpty) {
      return;
    }

    final localId = sheetTagAt(schedaCorrente).trim();
    if (hostId == localId) return;
    final sentAt =
        DateTime.tryParse('${payload['sentAt'] ?? ''}') ?? DateTime.now();
    realtimeDungeonHosts[sessionId] = <String, dynamic>{
      'sessionId': sessionId,
      'hostId': hostId,
      'hostName': '${payload['hostName'] ?? payload['playerName'] ?? hostId}',
      'passwordProtected': payload['passwordProtected'] == true,
      'passwordHash': '${payload['passwordHash'] ?? ''}',
      'seenAt': sentAt.toIso8601String(),
    };
    pruneRealtimeDungeonHosts();
  }

  void pruneRealtimeDungeonHosts() {
    final limit = DateTime.now().subtract(const Duration(minutes: 3));
    realtimeDungeonHosts.removeWhere((_, host) {
      final seenAt = DateTime.tryParse('${host['seenAt'] ?? ''}');
      return seenAt == null || seenAt.isBefore(limit);
    });
  }

  List<Map<String, dynamic>> availableRealtimeDungeonHosts() {
    pruneRealtimeDungeonHosts();
    final hosts = realtimeDungeonHosts.values
        .map((host) => Map<String, dynamic>.from(host))
        .toList();
    hosts.sort(
      (a, b) => '${a['hostName'] ?? ''}'.compareTo('${b['hostName'] ?? ''}'),
    );
    return hosts;
  }

  void requestRealtimeDungeonHosts() {
    final service = realtimeService;
    if (service?.isConnected != true) return;
    unawaited(
      service!.sendDungeonShared(<String, dynamic>{
        'kind': 'session_discover',
        'senderId': sheetTagAt(schedaCorrente),
        'campaignId': activeCampaignId,
        'campaignName': activeCampaignName(),
      }),
    );
  }

  Future<void> showRealtimeDungeonJoinPicker() async {
    if (realtimeService?.isConnected != true) {
      setState(() {
        risultato = t(
          'Connettiti a Realtime prima di cercare una run online.',
          'Connect to Realtime before looking for an online run.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    requestRealtimeDungeonHosts();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final hosts = availableRealtimeDungeonHosts();
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: backgroundMidColor,
        title: Text(
          t('Unisciti alla run', 'Join a run'),
          style: TextStyle(color: primaryColor),
        ),
        content: SizedBox(
          width: min(MediaQuery.of(dialogContext).size.width * 0.88, 460),
          child: hosts.isEmpty
              ? Text(
                  t(
                    'Nessuna run online ha risposto nella tua stanza Realtime. Chiedi all host di aprire il Dungeon online e avviare la run.',
                    'No online run answered in your Realtime room. Ask the host to open Online Dungeon and start the run.',
                  ),
                  style: const TextStyle(color: Colors.white),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: hosts.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final host = hosts[index];
                    final name = '${host['hostName'] ?? '???'}';
                    final protected =
                        host['passwordProtected'] == true ||
                        '${host['passwordHash'] ?? ''}'.trim().isNotEmpty;
                    return ListTile(
                      leading: const Icon(
                        Icons.wifi_tethering,
                        color: Colors.greenAccent,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        protected
                            ? t(
                                'Run online protetta da password',
                                'Password-protected online run',
                              )
                            : t('Run online libera', 'Open online run'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () => Navigator.of(dialogContext).pop(host),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t('Chiudi', 'Close')),
          ),
        ],
      ),
    );
    if (!mounted || selected == null) return;
    _openDungeonMiniGame(openOnlinePanel: true, initialOnlineSession: selected);
  }

  String realtimeEventText(String event, Map<String, dynamic> payload) {
    final player = '${payload['playerName'] ?? '???'}';

    switch (event) {
      case 'hp_changed':
        return '$player HP ${payload['currentHp'] ?? '?'}'
            '/${payload['maxHp'] ?? '?'}'
            ' • Temp ${payload['tempHp'] ?? 0}'
            ' • Scudo ${payload['shield'] ?? 0}'
            '${readIntValue(payload['larvalBroodMaxHp']) > 0 ? " • Nidiata ${payload['larvalBroodHp'] ?? 0}/${payload['larvalBroodMaxHp']}" : ''}';
      case 'oculum_changed':
        return '$player Oculum ${payload['currentOculum'] ?? '?'}'
            '/${payload['maxOculum'] ?? '?'}';
      case 'dice_roll':
        return oculumResolvedRollLog(
          label: '[DADO] $player ${payload['label'] ?? 'tiro'}',
          total: readIntValue(payload['total']),
        );
      case 'party_log':
        return '$player: ${payload['message'] ?? ''}';
      case 'damage_report':
        return '$player dichiara ${payload['formula'] ?? payload['totalDamage'] ?? '?'} '
            '${payload['damageType'] ?? 'Normale'}';
      case 'session_note':
        final note = OculumSessionNote.tryParse(payload);
        if (note == null) return '$player: ${payload['message'] ?? ''}';
        return '${note.author} [${oculumSessionNoteTimeLabel(note.createdAt)}]: '
            '${note.message}';
      case 'session_notes_request':
        return t('$player richiede gli appunti.', '$player requests notes.');
      case 'session_notes_snapshot':
        return t('$player sincronizza gli appunti.', '$player syncs notes.');
      case 'monster_book_snapshot':
        return t(
          '$player sincronizza il Monster Book.',
          '$player syncs the Monster Book.',
        );
      case 'vtt_scene_request':
        return t(
          '$player richiede la scena attiva.',
          '$player requests the active scene.',
        );
      case 'vtt_scene_shared':
        final snapshot = payload['snapshot'];
        final scene = snapshot is Map && snapshot['scene'] is Map
            ? snapshot['scene'] as Map
            : const <dynamic, dynamic>{};
        return t(
          '$player mostra la scena ${scene['name'] ?? 'mappa'}.',
          '$player shares scene ${scene['name'] ?? 'map'}.',
        );
      case 'vtt_asset_chunk':
        return t(
          '$player sincronizza l immagine della scena.',
          '$player syncs the scene image.',
        );
      case 'vtt_token_patch':
        return t(
          '$player muove una pedina sulla mappa.',
          '$player moves a map token.',
        );
      case 'vtt_door_patch':
        return t(
          '$player modifica una porta sulla mappa.',
          '$player changes a map door.',
        );
      case 'vtt_ping':
        return t('$player crea un ping.', '$player creates a ping.');
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
      case 'sheet_received_ack':
        return t(
          '$player conferma ricezione scheda: ${payload['sheetName'] ?? '???'}.',
          '$player confirmed sheet receipt: ${payload['sheetName'] ?? '???'}.',
        );
      case 'initiative_shared':
        if (oculumInitiativePayloadClosesFight(payload)) {
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
      case 'initiative_turn_adjusted':
        return t(
          '$player ha riportato il proprio turno a ${payload['turn'] ?? 0}.',
          '$player reported their turn as ${payload['turn'] ?? 0}.',
        );
      case 'dungeon_shared':
        return t(
          '$player ha aggiornato una run dungeon condivisa.',
          '$player updated a shared dungeon run.',
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
        larvalBroodHp: broodRemainingHp(),
        larvalBroodMaxHp: broodMaximumHp(),
      ),
    );
  }

  void sendRealtimeDamageReport({
    required int baseDamage,
    required int bonusDamage,
    required int totalDamage,
    required String damageType,
  }) {
    final service = realtimeService;
    final formula = bonusDamage == 0
        ? '$baseDamage'
        : '$baseDamage ${bonusDamage >= 0 ? '+' : '-'} ${bonusDamage.abs()}';
    if (service?.isConnected == true) {
      unawaited(
        service!.sendDamageReport(
          baseDamage: baseDamage,
          bonusDamage: bonusDamage,
          totalDamage: totalDamage,
          damageType: damageType,
          formula: formula,
        ),
      );
    }
  }

  Widget realtimeDamageReportOverlay() {
    final report = realtimeDamageReportPopup;
    if (report == null || !haPermessiMaster) return const SizedBox.shrink();
    final player = cleanUiText('${report['playerName'] ?? 'Giocatore'}');
    final formula = cleanUiText(
      '${report['formula'] ?? report['totalDamage'] ?? '?'}',
    );
    final type = cleanUiText('${report['damageType'] ?? 'Normale'}');
    final total = readIntValue(report['totalDamage']);
    return Positioned(
      top: 18,
      right: 18,
      child: SafeArea(
        child: GestureDetector(
          onTap: () => setState(() => realtimeDamageReportPopup = null),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF15131B).withValues(alpha: .97),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: .85),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 16),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$player • COLPITO',
                    style: TextStyle(
                      color: tertiaryColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$formula  •  $type',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'Tocca il riquadro per chiuderlo.',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
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

  void sendRealtimeChatMessage() {
    final service = realtimeService;
    if (service?.isConnected != true) return;

    final message = cleanUiText(realtimeChatController.text).trim();
    if (message.isEmpty) return;

    final signedMessage = '${realtimeDisplayName()}: $message';
    realtimeChatController.clear();
    unawaited(service!.sendPartyLog(signedMessage));
    setState(() {
      realtimeEvents.insert(0, signedMessage);
    });
  }

  bool get realtimeWantsMasterRole => modalitaMaster || isMasterHost;

  bool get realtimeIsMasterRole =>
      realtimeService?.isConnected == true &&
          realtimeService?.authenticatedRole != null
      ? realtimeService!.authenticatedRole == 'master'
      : realtimeWantsMasterRole && !realtimeMasterBlockedByPresence;

  bool get realtimeIsCoMasterRole =>
      realtimeService?.isConnected == true &&
          realtimeService?.authenticatedRole != null
      ? realtimeService!.authenticatedRole == 'coMaster'
      : !realtimeIsMasterRole && sonoCoMaster;

  bool get realtimeCanBrowseOtherSheets =>
      realtimeIsMasterRole || realtimeIsCoMasterRole;

  bool get realtimeHasMasterOnline {
    return realtimeUsers.any((user) => '${user['role'] ?? ''}' == 'master');
  }

  String realtimeLocalRole() {
    if (realtimeIsMasterRole) return 'master';
    if (realtimeIsCoMasterRole) return 'coMaster';
    return 'player';
  }

  void refreshRealtimeRolePresence() {
    final service = realtimeService;
    if (service?.isConnected != true) return;
    setState(() {
      realtimeMasterBlockedByPresence = realtimeShouldYieldMaster(
        realtimeUsers,
      );
    });
    unawaited(service!.refreshPresence());
  }

  void clearRealtimeMasterAckTracking() {
    for (final timer in realtimePendingMasterAckTimers.values) {
      timer.cancel();
    }
    realtimePendingMasterAckTimers.clear();
    realtimePendingMasterAckSheetIds.clear();
    realtimePendingMasterAckAttempts.clear();
    realtimePendingMasterAckHashes.clear();
    realtimePendingPortraitHashes.clear();
    realtimeAcknowledgedPortraitHashes.clear();
  }

  String newRealtimeSheetDeliveryId(String sheetId) {
    return 'sheet_${sheetId}_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';
  }

  void cancelRealtimeMasterAckWatch(String deliveryId) {
    realtimePendingPortraitHashes.remove(deliveryId);
    realtimePendingMasterAckTimers.remove(deliveryId)?.cancel();
    realtimePendingMasterAckSheetIds.remove(deliveryId);
    realtimePendingMasterAckAttempts.remove(deliveryId);
    realtimePendingMasterAckHashes.remove(deliveryId);
  }

  void watchRealtimeMasterAck({
    required String deliveryId,
    required String sheetId,
    required int attempt,
  }) {
    if (deliveryId.isEmpty || sheetId.isEmpty) return;
    realtimePendingMasterAckSheetIds[deliveryId] = sheetId;
    realtimePendingMasterAckAttempts[deliveryId] = attempt;
    realtimePendingMasterAckTimers.remove(deliveryId)?.cancel();
    realtimePendingMasterAckTimers[deliveryId] = Timer(
      // Avoid replaying large sheets every few seconds while the database is
      // degraded. The durable journal retries with capped exponential delay.
      oculumRealtimeSheetAckRetryDelay(attempt),
      () {
        realtimePendingMasterAckTimers.remove(deliveryId);
        if (!mounted) return;
        if (!canShareRealtimeSheetToStaff) {
          cancelRealtimeMasterAckWatch(deliveryId);
          return;
        }
        if (!realtimeHasMasterOnline) {
          cancelRealtimeMasterAckWatch(deliveryId);
          return;
        }
        final sheetIndex = localSheetIndexForOculumTag(sheetId);
        if (sheetIndex < 0) {
          cancelRealtimeMasterAckWatch(deliveryId);
          return;
        }
        sendRealtimeSheetToStaffAt(
          sheetIndex,
          force: true,
          ensureMasterReceipt: true,
          deliveryId: deliveryId,
          attempt: attempt + 1,
        );
      },
    );
  }

  void receiveRealtimeSheetReceivedAck(Map<String, dynamic> payload) {
    if (realtimeIsMasterRole) return;
    final deliveryId = '${payload['deliveryId'] ?? ''}'.trim();
    if (deliveryId.isEmpty) return;

    final ownerTag = normalizeOculumFriendTag(
      '${payload['ownerTag'] ?? payload['sheetId'] ?? ''}',
    ).toUpperCase();
    final localTags = localOculumTags().map((tag) => tag.toUpperCase()).toSet();
    if (!localTags.contains(ownerTag)) return;
    if ((payload['receiverRole'] != 'master' &&
            payload['receiverRole'] != 'coMaster') ||
        realtimePendingMasterAckSheetIds[deliveryId]?.toUpperCase() !=
            ownerTag) {
      return;
    }

    final acknowledgedHash = realtimePendingMasterAckHashes[deliveryId];
    final portraitHash = realtimePendingPortraitHashes.remove(deliveryId);
    if (portraitHash != null) {
      realtimeAcknowledgedPortraitHashes[ownerTag] = portraitHash;
    }
    if (acknowledgedHash != null) {
      rememberRealtimeSheetHash(
        'staff:${realtimePendingMasterAckSheetIds[deliveryId]}',
        acknowledgedHash,
      );
    }
    cancelRealtimeMasterAckWatch(deliveryId);
    final sheetName = '${payload['sheetName'] ?? '???'}';
    risultato = t(
      'Master ha ricevuto la scheda: $sheetName.',
      'Master received the sheet: $sheetName.',
    );
    aggiungiLog(risultato);
  }

  void sendRealtimeMasterSheetAck({
    required Map<String, dynamic> payload,
    required String senderRole,
    required String sheetId,
  }) {
    if (!realtimeIsMasterRole) return;
    if (senderRole != 'player' && senderRole != 'coMaster') return;
    final service = realtimeService;
    if (service?.isConnected != true) return;

    final deliveryId = '${payload['deliveryId'] ?? ''}'.trim();
    if (deliveryId.isEmpty) return;
    final ownerTag = normalizeOculumFriendTag(
      '${payload['ownerTag'] ?? sheetId}',
    );
    if (ownerTag.isEmpty) return;

    unawaited(
      service!.sendSheetReceivedAck(
        deliveryId: deliveryId,
        ownerTag: ownerTag,
        sheetId: sheetId,
        sheetName: '${payload['sheetName'] ?? sheetId}',
        campaignId: '${payload['campaignId'] ?? activeCampaignId}',
        campaignName: '${payload['campaignName'] ?? activeCampaignName()}',
        receiverRole: 'master',
        receiverTag: sheetTagAt(schedaCorrente),
      ),
    );
  }

  bool get canShareRealtimeSheetToStaff {
    return realtimeService?.isConnected == true &&
        realtimeService?.unavailableActiveSheetTag == null &&
        !realtimeIsMasterRole;
  }

  Future<void> showRealtimeSheetIdentityConflict(String conflict) async {
    if (!mounted ||
        normalizeOculumFriendTag(sheetTagAt(schedaCorrente)).toUpperCase() !=
            conflict) {
      return;
    }
    final copy = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Scheda non consegnata al Master'),
        content: const Text(
          'Questo tag è già associato a un altro account nella stanza. '
          'Puoi accedere all’account originale nelle Impostazioni oppure '
          'creare una copia con un nuovo tag per questo personaggio. '
          'Statistiche, immagini e salvataggio originale restano conservati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Più tardi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Crea copia e invia'),
          ),
        ],
      ),
    );
    if (copy != true ||
        !mounted ||
        normalizeOculumFriendTag(sheetTagAt(schedaCorrente)).toUpperCase() !=
            conflict) {
      return;
    }
    await duplicaSchedaCorrente();
    await realtimeService?.refreshPresence();
    await sendRealtimeActiveSheetToStaff();
  }

  Future<void> requestRealtimePlayerSheets() async {
    final service = realtimeService;
    if (service?.isConnected != true || !realtimeCanBrowseOtherSheets) return;
    final sent = await service!.requestSharedSheetsConfirmed();
    if (!mounted || realtimeService != service) return;
    setState(() {
      risultato = sent
          ? 'Richiesta schede consegnata al server. Attendo le schede attive dei player.'
          : 'Richiesta schede non consegnata. Controlla lo stato della connessione.';
      aggiungiLog(risultato);
    });
  }

  Future<void> sendRealtimeCurrentSheetManually() async {
    final service = realtimeService;
    if (service?.isConnected != true || realtimeIsMasterRole) return;
    await service!.refreshPresence();
    if (!mounted || realtimeService != service) return;
    final conflict = service.unavailableActiveSheetTag;
    if (conflict != null) {
      await showRealtimeSheetIdentityConflict(conflict);
      return;
    }
    if (readBoolValue(
      schedePersonaggio[schedaCorrente]['realtimeSharedSheet'],
    )) {
      setState(() {
        risultato =
            'Questa è una scheda ricevuta online. Seleziona la tua scheda per inviarla al Master.';
        aggiungiLog(risultato);
      });
      return;
    }
    final tag = sheetTagAt(schedaCorrente);
    if (realtimeStaffTransfersInFlight[tag] == service) {
      setState(() {
        risultato =
            'Invio della scheda già in corso. Attendo la conferma del Master.';
        aggiungiLog(risultato);
      });
      return;
    }
    final sent = await sendRealtimeSheetToStaffAt(
      schedaCorrente,
      force: true,
      ensureMasterReceipt: true,
    );
    if (!mounted || realtimeService != service) return;
    setState(() {
      // A peer ACK can arrive before the sending RPC finishes.
      final waiting = realtimePendingMasterAckSheetIds.containsValue(tag);
      risultato = !sent
          ? 'Scheda non consegnata al server. Salvataggio locale conservato.'
          : waiting
          ? 'Scheda inviata al server. Attendo la conferma di ricezione del Master.'
          : 'Ricezione della scheda confermata dal Master.';
      aggiungiLog(risultato);
    });
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
      if (targetAudience == 'staff_turn_order') {
        return localRole == 'coMaster';
      }
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
    if (senderRole == 'fullShare') {
      if (ownerTag.isNotEmpty && isOculumFriendBlocked(ownerTag)) return false;
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
    bool includePartyMembers = true,
  }) {
    final safe = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
    oculumRealtimeStripPrivateMerchantState(safe);

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
      'realtimeVisibleInitiativeSnapshot',
      'encounterPlayerIdentities',
      'realtimeOwnerEditSequence',
      'realtimeOwnerEditRoom',
      'realtimeOwnerEditFieldSequences',
      'claimedEncounterRewardIds',
      'diaryEntityRoles',
      'diaryKnowledgeSync',
    ]) {
      safe.remove(key);
    }

    if (!includeImage) {
      safe['immaginePersonaggioBase64'] = '';
    }
    safe['logEventi'] = <String>[];
    if (!includePartyMembers) {
      safe['partyMembri'] = <Map<String, dynamic>>[];
    }
    return safe;
  }

  Map<String, dynamic> realtimePublicSheetJsonAt(int index) {
    final base = sheetRollBonusAt(index, 'iniziativa');
    final tag = sheetTagAt(index);
    final token = masterInitiativeTokens.firstWhere(
      (item) => '${item['sheetTag'] ?? ''}' == tag,
      orElse: () => <String, dynamic>{},
    );

    final title = titoloSempreVisibileSchedaAt(index);
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
      'faunaPublic':
          schedaJsonAt(index)['faunaPublic'] ?? const <String, dynamic>{},
      'precisionBodyParts':
          schedaJsonAt(index)['precisionBodyParts'] ?? const [],
      'publicVisibleTitleName': title?.nome ?? '',
      'publicVisibleTitleLegend': title?.leggenda ?? '',
    };
  }

  /// Adds only the title explicitly chosen as public. The Master receives this
  /// compact snapshot as soon as the player shares or reconnects their sheet.
  void addRealtimePublicTitleSnapshot(Map<String, dynamic> sheet, int index) {
    final title = titoloSempreVisibileSchedaAt(index);
    sheet['publicVisibleTitleName'] = title?.nome ?? '';
    sheet['publicVisibleTitleLegend'] = title?.leggenda ?? '';
    sheet['publicAccountDisplayName'] = realtimeNameController.text.trim();
  }

  String realtimeSharedSheetKey({
    required String ownerTag,
    required String campaignId,
    required String sheetId,
    String senderUserId = '',
  }) {
    final legacyKey =
        '${ownerTag.trim()}|${campaignId.trim()}|${sheetId.trim()}';
    final sender = senderUserId.trim();
    return sender.isEmpty ? legacyKey : '$sender|$legacyKey';
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
    oculumRealtimeStripPrivateMerchantState(sheet);
    final existingProfiles =
        existingIndex != null &&
            existingIndex >= 0 &&
            existingIndex < schedePersonaggio.length &&
            schedePersonaggio[existingIndex]['merchantProfiles'] is List
        ? (schedePersonaggio[existingIndex]['merchantProfiles'] as List)
              .whereType<Map>()
              .map((profile) => Map<String, dynamic>.from(profile))
              .toList()
        : <Map<String, dynamic>>[];
    final profilesWithRemoteRoster = oculumRealtimeMergeMerchantRoster(
      existingProfiles,
      sheet['merchantProfiles'],
    );
    sheet['merchantProfiles'] = oculumRealtimeMergeMerchantRoster(
      profilesWithRemoteRoster,
      oculumRealtimeMerchantRosterProjection(merchantProfiles),
    );

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
    if (realtimeIsMasterRole || realtimeIsCoMasterRole) {
      const folderId = 'oculum_received_online_sheets';
      sheetSidebarFolders.removeWhere((folder) => folder['id'] == folderId);
      sheetSidebarFolders.add({
        'id': folderId,
        'name': 'Online',
        'parent': '',
        'expanded': true,
      });
      sheetSidebarPlacements[localTag] = {
        'folder': folderId,
        'order': DateTime.now().microsecondsSinceEpoch.toDouble(),
      };
      sheetSidebarRevision.value++;
    }
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
    final campaignId = '${payload['campaignId'] ?? ''}'.trim().isEmpty
        ? 'online'
        : '${payload['campaignId'] ?? ''}'.trim();
    final senderUserId = '${payload['authenticatedUserId'] ?? ''}'.trim();
    final key = realtimeSharedSheetKey(
      ownerTag: normalizeOculumFriendTag('${payload['ownerTag'] ?? sheetId}'),
      campaignId: campaignId,
      sheetId: normalizeOculumFriendTag(sheetId),
      senderUserId: senderUserId,
    );
    var localIndex = realtimeLocalSheetIndexForKey(key);
    final secureStaffEdit =
        const {'master', 'coMaster'}.contains(payload['authenticatedRole']) &&
        (realtimeService?.channelName.startsWith('oculum_secure_') ?? false) &&
        readIntValue(payload['serverSequence']) > 0;
    if (localIndex < 0 && (senderUserId.isEmpty || secureStaffEdit)) {
      localIndex = localSheetIndexForOculumTag(sheetId);
    }
    if (localIndex < 0) return false;

    final existing = Map<String, dynamic>.from(schedePersonaggio[localIndex]);
    final localTag = normalizeOculumFriendTag(
      '${existing['sheetTag'] ?? existing['id'] ?? sheetId}',
    );

    final editRoom = realtimeService?.channelName ?? '';
    final editSequence = oculumRealtimeStaffOwnerEditSequence(
      existing,
      payload,
      editRoom,
    );
    // A local autosave can run after the Master sent this patch but before
    // delivery. Its wall clock is not an authoritative version of the edit.
    // Only verified staff edits to the owner's sheet use the server order;
    // locally edited shared copies retain their existing dirty-data guard.
    final stale =
        editSequence == null &&
        realtimeRemoteIsStaleForLocal(existing, payload);
    if (stale) {
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
    final fieldSequences = <String, dynamic>{
      if (existing['realtimeOwnerEditRoom'] == editRoom &&
          existing['realtimeOwnerEditFieldSequences'] is Map)
        ...Map<String, dynamic>.from(
          existing['realtimeOwnerEditFieldSequences'] as Map,
        ),
    };
    final acceptedKeys = editSequence != null
        ? sheet.keys
              .where(
                (key) =>
                    oculumRealtimePatchValueCanApply(
                      key,
                      sheet[key],
                      existing,
                      allowClearFields: allowClearFields,
                    ) &&
                    editSequence > readIntValue(fieldSequences[key]),
              )
              .toList()
        : appliedKeys;
    if (editSequence != null) {
      // Independent HP/shield edits may arrive out of order. Reject only
      // superseded fields, retaining a newer edit to every other field.
      appliedKeys.removeWhere((key) => !acceptedKeys.contains(key));
    }
    if (acceptedKeys.isEmpty) {
      aggiungiLog(
        t(
          'Realtime ignorato: patch vuota o protetta per ${existing['nome'] ?? '???'}.',
          'Realtime ignored: empty or protected patch for ${existing['nome'] ?? '???'}.',
        ),
      );
      return false;
    }

    final updated = oculumRealtimeMergeSheetPatch(existing, {
      for (final key in appliedKeys) key: sheet[key],
    }, allowClearFields: allowClearFields);

    updated['id'] = localTag;
    updated['sheetTag'] = localTag;
    if (editSequence != null) {
      updated['realtimeOwnerEditSequence'] = max(
        editSequence,
        existing['realtimeOwnerEditRoom'] == editRoom
            ? readIntValue(existing['realtimeOwnerEditSequence'])
            : 0,
      );
      updated['realtimeOwnerEditRoom'] = editRoom;
      updated['realtimeOwnerEditFieldSequences'] = {
        ...fieldSequences,
        // Even an unchanged value confirms a newer revision of that field.
        for (final key in acceptedKeys) key: editSequence,
      };
    }
    final remoteAt = realtimeIsoDate(payload['sentAt']);
    final localAt = realtimeIsoDate(existing['localUpdatedAt']);
    updated['localUpdatedAt'] =
        editSequence != null &&
            remoteAt != null &&
            localAt != null &&
            localAt.isAfter(remoteAt)
        ? existing['localUpdatedAt']
        : '${payload['sentAt'] ?? DateTime.now().toIso8601String()}';
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
    final deathOutcome = linguaInglese
        ? '${updated['realtimeDeathOutcomeEn'] ?? ''}'.trim()
        : '${updated['realtimeDeathOutcomeIt'] ?? ''}'.trim();
    if (deathOutcome.isNotEmpty) {
      risultato = deathOutcome;
      aggiungiLog(
        '${t('Esito combattimento ricevuto', 'Combat result received')}: $deathOutcome',
      );
    }
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
      'vcRapido': vcRapidoController,
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
    final senderRole = '${payload['senderRole'] ?? ''}';
    if (!validPermissionSender(payload, staff: true) ||
        (senderRole != 'master' &&
            !trustedCoMasterTags.contains(
              '$permissionScope:${payload['senderTag']}',
            ))) {
      return;
    }
    final targetTag = normalizeOculumFriendTag('${payload['targetTag'] ?? ''}');
    if (targetTag.isEmpty) return;

    final trustKey = '$permissionScope:$targetTag';
    // Only the Master can grant or revoke the trusted delegation.
    if (senderRole == 'master') {
      if (readBoolValue(payload['trusted']) &&
          readBoolValue(payload['coMaster'])) {
        trustedCoMasterTags.add(trustKey);
      } else {
        trustedCoMasterTags.remove(trustKey);
      }
    }

    final matchesLocal = ownPermissionTags
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
    coMasterCanSetCoMaster = coMaster && trustedCoMasterTags.contains(trustKey);
    coMasterCanEditSheets = coMaster;
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
    captureActiveMasterInitiativeGroup();
    final published = masterInitiativeGroups
        .where((group) => readBoolValue(group['published']))
        .map((group) => publicEncounterSnapshot(group))
        .toList();
    final root = published.firstWhere(
      (group) => group['encounterId'] == selectedMasterInitiativeGroupId,
      orElse: () => published.isNotEmpty
          ? published.first
          : <String, dynamic>{
              'tokens': [],
              'round': 1,
              'activeIndex': 0,
              'turnCount': 0,
            },
    );
    return {
      ...root,
      'campaignId': activeCampaignId,
      'campaignName': activeCampaignName(),
      'encounters': published,
      'completedEncounterRewards': [
        for (final g in masterInitiativeGroups)
          ...(g['rewards'] as List? ?? []),
      ],
      'sentAt': DateTime.now().toIso8601String(),
    };
  }

  String publicInitiativeSourceTag(Map<String, dynamic> token) {
    final tag = '${token['sheetTag'] ?? token['id'] ?? ''}';
    final index = schedePersonaggio.indexWhere(
      (sheet) => '${sheet['sheetTag'] ?? sheet['id'] ?? ''}' == tag,
    );
    if (index >= 0) {
      final source =
          '${schedePersonaggio[index]['realtimeSourceSheetTag'] ?? ''}';
      if (source.isNotEmpty) return source;
    }
    return tag;
  }

  Map<String, dynamic> publicEncounterSnapshot(Map<String, dynamic> group) {
    final tokens = (group['tokens'] as List? ?? const [])
        .whereType<Map>()
        .map((token) => Map<String, dynamic>.from(token))
        .toList();
    final active = tokens.isEmpty
        ? 0
        : readIntValue(group['activeIndex']).clamp(0, tokens.length - 1);
    final round = readIntValue(group['round']);
    final turnKey = '$round';
    return {
      'campaignId': activeCampaignId,
      'campaignName': activeCampaignName(),
      'encounterId': group['id'],
      'completedFightCount': readIntValue(group['completedFightCount']),
      'combatEnded': group['combatEnded'] == true,
      if (group.containsKey('fightStarted'))
        'fightStarted': group['fightStarted'] == true,
      'mergedEncounterIds': group['mergedEncounterIds'] ?? const <String>[],
      if (group['chainedFate'] is Map) 'chainedFate': group['chainedFate'],
      if (group['rollRequests'] is List) 'rollRequests': group['rollRequests'],
      'name': group['name'],
      'round': group['round'],
      'activeIndex': active,
      'turnCount': tokens.length,
      'manualOrder': group['manualOrder'],
      'tokens': [
        for (int i = 0; i < tokens.length; i++)
          <String, dynamic>{
            ...oculumPublicEncounterIdentity(tokens[i]),
            'index': i + 1,
            'turnNumber': i + 1,
            'turnCount': tokens.length,
            'id': publicInitiativeSourceTag(tokens[i]),
            if (monsterBookIdForCombatToken(tokens[i]).isNotEmpty)
              'monsterBookId': monsterBookIdForCombatToken(tokens[i]),
            'name': oculumReferenceEncounterTokenName(tokens[i]),
            'type': '${tokens[i]['type'] ?? 'Partecipante'}',
            'side': '${tokens[i]['side'] ?? 'ally'}',
            'status': '${tokens[i]['status'] ?? 'ready'}',
            'corruptedByTag': corruptionOwnerForToken(tokens[i]),
            'targetControlChancePercent': corruptionControlChanceForToken(
              tokens[i],
            ),
            'healthLabel': oculumCombatHealthLabel(
              readIntValue(tokens[i]['currentHp']),
              readIntValue(tokens[i]['maxHp']),
            ),
            'spriteAssetPath': masterInitiativeTokenSpriteAsset(tokens[i]),
            'tokenSize': masterInitiativeTokenSize(tokens[i]),
            'initiativeRoll': readIntValue(tokens[i]['initiativeRoll']),
            'initiativeBase': readIntValue(tokens[i]['initiativeBase']),
            'initiativeTotal': readIntValue(tokens[i]['initiativeTotal']),
            'reflexes': readIntValue(tokens[i]['reflexes']),
            if (readBoolValue(tokens[i]['oculumShadowClone'])) ...{
              'oculumShadowClone': true,
              'shadowCloneTurnsRemaining': readIntValue(
                tokens[i]['shadowCloneTurnsRemaining'],
              ),
              'shadowCloneExpired': readBoolValue(
                tokens[i]['shadowCloneExpired'],
              ),
            },
            'reportedTurn': max(0, readIntValue(tokens[i]['reportedTurn'])),
            'actionUsed': readBoolValue(tokens[i]['actionUsed']),
            'reactionMax': max(
              1,
              readIntValue(tokens[i]['reactionMax'], fallback: 1),
            ),
            'reactionFastMax': max(
              1,
              readIntValue(tokens[i]['reactionFastMax'], fallback: 1),
            ),
            'extraFastReactionCurrent': readIntValue(
              tokens[i]['extraFastReactionCurrent'],
            ),
            'extraNormalReactionCurrent': readIntValue(
              tokens[i]['extraNormalReactionCurrent'],
            ),
            'extraNormalReactionQueued': readIntValue(
              tokens[i]['extraNormalReactionQueued'],
            ),
            'reactionUsed': masterInitiativeReactionUsed(
              tokens[i],
              round: round,
            ),
            'reactionUsedRound': readIntValue(
              tokens[i]['reactionUsedRound'],
              fallback: round,
            ),
            'reactionFastUsed': masterInitiativeFastReactionUsedThisTurn(
              tokens[i],
              turnKey: turnKey,
            ),
            'reactionFastTurnKey': '${tokens[i]['reactionFastTurnKey'] ?? ''}',
            'reactionPoolInitialized': readBoolValue(
              tokens[i]['reactionPoolInitialized'],
            ),
            'reactionPoolRound': readIntValue(tokens[i]['reactionPoolRound']),
            'reactionNormalFirstRoundLocked': readBoolValue(
              tokens[i]['reactionNormalFirstRoundLocked'],
            ),
            'actionTurnRound': readIntValue(
              tokens[i]['actionTurnRound'],
              fallback: -1,
            ),
            'pendingReactionRollBonus': readIntValue(
              tokens[i]['pendingReactionRollBonus'],
            ).clamp(0, 12),
            'pendingFastReactionRollBonus': readIntValue(
              tokens[i]['pendingFastReactionRollBonus'],
            ).clamp(0, 6),
            'pendingFastReactionConsequenceBonus': readIntValue(
              tokens[i]['pendingFastReactionConsequenceBonus'],
            ),
            'oblivionMemoryReactionLost':
                tokens[i]['oblivionMemoryReactionLost'] == true,
            for (final key in [
              'mechaReactionOnly',
              'mechaCriticalOnly',
              'mechaOccupied',
              'mechaPilotExtra',
              'mechaPilotCritical',
            ])
              if (tokens[i].containsKey(key)) key: tokens[i][key],
            'initialFastReactionExpired':
                tokens[i]['initialFastReactionExpired'] == true,
            'fastReactionPersonalTurnRound': readIntValue(
              tokens[i]['fastReactionPersonalTurnRound'],
              fallback: -1,
            ),
            'actionAnticipatedRound': readIntValue(
              tokens[i]['actionAnticipatedRound'],
              fallback: -1,
            ),
            'freeReactionUsed': readBoolValue(tokens[i]['freeReactionUsed']),
            'reactionAvailable': masterInitiativeReactionAvailable(
              tokens[i],
              round: round,
              turnKey: turnKey,
            ),
            'active': i == active,
            ...oculumPublicEncounterIdentity(tokens[i]),
            // Portraits remain in sheet/token sharing. Keep the authoritative
            // turn state below the RPC limit even with many large portraits.
            'imageBase64': '${tokens[i]['imageBase64'] ?? ''}'.length <= 4096
                ? '${tokens[i]['imageBase64'] ?? ''}'
                : '',
          },
      ],
    };
  }

  String realtimeEncounterPortrait(Map<String, dynamic> token) {
    final embedded = '${token['imageBase64'] ?? ''}';
    if (embedded.isNotEmpty) return embedded;
    final tag = normalizeOculumFriendTag(
      '${token['sheetTag'] ?? token['id'] ?? ''}',
    ).toUpperCase();
    if (tag.isEmpty) return '';
    // These records have already passed room/recipient authorization. Reuse
    // their portrait rather than embedding it in every round/turn update.
    for (final record in realtimeSharedSheets.reversed) {
      if (normalizeOculumFriendTag(
            '${record['sheetId'] ?? ''}',
          ).toUpperCase() !=
          tag) {
        continue;
      }
      final sheet = record['sheet'];
      if (sheet is Map) {
        final image = '${sheet['immaginePersonaggioBase64'] ?? ''}';
        if (image.isNotEmpty) return image;
      }
    }
    final index = localSheetIndexForOculumTag(tag);
    return index >= 0 ? sheetImageBase64At(index) : '';
  }

  void receiveRealtimeInitiativeSnapshot(Map<String, dynamic> payload) {
    final senderRole = '${payload['senderRole'] ?? ''}';
    if (realtimeIsMasterRole || senderRole != 'master') return;
    final session = '${payload['sessionId'] ?? ''}';
    final revision = readIntValue(payload['revision']);
    final serverSequence = readIntValue(payload['serverSequence']);
    if (serverSequence > 0 &&
        serverSequence <= realtimeInitiativeServerSequence) {
      return;
    }
    if (session.isNotEmpty) {
      final authenticatedUserId = '${payload['authenticatedUserId'] ?? ''}'
          .trim();
      final restoredSnapshot = readBoolValue(payload['restoredSnapshot']);
      if (restoredSnapshot) {
        // This payload came from the room event table under member RLS; the
        // database stamps authenticatedRole and prevents players forging this
        // event. It may belong to a Master session that has since reconnected
        // with a new session id, or is temporarily offline.
        if (payload['authenticatedRole'] != 'master' ||
            authenticatedUserId.isEmpty) {
          return;
        }
      } else if (!realtimeUsers.any((user) {
        if (user['role'] != 'master') return false;
        if (user['sessionId'] == session) return true;
        return authenticatedUserId.isNotEmpty &&
            '${user['userId'] ?? ''}' == authenticatedUserId;
      })) {
        return;
      }
      if (session == realtimeInitiativeSession &&
          revision <= realtimeInitiativeRevision) {
        return;
      }
    }
    final masterCampaign = realtimeUsers
        .where(
          (user) => user['role'] == 'master' && user['sessionId'] == session,
        )
        .map((user) => '${user['campaignId'] ?? ''}')
        .where((id) => id.isNotEmpty)
        .firstOrNull;
    if (masterCampaign != null &&
        '${payload['campaignId'] ?? masterCampaign}' != masterCampaign) {
      return;
    }
    if (session.isNotEmpty) {
      realtimeInitiativeSession = session;
      realtimeInitiativeRevision = revision;
    }
    if (serverSequence > 0) realtimeInitiativeServerSequence = serverSequence;

    if (oculumInitiativePayloadClosesFight(payload)) {
      expireSummoningEmblems(onlineCombatEncounterId);
      realtimeOutgoingEncounterJoins.clear();
      realtimeEncounterJoinRetryTimer?.cancel();
      realtimeEncounterJoinRetryTimer = null;
      forgetCombatDiscoveries(onlineCombatEncounterId);
      realtimeVisibleInitiativeSnapshot = <String, dynamic>{};
      realtimeEncounterSnapshots = <Map<String, dynamic>>[];
      realtimeSelectedEncounterId = '';
      clearTemporaryCombatResistanceEffects();
      risultato = t('Fight chiusa dal Master.', 'Fight closed by the Master.');
      aggiungiLog(risultato);
      return;
    }

    final snapshotRaw = payload['snapshot'];
    if (snapshotRaw is! Map) return;
    if (snapshotRaw['campaignId'] != null &&
        snapshotRaw['campaignId'] != payload['campaignId']) {
      return;
    }
    receiveEncounterRewards(
      (snapshotRaw['completedEncounterRewards'] as List? ?? [])
          .whereType<Map>(),
    );
    final encountersRaw = snapshotRaw['encounters'];
    var selectedSnapshot = Map<String, dynamic>.from(snapshotRaw);
    if (encountersRaw is List) {
      realtimeEncounterSnapshots = encountersRaw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      selectedSnapshot = oculumSelectSharedEncounter(
        realtimeEncounterSnapshots,
        sheetTag: sheetTagAt(schedaCorrente),
        selectedId: realtimeSelectedEncounterId,
        staff: realtimeIsCoMasterRole,
      );
      realtimeSelectedEncounterId = '${selectedSnapshot['encounterId'] ?? ''}';
    }
    final previous = realtimeVisibleInitiativeSnapshot['tokens'];
    final deadBefore = previous is List
        ? previous
              .whereType<Map>()
              .where((t) => t['status'] == 'dead')
              .map((t) => '${t['id']}')
              .toSet()
        : <String>{};
    final incoming = selectedSnapshot['tokens'];
    if (incoming is List) {
      for (final token in incoming.whereType<Map>()) {
        if (token['status'] == 'dead' &&
            !deadBefore.contains('${token['id']}')) {
          aggiungiLog(
            '[MORTE] '
            '${token['name'] ?? '???'} · segnata dal Master.',
          );
        }
      }
    }
    realtimeVisibleInitiativeSnapshot =
        jsonDecode(
              jsonEncode({
                ...selectedSnapshot,
                'campaignId': payload['campaignId'],
                'campaignName': payload['campaignName'],
              }),
            )
            as Map<String, dynamic>;
    if (realtimeVisibleInitiativeSnapshot['combatEnded'] == true) {
      clearTemporaryCombatResistanceEffects();
    }
    final turnTokens = realtimeVisibleInitiativeSnapshot['tokens'];
    if (turnTokens is List && turnTokens.isNotEmpty) {
      final activeIndex = readIntValue(
        realtimeVisibleInitiativeSnapshot['activeIndex'],
      ).clamp(0, turnTokens.length - 1);
      final active = turnTokens[activeIndex];
      if (active is Map) {
        final activeTag = '${active['sheetTag'] ?? active['id'] ?? ''}';
        final turnKey =
            '${realtimeVisibleInitiativeSnapshot['encounterId'] ?? ''}:'
            '${readIntValue(realtimeVisibleInitiativeSnapshot['round'])}:'
            '${active['id'] ?? activeTag}';
        if (turnKey != realtimeLoggedInitiativeTurnKey) {
          realtimeLoggedInitiativeTurnKey = turnKey;
          if (activeTag == sheetTagAt(schedaCorrente)) {
            aggiungiLog(
              '[TURNISTICA] È il tuo turno: ${oculumReferenceEncounterTokenName(active)}. Azione disponibile.',
            );
          }
        }
      }
    } else {
      realtimeLoggedInitiativeTurnKey = '';
    }
    applyChainedFateCompletion(selectedSnapshot);
    receiveMasterRollRequests(selectedSnapshot);
    final aliases = (selectedSnapshot['mergedEncounterIds'] as List? ?? [])
        .whereType<String>()
        .toSet();
    mergeCombatDiscoveries(aliases, '${selectedSnapshot['encounterId']}');
    final mergedTags = (selectedSnapshot['tokens'] as List? ?? [])
        .whereType<Map>()
        .map((t) => '${t['sheetTag'] ?? t['id']}')
        .toSet();
    for (final request in onlineCombatRequests.values) {
      if (aliases.contains('${request['encounterId']}') &&
          mergedTags.contains('${request['sourceTag']}') &&
          mergedTags.contains('${request['targetTag']}')) {
        request['encounterId'] = selectedSnapshot['encounterId'];
      }
    }
    syncCurrentSheetEncounterTurn();
    syncOwnedEncounterTurns();
    shareOwnedEncounterSheetsToStaff();
    unawaited(retryPendingEncounterJoins());
    unawaited(replayOnlineCombatRequests());
    final realtimeTokens = realtimeVisibleInitiativeSnapshot['tokens'];
    if (realtimeTokens is! List || realtimeTokens.isEmpty) {
      clearTemporaryCombatResistanceEffects();
    }
    notifyActiveSheetSummaryChanged();
    risultato = t(
      'Fight aggiornata dal Master.',
      'Fight updated by the Master.',
    );
    aggiungiLog(risultato);
  }

  void syncCurrentSheetEncounterTurn() {
    final currentTag = sheetTagAt(schedaCorrente);
    final snapshotTokens = realtimeVisibleInitiativeSnapshot['tokens'];
    if (snapshotTokens is List) {
      for (final raw in snapshotTokens.whereType<Map>()) {
        final token = Map<String, dynamic>.from(raw);
        if ('${token['sheetTag'] ?? token['id'] ?? ''}' != currentTag) {
          continue;
        }
        final reported = max(0, readIntValue(token['reportedTurn']));
        setPlayerReportedTurn(reported, broadcast: false);
        break;
      }
    }
  }

  Future<void> requestVisibleEncounterStep(int delta) async {
    if (!realtimeIsCoMasterRole ||
        realtimeService?.isConnected != true ||
        !const {-1, 1}.contains(delta)) {
      return;
    }
    final snapshot = realtimeVisibleInitiativeSnapshot;
    final raw = snapshot['tokens'];
    if (raw is! List || raw.isEmpty) return;
    final active = readIntValue(
      snapshot['activeIndex'],
    ).clamp(0, raw.length - 1);
    final delivered = await realtimeService!.sendCombatEvent(
      'initiative_control',
      permissionEnvelope({
        'id':
            'initiative:${DateTime.now().microsecondsSinceEpoch}:${sheetTagAt(schedaCorrente)}',
        'encounterId': snapshot['encounterId'],
        'expectedRound': readIntValue(snapshot['round']),
        'expectedActiveTag': '${(raw[active] as Map)['id'] ?? ''}',
        'delta': delta,
      }),
    );
    if (!mounted) return;
    aggiungiLog(
      delivered
          ? '[TURNISTICA] Comando inviato al Master; attendo lo stato condiviso.'
          : '[TURNISTICA] Comando non consegnato: nessun turno locale modificato.',
    );
  }

  void receiveEncounterControl(Map<String, dynamic> payload) {
    if (!realtimeIsMasterRole || !validPermissionSender(payload, staff: true)) {
      return;
    }
    final id = '${payload['id'] ?? ''}';
    final delta = readIntValue(payload['delta']);
    if (!id.startsWith('initiative:') ||
        id.length > 160 ||
        onlineCombatRequests.containsKey(id) ||
        !const {-1, 1}.contains(delta)) {
      return;
    }
    final group = masterInitiativeGroups
        .where(
          (g) =>
              g['id'] == payload['encounterId'] &&
              readBoolValue(g['published']),
        )
        .firstOrNull;
    if (group == null) return;
    final previous = selectedMasterInitiativeGroupId;
    captureActiveMasterInitiativeGroup();
    selectMasterInitiativeGroup('${group['id']}');
    try {
      final active = masterInitiativeTokens.isEmpty
          ? null
          : masterInitiativeTokens[masterInitiativeActiveIndex.clamp(
              0,
              masterInitiativeTokens.length - 1,
            )];
      if (active == null ||
          readIntValue(payload['expectedRound']) != masterInitiativeRound ||
          '${payload['expectedActiveTag']}' !=
              publicInitiativeSourceTag(active)) {
        return;
      }
      onlineCombatRequests[id] = {
        'id': id,
        'type': 'initiative_control',
        'status': 'resolved',
        'scope': permissionScope,
      };
      while (onlineCombatRequests.length > 200) {
        final old = onlineCombatRequests.entries
            .where((e) => e.value['status'] != 'pending')
            .firstOrNull;
        if (old == null) break;
        onlineCombatRequests.remove(old.key);
      }
      nextMasterInitiativeTurn(delta: delta);
      aggiungiLog(
        '[TURNISTICA] ${payload['playerName'] ?? 'Co-Master'} ha cambiato il turno di ${group['name'] ?? group['id']}.',
      );
      captureActiveMasterInitiativeGroup();
    } finally {
      if (selectedMasterInitiativeGroupId != previous) {
        selectMasterInitiativeGroup(previous);
      }
      sendRealtimeInitiativeSnapshotIfPublished();
    }
  }

  void sendRealtimeReportedTurn({
    required String sheetTag,
    required int turn,
    required String senderRole,
  }) {
    final service = realtimeService;
    if (service?.isConnected != true) return;
    unawaited(
      service!.sendInitiativeTurnAdjusted(
        senderRole: senderRole,
        campaignId: activeCampaignId,
        campaignName: activeCampaignName(),
        sheetTag: sheetTag,
        encounterId: realtimeIsMasterRole
            ? selectedMasterInitiativeGroupId
            : realtimeSelectedEncounterId,
        turn: max(0, turn),
      ),
    );
  }

  void receiveRealtimeReportedTurn(Map<String, dynamic> payload) {
    final targetTag = '${payload['sheetTag'] ?? ''}'.trim();
    if (targetTag.isEmpty) return;
    final turn = max(0, readIntValue(payload['turn']));
    final senderRole = '${payload['senderRole'] ?? 'player'}';
    if (realtimeIsMasterRole && senderRole != 'master') {
      final session = '${payload['sessionId'] ?? ''}';
      final ownsSheet = oculumRealtimePresenceOwnsSheet(
        realtimeUsers,
        payload,
        targetTag,
      );
      if (!ownsSheet &&
          session.isNotEmpty &&
          readBoolValue(payload['joinEncounter']) &&
          payload['campaignId'] == activeCampaignId &&
          realtimePendingEncounterJoins.length < 100) {
        realtimePendingEncounterJoins['${payload['encounterId']}:$targetTag'] =
            Map<String, dynamic>.from(payload);
      }
      if (!ownsSheet ||
          '${payload['campaignId'] ?? ''}' != activeCampaignId ||
          (!readBoolValue(payload['joinEncounter']) &&
              !readBoolValue(payload['leaveEncounter']))) {
        return;
      }
      final requestedId = '${payload['encounterId'] ?? ''}';
      if (requestedId.isEmpty) return;
      final previousGroup = selectedMasterInitiativeGroupId;
      if (requestedId.isNotEmpty) {
        final group = masterInitiativeGroups
            .where(
              (item) =>
                  item['id'] == requestedId && readBoolValue(item['published']),
            )
            .firstOrNull;
        if (group == null) return;
        selectMasterInitiativeGroup(requestedId);
      }

      if (readBoolValue(payload['leaveEncounter'])) {
        final ownedSheet = schedePersonaggio
            .where(
              (sheet) =>
                  sheet['realtimeSourceSheetTag'] == targetTag &&
                  '${sheet['realtimeOwnerName'] ?? ''}' ==
                      '${payload['playerName'] ?? ''}' &&
                  '${sheet['realtimeOwnerName'] ?? ''}'.isNotEmpty,
            )
            .firstOrNull;
        if (ownedSheet != null) {
          final index = masterInitiativeTokens.indexWhere(
            (token) => publicInitiativeSourceTag(token) == targetTag,
          );
          if (index >= 0) removeMasterInitiativeTokenAt(index);
        }
        if (requestedId.isNotEmpty) selectMasterInitiativeGroup(previousGroup);
        notifyActiveSheetSummaryChanged();
        return;
      }
      if (readBoolValue(payload['joinEncounter'])) {
        final sheetIndex = schedePersonaggio.indexWhere(
          (sheet) =>
              sheet['realtimeSourceSheetTag'] == targetTag ||
              sheet['sheetTag'] == targetTag,
        );
        if (sheetIndex < 0) {
          if (realtimePendingEncounterJoins.length < 100) {
            realtimePendingEncounterJoins['$requestedId:$targetTag'] =
                Map<String, dynamic>.from(payload);
          }
          unawaited(
            realtimeService?.requestSharedSheets(targetSheetTag: targetTag),
          );
        }
        if (sheetIndex >= 0 &&
            !masterInitiativeTokens.any(
              (token) =>
                  normalizeOculumFriendTag(
                    publicInitiativeSourceTag(token),
                  ).toUpperCase() ==
                  normalizeOculumFriendTag(targetTag).toUpperCase(),
            )) {
          addSheetToMasterInitiative(sheetIndex);
        }
        captureActiveMasterInitiativeGroup();
        if (requestedId.isNotEmpty) selectMasterInitiativeGroup(previousGroup);
        sendRealtimeInitiativeSnapshotIfPublished();
        return;
      }
      final index = masterInitiativeTokens.indexWhere(
        (token) => publicInitiativeSourceTag(token).trim() == targetTag,
      );
      if (index < 0) {
        if (requestedId.isNotEmpty) selectMasterInitiativeGroup(previousGroup);
        return;
      }
      masterInitiativeTokens[index]['reportedTurn'] = turn;
      masterInitiativeTokens[index]['updatedAt'] = DateTime.now()
          .toIso8601String();
      captureActiveMasterInitiativeGroup();
      if (requestedId.isNotEmpty) selectMasterInitiativeGroup(previousGroup);
      programmaSalvataggio(invalidateCaches: false);
      sendRealtimeInitiativeSnapshotIfPublished();
      return;
    }
    if (!realtimeIsMasterRole &&
        senderRole == 'master' &&
        targetTag == sheetTagAt(schedaCorrente)) {
      if ('${payload['campaignId'] ?? ''}' != permissionCampaignId) return;
      if (!realtimeUsers.any(
        (user) =>
            user['role'] == 'master' &&
            (payload['sessionId'] == null ||
                user['sessionId'] == payload['sessionId']),
      )) {
        return;
      }
      setPlayerReportedTurn(turn, broadcast: false);
    }
  }

  void sendRealtimeInitiativeSnapshot({bool close = false}) {
    final service = realtimeService;
    if (service?.isConnected != true || !realtimeIsMasterRole) return;
    if (!close) sendRealtimeStaffTurnOrderSheets();

    unawaited(
      service!.sendInitiativeSnapshot(
        snapshot: buildRealtimeInitiativeSnapshot(),
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
      realtimeHiddenEncounterIds.remove(selectedMasterInitiativeGroupId);
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
    realtimeHiddenEncounterIds.add(selectedMasterInitiativeGroupId);
    if (realtimeService?.isConnected != true || !realtimeIsMasterRole) {
      setState(() {
        masterInitiativePublished = false;
        clearTemporaryCombatResistanceEffects();
      });
      programmaSalvataggio();
      return;
    }

    setState(() {
      masterInitiativePublished = false;
      clearTemporaryCombatResistanceEffects();
      risultato = t('Fight chiusa per i player.', 'Fight closed for players.');
      aggiungiLog(risultato);
    });
    sendRealtimeInitiativeSnapshot(close: true);
    programmaSalvataggio();
  }

  void sendRealtimeInitiativeSnapshotIfPublished() {
    if (realtimeService?.isConnected == true &&
        realtimeIsMasterRole &&
        masterInitiativeTokens.isNotEmpty &&
        !realtimeHiddenEncounterIds.contains(selectedMasterInitiativeGroupId)) {
      // An online Master encounter must not need a second, manual Publish
      // operation before players can see its turns and choose targets.
      masterInitiativePublished = true;
    }
    captureActiveMasterInitiativeGroup();
    if (!masterInitiativeGroups.any(
      (group) => readBoolValue(group['published']),
    )) {
      return;
    }
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
            includePartyMembers: true,
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
        targetAudience != 'staff_turn_order' &&
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
      senderUserId: '${payload['authenticatedUserId'] ?? ''}',
    );
    final record = <String, dynamic>{
      'key': key,
      'senderUserId': '${payload['authenticatedUserId'] ?? ''}',
      'ownerName':
          '${sheet['publicAccountDisplayName'] ?? ''}'.trim().isNotEmpty
          ? '${sheet['publicAccountDisplayName']}'
          : '${sheet['publicVisibleTitleName'] ?? ''}',
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
    final portraitReference = '${sheet['realtimePortraitReference'] ?? ''}';
    if (portraitReference.isNotEmpty) {
      final oldSheet = remoteIndex >= 0
          ? realtimeSharedSheets[remoteIndex]['sheet']
          : null;
      final oldPortrait = oldSheet is Map
          ? '${oldSheet['immaginePersonaggioBase64'] ?? ''}'
          : '';
      if (oldPortrait.isEmpty ||
          oculumRealtimeSheetContentSignature({'portrait': oldPortrait}) !=
              portraitReference) {
        // A newly joined Master/Co-Master must obtain a complete portrait once.
        unawaited(
          realtimeService?.requestSharedSheetsConfirmed(
            targetSheetTag: sheetId,
          ),
        );
        return false;
      }
      sheet['immaginePersonaggioBase64'] = oldPortrait;
      sheet.remove('realtimePortraitReference');
    }
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
    // A Co-Master that joins after a player still needs the same usable sheet
    // in the turn order.  Relay the Master registry only to Co-Masters; the
    // player copy stays owned by its original session and remains read-only.
    if (realtimeIsMasterRole && senderRole == 'player') {
      sendRealtimeStaffTurnOrderSheets();
    }
    // Confirm only after validation and storage in the receiving sheet registry.
    sendRealtimeMasterSheetAck(
      payload: payload,
      senderRole: senderRole,
      sheetId: sheetId,
    );

    final localIndex = realtimeLocalSheetIndexForKey(key);
    if (localIndex < 0) {
      if (oculumRealtimeShouldImportSharedSheet(
        senderRole: senderRole,
        masterParty: readBoolValue(payload['masterParty']),
        restrictedByMaster: readBoolValue(sheet['realtimeRestrictedByMaster']),
      )) {
        final prepared = prepareRealtimeSheetForLocal(record);
        schedePersonaggio.add(prepared);
        saveActiveCampaignInMemory();
        replayPendingEncounterJoins(sheetId);
        aggiungiLog(
          t(
            'Scheda online ricevuta: ${record['sheetName']}.',
            'Online sheet received: ${record['sheetName']}.',
          ),
        );
        return true;
      }

      // A staff relay is deliberately retained in the browsing registry until
      // opened; accepting it must still refresh and save the receiving UI.
      return targetAudience == 'staff_turn_order';
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
    syncSharedSheetToMasterEncounters(localIndex);
    aggiungiLog(
      t(
        'Scheda online aggiornata: ${record['sheetName']}.',
        'Online sheet updated: ${record['sheetName']}.',
      ),
    );
    saveActiveCampaignInMemory();
    replayPendingEncounterJoins(sheetId);
    return true;
  }

  void sendRealtimeMasterPartySheets() {
    sendRealtimeMasterVisiblePartyTokens();
  }

  /// Mirrors the player-sheet registry from the Master to all Co-Masters.
  /// It is intentionally separate from player-facing party publication: this
  /// contains no new writable ownership and is only used to open a participant
  /// from the shared turn order.
  void sendRealtimeStaffTurnOrderSheets() {
    final service = realtimeService;
    if (service?.isConnected != true || !realtimeIsMasterRole) return;
    if (!realtimeUsers.any((user) => user['role'] == 'coMaster')) return;

    final participantTags = <String>{
      for (final token in masterInitiativeTokens)
        publicInitiativeSourceTag(token),
      for (final group in masterInitiativeGroups)
        for (final token
            in (group['tokens'] as List? ?? const []).whereType<Map>())
          publicInitiativeSourceTag(Map<String, dynamic>.from(token)),
    };
    final records = <String, Map<String, dynamic>>{};
    for (final record in realtimeSharedSheets) {
      final tag = '${record['sheetId'] ?? ''}';
      if (participantTags.contains(tag) &&
          const {'player', 'coMaster'}.contains(record['senderRole']) &&
          record['sheet'] is Map) {
        records[tag] = record;
      }
    }
    for (var index = 0; index < schedePersonaggio.length; index++) {
      final source = schedePersonaggio[index];
      if (readBoolValue(source['realtimeSharedSheet'])) continue;
      final tag = '${source['sheetTag'] ?? source['id'] ?? ''}';
      if (!participantTags.contains(tag)) continue;
      records[tag] = {
        'sheetId': tag,
        'ownerTag': tag,
        'sheetName': nomeSchedaPersonaggio(index),
        'sheet': schedaJsonAt(index),
      };
    }
    for (final record in records.values) {
      final sheetId = normalizeOculumFriendTag('${record['sheetId'] ?? ''}');
      final ownerTag = normalizeOculumFriendTag('${record['ownerTag'] ?? ''}');
      if (sheetId.isEmpty || ownerTag.isEmpty) continue;
      final sheet = realtimeSafeSheetJson(
        Map<String, dynamic>.from(record['sheet'] as Map),
        includeImage: true,
      );
      final hashKey = 'relay:$sheetId';
      final hash = jsonEncode([
        activeCampaignId,
        oculumRealtimeStaffPresenceSignature(realtimeUsers),
        oculumRealtimeSheetContentSignature(sheet),
      ]);
      if (realtimeLastSentSheetHashes[hashKey] == hash) continue;
      rememberRealtimeSheetHash(hashKey, hash);
      unawaited(
        service!
            .sendSharedSheetConfirmed(
              sheet: sheet,
              campaignId: activeCampaignId,
              campaignName: activeCampaignName(),
              sheetId: sheetId,
              sheetName: '${record['sheetName'] ?? sheet['nome'] ?? '???'}',
              ownerTag: ownerTag,
              senderRole: 'master',
              targetAudience: 'staff_turn_order',
              fromMaster: true,
              masterParty: false,
            )
            .then<void>((sent) {
              if (!sent && realtimeLastSentSheetHashes[hashKey] == hash) {
                realtimeLastSentSheetHashes.remove(hashKey);
              }
            }),
      );
    }
  }

  void sendRealtimeCurrentPartySheet() {
    if (realtimeIsMasterRole) {
      sendRealtimeMasterVisiblePartyTokens();
    } else {
      sendRealtimeCurrentSheetToStaff();
    }
  }

  Future<void> drainRealtimeDirtySheets() async {
    if (realtimeDirtySheetsDrainRunning || !realtimeIsMasterRole) return;
    realtimeDirtySheetsDrainRunning = true;
    try {
      final tags = [
        for (var i = 0; i < schedePersonaggio.length; i++)
          if (i != schedaCorrente &&
              schedePersonaggio[i]['realtimeDirtyLocal'] == true)
            sheetTagAt(i),
      ];
      for (final tag in tags) {
        if (!mounted || !realtimeIsMasterRole) break;
        final index = schedePersonaggio.indexWhere(
          (sheet) => '${sheet['sheetTag'] ?? sheet['id']}' == tag,
        );
        if (index >= 0) {
          await _sendRealtimeEditedSharedSheetBack(sheetIndex: index);
        }
      }
    } finally {
      realtimeDirtySheetsDrainRunning = false;
    }
  }

  void sendRealtimeCurrentSheetToStaff({bool immediate = false}) {
    if (realtimeIsMasterRole) unawaited(drainRealtimeDirtySheets());
    if (!canShareRealtimeSheetToStaff) return;

    if (immediate) {
      realtimeSheetShareDebounceTimer?.cancel();
      salvaSchedaCorrenteInMemoria();
      sendRealtimeSheetToStaffAt(
        schedaCorrente,
        force: true,
        ensureMasterReceipt: true,
      );
      return;
    }

    if (realtimeSheetShareDebounceTimer?.isActive ?? false) return;
    realtimeSheetShareDebounceTimer = Timer(
      const Duration(milliseconds: 500),
      () {
        if (!mounted || !canShareRealtimeSheetToStaff) return;
        salvaSchedaCorrenteInMemoria();
        sendRealtimeSheetToStaffAt(schedaCorrente);
      },
    );
  }

  bool shouldSendRealtimeSheetHash(String key, Map<String, dynamic> sheet) {
    final hash = jsonEncode(sheet);
    if (realtimeLastSentSheetHashes[key] == hash) return false;
    return true;
  }

  void rememberRealtimeSheetHash(String key, String hash) {
    realtimeLastSentSheetHashes[key] = hash;
    if (realtimeLastSentSheetHashes.length > 256) {
      realtimeLastSentSheetHashes.remove(
        realtimeLastSentSheetHashes.keys.first,
      );
    }
  }

  void sendRealtimeCurrentSheetToFriends() {
    unawaited(
      sendRealtimeCurrentSheetToFriendsInternal(
        manual: true,
        sheetIndex: schedaCorrente,
      ),
    );
  }

  List<String> realtimeFullSheetTargetTags() {
    final tags = <String>{};
    final localTags = localOculumTags().map((tag) => tag.toUpperCase()).toSet();
    for (final friend in amiciOculum) {
      final tag = normalizeOculumFriendTag('${friend['tag'] ?? ''}');
      if (tag.isNotEmpty && !isOculumFriendBlocked(tag)) {
        tags.add(tag);
      }
    }
    // Full sheets are deliberately shared only with explicit friends and the
    // Master/Co-Masters of this Realtime room, never with every player merely
    // because they happen to be online.
    for (final user in realtimeUsers) {
      final role = '${user['role'] ?? ''}'.trim();
      if (role != 'master' && role != 'coMaster') continue;
      final rawTags = user['localSheetTags'];
      if (rawTags is! List) continue;
      for (final raw in rawTags) {
        final tag = normalizeOculumFriendTag('$raw');
        if (tag.isEmpty) continue;
        if (localTags.contains(tag.toUpperCase())) continue;
        if (isOculumFriendBlocked(tag)) continue;
        tags.add(tag);
      }
    }
    return tags.toList()..sort();
  }

  Future<bool> sendRealtimeFullSheetToFriendsAndPartyAt(
    int index, {
    bool force = true,
  }) async {
    final service = realtimeService;
    if (service?.isConnected != true) {
      setState(() {
        risultato = t(
          'Realtime non connesso: scheda non inviata.',
          'Realtime is not connected: sheet not sent.',
        );
        aggiungiLog(risultato);
      });
      return false;
    }
    if (index < 0 || index >= schedePersonaggio.length) return false;
    if (readBoolValue(schedePersonaggio[index]['realtimeSharedSheet'])) {
      setState(() {
        risultato = t(
          'Questa e gia una copia online: non la reinvio come scheda completa.',
          'This is already an online copy: it was not reshared as a full sheet.',
        );
        aggiungiLog(risultato);
      });
      return false;
    }

    salvaSchedaCorrenteInMemoria();
    final targetTags = realtimeFullSheetTargetTags();
    if (targetTags.isEmpty) {
      // Staff delivery is role-addressed in the database. It must not require
      // a friend entry or a currently advertised Master character tag.
      if (!realtimeIsMasterRole) {
        final sent = await sendRealtimeSheetToStaffAt(
          index,
          force: force,
          ensureMasterReceipt: true,
        );
        if (mounted) {
          setState(() {
            risultato = sent
                ? 'Scheda inviata al server per il Master. La ricezione viene confermata separatamente.'
                : 'Scheda non inviata: controlla il tag e lo stato della connessione nella pagina Online.';
            aggiungiLog(risultato);
          });
        }
        return sent;
      }
      setState(() {
        risultato = t(
          'Nessun amico o partecipante realtime con tag valido trovato.',
          'No friend or realtime participant with a valid tag was found.',
        );
        aggiungiLog(risultato);
      });
      return false;
    }

    final sheet = realtimeSafeSheetJson(
      schedaJsonAt(index),
      includeImage: true,
      includePartyMembers: true,
    );
    addRealtimePublicTitleSnapshot(sheet, index);
    sheet['realtimeRestrictedByMaster'] = false;
    final sheetId = normalizeOculumFriendTag(
      '${sheet['sheetTag'] ?? sheet['id'] ?? sheetTagAt(index)}',
    );
    if (sheetId.isEmpty) return false;
    final hashKey = 'full:$sheetId:${targetTags.join(',')}';
    final hash = jsonEncode(sheet);
    if (!force && realtimeLastSentSheetHashes[hashKey] == hash) {
      return true;
    }

    final sent = await service!.sendSharedSheetConfirmed(
      sheet: sheet,
      campaignId: activeCampaignId,
      campaignName: activeCampaignName(),
      sheetId: sheetId,
      sheetName: nomeSchedaPersonaggio(index),
      ownerTag: sheetId,
      senderRole: 'fullShare',
      targetAudience: 'friends_party_full',
      fromMaster: haPermessiMaster,
      masterParty: sheetInMasterPartyAt(index),
      targetTags: targetTags,
    );
    // Targeted delivery is the user-controlled full share. The staff channel
    // remains an explicit fallback for the Master in the current room.
    if (!realtimeIsMasterRole) {
      sendRealtimeSheetToStaffAt(index, force: true, ensureMasterReceipt: true);
    }
    if (sent) rememberRealtimeSheetHash(hashKey, hash);

    if (mounted) {
      setState(() {
        risultato = sent
            ? t(
                'Scheda completa inviata al server per amici e Master/Co-Master (${targetTags.length} tag). La ricezione del Master viene confermata separatamente.',
                'Full sheet sent to the server for friends and Master/Co-Masters (${targetTags.length} tags). Master receipt is confirmed separately.',
              )
            : t(
                'Invio realtime non confermato: controlla stanza e connessione di entrambi i player.',
                'Realtime delivery was not confirmed: check both players room and connection.',
              );
        aggiungiLog(risultato);
      });
    }
    return sent;
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
    unawaited(
      sendRealtimeCurrentSheetToFriendsInternal(
        manual: false,
        sheetIndex: schedaCorrente,
      ),
    );
  }

  void resendRealtimeFriendSheetsForPresence() {
    for (var index = 0; index < schedePersonaggio.length; index++) {
      if (!readBoolValue(
        schedePersonaggio[index]['realtimeShareWithFriends'],
      )) {
        continue;
      }
      unawaited(
        sendRealtimeCurrentSheetToFriendsInternal(
          manual: false,
          sheetIndex: index,
        ),
      );
    }
  }

  Future<bool> sendRealtimeCurrentSheetToFriendsInternal({
    required bool manual,
    required int sheetIndex,
    List<String>? targetTagsOverride,
    String? targetLabel,
  }) async {
    final service = realtimeService;
    if (service?.isConnected != true) return false;
    if (realtimeIsMasterRole) return false;
    if (sheetIndex < 0 || sheetIndex >= schedePersonaggio.length) return false;
    if (amiciOculum.isEmpty && targetTagsOverride == null) return false;
    if (readBoolValue(schedePersonaggio[sheetIndex]['realtimeSharedSheet'])) {
      return false;
    }

    if (sheetIndex == schedaCorrente) {
      salvaSchedaCorrenteInMemoria();
    }
    if (!readBoolValue(
      schedePersonaggio[sheetIndex]['realtimeShareWithFriends'],
    )) {
      schedePersonaggio[sheetIndex]['realtimeShareWithFriends'] = true;
      saveActiveCampaignInMemory();
    }
    final revokedTags = sheetRevokedAccessTagsAt(
      sheetIndex,
    ).map((tag) => tag.toUpperCase()).toSet();
    final targetTags =
        targetTagsOverride ??
        amiciOculum
            .map((friend) => normalizeOculumFriendTag('${friend['tag'] ?? ''}'))
            .where((tag) => tag.isNotEmpty && !isOculumFriendBlocked(tag))
            .toList();
    final allowedTargetTags =
        targetTags
            .where((tag) => !revokedTags.contains(tag.toUpperCase()))
            .map(normalizeOculumFriendTag)
            .where((tag) => tag.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    if (allowedTargetTags.isEmpty) return false;

    final sheet = realtimeSafeSheetJson(
      schedaJsonAt(sheetIndex),
      includeImage: true,
    );
    addRealtimePublicTitleSnapshot(sheet, sheetIndex);
    final sheetId = normalizeOculumFriendTag(
      '${sheet['sheetTag'] ?? sheet['id'] ?? sheetTagAt(sheetIndex)}',
    );
    if (sheetId.isEmpty) return false;
    final hashKey = oculumRealtimeSheetDeliveryHashKey(
      'friend',
      sheetId,
      allowedTargetTags,
    );
    final hash = jsonEncode(sheet);
    if (realtimeLastSentSheetHashes[hashKey] == hash) {
      if (manual && mounted) {
        setState(() {
          risultato = t(
            'La scheda condivisa e gia aggiornata per questi amici.',
            'The shared sheet is already up to date for these friends.',
          );
        });
      }
      return true;
    }

    final sent = await service!.sendSharedSheetConfirmed(
      sheet: sheet,
      campaignId: activeCampaignId,
      campaignName: activeCampaignName(),
      sheetId: sheetId,
      sheetName: nomeSchedaPersonaggio(sheetIndex),
      ownerTag: sheetId,
      senderRole: oculumRealtimeFriendShareSenderRole,
      targetAudience: 'friends',
      fromMaster: false,
      masterParty: false,
      targetTags: allowedTargetTags,
    );
    if (sent) rememberRealtimeSheetHash(hashKey, hash);

    if (manual && mounted) {
      setState(() {
        risultato = !sent
            ? t(
                'Invio scheda fallito: controlla la connessione Realtime e riprova.',
                'Sheet delivery failed: check the Realtime connection and try again.',
              )
            : targetLabel == null
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
    return sent;
  }

  void sendRealtimeSharedSheetAt(int index) {
    if (realtimeIsMasterRole) {
      sendRealtimeMasterVisibleTokenAt(index);
    } else {
      sendRealtimeSheetToStaffAt(index, force: true, ensureMasterReceipt: true);
    }
  }

  void sendRealtimeMasterDeathPatchToOwner(
    int index,
    Map<String, dynamic> token,
  ) {
    final service = realtimeService;
    if (service?.isConnected != true || !realtimeIsMasterRole) return;
    if (index < 0 || index >= schedePersonaggio.length) return;

    final source = schedePersonaggio[index];
    if (!readBoolValue(source['realtimeSharedSheet'])) return;
    final ownerTag = normalizeOculumFriendTag(
      '${source['realtimeSourceSheetTag'] ?? source['realtimeOwnerTag'] ?? ''}',
    );
    if (ownerTag.isEmpty) return;

    final patch = <String, dynamic>{
      'id': ownerTag,
      'sheetTag': ownerTag,
      'currentHp': '${token['currentHp'] ?? 0}',
      'currentOculum': '${token['currentOculum'] ?? 0}',
      'hpTemp': '${token['hpTemp'] ?? 0}',
      'scudo': '${token['shield'] ?? 0}',
      'personaggioCaduto': masterInitiativeTokenIsDowned(token),
      'feriteMorte': readIntValue(token['deathWounds']),
      'volontaVitale': readIntValue(token['vitalWills']),
      'realtimeDeathOutcomeIt': '${token['realtimeDeathOutcomeIt'] ?? ''}',
      'realtimeDeathOutcomeEn': '${token['realtimeDeathOutcomeEn'] ?? ''}',
      'realtimeDeathOutcomeAt': '${token['realtimeDeathOutcomeAt'] ?? ''}',
    };

    unawaited(
      service!.sendSharedSheetConfirmed(
        sheet: patch,
        campaignId: '${source['realtimeCampaignId'] ?? activeCampaignId}'
            .trim(),
        campaignName:
            '${source['realtimeCampaignName'] ?? activeCampaignName()}',
        sheetId: ownerTag,
        sheetName: nomeSchedaPersonaggio(index),
        ownerTag: ownerTag,
        senderRole: 'sheetEdit',
        targetAudience: 'owner',
        fromMaster: true,
        masterParty: true,
        targetTags: <String>[ownerTag],
      ),
    );
  }

  Future<bool> sendRealtimeSheetToStaffAt(
    int index, {
    bool force = false,
    bool ensureMasterReceipt = false,
    String? deliveryId,
    int attempt = 1,
  }) async {
    final service = realtimeService;
    if (service?.isConnected != true || !canShareRealtimeSheetToStaff) {
      return false;
    }
    if (index < 0 || index >= schedePersonaggio.length) return false;
    if (readBoolValue(schedePersonaggio[index]['realtimeSharedSheet'])) {
      return false;
    }
    final approvalSheet = schedePersonaggio[index];
    if ('${approvalSheet['monsterBookSourceId'] ?? ''}'.isNotEmpty &&
        approvalSheet['monsterBookApprovedScope'] != permissionScope &&
        !haPermessiMaster) {
      approvalSheet['monsterBookApprovalRequired'] = true;
      approvalSheet['monsterBookApproved'] = false;
    }
    salvaSchedaCorrenteInMemoria();
    final role = realtimeLocalRole();
    final sheet = realtimeSafeSheetJson(
      schedaJsonAt(index),
      includeImage: true,
    );
    addRealtimePublicTitleSnapshot(sheet, index);
    final sheetId = normalizeOculumFriendTag(
      '${sheet['sheetTag'] ?? sheet['id'] ?? sheetTagAt(index)}',
    );
    if (sheetId.isEmpty) return false;
    final hashKey = 'staff:$sheetId';
    final hash = oculumRealtimeSheetContentSignature(sheet);
    if (realtimeStaffTransfersInFlight[sheetId] == service) return false;
    if (!force && realtimeLastSentSheetHashes[hashKey] == hash) return false;
    if (!force &&
        realtimePendingMasterAckSheetIds.entries.any(
          (entry) =>
              entry.value == sheetId &&
              realtimePendingMasterAckHashes[entry.key] == hash,
        )) {
      return false;
    }

    final waitForMasterAck = ensureMasterReceipt || realtimeHasMasterOnline;
    final activeDeliveryId = waitForMasterAck
        ? (deliveryId != null &&
                  realtimePendingMasterAckHashes[deliveryId] == hash
              ? deliveryId
              : newRealtimeSheetDeliveryId(sheetId))
        : '';
    if (waitForMasterAck && activeDeliveryId.isNotEmpty) {
      // Keep one receipt per sheet; an older retry must not supersede new edits.
      final obsolete = realtimePendingMasterAckSheetIds.entries
          .where(
            (entry) => entry.value == sheetId && entry.key != activeDeliveryId,
          )
          .map((entry) => entry.key)
          .toList();
      for (final id in obsolete) {
        cancelRealtimeMasterAckWatch(id);
      }
      realtimePendingMasterAckTimers.remove(activeDeliveryId)?.cancel();
      // Register before sending: the receiver may answer before the server.
      realtimePendingMasterAckSheetIds[activeDeliveryId] = sheetId;
      realtimePendingMasterAckHashes[activeDeliveryId] = hash;
    }

    realtimeStaffTransfersInFlight[sheetId] = service!;
    final portrait = '${sheet['immaginePersonaggioBase64'] ?? ''}';
    final portraitHash = oculumRealtimeSheetContentSignature({
      'portrait': portrait,
    });
    if (activeDeliveryId.isNotEmpty) {
      realtimePendingPortraitHashes[activeDeliveryId] = portraitHash;
    }
    final wireSheet = Map<String, dynamic>.from(sheet);
    final staff = realtimeUsers
        .where((user) => const {'master', 'coMaster'}.contains(user['role']))
        .toList();
    if (!force &&
        staff.isNotEmpty &&
        staff.every((user) => readIntValue(user['protocolVersion']) >= 4) &&
        portrait.isNotEmpty &&
        realtimeAcknowledgedPortraitHashes[sheetId.toUpperCase()] ==
            portraitHash) {
      wireSheet['immaginePersonaggioBase64'] = '';
      wireSheet['realtimePortraitReference'] = portraitHash;
    }
    var delivered = false;
    await service
        .sendSharedSheetConfirmed(
          sheet: wireSheet,
          campaignId: activeCampaignId,
          campaignName: activeCampaignName(),
          sheetId: sheetId,
          sheetName: nomeSchedaPersonaggio(index),
          ownerTag: sheetId,
          senderRole: role,
          targetAudience: role == 'coMaster' ? 'master' : 'master_coMaster',
          fromMaster: false,
          masterParty: false,
          deliveryId: activeDeliveryId,
        )
        .then((sent) {
          delivered = sent;
          if (realtimeStaffTransfersInFlight[sheetId] == service) {
            realtimeStaffTransfersInFlight.remove(sheetId);
          }
          if (!mounted || realtimeService != service) return;
          if (sent && !waitForMasterAck) {
            rememberRealtimeSheetHash(hashKey, hash);
          }
          if (!sent) realtimeLastSentSheetHashes.remove(hashKey);
          // Start the receipt timeout only after the transport has finished.
          // Never resurrect a receipt already acknowledged or superseded.
          if (realtimePendingMasterAckSheetIds[activeDeliveryId] == sheetId) {
            watchRealtimeMasterAck(
              deliveryId: activeDeliveryId,
              sheetId: sheetId,
              attempt: attempt,
            );
          }
          // Coalesce edits made during a large transfer into one fresh send.
          final latestIndex = localSheetIndexForOculumTag(sheetId);
          if (latestIndex >= 0 && canShareRealtimeSheetToStaff) {
            final latest = realtimeSafeSheetJson(
              schedaJsonAt(latestIndex),
              includeImage: true,
            );
            addRealtimePublicTitleSnapshot(latest, latestIndex);
            if (oculumRealtimeSheetContentSignature(latest) != hash) {
              sendRealtimeSheetToStaffAt(
                latestIndex,
                ensureMasterReceipt: true,
              );
            }
          }
        });
    return delivered;
  }

  Future<bool> sendRealtimeEditedSharedSheetBack() async {
    final pending = realtimeEditedSheetSend;
    if (pending != null) return pending;
    final operation = _sendRealtimeEditedSharedSheetBack();
    realtimeEditedSheetSend = operation;
    try {
      return await operation;
    } finally {
      if (identical(realtimeEditedSheetSend, operation)) {
        realtimeEditedSheetSend = null;
      }
    }
  }

  Future<bool> _sendRealtimeEditedSharedSheetBack({int? sheetIndex}) async {
    final service = realtimeService;
    if (service?.isConnected != true) return false;
    final editedIndex = sheetIndex ?? schedaCorrente;
    if (editedIndex < 0 || editedIndex >= schedePersonaggio.length) {
      return false;
    }

    final current = schedePersonaggio[editedIndex];
    if (!readBoolValue(current['realtimeSharedSheet'])) return false;
    if (!readBoolValue(current['realtimeDirtyLocal'])) return false;
    if (readBoolValue(current['realtimeRestrictedByMaster'])) return false;
    if (readBoolValue(current['realtimeReadOnlyByMaster'])) return false;

    final sourceTag = normalizeOculumFriendTag(
      '${current['realtimeSourceSheetTag'] ?? current['realtimeOwnerTag'] ?? ''}',
    );
    if (sourceTag.isEmpty) return false;

    final fullSheet = realtimeSafeSheetJson(
      schedaJsonAt(editedIndex),
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
    final allowClearFields = <String>[
      for (final entry in patch.entries)
        if (entry.key != 'merchantProfiles' &&
            oculumRealtimeProtectedEmptyFields.contains(entry.key) &&
            oculumRealtimeValueIsEmpty(entry.value) &&
            !oculumRealtimeValueIsEmpty(baseSheet[entry.key]))
          entry.key,
    ];
    patch['id'] = sourceTag;
    patch['sheetTag'] = sourceTag;
    if (oculumRealtimeAppliedPatchKeys(
      baseSheet,
      patch,
      allowClearFields: allowClearFields.toSet(),
    ).isEmpty) {
      return false;
    }
    if (!shouldSendRealtimeSheetHash('edit:$sourceTag', patch)) return false;

    final sent = await service!.sendSharedSheetConfirmed(
      sheet: patch,
      campaignId: '${current['realtimeCampaignId'] ?? ''}'.trim().isNotEmpty
          ? '${current['realtimeCampaignId']}'
          : activeCampaignId,
      campaignName:
          '${current['realtimeCampaignName'] ?? activeCampaignName()}',
      sheetId: sourceTag,
      sheetName: nomeSchedaPersonaggio(editedIndex),
      ownerTag: sourceTag,
      senderRole: 'sheetEdit',
      targetAudience: 'owner',
      fromMaster: realtimeIsMasterRole,
      masterParty: false,
      targetTags: <String>[sourceTag],
      allowClearFields: allowClearFields,
    );
    if (!sent || !mounted || realtimeService != service) return false;

    rememberRealtimeSheetHash('edit:$sourceTag', jsonEncode(patch));

    if (sourceRecord.isNotEmpty && baseSheet.isNotEmpty) {
      sourceRecord['sheet'] = oculumRealtimeMergeSheetPatch(baseSheet, patch);
      sourceRecord['sentAt'] = DateTime.now().toIso8601String();
    }
    // A new local edit made during the send must remain pending.
    final latestIndex = sourceKey.isNotEmpty
        ? realtimeLocalSheetIndexForKey(sourceKey)
        : editedIndex;
    if (latestIndex >= 0 &&
        latestIndex < schedePersonaggio.length &&
        '${schedePersonaggio[latestIndex]['realtimeSourceSheetTag'] ?? schedePersonaggio[latestIndex]['realtimeOwnerTag'] ?? ''}' ==
            sourceTag &&
        jsonEncode(
              realtimeSafeSheetJson(
                schedaJsonAt(latestIndex),
                includeImage: true,
              ),
            ) ==
            jsonEncode(fullSheet)) {
      schedePersonaggio[latestIndex]['realtimeDirtyLocal'] = false;
      schedePersonaggio[latestIndex].remove('realtimeDirtyAt');
    }
    if (schedaCorrente >= 0 &&
        schedaCorrente < schedePersonaggio.length &&
        readBoolValue(
          schedePersonaggio[schedaCorrente]['realtimeDirtyLocal'],
        )) {
      programmaSalvataggio(
        invalidateCaches: false,
        delay: const Duration(milliseconds: 500),
      );
    }
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
        (realtimeIsCoMasterRole &&
            trustedCoMasterTags.contains(
              '$permissionScope:${sheetTagAt(schedaCorrente)}',
            ));
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
        campaignId: permissionCampaignId,
        campaignName: activeCampaignName(),
        senderTag: sheetTagAt(schedaCorrente),
        senderRole: realtimeLocalRole(),
        scope: permissionScope,
        trusted:
            coMaster &&
            trustedCoMasterTags.contains('$permissionScope:$targetTag'),
      ),
    );
    unawaited(salvaDatiSoloLocale());
  }

  void sendRealtimeMasterVisiblePartyTokens() {
    if (realtimeService?.isConnected != true || !haPermessiMaster) return;

    salvaSchedaCorrenteInMemoria();
    sendRealtimeStaffTurnOrderSheets();
    for (final index in masterPartyIndexes()) {
      sendRealtimeMasterVisibleTokenAt(index);
    }
  }

  Future<void> apriSchedaPartecipanteTurnistica(
    Map<String, dynamic> token,
  ) async {
    if (!realtimeCanBrowseOtherSheets) return;
    final tag = normalizeOculumFriendTag(onlineCombatTokenTag(token));
    if (tag.isEmpty) return;
    final recordIndex = realtimeSharedSheets.indexWhere(
      (record) =>
          ('${record['campaignId'] ?? ''}' == activeCampaignId ||
              '${record['campaignId'] ?? ''}' == permissionCampaignId) &&
          (normalizeOculumFriendTag('${record['sheetId'] ?? ''}') == tag ||
              normalizeOculumFriendTag('${record['ownerTag'] ?? ''}') == tag),
    );
    if (recordIndex >= 0) {
      await apriSchedaRealtimeCondivisa(recordIndex);
      return;
    }
    final localIndex = schedePersonaggio.indexWhere(
      (sheet) =>
          normalizeOculumFriendTag('${sheet['sheetTag'] ?? ''}') == tag ||
          normalizeOculumFriendTag(
                '${sheet['realtimeSourceSheetTag'] ?? ''}',
              ) ==
              tag,
    );
    if (localIndex >= 0) {
      await cambiaSchedaPersonaggio(localIndex);
      return;
    }
    setState(() {
      risultato = t(
        'Scheda del partecipante non ancora ricevuta: richiesta inviata.',
        'Participant sheet not received yet: request sent.',
      );
      aggiungiLog(risultato);
    });
    unawaited(realtimeService?.requestSharedSheets());
  }

  void sendRealtimeMonsterBookSnapshot() {
    final service = realtimeService;
    if (service?.isConnected != true || !realtimeIsMasterRole) return;
    final entries = monsterBookCustomEntries
        .map((entry) => entry.toJson())
        .toList(growable: false);
    final removed = monsterBookRemovedIds.toList()..sort();
    unawaited(
      service!.sendMonsterBookSnapshot(
        campaignId: activeCampaignId,
        campaignName: activeCampaignName(),
        entries: entries,
        removedIds: removed,
      ),
    );
  }

  String realtimeMerchantRosterSignature(String campaignId, dynamic profiles) =>
      jsonEncode(<dynamic>[
        campaignId.trim(),
        oculumRealtimeMerchantRosterProjection(profiles),
      ]);

  Future<bool> sendRealtimeMerchantRosterSnapshot({bool force = false}) async {
    final service = realtimeService;
    if (service?.isConnected != true) return false;
    final profiles = oculumRealtimeMerchantRosterProjection(merchantProfiles);
    if (profiles.isEmpty) return false;
    final campaignId = activeCampaignId.trim();
    if (campaignId.isEmpty) return false;
    final signature = realtimeMerchantRosterSignature(campaignId, profiles);
    if (!force && signature == realtimeLastSentMerchantRosterSignature) {
      return true;
    }
    final sent = await service!.sendMerchantRosterSnapshot({
      'campaignId': campaignId,
      'merchantProfiles': profiles,
    });
    if (!sent || !mounted || realtimeService != service) return false;
    final latest = realtimeMerchantRosterSignature(
      activeCampaignId,
      merchantProfiles,
    );
    if (latest == signature) {
      realtimeLastSentMerchantRosterSignature = signature;
    } else {
      unawaited(sendRealtimeMerchantRosterSnapshot());
    }
    return true;
  }

  bool receiveRealtimeMerchantRosterSnapshot(Map<String, dynamic> payload) {
    if (!mounted ||
        '${payload['campaignId'] ?? ''}'.trim() != activeCampaignId.trim()) {
      return false;
    }
    final incoming = oculumRealtimeMerchantRosterProjection(
      payload['merchantProfiles'],
    );
    if (incoming.isEmpty) return false;
    salvaSchedaCorrenteInMemoria();
    var changed = false;
    var activeProfiles = merchantProfiles;
    for (var i = 0; i < schedePersonaggio.length; i++) {
      final sheet = schedePersonaggio[i];
      final raw = sheet['merchantProfiles'];
      final current = raw is List
          ? raw
                .whereType<Map>()
                .map((profile) => Map<String, dynamic>.from(profile))
                .toList()
          : <Map<String, dynamic>>[];
      final merged = oculumRealtimeMergeMerchantRoster(current, incoming);
      if (realtimeMerchantRosterSignature(activeCampaignId, current) !=
          realtimeMerchantRosterSignature(activeCampaignId, merged)) {
        sheet['merchantProfiles'] = merged;
        changed = true;
      }
      if (i == schedaCorrente) activeProfiles = merged;
    }
    if (!changed) return false;
    setState(() => merchantProfiles = activeProfiles);
    saveActiveCampaignInMemory();
    programmaSalvataggio(
      invalidateCaches: false,
      delay: const Duration(milliseconds: 1000),
    );
    return true;
  }

  void sendRealtimeMasterVisibleTokenAt(int index) {
    final service = realtimeService;
    if (service?.isConnected != true || !haPermessiMaster) return;
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

    final hashKey = 'master:$sheetId';
    final hash = jsonEncode([
      activeCampaignId,
      masterEnemyFullSheetVisibility,
      oculumRealtimePresenceTagSignature(realtimeUsers),
      oculumRealtimeSheetContentSignature(sheet),
    ]);
    if (realtimeLastSentSheetHashes[hashKey] == hash) return;
    // Reserve before awaiting so repeated Presence callbacks cannot enqueue
    // the same large party while its first transfer is still in progress.
    rememberRealtimeSheetHash(hashKey, hash);

    unawaited(
      service!
          .sendSharedSheetConfirmed(
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
          )
          .then<void>((sent) {
            if (!sent && realtimeLastSentSheetHashes[hashKey] == hash) {
              realtimeLastSentSheetHashes.remove(hashKey);
            }
          }),
    );
  }

  Future<void> sendRealtimeDiceRollWithMasterConsent({
    required String label,
    required int roll,
    required int bonus,
    required int total,
  }) {
    return realtimeDiceConsentQueue.enqueue('dice-consent', () async {
      if (!mounted) return;
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
    });
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
                ? 'Online copia - ${schedePersonaggio[i]['realtimeOwnerName'] ?? '???'} - ${visibleSheetDisplayName(i)}'
                : '${i + 1}. ${visibleSheetDisplayName(i)}',
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
        TextButton.icon(
          onPressed: () => unawaited(requestRealtimePlayerSheets()),
          icon: const Icon(Icons.sync),
          label: Text(t('Richiedi schede ai Player', 'Request player sheets')),
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
            final publicTitleName = '${sheet['publicVisibleTitleName'] ?? ''}'
                .trim();
            final publicTitleLegend =
                '${sheet['publicVisibleTitleLegend'] ?? ''}'.trim();
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
                    (realtimeIsCoMasterRole &&
                        trustedCoMasterTags.contains(
                          '$permissionScope:${sheetTagAt(schedaCorrente)}',
                        ))) &&
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
                    oculumNameWithVisibleTitle(
                      '${record['sheetName'] ?? '???'}',
                      publicTitleName,
                    ),
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
                  if (publicTitleName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    smallInfoText(
                      publicTitleLegend.isEmpty
                          ? t(
                              'Titolo pubblico: $publicTitleName',
                              'Public title: $publicTitleName',
                            )
                          : t(
                              'Titolo pubblico: $publicTitleName — $publicTitleLegend',
                              'Public title: $publicTitleName — $publicTitleLegend',
                            ),
                      color: tertiaryColor,
                    ),
                  ],
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
                        if (realtimeIsMasterRole && coMasterMarked)
                          TextButton(
                            onPressed: () => setTrustedCoMaster(record),
                            child: Text(
                              trustedCoMasterTags.contains(
                                    '$permissionScope:$sheetId',
                                  )
                                  ? 'Fidato · attivo'
                                  : 'Fidato',
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                              ),
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
    if (realtimeIsMasterRole) {
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

    if (referenceCampaignStyle) {
      return referenceEncounterPanel(tokens: tokens, activeIndex: activeIndex);
    }

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
              if (realtimeService?.isConnected != true)
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
                onlineAttackButton(),
                onlineCombatRequestsPanel(),
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
            'Connesso alla stanza ${realtimeService?.normalizedRoomId ?? realtimeRoomController.text}',
            'Connected to room ${realtimeService?.normalizedRoomId ?? realtimeRoomController.text}',
          )
        : realtimeStatus;

    return gothicPanel(
      borderColor: Colors.greenAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Realtime Oculum',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (haPermessiMaster) onlinePermissionButton(),
              PopupMenuButton<String>(
                tooltip: t('Azioni dungeon online', 'Online Dungeon actions'),
                color: backgroundMidColor,
                icon: Icon(Icons.more_vert, color: primaryColor),
                onSelected: (value) {
                  if (value == 'join') {
                    unawaited(showRealtimeDungeonJoinPicker());
                  }
                  if (value == 'open') {
                    _openDungeonMiniGame(openOnlinePanel: true);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'join',
                    enabled: realtimeConnected,
                    child: Text(t('Unisciti alla run', 'Join a run')),
                  ),
                  PopupMenuItem(
                    value: 'open',
                    enabled: realtimeConnected,
                    child: Text(
                      t('Apri Dungeon online', 'Open Online Dungeon'),
                    ),
                  ),
                ],
              ),
            ],
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
              realtimeService?.masterRoleUnavailable == true
                  ? t(
                      'La stanza appartiene a un altro account: puoi partecipare come giocatore oppure creare una nuova stanza.',
                      'This room belongs to another account: join as a player or create a new room.',
                    )
                  : realtimeMasterBlockedByPresence
                  ? t(
                      'Master gia presente: ruolo attuale Giocatore.',
                      'Master already present: current role Player.',
                    )
                  : t(
                      '${realtimeConnected ? 'Ruolo online' : 'Ruolo richiesto'}: ${realtimeLocalRole() == 'master'
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
            onChanged: realtimeConnecting || realtimeConnected
                ? null
                : (value) {
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
                          : t(
                              'Ruolo realtime aggiornato.',
                              'Realtime role updated.',
                            );
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
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              t('Password stanza (opzionale)', 'Room password (optional)'),
              style: TextStyle(color: primaryColor),
            ),
            leading: Icon(Icons.lock_outline, color: primaryColor),
            children: [
              TextField(
                controller: realtimeRoomPasswordController,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: t('Password stanza', 'Room password'),
                  helperText: t(
                    'Vuota = nessuna password. Il Master deve comunque ammettere i nuovi giocatori.',
                    'Empty = no password. The Master must still approve new players.',
                  ),
                  helperMaxLines: 3,
                ),
              ),
              if (realtimeConnected && realtimeIsMasterRole)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await realtimeService?.setRoomPassword(
                        realtimeRoomPasswordController.text,
                      );
                    },
                    icon: const Icon(Icons.lock_reset),
                    label: Text(t('Applica password', 'Apply password')),
                  ),
                ),
            ],
          ),
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
                label: Text(
                  realtimeService?.isAwaitingApproval == true
                      ? t('In attesa del Master', 'Waiting for Master')
                      : realtimeConnecting
                      ? t('Connessione...', 'Connecting...')
                      : t('Connetti', 'Connect'),
                ),
              ),
              if (!realtimeConnected && realtimeWantsMasterRole)
                OutlinedButton.icon(
                  onPressed:
                      realtimeConnecting &&
                          realtimeService?.isAwaitingApproval != true
                      ? null
                      : createRealtimeMasterRoom,
                  icon: const Icon(Icons.add_home_outlined),
                  label: Text(t('Crea nuova stanza', 'Create new room')),
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
                label: Text(
                  realtimeConnecting
                      ? t('Annulla ingresso', 'Cancel joining')
                      : t('Disconnetti', 'Disconnect'),
                ),
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
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: tertiaryColor,
                  foregroundColor: Colors.black,
                ),
                onPressed: realtimeConnected
                    ? () => _openDungeonMiniGame(openOnlinePanel: true)
                    : null,
                icon: const Icon(Icons.sports_martial_arts),
                label: Text(t('Dungeon online', 'Online Dungeon')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          smallInfoText(
            connectedLabel,
            color: realtimeConnected ? Colors.greenAccent : tertiaryColor,
          ),
          if (realtimeConnected && !realtimeIsMasterRole) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => unawaited(sendRealtimeCurrentSheetManually()),
              icon: const Icon(Icons.upload_file),
              label: const Text('Invia scheda al Master'),
            ),
            if (realtimePendingMasterAckSheetIds.isNotEmpty)
              smallInfoText('Scheda in attesa della conferma del Master.'),
          ],
          if (realtimeConnected &&
              realtimeService?.unavailableActiveSheetTag != null) ...[
            const SizedBox(height: 10),
            smallInfoText(
              t(
                'Questa scheda non appartiene al tuo account online nella stanza. Se l’hai creata tu, accedi all’account originale nelle Impostazioni. Puoi anche creare una copia con un nuovo tag: la scheda originale resta conservata.',
                'This sheet does not belong to your online account in this room. If it is yours, sign in to the original account in Settings. You can also create a copy with a new tag; the original sheet is preserved.',
              ),
              color: tertiaryColor,
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await duplicaSchedaCorrente();
                await realtimeService?.refreshPresence();
                unawaited(sendRealtimeActiveSheetToStaff());
              },
              icon: const Icon(Icons.copy_all_outlined),
              label: Text(
                t('Crea copia con nuovo tag', 'Create copy with new tag'),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            t('Chat sessione', 'Session chat'),
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          campoTesto(
            label: t('Messaggio', 'Message'),
            controller: realtimeChatController,
            numero: false,
            helper: realtimeConnected
                ? t('Invia al party realtime.', 'Send to realtime party.')
                : t('Connettiti per inviare.', 'Connect to send.'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: realtimeConnected ? sendRealtimeChatMessage : null,
              icon: const Icon(Icons.send),
              label: Text(t('Invia chat', 'Send chat')),
            ),
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
