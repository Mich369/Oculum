part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const _meccanioTechniqueDescriptions = {
  'rays':
      'Raggio perforante. Un critico che colpisce applica Oltre Difesa al bersaglio per un turno; gli attacchi successivi ignorano la sua Difesa, conservando Scudi e resistenze.',
  'drones':
      'Droni riparatori: tira Meccanica e ripara il doppio. Il critico raddoppia ancora come nella cura normale. A Vita piena genera Scudo entro il limite della forma.',
  'lightning':
      'Scarica fino a tre nemici. Il danno totale cresce con i bersagli ma la quota individuale scende. Su critico una sola estrazione: 15% tutti i colpiti, 25% i due più deboli, 30% il più debole, 30% nessuno.',
  'shoulder':
      'Azione gratuita. Mitra sulla spalla: un solo tiro di Precisione con svantaggio; 1d60 proiettili da 2/3/4 danni, divisi per difetto sui bersagli. Il surriscaldamento avvia il cooldown.',
  'sphere':
      'Reazione per iniziare la carica. Nel prossimo turno di Meccanio concede un’unica Azione dedicata al lancio della Sfera elettro; la perdita di Vita può interrompere la Concentrazione.',
  'claw':
      'La pinza si apre in un artiglio conduttore: danni da Taglio e una scarica concentrata contro un bersaglio.',
  'harpoon':
      'Lancia un arpione runico da una cavità dell’avambraccio: colpo Perforante preciso contro un nemico, senza trascinarlo automaticamente.',
};

CharacterSkill meccanioTechnique(String key) {
  final passive = key == 'emergency';
  final open = key == 'missile' || key == 'automatic';
  final openSkill = key == 'open_skill';
  final name = passive
      ? 'Protezioni di Emergenza'
      : key == 'missile'
      ? 'Open · Missile'
      : key == 'automatic'
      ? 'Open · Mitra automatici'
      : openSkill
      ? 'Tecnica della Open'
      : meccanioTechniqueNames[key]!;
  final description = passive
      ? 'Gratuita, CD 1 turno. Se l’attacco supera il massimo tiro difensivo senza critico, +4/+6/+8 alla difesa. Fallimento: -20% danni; fallimento vicino: -25%; successo: zero. Resistenza riuscita: scarica di risposta e Scudo pari a Scudo/HP temporanei/Vita realmente tolti; Scudo Oculum separato pari a quello realmente tolto.'
      : key == 'missile'
      ? 'Un missile emerge dalla schiena: 75/100/125 danni a ogni avversario. Ogni alleato recupera il 75% della Vita realmente tolta complessivamente. Open buff: mani ad artiglio elettrificato, +10 Taglio e +15 Fulmine. La tecnica della Open affila l’artiglio.'
      : key == 'automatic'
      ? 'Le mani diventano mitragliatrici: 1d120+15/25/35 danni, Precisione o Fermezza con Super Vantaggio. Open buff: +4/+6/+8 RES/VOL/MAT; Oculum resta zero. La tecnica della Open usa una mano-mitragliatrice, con +5 Perforante.'
      : openSkill
      ? 'Richiede la propria Open attiva. Mitra: 1d60+5 Perforante, Precisione o Fermezza. Missile: artiglio +13 Taglio e 1d30+10; fuori Open la pinza mantiene il suo profilo normale.'
      : _meccanioTechniqueDescriptions[key]!;
  final forms = [
    for (var form = 1; form <= 3; form++)
      CharacterSkillForm(
        nome: const ['I', 'II', 'III'][form - 1],
        livello: '${(form - 1) * 3}',
        tipo: passive
            ? 'Passiva [pannello:difesa]'
            : key == 'drones' || open
            ? 'Supporto [pannello:supporto]'
            : 'Attacco [pannello:attacco]',
        costo: 'Nessun costo',
        costoStrutturato: OculumSkillCost(
          resource: 'nessuna',
          amountExpression: '0',
        ),
        cooldown:
            '${passive
                ? 1
                : open
                ? 8
                : key == 'sphere'
                ? 6
                : key == 'drones'
                ? 4
                : key == 'shoulder'
                ? 5
                : 3} turni',
        cooldownStrutturato: OculumAbilityCooldown(
          amount: passive
              ? 1
              : open
              ? 8
              : key == 'sphere'
              ? 6
              : key == 'drones'
              ? 4
              : key == 'shoulder'
              ? 5
              : 3,
        ),
        descrizione:
            '$description Forma $form: livello ${(form - 1) * 3}. Costi, effetti e recupero sono modificabili.',
        effettiStrutturati: [
          OculumStructuredEffect(
            id: 'meccanio:$key:$form',
            type: 'meccanio',
            target: key,
            valueExpression: '$form',
            narrativeText: description,
          ),
        ],
        oculumLimitiConfiguratiManualmente: true,
      ),
  ];
  return CharacterSkill(
    nome: name,
    tipo: forms.first.tipo,
    costo: 'Nessun costo',
    cooldown: forms.first.cooldown,
    descrizione: description,
    equipaggiata: true,
    forme: forms,
  );
}

