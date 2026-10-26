part of '../../main.dart';

int oculumNurseHpRecoveryCost(int missingHp) => (max(0, missingHp) + 9) ~/ 10;

int oculumNurseOculumShieldRecoveryCost(int missingShield) =>
    max(0, missingShield) * 2;

const List<int> oculumNurseStandardBuffPercents = <int>[10, 15, 20, 25, 30];

int oculumNurseBuffPercentFromRoll({
  required int percentileRoll,
  required int selectionRoll,
  int jackpotChancePercent = 1,
  List<int> jackpotValues = const <int>[40, 60],
  List<int> standardValues = oculumNurseStandardBuffPercents,
}) {
  if (percentileRoll.clamp(0, 99) < jackpotChancePercent.clamp(0, 100)) {
    final rare = jackpotValues.where((value) => value > 30).toList();
    if (rare.isNotEmpty) return rare[selectionRoll.abs() % rare.length];
    return selectionRoll.isEven ? 40 : 60;
  }
  final standard = standardValues
      .where((value) => value > 0 && value <= 30)
      .toList();
  if (standard.isEmpty) return oculumNurseStandardBuffPercents.first;
  return standard[selectionRoll.abs() % standard.length];
}

int oculumNurseBuffSurcharge(int percent) => max(0, percent) ~/ 5;

int oculumNurseBuffDuration(String difficulty) =>
    switch (oculumNormalizeText(difficulty)) {
      'facile' || 'easy' => 9,
      'difficile' || 'hard' => 3,
      'oculum' => 1,
      _ => 6,
    };

int oculumNurseRareTempHpGift({
  required int percentileRoll,
  required int level,
  int chancePercent = 1,
  int hpPerLevel = 5,
}) => percentileRoll.clamp(0, 99) < chancePercent.clamp(0, 100)
    ? max(0, level) * max(0, hpPerLevel)
    : 0;

int oculumNurseFullRestorationCost({
  required int missingHp,
  required int missingOculumShield,
  int missingStatPoints = 0,
  int missingArtIntegrity = 0,
  int negativeConditions = 0,
  int buffPercent = 10,
  int artIntegrityPerObser = 10,
  int cleanseCostPerCondition = 5,
}) {
  final subtotal =
      oculumNurseHpRecoveryCost(missingHp) +
      oculumNurseOculumShieldRecoveryCost(missingOculumShield) +
      max(0, missingStatPoints) +
      (max(0, missingArtIntegrity) + max(1, artIntegrityPerObser) - 1) ~/
          max(1, artIntegrityPerObser) +
      max(0, negativeConditions) * max(0, cleanseCostPerCondition);
  return max(1, (subtotal * .85).floor()) +
      oculumNurseBuffSurcharge(buffPercent);
}

int oculumNurseRareBuffBonusShield(int maximumHp) => max(0, maximumHp) ~/ 4;

int oculumNurseTempHpGiftFromRoll({
  required int percentileRoll,
  required int level,
  required int maximumTemporaryHp,
  int levelGiftChancePercent = 1,
  int halfCeilingChancePercent = 2,
  int halfFloorChancePercent = 5,
  int hpPerLevel = 5,
}) {
  final roll = percentileRoll.clamp(0, 99).toInt();
  final levelChance = levelGiftChancePercent.clamp(0, 100).toInt();
  final ceilingChance = halfCeilingChancePercent.clamp(0, 100).toInt();
  final floorChance = halfFloorChancePercent.clamp(0, 100).toInt();
  if (roll < levelChance) return max(0, level) * max(0, hpPerLevel);
  if (roll < levelChance + ceilingChance) {
    return (max(0, maximumTemporaryHp) + 1) ~/ 2;
  }
  if (roll < levelChance + ceilingChance + floorChance) {
    return max(0, maximumTemporaryHp) ~/ 2;
  }
  return 0;
}

int oculumBlackMarketDustPrice({
  required int basePrice,
  required int previousPurchases,
}) => (max(30, min(50, basePrice)) + max(0, previousPurchases) * 10)
    .clamp(30, 69)
    .toInt();

int oculumBlackMarketFallenEyeBasePrice({
  required int level,
  required int levelZeroBase,
}) {
  final initial = levelZeroBase.clamp(36, 69);
  return initial + ((115 - initial) * max(0, level)) ~/ 10;
}

int oculumBlackMarketFallenEyePrice({
  required int totalStats,
  required int level,
  int ownerTotalStats = 0,
  int levelZeroBase = 50,
  int? basePrice,
  int statUnitCost = 2,
  int surplusBlockSize = 20,
  int surplusPercentPerBlock = 25,
}) {
  final base = max(
    0,
    basePrice ??
        oculumBlackMarketFallenEyeBasePrice(
          level: level,
          levelZeroBase: levelZeroBase,
        ),
  );
  final subtotal = base + max(0, totalStats) * max(0, statUnitCost);
  final blocks =
      max(0, totalStats - max(0, ownerTotalStats)) ~/ max(1, surplusBlockSize);
  return (subtotal * (100 + blocks * max(0, surplusPercentPerBlock))) ~/ 100;
}

bool oculumBlackMarketMonsterBookPageEligible(MonsterBookEntry entry) {
  if (entry.isNpc) return false;
  final identity = '${entry.id} ${entry.nameIt} ${entry.nameEn}'.toLowerCase();
  return entry.formTags.any(
        (tag) => oculumNormalizeText(tag) == 'aberrazione',
      ) ||
      RegExp(r'errante|wandering').hasMatch(identity);
}

int oculumBlackMarketMonsterBookPageBasePrice(MonsterBookEntry entry) =>
    entry.formTags.any((tag) => oculumNormalizeText(tag) == 'aberrazione')
    ? 90
    : 56;

List<MonsterBookEntry> oculumRankBlackMarketMonsterBookPages({
  required Iterable<MonsterBookEntry> entries,
  required int playerLevel,
  required Map<String, int> playerStats,
  Set<String> alreadyKnownWeakPoints = const <String>{},
  int limit = 3,
}) {
  if (limit <= 0) return const <MonsterBookEntry>[];
  const statKeys = <String>['resilienza', 'volonta', 'materia', 'oculum'];
  final owner = <String, int>{
    for (final key in statKeys) key: max(0, playerStats[key] ?? 0),
  };
  final ownerTotal = statKeys.fold<int>(0, (sum, key) => sum + owner[key]!);
  final candidates =
      entries
          .where(
            (entry) =>
                oculumBlackMarketMonsterBookPageEligible(entry) &&
                !alreadyKnownWeakPoints.contains(entry.id),
          )
          .toList()
        ..sort((a, b) {
          int score(MonsterBookEntry entry) {
            final stats = entry.stats;
            final statDistance = statKeys.fold<int>(0, (sum, key) {
              return sum + ((stats[key] ?? 0) - owner[key]!).abs();
            });
            final total = statKeys.fold<int>(
              0,
              (sum, key) => sum + max(0, stats[key] ?? 0),
            );
            final levelDistance = ((stats['level'] ?? 0) - playerLevel).abs();
            return statDistance +
                (total - ownerTotal).abs() +
                levelDistance * 5;
          }

          final difference = score(a).compareTo(score(b));
          return difference != 0 ? difference : a.id.compareTo(b.id);
        });
  final selected = <MonsterBookEntry>[];
  final families = <String>{};
  for (final entry in candidates) {
    final family = oculumNormalizeText(
      entry.nameIt.split(RegExp(r'[·|/]')).first.trim(),
    );
    if (!families.add(family)) continue;
    selected.add(entry);
    if (selected.length >= max(0, limit)) break;
  }
  return selected;
}

String? oculumMerchantCanonicalOfferKey(Map<String, dynamic> offer) {
  final kind = '${offer['kind'] ?? ''}';
  String canonicalName(String key, List<String> prefixes) {
    var value = '${offer[key] ?? offer['name'] ?? offer['id'] ?? ''}'.trim();
    for (final prefix in prefixes) {
      if (oculumNormalizeText(value).startsWith(oculumNormalizeText(prefix))) {
        value = value.substring(prefix.length).trim();
        break;
      }
    }
    return oculumNormalizeText(value);
  }

  switch (kind) {
    case 'nurse_service':
      return 'nurse:${offer['service'] ?? ''}';
    case 'black_market_art':
      return 'art:${canonicalName('canonicalArtName', const ['Art Nera:'])}';
    case 'black_market_monster_art':
      return 'art:${canonicalName('canonicalArtName', const ['Art Oculum Nera ·'])}';
    case 'black_market_skill':
    case 'black_market_monster_skill':
      final semanticName = canonicalName('canonicalSkillName', const [
        'Tecnica Nera:',
        'Skill Nera ·',
      ]);
      if (semanticName.isNotEmpty) return 'skill:$semanticName';
      final skillId = '${offer['sourceSkillId'] ?? ''}';
      return 'skill:${skillId.isEmpty ? oculumNormalizeText('${offer['name'] ?? offer['id'] ?? ''}') : oculumMonsterBookSkillBaseId(skillId)}';
    case 'black_market_monster_weapon':
      return 'weapon:${canonicalName('canonicalItemName', const ['Arma del Mostro ·'])}';
    case 'technique_scroll':
      return 'scroll:${offer['scrollProfileId'] ?? offer['id']}:${offer['scrollGrade'] ?? ''}';
    case 'black_market_scroll':
      return 'scroll:${offer['scrollProfileId'] ?? offer['id']}:${offer['scrollGrade'] ?? ''}';
    case 'black_market_fallen_eye':
      return 'fallen_eye:${offer['sourceMonsterId'] ?? offer['id']}:${offer['level'] ?? ''}';
    case 'black_market_ascension_dust':
      return 'ascension_dust';
    case 'monster_book_page':
      return 'monster_book_page:${offer['monsterBookId'] ?? offer['id']}';
    default:
      return kind.startsWith('black_market_')
          ? 'black_market:${offer['id'] ?? offer['name']}'
          : null;
  }
}

int oculumMerchantOfferCount(Random random) =>
    random.nextInt(100) < 16 ? 12 : 6 + random.nextInt(4);

String? oculumMerchantOfferFamilyKey(Map<String, dynamic> offer) {
  final canonical = oculumMerchantCanonicalOfferKey(offer);
  if (canonical != null) return canonical;
  final kind = '${offer['kind'] ?? ''}';
  if (kind == 'gathering_collector') return 'gathering_collector';
  if (kind == 'creature_core') return 'creature_core';
  if (kind == 'stat_gem') return 'stat_gem:${offer['stat'] ?? ''}';
  if (kind == 'food') {
    final condition = '${offer['condition'] ?? ''}'.trim();
    if (condition == 'fortificato' ||
        readIntValue(offer['defensePercent']) > 0) {
      return 'food:defense';
    }
    if (condition.isNotEmpty) return 'food:condition:$condition';
    if (readIntValue(offer['damagePercent']) > 0) {
      return 'food:damage_percent';
    }
    if (readIntValue(offer['defensePercent']) > 0) {
      return 'food:defense_percent';
    }
    if (offer['restoreAllStats'] == true) return 'food:restore_all_stats';
    if (readIntValue(offer['healHpPercent']) > 0) return 'food:heal_hp';
    if (offer['cleanseNegativeConditions'] == true) {
      return 'food:cleanse_conditions';
    }
    final stats = const [
      'resilienza',
      'volonta',
      'materia',
      'oculum',
    ].where(offer.containsKey).toList(growable: false);
    if (stats.isNotEmpty) return 'food:stats:${stats.join(',')}';
    final id = '${offer['id'] ?? offer['name'] ?? ''}'.trim();
    return id.isEmpty ? null : 'food:$id';
  }
  final id = '${offer['id'] ?? ''}'.trim();
  return id.isEmpty ? null : '$kind:$id';
}

List<Map<String, dynamic>> oculumMerchantUniqueOffers(
  Iterable<Map<String, dynamic>> offers, {
  Random? random,
  Set<String> preferredIds = const <String>{},
}) {
  final seen = <String>{};
  final indexes = <String, int>{};
  final familyCounts = <String, int>{};
  final unique = <Map<String, dynamic>>[];
  for (final offer in offers) {
    final key = oculumMerchantOfferFamilyKey(offer);
    if (key == null || seen.add(key)) {
      if (key != null) {
        indexes[key] = unique.length;
        familyCounts[key] = 1;
      }
      unique.add(offer);
      continue;
    }
    final index = indexes[key]!;
    final existing = unique[index];
    final offerId = '${offer['id'] ?? ''}';
    final existingId = '${existing['id'] ?? ''}';
    final isPreferred = preferredIds.contains(offerId);
    final existingIsPreferred = preferredIds.contains(existingId);
    final familyCount = (familyCounts[key] ?? 1) + 1;
    familyCounts[key] = familyCount;
    if ((isPreferred && !existingIsPreferred) ||
        (!existingIsPreferred &&
            !isPreferred &&
            random != null &&
            random.nextInt(familyCount) == 0)) {
      unique[index] = offer;
    }
  }
  return unique;
}

double oculumMerchantPowerFit(Map<String, dynamic> offer, int totalPower) {
  final stats = offer['stats'];
  final explicit = offer['recommendedPower'] ?? offer['totalPower'];
  final strength = explicit is num
      ? explicit.toDouble()
      : max(0, readIntValue(offer['damage'])).toDouble() +
            max(0, readIntValue(offer['defence'] ?? offer['defense'])) +
            max(0, readIntValue(offer['shield'])) / 10 +
            (stats is Map
                ? stats.values.whereType<num>().fold<double>(
                    0,
                    (n, v) => n + max(0, v) * 3,
                  )
                : 0);
  if (strength <= 0) return 1;
  final power = max(1, totalPower);
  return (2.5 / (1 + (strength - power).abs() / power * 4)).clamp(.4, 2.5);
}

List<Map<String, dynamic>> oculumSelectMerchantOffers(
  List<Map<String, dynamic>> offers, {
  required int characterLevel,
  required int budget,
  required int count,
  required Random random,
  int Function(Map<String, dynamic> offer)? priceOf,
  int? characterTotalPower,
}) {
  final remaining = oculumMerchantUniqueOffers(offers).toList();
  final selected = <Map<String, dynamic>>[];
  final target = min(max(0, count), remaining.length);
  while (selected.length < target) {
    final weights = remaining
        .map((offer) {
          final hasLevel =
              offer.containsKey('requiredLevel') ||
              offer.containsKey('level') ||
              offer.containsKey('recommendedLevel');
          final offerLevel = readIntValue(
            offer['requiredLevel'] ??
                offer['level'] ??
                offer['recommendedLevel'],
          );
          final levelGap = (offerLevel - max(0, characterLevel)).abs();
          final levelWeight = !hasLevel
              ? 1.0
              : levelGap <= 1
              ? 2.0
              : levelGap <= 3
              ? 1.5
              : levelGap <= 6
              ? 1.0
              : .65;
          final price = max(
            0,
            priceOf?.call(offer) ?? readIntValue(offer['cost']),
          );
          final budgetWeight = budget <= 0
              ? 1.0
              : price <= budget
              ? 1.12
              : price <= budget + budget ~/ 4
              ? 1.0
              : .88;
          final powerWeight = characterTotalPower == null
              ? 1.0
              : oculumMerchantPowerFit(offer, characterTotalPower);
          return levelWeight * budgetWeight * powerWeight;
        })
        .toList(growable: false);
    final totalWeight = weights.fold<double>(0, (sum, value) => sum + value);
    var ticket = random.nextDouble() * totalWeight;
    var pickedIndex = weights.length - 1;
    for (var index = 0; index < weights.length; index++) {
      ticket -= weights[index];
      if (ticket < 0) {
        pickedIndex = index;
        break;
      }
    }
    selected.add(remaining.removeAt(pickedIndex));
  }
  return selected;
}

List<Map<String, dynamic>> oculumMerchantTimedFoodEffects(
  Map<String, dynamic> food, {
  required String source,
}) {
  final duration = readIntValue(
    food['conditionTurns'],
    fallback: 3,
  ).clamp(1, 999).toInt();
  final effects = <Map<String, dynamic>>[];
  for (final entry in <({String type, String target, String key})>[
    (
      type: 'danno_percentuale',
      target: 'danni_percentuale',
      key: 'damagePercent',
    ),
    (
      type: 'difesa_percentuale',
      target: 'difesa_percentuale',
      key: 'defensePercent',
    ),
  ]) {
    final value = readIntValue(food[entry.key]);
    if (value == 0) continue;
    effects.add(<String, dynamic>{
      'type': entry.type,
      'target': entry.target,
      'value': value,
      'remaining': duration,
      'unit': 'turni',
      'source': source,
      'mode': 'temporaneo',
    });
  }
  return effects;
}

int oculumAlchemyMediumFallenEyeLevel(int ownerLevel) =>
    max(0, ownerLevel - (max(0, ownerLevel) + 2) ~/ 3).toInt();

int oculumAlchemyRareFallenEyeLevel(int ownerLevel) =>
    (max(0, ownerLevel) + 1) ~/ 2;

int oculumAlchemyMediumFallenEyePrice({
  required int ownerLevel,
  required int ownerGrade,
  required int priceRoll,
}) =>
    56 +
    priceRoll.clamp(0, 33).toInt() +
    max(0, ownerLevel).toInt() +
    max(0, ownerGrade).toInt() * 3;

int oculumAlchemyRareFallenEyePrice({
  required int ownerLevel,
  required int ownerGrade,
  required int priceRoll,
}) =>
    230 +
    priceRoll.clamp(0, 220).toInt() +
    max(0, ownerLevel) ~/ 2 +
    max(0, ownerGrade).toInt() * 4;

const oculumStatGemNames = <String, String>{
  'resilienza': 'Gemma di Resilienza',
  'volonta': 'Gemma di Volontà',
  'materia': 'Gemma di Materia',
  'oculum': 'Gemma di Oculum',
};
const int oculumStatGemBaseCost = 3;
int oculumStatGemDieFaces(int stat) => max(1, max(0, stat) ~/ 3);
int oculumStatGemPrice(int stat) =>
    oculumStatGemBaseCost + 3 * (max(0, stat) ~/ 10);
bool oculumStatGemAvailable(Random random) => random.nextInt(4) == 0;

int oculumDropObserReward({
  required String subtraitId,
  required int rollTotal,
  required int level,
  required int dropBonus,
  required Random random,
}) {
  if (subtraitId != 'drop' || rollTotal <= 15) return 0;
  // Weights 26, 25, ... 1: low amounts are progressively more common.
  var ticket = random.nextInt(26 * 27 ~/ 2);
  for (var amount = 1; amount <= 26; amount++) {
    final weight = 27 - amount;
    if (ticket < weight) {
      return max(0, level).toInt() + max(0, dropBonus).toInt() + amount;
    }
    ticket -= weight;
  }
  throw StateError('Drop reward ticket outside its weighted range');
}

InventoryItem? oculumCreateTemporaryDropGem({
  required String subtraitId,
  required int naturalRoll,
  required bool usesOculum,
  required Map<String, int> stats,
  required Random random,
}) {
  if (subtraitId != 'drop' || naturalRoll < 19 || naturalRoll > 20) return null;
  final eligible = oculumStatGemNames.keys
      .where((key) => key != 'oculum' || usesOculum)
      .toList();
  final stat = eligible[random.nextInt(eligible.length)];
  final faces = oculumStatGemDieFaces(stats[stat] ?? 0);
  return InventoryItem(
    nome: '${oculumStatGemNames[stat]} temporanea',
    quantita: 1,
    peso: .1,
    statGemStat: stat,
    statGemDieFaces: faces,
    note:
        'Consumabile: recupera 1d$faces punti attuali. '
        'L’eccesso dura fino al riposo lungo. '
        'Resta nell’inventario finché non la usi.',
  );
}

int oculumMerchantShieldValue(int hp, int percent) =>
    (max(0, hp) * percent.clamp(35, 50) / 100).round();

int oculumMerchantDefenseValue(int materia) => 5 + 2 * max(0, materia);

int oculumMerchantAttackValue(int base, int will) =>
    max(0, base) + max(0, will) ~/ 2;

/// Tiro automatico del Vitalium Grezzo. Un 1 naturale e' un critico negativo:
/// puo' ridurre la cura, ma chi usa il risultato la limita sempre a zero.
int oculumRawVitaliumMedicineRoll({required int die, required int medicine}) {
  final total = die + medicine;
  return die == 1 ? -max(1, total.abs()) : total;
}

/// Gradi I-II: meta' del tiro; dal III: tiro intero. Mantiene il segno del
/// critico negativo, cosi' puo' annullare una cura ma non generare danno.
int oculumRawVitaliumMedicineBonus({
  required int grade,
  required int medicineRoll,
}) {
  if (grade >= 3) return medicineRoll;
  if (grade >= 1) return medicineRoll ~/ 2;
  return 0;
}

String oculumRawVitaliumRuleForGrade(int grade) {
  if (grade >= 3) {
    return 'Grado III+: attivo d30 + Medicina, tiro intero. Un 1 naturale può annullare la cura, mai fare danno.';
  }
  if (grade >= 2) {
    return 'Grado II: attivo d20 + Medicina, metà tiro. Un 1 naturale può annullare la cura, mai fare danno.';
  }
  if (grade >= 1) {
    return 'Grado I: attivo d10 + Medicina, metà tiro. Un 1 naturale può annullare la cura, mai fare danno.';
  }
  return 'Richiede Grado I per applicare il tiro automatico di Medicina.';
}

int oculumMerchantWeaponSkillDamage(int grade) => 5 + max(0, grade) * 10;

bool oculumMerchantCanPurchaseOffer(
  Map<String, dynamic> offer, {
  required int characterGrade,
}) {
  if (!const {'gear', 'title_item'}.contains('${offer['kind'] ?? ''}')) {
    return true;
  }
  return max(0, readIntValue(offer['grade'])) <= max(0, characterGrade);
}

int oculumMerchantEquipmentMinimumPrice(int grade) =>
    max(50, 50 + (max(0, grade) * 210 + 1) ~/ 3);

