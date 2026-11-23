part of '../../main.dart';

const _lamaOrbitaFlight = 'lamaOrbitaFlight';
const _lamaOrbitaCounter = 'lamaOrbitaCounterOf';
const _lamaOrbitaCooldown = 'launchCooldown';
const _lamaOrbitaDefaultCooldown = 5;

int _lamaOrbitaCooldownRemaining(Object? data) {
  final cooldown = data is Map ? data[_lamaOrbitaCooldown] : null;
  return cooldown is Map ? max(0, readIntValue(cooldown['remaining'])) : 0;
}

extension _OculumLamaOrbitaRuntime on _OculumHomePageState {
  Map? _lamaOrbitaData(InventoryItem item) {
    final raw = item.craftData[oculumLamaOrbitaId];
    return raw is Map ? raw : null;
  }

  Map? get _activeLamaOrbitaFlight {
    final raw = planarState[_lamaOrbitaFlight];
    if (raw is! Map) return null;
    final owner = sheetTagAt(schedaCorrente);
    if (raw['scope'] != permissionScope ||
        raw['encounter'] != onlineCombatEncounterId ||
        raw['fight'] != _summonFightKey(owner)) {
      return null;
    }
    return raw;
  }

  bool canLaunchLamaOrbita(InventoryItem item) {
    final data = _lamaOrbitaData(item);
    return data != null &&
        data['lost'] != true &&
        _lamaOrbitaCooldownRemaining(data) == 0 &&
        inventario.contains(item) &&
        item.quantita == 1 &&
        item.equipaggiata &&
        canEquipInventoryItem(item) &&
        currentCombatIsActive() &&
        !outsideFight &&
        hpCorrenti() > 0 &&
        executingCombatCommand == null &&
        _activeLamaOrbitaFlight == null;
  }

  void _writeLamaOrbitaData(InventoryItem item, Map<String, dynamic> data) {
    item.craftData = {...item.craftData, oculumLamaOrbitaId: data};
  }

  int lamaOrbitaCooldownRemaining(InventoryItem item) =>
      _lamaOrbitaCooldownRemaining(_lamaOrbitaData(item));

  int lamaOrbitaCooldownDuration(InventoryItem item) => max(
    0,
    readIntValue(
      _lamaOrbitaData(item)?['cooldownTurns'],
      fallback: _lamaOrbitaDefaultCooldown,
    ),
  );

  void setLamaOrbitaCooldownDuration(InventoryItem item, int turns) {
    final data = _lamaOrbitaData(item);
    if (data == null || !inventario.contains(item)) return;
    _writeLamaOrbitaData(item, {
      ...data.cast<String, dynamic>(),
      'cooldownTurns': max(0, turns),
    });
    programmaSalvataggio();
  }

  void _startLamaOrbitaCooldown(
    InventoryItem item,
    String owner,
    String fight,
  ) {
    final amount = lamaOrbitaCooldownDuration(item);
    if (amount == 0) return;
    final encounter = referenceTurnEncounter();
    final raw = encounter['tokens'];
    final active = readIntValue(encounter['activeIndex']);
    final myTurn =
        raw is List &&
        active >= 0 &&
        active < raw.length &&
        raw[active] is Map &&
        combatTokenMatchesSheet(
          Map<String, dynamic>.from(raw[active] as Map),
          owner,
        );
    _writeLamaOrbitaData(item, {
      ..._lamaOrbitaData(item)!.cast<String, dynamic>(),
      _lamaOrbitaCooldown: {
        'remaining': amount,
        'owner': owner,
        'fight': fight,
        'turn': myTurn ? playerReportedTurn : playerReportedTurn - 1,
      },
    });
  }

