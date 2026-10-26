part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int oculumMaskedPunchDamage(int base, int attack, int form) =>
    (max(0, base + attack) * (1 + const [.1, .2, .5][form.clamp(1, 3) - 1]))
        .floor();
int oculumMaskedVolleyCount(int form, bool precision, int die) =>
    die.clamp(
      1,
      (precision ? const [3, 5, 6] : const [5, 6, 8])[form.clamp(1, 3) - 1],
    ) +
    (precision ? const [1, 2, 3] : const [1, 3, 5])[form.clamp(1, 3) - 1];
int oculumMaskedVolleyDamage(int damage, int targets, bool precision) =>
    (max(0, damage) *
            (precision ? 3 / 7 : 1 / 3) *
            (1 + .05 * max(1, targets)) /
            max(1, targets))
        .floor();
bool oculumMaskedVolleyStops(int die, int total, int attack, int hit) =>
    die >= 20 && (total > attack || hit >= 2);
List<String> oculumMaskedVolleyOrder(
  List<String> selected,
  int hits,
  String lastAttacker, {
  Random? random,
}) {
  final targets = selected.toSet().toList()..shuffle(random ?? Random.secure());
  if (targets.isEmpty) return [];
  if (targets.remove(lastAttacker)) targets.insert(0, lastAttacker);
  return [for (var i = 0; i < hits; i++) targets[i % targets.length]];
}

extension _OculumMaskedMen on _OculumHomePageState {
  Map<String, dynamic> get pendingMaskedAttack =>
      Map<String, dynamic>.from(planarState['maskedAttack'] as Map? ?? {});
  String get maskedCurrentTurnKey =>
      '$onlineCombatEncounterId:${_onlineCombatRound()}:${_usesLocalMasterInitiative ? masterInitiativeActiveIndex : realtimeVisibleInitiativeSnapshot['activeIndex']}';
  bool get maskedShadowActive {
    final shadow = planarState['maskedShadow'];
    if (shadow is! Map) return false;
    return readIntValue(shadow['form']) == 2
        ? shadow['turnKey'] == maskedCurrentTurnKey
        : readIntValue(shadow['form']) != 3 ||
              readIntValue(shadow['turn']) == playerReportedTurn;
  }

  int get maskedShadowForm =>
      readIntValue((planarState['maskedShadow'] as Map?)?['form']);
  bool get maskedShadowFirst =>
      maskedShadowActive &&
      onlineCombatTokens().isNotEmpty &&
      onlineCombatTokenTag(onlineCombatTokens().first) ==
          sheetTagAt(schedaCorrente);
  int get maskedShadowDamage =>
      !maskedShadowFirst ? 0 : max(2, leggiNumero(livelloController) ~/ 10 * 3);
  int get maskedShadowDefense =>
      !maskedShadowFirst ? 0 : max(1, leggiNumero(livelloController) ~/ 10);
  bool maskedIsAbility(String id) => hasPlanarTechnique(id);

  int maskedParameter(String target, int fallback) {
    for (final effects in [
      for (final skill in skills.where((s) => s.equipaggiata))
        for (final form in skill.forme) form.effettiStrutturati,
      for (final art in arti)
        for (final skill in art.skills) skill.effettiEvoluzione(1),
    ]) {
      for (final effect in effects) {
        if (effect.type == 'planar' && effect.target == target) {
          return max(
            0,
            readIntValue(effect.valueExpression, fallback: fallback),
          );
        }
      }
    }
    return fallback;
  }

