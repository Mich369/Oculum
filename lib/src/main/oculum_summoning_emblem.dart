part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const oculumSummoningEmblemPrice = 200;
const oculumSummoningEmblemDefaults = <String, dynamic>{
  'hp': 120,
  'maximumTargets': 3,
  'statBonus': 3,
  'subtraitBonus': 2,
  'turns': 0,
};
const oculumSummoningEmblemDescription =
    'Evoca per questo scontro uno Slime da 120 HP. Protegge fino a tre '
    'partecipanti scelti, inclusi se stessi, intercettando il danno che '
    'raggiungerebbe la loro Vita. Finché è vivo dona ai protetti +3 a '
    'Resilienza, Volontà, Materia e Oculum e +2 a tutti i sottotratti.';

Map<String, dynamic> oculumSummoningEmblemOffer() => {
  'id': 'summoning_emblem',
  'kind': 'summoning_emblem',
  'name': 'Emblema di evocazione · Slime custode',
  'cost': oculumSummoningEmblemPrice,
  'desc': oculumSummoningEmblemDescription,
  'summoningEmblem': Map.of(oculumSummoningEmblemDefaults),
};

bool oculumSummoningSlimeApplies(
  OculumPawnGuardian guardian,
  String targetTag,
  String encounterId,
) =>
    guardian.isSummoningSlime &&
    guardian.alive &&
    !guardian.pendingRegistration &&
    encounterId.isNotEmpty &&
    guardian.summoningEmblem['encounterId'] == encounterId &&
    guardian.targets.contains(targetTag);

extension _OculumSummoningEmblem on _OculumHomePageState {
  List<String> validSummoningSlimeTargets(
    OculumPawnGuardian pawn,
    Iterable<String> requested, {
    bool limit = true,
  }) {
    final encounter = '${pawn.summoningEmblem['encounterId'] ?? ''}';
    final group = masterInitiativeGroups
        .where((g) => g['id'] == encounter)
        .firstOrNull;
    final tokens = encounter == onlineCombatEncounterId
        ? summoningEmblemFightTokens()
        : (group?['tokens'] as List? ?? const [])
              .whereType<Map>()
              .map((token) => Map<String, dynamic>.from(token))
              .toList();
    final owner = tokens
        .where((token) => onlineCombatTokenTag(token) == pawn.ownerTag)
        .firstOrNull;
    if (owner == null) return [];
    final allowed = tokens
        .where(
          (token) =>
              token['status'] != 'dead' &&
              '${token['side'] ?? 'ally'}' == '${owner['side'] ?? 'ally'}',
        )
        .map(onlineCombatTokenTag)
        .toSet();
    return requested
        .where(allowed.contains)
        .toSet()
        .take(limit ? pawn.maximumTargets : 1000000)
        .toList();
  }

  List<Map<String, dynamic>> summoningEmblemFightTokens() =>
      realtimeService?.isConnected == true
      ? onlineCombatTokens()
      : masterInitiativeTokens
            .map((token) => Map<String, dynamic>.from(token))
            .toList();

  int summoningEmblemBonus(String key, {bool subtrait = false}) {
    if (schedePersonaggio.isEmpty ||
        !pawnGuardians.any((pawn) => pawn.isSummoningSlime && pawn.alive)) {
      return 0;
    }
    // Computing bonuses must not create a sheet identity: tag generation itself
    // reads effective statistics, so calling sheetTagAt here would recurse.
    final tag = '${schedePersonaggio[schedaCorrente]['sheetTag'] ?? ''}';
    if (tag.isEmpty) return 0;
    final encounter = onlineCombatEncounterId;
    if (!summoningEmblemFightTokens().any(
      (token) => onlineCombatTokenTag(token) == tag,
    )) {
      return 0;
    }
    return pawnGuardians
        .where((pawn) => oculumSummoningSlimeApplies(pawn, tag, encounter))
        .fold(
          0,
          (sum, pawn) =>
              sum +
              readIntValue(
                pawn.summoningEmblem[subtrait ? 'subtraitBonus' : 'statBonus'],
                fallback: subtrait ? 2 : 3,
              ),
        );
  }

  void expireSummoningEmblems(String encounterId) {
    if (encounterId.isEmpty) return;
    final before = pawnGuardians.length;
    pawnGuardians.removeWhere(
      (pawn) =>
          pawn.isSummoningSlime &&
          pawn.summoningEmblem['encounterId'] == encounterId,
    );
    if (before == pawnGuardians.length) return;
    invalidateDerivedDataCaches();
    sendPawnSnapshot();
    programmaSalvataggio();
  }