  void _advanceLamaOrbitaCooldowns(String owner, int turn) {
    final fight = _summonFightKey(owner);
    var changed = false;
    for (final item in inventario) {
      final data = _lamaOrbitaData(item);
      final remaining = _lamaOrbitaCooldownRemaining(data);
      if (remaining <= 0 || data == null) continue;
      final cooldown = data[_lamaOrbitaCooldown] as Map;
      final elapsed = cooldown['owner'] == owner && cooldown['fight'] == fight
          ? turn - readIntValue(cooldown['turn'], fallback: turn)
          : 1;
      if (elapsed <= 0) continue;
      final next = remaining - elapsed;
      final updated = Map<String, dynamic>.from(data)
        ..remove(_lamaOrbitaCooldown);
      _writeLamaOrbitaData(item, {
        ...updated,
        if (next > 0)
          _lamaOrbitaCooldown: {
            'remaining': next,
            'owner': owner,
            'fight': fight,
            'turn': turn,
          },
      });
      changed = true;
    }
    if (changed) {
      programmaSalvataggio();
      notifyActiveSheetSummaryChanged();
    }
  }

  String _lamaOrbitaPhysicalId(InventoryItem item) {
    final data = _lamaOrbitaData(item)!;
    final existing = '${data['physicalId'] ?? ''}';
    if (existing.isNotEmpty) return existing;
    final id =
        'orbita:${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(1 << 31)}';
    _writeLamaOrbitaData(item, {
      ...data.cast<String, dynamic>(),
      'physicalId': id,
    });
    return id;
  }

  InventoryItem? _findLaunchedLamaOrbita(Map flight) => inventario
      .where(
        (item) =>
            item.quantita == 1 &&
            _lamaOrbitaData(item)?['physicalId'] == flight['physicalId'],
      )
      .singleOrNull;

  bool lamaOrbitaInFlight(InventoryItem item) {
    final flight = _activeLamaOrbitaFlight;
    return flight != null &&
        _lamaOrbitaData(item)?['physicalId'] == flight['physicalId'];
  }

  List<Map<String, dynamic>> _lamaOrbitaAreaTargets(String owner) {
    final side = combatScoutSide(owner);
    final opponents = onlineAttackTokens()
        .where((token) => _attackTokenIsOpponent(token, side))
        .toList();
    final mapped = opponents
        .where((token) => _oculiathMapDistance(owner, token) != null)
        .toList();
    return mapped.isEmpty ? opponents : mapped;
  }

