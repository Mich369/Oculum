part of '../../main.dart';

Map<String, dynamic> _personalMarketMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

Iterable<Map<String, dynamic>> _personalMarketRows(Object? value) =>
    _personalMarketMap(value).values.whereType<Map>().map(_personalMarketMap);

bool _personalMarketPublicTrader(String role) =>
    role == 'player' || role == 'coMaster';

String _personalMarketPostingKey(
  String account,
  String scope,
  String receiptId,
  String tag,
) => 'applied:${jsonEncode([account, scope, receiptId, tag])}';

bool oculumCanPostPersonalMarketSettlement(
  Map<String, Map<String, dynamic>> journal,
  Map<String, dynamic> receipt, {
  required String account,
  required String scope,
  required String tag,
}) {
  final id = '${receipt['id'] ?? ''}';
  bool posted(String receiptId) {
    final entry =
        journal[_personalMarketPostingKey(account, scope, receiptId, tag)];
    return entry?['status'] == 'applied' &&
        entry?['requesterUserId'] == account;
  }

  final saleId = '${receipt['originSaleId'] ?? ''}';
  return receipt['approved'] == true &&
      id.isNotEmpty &&
      !posted(id) &&
      (saleId.isEmpty || posted(saleId));
}

Map<String, dynamic> oculumApplyPersonalMarketOperation(
  Map<String, dynamic> previous,
  Map<String, dynamic> request, {
  required String actorTag,
  required String actorUserId,
  required String authenticatedRole,
  bool privateMaster = false,
}) {
  if (actorTag.isEmpty || actorUserId.isEmpty) return previous;
  final master = authenticatedRole == 'master';
  if (previous['privateMaster'] == true && !privateMaster ||
      privateMaster && !master ||
      !master && !_personalMarketPublicTrader(authenticatedRole)) {
    return previous;
  }
  final id = '${request['id'] ?? ''}';
  final operation = '${request['operation'] ?? ''}';
  if (id.isEmpty) return previous;
  final receipts = _personalMarketMap(previous['receipts']);
  if (receipts.containsKey(id)) return previous;

  final offers = _personalMarketMap(previous['offers']);
  final sales = _personalMarketMap(previous['sales']);
  final profiles = _personalMarketMap(previous['profiles']);
  final revision = readIntValue(previous['revision']) + 1;
  final receipt = <String, dynamic>{
    'id': id,
    'operation': operation,
    'requesterTag': actorTag,
    'requesterUserId': actorUserId,
    'approved': false,
    'revision': revision,
    if (privateMaster) 'privateMaster': true,
  };
  final offerId = '${request['offerId'] ?? ''}';
  final offer = _personalMarketMap(offers[offerId]);
  final sellerTag = '${offer['sellerTag'] ?? ''}';
  final sellerUserId = '${offer['sellerUserId'] ?? ''}';
  final ownsOffer =
      sellerUserId == actorUserId && (sellerTag == actorTag || privateMaster);
  final listingAllowed = !master || privateMaster;
  final quantity = request['quantity'];
  final unitPrice = request['unitPrice'];
  final settlements = <Map<String, dynamic>>[];

  void credit(String account, String tag, int amount) {
    if (amount > 0) {
      settlements.add({'userId': account, 'tag': tag, 'credit': amount});
    }
  }

  void deliver(String account, String tag, int count) {
    settlements.add({
      'userId': account,
      'tag': tag,
      'item': {..._personalMarketMap(offer['item']), 'quantita': count},
    });
  }

  switch (operation) {
    case 'profile':
      final name = '${request['name'] ?? ''}'.trim();
      final argb = request['argb'];
      if (listingAllowed &&
          name.isNotEmpty &&
          argb is int &&
          argb >= 0 &&
          argb <= 0xffffffff) {
        profiles[privateMaster ? actorUserId : actorTag] = {
          'ownerTag': actorTag,
          'ownerRole': authenticatedRole,
          'ownerName': '${request['ownerName'] ?? ''}',
          'name': name,
          'argb': argb,
        };
        receipt['approved'] = true;
      }
    case 'list':
      final item = _personalMarketMap(request['item']);
      if (listingAllowed &&
          quantity is int &&
          quantity > 0 &&
          unitPrice is int &&
          unitPrice >= 0 &&
          item['quantita'] == quantity &&
          '${item['nome'] ?? ''}'.trim().isNotEmpty &&
          item['equipaggiata'] == false) {
        offers[id] = {
          'id': id,
          'sellerTag': actorTag,
          'sellerUserId': actorUserId,
          'ownerRole': authenticatedRole,
          'ownerName': '${request['ownerName'] ?? ''}',
          'item': item,
          'quantity': quantity,
          'unitPrice': unitPrice,
        };
        receipt['approved'] = true;
      }
    case 'cancel':
      if (listingAllowed && ownsOffer) {
        deliver(actorUserId, sellerTag, offer['quantity'] as int);
        offers.remove(offerId);
        receipt['approved'] = true;
      }
    case 'buy':
      final paid = request['reservedObser'];
      final stock = offer['quantity'];
      if (!privateMaster &&
          sellerUserId.isNotEmpty &&
          sellerUserId != actorUserId &&
          _personalMarketPublicTrader('${offer['ownerRole']}') &&
          quantity is int &&
          quantity > 0 &&
          stock is int &&
          quantity <= stock &&
          unitPrice is int &&
          unitPrice >= 0 &&
          unitPrice == offer['unitPrice'] &&
          paid is int &&
          paid >= 0 &&
          paid ~/ quantity == unitPrice &&
          paid % quantity == 0) {
        credit(sellerUserId, sellerTag, paid);
        deliver(actorUserId, actorTag, quantity);
        if (quantity == stock) {
          offers.remove(offerId);
        } else {
          offers[offerId] = {
            ...offer,
            'quantity': stock - quantity,
            'item': {
              ..._personalMarketMap(offer['item']),
              'quantita': stock - quantity,
            },
          };
        }
        sales[id] = {
          'id': id,
          'ownerRole': offer['ownerRole'],
          'sellerTag': sellerTag,
          'buyerTag': actorTag,
          'buyerUserId': actorUserId,
          'itemName': '${_personalMarketMap(offer['item'])['nome']}',
          'quantity': quantity,
          'paid': paid,
          'refunded': 0,
          'effectiveTotal': paid,
        };
        receipt['approved'] = true;
      }
    case 'discountOffer':
      final price = offer['unitPrice'];
      if (master &&
          (!privateMaster || ownsOffer) &&
          price is int &&
          unitPrice is int &&
          unitPrice >= 0 &&
          unitPrice < price) {
        offers[offerId] = {...offer, 'unitPrice': unitPrice};
        receipt['approved'] = true;
      }
    case 'discountSale':
      final saleId = '${request['saleId'] ?? ''}';
      final sale = _personalMarketMap(sales[saleId]);
      final adjusted = request['adjustedTotal'];
      final paid = sale['paid'];
      final refunded = sale['refunded'];
      if (master &&
          !privateMaster &&
          adjusted is int &&
          adjusted >= 0 &&
          paid is int &&
          refunded is int &&
          adjusted < paid - refunded) {
        final difference = paid - refunded - adjusted;
        credit('${sale['buyerUserId']}', '${sale['buyerTag']}', difference);
        receipt['originSaleId'] = saleId;
        sales[saleId] = {
          ...sale,
          'refunded': refunded + difference,
          'effectiveTotal': adjusted,
        };
        receipt['approved'] = true;
      }
  }
  receipts[id] = {...receipt, 'settlements': settlements};
  return {
    'revision': revision,
    'profiles': profiles,
    'offers': offers,
    'sales': sales,
    'receipts': receipts,
    if (privateMaster) 'privateMaster': true,
  };
}

Map<String, dynamic> oculumPublicPersonalMarketSnapshot(
  Map<String, dynamic> state,
) {
  if (state['privateMaster'] == true) return <String, dynamic>{};
  Map<String, dynamic> publicRows(String field) => Map.fromEntries(
    _personalMarketMap(state[field]).entries.where((entry) {
      final row = _personalMarketMap(entry.value);
      return _personalMarketPublicTrader('${row['ownerRole']}');
    }),
  );

  return {
    'revision': readIntValue(state['revision']),
    'profiles': publicRows('profiles'),
    'offers': publicRows('offers'),
    'sales': publicRows('sales'),
    'receipts': Map.fromEntries(
      _personalMarketMap(state['receipts']).entries.where(
        (entry) => entry.value is Map && entry.value['privateMaster'] != true,
      ),
    ),
  };
}
