part of '../../main.dart';

const oculumLusierSelfMasteryKey = 'lusier_self_mastery';

Map<String, dynamic>? oculumLusierPreparedData(dynamic raw) {
  try {
    final data = jsonDecode('$raw');
    if (data is Map && data['lusierPrepared'] == true) {
      return Map<String, dynamic>.from(data);
    }
  } on FormatException {
    return null;
  }
  return null;
}

int oculumLusierBeamDamage(int damage, int die, {int flat = 45}) =>
    ((max(0, damage) + die + flat) * (die > 90 ? 1.25 : 1)).floor();

int oculumSolarVitaliumRecovery(int current, int maximum) =>
    (max(0, maximum - current) + 1) ~/ 2;

int oculumSolarVitaliumHp(int current, int maximum) {
  if (current >= maximum) return current;
  final healing = (max(0, current) * 65 + max(0, maximum) * 10 + 99) ~/ 100;
  return min(maximum, current + healing);
}

bool oculumLusierDisdainsTarget({
  required int sourceHp,
  required int sourceMaximumHp,
  required int targetHp,
  required int targetMaximumHp,
}) =>
    sourceMaximumHp > 0 &&
    targetMaximumHp > 0 &&
    sourceHp * 2 > sourceMaximumHp &&
    targetHp * 2 <= targetMaximumHp;

