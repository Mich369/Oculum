import 'dart:math';

/// Attacking an incoming attacker replaces the ordinary defense comparison.
/// Percentages are applied to each declared packet before its protections.
({int incomingPercent, int outgoingPercent}) oculumCounterAttackPercentages(
  int incomingAttack,
  int counterAttack,
) {
  final margin = counterAttack - incomingAttack;
  if (margin > 0) return (incomingPercent: 0, outgoingPercent: 100);
  if (margin == 0) return (incomingPercent: 50, outgoingPercent: 50);
  if (margin >= -3) return (incomingPercent: 75, outgoingPercent: 25);
  return (incomingPercent: 100, outgoingPercent: 0);
}

int oculumCounterAttackDamage(int damage, int percent) =>
    max(0, damage) * percent.clamp(0, 1000) ~/ 100;

int oculumFastReactionRollBonus({
  required int initiativeIndex,
  required int round,
}) => initiativeIndex == 0 && round == 0 ? 6 : 3;

bool oculumIsDoubleCritical({
  required int natural,
  required int total,
  required int opposingTotal,
  int naturalMaximum = 20,
}) =>
    naturalMaximum >= 2 &&
    natural == naturalMaximum &&
    total > 0 &&
    total >= max(1, opposingTotal) * 2;

/// New escape interceptions use d16; saves made before die metadata keep d20.
/// Ordinary attacks retain d20 even if a foreign packet supplies another die.
int oculumAttackRollFaces(Map request) =>
    '${request['escapeReactionOf'] ?? ''}'.isNotEmpty &&
        int.tryParse('${request['dieFaces'] ?? ''}') == 16
    ? 16
    : 20;

/// Credits one resolved roll, even after replay or restoring its saved sheet.
bool oculumGrantDoubleCriticalMagicalLuck(
  Map<String, dynamic> sheet, {
  required String receiptId,
  required int natural,
  required int total,
  required int opposingTotal,
  int naturalMaximum = 20,
}) {
  if (receiptId.trim().isEmpty ||
      !oculumIsDoubleCritical(
        natural: natural,
        total: total,
        opposingTotal: opposingTotal,
        naturalMaximum: naturalMaximum,
      )) {
    return false;
  }
  final claimed = (sheet['magicalLuckCriticalIds'] as List? ?? const [])
      .whereType<String>()
      .toSet();
  if (!claimed.add(receiptId)) return false;
  final before = int.tryParse('${sheet['fortuna'] ?? 0}') ?? 0;
  sheet['fortuna'] = max(0, before) + 1;
  sheet['magicalLuckCriticalIds'] = claimed.toList();
  return true;
}

int oculumDoubleCriticalDamageBonus(int level, int grade) =>
    max(2, max(0, level) * 3 + grade.clamp(0, 12) * 6);

/// Shared attack/defense rule: ties always favor defense.
enum OculumAttackOutcome {
  avoided('Evitato'),
  reduced('Ridotto'),
  full('Pieno');

  const OculumAttackOutcome(this.label);
  final String label;
}

OculumAttackOutcome oculumAttackOutcome(
  int attack,
  int defense, {
  String difficulty = 'normale',
}) {
  final margin = attack - defense;
  if (margin == 0) return OculumAttackOutcome.avoided;
  if (difficulty.trim().toLowerCase() == 'oculum') {
    if (margin == -1) return OculumAttackOutcome.reduced;
    return margin > 0 ? OculumAttackOutcome.full : OculumAttackOutcome.avoided;
  }
  if (margin <= 0) return OculumAttackOutcome.avoided;
  if (oculumAttackIsCritical(attack, defense)) return OculumAttackOutcome.full;
  final band = switch (difficulty.trim().toLowerCase()) {
    'facile' || 'easy' => 6,
    'difficile' || 'hard' => 3,
    _ => 5,
  };
  if (margin <= band) return OculumAttackOutcome.reduced;
  return OculumAttackOutcome.full;
}

/// Divides one declared damage packet among each selected hit. Rounding up is
/// intentional: every target receives at least its equal share, as confirmed
/// for multi-target attacks.
int oculumDamagePerTarget(
  int baseDamage,
  int targetCount, {
  int flatBonusPerTarget = 0,
}) {
  if (targetCount <= 0) return 0;
  // Keep a signed remainder until the per-target bonus has been recombined.
  // A skill expression such as `danni+8` is split from the prepared packet;
  // its base may be negative when existing penalties outweigh the bonus.
  final share = baseDamage >= 0
      ? (baseDamage + targetCount - 1) ~/ targetCount
      : -((-baseDamage) ~/ targetCount);
  return max(1, share + flatBonusPerTarget);
}

