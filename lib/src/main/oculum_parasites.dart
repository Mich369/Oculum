part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int oculumParasiteMedicineThreshold(int reflexes) => reflexes <= 10
    ? 14
    : reflexes <= 12
    ? 15
    : reflexes <= 13
    ? 16
    : reflexes <= 14
    ? 17
    : 18;
int oculumParasiteEscapePenalty(int turns) => min(9, max(0, turns) * 3);

extension _OculumParasites on _OculumHomePageState {
  bool get isLarvalParasite =>
      '${schedePersonaggio.elementAtOrNull(schedaCorrente)?['monsterBookSourceId'] ?? ''}'
          .startsWith('parassita_larvale');
  Map get parasiteInfestation =>
      planarState['parasiteInfestation'] as Map? ?? {};
  bool get parasiteInfested => parasiteInfestation.isNotEmpty;
  bool get parasiteOwnerLocked =>
      parasiteInfested &&
      !(modalitaMaster ||
          isMasterHost ||
          realtimeIsMasterRole ||
          realtimeIsCoMasterRole);
  int get parasiteReflexes {
    if (!isLarvalParasite) return 0;
    return readIntValue(
      planarState.putIfAbsent(
        'parasiteReflexes',
        () => 9 + Random.secure().nextInt(7),
      ),
    ).clamp(9, 15);
  }

  bool get parasiteHiddenInHost =>
      isLarvalParasite && planarState['parasiteHostTag'] != null;

