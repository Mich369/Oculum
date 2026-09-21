part of 'hero_engine.dart';

extension HeroSave on HeroRun {
  Map<String, dynamic> toJson({bool includeSnapshot = true}) => {
    ...legacy,
    'schema': 1,
    'seed': seed,
    'rng': rng.state,
    'player': player.toJson(),
    'difficulty': difficulty.name,
    'mode': mode.name,
    'actionsLeft': actionsLeft,
    'cardsPlayed': cardsPlayed,
    'scene': scene,
    'turn': turn,
    'obser': obser,
    'dust': dust,
    'madness': madness,
    'corruption': corruption,
    'destiny': destiny,
    'cup': cup,
    'forestDays': forestDays,
    'avoided': avoided,
    'kills': kills,
    'weaponBonus': weaponBonus,
    'titleMissions': titleMissions,
    'location': location,
    'scenario': scenario,
    'eventId': eventId,
    'text': text,
    'ending': ending,
    'hunt': hunt,
    'weapon': weapon,
    'finished': finished,
    'pendingDeath': pendingDeath,
    'pendingVictory': pendingVictory,
    'pendingEscape': pendingEscape,
    'enemies': enemies.map((e) => e.toJson()).toList(),
    'artSkills': artSkills,
    'titles': titles,
    'titleOffers': titleOffers,
    'cards': cards,
    'cardOffers': cardOffers,
    'importantNpcs': importantNpcs.map((k, v) => MapEntry(k, v.toJson())),
    'cooldowns': cooldowns,
    'inventory': inventory,
    'eventHistory': eventHistory,
    'foodBonuses': foodBonuses,
    'adaptationSamples': adaptationSamples,
    'quests': quests,
    'questStarted': questStarted,
    'questHistory': questHistory,
    'completedQuests': completedQuests,
    'npcs': npcs,
    'flags': flags.toList(),
    'achievements': achievements.toList(),
    'tags': tags.toList(),
    'adaptation': adaptation,
    'eyes': eyes.map((e) => e.toJson()).toList(),
    'rolls': rolls.map((r) => r.toJson()).toList(),
    'journal': journal,
    if (includeSnapshot) 'actionSnapshot': actionSnapshot,
    'lastAction': lastAction,
  };
}

