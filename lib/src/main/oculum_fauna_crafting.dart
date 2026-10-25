part of '../../main.dart';

bool oculumCraftWearable(InventoryItem item) =>
    item.arma ||
    item.protegge ||
    item.craftData['clothing'] == true ||
    item.craftData['wearable'] == true;
int oculumCraftLuckChance(int luck, {bool rebirthed = false}) =>
    (10 + max(0, luck)).clamp(0, rebirthed ? 100 : 90).toInt();
int oculumScrollLuck(int luck, {bool rebirthed = false}) =>
    rebirthed ? (max(0, luck) * 1.5).ceil() : max(0, luck);
bool oculumCompleteEquipmentCraft(
  InventoryItem item, {
  required String receipt,
  required int roll,
  required int luck,
  bool rebirthed = false,
  bool forged = false,
}) {
  if (!oculumCraftWearable(item)) return false;
  final receipts = Map<String, dynamic>.from(
    item.craftData['craftLuckReceipts'] as Map? ?? {},
  );
  if (receipts.containsKey(receipt)) return false;
  if (forged) item.livelloOggetto = max(0, item.livelloOggetto) + 1;
  final chance = oculumCraftLuckChance(luck, rebirthed: rebirthed);
  final success = roll >= 0 && roll < chance;
  final offense = item.arma || item.bonusDanno > 0;
  final defense = item.protegge || item.bonusDifesa > 0 || !offense;
  if (success) {
    if (offense) item.bonusDanno += item.livelloOggetto;
    if (defense) item.bonusDifesa += item.livelloOggetto;
  }
  receipts[receipt] = {
    'roll': roll,
    'chance': chance,
    'success': success,
    'level': item.livelloOggetto,
    'damage': success && offense ? item.livelloOggetto : 0,
    'defense': success && defense ? item.livelloOggetto : 0,
  };
  item.craftData = {...item.craftData, 'craftLuckReceipts': receipts};
  return success;
}

const _faunaCraftSpecs = [
  (
    'zombie_acido',
    'Guanti della sacca corrosa',
    'weapon',
    'zombie_acid_vomit',
    500,
  ),
  (
    'cavaliere_non_ritorno',
    'Spadone del varco spento',
    'weapon',
    'non_return_greatsword',
    1300,
  ),
  ('bramble', 'Scudo del roveto', 'shield', 'bramble_thorn_shield', 600),
  (
    'thunderbird',
    'Artiglio della rupe tonante',
    'weapon',
    'thunderbird_claw',
    350,
  ),
  (
    'scostubanditi',
    'Fucile d’ottone rattoppato',
    'weapon',
    'scostu_shot',
    1000,
  ),
  ('granscostumato', 'Bracciale del cannone', 'armor', 'gran_unstun', 800),
  (
    'fuocherelli',
    'Mantello di brace protetta',
    'armor',
    'fuocherelli_dart',
    500,
  ),
  ('feralis', 'Guanti della criniera', 'weapon', 'feralis_claw', 650),
  (
    'feralis_ancestrale',
    'Corazza delle spirali ancestrali',
    'armor',
    'feralis_ancestral_guard',
    1200,
  ),
  (
    'sempre_verde',
    'Mantello delle foglie cerate',
    'armor',
    'evergreen_dodge',
    600,
  ),
  (
    'lavastrello',
    'Stivali della tana lavica',
    'armor',
    'lavastrello_fire_attack',
    450,
  ),
  (
    'teschio_quattro_lame',
    'Lama delle quattro ossa',
    'weapon',
    'bone_sword_strike',
    800,
  ),
  ('teschio_monaco', 'Fasce del monaco', 'armor', 'monk_palm', 450),
  ('ogor', 'Scudo della valva viola', 'shield', 'ogor_slam', 1400),
  ('teirak', 'Disco runico di guardia', 'shield', 'teirak_rune_guard', 900),
  ('laer', 'Lama della torsione', 'weapon', 'laer_sword', 850),
  ('torretta_oculum', 'Bracciale del nucleo', 'weapon', 'turret_ray', 650),
  (
    'manichino_spada',
    'Corazza del manichino',
    'armor',
    'sword_puppet_guard',
    1100,
  ),
  ('deadly_sins', 'Guanto della catena', 'weapon', 'deadly_strike', 900),
];

