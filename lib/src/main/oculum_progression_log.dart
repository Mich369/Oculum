part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

final _progressionLogSending = Expando<bool>();

String oculumProgressionLogText(Map row) {
  final name = '${row['sheetName'] ?? '???'}';
  final amount = max(0, readIntValue(row['amount']));
  final before = max(0, readIntValue(row['beforeLevel']));
  final after = max(before, readIntValue(row['afterLevel']));
  final reason = '${row['reason'] ?? ''}'.trim();
  return '[EXP] $name: +$amount EXP${reason.isEmpty ? '' : ' · $reason'}.'
      '${after > before ? ' [LIVELLO] $name: $before → $after (+${after - before}).' : ''}';
}

extension _OculumProgressionLog on _OculumHomePageState {
  bool characterProgressionReceiptRecorded(String receiptId) =>
      (progressionLogState['awardReceiptIds'] as List? ?? const []).contains(
        '${sheetTagAt(schedaCorrente)}:$receiptId',
      );
  Map<String, dynamic> get progressionLogState {
    final raw = extraTopLevelSaveFields['progressionLogState'];
    if (raw is Map<String, dynamic>) return raw;
    final state = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    extraTopLevelSaveFields['progressionLogState'] = state;
    return state;
  }

  void recordCharacterProgressionLog({
    required int amount,
    required int beforeLevel,
    required String reason,
    String? receiptId,
  }) {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return;
    }
    final tag = sheetTagAt(schedaCorrente);
    if (tag.isEmpty ||
        schedePersonaggio[schedaCorrente]['realtimeSharedSheet'] == true) {
      return;
    }
    final state = progressionLogState;
    final recorded = (state['recordedIds'] as List? ?? const [])
        .map((value) => '$value')
        .toSet();
    final id = receiptId == null
        ? '$tag:exp:${DateTime.now().microsecondsSinceEpoch}:${readIntValue(state['sequence']) + 1}'
        : '$tag:$receiptId';
    if (!recorded.add(id)) return;
    if (receiptId != null) {
      final awards = (state['awardReceiptIds'] as List? ?? const [])
          .map((value) => '$value')
          .toSet();
      if (!awards.add(id)) return;
      // Award receipts are not the bounded display-log cache. Pruning old
      // messages must never make an already-paid settlement payable again.
      state['awardReceiptIds'] = awards.toList();
    }
    state['sequence'] = readIntValue(state['sequence']) + 1;
    state['recordedIds'] = recorded
        .toList()
        .reversed
        .take(1000)
        .toList()
        .reversed
        .toList();
    final after = max(beforeLevel, leggiNumero(livelloController));
    final row = <String, dynamic>{
      'id': id,
      'sheetTag': tag,
      'sheetName': nomeSchedaPersonaggio(schedaCorrente),
      'amount': max(0, amount),
      'beforeLevel': max(0, beforeLevel),
      'afterLevel': after,
      'reason': reason,
      'scope': permissionScope,
      'campaignId': permissionCampaignId,
    };
    if (after > beforeLevel) {
      aggiungiLog(
        '[LIVELLO] ${row['sheetName']}: $beforeLevel → $after (+${after - beforeLevel}).',
      );
    }
    // Offline play stays local. Only messages created in this online room are
    // retried there; joining a different room never publishes past private play.
    if (realtimeService?.isConnected == true) {
      final pending = List<dynamic>.from(state['pending'] as List? ?? const []);
      pending.add(row);
      state['pending'] = pending;
      unawaited(flushProgressionLogs());
    }
    programmaSalvataggio(invalidateCaches: false);
  }

  Future<void> flushProgressionLogs() async {
    final service = realtimeService;
    if (service?.isConnected != true || _progressionLogSending[this] == true) {
      return;
    }
    _progressionLogSending[this] = true;
    try {
      final state = progressionLogState;
      while (true) {
        if (!mounted || realtimeService != service || !service!.isConnected) {
          break;
        }
        final raw = (state['pending'] as List? ?? const [])
            .whereType<Map>()
            .where(
              (row) =>
                  row['scope'] == permissionScope &&
                  row['campaignId'] == permissionCampaignId &&
                  ownPermissionTags.any(
                    (tag) => oculumSameSheetIdentity(tag, row['sheetTag']),
                  ),
            )
            .firstOrNull;
        if (raw == null) break;
        final row = Map<String, dynamic>.from(raw);
        bool sent;
        try {
          sent = await service.sendProgressionLog({
            ...row,
            'senderTag': row['sheetTag'],
            'senderRole': realtimeLocalRole(),
            'message': oculumProgressionLogText(row),
          });
        } catch (_) {
          break;
        }
        if (!sent) break;
        // Re-read after await: a new award may have appended another message.
        final current = List<dynamic>.from(
          state['pending'] as List? ?? const [],
        );
        current.removeWhere(
          (entry) => entry is Map && entry['id'] == row['id'],
        );
        state['pending'] = current;
        programmaSalvataggio(invalidateCaches: false);
      }
    } finally {
      _progressionLogSending[this] = false;
    }
  }

  void receiveProgressionLog(Map<String, dynamic> payload) {
    if (!validPermissionSender(payload) ||
        !oculumSameSheetIdentity(payload['sheetTag'], payload['senderTag'])) {
      return;
    }
    final id = '${payload['id'] ?? ''}';
    if (id.isEmpty ||
        id.length > 500 ||
        '${payload['sheetName'] ?? ''}'.length > 150 ||
        '${payload['reason'] ?? ''}'.length > 500 ||
        readIntValue(payload['amount']) < 0 ||
        readIntValue(payload['afterLevel']) <
            readIntValue(payload['beforeLevel'])) {
      return;
    }
    final state = progressionLogState;
    final seen = (state['receivedIds'] as List? ?? const [])
        .map((value) => '$value')
        .toSet();
    final author = normalizeOculumFriendTag(
      '${payload['sheetTag']}',
    ).toUpperCase();
    final key = '$permissionScope:$author:$id';
    if (!seen.add(key)) return;
    state['receivedIds'] = seen
        .toList()
        .reversed
        .take(1000)
        .toList()
        .reversed
        .toList();
    // The owner already logged the award locally; a server echo is not a
    // second award or a second line. Receiving never changes EXP or levels.
    if (!ownPermissionTags.any(
      (tag) => oculumSameSheetIdentity(tag, payload['sheetTag']),
    )) {
      final text = oculumProgressionLogText(payload);
      aggiungiLog('[Realtime] $text');
      realtimeEvents.insert(0, text);
      if (realtimeEvents.length > 30) {
        realtimeEvents.removeRange(30, realtimeEvents.length);
      }
      if (mounted) setState(() {});
    }
    programmaSalvataggio(invalidateCaches: false);
  }
}

extension OculumProgressionLogProbe on OculumPerformanceProbe {
  Map<String, dynamic> progressionSaveEnvelope() => Map<String, dynamic>.from(
    oculumCopyJsonTree(_state.datiSalvataggioJson(revision: 1)) as Map,
  );
  void restoreProgressionSaveEnvelope(Map<String, dynamic> envelope) =>
      _state._memorizzaCampiTopLevelSconosciuti(envelope);
  Map<String, dynamic> progressionLogSnapshot() => Map<String, dynamic>.from(
    oculumCopyJsonTree(_state.progressionLogState) as Map,
  );
  Future<void> flushProgressionLogs() => _state.flushProgressionLogs();
  String awardExperience(
    int amount, {
    String reason = 'Premio',
    String? receiptId,
  }) => _state.applicaEsperienzaFlat(
    amount,
    motivo: reason,
    applyChainedFate: false,
    progressionReceiptId: receiptId,
  );
}
