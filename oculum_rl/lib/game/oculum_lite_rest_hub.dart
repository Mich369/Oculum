part of 'oculum_lite_run.dart';

enum LiteRestStation {
  tavern('Taverniera', Point(9, 9)),
  forge('Fabbro', Point(15, 6.3)),
  merchant('Mercante', Point(16, 14)),
  seer('Veggente', Point(22, 9.8)),
  art('Istruttrice di Art', Point(23, 16.5));

  const LiteRestStation(this.label, this.position);
  final String label;
  final Point<double> position;
}

enum LiteRestItem {
  stufato(
    'Stufato di Brace',
    LiteRestStation.tavern,
    29,
    '+20% Danni con le armi per 3 piani.',
  ),
  crosta(
    'Crosta di Ferro',
    LiteRestStation.tavern,
    34,
    '−20% Danni subiti per 3 piani.',
  ),
  spiedino(
    'Spiedino d’Ossidiana',
    LiteRestStation.tavern,
    38,
    'Recuperi 18 Resistenza del blocco all’inizio dei prossimi 3 piani.',
  ),
  tisana(
    'Tisana dell’Iride',
    LiteRestStation.tavern,
    32,
    '+0,5 Oculum al secondo per 3 piani.',
  ),
  chakram(
    'Chakram d’Iridio',
    LiteRestStation.forge,
    60,
    'Si lancia e rientra. +9 Danni, 9 m, recupero 0,32 s.',
  ),
  falce(
    'Falce runica',
    LiteRestStation.forge,
    51,
    'Fendente ampio e lama richiamabile.',
  ),
  carabina(
    'Carabina a impulsi',
    LiteRestStation.forge,
    57,
    'Proiettile caricato che perfora.',
  ),
  lame(
    'Doppie lame',
    LiteRestStation.forge,
    48,
    'Due fendenti separati da uno spostamento.',
  ),
  picca(
    'Picca d’ossidiana',
    LiteRestStation.forge,
    49,
    'Affondo stretto da 4,3 m.',
  ),
  balestra(
    'Balestra runica',
    LiteRestStation.forge,
    62,
    'Quadrello runico da 11 m.',
  ),
  brace(
    'Pergamena Brace errante',
    LiteRestStation.merchant,
    19,
    'Una palla di fuoco che rimbalza.',
  ),
  faglia(
    'Pergamena Spaccaterra',
    LiteRestStation.merchant,
    23,
    'Una faglia lungo la linea di mira.',
  ),
  linfa(
    'Pergamena Linfa verde',
    LiteRestStation.merchant,
    21,
    'Cura il 20% della Vita e ripara il blocco.',
  ),
  falciLunari(
    'Pergamena Falci di Vaitern',
    LiteRestStation.merchant,
    31,
    'Lancia due falci lunari divergenti da 14 Danni ciascuna.',
  ),
  token(
    'Gettone di Rinascita',
    LiteRestStation.merchant,
    180,
    'Intercetta una morte e restituisce il 35% della Vita.',
  ),
  spirale(
    'Iride a spirale',
    LiteRestStation.merchant,
    56,
    'Scaglia una spirale di proiettili ogni 6 s. Migliorabile fino al rango III.',
  ),
  bastione(
    'Cuore di fucina',
    LiteRestStation.forge,
    45,
    'Inizia ogni piano con Scudo extra. Migliorabile fino al rango III.',
  ),
  tempra(
    'Tempra dell’arma',
    LiteRestStation.forge,
    17,
    '+4% Danni per rango. Crescono anche gli effetti della tecnica su G.',
  ),
  artPlasma(
    'Raggio al plasma',
    LiteRestStation.art,
    72,
    'Oculum Art · Raggio diritto a lunga portata.',
  ),
  artFalci(
    'Falci di Vaitern',
    LiteRestStation.art,
    62,
    'Oculum Art · Due falci divergenti.',
  ),
  artLinfa(
    'Linfa verde',
    LiteRestStation.art,
    56,
    'Oculum Art · Recupera Vita e resistenza del blocco.',
  ),
  artCorruzione(
    'Presa della Corruzione Rossa',
    LiteRestStation.art,
    94,
    'Defiled Art · Onda a cinque forme, stordisce i nemici comuni.',
  ),
  artBrace(
    'Incisione di brace',
    LiteRestStation.art,
    68,
    'Un ventaglio di braci che rimbalzano sulle pareti.',
  ),
  artBasalto(
    'Piega di basalto',
    LiteRestStation.art,
    74,
    'Spacca il terreno in linea e può rompere i ripari.',
  ),
  artEcoVelata(
    'Eco velata',
    LiteRestStation.art,
    82,
    'Evoca due copie d’ombra temporanee.',
  ),
  artPassoSenzaLuce(
    'Passo senza luce',
    LiteRestStation.art,
    66,
    'Scatto continuo con intangibilità.',
  ),
  artFiloOmbra(
    'Filo d’Ombra',
    LiteRestStation.art,
    96,
    'Raggio guidato dalla mira. Il lanciatore resta ancorato.',
  ),
  beccoCaverna(
    'Becco della Caverna',
    LiteRestStation.forge,
    53,
    'Picca di selce. La tecnica spinge lungo una stoccata stretta.',
  ),
  falceFunerys(
    'Falce di Funerys',
    LiteRestStation.forge,
    64,
    'Falce ossaria. La tecnica raccoglie e rallenta i nemici.',
  ),
  bobinaPostea(
    'Bobina di Postea',
    LiteRestStation.forge,
    67,
    'Scettro runico. La tecnica salta fra tre nemici senza oltrepassare i muri.',
  );