List<CharacterSkill> meccanioLoadoutSkills(Map<String, dynamic> loadout) => [
  for (final key in (loadout['skills'] as List? ?? const []))
    if (meccanioTechniqueNames.containsKey('$key')) meccanioTechnique('$key'),
  meccanioTechnique('emergency'),
  meccanioTechnique(loadout['open'] == 'automatic' ? 'automatic' : 'missile'),
  meccanioTechnique('open_skill'),
];

extension _OculumMeccanio on _OculumHomePageState {
  bool get isThunderBot =>
      schedaCorrente >= 0 &&
      schedaCorrente < schedePersonaggio.length &&
      schedePersonaggio[schedaCorrente]['monsterBookSourceId'] == 'thunder_bot';
  bool get localMeccanioCombat =>
      realtimeService?.isConnected != true &&
      masterInitiativeTokens.any((token) {
        final index = localSheetIndexForOculumTag(
          publicInitiativeSourceTag(token),
        );
        return index >= 0 &&
            (isMeccanioBookId(
                  '${schedePersonaggio[index]['monsterBookSourceId'] ?? ''}',
                ) ||
                schedePersonaggio[index]['monsterBookSourceId'] ==
                    'thunder_bot');
      });
  bool get isMeccanio =>
      schedaCorrente >= 0 &&
      schedaCorrente < schedePersonaggio.length &&
      isMeccanioBookId(
        '${schedePersonaggio[schedaCorrente]['monsterBookSourceId'] ?? ''}',
      );
  Map<String, dynamic> get meccanioState {
    final sheet = schedePersonaggio[schedaCorrente];
    final value = sheet['meccanio'];
    if (value is Map<String, dynamic>) return value;
    final result = value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
    sheet['meccanio'] = result;
    return result;
  }

  bool get meccanioSphereReady =>
      isMeccanio &&
      meccanioState['spherePreparedTurn'] != null &&
      playerReportedTurn > readIntValue(meccanioState['spherePreparedTurn']) &&
      planarState['preparedSkill'] is Map;

  Map<String, dynamic> pendingMeccanioAttack() =>
      !isMeccanio || meccanioState['pendingAttack'] is! Map
      ? <String, dynamic>{}
      : Map<String, dynamic>.from(meccanioState['pendingAttack'] as Map);

  bool meccanioMayRelease() {
    final pending = pendingMeccanioAttack();
    if (pending['kind'] != 'sphere') return true;
    if (planarState['preparedSkill'] is! Map) {
      clearMeccanioAttack();
      aggiungiLog('Sfera elettro interrotta: prepara nuovamente la carica.');
      return false;
    }
    if (!meccanioSphereReady) {
      aggiungiLog('Sfera elettro: attendi il prossimo turno di Meccanio.');
      return false;
    }
    return true;
  }

  void meccanioTurn() {
    if (!isMeccanio) return;
    final token = masterInitiativeTokens
        .where(
          (t) => publicInitiativeSourceTag(t) == sheetTagAt(schedaCorrente),
        )
        .firstOrNull;
    if (token != null) {
      token['actionUsed'] = !meccanioSphereReady;
    }
  }

  int meccanioEmergencyDefense(Map<String, dynamic> request, int bonus) {
    if (!isMeccanio ||
        readIntValue(request['attack']) <= 20 + bonus ||
        readIntValue(meccanioState['emergencyReadyTurn']) >
            playerReportedTurn) {
      return 0;
    }
    final form = min(3, 1 + activeCriticalLevel() ~/ 3);
    meccanioState['emergencyReadyTurn'] = playerReportedTurn + 1;
    request['meccanioEmergency'] = true;
    final extra = meccanioSkillPower(meccanioEmergencyBonus(form));
    aggiungiLog(
      '[MECCANIO] Protezioni di Emergenza: attacco ${request['attack']} > massimo ${20 + bonus}; +$extra Difesa, CD 1 turno.',
    );
    return extra;
  }

