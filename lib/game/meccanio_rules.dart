import 'dart:math';

bool isMeccanioBookId(String id) => const {
  'meccanio',
  'meccanio_ammaccato',
  'meccanio_primordiale',
  'meccanio_elite',
}.contains(id);

int meccanioTamingDifficulty(int level, int grade) =>
    13 + max<int>(0, level) + 3 * max<int>(0, grade);
int meccanioDisobedienceAfterRest(int chance, {required bool longRest}) =>
    max(0, chance - (longRest ? 50 : 20));

int meccanioDisobedienceAfterEmpathy(int chance, int total) =>
    max(0, chance.clamp(0, 100) - max(0, total));

int meccanioDisobedienceAfterDeception(int chance, int natural, int total) =>
    natural < 12
    ? min(100, max(0, chance) + 10)
    : meccanioDisobedienceAfterEmpathy(chance, total);

int meccanioFailedProtectionReward(int hpLost, int hpMaximum) =>
    (2 + (38 * max(0, hpLost) / max(1, hpMaximum)).round()).clamp(2, 40);

Map<String, int> meccanioVariantProfile(String id) => {
  'skillPowerPercent': id == 'meccanio_ammaccato'
      ? 75
      : id == 'meccanio_elite'
      ? 125
      : 100,
  'initialShieldPercent': id == 'meccanio_ammaccato'
      ? 90
      : id == 'meccanio_primordiale'
      ? 120
      : 180,
  'repairShieldPercentI': id == 'meccanio_ammaccato'
      ? 80
      : id == 'meccanio_primordiale'
      ? 120
      : 160,
  'repairShieldPercentII': id == 'meccanio_ammaccato'
      ? 95
      : id == 'meccanio_primordiale'
      ? 120
      : 190,
  'defenseBonus': id == 'meccanio_primordiale' ? 3 : 0,
  'oculumShieldPercent': id == 'meccanio_primordiale' ? 10 : 0,
};

const meccanioOffensiveTechniques = {
  'rays',
  'lightning',
  'shoulder',
  'sphere',
  'claw',
  'harpoon',
};
const meccanioTechniqueNames = {
  'rays': 'Raggi mortali',
  'drones': 'Droni riparatori',
  'lightning': 'Folgorazione',
  'shoulder': 'Mitra sulla spalla',
  'sphere': 'Sfera elettro',
  'claw': 'Artiglio a scarica',
  'harpoon': 'Arpione magnetico',
};

/// Draw once per purchase; the resulting IDs belong in the creature JSON.
Map<String, dynamic> meccanioRollLoadout(Random random) {
  final pool = ['drones', 'lightning', 'shoulder', 'sphere', 'claw', 'harpoon'];
  if (random.nextInt(100) < 8) pool.add('rays');
  pool.shuffle(random);
  final selected = pool.take(3).toList();
  if (!selected.any(meccanioOffensiveTechniques.contains)) {
    selected[selected.length - 1] = 'claw';
  }
  const colours = [
    'giallo ocra e verde acqua',
    'rosso rame e avorio',
    'blu petrolio e argento',
    'viola scuro e ottone',
    'verde muschio e rame',
    'avorio e azzurro',
  ];
  return {
    'version': 1,
    'skills': selected,
    'open': random.nextBool() ? 'missile' : 'automatic',
    'colour': colours[random.nextInt(colours.length)],
    'emergency': true,
    'regenerationBonuses': <String, int>{},
  };
}

int meccanioElementPercent(int level) =>
    25 * (1 + max(0, level) ~/ 10).clamp(1, 4);

int meccanioRepairShieldLimit(int hpMaximum, int form) =>
    (max(0, hpMaximum) * (form <= 1 ? 1.6 : 1.9)).ceil();

({int hp, int shield, int healed, int shieldAdded}) meccanioRepair({
  required int hp,
  required int hpMaximum,
  required int shield,
  required int amount,
  int form = 1,
  int? shieldLimitPercent,
}) {
  final healed = min(max(0, hpMaximum - hp), max(0, amount));
  // Only a repair begun at full health generates Shield. Do not turn overflow
  // from an ordinary heal into a second reward or reduce an existing shield.
  final added = hp >= hpMaximum
      ? min(
          max(
            0,
            (shieldLimitPercent == null
                    ? meccanioRepairShieldLimit(hpMaximum, form)
                    : (hpMaximum * shieldLimitPercent / 100).ceil()) -
                shield,
          ),
          max(0, amount),
        )
      : 0;
  return (
    hp: hp + healed,
    shield: shield + added,
    healed: healed,
    shieldAdded: added,
  );
}

Map<String, int> meccanioRegenerationBonuses({
  required Map<String, int> base,
  required Map<String, int> previous,
  required Map<String, int> owner,
}) => {
  for (final stat in ['resilienza', 'volonta', 'materia'])
    stat: min(
      max(0, (owner[stat] ?? 0) - (base[stat] ?? 0)),
      max(0, previous[stat] ?? 0) + (stat == 'resilienza' ? 1 : 2),
    ),
};

/// One exclusive ticket; callers supply only targets actually hit.
int meccanioElectrocutionCount(int percentile, int hitCount) => min(
  max(0, hitCount),
  percentile < 15
      ? hitCount
      : percentile < 40
      ? 2
      : percentile < 70
      ? 1
      : 0,
);

int meccanioEmergencyBonus(int form) => 2 + 2 * form.clamp(1, 3);
int meccanioEmergencyDamage(
  int damage, {
  required bool avoided,
  required bool nearMiss,
}) => avoided ? 0 : (max(0, damage) * (nearMiss ? .75 : .8)).floor();

int meccanioShoulderDamage({
  required int bullets,
  required int targets,
  int form = 1,
}) => targets <= 0 ? 0 : max(0, bullets) * (form.clamp(1, 3) + 1) ~/ targets;

/// Keep max HP independent of changing damage/defence stats to prevent a
/// recursive health calculation. The integrity curve is a tunable baseline.
int meccanioIntegrityStat(int base, int hp, int hpMaximum, {int bonus = 0}) {
  final ratio = hpMaximum <= 0 ? 0.0 : (hp / hpMaximum).clamp(0.0, 1.0);
  return max(0, ((max(0, base) + bonus) * (.5 + ratio * .5)).floor());
}
