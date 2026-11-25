import 'dart:math';

part 'oculum_lite_night.dart';
part 'oculum_lite_burst.dart';
part 'oculum_lite_goblin.dart';
part 'oculum_lite_rest_hub.dart';
part 'oculum_lite_fauna.dart';
part 'oculum_lite_solar.dart';
part 'oculum_lite_second_act.dart';
part 'oculum_lite_third_act.dart';
part 'oculum_lite_arena_events.dart';
part 'oculum_lite_floor_map.dart';
part 'oculum_lite_stealth.dart';
part 'oculum_lite_baghest.dart';
part 'oculum_lite_art_selection.dart';
part 'oculum_lite_weapon_art.dart';

enum LiteHero {
  evasore('Passo fantasma', 'Scatto intangibile più lungo.'),
  duplicatore(
    'Doppio richiamo',
    'Evoca fino a due copie d’inchiostro per 8 secondi.',
  ),
  ashley('Molla a fondo corsa', 'Pugno a molla potenziato fino a 5 metri.'),
  scostubandito(
    'Gran Scostumato',
    'Evoca il Gran Scostumato con il suo cannone.',
  ),
  granScostumato('Chiamata della banda', 'Evoca due Scostubanditi col fucile.'),
  dronePostea('Sovraccarico', 'Una scarica ad area danneggia e rallenta.'),
  sentinella('Bastione di pietra', 'Ottieni Scudo e respingi i nemici vicini.'),
  babyForestDemon(
    'Ruggito della radura',
    'Travolgi chi si trova davanti a te.',
  ),
  curatorePeste(
    'Forma corvina',
    'Diventi gigante, raddoppi la Vita massima e respingi i nemici colpiti.',
  ),
  pyrel(
    'Corona di braci',
    'Tre palle di fuoco rimbalzano in direzioni diverse.',
  ),
  lithra('Faglia tripla', 'Tre strisce di roccia spezzano il terreno.'),
  luce('Sentenza solare', 'Luce ad area, respinta e Scudo.'),
  ombra('Velo d’ombra', 'Scatto intangibile e 3 secondi di protezione.'),
  veyrth('Costellazione cava', 'Scaglia una corona di sfere.'),
  doppelganger(
    'Istinto della copia',
    'Ripeti il colpo della creatura che hai copiato, potenziato.',
  ),
  cavaliereLunare(
    'Guardiano Lunare',
    'Evoca un Guardiano che scaglia lontano i nemici.',
  ),
  slimeBlu(
    'Marea affamata',
    'Inizia ad assorbire con una presa rinforzata e ottieni Scudo.',
  ),
  vampiro(
    'Sangue antico',
    'Raddoppia Vita massima, velocità e Danni e aumenta la respinta.',
  ),
  reGoblin('Corte dei goblin', 'Evoca due coltelli e un goblin fangoso.'),
  pollo(
    'Uova a orologeria',
    'Spara tre uova alle tue spalle. Esplodono all’impatto o 0,9 s dopo essersi fermate.',
  ),
  raganella(
    'Re dello stagno',
    'Rimbalza in avanti e spazza i nemici al punto di arrivo.',
  ),
  pipistrello(
    'Uno stormo solo',
    'Passa intangibile fra i nemici con un’onda di ultrasuoni.',
  ),
  guardiaSolare(
    'Passo di presidio',
    'Scatta sotto lo scudo e colpisce in avanti.',
  ),
  eliteSolare('Raggio del sigillo', 'Libera un lungo raggio dorato.'),
  guardianoSolare(
    'Mazza d’oro',
    'Materializza la mazza d’oro e potenzia i Danni per 4–7 secondi.',
  ),
  aberrazioneSolare(
    'Mantello d’oro',
    'Stringe le placche. Ottieni Scudo e riduci del 45% i Danni subiti.',
  ),
  demoneMinore('Balzo di cenere', 'Scatta e artiglia a distanza ravvicinata.'),
  demoneIntermedio(
    'Forgia sotto pelle',
    'Scatena uno sbalzo di magma e respinge i nemici.',
  ),
  demoneMaggiore(
    'Sigillo del Prediletto',
    'Attraversa la distanza e apre un sigillo al suolo.',
  ),
  diavolo(
    'Patto dei cinque fuochi',
    'Scaglia cinque fiamme rimbalzanti a ventaglio.',
  ),
  polloMeccanico(
    'Uova di Postea',
    'Lancia tre uova runiche più lontano, con esplosioni più forti e ampie.',
  ),
  vesanybel(
    'Rintocco cieco',
    'Un rintocco ad area travolge e allontana i nemici.',
  ),
  aerovyr('Ventaglio del Cumulonembo', 'Cinque sfere di tempesta divergenti.'),
  vedettaEiva(
    'Passo tra le maree',
    'Scatta e apre un varco con un ampio colpo di picca.',
  );

  const LiteHero(this.openName, this.openDescription);

  final String openName;
  final String openDescription;

  LiteWeapon? get fixedWeapon => switch (this) {
    scostubandito => LiteWeapon.fucileScostubandito,
    granScostumato => LiteWeapon.carabinaImpulsi,
    dronePostea => LiteWeapon.balestraRunica,
    sentinella => LiteWeapon.spadaScudo,
    babyForestDemon => LiteWeapon.guanti,
    curatorePeste || pyrel || veyrth => LiteWeapon.scettro,
    lithra || doppelganger => LiteWeapon.guanti,
    luce => LiteWeapon.piccaOssidiana,
    ombra => LiteWeapon.doppieLame,
    cavaliereLunare ||
    reGoblin ||
    guardiaSolare ||
    eliteSolare => LiteWeapon.spadaScudo,
    guardianoSolare => LiteWeapon.arco,
    aberrazioneSolare || demoneMinore => LiteWeapon.guanti,
    demoneIntermedio => LiteWeapon.falceRunica,
    demoneMaggiore => LiteWeapon.doppieLame,
    diavolo || aerovyr => LiteWeapon.scettro,
    vesanybel => LiteWeapon.falceRunica,
    vedettaEiva => LiteWeapon.piccaOssidiana,
    slimeBlu ||
    vampiro ||
    pollo ||
    polloMeccanico ||
    raganella ||
    pipistrello => LiteWeapon.guanti,
    _ => null,
  };
  String get talentName => switch (this) {
    evasore => 'Schivata',
    duplicatore => 'Duplica',
    ashley => 'Pugno a molla',
    scostubandito => 'Pugno',
    granScostumato => 'Colpo di cannone',
    dronePostea => 'Scarica',
    sentinella => 'Colpo di pietra',
    babyForestDemon => 'Zampata',
    curatorePeste => 'Evoca scheletri',
    pyrel => 'Palla di fuoco rimbalzante',
    lithra => 'Faglia di roccia',
    luce => 'Lancia solare',
    ombra => 'Passo d’ombra',
    veyrth => 'Sfera cava',
    doppelganger => 'Copia un nemico',
    cavaliereLunare => 'Chiama le due Guardie Lunari',
    slimeBlu => 'Assorbimento',
    vampiro => 'Forma pipistrello',
    reGoblin => 'Colpo stordente',
    pollo => 'Uova a orologeria',
    polloMeccanico => 'Uova esplosive di Postea',
    raganella => 'Linguata lunga',
    pipistrello => 'Ultrasuono',
    guardiaSolare => 'Bagliore molesto',
    eliteSolare => 'Guardia delle placche',
    guardianoSolare => 'Due frecce d’oro',
    aberrazioneSolare => 'Spalla di marmo',
    demoneMinore => 'Graffio fulmineo',
    demoneIntermedio => 'Faglia di magma',
    demoneMaggiore => 'Sigillo rapido',
    diavolo => 'Fuoco del patto',
    vesanybel => 'Rintocco protetto',
    aerovyr => 'Sfere gemelle',
    vedettaEiva => 'Stoccata di marea',
  };
  LiteEnemyKind? get sprite => switch (this) {
    scostubandito => LiteEnemyKind.scostubandito,
    granScostumato => LiteEnemyKind.granScostumato,
    dronePostea => LiteEnemyKind.dronePostea,
    sentinella => LiteEnemyKind.costrutto,
    babyForestDemon => LiteEnemyKind.babyForestDemon,
    vesanybel => LiteEnemyKind.vesanybel,
    aerovyr => LiteEnemyKind.aerovyr,
    _ => null,
  };
  String? get unlockHint => switch (this) {
    scostubandito => 'Porta la Vedetta viva oltre il Forest Demon adulto.',
    granScostumato => 'Sconfiggi Veyrth come Scostubandito.',
    dronePostea => 'Completa una missione di scorta del Drone di Postea.',
    sentinella => 'Completa una missione di scorta della Sentinella di Pietra.',
    babyForestDemon => 'Completa una missione di scorta del Baby Forest Demon.',
    luce => 'Sconfiggi La tua Luce al piano 3.',
    ombra => 'Sconfiggi La tua Ombra al piano 9.',
    veyrth => 'Sconfiggi Veyrth al piano 23.',
    cavaliereLunare => 'Completa la campagna in Facile o superiore.',
    slimeBlu => 'Abbatti dieci Slime nelle tue run.',
    reGoblin => 'Sconfiggi il Re Goblin nel Campo goblin segreto.',
    pollo => 'Lascia tre stanze senza ferirne la fauna.',
    polloMeccanico => 'Dopo aver sbloccato il Pollo di Brace, resta fermo dieci secondi in mezzo a tre polli senza aver mai ferito la fauna nella run.',
    raganella => 'Lascia quattro stanze senza ferirne la fauna, fra cui una con una raganella.',
    pipistrello => 'Lascia cinque stanze senza ferirne la fauna, fra cui una con un pipistrello.',
    doppelganger => 'Ottieni una Muta alla morte mentre giochi con un animale.',
    guardiaSolare => 'Supera il primo cortile del dungeon solare.',
    eliteSolare => 'Supera la penultima sala del dungeon solare.',
    guardianoSolare => 'Sconfiggi il Guardiano Solare.',
    aberrazioneSolare =>
      'Supera il dungeon solare dopo aver abbattuto l’Aberrazione.',
    demoneMinore => 'Supera la prima sala di Inferno nell’Atto II.',
    demoneIntermedio => 'Supera la seconda sala di Inferno nell’Atto II.',
    demoneMaggiore => 'Supera la terza sala di Inferno nell’Atto II.',
    diavolo => 'Spezza il patto nell’ultima sala di Inferno.',
    vesanybel => 'Sconfiggi Vesanybel nella Cripta della Campana Cieca.',
    aerovyr => 'Sconfiggi Aerovyr e completa l’Atto III.',
    vedettaEiva => 'Libera gli Altari di bassa marea nell’Atto III.',
    _ => null,
  };

  bool get solar =>
      index >= guardiaSolare.index && index <= aberrazioneSolare.index;
  bool get infernal => switch (this) {
    demoneMinore || demoneIntermedio || demoneMaggiore || diavolo => true,
    _ => false,
  };

  bool get specialTalent =>
      sprite != null || this == curatorePeste || index >= pyrel.index;

  LiteWeapon startingWeapon(LiteWeapon choice) => fixedWeapon ?? choice;
}

enum LitePermanentUpgrade {
  vita('Vita', 5),
  danni('Danni base', 1),
  oculum('Oculum', 1),
  portata('Portata delle armi', 5),
  richiamo('Attrazione Obser', 75),
  passoCompagno('Velocità compagni', 5),
  scudo('Scudo iniziale', 4),
  resistenza('Resistenza del blocco', 10);

  const LitePermanentUpgrade(this.label, this.points);
  final String label;
  final int points;
  static const maxRank = 2;

  String get bonusPerRank => switch (this) {
    vita => '+$points Vita massima',
    danni => '+$points Danni base',
    oculum => '+$points Oculum massimo',
    portata => '+$points% portata delle armi',
    richiamo => '+0,75 m di attrazione Obser',
    passoCompagno => '+$points% movimento e ritmo dei compagni',
    scudo => '+$points Scudo a ogni piano',
    resistenza => '+$points capacità del blocco',
  };

  static Map<LitePermanentUpgrade, int> read(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final upgrade in values)
        if (value[upgrade.name] case final int rank when rank > 0)
          upgrade: min(rank, maxRank),
    };
  }

  static Map<String, int> encode(Map<LitePermanentUpgrade, int> ranks) =>
      ranks.map((upgrade, rank) => MapEntry(upgrade.name, rank));
}

enum LiteWeapon {
  boomerang('Boomerang in legno', 5, 8, .55),
  spadaScudo('Spada e scudo', 6, 2.9, .42),
  guanti('Guanti d’arme giganti', 10, 2.4, .82),
  arco('Arco', 3, 10, .46),
  scettro('Scettro magico', 0, 12, .5),
  falceRunica('Falce runica', 7, 3.4, .86, isPostea: true),
  doppieLame('Doppie lame', 4, 1.9, .45, isPostea: true),
  carabinaImpulsi('Carabina a impulsi', 8, 13, .94, isPostea: true),
  piccaOssidiana('Picca d’ossidiana', 9, 4.3, .73),
  balestraRunica('Balestra runica', 12, 11, 1.24),
  fucileScostubandito('Fucile Scostubandito', 5, 12, .68),
  chakram('Chakram d’Iridio', 9, 9, .32);

  const LiteWeapon(
    this.label,
    this.damageBonus,
    this.range,
    this.cooldown, {
    this.isPostea = false,
  });
  final String label;
  final int damageBonus;
  final double range;
  final double cooldown;
  final bool isPostea;

  static const starters = [boomerang, spadaScudo, guanti, arco, scettro];
  static const scytheReturnRange = 6.3;
  bool get returns =>
      this == boomerang || this == falceRunica || this == chakram;
  bool get isBossLoot => this == piccaOssidiana || this == balestraRunica;
  double get chargeSeconds => switch (this) {
    guanti => .32,
    carabinaImpulsi => .43,
    piccaOssidiana => .20,
    balestraRunica => .29,
    _ => 0,
  };
  double get thrustArc => this == piccaOssidiana ? .87 : .38;
}

enum LiteDifficulty {
  moltoFacile('Molto facile', .65, 3),
  facile('Facile', .82, 1),
  medio('Medio', 1, 0),
  difficile('Difficile', 1.2, 0),
  oculum('Oculum', 1.45, 0);

  const LiteDifficulty(this.label, this.enemyStrength, this.revives);
  final String label;
  final double enemyStrength;
  final int revives;
  double get partyLifeStep => switch (this) {
    moltoFacile => .01,
    facile => .03,
    medio => .06,
    difficile => .09,
    oculum => .12,
  };
}

enum LiteBiome {
  campo('Campo Scostubanditi'),
  foresta('Foresta Elementale'),
  dungeon('Regno Sotterraneo'),
  postea('Postea · Fonderie runiche'),
  deserto('Deserto Divoratore'),
  orea('Orea Zalira');

  const LiteBiome(this.label);
  final String label;
  static const legacy = [campo, foresta, dungeon, postea];

  static List<LiteBiome> offers(
    int seed, {
    LiteBiome? include,
    LiteBiome? avoid,
  }) {
    final random = _LiteRandom(seed)
      ..nextDouble()
      ..nextDouble();
    final options = values
        .where((place) => place != include && place != avoid)
        .toList();
    for (var i = options.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final swap = options[i];
      options[i] = options[j];
      options[j] = swap;
    }
    return List.unmodifiable([
      if (include != null) include,
      ...options.take(include == null ? 3 : 2),
    ]);
  }
}

enum LiteEncounter { ordinary, elite, boss, finalBoss }

enum LiteArchonAttack {
  impact('Frattura', 1.35, 2.85, 30),
  fault('Spaccatura', 1.12, .9, 34),
  crown('Corona spezzata', 1.20, .43, 26);

  const LiteArchonAttack(this.label, this.windup, this.radius, this.damage);
  final String label;
  final double windup;
  final double radius;
  final double damage;
}

enum LitePowerUp {
  lama('Lama vorace', 'Danni delle armi', [.12, .28, .65]),
  prisma('Prisma spezzato', 'Danni di Art e pergamene', [.18, .42, .90]),
  cuore('Cuore runico', 'Vita massima e Scudo iniziale', [10, 25, 55]),
  passo('Passo di tempesta', 'Movimento e distanza della schivata', [
    .08,
    .19,
    .38,
  ]),
  condotto('Condotto dell’Iride', 'Oculum rigenerato al secondo', [
    .30,
    .75,
    2.4,
  ]),
  braci('Braci d’impatto', 'Danni ad area nei Clash', [5, 10, 20]),
  riflusso('Riflusso d’Oculum', 'Scudo ottenuto usando l’Open', [5, 10, 22]),
  risonanza('Risonanza d’ombra', 'Recupero degli attacchi dopo l’Open', [
    .18,
    .32,
    .50,
  ]),
  occhioLungo('Occhio lungo', 'Portata delle armi', [.08, .18, .35]),
  irideVorace('Iride vorace', 'Raggio di attrazione Obser', [1.25, 2.75, 4.50]),
  legameVigile('Legame vigile', 'Movimento e ritmo dei compagni', [
    .10,
    .22,
    .40,
  ]),
  pelleRunica('Pelle runica', 'Scudo a ogni piano', [5, 12, 25]),
  ferroVivo('Ferro vivo', 'Capacità del blocco', [12, 30, 65]),
  schegge('Sigillo delle schegge', 'Onda runica dai ripari', [7, 15, 30]);

  const LitePowerUp(this.label, this.effect, this.valuesByRank);
  final String label;
  final String effect;
  final List<double> valuesByRank;
  static const maxRank = 3;
  bool get shared =>
      this == braci ||
      this == riflusso ||
      this == risonanza ||
      this == occhioLungo ||
      this == irideVorace ||
      this == legameVigile ||
      this == pelleRunica ||
      this == ferroVivo ||
      this == schegge;

  double valueAt(int rank) =>
      rank <= 0 ? 0 : valuesByRank[rank.clamp(1, maxRank) - 1];

  String descriptionAt(int rank) {
    final value = valueAt(rank);
    return switch (this) {
      cuore =>
        '+${value.round()} Vita massima e +${(value / 3).ceil()} Scudo '
            'a ogni nuovo piano',
      condotto =>
        '+${value.toStringAsFixed(2).replaceFirst('.', ',')} Oculum/s',
      braci =>
        '+${value.round()} Danni ai nemici entro 2 m da un Clash di proiettili',
      riflusso => '+${value.round()} Scudo quando attivi la tua Open',
      risonanza =>
        '−${(value * 100).round()}% recupero degli attacchi per 4 s dopo l’Open',
      irideVorace =>
        '+${value.toStringAsFixed(2).replaceFirst('.', ',')} m di attrazione Obser',
      pelleRunica => '+${value.round()} Scudo subito e a ogni nuovo piano',
      ferroVivo => '+${value.round()} capacità del blocco con F',
      schegge => '${value.round()} Danni entro 2,6 m quando infrangi un riparo',
      _ => '+${(value * 100).round()}% · $effect',
    };
  }
}

enum LiteFloorLayout {
  standard(''),
  traversata('Passaggi incrociati'),
  cerchio('Anello dei ripari'),
  montaggio('Linea di montaggio');

  const LiteFloorLayout(this.label);
  final String label;
}

enum LiteArenaTrial {
  battuta('Battuta dei predoni', 'Due nemici in più', 22, LitePowerUp.braci),
  muraglia('Patto di ferro', '+25% Vita dei nemici', 28, LitePowerUp.riflusso),
  caccia(
    'Caccia al varco',
    'Nemici +15% velocità. Completa entro 40 s di arena',
    35,
    LitePowerUp.risonanza,
  );

  const LiteArenaTrial(this.label, this.risk, this.obser, this.power);
  final String label, risk;
  final int obser;
  final LitePowerUp power;
}

class LiteFloorPreview {
  const LiteFloorPreview({
    required this.floor,
    required this.biome,
    required this.encounter,
    required this.layout,
    required this.openingEnemies,
    required this.enemyKinds,
    required this.special,
    required this.rest,
    required this.featuredPower,
    this.trial,
  });

  final int floor;
  final LiteBiome biome;
  final LiteEncounter encounter;
  final LiteFloorLayout layout;
  final int openingEnemies;
  final List<LiteEnemyKind> enemyKinds;
  final LiteEnemyKind? special;
  final bool rest;
  final LitePowerUp? featuredPower;
  final LiteArenaTrial? trial;
}

enum LiteFinalBossPhase {
  inactive,
  tangible,
  intangible,
  beamTangible,
  beamIntangible,
  defeated,
}

enum LiteEnemyKind {
  scostubandito('Scostubandito', 23, .53, 3.1, 8),
  granScostumato('Gran Scostumato', 96, 1.05, 2.05, 22),
  babyForestDemon('Baby Forest Demon', 31, .67, 3.4, 11),
  forestDemon('Forest Demon', 106, 1.28, 2.15, 24),
  slime('Slime', 24, .55, 2.65, 9),
  costrutto('Costrutto Minore', 105, .93, 1.85, 23),
  ragnoSaldatore('Ragno Saldatore', 34, .7, 2.45, 13),
  dronePostea('Drone runico di Postea', 25, .52, 3.8, 8),
  miruscyrus('Miruscyrus', 112, 1.1, 2.8, 23),
  luce('La tua Luce', 156, .74, 4.0, 16),
  ombra('La tua Ombra', 152, .76, 4.55, 18),
  veyrth('Veyrth', 188, 1.24, 1.4, 20),
  minionVeyrth('Eco di Veyrth', 1, .43, 3.85, 5),
  ecoSpeculare('Eco speculare', 4, .51, 3.75, 7),
  rasvyr('Rasvyr', 38, .69, 2.5, 14),
  orbryx('Orbryx', 29, .57, 3.6, 11),
  lupoLunare('Lupo Lunare', 42, .68, 3.7, 15),
  gablyn('Gablyn', 36, .52, 3.0, 12),
  guardiaLunare('Guardia Lunare', 44, .56, 3.0, 12),
  guardianoLunare('Guardiano Lunare', 86, .97, 2.5, 24),
  goblinColtello('Goblin col coltello', 17, .47, 4.25, 12),
  goblinFango('Goblin fangoso', 33, .52, 2.55, 4),
  goblinColla('Spara-colla', 30, .53, 2.65, 3),
  reGoblin('Re Goblin', 174, .81, 3.85, 15),
  pollo('Pollo di Brace', 15, .42, 4.0, 8),
  raganella('Raganella del Muschio', 23, .44, 3.25, 10),
  pipistrello('Pipistrello di Pece', 17, .39, 4.6, 7),
  guardiaSolare('Guardia Solare', 30, .53, 3.25, 10),
  eliteSolare('Guardia Elité Solare', 68, .64, 3.05, 14),
  guardianoSolare('Guardiano Solare', 154, 1.14, 1.9, 22),
  aberrazioneSolare('Aberrazione d’Oro e Marmo', 63, .80, 3.08, 14),
  eliteLunare('Guardia Elité Lunare', 61, .65, 3.25, 15),
  custodeLunare('Custode Lunare', 126, 1.06, 2.2, 21),
  demoneMinore('Demone Minore', 31, .48, 4.35, 9),
  demoneIntermedio('Demone Intermedio', 57, .70, 2.75, 12),
  demoneMaggiore('Demone Maggiore Prediletto', 72, .65, 3.68, 14),
  diavolo('Diavolo del Patto', 146, .94, 2.38, 19),
  divoramitu('Divoramitù Elité', 78, 1.13, 2.3, 18),
  divoramituBoss('Divoramitù · Bocca della Cripta', 132, 1.85, 2.5, 23),
  arconte('Arconte delle Fratture', 312, 1.52, 1.7, 27),
  funerys('Funerys', 57, .62, 3.3, 15),
  vegliante('Vegliante di Bronzo', 104, .83, 2.1, 19),
  vesanybel('Vesanybel', 204, .91, 2.15, 22),
  sacrycrab('Sacrycrab', 68, .78, 3.25, 15),
  gelycryn('Gelycryn', 118, .95, 2.45, 20),
  thalvyr('Thalvyr', 219, 1.32, 2.25, 23),
  lapysrieth('Lapysrieth', 54, .64, 3.4, 16),
  nymboryth('Nymboryth', 127, 1.07, 3.0, 21),
  aerovyr('Aerovyr', 261, 1.30, 2.63, 26),
  baghest('Baghest', 265, 1.24, 2.55, 24),
  corrottoRosso('Baghest Slave', 48, .58, 3.8, 14);

  const LiteEnemyKind(
    this.label,
    this.health,
    this.radius,
    this.speed,
    this.damage,
  );
  final String label;
  final int health;
  final double radius;
  final double speed;
  final int damage;

  bool get elite =>
      this == granScostumato ||
      this == forestDemon ||
      this == costrutto ||
      this == miruscyrus ||
      this == eliteSolare ||
      this == eliteLunare ||
      this == divoramitu ||
      this == vegliante ||
      this == gelycryn ||
      this == nymboryth;

  LiteHero? get playableBoss => switch (this) {
    luce => LiteHero.luce,
    ombra => LiteHero.ombra,
    veyrth => LiteHero.veyrth,
    reGoblin => LiteHero.reGoblin,
    vesanybel => LiteHero.vesanybel,
    _ => null,
  };

  bool get boss =>
      playableBoss != null ||
      this == guardianoSolare ||
      this == custodeLunare ||
      this == divoramituBoss ||
      this == diavolo ||
      this == arconte ||
      this == vesanybel ||
      this == thalvyr ||
      this == aerovyr ||
      this == baghest;
  bool get echo => this == minionVeyrth || this == ecoSpeculare;
}

enum LiteCompanion {
  vedetta(
    'Vedetta Scostubandita',
    LiteEnemyKind.granScostumato,
    LiteEnemyKind.scostubandito,
    LiteWeapon.fucileScostubandito,
    46,
    9,
  ),
  drone(
    'Drone di Postea',
    LiteEnemyKind.miruscyrus,
    LiteEnemyKind.dronePostea,
    LiteWeapon.balestraRunica,
    38,
    10,
  ),
  granScostumato(
    'Gran Scostumato evocato',
    null,
    LiteEnemyKind.granScostumato,
    LiteWeapon.carabinaImpulsi,
    65,
    18,
  ),
  sentinella(
    'Sentinella di Pietra',
    LiteEnemyKind.costrutto,
    LiteEnemyKind.costrutto,
    LiteWeapon.spadaScudo,
    64,
    11,
  ),
  babyForestDemon(
    'Baby Forest Demon',
    LiteEnemyKind.forestDemon,
    LiteEnemyKind.babyForestDemon,
    LiteWeapon.guanti,
    51,
    12,
  ),
  scheletroFalce(
    'Scheletro con falce',
    null,
    LiteEnemyKind.costrutto,
    LiteWeapon.falceRunica,
    28,
    15,
  ),
  scheletroArco(
    'Scheletro arciere',
    null,
    LiteEnemyKind.costrutto,
    LiteWeapon.arco,
    22,
    11,
  ),
  piccolaMarea(
    'Piccola Marea',
    null,
    LiteEnemyKind.rasvyr,
    LiteWeapon.guanti,
    37,
    13,
  ),
  orbietto('Orbietto', null, LiteEnemyKind.orbryx, LiteWeapon.guanti, 30, 11),
  lumin('Lumin d’eco', null, LiteEnemyKind.slime, LiteWeapon.scettro, 24, 8),
  guardiaLunare(
    'Guardia Lunare',
    null,
    LiteEnemyKind.guardiaLunare,
    LiteWeapon.spadaScudo,
    43,
    14,
  ),
  guardianoLunare(
    'Guardiano Lunare',
    null,
    LiteEnemyKind.guardianoLunare,
    LiteWeapon.guanti,
    84,
    25,
  ),
  goblinColtello(
    'Goblin col coltello',
    null,
    LiteEnemyKind.goblinColtello,
    LiteWeapon.doppieLame,
    28,
    11,
  ),
  goblinFango(
    'Goblin fangoso',
    null,
    LiteEnemyKind.goblinFango,
    LiteWeapon.arco,
    33,
    4,
  ),
  goblinColla(
    'Spara-colla',
    null,
    LiteEnemyKind.goblinColla,
    LiteWeapon.arco,
    30,
    3,
  ),
  lupoAlleato(
    'Lupo Lunare alleato',
    null,
    LiteEnemyKind.lupoLunare,
    LiteWeapon.guanti,
    42,
    15,
  );

  const LiteCompanion(
    this.label,
    this.unlocksAfter,
    this.sprite,
    this.weapon,
    this.life,
    this.damage,
  );

  final String label;
  final LiteEnemyKind? unlocksAfter;
  final LiteEnemyKind sprite;
  final LiteWeapon weapon;
  final double life;
  final double damage;

  String get unlockKey => 'compagno-$name';
  LiteHero? get questHero => switch (this) {
    vedetta => LiteHero.scostubandito,
    drone => LiteHero.dronePostea,
    sentinella => LiteHero.sentinella,
    babyForestDemon => LiteHero.babyForestDemon,
    granScostumato ||
    scheletroFalce ||
    scheletroArco ||
    piccolaMarea ||
    orbietto ||
    lumin ||
    guardiaLunare ||
    guardianoLunare ||
    goblinColtello ||
    goblinFango ||
    goblinColla ||
    lupoAlleato => null,
  };
  String? get discovery => switch (this) {
    piccolaMarea => 'Spaccascheletri · abbatti tre Rasvyr durante la run',
    orbietto => 'Occhio per i segreti · trova una sala segreta a Orea Zalira',
    lumin => 'Predatore speculare · un Doppelganger copia uno Slime',
    goblinColla => 'Fanteria goblin · abbatti uno Spara-colla per arruolarlo nell’Open del Re',
    _ => null,
  };

  bool get isSkeleton => this == scheletroFalce || this == scheletroArco;

  static LiteCompanion? unlockedBy(LiteEnemyKind kind) =>
      values.where((companion) => companion.unlocksAfter == kind).firstOrNull;
}

enum LiteScroll {
  dardo('Dardo arcano', 3),
  onda('Onda di Materia', 4),
  velo('Velo protettivo', 3),
  richiamo('Richiamo d’inchiostro', 4),
  raggioAlPlasma('Raggio al plasma', 4),
  braceErrante('Brace errante', 4),
  spaccaterra('Spaccaterra', 5),
  linfaVerde('Linfa verde', 4),
  falciLunari('Falci di Vaitern', 5);

  const LiteScroll(this.label, this.cost);
  final String label;
  final int cost;

  static const ordinary = [dardo, onda, velo, richiamo];
}

enum LiteLootKind {
  obser,
  scroll,
  healing,
  weapon,
  greenStone,
  refinedGreenGem,
  lunarSymbol,
}

enum LiteProjectileKind {
  normal,
  scythe,
  pulse,
  cannon,
  plasma,
  frostBolt,
  veyrthSphere,
  rifleBullet,
  rifleCritical,
  fireball,
  bomb,
  mud,
  glue,
  chakram,
  spiral,
  lunarCrescent,
  egg,
  solarBolt,
  solarRay,
  posteaRay,
  posteaEgg,
}

enum LiteImpactTarget {
  player,
  enemy,
  ally,
  clash,
  verdict,
  fissure,
  explosion,
  defeat,
}

class LiteCombatImpact {
  LiteCombatImpact(
    this.target,
    this._id,
    this.position,
    this.time, {
    this.life = 0,
    this.shield = 0,
    this.intangible = false,
    this.enemyKind,
    this.end,
    this.silent = false,
  });

  final LiteImpactTarget target;
  final int _id;
  int get subjectId => _id;
  Point<double> position;
  double time;
  double life;
  double shield;
  final bool intangible;
  final LiteEnemyKind? enemyKind;
  final Point<double>? end;
  final bool silent;

  List<Object?> _frame() => [
    target.index,
    _id,
    position.x,
    position.y,
    time,
    life,
    shield,
    intangible,
    enemyKind?.index,
    if (end != null) ...[end!.x, end!.y],
    if (silent) true,
  ];

  static LiteCombatImpact? _fromFrame(Object? value, double now) {
    if (value is! List || value.length < 9 || value.length > 12) return null;
    final target = _int(value[0], -1);
    final kind = _int(value[8], -1);
    final at = _num(value[4], -1);
    if (target < 0 ||
        target >= LiteImpactTarget.values.length ||
        at < 0 ||
        at > now ||
        now - at > LiteRun.combatImpactDuration) {
      return null;
    }
    return LiteCombatImpact(
      LiteImpactTarget.values[target],
      _int(value[1]),
      Point(_num(value[2]), _num(value[3])),
      at,
      end: value.length >= 11 ? Point(_num(value[9]), _num(value[10])) : null,
      silent: value.length.isEven && value.last == true,
      life: max(0.0, _num(value[5])),
      shield: max(0.0, _num(value[6])),
      intangible: value[7] == true,
      enemyKind: kind >= 0 && kind < LiteEnemyKind.values.length
          ? LiteEnemyKind.values[kind]
          : null,
    );
  }
}

class LiteObstacle {
  LiteObstacle(
    this.left,
    this.top,
    this.width,
    this.height, {
    this.breakable = false,
    this.secretGate = false,
    this.mapShortcut = false,
    this.fixedMap = false,
    this.solarGate = false,
    this.hp = 20,
  });
  final double left, top, width, height;
  final bool breakable, secretGate, solarGate, mapShortcut, fixedMap;
  double hp;
  Point<double> get center => Point(left + width / 2, top + height / 2);

  bool visibleAt(Point<double> p, double radius) =>
      _intersects(p.x, p.y, radius * radius);

  bool _intersects(double x, double y, double radiusSquared) {
    final nearestX = x.clamp(left, left + width);
    final nearestY = y.clamp(top, top + height);
    return _square(x - nearestX) + _square(y - nearestY) < radiusSquared;
  }

  Map<String, dynamic> _json() => {
    'left': left,
    'top': top,
    'width': width,
    'height': height,
    'breakable': breakable,
    if (secretGate) 'secretGate': true,
    if (mapShortcut) 'mapShortcut': true,
    if (solarGate) 'solarGate': true,
    'hp': hp,
  };
  static LiteObstacle _read(Map<String, dynamic> json) => LiteObstacle(
    _num(json['left']),
    _num(json['top']),
    _num(json['width']),
    _num(json['height']),
    breakable: json['breakable'] == true,
    secretGate: json['secretGate'] == true,
    mapShortcut: json['mapShortcut'] == true,
    solarGate: json['solarGate'] == true,
    hp: _num(json['hp'], 20),
  );
}

/// Presentation follows displacement, so a blocked actor never walks in place.
class LiteStride {
  double _distance = 0;
  double _strength = 0;
  double _speed = 0;

  double get distance => _distance;
  double get strength => _strength;
  double get speed => _speed;

  void _track(Point<double> start, Point<double> end, double elapsed) {
    final displacement = start == end ? 0.0 : start.distanceTo(end);
    // A teleport has a separate effect. It does not play several steps.
    final travel = displacement <= 1.25 ? displacement : 0.0;
    _distance += travel;
    _speed = travel / elapsed;
    final target = (_speed / 1.1).clamp(0.0, 1.0);
    _strength += (target - _strength) * min(1.0, elapsed * 16);
    if (_strength < .005) _strength = 0;
  }

  void _reset() => _distance = _strength = _speed = 0;

  List<double> _frame() => [_distance, _strength, _speed];

  void _restore(Object? frame) {
    if (frame is! List || frame.length != 3) return;
    _distance = max(0.0, _num(frame[0]));
    _strength = _num(frame[1]).clamp(0.0, 1.0);
    _speed = _num(frame[2]).clamp(0.0, 35.0);
  }
}

class LiteEnemy {
  LiteEnemy(this.id, this.kind, this.position, this.maxHp)
    : hp = maxHp,
      burrow =
          kind == LiteEnemyKind.divoramitu ||
              kind == LiteEnemyKind.divoramituBoss
          ? LiteBurrow()
          : null;
  final LiteBurrow? burrow;
  LiteGuard? guard;

  final int id;
  final LiteEnemyKind kind;
  Point<double> position;
  final double maxHp;
  double hp;
  double hitFlash = 0;
  double shockRemaining = 0;
  Point<double>? shockSource;
  double cooldown = .75;
  double windup = 0;
  Point<double>? attackTarget;
  bool preparingBeam = false;
  bool mirrorSummon = false;
  double clashRemaining = 0;
  Point<double> clashDirection = const Point(0, 0);
  double summonIn = 3;
  double beamReadyIn = 0;
  LiteMirrorBuild? mirror;
  final stride = LiteStride();
  double stunned = 0;
  double muddied = 0;
  bool glueRetinue = false;
  int combatCycle = 0;
  LiteArchonAttack? archonAttack;
  int get archonPhase => hp > maxHp * .70 ? 1 : (hp > maxHp * .35 ? 2 : 3);
  double _strikePose = 0;
  double get strikePose => _strikePose;

  String get name => kind.label;
  double get radius => kind.radius;
  double get hitboxRadius => burrow == null ? radius : radius * .73;
  double get hitboxHalfLength => burrow == null ? 0 : radius * 1.22;
  Point<double> get hitboxAxis {
    final track = burrow;
    return track == null
        ? const Point(1, 0)
        : LiteRun._unit(track.end - track.start);
  }

  Point<double> closestHitboxPoint(Point<double> at) {
    if (burrow == null) return position;
    final axis = hitboxAxis;
    final delta = at - position;
    final along = (delta.x * axis.x + delta.y * axis.y).clamp(
      -hitboxHalfLength,
      hitboxHalfLength,
    );
    return position + axis * along;
  }

  bool hitboxContains(Point<double> at, {double extra = 0}) =>
      at.distanceTo(closestHitboxPoint(at)) <= hitboxRadius + extra;
  bool get attacking => windup > 0;
  bool get preparingSpheres =>
      kind == LiteEnemyKind.veyrth && hp > 0 && attacking && !preparingBeam;
  bool get cannonRaised => kind == LiteEnemyKind.granScostumato && attacking;

