part of 'hero_engine.dart';

extension HeroCombat on HeroRun {
  void endTurn({bool preserveSnapshot = false}) {
    if (!inCombat ||
        finished ||
        pendingDeath ||
        pendingVictory ||
        pendingEscape) {
      return;
    }
    if (!preserveSnapshot) captureAction('endTurn');
    turn++;
    for (final eye in eyes.where((e) => e.summoned && e.actor.hp > 0)) {
      final target = enemies.where((e) => e.hp > 0).firstOrNull;
      if (target == null) break;
      final role = monster(eye.sourceId).role;
      if (eye.rarity.index > 0 && turn % 3 == 0) {
        if (role == 'brain' || role == 'beam') target.conditions['Confuso'] = 2;
        if (role == 'tank' || role == 'root') target.conditions['Legato'] = 1;
        if (role == 'guard') eye.actor.shield++;
      }
      final r = roll(eye.actor, 'volonta', eye.actor.name);
      if (r.total >= roll(target, 'materia', 'Contrasto all’Occhio').total) {
        if (role == 'beam' && eye.rarity == EyeRarity.oculum && turn % 2 == 1) {
          brainBeam(target, eye.actor.baseDamage, r.natural);
          continue;
        }
        damage(
          target,
          (eye.rarity == EyeRarity.common
                  ? max(1, eye.actor.baseDamage ~/ 2)
                  : eye.actor.baseDamage) +
              (role == 'elk' && eye.rarity.index > 0 && turn % 3 == 1
                  ? OculusRules.antlerDamage
                  : 0),
          monster(eye.sourceId).family,
        );
        if (role == 'burn' && eye.rarity.index > 0) {
          target.conditions['Brucia'] = 2;
        }
      }
    }
    enemyTurn();
    pendingDeath = player.hp <= 0;
    pendingVictory = !pendingDeath && enemies.every((e) => e.hp <= 0);
    actionsLeft = OculusRules.baseActions;
    cardsPlayed = 0;
  }

  int get physicalPenalty =>
      player.conditions.containsKey('Bendato') ? OculusRules.strainDamage : 0;
  String cardWarning(String id) {
    final skill = heroSkills.where((s) => s.id == id).firstOrNull;
    return physicalPenalty > 0 &&
            (id == 'attack' || skill?.resource == 'volonta')
        ? 'La ferita bendata causa $physicalPenalty Vita di dolore.'
        : '';
  }

  bool canPlay(String id) {
    if (id == 'inspiration') {
      return !finished && actionSnapshot != null && player.inspirations[0] > 0;
    }
    if (!inCombat ||
        pendingDeath ||
        pendingVictory ||
        pendingEscape ||
        finished) {
      return false;
    }
    if (actionsLeft <= 0 ||
        !cards.containsKey(id) ||
        (cooldowns[id] ?? 0) > turn) {
      return false;
    }
    if (id == 'attack' || id == 'defend') return true;
    final skill = heroSkills.where((s) => s.id == id).firstOrNull;
    if (skill == null) return false;
    final cost = skill.price(cards[id]!);
    return switch (skill.resource) {
      'vita' =>
        player.hp > cost + (cardWarning(id).isNotEmpty ? physicalPenalty : 0),
      'volonta' => player.volonta >= cost,
      'materia' => player.materia >= cost,
      _ => player.oculum >= cost,
    };
  }

  void captureAction(String action) {
    actionSnapshot = null;
    actionSnapshot =
        jsonDecode(jsonEncode(toJson(includeSnapshot: false)))
            as Map<String, dynamic>;
    lastAction = action;
  }

