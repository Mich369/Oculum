part of '../../main.dart';

const int oculumMerchantBarterSecondPercent = 15;

bool oculumMerchantCanBarterAt(String location) => location != 'solar';

String _defaultMerchantLocation(String id) => switch (id) {
  _vaiternMerchantId || _lostTownMerchantId => 'city',
  _lostTownUpperMerchantId => 'solar',
  _ => 'outside',
};

int oculumMerchantBarterFallbackPercent(
  String difficulty,
  Random random, {
  bool masterDiscounted = false,
}) {
  final base = switch (normalizeTemporaryOculumDifficulty(difficulty)) {
    'oculum' => 0,
    'difficile' => 6,
    'facile' => 12,
    _ => 9,
  };
  if (masterDiscounted) return max(0, base - 3);
  return base == 0 ? random.nextInt(3) : base + 1 + random.nextInt(2);
}

typedef OculumMerchantBarterQuote = ({
  int firstObser,
  int credit,
  int secondObser,
  int cashChange,
  int tip,
  int luck,
  int fallbackDiscount,
});

/// Prices come from the current stock and credit from the chosen inventory units.
OculumMerchantBarterQuote? oculumMerchantBarterQuote({
  required int firstPrice,
  required int offerCredit,
  required int availableObser,
  required bool hasSecondOffer,
  required int fallbackDiscount,
  required bool fate,
  int? secondPrice,
  int tip = 0,
}) {
  if (firstPrice <= 0 || offerCredit <= 0) return null;
  final creditRemaining = offerCredit - firstPrice;
  final discount = creditRemaining > 0 && !hasSecondOffer
      ? fallbackDiscount.clamp(0, 99).toInt()
      : 0;
  final firstObser = oculumMerchantApplyPricePercent(
    firstPrice,
    100 - discount,
  );
  final secondObser = secondPrice == null
      ? 0
      : oculumMerchantApplyPricePercent(
          secondPrice,
          100 - oculumMerchantBarterSecondPercent,
        );
  if (secondPrice != null &&
      (!hasSecondOffer || secondPrice <= 0 || secondObser > creditRemaining)) {
    return null;
  }
  final changeBeforeTip = offerCredit - firstObser - secondObser;
  if (changeBeforeTip < -max(0, availableObser) ||
      tip < 0 ||
      tip > max(0, changeBeforeTip)) {
    return null;
  }
  return (
    firstObser: firstObser,
    credit: offerCredit,
    secondObser: secondObser,
    cashChange: changeBeforeTip - tip,
    tip: tip,
    luck: fate ? tip ~/ 9 : 0,
    fallbackDiscount: discount,
  );
}

const _merchantBarterTitleKinds = <String, String>{
  'arma': 'Arma',
  'armatura': 'Armatura',
  'scudo': 'Scudo',
  'scudo_offensivo': 'Scudo offensivo',
};

extension _OculumMerchantBarter on _OculumHomePageState {
  bool get _merchantBarterAtLocation {
    final profile = merchantProfiles
        .where((profile) => profile['id'] == merchantActiveProfileId)
        .firstOrNull;
    return oculumMerchantCanBarterAt(
      '${profile?['location'] ?? _defaultMerchantLocation(merchantActiveProfileId)}',
    );
  }

  int? _merchantOfferMasterPrice(Map<String, dynamic> offer) {
    final profile = merchantProfiles
        .where((profile) => profile['id'] == merchantActiveProfileId)
        .firstOrNull;
    final overrides = profile?['masterOfferPrices'];
    if (overrides is! Map) return null;
    final value = readIntValue(overrides['${offer['id'] ?? ''}']);
    return value > 0 ? value : null;
  }

  bool _merchantBarterIsMasterDiscounted(Map<String, dynamic> offer) {
    if (offer['masterDiscounted'] == true) return true;
    final override = _merchantOfferMasterPrice(offer);
    return override != null && override < _merchantOfferPriceBeforeCity(offer);
  }

