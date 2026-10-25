part of 'monster_book.dart';

final _stormAndBanditEntries = <MonsterBookEntry>[
  _canonicalCreature(
    'thunderbird',
    'ThunderBird',
    '',
    ['isole', 'nuvole_rocciose', 'foresta_elementale'],
    'fulmine',
    [7, 6, 8, 5],
    4,
    'Un grande rapace dal piumaggio nero carbone e argentato, con tre coppie di ali sovrapposte. Le remiganti più lunghe si aprono come lame morbide e raccolgono archi elettrici lungo le nervature. Due zampe robuste serrano la roccia; il becco affilato e gli occhi ambrati restano scoperti sopra il collare di piume. Vive sulle creste battute dai temporali e sulle isole volanti, ripartendo da posatoi anneriti dal fulmine. È un avversario difficile per mobilità e rapidità, non per una Vita smisurata.',
    'La testa esposta sopra il collare di piume.',
    [
      'thunderbird_wing',
      'thunderbird_flight',
      'thunderbird_teleport',
      'thunderbird_claw',
    ],
    'piuma_conduttrice_thunderbird',
    resistances: {'fulmine': 'resistenza'},
  ).copyWith(
    encounterRules: {
      'authoredCanonical': true,
      'difficulty': 'difficile',
      'huntReward': {'kills': 3, 'skillId': 'thunderbird_teleport'},
      'naturalScrollDrops': {
        'thunderbird_claw': {
          'minimum': 15,
          'maximum': 19,
          'finishingElement': 'fulmine',
        },
      },
    },
  ),
  _canonicalCreature(
    'scostubanditi',
    'Scostubanditi',
    '',
    ['mezzano', 'postea'],
    'fisico',
    [3, 3, 4, 4],
    1,
    'Piccoli banditi dalle grandi orecchie di coniglio, pelo grigio ruvido, muso color crema e occhi scuri molto espressivi. Portano una sciarpa azzurro polvere, corpetti di cuoio rattoppato e un fucile corto di legno e ottone consumato. Ti provocano con insulti sfrontati: sparano da lontano e usano il calcio del fucile da vicino. Preferiscono rubare e scappare; ogni loro colpo è non letale. Se ti sconfiggono ti risvegli con 1 Vita e il 75% degli Obser personali in meno, senza perdere oggetti o denaro della cassa comune. Disarmati infliggono metà dei loro Danni.',
    'Disarmarli: senza il loro fucile infliggono metà danno e non possono sparare.',
    [
      'scostu_shot',
      'scostu_breath',
      'scostu_punch',
      'scostu_recover',
      'scostu_rifle',
    ],
    'ottone_fucile_scostubanditi',
  ).copyWith(
    encounterRules: {
      'authoredCanonical': true,
      'difficulty': 'facile',
      'nonLethal': true,
      'huntReward': {'kills': 15, 'skillId': 'scostu_punch'},
      'naturalScrollDrops': {
        'scostu_recover': {
          'minimum': 15,
          'maximum': 18,
          'finishingSkillId': 'scostu_breath',
        },
      },
      'rifleDropTotal': 30,
    },
  ),
];

MonsterConcreteTechnique _newPassive(
  String name,
  String text,
  String target,
  List<int> values, {
  String element = 'fisico',
  int level = 0,
}) => _planarMove(
  name,
  text,
  element,
  'passiva',
  [
    for (final value in values)
      [
        MonsterTechniqueEffect(
          'planar',
          '$value',
          target: target,
          duration: '',
          mode: 'finche_attivo',
        ),
      ],
  ],
  costResource: 'nessuna',
  minimums: [0, 0, 0],
  maximums: [0, 0, 0],
  cd: [0, 0, 0],
  level: level,
);