  const LiteRestItem(this.label, this.station, this.basePrice, this.effect);
  final String label, effect;
  final LiteRestStation station;
  final int basePrice;

  LiteLearnedArt? get art => switch (this) {
    artPlasma => LiteLearnedArt.plasma,
    artFalci => LiteLearnedArt.falci,
    artLinfa => LiteLearnedArt.linfa,
    artCorruzione => LiteLearnedArt.corruzione,
    artBrace => LiteLearnedArt.brace,
    artBasalto => LiteLearnedArt.basalto,
    artEcoVelata => LiteLearnedArt.ecoVelata,
    artPassoSenzaLuce => LiteLearnedArt.passoSenzaLuce,
    artFiloOmbra => LiteLearnedArt.filoOmbra,
    _ => null,
  };
  bool get meal => station == LiteRestStation.tavern;
  bool get evolution => this == spirale || this == bastione;
  LiteWeapon? get weapon => switch (this) {
    chakram => LiteWeapon.chakram,
    falce => LiteWeapon.falceRunica,
    carabina => LiteWeapon.carabinaImpulsi,
    lame => LiteWeapon.doppieLame,
    picca => LiteWeapon.piccaOssidiana,
    balestra => LiteWeapon.balestraRunica,
    beccoCaverna => LiteWeapon.beccoCaverna,
    falceFunerys => LiteWeapon.falceFunerys,
    bobinaPostea => LiteWeapon.bobinaPostea,
    _ => null,
  };
  LiteScroll? get scroll => switch (this) {
    brace => LiteScroll.braceErrante,
    faglia => LiteScroll.spaccaterra,
    linfa => LiteScroll.linfaVerde,
    falciLunari => LiteScroll.falciLunari,
    _ => null,
  };
}

class LiteRestMemory {
  const LiteRestMemory(this.id, this.item, this.rank);
  final String id;
  final LiteRestItem item;
  final int rank;
  List<Object> get frame => [id, item.name, rank];

  static LiteRestMemory? read(Object? value) {
    if (value is! List || value.length != 3 || value[0] is! String) return null;
    final item = LiteRestItem.values
        .where((item) => item.name == value[1])
        .firstOrNull;
    return item == null
        ? null
        : LiteRestMemory(
            value[0] as String,
            item,
            _int(value[2], 1).clamp(1, 3),
          );
  }
}

