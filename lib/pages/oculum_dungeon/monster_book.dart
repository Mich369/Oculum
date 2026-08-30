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
        'Tipo Slime, livello 1/9, Senza Grado. Creatura semplice ma non vuota: lo Slime Blu usa il corpo per aprire spazio o proteggere varianti più forti. Con 20 Slime Skin, il colpo finale consente un tiro DT 18+ invece dell’impossibile. Titolo Slime Skin: +2 Resilienza, punto cieco danni da fuoco ×3. Drop: 1d20 g di slime.',
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
        'Slime Blu con Elmetto: variante che prende iniziativa e primo attacco quando nasce dalla Mother Slime. Non ripete il normale Slime Blu: assorbe i colpi deboli, protegge il branco e può essere chiamato dalle skill degli slime maggiori.',
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
        'Talpa patata malvagia. Base: Resilienza 15, Volontà 3, Materia 15. Generazione spende 1 azione e 10 Oculum per richiamare una Patalpa con le statistiche della più debole, senza Generazione (cooldown 10 turni). Palata: con critico applica Stun pari al critico e +2 danni × livello (cooldown 3). Rigenerazione: si interra a metà, raddoppia CM ma non tira e recupera 25% HP a turno (cooldown 2). Drop: Patalpa Dolce 250 g, cibo 2/1, +1 a tutte le stat per un’ora; con critico Pala del Patalpa Dolce (+4 VC, Palata, -2 Percezione).',
    descEn:
        'A potato mole. Generation spends an action and Oculum to summon a Sweet Patalpa using the weakest one’s stats.',
    elementId: 'flora',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/patalpa_dolce.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 150, 'atk': 24, 'def': 18, 'spd': 9},
    skillIds: [
      'patalpa_generazione',
      'patalpa_palata',
      'patalpa_rigenerazione',
    ],
    dropIds: ['patalpa_dolce_250g', 'pala_patalpa_dolce'],
  ),
  MonsterBookEntry(
    id: 'shadow_mimic',
    nameIt: 'Shadow Mimic',
    nameEn: 'Shadow Mimic',
    descIt:
        'Tipo Shadow, livello 0/40, Senza Grado/I/III. Shadow Eye apre un occhio per azioni Oculum e abbassa statistiche, con svantaggi ogni tre azioni; Magic Item estrae un oggetto utile che scala sugli Oculum immessi; Teletrasporto Tenebroso cerca la schiena e ignora il tiro salvo critico negativo. Il suo ultimate non copia il Rock Rhino: crea una Carica d’Ombra che attraversa le linee e lascia il bersaglio esposto. Con 20 Item Casuale: tiro DT 18+; titolo con +3 a una stat decisa dal Fato e punto cieco roleplay.',
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
        'Mostro errante Mini-Boss, livello 10/110, Grado I/V/X. Forma giovane dell’Incubo: Raggio Penetrante, Resistenza fisica e Pestone Esplosivo. Drop: scarti di carne, ossa e Cuore di Incubo giovane. Con 1/5 Maledizione dell’Incubo senza Risveglio, il colpo finale apre un tiro DT 18+; titolo Prima o poi Tornerà.',
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
        'Boss errante, livello 10/110, Grado V/X. Raggio Penetrante arriva a Oculum ×2 e segue i bersagli; Resistenza diventa quasi impenetrabile; Pestone Esplosivo cresce contro la difesa. A metà Vita, al livello 95, ottiene 5000 Scudo e Scudo di Salvataggio. Titolo assicurato da Grado V: Uccisore di un vero Incubo senza Risveglio; non può convivere con la Maledizione.',
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
        'Costrutto di Terra, livello 1/40, Senza Grado/I/III. Carica Devastante usa gli Oculum immessi e diventa difficile da bloccare; Scatto Arretrante protegge e prepara la carica successiva; Scatto Roccioso alza spuntoni. Ultimate Carica Finale: aura rocciosa che spinge e può arrivare a Oculum ×4 contro una parete. Con 20 Occhio di Rock Rhino: tiro DT 18+. Titolo Possessore dell’Occhio della Terra: +1 Volontà, +6 contro roccia/fango/terra; punto cieco +1 Volontà ai mostri d’acqua contro di te. Drop baby/adulto: Roccia e Core Rotto.',
    descEn:
        'Earth Construct. Rocky charge, high defense and compact dark-fantasy JRPG body.',
    elementId: 'earth',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/rock_rhino.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 160, 'atk': 25, 'def': 24, 'spd': 5},
    skillIds: ['devastating_charge', 'backward_dash', 'rocky_dash'],
    dropIds: ['roccia_500g', 'core_rotto', 'occhio_rock_rhino'],
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
        'Rettile Gigante, livello 10/30, Grado I/II/V. Carica Devastante usa gli Oculum immessi, diventa impossibile da bloccare senza almeno il doppio del suo livello e al grado alto raddoppia i danni. Scatto Arretrante protegge e raddoppia la Carica successiva; Scatto Immateriale concede +3/+10/+15 Materia. Ultimate Carica Finale: aura rossa, Oculum ×3 o ×4 contro una parete. Con 20 Forest Demon Weapon: tiro DT 18+. Titoli: Dirty Forest Demon Killer e Heavy Horn. Drop adulto: carne, scarti e Ossa Dure.',
    descEn:
        'Giant forest reptile. Devastating Charge, Backward Dash and Immaterial Dash make it a mobile bruiser.',
    elementId: 'natura',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/forest_demon.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 190, 'atk': 34, 'def': 18, 'spd': 12},
    skillIds: ['devastating_charge', 'backward_dash', 'immaterial_dash'],
    dropIds: ['carne_forest_demon', 'scarti_carne', 'ossa_dure', 'heavy_horn'],
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
        'Mini-Boss Slime, livello 9/100, Senza Grado/IV/IX. Tornado Slime usa la sfera volante per dare svantaggio e area; Schianto del Re cresce a Oculum ×2 con Stun; Spadata del Re Slime passa da 1d3 a 1d6 colpi. È un duellante che prepara il campo al Re, non il Re in miniatura.',
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
        'Boss Slime, livello 9/100, Grado IV/IX. Armata Slime crea slime blu davanti a sé: ogni evocato morto gli restituisce 1 Oculum. Con 20 Corona del Re Slime: tiro DT 18+. Titolo Re Slime: +2 Materia, +4 contro slime e possibilità di addomesticare al massimo due slime in fin di Vita; punto cieco fuoco ×2 e Ustionato dura 1 azione in più. Drop: 1d100×10 slime, fino a 1d100×100.',
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

