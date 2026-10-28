part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const _planarSelfRules = <String, String>{
  'rock_cloud_punch': 'golem_best_element',
  'cycle_lunar_bite': 'cycle_lunar_bite',
  'rock_shield_scales': 'rock_scales',
  'rock_shield_pressure': 'pressure',
  'rock_shield_blade': 'blade_recoil',
  'rock_shield_super_armor': 'super_armor',
  'air_navigator_float': 'flight',
  'air_navigator_vanish': 'vanish',
  'rock_cloud_max_power': 'max_power',
  'cloud_beast_lightning': 'lightning_charge',
  'topino_backstep': 'backstep',
  'ogle_split': 'illusion_copies',
  'rock_eater': 'eat_rock',
  'rocket_flight': 'rocket_flight',
};
const _planarTargetRules = <String, String>{
  'cloud_beast_tornado': 'critical_stun',
  'cloud_beast_prison': 'cloud_prison',
  'lightning_skull_claws': 'critical_aphonia',
  'lightning_skull_cloud': 'critical_stun',
  'air_navigator_claws': 'disorient',
  'rock_cloud_barrier': 'barrier',
  'bell_fate_paralysis': 'bell_paralysis',
  'topino_poison_knife': 'poison_knife',
  'illusion_stun': 'critical_stun',
  'psycho_bark': 'disorient',
};
List<List<OculumStructuredEffect>>? oculumPlanarSkillEffects(
  String id,
  List<List<OculumStructuredEffect>>? base,
) {
  final own = _planarSelfRules[id];
  final target = _planarTargetRules[id];
  if (own == null &&
      target == null &&
      id != 'cura_topesca' &&
      id != 'obliterated_devil_annihilation') {
    return base;
  }
  return List.generate(
    3,
    (form) => [
      if (base != null &&
          !const {
            'rock_shield_scales',
            'air_navigator_float',
            'air_navigator_vanish',
            'cloud_beast_lightning',
            'cura_topesca',
            'rock_cloud_barrier',
            'topino_backstep',
          }.contains(id))
        ...base[form].where(
          (e) =>
              (target == null || e.type != 'stato') &&
              !(id == 'rock_shield_blade' && e.type == 'difesa'),
        ),
      if (own != null)
        OculumStructuredEffect(
          id: 'planar:$id:$form',
          type: 'planar',
          target: own,
          valueExpression: own == 'flight'
              ? '3'
              : id == 'topino_backstep'
              ? 'oculum_spent*${form + 1}'
              : '${form + 1}',
          duration:
              '${own == 'rock_scales'
                  ? 0
                  : own == 'flight'
                  ? 0
                  : 3}',
          diceExpression: own == 'rock_scales'
              ? '1d3'
              : own == 'flight'
              ? '1d4'
              : '',
          diceDestination: 'durata',
        ),
      if (target != null)
        OculumStructuredEffect(
          id: 'planar:$id:$form',
          type: 'planar',
          target: target,
          valueExpression: '${form + 1}',
          recipient: target == 'barrier' ? 'se_stesso' : 'nemico',
          duration: target == 'bell_paralysis'
              ? '4'
              : target == 'critical_aphonia'
              ? '3'
              : '1',
        ),
      if (id == 'cura_topesca')
        OculumStructuredEffect(
          id: 'planar:party_heal:$form',
          type: 'cura',
          resource: 'vita',
          valueExpression: 'oculum_spent*${form + 1}',
          recipient: 'alleato',
          minimumTargets: 1,
          maximumTargets: 999,
        ),
      if (id == 'obliterated_devil_annihilation')
        OculumStructuredEffect(
          id: 'planar:annihilation:$form',
          type: 'planar',
          target: 'annihilation',
          valueExpression: '30',
          recipient: 'nemico',
          duration: '3',
        ),
    ],
  );
}

List<String> oculumRabbitHatHits(List<String> selected, int stage) {
  final targets = selected.toSet().take(3).toList();
  if (targets.isEmpty) return [];
  return [
    for (var hit = 0; hit < stage.clamp(1, 3); hit++)
      targets[hit % targets.length],
  ];
}

int oculumRabbitHatDamage(int base, int distinctBefore, int repeatBefore) =>
    (max(0, base) *
            (1 + .25 * max(0, distinctBefore) + .30 * max(0, repeatBefore)))
        .floor();
int oculumRabbitHatRollBonus(int stage) =>
    const [-2, 1, 5][stage.clamp(1, 3) - 1];
bool oculumRabbitHatAdapts(int percentile) =>
    percentile >= 0 && percentile < 60;
String oculumRabbitHatElement(
  Map<String, double> multipliers,
  String fallback,
  int percentile, {
  Random? random,
}) {
  if (!oculumRabbitHatAdapts(percentile) || multipliers.isEmpty) {
    return fallback;
  }
  final highest = multipliers.values.reduce(max);
  if (highest <= 1) return fallback;
  final choices = multipliers.keys
      .where((key) => multipliers[key] == highest)
      .toList();
  return choices[(random ?? Random.secure()).nextInt(choices.length)];
}

extension _OculumPlanarRuntime on _OculumHomePageState {
  Map<String, dynamic> get planarState {
    if (schedePersonaggio.isEmpty ||
        schedaCorrente < 0 ||
        schedaCorrente >= schedePersonaggio.length) {
      return {};
    }
    final sheet = schedePersonaggio[schedaCorrente];
    if (sheet['planarRuntime'] is! Map<String, dynamic>) {
      sheet['planarRuntime'] = Map<String, dynamic>.from(
        sheet['planarRuntime'] as Map? ?? {},
      );
    }
    return sheet['planarRuntime'] as Map<String, dynamic>;
  }

  Future<void> controlOblivionMemory(String statId) async {
    const allowed = {
      'resistenza',
      'canalizzazione',
      'memoria',
      'controllo_corporeo',
      'crepa',
    };
    if (!allowed.contains(statId) ||
        readIntValue(planarState['oblivionMemoryStage']) <= 0) {
      return;
    }
    final stat = hiddenEyeStats.where((s) => s.id == statId).firstOrNull;
    if (stat == null || !await spendCombatRollResource() || !mounted) return;
    await tiraSottotrattoOcchio(
      stat,
      resourceAlreadySpent: true,
      actionLabel: 'Controllo Oblio',
      onResolved: (natural, total) {
        if (!mounted) return;
        applyOblivionMemoryControl(total);
        programmaSalvataggio();
      },
    );
  }

  void applyOblivionMemoryControl(int total) {
    final difficulty = max(
      1,
      readIntValue(planarState['oblivionMemoryDifficulty']),
    );
    final before = readIntValue(planarState['oblivionMemoryStage']);
    planarState['oblivionMemoryStage'] =
        (before + (total >= difficulty ? -1 : 1)).clamp(0, 5);
    aggiungiLog(
      '[OBLIO] Controllo $total / DT $difficulty: ${total >= difficulty ? 'resisti' : 'cedi'}, stadio ${planarState['oblivionMemoryStage']}/5.',
    );
  }

  void resolveOblivionMemoryTurn(
    Map<String, dynamic> token, {
    int? percentile,
  }) {
    final index = localSheetIndexForOculumTag(publicInitiativeSourceTag(token));
    final runtime = index == schedaCorrente
        ? planarState
        : index < 0
        ? const {}
        : schedePersonaggio[index]['planarRuntime'] as Map? ?? const {};
    final stage = readIntValue(runtime['oblivionMemoryStage']);
    final lost =
        stage >= 5 && (percentile ?? Random.secure().nextInt(100)) < 50;
    token['oblivionMemoryReactionLost'] = lost;
    if (stage >= 5) {
      aggiungiLog(
        lost
            ? 'cosa stavo facendo?'
            : '[OBLIO] ${token['name']}: Reazione mantenuta.',
      );
    }
  }

  void resolveSaltalungoTail(Map<String, dynamic> request, int hpLost) {
    if (hpLost <= 0 ||
        criticalShieldBlocksDebuffs(request) ||
        readIntValue(request['natural']) < 20 ||
        request['targetWeakPointPrecision'] != true ||
        monsterLootSourceForSheet(schedePersonaggio[schedaCorrente])?.id !=
            'saltalungo_maculato' ||
        planarState['saltalungoTailBroken'] == true) {
      return;
    }
    planarState['saltalungoTailBroken'] = true;
    final reflex = hiddenEyeStats.where((s) => s.id == 'riflessi').firstOrNull;
    if (reflex != null) reflex.valore -= 6;
    activeStructuredEffects.add({
      'effectId': 'saltalungo_tail_initiative',
      'source': 'Coda distrutta',
      'type': 'modifica_sottotratto',
      'mode': 'aumento',
      'target': 'iniziativa',
      'value': -3,
      'remaining': -1,
      'unit': 'turni',
    });
    for (final token in _writableOnlineCombatTokens().where(
      (t) => onlineCombatTokenTag(t) == sheetTagAt(schedaCorrente),
    )) {
      token['reflexes'] = max(0, readIntValue(token['reflexes']) - 6);
      token['initiativeBase'] = readIntValue(token['initiativeBase']) - 3;
      token['initiativeTotal'] = readIntValue(token['initiativeTotal']) - 3;
    }
    invalidateDerivedDataCaches();
    sendRealtimeInitiativeSnapshotIfPublished();
    aggiungiLog(
      '[CODA] Saltalungo: Riflessi −6, Iniziativa −3 fino a fine scontro.',
    );
  }