class LiteRestLoadout {
  final _foodUntil = <LiteRestItem, int>{};
  final _evolutions = <LiteRestItem, int>{};
  final _receipts = <LiteRestItem, int>{};
  final scrolls = <LiteScroll, int>{};
  final _forgeRanks = <LiteWeapon, int>{};
  LiteWeaponFusion? _fusion;
  LiteVampirePact? vampirePact;
  LiteReysercthMod? reysercthMod;
  double get _reysercthLifeScale =>
      reysercthMod == null ? 1 : LiteReysercthMod.vitality;
  double get _reysercthWeaponScale =>
      reysercthMod == null ? 1 : LiteReysercthMod.power;
  int? _petTradeStage;
  double get _vampireLifeScale => vampirePact == null ? 1 : .65;
  double get _vampireMoveScale =>
      vampirePact == LiteVampirePact.passo ? 1.45 : 1;
  int lusierCards = 12;
  double _lusierRecharge = 0;
  LiteLearnedArt? art;
  final _learnedArts = <LiteLearnedArt>{};
  List<LiteGrimoireAction?>? _grimoireSlots;
  Set<LiteLearnedArt> get knownArts => Set.unmodifiable(_learnedArts);
  final _artTraining = <LiteLearnedArt, int>{};
  int artTraining(LiteLearnedArt art) => _artTraining[art] ?? 0;
  int artRank(LiteLearnedArt art, int level) =>
      min(art.maxRank, art.rankAt(level) + artTraining(art));
  double artRecovery(LiteLearnedArt art) =>
      art.cooldown * (1 - .10 * artTraining(art));
  bool hasGrimoire = false;
  bool knowsArt(LiteLearnedArt entry) =>
      _learnedArts.contains(entry) || art == entry;
  double artCooldown = 0;
  double extraArtCooldown = 0;
  bool emberSpent = false;
  double emberCooldown = 0;
  int forgeRank(LiteWeapon item) => _forgeRanks[item] ?? 0;
  Iterable<LiteRestItem> get receipts => _receipts.keys;
  int rank(LiteRestItem item) => _evolutions[item] ?? 0;
  bool fed(LiteRestItem item, int stage) => stage <= (_foodUntil[item] ?? -1);
  bool token = false;
  int lunarPieces = 0;
  double _spiralTime = 0;
  double _spin = 0;
  LiteRestMemory? promised;
  String? carriedId;
  bool get active =>
      token ||
      lunarPieces > 0 ||
      _foodUntil.isNotEmpty ||
      _evolutions.isNotEmpty ||
      _receipts.isNotEmpty ||
      _forgeRanks.isNotEmpty ||
      _fusion != null ||
      vampirePact != null ||
      reysercthMod != null ||
      _petTradeStage != null ||
      lusierCards < 12 ||
      hasGrimoire ||
      _grimoireSlots != null ||
      art != null ||
      emberSpent ||
      emberCooldown > 0 ||
      scrolls.isNotEmpty ||
      promised != null ||
      carriedId != null;

