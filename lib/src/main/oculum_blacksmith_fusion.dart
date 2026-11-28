part of '../../main.dart';

enum OculumEquipmentFusionKind { weapon, armor, shield }

OculumEquipmentFusionKind? oculumEquipmentFusionKind(InventoryItem item) {
  if (item.quantita <= 0 || !oculumEquipmentCanBecomeTitle(item)) return null;
  final protection = oculumWearProtectionKind(item);
  final family =
      item.craftData['wearProtectionKind'] ??
      item.craftData['itemFamily'] ??
      item.monsterLoot['itemFamily'];
  if (protection == OculumWearProtectionKind.shield || family == 'shield') {
    return OculumEquipmentFusionKind.shield;
  }
  if (protection == OculumWearProtectionKind.armor ||
      family == 'armor' ||
      item.craftData['clothing'] == true) {
    return OculumEquipmentFusionKind.armor;
  }
  final name = oculumNormalizeText(item.nome);
  if (item.protegge &&
      RegExp(r'\b(scudo|shield|brocchiere)\b').hasMatch(name)) {
    return OculumEquipmentFusionKind.shield;
  }
  if (item.arma) return OculumEquipmentFusionKind.weapon;
  return item.protegge ? OculumEquipmentFusionKind.armor : null;
}

String oculumEquipmentFusionBonus(OculumEquipmentFusionKind kind) =>
    switch (kind) {
      OculumEquipmentFusionKind.weapon => '+1 Danni',
      OculumEquipmentFusionKind.armor => '+1 Difesa e +1 Scudo',
      OculumEquipmentFusionKind.shield => '+1 Danni e +1 Difesa',
    };

int oculumFusedShieldDamageBonus(InventoryItem item) =>
    !item.arma && item.craftData['equipmentFusionKind'] == 'shield'
    ? oculumEquipmentWearValue(item, item.bonusDanno)
    : 0;

List<Map<String, dynamic>> oculumEquipmentShieldBreakEffects(
  InventoryItem item,
) => [
  if (item.effettoRotturaScudo.isNotEmpty) item.effettoRotturaScudo,
  if (item.craftData['extraShieldBreakEffects'] case final List extra)
    for (final effect in extra.whereType<Map>())
      if (effect.isNotEmpty) Map<String, dynamic>.from(effect),
];

void _setEquipmentShieldBreakEffects(
  InventoryItem item,
  List<Map<String, dynamic>> effects,
) {
  item.effettoRotturaScudo = effects.firstOrNull ?? const {};
  item.craftData = {...item.craftData}..remove('extraShieldBreakEffects');
  if (effects.length > 1) {
    item.craftData['extraShieldBreakEffects'] = effects.skip(1).toList();
  }
}

bool oculumEquipmentCanFuse(InventoryItem first, InventoryItem second) {
  final firstKind = oculumEquipmentFusionKind(first);
  return firstKind != null &&
      firstKind == oculumEquipmentFusionKind(second) &&
      (!identical(first, second) || first.quantita >= 2);
}

