part of '../../main.dart';

/// The defender wins ties. Critical rewards replace each other, never stack.
({int will, bool advantage, int accuracy, int beyondDefense})
oculumLusierDerisionResult({
  required int attack,
  required int defense,
  required int attackNatural,
  required int defenseNatural,
}) {
  final doubleCritical = oculumIsDoubleCritical(
    natural: defenseNatural,
    total: defense,
    opposingTotal: attack,
  );
  final critical = attackNatural == 1 || defenseNatural == 20;
  final margin = defense - attack;
  return (
    will: margin < 0
        ? -5
        : margin <= 5
        ? -3
        : 3,
    advantage: margin > 5,
    accuracy: doubleCritical
        ? 9
        : critical
        ? 5
        : 0,
    beyondDefense: doubleCritical ? 10 : 0,
  );
}

Map<String, dynamic> oculumBuildLusierSheet() {
  final base = monsterBookEntryById('guardia_solare_elite')!;
  final growth = oculumGeneratedMonsterBudget(base.presetType, 13);
  // Each growth point is assigned once; Will first, Oculum second.
  final res = growth * 15 ~/ 100, mat = growth * 15 ~/ 100;
  final ocu = growth * 29 ~/ 100;
  final stats = <String, int>{
    'resilienza': base.stats['resilienza']! + res,
    'volonta': base.stats['volonta']! + growth - res - mat - ocu,
    'materia': base.stats['materia']! + mat,
    'oculum': base.stats['oculum']! + ocu,
  };
  CharacterSkill technique(
    String name,
    String description,
    int cost,
    int cd,
    List<OculumStructuredEffect> effects,
  ) => CharacterSkill(
    nome: name,
    tipo: 'Attiva',
    costo: '@ocu-$cost',
    cooldown: '$cd turni',
    equipaggiata: true,
    descrizione: description,
    forme: [
      CharacterSkillForm(
        nome: name,
        tipo: 'Attiva',
        livello: '0',
        descrizione: description,
        costoStrutturato: OculumSkillCost(
          resource: 'oculum',
          amountExpression: '$cost',
          minimum: cost,
          maximum: cost,
        ),
        cooldownStrutturato: OculumAbilityCooldown(amount: cd, unit: 'turni'),
        effettiStrutturati: effects,
      ),
    ],
  );
  final clothes = InventoryItem(
    nome: 'Abito del comando solare di Lusier III',
    peso: 2.4,
    quantita: 1,
    equipaggiata: true,
    protegge: true,
    note:
        'Seta avorio e bordò, ricamata con fili d’oro e occhi solari. Il colletto alto, la stola e le ampie falde avvolgono il corpo senza diventare una corazza. I sigilli rinforzano magicamente la stoffa. Valori di bilanciamento modificabili: +12 Difesa Solare; la riserva personale di 150 Scudo Oculum e lo Scudo critico sono impostati nella scheda, non duplicati dall’abito.',
    buff: '@Difesa+12 Solare',
    livelloOggetto: 13,
    craftData: {
      'lusierClothes': true,
      'materiali': ['seta', 'oro'],
    },
  );
  final attack = technique(
    'Raggio del comando solare',
    'Un solo bersaglio, tiro di Manifestazione del Potere contro una difesa coerente. Danni attuali +25 Solare. Costo 4 Oculum; CD 2 turni personali.',
    4,
    2,
    [
      OculumStructuredEffect(
        id: 'lusier_solar_attack',
        type: 'danno',
        valueExpression: '25',
        elementType: 'solare',
        recipient: 'bersaglio',
        mode: 'prossima_azione',
      ),
    ],
  );
  final defense = technique(
    'Velo del sigillo aureo',
    'Un’Azione o una Reazione difensiva: +15 Difesa Solare per il prossimo tiro difensivo. Una Reazione non fa avanzare il turno. Costo 3 Oculum; CD 2.',
    3,
    2,
    [
      OculumStructuredEffect(
        id: 'lusier_solar_defense',
        type: 'difesa',
        valueExpression: '15',
        elementType: 'solare',
        recipient: 'se_stesso',
        mode: 'prossima_azione',
      ),
    ],
  );
  const derisionText =
      'Confronto di Inganno contro Volontà o una difesa mentale coerente. Nessun danno diretto. Se il bersaglio perde: −5 Volontà. Pareggio o vittoria fino a 5 di margine: −3 Volontà. Vittoria di oltre 5: +3 Volontà e Vantaggio per colpire Lusier fino a fine fight. Critico negativo di Lusier o positivo della difesa: +5 al prossimo tiro per colpirlo. Doppio critico positivo della difesa: +9 al posto di +5 e +10 Danni oltre Difesa nel prossimo attacco contro Lusier, conservando gli Scudi. Costo 2 Oculum; CD 3.';
  final derision = technique('Derisione del comandante', derisionText, 2, 3, [
    OculumStructuredEffect(
      id: 'lusier_derision',
      type: 'planar',
      target: 'lusier_derision',
      valueExpression: '1',
      recipient: 'bersaglio',
      mode: 'prossima_azione',
      duration: '1',
      durationUnit: 'fight',
    ),
  ]);
  return {
    'nome': 'Lusier III',
    'tipoScheda': base.presetType,
    'razza': 'Solare',
    'monsterBookSourceId': base.id,
    'livello': '13',
    'grado': '1',
    'exp': '0',
    for (final e in stats.entries) e.key: '${e.value}',
    for (final e in stats.entries)
      'current${e.key[0].toUpperCase()}${e.key.substring(1)}': '${e.value}',
    'maxOculum': stats['oculum'],
    'normalCurrentOculum': stats['oculum'],
    'currentHp': '${stats['resilienza']! * oculumHpMultiplierForGrade(1)}',
    'hpTemp': '0',
    'scudo': '0',
    'scudoCritico': '1',
    'scudoOculum': '150',
    'scudoOculumMax': '150',
    'skills': [attack.toJson(), defense.toJson(), derision.toJson()],
    'inventario': [
      clothes.toJson(),
      oculumExplosiveCards(lusier: true).toJson(),
      InventoryItem(
        nome: 'Spada sacra di Lusier III',
        peso: 1.5,
        quantita: 1,
        arma: true,
        equipaggiata: true,
        gradoOggetto: 1,
        gradoRichiesto: 1,
        livelloOggetto: 13,
        bonusDanno: 20,
        elementoDanno: 'Solare',
        note:
            'Lama sacra con sigilli e guardia solari; +20 Danni Solari, non +20 al tiro per colpire. È la spada con cui Lusier decapitò il padre di Senka, colpevole soltanto di non essersi inchinato.',
      ).toJson(),
      InventoryItem(
        nome: 'Vitalium Ridefinito',
        peso: .2,
        quantita: 1,
        note:
            'Consumabile: ripristina Vita, statistiche attuali e integrità delle Art ai massimali.',
      ).toJson(),
    ],
    'arti': <dynamic>[],
    'titoli': <dynamic>[],
    'trattiRazziali': <dynamic>[],
    'hiddenEyeStats': [
      for (final entry in {
        'manifestazione_potere': 6,
        'inganno': 6,
        'resistenza': 4,
        'riflessi': 3,
        'percezione': 3,
      }.entries)
        {
          'id': entry.key,
          'nome': entry.key,
          'valore': entry.value,
          'unlocked': true,
        },
    ],
    'planarRuntime': {
      'identityCelestial': 'solare',
      'canonicalNpc': 'lusier_iii',
    },
    'tutorialCompletato': true,
    'background':
        'Guardia Solare Élite di livello 13 e Grado I. Dirige battaglie e stermina popoli. Decapitò il padre di Senka perché non si inchinò. Infastidito dall’arrivo della madre e convinto di non essere rispettato, le lanciò cinque carte: due le recisero le braccia, due le colpirono le gambe e l’ultima rimase incastrata nella gola, facendola morire soffocata dal sangue e dal dolore. Kamaria, sconvolta, teneva Sky fra le braccia. La folla tremante nascose la scena mentre Lusier si allontanava; Haniel prese la mano di Senka e portò via entrambe. Le custodì per un anno, poi pagò per tre anni una stanza doppia in taverna. Continua ancora oggi ad addestrare Senka attraverso missioni e allenamenti, avendo compreso il suo desiderio di vendetta. Lusier è bellissimo, con pelle calda leggermente più scura degli altri Solari, capelli castani mossi non troppo lunghi e occhi d’oro eccezionalmente intenso. Indossa sete protettive avorio e bordò, ricamate d’oro con occhi solari; la stola e le falde lo circondano.',
    'notePersonaggio':
        'Base della Guardia Solare Élite: 56 punti. Crescita livello/Grado: $growth punti, tutti assegnati, senza duplicare il budget. Prima Volontà, poi Oculum. Un solo Scudo critico e 150 Scudo Oculum. Abito e tre tecniche modificabili negli editor; sottotratti e costi sono bilanciamenti iniziali modificabili.',
  };
}

