part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int oculumDeadlyKatanaPermanent(int attacks) => max(0, attacks) ~/ 3;
InventoryItem oculumDeadlySinsWeapon(
  MonsterBookEntry monster,
  int level,
  int grade,
  String receipt,
) {
  final art = oculumMonsterBookArt(
    monster.copyWith(skillIds: ['deadly_weapon']),
  );
  final ability = oculumEquipmentAbilityFromArt(art.skills.first);
  for (final f in ability.forme) {
    f.livello = '0';
  }
  return InventoryItem(
    nome: 'DeadlySins',
    peso: 1.8,
    quantita: 1,
    note:
        'Una corta lama con tre rune irregolari. Può allungarsi in katana o aprirsi in uno spadone: la forma si sceglie dalla sua abilità. Le rune si adattano all’estetica del portatore dopo nove Riposi Lunghi d’uso.',
    arma: true,
    bonusDanno: 5 + level,
    bonusDifesa: 3,
    elementoDanno: 'taglio',
    livelloOggetto: level,
    gradoOggetto: grade,
    ability: ability,
    craftData: {
      'deadlySinsWeapon': true,
      'deadlyBaseDamage': 5 + level,
      'deadlyForm': 1,
      'deadlyPermanent': 0,
      'deadlySessionGain': 0,
      'deadlyUsedRests': 0,
    },
    monsterLoot: {'id': '$receipt:deadly-weapon', 'monsterId': monster.id},
  );
}

extension _OculumDeadlySins on _OculumHomePageState {
  void deadlyGreatswordHit(Map<String, dynamic> request) {
    final item = deadlyWeapon;
    if (item == null ||
        deadlyWeaponForm != 3 ||
        request['faunaBurst'] == true ||
        !faunaReceipt(
          'deadly-wave:${request['attackGroupId'] ?? request['id']}',
        )) {
      return;
    }
    final percent = readIntValue(
      item.craftData['waveDamagePercent'],
      fallback: 25,
    ).clamp(0, 100);
    unawaited(
      sendFaunaBurst(
        sourceTag: '${request['sourceTag']}',
        centerTag: '${request['targetTag']}',
        receipt: 'deadly-wave:${request['attackGroupId'] ?? request['id']}',
        name: 'DeadlySins · onda d’urto',
        element: 'contundente',
        damage: (readIntValue(request['damage']) * percent / 100).floor(),
        radius: 3,
        maximumTargets: 10,
        damagePerAdditionalTargetPercent: readIntValue(
          item.craftData['waveAdditionalPercent'],
          fallback: 10,
        ),
      ),
    );
  }

  InventoryItem? get deadlyWeapon => inventario
      .where(
        (i) =>
            i.equipaggiata &&
            canEquipInventoryItem(i) &&
            i.craftData['deadlySinsWeapon'] == true,
      )
      .firstOrNull;
  int get deadlyWeaponForm =>
      readIntValue(deadlyWeapon?.craftData['deadlyForm'], fallback: 1);
  int get deadlySwordHitBonus =>
      deadlyWeapon != null && deadlyWeaponForm == 1 ? 6 : 0;
  void refreshDeadlyWeapon(InventoryItem item) {
    final f = readIntValue(item.craftData['deadlyForm'], fallback: 1);
    item.bonusDanno =
        readIntValue(item.craftData['deadlyBaseDamage']) +
        readIntValue(item.craftData['deadlyPermanent']) +
        (f == 2 ? readIntValue(item.craftData['deadlySessionGain']) : 0) +
        (item.craftData['deadlyAdapted'] == true ? 3 : 0);
    item.bonusDifesa = f == 1 ? 3 : 0;
    invalidateDerivedDataCaches();
  }

  void changeDeadlyWeaponForm(int form) {
    final item = deadlyWeapon;
    if (item == null) return;
    item.craftData = {...item.craftData, 'deadlyForm': form.clamp(1, 3)};
    refreshDeadlyWeapon(item);
    aggiungiLog(
      '[DEADLYSINS] Forma ${const ['Spada corta', 'Katana', 'Spadone'][form.clamp(1, 3) - 1]}.',
    );
  }

  void deadlyRecordAttack(String id) {
    final item = deadlyWeapon;
    if (item == null || !faunaReceipt('deadly-attack:$id')) return;
    item.craftData = {...item.craftData, 'deadlyUsedSinceRest': true};
    if (deadlyWeaponForm == 2) {
      item.craftData = {
        ...item.craftData,
        'deadlySessionGain':
            readIntValue(item.craftData['deadlySessionGain']) + 1,
      };
      refreshDeadlyWeapon(item);
      aggiungiLog(
        '[KATANA] +1 Danno accumulato; a fine sessione un terzo diventa permanente.',
      );
    }
  }

