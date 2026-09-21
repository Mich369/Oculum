import 'dart:convert';
import 'dart:math';
import 'hero_content.dart';
import 'hero_models.dart';
import 'oculus_rules.dart';
export 'hero_content.dart';
export 'hero_models.dart';
export 'oculus_rules.dart';
part 'hero_combat.dart';
part 'hero_inventory.dart';
part 'hero_save.dart';
part 'hero_quests.dart';

class HeroRun {
  HeroRun({
    required this.seed,
    required String name,
    this.difficulty = HeroDifficulty.medium,
    this.mode = HeroMode.normal,
    List<String> art = const ['brace', 'argilla', 'aurora'],
    Set<String> meta = const {},
  }) : rng = HeroRandom(seed),
       player = HeroActor(id: 'player', name: name) {
    artSkills.addAll(
      art.where((id) => heroSkills.any((s) => s.id == id)).toSet().take(3),
    );
    for (final skill in heroSkills) {
      if (artSkills.length >= 3) break;
      if (!artSkills.contains(skill.id)) artSkills.add(skill.id);
    }
    for (final id in ['attack', 'defend', ...artSkills]) {
      cards[id] = 0;
    }
    achievements.addAll(meta);
    if (meta.contains('prima_morte')) flags.add('memoria');
    if (meta.contains('guida_salvata')) flags.add('sogno_aperto');
    quests['cammino'] = 'Scopri chi suona la campana sotto terra.';
    questStarted['cammino'] = 0;
    inventory.addAll({'Benda improvvisata': 2, 'Carne': 1});
    roll(player, 'resilienza', 'Primo respiro');
    text = 'La strada finisce davanti a tre sentieri. Nessuno porta a casa.';
  }
  int actionsLeft = OculusRules.baseActions, cardsPlayed = 0;
  final int seed;
  HeroRandom rng;
  HeroActor player;
  HeroDifficulty difficulty;
  HeroMode mode;
  int scene = 0,
      turn = 0,
      obser = 8,
      dust = 0,
      madness = 0,
      corruption = 0,
      destiny = 0,
      cup = 0,
      forestDays = 0,
      avoided = 0,
      kills = 0,
      weaponBonus = 0,
      titleMissions = 0;
  String location = 'Villaggio',
      scenario = '',
      eventId = '',
      text = '',
      ending = '',
      hunt = '',
      weapon = 'Lama semplice';
  bool finished = false,
      pendingDeath = false,
      pendingVictory = false,
      pendingEscape = false;
  List<HeroActor> enemies = [];
  Map<String, HeroActor> importantNpcs = {};
  List<String> cardOffers = [];
  List<String> artSkills = [], titles = [], titleOffers = [];
  Map<String, int> cards = {},
      cooldowns = {},
      inventory = {},
      eventHistory = {},
      foodBonuses = {},
      adaptationSamples = {};
  Map<String, String> quests = {}, completedQuests = {}, npcs = {};
  Map<String, int> questStarted = {};
  List<Map<String, dynamic>> questHistory = [];
  Set<String> flags = {}, achievements = {}, tags = {};
  Map<String, double> adaptation = {};
  List<HeroEye> eyes = [];
  List<HeroRoll> rolls = [];
  List<String> journal = [];
  Map<String, dynamic>? actionSnapshot;
  String lastAction = '';
  Map<String, dynamic> legacy = {};
  int get day => scene ~/ OculusRules.scenesPerDay;
  bool get night =>
      scene % OculusRules.scenesPerDay >= OculusRules.scenesPerDay ~/ 2;
  bool get inCombat => enemies.isNotEmpty && !finished;
  int get agePenalty =>
      mode == HeroMode.aging ? scene ~/ OculusRules.ageInterval : 0;
  bool get forestSurvival => flags.contains('forest_survival');
  List<String> get locations => [
    'Villaggio',
    'Foresta',
    'Dungeon',
    if (flags.contains('citta_aperta')) 'Città',
    if (flags.contains('landa_aperta') || hasTitle('path')) 'Landa Nera',
    if (flags.contains('sogno_aperto')) 'Giardino del Sogno',
  ];
  HeroEvent get event => heroEvents.firstWhere(
    (e) => e.id == eventId,
    orElse: () => heroEvents.last,
  );
  bool hasTitle(String effect) =>
      heroTitles.any((t) => titles.contains(t.id) && t.effect == effect);
  void note(String value) {
    text = value;
    journal.add(value);
    if (journal.length > 60) journal.removeAt(0);
  }

