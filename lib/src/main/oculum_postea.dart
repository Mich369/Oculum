part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumPostea on _OculumHomePageState {
  void ensurePosteaOffers() {
    final random = Random.secure();
    final healerPercent = const [150, 100, 75, 50][random.nextInt(4)];
    final definitions = <Map<String, dynamic>>[
      {
        'id': 'postea_meccanio',
        'kind': 'postea_meccanio',
        'name': 'Meccanio',
        'cost': 120,
        'desc':
            'Compagno robot di Postea, livello 0: RES 4, VOL 2, MAT 4, OCU 0. Può autoripararsi usando Meccanica al posto di Medicina; il padrone può ripararlo con il proprio tiro di Meccanica. Il critico raddoppia la cura, senza superare la Vita massima. Prezzo iniziale modificabile: 120 Obser.',
      },
      {
        'id': 'postea_anti_malus',
        'kind': 'postea_antimalus',
        'name': 'Anti malus di Rusty',
        'cost': 50,
        'desc':
            'Rimuove una condizione negativa scelta e impedisce di riottenerla fino alla fine del fight; fuori fight, fino alla fine del prossimo. Una copia in omaggio con il primo acquisto Postea per personaggio.',
      },
      {
        'id': 'postea_healer',
        'kind': 'postea_companion',
        'companion': 'healer',
        'name': 'Curatore vivente',
        'medicinePercent': healerPercent,
        'cost': healerPercent == 150
            ? 95
            : healerPercent == 100
            ? 80
            : healerPercent == 75
            ? 70
            : 60,
        'desc':
            'Creatura vivente di 100 HP con iniziativa propria. Cura il proprietario di 20 + Medicina propria ogni turno. Medicina fissata all’acquisto: 50%, 75%, 100% o 150% di quella del compratore, per eccesso. Prezzi proposti modificabili: 60/70/80/95 Obser.',
      },
      {
        'id': 'postea_pawn',
        'kind': 'postea_companion',
        'companion': 'pawn',
        'name': 'Pawn Postea',
        'cost': 250,
        'desc':
            '10 Resilienza, 15 Volontà, 25 Materia. Intercetta gli attacchi al proprietario. Ogni turno vivo in fight +3 Resilienza temporanea; morto rinasce soltanto a scontro vinto, con +1 permanente a tutte le statistiche. Iniziativa propria, al primo giro solo Reazione veloce.',
      },
      {
        'id': 'postea_core',
        'kind': 'postea_companion',
        'companion': 'core',
        'name': 'Core autoriparabile',
        'cost': 90,
        'desc':
            'Crea un costrutto del tuo livello all’acquisto. Prezzo 90 + tuo Livello + Grado ×2 Obser. Se distrutto si ripara da solo al Riposo Lungo. Statistiche e livello fissati all’acquisto.',
      },
      {
        'id': 'postea_katana_fate',
        'kind': 'postea_katana',
        'name': 'Katana del Fato',
        'cost': 200,
        'damage': 30,
        'desc':
            'Lama runica pallida incisa da anelli concentrici. +30 Danni da arma; mentre è equipaggiata annulla i critici negativi e concede una Ispirazione al cambio di sessione.',
      },
      {
        'id': 'postea_combat_gloves',
        'kind': 'postea_gloves',
        'name': 'Guanti da combattimento',
        'cost': 60,
        'damage': 15,
        'shield': 20,
        'desc':
            'Guanti di fibra nera con nocche runiche di ottone. +15 Danni soltanto con attacchi corpo a corpo; +20 Scudo a sessione. Bonus e valori modificabili.',
      },
      {
        'id': 'postea_runic_lens',
        'kind': 'postea_runic_lens',
        'name': 'Runa d’impatto per arma',
        'cost': 50,
        'damage': 20,
        'uses': 20,
        'desc':
            'Una runa fissata all’arma amplifica il colpo di +20 Danni per 20 attacchi. Devi selezionarla fra gli Attacchi; usi, Danni e prezzo modificabili.',
      },
    ];
    for (final offer in definitions) {
      if (!merchantStock.any((saved) => saved['id'] == offer['id'])) {
        merchantStock.add(offer);
      }
    }
  }

  InventoryItem posteaItem(Map<String, dynamic> offer) {
    final kind = '${offer['kind']}';
    final level = max(0, leggiNumero(livelloController));
    final grade = max(0, leggiNumero(gradoController));
    final data = <String, dynamic>{'postea': true};
    if (kind == 'postea_meccanio') data['alchemyPet'] = 'meccanio';
    if (kind == 'postea_companion') {
      data.addAll({
        'pawn': true,
        'posteaCompanion': offer['companion'],
        'recoveryLevel': level,
        'purchaseGrade': grade,
      });
      if (offer['companion'] == 'healer') {
        final medicine = hiddenEyeStats
            .where((s) => s.id == 'medicina')
            .firstOrNull;
        data['medicine'] =
            (max(0, medicine == null ? 0 : hiddenEyeTotal(medicine)) *
                    readIntValue(offer['medicinePercent'], fallback: 100) /
                    100)
                .ceil();
      }
    }
    if (kind == 'postea_antimalus') data['posteaAntimalus'] = true;
    if (kind == 'postea_katana') data['posteaKatana'] = true;
    if (kind == 'postea_gloves') data['posteaGloves'] = true;
    final skill = kind == 'postea_gloves' || kind == 'postea_runic_lens'
        ? oculumPosteaMitraAbility(readIntValue(offer['damage']))
        : null;
    if (skill != null) {
      skill.nome = '${offer['name']}';
      for (final form in skill.forme) {
        form.descrizione = '${offer['desc']}';
        for (final effect in form.effettiStrutturati) {
          effect.bypassResistance = false;
          effect.id = kind == 'postea_gloves'
              ? 'postea_melee_damage'
              : 'postea_runic_damage';
        }
      }
    }
    if (kind == 'postea_runic_lens') {
      data['posteaUses'] = max(1, readIntValue(offer['uses'], fallback: 20));
    }
    return InventoryItem(
      nome: '${offer['name']}',
      peso: kind == 'postea_meccanio'
          ? 6
          : kind == 'postea_katana'
          ? 1.5
          : .5,
      quantita: 1,
      note:
          '${offer['desc']}${data['medicine'] == null ? '' : ' Medicina propria: ${data['medicine']}.'}',
      livelloOggetto: level,
      gradoOggetto: grade,
      arma: kind == 'postea_katana',
      protegge: kind == 'postea_gloves',
      bonusDanno: kind == 'postea_katana'
          ? readIntValue(offer['damage'], fallback: 30)
          : 0,
      bonusScudo: kind == 'postea_gloves'
          ? readIntValue(offer['shield'], fallback: 20)
          : 0,
      bonusScudoIncludeGrado: true,
      craftData: data,
      ability: skill,
    );
  }

  List<int> meccanioRepairTargets() {
    final own = sheetTagAt(schedaCorrente);
    return [
      for (var index = 0; index < schedePersonaggio.length; index++)
        if (isMeccanioBookId(
              '${schedePersonaggio[index]['monsterBookSourceId'] ?? ''}',
            ) &&
            (sheetTagAt(index) == own ||
                schedePersonaggio[index]['meccanioOwnerTag'] == own))
          index,
    ];
  }

  Future<void> repairMeccanio(HiddenEyeStat stat) async {
    final origin = currentSheetScrollId();
    final targets = meccanioRepairTargets();
    if (targets.isEmpty) return;
    final target = targets.length == 1
        ? targets.single
        : await showDialog<int>(
            context: context,
            builder: (dialog) => SimpleDialog(
              title: const Text('Meccanica · scegli Meccanio'),
              children: [
                for (final index in targets)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(dialog, index),
                    child: Text(nomeSchedaPersonaggio(index)),
                  ),
              ],
            ),
          );
    if (!mounted || target == null || currentSheetScrollId() != origin) return;
    final targetTag = sheetTagAt(target);
    if (currentCombatIsActive() && !await spendCombatRollResource()) return;
    if (!mounted || currentSheetScrollId() != origin) return;
    await tiraSottotrattoOcchio(
      stat,
      actionLabel: 'Meccanica · ripara Meccanio',
      onResolved: (natural, total) {
        if (!mounted || currentSheetScrollId() != origin) return;
        final index = localSheetIndexForOculumTag(targetTag);
        if (index < 0 || !meccanioRepairTargets().contains(index)) return;
        applyMeccanioRepair(targetTag, natural: natural, total: total);
      },
    );
  }

  bool applyMeccanioRepair(
    String tag, {
    required int natural,
    required int total,
  }) {
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0 || !meccanioRepairTargets().contains(index)) return false;
    final amount = max(0, total) * (natural == 20 ? 2 : 1);
    if (index == schedaCorrente && isMeccanio) {
      regenerateMeccanio(amount, form: min(3, 1 + activeCriticalLevel() ~/ 3));
      return true;
    }
    final robot = schedePersonaggio[index];
    if (robot['meccanio'] is Map) {
      applySupportToOwnedSheet(index, [
        OculumStructuredEffect(
          type: 'meccanio',
          target: 'repair',
          valueExpression: '$amount',
        ),
      ], 'Meccanica · riparazione di Meccanio');
      programmaSalvataggio();
      return true;
    }
    final maximum = robot['meccanio'] is Map
        ? max(
            1,
            readIntValue((robot['meccanio'] as Map)['maximumHp'], fallback: 20),
          )
        : max(1, readIntValue(robot['derivedMaxHp'], fallback: 20));
    if (readIntValue(robot['currentHp']) >= maximum) {
      final repaired = meccanioRepair(
        hp: maximum,
        hpMaximum: maximum,
        shield: readIntValue(robot['scudo']),
        amount: amount,
        form: min(3, 1 + readIntValue(robot['livello']) ~/ 3),
      );
      applySupportToOwnedSheet(index, [
        OculumStructuredEffect(
          type: 'scudo',
          valueExpression: '${repaired.shieldAdded}',
        ),
      ], 'Meccanica · Scudo di Meccanio');
      programmaSalvataggio();
      return true;
    }
    applySupportToOwnedSheet(index, [
      OculumStructuredEffect(
        type: 'cura',
        resource: 'vita',
        valueExpression: '$amount',
      ),
    ], 'Meccanica · riparazione di ${nomeSchedaPersonaggio(index)}');
    aggiungiLog(
      '[MECCANIO] Meccanica $total${natural == 20 ? ' · critico' : ''}: ripara fino a $amount Vita, entro il massimo.',
    );
    programmaSalvataggio();
    return true;
  }

  bool get hasFateKatana => inventario.any(
    (i) =>
        i.equipaggiata && i.quantita > 0 && i.craftData['posteaKatana'] == true,
  );

  void posteaNewSession() {
    if (hasFateKatana) {
      ispirazioniController.text = '${leggiNumero(ispirazioniController) + 1}';
      aggiungiLog(
        '[POSTEA] Katana del Fato: +1 Ispirazione per la sessione conclusa.',
      );
    }
    for (final item in inventario.where(
      (i) =>
          i.equipaggiata &&
          i.quantita > 0 &&
          i.craftData['posteaGloves'] == true,
    )) {
      final current = item.scudoIntegritaCorrente < 0
          ? itemShieldBonus(item)
          : item.scudoIntegritaCorrente;
      final restored = max(0, itemShieldBonus(item) - current);
      item.scudoIntegritaCorrente = itemShieldBonus(item);
      scudoController.text = '${leggiNumero(scudoController) + restored}';
    }
  }

  Future<void> usePosteaAntiMalus(InventoryItem item) async {
    final origin = currentSheetScrollId();
    final negatives = activeConditions
        .where(
          (c) =>
              oculumConditionDefinition(c.conditionType)?.polarity ==
              OculumConditionPolarity.negative,
        )
        .toList();
    if (negatives.isEmpty) {
      aggiungiLog('[ANTI MALUS] Nessuna condizione negativa da rimuovere.');
      return;
    }
    final selected = await showDialog<String>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: const Text('Anti malus · scegli una condizione'),
        children: [
          for (final c in negatives)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, c.conditionType),
              child: Text(
                oculumConditionDefinition(c.conditionType)?.nameIt ??
                    c.conditionType,
              ),
            ),
        ],
      ),
    );
    if (!mounted ||
        origin != currentSheetScrollId() ||
        selected == null ||
        !inventario.contains(item) ||
        item.quantita <= 0) {
      return;
    }
    final condition = getCondition(selected);
    if (condition == null) return;
    removeCondition(condition, force: true);
    planarState['posteaImmuneCondition'] = selected;
    planarState['posteaImmunityWaitingFight'] = !currentCombatIsActive();
    item.quantita--;
    if (item.quantita == 0) inventario.remove(item);
    aggiungiLog(
      '[ANTI MALUS] $selected rimosso e bloccato fino alla fine ${currentCombatIsActive() ? 'di questo fight' : 'del prossimo fight'}.',
    );
    programmaSalvataggio();
    setState(() {});
  }

  void restorePosteaCores() {
    for (final pawn in pawnGuardians.where(
      (p) => p.ownerTag == pawnSenderTag && p.posteaType == 'core',
    )) {
      pawn.hp = pawn.maxHp;
      updatePawnInitiativeToken(pawn);
    }
    sendPawnSnapshot();
  }

  void healPosteaOwner(OculumPawnGuardian pawn) {
    if (pawn.posteaType != 'healer' || !pawn.alive) return;
    final effect = OculumStructuredEffect(
      type: 'cura',
      duration: '1',
      valueExpression: '${20 + pawn.posteaMedicine}',
      recipient: 'se_stesso',
    );
    final index = localSheetIndexForOculumTag(pawn.ownerTag);
    if (index >= 0 && controlsOnlineCombatSheet(pawn.ownerTag)) {
      applySupportToOwnedSheet(index, [
        effect,
      ], '${pawn.displayName} · turno ${pawn.turn}');
    } else {
      unawaited(
        realtimeService?.sendCombatEvent(
          'combat_help',
          permissionEnvelope({
            'id':
                'postea_heal:${pawn.id}:$onlineCombatEncounterId:${pawn.turn}',
            'kind': 'help',
            'status': 'pending',
            'scope': permissionScope,
            'encounterId': onlineCombatEncounterId,
            'sourceTag': pawnSenderTag,
            'sourceName': pawn.displayName,
            'targetTag': pawn.ownerTag,
            'helpMode': 'effects',
            'effects': [effect.toJson()],
          }),
        ),
      );
    }
    aggiungiLog(
      '[POSTEA] ${pawn.displayName} cura ${20 + pawn.posteaMedicine} Vita al proprietario.',
    );
  }
}
