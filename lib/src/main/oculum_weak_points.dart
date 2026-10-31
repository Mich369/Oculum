part of '../../main.dart';

bool oculumPrecisionMayChooseBodyPart(int precision) => precision >= 3;

// ignore_for_file: invalid_use_of_protected_member

List<({String label, int penalty})> oculumArtWeakPoints(
  Iterable<CharacterArt> arts,
) => [
  for (final art in arts.where((a) => a.sbloccata && a.inUso))
    ...switch (oculumRecognizedArtKind(art)) {
      'defiled' || 'null' => <({String label, int penalty})>[],
      'martial' => [
        (
          label: '${art.nome}: piccola sfera nei legamenti · Precisione −2',
          penalty: 2,
        ),
      ],
      'emblem' => [
        (
          label:
              '${art.nome}: ${art.weakPointLocation.trim().isEmpty ? 'parte del corpo su cui è posto l’emblema' : art.weakPointLocation.trim()}',
          penalty: 0,
        ),
      ],
      'illness' => [(label: '${art.nome}: testa', penalty: 0)],
      'rune' => [(label: '${art.nome}: basso ventre', penalty: 0)],
      _ => [(label: '${art.nome}: occhi', penalty: 0)],
    },
];

List<Map<String, dynamic>> oculumPrecisionBodyParts({
  MonsterBookEntry? monster,
  Iterable<CharacterArt> arts = const [],
  String description = '',
  bool solarFaceUncovered = false,
}) {
  if (monster != null) {
    return oculumMonsterPrecisionAnatomy(
      monster,
      solarFaceUncovered: solarFaceUncovered,
    );
  }
  final result = <String, Map<String, dynamic>>{};
  final body = oculumNormalizeText(monster?.descIt ?? description);
  final weak = oculumNormalizeText(monster?.weakPointDescriptionIt ?? '');
  const definitions = [
    ('body', 'Corpo', r'corpo|massa'),
    ('head', 'Testa', r'testa|cranio|teschio'),
    ('eyes', 'Occhi', r'occhi|occhio'),
    ('torso', 'Torace', r'petto|torace|corazza'),
    ('belly', 'Ventre', r'pancia|ventre|addome'),
    ('arms', 'Braccia', r'braccia|braccio'),
    ('legs', 'Gambe', r'gambe|zampe|ginocchia'),
    ('wings', 'Ali', r'\bali\b|alato|piume'),
    ('tail', 'Coda', r'\bcoda\b'),
    ('core', 'Nucleo', r'nucleo|core'),
    ('mask', 'Maschera', r'maschera'),
    ('horns', 'Corna', r'corna|corni'),
  ];
  for (final d in definitions) {
    if (d.$1 != 'body' && monster != null && !RegExp(d.$3).hasMatch(body)) {
      continue;
    }
    if (monster == null &&
        const {'core', 'tail', 'wings', 'mask', 'horns'}.contains(d.$1) &&
        !RegExp(d.$3).hasMatch(body)) {
      continue;
    }
    result[d.$1] = {
      'id': d.$1,
      'label': d.$2,
      'penalty': 0,
      'weak': monster != null && d.$1 != 'body' && RegExp(d.$3).hasMatch(weak),
    };
  }
  if (monster == null) {
    for (final art in arts.where((a) => a.sbloccata && a.inUso)) {
      final kind = oculumRecognizedArtKind(art);
      final (part, label, penalty) = switch (kind) {
        'martial' => ('ligaments', 'Legamenti · piccola sfera', 2),
        'emblem' => (
          'emblem',
          art.weakPointLocation.trim().isEmpty
              ? 'Emblema'
              : art.weakPointLocation.trim(),
          0,
        ),
        'illness' => ('head', 'Testa', 0),
        'rune' => ('belly', 'Basso ventre', 0),
        'oculum' => ('eyes', 'Occhi', 0),
        _ => ('', '', 0),
      };
      if (part.isEmpty) continue;
      result[part] = {
        'id': part,
        'label': label,
        'penalty': penalty,
        'weak': true,
        'artKind': kind,
      };
    }
  }
  return result.values.toList();
}

