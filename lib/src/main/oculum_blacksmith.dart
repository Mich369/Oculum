part of '../../main.dart';

// Definitions and material powers are carried by the item, not regenerated on load.
int oculumBlacksmithDustCost(InventoryItem item) => min(
  12,
  max(
        readIntValue(item.craftData['blacksmithForgeCount']),
        readIntValue(item.craftData['titleReforgeCount']),
      ) +
      1,
).clamp(1, 12).toInt();
int oculumEquipmentSkillItemLevel(
  InventoryItem item,
  CharacterSkillForm form,
) => max(
  0,
  readIntValue(
    form.unlockRequirements['equipmentItemLevel'],
    fallback: item.livelloOggetto,
  ),
);
List<CharacterSkill> oculumAllEquipmentAbilities(InventoryItem item) => [
  if (item.ability != null) item.ability!,
  ...item.materialAbilities,
  ...oculumItemTitleAbilities(item),
];

OculumAuthoredMaterial? oculumBlacksmithMaterial(InventoryItem item) =>
    [...oculumAuthoredMaterials, ...oculumAdditionalCraftingMaterials]
        .where(
          (m) =>
              m.id == item.craftData['material'] ||
              oculumNormalizeText(m.name) == oculumNormalizeText(item.nome),
        )
        .firstOrNull;
int oculumBlacksmithMaterialLevel(InventoryItem item) => max(
  0,
  readIntValue(item.craftData['materialLevel'], fallback: item.livelloOggetto),
);
int oculumBlacksmithMaterialStrength(InventoryItem item) => max(
  1,
  readIntValue(
    item.craftData['materialStrength'],
    fallback:
        (max(0, readIntValue(item.craftData['materialGrade'], fallback: max(item.gradoOggetto, oculumBlacksmithMaterial(item)?.grade ?? 0))) +
                1) *
            3 +
        oculumBlacksmithMaterialLevel(item) ~/ 3,
  ),
);
int oculumBlacksmithMinimumGrams(
  InventoryItem target,
  InventoryItem material,
) => max(
  25,
  readIntValue(
    material.craftData['inlayMinimumGrams'],
    fallback: (max(.1, target.peso.isFinite ? target.peso : .1) * 1000 * .05)
        .ceil(),
  ),
);

/// New catalogue defaults: 60% at levels 0..6; successive bands shrink.
/// Existing JSON levels and explicit materialLevel edits are never replaced.
Map<String, int> oculumDefaultMaterialLevels() {
  final byId = <String, OculumAuthoredMaterial>{
    for (final m in [
      ...oculumAuthoredMaterials,
      ...oculumAdditionalCraftingMaterials,
    ])
      m.id: m,
  };
  final ordered = byId.values.toList()
    ..sort((a, b) {
      final g = a.grade.compareTo(b.grade);
      return g == 0 ? a.id.compareTo(b.id) : g;
    });
  final low = (ordered.length * .6).ceil();
  final result = <String, int>{};
  for (final (i, m) in ordered.indexed) {
    final p = i / max(1, ordered.length);
    result[m.id] = i < low
        ? i % 7
        : p < .82
        ? 7 + i % 6
        : p < .93
        ? 13 + i % 8
        : p < .98
        ? 21 + i % 10
        : 31 + i % 20;
  }
  return result;
}

int oculumBlacksmithAvailableGrams(
  Iterable<InventoryItem> inventory,
  InventoryItem target,
  String name,
) => inventory
    .where(
      (i) =>
          !identical(i, target) &&
          oculumNormalizeText(i.nome) == oculumNormalizeText(name),
    )
    .fold(
      0,
      (sum, i) => sum + max(0, (i.peso * 1000 * max(0, i.quantita)).round()),
    );