  Map<String, Object> get frame => {
    if (token) 'token': true,
    if (emberSpent) 'emberSpent': true,
    if (emberCooldown > 0) 'emberCooldown': emberCooldown,
    if (hasGrimoire || art != null) 'grimoire': true,
    if (_learnedArts.isNotEmpty)
      'learnedArts': _learnedArts.map((entry) => entry.name).toList(),
    if (art case final learned?) 'chosenArt': learned.name,
    if (_grimoireSlots case final slots?)
      'grimoireSlots': slots.map((action) => action?.key).toList(),
    if (_artTraining.isNotEmpty)
      'artTraining': _artTraining.map((art, rank) => MapEntry(art.name, rank)),
    if (artCooldown > 0) 'artCooldown': artCooldown,
    if (extraArtCooldown > 0) 'extraArtCooldown': extraArtCooldown,
    if (lunarPieces > 0) 'lunarPieces': lunarPieces,
    if (_foodUntil.isNotEmpty)
      'meals': _foodUntil.map((key, value) => MapEntry(key.name, value)),
    if (_evolutions.isNotEmpty)
      'evolutions': _evolutions.map((key, value) => MapEntry(key.name, value)),
    if (_receipts.isNotEmpty)
      'receipts': _receipts.map((key, value) => MapEntry(key.name, value)),
    if (_fusion case final pair?) 'fusion': pair.frame,
    if (vampirePact case final pact?) 'vampirePact': pact.name,
    if (reysercthMod case final upgrade?) 'reysercthMod': upgrade.name,
    if (_petTradeStage case final floor?) 'petTradeStage': floor,
    if (lusierCards < 12) 'lusierCards': [lusierCards, _lusierRecharge],
    if (_forgeRanks.isNotEmpty)
      'forge': _forgeRanks.map((weapon, rank) => MapEntry(weapon.name, rank)),
    if (scrolls.isNotEmpty)
      'scrolls': scrolls.map((key, value) => MapEntry(key.name, value)),
    if (_spiralTime > 0) 'spiral': [_spiralTime, _spin],
    if (promised case final memory?) 'promised': memory.frame,
    if (carriedId case final id?) 'carriedId': id,
  };

  void restore(Object? data) {
    if (data is! Map) return;
    token = data['token'] == true;
    reysercthMod = LiteReysercthMod.values
        .where((choice) => choice.name == data['reysercthMod'])
        .firstOrNull;
    _petTradeStage = data['petTradeStage'] is int
        ? data['petTradeStage'] as int
        : null;
    emberSpent = data['emberSpent'] == true;
    emberCooldown = _num(data['emberCooldown']).clamp(0, 1.45);
    art = LiteLearnedArt.values
        .where((entry) => entry.name == data['chosenArt'])
        .firstOrNull;
    hasGrimoire = data['grimoire'] == true || art != null;
    _learnedArts.clear();
    final slots = _list(data['grimoireSlots']);
    _grimoireSlots = slots.length == _grimoireSlotCount
        ? slots.map(LiteGrimoireAction.tryRead).toList()
        : null;
    if (hasGrimoire) {
      final names = _list(data['learnedArts']);
      _learnedArts.addAll(
        LiteLearnedArt.values.where(
          (entry) =>
              names.contains(entry.name) &&
              LiteRestItem.values.any((item) => item.art == entry),
        ),
      );
      if (art case final chosen?) _learnedArts.add(chosen);
    }
    _artTraining.clear();
    if (data['artTraining'] case final Map ranks) {
      for (final spell in LiteLearnedArt.values.where(knowsArt)) {
        final rank = _int(ranks[spell.name]).clamp(0, 2);
        if (rank > 0) _artTraining[spell] = rank;
      }
    }
    artCooldown = _num(data['artCooldown']).clamp(0, 8);
    extraArtCooldown = _num(data['extraArtCooldown']).clamp(0, 8);
    lunarPieces = _int(data['lunarPieces']).clamp(0, 255);
    void read(String key, Map<LiteRestItem, int> map, int maximum) {
      final values = data[key];
      if (values is! Map) return;
      for (final item in LiteRestItem.values) {
        if (values[item.name] case final int value when value >= 0) {
          map[item] = value.clamp(0, maximum);
        }
      }
    }

    read('meals', _foodUntil, LiteRun.finalStage + 3);
    read('evolutions', _evolutions, 3);
    read('receipts', _receipts, 3);
    _fusion = LiteWeaponFusion.read(data['fusion']);
    vampirePact = LiteVampirePact.values
        .where((choice) => choice.name == data['vampirePact'])
        .firstOrNull;
    if (data['lusierCards'] case final List cards when cards.length == 2) {
      lusierCards = _int(cards[0]).clamp(0, 12);
      _lusierRecharge = _num(cards[1]).clamp(0, 1);
    }
    if (data['forge'] case final Map ranks) {
      for (final weapon in LiteWeapon.values) {
        final rank = _int(ranks[weapon.name]).clamp(0, 12);
        if (rank > 0) _forgeRanks[weapon] = rank;
      }
    }
    if (data['scrolls'] case final Map counts) {
      for (final type in LiteScroll.values) {
        final count = _int(counts[type.name]).clamp(0, 99);
        if (count > 0) scrolls[type] = count;
      }
    }
    if (data['spiral'] case final List phase when phase.length == 2) {
      _spiralTime = _num(phase[0]).clamp(0, 6);
      _spin = _num(phase[1]) % (2 * pi);
    }
    promised = LiteRestMemory.read(data['promised']);
    if (data['carriedId'] case final String id) carriedId = id;
  }
}

