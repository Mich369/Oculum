part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const _sessionMaterialSlotCount = 5;

const _sessionMaterialChecks = <String, (String, String)>{
  'percezione': ('Percezione', 'Perception'),
  'investigazione': ('Investigazione', 'Investigation'),
  'furbizia': ('Furbizia', 'Cunning'),
  'valutazione': ('Valutazione', 'Appraisal'),
  'lettura_aura': ('Lettura aura', 'Aura reading'),
};

typedef _SessionMaterialScope = ({String campaign, String master});

@visibleForTesting
Map<String, dynamic> oculumSessionMaterialCloudSaveForMaster(
  Map<String, dynamic> payload,
  String userId,
) {
  final campaigns = payload['campaigns'];
  if (campaigns is! List) return payload;
  final owner = 'account:$userId';
  List<dynamic>? filtered;
  for (var i = 0; i < campaigns.length; i++) {
    final campaign = campaigns[i];
    if (campaign is! Map) continue;
    final plans = campaign['sessionMaterialByMaster'];
    if (plans is! Map || plans.keys.every((key) => key == owner)) continue;
    final copy = Map<String, dynamic>.from(campaign);
    final ownPlan = plans[owner];
    if (ownPlan is Map) {
      copy['sessionMaterialByMaster'] = {owner: ownPlan};
    } else {
      copy.remove('sessionMaterialByMaster');
    }
    (filtered ??= List<dynamic>.of(campaigns))[i] = copy;
  }
  return filtered == null ? payload : {...payload, 'campaigns': filtered};
}

class _SessionMaterialSlot {
  const _SessionMaterialSlot({
    required this.name,
    required this.check,
    required this.difficulty,
    this.extractionGrade,
  });

  static _SessionMaterialSlot? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name'];
    final check = raw['check'];
    final difficulty = raw['difficulty'];
    if (name is! String ||
        name.trim().isEmpty ||
        check is! String ||
        !_sessionMaterialChecks.containsKey(check) ||
        difficulty is! int ||
        difficulty < 0) {
      return null;
    }
    final grade = raw['extractionGrade'];
    return _SessionMaterialSlot(
      name: name,
      check: check,
      difficulty: difficulty,
      extractionGrade: grade is int && grade >= 0 ? grade : null,
    );
  }

  final String name;
  final String check;
  final int difficulty;
  final int? extractionGrade;

  Map<String, Object?> toJson() => {
    'name': name,
    'check': check,
    'difficulty': difficulty,
    if (extractionGrade != null) 'extractionGrade': extractionGrade,
  };
}

class _SessionBattleDraft {
  _SessionBattleDraft({
    required this.id,
    required this.name,
    required this.participantTags,
    this.startedEncounterId,
  });

  static _SessionBattleDraft? fromJson(Map raw) {
    final id = raw['id'];
    final name = raw['name'];
    final participants = raw['participantTags'];
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        participants is! List) {
      return null;
    }
    final tags = participants
        .whereType<String>()
        .where((tag) => tag.isNotEmpty)
        .toSet();
    if (tags.isEmpty) return null;
    final started = raw['startedEncounterId'];
    return _SessionBattleDraft(
      id: id,
      name: name,
      participantTags: tags,
      startedEncounterId: started is String && started.isNotEmpty
          ? started
          : null,
    );
  }

  final String id;
  final String name;
  final Set<String> participantTags;
  String? startedEncounterId;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'participantTags': participantTags.toList(),
    if (startedEncounterId != null) 'startedEncounterId': startedEncounterId,
  };
}

class _SessionMaterialPlan {
  _SessionMaterialPlan();

  _SessionMaterialPlan.fromJson(Map json) {
    allowCoMaster = json['allowCoMaster'] == true;
    final savedSlots = json['materials'];
    if (savedSlots is List) {
      for (var i = 0; i < min(materials.length, savedSlots.length); i++) {
        materials[i] = _SessionMaterialSlot.fromJson(savedSlots[i]);
      }
    }
    final savedDrafts = json['battles'];
    if (savedDrafts is List) {
      for (final raw in savedDrafts.whereType<Map>()) {
        final battle = _SessionBattleDraft.fromJson(raw);
        if (battle != null) battles[battle.id] = battle;
      }
    }
  }

