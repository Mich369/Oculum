part of 'monster_book.dart';

final _boneRuneEntries = <MonsterBookEntry>[
  _canonicalCreature(
    'adoratore_bestia',
    'Adoratore della Bestia',
    '',
    ['mezzano', 'foresta_elementale'],
    'bestiale',
    [4, 5, 3, 3],
    2,
    'Un umano caduto sotto il controllo della Bestia, un Eiva potentissimo. Porta una maschera rossa dai denti bianchi, un collare di pelo chiaro e grandi grani neri sul petto scoperto. Una veste arancione lascia libera una spalla; fasce metalliche proteggono avambracci e stinchi, mentre una cintura rossa trattiene le stoffe. Dietro i gesti umani affiora l’istinto del padrone: protegge la Bestia e uccide per suo conto. La sagoma della Bestia è una presenza di potere, non un secondo corpo dell’adoratore.',
    'Il sigillo di controllo sulla maschera.',
    ['cult_beast_strike', 'cult_beast_guard', 'cult_beast_roar'],
    'sigillo_adoratore_bestia',
  ),
  _canonicalCreature(
    'teschio_monaco',
    'Teschio Monaco',
    '',
    ['morti', 'sotterraneo'],
    'nonmorto',
    [4, 5, 5, 9],
    4,
    'Uno scheletro umano asciutto, dal cranio ingiallito e dalle orbite profonde. Combatte a mani nude in equilibrio su una gamba; pantaloni larghi blu notte e una fascia di cuoio consumata sono i soli abiti. Il Ki verde corre fra le articolazioni, avvolge dita e talloni e lascia brevi scie nei calci. Ha due Schivate Oculum.',
    'Le articolazioni mentre prolunga un calcio.',
    ['monk_palm', 'monk_dragon', 'monk_ki', 'monk_seal', 'monk_ki_hunt'],
    'falange_teschio_monaco',
  ).copyWith(
    stats: {
      'resilienza': 4,
      'volonta': 5,
      'materia': 5,
      'oculum': 9,
      'level': 4,
      'oculumDodge': 2,
    },
    encounterRules: {
      'authoredCanonical': true,
      'huntReward': {'kills': 6, 'skillId': 'monk_seal'},
      'kiFinisherReward': true,
      'finisherReward': {
        'condition': 'active_mortal_ki',
        'skillId': 'monk_ki_hunt',
      },
      'naturalScrollDrops': {
        'monk_ki': {'minimum': 20, 'maximum': 20},
      },
      'dragonDropTotal': 39,
    },
  ),
  _canonicalCreature(
    'teschio_quattro_lame',
    'Teschio Quattro Lame',
    '',
    ['morti', 'sotterraneo'],
    'taglio',
    [4, 3, 5, 4],
    3,
    'Uno scheletro dalle ossa pallide e macchiate, con quattro braccia articolate attorno alla gabbia toracica. Ogni mano impugna una lama ricurva consunta; anelli di ottone stringono gli avambracci. Il cranio ghignante segue il ritmo dei quattro fendenti, le gambe lunghe avanzano sul pavimento con passi secchi. Le quattro braccia sono il punto debole.',
    'Tutte e quattro le braccia: i colpi mirati critici possono spezzarle.',
    [
      'bone_sword_strike',
      'bone_four_slash',
      'bone_kill_regen',
      'bone_ground_spikes',
    ],
    'osso_lama',
  ).copyWith(
    encounterRules: {
      'authoredCanonical': true,
      'huntReward': {'kills': 3, 'skillId': 'bone_kill_regen'},
      'fourSlashDropTotal': 40,
      'brokenArmsSwordDrop': true,
    },
  ),
  _canonicalCreature(
    'teschio_mostruoso',
    'Teschio Mostruoso',
    '',
    ['morti', 'sotterraneo'],
    'contundente',
    [2, 1, 3, 0],
    1,
    'Uno scheletro a quattro braccia, privo di vestiti e di armi. La sommità del cranio forma una cresta ossea alta e piatta; la mascella spalancata mostra denti fitti e irregolari. La cassa toracica larga si stringe su un bacino sottile. Le mani lunghe e curve terminano in artigli d’osso, le gambe sono arcuate e i piedi ossuti hanno dita molto lunghe. Non possiede Oculum né Art Oculum: usa soltanto forza, ossa e cooldown.',
    'Le giunture delle quattro braccia.',
    ['bone_monster_claws', 'bone_monster_guard'],
    'falange_mostruosa',
  ),
  _canonicalCreature(
    'ogor',
    'Ogor',
    '',
    ['morti', 'sotterraneo_maggiore'],
    'oculum',
    [8, 6, 8, 8],
    5,
    'Un grande costrutto di ossa, formato da uno scheletro massiccio rivestito di crani e placche sovrapposte. Due lunghe corna chiare si incurvano sopra la testa; grandi teschi bestiali proteggono spalle e ginocchia. Mani enormi con dita ad artiglio sporgono dagli avambracci corazzati. Fra le costole del petto brilla un nucleo VIOLA di Oculum, mai azzurro: da quella apertura esce il raggio. La corazza dimezza i danni di ogni colpo che non sia Precisione mirata al nucleo già individuato. Tre colpi riusciti al nucleo lo rompono e bloccano il raggio.',
    'Nucleo viola nel petto; corazza ossea resistente al resto dei colpi.',
    ['ogor_slam', 'ogor_ray', 'ogor_restore', 'ogor_core'],
    'frammento_ogor',
  ).copyWith(
    encounterRules: {
      'authoredCanonical': true,
      'huntReward': {'kills': 5, 'skillId': 'ogor_restore'},
      'rayDropTotal': 46,
      'intactCoreDrop': true,
    },
  ),
  _canonicalCreature(
    'teirak',
    'Teirak',
    '',
    ['morti', 'sotterraneo_maggiore'],
    'oculum',
    [8, 8, 10, 12],
    7,
    'Un colosso di ossa e pietra consunta, con una testa piccola incassata fra un grande collare di costole e crani. Molte braccia scheletriche sporgono dalla schiena; le due principali reggono enormi armi ricurve ricavate da ossa seghettate. Un mantello di placche sovrapposte scende sul torace; rune viola si accendono fra le fessure del petto e lungo la cintura. Avanza sollevando polvere. Le rune evocano versioni molto forti dei poteri dei mostri. È un Mini Boss: al 60% Vita o meno attiva Ricordo Vitale per sei turni, una volta per scontro. I suoi critici possono velare la Vita del bersaglio per tre turni.',
    'Le rune esposte tra le costole.',
    ['teirak_ray', 'teirak_bone_grasp', 'teirak_rune_guard'],
    'runa_teirak',
  ).copyWith(
    isMiniBoss: true,
    encounterRules: {
      'authoredCanonical': true,
      'vitalMemoryThresholdPercent': 60,
      'vitalMemoryTurns': 6,
    },
  ),
];

