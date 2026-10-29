part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

bool oculumGuardianGoldArt(CharacterArt art) => art.openDescriptionEffects.any(
  (effect) => effect.target == 'guardian_gold_open',
);

/// Only new catalogue instances pass through here. Saved/custom Arts retain
/// their own descriptions, costs, effect values and cooldowns.
CharacterArt oculumConfigureGuardianGoldArt(CharacterArt art) {
  art.monsterOpenSkill = true;
  art.openName = 'Potere dell’oro';
  art.openDescription =
      'Costo: 8 Oculum. Evoca uno spadone e uno scudo d’oro fino al recupero della Open. '
      'I primi tre tentativi con lo spadone, anche mancati, infliggono ×1,5 Danni. '
      'Un critico rende dorata la parte colpita per un turno personale: −3 ai tiri '
      'che la usano. Un doppio critico rende d’oro tutto il corpo per due turni, '
      'Immobilizzato. Liberazione con Azione o Reazione: Forza, Controllo corporeo '
      'o Volontà contro DT 10 + livello del Guardiano + 2 × Grado. '
      'Lo scudo riflette il 15% dei Danni subiti in mischia, compresi quelli '
      'assorbiti dagli Scudi, esclusi i Danni di tipo Luna. Riflessi gratuito contro il totale '
      'dell’attacco originario; è possibile ritentare spendendo una Reazione.';
  art.openBuff =
      '@Difesa+10 Solare; @Danni+15 Solare; Scudo (100 + livello) × max(1, Grado). '
      'Muro d’oro diventa una cupola che segue il Guardiano; vede al suo interno '
      'e può attaccare senza dissolverla.';
  art.openSkill =
      'Muro d’oro. Costo: 3 Oculum. Cooldown: 3 turni personali. '
      'Sempre utilizzabile: fuori dalla propria Open appare soltanto lo scudo '
      'durante questa Skill, senza lo spadone. Fino a fine fight o nuova '
      'attivazione: Super Vantaggio (+6) difensivo. Con il potenziamento della '
      'propria Open, la cupola dà Svantaggio (−3) ai nemici percepiti che '
      'attaccano il Guardiano. Chi lo colpisce e chi aiuta quel '
      'colpo sono immuni alla protezione per questa attivazione. Ogni attacco '
      'ricevuto richiede Concentrazione DT15 (DT12 con la propria Open); '
      'fallendo, la protezione termina. Il muro normale termina quando il '
      'Guardiano attacca; la cupola della propria Open rimane e lo segue.';
  OculumStructuredEffect setting(String target, int value, String label) =>
      OculumStructuredEffect(
        id: target,
        type: 'planar',
        target: target,
        valueExpression: '$value',
        recipient: 'se_stesso',
        customDisplayText: label,
      );
  art.openDescriptionEffects = [
    setting('guardian_gold_open', 3, 'Primi tentativi dello spadone'),
    setting('guardian_gold_sword_percent', 50, 'Danni aggiuntivi spadone (%)'),
    setting('guardian_gold_reflect', 15, 'Danni in mischia riflessi (%)'),
    setting('guardian_gold_release_base', 10, 'DT liberazione base'),
    setting('guardian_gold_part_penalty', 3, 'Malus della parte dorata'),
    setting('guardian_gold_part_turns', 1, 'Turni della parte dorata'),
    setting('guardian_gold_whole_turns', 2, 'Turni del corpo dorato'),
    OculumStructuredEffect(
      id: 'guardian_gold_shield',
      type: 'planar',
      target: 'guardian_gold_shield',
      valueExpression: '100+livello',
      recipient: 'se_stesso',
      elementType: 'solare',
      customDisplayText: 'Scudo: valore × Grado (almeno 1)',
    ),
    // Marks a catalogue Open with no invented minimum level. The standard
    // unlock resolver still honours a user-edited "Richiede livello".
    OculumStructuredEffect(
      id: 'monster_open_ultimate_guardian_gold',
      type: 'planar',
      target: 'guardian_gold_catalogue',
      valueExpression: '0',
      recipient: 'se_stesso',
    ),
  ];
  art.openBuffEffects = [];
  art.openSkillEffects = [
    setting('guardian_gold_wall_penalty', 3, 'Svantaggio dei nemici percepiti'),
    setting('guardian_gold_wall_concentration', 15, 'DT Concentrazione muro'),
    setting('guardian_gold_dome_concentration', 12, 'DT Concentrazione cupola'),
    setting('guardian_gold_wall', 6, 'Super Vantaggio difensivo'),
  ];
  art.openDescriptionCooldown = null;
  art.openBuffCooldown = null;
  art.openSkillCooldown = OculumAbilityCooldown(amount: 3);
  return art;
}

