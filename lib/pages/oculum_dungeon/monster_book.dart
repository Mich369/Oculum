class MonsterBookEntry {
  final String id;
  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;
  final String elementId;
  final String spriteAssetPath;
  final String imageBase64;
  final bool isMiniBoss;
  final bool isBoss;
  final bool isNpc;
  final bool isNullFateless;
  final Map<String, int> stats;
  final List<String> skillIds;
  final List<String> dropIds;
  final bool canWieldWeapons;
  final List<String> weaponTags;
  final List<String> armorTags;

  const MonsterBookEntry({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.elementId,
    required this.spriteAssetPath,
    this.imageBase64 = '',
    required this.isMiniBoss,
    required this.isBoss,
    this.isNpc = false,
    required this.isNullFateless,
    this.stats = const {},
    this.skillIds = const [],
    this.dropIds = const [],
    this.canWieldWeapons = false,
    this.weaponTags = const [],
    this.armorTags = const [],
  });

  String get presetType {
    if (isNpc) return 'NPC';
    if (isBoss) return 'Mostro Boss';
    if (isMiniBoss) return 'Mostro Mini Boss';
    return 'Mostro';
  }

  MonsterBookEntry copyWith({
    String? id,
    String? nameIt,
    String? nameEn,
    String? descIt,
    String? descEn,
    String? elementId,
    String? spriteAssetPath,
    String? imageBase64,
    bool? isMiniBoss,
    bool? isBoss,
    bool? isNpc,
    bool? isNullFateless,
    Map<String, int>? stats,
    List<String>? skillIds,
    List<String>? dropIds,
    bool? canWieldWeapons,
    List<String>? weaponTags,
    List<String>? armorTags,
  }) {
    return MonsterBookEntry(
      id: id ?? this.id,
      nameIt: nameIt ?? this.nameIt,
      nameEn: nameEn ?? this.nameEn,
      descIt: descIt ?? this.descIt,
      descEn: descEn ?? this.descEn,
      elementId: elementId ?? this.elementId,
      spriteAssetPath: spriteAssetPath ?? this.spriteAssetPath,
      imageBase64: imageBase64 ?? this.imageBase64,
      isMiniBoss: isMiniBoss ?? this.isMiniBoss,
      isBoss: isBoss ?? this.isBoss,
      isNpc: isNpc ?? this.isNpc,
      isNullFateless: isNullFateless ?? this.isNullFateless,
      stats: stats ?? this.stats,
      skillIds: skillIds ?? this.skillIds,
      dropIds: dropIds ?? this.dropIds,
      canWieldWeapons: canWieldWeapons ?? this.canWieldWeapons,
      weaponTags: weaponTags ?? this.weaponTags,
      armorTags: armorTags ?? this.armorTags,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nameIt': nameIt,
      'nameEn': nameEn,
      'descIt': descIt,
      'descEn': descEn,
      'elementId': elementId,
      'spriteAssetPath': spriteAssetPath,
      'imageBase64': imageBase64,
      'isMiniBoss': isMiniBoss,
      'isBoss': isBoss,
      'isNpc': isNpc,
      'isNullFateless': isNullFateless,
      'stats': Map<String, int>.from(stats),
      'skillIds': List<String>.from(skillIds),
      'dropIds': List<String>.from(dropIds),
      'canWieldWeapons': canWieldWeapons,
      'weaponTags': List<String>.from(weaponTags),
      'armorTags': List<String>.from(armorTags),
    };
  }

  factory MonsterBookEntry.fromJson(Map<String, dynamic> json) {
    final type = '${json['presetType'] ?? json['type'] ?? ''}'.toLowerCase();
    final statsRaw = json['stats'];
    final stats = <String, int>{};
    if (statsRaw is Map) {
      for (final entry in statsRaw.entries) {
        stats['${entry.key}'] = _monsterBookInt(entry.value);
      }
    }
    return MonsterBookEntry(
      id: '${json['id'] ?? ''}'.trim(),
      nameIt: '${json['nameIt'] ?? json['name'] ?? ''}'.trim(),
      nameEn: '${json['nameEn'] ?? json['nameIt'] ?? json['name'] ?? ''}'
          .trim(),
      descIt: '${json['descIt'] ?? json['description'] ?? ''}'.trim(),
      descEn: '${json['descEn'] ?? json['descIt'] ?? json['description'] ?? ''}'
          .trim(),
      elementId: '${json['elementId'] ?? 'fisico'}'.trim(),
      spriteAssetPath: '${json['spriteAssetPath'] ?? ''}'.trim(),
      imageBase64: '${json['imageBase64'] ?? ''}',
      isMiniBoss: _monsterBookBool(json['isMiniBoss']) || type.contains('mini'),
      isBoss:
          _monsterBookBool(json['isBoss']) &&
              !_monsterBookBool(json['isMiniBoss']) ||
          (type.contains('boss') && !type.contains('mini')),
      isNpc: _monsterBookBool(json['isNpc']) || type == 'npc',
      isNullFateless: _monsterBookBool(json['isNullFateless']),
      stats: stats,
      skillIds: _monsterBookStrings(json['skillIds']),
      dropIds: _monsterBookStrings(json['dropIds']),
      canWieldWeapons: _monsterBookBool(json['canWieldWeapons']),
      weaponTags: _monsterBookStrings(json['weaponTags']),
      armorTags: _monsterBookStrings(json['armorTags']),
    );
  }
}

int _monsterBookInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}

