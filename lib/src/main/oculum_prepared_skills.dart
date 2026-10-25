part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int oculumPreparedKeepChance({
  required int concentration,
  int scrollGrade = 0,
  int ownerGrade = 0,
  int attackerGrade = 0,
}) =>
    (concentration +
            3 * max(0, scrollGrade) -
            max(0, attackerGrade - ownerGrade - 1) * 10)
        .clamp(0, 100)
        .toInt();
List<OculumTechniqueScrollProfile> oculumPreparedScrollProfiles() => [
  for (final definition in const [
    ('raggio_zenit', 'Raggio dello Zenit', 'luce'),
    ('nucleo_folgore', 'Nucleo della folgore', 'fulmine'),
  ])
    OculumTechniqueScrollProfile(
      definition.$1,
      definition.$2,
      'Scuole delle tecniche a carica crescente',
      definition.$3,
      [
        OculumStructuredEffect(
          id: 'prepared:${definition.$1}',
          type: 'preparazione',
          target: 'attacco',
          activationOption: 'concentrazione',
          valueExpression: '40',
          chargeOculumPerTurn: 1,
          chargeDamageSteps: const [40, 80, 120, 180],
          customDisplayText:
              'Attivazione: 2 Oculum e una Azione. Rilascio +40% Danni; ogni incremento in un tuo turno costa 1 Oculum e una Azione: +80%, +120%, +180%. Puoi rilasciare con Azione o Reazione anche prima del massimo. Concentrazione controllata solo se perdi Vita.',
        ),
      ],
    ),
  for (final definition in const [
    (
      'nucleo_sismico',
      'Nucleo sismico',
      'roccia',
      'attacco',
      'concentrazione',
      100,
    ),
    (
      'lancia_crepuscolo',
      'Lancia del crepuscolo',
      'buio',
      'attacco',
      'concentrazione',
      120,
    ),
    (
      'sussurro_guardiano',
      'Sussurro del Guardiano',
      'luce',
      'difesa',
      'sussurro',
      3,
    ),
    (
      'sigillo_presagio',
      'Sigillo del presagio',
      'psico',
      'difesa',
      'concentrazione',
      4,
    ),
  ])
    OculumTechniqueScrollProfile(
      definition.$1,
      definition.$2,
      'Scuole delle tecniche preparate',
      definition.$3,
      [
        OculumStructuredEffect(
          id: 'prepared:${definition.$1}',
          type: 'preparazione',
          target: definition.$4,
          activationOption: definition.$5,
          valueExpression: '${definition.$6}',
          customDisplayText:
              'Prepara con una Azione e un tiro di ${definition.$5}; il prossimo ${definition.$4} rilascia il potere usando normalmente Azione o Reazione, senza una terza spesa. La perdita di Vita può interrompere la preparazione. Solo durante l’uso della scroll: +3 × suo Grado alla Concentrazione richiesta; la skill appresa non conserva questo bonus.',
        ),
      ],
    ),
];