extension LiteRestHub on LiteRun {
  static const memoryPrice = 72;
  static const grimoirePrice = 24;
  static const tutorDiscountPercent = 20;

  Iterable<LiteRestStation> get restStations =>
      (restHub ? LiteRestStation.values : explorationStations).where(
        (station) => station != LiteRestStation.art || artDealerOpen,
      );

  bool canUseRestStation(LiteRestStation station, [LiteCoopFighter? fighter]) =>
      !finished &&
      (fighter?.hp ?? hp) > 0 &&
      restStations.contains(station) &&
      (restHub || restStationNearby(fighter) == station);

  LiteRestStation? restStationNearby([LiteCoopFighter? fighter]) {
    if (finished || (fighter?.hp ?? hp) <= 0) return null;
    final at = fighter?.position ?? position;
    LiteRestStation? nearest;
    var distance = 2.25;
    for (final station in restStations) {
      final remaining = at.distanceTo(restStationPoint(station));
      if (remaining >= distance) continue;
      nearest = station;
      distance = remaining;
    }
    return nearest;
  }

  bool get partyHasSmith =>
      hero == LiteHero.fabbro ||
      coopFighters.any(
        (fighter) => fighter.connected && fighter.hero == LiteHero.fabbro,
      );

  String restStationName(LiteRestStation station) => switch (station) {
    LiteRestStation.forge when partyHasSmith => 'Forgia',
    LiteRestStation.art when devilArtTutor => 'Istruttore di Art',
    LiteRestStation.art when usesExplorableFloor => 'Pittrice di Art',
    _ => station.label,
  };

  bool get devilArtTutor {
    final random = _LiteRandom(seed ^ (stage * 10037) ^ 0x2f861);
    random.nextDouble();
    return random.nextInt(100) < 12;
  }

  bool hasTutorDiscount([LiteCoopFighter? fighter]) =>
      switch (fighter?.hero ?? hero) {
        LiteHero.cavaliereLunare ||
        LiteHero.lupoDiVaitern ||
        LiteHero.demoneMinore ||
        LiteHero.demoneIntermedio ||
        LiteHero.demoneMaggiore ||
        LiteHero.diavolo => true,
        _ => false,
      };
  bool get awaitsRestHub =>
      stageClear && !usesSubArena && stage < lastStage && (stage + 1) % 6 == 0;
  bool get hubGoblin => (seed ^ stage * 7283).isOdd;

  bool enterRestHub() {
    if (!awaitsRestHub || !hasPortalNearby || finished || shopOpen || hostDown)
      return false;
    _noteFaunaCleared();
    _openSupplyRoom();
    return true;
  }

  void _openSupplyRoom() {
    _clearArenaActions();
    _dismissRoomWolves();
    restHub = true;
    fauna.clear();
    obstacles.clear();
    groundShots.clear();
    projectiles.clear();
    _combatImpacts.clear();
    position = LiteRun._spawn;
    restUsed = false;
    supply._receipts.clear();
    supply.promised = null;
    for (var i = 0; i < coopFighters.length; i++) {
      final fighter = coopFighters[i];
      fighter.position = _coopSpawn(i);
      fighter.restUsed = false;
      fighter.supply._receipts.clear();
      fighter.supply.promised = null;
    }
    message = 'Sala di ristoro · Botteghe aperte.';
  }