  void clearMeccanioAttack() {
    if (!isMeccanio) return;
    meccanioState.remove('pendingAttack');
    meccanioState.remove('spherePreparedTurn');
  }

  void resetMeccanioFight() {
    if (!isMeccanio) return;
    clearMeccanioAttack();
    meccanioState.remove('openActive');
    meccanioState.remove('openUsedFight');
    meccanioState.remove('emergencyReadyTurn');
  }

  void configureMeccanio(int index) {
    final sheet = schedePersonaggio[index];
    if (sheet['meccanio'] is Map) return; // Never reroll an existing purchase.
    final state = meccanioRollLoadout(Random.secure());
    final level = max(0, readIntValue(sheet['livello']));
    final variant = '${sheet['monsterBookSourceId'] ?? ''}';
    state.addAll(meccanioVariantProfile(variant));
    final maximum =
        (variant == 'meccanio_ammaccato'
            ? 14
            : variant == 'meccanio_elite'
            ? 28
            : 20) +
        level * 3;
    state['maximumHp'] = maximum;
    sheet['meccanio'] = state;
    sheet['skills'] = meccanioLoadoutSkills(
      state,
    ).map((s) => s.toJson()).toList();
    sheet['arti'] = <dynamic>[];
    for (final key in [
      'oculum',
      'currentOculum',
      'maxOculum',
      'normalCurrentOculum',
      'temporaryOculum',
    ]) {
      sheet[key] = '0';
    }
    sheet['currentHp'] = '$maximum';
    sheet['derivedMaxHp'] = maximum;
    final shield = (maximum * readIntValue(state['initialShieldPercent']) / 100)
        .ceil();
    final eyeShield =
        (maximum * readIntValue(state['oculumShieldPercent']) / 100).ceil();
    sheet['scudo'] = '$shield';
    sheet['scudoOculum'] = '$eyeShield';
    sheet['notePersonaggio'] =
        '${sheet['notePersonaggio'] ?? ''}\nScocca: ${state['colour']}. ${monsterBookEntryById('meccanio')!.descIt}';
    if (index == schedaCorrente) {
      skills
        ..clear()
        ..addAll(meccanioLoadoutSkills(state));
      arti.clear();
      currentHpController.text = '$maximum';
      scudoController.text = '$shield';
      scudoOculumController.text = '$eyeShield';
      oculumController.text = '0';
      currentOculumController.text = '0';
    }
  }

  int meccanioStatAdjustment(String stat, int current) {
    if (!isMeccanio ||
        !const {'resilienza', 'volonta', 'materia'}.contains(stat)) {
      return 0;
    }
    final state = meccanioState;
    final bonus = state['regenerationBonuses'] is Map
        ? readIntValue((state['regenerationBonuses'] as Map)[stat])
        : 0;
    final openBonus = state['openActive'] == 'automatic'
        ? 2 + 2 * readIntValue(state['openForm'], fallback: 1)
        : 0;
    return meccanioIntegrityStat(
          current,
          leggiNumero(currentHpController),
          max(1, readIntValue(state['maximumHp'], fallback: 20)),
          bonus: bonus + openBonus,
        ) -
        current;
  }

  void regenerateMeccanio(int amount, {int form = 1}) {
    if (!isMeccanio || amount <= 0) return;
    final maximum = maxHp();
    final repaired = meccanioRepair(
      hp: hpCorrenti(),
      hpMaximum: maximum,
      shield: leggiNumero(scudoController),
      amount: amount,
      form: form,
      shieldLimitPercent: meccanioVariantValue(
        form <= 1 ? 'repairShieldPercentI' : 'repairShieldPercentII',
      ),
    );
    currentHpController.text = '${repaired.hp}';
    scudoController.text = '${repaired.shield}';
    if ((repaired.healed > 0 || repaired.shieldAdded > 0) &&
        scudoOculum() > 0) {
      final owner = localSheetIndexForOculumTag(
        '${schedePersonaggio[schedaCorrente]['meccanioOwnerTag'] ?? ''}',
      );
      if (owner >= 0) {
        final sheet = schedePersonaggio[schedaCorrente];
        meccanioState['regenerationBonuses'] = meccanioRegenerationBonuses(
          base: {
            for (final key in ['resilienza', 'volonta', 'materia'])
              key: readIntValue(sheet[key]),
          },
          previous: {
            for (final key in ['resilienza', 'volonta', 'materia'])
              key: readIntValue(
                (meccanioState['regenerationBonuses'] as Map? ?? const {})[key],
              ),
          },
          owner: {
            for (final key in ['resilienza', 'volonta', 'materia'])
              key: readIntValue(schedePersonaggio[owner][key]),
          },
        );
      }
    }
    aggiungiLog(
      '[MECCANIO] Riparazione: +${repaired.healed} Vita, +${repaired.shieldAdded} Scudo.',
    );
    invalidateDerivedDataCaches();
    programmaSalvataggio();
  }