extension _OculumPreparedSkills on _OculumHomePageState {
  Widget rollEmpowermentButton() => OutlinedButton.icon(
    key: const ValueKey('fight_roll_empowerment'),
    onPressed: showRollEmpowermentDialog,
    icon: const Icon(Icons.auto_awesome),
    label: Text(
      'Potenziamento ${oculumTiroPreparato()}/${oculumTiroSpendCap()}',
    ),
  );
  Future<void> showRollEmpowermentDialog() async {
    if (oculumTiroLimiteRegola() <= 0) return;
    final origin = currentSheetScrollId();
    final input = TextEditingController(text: '${oculumTiroPreparato()}');
    final selected = await oculumShowDialogUntilClosed<int>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, refresh) {
          final cap = oculumTiroSpendCap();
          final amount = oculumParseSkillUseAmount(input.text);
          final valid = amount != null && amount >= 0 && amount <= cap;
          return AlertDialog(
            title: const Text('Potenziamento'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scegli Oculum da preparare: 0–$cap. Ogni punto dà +3 al prossimo tiro; se attacchi, anche +2 Danni. L’Oculum viene consumato al tiro.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('fight_roll_empowerment_amount'),
                    controller: input,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Oculum immesso',
                      errorText: valid
                          ? null
                          : 'Inserisci un intero tra 0 e $cap',
                    ),
                    onChanged: (_) => refresh(() {}),
                  ),
                  if (valid)
                    Text(
                      'Bonus preparato: +${amount * 3} al tiro; +${amount * 2} Danni se attacchi.',
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Annulla'),
              ),
              FilledButton(
                key: const ValueKey('fight_roll_empowerment_confirm'),
                onPressed: valid ? () => Navigator.pop(dialog, amount) : null,
                child: const Text('Prepara'),
              ),
            ],
          );
        },
      ),
    );
    input.dispose();
    if (selected == null ||
        !mounted ||
        origin != currentSheetScrollId() ||
        selected > oculumTiroSpendCap()) {
      return;
    }
    setState(() => oculumTiroController.text = '$selected');
    aggiungiLog(
      '[POTENZIAMENTO] Preparati $selected Oculum: +${selected * 3} al prossimo tiro; +${selected * 2} Danni se è un attacco. Consumo al tiro.',
    );
    programmaSalvataggio();
  }

  void prepareConcentratedSkill(
    OculumStructuredEffect effect,
    int value,
    String source,
  ) {
    final stat = hiddenEyeStats
        .where(
          (s) =>
              s.id ==
              (effect.activationOption == 'sussurro'
                  ? 'sussurro'
                  : 'concentrazione'),
        )
        .firstOrNull;
    final natural = tiraD20();
    final oculumSpend = consumaOculumTiro();
    final scrollBonus = 3 * effect.sourceScrollGrade;
    final total = rollTotalWithCritical(natural, 20, [
      (stat == null ? 0 : hiddenEyeTotal(stat)) +
          scrollBonus +
          oculumSpend.bonus +
          tiroGlobaleBonus() +
          consumeCombatHelp() +
          consumePendingReactionRollBonus() +
          (stat == null ? 0 : hiddenEyeStatRollQuickBonus(stat)),
    ]);
    final bonus =
        max(1, total ~/ 5) + (effect.target == 'difesa' ? max(0, value) : 0);
    planarState['preparedSkill'] = {
      'source': source,
      'kind': effect.target,
      'roll': total,
      'natural': natural,
      'rollBonus': bonus,
      'power': max(0, value),
      'scrollGrade': effect.sourceScrollGrade,
      'oculumKeepBonus': oculumSpend.bonus,
      if (effect.chargeOculumPerTurn > 0) ...{
        'growing': true,
        'chargeCount': 0,
        'chargeCost': effect.chargeOculumPerTurn,
        'chargeDamageSteps': effect.chargeDamageSteps.isEmpty
            ? [40, 80, 120, 180]
            : effect.chargeDamageSteps,
        'power': effect.chargeDamageSteps.isEmpty
            ? 40
            : effect.chargeDamageSteps.first,
        'lastChargeTurn': playerReportedTurn,
      },
    };
    aggiungiLog(
      '[PREPARAZIONE] $source · ${effect.activationOption}: $total (d20 $natural; scroll +$scrollBonus; ${oculumTiroLogLabel(oculumSpend)}). Prossim${effect.target == 'difesa' ? 'a difesa' : 'o attacco'}: +$bonus al tiro${effect.target == 'attacco' ? ', +${max(0, value) + max(0, total)}% danni' : ''}. Rilascio con la normale Azione/Reazione, senza un altro costo.',
    );
    programmaSalvataggio();
  }

  bool get hasGrowingPreparedSkill =>
      planarState['preparedSkill'] is Map &&
      (planarState['preparedSkill'] as Map)['growing'] == true;
  Future<void> growPreparedSkill() async {
    if (!hasGrowingPreparedSkill) return;
    final prepared = Map<String, dynamic>.from(
      planarState['preparedSkill'] as Map,
    );
    final steps = (prepared['chargeDamageSteps'] as List)
        .map(readIntValue)
        .toList();
    final charge = readIntValue(prepared['chargeCount']);
    final cost = readIntValue(prepared['chargeCost']);
    final turn = playerReportedTurn;
    if (charge + 1 >= steps.length ||
        readIntValue(prepared['lastChargeTurn']) == turn) {
      aggiungiLog('[CARICA] Un potenziamento per tuo turno, fino al massimo.');
      return;
    }
    if (oculumTotale() < cost) {
      aggiungiLog('[CARICA] Oculum insufficiente: servono $cost.');
      return;
    }
    final origin = currentSheetScrollId();
    if (currentTurnTrackerIsActive() && !await requestUtilitySpend('azione')) {
      return;
    }
    if (!mounted ||
        currentSheetScrollId() != origin ||
        !hasGrowingPreparedSkill) {
      return;
    }
    if (spendOculum(cost, scheduleSave: false) != cost) return;
    prepared['chargeCount'] = charge + 1;
    prepared['lastChargeTurn'] = turn;
    prepared['power'] = steps[charge + 1];
    planarState['preparedSkill'] = prepared;
    aggiungiLog(
      '[CARICA] ${prepared['source']} · ${charge + 1}/${steps.length - 1}: +${steps[charge + 1]}% Danni; spesi $cost Oculum e Azione. Puoi rilasciare col prossimo attacco.',
    );
    programmaSalvataggio();
    scheduleRealtimeOculumChanged();
    if (mounted) setState(() {});
  }

  Future<void> useLearnedPreparedSkill(Map<String, dynamic> data) async {
    final skill = skills
        .where((s) => s.scrollData['id'] == data['id'])
        .firstOrNull;
    if (skill == null) return;
    skill.ensureForms();
    final form = skill.forme.first;
    final effects = oculumScrollCombatEffects({...data, 'learned': true});
    final cooldown = form.cooldownStrutturato ??= OculumAbilityCooldown(
      amount: readIntValue(data['cooldownTurns'], fallback: 4),
    );
    await useConfiguredAbility(
      source: skill.nome,
      effects: effects,
      cost:
          form.costoStrutturato ??
          oculumStructuredCostFromText(form.costo) ??
          OculumSkillCost(resource: 'oculum', amountExpression: '2'),
      cooldown: cooldown,
    );
  }

  Map<String, dynamic> takePreparedSkill(String kind) {
    final raw = planarState['preparedSkill'];
    if (raw is! Map || raw['kind'] != kind) return {};
    final prepared = Map<String, dynamic>.from(raw);
    planarState.remove('preparedSkill');
    aggiungiLog(
      '[RILASCIO] ${prepared['source']} · $kind potenziato; consumata soltanto la normale risorsa del tiro.',
    );
    return prepared;
  }

  bool interruptPreparedSkill({int attackerGrade = 0, int? percentile}) {
    if (planarState['preparedSkill'] is! Map) return false;
    final prepared = Map<String, dynamic>.from(
      planarState['preparedSkill'] as Map,
    );
    final stat = hiddenEyeStats
        .where((s) => s.id == 'concentrazione')
        .firstOrNull;
    final chance = oculumPreparedKeepChance(
      concentration:
          (stat == null ? 0 : hiddenEyeTotal(stat)) +
          readIntValue(prepared['oculumKeepBonus']),
      scrollGrade: readIntValue(prepared['scrollGrade']),
      ownerGrade: activeCriticalGrade(),
      attackerGrade: attackerGrade,
    );
    final roll = percentile ?? Random.secure().nextInt(100);
    final kept = roll < chance;
    if (!kept) planarState.remove('preparedSkill');
    aggiungiLog(
      '[CONCENTRAZIONE] ${prepared['source']} · ${roll + 1}/100, mantenimento $chance%: ${kept ? 'mantenuta' : 'interrotta; bonus perso'}.',
    );
    programmaSalvataggio();
    return !kept;
  }
}