bool _monsterBookBool(dynamic value) {
  if (value is bool) return value;
  final normalized = '$value'.trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

List<String> _monsterBookStrings(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .map((entry) => '$entry'.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

/// Dati stabili dei mostri usati nel minigioco.
///
/// I PNG potrebbero non esistere ancora: in UI/painter deve essere sempre
/// presente un fallback (non crashare).
const List<MonsterBookEntry> _craftedMonsterBookEntries = [
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
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/slime_blu_helmeted.png',
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
    id: 'coro_facce_spezzate',
    nameIt: 'Coro delle Facce Spezzate',
    nameEn: 'Choir of Broken Faces',
    descIt:
        'Mostro Follia fantasma: maschere incrinate fuse in un coro nero. Strappa attenzione, Volonta e memoria breve.',
    descEn:
        'Madness ghost monster: cracked masks fused into a black choir. It tears attention, Will and short memory.',
    elementId: 'madness',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/coro_facce_spezzate.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 145, 'atk': 24, 'def': 12, 'spd': 13},
    skillIds: ['chorus_shatter', 'memory_wail', 'follia_echo'],
    dropIds: ['mask_shard', 'madness_pearl'],
  ),
  MonsterBookEntry(
    id: 'utero_di_specchio',
    nameIt: 'Utero di Specchio',
    nameEn: 'Mirror Womb',
    descIt:
        'Mini Boss Follia: guscio riflettente con occhi interni. Copia paure e rimanda skill con critico.',
    descEn:
        'Madness mini boss: reflective shell with inner eyes. Copies fears and reflects skills on criticals.',
    elementId: 'mirror',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/utero_di_specchio.png',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 260, 'atk': 34, 'def': 26, 'spd': 7},
    skillIds: ['mirror_birth', 'reflected_fear', 'silver_shell'],
    dropIds: ['mirror_veil', 'eye_glass'],
  ),
  MonsterBookEntry(
    id: 'giullare_ossa_filo',
    nameIt: 'Giullare Ossa-Filo',
    nameEn: 'Thread-Bone Jester',
    descIt:
        'Mostro Follia agile: burattino d ossa appeso a fili neri. Stunna ridendo e taglia reazioni.',
    descEn:
        'Agile Madness monster: bone puppet hanging from black threads. Stuns with laughter and cuts reactions.',
    elementId: 'thread',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/giullare_ossa_filo.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 125, 'atk': 30, 'def': 10, 'spd': 18},
    skillIds: ['wire_laugh', 'reaction_cut', 'puppet_dash'],
    dropIds: ['black_thread', 'jester_bone'],
  ),
  MonsterBookEntry(
    id: 'santo_vene_candela',
    nameIt: 'Santo delle Vene di Candela',
    nameEn: 'Candle-Vein Saint',
    descIt:
        'Boss Follia: santo di cera, aghi e vene accese. Brucia certezze, cura il proprio orrore e marchia il Fato.',
    descEn:
        'Madness boss: saint of wax, needles and lit veins. Burns certainty, heals its own horror and marks Fate.',
    elementId: 'wax_blood',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/santo_vene_candela.png',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {'hp': 520, 'atk': 52, 'def': 38, 'spd': 8},
    skillIds: ['candle_halo', 'vein_benediction', 'fate_brand'],
    dropIds: ['holy_wax', 'red_wick_heart'],
  ),
  MonsterBookEntry(
    id: 'opalus',
    nameIt: 'Opalus',
    nameEn: 'Opalus',
    descIt:
        'Mostro palustre di opale: riflette verde e cobalto al sole, trasforma la zona in palude e prende +10 nelle paludi.',
    descEn:
        'Opal swamp monster: reflects green and cobalt under the sun, turns the zone into swamp and gains +10 in swamps.',
    elementId: 'swamp',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/opalus.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 210, 'atk': 31, 'def': 24, 'spd': 9},
    skillIds: ['swamp_open', 'opal_reflect', 'cobalt_bite'],
    dropIds: ['opal_scale', 'swamp_core'],
  ),
  MonsterBookEntry(
    id: 'ushrin',
    nameIt: 'Ushrin',
    nameEn: 'Ushrin',
    descIt:
        'Mostro solare minuscolo: ali angeliche dorate, armatura nera e assalti in branco.',
    descEn:
        'Tiny solar monster: golden angel wings, black armor and swarm attacks.',
    elementId: 'solar',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/ushrin.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 80, 'atk': 22, 'def': 8, 'spd': 20},
    skillIds: ['solar_swarm', 'golden_pin', 'wing_flash'],
    dropIds: ['sun_pin', 'black_gold_chip'],
  ),
  MonsterBookEntry(
    id: 'cavaliere_campana_ruggine',
    nameIt: 'Cavaliere Campana Ruggine',
    nameEn: 'Rust Bell Knight',
    descIt:
        'Mostro corazzato: una campana arrugginita che cammina, tank lento con rintocchi che rompono la difesa.',
    descEn:
        'Armored monster: a walking rusty bell, slow tank with tolls that break defense.',
    elementId: 'rust',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/cavaliere_campana_ruggine.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 240, 'atk': 28, 'def': 34, 'spd': 4},
    skillIds: ['rust_toll', 'bell_guard', 'chain_drag'],
    dropIds: ['rust_bell_plate', 'cracked_clapper'],
  ),
  MonsterBookEntry(
    id: 'kitty_slime_errante',
    nameIt: 'Kitty Slime Errante',
    nameEn: 'Wandering Kitty Slime',
    descIt:
        'Slime puccioso e spesso innocuo. In facile puo comparire senza attaccare, regalando una piccola cura se trattato bene.',
    descEn:
        'Cute and often harmless slime. On easy it can appear without attacking and grant a small heal if treated kindly.',
    elementId: 'slime',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/kitty_slime_errante.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 55, 'atk': 6, 'def': 5, 'spd': 10},
    skillIds: ['soft_bounce', 'friendly_purr', 'tiny_bubble'],
    dropIds: ['kitty_slime_jelly', 'soft_crown_chip'],
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
  MonsterBookEntry(
    id: 'forest_demon',
    nameIt: 'Forest Demon',
    nameEn: 'Forest Demon',
    descIt:
        'Rettile gigante da foresta. Carica Devastante, Scatto Arretrante e Scatto Immateriale aiutano il Master a fare un bruiser mobile.',
    descEn:
        'Giant forest reptile. Devastating Charge, Backward Dash and Immaterial Dash make it a mobile bruiser.',
    elementId: 'natura',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/forest_demon.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 190, 'atk': 34, 'def': 18, 'spd': 12},
    skillIds: ['devastating_charge', 'back_dash', 'immaterial_dash'],
    dropIds: ['forest_demon_meat', 'heavy_horn'],
  ),
  MonsterBookEntry(
    id: 'plomp_piccolo',
    nameIt: 'Plomp Piccolo',
    nameEn: 'Small Plomp',
    descIt:
        'Sanguisuga cieca e lenta. Quando usa skill scatta di Materia, rotola e risucchia Oculum e vita.',
    descEn:
        'Blind slow leech. When it uses skills, it dashes with Matter, rolls and drains Oculum and life.',
    elementId: 'sangue',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/plomp_piccolo.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 95, 'atk': 18, 'def': 13, 'spd': 4},
    skillIds: ['plomp_dash', 'plomp_ball', 'plomp_leech'],
    dropIds: ['plomp_shell_low', 'low_plomp_converter'],
  ),
  MonsterBookEntry(
    id: 'plomp_adulto',
    nameIt: 'Plomp Adulto',
    nameEn: 'Adult Plomp',
    descIt:
        'Plomp maturo con corazza. Converte Oculum in Materia o Volonta e rende pericolosa ogni carica.',
    descEn:
        'Mature armored Plomp. Converts Oculum into Matter or Will and makes every charge dangerous.',
    elementId: 'sangue',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/plomp_adulto.png',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 210, 'atk': 33, 'def': 27, 'spd': 7},
    skillIds: ['plomp_dash_iii', 'plomp_ball_iii', 'plomp_leech_iii'],
    dropIds: ['plomp_shell', 'plomp_converter'],
  ),
  MonsterBookEntry(
    id: 'elementale_aria_minore',
    nameIt: 'Elementale dell Aria Minore',
    nameEn: 'Minor Air Elemental',
    descIt:
        'Elementale leggero. Spinge, disarma e si mette fuori portata senza fare troppo rumore.',
    descEn: 'Light elemental. Pushes, disarms and slips out of reach quietly.',
    elementId: 'vento',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/elementale_aria_minore.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 75, 'atk': 17, 'def': 7, 'spd': 23},
    skillIds: ['gust_step', 'air_cut', 'draft_guard'],
    dropIds: ['air_core'],
  ),
  MonsterBookEntry(
    id: 'elementale_fuoco_minore',
    nameIt: 'Elementale del Fuoco Minore',
    nameEn: 'Minor Fire Elemental',
    descIt:
        'Fiamma compatta. Brucia scudi leggeri e lascia una scia che obbliga il party a muoversi.',
    descEn:
        'Compact flame. Burns light shields and leaves a trail that forces movement.',
    elementId: 'fuoco',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/elementale_fuoco_minore.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 82, 'atk': 24, 'def': 8, 'spd': 16},
    skillIds: ['small_fireball', 'ember_skin', 'flame_step'],
    dropIds: ['fire_core'],
  ),
  MonsterBookEntry(
    id: 'elementale_acqua_minore',
    nameIt: 'Elementale dell Acqua Minore',
    nameEn: 'Minor Water Elemental',
    descIt:
        'Acqua viva. Cura poco, rallenta molto e spegne effetti di fuoco vicini.',
    descEn:
        'Living water. Heals a little, slows a lot and snuffs nearby fire effects.',
    elementId: 'acqua',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/elementale_acqua_minore.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 92, 'atk': 18, 'def': 14, 'spd': 13},
    skillIds: ['undertow', 'water_skin', 'little_tide'],
    dropIds: ['water_core'],
  ),
  MonsterBookEntry(
    id: 'elementale_terra_minore',
    nameIt: 'Elementale della Terra Minore',
    nameEn: 'Minor Earth Elemental',
    descIt:
        'Terra compatta. Mette coperture, trattiene caviglie e protegge mostri piu fragili.',
    descEn:
        'Compact earth. Creates cover, catches ankles and protects frailer monsters.',
    elementId: 'terra',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/elementale_terra_minore.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 120, 'atk': 18, 'def': 24, 'spd': 6},
    skillIds: ['stone_cover', 'ankle_root', 'earth_guard'],
    dropIds: ['earth_core'],
  ),
  MonsterBookEntry(
    id: 'elementale_gelo_minore',
    nameIt: 'Elementale del Gelo Minore',
    nameEn: 'Minor Ice Elemental',
    descIt:
        'Gelo minuto. Congela per un turno con dado open raro e crea terreno scivoloso.',
    descEn:
        'Small frost. Freezes for one turn on rare open rolls and creates slippery ground.',
    elementId: 'gelo',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/elementale_gelo_minore.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 88, 'atk': 21, 'def': 12, 'spd': 12},
    skillIds: ['ice_pin', 'frost_skin', 'slip_field'],
    dropIds: ['ice_core'],
  ),
  MonsterBookEntry(
    id: 'elementale_fulmine_minore',
    nameIt: 'Elementale del Fulmine Minore',
    nameEn: 'Minor Lightning Elemental',
    descIt:
        'Fulmine nervoso. Salta tra bersagli vicini e scarica reazioni veloci.',
    descEn:
        'Nervous lightning. Jumps between nearby targets and drains fast reactions.',
    elementId: 'fulmine',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/elementale_fulmine_minore.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 74, 'atk': 27, 'def': 6, 'spd': 24},
    skillIds: ['spark_jump', 'reaction_static', 'flash_escape'],
    dropIds: ['lightning_core'],
  ),
  MonsterBookEntry(
    id: 'elementale_ombra_minore',
    nameIt: 'Elementale dell Ombra Minore',
    nameEn: 'Minor Shadow Elemental',
    descIt:
        'Ombra bassa. Diventa invisibile per una azione e prende vantaggio al colpo seguente.',
    descEn:
        'Low shadow. Turns invisible for one action and gains advantage on the next hit.',
    elementId: 'oscuro',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/elementale_ombra_minore.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 86, 'atk': 25, 'def': 10, 'spd': 19},
    skillIds: ['one_action_invisible', 'shadow_backstab', 'dark_step'],
    dropIds: ['shadow_core'],
  ),
  MonsterBookEntry(
    id: 'elementale_sangue_minore',
    nameIt: 'Elementale del Sangue Minore',
    nameEn: 'Minor Blood Elemental',
    descIt:
        'Sangue coagulato. Ruba cure, apre ferite e rinforza mostri feriti.',
    descEn:
        'Clotted blood. Steals healing, opens wounds and empowers hurt monsters.',
    elementId: 'sangue',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/elementale_sangue_minore.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 105, 'atk': 23, 'def': 14, 'spd': 11},
    skillIds: ['blood_tax', 'open_wound', 'red_transfer'],
    dropIds: ['blood_core'],
  ),
  MonsterBookEntry(
    id: 'elementale_suono_minore',
    nameIt: 'Elementale del Suono Minore',
    nameEn: 'Minor Sound Elemental',
    descIt:
        'Risonanza viva. Usa strilli, rompe concentrazione e stunna chi non si copre.',
    descEn:
        'Living resonance. Screams, breaks focus and stuns anyone who fails to cover up.',
    elementId: 'sonoro',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/elementale_suono_minore.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 78, 'atk': 26, 'def': 8, 'spd': 18},
    skillIds: ['mad_scream', 'focus_break', 'echo_guard'],
    dropIds: ['sound_core'],
  ),
  MonsterBookEntry(
    id: 'pelle_sorridente',
    nameIt: 'Pelle Sorridente',
    nameEn: 'Smiling Skin',
    descIt:
        'Gore leggero: pelle senza corpo con grande sorriso. Si appiccica e cambia il tipo danno con TypeSwitch.',
    descEn:
        'Light gore: skin without a body and a huge smile. Sticks and changes damage type with TypeSwitch.',
    elementId: 'sangue',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/pelle_sorridente.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 118, 'atk': 29, 'def': 11, 'spd': 15},
    skillIds: ['skin_grin', 'type_switch_bite', 'blood_wrap'],
    dropIds: ['smiling_skin_strip'],
  ),
  MonsterBookEntry(
    id: 'mago_zombie_contrasto',
    nameIt: 'Mago Zombie in Decadenza',
    nameEn: 'Decaying Zombie Mage',
    descIt:
        'Non morto con forze contrastanti. Parte con Grimorio: sei skill di elementi diversi e una Art random.',
    descEn:
        'Undead with clashing forces. Starts with a Grimoire: six different element skills and one random Art.',
    elementId: 'necrotico',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/mago_zombie_contrasto.png',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 185, 'atk': 38, 'def': 17, 'spd': 10},
    skillIds: ['six_living_pages', 'holy_rot', 'demonic_decay'],
    dropIds: ['rotting_grimoire_page'],
  ),
  MonsterBookEntry(
    id: 'bestia_invisibile_del_vantaggio',
    nameIt: 'Bestia Invisibile del Vantaggio',
    nameEn: 'Invisible Advantage Beast',
    descIt:
        'Mostro che sparisce per una azione. Dopo l invisibilita attacca con vantaggio e scudo Oculum.',
    descEn:
        'Monster that vanishes for one action. After invisibility it attacks with advantage and Oculum shield.',
    elementId: 'oscuro',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/bestia_invisibile_del_vantaggio.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 150, 'atk': 35, 'def': 13, 'spd': 21},
    skillIds: ['vanish_action', 'advantage_claw', 'oculum_hide'],
    dropIds: ['invisible_hide'],
  ),
  MonsterBookEntry(
    id: 'monaco_bocca_cucita',
    nameIt: 'Monaco con la Bocca Cucita',
    nameEn: 'Sewn-Mouth Monk',
    descIt:
        'Figura rituale. Non parla, prega al contrario e trasforma il silenzio in difesa.',
    descEn:
        'Ritual figure. Does not speak, prays backward and turns silence into defense.',
    elementId: 'spirituale',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/monaco_bocca_cucita.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 142, 'atk': 22, 'def': 28, 'spd': 8},
    skillIds: ['stitched_prayer', 'silent_guard', 'threaded_curse'],
    dropIds: ['stitched_vow'],
  ),
  MonsterBookEntry(
    id: 'angelo_palpebra_sporca',
    nameIt: 'Angelo Sporco della Palpebra',
    nameEn: 'Dirty Eyelid Angel',
    descIt:
        'Angelo corrotto e fragile. Acceca, giudica e cade addosso come un cattivo presagio.',
    descEn:
        'Corrupt fragile angel. Blinds, judges and falls onto targets like a bad omen.',
    elementId: 'angelico',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/angelo_palpebra_sporca.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 132, 'atk': 31, 'def': 12, 'spd': 18},
    skillIds: ['dirty_halo', 'eyelid_fall', 'blind_judgement'],
    dropIds: ['dirty_feather'],
  ),
  MonsterBookEntry(
    id: 'ragno_obser_falsi',
    nameIt: 'Ragno degli Obser Falsi',
    nameEn: 'False-Obser Spider',
    descIt:
        'Tesse monete false. Intrappola l avidita e trasforma gli Obser in esche.',
    descEn: 'Weaves fake coins. Traps greed and turns Obser into bait.',
    elementId: 'veleno',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/ragno_obser_falsi.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 116, 'atk': 28, 'def': 10, 'spd': 20},
    skillIds: ['false_coin_web', 'greed_poison', 'silk_trip'],
    dropIds: ['false_obser_silk'],
  ),
  MonsterBookEntry(
    id: 'fabbro_senza_lingua',
    nameIt: 'Fabbro Senza Lingua',
    nameEn: 'Tongueless Blacksmith',
    descIt:
        'Fabbro muto. Batte metallo vivo e modifica armi o scudi dei presenti.',
    descEn:
        'Mute smith. Hammers living metal and alters weapons or shields nearby.',
    elementId: 'metallo',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/fabbro_senza_lingua.png',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 230, 'atk': 37, 'def': 32, 'spd': 5},
    skillIds: ['living_anvil', 'shield_reforge', 'tongueless_hammer'],
    dropIds: ['silent_tongs'],
  ),
  MonsterBookEntry(
    id: 'cane_di_cenere',
    nameIt: 'Cane di Cenere',
    nameEn: 'Ash Hound',
    descIt:
        'Predatore di cenere. Corre basso, lascia polvere e punisce chi resta fermo.',
    descEn:
        'Ash predator. Runs low, leaves dust and punishes anyone standing still.',
    elementId: 'cenere',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/cane_di_cenere.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 110, 'atk': 30, 'def': 9, 'spd': 24},
    skillIds: ['ash_pounce', 'dust_choke', 'low_run'],
    dropIds: ['warm_ash_fang'],
  ),
  MonsterBookEntry(
    id: 'pellegrino_senza_volto',
    nameIt: 'Pellegrino Senza Volto',
    nameEn: 'Faceless Pilgrim',
    descIt:
        'Viandante senza lineamenti. Chiede nomi, ruba iniziativa e cammina fuori dalla mappa.',
    descEn:
        'Featureless wanderer. Asks for names, steals initiative and walks outside the map.',
    elementId: 'spazio',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/pellegrino_senza_volto.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 155, 'atk': 25, 'def': 16, 'spd': 17},
    skillIds: ['name_tax', 'map_walk', 'faceless_step'],
    dropIds: ['blank_pilgrim_mask'],
  ),
  MonsterBookEntry(
    id: 'bambola_vapium',
    nameIt: 'Bambola di Vapium',
    nameEn: 'Vapium Doll',
    descIt:
        'Bambola cava. Condensa vapore tagliente e finge di rompersi per attirare colpi.',
    descEn:
        'Hollow doll. Condenses cutting vapor and pretends to break to draw attacks.',
    elementId: 'vapium',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/bambola_vapium.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 125, 'atk': 27, 'def': 15, 'spd': 14},
    skillIds: ['vapium_cut', 'fake_break', 'steam_counter'],
    dropIds: ['vapium_button'],
  ),
  MonsterBookEntry(
    id: 'occhio_caduto',
    nameIt: 'Occhio Caduto',
    nameEn: 'Fallen Eye',
    descIt:
        'Occhio staccato dal cielo. Percepisce Oculum, marca fonti e punisce chi lo guarda troppo.',
    descEn:
        'Eye fallen from the sky. Senses Oculum, marks sources and punishes long gazes.',
    elementId: 'oculum',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/occhio_caduto.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 100, 'atk': 32, 'def': 8, 'spd': 16},
    skillIds: ['oculum_mark', 'source_sense', 'gaze_punish'],
    dropIds: ['fallen_eye_lens'],
  ),
  MonsterBookEntry(
    id: 'custode_mani_inverse',
    nameIt: 'Custode con Mani Inverse',
    nameEn: 'Keeper with Inverted Hands',
    descIt:
        'Guardiano storto. Para in modo impossibile e ruota le prese dei personaggi.',
    descEn: 'Crooked keeper. Parries impossibly and twists the party grip.',
    elementId: 'fisico',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/custode_mani_inverse.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 170, 'atk': 29, 'def': 26, 'spd': 10},
    skillIds: ['inverse_parry', 'grip_turn', 'keeper_guard'],
    dropIds: ['inverse_hand_charm'],
  ),
  MonsterBookEntry(
    id: 'santo_vuoto_piccolo',
    nameIt: 'Santo Vuoto Piccolo',
    nameEn: 'Small Hollow Saint',
    descIt:
        'Santo minuscolo e inquietante. Benedice il nulla e svuota gli scudi sbagliati.',
    descEn:
        'Tiny unsettling saint. Blesses nothingness and empties wrong shields.',
    elementId: 'vuoto',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/santo_vuoto_piccolo.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 136, 'atk': 31, 'def': 18, 'spd': 9},
    skillIds: ['hollow_blessing', 'empty_shield', 'small_absolution'],
    dropIds: ['hollow_wax_drop'],
  ),
  MonsterBookEntry(
    id: 'prince_slime',
    nameIt: 'Prince Slime',
    nameEn: 'Prince Slime',
    descIt:
        'Miniboss Slime. Tornado Slime, Schianto del Re e Spadata del Re Slime preparano il trono.',
    descEn:
        'Slime miniboss. Slime Tornado, King Crash and Slime King Sword prepare the throne.',
    elementId: 'slime',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/prince_slime.png',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 190, 'atk': 32, 'def': 21, 'spd': 12},
    skillIds: ['slime_tornado', 'king_crash', 'slime_sword'],
    dropIds: ['slime_prince_crown'],
  ),
  MonsterBookEntry(
    id: 'king_slime',
    nameIt: 'King Slime',
    nameEn: 'King Slime',
    descIt:
        'Boss Slime. Apertura Armata Slime: gli slime evocati morti gli ridanno Oculum.',
    descEn:
        'Slime boss. Slime Army opening: dead summoned slimes restore Oculum to it.',
    elementId: 'slime',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/king_slime.png',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {'hp': 420, 'atk': 48, 'def': 33, 'spd': 9},
    skillIds: ['slime_army', 'royal_absorb', 'crown_slam'],
    dropIds: ['king_slime_crown'],
  ),
  MonsterBookEntry(
    id: 'cuore_filo',
    nameIt: 'Cuore Filo',
    nameEn: 'Thread Heart',
    descIt:
        'Cuore appeso a fili. Taglia reazioni, protegge un alleato e si spezza in due fasi.',
    descEn:
        'Heart hanging by threads. Cuts reactions, protects an ally and breaks into two phases.',
    elementId: 'sangue',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/cuore_filo.png',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 240, 'atk': 36, 'def': 20, 'spd': 15},
    skillIds: ['thread_reaction_cut', 'heart_guard', 'second_pulse'],
    dropIds: ['thread_heart_core'],
  ),
  MonsterBookEntry(
    id: 'lanterniere_osso',
    nameIt: 'Lanterniere d Osso',
    nameEn: 'Bone Lantern-Bearer',
    descIt:
        'Portatore di lanterna ossea. Illumina mostri nascosti e fa tremare chi e a poca vita.',
    descEn:
        'Bone lantern bearer. Reveals hidden monsters and shakes low-health targets.',
    elementId: 'osso',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/lanterniere_osso.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 148, 'atk': 26, 'def': 20, 'spd': 11},
    skillIds: ['bone_lantern', 'fear_light', 'hidden_reveal'],
    dropIds: ['bone_lantern_hook'],
  ),
  MonsterBookEntry(
    id: 'specchio_mangiavoce',
    nameIt: 'Specchio Mangiavoce',
    nameEn: 'Voice-Eating Mirror',
    descIt:
        'Specchio vivo. Mangia la voce delle skill, riflette critici e rende muti per un turno.',
    descEn:
        'Living mirror. Eats skill voices, reflects criticals and silences for one turn.',
    elementId: 'cristallo',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/specchio_mangiavoce.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 165, 'atk': 30, 'def': 29, 'spd': 8},
    skillIds: ['voice_eat', 'critical_reflect', 'mirror_mute'],
    dropIds: ['voice_mirror_shard'],
  ),
  MonsterBookEntry(
    id: 'sentinella_lava_lacrime',
    nameIt: 'Sentinella di Lava e Lacrime',
    nameEn: 'Lava-and-Tears Sentinel',
    descIt:
        'Sentinella che piange lava. Alterna difesa rovente e linee di fuoco ad area.',
    descEn:
        'Sentinel that cries lava. Alternates burning defense and area fire lines.',
    elementId: 'lava',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/sentinella_lava_lacrime.png',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 260, 'atk': 42, 'def': 31, 'spd': 6},
    skillIds: ['lava_tears', 'heated_guard', 'fire_line'],
    dropIds: ['lava_tear_core'],
  ),
  MonsterBookEntry(
    id: 'obliterato_null',
    nameIt: 'Obliterato Null',
    nameEn: 'Null Obliterated',
    descIt:
        'Rarissimo mostro Null. Cancella dall esistenza e dal ricordo cio che uccide o disintegra.',
    descEn:
        'Very rare Null monster. Erases from existence and memory what it kills or disintegrates.',
    elementId: 'vuoto',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/obliterato_null.png',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: true,
    stats: {'hp': 540, 'atk': 64, 'def': 42, 'spd': 13},
    skillIds: ['memory_erase', 'existence_cut', 'null_rebirth'],
    dropIds: ['null_memory_ash'],
  ),
];