  Future<void> _showMerchantBarterSettings() async {
    if (!realtimeIsMasterRole) return;
    final sheet = currentSheetScrollId();
    final profile = _activeMerchantProfile();
    final merchant = merchantActiveProfileId;
    final stock = recommendedMerchantStock()
        .where(_merchantBarterIsPhysicalOffer)
        .toList();
    final rawPrices = profile['masterOfferPrices'];
    final prices = rawPrices is Map
        ? Map<String, dynamic>.from(rawPrices)
        : <String, dynamic>{};
    final locations = {
      'outside': t('Fuori città', 'Outside a city'),
      'city': t('Città', 'City'),
      'solar': t('Zona solare', 'Solar zone'),
    };
    var location =
        '${profile['location'] ?? _defaultMerchantLocation(merchant)}';
    if (!locations.containsKey(location)) location = 'outside';
    var offer = stock.firstOrNull;
    var price = '${prices[offer?['id']] ?? ''}';
    void savePrice() {
      if (offer == null) return;
      final offerId = '${offer!['id']}';
      final value = int.tryParse(price.trim());
      if (value == null || value < 1) {
        prices.remove(offerId);
      } else {
        prices[offerId] = value;
      }
    }

    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text(
            t('Luogo e prezzi del mercante', 'Merchant location and prices'),
          ),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: location,
                    decoration: InputDecoration(
                      labelText: t('Luogo', 'Location'),
                    ),
                    items: [
                      for (final entry in locations.entries)
                        DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                    ],
                    onChanged: (value) => location = value ?? location,
                  ),
                  if (stock.isNotEmpty) ...[
                    DropdownButtonFormField<Map<String, dynamic>>(
                      initialValue: offer,
                      decoration: InputDecoration(
                        labelText: t('Articolo', 'Item'),
                      ),
                      isExpanded: true,
                      items: [
                        for (final entry in stock)
                          DropdownMenuItem(
                            value: entry,
                            child: Text(
                              '${entry['name']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) => refresh(() {
                        savePrice();
                        offer = value;
                        price = '${prices[value?['id']] ?? ''}';
                      }),
                    ),
                    TextFormField(
                      key: ValueKey(offer?['id']),
                      initialValue: price,
                      onChanged: (value) => price = value,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: t(
                          'Prezzo Master in Obser',
                          'Master price in Obser',
                        ),
                        helperText: t(
                          'Vuoto: prezzo ordinario',
                          'Blank: regular price',
                        ),
                        hintText: offer == null
                            ? null
                            : '${_merchantOfferPriceBeforeCity(offer!)}',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                savePrice();
                Navigator.pop(dialog, true);
              },
              child: Text(t('Salva', 'Save')),
            ),
          ],
        ),
      ),
    );
    if (accepted != true ||
        !mounted ||
        !realtimeIsMasterRole ||
        currentSheetScrollId() != sheet ||
        merchantActiveProfileId != merchant ||
        !identical(_activeMerchantProfile(), profile)) {
      return;
    }
    // ignore: invalid_use_of_protected_member
    setState(() {
      profile['location'] = location;
      profile['masterOfferPrices'] = prices;
    });
    programmaSalvataggio();
    unawaited(sendRealtimeMerchantRosterSnapshot());
  }

  bool _merchantBarterCanOffer(InventoryItem item) =>
      item.quantita > 0 &&
      !oculumIsLunarSymbolPiece(item) &&
      (item.craftData['explosiveCards'] != true ||
          merchantShopType == 'mercato_nero');

  List<Map<String, dynamic>> _merchantBarterStock() => [
    for (final offer in recommendedMerchantStock())
      if (_merchantBarterIsPhysicalOffer(offer) &&
          merchantOfferCost(offer) > 0 &&
          oculumMerchantCanPurchaseOffer(
            offer,
            characterGrade: leggiNumero(gradoController),
          ))
        offer,
  ];

  bool _merchantBarterIsPhysicalOffer(Map<String, dynamic> offer) {
    final kind = '${offer['kind'] ?? ''}';
    return kind.isNotEmpty &&
        !const {
          'monster_book_page',
          'corruption_page',
          'nurse_service',
          'fallen_eye',
        }.contains(kind) &&
        !kind.startsWith('black_market_') &&
        !(kind == 'technique_scroll' && offer['blackMarketSelected'] == true);
  }

  int _merchantBarterOfferedCredit(Map<InventoryItem, int> payment) =>
      payment.entries.fold(
        0,
        (total, entry) =>
            total + merchantSaleUnitValue(entry.key) * entry.value,
      );

  List<Map<String, dynamic>> _merchantBarterSecondOffers(
    List<Map<String, dynamic>> stock,
    Map<String, dynamic> first,
    int offerCredit,
  ) {
    final credit = offerCredit - merchantOfferCost(first);
    if (credit <= 0) return const [];
    return [
      for (final other in stock)
        if (other['id'] != first['id'] &&
            oculumMerchantApplyPricePercent(
                  merchantOfferCost(other),
                  100 - oculumMerchantBarterSecondPercent,
                ) <=
                credit)
          other,
    ];
  }

  OculumMerchantBarterQuote? _merchantBarterQuote(
    Map<InventoryItem, int> payment,
    Map<String, dynamic> first,
    Map<String, dynamic>? second,
    List<Map<String, dynamic>> secondOptions, {
    int tip = 0,
  }) {
    final offerId = '${first['id']}';
    final counts = _activeMerchantProfile()['barterTransactionsByOffer'];
    final previous = counts is Map ? readIntValue(counts[offerId]) : 0;
    final seed = monsterSpriteStableSeed(
      '${currentSheetScrollId()}:$merchantActiveProfileId:$offerId:$previous',
    );
    return oculumMerchantBarterQuote(
      firstPrice: merchantOfferCost(first),
      offerCredit: _merchantBarterOfferedCredit(payment),
      availableObser: leggiNumero(obserController),
      hasSecondOffer: secondOptions.isNotEmpty,
      secondPrice: second == null ? null : merchantOfferCost(second),
      fallbackDiscount: oculumMerchantBarterFallbackPercent(
        campaignDifficulty,
        Random(seed),
        masterDiscounted: _merchantBarterIsMasterDiscounted(first),
      ),
      fate: !identityIsChaos,
      tip: tip,
    );
  }

  Widget merchantBarterButton({VoidCallback? refresh}) => OutlinedButton.icon(
    onPressed: inventario.any(_merchantBarterCanOffer)
        ? () async {
            await _showMerchantBarter();
            if (mounted) refresh?.call();
          }
        : null,
    icon: const Icon(Icons.swap_horiz),
    label: Text(t('Baratta oggetti', 'Barter items')),
  );

  Future<void> _showMerchantBarter() async {
    if (!_merchantBarterAtLocation) return;
    final sheet = currentSheetScrollId();
    final merchant = merchantActiveProfileId;
    final shop = merchantShopType;
    final plane = selectedPlaneId;
    final stock = _merchantBarterStock();
    final inventory = inventario.where(_merchantBarterCanOffer).toList();
    if (stock.isEmpty || inventory.isEmpty) {
      aggiungiLog(t('Nessun baratto disponibile.', 'No barter available.'));
      return;
    }
    var first = stock.first;
    Map<String, dynamic>? second;
    var firstTitleKind = 'arma';
    var secondTitleKind = 'arma';
    var tipInput = '';
    final payment = <InventoryItem, int>{};
    final accepted = await showDialog<OculumMerchantBarterQuote>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, refresh) {
          final credit = _merchantBarterOfferedCredit(payment);
          final secondOptions = _merchantBarterSecondOffers(
            stock,
            first,
            credit,
          );
          final selectedSecond = secondOptions.contains(second) ? second : null;
          final draft = _merchantBarterQuote(
            payment,
            first,
            selectedSecond,
            secondOptions,
          );
          final tip = tipInput.isEmpty ? 0 : int.tryParse(tipInput);
          final tipValid = tip != null && tip <= max(0, draft?.cashChange ?? 0);
          final quote = draft == null || tip == null || !tipValid
              ? null
              : _merchantBarterQuote(
                  payment,
                  first,
                  selectedSecond,
                  secondOptions,
                  tip: tip,
                );
          return AlertDialog(
            title: Text(t('Baratta oggetti', 'Barter items')),
            content: SizedBox(
              width: 530,
              height: min(580, MediaQuery.sizeOf(context).height * .62),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        DropdownButtonFormField<Map<String, dynamic>>(
                          initialValue: first,
                          decoration: InputDecoration(
                            labelText: t('Primo articolo', 'First item'),
                          ),
                          isExpanded: true,
                          items: [
                            for (final offer in stock)
                              DropdownMenuItem(
                                value: offer,
                                child: Text(
                                  '${offer['name']} · ${merchantOfferCost(offer)} O',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (offer) {
                            if (offer == null) return;
                            refresh(() {
                              first = offer;
                              second = null;
                              tipInput = '';
                            });
                          },
                        ),
                        if (first['kind'] == 'title_item')
                          _merchantBarterTitlePicker(
                            firstTitleKind,
                            (value) => firstTitleKind = value,
                          ),
                      ],
                    ),
                  ),
                  SliverList.builder(
                    itemCount: inventory.length,
                    itemBuilder: (context, index) {
                      final item = inventory[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(item.nome),
                        subtitle: Text(
                          '${item.quantita} · ${merchantSaleUnitValue(item)} O / ${t('unità', 'unit')}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              tooltip: t('Rimuovi unità', 'Remove unit'),
                              onPressed: !payment.containsKey(item)
                                  ? null
                                  : () => refresh(() {
                                      final quantity = payment[item]! - 1;
                                      if (quantity == 0) {
                                        payment.remove(item);
                                      } else {
                                        payment[item] = quantity;
                                      }
                                      second = null;
                                      tipInput = '';
                                    }),
                            ),
                            Text('${payment[item] ?? 0}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              tooltip: t('Offri unità', 'Offer unit'),
                              onPressed: (payment[item] ?? 0) >= item.quantita
                                  ? null
                                  : () => refresh(() {
                                      payment[item] = (payment[item] ?? 0) + 1;
                                      second = null;
                                      tipInput = '';
                                    }),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        if (secondOptions.isNotEmpty)
                          DropdownButtonFormField<Map<String, dynamic>>(
                            key: ValueKey((first, credit)),
                            initialValue: selectedSecond,
                            hint: Text(t('Resto in Obser', 'Change in Obser')),
                            decoration: InputDecoration(
                              labelText: t(
                                'Secondo articolo · sconto 15%',
                                'Second item · 15% off',
                              ),
                            ),
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                child: Text(
                                  t('Resto in Obser', 'Change in Obser'),
                                ),
                              ),
                              for (final offer in secondOptions)
                                DropdownMenuItem(
                                  value: offer,
                                  child: Text(
                                    '${offer['name']} · ${oculumMerchantApplyPricePercent(merchantOfferCost(offer), 100 - oculumMerchantBarterSecondPercent)} O',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (offer) => refresh(() {
                              second = offer;
                              tipInput = '';
                            }),
                          ),
                        if (selectedSecond?['kind'] == 'title_item')
                          _merchantBarterTitlePicker(
                            secondTitleKind,
                            (value) => secondTitleKind = value,
                          ),
                        if (draft != null && draft.cashChange > 0)
                          TextFormField(
                            key: ValueKey((first, selectedSecond, credit)),
                            initialValue: tipInput,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) =>
                                refresh(() => tipInput = value),
                            decoration: InputDecoration(
                              labelText: t(
                                'Mancia facoltativa · Obser',
                                'Optional tip · Obser',
                              ),
                              helperText: '0–${draft.cashChange} O',
                              errorText: tipValid
                                  ? null
                                  : t(
                                      'La mancia supera il resto.',
                                      'The tip exceeds the change.',
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (quote != null)
                Text(_merchantBarterSummary(quote))
              else if (credit > 0 && draft == null)
                Text(
                  t(
                    'Credito e Obser insufficienti.',
                    'Not enough credit and Obser.',
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: Text(t('Annulla', 'Cancel')),
              ),
              FilledButton(
                onPressed: quote == null
                    ? null
                    : () => Navigator.pop(dialog, quote),
                child: Text(t('Conferma baratto', 'Confirm barter')),
              ),
            ],
          );
        },
      ),
    );
    if (accepted == null || !mounted) return;
    if (currentSheetScrollId() != sheet ||
        merchantActiveProfileId != merchant ||
        merchantShopType != shop ||
        selectedPlaneId != plane ||
        !_merchantBarterAtLocation ||
        payment.entries.any(
          (entry) =>
              !inventario.contains(entry.key) ||
              !_merchantBarterCanOffer(entry.key) ||
              entry.value > entry.key.quantita,
        )) {
      _merchantBarterChanged();
      return;
    }
    final liveStock = _merchantBarterStock();
    final liveSecondOptions = _merchantBarterSecondOffers(
      liveStock,
      first,
      accepted.credit,
    );
    if (!liveStock.contains(first) ||
        (second != null && !liveSecondOptions.contains(second)) ||
        _merchantBarterQuote(
              payment,
              first,
              second,
              liveSecondOptions,
              tip: accepted.tip,
            ) !=
            accepted) {
      _merchantBarterChanged();
      return;
    }
    final firstItem = merchantItemFromOffer(
      first,
      titleType: firstTitleKind,
      paidObser: accepted.firstObser,
    );
    final other = second;
    final secondItem = other == null
        ? null
        : merchantItemFromOffer(
            other,
            titleType: secondTitleKind,
            paidObser: accepted.secondObser,
          );
    final profile = _activeMerchantProfile();
    final rawCounts = profile['barterTransactionsByOffer'];
    final counts = rawCounts is Map
        ? Map<String, dynamic>.from(rawCounts)
        : <String, dynamic>{};
    final firstId = '${first['id']}';
    // ignore: invalid_use_of_protected_member
    setState(() {
      for (final entry in payment.entries) {
        final item = entry.key;
        if (item.quantita > entry.value) {
          item.quantita -= entry.value;
        } else {
          if (item.equipaggiata) {
            applicaScudoItemAttuale(item, -1);
            item.equipaggiata = false;
          }
          inventario.remove(item);
        }
      }
      _receiveMerchantInventoryItem(first, firstItem);
      if (other != null && secondItem != null) {
        _receiveMerchantInventoryItem(other, secondItem);
      }
      obserController.text =
          '${leggiNumero(obserController) + accepted.cashChange}';
      fortuna += accepted.luck;
      counts[firstId] = readIntValue(counts[firstId]) + 1;
      profile['barterTransactionsByOffer'] = counts;
      final summary = _merchantBarterSummary(accepted);
      final acquisitions = [
        firstItem.nome,
        if (secondItem != null) secondItem.nome,
      ].join(', ');
      risultato = '${t('Baratto', 'Barter')}: $acquisitions · $summary';
      aggiungiLog(risultato);
    });
    _saveActiveMerchantProfileStock();
    programmaSalvataggio();
    if (_merchantOfferSummonsPawn(first)) await activatePawnItem(firstItem);
    if (mounted &&
        currentSheetScrollId() == sheet &&
        other != null &&
        secondItem != null &&
        _merchantOfferSummonsPawn(other)) {
      await activatePawnItem(secondItem);
    }
    if (mounted && currentSheetScrollId() == sheet) {
      unawaited(sendRealtimeActiveSheetToStaff());
    }
  }

  Widget _merchantBarterTitlePicker(
    String value,
    ValueChanged<String> onChanged,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(
      labelText: t('Tipo di oggetto del Titolo', 'Title item type'),
    ),
    items: [
      for (final kind in _merchantBarterTitleKinds.entries)
        DropdownMenuItem(value: kind.key, child: Text(kind.value)),
    ],
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );

  String _merchantBarterSummary(OculumMerchantBarterQuote quote) {
    final difference = quote.cashChange;
    return [
      '${t('Valore offerto', 'Offer value')} ${quote.credit} O',
      if (quote.fallbackDiscount > 0)
        '${t('Sconto sul primo articolo', 'First item discount')} ${quote.fallbackDiscount}%',
      if (difference >= 0)
        '${t('Resto', 'Change')} $difference O'
      else
        '${t('Da aggiungere', 'Obser to add')} ${-difference} O',
      if (quote.tip > 0) '${t('Mancia', 'Tip')} ${quote.tip} O',
      if (quote.luck > 0) '+${quote.luck} ${t('Fortuna', 'Luck')}',
    ].join(' · ');
  }

  void _merchantBarterChanged() {
    aggiungiLog(
      t(
        'Il mercante o l’offerta sono cambiati. Riapri il baratto per controllare il nuovo prezzo.',
        'The merchant or the offer changed. Reopen barter to check the new price.',
      ),
    );
  }
}