OculumTitle oculumLusierSelfMasteryTitle() => OculumTitle(
  nome: 'Io, Padrone del Io',
  tipo: 'Titolo del Fato',
  chiaveSistema: oculumLusierSelfMasteryKey,
  equipaggiato: true,
  evoluto: true,
  ottenimento: 'Il dominio di Lusier III sulla propria identità.',
  buff:
      '@Difesa+livello\n15% di evitare maledizioni e condizioni negative altrimenti riuscite.',
  puntoCieco:
      'Mania di grandezza. Contro chi è a metà Vita o meno, mentre lui è sopra metà Vita, −5 al tiro per colpire: non vuole sprecare altro tempo.',
  skill:
      'Attacca con una delle armi equipaggiate. Ai Danni attuali aggiunge il maggiore fra Riflessi e Precisione. Solo se colpisce, recupera 5 + metà per difetto di quel sottotratto come Scudo Oculum.',
  richiede: 'Già sbloccato per Lusier III.',
  skillCombatRole: 'attacco',
  skillCost: OculumSkillCost(resource: 'nessuna', amountExpression: '0'),
  skillEffects: [
    OculumStructuredEffect(
      type: 'planar',
      target: 'lusier_condition_guard',
      valueExpression: '15',
    ),
    OculumStructuredEffect(
      type: 'planar',
      target: 'lusier_regal_strike',
      valueExpression: 'danni+agilita_arma',
      resource: '5+floor(agilita_arma/2)',
      recipient: 'nemico',
      mode: 'prossima_azione',
    ),
  ],
  openName: 'Dominio del Sole',
  openDescription:
      'Dalla mano aperta proietta un raggio solare spesso che insegue gli avversari. Può bersagliare tutti gli avversari del fight, +5 al tiro per colpire. Danni attuali +1d100+45 Solari. Con 91–100 sul d100, soltanto questo raggio infligge il 25% in più.',
  openBuff:
      '@Difesa+livello\nLa protezione da maledizioni e condizioni negative diventa 30%. Ottieni un Vitalium Solare una volta per fight. La Skill Open passa a 1d50+25 e fino a due bersagli.',
  openSkill:
      'Dal dito esce un raggio fine: Danni attuali +1d25+15 Solari. Col Buff: Danni attuali +1d50+25, fino a due bersagli. Su un solo bersaglio usa Precisione +10; se ne conosce il punto debole lo mira e, se riesce, aggiunge 15 Danni dopo il raggio. Non duplica il danno su un unico bersaglio.',
  openCombatRole: 'attacco',
  openEffects: [
    OculumStructuredEffect(
      type: 'planar',
      target: 'lusier_condition_guard',
      valueExpression: '30',
    ),
    OculumStructuredEffect(
      type: 'planar',
      target: 'lusier_solar_vitalium',
      valueExpression: '1',
    ),
    OculumStructuredEffect(
      type: 'planar',
      target: 'lusier_open_ray',
      valueExpression: 'danni+45',
      diceExpression: '1d100',
      resource: '25',
      recipient: 'nemico',
      mode: 'prossima_azione',
      elementType: 'solare',
      maximumTargets: 100,
    ),
  ],
  skillExtra: [
    TitleExtraSkillEntry(
      nome: 'Raggio sottile · Skill Open',
      descrizione:
          'Disponibile anche senza Open. Danni attuali +1d25+15; con Buff Open Danni attuali +1d50+25 Solari. Fino a due bersagli. Su uno: Precisione +10, mira il punto debole se conosciuto; +15 Danni se lo centra.',
      combatRole: 'attacco',
      cost: OculumSkillCost(resource: 'nessuna', amountExpression: '0'),
      effects: [
        OculumStructuredEffect(
          type: 'planar',
          target: 'lusier_thin_ray',
          valueExpression: 'danni+15',
          diceExpression: '1d25',
          recipient: 'nemico',
          mode: 'prossima_azione',
          elementType: 'solare',
        ),
      ],
    ),
  ],
);

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
    costo: '$cost Oculum',
    cooldown: '$cd turni',
    equipaggiata: true,
    descrizione: description,
    forme: [
      CharacterSkillForm(
        nome: name,
        tipo: 'Attiva',
        livello: '0',
        costo: '$cost Oculum',
        cooldown: '$cd turni personali',
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
    'currentHp':
        '${stats['resilienza']! * oculumHpMultiplierForGrade(1, level: 13)}',
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
    'titoli': [oculumLusierSelfMasteryTitle().toJson()],
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
    'planarRuntime': <String, dynamic>{
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

Map<String, dynamic> oculumBuildErikSheet() {
  final base = monsterBookEntryById('guardia_solare_elite')!;
  final growth = oculumGeneratedMonsterBudget(base.presetType, 8);
  final res = growth ~/ 4, mat = growth ~/ 4, ocu = growth ~/ 5;
  final stats = {
    'resilienza': base.stats['resilienza']! + res,
    'volonta': base.stats['volonta']! + growth - res - mat - ocu,
    'materia': base.stats['materia']! + mat,
    'oculum': base.stats['oculum']! + ocu,
  };
  final art = oculumMonsterBookArt(base)..sbloccata = true;
  final personal = CharacterSkill(
    nome: 'Custodia del Girone',
    tipo: 'Attiva · Difesa',
    costo: '3 Oculum',
    cooldown: '3 turni',
    equipaggiata: true,
    descrizione:
        'Erik concentra il sigillo solare davanti al corpo: riceve Scudo e rafforza la Difesa Solare per il prossimo tiro difensivo. Valori iniziali di bilanciamento modificabili; usa un’Azione o una Reazione, mai un turno aggiuntivo per la Reazione.',
    forme: [
      for (final (level, cost, shield, defense) in [
        (8, 3, 12, 8),
        (12, 4, 20, 11),
        (18, 6, 30, 15),
      ])
        CharacterSkillForm(
          nome: 'Custodia del Girone · $level',
          tipo: 'Attiva · Difesa',
          livello: '$level',
          costo: '$cost Oculum',
          cooldown: '3 turni personali',
          costoStrutturato: OculumSkillCost(
            resource: 'oculum',
            amountExpression: '$cost',
            minimum: cost,
            maximum: cost,
          ),
          cooldownStrutturato: OculumAbilityCooldown(amount: 3, unit: 'turni'),
          effettiStrutturati: [
            OculumStructuredEffect(
              type: 'scudo',
              valueExpression: '$shield',
              recipient: 'se_stesso',
              mode: 'immediato',
            ),
            OculumStructuredEffect(
              type: 'difesa',
              valueExpression: '$defense',
              elementType: 'solare',
              recipient: 'se_stesso',
              mode: 'prossima_azione',
            ),
          ],
        ),
    ],
  );
  return {
    'nome': 'Erik I',
    'tipoScheda': base.presetType,
    'razza': 'Solare',
    'monsterBookSourceId': base.id,
    'livello': '8',
    'grado': '0',
    'exp': '0',
    for (final e in stats.entries) e.key: '${e.value}',
    for (final e in stats.entries)
      'current${e.key[0].toUpperCase()}${e.key.substring(1)}': '${e.value}',
    'maxOculum': stats['oculum'],
    'normalCurrentOculum': stats['oculum'],
    'currentHp':
        '${stats['resilienza']! * oculumHpMultiplierForGrade(0, level: 8)}',
    'scudo': '35',
    'scudoCritico': '0',
    'scudoOculum': '40',
    'scudoOculumMax': '40',
    'hpTemp': '0',
    'arti': [art.toJson()],
    'skills': [personal.toJson()],
    'titoli': <dynamic>[],
    'trattiRazziali': <dynamic>[],
    'inventario': [
      InventoryItem(
        nome: 'Abito e placche auree di Erik I',
        peso: 3.2,
        quantita: 1,
        equipaggiata: true,
        protegge: true,
        livelloOggetto: 8,
        buff: '@Difesa+8 Solare',
        note:
            'Sete avorio e bordò e placche d’oro opaco; meno possente delle protezioni di Lusier. I fratelli sono un’eccezione al casco integrale delle guardie generiche.',
      ).toJson(),
      InventoryItem(
        nome: 'Lama del presidio di Erik I',
        peso: 1.2,
        quantita: 1,
        equipaggiata: true,
        arma: true,
        livelloOggetto: 8,
        bonusDanno: 7,
        elementoDanno: 'Solare',
        note:
            'Lama disciplinata, guardia e dettagli d’oro, sigilli solari sobri.',
      ).toJson(),
      InventoryItem(
        nome: 'Scudo del girone intermedio',
        peso: 2,
        quantita: 1,
        equipaggiata: true,
        protegge: true,
        livelloOggetto: 8,
        bonusScudo: 35,
        scudoIntegritaCorrente: 35,
        note:
            'Scudo con occhio solare inciso; la riserva iniziale di35 è già nella scheda, non aggiungerla di nuovo.',
      ).toJson(),
    ],
    'hiddenEyeStats': [
      for (final e in {
        'manifestazione_potere': 4,
        'precisione': 3,
        'riflessi': 3,
        'resistenza': 3,
        'percezione': 2,
      }.entries)
        {'id': e.key, 'nome': e.key, 'valore': e.value, 'unlocked': true},
    ],
    'planarRuntime': <String, dynamic>{
      'identityCelestial': 'solare',
      'canonicalNpc': 'erik_i',
    },
    'tutorialCompletato': true,
    'background':
        'Erik I, fratello di Lusier III, Soldato Solare Elité livello8 e Grado0, molto più debole del fratello. Più misurato, ma fedele a Lusier. Da lui ha ricevuto parte del dominio: i circoli solari inferiori, intermedi se si contano quelli contaminati ancora più in basso. Lusier sta sopra, Erik governa la fascia intermedia, sotto si trovano i circoli lunari contaminati dall’Oculum esausto scaricato dai piani alti per purificare l’aria di Lost Town. Il suo riferimento del volto è l’artwork indicato dall’utente, distinto dalle nuove guardie generiche con elmo completo.',
    'notePersonaggio':
        'Base Elité56 + crescita livello8 $growth punti, assegnati una sola volta. Equipaggiamento e tecniche del catalogo conservabili e modificabili; Custodia del Girone è un bilanciamento personale delegato, distinto dai poteri di Lusier. Nessuna carta personale, Titolo di Lusier o sua riserva di150 Scudo Oculum viene copiata.',
  };
}

extension _OculumLusierRuntime on _OculumHomePageState {
  OculumTitle? get lusierSelfMastery => titoli
      .where(
        (t) => t.equipaggiato && t.chiaveSistema == oculumLusierSelfMasteryKey,
      )
      .firstOrNull;

  bool get lusierOpenActive => lusierSelfMastery?.openAttiva == true;
  bool get lusierOpenSkillEmpowered =>
      lusierSelfMastery != null &&
      titleOwnOpenSkillEmpowered(lusierSelfMastery!);

  int get lusierConditionGuard {
    final title = lusierSelfMastery;
    if (title == null) return 0;
    final effects = title.openAttiva ? title.openEffects : title.skillEffects;
    return readIntValue(
      effects
          .where((e) => e.target == 'lusier_condition_guard')
          .firstOrNull
          ?.valueExpression,
    ).clamp(0, 100);
  }

  bool lusierPreventsNegativeCondition(
    String type,
    String source, {
    int? percentile,
  }) {
    if (source.isEmpty ||
        lusierConditionGuard <= 0 ||
        oculumConditionDefinition(type)?.polarity !=
            OculumConditionPolarity.negative) {
      return false;
    }
    final roll = percentile ?? Random.secure().nextInt(100) + 1;
    if (roll > lusierConditionGuard) return false;
    aggiungiLog(
      'Io, Padrone del Io: $type resistito ($roll ≤ $lusierConditionGuard%).',
    );
    return true;
  }

  bool get lusierThinRayPending => activeStructuredEffects.any(
    (e) =>
        e['type'] == 'pending_target' &&
        e['effect'] is Map &&
        (e['effect'] as Map)['target'] == 'lusier_thin_ray',
  );

  List<OculumStructuredEffect>? prepareLusierTitleEffects(
    List<OculumStructuredEffect> effects, {
    Random? random,
  }) {
    final targets = {
      'lusier_regal_strike',
      'lusier_open_ray',
      'lusier_thin_ray',
    };
    if (!effects.any((e) => targets.contains(e.target))) return effects;
    if (lusierSelfMastery == null) return null;
    if (effects.any((e) => e.target == 'lusier_regal_strike') &&
        armiEquipaggiate().isEmpty) {
      aggiungiLog('Il colpo leggero richiede un’arma equipaggiata.');
      return null;
    }
    final variables = <String, num>{
      ...formulaValueContext(),
      'danni': dannoTotale(),
    };
    variables['agilita_arma'] = max(
      variables['riflessi'] ?? 0,
      variables['precisione'] ?? 0,
    );
    return [
      for (final original in effects)
        if (original.target != 'lusier_condition_guard')
          (() {
            if (!targets.contains(original.target)) return original;
            final effect = OculumStructuredEffect.fromJson(original.toJson());
            if (effect.target == 'lusier_thin_ray' &&
                lusierOpenSkillEmpowered) {
              // The upgraded definition remains editable in the title's extra skill.
              effect.valueExpression = effect.valueExpression.replaceAll(
                '+15',
                '+25',
              );
              effect.diceExpression = effect.diceExpression == '1d25'
                  ? '1d50'
                  : effect.diceExpression;
              effect.maximumTargets = 2;
            }
            if (effect.target == 'lusier_open_ray') {
              effect.maximumTargets = max(1, onlineAttackTokens().length);
            }
            final roll = oculumResolveStructuredEffectRoll(
              effect,
              variables: variables,
              subtraits: hiddenEyeStats,
              random: random,
            );
            final recovery = effect.target == 'lusier_regal_strike'
                ? oculumEvaluateFormula(effect.resource, variables).floor()
                : 0;
            final die = roll.dice.rolls.fold<int>(0, (a, b) => a + b);
            effect.narrativeText = jsonEncode({
              'lusierPrepared': true,
              'shieldRecovery': recovery,
              'dice': die,
              'surgePercent': readIntValue(effect.resource),
              'buff': lusierOpenSkillEmpowered,
            });
            effect.valueExpression = '${roll.value}';
            effect.diceExpression = '';
            effect.includeLevel = effect.includeGrade = false;
            return effect;
          })(),
    ];
  }

  void claimLusierTitleAttack(Map<String, dynamic> request, int targetCount) {
    final effect = (request['effects'] as List? ?? [])
        .whereType<Map>()
        .where(
          (e) => const {
            'lusier_regal_strike',
            'lusier_open_ray',
            'lusier_thin_ray',
          }.contains(e['target']),
        )
        .firstOrNull;
    if (effect != null && request['lusierTitlePrepared'] != true) {
      final data = oculumLusierPreparedData(effect['narrativeText']);
      if (data == null) return;
      var damage = max(0, readIntValue(effect['valueExpression']));
      if (effect['target'] == 'lusier_open_ray') {
        request['attack'] = readIntValue(request['attack']) + 5;
        if (readIntValue(data['dice']) > 90) {
          damage = (damage * (100 + readIntValue(data['surgePercent'])) / 100)
              .floor();
        }
      }
      if (effect['target'] == 'lusier_thin_ray' &&
          data['buff'] == true &&
          targetCount == 1) {
        request['attack'] = readIntValue(request['attack']) + 10;
        request['lusierThinPrecision'] = true;
      }
      request['damage'] = damage;
      request['baseAttack'] = false;
      request['lusierTitlePrepared'] = true;
    }
    if (lusierSelfMastery != null) {
      request['lusierDisdainSourceHp'] = hpCorrenti();
      request['lusierDisdainSourceMaxHp'] = maxHp();
    }
  }

  void applyLusierDisdain(Map request) {
    if (request['lusierDisdainChecked'] == true) return;
    request['lusierDisdainChecked'] = true;
    if (oculumLusierDisdainsTarget(
      sourceHp: readIntValue(request['lusierDisdainSourceHp']),
      sourceMaximumHp: readIntValue(request['lusierDisdainSourceMaxHp']),
      targetHp: hpCorrenti(),
      targetMaximumHp: maxHp(),
    )) {
      request['attack'] = readIntValue(request['attack']) - 5;
      request['lusierDisdainPenalty'] = 5;
      aggiungiLog(
        'Mania di grandezza: Lusier −5 al tiro contro il bersaglio molto ferito.',
      );
    }
  }

  void confirmLusierRegalStrike(Map request) {
    if ('${request['sourceTag']}' != sheetTagAt(schedaCorrente) ||
        request['outcome'] == OculumAttackOutcome.avoided.name) {
      return;
    }
    final effect = (request['effects'] as List? ?? [])
        .whereType<Map>()
        .where((e) => e['target'] == 'lusier_regal_strike')
        .firstOrNull;
    if (effect == null || !faunaReceipt('lusier-strike:${request['id']}')) {
      return;
    }
    final data = oculumLusierPreparedData(effect['narrativeText']);
    if (data == null) return;
    final recovery = max(0, readIntValue(data['shieldRecovery']));
    scudoOculumController.text =
        '${leggiNumero(scudoOculumController) + recovery}';
    aggiungiLog(
      'Colpo leggero: +$recovery Scudo Oculum, anche oltre il massimo.',
    );
    programmaSalvataggio();
  }

  void grantLusierSolarVitalium() {
    final key = senkaFightKey;
    if (planarState['lusierVitaliumFight'] == key) return;
    planarState['lusierVitaliumFight'] = key;
    inventario.add(
      InventoryItem(
        nome: 'Vitalium Solare',
        peso: .2,
        quantita: 1,
        note:
            'Cura il 65% della Vita attuale + il 10% della Vita massima, arrotondato per eccesso, fino alla Vita massima. Recupera metà per eccesso delle risorse e dell’integrità Art mancanti; non riduce valori già oltre il massimo. All’uso +1 Scudo critico.',
        craftData: {'lusierSolarVitalium': true},
      ),
    );
  }

  void useLusierSolarVitalium() {
    // Restoring RES recalculates HP: preserve the pre-use reserve, including overflow.
    final originalHp = max(0, leggiNumero(currentHpController));
    for (final key in ['resilienza', 'volonta', 'materia', 'oculum']) {
      final current = currentStatValue(key), maximum = statMassimoNaturale(key);
      setCurrentStatFromVisibleInput(
        key,
        '${current + oculumSolarVitaliumRecovery(current, maximum)}',
        trackConsumption: false,
      );
    }
    currentHpController.text = '${oculumSolarVitaliumHp(originalHp, maxHp())}';
    for (final art in arti) {
      art.integritaCorrente += oculumSolarVitaliumRecovery(
        art.integritaCorrente,
        artIntegrityEffectiveMaximum(art),
      );
    }
    scudoCriticoController.text = '${scudoCritico() + 1}';
  }

  bool isLusierDerision(Map request) => (request['effects'] as List? ?? [])
      .whereType<Map>()
      .any((e) => e['type'] == 'planar' && e['target'] == 'lusier_derision');

  void resolveLusierDerision(
    Map request,
    int attack,
    int defense,
    int natural,
  ) {
    if (!isLusierDerision(request) ||
        request['lusierDerisionResolved'] == true) {
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
