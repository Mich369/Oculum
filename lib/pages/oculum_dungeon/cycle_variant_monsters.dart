part of 'monster_book.dart';

const _chikarCycleId = 'ciclo_cinghiale_fango_variante_chikar';
const _aberionBlueCycleId = 'ciclo_uomo_cactus_variante_aberion_blu';
const _aberionCycleId = 'ciclo_uomo_cactus_variante_aberion';
const _coloredHeronCycleId = 'ciclo_airone_guado_quieto_variante_colorato';
const _lunarHeronCycleId = 'ciclo_airone_guado_quieto_variante_lunare';
const _solidTurtleCycleId = 'ciclo_tartaruga_pioggia_chiara_variante_solida';
const _waterTurtleCycleId =
    'ciclo_tartaruga_pioggia_chiara_variante_incantatrice';

const _chikarFurrow = 'cycle_chikar_furrow';
const _blueAberionThorns = 'cycle_aberion_blue_thorns';
const _aberionRoots = 'cycle_aberion_grasping_roots';
const _heronFan = 'cycle_colored_heron_fan';
const _heronMoonShelter = 'cycle_lunar_heron_shelter';
const _solidTurtleGuard = 'cycle_solid_turtle_guard';
const _waterTurtleWeave = 'cycle_water_turtle_weave';

MonsterBookEntry _cycleArtVariant({
  required String baseId,
  required String id,
  required String italian,
  required String english,
  required String descriptionIt,
  required String descriptionEn,
  required String signature,
  required List<String> techniques,
  String? element,
  Map<String, int> stats = const {},
  String? openName,
  String? openKind,
}) {
  final base = oculumCycleMonsterEntries.firstWhere(
    (entry) => entry.id == baseId,
  );
  return base.copyWith(
    id: id,
    nameIt: italian,
    nameEn: english,
    descIt: descriptionIt,
    descEn: descriptionEn,
    elementId: element,
    skillIds: techniques,
    stats: {...base.stats, ...stats},
    classificationTags: [...base.classificationTags, 'Variante di specie'],
    encounterRules: {
      ...base.encounterRules,
      'canonicalVariantOf': baseId,
      'authoredSkillPool': true,
      'signatureSkillId': signature,
      'cycleOpenName': ?openName,
      'cycleOpenKind': ?openKind,
    },
  );
}

