part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const oculumPawnPrice = 100;
const oculumPawnExperiencePerTurn = 25;
const oculumPawnStatPointsPerLevel = 6;
const oculumPawnV2Price = 300;
const oculumPawnV2ExperiencePerTurn = 50;

int oculumPawnExperienceForLevel(String difficulty) {
  final standard = difficulty.trim().toLowerCase() == 'oculum' ? 1369 : 1000;
  return (standard / 2).ceil();
}

Map<String, int> oculumPawnProportionalStatAllocation(int points) {
  final result = <String, int>{
    'resilienza': 0,
    'volonta': 0,
    'materia': 0,
    'oculum': 0,
  };
  const weights = <String, int>{'resilienza': 3, 'volonta': 3, 'materia': 5};
  final safePoints = max(0, points);
  final fullCycles = safePoints ~/ 11;
  for (final entry in weights.entries) {
    result[entry.key] = entry.value * fullCycles;
  }
  var remainder = safePoints % 11;
  while (remainder > 0) {
    final next = weights.keys.reduce(
      (best, key) =>
          result[best]! / weights[best]! <= result[key]! / weights[key]!
          ? best
          : key,
    );
    result[next] = result[next]! + 1;
    remainder--;
  }
  return result;
}

Map<String, int> oculumPawnStats([Map<String, int>? values]) {
  final stats = <String, int>{
    'resilienza': 3,
    'volonta': 3,
    'materia': 5,
    'oculum': 0,
  };
  if (values != null) {
    for (final key in stats.keys) {
      if (values.containsKey(key)) stats[key] = max(0, values[key]!);
    }
  }
  return stats;
}

const oculumPawnDescription =
    'Livello 0 · Resilienza 3 · Volontà 3 · Materia 5 · Oculum 0 · 30 HP iniziali. '
    'Protegge una o più schede selezionate, intercettando solo il danno che raggiungerebbe gli HP. '
    'Gli scudi dei bersagli si consumano normalmente. Alla fine del proprio turno: cura 10 HP oppure, '
    'se già a vita piena, +5 Scudo. Da 20 Scudo ottiene Scudo di Salvataggio.';

Map<String, dynamic> oculumPawnMerchantOffer() => {
  'id': 'pawn',
  'name': 'Pawn',
  'kind': 'pawn',
  'cost': oculumPawnPrice,
  'desc': oculumPawnDescription,
};

const oculumPawnV2Description =
    'Statistiche iniziali pari alla metà di quelle della scheda che lo attiva. '
    'Cresce con il livello e il grado del proprietario; guadagna anche livelli '
    'propri al doppio dell esperienza per turno e offre 6 punti statistica '
    'assegnabili a ogni livello e grado. Distribuzione di riferimento del Pawn: '
    '3 Resilienza : 3 Volontà : 5 Materia : 0 Oculum.';

Map<String, dynamic> oculumPawnV2MerchantOffer() => {
  'id': 'pawn_v2',
  'name': 'Pawn V2',
  'kind': 'pawn_v2',
  'cost': oculumPawnV2Price,
  'desc': oculumPawnV2Description,
};

InventoryItem oculumPawnInventoryItem() => InventoryItem(
  nome: 'Pawn',
  peso: 0,
  quantita: 1,
  note: oculumPawnDescription,
  craftData: {'pawn': true},
);

InventoryItem oculumPawnV2InventoryItem() => InventoryItem(
  nome: 'Pawn V2',
  peso: 0,
  quantita: 1,
  note: oculumPawnV2Description,
  craftData: {'pawn': true, 'pawnV2': true},
);

class OculumPawnGuardian {
  OculumPawnGuardian({
    required this.id,
    required this.ownerTag,
    this.hp = 30,
    this.shield = 0,
    this.savingShield = false,
    this.turn = 0,
    this.level = 0,
    this.experience = 0,
    this.unspentStatPoints = 0,
    this.isV2 = false,
    this.grade = 0,
    this.ownerLevel = 0,
    this.ownerGrade = 0,
    this.pendingRegistration = false,
    this.conscious = false,
    Map<String, int>? stats,
    Map<String, int>? baseStats,
    Map<String, int>? allocatedStats,
    List<String>? targets,
  }) : stats = oculumPawnStats(stats),
       baseStats = oculumPawnStats(baseStats ?? stats),
       allocatedStats = {
         for (final key in const ['resilienza', 'volonta', 'materia', 'oculum'])
           key: max(0, allocatedStats?[key] ?? 0),
       },
       targets = List.of(targets ?? const []) {
    hp = hp.clamp(0, maxHp);
    shield = max(0, shield);
    turn = max(0, turn);
    level = max(0, level);
    experience = max(0, experience);
    unspentStatPoints = max(0, unspentStatPoints);
  }
  final String id;
  final String ownerTag;
  int hp;
  int shield;
  bool savingShield;
  int turn;
  int level;
  int experience;
  int unspentStatPoints;
  bool isV2;
  int grade;
  int ownerLevel;
  int ownerGrade;
  final Map<String, int> stats;
  final Map<String, int> baseStats;
  final Map<String, int> allocatedStats;
  bool pendingRegistration;
  bool conscious;
  List<String> targets;
  bool get alive => hp > 0;
  int get maxHp => max(1, stats['resilienza'] ?? 3) * 10;
  int get experiencePerTurn =>
      isV2 ? oculumPawnV2ExperiencePerTurn : oculumPawnExperiencePerTurn;
  int get statPointsPerLevel => oculumPawnStatPointsPerLevel;
  String get displayName => isV2 ? 'Pawn V2' : 'Pawn';