  bool play(String id, {int target = 0}) {
    if (id == 'inspiration') return rewind();
    if (!canPlay(id) ||
        target < 0 ||
        target >= enemies.length ||
        enemies[target].hp <= 0) {
      return false;
    }
    captureAction(id);
    rolls.clear();
    actionsLeft--;
    cardsPlayed++;
    if (cardWarning(id).isNotEmpty) {
      player.hp = max(0, player.hp - physicalPenalty);
    }
    final enemy = enemies[target];
    if (id == 'defend') {
      player.cm += OculusRules.defendCm + cards[id]!;
      player.conditions['Parata'] = 1;
      if (hasTitle('guard')) player.shield++;
      note('Alzi la guardia. CM +${OculusRules.defendCm + cards[id]!}.');
    } else if (id == 'attack') {
      attack(
        enemy,
        amount:
            player.dice['volonta']! +
            player.powerDie +
            bonus('volonta') +
            cards[id]! +
            weaponBonus,
        family: 'Taglio',
      );
    } else {
      final skill = heroSkills.firstWhere((s) => s.id == id);
      final level = cards[id]!;
      final cost = skill.price(level);
      switch (skill.resource) {
        case 'vita':
          player.hp -= cost;
        case 'volonta':
          player.volonta -= cost;
        case 'materia':
          player.materia -= cost;
        default:
          player.oculum -= cost;
      }
      if (skill.resource == 'oculum') tags.add('rumoroso');
      cooldowns[id] =
          turn + skill.cd(level) + (skill.effect == 'actions' ? 1 : 0);
      switch (skill.effect) {
        case 'actions':
          actionsLeft = min(
            OculusRules.maxActions,
            actionsLeft + skill.amount + (level >= 2 ? 1 : 0),
          );
          note('Puoi giocare altre carte in questo turno.');
        case 'heal':
          heal(skill.amount + level, fullTreatment: true);
          note('La ferita si richiude.');
        case 'guard':
          player.shield += skill.amount + level;
          player.conditions['Parata'] = 1;
          note('La tua Art forma una barriera.');
        case 'evade':
          player.conditions['Schivata'] = 1;
          player.conditions['Fuga'] = skill.amount + level;
          note('Prepari un passo fuori dalla traiettoria.');
        case 'control':
          enemy.conditions[skill.condition] =
              1 + (level >= 2 ? 1 : 0) + (hasTitle('control') ? 1 : 0);
          note('${enemy.name}: ${skill.condition}.');
        case 'setup':
          player.conditions['Preparato'] = skill.amount + level;
          note('Prepari il prossimo colpo.');
        case 'area':
          for (final e in enemies.where((e) => e.hp > 0)) {
            attack(e, amount: skill.amount + level, family: skill.element);
          }
        case 'sacrifice':
          attack(
            enemy,
            amount: skill.amount + level * 2 + (hasTitle('sacrifice') ? 1 : 0),
            family: skill.element,
          );
          heal(2);
        default:
          attack(
            enemy,
            amount: skill.amount + level,
            family: skill.element,
            condition: skill.condition,
          );
      }
    }
    pendingDeath = player.hp <= 0;
    pendingVictory = !pendingDeath && enemies.every((e) => e.hp <= 0);
    if (actionsLeft == 0 && !pendingDeath && !pendingVictory) {
      endTurn(preserveSnapshot: true);
    }
    return true;
  }

  void attack(
    HeroActor enemy, {
    required int amount,
    required String family,
    String condition = '',
  }) {
    final a = roll(player, 'volonta', 'Attacco');
    final b = roll(enemy, 'materia', '${enemy.name}: contrasto');
    final exposed = enemy.conditions.containsKey('Esposto');
    if (a.total + (exposed ? 2 : 0) < b.total) {
      note('${enemy.name} devia il colpo.');
      return;
    }
    final critical = OculusRules.critical(a.total, b.total);
    final setup = player.conditions.remove('Preparato') ?? 0;
    final dealt =
        max(1, amount + setup + (exposed && hasTitle('exposed') ? 1 : 0)) *
        (critical ? 2 : 1);
    damage(enemy, dealt, family);
    if (condition.isNotEmpty) {
      enemy.conditions[condition] = 2 + (hasTitle('control') ? 1 : 0);
    }
    note('${critical ? 'Critico. ' : ''}${enemy.name}: $dealt danni.');
  }

  int damage(
    HeroActor target,
    int amount,
    String family, {
    bool ignoreShield = false,
    bool ignoreDefense = true,
  }) {
    var value = max(0, amount - (ignoreDefense ? 0 : target.defense));
    if (target == player) {
      value = (value * (1 - (adaptation[family] ?? 0))).ceil();
    }
    if (!ignoreShield) {
      final absorbed = min(value, target.shield);
      target.shield -= absorbed;
      value -= absorbed;
    }
    target.hp = max(0, target.hp - value);
    if (target == player) adapt(family, handled: false);
    return value;
  }

