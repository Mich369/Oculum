part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const int oculumWorldDaySeconds = 9 * 60 * 60;
const int oculumTravelEventSeconds = 25 * 60;

String oculumWorldPhase(int elapsed) {
  final day = max(0, elapsed) % oculumWorldDaySeconds;
  if (day < 3 * 3600) return 'mattina';
  if (day < 4 * 3600) return 'primo_pomeriggio';
  if (day < 5 * 3600) return 'pomeriggio';
  if (day < 6 * 3600) return 'buio';
  return 'notte';
}

/// No UI countdown: the real timestamp is used only to validate a visit.
Map<String, dynamic> oculumWorldMerchantVisit(
  Map prior, {
  required int day,
  required DateTime now,
}) {
  final previousDay = readIntValue(prior['day'], fallback: -1);
  final last = readIntValue(prior['lastRealAtMs'], fallback: -1);
  if (last >= 0 && now.millisecondsSinceEpoch - last < 15 * 60 * 1000) {
    return {
      ...Map<String, dynamic>.from(prior),
      'counted': false,
      'grantRest': false,
    };
  }
  final visits = (previousDay == day ? readIntValue(prior['visits']) : 0) + 1;
  final rests = previousDay == day ? readIntValue(prior['rests']) : 0;
  final grant = rests < 2 && (visits == 1 || visits == 3);
  return {
    ...Map<String, dynamic>.from(prior),
    'day': day,
    'visits': visits,
    'rests': rests + (grant ? 1 : 0),
    'lastRealAtMs': now.millisecondsSinceEpoch,
    'counted': true,
    'grantRest': grant,
  };
}

extension _OculumWorldMerchantRest on _OculumHomePageState {
  void notifyWorldMerchantVisit() {
    final tag = sheetTagAt(schedaCorrente);
    final payload = permissionEnvelope({
      'id':
          'merchant-visit:$tag:${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(1 << 30)}',
      'worldClockCommand': 'merchant_visit',
      'sourceTag': tag,
      'merchantId': merchantActiveProfileId,
    });
    if (worldClockAuthority || !onlineMasterApprovalRequired) {
      receiveWorldMerchantVisit(payload, local: true);
    } else if (realtimeService?.isConnected == true) {
      unawaited(
        realtimeService?.sendCombatEvent('initiative_control', payload),
      );
    }
  }

  void receiveWorldMerchantVisit(
    Map<String, dynamic> payload, {
    bool local = false,
    DateTime? now,
  }) {
    if (!local && (!worldClockAuthority || !validPermissionSender(payload))) {
      return;
    }
    if (local && onlineMasterApprovalRequired && !worldClockAuthority) return;
    final tag = '${payload['sourceTag'] ?? ''}', id = '${payload['id'] ?? ''}';
    if (tag.isEmpty ||
        id.isEmpty ||
        id.length > 240 ||
        payload['senderTag'] != tag &&
            !const {'master', 'coMaster'}.contains(payload['senderRole'])) {
      return;
    }
    final clock = worldClockProgress;
    final previous = clock.merchantVisits[tag] is Map
        ? clock.merchantVisits[tag] as Map
        : const {};
    if (clock.receipts.contains(id)) {
      if (previous['lastGrant'] is Map) {
        sendWorldMerchantRestGrant(
          Map<String, dynamic>.from(previous['lastGrant'] as Map),
        );
      }
      return;
    }
    clock.receipts.add(id);
    final visit = oculumWorldMerchantVisit(
      previous,
      day: clock.seconds ~/ oculumWorldDaySeconds,
      now: now ?? DateTime.now(),
    );
    if (visit['grantRest'] == true) {
      final grant = {
        'targetTag': tag,
        'receipt': 'merchant-rest:$id',
        'day': clock.seconds ~/ oculumWorldDaySeconds,
      };
      visit['lastGrant'] = grant;
      clock.merchantVisits[tag] = visit;
      storeWorldClock(clock, publish: false);
      if (worldClockAuthority) {
        receiveWorldClockControl(
          permissionEnvelope({
            'id': 'party-time:${grant['receipt']}',
            'worldClockCommand': 'rest_request',
            'restTargetTag': tag,
            'longRest': false,
          }),
        );
      }
      sendWorldMerchantRestGrant(Map<String, dynamic>.from(grant));
    } else {
      clock.merchantVisits[tag] = visit;
      storeWorldClock(clock, publish: false);
      // A retry after a lost broadcast may receive the same grant; its owner
      // has a persistent receipt, so this cannot provide a second rest.
      if (visit['lastGrant'] is Map) {
        sendWorldMerchantRestGrant(
          Map<String, dynamic>.from(visit['lastGrant'] as Map),
        );
      }
    }
  }