HeroRun restoreHeroRun(Map<String, dynamic> d) {
  final r = HeroRun(
    seed: heroInt(d['seed'], 1),
    name:
        '${heroMap(d['player'])['name'] ?? d['playerNameInRun'] ?? 'Senza nome'}',
    difficulty: HeroDifficulty.values.firstWhere(
      (e) => e.name == d['difficulty'],
      orElse: () => HeroDifficulty.medium,
    ),
    mode: HeroMode.values.firstWhere(
      (e) => e.name == d['mode'],
      orElse: () => HeroMode.normal,
    ),
    art: heroStrings(d['artSkills']),
  );
  r.legacy = {...d}..remove('actionSnapshot');
  // Saved Art and owned cards predate unlock requirements and remain usable.
  r.artSkills = heroStrings(d['artSkills']);
  r.rng.state = heroInt(d['rng'], r.seed);
  if (r.rng.state <= 0 || r.rng.state >= 2147483647) r.rng = HeroRandom(r.seed);
  if (d['player'] is Map) r.player = HeroActor.fromJson(heroMap(d['player']));
  r.actionsLeft = heroInt(
    d['actionsLeft'],
    OculusRules.baseActions,
  ).clamp(0, OculusRules.maxActions);
  r.cardsPlayed = max(0, heroInt(d['cardsPlayed']));
  r.scene = max(0, heroInt(d['scene'], heroInt(d['room'])));
  r.turn = max(0, heroInt(d['turn']));
  r.obser = max(0, heroInt(d['obser'], 8));
  r.dust = max(0, heroInt(d['dust'], heroInt(d['ascensionDust'])));
  r.madness = max(0, heroInt(d['madness']));
  r.corruption = max(0, heroInt(d['corruption']));
  r.destiny = heroInt(d['destiny']);
  r.cup = max(0, heroInt(d['cup']));
  r.forestDays = max(0, heroInt(d['forestDays']));
  r.avoided = max(0, heroInt(d['avoided']));
  r.kills = max(0, heroInt(d['kills']));
  r.weaponBonus = max(0, heroInt(d['weaponBonus']));
  r.titleMissions = max(0, heroInt(d['titleMissions']));
  r.location = '${d['location'] ?? 'Villaggio'}';
  r.scenario = '${d['scenario'] ?? ''}';
  r.eventId = '${d['eventId'] ?? ''}';
  if (!heroEvents.any((e) => e.id == r.eventId)) r.eventId = '';
  r.text = '${d['text'] ?? r.text}';
  r.ending = '${d['ending'] ?? ''}';
  r.hunt = '${d['hunt'] ?? ''}';
  r.weapon = '${d['weapon'] ?? r.weapon}';
  r.finished = d['finished'] == true;
  r.pendingDeath = d['pendingDeath'] == true;
  r.pendingVictory = d['pendingVictory'] == true;
  r.pendingEscape = d['pendingEscape'] == true;
  r.enemies = (d['enemies'] as List? ?? [])
      .whereType<Map>()
      .map((e) => HeroActor.fromJson(heroMap(e)))
      .toList();
  r.titles = heroStrings(d['titles']);
  r.cardOffers = heroStrings(d['cardOffers']);
  r.importantNpcs = heroMap(
    d['importantNpcs'],
  ).map((k, v) => MapEntry(k, HeroActor.fromJson(heroMap(v))));
  r.titleOffers = heroStrings(d['titleOffers']);
  Map<String, int> numbers(String key) =>
      heroMap(d[key]).map((k, v) => MapEntry(k, heroInt(v)));
  Map<String, String> strings(String key) =>
      heroMap(d[key]).map((k, v) => MapEntry(k, '$v'));
  if (d['cards'] is Map) {
    r.cards = numbers('cards').map((k, v) => MapEntry(k, v.clamp(0, 3)));
  }
  r.cooldowns = numbers('cooldowns');
  if (d['inventory'] is Map) r.inventory = numbers('inventory');
  r.eventHistory = numbers('eventHistory');
  r.foodBonuses = numbers('foodBonuses');
  r.adaptationSamples = numbers('adaptationSamples');
  if (d['quests'] is Map) r.quests = strings('quests');
  r.completedQuests = strings('completedQuests');
  r.npcs = strings('npcs');
  r.flags = heroStrings(d['flags']).toSet();
  r.achievements = heroStrings(d['achievements']).toSet();
  r.tags = heroStrings(d['tags']).toSet();
  r.adaptation = heroMap(d['adaptation']).map(
    (k, v) => MapEntry(
      k,
      (v is num ? v.toDouble() : 0.0).clamp(0, OculusRules.adaptationCap),
    ),
  );
  r.eyes = (d['eyes'] as List? ?? d['fallenCompanions'] as List? ?? [])
      .whereType<Map>()
      .map((e) => HeroEye.fromJson(heroMap(e)))
      .toList();
  r.rolls = (d['rolls'] as List? ?? [])
      .whereType<Map>()
      .map((e) => HeroRoll.fromJson(heroMap(e)))
      .toList();
  r.journal = heroStrings(d['journal']);
  r.actionSnapshot = d['actionSnapshot'] is Map
      ? heroMap(d['actionSnapshot'])
      : null;
  r.lastAction = '${d['lastAction'] ?? ''}';
  r.questStarted = numbers('questStarted');
  r.questHistory = (d['questHistory'] as List? ?? [])
      .whereType<Map>()
      .map(heroMap)
      .toList();
  r.reconcileQuests();
  r.refreshSkillAchievements();
  r.cardOffers.removeWhere((id) => !heroSkillAvailable(id, r.achievements));
  return r;
}
