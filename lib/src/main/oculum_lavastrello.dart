part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int oculumLavastrelloNestHp(int level) => 30 + 5 * max(0, level);
bool oculumLavastrelloNestCanSpawn(Map nest) =>
    readIntValue(nest['currentHp'], fallback: 1) > 0 &&
    readIntValue(nest['lavastrelloSpawned']) <
        readIntValue(nest['lavastrelloMaximum'], fallback: 5);

extension _OculumLavastrello on _OculumHomePageState {
  bool get knowsLavastrelloNest => planarState['lavastrelloNestKnown'] == true;
  void discoverLavastrelloNest(int total) {
    if (total <= 15) return;
    final exists = onlineCombatTokens().any(
      (t) =>
          t['lavastrelloNest'] == true ||
          '${t['name']}'.startsWith('Tana Lavastrello'),
    );
    if (!exists) return;
    planarState['lavastrelloNestKnown'] = true;
    aggiungiLog(
      '[PERCEZIONE] Hai individuato una roccia lavica aperta: tana di Lavastrelli. Ora puoi usare Cerca tana con Vantaggio.',
    );
    programmaSalvataggio();
  }

  Future<void> searchLavastrelloNest() async {
    final stat = bestCombatScoutStat();
    if (stat == null || !knowsLavastrelloNest) return;
    if (currentTurnTrackerIsActive() && !await spendCombatRollResource()) {
      return;
    }
    final extra =
        3 +
        max(
          0,
          readIntValue(
            faunaPassive('lavastrello_nest_intuition')?.valueExpression,
          ),
        );
    await tiraSottotrattoOcchio(
      stat,
      resourceAlreadySpent: true,
      actionLabel: 'Cerca tana',
      onResolved: (natural, total) {
        final result = total + extra;
        aggiungiLog(
          '[CERCA TANA] ${stat.nome} $total +$extra (Vantaggio e Intuito) = $result; soglia >15.',
        );
        discoverLavastrelloNest(result.toInt());
      },
    );
  }

  Future<void> createLavastrelloNest() async {
    if (!haPermessiMaster || !canActWithoutMasterApproval) return;
    final level = max(0, leggiNumero(livelloController));
    final original = schedaCorrente, global = catturaImpostazioniGlobali();
    salvaSchedaCorrenteInMemoria();
    try {
      await creaNuovaSchedaPersonaggio(
        nome: 'Tana Lavastrello ${schedePersonaggio.length + 1}',
        tipo: 'Mostro',
        livello: level,
        grado: oculumGradeForLevel(level),
        aggiungiAlMasterParty: true,
      );
      final maximum = oculumLavastrelloNestHp(level);
      planarState['lavastrelloNestMaxHp'] = maximum;
      currentHpController.text = '$maximum';
      backgroundController.text =
          'Roccia lavica cava e aperta. $maximum Vita, modificabile. Una uscita per giro, massimo cinque totali. Distruggerla interrompe le uscite.';
      buffMalusRapidiController.clear();
      arti.clear();
      skills.clear();
      schedePersonaggio[schedaCorrente]['masterSideOverride'] = 'enemy';
      salvaSchedaCorrenteInMemoria();
      addSheetToMasterInitiative(schedaCorrente, rollInitiative: false);
      final token = masterInitiativeTokens.firstWhere(
        (t) => publicInitiativeSourceTag(t) == sheetTagAt(schedaCorrente),
      );
      token.addAll({
        'lavastrelloNest': true,
        'lavastrelloSpawned': 0,
        'lavastrelloMaximum': 5,
        'lavastrelloLastRound': masterInitiativeRound,
        'currentHp': maximum,
        'maxHp': maximum,
        'type': 'Oggetto',
        'actionMax': 0,
        'reactionMax': 0,
        'reactionFastMax': 0,
        'encounterObject': true,
      });
      captureActiveMasterInitiativeGroup();
      programmaSalvataggio();
      sendRealtimeInitiativeSnapshotIfPublished();
    } finally {
      if (mounted && original < schedePersonaggio.length) {
        schedaCorrente = original;
        caricaStatoDaJson(schedePersonaggio[original]);
        ripristinaImpostazioniGlobali(global);
      }
    }
  }