({int level, int damage, int defense, int shield, int percent, String kind})
oculumBlacksmithPreview(
  InventoryItem target,
  Iterable<InventoryItem> materials,
) {
  final evolved = oculumItemTitleEvolutionReady(target);
  final percent = evolved
      ? 40
      : target.craftData['titleItem'] == true
      ? 15
      : 8;
  final strength = materials.fold<int>(
    0,
    (n, m) => n + oculumBlacksmithMaterialStrength(m),
  );
  final level = materials.fold<int>(
    target.livelloOggetto,
    (n, m) => max(n, oculumBlacksmithMaterialLevel(m)),
  );
  return (
    level: level,
    damage: target.arma
        ? max(
            1,
            ((max(0, target.bonusDanno) + strength) * percent / 100).ceil(),
          )
        : 0,
    defense: target.protegge
        ? max(
            1,
            ((max(0, target.bonusDifesa) + strength) * percent / 100).ceil(),
          )
        : 0,
    shield: target.protegge
        ? max(
            1,
            ((max(0, target.bonusScudo) + strength * 2) * percent / 100).ceil(),
          )
        : 0,
    percent: percent,
    kind: evolved
        ? 'Vero Reforge · Titolo Item evoluto'
        : target.craftData['titleItem'] == true
        ? 'Combinazione ridotta · Titolo Item non evoluto'
        : 'Combinazione minore · equipaggiamento normale',
  );
}

void oculumStrengthenOldEquipmentAbility(
  CharacterSkill skill,
  int percent,
  int oldItemLevel,
) {
  for (final form in skill.forme) {
    form.unlockRequirements.putIfAbsent(
      'equipmentItemLevel',
      () => oldItemLevel,
    );
    for (final effect in form.effettiStrutturati) {
      if (!const {
            'danno',
            'difesa',
            'scudo',
            'cura',
            'hp_temporanei',
          }.contains(effect.type) ||
          effect.mode == 'diminuzione') {
        continue;
      }
      effect.valueExpression =
          '((${effect.valueExpression})${effect.diceExpression.isNotEmpty && effect.diceDestination == 'valore' ? '+(${effect.diceExpression})' : ''})*(100+$percent)/100';
      if (effect.diceDestination == 'valore') effect.diceExpression = '';
    }
  }
}