/// Creature consegnate dal manuale. Le descrizioni restano volutamente
/// leggibili e modificabili dal Monster Book: conservano soglie, drop e parti
/// narrative invece di ridurle a tre attacchi generici.
const List<MonsterBookEntry> _manualMonsterBookEntries = [
  MonsterBookEntry(
    id: 'mini_fate_golem',
    nameIt: 'Mini Fate Golem',
    nameEn: 'Mini Fate Golem',
    descIt:
        'Costrutto, livello 2/40, Senza Grado/I/III. Guardia mobile: Fata della Protezione reagisce ai colpi al centro del petto con 1/4 del danno del proprietario; a livello 15 la fata può trasformarsi e potenziarlo. Lancia Materia scala da Oculum a Oculum x2 e poi stordisce; Colpo Potenziato scaglia il bersaglio. Se il proprietario è di livello superiore, la fata raddoppia l’Oculum ricevuto. Drop: 1d3 Roccia scadente da 500 g.',
    descEn: 'Fate construct.',
    elementId: 'terra',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 95, 'atk': 18, 'def': 16, 'spd': 8},
    skillIds: ['fate_fairy_protection', 'matter_lance', 'enhanced_blow'],
    dropIds: ['roccia_scadente_500g'],
  ),
  MonsterBookEntry(
    id: 'fate_golem',
    nameIt: 'Fate Golem',
    nameEn: 'Fate Golem',
    descIt:
        'Costrutto adulto, livello 2/40, Grado I/III. Non è solo una versione con più vita: usa la fata come scudo reattivo e il terreno come munizione. Se la Fata della Protezione viene spezzata, combatte contro il suo stesso golem e lo distrugge. Drop: 1d6+4 Roccia scadente da 500 g.',
    descEn: 'Adult fate construct.',
    elementId: 'terra',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 260, 'atk': 34, 'def': 32, 'spd': 6},
    skillIds: ['fate_fairy_awaken', 'matter_lance_iii', 'enhanced_blow_iii'],
    dropIds: ['roccia_scadente_500g'],
  ),
  MonsterBookEntry(
    id: 'baby_rock_rhino',
    nameIt: 'Baby Rock Rhino',
    nameEn: 'Baby Rock Rhino',
    descIt:
        'Costrutto livello 1/40, Senza Grado. Giovane ariete di pietra: Carica Devastante, Scatto Arretrante difensivo e Scatto Roccioso. Impara presto a concatenare ritirata e carica. Drop: 1d3 Roccia da 500 g e 1 Core Debole Rotto.',
    descEn: 'Young rock construct.',
    elementId: 'terra',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 75, 'atk': 14, 'def': 15, 'spd': 11},
    skillIds: ['devastating_charge_i', 'backward_dash_i', 'rocky_dash_i'],
    dropIds: ['roccia_500g', 'core_debole_rotto'],
  ),
  MonsterBookEntry(
    id: 'mother_slime',
    nameIt: 'Mother Slime',
    nameEn: 'Mother Slime',
    descIt:
        'Mini-Boss/Boss slime rosa nato da uno Slime Blu, livello 9/36. My Death: A Birth lascia eredi alla morte; Liquidation afferra e chiede un tiro di Resilienza ad alta DT, altrimenti drena Oculum e Resilienza; Offspring genera piccoli slime a intervalli. Sotto metà Vita aumenta danni e difesa per gli slime in campo × Grado. Le evocazioni danno al massimo +10 EXP. Drop: Slime 10 kg, raro Nucleo Slime autoriparante.',
    descEn: 'Slime matriarch.',
    elementId: 'slime',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 330, 'atk': 39, 'def': 25, 'spd': 7},
    skillIds: [
      'my_death_a_birth',
      'slime_liquidation_grab',
      'offspring_save_me',
    ],
    dropIds: ['slime_10kg', 'nucleo_slime_autoriparante'],
  ),
  MonsterBookEntry(
    id: 'mammut_corazzato',
    nameIt: 'Mammut Corazzato',
    nameEn: 'Armored Mammoth',
    descIt:
        'Mammifero Grado I/IV/X. Tank da linea: Resistenza di un Corazzato riduce tutti i danni, Pestone di Ghiaccio alza inseguitori gelati e Carica del Mammut accumula Oculum per ogni metro, moltiplicandolo quando colpisce. Drop: Zanne, Metallo runico e 10/50 kg di carne.',
    descEn: 'Armored mammoth.',
    elementId: 'gelo',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 420, 'atk': 46, 'def': 42, 'spd': 8},
    skillIds: ['armored_resistance', 'ice_stomp', 'mammoth_charge'],
    dropIds: ['zanne_mammut', 'metallo_runico', 'carne_mammut'],
  ),
  MonsterBookEntry(
    id: 'idrax',
    nameIt: 'Idrax',
    nameEn: 'Idrax',
    descIt:
        'Serpente gigante livello 0. Quando subisce troppo danno può fare Muta: rigenera la parte eccedente ma perde 3 cm per un turno. Non cerca uno scontro frontale, alterna pelle, fuga e ritorno. Stat base: Resilienza 3, Volontà 5, Materia 5. Drop: 1d4 kg Pelle di serpente, Carne di Idrax 250 g (putrefazione 3 sessioni).',
    descEn: 'Giant shedding serpent.',
    elementId: 'natura',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 70, 'atk': 16, 'def': 9, 'spd': 17},
    skillIds: ['idrax_molt', 'serpent_coil', 'burrow_escape'],
    dropIds: ['pelle_serpente', 'carne_idrax'],
  ),
  MonsterBookEntry(
    id: 'notthing',
    nameIt: 'Notthing',
    nameEn: 'Notthing',
    descIt:
        'Tipo ???, Senza Grado/V/X. Appare solo in situazioni legate al Niente; ogni scontro viene dimenticato e le sue skill sono scelte dal Fato, non da un kit fisso. Stat base: Resilienza 9, Volontà 5, Materia 30, Null 10.',
    descEn: 'Thing of nothing.',
    elementId: 'vuoto',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: true,
    stats: {'hp': 190, 'atk': 31, 'def': 18, 'spd': 15},
    skillIds: [
      'nothing_random_fate_skill',
      'forgotten_encounter',
      'null_shift',
    ],
    dropIds: ['null_echo'],
  ),
  MonsterBookEntry(
    id: 'ciclope_del_fato',
    nameIt: 'Ciclope del Fato',
    nameEn: 'Fate Cyclops',
    descIt:
        'Umanoide neutrale, Senza Grado/IV/IX. Attacco di Fortuna può dare +200/+300/+600% danni ma lo sbilancia se il dado non raggiunge la soglia. Difesa del Fato e Raggio Oculare lo rendono un duellante che punisce Oculum. Non è ostile senza motivo.',
    descEn: 'Neutral fate cyclops.',
    elementId: 'oculum',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 230, 'atk': 35, 'def': 26, 'spd': 9},
    skillIds: ['fate_attack', 'fate_defense', 'ocular_ray'],
    dropIds: ['occhio_del_fato'],
  ),
  MonsterBookEntry(
    id: 'odor_ferroso_undead',
    nameIt: 'Odor Ferroso',
    nameEn: 'Ferrous Odor Undead',
    descIt:
        'Non morto livello 10/110, Grado I/V/X. Si annuncia con ferro e pianto di bambini; segue sangue in cimiteri ed edifici vuoti. Lancio del Feto applica penalità al tiro e può creare sciami; Artiglio Spettrale taglia da lontano; Il Putrido esplode in Putridume e Veleno a metà Vita. Apertura: sciame di 100 ragnetti come un solo mostro. Drop: Testa di bambino morto, carne putrida; raro Amuleto anti Putrido e Veleno.',
    descEn: 'Ferrous undead.',
    elementId: 'necrotico',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 390, 'atk': 48, 'def': 25, 'spd': 14},
    skillIds: ['fetal_throw', 'spectral_claw', 'the_putrid'],
    dropIds: ['testa_bambino_morto', 'carne_putrida', 'amuleto_anti_putrido'],
  ),
  MonsterBookEntry(
    id: 'leafly',
    nameIt: 'Leafly',
    nameEn: 'Leafly',
    descIt:
        'Creatura vegetale che cresce davvero: a ogni livello riceve 12 punti statistica. Base: Resilienza 15, Volontà 10, Materia 10, +3 danno e +5 difesa. È una sentinella in crescita, non un altro predatore generico.',
    descEn: 'Growing leaf creature.',
    elementId: 'natura',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 150, 'atk': 13, 'def': 15, 'spd': 10},
    skillIds: ['leafly_growth', 'root_guard', 'leaf_cut'],
    dropIds: ['foglia_viva'],
  ),
  MonsterBookEntry(
    id: 'mutant_fungus',
    nameIt: 'Mutant Fungus',
    nameEn: 'Mutant Fungus',
    descIt:
        'Neutrale, non possiede Oculum e vede attraverso i suoni. Non insegue il rumore a caso: mappa vibrazioni, tende agguati e perde efficacia nel silenzio. Drop: Funghi Mutanti 5/1.',
    descEn: 'Sound-seeing fungus.',
    elementId: 'fungo',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 105, 'atk': 19, 'def': 17, 'spd': 5},
    skillIds: ['sound_sight', 'spore_alarm', 'mycelium_guard'],
    dropIds: ['funghi_mutanti'],
  ),
  MonsterBookEntry(
    id: 'psycho_funginius',
    nameIt: 'PsychoFunginius',
    nameEn: 'PsychoFunginius',
    descIt:
        'Senza Grado/I/II. La sua presenza porta 1 Follia, anche se si fugge. Mix di Illusioni manda copie con una sola vera; Scomparire evita i tiri bassi; Percezione dei Pericoli gli dà vantaggio passivo. Apertura al livello 15: Gas Allucinogeno due volte a sessione, dimezza difese per 5 turni; poi +5 alle stat e +9 ai tiri. Drop: Funghi allucinogeni; raro Nettare.',
    descEn: 'Hallucinatory fungus.',
    elementId: 'psichico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 135, 'atk': 28, 'def': 12, 'spd': 13},
    skillIds: ['mix_illusioni', 'scomparire', 'percezione_pericoli'],
    dropIds: ['funghi_allucinogeni', 'nettare_psycho'],
  ),
  MonsterBookEntry(
    id: 'mavic',
    nameIt: 'Mavic',
    nameEn: 'Mavic',
    descIt:
        'Senza Grado/I/III. Cieco, ma sente anche una traccia minima di Oculum o Grado grazie alle pietre. Ormai sei mio marca il bersaglio; Taglio ad X cresce con Volontà; Percezione dei Pericoli lo rende prudente. Apertura livello 20: Vista Cieca, vantaggio Oculum per il fight e scavo di materiale o magia. Drop: Artiglio di Mavic; raro Pietra Mavic funzionante.',
    descEn: 'Blind Oculum hunter.',
    elementId: 'oculum',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 145, 'atk': 31, 'def': 16, 'spd': 15},
    skillIds: ['ormai_sei_mio', 'taglio_ad_x', 'mavic_blind_sight'],
    dropIds: ['artiglio_mavic', 'pietra_mavic'],
  ),
  MonsterBookEntry(
    id: 'gabli_caverne',
    nameIt: 'Gabli delle Caverne',
    nameEn: 'Cave Gabli',
    descIt:
        'Senza Grado/I/II. Vedono fonti minime di Oculum. Attacco a Palla passa nelle aperture e converte Materia/Volontà; Cacciatore in Gruppo cresce con il branco; Pianto richiama un Gabli più forte o diventa l’Urlo dell’adulto. Apertura: uovo con 1d10 Gabli a metà stat. Drop: carne prelibata, raro Uovo di Gabli e +3 Oculum temporanei.',
    descEn: 'Cave pack creature.',
    elementId: 'caverna',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 90, 'atk': 17, 'def': 10, 'spd': 14},
    skillIds: ['gabli_ball_attack', 'pack_hunter', 'gabli_cry'],
    dropIds: ['carne_gabli', 'uovo_gabli', 'oculum_temporaneo'],
  ),
  MonsterBookEntry(
    id: 'dooca',
    nameIt: 'Dooca',
    nameEn: 'Dooca',
    descIt:
        'Neutrale, Senza Grado/I/II. Raccoglie cose scintillanti e non combatte per forza. Armi Artigianali migliora le armi, Osso Duro difende dai colpi, Percezione dei Pericoli evita imboscate. Apertura livello 15: Richiamo di due Dooca alleati; Evocazione Istantanea crea un colpo con coltello d’osso. Drop: Ingranaggi scintillanti; raro Coltello Dissacrante.',
    descEn: 'Neutral scavenger.',
    elementId: 'metallo',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 110, 'atk': 20, 'def': 18, 'spd': 12},
    skillIds: ['armi_artigianali', 'osso_duro', 'richiamo_dooca'],
    dropIds: ['ingranaggi_scintillanti', 'coltello_dissacrante'],
  ),
  MonsterBookEntry(
    id: 'terrore_sotterranei',
    nameIt: 'Terrore dei Sotterranei',
    nameEn: 'Underground Terror',
    descIt:
        'Grado I/III/VII. Predatore di massa: Sbranata del Terrore danneggia Resilienza e Volontà e porta Follia; Pelle Corazzata cresce fino a Impenetrabile; Non Scappi punisce la fuga con DT 15/25/45. Apertura livello 40: Raggio Distruttore. Drop: Pelle, Artiglio e raro Cristallo d’evocazione.',
    descEn: 'Underground pack terror.',
    elementId: 'oscuro',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 350, 'atk': 45, 'def': 35, 'spd': 18},
    skillIds: ['terror_maul', 'armored_hide', 'no_escape'],
    dropIds: ['pelle_terrore', 'artiglio_terrore', 'cristallo_terrore'],
  ),
  MonsterBookEntry(
    id: 'slime_roccioso',
    nameIt: 'Slime Roccioso',
    nameEn: 'Rocky Slime',
    descIt:
        'Senza Grado/I/II. I cuccioli attaccano tutto, gli adulti sono neutrali buoni. Palla di Roccia Slime crea blocchi con Vita Oculum ×3/×5; Rimbalzo prepara reazioni e danno; Indurimento converte Resilienza e Oculum in difesa. Apertura livello 15: Masso Slime. Drop: Roccia Slime 250 g.',
    descEn: 'Rock slime.',
    elementId: 'terra',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 145, 'atk': 23, 'def': 24, 'spd': 8},
    skillIds: ['rock_slime_ball', 'rock_slime_bounce', 'rock_slime_harden'],
    dropIds: ['roccia_slime'],
  ),
  MonsterBookEntry(
    id: 'ciclope_non_morto',
    nameIt: 'Ciclope Non Morto',
    nameEn: 'Undead Cyclops',
    descIt:
        'Grado I/II/III, ostile anche agli altri mostri e di solito in gruppi da 3/4. Base: Resilienza 15, Volontà 10, Materia 5, Oculum 0. Drop: Carne Marcia, Ascia rovinata rituale (+12 danni ma fragile); raro 1d6 Obser, con 20: 1d20+6 Obser e Occhio del Caduto se integro.',
    descEn: 'Hostile undead cyclops.',
    elementId: 'necrotico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 150, 'atk': 29, 'def': 16, 'spd': 7},
    skillIds: ['cyclops_axe', 'dead_eye', 'hostile_roar'],
    dropIds: ['carne_marcia', 'ascia_ciclope', 'obser'],
  ),
  MonsterBookEntry(
    id: 'grisfi',
    nameIt: 'Grisfi',
    nameEn: 'Grisfi',
    descIt:
        'Creatura pacifica usata come cavalcatura: corre al doppio del passo umano per 2 ore oppure cammina a 1,5× per 6 ore. Nel Book è una creatura sociale e di viaggio, non un nemico riciclato.',
    descEn: 'Peaceful mount.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 160, 'atk': 12, 'def': 14, 'spd': 25},
    skillIds: ['grisfi_sprint', 'grisfi_endurance', 'mount_bond'],
    dropIds: ['piuma_grisfi'],
  ),
  MonsterBookEntry(
    id: 'lumaca_pelosa_seta',
    nameIt: 'Lumaca Pelosa di Seta',
    nameEn: 'Hairy Silk Snail',
    descIt:
        'Creatura non ostile che produce seta luminosa del colore del guscio; alcune nascono con guscio non cobalto. È una risorsa viva: può essere curata, allevata o raccolta con attenzione.',
    descEn: 'Luminous silk snail.',
    elementId: 'seta',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 35, 'atk': 1, 'def': 8, 'spd': 1},
    skillIds: ['luminous_silk', 'shell_color', 'slow_hide'],
    dropIds: ['seta_luminosa'],
  ),
  MonsterBookEntry(
    id: 'verme_fondali',
    nameIt: 'Verme dei Fondali',
    nameEn: 'Deepground Worm',
    descIt:
        'Senza Grado/I/III. Percepisce tutto ciò che tocca il terreno anche a ore di distanza. Odia dividere la preda e può sfidare altri vermi: pressione sismica, imboscata dal sottosuolo e duello territoriale.',
    descEn: 'Deep sensing worm.',
    elementId: 'terra',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 210, 'atk': 32, 'def': 22, 'spd': 6},
    skillIds: ['ground_sense', 'deep_ambush', 'territory_duel'],
    dropIds: ['carne_verme', 'dente_verme'],
  ),
  MonsterBookEntry(
    id: 'dalatro',
    nameIt: 'Dalàtro',
    nameEn: 'Dalatro',
    descIt:
        'Livello 1/9. Innocuo finché non viene disturbato: lancia terra e fango, poi usa la coda per spostarsi rapidamente. È un incontro di ambiente, non un combattente da eliminare.',
    descEn: 'Harmless mud creature.',
    elementId: 'fango',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 45, 'atk': 6, 'def': 7, 'spd': 13},
    skillIds: ['mud_throw', 'tail_scoot', 'burrow_hide'],
    dropIds: ['fango_pulito'],
  ),
  MonsterBookEntry(
    id: 'polletto',
    nameIt: 'Polletto',
    nameEn: 'Little Chicken',
    descIt:
        'Animale affettuoso non ostile, Grado 0/X. Dice coccodè e diventa gigantesco crescendo di livello. Può essere un compagno, una scena comica o un problema di spazio, non un mostro aggressivo.',
    descEn: 'Affectionate growing chicken.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 20, 'atk': 2, 'def': 2, 'spd': 9},
    skillIds: ['coccodè', 'giant_growth', 'friendly_follow'],
    dropIds: ['piuma_polletto'],
  ),
  MonsterBookEntry(
    id: 'sharp',
    nameIt: 'Sharp',
    nameEn: 'Sharp',
    descIt:
        'Senza Grado, livello 0. Scava la roccia e vola con piccoli razzetti dietro la testa; l’aspetto inganna, perché è molto buono. Base: Resilienza 2, Volontà 6, Materia 10. Drop: Scarti metallici, Dente di Sharp; raro a 18+: Scroll Mangia Roccia o Scroll Volo Sfrecciante.',
    descEn: 'Kind rocket miner.',
    elementId: 'metallo',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 40, 'atk': 8, 'def': 9, 'spd': 20},
    skillIds: ['rock_eater', 'rocket_flight', 'kind_mining'],
    dropIds: ['scarti_metallici', 'dente_sharp', 'scroll_mangia_roccia'],
  ),
  MonsterBookEntry(
    id: 'ogle',
    nameIt: 'Ogle',
    nameEn: 'Ogle',
    descIt:
        'Creatura emotiva che ricorda un cane: si disperde in copie e stordisce con attacchi psico-illusivi. Base: Resilienza 1, Volontà 0, Materia 5. Drop: Occhi Illusivi.',
    descEn: 'Emotional illusion hound.',
    elementId: 'psichico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 35, 'atk': 9, 'def': 4, 'spd': 16},
    skillIds: ['ogle_split', 'psycho_bark', 'illusion_stun'],
    dropIds: ['occhi_illusivi'],
  ),
  MonsterBookEntry(
    id: 'lumin_gommoso',
    nameIt: 'Lumin Gommoso',
    nameEn: 'Rubbery Lumin',
    descIt:
        'Tenerone sociale: cerca cibo per la tana e lo condivide. In difesa lancia sfere gommose, fluttuanti e imprigionanti. Drop: Carne (putrefazione 3 sessioni); raro a 18+: Scroll Sfere Gommose.',
    descEn: 'Social rubbery lumin.',
    elementId: 'gomma',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 65, 'atk': 8, 'def': 14, 'spd': 10},
    skillIds: ['rubber_orb', 'food_share', 'floating_prison'],
    dropIds: ['carne_lumin', 'scroll_sfere_gommose'],
  ),
  MonsterBookEntry(
    id: 'topino_avventuroso',
    nameIt: 'Topino Avventuroso',
    nameEn: 'Adventurous Mouse',
    descIt:
        'Topino livello 1/9, Senza Grado, taglia minuscola. Fiaccolata aumenta il dado, Scatto Arretrante protegge e Cura Topesca aiuta tutto il party. Ultimate: Coltello Nascosto avvelenato. Drop: Fiaccola; con 20 Scroll Coltello Avvelenato.',
    descEn: 'Adventurous mouse.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 42, 'atk': 10, 'def': 5, 'spd': 18},
    skillIds: ['fiaccolata', 'topino_backstep', 'cura_topesca'],
    dropIds: ['fiaccola', 'scroll_coltello_avvelenato'],
  ),
  MonsterBookEntry(
    id: 'mosca_campana',
    nameIt: 'Mosca Campana',
    nameEn: 'Bell Fly',
    descIt:
        'Base: Resilienza 10, Volontà 10, Materia 5. Muove la campanella per infliggere Paralisi del Fato per quattro turni se non superi una DT molto difficile; con critico aggiunge Stun e cura gli alleati della propria Volontà. Drop 15: Polvere della Magia del Suono; drop 18: Campanella stordisci nemici.',
    descEn: 'Bell fly.',
    elementId: 'sonoro',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 80, 'atk': 15, 'def': 8, 'spd': 19},
    skillIds: ['bell_fate_paralysis', 'critical_stun', 'will_heal'],
    dropIds: ['polvere_magia_suono', 'campanella_stordente'],
  ),
  MonsterBookEntry(
    id: 'obra',
    nameIt: 'Obra',
    nameEn: 'Obra',
    descIt:
        'Branco Senza Grado/I. Nasce con un elemento su tiro DT 15: +6 danni, immunità al proprio elemento e Scudo Magico Oculum. Senza elemento, con DT 18 tira due frecce e usa Alta Resistenza non magica e Scudo Fisico Oculum. Ha una reazione in più a inizio turno e vantaggio quando difende qualcuno.',
    descEn: 'Protective elemental pack.',
    elementId: 'variabile',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 90, 'atk': 19, 'def': 13, 'spd': 14},
    skillIds: [
      'obra_element_birth',
      'obra_double_arrow',
      'obra_protective_reaction',
    ],
    dropIds: ['scudo_obra'],
  ),
  MonsterBookEntry(
    id: 'forest_rune_golem',
    nameIt: 'Forest Rune Golem',
    nameEn: 'Forest Rune Golem',
    descIt:
        'Boss Grado I/II/III, livello 12/20. Parte con 3 Scudi Oculum, 1 Azione Oculum e difesa pari a 3 × livello. Repulsione Runica spinge fino a d20+90 m; Pugno Distruttivo premia il colpo diretto; Dona Reazione modifica il turno degli altri invece di sommare danno. Immunità Natura.',
    descEn: 'Runic forest boss.',
    elementId: 'natura',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {'hp': 520, 'atk': 55, 'def': 48, 'spd': 5},
    skillIds: ['runic_repulsion', 'destructive_punch', 'grant_reaction'],
    dropIds: ['runa_foresta', 'cuore_golem'],
  ),
  MonsterBookEntry(
    id: 'baby_forest_demon',
    nameIt: 'Baby Forest Demon',
    nameEn: 'Baby Forest Demon',
    descIt:
        'Rettile Gigante, livello 1/10, Senza Grado/I. Versione giovane del Forest Demon: Carica Devastante scala da Oculum a Oculum ×2 e diventa difficile da bloccare; Scatto Arretrante protegge e prepara una Carica raddoppiata; Scatto Immateriale concede +3/+10/+15 Materia. Ultimate Carica Finale: aura rossa Oculum ×3, ×4 contro una parete. Con 20 Forest Demon Weapon: tiro DT 18+. Drop baby: 1d10 Carne da 250 g, 1d6 Scarti di Carne e 1d3 Ossa.',
    descEn: 'Young giant forest reptile.',
    elementId: 'natura',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 85, 'atk': 18, 'def': 11, 'spd': 14},
    skillIds: ['devastating_charge_i', 'backward_dash_i', 'immaterial_dash_i'],
    dropIds: ['carne_forest_demon', 'scarti_carne', 'ossa'],
  ),
  MonsterBookEntry(
    id: 'mistificatore_runico_natura',
    nameIt: 'Mistificatore Runico della Natura',
    nameEn: 'Runic Nature Trickster',
    descIt:
        'Tipo Altri, livello 10/150, Grado I/IV/IX. Riproduzione Animalesca copia una skill di un mostro del suo livello (cooldown 6), poi due skill di mostri diversi (5) e infine le richiama ogni 3 turni. Open Follia Pura: aura rossa che spinge e infligge Oculum ×3, ×4 contro una parete. È un adattatore che prende il ritmo del gruppo, non un secondo Forest Demon.',
    descEn: 'Runic nature trickster.',
    elementId: 'natura',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 310, 'atk': 42, 'def': 25, 'spd': 16},
    skillIds: [
      'riproduzione_animalesca',
      'follia_pura',
      'mistificazione_runica',
    ],
    dropIds: ['runa_natura', 'pelle_mistificatore'],
  ),
  MonsterBookEntry(
    id: 'bunnys',
    nameIt: 'Bunnys',
    nameEn: 'Bunnys',
    descIt:
        'Senza Grado/II/IV. Supporto di branco: alla morte cura il 50% della Vita degli alleati; Cura restituisce il 25% di salute spendendo Oculum pari al livello; Rinsecchito applica la condizione fisica se supera un tiro di Oculum o Resilienza. Non è un semplice nemico: va gestito prima che salvi tutto il gruppo.',
    descEn: 'Support rabbit creature.',
    elementId: 'natura',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 75, 'atk': 9, 'def': 11, 'spd': 15},
    skillIds: ['bunny_death_heal', 'bunny_heal', 'rinsecchito'],
    dropIds: ['pelo_bunny'],
  ),
  MonsterBookEntry(
    id: 'graga_rana_azzurra',
    nameIt: 'Graga Rana Azzurra',
    nameEn: 'Blue Graga Frog',
    descIt:
        'Piccola rana base 3/3/3. Non ha un kit ripetitivo: quando viene uccisa si fa esplodere, perciò va gestita a distanza o con attenzione al colpo finale.',
    descEn: 'Exploding blue frog.',
    elementId: 'acqua',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 30, 'atk': 12, 'def': 3, 'spd': 11},
    skillIds: ['graga_hop', 'death_explosion', 'water_hide'],
    dropIds: ['pelle_graga'],
  ),
  MonsterBookEntry(
    id: 'pesce_killer',
    nameIt: 'Pesce Killer',
    nameEn: 'Killer Fish',
    descIt:
        'Base: Resilienza 3, Volontà 6, Materia 5. Tira d4 coltellate: ogni coltellata successiva riduce del 25% il danno dell’azione. Drop: 1d4+1 Pesce da 500 g. Con 20: titolo Coltellino Veloce (+3 Materia, +2 Volontà, d4+1 coltellate ogni 2 turni; punto cieco: ogni coltellata riduce il danno del 25%).',
    descEn: 'Knife fish.',
    elementId: 'acqua',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 55, 'atk': 19, 'def': 7, 'spd': 18},
    skillIds: ['knife_flurry_d4', 'diminishing_stabs', 'fish_dash'],
    dropIds: ['pesce_500g', 'coltellino_veloce'],
  ),
  MonsterBookEntry(
    id: 'pesce_ascia',
    nameIt: 'Pesce Ascia',
    nameEn: 'Axe Fish',
    descIt:
        'Mini-Boss compatto. Base: Resilienza 6, Volontà 20, Materia 0. Non è rapido come il Pesce Killer: usa la Volontà per scegliere un singolo colpo pesante. Drop: 2 Occhi della Volontà; mangiarne uno rigenera 1 Volontà, oppure concede 1 punto temporaneo oltre il massimo finché non viene speso.',
    descEn: 'Axe fish miniboss.',
    elementId: 'acqua',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 180, 'atk': 35, 'def': 10, 'spd': 8},
    skillIds: ['axe_fin', 'will_current', 'deep_guard'],
    dropIds: ['occhio_della_volonta'],
  ),
  MonsterBookEntry(
    id: 'ranu',
    nameIt: 'Ranu',
    nameEn: 'Ranu',
    descIt:
        'Mostro pacifico e molto buono da mangiare. Quando si spaventa lancia la lattuga che lo riveste, resta nudo e scappa: è una scelta narrativa fra raccolta, fuga e cura della creatura.',
    descEn: 'Peaceful lettuce frog.',
    elementId: 'natura',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 28, 'atk': 1, 'def': 4, 'spd': 12},
    skillIds: ['lettuce_throw', 'naked_escape', 'gentle_croak'],
    dropIds: ['lattuga_ranu', 'carne_ranu'],
  ),
  MonsterBookEntry(
    id: 'pesce_alato_cromatico',
    nameIt: 'Pesce Alato Cromatico',
    nameEn: 'Chromatic Winged Fish',
    descIt:
        'Pesce pacifico dai colori cangianti. Serve a dare vita a fiumi e cieli: vola, cambia colore e guida verso acque sicure, senza trasformarsi in un incontro ostile gratuito.',
    descEn: 'Peaceful winged fish.',
    elementId: 'cromatico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 32, 'atk': 0, 'def': 3, 'spd': 22},
    skillIds: ['chromatic_flight', 'color_shift', 'safe_current'],
    dropIds: ['scaglia_cromatica'],
  ),
  MonsterBookEntry(
    id: 'fugra_rana_viola',
    nameIt: 'Fugra Rana Viola',
    nameEn: 'Purple Fugra Frog',
    descIt:
        'Rana ostile, base Resilienza 3, Volontà 1, Materia 0. Ogni attacco è velenoso: colpisce poco ma lascia una pressione da veleno, quindi non replica né l’esplosione della Graga né la fuga del Ranu. Drop: Sacca Velenosa, materiale.',
    descEn: 'Poison frog.',
    elementId: 'veleno',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 34, 'atk': 11, 'def': 3, 'spd': 14},
    skillIds: ['poison_tongue', 'violet_hop', 'toxic_hide'],
    dropIds: ['sacca_velenosa'],
  ),
  MonsterBookEntry(
    id: 'pesce_mutato',
    nameIt: 'Pesce Mutato',
    nameEn: 'Mutated Fish',
    descIt:
        'Base Resilienza 4, Volontà 5, Materia 6. Creatura adattata a scarichi e acque strane: cambia linea di nuoto e usa colpi irregolari invece di un semplice morso. Drop: 1d4+1 Pesce da 500 g.',
    descEn: 'Mutated fish.',
    elementId: 'mutazione',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 65, 'atk': 16, 'def': 9, 'spd': 15},
    skillIds: ['mutated_bite', 'erratic_swim', 'water_adaptation'],
    dropIds: ['pesce_500g'],
  ),
  MonsterBookEntry(
    id: 'pozzanghera_draconica',
    nameIt: 'Pozzanghera Draconica',
    nameEn: 'Draconic Puddle',
    descIt:
        'Anomalia draconica di terreno, non un normale slime: trattiene impronte, riflette scaglie e può cambiare il percorso della scena. Drop: Core Debole Rotto, materiale da 500 g.',
    descEn: 'Draconic terrain anomaly.',
    elementId: 'draconico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 80, 'atk': 14, 'def': 15, 'spd': 0},
    skillIds: ['draconic_splash', 'scale_reflection', 'puddle_snare'],
    dropIds: ['core_debole_rotto'],
  ),
  MonsterBookEntry(
    id: 'crosty',
    nameIt: 'Crosty',
    nameEn: 'Crosty',
    descIt:
        'Mostro pacifico dal guscio duro. È raccolta e commercio, non aggressione: può chiudersi, lasciare una corazza vecchia o seguire chi non lo minaccia. Drop: Corazza Crosty, materiale.',
    descEn: 'Peaceful shell creature.',
    elementId: 'crosta',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 60, 'atk': 1, 'def': 22, 'spd': 3},
    skillIds: ['crosty_shell', 'peaceful_hide', 'old_shell'],
    dropIds: ['corazza_crosty'],
  ),
  MonsterBookEntry(
    id: 'agla',
    nameIt: 'Agla',
    nameEn: 'Agla',
    descIt:
        'Base Resilienza 9, Volontà 1, Materia 0. Piccola creatura di fortuna: non ha un attacco dominante, ma porta un drop da 1d20 Obser e tende a fuggire se messa alle strette.',
    descEn: 'Obser-bearing creature.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 50, 'atk': 6, 'def': 6, 'spd': 13},
    skillIds: ['agla_scurry', 'obser_stash', 'small_bite'],
    dropIds: ['obser'],
  ),
  MonsterBookEntry(
    id: 'paffer_axolotl',
    nameIt: 'Paffer Axolotl con Guscio Appuntito',
    nameEn: 'Spiked-Shell Paffer Axolotl',
    descIt:
        'Mostro pacifico dal guscio appuntito. Si gonfia per difendersi senza inseguire, vive vicino all’acqua e può lasciare un guscio dopo una lunga cura o una muta naturale.',
    descEn: 'Peaceful spiked axolotl.',
    elementId: 'acqua',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'hp': 58, 'atk': 2, 'def': 18, 'spd': 7},
    skillIds: ['paffer_inflate', 'spiked_shell', 'water_rest'],
    dropIds: ['guscio_paffer'],
  ),
];

