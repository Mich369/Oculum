part of 'monster_book.dart';

final _lavaMonsterEntries = [
  MonsterBookEntry(
    id: 'larva_lava',
    nameIt: 'Larva di Lava',
    nameEn: 'Lava Larva',
    descIt:
        'Creatura minore di magma vivo. Rigenera 3 HP a fine turno se non ha subito Gelo.',
    descEn:
        'Minor living magma creature. Regenerates 3 HP at end of turn unless hit by Frost.',
    elementId: 'lava',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: const {
      'level': 0,
      'resilienza': 3,
      'volonta': 1,
      'materia': 2,
      'oculum': 2,
    },
    skillIds: const [
      'lava_larva_bite',
      'lava_regeneration_minor',
      'lava_larva_splash',
    ],
    dropIds: const ['lava_tear_core'],
    dropChances: const {'lava_tear_core': 40},
  ),
  MonsterBookEntry(
    id: 'golem_lava',
    nameIt: 'Golem di Lava',
    nameEn: 'Lava Golem',
    descIt:
        'Guardiano di magma. Rigenera 8 HP a fine turno se non ha subito Gelo o Acqua.',
    descEn:
        'Magma guardian. Regenerates 8 HP at end of turn unless hit by Frost or Water.',
    elementId: 'lava',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: const {
      'level': 0,
      'resilienza': 7,
      'volonta': 3,
      'materia': 5,
      'oculum': 4,
    },
    skillIds: const [
      'lava_golem_slam',
      'lava_regeneration_guardian',
      'lava_golem_wall',
    ],
    dropIds: const ['lava_tear_core', 'metallo_runico'],
    dropChances: const {'lava_tear_core': 60, 'metallo_runico': 15},
  ),
  MonsterBookEntry(
    id: 'cuore_lava',
    nameIt: 'Cuore della Caldera',
    nameEn: 'Caldera Heart',
    descIt:
        'Nucleo maggiore di lava. Rigenera 15 HP a fine turno; Gelo o Acqua riducono la rigenerazione a 0 per un turno.',
    descEn:
        'Greater lava core. Regenerates 15 HP at end of turn; Frost or Water suppress it for one turn.',
    elementId: 'lava',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: const {
      'level': 0,
      'resilienza': 10,
      'volonta': 6,
      'materia': 8,
      'oculum': 8,
    },
    skillIds: const [
      'lava_heart_burst',
      'lava_regeneration_core',
      'lava_heart_fissure',
    ],
    dropIds: const ['lava_tear_core', 'metallo_runico', 'corno_forest_demon'],
    dropChances: const {
      'lava_tear_core': 80,
      'metallo_runico': 30,
      'corno_forest_demon': 10,
    },
  ),
];

String oculumLavaSkillText(String id) {
  if (!id.startsWith('lava_regeneration_')) return '';
  final amount = id.contains('minor')
      ? 3
      : id.contains('guardian')
      ? 8
      : 15;
  final weakness = id.contains('minor') ? 'Gelo' : 'Gelo o Acqua';
  final upgrades = id.contains('minor')
      ? 'II/5 HP. III/8 HP.'
      : id.contains('guardian')
      ? 'II/12 HP. III/16 HP e Scudo pari al 10% della Vita massima una volta per scontro sotto metà Vita.'
      : 'II/20 HP. III/25 HP e Scudo pari al 10% della Vita massima una volta per scontro sotto metà Vita.';
  return 'Rigenerazione di lava — I/Passiva automatica: a fine turno recuperi $amount HP se non hai subito $weakness. $upgrades Se $weakness ti colpisce, la rigenerazione resta a 0 per il prossimo turno e tutto viene scritto nel log del Master. Nessun tiro e nessun costo.';
}

int oculumLavaRegenerationAmount(String id) => id.contains('minor')
    ? 3
    : id.contains('guardian')
    ? 8
    : 15;