  int restPrice(LiteRestItem item, {LiteCoopFighter? fighter}) {
    final kit = fighter?.supply ?? supply;
    if (item.art case final art?) {
      final price = kit.knowsArt(art)
          ? (item.basePrice * .64).ceil() + kit.artTraining(art) * 26
          : item.basePrice + (kit.hasGrimoire ? 0 : grimoirePrice);
      return hasTutorDiscount(fighter)
          ? (price * (100 - tutorDiscountPercent) / 100).round()
          : price;
    }
    if (item == LiteRestItem.tempra) {
      return item.basePrice + kit.forgeRank(fighter?.weapon ?? weapon) * 5;
    }
    return item.basePrice + (item.evolution ? kit.rank(item) * 28 : 0);
  }

  bool canBuyRestItem(LiteRestItem item, {LiteCoopFighter? fighter}) {
    if (!canUseRestStation(item.station, fighter) ||
        (fighter?.obser ?? obser) < restPrice(item, fighter: fighter))
      return false;
    final kit = fighter?.supply ?? supply;
    if (item.art case final art?) {
      return artDealerOpen &&
          (!kit.knowsArt(art) || kit.artTraining(art) < 2) &&
          (art != LiteLearnedArt.corruzione ||
              achievements.contains('baghest-sconfitto'));
    }
    if (item == LiteRestItem.tempra) {
      return hasWeaponArt(fighter) &&
          kit.forgeRank(fighter?.weapon ?? weapon) < 12;
    }
    if (item == LiteRestItem.token) return !kit.token;
    if (item.evolution) return kit.rank(item) < 3;
    if (item.meal) return !kit._receipts.containsKey(item);
    if (item.weapon case final blade?) {
      final character = fighter?.hero ?? hero;
      final alreadyOwned = fighter == null || character == LiteHero.assassino
          ? (fighter?.ownedWeapons ?? ownedWeapons).contains(blade)
          : fighter.weapon == blade;
      return !character.bodyOnly &&
          character != LiteHero.doppelganger &&
          !alreadyOwned;
    }
    return true;
  }

  bool exchangeLunarPiece({LiteCoopFighter? fighter}) {
    final kit = fighter?.supply ?? supply;
    if ((!canUseRestStation(LiteRestStation.merchant, fighter) && !shopOpen) ||
        finished ||
        kit.lunarPieces <= 0)
      return false;
    kit.lunarPieces--;
    if (fighter == null) {
      obser += 60;
    } else {
      fighter.obser += 60;
    }
    message = 'Scambio · un frammento della Luna per 60 Obser.';
    return true;
  }

  bool buyRestItem(LiteRestItem item, {LiteCoopFighter? fighter}) {
    if (!canBuyRestItem(item, fighter: fighter)) return false;
    final kit = fighter?.supply ?? supply;
    final price = restPrice(item, fighter: fighter);
    final firstLesson = item.art != null && !kit.hasGrimoire;
    final studying = item.art != null && kit.knowsArt(item.art!);
    if (item.art case final art?) {
      if (studying) {
        kit._artTraining[art] = kit.artTraining(art) + 1;
      } else {
        kit
          ..hasGrimoire = true
          .._learnedArts.add(art)
          ..art = art;
      }
    } else if (item == LiteRestItem.tempra) {
      final blade = fighter?.weapon ?? weapon;
      kit._forgeRanks[blade] = kit.forgeRank(blade) + 1;
      if (kit.forgeRank(blade) >= 3) {
        achievements.add(
          fighter == null
              ? LiteRun.heroUnlockKey(LiteHero.fabbro)
              : _fabbroUnlockKey(fighter.account),
        );
      }
    } else {
      final rank = item.evolution ? kit.rank(item) + 1 : 1;
      _grantRestItem(item, rank, kit, fighter, stage + 3);
      kit._receipts[item] = rank;
    }
    if (fighter == null) {
      obser -= price;
    } else {
      fighter.obser -= price;
    }
    final blade = fighter?.weapon ?? weapon;
    message = item == LiteRestItem.tempra
        ? '${blade.label} · Tempra ${kit.forgeRank(blade)}/12.'
        : studying
        ? 'Allenamento completato · Forma anticipata e recupero ridotto.'
        : firstLesson
        ? 'Grimorio aperto · ${item.label} appresa.'
        : '${item.label} acquistato.';
    return true;
  }