final _boneRuneTechniques = <String, MonsterConcreteTechnique>{
  'monk_ki_hunt': _newPassive(
    'Ki Mortale accresciuto',
    'Quando attivi Ki Mortale ottieni un bonus 1d10: da 1 a 5 diventa +5 Ki, da 6 a 10 diventa +10. Una sola applicazione per attivazione.',
    'monk_ki_hunt',
    [1, 1, 1],
    element: 'nonmorto',
  ),
  'cult_beast_strike': _canonicalAttack(
    'Colpo della Bestia',
    'Il pugno segue la forza dell’Eiva che lo controlla. Un bersaglio e normali protezioni.',
    'bestiale',
    [5, 9, 14],
  ),
  'cult_beast_guard': _planarMove(
    'Proteggi la Bestia',
    'Il sigillo impone di resistere: +4/7/10 Difesa per due turni.',
    'bestiale',
    'difesa',
    [
      for (final n in [4, 7, 10])
        [MonsterTechniqueEffect('difesa', '$n', duration: '2')],
    ],
    costResource: 'materia',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cd: [3, 3, 3],
  ),
  'cult_beast_roar': _planarMove(
    'Ruggito imposto',
    'Il ruggito confonde un avversario: −2/3/4 ai tiri per un turno, se colpisce.',
    'sonoro',
    'danno',
    [
      for (final n in [2, 3, 4])
        [
          MonsterTechniqueEffect(
            'modifica_statistica',
            '-$n',
            target: 'tiro_globale',
            recipient: 'nemico',
            duration: '1',
          ),
        ],
    ],
    costResource: 'volonta',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cd: [3, 3, 3],
  ),
  'monk_palm': _canonicalAttack(
    'Palmo d’osso',
    'Un palmo o calcio preciso, senza un secondo attacco gratuito.',
    'contundente',
    [4, 8, 12],
  ),
  'monk_dragon': _planarMove(
    'Colpo del drago non morto · Open',
    'Un colpo Schianto devastante: +30/45/65 Danni. Il terreno trema; eventuali crolli dipendono dalla scena e sono decisi dal Master.',
    'nonmorto',
    'danno',
    [
      for (final n in [30, 45, 65])
        [
          MonsterTechniqueEffect(
            'danno',
            '$n',
            mode: 'prossima_azione',
            duration: '',
          ),
        ],
    ],
    minimums: [4, 6, 9],
    maximums: [4, 6, 9],
    cd: [5, 5, 5],
    level: 4,
  ),
  'monk_ki': _planarMove(
    'Ki Mortale',
    'Attivazione gratuita, CD 2 sessioni condiviso. Ottieni Ki verde dall’Oculum attuale ÷6; ogni critico su questa attivazione migliora il divisore di uno, fino a ÷3. Rimane finché lo consumi e può sostituire Oculum nei costi. Cinque Ki possono diventare una Reazione veloce. L’attivazione concede un’Azione aggiuntiva; sotto cinque Ki, quel Ki diventa invece un bonus alle quattro statistiche per una Azione.',
    'nonmorto',
    'utility',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'planar',
            '1',
            target: 'monk_ki',
            mode: 'immediato',
          ),
        ],
    ],
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cd: [2, 2, 2],
  ),
  'monk_seal': _planarMove(
    'È giunta la tua ora',
    'Toccando un nemico blocchi l’uso del suo Ki Mortale e Oculum per un turno, senza eliminarli. Deve colpire: normali tiro e difesa. CD 6 Azioni.',
    'nonmorto',
    'danno',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'planar',
            '1',
            target: 'monk_seal',
            recipient: 'nemico',
            duration: '1',
          ),
        ],
    ],
    minimums: [2, 3, 4],
    maximums: [2, 3, 4],
    cd: [6, 6, 6],
  ),
  'bone_sword_strike': _canonicalAttack(
    'Lama d’osso',
    'Un fendente della spada ricurva.',
    'taglio',
    [4, 8, 12],
  ),
  'bone_four_slash': _planarMove(
    'Quattro Slash',
    'Quattro fendenti contro un nemico, ciascuno con difesa separata. Ogni colpo già riuscito aumenta del 10/15/20% il danno dei successivi nella stessa azione. Ogni fendente parte da metà dei Danni, con normali protezioni.',
    'taglio',
    'danno',
    [
      for (final n in [10, 15, 20])
        [
          MonsterTechniqueEffect(
            'planar',
            '$n',
            target: 'bone_four_slash',
            mode: 'immediato',
          ),
        ],
    ],
    costResource: 'materia',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cd: [3, 3, 3],
  ),
  'bone_kill_regen': _newPassive(
    'Regen per kill',
    'Uccisione diretta: +1 Oculum e +5 Vita; assist registrato: +2 Vita. Non supera i massimi e non premia due volte lo stesso nemico.',
    'bone_kill_regen',
    [1, 1, 1],
    element: 'nonmorto',
  ),
  'bone_ground_spikes': _planarMove(
    'Spuntoni della Spada Osso',
    'Infilzi la spada nel terreno: fino a quattro nemici, Danni d’osso +5/8/12 e −4 ai loro tiri per un turno se colpiti.',
    'osso',
    'danno',
    [
      for (final n in [5, 8, 12])
        [
          MonsterTechniqueEffect(
            'danno',
            '$n',
            mode: 'prossima_azione',
            duration: '',
            maximumTargets: 4,
          ),
          const MonsterTechniqueEffect(
            'modifica_statistica',
            '-4',
            target: 'tiro_globale',
            recipient: 'nemico',
            duration: '1',
          ),
        ],
    ],
    minimums: [2, 3, 4],
    maximums: [2, 3, 4],
    cd: [3, 3, 3],
  ),
  'bone_monster_claws': _planarMove(
    'Artigli mostruosi',
    'Colpisce con gli artigli d’osso. Non usa Oculum: costa Materia e rispetta la normale Azione/Reazione.',
    'taglio',
    'danno',
    [
      for (final n in [3, 6, 9])
        [
          MonsterTechniqueEffect(
            'danno',
            '$n',
            mode: 'prossima_azione',
            duration: '',
          ),
        ],
    ],
    costResource: 'materia',
    minimums: [1, 1, 2],
    maximums: [1, 1, 2],
    cd: [2, 2, 2],
  ),
  'bone_monster_guard': _planarMove(
    'Incrocio d’ossa',
    'Incrocia le quattro braccia: +3/5/7 Difesa per un turno.',
    'osso',
    'difesa',
    [
      for (final n in [3, 5, 7])
        [MonsterTechniqueEffect('difesa', '$n', duration: '1')],
    ],
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cd: [3, 3, 3],
  ),
  'ogor_slam': _canonicalAttack(
    'Schianto corazzato',
    'La massa delle ossa abbatte un nemico.',
    'contundente',
    [8, 13, 18],
  ),
  'ogor_ray': _planarMove(
    'Raggio di Oculum · Open',
    'Dal nucleo VIOLA del petto parte un raggio spesso che esplode al contatto. Danni normali +1d90+50 / 1d110+65 / 1d130+80. Un bersaglio, normali Difesa e Scudi. Non utilizzabile con nucleo rotto.',
    'oculum',
    'danno',
    [
      for (final n in ['1d90+50', '1d110+65', '1d130+80'])
        [
          MonsterTechniqueEffect(
            'danno',
            n,
            mode: 'prossima_azione',
            duration: '',
          ),
        ],
    ],
    minimums: [5, 8, 11],
    maximums: [5, 8, 11],
    cd: [5, 5, 5],
    level: 5,
  ),
  'ogor_restore': _planarMove(
    'Ripristina energia',
    'Ripristina il flusso Oculum bloccato da debuff e recupera 3 Oculum entro il massimo. Una volta per Riposo Lungo.',
    'oculum',
    'utility',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'planar',
            '3',
            target: 'ogor_restore',
            mode: 'immediato',
          ),
        ],
    ],
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cd: [1, 1, 1],
  ),
  'ogor_core': _newPassive(
    'Nucleo di Oculum',
    'Oggetto di Grado I. Ogni tiro riuscito recupera 1 Oculum, massimo cinque volte per Riposo Breve o Lungo. Tre colpi riusciti al punto debole del portatore lo rompono e spengono l’effetto.',
    'ogor_core',
    [5, 5, 5],
    element: 'oculum',
  ),
  'teirak_ray': _planarMove(
    'Raggio runico',
    'Le rune concentrano un raggio viola: +18/28/40 Danni Oculum. Un critico vela la Vita del bersaglio per tre turni.',
    'oculum',
    'danno',
    [
      for (final n in [18, 28, 40])
        [
          MonsterTechniqueEffect(
            'danno',
            '$n',
            mode: 'prossima_azione',
            duration: '',
          ),
          const MonsterTechniqueEffect(
            'planar',
            '3',
            target: 'teirak_aphonia',
            recipient: 'nemico',
            duration: '3',
          ),
        ],
    ],
    minimums: [3, 5, 7],
    maximums: [3, 5, 7],
    cd: [3, 3, 3],
  ),
  'teirak_bone_grasp': _planarMove(
    'Presa delle rune d’osso',
    'Ossa evocate stringono un nemico: +12/20/30 Danni e −3 ai tiri per un turno. Il critico applica Vita Afona tre turni.',
    'osso',
    'danno',
    [
      for (final n in [12, 20, 30])
        [
          MonsterTechniqueEffect(
            'danno',
            '$n',
            mode: 'prossima_azione',
            duration: '',
          ),
          const MonsterTechniqueEffect(
            'modifica_statistica',
            '-3',
            target: 'tiro_globale',
            recipient: 'nemico',
            duration: '1',
          ),
          const MonsterTechniqueEffect(
            'planar',
            '3',
            target: 'teirak_aphonia',
            recipient: 'nemico',
            duration: '3',
          ),
        ],
    ],
    minimums: [3, 4, 6],
    maximums: [3, 4, 6],
    cd: [3, 3, 3],
  ),
  'teirak_rune_guard': _planarMove(
    'Corazza di rune',
    'Rune protettive aggiungono 20/35/50 Scudo. Al 60% Vita o meno Ricordo Vitale si attiva per sei turni, una volta per fight.',
    'oculum',
    'difesa',
    [
      for (final n in [20, 35, 50])
        [MonsterTechniqueEffect('scudo', '$n', mode: 'immediato')],
    ],
    minimums: [2, 3, 4],
    maximums: [2, 3, 4],
    cd: [4, 4, 4],
  ),
};