  void adapt(String family, {required bool handled}) {
    if ((adaptationSamples[family] ?? 0) >= OculusRules.adaptationPerScene) {
      return;
    }
    adaptationSamples.update(family, (n) => n + 1, ifAbsent: () => 1);
    final current = adaptation[family] ?? 0;
    final gain = handled
        ? OculusRules.adaptationHandled * (hasTitle('adapt') ? 1.25 : 1)
        : OculusRules.adaptationHit;
    adaptation[family] = min(
      OculusRules.adaptationCap,
      current + gain * (1 - current / OculusRules.adaptationCap),
    );
  }

  /// The beam uses the unmodified Stat face, never the sum or mastery.
  int brainBeam(HeroActor target, int normalDamage, int natural) => damage(
    target,
    normalDamage * 2,
    'Mente',
    ignoreShield: natural >= OculusRules.beamShieldNatural,
    ignoreDefense: natural >= OculusRules.beamDefenseNatural,
  );
  void enemyTurn() {
    for (final e in enemies.where((e) => e.hp > 0).toList()) {
      if (player.hp <= 0) break;
      for (final dot in ['Brucia', 'Avvelenato']) {
        if (e.conditions.containsKey(dot)) e.hp = max(0, e.hp - 1);
      }
      if (e.hp <= 0) continue;
      if (e.conditions.containsKey('Stordito') ||
          e.conditions.containsKey('Legato')) {
        tickConditions(e);
        continue;
      }
      final def = monster(e.id);
      if (def.role == 'transform' &&
          e.hp <= e.maxHp ~/ 2 &&
          !e.conditions.containsKey('Trasformato')) {
        e.conditions['Trasformato'] = -1;
        e.shield += 3;
        corruption++;
        note('Il Corrotto si apre lungo la schiena.');
      }
      if (def.role == 'brain' || def.role == 'beam') {
        if (turn % 3 == 1) {
          player.conditions['Confuso'] = 2;
          player.oculum = max(0, player.oculum - 1);
        }
        if (turn % 3 == 2) {
          final host = enemies.where((a) => a != e && a.hp > 0).firstOrNull;
          if (host != null) {
            host.shield += 2;
            host.conditions['Ospite'] = 2;
          }
        }
      }
      if (def.role == 'tank' || def.role == 'root') {
        player.conditions['Legato'] = 2;
      }
      if (def.role == 'guard') e.shield++;
      final allies = eyes
          .where((eye) => eye.summoned && eye.actor.hp > 0)
          .toList();
      final victim =
          allies.isNotEmpty &&
              rng.nextInt(100) < OculusRules.companionTargetChance
          ? allies[rng.nextInt(allies.length)].actor
          : player;
      final r = roll(e, 'volonta', e.name);
      final guard = roll(victim, 'materia', '${victim.name}: Difesa');
      final confused = e.conditions.containsKey('Confuso') ? 2 : 0;
      if (victim.conditions.remove('Schivata') != null ||
          r.total - confused < guard.total + victim.cm) {
        if (victim == player) adapt(def.family, handled: true);
        tickConditions(e);
        continue;
      }
      var amount =
          e.baseDamage + OculusRules.encounterPressure[difficulty.index];
      if (def.role == 'tank') amount = max(1, amount ~/ 2);
      if (def.role == 'assault') amount += 2;
      if (def.role == 'armed') amount += def.weapon == 'Ascia' ? 3 : 1;
      if (e.conditions.containsKey('Ospite') ||
          e.conditions.containsKey('Trasformato')) {
        amount += 2;
      }
      if (def.role == 'elk' &&
          (turn - 1) % (OculusRules.antlerCooldown + 1) == 0) {
        amount += OculusRules.antlerDamage;
      }
      final beam = def.role == 'beam' && turn % 2 == 1;
      final parried = victim.conditions.remove('Parata') != null;
      if (parried) {
        amount = max(0, amount - 2);
        adapt(def.family, handled: true);
      }
      final dealt = beam
          ? brainBeam(victim, amount, r.natural)
          : damage(victim, amount, def.family, ignoreDefense: false);
      if (dealt > 0 && victim == player) {
        flags.add('ferita:${def.family}');
        if (['Taglio', 'Perforazione'].contains(def.family)) {
          final protection =
              player.conditions.containsKey('Protezione Sanguinante')
              ? OculusRules.bleedProtection
              : 0;
          if (roll(player, 'resilienza', 'Resistere a Sanguinante').total +
                  protection <
              r.total) {
            player.conditions['Sanguinante'] = -1;
          }
        }
        if (def.role == 'burn') player.conditions['Brucia'] = 2;
        if (def.role == 'eiva') corruption++;
      }
      if (def.role == 'armed' && def.weapon == 'Lancia') {
        player.conditions['Legato'] = 2;
      }
      tickConditions(e);
    }
    if (player.conditions.containsKey('Sanguinante')) {
      player.hp = max(0, player.hp - OculusRules.bleedDamage);
    }
    if (player.conditions.containsKey('Brucia')) {
      player.hp = max(0, player.hp - 1);
    }
    tickConditions(player);
    player.cm = 0;
  }