int oculumGuardianGoldReleaseDifficulty(
  int level,
  int grade, {
  int base = 10,
}) => (max(0, base) + max(0, level) + 2 * max(0, grade)).toInt();

int oculumGuardianGoldReflection(int received, {int percent = 15}) =>
    (max(0, received) * percent.clamp(0, 100) / 100).floor();

extension _OculumGuardianGold on _OculumHomePageState {
  Map<String, dynamic> get guardianGoldState {
    final raw = planarState['guardianGold'];
    if (raw is Map<String, dynamic>) return raw;
    final next = Map<String, dynamic>.from(raw as Map? ?? const {});
    planarState['guardianGold'] = next;
    return next;
  }

  bool get guardianGoldOwnOpen => arti.any(
    (art) =>
        art.sbloccata &&
        art.inUso &&
        artOpenBuffActive(art) &&
        oculumGuardianGoldArt(art),
  );

  bool get guardianGoldSkillBoost => arti.any(
    (art) =>
        art.sbloccata &&
        art.inUso &&
        oculumGuardianGoldArt(art) &&
        artOwnOpenSkillEmpowered(art),
  );

  bool get guardianGoldWallActive => guardianGoldState['wallActive'] == true;

  Future<void> useGuardianGoldOpen(CharacterArt art, int index) async {
    if (!arti.contains(art) || !art.inUso || !artOpenSbloccata(art)) return;
    if (art.openAttiva) {
      deactivateArtOpenBuffCycle(art);
      art.openAttiva = false;
      guardianGoldState.remove('wallActive');
      invalidateDerivedDataCaches();
      programmaSalvataggio();
      scheduleRealtimeOculumChanged();
      await publishGuardianGoldState();
      if (mounted) setState(() {});
      return;
    }
    if (!canStartArtOpenCycle(art)) {
      aggiungiLog('Potere dell’oro: Open non ancora recuperata con i riposi.');
      return;
    }
    final origin = currentSheetScrollId();
    final encounter = onlineCombatEncounterId;
    ensureArtIntegrityValue(index);
    final integrityCost =
        !art.hasIntegrity || oculumRecognizedArtKind(art) == 'emblem'
        ? 0
        : artUseCost(oculumArtActivationCost);
    if (art.hasIntegrity &&
        !oculumArtCanActivate(art.integritaCorrente, cost: integrityCost)) {
      aggiungiLog('Potere dell’oro: integrità Art insufficiente.');
      return;
    }
    final parsed = oculumParseAbilityCost(art.openDescription);
    final used = await useConfiguredAbility(
      source: artOpenDisplayName(art, index),
      effects: art.openDescriptionEffects,
      cost: OculumSkillCost(
        resource: parsed?.resource ?? 'oculum',
        amountExpression: '${parsed?.minimum ?? 8}',
        minimum: parsed?.minimum ?? 8,
        maximum: parsed?.maximum ?? 8,
        variable: parsed != null && parsed.minimum != parsed.maximum,
      ),
      cooldown: art.openDescriptionCooldown,
      valid: () =>
          currentSheetScrollId() == origin &&
          onlineCombatEncounterId == encounter &&
          arti.contains(art) &&
          art.sbloccata &&
          art.inUso &&
          !art.openAttiva &&
          artOpenSbloccata(art) &&
          canStartArtOpenCycle(art),
      onPaid: (_) {
        recordArtOpenCycleActivation(art);
        if (art.hasIntegrity) {
          consumeArtIntegrityAndResolveDebuff(
            index,
            integrityCost,
            skillLevel: 3,
          );
        }
        disattivaTutteLeOpen(exceptArt: art);
        art.openAttiva = true;
        art.openUsedSinceLongRest = true;
      },
    );
    if (!used || !mounted || currentSheetScrollId() != origin) return;
    tagOpenLifecycleBuffEffects(
      artOpenLifecycle(art).id,
      artOpenDisplayName(art, index),
    );
    invalidateDerivedDataCaches();
    notifyArtIntegrityChanged(index);
    scheduleArtIntegritySave(<int>[index], immediate: true);
    programmaSalvataggio();
    await publishGuardianGoldState();
  }