/// Skill damage is an addition to the attacker's ordinary base damage. The
/// fixed bonuses are split out so area attacks can add them to every target.
int oculumAttackDamageWithAbilityBonus({
  required int preparedDamage,
  required int fixedBonuses,
  required int abilityDamageBonus,
}) =>
    (preparedDamage - max(0, fixedBonuses)).toInt() +
    max(0, abilityDamageBonus).toInt();

/// Reads an additive attack-roll fraction from editable equipment, skill,
/// Art, title, or quick-command text. Examples:
/// `@Danni+1/2dadoriflessi` and `1/3dadoforza ai danni`.
/// The formula contributes only when the named subtrait made this attack.
int oculumAttackRollDamageBonus({
  required Iterable<String> sourceTexts,
  required String attackChoiceId,
  required int rollTotal,
}) {
  if (rollTotal <= 0) return 0;
  final chosen = _oculumCanonicalAttackSubtrait(attackChoiceId);
  if (chosen.isEmpty) return 0;
  final pattern = RegExp(
    r'(?:(\d+)\s*/\s*(\d+)\s*)?dado\s*([A-Za-zÀ-ÿ_]+)',
    caseSensitive: false,
  );
  var total = 0;
  for (final text in sourceTexts) {
    for (final match in pattern.allMatches(text)) {
      final subtrait = _oculumCanonicalAttackSubtrait(match.group(3) ?? '');
      if (subtrait != chosen) continue;
      final marker = text.toLowerCase().lastIndexOf('@danni', match.start);
      final lastCommand = text.lastIndexOf('@', match.start);
      final commandBound = marker >= 0 && marker >= lastCommand;
      final nextCommand = text.indexOf('@', match.end);
      final end = nextCommand < 0 ? text.length : nextCommand;
      final suffix = text.substring(match.end, end).toLowerCase();
      final freeTextDamage = RegExp(r'\bdann[io]\b').hasMatch(suffix);
      if (!commandBound && !freeTextDamage) continue;
      final numerator = max(0, int.tryParse(match.group(1) ?? '1') ?? 1);
      final denominator = max(1, int.tryParse(match.group(2) ?? '1') ?? 1);
      total += rollTotal * numerator ~/ denominator;
    }
  }
  return total;
}

String _oculumCanonicalAttackSubtrait(String raw) {
  final normalized = raw
      .toLowerCase()
      .replaceAll('à', 'a')
      .replaceAll('è', 'e')
      .replaceAll('é', 'e')
      .replaceAll('ì', 'i')
      .replaceAll('ò', 'o')
      .replaceAll('ù', 'u')
      .replaceAll(RegExp(r'[^a-z0-9]'), '')
      .replaceFirst(RegExp(r'^dado'), '');
  return switch (normalized) {
    'vc' || 'volonta' => 'vc',
    'forza' => 'forza',
    'riflessi' || 'riflesso' => 'riflessi',
    'schianto' => 'schianto',
    'precisione' => 'precisione',
    'manifestazione' || 'manifestazionedelpotere' => 'manifestazione_potere',
    'furbizia' => 'furbizia',
    'velo' => 'velo',
    'strategia' => 'strategia',
    'percezione' => 'percezione',
    'investigazione' => 'investigazione',
    'valutazione' => 'valutazione',
    _ => normalized,
  };
}

String oculumMonsterCollectedElement(Map<String, dynamic> state) =>
    _oculumCanonicalCombatElement('${state['lastElement'] ?? ''}');

List<String> oculumMonsterCollectedElements(Map<String, dynamic> state) {
  final raw = state['collectedElements'];
  if (raw is! Iterable) return const [];
  return <String>{
    for (final item in raw)
      if (_oculumCanonicalCombatElement('$item').isNotEmpty)
        _oculumCanonicalCombatElement('$item'),
  }.toList(growable: false);
}

bool oculumIsElementCollector(String monsterBookSourceId) =>
    monsterBookSourceId.trim().startsWith('collezionista_di_elementi');

int oculumElementCollectorDefensePenalty({
  required String sourceMonsterBookId,
  required String incomingElement,
  required String defenseElement,
}) =>
    oculumIsElementCollector(sourceMonsterBookId) &&
        _oculumCanonicalCombatElement(incomingElement) ==
            _oculumCanonicalCombatElement(defenseElement)
    ? 2
    : 0;