  int bonus(String stat) =>
      player.stats[stat]! +
      (foodBonuses[stat] ?? 0) +
      (foodBonuses['run_$stat'] ?? 0) -
      (stat == 'volonta' && player.conditions.containsKey('Confuso') ? 2 : 0) -
      (stat == 'materia' && player.conditions.containsKey('Infreddolito')
          ? 1
          : 0) -
      (stat == 'volonta' || stat == 'materia' ? agePenalty : 0) +
      (forestSurvival && stat == 'volonta'
          ? 5
          : forestSurvival && stat == 'materia'
          ? 3
          : 0);
  HeroRoll roll(
    HeroActor actor,
    String stat,
    String label, {
    bool naturalOnly = false,
  }) {
    final r = HeroRoll(
      label,
      actor.dice[stat]!,
      rng.die(actor.dice[stat]!),
      naturalOnly ? 0 : actor.powerDie,
      naturalOnly ? 0 : rng.die(actor.powerDie),
      naturalOnly
          ? 0
          : actor == player
          ? bonus(stat)
          : actor.stats[stat]!,
    );
    rolls.add(r);
    if (rolls.length > 8) rolls.removeAt(0);
    return r;
  }

  int eventWeight(HeroEvent e) {
    if ([
          'mappa_viandante',
          'tracce_citta',
          'eco_campana',
          'tracce_campana',
          'residuo_eiva',
          'ritorno_memoria',
          'sigillo_eiva',
        ].contains(e.id) &&
        !quests.containsKey(e.id)) {
      return 0;
    }
    if (e.id == 'fonte_eiva' && !quests.containsKey('eiva')) return 0;
    if (e.id == 'viandante' && flags.contains('viandante_salvo')) return 0;
    if (e.id == 'quest_campana' && flags.contains('campana_cercata')) return 0;
    if (e.locations.isNotEmpty && !e.locations.contains(location)) return 0;
    if (e.requiredFlag.isNotEmpty && !flags.contains(e.requiredFlag)) return 0;
    if (e.excludedFlag.isNotEmpty && flags.contains(e.excludedFlag)) return 0;
    if (eventHistory.containsKey(e.id) &&
        scene - eventHistory[e.id]! < e.cooldown) {
      return 0;
    }
    var weight = e.weight;
    if (location == 'Dungeon' && heroScenarioProfiles[scenario]?.$2 == e.tag) {
      weight += OculusRules.scenarioEventBoost;
    }
    if (e.tag == 'madness') weight += madness * 3;
    if (e.tag == 'cup') weight += cup * 2;
    if (e.tag == 'npc') {
      weight += max(0, destiny) + (hasTitle('light') ? 10 : 0);
    }
    if (e.tag == 'quest' && quests.isNotEmpty) weight += 8;
    if (e.tag == 'rest' && player.conditions.isNotEmpty) weight += 8;
    if (e.tag == 'ore' && ['miniere', 'grotte'].contains(scenario)) {
      weight += 30;
    }
    if (e.tag == 'corruption') weight += corruption * 3;
    if (e.tag == 'eye' && completedQuests.isNotEmpty) weight += 5;
    if (e.tag == 'meta' && achievements.isNotEmpty) weight += 5;
    if (e.tag == 'combat' && tags.contains('rumoroso')) weight += 10;
    return weight;
  }

