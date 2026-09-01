import 'dart:math';

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

  /// Oggetti reali ottenuti quando questo mostro viene creato come scheda.
  /// Restano dati del Book, non cambiano il formato dei salvataggi esistenti.
  final List<Map<String, dynamic>> inventoryItems;

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
    this.inventoryItems = const [],
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
    List<Map<String, dynamic>>? inventoryItems,
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
      inventoryItems: inventoryItems ?? this.inventoryItems,
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
      'inventoryItems': inventoryItems
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false),
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
      inventoryItems: _monsterBookMaps(
        json['inventoryItems'] ?? json['inventory'],
      ),
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

List<Map<String, dynamic>> _monsterBookMaps(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList(growable: false);
}

/// Dati stabili dei mostri usati nel minigioco.
///
/// I PNG potrebbero non esistere ancora: in UI/painter deve essere sempre
/// presente un fallback (non crashare).
const List<MonsterBookEntry> _craftedMonsterBookEntries = [
  MonsterBookEntry(
    id: 'demone_minore',
    nameIt: 'Demone Minore',
    nameEn: 'Lesser Demon',
    descIt:
        'Classe Mini Boss, livello 0, Senza Grado. Privo di logica: è pura forza e difesa. Base: Resilienza 3, Volontà 20, Materia 9, Oculum 20, Difesa 120. Usa l’Oculum soltanto per corazzare il corpo o rendere più brutale il prossimo colpo. Ruolo in scena: ariete difensivo che avanza senza trattare.',
    descEn:
        'Mini-boss, level 0, no Grade. A mindless wall of force that spends Oculum only to harden itself or empower a blow.',
    elementId: 'diabolico',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 3,
      'volonta': 20,
      'materia': 9,
      'oculum': 20,
      'defense': 120,
    },
    skillIds: [
      'demon_lesser_harden',
      'demon_lesser_ward',
      'demon_lesser_crush',
    ],
    dropIds: ['corno_demoniaco_minore', 'frammento_oculum_corrotto'],
  ),
  MonsterBookEntry(
    id: 'demone_intermedio',
    nameIt: 'Demone Intermedio',
    nameEn: 'Intermediate Demon',
    descIt:
        'Classe Boss, livello 0, Senza Grado. Privo di buon senso e divorato dalla fame, è peggiore di un Demone Minore. Base: Resilienza 3, Volontà 30, Materia 15, Oculum 30, Difesa 200. Oltre a potenziarsi e difendersi, forma sfere d’energia che possono proteggere o ferire; con un tiro su Pressione le espande. Ruolo in scena: assediante affamato che stringe la zona.',
    descEn:
        'Boss, level 0, no Grade. A hungry brute that protects itself, empowers its body and expands defensive or damaging energy spheres through Pressure.',
    elementId: 'diabolico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 3,
      'volonta': 30,
      'materia': 15,
      'oculum': 30,
      'defense': 200,
    },
    skillIds: [
      'demon_intermediate_harden',
      'demon_intermediate_aegis_sphere',
      'demon_intermediate_pressure_sphere',
    ],
    dropIds: ['zanna_demoniaca_intermedia', 'nucleo_sfera_pressione'],
  ),
  MonsterBookEntry(
    id: 'demone_maggiore',
    nameIt: 'Demone Maggiore',
    nameEn: 'Greater Demon',
    descIt:
        'Classe Boss, livello 0, Senza Grado. Parla e ragiona in modo vicino agli umani, ma divora altri demoni per diventare più forte. A differenza delle basi comuni parte da Resilienza 10, Volontà 65, Materia 45, Oculum 50, Scudo 120 e Difesa 300. Usa l’Oculum per dominare il corpo, le barriere e i demoni minori. Ruolo in scena: predatore intelligente che spezza la linea e sceglie chi divorare.',
    descEn:
        'Boss, level 0, no Grade. An intelligent demon that eats weaker demons to grow; it begins with Resilience 10, Will 65, Matter 45, Oculum 50, Shield 120 and Defense 300.',
    elementId: 'diabolico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 10,
      'volonta': 65,
      'materia': 45,
      'oculum': 50,
      'shield': 120,
      'defense': 300,
    },
    skillIds: [
      'demon_greater_dominion',
      'demon_greater_devour',
      'demon_greater_hell_aegis',
    ],
    dropIds: ['cuore_demone_maggiore', 'corona_ossea_demoniaca'],
  ),
  MonsterBookEntry(
    id: 'scheletro_bombarolo',
    nameIt: 'Scheletro Bombarolo',
    nameEn: 'Bomber Skeleton',
    descIt:
        'Mostro, livello 0, Senza Grado. Base: Resilienza 1, Volontà 5, Materia 0, Oculum 0. Si spezza e rilancia ossa cariche in attacchi ad area semi-letali: la detonazione mira a dimezzare la Vita rimasta, non a cancellare il bersaglio con danno infinito. Ruolo in scena: artiglieria fragile che obbliga il gruppo a disperdersi.',
    descEn:
        'Level 0 monster. A fragile artillery skeleton whose area attacks deal semi-lethal damage based on remaining life.',
    elementId: 'osso',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 1,
      'volonta': 5,
      'materia': 0,
      'oculum': 0,
    },
    skillIds: [
      'bomber_skeleton_bone_bomb',
      'bomber_skeleton_shrapnel_ring',
      'bomber_skeleton_last_blast',
    ],
    dropIds: ['osso_cavo', 'polvere_di_ossa'],
  ),
  MonsterBookEntry(
    id: 'angelo_fustigatore',
    nameIt: 'Angelo Fustigatore',
    nameEn: 'Scourging Angel',
    descIt:
        'Classe Mini Boss, livello 0, Senza Grado. Base: Scudo Critico 1, Resilienza 10, Volontà 20, Materia 0, Oculum 1. Ogni 6 livelli ottiene +50 Danni; ogni 5 livelli +20 Difesa, oltre alla crescita normale. Ruolo in scena: cacciatore celeste che colpisce in finestre brevi e punitive.',
    descEn:
        'Level 0 mini-boss. Starts with one Critical Shield; gains +50 damage every 6 levels and +20 defense every 5 levels.',
    elementId: 'angelico',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'criticalShield': 1,
      'resilienza': 10,
      'volonta': 20,
      'materia': 0,
      'oculum': 1,
    },
    skillIds: [
      'scourging_angel_lash',
      'scourging_angel_judgement',
      'scourging_angel_wing_guard',
    ],
    dropIds: ['piuma_fustigatrice', 'frammento_scudo_critico'],
  ),
  MonsterBookEntry(
    id: 'angelo_protettore',
    nameIt: 'Angelo Protettore',
    nameEn: 'Protective Angel',
    descIt:
        'Classe Mini Boss, livello 0, Senza Grado. Base: Resilienza 30, Volontà 1, Materia 40, Oculum 2. Può prendere su di sé il danno destinato ai compagni. Ruolo in scena: muro vivente che trasforma l ordine dei bersagli e protegge chi è più fragile.',
    descEn:
        'Level 0 mini-boss. Takes damage in place of its companions and guards the weakest target.',
    elementId: 'angelico',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 30,
      'volonta': 1,
      'materia': 40,
      'oculum': 2,
    },
    skillIds: [
      'protective_angel_intercept',
      'protective_angel_wing_wall',
      'protective_angel_vow',
    ],
    dropIds: ['piuma_protettrice', 'sigillo_di_guardia'],
  ),
  MonsterBookEntry(
    id: 'serafino',
    nameIt: 'Serafino',
    nameEn: 'Seraph',
    descIt:
        'Classe Boss, livello 0, Senza Grado. Base: Resilienza 50, Volontà 20, Materia 30, Oculum 30. Entità angelica superiore: non sostituisce il Protettore né il Fustigatore, ma domina la scena con ali, luce e giudizio. Ruolo in scena: vertice celeste che unisce pressione, difesa e comando.',
    descEn:
        'Level 0 boss. A superior angelic entity that combines pressure, defense and command.',
    elementId: 'angelico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {
      'level': 0,
      'criticalShield': 2,
      'resistancePercent': 60,
      'oculumShieldPerLevel': 5,
      'resilienza': 50,
      'volonta': 20,
      'materia': 30,
      'oculum': 30,
    },
    skillIds: [
      'seraph_wing_lance',
      'seraph_halo_command',
      'seraph_six_wing_aegis',
    ],
    dropIds: ['piuma_serafica', 'nucleo_di_luce'],
  ),
  MonsterBookEntry(
    id: 'goblin_killer',
    nameIt: 'Goblin Killer',
    nameEn: 'Goblin Killer',
    descIt:
        'Mostro, livello 0. Base: Resilienza 1, Volontà 6, Materia 10, Oculum 0. Dopo aver ucciso una creatura recupera tutta la Vita. Ruolo in scena: piccolo finitore, pericoloso solo se può chiudere un bersaglio già ferito.',
    descEn: 'Level 0 monster. Fully heals after it kills a creature.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 1,
      'volonta': 6,
      'materia': 10,
      'oculum': 0,
    },
    skillIds: ['goblin_killer_finish'],
    dropIds: ['lama_goblin', 'moneta_sporca'],
  ),
  MonsterBookEntry(
    id: 'arcangelo',
    nameIt: 'Arcangelo',
    nameEn: 'Archangel',
    descIt:
        'Classe Boss, livello 0. Leggermente più forte degli altri angeli e versatile: alterna attacco, protezione e comando senza sostituire il Serafino. Base: Resilienza 40, Volontà 25, Materia 25, Oculum 20.',
    descEn:
        'Versatile level 0 angelic boss, slightly stronger than common angels.',
    elementId: 'angelico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 40,
      'volonta': 25,
      'materia': 25,
      'oculum': 20,
    },
    skillIds: ['archangel_strike', 'archangel_guard', 'archangel_order'],
    dropIds: ['piuma_arcangelo'],
  ),
  MonsterBookEntry(
    id: 'pinepine',
    nameIt: 'Pinepine',
    nameEn: 'Pinepine',
    descIt:
        'Mostro intermedio, livello 0. Base: Resilienza 6, Volontà 3, Materia 10, Oculum 0, Scudo Critico 1 e Resistenza 50%. Punto debole: Ferite Aperte e Fuoco. Con critico sul drop ottieni 20 Scudo Pigna: dimezza i danni non di fuoco; contro fuoco o simili la pelle esplode, danneggiando tutte le creature entro 2 metri, alleati inclusi.',
    descEn:
        'Intermediate creature with 50% resistance, weak to open wounds and fire.',
    elementId: 'natura',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'criticalShield': 1,
      'resistancePercent': 50,
      'resilienza': 6,
      'volonta': 3,
      'materia': 10,
      'oculum': 0,
    },
    skillIds: ['pinepine_cone_skin'],
    dropIds: ['scudo_pigna'],
  ),
  MonsterBookEntry(
    id: 'demone_glaciale_minore',
    nameIt: 'Demone Glaciale Minore',
    nameEn: 'Lesser Frost Demon',
    descIt:
        'Mostro, livello 0. Base: Resilienza 5, Volontà 8, Materia 6, Oculum 4. Ha Ricordo Vitale di base; se lo ferisci in ravvicinato, chi ti ha colpito riceve Congelamento.',
    descEn:
        'Level 0 frost demon with Vital Memory; melee attackers receive Freeze.',
    elementId: 'gelo',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 5,
      'volonta': 8,
      'materia': 6,
      'oculum': 4,
    },
    skillIds: ['lesser_frost_demon_cold_blood'],
    dropIds: ['scheggia_glaciale'],
  ),
  MonsterBookEntry(
    id: 'demone_glaciale_intermedio',
    nameIt: 'Demone Glaciale Intermedio',
    nameEn: 'Intermediate Frost Demon',
    descIt:
        'Classe Mini Boss, livello 0. Base: Resilienza 20, Volontà 25, Materia 19, Oculum 13. Usa Oculum per raggi congelanti a distanza.',
    descEn: 'Level 0 mini-boss with freezing Oculum rays.',
    elementId: 'gelo',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 20,
      'volonta': 25,
      'materia': 19,
      'oculum': 13,
    },
    skillIds: ['intermediate_frost_demon_ray'],
    dropIds: ['occhio_glaciale'],
  ),
  MonsterBookEntry(
    id: 'demone_glaciale_maggiore',
    nameIt: 'Demone Glaciale Maggiore',
    nameEn: 'Greater Frost Demon',
    descIt:
        'Classe Boss, livello 0. Base: Resilienza 30, Volontà 49, Materia 50, Oculum 39. La sua Open congela il tempo per un turno: tutti vedono e sentono ogni atrocità, ma il danno accumulato arriva insieme alla fine del turno.',
    descEn:
        'Level 0 boss that freezes time for one turn and delivers accumulated damage at its end.',
    elementId: 'gelo',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 30,
      'volonta': 49,
      'materia': 50,
      'oculum': 39,
    },
    skillIds: ['greater_frost_demon_time_freeze'],
    dropIds: ['cuore_glaciale'],
  ),
  MonsterBookEntry(
    id: 'lupo_infernale_del_ghiaccio',
    nameIt: 'Lupo Infernale del Ghiaccio',
    nameEn: 'Infernal Ice Wolf',
    descIt:
        'Mostro di un inferno fatto insieme di ghiaccio e fiamme. Non ha Skill: con 18+ naturale congela il nemico colpito. Ruolo in scena: predatore rapido da branco.',
    descEn: 'Infernal ice-and-flame wolf; a natural 18+ freezes its target.',
    elementId: 'gelo',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'resilienza': 6, 'volonta': 3, 'materia': 8, 'oculum': 2},
    skillIds: [],
    dropIds: ['zanna_ghiacciata'],
  ),
  MonsterBookEntry(
    id: 'demonietto_bruciante',
    nameIt: 'Demonietto Bruciante',
    nameEn: 'Burning Imp',
    descIt:
        'Piccolo demone dei biomi infernali: un colpo riuscito può applicare Bruciore. Nessuna Skill separata: la condizione è la sua peculiarità.',
    descEn: 'Small infernal imp that can apply Burn.',
    elementId: 'fuoco',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'resilienza': 2, 'volonta': 5, 'materia': 3, 'oculum': 6},
    skillIds: [],
    dropIds: ['brace_infernale'],
  ),
  MonsterBookEntry(
    id: 'demonietto_del_gelo',
    nameIt: 'Demonietto del Gelo',
    nameEn: 'Frost Imp',
    descIt:
        'Piccolo demone dei biomi infernali: un colpo critico applica Congelamento. Non possiede Skill dedicate.',
    descEn: 'Small infernal imp that freezes on a critical hit.',
    elementId: 'gelo',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'resilienza': 3, 'volonta': 4, 'materia': 5, 'oculum': 4},
    skillIds: [],
    dropIds: ['cristallo_infernale'],
  ),
  MonsterBookEntry(
    id: 'coboldo_di_brina',
    nameIt: 'Coboldo di Brina',
    nameEn: 'Frost Kobold',
    descIt:
        'Coboldo comune senza Skill: usa una lancia corta e cerca copertura, con statistiche basse ma adatte a un incontro iniziale.',
    descEn: 'Simple low-stat kobold with no Skills.',
    elementId: 'gelo',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'resilienza': 3, 'volonta': 2, 'materia': 4, 'oculum': 0},
    skillIds: [],
    dropIds: ['lancia_cobolda'],
  ),
  MonsterBookEntry(
    id: 'osservatore_bianco',
    nameIt: 'L Osservatore',
    nameEn: 'The Observer',
    descIt:
        'Classe Mini Boss, livello 0, Senza Grado. Figura magra, bianca e quasi scheletrica; si dice discenda da uno psicopatico con la stessa facoltà, trasformato in mostro. Base: Resilienza 6, Volontà 10, Materia 19, Oculum 30. Può copiare ogni Skill che vede, mantenendone costo, conseguenze e limiti. Ruolo in scena: adattatore che cambia piano dopo aver osservato il gruppo.',
    descEn:
        'Level 0 mini-boss. A thin white skeletal figure that copies every Skill it witnesses, retaining its costs and limits.',
    elementId: 'psichico',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 6,
      'volonta': 10,
      'materia': 19,
      'oculum': 30,
    },
    skillIds: [
      'observer_witness_copy',
      'observer_white_analysis',
      'observer_replay',
    ],
    dropIds: ['occhio_osservatore', 'osso_bianco'],
  ),
  MonsterBookEntry(
    id: 'immortale',
    nameIt: 'L Immortale',
    nameEn: 'The Immortal',
    descIt:
        'Mostro, livello 0, Senza Grado. Base: Resilienza 20, Volontà 10, Materia 5, Oculum 0. Gli Immortali recuperano Vita pari al danno realmente inflitto alla Vita del bersaglio: gli Scudi assorbiti non valgono. Ruolo in scena: duellante che diventa più difficile da abbattere se gli lasci raggiungere un bersaglio ferito.',
    descEn:
        'Level 0 monster. Heals for damage actually dealt to a target’s life; shield damage never counts.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 20,
      'volonta': 10,
      'materia': 5,
      'oculum': 0,
    },
    skillIds: [
      'immortal_life_harvest',
      'immortal_relentless_cut',
      'immortal_undying_stance',
    ],
    dropIds: ['midollo_immortale', 'filo_di_vita'],
  ),
  // Incontri classici: ogni profilo mantiene una funzione leggibile per il
  // Master e tre azioni piccole, senza trasformare ogni nemico in un boss.
  MonsterBookEntry(
    id: 'goblin_base',
    nameIt: 'Goblin',
    nameEn: 'Goblin',
    descIt:
        'Disturbo, 8 punti extra. Stat basse: RES 2 VOL 4 MAT 5 OCU 0. Colpo Sporco +1 danno da posizione favorevole; Scappa e Ridi: piccolo movimento dopo un attacco mancato, una volta a turno; Cianfrusaglia: un oggetto improvvisato casuale una volta per scontro. Ruolo in scena: disturba e fugge, non duella.',
    descEn: 'Low-stat disruptor goblin.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 8,
      'resilienza': 2,
      'volonta': 4,
      'materia': 5,
      'oculum': 0,
    },
    skillIds: ['dirty_strike', 'run_laugh', 'junk'],
    dropIds: ['cianfrusaglia'],
  ),
  MonsterBookEntry(
    id: 'kobold_base',
    nameIt: 'Kobold',
    nameEn: 'Kobold',
    descIt:
        'Trappole, 7 punti extra. RES 2 VOL 3 MAT 5 OCU 0. Filo Teso rallenta una piccola zona; Tana Conosciuta migliora il movimento in spazi stretti; Attacco di Branco +1 al tiro vicino a un alleato. Ruolo: prepara il terreno.',
    descEn: 'Trap kobold.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 7,
      'resilienza': 2,
      'volonta': 3,
      'materia': 5,
      'oculum': 0,
    },
    skillIds: ['tripwire', 'den_move', 'pack_attack'],
    dropIds: ['filo'],
  ),
  MonsterBookEntry(
    id: 'scheletro_base',
    nameIt: 'Scheletro',
    nameEn: 'Skeleton',
    descIt:
        'Fanteria, 10 punti extra. RES 4 VOL 2 MAT 4 OCU 0. Ossa Sparse sostituisce un controllo pesante con perdita di movimento; Ricomporsi recupera pochi HP sacrificando l azione; Vuoto Dentro resiste leggermente a paura e mente. Ruolo: linea semplice.',
    descEn: 'Skeleton infantry.',
    elementId: 'osso',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 10,
      'resilienza': 4,
      'volonta': 2,
      'materia': 4,
      'oculum': 0,
    },
    skillIds: ['scattered_bones', 'reassemble', 'hollow'],
    dropIds: ['osso'],
  ),
  MonsterBookEntry(
    id: 'zombie_base',
    nameIt: 'Zombie',
    nameEn: 'Zombie',
    descIt:
        'Tank lento, 12 punti extra. RES 7 VOL 2 MAT 2 OCU 0. Non Cade: una volta resta a 1 HP; Morso Marcio lascia un danno continuo lieve e rimovibile; Passo Inesorabile non scende sotto metà movimento. Ruolo: occupa spazio.',
    descEn: 'Slow zombie tank.',
    elementId: 'necrotico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 12,
      'resilienza': 7,
      'volonta': 2,
      'materia': 2,
      'oculum': 0,
    },
    skillIds: ['not_down', 'rotten_bite', 'slow_step'],
    dropIds: ['carne_marcia'],
  ),
  MonsterBookEntry(
    id: 'bandito_base',
    nameIt: 'Bandito',
    nameEn: 'Bandit',
    descIt:
        'Versatile, 11 punti extra. RES 4 VOL 5 MAT 4 OCU 0. Finta rinuncia a 1 danno per il prossimo attacco; Mano Rapida usa un oggetto senza perdere il turno; Alle Spalle dà un piccolo bonus su bersagli impegnati. Ruolo: opportunista.',
    descEn: 'Versatile bandit.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 11,
      'resilienza': 4,
      'volonta': 5,
      'materia': 4,
      'oculum': 0,
    },
    skillIds: ['feint', 'quick_hand', 'backstab'],
    dropIds: ['monete'],
  ),
  MonsterBookEntry(
    id: 'lupo_gigante_base',
    nameIt: 'Lupo Gigante',
    nameEn: 'Giant Wolf',
    descIt:
        'Inseguitore, 13 punti extra. RES 6 VOL 4 MAT 5 OCU 0. Morso alla Gamba riduce movimento; Predatore segue feriti; Branco +1 Difesa vicino a un lupo. Ruolo: insegue il bersaglio isolato.',
    descEn: 'Giant wolf.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 13,
      'resilienza': 6,
      'volonta': 4,
      'materia': 5,
      'oculum': 0,
    },
    skillIds: ['leg_bite', 'predator', 'wolf_pack'],
    dropIds: ['pelliccia'],
  ),
  MonsterBookEntry(
    id: 'gnoll_base',
    nameIt: 'Gnoll',
    nameEn: 'Gnoll',
    descIt:
        'Cacciatore, 16 punti extra. RES 6 VOL 6 MAT 6 OCU 0. Fiuto del Sangue contro metà HP; Risata Predatoria -1 al prossimo tiro offensivo, non cumulabile; Strappo rallenta dopo due colpi nello stesso round. Ruolo: finitore.',
    descEn: 'Gnoll hunter.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 16,
      'resilienza': 6,
      'volonta': 6,
      'materia': 6,
      'oculum': 0,
    },
    skillIds: ['blood_scent', 'predator_laugh', 'rend'],
    dropIds: ['zanna'],
  ),
  MonsterBookEntry(
    id: 'arpia_base',
    nameIt: 'Arpia',
    nameEn: 'Harpy',
    descIt:
        'Controllo mobile, 17 punti extra. RES 4 VOL 7 MAT 6 OCU 2. Canto Inquietante riduce movimento; Picchiata +2 danni dall alto ma perde Difesa; Battito d Ali respinge poco in area. Ruolo: sposta il gruppo.',
    descEn: 'Mobile harpy controller.',
    elementId: 'aria',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 17,
      'resilienza': 4,
      'volonta': 7,
      'materia': 6,
      'oculum': 2,
    },
    skillIds: ['harpy_song', 'dive', 'wingbeat'],
    dropIds: ['piuma'],
  ),
  MonsterBookEntry(
    id: 'orco_base',
    nameIt: 'Orco',
    nameEn: 'Orc',
    descIt:
        'Assaltatore, 18 punti extra. RES 8 VOL 5 MAT 5 OCU 0. Carica Brutale +2 danni dopo corsa ma -1 Difesa; Rabbia del Ferito +1 danno sotto metà HP; Spallata sposta rinunciando a danno. Ruolo: sfonda.',
    descEn: 'Orc charger.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 18,
      'resilienza': 8,
      'volonta': 5,
      'materia': 5,
      'oculum': 0,
    },
    skillIds: ['brutal_charge', 'hurt_rage', 'shoulder'],
    dropIds: ['ascia'],
  ),
  MonsterBookEntry(
    id: 'ragno_gigante_base',
    nameIt: 'Ragno Gigante',
    nameEn: 'Giant Spider',
    descIt:
        'Controllo, 19 punti extra. RES 6 VOL 5 MAT 7 OCU 1. Ragnatela rallenta ed è distruttibile; Morso Paralizzante riduce movimento o reazioni, non blocca totalmente; Arrampicatore ignora ostacoli verticali. Ruolo: chiude passaggi.',
    descEn: 'Giant spider.',
    elementId: 'veleno',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 19,
      'resilienza': 6,
      'volonta': 5,
      'materia': 7,
      'oculum': 1,
    },
    skillIds: ['web', 'weak_paralysis', 'climb'],
    dropIds: ['seta'],
  ),
  MonsterBookEntry(
    id: 'hobgoblin_base',
    nameIt: 'Hobgoblin',
    nameEn: 'Hobgoblin',
    descIt:
        'Soldato tattico, 22 punti extra. RES 8 VOL 7 MAT 7. Formazione +1 Difesa vicino a un alleato; Ordine Breve +1 al prossimo tiro alleato una volta per round; Contrattacco infligge 1 danno dopo una difesa riuscita, una volta per round.',
    descEn: 'Tactical soldier.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 22,
      'resilienza': 8,
      'volonta': 7,
      'materia': 7,
      'oculum': 0,
    },
    skillIds: ['formation', 'short_order', 'counterattack'],
    dropIds: ['scudo'],
  ),
  MonsterBookEntry(
    id: 'mimic_base',
    nameIt: 'Mimic',
    nameEn: 'Mimic',
    descIt:
        'Imboscata, 25 punti extra. RES 8 VOL 6 MAT 8 OCU 3. Oggetto Innocente migliora il primo attacco nascosto; Lingua Adesiva trascina poco; Forma Instabile cambia aspetto per un vantaggio situazionale. Ruolo: sorprende senza controllare tutto.',
    descEn: 'Ambush mimic.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 25,
      'resilienza': 8,
      'volonta': 6,
      'materia': 8,
      'oculum': 3,
    },
    skillIds: ['innocent_object', 'sticky_tongue', 'unstable_form'],
    dropIds: ['dente_mimic'],
  ),
  MonsterBookEntry(
    id: 'ogre_base',
    nameIt: 'Ogre',
    nameEn: 'Ogre',
    descIt:
        'Bruto, 28 punti extra. RES 13 VOL 5 MAT 7. Mazza a Terra è area ma meno del colpo normale; Presa immobilizza rinunciando ad azioni; Testa Dura accorcia il primo controllo. Ruolo: minaccia frontale lenta.',
    descEn: 'Ogre brute.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 28,
      'resilienza': 13,
      'volonta': 5,
      'materia': 7,
      'oculum': 0,
    },
    skillIds: ['ground_maul', 'grab', 'hard_head'],
    dropIds: ['mazza'],
  ),
  MonsterBookEntry(
    id: 'warg_base',
    nameIt: 'Warg',
    nameEn: 'Warg',
    descIt:
        'Predatore élite, 29 punti extra. RES 10 VOL 8 MAT 10. Assalto Coordinato +1 dopo un colpo alleato; Trascinamento muove poco un colpito; Ululato +1 movimento agli alleati vicini per un round.',
    descEn: 'Elite predator.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 29,
      'resilienza': 10,
      'volonta': 8,
      'materia': 10,
      'oculum': 0,
    },
    skillIds: ['coordinated_assault', 'drag', 'howl'],
    dropIds: ['zanna_warg'],
  ),
  MonsterBookEntry(
    id: 'basilisco_base',
    nameIt: 'Basilisco',
    nameEn: 'Basilisk',
    descIt:
        'Controllo élite, 32 punti extra. RES 11 VOL 10 MAT 8 OCU 4. Sguardo Calcificante accumula pietrificazione prima di immobilizzare; Coda Rocciosa fa poco danno e -1 Difesa; Pelle Minerale riduce il primo danno ogni round.',
    descEn: 'Elite control basilisk.',
    elementId: 'pietra',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 32,
      'resilienza': 11,
      'volonta': 10,
      'materia': 8,
      'oculum': 4,
    },
    skillIds: ['calcify', 'stone_tail', 'mineral_skin'],
    dropIds: ['occhio_basilisco'],
  ),
  MonsterBookEntry(
    id: 'troll_base',
    nameIt: 'Troll',
    nameEn: 'Troll',
    descIt:
        'Rigeneratore, 35 punti extra. RES 16 VOL 7 MAT 8. Rigenerazione piccola a fine turno e bloccabile da vulnerabilità; Braccia Lunghe aumentano portata; Carne Mutante dà +1 Res temporanea dopo un colpo pesante.',
    descEn: 'Regenerating troll.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 35,
      'resilienza': 16,
      'volonta': 7,
      'materia': 8,
      'oculum': 0,
    },
    skillIds: ['regen', 'long_arms', 'mutant_flesh'],
    dropIds: ['carne_troll'],
  ),
  MonsterBookEntry(
    id: 'golem_di_pietra_base',
    nameIt: 'Golem di Pietra',
    nameEn: 'Stone Golem',
    descIt:
        'Difensore élite, 38 punti extra. RES 19 VOL 4 MAT 9. Corpo Massiccio resiste agli spostamenti; Pugno Sismico è un cono corto; Crepe Strutturali gli tolgono Difesa dopo diversi colpi pesanti. Ruolo: muro con punto di rottura.',
    descEn: 'Stone defender.',
    elementId: 'pietra',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 38,
      'resilienza': 19,
      'volonta': 4,
      'materia': 9,
      'oculum': 0,
    },
    skillIds: ['massive_body', 'seismic_punch', 'cracks'],
    dropIds: ['cuore_golem'],
  ),
  MonsterBookEntry(
    id: 'necromante_base',
    nameIt: 'Necromante',
    nameEn: 'Necromancer',
    descIt:
        'Controllore élite, 40 punti extra. RES 8 VOL 14 MAT 8 OCU 10. Scheletro Effimero evoca un servo debole; Debito Vitale paga HP per magia; Eco Funebre dà un piccolo bonus non cumulabile quando muore un servo.',
    descEn: 'Elite necromancer.',
    elementId: 'necrotico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 40,
      'resilienza': 8,
      'volonta': 14,
      'materia': 8,
      'oculum': 10,
    },
    skillIds: ['temporary_skeleton', 'life_debt', 'funeral_echo'],
    dropIds: ['focus_nero'],
  ),
  MonsterBookEntry(
    id: 'grifone_base',
    nameIt: 'Grifone',
    nameEn: 'Griffin',
    descIt:
        'Predatore volante, 41 punti extra. RES 13 VOL 9 MAT 13 OCU 2. Artigliata dopo lungo volo; Afferrare trasporta un bersaglio piccolo per poco; Ali Difensive riducono un attacco a distanza con reazione.',
    descEn: 'Flying predator.',
    elementId: 'aria',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 41,
      'resilienza': 13,
      'volonta': 9,
      'materia': 13,
      'oculum': 2,
    },
    skillIds: ['dive_claw', 'carry', 'defensive_wings'],
    dropIds: ['piuma_grifone'],
  ),
  MonsterBookEntry(
    id: 'minotauro_base',
    nameIt: 'Minotauro',
    nameEn: 'Minotaur',
    descIt:
        'Miniboss, 43 punti extra. RES 20 VOL 9 MAT 12 OCU 2. Carica del Labirinto spinge ma richiede spazio; Furia Cieca aumenta danno sotto metà HP e perde Difesa; Memoria dei Corridoi ripete un tiro di movimento una volta.',
    descEn: 'Miniboss minotaur.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 43,
      'resilienza': 20,
      'volonta': 9,
      'materia': 12,
      'oculum': 2,
    },
    skillIds: ['maze_charge', 'blind_fury', 'corridor_memory'],
    dropIds: ['corno'],
  ),
  MonsterBookEntry(
    id: 'vampiro_base',
    nameIt: 'Vampiro',
    nameEn: 'Vampire',
    descIt:
        'Miniboss tecnico, 46 punti extra. RES 14 VOL 15 MAT 10 OCU 8. Morso cura solo parte del danno; Forma di Nebbia è evasione breve con cooldown; Fascino applica penalità mentale temporanea senza controllo totale.',
    descEn: 'Technical vampire miniboss.',
    elementId: 'sangue',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 46,
      'resilienza': 14,
      'volonta': 15,
      'materia': 10,
      'oculum': 8,
    },
    skillIds: ['vampire_bite', 'mist_form', 'charm'],
    dropIds: ['sangue_antico'],
  ),
  MonsterBookEntry(
    id: 'elementale_maggiore_base',
    nameIt: 'Elementale Maggiore',
    nameEn: 'Greater Elemental',
    descIt:
        'Miniboss elementale, 48 punti extra. RES 17 VOL 12 MAT 11 OCU 10. Corpo Elementale punisce una mischia una volta per round; Esplosione Elementale è area con cooldown; Instabilità sotto metà HP aumenta danno ma riduce Difesa.',
    descEn: 'Elemental miniboss.',
    elementId: 'elementale',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 48,
      'resilienza': 17,
      'volonta': 12,
      'materia': 11,
      'oculum': 10,
    },
    skillIds: ['elemental_body', 'elemental_blast', 'instability'],
    dropIds: ['nucleo_elementale'],
  ),
  MonsterBookEntry(
    id: 'lich_minore_base',
    nameIt: 'Lich Minore',
    nameEn: 'Lesser Lich',
    descIt:
        'Miniboss magico, 50 punti extra. RES 12 VOL 18 MAT 8 OCU 14. Anima Vincolata lo lascia a pochi HP se il focus è integro; Raggio Sepolcrale fa danno e piccolo malus; Sigillo Mortuario riduce cure in zona, senza annullarle.',
    descEn: 'Magic lich miniboss.',
    elementId: 'necrotico',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'extraPoints': 50,
      'resilienza': 12,
      'volonta': 18,
      'materia': 8,
      'oculum': 14,
    },
    skillIds: ['bound_soul', 'grave_ray', 'death_seal'],
    dropIds: ['focus_lich'],
  ),
  MonsterBookEntry(
    id: 'gigante_base',
    nameIt: 'Gigante',
    nameEn: 'Giant',
    descIt:
        'Boss, 52 punti extra. RES 28 VOL 10 MAT 14. Passo Distruttivo rompe piccoli ostacoli e respinge; Presa e Lancio consuma l azione; Collera Crescente +1 danno ogni 25% HP persi fino a +3.',
    descEn: 'Giant boss.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {
      'extraPoints': 52,
      'resilienza': 28,
      'volonta': 10,
      'materia': 14,
      'oculum': 0,
    },
    skillIds: ['destroying_step', 'grab_throw', 'growing_anger'],
    dropIds: ['osso_gigante'],
  ),
  MonsterBookEntry(
    id: 'drago_giovane_base',
    nameIt: 'Drago Giovane',
    nameEn: 'Young Dragon',
    descIt:
        'Boss, 56 punti extra. RES 23 VOL 15 MAT 15 OCU 10. Soffio area con ricarica; Colpo d Ala respinge poco; Dominio Draconico sotto metà HP dà movimento aggiuntivo, non turno extra.',
    descEn: 'Young dragon boss.',
    elementId: 'draconico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {
      'extraPoints': 56,
      'resilienza': 23,
      'volonta': 15,
      'materia': 15,
      'oculum': 10,
    },
    skillIds: ['breath', 'wing_hit', 'dragon_domain'],
    dropIds: ['scaglia'],
  ),
  MonsterBookEntry(
    id: 'idra_base',
    nameIt: 'Idra',
    nameEn: 'Hydra',
    descIt:
        'Boss resistente, 58 punti extra. RES 30 VOL 12 MAT 13 OCU 8. Teste Coordinate divide il danno tra due bersagli senza aumentarlo; Ricrescita è limitata a due volte; Furia delle Teste aggiunge danno e reazione sotto metà HP ma toglie Difesa.',
    descEn: 'Resilient hydra boss.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {
      'extraPoints': 58,
      'resilienza': 30,
      'volonta': 12,
      'materia': 13,
      'oculum': 8,
    },
    skillIds: ['coordinated_heads', 'controlled_regrowth', 'head_fury'],
    dropIds: ['testa_idra'],
  ),
  MonsterBookEntry(
    id: 'drago_antico_base',
    nameIt: 'Drago Antico',
    nameEn: 'Ancient Dragon',
    descIt:
        'Boss massimo livello 0, 60 punti extra. RES 34 VOL 16 MAT 16 OCU 14. Dominio Antico compie una azione minore una volta per round; Cataclisma prepara un turno un area enorme e interrompibile; Fase Furiosa sotto metà HP modifica abilità e +2 danni, senza secondo turno completo.',
    descEn: 'Maximum level 0 ancient dragon boss.',
    elementId: 'draconico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {
      'level': 0,
      'extraPoints': 60,
      'resilienza': 34,
      'volonta': 16,
      'materia': 16,
      'oculum': 14,
    },
    skillIds: ['ancient_domain', 'cataclysm', 'furious_phase'],
    dropIds: ['cuore_drago'],
  ),
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
    id: 'lumaca_assassina',
    nameIt: 'Lumaca Assassina',
    nameEn: 'Assassin Snail',
    descIt:
        'Mostro debole. Lumacone lungo due metri e largo uno e mezzo, con enorme guscio borchiato. Ruolo in scena: lascia una bava che toglie Reazioni a chi la attraversa; possiede Ricordo Vitale.',
    descEn: 'Weak giant spiked-shell snail.',
    elementId: 'acido',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 1,
      'resilienza': 4,
      'volonta': 2,
      'materia': 2,
      'oculum': 3,
    },
    skillIds: [
      'assassin_snail_slime',
      'assassin_snail_shell',
      'assassin_snail_memory',
    ],
    dropIds: ['bava_reattiva', 'spina_di_guscio', 'frammento_ricordo_vitale'],
  ),
  MonsterBookEntry(
    id: 'errante_con_la_sedia',
    nameIt: 'Errante con la Sedia',
    nameEn: 'Chair Wanderer',
    descIt:
        'Intermedio errante. Cammina piegato con una sedia fissata alla schiena; le gambe della sedia cercano i corridoi prima di lui. RES 8 VOL 7 MAT 6 OCU 5. Ruolo: blocca passaggi.',
    descEn: 'Medium chair-backed wanderer.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 5,
      'resilienza': 8,
      'volonta': 7,
      'materia': 6,
      'oculum': 5,
    },
    skillIds: ['chairram_block', 'chairram_pin', 'chairram_fall'],
    dropIds: ['gamba_sedia', 'cintura_strappata'],
  ),
  MonsterBookEntry(
    id: 'errante_bocca_cucita',
    nameIt: 'Errante Bocca Cucita',
    nameEn: 'Sewn Mouth Wanderer',
    descIt:
        'Intermedio errante. Non parla: sotto i fili della bocca qualcosa preme e canta. RES 6 VOL 10 MAT 7 OCU 8. Ruolo: interrompe e confonde.',
    descEn: 'Medium sewn-mouth wanderer.',
    elementId: 'mentale',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 7,
      'resilienza': 6,
      'volonta': 10,
      'materia': 7,
      'oculum': 8,
    },
    skillIds: ['sewn_hum', 'sewn_thread', 'sewn_open'],
    dropIds: ['filo_nero', 'dente_senza_radice'],
  ),
  MonsterBookEntry(
    id: 'errante_specchio',
    nameIt: 'Errante Specchio',
    nameEn: 'Mirror Wanderer',
    descIt:
        'Intermedio errante. Ha un piccolo specchio al posto del volto e mani troppo lunghe. RES 7 VOL 8 MAT 10 OCU 8. Ruolo: copia posizione e devia colpi.',
    descEn: 'Medium mirror-faced wanderer.',
    elementId: 'specchio',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 8,
      'resilienza': 7,
      'volonta': 8,
      'materia': 10,
      'oculum': 8,
    },
    skillIds: ['mirror_hand', 'mirror_step', 'mirror_crack'],
    dropIds: ['vetro_di_volto', 'dito_lungo'],
  ),
  MonsterBookEntry(
    id: 'errante_bambola_bagnata',
    nameIt: 'Errante Bambola Bagnata',
    nameEn: 'Wet Doll Wanderer',
    descIt:
        'Intermedio errante. Una bambola alta quanto una persona, gonfia d acqua scura e con capelli incollati al viso. RES 9 VOL 6 MAT 8 OCU 9. Ruolo: rallenta e consuma spazio.',
    descEn: 'Medium waterlogged doll wanderer.',
    elementId: 'acqua',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 9,
      'resilienza': 9,
      'volonta': 6,
      'materia': 8,
      'oculum': 9,
    },
    skillIds: ['wetdoll_drip', 'wetdoll_grab', 'wetdoll_spill'],
    dropIds: ['stoffa_bagnata', 'occhio_vetro_opaco'],
  ),
  MonsterBookEntry(
    id: 'errante_con_ombrello',
    nameIt: 'Errante con Ombrello',
    nameEn: 'Umbrella Wanderer',
    descIt:
        'Intermedio errante. Tiene un ombrello chiuso sopra la testa anche sottoterra; sotto la stoffa qualcosa respira. RES 7 VOL 9 MAT 9 OCU 10. Ruolo: entra, colpisce e sparisce.',
    descEn: 'Medium umbrella-bearing wanderer.',
    elementId: 'ombra',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 10,
      'resilienza': 7,
      'volonta': 9,
      'materia': 9,
      'oculum': 10,
    },
    skillIds: ['umbrella_thrust', 'umbrella_cover', 'umbrella_depart'],
    dropIds: ['tela_ombrello', 'manico_freddo'],
  ),
  MonsterBookEntry(
    id: 'topo_con_mani',
    nameIt: 'Topo con Mani',
    nameEn: 'Hand Rat',
    descIt:
        'Mostro debole ma fastidioso. Ratto grande come un gatto, con due piccole mani umane e unghie nere al posto delle zampe anteriori. RES 1 VOL 2 MAT 2 OCU 1. Ruolo: apre ferite e scappa.',
    descEn: 'Weak but irritating hand-rat.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 1,
      'volonta': 2,
      'materia': 2,
      'oculum': 1,
    },
    skillIds: [
      'handrat_face_pull',
      'handrat_fingers_inside',
      'handrat_skin_leave',
    ],
    dropIds: ['unghia_nera', 'pelle_di_topo', 'filo_nervoso'],
  ),
  MonsterBookEntry(
    id: 'occhio_millepiedi',
    nameIt: 'Occhio Millepiedi',
    nameEn: 'Centipede Eye',
    descIt:
        'Mostro debole e inquieto. Un occhio umano grande quanto un pugno; dal nervo ottico crescono decine di piccole zampe. RES 1 VOL 1 MAT 2 OCU 2. Ruolo: disturba tiri e difesa.',
    descEn: 'Weak centipede-eyed nuisance.',
    elementId: 'oculum',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 1,
      'volonta': 1,
      'materia': 2,
      'oculum': 2,
    },
    skillIds: ['centieye_lid_bite', 'centieye_stare', 'centieye_under_clothes'],
    dropIds: ['nervo_oculare', 'zampa_sottile', 'palpebra_dentata'],
  ),
  MonsterBookEntry(
    id: 'tappo_con_zampe',
    nameIt: 'Tappo con Zampe',
    nameEn: 'Legged Cap',
    descIt:
        'Debole, livello 0. RES 1 VOL 1 MAT 0 OCU 0. Un tappo di sughero che corre via dal rumore. Ruolo: disturba e fugge.',
    descEn: 'Weak running cork.',
    elementId: 'terra',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 1,
      'volonta': 1,
      'materia': 0,
      'oculum': 0,
    },
    skillIds: ['cap_bump', 'cap_roll', 'cap_squeak'],
    dropIds: ['sughero_umido'],
  ),
  MonsterBookEntry(
    id: 'pesce_scarpa',
    nameIt: 'Pesce Scarpa',
    nameEn: 'Shoe Fish',
    descIt:
        'Debole, livello 0. RES 2 VOL 1 MAT 1 OCU 0. Nuota nei fossi con una scarpa al posto della pinna. Ruolo: morde e scivola via.',
    descEn: 'Weak shoe-finned fish.',
    elementId: 'acqua',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 2,
      'volonta': 1,
      'materia': 1,
      'oculum': 0,
    },
    skillIds: ['shoe_bite', 'shoe_splash', 'shoe_hide'],
    dropIds: ['laccio_bagnato'],
  ),
  MonsterBookEntry(
    id: 'gatto_ciotola',
    nameIt: 'Gatto Ciotola',
    nameEn: 'Bowl Cat',
    descIt:
        'Intermedio, livello 4. RES 7 VOL 5 MAT 8 OCU 4. Un gatto che vive dentro una ciotola di ceramica e la usa come corazza. Ruolo: controlla spazio e difende.',
    descEn: 'Medium bowl-armored cat.',
    elementId: 'terra',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 4,
      'resilienza': 7,
      'volonta': 5,
      'materia': 8,
      'oculum': 4,
    },
    skillIds: ['bowl_spin', 'bowl_guard', 'bowl_crack'],
    dropIds: ['ciotola_incrinata', 'baffo_ceramica'],
  ),
  MonsterBookEntry(
    id: 'cervo_candela',
    nameIt: 'Cervo Candela',
    nameEn: 'Candle Deer',
    descIt:
        'Intermedio, livello 6. RES 6 VOL 9 MAT 6 OCU 8. Ha candele corte sulle corna e segue chi sanguina. Ruolo: pressione a distanza.',
    descEn: 'Medium candle-antler deer.',
    elementId: 'fuoco',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 6,
      'resilienza': 6,
      'volonta': 9,
      'materia': 6,
      'oculum': 8,
    },
    skillIds: ['candle_mark', 'candle_run', 'candle_burst'],
    dropIds: ['cera_caldo', 'corno_candela'],
  ),
  MonsterBookEntry(
    id: 'toro_di_fango',
    nameIt: 'Toro di Fango',
    nameEn: 'Mud Bull',
    descIt:
        'Forte, livello 12. RES 18 VOL 10 MAT 14 OCU 10. Un toro pesante che prende forma nelle pozzanghere. Ruolo: rompe la linea e resiste.',
    descEn: 'Strong mud bull.',
    elementId: 'terra',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 12,
      'resilienza': 18,
      'volonta': 10,
      'materia': 14,
      'oculum': 10,
    },
    skillIds: ['mud_charge', 'mud_hide', 'mud_throw'],
    dropIds: ['fango_pesante', 'corno_fango'],
  ),
  MonsterBookEntry(
    id: 'serpente_finestra',
    nameIt: 'Serpente Finestra',
    nameEn: 'Window Snake',
    descIt:
        'Forte, livello 16. RES 12 VOL 16 MAT 18 OCU 16. Il corpo è vetro opaco: passa dalle finestre e guarda da angoli impossibili. Ruolo: caccia isolati.',
    descEn: 'Strong opaque-glass snake.',
    elementId: 'specchio',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 16,
      'resilienza': 12,
      'volonta': 16,
      'materia': 18,
      'oculum': 16,
    },
    skillIds: ['window_bite', 'window_pass', 'window_reflect'],
    dropIds: ['vetro_opaco', 'dente_finestra'],
  ),
  MonsterBookEntry(
    id: 'papera_ranocchio',
    nameIt: 'Papera Ranocchio',
    nameEn: 'Duck Frog',
    descIt:
        'Creatura debole per chi inizia. Una rana con zampe da papera e una testa di papera che le esce dalla bocca. RES 2, VOL 1, MAT 1, OCU 1. Sembra assurda finché non ritrae la testa e la scaglia come un ariete: usa rinculo, salti storti e una risposta rabbiosa contro chi la colpisce. Drop: Piuma Bagnata, Zampa Palmata.',
    descEn: 'Beginner creature: a frog with duck legs and a duck head.',
    elementId: 'acqua',
    spriteAssetPath:
        'assets/oculum_dungeon/generated_sprites/enemies/papera_ranocchio.png',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 2,
      'volonta': 1,
      'materia': 1,
      'oculum': 1,
    },
    skillIds: [
      'duckfrog_recoil_headbutt',
      'duckfrog_frog_jump',
      'duckfrog_wet_retort',
    ],
    dropIds: ['piuma_bagnata', 'zampa_palmata'],
  ),
  MonsterBookEntry(
    id: 'strega_delle_fiale',
    nameIt: 'Strega delle Fiale',
    nameEn: 'Vial Witch',
    descIt:
        'Mini Boss alchimista. Materia 24, Oculum 12 e 5 Schivate Oculum. Non si ferma a lanciare magie: cura con l Oculum Art, prepara danno crescente per più turni e blocca chi prova a raggiungerla. Drop ottenibili: Fiala Veleno Putrido, Fiala Evasiva e Fiala della Creazione Goblin. Precisione usa già Materia/2 e copre mira e lancio delle fiale.',
    descEn: 'Alchemy mini boss with healing, stacking damage and stun.',
    elementId: 'oculum',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {'materia': 24, 'oculum': 12, 'schivateOculum': 5, 'precisione': 6},
    skillIds: ['witch_oculum_mend', 'witch_brewing_ruin', 'witch_stun_vial'],
    dropIds: [
      'fiala_veleno_putrido',
      'fiala_evasiva',
      'fiala_creazione_goblin',
    ],
  ),
  MonsterBookEntry(
    id: 'ragno_putrido',
    nameIt: 'Ragno Putrido',
    nameEn: 'Putrid Spider',
    descIt:
        'Mini Boss di livello 0. RES 10, VOL 10, MAT 0, OCU 10. Il suo Oculum Art non cerca il colpo grosso: distribuisce malus, poi riapre le ferite con il veleno finché Veleno Putrido sale di grado. La condizione può arrivare al grado IX e conserva le sue regole condivise: ignora Scudo e Difesa, infligge danno a fine turno e aumenta insieme a durata e pressione. Drop: Sacca di Veleno Putrido, Seta Marcescente.',
    descEn:
        'Level 0 mini boss. It spreads penalties and builds Rot Poison up to rank IX.',
    elementId: 'veleno',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 10,
      'volonta': 10,
      'materia': 0,
      'oculum': 10,
    },
    skillIds: ['putrid_oculum_art', 'rot_poison_escalation', 'miasma_web'],
    dropIds: ['sacca_veleno_putrido', 'seta_marcescente'],
  ),
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
  MonsterBookEntry(
    id: 'raccoglitore_di_chiodi',
    nameIt: 'Raccoglitore di Chiodi',
    nameEn: 'Nail Gatherer',
    descIt:
        'Umanoide debole, livello 1. Un uomo magro con un sacco pieno di chiodi piegati e un martello da banco. Ruolo: infastidisce la prima linea e recupera i propri chiodi. Inventario: martello da banco (+4 danni), cappotto cucito (+1 Difesa).',
    descEn: 'Weak humanoid nail gatherer.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 1,
      'resilienza': 3,
      'volonta': 2,
      'materia': 2,
      'oculum': 0,
    },
    skillIds: [
      'nailgatherer_throw',
      'nailgatherer_hammer',
      'nailgatherer_scramble',
    ],
    dropIds: ['chiodi_piegati', 'martello_da_banco'],
    canWieldWeapons: true,
    weaponTags: ['martello da banco'],
    armorTags: ['cappotto cucito'],
    inventoryItems: [
      {
        'nome': 'Martello da banco',
        'peso': 1.4,
        'quantita': 1,
        'note': 'Arma del Raccoglitore di Chiodi.',
        'arma': true,
        'equipaggiata': true,
        'bonusDanno': 4,
        'elementoDanno': 'Fisico',
      },
      {
        'nome': 'Cappotto cucito',
        'peso': 1.0,
        'quantita': 1,
        'note': 'Armatura leggera recuperata.',
        'protegge': true,
        'equipaggiata': true,
        'bonusDifesa': 1,
      },
    ],
  ),
  MonsterBookEntry(
    id: 'guardia_del_pozzo',
    nameIt: 'Guardia del Pozzo',
    nameEn: 'Well Guard',
    descIt:
        'Umanoide semplice, livello 6. Indossa una maschera di rame e custodisce un pozzo asciutto con una lancia smussata. Ruolo: tiene distanza e richiama chi prova a passare. Inventario: lancia da pozzo (+12 danni), scudo di tavole (+8 Scudo).',
    descEn: 'Low-tier humanoid well guard.',
    elementId: 'terra',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 6,
      'resilienza': 9,
      'volonta': 5,
      'materia': 5,
      'oculum': 2,
    },
    skillIds: ['wellguard_thrust', 'wellguard_hook', 'wellguard_wall'],
    dropIds: ['maschera_rame', 'punta_lancia_pozzo', 'corda_consunta'],
    canWieldWeapons: true,
    weaponTags: ['lancia da pozzo'],
    armorTags: ['scudo di tavole'],
    inventoryItems: [
      {
        'nome': 'Lancia da pozzo',
        'peso': 2.1,
        'quantita': 1,
        'note': 'Arma della Guardia del Pozzo.',
        'arma': true,
        'equipaggiata': true,
        'bonusDanno': 12,
        'elementoDanno': 'Fisico',
      },
      {
        'nome': 'Scudo di tavole',
        'peso': 2.5,
        'quantita': 1,
        'note': 'Scudo legato con corda.',
        'protegge': true,
        'equipaggiata': true,
        'bonusDifesa': 2,
        'bonusScudo': 8,
      },
    ],
  ),
  MonsterBookEntry(
    id: 'duellante_senza_palpebre',
    nameIt: 'Duellante Senza Palpebre',
    nameEn: 'Eyelidless Duelist',
    descIt:
        'Umanoide intermedio, livello 24. Non batte mai gli occhi e tiene due lame corte troppo lucide. Ruolo: sceglie un bersaglio isolato, lo legge e lo costringe a consumare reazioni. Inventario: coppia di lame lucide (+34 danni), giubba di cuoio nero (+7 Difesa).',
    descEn: 'Intermediate eyelidless humanoid duelist.',
    elementId: 'tagliente',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 24,
      'resilienza': 27,
      'volonta': 21,
      'materia': 24,
      'oculum': 17,
    },
    skillIds: ['eyelidless_read', 'eyelidless_crosscut', 'eyelidless_riposte'],
    dropIds: ['lama_lucida', 'pelle_oculare_secca', 'giubba_nera'],
    canWieldWeapons: true,
    weaponTags: ['coppia di lame lucide'],
    armorTags: ['giubba di cuoio nero'],
    inventoryItems: [
      {
        'nome': 'Coppia di lame lucide',
        'peso': 1.7,
        'quantita': 1,
        'note': 'Armi del Duellante Senza Palpebre.',
        'arma': true,
        'equipaggiata': true,
        'bonusDanno': 34,
        'elementoDanno': 'Tagliente',
      },
      {
        'nome': 'Giubba di cuoio nero',
        'peso': 2.3,
        'quantita': 1,
        'note': 'Armatura del duellante.',
        'protegge': true,
        'equipaggiata': true,
        'bonusDifesa': 7,
      },
    ],
  ),
  MonsterBookEntry(
    id: 'capitano_della_ruggine',
    nameIt: 'Capitano della Ruggine',
    nameEn: 'Rust Captain',
    descIt:
        'Umanoide potente, livello 58. Una corazza ossidata cresce direttamente nelle sue costole; usa una sciabola larga come una pala. Ruolo: comanda il centro, spezza scudi e non insegue chi fugge. Inventario: sciabola arrugginita (+62 danni), corazza costolare (+22 Difesa, +30 Scudo).',
    descEn: 'Powerful rust-armored humanoid captain.',
    elementId: 'ruggine',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {
      'level': 58,
      'resilienza': 70,
      'volonta': 54,
      'materia': 49,
      'oculum': 42,
    },
    skillIds: ['rustcaptain_order', 'rustcaptain_cleave', 'rustcaptain_plate'],
    dropIds: ['scaglia_ruggine', 'elsa_capitano', 'costola_corazzata'],
    canWieldWeapons: true,
    weaponTags: ['sciabola arrugginita'],
    armorTags: ['corazza costolare'],
    inventoryItems: [
      {
        'nome': 'Sciabola arrugginita',
        'peso': 4.2,
        'quantita': 1,
        'note': 'Arma del Capitano della Ruggine.',
        'arma': true,
        'equipaggiata': true,
        'bonusDanno': 62,
        'elementoDanno': 'Ruggine',
        'gradoOggetto': 7,
        'gradoRichiesto': 7,
      },
      {
        'nome': 'Corazza costolare',
        'peso': 7.0,
        'quantita': 1,
        'note': 'Corazza cresciuta sulle costole.',
        'protegge': true,
        'equipaggiata': true,
        'bonusDifesa': 22,
        'bonusScudo': 30,
        'gradoOggetto': 7,
        'gradoRichiesto': 7,
      },
    ],
  ),
  MonsterBookEntry(
    id: 'uomo_del_martello_lungo',
    nameIt: 'Uomo del Martello Lungo',
    nameEn: 'Long Hammer Man',
    descIt:
        'Umanoide davvero potente, livello 100. È alto e magro ma il braccio destro termina in un martello telescopico; nessuno sa dove finisca il suo gomito. Ruolo: boss da corridoio, controlla distanza, rompe pareti e punisce chi resta vicino. Inventario: Martello Lungo (+90 danni), mantello di placche (+34 Difesa, +55 Scudo).',
    descEn: 'Level 100 humanoid with a telescopic hammer.',
    elementId: 'impatto',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {
      'level': 100,
      'resilienza': 120,
      'volonta': 92,
      'materia': 86,
      'oculum': 78,
    },
    skillIds: ['longhammer_reach', 'longhammer_recoil', 'longhammer_wall'],
    dropIds: ['asta_telescopica', 'testa_martello_lunga', 'placca_fredda'],
    canWieldWeapons: true,
    weaponTags: ['Martello Lungo'],
    armorTags: ['mantello di placche'],
    inventoryItems: [
      {
        'nome': 'Martello Lungo',
        'peso': 9.0,
        'quantita': 1,
        'note': 'Arma del livello 100 Uomo del Martello Lungo.',
        'arma': true,
        'equipaggiata': true,
        'bonusDanno': 90,
        'elementoDanno': 'Impatto',
        'gradoOggetto': 12,
        'gradoRichiesto': 12,
      },
      {
        'nome': 'Mantello di placche',
        'peso': 10.0,
        'quantita': 1,
        'note': 'Difesa a placche del livello 100.',
        'protegge': true,
        'equipaggiata': true,
        'bonusDifesa': 34,
        'bonusScudo': 55,
        'gradoOggetto': 12,
        'gradoRichiesto': 12,
      },
    ],
  ),
  MonsterBookEntry(
    id: 'armaiolo_della_fila_lunga',
    nameIt: 'Armaiolo della Fila Lunga',
    nameEn: 'Long Rank Armorer',
    descIt:
        'Boss umanoide della stessa stirpe dei raccoglitori e delle guardie, livello 82. La sua pelle sembra una sala d armi: ganci, foderi e piastre si aprono lungo braccia e schiena. Comanda la Fila Lunga scegliendo stile a ogni turno: picca e lancia per tenere distanza, spada e scudo per il duello, alabarda per il controllo, balestra per punire da lontano, enormi guanti d arme per spezzare Difesa e Scudi. Inventario completo: ogni arma è reale e trasferibile quando lo crei come scheda.',
    descEn:
        'Level 82 humanoid commander with shifting medieval and fantasy weapons.',
    elementId: 'acciaio',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {
      'level': 82,
      'resilienza': 98,
      'volonta': 78,
      'materia': 74,
      'oculum': 66,
    },
    skillIds: ['longrank_style', 'longrank_gauntlets', 'longrank_command'],
    dropIds: [
      'chiave_fonderia',
      'guanto_d_arme_gigante',
      'manuale_della_fila_lunga',
    ],
    canWieldWeapons: true,
    weaponTags: [
      'spada lunga',
      'lancia',
      'picca',
      'alabarda',
      'mazza ferrata',
      'ascia bipenne',
      'balestra',
      'guanti d arme enormi',
    ],
    armorTags: ['scudo torre', 'corazza a piastre'],
    inventoryItems: [
      {
        'nome': 'Spada lunga della Fila',
        'peso': 2.8,
        'quantita': 1,
        'note': 'Stile duello: taglio affidabile.',
        'arma': true,
        'equipaggiata': true,
        'bonusDanno': 48,
        'elementoDanno': 'Tagliente',
        'gradoOggetto': 10,
        'gradoRichiesto': 10,
      },
      {
        'nome': 'Lancia da fila',
        'peso': 3.1,
        'quantita': 1,
        'note': 'Stile portata: colpisce oltre la prima linea.',
        'arma': true,
        'bonusDanno': 44,
        'elementoDanno': 'Perforante',
        'gradoOggetto': 10,
        'gradoRichiesto': 10,
      },
      {
        'nome': 'Picca a ganci',
        'peso': 4.5,
        'quantita': 1,
        'note': 'Stile tenuta: aggancia e sposta.',
        'arma': true,
        'bonusDanno': 50,
        'elementoDanno': 'Perforante',
        'gradoOggetto': 10,
        'gradoRichiesto': 10,
      },
      {
        'nome': 'Alabarda di ferro freddo',
        'peso': 5.0,
        'quantita': 1,
        'note': 'Stile controllo: taglio, punta e aggancio.',
        'arma': true,
        'bonusDanno': 56,
        'elementoDanno': 'Acciaio',
        'gradoOggetto': 10,
        'gradoRichiesto': 10,
      },
      {
        'nome': 'Balestra di fonderia',
        'peso': 4.0,
        'quantita': 1,
        'note': 'Stile distanza: punisce chi fugge.',
        'arma': true,
        'bonusDanno': 52,
        'elementoDanno': 'Perforante',
        'gradoOggetto': 10,
        'gradoRichiesto': 10,
      },
      {
        'nome': 'Guanti d arme enormi',
        'peso': 8.0,
        'quantita': 1,
        'note':
            'Stile spezzascudi: enormi guanti fantasy per urtare corazze e Scudi.',
        'arma': true,
        'bonusDanno': 68,
        'elementoDanno': 'Impatto',
        'gradoOggetto': 11,
        'gradoRichiesto': 11,
      },
      {
        'nome': 'Scudo torre della Fila',
        'peso': 9.0,
        'quantita': 1,
        'note': 'Scudo da comando.',
        'protegge': true,
        'equipaggiata': true,
        'bonusDifesa': 28,
        'bonusScudo': 48,
        'gradoOggetto': 10,
        'gradoRichiesto': 10,
      },
      {
        'nome': 'Corazza a piastre di fonderia',
        'peso': 13.0,
        'quantita': 1,
        'note': 'Armatura del comandante.',
        'protegge': true,
        'equipaggiata': true,
        'bonusDifesa': 30,
        'bonusScudo': 36,
        'gradoOggetto': 10,
        'gradoRichiesto': 10,
      },
    ],
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
            '${entry.descIt}\n\nSkill per il giocatore:\n${entry.skillIds.asMap().entries.map((skill) => 'Livello richiesto ${monsterBookSkillRequiredLevel(entry, skill.key)} — ${monsterBookSkillText(skill.value)}').join('\n')}',
        descEn:
            '${entry.descEn}\n\nPlayer skills:\n${entry.skillIds.asMap().entries.map((skill) => 'Required level ${monsterBookSkillRequiredLevel(entry, skill.key)} — ${monsterBookSkillText(skill.value)}').join('\n')}',
      ),
    )
    .toList(growable: false);