  void tickConditions(HeroActor actor) {
    for (final key in actor.conditions.keys.toList()) {
      if ([
        'Protezione Sanguinante',
        'Bendato',
        'Preparato',
        'Fuga',
      ].contains(key)) {
        continue;
      }
      if (actor.conditions[key]! > 0) {
        actor.conditions[key] = actor.conditions[key]! - 1;
        if (actor.conditions[key] == 0) actor.conditions.remove(key);
      }
    }
  }

  bool rewind() {
    if (finished || actionSnapshot == null || player.inspirations[0] <= 0) {
      return false;
    }
    final currentRng = rng.state;
    final spent = player.inspirations[0] - 1;
    final restored = HeroRun.fromJson(actionSnapshot!);
    player = restored.player;
    player.inspirations[0] = min(spent, player.inspirations[0]);
    enemies = restored.enemies;
    eyes = restored.eyes;
    turn = restored.turn;
    actionsLeft = restored.actionsLeft;
    cardsPlayed = restored.cardsPlayed;
    cooldowns = restored.cooldowns;
    adaptation = restored.adaptation;
    adaptationSamples = restored.adaptationSamples;
    flags = restored.flags;
    tags = restored.tags;
    inventory = restored.inventory;
    weapon = restored.weapon;
    weaponBonus = restored.weaponBonus;
    foodBonuses = restored.foodBonuses;
    corruption = restored.corruption;
    madness = restored.madness;
    rng.state = currentRng;
    actionSnapshot = null;
    pendingVictory = false;
    pendingEscape = false;
    pendingDeath = false;
    rolls.clear();
    note(
      'Ispirazione consumata. L’ultima azione è annullata: puoi ritentarla.',
    );
    return true;
  }

  bool escape() {
    if (!inCombat ||
        pendingDeath ||
        pendingVictory ||
        pendingEscape ||
        finished) {
      return false;
    }
    captureAction('escape');
    actionsLeft--;
    final bonus =
        (inventory['Stivali da fuga'] ?? 0) +
        (hasTitle('escape') ? 1 : 0) +
        (player.conditions['Fuga'] ?? 0);
    final target =
        OculusRules.escapeTarget[difficulty.index] +
        (player.conditions.containsKey('Legato') ? 4 : 0) +
        (enemies.any((e) => monster(e.id).role == 'assault') ? 2 : 0);
    if (roll(player, 'materia', 'Fuga').total + bonus >= target) {
      pendingEscape = true;
      note('Hai trovato un varco. Conferma la fuga o usa Ispirazione.');
    } else {
      endTurn(preserveSnapshot: true);
      pendingDeath = player.hp <= 0;
      note('La via si chiude. Devi tentare ancora.');
    }
    return pendingEscape;
  }