  ({int rolled, int restored, int temporary}) rechargePlasmaMatter(
    int form, {
    int? rolled,
  }) {
    final index = form.clamp(1, 3) - 1;
    final amount =
        rolled ??
        (Random.secure().nextInt(const [4, 8, 12][index]) +
            1 +
            const [0, 3, 6][index]);
    final before = max(0, leggiNumero(currentMateriaController));
    final maximum = max(0, materiaMassimoNaturale());
    final restored = min(max(0, maximum - before), amount);
    final temporary = max(0, amount - restored) ~/ 2;
    currentMateriaController.text = '${before + restored}';
    planarState['plasmaTemporaryMatter'] =
        readIntValue(planarState['plasmaTemporaryMatter']) + temporary;
    invalidateDerivedDataCaches();
    aggiungiLog(
      '[RICARICA] +$restored Materia, +$temporary temporanea (eccesso dimezzato per difetto), tiro $amount. La temporanea si spende prima e scade a fine scontro.',
    );
    programmaSalvataggio();
    return (rolled: amount, restored: restored, temporary: temporary);
  }

  bool grantDollSpringReaction(int chance, {int? percentile}) {
    if (totalPowerExhausted) return false;
    final success =
        (percentile ?? Random.secure().nextInt(100)) < chance.clamp(0, 100);
    if (success) {
      unawaited(
        requestUtilitySpend(
          'speed_grant_fast',
          preferFreeReaction: false,
        ).then((_) => flushPendingCombatTurnResources()),
      );
    }
    aggiungiLog(
      '[MOLLA] ${success ? 'Reazione veloce extra ottenuta' : 'Nessuna Reazione veloce extra'} · probabilità $chance%.',
    );
    return success;
  }

  bool get rabbitHatReady => readIntValue(planarState['rabbitHatStage']) > 0;
  Future<void> useRabbitHat({bool charge = false, bool release = false}) async {
    if (!rabbitHatReady) return;
    final tag = sheetTagAt(schedaCorrente);
    final tokens = onlineCombatTokens();
    final active = _usesLocalMasterInitiative
        ? masterInitiativeActiveIndex
        : readIntValue(realtimeVisibleInitiativeSnapshot['activeIndex']);
    final ownTurn =
        !currentTurnTrackerIsActive() ||
        active >= 0 &&
            active < tokens.length &&
            onlineCombatTokenTag(tokens[active]) == tag;
    final origin = currentSheetScrollId();
    final sameAction =
        readIntValue(planarState['rabbitHatPaidTurn'], fallback: -1) ==
        playerReportedTurn;
    if (!ownTurn && !(release && !charge && sameAction)) {
      aggiungiLog('[CAPPELLO] Caricare richiede la tua Azione nel tuo turno.');
      return;
    }
    if ((charge || !sameAction) &&
        !await requestUtilitySpend('azione', preferFreeReaction: false)) {
      return;
    }
    if (!mounted || currentSheetScrollId() != origin) return;
    if (charge) {
      planarState['rabbitHatStage'] = min(
        3,
        readIntValue(planarState['rabbitHatStage']) + 1,
      );
    }
    planarState['rabbitHatPaidTurn'] = playerReportedTurn;
    final stage = readIntValue(planarState['rabbitHatStage']);
    aggiungiLog(
      '[CAPPELLO] ${const ['Instabile', 'Stabile', 'Perfetto'][stage - 1]}: ${oculumRabbitHatRollBonus(stage)} al tiro. Lancio incluso nell’Azione.',
    );
    if (release) {
      await planOnlineAttack(
        resourceAlreadySpent: true,
        rabbitHat: true,
        maximumTargets: 3,
      );
    }
    programmaSalvataggio();
    if (mounted) setState(() {});
  }

  Future<void> escapeRabbitChains(String statId) async {
    if (planarState['rabbitChains'] != true) return;
    final stat = hiddenEyeStats.where((s) => s.id == statId).firstOrNull;
    if (stat == null || !await spendCombatRollResource() || !mounted) return;
    await tiraSottotrattoOcchio(
      stat,
      resourceAlreadySpent: true,
      actionLabel: 'Liberati dalle catene',
      onResolved: (natural, total) {
        final difficulty = readIntValue(planarState['rabbitChainsDifficulty']);
        if (total >= difficulty) {
          planarState.remove('rabbitChains');
          final condition = getCondition('immobilizzato');
          if (condition != null) removeCondition(condition, force: true);
          aggiungiLog('[CATENE] $total / DT $difficulty: libero.');
        } else {
          aggiungiLog('[CATENE] $total / DT $difficulty: ancora intrappolato.');
        }
        programmaSalvataggio();
      },
    );
  }

  bool hasPlanarTechnique(String id) {
    final text = oculumPlanarTechnique(id)?.name;
    if (text == null) return false;
    return skills.any((s) => s.equipaggiata && s.nome == text) ||
        arti.any((a) => a.skills.any((s) => s.nome == text));
  }

