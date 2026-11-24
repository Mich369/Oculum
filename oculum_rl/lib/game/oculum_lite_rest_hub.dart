part of 'oculum_lite_run.dart';

enum LiteRestStation {
  tavern('Taverniera'),
  forge('Fabbro'),
  merchant('Mercante'),
  seer('Veggente');

  const LiteRestStation(this.label);
  final String label;
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
  );

  const LiteRestItem(this.label, this.station, this.basePrice, this.effect);
  final String label, effect;
  final LiteRestStation station;
  final int basePrice;

  bool get meal => station == LiteRestStation.tavern;
  bool get evolution => this == spirale || this == bastione;
  LiteWeapon? get weapon => switch (this) {
    chakram => LiteWeapon.chakram,
    falce => LiteWeapon.falceRunica,
    carabina => LiteWeapon.carabinaImpulsi,
    lame => LiteWeapon.doppieLame,
    picca => LiteWeapon.piccaOssidiana,
    balestra => LiteWeapon.balestraRunica,
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
      scrolls.isNotEmpty ||
      promised != null ||
      carriedId != null;

  Map<String, Object> get frame => {
    if (token) 'token': true,
    if (lunarPieces > 0) 'lunarPieces': lunarPieces,
    if (_foodUntil.isNotEmpty)
      'meals': _foodUntil.map((key, value) => MapEntry(key.name, value)),
    if (_evolutions.isNotEmpty)
      'evolutions': _evolutions.map((key, value) => MapEntry(key.name, value)),
    if (_receipts.isNotEmpty)
      'receipts': _receipts.map((key, value) => MapEntry(key.name, value)),
    if (scrolls.isNotEmpty)
      'scrolls': scrolls.map((key, value) => MapEntry(key.name, value)),
    if (_spiralTime > 0) 'spiral': [_spiralTime, _spin],
    if (promised case final memory?) 'promised': memory.frame,
    if (carriedId case final id?) 'carriedId': id,
  };

  void restore(Object? data) {
    if (data is! Map) return;
    token = data['token'] == true;
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
    restHub = true;
    fauna.clear();
    obstacles.clear();
    groundShots.clear();
    projectiles.clear();
    _combatImpacts.clear();
    _burstTraces.clear();
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

  int restPrice(LiteRestItem item, {LiteCoopFighter? fighter}) =>
      item.basePrice +
      (item.evolution ? (fighter?.supply ?? supply).rank(item) * 28 : 0);

  bool canBuyRestItem(LiteRestItem item, {LiteCoopFighter? fighter}) {
    if (!restHub ||
        finished ||
        (fighter?.hp ?? hp) <= 0 ||
        (fighter?.obser ?? obser) < restPrice(item, fighter: fighter))
      return false;
    final kit = fighter?.supply ?? supply;
    if (item == LiteRestItem.token) return !kit.token;
    if (item.evolution) return kit.rank(item) < 3;
    if (item.meal) return !kit._receipts.containsKey(item);
    if (item.weapon case final blade?) {
      return (fighter?.hero ?? hero) != LiteHero.doppelganger &&
          (fighter != null
              ? fighter.weapon != blade
              : !ownedWeapons.contains(blade));
    }
    return true;
  }

  bool exchangeLunarPiece({LiteCoopFighter? fighter}) {
    final kit = fighter?.supply ?? supply;
    if ((!restHub && !shopOpen) || finished || kit.lunarPieces <= 0)
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
    final rank = item.evolution ? kit.rank(item) + 1 : 1;
    _grantRestItem(item, rank, kit, fighter, stage + 3);
    kit._receipts[item] = rank;
    if (fighter == null) {
      obser -= price;
    } else {
      fighter.obser -= price;
    }
    message = '${item.label} acquistato.';
    return true;
  }

  bool rememberRestItem(LiteRestItem item, {LiteCoopFighter? fighter}) {
    final kit = fighter?.supply ?? supply;
    final purchased = kit._receipts[item];
    final money = fighter?.obser ?? obser;
    if (!restHub ||
        purchased == null ||
        money < memoryPrice ||
        kit.promised != null ||
        (fighter?.hp ?? hp) <= 0)
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
    } else if (item.evolution) {
      kit._evolutions[item] = rank;
    } else if (item == LiteRestItem.token) {
      kit.token = true;
    } else if (item.weapon case final blade?) {
      if (fighter == null) {
        if (hero == LiteHero.doppelganger) return;
        if (!ownedWeapons.contains(blade)) ownedWeapons.add(blade);
        weapon = blade;
      } else if (fighter.hero != LiteHero.doppelganger) {
        fighter.weapon = blade;
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
