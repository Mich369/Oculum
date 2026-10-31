part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

bool oculumIsAntiCorruptionStone(InventoryItem item) =>
    item.quantita > 0 &&
    (item.craftData['antiCorruptionStone'] == true ||
        oculumNormalizeText(item.nome).replaceAll('-', ' ') ==
            'pietra anti corruzione');

InventoryItem oculumAntiCorruptionStone() => InventoryItem(
  nome: 'Pietra anti-corruzione',
  peso: .1,
  quantita: 1,
  note:
      'Purificazione del Manichino di Baghest: un’Azione; '
      'Riflessi propri + Memoria base del Manichino contro i suoi Riflessi. '
      'Si consuma soltanto al successo. Non è una dose alchemica.',
  craftData: {'antiCorruptionStone': true},
);

extension _OculumBaghestPuppet on _OculumHomePageState {
  void initializeBaghestPuppet() {
    if (faunaCurrentMonsterId != 'manichino_baghest' ||
        getCondition('corruzione') != null ||
        schedePersonaggio[schedaCorrente]['baghestPurified'] == true) {
      return;
    }
    activeConditions.add(
      OculumConditionInstance(
        id: 'baghest-red:${sheetTagAt(schedaCorrente)}',
        conditionType: 'corruzione',
        category: OculumConditionCategory.special,
        durationType: OculumConditionDurationType.permanent,
        source: 'Baghest',
        metadata: {
          ...corruptionInfectionMetadata({
            'corruptionKind': 'rossa',
            'sourceTag': 'BAGHEST',
            'level': leggiNumero(livelloController),
          }, schedaCorrente),
          'elapsedNights': 3,
          'sourceName': 'Baghest',
          'baghestPuppet': true,
        },
      ),
    );
  }

  bool canPurifyBaghestToken(Map<String, dynamic> token) {
    final index = localSheetIndexForOculumTag(publicInitiativeSourceTag(token));
    if (index < 0) return false;
    final conditions = index == schedaCorrente
        ? activeConditions.map((c) => c.toJson()).toList()
        : schedePersonaggio[index]['conditions'];
    final corrupted =
        conditions is List &&
        conditions.whereType<Map>().any(
          (c) =>
              c['conditionType'] == 'corruzione' &&
              c['metadata'] is Map &&
              oculumCorruptionKind(c['metadata']) == 'rossa',
        );
    return index >= 0 &&
        corrupted &&
        schedePersonaggio[index]['monsterBookSourceId'] ==
            'manichino_baghest' &&
        schedePersonaggio[index]['baghestPurified'] != true &&
        !const {'dead', 'fled', 'expired'}.contains(token['status']) &&
        token['outsideFight'] != true;
  }