  bool parasiteSheetControlledByStaff(String tag) {
    if (!(realtimeIsMasterRole ||
        realtimeIsCoMasterRole ||
        modalitaMaster ||
        isMasterHost)) {
      return false;
    }
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0) return false;
    return ((schedePersonaggio[index]['planarRuntime']
                    as Map?)?['parasiteInfestation']
                as Map? ??
            {})
        .isNotEmpty;
  }

  bool parasiteStaffPacket(Map<String, dynamic> packet, String tag) {
    if (!const {'master', 'coMaster'}.contains('${packet['senderRole']}')) {
      return false;
    }
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0) return false;
    return ((schedePersonaggio[index]['planarRuntime']
                    as Map?)?['parasiteInfestation']
                as Map? ??
            {})
        .isNotEmpty;
  }

  Widget parasiteEscapePanel() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      Text(
        'Infestazione · DT da superare ${parasiteInfestation['roll']} · penalità −${oculumParasiteEscapePenalty(readIntValue(parasiteInfestation['turns']))}',
      ),
      for (final key in const ['resistenza', 'volonta'])
        FilledButton(
          onPressed: () => attemptParasiteEscape(key),
          child: Text(
            'Liberati · ${key == 'volonta' ? 'Volontà' : 'Resistenza'}',
          ),
        ),
      for (final (i, art) in arti.indexed)
        if (art.inUso && artOpenSbloccata(art))
          OutlinedButton(
            onPressed: () => usaOpenArt(i),
            child: Text('Open · ${art.nome}'),
          ),
      for (final title in titoli.where((t) => t.evoluto))
        OutlinedButton(
          onPressed: () => usaOpen(title),
          child: Text('Open · ${title.nome}'),
        ),
      OutlinedButton(
        onPressed: parasiteMedicineTreatment,
        child: const Text('Cura · Medicina per espellere'),
      ),
    ],
  );

  void installParasite(Map<String, dynamic> request) {
    if (parasiteInfested) return;
    final reflex = readIntValue(
      request['parasiteReflexes'],
      fallback: 9,
    ).clamp(9, 15);
    final parasiteIndex = localSheetIndexForOculumTag(
      '${request['sourceTag']}',
    );
    if (parasiteIndex >= 0 && parasiteIndex != schedaCorrente) {
      schedePersonaggio[parasiteIndex]['planarRuntime'] = {
        ...(schedePersonaggio[parasiteIndex]['planarRuntime'] as Map? ?? {}),
        'parasiteHostTag': sheetTagAt(schedaCorrente),
      };
    }
    planarState['parasiteInfestation'] = {
      'sourceTag': request['sourceTag'],
      'sourceName': request['sourceName'],
      'roll': request['attack'],
      'reflexes': reflex,
      'turns': 0,
      'damageBonus': max(0, readIntValue(request['parasiteDamage'])) ~/ 2,
      'defenseBonus': max(0, readIntValue(request['parasiteDefense'])) ~/ 2,
    };
    aggiungiLog(
      '[PARASSITA] ${request['sourceName']} controlla ${realtimeDisplayName()}. Il proprietario può liberarsi con Resistenza, Volontà o Open.',
    );
    programmaSalvataggio();
    unawaited(sendRealtimeActiveSheetToStaff());
  }

  Future<void> attemptParasiteEscape(String stat) async {
    if (!parasiteInfested) return;
    final origin = currentSheetScrollId();
    final attemptedTurn = playerReportedTurn;
    if (readIntValue(parasiteInfestation['lastAttempt'], fallback: -1) ==
        attemptedTurn) {
      aggiungiLog('[PARASSITA] Hai già tentato in questo turno.');
      return;
    }
    if (!await requestUtilitySpend('azione')) return;
    if (!mounted || origin != currentSheetScrollId() || !parasiteInfested) {
      return;
    }
    final infestation = Map<String, dynamic>.from(parasiteInfestation);
    final sub = hiddenEyeStats.where((s) => s.id == 'resistenza').firstOrNull;
    final bonus = stat == 'volonta'
        ? volontaTotale()
        : sub == null
        ? 0
        : hiddenEyeTotal(sub);
    final natural = tiraD20();
    final total = rollTotalWithCritical(natural, 20, [
      bonus,
      readIntValue(infestation['adrenaline']),
      -oculumParasiteEscapePenalty(readIntValue(infestation['turns'])),
    ]);
    infestation['lastAttempt'] = attemptedTurn;
    infestation['adrenaline'] = 0;
    planarState['parasiteInfestation'] = infestation;
    final target = readIntValue(infestation['roll']);
    aggiungiLog(
      '[LIBERAZIONE] $stat $total contro $target: ${total > target ? 'libero' : 'ancora infestato'}.',
    );
    if (total > target) {
      clearParasite(killed: false);
    } else if (target - total <= 5) {
      final index = masterInitiativeTokens.indexWhere(
        (t) => '${t['sheetTag'] ?? t['id']}' == '${infestation['sourceTag']}',
      );
      if (index >= 0) {
        consumeMasterReactionForSheetTag('${infestation['sourceTag']}');
      }
      if (target - total == 1) infestation['controllerRollPenalty'] = -4;
      aggiungiLog(
        '[PARASSITA] Il controllore perde una Reazione${target - total == 1 ? ' e avrà −4 al prossimo tiro' : ''}.',
      );
    }
    programmaSalvataggio();
    unawaited(sendRealtimeActiveSheetToStaff());
    setState(() {});
  }

  void clearParasite({required bool killed}) {
    if (!parasiteInfested) return;
    final source = '${parasiteInfestation['sourceTag']}';
    final index = localSheetIndexForOculumTag(source);
    if (index >= 0) {
      final state = Map<String, dynamic>.from(
        schedePersonaggio[index]['planarRuntime'] as Map? ?? {},
      );
      state.remove('parasiteHostTag');
      schedePersonaggio[index]['planarRuntime'] = state;
      if (killed) schedePersonaggio[index]['currentHp'] = '0';
    }
    planarState.remove('parasiteInfestation');
    invalidateDerivedDataCaches();
    aggiungiLog(
      '[PARASSITA] Controllo recuperato${killed ? '; parassita ucciso' : ''}.',
    );
    programmaSalvataggio();
    unawaited(sendRealtimeActiveSheetToStaff());
  }

  Future<void> parasiteMedicineTreatment() async {
    if (parasiteOwnerLocked) return;
    final origin = currentSheetScrollId();
    final candidates = <int>[
      for (var i = 0; i < schedePersonaggio.length; i++)
        if ((((schedePersonaggio[i]['planarRuntime']
                        as Map?)?['parasiteInfestation'])
                    as Map? ??
                {})
            .isNotEmpty)
          i,
    ];
    final selected = await showDialog<int>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: const Text('Medicina · cura un infestato'),
        children: [
          for (final i in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, i),
              child: Text(nomeSchedaPersonaggio(i)),
            ),
        ],
      ),
    );
    if (!mounted || selected == null || origin != currentSheetScrollId()) {
      return;
    }
    if (!await requestUtilitySpend('azione')) return;
    if (!mounted || origin != currentSheetScrollId()) return;
    final natural = tiraD20();
    final effect = OculumStructuredEffect(
      type: 'planar',
      target: 'parasite_medicine',
      duration: '1',
      valueExpression: '$natural',
      recipient: 'se_stesso',
    );
    final tag = sheetTagAt(selected);
    aggiungiLog(
      '[MEDICINA] Cura ${nomeSchedaPersonaggio(selected)}: dado naturale $natural.',
    );
    if (controlsOnlineCombatSheet(tag)) {
      applySupportToOwnedSheet(selected, [effect], realtimeDisplayName());
    } else {
      final packet = <String, dynamic>{
        'id': 'parasite_medicine:${DateTime.now().microsecondsSinceEpoch}',
        'helpMode': 'effects',
        'effects': [effect.toJson()],
        'sourceTag': sheetTagAt(schedaCorrente),
        'sourceName': realtimeDisplayName(),
        'targetTag': tag,
        'targetName': nomeSchedaPersonaggio(selected),
        'encounterId': onlineCombatEncounterId,
      };
      attachPendingCombatTurnResources(packet);
      await realtimeService?.sendCombatEvent(
        'combat_help',
        permissionEnvelope(packet),
      );
    }
    programmaSalvataggio();
  }

  void applyParasiteMedicine(int natural) {
    if (!parasiteInfested) return;
    final threshold = oculumParasiteMedicineThreshold(
      readIntValue(parasiteInfestation['reflexes']),
    );
    aggiungiLog(
      '[MEDICINA] Naturale $natural contro $threshold: ${natural >= threshold ? 'parassita ucciso' : 'resiste'}.',
    );
    if (natural >= threshold) clearParasite(killed: true);
  }

  void parasiteTurn() {
    if (!parasiteInfested) return;
    planarState['parasiteInfestation'] = {
      ...parasiteInfestation,
      'turns': readIntValue(parasiteInfestation['turns']) + 1,
    };
  }

  int consumeParasiteControllerPenalty() {
    final penalty = readIntValue(parasiteInfestation['controllerRollPenalty']);
    if (penalty != 0) {
      planarState['parasiteInfestation'] = {
        ...parasiteInfestation,
        'controllerRollPenalty': 0,
      };
    }
    return penalty;
  }

  Future<void> resolveMartyrDeath(Map enemy, String receipt) async {
    if (!'${enemy['monsterBookId']}'.startsWith('martire_mortale')) return;
    final seen = (partyChest['martyrReceipts'] as List? ?? [])
        .map((v) => '$v')
        .toSet();
    if (seen.contains(receipt)) return;
    final ownToken = masterInitiativeTokens
        .where((t) => '${t['id']}' == '${enemy['id']}')
        .firstOrNull;
    final side = ownToken?['side'] ?? 'enemy';
    final candidates = masterInitiativeTokens
        .where(
          (t) =>
              t['side'] == side &&
              '${t['id']}' != '${enemy['id']}' &&
              !const {'dead', 'fled', 'expired'}.contains('${t['status']}'),
        )
        .toList();
    final selected = <String>{};
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Martire Mortale · fino a 3 alleati'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final target in candidates)
                    CheckboxListTile(
                      title: Text('${target['name']}'),
                      value: selected.contains(
                        '${target['sheetTag'] ?? target['id']}',
                      ),
                      onChanged: (value) => update(() {
                        final tag = '${target['sheetTag'] ?? target['id']}';
                        if (value == true && selected.length < 3) {
                          selected.add(tag);
                        } else {
                          selected.remove(tag);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Assegna il sacrificio'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || accepted != true) return;
    seen.add(receipt);
    partyChest['martyrReceipts'] = seen.toList();
    final level = max(0, readIntValue(enemy['level']));
    final percent = 10 + (level ~/ 10) * 10;
    final duration = max(1, level ~/ 5);
    for (final tag in selected) {
      final index = localSheetIndexForOculumTag(tag);
      if (index < 0) continue;
      applySupportToOwnedSheet(index, [
        for (final stat in const ['resilienza', 'volonta', 'materia', 'oculum'])
          OculumStructuredEffect(
            id: 'martyr:$receipt:$stat',
            type: 'modifica_statistica',
            target: stat,
            valueExpression:
                '${(max(0, sheetIntValueAt(index, stat)) * percent / 100).ceil()}',
            duration: '$duration',
            recipient: 'se_stesso',
          ),
      ], 'Martire Mortale +$percent% · $duration turni');
    }
    programmaSalvataggio();
  }

  int parasiteHostBonus(String key) => readIntValue(parasiteInfestation[key]);
}
