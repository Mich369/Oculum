part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int oculumEvergreenLeafDamage(int die, int spent) =>
    2 * (die.clamp(1, 20) + max(0, spent));

extension _OculumCannonEvergreen on _OculumHomePageState {
  void activateEvergreenLeaves(int spent) {
    final die = Random.secure().nextInt(20) + 1,
        damage = oculumEvergreenLeafDamage(die, spent);
    activeStructuredEffects.add({
      'effectId': 'evergreen_leaves_damage',
      'source': 'Foglie Lama',
      'type': 'danno',
      'target': 'danni',
      'value': damage,
      'mode': 'prossima_azione',
      'remaining': 1,
      'unit': 'azioni',
      'element': 'taglio',
    });
    aggiungiLog(
      '[FOGLIE LAMA] ($die + $spent Oculum) ×2 = $damage Danni da raffica, un solo bersaglio.',
    );
    invalidateDerivedDataCaches();
  }

  bool get evergreenDisguiseProtected =>
      faunaPassive('evergreen_disguise') != null &&
      planarState['evergreenDisguiseBroken'] != true;
  bool faunaTokenIsMonster(Map<String, dynamic> token) {
    if ('${token['monsterBookId'] ?? ''}'.isNotEmpty) return true;
    final type = '${token['type'] ?? ''}'.toLowerCase();
    return type.contains('mostro') ||
        type.contains('monster') ||
        type.contains('boss');
  }

  bool evergreenTargetAllowed(
    Map<String, dynamic> target, {
    required Map<String, dynamic> actingToken,
  }) {
    if (!faunaTokenIsMonster(actingToken)) return true;
    final tag = onlineCombatTokenTag(target),
        index = localSheetIndexForOculumTag(onlineCombatTokenTag(target));
    final json = index >= 0 ? schedaJsonAt(index) : target;
    final public = json['faunaPublic'] as Map? ?? {};
    if (public['evergreenDisguiseProtected'] != true &&
        target['evergreenDisguiseProtected'] != true) {
      return true;
    }
    final key = 'evergreen:$maskedCurrentTurnKey:$tag';
    final attempts = Map<String, dynamic>.from(
      planarState['evergreenAttempts'] as Map? ?? {},
    );
    if (!attempts.containsKey(key)) {
      attempts[key] = Random.secure().nextInt(100) >= 50;
      planarState['evergreenAttempts'] = attempts;
      aggiungiLog(
        '[COSTUME] ${target['name'] ?? tag}: ${attempts[key] == true ? 'il mostro decide di attaccare' : 'il mostro esita; scegli un altro bersaglio senza spendere risorse'}.',
      );
    }
    return attempts[key] == true;
  }

  void evergreenNoteAggression(List<String> targets) {
    if (!evergreenDisguiseProtected) return;
    final selected = onlineCombatTokens().where(
      (t) => targets.contains(onlineCombatTokenTag(t)),
    );
    if (selected.any(faunaTokenIsMonster)) {
      planarState['evergreenDisguiseBroken'] = true;
      aggiungiLog(
        '[COSTUME] Hai attaccato un mostro: l’esitazione termina fino a fine scontro.',
      );
    }
  }

  void granRemoveStun() {
    for (final condition in activeConditions.toList()) {
      final id = condition.conditionType;
      if (id == 'stordito' ||
          id == 'stun' ||
          id == 'stunned' ||
          id.startsWith('stun_')) {
        removeCondition(condition, force: true);
      }
    }
    aggiungiLog(
      '[MA PORCA TROIA!] Stun rimossi. Nessuna Azione o Reazione consumata.',
    );
  }

  bool get faunaFirearmEquipped => inventario.any(
    (i) =>
        i.equipaggiata &&
        (i.craftData['weaponType'] == 'firearm' ||
            RegExp(
              'fucile|pistola|mitra|cannone',
              caseSensitive: false,
            ).hasMatch(i.nome)),
  );
  bool granBreakShields(Map request) {
    if (request['granCannon'] != true) return false;
    if (scudoCritico() > 0) {
      scudoCriticoController.text = '${scudoCritico() - 1}';
      aggiungiLog('[CANNONE] Distrutto uno Scudo critico, con priorità.');
      return true;
    } else {
      var remaining = 150;
      final ocu = min(remaining, max(0, scudoOculum()));
      remaining -= ocu;
      scudoOculumController.text = '${scudoOculum() - ocu}';
      final ordinary = min(remaining, max(0, scudo()));
      scudoController.text = '${scudo() - ordinary}';
      aggiungiLog(
        '[CANNONE] Spezzati $ocu Scudo Oculum e $ordinary Scudo normale; nessun danno alla Vita dalla rottura.',
      );
    }
    return false;
  }

