part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const oculumDustCrystalSizes = ['piccolo', 'medio', 'grande'];

int oculumDustCrystalInfusionUnits(String size) => switch (size) {
  'piccolo' => 1,
  'medio' => 2,
  'grande' => 3,
  _ => 0,
};

int oculumDustCrystalYield(String size, int die) {
  final faces = size == 'grande'
      ? 10
      : size == 'medio'
      ? 6
      : 3;
  return die.clamp(1, faces) + (size == 'piccolo' ? 0 : 2);
}

InventoryItem oculumDustCrystal(String size, {String killId = ''}) {
  final resolved = oculumDustCrystalSizes.contains(size) ? size : 'piccolo';
  final infusionUnits = oculumDustCrystalInfusionUnits(resolved);
  final faces = resolved == 'grande'
      ? 10
      : resolved == 'medio'
      ? 6
      : 3;
  return InventoryItem(
    nome: 'Cristallo di Ascension Dust $resolved',
    peso: resolved == 'grande'
        ? .3
        : resolved == 'medio'
        ? .2
        : .1,
    quantita: 1,
    note:
        'Materiale da crafting e consumabile. Conservalo oppure scegli quando distruggerlo: 1d$faces${resolved == 'piccolo' ? '' : '+2'} Ascension Dust. Nessuna rottura automatica all’acquisto o al drop. Infuso intero nell’equipaggiamento vale $infusionUnits ${infusionUnits == 1 ? 'infusione permanente' : 'infusioni permanenti'} (${3 * infusionUnits} Dust equivalenti).',
    craftData: {
      'dustCrystal': resolved,
      'diceFaces': faces,
      'flatDust': resolved == 'piccolo' ? 0 : 2,
      'material': true,
    },
    monsterLoot: {
      'material': true,
      if (killId.isNotEmpty) 'id': '$killId:dust_crystal',
    },
  );
}

InventoryItem? oculumDustCrystalDrop({
  required int monsterLevel,
  required int monsterGrade,
  required int rollerLevel,
  required int dropTotal,
  required int percentile,
  required String killId,
}) {
  if (monsterLevel < rollerLevel + 3 ||
      dropTotal < 20 + monsterLevel + 2 * monsterGrade) {
    return null;
  }
  final roll = percentile.clamp(0, 99);
  if (roll < 25) return oculumDustCrystal('piccolo', killId: killId);
  if (roll < 40) return oculumDustCrystal('medio', killId: killId);
  if (roll < 46) return oculumDustCrystal('grande', killId: killId);
  return null;
}

List<InventoryItem> oculumCorruptedCriticalCrystals({
  required int monsterPower,
  required int rollerPower,
  required Random random,
  required String killId,
}) {
  final difference = monsterPower - rollerPower;
  final baseCount = 1 + random.nextInt(5);
  final bonusChance = min(25, difference.abs());
  final shift = random.nextInt(100) < bonusChance ? difference.sign : 0;
  final count = (baseCount + shift).clamp(1, 5);
  final largeChance = 30 - 5 * (count - 1);
  return List.generate(count, (index) {
    final roll = random.nextInt(100);
    final size = roll < largeChance
        ? 'grande'
        : roll < largeChance + 40
        ? 'medio'
        : 'piccolo';
    return oculumDustCrystal(size, killId: '$killId:corrupted:$index');
  });
}

List<Map<String, dynamic>> oculumBoardAfterFight(Iterable<Map> tokens) => [
  for (final token in tokens)
    if (token['side'] != 'enemy' &&
        token['temporaryTurn'] != true &&
        token['status'] != 'expired' &&
        (token['status'] != 'fled' || token['outsideFight'] == true))
      {
        ...Map<String, dynamic>.from(token),
        'actionUsed': false,
        'reportedTurn': 0,
      },
];

enum OculumDustInfusionMode {
  offense,
  defense,
  both;

  bool get attacks => this != defense;
  bool get defends => this != offense;

  int shieldAt(int level) => switch (this) {
    offense => 0,
    defense => level <= 0 ? 6 : 10 + 30 * (level ~/ 3),
    both => level <= 0 ? 3 : 6 + 30 * (level ~/ 3),
  };
}

const _dustInfusionKey = 'dustInfusion';

bool oculumCanInfuseEquipment(InventoryItem item) =>
    item.arma || item.protegge || item.craftData['titleItem'] == true;

Map _dustInfusionData(InventoryItem item) {
  final data = item.craftData[_dustInfusionKey];
  return data is Map ? data : const {};
}

