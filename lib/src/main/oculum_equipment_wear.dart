part of '../../main.dart';

const oculumEquipmentMaxUses = 1000;
const _wearUsesKey = 'wearUsesRemaining';
const _wearBrokenKey = 'wearBrokenPercent';
const _wearCapacityKey = 'wearCapacity';

int oculumEquipmentCapacity(InventoryItem item) =>
    (1 + item.livelloOggetto.clamp(0, 3).toInt()) *
    (oculumEquipmentMaxUses ~/ 4);

bool oculumEquipmentCanWear(InventoryItem item) =>
    (item.arma || item.protegge) && item.craftData['titleItem'] != true;

int oculumEquipmentUses(InventoryItem item) {
  final capacity = oculumEquipmentCapacity(item);
  if (!oculumEquipmentCanWear(item)) return capacity;
  final savedCapacity = readIntValue(
    item.craftData[_wearCapacityKey],
    fallback: capacity,
  ).clamp(1, oculumEquipmentMaxUses).toInt();
  final savedUses = readIntValue(
    item.craftData[_wearUsesKey],
    fallback: savedCapacity,
  ).clamp(0, savedCapacity).toInt();
  // Editing or forging the item preserves its worn fraction and break state.
  return savedUses == 0 ? 0 : max(1, savedUses * capacity ~/ savedCapacity);
}

int oculumEquipmentBrokenPercent(InventoryItem item) =>
    oculumEquipmentUses(item) == 0
    ? readIntValue(
        item.craftData[_wearBrokenKey],
        fallback: 20,
      ).clamp(20, 30).toInt()
    : 0;

int oculumSpendEquipmentWear(
  InventoryItem item,
  int uses, {
  int Function()? rollBrokenPercent,
}) {
  final before = oculumEquipmentUses(item);
  final spent = min(before, uses);
  if (spent <= 0 || !oculumEquipmentCanWear(item)) return 0;
  final remaining = before - spent;
  item.craftData = {
    ...item.craftData,
    _wearUsesKey: remaining,
    _wearCapacityKey: oculumEquipmentCapacity(item),
    if (remaining == 0)
      _wearBrokenKey:
          (rollBrokenPercent?.call() ?? 20 + Random.secure().nextInt(11))
              .clamp(20, 30)
              .toInt(),
  };
  return spent;
}

bool oculumRepairEquipmentWear(InventoryItem item) {
  if (oculumEquipmentUses(item) == oculumEquipmentCapacity(item)) return false;
  item.craftData = {...item.craftData}
    ..remove(_wearUsesKey)
    ..remove(_wearCapacityKey)
    ..remove(_wearBrokenKey);
  return true;
}

int oculumRestoreEquipmentWear(InventoryItem item, int uses) {
  final before = oculumEquipmentUses(item);
  final capacity = oculumEquipmentCapacity(item);
  final restored = min(uses, capacity - before);
  if (before == 0 || restored <= 0) return 0;
  if (before + restored == capacity) {
    oculumRepairEquipmentWear(item);
  } else {
    item.craftData = {
      ...item.craftData,
      _wearUsesKey: before + restored,
      _wearCapacityKey: capacity,
    };
  }
  return restored;
}

int oculumWearAgainstOpponent(
  int uses, {
  required int wearerLevel,
  required int wearerGrade,
  required int opponentLevel,
  required int opponentGrade,
}) {
  if (uses <= 0) return 0;
  final levelDifference = opponentLevel - wearerLevel;
  final levelPercent = switch (levelDifference) {
    >= 4 => 190,
    >= 1 => 125,
    _ => 100,
  };
  final gradeMultiplierTwice = 2 + max(0, opponentGrade - wearerGrade);
  return (uses * levelPercent * gradeMultiplierTwice + 199) ~/ 200;
}