  void faunaRecordBaseAttack(String group) {
    if (faunaPassive('gran_base_counter') == null ||
        !faunaReceipt('gran-base:$group')) {
      return;
    }
    final count = readIntValue(planarState['granBaseAttacks']) + 1;
    final threshold = max(
      1,
      readIntValue(
        faunaPassive('gran_base_counter')!.valueExpression,
        fallback: 9,
      ),
    );
    planarState['granBaseAttacks'] = count % threshold;
    if (count % threshold == 0) {
      addOculum(1);
      aggiungiLog('[ATTACCHI BASE] $threshold attacchi eseguiti: +1 Oculum.');
    }
  }

  void faunaConfirmedKills(Iterable<Map> enemies, String encounter) {
    for (final enemy in enemies) {
      final source =
          '${enemy['killerTag'] ?? enemy['lastDamageSourceTag'] ?? ''}';
      if (source.isEmpty) continue;
      if (canManagePartyQuests) {
        final confirmations = Map<String, dynamic>.from(
          partyChest['confirmedFaunaKills'] as Map? ?? {},
        );
        final key = 'death:${enemy['monsterSheetTag'] ?? enemy['id']}';
        confirmations[key] = {
          ...Map<String, dynamic>.from(confirmations[key] as Map? ?? {}),
          ...oculumCopyJsonTree(enemy),
        };
        partyChest['confirmedFaunaKills'] = confirmations;
      }
      faunaForOwnedSheet(source, () {
        final kills = (planarState['faunaConfirmedKillReceipts'] as List? ?? [])
            .map((e) => '$e')
            .toSet();
        final id = 'death:${enemy['monsterSheetTag'] ?? enemy['id']}';
        if (!kills.add(id)) return;
        planarState['faunaConfirmedKillReceipts'] = kills.toList();
        final defeated = monsterBookEntryById(
          '${enemy['monsterBookId'] ?? ''}',
        );
        if (defeated?.encounterRules['empathic'] == true) {
          planarState['banditVendetta'] = true;
          for (final token in _writableOnlineCombatTokens().where(
            (t) => onlineCombatTokenTag(t) == source,
          )) {
            token['faunaPublic'] = {
              ...Map<String, dynamic>.from(token['faunaPublic'] as Map? ?? {}),
              'banditVendetta': true,
            };
          }
          final rules = defeated!.encounterRules;
          final amount =
              readIntValue(rules['killerObserBase'], fallback: 10) +
              max(0, readIntValue(enemy['level'])) *
                  readIntValue(rules['killerObserPerLevel'], fallback: 3);
          final lost = min(max(0, leggiNumero(obserController)), amount);
          obserController.text =
              '${max(0, leggiNumero(obserController)) - lost}';
          aggiungiLog(
            '[OBSER] −$lost Obser personali: hai ucciso una creatura empatica. Sottrazione applicata una sola volta; cassa comune esclusa.',
          );
        }
        if (faunaPassive('bone_kill_regen') != null) {
          if (hpCorrenti() > 0) {
            currentHpController.text = '${min(maxHp(), hpCorrenti() + 5)}';
          }
          addOculum(1);
        }
        if (faunaPassive('feralis_kill_rebirth') != null) {
          final hp = hpCorrenti();
          if (hp > 0) {
            currentHpController.text = '${min(maxHp(), hp + (hp / 2).ceil())}';
          }
          addOculum((max(0, oculumTotale()) / 2).ceil());
          aggiungiLog(
            '[RINASCITA] Uccisione confermata: recuperata metà della Vita e dell’Oculum correnti, entro i massimi.',
          );
        }
        if (schedePersonaggio[schedaCorrente]['monsterBookSourceId'] ==
            'granscostumato') {
          aggiungiLog('oh merda l’ho rotto');
        }
      });
      for (final helper
          in ((enemy['finisher'] as Map?)?['helpers'] as List? ?? [])
              .whereType<Map>()) {
        final helperTag = '${helper['sheetTag'] ?? helper['sourceTag'] ?? ''}';
        if (helperTag.isEmpty || helperTag == source) continue;
        faunaForOwnedSheet(helperTag, () {
          if (faunaPassive('bone_kill_regen') != null &&
              faunaReceipt(
                'assist:${enemy['monsterSheetTag'] ?? enemy['id']}',
              ) &&
              hpCorrenti() > 0) {
            currentHpController.text = '${min(maxHp(), hpCorrenti() + 2)}';
            aggiungiLog('[ASSIST] Regen per kill: +2 Vita.');
          }
        });
      }
    }
  }

  void resetCannonEvergreenFight() {
    for (final key in [
      'evergreenDisguiseBroken',
      'evergreenAttempts',
      'granBaseAttacks',
      'granLeave',
      'granCannon',
      'evergreenDodge',
    ]) {
      planarState.remove(key);
    }
  }
}
