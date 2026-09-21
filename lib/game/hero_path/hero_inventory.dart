part of 'hero_engine.dart';

extension HeroInventory on HeroRun {
  void offerCards() {
    final pool = heroSkills.where((s) => !cards.containsKey(s.id)).toList();
    cardOffers.clear();
    while (cardOffers.length < 3 && pool.isNotEmpty) {
      cardOffers.add(pool.removeAt(rng.nextInt(pool.length)).id);
    }
  }

  bool chooseCard(String id) {
    if (finished || pendingDeath || !cardOffers.contains(id)) return false;
    cards[id] = 0;
    cardOffers.clear();
    return true;
  }

  void heal(int amount, {bool fullTreatment = false}) {
    player.hp = max(player.hp, min(player.maxHp, player.hp + max(0, amount)));
    if (fullTreatment) {
      player.conditions.remove('Sanguinante');
      player.conditions.remove('Bendato');
      player.conditions.remove('Avvelenato');
      player.conditions['Protezione Sanguinante'] =
          OculusRules.protectionScenes;
      for (final f in flags.where((f) => f.startsWith('ferita:')).toList()) {
        adapt(f.substring(7), handled: true);
        flags.remove(f);
      }
    }
  }

  bool useItem(String item) {
    if (finished ||
        pendingDeath ||
        pendingVictory ||
        pendingEscape ||
        (inventory[item] ?? 0) <= 0) {
      return false;
    }
    if (![
      'Benda improvvisata',
      'Carne',
      'Erbe',
      'Corna dell’Alce Cieco',
    ].contains(item)) {
      return false;
    }
    if (inCombat) {
      captureAction('item:$item');
    } else {
      actionSnapshot = null;
    }
    inventory[item] = inventory[item]! - 1;
    switch (item) {
      case 'Benda improvvisata':
        player.conditions.remove('Sanguinante');
        player.conditions['Bendato'] = -1;
        note('Il sangue si ferma. Gli sforzi fisici fanno ancora male.');
      case 'Carne':
        heal(2);
        foodBonuses['volonta'] = 1;
        note('La carne ti scalda. +1 Volontà fino a fine giornata.');
      case 'Erbe':
        heal(2);
        note('Le erbe leniscono il dolore, ma non curano la ferita.');
      case 'Corna dell’Alce Cieco':
        weaponBonus += OculusRules.antlerEquipment;
        weapon = 'Lama con Corna dell’Alce Cieco';
        note('Le corna diventano parte dell’arma: +15 danno.');
    }
    if (inCombat) {
      endTurn(preserveSnapshot: true);
    }
    return true;
  }

  bool craftBandage() {
    if (finished || pendingDeath || inCombat || (inventory['Erbe'] ?? 0) < 1) {
      return false;
    }
    inventory['Erbe'] = inventory['Erbe']! - 1;
    inventory.update('Benda improvvisata', (n) => n + 1, ifAbsent: () => 1);
    return true;
  }

  bool eat(String food) {
    if (finished ||
        pendingDeath ||
        inCombat ||
        location != 'Villaggio' ||
        !heroFoods.containsKey(food)) {
      return false;
    }
    final f = heroFoods[food]!;
    if (obser < f.$1) return false;
    obser -= f.$1;
    foodBonuses[f.$3 == 'run' ? 'run_${f.$2}' : f.$2] = f.$4;
    note('$food: +${f.$4} ${f.$2}, durata ${f.$3}.');
    return true;
  }

  bool sleep() {
    if (finished ||
        pendingDeath ||
        inCombat ||
        eventId.isNotEmpty ||
        titleOffers.isNotEmpty ||
        !night ||
        location != 'Villaggio' ||
        obser < OculusRules.sleepCost) {
      return false;
    }
    obser -= OculusRules.sleepCost;
    player.replenish();
    if (hasTitle('rest')) player.hp++;
    for (final e in eyes) {
      e.rest();
    }
    do {
      nextScene();
    } while (night && !finished && !pendingDeath);
    if (!finished && !pendingDeath) {
      note('Ti svegli al rumore delle stoviglie.');
    }
    return true;
  }

  bool healer() {
    if (finished ||
        pendingDeath ||
        inCombat ||
        location != 'Villaggio' ||
        obser < OculusRules.healCost) {
      return false;
    }
    obser -= OculusRules.healCost;
    heal(player.maxHp, fullTreatment: true);
    note(
      'Il guaritore rimuove la benda. +2 contro Sanguinante per ${OculusRules.protectionScenes} scene.',
    );
    return true;
  }