bool oculumEquipmentWearHostileCombatant(Object? type, Object? side) {
  if (side != 'enemy') return false;
  final normalized = oculumNormalizeText('${type ?? ''}');
  return normalized.contains('mostro') ||
      normalized.contains('monster') ||
      normalized.contains('boss') ||
      normalized.contains('npc');
}

int oculumWeaponBaseWear({
  required int wearerLevel,
  required int weaponLevel,
  required bool boosted,
}) {
  final difference = wearerLevel - weaponLevel;
  if (difference < 0) return 0;
  return boosted ? 3 + (3 * difference + 1) ~/ 2 : 1 + difference;
}

int oculumEquipmentWearValue(InventoryItem item, int baseValue) {
  if (baseValue <= 0 || !oculumEquipmentCanWear(item)) return baseValue;
  final uses = oculumEquipmentUses(item);
  if (uses == 0) {
    return baseValue * oculumEquipmentBrokenPercent(item) ~/ 100;
  }
  // A broken roll can retain up to 30%; an intact item cannot be weaker.
  final capacity = oculumEquipmentCapacity(item);
  return baseValue * max(uses, capacity * 30 ~/ 100) ~/ capacity;
}

int oculumWeaponWearDamage(InventoryItem item) => oculumEquipmentWearValue(
  item,
  item.bonusDanno + item.gradoOggetto.clamp(0, 12).toInt() * 5,
);

enum OculumWearProtectionKind { armor, shield }

OculumWearProtectionKind? oculumWearProtectionKind(InventoryItem item) {
  if (!item.protegge || !oculumEquipmentCanWear(item)) return null;
  final explicit = item.craftData['wearProtectionKind'];
  final catalogue =
      item.craftData['itemFamily'] ?? item.monsterLoot['itemFamily'];
  return switch (explicit ?? catalogue) {
    'armor' => OculumWearProtectionKind.armor,
    'shield' => OculumWearProtectionKind.shield,
    _ =>
      item.craftData['clothing'] == true
          ? OculumWearProtectionKind.armor
          : null,
  };
}

extension _OculumProtectionWearRuntime on _OculumHomePageState {
  int _protectionWearCost(String? packetId) {
    final sourceTag = onlineCombatRequests[packetId]?['sourceTag'];
    if (sourceTag is! String || sourceTag.isEmpty) return 1;
    final bearerTag = sheetTagAt(schedaCorrente);
    final tokens = onlineCombatTokens();
    final source = tokens
        .where((token) => combatTokenMatchesSheet(token, sourceTag))
        .firstOrNull;
    final bearer = tokens
        .where((token) => combatTokenMatchesSheet(token, bearerTag))
        .firstOrNull;
    final sourceSide = source?['side'];
    final bearerSide = bearer?['side'];
    if (sourceSide == null ||
        bearerSide == null ||
        sourceSide == bearerSide ||
        !(oculumEquipmentWearHostileCombatant(source?['type'], sourceSide) ||
            oculumEquipmentWearHostileCombatant(
              tipoSchedaPersonaggio(schedaCorrente),
              bearerSide,
            ))) {
      return 1;
    }
    final level = int.tryParse('${source?['level']}');
    final grade = int.tryParse('${source?['grade']}');
    if (level == null || level < 0 || grade == null || grade < 0) return 1;
    return oculumWearAgainstOpponent(
      1,
      wearerLevel: activeCriticalLevel(),
      wearerGrade: activeCriticalGrade(),
      opponentLevel: level,
      opponentGrade: grade,
    );
  }