const int targetNormalMonsterCount = 96;
const int targetMiniBossMonsterCount = 69;
const int targetBossMonsterCount = 36;

final List<MonsterBookEntry> defaultMonsterBookEntries = List.unmodifiable(
  _withFallbackMonsterSkills([
    ..._craftedMonsterBookEntries,
    ..._generateMonsterTier(
      count: targetNormalMonsterCount - _craftedNormalMonsterCount,
      tier: _GeneratedMonsterTier.normal,
    ),
    ..._generateMonsterTier(
      count: targetMiniBossMonsterCount - _craftedMiniBossMonsterCount,
      tier: _GeneratedMonsterTier.miniBoss,
    ),
    ..._generateMonsterTier(
      count: targetBossMonsterCount - _craftedBossMonsterCount,
      tier: _GeneratedMonsterTier.boss,
    ),
  ]),
);

List<MonsterBookEntry> _activeMonsterBookEntries = defaultMonsterBookEntries;

List<MonsterBookEntry> get monsterBookEntries => _activeMonsterBookEntries;

void configureMonsterBookEntries({
  Iterable<MonsterBookEntry> customEntries = const <MonsterBookEntry>[],
  Iterable<String> removedIds = const <String>[],
}) {
  final hidden = removedIds
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet();
  final overrides = <String, MonsterBookEntry>{
    for (final entry in customEntries)
      if (entry.id.trim().isNotEmpty) entry.id.trim(): entry,
  };
  final merged = <MonsterBookEntry>[];
  final used = <String>{};

  for (final entry in defaultMonsterBookEntries) {
    if (hidden.contains(entry.id)) continue;
    final replacement = overrides[entry.id] ?? entry;
    merged.add(replacement);
    used.add(entry.id);
  }
  for (final entry in overrides.values) {
    if (hidden.contains(entry.id) || used.contains(entry.id)) continue;
    merged.add(entry);
    used.add(entry.id);
  }

  _activeMonsterBookEntries = List<MonsterBookEntry>.unmodifiable(merged);
}