  bool get planarCharging =>
      readIntValue(planarState['chargeNeeded']) >
      readIntValue(planarState['chargeSteps']);
  bool get planarCloudForm => planarState['cloudLifeActive'] == true;
  int planarResilienceBonus(int normal) =>
      planarState['maxPower'] == true ? normal : 0;
  int planarAttackRollBonus() =>
      (faunaCurrentMonsterId == 'ciclo_gigante_goblin' ? -5 : 0) +
      deadlySwordHitBonus +
      (faunaCurrentMonsterId == 'torretta_oculum' ? 9 : 0) +
      readIntValue(planarState['attackRollBonus']) +
      (maskedShadowActive ? 5 : 0) +
      (planarState['maskedTeleport'] == true ? 9 : 0);
  int planarDefenseRollBonus() =>
      readIntValue(planarState.remove('defenseRollBonus')) +
      readIntValue(planarState['defenseRollPenalty']) +
      (maskedShadowActive ? 5 : 0) +
      (planarState['maskedTeleport'] == true ? 10 : 0);
  void activatePlanarEffect(
    OculumStructuredEffect effect,
    int value,
    int duration,
    String source,
  ) {
    final state = planarState;
    if (effect.target == 'lusier_condition_guard') return;
    if (effect.target == 'lusier_solar_vitalium') {
      grantLusierSolarVitalium();
      return;
    }
    if (activateSenkaEffect(effect, value)) return;
    if (activateReferenceCreatureEffect(effect, value, duration, source)) {
      return;
    }
    if (activateTotalPowerEffect(effect, value, duration)) return;
    if (activateProvokerEffect(effect, value, duration)) return;
    if (activateCycleEffect(effect, value)) return;
    if (effect.target == 'deadly_empowered') {
      state['deadlyEmpoweredTurns'] = max(1, duration);
      state['deadlyEmpoweredForm'] = value;
      return;
    }
    if (effect.target == 'deadly_regen') {
      unawaited(deadlyRegenerate());
      return;
    }
    if (effect.target == 'deadly_weapon') {
      changeDeadlyWeaponForm(value);
      return;
    }
    if (effect.target == 'puppet_attack_bonus') {
      state['attackRollBonus'] = readIntValue(state['attackRollBonus']) + value;
      return;
    }
    if (effect.target == 'laer_sword') {
      state['laerSword'] = true;
      return;
    }
    if (effect.target == 'laer_twist' || effect.target == 'next_defense_roll') {
      state['defenseRollBonus'] =
          readIntValue(state['defenseRollBonus']) + value;
      return;
    }
    if (effect.target == 'monk_ki') {
      unawaited(activateMortalKi());
      return;
    }
    if (effect.target == 'monk_seal') {
      state['mortalKiLock'] = max(1, duration);
      aggiungiLog(
        '[È GIUNTA LA TUA ORA] Ki Mortale e Oculum non utilizzabili per un turno; le risorse restano conservate.',
      );
      return;
    }
    if (effect.target == 'bone_four_slash') {
      state['boneFourSlash'] = max(0, value);
      return;
    }
    if (effect.target == 'ogor_restore') {
      restoreOgorEnergy();
      return;
    }
    if (effect.target == 'teirak_aphonia') {
      applyCondition('vita_afona', duration: 3, source: 'Rune di Teirak');
      aggiungiLog('Le rune velano la tua Vitalità: non riesci a percepirla.');
      return;
    }
    switch (effect.target) {
      case 'feralis_fury':
        startFeralisFury();
        break;
      case 'fuocherelli_reanimate':
        unawaited(commitFaunaReanimation());
        break;
      case 'fuocherelli_critical_fire':
        applyCondition(
          'bruciatura',
          duration: Random.secure().nextInt(4) + 1,
          source: 'Dardo di fuoco',
        );
        break;
      case 'lavastrello_critical_fire':
        applyCondition('bruciatura', duration: 1, source: 'Attacco di Fuoco');
        break;
      case 'gran_leave':
        state['granLeave'] = true;
        state['attackRollBonus'] = readIntValue(state['attackRollBonus']) + 5;
        break;
      case 'gran_cannon':
        state['granCannon'] = true;
        break;
      case 'gran_unstun':
        granRemoveStun();
        break;
      case 'evergreen_leaves':
        activateEvergreenLeaves(value);
        break;
      case 'evergreen_dodge':
        state['evergreenDodge'] = max(1, value);
        break;
      case 'thunderbird_teleport':
        unawaited(useThunderTeleport());
        break;
      case 'thunderbird_claw':
        applyCondition(
          'paralisi_fato',
          duration: 1,
          durationType: OculumConditionDurationType.actions,
          source: 'Artiglio di Fulmine',
        );
        break;
      case 'scostu_punch':
        state['scostuPunch'] = true;
        break;
      case 'scostu_rifle_ammo':
        state['scostuRifleAmmo'] = max(0, value);
        state['scostuRifleHolstered'] = false;
        final disarmed = getCondition('disarmato');
        if (disarmed != null) removeCondition(disarmed, force: true);
        break;
      case 'scostu_rifle_form':
        state['scostuRifleForm'] = value.clamp(1, 3);
        break;
      case 'scostu_breath':
      case 'scostu_recover':
        break;
      case 'bramble_thorn_shield':
        state['brambleShield'] = max(0, value);
        state['brambleShieldTurns'] = max(1, duration);
        break;
      case 'bramble_thorn_retaliation':
        state['brambleRetaliation'] = max(0, value);
        break;
      case 'bramble_arduous_challenge':
        break; // Passive is resolved from the confirmed critical's target.
      case 'mask_serious_punch':
      case 'mask_blue_volley':
      case 'mask_shadow_form':
      case 'mask_shadow_teleport':
      case 'mask_angelic_arrows':
      case 'mask_solar_arrows':
        activateMaskedPower(effect.target, value);
        break;
      case 'mask_vital_memory':
        if (!hasCondition('ricordo_vitale')) {
          applyCondition('ricordo_vitale', source: 'Maschera verde');
        }
        break;
      case 'plasma_matter_recharge':
        rechargePlasmaMatter(value);
        break;
      case 'rabbit_hat':
        state['rabbitHatStage'] = 1;
        state['rabbitHatForm'] = value.clamp(1, 3);
        state['rabbitHatPaidTurn'] = playerReportedTurn;
        aggiungiLog(
          '[CAPPELLO] Instabile pronto (−2). Lancia incluso nell’Azione o conserva la carica per il prossimo turno.',
        );
        break;
      case 'rabbit_chains':
        state['rabbitChains'] = true;
        applyCondition(
          'immobilizzato',
          durationType: OculumConditionDurationType.permanent,
          source: 'Catene runiche: fino a liberazione',
        );
        break;
      case 'doll_spring':
        grantDollSpringReaction(value);
        break;
      case 'oblivion_memory':
        state['oblivionMemoryStage'] = min(
          5,
          readIntValue(state['oblivionMemoryStage']) + max(1, value),
        );
        aggiungiLog(
          '[OBLIO] Memoria incrinata: stadio ${state['oblivionMemoryStage']}/5. Utility: Resistenza, Canalizzazione, Memoria, Controllo corporeo o Crepa.',
        );
        break;
      case 'speed_increase':
        final tag = sheetTagAt(schedaCorrente);
        final token = _writableOnlineCombatTokens()
            .where(
              (token) =>
                  (_usesLocalMasterInitiative
                      ? publicInitiativeSourceTag(token)
                      : onlineCombatTokenTag(token)) ==
                  tag,
            )
            .firstOrNull;
        if (token != null) {
          unawaited(
            requestUtilitySpend(
              value >= 3 ? 'speed_grant_fast' : 'speed_queue_normal',
              preferFreeReaction: false,
            ).then((_) => flushPendingCombatTurnResources()),
          );
          if (_usesLocalMasterInitiative) {
            captureActiveMasterInitiativeGroup();
            sendRealtimeInitiativeSnapshotIfPublished();
          }
          aggiungiLog(
            '[AUMENTO DI VELOCITÀ] ${value >= 3 ? 'Una Reazione veloce disponibile subito' : 'Una Reazione normale extra al prossimo turno personale'}; nessuna Azione o Reazione consumata.',
          );
        }
        break;
      case 'parasite_medicine':
        applyParasiteMedicine(value);
        break;
      case 'backstep':
        state['backstepReduction'] = value;
        break;
      case 'rock_scales':
        state['scalesTurns'] = max(1, duration);
        break;
      case 'super_armor':
        state['armorHits'] = 3;
        break;
      case 'pressure':
        state['attackRollBonus'] = 9;
        break;
      case 'blade_recoil':
        state['defenseRollPenalty'] = -2;
        break;
      case 'flight':
        if (wingsGrounded) {
          aggiungiLog('[ALI] Due ali danneggiate: il volo non è disponibile.');
          break;
        }
        state['flightTurns'] = max(1, duration);
        activeStructuredEffects.removeWhere(
          (e) => '${e['effectId']}'.startsWith('planar_flight_'),
        );
        for (final target in ['difesa', 'movimento']) {
          activeStructuredEffects.add({
            'effectId': 'planar_flight_$target',
            'source': source,
            'type': 'modifica_sottotratto',
            'mode': 'aumento',
            'target': target,
            'value': value,
            'remaining': -1,
            'unit': 'turni',
          });
        }
        break;
      case 'vanish':
        state['vanishTurns'] = 1;
        state['attackRollBonus'] = 3;
        break;
      case 'max_power':
        state['maxPower'] = true;
        schivateOculumBonus += 1;
        break;
      case 'illusion_copies':
        state['illusionCopies'] = min(4, max(1, value + 1));
        state['illusionTurns'] = 2;
        break;
      case 'eat_rock':
        state['rockEatenM3'] =
            readIntValue(state['rockEatenM3']) + min(10, max(1, value) * 3 + 1);
        break;
      case 'rocket_flight':
        state['rocketFlightTurns'] = 2;
        state['rocketFlightMetres'] = 100;
        break;
      case 'lightning_charge':
        state['chargeNeeded'] = max(0, value - 1);
        state['chargeSteps'] = min(1, max(0, value - 1));
        state['chargePower'] = 15 + (value - 1) * 10;
        state['chargeForm'] = value;
        if (value == 1) {
          state['attackRollBonus'] = -3;
          releasePlanarLightning();
        }
        break;
      case 'disorient':
        applyCondition('duello_vc_cm_svantaggio', duration: 1, source: source);
        break;
      case 'critical_stun':
        applyCondition('stordito', duration: 1, source: source);
        break;
      case 'critical_aphonia':
        applyCondition('vita_afona', duration: 3, source: source);
        break;
      case 'cloud_prison':
        applyCondition(
          'immobilizzato',
          duration: max(1, duration),
          source: source,
        );
        state['cloudPrison'] = true;
        break;
      case 'bell_paralysis':
        applyCondition(
          'paralisi_fato',
          duration: max(1, duration),
          source: source,
        );
        break;
      case 'barrier':
        state['barrierPower'] = 6 + max(1, value) * 4;
        state['barrierTurns'] = 3;
        scudoController.text =
            '${leggiNumero(scudoController) + 10 + max(1, value) * 10}';
        break;
      case 'golem_best_element':
        state['golemBestElementPending'] = true;
        break;
      case 'poison_knife':
        applyCondition('avvelenato', duration: 2, source: source);
        break;
      case 'annihilation':
        final existing = titoli
            .where((t) => t.chiaveSistema == 'planar_annihilation')
            .firstOrNull;
        if (existing == null) {
          titoli.add(
            OculumTitle(
              nome: 'Annichilimento',
              tipo: 'Titolo Malanno',
              ottenimento: 'Occhi dell’Annichilimento',
              buff: '@res-30%',
              puntoCieco: '',
              skill: 'La riduzione termina dopo tre Riposi Lunghi.',
              richiede: '',
              equipaggiato: true,
              chiaveSistema: 'planar_annihilation',
            ),
          );
        }
        state['annihilationRests'] = max(1, duration);
        break;
    }
    aggiungiLog(
      '[EFFETTO] $source · ${effect.target}${duration > 0 ? ' · $duration turni' : ''}.',
    );
    invalidateDerivedDataCaches();
    programmaSalvataggio();
  }

