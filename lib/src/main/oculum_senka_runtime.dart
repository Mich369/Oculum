part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int oculumSenkaCloneLimit(int level) => max(1, min(16, 2 * max(0, level)));
int oculumSenkaShieldRecovery(int ownerLevel, int enemyLevel) =>
    min(6, 1 + max(0, enemyLevel - ownerLevel));
int oculumSenkaBrokenRepair(int roll) => (max(0, roll) * 3 + 3) ~/ 4;

extension _OculumSenkaRuntime on _OculumHomePageState {
  InventoryItem? get senkaMaskItem => inventario
      .where((i) => i.quantita > 0 && i.craftData['senkaMask'] == true)
      .firstOrNull;
  bool get senkaMaskActive => senkaMaskItem?.equipaggiata == true;
  bool get senkaIsClone => planarState['senkaClone'] == true;
  Map<String, dynamic> get senkaRuntime {
    if (planarState['senka'] is! Map<String, dynamic>) {
      planarState['senka'] = Map<String, dynamic>.from(
        planarState['senka'] as Map? ?? {},
      );
    }
    return planarState['senka'] as Map<String, dynamic>;
  }

  bool setSenkaMaskManifested(InventoryItem item, bool active) {
    if (!inventario.contains(item) ||
        item.quantita <= 0 ||
        item.craftData['senkaMask'] != true) {
      return false;
    }
    if (item.equipaggiata == active) return true;
    if (active && readIntValue(senkaRuntime['disabledTurns']) > 0) {
      aggiungiLog(
        'La maschera si sta ricomponendo: attendi il prossimo turno personale.',
      );
      return false;
    }
    if (active && !canEquipInventoryItem(item)) return false;
    final beforeMax = maxHp();
    final beforeHp = hpCorrenti();
    final beforeRawOculum = leggiNumero(currentOculumController);
    final storedBaseHp = readIntValue(senkaRuntime['baseHpAtEquip']);
    final storedRawOculum = readIntValue(senkaRuntime['rawOculumAtEquip']);
    setState(() {
      if (!active) {
        final reserveHp = max(
          0,
          min(readIntValue(senkaRuntime['hpReserve']), beforeHp - storedBaseHp),
        );
        currentHpController.text = max(0, beforeHp - reserveHp).toString();
        final usedReserve = (storedRawOculum - beforeRawOculum).clamp(0, 5);
        currentOculumController.text = '${beforeRawOculum + usedReserve}';
        scudoOculumController.text = max(
          0,
          leggiNumero(scudoOculumController) -
              max(0, item.scudoIntegritaOculumCorrente),
        ).toString();
        senkaRuntime.remove('shadowUntilTurn');
      }
      item.equipaggiata = active;
      invalidateDerivedDataCaches();
      if (active) {
        final hpReserve = max(0, maxHp() - beforeMax);
        senkaRuntime['baseHpAtEquip'] = beforeHp;
        senkaRuntime['rawOculumAtEquip'] = beforeRawOculum;
        senkaRuntime['hpReserve'] = hpReserve;
        currentHpController.text = '${beforeHp + hpReserve}';
        final maximum = itemOculumShieldBonus(item);
        if (item.scudoIntegritaOculumCorrente < 0) {
          item.scudoIntegritaOculumCorrente = maximum;
        }
        scudoOculumController.text =
            '${leggiNumero(scudoOculumController) + max(0, item.scudoIntegritaOculumCorrente)}';
        final fight = onlineCombatEncounterId.isNotEmpty
            ? onlineCombatEncounterId
            : selectedMasterInitiativeGroupId;
        if (currentCombatIsActive() &&
            senkaRuntime['normalShieldFight'] != fight) {
          senkaRuntime['normalShieldFight'] = fight;
          scudoController.text =
              '${leggiNumero(scudoController) + readIntValue(item.craftData['onEquipNormalShield'], fallback: 10)}';
        }
      } else {
        currentHpController.text = min(hpCorrenti(), maxHp()).toString();
      }
    });
    aggiungiLog(
      'Maschera ${active ? 'manifestata' : 'rimossa'}: nessuna Azione o Reazione.',
    );
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
    return true;
  }

  int repairSenkaMaskShield(int roll) {
    final item = senkaMaskItem;
    if (item == null || roll <= 0) return 0;
    final maximum = itemOculumShieldBonus(item);
    final before = item.scudoIntegritaOculumCorrente < 0
        ? maximum
        : item.scudoIntegritaOculumCorrente;
    if (before >= maximum) return 0;
    final recovery = before <= 0 ? oculumSenkaBrokenRepair(roll) : roll;
    item.scudoIntegritaOculumCorrente = max(0, before) + recovery;
    if (item.equipaggiata) {
      scudoOculumController.text =
          '${leggiNumero(scudoOculumController) + recovery}';
    }
    invalidateDerivedDataCaches();
    programmaSalvataggio();
    return recovery;
  }