bool oculumSolarFaceUncovered(Map runtime) =>
    runtime['solarFaceUncovered'] is bool
    ? runtime['solarFaceUncovered'] == true
    : const {'lusier_iii', 'erik_i'}.contains(runtime['canonicalNpc']);

extension _OculumWeakPoints on _OculumHomePageState {
  bool get solarFaceUncovered => oculumSolarFaceUncovered(planarState);
  bool combatTokenHasAccessibleAnatomicalWeakPoint(Map<String, dynamic> token) {
    final id = monsterBookIdForCombatToken(token);
    if (!oculumMonsterHasAnatomicalWeakPoint(monsterBookEntryById(id))) {
      return false;
    }
    // Knowing a purchased page does not open the Guardian's intact chest.
    return !(oculumLunarGuardianCoreMonsterIds.contains(id) ||
            const {'costrutto_minore', 'nuvola_in_bottiglia'}.contains(id)) ||
        precisionPartsForToken(token).any((part) => part['weak'] == true);
  }

  Future<void> applyFateCoreReflection(Map<String, dynamic> request) async {
    final source = '${request['sourceTag']}';
    if (!controlsOnlineCombatSheet(source) ||
        !faunaReceipt('fate-core:${request['id']}')) {
      return;
    }
    final damage = max(0, readIntValue(request['damage']));
    combatLogFor(
      source,
      '[NUCLEO CON FATA] ${request['targetName']}: $damage Danni tornano a te, senza tiro contrapposto. Azione/Reazione consumata.',
    );
    await applyRunicReflectedDamage(
      source,
      damage,
      element: '${request['element'] ?? 'fisico'}',
      source: 'Nucleo con fata',
    );
  }