  void syncOwnerProgress({
    required int level,
    required int grade,
    required Map<String, int> ownerStats,
  }) {
    if (!isV2) return;
    final nextLevel = max(ownerLevel, level);
    final nextGrade = max(ownerGrade, grade);
    final gainedOwnerLevels = nextLevel - ownerLevel;
    final gainedGrades = nextGrade - ownerGrade;
    if (gainedOwnerLevels > 0 || gainedGrades > 0) {
      unspentStatPoints +=
          (gainedOwnerLevels + gainedGrades) * oculumPawnStatPointsPerLevel;
    }
    ownerLevel = nextLevel;
    ownerGrade = nextGrade;
    this.grade = max(this.grade, nextGrade);
    for (final key in baseStats.keys) {
      baseStats[key] = max(0, ownerStats[key] ?? 0) ~/ 2;
      stats[key] = baseStats[key]! + allocatedStats[key]!;
    }
    hp = hp.clamp(0, maxHp);
  }

  int gainTurnExperience(String difficulty) {
    final threshold = oculumPawnExperienceForLevel(difficulty);
    experience += experiencePerTurn;
    var gainedLevels = 0;
    while (experience >= threshold) {
      experience -= threshold;
      level++;
      unspentStatPoints += statPointsPerLevel;
      gainedLevels++;
    }
    return gainedLevels;
  }

  bool allocateStatPoints(Map<String, int> allocation) {
    const keys = <String>{'resilienza', 'volonta', 'materia', 'oculum'};
    if (allocation.keys.any((key) => !keys.contains(key)) ||
        allocation.values.any((value) => value < 0)) {
      return false;
    }
    final spent = allocation.values.fold<int>(0, (sum, value) => sum + value);
    if (spent <= 0 || spent > unspentStatPoints) return false;
    final resilience = allocation['resilienza'] ?? 0;
    stats.updateAll((key, value) => value + (allocation[key] ?? 0));
    allocatedStats.updateAll((key, value) => value + (allocation[key] ?? 0));
    unspentStatPoints -= spent;
    if (resilience > 0 && alive) hp = min(maxHp, hp + 10 * resilience);
    return true;
  }

  /// Returns HP damage still reaching the protected target. This amount has
  /// already passed the target's defense and shields: never reduce it twice.
  int intercept(int damage) {
    final incoming = max(0, damage);
    if (!alive || pendingRegistration || incoming == 0) return incoming;
    final shieldBefore = shield;
    final absorbedShield = min(shield, incoming);
    shield -= absorbedShield;
    var remaining = incoming - absorbedShield;
    if (savingShield && shieldBefore > 0 && shield == 0) {
      savingShield = false;
      return 0;
    }
    final absorbedHp = min(hp, remaining);
    hp -= absorbedHp;
    remaining -= absorbedHp;
    return remaining;
  }

  bool advanceTo(int nextTurn, {String difficulty = 'normale'}) {
    if (nextTurn <= turn || !alive || pendingRegistration) return false;
    while (turn < nextTurn) {
      gainTurnExperience(difficulty);
      if (hp < maxHp) {
        hp = min(maxHp, hp + 10);
      } else {
        shield += 5;
        if (shield >= 20) savingShield = true;
      }
      turn++;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerTag': ownerTag,
    'hp': hp,
    'shield': shield,
    'savingShield': savingShield,
    'turn': turn,
    'level': level,
    'experience': experience,
    'unspentStatPoints': unspentStatPoints,
    'isV2': isV2,
    'grade': grade,
    'ownerLevel': ownerLevel,
    'ownerGrade': ownerGrade,
    'stats': Map<String, int>.from(stats),
    'baseStats': Map<String, int>.from(baseStats),
    'allocatedStats': Map<String, int>.from(allocatedStats),
    'targets': targets.toList(),
    'pendingRegistration': pendingRegistration,
    'conscious': conscious,
  };
  factory OculumPawnGuardian.fromJson(Map<String, dynamic> data) =>
      OculumPawnGuardian(
        id: '${data['id'] ?? ''}',
        ownerTag: '${data['ownerTag'] ?? ''}',
        hp: readIntValue(data['hp'], fallback: 30),
        shield: readIntValue(data['shield']),
        savingShield: readBoolValue(data['savingShield']),
        turn: readIntValue(data['turn']),
        level: readIntValue(data['level']),
        experience: readIntValue(data['experience']),
        unspentStatPoints: readIntValue(data['unspentStatPoints']),
        isV2: readBoolValue(data['isV2']),
        grade: readIntValue(data['grade']),
        ownerLevel: readIntValue(data['ownerLevel']),
        ownerGrade: readIntValue(data['ownerGrade']),
        stats: data['stats'] is Map
            ? oculumPawnStats(
                (data['stats'] as Map).map(
                  (key, value) => MapEntry('$key', readIntValue(value)),
                ),
              )
            : null,
        pendingRegistration: readBoolValue(data['pendingRegistration']),
        conscious: readBoolValue(data['conscious']),
        baseStats: data['baseStats'] is Map
            ? (data['baseStats'] as Map).map(
                (key, value) => MapEntry('$key', readIntValue(value)),
              )
            : null,
        allocatedStats: data['allocatedStats'] is Map
            ? (data['allocatedStats'] as Map).map(
                (key, value) => MapEntry('$key', readIntValue(value)),
              )
            : null,
        targets: (data['targets'] is List ? data['targets'] as List : const [])
            .whereType<String>()
            .where((tag) => tag.isNotEmpty)
            .toSet()
            .toList(),
      );
}

extension _OculumPawnRuntime on _OculumHomePageState {
  bool get pawnRemoteAuthority =>
      realtimeService?.isConnected == true && !realtimeIsMasterRole;
  String get pawnSenderTag => sheetTagAt(schedaCorrente);
  String get pawnSenderRole => realtimeIsMasterRole
      ? 'master'
      : realtimeIsCoMasterRole
      ? 'coMaster'
      : 'player';

