part of 'monster_book.dart';

bool oculumDeadKnightGetsOldLove({Random? random, int chancePercent = 5}) =>
    (random ?? Random.secure()).nextInt(100) < chancePercent.clamp(0, 100);

final _necromancerMonsterEntries = [
  MonsterBookEntry(
    id: 'cavaliere_morto',
    nameIt: 'Cavaliere Morto',
    nameEn: 'Dead Knight',
    descIt:
        'Armatura vuota animata attorno a una sfera di Oculum nascosta alla base della vita. Finché non ne scopri il punto debole, il corpo ignora i colpi: può subire danno solo dopo la scoperta della sfera oppure con un tiro naturale superiore a 17 e un totale che supera la sua CM. Porta spada e scudo. Spadata aggiunge 5 + Livello Danni per quella sola azione; la difesa cresce fino a uno Scudo Oculum. Raramente (impostazione iniziale 5%) possiede anche “Un vecchio amore”: una donna scheletrica dai capelli di colore casuale, armatura di pelle e arco che si erge dal terreno. È una Summon al livello del Cavaliere e può valere il doppio dell’EXP di una Summon ordinaria.',
    descEn:
        'An empty suit of armor animated around an Oculum sphere hidden at the base of its life. Until the weak point is discovered it ignores hits: it can take damage only after the sphere is exposed, or from a natural roll above 17 whose total exceeds its CM. It carries sword and shield. Sword Strike adds 5 + Level damage for that action; its defense grows into an Oculum Shield. Rarely (initial setting 5%) it also has “An Old Love”: a skeletal woman with randomly colored hair, leather armor and a bow who rises from the ground. She is a Summon at the Knight’s level and can grant twice the EXP of an ordinary Summon.',
    elementId: 'ombra',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: const {
      'level': 0,
      'resilienza': 7,
      'volonta': 4,
      'materia': 5,
      'oculum': 6,
    },
    skillIds: const [
      'necromancer_dead_knight_sword',
      'necromancer_dead_knight_shield',
      'necromancer_dead_knight_oculum_aegis',
    ],
    dropIds: const ['metallo_runico', 'nucleo_rotto_debole'],
    dropChances: const {'metallo_runico': 25, 'nucleo_rotto_debole': 20},
  ),
  MonsterBookEntry(
    id: 'necromante_cenere',
    nameIt: 'Necromante della Cenere',
    nameEn: 'Ash Necromancer',
    descIt:
        'Evoca due servitori d’ossa: ciascuno ha 10 + un terzo della Vita massima del necromante. Finché uno è vivo il necromante non subisce danni; quando entrambi cadono, la resurrezione ha CD 10 turni.',
    descEn:
        'Summons two bone thralls. Each has 10 plus one third of the necromancer max HP; damage is blocked while either thrall lives. Resurrection cooldown: 10 turns.',
    elementId: 'cenere',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: const {
      'level': 0,
      'resilienza': 5,
      'volonta': 9,
      'materia': 7,
      'oculum': 8,
    },
    skillIds: const [
      'necromancer_raise_dead',
      'necromancer_ash_bind',
      'necromancer_soul_flame',
    ],
    dropIds: const ['cenere_fenice', 'cuore_demone_maggiore'],
    dropChances: const {'cenere_fenice': 35, 'cuore_demone_maggiore': 10},
  ),
  MonsterBookEntry(
    id: 'necromante_ossidiana',
    nameIt: 'Necromante d’Ossidiana',
    nameEn: 'Obsidian Necromancer',
    descIt:
        'Due servitori d’ossidiana assorbono ogni danno prima del padrone. La Skill di evocazione ricrea i due servitori con CD 10 turni.',
    descEn:
        'Two obsidian thralls absorb damage before their master. Summoning cooldown is 10 turns.',
    elementId: 'ombra',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: const {
      'level': 0,
      'resilienza': 8,
      'volonta': 14,
      'materia': 11,
      'oculum': 13,
    },
    skillIds: const [
      'necromancer_raise_dead',
      'necromancer_obsidian_chain',
      'necromancer_black_sun',
    ],
    dropIds: const ['metallo_runico', 'cristallo_infernale'],
    dropChances: const {'metallo_runico': 30, 'cristallo_infernale': 25},
  ),
  MonsterBookEntry(
    id: 'necromante_fame',
    nameIt: 'Necromante della Fame',
    nameEn: 'Hunger Necromancer',
    descIt:
        'I due servitori divorano la luce dei colpi. La protezione termina solo quando entrambi sono a 0 HP; il richiamo torna disponibile dopo 10 turni.',
    descEn:
        'Two thralls devour the light of attacks. Protection ends only when both reach 0 HP; recall returns after 10 turns.',
    elementId: 'sangue',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: const {
      'level': 0,
      'resilienza': 9,
      'volonta': 18,
      'materia': 13,
      'oculum': 16,
    },
    skillIds: const [
      'necromancer_raise_dead',
      'necromancer_hunger_mark',
      'necromancer_last_feast',
    ],
    dropIds: const ['cuore_demone_maggiore', 'cenere_fenice'],
    dropChances: const {'cuore_demone_maggiore': 20, 'cenere_fenice': 40},
  ),
];

String oculumNecromancerSkillText(String id) {
  if (id == 'necromancer_dead_knight_sword') {
    return 'Spadata — I/Aumenti di 5 + Livello i Danni inflitti per questa sola azione; il bonus si consuma al termine del colpo. Richiede livello 0. Nessun costo Oculum. II/Aumenti di 5 + Livello i Danni della sola azione. Richiede livello 3. Nessun costo. III/Aumenti di 5 + Livello i Danni della sola azione. Richiede livello 6. Nessun costo.';
  }
  if (id == 'necromancer_dead_knight_shield') {
    return 'Difesa con spada e scudo — I/+5 Difesa per questo colpo. Richiede livello 0. Nessun costo Oculum. II/+8 Difesa e +20 Scudo fino a esaurimento per questo scontro. Richiede livello 3. Nessun costo. III/+12 Difesa e +30 Scudo fino a esaurimento per questo scontro. Richiede livello 6. Nessun costo.';
  }
  if (id == 'necromancer_dead_knight_oculum_aegis') {
    return 'Scudo della sfera — I/+5 Difesa per questo colpo. Richiede livello 0. Nessun costo Oculum. II/+8 Difesa e +10 Scudo Oculum fino a esaurimento per questo scontro. Richiede livello 3. Nessun costo. III/+12 Difesa e +20 Scudo Oculum fino a esaurimento per questo scontro. Richiede livello 6. Nessun costo.';
  }
  if (id == 'necromancer_raise_dead') {
    return 'Richiamo dei servitori — I/Crea due servitori, ciascuno con 10 + Vita massima del necromante/3 HP. Ogni Oculum immesso aggiunge 1 HP a ciascun servitore. Finché uno è vivo il necromante non subisce danni. CD 10 turni. Richiede livello 0. (1/4 Oculum). II/La stessa evocazione ottiene +10 HP per servitore, più 1 HP per ogni Oculum immesso. CD 10 turni. Richiede livello 3. (5/10 Oculum). III/La stessa evocazione ottiene +20 HP per servitore, più 1 HP per ogni Oculum immesso, e condivide le condizioni del padrone. CD 10 turni. Richiede livello 6. (11/30 Oculum).';
  }
  return _necromancerTechnique(id)?.text() ?? '';
}
