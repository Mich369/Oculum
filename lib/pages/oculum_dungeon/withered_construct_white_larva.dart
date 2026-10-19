part of 'monster_book.dart';

const _witheredConstructWhiteLarvaEntries = [
  MonsterBookEntry(
    id: 'costrutto_rinsecchito',
    nameIt: 'Costrutto Rinsecchito',
    nameEn: 'Withered Construct',
    descIt:
        'Grado 0–I. Tank di legno secco con nucleo incrinato: Resilienza 2, Volontà 3, Materia 1 (crescente), Oculum 3. Eretti scudi di rami; Ricordo Vitale costa 1 Oculum per turno e dura al massimo tanti turni quanto Oculum all’attivazione. Il cuore raro cura il 90% della Vita massima e concede Ricordo Vitale per 1d9 turni.',
    descEn: 'Grade 0–I wooden tank with shields and Vital Memory upkeep.',
    elementId: 'natura',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'grade': 0,
      'resilienza': 2,
      'volonta': 3,
      'materia': 1,
      'oculum': 3,
    },
    skillIds: ['withered_shield', 'withered_memory', 'withered_strike'],
    dropIds: [
      'nucleo_rotto_debole',
      'rami_rinsecchiti',
      'cuore_rami_rinsecchiti',
    ],
    dropChances: {'cuore_rami_rinsecchiti': 3},
    classificationTags: ['Costrutto', 'Tank'],
  ),
  MonsterBookEntry(
    id: 'larva_bianca',
    nameIt: 'Larva Bianca',
    nameEn: 'White Larva',
    descIt:
        'Grado 0–I. Resilienza 1, Volontà 2, Materia 0, Oculum 0. Mosse senza costo con cooldown. Assalto prepara +5/+15/+45 Danni più Oculum (×1,5 nella seconda forma, ×2 nella terza). Infestazione genera una nidiata: 1d100 / 1d200+20 / 1d250+100 larve da 1 Vita, una sacrificata per danno. Scavata permette fuga su Velo oppure attacco con svantaggio alto al difensore. Un 20 naturale sul Drop rilascia una scroll Nidiata della forma disponibile del mostro; apprendimento raro come le altre scroll.',
    descEn: 'Grade 0–I larva with free cooldown moves and a sacrificial brood.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'grade': 0,
      'resilienza': 1,
      'volonta': 2,
      'materia': 0,
      'oculum': 0,
    },
    skillIds: [
      'white_larva_assault',
      'white_larva_brood',
      'white_larva_burrow',
    ],
    dropIds: [],
    classificationTags: ['Insetto', 'Mostro minore'],
  ),
];

String oculumWitheredLarvaSkillText(String id) => switch (id) {
  'withered_shield' =>
    'Scudo di rami — I/+5 + Materia×2 Scudo; II/+12 + Materia×3; III/+24 + Materia×4. Costo 1 Materia. CD 2/3/4 turni. Forme: livelli 0/3/6.',
  'withered_memory' =>
    'Ricordo del nucleo — I/Ricordo Vitale per Oculum turni, costo 1 Oculum per turno; II/stessa durata e mantenimento; III/stessa durata e mantenimento. Si interrompe se manca Oculum. Forme: livelli 0/3/6.',
  'withered_strike' =>
    'Ramo spezzato — I/+4 + Oculum Danni; II/floor((12 + Oculum)×1,5); III/(34 + Oculum)×2. Bonus al prossimo attacco, una sola volta. Costo 1/2/3 Volontà; CD 1/2/3. Forme: livelli 0/3/6.',
  'white_larva_assault' =>
    'Assalto — I/+5 + Oculum Danni; II/+15 + floor(Oculum×1,5); III/+45 + Oculum×2. Prossimo attacco, una sola volta. Costo 0. CD 2/3/4 turni. Forme: livelli 0/3/6.',
  'white_larva_brood' =>
    'Infestazione · Nidiata — I/1d100; II/1d200+20; III/1d250+100 larve da 1 Vita. Ogni danno destinato alla Vita uccide una larva prima del padrone. Non si cumula: rinnova la nidiata. Costo 0. CD 4/6/8 turni. Forme: livelli 0/3/6.',
  'white_larva_burrow' =>
    'Scavata — I/scegli Fuga: tiro Velo, oppure Attacco: il bersaglio riceve −6 al prossimo tiro; II/stessa scelta; III/stessa scelta. Il Master decide se il terreno permette di scavare. Costo 0. CD 3/4/5 turni. Forme: livelli 0/3/6.',
  _ => '',
};