  void activateMaskedPower(String target, int form) {
    final tier = form.clamp(1, 3);
    switch (target) {
      case 'mask_serious_punch':
      case 'mask_blue_volley':
      case 'mask_angelic_arrows':
      case 'mask_solar_arrows':
        planarState['maskedAttack'] = {
          'kind': target,
          'form': tier,
          if (target == 'mask_blue_volley') ...{
            'reflexHits': oculumMaskedVolleyCount(
              tier,
              false,
              Random.secure().nextInt(const [5, 6, 8][tier - 1]) + 1,
            ),
            'precisionHits': oculumMaskedVolleyCount(
              tier,
              true,
              Random.secure().nextInt(const [3, 5, 6][tier - 1]) + 1,
            ),
          },
        };
        aggiungiLog(
          target == 'mask_angelic_arrows' || target == 'mask_solar_arrows'
              ? '[ARCO] Pronto: ${target == 'mask_angelic_arrows' ? 'tre frecce angeliche, tiro +9' : 'due frecce solari, tiro +3'}. Scegli Attacco; i bersagli mancanti vengono ricolpiti.'
              : target == 'mask_serious_punch'
              ? '[PUGNO SERIO] Pronto: scegli Attacco. Schianto aggiunto al danno, +${const [10, 20, 50][tier - 1]}%; nessuna Azione/Reazione.'
              : '[CONCATENAZIONE] Pronta: scegli Attacco, Riflessi +5 oppure Precisione su punti deboli già noti. Una sola Azione/Reazione per tutta la raffica.',
        );
      case 'mask_shadow_form':
        planarState['maskedShadowTier'] = tier;
        planarState['maskedShadow'] = {
          'form': tier,
          'turn': playerReportedTurn,
          'turnKey': maskedCurrentTurnKey,
        };
        aggiungiLog(
          '[L’OMBRA] Forma $tier: immune al Fisico; +5 ai tiri Attacco/Difesa. ${tier == 1
              ? 'Fino alla prossima tua azione.'
              : tier == 2
              ? 'Fino a fine turno corrente.'
              : 'Fino all’inizio del tuo prossimo turno.'}',
        );
      case 'mask_shadow_teleport':
        planarState['maskedTeleport'] = true;
        final chance =
            const [10, 15, 30][readIntValue(
                  planarState['maskedShadowTier'],
                  fallback: 1,
                ).clamp(1, 3) -
                1];
        if (Random.secure().nextInt(100) < chance) {
          unawaited(
            requestUtilitySpend('speed_grant_fast', preferFreeReaction: false),
          );
          aggiungiLog(
            '[TELETRASPORTO] Reazione veloce extra ottenuta ($chance%).',
          );
        }
        aggiungiLog(
          '[TELETRASPORTO] Prossimo Attacco +9 oppure Difesa +10; poi il bonus si consuma.',
        );
    }
    programmaSalvataggio();
  }

  void consumeMaskedShadowAction() {
    if (maskedShadowForm == 1) planarState.remove('maskedShadow');
  }

  void maskedTurnStart({int? percentile}) {
    planarState.remove('maskedShadow');
    ensureMaskedPassives();
    if (maskedIsAbility('masked_violet_recovery')) {
      final missing = max(0, oculumMassimoNaturale() - currentOculum());
      if (missing > 0) {
        addOculum(min(2, missing));
        aggiungiLog('[MASCHERA VIOLA] +${min(2, missing)} Oculum.');
      } else if ((percentile ?? Random.secure().nextInt(100)) < 20) {
        // The ordinary temporary pool has its own lifetime and is spent first.
        final before = currentTemporaryOculumState();
        applyTemporaryOculumState(
          TemporaryOculumState(
            normalCurrent: before.normalCurrent,
            temporary: before.temporary + 1,
            rollsRemaining: max(1, before.rollsRemaining),
          ),
        );
        aggiungiLog('[MASCHERA VIOLA] +1 Oculum temporaneo (20%).');
      }
    }
  }

  void ensureMaskedPassives() {
    if (maskedIsAbility('masked_green_memory') &&
        !hasCondition('ricordo_vitale')) {
      applyCondition(
        'ricordo_vitale',
        source: 'Maschera verde',
        durationType: OculumConditionDurationType.permanent,
      );
    }
  }

  int maskedAngelicHpHit(int hpLost) {
    if (hpLost <= 0 || !maskedIsAbility('masked_angelic_memory')) return 0;
    final count = readIntValue(planarState['maskedAngelicHits']) + 1;
    final threshold = max(1, maskedParameter('mask_angelic_hits', 3));
    final percent = maskedParameter('mask_angelic_heal', 5);
    planarState['maskedAngelicHits'] = count % threshold;
    if (count < threshold || hpCorrenti() <= 0) return 0;
    final amount = min(
      max(0, maxHp() - hpCorrenti()),
      (hpCorrenti() * percent / 100).ceil(),
    );
    currentHpController.text = '${hpCorrenti() + amount}';
    aggiungiLog(
      '[RICORDO ANGELICO] $threshold colpi alla Vita: +$amount HP ($percent% della Vita rimasta).',
    );
    return amount;
  }

  void maskedAnyTurnEnded() {
    for (var i = 0; i < schedePersonaggio.length; i++) {
      final runtime = i == schedaCorrente
          ? planarState
          : schedePersonaggio[i]['planarRuntime'];
      if (runtime is Map &&
          runtime['maskedShadow'] is Map &&
          readIntValue((runtime['maskedShadow'] as Map)['form']) == 2) {
        runtime.remove('maskedShadow');
      }
    }
  }

  Map<String, dynamic>? maskedVolleyRecord(Map request) =>
      onlineCombatRequests['masked-volley:${request['attackGroupId']}'];
  void startMaskedVolley(List<Map<String, dynamic>> requests) {
    if (requests.isEmpty) return;
    final first = requests.first;
    onlineCombatRequests['masked-volley:${first['attackGroupId']}'] = {
      'kind': 'masked_volley',
      'id': 'masked-volley:${first['attackGroupId']}',
      'sourceTag': first['sourceTag'],
      'encounterId': first['encounterId'],
      'status': 'running',
      'packets': requests,
      'next': 1,
    };
    dispatchMaskedVolleyPacket(first);
  }

  void dispatchMaskedVolleyPacket(Map<String, dynamic> request) {
    onlineCombatRequests['${request['id']}'] = request;
    receiveLocalCombatAttack(request);
    unawaited(sendOnlineCombatRequest(request));
    programmaSalvataggio();
  }

  void stopMaskedVolley(Map request) {
    final record = maskedVolleyRecord(request);
    if (record != null) record['status'] = 'cancelled';
    for (final packet in onlineCombatRequests.values.where(
      (p) =>
          p['attackGroupId'] == request['attackGroupId'] &&
          p['status'] == 'pending',
    )) {
      packet['status'] = 'cancelled';
    }
    aggiungiLog(
      '[CONCATENAZIONE] Critico difensivo: raffica interrotta. Restano soltanto i danni già subiti.',
    );
    programmaSalvataggio();
  }

  void advanceMaskedVolley(
    Map<String, dynamic> request,
    int natural,
    int total,
  ) {
    if (request['maskedVolley'] != true &&
        request['boneVolley'] != true &&
        request['cycleSpines'] != true) {
      return;
    }
    if (request['boneVolley'] != true &&
        request['cycleSpines'] != true &&
        oculumMaskedVolleyStops(
          natural,
          total,
          readIntValue(request['attack']),
          readIntValue(request['maskedHitIndex']),
        )) {
      stopMaskedVolley(request);
      return;
    }
    final record = maskedVolleyRecord(request);
    if (record == null || record['status'] != 'running') return;
    final processed = (record['processed'] as List? ?? [])
        .map((e) => '$e')
        .toSet();
    if (!processed.add('${request['id']}')) return;
    record['processed'] = processed.toList();
    final spineHits = (record['cycleSpineSuccessfulTags'] as List? ?? [])
        .map((v) => '$v')
        .toList();
    if (request['cycleSpines'] == true &&
        readIntValue(request['attack']) > total) {
      spineHits.add('${request['targetTag']}');
      record['cycleSpineSuccessfulTags'] = spineHits;
    }
    if (request['boneVolley'] == true &&
        readIntValue(request['attack']) > total) {
      record['boneSuccessfulHits'] =
          readIntValue(record['boneSuccessfulHits']) + 1;
    }
    final packets = (record['packets'] as List).whereType<Map>().toList();
    final next = readIntValue(record['next']);
    if (next >= packets.length) {
      record['status'] = 'resolved';
      return;
    }
    record['next'] = next + 1;
    final packet = Map<String, dynamic>.from(packets[next]);
    if (packet['cycleSpines'] == true) {
      packet['damage'] = oculumCycleSpineDamage(
        readIntValue(packet['cycleSpineBaseDamage']),
        spineHits,
        '${packet['targetTag']}',
      );
    }
    if (packet['boneVolley'] == true) {
      packet['damage'] = oculumBoneSlashDamage(
        readIntValue(packet['boneSlashBase']),
        readIntValue(record['boneSuccessfulHits']),
        readIntValue(packet['boneSlashPercent']),
      );
    }
    dispatchMaskedVolleyPacket(packet);
  }

  bool receiveMaskedInterrupt(Map<String, dynamic> payload) {
    if (payload['maskedInterrupt'] != true) return false;
    final request = onlineCombatRequests['${payload['id']}'];
    if (request == null ||
        payload['encounterId'] != request['encounterId'] ||
        request['scope'] != permissionScope ||
        request['maskedVolley'] != true ||
        request['status'] != 'pending' ||
        readIntValue(request['maskedHitIndex']) < 2 ||
        !(request['maskedSelectedTargets'] as List? ?? []).contains(
          payload['senderTag'],
        ) ||
        readIntValue(payload['maskedInterruptNatural']) < 20 ||
        payload['sourceTag'] != request['sourceTag'] ||
        payload['targetTag'] != request['targetTag']) {
      return true;
    }
    stopMaskedVolley(request);
    return true;
  }

  Iterable<Map<String, dynamic>> get maskedInterruptibleVolleys =>
      onlineCombatRequests.values.where(
        (r) =>
            r['maskedVolley'] == true &&
            r['status'] == 'pending' &&
            readIntValue(r['maskedHitIndex']) >= 2 &&
            (r['maskedSelectedTargets'] as List? ?? []).contains(
              sheetTagAt(schedaCorrente),
            ),
      );
  Future<void> interruptMaskedVolley(Map<String, dynamic> request) async {
    final origin = currentSheetScrollId();
    if (!await spendCombatRollResource() ||
        !mounted ||
        currentSheetScrollId() != origin) {
      return;
    }
    await tiraValoreSpeciale(
      'Interrompi concatenazione · CM',
      cm(),
      resourceAlreadySpent: true,
      onResolved: (natural, total) {
        aggiungiLog(
          '[CONCATENAZIONE] Tentativo di interruzione $total (dado $natural): ${natural >= 20 ? 'critico, raffica fermata' : 'nessuna interruzione'}.',
        );
        if (natural < 20 || request['status'] != 'pending') return;
        final packet = <String, dynamic>{
          ...request,
          'maskedInterrupt': true,
          'maskedInterruptNatural': natural,
          'defense': total,
        };
        stopMaskedVolley(request);
        attachPendingCombatTurnResources(packet);
        unawaited(
          realtimeService?.sendCombatEvent(
            'combat_defense',
            permissionEnvelope(packet),
          ),
        );
      },
    );
  }
}