  bool activateGuardianGoldEffect(OculumStructuredEffect effect, int value) {
    if (!effect.target.startsWith('guardian_gold_')) return false;
    final state = guardianGoldState;
    switch (effect.target) {
      case 'guardian_gold_open':
        state['swordAttempts'] = 0;
        state['swordAttemptLimit'] = max(0, value);
        state['attackReceipts'] = <String, dynamic>{};
        break;
      case 'guardian_gold_wall':
        state['wallActive'] = true;
        state['wallDefense'] = max(0, value);
        state['wallGeneration'] = '${DateTime.now().microsecondsSinceEpoch}';
        state['immuneTags'] = <String>[];
        state['incomingReceipts'] = <String>[];
        if (guardianGoldSkillBoost) {
          final stat = hiddenEyeStats
              .where((s) => s.id == 'percezione')
              .firstOrNull;
          final natural = tiraD20();
          state['perceptionTotal'] = rollTotalWithCritical(natural, 20, [
            stat == null ? 0 : hiddenEyeTotal(stat),
            tiroGlobaleBonus(),
          ]);
          aggiungiLog(
            '[CUPOLA D’ORO] Percezione ${state['perceptionTotal']} '
            '(d20 $natural): confronto con le difese percettive dei nemici.',
          );
        } else {
          state.remove('perceptionTotal');
        }
        unawaited(publishGuardianGoldState());
        break;
      case 'guardian_gold_shield':
        final amount = max(0, value) * max(1, leggiNumero(gradoController));
        scudoController.text =
            '${max(0, leggiNumero(scudoController)) + amount}';
        break;
      default:
        state[effect.target.substring('guardian_gold_'.length)] = max(0, value);
    }
    return true;
  }

  /// Called exactly when a genuine attack attempt is committed, not while its
  /// planner is opened. Retries of one packet reuse the recorded multiplier.
  double guardianGoldBeforeOutgoingAttack({
    required String actionId,
    required bool melee,
  }) {
    final state = guardianGoldState;
    if (guardianGoldWallActive && !guardianGoldSkillBoost) {
      state['wallActive'] = false;
      unawaited(publishGuardianGoldState());
    }
    if (!guardianGoldOwnOpen || !melee || actionId.isEmpty) return 1;
    final receipts = Map<String, dynamic>.from(
      state['attackReceipts'] as Map? ?? const {},
    );
    final old = receipts[actionId];
    if (old is num) return old.toDouble();
    final attempts = readIntValue(state['swordAttempts']);
    final limit = readIntValue(state['swordAttemptLimit'], fallback: 3);
    final multiplier = attempts < limit
        ? 1 + readIntValue(state['sword_percent'], fallback: 50) / 100
        : 1.0;
    state['swordAttempts'] = attempts + 1;
    receipts[actionId] = multiplier;
    state['attackReceipts'] = receipts;
    programmaSalvataggio();
    return multiplier;
  }

