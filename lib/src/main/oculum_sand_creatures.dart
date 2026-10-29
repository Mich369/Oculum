part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int oculumSandTailReceivedDamage(int damage, int percent) =>
    (max(0, damage) * percent.clamp(0, 100) / 100).ceil();
bool oculumSandVitrificationSucceeds(int roll, int chance) =>
    roll >= 0 && roll < chance.clamp(0, 100);

extension _OculumSandCreatures on _OculumHomePageState {
  String get sandSpeciesId => faunaCurrentMonsterId.split('_variante_').first;
  bool get isSandTailCreature =>
      const {'mostro_sabbia', 'gigante_sabbia'}.contains(sandSpeciesId);
  bool get isSandGiant => sandSpeciesId == 'gigante_sabbia';

  Map<String, dynamic> get sandRules => {
    'cooldownPersonalTurns': 2,
    'receivedDamagePercent': 65,
    'lavaKillPercent': 50,
    'matterDurationTurns': 3,
    'matterDivisor': 2,
    'parryCriticalReference': 'resistenza',
    ...Map<String, dynamic>.from(
      monsterBookEntryById(faunaCurrentMonsterId)?.encounterRules['sandRules']
              is Map
          ? monsterBookEntryById(
                  faunaCurrentMonsterId,
                )!.encounterRules['sandRules']
                as Map
          : const {},
    ),
    ...Map<String, dynamic>.from(
      planarState['sandRules'] is Map
          ? planarState['sandRules'] as Map
          : const {},
    ),
  };

  Map<String, dynamic> get sandTailState {
    final raw = planarState['sandTail'];
    if (raw is Map<String, dynamic>) return raw;
    final result = Map<String, dynamic>.from(raw is Map ? raw : const {});
    planarState['sandTail'] = result;
    return result;
  }

  String get sandFightKey {
    final tag = sheetTagAt(schedaCorrente);
    final token = onlineCombatTokens()
        .where((t) => combatTokenMatchesSheet(t, tag))
        .firstOrNull;
    return '$onlineCombatEncounterId:${token?['fightInstanceId'] ?? ''}';
  }

  bool get sandTailReady =>
      isSandTailCreature &&
      currentCombatIsActive() &&
      !outsideFight &&
      !totalPowerExhausted &&
      hpCorrenti() > 0 &&
      (sandTailState['fight'] != sandFightKey ||
          playerReportedTurn >= readIntValue(sandTailState['readyAtTurn']));

  bool canPrepareSandTail(String mode) =>
      const {'attack', 'parry'}.contains(mode) && sandTailReady;

  bool prepareSandTail(String mode, {int? receivedPercent, int? cooldown}) {
    if (!canPrepareSandTail(mode)) return false;
    final state = sandTailState;
    if (state['fight'] != sandFightKey) state.clear();
    state.addAll({
      'fight': sandFightKey,
      'mode': mode,
      'nonce':
          '${sheetTagAt(schedaCorrente)}:$sandFightKey:'
          '${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(1 << 30)}',
      'receivedDamagePercent':
          (receivedPercent ??
                  readIntValue(
                    sandRules['receivedDamagePercent'],
                    fallback: 65,
                  ))
              .clamp(0, 100),
      'cooldownPersonalTurns': max(
        1,
        cooldown ??
            readIntValue(sandRules['cooldownPersonalTurns'], fallback: 2),
      ),
    });
    aggiungiLog(
      '[CODA DI SABBIA] ${mode == 'attack' ? 'Attacco' : 'Parata senza tiro'} '
      'preparata gratuitamente; una sola disponibilità condivisa.',
    );
    programmaSalvataggio();
    return true;
  }

  bool activateSandEffect(
    OculumStructuredEffect effect,
    int value,
    int duration,
  ) {
    if (!const {
      'sand_tail_attack',
      'sand_tail_parry',
    }.contains(effect.target)) {
      return false;
    }
    prepareSandTail(
      effect.target == 'sand_tail_attack' ? 'attack' : 'parry',
      receivedPercent: value,
      cooldown: duration,
    );
    return true;
  }

  Map<String, dynamic> get pendingSandTailAttack =>
      sandTailReady &&
          sandTailState['mode'] == 'attack' &&
          sandTailState['fight'] == sandFightKey
      ? Map<String, dynamic>.from(sandTailState)
      : const {};

  int get sandParryCriticalReference =>
      sandRules['parryCriticalReference'] == 'cm'
      ? cm()
      : referenceResistanceValue;

  bool claimSandTail(String mode, {String? nonce, String? packetId}) {
    if (!canPrepareSandTail(mode)) return false;
    final state = sandTailState;
    if (state['fight'] != sandFightKey ||
        state['mode'] != mode ||
        nonce != null && nonce != state['nonce']) {
      return false;
    }
    final received = readIntValue(state['receivedDamagePercent'], fallback: 65);
    state['readyAtTurn'] =
        playerReportedTurn +
        max(1, readIntValue(state['cooldownPersonalTurns'], fallback: 2));
    state.remove('mode');
    state.remove('nonce');
    if (mode == 'parry' && packetId != null && packetId.isNotEmpty) {
      final claims = Map<String, dynamic>.from(
        state['parryPackets'] is Map ? state['parryPackets'] as Map : const {},
      );
      claims[packetId] = {'receivedPercent': received, 'used': false};
      state['parryPackets'] = claims;
    }
    aggiungiLog(
      '[CODA DI SABBIA] ${mode == 'attack' ? 'Attacco' : 'Parata'} '
      'gratuita usata; pronta dal turno personale ${state['readyAtTurn']}.',
    );
    programmaSalvataggio();
    return true;
  }

