part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

@immutable
class _OculumParticipantMenuAnchor {
  const _OculumParticipantMenuAnchor({
    required this.encounterId,
    required this.tokenId,
    required this.selectedEncounterId,
    required this.ownerTag,
    required this.fightId,
  });
  final String encounterId, tokenId, selectedEncounterId, ownerTag, fightId;
}

extension _OculumMasterParticipantMenu on _OculumHomePageState {
  bool get masterParticipantUsesRemote =>
      realtimeService?.isConnected == true &&
      realtimeIsCoMasterRole &&
      !realtimeIsMasterRole;
  String get masterParticipantSelection => masterParticipantUsesRemote
      ? realtimeSelectedEncounterId
      : selectedMasterInitiativeGroupId;

  Map<String, dynamic>? masterParticipantGroup(String encounterId) =>
      (masterParticipantUsesRemote
              ? realtimeEncounterSnapshots
              : masterInitiativeGroups)
          .where(
            (group) =>
                '${group['id'] ?? group['encounterId'] ?? ''}' == encounterId,
          )
          .firstOrNull;

  List<Map<String, dynamic>> masterParticipantTokens(String encounterId) =>
      !masterParticipantUsesRemote &&
          encounterId == selectedMasterInitiativeGroupId
      ? masterInitiativeTokens
      : (masterParticipantGroup(encounterId)?['tokens'] as List? ?? [])
            .whereType<Map>()
            .map((token) => token.cast<String, dynamic>())
            .toList();

  String masterParticipantFightId(String encounterId) {
    final group = masterParticipantGroup(encounterId);
    final tokens = masterParticipantTokens(encounterId);
    return '${group?['fightInstanceId'] ?? (tokens.isEmpty ? null : tokens.first['fightInstanceId']) ?? group?['completedFightCount'] ?? ''}';
  }

  _OculumParticipantMenuAnchor masterParticipantAnchor(
    String encounterId,
    Map token,
  ) => _OculumParticipantMenuAnchor(
    encounterId: encounterId,
    tokenId: '${token['id'] ?? token['sheetTag'] ?? ''}',
    selectedEncounterId: masterParticipantSelection,
    ownerTag: sheetTagAt(schedaCorrente),
    fightId: masterParticipantFightId(encounterId),
  );

  Map<String, dynamic>? resolveMasterParticipantAnchor(
    _OculumParticipantMenuAnchor anchor,
  ) {
    if (!mounted ||
        !haPermessiMaster ||
        anchor.tokenId.isEmpty ||
        anchor.ownerTag != sheetTagAt(schedaCorrente) ||
        anchor.selectedEncounterId != masterParticipantSelection ||
        anchor.fightId != masterParticipantFightId(anchor.encounterId) ||
        masterParticipantGroup(anchor.encounterId) == null) {
      return null;
    }
    return masterParticipantTokens(anchor.encounterId)
        .where(
          (token) =>
              '${token['id'] ?? token['sheetTag'] ?? ''}' == anchor.tokenId,
        )
        .firstOrNull;
  }

