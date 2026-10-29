import 'dart:math';
import 'oculum_hp_rules.dart';

const oculumScoutReadingStatIds = <String>{
  'percezione',
  'investigazione',
  'furbizia',
  'valutazione',
  'lettura_aura',
};
int oculumScoutNoSpendChance(int subtrait) => subtrait.clamp(0, 95);

const oculumPowerReadPhrases = <String, String>{
  'much_stronger': 'ho una potenza nettamente superiore',
  'stronger': 'ho una potenza leggermente superiore',
  'equal': 'siamo alla pari o quasi',
  'weaker': 'è leggermente più forte di me',
  'much_weaker': 'è nettamente più forte di me',
  'impossible': 'impossibile da battere',
};

int oculumScoutPower(int level, Iterable<int> statistics, {int grade = 0}) =>
    max(0, level) +
    max(0, grade) * 3 +
    oculumHpTotalPowerBonusForGrade(grade, level: level) +
    statistics.fold(0, (sum, stat) => sum + max(0, stat));

({int divisor, int threshold, int chancePerPoint, int weakPointNatural})
oculumScoutPowerTier(int? power) => switch (power) {
  final int p when p <= 10 => (
    divisor: 8,
    threshold: 1,
    chancePerPoint: 25,
    weakPointNatural: 3,
  ),
  final int p when p <= 20 => (
    divisor: 5,
    threshold: 3,
    chancePerPoint: 20,
    weakPointNatural: 5,
  ),
  final int p when p <= 30 => (
    divisor: 3,
    threshold: 5,
    chancePerPoint: 15,
    weakPointNatural: 7,
  ),
  final int p when p <= 50 => (
    divisor: 2,
    threshold: 10,
    chancePerPoint: 10,
    weakPointNatural: 10,
  ),
  final int p when p < 100 => (
    divisor: 1,
    threshold: 20,
    chancePerPoint: 5,
    weakPointNatural: 20,
  ),
  _ => (divisor: 1, threshold: 40, chancePerPoint: 5, weakPointNatural: 20),
};

bool oculumScoutWeakPointRollQualifies(int natural, int power) =>
    natural >= oculumScoutPowerTier(power).weakPointNatural;

bool oculumScoutRevealsWeakPoint({
  required int natural,
  required int rollTotal,
  required int targetPower,
  required OculumCombatScoutRead read,
}) =>
    read.isExact &&
    (natural == 20 || targetPower <= 50 && rollTotal >= read.requirement + 5);

int oculumExactPowerChance(
  int rollTotal, {
  required bool success,
  int? targetPower,
  int? observationRequirement,
}) =>
    success &&
        targetPower != null &&
        targetPower <= 50 &&
        observationRequirement != null &&
        rollTotal >= observationRequirement + 5
    ? 100
    : success
    ? ((rollTotal - oculumScoutPowerTier(targetPower).threshold) *
              oculumScoutPowerTier(targetPower).chancePerPoint)
          .clamp(0, 100)
    : 0;

int oculumPowerScannerLimit(int level) => 50 + max(0, level) * 30;

int oculumPowerScannerPrice(int level, {bool postea = false}) =>
    ((30 + 15 * max(0, level)) * (postea ? 6 : 1)).toInt();

int oculumPowerScannerUses(Random random, {bool postea = false}) =>
    random.nextInt(postea ? 23 : 9) + (postea ? 13 : 7);

/// Only the estimate is returned. Out-of-range results contain no power value.
Map<String, dynamic> oculumPowerScannerRead(
  int power,
  int level,
  Random random,
) {
  if (power > oculumPowerScannerLimit(level)) {
    return {'scannerOutOfRange': true};
  }
  final minimum = (max(0, power) * .9).ceil();
  final maximum = (max(0, power) * 1.1).floor();
  return {'scannerEstimate': minimum + random.nextInt(maximum - minimum + 1)};
}

/// Ordinary readings share this category; the separate confirmed high-roll
/// check may reveal total power, without sharing its component statistics.
String oculumScoutPowerBand(
  int observer,
  int target, {
  double equalMargin = .10,
  double slightMargin = .35,
  double impossibleRatio = 2,
}) {
  if (observer <= 0) return target <= 0 ? 'equal' : 'impossible';
  final own = max(1, observer);
  final other = max(0, target);
  final ratio = other / own;
  if (ratio >= impossibleRatio) return 'impossible';
  if ((ratio - 1).abs() <= equalMargin + .0000001) return 'equal';
  if (ratio < 1) {
    return ratio >= 1 - slightMargin ? 'stronger' : 'much_stronger';
  }
  return ratio <= 1 + slightMargin ? 'weaker' : 'much_weaker';
}

String oculumScoutDominantStat(Map<String, int> statistics) {
  const keys = ['resilienza', 'volonta', 'materia', 'oculum'];
  var result = keys.first;
  for (final key in keys.skip(1)) {
    if ((statistics[key] ?? 0) > (statistics[result] ?? 0)) result = key;
  }
  return result;
}

bool oculumScoutUnlocksTheme(bool success, int percentile) =>
    success && percentile >= 0 && percentile < 90;

String oculumScoutFailurePhrase(String stat) => switch (stat) {
  'volonta' => 'la sua volontà non mi permette di percepire',
  'materia' => 'la sua materia non mi permette di percepire',
  'oculum' => 'il suo oculum non mi permette di percepire',
  _ => 'la sua resilienza non mi permette di percepire',
};