  void settleCombat() {
    if ((!pendingVictory && !pendingEscape) || pendingDeath) return;
    actionSnapshot = null;
    if (pendingEscape) {
      avoided++;
      note('Ti lasci il combattimento alle spalle.');
    } else {
      for (final e in enemies) {
        kills++;
        if (e.id == 'alce') inventory['Corna dell’Alce Cieco'] = 1;
        if (e.id == 'eiva') {
          flags.add('eiva_caduta');
          completeQuest('eiva', 'La fonte spezzata');
          achievements.add('eiva');
        }
      }
      if (hunt == 'Foresta') {
        inventory.update('Carne', (n) => n + 2, ifAbsent: () => 2);
        inventory.update('Erbe', (n) => n + 1, ifAbsent: () => 1);
      } else {
        obser +=
            OculusRules.fightReward[difficulty.index] +
            (hunt == 'Villaggio' && hasTitle('trade') ? 1 : 0);
      }
      note('La strada è libera. Le ricompense sono nella borsa.');
      if (rng.nextInt(100) < OculusRules.captureChance) {
        obtainEye(source: enemies.first);
      }
      if (rng.nextInt(100) < 30) dust++;
      if (location == 'Dungeon' &&
          rng.nextInt(100) < (heroScenarioProfiles[scenario]?.$3 ?? 0)) {
        addOre();
      }
      if (kills % 2 == 0) player.levelUp();
      if (kills == 1 && !cards.containsKey('slancio')) {
        cards['slancio'] = 0;
        note('$text Carta ottenuta: Slancio Oltre il Limite (+2 azioni).');
      } else if (kills % (mode == HeroMode.roguelite ? 2 : 3) == 0) {
        offerCards();
      }
      if (kills %
              (mode == HeroMode.roguelite ? 3 : OculusRules.titleInterval) ==
          0) {
        offerTitles();
      }
      if (kills >= 1) achievements.add('prima_vittoria');
      if (kills >= 6) flags.add('landa_aperta');
    }
    enemies.clear();
    hunt = '';
    pendingVictory = false;
    pendingEscape = false;
    refreshSkillAchievements();
  }

  bool resolveDeath() {
    if (!pendingDeath || finished) return false;
    actionSnapshot = null;
    rolls.clear();
    if (player.kind != EntityKind.player) {
      finish(selectEnding());
      return false;
    }
    final r = roll(
      player,
      'volonta',
      'Tiro contro la morte',
      naturalOnly: true,
    );
    if (!OculusRules.deathSuccess(player.kind, difficulty, r.natural)) {
      finish(selectEnding());
      return false;
    }
    final medicine =
        roll(player, 'materia', 'Medicina').total +
        (hasTitle('medicine') ? 1 : 0);
    final currentStats = {
      for (final k in OculusRules.stats) k: player.dice[k]! + player.stats[k]!,
    };
    player.hp = max(
      1,
      OculusRules.rebirthLife(difficulty, currentStats, medicine),
    );
    if (hasTitle('survivor')) player.shield++;
    pendingDeath = false;
    achievements.add('rinato');
    pendingVictory = enemies.isNotEmpty && enemies.every((e) => e.hp <= 0);
    note('Rinasci con ${player.hp} Vita. Il dado naturale era ${r.natural}.');
    return true;
  }

  String selectEnding() {
    if (flags.contains('eiva_caduta') && npcs['rosso'] == 'salvo') {
      return 'La città che ricorda';
    }
    if (mode == HeroMode.aging && forestSurvival) {
      return 'Le radici custodiscono il nome';
    }
    if (corruption >= 8 || (cup >= 3 && madness >= 5)) {
      return 'Un nuovo volto nella Follia';
    }
    if (eyes.any((e) => e.awakened) && flags.contains('verita')) {
      return 'L’Occhio oltre la morte';
    }
    if (npcs['campanaro'] == 'salvo' && destiny > 1) {
      return 'La campana tace per te';
    }
    if (avoided > kills && titles.isNotEmpty) {
      return 'Nessuno vide il tuo passaggio';
    }
    if (completedQuests.containsKey('guida') &&
        achievements.contains('prima_quest')) {
      return 'Qualcuno ti aspetta alla porta';
    }
    if (location == 'Landa Nera' && flags.contains('colonia')) {
      return 'Una voce nella colonia';
    }
    return 'Il sentiero conserva le impronte';
  }

  void finish(String result) {
    finished = true;
    pendingDeath = false;
    ending = result;
    achievements.add('prima_morte');
    note(result);
  }
}
