part of 'monster_book.dart';

const oculumVolenterosiId = 'volenterosi';
const oculumVolenterosiTransformation = 'volenterosi_trasformazione';

const _volenterosi = MonsterBookEntry(
  id: oculumVolenterosiId,
  planeIds: ['mezzano'],
  nameIt: 'Volenterosi',
  nameEn: 'The Resolute',
  descIt:
      'Duellisti dai capelli azzurro cenere e da un occhio rosso visibile. '
      'Un’aura cremisi avvolge la spada e il pugno libero. Iniziano come NPC '
      'della squadra opposta. Possono unirsi al gruppo dopo aver stretto un '
      'legame o diventare ostili se considerano il gruppo una minaccia. '
      'Ogni attacco aggiunge ai Danni la loro Volontà attuale, senza consumarla.',
  descEn:
      'Duelists with ash-blue hair and one visible red eye. Crimson aura '
      'wraps their sword and free fist. They begin as NPCs on the opposing '
      'team. They may join after forming a bond or become hostile when they '
      'see the party as a threat. Each attack adds their current Willpower '
      'to its damage without spending it.',
  elementId: 'oculum',
  spriteAssetPath: '',
  isMiniBoss: false,
  isBoss: false,
  isNpc: true,
  isNullFateless: false,
  stats: {
    'level': 4,
    'resilienza': 6,
    'volonta': 10,
    'materia': 6,
    'oculum': 5,
  },
  encounterRules: {
    'authoredCanonical': true,
    'generationSide': 'enemy',
    'loadoutPolicy': 'sample_three',
    'signatureSkillId': oculumVolenterosiTransformation,
    'authoredUltimateIds': _volenterosiUltimateIds,
    'dispositions': ['prudente', 'legabile', 'ostile se minacciato'],
  },
  skillIds: [
    'volenterosi_fendente_cremisi',
    'volenterosi_pugno_del_voto',
    oculumVolenterosiTransformation,
    'volenterosi_guardia_di_braci',
    'volenterosi_affondo_risoluto',
    'volenterosi_passo_del_voto',
    'volenterosi_giuramento_breve',
    'volenterosi_mira_rossa',
    'volenterosi_respiro_fermo',
  ],
  inventoryItems: [
    {
      'nome': 'Gemma di Volontà',
      'quantita': 3,
      'peso': .1,
      'statGemStat': 'volonta',
      'statGemDieFaces': 3,
      'note':
          'Consumabile: recupera punti attuali di Volontà di 1d3. '
          'Una gemma, un solo tiro. Eccesso fino al riposo lungo.',
    },
  ],
  classificationTags: ['Umanoide', 'Sfidante'],
);

final _volenterosiTechniques = <String, MonsterConcreteTechnique>{
  'volenterosi_fendente_cremisi': const MonsterConcreteTechnique(
    name: 'Fendente Cremisi',
    action:
        'Avvolgi la lama di aura cremisi e colpisci un bersaglio a contatto',
    element: 'taglio',
    kind: 'danno',
    requiredLevel: 4,
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [2, 2, 3],
    forms: [
      [MonsterTechniqueEffect('danno', '5', mode: 'prossima_azione')],
      [MonsterTechniqueEffect('danno', '9', mode: 'prossima_azione')],
      [MonsterTechniqueEffect('danno', '14', mode: 'prossima_azione')],
    ],
  ),
  'volenterosi_pugno_del_voto': const MonsterConcreteTechnique(
    name: 'Pugno del Voto',
    action:
        'Interponi il pugno avvolto d’aura e rinforza la tua Difesa per un turno',
    element: 'oculum',
    kind: 'difesa',
    requiredLevel: 4,
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [2, 2, 3],
    forms: [
      [MonsterTechniqueEffect('difesa', '4')],
      [MonsterTechniqueEffect('difesa', '8')],
      [MonsterTechniqueEffect('difesa', '12')],
    ],
  ),
  oculumVolenterosiTransformation: MonsterConcreteTechnique(
    name: 'Forma del Voto',
    action:
        'Trasformati e ottieni Scudo, Volontà e Materia per la stessa durata tirata. '
        'Lo Scudo della forma rimasto si esaurisce al termine',
    element: 'oculum',
    kind: 'buff',
    requiredLevel: 4,
    minimums: const [2, 4, 6],
    maximums: const [2, 4, 6],
    cooldownValues: const [3, 5, 7],
    forms: [
      _volenterosoTransformationForm('1d3', '15', '9', '6'),
      _volenterosoTransformationForm('1d6+1', '50', '12', '9'),
      _volenterosoTransformationForm('1d9+3', '100', '24', '15'),
    ],
  ),
};

List<MonsterTechniqueEffect> _volenterosoTransformationForm(
  String duration,
  String shield,
  String will,
  String matter,
) => [
  MonsterTechniqueEffect(
    'planar',
    shield,
    target: oculumVolenterosiTransformation,
    duration: duration,
  ),
  MonsterTechniqueEffect(
    'modifica_statistica',
    will,
    target: 'volonta',
    duration: '',
  ),
  MonsterTechniqueEffect(
    'modifica_statistica',
    matter,
    target: 'materia',
    duration: '',
  ),
];