  bool recordProtectionWear(
    Iterable<InventoryItem> items, {
    required String? packetId,
  }) {
    if (items.isEmpty ||
        (realtimeService?.isConnected == true &&
            !controlsOnlineCombatSheet(sheetTagAt(schedaCorrente)))) {
      return false;
    }
    final cost = _protectionWearCost(packetId);
    final changes = <String>[];
    for (final item in items) {
      final spent = oculumSpendEquipmentWear(item, cost);
      if (spent == 0) continue;
      final uses = oculumEquipmentUses(item);
      final broken = oculumEquipmentBrokenPercent(item);
      changes.add(
        broken > 0
            ? '${item.nome} −$spent usi, $broken% protezione'
            : '${item.nome} −$spent usi ($uses/${oculumEquipmentCapacity(item)})',
      );
    }
    if (changes.isEmpty) return false;
    aggiungiLog('[USURA] ${changes.join(' · ')}.');
    notifyActiveSheetSummaryChanged();
    return true;
  }
}

extension _OculumWeaponWearRuntime on _OculumHomePageState {
  bool get weaponWearAttackBoosted =>
      tempStatBonus('volonta') > 0 ||
      activeStructuredEffectBonus('volonta') > 0 ||
      conditionalBuffStatBonus('volonta') > 0 ||
      globalQuickBonus('volonta') > 0 ||
      bonusAttaccoRapidoBase() > 0 ||
      runtimeQuickBonus('tiro_attacco') > 0 ||
      activeStructuredEffectBonus('vc') > 0 ||
      activeStructuredEffectBonus('attacco_percentuale') > 0 ||
      readIntValue(planarState['attackRollBonus']) > 0;

  void recordWeaponAttackWear(
    List<InventoryItem> weapons,
    Set<String> targetTags,
    List<Map<String, dynamic>> fightTokens, {
    required bool boosted,
  }) {
    if (weapons.isEmpty || targetTags.isEmpty) return;
    final source = sheetTagAt(schedaCorrente);
    final tokens = fightTokens.where(
      (token) => !const {'dead', 'fled', 'expired'}.contains(token['status']),
    );
    final actingToken = tokens
        .where((token) => combatTokenMatchesSheet(token, source))
        .firstOrNull;
    if (actingToken == null) return;
    final liveTargets = tokens
        .where((token) => targetTags.contains(onlineCombatTokenTag(token)))
        .toList();
    if (liveTargets.isEmpty) return;
    final side = actingToken['side'];
    final wearerIsHostile = oculumEquipmentWearHostileCombatant(
      tipoSchedaPersonaggio(schedaCorrente),
      side,
    );
    final opponents = liveTargets.where(
      (token) =>
          side != null &&
          token['side'] != null &&
          token['side'] != side &&
          (wearerIsHostile ||
              oculumEquipmentWearHostileCombatant(
                token['type'],
                token['side'],
              )),
    );
    final wearerLevel = max(0, leggiNumero(livelloController));
    final fightLevel = activeCriticalLevel();
    final grade = activeCriticalGrade();
    final wearLog = <String>[];
    for (final item in weapons) {
      if (!inventario.contains(item)) continue;
      final base = oculumWeaponBaseWear(
        wearerLevel: wearerLevel,
        weaponLevel: item.livelloOggetto,
        boosted: boosted,
      );
      var cost = base;
      for (final token in opponents) {
        cost = max(
          cost,
          oculumWearAgainstOpponent(
            base,
            wearerLevel: fightLevel,
            wearerGrade: grade,
            opponentLevel: readIntValue(token['level'], fallback: fightLevel),
            opponentGrade: readIntValue(token['grade'], fallback: grade),
          ),
        );
      }
      final spent = oculumSpendEquipmentWear(item, cost);
      if (spent == 0) continue;
      final remaining = oculumEquipmentUses(item);
      final broken = oculumEquipmentBrokenPercent(item);
      wearLog.add(
        broken > 0
            ? '${item.nome} −$spent usi, rotta ($broken% Danni)'
            : '${item.nome} −$spent usi ($remaining/${oculumEquipmentCapacity(item)})',
      );
    }
    if (wearLog.isEmpty) return;
    aggiungiLog('[USURA] ${wearLog.join(' · ')}.');
    notifyActiveSheetSummaryChanged();
  }
}