void resetMonsterBookEntries() {
  _activeMonsterBookEntries = defaultMonsterBookEntries;
}

int get _craftedNormalMonsterCount => _craftedMonsterBookEntries
    .where((monster) => !monster.isMiniBoss && !monster.isBoss)
    .length;

int get _craftedMiniBossMonsterCount =>
    _craftedMonsterBookEntries.where((monster) => monster.isMiniBoss).length;

int get _craftedBossMonsterCount =>
    _craftedMonsterBookEntries.where((monster) => monster.isBoss).length;

enum _GeneratedMonsterTier { normal, miniBoss, boss }

const List<String> _baseMonsterBodies = [
  'Goblin',
  'Orco',
  'Kobold',
  'Gnoll',
  'Bandito delle Palpebre',
  'Cavaliere Vuoto',
  'Cane Lungo',
  'Capra Sorridente',
  'Bambola di Sale',
  'Occhio da Muro',
  'Pellegrino Cieco',
  'Arciere di Muschio',
  'Mago di Ruggine',
  'Slime d Acqua',
  'Slime di Latte',
  'Piccolo Plomp',
  'Mimic da Corridoio',
  'Mano Randagia',
  'Monaco del Silenzio',
  'Lama di Campana',
  'Custode di Chiavi',
  'Obser Vagante',
  'Falena del Fato',
  'Scheletro di Bosco',
  'Guardia Postea',
  'Ranocchio di Cenere',
  'Patalpa Selvatica',
  'Cervo di Specchio',
  'Spirito di Pane',
  'Guscio Gentile',
  'Topo Oculare',
  'Corvo Senza Becco',
];