  Future<void> launchLamaOrbita(InventoryItem item) async {
    advanceLamaOrbitaFlight(playerReportedTurn);
    if (!canLaunchLamaOrbita(item) || !requireConfirmedSheetRoll()) return;
    final owner = sheetTagAt(schedaCorrente);
    final scope = permissionScope;
    final campaign = activeCampaignId;
    final fight = _summonFightKey(owner);
    final encounter = onlineCombatEncounterId;
    final scene = vttSceneForDisplay().id;
    final targets = _lamaOrbitaAreaTargets(owner);
    if (targets.isEmpty) return;
    final selectedTargets = targets.map(onlineCombatTokenTag).toSet();
    var element = oculumLamaOrbitaElements.first;
    final resource = await showDialog<String>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text(t('Lancia Lama Orbita', 'Launch Orbit Blade')),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: [
                      for (final id in oculumLamaOrbitaElements)
                        ButtonSegment(
                          value: id,
                          label: Text(elementDisplayName(id)),
                        ),
                    ],
                    selected: {element},
                    onSelectionChanged: (value) =>
                        refresh(() => element = value.single),
                  ),
                  for (final token in targets)
                    CheckboxListTile(
                      dense: true,
                      title: Text(faunaTargetName(token)),
                      value: selectedTargets.contains(
                        onlineCombatTokenTag(token),
                      ),
                      onChanged: (checked) => refresh(() {
                        final tag = onlineCombatTokenTag(token);
                        if (checked == true) {
                          selectedTargets.add(tag);
                        } else {
                          selectedTargets.remove(tag);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(t('Annulla', 'Cancel')),
            ),
            TextButton(
              onPressed: selectedTargets.isEmpty
                  ? null
                  : () => Navigator.pop(dialog, 'reazione'),
              child: Text(t('1 Reazione', '1 Reaction')),
            ),
            FilledButton(
              onPressed: selectedTargets.isEmpty
                  ? null
                  : () => Navigator.pop(dialog, 'azione'),
              child: Text(t('1 Azione', '1 Action')),
            ),
          ],
        ),
      ),
    );
    bool valid() =>
        mounted &&
        sheetTagAt(schedaCorrente) == owner &&
        campaign == activeCampaignId &&
        scope == permissionScope &&
        encounter == onlineCombatEncounterId &&
        fight == _summonFightKey(owner) &&
        scene == vttSceneForDisplay().id &&
        canLaunchLamaOrbita(item) &&
        _lamaOrbitaAreaTargets(
          owner,
        ).map(onlineCombatTokenTag).toSet().containsAll(selectedTargets);
    if (resource == null || !valid()) return;
    final calculation = _captureSheetRollMath(20, vc() + tiroGlobaleBonus());
    final roll = tiraDado(20);
    final review = await _reviewInteractiveSheetRoll(
      label: 'Lancio Lama Orbita',
      natural: roll,
      total: calculation.totalForNatural(roll),
      faces: 20,
      totalForNatural: calculation.totalForNatural,
      reviewFailure: false,
      succeeds: (_, total) => total >= 0,
      canCommit: valid,
    );
    if (review == null || !valid()) return;
    if (!await requestUtilitySpend(
      resource,
      preferFreeReaction: false,
      deferMasterTurn: true,
    )) {
      return;
    }
    if (valid()) {
      final physicalId = _lamaOrbitaPhysicalId(item);
      final affinity = readIntValue(_lamaOrbitaData(item)?['affinity']);
      final natural = review.natural;
      final total = review.total;
      final fumbled = oculumLamaOrbitaFumblesReturn(affinity, natural);
      final percentile = Random.secure().nextInt(100) + 1;
      final loops = fumbled
          ? 1
          : oculumLamaOrbitaRollLoops(affinity, percentile);
      _startLamaOrbitaCooldown(item, owner, fight);
      planarState[_lamaOrbitaFlight] = {
        'id':
            'orbita:${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(1 << 31)}',
        'physicalId': physicalId,
        'scope': scope,
        'campaign': campaign,
        'encounter': encounter,
        'fight': fight,
        'scene': scene,
        'targets': selectedTargets.toList(),
        'firstTurn': playerReportedTurn,
        'dueTurn': playerReportedTurn,
        'natural': natural,
        'attack': total,
        'damage': max(
          0,
          dannoTotale(armaSpecificata: item) +
              oculumLamaOrbitaDamageBonus(affinity),
        ),
        'difficulty': normalizedCampaignDifficulty(),
        'element': element,
        'loops': loops,
        'fumbled': fumbled,
        'orbit': 0,
        'nextTarget': 0,
        'receipts': <String>[],
      };
      registerValidRoll();
      final log = '[LAMA ORBITA] Lancio $total (dado $natural). Giri: $loops.';
      aggiungiLog(log);
      mostraDadoCentrale(
        valore: '$total',
        criticoUno: natural == 1,
        criticoVenti: natural == 20,
      );
      programmaSalvataggio();
      notifyActiveSheetSummaryChanged();
    }
    if (!mounted || sheetTagAt(schedaCorrente) != owner) return;
    await flushPendingCombatTurnResources();
    if (!mounted || sheetTagAt(schedaCorrente) != owner) return;
    advanceLamaOrbitaFlight(playerReportedTurn);
    if (resource == 'azione') advanceMasterInitiativeAfterAction(owner);
  }

  Map<String, dynamic> _lamaOrbitaAttackPacket(
    Map flight,
    Map<String, dynamic> target,
    int orbit, {
    Map<String, dynamic>? incoming,
  }) {
    final launchId = '${flight['id']}';
    final targetTag = onlineCombatTokenTag(target);
    final counter = incoming != null;
    final id = counter
        ? 'orbita:${incoming['id']}'
        : '$launchId:$orbit:${flight['nextTarget']}';
    final damage = readIntValue(flight['damage']);
    return {
      'id': id,
      'attackGroupId': counter ? id : '$launchId:$orbit',
      'scope': flight['scope'],
      'encounterId': flight['encounter'],
      'sourceTag': sheetTagAt(schedaCorrente),
      'sourceName': realtimeDisplayName(),
      'targetTag': targetTag,
      'targetName': faunaTargetName(target),
      'targetFightInstance': target['fightInstanceId'],
      'attack': readIntValue(flight['attack']) - 5 * orbit,
      'damage': damage,
      'damageTotal': damage,
      'difficulty': flight['difficulty'],
      'element': flight['element'],
      'natural': flight['natural'],
      'dieFaces': 20,
      'level': activeCriticalLevel(),
      'grade': activeCriticalGrade(),
      'choice': 'lama_orbita',
      'abilityName': counter ? 'Lama Orbita · Risposta' : 'Lama Orbita',
      'ranged': true,
      'status': 'pending',
      'timestamp': DateTime.now().toIso8601String(),
      'lamaOrbitaLaunchId': launchId,
      'lamaOrbitaPhysicalId': flight['physicalId'],
      'lamaOrbitaOrbit': orbit,
      if (counter) ...{
        _lamaOrbitaCounter: incoming['id'],
        'lamaOrbitaCritical': readIntValue(incoming['natural']) == 1,
      },
    };
  }

  void _sendLamaOrbitaPacket(Map<String, dynamic> packet) {
    final id = '${packet['id']}';
    if (id.length > 160 || onlineCombatRequests.containsKey(id)) return;
    onlineCombatRequests[id] = packet;
    if (packet[_lamaOrbitaCounter] == null) {
      unawaited(sendOnlineCombatRequest(packet));
    }
    receiveLocalCombatAttack(packet);
  }

  bool _lamaOrbitaEligibleMiss(Map request) =>
      request['status'] == 'resolved' &&
      request['outcome'] == OculumAttackOutcome.avoided.name &&
      request['lamaOrbitaLaunchId'] == null &&
      request['kind'] != 'help' &&
      !oculumIsFreeProtectiveImpact(request) &&
      oculumGuardianMeleeAttack(request);

  bool validLamaOrbitaCounter(Map packet) {
    final originalId = '${packet[_lamaOrbitaCounter] ?? ''}';
    final original = onlineCombatRequests[originalId];
    return original != null &&
        controlsOnlineCombatSheet('${packet['sourceTag']}') &&
        controlsOnlineCombatSheet('${packet['targetTag']}') &&
        packet['id'] == 'orbita:$originalId' &&
        packet['scope'] == original['scope'] &&
        packet['encounterId'] == original['encounterId'] &&
        packet['sourceTag'] == original['targetTag'] &&
        packet['targetTag'] == original['sourceTag'] &&
        (packet['lamaOrbitaCritical'] == true) ==
            (readIntValue(original['natural']) == 1) &&
        _lamaOrbitaEligibleMiss(original);
  }

  void triggerLamaOrbitaCounter(Map<String, dynamic> incoming) {
    final flight = _activeLamaOrbitaFlight;
    final owner = sheetTagAt(schedaCorrente);
    if (flight == null ||
        incoming['targetTag'] != owner ||
        !controlsOnlineCombatSheet('${incoming['sourceTag']}') ||
        incoming['scope'] != flight['scope'] ||
        incoming['encounterId'] != flight['encounter'] ||
        !_lamaOrbitaEligibleMiss(incoming) ||
        _friendlyFireFor(incoming).friendly ||
        _findLaunchedLamaOrbita(flight) == null ||
        flight['scene'] != vttSceneForDisplay().id) {
      return;
    }
    final incomingId = '${incoming['id'] ?? ''}';
    final orbit = readIntValue(flight['orbit']);
    if (incomingId.isEmpty ||
        orbit < 0 ||
        orbit >= readIntValue(flight['loops'])) {
      return;
    }
    final target = _lamaOrbitaAreaTargets(owner)
        .where(
          (token) => combatTokenMatchesSheet(token, '${incoming['sourceTag']}'),
        )
        .firstOrNull;
    if (target == null) return;
    final receipts = (flight['receipts'] as List? ?? const [])
        .whereType<String>()
        .toSet();
    if (!receipts.add(incomingId)) return;
    flight['receipts'] = receipts.toList();
    _sendLamaOrbitaPacket(
      _lamaOrbitaAttackPacket(flight, target, orbit, incoming: incoming),
    );
    programmaSalvataggio();
  }

  Future<void> resolveLamaOrbitaAutomaticHit(
    Map<String, dynamic> packet,
  ) async {
    final tag = '${packet['targetTag']}';
    if (!controlsOnlineCombatSheet(tag) ||
        packet['status'] != 'pending' ||
        !validLamaOrbitaCounter(packet)) {
      return;
    }
    final index = localSheetIndexForOculumTag(tag);
    final id = '${packet['id']}';
    if (index < 0 || !onlineCombatResolving.add(id)) return;
    final previous = schedaCorrente;
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    try {
      if (index != previous) {
        schedaCorrente = index;
        caricaStatoDaJson(schedePersonaggio[index]);
        ripristinaImpostazioniGlobali(global);
      }
      await applyResolvedOnlineDefense(packet, 'lama_orbita_passiva', 0);
      if (schedaCorrente == index) salvaSchedaCorrenteInMemoria();
    } finally {
      onlineCombatResolving.remove(id);
      if (index != previous && mounted && schedaCorrente == index) {
        schedaCorrente = previous;
        caricaStatoDaJson(schedePersonaggio[previous]);
        ripristinaImpostazioniGlobali(global);
      }
    }
  }

  void claimLamaOrbitaAttack(Map<String, dynamic> packet) {
    final physicalId = packet['lamaOrbitaPhysicalId'];
    final launchId = packet['lamaOrbitaLaunchId'];
    if (physicalId is! String ||
        launchId is! String ||
        packet['status'] != 'resolved' ||
        packet['scope'] != permissionScope ||
        packet['encounterId'] != onlineCombatEncounterId ||
        packet['damageReceipt'] is! Map ||
        _friendlyFireFor(packet).friendly) {
      return;
    }
    final source = '${packet['sourceTag']}';
    faunaForOwnedSheet(source, () {
      final orbit = readIntValue(packet['lamaOrbitaOrbit']);
      final landed = const {'full', 'reduced'}.contains(packet['outcome']);
      final blade = _findLaunchedLamaOrbita({'physicalId': physicalId});
      if (blade != null && landed && orbit >= 0 && orbit < 5) {
        final data = _lamaOrbitaData(blade)!.cast<String, dynamic>();
        final receipts = (data['creditedOrbits'] as List? ?? const [])
            .whereType<String>()
            .toSet();
        if (receipts.add('$launchId:$orbit')) {
          final affinity = oculumLamaOrbitaAffinityAfterHit(
            readIntValue(data['affinity']),
            1,
          );
          _writeLamaOrbitaData(blade, {
            ...data,
            'affinity': affinity,
            'creditedOrbits': receipts.toList(),
          });
          aggiungiLog('[LAMA ORBITA] Affinità $affinity.');
          programmaSalvataggio();
        }
      }
      final flight = _activeLamaOrbitaFlight;
      if (flight == null ||
          flight['id'] != launchId ||
          flight['pending'] != packet['id']) {
        return;
      }
      final landedAt = _lamaOrbitaMapToken('${packet['targetTag'] ?? ''}');
      if (flight['scene'] == vttSceneForDisplay().id && landedAt != null) {
        flight['dropPoint'] = {
          'x': localMapTokenAxis(landedAt, 'x'),
          'y': localMapTokenAxis(landedAt, 'y'),
        };
      }
      flight.remove('pending');
      if (readIntValue(packet['defenseNatural']) == 20 &&
          packet['outcome'] == OculumAttackOutcome.avoided.name) {
        _returnLamaOrbita(flight, blocked: true);
      } else {
        advanceLamaOrbitaFlight(
          readIntValue(flight['dueTurn'], fallback: playerReportedTurn),
        );
      }
    });
  }

  void _returnLamaOrbita(Map flight, {bool blocked = false}) {
    final blade = _findLaunchedLamaOrbita(flight);
    planarState.remove(_lamaOrbitaFlight);
    if (blade != null && !blocked && flight['fumbled'] == true) {
      _writeLamaOrbitaData(blade, {
        ..._lamaOrbitaData(blade)!.cast<String, dynamic>(),
        'lost': true,
        'drop': {
          'campaign': flight['campaign'] ?? activeCampaignId,
          'scene': flight['scene'],
          if (flight['dropPoint'] case final Map point) ...point,
        },
      });
      blade.equipaggiata = false;
      aggiungiLog('[LAMA ORBITA] La Lama è caduta a terra.');
    } else if (blade != null) {
      aggiungiLog(
        blocked
            ? '[LAMA ORBITA] Una difesa critica interrompe il volo. La Lama rientra.'
            : '[LAMA ORBITA] La Lama rientra.',
      );
    }
    invalidateDerivedDataCaches();
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
  }

  Map<String, dynamic>? _lamaOrbitaMapToken(String tag) {
    if (tag.isEmpty) return null;
    final initiative = onlineCombatTokens()
        .where((token) => combatTokenMatchesSheet(token, tag))
        .firstOrNull;
    if (!vttShowingRemoteScene && initiative != null) {
      final token = localMapTokenForInitiativeToken(initiative);
      if (token != null) return token;
    }
    final mapId = initiative?['mapTokenId'];
    return vttSceneForDisplay().tokens.where((token) {
      return (mapId != null && mapId == token['id']) ||
          oculumSameSheetIdentity(token['sheetTag'], tag) ||
          oculumSameSheetIdentity(token['ownerTag'], tag);
    }).firstOrNull;
  }

  bool? _lamaOrbitaPickupContact(InventoryItem item) {
    final data = _lamaOrbitaData(item);
    if (data?['lost'] != true ||
        !inventario.contains(item) ||
        hpCorrenti() <= 0) {
      return false;
    }
    final drop = data?['drop'];
    if (drop is! Map) return null;
    final scene = vttSceneForDisplay();
    if (drop['campaign'] != activeCampaignId || drop['scene'] != scene.id) {
      return false;
    }
    final actor = _lamaOrbitaMapToken(sheetTagAt(schedaCorrente));
    if (actor == null || drop['x'] is! num || drop['y'] is! num) return null;
    final dx =
        (localMapTokenAxis(actor, 'x') - readDoubleValue(drop['x'])) *
        scene.widthMeters;
    final dy =
        (localMapTokenAxis(actor, 'y') - readDoubleValue(drop['y'])) *
        scene.heightMeters;
    final dz = readDoubleValue(actor['elevationMeters']);
    final reach = scene.distancePerCell > 0 ? scene.distancePerCell : 1.0;
    return dx * dx + dy * dy + dz * dz <= reach * reach;
  }

  bool get _canConfirmLamaOrbitaContact =>
      realtimeService?.isConnected != true ||
      realtimeIsMasterRole ||
      realtimeIsCoMasterRole;

  bool canRecoverLamaOrbita(InventoryItem item) =>
      _lamaOrbitaPickupContact(item) ?? _canConfirmLamaOrbitaContact;

  Future<void> recoverLamaOrbita(InventoryItem item) async {
    if (!canRecoverLamaOrbita(item)) return;
    final identity = sheetTagAt(schedaCorrente);
    final dropped = _lamaOrbitaData(item);
    final fighting = currentCombatIsActive() && !outsideFight;
    final encounter = onlineCombatEncounterId;
    final contact = _lamaOrbitaPickupContact(item);
    if (contact == null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(t('Raccogli Lama Orbita', 'Pick up Orbit Blade')),
          content: Text(
            t(
              'Conferma di essere a contatto con la Lama caduta.',
              'Confirm you are touching the dropped Blade.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(t('Conferma', 'Confirm')),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    bool valid() =>
        mounted &&
        sheetTagAt(schedaCorrente) == identity &&
        identical(dropped, _lamaOrbitaData(item)) &&
        fighting == (currentCombatIsActive() && !outsideFight) &&
        (!fighting || encounter == onlineCombatEncounterId) &&
        canRecoverLamaOrbita(item);
    if (!valid() ||
        fighting &&
            !await requestUtilitySpend(
              'azione',
              preferFreeReaction: false,
              deferMasterTurn: true,
            )) {
      return;
    }
    if (!valid()) return;
    _writeLamaOrbitaData(
      item,
      Map<String, dynamic>.from(dropped!)
        ..remove('lost')
        ..remove('drop'),
    );
    invalidateDerivedDataCaches();
    aggiungiLog('[LAMA ORBITA] Lama raccolta.');
    refreshPermissionUi();
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
    if (fighting) {
      await flushPendingCombatTurnResources();
      if (mounted) advanceMasterInitiativeAfterAction(identity);
    }
  }

  void advanceLamaOrbitaFlight(int ownerTurn) {
    final raw = planarState[_lamaOrbitaFlight];
    if (raw is! Map) return;
    final flight = _activeLamaOrbitaFlight;
    if (flight == null || _findLaunchedLamaOrbita(raw) == null) {
      _returnLamaOrbita(raw);
      return;
    }
    if (flight['scene'] != vttSceneForDisplay().id ||
        !currentCombatIsActive() ||
        outsideFight) {
      _returnLamaOrbita(flight);
      return;
    }
    final pending = '${flight['pending'] ?? ''}';
    final dueTurn = max(
      ownerTurn,
      readIntValue(flight['dueTurn'], fallback: ownerTurn),
    );
    flight['dueTurn'] = dueTurn;
    if (pending.isNotEmpty &&
        onlineCombatRequests[pending]?['status'] == 'pending') {
      return;
    }
    flight.remove('pending');
    final elapsed = max(0, dueTurn - readIntValue(flight['firstTurn']));
    var orbit = readIntValue(flight['orbit']);
    final loops = readIntValue(flight['loops']);
    final targets = (flight['targets'] as List? ?? const [])
        .whereType<String>()
        .toList();
    final inArea = _lamaOrbitaAreaTargets(sheetTagAt(schedaCorrente));
    var next = readIntValue(flight['nextTarget']);
    while (true) {
      if (next >= targets.length) {
        if (elapsed <= orbit) break;
        if (orbit + 1 >= loops) {
          _returnLamaOrbita(flight);
          return;
        }
        next = 0;
        flight['nextTarget'] = next;
        flight['orbit'] = ++orbit;
      }
      flight['nextTarget'] = next + 1;
      final tag = targets[next++];
      final target = inArea
          .where((token) => combatTokenMatchesSheet(token, tag))
          .firstOrNull;
      if (target == null) continue;
      final packet = _lamaOrbitaAttackPacket(flight, target, orbit);
      flight['pending'] = packet['id'];
      _sendLamaOrbitaPacket(packet);
      if (packet['status'] == 'pending' &&
          onlineCombatRequests.containsKey(packet['id'])) {
        break;
      }
      flight.remove('pending');
    }
    programmaSalvataggio();
  }

  void advanceLamaOrbitaForActiveToken(Map<String, dynamic> token) {
    final owner = onlineCombatTokenTag(token);
    if (owner.isEmpty) return;
    final index = localSheetIndexForOculumTag(owner);
    if (index < 0) return;
    if (index == schedaCorrente) {
      if (planarState[_lamaOrbitaFlight] == null &&
          !inventario.any((item) => lamaOrbitaCooldownRemaining(item) > 0)) {
        return;
      }
    } else {
      final sheet = schedePersonaggio[index];
      final rawItems = sheet['inventario'];
      if ((sheet['planarRuntime'] as Map?)?[_lamaOrbitaFlight] == null &&
          (rawItems is! List ||
              !rawItems.whereType<Map>().any((item) {
                final data = item['craftData'];
                return data is Map &&
                    _lamaOrbitaCooldownRemaining(data[oculumLamaOrbitaId]) > 0;
              }))) {
        return;
      }
    }
    faunaForOwnedSheet(owner, () {
      if (!currentCombatIsActive()) return;
      final turn = readIntValue(token['reportedTurn']);
      _advanceLamaOrbitaCooldowns(owner, turn);
      advanceLamaOrbitaFlight(turn);
    });
  }
}