/// Porta il roster storico allo stile del manuale senza cambiare gli ID che
/// possono già comparire in campagne, salvataggi e copie online. Ogni profilo
/// indica cosa prova a fare in scena, così il Master non riceve più mostri
/// intercambiabili anche quando le skill restano personalizzabili.
List<MonsterBookEntry> _humanizeLegacyMonsterEntries(
  Iterable<MonsterBookEntry> entries,
) {
  return entries
      .map((entry) {
        if (entry.descIt.contains('Ruolo in scena:')) return entry;
        final role = _legacyMonsterRole(entry);
        final skills = entry.skillIds.isEmpty
            ? 'le sue tecniche personali'
            : entry.skillIds.take(3).join(', ');
        final drops = entry.dropIds.isEmpty
            ? 'drop da definire dal Master'
            : entry.dropIds.join(', ');
        final base = entry.descIt.trim();
        final addition =
            ' Ruolo in scena: $role. Lavora con $skills; i suoi drop restano $drops.';
        return entry.copyWith(
          descIt: '$base$addition',
          descEn: '$base$addition',
        );
      })
      .toList(growable: false);
}

String _legacyMonsterRole(MonsterBookEntry entry) {
  final name = entry.nameIt.toLowerCase();
  final element = entry.elementId.toLowerCase();
  final hp = entry.stats['hp'] ?? 0;
  final atk = entry.stats['atk'] ?? 0;
  final def = entry.stats['def'] ?? 0;
  final spd = entry.stats['spd'] ?? 0;
  if (entry.isBoss) {
    return 'regista dello scontro: apre una fase, cambia il terreno e costringe il gruppo a dividere le priorità';
  }
  if (entry.isMiniBoss) {
    return 'perno dell’incontro: protegge un punto debole del proprio gruppo e richiede una risposta precisa';
  }
  if (name.contains('slime') || name.contains('fung')) {
    return 'controllore adattivo: occupa spazio, sfrutta i resti e cambia valore se viene ignorato';
  }
  if (name.contains('cane') ||
      name.contains('ragno') ||
      (spd >= atk + 4 && spd >= def + 4)) {
    return 'cacciatore mobile: cerca il bersaglio isolato, entra rapido e si sposta prima della risposta';
  }
  if (def >= atk + 6 || hp >= 200) {
    return 'guardiano di linea: ferma i passaggi, copre un alleato e rende costoso colpirlo frontalmente';
  }
  if (element == 'sonoro' || element == 'psichico' || element == 'specchio') {
    return 'disturbatore: spezza concentrazione, reazioni o informazioni invece di inseguire solo i danni';
  }
  if (element == 'natura' || element == 'acqua') {
    return 'creatura di ambiente: usa terreno e posizione, lasciando spazio a trattativa o fuga quando coerente';
  }
  return 'opportunista: alterna pressione e difesa, cercando di non ripetere la stessa azione due turni di fila';
}

