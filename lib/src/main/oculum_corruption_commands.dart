part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumCorruptionCommands on _OculumHomePageState {
  Map<String, dynamic>? get executingCorruptionCommand => onlineCombatRequests
      .values
      .where(
        (r) =>
            r['kind'] == 'corruption_command' &&
            r['status'] == 'executing' &&
            r['targetTag'] == sheetTagAt(schedaCorrente) &&
            r['scope'] == permissionScope &&
            r['encounterId'] == onlineCombatEncounterId,
      )
      .firstOrNull;

  List<Map<String, dynamic>> corruptionCommandOptions() => [
    {'key': 'attack', 'name': 'Attacco', 'type': 'attack'},
    for (final (i, s) in skills.indexed)
      for (final (f, form) in s.forme.indexed)
        if (s.equipaggiata && combatNaturalFormAvailable(form))
          {
            'key': 'skill:$i:$f',
            'name': '${s.nome} · ${form.nome}',
            'type': 'skill',
            'skillName': s.nome,
          },
    for (final (a, art) in arti.indexed)
      if (art.inUso && art.sbloccata)
        for (final (s, skill) in art.skills.indexed)
          for (var f = 1; f <= min(3, artMaxLevel(art)); f++)
            if (combatArtFormAvailable(art, skill, f))
              {
                'key': 'art:$a:$s:$f',
                'name': '${art.nome} / ${skill.nome} · $f',
                'type': 'art',
                'skillName': skill.nome,
              },
  ];

  bool corruptionCanSpendToken(Map<String, dynamic> token, String resource) {
    if (!masterInitiativeTokenCanAct(token) ||
        masterInitiativeTokenIsTemporary(token)) {
      return false;
    }
    if (resource == 'azione') {
      final tokens = onlineCombatTokens();
      final active = referenceUsesLocalTurnState
          ? masterInitiativeActiveIndex
          : readIntValue(
              realtimeVisibleInitiativeSnapshot['activeIndex'],
              fallback: -1,
            );
      return active >= 0 &&
          active < tokens.length &&
          onlineCombatTokenTag(tokens[active]) == onlineCombatTokenTag(token) &&
          !masterInitiativeActionUsed(token) &&
          artDebtForToken(token, 'action') == 0 &&
          token['meccanioReactionsOnly'] != true;
    }
    return resource == 'reazione' &&
        masterInitiativeReactionAvailable(token, round: _onlineCombatRound()) >
            0 &&
        artDebtForToken(token, 'reaction') == 0;
  }

  Future<void> emitCorruptionCommand(Map<String, dynamic> packet) async {
    final payload = permissionEnvelope({
      ...packet,
      'corruptionCommandEvent': true,
      'scope': permissionScope,
      'encounterId': onlineCombatEncounterId,
    });
    receiveCorruptionCommand(payload);
    await realtimeService?.sendCombatEvent('combat_scout', payload);
  }

  Future<void> offerCorruptionCommand(
    Map<String, dynamic> target,
    String resource,
  ) async {
    if (corruptionOwnerForToken(target) != sheetTagAt(schedaCorrente)) return;
    final source = sheetTagAt(schedaCorrente);
    await emitCorruptionCommand({
      'id': 'corrupt-command:$source:${DateTime.now().microsecondsSinceEpoch}',
      'stage': 'offer',
      'sourceTag': source,
      'targetTag': onlineCombatTokenTag(target),
      'sourceName': realtimeDisplayName(),
      'targetName': oculumReferenceEncounterTokenName(target),
      'resource': resource,
      'fightInstanceId': target['fightInstanceId'] ?? '',
    });
  }

  void receiveCorruptionCommand(Map<String, dynamic> payload) {
    final id = '${payload['commandId'] ?? payload['id'] ?? ''}';
    if (id.isEmpty ||
        id.length > 160 ||
        payload['scope'] != permissionScope ||
        payload['encounterId'] != onlineCombatEncounterId) {
      return;
    }
    final online = realtimeService?.isConnected == true;
    if (online && !validPermissionSender(payload)) return;
    final stage = '${payload['stage']}';
    final source = '${payload['sourceTag']}',
        target = '${payload['targetTag']}';
    final sourceToken = onlineCombatTokens()
        .where((t) => onlineCombatTokenTag(t) == source)
        .firstOrNull;
    final targetToken = onlineCombatTokens()
        .where((t) => onlineCombatTokenTag(t) == target)
        .firstOrNull;
    if (sourceToken == null || targetToken == null || source == target) return;
    if ('${payload['fightInstanceId'] ?? ''}'.isNotEmpty &&
        '${targetToken['fightInstanceId'] ?? ''}' != payload['fightInstanceId']) {
      return;
    }
    final sender = '${payload['senderTag']}';
    final staff = payload['senderRole'] == 'master';
    if (stage == 'offer') {
      if (!escapeAuthority ||
          online && sender != source && !staff ||
          onlineCombatRequests.containsKey(id) ||
          corruptionOwnerForToken(targetToken) != source) {
        return;
      }
      final resource = '${payload['resource']}';
      if (!corruptionCanSpendToken(targetToken, resource)) return;
      final ownResource = corruptionCanSpendToken(sourceToken, 'azione')
          ? 'azione'
          : 'reazione';
      if (!corruptionCanSpendToken(sourceToken, ownResource)) return;
      final sourceLevel = readIntValue(sourceToken['level']);
      final targetLevel = readIntValue(targetToken['level']);
      final kind = oculumCorruptionKind(
        corruptionMetadataForToken(targetToken),
      );
      final chance = oculumCorruptionCommandChance(
        kind,
        sourceLevel,
        targetLevel,
      );
      final free =
          Random.secure().nextInt(100) <
          oculumCorruptionFreeCommandChance(sourceLevel, targetLevel);
      final success = Random.secure().nextInt(100) < chance;
      final record = <String, dynamic>{
        ...payload,
        'kind': 'corruption_command',
        'status': 'authorizing',
      };
      onlineCombatRequests[id] = record;
      // Both predicates were checked before either synchronous spend. Only the
      // Master consumes these resources; later execution carries one credit.
      if (!free &&
          !_consumeLocalCombatTurnResource(
            source,
            ownResource,
            advanceMasterTurn: false,
          )) {
        onlineCombatRequests.remove(id);
        return;
      }
      if (success &&
          !_consumeLocalCombatTurnResource(
            target,
            resource,
            advanceMasterTurn: false,
          )) {
        record['status'] = 'rejected';
        return;
      }
      unawaited(
        emitCorruptionCommand({
          ...payload,
          'id': '$id:authorization',
          'commandId': id,
          'stage': 'authorized',
          'success': success,
          'chance': chance,
          'controllerFree': free,
          'controllerResource': ownResource,
        }),
      );
      if (!free && ownResource == 'azione') {
        advanceMasterInitiativeAfterAction(source);
      }
      if (success && resource == 'azione') {
        advanceMasterInitiativeAfterAction(target);
      }
      captureActiveMasterInitiativeGroup();
      sendRealtimeInitiativeSnapshotIfPublished();
    } else if (stage == 'authorized') {
      if (online && !staff) return;
      final old = onlineCombatRequests[id];
      if (old?['authorizationReceived'] == true) return;
      final success = payload['success'] == true;
      final record = <String, dynamic>{
        ...payload,
        'id': id,
        'kind': 'corruption_command',
        'status': success ? 'awaiting_options' : 'counter_available',
        'authorizationReceived': true,
        'masterAuthorized': true,
        'controlSuccess': success,
        if (!success) ...{
          'freeReaction': true,
          'reactionUsed': false,
          'corruptionMentalCounter': true,
        },
      };
      onlineCombatRequests[id] = record;
      combatLogFor(
        target,
        '[CORRUZIONE] Comando ${success ? 'riuscito' : 'fallito'} (${payload['chance']}%). ${success ? 'La risorsa è già pagata: il corruttore sceglie l’attacco o la Skill.' : 'Hai una Reazione gratuita di risposta mentale.'}',
      );
      if (success &&
          target == sheetTagAt(schedaCorrente) &&
          controlsOnlineCombatSheet(target)) {
        unawaited(publishCorruptionCommandOptions(record));
      }
    } else if (stage == 'options') {
      if (online && sender != target && !staff) return;
      final record = onlineCombatRequests[id];
      if (record == null || record['status'] != 'awaiting_options') return;
      final options = payload['options'];
      if (options is! List || options.length > 500) return;
      record['options'] = options;
      record['targets'] = payload['targets'];
      record['status'] = 'awaiting_choice';
    } else if (stage == 'choice') {
      if (online && sender != source && !staff) return;
      final record = onlineCombatRequests[id];
      if (record == null ||
          record['status'] != 'awaiting_choice' ||
          corruptionOwnerForToken(targetToken) != source) {
        return;
      }
      final choice = '${payload['optionKey']}';
      final option = (record['options'] as List? ?? [])
          .whereType<Map>()
          .where((o) => o['key'] == choice)
          .firstOrNull;
      final chosenTarget = '${payload['attackTarget']}';
      if (option == null ||
          !(record['targets'] as List? ?? []).whereType<Map>().any(
            (t) => t['tag'] == chosenTarget,
          )) {
        return;
      }
      record['option'] = Map<String, dynamic>.from(option);
      record['attackTarget'] = chosenTarget;
      record['status'] = 'ready';
    }
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
    if (mounted) setState(() {});
  }

  Future<void> publishCorruptionCommandOptions(
    Map<String, dynamic> record,
  ) async {
    if (record['targetTag'] != sheetTagAt(schedaCorrente) ||
        record['status'] != 'awaiting_options') {
      return;
    }
    await emitCorruptionCommand({
      ...record,
      'commandId': record['id'],
      'id': '${record['id']}:options',
      'stage': 'options',
      'options': corruptionCommandOptions(),
      'targets': [
        for (final t in onlineAttackTokens())
          {
            'tag': onlineCombatTokenTag(t),
            'name': oculumReferenceEncounterTokenName(t),
          },
      ],
    });
  }

  Future<void> chooseCorruptionCommand(Map<String, dynamic> record) async {
    final options = (record['options'] as List? ?? [])
        .whereType<Map>()
        .toList();
    final targets = (record['targets'] as List? ?? [])
        .whereType<Map>()
        .toList();
    if (options.isEmpty || targets.isEmpty) return;
    String? choice, target;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (_, update) => AlertDialog(
          title: Text('Comanda ${record['targetName']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Attacco o Skill reale',
                ),
                items: [
                  for (final o in options)
                    DropdownMenuItem(
                      value: '${o['key']}',
                      child: Text(
                        '${o['name']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => update(() => choice = v),
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Bersaglio'),
                items: [
                  for (final t in targets)
                    DropdownMenuItem(
                      value: '${t['tag']}',
                      child: Text('${t['name']}'),
                    ),
                ],
                onChanged: (v) => update(() => target = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: choice == null || target == null
                  ? null
                  : () => Navigator.pop(dialog, true),
              child: const Text('Conferma comando'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted || record['status'] != 'awaiting_choice') {
      return;
    }
    await emitCorruptionCommand({
      ...record,
      'id': '${record['id']}:choice',
      'commandId': record['id'],
      'stage': 'choice',
      'optionKey': choice,
      'attackTarget': target,
    });
  }

  Future<void> executeCorruptionCommand(Map<String, dynamic> record) async {
    if (record['targetTag'] != sheetTagAt(schedaCorrente) ||
        record['status'] != 'ready' ||
        record['masterAuthorized'] != true ||
        corruptionOwnerForToken(escapeToken('${record['targetTag']}') ?? {}) !=
            record['sourceTag']) {
      return;
    }
    final key = '${(record['option'] as Map?)?['key']}';
    final current = corruptionCommandOptions()
        .where(
          (o) =>
              o['key'] == key &&
              o['name'] == (record['option'] as Map?)?['name'],
        )
        .firstOrNull;
    if (current == null) {
      aggiungiLog(
        '[CORRUZIONE] Skill non più disponibile: il Master può risolvere il comando.',
      );
      return;
    }
    record['status'] = 'executing';
    record['executionResourceClaimed'] = false;
    final own = currentSheetScrollId();
    try {
      final parts = key.split(':');
      if (key == 'attack') {
        await planOnlineAttack();
      } else if (parts.first == 'skill') {
        await usaFormaSkill(
          skills[int.parse(parts[1])],
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        if (mounted &&
            own == currentSheetScrollId() &&
            record['executionResourceClaimed'] == true &&
            activeStructuredEffects.any((e) => e['type'] == 'pending_target')) {
          await planOnlineAttack();
        }
      } else if (parts.first == 'art') {
        await impostaLivelloSkillArt(
          artIndex: int.parse(parts[1]),
          skillIndex: int.parse(parts[2]),
          nuovoLivello: int.parse(parts[3]),
          riutilizza: true,
        );
        if (mounted &&
            own == currentSheetScrollId() &&
            record['executionResourceClaimed'] == true &&
            activeStructuredEffects.any((e) => e['type'] == 'pending_target')) {
          await planOnlineAttack();
        }
      }
    } finally {
      record['status'] = record['executionResourceClaimed'] == true
          ? 'resolved'
          : 'ready';
      programmaSalvataggio();
    }
  }

  Widget corruptionCommandsPanel() {
    final own = sheetTagAt(schedaCorrente);
    final controlled = onlineCombatTokens()
        .where(
          (t) =>
              corruptionOwnerForToken(t) == own &&
              onlineCombatTokenTag(t) != own,
        )
        .toList();
    final pending = onlineCombatRequests.values
        .where(
          (r) =>
              r['kind'] == 'corruption_command' &&
              (r['sourceTag'] == own || r['targetTag'] == own) &&
              r['scope'] == permissionScope &&
              r['encounterId'] == onlineCombatEncounterId &&
              !const ['resolved', 'rejected'].contains(r['status']),
        )
        .toList();
    if (controlled.isEmpty && pending.isEmpty) return const SizedBox.shrink();
    return gothicPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Comandi della Corruzione',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final t in controlled)
            Wrap(
              spacing: 6,
              children: [
                Text(oculumReferenceEncounterTokenName(t)),
                for (final resource in const ['azione', 'reazione'])
                  OutlinedButton(
                    onPressed: !corruptionCanSpendToken(t, resource)
                        ? null
                        : () => offerCorruptionCommand(t, resource),
                    child: Text('Comanda $resource'),
                  ),
              ],
            ),
          for (final r in pending)
            ListTile(
              dense: true,
              title: Text('${r['sourceName']} → ${r['targetName']}'),
              subtitle: Text('${r['status']} · risorsa ${r['resource']}'),
              trailing: Wrap(
                spacing: 4,
                children: [
                  if (r['status'] == 'awaiting_options' &&
                      r['targetTag'] == own)
                    TextButton(
                      onPressed: () => publishCorruptionCommandOptions(r),
                      child: const Text('Invia Skill disponibili'),
                    ),
                  if (r['status'] == 'awaiting_choice' && r['sourceTag'] == own)
                    TextButton(
                      onPressed: () => chooseCorruptionCommand(r),
                      child: const Text('Scegli comando'),
                    ),
                  if (r['status'] == 'ready' && r['targetTag'] == own)
                    TextButton(
                      onPressed: () => executeCorruptionCommand(r),
                      child: const Text('Esegui comando'),
                    ),
                  if (r['status'] == 'counter_available' &&
                      r['targetTag'] == own &&
                      r['reactionUsed'] != true)
                    TextButton(
                      onPressed: () => planOnlineAttack(
                        freeReactionId: '${r['id']}',
                        initialChoice: bestCorruptionMentalStat(),
                      ),
                      child: const Text('Impulso mentale · Reazione gratuita'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String bestCorruptionMentalStat() {
    final stats =
        hiddenEyeStats
            .where(
              (s) =>
                  s.unlocked &&
                  const ['fermezza', 'crepa', 'concentrazione'].contains(s.id),
            )
            .toList()
          ..sort((a, b) => hiddenEyeTotal(b).compareTo(hiddenEyeTotal(a)));
    return stats.firstOrNull?.id ?? 'vc';
  }

  int corruptionMentalCounterDamage() {
    final stat = hiddenEyeStats
        .where((s) => s.id == bestCorruptionMentalStat())
        .firstOrNull;
    return dannoTotale() ~/ 2 +
        volontaTotale() +
        (stat == null ? 0 : hiddenEyeTotal(stat));
  }
}
