part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

bool oculumEscapeWins(
  int escape,
  int blocker,
  int movement,
  int blockerMovement,
) => escape > blocker || escape == blocker && movement >= blockerMovement;
int oculumEscapeExperience(
  int enemyHpLost,
  int members,
  int damage,
  int ownHpLost,
) => max(
  max(0, ownHpLost),
  max(0, enemyHpLost) ~/ max(1, members) - max(0, damage),
);
bool oculumEscapePrecisionStops(int attack, int fleeTotal) =>
    attack * 5 >= max(0, fleeTotal) * 4;

extension _OculumEscape on _OculumHomePageState {
  void moveEncounterMemberToRole(String encounterId, Map token) {
    if (!escapeAuthority || !haPermessiMaster) return;
    final group = masterInitiativeGroups
        .where((g) => g['id'] == encounterId)
        .firstOrNull;
    if (group == null) return;
    final tag = onlineCombatTokenTag(Map<String, dynamic>.from(token));
    final tokens = encounterId == selectedMasterInitiativeGroupId
        ? masterInitiativeTokens
        : (group['tokens'] as List? ?? []).whereType<Map>().toList();
    final member = tokens
        .where((t) => onlineCombatTokenTag(Map<String, dynamic>.from(t)) == tag)
        .firstOrNull;
    if (member == null) return;
    setState(() {
      member['outsideFight'] = true;
      member['status'] = 'fled';
      member['outsideFirstPending'] = true;
      member['outsideCritical'] = false;
      if (encounterId == selectedMasterInitiativeGroupId) {
        captureActiveMasterInitiativeGroup();
      }
    });
    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  Widget encounterRoleFolder(
    Map group,
    String encounterId, {
    required bool local,
  }) {
    final members = (group['tokens'] as List? ?? [])
        .whereType<Map>()
        .where((t) => t['outsideFight'] == true || group['combatEnded'] == true)
        .toList();
    if (members.isEmpty && !haPermessiMaster) return const SizedBox.shrink();
    return ExpansionTile(
      key: ValueKey('role_folder_$encounterId'),
      leading: const Icon(Icons.folder_open),
      title: Text('${group['roleName'] ?? 'Role'} · ${members.length}'),
      children: [
        if (local && haPermessiMaster)
          TextFormField(
            initialValue: '${group['roleName'] ?? 'Role'}',
            decoration: const InputDecoration(
              labelText: 'Nome della cartella Role',
            ),
            onChanged: (value) {
              group['roleName'] = value.trim().isEmpty ? 'Role' : value.trim();
              programmaSalvataggio(invalidateCaches: false);
              sendRealtimeInitiativeSnapshotIfPublished();
            },
          ),
        for (final member in members)
          ListTile(
            dense: true,
            title: Text(
              oculumReferenceEncounterTokenName(
                Map<String, dynamic>.from(member),
              ),
            ),
            subtitle: Text(
              group['combatEnded'] == true
                  ? 'Combattimento finito'
                  : 'Fuori fight',
            ),
          ),
      ],
    );
  }

  bool get escapeAuthority =>
      realtimeService?.isConnected != true || realtimeIsMasterRole;
  Map<String, dynamic> get escapeLedger {
    final group = masterInitiativeGroups
        .where((g) => g['id'] == onlineCombatEncounterId)
        .firstOrNull;
    final owner = group ?? planarState;
    if (owner['escapeLedger'] is! Map<String, dynamic>) {
      owner['escapeLedger'] = Map<String, dynamic>.from(
        owner['escapeLedger'] as Map? ?? {},
      );
    }
    return owner['escapeLedger'] as Map<String, dynamic>;
  }

  Map<String, dynamic>? escapeToken(String tag) => _writableOnlineCombatTokens()
      .where((t) => onlineCombatTokenTag(t) == tag)
      .firstOrNull;
  bool get outsideFight =>
      escapeToken(sheetTagAt(schedaCorrente))?['outsideFight'] == true;
  bool escapeTokenIsOut(String tag) =>
      escapeToken(tag)?['outsideFight'] == true;

  int escapeDamageStat(String tag) {
    final index = localSheetIndexForOculumTag(tag);
    return index == schedaCorrente
        ? dannoTotale()
        : index < 0
        ? 0
        : readIntValue(schedePersonaggio[index]['derivedDanno']);
  }

  bool escapeMayHelp(String helper, String beneficiary) {
    final packets = onlineCombatRequests.values.where(
      (r) =>
          r['status'] == 'pending' &&
          r['escapeReturn'] is Map &&
          (r['sourceTag'] == beneficiary || r['targetTag'] == beneficiary),
    );
    for (final packet in packets) {
      final source = '${packet['sourceTag']}';
      if (fatePartyPerceives(helper, source)) continue;
      final total = readIntValue((packet['escapeReturn'] as Map)['total']);
      final veil = readIntValue(
        (packet['escapeReturn'] as Map)['veil'],
        fallback: total,
      );
      if (escapeSubtraitAt(localSheetIndexForOculumTag(helper), 'percezione') <
          veil) {
        return false;
      }
    }
    return true;
  }

  void applyEscapeReturnBonus(Map<String, dynamic> request) {
    if (request['escapeReturn'] is! Map ||
        request['escapeReturnResolved'] == true) {
      return;
    }
    final stealth = request['escapeReturn'] as Map;
    final perceived =
        escapeSubtraitAt(schedaCorrente, 'percezione') >
        readIntValue(stealth['veil']);
    request['escapeReturnResolved'] = true;
    request['escapeReturnBonus'] = perceived ? 0 : 3;
    request['escapeBaseAttack'] = readIntValue(request['attack']);
    if (!perceived) {
      request['attack'] = readIntValue(request['attack']) + 3;
      request['damage'] =
          readIntValue(request['damage']) +
          max(0, readIntValue(stealth['veil']));
      aggiungiLog(
        '[RIENTRO FURTIVO] Non percepito: +3 al tiro e +${stealth['veil']} Danni contro di te.',
      );
    }
  }

  void acceptEscapeReturnReply(
    Map<String, dynamic> request,
    Map<String, dynamic> payload,
  ) {
    if (request['escapeReturn'] is! Map ||
        request['escapeReturnReplyAccepted'] == true) {
      return;
    }
    final bonus = readIntValue(payload['escapeReturnBonus']).clamp(0, 3);
    final base = readIntValue(
      request['escapeBaseAttack'],
      fallback: readIntValue(request['attack']),
    );
    request['attack'] = base + bonus;
    request['escapeReturnReplyAccepted'] = true;
  }

  int escapeSubtraitAt(int index, String id) {
    if (index < 0 || index >= schedePersonaggio.length) return 0;
    if (index == schedaCorrente) {
      final stat = hiddenEyeStats
          .where((s) => s.id == id && s.unlocked)
          .firstOrNull;
      return stat == null ? 0 : hiddenEyeTotal(stat);
    }
    final sheet = schedePersonaggio[index];
    final derived = 'derived${id[0].toUpperCase()}${id.substring(1)}';
    if (sheet[derived] is num) return readIntValue(sheet[derived]);
    final allocated = (sheet['hiddenEyeStats'] as List? ?? [])
        .whereType<Map>()
        .where((s) => s['id'] == id)
        .firstOrNull;
    return readIntValue(allocated?['valore']) +
        oculumHiddenEyeDerivedBonusFor(
          level: sheetIntValueAt(index, 'livello'),
          id: id,
          resilienza: sheetIntValueAt(index, 'resilienza'),
          volonta: sheetIntValueAt(index, 'volonta'),
          materia: sheetIntValueAt(index, 'materia'),
          oculum: sheetIntValueAt(index, 'oculum'),
          karma: sheetIntValueAt(index, 'karma'),
        );
  }

  bool fatePartyPerceives(String observer, String target) {
    final a = localSheetIndexForOculumTag(observer),
        b = localSheetIndexForOculumTag(target);
    if (a < 0 ||
        b < 0 ||
        combatScoutSide(observer) == 'enemy' ||
        combatScoutSide(target) == 'enemy') {
      return false;
    }
    bool fate(int i) =>
        (schedePersonaggio[i]['planarRuntime'] as Map? ??
            {})['identityFateChaos'] !=
        'Chaos';
    return fate(a) && fate(b);
  }

  void recordEscapeAttack(Map<String, dynamic> request) {
    if (!currentCombatIsActive() ||
        request['kind'] == 'escape' ||
        '${request['sourceTag'] ?? ''}'.isEmpty) {
      return;
    }
    final seen = (escapeLedger['attackIds'] as List? ?? [])
        .map((v) => '$v')
        .toSet();
    if (!seen.add('${request['id']}')) return;
    escapeLedger['attackIds'] = seen.toList();
    final sequence = readIntValue(escapeLedger['sequence']) + 1;
    escapeLedger['sequence'] = sequence;
    final targets = Map<String, dynamic>.from(
      escapeLedger['lastTargeted'] as Map? ?? {},
    );
    targets['${request['targetTag']}'] = sequence;
    escapeLedger['lastTargeted'] = targets;
    final attacks = Map<String, dynamic>.from(
      escapeLedger['lastAttack'] as Map? ?? {},
    );
    attacks['${request['targetTag']}'] = {
      'source': request['sourceTag'],
      'sequence': sequence,
    };
    escapeLedger['lastAttack'] = attacks;
    final escapeId = '${request['escapeReactionOf'] ?? ''}';
    final attempt = onlineCombatRequests[escapeId];
    if (attempt != null && attempt['kind'] == 'escape') {
      final answers = Map<String, dynamic>.from(
        attempt['answers'] as Map? ?? {},
      );
      answers['${request['sourceTag']}'] = {
        'kind': 'attack',
        'attackId': request['id'],
        'pending': true,
      };
      attempt['answers'] = answers;
    }
    final returned =
        onlineCombatRequests['escape-return:${request['sourceTag']}'];
    if (returned != null) returned['status'] = 'used';
  }

  void recordEscapeHelp(String beneficiary, String helper, int total) {
    if (!currentCombatIsActive()) return;
    final all = Map<String, dynamic>.from(escapeLedger['help'] as Map? ?? {});
    final helpers = Map<String, dynamic>.from(all[beneficiary] as Map? ?? {});
    helpers[helper] = max(readIntValue(helpers[helper]), total);
    all[beneficiary] = helpers;
    escapeLedger['help'] = all;
  }

  void recordEscapeHpLoss(int amount) {
    if (amount <= 0 || !currentCombatIsActive()) return;
    final token = escapeToken(sheetTagAt(schedaCorrente));
    final key = '$onlineCombatEncounterId:${token?['fightInstanceId'] ?? ''}';
    final previous = Map<String, dynamic>.from(
      planarState['escapeHpLoss'] as Map? ?? {},
    );
    planarState['escapeHpLoss'] = {
      'fight': key,
      'amount':
          (previous['fight'] == key ? readIntValue(previous['amount']) : 0) +
          amount,
    };
  }

  void recordEscapeDamage(Map<String, dynamic> request) {
    if (!currentCombatIsActive() || request['damageReceipt'] is! Map) return;
    final entries = Map<String, dynamic>.from(
      escapeLedger['damage'] as Map? ?? {},
    );
    final id = '${request['id']}';
    if (entries.containsKey(id)) return;
    final amount = max(
      0,
      readIntValue((request['damageReceipt'] as Map)['hpLost']),
    );
    entries[id] = {
      'source': request['sourceTag'],
      'target': request['targetTag'],
      'hp': amount,
    };
    escapeLedger['damage'] = entries;
    if (amount > 0) {
      final last = Map<String, dynamic>.from(
        escapeLedger['lastDamage'] as Map? ?? {},
      );
      last['${request['targetTag']}'] = {
        'source': request['sourceTag'],
        'helpers': request['sourceHelpers'] ?? [],
        'defenseHelpers': request['defenseHelpers'] ?? [],
      };
      escapeLedger['lastDamage'] = last;
    }
    final escapeId = '${request['escapeReactionOf'] ?? ''}';
    final record = onlineCombatRequests[escapeId];
    if (record != null && record['kind'] == 'escape') {
      final answers = Map<String, dynamic>.from(
        record['answers'] as Map? ?? {},
      );
      final hit = request['outcome'] != OculumAttackOutcome.avoided.name;
      final critical =
          request['criticalShieldProtected'] != true &&
          (request['forcedCritical'] == true ||
              oculumAttackIsCritical(
                readIntValue(request['attack']),
                readIntValue(request['defense']),
              ));
      final precision =
          '${request['choice']}'.startsWith('precisione') &&
          oculumEscapePrecisionStops(
            readIntValue(request['attack']),
            readIntValue(record['total']),
          );
      answers['${request['sourceTag']}'] = {
        'kind': 'attack',
        'pending': false,
        'attackId': id,
        'stops': hit && (critical || precision),
      };
      record['answers'] = answers;
    }
  }

  bool escapeAttackAllowed(Map<String, dynamic> packet) {
    final id = '${packet['escapeReactionOf'] ?? ''}';
    if (id.isEmpty) return true;
    final record = onlineCombatRequests[id];
    if (record == null ||
        record['kind'] != 'escape' ||
        record['status'] != 'pending' ||
        record['sourceTag'] != packet['targetTag'] ||
        record['lastAggressor'] != packet['sourceTag'] ||
        (record['noticed'] as Map? ?? {})[packet['sourceTag']] != true) {
      return false;
    }
    final answer = (record['answers'] as Map? ?? {})[packet['sourceTag']];
    return answer == null ||
        answer is Map && answer['attackId'] == packet['id'];
  }

  Future<void> emitEscape(Map<String, dynamic> payload) async {
    payload['escapeEvent'] = true;
    payload.putIfAbsent('scope', () => permissionScope);
    payload.putIfAbsent('encounterId', () => onlineCombatEncounterId);
    final envelope = permissionEnvelope(payload);
    receiveEscapeEvent(envelope);
    await realtimeService?.sendCombatEvent('combat_scout', envelope);
  }

  void prepareEscapeNotice(Map<String, dynamic> record) {
    final source = '${record['sourceTag']}';
    final last =
        (escapeLedger['lastDamage'] as Map? ?? {})[source] as Map? ?? {};
    record['lastAggressor'] = last['source'] ?? '';
    record['lastEnemyHelpers'] = last['helpers'] ?? [];
    record['lastFriendlyHelpers'] = last['defenseHelpers'] ?? [];
    final helpers = Map<String, dynamic>.from(
      (escapeLedger['help'] as Map? ?? {})[source] as Map? ?? {},
    );
    final ordered = helpers.entries.toList()
      ..sort((a, b) => readIntValue(b.value).compareTo(readIntValue(a.value)));
    record['freeHelper'] = ordered.isEmpty ? '' : ordered.first.key;
    final noticed = <String, bool>{};
    final lastAttack =
        (escapeLedger['lastAttack'] as Map? ?? {})[source] as Map? ?? {};
    for (final token in onlineCombatTokens()) {
      final tag = onlineCombatTokenTag(token);
      if (tag == source ||
          const {'dead', 'fled', 'expired'}.contains(token['status'])) {
        continue;
      }
      final index = localSheetIndexForOculumTag(tag);
      var perception = escapeSubtraitAt(index, 'percezione');
      if (lastAttack['source'] == tag &&
          readIntValue((escapeLedger['lastTargeted'] as Map? ?? {})[tag]) <=
              readIntValue(lastAttack['sequence'])) {
        perception += 3;
      }
      noticed[tag] =
          fatePartyPerceives(tag, source) ||
          record['stealth'] != true ||
          perception >= readIntValue(record['noticeDt']);
    }
    record['noticed'] = noticed;
    record['noticeRevision'] = 1;
  }

  Future<void> attemptEscape() async {
    if (!currentCombatIsActive() || outsideFight) return;
    final tag = sheetTagAt(schedaCorrente), origin = currentSheetScrollId();
    if (onlineCombatRequests.values.any(
      (r) =>
          r['kind'] == 'escape' &&
          r['status'] == 'pending' &&
          r['sourceTag'] == tag &&
          r['encounterId'] == onlineCombatEncounterId,
    )) {
      return;
    }
    if (!await spendCombatRollResource()) return;
    if (!mounted || currentSheetScrollId() != origin) return;
    final reflex = escapeSubtraitAt(schedaCorrente, 'riflessi'),
        veil = escapeSubtraitAt(schedaCorrente, 'velo');
    final movement = movimento(), stealth = veil > reflex;
    Map<String, dynamic>? record;
    await tiraValoreSpeciale(
      'Fuga · Movimento + ${stealth ? 'Velo' : 'Riflessi'}',
      movement + max(reflex, veil),
      resourceAlreadySpent: true,
      onResolved: (natural, total) {
        record = {
          'id': 'escape:$tag:${DateTime.now().microsecondsSinceEpoch}',
          'kind': 'escape',
          'stage': 'offer',
          'status': 'pending',
          'sourceTag': tag,
          'targetTag': tag,
          'sourceName': realtimeDisplayName(),
          'sourceSide': combatScoutSide(tag),
          'natural': natural,
          'total': total,
          'movement': movement,
          'stealth': stealth,
          'noticeDt': natural + veil,
          'answers': <String, dynamic>{},
        };
      },
    );
    if (record == null || !mounted || currentSheetScrollId() != origin) return;
    attachPendingCombatTurnResources(record!);
    await emitEscape(record!);
    aggiungiLog(
      '[FUGA] Totale ${record!['total']}; gli avversari che ti notano possono tentare di fermarti. Il Master conclude il confronto dopo le risposte.',
    );
  }

  Future<void> answerEscape(Map<String, dynamic> record, String kind) async {
    final tag = sheetTagAt(schedaCorrente), source = '${record['sourceTag']}';
    if (record['status'] != 'pending' ||
        (record['answers'] as Map? ?? {}).containsKey(tag) ||
        (record['noticed'] as Map? ?? {})[tag] != true) {
      return;
    }
    final friendly = combatScoutSide(tag) == record['sourceSide'];
    final free =
        !totalPowerExhausted &&
        (friendly
            ? record['freeHelper'] == tag
            : record['lastAggressor'] == tag);
    if (kind == 'attack') {
      if (!free || friendly) return;
      await planOnlineAttack(
        targetId: source,
        resourceAlreadySpent: true,
        escapeReactionOf: '${record['id']}',
      );
      return;
    }
    if (kind != 'pass' && !free && !await spendCombatRollResource()) return;
    final payload = <String, dynamic>{
      'id': 'escape-answer:${record['id']}:$tag',
      'escapeId': record['id'],
      'stage': 'answer',
      'sourceTag': tag,
      'targetTag': source,
      'answer': kind,
      'friendly': friendly,
      'movement': movimento(),
      'total': 0,
    };
    if (kind == 'block') {
      await tiraValoreSpeciale(
        'Ferma la fuga · Movimento + Riflessi',
        movimento() + escapeSubtraitAt(schedaCorrente, 'riflessi'),
        resourceAlreadySpent: true,
        onResolved: (_, total) => payload['total'] = total,
      );
    } else if (kind == 'help') {
      payload['bonus'] =
          ((record[friendly ? 'lastFriendlyHelpers' : 'lastEnemyHelpers']
                      as List? ??
                  [])
              .contains(tag))
          ? 3
          : 2;
    }
    attachPendingCombatTurnResources(payload);
    await emitEscape(payload);
  }

  Future<void> concludeEscape(Map<String, dynamic> record) async {
    if (!escapeAuthority || record['status'] != 'pending') return;
    final answers = (record['answers'] as Map? ?? {}).values
        .whereType<Map>()
        .toList();
    if (answers.any((a) => a['pending'] == true)) {
      aggiungiLog('[FUGA] Risolvi prima l’attacco di intercettazione.');
      return;
    }
    final friendlyHelp = answers
        .where((a) => a['answer'] == 'help' && a['friendly'] == true)
        .fold<int>(0, (n, a) => n + readIntValue(a['bonus']));
    final enemyHelp = answers
        .where((a) => a['answer'] == 'help' && a['friendly'] != true)
        .fold<int>(0, (n, a) => n + readIntValue(a['bonus']));
    final blocks = answers.where((a) => a['answer'] == 'block').toList()
      ..sort((a, b) {
        final byRoll = readIntValue(
          b['total'],
        ).compareTo(readIntValue(a['total']));
        return byRoll != 0
            ? byRoll
            : readIntValue(
                b['movement'],
              ).compareTo(readIntValue(a['movement']));
      });
    final best = blocks.firstOrNull;
    final success =
        !answers.any((a) => a['stops'] == true) &&
        (best == null ||
            oculumEscapeWins(
              readIntValue(record['total']) + friendlyHelp,
              readIntValue(best['total']) + enemyHelp,
              readIntValue(record['movement']),
              readIntValue(best['movement']),
            ));
    await emitEscape({
      'id': 'escape-result:${record['id']}',
      'escapeId': record['id'],
      'stage': 'result',
      'sourceTag': record['sourceTag'],
      'targetTag': record['sourceTag'],
      'success': success,
      'critical': readIntValue(record['natural']) == 20,
      'total': readIntValue(record['total']) + friendlyHelp,
    });
  }

  void receiveEscapeEvent(Map<String, dynamic> payload) {
    final eventId = '${payload['id'] ?? ''}';
    if (eventId.isEmpty || eventId.length > 160) return;
    if (payload['scope'] != permissionScope ||
        payload['encounterId'] != onlineCombatEncounterId ||
        realtimeService?.isConnected == true &&
            !validPermissionSender(payload)) {
      return;
    }
    final source = '${payload['sourceTag']}', stage = '${payload['stage']}';
    if (!onlineCombatTokens().any((t) => onlineCombatTokenTag(t) == source)) {
      return;
    }
    final staff = const {'master', 'coMaster'}.contains(payload['senderRole']);
    if (realtimeService?.isConnected == true &&
        payload['senderTag'] != source &&
        !staff) {
      return;
    }
    if (stage == 'offer') {
      final id = '${payload['id']}';
      if (onlineCombatRequests[id]?['escapePrepared'] == true) return;
      final record = <String, dynamic>{
        ...payload,
        'kind': 'escape',
        'status': 'pending',
        'answers': <String, dynamic>{},
        'escapePrepared': true,
      };
      onlineCombatRequests[id] = record;
      if (escapeAuthority) {
        prepareEscapeNotice(record);
        unawaited(emitEscape({...record, 'stage': 'notice'}));
      }
    } else if (stage == 'notice') {
      if (!staff && realtimeService?.isConnected == true) return;
      final id = '${payload['id']}';
      if (readIntValue(onlineCombatRequests[id]?['noticeRevision']) >=
          readIntValue(payload['noticeRevision'])) {
        return;
      }
      onlineCombatRequests[id] = <String, dynamic>{
        ...payload,
        'kind': 'escape',
        'status': 'pending',
      };
    } else if (stage == 'answer') {
      final record = onlineCombatRequests['${payload['escapeId']}'];
      if (record == null ||
          record['status'] != 'pending' ||
          (record['noticed'] as Map? ?? {})[source] != true) {
        return;
      }
      final answers = Map<String, dynamic>.from(
        record['answers'] as Map? ?? {},
      );
      final friendly = combatScoutSide(source) == record['sourceSide'];
      payload['friendly'] = friendly;
      if (payload['answer'] == 'help') {
        payload['bonus'] =
            ((record[friendly ? 'lastFriendlyHelpers' : 'lastEnemyHelpers']
                        as List? ??
                    [])
                .contains(source))
            ? 3
            : 2;
      }
      answers.putIfAbsent(source, () => Map<String, dynamic>.from(payload));
      record['answers'] = answers;
    } else if (stage == 'result') {
      if (!staff && realtimeService?.isConnected == true) return;
      final record = onlineCombatRequests['${payload['escapeId']}'];
      if (record == null || record['status'] != 'pending') return;
      record['status'] = payload['success'] == true ? 'escaped' : 'failed';
      if (payload['success'] == true) {
        markOutsideFight(source, critical: payload['critical'] == true);
      }
      aggiungiLog(
        '[FUGA] ${record['sourceName']}: ${payload['success'] == true ? 'fuori fight' : 'fuga fermata'}.',
      );
      if (escapeAuthority && payload['success'] == true) {
        unawaited(finishIfPartyEscaped());
      }
    } else if (stage == 'return') {
      if (!const {'velo', 'riflessi'}.contains(payload['mode'])) return;
      final token = escapeToken(source);
      if (token == null || token['outsideFight'] != true) return;
      token['outsideFight'] = false;
      token['status'] = 'ready';
      token.remove('outsideNormal');
      token.remove('outsideFast');
      onlineCombatRequests['escape-return:$source'] = {
        ...payload,
        'status': 'ready',
      };
      if (payload['mode'] == 'riflessi') {
        token['extraFastReactionCurrent'] =
            readIntValue(token['extraFastReactionCurrent']) + 1;
        token['escapeReturnFastTurns'] = 1;
      }
      aggiungiLog(
        '[RIENTRO] ${token['name']}: ${payload['mode'] == 'riflessi' ? 'visibile; una Reazione veloce ora e al prossimo turno' : 'Velo ${payload['veil']}: +3 al tiro e +${payload['veil']} Danni contro chi non ti percepisce'}.',
      );
    }
    if (mounted) setState(() {});
    programmaSalvataggio();
    if (escapeAuthority) {
      captureActiveMasterInitiativeGroup();
      sendRealtimeInitiativeSnapshotIfPublished();
    }
  }

  void markOutsideFight(String tag, {bool critical = false}) {
    final token = escapeToken(tag);
    if (token == null) return;
    token.addAll({
      'outsideFight': true,
      'status': 'fled',
      'outsideFirstPending': true,
      'outsideCritical': critical,
    });
  }

  void refreshEscapeTurn(Map<String, dynamic> token, {int? percentile}) {
    if (token['outsideFight'] == true) {
      final critical =
          token['outsideFirstPending'] == true &&
          token['outsideCritical'] == true;
      final fast = critical
          ? 3
          : (percentile ?? Random.secure().nextInt(100)) < 50
          ? 1
          : 0;
      token.addAll({
        'outsideNormal': critical ? 0 : 2 - fast,
        'outsideFast': fast,
        'outsideFirstPending': false,
        'actionUsed': false,
        'reactionUsed': 0,
        'reactionFastUsed': 0,
        'reactionPoolInitialized': true,
        'reactionNormalFirstRoundLocked': false,
      });
    } else if (readIntValue(token['escapeReturnFastTurns']) > 0) {
      token['extraFastReactionCurrent'] =
          readIntValue(token['extraFastReactionCurrent']) + 1;
      token['escapeReturnFastTurns'] =
          readIntValue(token['escapeReturnFastTurns']) - 1;
    }
  }

  Future<void> returnToFight(String mode) async {
    if (!outsideFight) return;
    if (!await requestUtilitySpend('azione', preferFreeReaction: false)) return;
    final tag = sheetTagAt(schedaCorrente),
        bonus = escapeSubtraitAt(schedaCorrente, mode);
    int total = 0;
    await tiraValoreSpeciale(
      'Rientro · $mode',
      bonus,
      resourceAlreadySpent: true,
      onResolved: (_, value) => total = value,
    );
    await emitEscape({
      'id': 'return:$tag:${DateTime.now().microsecondsSinceEpoch}',
      'stage': 'return',
      'sourceTag': tag,
      'targetTag': tag,
      'mode': mode,
      'total': total,
      'veil': mode == 'velo' ? bonus : 0,
    });
  }

  Widget escapeUtilityControls() => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      if (!outsideFight)
        OutlinedButton.icon(
          onPressed: currentCombatIsActive()
              ? () => unawaited(attemptEscape())
              : null,
          icon: const Icon(Icons.directions_run),
          label: const Text('Fuga · Movimento + Riflessi/Velo'),
        ),
      if (outsideFight) ...[
        const Text('Fuori fight · cure, riparazioni e utilità su di te'),
        OutlinedButton(
          onPressed: () => unawaited(returnToFight('velo')),
          child: const Text('Rientra con Velo · Azione'),
        ),
        OutlinedButton(
          onPressed: () => unawaited(returnToFight('riflessi')),
          child: const Text('Rientra con Riflessi · Azione'),
        ),
      ],
    ],
  );

  Widget escapeRequestsPanel() {
    final records = onlineCombatRequests.values
        .where(
          (r) =>
              r['kind'] == 'escape' &&
              r['status'] == 'pending' &&
              r['scope'] == permissionScope &&
              r['encounterId'] == onlineCombatEncounterId,
        )
        .toList();
    if (records.isEmpty) return const SizedBox.shrink();
    final tag = sheetTagAt(schedaCorrente);
    return Column(
      children: [
        for (final record in records)
          gothicPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fuga · ${record['sourceName']} · ${record['total']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Parità: vince chi ha più Movimento; a Movimento pari riesce la Fuga.',
                ),
                if ((record['noticed'] as Map? ?? {})[tag] == true &&
                    !(record['answers'] as Map? ?? {}).containsKey(tag))
                  Wrap(
                    spacing: 6,
                    children: [
                      if (combatScoutSide(tag) != record['sourceSide'])
                        TextButton(
                          onPressed: () =>
                              unawaited(answerEscape(record, 'block')),
                          child: Text(
                            record['lastAggressor'] == tag
                                ? 'Blocca · Reazione gratuita'
                                : 'Blocca · Azione/Reazione',
                          ),
                        ),
                      if (record['lastAggressor'] == tag)
                        TextButton(
                          onPressed: () =>
                              unawaited(answerEscape(record, 'attack')),
                          child: const Text('Colpisci · Reazione gratuita'),
                        ),
                      TextButton(
                        onPressed: () =>
                            unawaited(answerEscape(record, 'help')),
                        child: Text(
                          record['freeHelper'] == tag
                              ? 'Aiuta · Reazione gratuita'
                              : 'Aiuta · Azione/Reazione',
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            unawaited(answerEscape(record, 'pass')),
                        child: const Text('Passa'),
                      ),
                    ],
                  ),
                for (final answer in (record['answers'] as Map? ?? {}).entries)
                  Text(
                    '${answer.key}: ${(answer.value as Map)['answer'] ?? (answer.value as Map)['kind']}',
                  ),
                if (escapeAuthority)
                  TextButton(
                    onPressed: () => unawaited(concludeEscape(record)),
                    child: const Text(
                      'Concludi confronto · chi non risponde rinuncia',
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Map<String, int> escapeExperienceByParticipant() {
    final tokens = onlineCombatTokens();
    final party = tokens
        .where(
          (t) =>
              t['side'] == 'party' &&
              t['encounterObject'] != true &&
              !masterInitiativeTokenIsTemporary(t),
        )
        .toList();
    final damage = (escapeLedger['damage'] as Map? ?? {}).values
        .whereType<Map>();
    int hpLost(String tag) {
      final recorded = damage
          .where((d) => d['target'] == tag)
          .fold<int>(0, (n, d) => n + readIntValue(d['hp']));
      final index = localSheetIndexForOculumTag(tag);
      if (index < 0) return recorded;
      final saved =
          (index == schedaCorrente
                  ? planarState
                  : schedePersonaggio[index]['planarRuntime'] as Map? ??
                        {})['escapeHpLoss']
              as Map? ??
          {};
      final key =
          '$onlineCombatEncounterId:${escapeToken(tag)?['fightInstanceId'] ?? ''}';
      return max(
        recorded,
        saved['fight'] == key ? readIntValue(saved['amount']) : 0,
      );
    }

    final enemyHp = tokens
        .where((t) => t['side'] == 'enemy')
        .fold<int>(0, (n, t) => n + hpLost(onlineCombatTokenTag(t)));
    return {
      for (final token in party)
        onlineCombatTokenTag(token): oculumEscapeExperience(
          enemyHp,
          party.length,
          escapeDamageStat(onlineCombatTokenTag(token)),
          hpLost(onlineCombatTokenTag(token)),
        ),
    };
  }

  Future<void> finishIfPartyEscaped() async {
    if (!escapeAuthority || !currentCombatIsActive()) return;
    final party = masterInitiativeTokens
        .where(
          (t) =>
              t['side'] == 'party' &&
              !masterInitiativeTokenIsTemporary(t) &&
              t['encounterObject'] != true,
        )
        .toList();
    if (party.isEmpty ||
        party.any(
          (t) => t['outsideFight'] != true && !masterInitiativeTokenIsDead(t),
        )) {
      return;
    }
    final group = masterInitiativeGroups
        .where((g) => g['id'] == onlineCombatEncounterId)
        .firstOrNull;
    if (group == null || group['escapeFinishing'] == true) return;
    group['escapeFinishing'] = true;
    group['escapeExperience'] = escapeExperienceByParticipant();
    await finishEncounter(onlineCombatEncounterId, automatic: true);
  }
}
