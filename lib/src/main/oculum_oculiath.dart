part of '../../main.dart';

final _oculiathGrabInProgress = Expando<bool>();

class _OculiathRay {
  _OculiathRay(this.entry, Map effect)
    : rule = '${effect['target']}',
      range = readIntValue(effect['valueExpression']),
      reduction = readIntValue(effect['duration']).clamp(0, 100);

  final Map<String, dynamic> entry;
  final String rule;
  final int range, reduction;
  bool get aculotide => rule == oculumAculotideCoronaEffect;
  bool get frutibush => rule == oculumFrutibushLeafSkill;
  bool get greater => rule == oculumGreaterOculiathRayRule;
  int get count => frutibush
      ? range.clamp(1, oculumFrutibushLeafCaps.last)
      : aculotide
      ? oculumAculotideSpineCount
      : greater
      ? 1 + oculumOculiathSecondaryRayCount
      : 1;
}

extension _OculumOculiathRuntime on _OculumHomePageState {
  Map? oculiathHoldFor(Map<String, dynamic> token) {
    final hold = token['oculiathHold'];
    if (hold is! Map ||
        hold['scope'] != permissionScope ||
        hold['fight'] != selectedMasterInitiativeGroupId ||
        hold['campaign'] != permissionCampaignId) {
      return null;
    }
    return hold;
  }

  Map<String, dynamic>? oculiathCarrierHolding(String target) =>
      _writableOnlineCombatTokens().where((token) {
        return oculiathHoldFor(token)?['targetTag'] == target;
      }).firstOrNull;

