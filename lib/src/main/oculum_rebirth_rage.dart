part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const oculumFeralisCommonElements = {
  'fuoco',
  'acqua',
  'gelo',
  'terra',
  'vento',
  'fulmine',
};
int oculumFuocherelliRevivalHp(int maximum) =>
    min(max(0, maximum), max(20, (max(0, maximum) * .05).ceil()));
int oculumFeralisDamage(int damage, int turns, bool active) =>
    active ? max(0, damage) * 2 + max(0, turns) * 5 : damage;

extension _OculumRebirthRage on _OculumHomePageState {
  bool get feralisFuryActive => planarState['feralisFury'] == true;
  int get feralisFuryDefense => feralisFuryActive
      ? readIntValue(planarState['feralisFuryPaidTurns']) * 2
      : 0;
  void startFeralisFury() {
    if (hpCorrenti() <= 0 || hpCorrenti() * 2 > maxHp() || feralisFuryActive) {
      return;
    }
    planarState['feralisFury'] = true;
    planarState['feralisFuryPaidTurns'] = 0;
    final tokens = onlineCombatTokens();
    final active = _usesLocalMasterInitiative
        ? masterInitiativeActiveIndex
        : readIntValue(realtimeVisibleInitiativeSnapshot['activeIndex']);
    planarState['feralisFurySkipTick'] =
        active < 0 ||
        active >= tokens.length ||
        onlineCombatTokenTag(tokens[active]) != sheetTagAt(schedaCorrente);
    addOculum((oculumMassimo() / 4).ceil());
    aggiungiLog(
      '[FURIA PRIMORDIALE] Danni ×2, danni ricevuti dimezzati. Recuperato ¼ dell’Oculum massimo; mantenimento 3 dal secondo turno personale.',
    );
    invalidateDerivedDataCaches();
  }

  void stopFeralisFury() {
    planarState.remove('feralisFury');
    planarState.remove('feralisFuryPaidTurns');
    planarState.remove('feralisFurySkipTick');
    invalidateDerivedDataCaches();
    aggiungiLog(
      '[FURIA PRIMORDIALE] Trasformazione terminata; rimossi i suoi bonus.',
    );
    if (mounted) setState(() {});
    programmaSalvataggio();
  }

  void tickFeralisFury() {
    if (!feralisFuryActive) return;
    if (planarState.remove('feralisFurySkipTick') == true) return;
    if (oculumTotale() < 3) {
      stopFeralisFury();
      return;
    }
    if (spendOculum(3) != 3) {
      stopFeralisFury();
      return;
    }
    final paid = readIntValue(planarState['feralisFuryPaidTurns']) + 1;
    planarState['feralisFuryPaidTurns'] = paid;
    aggiungiLog(
      '[FURIA] −3 Oculum; bonus cumulato +${paid * 5} Danni e +${paid * 2} Difesa.',
    );
    invalidateDerivedDataCaches();
  }

  int feralisAdaptDamage(int damage, String element) {
    final effect = faunaPassive('feralis_elemental_resistance');
    if (effect == null ||
        !oculumFeralisCommonElements.contains(element) ||
        damage <= 0) {
      return damage;
    }
    final values = Map<String, dynamic>.from(
      planarState['feralisElementResistance'] as Map? ?? {},
    );
    final resistance = readIntValue(values[element]).clamp(0, 150);
    values[element] = min(
      150,
      resistance + max(0, readIntValue(effect.valueExpression, fallback: 15)),
    );
    planarState['feralisElementResistance'] = values;
    final signedDamage = (damage * (1 - resistance / 100)).round();
    if (signedDamage < 0) {
      final healed = min(max(0, maxHp() - hpCorrenti()), -signedDamage);
      currentHpController.text = '${hpCorrenti() + healed}';
      aggiungiLog(
        '[RESISTENZA ELEMENTALE] $element $resistance%: +$healed Vita; prossimo colpo ${values[element]}%.',
      );
      return 0;
    }
    aggiungiLog(
      '[RESISTENZA ELEMENTALE] $element $resistance% → ${values[element]}% per il prossimo colpo.',
    );
    return signedDamage;
  }

