part of '../../main.dart';

const _oculiathPendingScratches = 'oculiathPendingScratches';
const _oculiathScratchTurn = 'oculiathScratchTurn';
int oculumOculiathScratchDamage(int roll, int grade) =>
    roll >= 1 && roll <= 9 ? roll * max(0, grade) : 0;

extension _OculumOculiathScratches on _OculumHomePageState {
  void startOculiathScratchTurn(Map<String, dynamic> token, int round) {
    if (!mounted ||
        realtimeService?.isConnected == true && !realtimeIsMasterRole ||
        token['temporaryTurn'] == true ||
        token['duplicateAction'] == true ||
        token['outsideFight'] == true ||
        masterInitiativeTokenIsDowned(token) ||
        masterInitiativeTokenIsDead(token)) {
      return;
    }
    final target = publicInitiativeSourceTag(token);
    final index = localSheetIndexForOculumTag(target);
    if (index < 0 || !controlsOnlineCombatSheet(target)) return;
    final carrier = oculiathCarrierHolding(target);
    if (carrier == null ||
        carrier['outsideFight'] == true ||
        masterInitiativeTokenIsDead(carrier)) {
      return;
    }
    final hold = oculiathHoldFor(carrier);
    final encounter = selectedMasterInitiativeGroupId;
    if (hold == null ||
        hold['fight'] != encounter ||
        hold['scope'] != permissionScope) {
      return;
    }
    final holdId = '${hold['id'] ?? ''}';
    final previous = token[_oculiathScratchTurn];
    if (holdId.isEmpty ||
        previous is Map &&
            previous['hold'] == holdId &&
            readIntValue(previous['round'], fallback: -1) >= round) {
      return;
    }
    token[_oculiathScratchTurn] = {'hold': holdId, 'round': round};
    final grade = masterInitiativeTokenGrade(carrier);
    if (grade == 0) return;

    final source = publicInitiativeSourceTag(carrier);
    final id = 'oculiath-scratch:$holdId:$round';
    final roll = Random.secure().nextInt(9) + 1;
    final runtime = index == schedaCorrente
        ? planarState
        : Map<String, dynamic>.from(
            schedePersonaggio[index]['planarRuntime'] as Map? ?? const {},
          );
    final pending = Map<String, dynamic>.from(
      runtime[_oculiathPendingScratches] as Map? ?? const {},
    );
    pending.putIfAbsent(
      id,
      () => {
        'campaign': activeCampaignId,
        'scope': permissionScope,
        'encounter': encounter,
        'instance': combatSubtraitExperienceFightId(
          encounter,
          ownerTag: target,
        ),
        'source': source,
        'grade': grade,
        'level': masterInitiativeTokenLevel(carrier),
        'roll': roll,
      },
    );
    runtime[_oculiathPendingScratches] = pending;
    if (index != schedaCorrente) {
      schedePersonaggio[index]['planarRuntime'] = runtime;
    }
    programmaSalvataggio(invalidateCaches: false);
    scheduleOculiathDamageDrain();
  }

  void scheduleOculiathDamageDrain() {
    if (_oculiathFallDrainActive[this] == true ||
        realtimeService?.isConnected == true && !realtimeIsMasterRole) {
      return;
    }
    _oculiathFallDrainActive[this] = true;
    final campaign = activeCampaignId;
    unawaited(
      Future<void>.delayed(Duration.zero, () async {
        try {
          final queued = <(String, String)>[];
          for (var index = 0; index < schedePersonaggio.length; index++) {
            final runtime = index == schedaCorrente
                ? planarState
                : schedePersonaggio[index]['planarRuntime'] as Map?;
            final pending = runtime?[_oculiathPendingScratches];
            if (pending is! Map) continue;
            final tag = sheetTagAt(index);
            for (final entry in pending.entries) {
              final row = entry.value;
              if (entry.key is String &&
                  row is Map &&
                  row['campaign'] == campaign &&
                  row['scope'] == permissionScope) {
                queued.add((tag, entry.key as String));
              }
            }
          }
          for (final (tag, id) in queued) {
            if (!mounted || activeCampaignId != campaign) return;
            await _applyPendingOculiathScratch(tag, id);
          }
          if (mounted && activeCampaignId == campaign) {
            await _drainOculiathFalls();
          }
        } finally {
          _oculiathFallDrainActive[this] = null;
        }
      }),
    );
  }

  Future<void> _applyPendingOculiathScratch(String tag, String id) async {
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0 || !controlsOnlineCombatSheet(tag)) return;
    final previous = schedaCorrente;
    final previousTag = sheetTagAt(previous);
    final campaign = activeCampaignId;
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    try {
      if (index != previous) {
        schedaCorrente = index;
        caricaStatoDaJson(schedePersonaggio[index]);
        ripristinaImpostazioniGlobali(global);
      }
      if (pawnPendingDamage.isNotEmpty) return;
      final pending = Map<String, dynamic>.from(
        planarState[_oculiathPendingScratches] as Map? ?? const {},
      );
      final row = pending[id];
      if (row is! Map ||
          row['campaign'] != campaign ||
          row['scope'] != permissionScope) {
        return;
      }
      final encounter = '${row['encounter'] ?? ''}';
      if (encounter != onlineCombatEncounterId) return;
      final fight = referenceTurnEncounter();
      final validFight =
          fight['fightStarted'] == true &&
          fight['combatEnded'] != true &&
          row['instance'] ==
              combatSubtraitExperienceFightId(encounter, ownerTag: tag);

      pending.remove(id);
      if (pending.isEmpty) {
        planarState.remove(_oculiathPendingScratches);
      } else {
        planarState[_oculiathPendingScratches] = pending;
      }
      salvaSchedaCorrenteInMemoria();
      programmaSalvataggio(invalidateCaches: false);
      if (!validFight || hpCorrenti() <= 0) return;

      final grade = readIntValue(row['grade']);
      final roll = readIntValue(row['roll']);
      final damage = oculumOculiathScratchDamage(roll, grade);
      if (damage <= 0) return;
      final friendly = _friendlyFireFor({
        'sourceTag': row['source'],
        'targetTag': tag,
      });
      final element = incomingDamageElement;
      incomingDamageElement = 'taglio';
      try {
        aggiungiLog('[UNCINO] Graffi: 1d9 ($roll) × Grado $grade.');
        await applicaDannoSubito(
          dannoEsplicito: damage,
          damagePacketId: id,
          enemyLevel: readIntValue(row['level']),
          enemyGrade: grade,
          attackKind: 'taglio',
          friendlyFire: friendly.friendly,
          friendlyFireResisted: friendly.resisted,
        );
      } finally {
        if (mounted &&
            activeCampaignId == campaign &&
            sheetTagAt(schedaCorrente) == tag) {
          incomingDamageElement = element;
          salvaSchedaCorrenteInMemoria();
        }
      }
    } finally {
      if (mounted &&
          activeCampaignId == campaign &&
          sheetTagAt(schedaCorrente) == tag &&
          previousTag != tag) {
        final restore = localSheetIndexForOculumTag(previousTag);
        if (restore >= 0) {
          final updated = catturaImpostazioniGlobali();
          schedaCorrente = restore;
          caricaStatoDaJson(schedePersonaggio[restore]);
          ripristinaImpostazioniGlobali(updated);
        }
      }
    }
  }
}