int oculumMonsterRelicSaleValueForMarketPrice(
  int marketPrice, {
  int quantity = 1,
}) => max(1, max(0, marketPrice) * 30 ~/ 100) * max(1, quantity);

int oculumMerchantEquipmentPrice(Map<String, dynamic> offer) {
  final grade = max(0, readIntValue(offer['grade']));
  final level = max(0, readIntValue(offer['level']));
  final levelBand = grade * 5;
  final levelPremium = max(0, level - levelBand) * 10;
  return max(
        readIntValue(offer['cost']),
        oculumMerchantEquipmentMinimumPrice(grade),
      ) +
      levelPremium;
}

bool oculumMerchantPawnV2Available(Random random) => random.nextInt(10) == 0;

int oculumMerchantPricePercent(Random random) {
  final roll = random.nextInt(100);
  if (roll < 3) return 125;
  if (roll == 3) return 85;
  return 95 + random.nextInt(11);
}

int oculumMerchantApplyPricePercent(int price, int percent) =>
    max(1, max(0, price) * percent.clamp(1, 10000) ~/ 100);

const oculumMerchantEssentialIds = [
  'pawn',
  'oculum_vial',
  'raw_vitalium',
  'refined_vitalium',
];

int oculumMerchantNeedScore(
  Map<String, dynamic> offer,
  Map<String, int> stats,
) {
  var score = 0;
  final bonuses = offer['statBonuses'];
  if (bonuses is Map) {
    for (final stat in const ['resilienza', 'volonta', 'materia', 'oculum']) {
      if (stat == 'oculum' && (stats[stat] ?? 0) <= 0) continue;
      final bonus = max(0, readIntValue(bonuses[stat]));
      score += bonus * (12 - (stats[stat] ?? 0).clamp(0, 12).toInt()) * 10;
    }
  }
  if (offer['kind'] == 'stat_gem' && readIntValue(offer['remaining']) > 0) {
    final key = '${offer['stat']}';
    if (key != 'oculum' || (stats['oculum'] ?? 0) > 0) {
      score += max(0, 10 - (stats[key] ?? 0)) * 3;
    }
  }
  return score;
}

List<Map<String, dynamic>> oculumMerchantOrderedOffers(
  List<Map<String, dynamic>> stock,
  Map<String, int> stats,
) {
  final indexed = stock.asMap().entries.toList();
  indexed.sort((a, b) {
    final ai = oculumMerchantEssentialIds.indexOf('${a.value['id']}');
    final bi = oculumMerchantEssentialIds.indexOf('${b.value['id']}');
    if (ai >= 0 || bi >= 0) {
      return (ai < 0 ? 100 : ai).compareTo(bi < 0 ? 100 : bi);
    }
    final score = oculumMerchantNeedScore(
      b.value,
      stats,
    ).compareTo(oculumMerchantNeedScore(a.value, stats));
    return score != 0 ? score : a.key.compareTo(b.key);
  });
  return indexed.map((entry) => entry.value).toList();
}

String oculumMerchantWeaponSkillName(String weaponName) {
  final lower = weaponName.toLowerCase();
  if (lower.contains('arco') || lower.contains('balestra')) {
    return 'Tiro di $weaponName';
  }
  if (lower.contains('martello') || lower.contains('mazza')) {
    return 'Schianto di $weaponName';
  }
  if (lower.contains('lancia') || lower.contains('picca')) {
    return 'Affondo di $weaponName';
  }
  if (lower.contains('ascia')) return 'Fendente di $weaponName';
  return 'Taglio di $weaponName';
}

String oculumMerchantWeaponSkillText(String weaponName, int grade) {
  final damage = oculumMerchantWeaponSkillDamage(grade);
  final nextDamage = damage + 5;
  return 'I/usi $weaponName: @Danni+$damage (1/4).\n'
      'II/@Danni+$nextDamage (2/4), scegli se spostare o esporre il bersaglio.\n'
      'III/@Danni+${nextDamage + 10} (3/4), il Master applica la conseguenza coerente con l arma.\n'
      'Al quarto uso la Skill va in recupero fino al turno successivo.';
}

double oculumMonsterFoodLearningChance(num luck) =>
    (.5 + luck).clamp(0, 100).toDouble();

/// Negoziante locale della scheda. Lo stock usa il salvataggio della scheda,
/// e resta stabile anche dopo il riavvio. Un nuovo mercante ha un nuovo stock.
extension _OculumHomeMerchant on _OculumHomePageState {
  Map<String, int> get merchantNeedStats => {
    for (final key in const ['resilienza', 'volonta', 'materia', 'oculum'])
      key: merchantGemStatValue(key),
  };
  void tryLearnMonsterFood(Map food) {
    final id = '${food['learnMonsterId'] ?? ''}';
    if (id.isEmpty) return;
    final monster = monsterById(id);
    if (monster == null) return;
    final fortune = hiddenEyeStats
        .where((s) => s.id == 'fortuna' && s.unlocked)
        .firstOrNull;
    final luck = fortune == null ? 0 : hiddenEyeTotal(fortune);
    final chance = oculumMonsterFoodLearningChance(luck);
    final roll = Random().nextDouble() * 100;
    if (roll >= chance) {
      aggiungiLog(
        '[CIBO MOSTRO] ${monster.nameIt}: nessuna skill appresa (${roll.toStringAsFixed(2)}% / ${chance.toStringAsFixed(1)}%).',
      );
      return;
    }
    final art = oculumMonsterBookArt(monster);
    final ids = monsterBookUsableSkillIds(monster);
    final eligible = <int>[
      for (var i = 0; i < min(ids.length, art.skills.length); i++)
        if (!skills.any((s) => s.nome == art.skills[i].nome)) i,
    ];
    if (eligible.isEmpty) {
      aggiungiLog(
        '[CIBO MOSTRO] Nessuna nuova skill di ${monster.nameIt} da apprendere.',
      );
      return;
    }
    final index = eligible[Random().nextInt(eligible.length)];
    final skill = _naturalMonsterSkill(monster, ids[index], art.skills[index])
      ..equipaggiata = false;
    skills.add(skill);
    aggiungiLog(
      '[CIBO MOSTRO] Appresa ${skill.nome} da ${monster.nameIt}. Forme, costi e cooldown modificabili nelle Skill.',
    );
  }

  int get merchantDustPrice => min(
    69,
    oculumMerchantApplyPricePercent(
      oculumBlackMarketDustPrice(
        basePrice:
            30 + (monsterSpriteStableSeed(merchantActiveProfileId) % 21).abs(),
        previousPurchases: merchantDustPurchaseCount,
      ),
      merchantPricePercent,
    ),
  );
  int get merchantPricePercent =>
      readIntValue(_activeMerchantProfile()['pricePercent'], fallback: 100);
  String get merchantShopType {
    final profile = merchantProfiles
        .where((p) => p['id'] == merchantActiveProfileId)
        .firstOrNull;
    return '${profile?['shopType'] ?? 'tutti'}';
  }

  int merchantOfferCost(Map<String, dynamic> offer) {
    final kind = '${offer['kind'] ?? ''}';
    if (const {'power_scanner', 'postea_power_scanner'}.contains(kind)) {
      return max(0, readIntValue(offer['cost']));
    }
    if (kind == 'dust_crystal') return max(0, readIntValue(offer['cost']));
    if (kind == 'postea_companion' && offer['companion'] == 'core') {
      return (90 +
              max(0, leggiNumero(livelloController)) +
              2 * max(0, leggiNumero(gradoController)))
          .toInt();
    }
    if (kind.startsWith('postea_') && kind != 'postea_cyber_armor') {
      return max(0, readIntValue(offer['cost']));
    }
    if (kind == 'postea_cyber_armor') return 36 + (maxHp() / 2).ceil();
    if (kind == 'black_market_ascension_dust') {
      return min(69, merchantDustPrice);
    }
    if (kind == 'black_market_fallen_eye') {
      final source = offer['sourceSheet'];
      final stats = source is Map
          ? ['resilienza', 'volonta', 'materia', 'oculum'].fold<int>(
              0,
              (sum, stat) => sum + max(0, readIntValue(source[stat])),
            )
          : 1;
      if (offer['priceFormulaVersion'] != 2) {
        // Existing saved offers retain their custom price until a new shop.
        return oculumMerchantApplyPricePercent(
          max(0, readIntValue(offer['cost'])),
          merchantPricePercent,
        );
      }
      final base = oculumBlackMarketFallenEyePrice(
        totalStats: stats,
        level: readIntValue(offer['level']),
        ownerTotalStats: readIntValue(offer['ownerStatTotal']),
        basePrice: readIntValue(offer['eyeBasePrice']),
        statUnitCost: readIntValue(offer['statUnitCost'], fallback: 2),
        surplusBlockSize: readIntValue(offer['surplusBlockSize'], fallback: 20),
        surplusPercentPerBlock: readIntValue(
          offer['surplusPercentPerBlock'],
          fallback: 25,
        ),
      );
      return oculumMerchantApplyPricePercent(base, merchantPricePercent);
    }
    if (kind == 'nurse_service') {
      return switch ('${offer['service'] ?? ''}') {
        'hp' => oculumNurseHpRecoveryCost(max(0, maxHp() - hpCorrenti())),
        'oculum_shield' => oculumNurseOculumShieldRecoveryCost(
          max(0, scudoOculumMax() - scudoOculum()),
        ),
        'full' => oculumNurseFullRestorationCost(
          missingHp: max(0, maxHp() - hpCorrenti()),
          missingOculumShield: max(0, scudoOculumMax() - scudoOculum()),
          missingStatPoints:
              (max(
                        0,
                        currentStatNaturalControllerMax('resilienza') -
                            currentResilienza(),
                      ) +
                      max(
                        0,
                        currentStatNaturalControllerMax('volonta') -
                            currentVolonta(),
                      ) +
                      max(
                        0,
                        currentStatNaturalControllerMax('materia') -
                            currentMateria(),
                      ) +
                      max(0, oculumMassimo() - oculumTotale()))
                  .toInt(),
          missingArtIntegrity: arti.fold<int>(
            0,
            (total, art) =>
                total +
                max(
                  0,
                  artIntegrityEffectiveMaximum(art) - art.integritaCorrente,
                ),
          ),
          negativeConditions: activeConditions
              .where(oculumConditionIsNegative)
              .length,
          buffPercent: readIntValue(
            offer['buffPercent'],
            fallback: 10,
          ).clamp(10, 60).toInt(),
          artIntegrityPerObser: readIntValue(
            offer['artIntegrityPerObser'],
            fallback: 10,
          ),
          cleanseCostPerCondition: readIntValue(
            offer['cleanseCostPerCondition'],
            fallback: 5,
          ),
        ),
        _ => max(0, readIntValue(offer['cost'])),
      };
    }
    final isEquipment = const {'gear', 'title_item'}.contains(offer['kind']);
    final base =
        const {
          'clothing',
          'postea_weapon',
          'postea_boots',
        }.contains(offer['kind'])
        ? readIntValue(offer['cost'])
        : isEquipment
        ? oculumMerchantEquipmentPrice(offer)
        : readIntValue(offer['cost']) +
              max(0, readIntValue(offer['level'])) * 25;
    final adjusted =
        merchantShopType == 'alchimista' && offer['kind'] == 'refined_vitalium'
        ? max(1, (base * .9).floor())
        : base;
    return oculumMerchantApplyPricePercent(adjusted, merchantPricePercent);
  }

  bool merchantOfferMatchesShop(Map<String, dynamic> offer) {
    if (!merchantOfferMatchesPlane(offer)) return false;
    final kind = '${offer['kind']}';
    if (kind == 'technique_scroll' &&
        readIntValue(offer['scrollGrade']) !=
            max(
              selectedPlane.minimumGrade,
              leggiNumero(gradoController),
            ).clamp(0, 12)) {
      return false;
    }
    if (kind.startsWith('postea_')) {
      return merchantShopType == 'postea' || merchantShopType == 'tutti';
    }
    if (kind == 'clothing') {
      return merchantShopType == 'sartoria' || merchantShopType == 'tutti';
    }
    return switch (merchantShopType) {
      'materiali' =>
        const {
              'raw_vitalium',
              'refined_vitalium',
              'oculum_vial',
              'creature_core',
            }.contains(kind) ||
            (kind == 'food' && offer['isMaterial'] == true),
      'fabbro' =>
        const {
              'pawn',
              'pawn_v2',
              'title_item',
              'gathering_collector',
              'weapon',
              'armor',
              'shield',
            }.contains(kind) ||
            offer['damage'] != null ||
            offer['defence'] != null,
      'mercato_nero' =>
        kind.startsWith('black_market_') ||
            kind == 'monster_book_page' ||
            (kind == 'technique_scroll' &&
                offer['blackMarketSelected'] == true),
      'infermiera_eroica' =>
        kind == 'nurse_service' || offer['nurseCatalog'] == true,
      'alchimista' =>
        const {
              'power_scanner',
              'fallen_eye',
              'smoking_herbs',
              'fate_sign',
              'chaos_sign',
              'stat_gem',
              'refined_vitalium',
              'oculum_vial',
              'bone_prison_scroll',
              'scroll',
              'technique_scroll',
              'alchemy_pet',
              'summoning_emblem',
              'creature_core',
            }.contains(kind) ||
            offer['isMaterial'] == true,
      'postea' => kind.startsWith('postea_'),
      'sartoria' => kind == 'clothing',
      'chef' => kind == 'food' && offer['isMaterial'] != true,
      _ => true,
    };
  }

  List<Map<String, dynamic>> recommendedMerchantStock() {
    final stock = ensureMerchantStock();
    final selections = _activeMerchantProfile()['offerSelections'];
    final selection = selections is Map ? selections[merchantShopType] : null;
    final rawSelectedIds = selection is Map ? selection['ids'] : null;
    if (rawSelectedIds is! List) return const <Map<String, dynamic>>[];
    final selectedIds = rawSelectedIds.map((id) => '$id').toSet();
    final selected = stock
        .where(
          (offer) =>
              merchantOfferMatchesShop(offer) &&
              selectedIds.contains('${offer['id'] ?? ''}') &&
              !merchantOfferUnavailable(offer),
        )
        .toList();
    return oculumMerchantOrderedOffers(
      oculumMerchantUniqueOffers(selected),
      merchantNeedStats,
    );
  }

  List<Map<String, dynamic>> _merchantReservedOffers(
    List<Map<String, dynamic>> candidates,
  ) {
    Map<String, dynamic>? firstWhere(bool Function(Map<String, dynamic>) test) {
      for (final offer in candidates) {
        if (test(offer)) return offer;
      }
      return null;
    }

    final reserved = <Map<String, dynamic>>[];
    switch (merchantShopType) {
      case 'mercato_nero':
        final dust = firstWhere(
          (offer) => offer['kind'] == 'black_market_ascension_dust',
        );
        final scroll = firstWhere(
          (offer) =>
              (offer['kind'] == 'technique_scroll' &&
                  offer['blackMarketSelected'] == true) ||
              offer['kind'] == 'black_market_scroll',
        );
        final entrySkill = firstWhere(
          (offer) =>
              offer['kind'] == 'black_market_skill' &&
              readIntValue(offer['requiredLevel']) <=
                  max(0, leggiNumero(livelloController)),
        );
        if (dust != null) reserved.add(dust);
        if (scroll != null) reserved.add(scroll);
        if (entrySkill != null) reserved.add(entrySkill);
        break;
      case 'alchimista':
        final fate = firstWhere((offer) => offer['kind'] == 'fate_sign');
        final pet = firstWhere((offer) => offer['kind'] == 'alchemy_pet');
        if (fate != null) reserved.add(fate);
        if (pet != null) reserved.add(pet);
        break;
      case 'fabbro':
        final pawn = firstWhere(
          (offer) => offer['kind'] == 'pawn' || offer['kind'] == 'pawn_v2',
        );
        if (pawn != null) reserved.add(pawn);
        break;
      case 'materiali':
        final vitalium = firstWhere((offer) => offer['kind'] == 'raw_vitalium');
        if (vitalium != null) reserved.add(vitalium);
        break;
      case 'infermiera_eroica':
        final refill = firstWhere(
          (offer) =>
              offer['kind'] == 'nurse_service' && offer['service'] == 'full',
        );
        if (refill != null) reserved.add(refill);
        break;
    }
    if (const {'alchimista', 'tutti'}.contains(merchantShopType)) {
      for (final offer in candidates) {
        if (offer['planeId'] == selectedPlaneId &&
            offer['kind'] == 'technique_scroll' &&
            const {
              'raggio_angelico',
              'richiamo_piranha',
            }.contains(offer['scrollProfileId'])) {
          if (!reserved.contains(offer)) reserved.add(offer);
        }
      }
    }
    return reserved;
  }

  void _ensureMerchantOfferSelection() {
    final profile = _activeMerchantProfile();
    final selections = profile['offerSelections'] is Map
        ? Map<String, dynamic>.from(profile['offerSelections'] as Map)
        : <String, dynamic>{};
    final savedValue = selections[merchantShopType];
    final saved = savedValue is Map
        ? Map<String, dynamic>.from(savedValue)
        : <String, dynamic>{};
    final savedIds = (saved['ids'] as List?)
        ?.map((id) => '$id')
        .toList(growable: true);
    final random = Random.secure();
    final level = max(0, leggiNumero(livelloController));
    final candidates = oculumMerchantUniqueOffers(
      merchantStock
          .where(merchantOfferMatchesShop)
          .where((offer) => !merchantOfferUnavailable(offer)),
      random: random,
      preferredIds: savedIds?.toSet() ?? const <String>{},
    );
    final reserved = _merchantReservedOffers(candidates);
    final reservedIds = reserved
        .map((offer) => '${offer['id'] ?? ''}')
        .where((id) => id.isNotEmpty)
        .toSet();
    final levelChanged = readIntValue(saved['level'], fallback: -1) != level;
    final totalPower = scoutTotalPowerAt(schedaCorrente);
    final powerChanged =
        saved.containsKey('totalPower') &&
        readIntValue(saved['totalPower']) != totalPower;
    final refreshSelection = levelChanged || powerChanged;
    final wasSaved = savedIds != null && savedValue is Map;
    final targetCount = wasSaved && !refreshSelection
        ? readIntValue(saved['count'], fallback: 0).clamp(6, 12).toInt()
        : oculumMerchantOfferCount(random);
    final candidateIds = candidates
        .map((offer) => '${offer['id'] ?? ''}')
        .toSet();
    final selectedIds = <String>[];
    for (final id in reservedIds) {
      if (candidateIds.contains(id)) selectedIds.add(id);
    }
    if (wasSaved && !refreshSelection) {
      for (final id in savedIds) {
        if (candidateIds.contains(id) && !selectedIds.contains(id)) {
          selectedIds.add(id);
        }
      }
    }
    if (selectedIds.length > targetCount) {
      selectedIds.removeRange(targetCount, selectedIds.length);
    }
    final missing = max(0, targetCount - selectedIds.length);
    if (missing > 0) {
      final selectedSet = selectedIds.toSet();
      final extras = oculumSelectMerchantOffers(
        candidates
            .where((offer) => !selectedSet.contains('${offer['id'] ?? ''}'))
            .toList(),
        characterLevel: level,
        characterTotalPower: totalPower,
        budget: max(0, leggiNumero(obserController)),
        count: missing,
        random: random,
        priceOf: merchantOfferCost,
      );
      selectedIds.addAll(extras.map((offer) => '${offer['id'] ?? ''}'));
    }
    final next = <String, dynamic>{
      'level': level,
      'totalPower': totalPower,
      'count': targetCount,
      'ids': selectedIds,
    };
    if (saved['level'] == next['level'] &&
        saved['totalPower'] == next['totalPower'] &&
        saved['count'] == next['count'] &&
        (saved['ids'] as List?)?.map((id) => '$id').join('|') ==
            selectedIds.join('|')) {
      return;
    }
    selections[merchantShopType] = next;
    profile['offerSelections'] = selections;
    programmaSalvataggio(invalidateCaches: false);
  }

  void selectMerchantShop(String type) {
    final profile = merchantProfiles
        .where((p) => p['id'] == merchantActiveProfileId)
        .firstOrNull;
    if (profile == null) return;
    // ignore: invalid_use_of_protected_member
    setState(() => profile['shopType'] = type);
    ensureMerchantStock();
    if (type == 'infermiera_eroica' && merchantIsOpen) {
      _rollNurseRefillBuffForShopOpen();
    }
    _saveActiveMerchantProfileStock();
    programmaSalvataggio();
    unawaited(sendRealtimeMerchantRosterSnapshot());
  }

  String merchantRecommendation(Map<String, dynamic> offer) {
    if (oculumMerchantNeedScore(offer, merchantNeedStats) <= 0) return '';
    final bonuses = offer['statBonuses'];
    if (bonuses is! Map) return '';
    final entries =
        bonuses.entries
            .where(
              (e) =>
                  readIntValue(e.value) > 0 &&
                  (e.key != 'oculum' || merchantGemStatValue('oculum') > 0),
            )
            .toList()
          ..sort(
            (a, b) => merchantGemStatValue(
              '${a.key}',
            ).compareTo(merchantGemStatValue('${b.key}')),
          );
    if (entries.isEmpty) return '';
    final stat = '${entries.first.key}';
    return 'Consigliato: $stat ${merchantGemStatValue(stat)} → +${entries.first.value} mentre equipaggiato.\n';
  }

  int merchantGemStatValue(String key) => max(
    0,
    leggiNumero(switch (key) {
      'resilienza' => resilienzaController,
      'volonta' => volontaController,
      'materia' => materiaController,
      _ => oculumController,
    }),
  );

  void updateMerchantGemOffers() {
    for (final offer in merchantStock.where((o) => o['kind'] == 'stat_gem')) {
      final stat = merchantGemStatValue('${offer['stat']}');
      offer['cost'] = oculumStatGemPrice(stat);
      offer['dieFaces'] = oculumStatGemDieFaces(stat);
      offer['baseStat'] = stat;
    }
  }