  Point<double> sphereDirection(int index) {
    final delta = (attackTarget ?? position) - position;
    final angle =
        atan2(delta.y, delta.x) + index * (2 * pi / LiteRun.finalSphereCount);
    return Point(cos(angle), sin(angle));
  }

  Map<String, dynamic> _json({bool includeEffects = false}) => {
    'id': id,
    'kind': kind.name,
    'position': _savePoint(position),
    'maxHp': maxHp,
    'hp': hp,
    'hitFlash': hitFlash,
    if (guard case final senses?) 'guard': senses.frame,
    if (stunned > 0) 'stun': stunned,
    if (muddied > 0) 'mud': muddied,
    if (shockSource case final source? when shockRemaining > 0) ...{
      'shockRemaining': shockRemaining,
      'shockSource': _savePoint(source),
    },
    'cooldown': cooldown,
    'windup': windup,
    if (combatCycle != 0) 'combatCycle': combatCycle,
    if (archonAttack case final attack? when attacking)
      'archonAttack': attack.name,
    if (burrow case final track?) 'burrow': track.frame,
    if (includeEffects) ...{
      'stride': stride._frame(),
      if (_strikePose > 0) 'strikePose': _strikePose,
    },
    if (clashRemaining > 0) ...{
      'clashRemaining': clashRemaining,
      'clashDirection': _savePoint(clashDirection),
    },
    if (attackTarget != null) 'attackTarget': _savePoint(attackTarget!),
    if (kind == LiteEnemyKind.reGoblin) 'summonIn': summonIn,
    if (glueRetinue) 'glueRetinue': true,
    if (kind == LiteEnemyKind.veyrth) ...{
      'preparingBeam': preparingBeam,
      'summonIn': summonIn,
      'beamReadyIn': beamReadyIn,
    },
    if (mirror != null) 'mirror': mirror!._json(),
    if (mirrorSummon) 'mirrorSummon': true,
  };
  static LiteEnemy _read(Map<String, dynamic> json) =>
      LiteEnemy(
          _int(json['id']),
          _enum(LiteEnemyKind.values, json['kind'], LiteEnemyKind.slime),
          _point(json['position']),
          max(1, _num(json['maxHp'], 1)),
        )
        ..hp = _num(json['hp'])
        ..guard = LiteGuard.read(json['guard'])
        ..hitFlash = _num(json['hitFlash'])
        ..stunned = _num(json['stun']).clamp(0.0, .9)
        ..muddied = _num(json['mud']).clamp(0.0, .9)
        ..glueRetinue = json['glueRetinue'] == true
        ..shockRemaining = _num(json['shockRemaining'])
            .clamp(0, LiteRun.staffShockSlow)
        ..shockSource = json['shockSource'] == null
            ? null
            : _point(json['shockSource'])
        ..cooldown = _num(json['cooldown'])
        ..windup = _num(json['windup'])
        ..combatCycle = _int(json['combatCycle'])
        ..archonAttack = LiteArchonAttack.values
            .where((attack) => attack.name == json['archonAttack'])
            .firstOrNull
        ..stride._restore(json['stride'])
        .._strikePose = _num(json['strikePose']).clamp(0.0, .24)
        ..clashRemaining = _num(json['clashRemaining'])
            .clamp(0.0, LiteRun.clashDashDuration)
        ..clashDirection = _point(json['clashDirection'])
        ..preparingBeam = json['preparingBeam'] == true
        ..mirrorSummon = json['mirrorSummon'] == true
        ..summonIn = _num(json['summonIn'], 3)
        ..beamReadyIn = _num(json['beamReadyIn'])
        ..mirror = json['mirror'] is Map<String, dynamic>
            ? LiteMirrorBuild._read(json['mirror'] as Map<String, dynamic>)
            : null
        ..burrow?.restore(json['burrow'])
        ..attackTarget = json['attackTarget'] == null
            ? null
            : _point(json['attackTarget']);
}

class LiteMirrorBuild {
  LiteMirrorBuild({
    required this.hero,
    required this.weapon,
    required this.slots,
    required this.quantities,
    required this.learned,
    required this.oculum,
    required this.damage,
    required this.shield,
    this.powers = const {},
  });

  final LiteHero hero;
  final LiteWeapon weapon;
  final List<LiteScroll> slots;
  final List<int> quantities;
  final Set<LiteScroll> learned;
  final double damage;
  final Map<LitePowerUp, int> powers;
  double oculum;
  double shield;
  double talentCooldown = 2;
  double artCooldown = 2;
  double intangible = 0;
  double signatureCooldown = 2.5;
  double shadowVeilRemaining = 0;
  bool chargingVerdict = false;
  int actionCycle = 0;

  double power(LitePowerUp item) => item.valueAt(powers[item] ?? 0);

  Map<String, dynamic> _json() => {
    'hero': hero.name,
    'weapon': weapon.name,
    'slots': slots.map((scroll) => scroll.name).toList(),
    'quantities': [...quantities],
    'learned': learned.map((scroll) => scroll.name).toList(),
    'damage': damage,
    'oculum': oculum,
    'shield': shield,
    'powers': _savePowers(powers),
    'talentCooldown': talentCooldown,
    'artCooldown': artCooldown,
    'intangible': intangible,
    'signatureCooldown': signatureCooldown,
    'shadowVeilRemaining': shadowVeilRemaining,
    'chargingVerdict': chargingVerdict,
    'actionCycle': actionCycle,
  };

  static LiteMirrorBuild _read(Map<String, dynamic> json) {
    final quantities = _list(json['quantities']);
    return LiteMirrorBuild(
        hero: _enum(LiteHero.values, json['hero'], LiteHero.evasore),
        weapon: _enum(LiteWeapon.values, json['weapon'], LiteWeapon.spadaScudo),
        slots: _list(json['slots'])
            .map((name) => _enum(LiteScroll.values, name, LiteScroll.dardo))
            .take(4)
            .toList(),
        quantities: List.generate(
          LiteScroll.values.length,
          (i) => i < quantities.length ? _int(quantities[i]) : 0,
        ),
        learned: _list(json['learned'])
            .map((name) => _enum(LiteScroll.values, name, LiteScroll.dardo))
            .toSet(),
        oculum: _num(json['oculum']),
        damage: _num(json['damage']),
        shield: _num(json['shield']),
        powers: _readPowers(json['powers']),
      )
      ..talentCooldown = _num(json['talentCooldown'])
      ..artCooldown = _num(json['artCooldown'])
      ..intangible = _num(json['intangible'])
      ..signatureCooldown = _num(json['signatureCooldown'], 2.5)
      ..shadowVeilRemaining = _num(json['shadowVeilRemaining']).clamp(0.0, 3.0)
      ..chargingVerdict = json['chargingVerdict'] == true
      ..actionCycle = _int(json['actionCycle']);
  }
}

Map<String, int> _savePowers(Map<LitePowerUp, int> powers) => {
  for (final entry in powers.entries) entry.key.name: entry.value,
};

Map<LitePowerUp, int> _readPowers(Object? input) => {
  if (input is Map)
    for (final power in LitePowerUp.values)
      if (_int(input[power.name]) > 0)
        power: min(LitePowerUp.maxRank, _int(input[power.name])),
};

class LiteBeam {
  LiteBeam(this.origin, this.direction) : end = origin;

  final Point<double> origin;
  Point<double> direction;
  Point<double> end;
  double remaining = LiteRun.finalBeamDuration;
  double coverContact = 0;
  double _pulseRemaining = 0;
  LiteObstacle? _cover;

  Map<String, dynamic> _json(List<LiteObstacle> obstacles) => {
    'origin': _savePoint(origin),
    'direction': _savePoint(direction),
    'end': _savePoint(end),
    'remaining': remaining,
    'coverContact': coverContact,
    'pulseRemaining': _pulseRemaining,
    'coverIndex': _cover == null ? -1 : obstacles.indexOf(_cover!),
  };

  static LiteBeam _read(
    Map<String, dynamic> json,
    List<LiteObstacle> obstacles,
  ) {
    final coverIndex = _int(json['coverIndex'], -1);
    final cover = coverIndex >= 0 && coverIndex < obstacles.length
        ? obstacles[coverIndex]
        : null;
    return LiteBeam(_point(json['origin']), _point(json['direction']))
      ..end = _point(json['end'])
      ..remaining = _num(json['remaining'])
      ..coverContact = cover == null ? 0 : _num(json['coverContact'])
      .._pulseRemaining = _num(json['pulseRemaining'])
      .._cover = cover;
  }
}

class LiteProjectile {
  LiteProjectile({
    required this.position,
    required this.direction,
    required this.speed,
    required this.remaining,
    required this.damage,
    this.fromEnemy = false,
    this.magic = false,
    this.boomerang = false,
    this.returning = false,
    this.ownerCanHeal = true,
    this.nonLethal = false,
    this.kind = LiteProjectileKind.normal,
    this.sourceCloneId,
    this.bounces = 0,
    Point<double>? origin,
  }) : origin = origin ?? position;

  Point<double> position, direction;
  final Point<double> origin;
  final double speed, damage;
  double remaining;
  int bounces;
  double? eggFuse;
  double age = 0;
  final bool fromEnemy, magic, boomerang, ownerCanHeal, nonLethal;
  final LiteProjectileKind kind;
  final int? sourceCloneId;
  bool returning;
  final Set<int> hit = {};

  Map<String, dynamic> _json() => {
    'position': _savePoint(position),
    'direction': _savePoint(direction),
    'origin': _savePoint(origin),
    'speed': speed,
    'remaining': remaining,
    'damage': damage,
    'age': age,
    if (bounces > 0) 'bounces': bounces,
    if (eggFuse case final fuse?) 'eggFuse': fuse,
    'fromEnemy': fromEnemy,
    'magic': magic,
    'boomerang': boomerang,
    'returning': returning,
    'ownerCanHeal': ownerCanHeal,
    'nonLethal': nonLethal,
    if (kind != LiteProjectileKind.normal) 'kind': kind.name,
    if (sourceCloneId != null) 'sourceCloneId': sourceCloneId,
    'hit': hit.toList(),
  };
  static LiteProjectile _read(Map<String, dynamic> json) =>
      LiteProjectile(
          position: _point(json['position']),
          direction: _point(json['direction']),
          origin: _point(json['origin']),
          speed: _num(json['speed']),
          remaining: _num(json['remaining']),
          damage: _num(json['damage']),
          fromEnemy: json['fromEnemy'] == true,
          magic: json['magic'] == true,
          boomerang: json['boomerang'] == true,
          returning: json['returning'] == true,
          ownerCanHeal: json['ownerCanHeal'] != false,
          nonLethal: json['nonLethal'] == true,
          kind: _enum(
            LiteProjectileKind.values,
            json['kind'],
            LiteProjectileKind.normal,
          ),
          sourceCloneId: json['sourceCloneId'] as int?,
          bounces: _int(json['bounces']).clamp(0, 6),
        )
        ..age = _num(json['age'])
        ..eggFuse = json['eggFuse'] is num
            ? _num(json['eggFuse']).clamp(0, .9)
            : null
        ..hit.addAll(_list(json['hit']).whereType<int>());
}

class LiteClone {
  LiteClone(
    this.position,
    this.hp,
    this.weapon, {
    this.summoned = false,
    this.companion,
    this.ownerId = 0,
    this.id = 0,
    this.expiresAfter,
    this.recruitedFloor,
    this.damageScale = 1,
    double? maxHp,
  }) : _baseMaxHp = maxHp ?? hp;
  Point<double> position;
  double hp;
  final double _baseMaxHp;
  double get maxHp => _baseMaxHp;
  LiteWeapon weapon;
  final bool summoned;
  final LiteCompanion? companion;
  final int ownerId;
  final int id;
  double? expiresAfter;
  final int? recruitedFloor;
  final double damageScale;
  double cooldown = .35;
  double downRemaining = 0;
  bool corrupted = false;
  final stride = LiteStride();
  Point<double> _poseAim = const Point(1, 0);
  double _swing = 0;
  Point<double> get poseAim => _poseAim;
  double get swing => _swing;

  bool get down => hp <= 0 && downRemaining > 0;

  void _takeDamage(double damage) {
    if (hp <= 0) return;
    hp = max(0, hp - damage);
    if (hp == 0 && expiresAfter == null) {
      downRemaining = LiteRun.allyRescueWindow;
    }
  }

  Map<String, dynamic> _json({bool includeEffects = false}) => {
    'position': _savePoint(position),
    'hp': hp,
    'maxHp': maxHp,
    'weapon': weapon.name,
    'summoned': summoned,
    if (companion != null) 'companion': companion!.name,
    if (ownerId > 0) 'ownerId': ownerId,
    if (id > 0) 'id': id,
    if (expiresAfter case final remaining?) 'expiresAfter': remaining,
    if (recruitedFloor case final floor?) 'recruitedFloor': floor,
    if (damageScale != 1) 'damageScale': damageScale,
    'cooldown': cooldown,
    'downRemaining': downRemaining,
    if (corrupted) 'corrupted': true,
    if (includeEffects) ...{
      'stride': stride._frame(),
      'poseAim': _savePoint(_poseAim),
      if (_swing > 0) 'swing': _swing,
    },
  };
  static LiteClone _read(Map<String, dynamic> json) =>
      LiteClone(
          _point(json['position']),
          _num(json['hp']),
          _enum(LiteWeapon.values, json['weapon'], LiteWeapon.spadaScudo),
          summoned: json['summoned'] == true,
          companion: LiteCompanion.values
              .where((entry) => entry.name == json['companion'])
              .firstOrNull,
          ownerId: _int(json['ownerId']),
          id: _int(json['id']),
          expiresAfter: json['expiresAfter'] == null
              ? null
              : _num(json['expiresAfter']).clamp(0, LiteRun.maxSummonDuration),
          recruitedFloor: json['recruitedFloor'] is int
              ? _int(json['recruitedFloor'])
              : null,
          damageScale: _num(json['damageScale'], 1).clamp(.5, 4.0),
          maxHp: max(1, _num(json['maxHp'], _num(json['hp'], 1))),
        )
        ..cooldown = _num(json['cooldown'])
        ..stride._restore(json['stride'])
        .._poseAim = json['poseAim'] == null
            ? const Point(1, 0)
            : _point(json['poseAim'])
        .._swing = _num(json['swing']).clamp(0.0, .23)
        ..corrupted = json['corrupted'] == true
        ..downRemaining = _num(json['downRemaining']);
}

class _LiteBanditSkills {
  int rounds = 0;
  bool dodgeReady = false;
  bool shieldRecovered = false;
  double punchCooldown = 0;
  double get punchPose =>
      max(0, punchCooldown - (LiteRun.springCooldown - .24));

  List<Object> get frame => [
    rounds,
    dodgeReady,
    shieldRecovered,
    punchCooldown,
  ];

  void restore(Object? value) {
    if (value is! List || value.length != 4) return;
    rounds = _int(value[0]).clamp(0, LiteRun.banditRifleCost);
    dodgeReady = value[1] == true;
    shieldRecovered = value[2] == true;
    punchCooldown = _num(value[3]).clamp(0.0, LiteRun.springCooldown);
  }
}

class _LiteBlock {
  _LiteBlock({required this.lunar, required this.bonus});
  final bool lunar;
  final int Function() bonus;
  int get _baseCapacity => 100 + bonus();
  bool held = false;
  double _baseWear = 0;
  double _shieldWear = 0;
  bool get worn => _baseWear + _shieldWear > 0;
  List<double> get frame => [_baseWear, _shieldWear];

  int capacity(LiteWeapon weapon) =>
      _baseCapacity +
      (weapon == LiteWeapon.spadaScudo ? (lunar ? 200 : 60) : 0);
  double remaining(LiteWeapon weapon) =>
      capacity(weapon) -
      _baseWear -
      (weapon == LiteWeapon.spadaScudo ? _shieldWear : 0);

  double absorb(LiteWeapon weapon, double damage) {
    final blocked = min(remaining(weapon), damage);
    final base = min(_baseCapacity - _baseWear, blocked);
    _baseWear += base;
    _shieldWear += blocked - base;
    return damage - blocked;
  }

  void recover(LiteWeapon weapon, [double amount = 10]) {
    final base = min(_baseWear, amount);
    _baseWear -= base;
    if (weapon == LiteWeapon.spadaScudo) {
      _shieldWear = max(0, _shieldWear - (amount - base));
    }
  }

  void restore(Object? value) {
    if (value is List && value.length == 2) {
      _baseWear = _num(value[0]).clamp(0.0, _baseCapacity.toDouble());
      _shieldWear = _num(value[1]).clamp(0.0, lunar ? 200.0 : 60.0);
      return;
    }
    final wear = _num(value).clamp(0.0, 160.0);
    _baseWear = min(100, wear);
    _shieldWear = wear - _baseWear;
  }
}

// A null ally in a rescue target represents the Master.
typedef _RescueTarget = ({LiteClone? ally});
typedef LiteRescueStatus = ({double progress, bool paused, bool reload});

LiteRescueStatus? _readRescueStatus(Object? frame) {
  if (frame is! List || frame.length != 3) return null;
  return (
    progress: _num(frame[0]).clamp(0.0, 1.0),
    paused: frame[1] == true,
    reload: frame[2] == true,
  );
}

class _LiteRescue {
  _LiteRescue(this.target, this.reload);

  final _RescueTarget target;
  final bool reload;
  double elapsed = 0;
  double pause = 0;

  LiteRescueStatus get status => (
    progress: elapsed / LiteRun.rescueDuration,
    paused: pause > 0,
    reload: reload,
  );
  List<Object> get frame => [status.progress, status.paused, status.reload];
}

class LiteMimicForm {
  const LiteMimicForm(this.kind, this.maxHp, this.originalHp, this.damage);
  final LiteEnemyKind kind;
  final double maxHp, originalHp, damage;

  List<Object> get frame => [kind.name, maxHp, originalHp, damage];

  static LiteMimicForm? read(Object? data) {
    if (data is! List || data.length != 4) return null;
    final kind = LiteEnemyKind.values
        .where((kind) => kind.name == data[0])
        .firstOrNull;
    if (kind == null || kind.boss || kind.echo) return null;
    return LiteMimicForm(
      kind,
      max(1.0, _num(data[1])),
      max(1.0, _num(data[2])),
      max(1.0, _num(data[3])),
    );
  }
}

class LiteCoopFighter extends LiteClone {
  LiteCoopFighter(
    this.account,
    this.name,
    this.hero,
    super.position,
    super.hp,
    super.weapon, {
    required super.id,
    this.upgrades = const {},
    this.allowGlue = false,
    this.allowMechanicalChicken = false,
  });

  final bool allowGlue;
  final bool allowMechanicalChicken;
  final supply = LiteRestLoadout();
  double _hubCastCooldown = 0;
  double weaponArtCooldown = 0;
  final String account;
  final String name;
  LiteHero hero;
  final _night = _NightKit();
  LiteNightVisual get night => _night;
  final Map<LitePermanentUpgrade, int> upgrades;
  int get permanentDamage => upgrades[LitePermanentUpgrade.danni] ?? 0;
  Point<double> aim = const Point(1, 0);
  Point<double> movement = const Point(0, 0);
  bool firing = false;
  double _inputAge = 1;
  double _protection = 0;
  double _shadowProtection = 0;
  double _dodgeCooldown = 0;
  double _staffCooldown = 0;
  double _bombCooldown = 0;
  double get bombCooldown => _bombCooldown;
  double _dashCooldown = 0;
  double _openCooldown = 0;
  double _plagueFormRemaining = 0;
  bool get plagueForm => _plagueFormRemaining > 0;
  double get plagueSeconds => _plagueFormRemaining;
  LiteMimicForm? _mimic;
  LiteMimicForm? get mimic => _mimic;
  int _teamBlockBonus = 0;
  late final _block = _LiteBlock(
    lunar: hero == LiteHero.cavaliereLunare,
    bonus: () =>
        _teamBlockBonus +
        (upgrades[LitePermanentUpgrade.resistenza] ?? 0) *
            LitePermanentUpgrade.resistenza.points,
  );
  int get maxBlockResistance => _block.capacity(weapon);
  double get blockResistance => _block.remaining(weapon);
  bool get blocking =>
      connected && hp > 0 && _block.held && blockResistance > 0;
  final _bandit = _LiteBanditSkills();
  double get openCooldown => _openCooldown;
  int get level => LiteRun.levelForExperience(experience);
  int get openGrade => LiteRun.openGradeFor(level);
  int get banditRounds => _bandit.rounds;
  bool get banditDodgeReady => _bandit.dodgeReady;
  double get banditPunchPose => _bandit.punchPose;
  double _springPose = 0;
  bool get springPunchActive => _springPose > 0;
  double get springPoseRemaining => _springPose;
  double _dashRemaining = 0;
  double _dashSpeed = 15;
  Point<double> _dashDirection = const Point(0, 0);
  double _windup = 0;
  Point<double> _strike = const Point(0, 0);
  double get attackCooldown => _strike.magnitude > .001 ? cooldown : 0;
  Point<double> get weaponAim => attackCooldown > 0 ? _strike : aim;
  bool get preparingAttack => _windup > 0;
  double get burstRemaining => _dashRemaining;
  Point<double> get burstDirection => _dashDirection;
  bool get isMoving => _dashRemaining > 0 || stride.speed > .03;
  bool _slow = false;
  int arrows = LiteRun.bowCapacity;
  double _reload = 0;
  _LiteRescue? _rescue;
  LiteRescueStatus? _rescueSnapshot;
  LiteRescueStatus? get rescueStatus => _rescue?.status ?? _rescueSnapshot;
  bool restUsed = false;
  @override
  double get maxHp =>
      _mimic?.maxHp ??
      (super.maxHp + (level - 1) * 10) *
          (plagueForm || _night.sanguine > 0 ? 2 : 1);
  double get maxOculum =>
      10.0 + (level - 1) * 2 + (upgrades[LitePermanentUpgrade.oculum] ?? 0);
  double shield = 0;
  double oculum = 10;
  int experience = 0;
  int obser = 0;
  int crystals = 0;
  bool get protected => _protection > 1e-9 || _shadowProtection > 1e-9;
  bool get connected => _inputAge <= 1;

  Map<String, dynamic> _wire({bool includeEffects = false}) => {
    ..._json(includeEffects: includeEffects),
    'account': account,
    if (supply.active) 'supplies': supply.frame,
    if (allowGlue) 'allowGlue': true,
    if (allowMechanicalChicken) 'allowMechanicalChicken': true,
    'name': name,
    'hero': hero.name,
    'baseHp': _baseMaxHp,
    if (upgrades.isNotEmpty) 'upgrades': LitePermanentUpgrade.encode(upgrades),
    if (_shadowProtection > 0) 'shadowProtection': _shadowProtection,
    if (_staffCooldown > 0) 'staffCooldown': _staffCooldown,
    if (_bombCooldown > 0) 'bombCooldown': _bombCooldown,
    if (_openCooldown > 0) 'openCooldown': _openCooldown,
    if (plagueForm) 'plagueForm': _plagueFormRemaining,
    if (_mimic case final form?) 'mimic': form.frame,
    if (_night.active) 'night': _night.frame,
    if (weaponArtCooldown > 0) 'weaponArtCooldown': weaponArtCooldown,
    if (_block.worn) 'blockWear': _block.frame,
    if (includeEffects && blocking) 'blocking': true,
    if (hero == LiteHero.scostubandito) 'banditSkills': _bandit.frame,
    'aim': _savePoint(aim),
    'arrows': arrows,
    if (restUsed) 'restUsed': true,
    if (includeEffects && _rescue != null) 'rescue': _rescue!.frame,
    'shield': shield,
    'protection': _protection,
    'springPose': _springPose,
    if (attackCooldown > 0) 'strike': _savePoint(_strike),
    if (_windup > 0) 'windup': _windup,
    if (_dashRemaining > 0) ...{
      'dashRemaining': _dashRemaining,
      'dashDirection': _savePoint(_dashDirection),
      'dashSpeed': _dashSpeed,
    },
    if (isMoving) 'movement': _savePoint(movement),
    'oculum': oculum,
    'experience': experience,
    'obser': obser,
    'crystals': crystals,
    'connected': connected,
  };

  static LiteCoopFighter _fromWire(
    Map<String, dynamic> data,
    int teamBlockBonus,
  ) {
    final fighter = LiteCoopFighter(
      '${data['account']}',
      '${data['name']}',
      _enum(LiteHero.values, data['hero'], LiteHero.evasore),
      _point(data['position']),
      _num(data['baseHp'], _num(data['maxHp'], 100)),
      _enum(LiteWeapon.values, data['weapon'], LiteWeapon.arco),
      id: _int(data['id']),
      allowGlue: data['allowGlue'] == true,
      allowMechanicalChicken: data['allowMechanicalChicken'] == true,
      upgrades: LitePermanentUpgrade.read(data['upgrades']),
    );
    return fighter
      ..hp = _num(data['hp'])
      ..aim = _point(data['aim'])
      ..cooldown = _num(data['cooldown'])
      ..stride._restore(data['stride'])
      .._windup = _num(data['windup'])
      .._strike = _point(data['strike'])
      .._dashRemaining = _num(data['dashRemaining'])
      .._dashSpeed = _num(data['dashSpeed'], 15)
      .._dashDirection = _point(data['dashDirection'])
      ..movement = _point(data['movement'])
      ..arrows = _int(data['arrows'])
      ..restUsed = data['restUsed'] == true
      .._rescueSnapshot = _readRescueStatus(data['rescue'])
      ..shield = _num(data['shield'])
      ..oculum = _num(data['oculum'])
      .._staffCooldown = _num(data['staffCooldown'])
      .._bombCooldown = _num(data['bombCooldown']).clamp(0.0, 5.5)
      .._openCooldown = _num(data['openCooldown'])
          .clamp(0.0, LiteRun.openRecovery)
      .._plagueFormRemaining = _num(data['plagueForm']).clamp(0.0, 5.0)
      .._mimic = fighter.hero == LiteHero.doppelganger
          ? LiteMimicForm.read(data['mimic'])
          : null
      .._bandit.restore(data['banditSkills'])
      ..weaponArtCooldown = _num(data['weaponArtCooldown'])
          .clamp(0, LiteWeaponArt.weaponArtRecovery)
      .._teamBlockBonus = teamBlockBonus
      .._block.restore(data['blockWear'])
      .._block.held = data['blocking'] == true
      ..experience = _int(data['experience'])
      ..obser = _int(data['obser'])
      ..crystals = _int(data['crystals'])
      .._protection = _num(data['protection'])
      .._shadowProtection = _num(data['shadowProtection']).clamp(0.0, 3.0)
      .._night.restore(data['night'])
      ..supply.restore(data['supplies'])
      .._springPose = _num(data['springPose'])
      .._inputAge = data['connected'] == true ? 0 : 2;
  }
}

class LiteLoot {
  LiteLoot(this.position, this.kind, this.amount, {this.scroll, this.weapon});
  Point<double> position;
  final LiteLootKind kind;
  final int amount;
  final LiteScroll? scroll;
  final LiteWeapon? weapon;
  Map<String, dynamic> _json() => {
    'position': _savePoint(position),
    'kind': kind.name,
    'amount': amount,
    'scroll': scroll?.name,
    if (weapon != null) 'weapon': weapon!.name,
  };
  static LiteLoot _read(Map<String, dynamic> json) => LiteLoot(
    _point(json['position']),
    _enum(LiteLootKind.values, json['kind'], LiteLootKind.obser),
    _int(json['amount']),
    scroll: json['scroll'] == null
        ? null
        : _enum(LiteScroll.values, json['scroll'], LiteScroll.dardo),
    weapon: json['weapon'] == null
        ? null
        : _enum(LiteWeapon.values, json['weapon'], LiteWeapon.falceRunica),
  );
}

class LiteQuest {
  LiteQuest(this.id, this.name, this.target, this.reward, {this.major = false});
  final String id, name;
  final int target, reward;
  final bool major;
  int current = 0;
  bool get complete => current >= target;
  Map<String, dynamic> _json() => {
    'id': id,
    'name': name,
    'target': target,
    'reward': reward,
    'major': major,
    'current': current,
  };
  static LiteQuest _read(Map<String, dynamic> json) => LiteQuest(
    json['id'] as String,
    json['name'] as String,
    _int(json['target']),
    _int(json['reward']),
    major: json['major'] == true,
  )..current = _int(json['current']);
}

/// Deterministic real-time simulation. Visual assets, input and persistence I/O
/// stay outside the simulation. All distances are measured in world metres.
class LiteRun {
  LiteRun({
    required this.seed,
    this.progressId,
    this.allowGlue = false,
    this.allowMechanicalChicken = false,
    required this.hero,
    required LiteWeapon weapon,
    this.difficulty = LiteDifficulty.medio,
    this.biome = LiteBiome.campo,
    int playerCount = 1,
    Map<LitePermanentUpgrade, int> upgrades = const {},
  }) : _rng = _LiteRandom(seed),
       upgrades = Map.unmodifiable(upgrades),
       playerCount = playerCount.clamp(1, maxCoopPlayers),
       _startingBiome = biome,
       weapon = hero.startingWeapon(weapon),
       livesRemaining = difficulty.revives {
    ownedWeapons.add(this.weapon);
    hp = maxHp;
    oculum = maxOculum;
    _startStage();
  }

  final int seed;
  final String? progressId;
  final bool allowGlue;
  bool allowMechanicalChicken;
  bool get hasGlue =>
      allowGlue || achievements.contains(LiteCompanion.goblinColla.unlockKey);
  final groundShots = <LiteGroundShot>[];
  final supply = LiteRestLoadout();
  final fauna = <LiteEnemy>[];
  final _chickenTrial = <int, double>{};
  final _provokedRooms = <int>{};
  final _sparedRooms = <int>{};
  bool restHub = false;
  LiteSolarPhase? solarPhase;
  Point<double>? solarStairs;
  bool get solarCampaign => hero.solar;
  LiteRealm? realm;
  int actRoom = 0;
  int thirdRoom = 0;
  String? _mappedFloor;
  int _mappedSectors = 0;
  Point<double>? _mapWaypoint;
  bool _walking = false;
  double? _arenaEventStart;
  String? _claimedWell;
  final actRelics = <LiteActRelic>[];
  int _actRelicClaims = 0;
  double weaponArtCooldown = 0;
  int _goblinWave = 0;
  String get slimeCreditId => progressId ?? 'legacy-$seed-${hero.name}';
  int slimeKills = 0;
  double get slimeDashCooldown => _night.utility;
  final _night = _NightKit();
  LiteNightVisual get night => _night;
  LiteHero hero;
  final LiteDifficulty difficulty;
  final int playerCount;
  final Map<LitePermanentUpgrade, int> upgrades;
  final _LiteRandom _rng;
  LiteBiome _startingBiome;
  LiteBiome biome;
  LiteFloorLayout floorLayout = LiteFloorLayout.standard;
  LiteArenaTrial? arenaTrial;
  double _trialStart = 0;
  int? get trialSecondsLeft =>
      arenaTrial == LiteArenaTrial.caccia && !stageClear
      ? max(0, (40 - (time - _trialStart)).ceil())
      : null;
  LiteWeapon weapon;
  int stage = 0;
  int level = 1;
  int exp = 0;
  int obser = 0;
  int crystals = 0;
  int ascensionDust = 0;
  int spentOculum = 0;
  int livesRemaining;
  double hp = 100;
  double oculum = 10;
  double shield = 0;
  Point<double> position = _spawn;
  Point<double> aim = const Point(1, 0);
  final List<LiteEnemy> enemies = [];
  final List<LiteProjectile> projectiles = [];
  final List<LiteClone> clones = [];
  final List<LiteCoopFighter> coopFighters = [];
  final List<LiteObstacle> obstacles = [];
  final List<LiteLoot> loot = [];
  final List<LiteCombatImpact> _combatImpacts = [];
  final _burstTraces = <int, LiteBurstTrace>{};
  Iterable<LiteBurstTrace> get burstTraces => _burstTraces.values;
  LiteBurstTrace? burstTraceFor(int fighterId) => _burstTraces[fighterId];
  final Map<LitePowerUp, int> _powerRanks = {};
  final List<LitePowerUp> _powerOffers = [];
  final List<LiteQuest> quests = [];
  final _optionalMissions = <LiteQuest>[];
  Iterable<LiteQuest> get missions => quests.followedBy(_optionalMissions);
  final List<LiteWeapon> ownedWeapons = [];
  final List<int> scrolls = List.filled(LiteScroll.values.length, 0);
  final List<LiteScroll> equippedScrolls = [...LiteScroll.ordinary];
  final Set<LiteScroll> learnedScrolls = {};
  final Set<String> achievements = {};
  final List<int> bossCrystalGrades = [];
  int dodgeCharges = 1;
  int maxDodgeCharges = 1;
  int dodgeLevel = 0;
  double time = 0;
  bool stageClear = false;
  bool eliteDefeated = false;
  bool dead = false;
  bool victorious = false;
  bool shopOpen = false;
  String? _baghestEncounter;
  final _redGrips = <int, int>{};
  bool restUsed = false;
  bool _eliteReleased = false;
  bool _finalBossDefeated = false;
  LiteBeam? _activeBeam;
  int _nextId = 1;
  double _attackCooldown = 0;
  double _windup = 0;
  double _invulnerability = 0;
  double _hitProtectionRemaining = 0;
  double _clashRemaining = 0;
  double _burstTime = 0;
  double _burstSpeed = 0;
  double _dashCooldown = 0;
  double _dodgeRecharge = 0;
  double _springCooldown = 0;
  double _staffCooldown = 0;
  double _bombCooldown = 0;
  double get bombCooldown => _bombCooldown;
  double _openCooldown = 0;
  late final _block = _LiteBlock(
    lunar: hero == LiteHero.cavaliereLunare,
    bonus: () =>
        _power(LitePowerUp.ferroVivo).round() +
        _permanent(LitePermanentUpgrade.resistenza),
  );
  int get maxBlockResistance => _block.capacity(weapon);
  double get blockResistance => _block.remaining(weapon);
  bool get blocking =>
      !finished && !hostDown && _block.held && blockResistance > 0;

  void setBlocking(bool held) {
    _block.held = held && !finished && !hostDown && !shopOpen;
    if (blocking) _windup = 0;
  }

  final _bandit = _LiteBanditSkills();
  double get openCooldown => _openCooldown;
  int get banditRounds => _bandit.rounds;
  bool get banditDodgeReady => _bandit.dodgeReady;
  double get banditPunchPose => _bandit.punchPose;
  double _springPose = 0;
  bool get springPunchActive => _springPose > 0;
  double get springPoseRemaining => _springPose;
  double get burstRemaining => _burstTime;
  Point<double> get burstDirection => _burstDirection;
  final stride = LiteStride();
  static const springRange = 4.2;
  static const springCooldown = 3.4;
  double _scrollCooldown = 0;
  double _plagueFormRemaining = 0;
  bool get plagueForm => _plagueFormRemaining > 0;
  double get plagueSeconds => _plagueFormRemaining;
  LiteMimicForm? _mimic;
  LiteMimicForm? get mimic => _mimic;
  int _arrows = bowCapacity;
  double _reloadRemaining = 0;
  _LiteRescue? _rescue;
  LiteRescueStatus? _rescueSnapshot;
  Point<double> _burstDirection = const Point(0, 0);
  Point<double> _strikeDirection = const Point(1, 0);
  Point<double> _lastMove = const Point(0, 0);
  String message = '';

  static const _spawn = Point<double>(4, 11);
  static const _playerRadius = .42;
  static const schemaVersion = 1;
  static const _campaignVersion = 3;
  static const lateStage = 13;
  static const veyrthStage = 23;
  static const _legacyFinalStage = 13;
  static const campaignRooms = 25;
  static const finalStage = campaignRooms - 1;
  static const secondActEntranceFloor = 11;

  int _lastStage = finalStage;
  bool _legacyVeyrthFinal = false;
  bool _legacyOrdinary23 = false;
  bool get isVeyrthArena =>
      stage == veyrthStage && !_legacyOrdinary23 ||
      isFinalFloor && _legacyVeyrthFinal;
  int get lastStage => _lastStage;
  bool get isFinalFloor => stage == lastStage;
  static const maxCoopPlayers = 6;
  static const finalBeamDuration = 6.0;
  static const finalBeamCoverSeconds = 2.5;
  static const finalSummonInterval = 3.0;
  static const finalSphereCount = 12;
  static const finalSphereWindup = .47;
  static const finalSphereRingRadius = .95;
  static const lifeHitProtection = 1.9;
  static const shieldHitProtection = lifeHitProtection / 2;
  static const combatImpactDuration = .86;
  static const shadowVeilDuration = 3.0;
  static const verdictRadius = 1.26;
  static const clashDashDuration = .26;
  static const _clashWindow = .10;
  static const bowRange = 10.0;
  static const bowCapacity = 12;
  static const reloadDuration = 1.2;
  static const rescueDuration = 1.2;
  static const rescueHitPause = .35;
  static const allyRescueWindow = 12.0;
  static const granSummonDuration = 12.0;
  static const maxSummonDuration = 18.0;
  static const granSummonCost = 5.0;
  static const openRecovery = 8.0;
  static const banditRifleCost = 4;
  static const _banditShield = 8.0;
  static const unlockScostubandito = 'scostubandito-oltre-il-forest-demon';
  static String heroUnlockKey(LiteHero hero) => hero == LiteHero.scostubandito
      ? unlockScostubandito
      : 'eroe-${hero.name}';
  static int levelForExperience(int experience) {
    // A level n needs 45*n EXP, so the totals are triangular.
    return ((1 + sqrt(1 + 8 * max(0, experience) / 45)) / 2).floor();
  }

  static int openGradeFor(int level) => level >= 6
      ? 3
      : level >= 3
      ? 2
      : 1;
  static double openRecoveryFor(int grade) => openRecovery + 1 - grade;
  int get openGrade => openGradeFor(level);