  void releasePlanarLightning() {
    final state = planarState;
    if (planarCharging || readIntValue(state['chargePower']) <= 0) return;
    final form = readIntValue(state['chargeForm']);
    activeStructuredEffects.removeWhere(
      (e) => e['effectId'] == 'planar_lightning_damage',
    );
    activeStructuredEffects.add({
      'effectId': 'planar_lightning_damage',
      'source': 'Scarica di fulmini',
      'type': 'danno',
      'mode': 'prossima_azione',
      'target': 'danni',
      'value': readIntValue(state['chargePower']),
      'remaining': 1,
      'unit': 'azioni',
      'element': 'fulmine',
    });
    if (form == 3) state['attackRollBonus'] = 3;
    state.remove('chargeNeeded');
    state.remove('chargeSteps');
    state.remove('chargePower');
    aggiungiLog(
      '[SCARICA DI FULMINI] Pronta: attacca usando Azione nel tuo turno o Reazione fuori turno. Un colpo ricevuto interrompe la carica conservata.',
    );
  }

  Future<bool> continuePlanarCharge() async {
    if (readIntValue(planarState['chargePower']) <= 0) return false;
    if (planarCharging) {
      final resource =
          currentCombatIsActive() &&
              masterInitiativeActiveIndex >= 0 &&
              masterInitiativeActiveIndex < masterInitiativeTokens.length &&
              publicInitiativeSourceTag(
                    masterInitiativeTokens[masterInitiativeActiveIndex],
                  ) ==
                  sheetTagAt(schedaCorrente)
          ? 'azione'
          : 'reazione';
      if (!await requestUtilitySpend(resource)) return false;
      planarState['chargeSteps'] = readIntValue(planarState['chargeSteps']) + 1;
      aggiungiLog(
        '[CARICA] ${planarState['chargeSteps']}/${planarState['chargeNeeded']} · spesa $resource.',
      );
    } else {
      releasePlanarLightning();
    }
    programmaSalvataggio();
    if (mounted) setState(() {});
    return true;
  }

  void tickPlanarTurn() {
    tickTotalPowerExhaustion();
    tickProvokerShield();
    if (readIntValue(planarState['deadlyEmpoweredTurns']) > 0) {
      planarState['deadlyEmpoweredTurns'] =
          readIntValue(planarState['deadlyEmpoweredTurns']) - 1;
    }
    tickBoneRuneTurn();
    tickFeralisFury();
    maskedTurnStart();
    senkaTurnStart();
    meccanioTurn();
    parasiteTurn();
    if (currentCombatIsActive()) refreshChaosStats();
    for (final key in const [
      'scalesTurns',
      'flightTurns',
      'vanishTurns',
      'illusionTurns',
      'rocketFlightTurns',
      'barrierTurns',
      'brambleShieldTurns',
    ]) {
      if (readIntValue(planarState[key]) > 0) {
        planarState[key] = readIntValue(planarState[key]) - 1;
      }
    }
    if (readIntValue(planarState['flightTurns']) <= 0) {
      activeStructuredEffects.removeWhere(
        (e) => '${e['effectId']}'.startsWith('planar_flight_'),
      );
    }
    if (readIntValue(planarState['illusionTurns']) <= 0) {
      planarState.remove('illusionCopies');
    }
  }

  void resetOwnedPlanarFightEffects() {
    if (schedePersonaggio.isEmpty) return;
    salvaSchedaCorrenteInMemoria();
    final original = schedaCorrente;
    final global = catturaImpostazioniGlobali();
    try {
      for (var index = 0; index < schedePersonaggio.length; index++) {
        if (schedePersonaggio[index]['realtimeSharedSheet'] == true) continue;
        if (index != schedaCorrente) {
          schedaCorrente = index;
          caricaStatoDaJson(schedePersonaggio[index]);
          ripristinaImpostazioniGlobali(global);
        }
        resetPlanarFight();
        salvaSchedaCorrenteInMemoria();
      }
    } finally {
      schedaCorrente = original;
      caricaStatoDaJson(schedePersonaggio[original]);
      ripristinaImpostazioniGlobali(global);
    }
  }

  void resetPlanarFight() {
    planarState.remove('provokerShield');
    planarState.remove('provokerTurns');
    planarState.remove('provokerPendingReflection');
    resetCycleFight();
    planarState.remove('deadlyEmpoweredTurns');
    planarState.remove('artWeakPointPenalties');
    planarState.remove('artWeakPointAction');
    resetBoneRuneFight();
    resetCannonEvergreenFight();
    planarState.remove('feralisFury');
    planarState.remove('feralisFuryPaidTurns');
    planarState.remove('feralisFurySkipTick');
    planarState.remove('feralisElementResistance');
    planarState.remove('fuocherelliWaterSuppressedActions');
    resetStormBanditFight();
    resetBrambleFight();
    senkaFightEnd();
    planarState.remove('maskedShadow');
    planarState.remove('maskedTeleport');
    planarState.remove('maskedAttack');
    planarState.remove('maskedAngelicHits');
    resetMeccanioFight();
    if (planarState.remove('saltalungoTailBroken') == true) {
      final reflex = hiddenEyeStats
          .where((s) => s.id == 'riflessi')
          .firstOrNull;
      if (reflex != null) reflex.valore += 6;
      activeStructuredEffects.removeWhere(
        (e) => e['effectId'] == 'saltalungo_tail_initiative',
      );
    }
    if (planarState['posteaImmunityWaitingFight'] != true) {
      planarState.remove('posteaImmuneCondition');
      planarState.remove('posteaImmunityWaitingFight');
    }
    activeStructuredEffects.removeWhere(
      (e) => '${e['effectId']}'.startsWith('planar_flight_'),
    );
    for (final key in const [
      'chaosStats',
      'chaosEncounter',
      'chaosProcAttempts',
      'chaosPenaltyReceipts',
      'chaosAttackAttempts',
      'preparedSkill',
      'rabbitHatStage',
      'rabbitHatForm',
      'rabbitHatPaidTurn',
      'plasmaTemporaryMatter',
      'bringiFirstResponse',
      'bringiHits',
      'maxPower',
      'scalesTurns',
      'flightTurns',
      'vanishTurns',
      'illusionTurns',
      'illusionCopies',
      'armorHits',
      'barrierTurns',
      'barrierPower',
      'chargePower',
      'chargeNeeded',
      'chargeSteps',
      'attackRollBonus',
      'defenseRollPenalty',
    ]) {
      planarState.remove(key);
    }
    invalidateDerivedDataCaches();
  }

  void longRestPlanarEffects() {
    referenceLongRest();
    restoreDamagedWings();
    planarState.remove('banditVendetta');
    for (final token in _writableOnlineCombatTokens().where(
      (t) => onlineCombatTokenTag(t) == sheetTagAt(schedaCorrente),
    )) {
      token['faunaPublic'] = {
        ...Map<String, dynamic>.from(token['faunaPublic'] as Map? ?? {}),
        'banditVendetta': false,
      };
    }
    deadlyLongRest();
    resetOgorCoreRest(long: true);
    planarState.remove('fuocherelliSecondLifeUsed');
    planarState.remove('oblivionMemoryStage');
    planarState.remove('oblivionMemoryDifficulty');
    planarState.remove('oblivionMemoryReactionLost');
    final rests = readIntValue(planarState['annihilationRests']);
    if (rests > 0) {
      planarState['annihilationRests'] = rests - 1;
      if (rests == 1) {
        titoli.removeWhere((t) => t.chiaveSistema == 'planar_annihilation');
        aggiungiLog(
          '[MALANNO] Annichilimento terminato dopo tre Riposi Lunghi.',
        );
      }
    }
    if (planarCloudForm && hpCorrenti() > 0) {
      planarState['cloudLifeActive'] = false;
      planarState.remove('cloudLifeHp');
      currentHpController.text = '${maxHp()}';
      aggiungiLog(
        '[RINASCITA] La nube è sopravvissuta al Riposo Lungo: ritorni alla forma originale.',
      );
    }
    resetPlanarFight();
  }

