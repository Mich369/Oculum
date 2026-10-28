part of 'monster_book.dart';

// User-confirmed level-zero powers. Growth is added by the existing sheet
// generator, never baked into this base a second time.
final _solarGuardAndGrofixEntries = <MonsterBookEntry>[
  for (final seed in const [
    (
      'guardia_solare',
      'Guardia Solare',
      [1, 4, 5, 3],
      false,
      'Umanoide in uniforme solare leggera, con mantellina corta e un elmo solare completo. La maschera frontale è semplice, di metallo brunito, con occhio solare inciso; non mostra capelli o volto. Il corpo è fragile: combatte in pattuglia, disturba con bagliori e impedisce di raggiungere i compagni. La lancia corta e lo scudo leggero gli consentono di punzecchiare e arretrare.',
      'Il fianco sotto il braccio che regge lo scudo.',
      'Pattuglia ostile ai Lunari, cerca rinforzi e preferisce logorare anziché sostenere uno scambio diretto.',
    ),
    (
      'guardia_solare_elite',
      'Guardia Solare élite',
      [16, 14, 14, 12],
      false,
      'Umanoide in uniforme solare rinforzata, con elmo solare integrale e maschera d’oro, placche d’oro opaco su torace e avambracci. I simboli sono occhi solari; l’equipaggiamento e il portamento comunicano una forza molto maggiore della guardia comune. Lusier ed Erik restano eccezioni personali al casco chiuso. Porta una lama disciplinata e uno scudo con occhio solare inciso. Alterna pressione, parate e lampi controllati: il suo fisico è equilibrato, senza la fragilità della guardia comune.',
      'La giuntura interna del gomito sotto la placca.',
      'Disciplina la pattuglia, copre gli alleati e punisce chi abbandona la guardia.',
    ),
    (
      'guardiano_solare',
      'Guardiano Solare',
      [56, 32, 26, 12],
      false,
      'Colosso umanoide lento e massiccio, chiuso in un’armatura solare pesante d’oro brunito. L’elmo non mostra il volto: un grande occhio solare incastonato osserva fra le piastre. Le spalle larghe sostengono un arco d’oro e le mani possono tendere due frecce dorate insieme. Le fessure del petto concentrano raggi solari. Ogni passo è deliberato e pesante; la forza serve a presidiare un passaggio, non a inseguire.',
      'La giuntura posteriore del ginocchio, esposta durante un passo.',
      'Custode territoriale: sbarra passaggi e protegge luoghi solari, avanza lentamente e domina una linea di tiro.',
    ),
    (
      'serafino_solare',
      'Serafino Solare',
      [40, 60, 40, 40],
      true,
      'Miniboss dal volto bello e inquietante, con SEI ali disposte in tre coppie. Le piume dorate custodiscono occhi oro e arancio; placche solari lasciano filtrare brace fra le giunture. Le ali superiori concentrano raggi, le mediane guidano il volo e le inferiori chiudono una corona di fuoco davanti al corpo. Non è il Serafino Boss già conosciuto: è una specie solare distinta.',
      'Le radici delle ali quando apre tutte e tre le coppie.',
      'Aggressivo e dominante, circonda il bersaglio con luce e fuoco solare.',
    ),
    (
      'serafino_angelico',
      'Serafino Angelico',
      [80, 35, 60, 25],
      true,
      'Miniboss dal volto armonioso e inquietante, con SEI grandi ali in tre coppie e occhi sobriamente distribuiti sulle penne. La corazza è di metallo angelico bianco con giunture d’oro. Le ali ripiegate si sovrappongono come protezioni, mentre il sigillo fra le mani concentra un giudizio angelico. È una specie distinta dal Serafino Boss preesistente.',
      'Il sigillo toracico visibile quando apre le ali per proteggere un alleato.',
      'Vigile e difensivo: preserva la formazione, protegge gli alleati e risponde con giudizi angelici.',
    ),
  ])
    _authoredPlanar(
      seed.$1,
      seed.$2,
      seed.$1 == 'serafino_angelico'
          ? ['angelico', 'sacro']
          : ['mezzano', 'sacro'],
      seed.$1 == 'serafino_angelico' ? 'angelico' : 'solare',
      seed.$5,
      seed.$6,
      seed.$3,
      0,
      false,
      seed.$4,
      [
        for (var i = 0; i < 4; i++) '${seed.$1}_tech_$i',
        if (seed.$1 == 'guardiano_solare') 'guardiano_solare_mazza_oro',
      ],
      {
        'authoredCanonical': true,
        'naturalAttitude': seed.$7,
        'celestialIdentity': seed.$1 == 'serafino_angelico'
            ? 'nessuna'
            : 'solare',
        if (seed.$1.startsWith('serafino_')) 'wingCount': 6,
        if (seed.$1 == 'guardiano_solare') 'slowColossus': true,
      },
      const {},
    ).copyWith(
      classificationTags: [
        seed.$1.startsWith('serafino_') ? 'Angelo' : 'Umanoide',
      ],
      dropIds: ['frammento_${seed.$1}', 'equip_${seed.$1}'],
      dropChances: {'frammento_${seed.$1}': 45, 'equip_${seed.$1}': 20},
    ),
  _authoredPlanar(
    'grofix',
    'Grofix',
    ['sotterraneo', 'sotterraneo_maggiore', 'reame_cristallo'],
    'natura',
    'Un’infestazione minerale risvegliata. Il corpo basso e asimmetrico è un intreccio di muschio grigio e verde, filamenti assorbenti e radici aderenti ai giacimenti trascurati. I materiali depredati si sfarinano e perdono potere. Dove l’infestazione ha sottratto più Grado crescono cristalli variegati, lunghi e molto appuntiti: colore e forma dipendono dai materiali assorbiti. Il nodo fibroso sotto la corona minerale si contrae quando risucchia Oculum. Può essere incontrato già vivo, oltre a risvegliarsi durante la raccolta infestata con un 1 naturale in presenza di Grofix in eccesso.',
    'Il nodo fibroso alla base della corona di cristalli.',
    [3, 2, 2, 2],
    1,
    false,
    false,
    ['grofix_morso', 'grofix_filamenti', 'grofix_guscio', 'grofix_sensi'],
    {
      'authoredCanonical': true,
      'naturalAttitude':
          'Si nutre dei giacimenti poco raccolti e difende ciò che sta assorbendo. Reagisce violentemente alla rimozione dei materiali infestati.',
      'materialInfestation': true,
      'canEncounterAlreadyAwake': true,
      'harvestAwakeningNatural': 1,
      'awakeningLevelSource': 'materialLevel',
    },
    const {},
  ).copyWith(
    classificationTags: ['Infestante', 'Creatura minerale'],
    dropIds: ['grofix'],
    dropChances: {'grofix': 60},
  ),
];