({OculumDustInfusionMode? mode, int doses}) oculumPendingDustInfusion(
  InventoryItem item,
) {
  final data = _dustInfusionData(item);
  final doses = readIntValue(data['doses']).clamp(0, 2);
  final mode = OculumDustInfusionMode.values
      .where((candidate) => candidate.name == data['pending'])
      .firstOrNull;
  return mode == null || doses == 0
      ? (mode: null, doses: 0)
      : (mode: mode, doses: doses);
}

({int attack, int defense, int shield}) oculumDustInfusionBonuses(
  InventoryItem item,
) {
  if (item.quantita <= 0 ||
      !oculumCanInfuseEquipment(item) ||
      !item.craftData.containsKey(_dustInfusionKey)) {
    return (attack: 0, defense: 0, shield: 0);
  }
  final data = _dustInfusionData(item);
  final pending = oculumPendingDustInfusion(item);
  var attack = 0;
  var defense = 0;
  var shield = 0;
  for (final mode in OculumDustInfusionMode.values) {
    final count =
        max(0, readIntValue(data[mode.name])) +
        (pending.mode == mode ? pending.doses : 0);
    if (mode.attacks) attack += count;
    if (mode.defends) defense += count;
    shield += count * mode.shieldAt(item.livelloOggetto);
  }
  return (attack: attack, defense: defense, shield: shield);
}

bool oculumApplyDustInfusion(
  InventoryItem item,
  OculumDustInfusionMode mode, {
  required bool crystal,
  String crystalSize = 'piccolo',
}) {
  if (!oculumCanInfuseEquipment(item) || item.quantita <= 0) return false;
  final units = crystal ? oculumDustCrystalInfusionUnits(crystalSize) : 1;
  if (units == 0) return false;
  final pending = oculumPendingDustInfusion(item);
  if (!crystal && pending.mode != null && pending.mode != mode) return false;
  final data = Map<String, dynamic>.from(_dustInfusionData(item));
  if (crystal || pending.doses == 2) {
    data[mode.name] = max(0, readIntValue(data[mode.name])) + units;
    if (!crystal) {
      data.remove('pending');
      data.remove('doses');
    }
  } else {
    data['pending'] = mode.name;
    data['doses'] = pending.doses + 1;
  }
  item.craftData = {...item.craftData, _dustInfusionKey: data};
  return true;
}

bool oculumExpireDustInfusion(InventoryItem item) {
  final data = _dustInfusionData(item);
  if (!data.containsKey('doses') && !data.containsKey('pending')) return false;
  final remaining = Map<String, dynamic>.from(data)
    ..remove('pending')
    ..remove('doses');
  item.craftData = {...item.craftData};
  if (remaining.isEmpty) {
    item.craftData.remove(_dustInfusionKey);
  } else {
    item.craftData[_dustInfusionKey] = remaining;
  }
  return true;
}

extension _OculumEquipmentInfusion on _OculumHomePageState {
  int dustInfusionRollBonus({
    required bool usesOculum,
    required bool attack,
    required bool defense,
  }) {
    if (!usesOculum || (!attack && !defense)) return 0;
    return inventario.fold(0, (total, item) {
      if (!item.equipaggiata ||
          item.quantita <= 0 ||
          !item.craftData.containsKey(_dustInfusionKey) ||
          !canEquipInventoryItem(item)) {
        return total;
      }
      final bonus = oculumDustInfusionBonuses(item);
      return total + (attack ? bonus.attack : bonus.defense);
    });
  }

  void changeInventoryOculumShieldCapacity(
    InventoryItem item,
    void Function() update, {
    bool chargeNewCapacity = true,
  }) {
    final before = itemOculumShieldBonus(item);
    if (item.equipaggiata && oculumDustInfusionBonuses(item).shield > 0) {
      reconcileTrackedOculumShield();
    }
    final current = itemIntegrityOculumShieldCurrent(item);
    update();
    final after = itemOculumShieldBonus(item);
    if (before == after) return;
    // Add only new capacity, preserving already spent points on this item.
    final delta = after - before;
    final remaining = (current + (chargeNewCapacity ? delta : min(0, delta)))
        .clamp(0, after)
        .toInt();
    item.scudoIntegritaOculumCorrente = remaining;
    if (item.equipaggiata && canEquipInventoryItem(item)) {
      scudoOculumController.text =
          '${max(0, leggiNumero(scudoOculumController) + remaining - current)}';
    }
  }

  String dustInfusionModeLabel(OculumDustInfusionMode mode) => switch (mode) {
    OculumDustInfusionMode.offense => t('Offensiva', 'Offensive'),
    OculumDustInfusionMode.defense => t('Difensiva', 'Defensive'),
    OculumDustInfusionMode.both => t('Entrambe', 'Both'),
  };