  int planarModifyIncomingDamage(
    int damage, {
    required String element,
    String attackKind = '',
    bool magical = false,
    bool bypassShields = false,
  }) {
    final state = planarState;
    damage = (damage * silkResistanceMultiplier(element)).round();
    damage = feralisAdaptDamage(damage, element);
    if (senkaMaskActive &&
        magical &&
        oculumNormalizeElementId(element) == 'solare') {
      damage = (damage * 1.15).round();
    }
    if (feralisFuryActive) damage = (damage / 2).ceil();
    if (damage <= 0) return damage;
    damage = brambleAbsorbDamage(damage, element, bypassShields: bypassShields);
    if (maskedShadowActive &&
        const {
          'fisico',
          'taglio',
          'contundente',
          'perforante',
          'fisico_taglio',
          'fisico_contundente',
          'fisico_perforante',
        }.contains(element)) {
      aggiungiLog('[L’OMBRA] Il colpo fisico attraversa la sagoma.');
      return 0;
    }
    final monsterId =
        schedaCorrente >= 0 && schedaCorrente < schedePersonaggio.length
        ? '${schedePersonaggio[schedaCorrente]['monsterBookSourceId'] ?? ''}'
        : '';
    if (monsterId == 'pupazzo_artigliato' &&
        const {
          'spirituale',
          'anima',
          'danno_anima',
          'spirito',
        }.contains(element)) {
      aggiungiLog(
        '[PUPAZZO VUOTO] Nessuna anima o corpo interno: danno spirituale ignorato.',
      );
      return 0;
    }

    if (readIntValue(state['illusionCopies']) > 0) {
      final n = readIntValue(state['illusionCopies']);
      if (Random.secure().nextInt(n + 1) > 0) {
        state['illusionCopies'] = n - 1;
        aggiungiLog('[ILLUSIONE] Il colpo distrugge una copia; nessun danno.');
        return 0;
      }
    }
    final backstep = readIntValue(state.remove('backstepReduction'));
    damage = max(0, damage - backstep);
    if (readIntValue(state['vanishTurns']) > 0 &&
        const {
          'fisico',
          'taglio',
          'contundente',
          'perforante',
        }.contains(element)) {
      return 0;
    }
    if (readIntValue(state['scalesTurns']) > 0) {
      if (!magical && (element == 'taglio' || attackKind == 'taglio')) return 0;
      if (magical || !(element == 'contundente' || attackKind == 'schianto')) {
        damage = (damage + 1) ~/ 2;
      }
    }
    if (readIntValue(state['armorHits']) > 0) {
      state['armorHits'] = readIntValue(state['armorHits']) - 1;
      if (const {
        'fisico',
        'taglio',
        'contundente',
        'perforante',
      }.contains(element)) {
        damage = (damage + 1) ~/ 2;
      }
    }
    if (state['cloudPrison'] == true) {
      state.remove('cloudPrison');
      final held = getCondition('immobilizzato');
      if (held != null) removeCondition(held, force: true);
      applyCondition('stordito', duration: 1, source: 'Nuvola Prigioniera');
    }
    state.remove('chargeNeeded');
    state.remove('chargeSteps');
    state.remove('chargePower');
    activeStructuredEffects.removeWhere(
      (e) => e['effectId'] == 'planar_lightning_damage',
    );
    return damage;
  }

  void planarAfterHpDamage() {
    boneRuneAfterHpDamage();
    if (hpCorrenti() > 0 ||
        planarCloudForm ||
        planarState['cloudLifeUsed'] == true ||
        !hasPlanarTechnique('smiling_storm_cloud_life')) {
      return;
    }
    final hp = max(1, (maxHp() + 1) ~/ 2);
    planarState['cloudLifeHp'] = hp;
    planarState['cloudLifeActive'] = true;
    planarState['cloudLifeUsed'] = true;
    unawaited(publishProvokerState());
    currentHpController.text = '$hp';
    aggiungiLog(
      '[VITA DI UNA NUVOLA] Ti trasformi in nube con $hp Vita. Puoi muoverti, non attaccare. Sopravvivi fino al Riposo Lungo per rinascere.',
    );
  }

  bool planarIsCriticalEffectAllowed(
    Map request,
    OculumStructuredEffect effect,
  ) {
    if (!oculumEffectRequiresCritical(effect)) {
      return true;
    }
    if (criticalShieldBlocksDebuffs(request)) return false;
    return readIntValue(request['natural']) >= 20 ||
        request['forcedCritical'] == true ||
        oculumScostuPacketCritical(request) ||
        oculumAttackIsCritical(
          readIntValue(request['attack']),
          readIntValue(request['defense']),
        );
  }
}

bool oculumEffectRequiresCritical(OculumStructuredEffect effect) =>
    effect.criticalOnly ||
    const {
      'critical_stun',
      'critical_aphonia',
      'annihilation',
      'thunderbird_claw',
      'fuocherelli_critical_fire',
      'lavastrello_critical_fire',
      'teirak_aphonia',
      'meccanio_oltre_difesa',
    }.contains(effect.target) ||
    effect.id == 'meccanio_beyond_defense';

InventoryItem oculumPlanarTechniqueScroll(
  MonsterBookEntry monster,
  String id, {
  required String receipt,
  int level = 0,
  int grade = 0,
}) {
  final technique = oculumPlanarTechnique(id);
  final art = oculumMonsterBookArt(monster.copyWith(skillIds: [id]));
  final skill = art.skills.first;
  final form = (level >= 6
      ? 2
      : level >= 3
      ? 1
      : 0);
  return InventoryItem(
    nome: 'Scroll · ${technique?.name ?? skill.nome}',
    peso: .05,
    quantita: 1,
    gradoOggetto: grade,
    livelloOggetto: level,
    note:
        'Monouso. ${technique?.action ?? skill.evo1} Apprendimento non automatico: segue le regole normali delle scroll.',
    craftData: {
      'scroll': {
        'id': 'planar-scroll:$id:$receipt',
        'name': technique?.name ?? skill.nome,
        'kind': 'technique',
        'authoredSkill': oculumEquipmentAbilityFromArt(skill).toJson(),
        if (technique?.name.contains('· Open') == true)
          'authoredOpen': art.toJson(),
        'grade': grade,
        'skillLevel': (technique?.requiredLevel ?? 0) + form * 3,
        'element': monster.elementId,
        'description': technique?.text() ?? skill.evo1,
        'willCost': max(1, grade + 1),
        'cooldownTurns': technique?.cooldowns[form] ?? 3,
        'effects': skill.effettiPerLivello[form]
            .map((e) => e.toJson())
            .toList(),
      },
    },
    monsterLoot: {
      'id': receipt,
      'monsterId': monster.id,
      'sourceSkillId': id,
      'skill': skill.toJson(),
    },
  );
}

