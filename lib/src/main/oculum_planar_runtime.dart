part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const _planarSelfRules = <String, String>{
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
  int planarAttackRollBonus() => readIntValue(planarState['attackRollBonus']);
  int planarDefenseRollBonus() =>
      readIntValue(planarState['defenseRollPenalty']);
  void activatePlanarEffect(
    OculumStructuredEffect effect,
    int value,
    int duration,
    String source,
  ) {
    final state = planarState;
    switch (effect.target) {
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
    resetMeccanioFight();
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
  }) {
    final state = planarState;
    if (damage <= 0) return damage;
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
    currentHpController.text = '$hp';
    aggiungiLog(
      '[VITA DI UNA NUVOLA] Ti trasformi in nube con $hp Vita. Puoi muoverti, non attaccare. Sopravvivi fino al Riposo Lungo per rinascere.',
    );
  }

  bool planarIsCriticalEffectAllowed(
    Map request,
    OculumStructuredEffect effect,
  ) {
    if (!const {
      'critical_stun',
      'critical_aphonia',
      'annihilation',
    }.contains(effect.target)) {
      return true;
    }
    return readIntValue(request['natural']) >= 20;
  }
}

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
        'grade': grade,
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
  String killId,
) {
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

  void recordPlanarMonsterRewards(Iterable<Map> enemies, String encounterId) {
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
