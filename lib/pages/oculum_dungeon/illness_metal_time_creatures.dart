part of 'monster_book.dart';

final _tacticalCreatureEntries = <MonsterBookEntry>[
  _authoredPlanar(
    'il_doppione',
    'Il Doppione',
    ['mezzano', 'shadow_hell'],
    'mentale',
    'Figura alta e sottile, dal corpo segnato da pieghe, mani lunghe e testa aperta in una corona di lembi sopra una bocca dentata. Possiede Illness Art: guadagna 1 Follia a ogni proprio turno. Ogni tre turni propri emette un’onda mentale contro tutti gli avversari, ciascuno con una difesa coerente: chi fallisce riceve 1 Follia. Spende 1 o 2 Follia per creare rispettivamente una o due copie indistinguibili, con il suo tiro d’attacco ma un quarto dei Danni e del totale difensivo; un colpo riuscito distrugge una copia.',
    'La piega centrale della corona, aperta quando emette l’onda mentale.',
    [3, 6, 3, 1],
    3,
    false,
    false,
    ['doppione_illness_passive', 'doppione_copies'],
    {
      'authoredCanonical': true,
      'illnessArt': true,
      'dispositions': ['ostile'],
      'madnessPerTurn': 1,
      'madnessWaveEveryTurns': 3,
    },
    const {},
  ).copyWith(
    dropIds: ['lembo_del_doppione'],
    classificationTags: ['Illness Art', 'Aberrazione'],
  ),
  for (final solar in [false, true])
    _authoredPlanar(
      solar ? 'aberrazione_metallica_solare' : 'aberrazione_metallica_angelica',
      solar
          ? 'Aberrazione metallica · Solare'
          : 'Aberrazione metallica · Angelica',
      solar ? ['sacro'] : ['angelico', 'sacro'],
      solar ? 'solare' : 'luce',
      solar
          ? 'Aberrazione interamente d’oro, avvolta in un mantello di lamelle metalliche. Il mantello para senza tiro il 45% dei danni e usa anche la normale Resistenza passiva. Ogni proprio turno ha il 90% di ottenere una Reazione veloce extra.'
          : 'Aberrazione di metallo angelico bianco; giunti, fessure e ogni parte di altro colore sono d’oro. Il mantello di acciaio angelico para senza tiro il 90% dei danni e usa anche la normale Resistenza passiva. Ogni proprio turno ha il 90% di ottenere una Reazione veloce extra.',
      'I giunti d’oro del collo, visibili fra le lamelle del mantello.',
      solar ? [2, 6, 2, 3] : [4, 3, 5, 1],
      2,
      false,
      false,
      [
        solar ? 'solar_metal_mantle' : 'angelic_metal_mantle',
        'metallic_quick_passive',
      ],
      {
        'authoredCanonical': true,
        'dispositions': solar ? ['ostile', 'aggressivo'] : ['obbediente'],
        'mantleProtectionPercent': solar ? 45 : 90,
        'mantleCriticalWear': 5,
        'mantleDoubleCriticalWear': 20,
        'extraFastReactionChance': 90,
        'mantleRestoration': 'long_rest',
      },
      const {},
    ).copyWith(
      dropIds: [solar ? 'lamella_oro_solare' : 'lamella_acciaio_angelico'],
      classificationTags: [
        'Aberrazione metallica',
        solar ? 'Solare' : 'Angelica',
      ],
    ),
  _authoredPlanar(
    'ciclope_del_tempo',
    'Il Ciclope del Tempo',
    ['mezzano', 'angelico'],
    'fisico',
    'Un ciclope fragile e incurvato, con un solo occhio simile a un quadrante luminoso, vesti consunte e una falce pesante. Un’aureola chiara dietro la testa gli dà +3 Difesa finché resta sopra metà Vita; ritorna se recupera abbastanza Vita. Il suo potere del tempo è lieve e molto costoso: può ottenere Reazioni veloci o riportare sé stesso o un compagno alla Vita precedente all’ultimo attacco subito. Le statistiche, soprattutto la Vita, sono molto basse.',
    'L’unico occhio, il quadrante luminoso al centro del volto.',
    [1, 2, 1, 4],
    1,
    false,
    false,
    ['time_cyclops_halo', 'time_cyclops_quick', 'time_cyclops_rewind'],
    {
      'authoredCanonical': true,
      'dispositions': ['neutrale', 'ostile'],
      'haloDefenseBonus': 3,
      'haloReturnsAboveHalfHp': true,
    },
    const {},
  ).copyWith(
    dropIds: ['frammento_aureola_temporale'],
    classificationTags: ['Ciclope', 'Tempo'],
    canWieldWeapons: true,
    weaponTags: ['falce', 'pesante'],
    inventoryItems: [
      {
        'nome': 'Falce pesante del Tempo',
        'descrizione':
            'Falce pesante impugnata dal Ciclope del Tempo; valori iniziali modificabili.',
        'quantita': 1,
        'peso': 4.5,
        'arma': true,
        'bonusDanno': 8,
      },
    ],
  ),
];