  bool equipRestArt(LiteRestItem item, {LiteCoopFighter? fighter}) {
    final art = item.art;
    final kit = fighter?.supply ?? supply;
    if (art == null ||
        !canUseRestStation(LiteRestStation.art, fighter) ||
        !kit.hasGrimoire ||
        !kit.knowsArt(art) ||
        kit.art == art) {
      return false;
    }
    kit.art = art;
    message = '${art.label} equipaggiata.';
    return true;
  }

  bool rememberRestItem(LiteRestItem item, {LiteCoopFighter? fighter}) {
    final kit = fighter?.supply ?? supply;
    final purchased = kit._receipts[item];
    final money = fighter?.obser ?? obser;
    if (!canUseRestStation(LiteRestStation.seer, fighter) ||
        purchased == null ||
        money < memoryPrice ||
        kit.promised != null)
      return false;
    final id = '$slimeCreditId-$stage-${fighter?.id ?? 0}-${item.name}';
    kit.promised = LiteRestMemory(id, item, purchased);
    if (fighter == null) {
      obser -= memoryPrice;
    } else {
      fighter.obser -= memoryPrice;
    }
    message = 'La Veggente custodisce ${item.label} per la prossima run.';
    return true;
  }

  bool carryRestMemory(LiteRestMemory memory, {LiteCoopFighter? fighter}) {
    final kit = fighter?.supply ?? supply;
    if (stage != 0 || time != 0 || kit.carriedId != null) return false;
    _grantRestItem(memory.item, memory.rank, kit, fighter, 2);
    kit.carriedId = memory.id;
    if (memory.item == LiteRestItem.bastione) {
      if (fighter == null) {
        shield += memory.rank * 9;
      } else {
        fighter.shield += memory.rank * 9;
      }
    }
    return true;
  }

  void _grantRestItem(
    LiteRestItem item,
    int rank,
    LiteRestLoadout kit,
    LiteCoopFighter? fighter,
    int foodUntil,
  ) {
    if (item.meal) {
      kit._foodUntil[item] = foodUntil;
      for (final ally in clones) {
        if (ally.companion != null &&
            ally.ownerId == (fighter?.id ?? 0) &&
            ally.hp > 0) {
          ally.hp = min(ally.maxHp, ally.hp + ally.maxHp * .20);
        }
      }
    } else if (item.evolution) {
      kit._evolutions[item] = rank;
    } else if (item == LiteRestItem.token) {
      kit.token = true;
    } else if (item.weapon case final blade?) {
      if (fighter == null) {
        if (hero == LiteHero.doppelganger) return;
        if (!ownedWeapons.contains(blade)) ownedWeapons.add(blade);
        if (_assassinCanEquip(blade)) weapon = blade;
      } else if (fighter.hero != LiteHero.doppelganger) {
        fighter.ownedWeapons.add(blade);
        if (_assassinCanEquip(blade, fighter)) fighter.weapon = blade;
      }
    } else if (item.scroll case final scroll?) {
      if (fighter == null) {
        scrolls[scroll.index]++;
      } else {
        kit.scrolls[scroll] = (kit.scrolls[scroll] ?? 0) + 1;
      }
    }
  }