  void saveMasterParticipantChange(String encounterId) {
    if (encounterId == selectedMasterInitiativeGroupId) {
      captureActiveMasterInitiativeGroup();
    }
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  String masterParticipantRestoredSide(Map<String, dynamic> token) {
    final previous = '${token['masterSideBeforeEnemy'] ?? ''}';
    if (const {'party', 'ally', 'neutral'}.contains(previous)) return previous;
    final index = localSheetIndexForOculumTag(publicInitiativeSourceTag(token));
    if (index >= 0) {
      final side = sheetSideAt(index);
      if (const {'party', 'ally', 'neutral'}.contains(side)) return side;
    }
    final type = '${token['type'] ?? ''}'.toLowerCase();
    return type.contains('player') || type == 'pg' ? 'party' : 'neutral';
  }

  bool canEditManualParticipantNumbers(Map<String, dynamic> token) {
    if (localSheetIndexForOculumTag(publicInitiativeSourceTag(token)) >= 0) {
      return false;
    }
    final type = '${token['type'] ?? ''}'.toLowerCase();
    if (type.contains('player') || type == 'pg') return false;
    return token['side'] != 'party' || token['npc'] == true;
  }

  List<PopupMenuEntry<String>> masterParticipantMenuEntries(
    String encounterId,
    Map<String, dynamic> token,
  ) => [
    CheckedPopupMenuItem<String>(
      value: 'toggleEnemy',
      checked: token['side'] == 'enemy',
      child: Text(t('Cattivo · Nemico', 'Hostile · Enemy')),
    ),
    CheckedPopupMenuItem<String>(
      value: 'toggleDead',
      checked: token['status'] == 'dead',
      child: Text(t('Morto', 'Dead')),
    ),
    for (final request in escapeRequestsForToken(
      encounterId,
      publicInitiativeSourceTag(token),
    ))
      for (final kind in ['block', 'help', 'attack', 'pass'])
        if (canAnswerEscapeForToken(
          encounterId,
          '${request['id']}',
          publicInitiativeSourceTag(token),
          kind,
        ))
          PopupMenuItem(
            value: 'escapeReply:${jsonEncode(['${request['id']}', kind])}',
            child: Text(
              '${switch (kind) {
                'block' => 'Blocca fuga',
                'help' => 'Aiuta fuga',
                'attack' => 'Colpisci chi fugge',
                _ => 'Non intervenire',
              }} · ${request['sourceName'] ?? 'Fuga'}',
            ),
          ),
    const PopupMenuDivider(),
    if ((!onlineMasterApprovalRequired || realtimeIsMasterRole) &&
        encounterId == selectedMasterInitiativeGroupId &&
        canPurifyBaghestToken(token))
      const PopupMenuItem(
        value: 'baghestPurify',
        child: Text('Purifica · Pietra anti-corruzione'),
      ),
    PopupMenuItem(
      value: 'role',
      child: Text(t('Sposta in Role', 'Move to Role')),
    ),
    if (realtimeIsMasterRole &&
        escapeMasterControlsNpc(token) &&
        masterInitiativeTokenCanAct(token) &&
        token['outsideFight'] != true &&
        token['status'] != 'dead' &&
        token['status'] != 'fled')
      PopupMenuItem(
        value: 'escape',
        child: Text(t('Tenta fuga', 'Attempt escape')),
      ),
    if (canEditManualParticipantNumbers(token))
      PopupMenuItem(
        value: 'levelGrade',
        child: Text(
          t('Livello, Grado e statistiche', 'Level, Grade and statistics'),
        ),
      ),
    if (encounterId == selectedMasterInitiativeGroupId) ...[
      const PopupMenuDivider(),
      for (final status in [
        'active',
        'ready',
        'acted',
        'skipped',
        'downed',
        'fled',
      ])
        PopupMenuItem(
          value: status,
          child: Text(masterInitiativeStatusLabel(status)),
        ),
      const PopupMenuDivider(),
      for (final side in ['ally', 'enemy', 'neutral'])
        PopupMenuItem(
          value: 'side:$side',
          child: Text(masterInitiativeSideEyeLabel(side)),
        ),
      const PopupMenuDivider(),
      PopupMenuItem(value: 'up', child: Text(t('Sposta su', 'Move up'))),
      PopupMenuItem(value: 'down', child: Text(t('Sposta giù', 'Move down'))),
      PopupMenuItem(value: 'remove', child: Text(t('Rimuovi', 'Remove'))),
    ],
  ];

  Future<void> showMasterParticipantMenu(
    String encounterId,
    Map<String, dynamic> displayed, {
    Offset? position,
  }) async {
    if (!haPermessiMaster) return;
    if (!masterParticipantUsesRemote) captureActiveMasterInitiativeGroup();
    final anchor = masterParticipantAnchor(encounterId, displayed);
    final token = resolveMasterParticipantAnchor(anchor);
    if (token == null) return;
    final overlay = Navigator.of(context).overlay?.context.findRenderObject();
    if (overlay is! RenderBox) return;
    final point = overlay.globalToLocal(
      position ?? overlay.localToGlobal(Offset.zero),
    );
    final result = await showMenu<String>(
      context: context,
      color: const Color(0xFF10121A),
      position: RelativeRect.fromRect(
        Rect.fromLTWH(point.dx, point.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: masterParticipantMenuEntries(encounterId, token),
    );
    if (result == null) return;
    await applyMasterParticipantCommand(anchor, result);
  }

  Future<void> applyMasterParticipantCommand(
    _OculumParticipantMenuAnchor anchor,
    String command,
  ) async {
    final token = resolveMasterParticipantAnchor(anchor);
    if (token == null) return;
    if (command == 'baghestPurify') {
      await showBaghestPurification(publicInitiativeSourceTag(token));
      return;
    }
    if (command.startsWith('escapeReply:')) {
      final decoded = jsonDecode(command.substring('escapeReply:'.length));
      if (decoded is! List || decoded.length != 2) return;
      await answerEscapeForToken(
        anchor.encounterId,
        '${decoded[0]}',
        publicInitiativeSourceTag(token),
        '${decoded[1]}',
      );
      return;
    }
    if (masterParticipantUsesRemote && command != 'levelGrade') {
      await sendMasterParticipantCommand(anchor, command);
      return;
    }
    if (command == 'role') {
      moveEncounterMemberToRole(anchor.encounterId, token);
      return;
    }
    if (command == 'escape') {
      if (!realtimeIsMasterRole) return;
      await attemptEscapeForToken(
        anchor.encounterId,
        publicInitiativeSourceTag(token),
      );
      return;
    }
    if (command == 'levelGrade') {
      await editMasterParticipantLevelGrade(anchor);
      return;
    }
    final current = anchor.encounterId == selectedMasterInitiativeGroupId;
    final index = current ? masterInitiativeTokens.indexOf(token) : -1;
    if (const {'remove', 'up', 'down', 'active'}.contains(command)) {
      if (index < 0) return;
      if (command == 'remove') removeMasterInitiativeTokenAt(index);
      if (command == 'up') moveMasterInitiativeToken(index, -1);
      if (command == 'down') moveMasterInitiativeToken(index, 1);
      if (command == 'active') setMasterInitiativeActiveIndex(index);
      return;
    }
    if (command.startsWith('side:')) {
      final side = command.substring(5);
      if (!const {'ally', 'enemy', 'neutral'}.contains(side)) return;
      setState(() {
        if (side == 'enemy' && token['side'] != 'enemy') {
          token['masterSideBeforeEnemy'] = token['side'] ?? 'neutral';
        }
        token['side'] = side;
      });
    } else if (command == 'toggleEnemy') {
      setState(() {
        if (token['side'] == 'enemy') {
          token['side'] = masterParticipantRestoredSide(token);
          token.remove('masterSideBeforeEnemy');
        } else {
          token['masterSideBeforeEnemy'] = token['side'] ?? 'neutral';
          token['side'] = 'enemy';
        }
      });
    } else if (command == 'toggleDead' ||
        const {
          'ready',
          'acted',
          'skipped',
          'downed',
          'fled',
        }.contains(command)) {
      setState(() {
        final status = command == 'toggleDead'
            ? token['status'] == 'dead'
                  ? 'ready'
                  : 'dead'
            : command;
        token['status'] = status;
        token['automaticDeath'] = false;
        token['downed'] = status == 'downed';
        if (status == 'dead') {
          token['rewardDeathRound'] =
              anchor.encounterId == selectedMasterInitiativeGroupId
              ? masterInitiativeRound
              : readIntValue(
                  masterParticipantGroup(anchor.encounterId)?['round'],
                );
          token['rewardDeathFightInstanceId'] = token['fightInstanceId'];
          aggiungiLog(
            '[MORTE] ${token['name'] ?? '???'} · segnata dal Master.',
          );
        }
        if (status == 'fled') recordPlanarMonsterEscape(token);
      });
    } else {
      return;
    }
    token['updatedAt'] = DateTime.now().toIso8601String();
    saveMasterParticipantChange(anchor.encounterId);
  }

  Future<void> sendMasterParticipantCommand(
    _OculumParticipantMenuAnchor anchor,
    String command, {
    Map<String, dynamic> values = const {},
  }) async {
    final token = resolveMasterParticipantAnchor(anchor);
    if (!masterParticipantUsesRemote || token == null) {
      return;
    }
    final delivered = await realtimeService?.sendCombatEvent(
      'initiative_control',
      permissionEnvelope({
        'id':
            'participant:${DateTime.now().microsecondsSinceEpoch}:${sheetTagAt(schedaCorrente)}',
        'encounterId': anchor.encounterId,
        'participantId': anchor.tokenId,
        'expectedFightId': anchor.fightId,
        'participantCommand': command,
        'participantValues': {
          ...values,
          if (command == 'toggleEnemy') 'expectedSide': token['side'] ?? 'ally',
          if (command == 'toggleDead')
            'expectedStatus': token['status'] ?? 'ready',
        },
      }),
    );
    if (!mounted) return;
    aggiungiLog(
      delivered == true
          ? '[TURNISTICA] Comando partecipante inviato al Master; attendo lo stato condiviso.'
          : '[TURNISTICA] Comando non consegnato: nessun partecipante modificato.',
    );
  }

  Future<void> receiveMasterParticipantControl(
    Map<String, dynamic> payload,
  ) async {
    if (!realtimeIsMasterRole || !validPermissionSender(payload, staff: true)) {
      return;
    }
    final id = '${payload['id'] ?? ''}';
    final command = '${payload['participantCommand'] ?? ''}';
    if (!id.startsWith('participant:') ||
        id.length > 160 ||
        onlineCombatRequests.containsKey(id) ||
        !const {
          'toggleEnemy',
          'toggleDead',
          'role',
          'levelGrade',
        }.contains(command)) {
      return;
    }
    final encounterId = '${payload['encounterId'] ?? ''}';
    final group = masterParticipantGroup(encounterId);
    if (group == null ||
        group['published'] != true ||
        '${payload['expectedFightId'] ?? ''}' !=
            masterParticipantFightId(encounterId)) {
      return;
    }
    final participantId = '${payload['participantId'] ?? ''}';
    final matches = masterParticipantTokens(encounterId)
        .where(
          (token) =>
              '${token['id'] ?? token['sheetTag'] ?? ''}' == participantId ||
              publicInitiativeSourceTag(token) == participantId,
        )
        .toList();
    if (matches.length != 1) return;
    final token = matches.single;
    final values = payload['participantValues'] is Map
        ? Map<String, dynamic>.from(payload['participantValues'] as Map)
        : <String, dynamic>{};
    if (command == 'toggleEnemy' &&
        values['expectedSide'] != (token['side'] ?? 'ally')) {
      return;
    }
    if (command == 'toggleDead' &&
        values['expectedStatus'] != (token['status'] ?? 'ready')) {
      return;
    }
    onlineCombatRequests[id] = {
      'id': id,
      'type': 'participant_control',
      'status': 'resolved',
      'scope': permissionScope,
    };
    while (onlineCombatRequests.length > 200) {
      final oldest = onlineCombatRequests.entries
          .where((entry) => entry.value['status'] != 'pending')
          .firstOrNull;
      if (oldest == null) break;
      onlineCombatRequests.remove(oldest.key);
    }
    if (command == 'levelGrade') {
      if (!canEditManualParticipantNumbers(token) ||
          payload['participantValues'] is! Map) {
        return;
      }
      if (!validMasterParticipantNumericValues(values)) return;
      setState(() => applyMasterParticipantNumericValues(token, values));
      saveMasterParticipantChange(encounterId);
      return;
    }
    await applyMasterParticipantCommand(
      masterParticipantAnchor(encounterId, token),
      command,
    );
  }

  bool validMasterParticipantNumericValues(Map<String, dynamic> values) {
    if (values['level'] is! int ||
        values['grade'] is! int ||
        (values['level'] as int) < 0 ||
        (values['grade'] as int) < 0) {
      return false;
    }
    if (values['totalPower'] != null &&
        (values['totalPower'] is! int || (values['totalPower'] as int) < 0)) {
      return false;
    }
    final stats = values['statsTotal'];
    return stats == null ||
        stats is Map &&
            const [
              'resilienza',
              'volonta',
              'materia',
              'oculum',
            ].every((key) => stats[key] is int && (stats[key] as int) >= 0);
  }

  void applyMasterParticipantNumericValues(
    Map<String, dynamic> token,
    Map<String, dynamic> values,
  ) {
    token['level'] = values['level'];
    token['grade'] = values['grade'];
    token['manualLevelGradeOverride'] = true;
    if (values['statsTotal'] is Map) {
      final stats = Map<String, dynamic>.from(values['statsTotal'] as Map);
      token['statsTotal'] = stats;
      token['rewardPermanentCoreStats'] = Map<String, dynamic>.from(stats);
      token.addAll(stats);
    }
    if (values['totalPower'] is int) token['totalPower'] = values['totalPower'];
    token['updatedAt'] = DateTime.now().toIso8601String();
  }

  Widget masterParticipantContextArea({
    required String encounterId,
    required Map<String, dynamic> token,
    required Widget child,
  }) => !haPermessiMaster
      ? child
      : GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTapDown: (details) => showMasterParticipantMenu(
            encounterId,
            token,
            position: details.globalPosition,
          ),
          onLongPressStart: (details) => showMasterParticipantMenu(
            encounterId,
            token,
            position: details.globalPosition,
          ),
          child: child,
        );

  Widget masterParticipantMenuButton(
    String encounterId,
    Map<String, dynamic> token,
  ) => !haPermessiMaster
      ? const SizedBox.shrink()
      : Builder(
          builder: (buttonContext) => IconButton(
            tooltip: t('Gestisci partecipante', 'Manage participant'),
            icon: Icon(Icons.more_vert, color: tertiaryColor),
            onPressed: () => showMasterParticipantMenu(
              encounterId,
              token,
              position: (buttonContext.findRenderObject()! as RenderBox)
                  .localToGlobal(Offset.zero),
            ),
          ),
        );

  Future<void> editMasterParticipantLevelGrade(
    _OculumParticipantMenuAnchor anchor,
  ) async {
    final token = resolveMasterParticipantAnchor(anchor);
    if (token == null || !canEditManualParticipantNumbers(token)) {
      return;
    }
    final level = TextEditingController(
      text: '${readIntValue(token['level'])}',
    );
    final grade = TextEditingController(
      text: '${readIntValue(token['grade'])}',
    );
    final power = TextEditingController(
      text: token['totalPower'] is num
          ? '${readIntValue(token['totalPower'])}'
          : '',
    );
    final existing = token['statsTotal'] is Map
        ? Map<String, dynamic>.from(token['statsTotal'] as Map)
        : <String, dynamic>{};
    for (final key in ['resilienza', 'volonta', 'materia', 'oculum']) {
      if (token.containsKey(key)) existing[key] = token[key];
    }
    final stats = <String, TextEditingController>{
      for (final key in ['resilienza', 'volonta', 'materia', 'oculum'])
        key: TextEditingController(
          text: existing.containsKey(key)
              ? '${readIntValue(existing[key])}'
              : '',
        ),
    };
    String? error;
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, update) => AlertDialog(
            title: Text(t('Partecipante manuale', 'Manual participant')),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: level,
                      keyboardType: TextInputType.number,
                      decoration: fieldDecoration(t('Livello', 'Level')),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: grade,
                      keyboardType: TextInputType.number,
                      decoration: fieldDecoration('Grado'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t(
                        'Statistiche permanenti (4), facoltative: includi equipaggiamento e Titoli fissi, escludi maschera e buff temporanei. Inseriscile tutte oppure lasciale vuote; nessun valore viene inventato.',
                        'Permanent statistics (4), optional: include fixed equipment and Titles, exclude masks and temporary buffs. Supply all four or leave them blank; no values are generated.',
                      ),
                    ),
                    for (final entry in stats.entries) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: entry.value,
                        keyboardType: TextInputType.number,
                        decoration: fieldDecoration(sheetRollLabel(entry.key)),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextField(
                      controller: power,
                      keyboardType: TextInputType.number,
                      decoration: fieldDecoration(
                        t(
                          'Potenza Totale nota · facoltativa',
                          'Known Total Power · optional',
                        ),
                      ),
                    ),
                    if (error != null)
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(t('Annulla', 'Cancel')),
              ),
              FilledButton(
                onPressed: () {
                  final allValues = [
                    level.text,
                    grade.text,
                    if (power.text.trim().isNotEmpty) power.text,
                    ...stats.values
                        .map((c) => c.text)
                        .where((s) => s.trim().isNotEmpty),
                  ];
                  final statCount = stats.values
                      .where((c) => c.text.trim().isNotEmpty)
                      .length;
                  if (allValues.any(
                        (text) =>
                            int.tryParse(text.trim()) == null ||
                            int.parse(text.trim()) < 0,
                      ) ||
                      statCount != 0 && statCount != 4) {
                    update(
                      () => error = t(
                        'Usa numeri interi non negativi. Le statistiche devono essere tutte presenti oppure tutte vuote.',
                        'Use non-negative whole numbers. Supply either all four statistics or none.',
                      ),
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: Text(t('Salva', 'Save')),
              ),
            ],
          ),
        ),
      );
      if (accepted != true) return;
      final latest = resolveMasterParticipantAnchor(anchor);
      if (latest == null) return;
      final values = <String, dynamic>{
        'level': int.parse(level.text.trim()),
        'grade': int.parse(grade.text.trim()),
        if (power.text.trim().isNotEmpty)
          'totalPower': int.parse(power.text.trim()),
        if (stats.values.every((c) => c.text.trim().isNotEmpty))
          'statsTotal': {
            for (final e in stats.entries)
              e.key: int.parse(e.value.text.trim()),
          },
      };
      if (masterParticipantUsesRemote) {
        await sendMasterParticipantCommand(
          anchor,
          'levelGrade',
          values: values,
        );
        return;
      }
      setState(() {
        applyMasterParticipantNumericValues(latest, values);
      });
      saveMasterParticipantChange(anchor.encounterId);
    } finally {
      level.dispose();
      grade.dispose();
      power.dispose();
      for (final controller in stats.values) {
        controller.dispose();
      }
    }
  }
}