  Future<void> tickLavastrelloNests() async {
    if (!haPermessiMaster || !currentCombatIsActive()) return;
    final group = masterInitiativeGroups
        .where((g) => g['id'] == selectedMasterInitiativeGroupId)
        .firstOrNull;
    if (group == null || group['lavastrelloSpawning'] == true) return;
    group['lavastrelloSpawning'] = true;
    final original = schedaCorrente, global = catturaImpostazioniGlobali();
    final name = quickSheetNameController.text,
        desc = quickSheetDescriptionController.text,
        count = quickSheetCountController.text,
        mode = quickSheetArtMode,
        add = quickSheetAddToInitiative;
    salvaSchedaCorrenteInMemoria();
    try {
      for (final nest
          in masterInitiativeTokens
              .where((t) => t['lavastrelloNest'] == true)
              .toList()) {
        if (!oculumLavastrelloNestCanSpawn(nest) ||
            readIntValue(nest['lavastrelloLastRound']) >=
                masterInitiativeRound) {
          continue;
        }
        nest['lavastrelloLastRound'] = masterInitiativeRound;
        nest['lavastrelloSpawned'] =
            readIntValue(nest['lavastrelloSpawned']) + 1;
        quickSheetNameController.text = 'Lavastrello';
        quickSheetDescriptionController.text = monsterBookEntryById(
          'lavastrello',
        )!.descIt;
        quickSheetCountController.text = '1';
        quickSheetAddToInitiative = true;
        await creaSchedaRapidaMaster(
          forcedType: 'Mostro',
          sideOverride: 'enemy',
          forceEnemyProfile: true,
          livelloForzato: readIntValue(nest['level']),
          monsterBookSource: monsterBookEntryById('lavastrello'),
        );
        aggiungiLog(
          '[TANA] Uscito Lavastrello ${nest['lavastrelloSpawned']}/${nest['lavastrelloMaximum']}.',
        );
      }
    } finally {
      group.remove('lavastrelloSpawning');
      quickSheetNameController.text = name;
      quickSheetDescriptionController.text = desc;
      quickSheetCountController.text = count;
      quickSheetArtMode = mode;
      quickSheetAddToInitiative = add;
      if (mounted && original < schedePersonaggio.length) {
        salvaSchedaCorrenteInMemoria();
        schedaCorrente = original;
        caricaStatoDaJson(schedePersonaggio[original]);
        ripristinaImpostazioniGlobali(global);
      }
      programmaSalvataggio();
      sendRealtimeInitiativeSnapshotIfPublished();
    }
  }

  void resolveLavastrelloNestDestroyed(Map<String, dynamic> nest) {
    if (nest['lavastrelloNest'] != true ||
        readIntValue(nest['currentHp']) > 0 ||
        nest['lavastrelloDestroyed'] == true) {
      return;
    }
    nest['lavastrelloDestroyed'] = true;
    if (!canManagePartyQuests ||
        readIntValue(nest['lavastrelloSpawned']) >=
            readIntValue(nest['lavastrelloMaximum'], fallback: 5)) {
      return;
    }
    final id = 'nest:${nest['sheetTag'] ?? nest['id']}';
    final scroll = oculumPlanarTechniqueScroll(
      monsterBookEntryById('lavastrello')!,
      'lavastrello_nest_intuition',
      receipt: id,
      level: readIntValue(nest['level']),
      grade: readIntValue(nest['grade']),
    );
    final pending = List<dynamic>.from(
      partyChest['pendingLoot'] as List? ?? [],
    );
    if (!pending.whereType<Map>().any((p) => p['id'] == id)) {
      pending.add({'id': id, 'item': scroll.toJson()});
    }
    partyChest['pendingLoot'] = pending;
    oculumPromotePendingChestLoot(partyChest);
    partyChest['revision'] = readIntValue(partyChest['revision']) + 1;
    aggiungiLog(
      '[TANA DISTRUTTA] Uscite interrotte prima della quinta: scroll Intuito lavastrellesco nella cassa comune.',
    );
    unawaited(sendPartyChestState());
  }
}
