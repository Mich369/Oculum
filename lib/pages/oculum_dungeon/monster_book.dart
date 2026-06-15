class MonsterBookEntry {
  final String id;
  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;
  final String elementId;
  final String spriteAssetPath;
  final bool isMiniBoss;
  final bool isBoss;
  final bool isNullFateless;
  final Map<String, int> stats;
  final List<String> skillIds;
  final List<String> dropIds;

  const MonsterBookEntry({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.elementId,
    required this.spriteAssetPath,
    required this.isMiniBoss,
    required this.isBoss,
    required this.isNullFateless,
    this.stats = const {},
    this.skillIds = const [],
    this.dropIds = const [],
  });
}

/// Dati stabili dei mostri usati nel minigioco.
///
/// I PNG potrebbero non esistere ancora: in UI/painter deve essere sempre
/// presente un fallback (non crashare).
const List<MonsterBookEntry> monsterBookEntries = [
  MonsterBookEntry(
    id: 'slime_blu',
    nameIt: 'Slime Blu',
    nameEn: 'Blue Slime',
    descIt:
        'Tipo Slime. Range livello 1/9, senza Grado. Drop chiave: Slime Skin.',
    descEn: 'Slime type. Level range 1/9, no Grade. Key drop: Slime Skin.',
    elementId: 'slime',
    spriteAssetPath: 'assets/oculum/sprites/Slime.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
  ),
  MonsterBookEntry(
    id: 'bone_crown_boss',
    nameIt: 'Corona d\'Ossa',
    nameEn: 'Crown of Bones',
    descIt:
        'Un boss antico coronato da ossa. Emana una presenza fredda e protettiva.',
    descEn:
        'An ancient boss crowned with bones. Emits a cold, protective presence.',
    elementId: 'bone',
    spriteAssetPath: 'assets/oculum/sprites/Crown_of_Bones.png',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {'hp': 350, 'atk': 40, 'def': 30, 'spd': 8},
    skillIds: ['bone_crown_rend', 'bone_shield'],
    dropIds: ['bone_crown_fragment', 'ancient_bone'],
  ),
  MonsterBookEntry(
    id: 'fetal_man',
    nameIt: 'Uomo in Posizione Fetale',
    nameEn: 'Fetal Man',
    descIt:
        'Una figura rannicchiata, deformata dall\'angoscia; il suo corpo reagisce in modo imprevedibile.',
    descEn:
        'A curled figure, deformed by anguish; its body reacts unpredictably.',
    elementId: 'corrupted',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/uomo_in_posizione_fetale_refit.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 90, 'atk': 16, 'def': 6, 'spd': 9},
    skillIds: ['embrace_deform', 'weep_of_fate'],
    dropIds: ['corrupted_meat', 'impure_eye'],
  ),
  MonsterBookEntry(
    id: 'headless_man',
    nameIt: 'Uomo Decapitato',
    nameEn: 'Headless Man',
    descIt:
        'Un essere senza testa che vaga, guidato da una forza oscura; attacca con colpi brutali e imprevisti.',
    descEn:
        'A headless being that wanders, driven by a dark force; attacks with brutal, unexpected strikes.',
    elementId: 'blood',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/headless_man_blood.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 130, 'atk': 22, 'def': 12, 'spd': 6},
    skillIds: ['neck_seal', 'bloody_swarm'],
    dropIds: ['ancient_blood', 'neck_seal'],
  ),
  MonsterBookEntry(
    id: 'slime_blu_helmeted',
    nameIt: 'Slime Blu con Elmetto',
    nameEn: 'Helmeted Blue Slime',
    descIt:
        'Slime Blu corazzato. La pelle assorbe male il fuoco ma rimbalza sui colpi deboli.',
    descEn:
        'Armored Blue Slime. Its skin resists fire poorly but bounces weak hits well.',
    elementId: 'slime',
    spriteAssetPath: 'assets/oculum/sprites/Slime.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
  ),
  MonsterBookEntry(
    id: 'cultist_of_purple_eyes',
    nameIt: 'Cultista degli Occhi Viola',
    nameEn: 'Cultist of Purple Eyes',
    descIt:
        'Un devoto corrotto dell Oculum. Usa sguardi pressanti e marchi che consumano lentamente.',
    descEn:
        'A corrupted Oculum devotee. Uses oppressive gazes and marks that drain over time.',
    elementId: 'oculum',
    spriteAssetPath: 'assets/oculum/sprites/Cultist_of_Purple_Eyes.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 115, 'atk': 19, 'def': 10, 'spd': 11},
    skillIds: ['oculum_gaze', 'fate_pressure'],
    dropIds: ['purple_eye_shard', 'cultist_ribbon'],
  ),
  MonsterBookEntry(
    id: 'patalpa_dolce',
    nameIt: 'Patalpa Dolce',
    nameEn: 'Sweet Patalpa',
    descIt:
        'Una talpa patata. Generazione usa azione e Oculum per richiamare Patalpa Dolce con le stats del più debole.',
    descEn:
        'A potato mole. Generation spends an action and Oculum to summon a Sweet Patalpa using the weakest one’s stats.',
    elementId: 'flora',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/patalpa_dolce.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
  ),
  MonsterBookEntry(
    id: 'shadow_mimic',
    nameIt: 'Shadow Mimic',
    nameEn: 'Shadow Mimic',
    descIt:
        'Tipo Shadow. Shadow Eye riduce statistiche; Magic Item crea l’oggetto utile; Teletrasporto Tenebroso cerca la schiena.',
    descEn:
        'Shadow type. Shadow Eye lowers stats; Magic Item creates the useful item; Dark Teleport hunts your back.',
    elementId: 'shadow',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/shadow_mimic.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
  ),
  MonsterBookEntry(
    id: 'infant_nightmare_without_awakening',
    nameIt: 'Incubo senza Risveglio Infante',
    nameEn: 'Infant Nightmare Without Awakening',
    descIt:
        'Mostro errante Mini Boss. Raggio Penetrante, Resistenza e Pestone Esplosivo in forma giovane.',
    descEn:
        'Wandering miniboss. Penetrating Ray, Resistance and Explosive Stomp in a young form.',
    elementId: 'dream',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/infant_nightmare_without_awakening.png',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
  ),
  MonsterBookEntry(
    id: 'true_nightmare_without_awakening',
    nameIt: 'Vero Incubo senza Risveglio',
    nameEn: 'True Nightmare Without Awakening',
    descIt:
        'Boss errante Grado V/X. A metà vita ottiene enorme Scudo e un Salvataggio nello sheet completo.',
    descEn:
        'Grade V/X wandering boss. At half HP it grants massive Shield and a Saving Shield in the full sheet.',
    elementId: 'dream',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/true_nightmare_without_awakening.png',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
  ),
  MonsterBookEntry(
    id: 'null_fateless',
    nameIt: 'Null/Fateless',
    nameEn: 'Null/Fateless',
    descIt:
        'Null/Fateless: mini-boss inquietante. Se ti ferisce, il Fato non ricorda.',
    descEn:
        'Null/Fateless: an unsettling miniboss. If it wounds you, Fate does not remember.',
    elementId: 'nullum',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/null_fateless.png',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: true,
  ),
  MonsterBookEntry(
    id: 'rock_rhino',
    nameIt: 'Rock Rhino',
    nameEn: 'Rock Rhino',
    descIt:
        'Costrutto di Terra. Carica rocciosa, difesa alta e corpo compatto da JRPG dark fantasy.',
    descEn:
        'Earth Construct. Rocky charge, high defense and compact dark-fantasy JRPG body.',
    elementId: 'earth',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/rock_rhino.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 160, 'atk': 25, 'def': 24, 'spd': 5},
    skillIds: ['generic_power_strike', 'generic_guard'],
    dropIds: ['rock_horn', 'stone_plate'],
  ),
  MonsterBookEntry(
    id: 'postea_scientist',
    nameIt: 'Scienziato di Postea',
    nameEn: 'Postea Scientist',
    descIt:
        'Boss/evento di Postea: futuro, carne e fiori in una sola sagoma. Può potenziarsi se il fight si allunga.',
    descEn:
        'Postea event boss: future, flesh and flowers in one silhouette. Can enhance itself if the fight drags on.',
    elementId: 'postea',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/postea_scientist.png',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    skillIds: ['postea_vivisection_future', 'postea_gene_leviante'],
  ),
];

MonsterBookEntry? monsterById(String id) {
  try {
    return monsterBookEntries.firstWhere((e) => e.id == id);
  } catch (_) {
    return null;
  }
}

/// Hints di layout utili per futuri widget.
class MonsterBookLayoutHints {
  static const double defaultSpriteSize = 140;
  static const double mobileSpriteSize = 96;
}