  void loadPawnCampaignState(Map<String, dynamic> data) {
    for (final timer in pawnDamageRetryTimers.values) {
      timer.cancel();
    }
    pawnDamageRetryTimers.clear();
    for (final waiter in pawnDamageWaiters.values) {
      if (!waiter.isCompleted) {
        waiter.completeError(
          StateError(
            'Campagna cambiata: il danno resta in sospeso nella campagna originale.',
          ),
        );
      }
    }
    pawnDamageWaiters.clear();
    pawnGuardians
      ..clear()
      ..addAll(
        (data['pawnGuardians'] is List
                ? data['pawnGuardians'] as List
                : const [])
            .whereType<Map>()
            .map(
              (raw) =>
                  OculumPawnGuardian.fromJson(Map<String, dynamic>.from(raw)),
            ),
      );
    pawnDamageReceipts.clear();
    if (data['pawnDamageReceipts'] is Map) {
      for (final entry in (data['pawnDamageReceipts'] as Map).entries) {
        if (entry.value is Map) {
          pawnDamageReceipts['${entry.key}'] = Map<String, dynamic>.from(
            entry.value,
          );
        }
      }
    }
    pawnPendingDamage = data['pawnPendingDamage'] is Map
        ? Map<String, dynamic>.from(data['pawnPendingDamage'])
        : {};
  }

  Map<String, int> pawnOwnerStats(String ownerTag) {
    final index = schedePersonaggio.indexWhere(
      (sheet) =>
          '${sheet['sheetTag'] ?? sheet['id'] ?? ''}' == ownerTag ||
          sheetTagAt(schedePersonaggio.indexOf(sheet)) == ownerTag,
    );
    if (index < 0) {
      return {
        'resilienza': resilienzaBase(),
        'volonta': volontaBase(),
        'materia': materiaBase(),
        'oculum': oculumBase(),
      };
    }
    final sheet = schedePersonaggio[index];
    final active = ownerTag == pawnSenderTag && index == schedaCorrente;
    return {
      'resilienza': max(
        0,
        active ? resilienzaBase() : readIntValue(sheet['resilienza']),
      ),
      'volonta': max(
        0,
        active ? volontaBase() : readIntValue(sheet['volonta']),
      ),
      'materia': max(
        0,
        active ? materiaBase() : readIntValue(sheet['materia']),
      ),
      'oculum': max(0, active ? oculumBase() : readIntValue(sheet['oculum'])),
    };
  }

  int pawnOwnerValue(String ownerTag, String key, int currentValue) {
    if (ownerTag == pawnSenderTag) {
      return switch (key) {
        'livello' => leggiNumero(livelloController),
        'grado' => leggiNumero(gradoController),
        'resilienza' => resilienzaBase(),
        'volonta' => volontaBase(),
        'materia' => materiaBase(),
        'oculum' => oculumBase(),
        _ => currentValue,
      };
    }
    final index = schedePersonaggio.indexWhere(
      (sheet) =>
          '${sheet['sheetTag'] ?? sheet['id'] ?? ''}' == ownerTag ||
          sheetTagAt(schedePersonaggio.indexOf(sheet)) == ownerTag,
    );
    if (index < 0) return 0;
    final sheet = schedePersonaggio[index];
    return switch (key) {
      'livello' => readIntValue(sheet['livello'] ?? sheet['level']),
      'grado' => readIntValue(sheet['grado'] ?? sheet['grade']),
      'resilienza' => readIntValue(sheet['resilienza']),
      'volonta' => readIntValue(sheet['volonta']),
      'materia' => readIntValue(sheet['materia']),
      'oculum' => readIntValue(sheet['oculum']),
      _ => currentValue,
    };
  }

  Map<String, dynamic> pawnEnvelope(Map<String, dynamic> payload) => {
    ...payload,
    'campaignId': activeCampaignId,
    'senderTag': pawnSenderTag,
    'senderRole': pawnSenderRole,
  };

  Future<void> sendPawnMessage(
    String event,
    Map<String, dynamic> payload,
  ) async {
    final service = realtimeService;
    if (service?.isConnected != true) return;
    try {
      await service!.sendPawnEvent(event, pawnEnvelope(payload));
    } catch (error) {
      debugPrint('Invio Pawn in attesa: $error');
    }
  }

  void sendPawnSnapshot() {
    if (realtimeIsMasterRole) {
      unawaited(
        sendPawnMessage('pawn_snapshot', {
          'pawns': pawnGuardians
              .where((pawn) => !pawn.pendingRegistration)
              .map((pawn) => pawn.toJson())
              .toList(),
        }),
      );
    }
  }

