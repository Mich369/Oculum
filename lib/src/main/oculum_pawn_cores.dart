part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const oculumCoreTiers = <(String, int, int)>[
  ('Debole', 0, 2),
  ('Medio', 3, 5),
  ('Forte', 6, 8),
  ('Oculum', 9, 12),
];
int oculumCoreRepairDifficulty(int level) => 15 + max(0, level);
String oculumCoreRepairOutcome({
  required int natural,
  required int total,
  required int level,
}) {
  if (natural == 1 || total < 0) return 'scraps';
  if (total < oculumCoreRepairDifficulty(level)) return 'broken';
  return natural >= 15 ? 'conscious' : 'normal';
}

InventoryItem oculumCreatureCore(
  int tier, {
  Map<String, dynamic>? source,
  bool broken = false,
  bool conscious = false,
}) {
  final band = oculumCoreTiers[tier.clamp(0, 3)];
  return InventoryItem(
    nome: broken ? 'Nucleo rotto di Pawn' : 'Nucleo ${band.$1}',
    peso: .2,
    quantita: 1,
    note: broken
        ? 'Meccanica DT 15 + livello originale; un dado naturale di 15+ conserva la coscienza se supera la DT. Critico negativo: scarti metallici. Con 6 kg di Metallo runico rievoca il Pawn a livello 10.'
        : 'Evoca una creatura di grado ${band.$2}/${band.$3}.${conscious ? " Conserva la coscienza della creatura originale." : ""}',
    craftData: {
      'creatureCore': true,
      'coreTier': tier.clamp(0, 3),
      'brokenCore': broken,
      'conscious': conscious,
      // ignore: use_null_aware_elements
      if (source != null) 'coreSource': source,
    },
  );
}

List<Map<String, dynamic>> oculumCreatureCoreOffers() => [
  for (var i = 0; i < oculumCoreTiers.length; i++)
    {
      'id': 'creature_core_$i',
      'name': 'Nucleo ${oculumCoreTiers[i].$1}',
      'kind': 'creature_core',
      'coreTier': i,
      'cost': 100 * oculumCoreTiers[i].$3,
      'description':
          'Nucleo riparato: evoca una creatura di grado ${oculumCoreTiers[i].$2}/${oculumCoreTiers[i].$3}.',
    },
];

extension _OculumPawnCores on _OculumHomePageState {
  void claimBrokenPawnCore(OculumPawnGuardian pawn) {
    if (pawn.alive) return;
    final index = schedePersonaggio.indexWhere(
      (sheet) =>
          '${sheet['sheetTag'] ?? sheet['id'] ?? ''}' == pawn.ownerTag ||
          sheetTagAt(schedePersonaggio.indexOf(sheet)) == pawn.ownerTag,
    );
    if (index < 0) return;
    final sheet = schedePersonaggio[index];
    final claims = List<String>.from(
      sheet['pawnCoreClaims'] as List? ?? const [],
    );
    if (claims.contains(pawn.id)) return;
    claims.add(pawn.id);
    sheet['pawnCoreClaims'] = claims;
    final core = oculumCreatureCore(
      pawn.grade <= 2
          ? 0
          : pawn.grade <= 5
          ? 1
          : pawn.grade <= 8
          ? 2
          : 3,
      source: pawn.toJson(),
      broken: true,
    );
    if (index == schedaCorrente) {
      inventario.add(core);
    } else {
      final items = List<dynamic>.from(
        sheet['inventario'] as List? ?? const [],
      );
      items.add(core.toJson());
      sheet['inventario'] = items;
    }
    aggiungiLog(
      '${pawn.displayName} è morto: ${nomeSchedaPersonaggio(index)} riceve un Nucleo rotto di Pawn.',
    );
    programmaSalvataggio();
  }

