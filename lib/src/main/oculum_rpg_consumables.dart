part of '../../main.dart';

/// Initial balancing values, editable on the merchant offer and saved item.
/// Asher's values and the leaf's local healing are explicit user rules.
const oculumRpgConsumables = <Map<String, dynamic>>[
  {
    'id': 'leaf_greenheart',
    'name': 'Foglia di Cuorverde',
    'rarity': 'non_comune',
    'minimumPrice': 90,
    'maximumPrice': 129,
    'desc':
        'Foglia viola dal centro verde. Applicata a una parte ferita si '
        'secca: ripristina tutta la Vita separata di quella parte e ne cura '
        'ferite e fratture. Senza Vita separata della parte: cura un quarto '
        'della Vita massima per eccesso più il livello del bersaglio. '
        'Non ricrea parti mancanti.',
    'effects': {
      'healPart': true,
      'bodyHealWithoutPartHpPercent': 25,
      'bodyHealWithoutPartHpPerLevel': 1,
    },
  },
  {
    'id': 'leaf_vital',
    'name': 'Foglia di Linfa Viva',
    'minimumPrice': 25,
    'maximumPrice': 39,
    'desc': 'Si secca sulla pelle e recupera il 25% della Vita massima.',
    'effects': {'healHpPercent': 25},
  },
  {
    'id': 'leaf_greater_vital',
    'name': 'Foglia di Linfa Antica',
    'minimumPrice': 65,
    'maximumPrice': 89,
    'desc': 'Recupera il 50% della Vita massima. La foglia diventa cenere.',
    'effects': {'healHpPercent': 50},
  },
  {
    'id': 'leaf_antidote',
    'name': 'Foglia di Neroluce',
    'minimumPrice': 20,
    'maximumPrice': 34,
    'desc': 'Assorbe il veleno e si annerisce: rimuove Avvelenato curabile.',
    'effects': {
      'removeConditions': ['avvelenato'],
    },
  },
  {
    'id': 'crystal_clot',
    'name': 'Cristallo Ematico',
    'minimumPrice': 20,
    'maximumPrice': 34,
    'desc': 'Si dissolve sulla ferita: arresta Sanguinamento curabile.',
    'effects': {
      'removeConditions': ['sanguinamento'],
    },
  },
  {
    'id': 'crystal_cool',
    'name': 'Cristallo di Brina Dolce',
    'minimumPrice': 20,
    'maximumPrice': 34,
    'desc': 'Si scioglie sulla pelle: rimuove Bruciatura curabile.',
    'effects': {
      'removeConditions': ['bruciatura'],
    },
  },
  {
    'id': 'crystal_restore',
    'name': 'Cristallo delle Quattro Vene',
    'minimumPrice': 140,
    'maximumPrice': 189,
    'desc':
        'Si frantuma e ripristina le statistiche attuali ai massimi naturali. '
        'Non concede Oculum a chi non lo possiede.',
    'effects': {'restoreAllStats': true},
  },
  {
    'id': 'wing_asher_fragment',
    'name': 'Frammento di Ala di Asher',
    'minimumPrice': 300,
    'maximumPrice': 369,
    'desc':
        'Frammento di ala di Eiva consumabile. Fino al Riposo Lungo: '
        '+9 Volontà e +6 Resilienza, Materia e Oculum. Senza Oculum, quei '
        '6 punti diventano +6 Volontà e +2 Materia aggiuntivi. Non si cumula '
        'con un altro frammento di Asher; il bonus viene rinnovato.',
    'effects': {
      'stats': {'resilienza': 6, 'volonta': 9, 'materia': 6, 'oculum': 6},
      'redirectMissingOculum': true,
      'untilLongRest': true,
    },
  },
  {
    'id': 'wing_eiva_vital',
    'name': 'Ala di Eiva Vitale',
    'minimumPrice': 600,
    'maximumPrice': 799,
    'desc':
        'Si consuma in una fiammata verde: ripristina tutta la Vita del '
        'corpo e le statistiche attuali. Non resuscita né ricrea arti.',
    'effects': {'healHpPercent': 100, 'restoreAllStats': true},
  },
];

