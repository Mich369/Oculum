part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member
extension _OculumEncounterRewards on _OculumHomePageState {
  void receiveEncounterRewards(Iterable<Map> rewards) {
    for (final reward in rewards) {
      final id = '${reward['id'] ?? ''}';
      final amount = readIntValue(reward['amount']).clamp(0, 100000000);
      if (id.isEmpty || amount <= 0) continue;
      for (var i = 0; i < schedePersonaggio.length; i++) {
        if (schedePersonaggio[i]['realtimeSharedSheet'] == true) continue;
        final tag = sheetTagAt(i);
        if (!(reward['participants'] as List? ?? []).contains(tag)) continue;
        final key = 'reward:$id:$tag';
        onlineCombatRequests.putIfAbsent(
          key,
          () => {
            'id': key,
            'kind': 'encounter_reward',
            'status': 'queued',
            'targetTag': tag,
            'amount': amount,
            'encounterName': reward['name'],
            'multiplier':
                reward['fateActive'] == true &&
                    (reward['fateParticipants'] == null ||
                        (reward['fateParticipants'] as List).contains(tag))
                ? ((i == schedaCorrente
                              ? chainedFateCompletedIds.length
                              : (schedePersonaggio[i]['chainedFateCompletedIds']
                                            as List? ??
                                        [])
                                    .length) >=
                          3
                      ? 3
                      : 2)
                : 1,
          },
        );
      }
    }
    claimQueuedEncounterRewards();
    programmaSalvataggio();
  }

  void claimQueuedEncounterRewards() {
    if (schedaCorrente < 0 ||
        schedaCorrente >= schedePersonaggio.length ||
        schedePersonaggio[schedaCorrente]['realtimeSharedSheet'] == true) {
      return;
    }
    final tag = sheetTagAt(schedaCorrente);
    for (final reward
        in onlineCombatRequests.values
            .where(
              (r) =>
                  r['kind'] == 'encounter_reward' &&
                  r['status'] == 'queued' &&
                  r['targetTag'] == tag,
            )
            .toList()) {
      reward['status'] = 'granted';
      final amount =
          readIntValue(reward['amount']) *
          readIntValue(reward['multiplier'], fallback: 1);
      final message = applicaEsperienzaFlat(
        amount,
        motivo: 'Fine scontro ${reward['encounterName'] ?? ''}',
        applyChainedFate: false,
      );
      aggiungiLog(message);
    }
  }

  Future<void> finishEncounter(String id) async {
    if (realtimeService?.isConnected == true && !realtimeIsMasterRole) return;
    selectMasterInitiativeGroup(id);
    captureActiveMasterInitiativeGroup();
    final group = masterInitiativeGroups
        .where((g) => g['id'] == id)
        .firstOrNull;
    if (group == null || masterInitiativeTokens.isEmpty) return;
    var amount = 0;
    final participants = <String>[];
    for (final token in masterInitiativeTokens) {
      if (token['side'] != 'enemy') {
        participants.add(publicInitiativeSourceTag(token));
        continue;
      }
      if (token['status'] != 'dead' &&
          readIntValue(token['currentHp'], fallback: 1) > 0) {
        continue;
      }
      final index = localSheetIndexForOculumTag(
        '${token['sheetTag'] ?? token['id']}',
      );
      amount += max(0, readIntValue(token['level']));
      if (index >= 0) {
        for (final stat in ['resilienza', 'volonta', 'materia', 'oculum']) {
          amount += max(0, sheetIntValueAt(index, stat));
        }
      } else {
        amount += max(0, readIntValue(token['statsTotal']));
      }
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Termina scontro'),
        content: Text(
          '$amount EXP base a ciascuno dei ${participants.length} partecipanti. La turnistica viene svuotata e la condivisione chiusa. Gli scontri uniti tornano separati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Termina e assegna EXP'),
          ),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    final reward = <String, dynamic>{
      'id': '$id:${DateTime.now().microsecondsSinceEpoch}',
      'name': group['name'],
      'amount': amount,
      'participants': participants,
      'fateActive':
          group['chainedFate'] is Map &&
          (group['chainedFate'] as Map)['status'] == 'active',
      'fateParticipants': group['chainedFate'] is Map
          ? List<dynamic>.from(
              (group['chainedFate'] as Map)['participants'] as List? ?? [],
            )
          : <dynamic>[],
    };
    final rewards = (group['rewards'] as List? ?? []).whereType<Map>().toList()
      ..add(reward);
    group['rewards'] = rewards;
    receiveEncounterRewards([reward]);
    expireSummoningEmblems(id);
    closeRealtimeInitiativeSnapshot();
    for (final request in onlineCombatRequests.values) {
      if (request['encounterId'] == id &&
          request['kind'] != 'encounter_reward') {
        request['status'] = 'closed';
        request['freeReaction'] = false;
      }
    }
    masterInitiativeTokens.clear();
    masterInitiativeRound = 0;
    masterInitiativeActiveIndex = 0;
    masterInitiativeManualOrder = false;
    masterInitiativeManualCounter = 0;
    group['mergedEncounterIds'] = <String>[];
    group['rollRequests'] = <Map<String, dynamic>>[];
    if (group['chainedFate'] is Map) {
      (group['chainedFate'] as Map)['status'] = 'ended';
    }
    forgetCombatDiscoveries(id);
    captureActiveMasterInitiativeGroup();
    sendRealtimeInitiativeSnapshot();
    aggiungiLog(
      '[FINE SCONTRO] ${group['name']}: $amount EXP base per partecipante.',
    );
    programmaSalvataggio();
    setState(() {});
  }
}
