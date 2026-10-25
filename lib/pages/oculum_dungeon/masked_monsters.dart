part of 'monster_book.dart';

final _maskedMonsterEntries = <MonsterBookEntry>[
  _canonicalCreature(
    'uomo_maschera_solare',
    'Assassino Solare',
    'uomo_maschera',
    ['sacro', 'isole'],
    'solare',
    [6, 6, 6, 6],
    4,
    'Un assassino dal mantello chiaro porta una maschera d’oro opaco, con un foro aderente all’occhio e un marchio del sole inciso sulla fronte. Piccole crepe irradiano luce calda lungo i bordi. È poco più forte delle forme colorate: concentra raggi distruttivi, lancia piccoli soli e materializza un arco solare che guida due frecce verso i bersagli scelti.',
    'L’incisione del sole si apre mentre concentra un raggio.',
    ['masked_solar_ray', 'masked_small_sun', 'masked_solar_bow'],
    'incisione_maschera_solare',
  ),
  _canonicalCreature(
    'uomo_maschera_angelica',
    'Assassino Angelico',
    'uomo_maschera',
    ['angelico', 'sacro'],
    'angelico',
    [6, 7, 7, 10],
    5,
    'Una figura alta e composta, protetta da un mantello bianco e da una maschera d’oro pallido. Il foro segue il contorno di un unico occhio luminoso; sulla fronte il sole inciso è circondato da piccole tacche simili a un’aureola. Forte quanto L’Ombra Ignota, usa Raggio Angelico e un arco che scocca tre frecce segugio. Infligge il venticinque per cento di danni aggiuntivi a Chaos e, ogni tre colpi che raggiungono la Vita, recupera il cinque per cento della Vita rimasta.',
    'Il giunto fra aureola incisa e bordo superiore della maschera.',
    ['raggio_angelico', 'masked_angelic_bow', 'masked_angelic_memory'],
    'incisione_maschera_angelica',
  ),
  _canonicalCreature(
    'uomo_maschera',
    'Uomo con la maschera',
    '',
    ['mezzano'],
    'fisico',
    [4, 4, 4, 2],
    3,
    'Figura umana avvolta in un mantello sobrio, con mani fasciate e volto interamente coperto. La maschera può essere verde, rossa, blu o viola: il colore determina una disciplina diversa e resta fissato alla creazione. La verde custodisce il Ricordo Vitale, la rossa concentra i pugni, la blu concatena colpi e la viola modella Oculum in spuntoni e scudi.',
    'Le legature della maschera sotto la nuca.',
    ['masked_base_strike'],
    'legatura_maschera',
  ),
  _canonicalCreature(
    'uomo_maschera_verde',
    'Uomo con la maschera verde',
    'uomo_maschera',
    ['mezzano', 'foresta_elementale'],
    'fisico',
    [9, 4, 4, 2],
    3,
    'Un uomo dal mantello consunto porta una maschera verde scuro, incisa con venature simili a foglie. Il corpo robusto conserva una memoria soprannaturale dei colpi: la maggiore Resilienza è permanente e Ricordo Vitale segue le normali regole, inclusa la vulnerabilità aggiuntiva. Difende il volto con gli avambracci e risponde con brevi colpi pesanti.',
    'La giuntura fra mascella e legature posteriori.',
    ['masked_green_memory', 'masked_base_strike'],
    'scheggia_maschera_verde',
  ),
  _canonicalCreature(
    'uomo_maschera_rossa',
    'Uomo con la maschera rossa',
    'uomo_maschera',
    ['mezzano', 'sotterraneo'],
    'contundente',
    [4, 9, 4, 2],
    3,
    'La maschera rossa ha una superficie liscia attraversata da sottili crepe color rame. Spalle tese, mani fasciate e mantello corto lasciano libere le braccia. La sua Volontà superiore alimenta Pugno serio: un attacco di Schianto senza consumo di Azione o Reazione, che aggiunge il tiro al danno prima del potenziamento della forma.',
    'Il fianco scoperto mentre carica il pugno.',
    ['masked_serious_punch', 'masked_base_strike'],
    'scheggia_maschera_rossa',
  ),
  _canonicalCreature(
    'uomo_maschera_blu',
    'Uomo con la maschera blu',
    'uomo_maschera',
    ['mezzano', 'isole'],
    'fisico',
    [4, 4, 9, 2],
    3,
    'Una maschera blu opaca copre il volto di un combattente dalle fasce strette ai polsi e alle caviglie. La Materia superiore sostiene un equilibrio preciso. Concatena colpi di Riflessi oppure, dopo aver percepito il punto debole, di Precisione; cambia bersaglio con piccoli passi, senza trasformare la raffica in più Azioni.',
    'La caviglia d’appoggio durante il cambio di bersaglio.',
    ['masked_blue_chain', 'masked_base_strike'],
    'scheggia_maschera_blu',
  ),
  _canonicalCreature(
    'uomo_maschera_viola',
    'Uomo con la maschera viola',
    'uomo_maschera',
    ['mezzano', 'sotterraneo'],
    'oculum',
    [4, 4, 4, 9],
    3,
    'La maschera viola riflette una luce tenue dalle incisioni intorno agli occhi. Sotto il mantello le dita tracciano filamenti di Oculum che diventano spuntoni o lastre protettive. È soprattutto un mago: recupera due Oculum a ogni proprio turno; a riserva piena ha invece il venti per cento di ottenere un punto temporaneo. Gli scudi più evoluti possono riflettere parte degli attacchi evitati.',
    'Le mani mentre intreccia la forma dello scudo.',
    ['masked_violet_recovery', 'masked_oculum_spikes', 'masked_oculum_shield'],
    'scheggia_maschera_viola',
  ),
  _canonicalCreature(
    'ombra_ignota',
    'L’Ombra Ignota',
    'uomo_maschera',
    ['oblio', 'shadow_hell', 'mezzano'],
    'buio',
    [5, 6, 6, 8],
    5,
    'Una figura umana silenziosa indossa un mantello scuro e una maschera nera ovale, con solchi profondi a spirale che convergono su un’unica apertura laterale. Il foro è sagomato esattamente come un occhio e aderisce al suo contorno: mostra un solo occhio viola acceso, senza altra pelle visibile. L’Oculum Art L’Ombra gli permette di assottigliarsi in una sagoma intangibile al Fisico, spostarsi fra ombre e legare il movimento dei nemici con filamenti scuri.',
    'L’unico occhio visibile mentre l’ombra torna a essere solida.',
    [
      'masked_shadow_form',
      'masked_shadow_teleport',
      'masked_shadow_bind',
      'masked_shadow_blades',
    ],
    'frammento_spirale_nera',
  ),
];