  bool buy(String item) {
    const shop = {
      'Benda improvvisata': 2,
      'Stivali da fuga': 6,
      'Mantello silente': 6,
      'Ferro opaco': 3,
    };
    final cost = shop[item];
    if (finished ||
        pendingDeath ||
        inCombat ||
        location != 'Villaggio' ||
        cost == null ||
        obser < cost) {
      return false;
    }
    obser -= cost;
    inventory.update(item, (n) => n + 1, ifAbsent: () => 1);
    return true;
  }

  void addOre() {
    final index = min(3, max(0, scene ~/ 20 + (rng.nextInt(100) < 10 ? 1 : 0)));
    final ore = heroMinerals.keys.elementAt(index);
    inventory.update(
      ore,
      (n) => n + 1 + (hasTitle('ore') ? 1 : 0),
      ifAbsent: () => 1 + (hasTitle('ore') ? 1 : 0),
    );
    note('Trovi $ore.');
  }

  bool improveWeapon(String mineral) {
    if (finished ||
        pendingDeath ||
        inCombat ||
        (inventory[mineral] ?? 0) < OculusRules.mineralCost ||
        !heroMinerals.containsKey(mineral)) {
      return false;
    }
    inventory[mineral] = inventory[mineral]! - OculusRules.mineralCost;
    weaponBonus += heroMinerals[mineral]!;
    return true;
  }

  bool upgradeCard(String id) {
    if (finished ||
        pendingDeath ||
        inCombat ||
        !cards.containsKey(id) ||
        cards[id]! >= 3 ||
        dust < OculusRules.upgradeCost) {
      return false;
    }
    dust -= OculusRules.upgradeCost;
    cards[id] = cards[id]! + 1;
    return true;
  }

  void offerTitles() {
    final pool = heroTitles.where((t) => !titles.contains(t.id)).toList();
    titleOffers.clear();
    while (titleOffers.length < 3 && pool.isNotEmpty) {
      titleOffers.add(pool.removeAt(rng.nextInt(pool.length)).id);
    }
  }

  bool chooseTitle(String id) {
    if (finished || pendingDeath || !titleOffers.contains(id)) return false;
    titles.add(id);
    titleOffers.clear();
    if (hasTitle('path')) flags.add('landa_aperta');
    if (hasTitle('dream')) flags.add('sogno_aperto');
    return true;
  }

  void obtainEye({HeroActor? source}) {
    if (eyes.length >= OculusRules.maxEyes) {
      dust++;
      note('La borsa degli Occhi è piena: raccogli una Dust.');
      return;
    }
    final percentile = rng.nextInt(100);
    final rarity = percentile < 5
        ? EyeRarity.oculum
        : percentile < 20
        ? EyeRarity.rare
        : percentile < 50
        ? EyeRarity.uncommon
        : EyeRarity.common;
    final actor = source == null
        ? createEnemy(monster('ossa'))
        : HeroActor.fromJson(source.toJson());
    actor.id = 'eye_${seed}_${scene}_${eyes.length}';
    actor.replenish();
    final eye = HeroEye(actor: actor, rarity: rarity)
      ..bond = OculusRules.initialBond(
        rarity,
        rarity == EyeRarity.oculum ? rng.nextInt(100) : 99,
      );
    eye.sourceId = source?.id ?? 'ossa';
    eyes.add(eye);
    note(
      'Occhio dei Caduti ottenuto — ${['Comune', 'Non Comune', 'Raro', 'Oculum'][rarity.index]}',
    );
  }

  bool useDust(HeroEye eye, int amount) {
    if (finished ||
        pendingDeath ||
        inCombat ||
        !eyes.contains(eye) ||
        amount <= 0 ||
        dust < amount ||
        eye.bond >= OculusRules.maxBond) {
      return false;
    }
    final used = min(
      amount,
      ((OculusRules.maxBond - eye.bond) / OculusRules.dustBond).ceil(),
    );
    dust -= used;
    eye.bond = min(OculusRules.maxBond, eye.bond + used * OculusRules.dustBond);
    return true;
  }

  bool reforge(HeroEye eye) {
    if (finished ||
        pendingDeath ||
        inCombat ||
        !eyes.contains(eye) ||
        eye.rarity == EyeRarity.oculum ||
        dust < OculusRules.reforgeCost(eye.rarity)) {
      return false;
    }
    dust -= OculusRules.reforgeCost(eye.rarity);
    eye.reforgeAttempts++;
    if (rng.nextInt(100) <
        OculusRules.reforge[difficulty.index][eye.rarity.index]) {
      eye.rarity = EyeRarity.values[eye.rarity.index + 1];
      eye.failures = 0;
      note('Reforge riuscito. L’Occhio cambia colore.');
    } else {
      eye.failures++;
      note('Reforge fallito. L’Occhio resta intatto.');
    }
    return true;
  }
}
