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

/// New interception packets must contain a real d16 natural. Older saved
/// pending attacks omit this metadata and keep their original d20 semantics.
bool oculumEscapeAttackDieIsValid(Map packet) {
  if ('${packet['escapeReactionOf'] ?? ''}'.isEmpty ||
      !packet.containsKey('dieFaces')) {
    return true;
  }
  final faces = int.tryParse('${packet['dieFaces']}');
  final natural = int.tryParse('${packet['natural']}');
  return faces == 16 && natural != null && natural >= 1 && natural <= 16;
}

extension _OculumEscape on _OculumHomePageState {
  bool get escapeUsesMasterTokens =>
      escapeAuthority && _usesLocalMasterInitiative;
  String get escapeEventEncounterId => escapeUsesMasterTokens
      ? selectedMasterInitiativeGroupId
      : onlineCombatEncounterId;
  List<Map<String, dynamic>> escapeCombatTokens() =>
      escapeUsesMasterTokens ? masterInitiativeTokens : onlineCombatTokens();
  String escapeCombatSide(String tag) =>
      '${escapeCombatTokens().where((t) => onlineCombatTokenTag(t) == tag).firstOrNull?['side'] ?? 'ally'}';
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
        .where((g) => g['id'] == escapeEventEncounterId)
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

  bool escapeRequestIsCurrent(Map<String, dynamic> record) {
    final current =
        '${escapeToken('${record['sourceTag']}')?['fightInstanceId'] ?? ''}';
    final recorded = '${record['fightInstanceId'] ?? ''}';
    return current.isEmpty || recorded.isEmpty || current == recorded;
  }

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
      final stat = hiddenEyeStats.where((s) => s.id == id).firstOrNull;
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
        escapeCombatSide(observer) == 'enemy' ||
        escapeCombatSide(target) == 'enemy') {
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
    recordCombatHpLost(amount);
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
    // Missing metadata belongs to an already-saved legacy d20 interception.
    // New attacks carry the actual d16 natural, never a converted/fake d20.
    if (!oculumEscapeAttackDieIsValid(packet)) return false;
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
    payload.putIfAbsent('encounterId', () => escapeEventEncounterId);
    final envelope = permissionEnvelope(payload);
    receiveEscapeEvent(envelope, locallyAuthored: true);
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
    for (final token in escapeCombatTokens()) {
      final tag = onlineCombatTokenTag(token);
      if (tag == source ||
          const {'dead', 'fled', 'expired'}.contains(token['status'])) {
        continue;
      }
      final index = localSheetIndexForOculumTag(tag);
      var perception = index >= 0
          ? escapeSubtraitAt(index, 'percezione')
          : readIntValue(token['perception'] ?? token['percezione']);
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
    alignCombatEncounterForRoll();
    if (!currentCombatIsActive() || outsideFight) return;
    final tag = sheetTagAt(schedaCorrente), origin = currentSheetScrollId();
    if (onlineCombatRequests.values.any(
      (r) =>
          r['kind'] == 'escape' &&
          r['status'] == 'pending' &&
          r['sourceTag'] == tag &&
          escapeRequestIsCurrent(r) &&
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
          'fightInstanceId': escapeToken(tag)?['fightInstanceId'],
          'targetTag': tag,
          'sourceName': realtimeDisplayName(),
          'sourceSide': combatScoutSide(tag),
          'natural': natural,
          'total': total,
          'movement': movement,
          'stealth': stealth,
          'subtraitId': stealth ? 'velo' : 'riflessi',
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

  /// The Master may roll for a real NPC token without loading that NPC over
  /// the currently open character or spending the Master's own resources.
  Future<void> attemptEscapeForToken(String encounterId, String tag) async {
    if (!escapeAuthority || !haPermessiMaster || !_usesLocalMasterInitiative) {
      return;
    }
    final group = masterInitiativeGroups
        .where((g) => '${g['id']}' == encounterId)
        .firstOrNull;
    if (group == null ||
        group['fightStarted'] != true ||
        group['combatEnded'] == true) {
      return;
    }
    final previous = selectedMasterInitiativeGroupId;
    if (previous != encounterId) selectMasterInitiativeGroup(encounterId);
    try {
      final token = masterInitiativeTokens
          .where((t) => combatTokenMatchesSheet(t, tag))
          .firstOrNull;
      if (token == null ||
          token['outsideFight'] == true ||
          const {
            'dead',
            'fled',
            'expired',
            'downed',
          }.contains(token['status']) ||
          masterInitiativeTokenIsTemporary(token) ||
          token['encounterObject'] == true) {
        return;
      }
      final actor = publicInitiativeSourceTag(token);
      if (!escapeMasterControlsNpc(token)) return;
      if (onlineCombatRequests.values.any(
        (r) =>
            r['kind'] == 'escape' &&
            r['status'] == 'pending' &&
            r['sourceTag'] == actor &&
            r['encounterId'] == encounterId &&
            escapeRequestIsCurrent(r),
      )) {
        return;
      }
      final index = localSheetIndexForOculumTag(actor);
      int subtrait(String id, String alias) => index >= 0
          ? escapeSubtraitAt(index, id)
          : readIntValue(token[id] ?? token[alias]);
      final reflex = subtrait('riflessi', 'reflexes');
      final veil = subtrait('velo', 'veil');
      final movement =
          (index >= 0
                  ? sheetMovementAt(index)
                  : max(
                      0,
                      readIntValue(
                        token['movement'] ?? token['movimento'],
                        fallback: 30 + readIntValue(token['materia']) ~/ 6,
                      ),
                    ))
              .toInt();
      final active =
          masterInitiativeTokens.indexOf(token) == masterInitiativeActiveIndex;
      final free = !totalPowerExhaustedForTag(actor)
          ? onlineCombatRequests.entries
                .where(
                  (entry) =>
                      entry.value['targetTag'] == actor &&
                      entry.value['freeReaction'] == true &&
                      entry.value['reactionUsed'] != true,
                )
                .firstOrNull
          : null;
      final resource =
          free?.key ??
          (active &&
                  (!readBoolValue(token['actionUsed']) ||
                      readIntValue(token['kiExtraActions']) > 0) &&
                  artDebtForToken(token, 'action') == 0
              ? 'azione'
              : 'reazione');
      if (!_consumeLocalCombatTurnResource(actor, resource)) {
        aggiungiLog(
          '[FUGA] ${token['name']}: nessuna Azione/Reazione disponibile.',
        );
        return;
      }
      final natural = Random.secure().nextInt(20) + 1;
      final bonus = (movement + max(reflex, veil)).toInt();
      final level = index >= 0
          ? sheetCriticalLevelAt(index)
          : readIntValue(token['level']);
      final grade = index >= 0
          ? sheetIntValueAt(index, 'grado')
          : readIntValue(token['grade']);
      final difficulty = index >= 0
          ? sheetDifficoltaTiroAt(index)
          : readIntValue(token['rollDifficulty']);
      final total = rollTotalWithCritical(
        natural,
        20,
        [bonus],
        level: level,
        grade: grade,
        difficulty: difficulty,
      );
      final stealth = veil > reflex;
      final record = <String, dynamic>{
        'id': 'escape:$actor:${DateTime.now().microsecondsSinceEpoch}',
        'kind': 'escape',
        'stage': 'offer',
        'status': 'pending',
        'sourceTag': actor,
        'targetTag': actor,
        'encounterId': encounterId,
        'fightInstanceId': token['fightInstanceId'],
        'sourceName': oculumReferenceEncounterTokenName(token),
        'sourceSide': token['side'] ?? 'enemy',
        'natural': natural,
        'total': total,
        'movement': movement,
        'stealth': stealth,
        'subtraitId': stealth ? 'velo' : 'riflessi',
        'noticeDt': natural + veil,
        'answers': <String, dynamic>{},
      };
      await emitEscape(record);
      aggiungiLog(
        '[FUGA NPC] ${record['sourceName']}: 1d20 $natural + $bonus = $total; confronto in attesa.',
      );
      mostraDadoCentrale(
        valore: rollFormulaWithCritical(
          roll: natural,
          faces: 20,
          bonuses: [bonus],
          level: level,
          grade: grade,
          difficulty: difficulty,
        ),
        criticoUno: natural == 1,
        criticoVenti: natural == 20,
      );
      captureActiveMasterInitiativeGroup();
      sendRealtimeInitiativeSnapshotIfPublished();
      programmaSalvataggio();
    } finally {
      if (previous != encounterId &&
          mounted &&
          selectedMasterInitiativeGroupId == encounterId) {
        captureActiveMasterInitiativeGroup();
        selectMasterInitiativeGroup(previous);
      }
    }
  }

  bool escapeMasterControlsNpc(Map<String, dynamic> token) {
    if (!escapeAuthority || !haPermessiMaster || !_usesLocalMasterInitiative) {
      return false;
    }
    final index = localSheetIndexForOculumTag(publicInitiativeSourceTag(token));
    if (index < 0) {
      return token['side'] != 'party' || token['npc'] == true;
    }
    final type = tipoSchedaPersonaggio(index).toLowerCase();
    return type.contains('mostro') ||
        type.contains('boss') ||
        schedePersonaggio[index]['npc'] == true;
  }

  List<Map<String, dynamic>> escapeRequestsForToken(
    String encounterId,
    String actorTag,
  ) => onlineCombatRequests.values
      .where(
        (record) =>
            record['kind'] == 'escape' &&
            record['status'] == 'pending' &&
            record['encounterId'] == encounterId &&
            record['sourceTag'] != actorTag &&
            (record['noticed'] as Map? ?? {})[actorTag] == true &&
            !(record['answers'] as Map? ?? {}).containsKey(actorTag),
      )
      .toList();

  bool canAnswerEscapeForToken(
    String encounterId,
    String escapeId,
    String actorTag,
    String kind,
  ) {
    if (!const {'block', 'help', 'attack', 'pass'}.contains(kind)) return false;
    final group = masterInitiativeGroups
        .where((g) => '${g['id']}' == encounterId)
        .firstOrNull;
    if (group == null ||
        group['fightStarted'] != true ||
        group['combatEnded'] == true) {
      return false;
    }
    final tokens = encounterId == selectedMasterInitiativeGroupId
        ? masterInitiativeTokens
        : (group['tokens'] as List? ?? const [])
              .whereType<Map>()
              .map((t) => Map<String, dynamic>.from(t))
              .toList();
    final actor = tokens
        .where((t) => combatTokenMatchesSheet(t, actorTag))
        .firstOrNull;
    final record = onlineCombatRequests[escapeId];
    if (actor == null ||
        !escapeMasterControlsNpc(actor) ||
        !masterInitiativeTokenCanAct(actor) ||
        actor['outsideFight'] == true ||
        masterInitiativeTokenIsTemporary(actor) ||
        actor['encounterObject'] == true ||
        record == null ||
        record['kind'] != 'escape' ||
        record['status'] != 'pending' ||
        record['encounterId'] != encounterId ||
        record['scope'] != permissionScope ||
        record['sourceTag'] == actorTag ||
        (record['noticed'] as Map? ?? {})[actorTag] != true ||
        (record['answers'] as Map? ?? {}).containsKey(actorTag)) {
      return false;
    }
    final source = tokens
        .where((t) => combatTokenMatchesSheet(t, '${record['sourceTag']}'))
        .firstOrNull;
    if (source == null ||
        source['outsideFight'] == true ||
        '${source['fightInstanceId'] ?? ''}'.isNotEmpty &&
            '${record['fightInstanceId'] ?? ''}'.isNotEmpty &&
            source['fightInstanceId'] != record['fightInstanceId']) {
      return false;
    }
    final friendly = actor['side'] == record['sourceSide'];
    if (kind == 'pass') return true;
    if (kind == 'block' && friendly) return false;
    final free =
        !totalPowerTokenExhausted(actor) &&
        (friendly ? record['freeHelper'] : record['lastAggressor']) == actorTag;
    if (kind == 'attack') return !friendly && free;
    if (free) return true;
    final active = tokens.indexOf(actor) == readIntValue(group['activeIndex']);
    if (active &&
        (!readBoolValue(actor['actionUsed']) ||
            readIntValue(actor['kiExtraActions']) > 0) &&
        artDebtForToken(actor, 'action') == 0) {
      return true;
    }
    final round = readIntValue(group['round']);
    return artDebtForToken(actor, 'reaction') == 0 &&
        (masterInitiativeNormalReactionRemaining(actor, round: round) > 0 ||
            masterInitiativeFastReactionUsedThisTurn(actor, turnKey: '$round') <
                masterInitiativeFastReactionMax(actor));
  }

  bool escapeNpcStaffAttack(Map<String, dynamic> packet) {
    if (packet['escapeNpcInterception'] != true ||
        !const {'master', 'coMaster'}.contains(packet['senderRole']) ||
        !oculumEscapeAttackDieIsValid(packet)) {
      return false;
    }
    final record = onlineCombatRequests['${packet['escapeReactionOf'] ?? ''}'];
    if (record == null || !escapeAttackAllowed(packet)) return false;
    final source = onlineCombatTokens()
        .where((t) => combatTokenMatchesSheet(t, '${packet['sourceTag']}'))
        .firstOrNull;
    if (source == null ||
        source['side'] == record['sourceSide'] ||
        source['outsideFight'] == true ||
        !masterInitiativeTokenCanAct(source)) {
      return false;
    }
    final index = localSheetIndexForOculumTag('${packet['sourceTag']}');
    final type = index >= 0
        ? tipoSchedaPersonaggio(index)
        : '${source['type'] ?? ''}';
    return source['side'] != 'party' ||
        source['npc'] == true ||
        type.toLowerCase().contains('mostro') ||
        type.toLowerCase().contains('boss');
  }

  Future<void> answerEscapeForToken(
    String encounterId,
    String escapeId,
    String actorTag,
    String kind,
  ) async {
    if (!canAnswerEscapeForToken(encounterId, escapeId, actorTag, kind)) return;
    final previous = selectedMasterInitiativeGroupId;
    if (previous != encounterId) selectMasterInitiativeGroup(encounterId);
    try {
      // Revalidate after selecting, using the live authoritative counters.
      if (!canAnswerEscapeForToken(encounterId, escapeId, actorTag, kind)) {
        return;
      }
      final actor = masterInitiativeTokens.firstWhere(
        (t) => combatTokenMatchesSheet(t, actorTag),
      );
      final record = onlineCombatRequests[escapeId]!;
      final friendly = actor['side'] == record['sourceSide'];
      final free =
          !totalPowerTokenExhausted(actor) &&
          (friendly ? record['freeHelper'] : record['lastAggressor']) ==
              actorTag;
      if (kind != 'pass' && !free) {
        final active =
            masterInitiativeTokens.indexOf(actor) ==
            masterInitiativeActiveIndex;
        final resource =
            active &&
                (!readBoolValue(actor['actionUsed']) ||
                    readIntValue(actor['kiExtraActions']) > 0) &&
                artDebtForToken(actor, 'action') == 0
            ? 'azione'
            : 'reazione';
        if (!_consumeLocalCombatTurnResource(actorTag, resource)) return;
      }
      final index = localSheetIndexForOculumTag(actorTag);
      final reflex = index >= 0
          ? escapeSubtraitAt(index, 'riflessi')
          : readIntValue(actor['riflessi'] ?? actor['reflexes']);
      final movement =
          (index >= 0
                  ? sheetMovementAt(index)
                  : max(
                      0,
                      readIntValue(
                        actor['movement'] ?? actor['movimento'],
                        fallback: 30 + readIntValue(actor['materia']) ~/ 6,
                      ),
                    ))
              .toInt();
      final level = index >= 0
          ? sheetCriticalLevelAt(index)
          : masterInitiativeTokenLevel(actor);
      final grade = index >= 0
          ? sheetIntValueAt(index, 'grado')
          : masterInitiativeTokenGrade(actor);
      final difficulty = index >= 0
          ? sheetDifficoltaTiroAt(index)
          : readIntValue(actor['rollDifficulty']);
      final source = '${record['sourceTag']}';
      if (kind == 'attack') {
        final natural = Random.secure().nextInt(16) + 1;
        final bonus = index >= 0
            ? sheetRollBonusAt(index, 'vc')
            : readIntValue(actor['vc']);
        final total = rollTotalWithCritical(
          natural,
          16,
          [bonus],
          level: level,
          grade: grade,
          difficulty: difficulty,
        );
        final damage = index >= 0
            ? escapeDamageStat(actorTag)
            : max(0, readIntValue(actor['damage'] ?? actor['danno']));
        final monsterId = monsterBookIdForCombatToken(actor);
        final packet = <String, dynamic>{
          'id': 'escape-npc-attack:$escapeId:$actorTag',
          'scope': permissionScope,
          'encounterId': encounterId,
          'sourceTag': actorTag,
          'sourceName': oculumReferenceEncounterTokenName(actor),
          'targetTag': source,
          'targetName': record['sourceName'],
          'choice': 'vc',
          'attack': total,
          'natural': natural,
          'dieFaces': 16,
          'damage': max(0, damage),
          'damageTotal': max(0, damage),
          'baseAttack': true,
          'element': actor['attackElement'] ?? actor['element'] ?? 'fisico',
          'level': level,
          'grade': grade,
          'difficulty': difficulty,
          'sourceMonsterBookId': monsterId,
          if (monsterBookEntryById(
                monsterId,
              )?.encounterRules['canHitIntangible'] ==
              true)
            'canHitIntangible': true,
          'effects': <Map<String, dynamic>>[],
          'status': 'pending',
          'turnResourceSpends': <Map<String, dynamic>>[],
          'escapeReactionOf': escapeId,
          'escapeNpcInterception': true,
          'abilityName': 'Intercettazione · VC',
          'createdAt': DateTime.now().toIso8601String(),
        };
        if (!escapeAttackAllowed(packet)) return;
        onlineCombatRequests['${packet['id']}'] = packet;
        receiveLocalCombatAttack(packet);
        await sendOnlineCombatRequest(packet);
        mostraDadoCentrale(
          valore: rollFormulaWithCritical(
            roll: natural,
            faces: 16,
            bonuses: [bonus],
            level: level,
            grade: grade,
            difficulty: difficulty,
          ),
          criticoUno: natural == 1,
          criticoVenti: natural == 16,
          facce: 16,
        );
      } else {
        final payload = <String, dynamic>{
          'id': 'escape-answer:$escapeId:$actorTag',
          'escapeId': escapeId,
          'stage': 'answer',
          'encounterId': encounterId,
          'sourceTag': actorTag,
          'targetTag': source,
          'answer': kind,
          'friendly': friendly,
          'movement': movement,
          'total': 0,
        };
        if (kind == 'block') {
          final natural = Random.secure().nextInt(20) + 1;
          payload['natural'] = natural;
          payload['total'] = rollTotalWithCritical(
            natural,
            20,
            [movement + reflex],
            level: level,
            grade: grade,
            difficulty: difficulty,
          );
          mostraDadoCentrale(
            valore: rollFormulaWithCritical(
              roll: natural,
              faces: 20,
              bonuses: [movement + reflex],
              level: level,
              grade: grade,
              difficulty: difficulty,
            ),
            criticoUno: natural == 1,
            criticoVenti: natural == 20,
          );
        }
        await emitEscape(payload);
      }
      captureActiveMasterInitiativeGroup();
      sendRealtimeInitiativeSnapshotIfPublished();
      programmaSalvataggio();
    } finally {
      if (mounted &&
          previous != encounterId &&
          selectedMasterInitiativeGroupId == encounterId) {
        captureActiveMasterInitiativeGroup();
        selectMasterInitiativeGroup(previous);
      }
    }
  }

  Future<void> answerEscape(Map<String, dynamic> record, String kind) async {
    // The reference panel follows the current sheet's fight even when another
    // encounter is selected in the Master board or the shared snapshot. Spend
    // the reply in that same fight, as the attack planner already does.
    alignCombatEncounterForRoll();
    final tag = sheetTagAt(schedaCorrente), source = '${record['sourceTag']}';
    if (record['status'] != 'pending' ||
        !escapeRequestIsCurrent(record) ||
        record['scope'] != permissionScope ||
        record['encounterId'] != onlineCombatEncounterId ||
        (record['answers'] as Map? ?? {}).containsKey(tag) ||
        (record['noticed'] as Map? ?? {})[tag] != true) {
      return;
    }
    final friendly = escapeCombatSide(tag) == record['sourceSide'];
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
    final encounterId = '${record['encounterId'] ?? ''}';
    final previous = selectedMasterInitiativeGroupId;
    if (escapeUsesMasterTokens &&
        encounterId.isNotEmpty &&
        previous != encounterId) {
      if (!masterInitiativeGroups.any((g) => '${g['id']}' == encounterId)) {
        return;
      }
      selectMasterInitiativeGroup(encounterId);
      try {
        await concludeEscape(record);
      } finally {
        if (mounted && selectedMasterInitiativeGroupId == encounterId) {
          captureActiveMasterInitiativeGroup();
          selectMasterInitiativeGroup(previous);
        }
      }
      return;
    }
    if (!escapeRequestIsCurrent(record)) return;
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

  List<Map<String, dynamic>> escapeRescueCandidates(Map<String, dynamic> hero) {
    if (hero['kind'] != 'escape' ||
        hero['status'] != 'escaped' ||
        readIntValue(hero['natural']) != 20 ||
        hero['criticalRescueUsed'] == true ||
        hero['encounterId'] != onlineCombatEncounterId ||
        hero['scope'] != permissionScope ||
        !escapeRequestIsCurrent(hero) ||
        escapeToken('${hero['sourceTag']}')?['outsideFight'] != true) {
      return [];
    }
    return onlineCombatRequests.values.where((r) {
      final tag = '${r['sourceTag']}';
      final token = escapeToken(tag);
      return r['kind'] == 'escape' &&
          r['status'] == 'failed' &&
          r['encounterId'] == hero['encounterId'] &&
          r['scope'] == hero['scope'] &&
          escapeRequestIsCurrent(r) &&
          tag != hero['sourceTag'] &&
          token != null &&
          !const {'dead', 'expired', 'fled'}.contains(token['status']) &&
          token['outsideFight'] != true &&
          combatScoutSide(tag) == combatScoutSide('${hero['sourceTag']}');
    }).toList();
  }

  Future<void> requestCriticalEscapeRescue(
    Map<String, dynamic> hero,
    Map<String, dynamic> companion,
  ) async {
    if (!escapeRescueCandidates(hero).contains(companion)) return;
    await emitEscape({
      'id': 'escape-rescue:${hero['id']}:${companion['id']}',
      'stage': 'rescue_request',
      'sourceTag': hero['sourceTag'],
      'targetTag': companion['sourceTag'],
      'escapeId': hero['id'],
      'companionEscapeId': companion['id'],
    });
  }

  Widget criticalEscapeRescuePanel() {
    final own = sheetTagAt(schedaCorrente);
    final heroes = onlineCombatRequests.values
        .where(
          (r) =>
              (escapeAuthority || r['sourceTag'] == own) &&
              escapeRescueCandidates(r).isNotEmpty,
        )
        .toList();
    return Column(
      children: [
        for (final hero in heroes)
          gothicPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Fuga critica · ${hero['sourceName']} può salvare un compagno',
                ),
                const Text(
                  'Automaticamente, senza altri tiri né Azioni o Reazioni.',
                ),
                for (final companion in escapeRescueCandidates(hero))
                  TextButton.icon(
                    icon: const Icon(Icons.handshake_outlined),
                    label: Text('Porta fuori ${companion['sourceName']}'),
                    onPressed: () =>
                        requestCriticalEscapeRescue(hero, companion),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void receiveEscapeEvent(
    Map<String, dynamic> payload, {
    bool locallyAuthored = false,
  }) {
    if (realtimeService?.isConnected == true &&
        !locallyAuthored &&
        !validPermissionSender(payload)) {
      return;
    }
    final requested = '${payload['encounterId'] ?? ''}';
    final previous = selectedMasterInitiativeGroupId;
    if (escapeUsesMasterTokens &&
        requested.isNotEmpty &&
        requested != previous) {
      final known = masterInitiativeGroups.any(
        (group) => '${group['id']}' == requested,
      );
      if (!known) return;
      selectMasterInitiativeGroup(requested);
      try {
        _receiveEscapeEventForSelectedEncounter(
          payload,
          locallyAuthored: locallyAuthored,
        );
      } finally {
        captureActiveMasterInitiativeGroup();
        selectMasterInitiativeGroup(previous);
      }
      return;
    }
    _receiveEscapeEventForSelectedEncounter(
      payload,
      locallyAuthored: locallyAuthored,
    );
  }

  void _receiveEscapeEventForSelectedEncounter(
    Map<String, dynamic> payload, {
    required bool locallyAuthored,
  }) {
    final eventId = '${payload['id'] ?? ''}';
    if (eventId.isEmpty || eventId.length > 160) return;
    if (payload['scope'] != permissionScope ||
        payload['encounterId'] != escapeEventEncounterId ||
        realtimeService?.isConnected == true &&
            !locallyAuthored &&
            !validPermissionSender(payload)) {
      return;
    }
    final source = '${payload['sourceTag']}', stage = '${payload['stage']}';
    if (!escapeCombatTokens().any((t) => onlineCombatTokenTag(t) == source)) {
      return;
    }
    final staff = const {'master', 'coMaster'}.contains(payload['senderRole']);
    if (realtimeService?.isConnected == true &&
        payload['senderTag'] != source &&
        !staff) {
      return;
    }
    if (stage == 'offer') {
      if (!escapeRequestIsCurrent(payload)) return;
      final id = '${payload['id']}';
      if (onlineCombatRequests[id]?['escapePrepared'] == true) return;
      final record = <String, dynamic>{
        ...?onlineCombatRequests[id],
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
      final friendly = escapeCombatSide(source) == record['sourceSide'];
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
        recordCombatSuccessfulEscapeTrait(record);
        markOutsideFight(source, critical: payload['critical'] == true);
      }
      aggiungiLog(
        '[FUGA] ${record['sourceName']}: ${payload['success'] == true ? 'fuori fight' : 'fuga fermata'}.',
      );
      if (escapeAuthority && payload['success'] == true) {
        scheduleEscapeFightEnd('${payload['encounterId']}');
      }
    } else if (stage == 'rescue_request' || stage == 'rescue_result') {
      final hero = onlineCombatRequests['${payload['escapeId']}'];
      final companion = onlineCombatRequests['${payload['companionEscapeId']}'];
      if (hero == null ||
          companion == null ||
          hero['sourceTag'] != source ||
          companion['sourceTag'] != payload['targetTag'] ||
          !escapeRescueCandidates(hero).contains(companion)) {
        return;
      }
      if (stage == 'rescue_request') {
        if (!escapeAuthority) return;
        unawaited(
          emitEscape({
            ...payload,
            'id': '${payload['id']}:result',
            'stage': 'rescue_result',
          }),
        );
        return;
      }
      if (!staff && realtimeService?.isConnected == true) return;
      hero['criticalRescueUsed'] = true;
      hero['criticalRescueTarget'] = companion['sourceTag'];
      companion['status'] = 'escaped';
      companion['rescuedBy'] = source;
      markOutsideFight('${companion['sourceTag']}', critical: false);
      aggiungiLog(
        '[FUGA CRITICA] ${hero['sourceName']} porta fuori ${companion['sourceName']}: nessun altro tiro o costo.',
      );
      if (escapeAuthority) scheduleEscapeFightEnd('${payload['encounterId']}');
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
    if (token['side'] == 'enemy') recordPlanarMonsterEscape(token);
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
    alignCombatEncounterForRoll();
    if (!outsideFight || !const {'velo', 'riflessi'}.contains(mode)) return;
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
    final payload = <String, dynamic>{
      'id': 'return:$tag:${DateTime.now().microsecondsSinceEpoch}',
      'stage': 'return',
      'sourceTag': tag,
      'targetTag': tag,
      'mode': mode,
      'total': total,
      'veil': mode == 'velo' ? bonus : 0,
    };
    attachPendingCombatTurnResources(payload);
    await emitEscape(payload);
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
              escapeRequestIsCurrent(r) &&
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
                            record['lastAggressor'] == tag &&
                                    !totalPowerExhausted
                                ? 'Blocca · Reazione gratuita'
                                : 'Blocca · Azione/Reazione',
                          ),
                        ),
                      if (combatScoutSide(tag) != record['sourceSide'] &&
                          record['lastAggressor'] == tag)
                        Tooltip(
                          message: totalPowerExhausted
                              ? 'Sfinimento: le Reazioni gratuite sono bloccate.'
                              : 'Un tentativo contro chi sta fuggendo, senza avanzare il turno.',
                          child: TextButton(
                            onPressed: totalPowerExhausted
                                ? null
                                : () =>
                                      unawaited(answerEscape(record, 'attack')),
                            child: const Text(
                              'Colpisci · 1d16 · Reazione gratuita',
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: () =>
                            unawaited(answerEscape(record, 'help')),
                        child: Text(
                          (combatScoutSide(tag) == record['sourceSide']
                                          ? record['freeHelper']
                                          : record['lastAggressor']) ==
                                      tag &&
                                  !totalPowerExhausted
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
    final tokens = escapeCombatTokens();
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

  void scheduleEscapeFightEnd(String encounterId) {
    unawaited(
      Future<void>.microtask(() async {
        if (!mounted || !escapeAuthority) return;
        final previous = selectedMasterInitiativeGroupId;
        final group = masterInitiativeGroups
            .where((g) => '${g['id']}' == encounterId)
            .firstOrNull;
        if (group == null ||
            group['combatEnded'] == true ||
            group['fightStarted'] == false) {
          return;
        }
        if (previous != encounterId) selectMasterInitiativeGroup(encounterId);
        try {
          await finishIfPartyEscaped();
          if (mounted && group['combatEnded'] != true) {
            await finishIfEnemiesEscaped();
          }
        } finally {
          if (mounted &&
              previous != encounterId &&
              selectedMasterInitiativeGroupId == encounterId) {
            captureActiveMasterInitiativeGroup();
            selectMasterInitiativeGroup(previous);
          }
        }
      }),
    );
  }

  Future<void> finishIfEnemiesEscaped() async {
    if (!escapeUsesMasterTokens || !currentCombatIsActive()) return;
    final enemies = masterInitiativeTokens
        .where(
          (token) =>
              token['side'] == 'enemy' &&
              !masterInitiativeTokenIsTemporary(token) &&
              token['encounterObject'] != true,
        )
        .toList();
    if (enemies.isEmpty ||
        enemies.any(
          (t) => !const {'dead', 'fled', 'expired'}.contains('${t['status']}'),
        )) {
      return;
    }
    final group = masterInitiativeGroups
        .where((g) => '${g['id']}' == escapeEventEncounterId)
        .firstOrNull;
    if (group == null || group['enemyEscapeFinishing'] == true) return;
    group['enemyEscapeFinishing'] = true;
    await finishEncounter(escapeEventEncounterId, automatic: true);
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
        .where((g) => g['id'] == escapeEventEncounterId)
        .firstOrNull;
    if (group == null || group['escapeFinishing'] == true) return;
    group['escapeFinishing'] = true;
    group['escapeExperience'] = escapeExperienceByParticipant();
    await finishEncounter(escapeEventEncounterId, automatic: true);
  }
}