  Map<String, dynamic> guardianGoldAttackMetadata({required bool melee}) {
    if (!guardianGoldOwnOpen || !melee) return const {};
    final state = guardianGoldState;
    return {
      'guardianGoldAttack': {
        'releaseDifficulty': oculumGuardianGoldReleaseDifficulty(
          leggiNumero(livelloController),
          leggiNumero(gradoController),
          base: readIntValue(state['release_base'], fallback: 10),
        ),
        'partPenalty': readIntValue(state['part_penalty'], fallback: 3),
        'partTurns': readIntValue(state['part_turns'], fallback: 1),
        'wholeTurns': readIntValue(state['whole_turns'], fallback: 2),
      },
    };
  }

  Set<String> get guardianGoldImmuneTags => {
    for (final tag in guardianGoldState['immuneTags'] as List? ?? const [])
      '$tag',
  };

  int guardianGoldDefenseBonus(Map<String, dynamic> request) =>
      guardianGoldWallActive &&
          !guardianGoldImmuneTags.contains('${request['sourceTag']}')
      ? readIntValue(guardianGoldState['wallDefense'], fallback: 6)
      : 0;

  int guardianGoldIncomingRollPenalty(Map<String, dynamic> request) =>
      guardianGoldDefenseBonus(request) > 0 &&
          guardianGoldSkillBoost &&
          request['guardianGoldPerceived'] == true
      ? -readIntValue(guardianGoldState['wall_penalty'], fallback: 3)
      : 0;

  /// Owner-authoritative. All received attacks count, even a miss or a hit
  /// fully absorbed by shields. receivedDamage already includes shield loss.
  Map<String, dynamic>? guardianGoldAfterIncomingAttack(
    Map<String, dynamic> request, {
    required bool hit,
    required int receivedDamage,
    required bool melee,
    required bool lunar,
    int? concentrationNatural,
  }) {
    final state = guardianGoldState;
    final receipt = '${request['id'] ?? ''}';
    if (receipt.isEmpty) return null;
    final receipts = List<String>.from(
      state['incomingReceipts'] as List? ?? const [],
    );
    if (receipts.contains(receipt)) return null;
    receipts.add(receipt);
    state['incomingReceipts'] = receipts;
    if (guardianGoldWallActive) {
      if (hit) {
        final immune = guardianGoldImmuneTags..add('${request['sourceTag']}');
        for (final tag in request['guardianGoldHelpers'] as List? ?? const []) {
          immune.add('$tag');
        }
        state['immuneTags'] = immune.where((tag) => tag.isNotEmpty).toList();
      }
      final stat = hiddenEyeStats
          .where((s) => s.id == 'concentrazione')
          .firstOrNull;
      final natural = concentrationNatural ?? tiraD20();
      final total = rollTotalWithCritical(natural, 20, [
        stat == null ? 0 : hiddenEyeTotal(stat),
        tiroGlobaleBonus(),
      ]);
      final difficulty = readIntValue(
        state[guardianGoldSkillBoost
            ? 'dome_concentration'
            : 'wall_concentration'],
        fallback: guardianGoldSkillBoost ? 12 : 15,
      );
      final held = total >= difficulty;
      if (!held) state['wallActive'] = false;
      aggiungiLog(
        '[MURO D’ORO] Concentrazione $total / DT$difficulty: '
        '${held ? 'protezione mantenuta' : 'protezione dissolta'}.',
      );
      unawaited(publishGuardianGoldState());
    }
    programmaSalvataggio();
    if (!guardianGoldOwnOpen || !melee || lunar || !hit) return null;
    final reflected = oculumGuardianGoldReflection(
      receivedDamage,
      percent: readIntValue(state['reflect'], fallback: 15),
    );
    if (reflected <= 0) return null;
    return {
      'id': 'gold-reflect:$receipt',
      'sourceTag': sheetTagAt(schedaCorrente),
      'targetTag': request['sourceTag'],
      'damage': reflected,
      'difficulty': readIntValue(request['attackTotal']),
      'element': 'solare',
      'freeReflexDefense': true,
      'paidReactionRetry': true,
    };
  }

