part of '../oculum_dungeon_game.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element, unused_element_parameter, curly_braces_in_flow_control_structures

class _OculumBattleDominantDef {
  const _OculumBattleDominantDef({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.titleIt,
    required this.titleEn,
    required this.descIt,
    required this.descEn,
    required this.effectIt,
    required this.effectEn,
    required this.spriteKind,
    required this.color,
    required this.baseHp,
    required this.power,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String titleIt;
  final String titleEn;
  final String descIt;
  final String descEn;
  final String effectIt;
  final String effectEn;
  final String spriteKind;
  final Color color;
  final int baseHp;
  final int power;
}

class _OculumBattleTroopDef {
  const _OculumBattleTroopDef({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.spriteKind,
    required this.color,
    required this.rarity,
    required this.baseHp,
    required this.baseDamage,
    required this.armor,
    required this.speed,
    required this.cost,
    this.isPet = false,
    this.buffHp = 0,
    this.buffDamage = 0,
    this.spawns = 0,
    this.arenaId = 'general',
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;
  final String spriteKind;
  final Color color;
  final String rarity;
  final int baseHp;
  final int baseDamage;
  final int armor;
  final int speed;
  final int cost;
  final bool isPet;
  final int buffHp;
  final int buffDamage;
  final int spawns;
  final String arenaId;
}

class _OculumBattleArenaDef {
  const _OculumBattleArenaDef({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.color,
    required this.shadowColor,
    required this.hpDelta,
    required this.damageDelta,
    required this.pressureDelta,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;
  final Color color;
  final Color shadowColor;
  final int hpDelta;
  final int damageDelta;
  final int pressureDelta;
}

class _OculumBattleRulerTitleDef {
  const _OculumBattleRulerTitleDef({
    required this.dominantId,
    required this.secretIt,
    required this.secretEn,
    required this.nameIt,
    required this.nameEn,
    required this.triggerIt,
    required this.triggerEn,
  });

  final String dominantId;
  final String secretIt;
  final String secretEn;
  final String nameIt;
  final String nameEn;
  final String triggerIt;
  final String triggerEn;
}

class _OculumBattleArtDef {
  const _OculumBattleArtDef({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.rarityIt,
    required this.rarityEn,
    required this.descIt,
    required this.descEn,
    required this.color,
    required this.baseUses,
    required this.skillIds,
    this.arenaId = 'general',
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String rarityIt;
  final String rarityEn;
  final String descIt;
  final String descEn;
  final Color color;
  final int baseUses;
  final List<String> skillIds;
  final String arenaId;
}

class _OculumBattleArtSkillDef {
  const _OculumBattleArtSkillDef({
    required this.id,
    required this.artId,
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.icon,
    required this.color,
    this.defiledCost = 0,
  });

  final String id;
  final String artId;
  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;
  final IconData icon;
  final Color color;
  final int defiledCost;
}

class _OculumBattleArenaPackDef {
  const _OculumBattleArenaPackDef({
    required this.arenaId,
    required this.prefix,
    required this.dominantNameIt,
    required this.dominantNameEn,
    required this.dominantTitleIt,
    required this.dominantTitleEn,
    required this.unitThemeIt,
    required this.unitThemeEn,
    required this.artNameIt,
    required this.artNameEn,
    required this.skillOneIt,
    required this.skillOneEn,
    required this.skillTwoIt,
    required this.skillTwoEn,
    required this.petNameIt,
    required this.petNameEn,
    required this.titleNameIt,
    required this.titleNameEn,
    required this.color,
    required this.shadowColor,
    this.exploder = false,
  });

  final String arenaId;
  final String prefix;
  final String dominantNameIt;
  final String dominantNameEn;
  final String dominantTitleIt;
  final String dominantTitleEn;
  final String unitThemeIt;
  final String unitThemeEn;
  final String artNameIt;
  final String artNameEn;
  final String skillOneIt;
  final String skillOneEn;
  final String skillTwoIt;
  final String skillTwoEn;
  final String petNameIt;
  final String petNameEn;
  final String titleNameIt;
  final String titleNameEn;
  final Color color;
  final Color shadowColor;
  final bool exploder;
}

class _OculumBattleUnit {
  _OculumBattleUnit({
    required this.id,
    required this.cardId,
    required this.nameIt,
    required this.nameEn,
    required this.spriteKind,
    required this.color,
    required this.maxHp,
    required this.hp,
    required this.damage,
    required this.armor,
    required this.speed,
    required this.ally,
    required this.lane,
    this.pet = false,
    this.shadow = false,
    this.graduated = false,
    this.heroic = false,
    this.shadowSpawned = false,
    this.spawns = 0,
    this.age = 0,
    this.stunnedTurns = 0,
  });

  final String id;
  final String cardId;
  final String nameIt;
  final String nameEn;
  final String spriteKind;
  final Color color;
  int maxHp;
  int hp;
  int damage;
  int armor;
  final int speed;
  final bool ally;
  final bool pet;
  final bool shadow;
  final bool graduated;
  final bool heroic;
  bool shadowSpawned;
  final int spawns;
  final int lane;
  int age;
  int stunnedTurns;

  bool get alive => hp > 0;
}

List<_OculumBattleDominantDef> _generateOculumBattleDominants() {
  return [
    _OculumBattleDominantDef(
      id: 'noctis',
      nameIt: 'Noctis',
      nameEn: 'Noctis',
      titleIt: 'Signore della luna e dell ombra',
      titleEn: 'Lord of moon and shadow',
      descIt:
          'Un Dominatore fragile ma crudele: non protegge le truppe, le moltiplica quando sanguinano.',
      descEn:
          'A frail, cruel Dominant: he does not protect troops, he multiplies them when they bleed.',
      effectIt:
          'La prima volta che una tua evocazione con HP viene colpita, nasce la sua ombra con 25% HP e 75% danni.',
      effectEn:
          'The first time one of your HP summons is hit, its shadow rises with 25% HP and 75% damage.',
      spriteKind: 'dominant_noctis',
      color: Color(0xFF9B7CFF),
      baseHp: 210,
      power: 5,
    ),
    _OculumBattleDominantDef(
      id: 'first_melee_lord',
      nameIt: 'Regnante della Lama Vicina',
      nameEn: 'Ruler of the Near Blade',
      titleIt: 'Primo sangue ravvicinato',
      titleEn: 'First close blood',
      descIt:
          'Un sovrano di cortile che considera la distanza una forma di codardia.',
      descEn: 'A courtyard ruler who considers distance a form of cowardice.',
      effectIt: 'Potenzia i danni ravvicinati delle tue pedine.',
      effectEn: 'Boosts close-range damage for your pawns.',
      spriteKind: 'dominant_first_melee',
      color: Color(0xFFE05A6F),
      baseHp: 245,
      power: 4,
    ),
    _OculumBattleDominantDef(
      id: 'first_balanced_lord',
      nameIt: 'Custode del Primo Cerchio',
      nameEn: 'Keeper of the First Circle',
      titleIt: 'Bilancia del cortile',
      titleEn: 'Courtyard balance',
      descIt: 'Tiene insieme lama e freccia con una calma quasi offensiva.',
      descEn: 'Holds blade and arrow together with an almost offensive calm.',
      effectIt: 'Potenzia un po sia danni ravvicinati che a distanza.',
      effectEn: 'Slightly boosts both close and ranged damage.',
      spriteKind: 'dominant_first_balanced',
      color: Color(0xFFD6B56D),
      baseHp: 255,
      power: 3,
    ),
    _OculumBattleDominantDef(
      id: 'first_ranged_lord',
      nameIt: 'Regnante delle Frecce Nere',
      nameEn: 'Ruler of Black Arrows',
      titleIt: 'Trono oltre la gittata',
      titleEn: 'Throne beyond range',
      descIt: 'Non entra mai nel fango: fa entrare le frecce al posto suo.',
      descEn: 'Never steps into the mud: arrows enter in his place.',
      effectIt: 'Potenzia i danni a distanza delle tue pedine.',
      effectEn: 'Boosts ranged damage for your pawns.',
      spriteKind: 'dominant_first_ranged',
      color: Color(0xFF8FB7FF),
      baseHp: 225,
      power: 4,
    ),
    _OculumBattleDominantDef(
      id: 'eiva',
      nameIt: 'Eiva',
      nameEn: 'Eiva',
      titleIt: 'Radice sotto il patto',
      titleEn: 'Root beneath the pact',
      descIt:
          'Fa crescere vita nelle crepe della pietra nera e chiama le truppe a resistere.',
      descEn:
          'She grows life through black-stone cracks and calls troops to endure.',
      effectIt:
          'Ogni turno cura lievemente le truppe ferite e premia carapaci e spawner.',
      effectEn:
          'Each turn she lightly heals wounded troops and rewards shells and spawners.',
      spriteKind: 'dominant_eiva',
      color: Color(0xFF5EE08A),
      baseHp: 250,
      power: 4,
    ),
    _OculumBattleDominantDef(
      id: 'valley',
      nameIt: 'Valley',
      nameEn: 'Valley',
      titleIt: 'Figlia della natura morta',
      titleEn: 'Child of dead nature',
      descIt:
          'Una fioritura sbagliata in mezzo alle catacombe, tenera solo con chi obbedisce.',
      descEn: 'A wrong bloom in the catacombs, tender only to those who obey.',
      effectIt:
          'Le truppe sotto meta vita ottengono piccola corazza e i pet curano di piu.',
      effectEn:
          'Troops below half life gain a small armor boost and pets heal more.',
      spriteKind: 'dominant_valley',
      color: Color(0xFF73D46F),
      baseHp: 235,
      power: 3,
    ),
    _OculumBattleDominantDef(
      id: 'gufus',
      nameIt: 'Gufus Leviante',
      nameEn: 'Gufus Leviante',
      titleIt: 'Santo del colpo storto',
      titleEn: 'Saint of crooked shots',
      descIt:
          'Ogni ordine arriva come una pallottola benedetta da una pessima idea.',
      descEn: 'Every order lands like a bullet blessed by a terrible idea.',
      effectIt:
          'Le truppe veloci colpiscono piu forte e la prima pressione al Dominatore aumenta.',
      effectEn:
          'Fast troops hit harder and the first pressure against the Dominant increases.',
      spriteKind: 'dominant_gufus',
      color: Color(0xFFFFB85C),
      baseHp: 225,
      power: 4,
    ),
    _OculumBattleDominantDef(
      id: 'postea',
      nameIt: 'Postea',
      nameEn: 'Postea',
      titleIt: 'Archivio in armatura',
      titleEn: 'Armored archive',
      descIt:
          'Trasforma le truppe in pratiche da archiviare sotto ferro e sigilli.',
      descEn: 'Turns troops into files to be archived under iron and seals.',
      effectIt:
          'La prima truppa schierata ottiene molta armatura e ogni copia trovata rende il fronte piu stabile.',
      effectEn:
          'The first deployed troop gains heavy armor and every copy found steadies the front.',
      spriteKind: 'dominant_postea',
      color: Color(0xFF8FB7FF),
      baseHp: 275,
      power: 3,
    ),
    _OculumBattleDominantDef(
      id: 'kooba',
      nameIt: 'Kooba',
      nameEn: 'Kooba',
      titleIt: 'Mercante della candela rotta',
      titleEn: 'Merchant of the broken candle',
      descIt:
          'Compra e rivende paura: i piccoli buff arrivano sempre al prezzo giusto.',
      descEn:
          'Buys and resells fear: small buffs always arrive at the right price.',
      effectIt:
          'I pet danno bonus maggiori e le truppe comuni guadagnano un piccolo danno.',
      effectEn:
          'Pets give stronger bonuses and common troops gain a small damage boost.',
      spriteKind: 'dominant_kooba',
      color: Color(0xFFE7C66B),
      baseHp: 240,
      power: 3,
    ),
    _OculumBattleDominantDef(
      id: 'hires',
      nameIt: 'Hires',
      nameEn: 'Hires',
      titleIt: 'Occhio che non dorme',
      titleEn: 'Eye that never sleeps',
      descIt:
          'Guarda ogni scambio di colpi e trasforma le ferite rimaste in pressione.',
      descEn:
          'Watches every exchange and turns surviving wounds into pressure.',
      effectIt:
          'Le truppe superstiti fanno piu pressione al Dominatore nemico.',
      effectEn: 'Surviving troops apply more pressure to the enemy Dominant.',
      spriteKind: 'dominant_hires',
      color: Color(0xFFFF5A8D),
      baseHp: 215,
      power: 5,
    ),
    _OculumBattleDominantDef(
      id: 'null_fateless',
      nameIt: 'Null Fateless',
      nameEn: 'Null Fateless',
      titleIt: 'Vuoto senza destino',
      titleEn: 'Fateless void',
      descIt:
          'Non comanda: cancella piccoli pezzi di volonta dal campo avversario.',
      descEn:
          'It does not command: it erases small pieces of will from the enemy field.',
      effectIt: 'A ogni turno una truppa nemica perde un poco di danno.',
      effectEn: 'Each turn one enemy troop loses a little damage.',
      spriteKind: 'dominant_null',
      color: Color(0xFFB7B7C8),
      baseHp: 205,
      power: 5,
    ),
    _OculumBattleDominantDef(
      id: 'bone_crown',
      nameIt: 'Corona d Ossa',
      nameEn: 'Crown of Bones',
      titleIt: 'Re senza cranio',
      titleEn: 'Skull-less king',
      descIt:
          'Una corona che ha dimenticato il capo e quindi lo pretende da tutti.',
      descEn: 'A crown that forgot its head and now demands one from everyone.',
      effectIt:
          'Le truppe lente ottengono HP e armatura, ma la pressione e piu pesante su entrambi i Dominatori.',
      effectEn:
          'Slow troops gain HP and armor, but pressure is heavier on both Dominants.',
      spriteKind: 'dominant_bone_crown',
      color: Color(0xFFE8E2C8),
      baseHp: 290,
      power: 2,
    ),
    _OculumBattleDominantDef(
      id: 'goblin_queen',
      nameIt: 'Regina Goblin',
      nameEn: 'Goblin Queen',
      titleIt: 'Sovrana dei codini rossi',
      titleEn: 'Ruler of red ringlets',
      descIt:
          'Una goblin dai cappelli stretti in due codini ricci rossi. Ride quando il campo diventa troppo verde.',
      descEn:
          'A goblin with hair held in two curly red pigtails. She laughs when the field turns too green.',
      effectIt: 'I goblin in campo ottengono +50% danno.',
      effectEn: 'Goblins on the field gain +50% damage.',
      spriteKind: 'dominant_goblin_queen',
      color: Color(0xFF9BEA61),
      baseHp: 220,
      power: 4,
    ),
    _OculumBattleDominantDef(
      id: 'goblin_knight',
      nameIt: 'Cavaliere Goblin',
      nameEn: 'Goblin Knight',
      titleIt: 'Armatura del campo storto',
      titleEn: 'Armor of the crooked field',
      descIt:
          'Un goblin in armatura: piccolo, testardo, abbastanza feroce da sembrare piu grande.',
      descEn:
          'An armored goblin: small, stubborn, fierce enough to seem bigger.',
      effectIt:
          'I goblin spadaccini hanno +160% vita e tutte le altre unita recuperano 5 vita ogni round.',
      effectEn:
          'Goblin swordsmen gain +160% life and every other unit recovers 5 life each round.',
      spriteKind: 'dominant_goblin_knight',
      color: Color(0xFFBBD06A),
      baseHp: 260,
      power: 3,
    ),
    ..._generateOculumBattleArenaPackDominants(),
  ];
}

List<_OculumBattleTroopDef> _generateOculumBattleTroops() {
  return [
    _OculumBattleTroopDef(
      id: 'goblin_scouts',
      nameIt: 'Scout goblin della fossa',
      nameEn: 'Pit goblin scouts',
      descIt: 'Truppe piccole, veloci, numerose: vincono se sopravvivono.',
      descEn: 'Small, fast, numerous troops: they win by surviving.',
      spriteKind: 'goblin',
      color: Color(0xFF8FD36B),
      rarity: 'comune',
      baseHp: 26,
      baseDamage: 7,
      armor: 0,
      speed: 7,
      cost: 1,
      spawns: 1,
      arenaId: 'goblin_camp',
    ),
    _OculumBattleTroopDef(
      id: 'weak_goblin',
      nameIt: 'Goblin debole',
      nameEn: 'Weak goblin',
      descIt: 'Una creatura caduta male e arrabbiata peggio.',
      descEn: 'A creature that fell badly and got angry worse.',
      spriteKind: 'goblin_weak',
      color: Color(0xFF8FE35C),
      rarity: 'comune',
      baseHp: 18,
      baseDamage: 5,
      armor: 0,
      speed: 6,
      cost: 1,
      arenaId: 'goblin_camp',
    ),
    _OculumBattleTroopDef(
      id: 'first_strong_archers',
      nameIt: 'Arcieri del primo cortile',
      nameEn: 'First courtyard archers',
      descIt: 'Forti da lontano, fragili se qualcuno arriva sotto tiro corto.',
      descEn: 'Strong at range, fragile if anyone reaches short distance.',
      spriteKind: 'first_archer',
      color: Color(0xFFD8C083),
      rarity: 'comune',
      baseHp: 30,
      baseDamage: 15,
      armor: 0,
      speed: 6,
      cost: 3,
      arenaId: 'grave_courtyard',
    ),
    _OculumBattleTroopDef(
      id: 'first_lancers',
      nameIt: 'Lancieri del ferro spento',
      nameEn: 'Dead-iron lancers',
      descIt:
          'Medio forti da lontano e vicino, ma non sono tank: se cedono, cedono subito.',
      descEn:
          'Mid-strong at range and close, but not tanks: when they break, they break fast.',
      spriteKind: 'first_lancer',
      color: Color(0xFFBFC6D8),
      rarity: 'comune',
      baseHp: 38,
      baseDamage: 11,
      armor: 1,
      speed: 4,
      cost: 3,
      arenaId: 'grave_courtyard',
    ),
    _OculumBattleTroopDef(
      id: 'first_squires',
      nameIt: 'Scudieri del cortile',
      nameEn: 'Courtyard squires',
      descIt: 'Tank lenti con scudi troppo grandi: attirano molti bersagli.',
      descEn: 'Slow tanks with shields too large: they draw many targets.',
      spriteKind: 'first_squire',
      color: Color(0xFF9AA5B8),
      rarity: 'non comune',
      baseHp: 82,
      baseDamage: 5,
      armor: 5,
      speed: 1,
      cost: 3,
      arenaId: 'grave_courtyard',
    ),
    _OculumBattleTroopDef(
      id: 'shadow_knights',
      nameIt: 'Cavalieri dell ombra',
      nameEn: 'Shadow knights',
      descIt:
          'Ogni cinque battiti si tippano nell ombra nemica e fanno grossi danni ravvicinati.',
      descEn:
          'Every five beats they step into the enemy shadow and deal heavy close damage.',
      spriteKind: 'shadow_knight',
      color: Color(0xFF8B7BD9),
      rarity: 'rara',
      baseHp: 68,
      baseDamage: 18,
      armor: 3,
      speed: 5,
      cost: 5,
      arenaId: 'grave_courtyard',
    ),
    _OculumBattleTroopDef(
      id: 'black_assassins',
      nameIt: 'Assassini della lama cava',
      nameEn: 'Hollow-blade assassins',
      descIt: 'Poca vita, poca difesa, tantissimo danno.',
      descEn: 'Low life, low defense, extremely high damage.',
      spriteKind: 'black_assassin',
      color: Color(0xFFE05A6F),
      rarity: 'rara',
      baseHp: 24,
      baseDamage: 22,
      armor: 0,
      speed: 9,
      cost: 4,
      arenaId: 'grave_courtyard',
    ),
    _OculumBattleTroopDef(
      id: 'goblin_mages',
      nameIt: 'Goblin maghi della maledizione',
      nameEn: 'Curse goblin mages',
      descIt:
          'Lanciano palle di maledizione AoE: i mostri uccisi diventano goblin deboli.',
      descEn:
          'They throw AoE curse balls: killed monsters become weak goblins.',
      spriteKind: 'goblin_mage',
      color: Color(0xFF77F063),
      rarity: 'non comune',
      baseHp: 30,
      baseDamage: 8,
      armor: 0,
      speed: 5,
      cost: 3,
      spawns: 1,
      arenaId: 'goblin_camp',
    ),
    _OculumBattleTroopDef(
      id: 'goblin_fall',
      nameIt: 'Caduta goblin',
      nameEn: 'Goblin fall',
      descIt:
          'Due goblin con spada corta cadono nella zona avversaria: -25% vita, danno a impatto.',
      descEn:
          'Two short-sword goblins fall into the enemy zone: -25% life, impact damage.',
      spriteKind: 'goblin_fall',
      color: Color(0xFFB8F36D),
      rarity: 'non comune',
      baseHp: 24,
      baseDamage: 8,
      armor: 0,
      speed: 7,
      cost: 3,
      spawns: 2,
      arenaId: 'goblin_camp',
    ),
    _OculumBattleTroopDef(
      id: 'goblin_swordsmen',
      nameIt: 'Goblin spadaccini',
      nameEn: 'Goblin swordsmen',
      descIt: 'Tre goblin spadaccini: piccoli tagli, molta confusione.',
      descEn: 'Three goblin swordsmen: small cuts, much confusion.',
      spriteKind: 'goblin_sword',
      color: Color(0xFFA7EC5C),
      rarity: 'rara',
      baseHp: 28,
      baseDamage: 9,
      armor: 1,
      speed: 6,
      cost: 4,
      spawns: 2,
      arenaId: 'goblin_camp',
    ),
    _OculumBattleTroopDef(
      id: 'carapace_guard',
      nameIt: 'Guardia dal carapace nero',
      nameEn: 'Black carapace guard',
      descIt: 'Una linea lenta e corazzata che tiene aperta la ferita.',
      descEn: 'A slow armored line that keeps the wound open.',
      spriteKind: 'carapace',
      color: Color(0xFF65D1B7),
      rarity: 'comune',
      baseHp: 58,
      baseDamage: 6,
      armor: 4,
      speed: 2,
      cost: 2,
    ),
    _OculumBattleTroopDef(
      id: 'weak_spawner',
      nameIt: 'Spawner debole di cenere',
      nameEn: 'Weak ash spawner',
      descIt: 'Fa nascere resti fragili ogni due turni finche non cade.',
      descEn: 'Creates fragile remains every two turns until it falls.',
      spriteKind: 'spawner',
      color: Color(0xFFC0A0FF),
      rarity: 'comune',
      baseHp: 42,
      baseDamage: 3,
      armor: 1,
      speed: 1,
      cost: 2,
      spawns: 2,
    ),
    _OculumBattleTroopDef(
      id: 'rust_troll',
      nameIt: 'Troll della ruggine',
      nameEn: 'Rust troll',
      descIt: 'Pochi passi, molta carne, colpi pesanti come cancelli.',
      descEn: 'Few steps, much flesh, blows heavy as gates.',
      spriteKind: 'troll',
      color: Color(0xFFB98658),
      rarity: 'non comune',
      baseHp: 86,
      baseDamage: 13,
      armor: 2,
      speed: 1,
      cost: 4,
    ),
    _OculumBattleTroopDef(
      id: 'bone_hounds',
      nameIt: 'Segugi d osso ciechi',
      nameEn: 'Blind bone hounds',
      descIt: 'Rapidi e brutali, inseguono la truppa piu ferita.',
      descEn: 'Fast and brutal, they chase the most wounded troop.',
      spriteKind: 'hound',
      color: Color(0xFFE7E0C5),
      rarity: 'non comune',
      baseHp: 34,
      baseDamage: 11,
      armor: 1,
      speed: 8,
      cost: 2,
      spawns: 1,
    ),
    _OculumBattleTroopDef(
      id: 'ash_slime',
      nameIt: 'Slime di fuliggine',
      nameEn: 'Soot slime',
      descIt: 'Assorbe colpi deboli e lascia macchie vive sul terreno.',
      descEn: 'Absorbs weak blows and leaves living stains on the ground.',
      spriteKind: 'slime',
      color: Color(0xFF78D6FF),
      rarity: 'comune',
      baseHp: 48,
      baseDamage: 5,
      armor: 2,
      speed: 3,
      cost: 2,
    ),
    _OculumBattleTroopDef(
      id: 'fusing_slimes',
      nameIt: 'Slime fondenti x2',
      nameEn: 'Fusing slimes x2',
      descIt:
          'Due slime scuri che non vogliono restare piccoli: alla morte chiamano un Prince Slime.',
      descEn:
          'Two dark slimes that refuse to stay small: on death they call a Prince Slime.',
      spriteKind: 'slime_fusing',
      color: Color(0xFF7BE7BA),
      rarity: 'non comune',
      baseHp: 56,
      baseDamage: 7,
      armor: 1,
      speed: 3,
      cost: 3,
    ),
    _OculumBattleTroopDef(
      id: 'prince_slime',
      nameIt: 'Prince Slime nero',
      nameEn: 'Black Prince Slime',
      descIt:
          'Combatte con vortici di gelatina e pestoni molli. Se muore evoca 6 slime deboli.',
      descEn:
          'Fights with jelly vortices and soft stomps. If killed, summons 6 weak slimes.',
      spriteKind: 'prince_slime',
      color: Color(0xFF5EE0C2),
      rarity: 'rara',
      baseHp: 92,
      baseDamage: 14,
      armor: 3,
      speed: 2,
      cost: 5,
      spawns: 1,
    ),
    _OculumBattleTroopDef(
      id: 'king_slime',
      nameIt: 'King Slime del pozzo',
      nameEn: 'Well King Slime',
      descIt:
          'Regnante gelatinoso: vortici che avvicinano, pestoni e slime deboli. Se muore ne evoca 12.',
      descEn:
          'Gelatinous ruler: pulling vortices, stomps and weak slimes. If killed, summons 12.',
      spriteKind: 'king_slime',
      color: Color(0xFF46C7FF),
      rarity: 'epica',
      baseHp: 138,
      baseDamage: 18,
      armor: 5,
      speed: 1,
      cost: 6,
      spawns: 2,
    ),
    _OculumBattleTroopDef(
      id: 'bandit_band',
      nameIt: 'Banda di banditi',
      nameEn: 'Bandit band',
      descIt:
          'Tre corpi in uno slot: due sparano a distanza e uno chiude in melee.',
      descEn:
          'Three bodies in one slot: two shoot from range and one closes in melee.',
      spriteKind: 'bandit_melee',
      color: Color(0xFFD49A60),
      rarity: 'rara',
      baseHp: 38,
      baseDamage: 10,
      armor: 1,
      speed: 6,
      cost: 4,
      spawns: 2,
    ),
    _OculumBattleTroopDef(
      id: 'chain_cultist',
      nameIt: 'Cultista dalle catene viola',
      nameEn: 'Violet-chain cultist',
      descIt: 'Non regge a lungo, ma segna il bersaglio per gli altri.',
      descEn: 'Does not last long, but marks targets for the others.',
      spriteKind: 'cultist',
      color: Color(0xFFA78BFA),
      rarity: 'rara',
      baseHp: 36,
      baseDamage: 15,
      armor: 0,
      speed: 5,
      cost: 3,
    ),
    _OculumBattleTroopDef(
      id: 'grave_archer',
      nameIt: 'Arciere del camposanto',
      nameEn: 'Graveyard archer',
      descIt: 'Colpisce da lontano e teme solo chi arriva troppo presto.',
      descEn: 'Strikes from afar and fears only those who arrive too soon.',
      spriteKind: 'archer',
      color: Color(0xFFD8C083),
      rarity: 'non comune',
      baseHp: 31,
      baseDamage: 12,
      armor: 0,
      speed: 6,
      cost: 2,
    ),
    _OculumBattleTroopDef(
      id: 'plague_swarm',
      nameIt: 'Sciame della piaga nera',
      nameEn: 'Black plague swarm',
      descIt: 'Tanti corpi minuscoli: poca vita, molta pressione.',
      descEn: 'Many tiny bodies: little life, much pressure.',
      spriteKind: 'swarm',
      color: Color(0xFFB7F26B),
      rarity: 'rara',
      baseHp: 24,
      baseDamage: 8,
      armor: 0,
      speed: 9,
      cost: 2,
      spawns: 2,
    ),
    _OculumBattleTroopDef(
      id: 'mirror_knight',
      nameIt: 'Cavaliere dello specchio spento',
      nameEn: 'Dead-mirror knight',
      descIt: 'Raro, duro, riflette una parte della paura che riceve.',
      descEn: 'Rare, hard, reflecting part of the fear it receives.',
      spriteKind: 'mirror_knight',
      color: Color(0xFFCFD9FF),
      rarity: 'rara',
      baseHp: 72,
      baseDamage: 12,
      armor: 5,
      speed: 3,
      cost: 4,
    ),
    _OculumBattleTroopDef(
      id: 'eye_larva',
      nameIt: 'Larva oculare',
      nameEn: 'Ocular larva',
      descIt: 'Debole da sola, cresce bene con Dominatori ossessivi.',
      descEn: 'Weak alone, grows well with obsessive Dominants.',
      spriteKind: 'eye_larva',
      color: Color(0xFFFF79B8),
      rarity: 'comune',
      baseHp: 28,
      baseDamage: 9,
      armor: 0,
      speed: 6,
      cost: 1,
    ),
    _OculumBattleTroopDef(
      id: 'carrion_golem',
      nameIt: 'Golem del carnaio',
      nameEn: 'Carrion golem',
      descIt: 'Una massa lenta che fa perdere tempo anche alla morte.',
      descEn: 'A slow mass that wastes even death s time.',
      spriteKind: 'golem',
      color: Color(0xFFAA7B69),
      rarity: 'epica',
      baseHp: 112,
      baseDamage: 15,
      armor: 6,
      speed: 1,
      cost: 5,
    ),
    _OculumBattleTroopDef(
      id: 'ashen_moth',
      nameIt: 'Pet: falena di cenere',
      nameEn: 'Pet: ash moth',
      descIt: 'Piccolo pet: aumenta appena la vita delle truppe.',
      descEn: 'Small pet: slightly increases troop life.',
      spriteKind: 'pet_moth',
      color: Color(0xFFFFD6A0),
      rarity: 'pet',
      baseHp: 18,
      baseDamage: 1,
      armor: 0,
      speed: 4,
      cost: 1,
      isPet: true,
      buffHp: 5,
    ),
    _OculumBattleTroopDef(
      id: 'relic_wisp',
      nameIt: 'Pet: fuoco fatuo reliquia',
      nameEn: 'Pet: relic wisp',
      descIt: 'Pet raro: un filo di danno a tutte le truppe.',
      descEn: 'Rare pet: a thread of damage for every troop.',
      spriteKind: 'pet_wisp',
      color: Color(0xFF85F0FF),
      rarity: 'pet raro',
      baseHp: 16,
      baseDamage: 1,
      armor: 0,
      speed: 5,
      cost: 1,
      isPet: true,
      buffDamage: 1,
    ),
    _OculumBattleTroopDef(
      id: 'duelist_candle',
      nameIt: 'Pet: candela del duellante',
      nameEn: 'Pet: duelist candle',
      descIt: 'Pet della prima arena: un piccolo buff ai danni ravvicinati.',
      descEn: 'First-arena pet: a small close-damage buff.',
      spriteKind: 'pet_candle',
      color: Color(0xFFFFB86B),
      rarity: 'pet',
      baseHp: 16,
      baseDamage: 1,
      armor: 0,
      speed: 4,
      cost: 1,
      isPet: true,
      buffDamage: 1,
      arenaId: 'grave_courtyard',
    ),
    _OculumBattleTroopDef(
      id: 'black_arrow_relic',
      nameIt: 'Pet: reliquia freccia nera',
      nameEn: 'Pet: black-arrow relic',
      descIt: 'Pet della prima arena: aumenta appena vita e gittata utile.',
      descEn: 'First-arena pet: slightly increases life and useful range.',
      spriteKind: 'pet_arrow_relic',
      color: Color(0xFF8FB7FF),
      rarity: 'pet raro',
      baseHp: 18,
      baseDamage: 1,
      armor: 0,
      speed: 5,
      cost: 1,
      isPet: true,
      buffHp: 4,
      buffDamage: 1,
      arenaId: 'grave_courtyard',
    ),
    _OculumBattleTroopDef(
      id: 'little_obser',
      nameIt: 'Pet: piccolo Obser bendato',
      nameEn: 'Pet: small blindfolded Obser',
      descIt: 'Pet molto raro: poca vita e poco danno, ma ottima maestria.',
      descEn: 'Very rare pet: little life and damage, but excellent mastery.',
      spriteKind: 'pet_obser',
      color: Color(0xFFFF5A8D),
      rarity: 'pet raro',
      baseHp: 20,
      baseDamage: 2,
      armor: 0,
      speed: 6,
      cost: 1,
      isPet: true,
      buffHp: 3,
      buffDamage: 1,
    ),
    ..._generateOculumBattleArenaPackTroops(),
  ];
}

final List<_OculumBattleArenaDef> _oculumBattleArenaDefs = const [
  _OculumBattleArenaDef(
    id: 'goblin_camp',
    nameIt: 'Campo Goblin',
    nameEn: 'Goblin camp',
    descIt:
        'Tende marce, pali storti e cielo aperto: qui i goblin cadono addosso al nemico e ridono.',
    descEn:
        'Rotten tents, crooked poles and open sky: here goblins fall onto enemies and laugh.',
    color: Color(0xFF486F2D),
    shadowColor: Color(0xFF071006),
    hpDelta: 2,
    damageDelta: 1,
    pressureDelta: 1,
  ),
  _OculumBattleArenaDef(
    id: 'grave_courtyard',
    nameIt: 'Cortile delle tombe',
    nameEn: 'Grave courtyard',
    descIt: 'Pietra bagnata, lapidi basse, nessuno spazio per scappare.',
    descEn: 'Wet stone, low graves, no room to flee.',
    color: Color(0xFF605A72),
    shadowColor: Color(0xFF17131D),
    hpDelta: 0,
    damageDelta: 0,
    pressureDelta: 0,
  ),
  _OculumBattleArenaDef(
    id: 'undead_necropolis',
    nameIt: 'Necropoli dei Non Morti',
    nameEn: 'Undead necropolis',
    descIt:
        'Tombe aperte, campane senza lingua e cadaveri che aspettano il secondo ordine.',
    descEn:
        'Open graves, tongueless bells and corpses waiting for the second order.',
    color: Color(0xFF56615C),
    shadowColor: Color(0xFF080B09),
    hpDelta: 5,
    damageDelta: 0,
    pressureDelta: 1,
  ),
  _OculumBattleArenaDef(
    id: 'obsidian_chapel',
    nameIt: 'Cappella d ossidiana',
    nameEn: 'Obsidian chapel',
    descIt: 'I colpi risuonano piu forte sotto vetro nero e candele morte.',
    descEn: 'Blows echo harder under black glass and dead candles.',
    color: Color(0xFF3C3154),
    shadowColor: Color(0xFF09060F),
    hpDelta: 0,
    damageDelta: 1,
    pressureDelta: 0,
  ),
  _OculumBattleArenaDef(
    id: 'blood_marsh',
    nameIt: 'Palude del sangue lento',
    nameEn: 'Slow-blood marsh',
    descIt: 'Le truppe resistono di piu, ma ogni vittoria pesa sul Dominatore.',
    descEn: 'Troops endure more, but every survival weighs on the Dominant.',
    color: Color(0xFF5C2433),
    shadowColor: Color(0xFF13070B),
    hpDelta: 8,
    damageDelta: 0,
    pressureDelta: 1,
  ),
  _OculumBattleArenaDef(
    id: 'bone_bridge',
    nameIt: 'Ponte delle costole',
    nameEn: 'Rib bridge',
    descIt: 'Chi resta in piedi spinge il nemico nel vuoto.',
    descEn: 'Whoever remains standing pushes the enemy into the void.',
    color: Color(0xFF77694F),
    shadowColor: Color(0xFF15110B),
    hpDelta: 0,
    damageDelta: 0,
    pressureDelta: 2,
  ),
  _OculumBattleArenaDef(
    id: 'drowned_library',
    nameIt: 'Biblioteca annegata',
    nameEn: 'Drowned library',
    descIt: 'Le pagine zuppe attutiscono i colpi e conservano rancore.',
    descEn: 'Drenched pages soften blows and preserve resentment.',
    color: Color(0xFF244B5A),
    shadowColor: Color(0xFF061116),
    hpDelta: 6,
    damageDelta: -1,
    pressureDelta: 0,
  ),
  _OculumBattleArenaDef(
    id: 'pale_forge',
    nameIt: 'Forgia pallida',
    nameEn: 'Pale forge',
    descIt: 'Il ferro spento rende piu dure le creature lente.',
    descEn: 'Dead iron hardens slow creatures.',
    color: Color(0xFF6D6D76),
    shadowColor: Color(0xFF111116),
    hpDelta: 5,
    damageDelta: 0,
    pressureDelta: 0,
  ),
  _OculumBattleArenaDef(
    id: 'nullum_pit',
    nameIt: 'Fossa Nullum',
    nameEn: 'Nullum pit',
    descIt: 'La paura mangia danni e ricompone le ombre.',
    descEn: 'Fear eats damage and reassembles shadows.',
    color: Color(0xFF34333F),
    shadowColor: Color(0xFF050508),
    hpDelta: 0,
    damageDelta: -1,
    pressureDelta: 1,
  ),
  _OculumBattleArenaDef(
    id: 'thorn_catacombs',
    nameIt: 'Catacombe di spine',
    nameEn: 'Thorn catacombs',
    descIt: 'Ogni carapace sembra nascere con una lama sotto pelle.',
    descEn: 'Every shell seems born with a blade under its skin.',
    color: Color(0xFF35583C),
    shadowColor: Color(0xFF07100A),
    hpDelta: 4,
    damageDelta: 1,
    pressureDelta: 0,
  ),
  _OculumBattleArenaDef(
    id: 'moon_crypt',
    nameIt: 'Cripta lunare',
    nameEn: 'Moon crypt',
    descIt: 'Le ombre sono piu facili da chiamare e piu difficili da tacere.',
    descEn: 'Shadows are easier to call and harder to silence.',
    color: Color(0xFF4C4D78),
    shadowColor: Color(0xFF0C0D1A),
    hpDelta: 0,
    damageDelta: 1,
    pressureDelta: 1,
  ),
  _OculumBattleArenaDef(
    id: 'carrion_market',
    nameIt: 'Mercato del carnaio',
    nameEn: 'Carrion market',
    descIt: 'I pet trovano resti utili tra i banchi spezzati.',
    descEn: 'Pets find useful remains among broken stalls.',
    color: Color(0xFF60412F),
    shadowColor: Color(0xFF150B06),
    hpDelta: 3,
    damageDelta: 0,
    pressureDelta: 0,
  ),
  _OculumBattleArenaDef(
    id: 'glass_womb',
    nameIt: 'Utero di vetro',
    nameEn: 'Glass womb',
    descIt: 'Gli spawner tremano e partoriscono cose che non respirano.',
    descEn: 'Spawners tremble and birth things that do not breathe.',
    color: Color(0xFF6A426A),
    shadowColor: Color(0xFF140814),
    hpDelta: 0,
    damageDelta: 0,
    pressureDelta: 1,
  ),
  _OculumBattleArenaDef(
    id: 'black_sanctum',
    nameIt: 'Santuario nero',
    nameEn: 'Black sanctum',
    descIt: 'Qui il Dominatore paga tutto, anche quando vince.',
    descEn: 'Here the Dominant pays for everything, even victory.',
    color: Color(0xFF2C2132),
    shadowColor: Color(0xFF050309),
    hpDelta: -2,
    damageDelta: 1,
    pressureDelta: 2,
  ),
];

final List<_OculumBattleArenaPackDef> _oculumBattleArenaPacks = const [
  _OculumBattleArenaPackDef(
    arenaId: 'goblin_camp',
    prefix: 'goblin',
    dominantNameIt: 'Matriarca del Campo Goblin',
    dominantNameEn: 'Goblin Camp Matriarch',
    dominantTitleIt: 'Ruggito verde',
    dominantTitleEn: 'Green roar',
    unitThemeIt: 'goblin del campo',
    unitThemeEn: 'camp goblin',
    artNameIt: 'Rito del Campo Goblin',
    artNameEn: 'Goblin Camp Rite',
    skillOneIt: 'Pioggia di lame corte',
    skillOneEn: 'Short-blade rain',
    skillTwoIt: 'Urlo delle tende marce',
    skillTwoEn: 'Rotten-tent howl',
    petNameIt: 'Pet: rospo delle tende',
    petNameEn: 'Pet: tent toad',
    titleNameIt: 'Il campo obbedisce',
    titleNameEn: 'The camp obeys',
    color: Color(0xFF7CFF5A),
    shadowColor: Color(0xFF071006),
  ),
  _OculumBattleArenaPackDef(
    arenaId: 'grave_courtyard',
    prefix: 'grave',
    dominantNameIt: 'Reggente del Cortile',
    dominantNameEn: 'Courtyard Regent',
    dominantTitleIt: 'Primo patto di pietra',
    dominantTitleEn: 'First pact of stone',
    unitThemeIt: 'cortile',
    unitThemeEn: 'courtyard',
    artNameIt: 'Oculus del Cortile',
    artNameEn: 'Courtyard Oculus',
    skillOneIt: 'Taglio tra le lapidi',
    skillOneEn: 'Cut between graves',
    skillTwoIt: 'Ordine del cancello',
    skillTwoEn: 'Gate order',
    petNameIt: 'Pet: corvo da duello',
    petNameEn: 'Pet: dueling crow',
    titleNameIt: 'Nessuno oltrepassa il cancello',
    titleNameEn: 'None pass the gate',
    color: Color(0xFFD6B56D),
    shadowColor: Color(0xFF17131D),
  ),
  _OculumBattleArenaPackDef(
    arenaId: 'undead_necropolis',
    prefix: 'undead',
    dominantNameIt: 'Necromante della Campana Muta',
    dominantNameEn: 'Necromancer of the Mute Bell',
    dominantTitleIt: 'Secondo respiro dei morti',
    dominantTitleEn: 'Second breath of the dead',
    unitThemeIt: 'non morto',
    unitThemeEn: 'undead',
    artNameIt: 'Oculus dei Non Morti',
    artNameEn: 'Undead Oculus',
    skillOneIt: 'Richiamo della fossa',
    skillOneEn: 'Pit recall',
    skillTwoIt: 'Sangue che non circola',
    skillTwoEn: 'Blood that does not flow',
    petNameIt: 'Pet: cranio luminescente',
    petNameEn: 'Pet: glowing skull',
    titleNameIt: 'Muoiono una volta sola se lo permetto',
    titleNameEn: 'They die once only if I allow it',
    color: Color(0xFF9DB0A5),
    shadowColor: Color(0xFF080B09),
    exploder: true,
  ),
  _OculumBattleArenaPackDef(
    arenaId: 'obsidian_chapel',
    prefix: 'obsidian',
    dominantNameIt: 'Priora d Ossidiana',
    dominantNameEn: 'Obsidian Prioress',
    dominantTitleIt: 'Messa del vetro nero',
    dominantTitleEn: 'Mass of black glass',
    unitThemeIt: 'cappella',
    unitThemeEn: 'chapel',
    artNameIt: 'Oculus d Ossidiana',
    artNameEn: 'Obsidian Oculus',
    skillOneIt: 'Schegge consacrate',
    skillOneEn: 'Consecrated shards',
    skillTwoIt: 'Candela inversa',
    skillTwoEn: 'Inverted candle',
    petNameIt: 'Pet: chierico senza volto',
    petNameEn: 'Pet: faceless cleric',
    titleNameIt: 'Vetro sopra la carne',
    titleNameEn: 'Glass over flesh',
    color: Color(0xFF9C7BDA),
    shadowColor: Color(0xFF09060F),
  ),
  _OculumBattleArenaPackDef(
    arenaId: 'blood_marsh',
    prefix: 'bloodmarsh',
    dominantNameIt: 'Barone della Palude Rossa',
    dominantNameEn: 'Baron of the Red Marsh',
    dominantTitleIt: 'Sovrano del sangue lento',
    dominantTitleEn: 'Lord of slow blood',
    unitThemeIt: 'palude rossa',
    unitThemeEn: 'red marsh',
    artNameIt: 'Oculus della Palude',
    artNameEn: 'Marsh Oculus',
    skillOneIt: 'Risacca ematica',
    skillOneEn: 'Blood backwash',
    skillTwoIt: 'Fango coagulato',
    skillTwoEn: 'Clotted mud',
    petNameIt: 'Pet: sanguisuga cieca',
    petNameEn: 'Pet: blind leech',
    titleNameIt: 'Il fango ricorda il re',
    titleNameEn: 'The mud remembers the king',
    color: Color(0xFFC44B5C),
    shadowColor: Color(0xFF13070B),
  ),
  _OculumBattleArenaPackDef(
    arenaId: 'bone_bridge',
    prefix: 'bonebridge',
    dominantNameIt: 'Guardiano del Ponte di Costole',
    dominantNameEn: 'Rib-Bridge Warden',
    dominantTitleIt: 'Passaggio di osso',
    dominantTitleEn: 'Bone passage',
    unitThemeIt: 'ponte d osso',
    unitThemeEn: 'bone bridge',
    artNameIt: 'Oculus delle Costole',
    artNameEn: 'Rib Oculus',
    skillOneIt: 'Spinta nel vuoto',
    skillOneEn: 'Push into void',
    skillTwoIt: 'Parapetto di tibie',
    skillTwoEn: 'Tibia parapet',
    petNameIt: 'Pet: mano di costola',
    petNameEn: 'Pet: rib hand',
    titleNameIt: 'Il ponte vuole pedaggio',
    titleNameEn: 'The bridge wants toll',
    color: Color(0xFFE0D0A8),
    shadowColor: Color(0xFF15110B),
  ),
  _OculumBattleArenaPackDef(
    arenaId: 'drowned_library',
    prefix: 'drowned',
    dominantNameIt: 'Bibliotecario Annegato',
    dominantNameEn: 'Drowned Librarian',
    dominantTitleIt: 'Indice delle pagine morte',
    dominantTitleEn: 'Index of dead pages',
    unitThemeIt: 'biblioteca annegata',
    unitThemeEn: 'drowned library',
    artNameIt: 'Oculus delle Pagine Zuppe',
    artNameEn: 'Drenched Page Oculus',
    skillOneIt: 'Inchiostro nei polmoni',
    skillOneEn: 'Ink in lungs',
    skillTwoIt: 'Nota a margine',
    skillTwoEn: 'Margin note',
    petNameIt: 'Pet: libro morsicante',
    petNameEn: 'Pet: biting book',
    titleNameIt: 'Silenzio da scaffale',
    titleNameEn: 'Shelf silence',
    color: Color(0xFF65BED0),
    shadowColor: Color(0xFF061116),
  ),
  _OculumBattleArenaPackDef(
    arenaId: 'pale_forge',
    prefix: 'pale',
    dominantNameIt: 'Fabbro Pallido',
    dominantNameEn: 'Pale Smith',
    dominantTitleIt: 'Martello senza scintilla',
    dominantTitleEn: 'Sparkless hammer',
    unitThemeIt: 'forgia pallida',
    unitThemeEn: 'pale forge',
    artNameIt: 'Oculus della Forgia Pallida',
    artNameEn: 'Pale Forge Oculus',
    skillOneIt: 'Chiodo freddo',
    skillOneEn: 'Cold nail',
    skillTwoIt: 'Metallo spento',
    skillTwoEn: 'Dead metal',
    petNameIt: 'Pet: pinza pallida',
    petNameEn: 'Pet: pale tongs',
    titleNameIt: 'Forziamo anche la morte',
    titleNameEn: 'We forge even death',
    color: Color(0xFFB8BBC8),
    shadowColor: Color(0xFF111116),
  ),
  _OculumBattleArenaPackDef(
    arenaId: 'nullum_pit',
    prefix: 'nullpit',
    dominantNameIt: 'Signore della Fossa Nullum',
    dominantNameEn: 'Lord of the Nullum Pit',
    dominantTitleIt: 'Nome mai scritto',
    dominantTitleEn: 'Name never written',
    unitThemeIt: 'fossa nullum',
    unitThemeEn: 'nullum pit',
    artNameIt: 'Oculus Nullum',
    artNameEn: 'Nullum Oculus',
    skillOneIt: 'Taglio senza origine',
    skillOneEn: 'Originless cut',
    skillTwoIt: 'Vuoto nel comando',
    skillTwoEn: 'Void in command',
    petNameIt: 'Pet: eco vuota',
    petNameEn: 'Pet: empty echo',
    titleNameIt: 'Non ero qui',
    titleNameEn: 'I was not here',
    color: Color(0xFFB7B7C8),
    shadowColor: Color(0xFF050508),
  ),
  _OculumBattleArenaPackDef(
    arenaId: 'thorn_catacombs',
    prefix: 'thorn',
    dominantNameIt: 'Matriarca delle Spine',
    dominantNameEn: 'Thorn Matriarch',
    dominantTitleIt: 'Nido sotto pelle',
    dominantTitleEn: 'Nest under skin',
    unitThemeIt: 'catacomba di spine',
    unitThemeEn: 'thorn catacomb',
    artNameIt: 'Oculus delle Spine',
    artNameEn: 'Thorn Oculus',
    skillOneIt: 'Rovo nella gola',
    skillOneEn: 'Briar in throat',
    skillTwoIt: 'Radice del sarcofago',
    skillTwoEn: 'Sarcophagus root',
    petNameIt: 'Pet: larva spinosa',
    petNameEn: 'Pet: thorn larva',
    titleNameIt: 'Cresci dove sanguina',
    titleNameEn: 'Grow where it bleeds',
    color: Color(0xFF71C67B),
    shadowColor: Color(0xFF07100A),
  ),
  _OculumBattleArenaPackDef(
    arenaId: 'moon_crypt',
    prefix: 'mooncrypt',
    dominantNameIt: 'Reggente della Cripta Lunare',
    dominantNameEn: 'Moon Crypt Regent',
    dominantTitleIt: 'Luna sotto chiave',
    dominantTitleEn: 'Moon under lock',
    unitThemeIt: 'cripta lunare',
    unitThemeEn: 'moon crypt',
    artNameIt: 'Oculus Lunare',
    artNameEn: 'Moon Oculus',
    skillOneIt: 'Marea d ombra',
    skillOneEn: 'Shadow tide',
    skillTwoIt: 'Sigillo di luna fredda',
    skillTwoEn: 'Cold moon seal',
    petNameIt: 'Pet: tarlo lunare',
    petNameEn: 'Pet: moon moth',
    titleNameIt: 'La luna non perdona',
    titleNameEn: 'The moon does not forgive',
    color: Color(0xFF9B9CFF),
    shadowColor: Color(0xFF0C0D1A),
  ),
  _OculumBattleArenaPackDef(
    arenaId: 'carrion_market',
    prefix: 'carrion',
    dominantNameIt: 'Banditore del Carnaio',
    dominantNameEn: 'Carrion Auctioneer',
    dominantTitleIt: 'Prezzo della carne vecchia',
    dominantTitleEn: 'Price of old meat',
    unitThemeIt: 'mercato del carnaio',
    unitThemeEn: 'carrion market',
    artNameIt: 'Oculus del Carnaio',
    artNameEn: 'Carrion Oculus',
    skillOneIt: 'Offerta di ossa',
    skillOneEn: 'Bone bid',
    skillTwoIt: 'Contratto di viscere',
    skillTwoEn: 'Gut contract',
    petNameIt: 'Pet: moneta dentata',
    petNameEn: 'Pet: toothed coin',
    titleNameIt: 'Comprate cio che resta',
    titleNameEn: 'Buy what remains',
    color: Color(0xFFD49A60),
    shadowColor: Color(0xFF150B06),
  ),
  _OculumBattleArenaPackDef(
    arenaId: 'glass_womb',
    prefix: 'glasswomb',
    dominantNameIt: 'Levatrice del Vetro',
    dominantNameEn: 'Glass Midwife',
    dominantTitleIt: 'Nascita senza respiro',
    dominantTitleEn: 'Breathless birth',
    unitThemeIt: 'utero di vetro',
    unitThemeEn: 'glass womb',
    artNameIt: 'Oculus del Vetro Vivo',
    artNameEn: 'Living Glass Oculus',
    skillOneIt: 'Taglio prenatale',
    skillOneEn: 'Prenatal cut',
    skillTwoIt: 'Sacche che tremano',
    skillTwoEn: 'Trembling sacs',
    petNameIt: 'Pet: frammento neonato',
    petNameEn: 'Pet: newborn shard',
    titleNameIt: 'Nascono gia colpevoli',
    titleNameEn: 'They are born guilty',
    color: Color(0xFFD07AD0),
    shadowColor: Color(0xFF140814),
  ),
  _OculumBattleArenaPackDef(
    arenaId: 'black_sanctum',
    prefix: 'black',
    dominantNameIt: 'Priore del Santuario Nero',
    dominantNameEn: 'Prior of the Black Sanctum',
    dominantTitleIt: 'Ultima porta chiusa',
    dominantTitleEn: 'Last closed door',
    unitThemeIt: 'santuario nero',
    unitThemeEn: 'black sanctum',
    artNameIt: 'Oculus del Santuario Nero',
    artNameEn: 'Black Sanctum Oculus',
    skillOneIt: 'Liturgia del collasso',
    skillOneEn: 'Collapse liturgy',
    skillTwoIt: 'Assoluzione nera',
    skillTwoEn: 'Black absolution',
    petNameIt: 'Pet: cero senza fiamma',
    petNameEn: 'Pet: flameless candle',
    titleNameIt: 'Pregate con i denti',
    titleNameEn: 'Pray with your teeth',
    color: Color(0xFFC084FC),
    shadowColor: Color(0xFF050309),
  ),
];

List<_OculumBattleDominantDef> _generateOculumBattleArenaPackDominants() {
  return [
    for (final pack in _oculumBattleArenaPacks)
      _OculumBattleDominantDef(
        id: '${pack.prefix}_arena_dominant',
        nameIt: pack.dominantNameIt,
        nameEn: pack.dominantNameEn,
        titleIt: pack.dominantTitleIt,
        titleEn: pack.dominantTitleEn,
        descIt:
            'Dominatore dell arena ${pack.unitThemeIt}: guida il fronte locale e rende piu forte il pacchetto della sua arena.',
        descEn:
            'Dominant of the ${pack.unitThemeEn} arena: leads the local front and strengthens that arena pack.',
        effectIt:
            'Le unita della sua arena ottengono un piccolo buff costante.',
        effectEn: 'Units from its arena gain a small constant buff.',
        spriteKind: 'dominant_${pack.prefix}',
        color: pack.color,
        baseHp: pack.exploder ? 245 : 235,
        power: 3,
      ),
  ];
}

List<_OculumBattleTroopDef> _generateOculumBattleArenaPackTroops() {
  final troops = <_OculumBattleTroopDef>[];
  for (final pack in _oculumBattleArenaPacks) {
    troops.addAll([
      _OculumBattleTroopDef(
        id: '${pack.prefix}_vanguard',
        nameIt: 'Avanguardia ${pack.unitThemeIt}',
        nameEn: '${pack.unitThemeEn} vanguard',
        descIt: 'Unita ravvicinata stabile del pacchetto ${pack.unitThemeIt}.',
        descEn: 'Stable close unit from the ${pack.unitThemeEn} pack.',
        spriteKind: '${pack.prefix}_vanguard',
        color: pack.color,
        rarity: 'comune',
        baseHp: 42,
        baseDamage: 10,
        armor: 2,
        speed: 4,
        cost: 2,
        arenaId: pack.arenaId,
      ),
      _OculumBattleTroopDef(
        id: '${pack.prefix}_ranger',
        nameIt: 'Tiratore ${pack.unitThemeIt}',
        nameEn: '${pack.unitThemeEn} ranger',
        descIt: 'Danno a distanza del pacchetto ${pack.unitThemeIt}.',
        descEn: 'Ranged damage from the ${pack.unitThemeEn} pack.',
        spriteKind: '${pack.prefix}_ranger',
        color: Color.lerp(pack.color, Colors.white, 0.18)!,
        rarity: 'comune',
        baseHp: 30,
        baseDamage: 14,
        armor: 0,
        speed: 6,
        cost: 3,
        arenaId: pack.arenaId,
      ),
      _OculumBattleTroopDef(
        id: '${pack.prefix}_shield',
        nameIt: 'Scudiero ${pack.unitThemeIt}',
        nameEn: '${pack.unitThemeEn} shieldbearer',
        descIt: 'Tank lento del pacchetto ${pack.unitThemeIt}.',
        descEn: 'Slow tank from the ${pack.unitThemeEn} pack.',
        spriteKind: '${pack.prefix}_shield',
        color: Color.lerp(pack.color, Colors.black, 0.18)!,
        rarity: 'non comune',
        baseHp: 78,
        baseDamage: 5,
        armor: 5,
        speed: 1,
        cost: 3,
        arenaId: pack.arenaId,
      ),
      _OculumBattleTroopDef(
        id: '${pack.prefix}_assassin',
        nameIt: 'Assassino ${pack.unitThemeIt}',
        nameEn: '${pack.unitThemeEn} assassin',
        descIt: 'Poca vita, poca difesa e danni alti.',
        descEn: 'Low life, low defense and high damage.',
        spriteKind: '${pack.prefix}_assassin',
        color: Color.lerp(pack.color, Colors.redAccent, 0.25)!,
        rarity: 'rara',
        baseHp: 24,
        baseDamage: 20,
        armor: 0,
        speed: 9,
        cost: 4,
        arenaId: pack.arenaId,
      ),
      _OculumBattleTroopDef(
        id: pack.exploder ? '${pack.prefix}_exploder' : '${pack.prefix}_caster',
        nameIt: pack.exploder
            ? 'Cadavere gonfio esplosivo'
            : 'Ritualista ${pack.unitThemeIt}',
        nameEn: pack.exploder
            ? 'Bloated explosive corpse'
            : '${pack.unitThemeEn} ritualist',
        descIt: pack.exploder
            ? 'Non morto fragile: quando muore esplode e lacera i nemici vicini.'
            : 'Lancia piccoli rituali AoE della sua arena.',
        descEn: pack.exploder
            ? 'Fragile undead: when killed it explodes and tears nearby enemies.'
            : 'Casts small AoE rites from its arena.',
        spriteKind: pack.exploder
            ? '${pack.prefix}_exploder'
            : '${pack.prefix}_caster',
        color: Color.lerp(pack.color, Colors.greenAccent, 0.18)!,
        rarity: 'non comune',
        baseHp: pack.exploder ? 22 : 34,
        baseDamage: pack.exploder ? 7 : 12,
        armor: 0,
        speed: pack.exploder ? 3 : 5,
        cost: 3,
        arenaId: pack.arenaId,
      ),
      _OculumBattleTroopDef(
        id: '${pack.prefix}_brute',
        nameIt: 'Bruto ${pack.unitThemeIt}',
        nameEn: '${pack.unitThemeEn} brute',
        descIt: 'Unita pesante per chi vuole pressione costante.',
        descEn: 'Heavy unit for constant pressure.',
        spriteKind: '${pack.prefix}_brute',
        color: Color.lerp(pack.color, Colors.black, 0.28)!,
        rarity: 'rara',
        baseHp: 70,
        baseDamage: 15,
        armor: 3,
        speed: 2,
        cost: 4,
        arenaId: pack.arenaId,
      ),
      _OculumBattleTroopDef(
        id: '${pack.prefix}_pet',
        nameIt: pack.petNameIt,
        nameEn: pack.petNameEn,
        descIt: 'Pet dell arena ${pack.unitThemeIt}: piccolo buff al fronte.',
        descEn: 'Pet from the ${pack.unitThemeEn} arena: small front buff.',
        spriteKind: 'pet_${pack.prefix}',
        color: Color.lerp(pack.color, Colors.white, 0.28)!,
        rarity: 'pet',
        baseHp: 18,
        baseDamage: 1,
        armor: 0,
        speed: 5,
        cost: 1,
        isPet: true,
        buffHp: 3,
        buffDamage: 1,
        arenaId: pack.arenaId,
      ),
    ]);
  }
  return troops;
}

List<_OculumBattleRulerTitleDef> _generateOculumBattleArenaPackTitles() {
  return [
    for (final pack in _oculumBattleArenaPacks)
      _OculumBattleRulerTitleDef(
        dominantId: '${pack.prefix}_arena_dominant',
        secretIt: 'Titolo arena sigillato',
        secretEn: 'Sealed arena Title',
        nameIt: pack.titleNameIt,
        nameEn: pack.titleNameEn,
        triggerIt:
            'Quando il Dominatore scende sotto il 35% vita, le unita della sua arena ottengono HP e danno.',
        triggerEn:
            'When the Dominant drops below 35% life, units from its arena gain HP and damage.',
      ),
  ];
}

List<_OculumBattleArtDef> _generateOculumBattleArenaPackArts() {
  return [
    for (final pack in _oculumBattleArenaPacks)
      _OculumBattleArtDef(
        id: '${pack.prefix}_arena_art',
        nameIt: pack.artNameIt,
        nameEn: pack.artNameEn,
        rarityIt: 'arena',
        rarityEn: 'arena',
        descIt:
            'Art dell arena ${pack.unitThemeIt}: due skill tematiche usabili in battaglia.',
        descEn:
            'Art from the ${pack.unitThemeEn} arena: two themed skills usable in battle.',
        color: pack.color,
        baseUses: 2,
        skillIds: [
          '${pack.prefix}_arena_skill_1',
          '${pack.prefix}_arena_skill_2',
        ],
        arenaId: pack.arenaId,
      ),
  ];
}

List<_OculumBattleArtSkillDef> _generateOculumBattleArenaPackSkills() {
  return [
    for (final pack in _oculumBattleArenaPacks) ...[
      _OculumBattleArtSkillDef(
        id: '${pack.prefix}_arena_skill_1',
        artId: '${pack.prefix}_arena_art',
        nameIt: pack.skillOneIt,
        nameEn: pack.skillOneEn,
        descIt: 'Skill offensiva dell arena ${pack.unitThemeIt}.',
        descEn: 'Offensive skill from the ${pack.unitThemeEn} arena.',
        icon: Icons.flash_on,
        color: pack.color,
      ),
      _OculumBattleArtSkillDef(
        id: '${pack.prefix}_arena_skill_2',
        artId: '${pack.prefix}_arena_art',
        nameIt: pack.skillTwoIt,
        nameEn: pack.skillTwoEn,
        descIt: 'Skill di controllo o rinforzo dell arena ${pack.unitThemeIt}.',
        descEn:
            'Control or reinforcement skill from the ${pack.unitThemeEn} arena.',
        icon: Icons.blur_on,
        color: Color.lerp(pack.color, Colors.white, 0.18)!,
      ),
    ],
  ];
}

final List<_OculumBattleRulerTitleDef> _oculumBattleRulerTitleDefs = [
  _OculumBattleRulerTitleDef(
    dominantId: 'noctis',
    secretIt: 'Titolo lunare sigillato',
    secretEn: 'Sealed lunar Title',
    nameIt: 'Due ombre sotto il quarto di luna',
    nameEn: 'Two shadows under the quarter moon',
    triggerIt: 'Quando Noctis scende al 25% di vita, evoca due ombre alleate.',
    triggerEn: 'When Noctis drops to 25% life, he summons two allied shadows.',
  ),
  _OculumBattleRulerTitleDef(
    dominantId: 'first_melee_lord',
    secretIt: 'Titolo del primo cortile sigillato',
    secretEn: 'Sealed first-courtyard Title',
    nameIt: 'Sangue sotto la lama vicina',
    nameEn: 'Blood under the near blade',
    triggerIt: 'Sotto il 35% vita, le truppe ravvicinate ottengono danno e HP.',
    triggerEn: 'Below 35% life, close troops gain damage and HP.',
  ),
  _OculumBattleRulerTitleDef(
    dominantId: 'first_balanced_lord',
    secretIt: 'Titolo del primo cortile sigillato',
    secretEn: 'Sealed first-courtyard Title',
    nameIt: 'Due mani sul primo cancello',
    nameEn: 'Two hands on the first gate',
    triggerIt: 'Sotto il 35% vita, tutto il fronte riceve un piccolo rinforzo.',
    triggerEn:
        'Below 35% life, the whole front receives a small reinforcement.',
  ),
  _OculumBattleRulerTitleDef(
    dominantId: 'first_ranged_lord',
    secretIt: 'Titolo del primo cortile sigillato',
    secretEn: 'Sealed first-courtyard Title',
    nameIt: 'Frecce dalla seconda fila',
    nameEn: 'Arrows from the second row',
    triggerIt: 'Sotto il 35% vita, le truppe a distanza ottengono danno e HP.',
    triggerEn: 'Below 35% life, ranged troops gain damage and HP.',
  ),
  _OculumBattleRulerTitleDef(
    dominantId: 'eiva',
    secretIt: 'Titolo radicale sigillato',
    secretEn: 'Sealed root Title',
    nameIt: 'Radici che bevono paura',
    nameEn: 'Roots that drink fear',
    triggerIt:
        'Al 25% di vita cura tutte le truppe e richiama uno spawner debole.',
    triggerEn: 'At 25% life she heals every troop and recalls a weak spawner.',
  ),
  _OculumBattleRulerTitleDef(
    dominantId: 'valley',
    secretIt: 'Titolo floreale sigillato',
    secretEn: 'Sealed bloom Title',
    nameIt: 'Fiore nato nella bara',
    nameEn: 'Flower born in the coffin',
    triggerIt: 'Al 25% di vita copre gli alleati con corazza viva.',
    triggerEn: 'At 25% life she covers allies with living armor.',
  ),
  _OculumBattleRulerTitleDef(
    dominantId: 'gufus',
    secretIt: 'Titolo balistico sigillato',
    secretEn: 'Sealed ballistic Title',
    nameIt: 'Ultimo colpo storto',
    nameEn: 'Last crooked shot',
    triggerIt: 'Al 25% di vita spara tre colpi contro il fronte nemico.',
    triggerEn: 'At 25% life he fires three shots into the enemy front.',
  ),
  _OculumBattleRulerTitleDef(
    dominantId: 'postea',
    secretIt: 'Titolo archivio sigillato',
    secretEn: 'Sealed archive Title',
    nameIt: 'Protocollo della porta chiusa',
    nameEn: 'Closed-door protocol',
    triggerIt: 'Al 25% di vita fortifica la prima linea sopravvissuta.',
    triggerEn: 'At 25% life the surviving frontline is fortified.',
  ),
  _OculumBattleRulerTitleDef(
    dominantId: 'kooba',
    secretIt: 'Titolo mercante sigillato',
    secretEn: 'Sealed merchant Title',
    nameIt: 'Saldo delle candele rotte',
    nameEn: 'Broken-candle balance',
    triggerIt: 'Al 25% di vita trasforma un pet in un piccolo buff globale.',
    triggerEn: 'At 25% life a pet becomes a small global buff.',
  ),
  _OculumBattleRulerTitleDef(
    dominantId: 'hires',
    secretIt: 'Titolo oculare sigillato',
    secretEn: 'Sealed ocular Title',
    nameIt: 'Sguardo che fa arretrare',
    nameEn: 'Gaze that pushes back',
    triggerIt:
        'Al 25% di vita infligge pressione diretta al Dominatore nemico.',
    triggerEn: 'At 25% life it pressures the enemy Dominant directly.',
  ),
  _OculumBattleRulerTitleDef(
    dominantId: 'null_fateless',
    secretIt: 'Titolo vuoto sigillato',
    secretEn: 'Sealed void Title',
    nameIt: 'Nome cancellato due volte',
    nameEn: 'Name erased twice',
    triggerIt: 'Al 25% di vita dimezza il prossimo fronte nemico.',
    triggerEn: 'At 25% life it halves the next enemy front.',
  ),
  _OculumBattleRulerTitleDef(
    dominantId: 'bone_crown',
    secretIt: 'Titolo regale sigillato',
    secretEn: 'Sealed royal Title',
    nameIt: 'Corona senza cranio',
    nameEn: 'Crown without skull',
    triggerIt: 'Al 25% di vita chiama segugi d osso dalla pavimentazione.',
    triggerEn: 'At 25% life it calls bone hounds from the floor.',
  ),
  _OculumBattleRulerTitleDef(
    dominantId: 'goblin_queen',
    secretIt: 'Titolo goblin sigillato',
    secretEn: 'Sealed goblin Title',
    nameIt: 'Per il vostro sovrano',
    nameEn: 'For your sovereign',
    triggerIt:
        'Quando il Dominatore scende sotto il 50% vita, i goblin ottengono +25% danni e HP.',
    triggerEn:
        'When the Dominant drops below 50% life, goblins gain +25% damage and HP.',
  ),
  _OculumBattleRulerTitleDef(
    dominantId: 'goblin_knight',
    secretIt: 'Titolo goblin sigillato',
    secretEn: 'Sealed goblin Title',
    nameIt: 'Per il vostro sovrano',
    nameEn: 'For your sovereign',
    triggerIt:
        'Quando il Dominatore scende sotto il 50% vita, i goblin ottengono +25% danni e HP.',
    triggerEn:
        'When the Dominant drops below 50% life, goblins gain +25% damage and HP.',
  ),
  ..._generateOculumBattleArenaPackTitles(),
];

final List<_OculumBattleArtDef> _oculumBattleArtDefs = [
  _OculumBattleArtDef(
    id: 'oculum_art',
    nameIt: 'Oculum Art',
    nameEn: 'Oculum Art',
    rarityIt: 'facile',
    rarityEn: 'common',
    descIt: 'La Art piu facile da trovare: fuoco, cura e dardi segugi.',
    descEn: 'The easiest Art to find: fire, healing and hound darts.',
    color: Color(0xFFFF6A3D),
    baseUses: 3,
    skillIds: ['fireball', 'regenerating_fire', 'fire_hound_darts'],
  ),
  _OculumBattleArtDef(
    id: 'goblin_oculus',
    nameIt: 'Oculus del Goblin',
    nameEn: 'Goblin Oculus',
    rarityIt: 'facile',
    rarityEn: 'common',
    descIt:
        'Art del Campo Goblin: fulmini verdi, razzi improvvisati e fiale puzzolenti.',
    descEn:
        'Goblin Camp Art: green lightning, improvised rockets and stink vials.',
    color: Color(0xFF7CFF5A),
    baseUses: 3,
    skillIds: ['green_lightning', 'goblin_rocket', 'stink_vial'],
  ),
  _OculumBattleArtDef(
    id: 'martial_art',
    nameIt: 'Martial Art',
    nameEn: 'Martial Art',
    rarityIt: 'comune',
    rarityEn: 'common',
    descIt: 'Si mette sulle pedine: buff, scatti e attacchi speciali.',
    descEn: 'Placed on pawns: buffs, dashes and special attacks.',
    color: Color(0xFFE7C66B),
    baseUses: 3,
    skillIds: ['iron_stance', 'blood_step', 'execution_order'],
  ),
  _OculumBattleArtDef(
    id: 'illness_art',
    nameIt: 'Illness Art',
    nameEn: 'Illness Art',
    rarityIt: 'non comune',
    rarityEn: 'uncommon',
    descIt: 'Tre skill sulla follia: panico, febbre e risate rotte.',
    descEn: 'Three madness skills: panic, fever and broken laughter.',
    color: Color(0xFF95D66B),
    baseUses: 3,
    skillIds: ['madness_seed', 'fever_bell', 'broken_laughter'],
  ),
  _OculumBattleArtDef(
    id: 'grimorio',
    nameIt: 'Grimorio',
    nameEn: 'Grimoire',
    rarityIt: 'raro',
    rarityEn: 'rare',
    descIt:
        'La vera svolta: porta 6 skill dello stesso tipo di Art dentro il libro.',
    descEn:
        'The turning point: carry 6 skills of the same Art type inside the book.',
    color: Color(0xFFBFA7FF),
    baseUses: 6,
    skillIds: [
      'fireball',
      'regenerating_fire',
      'fire_hound_darts',
      'madness_seed',
      'fever_bell',
      'broken_laughter',
    ],
  ),
  _OculumBattleArtDef(
    id: 'emblem_art',
    nameIt: 'Emblem Art',
    nameEn: 'Emblem Art',
    rarityIt: 'molto raro',
    rarityEn: 'very rare',
    descIt: 'Tre skill piu forti della Oculum Art: usa cariche, non Oculum.',
    descEn: 'Three skills stronger than Oculum Art: uses charges, not Oculum.',
    color: Color(0xFF85F0FF),
    baseUses: 3,
    skillIds: ['emblem_sun', 'emblem_chain', 'emblem_guard'],
  ),
  _OculumBattleArtDef(
    id: 'defiled',
    nameIt: 'Defiled',
    nameEn: 'Defiled',
    rarityIt: 'rarissima',
    rarityEn: 'ultra rare',
    descIt:
        'Mangia le tue pedine per riempire la barra utilizzo skill. Tre colpi molto forti.',
    descEn:
        'Eat your own pawns to fill the skill-use bar. Three very strong strikes.',
    color: Color(0xFFE11D48),
    baseUses: 0,
    skillIds: [
      'defiled_devour',
      'defiled_maw',
      'defiled_scream',
      'defiled_crown',
    ],
  ),
  ..._generateOculumBattleArenaPackArts(),
];

final List<_OculumBattleArtSkillDef> _oculumBattleArtSkillDefs = [
  _OculumBattleArtSkillDef(
    id: 'fireball',
    artId: 'oculum_art',
    nameIt: 'Palla di fuoco',
    nameEn: 'Fireball',
    descIt: 'Brucia il bersaglio piu resistente.',
    descEn: 'Burns the toughest target.',
    icon: Icons.local_fire_department,
    color: Color(0xFFFF6A3D),
  ),
  _OculumBattleArtSkillDef(
    id: 'regenerating_fire',
    artId: 'oculum_art',
    nameIt: 'Fuoco rigenerante',
    nameEn: 'Regenerating fire',
    descIt: 'Cura il fronte alleato senza numeri inutili.',
    descEn: 'Heals the allied front without noisy numbers.',
    icon: Icons.healing,
    color: Color(0xFFFF9F5C),
  ),
  _OculumBattleArtSkillDef(
    id: 'fire_hound_darts',
    artId: 'oculum_art',
    nameIt: 'Dardi segugio di fuoco',
    nameEn: 'Fire hound darts',
    descIt: 'Tre dardi inseguono i nemici feriti.',
    descEn: 'Three darts chase wounded enemies.',
    icon: Icons.whatshot,
    color: Color(0xFFFFC46B),
  ),
  _OculumBattleArtSkillDef(
    id: 'green_lightning',
    artId: 'goblin_oculus',
    nameIt: 'Fulmine verde',
    nameEn: 'Green lightning',
    descIt:
        'Si protrae sui nemici vicini: pochi danni, i morti diventano goblin deboli.',
    descEn:
        'Chains through nearby enemies: low damage, dead targets become weak goblins.',
    icon: Icons.bolt,
    color: Color(0xFF7CFF5A),
  ),
  _OculumBattleArtSkillDef(
    id: 'goblin_rocket',
    artId: 'goblin_oculus',
    nameIt: 'Razzo di goblin',
    nameEn: 'Goblin rocket',
    descIt: 'Grande danno e spawna due goblin deboli.',
    descEn: 'Heavy damage and spawns two weak goblins.',
    icon: Icons.rocket_launch,
    color: Color(0xFFB8F36D),
  ),
  _OculumBattleArtSkillDef(
    id: 'stink_vial',
    artId: 'goblin_oculus',
    nameIt: 'Fiala puzzolente',
    nameEn: 'Stink vial',
    descIt: 'Non fa danni: stunna per un po i nemici colpiti.',
    descEn: 'Deals no damage: stuns hit enemies for a while.',
    icon: Icons.science,
    color: Color(0xFFB7F26B),
  ),
  _OculumBattleArtSkillDef(
    id: 'iron_stance',
    artId: 'martial_art',
    nameIt: 'Posizione di ferro',
    nameEn: 'Iron stance',
    descIt: 'Buffa le pedine con corazza e danno.',
    descEn: 'Buffs pawns with armor and damage.',
    icon: Icons.shield,
    color: Color(0xFFE7C66B),
  ),
  _OculumBattleArtSkillDef(
    id: 'blood_step',
    artId: 'martial_art',
    nameIt: 'Passo di sangue',
    nameEn: 'Blood step',
    descIt: 'La pedina piu veloce colpisce subito.',
    descEn: 'The fastest pawn strikes immediately.',
    icon: Icons.directions_run,
    color: Color(0xFFFF6A6A),
  ),
  _OculumBattleArtSkillDef(
    id: 'execution_order',
    artId: 'martial_art',
    nameIt: 'Ordine d esecuzione',
    nameEn: 'Execution order',
    descIt: 'Tutto il fronte attacca il bersaglio piu debole.',
    descEn: 'The whole front hits the weakest target.',
    icon: Icons.gavel,
    color: Color(0xFFFFD36A),
  ),
  _OculumBattleArtSkillDef(
    id: 'madness_seed',
    artId: 'illness_art',
    nameIt: 'Seme di follia',
    nameEn: 'Madness seed',
    descIt: 'La truppa nemica piu forte si lacera da sola.',
    descEn: 'The strongest enemy troop tears itself open.',
    icon: Icons.psychology,
    color: Color(0xFF95D66B),
  ),
  _OculumBattleArtSkillDef(
    id: 'fever_bell',
    artId: 'illness_art',
    nameIt: 'Campana febbrile',
    nameEn: 'Fever bell',
    descIt: 'La febbre passa su tutto il fronte nemico.',
    descEn: 'Fever rolls across the enemy front.',
    icon: Icons.notifications_active,
    color: Color(0xFFB7F26B),
  ),
  _OculumBattleArtSkillDef(
    id: 'broken_laughter',
    artId: 'illness_art',
    nameIt: 'Risata rotta',
    nameEn: 'Broken laughter',
    descIt: 'Il Dominatore nemico perde pressione e sangue.',
    descEn: 'The enemy Dominant loses pressure and blood.',
    icon: Icons.sentiment_very_dissatisfied,
    color: Color(0xFFD8FF8A),
  ),
  _OculumBattleArtSkillDef(
    id: 'emblem_sun',
    artId: 'emblem_art',
    nameIt: 'Emblema del sole nero',
    nameEn: 'Black sun emblem',
    descIt: 'Colpo forte su nemici e Dominatore.',
    descEn: 'Strong strike on enemies and Dominant.',
    icon: Icons.brightness_5,
    color: Color(0xFF85F0FF),
  ),
  _OculumBattleArtSkillDef(
    id: 'emblem_chain',
    artId: 'emblem_art',
    nameIt: 'Emblema delle catene',
    nameEn: 'Chain emblem',
    descIt: 'Tira il fronte nemico verso la morte.',
    descEn: 'Pulls the enemy front toward death.',
    icon: Icons.link,
    color: Color(0xFF8FB7FF),
  ),
  _OculumBattleArtSkillDef(
    id: 'emblem_guard',
    artId: 'emblem_art',
    nameIt: 'Emblema guardiano',
    nameEn: 'Guardian emblem',
    descIt: 'Protegge e cura le tue pedine.',
    descEn: 'Protects and heals your pawns.',
    icon: Icons.security,
    color: Color(0xFF9FE8FF),
  ),
  _OculumBattleArtSkillDef(
    id: 'defiled_devour',
    artId: 'defiled',
    nameIt: 'Mangia pedina',
    nameEn: 'Devour pawn',
    descIt: 'Sacrifica una pedina e riempie la barra Defiled.',
    descEn: 'Sacrifices a pawn and fills the Defiled bar.',
    icon: Icons.restaurant,
    color: Color(0xFFE11D48),
  ),
  _OculumBattleArtSkillDef(
    id: 'defiled_maw',
    artId: 'defiled',
    nameIt: 'Fauce contaminata',
    nameEn: 'Defiled maw',
    descIt: 'Un morso enorme al fronte nemico.',
    descEn: 'A huge bite into the enemy front.',
    icon: Icons.dangerous,
    color: Color(0xFFFF5A8D),
    defiledCost: 35,
  ),
  _OculumBattleArtSkillDef(
    id: 'defiled_scream',
    artId: 'defiled',
    nameIt: 'Urlo impuro',
    nameEn: 'Impure scream',
    descIt: 'Danneggia ogni nemico e scuote il Dominatore.',
    descEn: 'Damages every enemy and shakes the Dominant.',
    icon: Icons.record_voice_over,
    color: Color(0xFFFF7AA8),
    defiledCost: 45,
  ),
  _OculumBattleArtSkillDef(
    id: 'defiled_crown',
    artId: 'defiled',
    nameIt: 'Corona divorata',
    nameEn: 'Devoured crown',
    descIt: 'Colpo rarissimo e crudele contro il Dominatore.',
    descEn: 'A rare cruel blow against the Dominant.',
    icon: Icons.workspace_premium,
    color: Color(0xFFFF9AB8),
    defiledCost: 60,
  ),
  ..._generateOculumBattleArenaPackSkills(),
];

String _oculumBattleEncodeIntMap(Map<String, int> map) {
  final entries = map.entries.where((entry) => entry.value > 0).toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((entry) => '${entry.key}:${entry.value}').join('|');
}

Map<String, int> _oculumBattleDecodeIntMap(String? value) {
  if (value == null || value.trim().isEmpty) return <String, int>{};
  final result = <String, int>{};
  for (final pair in value.split('|')) {
    final parts = pair.split(':');
    if (parts.length != 2) continue;
    final parsed = int.tryParse(parts[1]);
    if (parsed != null && parsed > 0) result[parts[0]] = parsed;
  }
  return result;
}

extension _OculumBattleSystem on _OculumDungeonGameDialogState {
  List<_OculumBattleArenaDef> get _oculumBattleArenas => _oculumBattleArenaDefs;

  List<_OculumBattleArtDef> get _oculumBattleArts => _oculumBattleArtDefs;

  _OculumBattleArtDef get _selectedBattleArt {
    return _oculumBattleArts.firstWhere(
      (art) => art.id == oculumBattleSelectedArtId,
      orElse: () => _oculumBattleArts.first,
    );
  }

  _OculumBattleRulerTitleDef? _rulerTitleFor(String dominantId) {
    for (final title in _oculumBattleRulerTitleDefs) {
      if (title.dominantId == dominantId) return title;
    }
    return null;
  }

  _OculumBattleArtSkillDef? _artSkillById(String id) {
    for (final skill in _oculumBattleArtSkillDefs) {
      if (skill.id == id) return skill;
    }
    return null;
  }

  _OculumBattleDominantDef get _selectedBattleDominant =>
      _oculumBattleDominantById(oculumBattleSelectedDominantId);

  _OculumBattleDominantDef get _enemyBattleDominant =>
      _oculumBattleDominantById(oculumBattleEnemyDominantId);

  _OculumBattleArenaDef get _selectedBattleArena {
    return _oculumBattleArenas.firstWhere(
      (arena) => arena.id == oculumBattleArenaId,
      orElse: () => _oculumBattleArenas.first,
    );
  }

  List<_OculumBattleTroopDef> get _selectedBattleCards {
    return _oculumBattleTroops
        .where((card) => oculumBattleDraftTroopIds.contains(card.id))
        .toList();
  }

  List<_OculumBattleTroopDef> get _selectedBattlePets {
    return _selectedBattleCards.where((card) => card.isPet).toList();
  }

  List<_OculumBattleTroopDef> get _selectedBattleTroops {
    return _selectedBattleCards.where((card) => !card.isPet).toList();
  }

  _OculumBattleDominantDef _oculumBattleDominantById(String id) {
    return _oculumBattleDominants.firstWhere(
      (dominant) => dominant.id == id,
      orElse: () => _oculumBattleDominants.first,
    );
  }

  _OculumBattleTroopDef? _oculumBattleCardById(String id) {
    for (final card in _oculumBattleTroops) {
      if (card.id == id) return card;
    }
    return null;
  }

  bool _isGoblinCardId(String id) {
    return id.contains('goblin') || id == 'bandit_shooter';
  }

  bool _isGoblinCard(_OculumBattleTroopDef card) {
    return _isGoblinCardId(card.id) || card.spriteKind.contains('goblin');
  }

  bool _isGoblinUnit(_OculumBattleUnit unit) {
    return _isGoblinCardId(unit.cardId) || unit.spriteKind.contains('goblin');
  }

  bool _isArenaPackDominant(String id) => id.endsWith('_arena_dominant');

  String _arenaPrefixFromDominant(String id) {
    return id.replaceFirst('_arena_dominant', '');
  }

  _OculumBattleArenaPackDef? _arenaPackByPrefix(String prefix) {
    for (final pack in _oculumBattleArenaPacks) {
      if (pack.prefix == prefix) return pack;
    }
    return null;
  }

  _OculumBattleArenaPackDef? _arenaPackForSkill(String skillId) {
    for (final pack in _oculumBattleArenaPacks) {
      if (skillId.startsWith('${pack.prefix}_arena_skill_')) return pack;
    }
    return null;
  }

  bool _isCloseCard(_OculumBattleTroopDef card) {
    final id = card.id;
    final kind = card.spriteKind;
    return id.contains('assassin') ||
        id.contains('swords') ||
        id.contains('vanguard') ||
        id.contains('knight') ||
        kind.contains('assassin') ||
        kind.contains('sword') ||
        kind.contains('vanguard') ||
        kind.contains('knight');
  }

  bool _isRangedCard(_OculumBattleTroopDef card) {
    final id = card.id;
    final kind = card.spriteKind;
    return id.contains('archer') ||
        id.contains('ranger') ||
        id.contains('shooter') ||
        id.contains('mage') ||
        id.contains('caster') ||
        kind.contains('archer') ||
        kind.contains('ranger') ||
        kind.contains('shooter') ||
        kind.contains('mage') ||
        kind.contains('caster');
  }

  bool _isPriorityTarget(_OculumBattleUnit unit) {
    return unit.cardId.contains('squire') ||
        unit.cardId.contains('shield') ||
        unit.spriteKind.contains('squire') ||
        unit.spriteKind.contains('shield');
  }

  bool _isTacticalSlotCardUsable(String? cardId) {
    if (cardId == null || cardId.trim().isEmpty) return false;
    final card = _oculumBattleCardById(cardId);
    return card != null && !card.isPet && _isOculumBattleCardUnlocked(card);
  }

  _OculumBattleTroopDef? get _graduatedSlotCard {
    if (!_isTacticalSlotCardUsable(oculumBattleGraduatedSlotCardId)) {
      return null;
    }
    return _oculumBattleCardById(oculumBattleGraduatedSlotCardId!);
  }

  _OculumBattleTroopDef? get _heroicSlotCard {
    if (!_isTacticalSlotCardUsable(oculumBattleHeroicSlotCardId) ||
        !unlockedOculumBattleHeroicCardIds.contains(
          oculumBattleHeroicSlotCardId,
        )) {
      return null;
    }
    return _oculumBattleCardById(oculumBattleHeroicSlotCardId!);
  }

  bool _isGraduatedSlotCard(String cardId) {
    return cardId == oculumBattleGraduatedSlotCardId &&
        _isTacticalSlotCardUsable(cardId);
  }

  bool _isHeroicSlotCard(String cardId) {
    return cardId == oculumBattleHeroicSlotCardId &&
        unlockedOculumBattleHeroicCardIds.contains(cardId) &&
        _isTacticalSlotCardUsable(cardId);
  }

  List<_OculumBattleTroopDef> get _battleTroopsWithTacticalSlots {
    final result = _selectedBattleTroops.toList();
    for (final slotCard in [_graduatedSlotCard, _heroicSlotCard]) {
      if (slotCard == null) continue;
      if (result.any((card) => card.id == slotCard.id)) continue;
      result.add(slotCard);
    }
    return result;
  }

  List<_OculumBattleTroopDef> get _previewBattleCardsWithTacticalSlots {
    final result = _selectedBattleCards.toList();
    for (final slotCard in [_graduatedSlotCard, _heroicSlotCard]) {
      if (slotCard == null) continue;
      if (result.any((card) => card.id == slotCard.id)) continue;
      result.add(slotCard);
    }
    return result;
  }

  bool oculumBattleMasterySkinUnlocked(String id) {
    return oculumBattleCardLevel(id) >= 3;
  }

  String oculumBattleMasterySkinName(String id) {
    final grade = oculumBattleCardLevel(id);
    if (grade >= 6) return t('Skin Reliquia', 'Relic Skin');
    if (grade >= 3) return t('Skin Maestria', 'Mastery Skin');
    return t('Skin bloccata', 'Skin locked');
  }

  Color _oculumBattleSkinColor(String id, Color baseColor) {
    final grade = oculumBattleCardLevel(id);
    if (grade >= 6)
      return Color.lerp(baseColor, const Color(0xFFFFD36A), 0.52)!;
    if (grade >= 3)
      return Color.lerp(baseColor, const Color(0xFFBFA7FF), 0.38)!;
    return baseColor;
  }

  int _oculumBattleFormationHpBonus() {
    final arenaMatches = _previewBattleCardsWithTacticalSlots
        .where((card) => card.arenaId == oculumBattleArenaId)
        .length;
    return arenaMatches >= 4
        ? 10
        : arenaMatches >= 3
        ? 6
        : 0;
  }

  int _oculumBattleFormationDamageBonus() {
    final cards = _previewBattleCardsWithTacticalSlots;
    final arenaMatches = cards
        .where((card) => card.arenaId == oculumBattleArenaId)
        .length;
    final hasFront = cards.any(_isCloseCard);
    final hasBack = cards.any(_isRangedCard);
    final hasTank = cards.any(
      (card) => card.id.contains('shield') || card.id.contains('squire'),
    );
    return (arenaMatches >= 3 ? 1 : 0) +
        (hasFront && hasBack && hasTank ? 1 : 0);
  }

  String _heroicAbilityLabel(_OculumBattleTroopDef card) {
    if (_isPriorityTargetId(card.id, card.spriteKind)) {
      return t('Aura Guardia', 'Guard Aura');
    }
    if (_isRangedCard(card)) return t('Raffica Evoluta', 'Evolved Volley');
    if (card.id.contains('slime')) return t('Nucleo Gelatina', 'Jelly Core');
    if (_isGoblinCard(card)) return t('Chiamata Verde', 'Green Call');
    if (card.id.contains('spawner')) return t('Nido Evoluto', 'Evolved Nest');
    if (card.id.contains('assassin')) return t('Esecuzione', 'Execution');
    return t('Impulso Evoluto', 'Evolved Pulse');
  }

  bool _isPriorityTargetId(String id, String spriteKind) {
    return id.contains('squire') ||
        id.contains('shield') ||
        spriteKind.contains('squire') ||
        spriteKind.contains('shield') ||
        id.contains('carapace');
  }

  bool _isOculumBattleCardUnlocked(_OculumBattleTroopDef card) {
    return card.isPet
        ? unlockedOculumBattlePetIds.contains(card.id)
        : unlockedOculumBattleTroopIds.contains(card.id);
  }

  String _oculumBattleRarityKey(String rarity) {
    final value = rarity.toLowerCase().trim().replaceAll('_', ' ');
    if (value.contains('oculum') ||
        value.contains('rarissima') ||
        value.contains('ultra')) {
      return 'oculum';
    }
    if (value.contains('molto') ||
        value.contains('very') ||
        value.contains('epica') ||
        value.contains('epic') ||
        value.contains('pet raro')) {
      return 'molto_rara';
    }
    if (value.contains('rara') ||
        value.contains('raro') ||
        value.contains('rare')) {
      return 'rara';
    }
    if (value.contains('non comune') ||
        value.contains('uncommon') ||
        value == 'pet') {
      return 'non_comune';
    }
    return 'comune';
  }

  String _oculumBattleRarityLabel(String rarity) {
    return _oculumBattleRarityLabelFor(rarity, english: widget.linguaInglese);
  }

  String _oculumBattleRarityLabelFor(String rarity, {required bool english}) {
    switch (_oculumBattleRarityKey(rarity)) {
      case 'non_comune':
        return english ? 'Uncommon' : 'Non comune';
      case 'rara':
        return english ? 'Rare' : 'Rara';
      case 'molto_rara':
        return english ? 'Very rare' : 'Molto rara';
      case 'oculum':
        return 'Oculum';
      default:
        return english ? 'Common' : 'Comune';
    }
  }

  Color _oculumBattleRarityColor(String rarity) {
    switch (_oculumBattleRarityKey(rarity)) {
      case 'non_comune':
        return const Color(0xFF85F0FF);
      case 'rara':
        return const Color(0xFFBFA7FF);
      case 'molto_rara':
        return const Color(0xFFE7C66B);
      case 'oculum':
        return const Color(0xFFFF6A3D);
      default:
        return const Color(0xFFB7F58A);
    }
  }

  int _oculumBattleRarityDropWeight(String rarity) {
    switch (_oculumBattleRarityKey(rarity)) {
      case 'non_comune':
        return 55;
      case 'rara':
        return 24;
      case 'molto_rara':
        return 9;
      case 'oculum':
        return 3;
      default:
        return 90;
    }
  }

  void _learnOculumBattleStyleFromCards(Iterable<_OculumBattleTroopDef> cards) {
    for (final card in cards) {
      for (final tag in _oculumBattleCardTags(card)) {
        _rememberOculumBattleStyle(tag, amount: card.isPet ? 1 : 2);
      }
      if (_isGraduatedSlotCard(card.id)) {
        _rememberOculumBattleStyle('graduated', amount: 2);
      }
      if (_isHeroicSlotCard(card.id)) {
        _rememberOculumBattleStyle('evolved', amount: 3);
      }
    }
  }

  void _learnOculumBattleSkill(String skillId) {
    final skill = _artSkillById(skillId);
    final artId = skill?.artId ?? '';
    _rememberOculumBattleStyle('spell', amount: 2);
    if (skillId.contains('stink') ||
        skillId.contains('madness') ||
        skillId.contains('laughter') ||
        skillId.contains('scream') ||
        skillId.contains('chain')) {
      _rememberOculumBattleStyle('control', amount: 2);
    }
    if (skillId.contains('fire') ||
        skillId.contains('rocket') ||
        skillId.contains('emblem') ||
        skillId.endsWith('_arena_skill_1')) {
      _rememberOculumBattleStyle('aoe', amount: 2);
    }
    if (skillId.contains('regenerating') ||
        skillId.contains('guard') ||
        skillId.contains('stance') ||
        skillId.endsWith('_arena_skill_2')) {
      _rememberOculumBattleStyle('support', amount: 2);
    }
    if (artId == 'defiled' || skillId.contains('defiled')) {
      _rememberOculumBattleStyle('defiled', amount: 3);
    }
    if (artId == 'goblin_oculus' || skillId.contains('goblin')) {
      _rememberOculumBattleStyle('goblin', amount: 2);
    }
    if (artId == 'emblem_art' || artId == 'grimorio') {
      _rememberOculumBattleStyle('oculum', amount: 1);
    }
  }

  void _rememberOculumBattleStyle(String tag, {int amount = 1}) {
    if (tag.isEmpty) return;
    oculumBattleBotMemory[tag] = min(
      999,
      (oculumBattleBotMemory[tag] ?? 0) + amount,
    );
  }

  List<String> _oculumBattleCardTags(_OculumBattleTroopDef card) {
    final tags = <String>{_oculumBattleRarityKey(card.rarity), card.arenaId};
    final id = card.id.toLowerCase();
    final kind = card.spriteKind.toLowerCase();
    if (card.isPet) tags.add('pet');
    if (_isCloseCard(card)) tags.add('close');
    if (_isRangedCard(card)) tags.add('ranged');
    if (_isPriorityTargetId(id, kind) || card.armor >= 4 || card.baseHp >= 70) {
      tags.add('tank');
    }
    if (card.spawns > 0 ||
        id.contains('bandit') ||
        id.contains('goblin') ||
        id.contains('slime')) {
      tags.add('swarm');
    }
    if (id.contains('goblin')) tags.add('goblin');
    if (id.contains('slime')) tags.add('slime');
    if (id.contains('undead') ||
        id.contains('bone') ||
        id.contains('corpse') ||
        id.contains('cadavere')) {
      tags.add('undead');
    }
    if (id.contains('exploder') ||
        id.contains('caster') ||
        kind.contains('mage')) {
      tags.add('aoe');
    }
    if (id.contains('caster') || kind.contains('mage')) tags.add('caster');
    if (id.contains('assassin') || kind.contains('assassin')) {
      tags.add('assassin');
    }
    if (id.contains('spawner')) tags.add('spawner');
    if (id.contains('oculum')) tags.add('oculum');
    if (card.speed >= 5) tags.add('fast');
    return tags.toList(growable: false);
  }

  List<String> _oculumBattleBotCounterTags() {
    final sorted = oculumBattleBotMemory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).map((entry) => entry.key).toSet();
    final counters = <String>[];

    void addAll(Iterable<String> tags) {
      for (final tag in tags) {
        if (!counters.contains(tag)) counters.add(tag);
      }
    }

    if (top.contains('ranged')) addAll(['assassin', 'tank', 'fast']);
    if (top.contains('close')) addAll(['tank', 'ranged']);
    if (top.contains('tank')) addAll(['spell', 'assassin', 'oculum']);
    if (top.contains('swarm') ||
        top.contains('goblin') ||
        top.contains('slime') ||
        top.contains('spawner')) {
      addAll(['aoe', 'caster', 'tank']);
    }
    if (top.contains('spell') || top.contains('aoe')) {
      addAll(['fast', 'swarm', 'ranged']);
    }
    if (top.contains('support') || top.contains('pet')) {
      addAll(['assassin', 'control']);
    }
    if (top.contains('defiled') ||
        top.contains('evolved') ||
        top.contains('graduated')) {
      addAll(['oculum', 'control', 'tank']);
    }
    if (top.contains('undead')) addAll(['ranged', 'aoe']);
    return counters.isEmpty ? ['ranged', 'close', 'tank'] : counters;
  }

  List<_OculumBattleTroopDef> _draftOculumBattleBotCards(
    Random rng,
    int count,
    List<_OculumBattleTroopDef> pool,
  ) {
    final remaining = pool.toList();
    final picked = <_OculumBattleTroopDef>[];
    final counters = _oculumBattleBotCounterTags().toSet();
    while (picked.length < count && remaining.isNotEmpty) {
      final weights = [
        for (final card in remaining)
          _oculumBattleBotCardWeight(card, counters),
      ];
      final total = weights.fold<int>(0, (sum, weight) => sum + weight);
      var roll = rng.nextInt(max(1, total));
      var index = 0;
      for (; index < weights.length; index++) {
        roll -= weights[index];
        if (roll < 0) break;
      }
      picked.add(remaining.removeAt(min(index, remaining.length - 1)));
    }
    return picked;
  }

  int _oculumBattleBotCardWeight(
    _OculumBattleTroopDef card,
    Set<String> counters,
  ) {
    final tags = _oculumBattleCardTags(card).toSet();
    var weight = 12 + min<int>(28, oculumBattleWins * 2);
    for (final tag in tags) {
      if (counters.contains(tag)) weight += 22;
    }
    if (tags.contains('caster') && counters.contains('aoe')) weight += 18;
    if (tags.contains('ranged') && counters.contains('control')) weight += 8;
    weight += switch (_oculumBattleRarityKey(card.rarity)) {
      'oculum' => 2 + min<int>(10, oculumBattleWins),
      'molto_rara' => 5 + min<int>(12, oculumBattleWins),
      'rara' => 9,
      'non_comune' => 14,
      _ => 18,
    };
    return max(1, weight);
  }

  int oculumBattleArtUsesLeft(String artId) {
    final art = _oculumBattleArts.firstWhere(
      (item) => item.id == artId,
      orElse: () => _oculumBattleArts.first,
    );
    return oculumBattleArtUses[artId] ?? art.baseUses;
  }

  int oculumBattleCardLevel(String id) {
    return max(1, oculumBattleCardLevels[id] ?? 1);
  }

  int oculumBattleMasteryTarget(String id) {
    final level = oculumBattleCardLevel(id);
    final troop = _oculumBattleCardById(id);
    if (troop?.isPet == true) return 8 + level * 6;
    final dominant = _oculumBattleDominants.any((item) => item.id == id);
    if (dominant) return 12 + level * 9;
    return 6 + level * 5;
  }

  double oculumBattleMasteryFraction(String id) {
    final target = max(1, oculumBattleMasteryTarget(id));
    final progress = max(0, oculumBattleCardMastery[id] ?? 0);
    return (progress / target).clamp(0.0, 1.0).toDouble();
  }

  void restoreOculumBattleProgressFromPrefs(SharedPreferences prefs) {
    unlockedOculumBattleDominantIds
      ..clear()
      ..addAll(
        prefs.getStringList('oculumBattle.unlockedDominantIds') ??
            const [
              'noctis',
              'eiva',
              'first_melee_lord',
              'first_balanced_lord',
              'first_ranged_lord',
            ],
      );
    if (unlockedOculumBattleDominantIds.isEmpty) {
      unlockedOculumBattleDominantIds.addAll(['noctis', 'eiva']);
    }

    unlockedOculumBattleTroopIds
      ..clear()
      ..addAll(
        prefs.getStringList('oculumBattle.unlockedTroopIds') ??
            const [
              'first_strong_archers',
              'first_lancers',
              'first_squires',
              'shadow_knights',
              'black_assassins',
              'grave_vanguard',
            ],
      );
    if (unlockedOculumBattleTroopIds.isEmpty) {
      unlockedOculumBattleTroopIds.addAll([
        'first_strong_archers',
        'first_lancers',
        'first_squires',
        'shadow_knights',
        'black_assassins',
        'grave_vanguard',
      ]);
    }

    unlockedOculumBattlePetIds
      ..clear()
      ..addAll(
        prefs.getStringList('oculumBattle.unlockedPetIds') ??
            const ['duelist_candle'],
      );
    if (unlockedOculumBattlePetIds.isEmpty) {
      unlockedOculumBattlePetIds.add('duelist_candle');
    }

    oculumBattleCardLevels
      ..clear()
      ..addAll(
        _oculumBattleDecodeIntMap(prefs.getString('oculumBattle.cardLevels')),
      );
    oculumBattleCardMastery
      ..clear()
      ..addAll(
        _oculumBattleDecodeIntMap(prefs.getString('oculumBattle.cardMastery')),
      );
    oculumBattleCardCopies
      ..clear()
      ..addAll(
        _oculumBattleDecodeIntMap(prefs.getString('oculumBattle.cardCopies')),
      );
    oculumBattleBotMemory
      ..clear()
      ..addAll(
        _oculumBattleDecodeIntMap(prefs.getString('oculumBattle.botMemory')),
      );
    unlockedOculumBattleHeroicCardIds
      ..clear()
      ..addAll(
        prefs.getStringList('oculumBattle.unlockedHeroicCardIds') ?? const [],
      );
    equippedOculumBattleTitleIds
      ..clear()
      ..addAll(
        prefs.getStringList('oculumBattle.equippedTitleIds') ??
            const ['noctis'],
      );
    revealedOculumBattleTitleIds
      ..clear()
      ..addAll(
        prefs.getStringList('oculumBattle.revealedTitleIds') ?? const [],
      );
    oculumBattleArtUses
      ..clear()
      ..addAll(
        _oculumBattleDecodeIntMap(prefs.getString('oculumBattle.artUses')),
      );

    oculumBattleWins = prefs.getInt('oculumBattle.wins') ?? oculumBattleWins;
    oculumBattleFirstWinPackClaimed =
        prefs.getBool('oculumBattle.firstWinPackClaimed') ??
        oculumBattleFirstWinPackClaimed;
    oculumBattleSelectedDominantId =
        prefs.getString('oculumBattle.selectedDominantId') ??
        oculumBattleSelectedDominantId;
    if (!unlockedOculumBattleDominantIds.contains(
      oculumBattleSelectedDominantId,
    )) {
      oculumBattleSelectedDominantId = unlockedOculumBattleDominantIds.first;
    }
    oculumBattleArenaId =
        prefs.getString('oculumBattle.arenaId') ?? oculumBattleArenaId;
    if (!_oculumBattleArenas.any((arena) => arena.id == oculumBattleArenaId)) {
      oculumBattleArenaId = _oculumBattleArenas.first.id;
    }
    oculumBattleSelectedArtId =
        prefs.getString('oculumBattle.selectedArtId') ??
        oculumBattleSelectedArtId;
    if (!_oculumBattleArts.any((art) => art.id == oculumBattleSelectedArtId)) {
      oculumBattleSelectedArtId = _oculumBattleArts.first.id;
    }
    oculumBattleDefiledBar =
        prefs.getInt('oculumBattle.defiledBar') ?? oculumBattleDefiledBar;
    oculumBattleEvolutionPrinciples =
        prefs.getInt('oculumBattle.evolutionPrinciples') ??
        oculumBattleEvolutionPrinciples;
    oculumBattleGraduatedSlotCardId = prefs.getString(
      'oculumBattle.graduatedSlotCardId',
    );
    oculumBattleHeroicSlotCardId = prefs.getString(
      'oculumBattle.heroicSlotCardId',
    );

    final savedDeck = prefs.getStringList('oculumBattle.deckIds') ?? const [];
    oculumBattleDraftTroopIds
      ..clear()
      ..addAll(
        savedDeck.where((id) {
          final card = _oculumBattleCardById(id);
          return card != null && _isOculumBattleCardUnlocked(card);
        }),
      );
    if (oculumBattleDraftTroopIds.isEmpty) {
      oculumBattleDraftTroopIds.addAll([
        'first_strong_archers',
        'first_lancers',
        'first_squires',
        'shadow_knights',
        'black_assassins',
        'grave_vanguard',
      ]);
    }
    if (!_isTacticalSlotCardUsable(oculumBattleGraduatedSlotCardId)) {
      oculumBattleGraduatedSlotCardId = null;
    }
    if (!_isTacticalSlotCardUsable(oculumBattleHeroicSlotCardId) ||
        !unlockedOculumBattleHeroicCardIds.contains(
          oculumBattleHeroicSlotCardId,
        )) {
      oculumBattleHeroicSlotCardId = null;
    }
  }

  Future<void> saveOculumBattleProgressToPrefs(SharedPreferences prefs) async {
    await prefs.setStringList(
      'oculumBattle.unlockedDominantIds',
      unlockedOculumBattleDominantIds.toList()..sort(),
    );
    await prefs.setStringList(
      'oculumBattle.unlockedTroopIds',
      unlockedOculumBattleTroopIds.toList()..sort(),
    );
    await prefs.setStringList(
      'oculumBattle.unlockedPetIds',
      unlockedOculumBattlePetIds.toList()..sort(),
    );
    await prefs.setString(
      'oculumBattle.cardLevels',
      _oculumBattleEncodeIntMap(oculumBattleCardLevels),
    );
    await prefs.setString(
      'oculumBattle.cardMastery',
      _oculumBattleEncodeIntMap(oculumBattleCardMastery),
    );
    await prefs.setString(
      'oculumBattle.cardCopies',
      _oculumBattleEncodeIntMap(oculumBattleCardCopies),
    );
    await prefs.setString(
      'oculumBattle.botMemory',
      _oculumBattleEncodeIntMap(oculumBattleBotMemory),
    );
    await prefs.setStringList(
      'oculumBattle.unlockedHeroicCardIds',
      unlockedOculumBattleHeroicCardIds.toList()..sort(),
    );
    await prefs.setStringList(
      'oculumBattle.equippedTitleIds',
      equippedOculumBattleTitleIds.toList()..sort(),
    );
    await prefs.setStringList(
      'oculumBattle.revealedTitleIds',
      revealedOculumBattleTitleIds.toList()..sort(),
    );
    await prefs.setString(
      'oculumBattle.artUses',
      _oculumBattleEncodeIntMap(oculumBattleArtUses),
    );
    await prefs.setInt('oculumBattle.wins', oculumBattleWins);
    await prefs.setBool(
      'oculumBattle.firstWinPackClaimed',
      oculumBattleFirstWinPackClaimed,
    );
    await prefs.setString(
      'oculumBattle.selectedDominantId',
      oculumBattleSelectedDominantId,
    );
    await prefs.setString('oculumBattle.arenaId', oculumBattleArenaId);
    await prefs.setString(
      'oculumBattle.selectedArtId',
      oculumBattleSelectedArtId,
    );
    await prefs.setInt('oculumBattle.defiledBar', oculumBattleDefiledBar);
    await prefs.setInt(
      'oculumBattle.evolutionPrinciples',
      oculumBattleEvolutionPrinciples,
    );
    if (oculumBattleGraduatedSlotCardId == null) {
      await prefs.remove('oculumBattle.graduatedSlotCardId');
    } else {
      await prefs.setString(
        'oculumBattle.graduatedSlotCardId',
        oculumBattleGraduatedSlotCardId!,
      );
    }
    if (oculumBattleHeroicSlotCardId == null) {
      await prefs.remove('oculumBattle.heroicSlotCardId');
    } else {
      await prefs.setString(
        'oculumBattle.heroicSlotCardId',
        oculumBattleHeroicSlotCardId!,
      );
    }
    await prefs.setStringList(
      'oculumBattle.deckIds',
      oculumBattleDraftTroopIds.toList()..sort(),
    );
  }

  void showOculumBattlePanel() {
    setState(() {
      showOculumBattle = true;
      showEventChoices = true;
      clearChoices(mode: 'battle');
      textIt =
          'Oculum Battle.\nScegli un Dominatore, prepara truppe e pet, poi manda il fronte a morire per te. Allenamento non da ricompense.';
      textEn =
          'Oculum Battle.\nChoose a Dominant, prepare troops and pets, then send the front to die for you. Training gives no rewards.';
      eventChoices.addAll([
        _DungeonChoice(
          labelIt: 'Apri Oculum Battle',
          labelEn: 'Open Oculum Battle',
          icon: Icons.workspace_premium,
          color: const Color(0xFFE7C66B),
          onPressed: () => setState(() => showOculumBattle = true),
        ),
        _DungeonChoice(
          labelIt: 'Allenamento',
          labelEn: 'Training',
          icon: Icons.fitness_center,
          color: const Color(0xFF85F0FF),
          onPressed: () => startOculumBattle(training: true),
        ),
      ]);
    });
  }

  void toggleOculumBattleCard(_OculumBattleTroopDef card) {
    if (!_isOculumBattleCardUnlocked(card)) return;
    setState(() {
      if (oculumBattleDraftTroopIds.contains(card.id)) {
        oculumBattleDraftTroopIds.remove(card.id);
      } else {
        if (oculumBattleDraftTroopIds.length >= 6) {
          oculumBattleLastRewardIt = 'Massimo 6 carte nel fronte.';
          oculumBattleLastRewardEn = 'Maximum 6 cards in the front.';
          return;
        }
        oculumBattleDraftTroopIds.add(card.id);
      }
    });
    unawaited(_savePermanentProgress());
  }

  void toggleOculumBattleGraduatedSlot(_OculumBattleTroopDef card) {
    if (!_isOculumBattleCardUnlocked(card) || card.isPet) return;
    setState(() {
      if (oculumBattleGraduatedSlotCardId == card.id) {
        oculumBattleGraduatedSlotCardId = null;
      } else {
        oculumBattleGraduatedSlotCardId = card.id;
        if (oculumBattleHeroicSlotCardId == card.id) {
          oculumBattleHeroicSlotCardId = null;
        }
      }
      oculumBattleLastRewardIt =
          'Slot Carta Graduata aggiornato: Grado +1 e +25% HP.';
      oculumBattleLastRewardEn =
          'Graduated Card slot updated: Grade +1 and +25% HP.';
    });
    unawaited(_savePermanentProgress());
  }

  void toggleOculumBattleHeroicSlot(_OculumBattleTroopDef card) {
    if (!_isOculumBattleCardUnlocked(card) || card.isPet) return;
    setState(() {
      if (!unlockedOculumBattleHeroicCardIds.contains(card.id)) {
        if (oculumBattleEvolutionPrinciples <= 0) {
          oculumBattleLastRewardIt =
              'Serve un Principio di Evoluzione per rendere evoluta questa carta.';
          oculumBattleLastRewardEn =
              'You need an Evolution Principle to evolve this card.';
          return;
        }
        oculumBattleEvolutionPrinciples -= 1;
        unlockedOculumBattleHeroicCardIds.add(card.id);
        oculumBattleLastRewardIt =
            'Principio di Evoluzione innestato: ${card.nameIt}.';
        oculumBattleLastRewardEn = 'Evolution Principle bound: ${card.nameEn}.';
      }

      if (oculumBattleHeroicSlotCardId == card.id) {
        oculumBattleHeroicSlotCardId = null;
      } else {
        oculumBattleHeroicSlotCardId = card.id;
        if (oculumBattleGraduatedSlotCardId == card.id) {
          oculumBattleGraduatedSlotCardId = null;
        }
      }
    });
    unawaited(_savePermanentProgress());
  }

  int _oculumBattlePetHpBuff() {
    var value = _selectedBattlePets.fold<int>(
      0,
      (sum, pet) => sum + pet.buffHp + (oculumBattleCardLevel(pet.id) ~/ 2),
    );
    if (oculumBattleSelectedDominantId == 'kooba') value += 3;
    if (_selectedBattleArena.id == 'carrion_market') value += 2;
    return value;
  }

  int _oculumBattlePetDamageBuff() {
    var value = _selectedBattlePets.fold<int>(
      0,
      (sum, pet) => sum + pet.buffDamage + (oculumBattleCardLevel(pet.id) ~/ 4),
    );
    if (oculumBattleSelectedDominantId == 'kooba') value += 1;
    return value;
  }

  int _oculumBattleDominantMaxHp(
    _OculumBattleDominantDef dominant, {
    required bool ally,
  }) {
    final level = oculumBattleCardLevel(dominant.id);
    final draftCost = ally
        ? _selectedBattleTroops.fold<int>(0, (sum, card) => sum + card.cost)
        : 9;
    return max(80, dominant.baseHp + level * 28 + draftCost * 7);
  }

  _OculumBattleUnit _makeOculumBattleUnit(
    _OculumBattleTroopDef card, {
    required bool ally,
    required int lane,
    required int index,
    bool shadow = false,
    int hpScale = 100,
    int damageScale = 100,
  }) {
    final graduated = ally && _isGraduatedSlotCard(card.id);
    final heroic = ally && _isHeroicSlotCard(card.id);
    final level = oculumBattleCardLevel(card.id) + (graduated ? 1 : 0);
    final arena = _selectedBattleArena;
    int hp =
        card.baseHp +
        arena.hpDelta +
        (level - 1) * (5 + card.cost * 2) +
        (ally ? _oculumBattlePetHpBuff() : 0);
    int damage =
        card.baseDamage +
        arena.damageDelta +
        (level - 1) * max(1, card.cost).toInt() +
        (ally ? _oculumBattlePetDamageBuff() : 0);
    var armor = card.armor;
    if (ally && oculumBattleSelectedDominantId == 'postea' && index == 0) {
      hp += 12;
      armor += 2;
    }
    if (ally &&
        oculumBattleSelectedDominantId == 'bone_crown' &&
        card.speed <= 2) {
      hp += 10;
      armor += 1;
    }
    if (ally && oculumBattleSelectedDominantId == 'gufus' && card.speed >= 6) {
      damage += 2;
    }
    if (ally &&
        oculumBattleSelectedDominantId == 'goblin_queen' &&
        _isGoblinCard(card)) {
      damage = (damage * 1.5).round();
    }
    if (ally &&
        oculumBattleSelectedDominantId == 'goblin_knight' &&
        card.id == 'goblin_swordsmen') {
      hp = (hp * 2.6).round();
    }
    if (!ally &&
        oculumBattleEnemyDominantId == 'goblin_queen' &&
        _isGoblinCard(card)) {
      damage = (damage * 1.5).round();
    }
    if (!ally &&
        oculumBattleEnemyDominantId == 'goblin_knight' &&
        card.id == 'goblin_swordsmen') {
      hp = (hp * 2.6).round();
    }
    if (_selectedBattleArena.id == 'goblin_camp' && _isGoblinCard(card)) {
      hp += 5;
      damage += 1;
    }
    if (ally &&
        oculumBattleSelectedDominantId == 'first_melee_lord' &&
        _isCloseCard(card)) {
      damage += 4;
    }
    if (ally &&
        oculumBattleSelectedDominantId == 'first_ranged_lord' &&
        _isRangedCard(card)) {
      damage += 4;
    }
    if (ally && oculumBattleSelectedDominantId == 'first_balanced_lord') {
      damage += 2;
      hp += 5;
    }
    if (!ally &&
        oculumBattleEnemyDominantId == 'first_melee_lord' &&
        _isCloseCard(card)) {
      damage += 4;
    }
    if (!ally &&
        oculumBattleEnemyDominantId == 'first_ranged_lord' &&
        _isRangedCard(card)) {
      damage += 4;
    }
    if (!ally && oculumBattleEnemyDominantId == 'first_balanced_lord') {
      damage += 2;
      hp += 5;
    }
    final allyPack = _isArenaPackDominant(oculumBattleSelectedDominantId)
        ? _arenaPackByPrefix(
            _arenaPrefixFromDominant(oculumBattleSelectedDominantId),
          )
        : null;
    if (ally && allyPack != null && card.arenaId == allyPack.arenaId) {
      hp += 7;
      damage += 2;
    }
    final enemyPack = _isArenaPackDominant(oculumBattleEnemyDominantId)
        ? _arenaPackByPrefix(
            _arenaPrefixFromDominant(oculumBattleEnemyDominantId),
          )
        : null;
    if (!ally && enemyPack != null && card.arenaId == enemyPack.arenaId) {
      hp += 7;
      damage += 2;
    }
    if (!ally &&
        oculumBattleEnemyDominantId == 'bone_crown' &&
        card.speed <= 2) {
      hp += 8;
      armor += 1;
    }
    if (ally) {
      hp += _oculumBattleFormationHpBonus();
      damage += _oculumBattleFormationDamageBonus();
    }
    if (graduated) {
      hp = (hp * 1.25).round();
    }
    if (heroic) {
      hp *= 2;
      damage *= 2;
      armor *= 2;
    }
    hp = max(1, (hp * hpScale / 100).round());
    damage = max(1, (damage * damageScale / 100).round());
    final unitColor = ally
        ? _oculumBattleSkinColor(
            card.id,
            heroic
                ? Color.lerp(card.color, const Color(0xFFFFD36A), 0.55)!
                : graduated
                ? Color.lerp(card.color, const Color(0xFFBFA7FF), 0.35)!
                : card.color,
          )
        : card.color;
    return _OculumBattleUnit(
      id: '${ally ? 'a' : 'e'}_${card.id}_${DateTime.now().microsecondsSinceEpoch}_$index',
      cardId: card.id,
      nameIt: card.nameIt,
      nameEn: card.nameEn,
      spriteKind: shadow ? 'shadow_${card.spriteKind}' : card.spriteKind,
      color: shadow ? const Color(0xFF8072AA) : unitColor,
      maxHp: hp,
      hp: hp,
      damage: damage,
      armor: armor,
      speed: card.speed,
      ally: ally,
      pet: card.isPet,
      shadow: shadow,
      graduated: graduated,
      heroic: heroic,
      spawns: card.spawns,
      lane: lane,
    );
  }

  List<_OculumBattleUnit> _expandOculumBattleCardToUnits(
    _OculumBattleTroopDef card, {
    required bool ally,
    required int lane,
    required int index,
    int hpScale = 100,
    int damageScale = 100,
  }) {
    if (card.id == 'goblin_swordsmen') {
      return [
        for (var i = 0; i < 3; i++)
          _makeOculumBattleUnit(
            card,
            ally: ally,
            lane: (lane + i) % 3,
            index: index + i,
            hpScale: hpScale,
            damageScale: damageScale,
          ),
      ];
    }
    if (card.id == 'goblin_fall') {
      return [
        for (var i = 0; i < 2; i++)
          _makeOculumBattleUnit(
            card,
            ally: ally,
            lane: (lane + i) % 3,
            index: index + i,
            hpScale: (hpScale * 0.75).round(),
            damageScale: damageScale,
          ),
      ];
    }
    if (card.id != 'bandit_band') {
      return [
        _makeOculumBattleUnit(
          card,
          ally: ally,
          lane: lane,
          index: index,
          hpScale: hpScale,
          damageScale: damageScale,
        ),
      ];
    }

    final shooter = _OculumBattleTroopDef(
      id: 'bandit_shooter',
      nameIt: 'Bandito tiratore',
      nameEn: 'Bandit shooter',
      descIt: card.descIt,
      descEn: card.descEn,
      spriteKind: 'bandit_shooter',
      color: card.color,
      rarity: card.rarity,
      baseHp: max(18, card.baseHp - 9),
      baseDamage: card.baseDamage + 2,
      armor: card.armor,
      speed: card.speed + 1,
      cost: card.cost,
    );
    final melee = _OculumBattleTroopDef(
      id: 'bandit_melee',
      nameIt: 'Bandito da mischia',
      nameEn: 'Melee bandit',
      descIt: card.descIt,
      descEn: card.descEn,
      spriteKind: 'bandit_melee',
      color: Color.lerp(card.color, Colors.black, 0.2)!,
      rarity: card.rarity,
      baseHp: card.baseHp + 8,
      baseDamage: card.baseDamage,
      armor: card.armor + 1,
      speed: card.speed,
      cost: card.cost,
    );
    return [
      _makeOculumBattleUnit(
        shooter,
        ally: ally,
        lane: lane,
        index: index,
        hpScale: hpScale,
        damageScale: damageScale,
      ),
      _makeOculumBattleUnit(
        shooter,
        ally: ally,
        lane: (lane + 1) % 3,
        index: index + 1,
        hpScale: hpScale,
        damageScale: damageScale,
      ),
      _makeOculumBattleUnit(
        melee,
        ally: ally,
        lane: (lane + 2) % 3,
        index: index + 2,
        hpScale: hpScale,
        damageScale: damageScale,
      ),
    ];
  }

  void startOculumBattle({bool training = false}) {
    final troops = _battleTroopsWithTacticalSlots;
    if (troops.isEmpty) {
      setState(() {
        oculumBattleLastRewardIt = 'Serve almeno una truppa non-pet.';
        oculumBattleLastRewardEn = 'You need at least one non-pet troop.';
      });
      return;
    }

    final rng = Random(DateTime.now().microsecondsSinceEpoch);
    final enemyDominants = _oculumBattleDominants
        .where((dominant) => dominant.id != oculumBattleSelectedDominantId)
        .toList();
    final enemyDominant = enemyDominants[rng.nextInt(enemyDominants.length)];
    final enemyPool = _oculumBattleTroops.where((card) => !card.isPet).toList();
    final enemyCount = training
        ? 3
        : (4 + min(2, oculumBattleWins ~/ 3)).toInt();
    _learnOculumBattleStyleFromCards(<_OculumBattleTroopDef>[
      ...troops,
      ..._selectedBattlePets,
    ]);
    final enemyCards = _draftOculumBattleBotCards(rng, enemyCount, enemyPool);

    setState(() {
      oculumBattleTrainingMode = training;
      oculumBattleActive = true;
      oculumBattleFinished = false;
      oculumBattleVictory = false;
      oculumBattleTurn = 0;
      oculumBattleEnemyDominantId = enemyDominant.id;
      oculumBattleDominantHp = _oculumBattleDominantMaxHp(
        _selectedBattleDominant,
        ally: true,
      );
      oculumBattleEnemyDominantHp = _oculumBattleDominantMaxHp(
        enemyDominant,
        ally: false,
      );
      if (training) {
        oculumBattleEnemyDominantHp = (oculumBattleEnemyDominantHp * 0.82)
            .round();
      }
      oculumBattleActivatedTitleIds.clear();
      oculumBattleArtUses[oculumBattleSelectedArtId] =
          _selectedBattleArt.baseUses;
      if (oculumBattleSelectedArtId != 'defiled') {
        oculumBattleDefiledBar = 0;
      }

      oculumBattleAllies
        ..clear()
        ..addAll([
          for (var i = 0; i < troops.length; i++)
            ..._expandOculumBattleCardToUnits(
              troops[i],
              ally: true,
              lane: i % 3,
              index: i * 3,
            ),
          for (var i = 0; i < _selectedBattlePets.length; i++)
            _makeOculumBattleUnit(
              _selectedBattlePets[i],
              ally: true,
              lane: (i + troops.length) % 3,
              index: i + troops.length,
              hpScale: 85,
            ),
        ]);
      oculumBattleEnemies
        ..clear()
        ..addAll([
          for (var i = 0; i < enemyCards.length; i++)
            ..._expandOculumBattleCardToUnits(
              enemyCards[i],
              ally: false,
              lane: i % 3,
              index: i * 3,
              hpScale: training ? 88 : 100 + min(35, oculumBattleWins * 2),
              damageScale: training ? 85 : 100 + min(25, oculumBattleWins),
            ),
        ]);
      oculumBattleLog
        ..clear()
        ..add(
          training
              ? 'Allenamento aperto nella ${_selectedBattleArena.nameIt}.'
              : 'Battaglia aperta nella ${_selectedBattleArena.nameIt}.',
        )
        ..add(
          '${_selectedBattleDominant.nameIt} contro ${enemyDominant.nameIt}.',
        );
      _applyGoblinFallImpact(
        ally: true,
        count: troops.where((card) => card.id == 'goblin_fall').length,
      );
      _applyGoblinFallImpact(
        ally: false,
        count: enemyCards.where((card) => card.id == 'goblin_fall').length,
      );
      oculumBattleLastRewardIt = '';
      oculumBattleLastRewardEn = '';
      showOculumBattle = true;
    });
    unawaited(_savePermanentProgress());
  }

  void advanceOculumBattleRound() {
    if (!oculumBattleActive || oculumBattleFinished) return;
    setState(() {
      oculumBattleTurn += 1;
      _applyOculumBattleStartOfTurnEffects();
      _spawnOculumBattleMinions(ally: true);
      _spawnOculumBattleMinions(ally: false);
      _resolveOculumBattleAttacks(ally: true);
      _resolveOculumBattleAttacks(ally: false);
      _removeDeadOculumBattleUnits();
      _applyOculumBattleDominantPressure();
      _applyOculumBattleRulerTitleTriggers();
      _finishOculumBattleIfNeeded();
    });
    unawaited(_savePermanentProgress());
  }

  void _applyOculumBattleStartOfTurnEffects() {
    if (oculumBattleSelectedDominantId == 'eiva' ||
        oculumBattleSelectedDominantId == 'valley') {
      for (final unit in oculumBattleAllies.where((unit) => unit.alive)) {
        final heal = oculumBattleSelectedDominantId == 'valley' && unit.pet
            ? 5
            : 3;
        unit.hp = min(unit.maxHp, unit.hp + heal);
      }
    }
    if (oculumBattleEnemyDominantId == 'eiva') {
      for (final unit in oculumBattleEnemies.where((unit) => unit.alive)) {
        unit.hp = min(unit.maxHp, unit.hp + 2);
      }
    }
    if (oculumBattleSelectedDominantId == 'goblin_knight') {
      for (final unit in oculumBattleAllies.where(
        (unit) => unit.alive && unit.cardId != 'goblin_swordsmen',
      )) {
        unit.hp = min(unit.maxHp, unit.hp + 5);
      }
    }
    if (oculumBattleEnemyDominantId == 'goblin_knight') {
      for (final unit in oculumBattleEnemies.where(
        (unit) => unit.alive && unit.cardId != 'goblin_swordsmen',
      )) {
        unit.hp = min(unit.maxHp, unit.hp + 5);
      }
    }
    if (oculumBattleSelectedDominantId == 'null_fateless' &&
        oculumBattleEnemies.isNotEmpty) {
      final target = oculumBattleEnemies
          .where((unit) => unit.alive)
          .fold<_OculumBattleUnit?>(null, (best, unit) {
            if (best == null || unit.damage > best.damage) return unit;
            return best;
          });
      if (target != null) {
        target.damage = max(1, target.damage - 1);
        oculumBattleLog.add('Null Fateless corrode un colpo nemico.');
      }
    }
    _applyGoblinMageCurseBalls(ally: true);
    _applyGoblinMageCurseBalls(ally: false);
    _applyShadowKnightStep(ally: true);
    _applyShadowKnightStep(ally: false);
    _applyArenaCasterPulse(ally: true);
    _applyArenaCasterPulse(ally: false);
    _applyHeroicEvolutionPowers(ally: true);
    _applyHeroicEvolutionPowers(ally: false);
    _applySlimeRoyalEffects(ally: true);
    _applySlimeRoyalEffects(ally: false);
  }

  void _applyShadowKnightStep({required bool ally}) {
    if (oculumBattleTurn == 0 || oculumBattleTurn % 5 != 0) return;
    final knights = (ally ? oculumBattleAllies : oculumBattleEnemies)
        .where((unit) => unit.alive && unit.cardId == 'shadow_knights')
        .toList();
    if (knights.isEmpty) return;
    final targets = ally ? oculumBattleEnemies : oculumBattleAllies;
    for (final knight in knights) {
      final target = _strongestOculumBattleUnit(targets);
      if (target == null) continue;
      _applyOculumBattleDamage(target, knight.damage + 18);
    }
    oculumBattleLog.add(
      ally
          ? 'I Cavalieri dell ombra si tippano nell ombra nemica.'
          : 'Cavalieri dell ombra nemici appaiono nella tua retrovia.',
    );
  }

  void _applyArenaCasterPulse({required bool ally}) {
    if (oculumBattleTurn % 3 != 0) return;
    final casters = (ally ? oculumBattleAllies : oculumBattleEnemies)
        .where((unit) => unit.alive && unit.cardId.endsWith('_caster'))
        .toList();
    if (casters.isEmpty) return;
    final targets = ally ? oculumBattleEnemies : oculumBattleAllies;
    for (final target in targets.where((unit) => unit.alive).take(3).toList()) {
      _applyOculumBattleDamage(target, 5 + casters.length * 2);
    }
  }

  void _applyHeroicEvolutionPowers({required bool ally}) {
    final heroes = (ally ? oculumBattleAllies : oculumBattleEnemies)
        .where((unit) => unit.alive && unit.heroic)
        .toList();
    if (heroes.isEmpty) return;
    final enemies = ally ? oculumBattleEnemies : oculumBattleAllies;
    final friends = ally ? oculumBattleAllies : oculumBattleEnemies;
    for (final hero in heroes) {
      if (_isPriorityTarget(hero)) {
        hero.hp = min(hero.maxHp, hero.hp + 10);
        for (final friend in friends.where((unit) => unit.alive).take(4)) {
          friend.hp = min(friend.maxHp, friend.hp + 4);
        }
        continue;
      }
      if (_isRangedUnit(hero)) {
        if (oculumBattleTurn % 2 == 0) {
          final target = _weakestOculumBattleUnit(enemies);
          if (target != null) {
            _applyOculumBattleDamage(target, 8 + hero.damage ~/ 2);
          }
        }
        continue;
      }
      if (_isGoblinUnit(hero)) {
        if (oculumBattleTurn % 2 == 0) {
          _summonOculumBattleCard(
            'weak_goblin',
            ally: ally,
            count: 1,
            lane: hero.lane,
            hpScale: 80,
            damageScale: 80,
          );
        }
        continue;
      }
      if (hero.cardId.contains('slime')) {
        if (oculumBattleTurn % 2 == 0) {
          _summonOculumBattleCard(
            'ash_slime',
            ally: ally,
            count: 1,
            lane: hero.lane,
            hpScale: 70,
            damageScale: 70,
          );
        }
        continue;
      }
      if (hero.cardId.contains('spawner') || hero.cardId.endsWith('_caster')) {
        if (oculumBattleTurn % 3 == 0) {
          _summonOculumBattleCard(
            hero.cardId,
            ally: ally,
            count: 1,
            lane: hero.lane,
            hpScale: 45,
            damageScale: 55,
          );
        }
        continue;
      }
      final target = hero.cardId.contains('assassin')
          ? _weakestOculumBattleUnit(enemies)
          : _strongestOculumBattleUnit(enemies);
      if (target != null && oculumBattleTurn % 2 == 1) {
        _applyOculumBattleDamage(target, 10 + hero.damage ~/ 3);
      }
    }
  }

  void _applyGoblinMageCurseBalls({required bool ally}) {
    final mages = (ally ? oculumBattleAllies : oculumBattleEnemies)
        .where((unit) => unit.alive && unit.cardId == 'goblin_mages')
        .toList();
    if (mages.isEmpty || oculumBattleTurn % 2 != 0) return;
    final targets = ally ? oculumBattleEnemies : oculumBattleAllies;
    var converted = 0;
    for (final target in targets.where((unit) => unit.alive).toList()) {
      final died = _applyGoblinConvertingDamage(target, 6 + mages.length * 2);
      if (died) converted += 1;
    }
    if (converted > 0) {
      _summonOculumBattleCard(
        'weak_goblin',
        ally: ally,
        count: converted,
        lane: 1,
        hpScale: 70,
        damageScale: 70,
      );
    }
    oculumBattleLog.add('I goblin maghi lanciano palle di maledizione.');
  }

  void _applySlimeRoyalEffects({required bool ally}) {
    final source = (ally ? oculumBattleAllies : oculumBattleEnemies)
        .where(
          (unit) =>
              unit.alive &&
              (unit.cardId == 'king_slime' || unit.cardId == 'prince_slime'),
        )
        .toList();
    if (source.isEmpty) return;
    final targets = ally ? oculumBattleEnemies : oculumBattleAllies;
    for (final slime in source) {
      final isKing = slime.cardId == 'king_slime';
      if (oculumBattleTurn % (isKing ? 2 : 3) == 0) {
        for (final target in targets.where((unit) => unit.alive).toList()) {
          _applyOculumBattleDamage(target, isKing ? 7 : 4);
        }
        oculumBattleLog.add(
          isKing
              ? 'King Slime trascina il fronte con vortici di gelatina.'
              : 'Prince Slime attira i nemici nel fango vivo.',
        );
      }
      if (isKing && oculumBattleTurn % 3 == 0) {
        _summonOculumBattleCard(
          'ash_slime',
          ally: ally,
          count: 2,
          lane: slime.lane,
          hpScale: 35,
          damageScale: 45,
        );
      }
    }
  }

  void _spawnOculumBattleMinions({required bool ally}) {
    final list = ally ? oculumBattleAllies : oculumBattleEnemies;
    final additions = <_OculumBattleUnit>[];
    for (final unit in list.where((unit) => unit.alive).toList()) {
      unit.age += 1;
      if (unit.spawns <= 0 || unit.age % 2 != 0) continue;
      final base = _oculumBattleCardById(unit.cardId);
      if (base == null) continue;
      for (var i = 0; i < min(2, unit.spawns); i++) {
        additions.add(
          _makeOculumBattleUnit(
            base,
            ally: ally,
            lane: unit.lane,
            index: list.length + additions.length,
            hpScale: 42,
            damageScale: 55,
          ),
        );
      }
    }
    if (additions.isNotEmpty) {
      list.addAll(additions);
      oculumBattleLog.add(
        ally
            ? 'Gli spawner alleati sputano resti deboli.'
            : 'Gli spawner nemici aprono nuove sacche.',
      );
    }
  }

  void _resolveOculumBattleAttacks({required bool ally}) {
    final attackers =
        (ally ? oculumBattleAllies : oculumBattleEnemies)
            .where((unit) => unit.alive)
            .toList()
          ..sort((a, b) => b.speed.compareTo(a.speed));
    for (final attacker in attackers) {
      if (!attacker.alive) continue;
      if (attacker.stunnedTurns > 0) {
        attacker.stunnedTurns -= 1;
        continue;
      }
      final defenders = (ally ? oculumBattleEnemies : oculumBattleAllies)
          .where((unit) => unit.alive)
          .toList();
      if (defenders.isEmpty) break;
      defenders.sort((a, b) {
        final priority = (_isPriorityTarget(b) ? 1 : 0).compareTo(
          _isPriorityTarget(a) ? 1 : 0,
        );
        if (priority != 0) return priority;
        if (attacker.spriteKind.contains('hound')) {
          return a.hp.compareTo(b.hp);
        }
        final laneDistance = (a.lane - attacker.lane).abs().compareTo(
          (b.lane - attacker.lane).abs(),
        );
        if (laneDistance != 0) return laneDistance;
        return a.hp.compareTo(b.hp);
      });
      final target = defenders.first;
      final dealt = max(1, attacker.damage - target.armor);
      _applyOculumBattleDamage(target, dealt);
    }
  }

  void _applyOculumBattleDamage(_OculumBattleUnit target, int amount) {
    if (!target.alive) return;
    target.hp = max(0, target.hp - amount);
    if (target.hp <= 0) {
      _handleOculumBattleDeathEffect(target);
    }
    final dominantId = target.ally
        ? oculumBattleSelectedDominantId
        : oculumBattleEnemyDominantId;
    if (dominantId != 'noctis' ||
        target.shadow ||
        target.pet ||
        target.shadowSpawned) {
      return;
    }
    target.shadowSpawned = true;
    final source = _oculumBattleCardById(target.cardId);
    if (source == null) return;
    final shadowUnit = _makeOculumBattleUnit(
      source,
      ally: target.ally,
      lane: target.lane,
      index: target.ally
          ? oculumBattleAllies.length
          : oculumBattleEnemies.length,
      shadow: true,
      hpScale: 25,
      damageScale: 75,
    );
    if (target.ally) {
      oculumBattleAllies.add(shadowUnit);
    } else {
      oculumBattleEnemies.add(shadowUnit);
    }
    oculumBattleLog.add(
      target.ally
          ? 'Noctis strappa un ombra dal sangue alleato.'
          : 'Noctis nemico genera un ombra.',
    );
  }

  bool _applyGoblinConvertingDamage(_OculumBattleUnit target, int amount) {
    if (!target.alive) return false;
    _applyOculumBattleDamage(target, amount);
    return !target.alive;
  }

  void _handleOculumBattleDeathEffect(_OculumBattleUnit unit) {
    if (unit.cardId == 'fusing_slimes') {
      _summonOculumBattleCard(
        'prince_slime',
        ally: unit.ally,
        count: 1,
        lane: unit.lane,
        hpScale: 80,
        damageScale: 85,
      );
      oculumBattleLog.add('Gli slime fondenti diventano un Prince Slime.');
      return;
    }
    if (unit.cardId == 'prince_slime') {
      _summonOculumBattleCard(
        'ash_slime',
        ally: unit.ally,
        count: 6,
        lane: unit.lane,
        hpScale: 30,
        damageScale: 40,
      );
      oculumBattleLog.add('Il Prince Slime esplode in 6 slime deboli.');
      return;
    }
    if (unit.cardId == 'king_slime') {
      _summonOculumBattleCard(
        'ash_slime',
        ally: unit.ally,
        count: 12,
        lane: unit.lane,
        hpScale: 28,
        damageScale: 38,
      );
      oculumBattleLog.add('Il King Slime muore e vomita 12 slime deboli.');
      return;
    }
    if (unit.cardId == 'undead_exploder' || unit.cardId.endsWith('_exploder')) {
      final targets = unit.ally ? oculumBattleEnemies : oculumBattleAllies;
      for (final target
          in targets.where((unit) => unit.alive).take(4).toList()) {
        _applyOculumBattleDamage(target, unit.heroic ? 34 : 18);
      }
      oculumBattleLog.add(
        unit.ally
            ? 'Il cadavere gonfio esplode tra i nemici.'
            : 'Un non morto esplode contro il tuo fronte.',
      );
    }
  }

  void _summonOculumBattleCard(
    String cardId, {
    required bool ally,
    required int count,
    required int lane,
    int hpScale = 100,
    int damageScale = 100,
  }) {
    final card = _oculumBattleCardById(cardId);
    if (card == null) return;
    final list = ally ? oculumBattleAllies : oculumBattleEnemies;
    for (var i = 0; i < count; i++) {
      list.add(
        _makeOculumBattleUnit(
          card,
          ally: ally,
          lane: (lane + i) % 3,
          index: list.length + i,
          hpScale: hpScale,
          damageScale: damageScale,
        ),
      );
    }
  }

  void _applyGoblinFallImpact({required bool ally, required int count}) {
    if (count <= 0) return;
    final targets = ally ? oculumBattleEnemies : oculumBattleAllies;
    final damage = 10 + count * 4;
    for (final target in targets.where((unit) => unit.alive).take(3).toList()) {
      _applyOculumBattleDamage(target, damage);
    }
    oculumBattleLog.add(
      ally
          ? 'Caduta goblin: due lame corte piovono nella zona avversaria.'
          : 'Caduta goblin nemica: il cielo tossisce spade corte.',
    );
  }

  void _removeDeadOculumBattleUnits() {
    oculumBattleAllies.removeWhere((unit) => !unit.alive);
    oculumBattleEnemies.removeWhere((unit) => !unit.alive);
  }

  void _applyOculumBattleDominantPressure() {
    final arena = _selectedBattleArena;
    final allyPressure = oculumBattleAllies
        .where((unit) => unit.alive && !unit.pet)
        .fold<int>(0, (sum, unit) => sum + 2 + unit.damage ~/ 4);
    final enemyPressure = oculumBattleEnemies
        .where((unit) => unit.alive && !unit.pet)
        .fold<int>(0, (sum, unit) => sum + 2 + unit.damage ~/ 4);
    var allyBonus = arena.pressureDelta;
    var enemyBonus = arena.pressureDelta;
    if (oculumBattleSelectedDominantId == 'hires') allyBonus += 2;
    if (oculumBattleEnemyDominantId == 'hires') enemyBonus += 2;
    if (oculumBattleSelectedDominantId == 'gufus' && oculumBattleTurn == 1) {
      allyBonus += 3;
    }
    if (oculumBattleSelectedDominantId == 'bone_crown') allyBonus += 1;
    if (oculumBattleEnemyDominantId == 'bone_crown') enemyBonus += 1;
    oculumBattleEnemyDominantHp = max(
      0,
      oculumBattleEnemyDominantHp - max(0, allyPressure + allyBonus),
    );
    oculumBattleDominantHp = max(
      0,
      oculumBattleDominantHp - max(0, enemyPressure + enemyBonus),
    );
  }

  void _applyOculumBattleRulerTitleTriggers() {
    _tryOculumBattleRulerTitleTrigger(
      dominantId: oculumBattleSelectedDominantId,
      ally: true,
      currentHp: oculumBattleDominantHp,
      maxHp: _oculumBattleDominantMaxHp(_selectedBattleDominant, ally: true),
    );
    _tryOculumBattleRulerTitleTrigger(
      dominantId: oculumBattleEnemyDominantId,
      ally: false,
      currentHp: oculumBattleEnemyDominantHp,
      maxHp: _oculumBattleDominantMaxHp(_enemyBattleDominant, ally: false),
    );
  }

  void _tryOculumBattleRulerTitleTrigger({
    required String dominantId,
    required bool ally,
    required int currentHp,
    required int maxHp,
  }) {
    if (currentHp <= 0) return;
    final threshold =
        dominantId == 'goblin_queen' || dominantId == 'goblin_knight'
        ? 0.50
        : dominantId.startsWith('first_') || _isArenaPackDominant(dominantId)
        ? 0.35
        : 0.25;
    if (currentHp > max(1, (maxHp * threshold).floor())) return;
    final key = '${ally ? 'a' : 'e'}:$dominantId';
    if (oculumBattleActivatedTitleIds.contains(key)) return;
    if (ally && !equippedOculumBattleTitleIds.contains(dominantId)) return;
    final title = _rulerTitleFor(dominantId);
    if (title == null) return;
    oculumBattleActivatedTitleIds.add(key);
    if (ally) revealedOculumBattleTitleIds.add(dominantId);
    final list = ally ? oculumBattleAllies : oculumBattleEnemies;
    final enemyList = ally ? oculumBattleEnemies : oculumBattleAllies;
    switch (dominantId) {
      case 'noctis':
        final source = list.where((unit) => unit.alive && !unit.pet).isEmpty
            ? null
            : list.where((unit) => unit.alive && !unit.pet).first;
        if (source != null) {
          final card = _oculumBattleCardById(source.cardId);
          if (card != null) {
            for (var i = 0; i < 2; i++) {
              list.add(
                _makeOculumBattleUnit(
                  card,
                  ally: ally,
                  lane: (source.lane + i) % 3,
                  index: list.length + i,
                  shadow: true,
                  hpScale: 25,
                  damageScale: 75,
                ),
              );
            }
          }
        }
        break;
      case 'eiva':
        for (final unit in list.where((unit) => unit.alive)) {
          unit.hp = min(unit.maxHp, unit.hp + 18);
        }
        _summonOculumBattleCard(
          'weak_spawner',
          ally: ally,
          count: 1,
          lane: 1,
          hpScale: 80,
          damageScale: 70,
        );
        break;
      case 'valley':
        for (final unit in list.where((unit) => unit.alive)) {
          unit.armor += 2;
          unit.hp = min(unit.maxHp, unit.hp + 8);
        }
        break;
      case 'gufus':
        for (var i = 0; i < 3; i++) {
          final target = _weakestOculumBattleUnit(enemyList);
          if (target == null) break;
          _applyOculumBattleDamage(target, 14);
        }
        break;
      case 'postea':
        for (final unit in list.where((unit) => unit.alive).take(3)) {
          unit.armor += 3;
          unit.hp = min(unit.maxHp, unit.hp + 12);
        }
        break;
      case 'kooba':
        for (final unit in list.where((unit) => unit.alive)) {
          unit.damage += unit.pet ? 4 : 1;
        }
        break;
      case 'hires':
        if (ally) {
          oculumBattleEnemyDominantHp = max(
            0,
            oculumBattleEnemyDominantHp - 34,
          );
        } else {
          oculumBattleDominantHp = max(0, oculumBattleDominantHp - 34);
        }
        break;
      case 'null_fateless':
        for (final unit in enemyList.where((unit) => unit.alive).take(4)) {
          unit.damage = max(1, unit.damage ~/ 2);
        }
        break;
      case 'bone_crown':
        _summonOculumBattleCard(
          'bone_hounds',
          ally: ally,
          count: 2,
          lane: 1,
          hpScale: 85,
          damageScale: 85,
        );
        break;
      case 'goblin_queen':
      case 'goblin_knight':
        for (final unit in list.where(
          (unit) => unit.alive && _isGoblinUnit(unit),
        )) {
          final bonusHp = max(1, (unit.maxHp * 0.25).round());
          unit.maxHp += bonusHp;
          unit.hp += bonusHp;
          unit.damage = max(1, (unit.damage * 1.25).round());
        }
        break;
      case 'first_melee_lord':
        _buffOculumBattleUnits(
          list.where((unit) => unit.alive && _isCloseUnit(unit)),
          hpPct: 0.22,
          damagePct: 0.25,
        );
        break;
      case 'first_balanced_lord':
        _buffOculumBattleUnits(
          list.where((unit) => unit.alive),
          hpPct: 0.12,
          damagePct: 0.12,
        );
        break;
      case 'first_ranged_lord':
        _buffOculumBattleUnits(
          list.where((unit) => unit.alive && _isRangedUnit(unit)),
          hpPct: 0.18,
          damagePct: 0.28,
        );
        break;
    }
    if (_isArenaPackDominant(dominantId)) {
      final pack = _arenaPackByPrefix(_arenaPrefixFromDominant(dominantId));
      if (pack != null) {
        _buffOculumBattleUnits(
          list.where(
            (unit) => unit.alive && unit.cardId.startsWith(pack.prefix),
          ),
          hpPct: 0.20,
          damagePct: 0.20,
        );
      }
    }
    oculumBattleLog.add(
      ally
          ? 'Titolo rivelato: ${title.nameIt}.'
          : 'Il titolo nemico si apre: ${title.nameIt}.',
    );
  }

  bool _isCloseUnit(_OculumBattleUnit unit) {
    final card = _oculumBattleCardById(unit.cardId);
    if (card != null) return _isCloseCard(card);
    return unit.cardId.contains('assassin') ||
        unit.cardId.contains('vanguard') ||
        unit.spriteKind.contains('assassin') ||
        unit.spriteKind.contains('vanguard') ||
        unit.spriteKind.contains('knight');
  }

  bool _isRangedUnit(_OculumBattleUnit unit) {
    final card = _oculumBattleCardById(unit.cardId);
    if (card != null) return _isRangedCard(card);
    return unit.cardId.contains('archer') ||
        unit.cardId.contains('ranger') ||
        unit.spriteKind.contains('archer') ||
        unit.spriteKind.contains('ranger') ||
        unit.spriteKind.contains('mage');
  }

  void _buffOculumBattleUnits(
    Iterable<_OculumBattleUnit> units, {
    required double hpPct,
    required double damagePct,
  }) {
    for (final unit in units) {
      final bonusHp = max(1, (unit.maxHp * hpPct).round());
      unit.maxHp += bonusHp;
      unit.hp += bonusHp;
      unit.damage = max(1, (unit.damage * (1 + damagePct)).round());
    }
  }

  _OculumBattleUnit? _weakestOculumBattleUnit(List<_OculumBattleUnit> units) {
    final alive = units.where((unit) => unit.alive).toList();
    if (alive.isEmpty) return null;
    alive.sort((a, b) => a.hp.compareTo(b.hp));
    return alive.first;
  }

  void _finishOculumBattleIfNeeded() {
    if (oculumBattleEnemyDominantHp <= 0 || oculumBattleEnemies.isEmpty) {
      _completeOculumBattleVictory();
      return;
    }
    if (oculumBattleDominantHp <= 0 || oculumBattleAllies.isEmpty) {
      oculumBattleActive = false;
      oculumBattleFinished = true;
      oculumBattleVictory = false;
      oculumBattleLog.add(
        oculumBattleTrainingMode
            ? 'Allenamento perso. Nessuna conseguenza.'
            : 'Il tuo Dominatore cade sotto il peso delle truppe rimaste.',
      );
    }
  }

  void _completeOculumBattleVictory() {
    oculumBattleActive = false;
    oculumBattleFinished = true;
    oculumBattleVictory = true;
    if (oculumBattleTrainingMode) {
      oculumBattleLog.add('Allenamento vinto. Nessuna ricompensa.');
      oculumBattleLastRewardIt = 'Allenamento completato: nessun drop.';
      oculumBattleLastRewardEn = 'Training complete: no drop.';
      return;
    }

    final previousWins = oculumBattleWins;
    oculumBattleWins += 1;
    if (previousWins == 0 && !oculumBattleFirstWinPackClaimed) {
      oculumBattleLastRewardIt =
          'Prima vittoria: scegli un pacco Dominatori con 6-13 entita e un Dominatore forzato.';
      oculumBattleLastRewardEn =
          'First victory: choose a Dominant pack with 6-13 entities and a forced Dominant.';
      oculumBattleLog.add('Prima vittoria: il patto chiede un pacco.');
      return;
    }

    final reward = _grantOculumBattleVictoryDrop();
    oculumBattleLastRewardIt = reward.$1;
    oculumBattleLastRewardEn = reward.$2;
    oculumBattleLog.add(reward.$1);
  }

  (String, String) _grantOculumBattleVictoryDrop() {
    final rng = Random(DateTime.now().microsecondsSinceEpoch);
    final roll = rng.nextInt(100);
    if (roll < 4) {
      final id = _randomOculumBattleDominantId(rng);
      return _grantOculumBattleCard(id);
    }
    if (roll < 11) {
      oculumBattleEvolutionPrinciples += 1;
      return (
        'Hai trovato un Principio di Evoluzione.',
        'You found an Evolution Principle.',
      );
    }
    final id = roll < 24
        ? _randomOculumBattlePetId(rng)
        : _randomOculumBattleMonsterId(rng);
    return _grantOculumBattleCard(id);
  }

  String _randomOculumBattleMonsterId(Random rng) {
    final pool = _oculumBattleTroops.where((card) => !card.isPet).toList();
    return _weightedOculumBattleCardDrop(rng, pool).id;
  }

  String _randomOculumBattlePetId(Random rng) {
    final pool = _oculumBattleTroops.where((card) => card.isPet).toList();
    return _weightedOculumBattleCardDrop(rng, pool).id;
  }

  _OculumBattleTroopDef _weightedOculumBattleCardDrop(
    Random rng,
    List<_OculumBattleTroopDef> pool,
  ) {
    final weights = [
      for (final card in pool) _oculumBattleRarityDropWeight(card.rarity),
    ];
    final total = weights.fold<int>(0, (sum, weight) => sum + weight);
    var roll = rng.nextInt(max(1, total));
    for (var i = 0; i < pool.length; i++) {
      roll -= weights[i];
      if (roll < 0) return pool[i];
    }
    return pool.last;
  }

  String _randomOculumBattleDominantId(Random rng) {
    return _oculumBattleDominants[rng.nextInt(_oculumBattleDominants.length)]
        .id;
  }

  void openOculumBattleDominantPack(String packId) {
    if (oculumBattleFirstWinPackClaimed) return;
    final rng = Random(DateTime.now().microsecondsSinceEpoch + packId.hashCode);
    final forcedDominantId = switch (packId) {
      'moon' => 'noctis',
      'root' => 'eiva',
      'story' => ['valley', 'gufus', 'postea'][rng.nextInt(3)],
      _ => 'bone_crown',
    };
    final count = 6 + rng.nextInt(8);
    final rewards = <String>[forcedDominantId];
    while (rewards.length < count) {
      final roll = rng.nextInt(100);
      if (roll < 12) {
        rewards.add(_randomOculumBattleDominantId(rng));
      } else if (roll < 35) {
        rewards.add(_randomOculumBattlePetId(rng));
      } else {
        rewards.add(_randomOculumBattleMonsterId(rng));
      }
    }

    final namesIt = <String>[];
    final namesEn = <String>[];
    setState(() {
      oculumBattleFirstWinPackClaimed = true;
      for (final id in rewards) {
        final result = _grantOculumBattleCard(id);
        namesIt.add(result.$1);
        namesEn.add(result.$2);
      }
      oculumBattleLastRewardIt = 'Pacco aperto: ${namesIt.join(' | ')}';
      oculumBattleLastRewardEn = 'Pack opened: ${namesEn.join(' | ')}';
      oculumBattleLog.add('Pacco Dominatori aperto.');
    });
    unawaited(_savePermanentProgress());
  }

  (String, String) _grantOculumBattleCard(String id) {
    _OculumBattleDominantDef? dominant;
    for (final item in _oculumBattleDominants) {
      if (item.id == id) {
        dominant = item;
        break;
      }
    }
    if (dominant != null) {
      final wasNew = unlockedOculumBattleDominantIds.add(id);
      final leveled = _addOculumBattleCardMastery(id, amount: wasNew ? 1 : 4);
      return (
        wasNew
            ? 'Nuovo Dominatore: ${dominant.nameIt}'
            : 'Dominatore duplicato: ${dominant.nameIt}${leveled ? ' aumenta di Grado' : ''}',
        wasNew
            ? 'New Dominant: ${dominant.nameEn}'
            : 'Duplicate Dominant: ${dominant.nameEn}${leveled ? ' Grade up' : ''}',
      );
    }

    final card = _oculumBattleCardById(id);
    if (card == null) return ('Eco vuota', 'Empty echo');
    final rarityIt = _oculumBattleRarityLabelFor(card.rarity, english: false);
    final rarityEn = _oculumBattleRarityLabelFor(card.rarity, english: true);
    final wasNew = card.isPet
        ? unlockedOculumBattlePetIds.add(id)
        : unlockedOculumBattleTroopIds.add(id);
    final leveled = _addOculumBattleCardMastery(
      id,
      amount: wasNew
          ? 1
          : card.isPet
          ? 3
          : 2,
    );
    return (
      wasNew
          ? 'Nuova entita $rarityIt: ${card.nameIt}'
          : 'Carta $rarityIt trovata: ${card.nameIt}${leveled ? ' aumenta di Grado' : ''}',
      wasNew
          ? 'New $rarityEn entity: ${card.nameEn}'
          : '$rarityEn card found: ${card.nameEn}${leveled ? ' Grade up' : ''}',
    );
  }

  bool _addOculumBattleCardMastery(String id, {required int amount}) {
    oculumBattleCardCopies[id] = (oculumBattleCardCopies[id] ?? 0) + 1;
    var mastery = (oculumBattleCardMastery[id] ?? 0) + amount;
    var level = oculumBattleCardLevel(id);
    var leveled = false;
    while (mastery >= oculumBattleMasteryTarget(id)) {
      mastery -= oculumBattleMasteryTarget(id);
      level += 1;
      leveled = true;
    }
    oculumBattleCardMastery[id] = mastery;
    oculumBattleCardLevels[id] = level;
    return leveled;
  }

  Widget buildOculumBattlePanel(Color c) {
    if (!showOculumBattle) return const SizedBox.shrink();
    final dominant = _selectedBattleDominant;
    final enemy = _enemyBattleDominant;
    final arena = _selectedBattleArena;
    final canClaimPack =
        oculumBattleWins >= 1 && !oculumBattleFirstWinPackClaimed;
    return compactCard(
      borderColor: const Color(0xFFE7C66B),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/oculum/sprites/Crown_of_Bones.png',
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Oculum Battle',
                  style: const TextStyle(
                    color: Color(0xFFE7C66B),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              statChip(
                t('Vittorie', 'Wins'),
                '$oculumBattleWins',
                color: const Color(0xFFE7C66B),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildOculumBattleDominantSelector(),
          const SizedBox(height: 10),
          _buildOculumBattleArenaSelector(arena),
          const SizedBox(height: 10),
          _buildOculumBattleDeckSelector(),
          const SizedBox(height: 10),
          _buildOculumBattleArtSelector(),
          const SizedBox(height: 10),
          _buildOculumBattleArena(dominant, enemy, arena),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              modernActionButton(
                label: t('Battaglia', 'Battle'),
                icon: Icons.local_fire_department,
                color: const Color(0xFFE11D48),
                onPressed: () => startOculumBattle(),
                compact: true,
              ),
              modernActionButton(
                label: t('Allenamento', 'Training'),
                icon: Icons.fitness_center,
                color: const Color(0xFF85F0FF),
                onPressed: () => startOculumBattle(training: true),
                compact: true,
              ),
              modernActionButton(
                label: t('Turno', 'Turn'),
                icon: Icons.double_arrow,
                color: const Color(0xFFE7C66B),
                onPressed: oculumBattleActive ? advanceOculumBattleRound : null,
                compact: true,
              ),
            ],
          ),
          if (canClaimPack) ...[
            const SizedBox(height: 10),
            _buildOculumBattleFirstWinPacks(),
          ],
          if (oculumBattleLastRewardIt.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              cleanDungeonText(
                widget.linguaInglese
                    ? oculumBattleLastRewardEn
                    : oculumBattleLastRewardIt,
              ),
              style: const TextStyle(
                color: Color(0xFFE8E2FF),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (oculumBattleLog.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              oculumBattleLog.reversed.take(4).join('\n'),
              style: const TextStyle(
                color: Color(0xFFBFB7DD),
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOculumBattleDominantSelector() {
    final unlocked = _oculumBattleDominants
        .where(
          (dominant) => unlockedOculumBattleDominantIds.contains(dominant.id),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Dominatore', 'Dominant'),
          style: const TextStyle(
            color: Color(0xFFE7C66B),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        _buildOculumBattleTacticalSlots(),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final dominant in unlocked)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _oculumBattleDominantTile(dominant),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _oculumBattleDominantTile(_OculumBattleDominantDef dominant) {
    final selected = dominant.id == oculumBattleSelectedDominantId;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() => oculumBattleSelectedDominantId = dominant.id);
        unawaited(_savePermanentProgress());
      },
      child: Container(
        width: 218,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1B1722) : const Color(0xFF0B0A10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: dominant.color.withValues(alpha: selected ? 0.95 : 0.35),
          ),
        ),
        child: Row(
          children: [
            _OculumBattleSprite(
              kind: dominant.spriteKind,
              color: dominant.color,
              size: 48,
              faceRight: true,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dominant.nameIt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFF4F0FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    widget.linguaInglese
                        ? dominant.effectEn
                        : dominant.effectIt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFBFB7DD),
                      fontSize: 9.5,
                      height: 1.1,
                    ),
                  ),
                  if (_rulerTitleFor(dominant.id) != null) ...[
                    const SizedBox(height: 4),
                    _oculumBattleTitleChip(dominant),
                  ],
                  const SizedBox(height: 5),
                  _oculumBattleMasteryBar(dominant.id, dominant.color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _oculumBattleTitleChip(_OculumBattleDominantDef dominant) {
    final title = _rulerTitleFor(dominant.id);
    if (title == null) return const SizedBox.shrink();
    final revealed = revealedOculumBattleTitleIds.contains(dominant.id);
    final equipped = equippedOculumBattleTitleIds.contains(dominant.id);
    final label = revealed
        ? (widget.linguaInglese ? title.nameEn : title.nameIt)
        : (widget.linguaInglese ? title.secretEn : title.secretIt);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        setState(() {
          if (equipped) {
            equippedOculumBattleTitleIds.remove(dominant.id);
          } else {
            equippedOculumBattleTitleIds.add(dominant.id);
          }
        });
        unawaited(_savePermanentProgress());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF09090F),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: dominant.color.withValues(alpha: equipped ? 0.75 : 0.28),
          ),
        ),
        child: Row(
          children: [
            Icon(
              revealed ? Icons.workspace_premium : Icons.lock,
              color: dominant.color,
              size: 12,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE8E2FF),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              equipped ? Icons.check_circle : Icons.radio_button_unchecked,
              color: dominant.color,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOculumBattleArenaSelector(_OculumBattleArenaDef arena) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0A10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: arena.color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance, color: arena.color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: arena.id,
                isDense: true,
                dropdownColor: const Color(0xFF11101A),
                iconEnabledColor: arena.color,
                style: const TextStyle(
                  color: Color(0xFFF4F0FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                items: [
                  for (final item in _oculumBattleArenas)
                    DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(
                        widget.linguaInglese ? item.nameEn : item.nameIt,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => oculumBattleArenaId = value);
                  unawaited(_savePermanentProgress());
                },
              ),
            ),
          ),
          Text(
            '${_oculumBattleArenas.length}',
            style: TextStyle(
              color: arena.color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOculumBattleDeckSelector() {
    final arenaCards = _oculumBattleTroops
        .where((card) => card.arenaId == oculumBattleArenaId)
        .toList();
    final otherVisibleCards = _oculumBattleTroops
        .where(
          (card) =>
              card.arenaId != oculumBattleArenaId &&
              (_isOculumBattleCardUnlocked(card) ||
                  oculumBattleDraftTroopIds.contains(card.id)),
        )
        .toList();
    final visibleCards = <_OculumBattleTroopDef>[
      ...arenaCards,
      ...otherVisibleCards,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t('Fronte e pet', 'Front and pets'),
                style: const TextStyle(
                  color: Color(0xFFE7C66B),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${oculumBattleDraftTroopIds.length}/6',
              style: const TextStyle(
                color: Color(0xFFBFB7DD),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final card in visibleCards)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _oculumBattleCardTile(card),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOculumBattleTacticalSlots() {
    final graduated = _graduatedSlotCard;
    final heroic = _heroicSlotCard;
    final formationHp = _oculumBattleFormationHpBonus();
    final formationDamage = _oculumBattleFormationDamageBonus();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _oculumBattleSlotPill(
          icon: Icons.upgrade,
          color: const Color(0xFFBFA7FF),
          label: 'Graduata',
          value: graduated == null
              ? t('vuoto', 'empty')
              : (widget.linguaInglese ? graduated.nameEn : graduated.nameIt),
        ),
        _oculumBattleSlotPill(
          icon: Icons.auto_awesome,
          color: const Color(0xFFFFD36A),
          label: 'Evoluta',
          value: heroic == null
              ? t('vuoto', 'empty')
              : (widget.linguaInglese ? heroic.nameEn : heroic.nameIt),
        ),
        _oculumBattleSlotPill(
          icon: Icons.brightness_7,
          color: const Color(0xFFFFD36A),
          label: t('Principi', 'Principles'),
          value: '$oculumBattleEvolutionPrinciples',
        ),
        if (formationHp > 0 || formationDamage > 0)
          _oculumBattleSlotPill(
            icon: Icons.account_tree,
            color: const Color(0xFF85F0FF),
            label: t('Formazione', 'Formation'),
            value: '+$formationHp HP +$formationDamage DMG',
          ),
      ],
    );
  }

  Widget _oculumBattleSlotPill({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF09090F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '$label: $value',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFE8E2FF),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _oculumBattleCardTile(_OculumBattleTroopDef card) {
    final unlocked = _isOculumBattleCardUnlocked(card);
    final selected = oculumBattleDraftTroopIds.contains(card.id);
    final color = unlocked
        ? _oculumBattleSkinColor(card.id, card.color)
        : const Color(0xFF4D4A57);
    final slotUsable = unlocked && !card.isPet;
    final graduated = card.id == oculumBattleGraduatedSlotCardId;
    final heroic = card.id == oculumBattleHeroicSlotCardId;
    final heroicUnlocked = unlockedOculumBattleHeroicCardIds.contains(card.id);
    final rarityColor = _oculumBattleRarityColor(card.rarity);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: unlocked ? () => toggleOculumBattleCard(card) : null,
      child: Opacity(
        opacity: unlocked ? 1 : 0.48,
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1A161F) : const Color(0xFF09090F),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: selected ? 0.95 : 0.32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _OculumBattleSprite(
                    kind: card.spriteKind,
                    color: color,
                    size: 34,
                    faceRight: true,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.linguaInglese ? card.nameEn : card.nameIt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF4F0FF),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    'Gr ${oculumBattleCardLevel(card.id)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    selected ? Icons.check_box : Icons.check_box_outline_blank,
                    color: color,
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: rarityColor.withValues(alpha: 0.52),
                  ),
                ),
                child: Text(
                  _oculumBattleRarityLabel(card.rarity),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: rarityColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              _oculumBattleMasteryBar(card.id, color),
              const SizedBox(height: 5),
              Text(
                oculumBattleMasterySkinName(card.id),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: oculumBattleMasterySkinUnlocked(card.id)
                      ? color
                      : const Color(0xFF7A748A),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (slotUsable) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    _oculumBattleMiniSlotButton(
                      label: 'Grad',
                      color: const Color(0xFFBFA7FF),
                      active: graduated,
                      onTap: () => toggleOculumBattleGraduatedSlot(card),
                    ),
                    _oculumBattleMiniSlotButton(
                      label: heroicUnlocked ? 'Evoluta' : 'Principio',
                      color: const Color(0xFFFFD36A),
                      active: heroic,
                      onTap: () => toggleOculumBattleHeroicSlot(card),
                    ),
                  ],
                ),
                if (heroicUnlocked) ...[
                  const SizedBox(height: 4),
                  Text(
                    _heroicAbilityLabel(card),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFD36A),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _oculumBattleMiniSlotButton({
    required String label,
    required Color color,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.18) : Colors.black,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color.withValues(alpha: active ? 0.85 : 0.35),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildOculumBattleArtSelector() {
    final art = _selectedBattleArt;
    final skills = art.skillIds
        .map(_artSkillById)
        .whereType<_OculumBattleArtSkillDef>()
        .toList();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0A10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: art.color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high, color: art.color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: art.id,
                    isDense: true,
                    dropdownColor: const Color(0xFF11101A),
                    iconEnabledColor: art.color,
                    style: const TextStyle(
                      color: Color(0xFFF4F0FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    items: [
                      for (final item in _oculumBattleArts)
                        DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(
                            '${widget.linguaInglese ? item.nameEn : item.nameIt} - ${widget.linguaInglese ? item.rarityEn : item.rarityIt}',
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => oculumBattleSelectedArtId = value);
                      unawaited(_savePermanentProgress());
                    },
                  ),
                ),
              ),
              Text(
                art.id == 'defiled'
                    ? '${oculumBattleDefiledBar.clamp(0, 100)}%'
                    : '${t('Usi', 'Uses')} ${oculumBattleArtUsesLeft(art.id)}',
                style: TextStyle(
                  color: art.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.linguaInglese ? art.descEn : art.descIt,
            style: const TextStyle(
              color: Color(0xFFBFB7DD),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (art.id == 'defiled')
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (oculumBattleDefiledBar / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.black,
                valueColor: AlwaysStoppedAnimation<Color>(art.color),
              ),
            ),
          if (art.id == 'defiled') const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final skill in skills)
                modernActionButton(
                  label: widget.linguaInglese ? skill.nameEn : skill.nameIt,
                  icon: skill.icon,
                  color: skill.color,
                  onPressed: () => useOculumBattleArtSkill(skill.id),
                  compact: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  void useOculumBattleArtSkill(String skillId) {
    final skill = _artSkillById(skillId);
    if (skill == null) return;
    if (!oculumBattleActive || oculumBattleFinished) {
      setState(() {
        oculumBattleLastRewardIt = 'Apri una battaglia per usare le Art.';
        oculumBattleLastRewardEn = 'Open a battle to use Arts.';
      });
      return;
    }

    final art = _selectedBattleArt;
    setState(() {
      if (art.id == 'defiled') {
        if (skill.id == 'defiled_devour') {
          final victim = _weakestOculumBattleUnit(
            oculumBattleAllies.where((unit) => !unit.pet).toList(),
          );
          if (victim == null) {
            oculumBattleLastRewardIt = 'Defiled non trova pedine da mangiare.';
            oculumBattleLastRewardEn = 'Defiled finds no pawns to eat.';
            return;
          }
          victim.hp = 0;
          oculumBattleDefiledBar = min(100, oculumBattleDefiledBar + 35);
          _learnOculumBattleSkill(skill.id);
          oculumBattleLog.add('Defiled mangia ${victim.nameIt}.');
          _removeDeadOculumBattleUnits();
          return;
        }
        if (oculumBattleDefiledBar < skill.defiledCost) {
          oculumBattleLastRewardIt = 'La barra Defiled non basta.';
          oculumBattleLastRewardEn = 'The Defiled bar is not full enough.';
          return;
        }
        oculumBattleDefiledBar -= skill.defiledCost;
      } else {
        final uses = oculumBattleArtUsesLeft(art.id);
        if (uses <= 0) {
          oculumBattleLastRewardIt = 'Art senza utilizzi.';
          oculumBattleLastRewardEn = 'Art has no uses left.';
          return;
        }
        oculumBattleArtUses[art.id] = uses - 1;
      }

      _learnOculumBattleSkill(skill.id);
      _resolveOculumBattleArtSkill(skill);
      _removeDeadOculumBattleUnits();
      _applyOculumBattleRulerTitleTriggers();
      _finishOculumBattleIfNeeded();
    });
    unawaited(_savePermanentProgress());
  }

  void _resolveOculumBattleArtSkill(_OculumBattleArtSkillDef skill) {
    final grade = oculumBattleCardLevel(oculumBattleSelectedDominantId);
    final arenaPack = _arenaPackForSkill(skill.id);
    if (arenaPack != null) {
      if (skill.id.endsWith('_arena_skill_1')) {
        for (final target
            in oculumBattleEnemies
                .where((unit) => unit.alive)
                .take(4)
                .toList()) {
          _applyOculumBattleDamage(target, 13 + grade * 2);
        }
        if (arenaPack.exploder) {
          _summonOculumBattleCard(
            '${arenaPack.prefix}_exploder',
            ally: true,
            count: 1,
            lane: 1,
            hpScale: 75,
            damageScale: 80,
          );
        }
      } else {
        for (final unit
            in oculumBattleAllies
                .where(
                  (unit) =>
                      unit.alive && unit.cardId.startsWith(arenaPack.prefix),
                )
                .take(4)) {
          unit.hp = min(unit.maxHp, unit.hp + 14);
          unit.damage += 1;
        }
        for (final target
            in oculumBattleEnemies.where((unit) => unit.alive).take(2)) {
          target.stunnedTurns = max(target.stunnedTurns, 1).toInt();
        }
      }
      oculumBattleLog.add('Art arena: ${skill.nameIt}.');
      return;
    }
    switch (skill.id) {
      case 'fireball':
        final target = _strongestOculumBattleUnit(oculumBattleEnemies);
        if (target != null) {
          _applyOculumBattleDamage(target, 24 + grade * 4);
        } else {
          oculumBattleEnemyDominantHp = max(
            0,
            oculumBattleEnemyDominantHp - 18,
          );
        }
        break;
      case 'regenerating_fire':
        for (final unit in oculumBattleAllies.where((unit) => unit.alive)) {
          unit.hp = min(unit.maxHp, unit.hp + 18 + grade * 2);
        }
        break;
      case 'fire_hound_darts':
        for (var i = 0; i < 3; i++) {
          final target = _weakestOculumBattleUnit(oculumBattleEnemies);
          if (target == null) break;
          _applyOculumBattleDamage(target, 10 + grade * 2);
        }
        break;
      case 'green_lightning':
        var converted = 0;
        for (final target
            in oculumBattleEnemies
                .where((unit) => unit.alive)
                .take(5)
                .toList()) {
          final died = _applyGoblinConvertingDamage(target, 7 + grade);
          if (died) converted += 1;
        }
        if (converted > 0) {
          _summonOculumBattleCard(
            'weak_goblin',
            ally: true,
            count: converted,
            lane: 1,
            hpScale: 70,
            damageScale: 70,
          );
        }
        break;
      case 'goblin_rocket':
        final target = _strongestOculumBattleUnit(oculumBattleEnemies);
        if (target != null) _applyOculumBattleDamage(target, 34 + grade * 3);
        _summonOculumBattleCard(
          'weak_goblin',
          ally: true,
          count: 2,
          lane: 1,
          hpScale: 75,
          damageScale: 70,
        );
        break;
      case 'stink_vial':
        for (final target
            in oculumBattleEnemies.where((unit) => unit.alive).take(4)) {
          target.stunnedTurns = max(target.stunnedTurns, 2).toInt();
        }
        break;
      case 'iron_stance':
        for (final unit in oculumBattleAllies.where((unit) => unit.alive)) {
          unit.armor += 1;
          unit.damage += 2;
          unit.hp = min(unit.maxHp, unit.hp + 5);
        }
        break;
      case 'blood_step':
        final attacker = _fastestOculumBattleUnit(oculumBattleAllies);
        final target = _weakestOculumBattleUnit(oculumBattleEnemies);
        if (attacker != null && target != null) {
          _applyOculumBattleDamage(target, attacker.damage + 10);
        }
        break;
      case 'execution_order':
        final target = _weakestOculumBattleUnit(oculumBattleEnemies);
        if (target != null) {
          for (final unit in oculumBattleAllies.where((unit) => unit.alive)) {
            _applyOculumBattleDamage(target, max(1, unit.damage ~/ 2));
            if (!target.alive) break;
          }
        }
        break;
      case 'madness_seed':
        final target = _strongestOculumBattleUnit(oculumBattleEnemies);
        if (target != null) _applyOculumBattleDamage(target, 22 + grade * 3);
        break;
      case 'fever_bell':
        for (final target
            in oculumBattleEnemies.where((unit) => unit.alive).toList()) {
          _applyOculumBattleDamage(target, 9 + grade);
        }
        break;
      case 'broken_laughter':
        oculumBattleEnemyDominantHp = max(
          0,
          oculumBattleEnemyDominantHp - 24 - grade * 2,
        );
        for (final unit in oculumBattleEnemies.where((unit) => unit.alive)) {
          unit.damage = max(1, unit.damage - 1);
        }
        break;
      case 'emblem_sun':
        for (final target
            in oculumBattleEnemies.where((unit) => unit.alive).toList()) {
          _applyOculumBattleDamage(target, 16 + grade * 2);
        }
        oculumBattleEnemyDominantHp = max(0, oculumBattleEnemyDominantHp - 22);
        break;
      case 'emblem_chain':
        final target = _strongestOculumBattleUnit(oculumBattleEnemies);
        if (target != null) _applyOculumBattleDamage(target, 34 + grade * 2);
        oculumBattleEnemyDominantHp = max(0, oculumBattleEnemyDominantHp - 12);
        break;
      case 'emblem_guard':
        for (final unit in oculumBattleAllies.where((unit) => unit.alive)) {
          unit.armor += 2;
          unit.hp = min(unit.maxHp, unit.hp + 16);
        }
        break;
      case 'defiled_maw':
        final target = _strongestOculumBattleUnit(oculumBattleEnemies);
        if (target != null) _applyOculumBattleDamage(target, 52 + grade * 3);
        break;
      case 'defiled_scream':
        for (final target
            in oculumBattleEnemies.where((unit) => unit.alive).toList()) {
          _applyOculumBattleDamage(target, 22 + grade);
        }
        oculumBattleEnemyDominantHp = max(0, oculumBattleEnemyDominantHp - 18);
        break;
      case 'defiled_crown':
        oculumBattleEnemyDominantHp = max(0, oculumBattleEnemyDominantHp - 68);
        break;
    }
    oculumBattleLog.add('Art: ${skill.nameIt}.');
  }

  _OculumBattleUnit? _strongestOculumBattleUnit(List<_OculumBattleUnit> units) {
    final alive = units.where((unit) => unit.alive).toList();
    if (alive.isEmpty) return null;
    alive.sort((a, b) => b.maxHp.compareTo(a.maxHp));
    return alive.first;
  }

  _OculumBattleUnit? _fastestOculumBattleUnit(List<_OculumBattleUnit> units) {
    final alive = units.where((unit) => unit.alive).toList();
    if (alive.isEmpty) return null;
    alive.sort((a, b) => b.speed.compareTo(a.speed));
    return alive.first;
  }

  Widget _oculumBattleMasteryBar(String id, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: oculumBattleMasteryFraction(id),
        minHeight: 5,
        backgroundColor: Colors.black,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _buildOculumBattleArena(
    _OculumBattleDominantDef dominant,
    _OculumBattleDominantDef enemy,
    _OculumBattleArenaDef arena,
  ) {
    final dominantMax = _oculumBattleDominantMaxHp(dominant, ally: true);
    final enemyMax = _oculumBattleDominantMaxHp(enemy, ally: false);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [arena.color.withValues(alpha: 0.35), arena.shadowColor],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: arena.color.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _oculumBattleDominantBar(
                  dominant.nameIt,
                  oculumBattleDominantHp <= 0
                      ? dominantMax
                      : oculumBattleDominantHp,
                  dominantMax,
                  dominant.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _oculumBattleDominantBar(
                  enemy.nameIt,
                  oculumBattleEnemyDominantHp <= 0
                      ? enemyMax
                      : oculumBattleEnemyDominantHp,
                  enemyMax,
                  enemy.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 188,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _OculumBattleArenaPainterWidget(arena: arena),
                ),
                Positioned(
                  left: 8,
                  top: 52,
                  child: _OculumBattleSprite(
                    kind: dominant.spriteKind,
                    color: dominant.color,
                    size: 56,
                    faceRight: true,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 52,
                  child: _OculumBattleSprite(
                    kind: enemy.spriteKind,
                    color: enemy.color,
                    size: 56,
                    faceRight: false,
                  ),
                ),
                ..._positionedOculumBattleUnits(
                  units: oculumBattleActive || oculumBattleFinished
                      ? oculumBattleAllies
                      : [
                          for (
                            var i = 0;
                            i < _previewBattleCardsWithTacticalSlots.length;
                            i++
                          )
                            ..._expandOculumBattleCardToUnits(
                              _previewBattleCardsWithTacticalSlots[i],
                              ally: true,
                              lane: i % 3,
                              index: i * 3,
                            ),
                        ],
                  ally: true,
                ),
                ..._positionedOculumBattleUnits(
                  units: oculumBattleEnemies,
                  ally: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.linguaInglese ? arena.descEn : arena.descIt,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFBFB7DD),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _oculumBattleDominantBar(
    String label,
    int current,
    int maxValue,
    Color color,
  ) {
    final pct = (current / max(1, maxValue)).clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cleanDungeonText(label),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.black,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  List<Widget> _positionedOculumBattleUnits({
    required List<_OculumBattleUnit> units,
    required bool ally,
  }) {
    final aliveUnits = units.where((unit) => unit.alive).take(10).toList();
    final widgets = <Widget>[];
    for (var i = 0; i < aliveUnits.length; i++) {
      final unit = aliveUnits[i];
      final laneY = 18.0 + unit.lane * 48.0 + (i % 2) * 8.0;
      final x = ally ? 84.0 + (i % 5) * 34.0 : 332.0 - (i % 5) * 34.0;
      widgets.add(
        Positioned(
          left: ally ? x : null,
          right: ally ? null : max(72.0, 420.0 - x),
          top: laneY,
          child: _oculumBattleUnitSprite(unit),
        ),
      );
    }
    return widgets;
  }

  Widget _oculumBattleUnitSprite(_OculumBattleUnit unit) {
    return SizedBox(
      width: 44,
      child: Column(
        children: [
          _OculumBattleSprite(
            kind: unit.spriteKind,
            color: unit.color,
            size: unit.pet ? 30 : 38,
            faceRight: unit.ally,
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (unit.hp / max(1, unit.maxHp)).clamp(0.0, 1.0).toDouble(),
              minHeight: 4,
              backgroundColor: Colors.black,
              valueColor: AlwaysStoppedAnimation<Color>(unit.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOculumBattleFirstWinPacks() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0A10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE7C66B).withValues(alpha: 0.5),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          modernActionButton(
            label: t('Patto Luna', 'Moon Pact'),
            icon: Icons.dark_mode,
            color: const Color(0xFF9B7CFF),
            onPressed: () => openOculumBattleDominantPack('moon'),
            compact: true,
          ),
          modernActionButton(
            label: t('Radici Eiva', 'Eiva Roots'),
            icon: Icons.grass,
            color: const Color(0xFF5EE08A),
            onPressed: () => openOculumBattleDominantPack('root'),
            compact: true,
          ),
          modernActionButton(
            label: t('Storia Nera', 'Black Story'),
            icon: Icons.auto_stories,
            color: const Color(0xFFE7C66B),
            onPressed: () => openOculumBattleDominantPack('story'),
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _OculumBattleArenaPainterWidget extends StatelessWidget {
  const _OculumBattleArenaPainterWidget({required this.arena});

  final _OculumBattleArenaDef arena;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _OculumBattleArenaPainter(arena));
  }
}

class _OculumBattleArenaPainter extends CustomPainter {
  const _OculumBattleArenaPainter(this.arena);

  final _OculumBattleArenaDef arena;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    paint.color = arena.shadowColor.withValues(alpha: 0.85);
    canvas.drawRect(Offset.zero & size, paint);
    final pixel = max(6.0, size.width / 44);
    paint.color = arena.color.withValues(alpha: 0.28);
    for (var i = 0; i < 11; i++) {
      final x = (i * 37) % max(1, size.width.toInt());
      final y = size.height - 22 - (i % 3) * 13;
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), y.toDouble(), pixel * 2, pixel * 5),
        paint,
      );
    }
    paint.color = const Color(0xFF050407).withValues(alpha: 0.7);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 42, size.width, 42), paint);
    paint.color = arena.color.withValues(alpha: 0.18);
    for (var i = 0; i < 26; i++) {
      final x = (i * 19) % max(1, size.width.toInt());
      final y = size.height - 40 + (i % 4) * 8;
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), y.toDouble(), pixel, 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OculumBattleArenaPainter oldDelegate) {
    return oldDelegate.arena.id != arena.id;
  }
}

class _OculumBattleSprite extends StatefulWidget {
  const _OculumBattleSprite({
    required this.kind,
    required this.color,
    required this.size,
    required this.faceRight,
  });

  final String kind;
  final Color color;
  final double size;
  final bool faceRight;

  @override
  State<_OculumBattleSprite> createState() => _OculumBattleSpriteState();
}

class _OculumBattleSpriteState extends State<_OculumBattleSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -2 * sin(_controller.value * pi)),
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _OculumBattleSpritePainter(
              kind: widget.kind,
              color: widget.color,
              faceRight: widget.faceRight,
              phase: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class _OculumBattleSpritePainter extends CustomPainter {
  const _OculumBattleSpritePainter({
    required this.kind,
    required this.color,
    required this.faceRight,
    required this.phase,
  });

  final String kind;
  final Color color;
  final bool faceRight;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = false;
    final px = size.width / 16;
    canvas.save();
    if (!faceRight) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    void rect(int x, int y, int w, int h, Color c) {
      p.color = c;
      canvas.drawRect(Rect.fromLTWH(x * px, y * px, w * px, h * px), p);
    }

    final dark = Color.lerp(color, Colors.black, 0.48)!;
    final light = Color.lerp(color, Colors.white, 0.32)!;
    final eye = kind.contains('null')
        ? const Color(0xFFF4F0FF)
        : kind.contains('shadow')
        ? const Color(0xFFBFA7FF)
        : const Color(0xFFFF5A8D);
    final bob = phase > 0.5 ? 1 : 0;

    rect(4, 13, 8, 2, Colors.black.withValues(alpha: 0.6));

    if (kind.contains('dominant')) {
      rect(5, 3 + bob, 6, 8, dark);
      rect(4, 5 + bob, 8, 5, color);
      rect(6, 1 + bob, 4, 3, light);
      rect(5, 0 + bob, 2, 2, const Color(0xFFE7C66B));
      rect(9, 0 + bob, 2, 2, const Color(0xFFE7C66B));
      rect(7, 5 + bob, 2, 1, eye);
      rect(6, 11 + bob, 2, 3, dark);
      rect(9, 11 + bob, 2, 3, dark);
      rect(3, 7 + bob, 2, 4, dark);
      rect(11, 7 + bob, 2, 4, dark);
      if (kind.contains('noctis')) {
        rect(2, 4 + bob, 2, 7, const Color(0xFF4D3F72));
        rect(12, 4 + bob, 2, 7, const Color(0xFF4D3F72));
      }
      canvas.restore();
      return;
    }

    if (kind.contains('spawner')) {
      rect(4, 7 + bob, 8, 6, dark);
      rect(5, 5 + bob, 6, 5, color);
      rect(6, 6 + bob, 1, 1, eye);
      rect(9, 6 + bob, 1, 1, eye);
      rect(3, 11 + bob, 10, 2, light.withValues(alpha: 0.7));
      canvas.restore();
      return;
    }

    if (kind.contains('carapace') || kind.contains('golem')) {
      rect(3, 6 + bob, 10, 6, dark);
      rect(4, 4 + bob, 8, 6, color);
      rect(6, 3 + bob, 4, 3, light);
      rect(6, 6 + bob, 1, 1, eye);
      rect(9, 6 + bob, 1, 1, eye);
      rect(2, 9 + bob, 2, 3, dark);
      rect(12, 9 + bob, 2, 3, dark);
      canvas.restore();
      return;
    }

    if (kind.contains('troll')) {
      rect(4, 5 + bob, 8, 7, color);
      rect(5, 2 + bob, 6, 5, dark);
      rect(6, 4 + bob, 1, 1, eye);
      rect(9, 4 + bob, 1, 1, eye);
      rect(2, 7 + bob, 3, 5, dark);
      rect(11, 7 + bob, 3, 5, dark);
      rect(6, 12 + bob, 2, 2, dark);
      rect(9, 12 + bob, 2, 2, dark);
      canvas.restore();
      return;
    }

    if (kind.contains('pet')) {
      rect(6, 7 + bob, 4, 4, color);
      rect(5, 6 + bob, 2, 2, light);
      rect(9, 6 + bob, 2, 2, light);
      rect(7, 8 + bob, 1, 1, eye);
      rect(3, 8 + bob, 3, 2, color.withValues(alpha: 0.65));
      rect(10, 8 + bob, 3, 2, color.withValues(alpha: 0.65));
      canvas.restore();
      return;
    }

    if (kind.contains('hound') || kind.contains('swarm')) {
      rect(4, 8 + bob, 8, 4, color);
      rect(10, 6 + bob, 3, 3, dark);
      rect(11, 7 + bob, 1, 1, eye);
      rect(4, 12 + bob, 2, 2, dark);
      rect(9, 12 + bob, 2, 2, dark);
      canvas.restore();
      return;
    }

    if (kind.contains('slime')) {
      rect(4, 8 + bob, 8, 4, color);
      rect(5, 6 + bob, 6, 4, light.withValues(alpha: 0.8));
      rect(6, 8 + bob, 1, 1, eye);
      rect(9, 8 + bob, 1, 1, eye);
      canvas.restore();
      return;
    }

    rect(5, 5 + bob, 6, 7, color);
    rect(6, 3 + bob, 4, 4, dark);
    rect(7, 5 + bob, 1, 1, eye);
    rect(9, 5 + bob, 1, 1, eye);
    rect(3, 8 + bob, 3, 2, dark);
    rect(10, 8 + bob, 3, 2, dark);
    rect(6, 12 + bob, 2, 2, dark);
    rect(9, 12 + bob, 2, 2, dark);
    if (kind.contains('archer')) rect(12, 5 + bob, 1, 7, light);
    if (kind.contains('cultist'))
      rect(4, 2 + bob, 8, 2, const Color(0xFF4D3F72));
    if (kind.contains('shadow'))
      rect(4, 4 + bob, 8, 9, const Color(0x883A3058));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OculumBattleSpritePainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.color != color ||
        oldDelegate.faceRight != faceRight ||
        oldDelegate.phase != phase;
  }
}
