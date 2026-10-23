import 'dart:math';

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
}) {
  final level = max(0, targetLevel);
  final velo = max(0, targetVelo);
  final grade = max(0, targetGrade);
  final cm = max(0, targetCm);
  final requirement = level + velo;
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