  void senkaRest() {
    final item = senkaMaskItem;
    if (item == null) return;
    item.scudoIntegritaOculumCorrente = max(
      itemOculumShieldBonus(item),
      item.scudoIntegritaOculumCorrente,
    );
    senkaRuntime.remove('disabledTurns');
  }

  void senkaConfirmDamage(Map request) {
    final item = senkaMaskItem;
    if (item == null ||
        !item.equipaggiata ||
        item.scudoIntegritaOculumCorrente <= 0 ||
        '${request['sourceTag']}' != sheetTagAt(schedaCorrente)) {
      return;
    }
    final receipt = request['damageReceipt'];
    if (receipt is! Map ||
        [
              'hpLost',
              'shieldLost',
              'oculumShieldLost',
              'temporaryHpLost',
            ].fold<int>(0, (n, k) => n + readIntValue(receipt[k])) <=
            0) {
      return;
    }
    final id = '${request['attackGroupId'] ?? request['id'] ?? ''}';
    if (id.isEmpty) return;
    final claimed = (senkaRuntime['damageClaims'] as List? ?? [])
        .map((e) => '$e')
        .toList();
    if (claimed.contains(id)) return;
    claimed.add(id);
    senkaRuntime['damageClaims'] = claimed.length > 300
        ? claimed.sublist(claimed.length - 300)
        : claimed;
    final recovery = min(
      max(0, itemOculumShieldBonus(item) - item.scudoIntegritaOculumCorrente),
      oculumSenkaShieldRecovery(
        leggiNumero(livelloController),
        readIntValue(request['targetLevel']),
      ),
    );
    item.scudoIntegritaOculumCorrente += recovery;
    scudoOculumController.text =
        '${leggiNumero(scudoOculumController) + recovery}';
    if (recovery > 0) {
      aggiungiLog('Maschera: +$recovery Scudo Oculum sui Danni confermati.');
    }
    programmaSalvataggio();
  }

  String get senkaFightKey => onlineCombatEncounterId.isNotEmpty
      ? onlineCombatEncounterId
      : selectedMasterInitiativeGroupId;
  int get senkaClonesCreated => senkaRuntime['cloneFight'] == senkaFightKey
      ? readIntValue(senkaRuntime['cloneCount'])
      : 0;

  bool get senkaCanCreateClone =>
      !senkaIsClone &&
      currentCombatIsActive() &&
      senkaClonesCreated <
          oculumSenkaCloneLimit(leggiNumero(livelloController));

  int createSenkaShadowClone(int hp) {
    if (!senkaCanCreateClone || hp <= 0) return -1;
    final createdBefore = senkaClonesCreated;
    final stats = {
      for (final key in ['resilienza', 'volonta', 'materia', 'oculum'])
        key: currentStatValue(key),
    };
    final damage = dannoTotale(), defense = difesa();
    final traits = [
      for (final stat in hiddenEyeStats)
        {
          ...stat.toJson(),
          'valore':
              hiddenEyeTotal(stat) -
              oculumHiddenEyeDerivedBonusFor(
                level: leggiNumero(livelloController),
                id: stat.id,
                resilienza: stats['resilienza']!,
                volonta: stats['volonta']!,
                materia: stats['materia']!,
                oculum: stats['oculum']!,
                karma: karmaTotale(),
              ),
        },
    ];
    final copiedSkills = [
      for (final skill in skills) CharacterSkill.fromJson(skill.toJson()),
    ];
    final copiedArts = [for (final art in arti) art.toJson()];
    final index = createShadowCloneSheet(
      hp: hp,
      duration: 0,
      source: 'Clone di Senka',
      asSummon: true,
      copyResilience: true,
      summonKind: 'senka_shadow',
      summonSkills: copiedSkills,
      summonDescription:
          'Ombra di Senka: una Reazione veloce alla nascita, poi soltanto una Reazione normale al proprio turno. Non può generare cloni.',
    );
    if (index < 0) return -1;
    final clone = schedePersonaggio[index];
    clone['arti'] = oculumCopyJsonTree(copiedArts);
    clone['hiddenEyeStats'] = traits;
    for (final entry in stats.entries) {
      clone[entry.key] = '${entry.value}';
      clone['current${entry.key[0].toUpperCase()}${entry.key.substring(1)}'] =
          '${entry.value}';
    }
    clone['normalCurrentOculum'] = '${stats['oculum']}';
    clone['manualHpMaximumAdjustment'] =
        hp - max(1, stats['resilienza']!) * moltiplicatoreHp();
    clone['derivedMaxHp'] = hp;
    clone['planarRuntime'] = {
      'senkaClone': true,
      'senkaCloneFight': senkaFightKey,
    };
    clone['derivedReazioni'] = 1;
    clone['derivedReazioniVeloci'] = 0;
    clone['reazioni'] = 1;
    clone['reazioniVeloci'] = 0;
    // Effective core stats already contain the transformation and other bonuses.
    // Reproduce only the remaining damage/defense delta, without copying gear.
    final baseDamage =
        stats['volonta']! + bonusLivelloGrado() + bonusAttaccoRapido() + vc();
    final baseDefense =
        (stats['materia']! + stats['volonta']! + bonusLivelloGrado()) ~/ 2 +
        bonusDifesaRapido();
    clone['buffMalusRapidi'] =
        '@Danni${damage - baseDamage >= 0 ? '+' : ''}${damage - baseDamage}\n@Difesa${defense - baseDefense >= 0 ? '+' : ''}${defense - baseDefense}';
    senkaRuntime['cloneFight'] = senkaFightKey;
    senkaRuntime['cloneCount'] = createdBefore + 1;
    salvaSchedaCorrenteInMemoria();
    programmaSalvataggio();
    return index;
  }