  void syncPawnPresence() {
    if (realtimeIsMasterRole) {
      sendPawnSnapshot();
      return;
    }
    for (final pawn in pawnGuardians.where(
      (pawn) => pawn.pendingRegistration && pawn.ownerTag == pawnSenderTag,
    )) {
      unawaited(
        sendPawnMessage('pawn_command', {
          'action': 'create',
          'pawnId': pawn.id,
          'targets': pawn.targets,
          'pawnData': pawn.toJson(),
        }),
      );
    }
    if (pawnPendingDamage.isNotEmpty) retryPawnDamage(pawnPendingDamage);
    unawaited(sendPawnMessage('pawn_command', {'action': 'snapshot'}));
  }

  Future<void> activatePawnItem(InventoryItem item) async {
    if (!inventario.contains(item) || item.quantita <= 0) return;
    final isV2 = item.craftData['pawnV2'] == true;
    final recoveryLevel = max(0, readIntValue(item.craftData['recoveryLevel']));
    final recoveryGrade = oculumGradeForLevel(recoveryLevel);
    final recoveryAllocation = oculumPawnProportionalStatAllocation(
      (recoveryLevel + recoveryGrade) * oculumPawnStatPointsPerLevel,
    );
    final recoveryStats = {
      for (final entry in oculumPawnStats(null).entries)
        entry.key: entry.value + (recoveryAllocation[entry.key] ?? 0),
    };
    final ownerLevel = pawnOwnerValue(
      pawnSenderTag,
      'livello',
      leggiNumero(livelloController),
    );
    final ownerGrade = pawnOwnerValue(
      pawnSenderTag,
      'grado',
      leggiNumero(gradoController),
    );
    final ownerStats = pawnOwnerStats(pawnSenderTag);
    final inherited = <String, int>{
      for (final entry in ownerStats.entries) entry.key: entry.value ~/ 2,
    };
    final pawn = OculumPawnGuardian(
      id: 'pawn_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1000000)}',
      ownerTag: pawnSenderTag,
      hp: isV2
          ? max(1, inherited['resilienza'] ?? 0) * 10
          : recoveryLevel > 0
          ? recoveryStats['resilienza']! * 10
          : 30,
      level: recoveryLevel,
      conscious: item.craftData['conscious'] == true,
      isV2: isV2,
      grade: isV2 ? ownerGrade : recoveryGrade,
      ownerLevel: isV2 ? ownerLevel : 0,
      ownerGrade: isV2 ? ownerGrade : 0,
      stats: isV2
          ? inherited
          : recoveryLevel > 0
          ? recoveryStats
          : null,
      baseStats: isV2 ? inherited : null,
      allocatedStats: recoveryLevel > 0 ? recoveryAllocation : null,
      unspentStatPoints: isV2
          ? (ownerLevel + ownerGrade) * oculumPawnStatPointsPerLevel
          : 0,
      pendingRegistration: pawnRemoteAuthority,
    );
    setState(() {
      item.quantita--;
      if (item.quantita == 0) inventario.remove(item);
      pawnGuardians.add(pawn);
      risultato =
          '${pawn.displayName} attivato: ${pawn.hp} HP, livello ${pawn.level}${isV2 ? ' · grado ${pawn.grade} · statistiche pari alla metà della scheda proprietaria' : ''}${pawn.conscious ? ' · coscienza originale conservata' : ''}. Seleziona le schede da proteggere.';
      aggiungiLog(risultato);
    });
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
    if (pawn.pendingRegistration) {
      unawaited(
        sendPawnMessage('pawn_command', {
          'action': 'create',
          'pawnId': pawn.id,
          'targets': pawn.targets,
          'pawnData': pawn.toJson(),
        }),
      );
    } else {
      sendPawnSnapshot();
    }
    await choosePawnTargets(pawn);
  }

