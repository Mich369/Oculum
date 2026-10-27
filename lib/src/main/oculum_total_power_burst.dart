part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int oculumPowerBurstTurns(int power, int die) =>
    max(1, die) + max(0, power) ~/ 160;
int oculumPowerBurstAccuracy(int adaptation) => max(2, 10 - adaptation);

bool oculumFormulaUsesTotalPower(String expression) => RegExp(
  r'\b(?:pt|potenza_totale|potenzatotale|total_power|totalpower)\b',
  caseSensitive: false,
).hasMatch(expression);

/// Passive quick commands cannot grant a cost-free power-based benefit.
/// Their original text is preserved in the editor and in the save.
String oculumPassiveQuickTextWithoutTotalPower(String text) =>
    text.replaceAllMapped(
      RegExp(r'@[^@;,\n]+'),
      (match) => oculumFormulaUsesTotalPower(match[0]!) ? '' : match[0]!,
    );

/// Sum the PT contribution of all effects, excluding fixed additive values.
/// The same activation makes one roll, even when split between damage/shield.
double oculumTotalPowerExhaustionChance(
  Iterable<OculumStructuredEffect> effects,
  Map<String, num> variables,
) {
  final power = max(1, (variables['potenza_totale'] ?? 0).toDouble());
  var fraction = 0.0;
  for (final effect in effects.where((e) => e.enabled)) {
    // The historical burst already applies its own longer exhaustion.
    if (effect.target == 'total_power_burst') continue;
    for (final expression in [effect.valueExpression, effect.duration]) {
      if (!oculumFormulaUsesTotalPower(expression)) continue;
      try {
        final withPower = oculumEvaluateFormula(expression, {
          ...variables,
          'potenza_totale': power,
        });
        final withoutPower = oculumEvaluateFormula(expression, {
          ...variables,
          'potenza_totale': 0,
        });
        fraction += ((withPower - withoutPower) / power).abs();
      } on FormatException {
        // A formula using PT as a divisor still uses the full reference.
        fraction += 1;
      }
    }
  }
  return (fraction * 100).clamp(0, 100).toDouble();
}

ArtSkill oculumTotalPowerBurstSkill({bool will = false}) {
  final name = will ? 'Impeto totale' : 'Scarica totale';
  final resource = will ? 'volonta' : 'oculum';
  return ArtSkill(
    nome: name,
    evo1:
        'I/Un singolo attacco riceve +Potenza totale ai Danni. '
        'Il prossimo tiro per colpire e il primo tiro nemico contro di te ricevono '
        '+max(2, 10 − Adattamento). Azzera subito tutte le Reazioni, normali, '
        'veloci e gratuite, e impedisce ogni nuovo guadagno, anche da skill o altre '
        'fonti, per 1d3 + Potenza totale ÷160 per difetto turni personali. '
        'Costo 5 ${will ? 'Volontà' : 'Oculum'}, CD 3 turni. '
        'Una nuova attivazione sostituisce il bonus in attesa e non accorcia lo Sfinimento.',
    tipiPerLivello: List.filled(5, 'Attiva · Attacco'),
    risorseCostoPerLivello: List.filled(5, resource),
    oculumMinimiPerLivello: [5, 0, 0, 0, 0],
    oculumMassimiPerLivello: [5, 0, 0, 0, 0],
    cooldownPerLivello: List.generate(
      5,
      (_) => OculumAbilityCooldown(amount: 3),
    ),
    effettiPerLivello: [
      [
        OculumStructuredEffect(
          id: '${resource}_total_power_burst',
          type: 'planar',
          target: 'total_power_burst',
          valueExpression: 'potenza_totale',
          duration: '0',
          diceExpression: '1d3',
          diceDestination: 'durata',
          recipient: 'se_stesso',
          customDisplayText:
              'Potenza per un colpo · Sfinimento 1d3 + Potenza/160',
        ),
        OculumStructuredEffect(
          id: '${resource}_total_power_accuracy',
          type: 'planar',
          target: 'total_power_accuracy',
          valueExpression: '10-adattamento',
          duration: '1',
          recipient: 'se_stesso',
          customDisplayText: 'Bonus ai due tiri per colpire (minimo +2)',
        ),
      ],
    ],
  );
}