extension _OculumLusierRuntime on _OculumHomePageState {
  bool isLusierDerision(Map request) => (request['effects'] as List? ?? [])
      .whereType<Map>()
      .any((e) => e['type'] == 'planar' && e['target'] == 'lusier_derision');

  void resolveLusierDerision(
    Map request,
    int attack,
    int defense,
    int natural,
  ) {
    if (!isLusierDerision(request) || request['lusierDerisionResolved'] == true) {
      return;
    }
    request['lusierDerisionResolved'] = true;
    final result = oculumLusierDerisionResult(
      attack: attack,
      defense: defense,
      attackNatural: readIntValue(request['natural']),
      defenseNatural: natural,
    );
    final source = '${request['sourceTag']}';
    final id = '${request['id']}';
    activeStructuredEffects.add({
      'effectId': 'lusier_will:$id',
      'source': 'Derisione di ${request['sourceName']}',
      'type': 'modifica_statistica',
      'target': 'volonta',
      'value': result.will,
      'remaining': 1,
      'unit': 'fight',
      'mode': 'finche_attivo',
    });
    activeStructuredEffects.add({
      'effectId': 'lusier_reply:$id',
      'source': 'Risposta alla Derisione',
      'type': 'lusier_reply',
      'target': source,
      'value': 0,
      'advantage': result.advantage,
      'accuracy': result.accuracy,
      'beyondDefense': result.beyondDefense,
      'remaining': 1,
      'unit': 'fight',
      'mode': 'finche_attivo',
    });
    invalidateDerivedDataCaches();
    aggiungiLog(
      'Derisione: ${result.will} Volontà fino a fine fight; '
      '${result.advantage ? 'Vantaggio contro Lusier; ' : ''}+${result.accuracy} al prossimo attacco contro di lui.',
    );
  }

  ({int accuracy, int beyondDefense}) lusierReplyBonus(
    String target, {
    bool consume = false,
  }) {
    var accuracy = 0, beyond = 0, advantage = false;
    for (final effect in activeStructuredEffects.where(
      (e) => e['type'] == 'lusier_reply' && e['target'] == target,
    )) {
      advantage |= effect['advantage'] == true;
      accuracy = max(accuracy, readIntValue(effect['accuracy']));
      beyond = max(beyond, readIntValue(effect['beyondDefense']));
      if (consume) {
        effect['accuracy'] = 0;
        effect['beyondDefense'] = 0;
      }
    }
    // Vantaggio is the canonical +3; do not duplicate a selected stronger one.
    return (
      accuracy: accuracy + (advantage ? max(0, 3 - vantaggioTiroBonus()) : 0),
      beyondDefense: beyond,
    );
  }
}