  Future<void> choosePawnTargets(OculumPawnGuardian pawn) async {
    final choices = <String, String>{};
    for (var i = 0; i < schedePersonaggio.length; i++) {
      choices[sheetTagAt(i)] =
          '${schedePersonaggio[i]['nome'] ?? 'Scheda ${i + 1}'} (locale)';
    }
    for (final user in realtimeUsers) {
      if ('${user['campaignId']}' != activeCampaignId) continue;
      final tag = '${user['activeSheetTag'] ?? ''}';
      if (tag.isNotEmpty) {
        choices[tag] =
            '${user['activeSheetName'] ?? user['playerName'] ?? tag} (online)';
      }
    }
    for (final tag in pawn.targets) {
      choices.putIfAbsent(tag, () => '$tag (salvato)');
    }
    final selected = pawn.targets.toSet();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, refresh) => AlertDialog(
          title: Text('Schede protette da ${pawn.displayName}'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final choice in choices.entries)
                    CheckboxListTile(
                      value: selected.contains(choice.key),
                      title: Text(choice.value),
                      onChanged: (value) => refresh(() {
                        if (value == true) {
                          selected.add(choice.key);
                        } else {
                          selected.remove(choice.key);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selected.toList()),
              child: const Text('Proteggi'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    if (pawnRemoteAuthority) {
      unawaited(
        sendPawnMessage('pawn_command', {
          'action': 'targets',
          'pawnId': pawn.id,
          'targets': result,
        }),
      );
      if (pawn.pendingRegistration) pawn.targets = result;
    } else {
      setState(() => pawn.targets = result);
      sendPawnSnapshot();
    }
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
  }

  void updatePawnInitiativeToken(OculumPawnGuardian pawn) {
    for (final token in masterInitiativeTokens.where(
      (token) => token['pawnId'] == pawn.id,
    )) {
      token['hp'] = pawn.hp;
      token['maxHp'] = pawn.maxHp;
      token['resilienza'] = pawn.stats['resilienza'];
      token['volonta'] = pawn.stats['volonta'];
      token['materia'] = pawn.stats['materia'];
      token['oculum'] = pawn.stats['oculum'];
      token['level'] = pawn.level;
      token['grade'] = pawn.grade;
      token['reportedTurn'] = pawn.turn;
      token['status'] = pawn.alive ? 'ready' : 'dead';
      token['dead'] = !pawn.alive;
    }
  }

  void addPawnToInitiative(OculumPawnGuardian pawn) {
    if (pawnRemoteAuthority) {
      if (pawn.ownerTag == pawnSenderTag || realtimeIsCoMasterRole) {
        unawaited(
          sendPawnMessage('pawn_command', {
            'action': 'initiative',
            'pawnId': pawn.id,
          }),
        );
      }
      return;
    }
    if (masterInitiativeTokens.any((token) => token['pawnId'] == pawn.id)) {
      return;
    }
    setState(
      () => masterInitiativeTokens.add({
        'id': pawn.id,
        'sheetTag': pawn.id,
        'pawnId': pawn.id,
        'name': pawn.displayName,
        'role': 'pawn',
        'hp': pawn.hp,
        'maxHp': pawn.maxHp,
        'volonta': pawn.stats['volonta'],
        'materia': pawn.stats['materia'],
        'oculum': pawn.stats['oculum'],
        'resilienza': pawn.stats['resilienza'],
        'level': pawn.level,
        'grade': pawn.grade,
        'initiativeTotal': 0,
        'reportedTurn': pawn.turn,
        'status': pawn.alive ? 'ready' : 'dead',
        'dead': !pawn.alive,
      }),
    );
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  Future<void> advancePawnTurn(String id, int turn) async {
    final pawn = pawnGuardians.where((pawn) => pawn.id == id).firstOrNull;
    if (pawn == null) return;
    if (pawnRemoteAuthority) {
      if ((pawn.ownerTag == pawnSenderTag || realtimeIsCoMasterRole) &&
          pawn.alive) {
        unawaited(
          sendPawnMessage('pawn_command', {
            'action': 'advance',
            'pawnId': pawn.id,
            'turn': turn,
          }),
        );
      }
      return;
    }
    if (turn <= pawn.turn) return;
    final pointsBefore = pawn.unspentStatPoints;
    final gradeBefore = pawn.grade;
    if (pawn.isV2) {
      pawn.syncOwnerProgress(
        level: pawnOwnerValue(pawn.ownerTag, 'livello', 0),
        grade: pawnOwnerValue(pawn.ownerTag, 'grado', 0),
        ownerStats: pawnOwnerStats(pawn.ownerTag),
      );
    }
    final previousLevel = pawn.level;
    final threshold = oculumPawnExperienceForLevel(
      normalizedCampaignDifficulty(),
    );
    if (!pawn.advanceTo(turn, difficulty: normalizedCampaignDifficulty())) {
      return;
    }
    updatePawnInitiativeToken(pawn);
    aggiungiLog(
      '${pawn.displayName}: turno ${pawn.turn}, ${pawn.hp}/${pawn.maxHp} HP, ${pawn.shield} Scudo. EXP ${pawn.experience}/$threshold, livello ${pawn.level}, grado ${pawn.grade}${pawn.level > previousLevel || pawn.grade > gradeBefore || pawn.unspentStatPoints > pointsBefore ? ', ${pawn.unspentStatPoints} punti statistica disponibili' : ''}${pawn.savingShield ? ', Scudo di Salvataggio pronto' : ''}.',
    );
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
    sendPawnSnapshot();
    if (pawn.level > previousLevel ||
        pawn.grade > gradeBefore ||
        pawn.unspentStatPoints > pointsBefore) {
      await showPawnStatAllocationIfNeeded(pawn);
    }
  }

  Future<void> showPawnStatAllocationIfNeeded(OculumPawnGuardian pawn) async {
    if (pawn.unspentStatPoints <= 0 || !mounted) return;
    final controllers = <String, TextEditingController>{
      for (final stat in const ['resilienza', 'volonta', 'materia', 'oculum'])
        stat: TextEditingController(text: '0'),
    };
    try {
      final allocation = await showDialog<Map<String, int>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            '${pawn.displayName} · Lv ${pawn.level} · Gr ${pawn.grade}: assegna punti',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Punti disponibili: ${pawn.unspentStatPoints}'),
              const Text(
                'Profilo Pawn base: 3 Resilienza : 3 Volontà : 5 Materia : 0 Oculum.',
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    final suggested = oculumPawnProportionalStatAllocation(
                      pawn.unspentStatPoints,
                    );
                    for (final entry in suggested.entries) {
                      controllers[entry.key]!.text = '${entry.value}';
                    }
                  },
                  icon: const Icon(Icons.balance),
                  label: const Text('Usa proporzione Pawn base'),
                ),
              ),
              for (final entry in controllers.entries)
                TextField(
                  controller: entry.value,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: switch (entry.key) {
                      'resilienza' => 'Resilienza',
                      'volonta' => 'Volontà',
                      'materia' => 'Materia',
                      _ => 'Oculum',
                    },
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Dopo'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                controllers.map(
                  (key, controller) => MapEntry(
                    key,
                    max(0, int.tryParse(controller.text.trim()) ?? 0),
                  ),
                ),
              ),
              child: const Text('Assegna'),
            ),
          ],
        ),
      );
      if (allocation == null || !mounted) return;
      if (pawnRemoteAuthority) {
        if (pawn.ownerTag != pawnSenderTag && !realtimeIsCoMasterRole) return;
        final requested = allocation.values.fold<int>(
          0,
          (sum, value) => sum + value,
        );
        if (allocation.values.any((value) => value < 0) ||
            requested <= 0 ||
            requested > pawn.unspentStatPoints) {
          risultato =
              'Punti Pawn non assegnati: distribuisci al massimo ${pawn.unspentStatPoints} punti disponibili.';
          notifyDiceResultChanged();
          return;
        }
        unawaited(
          sendPawnMessage('pawn_command', {
            'action': 'allocate',
            'pawnId': pawn.id,
            'allocation': allocation,
          }),
        );
        return;
      }
      if (!pawn.allocateStatPoints(allocation)) {
        risultato =
            'Punti Pawn non assegnati: distribuisci al massimo ${pawn.unspentStatPoints} punti disponibili.';
        notifyDiceResultChanged();
        return;
      }
      updatePawnInitiativeToken(pawn);
      aggiungiLog(
        'Pawn livello ${pawn.level}: statistiche ${pawn.stats.entries.map((entry) => '${entry.key} ${entry.value}').join(', ')}; ${pawn.unspentStatPoints} punti restanti.',
      );
      programmaSalvataggio();
      sendPawnSnapshot();
      notifyActiveSheetSummaryChanged();
    } finally {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
  }