InventoryItem? oculumFuseEquipment(
  List<InventoryItem> inventory,
  InventoryItem first,
  InventoryItem second, {
  required String name,
  required String receipt,
}) {
  final finalName = name.trim();
  final firstIndex = inventory.indexOf(first);
  if (finalName.isEmpty ||
      receipt.isEmpty ||
      firstIndex < 0 ||
      !inventory.contains(second) ||
      !oculumEquipmentCanFuse(first, second) ||
      inventory.any(
        (item) => item.craftData['equipmentFusionReceipt'] == receipt,
      )) {
    return null;
  }
  final kind = oculumEquipmentFusionKind(first)!;
  InventoryItem copy(InventoryItem item) => InventoryItem.fromJson(
    oculumCopyJsonTree(item.toJson()) as Map<String, dynamic>,
  );
  final combined = copy(first);
  final donor = copy(second);
  // Named monster techniques can be materialized from the existing inventory UI.
  void retainNamedAbility(InventoryItem item) {
    if (item.ability != null || item.monsterLoot['skill'] is! Map) return;
    item.ability = oculumEquipmentAbilityFromArt(
      ArtSkill.fromJson(
        Map<String, dynamic>.from(item.monsterLoot['skill'] as Map),
      ),
    );
  }

  retainNamedAbility(combined);
  retainNamedAbility(donor);
  final level = max(first.livelloOggetto, second.livelloOggetto);
  // The two source skills have their own item-level requirements.
  for (final original in [combined, donor]) {
    if (original.livelloOggetto == level) continue;
    for (final ability in oculumAllEquipmentAbilities(original)) {
      for (final form in ability.forme) {
        form.unlockRequirements.putIfAbsent(
          'equipmentItemLevel',
          () => original.livelloOggetto,
        );
      }
    }
  }
  final breakEffects = [
    for (final original in [combined, donor])
      for (final effect in oculumEquipmentShieldBreakEffects(original))
        {
          ...effect,
          'usesPosteaBreakChance':
              effect['usesPosteaBreakChance'] ??
              (original.craftData['cyberPostea'] == true),
        },
  ];
  final abilities = oculumAllEquipmentAbilities(donor);
  combined.materialAbilities = [...combined.materialAbilities, ...abilities];
  // Make the second equipment skill accessible through the regular item editor
  // even when the first piece had no stock ability of its own.
  if (combined.ability == null && combined.materialAbilities.isNotEmpty) {
    combined.ability = combined.materialAbilities.first;
    combined.materialAbilities = combined.materialAbilities.skip(1).toList();
  }
  String appendText(String parent, String additional) => {
    parent.trim(),
    additional.trim(),
  }.where((text) => text.isNotEmpty).join('\n');
  int integrity(int a, int b) => a < 0
      ? b
      : b < 0
      ? a
      : min(a, b);
  combined
    ..nome = finalName
    ..quantita = 1
    ..peso += donor.peso
    ..equipaggiata = false;
  combined
    ..arma = first.arma || second.arma
    ..protegge = first.protegge || second.protegge
    ..gradoOggetto = max(first.gradoOggetto, second.gradoOggetto)
    ..gradoRichiesto = max(first.gradoRichiesto, second.gradoRichiesto)
    ..livelloOggetto = level
    ..bonusDanno =
        max(first.bonusDanno, second.bonusDanno) +
        (kind == OculumEquipmentFusionKind.armor ? 0 : 1)
    ..bonusDifesa =
        max(first.bonusDifesa, second.bonusDifesa) +
        (kind == OculumEquipmentFusionKind.weapon ? 0 : 1)
    ..bonusScudo =
        max(first.bonusScudo, second.bonusScudo) +
        (kind == OculumEquipmentFusionKind.armor ? 1 : 0)
    ..bonusScudoIncludeGrado = second.bonusScudo > first.bonusScudo
        ? second.bonusScudoIncludeGrado
        : first.bonusScudoIncludeGrado
    ..bonusScudoOculum = max(first.bonusScudoOculum, second.bonusScudoOculum)
    ..scudoIntegritaCorrente = integrity(
      first.scudoIntegritaCorrente,
      second.scudoIntegritaCorrente,
    )
    ..scudoIntegritaOculumCorrente = integrity(
      first.scudoIntegritaOculumCorrente,
      second.scudoIntegritaOculumCorrente,
    )
    ..effettoIntegritaScudo = appendText(
      first.effettoIntegritaScudo,
      second.effettoIntegritaScudo,
    )
    ..monsterLoot = {...donor.monsterLoot, ...combined.monsterLoot}
    ..buff = appendText(first.buff, second.buff)
    ..note = appendText(first.note, second.note);
  combined.note = appendText(
    combined.note,
    'Fusione Fabbro: ${first.nome} + ${second.nome}. ${oculumEquipmentFusionBonus(kind)}.',
  );
  final capacity = oculumEquipmentCapacity(combined);
  final wear = min(
    oculumEquipmentUses(first) * capacity ~/ oculumEquipmentCapacity(first),
    oculumEquipmentUses(second) * capacity ~/ oculumEquipmentCapacity(second),
  );
  combined.craftData = {
    ...donor.craftData,
    ...combined.craftData,
    if (kind != OculumEquipmentFusionKind.weapon)
      'wearProtectionKind': kind.name,
    _wearUsesKey: wear,
    _wearCapacityKey: capacity,
    if (wear == 0)
      _wearBrokenKey: max(
        oculumEquipmentBrokenPercent(first),
        oculumEquipmentBrokenPercent(second),
      ),
    'equipmentFusionKind': kind.name,
    'equipmentFusionReceipt': receipt,
    'equipmentFusionSources': [first.nome, second.nome],
  };
  _setEquipmentShieldBreakEffects(combined, breakEffects);
  first.quantita--;
  second.quantita--;
  inventory.removeWhere(
    (item) =>
        (identical(item, first) || identical(item, second)) &&
        item.quantita <= 0,
  );
  inventory.insert(min(firstIndex, inventory.length), combined);
  return combined;
}

