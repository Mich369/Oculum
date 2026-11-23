part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const _oculumMasterOnlyDraft = 'masterOnlyDraft';

extension _OculumFightCreator on _OculumHomePageState {
  bool isMasterOnlyDraft(Map? group) => group?[_oculumMasterOnlyDraft] == true;

  bool get activeMasterOnlyDraft => isMasterOnlyDraft(
    masterInitiativeGroups
        .where((group) => group['id'] == selectedMasterInitiativeGroupId)
        .firstOrNull,
  );

  bool isNonLethalTrainingForSheet({
    String? encounterId,
    String? participantTag,
  }) {
    final shared = realtimeService?.isConnected == true && !realtimeIsMasterRole;
    final id =
        encounterId ??
        (shared ? onlineCombatEncounterId : selectedMasterInitiativeGroupId);
    final group = shared
        ? [realtimeVisibleInitiativeSnapshot, ...realtimeEncounterSnapshots]
              .where((fight) => fight['encounterId'] == id)
              .firstOrNull
        : masterInitiativeGroups.where((fight) => fight['id'] == id).firstOrNull;
    if (group == null ||
        group['trainingMode'] != true ||
        group['fightStarted'] != true ||
        group['combatEnded'] == true) {
      return false;
    }
    final tokens = !shared && id == selectedMasterInitiativeGroupId
        ? masterInitiativeTokens
        : group['tokens'] as List? ?? const [];
    final tag = participantTag ?? sheetTagAt(schedaCorrente);
    return tokens.whereType<Map<String, dynamic>>().any(
      (token) =>
          token['outsideFight'] != true && combatTokenMatchesSheet(token, tag),
    );
  }