  int redirectPawnHpDamage(String tag, int damage) {
    var remaining = max(0, damage);
    for (final pawn in pawnGuardians.where(
      (pawn) =>
          pawn.alive && !pawn.pendingRegistration && pawn.targets.contains(tag),
    )) {
      if (remaining == 0) break;
      final before = remaining;
      final hpBefore = pawn.hp;
      final shieldBefore = pawn.shield;
      final savingShieldBefore = pawn.savingShield;
      remaining = pawn.intercept(remaining);
      claimBrokenPawnCore(pawn);
      updatePawnInitiativeToken(pawn);
      aggiungiLog(
        '${pawn.displayName} subisce al posto di $tag ${before - remaining} danni destinati alla Vita: perde ${hpBefore - pawn.hp} HP ($hpBefore → ${pawn.hp}/${pawn.maxHp}) e ${shieldBefore - pawn.shield} Scudo ($shieldBefore → ${pawn.shield}).${savingShieldBefore && !pawn.savingShield ? " Scudo di Salvataggio consumato: la Vita è protetta dal colpo che esaurisce lo Scudo." : ""}',
      );
    }
    if (remaining != damage) {
      notifyActiveSheetSummaryChanged();
      programmaSalvataggio();
      sendPawnSnapshot();
    }
    return remaining;
  }

  bool pawnProtects(String tag) => pawnGuardians.any(
    (pawn) =>
        pawn.alive && !pawn.pendingRegistration && pawn.targets.contains(tag),
  );

