part of '../../main.dart';

String _aculotideDeathBurstId(String fight, String source, String target) {
  final bytes = Uint8List.fromList(
    utf8.encode(jsonEncode([fight, source, target])),
  );
  final hash = SHA256Digest().process(bytes);
  return 'aculotide-scoppio:${base64Url.encode(hash)}';
}

extension _OculumAculotideRuntime on _OculumHomePageState {
  String _aculotideFightKey(String tag) => jsonEncode([
    permissionScope,
    permissionCampaignId,
    onlineCombatEncounterId,
    _summonFightKey(tag),
  ]);

  Map<String, dynamic>? _aculotideCombatToken(String tag) =>
      onlineCombatTokens()
          .where((token) => combatTokenMatchesSheet(token, tag))
          .firstOrNull;

  void prepareAculotideDodge(int bonus, int rise) {
    final tag = sheetTagAt(schedaCorrente);
    planarState['aculotideDodge'] = {
      'fight': _aculotideFightKey(tag),
      'bonus': bonus,
      'rise': rise.clamp(0, oculumAculotideMaximumRise.toInt()),
    };
  }

  Map? _preparedAculotideDodge() {
    final prepared = planarState['aculotideDodge'];
    if (prepared is! Map || faunaCurrentMonsterId != oculumAculotideId) {
      return null;
    }
    final tag = sheetTagAt(schedaCorrente);
    return prepared['fight'] == _aculotideFightKey(tag) ? prepared : null;
  }

  int aculotideDodgeBonus(String choice) => choice == 'cm'
      ? max(0, readIntValue(_preparedAculotideDodge()?['bonus']))
      : 0;

  void bindAculotideDodgeToDefense(
    Map<String, dynamic> request,
    String choice,
    double rise,
  ) {
    request.remove('aculotideDodgeRise');
    if (choice != 'cm' || aculotideDodgeBonus(choice) <= 0) return;
    request['aculotideDodgeRise'] = rise;
    planarState.remove('aculotideDodge');
  }

