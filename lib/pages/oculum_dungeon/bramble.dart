part of 'monster_book.dart';

final _brambleEntry =
    _canonicalCreature(
      'bramble',
      'Bramble',
      '',
      ['foresta_elementale', 'mezzano'],
      'natura',
      [7, 4, 5, 6],
      3,
      'Un custode vegetale di corteccia intrecciata, con un busto umanoide e due braccia dalle lunghe dita-radici. Sotto il busto si allargano quattro tentacoli di rovi: sono le sue appendici locomotorie, che si piegano e fanno presa sul terreno per spostarlo, senza zampe bestiali aggiuntive. Può anche restare appeso a testa in giù ai rami più alti. Il volto appuntito ricorda una maschera di legno; gli occhi verde pallido osservano fra le fenditure, mentre dita lunghe come radici cercano un appiglio. Numerosi tentacoli di rovi, grossi tralci spinosi, partono dalla schiena e dalle spalle, avvolgendosi ai tronchi in archi irregolari. Fra le costole di legno pulsa un cuore ambrato. Difende i vecchi passaggi del bosco e richiude con i rovi le tracce lasciate da chi li danneggia. Il Fuoco brucia il corpo e attraversa lo Scudo di rovi; l’Acqua può spegnere il cuore senza consumare i semi da cui nasce la sua pergamena rara.',
      'Il cuore visibile fra le costole di legno; vulnerabile al Fuoco.',
      ['bramble_lash', 'bramble_thorn_shield', 'bramble_arduous_challenge'],
      'fibra_rovo_bramble',
      resistances: {'fuoco': 'debolezza', 'natura': 'resistenza'},
    ).copyWith(
      classificationTags: ['Vegetale', 'Custode'],
      encounterRules: {
        'authoredCanonical': true,
        'precisionBodyParts': [
          {"id": "body", "label": "Corpo", "group": "body"},
          {"id": "head", "label": "Testa a maschera lignea", "group": "head"},
          {"id": "torso", "label": "Busto di corteccia", "group": "torso"},
          {
            "id": "heart",
            "label": "Cuore ambrato",
            "group": "heart",
            "weak": true,
          },
          {"id": "arms_1", "label": "Braccio destro", "group": "arms"},
          {"id": "arms_2", "label": "Braccio sinistro", "group": "arms"},
          {
            "id": "legs_1",
            "label": "Tentacolo locomotore di rovi 1",
            "group": "tendrils",
            "locomotor": true,
          },
          {
            "id": "legs_2",
            "label": "Tentacolo locomotore di rovi 2",
            "group": "tendrils",
            "locomotor": true,
          },
          {
            "id": "legs_3",
            "label": "Tentacolo locomotore di rovi 3",
            "group": "tendrils",
            "locomotor": true,
          },
          {
            "id": "legs_4",
            "label": "Tentacolo locomotore di rovi 4",
            "group": "tendrils",
            "locomotor": true,
          },
        ],
        'dispositions': ['neutrale', 'ostile'],
        'naturalScrollDrops': {
          'bramble_thorn_shield': {'minimum': 20, 'maximum': 20},
          'bramble_arduous_challenge': {
            'minimum': 10,
            'maximum': 19,
            'finishingElement': 'acqua',
          },
        },
      },
    );

final _brambleTechniques = <String, MonsterConcreteTechnique>{
  'bramble_lash': _canonicalAttack(
    'Frustata di rovi',
    'Un tralcio si tende e sferza a distanza ravvicinata. Un solo attacco Natura; le spine non ignorano Difesa o Scudi.',
    'natura',
    [4, 7, 10],
  ),
  'bramble_thorn_shield': _planarMove(
    'Scudo di rovi',
    'Intreccia una barriera viva che assorbe 12/18/24 danni dopo la Difesa per 3 turni personali o fino a esaurimento. Se assorbe un colpo ravvicinato, le spine infliggono 2/4/6 Danni Natura all’aggressore, con le sue normali protezioni. Fuoco, Lava e Plasma attraversano la barriera senza consumarla. Riattivarla sostituisce la barriera, senza sommarla. Non consuma ulteriori Azioni o Reazioni per ogni colpo bloccato.',
    'natura',
    'difesa',
    [
      for (var f = 1; f <= 3; f++)
        [
          MonsterTechniqueEffect(
            'planar',
            '${6 + f * 6}',
            target: 'bramble_thorn_shield',
            duration: '3',
            mode: 'immediato',
          ),
          MonsterTechniqueEffect(
            'planar',
            '${f * 2}',
            target: 'bramble_thorn_retaliation',
            duration: '3',
            mode: 'immediato',
          ),
        ],
    ],
    minimums: [2, 3, 4],
    maximums: [2, 3, 4],
    cd: [3, 3, 3],
    level: 3,
  ),
  'bramble_arduous_challenge': _planarMove(
    'Sfida Ardua',
    'Passiva, senza costo né Azione/Reazione. Ogni tuo critico positivo contro un elemento a cui il bersaglio è resistente concede +1 Oculum e +1 Resilienza temporanei, fino a fine scontro. Un critico positivo contro una sua Fragilità concede Ricordo Vitale per 6 turni personali. Conta la resistenza configurata prima che il critico ne cambi lo stadio; lo stesso critico non si assegna due volte. Le forme mantengono gli stessi premi.',
    'natura',
    'passiva',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'planar',
            '1',
            target: 'bramble_arduous_challenge',
            duration: '6',
            mode: 'finche_attivo',
          ),
        ],
    ],
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cd: [0, 0, 0],
    level: 3,
  ),
};