  int oculiathCurrentWillAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return 0;
    if (index == schedaCorrente) return max(0, currentVolonta());
    final sheet = schedePersonaggio[index];
    return max(0, readIntValue(sheet['currentVolonta'] ?? sheet['volonta']));
  }

  bool get _canManageOculiathHold =>
      _usesLocalMasterInitiative &&
      encounterFightStarted(onlineCombatEncounterId) &&
      !vttShowingRemoteScene;

  bool get _oculiathHookIntact =>
      oculumOculiathPartIntact(anatomicalPartState['parts'], 'hook');

  List<int> get oculiathWorkingEyes =>
      oculumGreaterOculiathWorkingEyes(anatomicalPartState['parts']);

  Iterable<Map<String, dynamic>> _oculiathGrabTargets(
    Map<String, dynamic> carrier,
  ) => _writableOnlineCombatTokens().where((token) {
    final tag = onlineCombatTokenTag(token);
    return tag.isNotEmpty &&
        tag != onlineCombatTokenTag(carrier) &&
        token['outsideFight'] != true &&
        !masterInitiativeTokenIsDead(token) &&
        controlsOnlineCombatSheet(tag) &&
        oculiathCarrierHolding(tag) == null &&
        oculiathHoldFor(token) == null &&
        localMapTokenForInitiativeToken(token) != null &&
        oculumOculiathCanGrab(
          monsterId: faunaCurrentMonsterId,
          carrierCurrentWill: oculiathCurrentWillAt(schedaCorrente),
          targetCurrentWill: oculiathCurrentWillAt(
            localSheetIndexForOculumTag(tag),
          ),
          inContact: true,
          hookIntact: _oculiathHookIntact,
          hasPassenger: oculiathHoldFor(carrier) != null,
        );
  });

  Future<void> selectOculiathGrab() async {
    if (!_canManageOculiathHold || _oculiathGrabInProgress[this] == true) {
      return;
    }
    final origin = sheetTagAt(schedaCorrente);
    final carrier = escapeToken(origin);
    if (carrier == null ||
        !controlsOnlineCombatSheet(origin) ||
        !masterInitiativeTokenCanAct(carrier) ||
        carrier['outsideFight'] == true ||
        oculiathCarrierHolding(origin) != null ||
        localMapTokenForInitiativeToken(carrier) == null) {
      return;
    }
    final fight = onlineCombatEncounterId;
    final scope = permissionScope;
    final scene = activeVttScene.id;
    final candidates = _oculiathGrabTargets(carrier).toList();
    if (candidates.isEmpty) {
      aggiungiLog(
        t(
          'Nessun bersaglio idoneo sulla mappa.',
          'No eligible target on the map.',
        ),
      );
      return;
    }
    _oculiathGrabInProgress[this] = true;
    try {
      final selected = await showDialog<(String, String)>(
        context: context,
        builder: (dialog) => SimpleDialog(
          title: Text(t('Afferra con l’uncino', 'Grab with hook')),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                t(
                  'Con questa scelta confermi che il bersaglio è a contatto. La presa in volo richiede le due pedine sulla mappa.',
                  'Your choice confirms that the target is in contact. A flying hold requires both tokens on the map.',
                ),
              ),
            ),
            for (final token in candidates)
              for (final (key, label) in [
                ('azione', t('Azione', 'Action')),
                ('reazione', t('Reazione', 'Reaction')),
              ])
                SimpleDialogOption(
                  onPressed: () =>
                      Navigator.pop(dialog, (onlineCombatTokenTag(token), key)),
                  child: Text(
                    '${oculumReferenceEncounterTokenName(token)} · $label',
                  ),
                ),
          ],
        ),
      );
      if (selected == null ||
          !mounted ||
          origin != sheetTagAt(schedaCorrente) ||
          scope != permissionScope ||
          fight != onlineCombatEncounterId ||
          scene != activeVttScene.id ||
          !identical(escapeToken(origin), carrier)) {
        return;
      }
      final (tag, resource) = selected;
      final target = _oculiathGrabTargets(
        carrier,
      ).where((token) => onlineCombatTokenTag(token) == tag).firstOrNull;
      final sourceMap = localMapTokenForInitiativeToken(carrier);
      final targetMap = target == null
          ? null
          : localMapTokenForInitiativeToken(target);
      if (sourceMap == null ||
          targetMap == null ||
          identical(sourceMap, targetMap)) {
        return;
      }
      final surface = readDoubleValue(targetMap['elevationMeters']);
      if (!surface.isFinite ||
          !await requestUtilitySpend(resource, preferFreeReaction: false) ||
          !mounted ||
          origin != sheetTagAt(schedaCorrente) ||
          scope != permissionScope ||
          fight != onlineCombatEncounterId ||
          scene != activeVttScene.id) {
        return;
      }
      final id =
          'oculiath:$origin:$tag:${DateTime.now().microsecondsSinceEpoch}';
      var applied = false;
      faunaForOwnedSheet(tag, () {
        applied = applyCondition(
          'afferrato',
          durationType: OculumConditionDurationType.permanent,
          removable: false,
          source: 'Uncino dell’Oculiath',
          metadata: {
            'referenceCurseSource': id,
            'oculiathFight': fight,
            'oculiathCampaign': permissionCampaignId,
          },
        );
      });
      if (applied) {
        carrier['oculiathHold'] = {
          'id': id,
          'targetTag': tag,
          'fight': fight,
          'scope': scope,
          'surface': surface,
          'scene': scene,
          'campaign': permissionCampaignId,
        };
        final liveSourceMap = localMapTokenForInitiativeToken(carrier);
        if (liveSourceMap != null) syncOculiathPassenger(liveSourceMap);
        notifyVttCanvasChanged(save: true, publish: true);
        captureActiveMasterInitiativeGroup();
        sendRealtimeInitiativeSnapshotIfPublished();
        programmaSalvataggio();
      }
      await flushPendingCombatTurnResources();
    } finally {
      _oculiathGrabInProgress[this] = false;
    }
  }

  bool isOculiathHeldMapToken(Map<String, dynamic> mapToken) {
    final token = initiativeTokenForLocalMapToken(mapToken);
    final carrier = token == null
        ? null
        : oculiathCarrierHolding(onlineCombatTokenTag(token));
    return carrier != null &&
        oculiathHoldFor(carrier)?['scene'] == activeVttScene.id;
  }

  void expireOculiathHolds(String fight, {String? campaignId}) {
    if (fight.isEmpty) return;
    final campaign = campaignId ?? permissionCampaignId;
    for (final token in masterInitiativeTokens) {
      final hold = token['oculiathHold'];
      if (hold is Map &&
          hold['fight'] == fight &&
          hold['campaign'] == campaign) {
        token.remove('oculiathHold');
      }
    }
    bool matches(Map metadata) =>
        metadata['oculiathFight'] == fight &&
        metadata['oculiathCampaign'] == campaign;
    for (var index = 0; index < schedePersonaggio.length; index++) {
      final sheet = schedePersonaggio[index];
      if (sheet['realtimeSharedSheet'] == true) continue;
      if (index == schedaCorrente) {
        activeConditions.removeWhere(
          (condition) =>
              condition.conditionType == 'afferrato' &&
              matches(condition.metadata),
        );
        continue;
      }
      final conditions = sheet['conditions'] ?? sheet['activeConditions'];
      if (conditions is! List) continue;
      final remaining = conditions
          .where(
            (condition) =>
                !(condition is Map &&
                    condition['conditionType'] == 'afferrato' &&
                    condition['metadata'] is Map &&
                    matches(condition['metadata'] as Map)),
          )
          .toList();
      if (remaining.length != conditions.length) {
        sheet['conditions'] = remaining;
      }
    }
    invalidateDerivedDataCaches(notifyHiddenEyeCards: false);
  }

  bool syncOculiathPassenger(Map<String, dynamic> sourceMap) {
    if (!_canManageOculiathHold) return false;
    final carrier = initiativeTokenForLocalMapToken(sourceMap);
    final hold = carrier == null ? null : oculiathHoldFor(carrier);
    if (hold == null || hold['scene'] != activeVttScene.id) return false;
    final target = escapeToken('${hold['targetTag']}');
    final targetMap = target == null
        ? null
        : localMapTokenForInitiativeToken(target);
    if (targetMap == null || identical(sourceMap, targetMap)) return false;
    targetMap['x'] = localMapTokenAxis(sourceMap, 'x');
    targetMap['y'] = localMapTokenAxis(sourceMap, 'y');
    targetMap['elevationMeters'] = readDoubleValue(
      sourceMap['elevationMeters'],
    );
    hold['lastElevation'] = targetMap['elevationMeters'];
    return true;
  }

  Iterable<Widget> oculiathHoldControls(
    void Function(VoidCallback) select,
  ) sync* {
    if (!_canManageOculiathHold) return;
    final tag = sheetTagAt(schedaCorrente);
    final carrier = escapeToken(tag);
    if (carrier != null && oculumOculiathHasHook(faunaCurrentMonsterId)) {
      final hold = oculiathHoldFor(carrier);
      yield ListTile(
        leading: const Icon(Icons.pan_tool_alt_outlined),
        title: Text(
          hold == null
              ? t('Afferra con l’uncino', 'Grab with hook')
              : t('Rilascia il bersaglio', 'Release target'),
        ),
        enabled:
            hold != null ||
            (_oculiathHookIntact && oculiathCarrierHolding(tag) == null),
        onTap: () => select(
          () => unawaited(
            hold == null
                ? selectOculiathGrab()
                : releaseOculiathHold(
                    carrier,
                    reason: 'L’Oculiath rilascia la presa.',
                  ),
          ),
        ),
      );
    }
    if (oculiathCarrierHolding(tag) == null) return;
    yield ListTile(
      leading: const Icon(Icons.link_off),
      title: Text(t('Liberati dall’uncino', 'Break free from hook')),
      onTap: () => select(() => unawaited(_showOculiathEscape())),
    );
  }

  Future<void> _showOculiathEscape() async {
    final tag = sheetTagAt(schedaCorrente);
    final choice = await showDialog<(String, String)>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text(t('Prova di liberazione', 'Break-free check')),
        children: [
          for (final (trait, label) in [
            ('forza', t('Forza', 'Strength')),
            ('controllo_corporeo', t('Controllo corporeo', 'Body control')),
          ])
            for (final (resource, cost) in [
              ('azione', t('Azione', 'Action')),
              ('reazione', t('Reazione', 'Reaction')),
            ])
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialog, (trait, resource)),
                child: Text('$label · $cost'),
              ),
        ],
      ),
    );
    if (choice != null && mounted && tag == sheetTagAt(schedaCorrente)) {
      await tryOculiathEscape(choice.$1, choice.$2);
      await flushPendingCombatTurnResources();
    }
  }

  _OculiathRay? get pendingOculiathRay {
    final entry = activeStructuredEffects.where((entry) {
      final effect = entry['effect'];
      return entry['type'] == 'pending_target' &&
          effect is Map &&
          effect['type'] == 'planar' &&
          const {
            oculumOculiathRayRule,
            oculumGreaterOculiathRayRule,
            oculumAculotideCoronaEffect,
            oculumFrutibushLeafSkill,
          }.contains(effect['target']);
    }).lastOrNull;
    return entry == null ? null : _OculiathRay(entry, entry['effect'] as Map);
  }

  ({double dx, double dy, double dz})? _oculiathMapDistance(
    String sourceTag,
    Map<String, dynamic> targetToken,
  ) {
    final sourceToken = onlineCombatTokens()
        .where((token) => combatTokenMatchesSheet(token, sourceTag))
        .firstOrNull;
    if (sourceToken == null) return null;
    final scene = vttSceneForDisplay();
    Map<String, dynamic>? mapToken(Map<String, dynamic> token) {
      if (!vttShowingRemoteScene) return localMapTokenForInitiativeToken(token);
      final id = '${token['mapTokenId'] ?? ''}'.trim();
      if (id.isNotEmpty) {
        final exact = scene.tokens
            .where((part) => part['id'] == id)
            .firstOrNull;
        if (exact != null) return exact;
      }
      final tag = onlineCombatTokenTag(token);
      if (tag.isEmpty) return null;
      return scene.tokens
          .where(
            (part) =>
                oculumSameSheetIdentity(part['sheetTag'], tag) ||
                oculumSameSheetIdentity(part['ownerTag'], tag),
          )
          .firstOrNull;
    }

    final source = mapToken(sourceToken);
    final target = mapToken(targetToken);
    if (source == null || target == null || identical(source, target)) {
      return null;
    }
    final width = vttShowingRemoteScene
        ? scene.widthMeters
        : mapWidthMetersValue();
    final height = vttShowingRemoteScene
        ? scene.heightMeters
        : mapHeightMetersValue();
    return (
      dx:
          (localMapTokenAxis(source, 'x') - localMapTokenAxis(target, 'x')) *
          width,
      dy:
          (localMapTokenAxis(source, 'y') - localMapTokenAxis(target, 'y')) *
          height,
      dz:
          readDoubleValue(source['elevationMeters']) -
          readDoubleValue(target['elevationMeters']),
    );
  }

  bool? oculiathMapTargetInRange(
    _OculiathRay ray,
    String sourceTag,
    Map<String, dynamic> token,
  ) {
    if (ray.aculotide || ray.frutibush) return true;
    final metres = _oculiathMapDistance(sourceTag, token);
    if (metres == null) return null;
    return oculumOculiathWithinRange(
      dxMeters: metres.dx,
      dyMeters: metres.dy,
      dzMeters: metres.dz,
      range: ray.range,
    );
  }

  bool oculiathLiveTargetsInRange(
    _OculiathRay ray,
    String source,
    Iterable<String> targets,
  ) {
    final live = {
      for (final token in onlineCombatTokens())
        onlineCombatTokenTag(token): token,
    };
    final sourceTeam = ray.frutibush ? combatScoutSide(source) : '';
    return targets.every((target) {
      final token = live[target];
      return token != null &&
          masterInitiativeTokenCanAct(token) &&
          !escapeTokenIsOut(target) &&
          (!ray.frutibush || _attackTokenIsOpponent(token, sourceTeam)) &&
          oculiathMapTargetInRange(ray, source, token) != false;
    });
  }

  bool oculiathMayDispatchRay(Map<String, dynamic> packet) {
    final target = '${packet['targetTag'] ?? ''}';
    final token = onlineCombatTokens()
        .where((token) => onlineCombatTokenTag(token) == target)
        .firstOrNull;
    if (token == null ||
        !masterInitiativeTokenCanAct(token) ||
        escapeTokenIsOut(target)) {
      return false;
    }
    if (packet['aculotideSpine'] == true) return true;
    if (packet['frutibushLeaf'] == true) {
      return _attackTokenIsOpponent(
        token,
        combatScoutSide('${packet['sourceTag']}'),
      );
    }
    final eye = readIntValue(packet['oculiathEye']);
    if (eye > 0) {
      final source = localSheetIndexForOculumTag('${packet['sourceTag']}');
      if (source >= 0) {
        final runtime = schedePersonaggio[source]['planarRuntime'];
        final anatomy = source == schedaCorrente
            ? anatomicalPartState
            : runtime is Map
            ? runtime['anatomicalParts']
            : null;
        if (anatomy is Map &&
            !oculumOculiathPartIntact(anatomy['parts'], 'eyes_$eye')) {
          return false;
        }
      }
    }
    final metres = _oculiathMapDistance('${packet['sourceTag']}', token);
    return metres == null ||
        oculumOculiathWithinRange(
          dxMeters: metres.dx,
          dyMeters: metres.dy,
          dzMeters: metres.dz,
          range: readIntValue(packet['oculiathRange']),
        );
  }

  Future<List<String>?> planOculiathRayTargets(
    _OculiathRay ray,
    List<String> targets,
    Map<String, Map<String, dynamic>> byId, {
    required int rayCount,
    bool hasPrimary = true,
  }) async {
    if (targets.isEmpty) return null;
    if (ray.frutibush) {
      if (targets.length > rayCount) return null;
      final leafCount = targets.length == rayCount
          ? rayCount
          : await showDialog<int>(
              context: context,
              builder: (dialog) => SimpleDialog(
                title: const Text('Quante foglie vuoi lanciare?'),
                children: [
                  for (var count = targets.length; count <= rayCount; count++)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(dialog, count),
                      child: Text(count == 1 ? '1 foglia' : '$count foglie'),
                    ),
                ],
              ),
            );
      if (leafCount == null || !mounted) return null;
      return selectSenkaMoonCuts(targets, byId, leafCount, hitLabel: 'foglie');
    }
    if (ray.aculotide) {
      return selectSenkaMoonCuts(targets, byId, rayCount, hitLabel: 'spine');
    }
    final source = sheetTagAt(schedaCorrente);
    final unmapped = <String>[];
    for (final target in targets) {
      final token = byId[target];
      if (token == null) return null;
      final eligible = oculiathMapTargetInRange(ray, source, token);
      if (eligible == false) return null;
      if (eligible == null) unmapped.add('${token['name'] ?? target}');
    }
    if (!await confirmOculiathUnmappedRange(ray, unmapped) || !mounted) {
      return null;
    }
    final secondaryCount = rayCount - (hasPrimary ? 1 : 0);
    final secondary = secondaryCount > 0
        ? await selectSenkaMoonCuts(
            targets,
            byId,
            secondaryCount,
            hitLabel: 'raggi secondari',
            allowNoHitsOnFirst: hasPrimary,
          )
        : const <String>[];
    return secondary == null
        ? null
        : [if (hasPrimary) targets.first, ...secondary];
  }

  Future<bool> confirmOculiathUnmappedRange(
    _OculiathRay ray,
    List<String> names,
  ) async {
    if (names.isEmpty) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        scrollable: true,
        title: const Text('Conferma la gittata del raggio'),
        content: Text(
          'La mappa non misura la distanza di ${names.join(', ')}. '
          'Conferma con il Master che ogni bersaglio sia entro ${ray.range} m.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Conferma la distanza'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}
