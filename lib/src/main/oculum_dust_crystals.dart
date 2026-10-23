part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const oculumDustCrystalSizes = ['piccolo', 'medio', 'grande'];
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
        'Materiale da crafting e consumabile. Conservalo oppure scegli quando distruggerlo: 1d$faces${resolved == 'piccolo' ? '' : '+2'} Ascension Dust. Nessuna rottura automatica all’acquisto o al drop.',
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

List<Map<String, dynamic>> oculumBoardAfterFight(Iterable<Map> tokens) => [
  for (final token in tokens)
    if (token['side'] != 'enemy' &&
        token['temporaryTurn'] != true &&
        !const {'fled', 'expired'}.contains('${token['status']}'))
      {
        ...Map<String, dynamic>.from(token),
        'actionUsed': false,
        'reportedTurn': 0,
      },
];

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
    if (currentCombatIsActive() && !await requestUtilitySpend('azione')) return;
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