  int applySandTailParry(int damage, {String? packetId}) {
    if (!isSandTailCreature) return damage;
    final state = sandTailState;
    int? percent;
    if (packetId != null && packetId.isNotEmpty) {
      final packets = state['parryPackets'];
      final claim = packets is Map ? packets[packetId] : null;
      if (claim is Map && claim['used'] != true) {
        percent = readIntValue(claim['receivedPercent'], fallback: 65);
        claim['used'] = true;
      }
    } else if (state['mode'] == 'parry' && sandTailReady) {
      percent = readIntValue(state['receivedDamagePercent'], fallback: 65);
      if (!claimSandTail('parry', nonce: '${state['nonce']}')) return damage;
    }
    if (percent == null) return damage;
    final result = oculumSandTailReceivedDamage(damage, percent);
    aggiungiLog(
      '[CODA DI SABBIA] $damage → $result Danni '
      '($percent% ricevuto dopo Difesa e prima degli Scudi).',
    );
    return result;
  }

  Map<String, dynamic> get sandLavaReceipts {
    final raw = planarState['sandLavaReceipts'];
    if (raw is Map<String, dynamic>) return raw;
    final value = Map<String, dynamic>.from(raw is Map ? raw : const {});
    planarState['sandLavaReceipts'] = value;
    return value;
  }

  bool sandLavaPacketAlreadyResolved(String? packetId) =>
      isSandGiant &&
      packetId != null &&
      packetId.isNotEmpty &&
      sandLavaReceipts.containsKey(packetId);

  ({int hp, String? receiptId}) resolveSandLavaHit({
    required int hpBefore,
    required int hpAfter,
    required String element,
    required bool doubleCritical,
    required bool criticalProtected,
    String? packetId,
    int? percentile,
  }) {
    if (!isSandGiant ||
        !doubleCritical ||
        oculumNormalizeElementId(element) != 'lava') {
      return (hp: hpAfter, receiptId: null);
    }
    final id = packetId == null || packetId.isEmpty
        ? 'manual-sand-hit:${DateTime.now().microsecondsSinceEpoch}:'
              '${Random.secure().nextInt(1 << 30)}'
        : packetId;
    if (sandLavaReceipts.containsKey(id)) {
      return (hp: hpAfter, receiptId: null);
    }
    final eligible = !criticalProtected && hpBefore > 0 && hpAfter < hpBefore;
    final roll = eligible && hpAfter > 0
        ? percentile ?? Random.secure().nextInt(100)
        : null;
    final killed =
        roll != null &&
        oculumSandVitrificationSucceeds(
          roll,
          readIntValue(sandRules['lavaKillPercent'], fallback: 50),
        );
    sandLavaReceipts[id] = {
      'eligible': eligible,
      'roll': roll,
      'vitrified': killed,
      'hpBefore': hpBefore,
      'hpAfterNormalDamage': hpAfter,
      'matterUntilTurn':
          playerReportedTurn +
          max(1, readIntValue(sandRules['matterDurationTurns'], fallback: 3)),
      'matterDivisor': max(
        1,
        readIntValue(sandRules['matterDivisor'], fallback: 2),
      ),
    };
    programmaSalvataggio();
    return (hp: killed ? 0 : hpAfter, receiptId: id);
  }

  // The ordinary pipeline may still save the character through safeHP or a
  // native revival. Decide the survivor penalty only after those protections;
  // a later resurrection must not inherit a penalty from a lethal old hit.
  void finishSandLavaHit(String? receiptId, int finalHp) {
    if (receiptId == null) return;
    final receipt = sandLavaReceipts[receiptId];
    if (receipt is! Map || receipt['settled'] == true) return;
    receipt['settled'] = true;
    receipt['finalHp'] = finalHp;
    receipt['survived'] = finalHp > 0;
    if (receipt['eligible'] == true && finalHp > 0) {
      planarState['sandMatterUntilTurn'] = readIntValue(
        receipt['matterUntilTurn'],
      );
      planarState['sandMatterDivisor'] = readIntValue(
        receipt['matterDivisor'],
        fallback: 2,
      );
      invalidateDerivedDataCaches();
      aggiungiLog(
        '[VETRIFICAZIONE] Il Gigante sopravvive${receipt['vitrified'] == true ? ' grazie alla sua protezione' : ''}: '
        'Materia divisa per ${receipt['matterDivisor']} fino al turno personale ${receipt['matterUntilTurn']}.',
      );
    } else if (receipt['vitrified'] == true && finalHp <= 0) {
      aggiungiLog(
        '[VETRIFICAZIONE] Il doppio critico Lava trasforma il Gigante in vetro.',
      );
    }
    programmaSalvataggio();
  }

  int sandAdjustedMatter(int normal) =>
      isSandGiant &&
          readIntValue(planarState['sandMatterUntilTurn']) > playerReportedTurn
      ? max(0, normal) ~/
            max(1, readIntValue(planarState['sandMatterDivisor'], fallback: 2))
      : normal;

  void tickSandTurn() {
    if (readIntValue(planarState['sandMatterUntilTurn']) <=
        playerReportedTurn) {
      planarState.remove('sandMatterUntilTurn');
      planarState.remove('sandMatterDivisor');
    }
  }

  void resetSandFight() {
    planarState.remove('sandTail');
    planarState.remove('sandMatterUntilTurn');
    planarState.remove('sandMatterDivisor');
    // Completed hit receipts survive fight changes and JSON replay.
  }
}