final _stormAndBanditTechniques = <String, MonsterConcreteTechnique>{
  'thunderbird_wing': _canonicalAttack(
    'Battito del temporale',
    'Una remigante elettrificata colpisce un solo avversario con un attacco Fulmine.',
    'fulmine',
    [4, 7, 10],
  ),
  'thunderbird_flight': _planarMove(
    'Volo Elettrico',
    'Una scarica sostiene un breve balzo in volo per evitare un colpo o superare un ostacolo. +5 al tiro di Riflessi per una propria azione; non è volo permanente.',
    'fulmine',
    'difesa',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'modifica_sottotratto',
            '5',
            target: 'riflessi',
            duration: '1',
            mode: 'prossima_azione',
          ),
        ],
    ],
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cd: [2, 2, 2],
    level: 4,
  ),
  'thunderbird_teleport': _planarMove(
    'TP elettrico',
    'Scegli un nemico e confronta i tuoi Riflessi con i suoi. Se lo superi ti sposti alle sue spalle: +2 Iniziativa per il turno, +5 al prossimo tiro e una Fragilità prima del prossimo colpo contro quel bersaglio. Con naturale superiore a 10 e successo ottieni una Reazione veloce. Non infligge danni durante il teletrasporto.',
    'fulmine',
    'utility',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'planar',
            '1',
            target: 'thunderbird_teleport',
            mode: 'immediato',
          ),
        ],
    ],
    minimums: [2, 3, 4],
    maximums: [2, 3, 4],
    cd: [3, 3, 3],
    level: 4,
  ),
  'thunderbird_claw': _planarMove(
    'Artiglio di Fulmine',
    'Richiami in mano un artiglio elettrico: il prossimo attacco ottiene +6/10/14 Danni Fulmine. Un critico positivo applica Paralisi dal Fato per una azione e invia piccole scosse da 2/3/4 Danni ai soli compagni vicini del bersaglio, mai ai tuoi alleati.',
    'fulmine',
    'danno',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'danno',
            '${6 + f * 4}',
            mode: 'prossima_azione',
            duration: '',
          ),
          MonsterTechniqueEffect(
            'planar',
            '${f + 2}',
            target: 'thunderbird_claw',
            recipient: 'nemico',
            mode: 'immediato',
          ),
        ],
    ],
    minimums: [2, 3, 4],
    maximums: [2, 3, 4],
    cd: [2, 2, 2],
    level: 4,
  ),
  'scostu_shot': _planarMove(
    'Colpo di fucile',
    'Spara da lontano o colpisce con il calcio da vicino: +3/5/7 Danni al prossimo attacco. Gli Scostubanditi usano sempre colpi non letali. Con Disarmato non puoi sparare.',
    'fisico',
    'danno',
    _planarDamageForms([3, 5, 7]),
    costResource: 'materia',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cd: [1, 1, 1],
  ),
  'scostu_breath': _newPassive(
    'Dammi il tempo di respirare, cazzo!',
    'Passiva. Quando lo Scudo normale assorbe un colpo senza rompersi, infliggi 6/9/12 Danni e respingi i nemici entro 2 metri. Una volta per attacco; non scatta se lo Scudo arriva a zero o il colpo attraversa gli Scudi.',
    'scostu_breath',
    [6, 9, 12],
  ),
  'scostu_punch': _planarMove(
    'Prendi questo, stronzo!',
    'Prepari un pugno, poi scegli un attacco ravvicinato. Un’unica estrazione dà il 25% di renderlo critico positivo. +3/6/9 Danni al pugno; una sola Azione o Reazione complessiva.',
    'contundente',
    'danno',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'danno',
            '${3 + f * 3}',
            mode: 'prossima_azione',
            duration: '',
          ),
          const MonsterTechniqueEffect(
            'planar',
            '25',
            target: 'scostu_punch',
            mode: 'immediato',
          ),
        ],
    ],
    costResource: 'materia',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cd: [3, 3, 3],
  ),
  'scostu_recover': _newPassive(
    'Oh merda, escono dalle fottute pareti!',
    'Passiva, una volta per fight. Quando lo Scudo normale si rompe recuperi 50 + 3×Livello Scudo. Non annulla il danno già passato alla Vita.',
    'scostu_recover',
    [50, 50, 50],
  ),
  'scostu_rifle': _planarMove(
    'Fucile schivata',
    'Evoca in mano il fucile. Ogni critico positivo andato a segno con quest’arma dà una Schivata Oculum. I: dura per tanti colpi sparati quanto Oculum immesso. II: conta soltanto i colpi andati a segno. III: conta i colpi a segno e ogni critico aggiunge 3 colpi. Non si accumulano più fucili evocati.',
    'fisico',
    'danno',
    [
      for (var f = 1; f <= 3; f++)
        [
          MonsterTechniqueEffect(
            'planar',
            'oculum_spent',
            target: 'scostu_rifle_ammo',
            mode: 'immediato',
          ),
          MonsterTechniqueEffect(
            'planar',
            '$f',
            target: 'scostu_rifle_form',
            mode: 'immediato',
          ),
        ],
    ],
    minimums: [1, 5, 11],
    maximums: [4, 10, 20],
    cd: [3, 3, 3],
  ),
};