/// Keeps an additive tail such as `danni+8` outside the divided area packet.
/// The tail is evaluated once on activation and added to every hit.
({String base, String perTargetBonus}) oculumSplitAreaDamageExpression(
  String expression,
) {
  var depth = 0;
  for (var index = 0; index < expression.length; index++) {
    final char = expression[index];
    if (char == '(') depth++;
    if (char == ')') depth = max(0, depth - 1);
    if (depth != 0 || (char != '+' && char != '-')) continue;
    if (index == 0 || index == expression.length - 1) continue;
    final left = expression.substring(0, index).trim();
    final right = expression.substring(index + 1).trim();
    if (left.isEmpty ||
        right.isEmpty ||
        !RegExp(r'danni', caseSensitive: false).hasMatch(left)) {
      continue;
    }
    return (base: left, perTargetBonus: char == '-' ? '-($right)' : right);
  }
  return (base: expression, perTargetBonus: '');
}

/// Zero/negative totals do not grant an unearned critical reaction.
bool oculumDefenseGrantsFreeReaction(int attack, int defense) =>
    defense > 0 && defense > attack && defense >= (attack > 0 ? attack * 2 : 2);

bool oculumAttackIsCritical(int attack, int defense) =>
    attack > 0 && attack > defense && attack >= (defense > 0 ? defense * 2 : 2);

bool oculumManifestationConsumesOculum(int rollOutOf100) {
  if (rollOutOf100 < 0 || rollOutOf100 >= 100) {
    throw RangeError.range(rollOutOf100, 0, 99);
  }
  return rollOutOf100 < 13;
}

int oculumOpposedDamage(
  int damage,
  int attack,
  int defense, {
  bool forcedCritical = false,
  int criticalBonus = 0,
  String difficulty = 'normale',
}) {
  if (damage <= 0) return 0;
  final outcome = oculumAttackOutcome(attack, defense, difficulty: difficulty);
  if (outcome == OculumAttackOutcome.avoided) return 0;
  final critical = forcedCritical || oculumAttackIsCritical(attack, defense);
  final amount =
      damage + (critical && criticalBonus > 0 ? criticalBonus * 2 : 0);
  return amount;
}

/// Returns the damage retained when a defender chooses an elemental affinity.
/// A counter-affinity protects from that incoming element by 25%. Custom and
/// non-elemental types stay neutral unless an explicit matchup is added here.
/// Angelic and demonic damage mutually weaken each other while the defender
/// has at least 30% of maximum HP; at lower HP that ward collapses.
double oculumElementalDefenseMultiplier({
  required String incomingElement,
  required String defenseElement,
  required int currentHp,
  required int maximumHp,
}) {
  final incoming = _oculumCanonicalCombatElement(incomingElement);
  final defense = _oculumCanonicalCombatElement(defenseElement);
  if (incoming.isEmpty || defense.isEmpty || maximumHp <= 0) return 1;

  if (defense == 'diabolico' && incoming == 'demoniaco') return 0.25;

  bool isAngelic(String value) => value == 'angelico';
  bool isDemonic(String value) => value == 'demoniaco';
  final pair =
      (isAngelic(incoming) && isDemonic(defense)) ||
      (isDemonic(incoming) && isAngelic(defense));
  if (pair) {
    final hp = currentHp.clamp(0, maximumHp);
    return hp * 100 >= maximumHp * 30 ? 0.75 : 1;
  }

  // The left side is the defending affinity; it counters the incoming type.
  const counters = <String, Set<String>>{
    'acqua': {'fuoco', 'lava'},
    'fuoco': {'gelo', 'ghiaccio'},
    'gelo': {'vento', 'aria'},
    'ghiaccio': {'vento', 'aria'},
    'vento': {'terra', 'radice'},
    'terra': {'fulmine', 'elettrico'},
    'fulmine': {'acqua'},
    'oscuro': {'luce'},
    'sacro': {'oscuro'},
    'solare': {'lunare'},
  };
  return counters[defense]?.contains(incoming) == true ? 0.75 : 1;
}

String _oculumCanonicalCombatElement(String raw) {
  final value = raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  return const {
        'dark': 'oscuro',
        'darkness': 'oscuro',
        'buio': 'oscuro',
        'light': 'luce',
        'lunar': 'lunare',
        'moon': 'lunare',
        'solar': 'solare',
        'sun': 'solare',
        'angelic': 'angelico',
        'demonic': 'demoniaco',
        'diabolic': 'diabolico',
        'ghiaccio': 'gelo',
        'aria': 'vento',
        'elettrico': 'fulmine',
      }[value] ??
      value;
}