  Future<void> repairCreatureCore(InventoryItem item) async {
    if (!inventario.contains(item) ||
        item.quantita <= 0 ||
        item.craftData['brokenCore'] != true) {
      return;
    }
    ensureHiddenEyeDefaults();
    final stat = hiddenEyeStats.where((s) => s.id == 'meccanica').firstOrNull;
    if (stat == null) return;
    final source = Map<String, dynamic>.from(
      item.craftData['coreSource'] as Map? ?? const {},
    );
    final level = readIntValue(source['level']);
    var natural = 0, total = 0;
    await tiraSottotrattoOcchio(
      stat,
      actionLabel:
          'Riparazione nucleo · DT ${oculumCoreRepairDifficulty(level)}',
      onResolved: (n, t) {
        natural = n;
        total = t;
      },
    );
    if (!mounted || natural <= 0 || !inventario.contains(item)) return;
    final outcome = oculumCoreRepairOutcome(
      natural: natural,
      total: total,
      level: level,
    );
    if (outcome == 'broken') {
      aggiungiLog(
        'Nucleo ancora rotto: Meccanica $total < ${oculumCoreRepairDifficulty(level)}.',
      );
      return;
    }
    setState(() {
      item.quantita--;
      if (item.quantita <= 0) inventario.remove(item);
      inventario.add(
        outcome == 'scraps'
            ? InventoryItem(
                nome: 'Scarti metallici',
                peso: .2,
                quantita: 1,
                note: 'Resti di un nucleo distrutto da un critico negativo.',
              )
            : oculumCreatureCore(
                readIntValue(item.craftData['coreTier']),
                source: source,
                conscious: outcome == 'conscious',
              ),
      );
      aggiungiLog(
        'Meccanica $total: ${outcome == 'scraps'
            ? "critico negativo, il nucleo diventa Scarti metallici"
            : outcome == 'conscious'
            ? "nucleo riparato con la coscienza originale"
            : "nucleo riparato"}.',
      );
    });
    programmaSalvataggio();
  }

  Future<void> restorePawnCore(InventoryItem item) async {
    if (!inventario.contains(item) ||
        item.quantita <= 0 ||
        item.craftData['brokenCore'] != true) {
      return;
    }
    final metal = inventario
        .where((i) => i.nome.trim().toLowerCase() == 'metallo runico')
        .toList();
    final grams = metal.fold<int>(
      0,
      (sum, i) => sum + (i.peso * 1000 * i.quantita).round(),
    );
    if (grams < 6000) {
      aggiungiLog(
        'Rievocazione Pawn non eseguita: servono 6 kg di Metallo runico, disponibili $grams g.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text('Rievoca Pawn · Lv 10'),
        content: const Text(
          'Consuma un nucleo rotto e 6 kg di Metallo runico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rievoca'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || !inventario.contains(item)) return;
    var remaining = 6000;
    setState(() {
      for (final m in metal) {
        if (remaining <= 0) break;
        final available = (m.peso * 1000 * m.quantita).round();
        final used = min(remaining, available);
        final leftover = available - used;
        remaining -= used;
        if (leftover == 0) {
          inventario.remove(m);
        } else {
          m.peso = leftover / 1000;
          m.quantita = 1;
        }
      }
      item.quantita--;
      if (item.quantita <= 0) inventario.remove(item);
      inventario.add(
        oculumPawnInventoryItem()
          ..craftData = {
            'pawn': true,
            'recoveryLevel': 10,
            'coreSource': item.craftData['coreSource'],
          },
      );
    });
    final recovered = inventario.last;
    await activatePawnItem(recovered);
    aggiungiLog(
      'Nucleo rotto + 6 kg Metallo runico: Pawn rievocato a livello 10.',
    );
    programmaSalvataggio();
  }

  Future<void> summonCreatureCore(InventoryItem item) async {
    if (!inventario.contains(item) ||
        item.quantita <= 0 ||
        item.craftData['brokenCore'] == true) {
      return;
    }
    final source = item.craftData['coreSource'];
    if (source is Map && source['id'] != null) {
      final recovered = oculumPawnInventoryItem()
        ..craftData = {
          'pawn': true,
          'recoveryLevel': max(0, readIntValue(source['level'])),
          'coreSource': source,
          'conscious': item.craftData['conscious'] == true,
        };
      setState(() {
        item.quantita--;
        if (item.quantita <= 0) inventario.remove(item);
        inventario.add(recovered);
      });
      await activatePawnItem(recovered);
      return;
    }
    final tier = readIntValue(item.craftData['coreTier']).clamp(0, 3);
    final band = oculumCoreTiers[tier];
    var selected = '', grade = band.$2;
    final selection = await showDialog<(String, int)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          backgroundColor: secondaryColor,
          title: Text(item.nome),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OculumMonsterPicker(
                  entries: monsterBookEntries.where((e) => !e.isNpc).toList(),
                  selectedId: selected,
                  onSelected: (id) => refresh(() => selected = id),
                ),
                DropdownButton<int>(
                  value: grade,
                  items: [
                    for (var g = band.$2; g <= band.$3; g++)
                      DropdownMenuItem(value: g, child: Text('Grado $g')),
                  ],
                  onChanged: (g) => refresh(() => grade = g ?? grade),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(ctx, (selected, grade)),
              child: const Text('Evoca'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || selection == null || !inventario.contains(item)) return;
    final entry = monsterBookEntries
        .where((e) => e.id == selection.$1)
        .firstOrNull;
    if (entry == null) return;
    var level = 0;
    while (oculumGradeForLevel(level) < selection.$2) {
      level++;
    }
    setState(() {
      item.quantita--;
      if (item.quantita <= 0) inventario.remove(item);
      aggiungiLog(
        '${item.nome}: evocazione ${entry.nameIt}, grado ${selection.$2}, livello $level.',
      );
    });
    await forzaSalvataggioImmediato(soloLocale: true);
    quickSheetNameController.text = entry.nameIt;
    quickSheetDescriptionController.text = systemMonsterGeneratorDescription(
      entry,
    );
    quickSheetCountController.text = '1';
    await creaSchedaRapidaMaster(
      forcedType: entry.presetType,
      fallbackName: entry.nameIt,
      sideOverride: 'ally',
      forceEnemyProfile: false,
      livelloForzato: level,
      statsMostroForzate: oculumMonsterCreationStats(entry, level),
      monsterVariant: 'base',
      monsterBookSource: entry,
    );
  }
}
