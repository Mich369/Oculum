part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

Map<String, int> oculumQuestBonus(int roll) {
  if (roll < 0 || roll > 99) throw RangeError.range(roll, 0, 99);
  if (roll < 1) {
    return {
      'ispirazioni': 1,
      'superIspirazioni': 1,
      'ispirazioniOculum': 1,
      'schivateOculumBonus': 1,
    };
  }
  if (roll < 4) return {'schivateOculumBonus': 1};
  if (roll < 9) return {'ispirazioniOculum': 1};
  if (roll < 19) return {'superIspirazioni': 1};
  if (roll < 44) return {'ispirazioni': 1};
  return {};
}

/// A board is scoped to one campaign, persisted inside the chest snapshot.
/// A new board never uses historical kills; completed IDs cannot pay twice.
List<Map<String, dynamic>> oculumCreatePartyQuests({
  required String plane,
  required int level,
  required int grade,
  required int veil,
  required int sequence,
  Iterable<String> elements = const [],
}) {
  final localElements = elements.where((e) => e != 'fisico').toSet().toList()
    ..sort();
  final element = localElements.isEmpty
      ? ''
      : localElements[sequence % localElements.length];
  final count = 2 + sequence % 2;
  return [
    {
      'id': 'quest:$sequence:0',
      'plane': plane,
      'kind': 'kills',
      'minimumLevel': max(0, level),
      'target': count,
      'progress': 0,
      'obser': 10 + grade * 5 + count * 5,
      'title':
          'Sconfiggete $count nemic${count == 1 ? 'o' : 'i'} di livello almeno $level',
    },
    {
      'id': 'quest:$sequence:1',
      'plane': plane,
      'kind': 'kills',
      'minimumLevel': max(0, level),
      'element': element,
      'target': 1,
      'progress': 0,
      'obser': 15 + grade * 5,
      'title': element.isEmpty
          ? 'Sconfiggete un nemico di livello almeno $level'
          : 'Sconfiggete un nemico $element di livello almeno $level',
    },
    {
      'id': 'quest:$sequence:2',
      'plane': plane,
      'kind': 'veil',
      'minimumLevel': 0,
      'target': veil + 3,
      'progress': veil,
      'baseline': veil,
      'obser': 12 + grade * 5,
      'title': 'Un membro del party raggiunge +${veil + 3} Velo',
    },
  ];
}

bool oculumQuestAcceptsEnemy(Map quest, Map enemy, String plane) =>
    quest['kind'] == 'kills' &&
    quest['plane'] == plane &&
    !oculumEncounterEnemyIsSummon(enemy) &&
    readIntValue(enemy['level']) >= readIntValue(quest['minimumLevel']) &&
    ('${quest['element'] ?? ''}'.isEmpty ||
        quest['element'] == enemy['element']);

extension _OculumPartyQuests on _OculumHomePageState {
  bool get canManagePartyQuests => realtimeService?.isConnected == true
      ? realtimeIsMasterRole
      : haPermessiMaster;
  List<int> questPartyIndices() {
    final tags = (partyChest['members'] as Map? ?? {}).keys.toSet();
    return [
      for (var i = 0; i < schedePersonaggio.length; i++)
        if (!isEnemySheetAt(i) &&
            !RegExp(
              r'mostr|monster|boss|pawn|creatura|fallen|occhi|occhio',
            ).hasMatch(oculumNormalizeText(tipoSchedaPersonaggio(i))) &&
            (realtimeService?.isConnected == true
                ? tags.contains(sheetTagAt(i))
                : (masterPartyIndexes().contains(i) || i == schedaCorrente)))
          i,
    ];
  }