  void sendWorldMerchantRestGrant(Map<String, dynamic> grant) {
    final payload = permissionEnvelope({
      'id': 'grant:${grant['receipt']}',
      'worldMerchantRestGrant': grant,
    });
    receiveWorldMerchantRestGrant(payload, local: true);
    if (worldClockAuthority) {
      unawaited(
        realtimeService?.sendCombatEvent('initiative_control', payload),
      );
    }
  }

  void receiveWorldMerchantRestGrant(
    Map<String, dynamic> payload, {
    bool local = false,
  }) {
    if (!local &&
        (payload['senderRole'] != 'master' ||
            !validPermissionSender(payload, staff: true))) {
      return;
    }
    if (local && onlineMasterApprovalRequired && !worldClockAuthority) return;
    final grant = payload['worldMerchantRestGrant'];
    if (grant is! Map) return;
    final tag = '${grant['targetTag'] ?? ''}',
        receipt = '${grant['receipt'] ?? ''}';
    if (receipt.isEmpty || !controlsOnlineCombatSheet(tag)) return;
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0 || schedePersonaggio[index]['realtimeSharedSheet'] == true) {
      return;
    }
    final original = schedaCorrente;
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    try {
      if (index != original) {
        schedaCorrente = index;
        caricaStatoDaJson(schedePersonaggio[index]);
        ripristinaImpostazioniGlobali(global);
      }
      final seen = (planarState['merchantRestReceipts'] as List? ?? const [])
          .map((value) => '$value')
          .toSet();
      if (!seen.add(receipt)) return;
      planarState['merchantRestReceipts'] = seen.toList();
      riposoBreve(advanceWorldClock: false);
      aggiungiLog('[MERCANTE] Riposo Breve della visita confermato.');
      salvaSchedaCorrenteInMemoria();
    } finally {
      if (index != original && mounted) {
        schedaCorrente = original;
        caricaStatoDaJson(schedePersonaggio[original]);
        ripristinaImpostazioniGlobali(global);
      }
    }
    sendRealtimeSheetToStaffAt(index, force: true, ensureMasterReceipt: true);
    syncSharedSheetToMasterEncounters(index);
    programmaSalvataggio();
  }
}

String oculumWorldPhaseName(String phase) =>
    const {
      'mattina': 'Mattina',
      'primo_pomeriggio': 'Primo pomeriggio',
      'pomeriggio': 'Pomeriggio pieno',
      'buio': 'Buio che si inoltra',
      'notte': 'Notte',
    }[phase] ??
    'Mattina';

String oculumWorldDuration(int seconds) {
  final safe = max(0, seconds);
  final hours = safe ~/ 3600, minutes = safe % 3600 ~/ 60;
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}

int oculumWorldMonsterCoreBonus(
  int seconds,
  int level,
  int grade, {
  required bool isMonster,
}) {
  if (!isMonster) return 0;
  return (switch (oculumWorldPhase(seconds)) {
    'buio' => 1,
    'notte' => 5 + max(0, level) + 3 * max(0, grade),
    _ => 0,
  }).toInt();
}

/// Movement is metres per ten seconds. A total speed percentage is explicit:
/// 100 means walking, 500 means five times the walking speed.
int oculumWorldTravelSeconds(
  double metres,
  Iterable<num> movements, {
  double totalSpeedPercent = 100,
}) {
  final speeds = movements.map((value) => max(0.0, value.toDouble())).toList();
  if (!metres.isFinite ||
      metres <= 0 ||
      speeds.isEmpty ||
      !totalSpeedPercent.isFinite ||
      totalSpeedPercent <= 0) {
    throw ArgumentError(
      'Distanza, Movimento e velocità devono essere positivi.',
    );
  }
  final average =
      speeds.fold<double>(0, (sum, speed) => sum + speed) / speeds.length;
  if (average <= 0) {
    throw ArgumentError('Il party non ha Movimento disponibile.');
  }
  return (metres / (average * totalSpeedPercent / 100) * 10).ceil();
}