/// What a Percezione/Investigazione roll is allowed to reveal about a target.
///
/// The target resolves this locally before it publishes any values, so private
/// level, Velo and CM never have to be sent to another client before the roll.
enum OculumCombatScoutReveal { exact, approximate, insufficient }

class OculumCombatScoutRead {
  const OculumCombatScoutRead({
    required this.reveal,
    required this.requirement,
    required this.targetLevel,
    required this.targetGrade,
    required this.targetCm,
    required this.failure,
  });

  final OculumCombatScoutReveal reveal;
  final int requirement;
  final int? targetLevel;
  final int? targetGrade;
  final int? targetCm;
  final int failure;

  bool get showsProbabilities =>
      reveal == OculumCombatScoutReveal.exact ||
      reveal == OculumCombatScoutReveal.approximate;
  bool get isExact => reveal == OculumCombatScoutReveal.exact;
}

bool oculumSeesVeilAutomatically({
  required String conditionType,
  required int targetGrade,
  required int observerGrade,
}) {
  final grade = max(0, targetGrade);
  if (conditionType == 'trasparenza') return observerGrade > grade;
  if (conditionType == 'invisibile') {
    return observerGrade >= (grade ~/ 3 + 1) * 3;
  }
  return false;
}

int oculumTransparencyDefenseBonus({
  required int observerLevel,
  required bool transparent,
  required bool identified,
}) => transparent && identified ? max(0, observerLevel) : 0;

/// Returns the strongest active Invisibility/Transparency Velo bonus.
///
/// An exact Percezione reading halves each condition's bonus for the observing
/// side, rounding down. An approximate reading does not change the bonus, and
/// other sides retain the original bonus.
/// The condition's saved editor values and level scaling remain authoritative.
int oculumCombatScoutVeilBonus({
  required Iterable<Map> conditions,
  required int level,
  bool exactPerceptionReading = false,
  int? observerGrade,
  int targetGrade = 0,
}) {
  var bonus = 0;
  for (final condition in conditions) {
    final type = '${condition['conditionType'] ?? condition['type'] ?? ''}';
    if (type != 'invisibile' && type != 'trasparenza') continue;
    if (observerGrade != null &&
        oculumSeesVeilAutomatically(
          conditionType: type,
          targetGrade: targetGrade,
          observerGrade: observerGrade,
        )) {
      continue;
    }
    final rawMetadata = condition['metadata'];
    final metadata = rawMetadata is Map
        ? rawMetadata
        : const <String, dynamic>{};
    final base = type == 'invisibile' ? 18 : 6;
    final rawBase = metadata['veilBaseBonus'];
    final parsedBase = rawBase is num
        ? rawBase.toInt()
        : int.tryParse('${rawBase ?? ''}') ?? base;
    final rawAddLevel = metadata['veilAddLevel'];
    final addLevel = rawAddLevel == null
        ? true
        : rawAddLevel == true || rawAddLevel == 1 || rawAddLevel == 'true';
    final value = parsedBase + (addLevel ? (level < 0 ? 0 : level) : 0);
    final normalized = value < 0 ? 0 : value;
    final effective = exactPerceptionReading ? normalized ~/ 2 : normalized;
    if (effective > bonus) bonus = effective;
  }
  return bonus;
}

/// Whether this incoming damage element has an explicit saved resistance.
/// Explicit per-element customizations override Monster Book anatomy defaults;
/// temporary effects are intentionally resolved separately by the caller.
bool oculumIncomingResistanceIsExplicit({
  required String elementId,
  required Map savedPresets,
  required Map savedPercentages,
  String legacyPercentage = '',
}) {
  final id = elementId.trim().toLowerCase();
  bool containsElement(Map map) =>
      map.keys.any((key) => '$key'.trim().toLowerCase() == id);
  if (containsElement(savedPresets) || containsElement(savedPercentages)) {
    return true;
  }
  final hasTypedConfiguration =
      savedPresets.isNotEmpty || savedPercentages.isNotEmpty;
  return !hasTypedConfiguration && legacyPercentage.trim().isNotEmpty;
}

/// Resolves the confirmed Percezione threshold.
///
/// Exact information requires `level + Velo`. A miss of at most five returns
/// a deliberately lower level and defensive estimate while retaining the
/// target grade. A larger miss exposes no combat probability information.
OculumCombatScoutRead oculumCombatScoutRead({
  required int rollTotal,
  required int targetLevel,
  required int targetVelo,
  required int targetGrade,
  required int targetCm,
  int? targetPower,
}) {
  final level = max(0, targetLevel);
  final velo = max(0, targetVelo);
  final grade = max(0, targetGrade);
  final cm = max(0, targetCm);
  final requirement =
      (level + velo) ~/ oculumScoutPowerTier(targetPower).divisor;
  final failure = max(0, requirement - rollTotal);
  if (failure == 0) {
    return OculumCombatScoutRead(
      reveal: OculumCombatScoutReveal.exact,
      requirement: requirement,
      targetLevel: level,
      targetGrade: grade,
      targetCm: cm,
      failure: 0,
    );
  }
  if (failure <= 5) {
    return OculumCombatScoutRead(
      reveal: OculumCombatScoutReveal.approximate,
      requirement: requirement,
      targetLevel: max(0, level - max(1, failure)),
      targetGrade: grade,
      targetCm: max(0, cm - max(1, failure)),
      failure: failure,
    );
  }
  return OculumCombatScoutRead(
    reveal: OculumCombatScoutReveal.insufficient,
    requirement: requirement,
    targetLevel: null,
    targetGrade: null,
    targetCm: null,
    failure: failure,
  );
}