const List<String> _horrorMonsterBodies = [
  'Uomo delle Scale',
  'Sorriso Rosso',
  'Cane Senza Sonno',
  'Capra dei Bui',
  'Carne del Voto',
  'Santo Muto',
  'Occhio della Cameretta',
  'Ragno Ossa-Filo',
  'Fauce di Corridoio',
  'Mascella Bianca',
  'Burattino delle Mani',
  'Testimone del Nulla',
  'Torace Aperto',
  'Figura del Letto',
  'Teschio con Coda',
  'Angelo Contratto',
];

const List<String> _monsterAspects = [
  'di Rame',
  'di Cenere',
  'della Palude',
  'di Vetro',
  'di Filo',
  'del Sottoscala',
  'di Muschio',
  'del Campanile',
  'della Fame Dolce',
  'del Rumore Basso',
  'del Primo Piano',
  'dell Occhio Quieto',
  'della Lanterna Spenta',
  'di Postea',
  'della Chiave Morsa',
  'del Bosco Rosso',
  'del Latte Nero',
  'della Pioggia Ferma',
];

const List<String> _monsterElements = [
  'fisico',
  'oscuro',
  'sangue',
  'osso',
  'natura',
  'acqua',
  'ruggine',
  'cristallo',
  'cenere',
  'psichico',
  'sonoro',
  'vuoto',
  'slime',
  'fulmine',
  'gelo',
  'fuoco',
  'metallo',
  'specchio',
];