  Future<void> activateSummoningEmblem(InventoryItem item) async {
    final origin = currentSheetScrollId();
    final encounter = onlineCombatEncounterId;
    final owner = pawnSenderTag;
    final tokens = summoningEmblemFightTokens();
    final ownToken = tokens
        .where((token) => onlineCombatTokenTag(token) == owner)
        .firstOrNull;
    if (encounter.isEmpty || ownToken == null) {
      aggiungiLog('Entra in una turnistica prima di usare l’emblema.');
      return;
    }
    final config = <String, dynamic>{
      ...oculumSummoningEmblemDefaults,
      ...Map<String, dynamic>.from(item.craftData['summoningEmblem'] as Map),
    };
    final limit = readIntValue(
      config['maximumTargets'],
      fallback: 3,
    ).clamp(1, 100);
    final allies = tokens
        .where(
          (token) =>
              token['status'] != 'dead' &&
              '${token['side'] ?? 'ally'}' == '${ownToken['side'] ?? 'ally'}',
        )
        .toList();
    final selected = <String>{owner};
    final targets = await showDialog<List<String>>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (_, refresh) => AlertDialog(
          title: const Text('Slime custode · chi protegge?'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fino a $limit · ${config['hp']} HP condivisi · per questo scontro',
                  ),
                  for (final token in allies)
                    CheckboxListTile(
                      value: selected.contains(onlineCombatTokenTag(token)),
                      activeColor: onlineCombatTokenTag(token) == owner
                          ? Colors.green
                          : Colors.lightBlue,
                      title: Text(
                        onlineCombatTokenTag(token) == owner
                            ? 'Se stessi · ${token['name'] ?? 'Tu'}'
                            : '${token['name'] ?? 'Alleato'}',
                      ),
                      onChanged: (value) => refresh(() {
                        final tag = onlineCombatTokenTag(token);
                        if (value == true && selected.length < limit) {
                          selected.add(tag);
                        } else if (value != true) {
                          selected.remove(tag);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialog, selected.toList()),
              child: const Text('Evoca'),
            ),
          ],
        ),
      ),
    );
    if (!mounted ||
        targets == null ||
        currentSheetScrollId() != origin ||
        encounter != onlineCombatEncounterId ||
        !inventario.contains(item) ||
        item.quantita <= 0) {
      return;
    }
    final pawn = OculumPawnGuardian(
      id: 'pawn_slime_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 30)}',
      ownerTag: owner,
      hp: max(1, readIntValue(config['hp'], fallback: 120)),
      stats: const {'resilienza': 0, 'volonta': 0, 'materia': 0, 'oculum': 0},
      targets: targets,
      summoningEmblem: {...config, 'encounterId': encounter},
      pendingRegistration: pawnRemoteAuthority,
    );
    setState(() {
      pawnGuardians.add(pawn);
      item.quantita--;
      if (item.quantita <= 0) inventario.remove(item);
      invalidateDerivedDataCaches();
      aggiungiLog(
        '${pawn.displayName}: ${pawn.hp} HP, ${targets.length} protetti. '
        '${pawn.pendingRegistration ? 'In attesa del Master.' : 'Attivo fino a fine scontro.'}',
      );
    });
    programmaSalvataggio();
    if (pawn.pendingRegistration) {
      await sendPawnMessage('pawn_command', {
        'action': 'create',
        'pawnId': pawn.id,
        'targets': pawn.targets,
        'pawnData': pawn.toJson(),
      });
      await sendPawnMessage('pawn_command', {
        'action': 'initiative',
        'pawnId': pawn.id,
      });
    } else {
      addPawnToInitiative(pawn);
      sendPawnSnapshot();
    }
  }

  Future<void> editSummoningEmblem(InventoryItem item) async {
    final config = <String, dynamic>{
      ...oculumSummoningEmblemDefaults,
      ...Map<String, dynamic>.from(item.craftData['summoningEmblem'] as Map),
    };
    final fields = <String, String>{
      'hp': 'Vita dello slime',
      'maximumTargets': 'Massimo destinatari',
      'statBonus': 'Bonus per statistica',
      'subtraitBonus': 'Bonus per sottotratto',
      'turns': 'Turni (0 = intero scontro)',
    };
    final controllers = {
      for (final key in fields.keys)
        key: TextEditingController(text: '${config[key]}'),
    };
    final origin = currentSheetScrollId();
    try {
      final save = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          scrollable: true,
          title: const Text('Configura emblema'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final field in fields.entries)
                TextField(
                  controller: controllers[field.key],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: field.value),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Salva'),
            ),
          ],
        ),
      );
      if (!mounted ||
          save != true ||
          origin != currentSheetScrollId() ||
          !inventario.contains(item)) {
        return;
      }
      setState(() {
        for (final entry in controllers.entries) {
          config[entry.key] = readIntValue(
            entry.value.text,
            fallback: readIntValue(config[entry.key]),
          );
        }
        config['hp'] = readIntValue(config['hp']).clamp(1, 1000000);
        config['maximumTargets'] = readIntValue(
          config['maximumTargets'],
        ).clamp(1, 100);
        config['turns'] = max(0, readIntValue(config['turns']));
        item.craftData['summoningEmblem'] = config;
      });
      programmaSalvataggio();
    } finally {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
  }
}
