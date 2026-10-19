part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

({int normal, int superInspiration, int oculum}) oculumFateSignChances(
  int cost,
) {
  final progress = (cost.clamp(50, 120) - 50) / 70;
  final superChance = (20 + 20 * progress).round();
  final oculumChance = (10 + 20 * progress).round();
  return (
    normal: 100 - superChance - oculumChance,
    superInspiration: superChance,
    oculum: oculumChance,
  );
}

String oculumFateSignOutcome(int cost, int percentile) {
  final chance = oculumFateSignChances(cost);
  final roll = percentile.clamp(0, 99);
  return roll < chance.normal
      ? 'normal'
      : roll < chance.normal + chance.superInspiration
      ? 'super'
      : 'oculum';
}

Map<String, dynamic> oculumFateSignOffer() => {
  'id': 'fate_sign',
  'kind': 'fate_sign',
  'name': 'Segno del Fato',
  'cost': 50,
  'desc':
      'Scegli da 50 a 120 Obser. A 50: 70% Ispirazione, 20% Super Ispirazione, 10% Ispirazione Oculum. A 120: 30%/40%/30%. Crescita graduale: più spendi, maggiori sono le possibilità rare. Monouso, rispetta i limiti di Ispirazione.',
};

extension _OculumFateSign on _OculumHomePageState {
  Future<int?> chooseFateSignPrice() => showDialog<int>(
    context: context,
    builder: (dialog) {
      var selected = 50;
      return StatefulBuilder(
        builder: (context, update) {
          final chance = oculumFateSignChances(selected);
          return AlertDialog(
            title: const Text('Segno del Fato'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$selected Obser',
                  style: TextStyle(color: tertiaryColor, fontSize: 22),
                ),
                Slider(
                  value: selected.toDouble(),
                  min: 50,
                  max: 120,
                  divisions: 70,
                  label: '$selected Obser',
                  onChanged: (value) => update(() => selected = value.round()),
                ),
                Text(
                  'Ispirazione ${chance.normal}%\nSuper Ispirazione ${chance.superInspiration}%\nIspirazione Oculum ${chance.oculum}%',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Il segno si conserva nell’inventario. Consumarlo assegna un’ispirazione rispettando i limiti già previsti.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: selected > leggiNumero(obserController)
                    ? null
                    : () => Navigator.pop(dialog, selected),
                child: const Text('Acquista'),
              ),
            ],
          );
        },
      );
    },
  );

  void useFateSign(InventoryItem item) {
    final cost = readIntValue(
      (item.craftData['fateSign'] as Map)['cost'],
      fallback: 50,
    ).clamp(50, 120);
    final roll = Random.secure().nextInt(100);
    final outcome = oculumFateSignOutcome(cost, roll);
    final messages = <String>[];
    item.quantita--;
    if (item.quantita <= 0) inventario.remove(item);
    grantInspirationWithCap(outcome, 1, messages);
    final label = switch (outcome) {
      'super' => 'Super Ispirazione',
      'oculum' => 'Ispirazione Oculum',
      _ => 'Ispirazione',
    };
    aggiungiLog(
      '[SEGNO DEL FATO] $cost Obser · d100 ${roll + 1}: $label. ${messages.join(' ')} Segno consumato.',
    );
    programmaSalvataggio();
  }
}
