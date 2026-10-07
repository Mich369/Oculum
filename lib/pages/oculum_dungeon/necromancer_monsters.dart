part of 'monster_book.dart';

final _necromancerMonsterEntries = [
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
  if (id == 'necromancer_raise_dead') {
    return 'Richiamo dei servitori — I/Crea due servitori, ciascuno con 10 + Vita massima del necromante/3 HP. Ogni Oculum immesso aggiunge 1 HP a ciascun servitore. Finché uno è vivo il necromante non subisce danni. CD 10 turni. Richiede livello 0. (1/4 Oculum). II/La stessa evocazione ottiene +10 HP per servitore, più 1 HP per ogni Oculum immesso. CD 10 turni. Richiede livello 3. (5/10 Oculum). III/La stessa evocazione ottiene +20 HP per servitore, più 1 HP per ogni Oculum immesso, e condivide le condizioni del padrone. CD 10 turni. Richiede livello 6. (11/30 Oculum).';
  }
  return 'Tecnica necromantica — I/Un attacco del necromante o dei suoi servitori. Richiede livello 0. (1/4 Oculum). II/Aggiunge Oculum ai danni. Richiede livello 3. (5/10 Oculum). III/Colpisce anche un secondo bersaglio. Richiede livello 6. (11/30 Oculum).';
}
