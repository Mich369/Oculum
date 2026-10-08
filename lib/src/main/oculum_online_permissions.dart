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
      final master = realtimeUsers
          .where((user) => user['role'] == 'master')
          .firstOrNull;
      final campaign = '${master?['campaignId'] ?? ''}';
      if (campaign.isNotEmpty) return campaign;
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
        (request) => request['scope'] == permissionScope,
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
    return realtimeUsers.any(
      (user) =>
          '${user['sessionId'] ?? ''}' == '${payload['sessionId'] ?? ''}' &&
          '${user['activeSheetTag'] ?? ''}' ==
              '${payload['senderTag'] ?? ''}' &&
          '${user['role'] ?? ''}' == role,
    );
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
    onlinePermissionRetryTimer = Timer.periodic(const Duration(seconds: 5), (
      _,
    ) {
      if (mounted && realtimeService?.isConnected == true) {
        unawaited(replayPermissionRequests());
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

  Future<void> decideMasterRequest(
    Map<String, dynamic> request,
    bool allowed,
  ) async {
    if (!haPermessiMaster ||
        request['status'] != 'pending' ||
        request['scope'] != permissionScope) {
      return;
    }
    final service = realtimeService;
    if (service?.isConnected != true) return;
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
    if (!haPermessiMaster) return;
    for (final request in currentPermissionRequests) {
      request['unread'] = false;
    }
    refreshPermissionUi();
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
                          if (request['status'] == 'pending')
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      decideMasterRequest(request, true),
                                  child: Text(t('Consenti', 'Allow')),
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
                              request['status'] == 'approved'
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
  }
}