  int meccanioVariantValue(String key) => !isMeccanio
      ? 0
      : readIntValue(
          meccanioState[key],
          fallback:
              meccanioVariantProfile(
                '${schedePersonaggio[schedaCorrente]['monsterBookSourceId'] ?? ''}',
              )[key] ??
              0,
        );

  int meccanioSkillPower(int value) =>
      (value * meccanioVariantValue('skillPowerPercent') / 100).ceil();

  bool meccanioSkillAllowed(Iterable<OculumStructuredEffect> effects) {
    final own = effects.where((e) => e.type == 'meccanio').firstOrNull;
    if (own == null) return true;
    if (!isMeccanio) return false;
    if ((own.target == 'missile' || own.target == 'automatic') &&
        meccanioState['openUsedFight'] == onlineCombatEncounterId &&
        currentCombatIsActive()) {
      aggiungiLog('Open di Meccanio già usata in questo scontro.');
      return false;
    }
    if (!meccanioAcceptsCommand()) return false;
    if (own.target == 'open_skill' && meccanioState['openActive'] == null) {
      aggiungiLog('Attiva prima la Open di Meccanio.');
      return false;
    }
    if (meccanioState['pendingAttack'] is Map) {
      aggiungiLog('Rilascia o annulla prima la tecnica già preparata.');
      return false;
    }
    return true;
  }

  void activateMeccanioTechnique(OculumStructuredEffect effect, int form) {
    if (!isMeccanio) return;
    final key = effect.target;
    if (key == 'repair') {
      regenerateMeccanio(
        max(0, form),
        form: min(3, 1 + activeCriticalLevel() ~/ 3),
      );
      return;
    }
    final f = form.clamp(1, 3);
    if (key == 'drones') {
      final stat = hiddenEyeStats.where((s) => s.id == 'meccanica').firstOrNull;
      final natural = tiraD20();
      final total = rollTotalWithCritical(natural, 20, [
        stat == null ? 0 : hiddenEyeTotal(stat),
      ]);
      regenerateMeccanio(
        meccanioSkillPower(max(0, total) * 2 * (natural == 20 ? 2 : 1)),
        form: f,
      );
      return;
    }
    if (key == 'emergency') return;
    final open = key == 'missile' || key == 'automatic';
    if (open) {
      if (meccanioState['openUsedFight'] == onlineCombatEncounterId &&
          currentCombatIsActive()) {
        aggiungiLog('Open di Meccanio già usata in questo scontro.');
        return;
      }
      meccanioState['openActive'] = key;
      meccanioState['openForm'] = f;
      meccanioState['openUsedFight'] = onlineCombatEncounterId;
    }
    var damage = switch (key) {
      'shoulder' => (Random.secure().nextInt(60) + 1) * (f + 1),
      'automatic' => Random.secure().nextInt(120) + 1 + 15 + (f - 1) * 10,
      'missile' => 50 + f * 25,
      'sphere' => 65 + f * 35,
      'rays' => 8 + f * 8,
      'lightning' => 8 + f * 6,
      'claw' => 9 + Random.secure().nextInt(20) + 1 + (f - 1) * 6,
      'harpoon' => 8 + f * 5,
      'open_skill' =>
        meccanioState['openActive'] == 'missile'
            ? 23 + Random.secure().nextInt(30) + 1
            : 5 + Random.secure().nextInt(60) + 1,
      _ => 0,
    };
    if (meccanioState['openActive'] == 'missile' && !open) damage += 25;
    damage = meccanioSkillPower(damage);
    meccanioState['pendingAttack'] = {
      'kind': key,
      'form': f,
      'damage': damage,
      'free': key == 'shoulder',
      'allOpponents': key == 'missile',
      'maximumTargets': key == 'lightning'
          ? 3
          : key == 'shoulder' || key == 'automatic' || key == 'missile'
          ? 99
          : 1,
      'choice': 'precisione',
      'element': key == 'lightning' || key == 'sphere'
          ? 'fulmine'
          : key == 'claw'
          ? 'taglio'
          : 'perforante',
    };
    if (key == 'sphere') {
      meccanioState['spherePreparedTurn'] = playerReportedTurn;
      prepareConcentratedSkill(
        OculumStructuredEffect(
          type: 'preparazione',
          target: 'attacco',
          activationOption: 'concentrazione',
        ),
        0,
        'Sfera elettro',
      );
    }
    aggiungiLog(
      '[MECCANIO] ${effect.narrativeText} Danno preparato: $damage. Usa Attacco per scegliere i bersagli e risolvere il tiro.',
    );
    invalidateDerivedDataCaches();
    programmaSalvataggio();
  }