List<InventoryItem>? oculumPlanarNaturalDrops(
  MonsterBookEntry monster,
  int level,
  int grade,
  int natural,
  String killId, {
  String finishingElement = '',
  String finishingSkillId = '',
  Map combatHistory = const {},
  int dropTotal = 0,
}) {
  final id = oculumPartyHuntSpeciesId(monster.id);
  InventoryItem material(String name, double weight) => InventoryItem(
    nome: name,
    note: 'Materiale di ${monster.nameIt}.',
    peso: weight,
    quantita: 1,
    gradoOggetto: grade,
    livelloOggetto: level,
    monsterLoot: {
      'id': '$killId:$name',
      'monsterId': id,
      'material': true,
      'naturalDropRoll': natural,
    },
  );
  if (const {
    'fuocherelli',
    'feralis',
    'granscostumato',
    'sempre_verde',
    'lavastrello',
    'teschio_monaco',
    'teschio_quattro_lame',
    'ogor',
    'teirak',
    'teschio_mostruoso',
    'adoratore_bestia',
    'laer',
    'torretta_oculum',
    'manichino_spada',
    'deadly_sins',
    'zombie_acido',
    'cavaliere_non_ritorno',
  }.contains(monster.id)) {
    final rules = monster.encounterRules['naturalScrollDrops'] as Map? ?? {};
    InventoryItem scroll(String skill) => oculumPlanarTechniqueScroll(
      monster,
      skill,
      receipt: '$killId:$skill',
      level: level,
      grade: grade,
    );
    return [
      if (monster.id == 'deadly_sins' && natural == 20)
        oculumDeadlySinsWeapon(monster, level, grade, killId),
      if (natural >= 8)
        material(
          oculumMonsterDropName(
            monster.dropChances.keys.firstOrNull ?? 'frammento_${monster.id}',
          ),
          .15,
        ),
      for (final entry in rules.entries)
        if (entry.value is Map &&
            natural >= readIntValue(entry.value['minimum']) &&
            natural <= readIntValue(entry.value['maximum']))
          scroll('${entry.key}'),
      if (monster.id == 'sempre_verde' && dropTotal >= 36)
        scroll('evergreen_leaves'),
      if (monster.id == 'teschio_monaco' && dropTotal >= 39)
        scroll('monk_dragon'),
      if (monster.id == 'teschio_quattro_lame' && dropTotal >= 40)
        scroll('bone_four_slash'),
      if (monster.id == 'ogor' && dropTotal >= 46) scroll('ogor_ray'),
      if (monster.id == 'sempre_verde' && combatHistory['soulOnly'] == true)
        InventoryItem(
          nome: 'Costume dei Sempre Verde',
          peso: .8,
          quantita: 1,
          note: 'Costume intatto: i mostri esitano finché non li attacchi.',
          livelloOggetto: level,
          gradoOggetto: grade,
          ability: oculumEquipmentAbilityFromArt(
            oculumMonsterBookArt(
              monster.copyWith(skillIds: ['evergreen_disguise']),
            ).skills.first,
          ),
          monsterLoot: {'id': '$killId:costume', 'monsterId': monster.id},
        ),
      if (monster.id == 'teschio_quattro_lame' &&
          readIntValue(combatHistory['boneBrokenArms']) >= 4)
        InventoryItem(
          nome: 'Spada Osso',
          peso: 1.4,
          quantita: 1,
          note:
              'Lama d’osso pallido con denti minuti sul filo e guardia di vertebre. Piantandola nel terreno evoca spuntoni, fino a quattro nemici.',
          buff: '@vol+2 @res+1',
          arma: true,
          livelloOggetto: level,
          gradoOggetto: grade,
          ability: oculumEquipmentAbilityFromArt(
            oculumMonsterBookArt(
              monster.copyWith(skillIds: ['bone_ground_spikes']),
            ).skills.first,
          ),
          monsterLoot: {'id': '$killId:bone-sword', 'monsterId': monster.id},
        ),
      if (monster.id == 'ogor' &&
          readIntValue(combatHistory['ogorCoreHits']) == 0)
        InventoryItem(
          nome: 'Nucleo di Oculum',
          peso: .35,
          quantita: 1,
          note:
              'Nucleo viola integro di Grado I. Cinque recuperi di 1 Oculum su tiri riusciti per riposo. Si rompe dopo tre colpi al punto debole del portatore.',
          gradoOggetto: 1,
          gradoRichiesto: 1,
          livelloOggetto: level,
          craftData: {
            'ogorCore': true,
            'weakPointHits': 0,
            'successfulRolls': 0,
            'broken': false,
          },
          ability: oculumEquipmentAbilityFromArt(
            oculumMonsterBookArt(
              monster.copyWith(skillIds: ['ogor_core']),
            ).skills.first,
          ),
          monsterLoot: {'id': '$killId:core', 'monsterId': monster.id},
        ),
    ];
  }
  if (monster.id == 'bramble') {
    final rules = monster.encounterRules['naturalScrollDrops'] as Map? ?? {};
    return [
      if (natural >= 8) material('Fibra spinosa di Bramble', .15),
      for (final entry in rules.entries)
        if (entry.value is Map &&
            natural >= readIntValue(entry.value['minimum'], fallback: 20) &&
            natural <= readIntValue(entry.value['maximum'], fallback: 20) &&
            ('${entry.value['finishingElement'] ?? ''}'.isEmpty ||
                oculumNormalizeElementId(finishingElement) ==
                    entry.value['finishingElement']))
          oculumPlanarTechniqueScroll(
            monster,
            '${entry.key}',
            receipt: '$killId:${entry.key}',
            level: level,
            grade: grade,
          ),
    ];
  }
  if (const {'thunderbird', 'scostubanditi'}.contains(monster.id)) {
    final rules = monster.encounterRules['naturalScrollDrops'] as Map? ?? {};
    return [
      if (natural >= 8)
        material(
          monster.id == 'thunderbird'
              ? 'Piuma conduttrice di ThunderBird'
              : 'Ottone del fucile Scostubanditi',
          .15,
        ),
      for (final entry in rules.entries)
        if (entry.value is Map &&
            natural >= readIntValue(entry.value['minimum']) &&
            natural <= readIntValue(entry.value['maximum']) &&
            ('${entry.value['finishingElement'] ?? ''}'.isEmpty ||
                oculumNormalizeElementId(finishingElement) ==
                    entry.value['finishingElement']) &&
            ('${entry.value['finishingSkillId'] ?? ''}'.isEmpty ||
                finishingSkillId == entry.value['finishingSkillId']))
          oculumPlanarTechniqueScroll(
            monster,
            '${entry.key}',
            receipt: '$killId:${entry.key}',
            level: level,
            grade: grade,
          ),
      if (monster.id == 'scostubanditi' &&
          dropTotal >=
              readIntValue(
                monster.encounterRules['rifleDropTotal'],
                fallback: 30,
              ))
        InventoryItem(
          nome: 'Fucile schivata',
          peso: 2.2,
          quantita: 1,
          livelloOggetto: level,
          gradoOggetto: grade,
          note:
              'Fucile di legno e ottone. Puoi evocarlo con la Skill collegata: costo e munizioni dipendono dalla forma e dall’Oculum immesso. Totale Drop almeno 30.',
          ability: oculumEquipmentAbilityFromArt(
            oculumMonsterBookArt(
              monster.copyWith(skillIds: ['scostu_rifle']),
            ).skills.first,
          ),
          monsterLoot: {
            'id': '$killId:rifle',
            'monsterId': monster.id,
            'dropTotal': dropTotal,
          },
        ),
    ];
  }
  if (const {
    'observers_tear',
    'obser_sunshine',
    'saltalungo_maculato',
    'famelico_oblio',
  }.contains(monster.id)) {
    final (name, weight) = switch (monster.id) {
      'observers_tear' => ('Scheggia dell’occhio viola', .12),
      'obser_sunshine' => ('Frammento dell’occhio solare', .12),
      'saltalungo_maculato' => ('Tendine elastico maculato', .2),
      _ => ('Zanna del ricordo vuoto', .15),
    };
    return [
      if (natural >= 8) material(name, weight),
      if (natural >= 18)
        for (final skill in monster.skillIds)
          oculumPlanarTechniqueScroll(
            monster,
            skill,
            receipt: '$killId:$skill',
            level: level,
            grade: grade,
          ),
      if (natural == 20)
        InventoryItem(
          nome: 'Reliquia · ${monster.nameIt}',
          peso: .35,
          quantita: 1,
          livelloOggetto: level,
          gradoOggetto: grade,
          note:
              'Reliquia di ${monster.nameIt}: conserva una tecnica della creatura con costo e cooldown. Richiede livello $level e Grado $grade; valori modificabili.',
          ability: oculumEquipmentAbilityFromArt(
            oculumMonsterBookArt(monster).skills.first,
          ),
          monsterLoot: {
            'id': '$killId:relic',
            'monsterId': monster.id,
            'rareMonsterEquipment': true,
            'naturalDropRoll': natural,
          },
        ),
    ];
  }
  if (const {
    'nuvi',
    'coniglio_prestigiatore',
    'coniglio_plasma',
    'pupazzo_artigliato',
    'medusa_vetro',
    'nocciolo_corazzato',
  }.contains(monster.id)) {
    final materialName = switch (monster.id) {
      'nuvi' => 'Piuma soffice di Nuvì',
      'coniglio_prestigiatore' => 'Fodera incantata del cappello',
      'coniglio_plasma' => 'Bobina al plasma',
      'pupazzo_artigliato' => 'Molla di pupazzo',
      'medusa_vetro' => 'Filamento di vetro',
      _ => 'Guscio elastico di nocciolo',
    };
    return [
      if (natural >= 8)
        material(materialName, monster.id == 'nuvi' ? 0.02 : 0.2),
      if (natural >= 18 && monster.id != 'nuvi')
        for (final skill in monster.skillIds)
          if (skill != 'robot_rabbit_chains')
            oculumPlanarTechniqueScroll(
              monster,
              skill,
              receipt: '$killId:$skill',
              level: level,
              grade: grade,
            ),
      if (natural >= 18 && monster.id == 'coniglio_plasma')
        InventoryItem(
          nome: 'Catene runiche d’intrappolamento',
          peso: 1.2,
          quantita: 1,
          livelloOggetto: level,
          gradoOggetto: grade,
          note:
              'Immobilizzato fino alla liberazione con Forza o Riflessi contro il tiro originale. Costo e CD modificabili.',
          ability: oculumEquipmentAbilityFromArt(
            oculumMonsterBookArt(
              monster,
            ).skills.firstWhere((s) => s.nome == 'Catene d’intrappolamento'),
          ),
          monsterLoot: {'id': '$killId:catene', 'monsterId': monster.id},
        ),
    ];
  }
  if (id == 'sharp') {
    return [
      if (natural >= 8) material('Scarti metallici', .25),
      if (natural >= 12) material('Dente di Sharp', .1),
      if (natural >= 18) ...[
        for (final skill in ['rock_eater', 'rocket_flight'])
          oculumPlanarTechniqueScroll(
            monster,
            skill,
            receipt: '$killId:$skill',
            level: level,
            grade: grade,
          ),
      ],
    ];
  }
  if (id == 'lupo_delle_nevi') {
    final (materialId, materialName) = switch (monster.id) {
      'lupo_delle_nevi' => ('zanna_brinata', 'Zanna brinata'),
      'lupo_infernale_del_ghiaccio' => (
        'scheggia_brace_lupo',
        'Scheggia di brace lupina',
      ),
      'lupo_ombra_oblio' => ('filo_ululante_oblio', 'Filo ululante d’Oblio'),
      'lupo_runico_postea' => ('dente_circuito_lupo', 'Dente a circuito'),
      _ => ('artigli_lupo', 'Artigli di lupo'),
    };
    final drops = <InventoryItem>[
      if (natural >= 8)
        InventoryItem(
          nome: materialName,
          peso: .15,
          quantita: 1,
          gradoOggetto: grade,
          livelloOggetto: level,
          note:
              'Materiale da ${monster.nameIt}. In fusione con un equipaggiamento del Monster Book aggiunge +${max(1, level)} Danni all’arma oppure +${max(1, grade)} Difesa all’armatura; richiede il Grado del nemico o il Fabbro. Non assegna statistiche permanenti.',
          monsterLoot: {
            'id': '$killId:$materialId',
            'monsterId': monster.id,
            'material': true,
            'weaponBonus': max(1, level),
            'armorBonus': max(1, grade),
            'naturalDropRoll': natural,
          },
        ),
      if (natural >= 18)
        for (final skill in monster.skillIds)
          oculumPlanarTechniqueScroll(
            monster,
            skill,
            receipt: '$killId:$skill',
            level: level,
            grade: grade,
          ),
      if (natural == 20)
        ..._wolfRelicDrop(monster, level: level, grade: grade, killId: killId),
    ];
    return drops;
  }
  if (id == 'topino_avventuroso') {
    return [
      material('Fiaccola', .2),
      if (natural == 20)
        oculumPlanarTechniqueScroll(
          monster,
          'topino_poison_knife',
          receipt: '$killId:knife',
          level: level,
          grade: grade,
        ),
    ];
  }
  if (id == 'mosca_campana') {
    return [
      if (natural >= 15) material('Polvere della Magia del Suono', .05),
      if (natural >= 18)
        InventoryItem(
          nome: 'Campanella stordisci nemici',
          peso: .2,
          quantita: 1,
          gradoOggetto: grade,
          livelloOggetto: level,
          note:
              'La campanella della Mosca Campana. Rintocco: DT 25, Paralisi dal Fato 4 turni; critico Stun 1 turno e cura degli alleati. Costo 3 Volontà, CD 5 turni.',
          ability: oculumEquipmentAbilityFromArt(
            oculumMonsterBookArt(
              monster.copyWith(skillIds: ['bell_fate_paralysis']),
            ).skills.first,
          ),
          monsterLoot: {
            'id': '$killId:bell',
            'monsterId': id,
            'naturalDropRoll': natural,
          },
        ),
    ];
  }
  return null;
}

