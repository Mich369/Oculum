part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member
extension _OculumMasterRollRequests on _OculumHomePageState {
  Future<void> requestPlayerRolls(String encounterId) async {
    if (!(modalitaMaster || isMasterHost || realtimeIsMasterRole)) return;
    if (realtimeService?.isConnected == true && !realtimeIsMasterRole) return;
    captureActiveMasterInitiativeGroup();
    final group = masterInitiativeGroups
        .where((g) => g['id'] == encounterId)
        .firstOrNull;
    if (group == null) return;
    final tokens = (group['tokens'] as List? ?? [])
        .whereType<Map>()
        .where((t) => t['side'] != 'enemy')
        .toList();
    final chosen = <String>{};
    final options = <String, String>{
      'resilienza': 'Resilienza',
      'volonta': 'Volontà',
      'materia': 'Materia',
      'oculum': 'Oculum',
      'vc': 'VC',
      'cm': 'CM',
      for (final stat in hiddenEyeStats.where((s) => s.unlocked))
        stat.id: stat.nome,
    };
    var key = 'resilienza';
    final dt = TextEditingController(text: '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          scrollable: true,
          title: const Text('Richiedi un tiro ai giocatori'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: key,
                  items: [
                    for (final e in options.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) {
                    if (v != null) update(() => key = v);
                  },
                ),
                TextField(
                  controller: dt,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'DT aggiuntiva del tiro',
                  ),
                ),
                for (final token in tokens)
                  CheckboxListTile(
                    title: Text('${token['name'] ?? '???'}'),
                    value: chosen.contains(
                      publicInitiativeSourceTag(
                        Map<String, dynamic>.from(token),
                      ),
                    ),
                    onChanged: (v) => update(() {
                      final tag = publicInitiativeSourceTag(
                        Map<String, dynamic>.from(token),
                      );
                      if (v == true) {
                        chosen.add(tag);
                      } else {
                        chosen.remove(tag);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: chosen.isEmpty
                  ? null
                  : () => Navigator.pop(dialog, true),
              child: const Text('Invia richiesta'),
            ),
          ],
        ),
      ),
    );
    final difficulty = int.tryParse(dt.text) ?? 0;
    dt.dispose();
    if (!mounted || ok != true) return;
    final requests = (group['rollRequests'] as List? ?? [])
        .whereType<Map>()
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
    for (final tag in chosen) {
      requests.add({
        'id': 'master-roll:${DateTime.now().microsecondsSinceEpoch}:$tag',
        'targetTag': tag,
        'rollKey': key,
        'rollName': options[key],
        'dt': difficulty,
        'encounterId': encounterId,
      });
    }
    group['rollRequests'] = requests;
    receiveMasterRollRequests(group);
    sendRealtimeInitiativeSnapshotIfPublished();
    programmaSalvataggio();
    setState(() {});
  }

  void receiveMasterRollRequests(Map<String, dynamic> group) {
    for (final raw in (group['rollRequests'] as List? ?? []).whereType<Map>()) {
      final id = '${raw['id']}';
      final tag = '${raw['targetTag']}';
      if (id.length > 200 ||
          onlineCombatRequests.containsKey(id) ||
          !ownPermissionTags.contains(normalizeOculumFriendTag(tag))) {
        continue;
      }
      onlineCombatRequests[id] = {
        ...raw,
        'kind': 'master_roll',
        'status': 'awaiting',
        'scope': permissionScope,
      };
      combatLogFor(
        tag,
        '[TIRO RICHIESTO DAL MASTER] ${raw['rollName']} · DT ${raw['dt']}.',
      );
    }
    programmaSalvataggio();
  }

  Future<void> performMasterRequestedRoll(Map<String, dynamic> request) async {
    final origin = currentSheetScrollId();
    if (request['targetTag'] != sheetTagAt(schedaCorrente) ||
        request['status'] != 'awaiting' ||
        request['encounterId'] != onlineCombatEncounterId ||
        request['scope'] != permissionScope) {
      return;
    }
    final key = '${request['rollKey']}';
    final stat = hiddenEyeStats
        .where((s) => s.id == key && s.unlocked)
        .firstOrNull;
    if (!const {
          'resilienza',
          'volonta',
          'materia',
          'oculum',
          'vc',
          'cm',
        }.contains(key) &&
        stat == null) {
      return;
    }
    final oldDt = difficoltaTiroController.text;
    request['status'] = 'rolling';
    difficoltaTiroController.text =
        '${(int.tryParse(oldDt) ?? 0) + readIntValue(request['dt'])}';
    try {
      aggiungiLog(
        '[RISPOSTA AL MASTER] ${request['rollName']} · DT aggiuntiva ${request['dt']}.',
      );
      if (stat != null) {
        await tiraSottotrattoOcchio(stat);
      } else if (key == 'vc' || key == 'cm') {
        await tiraValoreSpeciale(key.toUpperCase(), key == 'vc' ? vc() : cm());
      } else {
        final value = switch (key) {
          'resilienza' => resilienzaTotale(),
          'volonta' => volontaTotale(),
          'materia' => materiaTotale(),
          _ => oculumTotale(),
        };
        await tiraStat('${request['rollName']}', value);
      }
      request['status'] = 'completed';
    } finally {
      if (currentSheetScrollId() == origin) {
        difficoltaTiroController.text = oldDt;
      }
      if (request['status'] == 'rolling') request['status'] = 'awaiting';
      programmaSalvataggio();
      if (mounted) setState(() {});
    }
  }

  Widget masterRequestedRollsPanel() {
    final pending = onlineCombatRequests.values
        .where(
          (r) =>
              r['kind'] == 'master_roll' &&
              r['scope'] == permissionScope &&
              r['status'] == 'awaiting' &&
              r['targetTag'] == sheetTagAt(schedaCorrente) &&
              r['encounterId'] == onlineCombatEncounterId,
        )
        .toList();
    if (pending.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      children: [
        for (final r in pending)
          OutlinedButton.icon(
            onPressed: () => performMasterRequestedRoll(r),
            icon: const Icon(Icons.casino_outlined),
            label: Text('Master: ${r['rollName']} · DT ${r['dt']}'),
          ),
      ],
    );
  }
}