  int tryFuocherelliSecondLife(
    int hp,
    String incomingElement, {
    int? shieldRoll,
    int? existingShield,
  }) {
    final definition = faunaPassive('fuocherelli_second_life');
    if (hp > 0 ||
        definition == null ||
        incomingElement == 'acqua' ||
        planarState['fuocherelliSecondLifeUsed'] == true) {
      return hp;
    }
    final form = readIntValue(
      definition.valueExpression,
      fallback: 1,
    ).clamp(1, 3);
    final die = const [120, 200, 250][form - 1];
    final level = max(0, leggiNumero(livelloController));
    final shield =
        (shieldRoll ?? Random.secure().nextInt(die) + 1).clamp(1, die) +
        (form == 2
            ? level
            : form == 3
            ? level * 3
            : 0);
    planarState['fuocherelliSecondLifeUsed'] = true;
    scudoController.text = '${(existingShield ?? scudo()) + shield}';
    feriteMorte = 0;
    personaggioCaduto = false;
    aggiungiLog(
      '[SECONDA VITA] Rinasci con ${oculumFuocherelliRevivalHp(maxHp())} Vita e +$shield Scudo. Esplosione Fuoco entro 3 metri; non si ripete prima del Riposo Lungo.',
    );
    unawaited(
      sendFaunaBurst(
        sourceTag: sheetTagAt(schedaCorrente),
        centerTag: sheetTagAt(schedaCorrente),
        receipt:
            'second-life:$onlineCombatEncounterId:${sheetTagAt(schedaCorrente)}',
        name: 'Seconda Vita',
        element: 'fuoco',
        damage: 10 + level * 2,
        radius: 3,
        bothSides: true,
      ),
    );
    return oculumFuocherelliRevivalHp(maxHp());
  }

  void recordFaunaFallenTurn() {
    planarState['faunaFallenPersonalTurn'] = playerReportedTurn;
    planarState['faunaFallenRound'] = _onlineCombatRound();
    final tokens = onlineCombatTokens();
    final ownIndex = tokens.indexWhere(
      (t) => onlineCombatTokenTag(t) == sheetTagAt(schedaCorrente),
    );
    final active = _usesLocalMasterInitiative
        ? masterInitiativeActiveIndex
        : readIntValue(realtimeVisibleInitiativeSnapshot['activeIndex']);
    planarState['faunaFallenDeadlineRound'] =
        _onlineCombatRound() + (active >= ownIndex ? 1 : 0);
    planarState['faunaFallenIndex'] = ownIndex;
  }

  bool get faunaCanBeReanimated {
    if (hpCorrenti() > 0) return false;
    if (!planarState.containsKey('faunaFallenPersonalTurn')) {
      return true; // Legacy/manual death, still editable by Master.
    }
    final round = _onlineCombatRound(),
        deadline = readIntValue(planarState['faunaFallenDeadlineRound']);
    final active = _usesLocalMasterInitiative
        ? masterInitiativeActiveIndex
        : readIntValue(realtimeVisibleInitiativeSnapshot['activeIndex']);
    return playerReportedTurn ==
            readIntValue(planarState['faunaFallenPersonalTurn']) &&
        (round < deadline ||
            round == deadline &&
                active < readIntValue(planarState['faunaFallenIndex']));
  }