/// Validate before spending, split exactly one item, and consume exact grams.
/// Returns the resulting item; null means neither materials nor target changed.
InventoryItem? oculumCombineEquipment(
  List<InventoryItem> inventory,
  InventoryItem target,
  List<InventoryItem> materials, {
  required String receipt,
  required int ownerPower,
}) {
  if (receipt.isEmpty ||
      !inventory.contains(target) ||
      target.quantita <= 0 ||
      !target.peso.isFinite ||
      target.peso <= 0 ||
      !oculumEquipmentCanBecomeTitle(target) ||
      materials.isEmpty) {
    return null;
  }
  final seen = (target.craftData['blacksmithReceipts'] as List? ?? [])
      .map((e) => '$e')
      .toSet();
  if (seen.contains(receipt)) return null;
  final selected = <InventoryItem>[];
  final names = <String>{};
  for (final item in materials) {
    if (!inventory.contains(item) ||
        identical(item, target) ||
        !names.add(oculumNormalizeText(item.nome)) ||
        oculumBlacksmithMaterial(item) == null) {
      return null;
    }
    if (oculumBlacksmithAvailableGrams(inventory, target, item.nome) <
        oculumBlacksmithMinimumGrams(target, item)) {
      return null;
    }
    selected.add(item);
  }
  final preview = oculumBlacksmithPreview(target, selected);
  final oldLevel = target.livelloOggetto;
  final forged = InventoryItem.fromJson(
    oculumCopyJsonTree(target.toJson()) as Map<String, dynamic>,
  )..quantita = 1;
  for (final ability in oculumAllEquipmentAbilities(forged)) {
    oculumStrengthenOldEquipmentAbility(ability, preview.percent, oldLevel);
  }
  if (oculumItemTitleEvolutionReady(forged) &&
      !oculumReforgeItemTitle(forged, ownerPower: ownerPower)) {
    return null;
  }
  forged.bonusDanno += preview.damage;
  forged.bonusDifesa += preview.defense;
  forged.bonusScudo += preview.shield;
  forged.livelloOggetto = preview.level;
  forged.ability ??= oculumEquipmentAbility(
    forged.nome,
    forged.gradoOggetto,
    element: forged.elementoDanno,
  );
  final additions = <CharacterSkill>[];
  final details = <Map<String, dynamic>>[];
  var addedGrams = 0;
  for (final item in selected) {
    final material = oculumBlacksmithMaterial(item)!;
    final grams = oculumBlacksmithMinimumGrams(target, item);
    addedGrams += grams;
    final level = oculumBlacksmithMaterialLevel(item);
    final strength = oculumBlacksmithMaterialStrength(item);
    final type = forged.arma ? 'danno' : 'scudo';
    additions.add(
      CharacterSkill(
        nome: 'Intarsio · ${material.name}',
        tipo: 'Skill equipaggiamento',
        costo: '1 Volontà',
        cooldown: '3 turni',
        descrizione: material.effect,
        forme: [
          CharacterSkillForm(
            nome: material.name,
            tipo: forged.arma ? 'Attacco' : 'Difesa',
            livello: '$level',
            costo: '1 Volontà',
            costoStrutturato: OculumSkillCost(
              resource: 'volonta',
              amountExpression: '1',
            ),
            cooldown: '3 turni',
            cooldownStrutturato: OculumAbilityCooldown(
              amount: 3,
              startsReady: true,
            ),
            descrizione:
                '${material.effect} ${forged.arma ? '+$strength Danni al prossimo attacco' : '+${strength * 2} Scudo'}; richiede livello $level.',
            effettiStrutturati: [
              OculumStructuredEffect(
                type: type,
                valueExpression: '${forged.arma ? strength : strength * 2}',
                mode: forged.arma ? 'prossima_azione' : 'immediato',
                elementType: forged.elementoDanno,
              ),
            ],
            oculumLimitiConfiguratiManualmente: true,
          ),
        ],
      ),
    );
    final passive = oculumParseStructuredEffectsFromText(material.passive).effects;
    if (passive.isNotEmpty) {
      additions.last.forme.add(CharacterSkillForm(nome: '${material.name} · passiva', tipo: 'Passiva', livello: '$level', costo: 'Gratuito', costoStrutturato: OculumSkillCost(resource: 'nessuna'), descrizione: material.passive, effettiStrutturati: passive));
    }
    final active = oculumParseStructuredEffectsFromText(material.active).effects;
    if (active.isNotEmpty) {
      additions.last.forme.first.effettiStrutturati = active;
      additions.last.forme.first.tipo = active.any((e) => const {'danno','danno_percentuale'}.contains(e.type)) ? 'Attacco' : 'Difesa';
      additions.last.forme.first.descrizione = '${material.effect} Attivazione: ${material.active}. Richiede livello $level.';
    }
    details.add({
      'name': material.name,
      'material': material.id,
      'inventoryName': item.nome,
      'grams': grams,
      'level': level,
      'strength': strength,
      'effect': material.effect,
      'passive': material.passive,
      'active': material.active,
    });
  }
  forged.materialAbilities = [...forged.materialAbilities, ...additions];
  forged.peso += addedGrams / 1000;
  final count =
      max(
        readIntValue(target.craftData['blacksmithForgeCount']),
        readIntValue(target.craftData['titleReforgeCount']),
      ) +
      1;
  forged.craftData = {
    ...forged.craftData,
    'blacksmithForgeCount': count,
    'blacksmithReceipts': [...seen, receipt],
    'materialInlays': [
      ...(target.craftData['materialInlays'] as List? ?? []),
      ...details,
    ],
  };
  forged.note +=
      '\n${preview.kind}: +${preview.damage} Danni, +${preview.defense} Difesa, +${preview.shield} Scudo. Materiali: ${details.map((d) => '${d['material']} ${d['grams']} g').join(', ')}. Vecchi poteri conservati e potenziati; nuovi poteri al livello richiesto.';
  // Commit only after the complete result has been constructed successfully.
  final index = inventory.indexOf(target);
  if (target.quantita > 1) {
    target.quantita--;
    target.craftData = {
      ...target.craftData,
      'blacksmithReceipts': [...seen, receipt],
    };
    forged.equipaggiata = false;
    inventory.insert(index + 1, forged);
  } else {
    inventory[index] = forged;
  }
  for (final entry in details) {
    var remaining = readIntValue(entry['grams']);
    for (final item in inventory.toList().reversed) {
      if (identical(item, forged) ||
          identical(item, target) ||
          oculumNormalizeText(item.nome) !=
              oculumNormalizeText('${entry['inventoryName']}') ||
          remaining == 0) {
        continue;
      }
      final available = max(
        0,
        (item.peso * 1000 * max(0, item.quantita)).round(),
      );
      final taken = min(remaining, available);
      remaining -= taken;
      if (taken == available) {
        inventory.remove(item);
      } else {
        item.quantita = 1;
        item.peso = (available - taken) / 1000;
      }
    }
  }
  return forged;
}

