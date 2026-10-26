part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

ArtSkill oculumProvokerShieldSkill() {
  const costs = [5, 10, 20];
  const chances = [60, 75, 90];
  const shields = [30, 40, 60];
  const percents = [50, 75, 100];
  String description(int i) =>
      '${const ['I', 'II', 'III'][i]}/Richiede livello ${i * 3}. '
      'Per 3 turni: ${chances[i]}% di attirare gli attacchi nemici, '
      '+${5 * (i + 1)} Difesa e ${shields[i]} × livello Scudo del provocatore. '
      'Quando un colpo rompe questa barriera, riflette il ${percents[i]}% '
      'dei danni assorbiti da quel colpo più il ${percents[i]}% della tua statistica Danni. '
      'Costo ${costs[i]} Oculum, CD 3 turni. Una nuova attivazione sostituisce la barriera precedente.';
  return ArtSkill(
    nome: 'Scudo del provocatore',
    evo1: description(0),
    evo2: description(1),
    evo3: description(2),
    tipiPerLivello: List.filled(5, 'Attiva · Difesa'),
    risorseCostoPerLivello: List.filled(5, 'oculum'),
    oculumMinimiPerLivello: [...costs, 0, 0],
    oculumMassimiPerLivello: [...costs, 0, 0],
    cooldownPerLivello: List.generate(
      5,
      (_) => OculumAbilityCooldown(amount: 3),
    ),
    effettiPerLivello: [
      for (var i = 0; i < 3; i++)
        [
          OculumStructuredEffect(
            id: 'provoker_shield_$i',
            type: 'planar',
            target: 'provoker_shield',
            valueExpression: '${shields[i]}*livello',
            duration: '3',
            recipient: 'se_stesso',
            customDisplayText: 'Scudo del provocatore',
          ),
          OculumStructuredEffect(
            id: 'provoker_chance_$i',
            type: 'planar',
            target: 'provoker_chance',
            valueExpression: '${chances[i]}',
            duration: '3',
            recipient: 'se_stesso',
            customDisplayText: 'Probabilità di attirare gli attacchi (%)',
          ),
          OculumStructuredEffect(
            id: 'provoker_reflection_$i',
            type: 'planar',
            target: 'provoker_reflection',
            valueExpression: '${percents[i]}',
            duration: '3',
            recipient: 'se_stesso',
            customDisplayText:
                'Quota riflessa di Scudo assorbito e Danni personali (%)',
          ),
          OculumStructuredEffect(
            id: 'provoker_defense_$i',
            type: 'difesa',
            target: 'difesa',
            valueExpression: '${5 * (i + 1)}',
            duration: '3',
            mode: 'temporaneo',
            recipient: 'se_stesso',
          ),
        ],
    ],
  );
}

int oculumProvokerReflection(int absorbed, int personalDamage, int percent) =>
    ((max(0, absorbed) + max(0, personalDamage)) * percent.clamp(0, 100) / 100)
        .floor();

extension _OculumProvokerShield on _OculumHomePageState {
  bool get provokerActive =>
      readIntValue(planarState['provokerTurns']) > 0 &&
      readIntValue(planarState['provokerShield']) > 0;

  bool activateProvokerEffect(
    OculumStructuredEffect effect,
    int value,
    int duration,
  ) {
    if (!effect.target.startsWith('provoker_')) return false;
    switch (effect.target) {
      case 'provoker_shield':
        planarState['provokerShield'] = max(0, value);
        planarState['provokerTurns'] = max(1, duration);
        planarState.remove('provokerPendingReflection');
        break;
      case 'provoker_chance':
        planarState['provokerChance'] = value.clamp(0, 100);
        break;
      case 'provoker_reflection':
        planarState['provokerReflectionPercent'] = value.clamp(0, 100);
        break;
      default:
        return false;
    }
    unawaited(publishProvokerState());
    return true;
  }

  int absorbProvokerShield(int damage, {bool bypassShields = false}) {
    if (!provokerActive || bypassShields || damage <= 0) return damage;
    final before = readIntValue(planarState['provokerShield']);
    final absorbed = min(before, damage);
    planarState['provokerShield'] = before - absorbed;
    if (absorbed == before) {
      final reflected = oculumProvokerReflection(
        absorbed,
        dannoTotale(),
        readIntValue(planarState['provokerReflectionPercent']),
      );
      planarState['provokerPendingReflection'] = reflected;
      aggiungiLog(
        '[SCUDO DEL PROVOCATORE] Barriera rotta: $absorbed Danni assorbiti dal colpo; $reflected Danni riflessi all’attaccante, con le normali Difesa e protezioni.',
      );
    } else {
      aggiungiLog(
        '[SCUDO DEL PROVOCATORE] Assorbiti $absorbed Danni; restano ${before - absorbed}.',
      );
    }
    unawaited(publishProvokerState());
    return damage - absorbed;
  }