  Set<LiteHero> unlockedHeroesFor(
    LiteHero playedHero, {
    String? guestAccount,
  }) => {
    if (guestAccount != null &&
        achievements.contains(
          LiteFauna._mechanicalChickenGuestKey(guestAccount),
        ))
      LiteHero.polloMeccanico,
    for (final character in LiteHero.values)
      if (character != LiteHero.granScostumato &&
          (character != LiteHero.polloMeccanico || guestAccount == null) &&
          character.unlockHint != null &&
          achievements.contains(heroUnlockKey(character)))
        character,
    if (stage > 3 && !solarCampaign) LiteHero.luce,
    if (stage > 9 && !solarCampaign) LiteHero.ombra,
    if (victorious) LiteHero.veyrth,
    if (victorious && difficulty.index >= LiteDifficulty.facile.index)
      LiteHero.cavaliereLunare,
    if (slimeKills >= 10) LiteHero.slimeBlu,
    if (playedHero == LiteHero.doppelganger) LiteHero.doppelganger,
    if (victorious && playedHero == LiteHero.scostubandito)
      LiteHero.granScostumato,
  };
  static const sigilFloors = [0, 3, 6, 9, 12, 13, 15, 18, 21, finalStage];
  static const staffShockRadius = 2.6;
  static const staffShockInterval = .86;
  static const staffShockSlow = .50;
  static const staffShockFlash = .16;
  static const rescueRadius = 1.8;
  static const rescueHealthFraction = .30;
  static const magicBonus = .15;
  static const healChance = .50;
  static const healFraction = .06;
  static const cloneFraction = .02;
  static const potionPrice = 12;
  static const weaponPrice = 28;
  static const posteaWeaponPrice = 42;
  static const dodgeUpgradePrice = 32;

  double get width => 34;
  double get monsterLifeMultiplier =>
      1 + (playerCount - 1) * difficulty.partyLifeStep;
  static int enemyLifeBonusAt(int floor, {bool late = true}) => floor < 3
      ? 0
      : 15 +
            (floor - 3) * 2 +
            (late && floor >= lateStage ? 24 + floor - lateStage : 0);
  static int enemyDamageBonusAt(int floor, {bool late = true}) =>
      floor < 3 ? 0 : 12 + (floor - 3) + (late && floor >= lateStage ? 14 : 0);
  static int arenaSpeedBonusAt(int floor) => max(0, floor ~/ 3) * 10;
  int get arenaSpeedBonus =>
      arenaSpeedBonusAt(
        inActTwo ? min(secondActEntranceFloor + 1, stage + actRoom) : stage,
      ) +
      (inThirdAct ? thirdRoom ~/ 3 * 5 : 0);

  double get arenaSpeed => 1 + arenaSpeedBonus / 100;

  double get _floorDamageScale =>
      1 + enemyDamageBonusAt(stage, late: !_legacyVeyrthFinal) / 100;
  static ({int life, int damage}) challengeBonus(
    int floor,
    LiteEnemyKind kind,
  ) {
    if (floor < 3) return (life: 0, damage: 0);
    if (kind == LiteEnemyKind.veyrth) return (life: 30, damage: 18);
    if (kind == LiteEnemyKind.arconte) return (life: 38, damage: 24);
    if (kind.boss) return (life: 25, damage: 15);
    if (kind.elite) return (life: 20, damage: 10);
    return (life: 0, damage: 0);
  }

  double _challengeDamageScale(LiteEnemyKind kind) =>
      1 + challengeBonus(stage, kind).damage / 100;
  bool get hostDown => hp <= 0 && playerCount > 1;
  double get height => 22;
  int _permanent(LitePermanentUpgrade upgrade) => _profileBonus(upgrade, null);
  double get maxHp =>
      _mimic?.maxHp ??
      (100.0 +
              (level - 1) * 10 +
              _power(LitePowerUp.cuore) +
              _permanent(LitePermanentUpgrade.vita)) *
          (plagueForm || _night.sanguine > 0 ? 2 : 1);
  double get maxOculum =>
      10.0 + (level - 1) * 2 + _permanent(LitePermanentUpgrade.oculum);
  double get weaponDamage => _damageFor(weapon);
  double get verdictDamage =>
      (6 + weaponDamage * .42 + (maxHp - 100) * .018) *
      difficulty.enemyStrength;
  double _weaponRangeScale([LiteCoopFighter? fighter]) =>
      1 +
      _power(LitePowerUp.occhioLungo) +
      _profileBonus(LitePermanentUpgrade.portata, fighter) / 100;

  double weaponReach(LiteWeapon item, [LiteCoopFighter? fighter]) =>
      item.range * _weaponRangeScale(fighter);

  static const _pickupRadius = .85;
  static const _baseObserPull = 1.6;
  static const _obserPullSpeed = 14.0;

  double obserPullRadius([LiteCoopFighter? fighter]) =>
      _baseObserPull +
      _power(LitePowerUp.irideVorace) +
      _profileBonus(LitePermanentUpgrade.richiamo, fighter) / 100;

  double _extraStartingShield([LiteCoopFighter? fighter]) =>
      _power(LitePowerUp.pelleRunica) +
      _profileBonus(LitePermanentUpgrade.scudo, fighter);

  int _profileBonus(LitePermanentUpgrade upgrade, LiteCoopFighter? fighter) =>
      ((fighter?.upgrades ?? upgrades)[upgrade] ?? 0) * upgrade.points;

  LiteCoopFighter? _coopFighterById(int? id) => id == null
      ? null
      : coopFighters.where((fighter) => fighter.id == id).firstOrNull;

  double _power(LitePowerUp power) => power.valueAt(powerRank(power));
  int powerRank(LitePowerUp power) => _powerRanks[power] ?? 0;
  Iterable<LitePowerUp> get powerOffers => _powerOffers;
  Iterable<LitePowerUp> get activePowers => _powerRanks.keys;

  bool choosePowerUp(LitePowerUp power) {
    final rank = powerRank(power);
    if (finished ||
        !_powerOffers.contains(power) ||
        rank >= LitePowerUp.maxRank) {
      return false;
    }
    _powerOffers.clear();
    _grantPower(power);
    return true;
  }

  void _grantPower(LitePowerUp power) {
    final rank = powerRank(power);
    final previousMax = maxHp;
    _powerRanks[power] = rank + 1;
    if (power == LitePowerUp.pelleRunica) {
      final gained = power.valueAt(rank + 1) - power.valueAt(rank);
      if (!hostDown) shield += gained;
      for (final fighter in coopFighters) {
        if (fighter.hp > 0) fighter.shield += gained;
      }
    }
    if (power == LitePowerUp.ferroVivo) {
      for (final fighter in coopFighters) {
        fighter._teamBlockBonus = _power(power).round();
      }
    }
    if (!hostDown) hp += maxHp - previousMax;
    message = '${power.label} · Grado ${rank + 1}/${LitePowerUp.maxRank}';
  }

  void _offerPowers() {
    final eligible = [
      for (final power in LitePowerUp.values)
        if ((playerCount == 1 || power.shared) &&
            powerRank(power) < LitePowerUp.maxRank)
          power,
    ];
    final themed = _featuredPower(biome, _trialEarned ? arenaTrial : null);
    // Loot and enemy behavior keep their own random sequence.
    final offerRng = _LiteRandom(
      seed ^ (stage + 1) * 8191 ^ thirdRoom * 283 ^ actRoom * 67,
    );
    _powerOffers.clear();
    final firstPowers = stage == 0 && campPatrols
        ? [
            themed,
            LitePowerUp.schegge,
            LitePowerUp.ferroVivo,
            LitePowerUp.occhioLungo,
          ]
        : [themed];
    for (final power in firstPowers) {
      if (eligible.remove(power)) _powerOffers.add(power);
      if (_powerOffers.length == 3) break;
    }
    while (eligible.isNotEmpty && _powerOffers.length < 3) {
      _powerOffers.add(eligible.removeAt(offerRng.nextInt(eligible.length)));
    }
  }

  int get restarts => difficulty.revives - livesRemaining;
  bool get intangible => _invulnerability > 1e-9;
  bool get clashDashing => _clashRemaining > 1e-9;
  bool get invulnerable => intangible || _hitProtectionRemaining > 1e-9;
  double get hitProtectionRemaining => _hitProtectionRemaining;
  Iterable<LiteCombatImpact> get combatImpacts => _combatImpacts.where(
    (effect) => effect.target != LiteImpactTarget.defeat,
  );
  Iterable<LiteCombatImpact> get defeats => _combatImpacts.where(
    (effect) => effect.target == LiteImpactTarget.defeat,
  );
  bool get finished => dead || victorious;
  LiteEncounter get encounter => _encounterFor(stage);
  LiteBeam? get activeBeam => _activeBeam;

  Point<double> finalBeamPreviewEnd(LiteEnemy boss) {
    final aim = _unit(position - boss.position);
    final direction = aim == const Point<double>(0, 0)
        ? const Point<double>(-1, 0)
        : aim;
    var distance = _boundBeam(boss.position, direction);
    for (final wall in obstacles) {
      distance = min(
        distance,
        _beamCoverDistance(boss.position, direction, wall, distance),
      );
    }
    return boss.position + direction * distance;
  }

  static LiteEncounter encounterAt(int floor) => switch (floor) {
    0 || 6 || 12 || 18 => LiteEncounter.elite,
    3 || 9 || 15 || 21 || veyrthStage => LiteEncounter.boss,
    finalStage => LiteEncounter.finalBoss,
    _ => LiteEncounter.ordinary,
  };

  LiteEncounter _encounterFor(int floor) {
    if (floor == lastStage) return LiteEncounter.finalBoss;
    if (floor == veyrthStage && _legacyOrdinary23)
      return LiteEncounter.ordinary;
    return encounterAt(floor);
  }

  List<LiteBiome> get routeBiomes =>
      LiteBiome.offers(seed ^ ((stage + 1) * 29063), avoid: biome);

  LiteFloorPreview? previewNextFloor(LiteBiome destination) {
    if (finished || stage >= lastStage) return null;
    final floor = stage + 1;
    final encounter = _encounterFor(floor);
    final bossArena =
        encounter == LiteEncounter.finalBoss || floor == veyrthStage;
    final trial = _trialFor(floor, destination);
    final count = bossArena ? 0 : _openingEnemyCount(floor, trial);
    final power = _featuredPower(destination, trial);
    return LiteFloorPreview(
      floor: floor,
      biome: destination,
      encounter: encounter,
      layout: _layoutFor(floor, destination),
      openingEnemies: count,
      enemyKinds: List.unmodifiable({
        for (var i = 0; i < count; i++)
          _openingEnemyKind(destination, i, floor),
      }),
      special: encounter == LiteEncounter.ordinary ? null : _specialKind(floor),
      rest: _hasRestAt(floor),
      featuredPower:
          encounter != LiteEncounter.finalBoss &&
              powerRank(power) < LitePowerUp.maxRank
          ? power
          : null,
      trial: trial,
    );
  }

  LitePowerUp _featuredPower(LiteBiome location, LiteArenaTrial? trial) =>
      trial?.power ??
      (playerCount > 1
          ? switch (location) {
              LiteBiome.campo => LitePowerUp.braci,
              LiteBiome.foresta || LiteBiome.dungeon => LitePowerUp.riflusso,
              LiteBiome.postea || LiteBiome.deserto => LitePowerUp.risonanza,
              LiteBiome.orea => LitePowerUp.riflusso,
            }
          : switch (location) {
              LiteBiome.campo => LitePowerUp.lama,
              LiteBiome.foresta => LitePowerUp.passo,
              LiteBiome.dungeon => LitePowerUp.cuore,
              LiteBiome.postea || LiteBiome.deserto => LitePowerUp.prisma,
              LiteBiome.orea => LitePowerUp.condotto,
            });

  LiteArenaTrial? _trialFor(int floor, LiteBiome destination) {
    if (floor < 2 || _encounterFor(floor) != LiteEncounter.ordinary)
      return null;
    final roll = _LiteRandom(seed ^ (floor + 1) * 18751);
    if (roll.nextInt(LiteBiome.values.length) != destination.index) return null;
    return LiteArenaTrial.values[roll.nextInt(LiteArenaTrial.values.length)];
  }

  bool get _trialEarned =>
      arenaTrial != null &&
      (arenaTrial != LiteArenaTrial.caccia || time - _trialStart <= 40);

  LiteFloorLayout _layoutFor(int floor, LiteBiome location) =>
      floor == lastStage || floor == veyrthStage
      ? LiteFloorLayout.standard
      : location == LiteBiome.postea
      ? LiteFloorLayout.montaggio
      : LiteFloorLayout.values[(seed.abs() + floor * 2 + location.index) % 3];

  int _openingEnemyCount(int floor, LiteArenaTrial? trial) =>
      solarCampaign && floor == 8
      ? 6
      : min(7, 3 + floor ~/ 2) + (trial == LiteArenaTrial.battuta ? 2 : 0);

  LiteEnemyKind _openingEnemyKind(LiteBiome location, int order, int floor) {
    if (solarCampaign) {
      if (floor == 8) {
        if (order == 0) return LiteEnemyKind.custodeLunare;
        if (order <= 2) return LiteEnemyKind.eliteLunare;
        return LiteEnemyKind.guardiaLunare;
      }
      if (floor > 4 && order % 4 == 2) return LiteEnemyKind.eliteLunare;
      return order % 3 == 1
          ? LiteEnemyKind.lupoLunare
          : LiteEnemyKind.guardiaLunare;
    }
    return switch (location) {
      LiteBiome.campo => LiteEnemyKind.scostubandito,
      LiteBiome.foresta =>
        floor > 0 && order % 3 == 1
            ? LiteEnemyKind.lupoLunare
            : LiteEnemyKind.babyForestDemon,
      LiteBiome.dungeon =>
        floor > 0 && order % 3 == 2
            ? LiteEnemyKind.gablyn
            : LiteEnemyKind.slime,
      LiteBiome.deserto => LiteEnemyKind.rasvyr,
      LiteBiome.orea => LiteEnemyKind.orbryx,
      LiteBiome.postea =>
        order.isEven ? LiteEnemyKind.ragnoSaldatore : LiteEnemyKind.dronePostea,
    };
  }

  bool get finalBossTangible {
    var bossAlive = false;
    for (final enemy in enemies) {
      if (enemy.hp <= 0) continue;
      if (enemy.kind == LiteEnemyKind.minionVeyrth) return false;
      if (enemy.kind == LiteEnemyKind.veyrth) bossAlive = true;
    }
    return bossAlive;
  }

  LiteFinalBossPhase get finalBossPhase {
    if (victorious) return LiteFinalBossPhase.defeated;
    if (dead ||
        !isVeyrthArena ||
        !enemies.any(
          (enemy) => enemy.kind == LiteEnemyKind.veyrth && enemy.hp > 0,
        )) {
      return LiteFinalBossPhase.inactive;
    }
    final tangible = finalBossTangible;
    return _activeBeam == null
        ? (tangible
              ? LiteFinalBossPhase.tangible
              : LiteFinalBossPhase.intangible)
        : (tangible
              ? LiteFinalBossPhase.beamTangible
              : LiteFinalBossPhase.beamIntangible);
  }

  bool get preparingAttack => _windup > 0;
  Point<double> get weaponAim =>
      clashDashing || _attackCooldown > 0 ? _strikeDirection : aim;
  bool get isMoving => stride.speed > .03 || _burstTime > 0;
  double get attackCooldown => _attackCooldown;
  int get arrows => _arrows;
  bool get reloading => _reloadRemaining > 0;
  bool get rescuing => _rescue != null;
  bool get reloadingDuringRescue => _rescue?.reload ?? false;
  bool get rescueInterrupted => (_rescue?.pause ?? 0) > 0;
  double get rescueProgress => (_rescue?.elapsed ?? 0) / rescueDuration;
  LiteRescueStatus? get rescueStatus => _rescue?.status ?? _rescueSnapshot;
  LiteClone? get fallenAllyNearby => _nearbyRescueTarget(null)?.ally;

  bool canRescueNearby([LiteCoopFighter? fighter]) =>
      !finished &&
      !shopOpen &&
      (fighter == null ? !hostDown : fighter.hp > 0) &&
      _nearbyRescueTarget(fighter) != null;

  _RescueTarget? _nearbyRescueTarget(LiteCoopFighter? fighter) {
    final from = fighter?.position ?? position;
    _RescueTarget? nearest;
    var nearestDistance = rescueRadius * rescueRadius;
    void consider(LiteClone? ally, Point<double> at) {
      final distance = _distanceSquared(from, at);
      if (distance > nearestDistance || _lineBlocked(from, at)) return;
      nearestDistance = distance;
      nearest = (ally: ally);
    }

    for (final ally in clones) {
      if (ally.down) consider(ally, ally.position);
    }
    for (final ally in coopFighters) {
      if (ally != fighter && ally.hp <= 0 && ally.connected) {
        consider(ally, ally.position);
      }
    }
    if (fighter != null && hostDown) consider(null, position);
    return nearest;
  }

  bool get canOpenShop =>
      !finished &&
      !hostDown &&
      !inActTwo &&
      !inThirdAct &&
      !inSolarDungeon &&
      !restHub &&
      (stageClear || campPatrols && stage == 0) &&
      _distance(position, shopPosition) < 2;
  bool get hasPortalNearby =>
      !finished &&
      (inThirdAct
          ? thirdRoom < LiteThirdAct.rooms.length
          : stage < lastStage) &&
      stageClear &&
      _distance(position, portalPosition) < 2;
  bool get coopPortalOpen =>
      !finished &&
      stageClear &&
      (inThirdAct
          ? thirdRoom < LiteThirdAct.rooms.length
          : stage < lastStage) &&
      !shopOpen;
  bool get usesSubArena =>
      restHub || inActTwo || inThirdAct || inSolarDungeon || goblinCamp;
  String get inputArena => [
    stage,
    if (restHub) 'rest',
    if (solarPhase != null) solarPhase!.name,
    if (realm != null) ...[realm!.name, actRoom],
    if (inThirdAct) ...['atto-iii', thirdRoom],
    if (goblinCamp) 'goblin',
  ].join(':');
  Point<double> get portalPosition => const Point(30, 11);
  Point<double> get shopPosition => const Point(5, 5);
  Point<double> get restPosition => const Point(5, 16);
  bool _hasRestAt(int floor) => floor < lastStage && floor % 3 == 0;
  bool get hasRest =>
      restHub ||
      (inThirdAct
          ? thirdRoom < LiteThirdAct.rooms.length && thirdRoom % 3 == 0
          : !inActTwo && !inSolarDungeon && _hasRestAt(stage));
  bool get canRest => canUseRest();

  bool canUseRest([LiteCoopFighter? fighter]) =>
      stageClear &&
      hasRest &&
      !finished &&
      (fighter == null
          ? !restUsed && !hostDown
          : !fighter.restUsed && fighter.hp > 0 && fighter.connected) &&
      (fighter?.position ?? position).distanceTo(restPosition) < 2;

  void _healFighter(double amount, [LiteCoopFighter? fighter]) {
    final previous = fighter?.hp ?? hp;
    final maximum = fighter?.maxHp ?? maxHp;
    if (previous <= 0 || amount <= 0) return;
    final after = min(maximum, previous + amount);
    if (fighter == null) {
      hp = after;
    } else {
      fighter.hp = after;
    }
    final shared = (after - previous) * .30;
    if (shared <= 0) return;
    for (final companion in clones) {
      if (companion.ownerId == (fighter?.id ?? 0) &&
          companion.companion != null &&
          companion.hp > 0) {
        companion.hp = min(companion.maxHp, companion.hp + shared);
      }
    }
  }

  bool useRest([LiteCoopFighter? fighter]) {
    if (!canUseRest(fighter)) return false;
    if (fighter != null) {
      _healFighter(fighter.maxHp * .50, fighter);
      fighter
        ..restUsed = true
        ..oculum = min(
          fighter.maxOculum,
          fighter.oculum + fighter.maxOculum * .25,
        );
      return true;
    }
    restUsed = true;
    _healFighter(maxHp * .50);
    oculum = min(maxOculum, oculum + maxOculum * .25);
    message = 'Ristoro · Recuperi il 50% della Vita e il 25% di Oculum.';
    return true;
  }

  Iterable<LiteWeapon> get shopWeapons => biome == LiteBiome.postea
      ? LiteWeapon.values.where(
          (weapon) =>
              !weapon.isBossLoot && weapon != LiteWeapon.fucileScostubandito,
        )
      : LiteWeapon.starters;

  int priceForWeapon(LiteWeapon item) =>
      campPatrols && stage == 0 && !stageClear && item == LiteWeapon.spadaScudo
      ? 12
      : item.isPostea
      ? posteaWeaponPrice
      : weaponPrice;

  bool canBuyWeapon(LiteWeapon item) =>
      hero != LiteHero.doppelganger &&
      shopOpen &&
      shopWeapons.contains(item) &&
      obser >= priceForWeapon(item) &&
      !ownedWeapons.contains(item);

  static const secretCache = Point<double>(5.5, 1.8);
  String get _secretRoomKey =>
      'sala-segreta:${inActTwo || inThirdAct ? inputArena : stage}';
  bool get secretRoomRevealed =>
      !restHub && !inSolarDungeon && achievements.contains(_secretRoomKey);

  bool get hasSecretRoom {
    if (restHub || inSolarDungeon || goblinCamp) return false;
    if (inThirdAct) {
      final index = thirdRoom - 1;
      return index % 6 == _secretSlot(57199, index ~/ 6, 6);
    }
    if (inActTwo) {
      return actRoom - 1 ==
          _secretSlot(12163, realm!.index, LiteSecondAct.actTwoRooms);
    }
    if (isFinalFloor) return false;
    final group = stage ~/ 6;
    final roomCount = min(6, lastStage - group * 6);
    return stage % 6 == _secretSlot(41507, group, roomCount);
  }

  int _secretSlot(int salt, int group, int count) {
    final roll = _LiteRandom(seed ^ ((group + 1) * salt))
      ..nextDouble()
      ..nextDouble();
    return roll.nextInt(count);
  }

  void _placeSecretRoom() {
    if (!hasSecretRoom || secretRoomRevealed) return;
    obstacles.addAll([
      LiteObstacle(3.0, 0, .6, 4.2),
      LiteObstacle(7.4, 0, .6, 4.2),
      LiteObstacle(
        3.6,
        3.6,
        3.8,
        .6,
        breakable: true,
        secretGate: true,
        hp: 22,
      ),
    ]);
  }

  void _startStage() {
    _baghestEncounter = null;
    _redGrips.clear();
    _arenaEventStart = time;
    if (stage > 0 && supply.fed(LiteRestItem.spiedino, stage)) {
      _block.recover(weapon, 18);
    }
    for (final fighter in coopFighters) {
      if (fighter.supply.fed(LiteRestItem.spiedino, stage)) {
        fighter._block.recover(fighter.weapon, 18);
      }
    }
    restHub = false;
    solarPhase = null;
    solarStairs = null;
    realm = null;
    actRoom = 0;
    supply._foodUntil.removeWhere((_, until) => until < stage);
    _goblinWave = 0;
    endRescue();
    _block.held = false;
    enemies.clear();
    fauna.clear();
    _chickenTrial.clear();
    projectiles.clear();
    groundShots.clear();
    _combatImpacts.clear();
    _burstTraces.clear();
    _powerOffers.clear();
    _hitProtectionRemaining = 0;
    _clashRemaining = 0;
    loot.clear();
    obstacles.clear();
    quests.clear();
    _optionalMissions.clear();
    position = _spawn;
    stride._reset();
    _activeBeam = null;
    _finalBossDefeated = false;
    aim = const Point(1, 0);
    clones.removeWhere(
      (clone) =>
          clone.expiresAfter != null ||
          clone.companion == LiteCompanion.lupoAlleato,
    );
    for (final clone in clones) {
      clone.position = _spawn + const Point<double>(0, 1.15);
      clone.stride._reset();
      clone._swing = 0;
    }
    for (var i = 0; i < coopFighters.length; i++) {
      final fighter = coopFighters[i];
      fighter.position = _coopSpawn(i);
      fighter.stride._reset();
      if (fighter.hp <= 0) fighter.hp = fighter.maxHp * .3;
      fighter._bandit.shieldRecovered = false;
      fighter._block.held = false;
      fighter._rescue = null;
      fighter.restUsed = false;
      fighter.supply._foodUntil.removeWhere((_, until) => until < stage);
      fighter.shield =
          _startingShield(fighter.hero, fighter.weapon) +
          _extraStartingShield(fighter) +
          fighter.supply.rank(LiteRestItem.bastione) * 9;
    }
    if (hostDown) hp = maxHp * .3;
    _lastMove = const Point(0, 0);
    stageClear = eliteDefeated = _eliteReleased = shopOpen = false;
    restUsed = false;
    _burstTime = _attackCooldown = _windup = _springPose = 0;
    _bandit.shieldRecovered = false;
    shield =
        _startingShield(hero, weapon) +
        _extraStartingShield() +
        (_power(LitePowerUp.cuore) / 3).ceil() +
        supply.rank(LiteRestItem.bastione) * 9;
    floorLayout = _layoutFor(stage, biome);
    arenaTrial = _trialFor(stage, biome);
    _trialStart = time;
    _openFloorMap();
    if (isVeyrthArena || isFinalFloor) {
      _startBossArena(_specialKind(stage));
      return;
    }
    if (biome == LiteBiome.campo) {
      obstacles.addAll([
        LiteObstacle(11, 4 + _rng.nextDouble(), 2.1, 2.2),
        LiteObstacle(15.5, 14 + _rng.nextDouble(), 2.6, 1.8),
        LiteObstacle(22, 7, 2.4, 2.1, breakable: true),
        LiteObstacle(25, 16, 3, 1.2),
      ]);
    } else if (biome == LiteBiome.foresta) {
      obstacles.addAll([
        LiteObstacle(8, 3 + _rng.nextDouble(), 2.4, 3.2),
        LiteObstacle(11, 14.5 + _rng.nextDouble(), 2.1, 3.6),
        LiteObstacle(18, 16.5, 2.8, 2.1, breakable: true),
        LiteObstacle(27, 4, 2.8, 3.4),
      ]);
    } else if (biome == LiteBiome.dungeon) {
      obstacles.addAll([
        LiteObstacle(
          11,
          1,
          1.3,
          mapHasShortcut ? 3.4 : 7.2,
          fixedMap: mapHasShortcut,
        ),
        if (mapHasShortcut) LiteObstacle(11, 6.74, 1.3, 1.46, fixedMap: true),
        LiteObstacle(11, 14, 1.3, 7),
        LiteObstacle(18, 9.5, 3, 2.7),
        LiteObstacle(25, 1, 1.25, 6.8),
        LiteObstacle(25, 14, 1.25, 7),
        LiteObstacle(22, 15 + _rng.nextDouble(), 1.4, 2.5, breakable: true),
      ]);
    } else if (biome == LiteBiome.deserto) {
      obstacles.addAll([
        LiteObstacle(8.2, 3.1, 2.8, 2.2),
        LiteObstacle(13.5, 14.6, 2.3, 3.0),
        LiteObstacle(18.2, 6.3, 3.0, 2.5, breakable: true),
        LiteObstacle(25.6, 11.3, 2.5, 3.4, breakable: true),
      ]);
    } else if (biome == LiteBiome.orea) {
      obstacles.addAll([
        LiteObstacle(8.7, 5.0, 2.6, 2.2, breakable: true),
        LiteObstacle(10.8, 14.2, 3.0, 2.9),
        LiteObstacle(19.1, 10.2, 3.5, 2.1, breakable: true),
        LiteObstacle(25.0, 3.5, 2.8, 2.5),
        LiteObstacle(25.5, 16.2, 2.2, 2.3),
      ]);
    } else {
      // The service corridor stays open between the foundry's press housings.
      obstacles.addAll([
        LiteObstacle(8.8, 2.0, 4.2, 4.5),
        LiteObstacle(8.8, 15.6, 4.2, 4.4),
        LiteObstacle(15.1, 5.1 + _rng.nextDouble(), 2.3, 2.8, breakable: true),
        LiteObstacle(17.5, 14.2, 3.1, 2.8, breakable: true),
        LiteObstacle(23.6, 1.8, 3.3, 3.2),
        LiteObstacle(26.9, 15.1, 1.7, 4.2),
      ]);
    }
    if (stage > 0) _varyFloorCover();
    _placeLayoutCover();
    _placeSecretRoom();
    final count = _openingEnemyCount(stage, arenaTrial);
    final formation = stage >= 3 ? floorLayout.index % 3 : 0;
    for (var i = 0; i < count; i++) {
      final lane = 4.5 + 12.5 * (i / max(1, count - 1));
      final y = stage == 0 ? lane : lane + (_rng.nextDouble() - .5) * 2.1;
      final kind = _openingEnemyKind(biome, i, stage);
      final column = switch (formation) {
        1 => i.isEven ? 19.0 : 25.5,
        2 => 21.0 + (1 - (y - 11).abs() / 7) * 4,
        _ => 19.0,
      };
      final spread = formation == 0 ? 7.0 : 1.5;
      final candidate = Point(column + _rng.nextDouble() * spread, y);
      _spawnEnemy(
        kind,
        campPatrols && stage == 0 && i == 0
            ? const Point(12.3, 13.15)
            : candidate,
      );
    }
    quests.addAll([
      LiteQuest(
        'p$stage:${biome.name}:prima-ondata',
        'Supera la prima ondata',
        count,
        4,
      ),
      LiteQuest('p$stage:${biome.name}:bottino', 'Raccogli il bottino', 2, 6),
      LiteQuest(
        'p$stage:${biome.name}:conquista',
        switch (encounter) {
          LiteEncounter.elite => 'Abbatti l’élite',
          LiteEncounter.boss => 'Sconfiggi il riflesso',
          _ => 'Conquista il piano',
        },
        1,
        20,
        major: true,
      ),
    ]);
    _populateFauna();
    _placeSolarGate();
    _optionalMissions.add(
      LiteQuest('fauna-$stage', 'Passa oltre lasciando intatta la fauna', 1, 8),
    );
    if (obstacles.any((wall) => wall.solarGate)) {
      _optionalMissions.add(
        LiteQuest(
          'scale-$stage',
          'Scopri il passaggio sotto il riparo frangibile',
          1,
          10,
        ),
      );
    }
    if (solarCampaign) {
      _optionalMissions.add(
        LiteQuest(
          'lunare-$stage',
          'Assorbi tre attacchi dietro al blocco',
          3,
          12,
        ),
      );
    }
    final layout = floorLayout.label;
    message =
        'Piano $stage · ${biome.label}${layout.isEmpty ? '' : ' · $layout'}'
        '${arenaTrial == null ? '' : ' · ${arenaTrial!.label}'}';
    if (solarCampaign) {
      message = stage == 8
          ? 'Assedio lunare · Custode, due Elité e tre Guardie.'
          : 'Campagna del Sole · $message · Pattuglie lunari.';
    }
  }

  void _placeLayoutCover() {
    switch (floorLayout) {
      case LiteFloorLayout.standard:
        return;
      case LiteFloorLayout.traversata:
        obstacles.addAll([
          LiteObstacle(13, 6.6, 1.1, 3.1),
          LiteObstacle(21, 12.3, 1.3, 3.7, breakable: true),
        ]);
      case LiteFloorLayout.cerchio:
        obstacles.addAll([
          LiteObstacle(13.4, 10.5, 1.35, 1.7, breakable: true),
          LiteObstacle(19.5, 5.4, 1.6, 1.55, breakable: true),
          LiteObstacle(23.1, 11.4, 1.35, 1.8, breakable: true),
        ]);
      case LiteFloorLayout.montaggio:
        obstacles.addAll([
          LiteObstacle(12.3, 8.1, 1.25, 1.45, breakable: true),
          LiteObstacle(20.5, 12.2, 1.7, 1.52, breakable: true),
          LiteObstacle(25.2, 7.8, 1.25, 1.6, breakable: true),
        ]);
    }
  }

  void _varyFloorCover() {
    final old = List<LiteObstacle>.of(obstacles);
    final delta = (_rng.nextDouble() - .5) * (1.3 + stage * .15);
    obstacles.clear();
    for (var i = 0; i < old.length; i++) {
      final cover = old[i];
      if (cover.fixedMap || cover.mapShortcut) {
        obstacles.add(cover);
        continue;
      }
      final left = (cover.left + (i.isEven ? delta : -delta)).clamp(
        7.1,
        width - cover.width - 2.2,
      );
      final top = stage.isOdd ? height - cover.top - cover.height : cover.top;
      obstacles.add(
        LiteObstacle(
          left,
          top,
          cover.width,
          cover.height,
          breakable: cover.breakable,
          hp: cover.hp,
        ),
      );
    }
    obstacles.add(
      LiteObstacle(
        8.8 + _rng.nextDouble() * 3.2,
        stage.isEven ? 7.45 : 12.75,
        1.05,
        1.3,
        breakable: true,
      ),
    );
  }

  void _startBossArena(LiteEnemyKind boss) {
    final offset = (_rng.nextDouble() - .5) * 1.2;
    obstacles.addAll([
      LiteObstacle(9, 5.5 + offset, 1.6, 2.6, breakable: true),
      LiteObstacle(12.8, 13.6 - offset, 2.2, 2.8, breakable: true),
      LiteObstacle(18.5, 9.35 + offset, 1.3, 3.3, breakable: true),
      LiteObstacle(23, 4.5 - offset, 2.1, 2.4, breakable: true),
      LiteObstacle(24.4, 15.4 + offset, 1.55, 2.4, breakable: true),
    ]);
    final archon = boss == LiteEnemyKind.arconte;
    quests.addAll([
      if (archon)
        LiteQuest('p$stage:breccia', 'Porta l’Arconte alla terza fase', 1, 12)
      else
        LiteQuest('p$stage:evocazioni', 'Disperdi due echi', 2, 4),
      LiteQuest('p$stage:riparo', 'Abbatti un riparo', 1, 6),
      LiteQuest(
        'p$stage:${boss.name}',
        'Sconfiggi ${boss.label}',
        1,
        archon ? 35 : 20,
        major: true,
      ),
    ]);
    _eliteReleased = true;
    _placeSecretRoom();
    _spawnEnemy(boss, const Point(27.8, 11)).cooldown = .75;
    message = archon
        ? 'L’Arconte delle Fratture si risveglia. Evita i segni a terra.'
        : 'Piano $stage · Veyrth. Elimina i suoi echi per renderlo vulnerabile.';
  }

  LiteEnemyKind _specialKind(int floor) {
    if (floor == lastStage) {
      return _legacyVeyrthFinal ? LiteEnemyKind.veyrth : LiteEnemyKind.arconte;
    }
    if (floor == veyrthStage) return LiteEnemyKind.veyrth;
    if (solarCampaign) {
      return switch (floor) {
        6 || 9 || 12 || 15 || 21 => LiteEnemyKind.custodeLunare,
        _ => LiteEnemyKind.eliteLunare,
      };
    }
    switch (floor) {
      case 3:
        return LiteEnemyKind.luce;
      case 9:
        return LiteEnemyKind.ombra;
      case 15:
        return LiteEnemyKind.divoramituBoss;
      case 18:
        return LiteEnemyKind.eliteSolare;
      case 21:
        return LiteEnemyKind.diavolo;
    }
    final rotation = LiteBiome.legacy.contains(_startingBiome)
        ? LiteBiome.legacy
        : LiteBiome.values;
    final habitat =
        rotation[(_startingBiome.index + floor ~/ 6) % rotation.length];
    return switch (habitat) {
      LiteBiome.campo => LiteEnemyKind.granScostumato,
      LiteBiome.foresta => LiteEnemyKind.forestDemon,
      LiteBiome.dungeon => LiteEnemyKind.costrutto,
      LiteBiome.postea => LiteEnemyKind.miruscyrus,
      LiteBiome.deserto => LiteEnemyKind.costrutto,
      LiteBiome.orea => LiteEnemyKind.forestDemon,
    };
  }

  LiteEnemy _spawnEnemy(
    LiteEnemyKind kind,
    Point<double> candidate, {
    double? maxHealth,
  }) {
    final p = _safePoint(candidate, kind.radius, const Point(27.4, 11));
    final maxHp =
        maxHealth ??
        (kind.echo
            ? kind.health.toDouble()
            : (kind.health *
                          difficulty.enemyStrength *
                          (1 + .10 * stage) *
                          (1 +
                              enemyLifeBonusAt(
                                    stage,
                                    late: !_legacyVeyrthFinal,
                                  ) /
                                  100) *
                          (1 + challengeBonus(stage, kind).life / 100) *
                          (arenaTrial == LiteArenaTrial.muraglia ? 1.25 : 1) *
                          monsterLifeMultiplier)
                      .roundToDouble() +
                  (kind == LiteEnemyKind.luce || kind == LiteEnemyKind.ombra
                      ? _power(LitePowerUp.cuore)
                      : 0));
    final enemy = LiteEnemy(_nextId++, kind, p, maxHp);
    if (campPatrols && kind == LiteEnemyKind.scostubandito) {
      enemy.guard = LiteGuard(p);
    }
    if (kind == LiteEnemyKind.ragnoSaldatore) enemy.cooldown = 1.45;
    if (kind == LiteEnemyKind.veyrth) enemy.cooldown = .75;
    if (kind == LiteEnemyKind.luce || kind == LiteEnemyKind.ombra) {
      enemy.mirror = LiteMirrorBuild(
        hero: hero,
        weapon: weapon,
        slots: [...equippedScrolls],
        quantities: [...scrolls],
        learned: {...learnedScrolls},
        oculum: maxOculum,
        damage: weaponDamage * (kind == LiteEnemyKind.luce ? 1.12 : 1),
        shield:
            (weapon == LiteWeapon.spadaScudo ? 6.0 : 0.0) +
            (_power(LitePowerUp.cuore) / 3).ceil(),
        powers: Map.unmodifiable(_powerRanks),
      );
    }
    enemy.cooldown += _rng.nextDouble() * .5;
    enemies.add(enemy);
    return enemy;
  }