extension _OculumBlacksmith on _OculumHomePageState {
  Future<void> showBlacksmithCombine() async {
    if (!merchantIsOpen || merchantShopType != 'fabbro') return;
    InventoryItem? target;
    final chosen = <InventoryItem>{};
    final origin = currentSheetScrollId();
    final receipt = 'blacksmith:${DateTime.now().microsecondsSinceEpoch}';
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) {
          final candidates = target == null
              ? <InventoryItem>[]
              : inventario
                    .where(
                      (i) =>
                          !identical(i, target) &&
                          oculumBlacksmithMaterial(i) != null &&
                          oculumBlacksmithAvailableGrams(
                                inventario,
                                target!,
                                i.nome,
                              ) >=
                              oculumBlacksmithMinimumGrams(target!, i),
                    )
                    .toList();
          final unique = <String, InventoryItem>{
            for (final i in candidates) oculumNormalizeText(i.nome): i,
          }.values.toList();
          final preview = target == null
              ? null
              : oculumBlacksmithPreview(target!, chosen);
          final cost = target == null ? 0 : oculumBlacksmithDustCost(target!);
          return AlertDialog(
            title: const Text('Fabbro · Combina'),
            content: SizedBox(
              width: 650,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<InventoryItem>(
                      isExpanded: true,
                      initialValue: target,
                      hint: const Text('Scegli arma, armatura o scudo'),
                      items: [
                        for (final item in inventario.where(
                          (i) =>
                              i.quantita > 0 &&
                              oculumEquipmentCanBecomeTitle(i),
                        ))
                          DropdownMenuItem(
                            value: item,
                            child: Text(
                              item.nome,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => update(() {
                        target = v;
                        chosen.clear();
                      }),
                    ),
                    if (target != null) ...[
                      Text(
                        '${preview!.kind}\nCosto di questo oggetto: $cost Ascension Dust · precedenti lavorazioni ${max(readIntValue(target!.craftData['blacksmithForgeCount']), readIntValue(target!.craftData['titleReforgeCount']))}.\nLivello ${target!.livelloOggetto} → ${preview.level}; +${preview.damage} Danni, +${preview.defense} Difesa, +${preview.shield} Scudo. Potenziamento vecchi effetti ${preview.percent}%. Peso dei materiali aggiunto all’equipaggiamento.',
                      ),
                      for (final material in unique)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: chosen.contains(material),
                          title: Text(material.nome),
                          subtitle: Text(
                            'Minimo ${oculumBlacksmithMinimumGrams(target!, material)} g · disponibili ${oculumBlacksmithAvailableGrams(inventario, target!, material.nome)} g · livello ${oculumBlacksmithMaterialLevel(material)} · forza ${oculumBlacksmithMaterialStrength(material)}\n${oculumBlacksmithMaterial(material)!.effect}',
                          ),
                          onChanged: (v) => update(() {
                            v == true
                                ? chosen.add(material)
                                : chosen.remove(material);
                          }),
                        ),
                      if (unique.isEmpty)
                        const Text(
                          'Nessun materiale raggiunge il minimo d’inserimento. Nessuna risorsa sarà consumata.',
                        ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed:
                    target == null ||
                        chosen.isEmpty ||
                        leggiNumero(ascensionDustController) < cost
                    ? null
                    : () {
                        if (!merchantIsOpen ||
                            merchantShopType != 'fabbro' ||
                            currentSheetScrollId() != origin ||
                            !inventario.contains(target) ||
                            leggiNumero(ascensionDustController) <
                                oculumBlacksmithDustCost(target!)) {
                          return;
                        }
                        final payable = oculumBlacksmithDustCost(target!);
                        final forged = oculumCombineEquipment(
                          inventario,
                          target!,
                          chosen.toList(),
                          receipt: receipt,
                          ownerPower: scoutTotalPowerAt(schedaCorrente),
                        );
                        if (forged == null) return;
                        ascensionDustController.text =
                            '${leggiNumero(ascensionDustController) - payable}';
                        invalidateDerivedDataCaches();
                        aggiungiLog(
                          '[FABBRO] ${forged.nome}: −$payable Dust. ${forged.note.split('\n').last}',
                        );
                        programmaSalvataggio();
                        Navigator.pop(dialog);
                      },
                child: Text('Combina · $cost Dust'),
              ),
            ],
          );
        },
      ),
    );
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(() {});
    }
  }
}
