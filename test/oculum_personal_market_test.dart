import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  const listing = <String, dynamic>{
    'id': 'listing',
    'operation': 'list',
    'quantity': 3,
    'unitPrice': 15,
    'item': {'nome': 'Pergamena', 'quantita': 3, 'equipaggiata': false},
  };
  const purchase = <String, dynamic>{
    'id': 'purchase',
    'operation': 'buy',
    'offerId': 'listing',
    'quantity': 2,
    'unitPrice': 15,
    'reservedObser': 30,
  };
  Map<String, dynamic> apply(
    Map<String, dynamic> state,
    Map<String, dynamic> request, {
    String actor = 'SELLER',
    String role = 'player',
    bool privateMaster = false,
  }) => oculumApplyPersonalMarketOperation(
    state,
    request,
    actorTag: actor,
    actorUserId: '$actor-account',
    authenticatedRole: role,
    privateMaster: privateMaster,
  );

  test('concurrent purchases keep the approved price and remaining stock', () {
    var state = apply({}, listing);
    state = apply(state, {
      ...purchase,
      'id': 'bad-price',
      'unitPrice': 10,
      'reservedObser': 20,
    }, actor: 'BUYER');
    expect(state['receipts']['bad-price']['approved'], isFalse);
    state = apply(state, purchase, actor: 'BUYER');
    expect(state['offers']['listing']['quantity'], 1);
    expect(state['receipts']['purchase']['settlements'], [
      {'userId': 'SELLER-account', 'tag': 'SELLER', 'credit': 30},
      {
        'userId': 'BUYER-account',
        'tag': 'BUYER',
        'item': {'nome': 'Pergamena', 'quantita': 2, 'equipaggiata': false},
      },
    ]);
    expect(apply(state, purchase, actor: 'BUYER'), same(state));
    state = apply(state, {...purchase, 'id': 'no-stock'}, actor: 'OTHER');
    expect(state['receipts']['no-stock']['approved'], isFalse);
    expect(state['offers']['listing']['quantity'], 1);
  });

  test('only a verified Master can credit the latest paid difference', () {
    var state = apply(apply({}, listing), purchase, actor: 'BUYER');
    const discount = <String, dynamic>{
      'operation': 'discountSale',
      'saleId': 'purchase',
      'adjustedTotal': 20,
    };
    state = apply(state, {...discount, 'id': 'player-attempt'}, actor: 'BUYER');
    expect(state['receipts']['player-attempt']['approved'], isFalse);
    state = apply(
      state,
      {...discount, 'id': 'first-discount'},
      actor: 'MASTER',
      role: 'master',
    );
    expect(state['receipts']['first-discount']['settlements'], [
      {'userId': 'BUYER-account', 'tag': 'BUYER', 'credit': 10},
    ]);
    expect(state['receipts']['first-discount']['originSaleId'], 'purchase');
    // Saving and reloading preserves duplicate suppression.
    state = Map<String, dynamic>.from(jsonDecode(jsonEncode(state)) as Map);
    expect(
      apply(
        state,
        {...discount, 'id': 'first-discount'},
        actor: 'MASTER',
        role: 'master',
      ),
      same(state),
    );
    state = apply(
      state,
      {...discount, 'id': 'same-effective-total'},
      actor: 'MASTER',
      role: 'master',
    );
    expect(state['receipts']['same-effective-total']['settlements'], isEmpty);
    state = apply(
      state,
      {...discount, 'id': 'lower-total', 'adjustedTotal': 17},
      actor: 'MASTER',
      role: 'master',
    );
    expect(state['receipts']['lower-total']['settlements'], [
      {'userId': 'BUYER-account', 'tag': 'BUYER', 'credit': 3},
    ]);
    expect(state['sales']['purchase']['paid'], 30);
    expect(state['sales']['purchase']['refunded'], 13);
    expect(state['sales']['purchase']['effectiveTotal'], 17);
  });

  test('a discount waits for the buyer’s posted purchase on either device', () {
    const scope = 'room:campaign';
    const account = 'buyer-account';
    const tag = 'BUYER';
    const applied = {'status': 'applied', 'requesterUserId': account};
    const receipt = {'id': 'refund', 'approved': true, 'originSaleId': 'sale'};
    final journal = <String, Map<String, dynamic>>{};

    bool canPost() => oculumCanPostPersonalMarketSettlement(
      journal,
      receipt,
      account: account,
      scope: scope,
      tag: tag,
    );
    String posting(String context, String id) =>
        'applied:${jsonEncode([account, context, id, tag])}';

    expect(canPost(), isFalse);
    journal[posting('other:campaign', 'sale')] = applied;
    expect(canPost(), isFalse);
    journal[posting(scope, 'sale')] = {
      ...applied,
      'requesterUserId': 'different-account',
    };
    expect(canPost(), isFalse);
    journal[posting(scope, 'sale')] = applied;
    expect(canPost(), isTrue);
    journal[posting(scope, 'refund')] = applied;
    expect(canPost(), isFalse);
  });

  test('Master listings and receipts stay out of room snapshots', () {
    final public = apply({}, listing, actor: 'MASTER', role: 'master');
    expect(public['offers'], isEmpty);
    final private = apply(
      {},
      listing,
      actor: 'MASTER',
      role: 'master',
      privateMaster: true,
    );
    expect(private['offers']['listing']['quantity'], 3);
    expect(oculumPublicPersonalMarketSnapshot(private), isEmpty);
    expect(
      oculumPublicPersonalMarketSnapshot({
        'offers': private['offers'],
        'receipts': private['receipts'],
      }),
      containsPair('offers', isEmpty),
    );
    expect(
      oculumPublicPersonalMarketSnapshot({'receipts': private['receipts']}),
      containsPair('receipts', isEmpty),
    );
  });
}