List<MonsterBookEntry> _withMonsterSkillNarration(
  Iterable<MonsterBookEntry> entries,
) => entries
    .map(
      (entry) => entry.copyWith(
        descIt:
            '${entry.descIt}\n\nSkill per il giocatore:\n${entry.skillIds.map(monsterBookSkillText).join('\n')}',
        descEn:
            '${entry.descEn}\n\nSkill per il giocatore:\n${entry.skillIds.map(monsterBookSkillText).join('\n')}',
      ),
    )
    .toList(growable: false);

/// Il Book non mostra più sigle tecniche come skill: ogni forma parla a chi la
/// usa. Le schede create dal giocatore possono comunque sostituire il testo.
String monsterBookSkillText(String rawId) {
  final id = rawId.replaceAll('_', ' ').trim();
  final label = id.isEmpty ? 'Tecnica del mostro' : id;
  switch (rawId.trim().toLowerCase()) {
    case 'solar_swarm':
      return 'solar swarm — I/dirigi un piccolo sciame solare contro un bersaglio o la casella vicina: lo pressa con più colpi leggeri e ne disturba la guardia; II/lo sciame raggiunge due bersagli vicini oppure continua a premere lo stesso bersaglio; III/chiudi il bersaglio in una corona di luce che lo colpisce ripetutamente, ma lo sciame resta esposto alle reazioni ad area fino al tuo turno successivo.';
    case 'golden_pin':
      return 'golden pin — I/lanci una spina d oro e armatura nera che ferisce e inchioda per un istante il bersaglio o un suo oggetto; II/aumenti la distanza oppure fissi due bersagli vicini, rendendo più difficile spostarsi o reagire; III/immobilizzi il bersaglio finché non si libera con un azione o un aiuto, ma la spina resta visibile e può essere spezzata.';
    case 'wing_flash':
      return 'wing flash — I/apri le ali dorate in un lampo: abbagli un bersaglio vicino e guadagni spazio per difenderti o riposizionarti; II/il lampo investe più bersagli vicini oppure protegge un alleato dalla prossima pressione; III/crei un bagliore accecante che interrompe le reazioni nella zona fino al turno successivo, ma rivela con chiarezza la tua posizione.';
  }
  bool hasAny(Iterable<String> terms) => terms.any(id.contains);
  if (hasAny(['guard', 'shield', 'shell', 'hide', 'skin', 'armor', 'cover'])) {
    return '$label — I/erigi una protezione che assorbe il prossimo colpo o copre un alleato; II/la barriera dura fino al tuo turno successivo e rende più costoso forzarla; III/respingi chi la attraversa, ma rinunci alla pressione offensiva mentre la mantieni.';
  }
  if (hasAny([
    'dash',
    'step',
    'hop',
    'sprint',
    'flight',
    'scurry',
    'swim',
    'escape',
    'vanish',
    'scomparire',
  ])) {
    return '$label — I/ti sposti rapidamente fuori dalla linea diretta o verso un bersaglio esposto; II/attraversi una zona minacciata oppure porti un alleato con te; III/scompari dalla pressione e riappari in posizione vantaggiosa, ma non puoi ripetere la stessa fuga nel turno seguente.';
  }
  if (hasAny([
    'heal',
    'regen',
    'rebirth',
    'birth',
    'growth',
    'molt',
    'reforge',
    'repair',
    'absolution',
  ])) {
    return '$label — I/recuperi una piccola parte delle forze oppure ricomponi una difesa danneggiata; II/il recupero aumenta o raggiunge anche un alleato vicino; III/torni in piena efficienza per un istante, ma lasci una finestra chiara per interromperti o colpirti.';
  }
  if (hasAny([
    'stun',
    'paralysis',
    'mute',
    'choke',
    'erase',
    'snare',
    'trip',
    'root',
    'coil',
    'prison',
    'drag',
    'tax',
    'mark',
    'pressure',
    'curse',
    'cut',
  ])) {
    return '$label — I/impedisci una risposta del bersaglio: lo rallenti, lo sbilanci o gli togli una reazione; II/il vincolo si estende a più bersagli vicini o dura fino al turno successivo; III/blocchi una scelta importante del bersaglio, ma l’effetto termina se un alleato interviene o supera la sua difesa.';
  }
  if (hasAny([
    'reveal',
    'sense',
    'sight',
    'eye',
    'gaze',
    'percezione',
    'map',
    'detect',
  ])) {
    return '$label — I/scopri posizione, difesa o punto debole di un bersaglio; II/condividi l’informazione con gli alleati o segui il bersaglio anche se si nasconde; III/esponi ogni apertura nella zona, ma anche la tua attenzione resta fissata lì e può essere aggirata.';
  }
  if (hasAny([
    'illusion',
    'mirror',
    'fake',
    'mistificazione',
    'reflect',
    'double',
    'color_shift',
    'invisible',
  ])) {
    return '$label — I/crei un inganno visivo che devia il prossimo attacco o la prossima reazione; II/l’inganno coinvolge più nemici oppure copia una minaccia già presente; III/costringe il bersaglio a scegliere tra immagini credibili, ma svanisce appena subisce un colpo netto o viene smascherato.';
  }
  if (hasAny([
    'summon',
    'swarm',
    'pack',
    'offspring',
    'slime_army',
    'richiamo',
    'pages',
  ])) {
    return '$label — I/chiami una piccola minaccia di supporto che occupa spazio e pressa il bersaglio; II/aumenti il numero oppure fai agire il branco su due lati; III/chiudi la zona con gli alleati evocati, ma ogni creatura aggiunta resta vulnerabile a effetti ad area.';
  }
  if (hasAny([
    'poison',
    'toxic',
    'putrid',
    'decay',
    'rot',
    'wound',
    'blood',
    'tear',
  ])) {
    return '$label — I/colpisci, ferisci e lasci un effetto corrosivo o sanguinante che continua a pesare sul bersaglio; II/il danno si propaga a un vicino o dura più a lungo; III/rendi la ferita una minaccia urgente, ma il bersaglio può fermarla con una cura o una difesa tempestiva.';
  }
  if (hasAny([
    'blast',
    'explosion',
    'swarm',
    'line',
    'splash',
    'tornado',
    'ball',
    'halo',
    'roar',
    'scream',
    'wail',
    'punch',
    'slam',
    'crash',
    'maul',
    'lance',
    'claw',
    'bite',
    'strike',
    'throw',
    'hammer',
    'axe',
    'fireball',
    'ray',
    'stabs',
    'flurry',
    'attack',
  ])) {
    return '$label — I/colpisci un bersaglio o la zona accanto con un attacco tematico; II/aumenti l’area, il numero dei colpi o la pressione su chi prova a difendersi; III/sferri il colpo decisivo che costringe il bersaglio a riposizionarsi, ma ti lascia scoperto se non va a segno.';
  }
  if (id.contains('charge') || id.contains('carica')) {
    return '$label — I/carichi il nemico usando gli Oculum immessi; II/aumenti l’impatto e rendi più difficile bloccarti; III/raddoppi il colpo oppure sfrutti un ostacolo.';
  }
  return '$label — I/canalizzi il tema della creatura per creare un vantaggio concreto contro il bersaglio vicino; II/trasformi quel vantaggio in pressione su più bersagli o in controllo della zona; III/ottieni una svolta forte nello scontro, ma devi dichiarare l’apertura che lasci agli avversari.';
}