  void expireInventoryDustInfusions() {
    for (final item in inventario) {
      if (!item.craftData.containsKey(_dustInfusionKey)) continue;
      changeInventoryOculumShieldCapacity(
        item,
        () => oculumExpireDustInfusion(item),
      );
    }
  }

  void editInfusedInventoryRole(InventoryItem item, void Function() update) {
    if (!item.equipaggiata || oculumDustInfusionBonuses(item).shield == 0) {
      update();
      return;
    }
    applicaScudoItemAttuale(item, -1);
    item.equipaggiata = false;
    changeInventoryOculumShieldCapacity(item, update, chargeNewCapacity: false);
    if (oculumCanInfuseEquipment(item) || item.buff.trim().isNotEmpty) {
      applicaScudoItemAttuale(item, 1);
      item.equipaggiata = true;
    }
  }

  Widget inventoryDustInfusionButton(InventoryItem item) {
    final bonus = oculumDustInfusionBonuses(item);
    final doses = oculumPendingDustInfusion(item).doses;
    final description = [
      if (bonus.attack > 0)
        t('Attacco +${bonus.attack}', 'Attack +${bonus.attack}'),
      if (bonus.defense > 0)
        t('Difesa +${bonus.defense}', 'Defense +${bonus.defense}'),
      if (doses > 0) t('Dust $doses/3', 'Dust $doses/3'),
    ].join(' · ');
    return OutlinedButton.icon(
      onPressed: () => showInventoryDustInfusion(item),
      icon: const Icon(Icons.diamond_outlined),
      label: Text(
        description.isEmpty
            ? t('Infondi Ascension Dust', 'Infuse Ascension Dust')
            : t('Infondi · $description', 'Infuse · $description'),
      ),
    );
  }