  int merchantCharacterPower() {
    final stats = [
      leggiNumero(resilienzaController),
      leggiNumero(volontaController),
      leggiNumero(materiaController),
      leggiNumero(oculumController),
    ];
    return stats.fold<int>(0, (sum, value) => sum + max(0, value));
  }

  int merchantScaledValue(int base, {double strength = 1, int level = 0}) {
    final power = merchantCharacterPower();
    final tenStatSteps = power ~/ 10;
    final factor = 1 + tenStatSteps * 0.05 * strength;
    return max(1, (base * factor).round() + max(0, level) * 25);
  }

  int merchantTitleCost(int baseCost, {int level = 0}) =>
      merchantScaledValue(baseCost, level: level);

  Map<String, dynamic> _activeMerchantProfile() {
    for (final profile in merchantProfiles) {
      if ('${profile['id'] ?? ''}' == merchantActiveProfileId) {
        final needsPrice = !profile.containsKey('pricePercent');
        profile.putIfAbsent(
          'pricePercent',
          () => oculumMerchantPricePercent(Random.secure()),
        );
        if (needsPrice) unawaited(sendRealtimeMerchantRosterSnapshot());
        return profile;
      }
    }
    final profile = <String, dynamic>{
      'id': merchantActiveProfileId,
      'name': 'Mercante di fiducia',
      'stock': <Map<String, dynamic>>[],
      'pricePercent': oculumMerchantPricePercent(Random.secure()),
    };
    merchantProfiles.add(profile);
    unawaited(sendRealtimeMerchantRosterSnapshot());
    return profile;
  }

  void _saveActiveMerchantProfileStock() {
    _activeMerchantProfile()['stock'] = merchantStock
        .map((offer) => Map<String, dynamic>.from(offer))
        .toList(growable: true);
  }

  String get activeMerchantName => '${_activeMerchantProfile()['name']}';

  void switchMerchantProfile(String profileId) {
    if (profileId == merchantActiveProfileId) return;
    _saveActiveMerchantProfileStock();
    Map<String, dynamic>? target;
    for (final profile in merchantProfiles) {
      if ('${profile['id'] ?? ''}' == profileId) {
        target = profile;
        break;
      }
    }
    if (target == null) return;
    merchantActiveProfileId = profileId;
    final stock = target['stock'];
    merchantStock = stock is List
        ? stock
              .whereType<Map>()
              .map((offer) => Map<String, dynamic>.from(offer))
              .toList(growable: true)
        : <Map<String, dynamic>>[];
    merchantStockSessionId = merchantStock.isEmpty
        ? ''
        : merchantRuntimeSessionId;
    ensureMerchantStock();
    _saveActiveMerchantProfileStock();
    // ignore: invalid_use_of_protected_member
    setState(() {});
    programmaSalvataggio();
    unawaited(sendRealtimeMerchantRosterSnapshot());
  }

  void createRandomMerchantProfile() {
    _saveActiveMerchantProfileStock();
    final profileId = 'merchant_${DateTime.now().microsecondsSinceEpoch}';
    merchantActiveProfileId = profileId;
    merchantStock = <Map<String, dynamic>>[];
    merchantStockSessionId = '';
    merchantProfiles.add(<String, dynamic>{
      'id': profileId,
      'name': 'Mercante ${merchantProfiles.length + 1}',
      'stock': <Map<String, dynamic>>[],
    });
    ensureMerchantStock();
    _saveActiveMerchantProfileStock();
    // ignore: invalid_use_of_protected_member
    setState(() {});
    programmaSalvataggio();
  }