  bool travel(String destination) {
    if (cardOffers.isNotEmpty) return false;
    if (finished ||
        pendingDeath ||
        inCombat ||
        eventId.isNotEmpty ||
        titleOffers.isNotEmpty ||
        !locations.contains(destination)) {
      return false;
    }
    location = destination;
    nextScene();
    return true;
  }

  void nextScene() {
    reconcileQuests();
    if (cardOffers.isNotEmpty) return;
    if (finished ||
        pendingDeath ||
        inCombat ||
        titleOffers.isNotEmpty ||
        eventId.isNotEmpty) {
      return;
    }
    actionSnapshot = null;
    pendingVictory = false;
    pendingEscape = false;
    final oldDay = day;
    scene++;
    turn = 0;
    adaptationSamples.clear();
    cooldowns.clear();
    player.cm = 0;
    tags.remove('rumoroso');
    player.conditions.remove('Infreddolito');
    if (day != oldDay) foodBonuses.removeWhere((k, _) => !k.startsWith('run_'));
    for (final key in ['Protezione Sanguinante']) {
      if ((player.conditions[key] ?? 0) > 0) {
        player.conditions[key] = player.conditions[key]! - 1;
        if (player.conditions[key] == 0) player.conditions.remove(key);
      }
    }
    if (player.conditions.containsKey('Sanguinante')) {
      player.hp = max(0, player.hp - OculusRules.bleedDamage);
    }
    if (mode == HeroMode.aging && scene % OculusRules.ageInterval == 0) {
      player.volonta = max(0, player.volonta - 1);
      player.materia = max(0, player.materia - 1);
    }
    if (mode == HeroMode.aging && scene >= OculusRules.oldAgeScene) {
      finish('La lunga veglia');
      return;
    }
    if (player.hp <= 0) {
      pendingDeath = true;
      return;
    }
    if (location == 'Foresta') {
      forestDays++;
      if (mode == HeroMode.aging && forestDays >= OculusRules.forestUnlock) {
        flags.add('forest_survival');
      }
    }
    if (location == 'Landa Nera' && quests.containsKey('ombra')) {
      completeQuest('ombra', 'Hai raggiunto la tua ombra');
      flags.add('sogno_aperto');
    }
    if (location == 'Giardino del Sogno') {
      if (quests.containsKey('vena')) {
        completeQuest('vena', 'Il giardino ricorda');
      }
      if (quests.containsKey('memoria') && eyes.isNotEmpty) {
        completeQuest('memoria', 'Un Occhio ricorda per te');
        flags.add('verita');
      }
    }
    tags
      ..removeWhere((t) => t.startsWith('luogo:'))
      ..add('luogo:$location');
    if (location == 'Dungeon') {
      scenario = dungeonScenarios.keys.elementAt(
        rng.nextInt(dungeonScenarios.length),
      );
    }
    final requiredEvent = dueQuestEvent;
    if (location == 'Villaggio' && requiredEvent == null) {
      eventId = '';
      note(
        'Il fumo della taverna copre l’odore della strada. Qualcuno ti tiene d’occhio.',
      );
      return;
    }
    final e = requiredEvent == null
        ? rng.weighted(heroEvents, eventWeight)
        : heroEvents.firstWhere((e) => e.id == requiredEvent);
    eventId = e.id;
    eventHistory[e.id] = scene;
    note(
      '${location == 'Dungeon'
          ? '${dungeonScenarios[scenario]}\n'
          : location == 'Landa Nera'
          ? 'Terra nera, tronchi bianchi, foglie di sangue.\n'
          : ''}${e.text}',
    );
    if (location == 'Foresta' &&
        rng.nextInt(100) <
            max(0, 20 - forestDays - (hasTitle('forest') ? 5 : 0))) {
      player.conditions['Infreddolito'] = 1;
      note('$text Il freddo ti irrigidisce.');
    }
  }

  void villageEvent() {
    if (inCombat ||
        finished ||
        pendingDeath ||
        location != 'Villaggio' ||
        eventId.isNotEmpty) {
      return;
    }
    final e = rng.weighted(heroEvents, eventWeight);
    eventId = e.id;
    eventHistory[e.id] = scene;
    note(e.text);
  }

  void choose(int choice) {
    if (finished ||
        pendingDeath ||
        inCombat ||
        eventId.isEmpty ||
        choice < 0 ||
        choice >= event.choices.length) {
      return;
    }
    final id = eventId;
    if (['viandante', 'campanaro', 'rosso'].contains(id)) {
      importantNpcs.putIfAbsent(
        id,
        () => HeroActor(id: id, name: id, kind: EntityKind.npc),
      );
    }
    eventId = '';
    actionSnapshot = null;
    if (resolveQuestEvent(id, choice)) {
      reconcileQuests();
      return;
    }
    switch (id) {
      case 'viandante':
        if (choice == 0) {
          flags.add('viandante_salvo');
          npcs['viandante'] = 'salvo';
          quests['guida'] = 'Ritrova il viandante lungo la strada.';
          destiny++;
          note('Lo liberi. «Se arrivo alla città, ti aspetto.»');
        } else if (choice == 1) {
          flags.add('viandante_morto');
          npcs['viandante'] = 'morto';
          obser += 5;
          destiny--;
          note('La borsa pesa poco. Il silenzio, di più.');
        } else {
          note('Lasci il carro alle tue spalle.');
        }
      case 'ritorno':
        if (choice == 1) {
          flags.add('viandante_partito');
          note(
            'Il viandante parte prima del tramonto. La sua mappa è ancora qui.',
          );
          break;
        }
        flags.add('citta_aperta');
        completeQuest('guida', 'La porta senza guardie');
        achievements.add('guida_salvata');
        note('Il viandante ti indica la Città. Ora conosci la strada.');
      case 'colonia':
        flags.add('colonia');
        if (choice == 0) {
          encounter(forced: 'cervello', colony: true);
        } else {
          avoidEncounter('cervello');
        }
      case 'follia':
        if (choice == 0) {
          madness += 2;
          flags.add('landa_aperta');
          quests['ombra'] = 'Segui il tuo riflesso nella Landa.';
          encounter(
            forced: rng.nextInt(2) == 0 ? 'diverso_tank' : 'diverso_assalto',
          );
        } else if (choice == 1) {
          final r = roll(player, 'volonta', 'Resistere alla Follia');
          madness = max(0, madness + (r.total >= 6 ? -1 : 1));
          note('L’ombra torna ai tuoi piedi. Per ora.');
        } else {
          avoided++;
          madness++;
          note('Non ti volti più.');
        }
      case 'vena':
        if (choice == 0) {
          addOre();
          if (rng.nextInt(100) < 25) encounter();
        } else if (choice == 1) {
          flags.add('sogno_aperto');
          quests['vena'] = 'Trova il Giardino del Sogno.';
          note('La pietra pronuncia il nome di un giardino.');
        } else {
          note('Lasci la vena intatta.');
        }
      case 'tazza':
        if (choice == 0) {
          cup++;
          destiny += rng.nextInt(3) - 1;
          player.oculum = min(player.maxOculum, player.oculum + 3);
          madness++;
          note('La tazza era vuota. Eppure hai bevuto.');
        } else {
          destiny++;
          note('La vecchia annuisce, quasi sollevata.');
        }
      case 'altare':
        if (choice == 0) {
          obtainEye();
          corruption++;
        } else if (choice == 1 && obser > 0) {
          obser--;
          destiny++;
          dust++;
          note('La palpebra si chiude. Rimane una Dust.');
        } else {
          note('La pietra rimane immobile.');
        }
      case 'rosso':
        if (choice == 0) {
          if (hasTitle('red') || (inventory['Carne'] ?? 0) > 0) {
            inventory.update('Carne', (n) => max(0, n - 1), ifAbsent: () => 0);
            npcs['rosso'] = 'salvo';
            flags.add('fonte_eiva');
            quests['eiva'] = 'Spezza la fonte della corruzione.';
            destiny++;
            note('Il braccio tace. Ti indica la fonte dell’Eiva.');
          } else {
            encounter(forced: 'rosso');
          }
        } else if (choice == 1) {
          encounter(forced: 'rosso');
        } else {
          flags.add('fonte_eiva');
          quests['eiva'] = 'Spezza la fonte della corruzione.';
          encounter(forced: 'eiva');
        }
      case 'sogno':
        if (choice == 0) {
          flags.add('verita');
          completeQuest('vena', 'Il giardino ricorda');
          madness++;
          note('Il fuoco racconta la tua prima morte.');
        } else {
          madness = max(0, madness - 2);
          note('Il volto scompare con la fiamma.');
          flags.add('giardino_chiuso');
          flags.remove('sogno_aperto');
        }
      case 'memoria':
        if (choice == 0) {
          flags.add('sogno_aperto');
          dust++;
          quests['memoria'] = 'Porta un Occhio al Giardino del Sogno.';
          note('Oltre la porta senti il passo di una vita precedente.');
        } else {
          note('Conosci già il prezzo di quella porta.');
        }
      case 'bivio':
        flags.add('landa_aperta');
        if (choice == 0) location = 'Landa Nera';
        note('Segni il sentiero. Le foglie smettono di muoversi.');
      case 'quest_campana':
        if (choice == 0) {
          flags.add('campana_cercata');
          quests['campana'] = 'Trova il campanaro nel Dungeon o nella Landa.';
          note('Segui il suono. La corda pulsa.');
        } else if (choice == 1) {
          flags.add('campana_finita');
          corruption++;
          completedQuests['campana'] = 'La corda recisa';
          note('Il cielo smette di rispondere.');
        } else {
          replaceQuest(
            'cammino',
            'tracce_campana',
            'Cerca le tracce del campanaro nel Dungeon.',
            'Hai lasciato passare il richiamo della campana.',
          );
          note('La campana suona ancora.');
        }
      case 'campanaro':
        flags.add('campana_finita');
        flags.add('landa_aperta');
        if (choice == 0) {
          npcs['campanaro'] = 'salvo';
          destiny += 2;
          completeQuest('campana', 'Il cuore liberato');
          completeQuest('cammino', 'Il suono sotto terra');
        } else {
          npcs['campanaro'] = 'morto';
          corruption += 3;
          inventory['Cuore della campana'] = 1;
          completeQuest('campana', 'Il cuore rubato');
        }
        note('Il suono cessa. Nella Landa qualcuno ha ascoltato.');
      case 'riparo':
        if (choice == 0) {
          player.hp = min(player.maxHp, player.hp + 2);
          note('Dormi con un occhio aperto.');
        } else if (choice == 1) {
          inventory.update(
            'Benda improvvisata',
            (n) => n + 1,
            ifAbsent: () => 1,
          );
          note('Trovi stoffa pulita sotto il tavolo.');
        } else {
          note('La candela brucia alle tue spalle.');
        }
      default:
        if (choice == 1) {
          avoidEncounter(null);
        } else {
          if (choice == 2) tags.add('rumoroso');
          encounter();
        }
    }
    reconcileQuests();
  }

  void completeQuest(String id, String result) {
    if (completedQuests.containsKey(id) || !quests.containsKey(id)) return;
    quests.remove(id);
    completedQuests[id] = result;
    titleMissions++;
    player.titleLevel = min(12, titleMissions);
    dust += hasTitle('quest') ? 2 : 1;
    achievements.add('prima_quest');
  }

  HeroMonster monster(String id) => heroMonsters.firstWhere(
    (m) => m.id == id,
    orElse: () => heroMonsters.first,
  );
  HeroActor createEnemy(HeroMonster def) {
    final a = HeroActor(id: def.id, name: def.name, kind: EntityKind.monster)
      ..boss = def.boss
      ..miniBoss = def.mini;
    final target = def.role == 'eiva'
        ? 10
        : min(
            12,
            scene ~/ OculusRules.enemyTierScenes +
                (def.boss
                    ? 2
                    : def.mini
                    ? 1
                    : 0),
          );
    while (a.level < target) {
      a.levelUp();
    }
    if (def.boss) {
      while (a.dieSteps > 0 && a.dice['volonta']! < 20) {
        a.advanceDie('volonta');
      }
    }
    a.quickAllocate();
    if (def.role == 'tank') {
      a.stats['resilienza'] = a.stats['resilienza']! + 6;
      a.stats['materia'] = a.stats['materia']! + 3;
    }
    a.replenish();
    return a;
  }

  void encounter({String? forced, bool colony = false}) {
    if (finished || inCombat || pendingDeath) return;
    eventId = '';
    rolls.clear();
    final candidates = heroMonsters
        .where(
          (m) =>
              (m.locations.contains(location) ||
                  (location == 'Dungeon' &&
                      (heroScenarioProfiles[scenario]?.$1.contains(m.role) ??
                          false))) &&
              (m.id != 'capo_cervelli' || colony) &&
              (m.role != 'eiva' || flags.contains('fonte_eiva')),
        )
        .toList();
    final def = forced == null
        ? rng.weighted(
            candidates.isEmpty ? [heroMonsters.first] : candidates,
            (m) =>
                (location == 'Dungeon' &&
                        (heroScenarioProfiles[scenario]?.$1.contains(m.role) ??
                            false)
                    ? OculusRules.scenarioEventBoost
                    : 0) +
                (m.id.startsWith('diverso')
                    ? 1 + madness * 2
                    : m.boss
                    ? max(1, scene ~/ 12)
                    : 8),
          )
        : monster(forced);
    enemies = [createEnemy(def)];
    if (colony) {
      enemies.add(createEnemy(monster('cervello')));
      if (scene >= 12 || rng.nextInt(100) < 25) {
        enemies.add(createEnemy(monster('capo_cervelli')));
      }
    } else if (scene >= 18 && rng.nextInt(100) < 15 + difficulty.index * 5) {
      enemies.add(createEnemy(monster('ossa')));
    }
    player.shield = player.maxShield + (hasTitle('shield') ? 1 : 0);
    player.cm = 0;
    cooldowns.clear();
    turn = 0;
    actionsLeft = OculusRules.baseActions;
    cardsPlayed = 0;
    pendingVictory = false;
    pendingEscape = false;
    actionSnapshot = null;
    note('${def.name}. ${def.description}');
  }

  void avoidEncounter(String? forced) {
    final def = forced == null
        ? monster(location == 'Foresta' && madness > 0 ? 'alce' : 'lupo')
        : monster(forced);
    final quiet = hasTitle('quiet') || (inventory['Mantello silente'] ?? 0) > 0;
    final target =
        OculusRules.escapeTarget[difficulty.index] +
        (def.role == 'elk'
            ? (tags.contains('rumoroso')
                  ? 4
                  : player.oculum > 0
                  ? 2
                  : 0)
            : 0) -
        (quiet ? 2 : 0);
    if (roll(player, 'materia', 'Evitare ${def.name}').total >= target) {
      avoided++;
      destiny++;
      note('Trattieni il respiro. La creatura passa oltre.');
    } else {
      encounter(forced: def.id);
    }
  }

  void startHunt() {
    if (finished ||
        pendingDeath ||
        inCombat ||
        eventId.isNotEmpty ||
        !['Villaggio', 'Foresta'].contains(location)) {
      return;
    }
    hunt = location;
    encounter(forced: 'lupo');
  }

  factory HeroRun.fromJson(Map<String, dynamic> data) => restoreHeroRun(data);
}