  void deadlyNewSession() {
    for (final item in inventario.where(
      (i) => i.craftData['deadlySinsWeapon'] == true,
    )) {
      final gain = oculumDeadlyKatanaPermanent(
        readIntValue(item.craftData['deadlySessionGain']),
      );
      item.craftData = {
        ...item.craftData,
        'deadlyPermanent':
            readIntValue(item.craftData['deadlyPermanent']) + gain,
        'deadlySessionGain': 0,
      };
      refreshDeadlyWeapon(item);
      if (gain > 0) {
        aggiungiLog(
          '[KATANA] Fine sessione: +$gain Danni permanenti; rimossa la parte temporanea.',
        );
      }
    }
  }

  void deadlyLongRest() {
    for (final item in inventario.where(
      (i) =>
          i.craftData['deadlySinsWeapon'] == true &&
          i.craftData['deadlyUsedSinceRest'] == true,
    )) {
      final rests = readIntValue(item.craftData['deadlyUsedRests']) + 1;
      item.craftData = {
        ...item.craftData,
        'deadlyUsedRests': rests,
        'deadlyUsedSinceRest': false,
      };
      if (rests >= 9 && item.craftData['deadlyAdapted'] != true) {
        item.craftData = {...item.craftData, 'deadlyAdapted': true};
        aggiungiLog(
          '[DEADLYSINS] Nono Riposo Lungo d’uso: l’arma si adatta a ${nomeController.text}; +3 Danni permanenti. Aspetto personalizzabile nelle note dell’oggetto.',
        );
      }
      refreshDeadlyWeapon(item);
    }
  }

  int deadlyBaseAttackBonus() {
    if (readIntValue(planarState['deadlyEmpoweredTurns']) <= 0) return 0;
    final strength = hiddenEyeStats.where((s) => s.id == 'forza').firstOrNull;
    return (strength == null ? 0 : hiddenEyeTotal(strength)) *
        (readIntValue(planarState['deadlyEmpoweredForm']) <= 1 ? 1 : 2);
  }

  Future<void> deadlyRegenerate() async {
    final previous = planarState['deadlyLastHpDamage'];
    if (previous is! Map ||
        hpCorrenti() <= 0 ||
        previous['claimed'] == true ||
        readIntValue(previous['hpLost']) <= 0) {
      return;
    }
    final origin = currentSheetScrollId(), id = '${previous['id']}';
    final stat = hiddenEyeStats.where((s) => s.id == 'resistenza').firstOrNull;
    if (stat == null) return;
    await tiraSottotrattoOcchio(
      stat,
      resourceAlreadySpent: true,
      actionLabel: 'Regen del DeadlySins',
      onResolved: (natural, total) {
        if (currentSheetScrollId() != origin ||
            '${(planarState['deadlyLastHpDamage'] as Map?)?['id']}' != id) {
          return;
        }
        final critical = natural == 1 || natural == 20;
        if (total <= 0 && !critical) return;
        final amount = critical
            ? readIntValue(previous['hpLost'])
            : (readIntValue(previous['hpLost']) / 2).ceil();
        previous['claimed'] = true;
        final restored = min(max(0, maxHp() - hpCorrenti()), amount);
        currentHpController.text = '${hpCorrenti() + restored}';
        aggiungiLog(
          '[REGEN DEADLYSINS] Resistenza $total${critical ? ' · critico, anche negativo' : ''}: +$restored Vita dell’ultimo attacco. Nessun recupero di Scudi o HP temporanei.',
        );
        programmaSalvataggio();
      },
    );
  }

  void activateSharedFaunaCooldown(
    List<OculumStructuredEffect> effects,
    OculumAbilityCooldown? used,
  ) {
    if (used == null) return;
    final shared = effects.any(
      (e) => const {
        'monk_ki',
        'monk_seal',
        'deadly_empowered',
        'deadly_weapon',
        'deadly_regen',
        'evergreen_dodge',
        'gran_unstun',
      }.contains(e.target),
    );
    if (!shared) return;
    final targets = effects.map((e) => e.target).toSet();
    for (final skill in [
      ...skills,
      ...inventario.map((i) => i.ability).whereType<CharacterSkill>(),
    ]) {
      if (!skill.forme.any(
        (f) => f.effettiStrutturati.any((e) => targets.contains(e.target)),
      )) {
        continue;
      }
      for (final f in skill.forme) {
        final cd = f.cooldownStrutturato;
        if (cd != null) {
          cd.remaining = used.remaining;
        }
      }
    }
    for (final art in arti) {
      for (final skill in art.skills) {
        if (!skill.effettiPerLivello.any(
          (fs) => fs.any((e) => targets.contains(e.target)),
        )) {
          continue;
        }
        for (final cd in skill.cooldownPerLivello) {
          cd.remaining = used.remaining;
        }
      }
    }
  }
}