MonsterConcreteTechnique _maskedMove(
  String name,
  String text,
  List<List<MonsterTechniqueEffect>> forms, {
  String element = 'fisico',
  String cost = 'nessuna',
  List<int> amounts = const [0, 0, 0],
  List<int> cd = const [3, 3, 3],
  int level = 3,
}) => _planarMove(
  name,
  text,
  element,
  'utility',
  forms,
  costResource: cost,
  minimums: amounts,
  maximums: amounts,
  cd: cd,
  level: level,
);

final _maskedTechniques = <String, MonsterConcreteTechnique>{
  'masked_solar_ray': _maskedMove(
    'Raggio distruttivo solare',
    'Il marchio sulla fronte concentra un raggio sottile e rovente contro un solo nemico.',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'danno',
            '${12 + f * 9}',
            mode: 'prossima_azione',
            duration: '',
          ),
        ],
    ],
    element: 'solare',
    cost: 'oculum',
    amounts: [2, 3, 5],
    cd: [3, 3, 4],
    level: 4,
  ),
  'masked_small_sun': _maskedMove(
    'Piccolo sole',
    'Una sfera solare ruota sul palmo e viene lanciata contro fino a tre bersagli vicini; il danno segue le normali regole d’area.',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'danno',
            '${18 + f * 12}',
            mode: 'prossima_azione',
            duration: '',
            maximumTargets: 3,
          ),
        ],
    ],
    element: 'solare',
    cost: 'oculum',
    amounts: [3, 4, 6],
    cd: [4, 4, 5],
    level: 4,
  ),
  for (final angelic in [false, true])
    (angelic ? 'masked_angelic_bow' : 'masked_solar_bow'): _maskedMove(
      angelic ? 'Arco angelico segugio' : 'Arco solare segugio',
      'Un arco di luce emerge dal braccio e scocca ${angelic ? 3 : 2} frecce verso altrettanti bersagli o ripetendo quelli selezionati. Tiro +${angelic ? 9 : 3}; una sola Azione/Reazione. Ogni freccia risolve la propria difesa.',
      [
        for (var f = 0; f < 3; f++)
          [
            MonsterTechniqueEffect(
              'planar',
              '${f + 1}',
              target: angelic ? 'mask_angelic_arrows' : 'mask_solar_arrows',
              mode: 'immediato',
            ),
          ],
      ],
      element: angelic ? 'angelico' : 'solare',
      cost: 'oculum',
      amounts: angelic ? [3, 4, 5] : [2, 3, 4],
      cd: [3, 3, 4],
      level: angelic ? 5 : 4,
    ),
  'masked_angelic_memory': _maskedMove(
    'Ricordo angelico',
    'Passiva: +25% Danni contro Chaos. Ogni tre colpi che tolgono Vita, cura il 5% della Vita rimasta per eccesso; niente resurrezione, conteggio azzerato a fine fight.',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'planar',
            '25',
            target: 'mask_angelic_memory',
            mode: 'finche_attivo',
          ),
          const MonsterTechniqueEffect(
            'planar',
            '5',
            target: 'mask_angelic_heal',
            mode: 'finche_attivo',
          ),
          const MonsterTechniqueEffect(
            'planar',
            '3',
            target: 'mask_angelic_hits',
            mode: 'finche_attivo',
          ),
        ],
    ],
    element: 'angelico',
    cd: [0, 0, 0],
    level: 5,
  ),
  'masked_base_strike': _canonicalAttack(
    'Colpo mascherato',
    'Un breve colpo dell’avambraccio, diretto al centro del bersaglio.',
    'contundente',
    [3, 5, 8],
    requiredLevel: 3,
  ),
  'masked_green_memory': _maskedMove(
    'Ricordo della maschera verde',
    'Passiva: Ricordo Vitale permanente, con tutte le normali regole. La maggiore Resilienza fa parte delle statistiche della variante.',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'planar',
            '1',
            target: 'mask_vital_memory',
            mode: 'finche_attivo',
          ),
        ],
    ],
    cd: [0, 0, 0],
  ),
  'masked_serious_punch': _maskedMove(
    'Pugno serio',
    'Gratuita: nessuna Azione, Reazione o statistica. Usa Schianto; aggiungi il totale del tiro ai Danni e poi +10%/+20%/+50%. Un bersaglio; cooldown condiviso 3 turni.',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'planar',
            '${f + 1}',
            target: 'mask_serious_punch',
            mode: 'immediato',
          ),
        ],
    ],
  ),
  'masked_blue_chain': _maskedMove(
    'Concatenazione di colpi',
    'Una sola Azione/Reazione; CD condiviso 2 turni. Riflessi +5: 1d5+1 / 1d6+3 / 1d8+5 colpi da un terzo dei Danni. Precisione su punti deboli noti: 1d3+1 / 1d5+2 / 1d6+3 colpi da tre settimi con Fragilità per ciascun colpo. Dividi fra i bersagli scelti e aggiungi 5% per bersaglio. Prima chi ti ha colpito per ultimo, altrimenti ordine casuale. Il critico difensivo interrompe i colpi futuri; dal terzo colpo basta il critico anche da un bersaglio ancora in attesa.',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'planar',
            '${f + 1}',
            target: 'mask_blue_volley',
            mode: 'immediato',
          ),
        ],
    ],
    cd: [2, 2, 2],
  ),
  'masked_violet_recovery': _maskedMove(
    'Respiro viola',
    'Passiva: a ogni tuo turno recuperi 2 Oculum mancanti; se sei già al massimo, 20% di ottenere 1 Oculum temporaneo.',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'planar',
            '2',
            target: 'mask_violet_recovery',
            mode: 'finche_attivo',
          ),
        ],
    ],
    element: 'oculum',
    cd: [0, 0, 0],
  ),
  'masked_oculum_spikes': _maskedMove(
    'Spuntoni di Oculum',
    'Filamenti viola si irrigidiscono in punte dirette a un bersaglio.',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'danno',
            '${8 + f * 7}',
            mode: 'prossima_azione',
            duration: '',
          ),
        ],
    ],
    element: 'oculum',
    cost: 'oculum',
    amounts: [2, 3, 4],
    cd: [2, 2, 3],
  ),
  'masked_oculum_shield': _maskedMove(
    'Scudo intrecciato',
    'Una lastra viola dà Scudo. Le forme II/III riflettono il 20%/35% di un attacco evitato per due turni.',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect('scudo', '${20 + f * 15}+livello'),
          if (f > 0)
            MonsterTechniqueEffect(
              'modifica_statistica',
              '${f == 1 ? 20 : 35}',
              target: 'runic_reflection_percent',
              duration: '2',
              mode: 'temporaneo',
            ),
        ],
    ],
    element: 'oculum',
    cost: 'oculum',
    amounts: [2, 3, 4],
    cd: [3, 3, 4],
  ),
  'masked_shadow_form': _maskedMove(
    'Diventa ombra',
    'Fisico ignorato; +5 ai tiri Attacco/Difesa. I: una tua azione; II: fine turno corrente; III: inizio prossimo tuo turno. Se primo in iniziativa: +3 Danni e +1 Difesa ogni 10 livelli, minimi +2/+1.',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'planar',
            '${f + 1}',
            target: 'mask_shadow_form',
            mode: 'immediato',
          ),
        ],
    ],
    element: 'buio',
    cost: 'oculum',
    amounts: [2, 3, 4],
    cd: [4, 5, 6],
    level: 5,
  ),
  'masked_shadow_teleport': _maskedMove(
    'Teletrasporto nell’ombra',
    'Scegli il prossimo uso: Attacco +9 oppure Difesa +10, senza sommare entrambi. Reazione veloce extra al 10%/15%/30% secondo l’ultima forma di Diventa ombra attivata.',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'planar',
            '${f + 1}',
            target: 'mask_shadow_teleport',
            mode: 'immediato',
          ),
        ],
    ],
    element: 'buio',
    cost: 'oculum',
    amounts: [1, 2, 3],
    cd: [3, 3, 4],
    level: 5,
  ),
  'masked_shadow_bind': _maskedMove(
    'Legame d’ombra',
    'La propria ombra si allunga in una striscia sottile, aggancia quella del bersaglio e ne blocca i passi per un turno. La lama scura infligge pochi danni.',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'danno',
            '${4 + f * 4}',
            mode: 'prossima_azione',
            duration: '',
          ),
          const MonsterTechniqueEffect(
            'stato',
            '1',
            target: 'immobilizzato',
            recipient: 'nemico',
            duration: '1',
          ),
        ],
    ],
    element: 'buio',
    cost: 'oculum',
    amounts: [2, 3, 4],
    cd: [3, 3, 4],
    level: 5,
  ),
  'masked_shadow_blades': _maskedMove(
    'Lame dal riflesso',
    'L’ombra sotto il bersaglio si piega in due lame sottili che scattano verso l’alto, lasciando la sagoma dell’utilizzatore intatta.',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'danno',
            '${10 + f * 8}',
            mode: 'prossima_azione',
            duration: '',
          ),
        ],
    ],
    element: 'buio',
    cost: 'oculum',
    amounts: [2, 4, 6],
    cd: [3, 4, 4],
    level: 5,
  ),
};