  void receiveGuardianGoldCritical(
    Map<String, dynamic> request, {
    required int criticalCount,
    String bodyPart = '',
  }) {
    if (criticalCount <= 0 || request['guardianGoldAttack'] is! Map) return;
    final config = request['guardianGoldAttack'] as Map;
    final receipt = '${request['id'] ?? ''}';
    if (receipt.isEmpty) return;
    final state = guardianGoldState;
    final seen = List<String>.from(state['goldReceipts'] as List? ?? const []);
    if (seen.contains(receipt)) return;
    seen.add(receipt);
    state['goldReceipts'] = seen;
    final whole = criticalCount >= 2;
    final turns = max(
      1,
      readIntValue(
        config[whole ? 'wholeTurns' : 'partTurns'],
        fallback: whole ? 2 : 1,
      ),
    );
    final effects = List<Map<String, dynamic>>.from(
      (state['goldParts'] as List? ?? const []).whereType<Map>().map(
        (entry) => Map<String, dynamic>.from(entry),
      ),
    );
    effects.add({
      'receipt': receipt,
      'part': whole
          ? 'corpo intero'
          : bodyPart.trim().isEmpty
          ? 'parte colpita'
          : bodyPart.trim(),
      'whole': whole,
      'remaining': turns,
      'penalty': max(0, readIntValue(config['partPenalty'], fallback: 3)),
      'difficulty': max(
        0,
        readIntValue(config['releaseDifficulty'], fallback: 10),
      ),
    });
    state['goldParts'] = effects;
    if (whole) {
      applyCondition(
        'immobilizzato',
        duration: turns,
        source: 'Potere dell’oro · $receipt',
      );
    }
    aggiungiLog(
      '[POTERE DELL’ORO] ${effects.last['part']} dorato: $turns turni personali.',
    );
    programmaSalvataggio();
  }

  List<Map<String, dynamic>> get guardianGoldParts => [
    for (final raw in guardianGoldState['goldParts'] as List? ?? const [])
      if (raw is Map && readIntValue(raw['remaining']) > 0)
        Map<String, dynamic>.from(raw),
  ];

  int guardianGoldPartPenalty(String part) {
    final normalized = oculumNormalizeText(part);
    if (normalized.isEmpty) return 0;
    var penalty = 0;
    for (final effect in guardianGoldParts) {
      if (effect['whole'] == true) continue;
      final affected = oculumNormalizeText('${effect['part']}');
      if (affected == normalized || affected == 'parte colpita') {
        penalty = max(penalty, readIntValue(effect['penalty']));
      }
    }
    return -penalty;
  }

  Future<void> releaseGuardianGold(
    String receipt,
    String trait,
    String resource,
  ) async {
    const allowed = {'forza', 'controllo_corporeo', 'volonta'};
    if (!allowed.contains(trait)) return;
    final origin = currentSheetScrollId();
    final effect = guardianGoldParts
        .where((e) => e['receipt'] == receipt)
        .firstOrNull;
    if (effect == null ||
        !await requestUtilitySpend(resource, preferFreeReaction: false) ||
        !mounted ||
        currentSheetScrollId() != origin) {
      return;
    }
    final stat = hiddenEyeStats.where((s) => s.id == trait).firstOrNull;
    final base = trait == 'volonta'
        ? volontaTotale()
        : stat == null
        ? 0
        : hiddenEyeTotal(stat);
    final natural = tiraD20();
    final total = rollTotalWithCritical(natural, 20, [
      base,
      tiroGlobaleBonus(),
    ]);
    final success = total >= readIntValue(effect['difficulty']);
    if (success) {
      guardianGoldState['goldParts'] = guardianGoldParts
          .where((e) => e['receipt'] != receipt)
          .toList();
      for (final condition
          in activeConditions
              .where((c) => c.source == 'Potere dell’oro · $receipt')
              .toList()) {
        removeCondition(condition, force: true);
      }
    }
    aggiungiLog(
      '[LIBERAZIONE DALL’ORO] $trait $total / DT${effect['difficulty']}: '
      '${success ? 'libero' : 'doratura mantenuta'}.',
    );
    programmaSalvataggio();
    if (mounted) setState(() {});
  }

