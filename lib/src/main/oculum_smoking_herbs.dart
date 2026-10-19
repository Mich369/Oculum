part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

Map<String, dynamic> oculumSmokingHerbsOffer(String merchantId) => {
  'id': 'smoking_herbs',
  'kind': 'smoking_herbs',
  'name': 'Erbe fumabili',
  'cost': 30 + monsterSpriteStableSeed(merchantId).abs() % 21,
  'desc':
      '+6 Volontà e +4 Materia: termina al primo limite tra 3 turni di combattimento, 2 riposi brevi e 1 lungo. Poi Confuso: −20% danni, DT +2 per 2 turni o fino alla prossima cura o riposo.',
  'willBonus': 6,
  'matterBonus': 4,
  'combatTurns': 3,
  'shortRests': 2,
  'confusedTurns': 2,
  'damagePenaltyPercent': 20,
  'difficultyPenalty': 2,
};

extension _OculumSmokingHerbs on _OculumHomePageState {
  void ensureSmokingHerbsOffer() {
    if (!merchantStock.any((offer) => offer['id'] == 'smoking_herbs')) {
      merchantStock.add(oculumSmokingHerbsOffer(merchantActiveProfileId));
    }
  }

  int smokingHerbStatBonus(String stat) => merchantHerbalEffects
      .where((effect) => effect['type'] == 'smoking_herbs')
      .fold(0, (sum, effect) => sum + readIntValue(effect[stat]));

  void clearSmokingHerbConfusion() {
    for (final condition
        in activeConditions
            .where((c) => c.conditionType == 'confuso_erbe')
            .toList()) {
      removeCondition(condition, force: true);
    }
  }

  void useSmokingHerbs(InventoryItem item) {
    final config = Map<String, dynamic>.from(
      item.craftData['smokingHerbs'] as Map,
    );
    merchantHerbalEffects.removeWhere(
      (effect) => effect['type'] == 'smoking_herbs',
    );
    merchantHerbalEffects.add({
      'type': 'smoking_herbs',
      'source': item.nome,
      'volonta': readIntValue(config['willBonus'], fallback: 6),
      'materia': readIntValue(config['matterBonus'], fallback: 4),
      'combatTurnsRemaining': readIntValue(config['combatTurns'], fallback: 3),
      'shortRestsRemaining': readIntValue(config['shortRests'], fallback: 2),
      'confusedTurns': readIntValue(config['confusedTurns'], fallback: 2),
      'damagePenaltyPercent': readIntValue(
        config['damagePenaltyPercent'],
        fallback: 20,
      ),
      'difficultyPenalty': readIntValue(
        config['difficultyPenalty'],
        fallback: 2,
      ),
    });
    item.quantita--;
    if (item.quantita <= 0) inventario.remove(item);
    aggiungiLog(
      '[ERBE FUMABILI] +6 Volontà e +4 Materia. Dopo il buff: Confuso, −20% danni e DT +2.',
    );
    invalidateDerivedDataCaches();
    programmaSalvataggio();
  }

  void advanceSmokingHerbs(String trigger) {
    if (trigger != 'turn') clearSmokingHerbConfusion();
    for (final effect
        in merchantHerbalEffects
            .where((e) => e['type'] == 'smoking_herbs')
            .toList()) {
      final key = trigger == 'turn'
          ? 'combatTurnsRemaining'
          : 'shortRestsRemaining';
      effect[key] = max(0, readIntValue(effect[key]) - 1);
      if (trigger == 'long_rest' || readIntValue(effect[key]) == 0) {
        merchantHerbalEffects.remove(effect);
        applyCondition(
          'confuso_erbe',
          duration: readIntValue(effect['confusedTurns'], fallback: 2),
          durationType: OculumConditionDurationType.turns,
          source: 'Erbe fumabili',
          metadata: {
            'damagePenaltyPercent': effect['damagePenaltyPercent'],
            'difficultyPenalty': effect['difficultyPenalty'],
          },
        );
        aggiungiLog(
          '[ERBE FUMABILI] Buff terminato: Confuso, −20% danni e DT +2 fino alla prossima cura/riposo o per 2 turni.',
        );
      }
    }
    invalidateDerivedDataCaches();
  }
}