List<InventoryItem> _wolfRelicDrop(
  MonsterBookEntry monster, {
  required int level,
  required int grade,
  required String killId,
}) {
  final candidates = oculumMonsterEquipmentCatalogue(
    source: monster,
    level: level,
    grade: grade,
  ).where((item) => item.craftData['itemFamily'] == 'weapon').toList();
  if (candidates.isEmpty) return const [];
  final item = InventoryItem.fromJson(candidates.first.toJson());
  item
    ..nome = 'Lama del Branco · ${monster.nameIt}'
    ..note =
        'Reliquia del Lupo delle Nevi e delle sue varianti. ${item.note} La skill collegata richiede livello $level e conserva costo, forme e cooldown; apprendimento ed equipaggiamento seguono i requisiti normali.'
    ..monsterLoot = {
      ...item.monsterLoot,
      'id': '$killId:lupo-reliquia',
      'monsterId': monster.id,
      'rareMonsterEquipment': true,
      'naturalDropRoll': 20,
    }
    ..craftData = {
      ...item.craftData,
      'wolfFamily': 'lupo_delle_nevi',
      'naturalDropRollRequired': 20,
      'skillLevelRequired': level,
    };
  return [item];
}

extension _OculumPlanarHunts on _OculumHomePageState {
  void recordPlanarMonsterEscape(Map token) {
    final monsterId = monsterBookIdForCombatToken(
      Map<String, dynamic>.from(token),
    );
    if (oculumPartyHuntSpeciesId(monsterId) != 'obliterated_devil' ||
        !canManagePartyQuests) {
      return;
    }
    final forgotten = (partyChest['forgottenMonsterIds'] as List? ?? [])
        .map((id) => '$id')
        .toSet();
    if (!forgotten.add('obliterated_devil')) return;
    partyChest['forgottenMonsterIds'] = forgotten.toList();
    partyChest['revision'] = readIntValue(partyChest['revision']) + 1;
    aggiungiLog(
      '[OBLIO] Il Diavolo è fuggito: identità dimenticata nel Monster Book; uccisioni, scoperte e premi restano conservati.',
    );
    programmaSalvataggio();
    unawaited(sendPartyChestState());
  }