  int absorbSenkaShadows() {
    if (senkaIsClone || !currentCombatIsActive()) return 0;
    final owner = sheetTagAt(schedaCorrente);
    final clones = schedePersonaggio
        .where(
          (s) =>
              s['isSummon'] == true &&
              s['summonKind'] == 'senka_shadow' &&
              s['summonExpired'] != true &&
              '${s['summonerTag']}' == owner &&
              '${s['summonEncounterId']}' == senkaFightKey &&
              readIntValue(s['currentHp']) > 0,
        )
        .toList();
    if (clones.isEmpty) return 0;
    var hp = 0;
    final totals = {'volonta': 0, 'materia': 0, 'oculum': 0};
    final tags = <String>{};
    for (final clone in clones) {
      hp += max(0, readIntValue(clone['currentHp']));
      for (final key in totals.keys) {
        totals[key] = totals[key]! + max(0, readIntValue(clone[key]));
      }
      tags.add('${clone['sheetTag'] ?? clone['id']}');
      clone['summonExpired'] = true;
      clone['currentHp'] = '0';
    }
    hpTempController.text = '${hpTemp() + hp}';
    senkaRuntime['fusionTemporaryHpRemaining'] =
        readIntValue(senkaRuntime['fusionTemporaryHpRemaining']) + hp;
    for (final entry in totals.entries) {
      activeStructuredEffects.add({
        'effectId':
            'senka_fusion_${DateTime.now().microsecondsSinceEpoch}_${entry.key}',
        'source': 'Confluenza delle Ombre',
        'type': 'modifica_statistica',
        'target': entry.key,
        'mode': 'finche_attivo',
        'value': entry.value ~/ 10,
        'remaining': 1,
        'unit': 'fight',
        'senkaFusion': true,
      });
    }
    final activeTag = masterInitiativeTokens.isEmpty
        ? null
        : masterInitiativeTokens[masterInitiativeActiveIndex.clamp(
            0,
            masterInitiativeTokens.length - 1,
          )]['id'];
    masterInitiativeTokens.removeWhere(
      (t) => tags.contains('${t['sheetTag'] ?? t['id']}'),
    );
    final preservedIndex = masterInitiativeTokens.indexWhere(
      (t) => t['id'] == activeTag,
    );
    masterInitiativeActiveIndex = preservedIndex >= 0
        ? preservedIndex
        : (masterInitiativeTokens.isEmpty
              ? 0
              : masterInitiativeActiveIndex.clamp(
                  0,
                  masterInitiativeTokens.length - 1,
                ));
    invalidateDerivedDataCaches();
    aggiungiLog(
      'Confluenza: ${clones.length} ombre assorbite, +$hp HP temporanei; VOL/MAT/OCU ${totals.values.map((n) => n ~/ 10).join('/')}.',
    );
    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
    return clones.length;
  }

  bool activateSenkaEffect(OculumStructuredEffect effect, int value) {
    switch (effect.target) {
      case 'senka_shadow_clone':
        createSenkaShadowClone(value);
        return true;
      case 'senka_shadow_fusion':
        absorbSenkaShadows();
        return true;
      case 'senka_shadow_form':
        senkaRuntime['shadowUntilTurn'] = playerReportedTurn + 1;
        return true;
    }
    return false;
  }

  void senkaTurnStart() {
    rechargeExplosiveCards();
    if (senkaMaskItem == null && !senkaIsClone) return;
    if (readIntValue(senkaRuntime['disabledTurns']) > 0) {
      senkaRuntime['disabledTurns'] =
          readIntValue(senkaRuntime['disabledTurns']) - 1;
    }
    if (readIntValue(senkaRuntime['shadowUntilTurn']) <= playerReportedTurn) {
      senkaRuntime.remove('shadowUntilTurn');
    }
  }

  void senkaFightEnd() {
    if (senkaMaskItem == null && !senkaIsClone) return;
    senkaRuntime.remove('cloneFight');
    senkaRuntime.remove('cloneCount');
    senkaRuntime.remove('normalShieldFight');
    senkaRuntime.remove('shadowUntilTurn');
    hpTempController.text =
        '${max(0, hpTemp() - readIntValue(senkaRuntime.remove('fusionTemporaryHpRemaining')))}';
    activeStructuredEffects.removeWhere((e) => e['senkaFusion'] == true);
  }
}