extension _OculumBlacksmithFusion on _OculumHomePageState {
  bool get canUseBlacksmithFusion {
    if (!_blacksmithServiceAvailable(null) ||
        salvataggioBloccatoPerErrore ||
        schedaCorrente < 0 ||
        schedaCorrente >= schedePersonaggio.length) {
      return false;
    }
    final sheet = schedePersonaggio[schedaCorrente];
    return !readBoolValue(sheet['realtimeReadOnlyByMaster']) &&
        !readBoolValue(sheet['realtimeRestrictedByMaster']);
  }

  Future<void> showBlacksmithFusion() async {
    if (!canUseBlacksmithFusion) return;
    final origin = currentSheetScrollId();
    final receipt = 'fusion:${DateTime.now().microsecondsSinceEpoch}';
    InventoryItem? first;
    InventoryItem? second;
    var name = '';
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) {
          final equipment = inventario
              .where((item) => oculumEquipmentFusionKind(item) != null)
              .toList();
          List<DropdownMenuItem<InventoryItem>> rows(
            Iterable<InventoryItem> items,
          ) => [
            for (final item in items)
              DropdownMenuItem(
                value: item,
                child: Text(item.nome, overflow: TextOverflow.ellipsis),
              ),
          ];
          final activeFirst = equipment.contains(first) ? first : null;
          final donors = activeFirst == null
              ? <InventoryItem>[]
              : equipment
                    .where((item) => oculumEquipmentCanFuse(activeFirst, item))
                    .toList();
          final activeSecond = donors.contains(second) ? second : null;
          final kind = activeFirst == null
              ? null
              : oculumEquipmentFusionKind(activeFirst);
          return AlertDialog(
            title: const Text('Fabbro · Fondi equipaggiamento'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'I due pezzi diventano un solo oggetto. Le abilità restano utilizzabili singolarmente.',
                    ),
                    DropdownButtonFormField<InventoryItem>(
                      key: ValueKey(activeFirst),
                      initialValue: activeFirst,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Primo pezzo',
                      ),
                      items: rows(equipment),
                      onChanged: (item) => update(() {
                        first = item;
                        second = null;
                      }),
                    ),
                    DropdownButtonFormField<InventoryItem>(
                      key: ValueKey((activeFirst, activeSecond)),
                      initialValue: activeSecond,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Secondo pezzo della stessa categoria',
                      ),
                      items: rows(donors),
                      onChanged: donors.isEmpty
                          ? null
                          : (item) => update(() => second = item),
                    ),
                    TextFormField(
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Nome del nuovo oggetto',
                      ),
                      onChanged: (value) => update(() => name = value),
                    ),
                    if (kind != null) Text(oculumEquipmentFusionBonus(kind)),
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
                    activeFirst == null ||
                        activeSecond == null ||
                        name.trim().isEmpty
                    ? null
                    : () {
                        if (!canUseBlacksmithFusion ||
                            currentSheetScrollId() != origin)
                          return;
                        final item = oculumFuseEquipment(
                          inventario,
                          activeFirst,
                          activeSecond,
                          name: name,
                          receipt: receipt,
                        );
                        if (item == null) return;
                        invalidateDerivedDataCaches();
                        aggiungiLog(
                          '[FABBRO] ${item.nome}. ${oculumEquipmentFusionBonus(kind!)}.',
                        );
                        programmaSalvataggio(delay: Duration.zero);
                        Navigator.pop(dialog);
                      },
                child: const Text('Fondi'),
              ),
            ],
          );
        },
      ),
    );
  }
}