  Point<double> _coopSpawn(int index) =>
      _spawn + Point<double>(.85 * (1 + index ~/ 2), index.isEven ? 1 : -1);

  LiteCoopFighter? coopFighter(String account) {
    for (final fighter in coopFighters) {
      if (fighter.account == account) return fighter;
    }
    return null;
  }

  /// The host is first. Guest order is preserved in saves and network frames,
  /// including when a guest disconnects and reconnects.
  int coopPlayerSeat(LiteCoopFighter? guest) =>
      guest == null ? 0 : coopFighters.indexOf(guest) + 1;

  bool addCoopFighter(
    String account,
    String name,
    LiteHero hero,
    LiteWeapon weapon, {
    Map<LitePermanentUpgrade, int> upgrades = const {},
    bool allowGlue = false,
    bool allowMechanicalChicken = false,
  }) {
    if (coopFighters.length >= playerCount - 1 ||
        coopFighter(account) != null ||
        (!stageClear && (stage != 0 || time > 0))) {
      return false;
    }
    final startingWeapon = hero.startingWeapon(weapon);
    coopFighters.add(
      LiteCoopFighter(
          account,
          name,
          hero,
          _coopSpawn(coopFighters.length),
          100.0 +
              (upgrades[LitePermanentUpgrade.vita] ?? 0) *
                  LitePermanentUpgrade.vita.points,
          startingWeapon,
          id: _nextId++,
          allowGlue: allowGlue,
          allowMechanicalChicken: allowMechanicalChicken,
          upgrades: Map.unmodifiable(upgrades),
        )
        .._teamBlockBonus = _power(LitePowerUp.ferroVivo).round()
        ..shield =
            _startingShield(hero, startingWeapon) +
            _power(LitePowerUp.pelleRunica) +
            (upgrades[LitePermanentUpgrade.scudo] ?? 0) *
                LitePermanentUpgrade.scudo.points
        ..oculum = 10.0 + (upgrades[LitePermanentUpgrade.oculum] ?? 0),
    );
    return true;
  }

  static double _startingShield(LiteHero hero, LiteWeapon weapon) =>
      weapon == LiteWeapon.spadaScudo
      ? (hero == LiteHero.cavaliereLunare ? 12 : 6)
      : hero == LiteHero.scostubandito
      ? _banditShield
      : 0;

  void suspendCoopControls() {
    for (final fighter in coopFighters) {
      fighter
        .._inputAge = 2
        ..movement = const Point(0, 0)
        ..firing = false
        .._block.held = false;
      endRescue(fighter);
    }
  }

  bool setCoopControls(
    String account,
    Point<double> move,
    Point<double> target, {
    required bool attack,
    bool dodge = false,
    bool dash = false,
    bool reload = false,
    bool slow = false,
    bool open = false,
    bool rifleSkill = false,
    bool bomb = false,
    bool block = false,
    bool rescue = false,
    bool rest = false,
    bool weaponArt = false,
  }) {
    final fighter = coopFighter(account);
    if (fighter == null ||
        finished ||
        !move.x.isFinite ||
        !move.y.isFinite ||
        !target.x.isFinite ||
        !target.y.isFinite) {
      return false;
    }
    fighter._inputAge = 0;
    if (fighter.hp <= 0 || fighter._night.stun > 0) return false;
    if (gripRemaining(fighter) > 0) {
      fighter.movement = const Point(0, 0);
      fighter.firing = false;
      return true;
    }
    final aim = _unit(target - fighter.position);
    if (aim.magnitude > 0) fighter.aim = aim;
    fighter
      ..movement = _unit(move)
      ..firing = attack
      .._slow = slow;
    if (rest) useRest(fighter);
    if (rescue) {
      if (fighter._rescue == null) beginRescue(fighter);
    } else {
      endRescue(fighter);
    }
    fighter._block.held = block;
    if (fighter.blocking || fighter._rescue != null) {
      fighter._windup = 0;
      fighter.firing = false;
    }
    final talent = dodge && !fighter.blocking && fighter._rescue == null;
    if (open) _useOpen(target, fighter);
    if (weaponArt) useWeaponArt(target, fighter);
    if (rifleSkill) {
      if (fighter.hero == LiteHero.reGoblin) {
        this._raiseByRoyalCall(fighter);
      } else if (fighter.hero == LiteHero.slimeBlu) {
        this._slimeDash(target, fighter);
      } else {
        _armBanditRifle(fighter);
      }
    }
    if (bomb) _throwBanditBomb(target, fighter);
    if (talent &&
        fighter.hero == LiteHero.ashley &&
        fighter._dodgeCooldown <= 0 &&
        fighter._windup <= 0) {
      fighter
        .._dodgeCooldown = springCooldown
        .._springPose = .28;
      _melee(
        fighter.position,
        fighter.aim,
        LiteWeapon.guanti,
        14.0 + 2 * (fighter.level - 1),
        ownerCanHeal: false,
        sourceCloneId: fighter.id,
        reach: springRange,
        minDot: .86,
      );
    }
    if (talent && fighter.hero == LiteHero.duplicatore) {
      final cost = _duplicate(
        fighter.position,
        fighter.aim,
        fighter.weapon,
        fighter.hp,
        fighter.maxHp,
        ownerId: fighter.id,
      );
      fighter.hp -= cost;
    }
    if (talent &&
        fighter.hero == LiteHero.scostubandito &&
        fighter._windup <= 0) {
      _banditPunch(
        fighter.position,
        fighter.aim,
        fighter._bandit,
        fighter.level,
        fighter.id,
      );
    }
    if (talent &&
        (fighter.hero.specialTalent) &&
        fighter.hero != LiteHero.scostubandito) {
      _npcTalent(fighter.aim, fighter);
    }
    if (talent &&
        fighter.hero == LiteHero.evasore &&
        fighter._dodgeCooldown <= 0 &&
        fighter._dashRemaining <= 0) {
      final direction = fighter.movement.magnitude > .01
          ? fighter.movement
          : fighter.aim;
      fighter
        .._dashRemaining = .21
        .._dashSpeed = 15
        .._dashDirection = direction
        .._dodgeCooldown = 3.2
        .._protection = max(fighter._protection, .21);
      _beginBurstTrace(LiteBurstKind.phase, .21, fighter: fighter);
    }
    if (reload &&
        fighter._rescue == null &&
        fighter.weapon == LiteWeapon.arco &&
        fighter.arrows < bowCapacity &&
        fighter._reload <= 0) {
      fighter._reload = reloadDuration;
    }
    if (dash && fighter._dashCooldown <= 0 && fighter._dashRemaining <= 0) {
      fighter
        .._dashRemaining = .19
        .._dashSpeed = 15
        .._dashDirection = fighter.movement.magnitude > .01
            ? fighter.movement
            : fighter.aim
        .._dashCooldown = 1.1;
      _beginBurstTrace(
        fighter._bandit.dodgeReady ? LiteBurstKind.phase : LiteBurstKind.dash,
        fighter._dashRemaining,
        fighter: fighter,
      );
      if (fighter._bandit.dodgeReady) {
        fighter._bandit.dodgeReady = false;
        fighter._protection = max(fighter._protection, fighter._dashRemaining);
      }
    }
    return true;
  }

  void _tickCoop(double elapsed) {
    for (final fighter in coopFighters) {
      fighter._inputAge += elapsed;
      if (!fighter.connected) endRescue(fighter);
      if (fighter.hp <= 0) continue;
      this._tickNight(fighter, elapsed);
      fighter._night.solarMace = max(0, fighter._night.solarMace - elapsed);
      fighter._night.solarMantle = max(0, fighter._night.solarMantle - elapsed);
      this._tickSupply(elapsed, fighter: fighter);
      _tickRelicMana(elapsed, fighter);
      final beforeMove = fighter.position;
      final groundSpeed = this.terrainSpeedAt(fighter.position, enemy: false);
      fighter.cooldown = max(0, fighter.cooldown - elapsed);
      fighter.weaponArtCooldown = max(0, fighter.weaponArtCooldown - elapsed);
      fighter._protection = max(0, fighter._protection - elapsed);
      fighter._shadowProtection = max(0, fighter._shadowProtection - elapsed);
      fighter._dodgeCooldown = max(0, fighter._dodgeCooldown - elapsed);
      fighter._staffCooldown = max(0, fighter._staffCooldown - elapsed);
      fighter._bombCooldown = max(0, fighter._bombCooldown - elapsed);
      fighter._dashCooldown = max(0, fighter._dashCooldown - elapsed);
      fighter._openCooldown = max(0, fighter._openCooldown - elapsed);
      if (fighter.plagueForm) {
        fighter._plagueFormRemaining = max(
          0,
          fighter._plagueFormRemaining - elapsed,
        );
        if (!fighter.plagueForm) fighter.hp /= 2;
      }
      fighter._bandit.punchCooldown = max(
        0,
        fighter._bandit.punchCooldown - elapsed,
      );
      fighter._springPose = max(0, fighter._springPose - elapsed);
      if (fighter._reload > 0) {
        fighter._reload = max(0, fighter._reload - elapsed);
        if (fighter._reload <= 1e-9) fighter.arrows = bowCapacity;
      }
      if (fighter._dashRemaining > 0) {
        final slice = min(elapsed, fighter._dashRemaining);
        fighter._dashRemaining = max(0, fighter._dashRemaining - elapsed);
        fighter.position = _move(
          fighter.position,
          fighter._dashDirection * (fighter._dashSpeed * slice * groundSpeed),
          _playerRadius,
        );
        _recordBurstTrace(fighter.id, fighter.position, fighter._dashRemaining);
      } else if (fighter.connected &&
          fighter._night.stun <= 0 &&
          fighter.movement.magnitude > .01) {
        fighter.position = _move(
          fighter.position,
          fighter.movement *
              ((fighter._slow ? 3.2 : 6.5) *
                  elapsed *
                  (fighter._night.sanguine > 0 ? 2 : 1) *
                  groundSpeed),
          _playerRadius,
        );
      }
      fighter.stride._track(beforeMove, fighter.position, elapsed);
      final item = fighter.weapon;
      if (fighter._night.stun > 0 || fighter._night.bat > 0) continue;
      if (item == LiteWeapon.scettro &&
          fighter.connected &&
          fighter._staffCooldown == 0 &&
          _staffShock(
            fighter.position,
            4.0 + (fighter.level - 1) ~/ 3,
            sourceFighterId: fighter.id,
          )) {
        fighter._staffCooldown = staffShockInterval;
      }
      if (fighter._windup > 0) {
        fighter._windup = max(0, fighter._windup - elapsed);
        if (fighter._windup <= 1e-9) _coopStrike(fighter, fighter._strike);
      } else if (fighter.connected &&
          !fighter.blocking &&
          fighter._rescue == null &&
          fighter.firing &&
          fighter.cooldown <= 0 &&
          (item != LiteWeapon.arco ||
              fighter._night.solarMace > 0 ||
              fighter.arrows > 0 && fighter._reload <= 0)) {
        fighter.firing = false;
        fighter.cooldown = _weaponRecovery(
          item,
          fighter.openCooldown,
          fighter.openGrade,
        );
        if (item == LiteWeapon.arco && fighter._night.solarMace <= 0)
          fighter.arrows--;
        fighter._strike = fighter.aim;
        fighter._windup =
            fighter.hero == LiteHero.doppelganger ||
                fighter._night.solarMace > 0
            ? 0
            : item.chargeSeconds;
        if (fighter.hero == LiteHero.doppelganger)
          fighter.cooldown = fighter._mimic == null ? .64 : .82;
        if (fighter._windup == 0) _coopStrike(fighter, fighter._strike);
      }
    }
  }

  void _coopStrike(LiteCoopFighter fighter, Point<double> direction) {
    if (fighter.hero == LiteHero.guardianoSolare &&
        fighter._night.solarMace > 0) {
      _melee(
        fighter.position,
        direction,
        LiteWeapon.guanti,
        23 + fighter.level * 1.9,
        reach: 2.65,
        minDot: .22,
        ownerCanHeal: false,
        sourceCloneId: fighter.id,
      );
      return;
    }
    if (_animalStrike(
      fighter.hero,
      fighter.position,
      direction,
      fighter.level,
      fighter.id,
    ))
      return;
    if (fighter.hero == LiteHero.slimeBlu &&
        fighter.weapon == LiteWeapon.guanti) {
      _melee(
        fighter.position,
        direction,
        LiteWeapon.guanti,
        9 + fighter.level.toDouble(),
        reach: 2.15,
        minDot: .1,
        ownerCanHeal: false,
        sourceCloneId: fighter.id,
      );
      return;
    }
    if (fighter.hero == LiteHero.doppelganger) {
      _mimicStrike(fighter._mimic, fighter.position, direction, fighter.id);
      return;
    }
    _weaponAction(
      fighter.position,
      direction,
      fighter.weapon,
      (8 +
              fighter.weapon.damageBonus.toDouble() +
              fighter.permanentDamage +
              2 * (fighter.level - 1)) *
          (1 + .04 * fighter.supply.forgeRank(fighter.weapon)) *
          (fighter.hero == LiteHero.cavaliereLunare &&
                  fighter.weapon == LiteWeapon.spadaScudo
              ? 2
              : 1),
      ownerCanHeal: false,
      sourceCloneId: fighter.id,
    );
  }

  Point<double> _enemyAimFrom(
    Point<double> from, {
    bool ignoreBreakable = false,
  }) {
    if (clones.isEmpty && coopFighters.isEmpty) return position;
    Point<double>? visible;
    var visibleDistance = double.infinity;
    var nearest = position;
    var nearestDistance = double.infinity;
    void consider(Point<double> candidate) {
      final distance = _distanceSquared(from, candidate);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = candidate;
      }
      if (distance < visibleDistance &&
          !_lineBlocked(from, candidate, ignoreBreakable: ignoreBreakable)) {
        visibleDistance = distance;
        visible = candidate;
      }
    }