  bool allowCoMaster = false;
  final materials = List<_SessionMaterialSlot?>.filled(
    _sessionMaterialSlotCount,
    null,
  );
  final battles = <String, _SessionBattleDraft>{};

  Map<String, Object?> toJson() => {
    'allowCoMaster': allowCoMaster,
    'materials': materials.map((material) => material?.toJson()).toList(),
    'battles': battles.values.map((battle) => battle.toJson()).toList(),
  };
}

extension _OculumSessionMaterial on _OculumHomePageState {
  String? get sessionMaterialMasterKey {
    final service = realtimeService;
    if (service != null && service.isConnected) {
      // Local role preferences cannot authorize access in an online room.
      if (service.authenticatedRole != 'master') return null;
      final id = service.authenticatedUserId?.trim();
      return id == null || id.isEmpty ? null : 'account:$id';
    }
    if ((!modalitaMaster && !isMasterHost) ||
        isConnectedToMaster ||
        sonoCoMaster) {
      return null;
    }
    final id = OculumAuthService.instance.state.userId?.trim();
    return id == null || id.isEmpty ? 'local-master' : 'account:$id';
  }

  _SessionMaterialScope? get _sessionMaterialScope {
    final master = sessionMaterialMasterKey;
    if (master == null || activeCampaignId.isEmpty) return null;
    return (campaign: activeCampaignId, master: master);
  }

  void _editSessionMaterial(
    _SessionMaterialScope scope,
    void Function(_SessionMaterialPlan) edit,
  ) {
    if (!mounted || _sessionMaterialScope != scope) return;
    setState(() {
      edit(
        sessionMaterialsByMaster.putIfAbsent(
          scope.master,
          _SessionMaterialPlan.new,
        ),
      );
    });
    programmaSalvataggio(invalidateCaches: false);
  }