final List<MonsterBookEntry> defaultMonsterBookEntries = List.unmodifiable(
  _withMonsterSkillNarration(
    _withFallbackMonsterSkills(
      _humanizeLegacyMonsterEntries([
        ..._craftedMonsterBookEntries,
        ..._manualMonsterBookEntries,
        ..._generateMonsterTier(
          count: targetNormalMonsterCount - _staticNormalMonsterCount,
          tier: _GeneratedMonsterTier.normal,
        ),
        ..._generateMonsterTier(
          count: targetMiniBossMonsterCount - _staticMiniBossMonsterCount,
          tier: _GeneratedMonsterTier.miniBoss,
        ),
        ..._generateMonsterTier(
          count: targetBossMonsterCount - _staticBossMonsterCount,
          tier: _GeneratedMonsterTier.boss,
        ),
      ]),
    ),
  ),
);

List<MonsterBookEntry> _activeMonsterBookEntries = defaultMonsterBookEntries;
Map<String, MonsterBookEntry> _monsterBookEntriesById =
    <String, MonsterBookEntry>{
      for (final entry in defaultMonsterBookEntries) entry.id: entry,
    };

List<MonsterBookEntry> get monsterBookEntries => _activeMonsterBookEntries;

MonsterBookEntry? monsterBookEntryById(String id) =>
    _monsterBookEntriesById[id.trim()];

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
  _monsterBookEntriesById = <String, MonsterBookEntry>{
    for (final entry in _activeMonsterBookEntries) entry.id: entry,
  };
}