    if (!hostDown) consider(position);
    for (final ally in _damageableAllies) {
      if (ally.hp > 0) consider(ally.position);
    }
    return visible ?? nearest;
  }

  Iterable<LiteClone> get _damageableAllies => coopFighters.isEmpty
      ? clones
      : [...clones, ...coopFighters.where((p) => p.connected)];

  static Point<double> _unit(Point<double> direction) {
    final length = sqrt(_square(direction.x) + _square(direction.y));
    return length <= 1e-9
        ? const Point(0, 0)
        : Point(direction.x / length, direction.y / length);
  }

  static double _distance(Point<double> a, Point<double> b) =>
      sqrt(_distanceSquared(a, b));

  static double _distanceSquared(Point<double> a, Point<double> b) =>
      _square(b.x - a.x) + _square(b.y - a.y);

  bool _blocked(Point<double> p, double r) => _blockedAt(p.x, p.y, r);

  bool _blockedAt(
    double x,
    double y,
    double radius, {
    bool ignoreBreakable = false,
  }) {
    if (x - radius < 0 ||
        y - radius < 0 ||
        x + radius > width ||
        y + radius > height) {
      return true;
    }
    final radiusSquared = radius * radius;
    for (final wall in obstacles) {
      if (ignoreBreakable && wall.breakable) continue;
      if (wall._intersects(x, y, radiusSquared)) return true;
    }
    return false;
  }

  Point<double> _safePoint(Point<double> p, double r, Point<double> fallback) {
    if (!_blocked(p, r)) return p;
    for (final delta in const [
      Point<double>(0, 1.6),
      Point<double>(0, -1.6),
      Point<double>(2, 0),
      Point<double>(-2, 0),
    ]) {
      final next = p + delta;
      if (!_blocked(next, r)) return next;
    }
    return fallback;
  }

  Point<double> _move(Point<double> p, Point<double> offset, double r) {
    final x = p.x + offset.x;
    final nextX = _blockedAt(x, p.y, r) ? p.x : x;
    final y = p.y + offset.y;
    final nextY = _blockedAt(nextX, y, r) ? p.y : y;
    return nextX == p.x && nextY == p.y ? p : Point(nextX, nextY);
  }

  void lookAt(Point<double> target) {
    if (clashDashing) return;
    final direction = _unit(target - position);
    if (direction != const Point<double>(0, 0)) aim = direction;
  }

  /// Converts the real frame interval to time inside the arena.
  void advanceFrame(
    double seconds, {
    Point<double> move = const Point(0, 0),
    bool walk = false,
  }) => step(seconds * arenaSpeed, move: move, walk: walk);

  /// Advances an explicit amount of simulation time.
  void step(
    double seconds, {
    Point<double> move = const Point(0, 0),
    bool walk = false,
  }) {
    if (finished ||
        shopOpen ||
        !seconds.isFinite ||
        seconds <= 0 ||
        !move.x.isFinite ||
        !move.y.isFinite) {
      return;
    }
    // Split a long frame so projectiles and charges cannot cross obstacles.
    final total = min(.25, seconds);
    final slices = max(1, (total / (1 / 120)).ceil());
    final elapsed = total / slices;
    final movement = _unit(move);
    for (var i = 0; i < slices && !finished; i++) {
      _tick(elapsed, movement, walk);
    }
  }

  void _tick(double elapsed, Point<double> movement, bool walk) {
    if (gripRemaining() > 0) movement = const Point(0, 0);
    _walking = walk && _burstTime <= 0;
    time += elapsed;
    _gripTick(elapsed);
    supply.artCooldown = max(0, supply.artCooldown - elapsed);
    for (final fighter in coopFighters) {
      fighter.supply.artCooldown = max(0, fighter.supply.artCooldown - elapsed);
    }
    if (_burstTraces.isNotEmpty) {
      _burstTraces.removeWhere(
        (_, trace) => time >= trace.fadeStart + LiteBurstTrace.fadeDuration,
      );
    }
    if (groundShots.isNotEmpty) {
      for (final floor in groundShots) {
        floor.remaining -= elapsed;
      }
      groundShots.removeWhere((floor) => floor.remaining <= 0);
    }
    if (_combatImpacts.isNotEmpty &&
        _combatImpacts.first.time <= time - combatImpactDuration) {
      _combatImpacts.removeWhere(
        (impact) => impact.time <= time - combatImpactDuration,
      );
    }
    _lastMove = movement;
    _invulnerability = max(0, _invulnerability - elapsed);
    _hitProtectionRemaining = max(0, _hitProtectionRemaining - elapsed);
    _clashRemaining = max(0, _clashRemaining - elapsed);
    final recovery = _power(LitePowerUp.condotto);
    if (recovery > 0) oculum = min(maxOculum, oculum + elapsed * recovery);
    _attackCooldown = max(0, _attackCooldown - elapsed);
    _scrollCooldown = max(0, _scrollCooldown - elapsed);
    _dashCooldown = max(0, _dashCooldown - elapsed);
    _openCooldown = max(0, _openCooldown - elapsed);
    if (plagueForm) {
      _plagueFormRemaining = max(0, _plagueFormRemaining - elapsed);
      if (!plagueForm) hp /= 2;
    }
    _bandit.punchCooldown = max(0, _bandit.punchCooldown - elapsed);
    _springCooldown = max(0, _springCooldown - elapsed);
    _staffCooldown = max(0, _staffCooldown - elapsed);
    _bombCooldown = max(0, _bombCooldown - elapsed);
    _springPose = max(0, _springPose - elapsed);
    if (_reloadRemaining > 0) {
      _reloadRemaining = max(0, _reloadRemaining - elapsed);
      if (_reloadRemaining <= 1e-9) {
        _reloadRemaining = 0;
        _arrows = bowCapacity;
        if (weapon == LiteWeapon.arco && !rescuing) {
          message = 'Arco ricaricato.';
        }
      }
    }
    if (dodgeCharges < maxDodgeCharges) {
      _dodgeRecharge -= elapsed;
      if (_dodgeRecharge <= 0) {
        dodgeCharges++;
        _dodgeRecharge = max(1.75, 3.2 - dodgeLevel * .36);
      }
    }
    if (!hostDown) {
      this._tickNight(null, elapsed);
      _night.solarMace = max(0, _night.solarMace - elapsed);
      _night.solarMantle = max(0, _night.solarMantle - elapsed);
      this._tickSupply(elapsed);
      weaponArtCooldown = max(0, weaponArtCooldown - elapsed);
      _tickRelicMana(elapsed);
    }
    final beforeMove = position;
    final groundSpeed = this.terrainSpeedAt(position, enemy: false);
    if (!hostDown && _night.stun <= 0 && _burstTime > 0) {
      position = _move(
        position,
        _burstDirection *
            (_burstSpeed * min(elapsed, _burstTime) * groundSpeed),
        _playerRadius,
      );
      _burstTime = max(0, _burstTime - elapsed);
      _recordBurstTrace(0, position, _burstTime);
    } else if (!hostDown &&
        _night.stun <= 0 &&
        (movement.x != 0 || movement.y != 0)) {
      position = _move(
        position,
        movement *
            ((walk ? 3.2 : 6.5) *
                elapsed *
                (1 + _power(LitePowerUp.passo)) *
                (_night.sanguine > 0 ? 2 : 1) *
                groundSpeed),
        _playerRadius,
      );
    }
    stride._track(beforeMove, position, elapsed);
    if (_windup > 0) {
      _windup = max(0, _windup - elapsed);
      if (_windup == 0) {
        if (weapon == LiteWeapon.doppieLame) {
          _melee(position, _strikeDirection, weapon, _damageFor(weapon) * .56);
        } else {
          _weaponAction(position, _strikeDirection, weapon, _damageFor(weapon));
        }
      }
    }
    if (coopFighters.isNotEmpty) _tickCoop(elapsed);
    _discoverFloorMap();
    if (!hostDown &&
        weapon == LiteWeapon.scettro &&
        _staffCooldown == 0 &&
        _staffShock(position, 4.0 + (level - 1) ~/ 3)) {
      _staffCooldown = staffShockInterval;
    }
    _tickFinalBeam(elapsed);
    if (dead) return;
    _befriendWolves();
    // New summons enter combat on the next substep.
    final enemiesAtStart = enemies.length;
    for (var i = 0; i < enemiesAtStart; i++) {
      final enemy = enemies[i];
      if (enemy.hp > 0) {
        final beforeMove = enemy.position;
        final hadWindup = enemy.attacking;
        enemy._strikePose = max(0, enemy._strikePose - elapsed);
        enemy.shockRemaining = max(0, enemy.shockRemaining - elapsed);
        _enemyTick(enemy, elapsed);
        enemy.stride._track(beforeMove, enemy.position, elapsed);
        if (hadWindup && !enemy.attacking && enemy.clashRemaining <= 0) {
          enemy._strikePose = .24;
        }
      }
      if (dead) return;
    }
    _tickFauna(elapsed);
    if (dead) return;
    final alliesAtStart = clones.length;
    for (var i = 0; i < alliesAtStart; i++) {
      final clone = clones[i];
      if (clone.expiresAfter case final remaining?) {
        clone.expiresAfter = max(0, remaining - elapsed);
        if (clone.expiresAfter == 0) clone.hp = 0;
      }
      if (clone.hp > 0) {
        final beforeMove = clone.position;
        clone._swing = max(0, clone._swing - elapsed);
        if (clone.corrupted) {
          _redAllyTick(clone, elapsed);
        } else {
          _cloneTick(clone, elapsed);
        }
        clone.stride._track(beforeMove, clone.position, elapsed);
        if (clone._swing <= 0 && clone.position != beforeMove) {
          clone._poseAim = _unit(clone.position - beforeMove);
        }
      }
      if (clone.down) {
        clone.downRemaining = max(0, clone.downRemaining - elapsed);
      }
    }
    // A destroyed obstacle can add a trap projectile while these are moving.
    // Keep new projectiles for the next simulation step.
    final projectilesAtStart = projectiles.length;
    _clashProjectiles(elapsed);
    for (var i = 0; i < projectilesAtStart; i++) {
      _projectileTick(projectiles[i], elapsed);
      if (dead) return;
    }
    if (rescuing) _tickRescue(elapsed);
    for (final fighter in coopFighters) {
      if (fighter._rescue != null) _tickRescue(elapsed, fighter);
    }
    projectiles.removeWhere((projectile) => projectile.remaining <= 0);
    _tickMechanicalChickenTrial(elapsed / arenaSpeed, movement);
    final royalRescue =
        hero == LiteHero.reGoblin && hp > 0 ||
        coopFighters.any(
          (fighter) => fighter.hero == LiteHero.reGoblin && fighter.hp > 0,
        );
    clones.removeWhere(
      (clone) =>
          clone.hp <= 0 &&
          !clone.down &&
          !(royalRescue && clone.expiresAfter == null),
    );
    enemies.removeWhere((enemy) => enemy.hp <= 0);
    _tickArenaEvent(elapsed);
    _collectLoot(elapsed / arenaSpeed);
    this._checkGoblinEntrance();
    if (hostDown && coopFighters.every((fighter) => fighter.hp <= 0)) {
      dead = true;
      message = 'Il gruppo è caduto al piano $stage.';
    }
    if (dead || enemies.isNotEmpty || stageClear) return;
    if (baghestFight) {
      _completeBaghest();
      return;
    }
    if (_advanceSolarEncounter() || _completeActRoom() || _completeThirdRoom())
      return;
    if (this.goblinCamp) {
      this._nextGoblinWave();
      return;
    }
    if (encounter != LiteEncounter.ordinary && !_eliteReleased) {
      _eliteReleased = true;
      final special = _specialKind(stage);
      _spawnEnemy(special, const Point(28.3, 11));
      message = '${special.label} entra nello scontro.';
      return;
    }
    if (isFinalFloor && !_finalBossDefeated) return;
    stageClear = true;
    _progressQuest(2);
    if (isFinalFloor) {
      victorious = true;
      achievements.add('campagna-completata');
      message = '${_specialKind(stage).label} sconfitto. Campagna completata.';
      return;
    }
    if (biome == LiteBiome.campo) achievements.add('scostubandito-sblocco');
    final trial = arenaTrial;
    if (trial != null && _trialEarned) {
      obser += trial.obser;
      for (final fighter in coopFighters) {
        fighter.obser += trial.obser;
      }
      message =
          '${trial.label} superata · +${trial.obser} Obser per combattente.';
    } else {
      message = trial == null
          ? 'Piano completato. R presso il mercante o il portale.'
          : 'Tempo scaduto. Piano completato, premio extra perso.';
    }
    _offerPowers();
  }

  double _damageFor(LiteWeapon item) =>
      (8 +
          2.0 * (level - 1) +
          item.damageBonus +
          _permanent(LitePermanentUpgrade.danni)) *
      (1 + _power(LitePowerUp.lama)) *
      (1 + .04 * supply.forgeRank(item)) *
      (hero == LiteHero.cavaliereLunare && item == LiteWeapon.spadaScudo
          ? 2
          : 1);

  double _weaponRecovery(LiteWeapon item, double openCooldown, int grade) =>
      item.cooldown *
      (openCooldown > openRecoveryFor(grade) - 4
          ? 1 - _power(LitePowerUp.risonanza)
          : 1);

  bool _staffShock(
    Point<double> source,
    double damage, {
    int? sourceFighterId,
  }) {
    LiteEnemy? target;
    var nearest = staffShockRadius * staffShockRadius;
    for (final enemy in enemies) {
      if (enemy.hp <= 0 || _enemyIntangible(enemy)) continue;
      final distance = _distanceSquared(source, enemy.position);
      if (distance > nearest || _lineBlocked(source, enemy.position)) continue;
      target = enemy;
      nearest = distance;
    }
    if (target == null) return false;
    target
      ..shockRemaining = staffShockSlow
      ..shockSource = source;
    _hitEnemy(
      target,
      damage,
      ownerCanHeal: sourceFighterId == null,
      sourceCloneId: sourceFighterId,
    );
    final pool = drownedPoolAt(target.position);
    if (pool >= 0) {
      final branch = enemies
          .where(
            (enemy) =>
                enemy != target &&
                enemy.hp > 0 &&
                !_enemyIntangible(enemy) &&
                enemy.position.distanceTo(target!.position) <= 2.6 &&
                drownedPoolAt(enemy.position) == pool &&
                !_lineBlocked(target.position, enemy.position),
          )
          .firstOrNull;
      if (branch != null) {
        branch
          ..shockSource = target.position
          ..shockRemaining = staffShockSlow;
        _hitEnemy(
          branch,
          damage * .55,
          ownerCanHeal: sourceFighterId == null,
          sourceCloneId: sourceFighterId,
        );
      }
    }
    return true;
  }

  bool attack(Point<double> target) {
    if (finished ||
        gripRemaining() > 0 ||
        _night.bat > 0 ||
        _night.stun > 0 ||
        hostDown ||
        shopOpen ||
        blocking ||
        rescuing ||
        _attackCooldown > 0 ||
        _windup > 0 ||
        clashDashing) {
      return false;
    }
    if (weapon == LiteWeapon.arco &&
        !(hero == LiteHero.guardianoSolare && _night.solarMace > 0)) {
      if (reloading) return false;
      if (_arrows == 0) {
        message = 'Faretra vuota. R per ricaricare.';
        return false;
      }
      _arrows--;
    }
    lookAt(target);
    _strikeDirection = aim;
    if (hero == LiteHero.guardianoSolare && _night.solarMace > 0) {
      _attackCooldown = .72;
      _melee(
        position,
        aim,
        LiteWeapon.guanti,
        23 + level * 1.9,
        reach: 2.65,
        minDot: .22,
      );
      return true;
    }
    if (_animalStrike(hero, position, aim, level, null)) {
      _attackCooldown = .42;
      return true;
    }
    if (hero == LiteHero.slimeBlu && weapon == LiteWeapon.guanti) {
      _attackCooldown = .58;
      _melee(
        position,
        aim,
        LiteWeapon.guanti,
        9 + level.toDouble(),
        reach: 2.15,
        minDot: .1,
      );
      return true;
    }
    if (hero == LiteHero.doppelganger) {
      _attackCooldown = _mimic == null ? .64 : .82;
      _mimicStrike(_mimic, position, aim, null);
      return true;
    }
    _attackCooldown = _weaponRecovery(weapon, openCooldown, openGrade);
    switch (weapon) {
      case LiteWeapon.doppieLame:
        _melee(position, aim, weapon, _damageFor(weapon) * .56);
        if (clashDashing) return true;
        final reposition = _lastMove == const Point<double>(0, 0)
            ? aim
            : _lastMove;
        position = _move(position, reposition * 1.05, _playerRadius);
        _windup = .11;
      default:
        _windup = weapon.chargeSeconds;
        if (_windup == 0) {
          _weaponAction(position, aim, weapon, _damageFor(weapon));
        }
    }
    return true;
  }

  void _weaponAction(
    Point<double> source,
    Point<double> direction,
    LiteWeapon item,
    double damage, {
    bool ownerCanHeal = true,
    int? sourceCloneId,
  }) {
    final fighter = ownerCanHeal ? null : _coopFighterById(sourceCloneId);
    final kit = ownerCanHeal ? supply : fighter?.supply;
    final rangeScale = ownerCanHeal || fighter != null
        ? _weaponRangeScale(fighter)
        : 1.0;
    if (kit?.fed(LiteRestItem.stufato, stage) == true) damage *= 1.20;
    if (item == LiteWeapon.fucileScostubandito) {
      final buttRange = 2.0 * rangeScale;
      if (enemies.any(
        (enemy) =>
            enemy.hp > 0 &&
            _inArc(
              source,
              direction,
              enemy.position,
              buttRange + enemy.radius,
              minDot: .60,
            ) &&
            !_lineBlocked(source, enemy.position),
      )) {
        _melee(
          source,
          direction,
          item,
          damage,
          reach: buttRange,
          minDot: .60,
          ownerCanHeal: ownerCanHeal,
          sourceCloneId: sourceCloneId,
        );
        return;
      }
      _campNoise(source, 12);
      final skills = ownerCanHeal ? _bandit : _banditForFighter(sourceCloneId);
      final infused = (skills?.rounds ?? 0) > 0;
      if (infused) skills!.rounds--;
      final critical = infused && _rng.nextInt(4) == 0;
      projectiles.add(
        LiteProjectile(
          position: source,
          direction: direction,
          speed: 26,
          remaining: item.range * rangeScale,
          damage: damage * (critical ? 1.5 : 1),
          ownerCanHeal: ownerCanHeal,
          sourceCloneId: sourceCloneId,
          kind: critical
              ? LiteProjectileKind.rifleCritical
              : LiteProjectileKind.rifleBullet,
        ),
      );
      return;
    }
    if (item == LiteWeapon.spadaScudo ||
        item == LiteWeapon.guanti ||
        item == LiteWeapon.piccaOssidiana) {
      _melee(
        source,
        direction,
        item,
        damage,
        minDot: item.thrustArc,
        ownerCanHeal: ownerCanHeal,
        sourceCloneId: sourceCloneId,
      );
      return;
    }
    if (item == LiteWeapon.doppieLame) {
      _melee(
        source,
        direction,
        item,
        damage * .56,
        ownerCanHeal: ownerCanHeal,
        sourceCloneId: sourceCloneId,
      );
      _melee(
        source,
        direction,
        item,
        damage * .56,
        ownerCanHeal: ownerCanHeal,
        sourceCloneId: sourceCloneId,
      );
      return;
    }
    if (item == LiteWeapon.falceRunica) {
      final clashed = _melee(
        source,
        direction,
        item,
        damage,
        ownerCanHeal: ownerCanHeal,
        sourceCloneId: sourceCloneId,
        minDot: .10,
      );
      if (clashed) return;
    }
    projectiles.add(
      LiteProjectile(
        position: source,
        direction: direction,
        speed: switch (item) {
          LiteWeapon.arco => 23,
          LiteWeapon.fucileScostubandito => 26,
          LiteWeapon.carabinaImpulsi => 30,
          LiteWeapon.balestraRunica => 29,
          LiteWeapon.falceRunica => 12,
          LiteWeapon.chakram => 21,
          _ => 15,
        },
        remaining:
            (item == LiteWeapon.falceRunica
                ? LiteWeapon.scytheReturnRange
                : item.range) *
            rangeScale,
        damage: switch (item) {
          LiteWeapon.scettro => damage * (1 + magicBonus),
          LiteWeapon.falceRunica => damage * .50,
          _ => damage,
        },
        magic: item == LiteWeapon.scettro,
        boomerang: item.returns,
        ownerCanHeal: ownerCanHeal,
        kind: switch (item) {
          LiteWeapon.falceRunica => LiteProjectileKind.scythe,
          LiteWeapon.chakram => LiteProjectileKind.chakram,
          LiteWeapon.fucileScostubandito => LiteProjectileKind.rifleBullet,
          LiteWeapon.carabinaImpulsi => LiteProjectileKind.pulse,
          LiteWeapon.balestraRunica => LiteProjectileKind.frostBolt,
          _ => LiteProjectileKind.normal,
        },
        sourceCloneId: sourceCloneId,
      ),
    );
  }

  _LiteBanditSkills? _banditForFighter(int? id) => id == null
      ? null
      : coopFighters
            .where(
              (fighter) =>
                  fighter.id == id && fighter.hero == LiteHero.scostubandito,
            )
            .firstOrNull
            ?._bandit;

  bool _melee(
    Point<double> origin,
    Point<double> direction,
    LiteWeapon item,
    double damage, {
    bool ownerCanHeal = true,
    int? sourceCloneId,
    double minDot = .38,
    double? reach,
    bool royalCombo = false,
    double push = 0,
  }) {
    final fighter = ownerCanHeal ? null : _coopFighterById(sourceCloneId);
    final range =
        reach ??
        (ownerCanHeal || fighter != null
            ? weaponReach(item, fighter)
            : item.range);
    if (ownerCanHeal) {
      for (final enemy in enemies) {
        if (enemy.hp <= 0 ||
            _enemyIntangible(enemy) ||
            enemy.windup <= 0 ||
            enemy.windup > _clashWindow ||
            _usesRangedWeapon(enemy) ||
            enemy.mirror?.chargingVerdict == true) {
          continue;
        }
        final enemyRange = enemy.mirror?.weapon.range ?? 1.35 + enemy.radius;
        if (_distanceSquared(origin, enemy.position) >
                _square(enemyRange + _playerRadius) ||
            !_inArc(
              origin,
              direction,
              enemy.position,
              range + enemy.radius,
              minDot: minDot,
            ) ||
            !_meleeThreatensPlayer(enemy, enemyRange)) {
          continue;
        }
        _campNoise(origin, 9);
        _startClashDash(enemy);
        return true;
      }
    }
    if (_interceptWithMelee(origin, direction, range, minDot: minDot)) {
      return true;
    }
    for (final enemy in _attackableCreatures) {
      final hitPoint = enemy.closestHitboxPoint(origin);
      if (enemy.hp <= 0 ||
          !(enemy.burrow != null && enemy.hitboxContains(origin)) &&
              !_inArc(
                origin,
                direction,
                hitPoint,
                range + enemy.hitboxRadius,
                minDot: minDot,
              )) {
        continue;
      }
      if (_lineBlocked(origin, hitPoint)) continue;
      if (_enemyIntangible(enemy)) {
        if (ownerCanHeal) _recordIntangible(enemy);
        continue;
      }
      _hitEnemy(
        enemy,
        damage,
        ownerCanHeal: ownerCanHeal,
        sourceCloneId: sourceCloneId,
        impactFrom: origin,
        launch: push,
        forceImpact:
            item == LiteWeapon.guanti || item == LiteWeapon.fucileScostubandito,
      );
      if (royalCombo && enemy.hp > 0) {
        enemy.stunned = enemy.kind.boss
            ? .3
            : enemy.kind.elite
            ? .6
            : .9;
        enemy.windup = 0;
      }
    }
    for (final clone in clones) {
      if (clone.corrupted &&
          clone.hp > 0 &&
          _inArc(
            origin,
            direction,
            clone.position,
            range + .26,
            minDot: minDot,
          ) &&
          !_lineBlocked(origin, clone.position)) {
        _hitRedAlly(clone, damage);
      }
    }
    for (final wall in [...obstacles]) {
      if (wall.breakable &&
          _inArc(origin, direction, wall.center, range, minDot: minDot)) {
        _breakObstacle(
          wall,
          damage,
          origin,
          partyAttack: ownerCanHeal || _coopFighterById(sourceCloneId) != null,
          sourceCloneId: sourceCloneId,
        );
      }
    }
    return false;
  }

  bool _meleeThreatensPlayer(LiteEnemy enemy, double range) {
    if (_lineBlocked(enemy.position, position)) return false;
    final mirror = enemy.mirror;
    if (mirror == null) return true;
    return _inArc(
      enemy.position,
      _unit((enemy.attackTarget ?? position) - enemy.position),
      position,
      range + _playerRadius,
    );
  }

  bool _counterClash(LiteEnemy enemy, double reach) {
    if (clashDashing ||
        _enemyIntangible(enemy) ||
        _windup <= 0 ||
        _windup > _clashWindow ||
        (weapon != LiteWeapon.guanti &&
            weapon != LiteWeapon.doppieLame &&
            weapon != LiteWeapon.piccaOssidiana)) {
      return false;
    }
    if (_distanceSquared(enemy.position, position) >
            _square(reach + _playerRadius) ||
        !_meleeThreatensPlayer(enemy, reach) ||
        !_inArc(
          position,
          _strikeDirection,
          enemy.position,
          weaponReach(weapon) + enemy.radius,
        )) {
      return false;
    }
    _startClashDash(enemy);
    return true;
  }

  void _startClashDash(LiteEnemy enemy) {
    var towards = _unit(enemy.position - position);
    if (towards == const Point<double>(0, 0)) towards = aim;
    _recordImpact(
      LiteImpactTarget.clash,
      enemy.id,
      (enemy.position + position) * .5,
    );
    aim = _strikeDirection = towards;
    _windup = 0;
    _attackCooldown = max(_attackCooldown, .30);
    _clashRemaining = clashDashDuration;
    _invulnerability = max(_invulnerability, clashDashDuration);
    _burstTime = clashDashDuration;
    _burstSpeed = 10.5;
    _burstDirection = towards * -1.0;
    enemy.windup = 0;
    enemy.cooldown = max(enemy.cooldown, .52);
    enemy.clashRemaining = clashDashDuration;
    enemy.clashDirection = towards;
    _beginBurstTrace(LiteBurstKind.clash, clashDashDuration);
    _burstTraces[-enemy.id] = LiteBurstTrace._(
      LiteBurstKind.clash,
      time,
      clashDashDuration,
      towards,
      enemy.position,
      [enemy.position],
    );
  }

  bool _lineBlocked(
    Point<double> from,
    Point<double> to, {
    bool ignoreBreakable = false,
  }) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final count = (sqrt(dx * dx + dy * dy) / .25).ceil();
    for (var i = 1; i < count; i++) {
      final fraction = i / count;
      if (_blockedAt(
        from.x + dx * fraction,
        from.y + dy * fraction,
        .12,
        ignoreBreakable: ignoreBreakable,
      )) {
        return true;
      }
    }
    return false;
  }

  static bool _inArc(
    Point<double> from,
    Point<double> direction,
    Point<double> target,
    double range, {
    double minDot = .38,
  }) {
    if (_distance(from, target) > range) return false;
    final delta = _unit(target - from);
    return direction.x * delta.x + direction.y * delta.y > minDot;
  }

  bool dash(Point<double> target) {
    if (finished ||
        hostDown ||
        shopOpen ||
        _dashCooldown > 0 ||
        _burstTime > 0) {
      return false;
    }
    lookAt(target);
    _burstDirection = _lastMove == const Point<double>(0, 0) ? aim : _lastMove;
    _burstSpeed = 14;
    _burstTime = .19;
    _dashCooldown = 1.1;
    _beginBurstTrace(
      _bandit.dodgeReady ? LiteBurstKind.phase : LiteBurstKind.dash,
      _burstTime,
    );
    if (_bandit.dodgeReady) {
      _bandit.dodgeReady = false;
      _invulnerability = max(_invulnerability, _burstTime);
    }
    return true;
  }

  bool useOpen(Point<double> target) => _useOpen(target, null);

  bool _useOpen(Point<double> target, LiteCoopFighter? fighter) {
    final character = fighter?.hero ?? hero;
    final cooldown = fighter?._openCooldown ?? _openCooldown;
    final available = fighter?.oculum ?? oculum;
    if (finished ||
        shopOpen ||
        (fighter == null ? hostDown || clashDashing : fighter.hp <= 0) ||
        cooldown > 0 ||
        available < granSummonCost) {
      return false;
    }
    final source = fighter?.position ?? position;
    final ownerId = fighter?.id ?? 0;
    final characterLevel = fighter?.level ?? level;
    final grade = openGradeFor(characterLevel);
    final aimed = _unit(target - source);
    final direction = aimed.magnitude > 0 ? aimed : fighter?.aim ?? aim;
    switch (character) {
      case LiteHero.vesanybel || LiteHero.aerovyr || LiteHero.vedettaEiva:
        _thirdHeroMove(
          character,
          source,
          direction,
          fighter,
          grade,
          open: true,
        );
      case LiteHero.demoneMinore ||
          LiteHero.demoneIntermedio ||
          LiteHero.demoneMaggiore ||
          LiteHero.diavolo:
        _infernalMove(character, source, direction, fighter, grade, open: true);
      case LiteHero.guardiaSolare || LiteHero.aberrazioneSolare:
        _solarPlayerGuard(character, source, direction, fighter, grade);
      case LiteHero.eliteSolare:
        _fireSun(
          source,
          direction,
          28 + grade * 7.0,
          owner: fighter?.id,
          ray: true,
        );
      case LiteHero.guardianoSolare:
        (fighter?._night ?? _night).solarMace = 4 + grade.toDouble();
      case LiteHero.pollo || LiteHero.polloMeccanico:
        final mechanical = character == LiteHero.polloMeccanico;
        _throwEggs(
          source,
          direction,
          fighter?.id,
          damage: mechanical ? 24 + 6.0 * grade : 16 + 5.0 * grade,
          spread: .31,
          mechanical: mechanical,
        );
        if (mechanical) {
          if (fighter == null) {
            _springPose = .34;
          } else {
            fighter._springPose = .34;
          }
        }
      case LiteHero.raganella:
        _playableShadowStep(
          source,
          direction,
          fighter,
          distance: 3.9 + grade * .38,
          protection: .4,
        );
        _openBurst(
          fighter?.position ?? position,
          2.65,
          18 + grade * 6.0,
          ownerId,
          push: 1.2,
        );
      case LiteHero.pipistrello:
        _playableShadowStep(
          source,
          direction,
          fighter,
          distance: 4.8 + grade * .4,
          protection: .85,
        );
        _openBurst(
          fighter?.position ?? position,
          3.3,
          13 + grade * 6.0,
          ownerId,
          push: 1.3,
        );
      case LiteHero.evasore:
        final duration = .48 + .10 * (grade - 1);
        final speed = 20.0 + (grade - 1) * 2;
        if ((fighter?._dashRemaining ?? _burstTime) > 0) return false;
        if (fighter == null) {
          aim = _burstDirection = direction;
          _burstSpeed = speed;
          _burstTime = duration;
          _invulnerability = max(_invulnerability, duration);
        } else {
          fighter
            ..aim = direction
            .._dashDirection = direction
            .._dashSpeed = speed
            .._dashRemaining = duration
            .._protection = max(fighter._protection, duration);
        }
        _beginBurstTrace(LiteBurstKind.open, duration, fighter: fighter);
      case LiteHero.duplicatore:
        final occupied = clones
            .where((ally) => ally.ownerId == ownerId && ally.companion == null)
            .length;
        final count = min(grade == 3 ? 3 : 2, 3 - occupied);
        if (count <= 0) return false;
        final flank = Point(-direction.y, direction.x) * 1.3;
        for (var i = 0; i < count; i++) {
          final beside = switch (i) {
            0 => source + flank,
            1 => source - flank,
            _ => source + direction * 1.3,
          };
          clones.add(
            LiteClone(
              _safePoint(beside, .35, source),
              22.0 + grade * 7,
              fighter?.weapon ?? weapon,
              expiresAfter: 10.0 + grade * 2,
              damageScale: 1 + grade * .30,
              id: _nextId++,
              ownerId: ownerId,
            ),
          );
        }
      case LiteHero.ashley:
        if ((fighter?._windup ?? _windup) > 0) return false;
        if (fighter == null) {
          aim = direction;
          _springPose = .28;
        } else {
          fighter
            ..aim = direction
            .._springPose = .28;
        }
        _melee(
          source,
          direction,
          LiteWeapon.guanti,
          38.0 + 4 * characterLevel + 10 * (grade - 1),
          reach: 5 + .45 * (grade - 1),
          minDot: .69,
          ownerCanHeal: fighter == null,
          sourceCloneId: fighter?.id,
        );
      case LiteHero.scostubandito:
        if (!_summonCompanions(
          LiteCompanion.granScostumato,
          1,
          source,
          direction,
          ownerId,
          grade,
        )) {
          return false;
        }
      case LiteHero.granScostumato:
        if (!_summonCompanions(
          LiteCompanion.vedetta,
          2,
          source,
          direction,
          ownerId,
          grade,
        )) {
          return false;
        }
      case LiteHero.dronePostea:
        _openBurst(
          source,
          3.2 + grade * .5,
          20.0 + grade * 11,
          ownerId,
          shock: .6 + grade * .2,
        );
      case LiteHero.sentinella:
        final ward = 24.0 + 12 * grade;
        if (fighter == null) {
          shield += ward;
        } else {
          fighter.shield += ward;
        }
        _openBurst(
          source,
          2.6 + grade * .35,
          15.0 + grade * 7,
          ownerId,
          push: 1.0 + grade * .4,
        );
      case LiteHero.babyForestDemon:
        _melee(
          source,
          direction,
          LiteWeapon.guanti,
          28.0 + grade * 13 + 2 * characterLevel,
          reach: 3.9 + grade * .5,
          minDot: .25,
          ownerCanHeal: false,
          sourceCloneId: fighter?.id,
        );
      case LiteHero.pyrel:
        for (final turn in [-.31, .0, .31]) {
          _launchFireball(
            source,
            _rotate(direction, turn),
            17 + grade * 5.0,
            2 + grade,
            fighter?.id,
          );
        }
      case LiteHero.lithra:
        for (final turn in [-.32, .0, .32]) {
          _fissure(
            source,
            _rotate(direction, turn),
            6 + grade * .7,
            17 + grade * 6.0,
            fighter?.id,
          );
        }
      case LiteHero.luce:
        if (fighter == null) {
          shield += 15 + 6 * grade;
        } else {
          fighter.shield += 15 + 6 * grade;
        }
        _openBurst(
          source,
          3.4 + grade * .4,
          23 + grade * 7.0,
          ownerId,
          push: 1.5,
        );
      case LiteHero.ombra:
        _playableShadowStep(
          source,
          direction,
          fighter,
          distance: 4.6 + grade * .65,
          protection: 3,
        );
      case LiteHero.veyrth:
        for (var i = 0; i < 5 + grade * 2; i++) {
          _launchSphere(
            source,
            _rotate(direction, i * 2 * pi / (5 + grade * 2)),
            12 + grade * 3.0,
            fighter?.id,
          );
        }
      case LiteHero.doppelganger:
        final form = fighter == null ? _mimic : fighter._mimic;
        if (form == null) return false;
        _mimicStrike(
          form,
          source,
          direction,
          fighter?.id,
          factor: 1.6 + grade * .25,
          special: true,
        );
      case LiteHero.reGoblin:
        if (!this._goblinRetinue(source, direction, ownerId, grade))
          return false;
      case LiteHero.cavaliereLunare:
        if (!_summonCompanions(
          LiteCompanion.guardianoLunare,
          1,
          source,
          direction,
          ownerId,
          grade,
        ))
          return false;
      case LiteHero.slimeBlu:
        if (!this._extendAbsorption(source, direction, fighter, empower: true))
          return false;
        if (fighter == null) {
          shield += 12 + 4 * grade;
        } else {
          fighter.shield += 12 + 4 * grade;
        }
      case LiteHero.vampiro:
        final state = fighter?._night ?? _night;
        if (state.sanguine > 0) return false;
        state.sanguine = 5 + grade.toDouble();
        if (fighter == null) {
          hp *= 2;
        } else {
          fighter.hp *= 2;
        }
      case LiteHero.curatorePeste:
        if (fighter?.plagueForm ?? plagueForm) return false;
        final duration = 4.0 + .5 * (grade - 1);
        if (fighter == null) {
          _plagueFormRemaining = duration;
          hp *= 2;
        } else {
          fighter
            .._plagueFormRemaining = duration
            ..hp *= 2;
        }
    }
    if (fighter == null) {
      oculum -= granSummonCost;
      shield += _power(LitePowerUp.riflusso);
      _openCooldown = openRecoveryFor(grade);
    } else {
      fighter.oculum -= granSummonCost;
      fighter.shield += _power(LitePowerUp.riflusso);
      fighter._openCooldown = openRecoveryFor(grade);
    }
    message = 'Open · ${character.openName}.';
    return true;
  }

  bool throwBanditBomb(Point<double> target) => _throwBanditBomb(target, null);
  bool _throwBanditBomb(Point<double> target, LiteCoopFighter? fighter) {
    if (finished ||
        (fighter == null
            ? hostDown || shopOpen || blocking || rescuing
            : fighter.blocking || fighter.hp <= 0) ||
        (fighter?.hero ?? hero) != LiteHero.scostubandito ||
        (fighter?._bombCooldown ?? _bombCooldown) > 0 ||
        (fighter?.oculum ?? oculum) < 2)
      return false;
    final from = fighter?.position ?? position;
    final delta = target - from;
    final direction = delta.magnitude > .1 ? _unit(delta) : fighter?.aim ?? aim;
    final range = delta.magnitude.clamp(2.2, 7.0);
    projectiles.add(
      LiteProjectile(
        position: from,
        direction: direction,
        speed: 11,
        remaining: range,
        damage: 25 + 2.0 * (fighter?.level ?? level),
        kind: LiteProjectileKind.bomb,
        ownerCanHeal: fighter == null,
        sourceCloneId: fighter?.id,
      ),
    );
    if (fighter == null) {
      _bombCooldown = 5.5;
      oculum -= 2;
    } else {
      fighter._bombCooldown = 5.5;
      fighter.oculum -= 2;
    }
    message = 'Bomba dello Scostubandito.';
    return true;
  }

  bool banditRifleSkill() => _armBanditRifle(null);

  bool slimeDash(Point<double> target) => this._slimeDash(target, null);

  bool royalCall() => this._raiseByRoyalCall(null);

  bool _armBanditRifle(LiteCoopFighter? fighter) {
    final character = fighter?.hero ?? hero;
    final skills = fighter?._bandit ?? _bandit;
    if (character != LiteHero.scostubandito ||
        (fighter?.weapon ?? weapon) != LiteWeapon.fucileScostubandito ||
        finished ||
        shopOpen ||
        (fighter?.hp ?? hp) <= 0 ||
        (fighter?.oculum ?? oculum) < banditRifleCost ||
        skills.rounds > 0) {
      return false;
    }
    if (fighter == null) {
      oculum -= banditRifleCost;
    } else {
      fighter.oculum -= banditRifleCost;
    }
    skills.rounds = banditRifleCost;
    message = 'Fucile schivata · 4 colpi infusi.';
    return true;
  }

  bool _banditPunch(
    Point<double> source,
    Point<double> direction,
    _LiteBanditSkills skills,
    int level,
    int? ownerId,
  ) {
    if (skills.punchCooldown > 0) return false;
    skills.punchCooldown = springCooldown;
    final critical = _rng.nextInt(4) == 0;
    _melee(
      source,
      direction,
      LiteWeapon.guanti,
      (12 + 2.0 * level) * (critical ? 1.5 : 1),
      minDot: .70,
      ownerCanHeal: ownerId == null,
      sourceCloneId: ownerId,
    );
    message = critical ? 'Pugno critico.' : 'Prendi questo, stronzo!';
    return true;
  }

  bool special(Point<double> target) {
    if (finished || shopOpen || clashDashing || blocking) return false;
    if (hostDown) return false;
    lookAt(target);
    if (hero == LiteHero.scostubandito) {
      return _windup <= 0 && _banditPunch(position, aim, _bandit, level, null);
    }
    if (hero.specialTalent) {
      return _npcTalent(aim, null);
    }
    if (hero == LiteHero.ashley) {
      if (_springCooldown > 0 || _windup > 0) return false;
      _springCooldown = springCooldown;
      _springPose = .28;
      _melee(
        position,
        aim,
        LiteWeapon.guanti,
        14.0 + 2 * level,
        reach: springRange,
        minDot: .86,
      );
      return true;
    }
    if (hero == LiteHero.evasore) {
      if (dodgeCharges < 1 || _burstTime > 0) return false;
      if (dodgeCharges == maxDodgeCharges) {
        _dodgeRecharge = max(1.75, 3.2 - dodgeLevel * .36);
      }
      dodgeCharges--;
      _burstDirection = _lastMove == const Point<double>(0, 0)
          ? aim
          : _lastMove;
      _burstSpeed =
          (16 + min(dodgeLevel, 3) * 1.5) * (1 + _power(LitePowerUp.passo));
      _burstTime = .21 + min(dodgeLevel, 3) * .025;
      _invulnerability = max(_invulnerability, _burstTime);
      _beginBurstTrace(LiteBurstKind.phase, _burstTime);
      return true;
    }
    final cost = _duplicate(position, aim, weapon, hp, maxHp);
    if (cost == 0) {
      message = 'Servono Vita e un posto libero per il duplicato.';
      return false;
    }
    hp -= cost;
    message = 'Duplicato evocato.';
    return true;
  }

  bool _npcTalent(Point<double> direction, LiteCoopFighter? fighter) {
    final kit = fighter?._night ?? _night;
    if (kit.stun > 0 || kit.bat > 0) return false;
    if ((fighter?.hero ?? hero) == LiteHero.slimeBlu) {
      return this._extendAbsorption(
        fighter?.position ?? position,
        direction,
        fighter,
      );
    }
    if ((fighter?._dodgeCooldown ?? _springCooldown) > 0 ||
        (fighter?._windup ?? _windup) > 0)
      return false;
    final character = fighter?.hero ?? hero;
    final source = fighter?.position ?? position;
    final characterLevel = fighter?.level ?? level;
    if (character == LiteHero.doppelganger &&
        !_copyEnemy(source, direction, fighter))
      return false;
    if (character == LiteHero.curatorePeste &&
        !_raiseSkeletons(source, direction, fighter?.id ?? 0))
      return false;
    if (fighter == null) {
      _springCooldown = character == LiteHero.reGoblin ? 1.8 : springCooldown;
      _springPose = .28;
    } else {
      fighter
        .._dodgeCooldown = character == LiteHero.reGoblin ? 1.8 : springCooldown
        .._springPose = .28;
    }
    final owner = fighter?.id;
    switch (character) {
      case LiteHero.vesanybel || LiteHero.aerovyr || LiteHero.vedettaEiva:
        _thirdHeroMove(
          character,
          source,
          direction,
          fighter,
          openGradeFor(characterLevel),
          open: false,
        );
      case LiteHero.demoneMinore ||
          LiteHero.demoneIntermedio ||
          LiteHero.demoneMaggiore ||
          LiteHero.diavolo:
        _infernalMove(
          character,
          source,
          direction,
          fighter,
          openGradeFor(characterLevel),
        );
      case LiteHero.guardiaSolare:
        _sunGlare(source, direction, owner);
      case LiteHero.eliteSolare:
        if (fighter == null) {
          shield += 14 + characterLevel;
        } else {
          fighter.shield += 14 + characterLevel;
        }
      case LiteHero.guardianoSolare:
        _fireSun(source, direction, 12 + characterLevel * 1.8, owner: owner);
      case LiteHero.aberrazioneSolare:
        _solarPlayerGuard(character, source, direction, fighter, 0);
      case LiteHero.pollo || LiteHero.polloMeccanico:
        final mechanical = character == LiteHero.polloMeccanico;
        _throwEggs(
          source,
          direction,
          owner,
          damage: mechanical
              ? 18 + characterLevel * 1.50
              : 12 + characterLevel * 1.25,
          spread: .24,
          mechanical: mechanical,
        );
      case LiteHero.raganella:
        _melee(
          source,
          direction,
          LiteWeapon.guanti,
          14 + characterLevel * 1.2,
          ownerCanHeal: owner == null,
          sourceCloneId: owner,
          reach: 4.1,
          minDot: .82,
        );
      case LiteHero.pipistrello:
        _openBurst(
          source,
          2.65,
          10 + characterLevel * 1.25,
          owner ?? 0,
          push: .90,
        );
      case LiteHero.curatorePeste || LiteHero.doppelganger:
        return true;
      case LiteHero.reGoblin:
        _melee(
          source,
          direction,
          LiteWeapon.spadaScudo,
          15 + characterLevel * 2.0,
          reach: 3.15,
          minDot: .25,
          ownerCanHeal: owner == null,
          sourceCloneId: owner,
          royalCombo: true,
        );
        return true;
      case LiteHero.cavaliereLunare:
        return _summonCompanions(
          LiteCompanion.guardiaLunare,
          2,
          source,
          direction,
          owner ?? 0,
          fighter?.openGrade ?? openGrade,
        );
      case LiteHero.vampiro:
        final state = fighter?._night ?? _night;
        state.bat = 3;
        if (fighter == null) {
          _invulnerability = max(_invulnerability, 3);
        } else {
          fighter._shadowProtection = max(fighter._shadowProtection, 3);
        }
        message = 'Forma pipistrello · 3 s di intangibilità.';
        return true;
      case LiteHero.pyrel:
        _launchFireball(source, direction, 18 + 2.0 * characterLevel, 3, owner);
        return true;
      case LiteHero.lithra:
        _fissure(source, direction, 7, 22 + 2.0 * characterLevel, owner);
        return true;
      case LiteHero.luce:
        _melee(
          source,
          direction,
          LiteWeapon.piccaOssidiana,
          22 + 2.0 * characterLevel,
          reach: 5.2,
          minDot: .85,
          ownerCanHeal: fighter == null,
          sourceCloneId: owner,
        );
        return true;
      case LiteHero.ombra:
        _playableShadowStep(
          source,
          direction,
          fighter,
          distance: 3.25,
          protection: .38,
        );
        return true;
      case LiteHero.veyrth:
        _launchSphere(source, direction, 24 + 2.0 * characterLevel, owner);
        return true;
      default:
        break;
    }
    if (character == LiteHero.granScostumato) {
      projectiles.add(
        LiteProjectile(
          position: source,
          direction: direction,
          speed: 14,
          remaining: 15,
          damage: 24 + 3.0 * characterLevel,
          kind: LiteProjectileKind.cannon,
          sourceCloneId: fighter?.id,
        ),
      );
      return true;
    }
    if (character == LiteHero.dronePostea) {
      _staffShock(
        source,
        12.0 + 2 * characterLevel,
        sourceFighterId: fighter?.id,
      );
      return true;
    }
    _melee(
      source,
      direction,
      LiteWeapon.guanti,
      13.0 + 2 * characterLevel,
      reach: character == LiteHero.babyForestDemon ? 3.4 : 2.8,
      minDot: .50,
      ownerCanHeal: false,
      sourceCloneId: fighter?.id,
    );
    return true;
  }

  Point<double> _rotate(Point<double> a, double theta) => Point(
    a.x * cos(theta) - a.y * sin(theta),
    a.x * sin(theta) + a.y * cos(theta),
  );

  void _playableShadowStep(
    Point<double> from,
    Point<double> direction,
    LiteCoopFighter? fighter, {
    required double distance,
    required double protection,
  }) {
    var target = from;
    for (var left = distance; left > 0; left -= .20) {
      final next = _move(target, direction * min(.20, left), _playerRadius);
      if (next == target) break;
      target = next;
    }
    if (fighter == null) {
      position = target;
      _invulnerability = max(_invulnerability, protection);
    } else {
      fighter.position = target;
      fighter._shadowProtection = max(fighter._shadowProtection, protection);
    }
  }

  bool _copyEnemy(
    Point<double> from,
    Point<double> direction,
    LiteCoopFighter? fighter,
  ) {
    if ((fighter == null ? _mimic : fighter._mimic) != null) {
      message = 'La forma copiata dura finché viene abbattuta.';
      return false;
    }
    LiteEnemy? target;
    var best = double.infinity;
    for (final enemy in _attackableCreatures) {
      if (enemy.hp <= 0 || enemy.kind.boss || enemy.kind.echo) continue;
      final delta = enemy.position - from;
      final along = delta.x * direction.x + delta.y * direction.y;
      final across = (delta.x * direction.y - delta.y * direction.x).abs();
      if (along <= 0 ||
          along > 7 ||
          across > enemy.radius + .36 ||
          _lineBlocked(from, enemy.position))
        continue;
      if (along < best) {
        target = enemy;
        best = along;
      }
    }
    if (target == null) {
      message = 'Mira a un nemico a 7 m. Boss ed eco non sono copiabili.';
      return false;
    }
    final scale = difficulty.enemyStrength * (1 + .12 * max(0, stage - 1));
    final form = LiteMimicForm(
      target.kind,
      target.maxHp,
      fighter?.hp ?? hp,
      target.kind.damage * scale,
    );
    if (fighter == null) {
      _mimic = form;
      hp = target.hp;
      shield = 0;
    } else {
      fighter._mimic = form;
      fighter.hp = target.hp;
      fighter.shield = 0;
    }
    achievements.add('predatore-speculare');
    message = 'Forma copiata · ${target.kind.label}.';
    if (target.kind == LiteEnemyKind.slime)
      _discoverPet(LiteCompanion.lumin, from);
    return true;
  }

  void _revertMimic(LiteMimicForm form, LiteCoopFighter? fighter) {
    if (fighter == null) {
      _mimic = null;
      hp = min(maxHp, form.originalHp * .65);
      _windup = 0;
    } else {
      fighter._mimic = null;
      fighter.hp = min(fighter.maxHp, form.originalHp * .65);
      fighter._windup = 0;
    }
    message = 'Forma distrutta · ritorni con il 65% della Vita che avevi.';
  }

  void _mimicStrike(
    LiteMimicForm? form,
    Point<double> from,
    Point<double> direction,
    int? owner, {
    double factor = 1,
    bool special = false,
  }) {
    final kind = form?.kind;
    final damage =
        (form?.damage ?? (owner == null ? 6 + (level - 1) * .8 : 6.0)) * factor;
    final wasHost = owner == null;
    if (kind != null && _ranged(kind)) {
      final spread = kind == LiteEnemyKind.dronePostea
          ? [-.09, .09]
          : special
          ? [-.18, .0, .18]
          : [.0];
      for (final turn in spread) {
        projectiles.add(
          LiteProjectile(
            position: from,
            direction: _rotate(direction, turn),
            speed: kind == LiteEnemyKind.ragnoSaldatore ? 13 : 18,
            remaining: 10,
            damage: damage * (spread.length == 1 ? 1 : .65),
            kind: switch (kind) {
              LiteEnemyKind.ragnoSaldatore => LiteProjectileKind.plasma,
              LiteEnemyKind.dronePostea => LiteProjectileKind.pulse,
              LiteEnemyKind.granScostumato => LiteProjectileKind.cannon,
              _ => LiteProjectileKind.rifleBullet,
            },
            magic: kind == LiteEnemyKind.ragnoSaldatore,
            ownerCanHeal: wasHost,
            sourceCloneId: owner,
          ),
        );
      }
      return;
    }
    if (kind == LiteEnemyKind.orbryx ||
        kind == LiteEnemyKind.rasvyr ||
        kind == LiteEnemyKind.miruscyrus) {
      final destination = _move(
        from,
        direction * (special ? 2.8 : 1.4),
        _playerRadius,
      );
      if (wasHost) {
        position = destination;
      } else {
        for (final fighter in coopFighters) {
          if (fighter.id == owner) fighter.position = destination;
        }
      }
      from = destination;
    }
    _melee(
      from,
      direction,
      LiteWeapon.guanti,
      damage,
      reach: switch (kind) {
        LiteEnemyKind.rasvyr => 3.0,
        LiteEnemyKind.babyForestDemon || LiteEnemyKind.orbryx => 2.5,
        _ => special ? 3.2 : 1.75,
      },
      minDot: kind == LiteEnemyKind.slime ? .05 : .5,
      ownerCanHeal: wasHost,
      sourceCloneId: owner,
    );
  }

  void _launchFireball(
    Point<double> from,
    Point<double> direction,
    double damage,
    int bounces,
    int? owner,
  ) {
    projectiles.add(
      LiteProjectile(
        position: from,
        direction: direction,
        speed: 14,
        remaining: 32,
        damage: damage,
        magic: true,
        kind: LiteProjectileKind.fireball,
        bounces: bounces,
        ownerCanHeal: owner == null,
        sourceCloneId: owner,
      ),
    );
  }

  void _launchSphere(
    Point<double> from,
    Point<double> direction,
    double damage,
    int? owner,
  ) {
    projectiles.add(
      LiteProjectile(
        position: from,
        direction: direction,
        speed: 12,
        remaining: 10.5,
        damage: damage,
        magic: true,
        kind: LiteProjectileKind.veyrthSphere,
        ownerCanHeal: owner == null,
        sourceCloneId: owner,
      ),
    );
  }

  void _fissure(
    Point<double> from,
    Point<double> direction,
    double range,
    double damage,
    int? owner,
  ) {
    var reach = 0.0;
    while (reach < range) {
      final length = min(range, reach + .2);
      final next = from + direction * length;
      if (_blocked(next, .14)) {
        for (final obstacle in obstacles) {
          if (obstacle.breakable && obstacle.visibleAt(next, .14)) {
            _breakObstacle(obstacle, damage, from);
            break;
          }
        }
        if (_blocked(next, .14)) break;
      }
      reach = length;
    }
    if (reach == 0) return;
    if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
    _combatImpacts.add(
      LiteCombatImpact(
        LiteImpactTarget.fissure,
        _nextId++,
        from,
        time,
        end: from + direction * reach,
      ),
    );
    for (final enemy in enemies) {
      if (enemy.hp <= 0) continue;
      final delta = enemy.position - from;
      final along = delta.x * direction.x + delta.y * direction.y;
      final across = (delta.x * direction.y - delta.y * direction.x).abs();
      if (along < 0 ||
          along > reach ||
          across > .66 + enemy.radius ||
          _lineBlocked(from, enemy.position))
        continue;
      _hitEnemy(
        enemy,
        damage,
        ownerCanHeal: owner == null,
        sourceCloneId: owner,
      );
    }
  }

  bool _raiseSkeletons(
    Point<double> source,
    Point<double> direction,
    int ownerId,
  ) {
    var raised = false;
    final flank = Point(-direction.y, direction.x) * 1.7;
    for (final (companion, side) in [
      (LiteCompanion.scheletroFalce, 1.0),
      (LiteCompanion.scheletroArco, -1.0),
    ]) {
      if (clones.any(
        (ally) =>
            ally.companion == companion &&
            ally.ownerId == ownerId &&
            ally.hp > 0,
      ))
        continue;
      clones.add(
        LiteClone(
          _safePoint(source + (flank + direction * 1.45) * side, .35, source),
          companion.life,
          companion.weapon,
          companion: companion,
          expiresAfter: 18,
          summoned: true,
          id: _nextId++,
          ownerId: ownerId,
        ),
      );
      raised = true;
    }
    return raised;
  }

  void _openBurst(
    Point<double> source,
    double radius,
    double damage,
    int ownerId, {
    double shock = 0,
    double push = 0,
  }) {
    for (final enemy in _attackableCreatures) {
      final hitPoint = enemy.closestHitboxPoint(source);
      final outside = enemy.burrow == null
          ? _distanceSquared(source, hitPoint) > radius * radius
          : !enemy.hitboxContains(source, extra: radius);
      if (_enemyIntangible(enemy) ||
          enemy.hp <= 0 ||
          outside ||
          _lineBlocked(source, hitPoint))
        continue;
      _hitEnemy(
        enemy,
        damage,
        ownerCanHeal: ownerId == 0,
        sourceCloneId: ownerId == 0 ? null : ownerId,
      );
      if (enemy.hp <= 0) continue;
      enemy.shockRemaining = max(enemy.shockRemaining, shock);
      if (push > 0) {
        enemy.position = _move(
          enemy.position,
          _unit(enemy.position - source) * push,
          enemy.radius,
        );
      }
    }
  }

  bool _summonCompanions(
    LiteCompanion companion,
    int count,
    Point<double> source,
    Point<double> direction,
    int ownerId,
    int grade,
  ) {
    final living = clones
        .where(
          (ally) =>
              ally.ownerId == ownerId &&
              ally.companion == companion &&
              ally.expiresAfter != null &&
              ally.hp > 0,
        )
        .length;
    final missing = count - living;
    if (companion != LiteCompanion.guardiaLunare &&
            companion != LiteCompanion.goblinColtello &&
            living > 0 ||
        missing <= 0)
      return false;
    final flank = Point(-direction.y, direction.x) * 1.3;
    for (var i = 0; i < missing; i++) {
      final beside =
          source + flank * ((i + living).isEven ? 1.0 : -1.0) + direction * .9;
      clones.add(
        LiteClone(
          _safePoint(beside, .35, source),
          companion.life * (1 + .25 * grade),
          companion.weapon,
          companion: companion,
          summoned: true,
          expiresAfter: granSummonDuration + (grade - 1) * 3,
          damageScale: 1 + .30 * grade,
          id: _nextId++,
          ownerId: ownerId,
        ),
      );
    }
    return true;
  }

  double _duplicate(
    Point<double> source,
    Point<double> direction,
    LiteWeapon item,
    double life,
    double maximum, {
    int ownerId = 0,
  }) {
    final cost = (maximum * cloneFraction).ceilToDouble();
    final owned = clones.where(
      (clone) => clone.ownerId == ownerId && clone.companion == null,
    );
    if (owned.length >= 3 ||
        owned.where((clone) => !clone.summoned).length >= 2 ||
        life - cost < 1) {
      return 0;
    }
    final beside = source + Point(-direction.y, direction.x) * 1.2;
    clones.add(
      LiteClone(
        _safePoint(beside, .35, source),
        cost,
        item,
        id: _nextId++,
        ownerId: ownerId,
      ),
    );
    return cost;
  }

  bool equipScroll(int slot, LiteScroll scroll) {
    if (finished || slot < 0 || slot >= equippedScrolls.length) return false;
    equippedScrolls[slot] = scroll;
    return true;
  }

  bool castScroll(int slot, Point<double> target) {
    if (hero == LiteHero.doppelganger ||
        (hero == LiteHero.slimeBlu || hero == LiteHero.reGoblin) && slot == 0)
      return false;
    if (finished ||
        shopOpen ||
        blocking ||
        slot < 0 ||
        slot >= equippedScrolls.length ||
        _scrollCooldown > 0) {
      return false;
    }
    final scroll = equippedScrolls[slot];
    final usesArt =
        hero == LiteHero.duplicatore &&
        (slot > 0 ||
            scrolls[scroll.index] <= 0 && learnedScrolls.contains(scroll));
    if (usesArt
        ? !learnedScrolls.contains(scroll)
        : scrolls[scroll.index] <= 0) {
      message = usesArt
          ? 'Impara prima questa Art usando una pergamena con Q.'
          : 'Qui serve una pergamena.';
      return false;
    }
    final companionSlotsFull =
        clones.where((clone) => clone.ownerId == 0).length >= 3;
    if (oculum < scroll.cost ||
        (scroll == LiteScroll.richiamo && companionSlotsFull)) {
      message = scroll == LiteScroll.richiamo && companionSlotsFull
          ? 'Non ci sono posti compagno liberi.'
          : 'Oculum insufficiente.';
      return false;
    }
    lookAt(target);
    _scrollCooldown = .46;
    oculum -= scroll.cost;
    if (!usesArt) {
      scrolls[scroll.index]--;
      if (_rng.nextDouble() < (hero == LiteHero.duplicatore ? .70 : .35)) {
        learnedScrolls.add(scroll);
      }
    }
    final modifier =
        (weapon == LiteWeapon.scettro ? 1 + magicBonus : 1.0) *
        (1 + _power(LitePowerUp.prisma));
    switch (scroll) {
      case LiteScroll.dardo:
        projectiles.add(
          LiteProjectile(
            position: position,
            direction: aim,
            speed: 17,
            remaining: 12,
            damage: 24 * modifier,
            magic: true,
          ),
        );
      case LiteScroll.onda:
        for (final enemy in _attackableCreatures) {
          if (enemy.hp > 0 &&
              _distanceSquared(position, enemy.position) <=
                  _square(4.3 + enemy.radius) &&
              !_lineBlocked(position, enemy.position)) {
            if (_enemyIntangible(enemy)) {
              _recordIntangible(enemy);
              continue;
            }
            _hitEnemy(enemy, 19 * modifier);
            enemy.position = _move(
              enemy.position,
              _unit(enemy.position - position) * 1.3,
              enemy.radius,
            );
          }
        }
      case LiteScroll.velo:
        shield = max(shield, 15);
      case LiteScroll.richiamo:
        final p = _safePoint(position - aim * 1.2, .35, position);
        clones.add(
          LiteClone(p, 9, LiteWeapon.spadaScudo, summoned: true, id: _nextId++),
        );
      case LiteScroll.braceErrante:
        _launchFireball(position, aim, 22 * modifier, 3, null);
      case LiteScroll.spaccaterra:
        _fissure(position, aim, 7.8, 29 * modifier, null);
      case LiteScroll.falciLunari:
        _lunarVolley(position, aim, 14 * modifier);
      case LiteScroll.linfaVerde:
        _healFighter(maxHp * .20);
        _block.recover(weapon);
      case LiteScroll.raggioAlPlasma:
        projectiles.add(
          LiteProjectile(
            position: position,
            direction: aim,
            speed: 45,
            remaining: 10,
            damage: 22 * modifier,
            magic: true,
            kind: LiteProjectileKind.plasma,
          ),
        );
    }
    return true;
  }

  void _enemyTick(LiteEnemy enemy, double elapsed) {
    if (enemy.kind == LiteEnemyKind.baghest && enemy.stunned <= 0) {
      _baghestTick(enemy, elapsed);
      return;
    }
    if (enemy.burrow != null) {
      _tickBurrow(enemy, elapsed);
      return;
    }
    if (enemy.stunned > 0) {
      enemy.stunned = max(0, enemy.stunned - elapsed);
      enemy.windup = 0;
      return;
    }
    if (enemy.muddied > 0) {
      enemy.muddied = max(0, enemy.muddied - elapsed);
      final phase = (enemy.muddied * 6).floor();
      final angle =
          _LiteRandom(seed ^ enemy.id * 20011 ^ phase * 189657).nextDouble() *
          2 *
          pi;
      enemy.position = _move(
        enemy.position,
        Point(cos(angle), sin(angle)) * (elapsed * enemy.kind.speed * .82),
        enemy.radius,
      );
      enemy.windup = 0;
      return;
    }
    if (enemy.kind == LiteEnemyKind.reGoblin)
      this._goblinSummons(enemy, elapsed);
    if (enemy.clashRemaining > 0) {
      final slice = min(elapsed, enemy.clashRemaining);
      enemy.position = _move(
        enemy.position,
        enemy.clashDirection * (slice * 10.5),
        enemy.radius,
      );
      enemy.clashRemaining = max(0, enemy.clashRemaining - elapsed);
      _recordBurstTrace(-enemy.id, enemy.position, enemy.clashRemaining);
      return;
    }
    enemy.hitFlash = max(0, enemy.hitFlash - elapsed);
    if (this._answerSlime(enemy, elapsed)) return;
    if (enemy.kind == LiteEnemyKind.veyrth) {
      _tickVeyrth(enemy, elapsed);
      return;
    }
    if (enemy.kind == LiteEnemyKind.arconte) {
      _tickArchon(enemy, elapsed);
      return;
    }
    if (_tickThirdEnemy(enemy, elapsed)) return;
    if (enemy.mirror != null) {
      _tickMirror(enemy, elapsed);
      return;
    }
    final ranged = _ranged(enemy.kind);
    if (enemy.windup > 0) {
      enemy.windup = max(0, enemy.windup - elapsed);
      if (enemy.windup == 0) _resolveEnemyAttack(enemy, ranged);
      return;
    }
    enemy.cooldown = max(0, enemy.cooldown - elapsed);
    final kind = enemy.kind;
    final cannon = kind == LiteEnemyKind.granScostumato;
    final target = enemy.guard != null
        ? _campTarget(enemy, elapsed)
        : _enemyAimFrom(enemy.position, ignoreBreakable: cannon);
    if (target == null) {
      enemy.attackTarget = null;
      return;
    }
    final distance = _distance(target, enemy.position);
    enemy.attackTarget = target;
    final ideal = switch (kind) {
      LiteEnemyKind.granScostumato => 10.5,
      LiteEnemyKind.ragnoSaldatore => 8.6,
      LiteEnemyKind.dronePostea => 6.4,
      LiteEnemyKind.scostubandito => 7.5,
      LiteEnemyKind.miruscyrus => 4.6,
      LiteEnemyKind.rasvyr => 3.25,
      LiteEnemyKind.orbryx => 3.8,
      LiteEnemyKind.lupoLunare => 4.2,
      LiteEnemyKind.goblinFango || LiteEnemyKind.goblinColla => 7.2,
      LiteEnemyKind.goblinColtello => 4.2,
      LiteEnemyKind.reGoblin => 2.8,
      LiteEnemyKind.guardianoSolare => enemy.combatCycle % 3 == 2 ? 3.4 : 12,
      LiteEnemyKind.eliteSolare => 7.4,
      LiteEnemyKind.custodeLunare => 3.35,
      LiteEnemyKind.diavolo => 10.2,
      LiteEnemyKind.demoneMinore => 3.5,
      LiteEnemyKind.demoneIntermedio || LiteEnemyKind.demoneMaggiore => 3.1,

      _ => 1.15 + enemy.radius,
    };
    final canWindUp = enemy.cooldown <= 0 && distance < ideal;
    final needsApproach = distance > ideal * .84;
    final lineBlocked =
        (canWindUp || !needsApproach) &&
        _lineBlocked(enemy.position, target, ignoreBreakable: cannon);
    if (canWindUp && !lineBlocked) {
      enemy.windup = switch (kind) {
        LiteEnemyKind.granScostumato => 1.05,
        LiteEnemyKind.ragnoSaldatore => .72,
        LiteEnemyKind.miruscyrus => .46,
        LiteEnemyKind.rasvyr => .53,
        LiteEnemyKind.orbryx => .62,
        LiteEnemyKind.lupoLunare => .48,
        LiteEnemyKind.goblinFango || LiteEnemyKind.goblinColla => .78,
        LiteEnemyKind.goblinColtello => .27,
        LiteEnemyKind.reGoblin => .31,
        LiteEnemyKind.guardianoSolare => 1.10,
        LiteEnemyKind.custodeLunare => .86,
        LiteEnemyKind.eliteSolare || LiteEnemyKind.eliteLunare => .66,

        _ => kind.elite ? .52 : .34,
      };
      return;
    }
    final needsSpace =
        ranged && kind != LiteEnemyKind.guardianoSolare && distance < 3.1;
    final strafe =
        ranged && !needsApproach && !needsSpace && enemy.cooldown > .35;
    if (needsApproach || lineBlocked || needsSpace || strafe) {
      final dx = target.x - enemy.position.x;
      final dy = target.y - enemy.position.y;
      final scale = distance <= 1e-9 ? 0.0 : (needsSpace ? -1 : 1) / distance;
      final forward = Point(dx * scale, dy * scale);
      final flank =
          Point(-forward.y, forward.x) * (enemy.id.isEven ? 1.0 : -1.0);
      final direction = strafe
          ? flank
          : !ranged && distance > 3.1 && !lineBlocked
          ? _unit(forward + flank * .28)
          : forward;
      final speed =
          enemy.kind.speed *
          (strafe ? .48 : 1) *
          this.terrainSpeedAt(enemy.position, enemy: true) *
          elapsed *
          (arenaTrial == LiteArenaTrial.caccia ? 1.15 : 1) *
          (enemy.hitFlash > 0 || enemy.shockRemaining > 0 ? .70 : 1);
      enemy.position = _chooseLane(
        enemy.position,
        direction,
        speed,
        enemy.radius,
        rightFirst: enemy.id.isEven,
      );
    }
  }

  String get bossStatus {
    final boss = enemies
        .where((enemy) => enemy.kind == LiteEnemyKind.arconte)
        .firstOrNull;
    if (boss != null) {
      final attack = boss.attacking ? boss.archonAttack : null;
      return ' · Arconte ${boss.archonPhase}/3'
          '${attack == null ? '' : ' · ${attack.label}'}';
    }
    return switch (finalBossPhase) {
      LiteFinalBossPhase.inactive || LiteFinalBossPhase.defeated => '',
      LiteFinalBossPhase.tangible => ' · Veyrth vulnerabile',
      LiteFinalBossPhase.intangible => ' · Distruggi gli echi',
      LiteFinalBossPhase.beamTangible => ' · Raggio attivo',
      LiteFinalBossPhase.beamIntangible => ' · Raggio ed echi attivi',
    };
  }

  (Point<double>, Point<double>)? archonFault(LiteEnemy boss) {
    final mark = boss.attackTarget;
    if (mark == null) return null;
    final heading = _unit(mark - boss.position);
    if (heading.magnitude <= 1e-9) return null;
    var distance = _boundBeam(boss.position, heading);
    for (final wall in obstacles) {
      distance = min(
        distance,
        _beamCoverDistance(boss.position, heading, wall, distance),
      );
    }
    return (boss.position, boss.position + heading * distance);
  }

  Iterable<Point<double>> archonCrownDirections(LiteEnemy boss) sync* {
    final to = (boss.attackTarget ?? position) - boss.position;
    final angle = atan2(to.y, to.x);
    // Leave a gap in the direction of the marked target.
    for (var i = 1; i < 12; i++) {
      final heading = angle + i * pi / 6;
      yield Point(cos(heading), sin(heading));
    }
  }

  void _tickArchon(LiteEnemy boss, double elapsed) {
    const patterns = [
      [LiteArchonAttack.impact, LiteArchonAttack.fault],
      [LiteArchonAttack.fault, LiteArchonAttack.crown, LiteArchonAttack.impact],
      [
        LiteArchonAttack.crown,
        LiteArchonAttack.impact,
        LiteArchonAttack.fault,
        LiteArchonAttack.impact,
      ],
    ];
    final phase = boss.archonPhase;
    if (phase == 3 && quests.firstOrNull?.current == 0) _progressQuest(0);
    if (boss.windup > 0) {
      boss.windup = max(0, boss.windup - elapsed);
      if (boss.windup > 0) return;
      if (boss.archonAttack case final attack?) {
        _resolveArchonAttack(boss, attack);
      }
      boss.archonAttack = null;
      boss.cooldown = [1.65, 1.38, 1.14][phase - 1];
      return;
    }
    boss.cooldown = max(0, boss.cooldown - elapsed);
    if (boss.cooldown > 0) return;
    final pattern = patterns[phase - 1];
    final attack = pattern[boss.combatCycle++ % pattern.length];
    final target = _enemyAimFrom(boss.position);
    boss.attackTarget = target == boss.position
        ? target + const Point<double>(-1, 0)
        : target;
    boss.archonAttack = attack;
    boss.windup = attack.windup;
  }

  void _resolveArchonAttack(LiteEnemy boss, LiteArchonAttack attack) {
    boss._strikePose = .24;
    final damage =
        attack.damage *
        difficulty.enemyStrength *
        _challengeDamageScale(boss.kind);
    if (attack == LiteArchonAttack.crown) {
      for (final heading in archonCrownDirections(boss)) {
        projectiles.add(
          LiteProjectile(
            position: boss.position,
            direction: heading,
            speed: 8.4,
            remaining: 28,
            damage: damage,
            fromEnemy: true,
            magic: true,
            kind: LiteProjectileKind.veyrthSphere,
          ),
        );
      }
      return;
    }
    final mark = boss.attackTarget;
    if (mark == null) return;
    final lane = attack == LiteArchonAttack.fault ? archonFault(boss) : null;
    if (attack == LiteArchonAttack.fault && lane == null) return;
    if (lane == null) {
      _recordImpact(LiteImpactTarget.verdict, boss.id, mark);
    } else {
      if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
      _combatImpacts.add(
        LiteCombatImpact(
          LiteImpactTarget.fissure,
          _nextId++,
          lane.$1,
          time,
          end: lane.$2,
        ),
      );
    }
    bool hits(Point<double> at, double radius) {
      if (lane == null) return _distance(at, mark) <= attack.radius + radius;
      final axis = _unit(lane.$2 - lane.$1);
      final offset = at - lane.$1;
      final along = offset.x * axis.x + offset.y * axis.y;
      final across = (offset.x * axis.y - offset.y * axis.x).abs();
      return along >= 0 &&
          along <= _distance(lane.$1, lane.$2) &&
          across <= attack.radius + radius &&
          !_lineBlocked(lane.$1, at);
    }

    if (!hostDown && hits(position, _playerRadius)) _damagePlayer(damage);
    for (final ally in _damageableAllies) {
      if (ally.hp > 0 && hits(ally.position, .42)) _hitAlly(ally, damage);
    }
  }

  void _tickVeyrth(LiteEnemy boss, double elapsed) {
    boss.summonIn -= elapsed;
    if (boss.summonIn <= 1e-9) {
      boss.summonIn += finalSummonInterval;
      final angle = _rng.nextDouble() * 2 * pi;
      final near = boss.position + Point(cos(angle), sin(angle)) * 2.0;
      _spawnEnemy(LiteEnemyKind.minionVeyrth, near);
    }
    boss.beamReadyIn = max(0, boss.beamReadyIn - elapsed);
    if (_activeBeam != null) return;
    if (boss.windup > 0) {
      boss.windup = max(0, boss.windup - elapsed);
      if (boss.windup > 1e-9) return;
      boss.windup = 0;
      if (boss.preparingBeam) {
        boss.preparingBeam = false;
        if (!finalBossTangible) {
          boss.windup = finalSphereWindup;
          return;
        }
        final direction = _unit(_enemyAimFrom(boss.position) - boss.position);
        _activeBeam = LiteBeam(
          boss.position,
          direction == const Point<double>(0, 0)
              ? const Point(-1, 0)
              : direction,
        );
        boss.beamReadyIn = 11.5;
        message = 'Veyrth ha scatenato il raggio. Cerca un riparo.';
      } else {
        _fireVeyrthSpheres(boss);
      }
      boss.cooldown = 1.35;
      return;
    }
    boss.cooldown = max(0, boss.cooldown - elapsed);
    if (boss.cooldown > 0) return;
    boss.preparingBeam = boss.beamReadyIn <= 0 && finalBossTangible;
    boss.attackTarget = _enemyAimFrom(boss.position);
    boss.windup = boss.preparingBeam ? .75 : finalSphereWindup;
  }

  void _tickMirror(LiteEnemy boss, double elapsed) {
    final build = boss.mirror!;
    build.signatureCooldown = max(0, build.signatureCooldown - elapsed);
    build.shadowVeilRemaining = max(0, build.shadowVeilRemaining - elapsed);
    build.intangible = max(0, build.intangible - elapsed);
    build.talentCooldown = max(0, build.talentCooldown - elapsed);
    build.artCooldown = max(0, build.artCooldown - elapsed);
    final recovery = build.power(LitePowerUp.condotto);
    if (recovery > 0) {
      build.oculum = min(maxOculum, build.oculum + recovery * elapsed);
    }
    if (boss.windup > 0) {
      boss.windup = max(0, boss.windup - elapsed);
      if (boss.windup > 1e-9) return;
      boss.windup = 0;
      if (build.chargingVerdict) {
        build.chargingVerdict = false;
        final mark = boss.attackTarget;
        if (mark != null) _resolveVerdict(boss, mark);
        return;
      }
      _fireMirrorWeapon(
        boss,
        _unit((boss.attackTarget ?? position) - boss.position),
      );
      return;
    }
    boss.cooldown = max(0, boss.cooldown - elapsed);
    final target = _enemyAimFrom(boss.position);
    boss.attackTarget = target;
    final delta = target - boss.position;
    final distance = delta.magnitude;
    final direction = _unit(delta);
    final ranged = _usesRangedWeapon(boss);
    final isLight = boss.kind == LiteEnemyKind.luce;
    final hasLine = !_lineBlocked(boss.position, target);
    if (build.signatureCooldown <= 0 && distance <= 10.5) {
      if (boss.kind == LiteEnemyKind.ombra &&
          (_mirrorThreatened(boss) || distance < 6.1)) {
        _shadowStep(boss, target, direction);
        return;
      }
      if (isLight && hasLine) {
        build.signatureCooldown = 6.8;
        build.chargingVerdict = true;
        boss.windup = .76;
        boss.cooldown = .65;
        return;
      }
    }
    if (!boss.kind.echo && build.talentCooldown <= 0 && hasLine) {
      if (build.hero == LiteHero.evasore && _mirrorThreatened(boss)) {
        build.intangible = .21;
        build.talentCooldown = isLight ? 3.2 : 4.2;
        final side = Point(-direction.y, direction.x) * (isLight ? 1.4 : -1.4);
        boss.position = _move(boss.position, side, boss.radius);
        return;
      }
      if (build.hero == LiteHero.duplicatore &&
          distance < (isLight ? 6.5 : 10.0) &&
          _summonMirrorEcho(boss)) {
        build.talentCooldown = isLight ? 5.2 : 4.25;
        return;
      }
    }
    if (!boss.kind.echo &&
        build.artCooldown <= 0 &&
        hasLine &&
        _castMirrorScroll(boss, direction, distance)) {
      return;
    }
    final reach = build.weapon.range * (isLight && ranged ? .88 : .76);
    if (boss.cooldown <= 0 && distance <= reach && hasLine) {
      boss.windup = switch (build.weapon) {
        LiteWeapon.carabinaImpulsi => .43,
        LiteWeapon.piccaOssidiana => .20,
        LiteWeapon.balestraRunica => .29,
        LiteWeapon.guanti => .32,
        _ => isLight ? .28 : .17,
      };
      boss.cooldown = build.weapon.cooldown + (isLight ? .45 : .3);
      return;
    }
    final retreats = isLight && ranged && distance < reach * .55;
    if (!retreats && hasLine && distance <= reach * .85) return;
    final stride =
        boss.kind.speed *
        elapsed *
        (1 + build.power(LitePowerUp.passo)) *
        (boss.shockRemaining > 0 ? .70 : 1) *
        (retreats ? -.70 : 1.0);
    final next = _move(boss.position, direction * stride, boss.radius);
    if (next != boss.position) {
      boss.position = next;
    } else {
      final side =
          Point(-direction.y, direction.x) *
          (stride * (boss.id.isEven ? -1 : 1));
      boss.position = _move(boss.position, side, boss.radius);
    }
  }

  void _shadowStep(LiteEnemy boss, Point<double> target, Point<double> toward) {
    final build = boss.mirror!;
    final side = Point(-toward.y, toward.x);
    final firstSide = build.actionCycle.isEven ? side : side * -1.0;
    for (final offset in [
      firstSide * 3.8 - toward * 1.35,
      firstSide * -3.8 - toward * 1.35,
      toward * 3.7,
    ]) {
      final candidate = target + offset;
      if (_blocked(candidate, boss.radius)) continue;
      boss.position = candidate;
      break;
    }
    build.signatureCooldown = 9.0;
    build.shadowVeilRemaining = shadowVeilDuration;
    boss.cooldown = .57;
    message = 'La tua Ombra attraversa il Velo · Intangibile per 3 s.';
  }

  void _resolveVerdict(LiteEnemy boss, Point<double> mark) {
    _recordImpact(LiteImpactTarget.verdict, boss.id, mark);
    final damage =
        verdictDamage *
        (1 + boss.mirror!.power(LitePowerUp.prisma)) *
        _challengeDamageScale(boss.kind);
    if (_distanceSquared(position, mark) <= _square(verdictRadius) &&
        !_lineBlocked(boss.position, position)) {
      _damagePlayer(damage);
    }
    for (final clone in _damageableAllies) {
      if (_distanceSquared(clone.position, mark) <= _square(verdictRadius) &&
          !_lineBlocked(boss.position, clone.position)) {
        _hitAlly(clone, damage);
      }
    }
  }

  bool _mirrorThreatened(LiteEnemy boss) {
    if (_distanceSquared(position, boss.position) <= 2.1 * 2.1 &&
        _attackCooldown > .04) {
      return true;
    }
    for (final shot in projectiles) {
      if (shot.fromEnemy || shot.remaining <= 0) continue;
      if (_distanceSquared(shot.position, boss.position) <= 3 * 3) return true;
    }
    return false;
  }

  bool _summonMirrorEcho(LiteEnemy boss, {bool summoned = false}) {
    var duplicates = 0;
    var summons = 0;
    for (final other in enemies) {
      if (other.kind != LiteEnemyKind.ecoSpeculare || other.hp <= 0) continue;
      if (other.mirrorSummon) {
        summons++;
      } else {
        duplicates++;
      }
    }
    if (summoned ? summons >= 1 : duplicates >= 2) return false;
    final cost = (boss.maxHp * cloneFraction).ceilToDouble();
    if (!summoned && boss.hp - cost < 1) return false;
    if (!summoned) boss.hp -= cost;
    final build = boss.mirror!;
    final direction = _unit(position - boss.position);
    final beside =
        Point(-direction.y, direction.x) * (duplicates.isEven ? 1.3 : -1.3);
    final echo = _spawnEnemy(
      LiteEnemyKind.ecoSpeculare,
      boss.position + beside,
      maxHealth: summoned ? 9 : cost,
    );
    echo.mirrorSummon = summoned;
    echo.mirror = LiteMirrorBuild(
      hero: build.hero,
      weapon: summoned ? LiteWeapon.spadaScudo : build.weapon,
      slots: [],
      quantities: [],
      learned: {},
      oculum: 0,
      damage: summoned ? 8 : build.damage,
      shield: 0,
    );
    return true;
  }

  bool _castMirrorScroll(
    LiteEnemy boss,
    Point<double> direction,
    double distance,
  ) {
    final build = boss.mirror!;
    final count = build.slots.length;
    for (var offset = 0; offset < count; offset++) {
      final slot = (build.actionCycle + offset) % count;
      final scroll = build.slots[slot];
      final stock = build.quantities[scroll.index];
      final usesArt =
          build.hero == LiteHero.duplicatore &&
          (slot > 0 || stock <= 0 && build.learned.contains(scroll));
      if (build.oculum < scroll.cost ||
          (usesArt ? !build.learned.contains(scroll) : stock <= 0)) {
        continue;
      }
      final modifier =
          (build.weapon == LiteWeapon.scettro ? 1 + magicBonus : 1.0) *
          (1 + build.power(LitePowerUp.prisma)) *
          _challengeDamageScale(boss.kind);
      switch (scroll) {
        case LiteScroll.velo:
          if (build.shield >= 8 || distance > 12) continue;
          build.shield = 15;
        case LiteScroll.onda:
          if (distance > 4.3 + _playerRadius) continue;
          _damagePlayer(19 * modifier);
        case LiteScroll.richiamo:
          if (distance > 10 || !_summonMirrorEcho(boss, summoned: true)) {
            continue;
          }
        case LiteScroll.falciLunari:
          if (distance > 10) continue;
          _lunarVolley(boss.position, direction, 14 * modifier, enemy: true);
        case LiteScroll.linfaVerde:
          boss.hp = min(boss.maxHp, boss.hp + boss.maxHp * .12);
        case LiteScroll.braceErrante ||
            LiteScroll.spaccaterra ||
            LiteScroll.dardo ||
            LiteScroll.raggioAlPlasma:
          final plasma = scroll == LiteScroll.raggioAlPlasma;
          if (distance > (plasma ? 10 : 12)) continue;
          projectiles.add(
            LiteProjectile(
              position: boss.position,
              direction: direction,
              speed: plasma ? 45 : 17,
              remaining: plasma ? 10 : 12,
              damage: (plasma ? 22 : 24) * modifier,
              fromEnemy: true,
              magic: true,
              kind: plasma
                  ? LiteProjectileKind.plasma
                  : LiteProjectileKind.normal,
            ),
          );
      }
      if (!usesArt) build.quantities[scroll.index]--;
      build.oculum -= scroll.cost;
      build.artCooldown = boss.kind == LiteEnemyKind.luce ? 2.4 : 1.75;
      build.actionCycle = slot + 1;
      return true;
    }
    return false;
  }

  void _fireMirrorWeapon(LiteEnemy boss, Point<double> direction) {
    final build = boss.mirror!;
    final item = build.weapon;
    final damage =
        build.damage *
        (.78 + stage * .012) *
        difficulty.enemyStrength *
        _challengeDamageScale(boss.kind);
    switch (item) {
      case LiteWeapon.spadaScudo ||
          LiteWeapon.guanti ||
          LiteWeapon.piccaOssidiana:
        _mirrorMelee(
          boss,
          direction,
          item.range,
          damage,
          minDot: item.thrustArc,
        );
        return;
      case LiteWeapon.doppieLame:
        _mirrorMelee(boss, direction, item.range, damage * .56);
        boss.position = _move(boss.position, direction * 1.05, boss.radius);
        _mirrorMelee(boss, direction, item.range, damage * .56);
        return;
      case LiteWeapon.falceRunica:
        _mirrorMelee(boss, direction, item.range, damage, minDot: .10);
      default:
        break;
    }
    projectiles.add(
      LiteProjectile(
        position: boss.position,
        direction: direction,
        speed: switch (item) {
          LiteWeapon.arco => 23,
          LiteWeapon.carabinaImpulsi => 30,
          LiteWeapon.balestraRunica => 29,
          LiteWeapon.falceRunica => 12,
          LiteWeapon.chakram => 21,
          _ => 15,
        },
        remaining: item == LiteWeapon.falceRunica
            ? LiteWeapon.scytheReturnRange
            : item.range,
        damage: switch (item) {
          LiteWeapon.scettro => damage * (1 + magicBonus),
          LiteWeapon.falceRunica => damage * .50,
          _ => damage,
        },
        fromEnemy: true,
        ownerCanHeal: false,
        magic: item == LiteWeapon.scettro,
        boomerang: item.returns,
        kind: switch (item) {
          LiteWeapon.falceRunica => LiteProjectileKind.scythe,
          LiteWeapon.chakram => LiteProjectileKind.chakram,
          LiteWeapon.carabinaImpulsi => LiteProjectileKind.pulse,
          LiteWeapon.balestraRunica => LiteProjectileKind.frostBolt,
          _ => LiteProjectileKind.normal,
        },
      ),
    );
  }

  void _mirrorMelee(
    LiteEnemy boss,
    Point<double> direction,
    double reach,
    double damage, {
    double minDot = .38,
  }) {
    if (_counterClash(boss, reach) ||
        _interceptWithMelee(
          boss.position,
          direction,
          reach,
          minDot: minDot,
          fromEnemy: true,
        )) {
      return;
    }
    for (final clone in _damageableAllies) {
      if (_inArc(
            boss.position,
            direction,
            clone.position,
            reach + .35,
            minDot: minDot,
          ) &&
          !_lineBlocked(boss.position, clone.position)) {
        _hitAlly(clone, damage);
      }
    }
    if (_inArc(
          boss.position,
          direction,
          position,
          reach + _playerRadius,
          minDot: minDot,
        ) &&
        !_lineBlocked(boss.position, position)) {
      _damagePlayer(damage);
    }
  }

  void _fireVeyrthSpheres(LiteEnemy boss) {
    for (var i = 0; i < finalSphereCount; i++) {
      final direction = boss.sphereDirection(i);
      final formedAt = boss.position + direction * finalSphereRingRadius;
      final spawn =
          _blocked(formedAt, .12) || _lineBlocked(boss.position, formedAt)
          ? boss.position
          : formedAt;
      projectiles.add(
        LiteProjectile(
          position: spawn,
          direction: direction,
          speed: 7.2,
          remaining: 24,
          damage:
              14 * difficulty.enemyStrength * _challengeDamageScale(boss.kind),
          fromEnemy: true,
          magic: true,
          kind: LiteProjectileKind.veyrthSphere,
        ),
      );
    }
  }

  void _tickFinalBeam(double elapsed) {
    final beam = _activeBeam;
    if (beam == null) return;
    final slice = min(elapsed, beam.remaining);
    beam.remaining = max(0, beam.remaining - slice);
    final target = _enemyAimFrom(beam.origin) - beam.origin;
    if (target.magnitude > .01) {
      final current = atan2(beam.direction.y, beam.direction.x);
      final wanted = atan2(target.y, target.x);
      final difference = (wanted - current + pi) % (2 * pi) - pi;
      final next = current + difference.clamp(-.38 * slice, .38 * slice);
      beam.direction = Point(cos(next), sin(next));
    }
    var distance = _boundBeam(beam.origin, beam.direction);
    LiteObstacle? cover;
    for (final wall in obstacles) {
      final hit = _beamCoverDistance(
        beam.origin,
        beam.direction,
        wall,
        distance,
      );
      if (hit >= distance) continue;
      distance = hit;
      cover = wall;
    }
    beam.end = beam.origin + beam.direction * distance;
    if (cover == null || !identical(cover, beam._cover)) {
      beam.coverContact = 0;
      beam._cover = cover;
    }
    if (cover != null) {
      beam.coverContact += slice;
      if (beam.coverContact + 1e-9 >= finalBeamCoverSeconds) {
        _destroyCover(cover);
        beam._cover = null;
        beam.coverContact = 0;
        message = 'Il raggio di Veyrth ha sfondato il riparo.';
      }
    }
    beam._pulseRemaining -= slice;
    if (beam._pulseRemaining <= 1e-9) {
      beam._pulseRemaining += .42;
      final damage =
          8.0 *
          difficulty.enemyStrength *
          _challengeDamageScale(LiteEnemyKind.veyrth);
      for (final clone in _damageableAllies) {
        if (_beamTouches(beam, clone.position, distance, .30)) {
          _hitAlly(clone, damage);
        }
      }
      if (_beamTouches(beam, position, distance, .46)) _damagePlayer(damage);
    }
    if (beam.remaining <= 1e-9 || dead) _activeBeam = null;
  }

  double _boundBeam(Point<double> from, Point<double> direction) {
    var distance = 28.0;
    if (direction.x > 1e-9) {
      distance = min(distance, (width - from.x) / direction.x);
    }
    if (direction.x < -1e-9) distance = min(distance, -from.x / direction.x);
    if (direction.y > 1e-9) {
      distance = min(distance, (height - from.y) / direction.y);
    }
    if (direction.y < -1e-9) distance = min(distance, -from.y / direction.y);
    return distance;
  }

  static double _beamCoverDistance(
    Point<double> from,
    Point<double> direction,
    LiteObstacle wall,
    double limit,
  ) {
    var near = 0.0;
    var far = limit;
    if (direction.x.abs() <= 1e-9) {
      if (from.x < wall.left || from.x > wall.left + wall.width) return limit;
    } else {
      final a = (wall.left - from.x) / direction.x;
      final b = (wall.left + wall.width - from.x) / direction.x;
      near = max(near, min(a, b));
      far = min(far, max(a, b));
    }
    if (direction.y.abs() <= 1e-9) {
      if (from.y < wall.top || from.y > wall.top + wall.height) return limit;
    } else {
      final a = (wall.top - from.y) / direction.y;
      final b = (wall.top + wall.height - from.y) / direction.y;
      near = max(near, min(a, b));
      far = min(far, max(a, b));
    }
    return near <= far ? near : limit;
  }

  static bool _beamTouches(
    LiteBeam beam,
    Point<double> p,
    double reach,
    double radius,
  ) {
    final dx = p.x - beam.origin.x;
    final dy = p.y - beam.origin.y;
    final along = dx * beam.direction.x + dy * beam.direction.y;
    final across = dx * beam.direction.y - dy * beam.direction.x;
    return along >= 0 && along <= reach && across.abs() <= radius;
  }

  static bool _ranged(LiteEnemyKind kind) =>
      kind == LiteEnemyKind.scostubandito ||
      kind == LiteEnemyKind.granScostumato ||
      kind == LiteEnemyKind.ragnoSaldatore ||
      kind == LiteEnemyKind.dronePostea ||
      kind == LiteEnemyKind.goblinFango ||
      kind == LiteEnemyKind.goblinColla ||
      kind == LiteEnemyKind.guardianoSolare ||
      kind == LiteEnemyKind.eliteSolare ||
      kind == LiteEnemyKind.diavolo ||
      kind == LiteEnemyKind.veyrth;

  static bool _usesRangedWeapon(LiteEnemy enemy) =>
      switch (enemy.mirror?.weapon) {
        null => _ranged(enemy.kind),
        LiteWeapon.spadaScudo ||
        LiteWeapon.guanti ||
        LiteWeapon.doppieLame ||
        LiteWeapon.piccaOssidiana => false,
        _ => true,
      };

  void _resolveEnemyAttack(LiteEnemy enemy, bool ranged) {
    final target = enemy.attackTarget ?? position;
    final direction = _unit(target - enemy.position);
    final kind = enemy.kind;
    final scale = difficulty.enemyStrength * (1 + .12 * max(0, stage - 1));
    final rawDamage = kind.damage * scale * _challengeDamageScale(kind);
    final damage =
        kind == LiteEnemyKind.goblinFango || kind == LiteEnemyKind.goblinColla
        ? min(rawDamage, 7 / _floorDamageScale)
        : rawDamage;
    enemy.cooldown = switch (kind) {
      LiteEnemyKind.granScostumato => 2.05,
      LiteEnemyKind.ragnoSaldatore => 2.2,
      LiteEnemyKind.dronePostea => 1.15,
      LiteEnemyKind.miruscyrus => 1.3,
      LiteEnemyKind.reGoblin ||
      LiteEnemyKind.goblinFango ||
      LiteEnemyKind.goblinColla => 1.8,
      LiteEnemyKind.goblinColtello => .92,
      _ => ranged ? 1.35 : 1.15,
    };
    if (kind == LiteEnemyKind.guardianoSolare ||
        kind == LiteEnemyKind.eliteSolare) {
      _solarVolley(enemy, direction, damage);
      return;
    }
    if (kind == LiteEnemyKind.diavolo) {
      for (final spread in [-.28, 0.0, .28]) {
        final bend = _rotate(direction, spread);
        projectiles.add(
          LiteProjectile(
            position: enemy.position,
            direction: bend,
            speed: 12,
            remaining: 14,
            damage: damage * .73,
            kind: LiteProjectileKind.fireball,
            fromEnemy: true,
            magic: true,
            bounces: 1,
          ),
        );
      }
      return;
    }
    if (kind == LiteEnemyKind.demoneIntermedio ||
        kind == LiteEnemyKind.custodeLunare) {
      _astralImpact(enemy.position + direction * .9, 2.7, damage);
      return;
    }
    if (ranged) {
      _fireEnemyProjectile(enemy, direction, damage);
      return;
    }
    if (kind == LiteEnemyKind.miruscyrus ||
        kind == LiteEnemyKind.rasvyr ||
        kind == LiteEnemyKind.orbryx ||
        kind == LiteEnemyKind.lupoLunare ||
        kind == LiteEnemyKind.goblinColtello ||
        kind == LiteEnemyKind.demoneMinore ||
        kind == LiteEnemyKind.demoneMaggiore) {
      final charge = min(
        3.25,
        max(0.0, _distance(enemy.position, target) - .62),
      );
      final strides = (charge / .22).ceil();
      for (var i = 0; i < strides; i++) {
        final next = _move(
          enemy.position,
          direction * (charge / strides),
          enemy.radius,
        );
        if (next == enemy.position) break;
        enemy.position = next;
      }
    }
    final reach = 1.35 + enemy.radius;
    if (_counterClash(enemy, reach) ||
        _interceptWithMelee(
          enemy.position,
          direction,
          reach,
          minDot: -1,
          fromEnemy: true,
        )) {
      return;
    }
    for (final clone in _damageableAllies) {
      if (_distance(enemy.position, clone.position) <= reach &&
          !_lineBlocked(enemy.position, clone.position)) {
        final before = clone.hp;
        _hitAlly(clone, damage);
        if (kind == LiteEnemyKind.reGoblin &&
            clone.hp < before &&
            clone.hp > 0 &&
            clone is LiteCoopFighter) {
          clone._night.stun = .6;
          clone._dashRemaining = 0;
          clone._windup = 0;
          clone._block.held = false;
        }
      }
    }
    if (_distance(enemy.position, position) <= reach &&
        !_lineBlocked(enemy.position, position)) {
      final before = hp;
      _damagePlayer(damage);
      if (kind == LiteEnemyKind.reGoblin && hp < before && hp > 0) {
        _night.stun = .6;
        _burstTime = _windup = 0;
        _block.held = false;
      }
    }
  }

  void _fireEnemyProjectile(
    LiteEnemy enemy,
    Point<double> direction,
    double damage,
  ) {
    final kind = enemy.kind;
    if (kind == LiteEnemyKind.goblinFango ||
        kind == LiteEnemyKind.goblinColla) {
      projectiles.add(
        LiteProjectile(
          position: enemy.position,
          direction: direction,
          speed: 9.5,
          remaining: 8.5,
          damage: damage,
          kind: kind == LiteEnemyKind.goblinColla
              ? LiteProjectileKind.glue
              : LiteProjectileKind.mud,
          fromEnemy: true,
        ),
      );
      return;
    }
    if (kind == LiteEnemyKind.dronePostea) {
      final side = Point(-direction.y, direction.x) * .085;
      for (final shot in [_unit(direction + side), _unit(direction - side)]) {
        projectiles.add(
          LiteProjectile(
            position: enemy.position,
            direction: shot,
            speed: 13,
            remaining: 10,
            damage: damage * .65,
            fromEnemy: true,
            kind: LiteProjectileKind.pulse,
          ),
        );
      }
      return;
    }
    projectiles.add(
      LiteProjectile(
        position: enemy.position,
        direction: direction,
        speed: switch (kind) {
          LiteEnemyKind.granScostumato => 10.5,
          LiteEnemyKind.ragnoSaldatore => 45,
          _ => 8.6,
        },
        remaining: switch (kind) {
          LiteEnemyKind.granScostumato => 16,
          LiteEnemyKind.ragnoSaldatore => 10,
          _ => 12,
        },
        damage: damage,
        fromEnemy: true,
        nonLethal: kind == LiteEnemyKind.scostubandito,
        kind: switch (kind) {
          LiteEnemyKind.scostubandito => LiteProjectileKind.rifleBullet,
          LiteEnemyKind.granScostumato => LiteProjectileKind.cannon,
          LiteEnemyKind.ragnoSaldatore => LiteProjectileKind.plasma,
          _ => LiteProjectileKind.normal,
        },
      ),
    );
  }

  Point<double> _chooseLane(
    Point<double> at,
    Point<double> heading,
    double step,
    double radius, {
    required bool rightFirst,
  }) {
    final direct = _move(at, heading * step, radius);
    if (_distanceSquared(at, direct) > _square(step * .68)) return direct;
    final sign = rightFirst ? 1.0 : -1.0;
    var best = direct;
    var clearance = _distanceSquared(at, direct);
    for (final turn in [.72 * sign, -.72 * sign, 1.43 * sign, -1.43 * sign]) {
      final alternate = _rotate(heading, turn);
      final candidate = _move(at, alternate * step, radius);
      final safeAhead = _move(candidate, alternate * .48, radius);
      final room =
          _distanceSquared(candidate, at) +
          .022 * _distanceSquared(safeAhead, candidate);
      if (room > clearance) {
        clearance = room;
        best = candidate;
      }
      if (_distanceSquared(at, best) > _square(step * .9) &&
          !_blocked(safeAhead, radius))
        break;
    }
    return best;
  }

  LiteEnemy? _companionTarget(LiteClone clone, Point<double> owner) {
    LiteEnemy? chosen;
    var best = double.infinity;
    final ranged =
        clone.weapon.range > 5 && clone.weapon != LiteWeapon.boomerang;
    for (final foe in enemies) {
      if (foe.hp <= 0 || _enemyIntangible(foe)) continue;
      final distance = _distance(clone.position, foe.position);
      final clearance = _lineBlocked(clone.position, foe.position)
          ? (ranged ? 5.0 : 2.0)
          : 0.0;
      final threatensOwner = _distanceSquared(foe.position, owner) < 9;
      final score =
          distance +
          clearance +
          foe.hp / foe.maxHp * 1.8 -
          (threatensOwner ? 2.8 : 0);
      if (score < best) {
        best = score;
        chosen = foe;
      }
    }
    return chosen;
  }

  void _cloneTick(LiteClone clone, double elapsed) {
    final owner = _coopFighterById(clone.ownerId);
    final rooms = clone.recruitedFloor == null
        ? ((owner?.level ?? level) - 1).clamp(0, 12)
        : (stage - clone.recruitedFloor! + actRoom + thirdRoom).clamp(0, 12);
    final training = clone.companion == null ? 0.0 : rooms * .04;
    final paceScale = clone.companion == null
        ? 1.0
        : 1 +
              _power(LitePowerUp.legameVigile) +
              training * .45 +
              _profileBonus(LitePermanentUpgrade.passoCompagno, owner) / 100;
    clone.cooldown = max(0, clone.cooldown - elapsed * paceScale);
    if (owner != null && !owner.connected) return;
    final ownerPosition = owner?.position ?? position;
    final enemy = _companionTarget(clone, ownerPosition);
    final pace =
        elapsed *
        4.7 *
        paceScale *
        this.terrainSpeedAt(clone.position, enemy: false);
    if (enemy == null ||
        (clone.companion != LiteCompanion.lupoAlleato &&
            _distanceSquared(clone.position, ownerPosition) > 150)) {
      final angle = (clone.id % 8) * pi / 4;
      final goal = ownerPosition + Point(cos(angle), sin(angle)) * 1.48;
      if (_distanceSquared(clone.position, goal) > .40) {
        clone.position = _chooseLane(
          clone.position,
          _unit(goal - clone.position),
          pace,
          .35,
          rightFirst: clone.id.isEven,
        );
      }
      return;
    }
    final close =
        _distanceSquared(clone.position, enemy.position) <=
            _square(clone.weapon.range * .8) &&
        !_lineBlocked(clone.position, enemy.position);
    final direction = _unit(enemy.position - clone.position);
    final ranged =
        clone.weapon.range > 5 && clone.weapon != LiteWeapon.boomerang;
    if (ranged && _distanceSquared(clone.position, enemy.position) < 9) {
      final retreat = _move(
        clone.position,
        direction * (-elapsed * 3.6 * paceScale),
        .35,
      );
      if (retreat != clone.position) {
        clone.position = retreat;
        return;
      }
    }
    if (close && clone.cooldown > 0) return;
    if (!close) {
      clone.position = _chooseLane(
        clone.position,
        direction,
        pace,
        .35,
        rightFirst: clone.id.isEven,
      );
      return;
    }
    if (clone.companion == LiteCompanion.goblinFango ||
        clone.companion == LiteCompanion.goblinColla) {
      clone.cooldown = 1.8;
      clone._poseAim = direction;
      clone._swing = .23;
      projectiles.add(
        LiteProjectile(
          position: clone.position,
          direction: direction,
          speed: 10,
          remaining: 8.5,
          damage: min(7, 5 * clone.damageScale * (1 + training)),
          kind: clone.companion == LiteCompanion.goblinColla
              ? LiteProjectileKind.glue
              : LiteProjectileKind.mud,
          ownerCanHeal: false,
          sourceCloneId: clone.id,
        ),
      );
      return;
    }
    final cannon = clone.companion == LiteCompanion.granScostumato;
    clone.cooldown = cannon ? 2.2 : clone.weapon.cooldown * 1.22;
    clone._poseAim = direction;
    clone._swing = .23;
    if (cannon) {
      projectiles.add(
        LiteProjectile(
          position: clone.position,
          direction: direction,
          speed: 14,
          remaining: 15,
          damage:
              LiteCompanion.granScostumato.damage *
              clone.damageScale *
              (1 + training),
          kind: LiteProjectileKind.cannon,
          ownerCanHeal: false,
          sourceCloneId: clone.id,
        ),
      );
      return;
    }
    if (clone.companion == LiteCompanion.guardianoLunare) {
      if (_lineBlocked(clone.position, enemy.position)) return;
      _hitEnemy(
        enemy,
        LiteCompanion.guardianoLunare.damage *
            clone.damageScale *
            (1 + training),
        ownerCanHeal: false,
        sourceCloneId: clone.id,
      );
      if (enemy.hp > 0) this._ram(enemy, clone.position, 12);
      return;
    }
    _weaponAction(
      clone.position,
      direction,
      clone.weapon,
      (clone.companion?.damage ??
              (clone.summoned
                  ? 8
                  : owner == null
                  ? _damageFor(clone.weapon)
                  : 8.0 +
                        clone.weapon.damageBonus +
                        owner.permanentDamage +
                        2 * (owner.level - 1))) *
          clone.damageScale *
          (1 + training),
      ownerCanHeal: false,
      sourceCloneId: clone.id > 0 ? clone.id : null,
    );
  }

  LiteEnemy? _nearestEnemy(Point<double> from, {Set<int> skip = const {}}) {
    LiteEnemy? closest;
    var best = double.infinity;
    for (final enemy in faunaAggressive ? _attackableCreatures : enemies) {
      if (enemy.hp <= 0 || skip.contains(enemy.id) || _enemyIntangible(enemy))
        continue;
      final distance = _distanceSquared(from, enemy.position);
      if (distance < best) {
        best = distance;
        closest = enemy;
      }
    }
    return closest;
  }

  bool _interceptWithMelee(
    Point<double> origin,
    Point<double> direction,
    double reach, {
    double minDot = .38,
    bool fromEnemy = false,
  }) {
    LiteProjectile? intercepted;
    var nearest = (reach + .24) * (reach + .24);
    for (final shot in projectiles) {
      if (shot.remaining <= 0 || shot.fromEnemy == fromEnemy) continue;
      final distance = _distanceSquared(origin, shot.position);
      if (distance > nearest ||
          !_inArc(
            origin,
            direction,
            shot.position,
            reach + .24,
            minDot: minDot,
          ) ||
          _lineBlocked(origin, shot.position)) {
        continue;
      }
      intercepted = shot;
      nearest = distance;
    }
    if (intercepted == null) return false;
    intercepted.remaining = 0;
    _recordImpact(LiteImpactTarget.clash, 0, intercepted.position);
    return true;
  }

  void _clashProjectiles(double elapsed) {
    for (final playerShot in projectiles) {
      if (playerShot.fromEnemy ||
          playerShot.remaining <= 0 ||
          playerShot.eggFuse != null)
        continue;
      final from = playerShot.position;
      final playerStep =
          playerShot.direction *
          min(playerShot.remaining, playerShot.speed * elapsed);
      var firstContact = double.infinity;
      LiteProjectile? intercepted;
      for (final enemyShot in projectiles) {
        if (!enemyShot.fromEnemy || enemyShot.remaining <= 0) continue;
        final separation = from - enemyShot.position;
        final enemyStep =
            enemyShot.direction *
            min(enemyShot.remaining, enemyShot.speed * elapsed);
        final relative = playerStep - enemyStep;
        final speedSquared = _square(relative.x) + _square(relative.y);
        final fraction = speedSquared <= 1e-9
            ? 0.0
            : (-(separation.x * relative.x + separation.y * relative.y) /
                      speedSquared)
                  .clamp(0.0, 1.0);
        if (fraction >= firstContact) continue;
        final radius =
            playerShot.kind == LiteProjectileKind.cannon ||
                enemyShot.kind == LiteProjectileKind.cannon
            ? .40
            : .28;
        if ((separation + relative * fraction).magnitude > radius ||
            _blocked(from + playerStep * fraction, .12) ||
            _blocked(enemyShot.position + enemyStep * fraction, .12)) {
          continue;
        }
        firstContact = fraction;
        intercepted = enemyShot;
      }
      if (intercepted != null) {
        playerShot.remaining = intercepted.remaining = 0;
        final at = from + playerStep * firstContact;
        _recordImpact(LiteImpactTarget.clash, 0, at);
        final sparks = _power(LitePowerUp.braci);
        if (sparks > 0) {
          for (final enemy in enemies) {
            if (_distanceSquared(at, enemy.position) <= 4 &&
                !_lineBlocked(at, enemy.position)) {
              _hitEnemy(enemy, sparks, ownerCanHeal: false);
            }
          }
        }
      }
    }
  }

  void _projectileTick(LiteProjectile projectile, double elapsed) {
    if (projectile.remaining <= 0) return;
    if (_finalBossDefeated && !inThirdAct && projectile.fromEnemy) {
      projectile.remaining = 0;
      return;
    }
    projectile.age += elapsed;
    if (projectile.kind == LiteProjectileKind.egg ||
        projectile.kind == LiteProjectileKind.posteaEgg) {
      _tickEgg(projectile, elapsed);
      return;
    }
    if (projectile.kind == LiteProjectileKind.posteaRay) {
      _steerPosteaRay(projectile, elapsed);
    }
    if (projectile.kind == LiteProjectileKind.spiral) {
      projectile.direction = _rotate(projectile.direction, .91 * elapsed);
    }
    if (projectile.boomerang) {
      if (projectile.returning) {
        final returnTo = projectileReturnTarget(projectile);
        if (_distanceSquared(projectile.position, returnTo) < .58 * .58) {
          projectile.remaining = 0;
          return;
        }
        projectile.direction = _unit(returnTo - projectile.position);
      } else if (!projectile.fromEnemy &&
          projectile.kind != LiteProjectileKind.scythe &&
          projectile.age > .16) {
        final enemy = _nearestEnemy(projectile.position);
        if (enemy != null && !projectile.hit.contains(enemy.id)) {
          final bend = _unit(enemy.position - projectile.position);
          projectile.direction = _unit(
            projectile.direction + bend * (elapsed * 4),
          );
        }
      }
    }
    final travelled = min(projectile.remaining, projectile.speed * elapsed);
    final next = projectile.position + projectile.direction * travelled;
    final cannon = projectile.kind == LiteProjectileKind.cannon;
    final hitRadius = cannon ? .24 : .12;
    if (_blocked(next, hitRadius)) {
      for (final wall in obstacles) {
        if (wall.breakable && wall.visibleAt(next, hitRadius)) {
          _breakObstacle(
            wall,
            cannon ? max(wall.hp, projectile.damage) : projectile.damage,
            projectile.origin,
            partyAttack:
                !projectile.fromEnemy &&
                (projectile.ownerCanHeal ||
                    _coopFighterById(projectile.sourceCloneId) != null),
            sourceCloneId: projectile.sourceCloneId,
          );
          break;
        }
      }
      if (!cannon || _blocked(next, hitRadius)) {
        if (projectile.kind == LiteProjectileKind.fireball &&
            projectile.bounces > 0) {
          final at = projectile.position;
          final xBlocked = _blocked(Point(next.x, at.y), hitRadius);
          final yBlocked = _blocked(Point(at.x, next.y), hitRadius);
          final vector = projectile.direction;
          projectile.direction = Point(
            xBlocked || !yBlocked ? -vector.x : vector.x,
            yBlocked || !xBlocked ? -vector.y : vector.y,
          );
          projectile.bounces--;
          projectile.remaining -= travelled;
          return;
        }
        _stopProjectile(projectile);
        return;
      }
    }
    if (projectile.kind == LiteProjectileKind.posteaRay &&
        _ignitePosteaEgg(projectile, next)) {
      projectile.remaining = 0;
      return;
    }
    projectile.position = next;
    projectile.remaining -= travelled;
    if (projectile.kind == LiteProjectileKind.bomb) {
      if (projectile.remaining <= 1e-9) _stopProjectile(projectile);
      return;
    }
    if (projectile.fromEnemy) {
      for (final clone in _damageableAllies) {
        if (clone.hp > 0 &&
            !(clone is LiteCoopFighter && clone.protected) &&
            _distanceSquared(next, clone.position) <=
                _square(cannon ? .62 : .43)) {
          if (projectile.boomerang && !projectile.hit.add(-clone.id - 2)) {
            continue;
          }
          if (projectile.kind == LiteProjectileKind.mud &&
              clone is LiteCoopFighter)
            clone._night.mud = .9;
          _hitAlly(clone, projectile.damage);
          if (!projectile.boomerang) {
            _stopProjectile(projectile);
            return;
          }
        }
      }
      if (!invulnerable &&
          _distanceSquared(next, position) <=
              _square(cannon ? .68 : _playerRadius) &&
          (!projectile.boomerang || projectile.hit.add(-1))) {
        if (projectile.kind == LiteProjectileKind.mud) _night.mud = .9;
        _damagePlayer(projectile.damage, nonLethal: projectile.nonLethal);
        if (!projectile.boomerang) {
          _stopProjectile(projectile);
          return;
        }
        if (projectile.returning &&
            projectile.kind == LiteProjectileKind.scythe) {
          final direction = _unit(projectile.origin - position);
          position = _move(position, direction * .90, _playerRadius);
        }
      }
      if (projectile.remaining <= 1e-9) {
        _stopProjectile(projectile);
      }
      return;
    }
    for (final clone in clones) {
      if (clone.corrupted &&
          clone.hp > 0 &&
          clone.position.distanceTo(next) < .56 &&
          projectile.hit.add(clone.id)) {
        _hitRedAlly(clone, projectile.damage);
        if (!projectile.boomerang) {
          _stopProjectile(projectile);
          return;
        }
      }
    }
    for (final enemy in _attackableCreatures) {
      if (enemy.hp <= 0 ||
          !enemy.hitboxContains(next) ||
          projectile.hit.contains(enemy.id)) {
        continue;
      }
      // A bow target centred beyond 10 m stays out of range even if its
      // collision radius overlaps the endpoint of the flight.
      if (!projectile.magic &&
          !projectile.boomerang &&
          projectile.kind == LiteProjectileKind.normal &&
          _distanceSquared(projectile.origin, enemy.position) >
              _square(bowRange + 1e-9)) {
        continue;
      }
      if (_enemyIntangible(enemy)) {
        if (projectile.ownerCanHeal) _recordIntangible(enemy);
        continue;
      }
      projectile.hit.add(enemy.id);
      if (projectile.kind == LiteProjectileKind.mud) enemy.muddied = .9;
      _hitEnemy(
        enemy,
        projectile.damage,
        ownerCanHeal: projectile.ownerCanHeal,
        sourceCloneId: projectile.sourceCloneId,
        impactFrom: projectile.origin,
      );
      if (projectile.kind == LiteProjectileKind.rifleCritical) {
        final skills = projectile.ownerCanHeal
            ? _bandit
            : _banditForFighter(projectile.sourceCloneId);
        if (skills != null) skills.dodgeReady = true;
        message = 'Fucile schivata · prossimo scatto intangibile.';
      }
      if (projectile.kind == LiteProjectileKind.frostBolt &&
          enemy.hp > 0 &&
          !enemy.kind.boss &&
          !enemy.kind.elite) {
        enemy.hitFlash = max(enemy.hitFlash, .64);
      }
      if (projectile.returning &&
          projectile.kind == LiteProjectileKind.scythe &&
          enemy.hp > 0) {
        final direction = _unit(
          projectileReturnTarget(projectile) - enemy.position,
        );
        enemy.position = _move(enemy.position, direction * .90, enemy.radius);
      }
      final canPierce =
          projectile.kind == LiteProjectileKind.pulse &&
          projectile.hit.length < 2;
      if (projectile.kind == LiteProjectileKind.fireball &&
          projectile.bounces > 0) {
        final target = _nearestEnemy(next, skip: projectile.hit);
        if (target != null &&
            _distanceSquared(next, target.position) <= 49 &&
            !_lineBlocked(next, target.position)) {
          projectile.direction = _unit(target.position - next);
        } else {
          projectile.direction = projectile.direction * -1.0;
        }
        projectile.bounces--;
        break;
      }
      if (!projectile.boomerang && !canPierce) {
        _stopProjectile(projectile);
        return;
      }
    }
    if (projectile.remaining <= 1e-9) _stopProjectile(projectile);
  }

  Point<double> projectileReturnTarget(LiteProjectile projectile) {
    if (projectile.ownerCanHeal) return position;
    final id = projectile.sourceCloneId;
    if (id != null) {
      for (final fighter in coopFighters) {
        if (fighter.id == id && fighter.hp > 0) return fighter.position;
      }
      for (final clone in clones) {
        if (clone.id == id && clone.hp > 0) return clone.position;
      }
    }
    return projectile.origin;
  }

  void _stopProjectile(LiteProjectile projectile) {
    if (projectile.kind == LiteProjectileKind.mud ||
        projectile.kind == LiteProjectileKind.glue) {
      this._leaveGroundShot(projectile);
    }
    if (projectile.kind == LiteProjectileKind.bomb) {
      _openBurst(
        projectile.position,
        2.65,
        projectile.damage,
        projectile.sourceCloneId ?? 0,
        push: .75,
      );
      if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
      _combatImpacts.add(
        LiteCombatImpact(
          LiteImpactTarget.explosion,
          _nextId++,
          projectile.position,
          time,
        ),
      );
    }
    if (projectile.boomerang && !projectile.returning) {
      projectile.returning = true;
      projectile.remaining = 42;
      projectile.hit.clear();
      return;
    }
    projectile.remaining = 0;
  }

  void _breakObstacle(
    LiteObstacle obstacle,
    double damage,
    Point<double> source, {
    bool partyAttack = false,
    int? sourceCloneId,
  }) {
    if (!obstacle.breakable ||
        !obstacles.contains(obstacle) ||
        obstacle.mapShortcut && source.x <= obstacle.center.x + .2)
      return;
    obstacle.hp -= damage;
    if (obstacle.hp > 0) return;
    _destroyCover(obstacle);
    if (partyAttack &&
        !obstacle.mapShortcut &&
        !obstacle.secretGate &&
        !obstacle.solarGate) {
      final shards = _power(LitePowerUp.schegge);
      if (shards > 0) {
        _recordImpact(LiteImpactTarget.explosion, _nextId++, obstacle.center);
        for (final enemy in [...enemies]) {
          if (enemy.hp > 0 &&
              enemy.position.distanceTo(obstacle.center) <= 2.6 &&
              !_lineBlocked(obstacle.center, enemy.position)) {
            _hitEnemy(
              enemy,
              shards,
              ownerCanHeal: sourceCloneId == null,
              sourceCloneId: sourceCloneId,
              impactFrom: obstacle.center,
            );
          }
        }
      }
    }
    if (biome == LiteBiome.dungeon && !isFinalFloor) {
      final direction = _unit(source - obstacle.center);
      if (direction != const Point<double>(0, 0)) {
        projectiles.add(
          LiteProjectile(
            position: obstacle.center,
            direction: direction,
            speed: 6,
            remaining: 3.6,
            damage: 12,
            fromEnemy: true,
          ),
        );
      }
    }
  }

  void _destroyCover(LiteObstacle obstacle) {
    if (!obstacles.remove(obstacle)) return;
    _campNoise(obstacle.center, 8);
    if (obstacle.mapShortcut) {
      message = 'Scorciatoia aperta verso il bivio.';
      return;
    }
    if (obstacle.solarGate) {
      solarStairs = obstacle.center;
      achievements.add('scale-d-oro');
      _progressOptionalQuest('scale');
      message = 'Scale d’oro scoperte. Avvicinati e premi R a fine scontro.';
      return;
    }
    if (obstacle.secretGate) {
      achievements.add('sala-segreta-scoperta');
      if (!achievements.add(_secretRoomKey)) return;
      final mainRoom = !inActTwo && !inThirdAct;
      message = mainRoom && stage >= 6 && stage < 12
          ? 'Ingresso del Campo goblin scoperto. Raggiungi il sigillo a fine scontro.'
          : 'Sala segreta scoperta.';
      if (mainRoom && biome == LiteBiome.orea) {
        _discoverPet(LiteCompanion.orbietto, secretCache);
      }
      loot.addAll([
        LiteLoot(secretCache, LiteLootKind.obser, 20),
        LiteLoot(secretCache + const Point(.62, 0), LiteLootKind.greenStone, 1),
        LiteLoot(
          secretCache - const Point(.62, 0),
          LiteLootKind.scroll,
          1,
          scroll: const [
            LiteScroll.braceErrante,
            LiteScroll.spaccaterra,
            LiteScroll.linfaVerde,
          ][_LiteRandom(seed ^ stage).nextInt(3)],
        ),
      ]);
      return;
    }
    loot.add(LiteLoot(obstacle.center, LiteLootKind.obser, 3));
    if (isVeyrthArena || isFinalFloor) _progressQuest(1);
  }

  bool _enemyIntangible(LiteEnemy enemy) =>
      enemy.clashRemaining > 0 ||
      enemy.burrow?.exposed == false ||
      enemy.kind == LiteEnemyKind.veyrth && !finalBossTangible ||
      (enemy.mirror?.intangible ?? 0) > 0 ||
      (enemy.mirror?.shadowVeilRemaining ?? 0) > 0;

  void _recordIntangible(LiteEnemy enemy) {
    _recordImpact(
      LiteImpactTarget.enemy,
      enemy.id,
      enemy.position,
      intangible: true,
      enemyKind: enemy.kind,
    );
  }

  void _recordImpact(
    LiteImpactTarget target,
    int id,
    Point<double> at, {
    double life = 0,
    double shield = 0,
    bool intangible = false,
    LiteEnemyKind? enemyKind,
    bool silent = false,
  }) {
    if (life <= 0 &&
        shield <= 0 &&
        !intangible &&
        target != LiteImpactTarget.verdict &&
        target != LiteImpactTarget.clash &&
        target != LiteImpactTarget.explosion) {
      return;
    }
    final mergeWindow = target == LiteImpactTarget.clash
        ? 0.0
        : intangible
        ? combatImpactDuration
        : .17;
    for (var i = _combatImpacts.length - 1; i >= 0; i--) {
      final earlier = _combatImpacts[i];
      if (time - earlier.time >= mergeWindow) break;
      if (earlier.target != target ||
          earlier._id != id ||
          earlier.intangible != intangible ||
          earlier.silent != silent) {
        continue;
      }
      if (!intangible) {
        _combatImpacts.removeAt(i);
        _combatImpacts.add(
          earlier
            ..position = at
            ..time = time
            ..life += life
            ..shield += shield,
        );
      }
      return;
    }
    if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
    _combatImpacts.add(
      LiteCombatImpact(
        target,
        id,
        at,
        time,
        life: life,
        shield: shield,
        intangible: intangible,
        enemyKind: enemyKind,
        silent: silent,
      ),
    );
  }

  void _hitAlly(LiteClone clone, double damage) {
    damage *= _floorDamageScale;
    if (clone is LiteCoopFighter) {
      if (clone.protected || clone.hp <= 0) return;
      if (clone.supply.fed(LiteRestItem.crosta, stage)) damage *= .80;
      if (clone._night.solarMantle > 0) damage *= .55;
      damage *= 1 - relicProtection;
      if (clone.hero == LiteHero.cavaliereLunare &&
          clone.weapon == LiteWeapon.spadaScudo) {
        damage = max(1, damage - 2);
      }
      if (clone.blocking) {
        if (solarCampaign) _progressOptionalQuest('lunare');
        damage = clone._block.absorb(clone.weapon, damage);
        if (damage <= 0) return;
      }
      final absorbed = min(clone.shield, damage);
      clone.shield -= absorbed;
      final life = min(clone.hp, damage - absorbed);
      clone.hp -= life;
      clone._protection = life > 0 ? lifeHitProtection : shieldHitProtection;
      if (clone._rescue case final rescue?) {
        rescue.pause = rescueHitPause;
      }
      if (clone._mimic case final form? when clone.hp <= 0) {
        _revertMimic(form, clone);
      }
      if (clone.hp <= 0 && clone.supply.token) {
        clone.supply.token = false;
        clone.hp = clone.maxHp * .35;
        clone._protection = 1.9;
        message = 'Il Gettone di Rinascita salva ${clone.name}.';
      }
      if (clone.hp <= 0) _tryAnimalRebirth(clone);
      if (clone.hp <= 0) {
        clone._night.reset();
        clone._plagueFormRemaining = 0;
        endRescue(clone);
        clone
          .._windup = 0
          .._strike = const Point(0, 0)
          .._dashRemaining = 0
          .._springPose = 0
          .._block.held = false
          ..firing = false
          ..movement = const Point(0, 0);
      }
      _recordImpact(
        LiteImpactTarget.ally,
        clone.id,
        clone.position,
        life: life,
        shield: absorbed,
      );
      if (clone.hero == LiteHero.scostubandito && clone.hp > 0) {
        clone.shield = _banditGuard(
          clone._bandit,
          clone.position,
          clone.shield,
          absorbed,
          clone.level,
        );
      }
      return;
    }
    final previousHp = clone.hp;
    clone._takeDamage(damage);
    _recordImpact(
      LiteImpactTarget.ally,
      clone.id == 0 ? identityHashCode(clone) : clone.id,
      clone.position,
      life: previousHp - clone.hp,
    );
  }

  double _banditGuard(
    _LiteBanditSkills skills,
    Point<double> source,
    double remaining,
    double absorbed,
    int level,
  ) {
    if (absorbed <= 0) return remaining;
    if (remaining <= 0) {
      if (skills.shieldRecovered) return remaining;
      skills.shieldRecovered = true;
      message = 'Oh merda, escono dalle fottute pareti! · Scudo recuperato.';
      return 16 + 2.0 * (level - 1);
    }
    for (final enemy in enemies) {
      if (enemy.hp <= 0 ||
          _enemyIntangible(enemy) ||
          _distanceSquared(source, enemy.position) > 4 ||
          _lineBlocked(source, enemy.position))
        continue;
      _hitEnemy(enemy, 6, ownerCanHeal: false);
      if (enemy.hp > 0) {
        enemy.position = _move(
          enemy.position,
          _unit(enemy.position - source) * .8,
          enemy.radius,
        );
      }
    }
    return remaining;
  }

  void _hitEnemy(
    LiteEnemy enemy,
    double amount, {
    bool ownerCanHeal = true,
    int? sourceCloneId,
    bool vampireStrike = true,
    Point<double>? impactFrom,
    bool forceImpact = false,
    double launch = 0,
  }) {
    if (enemy.hp <= 0 || _enemyIntangible(enemy)) return;
    final vampire = sourceCloneId == null
        ? null
        : coopFighters
              .where((fighter) => fighter.id == sourceCloneId)
              .firstOrNull;
    final hasVampire =
        vampireStrike &&
        (ownerCanHeal ? hero : vampire?.hero) == LiteHero.vampiro;
    final transformed = hasVampire && (vampire?._night ?? _night).sanguine > 0;
    if (transformed) amount *= 2;
    final mirror = enemy.mirror;
    final defense = enemy.kind.elite
        ? 2
        : mirror?.weapon == LiteWeapon.spadaScudo
        ? 1
        : 0;
    var damage = max(1.0, amount * (1 + relicDamage) - defense);
    if (enemy.kind == LiteEnemyKind.aberrazioneSolare && enemy.windup > .12) {
      damage *= .55;
    } else if ((enemy.kind == LiteEnemyKind.eliteLunare ||
            enemy.kind == LiteEnemyKind.custodeLunare) &&
        enemy.cooldown > .70 &&
        !enemy.attacking) {
      final facing = enemy.attackTarget ?? position;
      final forward = _unit(facing - enemy.position);
      final back = _unit(position - enemy.position);
      if (forward.x * back.x + forward.y * back.y > .56) damage *= .60;
    }
    var absorbed = 0.0;
    if (mirror != null && mirror.shield > 0) {
      absorbed = min(mirror.shield, damage);
      mirror.shield -= absorbed;
      damage -= absorbed;
    }
    if (hasVampire && damage + absorbed > 0 && enemy.hp > 0) {
      final force = (vampire?.level ?? level) >= 3 ? 6.0 : 3.0;
      if (this._ram(
        enemy,
        vampire?.position ?? position,
        transformed ? force * 2 : force,
      ))
        damage += 5;
    }
    final lifeLost = min(enemy.hp, damage);
    enemy.hp = max(0, enemy.hp - damage);
    // Player-owned attacks can end this protection. Allies and summons cannot.
    if (ownerCanHeal && (lifeLost > 0 || absorbed > 0)) {
      _hitProtectionRemaining = 0;
    }
    LiteCoopFighter? attacker;
    if (sourceCloneId != null) {
      for (final fighter in coopFighters) {
        if (fighter.id == sourceCloneId) {
          attacker = fighter;
          if (lifeLost > 0 || absorbed > 0) fighter._protection = 0;
          break;
        }
      }
    }
    final plagueSource =
        attacker?.hero == LiteHero.curatorePeste && attacker!.plagueForm
        ? attacker.position
        : ownerCanHeal && hero == LiteHero.curatorePeste && plagueForm
        ? position
        : null;
    if (plagueSource != null && enemy.hp > 0 && lifeLost + absorbed > 0) {
      final grade = attacker?.openGrade ?? openGrade;
      enemy.position = _move(
        enemy.position,
        _unit(enemy.position - plagueSource) * (1.8 + .5 * grade),
        enemy.radius,
      );
    }
    final silent =
        enemy.guard != null &&
        lifeLost + absorbed > 0 &&
        _campImpact(
          enemy,
          impactFrom ?? attacker?.position ?? enemy.position,
          forceImpact && (ownerCanHeal || attacker != null),
          ownerCanHeal
              ? _walking
              : attacker?._slow == true && attacker!._dashRemaining <= 0,
        );
    _recordImpact(
      LiteImpactTarget.enemy,
      enemy.id,
      enemy.position,
      life: lifeLost,
      shield: absorbed,
      enemyKind: enemy.kind,
      silent: silent,
    );
    enemy.hitFlash = .14;
    if (enemy.hp > 0 && launch > 0 && lifeLost + absorbed > 0) {
      _ram(enemy, impactFrom ?? attacker?.position ?? position, launch);
      enemy.stunned = max(enemy.stunned, .55);
    }
    if (enemy.hp <= 0 && !enemy.kind.echo) {
      final origin = impactFrom ?? attacker?.position ?? position;
      final direction = _unit(enemy.position - origin);
      final travel = silent
          ? .55
          : enemy.kind.boss
          ? .81
          : launch > 0
          ? launch
          : forceImpact
          ? 3.5
          : 2.25;
      // Use the same bounded collision sweep as a live knockback.
      final body = LiteEnemy(enemy.id, enemy.kind, enemy.position, 1);
      if (direction.magnitude > 0)
        _ram(body, origin, travel, breakCover: false);
      final endpoint = body.position;
      if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
      _combatImpacts.add(
        LiteCombatImpact(
          LiteImpactTarget.defeat,
          enemy.id,
          enemy.position,
          time,
          end: endpoint,
          enemyKind: enemy.kind,
          silent: silent,
        ),
      );
    }
    if (LiteAnimal.forCreature(enemy.kind) != null) {
      if (lifeLost > 0 && (ownerCanHeal || attacker != null)) {
        _noteFaunaHit(enemy, attacker?.position ?? position);
      }
      if (enemy.hp <= 0 && (ownerCanHeal || attacker != null)) {
        achievements.add('fauna-abbattuta-${enemy.kind.name}');
      }
      return;
    }
    if (enemy.hp > 0) return;
    if (!ownerCanHeal && attacker == null && sourceCloneId != null) {
      final skeleton = clones
          .where(
            (ally) =>
                ally.id == sourceCloneId &&
                (ally.companion?.isSkeleton ?? false),
          )
          .firstOrNull;
      if (skeleton != null) {
        if (skeleton.ownerId == 0) {
          _plagueKill(null);
        } else {
          final owner = coopFighters
              .where((fighter) => fighter.id == skeleton.ownerId)
              .firstOrNull;
          if (owner != null) _plagueKill(owner);
        }
      }
    } else if (ownerCanHeal || attacker != null) {
      _plagueKill(attacker);
    }
    final kind = enemy.kind;
    if (kind == LiteEnemyKind.baghest) _redGrips.clear();
    if (!kind.echo &&
        (attacker?.hero == LiteHero.cavaliereLunare ||
            ownerCanHeal && hero == LiteHero.cavaliereLunare ||
            clones.any(
              (clone) =>
                  clone.id == sourceCloneId &&
                  (clone.companion == LiteCompanion.guardiaLunare ||
                      clone.companion == LiteCompanion.guardianoLunare),
            ))) {
      final roll = _LiteRandom(seed ^ enemy.id * 172479 ^ stage * 30179)
        ..nextDouble()
        ..nextDouble();
      if (roll.nextInt(100) < lunarDropChance(kind)) {
        loot.add(LiteLoot(enemy.position, LiteLootKind.lunarSymbol, 3));
      }
    }
    if (kind.echo) {
      if (kind == LiteEnemyKind.minionVeyrth && isVeyrthArena) {
        _progressQuest(0);
      }
      return;
    }
    final greenDrop = _LiteRandom(seed ^ (stage + 1) * 17401 ^ enemy.id * 977)
        .nextInt(100);
    if (greenDrop < 20) {
      loot.add(
        LiteLoot(
          enemy.position,
          greenDrop < 2
              ? LiteLootKind.refinedGreenGem
              : LiteLootKind.greenStone,
          1,
        ),
      );
    }
    loot.add(
      LiteLoot(
        enemy.position,
        LiteLootKind.obser,
        kind.boss
            ? 15
            : kind.elite
            ? 9
            : 3,
      ),
    );
    _dropWeapon(enemy);
    if (enemy.kind == LiteEnemyKind.ragnoSaldatore && _rng.nextInt(20) == 19) {
      loot.add(
        LiteLoot(
          enemy.position,
          LiteLootKind.scroll,
          1,
          scroll: LiteScroll.raggioAlPlasma,
        ),
      );
    }
    if (kind == LiteEnemyKind.slime) slimeKills = min(10, slimeKills + 1);
    if (kind == LiteEnemyKind.goblinColla)
      achievements.add(LiteCompanion.goblinColla.unlockKey);
    if (kind == LiteEnemyKind.reGoblin) {
      achievements.add(heroUnlockKey(LiteHero.reGoblin));
      obser += 30;
      message = 'Re Goblin sbloccato.';
      return;
    }
    if (this.goblinCamp &&
        (kind == LiteEnemyKind.goblinFango ||
            kind == LiteEnemyKind.goblinColtello ||
            kind == LiteEnemyKind.goblinColla)) {
      loot.add(LiteLoot(enemy.position, LiteLootKind.obser, 2));
      return;
    }
    if (kind.boss) {
      if (kind.playableBoss case final unlocked?) {
        achievements.add(heroUnlockKey(unlocked));
      }
      spentOculum += 5;
      crystals++;
      bossCrystalGrades.add(1 + _rng.nextInt(3));
      if (kind == LiteEnemyKind.veyrth) _activeBeam = null;
      if (kind == LiteEnemyKind.arconte && quests.firstOrNull?.current == 0) {
        _progressQuest(0);
      }
      if (kind == LiteEnemyKind.arconte ||
          kind == LiteEnemyKind.veyrth && isFinalFloor) {
        _finalBossDefeated = true;
      }
      _progressQuest(2);
    } else if (kind.elite) {
      eliteDefeated = true;
      spentOculum += 3;
      ascensionDust++;
      _progressQuest(2);
    } else {
      spentOculum++;
      if (quests.firstOrNull?.current == 0 ||
          _rng.nextDouble() < (hero == LiteHero.evasore ? .60 : .30)) {
        final type = switch (kind) {
          LiteEnemyKind.rasvyr => LiteScroll.spaccaterra,
          LiteEnemyKind.orbryx => LiteScroll.linfaVerde,
          LiteEnemyKind.scostubandito
              when _LiteRandom(seed ^ enemy.id * 1021).nextInt(5) == 0 =>
            LiteScroll.braceErrante,
          _ => LiteScroll.ordinary[_rng.nextInt(LiteScroll.ordinary.length)],
        };
        loot.add(
          LiteLoot(enemy.position, LiteLootKind.scroll, 1, scroll: type),
        );
      }
      if (hp < maxHp * .42 && _rng.nextDouble() < .25) {
        loot.add(LiteLoot(enemy.position, LiteLootKind.healing, 10));
      }
      _progressQuest(0);
    }
    if (!dead &&
        ownerCanHeal &&
        hero == LiteHero.evasore &&
        _rng.nextDouble() < healChance) {
      _healFighter(maxHp * healFraction);
    }
    exp += kind.boss
        ? 75
        : kind.elite
        ? 45
        : 16 + stage;
    for (final fighter in coopFighters) {
      final oldLevel = fighter.level;
      fighter.experience += kind.boss
          ? 75
          : kind.elite
          ? 45
          : 16 + stage;
      if (fighter.hp > 0 && fighter.level > oldLevel) {
        fighter
          ..hp = fighter.maxHp
          ..oculum = fighter.maxOculum;
      }
    }
    if (attacker?.hero == LiteHero.evasore &&
        attacker!.hp > 0 &&
        _rng.nextDouble() < healChance) {
      _healFighter(attacker.maxHp * healFraction, attacker);
    }
    while (exp >= level * 45) {
      exp -= level * 45;
      level++;
      hp = maxHp;
      oculum = maxOculum;
      message = 'Livello $level · Vita e Oculum ripristinati.';
    }
    if (kind == LiteEnemyKind.rasvyr) {
      final next = achievements.contains('rasvyr-2')
          ? 3
          : achievements.contains('rasvyr-1')
          ? 2
          : 1;
      achievements.add('rasvyr-$next');
      if (next == 3) _discoverPet(LiteCompanion.piccolaMarea, position);
    }
    _recruitCompanion(kind);
  }

  void _plagueKill(LiteCoopFighter? fighter) {
    if ((fighter?.hero ?? hero) != LiteHero.curatorePeste ||
        (fighter?.hp ?? hp) <= 0)
      return;
    if (fighter == null) {
      _healFighter(maxHp * .08);
      _block.recover(weapon);
    } else {
      _healFighter(fighter.maxHp * .08, fighter);
      fighter._block.recover(fighter.weapon);
    }
  }

  void _recruitCompanion(LiteEnemyKind defeated) {
    final companion = LiteCompanion.unlockedBy(defeated);
    if (companion != null) _discoverPet(companion, position);
  }

  Set<LiteCompanion> get discoveredPets => {
    for (final pet in LiteCompanion.values)
      if (pet.discovery != null && achievements.contains(pet.unlockKey)) pet,
  };

  void _discoverPet(LiteCompanion companion, Point<double> near) {
    if (!achievements.add(companion.unlockKey)) return;
    final beside = near + Point(-aim.y, aim.x) * 1.15;
    clones.add(
      LiteClone(
        _safePoint(beside, .35, near),
        companion.life,
        companion.weapon,
        companion: companion,
        recruitedFloor: stage,
        id: _nextId++,
      ),
    );
    message = '${companion.label} si unisce al gruppo.';
  }

  static int lunarDropChance(LiteEnemyKind kind) => kind.boss
      ? 12
      : kind.elite
      ? 6
      : kind.echo
      ? 0
      : 1;

  static LiteWeapon? bossWeapon(LiteEnemyKind kind) => switch (kind) {
    LiteEnemyKind.luce => LiteWeapon.piccaOssidiana,
    LiteEnemyKind.ombra => LiteWeapon.balestraRunica,
    _ => null,
  };

  void _dropWeapon(LiteEnemy enemy) {
    final item = switch (enemy.kind) {
      LiteEnemyKind.ragnoSaldatore when biome == LiteBiome.postea =>
        LiteWeapon.carabinaImpulsi,
      LiteEnemyKind.dronePostea when biome == LiteBiome.postea =>
        LiteWeapon.doppieLame,
      LiteEnemyKind.miruscyrus when biome == LiteBiome.postea =>
        LiteWeapon.falceRunica,
      _ => bossWeapon(enemy.kind),
    };
    if (item == null ||
        ownedWeapons.contains(item) ||
        loot.any((drop) => drop.weapon == item)) {
      return;
    }
    loot.add(LiteLoot(enemy.position, LiteLootKind.weapon, 1, weapon: item));
  }

  void _damagePlayer(double damage, {bool nonLethal = false}) {
    if (finished || hostDown || invulnerable) return;
    if (supply.fed(LiteRestItem.crosta, stage)) damage *= .80;
    if (_night.solarMantle > 0) damage *= .55;
    damage *= 1 - relicProtection;
    var remaining = max(
      1.0,
      damage * _floorDamageScale -
          (weapon == LiteWeapon.spadaScudo
              ? (hero == LiteHero.cavaliereLunare ? 2 : 1)
              : 0),
    );
    if (blocking) {
      if (solarCampaign) _progressOptionalQuest('lunare');
      remaining = _block.absorb(weapon, remaining);
      if (remaining <= 0) return;
    }
    final absorbed = min(shield, remaining);
    shield -= absorbed;
    remaining -= absorbed;
    final previousHp = hp;
    hp = max(0, hp - remaining);
    final formBroken = hp == 0 && _mimic != null && !nonLethal;
    final collapsed = formBroken ? _mimic! : null;
    if (hp == 0 && nonLethal) hp = 1;
    final lifeLost = max(0.0, previousHp - hp);
    _recordImpact(
      LiteImpactTarget.player,
      0,
      position,
      life: lifeLost,
      shield: absorbed,
    );
    if (lifeLost > 0 || absorbed > 0) {
      _hitProtectionRemaining = lifeLost > 0
          ? lifeHitProtection
          : shieldHitProtection;
      if (_rescue case final rescue?) rescue.pause = rescueHitPause;
    }
    if (hero == LiteHero.scostubandito && hp > 0) {
      shield = _banditGuard(_bandit, position, shield, absorbed, level);
    }
    if (collapsed != null) {
      _revertMimic(collapsed, null);
      return;
    }
    if (hp <= 0) {
      _night.reset();
      _plagueFormRemaining = 0;
    }
    if (remaining <= 0) return;
    if (remaining < previousHp) return;
    if (nonLethal) {
      final robbed = (obser * .75).round();
      obser -= robbed;
      message = 'Lo Scostubandito ti lascia in vita e sottrae $robbed Obser.';
    } else if (supply.token) {
      supply.token = false;
      hp = maxHp * .35;
      _invulnerability = 1.9;
      endRescue();
      _block.held = false;
      message = 'Gettone di Rinascita · sei tornato al 35% della Vita.';
      return;
    } else if (_tryAnimalRebirth()) {
      return;
    } else if (livesRemaining > 0) {
      livesRemaining--;
      _block.held = false;
      endRescue();
      hp = maxHp;
      oculum = maxOculum;
      position = _spawn;
      _invulnerability = 1.25;
      message = 'Rinascita. Ne restano $livesRemaining.';
      return;
    } else {
      if (coopFighters.any((fighter) => fighter.hp > 0)) {
        _windup = 0;
        _burstTime = 0;
        _block.held = false;
        endRescue();
        hp = 0;
        message = 'Sei a terra. Gli altri giocatori possono continuare.';
        return;
      }
      message = 'La run si è conclusa al piano $stage.';
    }
    dead = true;
    achievements.add('prima-run-conclusa');
  }

  void _collectLoot(double seconds) {
    const radiusSquared = _pickupRadius * _pickupRadius;
    var remaining = 0;
    for (var i = 0; i < loot.length; i++) {
      final item = loot[i];
      if (item.kind == LiteLootKind.obser) {
        if (!_collectObser(item, seconds)) loot[remaining++] = item;
        continue;
      }
      final myDistance = hostDown
          ? double.infinity
          : _distanceSquared(position, item.position);
      final healing =
          item.kind == LiteLootKind.healing ||
          item.kind == LiteLootKind.greenStone ||
          item.kind == LiteLootKind.refinedGreenGem;
      if (healing || item.kind == LiteLootKind.lunarSymbol) {
        LiteCoopFighter? guest;
        var nearest = myDistance;
        for (final fighter in coopFighters) {
          if (!fighter.connected || fighter.hp <= 0) continue;
          final distance = _distanceSquared(fighter.position, item.position);
          if (distance <= radiusSquared && distance < nearest) {
            nearest = distance;
            guest = fighter;
          }
        }
        if (guest != null || myDistance <= radiusSquared) {
          if (healing) {
            _collectHealing(item, guest);
          } else {
            (guest?.supply ?? supply).lunarPieces += item.amount;
            message = 'Simbolo della Luna · tre frammenti da 60 Obser.';
          }
          continue;
        }
      }
      if (myDistance > radiusSquared) {
        if (remaining != i) loot[remaining] = item;
        remaining++;
        continue;
      }
      switch (item.kind) {
        case LiteLootKind.scroll:
          scrolls[(item.scroll ?? LiteScroll.dardo).index] += item.amount;
        case LiteLootKind.obser ||
            LiteLootKind.healing ||
            LiteLootKind.greenStone ||
            LiteLootKind.refinedGreenGem ||
            LiteLootKind.lunarSymbol:
          break; // Healing is awarded to the nearest living fighter above.
        case LiteLootKind.weapon:
          final itemWeapon = item.weapon;
          if (itemWeapon != null && !ownedWeapons.contains(itemWeapon)) {
            ownedWeapons.add(itemWeapon);
            message = '${itemWeapon.label} aggiunta all’equipaggiamento.';
          }
      }
    }
    if (remaining < loot.length) loot.removeRange(remaining, loot.length);
  }

  bool _collectObser(LiteLoot item, double seconds) {
    Point<double>? target;
    var best = double.infinity;
    void consider(Point<double> at, double radius) {
      final distance = _distanceSquared(item.position, at);
      if (distance > _square(radius) ||
          distance >= best ||
          _lineBlocked(item.position, at)) {
        return;
      }
      best = distance;
      target = at;
    }

    if (!hostDown) consider(position, obserPullRadius());
    for (final fighter in coopFighters) {
      if (fighter.connected && fighter.hp > 0) {
        consider(fighter.position, obserPullRadius(fighter));
      }
    }
    final near = target;
    if (near == null) return false;
    final distance = sqrt(best);
    final step = _obserPullSpeed * seconds;
    if (distance > _pickupRadius + step) {
      item.position += (near - item.position) * (step / distance);
      return false;
    }
    _awardPartyObser(item.amount);
    // In the boss arenas this slot tracks broken cover, not its coins.
    if (quests.length > 1 && quests[1].id.endsWith(':bottino')) {
      _progressQuest(1);
    }
    return true;
  }

  void _collectHealing(LiteLoot item, LiteCoopFighter? fighter) {
    final maximum = fighter?.maxHp ?? maxHp;
    final full = item.kind == LiteLootKind.refinedGreenGem;
    final amount = full
        ? maximum
        : item.kind == LiteLootKind.greenStone
        ? maximum * .20
        : item.amount;
    _healFighter(amount.toDouble(), fighter);
    if (fighter == null) {
      if (full) oculum = maxOculum;
      _block.recover(weapon);
      if (full) message = 'Gemma verde ridefinita · Vita e Oculum al massimo.';
      if (item.kind == LiteLootKind.greenStone)
        message = 'Pietra verde · +20% Vita massima.';
    } else {
      if (full)
        fighter.oculum =
            10.0 + (fighter.upgrades[LitePermanentUpgrade.oculum] ?? 0);
      fighter._block.recover(fighter.weapon);
    }
  }

  void _progressOptionalQuest(String prefix) {
    final quest = _optionalMissions
        .where((item) => item.id.startsWith('$prefix-'))
        .firstOrNull;
    if (quest == null) return;
    _advanceMission(quest);
  }

  void _progressQuest(int index) => _advanceMission(quests[index]);

  void _advanceMission(LiteQuest quest) {
    if (quest.complete) return;
    quest.current++;
    if (quest.complete) {
      obser += quest.reward;
      for (final fighter in coopFighters) {
        fighter.obser += quest.reward;
      }
      achievements.add(quest.id);
      if (quest.major) crystals++;
    }
  }

  bool interact() {
    if (shakeRedGrip() || challengeBaghest()) return true;
    if (useRest()) return true;
    if (canOpenShop) {
      if (campPatrols &&
          stage == 0 &&
          !stageClear &&
          achievements.add('borsa-della-palizzata')) {
        _awardPartyObser(12);
        message = 'Borsa della palizzata · +12 Obser.';
      }
      shopOpen = true;
      return true;
    }
    if (hasPortalNearby) {
      message = 'Scegli il prossimo piano.';
      return true;
    }
    return beginReload();
  }

  bool beginReload() {
    if (finished ||
        shopOpen ||
        rescuing ||
        reloading ||
        weapon != LiteWeapon.arco ||
        _arrows == bowCapacity) {
      return false;
    }
    _reloadRemaining = reloadDuration;
    message = 'Ricarica in corso…';
    return true;
  }

  _LiteRescue? _rescueFor(LiteCoopFighter? fighter) =>
      fighter == null ? _rescue : fighter._rescue;

  bool beginRescue([LiteCoopFighter? fighter]) {
    if (finished ||
        shopOpen ||
        (fighter == null ? hostDown : fighter.hp <= 0 || !fighter.connected) ||
        _rescueFor(fighter) != null ||
        (fighter?._windup ?? _windup) > 0)
      return false;
    final target = _nearbyRescueTarget(fighter);
    if (target == null) return false;
    final rescue = _LiteRescue(
      target,
      (fighter?.weapon ?? weapon) == LiteWeapon.arco &&
          (fighter?.arrows ?? _arrows) < bowCapacity,
    );
    if (fighter == null) {
      _rescue = rescue;
    } else {
      fighter._rescue = rescue;
    }
    return true;
  }

  void endRescue([LiteCoopFighter? fighter]) {
    if (fighter == null) {
      _rescue = null;
    } else {
      fighter._rescue = null;
    }
  }

  void _tickRescue(double elapsed, [LiteCoopFighter? fighter]) {
    final rescue = _rescueFor(fighter)!;
    final ally = rescue.target.ally;
    final down = switch (ally) {
      null => hostDown,
      LiteCoopFighter() => ally.connected && ally.hp <= 0,
      _ => ally.down,
    };
    final from = fighter?.position ?? position;
    final to = ally?.position ?? position;
    if (!down ||
        _distanceSquared(from, to) > rescueRadius * rescueRadius ||
        _lineBlocked(from, to)) {
      endRescue(fighter);
      return;
    }
    final paused = min(elapsed, rescue.pause);
    rescue.pause -= paused;
    rescue.elapsed += elapsed - paused;
    if (rescue.elapsed + 1e-9 < rescueDuration) return;
    final restoredHp = ((ally?.maxHp ?? maxHp) * rescueHealthFraction)
        .ceilToDouble();
    if (ally == null) {
      hp = restoredHp;
      _hitProtectionRemaining = shieldHitProtection;
    } else {
      ally
        ..hp = restoredHp
        ..downRemaining = 0;
      if (ally is LiteCoopFighter) ally._protection = shieldHitProtection;
    }
    if (rescue.reload) {
      if (fighter == null) {
        _arrows = bowCapacity;
        _reloadRemaining = 0;
      } else {
        fighter
          ..arrows = bowCapacity
          .._reload = 0;
      }
    }
    message = rescue.reload
        ? 'Alleato rialzato e arco ricaricato.'
        : 'Alleato rialzato.';
    endRescue(fighter);
  }

  void closeShop() => shopOpen = false;

  bool buyPotion() {
    if (!shopOpen || obser < potionPrice || hp >= maxHp) return false;
    obser -= potionPrice;
    _healFighter(maxHp * .25);
    message = 'Foglia di Linfa Viva acquistata. Hai recuperato Vita.';
    return true;
  }

  bool buyDodgeUpgrade() {
    if (!shopOpen ||
        hero != LiteHero.evasore ||
        obser < dodgeUpgradePrice ||
        dodgeLevel >= 3) {
      return false;
    }
    obser -= dodgeUpgradePrice;
    dodgeLevel++;
    maxDodgeCharges++;
    dodgeCharges = maxDodgeCharges;
    message = 'Schivata potenziata. Cariche: $maxDodgeCharges.';
    return true;
  }

  bool buyWeapon(LiteWeapon item) {
    if (!canBuyWeapon(item)) return false;
    obser -= priceForWeapon(item);
    ownedWeapons.add(item);
    message = '${item.label} aggiunto all’equipaggiamento.';
    return true;
  }

  bool switchWeapon([int direction = 1]) {
    if (hero == LiteHero.doppelganger) return false;
    if (finished || _windup > 0 || ownedWeapons.length < 2 || direction == 0) {
      return false;
    }
    final index = ownedWeapons.indexOf(weapon);
    weapon =
        ownedWeapons[(index + (direction < 0 ? -1 : 1)) % ownedWeapons.length];
    return true;
  }

  bool advance([LiteBiome? destination]) {
    if (!hasPortalNearby || shopOpen) return false;
    if (solarBossWaiting) return enterSolarBoss();
    if (canChooseActTwo) return false;
    if (nextActTwoRoom) return advanceActTwo();
    if (inThirdAct) return advanceThirdAct();
    return _nextFloor(destination);
  }

  bool advanceCoop(LiteBiome destination) =>
      playerCount > 1 &&
      coopPortalOpen &&
      !canChooseActTwo &&
      (solarBossWaiting
          ? enterSolarBoss()
          : nextActTwoRoom
          ? advanceActTwo()
          : inThirdAct
          ? advanceThirdAct(remote: true)
          : _nextFloor(destination));

  bool _nextFloor(LiteBiome? destination) {
    _noteFaunaCleared();
    final unlocked =
        eliteDefeated &&
        _specialKind(stage) == LiteEnemyKind.forestDemon &&
        clones.any(
          (ally) =>
              ally.companion == LiteCompanion.vedetta &&
              ally.hp > 0 &&
              ally.expiresAfter == null,
        ) &&
        achievements.add(unlockScostubandito);
    for (final ally in clones) {
      final character = ally.companion?.questHero;
      if (character != null &&
          character != LiteHero.scostubandito &&
          ally.hp > 0 &&
          ally.expiresAfter == null &&
          stage > (ally.recruitedFloor ?? -1)) {
        achievements.add(heroUnlockKey(character));
      }
    }
    final next = destination ?? routeBiomes.first;
    stage++;
    biome = next;
    _startStage();
    if (unlocked) message = 'Scostubandito sbloccato per le nuove run.';
    return true;
  }

  Map<String, dynamic> toJson({bool includeEffects = false}) => {
    if (progressId != null) 'progressId': progressId,
    if (actRelics.isNotEmpty)
      'actRelics': actRelics.map((relic) => relic.name).toList(),
    if (_actRelicClaims > 0) 'actRelicClaims': _actRelicClaims,
    if (weaponArtCooldown > 0) 'weaponArtCooldown': weaponArtCooldown,
    if (restHub) 'restHub': true,
    if (realm case final area?) ...{'realm': area.name, 'actRoom': actRoom},
    if (inThirdAct) 'thirdRoom': thirdRoom,
    if (baghestFight) ...{
      'baghestArena': _baghestEncounter,
      if (_redGrips.isNotEmpty)
        'grips': _redGrips.map(
          (id, remaining) => MapEntry(id.toString(), remaining),
        ),
    },
    if (hasFloorMap) ...{
      'mappedFloor': _mappedFloor,
      'mappedSectors': _mappedSectors,
      if (_mapWaypoint case final pin?) 'mapPoint': _savePoint(pin),
    },
    if (_arenaEventStart != null) 'arenaEventStart': _arenaEventStart,
    if (_claimedWell != null) 'claimedWell': _claimedWell,
    if (solarPhase case final phase?) 'solarPhase': phase.name,
    if (solarStairs case final stairs?) 'solarStairs': _savePoint(stairs),
    if (fauna.isNotEmpty)
      'fauna': fauna
          .map((animal) => animal._json(includeEffects: includeEffects))
          .toList(),
    if (_provokedRooms.isNotEmpty) 'provokedRooms': _provokedRooms.toList(),
    if (_sparedRooms.isNotEmpty) 'sparedRooms': _sparedRooms.toList(),
    if (supply.active) 'supplies': supply.frame,
    if (_goblinWave > 0) 'goblinWave': _goblinWave,
    if (allowGlue) 'allowGlue': true,
    if (allowMechanicalChicken) 'allowMechanicalChicken': true,
    if (groundShots.isNotEmpty)
      'groundShots': groundShots.map((floor) => floor.frame).toList(),
    if (slimeKills > 0) 'slimeKills': slimeKills,
    'version': schemaVersion,
    'campaignVersion': _campaignVersion,
    if (lastStage == _legacyFinalStage) 'legacyFinal': true,
    if (_legacyVeyrthFinal) 'legacyVeyrthFinal': true,
    if (_legacyOrdinary23 && stage == veyrthStage) 'legacyOrdinary23': true,
    'seed': seed,
    if (upgrades.isNotEmpty) 'upgrades': LitePermanentUpgrade.encode(upgrades),
    'playerCount': playerCount,
    'rng': _rng.state,
    'hero': hero.name,
    'difficulty': difficulty.name,
    'biome': biome.name,
    'floorLayout': floorLayout.name,
    if (arenaTrial case final trial?) ...{
      'arenaTrial': trial.name,
      'trialStart': _trialStart,
    },
    'startingBiome': _startingBiome.name,
    'weapon': weapon.name,
    'stage': stage,
    'level': level,
    'exp': exp,
    'obser': obser,
    'crystals': crystals,
    'bossCrystalGrades': [...bossCrystalGrades],
    'ascensionDust': ascensionDust,
    'spentOculum': spentOculum,
    'livesRemaining': livesRemaining,
    'hp': hp,
    if (includeEffects && _rescue != null) 'rescue': _rescue!.frame,
    if (plagueForm) 'plagueForm': _plagueFormRemaining,
    if (_mimic case final form?) 'mimic': form.frame,
    if (_night.active) 'night': _night.frame,
    'oculum': oculum,
    'shield': shield,
    'powers': _savePowers(_powerRanks),
    'powerOffers': _powerOffers.map((power) => power.name).toList(),
    'position': _savePoint(position),
    'aim': _savePoint(aim),
    'enemies': enemies
        .map((enemy) => enemy._json(includeEffects: includeEffects))
        .toList(),
    if (includeEffects) 'stride': stride._frame(),
    if (includeEffects && _burstTraces.isNotEmpty)
      'burstTraces': _burstTraces.entries
          .map((entry) => entry.value._frame(entry.key))
          .toList(),
    if (includeEffects && _combatImpacts.isNotEmpty)
      'impacts': _combatImpacts
          .skip(max(0, _combatImpacts.length - 16))
          .map((impact) => impact._frame())
          .toList(),
    'projectiles': projectiles.map((projectile) => projectile._json()).toList(),
    'clones': clones
        .map((clone) => clone._json(includeEffects: includeEffects))
        .toList(),
    if (coopFighters.isNotEmpty)
      'fighters': coopFighters
          .map((fighter) => fighter._wire(includeEffects: includeEffects))
          .toList(),
    'obstacles': obstacles.map((wall) => wall._json()).toList(),
    'loot': loot.map((item) => item._json()).toList(),
    'quests': quests.map((quest) => quest._json()).toList(),
    if (_optionalMissions.isNotEmpty)
      'optionalMissions': _optionalMissions
          .map((mission) => mission._json())
          .toList(),
    'ownedWeapons': ownedWeapons.map((item) => item.name).toList(),
    'scrolls': [...scrolls],
    'equippedScrolls': equippedScrolls.map((item) => item.name).toList(),
    'learnedScrolls': learnedScrolls.map((item) => item.name).toList(),
    'achievements': achievements.toList(),
    'dodgeCharges': dodgeCharges,
    'maxDodgeCharges': maxDodgeCharges,
    'dodgeLevel': dodgeLevel,
    'time': time,
    'stageClear': stageClear,
    'eliteDefeated': eliteDefeated,
    'dead': dead,
    'victorious': victorious,
    'finalBossDefeated': _finalBossDefeated,
    if (_activeBeam != null) 'activeBeam': _activeBeam!._json(obstacles),
    'shopOpen': shopOpen,
    'restUsed': restUsed,
    'eliteReleased': _eliteReleased,
    'nextId': _nextId,
    'attackCooldown': _attackCooldown,
    'windup': _windup,
    'invulnerability': _invulnerability,
    'hitProtectionRemaining': _hitProtectionRemaining,
    if (_clashRemaining > 0) 'clashRemaining': _clashRemaining,
    'burstTime': _burstTime,
    'burstSpeed': _burstSpeed,
    'dashCooldown': _dashCooldown,
    if (_block.worn) 'blockWear': _block.frame,
    if (includeEffects && blocking) 'blocking': true,
    if (_openCooldown > 0) 'openCooldown': _openCooldown,
    if (hero == LiteHero.scostubandito) 'banditSkills': _bandit.frame,
    'dodgeRecharge': _dodgeRecharge,
    if (_springCooldown > 0) 'springCooldown': _springCooldown,
    if (_staffCooldown > 0) 'staffCooldown': _staffCooldown,
    if (_bombCooldown > 0) 'bombCooldown': _bombCooldown,
    if (hero == LiteHero.ashley) 'springPose': _springPose,
    'scrollCooldown': _scrollCooldown,
    'arrows': _arrows,
    'reloadRemaining': _reloadRemaining,
    'burstDirection': _savePoint(_burstDirection),
    'strikeDirection': _savePoint(_strikeDirection),
    'lastMove': _savePoint(_lastMove),
    'message': message,
  };

  factory LiteRun.fromJson(Map<String, dynamic> json) {
    if (json['version'] != schemaVersion) {
      throw const FormatException(
        'Versione del salvataggio Oculum RL non riconosciuta.',
      );
    }
    final run = LiteRun(
      seed: _int(json['seed']),
      progressId: json['progressId'] as String?,
      allowGlue: json['allowGlue'] == true,
      allowMechanicalChicken: json['allowMechanicalChicken'] == true,
      upgrades: LitePermanentUpgrade.read(json['upgrades']),
      hero: _enum(LiteHero.values, json['hero'], LiteHero.evasore),
      weapon: _enum(LiteWeapon.values, json['weapon'], LiteWeapon.spadaScudo),
      difficulty: _enum(
        LiteDifficulty.values,
        json['difficulty'],
        LiteDifficulty.medio,
      ),
      biome: _enum(LiteBiome.values, json['biome'], LiteBiome.campo),
      playerCount: _int(json['playerCount'], 1),
    );
    run.weapon = _enum(LiteWeapon.values, json['weapon'], run.weapon);
    run._rng.state = _int(json['rng'], run._rng.state);
    run._arrows = _int(json['arrows'], bowCapacity).clamp(0, bowCapacity);
    run._reloadRemaining = _num(json['reloadRemaining'])
        .clamp(0.0, reloadDuration);
    final savedCampaign = _int(json['campaignVersion']);
    final legacyCampaign = savedCampaign < 1;
    final savedStage = _int(json['stage'], legacyCampaign ? 1 : 0);
    if (savedStage == _legacyFinalStage &&
        (savedCampaign < 2 || json['legacyFinal'] == true)) {
      run._lastStage = _legacyFinalStage;
    }
    run._legacyVeyrthFinal =
        run.lastStage == _legacyFinalStage ||
        savedStage == finalStage && savedCampaign < 3 ||
        json['legacyVeyrthFinal'] == true;
    run._legacyOrdinary23 =
        savedStage == veyrthStage &&
        (savedCampaign == 2 || json['legacyOrdinary23'] == true);
    run.stage = savedStage.clamp(0, run.lastStage);
    run._startingBiome = _enum(
      LiteBiome.values,
      json['startingBiome'],
      run.biome,
    );
    run.floorLayout = _enum(
      LiteFloorLayout.values,
      json['floorLayout'],
      LiteFloorLayout.standard,
    );
    run._powerRanks.addAll(_readPowers(json['powers']));
    final savedOffers = _list(json['powerOffers']);
    run._powerOffers.addAll(
      savedOffers
          .map(
            (name) => LitePowerUp.values
                .where((item) => item.name == name)
                .firstOrNull,
          )
          .whereType<LitePowerUp>()
          .where((power) => run.powerRank(power) < LitePowerUp.maxRank)
          .toSet()
          .take(3),
    );
    run.level = max(1, _int(json['level'], 1));
    run.exp = _int(json['exp']);
    run.obser = _int(json['obser']);
    run.crystals = _int(json['crystals']);
    run.bossCrystalGrades.addAll(
      _list(json['bossCrystalGrades']).whereType<int>(),
    );
    run.ascensionDust = _int(json['ascensionDust']);
    run.spentOculum = _int(json['spentOculum']);
    run.livesRemaining = _int(json['livesRemaining']);
    run._plagueFormRemaining = _num(json['plagueForm']).clamp(0.0, 5.0);
    run.slimeKills = _int(json['slimeKills']).clamp(0, 10);
    run._goblinWave = _int(json['goblinWave']).clamp(0, 8);
    run.groundShots
      ..clear()
      ..addAll(
        _list(json['groundShots'])
            .take(28)
            .map(LiteGroundShot.read)
            .whereType<LiteGroundShot>(),
      );
    run._night.restore(json['night']);
    for (final name in _list(json['actRelics']).take(3)) {
      final relic = LiteActRelic.values
          .where((item) => item.name == name)
          .firstOrNull;
      if (relic != null) run.actRelics.add(relic);
    }
    run._actRelicClaims = _int(json['actRelicClaims']).clamp(0, 3);
    run.restHub = json['restHub'] == true;
    run.weaponArtCooldown = _num(json['weaponArtCooldown'])
        .clamp(0, LiteWeaponArt.weaponArtRecovery);
    run.realm = LiteRealm.values
        .where((area) => area.name == json['realm'])
        .firstOrNull;
    run.actRoom = run.realm == null
        ? 0
        : _int(json['actRoom'], 1).clamp(1, LiteSecondAct.actTwoRooms);
    run.solarPhase = LiteSolarPhase.values
        .where((phase) => phase.name == json['solarPhase'])
        .firstOrNull;
    if (json['solarStairs'] is List)
      run.solarStairs = _point(json['solarStairs']);
    run.supply.restore(json['supplies']);
    if (run.hero == LiteHero.doppelganger)
      run._mimic = LiteMimicForm.read(json['mimic']);
    run.hp = _num(json['hp'], run.maxHp);
    run._rescueSnapshot = _readRescueStatus(json['rescue']);
    run.oculum = _num(json['oculum'], run.maxOculum);
    run.shield = _num(json['shield']);
    run.position = _point(json['position']);
    run.aim = _point(json['aim']);
    void load<T>(
      List<T> output,
      Object? input,
      T Function(Map<String, dynamic>) decode,
    ) {
      output
        ..clear()
        ..addAll(
          _list(input)
              .whereType<Map>()
              .map((item) => decode(Map<String, dynamic>.from(item))),
        );
    }

    load(run.enemies, json['enemies'], LiteEnemy._read);
    load(run.projectiles, json['projectiles'], LiteProjectile._read);
    load(run.clones, json['clones'], LiteClone._read);
    load(
      run.coopFighters,
      _list(json['fighters']).take(maxCoopPlayers - 1).toList(),
      (data) => LiteCoopFighter._fromWire(
        data,
        run._power(LitePowerUp.ferroVivo).round(),
      ),
    );
    load(run.fauna, json['fauna'], LiteEnemy._read);
    run.fauna.removeWhere(
      (animal) => LiteAnimal.forCreature(animal.kind) == null,
    );
    run._provokedRooms.addAll(
      _list(json['provokedRooms'])
          .whereType<int>()
          .where((floor) => floor >= 0 && floor <= run.stage),
    );
    run._sparedRooms.addAll(
      _list(json['sparedRooms'])
          .whereType<int>()
          .where((floor) => floor >= 0 && floor <= run.stage),
    );
    load(run.obstacles, json['obstacles'], LiteObstacle._read);
    load(run.loot, json['loot'], LiteLoot._read);
    load(run.quests, json['quests'], LiteQuest._read);
    load(run._optionalMissions, json['optionalMissions'], LiteQuest._read);
    if (run.quests.length != 3) {
      throw const FormatException('Missioni del piano mancanti.');
    }
    run.ownedWeapons
      ..clear()
      ..addAll(
        _list(json['ownedWeapons'])
            .map((item) => _enum(LiteWeapon.values, item, run.weapon))
            .toSet(),
      );
    if (!run.ownedWeapons.contains(run.weapon)) {
      run.ownedWeapons.add(run.weapon);
    }
    if (run.hero == LiteHero.scostubandito &&
        !run.ownedWeapons.contains(LiteWeapon.fucileScostubandito)) {
      run.ownedWeapons.add(LiteWeapon.fucileScostubandito);
    }
    final quantities = _list(json['scrolls']);
    final equipped = _list(json['equippedScrolls']);
    for (var i = 0; i < run.scrolls.length; i++) {
      if (i < quantities.length) run.scrolls[i] = max(0, _int(quantities[i]));
    }
    for (var i = 0; i < min(equipped.length, run.equippedScrolls.length); i++) {
      run.equippedScrolls[i] = _enum(
        LiteScroll.values,
        equipped[i],
        LiteScroll.ordinary[i],
      );
    }
    run.learnedScrolls.addAll(
      _list(json['learnedScrolls'])
          .map((item) => _enum(LiteScroll.values, item, LiteScroll.dardo)),
    );
    run.achievements.addAll(_list(json['achievements']).whereType<String>());
    run.dodgeCharges = _int(json['dodgeCharges'], 1);
    run.maxDodgeCharges = _int(json['maxDodgeCharges'], 1);
    run.dodgeLevel = _int(json['dodgeLevel']);
    run.time = _num(json['time']);
    if (json['arenaEventStart'] is num) {
      run._arenaEventStart = _num(json['arenaEventStart']).clamp(0, run.time);
    } else {
      run._arenaEventStart = null;
    }
    run.arenaTrial = LiteArenaTrial.values
        .where((trial) => trial.name == json['arenaTrial'])
        .firstOrNull;
    run._trialStart = _num(json['trialStart'], run.time).clamp(0.0, run.time);
    run.stride._restore(json['stride']);
    run._restoreBurstTraces(json['burstTraces']);
    for (final value in _list(json['impacts']).take(16)) {
      if (LiteCombatImpact._fromFrame(value, run.time) case final impact?) {
        run._combatImpacts.add(impact);
      }
    }
    run.thirdRoom = _int(json['thirdRoom']).clamp(0, LiteThirdAct.rooms.length);
    if (run.stage != run.lastStage || run.realm != null) run.thirdRoom = 0;
    run._claimedWell = json['claimedWell'] is String
        ? json['claimedWell'] as String
        : null;
    run.stageClear = json['stageClear'] == true;
    run.eliteDefeated = json['eliteDefeated'] == true;
    run.dead = json['dead'] == true;
    run.victorious =
        json['victorious'] == true &&
        run.isFinalFloor &&
        !run.dead &&
        (!run.inThirdAct || run.thirdRoom == LiteThirdAct.rooms.length);
    run._finalBossDefeated =
        json['finalBossDefeated'] == true || run.victorious;
    run._mappedFloor = json['mappedFloor'] == run.inputArena
        ? run.inputArena
        : null;
    run._mappedSectors = _int(json['mappedSectors']).clamp(0, 31);
    if (run.hasFloorMap && json['mapPoint'] is List) {
      run.markMapPoint(_point(json['mapPoint']));
    }
    if (json['baghestArena'] == run.inputArena) {
      run._baghestEncounter = run.inputArena;
      if (json['grips'] case final Map grips) {
        for (final id in [
          0,
          ...run.coopFighters.map((fighter) => fighter.id),
        ]) {
          final count = _int(grips[id.toString()]).clamp(0, 5);
          if (count > 0) run._redGrips[id] = count;
        }
      }
    }
    run.shopOpen = json['shopOpen'] == true && run.canOpenShop;
    run.restUsed = json['restUsed'] == true;
    run._eliteReleased = json['eliteReleased'] == true;
    if (legacyCampaign && !run.dead) {
      if (run.isFinalFloor) {
        run.stageClear = false;
        run.shopOpen = false;
      }
      if (!run.stageClear &&
          (run.encounter == LiteEncounter.boss ||
              run.encounter == LiteEncounter.finalBoss)) {
        run._eliteReleased = false;
      }
    } else if (!run.finished && json['activeBeam'] is Map<String, dynamic>) {
      run._activeBeam = LiteBeam._read(
        json['activeBeam'] as Map<String, dynamic>,
        run.obstacles,
      );
    }
    run._nextId = _int(json['nextId']);
    run._attackCooldown = _num(json['attackCooldown']);
    run._windup = _num(json['windup']);
    run._invulnerability = _num(json['invulnerability']);
    run._hitProtectionRemaining = _num(json['hitProtectionRemaining'])
        .clamp(0.0, lifeHitProtection);
    run._clashRemaining = _num(json['clashRemaining'])
        .clamp(0.0, clashDashDuration);
    run._burstTime = _num(json['burstTime']);
    run._burstSpeed = _num(json['burstSpeed']);
    run._dashCooldown = _num(json['dashCooldown']);
    run._block.restore(json['blockWear']);
    run._block.held = json['blocking'] == true;
    run._openCooldown = _num(json['openCooldown']).clamp(0.0, openRecovery);
    run._bandit.restore(json['banditSkills']);
    run._dodgeRecharge = _num(json['dodgeRecharge']);
    run._springCooldown = _num(json['springCooldown']);
    run._staffCooldown = _num(json['staffCooldown'])
        .clamp(0, staffShockInterval);
    run._bombCooldown = _num(json['bombCooldown']).clamp(0.0, 5.5);
    run._springPose = _num(json['springPose']);
    run._scrollCooldown = _num(json['scrollCooldown']);
    run._burstDirection = _point(json['burstDirection']);
    run._strikeDirection = _point(json['strikeDirection']);
    run._lastMove = _point(json['lastMove']);
    run.message = json['message'] as String? ?? '';
    return run;
  }
}

// Park–Miller uses a product below 2^53, so JavaScript and native builds
// produce the same sequence without relying on platform Random internals.
class _LiteRandom {
  _LiteRandom(int seed) : state = seed % 2147483646 + 1;
  int state;
  double nextDouble() {
    state = (state * 48271) % 2147483647;
    return state / 2147483647;
  }

  int nextInt(int max) => (nextDouble() * max).floor();
}

double _square(num value) => (value * value).toDouble();
double _num(Object? value, [double fallback = 0]) =>
    value is num && value.isFinite ? value.toDouble() : fallback;
int _int(Object? value, [int fallback = 0]) =>
    value is num && value.isFinite ? value.toInt() : fallback;
List<dynamic> _list(Object? value) => value is List ? value : const [];
List<double> _savePoint(Point<double> p) => [p.x, p.y];
Point<double> _point(Object? value) => value is List && value.length == 2
    ? Point(_num(value[0]), _num(value[1]))
    : const Point(0, 0);
T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.where((item) => item.name == name).firstOrNull ?? fallback;