Map<String, int> oculumRpgConsumableStatBonuses(
  Map effects, {
  required bool hasOculum,
}) {
  final raw = effects['stats'];
  final stats = <String, int>{
    for (final key in const ['resilienza', 'volonta', 'materia', 'oculum'])
      key: raw is Map ? max(0, readIntValue(raw[key])) : 0,
  };
  if (!hasOculum) {
    final unused = stats['oculum']!;
    stats['oculum'] = 0;
    if (effects['redirectMissingOculum'] == true) {
      stats['volonta'] = stats['volonta']! + unused;
      stats['materia'] = stats['materia']! + unused ~/ 3;
    }
  }
  return stats;
}

InventoryItem oculumRpgConsumableFromOffer(Map<String, dynamic> offer) =>
    InventoryItem(
      nome: '${offer['name']}',
      peso: .1,
      quantita: 1,
      note:
          '${offer['rarity'] == 'non_comune' ? 'Non comune · ' : ''}'
          '${offer['desc']} In Fight: 1 Azione oppure 1 Reazione. '
          'Fuori Fight: nessun costo di azione. Si consuma all’uso.',
      craftData: {
        if (offer['rarity'] != null) 'rarity': offer['rarity'],
        'rpgConsumable': jsonDecode(
          jsonEncode({
            'id': offer['id'],
            'effects': offer['effects'],
            'combatSpend': 'action_or_reaction',
          }),
        ),
      },
    );

final _rpgConsumableBusy = Expando<bool>();

extension _OculumRpgConsumables on _OculumHomePageState {
  void ensureRpgConsumableOffers() {
    final random = Random();
    for (final definition in oculumRpgConsumables) {
      final existing = merchantStock.where(
        (offer) => offer['id'] == definition['id'],
      );
      if (existing.isNotEmpty) {
        if (definition['rarity'] != null) {
          existing.first.putIfAbsent('rarity', () => definition['rarity']);
        }
        continue;
      }
      final minimum = readIntValue(definition['minimumPrice']);
      final maximum = readIntValue(definition['maximumPrice']);
      merchantStock.add({
        ...Map<String, dynamic>.from(jsonDecode(jsonEncode(definition)) as Map),
        'kind': 'rpg_consumable',
        'cost': minimum + random.nextInt(maximum - minimum + 1),
        'remaining':
            definition['id'] == 'wing_asher_fragment' ||
                definition['id'] == 'wing_eiva_vital'
            ? 1
            : 3,
      });
    }
  }

  bool _rpgPartMissing(Map part) =>
      part['missing'] == true ||
      part['severed'] == true ||
      part['detached'] == true;

  List<int> _rpgLivingContactPatients() => [
    for (var index = 0; index < schedePersonaggio.length; index++)
      if (controlsOnlineCombatSheet(
            normalizeOculumFriendTag(sheetTagAt(index)),
          ) &&
          (index == schedaCorrente
                  ? hpCorrenti()
                  : sheetIntValueAt(index, 'currentHp')) >
              0 &&
          (!currentCombatIsActive() ||
              index == schedaCorrente ||
              onlineCombatTokens().any(
                (token) => combatTokenMatchesSheet(token, sheetTagAt(index)),
              )))
        index,
  ];

  Map<String, Map> _rpgPartsForPatient(int index) {
    final sheet = schedePersonaggio[index];
    final saved = sheet['precisionBodyParts'];
    final runtime = sheet['planarRuntime'];
    final anatomy = runtime is Map ? runtime['anatomicalParts'] : null;
    final state = index == schedaCorrente
        ? anatomicalPartState['parts']
        : anatomy is Map
        ? anatomy['parts']
        : null;
    final parts = index == schedaCorrente
        ? currentPrecisionBodyParts
        : saved is List
        ? saved.whereType<Map>().toList()
        : oculumPrecisionBodyParts(
            monster: monsterBookEntryById(
              '${sheet['monsterBookSourceId'] ?? ''}',
            ),
            description: '${sheet['background'] ?? ''}',
          );
    return {
      for (final part in parts) '${part['id']}': part,
      if (state is Map)
        for (final entry in state.entries)
          if (entry.value is Map) '${entry.key}': entry.value as Map,
    };
  }

