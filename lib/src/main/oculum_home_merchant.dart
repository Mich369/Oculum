part of '../../main.dart';

/// Negoziante locale della scheda. Lo stock usa il salvataggio della scheda,
/// ma il suo identificatore di sessione lo rinnova solo dopo la chiusura e
/// riapertura dell'app: non cambia ad ogni rebuild o apertura del pannello.
extension _OculumHomeMerchant on _OculumHomePageState {
  List<Map<String, dynamic>> ensureMerchantStock() {
    if (merchantStockSessionId == merchantRuntimeSessionId &&
        merchantStock.isNotEmpty) {
      return merchantStock;
    }
    final random = Random(
      monsterSpriteStableSeed(currentSheetScrollId()) ^
          DateTime.now().microsecondsSinceEpoch,
    );
    merchantStock = <Map<String, dynamic>>[
      {
        'id': 'raw_vitalium',
        'name': 'Vitalium Grezzo',
        'cost': 13 + random.nextInt(7),
        'kind': 'raw_vitalium',
        'desc': 'Consumabile: cura HP pari all Oculum che scegli di immettere.',
      },
      {
        'id': 'refined_vitalium',
        'name': 'Vitalium Ridefinito',
        'cost': 100 + random.nextInt(61),
        'kind': 'refined_vitalium',
        'desc': 'Refulla HP, integrita, Oculum e statistiche temporanee.',
      },
      {
        'id': 'oculum_vial',
        'name': 'Fiala di Oculum',
        'cost': 6 + random.nextInt(3),
        'kind': 'oculum_vial',
        'desc': 'Consumabile: ricarica 1d4 Oculum.',
      },
      {
        'id': 'title_item',
        'name': 'Item Titolo',
        'cost': 75 + random.nextInt(46),
        'kind': 'title_item',
        'desc': 'Scegli tu se diventa arma, armatura o scudo.',
      },
    ];
    if (random.nextInt(12) == 0) {
      merchantStock.add(<String, dynamic>{
        'id': 'scroll_bone_prison',
        'name': 'Pergamena della Prigione d Ossa',
        'cost': 160,
        'kind': 'bone_prison_scroll',
        'desc':
            'Rara. Imprigiona il bersaglio, applica Stordito e infligge danno perforante.',
      });
    }
    // Catalogo > 200 oggetti: ogni scheda ne vede solo pochi, ma non pesca
    // sempre dagli stessi dieci nomi. Lo stock salvato resta invariato fino al
    // prossimo avvio dell'app.
    const materials = <String>[
      'bronzo rovinato',
      'ferro opaco',
      'rame freddo',
      'osso levigato',
      'legno nero',
      'acciaio vecchio',
      'vetro fumé',
      'pietra di fiume',
      'cuoio duro',
      'argento annerito',
      'corallo secco',
      'cenere compressa',
      'ottone consumato',
      'salice rosso',
      'sale nero',
      'vetro di luna',
    ];
    const weapons = <String>[
      'coltellino',
      'spada corta',
      'spada lunga',
      'sciabola',
      'stocco',
      'ascia',
      'mazza',
      'martello',
      'lancia',
      'picca',
      'alabarda',
      'falce',
      'frusta',
      'arco',
      'balestra',
      'guanti d arme',
    ];
    const protections = <String>[
      'scudo',
      'brocchiere',
      'mantello',
      'giubba',
      'corazza',
      'piastra',
      'elmo',
      'bracciale',
      'stivali',
      'anello',
      'cappuccio',
      'targa',
    ];
    final catalog = <({String name, bool weapon})>[
      for (final material in materials)
        for (final weapon in weapons)
          (name: '$weapon di $material', weapon: true),
      for (final material in materials)
        for (final protection in protections)
          (name: '$protection di $material', weapon: false),
    ];
    for (var i = 0; i < 8; i++) {
      final source = catalog[random.nextInt(catalog.length)];
      final grade = random.nextInt(40) == 0 ? 1 + random.nextInt(12) : 0;
      final weapon = source.weapon;
      final damage = grade == 0
          ? 2 + random.nextInt(5)
          : 12 + grade * 8 + random.nextInt(7);
      final defence = grade == 0
          ? 1 + random.nextInt(3)
          : 3 + grade * 4 + random.nextInt(4);
      merchantStock.add(<String, dynamic>{
        'id': 'merchant_${i}_${random.nextInt(1 << 31)}',
        'name': source.name,
        'cost': grade == 0
            ? 25 + random.nextInt(51)
            : grade * (100 + random.nextInt(101)),
        'kind': 'gear',
        'grade': grade,
        'weapon': weapon,
        'damage': damage,
        'defence': defence,
        'quickReaction': grade > 0 && random.nextInt(9) == 0,
        'desc': grade == 0
            ? 'Reliquia minuta: bonus difensivo o offensivo contenuto.'
            : 'Oggetto graduato molto raro: richiede Grado $grade per essere equipaggiato.',
      });
    }
    merchantStockSessionId = merchantRuntimeSessionId;
    return merchantStock;
  }