class OculumWorldClockProgress {
  OculumWorldClockProgress({
    this.seconds = 0,
    this.revision = 0,
    this.travelRemainder = 0,
    this.travelChecks = 0,
    Set<String>? receipts,
    List<Map<String, dynamic>>? events,
    List<Map<String, dynamic>>? checks,
    List<Map<String, dynamic>>? rests,
    Map<String, dynamic>? travelSettings,
    Map<String, dynamic>? merchantVisits,
  }) : receipts = {...?receipts},
       events = [...?events],
       checks = [...?checks],
       rests = [...?rests],
       travelSettings = {...?travelSettings},
       merchantVisits = {...?merchantVisits};

  factory OculumWorldClockProgress.fromJson(Map raw) {
    List<Map<String, dynamic>> rows(String key) => [
      for (final value in raw[key] is List ? raw[key] as List : const [])
        if (value is Map) Map<String, dynamic>.from(value),
    ];
    return OculumWorldClockProgress(
      seconds: max(0, readIntValue(raw['seconds'])),
      revision: max(0, readIntValue(raw['revision'])),
      travelRemainder: readIntValue(
        raw['travelRemainder'],
      ).clamp(0, oculumTravelEventSeconds - 1).toInt(),
      travelChecks: max(0, readIntValue(raw['travelChecks'])),
      receipts: (raw['receipts'] is List ? raw['receipts'] as List : const [])
          .map((value) => '$value')
          .where((id) => id.isNotEmpty)
          .toSet(),
      events: rows('events'),
      checks: rows('checks'),
      rests: rows('rests'),
      travelSettings: raw['travelSettings'] is Map
          ? Map<String, dynamic>.from(raw['travelSettings'] as Map)
          : null,
      merchantVisits: raw['merchantVisits'] is Map
          ? Map<String, dynamic>.from(raw['merchantVisits'] as Map)
          : null,
    );
  }

  int seconds, revision, travelRemainder, travelChecks;
  final Set<String> receipts;
  final List<Map<String, dynamic>> events, checks, rests;
  final Map<String, dynamic> travelSettings;
  final Map<String, dynamic> merchantVisits;

  bool advance(int delta, String receipt) {
    if (delta <= 0 || receipt.isEmpty || !receipts.add(receipt)) return false;
    seconds += delta;
    revision++;
    return true;
  }

  bool travel({
    required int duration,
    required String receipt,
    required bool chaos,
    required String realm,
    required List<Map<String, dynamic>> party,
    Random? random,
  }) {
    if (duration <= 0 || receipt.isEmpty || receipts.contains(receipt)) {
      return false;
    }
    final total = travelRemainder + duration;
    final firstCheckpoint = oculumTravelEventSeconds - travelRemainder;
    final startSeconds = seconds;
    final count = total ~/ oculumTravelEventSeconds;
    if (count > 10000) {
      throw ArgumentError('Dividi questo viaggio in tratte più brevi.');
    }
    if (!advance(duration, receipt)) return false;
    final rng = random ?? Random.secure();
    travelRemainder = total % oculumTravelEventSeconds;
    for (var index = 0; index < count; index++) {
      final roll = rng.nextInt(100) + 1;
      final success = roll <= (chaos ? 90 : 75);
      final id = 'travel:$receipt:${++travelChecks}';
      checks.add({
        'id': id,
        'roll': roll,
        'chance': chaos ? 90 : 75,
        'event': success,
        'realm': realm,
      });
      if (success) {
        events.add({
          'id': id,
          'realm': realm,
          'status': 'pending',
          'check': travelChecks,
          'party': jsonDecode(jsonEncode(party)),
          'chaos': chaos,
          'worldSeconds':
              startSeconds + firstCheckpoint + index * oculumTravelEventSeconds,
        });
      }
    }
    return true;
  }

  Map<String, dynamic> publicJson() => {
    'seconds': seconds,
    'revision': revision,
    'day': seconds ~/ oculumWorldDaySeconds + 1,
    'phase': oculumWorldPhase(seconds),
  };
  Map<String, dynamic> toJson() => {
    ...publicJson(),
    'travelRemainder': travelRemainder,
    'travelChecks': travelChecks,
    'receipts': receipts.toList(),
    'events': events,
    'checks': checks,
    'rests': rests,
    'travelSettings': travelSettings,
    'merchantVisits': merchantVisits,
  };
}

extension _OculumWorldClock on _OculumHomePageState {
  bool get worldClockAuthority => realtimeService?.isConnected == true
      ? realtimeIsMasterRole
      : haPermessiMaster;