  Future<void> showInventoryDustInfusion(InventoryItem item) async {
    if (!oculumCanInfuseEquipment(item) || item.quantita <= 0) return;
    final origin = currentSheetScrollId();
    final pure = max(0, leggiNumero(ascensionDustController));
    final available = {
      if (pure > 0) 'dust': pure,
      for (final size in oculumDustCrystalSizes)
        size: inventario.fold(
          0,
          (total, crystal) => crystal.craftData['dustCrystal'] == size
              ? total + max(0, crystal.quantita)
              : total,
        ),
    }..removeWhere((key, count) => count == 0);
    if (available.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(t('Infondi Ascension Dust', 'Infuse Ascension Dust')),
          content: Text(
            t(
              'Serve una dose di Dust pura o un cristallo di Ascension Dust.',
              'Requires one dose of pure Dust or one Ascension Dust crystal.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(t('Chiudi', 'Close')),
            ),
          ],
        ),
      );
      return;
    }
    final pending = oculumPendingDustInfusion(item);
    var material = available.keys.first;
    var mode = pending.mode ?? OculumDustInfusionMode.offense;
    var submitted = false;
    final choice = await showDialog<(String, OculumDustInfusionMode)>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, refresh) {
          final temporary = material == 'dust';
          final units = temporary
              ? 1
              : oculumDustCrystalInfusionUnits(material);
          final allowed = temporary && pending.mode != null
              ? [pending.mode!]
              : OculumDustInfusionMode.values;
          final shield = units * mode.shieldAt(item.livelloOggetto);
          return AlertDialog(
            title: Text(t('Infondi ${item.nome}', 'Infuse ${item.nome}')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButton<String>(
                  isExpanded: true,
                  value: material,
                  items: [
                    for (final entry in available.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          '${entry.key == 'dust' ? t('Dust pura', 'Pure Dust') : t('Cristallo ${entry.key}', 'Crystal ${entry.key}')} (${entry.value})',
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    refresh(() {
                      material = value;
                      if (value == 'dust' && pending.mode != null) {
                        mode = pending.mode!;
                      }
                    });
                  },
                ),
                DropdownButton<OculumDustInfusionMode>(
                  isExpanded: true,
                  value: mode,
                  items: [
                    for (final candidate in allowed)
                      DropdownMenuItem(
                        value: candidate,
                        child: Text(dustInfusionModeLabel(candidate)),
                      ),
                  ],
                  onChanged: allowed.length == 1
                      ? null
                      : (value) {
                          if (value != null) refresh(() => mode = value);
                        },
                ),
                Text(
                  [
                    if (mode.attacks)
                      t('+$units Attacco Oculum', '+$units Oculum attack'),
                    if (mode.defends)
                      t('+$units Difesa Oculum', '+$units Oculum defense'),
                    if (shield > 0)
                      t('Scudo Oculum $shield', 'Oculum Shield $shield'),
                  ].join(' · '),
                ),
                const SizedBox(height: 8),
                Text(
                  temporary
                      ? pending.doses == 2
                            ? t(
                                'Terza dose: converte le dosi in una sola infusione permanente.',
                                'Third dose: converts the doses into one permanent infusion.',
                              )
                            : t(
                                'Fino al Riposo Lungo · ${pending.doses + 1}/3 dosi della stessa modalità.',
                                'Until Long Rest · ${pending.doses + 1}/3 doses of the same mode.',
                              )
                      : units == 1
                      ? t(
                          'Consuma un cristallo. Un’infusione permanente, equivalente a 3 Dust.',
                          'Consumes one crystal. One permanent infusion, equivalent to 3 Dust.',
                        )
                      : t(
                          'Consuma un cristallo. $units infusioni permanenti, equivalenti a ${3 * units} Dust.',
                          'Consumes one crystal. $units permanent infusions, equivalent to ${3 * units} Dust.',
                        ),
                ),
              ],
            ),
            scrollable: true,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: Text(t('Annulla', 'Cancel')),
              ),
              FilledButton(
                onPressed: () {
                  if (submitted) return;
                  submitted = true;
                  Navigator.pop(dialog, (material, mode));
                },
                child: Text(t('Infondi', 'Infuse')),
              ),
            ],
          );
        },
      ),
    );
    if (!mounted ||
        choice == null ||
        origin != currentSheetScrollId() ||
        !inventario.contains(item) ||
        item.quantita <= 0 ||
        !oculumCanInfuseEquipment(item)) {
      return;
    }
    final (source, selectedMode) = choice;
    final useCrystal = source != 'dust';
    final units = useCrystal ? oculumDustCrystalInfusionUnits(source) : 1;
    if (units == 0) return;
    final crystal = useCrystal
        ? inventario
              .where(
                (candidate) =>
                    candidate.quantita > 0 &&
                    candidate.craftData['dustCrystal'] == source,
              )
              .firstOrNull
        : null;
    final dustAvailable = leggiNumero(ascensionDustController);
    final currentPending = oculumPendingDustInfusion(item).mode;
    if (useCrystal
        ? crystal == null
        : dustAvailable <= 0 ||
              (currentPending != null && currentPending != selectedMode)) {
      return;
    }
    setState(() {
      if (item.quantita > 1 && !item.craftData.containsKey(_dustInfusionKey)) {
        final remainder = InventoryItem.fromJson({
          ...item.toJson(),
          'quantita': item.quantita - 1,
          'equipaggiata': false,
        });
        item.quantita = 1;
        inventario.insert(inventario.indexOf(item) + 1, remainder);
      }
      changeInventoryOculumShieldCapacity(
        item,
        () => oculumApplyDustInfusion(
          item,
          selectedMode,
          crystal: useCrystal,
          crystalSize: source,
        ),
      );
      if (crystal != null) {
        if (--crystal.quantita == 0) inventario.remove(crystal);
      } else {
        ascensionDustController.text = '${dustAvailable - 1}';
      }
      final scope = useCrystal || oculumPendingDustInfusion(item).doses == 0
          ? units == 1
                ? t('permanente', 'permanent')
                : t('$units infusioni permanenti', '$units permanent infusions')
          : t('fino al Riposo Lungo', 'until Long Rest');
      aggiungiLog(
        '${t('Infusione', 'Infusion')} · ${item.nome} · ${dustInfusionModeLabel(selectedMode)} · $scope.',
      );
    });
    programmaSalvataggio();
  }
}

extension _OculumDustCrystals on _OculumHomePageState {
  void ensureDustCrystalOffers() {
    for (final (i, size) in oculumDustCrystalSizes.indexed) {
      final id = 'ascension_dust_crystal_$size';
      if (merchantStock.any((o) => o['id'] == id)) continue;
      final bounds = const [(40, 60), (90, 120), (150, 200)][i];
      final item = oculumDustCrystal(size);
      merchantStock.add({
        'id': id,
        'kind': 'dust_crystal',
        'size': size,
        'name': item.nome,
        'desc': item.note,
        'cost': bounds.$1 + Random.secure().nextInt(bounds.$2 - bounds.$1 + 1),
        'isMaterial': true,
      });
    }
  }