extension _OculumTotalPowerBurst on _OculumHomePageState {
  bool get totalPowerExhausted =>
      readIntValue(planarState['totalPowerExhaustionTurns']) > 0;

  bool totalPowerExhaustedForTag(String tag) {
    if (tag == sheetTagAt(schedaCorrente)) return totalPowerExhausted;
    final token = escapeToken(tag);
    if (token != null && token.containsKey('totalPowerExhaustionTurns')) {
      return readIntValue(token['totalPowerExhaustionTurns']) > 0;
    }
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0) return false;
    final runtime = schedePersonaggio[index]['planarRuntime'];
    return runtime is Map &&
        readIntValue(runtime['totalPowerExhaustionTurns']) > 0;
  }

  bool totalPowerTokenExhausted(Map<String, dynamic> token) =>
      totalPowerExhaustedForTag(publicInitiativeSourceTag(token)) ||
      readIntValue(token['totalPowerExhaustionTurns']) > 0;

  void clearExhaustedTokenReactions(Map<String, dynamic> token) {
    for (final key in const [
      'extraNormalReactionCurrent',
      'extraNormalReactionQueued',
      'extraFastReactionCurrent',
      'extraFastReactionQueued',
      'outsideNormal',
      'outsideFast',
      'pendingReactionRollBonus',
      'pendingFastReactionRollBonus',
      'pendingFastReactionConsequenceBonus',
    ]) {
      token[key] = 0;
    }
    token['reactionUsed'] = max(
      1,
      readIntValue(token['reactionMax'], fallback: 1),
    );
    token['reactionFastUsed'] = max(
      1,
      readIntValue(token['reactionFastMax'], fallback: 1),
    );
    token['reactionUsedRound'] = _onlineCombatRound();
    token['reactionPoolRound'] = _onlineCombatRound();
  }

  void clearTotalPowerReactions() {
    final tag = sheetTagAt(schedaCorrente);
    for (final token in [
      ...masterInitiativeTokens,
      ..._writableOnlineCombatTokens(),
    ]) {
      if (publicInitiativeSourceTag(token) == tag) {
        token['totalPowerExhaustionTurns'] = readIntValue(
          planarState['totalPowerExhaustionTurns'],
        );
        clearExhaustedTokenReactions(token);
      }
    }
    for (final request in onlineCombatRequests.values) {
      if (request['targetTag'] == tag) {
        request['freeReaction'] = false;
        request['criticalReaction'] = false;
        request['schiantoReactionAvailable'] = false;
        request['reactionUsed'] = true;
      }
    }
    schedePersonaggio[schedaCorrente].remove(
      'combatSchiantoReactionBonusPending',
    );
    activeStructuredEffects.removeWhere(
      (effect) =>
          const {
            'reazione',
            'reazione_veloce',
          }.contains(normalizedStructuredTarget('${effect['target']}')) &&
          readIntValue(effect['value']) > 0,
    );
  }

  void activateTotalPowerBurst(int power, int die) {
    final value = max(0, power);
    planarState['totalPowerBurstDamage'] = value;
    final adaptation = hiddenEyeStats
        .where((s) => s.id == 'adattamento')
        .firstOrNull;
    final accuracy = oculumPowerBurstAccuracy(
      adaptation == null ? 0 : hiddenEyeTotal(adaptation),
    );
    planarState['totalPowerBurstAccuracy'] = accuracy;
    planarState['totalPowerExposureAccuracy'] = accuracy;
    planarState['totalPowerExhaustionTurns'] = max(
      readIntValue(planarState['totalPowerExhaustionTurns']),
      oculumPowerBurstTurns(value, die),
    );
    clearTotalPowerReactions();
    invalidateDerivedDataCaches();
    aggiungiLog(
      '[POTENZA TOTALE] Bonus pari alla Potenza totale per un colpo; +$accuracy al prossimo tiro per colpire e al primo tiro nemico contro di te. Sfinimento: ${planarState['totalPowerExhaustionTurns']} turni personali, nessuna Reazione.',
    );
    unawaited(publishProvokerState());
    programmaSalvataggio();
  }

  bool activateTotalPowerEffect(
    OculumStructuredEffect effect,
    int value,
    int duration,
  ) {
    if (effect.target == 'total_power_burst') {
      activateTotalPowerBurst(value, duration);
      return true;
    }
    if (effect.target == 'total_power_accuracy') {
      planarState['totalPowerBurstAccuracy'] = max(2, value);
      planarState['totalPowerExposureAccuracy'] = max(2, value);
      return true;
    }
    return false;
  }

  void applyTotalPowerBurstAttack(Map<String, dynamic> request) {
    if (request.containsKey('totalPowerBurstApplied') ||
        request['sourceTag'] != sheetTagAt(schedaCorrente) ||
        !planarState.containsKey('totalPowerBurstDamage')) {
      return;
    }
    final damage = readIntValue(planarState.remove('totalPowerBurstDamage'));
    final accuracy = readIntValue(
      planarState.remove('totalPowerBurstAccuracy'),
    );
    request['totalPowerBurstApplied'] = true;
    request['totalPowerBurstDamage'] = damage;
    request['totalPowerBurstAccuracy'] = accuracy;
    request['damage'] = readIntValue(request['damage']) + damage;
    request['damageTotal'] =
        readIntValue(
          request['damageTotal'],
          fallback: readIntValue(request['damage']) - damage,
        ) +
        damage;
    request['attack'] = readIntValue(request['attack']) + accuracy;
    programmaSalvataggio();
  }

  void applyTotalPowerExposure(Map<String, dynamic> request) {
    if (request.containsKey('totalPowerExposureAccuracy') ||
        request['targetTag'] != sheetTagAt(schedaCorrente) ||
        !planarState.containsKey('totalPowerExposureAccuracy')) {
      return;
    }
    final source = escapeToken('${request['sourceTag']}');
    final target = escapeToken('${request['targetTag']}');
    if (source != null && target != null && source['side'] == target['side']) {
      return;
    }
    final accuracy = readIntValue(
      planarState.remove('totalPowerExposureAccuracy'),
    );
    request['totalPowerExposureAccuracy'] = accuracy;
    request['attack'] = readIntValue(request['attack']) + accuracy;
    programmaSalvataggio();
  }

  Widget totalPowerBurstStatus() {
    final pending = planarState.containsKey('totalPowerBurstDamage');
    final exposed = planarState.containsKey('totalPowerExposureAccuracy');
    if (!totalPowerExhausted && !pending && !exposed) {
      return const SizedBox.shrink();
    }
    return ListTile(
      leading: const Icon(Icons.flash_on),
      title: Text(
        totalPowerExhausted
            ? 'Sfinimento · ${planarState['totalPowerExhaustionTurns']} turni'
            : 'Potenza totale · bonus in attesa',
      ),
      subtitle: Text(
        [
          if (totalPowerExhausted)
            'Tutte le Reazioni azzerate e bloccate, anche da skill.',
          if (pending)
            'Prossimo colpo: ${auraCanReadPower ? '+${planarState['totalPowerBurstDamage']}' : '+Potenza totale'} Danni, +${planarState['totalPowerBurstAccuracy']} per colpire.',
          if (exposed)
            'Primo tiro nemico contro di te: +${planarState['totalPowerExposureAccuracy']}.',
        ].join('\n'),
      ),
    );
  }

  void tickTotalPowerExhaustion() {
    if (!totalPowerExhausted) return;
    clearTotalPowerReactions();
    planarState['totalPowerExhaustionTurns'] =
        readIntValue(planarState['totalPowerExhaustionTurns']) - 1;
    final token = escapeToken(sheetTagAt(schedaCorrente));
    if (token != null) {
      token['totalPowerExhaustionTurns'] = readIntValue(
        planarState['totalPowerExhaustionTurns'],
      );
    }
    invalidateDerivedDataCaches();
    unawaited(publishProvokerState());
    if (!totalPowerExhausted) {
      aggiungiLog(
        '[SFINIMENTO] Terminato: le nuove Reazioni possono essere ricevute normalmente. Le Reazioni eliminate restano consumate.',
      );
    }
  }
}
