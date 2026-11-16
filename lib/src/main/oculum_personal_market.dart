part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumPersonalMarket on _OculumHomePageState {
  String _personalMarketTag(Object? value) =>
      normalizeOculumFriendTag('${value ?? ''}').toUpperCase();

  bool get _personalMarketConnected =>
      realtimeService?.isConnected == true &&
      (realtimeService?.authenticatedUserId ?? '').isNotEmpty;

  String get localPersonalMarketOwnerTag {
    final current = _personalMarketTag(sheetTagAt(schedaCorrente));
    final owned = ownPermissionTags.map(_personalMarketTag).toSet();
    if (owned.contains(current)) return current;
    return realtimeAuthenticatedMaster ? owned.firstOrNull ?? '' : '';
  }

  Map<String, dynamic> get _publicPersonalMarket =>
      personalMarketScopes[permissionScope] ?? const {};

  String? get _privatePersonalMarketKey {
    final account = realtimeService?.authenticatedUserId ?? '';
    if (!_personalMarketConnected || !realtimeAuthenticatedMaster) return null;
    return '$account:$permissionScope';
  }

  ValueListenable<int> get onlinePersonalMarketRevision =>
      onlinePermissionRevision;

  Map<String, dynamic> _personalMarketOwnerView({
    required String tag,
    required String ownerName,
    required Map<String, dynamic> profile,
    required Iterable<Map<String, dynamic>> offers,
  }) => {
    'ownerTag': tag,
    'ownerName': ownerName,
    'name': profile['name'] ?? ownerName,
    'argb': profile['argb'] ?? 0xff9fba97,
    'offers': offers.toList(),
  };

  List<Map<String, dynamic>> get onlineMarketParticipants {
    if (!_personalMarketConnected) return const [];
    final state = _publicPersonalMarket;
    final profiles = _personalMarketMap(state['profiles']);
    final owners = <String, String>{};
    final offersByOwner = <String, List<Map<String, dynamic>>>{};
    final localRole = '${realtimeService?.authenticatedRole}';
    if (_personalMarketPublicTrader(localRole) &&
        localPersonalMarketOwnerTag.isNotEmpty) {
      owners[localPersonalMarketOwnerTag] = realtimeDisplayName();
    }
    for (final user in realtimeUsers) {
      final tag = _personalMarketTag(user['activeSheetTag']);
      if (tag.isNotEmpty && _personalMarketPublicTrader('${user['role']}')) {
        owners.putIfAbsent(tag, () => '${user['playerName'] ?? tag}');
      }
    }
    for (final offer in _personalMarketRows(state['offers'])) {
      final tag = _personalMarketTag(offer['sellerTag']);
      if (tag.isNotEmpty) {
        owners.putIfAbsent(tag, () => '${offer['ownerName'] ?? tag}');
        (offersByOwner[tag] ??= []).add(offer);
      }
    }
    return [
      for (final owner in owners.entries)
        _personalMarketOwnerView(
          tag: owner.key,
          ownerName: owner.value,
          profile: _personalMarketMap(profiles[owner.key]),
          offers: offersByOwner[owner.key] ?? const [],
        ),
    ];
  }

  Map<String, dynamic>? get privateMasterMarketView {
    final key = _privatePersonalMarketKey;
    if (key == null) return null;
    final state = privateMasterMarkets[key] ?? const {};
    return _personalMarketOwnerView(
      tag: localPersonalMarketOwnerTag,
      ownerName: realtimeDisplayName(),
      profile: _personalMarketRows(state['profiles']).lastOrNull ?? const {},
      offers: _personalMarketRows(state['offers']),
    );
  }

  Color get localOnlineMarketOrbColor => Color(personalMarketLocalOrbArgb);

  List<Map<String, dynamic>> get onlinePersonalMarketSales =>
      realtimeAuthenticatedMaster && _personalMarketConnected
      ? _personalMarketRows(_publicPersonalMarket['sales']).toList()
      : const [];

  Future<bool> updateLocalOnlineMarketOrb({
    required String name,
    required Color color,
  }) async {
    final displayName = name.trim();
    if (displayName.isEmpty) return false;
    final argb = color.toARGB32();
    realtimeNameController.text = displayName;
    personalMarketLocalOrbArgb = argb;
    onlinePermissionRevision.value++;
    if (mounted) setState(() {});
    if (_personalMarketConnected && localPersonalMarketOwnerTag.isNotEmpty) {
      await _requestPersonalMarket({
        'operation': 'profile',
        'name': displayName,
        'argb': argb,
      });
    } else {
      await salvaDatiSoloLocale();
    }
    return true;
  }

  Future<bool> requestPersonalMarketOperation(
    String operation, {
    InventoryItem? item,
    String? offerId,
    String? saleId,
    int quantity = 1,
    int? unitPrice,
    int? adjustedTotal,
  }) => _requestPersonalMarket({
    'operation': operation,
    'quantity': quantity,
    'offerId': offerId,
    'saleId': saleId,
    'unitPrice': unitPrice,
    'adjustedTotal': adjustedTotal,
  }, item: item);

  Future<bool> _requestPersonalMarket(
    Map<String, dynamic> fields, {
    InventoryItem? item,
  }) async {
    if (!_personalMarketConnected) return false;
    final service = realtimeService!;
    final account = service.authenticatedUserId!;
    final tag = localPersonalMarketOwnerTag;
    if (tag.isEmpty) return false;
    final operation = '${fields['operation']}';
    if (!const {
      'profile',
      'list',
      'cancel',
      'buy',
      'discountOffer',
      'discountSale',
    }.contains(operation)) {
      return false;
    }
    final privateKey = _privatePersonalMarketKey;
    final privateState = privateMasterMarkets[privateKey];
    final ownOffer = _personalMarketMap(
      privateState?['offers'],
    ).containsKey('${fields['offerId']}');
    final isPrivate =
        privateKey != null &&
        (const {'profile', 'list', 'cancel'}.contains(operation) ||
            operation == 'discountOffer' && ownOffer);
    if (operation.startsWith('discount') && !realtimeAuthenticatedMaster) {
      return false;
    }
    final request = <String, dynamic>{
      ...fields,
      'id': service.newSheetTransferId(),
      'action': 'personal_market',
      'scope': permissionScope,
      'campaignId': permissionCampaignId,
      'requesterTag': tag,
      'requesterUserId': account,
      'ownerName': realtimeDisplayName(),
      'status': 'pending',
    };
    if (operation == 'profile' && '${request['name']}'.isEmpty) return false;
    final quantity = readIntValue(request['quantity']);
    final unitPrice = readIntValue(request['unitPrice'], fallback: -1);
    if (operation == 'list') {
      if (tag != _personalMarketTag(sheetTagAt(schedaCorrente)) ||
          item == null ||
          item.equipaggiata ||
          !inventario.contains(item) ||
          quantity <= 0 ||
          quantity > item.quantita ||
          unitPrice < 0) {
        return false;
      }
      request['item'] = {...item.toJson(), 'quantita': quantity};
      item.quantita -= quantity;
      if (item.quantita == 0) inventario.remove(item);
      _commitPersonalMarketInventory();
    }
    if (operation == 'buy') {
      final balance = leggiNumero(obserController);
      if (tag != _personalMarketTag(sheetTagAt(schedaCorrente)) ||
          quantity <= 0 ||
          balance < 0 ||
          unitPrice < 0 ||
          unitPrice > balance ~/ quantity) {
        return false;
      }
      final paid = unitPrice * quantity;
      request['reservedObser'] = paid;
      obserController.text = '${balance - paid}';
      _commitPersonalMarketWallet();
    }
    final id = '${request['id']}';
    if (isPrivate) {
      // The Master storefront is account-scoped. None of its operations are
      // placed in the public queue or sent with the room snapshot.
      final state = oculumApplyPersonalMarketOperation(
        privateState ?? const {},
        request,
        actorTag: tag,
        actorUserId: account,
        authenticatedRole: 'master',
        privateMaster: true,
      );
      privateMasterMarkets[privateKey] = state;
      final receipt = _personalMarketMap(
        _personalMarketMap(state['receipts'])[id],
      );
      if (receipt['approved'] == true) {
        _settlePersonalMarketReceipt(
          receipt,
          account,
          journalScope: privateKey,
        );
      } else if (request['item'] is Map) {
        inventario.add(
          InventoryItem.fromJson(_personalMarketMap(request['item'])),
        );
        _commitPersonalMarketInventory();
      }
      final saved = await salvaDatiMercatoConfermati(
        'privateMasterMarkets',
        privateKey,
        receiptId: id,
      );
      if (mounted) refreshPermissionUi();
      return saved && receipt['approved'] == true;
    }
    personalMarketPending[id] = request;
    return _dispatchPersonalMarketRequest(request);
  }

  Future<bool> _dispatchPersonalMarketRequest(
    Map<String, dynamic> request,
  ) async {
    final service = realtimeService;
    final id = '${request['id'] ?? ''}';
    final account = request['requesterUserId'];
    final scope = request['scope'];
    if (!_personalMarketConnected ||
        service == null ||
        id.isEmpty ||
        request['status'] != 'pending' ||
        scope != permissionScope ||
        account != service.authenticatedUserId ||
        !ownPermissionTags
            .map(_personalMarketTag)
            .contains(request['requesterTag'])) {
      return false;
    }
    final saved = await salvaDatiMercatoConfermati('personalMarketPending', id);
    if (mounted) onlinePermissionRevision.value++;
    if (!saved ||
        !mounted ||
        !_personalMarketConnected ||
        !identical(realtimeService, service) ||
        account != service.authenticatedUserId ||
        scope != permissionScope) {
      return false;
    }
    final pending = personalMarketPending[id];
    if (pending?['status'] != 'pending') {
      return pending?['status'] == 'approved';
    }
    final payload = {
      ...permissionEnvelope(pending!),
      'senderTag': pending['requesterTag'],
    };
    if (realtimeIsMasterRole) {
      return _applyPersonalMarketRequest(
        payload,
        '${payload['senderTag']}',
        service.authenticatedUserId!,
        '${service.authenticatedRole}',
      );
    }
    return service.sendPermissionEvent('permission_request', payload);
  }

  Future<void> replayPersonalMarketRequests() async {
    for (final request in personalMarketPending.values.toList()) {
      if (request['status'] == 'pending') {
        await _dispatchPersonalMarketRequest(request);
      }
    }
  }

  Future<void> sendPersonalMarketState() async {
    await _publishPersonalMarketState();
  }

  Future<bool> _publishPersonalMarketState() async {
    if (!_personalMarketConnected || !realtimeIsMasterRole) return false;
    final service = realtimeService!;
    final account = service.authenticatedUserId!;
    final sender = localPersonalMarketOwnerTag;
    final scope = permissionScope;
    final state = _publicPersonalMarket;
    if (sender.isEmpty || state.isEmpty) return false;
    String? lastReceiptId;
    var lastRevision = -1;
    for (final receipt in _personalMarketRows(state['receipts'])) {
      final revision = readIntValue(receipt['revision']);
      if (revision > lastRevision) {
        lastRevision = revision;
        lastReceiptId = '${receipt['id']}';
      }
    }
    _settlePersonalMarketState(state, account, scope);
    final saved = await salvaDatiMercatoConfermati(
      'personalMarketScopes',
      scope,
      receiptId: lastReceiptId,
    );
    if (mounted) refreshPermissionUi();
    if (!saved ||
        !mounted ||
        !_personalMarketConnected ||
        permissionScope != scope ||
        !identical(realtimeService, service) ||
        account != service.authenticatedUserId ||
        !realtimeIsMasterRole) {
      return false;
    }
    await service.sendPermissionEvent('permission_decision', {
      ...permissionEnvelope({
        'action': 'personal_market',
        'operation': 'snapshot',
        'state': oculumPublicPersonalMarketSnapshot(state),
      }),
      'senderTag': sender,
    });
    return true;
  }

  Future<bool> _applyPersonalMarketRequest(
    Map<String, dynamic> request,
    String tag,
    String account,
    String role,
  ) async {
    final scope = permissionScope;
    final current = _publicPersonalMarket;
    final state = oculumApplyPersonalMarketOperation(
      current,
      request,
      actorTag: tag,
      actorUserId: account,
      authenticatedRole: role,
    );
    final receipt = _personalMarketMap(
      _personalMarketMap(state['receipts'])['${request['id']}'],
    );
    if (receipt['requesterUserId'] != account ||
        receipt['requesterTag'] != tag) {
      return false;
    }
    personalMarketScopes[scope] = state;
    final saved = await _publishPersonalMarketState();
    return saved && receipt['approved'] == true;
  }

  Future<void> receivePersonalMarketEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    if (!_personalMarketConnected) return;
    final service = realtimeService!;
    final localAccount = service.authenticatedUserId!;
    final role = '${payload['authenticatedRole'] ?? ''}';
    final account = '${payload['authenticatedUserId'] ?? ''}';
    final scope = permissionScope;
    if (account.isEmpty ||
        role != payload['senderRole'] ||
        !validPermissionSender(
          payload,
          staff: event == 'permission_decision',
        ) ||
        !realtimeUsers.any(
          (user) =>
              user['sessionId'] == payload['sessionId'] &&
              user['userId'] == account,
        )) {
      return;
    }
    if (event == 'permission_request' && realtimeIsMasterRole) {
      final tag = _personalMarketTag(payload['senderTag']);
      if (tag != _personalMarketTag(payload['requesterTag']) ||
          account != payload['requesterUserId'] ||
          role == 'master' && account != localAccount) {
        return;
      }
      await _applyPersonalMarketRequest(payload, tag, account, role);
    }
    if (event != 'permission_decision' ||
        role != 'master' ||
        realtimeIsMasterRole ||
        realtimeUsesSameAccountMaster &&
            payload['sessionId'] != realtimeSameAccountMasterSession ||
        payload['operation'] != 'snapshot' ||
        payload['state'] is! Map) {
      return;
    }
    final raw = _personalMarketMap(payload['state']);
    if (raw['privateMaster'] == true ||
        readIntValue(raw['revision']) <
            readIntValue(_publicPersonalMarket['revision'])) {
      return;
    }
    final state = oculumPublicPersonalMarketSnapshot(raw);
    final changed =
        readIntValue(state['revision']) !=
        readIntValue(_publicPersonalMarket['revision']);
    personalMarketScopes[scope] = state;
    final settled = _settlePersonalMarketState(state, localAccount, scope);
    if (changed || settled) await salvaDatiSoloLocale();
    if (mounted) refreshPermissionUi();
  }

  bool _settlePersonalMarketState(
    Map<String, dynamic> state,
    String account,
    String scope,
  ) {
    var settled = false;
    final receipts = _personalMarketRows(state['receipts']).toList()
      ..sort(
        (a, b) =>
            readIntValue(a['revision']).compareTo(readIntValue(b['revision'])),
      );
    for (final receipt in receipts) {
      settled =
          _settlePersonalMarketReceipt(receipt, account, journalScope: scope) ||
          settled;
    }
    return settled;
  }

  bool _settlePersonalMarketReceipt(
    Map<String, dynamic> receipt,
    String account, {
    required String journalScope,
  }) {
    final id = '${receipt['id'] ?? ''}';
    if (id.isEmpty) return false;
    final pending = personalMarketPending[id];
    final requesterTag = _personalMarketTag(receipt['requesterTag']);
    final isLocalPending =
        pending?['status'] == 'pending' &&
        pending?['scope'] == journalScope &&
        pending?['requesterTag'] == requesterTag &&
        pending?['requesterUserId'] == account &&
        receipt['requesterUserId'] == account;
    final approved = receipt['approved'] == true;
    var changed = false;
    if (approved) {
      for (final settlement
          in (receipt['settlements'] as List? ?? const []).whereType<Map>()) {
        if (settlement['userId'] != account) continue;
        final tag = _personalMarketTag(settlement['tag']);
        if (receipt['operation'] == 'buy' &&
            settlement['item'] is Map &&
            !isLocalPending) {
          continue;
        }
        if (!oculumCanPostPersonalMarketSettlement(
          personalMarketPending,
          receipt,
          account: account,
          scope: journalScope,
          tag: tag,
        )) {
          continue;
        }
        if (!_creditPersonalMarketSheet(
          tag,
          readIntValue(settlement['credit']),
          settlement['item'],
        )) {
          continue;
        }
        personalMarketPending[_personalMarketPostingKey(
          account,
          journalScope,
          id,
          tag,
        )] = {
          'status': 'applied',
          'requesterUserId': account,
          'privateMaster': receipt['privateMaster'] == true,
        };
        changed = true;
      }
    }
    if (isLocalPending) {
      if (approved &&
          receipt['operation'] == 'buy' &&
          !personalMarketPending.containsKey(
            _personalMarketPostingKey(account, journalScope, id, requesterTag),
          )) {
        return changed;
      }
      if (!approved &&
          !_creditPersonalMarketSheet(
            requesterTag,
            readIntValue(pending?['reservedObser']),
            pending?['item'],
          )) {
        return changed;
      }
      pending!['status'] = approved ? 'approved' : 'rejected';
      changed = true;
    }
    return changed;
  }

  bool _creditPersonalMarketSheet(String tag, int credit, Object? item) {
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0 ||
        readBoolValue(schedePersonaggio[index]['realtimeSharedSheet'])) {
      return false;
    }
    final itemData = _personalMarketMap(item);
    final received = itemData.isEmpty ? null : InventoryItem.fromJson(itemData);
    if (index == schedaCorrente) {
      if (credit > 0) {
        obserController.text = '${leggiNumero(obserController) + credit}';
        _commitPersonalMarketWallet();
      }
      if (received != null) {
        inventario.add(received);
        _commitPersonalMarketInventory();
      }
    } else {
      final sheet = schedePersonaggio[index];
      if (credit > 0) {
        sheet['obser'] = '${readIntValue(sheet['obser']) + credit}';
      }
      if (received != null) {
        sheet['inventario'] = [
          ...(sheet['inventario'] as List? ?? const []),
          received.toJson(),
        ];
      }
      if (credit > 0 || received != null) {
        sheet['localUpdatedAt'] = DateTime.now().toIso8601String();
      }
    }
    return true;
  }

  void _commitPersonalMarketWallet() {
    final sheet = schedePersonaggio[schedaCorrente];
    sheet['obser'] = obserController.text;
    sheet['localUpdatedAt'] = DateTime.now().toIso8601String();
  }

  void _commitPersonalMarketInventory() {
    final sheet = schedePersonaggio[schedaCorrente];
    // The generic saver keeps an older nonempty inventory when the current
    // inventory is empty. Store escrow explicitly, including the last item.
    sheet['inventario'] = inventario.map((item) => item.toJson()).toList();
    sheet['localUpdatedAt'] = DateTime.now().toIso8601String();
    invalidateDerivedDataCaches();
  }
}