  List<Map<String, dynamic>> get activePartyQuests =>
      (partyChest['quests'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
  void ensurePartyQuests() {
    if (!canManagePartyQuests || schedePersonaggio.isEmpty) return;
    final indices = questPartyIndices();
    if (indices.isEmpty) return;
    final plane = selectedPlaneId;
    final current = activePartyQuests;
    if (current.length == 3 && current.every((q) => q['plane'] == plane)) {
      return;
    }
    final level = indices
        .map(
          (i) => i == schedaCorrente
              ? leggiNumero(livelloController)
              : sheetIntValueAt(i, 'livello'),
        )
        .reduce(max);
    final grade = oculumGradeForLevel(level);
    final veil = indices.map(sheetCombatScoutVeloAt).reduce(max);
    final elements = monsterBookEntries
        .where(
          (m) =>
              m.planeIds.contains(plane) &&
              !m.isNpc &&
              !m.isBoss &&
              !m.isMiniBoss,
        )
        .map((m) => m.elementId);
    final sequence = readIntValue(partyChest['questSequence']) + 1;
    partyChest['questSequence'] = sequence;
    partyChest['quests'] = oculumCreatePartyQuests(
      plane: plane,
      level: level,
      grade: grade,
      veil: veil,
      sequence: sequence,
      elements: elements,
    );
    partyChest['revision'] = readIntValue(partyChest['revision']) + 1;
    programmaSalvataggio();
  }

  void advancePartyQuestKills(Iterable<Map> enemies, String encounterId) {
    if (!canManagePartyQuests) return;
    // If no board existed at fight start, this creates future objectives only.
    final existed = activePartyQuests.length == 3;
    ensurePartyQuests();
    if (!existed) return;
    final quests = activePartyQuests;
    var changed = false;
    for (final enemy in enemies) {
      final killId = '$encounterId:${enemy['monsterSheetTag'] ?? enemy['id']}';
      for (final q in quests) {
        if (q['completed'] == true ||
            !oculumQuestAcceptsEnemy(q, enemy, selectedPlaneId)) {
          continue;
        }
        final seen = (q['killIds'] as List? ?? []).map((e) => '$e').toSet();
        if (!seen.add(killId)) continue;
        q['killIds'] = seen.toList();
        q['progress'] = min(
          readIntValue(q['target']),
          readIntValue(q['progress']) + 1,
        );
        if (q['progress'] == q['target']) {
          q['completed'] = true;
          q['completedBy'] = '${enemy['killerTag'] ?? ''}';
        }
        changed = true;
      }
    }
    if (changed) {
      partyChest['quests'] = quests;
      partyChest['revision'] = readIntValue(partyChest['revision']) + 1;
      programmaSalvataggio();
      unawaited(sendPartyChestState());
      autoClaimCompletedPartyQuests();
    }
  }

  void autoClaimCompletedPartyQuests() {
    for (final quest in activePartyQuests.where(
      (q) => q['completed'] == true && '${q['completedBy'] ?? ''}'.isNotEmpty,
    )) {
      unawaited(claimPartyQuest('${quest['id']}', '${quest['completedBy']}'));
    }
  }

  void refreshPartyQuestStats() {
    if (!canManagePartyQuests) return;
    ensurePartyQuests();
    final quests = activePartyQuests;
    var changed = false;
    for (final q in quests) {
      if (q['kind'] != 'veil' || q['completed'] == true) continue;
      for (final i in questPartyIndices()) {
        final value = sheetCombatScoutVeloAt(i);
        if (value > readIntValue(q['progress'])) {
          q['progress'] = value;
          changed = true;
        }
        if (value >= readIntValue(q['target'])) {
          q['completed'] = true;
          q['completedBy'] = sheetTagAt(i);
          changed = true;
          break;
        }
      }
    }
    if (changed) {
      partyChest['quests'] = quests;
      partyChest['revision'] = readIntValue(partyChest['revision']) + 1;
      programmaSalvataggio();
      autoClaimCompletedPartyQuests();
    }
  }

  Future<void> claimPartyQuest(String questId, String completer) async {
    if (!canManagePartyQuests ||
        !questPartyIndices().any((i) => sheetTagAt(i) == completer)) {
      return;
    }
    final quests = activePartyQuests;
    final q = quests.where((q) => q['id'] == questId).firstOrNull;
    if (q == null || q['completed'] != true || q['claimed'] == true) return;
    if ('${q['completedBy'] ?? ''}'.isNotEmpty &&
        q['completedBy'] != completer) {
      return;
    }
    final rewards = Map<String, dynamic>.from(
      partyChest['questRewards'] as Map? ?? {},
    );
    if (rewards.containsKey(questId)) return;
    final roll = Random.secure().nextInt(100);
    final bonus = oculumQuestBonus(roll);
    q['claimed'] = true;
    rewards[questId] = {
      'id': questId,
      'recipient': completer,
      'bonus': bonus,
      'roll': roll,
      'obser': q['obser'],
      'title': q['title'],
    };
    partyChest['obser'] =
        readIntValue(partyChest['obser']) + readIntValue(q['obser']);
    partyChest['questRewards'] = rewards;
    // Replace only the completed slot, preserving the other two objectives.
    final indices = questPartyIndices();
    final level = indices
        .map(
          (i) => i == schedaCorrente
              ? leggiNumero(livelloController)
              : sheetIntValueAt(i, 'livello'),
        )
        .reduce(max);
    final sequence = readIntValue(partyChest['questSequence']) + 1;
    partyChest['questSequence'] = sequence;
    final next = oculumCreatePartyQuests(
      plane: selectedPlaneId,
      level: level,
      grade: oculumGradeForLevel(level),
      veil: indices.map(sheetCombatScoutVeloAt).reduce(max),
      sequence: sequence,
      elements: monsterBookEntries
          .where(
            (m) =>
                m.planeIds.contains(selectedPlaneId) &&
                !m.isNpc &&
                !m.isBoss &&
                !m.isMiniBoss,
          )
          .map((m) => m.elementId),
    );
    final slot = quests.indexOf(q);
    quests[slot] = next[slot];
    partyChest['quests'] = quests;
    partyChest['revision'] = readIntValue(partyChest['revision']) + 1;
    aggiungiLog(
      '[QUEST] ${q['title']}: +${q['obser']} Obser in cassa. Premio personale: ${bonus.isEmpty ? 'nessuno' : bonus.keys.join(', ')}.',
    );
    settlePartyQuestRewards();
    await salvaDatiSoloLocale();
    await sendPartyChestState();
    if (mounted) setState(() {});
  }

  void settlePartyQuestRewards() {
    for (final reward
        in (partyChest['questRewards'] as Map? ?? {}).values.whereType<Map>()) {
      final tag = '${reward['recipient']}';
      if (!ownPermissionTags.contains(tag)) continue;
      final index = localSheetIndexForOculumTag(tag);
      if (index < 0) continue;
      final original = schedaCorrente;
      salvaSchedaCorrenteInMemoria();
      final global = catturaImpostazioniGlobali();
      try {
        if (index != original) {
          schedaCorrente = index;
          caricaStatoDaJson(schedePersonaggio[index]);
          ripristinaImpostazioniGlobali(global);
        }
        final sheet = schedePersonaggio[index];
        final received = (sheet['receivedPartyQuestRewards'] as List? ?? [])
            .map((e) => '$e')
            .toSet();
        final receipt = '$permissionCampaignId:${reward['id']}';
        if (!received.add(receipt)) continue;
        sheet['receivedPartyQuestRewards'] = received.toList();
        final bonus = reward['bonus'] as Map? ?? {};
        ispirazioniController.text =
            '${leggiNumero(ispirazioniController) + readIntValue(bonus['ispirazioni'])}';
        superIspirazioniController.text =
            '${leggiNumero(superIspirazioniController) + readIntValue(bonus['superIspirazioni'])}';
        ispirazioniOculumController.text =
            '${leggiNumero(ispirazioniOculumController) + readIntValue(bonus['ispirazioniOculum'])}';
        schivateOculumBonus += readIntValue(bonus['schivateOculumBonus']);
        scudoCriticoController.text =
            '${leggiNumero(scudoCriticoController) + readIntValue(bonus['scudoCritico'])}';
        salvaSchedaCorrenteInMemoria();
      } finally {
        if (index != original) {
          final updated = catturaImpostazioniGlobali();
          schedaCorrente = original;
          caricaStatoDaJson(schedePersonaggio[original]);
          ripristinaImpostazioniGlobali(updated);
        }
      }
    }
  }

  Future<void> showPartyQuests() async {
    if (schedePersonaggio.isEmpty) return;
    refreshPartyChestMembers();
    ensurePartyQuests();
    refreshPartyQuestStats();
    unawaited(sendPartyChestState());
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) {
          final quests = activePartyQuests;
          return AlertDialog(
            title: const Text('Quest del party · 3 obiettivi'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Obiettivi brevi del piano attuale. Premi in cassa comune; bonus personale a chi completa. Online il Master conferma l’autore quando non è stato registrato.',
                    ),
                    if (quests.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Il Master prepara le quest del party.'),
                      ),
                    for (final q in quests)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${q['title']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${q['progress']}/${q['target']} · ${q['obser']} Obser · ${oculumMonsterHabitats['${q['plane']}'] ?? q['plane']}',
                              ),
                              if (q['completed'] == true &&
                                  canManagePartyQuests)
                                FilledButton(
                                  onPressed: () async {
                                    var tag = '${q['completedBy'] ?? ''}';
                                    if (tag.isEmpty) {
                                      tag =
                                          await showDialog<String>(
                                            context: context,
                                            builder: (d) => SimpleDialog(
                                              title: const Text(
                                                'Chi ha completato la quest?',
                                              ),
                                              children: [
                                                for (final i
                                                    in questPartyIndices())
                                                  SimpleDialogOption(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          d,
                                                          sheetTagAt(i),
                                                        ),
                                                    child: Text(
                                                      nomeSchedaPersonaggio(i),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ) ??
                                          '';
                                    }
                                    if (tag.isNotEmpty) {
                                      await claimPartyQuest('${q['id']}', tag);
                                      if (context.mounted) update(() {});
                                    }
                                  },
                                  child: const Text(
                                    'Assegna premio e nuova quest',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Chiudi'),
              ),
            ],
          );
        },
      ),
    );
  }
}