  void _healRpgConsumablePart(
    String id, {
    int bodyHealPercent = 0,
    int bodyHealPerLevel = 0,
  }) {
    final parts = anatomicalPartState['parts'];
    final part = parts is Map ? parts[id] : null;
    final separateHp =
        part is Map && readIntValue(part['maximumHp']) > 0 ||
        monsterBookEntryById(faunaCurrentMonsterId) != null;
    planarState['anatomicalParts'] = oculumRepairAnatomicalPart(
      state: anatomicalPartState,
      partId: id,
      method: 'appropriate_treatment',
      receiptId: 'greenheart:${DateTime.now().microsecondsSinceEpoch}:$id',
    );
    final fracture = getCondition('frattura');
    if (fracture != null) {
      final limbs = (fracture.metadata['limbs'] as List? ?? [])
          .whereType<Map>()
          .where((part) => part['id'] != id)
          .toList();
      if (limbs.isEmpty) {
        removeCondition(fracture, force: true, repairFracturedParts: false);
      } else {
        fracture.metadata['limbs'] = limbs;
        fracture.stacks = limbs.length;
        notifyConditionsChanged(conditionTargetsFor(fracture));
      }
    }
    planarState['damagedWings'] = damagedWingIds
        .where((wing) => wing != id)
        .toList();
    if (!separateHp && hpCorrenti() > 0) {
      final amount =
          ((maxHp() * bodyHealPercent.clamp(0, 100) / 100).ceil() +
                  max(0, readIntValue(livelloController.text)) *
                      max(0, bodyHealPerLevel))
              .toInt();
      writeHealedLife(
        min(maxHp(), hpCorrenti() + applyConditionHealingAmount(amount)),
      );
    }
    publishReferenceCreatureAnatomyState();
  }