List<MonsterBookEntry> _withFallbackMonsterSkills(
  List<MonsterBookEntry> entries,
) {
  return [
    for (final monster in entries)
      monster.skillIds.isNotEmpty
          ? monster
          : MonsterBookEntry(
              id: monster.id,
              nameIt: monster.nameIt,
              nameEn: monster.nameEn,
              descIt: monster.descIt,
              descEn: monster.descEn,
              elementId: monster.elementId,
              spriteAssetPath: monster.spriteAssetPath,
              imageBase64: monster.imageBase64,
              isMiniBoss: monster.isMiniBoss,
              isBoss: monster.isBoss,
              isNpc: monster.isNpc,
              isNullFateless: monster.isNullFateless,
              stats: monster.stats,
              skillIds: _skillIdsForGeneratedMonster(
                monster.id,
                monster.elementId,
              ),
              dropIds: monster.dropIds.isEmpty
                  ? _dropIdsForGeneratedMonster(monster.id, monster.elementId)
                  : monster.dropIds,
              canWieldWeapons: monster.canWieldWeapons,
              weaponTags: monster.weaponTags,
              armorTags: monster.armorTags,
            ),
  ];
}

List<MonsterBookEntry> _generateMonsterTier({
  required int count,
  required _GeneratedMonsterTier tier,
}) {
  if (count <= 0) return const [];
  return [for (var i = 0; i < count; i++) _generatedMonsterEntry(i, tier)];
}