/// Il Book non mostra più sigle tecniche come skill: ogni forma parla a chi la
/// usa. Le schede create dal giocatore possono comunque sostituire il testo.
String monsterBookSkillText(String rawId) {
  final id = rawId.replaceAll('_', ' ').trim();
  final label = id.isEmpty ? 'Tecnica del mostro' : id;
  final baseId = rawId.trim().toLowerCase().replaceFirst(
    RegExp(r'_variante_[a-z]+$'),
    '',
  );
  switch (baseId) {
    case 'goblin_killer_finish':
      return 'finire il bersaglio — I/colpisci un nemico già ferito; II/se lo abbatti recuperi tutta la Vita; III/dopo l uccisione puoi spostarti, ma la cura non si attiva su Scudi o evocazioni già dissolte.';
    case 'archangel_strike':
      return 'colpo dell arcangelo — I/attacco di luce; II/linea corta; III/pressione su un bersaglio giudicato.';
    case 'archangel_guard':
      return 'guardia dell arcangelo — I/copertura; II/copertura di gruppo; III/risposta protettiva dopo il primo colpo.';
    case 'archangel_order':
      return 'ordine dell arcangelo — I/un alleato si muove o si difende; II/due alleati; III/una reazione nemica viene negata.';
    case 'pinepine_cone_skin':
      return 'pelle di pigna — I/dimezzi danni non di Fuoco; II/proteggi un alleato vicino; III/se Fuoco o simili ti colpiscono, esplodi entro 2 metri e ferisci anche gli alleati. Debole a Ferite Aperte e Fuoco.';
    case 'lesser_frost_demon_cold_blood':
      return 'sangue freddo — I/chi ti ferisce in mischia riceve Congelamento; II/Ricordo Vitale prepara la cura; III/la reazione fredda colpisce anche chi insiste a restare vicino.';
    case 'intermediate_frost_demon_ray':
      return 'raggio glaciale — I/spendi Oculum per un raggio congelante a distanza; II/due raggi o una linea più lunga; III/il bersaglio congelato resta esposto alla prossima pressione.';
    case 'greater_frost_demon_time_freeze':
      return 'open tempo ghiacciato — I/congeli il tempo per un turno: tutti vedono e sentono; II/i danni restano accumulati; III/alla fine arrivano insieme. Non cancella le difese applicate prima del congelamento.';
    case 'scourging_angel_lash':
      return 'frusta del giudizio — I/colpisci con una frusta di luce; II/il colpo raggiunge due nemici vicini; III/il bersaglio giudicato riceve anche la pressione dell ala. Ogni 6 livelli il Fustigatore aggiunge +50 Danni base.';
    case 'scourging_angel_judgement':
      return 'giudizio fustigatore — I/marchi un bersaglio e prepari il prossimo colpo; II/la marca riduce la sua difesa; III/la marca esplode se prova a ferire un alleato. Ogni 5 livelli il Fustigatore ottiene +20 Difesa base.';
    case 'scourging_angel_wing_guard':
      return 'guardia d ali — I/usi lo Scudo Critico per proteggerti; II/proteggi anche un alleato vicino; III/respinge chi forza la guardia.';
    case 'protective_angel_intercept':
      return 'intercettazione celeste — I/prendi su di te il prossimo danno diretto a un compagno; II/puoi farlo per due compagni vicini; III/il danno trasferito è ridotto dalla tua Difesa e dai tuoi Scudi normalmente.';
    case 'protective_angel_wing_wall':
      return 'muro d ali — I/copertura per un alleato; II/copertura per una linea; III/chi attraversa il muro perde la reazione, ma l Angelo resta esposto sul lato opposto.';
    case 'protective_angel_vow':
      return 'voto protettore — I/scegli un compagno da custodire; II/ottieni vantaggio quando intercetti per lui; III/se cade a 0 Vita puoi prendere il colpo che lo avrebbe abbattuto, una volta per scontro.';
    case 'seraph_wing_lance':
      return 'lancia delle ali — I/colpisci da lontano con luce angelica; II/attraversi una linea di bersagli; III/la lancia divide l area, ma richiede una linea visibile.';
    case 'seraph_halo_command':
      return 'comando dell aureola — I/ordini a un alleato di muoversi o difendersi; II/due alleati ricevono il comando; III/impedisci una reazione nemica nella zona, ma il Serafino resta il bersaglio più evidente.';
    case 'seraph_six_wing_aegis':
      return 'egida delle sei ali — I/crei una difesa celeste; II/la difesa copre il gruppo vicino; III/la prima offensiva contro l egida viene respinta, ma l egida termina dopo il colpo.';
    case 'bomber_skeleton_bone_bomb':
      return 'bomba d osso — I/lanci un osso carico in una piccola area: infligge il 35% della Vita attuale, senza ridurre sotto 1; II/45% in area media; III/50% in area ampia. È semi-letale: non può uccidere solo con questa detonazione.';
    case 'bomber_skeleton_shrapnel_ring':
      return 'anello di schegge — I/schegge in un area vicina: 25% della Vita attuale; II/35% e rallenta chi resta nella zona; III/45%, ma il Bombarolo si espone dopo il lancio.';
    case 'bomber_skeleton_last_blast':
      return 'ultima esplosione — I/quando è quasi distrutto, colpisce l area per 30% della Vita attuale; II/40%; III/50%. Ogni bersaglio resta almeno a 1 Vita.';
    case 'observer_witness_copy':
      return 'copia testimoniata — I/copi la prossima Skill che vedi; II/la conservi per due usi; III/copi anche una Forma scritta. Mantieni costo, limiti e conseguenze della Skill originale.';
    case 'observer_white_analysis':
      return 'analisi bianca — I/scopri costo e limite di una Skill vista; II/ottieni vantaggio per copiarla; III/scopri quale condizione la interrompe, ma resti fermo a osservare.';
    case 'observer_replay':
      return 'replica — I/usi una Skill copiata; II/ne usi due viste diverse in turni consecutivi; III/combini due copie compatibili, pagando entrambi i costi e rispettando ogni limite.';
    case 'immortal_life_harvest':
      return 'mietitura vitale — I/ogni danno che raggiunge davvero la Vita cura l Immortale dello stesso valore; II/la cura ripara anche una ferita recente; III/la cura eccedente crea HP temporanei. Danni assorbiti dagli Scudi non contano.';
    case 'immortal_relentless_cut':
      return 'taglio incessante — I/colpisci e applichi Mietitura Vitale; II/se raggiungi la Vita, insegui il bersaglio; III/se il bersaglio è già ferito, il danno alla Vita aumenta senza ignorare Scudi o Difesa.';
    case 'immortal_undying_stance':
      return 'posa imperitura — I/finché attiva, la prima Mietitura Vitale del turno cura anche 10 Difesa; II/20 Difesa; III/30 Difesa, ma rinunci alle reazioni mentre la mantieni.';
    case 'demon_lesser_harden':
      return 'corpo indurito — I/spendi Oculum per +30 Difesa fino al tuo turno; II/+60 Difesa e respingi chi ti colpisce in mischia; III/+100 Difesa e copri un alleato adiacente.';
    case 'demon_lesser_ward':
      return 'guardia istintiva — I/assorbi il prossimo colpo; II/la guardia copre anche un alleato; III/chi la spezza riceve una breve onda d urto.';
    case 'demon_lesser_crush':
      return 'schianto bruto — I/potenzi il pugno per +20 danni; II/+45 danni e sbilanci; III/+80 danni, rinunciando alla guardia nello stesso turno.';
    case 'demon_intermediate_harden':
      return 'fame corazzata — I/+40 Difesa; II/+75 Difesa e il primo colpo subito alimenta la prossima sfera; III/+120 Difesa e resistenza agli spostamenti.';
    case 'demon_intermediate_aegis_sphere':
      return 'sfera di difesa — I/assorbe 50 danni; II/100 danni e copre un alleato; III/160 danni e ferisce chi la attraversa.';
    case 'demon_intermediate_pressure_sphere':
      return 'sfera di pressione — I/+30 danni; II/+60 e con tiro positivo su Pressione espandi l area; III/+110, l area espansa respinge.';
    case 'demon_greater_dominion':
      return 'dominio demoniaco — I/+60 Difesa; II/+120 e un demone minore vicino non può sottrarsi; III/+180 e spezzi la sua guardia.';
    case 'demon_greater_devour':
      return 'divora il debole — I/divori un demone o evocazione sconfitto e recuperi 15 Oculum; II/30 Oculum e 60 Scudo; III/50 Oculum, 120 Scudo e +40 danni al prossimo colpo.';
    case 'demon_greater_hell_aegis':
      return 'egida infernale — I/barriera da 120 Scudo; II/220 e sfere alleate più resistenti; III/350 e +100 danni a chi la forza.';
    case 'solar_swarm':
      return 'solar swarm — I/dirigi un piccolo sciame solare contro un bersaglio o la casella vicina: lo pressa con più colpi leggeri e ne disturba la guardia; II/lo sciame raggiunge due bersagli vicini oppure continua a premere lo stesso bersaglio; III/chiudi il bersaglio in una corona di luce che lo colpisce ripetutamente, ma lo sciame resta esposto alle reazioni ad area fino al tuo turno successivo.';
    case 'golden_pin':
      return 'golden pin — I/lanci una spina d oro e armatura nera che ferisce e inchioda per un istante il bersaglio o un suo oggetto; II/aumenti la distanza oppure fissi due bersagli vicini, rendendo più difficile spostarsi o reagire; III/immobilizzi il bersaglio finché non si libera con un azione o un aiuto, ma la spina resta visibile e può essere spezzata.';
    case 'wing_flash':
      return 'wing flash — I/apri le ali dorate in un lampo: abbagli un bersaglio vicino e guadagni spazio per difenderti o riposizionarti; II/il lampo investe più bersagli vicini oppure protegge un alleato dalla prossima pressione; III/crei un bagliore accecante che interrompe le reazioni nella zona fino al turno successivo, ma rivela con chiarezza la tua posizione.';
    case 'putrid_oculum_art':
      return 'oculum art putrida — I/spendi il tuo Oculum per imporre a un bersaglio un malus breve: rallentamento, difesa incrinata o reazione negata; II/colpisci due bersagli vicini oppure applichi due malus diversi allo stesso bersaglio; III/finché il bersaglio porta almeno un malus, la prossima applicazione di Veleno Putrido non può essere convertita in un semplice danno diretto. Il Ragno rinuncia all attacco fisico mentre tesse questa pressione.';
    case 'assassin_snail_slime':
      return 'bava assassina — I/sputi saliva: chi colpisci perde una Reazione; II/la scia dietro di te infligge Senza Reazioni a chi la attraversa fino al turno successivo; III/la bava resta in una zona e chi vi entra perde anche una Reazione veloce.';
    case 'assassin_snail_shell':
      return 'guscio roteante borchiato — I/ti chiudi e ruoti: +6 danni e +2 Difesa; II/+14 danni e +5 Difesa mentre avanzi; III/+26 danni, +9 Difesa e respingi chi tenta di fermarti, ma non puoi sputare bava nello stesso turno.';
    case 'assassin_snail_memory':
      return 'ricordo vitale nel guscio — I/reazione, spendi 2 Oculum: inserisci un ricordo nel guscio, +5 Vita e +2 Difesa cumulabili; II/dal livello successivo costa 3 Oculum e il ricordo protegge anche la Lumaca da un malus lieve; III/costa 5 Oculum, conserva due ricordi e alla rottura del guscio restituisce una Reazione. Ricordo Vitale: ogni carica resta finché il guscio non viene spezzato.';
    case 'rot_poison_escalation':
      return 'veleno putrido crescente — I/mordi o chiudi il bersaglio nella seta e applichi Veleno Putrido I; II/se il bersaglio ne soffre già, aumenti il grado di uno invece di duplicare la condizione; III/puoi portarlo progressivamente fino a Veleno Putrido IX. Ogni grado usa danno e durata della condizione condivisa, ignora Scudo e Difesa e agisce a fine turno: non oltrepassa mai il suo cap anti-morte istantanea.';
    case 'miasma_web':
      return 'ragnatela di miasma — I/ancori una ragnatela a un bersaglio o a un passaggio: rallenta e rende più difficile liberarsi dai malus; II/la ragnatela raggiunge una piccola area e chi vi resta riceve il prossimo malus del Ragno; III/chi è già avvelenato deve scegliere se uscire dalla zona o perdere una reazione, ma la seta può essere spezzata da un alleato con un azione.';
    case 'witch_oculum_mend':
      return 'rimedio d occhio — I/usi Oculum Art per curare te o un alleato; II/la cura rimuove anche un malus lieve; III/la fiala spezzata cura due creature vicine, ma consuma la tua reazione.';
    case 'witch_brewing_ruin':
      return 'infuso di rovina — I/marchi un bersaglio: riceve danno aumentato fino al tuo prossimo turno; II/riapplicando accumuli un secondo grado e prolunghi l effetto; III/il terzo grado esplode in danno maggiore, poi l infuso termina: non puoi conservarlo indefinitamente.';
    case 'witch_stun_vial':
      return 'fiala stordente — I/colpisci e togli una reazione; II/il bersaglio è Stordito fino al suo prossimo turno; III/la rottura investe una piccola area, ma gli alleati devono allontanarsi per non respirarla.';
    case 'duckfrog_recoil_headbutt':
      return 'testata con rinculo — I/ritrai la testa di papera nella gola, la allunghi e colpisci: infliggi +5 + Oculum danni (1/4); II/+12 + Oculum danni (2/4) e il rinculo ti sposta fuori dalla risposta; III/+25 + Oculum danni (3/4), respingi il bersaglio e tu rimbalzi in una zona vicina. Al quarto uso la testa resta incastrata fino al turno successivo.';
    case 'duckfrog_frog_jump':
      return 'salto a rana — I/salti sopra una minaccia e il nemico bersagliato aggiunge +3 a CM + Oculum fino al suo prossimo tiro; II/il salto attraversa due zone e il bonus diventa +8 + Oculum; III/atterri alle spalle, il bonus diventa +16 + Oculum e neghi una reazione, ma devi avere spazio per il rinculo.';
    case 'duckfrog_wet_retort':
      return 'starnazzo di risposta — I/quando una creatura ti colpisce, ottieni una reazione aggiuntiva contro di lei: le spruzzi acqua e la rallenti; II/la risposta infligge anche +8 danni e la sposta; III/+18 danni, una breve apertura per gli alleati e puoi usare la risposta anche dopo un colpo a distanza. DT 2 turni: non puoi riattivarla prima della fine del secondo turno.';
    case 'handrat_face_pull':
      return 'tira il viso — I/salti sul bersaglio, afferri pelle e palpebre: @VC+3 e +4 danni taglienti; II/+7 danni e se colpisci applichi Precisione -2; III/+12 danni e il bersaglio perde una reazione finché si libera.';
    case 'handrat_fingers_inside':
      return 'dita dentro — I/DT 2: infili le dita in una ferita aperta, @VC+2 e +6 danni perforanti; II/contro un ferito aggiungi +3 danni; III/+12 danni contro chi ha due condizioni fisiche, ma resti esposto se fallisci.';
    case 'handrat_skin_leave':
      return 'lascia la pelle — I/DT 3: quando sei afferrato strappi pelle e scivoli via, @CM+5; II/attraversi anche una zona minacciata; III/lasci una falsa sagoma che assorbe il prossimo colpo. Subisci sempre +2 danni a te stesso.';
    case 'centieye_lid_bite':
      return 'morso delle palpebre — I/le palpebre si aprono verticalmente: @VC+2 e +3 danni perforanti; II/+7 danni e impedisci una reazione; III/+12 danni e il bersaglio resta Esposto fino al turno successivo.';
    case 'centieye_stare':
      return 'fissa — I/(1/4) la pupilla segue ogni gesto: DT 9 + OCU; II/il fallimento infligge VC -3 per 1 turno; III/il fallimento nega anche il prossimo tiro di precisione, ma lo sguardo termina se vieni colpito.';
    case 'centieye_under_clothes':
      return 'sotto i vestiti — I/reazione, DT 2: corri sotto gambe, stoffa e armature prima del colpo, @CM+4; II/il colpo manca e ti sposti; III/puoi anche applicare una breve distrazione al bersaglio che ti ha attaccato.';
    case 'nailgatherer_throw':
      return 'pioggia di chiodi — I/Livello 1: lanci chiodi piegati, +4 danni e rallenti un passo; II/+8 danni su una piccola zona; III/chi entra nella zona perde una Reazione per estrarli.';
    case 'nailgatherer_hammer':
      return 'martello da banco — I/Livello 1: +4 danni; II/+8 e incrini uno Scudo; III/+12 contro chi è già rallentato.';
    case 'nailgatherer_scramble':
      return 'raccogli e scappa — I/Livello 1: recuperi un chiodo e @CM+2; II/recuperi due chiodi; III/lasci il sacco come esca, ma perdi la prossima offensiva.';
    case 'wellguard_thrust':
      return 'punta del pozzo — I/Livello 6: la lancia infligge +12 danni a portata; II/+20 e spingi indietro; III/+28 se il bersaglio attraversa il cordone della Guardia.';
    case 'wellguard_hook':
      return 'gancio di corda — I/Livello 6: agganci e tiri un bersaglio; II/nega una Reazione; III/lo trascini vicino al bordo senza farlo cadere automaticamente.';
    case 'wellguard_wall':
      return 'muro di tavole — I/Livello 6: +8 Scudo; II/copre un alleato; III/chi lo rompe riceve una spinta e resta Esposto.';
    case 'eyelidless_read':
      return 'lettura senza palpebre — I/Livello 24: osservi un bersaglio, +4 Precisione contro di lui; II/prevedi una Reazione; III/il suo primo fallimento nel turno lascia Difesa -4.';
    case 'eyelidless_crosscut':
      return 'taglio incrociato — I/Livello 24: +34 danni taglienti; II/+48 e consumi una Reazione; III/+66 se il bersaglio è isolato.';
    case 'eyelidless_riposte':
      return 'risposta lucida — I/Livello 24, reazione: dopo un mancato colpo contro di te, attacchi; II/+20 danni; III/sposti il duello di una zona.';
    case 'rustcaptain_order':
      return 'ordine della ruggine — I/Livello 58: un alleato umanoide ottiene +10 Difesa; II/due alleati ottengono +20; III/uno può reagire subito, ma il Capitano resta esposto al tiro a distanza.';
    case 'rustcaptain_cleave':
      return 'sciabola da pala — I/Livello 58: +62 danni; II/+78 su una linea corta; III/+96 e spezza 20 Scudo prima della Difesa.';
    case 'rustcaptain_plate':
      return 'costole di ruggine — I/Livello 58: +22 Difesa e 30 Scudo; II/chi ti colpisce in mischia ottiene Ruggine lieve; III/resisti a una spinta, ma perdi mobilità.';
    case 'longhammer_reach':
      return 'martello telescopico — I/Livello 100: +90 danni a distanza insolita; II/+120 e respingi; III/+160 contro una parete o una linea, ma il martello deve rientrare nel turno successivo.';
    case 'longhammer_recoil':
      return 'rinculo di gomito — I/Livello 100, reazione: dopo un colpo subito spingi l attaccante; II/+45 danni; III/rompi anche 30 Scudo e cambi posizione.';
    case 'longhammer_wall':
      return 'colpo al corridoio — I/Livello 100: danneggi una copertura o blocchi un passaggio; II/la zona diventa difficile; III/una parete fragile cede, senza cancellare automaticamente chi ci sta dietro.';
    case 'longrank_style':
      return 'stile della Fila Lunga — I/Livello 82: scegli spada, lancia, picca, alabarda, balestra o mazza per il turno; II/l arma scelta guadagna +18 danni nel suo ruolo; III/cambi stile come reazione dopo aver visto il bersaglio, ma non puoi usare due armi nello stesso colpo.';
    case 'longrank_gauntlets':
      return 'guanti d arme enormi — I/Livello 82: +68 danni da impatto e -12 Scudo al bersaglio; II/+88 danni e lo sposti; III/+112, incrini anche la Difesa, ma perdi l uso della balestra fino al turno successivo.';
    case 'longrank_command':
      return 'comando dell armaiolo — I/Livello 82: un umanoide alleato cambia stile o ottiene una Reazione; II/due alleati ricevono +12 Difesa; III/la Fila Lunga avanza insieme e controlla una zona, ma il comandante è il bersaglio evidente.';
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
  _withoutDefaultMonsterImages(
    _withMonsterSkillNarration(
      _withMonsterVariants(
        _withFallbackMonsterSkills(
          _humanizeLegacyMonsterEntries([
            ..._craftedMonsterBookEntries,
            ..._manualMonsterBookEntries,
            ..._generateMonsterTier(
              count: targetNormalMonsterCount - _staticNormalMonsterCount < 2
                  ? 2
                  : targetNormalMonsterCount - _staticNormalMonsterCount,
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
    ),
  ),
);

/// I mostri forniti dall'app nascono come descrizioni visive, non come
/// ritratti imposti. Un Master o un giocatore puo aggiungere in seguito una
/// propria immagine alla singola voce personalizzata, senza toccarne l'ID.
List<MonsterBookEntry> _withoutDefaultMonsterImages(
  Iterable<MonsterBookEntry> entries,
) => List<MonsterBookEntry>.unmodifiable(
  entries.map((entry) => entry.copyWith(spriteAssetPath: '', imageBase64: '')),
);

/// Ogni mostro possiede anche una variante stabile, non un doppione grafico.
/// La variante conserva ID, drop, armi e compatibilità del capostipite,
/// aumentando solo ciò che serve a cambiare davvero il ruolo nello scontro.
List<MonsterBookEntry> _withMonsterVariants(
  Iterable<MonsterBookEntry> entries,
) {
  const styles = <({String id, String label, String role})>[
    (
      id: 'errante',
      label: 'Errante',
      role: 'si muove tra le linee e punisce chi resta isolato',
    ),
    (
      id: 'corazzata',
      label: 'Corazzata',
      role: 'protegge un passaggio e forza il gruppo a consumare Difesa',
    ),
    (
      id: 'rituale',
      label: 'Rituale',
      role: 'prepara il terreno con Oculum prima di colpire',
    ),
    (
      id: 'veterana',
      label: 'Veterana',
      role: 'alterna le sue tecniche senza ripetere la stessa apertura',
    ),
  ];
  final result = <MonsterBookEntry>[];
  for (final entry in entries) {
    result.add(entry);
    if (entry.id.contains('_variante_')) continue;
    final score = entry.id.codeUnits.fold<int>(0, (sum, code) => sum + code);
    final style = styles[score % styles.length];
    final level = entry.stats['level'] ?? 0;
    final bonus = entry.isBoss
        ? 16
        : entry.isMiniBoss
        ? 9
        : 4;
    final stats = <String, int>{
      for (final pair in entry.stats.entries)
        pair.key: switch (pair.key) {
          'level' => min(100, max(0, pair.value + (entry.isBoss ? 8 : 3))),
          'resilienza' ||
          'volonta' ||
          'materia' ||
          'oculum' => pair.value + bonus,
          'hp' => pair.value + bonus * 12,
          'atk' => pair.value + bonus * 2,
          'def' => pair.value + bonus * 2,
          _ => pair.value,
        },
    };
    result.add(
      entry.copyWith(
        id: '${entry.id}_variante_${style.id}',
        nameIt: '${entry.nameIt} ${style.label}',
        nameEn: '${entry.nameEn} ${style.label}',
        descIt:
            'Variante ${style.label.toLowerCase()} (dal livello $level): ${style.role}. ${entry.descIt}',
        descEn: '${style.label} variant of ${entry.nameEn}. ${entry.descEn}',
        stats: stats,
        skillIds: entry.skillIds
            .map((skill) => '${skill}_variante_${style.id}')
            .toList(growable: false),
        dropIds: [...entry.dropIds, 'frammento_variante_${style.id}'],
      ),
    );
  }
  return result;
}

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
              inventoryItems: monster.inventoryItems,
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

/// Le Art dei mostri non sono tutte disponibili al livello zero. La soglia
/// usa potenza e tenuta della creatura, senza alterare le Skill legacy.
int monsterBookSkillRequiredLevel(MonsterBookEntry monster, int skillIndex) {
  final stats = monster.stats;
  final power = max(
    stats['atk'] ?? stats['danno'] ?? 0,
    (stats['oculum'] ?? 0) * 2 + (stats['materia'] ?? 0),
  );
  final defense = stats['defense'] ?? stats['def'] ?? 0;
  final base = stats['level'] ?? 0;
  final weight = power ~/ 25 + defense ~/ 60;
  final stage = skillIndex.clamp(0, 2);
  return max(base, base + weight + stage * max(1, 1 + weight ~/ 3));
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