  /// The Master resolves both rolls once. A connected player cannot mutate an
  /// enemy sheet or consume an item on another player's behalf.
  Future<bool> purifyBaghestPuppet(
    String actorTag,
    String targetTag, {
    int? actorNatural,
    int? targetNatural,
  }) async {
    if (onlineMasterApprovalRequired && !realtimeIsMasterRole) return false;
    final actorIndex = localSheetIndexForOculumTag(actorTag);
    final targetIndex = localSheetIndexForOculumTag(targetTag);
    if (actorIndex < 0 || targetIndex < 0 || actorIndex == targetIndex) {
      return false;
    }
    if (onlineMasterApprovalRequired &&
        readBoolValue(schedePersonaggio[actorIndex]['realtimeSharedSheet']) &&
        (readBoolValue(
              schedePersonaggio[actorIndex]['realtimeReadOnlyByMaster'],
            ) ||
            readBoolValue(
              schedePersonaggio[actorIndex]['realtimeRestrictedByMaster'],
            ))) {
      return false;
    }
    final targetToken = masterInitiativeTokens
        .where((t) => combatTokenMatchesSheet(t, targetTag))
        .firstOrNull;
    final actorToken = masterInitiativeTokens
        .where((t) => combatTokenMatchesSheet(t, actorTag))
        .firstOrNull;
    if (targetToken == null ||
        actorToken == null ||
        !canPurifyBaghestToken(targetToken) ||
        !masterInitiativeTokenCanAct(actorToken) ||
        actorToken['outsideFight'] == true) {
      return false;
    }
    final fightId = '${targetToken['fightInstanceId'] ?? ''}';
    final encounter = selectedMasterInitiativeGroupId;
    final original = schedaCorrente;
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    void load(int index) {
      schedaCorrente = index;
      caricaStatoDaJson(schedePersonaggio[index]);
      ripristinaImpostazioniGlobali(global);
    }

    try {
      load(targetIndex);
      final memory = hiddenEyeStats.where((s) => s.id == 'memoria').firstOrNull;
      final baseMemory =
          (memory?.valore ?? 0) +
          oculumHiddenEyeDerivedBonusFor(
            level: leggiNumero(livelloController),
            id: 'memoria',
            resilienza: leggiNumero(resilienzaController),
            volonta: leggiNumero(volontaController),
            materia: leggiNumero(materiaController),
            oculum: leggiNumero(oculumController),
            karma: 0,
          );
      final defender = hiddenEyeStats
          .where((s) => s.id == 'riflessi')
          .firstOrNull;
      final defenseBonus = defender == null
          ? 0
          : hiddenEyeTotal(defender) + hiddenEyeStatRollQuickBonus(defender);
      salvaSchedaCorrenteInMemoria();
      load(actorIndex);
      var stone = inventario.where(oculumIsAntiCorruptionStone).firstOrNull;
      if (stone == null) {
        aggiungiLog(
          '[PURIFICAZIONE] Serve una Pietra anti-corruzione; nessuna Azione spesa.',
        );
        salvaSchedaCorrenteInMemoria();
        return false;
      }
      if (!await requestUtilitySpend('azione', preferFreeReaction: false)) {
        return false;
      }
      if (selectedMasterInitiativeGroupId != encounter ||
          '${targetToken['fightInstanceId'] ?? ''}' != fightId ||
          !canPurifyBaghestToken(targetToken)) {
        return false;
      }
      salvaSchedaCorrenteInMemoria();
      load(targetIndex);
      final defenseDie = targetNatural ?? tiraD20();
      salvaSchedaCorrenteInMemoria();
      load(actorIndex);
      // Reload creates InventoryItem instances; never consume a stale item
      // reference captured before switching to the defending sheet.
      stone = inventario.where(oculumIsAntiCorruptionStone).firstOrNull;
      if (stone == null) return false;
      if (defenseDie < 1 || defenseDie > 20) return false;
      final reflex = hiddenEyeStats
          .where((s) => s.id == 'riflessi')
          .firstOrNull;
      final attackBonus = reflex == null
          ? 0
          : hiddenEyeTotal(reflex) + hiddenEyeStatRollQuickBonus(reflex);
      final attackDie = actorNatural ?? tiraD20();
      final attack = attackDie + attackBonus + baseMemory;
      final defense = defenseDie + defenseBonus;
      if (attackDie < 1 || attackDie > 20) return false;
      final success = attack > defense; // A tie preserves the defense.
      final message =
          '[PURIFICAZIONE] ${nomeSchedaPersonaggio(actorIndex)}: '
          '$attackDie + Riflessi $attackBonus + Memoria base $baseMemory = $attack '
          'contro $defenseDie + Riflessi $defenseBonus = $defense. '
          '${success ? 'Riuscita: pietra consumata; il Manichino cade e si ricompone nel terreno. Sconfitta pacifica, nessuna uccisione.' : 'Fallita: la pietra resta nell’inventario.'}';
      if (success) {
        stone.quantita--;
        if (stone.quantita <= 0) inventario.remove(stone);
        // Explicit consumption must not be restored by the defensive save
        // guard for an accidentally emptied inventory.
        schedePersonaggio[actorIndex]['inventario'] = inventario
            .map((i) => i.toJson())
            .toList();
      }
      aggiungiLog(message);
      salvaSchedaCorrenteInMemoria();
      if (success) {
        load(targetIndex);
        activeConditions.removeWhere((c) => c.conditionType == 'corruzione');
        schedePersonaggio[targetIndex]['baghestPurified'] = true;
        targetToken.addAll({
          'status': 'expired',
          'baghestPurified': true,
          'peacefullyDefeated': true,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        aggiungiLog(message);
        salvaSchedaCorrenteInMemoria();
        saveMasterParticipantChange(encounter);
      }
      return success;
    } finally {
      // Persist a spent Action even on failure or an interrupted async path.
      salvaSchedaCorrenteInMemoria();
      load(original);
      programmaSalvataggio();
      notifyActiveSheetSummaryChanged();
      for (final index in {actorIndex, targetIndex}) {
        if (readBoolValue(schedePersonaggio[index]['realtimeSharedSheet'])) {
          schedePersonaggio[index]['realtimeDirtyLocal'] = true;
          unawaited(_sendRealtimeEditedSharedSheetBack(sheetIndex: index));
        } else {
          sendRealtimeMasterVisibleTokenAt(index);
        }
      }
      sendRealtimeInitiativeSnapshotIfPublished();
    }
  }

  Future<void> showBaghestPurification(String targetTag) async {
    if (onlineMasterApprovalRequired && !realtimeIsMasterRole) return;
    final owner = sheetTagAt(schedaCorrente);
    final encounter = selectedMasterInitiativeGroupId;
    final candidates = masterInitiativeTokens
        .where(
          (t) =>
              !combatTokenMatchesSheet(t, targetTag) &&
              masterInitiativeTokenCanAct(t) &&
              t['outsideFight'] != true &&
              localSheetIndexForOculumTag(publicInitiativeSourceTag(t)) >= 0,
        )
        .toList();
    final actor = await showDialog<String>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: const Text('Purifica il Manichino di Baghest'),
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Scegli chi usa un’Azione e una Pietra anti-corruzione. '
              'La pietra si consuma soltanto al successo.',
            ),
          ),
          for (final token in candidates)
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.pop(dialog, publicInitiativeSourceTag(token)),
              child: Text(
                '${token['name'] ?? publicInitiativeSourceTag(token)}',
              ),
            ),
        ],
      ),
    );
    if (!mounted ||
        actor == null ||
        owner != sheetTagAt(schedaCorrente) ||
        encounter != selectedMasterInitiativeGroupId) {
      return;
    }
    await purifyBaghestPuppet(actor, targetTag);
  }
}
