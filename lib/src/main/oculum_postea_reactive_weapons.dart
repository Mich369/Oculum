part of '../../main.dart';

bool oculumIsFreeProtectiveImpact(Map request) =>
    request['oculumShieldBreakImpact'] == true ||
    request['posteaArmorShock'] == true ||
    request['gunFollowup'] == true;

extension _OculumPosteaReactiveWeapons on _OculumHomePageState {
  InventoryItem? get posteaPerfectShield => protezioniEquipaggiate()
      .where((item) => item.craftData['posteaPerfectShield'] == true)
      .firstOrNull;

  int get posteaHomingPlasmaAttackBonus => armiEquipaggiate().fold(
    0,
    (best, item) =>
        max(best, readIntValue(item.craftData['posteaHomingPlasmaHitBonus'])),
  );

  bool get posteaArmorCoversWeakPoints => protezioniEquipaggiate().any((item) {
    if (item.craftData['posteaReactiveArmor'] != true &&
        item.craftData['cyberPostea'] != true) {
      return false;
    }
    final capacity = itemShieldBonus(item);
    return capacity > 0 && itemIntegrityShieldCurrent(item) * 4 >= capacity * 3;
  });

  bool get wieldsDreadBow =>
      armaPiuForteEquipaggiata()?.craftData['dreadBowIgnoresPhysicalArmor'] ==
      true;

  int get natureThornWhipDamage {
    final race = oculumNormalizeText(razzaController.text);
    if (!const {
          'figlio di madre natura',
          'figlia di madre natura',
          'figli di madre natura',
          'figlie di madre natura',
        }.contains(race) ||
        !armiEquipaggiate().any(
          (item) => item.craftData['natureThornWhip'] == true,
        )) {
      return 0;
    }
    return scoutPowerReserveForActiveSheet().current ~/ 4;
  }

  bool isDreadBowPhysicalArmor(InventoryItem item) =>
      item.protegge &&
      (oculumWearProtectionKind(item) == OculumWearProtectionKind.armor ||
          item.craftData['wearProtectionKind'] == 'armor' ||
          item.craftData['itemFamily'] == 'armor' ||
          item.craftData['clothing'] == true) &&
      item.craftData['intangibleArmor'] != true;

  String posteaGearFight(String encounter) =>
      '$encounter:${combatSubtraitExperienceFightId(encounter)}';

  Map get posteaReactiveGear =>
      planarState['posteaReactiveGear'] as Map? ?? const {};

  int get posteaParryBonus {
    final encounter = onlineCombatEncounterId;
    return posteaPerfectShield != null &&
            encounter.isNotEmpty &&
            currentCombatIsActive() &&
            posteaReactiveGear['fight'] == posteaGearFight(encounter)
        ? max(0, readIntValue(posteaReactiveGear['parries']))
        : 0;
  }

  void _grantPosteaShield(
    String key,
    int amount,
    int cap, {
    int parries = 0,
    required String encounter,
  }) {
    final state = Map<String, dynamic>.from(posteaReactiveGear);
    final current = min(scudo(), max(0, readIntValue(state[key])));
    final gained = min(max(0, amount), max(0, cap - current));
    final fight = posteaGearFight(encounter);
    planarState['posteaReactiveGear'] = {
      ...state,
      key: current + gained,
      'fight': fight,
      'parries':
          (state['fight'] == fight ? readIntValue(state['parries']) : 0) +
          parries,
    };
    if (gained > 0) {
      scudoController.text = '${leggiNumero(scudoController) + gained}';
      clearNormalShieldBreakPenaltyIfProtected();
    }
    invalidateDerivedDataCaches();
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
  }

  int posteaReactiveShieldPoints(int total) {
    return min(
      total,
      max(0, readIntValue(posteaReactiveGear['swordShield'])) +
          max(0, readIntValue(posteaReactiveGear['parryShield'])),
    );
  }

  int spendPosteaReactiveShield(int points) {
    final state = posteaReactiveGear;
    var remaining = points;
    for (final key in const ['swordShield', 'parryShield']) {
      final before = max(0, readIntValue(state[key]));
      final spent = min(before, remaining);
      if (spent <= 0) continue;
      state[key] = before - spent;
      remaining -= spent;
    }
    return remaining;
  }

  void confirmPosteaSwordHit(Map request) {
    if (request['posteaSwordAttack'] != true ||
        request['faunaBurst'] == true ||
        request['outcome'] != OculumAttackOutcome.full.name) {
      return;
    }
    final receipt = request['damageReceipt'];
    if (receipt is! Map ||
        !const [
          'hpLost',
          'temporaryHpLost',
          'shieldLost',
          'oculumShieldLost',
        ].any((key) => readIntValue(receipt[key]) > 0)) {
      return;
    }
    final encounter = '${request['encounterId'] ?? ''}';
    final packet = '${request['attackGroupId'] ?? request['id'] ?? ''}';
    if (encounter.isEmpty || packet.isEmpty) return;
    faunaForOwnedSheet('${request['sourceTag'] ?? ''}', () {
      if (onlineCombatEncounterId != encounter || !currentCombatIsActive()) {
        return;
      }
      final sword = inventario
          .where(
            (item) =>
                item.arma &&
                item.equipaggiata &&
                canEquipInventoryItem(item) &&
                item.craftData['posteaReactiveSword'] == true,
          )
          .firstOrNull;
      if (sword == null || !faunaReceipt('postea-sword:$encounter:$packet')) {
        return;
      }
      final cap = max(
        0,
        readIntValue(sword.craftData['posteaSwordShieldCap'], fallback: 100),
      );
      _grantPosteaShield('swordShield', cap, cap, encounter: encounter);
    });
  }

  void confirmPosteaPerfectParry(
    Map request, {
    required int attack,
    required int defense,
    required int natural,
    required String choice,
  }) {
    final shield = posteaPerfectShield;
    final encounter = '${request['encounterId'] ?? ''}';
    final packet = '${request['id'] ?? ''}';
    if (shield == null ||
        encounter.isEmpty ||
        packet.isEmpty ||
        choice != 'cm' ||
        natural < 2 ||
        !oculumDefenseGrantsFreeReaction(attack, defense) ||
        !faunaReceipt('postea-parry:$encounter:$packet')) {
      return;
    }
    _grantPosteaShield(
      'parryShield',
      readIntValue(shield.craftData['posteaParryShieldGain'], fallback: 25),
      readIntValue(shield.craftData['posteaParryShieldCap'], fallback: 75),
      encounter: encounter,
      parries: 1,
    );
  }
}