class OculumMonsterElementalAdaptation {
  const OculumMonsterElementalAdaptation({
    required this.resistanceBeforeHit,
    required this.resistanceAfterHit,
    required this.element,
    required this.lockedElement,
    required this.state,
    required this.changed,
  });

  final int resistanceBeforeHit;
  final int resistanceAfterHit;
  final String element;
  final String lockedElement;
  final Map<String, dynamic> state;
  final bool changed;
}

/// Mini-Bosses adapt only to their first incoming element (+3 resistance per
/// hit, capped at 60%). Bosses track each element independently (+6, capped at
/// 75%). The before-hit value applies to this hit; the returned state is for
/// subsequent hits.
OculumMonsterElementalAdaptation oculumPrepareMonsterElementalAdaptation({
  required bool isMiniBoss,
  required bool isBoss,
  required String incomingElement,
  Map<String, dynamic> previousState = const {},
}) {
  final element = _oculumCanonicalCombatElement(incomingElement);
  final rawResistances = previousState['resistanceByElement'];
  final resistances = <String, int>{
    if (rawResistances is Map)
      for (final entry in rawResistances.entries)
        _oculumCanonicalCombatElement('${entry.key}'): max(
          0,
          int.tryParse('${entry.value}') ?? 0,
        ),
  };
  if (!isMiniBoss && !isBoss) {
    return OculumMonsterElementalAdaptation(
      resistanceBeforeHit: 0,
      resistanceAfterHit: 0,
      element: element,
      lockedElement: '',
      state: previousState,
      changed: false,
    );
  }

  final locked = isBoss
      ? ''
      : _oculumCanonicalCombatElement('${previousState['firstElement'] ?? ''}');
  final chosen = isBoss || locked.isEmpty ? element : locked;
  if (!isBoss && locked.isNotEmpty && element != locked) {
    final current = resistances[locked] ?? 0;
    return OculumMonsterElementalAdaptation(
      resistanceBeforeHit: 0,
      resistanceAfterHit: current,
      element: element,
      lockedElement: locked,
      state: previousState,
      changed: false,
    );
  }

  final current = (resistances[chosen] ?? 0).clamp(0, isBoss ? 75 : 60);
  final next = min(isBoss ? 75 : 60, current + (isBoss ? 6 : 3));
  resistances[chosen] = next;
  final state = <String, dynamic>{
    ...previousState,
    'version': 1,
    'kind': isBoss ? 'boss' : 'miniBoss',
    if (!isBoss) 'firstElement': chosen,
    'resistanceByElement': resistances,
    'lastElement': element,
    if (isBoss && element.isNotEmpty)
      'collectedElements': <String>{
        ...oculumMonsterCollectedElements(previousState),
        element,
      }.toList(growable: false),
  };
  return OculumMonsterElementalAdaptation(
    resistanceBeforeHit: current,
    resistanceAfterHit: next,
    element: element,
    lockedElement: isBoss ? '' : chosen,
    state: state,
    changed: next != current || (!isBoss && locked.isEmpty),
  );
}

int oculumReduceIncomingDamage(int damage, double multiplier) =>
    (max(0, damage) * multiplier.clamp(0, 1)).ceil();

int oculumOpposedEffectDuration(int duration, OculumAttackOutcome outcome) =>
    outcome == OculumAttackOutcome.avoided
    ? 0
    : outcome == OculumAttackOutcome.reduced
    ? (duration > 0 ? duration ~/ 2 : 0)
    : duration;

/// Forecasts enumerate supplied totals, without assuming access to enemy stats.
class OculumAttackForecast {
  const OculumAttackForecast(this.avoided, this.reduced, this.full);
  final double avoided, reduced, full;

  factory OculumAttackForecast.fromRolls(
    List<int> attack,
    List<int> defense, {
    String difficulty = 'normale',
  }) {
    if (attack.isEmpty || defense.isEmpty) {
      throw ArgumentError('Roll lists must not be empty');
    }
    final counts = [0, 0, 0];
    for (final a in attack) {
      for (final d in defense) {
        counts[oculumAttackOutcome(a, d, difficulty: difficulty).index]++;
      }
    }
    final pairs = attack.length * defense.length;
    return OculumAttackForecast(
      counts[0] * 100 / pairs,
      counts[1] * 100 / pairs,
      counts[2] * 100 / pairs,
    );
  }
}