/// The original phase roster keeps its species IDs. Each form also has its own
/// stable entry for the chooser, saved sheets, turns and authored techniques.
final List<MonsterBookEntry> oculumCycleArtVariantEntries = List.unmodifiable([
  _cycleArtVariant(
    baseId: 'ciclo_cinghiale_fango',
    id: _chikarCycleId,
    italian: 'Chikar',
    english: 'Chikar',
    descriptionIt:
        'Forma più potente del Cinghiale del Fango. La crosta d’argilla si spezza tra il collo e le spalle mentre apre un solco con le zampe. Combatte prima con il Fango, poi con la Terra e infine con la Roccia.',
    descriptionEn:
        'A stronger Mud Boar form. The clay crust breaks along its neck and shoulders as it digs a furrow with its hooves. It fights with Mud first, Earth second and Rock last.',
    signature: _chikarFurrow,
    techniques: [_chikarFurrow, 'cycle_boar_earth', 'cycle_boar_rock'],
    stats: {'level': 4, 'resilienza': 8, 'materia': 7},
    openName: 'La palude cede al passo',
  ),
  _cycleArtVariant(
    baseId: 'ciclo_uomo_cactus',
    id: _aberionBlueCycleId,
    italian: 'Aberion blu',
    english: 'Blue Aberion',
    descriptionIt:
        'Forma blu dell’Uomo Cactus Assetato. Le pale carnose trattengono più liquido; quando le chiude intorno alle costole, le spine più rigide caricano il prossimo colpo di Natura.',
    descriptionEn:
        'A blue form of the Thirsting Cactus Man. Its fleshy pads hold more fluid. When it folds them across its ribs, the stiffer thorns prepare a harder Nature strike.',
    signature: _blueAberionThorns,
    techniques: [_blueAberionThorns, 'cycle_cactus_water'],
    stats: {'materia': 8},
    openName: 'Fioritura del blu assetato',
  ),
  _cycleArtVariant(
    baseId: 'ciclo_uomo_cactus',
    id: _aberionCycleId,
    italian: 'Aberion',
    english: 'Aberion',
    descriptionIt:
        'Variante dell’Uomo Cactus Assetato. Le escrescenze sporgono tra le articolazioni come uncini. Può spendere Materia per frenare un nemico con le radici e conserva il suo attacco di Natura alimentato da Oculum.',
    descriptionEn:
        'A Thirsting Cactus Man variant. Hooked growths protrude between its joints. It can spend Materia to slow an enemy with roots and retains its Oculum-powered Nature attack.',
    signature: _aberionRoots,
    techniques: ['cycle_cactus_spines', _aberionRoots, 'cycle_cactus_water'],
    openName: 'Le radici stringono il sentiero',
  ),
  _cycleArtVariant(
    baseId: 'ciclo_airone_guado_quieto',
    id: _coloredHeronCycleId,
    italian: 'Airone del Guado Quieto · Colorato',
    english: 'Quiet Ford Heron · Colorful',
    descriptionIt:
        'Il piumaggio colorato si apre a ventaglio sopra i sassi. Le piume indicano un passaggio poco profondo a chi lo segue; l’airone difende il nido solo se minacciato.',
    descriptionEn:
        'Colorful feathers fan out over the stones. They mark a shallow path for a companion, while the heron defends its nest only when threatened.',
    signature: _heronFan,
    techniques: ['ciclo_airone_guado_quieto_prima', _heronFan],
    openName: 'Il ventaglio indica il guado',
  ),
  _cycleArtVariant(
    baseId: 'ciclo_airone_guado_quieto',
    id: _lunarHeronCycleId,
    italian: 'Airone del Guado Quieto · Lunare',
    english: 'Quiet Ford Heron · Lunar',
    descriptionIt:
        'Forma lunare dell’Airone del Guado Quieto. Le piume fredde trattengono un riverbero indaco. Quando un compagno è esposto sul guado, estende un’ala per ripararlo.',
    descriptionEn:
        'The Lunar form of the Quiet Ford Heron. Its cool feathers hold an indigo glimmer. It spreads a wing to shelter a companion exposed on the ford.',
    signature: _heronMoonShelter,
    techniques: ['ciclo_airone_guado_quieto_prima', _heronMoonShelter],
    element: 'lunare',
    openName: 'L’ala veglia nel buio',
    openKind: 'scudo',
  ),
  _cycleArtVariant(
    baseId: 'ciclo_tartaruga_pioggia_chiara',
    id: _solidTurtleCycleId,
    italian: 'Tartaruga della Pioggia Chiara · Guscio solido',
    english: 'Clear Rain Turtle · Solid Shell',
    descriptionIt:
        'Forma più forte e robusta della Tartaruga della Pioggia Chiara. Quando si ritrae, le placche del carapace si puntellano come un argine. Conserva l’acqua raccolta nelle cavità del guscio per gli alleati.',
    descriptionEn:
        'A stronger, sturdier Clear Rain Turtle form. Its shell plates brace like a river embankment when it retracts. It keeps water in the hollows of its shell for its allies.',
    signature: _solidTurtleGuard,
    techniques: [_solidTurtleGuard, 'ciclo_tartaruga_pioggia_chiara_seconda'],
    stats: {'level': 4, 'resilienza': 7, 'materia': 5},
    openName: 'L’argine tiene',
  ),
  _cycleArtVariant(
    baseId: 'ciclo_tartaruga_pioggia_chiara',
    id: _waterTurtleCycleId,
    italian: 'Tartaruga della Pioggia Chiara · Incantatrice d’acqua',
    english: 'Clear Rain Turtle · Water Spellcaster',
    descriptionIt:
        'Forma della Tartaruga della Pioggia Chiara che incanta l’acqua del carapace. Solleva un filo di pioggia per curare e riparare lo stesso alleato.',
    descriptionEn:
        'A Clear Rain Turtle form that enchants the water in its shell. It lifts a thread of rain to heal and shelter the same companion.',
    signature: _waterTurtleWeave,
    techniques: ['ciclo_tartaruga_pioggia_chiara_prima', _waterTurtleWeave],
    openName: 'L’acqua ritorna al guscio',
    openKind: 'cura',
  ),
]);