  Widget guardianGoldificationControls() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final effect in guardianGoldParts) ...[
        Text(
          'Doratura · ${effect['part']} · ${effect['remaining']} turni · DT${effect['difficulty']}',
        ),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final trait in const [
              'forza',
              'controllo_corporeo',
              'volonta',
            ])
              for (final resource in const ['azione', 'reazione'])
                OutlinedButton(
                  onPressed: () => releaseGuardianGold(
                    '${effect['receipt']}',
                    trait,
                    resource,
                  ),
                  child: Text('${trait.replaceAll('_', ' ')} · $resource'),
                ),
          ],
        ),
      ],
    ],
  );

  void tickGuardianGoldTurn() {
    if (planarState['guardianGold'] is! Map) return;
    final effects = guardianGoldParts;
    for (final effect in effects) {
      effect['remaining'] = max(0, readIntValue(effect['remaining']) - 1);
    }
    guardianGoldState['goldParts'] = effects
        .where((e) => readIntValue(e['remaining']) > 0)
        .toList();
  }

  void resetGuardianGoldFight() {
    for (final condition
        in activeConditions
            .where(
              (condition) => condition.source.startsWith('Potere dell’oro · '),
            )
            .toList()) {
      removeCondition(condition, force: true);
    }
    if (planarState['guardianGold'] is Map) {
      for (final key in const [
        'wallActive',
        'wallGeneration',
        'immuneTags',
        'incomingReceipts',
        'perceptionTotal',
        'goldParts',
        'goldReceipts',
      ]) {
        guardianGoldState.remove(key);
      }
    }
  }

  Future<void> publishGuardianGoldState() async {
    final payload = permissionEnvelope({
      'id':
          'guardian-gold:${sheetTagAt(schedaCorrente)}:${DateTime.now().microsecondsSinceEpoch}',
      'guardianGoldEvent': true,
      'scope': permissionScope,
      'encounterId': onlineCombatEncounterId,
      'sourceTag': sheetTagAt(schedaCorrente),
      'wallActive': guardianGoldWallActive,
      'dome': guardianGoldSkillBoost,
      if (guardianGoldState['perceptionTotal'] is num)
        'perceptionTotal': guardianGoldState['perceptionTotal'],
      'wallGeneration': guardianGoldState['wallGeneration'],
      'defenseBonus': readIntValue(
        guardianGoldState['wallDefense'],
        fallback: 6,
      ),
      'attackPenalty': readIntValue(
        guardianGoldState['wall_penalty'],
        fallback: 3,
      ),
      'immuneTags': guardianGoldImmuneTags.toList(),
    });
    receiveGuardianGoldState(payload);
    await realtimeService?.sendCombatEvent('combat_scout', payload);
  }

  void receiveGuardianGoldState(Map<String, dynamic> payload) {
    if (payload['scope'] != permissionScope ||
        payload['encounterId'] != onlineCombatEncounterId) {
      return;
    }
    if (realtimeService?.isConnected == true &&
        (!validPermissionSender(payload) ||
            payload['senderTag'] != payload['sourceTag'] &&
                !const {
                  'master',
                  'coMaster',
                }.contains(payload['senderRole']))) {
      return;
    }
    final token = escapeToken('${payload['sourceTag']}');
    if (token == null) return;
    token['guardianGoldProtection'] = {
      'active': payload['wallActive'] == true,
      'dome': payload['dome'] == true,
      if (payload['perceptionTotal'] is num)
        'perceptionTotal': readIntValue(payload['perceptionTotal']),
      'generation': '${payload['wallGeneration'] ?? ''}',
      'defenseBonus': max(0, readIntValue(payload['defenseBonus'])),
      'attackPenalty': max(0, readIntValue(payload['attackPenalty'])),
      'immuneTags': List<String>.from(
        payload['immuneTags'] as List? ?? const [],
      ),
    };
    if (escapeAuthority) {
      captureActiveMasterInitiativeGroup();
      sendRealtimeInitiativeSnapshotIfPublished();
    }
  }
}