  List<Map<String, dynamic>>
  get currentPrecisionBodyParts => oculumArmadilloPrecisionParts(
    oculumReferenceCreaturePrecisionParts(
      oculumLunarGuardianCorePrecisionParts(
        oculumPrecisionBodyParts(
              monster: monsterBookEntryById(faunaCurrentMonsterId),
              solarFaceUncovered: solarFaceUncovered,
              arts: arti,
              description:
                  '${schedePersonaggio.isEmpty ? '' : schedePersonaggio[schedaCorrente]['razza'] ?? ''} ${backgroundController.text}',
            )
            .followedBy(
              isConstructCharacter
                  ? [
                      {
                        'id': 'core',
                        'label': 'Nucleo del Costrutto',
                        'penalty': 0,
                        'weak': true,
                      },
                    ].where(
                      (p) => !oculumPrecisionBodyParts(
                        monster: monsterBookEntryById(faunaCurrentMonsterId),
                        arts: arti,
                      ).any((part) => part['id'] == 'core'),
                    )
                  : <Map<String, dynamic>>[],
            )
            .where(
              (part) =>
                  !isLunarOrderCreature ||
                  !oculumLunarCrystalIds.contains(part['id']) ||
                  intactLunarCrystalIds.contains(part['id']),
            )
            .toList(),
        monsterId: faunaCurrentMonsterId,
        coreExposed: lunarGuardianCoreExposed,
      ),
      monsterId: faunaCurrentMonsterId,
      minorConstructCoreExposed: minorConstructCoreExposed,
      bottledCloudPhase: bottledCloudPhaseNumber,
      explicitMasterAnatomy: currentHasExplicitMasterAnatomy,
    ),
    closed: armadilloClosed,
  );
  List<Map<String, dynamic>> get publicPrecisionBodyParts => [
    for (final p in currentPrecisionBodyParts)
      {
        'id': p['id'],
        'label': p['label'],
        'penalty': p['penalty'],
        'group': p['group'] ?? p['id'],
        if (p['side'] != null) 'side': p['side'],
        if (p['sideIndex'] != null) 'sideIndex': p['sideIndex'],
      },
  ];
  List<Map<String, dynamic>> precisionPartsForToken(
    Map<String, dynamic> token,
  ) {
    final monster = monsterBookEntryById(monsterBookIdForCombatToken(token));
    final index = localSheetIndexForOculumTag(onlineCombatTokenTag(token));
    if (monster != null) {
      final public = token['faunaPublic'];
      final runtime = index == schedaCorrente
          ? planarState
          : index >= 0
          ? schedePersonaggio[index]['planarRuntime']
          : null;
      final uncovered = public is Map && public['solarFaceUncovered'] is bool
          ? public['solarFaceUncovered'] == true
          : runtime is Map && oculumSolarFaceUncovered(runtime);
      final publicCore = (token['faunaPublic'] as Map?)?['lunarGuardianCore'];
      final savedCore = index < 0
          ? null
          : (schedePersonaggio[index]['planarRuntime']
                as Map?)?['lunarGuardianCore'];
      final exposed = publicCore is Map
          ? publicCore['coreExposed'] == true
          : index == schedaCorrente
          ? lunarGuardianCoreExposed
          : savedCore is Map && savedCore['coreExposed'] == true;
      final minorExposed = index == schedaCorrente
          ? minorConstructCoreExposed
          : public is Map && public['minorConstructCoreExposed'] is bool
          ? public['minorConstructCoreExposed'] == true
          : runtime is Map && oculumMinorConstructBoxBroken(runtime);
      final cloudState = runtime is Map ? runtime['bottledCloud'] : null;
      final cloudPhase = index == schedaCorrente
          ? bottledCloudPhaseNumber
          : public is Map && public['bottledCloudPhase'] is num
          ? readIntValue(public['bottledCloudPhase'], fallback: 1)
          : cloudState is Map && cloudState['fight'] == bottledCloudFightKey
          ? readIntValue(cloudState['phase'], fallback: 1)
          : 1;
      final custom = monster.encounterRules['precisionBodyParts'];
      final publicArmadillo = public is Map ? public['armadillo'] : null;
      final savedArmadillo = runtime is Map ? runtime['armadillo'] : null;
      final targetArmadilloClosed = index == schedaCorrente
          ? armadilloClosed
          : oculumArmadilloSpeciesIds.contains(monster.id) &&
                oculumArmadilloStateIsClosed(
                  publicArmadillo is Map
                      ? publicArmadillo
                      : savedArmadillo is Map
                      ? savedArmadillo
                      : const {},
                  fightKey:
                      '$onlineCombatEncounterId:${token['fightInstanceId'] ?? ''}',
                  currentHp: readIntValue(token['currentHp'], fallback: 1),
                );
      return oculumArmadilloPrecisionParts(
        oculumReferenceCreaturePrecisionParts(
          oculumLunarGuardianCorePrecisionParts(
            oculumPrecisionBodyParts(
              monster: monster,
              solarFaceUncovered: uncovered,
            ),
            monsterId: monster.id,
            coreExposed: exposed,
          ),
          monsterId: monster.id,
          minorConstructCoreExposed: minorExposed,
          bottledCloudPhase: cloudPhase,
          explicitMasterAnatomy: custom is List && custom.isNotEmpty,
        ),
        closed: targetArmadilloClosed,
      );
    }
    final raw = index >= 0
        ? schedaJsonAt(index)['precisionBodyParts']
        : token['precisionBodyParts'];
    return (raw as List? ?? [])
        .whereType<Map>()
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
  }