  Widget sessionMaterialPanel() {
    final scope = _sessionMaterialScope;
    if (scope == null) return const SizedBox.shrink();
    final plan =
        sessionMaterialsByMaster[scope.master] ?? _SessionMaterialPlan();
    return gothicPanel(
      borderColor: tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle(t('Materiale sessione', 'Session material')),
          SwitchListTile(
            key: const ValueKey('session-material-co-master'),
            title: Text(
              t('Consenti accesso al Co-Master', 'Allow Co-Master access'),
            ),
            subtitle: Text(
              t(
                'La preferenza è salvata. In questa versione il materiale resta privato per il Master.',
                'The preference is saved. Session material stays private to the Master in this version.',
              ),
            ),
            value: plan.allowCoMaster,
            onChanged: (value) => _editSessionMaterial(
              scope,
              (plan) => plan.allowCoMaster = value,
            ),
          ),
          for (var i = 0; i < _sessionMaterialSlotCount; i++)
            _sessionMaterialTile(scope, i, plan.materials[i]),
          const Divider(),
          sectionTitle(t('Battaglie preparate', 'Prepared battles')),
          for (final battle in plan.battles.values)
            ListTile(
              title: Text(battle.name),
              subtitle: Text(
                battle.startedEncounterId == null
                    ? t(
                        '${battle.participantTags.length} partecipanti',
                        '${battle.participantTags.length} participants',
                      )
                    : t('Avviata', 'Started'),
              ),
              trailing: battle.startedEncounterId == null
                  ? Wrap(
                      children: [
                        IconButton(
                          tooltip: t('Modifica battaglia', 'Edit battle'),
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editSessionBattle(scope, battle),
                        ),
                        IconButton(
                          key: ValueKey('session-material-start-${battle.id}'),
                          tooltip: t('Avvia battaglia', 'Start battle'),
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () =>
                              _activateSessionBattle(scope, battle.id),
                        ),
                      ],
                    )
                  : null,
            ),
          OutlinedButton.icon(
            key: const ValueKey('session-material-prepare'),
            icon: const Icon(Icons.add),
            label: Text(t('Prepara battaglia', 'Prepare battle')),
            onPressed: () => _editSessionBattle(scope),
          ),
        ],
      ),
    );
  }

  Widget _sessionMaterialTile(
    _SessionMaterialScope scope,
    int index,
    _SessionMaterialSlot? material,
  ) {
    final grade = material?.extractionGrade;
    final check = _sessionMaterialChecks[material?.check];
    return ListTile(
      key: ValueKey('session-material-slot-$index'),
      leading: Text('${index + 1}'),
      title: Text(
        material?.name ?? t('Materiale libero', 'Empty material slot'),
      ),
      subtitle: material == null || check == null
          ? null
          : Text(
              [
                '${t(check.$1, check.$2)} · DT ${material.difficulty}',
                if (grade != null)
                  t('Estraibile · Grado $grade', 'Extractable · Grade $grade'),
              ].join(' · '),
            ),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () => _editSessionMaterialSlot(scope, index, material),
    );
  }

  Future<void> _editSessionMaterialSlot(
    _SessionMaterialScope scope,
    int index,
    _SessionMaterialSlot? material,
  ) async {
    if (_sessionMaterialScope != scope) return;
    final form = GlobalKey<FormState>();
    var name = material?.name ?? '';
    var check = material?.check ?? 'percezione';
    var difficulty = material?.difficulty ?? 0;
    var grade = material?.extractionGrade ?? 0;
    var extractable = material?.extractionGrade != null;
    _SessionMaterialSlot? result;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(t('Materiale ${index + 1}', 'Material ${index + 1}')),
          scrollable: true,
          content: SizedBox(
            width: 380,
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: const ValueKey('session-material-name'),
                    initialValue: name,
                    maxLength: 120,
                    decoration: InputDecoration(labelText: t('Nome', 'Name')),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? t('Inserisci un nome.', 'Enter a name.')
                        : null,
                    onSaved: (value) => name = value!.trim(),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: check,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: t('Prova', 'Check')),
                    items: [
                      for (final item in _sessionMaterialChecks.entries)
                        DropdownMenuItem(
                          value: item.key,
                          child: Text(t(item.value.$1, item.value.$2)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) check = value;
                    },
                  ),
                  _sessionMaterialNumber(
                    key: const ValueKey('session-material-difficulty'),
                    label: 'DT',
                    value: difficulty,
                    onSaved: (value) => difficulty = value,
                  ),
                  CheckboxListTile(
                    value: extractable,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      t(
                        'Minerale o cristallo estraibile',
                        'Extractable mineral or crystal',
                      ),
                    ),
                    onChanged: (value) =>
                        update(() => extractable = value == true),
                  ),
                  if (extractable)
                    _sessionMaterialNumber(
                      key: const ValueKey('session-material-grade'),
                      label: t('Grado del materiale', 'Material grade'),
                      value: grade,
                      onSaved: (value) => grade = value,
                    ),
                ],
              ),
            ),
          ),
          actions: [
            if (material != null)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(t('Svuota', 'Clear')),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (!form.currentState!.validate()) return;
                form.currentState!.save();
                result = _SessionMaterialSlot(
                  name: name,
                  check: check,
                  difficulty: difficulty,
                  extractionGrade: extractable ? grade : null,
                );
                Navigator.pop(dialogContext, true);
              },
              child: Text(t('Salva', 'Save')),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      _editSessionMaterial(scope, (plan) => plan.materials[index] = result);
    }
  }

  Widget _sessionMaterialNumber({
    required Key key,
    required String label,
    required int value,
    required ValueChanged<int> onSaved,
  }) => TextFormField(
    key: key,
    initialValue: '$value',
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label),
    validator: (text) => (int.tryParse(text?.trim() ?? '') ?? -1) < 0
        ? t(
            'Inserisci un intero da zero in su.',
            'Enter a non-negative integer.',
          )
        : null,
    onSaved: (text) => onSaved(int.parse(text!.trim())),
  );

  Future<void> _editSessionBattle(
    _SessionMaterialScope scope, [
    _SessionBattleDraft? draft,
  ]) async {
    if (_sessionMaterialScope != scope) return;
    final candidates = [
      for (final i in masterInitiativeAddableLocalSheetIndexes())
        (
          tag: sheetTagAt(i),
          name: nomeSchedaPersonaggio(i),
          type: tipoSchedaPersonaggio(i),
        ),
    ];
    final available = candidates.map((item) => item.tag).toSet();
    final selected = (draft?.participantTags ?? <String>{}).intersection(
      available,
    );
    final form = GlobalKey<FormState>();
    var name = draft?.name ?? '';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(t('Prepara battaglia', 'Prepare battle')),
          scrollable: true,
          content: SizedBox(
            width: 380,
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: const ValueKey('session-material-battle-name'),
                    initialValue: name,
                    maxLength: 120,
                    decoration: InputDecoration(
                      labelText: t('Nome battaglia', 'Battle name'),
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? t('Inserisci un nome.', 'Enter a name.')
                        : null,
                    onSaved: (value) => name = value!.trim(),
                  ),
                  if (candidates.isEmpty)
                    Text(
                      t('Nessuna scheda disponibile.', 'No sheets available.'),
                    )
                  else
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        itemCount: candidates.length,
                        itemBuilder: (context, index) {
                          final sheet = candidates[index];
                          return CheckboxListTile(
                            key: ValueKey(
                              'session-material-participant-${sheet.tag}',
                            ),
                            value: selected.contains(sheet.tag),
                            title: Text(sheet.name),
                            subtitle: Text('${sheet.type} · ${sheet.tag}'),
                            onChanged: (value) => update(() {
                              if (value == true) {
                                selected.add(sheet.tag);
                              } else {
                                selected.remove(sheet.tag);
                              }
                            }),
                          );
                        },
                      ),
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
              onPressed: selected.isEmpty
                  ? null
                  : () {
                      if (!form.currentState!.validate()) return;
                      form.currentState!.save();
                      Navigator.pop(dialogContext, true);
                    },
              child: Text(t('Salva bozza', 'Save draft')),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final id =
        draft?.id ?? 'session_battle_${DateTime.now().microsecondsSinceEpoch}';
    _editSessionMaterial(scope, (plan) {
      if (plan.battles[id]?.startedEncounterId != null) return;
      plan.battles[id] = _SessionBattleDraft(
        id: id,
        name: name,
        participantTags: Set.of(selected),
      );
    });
  }

  void _activateSessionBattle(_SessionMaterialScope scope, String id) {
    if (_sessionMaterialScope != scope) return;
    final draft = sessionMaterialsByMaster[scope.master]?.battles[id];
    if (draft == null || draft.startedEncounterId != null) return;
    final indexes = <String, int>{
      for (final index in masterInitiativeAddableLocalSheetIndexes())
        sheetTagAt(index): index,
    };
    if (!draft.participantTags.every(indexes.containsKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Una scheda della bozza non è più disponibile. Aggiorna i partecipanti.',
              'A sheet in the draft is no longer available. Update its participants.',
            ),
          ),
        ),
      );
      return;
    }
    setState(() {
      addMasterInitiativeGroup();
      final encounterId = selectedMasterInitiativeGroupId;
      final group = masterInitiativeGroups.firstWhere(
        (g) => g['id'] == encounterId,
      );
      group['name'] = draft.name;
      // Build the whole roster before normal fight start publishes it.
      for (final tag in draft.participantTags) {
        final index = indexes[tag]!;
        final base = sheetRollBonusAt(index, 'iniziativa');
        updateMasterInitiativeToken(
          index: index,
          roll: 0,
          base: base,
          total: base,
        );
        schedePersonaggio[index]['inMasterParty'] = true;
      }
      startEncounterFight(encounterId);
      draft.startedEncounterId = encounterId;
    });
    for (final tag in draft.participantTags) {
      sendRealtimeMasterVisibleTokenAt(indexes[tag]!);
    }
  }
}