MonsterBookEntry _generatedMonsterEntry(int index, _GeneratedMonsterTier tier) {
  final horror = tier != _GeneratedMonsterTier.normal || index % 5 == 3;
  final peaceful = tier == _GeneratedMonsterTier.normal && index % 11 == 8;
  final bodyPool = horror ? _horrorMonsterBodies : _baseMonsterBodies;
  final body = bodyPool[index % bodyPool.length];
  final aspect =
      _monsterAspects[(index * 5 + tier.index * 3) % _monsterAspects.length];
  final element =
      _monsterElements[(index * 7 + tier.index * 4) % _monsterElements.length];
  final tierPrefix = switch (tier) {
    _GeneratedMonsterTier.normal => 'Mostro',
    _GeneratedMonsterTier.miniBoss => 'Mini Boss',
    _GeneratedMonsterTier.boss => 'Boss',
  };
  final idPrefix = switch (tier) {
    _GeneratedMonsterTier.normal => 'generated_normal',
    _GeneratedMonsterTier.miniBoss => 'generated_miniboss',
    _GeneratedMonsterTier.boss => 'generated_boss',
  };
  final id = '${idPrefix}_${(index + 1).toString().padLeft(3, '0')}';
  final nameIt = peaceful
      ? '$body Pacifico $aspect'
      : tier == _GeneratedMonsterTier.normal
      ? '$body $aspect'
      : '$tierPrefix - $body $aspect';
  final nameEn = nameIt;
  final hpBase = switch (tier) {
    _GeneratedMonsterTier.normal => 70 + index * 3,
    _GeneratedMonsterTier.miniBoss => 220 + index * 5,
    _GeneratedMonsterTier.boss => 460 + index * 9,
  };
  final atkBase = switch (tier) {
    _GeneratedMonsterTier.normal => 13 + index % 18,
    _GeneratedMonsterTier.miniBoss => 34 + index % 24,
    _GeneratedMonsterTier.boss => 58 + index % 34,
  };
  final defBase = switch (tier) {
    _GeneratedMonsterTier.normal => 5 + index % 14,
    _GeneratedMonsterTier.miniBoss => 18 + index % 18,
    _GeneratedMonsterTier.boss => 32 + index % 28,
  };
  final spdBase = switch (tier) {
    _GeneratedMonsterTier.normal => 7 + index % 9,
    _GeneratedMonsterTier.miniBoss => 6 + index % 8,
    _GeneratedMonsterTier.boss => 5 + index % 10,
  };
  final canWield =
      body.contains('Goblin') ||
      body.contains('Orco') ||
      body.contains('Bandito') ||
      body.contains('Cavaliere') ||
      body.contains('Arciere') ||
      body.contains('Mago') ||
      body.contains('Guardia') ||
      body.contains('Lama');
  final weapon = body.contains('Arciere')
      ? 'arco'
      : body.contains('Mago')
      ? 'bastone'
      : body.contains('Goblin')
      ? 'coltello'
      : body.contains('Orco')
      ? 'mazza'
      : canWield
      ? 'lama'
      : '';
  final armor = tier == _GeneratedMonsterTier.boss
      ? 'reliquia'
      : tier == _GeneratedMonsterTier.miniBoss
      ? 'corazza'
      : canWield
      ? 'cuoio'
      : '';
  final descIt = peaceful
      ? '$nameIt e una creatura errante non ostile: osserva, annusa la luce dell Oculum e combatte solo se spinta. Skill: ${_skillLabel(element, 0)}, ${_skillLabel(element, 1)}, ${_skillLabel(element, 2)}.'
      : '$nameIt e un $tierPrefix affine a $element. Il suo comportamento resta coerente: usa corpo, ambiente e poteri legati al proprio elemento, senza effetti fuori tema. Skill: ${_skillLabel(element, 0)}, ${_skillLabel(element, 1)}, ${_skillLabel(element, 2)}.';
  final descEn = descIt;
  return MonsterBookEntry(
    id: id,
    nameIt: nameIt,
    nameEn: nameEn,
    descIt: descIt,
    descEn: descEn,
    elementId: element,
    spriteAssetPath: 'assets/oculum_dungeon/generated_sprites/enemies/$id.png',
    isMiniBoss: tier == _GeneratedMonsterTier.miniBoss,
    isBoss: tier == _GeneratedMonsterTier.boss,
    isNullFateless: element == 'vuoto' && tier == _GeneratedMonsterTier.boss,
    stats: {'hp': hpBase, 'atk': atkBase, 'def': defBase, 'spd': spdBase},
    skillIds: _skillIdsForGeneratedMonster(id, element),
    dropIds: _dropIdsForGeneratedMonster(id, element),
    canWieldWeapons: canWield,
    weaponTags: weapon.isEmpty ? const [] : [weapon],
    armorTags: armor.isEmpty ? const [] : [armor],
  );
}