  Future<Map<String, dynamic>?> selectPrecisionBodyPart(
    Map<String, dynamic> token, {
    bool weakOnly = false,
  }) async {
    if (weakOnly && !combatTokenHasAccessibleAnatomicalWeakPoint(token)) {
      return null;
    }
    final known = combatTokenWeakPointKnown(token);
    final parts = oculumMonsterPrecisionChoices(
      precisionPartsForToken(token),
      monster: monsterBookEntryById(monsterBookIdForCombatToken(token)),
      weakPointDiscovered: known,
    );
    final knownIds =
        (discoveredCombatTarget(onlineCombatTokenTag(token))?['knownBodyParts']
                    as List? ??
                [])
            .map((p) => '$p')
            .toSet();
    final available = weakOnly && monsterBookIdForCombatToken(token).isNotEmpty
        ? parts.where((p) => p['weak'] == true).toList()
        : parts;
    if (available.isEmpty) {
      return weakOnly && known
          ? {'id': 'known', 'label': 'Punto debole scoperto', 'penalty': 0}
          : {'id': 'body', 'label': 'Corpo', 'penalty': 0};
    }
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final point in available) {
      (groups['${point['group'] ?? point['id']}'] ??= []).add(point);
    }
    const names = {
      'arms': 'Braccia',
      'legs': 'Gambe / zampe',
      'wings': 'Ali',
      'tail': 'Code',
      'head': 'Teste',
      'eyes': 'Occhi',
    };
    final selected = await showDialog<String>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text('Precisione · ${token['name'] ?? 'bersaglio'}'),
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Scegli una parte del corpo. I punti deboli scoperti sono evidenziati.',
            ),
          ),
          for (final group in groups.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, group.key),
              child: Row(
                children: [
                  Icon(
                    group.value.any(
                          (p) =>
                              knownIds.contains(p['id']) ||
                              known && p['weak'] == true,
                        )
                        ? Icons.gps_fixed
                        : Icons.adjust,
                    color: Theme.of(dialog).colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.value.length > 1
                          ? '${names[group.key] ?? group.value.first['label']} · ${group.value.length}'
                          : '${group.value.single['label']}',
                    ),
                  ),
                  if (group.value.length > 1)
                    const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return null;
    final choices = groups[selected]!;
    if (choices.length == 1) return choices.single;
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text('${names[selected] ?? selected} · scegli quale'),
        children: [
          for (final point in choices)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, point),
              child: Text(
                '${point['side'] == null ? point['label'] : (point['side'] == 'right' ? 'Destra' : 'Sinistra')}${point['side'] == null || choices.length == 2 ? '' : ' ${point['sideIndex']}'}${readIntValue(point['penalty']) > 0 ? ' · −${point['penalty']} al tiro' : ''}',
                style: TextStyle(
                  fontWeight:
                      knownIds.contains(point['id']) ||
                          known && point['weak'] == true
                      ? FontWeight.w700
                      : null,
                  color:
                      knownIds.contains(point['id']) ||
                          known && point['weak'] == true
                      ? Theme.of(dialog).colorScheme.primary
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void resolvePrecisionBodyHit(Map<String, dynamic> request) {
    final part = currentPrecisionBodyParts
        .where((p) => p['id'] == request['targetBodyPart'])
        .firstOrNull;
    if (part == null || part['weak'] != true) return;
    request['targetWeakPointPrecision'] = true;
    request['bodyPointDiscovery'] = {'id': part['id'], 'label': part['label']};
    if (faunaCurrentMonsterId.isNotEmpty) {
      rememberMonsterBookPartyDiscovery(
        faunaCurrentMonsterId,
        seen: true,
        weakPoint: true,
        broadcast: true,
      );
    }
    final kind = '${part['artKind'] ?? ''}';
    if (kind.isNotEmpty) {
      final penalties = Map<String, dynamic>.from(
        planarState['artWeakPointPenalties'] as Map? ?? {},
      );
      penalties[kind] = 3;
      planarState['artWeakPointPenalties'] = penalties;
      aggiungiLog(
        '[PUNTO DEBOLE ART] ${part['label']}: −3 ai tiri della sola Art $kind per una Azione.',
      );
    }
  }

  int artWeakPointRollPenalty(String source) {
    final penalties = planarState['artWeakPointPenalties'] as Map? ?? {};
    for (final art in arti.where((a) => a.sbloccata && a.inUso)) {
      if (source.contains(art.nome) &&
          readIntValue(penalties[oculumRecognizedArtKind(art)]) > 0) {
        return 3;
      }
    }
    return 0;
  }

  int get preparedArtWeakPointPenalty => artWeakPointRollPenalty(
    activeStructuredEffects
        .where(
          (e) => const {
            'pending_target',
            'danno',
            'bonus_tiro',
            'difesa',
          }.contains(e['type']),
        )
        .map((e) => '${e['source'] ?? ''}')
        .join('\n'),
  );
  void markArtWeakPointAction() {
    if ((planarState['artWeakPointPenalties'] as Map? ?? {}).isNotEmpty) {
      planarState['artWeakPointAction'] = true;
    }
  }

  void finishArtWeakPointAction() {
    if (planarState.remove('artWeakPointAction') == true) {
      planarState.remove('artWeakPointPenalties');
    }
  }

  void rememberPrecisionBodyDiscovery(Map<String, dynamic> request) {
    if (!controlsOnlineCombatSheet('${request['sourceTag']}') ||
        request['bodyPointDiscovery'] is! Map) {
      return;
    }
    final point = request['bodyPointDiscovery'] as Map;
    final key = combatDiscoveryKey(
      '${request['targetTag']}',
      combatScoutSide('${request['sourceTag']}'),
    );
    final old = combatDiscoveries[key] ?? <String, dynamic>{};
    final ids = (old['knownBodyParts'] as List? ?? []).map((p) => '$p').toSet()
      ..add('${point['id']}');
    rememberCombatScoutRead(key, {
      ...old,
      'weakPoint': true,
      'knownBodyParts': ids.toList(),
    });
    aggiungiLog(
      '[PRECISIONE] Punto debole scoperto su ${request['targetName']}: ${point['label']}.',
    );
  }

  Future<void> masterDiscoverWeakPoint([String? selectedId]) async {
    if (!canManageAllThemes) return;
    final scope = permissionScope;
    final ids = onlineCombatTokens()
        .map(monsterBookIdForCombatToken)
        .where((id) => id.isNotEmpty)
        .toSet();
    final options = defaultMonsterBookEntries
        .where((m) => ids.isEmpty || ids.contains(m.id))
        .toList();
    final id =
        selectedId ??
        await showDialog<String>(
          context: context,
          builder: (dialog) => SimpleDialog(
            title: const Text('Punto debole scoperto'),
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Tutti gli esemplari della stessa voce. Le varianti restano separate.',
                ),
              ),
              for (final monster in options)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialog, monster.id),
                  child: Text(monster.nameIt),
                ),
            ],
          ),
        );
    if (!mounted ||
        !canManageAllThemes ||
        permissionScope != scope ||
        id == null ||
        monsterBookEntryById(id) == null) {
      return;
    }
    rememberMonsterBookPartyDiscovery(
      id,
      seen: true,
      weakPoint: true,
      broadcast: true,
    );
    aggiungiLog(
      '[MASTER] Punto debole scoperto: ${monsterBookEntryById(id)!.nameIt}. Vale per la stessa voce, senza sbloccare le varianti.',
    );
    programmaSalvataggio();
    setState(() {});
  }

  Widget sheetWeakPointSummary() {
    final monster = monsterBookEntryById(faunaCurrentMonsterId);
    final points = oculumArtWeakPoints(arti);
    final text =
        monster?.weakPointDescriptionIt ??
        (points.isEmpty
            ? 'Nessun punto debole da Art attiva.'
            : points.map((p) => p.label).join('\n'));
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Punto debole',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          SelectableText(text, style: const TextStyle(fontSize: 12)),
          anatomicalPartsSummary(),
          if (damagedWingIds.isNotEmpty)
            Text(
              'Ali danneggiate: ${damagedWingIds.length} · ${wingsGrounded ? 'volo impossibile' : 'bonus volo dimezzati'}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (canManageAllThemes && damagedWingIds.isNotEmpty)
            TextButton(
              onPressed: () {
                restoreDamagedWings();
                programmaSalvataggio();
                setState(() {});
              },
              child: const Text('Master · Ripristina ali'),
            ),
          if (monster == null)
            for (final art in arti.where(
              (a) =>
                  a.sbloccata &&
                  a.inUso &&
                  oculumRecognizedArtKind(a) == 'emblem',
            ))
              TextButton.icon(
                icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                label: Text('Posizione emblema · ${art.nome}'),
                onPressed: () async {
                  final controller = TextEditingController(
                    text: art.weakPointLocation,
                  );
                  final value = await showDialog<String>(
                    context: context,
                    builder: (dialog) => AlertDialog(
                      title: const Text('Dove si trova l’emblema?'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Es. dorso della mano sinistra',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialog),
                          child: const Text('Annulla'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(dialog, controller.text.trim()),
                          child: const Text('Salva'),
                        ),
                      ],
                    ),
                  );
                  controller.dispose();
                  if (value != null && mounted && arti.contains(art)) {
                    setState(() => art.weakPointLocation = value);
                    programmaSalvataggio();
                  }
                },
              ),
        ],
      ),
    );
  }
}
