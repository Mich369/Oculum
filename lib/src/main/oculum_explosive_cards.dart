part of '../../main.dart';

({int capacity, int recharge, int level}) oculumExplosiveCardsForm(int form) =>
    switch (form) {
      2 => (capacity: 10, recharge: 2, level: 12),
      >= 3 => (capacity: 15, recharge: 3, level: 20),
      _ => (capacity: 5, recharge: 1, level: 10),
    };

InventoryItem oculumExplosiveCards({bool lusier = false}) {
  final appearance = lusier
      ? 'Carte dorate del mazzo personale di Lusier III, con bordi incisi e sigilli da impatto. Eccezione personale: il mazzo generico dello shop resta non d’oro.'
      : 'Carte flessibili di fibra scura, bordi incisi e sigilli da impatto; non sono d’oro.';
  final description =
      '$appearance Grado I. Ogni carta esplode al contatto per 1d25 + floor(Danni attuali del portatore/5), senza aggiungere di nuovo il Danno base. Massimo 5 carte per attacco. I livello 10: 5 carte, recupero 1/turno. II livello 12: 10 carte, recupero 2/turno. III livello 20: 15 carte, recupero 3/turno. Recupero automatico delle carte consumate al proprio turno, entro la capienza; nessuna ricarica togliendo e rimettendo il mazzo. Ogni lancio paga la normale Azione o Reazione di attacco.';
  return InventoryItem(
    nome: 'Mazzo di carte esplosive',
    peso: .3,
    quantita: 1,
    note: description,
    arma: true,
    gradoOggetto: 1,
    gradoRichiesto: 1,
    livelloOggetto: lusier ? 13 : 10,
    elementoDanno: 'Esplosione',
    equipaggiata: lusier,
    craftData: {
      'explosiveCards': true,
      'cardsRemaining': lusier ? 10 : 5,
      'marketValue': lusier ? 215 : 180,
      'marketValueMinimum': 180,
      'marketValueMaximum': 250,
      if (lusier) 'cardsRechargeOverride': 3,
      if (lusier) 'personalGoldenDeck': true,
    },
    ability: CharacterSkill(
      nome: 'Lancio delle carte esplosive',
      tipo: 'Attacco',
      costo: 'Nessun costo',
      cooldown: '0',
      descrizione: description,
      equipaggiata: true,
      forme: [
        for (var form = 1; form <= 3; form++)
          CharacterSkillForm(
            nome: ['I', 'II', 'III'][form - 1],
            tipo: 'Attacco',
            livello: '${oculumExplosiveCardsForm(form).level}',
            descrizione: description,
            costoStrutturato: OculumSkillCost(
              resource: 'nessuna',
              amountExpression: '0',
            ),
            cooldownStrutturato: OculumAbilityCooldown(amount: 0),
            effettiStrutturati: [
              OculumStructuredEffect(
                id: 'explosive_cards_$form',
                type: 'planar',
                target: 'explosive_cards_damage',
                resource: '$form',
                valueExpression: '0',
                recipient: 'bersaglio',
                mode: 'prossima_azione',
                elementType: 'esplosione',
              ),
            ],
          ),
      ],
    ),
  );
}

extension _OculumExplosiveCardsRuntime on _OculumHomePageState {
  InventoryItem? get explosiveCardDeck => inventario
      .where(
        (i) =>
            i.quantita > 0 &&
            i.equipaggiata &&
            i.craftData['explosiveCards'] == true,
      )
      .firstOrNull;
  int get explosiveCardForm => leggiNumero(livelloController) >= 20
      ? 3
      : leggiNumero(livelloController) >= 12
      ? 2
      : 1;
  void rechargeExplosiveCards() {
    final deck = explosiveCardDeck;
    if (deck == null) return;
    final form = oculumExplosiveCardsForm(explosiveCardForm);
    final key =
        '$onlineCombatEncounterId:$selectedMasterInitiativeGroupId:$playerReportedTurn';
    if (deck.craftData['cardsLastRechargeTurn'] == key) return;
    deck.craftData['cardsLastRechargeTurn'] = key;
    deck.craftData['cardsRemaining'] = min(
      form.capacity,
      max(0, readIntValue(deck.craftData['cardsRemaining'])) +
          readIntValue(
            deck.craftData['cardsRechargeOverride'],
            fallback: form.recharge,
          ),
    );
  }

  Future<List<OculumStructuredEffect>?> prepareExplosiveCards(
    List<OculumStructuredEffect> effects,
  ) async {
    final deck = explosiveCardDeck;
    final card = effects
        .where((e) => e.target == 'explosive_cards_damage')
        .firstOrNull;
    if (card == null) return effects;
    if (deck == null ||
        leggiNumero(gradoController) < 1 ||
        leggiNumero(livelloController) <
            oculumExplosiveCardsForm(readIntValue(card.resource)).level) {
      return null;
    }
    if (activeStructuredEffects.any(
      (e) =>
          e['type'] == 'pending_target' &&
          e['target'] == 'explosive_cards_damage',
    )) {
      aggiungiLog('Lancia prima le carte già preparate.');
      return null;
    }
    final maximum = min(
      5,
      max(0, readIntValue(deck.craftData['cardsRemaining'])),
    );
    if (maximum == 0) {
      aggiungiLog(
        'Mazzo esaurito: attende il recupero al prossimo turno personale.',
      );
      return null;
    }
    final origin = currentSheetScrollId();
    final count = await showDialog<int>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text(
          'Carte da lanciare · ${deck.craftData['cardsRemaining']} disponibili',
        ),
        children: [
          for (var n = 1; n <= maximum; n++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, n),
              child: Text('$n ${n == 1 ? 'carta' : 'carte'}'),
            ),
        ],
      ),
    );
    if (count == null || !mounted || currentSheetScrollId() != origin) {
      return null;
    }
    return [
      for (final e in effects)
        if (identical(e, card))
          OculumStructuredEffect.fromJson(e.toJson())
            ..valueExpression = '$count*${dannoTotale() ~/ 5}'
            ..diceExpression = '${count}d25'
            ..narrativeText = 'Carte:$count'
        else
          e,
    ];
  }

  bool claimExplosiveCards(Map request) {
    final raw = (request['effects'] as List? ?? [])
        .whereType<Map>()
        .where((e) => e['target'] == 'explosive_cards_damage')
        .firstOrNull;
    if (raw == null) return true;
    final deck = explosiveCardDeck;
    final count = int.tryParse('${raw['narrativeText']}'.split(':').last) ?? 0;
    final id = '${request['attackGroupId'] ?? request['id'] ?? ''}';
    if (deck == null || id.isEmpty) return false;
    final claims = (deck.craftData['cardsClaims'] as List? ?? [])
        .map((s) => '$s')
        .toList();
    if (claims.contains(id)) {
      request['damage'] = max(0, readIntValue(raw['valueExpression']));
      request['baseAttack'] = false;
      return true;
    }
    if (count < 1 ||
        count > 5 ||
        readIntValue(deck.craftData['cardsRemaining']) < count) {
      return false;
    }
    deck.craftData['cardsRemaining'] =
        readIntValue(deck.craftData['cardsRemaining']) - count;
    claims.add(id);
    deck.craftData['cardsClaims'] = claims.length > 100
        ? claims.sublist(claims.length - 100)
        : claims;
    request['damage'] = max(0, readIntValue(raw['valueExpression']));
    request['baseAttack'] = false;
    request['abilityName'] = 'Carte esplosive · $count';
    return true;
  }
}