  Future<double?> chooseAculotideDodgeRise() async {
    final maximum = readDoubleValue(
      _preparedAculotideDodge()?['rise'],
    ).clamp(0.0, oculumAculotideMaximumRise).toDouble();
    if (maximum == 0) return 0;
    var rise = maximum;
    return showDialog<double>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Guizzo · quota dopo una difesa riuscita'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sali di ${rise.toStringAsFixed(1)} m'),
              Slider(
                min: 0,
                max: maximum,
                divisions: (maximum * 10).round(),
                value: rise,
                onChanged: (value) => update(() => rise = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, rise),
              child: const Text('Tira CM'),
            ),
          ],
        ),
      ),
    );
  }

  void resolveAculotideDodge(
    Map<String, dynamic> request, {
    required String choice,
    required int attack,
    required int defense,
    required OculumAttackOutcome outcome,
    required double rise,
  }) {
    if (rise <= 0 ||
        choice != 'cm' ||
        defense < attack ||
        outcome != OculumAttackOutcome.avoided ||
        !realtimeIsMasterRole && realtimeService?.isConnected == true ||
        request['scope'] != permissionScope ||
        request['encounterId'] != onlineCombatEncounterId ||
        vttShowingRemoteScene) {
      return;
    }
    final tag = '${request['targetTag'] ?? ''}';
    final participant = onlineCombatTokens()
        .where((token) => combatTokenMatchesSheet(token, tag))
        .firstOrNull;
    if (participant == null ||
        monsterBookIdForCombatToken(participant) != oculumAculotideId) {
      return;
    }
    final token = localMapTokenForInitiativeToken(participant);
    if (token == null) return;
    final receipt = '${_aculotideFightKey(tag)}:${request['id']}';
    final receipts = (token['aculotideGuizzoReceipts'] as List? ?? const [])
        .whereType<String>()
        .toList();
    final current = readDoubleValue(token['elevationMeters']);
    final elevation = oculumAculotideRaisedElevation(current, rise);
    if (elevation == null || receipts.contains(receipt)) return;
    final previous = token['aculotideGuizzoElevation'];
    final fight = _aculotideFightKey(tag);
    final base =
        previous is Map &&
            previous['fight'] == fight &&
            previous['raised'] == current
        ? readDoubleValue(previous['original'])
        : current;
    token['elevationMeters'] = elevation;
    token['aculotideGuizzoElevation'] = {
      'fight': fight,
      'turnStarted': _turnSpendRetryTurn()?.key,
      'original': base,
      'raised': elevation,
    };
    token['aculotideGuizzoReceipts'] = [
      ...receipts.skip(max(0, receipts.length - 63)),
      receipt,
    ];
    notifyVttCanvasChanged(save: true, publish: true);
    combatLogFor(tag, '[GUIZZO] Quota ${elevation.toStringAsFixed(1)} m.');
  }

  void expireAculotideDodgeElevation(Map<String, dynamic> participant) {
    if (vttShowingRemoteScene) return;
    final token = localMapTokenForInitiativeToken(participant);
    if (token == null) return;
    final elevation = token['aculotideGuizzoElevation'];
    if (elevation is! Map ||
        elevation['turnStarted'] == _turnSpendRetryTurn()?.key) {
      return;
    }
    final current = readDoubleValue(token['elevationMeters']);
    final restored = oculumAculotideRestoredElevation(
      current: current,
      original: readDoubleValue(elevation['original']),
      raised: readDoubleValue(elevation['raised']),
    );
    token.remove('aculotideGuizzoElevation');
    if (current != restored) token['elevationMeters'] = restored;
    notifyVttCanvasChanged(save: true, publish: true);
  }

  void recordAculotideMeleeHit(Map request, {required bool hit}) {
    if (!hit ||
        faunaCurrentMonsterId != oculumAculotideId ||
        request['faunaBurst'] == true ||
        request['scope'] != permissionScope ||
        request['encounterId'] != onlineCombatEncounterId ||
        !oculumGuardianMeleeAttack(request)) {
      return;
    }
    final target = sheetTagAt(schedaCorrente);
    final source = '${request['sourceTag'] ?? ''}';
    final turn = _turnSpendRetryTurn();
    if (turn == null ||
        !oculumSameSheetIdentity(request['targetTag'], target) ||
        source.isEmpty) {
      return;
    }
    final attacker = _aculotideCombatToken(source);
    final defender = _aculotideCombatToken(target);
    if (attacker == null ||
        defender == null ||
        !oculumShieldBreakCanTarget(defender, attacker)) {
      return;
    }
    final fight = _aculotideFightKey(target);
    final previous = planarState['aculotideMeleeHits'];
    final sources =
        previous is Map &&
            previous['fight'] == fight &&
            previous['turn'] == turn.key
        ? (previous['sources'] as List? ?? const []).whereType<String>()
        : const <String>[];
    planarState['aculotideMeleeHits'] = {
      'fight': fight,
      'turn': turn.key,
      'sources': {...sources, onlineCombatTokenTag(attacker)}.toList(),
    };
  }

  void resolveAculotideDeath(int index, Map<String, dynamic> token) {
    final online = realtimeService?.isConnected == true;
    if (!mounted ||
        !currentCombatIsActive() ||
        online && !realtimeIsMasterRole ||
        !masterInitiativeTokenIsDead(token) ||
        monsterBookIdForCombatToken(token) != oculumAculotideId) {
      return;
    }
    final scope = permissionScope;
    final encounter = onlineCombatEncounterId;
    final tag = onlineCombatTokenTag(token);
    final turn = _turnSpendRetryTurn()?.key;
    final localTag = sheetTagAt(index);
    final fight = _aculotideFightKey(tag);
    final ledger = index == schedaCorrente
        ? planarState
        : schedePersonaggio[index]['planarRuntime'] as Map?;
    if (tag.isEmpty ||
        encounter.isEmpty ||
        turn == null ||
        ledger == null ||
        ledger['aculotideDeathFight'] == fight) {
      return;
    }
    final hits = ledger['aculotideMeleeHits'];
    final sources =
        hits is Map && hits['fight'] == fight && hits['turn'] == turn
        ? (hits['sources'] as List? ?? const []).whereType<String>().toSet()
        : const <String>{};
    final damage = escapeDamageStat(localTag).clamp(0, 100000000).toInt();
    scheduleMicrotask(() async {
      if (!mounted ||
          permissionScope != scope ||
          onlineCombatEncounterId != encounter ||
          _aculotideFightKey(tag) != fight ||
          online && !realtimeIsMasterRole) {
        return;
      }
      final source = _aculotideCombatToken(tag);
      final currentIndex = localSheetIndexForOculumTag(localTag);
      if (source == null ||
          !masterInitiativeTokenIsDead(source) ||
          currentIndex < 0) {
        return;
      }
      final committed = currentIndex == schedaCorrente
          ? planarState
          : schedePersonaggio[currentIndex]['planarRuntime'] as Map?;
      if (committed == null || committed['aculotideDeathFight'] == fight) {
        return;
      }
      committed['aculotideDeathFight'] = fight;
      final requests = [
        for (final target in onlineCombatTokens())
          if (damage > 0 &&
              sources.contains(onlineCombatTokenTag(target)) &&
              oculumShieldBreakCanTarget(source, target))
            <String, dynamic>{
              'id': _aculotideDeathBurstId(
                fight,
                tag,
                onlineCombatTokenTag(target),
              ),
              'scope': scope,
              'encounterId': encounter,
              'aculotideDeathBurst': true,
              'aculotideDeathFight': fight,
              'sourceTag': tag,
              'targetTag': onlineCombatTokenTag(target),
              'sourceName': 'Aculotide',
              'targetName': target['name'],
              'abilityName': 'Scoppio di Aculotide',
              'kind': 'fauna_burst',
              'choice': 'fauna_burst',
              'faunaBurst': true,
              'attack': 1,
              'damage': damage,
              'element': 'acqua',
              'natural': 10,
              'effects': <Map<String, dynamic>>[],
              'status': 'pending',
              if (online) 'aculotideDeathOutbound': true,
            },
      ];
      for (final request in requests) {
        onlineCombatRequests.putIfAbsent('${request['id']}', () => request);
      }
      programmaSalvataggio();
      for (final request in requests) {
        if (online) await sendAculotideDeathBurst(request);
        if (mounted &&
            request['status'] == 'pending' &&
            request['scope'] == permissionScope &&
            request['encounterId'] == onlineCombatEncounterId) {
          await resolveAutomaticFaunaDamage(request);
        }
      }
    });
  }

  bool validAculotideDeathBurst(Map<String, dynamic> packet) {
    final sourceTag = '${packet['sourceTag'] ?? ''}';
    final targetTag = '${packet['targetTag'] ?? ''}';
    final fight = _aculotideFightKey(sourceTag);
    final source = _aculotideCombatToken(sourceTag);
    final target = _aculotideCombatToken(targetTag);
    return packet['scope'] == permissionScope &&
        packet['encounterId'] == onlineCombatEncounterId &&
        packet['senderRole'] == 'master' &&
        packet['id'] == _aculotideDeathBurstId(fight, sourceTag, targetTag) &&
        packet['aculotideDeathFight'] == fight &&
        packet['kind'] == 'fauna_burst' &&
        packet['faunaBurst'] == true &&
        packet['choice'] == 'fauna_burst' &&
        packet['element'] == 'acqua' &&
        packet['attack'] == 1 &&
        packet['natural'] == 10 &&
        packet['forcedCritical'] != true &&
        packet['turnResourceSpends'] == null &&
        packet['effects'] is List &&
        (packet['effects'] as List).isEmpty &&
        readIntValue(packet['damage']) > 0 &&
        source != null &&
        target != null &&
        masterInitiativeTokenIsDead(source) &&
        monsterBookIdForCombatToken(source) == oculumAculotideId &&
        oculumShieldBreakCanTarget(source, target);
  }

  Future<void> sendAculotideDeathBurst(Map<String, dynamic> request) async {
    final service = realtimeService;
    final sourceTag = '${request['sourceTag']}';
    if (!mounted ||
        service?.isConnected != true ||
        !realtimeIsMasterRole ||
        request['aculotideDeathOutbound'] != true ||
        request['attackAcknowledged'] == true ||
        request['status'] != 'pending' ||
        request['scope'] != permissionScope ||
        request['encounterId'] != onlineCombatEncounterId ||
        request['aculotideDeathFight'] != _aculotideFightKey(sourceTag)) {
      return;
    }
    await service!.sendCombatEvent(
      'combat_attack',
      permissionEnvelope({...request}..remove('aculotideDeathOutbound')),
    );
  }
}