  Widget merchantProfileControls() => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      OutlinedButton.icon(
        onPressed: selectCurrentPlane,
        icon: const Icon(Icons.public),
        label: Text('Piano: ${selectedPlane.name}'),
      ),
      if (planeNeedsAdaptation)
        OutlinedButton(
          onPressed: rollPlaneAdaptation,
          child: Text('Adattamento · pressione −$planePressurePenalty stats'),
        ),
      DropdownButton<String>(
        value: merchantShopType,
        onChanged: (v) {
          if (v != null) selectMerchantShop(v);
        },
        items: const [
          DropdownMenuItem(value: 'tutti', child: Text('Tutti i banchi')),
          DropdownMenuItem(
            value: 'materiali',
            child: Text('Venditore di materiali'),
          ),
          DropdownMenuItem(
            value: 'fabbro',
            child: Text('Fabbro · armi e Pawn'),
          ),
          DropdownMenuItem(
            value: 'alchimista',
            child: Text('Alchimista · cristalli e crafting'),
          ),
          DropdownMenuItem(
            value: 'postea',
            child: Text('Postea · Rusty, mercante runico'),
          ),
          DropdownMenuItem(
            value: 'sartoria',
            child: Text('Creatrice di vestiti · sartoria'),
          ),
          DropdownMenuItem(value: 'chef', child: Text('Chef · cibi e bevande')),
          DropdownMenuItem(
            value: 'mercato_nero',
            child: Text('Mercato nero · Art e Skill'),
          ),
          DropdownMenuItem(
            value: 'infermiera_eroica',
            child: Text('Infermiera eroica · cure e recupero'),
          ),
        ],
      ),
      PopupMenuButton<String>(
        tooltip: 'Torna da un mercante già incontrato',
        onSelected: switchMerchantProfile,
        itemBuilder: (context) => [
          for (final profile in merchantProfiles)
            PopupMenuItem<String>(
              value: '${profile['id']}',
              child: Text('${profile['name'] ?? 'Mercante'}'),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz),
              const SizedBox(width: 7),
              Text('Cambia mercante · ${merchantProfiles.length} salvati'),
            ],
          ),
        ),
      ),
      OutlinedButton.icon(
        onPressed: createRandomMerchantProfile,
        icon: const Icon(Icons.casino_outlined),
        label: const Text('Nuovo mercante'),
      ),
    ],
  );

  List<Map<String, dynamic>> ensureMerchantStock() {
    if (merchantStock.isNotEmpty) ensureSmokingHerbsOffer();
    if (merchantStock.isNotEmpty) {
      merchantStockSessionId = merchantRuntimeSessionId;
      updateMerchantGemOffers();
      ensureMerchantFoodOffers();
      if (merchantShopType == 'alchimista') {
        final profile = _activeMerchantProfile();
        if (profile['alchemyFallenEyeStockRolled'] != true) {
          addAlchemyFallenEyeOffers(
            Random(
              monsterSpriteStableSeed(merchantActiveProfileId) ^
                  DateTime.now().microsecondsSinceEpoch,
            ),
          );
          profile['alchemyFallenEyeStockRolled'] = true;
        }
      }
      ensureMerchantSpecialOffers();
      _ensureMerchantOfferSelection();
      _saveActiveMerchantProfileStock();
      return merchantStock;
    }
    final random = Random(
      monsterSpriteStableSeed(currentSheetScrollId()) ^
          DateTime.now().microsecondsSinceEpoch,
    );
    final rawVitaliumRule = oculumRawVitaliumRuleForGrade(
      max(0, leggiNumero(gradoController)),
    );
    merchantStock = <Map<String, dynamic>>[
      {
        'id': 'raw_vitalium',
        'name': 'Vitalium Grezzo',
        'cost': 13 + random.nextInt(7),
        'kind': 'raw_vitalium',
        'desc':
            'Consumabile: scegli quanto Oculum immettere e recuperi altrettanti HP. Se non hai Oculum, puoi alimentarlo spendendo 2 Materia e 2 Volontà per ogni punto. $rawVitaliumRule',
      },
      if (random.nextInt(50) != 0)
        {
          'id': 'refined_vitalium',
          'name': 'Vitalium Ridefinito',
          'cost': 100 + random.nextInt(61),
          'kind': 'refined_vitalium',
          'desc':
              'Ripristina HP, integrità delle Art e statistiche attuali fino ai massimali; non crea Oculum se il massimale è zero.',
        },
      {
        'id': 'oculum_vial',
        'name': 'Fiala di Oculum',
        'cost': 6 + random.nextInt(3),
        'kind': 'oculum_vial',
        'desc': 'Consumabile: ricarica 1d4 Oculum.',
      },
      {
        'id': 'title_item',
        'name': 'Item Titolo',
        'cost': merchantTitleCost(75 + random.nextInt(46)),
        'kind': 'title_item',
        'level': 1 + random.nextInt(10),
        'grade': 0,
        'damage': oculumMerchantAttackValue(6, leggiNumero(volontaController)),
        'defence': oculumMerchantDefenseValue(leggiNumero(materiaController)),
        'shield': oculumMerchantShieldValue(maxHp(), 35 + random.nextInt(16)),
        'desc': 'Scegli tu se diventa arma, armatura o scudo.',
      },
    ];
    if (oculumMerchantPawnV2Available(random)) {
      merchantStock.add(oculumPawnV2MerchantOffer());
    }
    for (final gem in oculumStatGemNames.entries) {
      if (!oculumStatGemAvailable(random)) continue;
      merchantStock.add(<String, dynamic>{
        'id': 'stat_gem_${gem.key}',
        'name': gem.value,
        'kind': 'stat_gem',
        'stat': gem.key,
        'remaining': 1,
        'desc':
            'Una gemma rara, consumabile. La sua forza è fissata quando la acquisti.',
      });
    }
    updateMerchantGemOffers();
    if (random.nextInt(12) == 0) {
      merchantStock.add(<String, dynamic>{
        'id': 'scroll_bone_prison',
        'name': 'Pergamena della Prigione d Ossa',
        'cost': 160,
        'kind': 'bone_prison_scroll',
        'desc':
            'Rara. Imprigiona il bersaglio, applica Stordito e infligge danno perforante.',
      });
    }
    // Quattro offerte distinte da materiali reali del Monster Book.
    // Lo stock salvato resta invariato fino alla scelta di un nuovo mercante.
    const catalog =
        <({String name, bool weapon, String monster, int grade, int damage})>[
          (
            name: 'Corno Affilato del Forest Demon',
            weapon: true,
            monster: 'forest_demon',
            grade: 1,
            damage: 10,
          ),
          (
            name: 'Guanto di Zanne di Goblin',
            weapon: true,
            monster: 'goblin_base',
            grade: 0,
            damage: 5,
          ),
          (
            name: 'Arco di Piume di Arpia',
            weapon: true,
            monster: 'arpia_base',
            grade: 0,
            damage: 6,
          ),
          (
            name: 'Lancia di Basalto dello Scarabeo',
            weapon: true,
            monster: 'scarabeo_di_basalto',
            grade: 0,
            damage: 7,
          ),
          (
            name: 'Lama del Demone Glaciale',
            weapon: true,
            monster: 'demone_glaciale_minore',
            grade: 1,
            damage: 9,
          ),
          (
            name: 'Corazza di Carapace di Scarabeo',
            weapon: false,
            monster: 'scarabeo_di_basalto',
            grade: 0,
            damage: 0,
          ),
          (
            name: 'Scudo di Roccia Slime',
            weapon: false,
            monster: 'slime_roccioso',
            grade: 0,
            damage: 0,
          ),
          (
            name: 'Mantello di Pelle del Lupo di Bruma',
            weapon: false,
            monster: 'lupo_di_bruma',
            grade: 0,
            damage: 0,
          ),
        ];
    final usedGearNames = <String>{};
    for (var i = 0; i < 4; i++) {
      final source = catalog[random.nextInt(catalog.length)];
      if (!usedGearNames.add(source.name)) {
        i--;
        continue;
      }
      final grade = min(12, source.grade + (random.nextInt(40) == 0 ? 1 : 0));
      final protection = !source.weapon;
      final offensiveShield =
          protection &&
          (source.name.startsWith('scudo ') ||
              source.name.startsWith('brocchiere ')) &&
          random.nextBool();
      final weapon = source.weapon || offensiveShield;
      final damage = offensiveShield
          ? 2 + grade * 8
          : source.damage + max(0, grade - source.grade) * 5;
      final defence = oculumMerchantDefenseValue(
        leggiNumero(materiaController),
      );
      final shieldValue = oculumMerchantShieldValue(
        maxHp(),
        35 + random.nextInt(16),
      );
      final breakEffect = protection
          ? <String, dynamic>{
              'duration': 2,
              'abilityBoostPercent': 50,
              'buffTarget': source.monster == 'lupo_di_bruma' ? 'cm' : 'difesa',
              'buffValue': 4 + grade * 2,
              'condition': source.monster == 'lupo_di_bruma'
                  ? 'concentrato'
                  : 'fortificato',
              'element': monsterById(source.monster)?.elementId ?? 'fisico',
              'resistance': 'Resistenza',
            }
          : <String, dynamic>{};
      merchantStock.add(<String, dynamic>{
        'id': 'merchant_${i}_${random.nextInt(1 << 31)}',
        'authored': true,
        'monsterId': source.monster,
        'buff': source.monster == 'forest_demon' ? '@Schianto+2' : '',
        'statBonuses': source.monster == 'goblin_base'
            ? {'materia': 2}
            : source.monster == 'arpia_base' ||
                  source.monster == 'lupo_di_bruma'
            ? {'materia': 1}
            : source.monster == 'scarabeo_di_basalto' ||
                  source.monster == 'slime_roccioso'
            ? {'resilienza': 1}
            : <String, int>{},
        'name': source.name,
        'cost': merchantTitleCost(
          grade == 0
              ? 25 + random.nextInt(51)
              : grade * (86 + random.nextInt(115)),
        ),
        'kind': 'gear',
        'level': max(1, grade * 5 + random.nextInt(5)),
        'grade': grade,
        'weapon': weapon,
        'protection': protection,
        'shield': shieldValue,
        'damage': damage,
        'defence': defence,
        'quickReaction': grade > 0 && random.nextInt(9) == 0,
        if (breakEffect.isNotEmpty) 'shieldBreakEffect': breakEffect,
        'desc': grade == 0
            ? (breakEffect.isNotEmpty
                  ? 'Alla rottura dello scudo: ${breakEffect['condition']} e ${breakEffect['resistance']} a ${breakEffect['element']} per ${breakEffect['duration']} turni.'
                  : offensiveShield
                  ? 'Scudo offensivo.'
                  : 'Equipaggiamento del mercante.')
            : 'Oggetto graduato molto raro: richiede Grado $grade per essere equipaggiato.',
      });
    }
    merchantStock.addAll([
      <String, dynamic>{
        'id': 'weapon_echo_riflessi',
        'name': 'Stocco dell’Eco Riflessa',
        'kind': 'gear',
        'cost': 80,
        'level': 1,
        'grade': 0,
        'weapon': true,
        'protection': false,
        'damage': 4,
        'defence': 0,
        'buff': '@Danni+1/4dadoriflessi',
        'desc':
            'Arma del fabbro: quando attacchi usando Riflessi, aggiunge un quarto del risultato totale del tiro ai danni di ogni bersaglio. Negli altri attacchi il tratto non si attiva.',
      },
      <String, dynamic>{
        'id': 'weapon_martello_forza',
        'name': 'Martello della Faglia',
        'kind': 'gear',
        'cost': 160,
        'level': 4,
        'grade': 1,
        'weapon': true,
        'protection': false,
        'damage': 9,
        'defence': 0,
        'buff': '@Danni+1/3dadoforza',
        'desc':
            'Arma del fabbro: quando attacchi usando Forza, aggiunge un terzo del risultato totale del tiro ai danni di ogni bersaglio. Negli altri attacchi il tratto non si attiva.',
      },
      <String, dynamic>{
        'id': 'weapon_lancia_velo',
        'name': 'Lancia della Soglia Velata',
        'kind': 'gear',
        'cost': 105,
        'level': 3,
        'grade': 0,
        'weapon': true,
        'protection': false,
        'damage': 6,
        'defence': 0,
        'buff': '@Danni+1/5dadovelo',
        'desc':
            'Arma del fabbro: con Velo aggiunge un quinto del risultato totale del tiro ai danni di ciascun bersaglio. Skill bloccata fino al livello 3.',
      },
      <String, dynamic>{
        'id': 'weapon_pugnale_precisione',
        'name': 'Pugnale della Misura Esatta',
        'kind': 'gear',
        'cost': 115,
        'level': 5,
        'grade': 0,
        'weapon': true,
        'protection': false,
        'damage': 5,
        'defence': 0,
        'buff': '@Danni+1/4dadoprecisione',
        'desc':
            'Arma del fabbro: con Precisione aggiunge un quarto del risultato totale del tiro ai danni di ciascun bersaglio. Skill bloccata fino al livello 5.',
      },
      <String, dynamic>{
        'id': 'armor_corazza_guardia',
        'name': 'Corazza della Guardia Frazionata',
        'kind': 'gear',
        'cost': 120,
        'level': 4,
        'grade': 0,
        'weapon': false,
        'protection': true,
        'damage': 0,
        'defence': 9,
        'shield': 12,
        'buff': '@Danni+1/5dadoresilienza',
        'desc':
            'Armatura del fabbro: la skill difensiva richiede livello 4; il tratto offensivo si attiva solo se attacchi con Resilienza.',
      },
      <String, dynamic>{
        'id': 'shield_bastione_materia',
        'name': 'Scudo del Bastione di Materia',
        'kind': 'gear',
        'cost': 132,
        'level': 6,
        'grade': 0,
        'weapon': false,
        'protection': true,
        'damage': 0,
        'defence': 8,
        'shield': 18,
        'buff': '@Danni+1/5dadomateria',
        'desc':
            'Scudo del fabbro: la skill difensiva richiede livello 6; il tratto offensivo si attiva solo se attacchi con Materia.',
      },
    ]);
    merchantStockSessionId = merchantRuntimeSessionId;
    ensureMerchantFoodOffers();
    if (merchantShopType == 'alchimista' &&
        _activeMerchantProfile()['alchemyFallenEyeStockRolled'] != true) {
      addAlchemyFallenEyeOffers(random);
      _activeMerchantProfile()['alchemyFallenEyeStockRolled'] = true;
    }
    ensureMerchantSpecialOffers();
    _ensureMerchantOfferSelection();
    _saveActiveMerchantProfileStock();
    return merchantStock;
  }

  void ensureClothingOffers() {
    ensureMagicSilkOffers();
    const designs = [
      (
        'femminile',
        'Abito della Rosa Nera',
        'Velluto prugna scuro, corpetto a cuciture d’argento e gonna a pannelli con sottogonna leggera. Il pizzo delle maniche disegna spine; gli spacchi laterali nascosti lasciano correre e combattere.',
      ),
      (
        'maschile',
        'Redingote del Vespro',
        'Lana antracite, spalle sagomate e falde lunghe foderate di raso color vino. Bottoni bruniti, collo alto e gilet con piccole tasche interne proteggono dal vento senza irrigidire i gomiti.',
      ),
      (
        'unisex',
        'Mantello del Pellegrino Cinereo',
        'Tela cerata grigio cenere sopra una tunica morbida, cappuccio profondo e fibbia di ferro a luna spezzata. La mantella corta lascia libere le braccia; cuciture rinforzate e tasche piatte servono al viaggio.',
      ),
      (
        'femminile',
        'Completo della Cacciatrice d’Ombra',
        'Giacca corta di pelle morbida, pantaloni aderenti rinforzati alle ginocchia e sciarpa color petrolio. Ricami geometrici, cintura modulare e bordi consumati danno un taglio pratico al gusto gotico.',
      ),
      (
        'maschile',
        'Farsetto del Guardiano d’Autunno',
        'Lino color terra sotto un farsetto verde bosco trapuntato, con alamari in osso levigato. Pantaloni ampi e polsi regolabili richiamano un abito da esploratore, sobrio e comodo anche fuori battaglia.',
      ),
      (
        'unisex',
        'Soprabito della Notte Stellata',
        'Cotone blu inchiostro, interno color rame e minuscoli punti metallici come stelle. Chiusura asimmetrica, collo ripiegabile e laccetti laterali permettono di adattare il taglio a corporature diverse.',
      ),
    ];
    final rng = Random();
    const growth = [
      'resilienza',
      'volonta',
      'materia',
      'oculum',
      'riflessi',
      'velo',
      'precisione',
      'resistenza',
    ];
    for (var i = 0; i < 16; i++) {
      final id = 'sartoria_stile_v2_$i';
      if (merchantStock.any((o) => o['id'] == id)) continue;
      final design = designs[i % designs.length];
      final level = i ~/ 2 + 1;
      final stat = growth[i % growth.length];
      final tempHp = i % 3 == 0 ? 5 : 0;
      final shield = 3 + (i % 2) * 3;
      final oculumShield = i == 15 ? 3 : 0;
      final damage = i % 5 == 0 ? 1 : 0;
      final defense = i % 4 == 0 ? 1 : 0;
      final base = 9 + rng.nextInt(10);
      merchantStock.add({
        'id': id,
        'kind': 'clothing',
        'name': '${design.$2} · $level',
        'level': level,
        'grade': 0,
        'growthStat': stat,
        'growthEvery': i % growth.length < 4 ? 3 : 2,
        'shield': shield,
        'oculumShield': oculumShield,
        'tempHp': tempHp,
        'damage': damage,
        'defence': defense,
        'baseCost': base,
        'cost':
            base +
            (tempHp / 5).ceil() * 2 +
            (shield / 3).ceil() * 2 +
            (oculumShield / 3).ceil() * 5 +
            damage * 2 +
            defense * 2 +
            2,
        'desc':
            'Taglio ${design.$1}. ${design.$3} Vestito economico: +1 $stat ogni ${i % growth.length < 4 ? 3 : 2} livelli oggetto. Bonus dimezzati per difetto quando si rompe il suo Scudo. Skill di protezione modificabile. Supplementi proposti: crescita 2 Obser, Danni/Difesa 2 Obser per punto.',
      });
    }
  }

  void ensureMerchantSpecialOffers() {
    ensurePowerScannerOffers();
    ensurePosteaOffers();
    ensureDustCrystalOffers();
    ensurePlaneOffers();
    ensureClothingOffers();
    if (!merchantStock.any((o) => o['id'] == 'postea_runic_mitra_15')) {
      merchantStock.add({
        'id': 'postea_runic_mitra_15',
        'kind': 'postea_weapon',
        'name': 'Mitra runico Postea',
        'cost': 50,
        'damage': 15,
        'desc':
            'Rusty, robottino malconcio del futuro errante di Postea. Seleziona il Mitra in Attacco: +15 danni che ignorano le resistenze. Il resto dell’attacco segue le resistenze normali; Difesa e Scudi restano applicabili.',
      });
    }
    if (!merchantStock.any((o) => o['id'] == 'postea_jump_boots')) {
      merchantStock.add({
        'id': 'postea_jump_boots',
        'kind': 'postea_boots',
        'name': 'Stivali del doppio salto Postea',
        'cost': 60,
        'desc':
            'Doppio salto gratuito fuori fight. In Difesa: un reroll CM +3, CD 5 turni. Non consuma Azioni, Reazioni o Reazioni veloci.',
      });
    }
    const cyberNames = [
      'Armatura Nervo di Neon',
      'Corazza del Ronin Sintetico',
      'Guscio della Cattedrale Elettrica',
    ];
    const cyberDescriptions = [
      'Taglio femminile: piastre sottili color ossidiana sopra una giacca corta in fibra tecnica, vita sagomata e gambali articolati. Circuiti viola corrono tra le cuciture; il collare proietta un’aureola di interferenza quando assorbe un colpo.',
      'Taglio maschile: corazza a lamelle di ceramica nera, spallacci bassi e soprabito sintetico con falde aperte. Fili rossi sotto vetro e un visore pieghevole richiamano un ronin delle città verticali; le giunture restano morbide.',
      'Taglio unisex regolabile: cappotto blindato color piombo, placche pettorali modulari e cappuccio con rete luminosa turchese. Cavi intrecciati come vetrate gotiche scaricano energia lungo i bordi, mentre fibbie magnetiche adattano il guscio al corpo.',
    ];
    for (var i = 0; i < cyberNames.length; i++) {
      final id = 'postea_cyber_armor_$i';
      if (merchantStock.any((o) => o['id'] == id)) continue;
      merchantStock.add({
        'id': id,
        'kind': 'postea_cyber_armor',
        'name': cyberNames[i],
        'variant': i,
        'cost': 36,
        'desc':
            '${cyberDescriptions[i]} Scudo consumabile: metà HP massimi fissata all’acquisto (per eccesso). Prezzo 36 + Scudo. Alla rottura diventa logora: bonus dimezzati, nessuna ricarica automatica; 99% di un buff per 6 turni.',
      });
    }
    final ids = merchantStock.map((offer) => '${offer['id']}').toSet();
    void add(Map<String, dynamic> offer) {
      final id = '${offer['id']}';
      if (ids.add(id)) merchantStock.add(offer);
    }

    void addMany(Iterable<Map<String, dynamic>> offers) {
      for (final offer in offers) {
        if (ids.add('${offer['id']}')) merchantStock.add(offer);
      }
    }

    if (merchantShopType == 'mercato_nero') {
      final ownerStats = <String, int>{
        'resilienza': currentStatNaturalControllerMax('resilienza'),
        'volonta': currentStatNaturalControllerMax('volonta'),
        'materia': currentStatNaturalControllerMax('materia'),
        'oculum': currentStatNaturalControllerMax('oculum'),
      };
      final alreadyKnown = <String>{
        for (final entry in monsterBookEntries)
          if (monsterBookPartyKnowledge(entry.id)?['pagePurchased'] == true)
            entry.id,
      };
      final candidates = oculumRankBlackMarketMonsterBookPages(
        entries: monsterBookEntries,
        playerLevel: max(0, leggiNumero(livelloController)),
        playerStats: ownerStats,
        alreadyKnownWeakPoints: alreadyKnown,
        limit: 3,
      );
      for (final entry in candidates) {
        add(<String, dynamic>{
          'id': 'monster_book_page_${entry.id}',
          'name': 'Pagina Monster Book · ${entry.nameIt}',
          'kind': 'monster_book_page',
          'monsterBookId': entry.id,
          'cost': oculumBlackMarketMonsterBookPageBasePrice(entry),
          'remaining': 1,
          'desc':
              'Pagina rara del Mercato Nero: rivela aspetto, resistenze e punto debole specifico. Sblocca il tiro Precisione mirato in combattimento. Prezzo ${oculumBlackMarketMonsterBookPageBasePrice(entry)} Obser.',
        });
      }
    }

    if (merchantShopType == 'fabbro') {
      for (var collectorGrade = 0; collectorGrade <= 12; collectorGrade++) {
        add(<String, dynamic>{
          'id': 'raccoglitore_grado_$collectorGrade',
          'name':
              'Raccoglitore Grado ${collectorGrade == 0 ? '0' : oculumRomanStage(collectorGrade)}',
          'kind': 'gathering_collector',
          'cost': 350 + collectorGrade * 70,
          'level': 0,
          'grade': collectorGrade,
          'remaining': 1,
          'desc':
              'Passiva: raddoppia i materiali raccolti di Grado $collectorGrade o inferiore. Nessun requisito di livello aggiuntivo.',
        });
      }
    }
    if (merchantShopType == 'mercato_nero') {
      addMany(<Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'black_market_art_scoria',
          'name': 'Art Nera: Archivio delle Scorie',
          'kind': 'black_market_art',
          'canonicalArtName': 'Archivio delle Scorie',
          'cost': 18000,
          'requiredLevel': 0,
          'remaining': 1,
          'desc':
              'Art acquistabile e modificabile. Contiene due tecniche offensive con forme evolutive; livello, testi, danni e recupero restano editabili.',
        },
        <String, dynamic>{
          'id': 'black_market_skill_brace',
          'name': 'Tecnica Nera: Colpo di Brace',
          'kind': 'black_market_skill',
          'canonicalSkillName': 'Colpo di Brace',
          'cost': 8000,
          'requiredLevel': 0,
          'remaining': 1,
          'desc':
              'Skill d’attacco iniziale: +20 danni Fuoco, una Azione, recupero 3 turni. Modificabile nelle Skill.',
        },
        <String, dynamic>{
          'id': 'black_market_skill_gelo',
          'name': 'Tecnica Nera: Taglio di Gelo',
          'kind': 'black_market_skill',
          'canonicalSkillName': 'Taglio di Gelo',
          'cost': 12000,
          'requiredLevel': 0,
          'remaining': 1,
          'desc':
              'Skill d’attacco iniziale: +30 danni Ghiaccio, una Azione, recupero 4 turni. Modificabile nelle Skill.',
        },
        <String, dynamic>{
          'id': 'black_market_scroll_corruption',
          'name': 'Pergamena Nera · Padrone della Corruzione',
          'kind': 'black_market_scroll',
          'scrollProfileId': 'corruption',
          'scrollGrade': max(
            0,
            leggiNumero(gradoController),
          ).clamp(0, 12).toInt(),
          'cost': oculumCorruptionScrollPrice(
            max(0, leggiNumero(gradoController)).clamp(0, 12).toInt(),
          ),
          'remaining': 1,
          'desc':
              'Pergamena d’attacco monouso, venduta soltanto qui. A colpo riuscito: 100% di infezione, −20 punti per ogni Grado del mostro sopra quello della pergamena, fino a 0%. La Skill appresa è passiva, non evolvibile e modificabile nella scheda.',
        },
        <String, dynamic>{
          'id': 'black_market_ascension_dust',
          'name': 'Ascension Dust · dose clandestina',
          'kind': 'black_market_ascension_dust',
          'purchaseLimit': 3,
          'desc':
              'Fino a tre acquisti per Riposo Lungo. La dose successiva aumenta di 10 Obser; la terza non supera 69 Obser.',
        },
      ]);
      ensureBlackMarketOffers();
    }
    if (merchantShopType == 'infermiera_eroica') {
      addMany(<Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'nurse_service_hp',
          'name': 'Cura delle ferite',
          'kind': 'nurse_service',
          'service': 'hp',
          'desc': 'Ripristina tutti gli HP mancanti: 1 Obser ogni 10 HP.',
        },
        <String, dynamic>{
          'id': 'nurse_service_oculum_shield',
          'name': 'Ricarica Scudo Oculum',
          'kind': 'nurse_service',
          'service': 'oculum_shield',
          'desc': 'Ripristina lo Scudo Oculum mancante: 2 Obser per punto.',
        },
        <String, dynamic>{
          'id': 'nurse_service_will',
          'name': 'Stimolante di Volontà',
          'kind': 'nurse_service',
          'service': 'will',
          'cost': 1,
          'desc': 'Ripristina 1 punto attuale di Volontà, fino al massimale.',
        },
        <String, dynamic>{
          'id': 'nurse_service_matter',
          'name': 'Stimolante di Materia',
          'kind': 'nurse_service',
          'service': 'matter',
          'cost': 1,
          'desc': 'Ripristina 1 punto attuale di Materia, fino al massimale.',
        },
        <String, dynamic>{
          'id': 'nurse_service_temp_hp',
          'name': 'Bendaggio eroico',
          'kind': 'nurse_service',
          'service': 'temp_hp',
          'cost': 2,
          'desc': 'Dona +15 HP temporanei, nel limite della scheda.',
        },
        <String, dynamic>{
          'id': 'nurse_service_shield',
          'name': 'Piastra di Scudo',
          'kind': 'nurse_service',
          'service': 'shield',
          'cost': 2,
          'desc': 'Dona +10 Scudo normale.',
        },
        <String, dynamic>{
          'id': 'nurse_service_oculum',
          'name': 'Fiala di Oculum',
          'kind': 'nurse_service',
          'service': 'oculum',
          'cost': 3,
          'desc': 'Ripristina 1 Oculum attuale, fino al massimale.',
        },
        <String, dynamic>{
          'id': 'nurse_service_full',
          'name': 'Refull · buff Danni e Difesa',
          'kind': 'nurse_service',
          'service': 'full',
          'buffPercent': 10,
          'standardBuffPercents': <int>[10, 15, 20, 25, 30],
          'rareBuffJackpotChancePercent': 1,
          'rareBuffValues': <int>[40, 60],
          'jackpotShieldHpFractionDenominator': 4,
          'rareTempHpChancePercent': 1,
          'halfTempHpRoundedUpChancePercent': 2,
          'halfTempHpRoundedDownChancePercent': 5,
          'tempHpPerLevel': 5,
          'artIntegrityPerObser': 10,
          'cleanseCostPerCondition': 5,
          'desc':
              'Refull completo con +10–30% a Danni e Difesa per la prossima battaglia. 1% jackpot: +40% o +60% e Scudo gratuito pari a un quarto degli HP massimi. HP temporanei: 1% di 5 × livello, 2% metà massimale per eccesso, 5% metà per difetto. Sovrapprezzo 1 Obser ogni 5%.',
        },
        <String, dynamic>{
          'id': 'nurse_vitalium_raw',
          'name': 'Vitalium Grezzo',
          'kind': 'raw_vitalium',
          'cost': 25,
          'nurseCatalog': true,
          'desc':
              'Consumabile: cura HP spendendo Oculum o le statistiche previste.',
        },
        <String, dynamic>{
          'id': 'nurse_vitalium_refined',
          'name': 'Vitalium Ridefinito',
          'kind': 'refined_vitalium',
          'cost': 180,
          'nurseCatalog': true,
          'desc':
              'Consumabile: ripristina HP, statistiche attuali e integrità delle Art.',
        },
        <String, dynamic>{
          'id': 'nurse_debuff_cleanser',
          'name': 'Fiala Depurante Eroica',
          'kind': 'food',
          'cost': 30,
          'nurseCatalog': true,
          'cleanseNegativeConditions': true,
          'desc': 'Consumabile: rimuove le condizioni negative attive.',
        },
      ]);
    }
  }

  void ensureBlackMarketOffers() {
    final profile = _activeMerchantProfile();
    if (readBoolValue(profile['blackMarketOffersRolled'])) return;

    final random = Random(
      monsterSpriteStableSeed('$merchantActiveProfileId:black_market'),
    );
    final ownerLevel = max(0, leggiNumero(livelloController)).toInt();
    final ownerGrade = max(
      0,
      leggiNumero(gradoController),
    ).clamp(0, 12).toInt();
    final existingKeys = merchantStock
        .map(oculumMerchantCanonicalOfferKey)
        .whereType<String>()
        .toSet();
    void addUnique(Map<String, dynamic> offer) {
      final key = oculumMerchantCanonicalOfferKey(offer);
      if (key != null && !existingKeys.add(key)) return;
      if (!merchantStock.any((item) => item['id'] == offer['id'])) {
        merchantStock.add(offer);
      }
    }

    final artCandidates =
        monsterBookEntries
            .where(
              (monster) =>
                  !monster.isNpc &&
                  oculumMonsterHasOculumArt(monster) &&
                  oculumMonsterBookImportArt(monster) != null,
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    artCandidates.shuffle(random);
    var addedArts = 0;
    for (final monster in artCandidates) {
      if (addedArts >= 2) break;
      final imported = oculumMonsterBookImportArt(monster);
      if (imported == null) continue;
      final sourceArtKey = oculumMonsterBookSkillBaseId(monster.id);
      final marker = 'oculum_market_art:$sourceArtKey';
      if (arti.any((art) => art.descrizione.contains(marker))) continue;
      final offer = <String, dynamic>{
        'id': 'black_market_monster_art_$sourceArtKey',
        'kind': 'black_market_monster_art',
        'sourceMonsterId': monster.id,
        'sourceArtKey': sourceArtKey,
        'canonicalArtName': imported.nome,
        'requiredLevel': ownerLevel,
        'cost': 14000 + ownerLevel * 500 + ownerGrade * 1200,
        'remaining': 1,
        'name': 'Art Oculum Nera · ${monster.nameIt} · ${imported.nome}',
        'desc':
            'Art Oculum importata dal Monster Book di ${monster.nameIt}. Requisito: livello $ownerLevel. Forme, effetti e costi restano modificabili nell’editor Art. ($marker)',
      };
      final priorCount = merchantStock.length;
      addUnique(offer);
      if (merchantStock.length > priorCount) addedArts++;
    }

    final skillCandidates =
        <
          ({
            MonsterBookEntry monster,
            String id,
            CharacterSkill skill,
            int sourceLevel,
          })
        >[];
    final seenSkillIds = <String>{};
    for (final monster in monsterBookEntries.where((entry) => !entry.isNpc)) {
      final art = oculumMonsterBookArt(monster);
      final ids = monsterBookUsableSkillIds(monster);
      for (var index = 0; index < min(ids.length, art.skills.length); index++) {
        final sourceId = ids[index];
        if (!oculumMonsterTechniqueIsNatural(monster, sourceId)) continue;
        final baseId = oculumMonsterBookSkillBaseId(sourceId);
        if (!seenSkillIds.add(baseId)) continue;
        final skill = _naturalMonsterSkill(
          monster,
          sourceId,
          art.skills[index],
        );
        final sourceLevel = max(
          0,
          monsterBookConcreteTechnique(sourceId)?.requiredLevel ?? 0,
        );
        if (sourceLevel <= ownerLevel + 2 &&
            !skills.any((owned) => owned.nome == skill.nome)) {
          skillCandidates.add((
            monster: monster,
            id: sourceId,
            skill: skill,
            sourceLevel: sourceLevel,
          ));
        }
      }
    }
    skillCandidates.sort((a, b) => a.id.compareTo(b.id));
    skillCandidates.shuffle(random);
    var addedSkills = 0;
    for (final candidate in skillCandidates) {
      if (addedSkills >= 3) break;
      final requiredLevel = min(
        ownerLevel + 2,
        max(ownerLevel, candidate.sourceLevel) + random.nextInt(3),
      );
      final marker =
          'black_market_source_skill:${oculumMonsterBookSkillBaseId(candidate.id)}';
      if (skills.any(
        (skill) =>
            skill.descrizione.contains(marker) ||
            skill.forme.any((form) => form.note.contains(marker)),
      )) {
        continue;
      }
      final offer = <String, dynamic>{
        'id':
            'black_market_monster_skill_${oculumMonsterBookSkillBaseId(candidate.id)}',
        'kind': 'black_market_monster_skill',
        'sourceMonsterId': candidate.monster.id,
        'sourceSkillId': candidate.id,
        'canonicalSkillName': candidate.skill.nome,
        'requiredLevel': requiredLevel,
        'cost': 7500 + requiredLevel * 900 + ownerGrade * 400,
        'remaining': 1,
        'name': 'Skill Nera · ${candidate.skill.nome}',
        'desc':
            'Tecnica del Monster Book di ${candidate.monster.nameIt}. Richiede livello $requiredLevel; le forme successive sbloccano ogni tre livelli. Abilità e costi si modificano nell’editor Skill. ($marker)',
      };
      final priorCount = merchantStock.length;
      addUnique(offer);
      if (merchantStock.length > priorCount) addedSkills++;
    }

    final weaponCandidates =
        monsterBookEntries
            .where((monster) => !monster.isNpc)
            .map(
              (monster) => (
                monster: monster,
                items: oculumMonsterEquipmentCatalogue(
                  source: monster,
                  level: ownerLevel,
                  grade: ownerGrade,
                ).where((item) => item.arma).toList(),
              ),
            )
            .where((entry) => entry.items.isNotEmpty)
            .toList()
          ..sort((a, b) => a.monster.id.compareTo(b.monster.id));
    weaponCandidates.shuffle(random);
    for (final candidate in weaponCandidates) {
      final item = candidate.items.first;
      final itemId = '${item.monsterLoot['id'] ?? ''}';
      final sourceSkillId = '${item.craftData['sourceSkillId'] ?? ''}';
      if (itemId.isEmpty || sourceSkillId.isEmpty) continue;
      final alreadyOwned = inventario.any(
        (owned) => '${owned.monsterLoot['id'] ?? ''}' == itemId,
      );
      if (alreadyOwned) continue;
      addUnique(<String, dynamic>{
        'id': 'black_market_monster_weapon_$itemId',
        'kind': 'black_market_monster_weapon',
        'sourceMonsterId': candidate.monster.id,
        'sourceSkillId': sourceSkillId,
        'itemId': itemId,
        'canonicalItemName': item.nome,
        'itemFamily': 'weapon',
        'requiredLevel': ownerLevel,
        'level': ownerLevel,
        'grade': ownerGrade,
        'cost': 2500 + ownerLevel * 250 + ownerGrade * 900,
        'remaining': 1,
        'name': 'Arma del Mostro · ${item.nome}',
        'desc':
            'Reliquia d’arma di ${candidate.monster.nameIt}, livello $ownerLevel e Grado $ownerGrade. La Skill collegata richiede il livello indicato e resta modificabile nell’editor equipaggiamento.',
      });
      break;
    }

    final ownerStats = <String, int>{
      'resilienza': max(0, resilienzaTotale()),
      'volonta': max(0, volontaTotale()),
      'materia': max(0, materiaTotale()),
      'oculum': max(0, oculumTotale()),
    };
    final ownerStatTotal = ownerStats.values.fold<int>(0, (a, b) => a + b);
    if (ownerStatTotal > 0) {
      final eyeCandidates =
          monsterBookEntries.where((monster) => !monster.isNpc).toList()
            ..sort((a, b) => a.id.compareTo(b.id));
      eyeCandidates.shuffle(random);
      for (final monster in eyeCandidates) {
        final source = _fallenEyeSourceFromMonsterBook(
          monster,
          name: 'Occhio dei Caduti | ${monster.nameIt} lvl $ownerLevel',
          level: ownerLevel,
        );
        final rawStats = <String, int>{
          for (final key in ownerStats.keys)
            key: max(0, readIntValue(source[key])),
        };
        final rawTotal = rawStats.values.fold<int>(0, (a, b) => a + b);
        final statCeiling = ownerStatTotal + max(2, ownerStatTotal ~/ 10);
        if (rawTotal > statCeiling) {
          source['blackMarketOriginalStats'] = Map<String, int>.from(rawStats);
          final scale = statCeiling / rawTotal;
          final capped = <String, int>{
            for (final key in rawStats.keys)
              key: (rawStats[key]! * scale).floor(),
          };
          if (statCeiling > 0 && capped['resilienza'] == 0) {
            capped['resilienza'] = 1;
          }
          while (capped.values.fold<int>(0, (a, b) => a + b) > statCeiling) {
            final highest = capped.keys
                .where((key) => key != 'resilienza' || capped[key]! > 1)
                .reduce((a, b) => capped[a]! >= capped[b]! ? a : b);
            capped[highest] = capped[highest]! - 1;
          }
          for (final entry in capped.entries) {
            source[entry.key] = '${entry.value}';
            source['current${entry.key[0].toUpperCase()}${entry.key.substring(1)}'] =
                '${entry.value}';
          }
          source['monsterBaseStats'] = capped;
          source['fallenEyeLevelStatBonuses'] = <String, int>{
            for (final key in capped.keys) key: 0,
          };
          source['currentHp'] =
              '${max(1, capped['resilienza']! * (10 + oculumGradeForLevel(ownerLevel) * 5))}';
          source['blackMarketStatsCapped'] = true;
        }
        final totalStats = ownerStats.keys.fold<int>(
          0,
          (sum, key) => sum + max(0, readIntValue(source[key])),
        );
        final levelZeroBase = 36 + random.nextInt(34);
        final eyeBasePrice = oculumBlackMarketFallenEyeBasePrice(
          level: ownerLevel,
          levelZeroBase: levelZeroBase,
        );
        final offer = <String, dynamic>{
          'id': 'black_market_fallen_eye_${monster.id}_$ownerLevel',
          'kind': 'black_market_fallen_eye',
          'sourceMonsterId': monster.id,
          'requiredLevel': ownerLevel,
          'level': ownerLevel,
          'grade': oculumGradeForLevel(ownerLevel),
          'priceFormulaVersion': 2,
          'levelZeroBase': levelZeroBase,
          'eyeBasePrice': eyeBasePrice,
          'ownerStatTotal': ownerStatTotal,
          'statUnitCost': 2,
          'surplusBlockSize': 20,
          'surplusPercentPerBlock': 25,
          'cost': oculumBlackMarketFallenEyePrice(
            totalStats: totalStats,
            level: ownerLevel,
            ownerTotalStats: ownerStatTotal,
            basePrice: eyeBasePrice,
          ),
          'remaining': 1,
          'name': '${source['nome'] ?? monster.nameIt}',
          'rarity': 'non_comune',
          'sourceSheet': source,
          'desc':
              'Mostro del Monster Book al tuo livello ($ownerLevel). Statistiche totali $totalStats, massimo consentito il tuo totale +10% (almeno 2 punti). Prezzo: base $eyeBasePrice + statistiche ×2; +25% ogni 20 statistiche oltre il tuo totale di $ownerStatTotal, arrotondato per eccesso. Base salvata per questa visita.',
        };
        final existingEye = occhiCaduti.any(
          (eye) =>
              '${eye['monsterBookSourceId'] ?? ''}' == monster.id &&
              readIntValue(eye['livello']) == ownerLevel,
        );
        if (!existingEye) addUnique(offer);
        if (oculumMerchantCanonicalOfferKey(offer) != null &&
            existingKeys.contains(oculumMerchantCanonicalOfferKey(offer))) {
          break;
        }
      }
    }

    final grade = max(0, leggiNumero(gradoController)).clamp(0, 12).toInt();
    final scrollCandidates =
        merchantStock
            .where(
              (offer) =>
                  offer['kind'] == 'technique_scroll' &&
                  readIntValue(offer['scrollGrade']) == grade,
            )
            .toList()
          ..sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
    scrollCandidates.shuffle(random);
    final selectedScrolls = <Map<String, dynamic>>[];
    final gratitude = scrollCandidates
        .where((offer) => offer['scrollProfileId'] == 'provi_gratitudine')
        .firstOrNull;
    if (gratitude != null && random.nextInt(100) < 60) {
      selectedScrolls.add(gratitude);
    }
    for (final offer in scrollCandidates) {
      if (selectedScrolls.length >= 2) break;
      if (!selectedScrolls.contains(offer)) selectedScrolls.add(offer);
    }
    for (final offer in selectedScrolls) {
      offer['blackMarketSelected'] = true;
      offer['remaining'] = 1;
    }

    profile['blackMarketOffersRolled'] = true;
    _saveActiveMerchantProfileStock();
  }

  void ensureMerchantFoodOffers() {
    ensureSmokingHerbsOffer();
    for (final offer in oculumCreatureCoreOffers()) {
      if (!merchantStock.any((existing) => existing['id'] == offer['id'])) {
        merchantStock.add(offer);
      }
    }
    if (!merchantStock.any((offer) => offer['id'] == 'pawn')) {
      merchantStock.add(oculumPawnMerchantOffer());
    }
    final foods = <Map<String, dynamic>>[
      {
        'id': 'food_forest_demon',
        'learnMonsterId': 'forest_demon',
        'name': 'Carne di Forest Demon',
        'cost': 12,
        'volonta': 2,
        'materia': 1,
      },
      {
        'id': 'food_mammuth',
        'learnMonsterId':
            defaultMonsterBookEntries
                .where((m) => m.nameIt.toLowerCase().contains('mammuth'))
                .firstOrNull
                ?.id ??
            '',
        'name': 'Carne cotta di Mammuth',
        'cost': 15,
        'resilienza': 2,
        'materia': 1,
      },
      {
        'id': 'food_patalpa',
        'name': 'Patalpa Dolce',
        'cost': 10,
        'resilienza': 1,
        'volonta': 1,
        'materia': 1,
        'oculum': 1,
        'isMaterial': true,
      },
      {
        'id': 'herb_lunar',
        'name': 'Erba Lunare',
        'cost': 8,
        'oculum': 2,
        'volonta': 1,
        'isMaterial': true,
      },
      {
        'id': 'herb_iron',
        'name': 'Erba di Ferro',
        'cost': 8,
        'resilienza': 2,
        'materia': 1,
        'isMaterial': true,
      },
      {
        'id': 'herb_fourfold_root',
        'name': 'Radice delle Quattro Vene',
        'cost': 42,
        'restoreAllStats': true,
        'isMaterial': true,
        'desc':
            'Ripristina Resilienza, Volontà, Materia e Oculum attuali fino ai massimali della scheda. Non assegna Oculum a chi non lo possiede.',
      },
      {
        'id': 'ointment_millefoglie',
        'name': 'Unguento di Millefoglie',
        'cost': 30,
        'healHpPercent': 25,
        'cleanseNegativeConditions': true,
        'isMaterial': true,
        'desc':
            'Cura HP pari al 25% del massimale e rimuove le condizioni negative attive.',
      },
      {
        'id': 'balm_blue_bark',
        'name': 'Balsamo di Corteccia Azzurra',
        'cost': 24,
        'resistanceElement': 'ghiaccio',
        'resistancePreset': 'Resistenza',
        'condition': 'fortificato',
        'isMaterial': true,
        'desc':
            'Resistenza al Ghiaccio e Fortificato fino al Riposo Lungo o dopo 2 Riposi Brevi.',
      },
      {
        'id': 'pollen_reflexes',
        'name': 'Polline dei Riflessi',
        'cost': 18,
        'subtraitId': 'riflessi',
        'subtraitBonus': 2,
        'isMaterial': true,
        'desc':
            'Materiale da crafting utilizzabile: +2 Riflessi fino al Riposo Lungo o dopo 2 Riposi Brevi.',
      },
      {
        'id': 'ointment_focus',
        'name': 'Unguento della Concentrazione',
        'cost': 20,
        'subtraitId': 'concentrazione',
        'subtraitBonus': 2,
        'condition': 'concentrato',
        'isMaterial': true,
        'desc':
            'Materiale da crafting utilizzabile: +2 Concentrazione e Concentrato fino al Riposo Lungo o dopo 2 Riposi Brevi.',
      },
      {
        'id': 'alcohol_ash',
        'name': 'Liquore di Cenere',
        'cost': 6,
        'volonta': -2,
        'materia': 1,
        'oculum': 1,
        'alcohol': true,
      },
    ];
    final grade = max(0, leggiNumero(gradoController)).clamp(0, 12);
    final profiles = oculumTechniqueScrolls.take(8).toList();
    for (final profile in profiles) {
      final id = 'alchemist_scroll_${profile.id}_$grade';
      if (!merchantStock.any((o) => o['id'] == id)) {
        merchantStock.add({
          'id': id,
          'kind': 'technique_scroll',
          'name': 'Pergamena ${profile.name} · Grado $grade',
          'cost': oculumScrollValue(grade),
          'scrollProfileId': profile.id,
          'scrollGrade': grade,
          'desc':
              'Monouso. Costo ${oculumScrollWillCost(grade)} Volontà, CD ${oculumScrollCooldown(grade)} turni, DT ${oculumScrollDifficulty(grade)}. Apprendimento raro secondo difficoltà.',
        });
      }
    }
    if (const {'alchimista', 'mercato_nero'}.contains(merchantShopType)) {
      final profileId = 'provi_gratitudine';
      final id = 'alchemist_scroll_${profileId}_$grade';
      if (!merchantStock.any((offer) => offer['id'] == id)) {
        merchantStock.add({
          'id': id,
          'kind': 'technique_scroll',
          'name': 'Pergamena Reazione Fulminea · Grado $grade',
          'cost': oculumScrollValue(grade),
          'scrollProfileId': profileId,
          'scrollGrade': grade,
          'desc':
              'Scroll di utility: una Reazione Fulminea e +${oculumGratitudineNextActionBonus(grade)} alla prossima azione per ogni partecipante selezionato. Costo ${oculumScrollWillCost(grade)} Volontà; apprendimento con 20 naturale.',
        });
      }
    }
    if (!merchantStock.any((offer) => offer['id'] == 'summoning_emblem')) {
      merchantStock.add(oculumSummoningEmblemOffer());
    }
    for (final pet in oculumAlchemyPets) {
      if (!merchantStock.any((o) => o['id'] == 'pet_${pet.$1}')) {
        merchantStock.add({
          'id': 'pet_${pet.$1}',
          'kind': 'alchemy_pet',
          'petId': pet.$1,
          'name': pet.$2,
          'cost': 120,
          'desc':
              '${pet.$3} Grado 0; supporto 1 Volontà, CD 3 turni. Crea una scheda alleata modificabile.',
        });
      }
    }
    final extendedFoods = <Map<String, dynamic>>[
      ...foods,
      for (final spec in [
        ('resilienza', 'Zuppa di radici ferrigne'),
        ('volonta', 'Stufato di brace'),
        ('materia', 'Brodo di scaglie minerali'),
        ('oculum', 'Infuso di fiori spirituali'),
        ('tutte', 'Banchetto delle Quattro Vene'),
      ])
        for (var stage = 1; stage <= 6; stage++)
          {
            'id': 'meal_${spec.$1}_$stage',
            'name':
                '${spec.$2} ${['I', 'II', 'III', 'IV', 'V', 'VI'][stage - 1]}',
            'cost': stage * stage * (spec.$1 == 'tutte' ? 18 : 8),
            'condition': 'nutrito_${spec.$1}',
            'conditionStage': stage,
            'conditionTurns': 3,
            'desc':
                '+${stage * 2}% ${spec.$1}, 3 turni. Versioni dello stesso buff non cumulative. Valori modificabili nelle condizioni.',
          },
      ...<Map<String, dynamic>>[
        {
          'id': 'meal_vital_memory',
          'name': 'Bistecca del Ricordo Vitale',
          'cost': 38,
          'condition': 'ricordo_vitale',
          'conditionTurns': 3,
          'desc':
              'Ricordo Vitale per 3 turni: il personaggio subisce più danni, ma recupera parte dei danni HP ricevuti secondo la condizione.',
        },
        {
          'id': 'drink_blood_vitality_i',
          'name': 'Infuso Ematico · I',
          'cost': 46,
          'condition': 'vampirismo',
          'conditionStage': 1,
          'conditionTurns': 3,
          'desc':
              'Vampirismo I per 3 turni. Effetto configurabile nella condizione.',
        },
        {
          'id': 'drink_blood_vitality_ii',
          'name': 'Infuso Ematico · II',
          'cost': 78,
          'condition': 'vampirismo',
          'conditionStage': 2,
          'conditionTurns': 3,
          'desc':
              'Vampirismo II per 3 turni. Effetto configurabile nella condizione.',
        },
        {
          'id': 'drink_blood_vitality_iii',
          'name': 'Infuso Ematico · III',
          'cost': 124,
          'condition': 'vampirismo',
          'conditionStage': 3,
          'conditionTurns': 3,
          'desc':
              'Vampirismo III per 3 turni. Effetto configurabile nella condizione.',
        },
        {
          'id': 'meal_hunters_fervor',
          'name': 'Arrosto del Cacciatore Cremisi',
          'cost': 72,
          'damagePercent': 30,
          'conditionTurns': 3,
          'desc': '+30% Danni per 3 turni di combattimento.',
        },
        {
          'id': 'meal_rune_bastion',
          'name': 'Brodo del Bastione Runico',
          'cost': 68,
          'defensePercent': 20,
          'conditionTurns': 3,
          'desc': '+20% Difesa per 3 turni di combattimento.',
        },
        {
          'id': 'drink_clear_veil',
          'name': 'Tisana della Soglia Trasparente',
          'cost': 58,
          'condition': 'trasparenza',
          'conditionTurns': 3,
          'desc': 'Trasparenza per 3 turni: Velo +6 + livello.',
        },
        {
          'id': 'drink_invisibility',
          'name': 'Elisir dell’Assenza',
          'cost': 116,
          'condition': 'invisibile',
          'conditionTurns': 3,
          'desc': 'Invisibilità per 3 turni: Velo +18 + livello.',
        },
        {
          'id': 'drink_quickstep',
          'name': 'Liquore del Passo Cavo',
          'cost': 44,
          'condition': 'accelerato',
          'conditionTurns': 3,
          'desc':
              'Accelerato per 3 turni. Effetto configurabile nella condizione.',
        },
        {
          'id': 'drink_focus',
          'name': 'Tè delle Quattro Lenti',
          'cost': 42,
          'condition': 'concentrato',
          'conditionTurns': 3,
          'desc':
              'Concentrato per 3 turni. Effetto configurabile nella condizione.',
        },
        {
          'id': 'meal_fortified',
          'name': 'Stufato della Muraglia Viva',
          'cost': 52,
          'condition': 'fortificato',
          'conditionTurns': 3,
          'desc': 'Fortificato per 3 turni: Difesa +15% (minimo +1).',
        },
        {
          'id': 'meal_fourfold_feast',
          'name': 'Banchetto delle Quattro Vene',
          'cost': 90,
          'resilienza': 2,
          'volonta': 2,
          'materia': 2,
          'oculum': 2,
          'desc':
              'Bonus consumabile alle quattro statistiche fino al prossimo riposo.',
        },
        {
          'id': 'meal_sunroot',
          'name': 'Radici Dorate al Miele',
          'cost': 34,
          'resilienza': 3,
          'materia': 1,
        },
        {
          'id': 'meal_moonfish',
          'name': 'Pesce Lunare in Crosta',
          'cost': 36,
          'volonta': 3,
          'oculum': 1,
        },
        {
          'id': 'drink_star_anise',
          'name': 'Cordiale di Anice Stellare',
          'cost': 31,
          'materia': 2,
          'oculum': 1,
        },
        {
          'id': 'drink_mineral_spring',
          'name': 'Acqua della Sorgente Minerale',
          'cost': 24,
          'resilienza': 1,
          'materia': 2,
        },
        {
          'id': 'meal_red_fungus',
          'name': 'Fungo Rosso alla Brace',
          'cost': 28,
          'volonta': 2,
          'materia': 1,
        },
        {
          'id': 'meal_cloudbread',
          'name': 'Pane di Nuvola Salata',
          'cost': 26,
          'resilienza': 2,
          'volonta': 1,
        },
      ],
    ];
    for (final food in extendedFoods) {
      Map<String, dynamic>? existing;
      for (final candidate in merchantStock) {
        if (candidate['id'] == food['id']) {
          existing = candidate;
          break;
        }
      }
      final offer = existing ?? <String, dynamic>{};
      if (existing == null) {
        offer.addAll(food);
        offer['kind'] = 'food';
        offer['desc'] = merchantFoodOfferDescription(food);
        merchantStock.add(offer);
      } else {
        for (final entry in food.entries) {
          offer.putIfAbsent(entry.key, () => entry.value);
        }
        offer.putIfAbsent('kind', () => 'food');
        offer.putIfAbsent('desc', () => merchantFoodOfferDescription(offer));
      }
    }
  }

  void addAlchemyFallenEyeOffers(Random random) {
    final ownerLevel = max(0, leggiNumero(livelloController)).toInt();
    final ownerGrade = max(
      0,
      leggiNumero(gradoController),
    ).clamp(0, 12).toInt();
    final ownerStats = <String, int>{
      'resilienza': max(0, leggiNumero(resilienzaController)),
      'volonta': max(0, leggiNumero(volontaController)),
      'materia': max(0, leggiNumero(materiaController)),
      'oculum': max(0, leggiNumero(oculumController)),
    };
    final ownerTotal = ownerStats.values.fold<int>(0, (a, b) => a + b);
    if (ownerTotal <= 0) return;
    final half = ownerTotal / 2;
    final candidates = defaultMonsterBookEntries
        .where((monster) => !monster.isNpc)
        .map((monster) {
          final stats = oculumMonsterCreationStats(monster, 0);
          final total = stats.values.fold<int>(
            0,
            (a, b) => a + max(0, b).toInt(),
          );
          return (monster: monster, stats: stats, total: total);
        })
        .where((entry) => entry.total > 0 && entry.total <= ownerTotal)
        .toList();
    if (candidates.isEmpty) return;
    final nearHalf = candidates
        .where((entry) => (entry.total - half).abs() <= max(2, half * .2))
        .toList();
    final pool = nearHalf.isNotEmpty
        ? nearHalf
        : (candidates..sort(
                (a, b) =>
                    (a.total - half).abs().compareTo((b.total - half).abs()),
              ))
              .take(min(5, candidates.length))
              .toList();
    if (random.nextInt(100) < 20) {
      final selected = pool[random.nextInt(pool.length)];
      final creatureLevel = oculumAlchemyMediumFallenEyeLevel(ownerLevel);
      final offerName =
          'Occhio dei Caduti | ${selected.monster.nameIt} lvl $creatureLevel';
      final source = _fallenEyeSourceFromMonsterBook(
        selected.monster,
        name: offerName,
        level: creatureLevel,
      );
      merchantStock.add({
        'id': 'alchemy_fallen_eye_medium_${random.nextInt(1 << 31)}',
        'kind': 'fallen_eye',
        'tier': 'medio_raro',
        'remaining': 1,
        'name': offerName,
        'rarity': 'non_comune',
        'sourceMonsterId': selected.monster.id,
        'sourceBaseStatTotal': selected.total,
        'level': 0,
        'grade': ownerGrade,
        'cost': oculumAlchemyMediumFallenEyePrice(
          ownerLevel: ownerLevel,
          ownerGrade: ownerGrade,
          priceRoll: random.nextInt(34),
        ),
        'sourceSheet': source,
        'desc':
            'Medio raro. Creatura casuale di livello $creatureLevel (circa un terzo sotto il tuo, minimo 0), con statistiche base vicine alla metà delle tue e mai superiori al tuo totale. Prezzo: 56–89 + tuo livello + Grado ×3 Obser.',
      });
    }
    if (random.nextInt(100) < 5) {
      final selected = pool[random.nextInt(pool.length)];
      final creatureLevel = oculumAlchemyRareFallenEyeLevel(ownerLevel);
      final offerName =
          'Occhio dei Caduti | ${selected.monster.nameIt} lvl $creatureLevel · Raro';
      final source = _fallenEyeSourceFromMonsterBook(
        selected.monster,
        name: offerName,
        level: creatureLevel,
      );
      final sheet = Map<String, dynamic>.from(source);
      final combinedStats = <String, int>{
        for (final key in ownerStats.keys)
          key: ownerStats[key]! + max(0, selected.stats[key] ?? 0).toInt(),
      };
      for (final entry in combinedStats.entries) {
        sheet[entry.key] = '${entry.value}';
        sheet['current${entry.key[0].toUpperCase()}${entry.key.substring(1)}'] =
            '${entry.value}';
      }
      sheet['monsterBaseStats'] = selected.stats;
      sheet['currentHp'] = '${oculumSheetHpMaximum(sheet)}';
      merchantStock.add({
        'id': 'alchemy_fallen_eye_rare_${random.nextInt(1 << 31)}',
        'kind': 'fallen_eye',
        'tier': 'raro',
        'remaining': 1,
        'name': offerName,
        'rarity': 'raro',
        'sourceMonsterId': selected.monster.id,
        'sourceBaseStatTotal': selected.total,
        'level': 0,
        'grade': ownerGrade,
        'cost': oculumAlchemyRareFallenEyePrice(
          ownerLevel: ownerLevel,
          ownerGrade: ownerGrade,
          priceRoll: random.nextInt(221),
        ),
        'sourceSheet': sheet,
        'desc':
            'Raro. Livello creatura pari a metà del tuo, arrotondato per eccesso. Le statistiche sommano le tue statistiche base e quelle base della creatura; la creatura scelta resta sotto il tuo totale e vicina alla metà. Prezzo: 230–450 + metà tuo livello + Grado ×4 Obser.',
      });
    }
  }

  String merchantFoodOfferDescription(Map<String, dynamic> food) {
    final authored = '${food['desc'] ?? ''}'.trim();
    if (authored.isNotEmpty) return authored;
    final effect = food['isMaterial'] == true
        ? 'Materiale da crafting utilizzabile dall’inventario: gli effetti durano fino al Riposo Lungo o dopo 2 Riposi Brevi.'
        : food['alcohol'] == true
        ? 'Alcolico: ogni dose somma il malus di Volontà e i bonus fino al prossimo riposo.'
        : 'Cibo consumabile: bonus fino al prossimo riposo.';
    final bonuses = ['resilienza', 'volonta', 'materia', 'oculum']
        .where(food.containsKey)
        .map(
          (key) =>
              '$key ${readIntValue(food[key]) >= 0 ? '+' : ''}${food[key]}',
        )
        .join(', ');
    return '$effect${bonuses.isEmpty ? '' : ' $bonuses.'}';
  }

  String merchantOfferDescription(Map<String, dynamic> offer) {
    if ('${offer['kind'] ?? ''}'.startsWith('black_market_') &&
        offer['kind'] != 'black_market_ascension_dust') {
      final requiredLevel = max(0, readIntValue(offer['requiredLevel']));
      return '${readIntValue(offer['remaining'], fallback: 1) > 0 ? 'Disponibile: 1' : 'Esaurito'} · Richiede livello $requiredLevel. ${offer['desc'] ?? ''}';
    }
    if (offer['kind'] == 'black_market_ascension_dust') {
      return merchantDustPurchaseCount >= 3
          ? 'Limite raggiunto: $merchantDustPurchaseCount/3. Disponibile dopo il Riposo Lungo. ${offer['desc'] ?? ''}'
          : 'Acquistate: $merchantDustPurchaseCount/3 · prossimo prezzo ${merchantOfferCost(offer)} Obser. ${offer['desc'] ?? ''}';
    }
    if (offer['kind'] == 'nurse_service' && offer['service'] == 'full') {
      final percent = readIntValue(
        offer['buffPercent'],
        fallback: 10,
      ).clamp(10, 60).toInt();
      final duration = oculumNurseBuffDuration(normalizedCampaignDifficulty());
      final jackpot = percent >= 40;
      final shieldDenominator = max(
        1,
        readIntValue(offer['jackpotShieldHpFractionDenominator'], fallback: 4),
      );
      return 'Refull: ripristina HP, statistiche attuali, Oculum, Scudo Oculum esistente e integrità Art; rimuove i debuff. Prezzo variabile sulle risorse ripristinate, sconto 15%, più ${oculumNurseBuffSurcharge(percent)} Obser per il buff. Prossima battaglia: +$percent% Danni e Difesa per $duration turni (${campaignDifficultyLabel()}).${jackpot ? ' Estrazione rara: anche +${maxHp() ~/ shieldDenominator} Scudo gratuito.' : ''} Ogni tanto può aggiungere HP temporanei.';
    }
    if (offer['kind'] == 'fallen_eye') {
      final availability = readIntValue(offer['remaining'], fallback: 1) > 0
          ? 'Disponibile: 1'
          : 'Esaurito';
      return '$availability · ${offer['desc']}';
    }
    if (const {'fate_sign', 'chaos_sign'}.contains(offer['kind'])) {
      return '${readIntValue(offer['remaining'], fallback: 1) > 0 ? 'Disponibile: 1' : 'Esaurito'} · ${offer['desc']}';
    }
    if (offer['kind'] == 'stat_gem') {
      final stat = '${offer['stat']}';
      final faces = readIntValue(offer['dieFaces'], fallback: 1);
      return '${readIntValue(offer['remaining']) > 0 ? 'Disponibile: 1' : 'Esaurita'} · Consumabile: recupera punti attuali di ${oculumStatGemNames[stat]?.replaceFirst('Gemma di ', '') ?? stat} di 1d$faces. Eccesso fino al riposo lungo. Potenza fissata all acquisto. Prezzo: 3 Obser +3 ogni 10 punti di questa statistica.';
    }
    if ('${offer['kind'] ?? ''}' == 'raw_vitalium') {
      return 'Consumabile: scegli quanto Oculum immettere; recuperi altrettanti HP. Se non hai Oculum, paghi 2 Materia e 2 Volontà per punto. ${oculumRawVitaliumRuleForGrade(max(0, leggiNumero(gradoController)))}';
    }
    if ('${offer['kind'] ?? ''}' == 'title_item') {
      final level = max(0, readIntValue(offer['level']));
      final grade = max(0, readIntValue(offer['grade']));
      return '${offer['desc'] ?? ''}\nLivello oggetto: $level · Grado richiesto per acquistare/equipaggiare: $grade. La skill dell’oggetto scelto si sblocca al livello $level (o al livello più alto indicato dalla forma).';
    }
    if ('${offer['kind'] ?? ''}' == 'gear') {
      final grade = readIntValue(offer['grade']);
      final level = max(0, readIntValue(offer['level']));
      final ability = oculumEquipmentAbility('${offer['name']}', grade);
      final skill = ability.forme.first;
      return '${offer['desc'] ?? ''}\nLivello oggetto: $level · Grado richiesto per acquistare/equipaggiare: ${max(0, grade)}. +${(1 + max(0, grade) ~/ 4).clamp(1, 3)} punti statistica per livello. La skill dell’oggetto si sblocca al livello $level (o al livello più alto indicato dalla forma).\n${ability.nome}: ${skill.descrizione} · ${skill.costo} · CD ${skill.cooldown}';
    }
    return '${offer['desc'] ?? ''}';
  }

  bool merchantOfferUnavailable(Map<String, dynamic> offer) {
    if (offer['kind'] == 'black_market_ascension_dust') {
      return merchantDustPurchaseCount >=
          readIntValue(offer['purchaseLimit'], fallback: 3);
    }
    if (offer['kind'] == 'monster_book_page' &&
        monsterBookPartyKnowledge(
              '${offer['monsterBookId'] ?? ''}',
            )?['pagePurchased'] ==
            true) {
      return true;
    }
    return offer.containsKey('remaining') &&
        readIntValue(offer['remaining'], fallback: 1) <= 0;
  }

  bool merchantServiceHasEffect(Map<String, dynamic> offer) {
    if (offer['kind'] != 'nurse_service') return true;
    return switch ('${offer['service'] ?? ''}') {
      'hp' => hpCorrenti() < maxHp(),
      'oculum_shield' => scudoOculum() < scudoOculumMax(),
      'will' => currentVolonta() < currentStatNaturalControllerMax('volonta'),
      'matter' => currentMateria() < currentStatNaturalControllerMax('materia'),
      'temp_hp' => hpTemp() < thresholdTemporaryHpLimit(),
      'oculum' => oculumTotale() < oculumMassimo(),
      'full' => true,
      _ => true,
    };
  }

  void _rollNurseRefillBuffForShopOpen() {
    if (merchantShopType != 'infermiera_eroica') return;
    final offer = merchantStock
        .where(
          (item) =>
              item['kind'] == 'nurse_service' && item['service'] == 'full',
        )
        .firstOrNull;
    if (offer == null) return;
    final random = Random.secure();
    offer['buffPercent'] = oculumNurseBuffPercentFromRoll(
      percentileRoll: random.nextInt(100),
      selectionRoll: random.nextInt(100),
      jackpotChancePercent: readIntValue(
        offer['rareBuffJackpotChancePercent'],
        fallback: 1,
      ),
      jackpotValues:
          (offer['rareBuffValues'] as List? ?? const <dynamic>[40, 60])
              .map((value) => readIntValue(value))
              .toList(),
      standardValues:
          (offer['standardBuffPercents'] as List? ??
                  oculumNurseStandardBuffPercents)
              .map((value) => readIntValue(value))
              .toList(),
    );
    offer['buffRolledAt'] = DateTime.now().toIso8601String();
    _saveActiveMerchantProfileStock();
    programmaSalvataggio(invalidateCaches: false);
  }

  CharacterSkill merchantWeaponSkill(InventoryItem item) {
    final grade = max(item.gradoOggetto, item.gradoRichiesto);
    final name = oculumMerchantWeaponSkillName(item.nome);
    final text = oculumMerchantWeaponSkillText(item.nome, grade);
    return CharacterSkill(
      nome: name,
      tipo: 'Skill arma del Negoziante',
      costo: '1 azione',
      cooldown: 'Recupero dopo 4 usi',
      descrizione: text,
      danni: oculumMerchantWeaponSkillDamage(grade),
      equipaggiata: true,
      forme: <CharacterSkillForm>[
        CharacterSkillForm(
          nome: 'Forma I',
          tipo: 'Skill arma del Negoziante',
          costo: '1 azione',
          cooldown: 'Recupero dopo 4 usi',
          descrizione: text,
        ),
      ],
    );
  }

  Widget merchantQuickPanel() {
    final stock = recommendedMerchantStock();
    return gothicPanel(
      borderColor: tertiaryColor.withValues(alpha: .7),
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedBackgroundColor: const Color(0xFF151019),
          backgroundColor: const Color(0xFF0D1017),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onExpansionChanged: (open) {
            // ignore: invalid_use_of_protected_member
            setState(() => merchantIsOpen = open);
            if (open) {
              _rollNurseRefillBuffForShopOpen();
              // ignore: invalid_use_of_protected_member
              if (mounted) setState(() {});
            }
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFC4863C), Color(0xFF442315)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFFE6D8BD)),
            ),
            child: const Icon(Icons.storefront_outlined, color: Colors.white),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  activeMerchantName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
              ),
              Text(
                '${leggiNumero(obserController)} O',
                style: const TextStyle(
                  color: Color(0xFFFFD977),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          subtitle: Text(
            t(
              'Offerte secondo la tua Potenza totale · 6–9 scelte adatte a te, 16% di probabilità di trovarne 12.',
              'Offers suited to your total power · 6–9 choices, with a 16% chance of 12.',
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          children: [
            merchantProfileControls(),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed:
                    merchantDustPurchaseCount >= 3 ||
                        merchantShopType != 'alchimista' ||
                        leggiNumero(obserController) < merchantDustPrice
                    ? null
                    : buyAscensionDustFromMerchant,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(
                  merchantDustPurchaseCount >= 3
                      ? t(
                          'Dust acquistata · disponibile dopo il Riposo Lungo',
                          'Dust purchased · available after a Long Rest',
                        )
                      : t(
                          '$merchantDustPrice Obser → 1 Ascension Dust · $merchantDustPurchaseCount/3 per Riposo Lungo',
                          '$merchantDustPrice Obser → 1 Ascension Dust · $merchantDustPurchaseCount/3 per Long Rest',
                        ),
                ),
              ),
            ),
            for (final offer in stock)
              Container(
                margin: const EdgeInsets.only(top: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF18151C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: readIntValue(offer['grade']) > 0
                        ? const Color(0xFFFFC35B).withValues(alpha: .72)
                        : Colors.white24,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  title: Tooltip(
                    message: offer['kind'] == 'fallen_eye'
                        ? '${offer['name']}\n${merchantOfferDescription(offer)}'
                        : '${offer['name']}',
                    child: Text(
                      '${offer['name']}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  subtitle: Text(
                    '${merchantRecommendation(offer)}${merchantOfferDescription(offer)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  trailing: FilledButton(
                    onPressed:
                        merchantOfferUnavailable(offer) ||
                            !merchantServiceHasEffect(offer) ||
                            !oculumMerchantCanPurchaseOffer(
                              offer,
                              characterGrade: leggiNumero(gradoController),
                            ) ||
                            leggiNumero(obserController) <
                                merchantOfferCost(offer)
                        ? null
                        : () => buyMerchantOffer(offer),
                    child: Text(
                      oculumMerchantCanPurchaseOffer(
                            offer,
                            characterGrade: leggiNumero(gradoController),
                          )
                          ? '${merchantOfferCost(offer)} O'
                          : 'Grado ${readIntValue(offer['grade'])}',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> showMerchantDialog() async {
    final stock = recommendedMerchantStock();
    _rollNurseRefillBuffForShopOpen();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          backgroundColor: const Color(0xFF0D0C13),
          title: Text('Negoziante', style: TextStyle(color: tertiaryColor)),
          content: SizedBox(
            width: min(620, MediaQuery.sizeOf(context).width * .94),
            height: min(560, MediaQuery.sizeOf(context).height * .68),
            child: ListView.builder(
              itemCount: stock.length,
              itemBuilder: (context, index) {
                final offer = stock[index];
                final cost = merchantOfferCost(offer);
                return ListTile(
                  title: Tooltip(
                    message: offer['kind'] == 'fallen_eye'
                        ? '${offer['name']}\n${merchantOfferDescription(offer)}'
                        : '${offer['name']}',
                    child: Text(
                      '${offer['name']}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  subtitle: Text(
                    '${merchantRecommendation(offer)}${merchantOfferDescription(offer)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: FilledButton(
                    onPressed:
                        merchantOfferUnavailable(offer) ||
                            !merchantServiceHasEffect(offer) ||
                            !oculumMerchantCanPurchaseOffer(
                              offer,
                              characterGrade: leggiNumero(gradoController),
                            ) ||
                            leggiNumero(obserController) < cost
                        ? null
                        : () async {
                            await buyMerchantOffer(offer);
                            if (mounted) refresh(() {});
                          },
                    child: Text(
                      oculumMerchantCanPurchaseOffer(
                            offer,
                            characterGrade: leggiNumero(gradoController),
                          )
                          ? '$cost O'
                          : 'Grado ${readIntValue(offer['grade'])}',
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t('Chiudi', 'Close')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> buyMerchantOffer(Map<String, dynamic> offer) async {
    if (!oculumMerchantCanPurchaseOffer(
      offer,
      characterGrade: leggiNumero(gradoController),
    )) {
      aggiungiLog(
        'Grado insufficiente: ${offer['name']} richiede Grado ${readIntValue(offer['grade'])}.',
      );
      return;
    }
    if (merchantOfferUnavailable(offer)) return;
    if (offer['kind'] == 'stat_gem' ||
        offer['kind'] == 'fallen_eye' ||
        offer['kind'] == 'black_market_fallen_eye') {
      if (offer['kind'] == 'stat_gem') updateMerchantGemOffers();
      if (readIntValue(offer['remaining'], fallback: 1) <= 0) return;
    }
    final cost = merchantOfferCost(offer);
    if (cost <= 0) return;
    if (leggiNumero(obserController) < cost) return;
    final kind = '${offer['kind'] ?? ''}';
    if (kind == 'monster_book_page') {
      final monsterId = '${offer['monsterBookId'] ?? ''}'.trim();
      final monster = monsterBookEntryById(monsterId);
      if (monster == null ||
          monsterBookPartyKnowledge(monsterId)?['pagePurchased'] == true) {
        return;
      }
      // ignore: invalid_use_of_protected_member
      setState(() {
        obserController.text = (leggiNumero(obserController) - cost).toString();
        offer['remaining'] = 0;
        risultato =
            'Pagina Monster Book acquistata: ${monster.nameIt} · punto debole scoperto.';
        aggiungiLog(risultato);
      });
      // Share only the discovery marker and stable Monster Book id.
      rememberMonsterBookPartyDiscovery(
        monsterId,
        seen: true,
        weakPoint: true,
        pagePurchased: true,
        broadcast: true,
      );
      _saveActiveMerchantProfileStock();
      programmaSalvataggio();
      return;
    }
    if ((kind == 'fate_sign' ||
            kind == 'chaos_sign' ||
            kind == 'fallen_eye' ||
            kind == 'black_market_fallen_eye') &&
        readIntValue(offer['remaining'], fallback: 1) <= 0) {
      return;
    }
    if (kind == 'nurse_service') {
      _buyNurseService(offer, cost);
      return;
    }
    if (kind == 'technique_scroll' && offer['blackMarketSelected'] == true) {
      await _buyBlackMarketOffer(offer, cost);
      return;
    }
    if (kind.startsWith('black_market_')) {
      await _buyBlackMarketOffer(offer, cost);
      return;
    }
    if (kind == 'fallen_eye') {
      final source = offer['sourceSheet'];
      if (source is! Map || source.isEmpty) {
        aggiungiLog(
          'Questo Occhio dei Caduti non è disponibile: scheda sorgente mancante.',
        );
        return;
      }
      // ignore: invalid_use_of_protected_member
      setState(() {
        obserController.text = (leggiNumero(obserController) - cost).toString();
        offer['remaining'] = 0;
        risultato =
            'Alchimista: hai ottenuto ${offer['name']} per $cost Obser.';
        aggiungiLog(risultato);
      });
      _saveActiveMerchantProfileStock();
      programmaSalvataggio();
      await createFallenEyeFromSource(
        Map<String, dynamic>.from(source),
        name: '${offer['name'] ?? 'Occhio dei Caduti'}',
        rarity: '${offer['rarity'] ?? 'non_comune'}',
      );
      return;
    }
    String titleType = '';
    InventoryItem? purchasedPawn;
    if (kind == 'title_item') {
      titleType =
          await showDialog<String>(
            context: context,
            builder: (context) => SimpleDialog(
              title: const Text('Scegli il tuo Item Titolo'),
              children: [
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'arma'),
                  child: const Text('Arma'),
                ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'armatura'),
                  child: const Text('Armatura'),
                ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'scudo'),
                  child: const Text('Scudo'),
                ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'scudo_offensivo'),
                  child: const Text('Scudo offensivo'),
                ),
              ],
            ),
          ) ??
          '';
      if (titleType.isEmpty) return;
    }
    // ignore: invalid_use_of_protected_member
    // ignore: invalid_use_of_protected_member
    setState(() {
      obserController.text = (leggiNumero(obserController) - cost).toString();
      final item = merchantItemFromOffer(
        const {'fate_sign', 'chaos_sign'}.contains(kind)
            ? {...offer, 'cost': cost}
            : offer,
        titleType: titleType,
      );
      if (kind == 'pawn' || kind == 'pawn_v2' || kind == 'postea_companion') {
        purchasedPawn = item;
      }
      inventario.add(item);
      if (kind.startsWith('postea_') &&
          planarState['posteaFirstGiftClaimed'] != true) {
        planarState['posteaFirstGiftClaimed'] = true;
        inventario.add(
          posteaItem({
            'kind': 'postea_antimalus',
            'name': 'Anti malus · omaggio di Rusty',
            'desc':
                'Rimuove un malus e lo blocca fino alla fine del fight corrente o prossimo.',
          }),
        );
      }
      if (const {
        'stat_gem',
        'fate_sign',
        'chaos_sign',
        'fallen_eye',
        'gathering_collector',
      }.contains(kind)) {
        offer['remaining'] = 0;
      }
      if (kind == 'technique_scroll' && offer['blackMarketSelected'] == true) {
        offer['remaining'] = 0;
      }
      if (item.arma && item.ability == null) {
        final weaponSkill = merchantWeaponSkill(item);
        if (!skills.any((skill) => skill.nome == weaponSkill.nome)) {
          skills.add(weaponSkill);
        }
      }
      risultato = 'Negoziante: hai speso $cost Obser per ${item.nome}.';
      aggiungiLog(risultato);
    });
    _saveActiveMerchantProfileStock();
    programmaSalvataggio();
    if (purchasedPawn != null) await activatePawnItem(purchasedPawn!);
    if (mounted) unawaited(sendRealtimeActiveSheetToStaff());
  }

  void _buyNurseService(Map<String, dynamic> offer, int cost) {
    final service = '${offer['service'] ?? ''}';
    if (!merchantServiceHasEffect(offer)) return;
    // ignore: invalid_use_of_protected_member
    setState(() {
      obserController.text = (leggiNumero(obserController) - cost).toString();
      switch (service) {
        case 'hp':
          currentHpController.text = maxHp().toString();
          break;
        case 'oculum_shield':
          ricaricaScudoOculum();
          break;
        case 'will':
          final current = currentVolonta();
          setCurrentStatFromVisibleInput(
            'volonta',
            min(statMassimo('volonta'), current + 1).toString(),
            trackConsumption: false,
          );
          break;
        case 'matter':
          final current = currentMateria();
          setCurrentStatFromVisibleInput(
            'materia',
            min(statMassimo('materia'), current + 1).toString(),
            trackConsumption: false,
          );
          break;
        case 'temp_hp':
          impostaHpTempTotali(hpTemp() + 15);
          break;
        case 'shield':
          scudoController.text = (leggiNumero(scudoController) + 10).toString();
          break;
        case 'oculum':
          addOculum(1, scheduleSave: false);
          break;
        case 'full':
          refullaStatsAttuali(forceMaximum: true);
          currentHpController.text = maxHp().toString();
          for (final art in arti) {
            art.integritaCorrente = artIntegrityEffectiveMaximum(art);
          }
          if (scudoOculumMax() > 0) ricaricaScudoOculum();
          final removed = removeNegativeConditionsForVulnerabilityReset();
          scudoController.text = '${leggiNumero(scudoController) + 20}';
          final percent = readIntValue(
            offer['buffPercent'],
            fallback: 10,
          ).clamp(10, 60).toInt();
          final jackpot = percent >= 40;
          final giftHp = oculumNurseTempHpGiftFromRoll(
            percentileRoll: Random.secure().nextInt(100),
            level: max(0, leggiNumero(livelloController)),
            maximumTemporaryHp: thresholdTemporaryHpLimit(),
            levelGiftChancePercent: readIntValue(
              offer['rareTempHpChancePercent'],
              fallback: 1,
            ),
            halfCeilingChancePercent: readIntValue(
              offer['halfTempHpRoundedUpChancePercent'],
              fallback: 2,
            ),
            halfFloorChancePercent: readIntValue(
              offer['halfTempHpRoundedDownChancePercent'],
              fallback: 5,
            ),
            hpPerLevel: readIntValue(offer['tempHpPerLevel'], fallback: 5),
          );
          var giftHpApplied = 0;
          if (giftHp > 0) {
            final beforeGift = hpTemp();
            impostaHpTempTotali(beforeGift + giftHp);
            giftHpApplied = max(0, hpTemp() - beforeGift);
          }
          final denominator = max(
            1,
            readIntValue(
              offer['jackpotShieldHpFractionDenominator'],
              fallback: 4,
            ),
          );
          final rareShield = jackpot ? maxHp() ~/ denominator : 0;
          if (rareShield > 0) {
            scudoController.text =
                '${leggiNumero(scudoController) + rareShield}';
          }
          heroicNursePendingBattleBuff = <String, dynamic>{
            'damagePercent': percent,
            'defensePercent': percent,
            'pending': true,
            'purchasedAt': DateTime.now().toIso8601String(),
            'difficultyDurations': <String, int>{
              'facile': 9,
              'medio': 6,
              'normale': 6,
              'difficile': 3,
              'oculum': 1,
            },
          };
          risultato =
              'Infermiera Eroica: Refull completato, $removed debuff rimossi, +20 Scudo incluso, +$percent% Danni e Difesa alla prossima battaglia${rareShield > 0 ? ', +$rareShield Scudo del jackpot' : ''}${giftHpApplied > 0 ? ', +$giftHpApplied HP temporanei in regalo' : ''}. Costo buff: ${oculumNurseBuffSurcharge(percent)} Obser.';
          break;
      }
      if (service != 'full') {
        risultato = 'Infermiera Eroica: ${offer['name']} per $cost Obser.';
      }
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
    if (service == 'hp' || service == 'full' || service == 'shield') {
      sendRealtimeHpChanged();
    }
    if (service == 'oculum' || service == 'full') {
      scheduleRealtimeOculumChanged();
    }
    unawaited(sendRealtimeActiveSheetToStaff());
  }

  Future<void> _buyBlackMarketOffer(
    Map<String, dynamic> offer,
    int cost,
  ) async {
    final id = '${offer['id'] ?? ''}';
    final kind = '${offer['kind'] ?? ''}';
    if (kind == 'black_market_ascension_dust') {
      if (merchantDustPurchaseCount >= 3) return;
      // ignore: invalid_use_of_protected_member
      setState(() {
        obserController.text = (leggiNumero(obserController) - cost).toString();
        ascensionDustController.text =
            (leggiNumero(ascensionDustController) + 1).toString();
        merchantDustPurchaseCount++;
        merchantDustPurchasedSinceLongRest = merchantDustPurchaseCount >= 3;
        risultato =
            'Mercato nero: acquistata Ascension Dust per $cost Obser · $merchantDustPurchaseCount/3.';
        aggiungiLog(risultato);
      });
      programmaSalvataggio();
      if (mounted) unawaited(sendRealtimeActiveSheetToStaff());
      return;
    }
    if (kind == 'black_market_fallen_eye') {
      final source = offer['sourceSheet'];
      if (source is! Map || source.isEmpty) return;
      // ignore: invalid_use_of_protected_member
      setState(() {
        obserController.text = (leggiNumero(obserController) - cost).toString();
        offer['remaining'] = 0;
        risultato =
            'Mercato nero: acquistato ${offer['name']} per $cost Obser.';
        aggiungiLog(risultato);
      });
      _saveActiveMerchantProfileStock();
      programmaSalvataggio();
      await createFallenEyeFromSource(
        Map<String, dynamic>.from(source),
        name: '${offer['name'] ?? 'Occhio dei Caduti'}',
        rarity: '${offer['rarity'] ?? 'non_comune'}',
      );
      if (mounted) unawaited(sendRealtimeActiveSheetToStaff());
      return;
    }

    CharacterArt? purchasedArt;
    CharacterSkill? purchasedSkill;
    InventoryItem? purchasedItem;
    if (kind == 'black_market_art') {
      purchasedArt = _blackMarketArt(id);
      if (purchasedArt == null ||
          arti.any((existing) => existing.nome == purchasedArt!.nome)) {
        return;
      }
    } else if (kind == 'black_market_monster_art') {
      purchasedArt = _blackMarketMonsterArtFromOffer(offer);
      final sourceArtKey = '${offer['sourceArtKey'] ?? ''}';
      final marker = 'oculum_market_art:$sourceArtKey';
      if (purchasedArt == null ||
          arti.any((existing) => existing.descrizione.contains(marker))) {
        return;
      }
    } else if (kind == 'black_market_skill') {
      purchasedSkill = _blackMarketSkill(id);
      if (purchasedSkill == null ||
          skills.any((existing) => existing.nome == purchasedSkill!.nome)) {
        return;
      }
    } else if (kind == 'black_market_monster_skill') {
      purchasedSkill = _blackMarketMonsterSkillFromOffer(offer);
      final sourceSkillId = '${offer['sourceSkillId'] ?? ''}';
      final marker =
          'black_market_source_skill:${oculumMonsterBookSkillBaseId(sourceSkillId)}';
      if (purchasedSkill == null ||
          skills.any(
            (existing) =>
                existing.descrizione.contains(marker) ||
                existing.forme.any((form) => form.note.contains(marker)),
          )) {
        return;
      }
    } else if (kind == 'black_market_monster_weapon') {
      final monster = monsterById('${offer['sourceMonsterId'] ?? ''}');
      if (monster == null) return;
      purchasedItem =
          oculumMonsterEquipmentCatalogue(
                source: monster,
                level: readIntValue(offer['level']),
                grade: readIntValue(offer['grade']),
              )
              .where(
                (item) =>
                    '${item.monsterLoot['id'] ?? ''}' == '${offer['itemId']}',
              )
              .firstOrNull;
      if (purchasedItem == null ||
          inventario.any(
            (item) => '${item.monsterLoot['id'] ?? ''}' == '${offer['itemId']}',
          )) {
        return;
      }
    } else if ((kind == 'technique_scroll' &&
            offer['blackMarketSelected'] == true) ||
        kind == 'black_market_scroll') {
      purchasedItem = merchantItemFromOffer(offer);
      if (inventario.any(
        (item) =>
            item.craftData['scroll'] is Map &&
            '${(item.craftData['scroll'] as Map)['id'] ?? ''}' ==
                (offer['scrollProfileId'] == 'corruption'
                    ? 'corruption/${readIntValue(offer['scrollGrade'])}'
                    : 'technique/${offer['scrollProfileId']}/${readIntValue(offer['scrollGrade'])}') &&
            readIntValue((item.craftData['scroll'] as Map)['grade']) ==
                readIntValue(offer['scrollGrade']),
      )) {
        return;
      }
    } else {
      return;
    }

    final purchasedName =
        purchasedArt?.nome ??
        purchasedSkill?.nome ??
        purchasedItem?.nome ??
        '${offer['name']}';
    // ignore: invalid_use_of_protected_member
    setState(() {
      obserController.text = (leggiNumero(obserController) - cost).toString();
      if (purchasedArt != null) arti.add(purchasedArt);
      if (purchasedSkill != null) skills.add(purchasedSkill);
      if (purchasedItem != null) inventario.add(purchasedItem);
      offer['remaining'] = 0;
      risultato = 'Mercato nero: acquistato $purchasedName per $cost Obser.';
      aggiungiLog(risultato);
    });
    _saveActiveMerchantProfileStock();
    programmaSalvataggio();
    if (mounted) unawaited(sendRealtimeActiveSheetToStaff());
  }

  CharacterArt? _blackMarketMonsterArtFromOffer(Map<String, dynamic> offer) {
    final monster = monsterById('${offer['sourceMonsterId'] ?? ''}');
    if (monster == null) return null;
    final imported = oculumMonsterBookImportArt(monster);
    if (imported == null) return null;
    final art = CharacterArt.fromJson(imported.toJson());
    final key = '${offer['sourceArtKey'] ?? monster.id}';
    art.nome = '${offer['name'] ?? imported.nome}';
    art.descrizione =
        '${art.descrizione}\nOrigine Mercato Nero: oculum_market_art:$key. Richiede livello ${readIntValue(offer['requiredLevel'])}.';
    return art;
  }

  CharacterSkill? _blackMarketMonsterSkillFromOffer(
    Map<String, dynamic> offer,
  ) {
    final monster = monsterById('${offer['sourceMonsterId'] ?? ''}');
    final skillId = '${offer['sourceSkillId'] ?? ''}';
    if (monster == null || skillId.isEmpty) return null;
    final art = oculumMonsterBookArt(monster);
    final ids = monsterBookUsableSkillIds(monster);
    final index = ids.indexOf(skillId);
    if (index < 0 || index >= art.skills.length) return null;
    if (!oculumMonsterTechniqueIsNatural(monster, skillId)) return null;
    final skill = CharacterSkill.fromJson(
      _naturalMonsterSkill(monster, skillId, art.skills[index]).toJson(),
    );
    final marker =
        'black_market_source_skill:${oculumMonsterBookSkillBaseId(skillId)}';
    skill.nome = '${offer['name'] ?? skill.nome}';
    skill.descrizione = '${skill.descrizione}\nOrigine: $marker.';
    final requiredLevel = max(0, readIntValue(offer['requiredLevel']));
    for (var i = 0; i < skill.forme.length; i++) {
      skill.forme[i].livello = '${requiredLevel + i * 3}';
      skill.forme[i].note =
          '${skill.forme[i].note}${skill.forme[i].note.isEmpty ? '' : '\n'}$marker';
    }
    return skill;
  }

  CharacterArt? _blackMarketArt(String id) {
    if (id != 'black_market_art_scoria') return null;
    return CharacterArt(
      nome: 'Art Nera: Archivio delle Scorie',
      tipo: 'Martial Art',
      descrizione:
          'Art acquistata al Mercato Nero. Evoluzioni e tecniche sono modificabili nell’editor Art.',
      skills: <ArtSkill>[
        ArtSkill(
          nome: 'Fiamma di Scoria',
          evo1: '@Danni+24 Fuoco',
          evo2: '@Danni+34 Fuoco',
          evo3: '@Danni+46 Fuoco',
          evo4: '@Danni+60 Fuoco',
          evo5: '@Danni+76 Fuoco',
          tipiPerLivello: List<String>.filled(5, 'Attacco'),
        ),
        ArtSkill(
          nome: 'Taglio di Gelo Nero',
          evo1: '@Danni+20 Ghiaccio',
          evo2: '@Danni+30 Ghiaccio',
          evo3: '@Danni+42 Ghiaccio',
          evo4: '@Danni+55 Ghiaccio',
          evo5: '@Danni+70 Ghiaccio',
          tipiPerLivello: List<String>.filled(5, 'Attacco'),
        ),
      ],
    );
  }

  CharacterSkill? _blackMarketSkill(String id) {
    final (name, damage, element, cooldown) = switch (id) {
      'black_market_skill_brace' => (
        'Tecnica Nera: Colpo di Brace',
        20,
        'Fuoco',
        '3 turni',
      ),
      'black_market_skill_gelo' => (
        'Tecnica Nera: Taglio di Gelo',
        30,
        'Ghiaccio',
        '4 turni',
      ),
      _ => ('', 0, '', ''),
    };
    if (name.isEmpty) return null;
    return CharacterSkill(
      nome: name,
      tipo: 'Attacco',
      costo: '1 azione',
      cooldown: cooldown,
      descrizione: 'Tecnica del Mercato Nero: +$damage danni $element.',
      forme: <CharacterSkillForm>[
        CharacterSkillForm(
          nome: 'Forma I',
          tipo: 'Attacco',
          livello: '0',
          costo: '1 azione',
          cooldown: cooldown,
          descrizione: 'Attacca un bersaglio con $element.',
          danni: '@Danni+$damage $element',
        ),
      ],
    );
  }

  /// Il mercante paga circa un sesto del valore stimato: utile, ma spilorcio.
  int merchantSaleValue(InventoryItem item) {
    if (item.craftData['monsterRelic'] == true &&
        readIntValue(item.craftData['monsterRelicMarketPrice']) > 0) {
      return oculumMonsterRelicSaleValueForMarketPrice(
        readIntValue(item.craftData['monsterRelicMarketPrice']),
        quantity: item.quantita,
      );
    }
    if (item.craftData['scroll'] is Map) {
      final data = item.craftData['scroll'] as Map;
      return max(1, oculumScrollValue(readIntValue(data['grade'])) ~/ 6) *
          max(1, item.quantita);
    }
    final grade = max(item.gradoOggetto, item.gradoRichiesto);
    final rawValue =
        18 +
        item.bonusDanno * 8 +
        item.bonusDifesa * 10 +
        item.bonusScudo * 3 +
        item.bonusScudoOculum * 12 +
        grade * grade * 90 +
        max(0, item.livelloOggetto) * 25;
    return max(1, rawValue ~/ 6) * max(1, item.quantita);
  }

  void sellInventoryItemToMerchant(InventoryItem item) {
    if (!merchantIsOpen || !inventario.contains(item)) return;
    final payment = merchantSaleValue(item);
    // ignore: invalid_use_of_protected_member
    setState(() {
      if (item.equipaggiata) {
        applicaScudoItemAttuale(item, -1);
        item.equipaggiata = false;
      }
      inventario.remove(item);
      obserController.text = (leggiNumero(obserController) + payment)
          .toString();
      risultato = 'Negoziante: hai venduto ${item.nome} per $payment Obser.';
      aggiungiLog(risultato);
    });
    _saveActiveMerchantProfileStock();
    programmaSalvataggio();
  }

  void buyAscensionDustFromMerchant() {
    if (merchantDustPurchaseCount >= 3 ||
        merchantShopType != 'alchimista' ||
        leggiNumero(obserController) < merchantDustPrice) {
      return;
    }
    // ignore: invalid_use_of_protected_member
    setState(() {
      obserController.text = (leggiNumero(obserController) - merchantDustPrice)
          .toString();
      ascensionDustController.text = (leggiNumero(ascensionDustController) + 1)
          .toString();
      merchantDustPurchaseCount++;
      merchantDustPurchasedSinceLongRest = merchantDustPurchaseCount >= 3;
      risultato =
          'Alchimista: $merchantDustPrice Obser per 1 Ascension Dust · $merchantDustPurchaseCount/3.';
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  InventoryItem merchantItemFromOffer(
    Map<String, dynamic> offer, {
    String titleType = '',
  }) {
    if (const {
      'power_scanner',
      'postea_power_scanner',
    }.contains(offer['kind'])) {
      return powerScannerFromOffer(offer);
    }
    if (offer['kind'] == 'dust_crystal') {
      return oculumDustCrystal('${offer['size']}');
    }
    if (const {
      'postea_companion',
      'postea_antimalus',
      'postea_katana',
      'postea_gloves',
      'postea_runic_lens',
      'postea_meccanio',
    }.contains(offer['kind'])) {
      return posteaItem(offer);
    }
    if (offer['kind'] == 'postea_cyber_armor') {
      final level = max(0, leggiNumero(livelloController));
      final grade = max(0, leggiNumero(gradoController));
      final shield = (maxHp() / 2).ceil();
      final variant = readIntValue(offer['variant']) % 3;
      final primary = const ['resilienza', 'materia', 'volonta'][variant];
      final growthBonus = (1 + grade ~/ 3).clamp(1, 4);
      return InventoryItem(
        nome: '${offer['name']}',
        peso: 2,
        quantita: 1,
        note:
            '${offer['desc']} Acquisto: HP massimi ${maxHp()}, Scudo $shield; livello $level. Bonus proposti: +${2 + grade} Danni e Difesa, +1 $primary ogni 3 livelli oggetto.',
        protegge: true,
        livelloOggetto: level,
        statCrescita: primary,
        bonusScudo: shield,
        bonusScudoIncludeGrado: true,
        buff: '@Danni+${2 + grade} @Difesa+${2 + grade}',
        craftData: {
          'clothing': true,
          'cyberPostea': true,
          'growthEvery': 3,
          'purchaseMaxHp': maxHp(),
          'purchaseShield': shield,
        },
        effettoRotturaScudo: {
          'chancePercent': 99,
          'duration': 6,
          if (variant == 0) 'condition': 'nutrito_resilienza',
          if (variant != 0) 'buffTarget': variant == 1 ? primary : 'piu_usato',
          if (variant != 0)
            'buffValue': variant == 1
                ? growthBonus
                : (3 + grade ~/ 3).clamp(3, 6),
        },
        ability: oculumForestDemonArmorAbility(level),
      );
    }
    if (offer['kind'] == 'postea_boots') {
      return InventoryItem(
        nome: '${offer['name']}',
        peso: .5,
        quantita: 1,
        note: '${offer['desc']}',
        craftData: {'posteaBoots': true},
        ability: oculumPosteaBootsAbility(),
      );
    }
    if (offer['kind'] == 'postea_weapon') {
      return InventoryItem(
        nome: '${offer['name']}',
        peso: 1,
        quantita: 1,
        note: '${offer['desc']}',
        arma: true,
        bonusDanno: 0,
        ability: oculumPosteaMitraAbility(
          max(0, readIntValue(offer['damage'])),
        ),
        craftData: {'postea': true},
      );
    }
    final silk = oculumMagicSilkItem('${offer['silkId'] ?? ''}');
    if (silk != null) return silk;
    if (offer['kind'] == 'clothing') {
      return InventoryItem(
        nome: '${offer['name']}',
        peso: .5,
        quantita: 1,
        note: '${offer['desc']}',
        protegge: true,
        livelloOggetto: max(0, readIntValue(offer['level'])),
        statCrescita: '${offer['growthStat']}',
        bonusScudo: max(0, readIntValue(offer['shield'])),
        bonusScudoIncludeGrado: true,
        bonusScudoOculum: max(0, readIntValue(offer['oculumShield'])),
        buff:
            '@HPTemp+${readIntValue(offer['tempHp'])} @Danni+${readIntValue(offer['damage'])} @Difesa+${readIntValue(offer['defence'])}',
        craftData: {
          'clothing': true,
          'growthEvery': readIntValue(offer['growthEvery'], fallback: 3),
        },
        ability: oculumEquipmentAbility('${offer['name']}', 0),
      );
    }
    if (offer['kind'] == 'gathering_collector') {
      final collectorGrade = readIntValue(offer['grade']).clamp(0, 12);
      final collectorLevel = max(0, readIntValue(offer['level']));
      return InventoryItem(
        nome: '${offer['name'] ?? 'Raccoglitore Grado 0/XII'}',
        quantita: 1,
        peso: .2,
        note:
            '${offer['desc'] ?? 'Passiva: raddoppia i materiali raccolti di Grado $collectorGrade o inferiore.'} Si attiva tenendolo nell’inventario.',
        gradoOggetto: collectorGrade,
        livelloOggetto: collectorLevel,
        craftData: <String, dynamic>{
          'gatheringCollector': <String, dynamic>{
            'grade': collectorGrade,
            'level': collectorLevel,
            'multiplier': 2,
          },
        },
      );
    }
    if (offer['kind'] == 'chaos_sign') {
      return InventoryItem(
        nome: 'Segno del Chaos',
        quantita: 1,
        peso: .01,
        note: '${offer['desc']}',
        craftData: {
          'chaosSign': {'cost': readIntValue(offer['cost'], fallback: 60)},
        },
      );
    }
    if (offer['kind'] == 'fate_sign') {
      return InventoryItem(
        nome: 'Segno del Fato',
        quantita: 1,
        peso: .01,
        note: '${offer['desc']}',
        craftData: {
          'fateSign': {'cost': readIntValue(offer['cost'], fallback: 50)},
        },
      );
    }
    if (offer['kind'] == 'smoking_herbs') {
      return InventoryItem(
        nome: '${offer['name']}',
        quantita: 1,
        peso: .05,
        note: '${offer['desc']}',
        craftData: {'smokingHerbs': Map<String, dynamic>.from(offer)},
      );
    }
    if (offer['kind'] == 'summoning_emblem') {
      return InventoryItem(
        nome: '${offer['name']}',
        peso: .1,
        quantita: 1,
        note: '${offer['desc']}',
        craftData: {
          'summoningEmblem': Map<String, dynamic>.from(
            offer['summoningEmblem'] is Map
                ? offer['summoningEmblem'] as Map
                : oculumSummoningEmblemDefaults,
          ),
        },
      );
    }
    if (offer['kind'] == 'alchemy_pet') {
      return InventoryItem(
        nome: '${offer['name']}',
        peso: .1,
        quantita: 1,
        note: '${offer['desc']}',
        craftData: {'alchemyPet': offer['petId']},
      );
    }
    if (offer['kind'] == 'black_market_scroll' &&
        offer['scrollProfileId'] == 'corruption') {
      return oculumCorruptionScrollItem(readIntValue(offer['scrollGrade']));
    }
    if (offer['kind'] == 'technique_scroll') {
      if (offer['scrollProfileId'] == 'provi_gratitudine') {
        return oculumGratitudineScrollItem(readIntValue(offer['scrollGrade']));
      }
      final profile = oculumTechniqueScrolls.firstWhere(
        (p) => p.id == offer['scrollProfileId'],
      );
      return oculumTechniqueScrollItem(
        profile,
        readIntValue(offer['scrollGrade']),
      );
    }
    if (offer['kind'] == 'creature_core') {
      return oculumCreatureCore(readIntValue(offer['coreTier']));
    }
    if (offer['kind'] == 'pawn') return oculumPawnInventoryItem();
    if (offer['kind'] == 'pawn_v2') return oculumPawnV2InventoryItem();
    final kind = '${offer['kind'] ?? ''}';
    if (kind == 'food') {
      final effects = <String, dynamic>{
        for (final key in [
          'resilienza',
          'volonta',
          'materia',
          'oculum',
          'alcohol',
          'restoreAllStats',
          'healHpPercent',
          'cleanseNegativeConditions',
          'resistanceElement',
          'resistancePreset',
          'subtraitId',
          'subtraitBonus',
          'condition',
          'conditionStage',
          'conditionTurns',
          'damagePercent',
          'defensePercent',
          'learnMonsterId',
        ])
          if (offer.containsKey(key)) key: offer[key],
      };
      return InventoryItem(
        nome: '${offer['name']}',
        peso: offer['isMaterial'] == true ? .05 : .25,
        quantita: 1,
        note: '${offer['desc']}',
        monsterLoot: <String, dynamic>{
          'food': effects,
          if (offer['isMaterial'] == true) 'material': true,
        },
      );
    }
    if (kind == 'stat_gem') {
      final stat = '${offer['stat']}';
      if (!oculumStatGemNames.containsKey(stat)) {
        throw ArgumentError('Statistica della gemma sconosciuta');
      }
      final faces = max(
        1,
        readIntValue(
          offer['dieFaces'],
          fallback: oculumStatGemDieFaces(merchantGemStatValue(stat)),
        ),
      );
      return InventoryItem(
        nome: oculumStatGemNames[stat]!,
        peso: .1,
        quantita: 1,
        statGemStat: stat,
        statGemDieFaces: faces,
        note:
            'Consumabile: recupera punti attuali di ${oculumStatGemNames[stat]!.replaceFirst('Gemma di ', '')} di 1d$faces. Una gemma, un solo tiro. Eccesso fino al riposo lungo.',
      );
    }
    if (kind == 'raw_vitalium') {
      return InventoryItem(
        nome: 'Vitalium Grezzo',
        peso: .1,
        quantita: 1,
        note:
            'Consumabile: scegli quanto Oculum immettere e recuperi altrettanti HP. Se non hai Oculum, paghi 2 Materia e 2 Volontà per punto. ${oculumRawVitaliumRuleForGrade(max(0, leggiNumero(gradoController)))}',
      );
    }
    if (kind == 'refined_vitalium') {
      return InventoryItem(
        nome: 'Vitalium Ridefinito',
        peso: .2,
        quantita: 1,
        note:
            'Consumabile: ripristina HP, Resilienza, Volontà, Materia e Oculum attuali fino ai massimali e l’integrità delle Art. Non crea Oculum se il massimale è zero.',
      );
    }
    if (kind == 'oculum_vial') {
      return InventoryItem(
        nome: 'Fiala di Oculum',
        peso: .1,
        quantita: 1,
        note: 'Consumabile: ricarica 1d4 Oculum.',
      );
    }
    if (kind == 'bone_prison_scroll') {
      return InventoryItem(
        nome: 'Pergamena della Prigione d Ossa',
        peso: .1,
        quantita: 1,
        note:
            'Usabile: infligge 12 danni perforanti e applica Stordito per 1 turno al bersaglio della scheda attiva.',
      );
    }
    final grade = readIntValue(offer['grade']);
    final isTitle = kind == 'title_item';
    final weapon = isTitle
        ? titleType == 'arma' || titleType == 'scudo_offensivo'
        : readBoolValue(offer['weapon']);
    final protects = isTitle
        ? titleType != 'arma'
        : readBoolValue(offer['protection'], fallback: !weapon);
    final shield = isTitle
        ? titleType == 'scudo' || titleType == 'scudo_offensivo'
        : protects;
    return InventoryItem(
      nome: isTitle
          ? 'Item Titolo — ${titleType.replaceAll('_', ' ')}'
          : '${offer['name']}',
      ability: offer['necromancyKind'] != null
          ? CharacterSkill(
              nome: '${offer['name']}',
              tipo: 'Supporto',
              costo: '',
              cooldown: '',
              descrizione: '${offer['desc']}',
              forme: [
                CharacterSkillForm(
                  nome: 'I',
                  tipo: 'Supporto',
                  livello: '${max(0, readIntValue(offer['level']))}',
                  descrizione: '${offer['desc']}',
                  cooldownStrutturato: OculumAbilityCooldown(amount: 6),
                  effettiStrutturati: [
                    OculumStructuredEffect(
                      type: 'evocazione',
                      valueExpression: '1',
                      duration: '3',
                    ),
                  ],
                ),
              ],
            )
          : offer['planeResistance'] != null
          ? CharacterSkill(
              nome: 'Sigillo contro ${offer['planeResistance']}',
              tipo: 'Difesa',
              costo: '',
              cooldown: '',
              descrizione: 'Protezione runica temporanea',
              forme: [
                CharacterSkillForm(
                  nome: 'I',
                  tipo: 'Difesa',
                  livello: '${max(0, readIntValue(offer['level']))}',
                  descrizione:
                      'Resistenza a ${offer['planeResistance']} per 3 turni; CD 6 turni.',
                  cooldownStrutturato: OculumAbilityCooldown(amount: 6),
                  effettiStrutturati: [
                    OculumStructuredEffect(
                      type: 'elemental_resistance',
                      elementType: '${offer['planeResistance']}',
                      customDisplayText: 'Resistenza',
                      mode: 'finche_attivo',
                      duration: '3',
                    ),
                  ],
                ),
              ],
            )
          : oculumEquipmentAbility(
              isTitle
                  ? (weapon ? 'Arma del Titolo' : 'Corazza del Titolo')
                  : '${offer['name']}',
              grade,
              element: offer['element'] as String?,
            ),
      peso: offer['heavyClothing'] == true ? 3 : 1.2,
      craftData: {
        if (offer['heavyClothing'] == true) 'heavyClothing': true,
        if (offer['necromancyKind'] != null)
          'necromancyKind': offer['necromancyKind'],
        if (offer['necromancyKind'] != null) 'duration': 3,
      },
      quantita: 1,
      note: isTitle
          ? 'Oggetto scelto dal Negoziante. Livello oggetto ${max(0, readIntValue(offer['level']))} · Grado richiesto $grade. Skill sbloccata dal livello ${max(0, readIntValue(offer['level']))}.'
          : weapon
          ? '${offer['desc']}\nLivello oggetto ${max(0, readIntValue(offer['level']))} · Grado richiesto $grade. Skill dell’oggetto sbloccata dal livello ${max(0, readIntValue(offer['level']))}. Materiale: ${offer['monsterId'] ?? "forgiatura del mercante"}. Skill configurabile nell’oggetto.'
          : '${offer['desc']}\nLivello oggetto ${max(0, readIntValue(offer['level']))} · Grado richiesto $grade. Skill difensiva sbloccata dal livello ${max(0, readIntValue(offer['level']))}.',
      arma: weapon,
      protegge: protects,
      bonusDanno: weapon && protects
          ? (isTitle
                ? 2
                : readIntValue(offer['damage'], fallback: 2 + grade * 8))
          : weapon
          ? max(
              readBoolValue(offer['authored']) ? 1 : 6,
              readIntValue(
                offer['damage'],
                fallback: oculumMerchantAttackValue(
                  6,
                  leggiNumero(volontaController),
                ),
              ),
            )
          : 0,
      bonusDifesa: !protects
          ? 0
          : max(
              5,
              readIntValue(
                offer['defence'],
                fallback: oculumMerchantDefenseValue(
                  leggiNumero(materiaController),
                ),
              ),
            ),
      bonusScudo: protects
          ? readIntValue(
              offer['shield'],
              fallback: oculumMerchantShieldValue(maxHp(), 40),
            )
          : 0,
      bonusScudoIncludeGrado: true,
      bonusScudoOculum: grade >= 3 && shield ? 4 + grade * 3 : 0,
      gradoOggetto: grade,
      livelloOggetto: max(0, readIntValue(offer['level'])),
      puntiStatPerLivello: (1 + grade ~/ 4).clamp(1, 3),
      statCrescita: weapon ? 'volonta' : 'materia',
      gradoRichiesto: grade,
      elementoDanno:
          '${offer['element'] ?? (grade >= 2 ? 'Oculum' : 'Fisico')}',
      buff: [
        '${offer['buff'] ?? ''}',
        if (offer['statBonuses'] is Map)
          for (final entry in (offer['statBonuses'] as Map).entries)
            if (entry.key != 'oculum' || merchantGemStatValue('oculum') > 0)
              '@${entry.key}+${entry.value}',
        if (readBoolValue(offer['quickReaction'])) '@ReazioneVeloce+1',
        if (!readBoolValue(offer['quickReaction']) && grade >= 3 && shield)
          '@SchivateOculum+1',
      ].where((value) => value.isNotEmpty).join(' '),
      effettoRotturaScudo: offer['shieldBreakEffect'] is Map
          ? Map<String, dynamic>.from(offer['shieldBreakEffect'])
          : <String, dynamic>{},
    );
  }

  int merchantHerbalSubtraitBonus(String subtraitId) => merchantHerbalEffects
      .where(
        (effect) =>
            effect['type'] == 'subtrait_bonus' &&
            effect['subtraitId'] == subtraitId &&
            readIntValue(effect['shortRestsRemaining']) > 0,
      )
      .fold<int>(0, (sum, effect) => sum + readIntValue(effect['value']));

  int merchantHerbalStatBonus(String statId) => merchantHerbalEffects
      .where(
        (effect) =>
            effect['type'] == 'stat_bonus' &&
            effect['statId'] == statId &&
            readIntValue(effect['shortRestsRemaining']) > 0,
      )
      .fold<int>(
        smokingHerbStatBonus(statId),
        (sum, effect) => sum + readIntValue(effect['value']),
      );

  Map<String, dynamic>? merchantCraftedHerbalOffer(String itemName) {
    final offerId = switch (itemName.trim()) {
      'Radice delle Quattro Vene' => 'herb_fourfold_root',
      'Unguento di Millefoglie' => 'ointment_millefoglie',
      'Balsamo di Corteccia Azzurra' => 'balm_blue_bark',
      'Polline dei Riflessi' => 'pollen_reflexes',
      'Unguento della Concentrazione' => 'ointment_focus',
      _ => '',
    };
    if (offerId.isEmpty) return null;
    for (final offer in ensureMerchantStock()) {
      if (offer['id'] == offerId) return offer;
    }
    return null;
  }

  bool isMerchantConsumable(InventoryItem item) =>
      item.craftData['powerScanner'] == true ||
      item.craftData['dustCrystal'] != null ||
      item.craftData['posteaAntimalus'] == true ||
      item.craftData['summoningEmblem'] is Map ||
      item.craftData['witheredHeart'] == true ||
      item.craftData['chaosSign'] is Map ||
      item.craftData['fateSign'] is Map ||
      item.craftData['smokingHerbs'] is Map ||
      item.craftData['creatureCore'] == true ||
      item.craftData['pawn'] == true ||
      item.craftData['alchemyPet'] != null ||
      item.craftData['scroll'] is Map ||
      item.monsterLoot['food'] is Map ||
      oculumStatGemNames.containsKey(item.statGemStat) ||
      const <String>{
        'Vitalium Grezzo',
        'Vitalium Ridefinito',
        'Fiala di Oculum',
        'Pergamena della Prigione d Ossa',
        'Pinna di Pesce Alato',
      }.contains(item.nome.trim());

  Future<void> useMerchantConsumable(InventoryItem item) async {
    if (!canEquipInventoryItem(item)) {
      aggiungiLog('Grado insufficiente per usare ${item.nome}.');
      return;
    }
    if (!inventario.contains(item) ||
        !isMerchantConsumable(item) ||
        item.quantita <= 0) {
      return;
    }
    if (item.craftData['powerScanner'] == true) {
      await usePowerScanner(item);
      return;
    }
    if (item.craftData['dustCrystal'] != null) {
      await breakDustCrystal(item);
      return;
    }
    if (item.craftData['posteaAntimalus'] == true) {
      await usePosteaAntiMalus(item);
      return;
    }
    if (item.craftData['summoningEmblem'] is Map) {
      await activateSummoningEmblem(item);
      return;
    }
    if (item.craftData['witheredHeart'] == true) {
      useWitheredHeart(item);
      // ignore: invalid_use_of_protected_member
      if (mounted) setState(() {});
      return;
    }
    if (item.craftData['creatureCore'] == true) {
      if (item.craftData['brokenCore'] == true) {
        await repairCreatureCore(item);
      } else {
        await summonCreatureCore(item);
      }
      return;
    }
    if (item.craftData['smokingHerbs'] is Map) {
      useSmokingHerbs(item);
      // ignore: invalid_use_of_protected_member
      if (mounted) setState(() {});
      return;
    }
    if (item.craftData['chaosSign'] is Map) {
      useChaosSign(item);
      // ignore: invalid_use_of_protected_member
      if (mounted) setState(() {});
      return;
    }
    if (item.craftData['fateSign'] is Map) {
      useFateSign(item);
      // ignore: invalid_use_of_protected_member
      if (mounted) setState(() {});
      return;
    }
    if (item.craftData['pawn'] == true) {
      await activatePawnItem(item);
      return;
    }
    if (item.craftData['alchemyPet'] != null) {
      await activateAlchemyPet(item);
      return;
    }
    if (item.craftData['scroll'] is Map) {
      await useScrollAbility(
        Map<String, dynamic>.from(item.craftData['scroll'] as Map),
        item: item,
      );
      return;
    }
    if (item.monsterLoot['food'] is Map) {
      final food = item.monsterLoot['food'] as Map;
      final hasTimedHerbalEffect =
          food['resistanceElement'] != null ||
          food['subtraitId'] != null ||
          food['condition'] != null ||
          readIntValue(food['damagePercent']) != 0 ||
          readIntValue(food['defensePercent']) != 0 ||
          food['isMaterial'] == true ||
          item.nome.startsWith('Erba ') ||
          item.nome.startsWith('Polline ') ||
          item.nome.startsWith('Unguento ') ||
          item.nome.startsWith('Balsamo ');
      if (food['restoreAllStats'] == true ||
          readIntValue(food['healHpPercent']) > 0 ||
          food['cleanseNegativeConditions'] == true ||
          hasTimedHerbalEffect) {
        final effects = <String>[];
        // ignore: invalid_use_of_protected_member
        setState(() {
          if (food['restoreAllStats'] == true) {
            refullaStatsAttuali();
            effects.add('statistiche attuali ripristinate');
          }
          final healPercent = readIntValue(food['healHpPercent']);
          if (healPercent > 0) {
            final hp = hpCorrenti();
            final recovery = (maxHp() * healPercent / 100).ceil();
            currentHpController.text = min(maxHp(), hp + recovery).toString();
            effects.add('+$recovery HP');
          }
          if (food['cleanseNegativeConditions'] == true) {
            final removed = removeNegativeConditionsForVulnerabilityReset();
            effects.add('$removed condizioni negative rimosse');
          }
          if (food['resistanceElement'] != null) {
            merchantHerbalEffects.add(<String, dynamic>{
              'type': 'resistance',
              'element': oculumNormalizeElementId(
                '${food['resistanceElement']}',
              ),
              'preset': canonicalDamageModifierName(
                '${food['resistancePreset'] ?? 'Resistenza'}',
              ),
              'shortRestsRemaining': 2,
              'source': item.nome,
            });
            effects.add(
              'resistenza a ${elementDisplayName('${food['resistanceElement']}')}',
            );
          }
          for (final statId in ['resilienza', 'volonta', 'materia', 'oculum']) {
            final value = readIntValue(food[statId]);
            if (value == 0 || (statId == 'oculum' && oculumTotale() <= 0)) {
              continue;
            }
            merchantHerbalEffects.add(<String, dynamic>{
              'type': 'stat_bonus',
              'statId': statId,
              'value': value,
              'shortRestsRemaining': 2,
              'source': item.nome,
            });
            effects.add('$statId ${value >= 0 ? '+' : ''}$value');
          }
          final subtraitId = '${food['subtraitId'] ?? ''}'.trim();
          final subtraitBonus = readIntValue(food['subtraitBonus']);
          if (subtraitId.isNotEmpty && subtraitBonus != 0) {
            merchantHerbalEffects.add(<String, dynamic>{
              'type': 'subtrait_bonus',
              'subtraitId': subtraitId,
              'value': subtraitBonus,
              'shortRestsRemaining': 2,
              'source': item.nome,
            });
            effects.add('+$subtraitBonus $subtraitId');
            invalidateHiddenEyeDerivedCaches();
          }
          final timedEffects = oculumMerchantTimedFoodEffects(
            Map<String, dynamic>.from(food),
            source: 'Cibo e Bevanda · ${item.nome}',
          );
          for (final timed in timedEffects) {
            activeStructuredEffects.removeWhere(
              (effect) =>
                  effect['source'] == timed['source'] &&
                  effect['type'] == timed['type'] &&
                  effect['target'] == timed['target'],
            );
            activeStructuredEffects.add(<String, dynamic>{
              'id':
                  'merchant_food_${timed['target']}_${DateTime.now().microsecondsSinceEpoch}',
              ...timed,
            });
            final label = timed['type'] == 'danno_percentuale'
                ? 'Danni'
                : 'Difesa';
            final value = readIntValue(timed['value']);
            effects.add('$label ${value > 0 ? '+' : ''}$value%');
          }
          final condition = '${food['condition'] ?? ''}'.trim();
          if (condition.isNotEmpty) {
            applyCondition(
              condition,
              stage: readIntValue(food['conditionStage'], fallback: 1),
              duration: readIntValue(food['conditionTurns'], fallback: 2),
              durationType: food['conditionTurns'] != null
                  ? OculumConditionDurationType.turns
                  : OculumConditionDurationType.rests,
              tickTrigger: OculumConditionTickTrigger.none,
              source: 'Erba ${item.nome}',
            );
            effects.add(condition);
          }
          tryLearnMonsterFood(food);
          item.quantita--;
          if (item.quantita <= 0) inventario.remove(item);
          invalidateDerivedDataCaches();
          final durationLabel = food['conditionTurns'] != null
              ? '${readIntValue(food['conditionTurns'])} turni'
              : 'fino al Riposo Lungo o dopo 2 Riposi Brevi';
          risultato =
              '${item.nome}: ${effects.join(', ')}. Durata: $durationLabel.';
          aggiungiLog(risultato);
        });
        programmaSalvataggio();
        return;
      }
      // ignore: invalid_use_of_protected_member
      setState(() {
        tempResilienza += readIntValue(food['resilienza']);
        tempVolonta += readIntValue(food['volonta']);
        tempMateria += readIntValue(food['materia']);
        final oculumBonus = oculumTotale() > 0
            ? readIntValue(food['oculum'])
            : 0;
        tempOculum += oculumBonus;
        for (final key in ['resilienza', 'volonta', 'materia', 'oculum']) {
          consumedFoodBonuses[key] =
              (consumedFoodBonuses[key] ?? 0) +
              (key == 'oculum' ? oculumBonus : readIntValue(food[key]));
        }
        tryLearnMonsterFood(food);
        item.quantita--;
        if (item.quantita <= 0) inventario.remove(item);
        invalidateDerivedDataCaches();
        risultato =
            '${item.nome}: bonus consumabile applicato; dura fino al prossimo riposo.';
        aggiungiLog(risultato);
      });
      programmaSalvataggio();
      return;
    }
    if (oculumStatGemNames.containsKey(item.statGemStat)) {
      final faces = max(1, item.statGemDieFaces);
      final roll = Random().nextInt(faces) + 1;
      // ignore: invalid_use_of_protected_member
      setState(() {
        final key = item.statGemStat;
        final controller = currentStatController(key);
        final maximum = currentStatNaturalControllerMax(key);
        final normal = key == 'oculum'
            ? currentTemporaryOculumState().normalCurrent
            : readIntValue(controller.text);
        final next = normal + roll;
        statGemOverflow[key] = max(statGemOverflow[key] ?? 0, next - maximum);
        if (key == 'oculum') {
          final current = currentTemporaryOculumState();
          applyTemporaryOculumState(
            TemporaryOculumState(
              normalCurrent: next,
              temporary: current.temporary,
              rollsRemaining: current.rollsRemaining,
            ),
          );
        } else {
          controller.text = next.toString();
          syncVisibleCurrentStatEditor(key);
          invalidateHiddenEyeDerivedCaches();
        }
        item.quantita--;
        if (item.quantita <= 0) inventario.remove(item);
        risultato =
            '${item.nome}: 1d$faces = $roll. Recuperati $roll punti; l’eccesso dura fino al riposo lungo.';
        aggiungiLog(risultato);
      });
      programmaSalvataggio();
      return;
    }
    var amount = 0;
    var payWithCoreStats = false;
    if (item.nome.trim() == 'Vitalium Grezzo') {
      final available = max(0, leggiNumero(currentOculumController));
      payWithCoreStats = available <= 0;
      final affordable = payWithCoreStats
          ? min(
                  leggiNumero(currentMateriaController),
                  leggiNumero(currentVolontaController),
                ) ~/
                2
          : available;
      if (affordable <= 0) {
        risultato = payWithCoreStats
            ? 'Vitalium Grezzo: servono almeno 2 Materia e 2 Volontà per usarlo senza Oculum.'
            : 'Vitalium Grezzo: non hai Oculum da immettere.';
        aggiungiLog(risultato);
        return;
      }
      final input = TextEditingController(text: '1');
      amount =
          await showDialog<int>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Vitalium Grezzo'),
              content: TextField(
                controller: input,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: payWithCoreStats
                      ? 'Unità da alimentare · costo 2 Materia + 2 Volontà ciascuna (1–$affordable)'
                      : 'Oculum da immettere (1–$available)',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    readIntValue(input.text).clamp(1, affordable),
                  ),
                  child: const Text('Usa'),
                ),
              ],
            ),
          ) ??
          0;
      input.dispose();
      if (amount <= 0) return;
    }
    // ignore: invalid_use_of_protected_member
    setState(() {
      switch (item.nome.trim()) {
        case 'Vitalium Grezzo':
          final grade = max(0, leggiNumero(gradoController));
          final medicineDieFaces = grade >= 3
              ? 30
              : grade >= 2
              ? 20
              : 10;
          final medicineDie = Random().nextInt(medicineDieFaces) + 1;
          final medicineRoll = oculumRawVitaliumMedicineRoll(
            die: medicineDie,
            medicine: medicinaAttualeAggiustaNucleo(),
          );
          final medicineBonus = oculumRawVitaliumMedicineBonus(
            grade: grade,
            medicineRoll: medicineRoll,
          );
          final heal = max(0, amount + medicineBonus);
          if (payWithCoreStats) {
            currentMateriaController.text = max(
              0,
              leggiNumero(currentMateriaController) - amount * 2,
            ).toString();
            currentVolontaController.text = max(
              0,
              leggiNumero(currentVolontaController) - amount * 2,
            ).toString();
          } else {
            currentOculumController.text = max(
              0,
              leggiNumero(currentOculumController) - amount,
            ).toString();
          }
          currentHpController.text = min(
            maxHp(),
            leggiNumero(currentHpController) + heal,
          ).toString();
          final medicineDetails = grade < 1
              ? ' d$medicineDieFaces Medicina: $medicineDie, tiro $medicineRoll: nessun bonus prima del Grado I.'
              : grade >= 3
              ? ' d$medicineDieFaces Medicina: $medicineDie, tiro $medicineRoll: ${medicineBonus >= 0 ? '+' : ''}$medicineBonus HP.'
              : ' d$medicineDieFaces Medicina: $medicineDie, tiro $medicineRoll, metà: ${medicineBonus >= 0 ? '+' : ''}$medicineBonus HP.';
          risultato =
              'Vitalium Grezzo: ${payWithCoreStats ? '-${amount * 2} Materia e -${amount * 2} Volontà' : '-$amount Oculum'}, +$heal HP.$medicineDetails${heal == 0 && medicineBonus < 0 ? ' Il critico negativo ha annullato la cura, senza infliggere danno.' : ''}';
          break;
        case 'Vitalium Ridefinito':
          currentHpController.text = maxHp().toString();
          for (final art in arti) {
            art.integritaCorrente = artIntegrityEffectiveMaximum(art);
          }
          refullaStatsAttuali();
          risultato =
              'Vitalium Ridefinito: HP, statistiche attuali e integrità delle Art ripristinati ai massimali.';
          break;
        case 'Fiala di Oculum':
          amount = Random().nextInt(4) + 1;
          currentOculumController.text = min(
            oculumTotale(),
            leggiNumero(currentOculumController) + amount,
          ).toString();
          risultato = 'Fiala di Oculum: +$amount Oculum (1d4).';
          break;
        case 'Pergamena della Prigione d Ossa':
          final before = hpCorrenti();
          currentHpController.text = max(0, before - 12).toString();
          applyCondition(
            'stordito',
            duration: 1,
            source: 'Pergamena della Prigione d Ossa',
          );
          risultato =
              'Pergamena della Prigione d Ossa: 12 danni perforanti e Stordito per 1 turno.';
          break;
        case 'Pinna di Pesce Alato':
          applyCondition(
            'nuoto_aria',
            duration: 3,
            source: 'Pinna di Pesce Alato',
          );
          risultato =
              'Pinna di Pesce Alato: Nuoto nell’Aria attivo per 3 turni.';
          break;
      }
      if (item.quantita > 1) {
        item.quantita--;
      } else {
        inventario.remove(item);
      }
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }
}