  /// A generated sheet stays private even before it belongs to an encounter.
  /// Participation in an ordinary encounter retains its existing sharing rules.
  bool masterOnlyDraftSheetAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return false;
    final tag = sheetTagAt(index);
    var private = schedePersonaggio[index][_oculumMasterOnlyDraft] == true;
    for (final group in masterInitiativeGroups) {
      final Iterable<Map> tokens =
          group['id'] == selectedMasterInitiativeGroupId
          ? masterInitiativeTokens
          : (group['tokens'] as List? ?? const []).whereType<Map>();
      if (!tokens.any(
        (token) =>
            oculumSameSheetIdentity(token['sheetTag'] ?? token['id'], tag),
      )) {
        continue;
      }
      if (!isMasterOnlyDraft(group)) return false;
      private = true;
    }
    return private;
  }

  bool get canUseFightCreator =>
      mounted &&
      oculumFightCreatorMasterAccess(
        connected: realtimeService?.isConnected == true,
        masterRole: realtimeIsMasterRole,
        coMasterRole: realtimeIsCoMasterRole,
        localMasterMode: modalitaMaster,
        localMasterHost: isMasterHost,
      );

  Widget fightCreatorPanel() => !canUseFightCreator
      ? const SizedBox.shrink()
      : gothicPanel(
          borderColor: primaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('fight-creator-open'),
                  onPressed: showFightCreator,
                  icon: const Icon(Icons.groups),
                  label: Text(
                    t(
                      'Fight Creator · Prepara uno scontro',
                      'Fight Creator · Prepare an encounter',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              smallInfoText(
                t(
                  'Scegli PG, NPC e mostri, confronta le Potenze delle squadre e cerca rinforzi per area. La bozza resta privata fino a «Pubblica Fight».',
                  'Choose PCs, NPCs and monsters, compare team Power and find reinforcements by area. The draft stays private until “Publish Fight”.',
                ),
              ),
            ],
          ),
        );

  List<OculumPawnGuardian> fightCreatorGuardians(Set<String> owners) => [
    for (final pawn in pawnGuardians)
      if (owners.contains(pawn.ownerTag) &&
          pawn.alive &&
          !pawn.pendingRegistration &&
          !pawn.isSummoningSlime &&
          !masterInitiativeGroups.any(
            (group) => (group['tokens'] as List? ?? const [])
                .whereType<Map>()
                .any((token) => token['pawnId'] == pawn.id),
          ))
        pawn,
  ];

  /// Only identifiers and team assignments leave the private dialog. No draft,
  /// power estimate, comparison or recommendation is persisted or broadcast.
  bool prepareFightCreatorEncounter({
    required String scope,
    required String name,
    required Map<String, String> assignments,
    required List<_FightTeam> teams,
    required Set<String> guardianIds,
    bool trainingMode = false,
  }) {
    if (!canUseFightCreator ||
        permissionScope != scope ||
        assignments.isEmpty) {
      return false;
    }
    final ids = teams.map((team) => team.id).toSet();
    if (ids.length != teams.length ||
        !ids.containsAll(const ['ally', 'enemy', 'neutral']) ||
        assignments.values.any((id) => !ids.contains(id)) ||
        teams.any(
          (team) =>
              team.name.trim().isEmpty ||
              team.name.length > 40 ||
              (team.color.toARGB32() >>> 24) != 0xff,
        ) ||
        teams.map((team) => team.name.toLowerCase()).toSet().length !=
            teams.length ||
        teams.map((team) => team.color.toARGB32()).toSet().length !=
            teams.length) {
      return false;
    }
    final indexes = <String, int>{};
    for (final tag in assignments.keys) {
      final index = localSheetIndexForOculumTag(tag);
      if (index < 0 || !sheetCanBeAddedToMasterInitiative(index)) return false;
      indexes[tag] = index;
    }
    final guardians = fightCreatorGuardians(assignments.keys.toSet());
    if (!guardians.map((pawn) => pawn.id).toSet().containsAll(guardianIds)) {
      return false;
    }
    // Validate everything before adding a group; the current fight is retained.
    addMasterInitiativeGroup(masterOnlyDraft: true);
    final encounter = selectedMasterInitiativeGroupId;
    final group = masterParticipantGroup(encounter)!;
    group['trainingMode'] = trainingMode;
    group['name'] = name.trim().isEmpty
        ? 'Scontro preparato'
        : cleanUiText(name).trim();
    final fightId = masterParticipantFightId(encounter);
    final resolved = <String, String>{};
    for (final team in teams) {
      if (const ['ally', 'enemy', 'neutral'].contains(team.id)) {
        resolved[team.id] = team.id;
      } else {
        // saveFightTeam generates the permanent ID and validates name/color.
        if (!saveFightTeam(
          encounter,
          name: team.name,
          color: team.color,
          expectedFightId: fightId,
        )) {
          return false;
        }
        resolved[team.id] = fightTeams(encounter)
            .firstWhere(
              (value) => value.name == team.name && value.color == team.color,
            )
            .id;
      }
    }
    for (final index in indexes.values) {
      addSheetToMasterInitiative(
        index,
        rollInitiative: false,
        includeGuardians: false,
        shareToRealtime: false,
      );
    }
    for (final pawn in guardians.where(
      (pawn) => guardianIds.contains(pawn.id),
    )) {
      addPawnToInitiative(pawn, rollInitiative: false);
      final owner = masterInitiativeTokens
          .where((token) => token['sheetTag'] == pawn.ownerTag)
          .firstOrNull;
      final child = masterInitiativeTokens
          .where((token) => token['pawnId'] == pawn.id)
          .firstOrNull;
      if (owner != null && child != null) {
        child['sourceTokenId'] = owner['id'] ?? owner['sheetTag'];
      }
    }
    for (final assignment in assignments.entries) {
      final token = masterInitiativeTokens.firstWhere(
        (value) => value['sheetTag'] == assignment.key,
      );
      assignFightTeam(
        encounter,
        '${token['id'] ?? token['sheetTag']}',
        resolved[assignment.value]!,
        expectedFightId: fightId,
      );
    }
    captureActiveMasterInitiativeGroup();
    programmaSalvataggio();
    setState(() {
      risultato =
          'Bozza privata preparata in Master → Turnistica. Usa “Pubblica Fight” per condividerla; avvia il combattimento quando sei pronto.';
    });
    return true;
  }

  Future<void> showFightCreator() async {
    if (!canUseFightCreator) return;
    salvaSchedaCorrenteInMemoria();
    final scope = permissionScope;
    final assignments = <String, String>{
      for (final index in masterPartyIndexes())
        if (sheetCanBeAddedToMasterInitiative(index) &&
            sheetSideAt(index) != 'enemy')
          sheetTagAt(index): sheetSideAt(index) == 'neutral'
              ? 'neutral'
              : 'ally',
    };
    final teams = _fightTeamsFrom(null);
    final name = TextEditingController(text: 'Scontro preparato');
    final search = TextEditingController();
    final teamName = TextEditingController();
    final suggestionPowers = <(String, int), int>{};
    var habitat = oculumMonsterHabitats.containsKey(selectedPlaneId)
        ? selectedPlaneId
        : '';
    var catalog = false, includeGuardians = true, busy = false;
    var trainingMode = false;
    var targetPercent = 100, suggestionLevel = 0;
    var comparisonTeam = 'ally';
    var status = '';
    BuildContext? creatorContext;
    var closing = false;
    bool permitted() => canUseFightCreator && permissionScope == scope;
    // A dialog has its own route: revoke the route as well as the entry button
    // when authoritative role or room/campaign changes while it is open.
    final permissionWatch = Timer.periodic(const Duration(milliseconds: 400), (
      _,
    ) {
      final active = creatorContext;
      if (!permitted() && active != null && active.mounted && !closing) {
        closing = true;
        final route = ModalRoute.of(active);
        Navigator.of(
          active,
        ).popUntil((candidate) => identical(candidate, route));
        if (active.mounted) Navigator.of(active).pop();
      }
    });
    try {
      await oculumShowDialogUntilClosed<void>(
        context: context,
        builder: (dialogContext) {
          creatorContext = dialogContext;
          return StatefulBuilder(
            builder: (context, refresh) {
              if (!permitted()) return const SizedBox.shrink();
              final pawnTags = pawnGuardians
                  .map((pawn) => pawn.creatureSheetTag)
                  .where((tag) => tag.isNotEmpty)
                  .toSet();
              final roster = <int>[
                for (var index = 0; index < schedePersonaggio.length; index++)
                  if (sheetCanBeAddedToMasterInitiative(index) &&
                      !pawnTags.contains(sheetTagAt(index)))
                    index,
              ];
              final available = roster.map(sheetTagAt).toSet();
              assignments.removeWhere((tag, _) => !available.contains(tag));
              final guardians = includeGuardians
                  ? fightCreatorGuardians(assignments.keys.toSet())
                  : <OculumPawnGuardian>[];
              final summary = oculumFightCreatorPowerSummary([
                for (final index in roster)
                  if (assignments.containsKey(sheetTagAt(index)))
                    (
                      id: sheetTagAt(index),
                      teamId: assignments[sheetTagAt(index)]!,
                      power: scoutTotalPowerAt(index),
                    ),
                for (final pawn in guardians)
                  (
                    id: 'guardian:${pawn.id}',
                    teamId: assignments[pawn.ownerTag]!,
                    power: oculumScoutPower(
                      pawn.level,
                      pawn.stats.values,
                      grade: pawn.grade,
                    ),
                  ),
              ]);
              final reference = summary.teams[comparisonTeam] ?? 0;
              final remaining = oculumFightCreatorRemainingEnemyPower(
                allyPower: reference,
                enemyPower: summary.teams['enemy'] ?? 0,
                targetPercent: targetPercent,
              );
              final query = oculumNormalizeText(search.text);
              final suggestions =
                  (catalog ? monsterBookEntries : <MonsterBookEntry>[])
                      .where(
                        (entry) =>
                            entry.generationSide == 'enemy' &&
                            entry.id != 'pawn_guardiano' &&
                            oculumMonsterMatchesHabitatFilter(entry, habitat) &&
                            (query.isEmpty ||
                                oculumNormalizeText(
                                  '${entry.nameIt} ${entry.descIt}',
                                ).contains(query)),
                      )
                      .toList();
              int suggestedPower(MonsterBookEntry entry) =>
                  suggestionPowers.putIfAbsent(
                    (entry.id, suggestionLevel),
                    () => oculumScoutPower(
                      suggestionLevel,
                      oculumMonsterCreationStats(entry, suggestionLevel).values,
                      grade: oculumGradeForLevel(suggestionLevel),
                    ),
                  );
              suggestions.sort((a, b) {
                final distance = (suggestedPower(a) - remaining)
                    .abs()
                    .compareTo((suggestedPower(b) - remaining).abs());
                return distance != 0 ? distance : a.nameIt.compareTo(b.nameIt);
              });
              final visible = roster
                  .where(
                    (index) =>
                        query.isEmpty ||
                        oculumNormalizeText(
                          nomeSchedaPersonaggio(index),
                        ).contains(query),
                  )
                  .toList();
              return AlertDialog(
                key: const ValueKey('fight-creator-dialog'),
                backgroundColor: backgroundMidColor,
                title: const Text('Fight Creator · Solo Master'),
                content: SizedBox(
                  width: 960,
                  height: max(180.0, MediaQuery.sizeOf(context).height * .74),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Nome dello scontro',
                        ),
                      ),
                      CheckboxListTile(
                        key: const ValueKey('fight-creator-training-mode'),
                        value: trainingMode,
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Allenamento non letale'),
                        secondary: Tooltip(
                          message:
                              'Stanza separata: i colpi possono mettere a terra senza tiri di morte. Alla chiusura o fuga assegna EXP dalla Potenza dei nemici morti o a terra; +150 una volta per Riposo Lungo e +100 se Difesa nemica e Danni differiscono al massimo di 6.',
                          child: const Icon(Icons.info_outline),
                        ),
                        onChanged: busy
                            ? null
                            : (value) =>
                                  refresh(() => trainingMode = value == true),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 100),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Chip(
                                label: Text(
                                  'Totale ${summary.total} · ${summary.count} partecipanti',
                                ),
                                key: const ValueKey('fight-creator-total'),
                              ),
                              for (final team in teams)
                                Chip(
                                  side: BorderSide(color: team.color),
                                  label: Text(
                                    '${team.name}: ${summary.teams[team.id] ?? 0} PT',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        children: [
                          ChoiceChip(
                            label: const Text('Schede e squadre'),
                            selected: !catalog,
                            onSelected: busy
                                ? null
                                : (_) => refresh(() {
                                    catalog = false;
                                    search.clear();
                                  }),
                          ),
                          ChoiceChip(
                            label: const Text('Suggerimenti per area'),
                            selected: catalog,
                            onSelected: busy
                                ? null
                                : (_) => refresh(() {
                                    catalog = true;
                                    search.clear();
                                  }),
                          ),
                        ],
                      ),
                      TextField(
                        controller: search,
                        onChanged: (_) => refresh(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Cerca',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      Expanded(
                        child: catalog
                            ? ListView(
                                children: [
                                  monsterHabitatFilter(
                                    habitat,
                                    (value) => refresh(() => habitat = value),
                                  ),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 6,
                                    children: [
                                      SizedBox(
                                        width: 190,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: comparisonTeam,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Confronta con',
                                          ),
                                          items: [
                                            for (final team in teams.where(
                                              (team) => team.id != 'enemy',
                                            ))
                                              DropdownMenuItem(
                                                value: team.id,
                                                child: Text(team.name),
                                              ),
                                          ],
                                          onChanged: (value) => refresh(
                                            () => comparisonTeam =
                                                value ?? 'ally',
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: TextFormField(
                                          initialValue: '$targetPercent',
                                          decoration: const InputDecoration(
                                            labelText: 'Obiettivo PT %',
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) => refresh(
                                            () => targetPercent =
                                                (int.tryParse(value) ?? 100)
                                                    .clamp(0, 1000),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: TextFormField(
                                          initialValue: '$suggestionLevel',
                                          decoration: const InputDecoration(
                                            labelText: 'Livello proposte',
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) => refresh(
                                            () => suggestionLevel =
                                                (int.tryParse(value) ?? 0)
                                                    .clamp(0, 1000),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Riferimento $reference PT · Nemici ${summary.teams['enemy'] ?? 0} PT · Mancano $remaining PT all’obiettivo.',
                                  ),
                                  smallInfoText(
                                    'Proposte ordinate per vicinanza al budget nell’area scelta. La Potenza base è indicativa: equipaggiamento, effetti e personalizzazioni sono inclusi nel riepilogo dopo la creazione. Non garantisce la difficoltà dello scontro.',
                                  ),
                                  if (suggestions.isEmpty)
                                    const Text(
                                      'Nessuna creatura in quest’area. Puoi cambiare il filtro.',
                                    ),
                                  for (final entry in suggestions.take(30))
                                    ListTile(
                                      key: ValueKey(
                                        'fight-creator-suggestion-${entry.id}',
                                      ),
                                      leading: creatureRecognitionPreview(
                                        entry,
                                        canEnlarge: true,
                                      ),
                                      title: Text(entry.nameIt),
                                      subtitle: Text(
                                        'Lv $suggestionLevel · PT base ${suggestedPower(entry)}',
                                      ),
                                      trailing: IconButton(
                                        tooltip:
                                            'Imposta quantità, livello e statistiche',
                                        icon: const Icon(Icons.add),
                                        onPressed: busy
                                            ? null
                                            : () async {
                                                if (!permitted()) return;
                                                final before = schedePersonaggio
                                                    .map(
                                                      (sheet) =>
                                                          '${sheet['sheetTag']}',
                                                    )
                                                    .toSet();
                                                final previous = (
                                                  quickSheetNameController.text,
                                                  quickSheetDescriptionController
                                                      .text,
                                                  quickSheetCountController
                                                      .text,
                                                  quickSheetAddToInitiative,
                                                );
                                                refresh(() => busy = true);
                                                quickSheetAddToInitiative =
                                                    false;
                                                try {
                                                  await showMonsterBookQuickSpawnDialog(
                                                    entry,
                                                    forFightCreator: true,
                                                    initialLevel:
                                                        suggestionLevel,
                                                  );
                                                  if (!permitted()) return;
                                                  for (
                                                    var index = 0;
                                                    index <
                                                        schedePersonaggio
                                                            .length;
                                                    index++
                                                  ) {
                                                    final tag = sheetTagAt(
                                                      index,
                                                    );
                                                    if (!before.contains(tag)) {
                                                      assignments[tag] =
                                                          sheetSideAt(index);
                                                    }
                                                  }
                                                  status =
                                                      'Le schede create restano salvate anche se chiudi la bozza.';
                                                } finally {
                                                  quickSheetNameController
                                                          .text =
                                                      previous.$1;
                                                  quickSheetDescriptionController
                                                          .text =
                                                      previous.$2;
                                                  quickSheetCountController
                                                          .text =
                                                      previous.$3;
                                                  quickSheetAddToInitiative =
                                                      previous.$4;
                                                  if (dialogContext.mounted &&
                                                      permitted()) {
                                                    refresh(() => busy = false);
                                                  }
                                                }
                                              },
                                      ),
                                    ),
                                  if (suggestions.length > 30)
                                    const Text(
                                      'Prime 30 proposte: usa la ricerca per le altre.',
                                    ),
                                ],
                              )
                            : ListView(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: teamName,
                                          decoration: const InputDecoration(
                                            labelText:
                                                'Nuova squadra (max 40 caratteri)',
                                          ),
                                          maxLength: 40,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.group_add),
                                        tooltip: 'Aggiungi squadra',
                                        onPressed: busy
                                            ? null
                                            : () => refresh(() {
                                                final label = cleanUiText(
                                                  teamName.text,
                                                ).trim();
                                                if (label.isEmpty ||
                                                    teams.any(
                                                      (team) =>
                                                          team.name
                                                              .toLowerCase() ==
                                                          label.toLowerCase(),
                                                    )) {
                                                  return;
                                                }
                                                final id =
                                                    'draft:${teams.length}';
                                                final color = HSVColor.fromAHSV(
                                                  1,
                                                  (teams.length * 137.508) %
                                                      360,
                                                  .65,
                                                  .95,
                                                ).toColor();
                                                teams.add((
                                                  id: id,
                                                  name: label,
                                                  color: color,
                                                ));
                                                teamName.clear();
                                              }),
                                      ),
                                    ],
                                  ),
                                  CheckboxListTile(
                                    value: includeGuardians,
                                    title: const Text(
                                      'Includi i guardiani disponibili dei partecipanti',
                                    ),
                                    subtitle: const Text(
                                      'Sono conteggiati singolarmente e seguono la squadra del proprietario. Quelli già impegnati in altri scontri non vengono aggiunti.',
                                    ),
                                    onChanged: busy
                                        ? null
                                        : (value) => refresh(
                                            () => includeGuardians =
                                                value == true,
                                          ),
                                  ),
                                  for (final index in visible) ...[
                                    CheckboxListTile(
                                      key: ValueKey(
                                        'fight-creator-sheet-${sheetTagAt(index)}',
                                      ),
                                      value: assignments.containsKey(
                                        sheetTagAt(index),
                                      ),
                                      title: Text(
                                        '${nomeSchedaPersonaggio(index)} · ${scoutTotalPowerAt(index)} PT',
                                      ),
                                      subtitle: Text(
                                        '${tipoSchedaPersonaggio(index)} · Lv ${sheetCriticalLevelAt(index)} · Gr ${sheetIntValueAt(index, 'grado')}\n'
                                        '${[
                                          for (final key in ['resilienza', 'volonta', 'materia', 'oculum']) '${key.toUpperCase()}: ${index == schedaCorrente ? switch (key) {
                                                    'resilienza' => resilienzaTotale(),
                                                    'volonta' => volontaTotale(),
                                                    'materia' => materiaTotale(),
                                                    _ => oculumTotale(),
                                                  } : readIntValue(schedePersonaggio[index]['derived${key[0].toUpperCase()}${key.substring(1)}Total'], fallback: sheetIntValueAt(index, key))}',
                                        ].join(' · ')}',
                                      ),
                                      onChanged: busy
                                          ? null
                                          : (value) => refresh(() {
                                              final tag = sheetTagAt(index);
                                              if (value == true) {
                                                assignments[tag] = sheetSideAt(
                                                  index,
                                                );
                                              } else {
                                                assignments.remove(tag);
                                              }
                                            }),
                                    ),
                                    if (assignments.containsKey(
                                      sheetTagAt(index),
                                    ))
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          key: ValueKey(
                                            'creator-team-${sheetTagAt(index)}',
                                          ),
                                          initialValue:
                                              assignments[sheetTagAt(index)],
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Squadra',
                                          ),
                                          items: [
                                            for (final team in teams)
                                              DropdownMenuItem(
                                                value: team.id,
                                                child: Text(team.name),
                                              ),
                                          ],
                                          onChanged: busy
                                              ? null
                                              : (value) => refresh(
                                                  () =>
                                                      assignments[sheetTagAt(
                                                            index,
                                                          )] =
                                                          value!,
                                                ),
                                        ),
                                      ),
                                  ],
                                  for (final pawn in guardians)
                                    ListTile(
                                      leading: const Icon(Icons.shield),
                                      title: Text(
                                        '${pawn.displayName} · ${oculumScoutPower(pawn.level, pawn.stats.values, grade: pawn.grade)} PT',
                                      ),
                                      subtitle: Text(
                                        'Guardiano · ${teams.firstWhere((team) => team.id == assignments[pawn.ownerTag]).name}',
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      if (status.isNotEmpty) Text(status),
                      if (trainingMode)
                        smallInfoText(
                          'Stanza separata: Danni non letali; EXP alla chiusura o fuga. Bonus: +150 una volta per Riposo Lungo e +100 con Difesa entro 6 dai Danni.',
                        ),
                      smallInfoText(
                        'La bozza resta privata, anche dopo la preparazione. In Turnistica usa “Pubblica Fight” per condividerla.',
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: busy ? null : () => Navigator.pop(dialogContext),
                    child: const Text('Chiudi'),
                  ),
                  FilledButton(
                    key: const ValueKey('fight-creator-prepare'),
                    onPressed: busy || assignments.isEmpty
                        ? null
                        : () {
                            if (!permitted()) return;
                            refresh(() => busy = true);
                            final prepared = prepareFightCreatorEncounter(
                              scope: scope,
                              name: name.text,
                              assignments: Map.of(assignments),
                              teams: List.of(teams),
                              guardianIds: guardians
                                  .map((pawn) => pawn.id)
                                  .toSet(),
                              trainingMode: trainingMode,
                            );
                            if (prepared) {
                              Navigator.pop(dialogContext);
                            } else {
                              refresh(() {
                                busy = false;
                                status =
                                    'Le schede o i permessi sono cambiati. Ricontrolla la selezione.';
                              });
                            }
                          },
                    child: Text(
                      trainingMode ? 'Prepara allenamento' : 'Prepara scontro',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      closing = true;
      permissionWatch.cancel();
      name.dispose();
      search.dispose();
      teamName.dispose();
    }
  }
}