  bool castRestScroll(
    LiteScroll scroll,
    Point<double> target,
    LiteCoopFighter fighter,
  ) {
    final cost = scroll.cost;
    final kit = fighter.supply;
    if (finished ||
        restHub ||
        fighter.hero == LiteHero.doppelganger ||
        cost > fighter.oculum ||
        fighter.hp <= 0 ||
        fighter.blocking ||
        fighter._night.stun > 0 ||
        kit.scrolls[scroll] == null ||
        kit.scrolls[scroll]! <= 0 ||
        fighter._hubCastCooldown > 0)
      return false;
    final aim = LiteRun._unit(target - fighter.position);
    if (aim.magnitude == 0 && scroll != LiteScroll.linfaVerde) return false;
    switch (scroll) {
      case LiteScroll.braceErrante:
        _launchFireball(fighter.position, aim, 22, 3, fighter.id);
      case LiteScroll.spaccaterra:
        _fissure(fighter.position, aim, 7.8, 29, fighter.id);
      case LiteScroll.falciLunari:
        _lunarVolley(fighter.position, aim, 14, owner: fighter.id);
      case LiteScroll.linfaVerde:
        fighter.hp = min(fighter.maxHp, fighter.hp + fighter.maxHp * .20);
        fighter._block.recover(fighter.weapon);
      default:
        return false;
    }
    fighter.oculum -= cost;
    kit.scrolls[scroll] = kit.scrolls[scroll]! - 1;
    fighter._hubCastCooldown = .46;
    return true;
  }

  void _lunarVolley(
    Point<double> origin,
    Point<double> aim,
    double damage, {
    int? owner,
    bool enemy = false,
  }) {
    final heading = atan2(aim.y, aim.x);
    for (final side in [-.23, .23]) {
      final angle = heading + side;
      projectiles.add(
        LiteProjectile(
          position: origin,
          direction: Point(cos(angle), sin(angle)),
          speed: 20,
          remaining: 10,
          damage: damage,
          fromEnemy: enemy,
          magic: true,
          kind: LiteProjectileKind.lunarCrescent,
          ownerCanHeal: owner == null && !enemy,
          sourceCloneId: owner,
        ),
      );
    }
  }

  void _consumeMealForVisit() {
    void use(LiteRestLoadout kit, LiteWeapon weapon, _LiteBlock block) {
      kit._foodUntil.updateAll((item, expiry) => expiry - 1);
      kit._foodUntil.removeWhere((_, expiry) => expiry < stage);
      if (kit.fed(LiteRestItem.spiedino, stage)) block.recover(weapon, 18);
    }

    use(supply, weapon, _block);
    for (final member in coopFighters) {
      use(member.supply, member.weapon, member._block);
    }
  }

  void _tickSupply(double elapsed, {LiteCoopFighter? fighter}) {
    final kit = fighter?.supply ?? supply;
    if (fighter != null)
      fighter._hubCastCooldown = max(0, fighter._hubCastCooldown - elapsed);
    if (kit.fed(LiteRestItem.tisana, stage) && !stageClear) {
      if (fighter == null) {
        oculum = min(maxOculum, oculum + elapsed * .5);
      } else {
        fighter.oculum = min(fighter.maxOculum, fighter.oculum + elapsed * .5);
      }
    }
    final rank = kit.rank(LiteRestItem.spirale);
    if (rank == 0 || stageClear) return;
    kit._spiralTime += elapsed;
    if (kit._spiralTime + 1e-9 < 6) return;
    kit._spiralTime = max(0.0, kit._spiralTime - 6);
    kit._spin = (kit._spin + .37) % (2 * pi);
    final count = 4 + 4 * rank;
    final start = fighter?.position ?? position;
    for (var i = 0; i < count; i++) {
      final angle = kit._spin + i * 2 * pi / count;
      projectiles.add(
        LiteProjectile(
          position: start,
          direction: Point(cos(angle), sin(angle)),
          speed: 10 + rank.toDouble(),
          remaining: 9 + rank.toDouble(),
          damage: 3 + rank * 2.0,
          magic: true,
          kind: LiteProjectileKind.spiral,
          ownerCanHeal: fighter == null,
          sourceCloneId: fighter?.id,
        ),
      );
    }
  }
}