final _cycleArtVariantTechniques = <String, MonsterConcreteTechnique>{
  _chikarFurrow: _planarMove(
    'Carica del solco',
    'Guadagna Movimento per un turno e potenzia il prossimo attacco di Fango.',
    'fango',
    'danno',
    [
      for (final form in const [(10, 1), (15, 2), (20, 3)])
        [
          MonsterTechniqueEffect(
            'danno',
            '${form.$1}',
            mode: 'prossima_azione',
            duration: '',
          ),
          MonsterTechniqueEffect(
            'modifica_sottotratto',
            '${form.$2}',
            target: 'movimento',
            mode: 'temporaneo',
            duration: '1',
          ),
        ],
    ],
    level: 4,
    minimums: const [1, 2, 3],
    maximums: const [1, 2, 3],
    cd: const [3, 3, 4],
  ),
  _blueAberionThorns: _planarMove(
    'Corona delle spine blu',
    'Le pale carnose aumentano la Difesa per un turno e preparano un attacco di Natura più forte.',
    'natura',
    'danno',
    [
      for (final form in const [(8, 1), (13, 2), (18, 3)])
        [
          MonsterTechniqueEffect(
            'danno',
            '${form.$1}',
            mode: 'prossima_azione',
            duration: '',
          ),
          MonsterTechniqueEffect(
            'difesa',
            '${form.$2}',
            mode: 'temporaneo',
            duration: '1',
          ),
        ],
    ],
    level: 3,
    minimums: const [1, 2, 3],
    maximums: const [1, 2, 3],
    cd: const [3, 3, 4],
  ),
  _aberionRoots: _planarMove(
    'Radice di presa',
    'Spende Materia per ridurre il Movimento di un nemico per un turno.',
    'natura',
    'controllo',
    [
      for (final penalty in const [2, 3, 4])
        [
          MonsterTechniqueEffect(
            'modifica_sottotratto',
            '$penalty',
            target: 'movimento',
            mode: 'diminuzione',
            duration: '1',
            recipient: 'nemico',
          ),
        ],
    ],
    level: 3,
    costResource: 'materia',
    minimums: const [1, 2, 3],
    maximums: const [1, 2, 3],
    cd: const [3, 3, 4],
  ),
  _heronFan: _planarMove(
    'Ventaglio del guado',
    'Indica un passaggio poco profondo e aumenta per un turno il Movimento di un alleato.',
    'acqua',
    'movimento',
    [
      for (final distance in const [2, 3, 4])
        [
          MonsterTechniqueEffect(
            'modifica_sottotratto',
            '$distance',
            target: 'movimento',
            mode: 'temporaneo',
            duration: '1',
            recipient: 'alleato',
          ),
        ],
    ],
    level: 1,
    minimums: const [1, 2, 3],
    maximums: const [1, 2, 3],
    cd: const [2, 2, 3],
  ),
  _heronMoonShelter: _planarMove(
    'Riparo di piume indaco',
    'Tende l’ala lunare e dà uno Scudo normale a un alleato.',
    'lunare',
    'scudo',
    [
      for (final shield in const [6, 10, 14])
        [
          MonsterTechniqueEffect(
            'scudo',
            '$shield',
            mode: 'immediato',
            duration: '',
            recipient: 'alleato',
          ),
        ],
    ],
    level: 1,
    minimums: const [1, 2, 3],
    maximums: const [1, 2, 3],
    cd: const [3, 3, 4],
  ),
  _solidTurtleGuard: _planarMove(
    'Argine di quarzo',
    'Serra il guscio e ottiene uno Scudo normale e Difesa per un turno.',
    'acqua',
    'scudo',
    [
      for (final form in const [(11, 2), (17, 3), (23, 4)])
        [
          MonsterTechniqueEffect(
            'scudo',
            '${form.$1}',
            mode: 'immediato',
            duration: '',
          ),
          MonsterTechniqueEffect(
            'difesa',
            '${form.$2}',
            mode: 'temporaneo',
            duration: '1',
          ),
        ],
    ],
    level: 4,
    minimums: const [1, 2, 3],
    maximums: const [1, 2, 3],
    cd: const [3, 3, 4],
  ),
  _waterTurtleWeave: _planarMove(
    'Trama d’acqua',
    'Incanta la pioggia del guscio, cura un alleato e gli dà uno Scudo normale.',
    'acqua',
    'cura',
    [
      for (final form in const [(5, 4), (9, 6), (13, 8)])
        [
          MonsterTechniqueEffect(
            'cura',
            '${form.$1}',
            mode: 'immediato',
            duration: '',
            recipient: 'alleato',
          ),
          MonsterTechniqueEffect(
            'scudo',
            '${form.$2}',
            mode: 'immediato',
            duration: '',
            recipient: 'alleato',
          ),
        ],
    ],
    level: 3,
    minimums: const [1, 2, 3],
    maximums: const [1, 2, 3],
    cd: const [3, 3, 4],
  ),
};