  Future<bool> prepareFaunaReanimation() async {
    final origin = currentSheetScrollId(), scope = permissionScope;
    final candidates = onlineCombatTokens()
        .where(
          (t) =>
              onlineCombatTokenTag(t) != origin &&
              combatScoutSide(onlineCombatTokenTag(t)) ==
                  combatScoutSide(origin) &&
              (masterInitiativeTokenIsDead(t) ||
                  masterInitiativeTokenIsDowned(t) ||
                  readIntValue(t['currentHp'], fallback: 1) <= 0),
        )
        .toList();
    if (candidates.isEmpty || hpCorrenti() <= 0) {
      aggiungiLog('[RIANIMAZIONE] Nessun compagno caduto disponibile.');
      return false;
    }
    String chosen = onlineCombatTokenTag(candidates.first);
    int amount = 1;
    final life = hpCorrenti();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Rianimazione · cedi Vita'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: chosen,
                  items: [
                    for (final t in candidates)
                      DropdownMenuItem(
                        value: onlineCombatTokenTag(t),
                        child: Text('${t['name']}'),
                      ),
                  ],
                  onChanged: (v) => update(() => chosen = v ?? chosen),
                ),
                TextFormField(
                  initialValue: '1',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Vita da cedere (1–$life)',
                  ),
                  onChanged: (v) => update(
                    () => amount = (int.tryParse(v) ?? 0).clamp(0, life),
                  ),
                ),
                Text(
                  'Perdi $amount Vita su $life; rimangono ${life - amount}.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: amount < 1 ? null : () => Navigator.pop(dialog, true),
              child: const Text('Continua'),
            ),
          ],
        ),
      ),
    );
    if (!mounted ||
        accepted != true ||
        origin != currentSheetScrollId() ||
        scope != permissionScope) {
      return false;
    }
    if (amount > life * .75) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Conferma il sacrificio di Vita'),
          content: Text(
            'Stai per perdere $amount Vita su $life (${(amount / life * 100).round()}%). Ti rimarranno ${life - amount} Vita${amount == life ? ': cadrai anche tu' : ''}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Conferma e cedi Vita'),
            ),
          ],
        ),
      );
      if (confirmed != true ||
          !mounted ||
          origin != currentSheetScrollId() ||
          scope != permissionScope) {
        return false;
      }
    }
    planarState['faunaPreparedReanimation'] = {
      'target': chosen,
      'amount': amount,
    };
    return true;
  }

  Future<void> commitFaunaReanimation() async {
    final prepared = planarState.remove('faunaPreparedReanimation');
    if (prepared is! Map) return;
    final amount = readIntValue(prepared['amount']);
    if (amount < 1 || hpCorrenti() < amount) return;
    final id = 'revive:${DateTime.now().microsecondsSinceEpoch}';
    final source = sheetTagAt(schedaCorrente), target = '${prepared['target']}';
    currentHpController.text = '${hpCorrenti() - amount}';
    controllaCadutaDopoDanno();
    final pending = Map<String, dynamic>.from(
      planarState['faunaPendingRevives'] as Map? ?? {},
    );
    pending[id] = {'amount': amount, 'target': target};
    planarState['faunaPendingRevives'] = pending;
    final request = <String, dynamic>{
      'id': id,
      'kind': 'fauna_revive',
      'faunaReviveAmount': amount,
      'sourceTag': source,
      'targetTag': target,
      'sourceName': nomeController.text,
      'damage': 0,
      'attack': 0,
      'scope': permissionScope,
      'encounterId': onlineCombatEncounterId,
      'campaignId': permissionCampaignId,
      'status': 'pending',
    };
    onlineCombatRequests[id] = request;
    if (controlsOnlineCombatSheet(target)) {
      await receiveFaunaReanimation(request);
    } else {
      unawaited(sendOnlineCombatRequest(request));
    }
    programmaSalvataggio();
  }

  Future<void> receiveFaunaReanimation(Map<String, dynamic> request) async {
    final tag = '${request['targetTag']}',
        index = localSheetIndexForOculumTag('${request['targetTag']}');
    if (index < 0 || !controlsOnlineCombatSheet(tag)) return;
    final original = schedaCorrente;
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    var received = 0;
    try {
      if (index != original) {
        schedaCorrente = index;
        caricaStatoDaJson(schedePersonaggio[index]);
        ripristinaImpostazioniGlobali(global);
      }
      final key = 'revive:${request['id']}';
      final previous = planarState[key];
      if (previous is int) {
        received = previous;
      } else if (faunaCanBeReanimated) {
        received = min(
          maxHp(),
          max(0, readIntValue(request['faunaReviveAmount'])),
        );
        if (received > 0) {
          currentHpController.text = '$received';
          personaggioCaduto = false;
          feriteMorte = 0;
          syncCurrentSheetDeathStateToInitiative();
        }
        planarState[key] = received;
      } else {
        planarState[key] = 0;
      }
      salvaSchedaCorrenteInMemoria();
      final reply = {
        ...request,
        'faunaReviveReceived': received,
        'status': 'resolved',
      };
      if (controlsOnlineCombatSheet('${request['sourceTag']}')) {
        finishFaunaReanimation(reply);
      }
      await realtimeService?.sendCombatEvent(
        'combat_defense',
        permissionEnvelope(reply),
      );
    } finally {
      if (index != original && mounted) {
        schedaCorrente = original;
        caricaStatoDaJson(schedePersonaggio[original]);
        ripristinaImpostazioniGlobali(global);
      }
    }
  }

  void finishFaunaReanimation(Map<String, dynamic> reply) {
    faunaForOwnedSheet('${reply['sourceTag']}', () {
      final pending = Map<String, dynamic>.from(
        planarState['faunaPendingRevives'] as Map? ?? {},
      );
      final reserved = pending.remove('${reply['id']}');
      if (reserved is! Map) return;
      final amount = readIntValue(reserved['amount']),
          received = readIntValue(
            reply['faunaReviveReceived'],
          ).clamp(0, readIntValue(reserved['amount']));
      final refund = amount - received;
      if (refund > 0) {
        currentHpController.text = '${min(maxHp(), hpCorrenti() + refund)}';
      }
      if (hpCorrenti() > 0) {
        personaggioCaduto = false;
        feriteMorte = 0;
        syncCurrentSheetDeathStateToInitiative();
      }
      planarState['faunaPendingRevives'] = pending;
      aggiungiLog(
        '[RIANIMAZIONE] Ceduti $received Vita${refund > 0 ? '; $refund restituiti perché non trasferibili' : ''}.',
      );
      programmaSalvataggio();
    });
  }
}