void resetMonsterBookEntries() {
  _activeMonsterBookEntries = defaultMonsterBookEntries;
  _monsterBookEntriesById = <String, MonsterBookEntry>{
    for (final entry in defaultMonsterBookEntries) entry.id: entry,
  };
}

Iterable<MonsterBookEntry> get _staticMonsterBookEntries sync* {
  yield* _craftedMonsterBookEntries;
  yield* _manualMonsterBookEntries;
}

int get _staticNormalMonsterCount => _staticMonsterBookEntries
    .where((monster) => !monster.isMiniBoss && !monster.isBoss)
    .length;

int get _staticMiniBossMonsterCount =>
    _staticMonsterBookEntries.where((monster) => monster.isMiniBoss).length;

int get _staticBossMonsterCount =>
    _staticMonsterBookEntries.where((monster) => monster.isBoss).length;

enum _GeneratedMonsterTier { normal, miniBoss, boss }

/// Ogni creatura generata riceve un ruolo, non soltanto tre varianti dello
/// stesso colpo elementale. Il Master può vedere subito come usarla in scena.
enum _GeneratedMonsterRole {
  predatore,
  guardiano,
  controllore,
  branco,
  supporto,
  schermagliatore,
}

const List<String> _generatedRoleDescriptions = [
  'Predatore: sceglie chi è isolato, entra con un colpo breve e si ritira prima di essere circondato',
  'Guardiano: occupa spazio, protegge una zona o un alleato e costringe a cambiare bersaglio',
  'Controllore: sporca il terreno, interrompe le reazioni e crea una scelta scomoda invece di puntare solo al danno',
  'Branco: diventa pericoloso vicino ai suoi simili, alternando pressione e richiami',
  'Supporto: non cerca subito l’abbattimento; rinforza, cura poco o prepara la prossima azione di un alleato',
  'Schermagliatore: usa linee, coperture e movimento per colpire da un punto diverso ogni turno',
];

List<String> _generatedRoleSkillIds(
  String id,
  String element,
  _GeneratedMonsterRole role,
) {
  final safe = id.replaceAll('-', '_');
  final elem = element.replaceAll('-', '_');
  final roleId = role.name;
  return [
    '${safe}_${roleId}_${elem}_apertura',
    '${safe}_${roleId}_${elem}_pressione',
    '${safe}_${roleId}_${elem}_risposta',
  ];
}

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
  final role = _GeneratedMonsterRole
      .values[(index * 3 + tier.index) % _GeneratedMonsterRole.values.length];
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
  final roleDescription = _generatedRoleDescriptions[role.index];
  final descIt = peaceful
      ? '$nameIt è una creatura errante non ostile: osserva, annusa la luce dell Oculum e combatte solo se spinta. Invece di inseguire il danno, $roleDescription.'
      : '$nameIt è un $tierPrefix affine a $element. $roleDescription. Le sue tre skill usano corpo, ambiente e $element senza uscire dal suo tema.';
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
    skillIds: _generatedRoleSkillIds(id, element, role),
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