List<String> _skillIdsForGeneratedMonster(String id, String element) {
  final safe = id.replaceAll('-', '_');
  final elem = element.replaceAll('-', '_');
  return [
    '${safe}_${elem}_strike',
    '${safe}_${elem}_guard',
    '${safe}_${elem}_field',
  ];
}

List<String> _dropIdsForGeneratedMonster(String id, String element) {
  final safe = id.replaceAll('-', '_');
  final elem = element.replaceAll('-', '_');
  return ['${safe}_${elem}_shard', '${safe}_token_art'];
}

String _skillLabel(String element, int slot) {
  final clean = element.trim().isEmpty ? 'fisico' : element;
  return switch (slot) {
    0 => 'Colpo $clean',
    1 => 'Guardia $clean',
    _ => 'Campo $clean',
  };
}

MonsterBookEntry? monsterById(String id) {
  try {
    return monsterBookEntries.firstWhere((e) => e.id == id);
  } catch (_) {
    return null;
  }
}

int monsterSpriteStableSeed(String text) {
  var hash = 5381;
  for (final code in text.codeUnits) {
    hash = ((hash << 5) + hash + code) & 0x7fffffff;
  }
  return hash;
}

int monsterSpriteVariantCount(String monsterId) {
  final seed = monsterSpriteStableSeed(monsterId);
  if (seed % 11 == 0) return 2;
  if (seed % 3 == 0 || seed % 7 == 0) return 1;
  return 0;
}

String monsterSpriteVariantAssetPath(String basePath, int variant) {
  if (variant <= 0 || !basePath.endsWith('.png')) return basePath;
  return basePath.replaceFirst('.png', '_variant_$variant.png');
}

List<String> monsterSpriteAssetPaths(MonsterBookEntry monster) {
  return [
    monster.spriteAssetPath,
    for (
      var variant = 1;
      variant <= monsterSpriteVariantCount(monster.id);
      variant++
    )
      monsterSpriteVariantAssetPath(monster.spriteAssetPath, variant),
  ];
}

String monsterSpriteAssetFor(MonsterBookEntry monster, {int seed = 0}) {
  final paths = monsterSpriteAssetPaths(monster);
  if (paths.length <= 1) return monster.spriteAssetPath;
  final index =
      (monsterSpriteStableSeed(monster.id) + seed).abs() % paths.length;
  return paths[index];
}

/// Hints di layout utili per futuri widget.
class MonsterBookLayoutHints {
  static const double defaultSpriteSize = 140;
  static const double mobileSpriteSize = 96;
}
