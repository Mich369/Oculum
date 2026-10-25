part of 'monster_book.dart';

List<Map<String, dynamic>> _nonReturnUndeadAnatomy({required bool knight}) => [
  for (final part in [
    ('body', 'Corpo'),
    ('head', 'Testa'),
    ('torso', 'Torace'),
  ])
    {
      'id': part.$1,
      'label': part.$2,
      'group': part.$1,
      'weak': false,
      'penalty': 0,
    },
  for (final group in ['arms', 'legs'])
    for (var i = 0; i < 2; i++)
      {
        'id': '${group}_${i + 1}',
        'label': group == 'arms'
            ? 'Braccio ${i == 0 ? 'destro' : 'sinistro'}'
            : 'Gamba ${i == 0 ? 'destra' : 'sinistra'}',
        'group': group,
        'side': i == 0 ? 'right' : 'left',
        'sideIndex': 1,
        'weak': false,
        'penalty': 0,
      },
  {
    'id': knight ? 'chest_eye' : 'sac',
    'label': knight
        ? 'Occhio del vortice nel petto'
        : 'Sacca acida sotto la gola',
    'group': knight ? 'core' : 'sac',
    'weak': true,
    'penalty': 0,
  },
];

final _nonReturnUndeadEntries = <MonsterBookEntry>[
  _canonicalCreature(
    'zombie_acido',
    'Zombie dello Sbocco Acido',
    '',
    ['morti', 'sotterraneo'],
    'acido',
    [3, 2, 4, 2],
    1,
    'Un morto ambulante dalla pelle grigio verdastra, con la mandibola abbassata e una sacca gonfia sotto la gola. Il torace è fasciato da strisce di tela bruciate dall’acido; dalle dita cadono gocce opache che lasciano piccoli solchi nella pietra. Prima di rigurgitare arretra la testa e la sacca diventa giallo limone. Cammina lentamente, cerca corridoi stretti e costringe gli avversari a passare davanti allo sbocco. Non è un cadavere esplosivo: la sua minaccia è la corrosione persistente.',
    'La sacca acida sotto la mandibola, esposta mentre prepara lo sbocco.',
    ['zombie_acid_vomit', 'zombie_acid_grasp', 'zombie_rigid_body'],
    'sacca_acida_zombie',
    resistances: {'acido': 'Resistenza', 'fuoco': 'Fragilità Bassa'},
  ).copyWith(
    classificationTags: ['Non morto', 'Umanoide'],
    encounterRules: {
      'precisionBodyParts': _nonReturnUndeadAnatomy(knight: false),
      'authoredCanonical': true,
      'dispositions': ['ostile'],
      'naturalScrollDrops': {
        'zombie_acid_vomit': {'minimum': 20, 'maximum': 20},
      },
    },
  ),
  _canonicalCreature(
    'cavaliere_non_ritorno',
    'Cavaliere del Non Ritorno',
    '',
    ['morti', 'sotterraneo_maggiore'],
    'ombra',
    [8, 8, 9, 6],
    5,
    'Un cavaliere alto, chiuso in un’armatura nera opaca che non riflette la luce. Punte irregolari sporgono da spalle, gomiti e schinieri; l’elmo è una visiera stretta senza volto visibile. Al centro del petto le piastre si incurvano in un vortice profondo che termina in un solo occhio viola. Trascina uno spadone largo, dal filo consumato e dal pomo ad anello spezzato. Tre Scudi critici e due Schivate Oculum lo rendono difficile da abbattere: alterna fendenti pesanti e brevi sparizioni, poi si chiude dietro la guardia. Il vortice resta scoperto per un istante quando rialza lo spadone.',
    'L’occhio alla fine del vortice nel petto, esposto quando solleva lo spadone.',
    ['non_return_greatsword', 'non_return_guard', 'non_return_step'],
    'frammento_corazza_non_ritorno',
    resistances: {
      'taglio': 'Resistenza Leggera',
      'angelico': 'Fragilità Bassa',
    },
  ).copyWith(
    classificationTags: ['Non morto', 'Cavaliere'],
    canWieldWeapons: true,
    weaponTags: ['spadone'],
    armorTags: ['armatura pesante'],
    stats: {
      'level': 5,
      'resilienza': 8,
      'volonta': 8,
      'materia': 9,
      'oculum': 6,
      'criticalShield': 3,
      'oculumDodge': 2,
    },
    encounterRules: {
      'authoredCanonical': true,
      'dispositions': ['ostile'],
      'criticalShields': 3,
      'precisionBodyParts': _nonReturnUndeadAnatomy(knight: true),
      'oculumDodges': 2,
      'naturalScrollDrops': {
        'non_return_step': {'minimum': 20, 'maximum': 20},
      },
    },
  ),
];

final _nonReturnUndeadTechniques = <String, MonsterConcreteTechnique>{
  'zombie_acid_vomit': _planarMove(
    'Sbocco d’acido',
    'Rigurgita un getto corto: +4/7/10 Danni Acido al colpo e Corrosione acida 2/3/4 per 2 turni, dal turno successivo. La difesa si tira normalmente; lo Scudo critico non annulla la corrosione ordinaria, che non richiede un critico.',
    'acido',
    'danno',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'danno',
            '${4 + f * 3}',
            mode: 'prossima_azione',
            duration: '',
          ),
          MonsterTechniqueEffect(
            'stato',
            '${2 + f}',
            target: 'corrosione_acida',
            duration: '2',
            recipient: 'nemico',
          ),
        ],
    ],
    costResource: 'materia',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cd: [3, 3, 3],
  ),
  'zombie_acid_grasp': _canonicalAttack(
    'Presa corrosa',
    'Stringe il bersaglio con dita intrise d’acido: un singolo colpo ravvicinato, senza immobilizzazione automatica.',
    'acido',
    [3, 5, 8],
  ),
  'zombie_rigid_body': _canonicalProtection(
    'Corpo irrigidito',
    'Blocca il torso e oppone le fasce indurite: Difesa extra per un turno.',
    'difesa',
    [3, 5, 7],
  ),
  'non_return_greatsword': _canonicalAttack(
    'Fendente senza ritorno',
    'Rialza lo spadone dal basso e lo abbatte davanti a sé. Un bersaglio difende normalmente; nessuna parte del colpo ignora Scudi o Difesa.',
    'taglio',
    [9, 15, 22],
  ),
  'non_return_guard': _canonicalProtection(
    'Guardia delle punte nere',
    'Incrocia il piatto dello spadone davanti al vortice: Difesa extra per un turno, senza rigenerare Scudi critici.',
    'difesa',
    [5, 8, 11],
  ),
  'non_return_step': _planarMove(
    'Passo del vortice',
    'Il bordo dell’armatura si dissolve per un istante: +3/+5/+7 al prossimo tiro di Difesa. Non concede Schivate Oculum aggiuntive né una seconda risorsa di turno.',
    'ombra',
    'difesa',
    [
      for (final n in [3, 5, 7])
        [
          MonsterTechniqueEffect(
            'planar',
            '$n',
            target: 'next_defense_roll',
            mode: 'prossima_azione',
            duration: '',
          ),
        ],
    ],
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cd: [4, 4, 3],
  ),
};