  void retryPawnDamage(Map<String, dynamic> request) {
    final id = '${request['requestId']}';
    if ('${request['campaignId']}' != activeCampaignId) return;
    unawaited(sendPawnMessage('pawn_intercept_request', request));
    pawnDamageRetryTimers.putIfAbsent(
      id,
      () => Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted || pawnPendingDamage['requestId'] != id) {
          pawnDamageRetryTimers.remove(id)?.cancel();
          return;
        }
        unawaited(sendPawnMessage('pawn_intercept_request', request));
      }),
    );
  }

  Future<int> requestPawnHpInterception(int amount) async {
    final id =
        'pawn_hit_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1000000)}';
    final waiter = Completer<int>();
    pawnDamageWaiters[id] = waiter;
    pawnPendingDamage = {
      'requestId': id,
      'campaignId': activeCampaignId,
      'sheetTag': pawnSenderTag,
      'amount': amount,
    };
    await forzaSalvataggioImmediato(soloLocale: true);
    retryPawnDamage(pawnPendingDamage);
    notifyActiveSheetSummaryChanged();
    aggiungiLog(
      'Danno alla Vita in attesa del Master: $amount HP, protezione Pawn da risolvere.',
    );
    return waiter.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        pawnDamageWaiters.remove(id);
        throw TimeoutException(
          'Il Master non ha ancora confermato il danno. La richiesta resta in attesa e verrà applicata alla risposta.',
        );
      },
    );
  }

  bool validPawnSender(
    Map<String, dynamic> payload, {
    bool masterOnly = false,
  }) =>
      '${payload['campaignId']}' == activeCampaignId &&
      (!masterOnly || payload['senderRole'] == 'master') &&
      realtimeUsers.any(
        (user) =>
            '${user['campaignId']}' == activeCampaignId &&
            '${user['activeSheetTag']}' == '${payload['senderTag']}' &&
            '${user['role']}'.toLowerCase() ==
                '${payload['senderRole']}'.toLowerCase(),
      );

  void receivePawnEvent(String event, Map<String, dynamic> payload) {
    if (!validPawnSender(
      payload,
      masterOnly: event == 'pawn_snapshot' || event == 'pawn_intercept_result',
    )) {
      return;
    }
    if (event == 'pawn_snapshot' &&
        !realtimeIsMasterRole &&
        payload['pawns'] is List) {
      final received = (payload['pawns'] as List)
          .whereType<Map>()
          .map(
            (raw) =>
                OculumPawnGuardian.fromJson(Map<String, dynamic>.from(raw)),
          )
          .toList();
      final pending = pawnGuardians
          .where(
            (pawn) =>
                pawn.pendingRegistration &&
                !received.any((other) => other.id == pawn.id),
          )
          .toList();
      setState(() {
        pawnGuardians
          ..clear()
          ..addAll(received)
          ..addAll(pending);
        for (final pawn in received.where(
          (p) => p.ownerTag == pawnSenderTag && !p.alive,
        )) {
          claimBrokenPawnCore(pawn);
        }
      });
      notifyActiveSheetSummaryChanged();
      programmaSalvataggio();
    } else if (event == 'pawn_command' && realtimeIsMasterRole) {
      final sender = '${payload['senderTag']}';
      final id = '${payload['pawnId'] ?? ''}';
      final action = '${payload['action']}';
      final targets =
          (payload['targets'] is List ? payload['targets'] as List : const [])
              .whereType<String>()
              .toSet()
              .toList();
      final pawn = pawnGuardians.where((pawn) => pawn.id == id).firstOrNull;
      if (action == 'create' && id.startsWith('pawn_') && pawn == null) {
        final raw = payload['pawnData'] is Map
            ? Map<String, dynamic>.from(payload['pawnData'] as Map)
            : <String, dynamic>{};
        raw['id'] = id;
        raw['ownerTag'] = sender;
        raw['targets'] = targets;
        raw['pendingRegistration'] = false;
        final created = OculumPawnGuardian.fromJson(raw);
        if (created.isV2) {
          created.level = 0;
          created.experience = 0;
          created.turn = 0;
          created.ownerLevel = 0;
          created.ownerGrade = 0;
          created.grade = 0;
          created.unspentStatPoints = 0;
          created.allocatedStats.updateAll((key, _) => 0);
          created.baseStats.updateAll((key, _) => 0);
          created.stats.updateAll((key, _) => created.allocatedStats[key] ?? 0);
          created.hp = 1;
          created.shield = 0;
          created.savingShield = false;
          created.syncOwnerProgress(
            level: pawnOwnerValue(sender, 'livello', 0),
            grade: pawnOwnerValue(sender, 'grado', 0),
            ownerStats: pawnOwnerStats(sender),
          );
          created.hp = created.maxHp;
        }
        pawnGuardians.add(created);
      } else if (action == 'targets' &&
          pawn != null &&
          (pawn.ownerTag == sender || payload['senderRole'] == 'coMaster')) {
        pawn.targets = targets;
      } else if (action == 'allocate' &&
          pawn != null &&
          (pawn.ownerTag == sender || payload['senderRole'] == 'coMaster') &&
          payload['allocation'] is Map) {
        final allocation = (payload['allocation'] as Map).map(
          (key, value) => MapEntry('$key', readIntValue(value)),
        );
        if (pawn.allocateStatPoints(allocation)) {
          updatePawnInitiativeToken(pawn);
        }
      } else if (action == 'advance' &&
          pawn != null &&
          (pawn.ownerTag == sender || payload['senderRole'] == 'coMaster') &&
          pawn.alive) {
        if (pawn.isV2) {
          pawn.syncOwnerProgress(
            level: pawnOwnerValue(pawn.ownerTag, 'livello', 0),
            grade: pawnOwnerValue(pawn.ownerTag, 'grado', 0),
            ownerStats: pawnOwnerStats(pawn.ownerTag),
          );
        }
        final requestedTurn = readIntValue(payload['turn']);
        if (requestedTurn > pawn.turn) {
          pawn.advanceTo(
            requestedTurn,
            difficulty: normalizedCampaignDifficulty(),
          );
          updatePawnInitiativeToken(pawn);
        }
      } else if (action == 'initiative' &&
          pawn != null &&
          (pawn.ownerTag == sender || payload['senderRole'] == 'coMaster')) {
        addPawnToInitiative(pawn);
      }
      notifyActiveSheetSummaryChanged();
      programmaSalvataggio();
      sendPawnSnapshot();
    } else if (event == 'pawn_intercept_request' &&
        realtimeIsMasterRole &&
        payload['sheetTag'] == payload['senderTag']) {
      unawaited(answerPawnInterception(payload));
    } else if (event == 'pawn_intercept_result' &&
        pawnPendingDamage['requestId'] == payload['requestId'] &&
        pawnPendingDamage['sheetTag'] == payload['sheetTag']) {
      final id = '${payload['requestId']}';
      final remaining = readIntValue(
        payload['remaining'],
      ).clamp(0, readIntValue(pawnPendingDamage['amount']));
      pawnDamageRetryTimers.remove(id)?.cancel();
      final waiter = pawnDamageWaiters.remove(id);
      if (waiter != null && !waiter.isCompleted) {
        waiter.complete(remaining);
      } else {
        // Recovery after restart: shields were already committed before the
        // request. Apply only the confirmed HP remainder, never the hit twice.
        final tag = '${pawnPendingDamage['sheetTag']}';
        setState(() {
          if (tag == pawnSenderTag) {
            currentHpController.text = '${max(0, hpCorrenti() - remaining)}';
          } else {
            final sheet = schedePersonaggio
                .where((sheet) => sheet['sheetTag'] == tag)
                .firstOrNull;
            if (sheet != null) {
              sheet['currentHp'] =
                  '${max(0, readIntValue(sheet['currentHp']) - remaining)}';
            }
          }
          pawnPendingDamage = {};
        });
        notifyActiveSheetSummaryChanged();
        programmaSalvataggio();
      }
    }
  }

  Future<void> answerPawnInterception(Map<String, dynamic> payload) async {
    final id = '${payload['requestId']}';
    final tag = '${payload['sheetTag']}';
    final amount = max(0, readIntValue(payload['amount']));
    if (id.isEmpty || amount == 0) {
      return;
    }
    var receipt = pawnDamageReceipts[id];
    if (receipt != null &&
        (receipt['sheetTag'] != tag || receipt['amount'] != amount)) {
      return;
    }
    receipt ??= {
      'sheetTag': tag,
      'amount': amount,
      'remaining': redirectPawnHpDamage(tag, amount),
    };
    pawnDamageReceipts[id] = receipt;
    await forzaSalvataggioImmediato(soloLocale: true);
    await sendPawnMessage('pawn_intercept_result', {
      'requestId': id,
      ...receipt,
    });
  }

  Widget pawnGuardiansPanel() => ValueListenableBuilder<int>(
    valueListenable: activeSheetSummaryRevision,
    builder: (_, revision, child) =>
        pawnGuardians.isEmpty && pawnPendingDamage.isEmpty
        ? const SizedBox.shrink()
        : gothicPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sectionTitle('Pawn · Guardiani'),
                if (pawnPendingDamage.isNotEmpty)
                  Text(
                    'Danno agli HP in attesa del Master. Richiesta salvata: viene ritentata senza duplicare il danno.',
                  ),
                for (final pawn in pawnGuardians)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pawn.displayName} · Lv ${pawn.level} · Gr ${pawn.grade} · ${pawn.stats['resilienza']} Res · ${pawn.stats['volonta']} Vol · ${pawn.stats['materia']} Mat · ${pawn.stats['oculum']} Ocu\n${pawn.hp}/${pawn.maxHp} HP · ${pawn.shield} Scudo · EXP ${pawn.experience}/${oculumPawnExperienceForLevel(normalizedCampaignDifficulty())} · +${pawn.experiencePerTurn} EXP/turno · Turno ${pawn.turn}${pawn.isV2 ? ' · Proprietario Lv ${pawn.ownerLevel} / Gr ${pawn.ownerGrade}' : ''}${pawn.unspentStatPoints > 0 ? ' · ${pawn.unspentStatPoints} punti da assegnare' : ''}${pawn.savingShield ? ' · Scudo di Salvataggio' : ''}${pawn.pendingRegistration ? ' · Registrazione in attesa del Master' : ''}',
                        ),
                        if (pawn.isV2)
                          Text(
                            'Pawn V2: statistiche base pari alla metà della scheda proprietaria; ogni livello proprio, livello del proprietario e grado assegna 6 punti. Profilo guida 3:3:5:0.',
                          ),
                        Text(
                          '${pawn.targets.length} schede protette${pawn.alive ? '' : ' · Inattivo a 0 HP'}',
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (!pawnRemoteAuthority ||
                                haPermessiMaster ||
                                pawn.ownerTag == pawnSenderTag)
                              OutlinedButton.icon(
                                onPressed: () => choosePawnTargets(pawn),
                                icon: const Icon(Icons.shield_outlined),
                                label: const Text('Scegli bersagli'),
                              ),
                            if (pawn.unspentStatPoints > 0 &&
                                (!pawnRemoteAuthority ||
                                    pawn.ownerTag == pawnSenderTag ||
                                    haPermessiMaster ||
                                    realtimeIsCoMasterRole))
                              OutlinedButton.icon(
                                onPressed: () =>
                                    showPawnStatAllocationIfNeeded(pawn),
                                icon: const Icon(Icons.upgrade),
                                label: const Text('Assegna punti Pawn'),
                              ),
                            OutlinedButton(
                              onPressed:
                                  !pawn.alive ||
                                      (pawnRemoteAuthority &&
                                          pawn.ownerTag != pawnSenderTag &&
                                          !haPermessiMaster &&
                                          !realtimeIsCoMasterRole)
                                  ? null
                                  : () =>
                                        advancePawnTurn(pawn.id, pawn.turn + 1),
                              child: Text('Termina turno ${pawn.displayName}'),
                            ),
                            if (!pawnRemoteAuthority ||
                                pawn.ownerTag == pawnSenderTag ||
                                haPermessiMaster ||
                                realtimeIsCoMasterRole)
                              OutlinedButton(
                                onPressed: () => addPawnToInitiative(pawn),
                                child: const Text('Aggiungi all’iniziativa'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
  );
}