final _tacticalCreatureTechniques = <String, MonsterConcreteTechnique>{
  'doppione_illness_passive': MonsterConcreteTechnique(
    name: 'Illness Art · Presenza del Doppione',
    action:
        'Passiva: +1 Follia a ogni proprio turno; ogni tre turni un’onda contrapposta mentale su tutti gli avversari dona 1 Follia a chi fallisce',
    element: 'mentale',
    kind: 'passiva',
    requiredLevel: 0,
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cooldownValues: [0, 0, 0],
    forms: [
      [MonsterTechniqueEffect('planar', '1', target: 'doppione_presence')],
      [MonsterTechniqueEffect('planar', '1', target: 'doppione_presence')],
      [MonsterTechniqueEffect('planar', '1', target: 'doppione_presence')],
    ],
  ),
  'doppione_copies': MonsterConcreteTechnique(
    name: 'Copie del Doppione',
    action:
        'Crea una copia per 1 Follia o due per 2 Follia. Mantengono il tiro d’attacco, Danni e totale difensivo sono un quarto; un colpo riuscito distrugge ciascuna copia',
    element: 'mentale',
    kind: 'evocazione',
    requiredLevel: 0,
    costResource: 'follia',
    minimums: [1, 2, 2],
    maximums: [1, 2, 2],
    cooldownValues: [0, 0, 0],
    forms: [
      [MonsterTechniqueEffect('planar', '1', target: 'doppione_copies')],
      [MonsterTechniqueEffect('planar', '2', target: 'doppione_copies')],
      [MonsterTechniqueEffect('planar', '2', target: 'doppione_copies')],
    ],
  ),
  for (final solar in [false, true])
    (solar
        ? 'solar_metal_mantle'
        : 'angelic_metal_mantle'): MonsterConcreteTechnique(
      name: solar ? 'Mantello d’oro solare' : 'Mantello di acciaio angelico',
      action:
          'Parata senza tiro: usa un’Azione o una Reazione disponibile. Il mantello perde 5 punti percentuali su critico e 20 su doppio critico già per quel colpo; si ripristina al Riposo Lungo. Il doppio critico si confronta con il valore di Resistenza',
      element: solar ? 'solare' : 'luce',
      kind: 'difesa',
      requiredLevel: 0,
      costResource: 'nessuna',
      minimums: [0, 0, 0],
      maximums: [0, 0, 0],
      cooldownValues: [0, 0, 0],
      forms: [
        [
          MonsterTechniqueEffect(
            'planar',
            solar ? '45' : '90',
            target: 'metallic_mantle',
          ),
        ],
        [
          MonsterTechniqueEffect(
            'planar',
            solar ? '45' : '90',
            target: 'metallic_mantle',
          ),
        ],
        [
          MonsterTechniqueEffect(
            'planar',
            solar ? '45' : '90',
            target: 'metallic_mantle',
          ),
        ],
      ],
    ),
  'metallic_quick_passive': MonsterConcreteTechnique(
    name: 'Scatto delle lamelle',
    action: 'Passiva: 90% di una Reazione veloce extra a ogni proprio turno',
    element: 'fisico',
    kind: 'passiva',
    requiredLevel: 0,
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cooldownValues: [0, 0, 0],
    forms: [
      [MonsterTechniqueEffect('planar', '90', target: 'metallic_quick')],
      [MonsterTechniqueEffect('planar', '90', target: 'metallic_quick')],
      [MonsterTechniqueEffect('planar', '90', target: 'metallic_quick')],
    ],
  ),
  'time_cyclops_halo': MonsterConcreteTechnique(
    name: 'Aureola del Tempo',
    action:
        'Passiva: +3 Difesa sopra metà Vita; si spegne a metà Vita o meno e ritorna quando la Vita torna sopra metà',
    element: 'tempo',
    kind: 'passiva',
    requiredLevel: 0,
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cooldownValues: [0, 0, 0],
    forms: [
      [MonsterTechniqueEffect('planar', '3', target: 'time_cyclops_halo')],
      [MonsterTechniqueEffect('planar', '3', target: 'time_cyclops_halo')],
      [MonsterTechniqueEffect('planar', '3', target: 'time_cyclops_halo')],
    ],
  ),
  'time_cyclops_quick': MonsterConcreteTechnique(
    name: 'Attimo in più',
    action:
        'Piega leggermente il tempo per ottenere Reazioni veloci per questo turno',
    element: 'tempo',
    kind: 'movimento',
    requiredLevel: 0,
    costResource: 'oculum',
    minimums: [4, 6, 8],
    maximums: [4, 6, 8],
    cooldownValues: [6, 5, 4],
    forms: [
      [MonsterTechniqueEffect('planar', '1', target: 'time_cyclops_quick')],
      [MonsterTechniqueEffect('planar', '2', target: 'time_cyclops_quick')],
      [MonsterTechniqueEffect('planar', '3', target: 'time_cyclops_quick')],
    ],
  ),
  'time_cyclops_rewind': MonsterConcreteTechnique(
    name: 'Un attacco indietro',
    action:
        'Riporta la Vita propria o di un compagno al valore precedente al suo ultimo attacco subito, entro il massimale attuale. Non riavvolge il resto dello scontro',
    element: 'tempo',
    kind: 'cura',
    requiredLevel: 0,
    costResource: 'oculum',
    minimums: [4, 6, 8],
    maximums: [4, 6, 8],
    cooldownValues: [6, 5, 4],
    forms: [
      [
        MonsterTechniqueEffect(
          'planar',
          '1',
          target: 'time_cyclops_rewind',
          recipient: 'alleato',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'planar',
          '1',
          target: 'time_cyclops_rewind',
          recipient: 'alleato',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'planar',
          '1',
          target: 'time_cyclops_rewind',
          recipient: 'alleato',
        ),
      ],
    ],
  ),
};