final _solarGuardAndGrofixTechniques = <String, MonsterConcreteTechnique>{
  'guardiano_solare_mazza_oro': _planarMove(
    'Mazza d’oro',
    'Evoca nelle mani una pesante mazza dorata di energia solare. '
        'La forma I moltiplica i Danni per ×1,2 per 1d3 turni personali; '
        'la II per ×1,3 per 1d3+2 turni personali; '
        'la III per ×1,5 per 1d3+3 turni personali. '
        'La durata viene tirata una sola volta all’attivazione. '
        'È un potenziamento temporaneo, non un attacco aggiuntivo né un oggetto da raccogliere; '
        'la mazza scompare alla scadenza. Riattivarla rinnova il bonus senza accumularlo.',
    'solare',
    'potenziamento',
    const [
      [
        MonsterTechniqueEffect(
          'danno_percentuale',
          '20',
          target: 'guardian_golden_mace',
          duration: '1d3',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'danno_percentuale',
          '30',
          target: 'guardian_golden_mace',
          duration: '1d3+2',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'danno_percentuale',
          '50',
          target: 'guardian_golden_mace',
          duration: '1d3+3',
        ),
      ],
    ],
    minimums: const [2, 4, 6],
    maximums: const [2, 4, 6],
    cd: const [4, 6, 8],
  ),
  for (final id in [
    'guardia_solare',
    'guardia_solare_elite',
    'guardiano_solare',
    'serafino_solare',
    'serafino_angelico',
  ])
    for (var slot = 0; slot < 4; slot++)
      '${id}_tech_$slot': _planarMove(
        slot == 0
            ? (id == 'guardiano_solare'
                  ? 'Due frecce d’oro'
                  : id.startsWith('serafino_')
                  ? 'Lancia delle sei ali'
                  : 'Affondo della pattuglia')
            : slot == 1
            ? (id == 'guardia_solare'
                  ? 'Bagliore molesto'
                  : 'Raggio del sigillo')
            : slot == 2
            ? 'Guardia delle placche'
            : 'Passo di presidio',
        slot == 0 && id == 'guardiano_solare'
            ? 'Tende l’arco e scocca due frecce d’oro: una sola Azione o Reazione, fino a due bersagli, difese separate. Prepara la raffica tramite il comando dell’arco già esistente.'
            : slot == 1 && id == 'guardia_solare'
            ? 'Inclina lo scudo inciso verso gli occhi del nemico: chi fallisce la difesa riceve Accecato per un turno.'
            : slot == 1
            ? 'Apre il sigillo e concentra un raggio contro un bersaglio, conservando le normali difese.'
            : slot == 2
            ? 'Chiude placche, scudo o ali sopra il punto debole, senza cancellare la Vita già perduta.'
            : slot == 3 && id == 'guardiano_solare'
            ? 'Si pianta sul terreno: la mole lenta riduce Movimento di 2 mentre rafforza la guardia per un turno.'
            : slot == 3
            ? 'Regola la distanza dalla propria formazione e protegge la linea di tiro.'
            : 'Colpisce con la propria arma o con una punta di luce condensata fra le ali.',
        id == 'serafino_angelico' ? 'angelico' : 'solare',
        slot == 2
            ? 'scudo'
            : slot == 3
            ? 'movimento'
            : 'danno',
        [
          for (var f = 0; f < 3; f++)
            [
              if (slot == 0 && id == 'guardiano_solare')
                MonsterTechniqueEffect(
                  'planar',
                  '${f + 1}',
                  target: 'mask_solar_arrows',
                  mode: 'immediato',
                  duration: '',
                )
              else if (slot == 1 && id == 'guardia_solare')
                const MonsterTechniqueEffect(
                  'stato',
                  '1',
                  target: 'accecato',
                  recipient: 'nemico',
                  duration: '1',
                )
              else if (slot == 2)
                MonsterTechniqueEffect(
                  'difesa',
                  '${(f + 1) * (id == 'guardia_solare' ? 2 : 5)}',
                  duration: '1',
                )
              else if (slot == 3) ...[
                MonsterTechniqueEffect(
                  'difesa',
                  '${(f + 1) * 2}',
                  duration: '1',
                ),
                if (id == 'guardiano_solare')
                  const MonsterTechniqueEffect('velocita', '-2', duration: '1'),
              ] else
                MonsterTechniqueEffect(
                  'danno',
                  '${(f + 1) * (id == 'guardia_solare'
                          ? 2
                          : id == 'guardia_solare_elite'
                          ? 6
                          : 12)}',
                  mode: 'prossima_azione',
                  duration: '',
                ),
            ],
        ],
        minimums: slot == 0 && id == 'guardiano_solare'
            ? const [2, 3, 4]
            : const [1, 2, 3],
        maximums: slot == 0 && id == 'guardiano_solare'
            ? const [2, 3, 4]
            : const [1, 2, 3],
        cd: slot == 1 ? const [3, 3, 4] : const [2, 3, 4],
      ),
  'grofix_morso': _planarMove(
    'Schegge del giacimento',
    'Contrae il muschio e protende le schegge cresciute dai materiali assorbiti contro un bersaglio.',
    'tagliente',
    'danno',
    _planarDamageForms([3, 6, 9]),
    minimums: const [1, 2, 3],
    maximums: const [1, 2, 3],
  ),
  'grofix_filamenti': _planarMove(
    'Filamenti succhia-Oculum',
    'I filamenti tentano di raggiungere la riserva del nemico: solo se il confronto riesce sottraggono Oculum. Il recupero della fonte non può essere inventato prima di conoscere quanto il bersaglio ha realmente perso.',
    'natura',
    'controllo',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'rimuovi_oculum',
            '${f + 1}',
            recipient: 'nemico',
            mode: 'immediato',
            duration: '',
          ),
        ],
    ],
    minimums: const [1, 2, 3],
    maximums: const [1, 2, 3],
  ),
  'grofix_guscio': _planarMove(
    'Crosta dei materiali rubati',
    'Sovrappone le placche minerali sottratte al giacimento intorno al nodo fibroso.',
    'roccia',
    'scudo',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'scudo',
            '${8 * (f + 1)}',
            mode: 'immediato',
            duration: '',
          ),
        ],
    ],
    minimums: const [1, 2, 3],
    maximums: const [1, 2, 3],
  ),
  'grofix_sensi': _planarMove(
    'Ascolto della vena',
    'Appoggia i filamenti alla roccia e percepisce vibrazioni nel minerale, senza rivelare automaticamente tutti i giacimenti.',
    'natura',
    'richiamo',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'modifica_sottotratto',
            '${2 * (f + 1)}',
            target: 'percezione',
            duration: '1',
          ),
        ],
    ],
    minimums: const [1, 2, 3],
    maximums: const [1, 2, 3],
  ),
};