  void resetMeccanioAtOwnerRest() {
    final owner = sheetTagAt(schedaCorrente);
    for (final sheet in schedePersonaggio) {
      if (sheet['meccanioOwnerTag'] != owner || sheet['meccanio'] is! Map) {
        continue;
      }
      (sheet['meccanio'] as Map)['regenerationBonuses'] = <String, int>{};
    }
  }

  bool meccanioAcceptsCommand() {
    if (!isMeccanio) return true;
    final owner =
        '${schedePersonaggio[schedaCorrente]['meccanioOwnerTag'] ?? ''}';
    if (owner.isEmpty) return true;
    final grudges = meccanioState['grudges'] as Map? ?? const {};
    final chance = readIntValue(grudges[owner]).clamp(0, 100);
    if (chance == 0) return true;
    final roll = Random.secure().nextInt(100);
    final accepted = roll >= chance;
    aggiungiLog(
      '[MECCANIO] Comando: ${roll + 1}/100, rifiuto $chance% → ${accepted ? 'obbedisce' : 'ignora il comando'}.',
    );
    return accepted;
  }

  void meccanioOwnerRest({required bool longRest}) {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return;
    }
    schedePersonaggio[schedaCorrente]['meccanioEmpathyUsed'] = false;
    final tag = sheetTagAt(schedaCorrente);
    for (final sheet in schedePersonaggio) {
      if (sheet['meccanio'] is! Map) continue;
      final data = sheet['meccanio'] as Map;
      final grudges = data['grudges'];
      if (grudges is Map && grudges.containsKey(tag)) {
        grudges[tag] = meccanioDisobedienceAfterRest(
          readIntValue(grudges[tag]),
          longRest: longRest,
        );
      }
    }
  }

  bool get canUseMeccanioEmpathy =>
      schedaCorrente >= 0 &&
      schedaCorrente < schedePersonaggio.length &&
      ownsMeccanio(sheetTagAt(schedaCorrente)) &&
      schedePersonaggio[schedaCorrente]['meccanioEmpathyUsed'] != true;

  Future<void> useMeccanioEmpathy({bool deception = false}) async {
    if (!canUseMeccanioEmpathy) return;
    final origin = currentSheetScrollId();
    final stat = hiddenEyeStats
        .where((s) => s.id == (deception ? 'inganno' : 'empatia'))
        .firstOrNull;
    if (stat == null) return;
    if (currentTurnTrackerIsActive() && !await spendCombatRollResource()) {
      return;
    }
    if (!mounted ||
        currentSheetScrollId() != origin ||
        !canUseMeccanioEmpathy) {
      return;
    }
    await tiraSottotrattoOcchio(
      stat,
      actionLabel: '${deception ? 'Inganno' : 'Empatia'} · Meccanio',
      onResolved: (natural, total) {
        if (currentSheetScrollId() != origin || !canUseMeccanioEmpathy) return;
        applyMeccanioEmpathy(total, deception: deception, natural: natural);
      },
    );
  }

  bool applyMeccanioEmpathy(
    int total, {
    bool deception = false,
    int natural = 20,
  }) {
    if (!canUseMeccanioEmpathy) return false;
    final owner = sheetTagAt(schedaCorrente);
    schedePersonaggio[schedaCorrente]['meccanioEmpathyUsed'] = true;
    for (final sheet in schedePersonaggio) {
      if (sheet['meccanioOwnerTag'] != owner || sheet['meccanio'] is! Map) {
        continue;
      }
      final data = sheet['meccanio'] as Map;
      final grudges = Map<String, dynamic>.from(
        data['grudges'] as Map? ?? const {},
      );
      final before = readIntValue(grudges[owner]);
      final after = deception
          ? meccanioDisobedienceAfterDeception(before, natural, total)
          : meccanioDisobedienceAfterEmpathy(before, total);
      grudges[owner] = after;
      data['grudges'] = grudges;
      aggiungiLog(
        '[MECCANIO] ${deception ? 'Inganno (dado $natural)' : 'Empatia'} $total: rifiuto $before% → $after%. Recupera al prossimo Riposo Breve o Lungo.',
      );
    }
    programmaSalvataggio();
    return true;
  }

  void recordMeccanioAggression(Map<String, dynamic> request) {
    if (!isMeccanio || request['meccanioAggressionRecorded'] == true) return;
    final tag = '${request['sourceTag'] ?? ''}';
    if (tag.isEmpty) return;
    final grudges = Map<String, dynamic>.from(
      meccanioState['grudges'] as Map? ?? const {},
    );
    grudges[tag] = 60;
    meccanioState['grudges'] = grudges;
    request['meccanioAggressionRecorded'] = true;
    programmaSalvataggio();
  }

  void rewardMeccanioProtection(
    Map<String, dynamic> request, {
    int? reduction,
  }) {
    if (!isMeccanio || readIntValue(request['defenseHelp']) <= 0) {
      return;
    }
    final owner =
        '${schedePersonaggio[schedaCorrente]['meccanioOwnerTag'] ?? ''}';
    final helpers = (request['defenseHelpers'] as List? ?? const [])
        .map((v) => '$v')
        .toSet();
    final id = '${request['id'] ?? ''}';
    if (owner.isEmpty || id.isEmpty || !helpers.contains(owner)) return;
    final receipts = (meccanioState['protectionReceipts'] as List? ?? const [])
        .map((v) => '$v')
        .toList();
    if (receipts.contains(id)) return;
    receipts.add(id);
    meccanioState['protectionReceipts'] = receipts.reversed
        .take(200)
        .toList()
        .reversed
        .toList();
    final grudges = Map<String, dynamic>.from(
      meccanioState['grudges'] as Map? ?? const {},
    );
    final before = readIntValue(grudges[owner]);
    final succeeded =
        readIntValue(request['defense']) >= readIntValue(request['attack']);
    final ownerIndex = localSheetIndexForOculumTag(owner);
    final snapshot = meccanioState['helpOwnerHealth'] as Map? ?? const {};
    final ownerHp = ownerIndex < 0
        ? readIntValue(snapshot['hp'])
        : readIntValue(schedePersonaggio[ownerIndex]['currentHp']);
    final lost = max(
      0,
      readIntValue(snapshot['hp'], fallback: ownerHp) - ownerHp,
    );
    final amount = succeeded
        ? (reduction ?? (5 + Random.secure().nextInt(26))).clamp(5, 30)
        : meccanioFailedProtectionReward(
            lost,
            readIntValue(snapshot['maximum'], fallback: 1),
          );
    final after = max(0, before - amount);
    grudges[owner] = after;
    meccanioState['grudges'] = grudges;
    aggiungiLog(
      '[MECCANIO] Aiuto del padrone ${succeeded ? 'riuscito' : 'fallito · Vita persa $lost'}: −$amount punti di rifiuto ($before% → $after%).',
    );
    programmaSalvataggio();
  }

  void recordMeccanioHelp(String target, String helper, int hp, int maximum) {
    final index = localSheetIndexForOculumTag(target);
    if (index < 0) return;
    final sheet = schedePersonaggio[index];
    if (sheet['meccanioOwnerTag'] != helper || sheet['meccanio'] is! Map) {
      return;
    }
    (sheet['meccanio'] as Map)['helpOwnerHealth'] = {
      'hp': max(0, hp),
      'maximum': max(1, maximum),
    };
  }

  bool ownsMeccanio(String owner) => schedePersonaggio.any(
    (sheet) =>
        isMeccanioBookId('${sheet['monsterBookSourceId'] ?? ''}') &&
        sheet['meccanioOwnerTag'] == owner,
  );

  bool tameMeccanio(int index, int total) {
    if (index < 0 || index >= schedePersonaggio.length) return false;
    final owner = sheetTagAt(schedaCorrente);
    final sheet = schedePersonaggio[index];
    if (!isMeccanioBookId('${sheet['monsterBookSourceId'] ?? ''}') ||
        '${sheet['meccanioOwnerTag'] ?? ''}'.isNotEmpty ||
        ownsMeccanio(owner)) {
      return false;
    }
    final dt = meccanioTamingDifficulty(
      readIntValue(sheet['livello']),
      readIntValue(sheet['grado']),
    );
    if (total < dt) {
      aggiungiLog('[MECCANIO] Addestramento $total < DT $dt: non addestrato.');
      return false;
    }
    sheet['meccanioOwnerTag'] = owner;
    sheet['inMasterParty'] = true;
    sheet['countsForPartyStats'] = false;
    sheet['masterSideOverride'] = 'ally';
    for (final token in masterInitiativeTokens) {
      if (publicInitiativeSourceTag(token) == sheetTagAt(index)) {
        token['side'] = 'ally';
      }
    }
    aggiungiLog(
      '[MECCANIO] Addestramento $total ≥ DT $dt: ${sheet['nome']} ha un padrone.',
    );
    programmaSalvataggio();
    return true;
  }

  Future<void> tryTameMeccanio() async {
    final origin = currentSheetScrollId();
    if (ownsMeccanio(sheetTagAt(schedaCorrente))) {
      aggiungiLog('Puoi possedere un solo Meccanio.');
      return;
    }
    final candidates = [
      for (var i = 0; i < schedePersonaggio.length; i++)
        if (isMeccanioBookId(
              '${schedePersonaggio[i]['monsterBookSourceId'] ?? ''}',
            ) &&
            '${schedePersonaggio[i]['meccanioOwnerTag'] ?? ''}'.isEmpty)
          i,
    ];
    if (candidates.isEmpty) return;
    final index = await showDialog<int>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: const Text('Addestra Meccanio · Meccanica'),
        children: [
          for (final i in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, i),
              child: Text(
                '${nomeSchedaPersonaggio(i)} · DT ${meccanioTamingDifficulty(readIntValue(schedePersonaggio[i]['livello']), readIntValue(schedePersonaggio[i]['grado']))}',
              ),
            ),
        ],
      ),
    );
    if (!mounted || index == null || currentSheetScrollId() != origin) return;
    final stat = hiddenEyeStats.where((s) => s.id == 'meccanica').firstOrNull;
    if (stat == null) return;
    if (currentTurnTrackerIsActive() && !await spendCombatRollResource()) {
      return;
    }
    if (!mounted || currentSheetScrollId() != origin) return;
    await tiraSottotrattoOcchio(
      stat,
      actionLabel: 'Addestramento di Meccanio',
      onResolved: (_, total) {
        if (currentSheetScrollId() == origin) tameMeccanio(index, total);
      },
    );
  }

  void claimMeccanioResults(Map<String, dynamic> request) {
    if (request['meccanioAttack'] is! Map || request['damageReceipt'] is! Map) {
      return;
    }
    final source = '${request['sourceTag'] ?? ''}';
    if (!controlsOnlineCombatSheet(source)) return;
    final ownerIndex = localSheetIndexForOculumTag(source);
    if (ownerIndex < 0) return;
    final group = '${request['attackGroupId'] ?? request['id']}';
    final related = onlineCombatRequests.values
        .where((r) => '${r['attackGroupId'] ?? r['id']}' == group)
        .toList();
    if (related.length <
            readIntValue(request['damageTargetCount'], fallback: 1) ||
        related.any(
          (r) => r['status'] != 'resolved' || r['damageReceipt'] is! Map,
        )) {
      return;
    }
    final owner = schedePersonaggio[ownerIndex];
    final claims = (owner['meccanioClaimedGroups'] as List? ?? [])
        .map((e) => '$e')
        .toSet();
    if (!claims.add(group)) return;
    owner['meccanioClaimedGroups'] = claims.toList();
    final data = Map<String, dynamic>.from(request['meccanioAttack'] as Map);
    final hit = related
        .where((r) => r['outcome'] != OculumAttackOutcome.avoided.name)
        .toList();
    final original = schedaCorrente;
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    try {
      if (ownerIndex != original) {
        schedaCorrente = ownerIndex;
        caricaStatoDaJson(schedePersonaggio[ownerIndex]);
        ripristinaImpostazioniGlobali(global);
      }
      if (data['kind'] == 'missile') {
        final hp = hit.fold<int>(
          0,
          (total, r) =>
              total + readIntValue((r['damageReceipt'] as Map)['hpLost']),
        );
        if (hp > 0) {
          unawaited(
            deliverPlanarPartyHealing(
              (hp * .75).floor(),
              'Meccanio · Missile · $group',
            ),
          );
        }
      } else if (data['kind'] == 'counter') {
        for (final r in hit) {
          final receipt = r['damageReceipt'] as Map;
          scudoController.text =
              '${leggiNumero(scudoController) + readIntValue(receipt['shieldLost']) + readIntValue(receipt['temporaryHpLost']) + readIntValue(receipt['hpLost'])}';
          scudoOculumController.text =
              '${leggiNumero(scudoOculumController) + readIntValue(receipt['oculumShieldLost'])}';
        }
      } else if (data['kind'] == 'lightning' &&
          readIntValue(request['natural']) == 20) {
        int strength(Map r) {
          final index = localSheetIndexForOculumTag('${r['targetTag']}');
          if (index < 0) return readIntValue(r['targetLevel']);
          final sheet = schedePersonaggio[index];
          return [
            'resilienza',
            'volonta',
            'materia',
            'oculum',
          ].fold<int>(0, (n, k) => n + readIntValue(sheet[k]));
        }

        hit.removeWhere((r) => r['criticalShieldProtected'] == true);
        hit.sort((a, b) => strength(a).compareTo(strength(b)));
        final count = meccanioElectrocutionCount(
          readIntValue(data['percentile']),
          hit.length,
        );
        final effect = OculumStructuredEffect(
          id: 'meccanio_folgorato',
          type: 'modifica_statistica',
          target: 'tiro_globale',
          valueExpression: '-3',
          mode: 'temporaneo',
          duration: '1',
          recipient: 'alleato',
          customDisplayText: 'Folgorato: −3 ai tiri per un turno',
        );
        if (count > 0) {
          final sourceLabel = 'Meccanio · Folgorazione · $group';
          applyStructuredEffectsOnActivation(
            [effect],
            source: sourceLabel,
            applyFusionBonus: false,
          );
          unawaited(
            deliverPendingSupport(
              minimum: count,
              maximum: count,
              selectedTags: hit
                  .take(count)
                  .map((r) => '${r['targetTag']}')
                  .toList(),
              sourcePrefix: sourceLabel,
            ),
          );
        }
        aggiungiLog(
          '[MECCANIO] Folgorazione: ${readIntValue(data['percentile']) + 1}/100, $count bersagli colpiti ricevono −3 ai tiri per un turno.',
        );
      }
      salvaSchedaCorrenteInMemoria();
      programmaSalvataggio();
    } finally {
      if (ownerIndex != original) {
        schedaCorrente = original;
        caricaStatoDaJson(schedePersonaggio[original]);
        ripristinaImpostazioniGlobali(global);
      }
    }
  }

  void sendMeccanioDischarge(Map<String, dynamic> resistedAttack, int defense) {
    if (!isMeccanio || resistedAttack['reactionOf'] != null) return;
    final source = sheetTagAt(schedaCorrente);
    final id = 'meccanio-counter:${resistedAttack['id']}';
    if (onlineCombatRequests.containsKey(id)) return;
    final request = <String, dynamic>{
      'id': id,
      'attackGroupId': id,
      'scope': permissionScope,
      'encounterId': onlineCombatEncounterId,
      'sourceTag': source,
      'sourceName': realtimeDisplayName(),
      'targetTag': resistedAttack['sourceTag'],
      'targetName': resistedAttack['sourceName'],
      'attack': defense,
      'natural': 10,
      'damage': 3 + min(3, 1 + activeCriticalLevel() ~/ 3),
      'damageTargetCount': 1,
      'element': 'fulmine',
      'choice': 'vc',
      'level': activeCriticalLevel(),
      'grade': activeCriticalGrade(),
      'reactionOf': resistedAttack['id'],
      'status': 'pending',
      'meccanioAttack': {'kind': 'counter'},
      'difficulty': normalizedCampaignDifficulty(),
    };
    onlineCombatRequests[id] = request;
    receiveLocalCombatAttack(request);
    unawaited(sendOnlineCombatRequest(request));
  }
}