List<OculumRecipe> oculumFaunaCraftingRecipes(String now) => [
  for (final spec in _faunaCraftSpecs)
    OculumRecipe(
      id: 'fauna_${spec.$1}',
      name: spec.$2,
      resultName: spec.$2,
      ingredients: [
        OculumRecipeIngredient(
          name: oculumMonsterDropName(
            monsterBookEntryById(spec.$1)!.dropIds.first,
          ),
          grams: '${spec.$5}',
        ),
        OculumRecipeIngredient(
          name: spec.$3 == 'armor' ? 'Cuoio conciato' : 'Lingotto di ferro',
          grams: '${spec.$3 == 'armor' ? 250 : 500}',
        ),
      ],
      resultDescription:
          '${spec.$3 == 'weapon'
              ? 'Arma'
              : spec.$3 == 'shield'
              ? 'Scudo'
              : 'Abito o armatura'} artigianale di ${monsterBookEntryById(spec.$1)!.nameIt}. Le parti recuperate sono montate con legature e supporti adatti al loro ambiente. Incorpora ${oculumPlanarTechnique(spec.$4)!.name}, con livelli, costo e cooldown originali. Il livello richiesto dalla tecnica resta quello della creatura.',
      masterNotes:
          'Ricetta e grammature modificabili. Bonus artigiano estratto una sola volta per oggetto.',
      visibleToPlayers: true,
      createdAt: now,
      updatedAt: now,
      recipeKind: 'forge',
      forgeTarget: spec.$3 == 'weapon' ? 'weapon' : 'armor',
      resultGrams: '${spec.$5 + 500}',
    ),
  for (final spec in _silkCraftSpecs)
    OculumRecipe(
      id: 'silk_${spec.$1}',
      name: spec.$2,
      resultName: spec.$2,
      ingredients: [
        OculumRecipeIngredient(name: 'Seta magica', grams: '500'),
        OculumRecipeIngredient(name: spec.$3, grams: '150'),
      ],
      resultDescription: spec.$4,
      masterNotes: 'Resistenza del tessuto modificabile nei dati dell’oggetto.',
      visibleToPlayers: true,
      createdAt: now,
      updatedAt: now,
      recipeKind: 'crafting',
      forgeTarget: 'armor',
      resultGrams: '650',
    ),
];
const _silkCraftSpecs = [
  (
    'urti',
    'Veste di seta a trama ferma',
    'Pelle di mostro',
    'Una veste unisex blu fumo, con falde sovrapposte e cuciture color rame. La seta si irrigidisce per un istante quando riceve un urto. −20% Danni Contundenti e −10% Fisici mentre equipaggiata.',
  ),
  (
    'rovi',
    'Corpetto di seta del roveto',
    'Fibra Rovo Bramble',
    'Corpetto verde petrolio con stecche flessibili e lacci asimmetrici, abbinabile a gonna o pantaloni. Fili vegetali rinforzano le giunture: −15% Danni da Taglio e Contundenti mentre equipaggiato.',
  ),
  (
    'tempesta',
    'Soprabito di seta della tempesta',
    'Piuma Conduttrice Thunderbird',
    'Soprabito indaco dalla fodera grigio perla, con collo alto e maniche larghe fermate ai polsi. La trama dissipa scariche e urti: −20% Fulmine e −10% Contundente mentre equipaggiato.',
  ),
];

InventoryItem? oculumFaunaCraftedItem(OculumRecipe recipe) {
  if (recipe.id.startsWith('silk_')) {
    final id = recipe.id.substring(5);
    final item = oculumMagicSilkItem(id);
    if (item != null) {
      item.nome = recipe.resultName;
      item.note = recipe.resultDescription;
    }
    return item;
  }
  final spec = _faunaCraftSpecs
      .where((s) => recipe.id == 'fauna_${s.$1}')
      .firstOrNull;
  if (spec == null) return null;
  final monster = monsterBookEntryById(spec.$1)!;
  final skill = oculumMonsterBookArt(
    monster.copyWith(skillIds: [spec.$4]),
  ).skills.first;
  final item = InventoryItem(
    peso: (double.tryParse(recipe.resultGrams) ?? 1000) / 1000,
    quantita: 1,
    note: recipe.resultDescription,
    nome: spec.$2,
    livelloOggetto: monster.stats['level'] ?? 0,
    gradoOggetto: oculumGradeForLevel(monster.stats['level'] ?? 0),
    ability: oculumEquipmentAbilityFromArt(skill),
    monsterLoot: {'sourceSkillId': spec.$4, 'monsterId': monster.id},
  );
  item
    ..nome = spec.$2
    ..peso = (double.tryParse(recipe.resultGrams) ?? 1000) / 1000
    ..arma = spec.$3 == 'weapon'
    ..protegge = spec.$3 != 'weapon'
    ..bonusDanno = spec.$3 == 'weapon' ? 3 : 0
    ..bonusDifesa = spec.$3 == 'weapon' ? 0 : 3
    ..note = recipe.resultDescription;
  return item;
}

InventoryItem? oculumMagicSilkItem(String id) {
  final spec = _silkCraftSpecs.where((s) => s.$1 == id).firstOrNull;
  if (spec == null) return null;
  return InventoryItem(
    nome: spec.$2,
    peso: .65,
    quantita: 1,
    note: spec.$4,
    protegge: true,
    livelloOggetto: 1,
    bonusDifesa: 1,
    craftData: {
      'clothing': true,
      'wearable': true,
      'silkResistances': id == 'urti'
          ? {'contundente': 20, 'fisico': 10}
          : id == 'rovi'
          ? {'taglio': 15, 'contundente': 15}
          : {'fulmine': 20, 'contundente': 10},
    },
  );
}

extension _OculumFaunaCrafting on _OculumHomePageState {
  void ensureMagicSilkOffers() {
    for (var i = 0; i < _silkCraftSpecs.length; i++) {
      final spec = _silkCraftSpecs[i];
      final id = 'seta_magica_${spec.$1}';
      if (merchantStock.any((offer) => offer['id'] == id)) continue;
      merchantStock.add({
        'id': id,
        'kind': 'clothing',
        'silkId': spec.$1,
        'name': spec.$2,
        'desc': spec.$4,
        'level': 1,
        'grade': 0,
        'cost': 36 + i * 6,
        'stock': 1,
      });
    }
  }

  int get rawCraftLuck {
    final stat = hiddenEyeStats.where((s) => s.id == 'fortuna').firstOrNull;
    return stat == null ? 0 : hiddenEyeTotal(stat);
  }

  double silkResistanceMultiplier(String element) {
    var resistance = 0;
    for (final item in inventario.where(
      (i) => i.equipaggiata && canEquipInventoryItem(i),
    )) {
      final values = item.craftData['silkResistances'] as Map? ?? {};
      resistance = max(
        resistance,
        readIntValue(values[oculumNormalizeElementId(element)]),
      );
    }
    return 1 - resistance.clamp(0, 90) / 100;
  }
}