  void tickProvokerShield() {
    if (readIntValue(planarState['provokerTurns']) <= 0) return;
    planarState['provokerTurns'] =
        readIntValue(planarState['provokerTurns']) - 1;
    if (readIntValue(planarState['provokerTurns']) == 0) {
      planarState['provokerShield'] = 0;
    }
    unawaited(publishProvokerState());
  }

  Future<void> publishProvokerState() async {
    final tag = sheetTagAt(schedaCorrente);
    final payload = permissionEnvelope({
      'id': 'provoker:$tag:${DateTime.now().microsecondsSinceEpoch}',
      'provokerEvent': true,
      'scope': permissionScope,
      'encounterId': onlineCombatEncounterId,
      'sourceTag': tag,
      'chance': provokerActive
          ? readIntValue(planarState['provokerChance'])
          : 0,
      'shield': provokerActive
          ? readIntValue(planarState['provokerShield'])
          : 0,
      'turns': provokerActive ? readIntValue(planarState['provokerTurns']) : 0,
      'cloudLifeActive': planarCloudForm,
    });
    receiveProvokerState(payload);
    await realtimeService?.sendCombatEvent('combat_scout', payload);
  }

  void receiveProvokerState(Map<String, dynamic> payload) {
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
    token['provokerChance'] = readIntValue(payload['chance']).clamp(0, 100);
    token['provokerShield'] = max(0, readIntValue(payload['shield']));
    token['provokerTurns'] = max(0, readIntValue(payload['turns']));
    token['cloudLifeActive'] = payload['cloudLifeActive'] == true;
    if (escapeAuthority) {
      captureActiveMasterInitiativeGroup();
      sendRealtimeInitiativeSnapshotIfPublished();
    }
    if (mounted) setState(() {});
  }

  OculumAttackPlan redirectProvokedAttack(
    OculumAttackPlan plan, {
    int? percentile,
  }) {
    final own = sheetTagAt(schedaCorrente);
    final side = combatScoutSide(own);
    if (combatScoutSide(plan.targetId) == side) return plan;
    if (faunaCurrentMonsterId.isNotEmpty) {
      final clouds = onlineAttackTokens()
          .where(
            (t) =>
                t['cloudLifeActive'] == true &&
                combatScoutSide(onlineCombatTokenTag(t)) != side,
          )
          .toList();
      if (clouds.isNotEmpty &&
          !plan.targetIds.any(
            (tag) => clouds.any((t) => onlineCombatTokenTag(t) == tag),
          )) {
        final cloud = clouds.first;
        aggiungiLog(
          '[VITA DI UNA NUVOLA] Il mostro è attirato da ${cloud['name']}.',
        );
        return OculumAttackPlan(
          onlineCombatTokenTag(cloud),
          plan.choiceId,
          plan.reason,
          additionalTargetIds: plan.additionalTargetIds,
          element: plan.element,
        );
      }
    }
    final candidates =
        onlineAttackTokens()
            .where(
              (t) =>
                  combatScoutSide(onlineCombatTokenTag(t)) != side &&
                  readIntValue(t['provokerTurns']) > 0 &&
                  readIntValue(t['provokerShield']) > 0 &&
                  readIntValue(t['provokerChance']) > 0,
            )
            .toList()
          ..sort(
            (a, b) => readIntValue(
              b['provokerChance'],
            ).compareTo(readIntValue(a['provokerChance'])),
          );
    if (candidates.isEmpty) return plan;
    final target = candidates.first,
        tag = onlineCombatTokenTag(candidates.first);
    if (plan.targetIds.contains(tag)) return plan;
    final chance = readIntValue(target['provokerChance']).clamp(0, 100);
    final roll = percentile ?? Random.secure().nextInt(100);
    aggiungiLog(
      '[PROVOCAZIONE] ${target['name']}: ${roll + 1}/100, probabilità $chance% · ${roll < chance ? 'attacco attirato' : 'bersagli confermati'}.',
    );
    return roll < chance
        ? OculumAttackPlan(
            tag,
            plan.choiceId,
            plan.reason,
            additionalTargetIds: plan.additionalTargetIds,
            element: plan.element,
          )
        : plan;
  }

  Widget provokerShieldStatus() => !provokerActive
      ? const SizedBox.shrink()
      : ListTile(
          leading: const Icon(Icons.shield),
          title: Text(
            'Scudo del provocatore · ${planarState['provokerShield']}',
          ),
          subtitle: Text(
            '${planarState['provokerTurns']} turni · ${planarState['provokerChance']}% provocazione',
          ),
        );
}