  Future<void> useRpgConsumable(InventoryItem item) async {
    if (_rpgConsumableBusy[this] == true ||
        !inventario.contains(item) ||
        item.quantita <= 0 ||
        hpCorrenti() <= 0) {
      return;
    }
    final tag = sheetTagAt(schedaCorrente), scope = permissionScope;
    if (!controlsOnlineCombatSheet(normalizeOculumFriendTag(tag))) return;
    final raw = item.craftData['rpgConsumable'];
    if (raw is! Map || raw['effects'] is! Map) return;
    final effects = Map<String, dynamic>.from(raw['effects'] as Map);
    final inFight = currentCombatIsActive();
    final encounter = onlineCombatEncounterId;
    if (inFight && !currentTurnTrackerIsActive()) {
      aggiungiLog(
        'Consumo rinviato: nessuna turnistica attiva per pagare Azione o Reazione.',
      );
      return;
    }
    _rpgConsumableBusy[this] = true;
    try {
      String? partId;
      var patientTag = tag;
      if (effects['healPart'] == true) {
        final patients = _rpgLivingContactPatients();
        if (patients.length > 1) {
          final selected = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Creatura viva a contatto'),
              content: SizedBox(
                width: 420,
                height: 320,
                child: ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (_, position) {
                    final index = patients[position];
                    return ListTile(
                      title: Text(nomeSchedaPersonaggio(index)),
                      subtitle: Text(
                        index == schedaCorrente
                            ? 'Tu'
                            : 'Applica la foglia alla creatura a contatto',
                      ),
                      onTap: () => Navigator.pop(context, sheetTagAt(index)),
                    );
                  },
                ),
              ),
            ),
          );
          if (selected == null) return;
          patientTag = selected;
        }
        final patientIndex = localSheetIndexForOculumTag(patientTag);
        if (patientIndex < 0) return;
        final parts = _rpgPartsForPatient(patientIndex);
        if (!mounted) return;
        partId = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text('Applica ${item.nome}'),
            children: [
              for (final entry in parts.entries)
                if (!_rpgPartMissing(entry.value))
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, entry.key),
                    child: Text('${entry.value['label'] ?? entry.key}'),
                  ),
            ],
          ),
        );
        if (partId == null) return;
      }
      String? spend;
      if (!mounted) return;
      if (currentCombatIsActive()) {
        spend = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Usa il consumabile'),
            children: [
              for (final entry in const {
                'azione': '1 Azione',
                'reazione': '1 Reazione',
              }.entries)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, entry.key),
                  child: Text(entry.value),
                ),
            ],
          ),
        );
        if (spend == null) return;
      }
      bool valid() =>
          mounted &&
          tag == sheetTagAt(schedaCorrente) &&
          scope == permissionScope &&
          inFight == currentCombatIsActive() &&
          encounter == onlineCombatEncounterId &&
          controlsOnlineCombatSheet(normalizeOculumFriendTag(tag)) &&
          inventario.contains(item) &&
          item.quantita > 0 &&
          hpCorrenti() > 0;
      bool validPatient() {
        if (partId == null) return true;
        final patientIndex = localSheetIndexForOculumTag(patientTag);
        if (patientIndex < 0 ||
            !_rpgLivingContactPatients().contains(patientIndex)) {
          return false;
        }
        final part = _rpgPartsForPatient(patientIndex)[partId];
        return part != null && !_rpgPartMissing(part);
      }

      if (!valid()) return;
      if (!validPatient()) return;
      if (spend != null &&
          !await requestUtilitySpend(
            spend,
            preferFreeReaction: false,
            grantFastRollBonus: false,
            deferMasterTurn: true,
          )) {
        return;
      }
      if (!valid() || !validPatient()) return;
      if (partId != null) {
        final patientIndex = localSheetIndexForOculumTag(patientTag);
        if (patientIndex < 0) return;
        // Pay and save the actor before the existing scoped-sheet helper loads
        // the patient; reloading recreates inventory item instances.
        if (--item.quantita == 0) inventario.remove(item);
        salvaSchedaCorrenteInMemoria();
        faunaForOwnedSheet(patientTag, () {
          _healRpgConsumablePart(
            partId!,
            bodyHealPercent: readIntValue(
              effects['bodyHealWithoutPartHpPercent'],
              fallback: 25,
            ),
            bodyHealPerLevel: readIntValue(
              effects['bodyHealWithoutPartHpPerLevel'],
              fallback: 1,
            ),
          );
          salvaSchedaCorrenteInMemoria();
          syncCurrentSheetDeathStateToInitiative();
        });
        aggiungiLog(
          '${item.nome} consumata su ${nomeSchedaPersonaggio(patientIndex)} · $partId.',
        );
        invalidateDerivedDataCaches();
        salvaSchedaCorrenteInMemoria();
        programmaSalvataggio();
        refreshOculumHome(() {});
        if (spend == 'azione') advanceMasterInitiativeAfterAction(tag);
        await sendRealtimeSheetToStaffAt(patientIndex);
        return;
      }
      if (effects['restoreAllStats'] == true) refullaStatsAttuali();
      final healPercent = readIntValue(effects['healHpPercent']).clamp(0, 100);
      if (healPercent > 0) {
        writeHealedLife(
          min(
            maxHp(),
            hpCorrenti() +
                applyConditionHealingAmount(
                  (maxHp() * healPercent / 100).ceil(),
                ),
          ),
        );
      }
      final remove = effects['removeConditions'];
      if (remove is List) {
        for (final condition in activeConditions.toList()) {
          if (remove.contains(condition.conditionType)) {
            removeCondition(condition);
          }
        }
      }
      final bonuses = oculumRpgConsumableStatBonuses(
        effects,
        hasOculum: !isMeccanio && !isThunderBot && oculumMassimoNaturale() > 0,
      );
      for (final entry in bonuses.entries) {
        if (entry.value == 0) continue;
        final source = 'rpg_consumable:${raw['id']}:${entry.key}';
        // Renewal replaces this item's prior buff; different effects remain.
        merchantHerbalEffects.removeWhere(
          (effect) => effect['source'] == source,
        );
        merchantHerbalEffects.add({
          'type': 'stat_bonus',
          'statId': entry.key,
          'value': entry.value,
          'source': source,
          'shortRestsRemaining': 2,
          'mealBuff': true,
        });
      }
      if (--item.quantita == 0) inventario.remove(item);
      invalidateDerivedDataCaches();
      aggiungiLog(
        '${item.nome} consumato${partId == null ? '' : ' sulla parte $partId'}.',
      );
      salvaSchedaCorrenteInMemoria();
      programmaSalvataggio();
      refreshOculumHome(() {});
      if (spend == 'azione') advanceMasterInitiativeAfterAction(tag);
    } finally {
      _rpgConsumableBusy[this] = false;
    }
  }
}
