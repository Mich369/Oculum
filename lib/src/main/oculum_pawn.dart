part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const oculumPawnPrice = 100;
const oculumPawnDescription =
    'Livello 0 · Resilienza 3 · Volontà 3 · Materia 5 · Oculum 0 · 30 HP. '
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

InventoryItem oculumPawnInventoryItem() => InventoryItem(
  nome: 'Pawn',
  peso: 0,
  quantita: 1,
  note: oculumPawnDescription,
  craftData: {'pawn': true},
);

class OculumPawnGuardian {
  OculumPawnGuardian({
    required this.id,
    required this.ownerTag,
    this.hp = 30,
    this.shield = 0,
    this.savingShield = false,
    this.turn = 0,
    this.pendingRegistration = false,
    List<String>? targets,
  }) : targets = List.of(targets ?? const []) {
    hp = hp.clamp(0, 30);
    shield = max(0, shield);
    turn = max(0, turn);
  }
  final String id;
  final String ownerTag;
  int hp;
  int shield;
  bool savingShield;
  int turn;
  bool pendingRegistration;
  List<String> targets;
  bool get alive => hp > 0;

  /// Returns HP damage still reaching the protected target. This amount has
  /// already passed the target's defense and shields: never reduce it twice.
  int intercept(int damage) {
    final incoming = max(0, damage);
    if (!alive || pendingRegistration || incoming == 0) return incoming;
    final shieldBefore = shield;
    final absorbedShield = min(shield, incoming);
    shield -= absorbedShield;
    var remaining = incoming - absorbedShield;
    if (savingShield && shieldBefore > 0 && shield == 0 && remaining > 0) {
      savingShield = false;
      return 0;
    }
    final absorbedHp = min(hp, remaining);
    hp -= absorbedHp;
    remaining -= absorbedHp;
    return remaining;
  }

  bool advanceTo(int nextTurn) {
    if (nextTurn <= turn || !alive || pendingRegistration) return false;
    while (turn < nextTurn) {
      if (hp < 30) {
        hp = min(30, hp + 10);
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
    'targets': targets.toList(),
    'pendingRegistration': pendingRegistration,
  };
  factory OculumPawnGuardian.fromJson(Map<String, dynamic> data) =>
      OculumPawnGuardian(
        id: '${data['id'] ?? ''}',
        ownerTag: '${data['ownerTag'] ?? ''}',
        hp: readIntValue(data['hp'], fallback: 30),
        shield: readIntValue(data['shield']),
        savingShield: readBoolValue(data['savingShield']),
        turn: readIntValue(data['turn']),
        pendingRegistration: readBoolValue(data['pendingRegistration']),
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
        }),
      );
    }
    if (pawnPendingDamage.isNotEmpty) retryPawnDamage(pawnPendingDamage);
    unawaited(sendPawnMessage('pawn_command', {'action': 'snapshot'}));
  }

  Future<void> activatePawnItem(InventoryItem item) async {
    if (!inventario.contains(item) || item.quantita <= 0) return;
    final pawn = OculumPawnGuardian(
      id: 'pawn_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1000000)}',
      ownerTag: pawnSenderTag,
      pendingRegistration: pawnRemoteAuthority,
    );
    setState(() {
      item.quantita--;
      if (item.quantita == 0) inventario.remove(item);
      pawnGuardians.add(pawn);
      risultato =
          'Pawn attivato: 30 HP, livello 0. Seleziona le schede da proteggere.';
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
          title: const Text('Schede protette da Pawn'),
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
      token['maxHp'] = 30;
      token['reportedTurn'] = pawn.turn;
      token['status'] = pawn.alive ? 'ready' : 'dead';
      token['dead'] = !pawn.alive;
    }
  }

  void advancePawnTurn(String id, int turn) {
    if (pawnRemoteAuthority) return;
    final pawn = pawnGuardians.where((pawn) => pawn.id == id).firstOrNull;
    if (pawn == null || !pawn.advanceTo(turn)) return;
    updatePawnInitiativeToken(pawn);
    aggiungiLog(
      'Pawn: turno ${pawn.turn}, ${pawn.hp}/30 HP, ${pawn.shield} Scudo${pawn.savingShield ? ', Scudo di Salvataggio pronto' : ''}.',
    );
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
    sendPawnSnapshot();
  }

  int redirectPawnHpDamage(String tag, int damage) {
    var remaining = max(0, damage);
    for (final pawn in pawnGuardians.where(
      (pawn) =>
          pawn.alive && !pawn.pendingRegistration && pawn.targets.contains(tag),
    )) {
      if (remaining == 0) break;
      final before = remaining;
      remaining = pawn.intercept(remaining);
      updatePawnInitiativeToken(pawn);
      aggiungiLog(
        'Pawn intercetta ${before - remaining} danni agli HP di $tag: ${pawn.hp}/30 HP, ${pawn.shield} Scudo.',
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
    return waiter.future;
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
        pawnGuardians.add(
          OculumPawnGuardian(id: id, ownerTag: sender, targets: targets),
        );
      } else if (action == 'targets' &&
          pawn != null &&
          (pawn.ownerTag == sender || payload['senderRole'] == 'coMaster')) {
        pawn.targets = targets;
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
                          'Pawn · Lv 0 · 3 Res · 3 Vol · 5 Mat · 0 Ocu\n${pawn.hp}/30 HP · ${pawn.shield} Scudo · Turno ${pawn.turn}${pawn.savingShield ? ' · Scudo di Salvataggio' : ''}${pawn.pendingRegistration ? ' · Registrazione in attesa del Master' : ''}',
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
                            OutlinedButton(
                              onPressed: pawnRemoteAuthority || !pawn.alive
                                  ? null
                                  : () =>
                                        advancePawnTurn(pawn.id, pawn.turn + 1),
                              child: const Text('Termina turno Pawn'),
                            ),
                            if (!pawnRemoteAuthority)
                              OutlinedButton(
                                onPressed: () {
                                  if (masterInitiativeTokens.any(
                                    (token) => token['pawnId'] == pawn.id,
                                  )) {
                                    return;
                                  }
                                  setState(
                                    () => masterInitiativeTokens.add({
                                      'id': pawn.id,
                                      'sheetTag': pawn.id,
                                      'pawnId': pawn.id,
                                      'name': 'Pawn',
                                      'role': 'pawn',
                                      'hp': pawn.hp,
                                      'maxHp': 30,
                                      'volonta': 3,
                                      'materia': 5,
                                      'oculum': 0,
                                      'resilienza': 3,
                                      'level': 0,
                                      'initiativeTotal': 0,
                                      'reportedTurn': pawn.turn,
                                      'status': pawn.alive ? 'ready' : 'dead',
                                      'dead': !pawn.alive,
                                    }),
                                  );
                                  programmaSalvataggio();
                                  notifyActiveSheetSummaryChanged();
                                  sendRealtimeInitiativeSnapshotIfPublished();
                                },
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