  void recordPlanarMonsterRewards(
    Iterable<Map> enemies,
    String encounterId, {
    Iterable<String> participantTags = const [],
  }) {
    if (!canManagePartyQuests) return;
    final ledger = Map<String, dynamic>.from(
      partyChest['planarHunts'] as Map? ?? {},
    );
    final items = List<dynamic>.from(partyChest['items'] as List? ?? []);
    var changed = false;
    for (final enemy in enemies) {
      if (oculumEncounterEnemyIsSummon(enemy)) continue;
      final monster = monsterBookEntryById(
        oculumPartyHuntSpeciesId('${enemy['monsterBookId'] ?? ''}'),
      );
      if (monster == null || monster.encounterRules.isEmpty) continue;
      final key = monster.id;
      final record = Map<String, dynamic>.from(ledger[key] as Map? ?? {});
      final kills = (record['killIds'] as List? ?? []).map((v) => '$v').toSet();
      final killId = '$encounterId:${enemy['monsterSheetTag'] ?? enemy['id']}';
      if (!kills.add(killId)) continue;
      final shieldPerLevel = readIntValue(
        monster.encounterRules['shieldOnKillPerEnemyLevel'],
      );
      final shieldKiller = '${enemy['killerTag'] ?? ''}';
      if (shieldPerLevel > 0 && shieldKiller.isNotEmpty) {
        final rewards = Map<String, dynamic>.from(
          partyChest['questRewards'] as Map? ?? {},
        );
        final receipt = 'monster-shield:$killId:$shieldKiller';
        rewards.putIfAbsent(
          receipt,
          () => {
            'id': receipt,
            'recipient': shieldKiller,
            'bonus': {
              'scudo': shieldPerLevel * max(0, readIntValue(enemy['level'])),
            },
          },
        );
        partyChest['questRewards'] = rewards;
      }
      final magicalLuck = monster.encounterRules['magicalLuckOnDefeat'];
      if (magicalLuck is Map) {
        final rewards = Map<String, dynamic>.from(
          partyChest['questRewards'] as Map? ?? {},
        );
        final killer = normalizeOculumFriendTag('${enemy['killerTag'] ?? ''}');
        for (final tag
            in participantTags.where((tag) => tag.trim().isNotEmpty).toSet()) {
          final gain = readIntValue(
            magicalLuck[normalizeOculumFriendTag(tag) == killer
                ? 'killer'
                : 'others'],
          );
          if (gain <= 0) continue;
          final receipt = 'monster-gratitude:$killId:$tag';
          rewards.putIfAbsent(
            receipt,
            () => {
              'id': receipt,
              'recipient': tag,
              'bonus': {'fortunaMagica': gain},
              'message': '${monster.encounterRules['defeatMessage'] ?? ''}',
            },
          );
        }
        partyChest['questRewards'] = rewards;
      }
      final defeatMessage = '${monster.encounterRules['defeatMessage'] ?? ''}'
          .trim();
      if (defeatMessage.isNotEmpty) {
        aggiungiLog('[SCONFITTA] $defeatMessage');
        final killer = '${enemy['killerTag'] ?? ''}';
        if (killer.isNotEmpty &&
            localSheetIndexForOculumTag(killer) != schedaCorrente) {
          combatLogFor(killer, '[SCONFITTA] $defeatMessage');
        }
      }
      record['killIds'] = kills.toList();
      record['count'] = kills.length;
      final received = (record['rewards'] as List? ?? [])
          .map((v) => '$v')
          .toSet();
      final finisher = enemy['finisher'] as Map? ?? {};
      void grant(Map reward, String suffix) {
        if (!received.add(suffix)) return;
        final skill = '${reward['skillId'] ?? ''}';
        if (skill.isNotEmpty) {
          final receipt = 'planar:$key:$suffix';
          final item = oculumPlanarTechniqueScroll(
            monster,
            skill,
            receipt: receipt,
            level: readIntValue(enemy['level']),
            grade: readIntValue(enemy['grade']),
          );
          // Quest/species reward objects are deposited once in the party chest.
          final pending = List<dynamic>.from(
            partyChest['pendingLoot'] as List? ?? [],
          );
          pending.add({'id': receipt, 'item': item.toJson()});
          partyChest['pendingLoot'] = pending;
          aggiungiLog(
            '[MONSTER BOOK] ${monster.nameIt}: ${item.nome} nella cassa comune.',
          );
        }
        if (readIntValue(reward['criticalShields']) > 0 &&
            '${enemy['killerTag'] ?? ''}'.isNotEmpty) {
          final rewards = Map<String, dynamic>.from(
            partyChest['questRewards'] as Map? ?? {},
          );
          final id = 'planar:$key:$suffix';
          rewards.putIfAbsent(
            id,
            () => {
              'id': id,
              'recipient': enemy['killerTag'],
              'bonus': {
                'scudoCritico': readIntValue(reward['criticalShields']),
              },
            },
          );
          partyChest['questRewards'] = rewards;
        }
      }

      final hunt = monster.encounterRules['huntReward'];
      if (hunt is Map && kills.length >= readIntValue(hunt['kills'])) {
        final reward = Map<String, dynamic>.from(hunt);
        if (reward['passive'] == 'slashing_critical_natural_19') {
          reward['skillId'] = 'blade_skull_critical';
        }
        grant(reward, 'hunt');
      }
      final finalRewards = [
        if (monster.encounterRules['finisherReward'] is Map)
          monster.encounterRules['finisherReward'] as Map,
        ...(monster.encounterRules['finisherRewards'] as List? ?? [])
            .whereType<Map>(),
      ];
      for (final reward in finalRewards) {
        final condition = '${reward['condition']}';
        final matched = switch (condition) {
          'weak_point' => finisher['weakPoint'] == true,
          'base_attack' => finisher['baseAttack'] == true,
          'stunning_attack' => finisher['stun'] == true,
          'active_mortal_ki' => readIntValue(finisher['sourceMortalKi']) > 0,
          'common_natural_element' => oculumFeralisCommonElements.contains(
            finisher['element'],
          ),
          'element:acqua' => finisher['element'] == 'acqua',
          'ability' => '${finisher['abilityName'] ?? ''}'.isNotEmpty,
          'nonmagical_blunt' =>
            finisher['baseAttack'] == true &&
                (finisher['choice'] == 'schianto' ||
                    finisher['element'] == 'contundente'),
          'lethal_precision_weak_point' => finisher['weakPoint'] == true,
          'skill:rock_shield_pressure' =>
            '${finisher['abilityName'] ?? ''}'.contains(
              'Pressione amplificata',
            ),
          _ => false,
        };
        if (matched) grant(reward, condition);
      }
      record['rewards'] = received.toList();
      ledger[key] = record;
      changed = true;
    }
    if (changed) {
      partyChest['planarHunts'] = ledger;
      partyChest['items'] = items;
      oculumPromotePendingChestLoot(partyChest);
      partyChest['revision'] = readIntValue(partyChest['revision']) + 1;
      settlePartyQuestRewards();
      programmaSalvataggio();
      unawaited(sendPartyChestState());
    }
  }
}

/// Reward overflow waits outside the chest until a withdrawal frees capacity.
void oculumPromotePendingChestLoot(Map<String, dynamic> chest) {
  final items = List<dynamic>.from(chest['items'] as List? ?? []);
  final pending = List<dynamic>.from(chest['pendingLoot'] as List? ?? []);
  final capacity = oculumPartyChestCapacity(
    (chest['members'] as Map? ?? {}).values.whereType<Map>(),
  );
  var weight = oculumPartyChestWeight(items.whereType<Map>());
  final remaining = <dynamic>[];
  for (final raw in pending) {
    if (raw is! Map || raw['item'] is! Map) continue;
    final item = raw['item'] as Map;
    final itemWeight =
        readDoubleValue(item['peso']) * max(1, readIntValue(item['quantita']));
    if (weight + itemWeight <= capacity + .000001) {
      items.add(raw);
      weight += itemWeight;
    } else {
      remaining.add(raw);
    }
  }
  chest['items'] = items;
  chest['pendingLoot'] = remaining;
}

extension _OculumPlanarSupport on _OculumHomePageState {
  Future<void> deliverPlanarPartyHealing(int value, String source) async {
    applyStructuredEffectsOnActivation([
      OculumStructuredEffect(
        id: 'planar:auto_party_heal',
        type: 'cura',
        resource: 'vita',
        valueExpression: '$value',
        recipient: 'alleato',
        minimumTargets: 1,
        maximumTargets: 999,
      ),
    ], source: source);
    final side = combatScoutSide(sheetTagAt(schedaCorrente));
    final targets = realtimeService?.isConnected == true
        ? onlineCombatTokens()
              .where(
                (t) =>
                    combatScoutSide(onlineCombatTokenTag(t)) == side &&
                    !const {'dead', 'fled', 'expired'}.contains(t['status']),
              )
              .map(onlineCombatTokenTag)
              .toList()
        : questPartyIndices().map(sheetTagAt).toList();
    await deliverPendingSupport(
      minimum: 1,
      maximum: max(1, targets.length),
      selectedTags: targets,
      sourcePrefix: source,
    );
  }

  void claimPlanarBellHealing(Map<String, dynamic> request) {
    if (request['planarBellHealClaimed'] == true ||
        readIntValue(request['natural']) != 20 ||
        request['outcome'] == OculumAttackOutcome.avoided.name ||
        !(request['effects'] as List? ?? []).whereType<Map>().any(
          (e) => e['type'] == 'planar' && e['target'] == 'bell_paralysis',
        )) {
      return;
    }
    final tag = '${request['sourceTag']}';
    if (!controlsOnlineCombatSheet(tag)) return;
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0) return;
    final original = schedaCorrente;
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    try {
      if (index != original) {
        schedaCorrente = index;
        caricaStatoDaJson(schedePersonaggio[index]);
        ripristinaImpostazioniGlobali(global);
      }
      request['planarBellHealClaimed'] = true;
      unawaited(
        deliverPlanarPartyHealing(
          readIntValue(request['sourceWill'], fallback: volontaTotale()),
          'Rintocco critico · ${request['id']}',
        ),
      );
      salvaSchedaCorrenteInMemoria();
    } finally {
      if (index != original) {
        final updated = catturaImpostazioniGlobali();
        schedaCorrente = original;
        caricaStatoDaJson(schedePersonaggio[original]);
        ripristinaImpostazioniGlobali(updated);
      }
    }
  }
}

extension _OculumBringiDamage on _OculumHomePageState {
  Future<void> applyPlanarSeedDamage(String tag, int damage) async {
    if (!controlsOnlineCombatSheet(tag)) return;
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0) return;
    final original = schedaCorrente;
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    try {
      if (index != original) {
        schedaCorrente = index;
        caricaStatoDaJson(schedePersonaggio[index]);
        ripristinaImpostazioniGlobali(global);
      }
      currentHpController.text = '${max(0, hpCorrenti() - damage)}';
      planarAfterHpDamage();
      controllaCadutaDopoDanno();
      salvaSchedaCorrenteInMemoria();
      programmaSalvataggio();
      sendRealtimeHpChanged();
    } finally {
      if (index != original) {
        final updated = catturaImpostazioniGlobali();
        schedaCorrente = original;
        caricaStatoDaJson(schedePersonaggio[original]);
        ripristinaImpostazioniGlobali(updated);
      }
    }
  }
}
