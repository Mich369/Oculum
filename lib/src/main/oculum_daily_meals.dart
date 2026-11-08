part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumDailyMeals on _OculumHomePageState {
  String mealWindowName(String window) => switch (window) {
    'first' => t('Primo pasto', 'First meal'),
    'second' => t('Secondo pasto', 'Second meal'),
    _ => window,
  };

  bool recordCharacterMeal({bool manual = false, bool hydrate = false}) {
    if (!automaticWorldNeedsEnabled ||
        schedaCorrente < 0 ||
        schedaCorrente >= schedePersonaggio.length ||
        schedePersonaggio[schedaCorrente]['realtimeSharedSheet'] == true ||
        !controlsOnlineCombatSheet(sheetTagAt(schedaCorrente))) {
      return false;
    }
    final now = worldClockSeconds;
    final progress = personalNeedsProgress(now: now);
    if (now < progress.processedThrough) return false;
    final meal = progress.recordMeal(
      now,
      manual: manual,
      canRest: !currentCombatIsActive(),
    );
    if (hydrate) progress.satisfy('water', now);
    setState(() {
      worldNeedsCampaigns[worldNeedsCampaignKey] = {
        ...worldNeedsData,
        ...progress.toJson(),
      };
      if (meal.second || meal.third) {
        final resilience = (meal.second ? 2 : 0) + (meal.third ? 1 : 0);
        final other = (meal.second ? 1 : 0) + (meal.third ? 1 : 0);
        final bonus = {
          'resilienza': resilience,
          'volonta': other,
          'materia': other,
          'oculum': other,
        };
        for (final entry in bonus.entries) {
          consumedFoodBonuses.update(
            entry.key,
            (previous) => previous + entry.value,
            ifAbsent: () => entry.value,
          );
        }
        tempResilienza += resilience;
        tempVolonta += other;
        tempMateria += other;
        tempOculum += other;
        rimarginaHpDaAumentoResilienza(resilience);
      }
      impostaCenereControllata(
        leggiNumero(cenereController),
        controllaSvenimento: false,
      );
      syncWorldNeedsLegacyCounters(now);
      invalidateDerivedDataCaches();
    });
    final window = meal.window;
    if (meal.consumed) {
      processConditionTick(OculumConditionTickTrigger.specificEvent);
      if (meal.shortRest) riposoBreve(advanceWorldClock: false);
    }
    final details = [
      if (window != null)
        '${mealWindowName(window)}${meal.early ? ' di domani' : ''} · '
            '${meal.early ? 1 : progress.mealsToday(now)}/2 per il fabbisogno',
      if (meal.second) '+2 RES, +1 VOL/MAT/OCU',
      if (meal.third) 'Terzo pasto · +1 RES/VOL/MAT/OCU',
      if (meal.shortRest) 'Vale come Riposo Breve',
    ];
    if (details.isNotEmpty) aggiungiLog('[PASTO] ${details.join(' · ')}.');
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
    sendRealtimeActiveSheetToStaff();
    return window != null;
  }

  void expireMealBuffsAtLongRest() {
    activeStructuredEffects.removeWhere(
      (effect) =>
          effect['mealBuff'] == true ||
          ('${effect['id']}'.startsWith('merchant_food_') &&
              '${effect['source']}'.startsWith('Cibo e Bevanda · ')),
    );
    final expired = activeConditions
        .where((condition) => condition.metadata['mealBuff'] == true)
        .toList(growable: false);
    for (final condition in expired) {
      removeCondition(condition, force: true, expired: true);
    }
  }
}
