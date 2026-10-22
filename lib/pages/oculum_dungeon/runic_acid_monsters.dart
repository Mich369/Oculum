part of 'monster_book.dart';

int oculumAcidSpitDuration(String difficulty) => switch (difficulty) {
  'facile' => 2,
  'difficile' => 5,
  'oculum' => 6,
  _ => 3,
};

int oculumRunicPassiveForm(int level) => level >= 6
    ? 3
    : level >= 3
    ? 2
    : 1;

final _runicAcidMonsterEntries = <MonsterBookEntry>[
  MonsterBookEntry(
    id: 'goblin_kamikaze',
    nameIt: 'Goblin Kamikaze',
    nameEn: 'Kamikaze Goblin',
    descIt:
        'Un goblin ricoperto di cariche e micce. Unica tecnica: Esplosione suicida, disponibile dopo 2 turni di ricarica. Colpisce tutti gli avversari dello schieramento attuale, sia buoni sia cattivi: come Occhio dei Caduti segue lo schieramento del proprietario. Infligge danni pari alla propria Vita massima, con danneggiamento Scudo al 150%, e muore esplodendo. Non possiede altre Skill. Valori modificabili.',
    descEn:
        'A goblin covered in charges and fuses. Its only technique is a suicide explosion after two cooldown turns: maximum-HP damage to all current opponents, 150 percent shield damage, then death. A Fallen Eye follows its owner’s side.',
    elementId: 'fuoco',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: const {
      'level': 0,
      'resilienza': 3,
      'volonta': 2,
      'materia': 4,
      'oculum': 0,
    },
    skillIds: const ['goblin_kamikaze_explosion'],
    dropIds: const [],
    dropChances: const {},
  ),
  MonsterBookEntry(
    id: 'golem_runico',
    nameIt: 'Golem Runico',
    nameEn: 'Runic Golem',
    descIt:
        'Un costrutto massiccio di piastre rosso cupo, giunti di pietra nera e catene spezzate. Solchi geometrici color rame attraversano petto e braccia; la testa è una calotta senza volto sopra una fessura buia. Le rune reagiscono ai colpi. RES 10, VOL 3, MAT 6, OCU 0. Tre passive gratuite crescono ai livelli 0/3/6: riflette il 10/15/20% dei danni dichiarati se supera il tiro difensivo; quando un suo colpo toglie Vita effettiva applica -2/-3/-4 Difesa per 1 turno, non cumulabile dalla stessa fonte; CM +3/+4/+5. Oculum Art: Open attiva Portali del nucleo, livello 6, nessun costo Oculum, CD 6 turni. Una sola attivazione per fight: un raggio per bersaglio scelto, danno pari alla Vita attuale del Golem, senza sommare il danno base; sul semicolpito metà danno. I raggi emergono da portali sul campo. Nessuna immagine allegata.',
    descEn:
        'A massive construct of dark red plates, black stone joints and broken chains. Copper geometric grooves cross its chest and limbs beneath a faceless dome. Free passives evolve at levels 0/3/6: reflect 10/15/20 percent of declared damage after a successful defense; inflicting actual HP loss applies -2/-3/-4 Defense for one turn; CM +3/+4/+5. Active Open: one current-HP beam per selected target, half on a partial hit, no ordinary base damage added, six-turn cooldown and once per fight.',
    elementId: 'pietra',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: const {
      'level': 0,
      'resilienza': 10,
      'volonta': 3,
      'materia': 6,
      'oculum': 0,
      'oculumArt': 1,
    },
    skillIds: const ['runic_reflection', 'runic_wound', 'runic_guard'],
    dropIds: const ['metallo_runico'],
    dropChances: const {'metallo_runico': 25},
  ),
  MonsterBookEntry(
    id: 'sputatore_corrosivo',
    nameIt: 'Sputatore Corrosivo',
    nameEn: 'Corrosive Spitter',
    descIt:
        'Una creatura bassa, pallida e gonfia, con ghiandole verdastre ai lati della gola. Attacco base Sputo acido: il colpo rispetta la normale difesa; se colpisce applica un logoramento da 2/3/6 Vita per turno nelle forme I/II/III, disponibili ai livelli 0/3/6. Il logoramento dura 3 turni normali, 2 in Facile, 5 in Difficile e 6 in Oculum; ignora Difesa, Scudo Oculum, Scudo e HP temporanei. Nessun danno periodico immediato all’applicazione. Il semicolpito dimezza la durata per difetto; la stessa fonte non si cumula ma rinnova l’effetto. La forma III è la più pericolosa. Valori modificabili.',
    descEn:
        'A low pale creature with swollen green throat glands. Acid Spit applies 2/3/6 HP corrosion per turn at levels 0/3/6. Duration: Easy two, Normal three, Hard five, Oculum six turns. Corrosion bypasses defense and shields and starts on the next turn; a partial hit halves duration. Same-source applications refresh without stacking.',
    elementId: 'acido',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: const {
      'level': 0,
      'resilienza': 5,
      'volonta': 3,
      'materia': 5,
      'oculum': 0,
    },
    skillIds: const ['corrosive_acid_spit'],
    dropIds: const ['ghiandola_acida'],
    dropChances: const {'ghiandola_acida': 30},
  ),
];

String oculumRunicAcidSkillText(String id) {
  final profile = switch (id) {
    'goblin_kamikaze_explosion' => (
      'Esplosione suicida',
      ['100', '100', '100'],
      'Danno pari al value% della propria Vita massima a tutti gli avversari dello schieramento attuale. Danneggiamento Scudo 150%. Il goblin muore esplodendo. CD iniziale 2 turni. Nessun’altra Skill.',
    ),
    'runic_reflection' => (
      'Specchio runico',
      ['10', '15', '20'],
      'Rifletti value% dei danni dichiarati contro chi ti attacca se superi il tiro difensivo.',
    ),
    'runic_wound' => (
      'Frattura delle rune',
      ['2', '3', '4'],
      'Se un tuo attacco toglie Vita effettiva, -value Difesa al bersaglio per 1 turno; stessa fonte non cumulabile.',
    ),
    'runic_guard' => ('Geometria della guardia', ['3', '4', '5'], '+value CM.'),
    'corrosive_acid_spit' => (
      'Sputo acido',
      ['2', '3', '6'],
      'Applica value danni periodici alla Vita, oltre Difesa e Scudi, per 3 turni (Facile 2, Difficile 5, Oculum 6).',
    ),
    _ => null,
  };
  if (profile == null) return '';
  final passive = id.startsWith('runic_');
  return '${profile.$1} — ${List.generate(3, (i) => '${['I', 'II', 'III'][i]}/${passive ? 'Passiva automatica: ' : ''}${profile.$3.replaceAll('value', profile.$2[i])} Richiede livello ${i * 3}. ${passive ? 'Nessun costo.' : '(${i + 1}/${i + 1} Volontà). CD 2 turni.'}').join(' ')}';
}