  Future<void> breakDustCrystal(InventoryItem item) async {
    final origin = currentSheetScrollId();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('Distruggi ${item.nome}?'),
        content: Text(
          '${item.note} Se lo usi nel crafting non lo puoi anche rompere.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Conserva'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Distruggi un cristallo'),
          ),
        ],
      ),
    );
    if (!mounted ||
        accepted != true ||
        origin != currentSheetScrollId() ||
        !inventario.contains(item) ||
        item.quantita <= 0) {
      return;
    }
    final faces = max(
      1,
      readIntValue(item.craftData['diceFaces'], fallback: 3),
    );
    final die = Random.secure().nextInt(faces) + 1;
    final bonus = max(0, readIntValue(item.craftData['flatDust']));
    final dust = die + bonus;
    setState(() {
      item.quantita--;
      if (item.quantita == 0) inventario.remove(item);
      ascensionDustController.text =
          '${leggiNumero(ascensionDustController) + dust}';
      aggiungiLog(
        '[CRISTALLO DUST] ${item.nome}: 1d$faces ($die) + $bonus = $dust Ascension Dust.',
      );
    });
    programmaSalvataggio();
  }
}

extension _OculumDustFusion on _OculumHomePageState {
  Map get dustFusion => planarState['dustFusion'] as Map? ?? {};
  int get dustFusionTier => readIntValue(dustFusion['rests']) > 0
      ? readIntValue(dustFusion['tier']).clamp(0, 3)
      : 0;
  List<Widget> dustFusionButtons() => [
    for (final (index, size) in oculumDustCrystalSizes.indexed)
      if (inventario.any(
        (item) => item.quantita > 0 && item.craftData['dustCrystal'] == size,
      ))
        OutlinedButton.icon(
          onPressed: () => fuseDustCrystal(size, index + 1),
          icon: const Icon(Icons.diamond_outlined),
          label: Text(
            'Fonditi con cristallo di Ascension Dust (${const ['I', 'II', 'III'][index]})',
          ),
        ),
  ];
  Future<void> fuseDustCrystal(String size, int tier) async {
    final origin = currentSheetScrollId();
    final item = inventario
        .where((i) => i.quantita > 0 && i.craftData['dustCrystal'] == size)
        .firstOrNull;
    if (item == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('Fusione $size'),
        content: Text(
          'Consuma un cristallo: +$tier a tutte le statistiche e +${tier * 10}% agli effetti positivi delle Art e Skill; +${tier * 5}% Danni e Difesa personali. Sostituisce la fusione attiva. In fight richiede una Azione.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Fonditi'),
          ),
        ],
      ),
    );
    if (!mounted ||
        confirmed != true ||
        origin != currentSheetScrollId() ||
        !inventario.contains(item) ||
        item.quantita <= 0) {
      return;
    }
    if (currentTurnTrackerIsActive() && !await requestUtilitySpend('azione')) {
      return;
    }
    if (!mounted || origin != currentSheetScrollId()) return;
    final die =
        Random.secure().nextInt(
          tier == 1
              ? 3
              : tier == 2
              ? 6
              : 10,
        ) +
        1;
    final rests =
        die +
        (tier == 1
            ? 0
            : tier == 2
            ? 1
            : 2);
    setState(() {
      item.quantita--;
      if (item.quantita == 0) inventario.remove(item);
      planarState['dustFusion'] = {'tier': tier, 'rests': rests};
      invalidateDerivedDataCaches();
    });
    aggiungiLog(
      '[FUSIONE DUST] +$tier statistiche · +${tier * 10}% effetti positivi Art · $rests Riposi Lunghi.',
    );
    programmaSalvataggio();
  }

  List<OculumStructuredEffect> dustFusionArtEffects(
    Iterable<OculumStructuredEffect> effects,
  ) => [
    for (final effect in effects)
      if (dustFusionTier > 0 &&
          const {
            'danno',
            'difesa',
            'difesa_percentuale',
            'danno_percentuale',
            'modifica_sottotratto',
            'forza',
            'velocita',
            'cura',
            'modifica_statistica',
            'sottotratto',
            'tiro',
          }.contains(effect.type) &&
          effect.valueExpression.isNotEmpty &&
          !effect.valueExpression.trimLeft().startsWith('-'))
        OculumStructuredEffect.fromJson(effect.toJson())
          ..valueExpression =
              'ceil((${effect.valueExpression})*${1 + dustFusionTier / 10})'
      else
        effect,
  ];
  void restDustFusion() {
    if (dustFusionTier <= 0) return;
    final remaining = readIntValue(dustFusion['rests']) - 1;
    if (remaining <= 0) {
      planarState.remove('dustFusion');
      aggiungiLog('[FUSIONE DUST] Effetto terminato.');
    } else {
      planarState['dustFusion'] = {...dustFusion, 'rests': remaining};
    }
    invalidateDerivedDataCaches();
  }
}