  Widget merchantQuickPanel() {
    final stock = ensureMerchantStock();
    return gothicPanel(
      borderColor: tertiaryColor.withValues(alpha: .7),
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (open) {
            // ignore: invalid_use_of_protected_member
            setState(() => merchantIsOpen = open);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          leading: const Icon(
            Icons.storefront_outlined,
            color: Color(0xFFE6D8BD),
          ),
          title: Text(
            t('Mercante in vista', 'Merchant in sight'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            t(
              'Stock fisso fino alla prossima apertura dell app.',
              'Fixed stock until the next app launch.',
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: leggiNumero(obserController) < 20
                    ? null
                    : buyAscensionDustFromMerchant,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('20 Obser → 1 Ascension Dust'),
              ),
            ),
            for (final offer in stock)
              ListTile(
                dense: true,
                title: Text(
                  '${offer['name']}',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${offer['desc']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                trailing: FilledButton(
                  onPressed:
                      leggiNumero(obserController) < readIntValue(offer['cost'])
                      ? null
                      : () => buyMerchantOffer(offer),
                  child: Text('${offer['cost']} O'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> showMerchantDialog() async {
    final stock = ensureMerchantStock();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          backgroundColor: const Color(0xFF0D0C13),
          title: Text('Negoziante', style: TextStyle(color: tertiaryColor)),
          content: SizedBox(
            width: min(620, MediaQuery.sizeOf(context).width * .94),
            height: min(560, MediaQuery.sizeOf(context).height * .68),
            child: ListView.builder(
              itemCount: stock.length,
              itemBuilder: (context, index) {
                final offer = stock[index];
                final cost = readIntValue(offer['cost']);
                return ListTile(
                  title: Text(
                    '${offer['name']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${offer['desc']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: FilledButton(
                    onPressed: leggiNumero(obserController) < cost
                        ? null
                        : () async {
                            await buyMerchantOffer(offer);
                            if (mounted) refresh(() {});
                          },
                    child: Text('$cost O'),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t('Chiudi', 'Close')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> buyMerchantOffer(Map<String, dynamic> offer) async {
    final cost = readIntValue(offer['cost']);
    if (leggiNumero(obserController) < cost) return;
    final kind = '${offer['kind'] ?? ''}';
    String titleType = '';
    if (kind == 'title_item') {
      titleType =
          await showDialog<String>(
            context: context,
            builder: (context) => SimpleDialog(
              title: const Text('Scegli il tuo Item Titolo'),
              children: [
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'arma'),
                  child: const Text('Arma'),
                ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'armatura'),
                  child: const Text('Armatura'),
                ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'scudo'),
                  child: const Text('Scudo'),
                ),
              ],
            ),
          ) ??
          '';
      if (titleType.isEmpty) return;
    }
    // ignore: invalid_use_of_protected_member
    // ignore: invalid_use_of_protected_member
    setState(() {
      obserController.text = (leggiNumero(obserController) - cost).toString();
      final item = merchantItemFromOffer(offer, titleType: titleType);
      inventario.add(item);
      risultato = 'Negoziante: hai speso $cost Obser per ${item.nome}.';
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  /// Il mercante paga circa un sesto del valore stimato: utile, ma spilorcio.
  int merchantSaleValue(InventoryItem item) {
    final grade = max(item.gradoOggetto, item.gradoRichiesto);
    final rawValue =
        18 +
        item.bonusDanno * 8 +
        item.bonusDifesa * 10 +
        item.bonusScudo * 3 +
        item.bonusScudoOculum * 12 +
        grade * grade * 90;
    return max(1, rawValue ~/ 6) * max(1, item.quantita);
  }

  void sellInventoryItemToMerchant(InventoryItem item) {
    if (!merchantIsOpen || !inventario.contains(item)) return;
    final payment = merchantSaleValue(item);
    // ignore: invalid_use_of_protected_member
    setState(() {
      if (item.equipaggiata) {
        applicaScudoItemAttuale(item, -1);
        item.equipaggiata = false;
      }
      inventario.remove(item);
      obserController.text = (leggiNumero(obserController) + payment)
          .toString();
      risultato = 'Negoziante: hai venduto ${item.nome} per $payment Obser.';
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void buyAscensionDustFromMerchant() {
    if (leggiNumero(obserController) < 20) return;
    // ignore: invalid_use_of_protected_member
    setState(() {
      obserController.text = (leggiNumero(obserController) - 20).toString();
      ascensionDustController.text = (leggiNumero(ascensionDustController) + 1)
          .toString();
      risultato = 'Negoziante: 20 Obser convertiti in 1 Ascension Dust.';
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  InventoryItem merchantItemFromOffer(
    Map<String, dynamic> offer, {
    String titleType = '',
  }) {
    final kind = '${offer['kind'] ?? ''}';
    if (kind == 'raw_vitalium') {
      return InventoryItem(
        nome: 'Vitalium Grezzo',
        peso: .1,
        quantita: 1,
        note: 'Consumabile: cura HP pari all Oculum immesso.',
      );
    }
    if (kind == 'refined_vitalium') {
      return InventoryItem(
        nome: 'Vitalium Ridefinito',
        peso: .2,
        quantita: 1,
        note:
            'Consumabile: refulla HP, integrita, Oculum e statistiche temporanee.',
      );
    }
    if (kind == 'oculum_vial') {
      return InventoryItem(
        nome: 'Fiala di Oculum',
        peso: .1,
        quantita: 1,
        note: 'Consumabile: ricarica 1d4 Oculum.',
      );
    }
    if (kind == 'bone_prison_scroll') {
      return InventoryItem(
        nome: 'Pergamena della Prigione d Ossa',
        peso: .1,
        quantita: 1,
        note:
            'Usabile: infligge 12 danni perforanti e applica Stordito per 1 turno al bersaglio della scheda attiva.',
      );
    }
    final grade = readIntValue(offer['grade']);
    final isTitle = kind == 'title_item';
    final weapon = isTitle
        ? titleType == 'arma'
        : readBoolValue(offer['weapon']);
    final shield = isTitle ? titleType == 'scudo' : !weapon && grade > 0;
    return InventoryItem(
      nome: isTitle ? 'Item Titolo — $titleType' : '${offer['name']}',
      peso: 1.2,
      quantita: 1,
      note: isTitle ? 'Oggetto scelto dal Negoziante.' : '${offer['desc']}',
      arma: weapon,
      protegge: !weapon,
      bonusDanno: weapon
          ? max(0, readIntValue(offer['damage'], fallback: 2 + grade * 8))
          : 0,
      bonusDifesa: weapon
          ? 0
          : max(0, readIntValue(offer['defence'], fallback: 1 + grade * 4)),
      bonusScudo: shield ? 4 + grade * 10 : (weapon ? 0 : 2 + grade * 4),
      bonusScudoOculum: grade >= 3 && shield ? 4 + grade * 3 : 0,
      gradoOggetto: grade,
      gradoRichiesto: grade,
      elementoDanno: grade >= 2 ? 'Oculum' : 'Fisico',
      buff: readBoolValue(offer['quickReaction'])
          ? '@ReazioneVeloce+1'
          : grade >= 3 && shield
          ? '@SchivateOculum+1'
          : '',
    );
  }

  bool isMerchantConsumable(InventoryItem item) => const <String>{
    'Vitalium Grezzo',
    'Vitalium Ridefinito',
    'Fiala di Oculum',
    'Pergamena della Prigione d Ossa',
  }.contains(item.nome.trim());

  Future<void> useMerchantConsumable(InventoryItem item) async {
    if (!inventario.contains(item) || !isMerchantConsumable(item)) return;
    var amount = 0;
    if (item.nome.trim() == 'Vitalium Grezzo') {
      final available = max(0, leggiNumero(currentOculumController));
      if (available <= 0) {
        risultato = 'Vitalium Grezzo: non hai Oculum da immettere.';
        aggiungiLog(risultato);
        return;
      }
      final input = TextEditingController(text: '1');
      amount =
          await showDialog<int>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Vitalium Grezzo'),
              content: TextField(
                controller: input,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Oculum da immettere (1–$available)',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    readIntValue(input.text).clamp(1, available),
                  ),
                  child: const Text('Usa'),
                ),
              ],
            ),
          ) ??
          0;
      input.dispose();
      if (amount <= 0) return;
    }
    // ignore: invalid_use_of_protected_member
    setState(() {
      switch (item.nome.trim()) {
        case 'Vitalium Grezzo':
          currentOculumController.text = max(
            0,
            leggiNumero(currentOculumController) - amount,
          ).toString();
          currentHpController.text = min(
            maxHp(),
            leggiNumero(currentHpController) + amount,
          ).toString();
          risultato = 'Vitalium Grezzo: -$amount Oculum, +$amount HP.';
          break;
        case 'Vitalium Ridefinito':
          currentHpController.text = maxHp().toString();
          currentOculumController.text = oculumTotale().toString();
          for (final art in arti) {
            art.integritaCorrente = artIntegrityEffectiveMaximum(art);
          }
          currentResilienzaController.text = resilienzaTotale().toString();
          currentVolontaController.text = volontaTotale().toString();
          currentMateriaController.text = materiaTotale().toString();
          currentOculumController.text = oculumTotale().toString();
          risultato = 'Vitalium Ridefinito: risorse e integrita ripristinate.';
          break;
        case 'Fiala di Oculum':
          amount = Random().nextInt(4) + 1;
          currentOculumController.text = min(
            oculumTotale(),
            leggiNumero(currentOculumController) + amount,
          ).toString();
          risultato = 'Fiala di Oculum: +$amount Oculum (1d4).';
          break;
        case 'Pergamena della Prigione d Ossa':
          final before = hpCorrenti();
          currentHpController.text = max(0, before - 12).toString();
          applyCondition(
            'stordito',
            duration: 1,
            source: 'Pergamena della Prigione d Ossa',
          );
          risultato =
              'Pergamena della Prigione d Ossa: 12 danni perforanti e Stordito per 1 turno.';
          break;
      }
      if (item.quantita > 1) {
        item.quantita--;
      } else {
        inventario.remove(item);
      }
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }
}