  Map<String, dynamic> get worldClockCampaigns {
    final raw = extraTopLevelSaveFields['worldClockCampaigns'];
    if (raw is Map<String, dynamic>) return raw;
    final map = Map<String, dynamic>.from(raw is Map ? raw : const {});
    extraTopLevelSaveFields['worldClockCampaigns'] = map;
    return map;
  }

  OculumWorldClockProgress get worldClockProgress =>
      OculumWorldClockProgress.fromJson(
        worldClockCampaigns[activeCampaignId] is Map
            ? worldClockCampaigns[activeCampaignId] as Map
            : const {},
      );

  Map<String, dynamic> worldClockCampaignJson() => worldClockProgress.toJson();
  void loadWorldClockCampaign(Map<String, dynamic> campaign) {
    final id = '${campaign['id'] ?? activeCampaignId}';
    worldClockCampaigns[id] = OculumWorldClockProgress.fromJson(
      campaign['worldClock'] is Map ? campaign['worldClock'] as Map : const {},
    ).toJson();
  }

  Map<String, dynamic> worldClockPublicSnapshot() =>
      worldClockProgress.publicJson();

  int get worldClockSeconds {
    if (realtimeService?.isConnected == true && !realtimeIsMasterRole) {
      final raw = realtimeVisibleInitiativeSnapshot['worldClock'];
      if (raw is Map) return max(0, readIntValue(raw['seconds']));
    }
    return worldClockProgress.seconds;
  }

  void storeWorldClock(OculumWorldClockProgress clock, {bool publish = true}) {
    worldClockCampaigns[activeCampaignId] = clock.toJson();
    invalidateDerivedDataCaches();
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
    if (mounted) setState(() {});
    if (publish && worldClockAuthority) unawaited(publishWorldClock());
  }

  void advanceWorldClockTurn(String encounterId, String receipt) {
    if (!worldClockAuthority || encounterId.isEmpty || receipt.isEmpty) return;
    final clock = worldClockProgress;
    if (clock.advance(10, 'turn:$encounterId:$receipt')) storeWorldClock(clock);
  }

  bool worldClockSheetIsMonster(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return false;
    final sheet = schedePersonaggio[index];
    final type = oculumNormalizeText(
      '${sheet['tipoScheda'] ?? sheet['type'] ?? ''}',
    );
    return '${sheet['monsterBookSourceId'] ?? ''}'.isNotEmpty ||
        type.contains('mostro') ||
        type.contains('monster') ||
        sheet['isSummon'] == true && sheet['summonType'] == 'monster';
  }

  int worldMonsterCoreBonusAt(int index) =>
      index < 0 || index >= schedePersonaggio.length
      ? 0
      : oculumWorldMonsterCoreBonus(
          worldClockSeconds,
          sheetIntValueAt(index, 'livello'),
          sheetIntValueAt(index, 'grado'),
          isMonster: worldClockSheetIsMonster(index),
        );

  void notifyWorldRestState({required bool longRest}) {
    final payload = permissionEnvelope({
      'id':
          'world-rest:${sheetTagAt(schedaCorrente)}:$longRest:${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(1 << 30)}',
      'worldClockCommand': 'rest_request',
      'longRest': longRest,
    });
    if (worldClockAuthority) {
      receiveWorldClockControl(payload);
    } else if (realtimeService?.isConnected == true) {
      unawaited(
        realtimeService?.sendCombatEvent('initiative_control', payload),
      );
    }
  }

