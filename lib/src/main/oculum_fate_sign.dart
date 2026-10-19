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

Map<String, dynamic> oculumFateSignOffer([String merchantId = '']) {
  final cost = 50 + monsterSpriteStableSeed('fate:$merchantId').abs() % 71;
  final chance = oculumFateSignChances(cost);
  return {
    'id': 'fate_sign',
    'kind': 'fate_sign',
    'name': 'Segno del Fato',
    'cost': cost,
    'remaining': 1,
    'shopPriceVersion': 1,
    'desc':
        'Disponibile: 1 per negozio. Prezzo del mercante: $cost Obser. '
        'Ispirazione ${chance.normal}%, Super ${chance.superInspiration}%, '
        'Oculum ${chance.oculum}%. Monouso; rispetta i limiti di Ispirazione.',
  };
}

bool oculumChaosSignAvailable(String merchantId) =>
    monsterSpriteStableSeed('chaos-availability:$merchantId').abs() % 100 < 3;

int oculumChaosSignPoints(int percentile) {
  final roll = percentile.clamp(0, 99);
  if (roll < 3) return 0;
  if (roll < 12) return 3;
  if (roll < 25) return 2;
  return 1;
}

Map<String, dynamic> oculumChaosSignOffer(String merchantId) => {
  'id': 'chaos_sign',
  'kind': 'chaos_sign',
  'name': 'Segno del Chaos',
  'cost': 60 + monsterSpriteStableSeed('chaos-price:$merchantId').abs() % 61,
  'remaining': 1,
  'desc':
      'Molto raro: 3% dei negozi dell’alchimista. Una copia. Monouso: '
      'ogni 10 Obser di valore effettua un’estrazione su una statistica casuale '
      '(Resilienza, Volontà, Materia oppure Oculum). '
      '75%: +1; 13%: +2; 9%: +3; 3%: +0. Punti permanenti.',
};

extension _OculumFateSign on _OculumHomePageState {
  void useChaosSign(InventoryItem item) {
    final config = item.craftData['chaosSign'] as Map;
    final cost = readIntValue(config['cost'], fallback: 60).clamp(60, 120);
    final random = Random.secure();
    final controllers = [
      resilienzaController,
      volontaController,
      materiaController,
      oculumController,
    ];
    const names = ['Resilienza', 'Volontà', 'Materia', 'Oculum'];
    final gains = List<int>.filled(4, 0);
    for (var i = 0; i < cost ~/ 10; i++) {
      gains[random.nextInt(4)] += oculumChaosSignPoints(random.nextInt(100));
    }
    item.quantita--;
    if (item.quantita <= 0) inventario.remove(item);
    for (var i = 0; i < controllers.length; i++) {
      controllers[i].text = '${leggiNumero(controllers[i]) + gains[i]}';
    }
    invalidateDerivedDataCaches();
    aggiungiLog(
      '[SEGNO DEL CHAOS] $cost Obser · ${cost ~/ 10} estrazioni: '
      '${List.generate(4, (i) => '${names[i]} +${gains[i]}').join(', ')}. Segno consumato.',
    );
    programmaSalvataggio();
  }

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