  Future<void> publishWorldClock() async {
    if (!worldClockAuthority) return;
    await realtimeService?.sendCombatEvent(
      'initiative_control',
      permissionEnvelope({
        'id': 'world-clock:$activeCampaignId:${worldClockProgress.revision}',
        'worldClockSnapshot': worldClockPublicSnapshot(),
      }),
    );
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void receiveWorldClockControl(Map<String, dynamic> payload) {
    if (payload['scope'] != permissionScope ||
        payload['campaignId'] != permissionCampaignId) {
      return;
    }
    if (payload['worldClockSnapshot'] is Map) {
      if (worldClockAuthority ||
          payload['senderRole'] != 'master' ||
          !validPermissionSender(payload, staff: true)) {
        return;
      }
      final raw = payload['worldClockSnapshot'] as Map;
      final old = realtimeVisibleInitiativeSnapshot['worldClock'];
      if (old is Map &&
          readIntValue(raw['revision']) <= readIntValue(old['revision'])) {
        return;
      }
      realtimeVisibleInitiativeSnapshot['worldClock'] = {
        'seconds': max(0, readIntValue(raw['seconds'])),
        'revision': max(0, readIntValue(raw['revision'])),
        'phase': oculumWorldPhase(readIntValue(raw['seconds'])),
      };
      invalidateDerivedDataCaches();
      if (mounted) setState(() {});
      return;
    }
    if (payload['worldMerchantRestGrant'] is Map) {
      receiveWorldMerchantRestGrant(payload);
      return;
    }
    if (!worldClockAuthority ||
        realtimeService?.isConnected == true &&
            !validPermissionSender(payload)) {
      return;
    }
    if (payload['worldClockCommand'] == 'travel_request') {
      receiveWorldTravelRequest(payload);
      return;
    }
    if (payload['worldClockCommand'] == 'merchant_visit') {
      receiveWorldMerchantVisit(payload);
      return;
    }
    if (payload['worldClockCommand'] != 'rest_request') return;
    final id = '${payload['id'] ?? ''}';
    if (id.isEmpty || id.length > 240) return;
    final clock = worldClockProgress;
    if (clock.receipts.contains(id)) return;
    clock.receipts.add(id);
    final longRest = payload['longRest'] == true;
    final restTag =
        payload['senderRole'] == 'master' &&
            '${payload['restTargetTag'] ?? ''}'.isNotEmpty
        ? '${payload['restTargetTag']}'
        : '${payload['senderTag'] ?? ''}';
    final pending = clock.rests
        .where(
          (rest) => rest['status'] == 'pending' && rest['longRest'] == longRest,
        )
        .firstOrNull;
    if (pending == null) {
      clock.rests.add({
        'id': id,
        'longRest': longRest,
        'status': 'pending',
        'requestedBy': [restTag],
      });
    } else {
      pending['requestedBy'] = {
        ...(pending['requestedBy'] as List? ?? const []).map(
          (value) => '$value',
        ),
        restTag,
      }.toList();
    }
    storeWorldClock(clock, publish: false);
  }

  bool confirmWorldPartyRest(String id, int minutes) {
    if (!worldClockAuthority) return false;
    final clock = worldClockProgress;
    final rest = clock.rests
        .where((rest) => rest['id'] == id && rest['status'] == 'pending')
        .firstOrNull;
    if (rest == null || minutes < (rest['longRest'] == true ? 90 : 30)) {
      return false;
    }
    if (!clock.advance(minutes * 60, 'party-rest:$id')) return false;
    rest['status'] = 'confirmed';
    rest['minutes'] = minutes;
    storeWorldClock(clock);
    return true;
  }

  List<Map<String, dynamic>> worldTravelParty(List<int> indexes) => [
    for (final index in indexes)
      if (index >= 0 && index < schedePersonaggio.length)
        {
          'tag': sheetTagAt(index),
          'name': nomeSchedaPersonaggio(index),
          'movement': sheetMovementAt(index),
          'power': oculumEncounterPermanentTotalPower(schedePersonaggio[index]),
          'level': sheetIntValueAt(index, 'livello'),
          'grade': sheetIntValueAt(index, 'grado'),
        },
  ];

  bool commitWorldTravel({
    required String receipt,
    required double metres,
    required List<int> members,
    required bool chaos,
    String mode = 'walk',
    double totalSpeedPercent = 100,
    Random? random,
  }) {
    if (!worldClockAuthority || !const {'walk', 'vehicle'}.contains(mode)) {
      return false;
    }
    salvaSchedaCorrenteInMemoria();
    final party = worldTravelParty(members);
    if (party.isEmpty) return false;
    int duration;
    try {
      duration = oculumWorldTravelSeconds(
        metres,
        party.map((member) => readIntValue(member['movement'])),
        totalSpeedPercent: mode == 'walk' ? 100 : totalSpeedPercent,
      );
    } on ArgumentError {
      return false;
    }
    final clock = worldClockProgress;
    bool changed;
    try {
      changed = clock.travel(
        duration: duration,
        receipt: receipt,
        chaos: chaos,
        realm: selectedPlaneId,
        party: party,
        random: random,
      );
    } on ArgumentError {
      return false;
    }
    if (!changed) return false;
    clock.travelSettings.addAll({
      'mode': mode,
      'totalSpeedPercent': totalSpeedPercent,
    });
    storeWorldClock(clock);
    aggiungiLog(
      '[VIAGGIO] ${oculumWorldDuration(duration)} trascorse per il party.',
    );
    return true;
  }

  Widget worldClockBar() {
    final seconds = worldClockSeconds,
        dayTime = seconds % oculumWorldDaySeconds;
    final text =
        '${dayTime ~/ 3600}:${(dayTime % 3600 ~/ 60).toString().padLeft(2, '0')}';
    final phase = oculumWorldPhase(seconds);
    return Tooltip(
      message:
          'Giorno ${seconds ~/ oculumWorldDaySeconds + 1} · '
          '${oculumWorldPhaseName(phase)} · $text\nIl tempo è gestito dal Master della campagna.',
      child: TextButton.icon(
        key: const ValueKey('campaign_world_clock'),
        onPressed: worldClockAuthority || realtimeIsCoMasterRole
            ? showWorldClockPanel
            : null,
        icon: const Icon(Icons.schedule, size: 16),
        label: Text(text),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(58, 34),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }

  Future<void> showWorldClockPanel() async {
    final campaign = activeCampaignId;
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, refresh) {
          final clock = worldClockProgress;
          return AlertDialog(
            title: const Text('Tempo della campagna'),
            content: SizedBox(
              width: 600,
              height: min(500, MediaQuery.sizeOf(dialog).height * .65),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giorno ${worldClockSeconds ~/ oculumWorldDaySeconds + 1} · '
                      '${oculumWorldPhaseName(oculumWorldPhase(worldClockSeconds))} · '
                      '${oculumWorldDuration(worldClockSeconds % oculumWorldDaySeconds)}',
                    ),
                    const Text(
                      'Un turno avanzato vale 10 secondi. Le Reazioni non avanzano il tempo. '
                      'Il giorno di Oculum dura 9 ore. I riposi del party si confermano una volta sola.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(dialog);
                        await showWorldTravelDialog();
                      },
                      icon: const Icon(Icons.route),
                      label: const Text('Prepara viaggio'),
                    ),
                    if (worldClockAuthority) ...[
                      for (final rest in clock.rests.where(
                        (rest) => rest['status'] == 'pending',
                      ))
                        ListTile(
                          title: Text(
                            'Riposo ${rest['longRest'] == true ? 'Lungo' : 'Breve'} del party',
                          ),
                          subtitle: Text(
                            '${(rest['requestedBy'] as List? ?? []).length} schede: '
                            'almeno ${rest['longRest'] == true ? 90 : 30} minuti una volta per il party.',
                          ),
                          trailing: TextButton(
                            onPressed: () async {
                              await confirmWorldRestDialog('${rest['id']}');
                              if (mounted && activeCampaignId == campaign) {
                                refresh(() {});
                              }
                            },
                            child: const Text('Conferma tempo'),
                          ),
                        ),
                      const Divider(),
                      Text(
                        'Eventi viaggio · privati del Master (${clock.events.where((event) => event['status'] != 'resolved').length})',
                      ),
                      for (final event in clock.events.where(
                        (event) => event['status'] != 'resolved',
                      ))
                        ListTile(
                          title: Text(
                            'Evento ${event['check']} · ${event['realm']}',
                          ),
                          subtitle: const Text(
                            'Il viaggio continua. Scegli quando introdurre l’evento.',
                          ),
                          onTap: () async {
                            await showWorldTravelEventDialog('${event['id']}');
                            if (mounted && activeCampaignId == campaign) {
                              refresh(() {});
                            }
                          },
                        ),
                    ],
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

  Future<void> confirmWorldRestDialog(String id) async {
    if (!worldClockAuthority) return;
    final campaign = activeCampaignId;
    final rest = worldClockProgress.rests
        .where((row) => row['id'] == id)
        .firstOrNull;
    if (rest == null) return;
    final minimum = rest['longRest'] == true ? 90 : 30;
    final input = TextEditingController(text: '$minimum');
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Tempo del riposo del party'),
        content: TextField(
          controller: input,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Minuti trascorsi (minimo $minimum)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Conferma party'),
          ),
        ],
      ),
    );
    final minutes = int.tryParse(input.text);
    input.dispose();
    if (accepted == true &&
        minutes != null &&
        mounted &&
        activeCampaignId == campaign) {
      confirmWorldPartyRest(id, minutes);
    }
  }
}
