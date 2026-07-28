part of '../../main.dart';

// MODELLI BASE
// =====================================================

class ColorOption {
  const ColorOption({
    required this.name,
    required this.category,
    required this.color,
  });

  final String name;
  final String category;
  final Color color;
}

class OculumColorPreset {
  const OculumColorPreset({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descriptionIt,
    required this.descriptionEn,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.utility,
    required this.oculumFormula,
    required this.backgroundTop,
    required this.backgroundMid,
    required this.backgroundBottom,
    required this.eyePupilGlow,
    this.iconAssetPath,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String descriptionIt;
  final String descriptionEn;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color utility;
  final Color oculumFormula;
  final Color backgroundTop;
  final Color backgroundMid;
  final Color backgroundBottom;
  final Color eyePupilGlow;
  final String? iconAssetPath;
}

List<String> readStringListValue(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? <String>[] : <String>[trimmed];
  }
  if (value is! List) return <String>[];
  return [
    for (final entry in value)
      if ('$entry'.trim().isNotEmpty) '$entry'.trim(),
  ];
}

List<Map<String, dynamic>> readMapListValue(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];
  final result = <Map<String, dynamic>>[];
  for (final entry in value) {
    if (entry is Map) {
      result.add(Map<String, dynamic>.from(entry));
    }
  }
  return result;
}

class DamageModifierOption {
  const DamageModifierOption({
    required this.name,
    required this.multiplier,
    required this.descriptionIt,
    required this.descriptionEn,
  });

  final String name;

  /// 1.00 = danno normale
  /// 0.90 = -10%
  /// 0.00 = immunità
  /// -0.10 = rigenera 10%
  /// 1.50 = +50%
  final double multiplier;

  final String descriptionIt;
  final String descriptionEn;
}

class ManualSection {
  const ManualSection({
    required this.titleIt,
    required this.titleEn,
    required this.contentIt,
    required this.contentEn,
  });

  final String titleIt;
  final String titleEn;
  final String contentIt;
  final String contentEn;
}

class HiddenEyeStat {
  HiddenEyeStat({
    required this.id,
    required this.nome,
    required this.descrizione,
    this.valore = 0,
    this.unlocked = true,
    this.masteryProgress = 0,
  });

  final String id;
  String nome;
  String descrizione;
  int valore;
  bool unlocked;
  int masteryProgress;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'descrizione': descrizione,
    'valore': valore,
    'unlocked': unlocked,
    'oculusSubtraitMasteryProgress': masteryProgress,
  };

  factory HiddenEyeStat.fromJson(Map<String, dynamic> json) {
    return HiddenEyeStat(
      id: '${json['id'] ?? ''}',
      nome: '${json['nome'] ?? ''}',
      descrizione: '${json['descrizione'] ?? ''}',
      valore: readIntValue(json['valore']),
      unlocked: json.containsKey('unlocked')
          ? readBoolValue(json['unlocked'])
          : true,
      masteryProgress: readIntValue(
        json['oculusSubtraitMasteryProgress'] ?? json['maestria'],
      ),
    );
  }
}

const String oculumAdaptationResistanceEffectId =
    'oculum.temp_resistance.adattamento.all_damage.current_combat.v1';

class OculumTemporaryResistanceEffect {
  OculumTemporaryResistanceEffect({
    required this.id,
    required this.ownerSheetId,
    required this.origin,
    required this.type,
    required this.duration,
    required this.coverage,
  });

  final String id;
  final String ownerSheetId;
  final String origin;
  final String type;
  final String duration;
  final String coverage;

  bool get isAdaptationAllDamageCurrentCombat =>
      id == oculumAdaptationResistanceEffectId &&
      origin == 'Adattamento' &&
      type == 'temporaneo' &&
      duration == 'combattimento_corrente' &&
      coverage == 'tutti_i_tipi_di_danno';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'ownerSheetId': ownerSheetId,
    'origin': origin,
    'type': type,
    'duration': duration,
    'coverage': coverage,
  };

  factory OculumTemporaryResistanceEffect.fromJson(Map<String, dynamic> json) {
    return OculumTemporaryResistanceEffect(
      id: '${json['id'] ?? ''}',
      ownerSheetId: '${json['ownerSheetId'] ?? ''}',
      origin: '${json['origin'] ?? ''}',
      type: '${json['type'] ?? ''}',
      duration: '${json['duration'] ?? ''}',
      coverage: '${json['coverage'] ?? ''}',
    );
  }
}

class OculumAdaptationCriticalOutcome {
  const OculumAdaptationCriticalOutcome({
    required this.isNaturalCritical,
    required this.applied,
    required this.alreadyActive,
  });

  final bool isNaturalCritical;
  final bool applied;
  final bool alreadyActive;
}

OculumAdaptationCriticalOutcome oculumApplyAdaptationCritical({
  required int naturalRoll,
  required bool combatActive,
  required String ownerSheetId,
  required List<OculumTemporaryResistanceEffect> effects,
}) {
  if (naturalRoll != 20) {
    return const OculumAdaptationCriticalOutcome(
      isNaturalCritical: false,
      applied: false,
      alreadyActive: false,
    );
  }
  if (!combatActive || ownerSheetId.trim().isEmpty) {
    return const OculumAdaptationCriticalOutcome(
      isNaturalCritical: true,
      applied: false,
      alreadyActive: false,
    );
  }

  final alreadyActive = effects.any(
    (effect) =>
        effect.ownerSheetId == ownerSheetId &&
        effect.isAdaptationAllDamageCurrentCombat,
  );
  if (alreadyActive) {
    return const OculumAdaptationCriticalOutcome(
      isNaturalCritical: true,
      applied: false,
      alreadyActive: true,
    );
  }

  effects.add(
    OculumTemporaryResistanceEffect(
      id: oculumAdaptationResistanceEffectId,
      ownerSheetId: ownerSheetId,
      origin: 'Adattamento',
      type: 'temporaneo',
      duration: 'combattimento_corrente',
      coverage: 'tutti_i_tipi_di_danno',
    ),
  );
  return const OculumAdaptationCriticalOutcome(
    isNaturalCritical: true,
    applied: true,
    alreadyActive: false,
  );
}

int oculumRemoveCurrentCombatTemporaryEffects(
  List<OculumTemporaryResistanceEffect> effects,
) {
  final before = effects.length;
  effects.removeWhere(
    (effect) =>
        effect.type == 'temporaneo' &&
        effect.duration == 'combattimento_corrente',
  );
  return before - effects.length;
}

class OculumActionQueue {
  OculumActionQueue();

  final Map<String, Future<void>> _tails = <String, Future<void>>{};

  Future<void> enqueue(String key, Future<void> Function() action) {
    final previous = _tails[key] ?? Future<void>.value();
    late final Future<void> next;
    next = previous
        .catchError((Object _) {})
        .then((_) => action())
        .whenComplete(() {
          if (identical(_tails[key], next)) {
            _tails.remove(key);
          }
        });
    _tails[key] = next;
    return next;
  }

  void clear() {
    _tails.clear();
  }
}

class OculumSaveRequestQueue {
  Future<void>? _active;
  bool? _pendingSoloLocal;

  bool get isRunning => _active != null;

  Future<void> enqueue({
    required bool soloLocal,
    required Future<void> Function(bool soloLocal) write,
    void Function(bool running)? onRunningChanged,
  }) {
    final pending = _pendingSoloLocal;
    _pendingSoloLocal = pending == null ? soloLocal : pending && soloLocal;

    final active = _active;
    if (active != null) return active;

    final drain = _drain(write, onRunningChanged);
    _active = drain;
    return drain;
  }

  Future<void> _drain(
    Future<void> Function(bool soloLocal) write,
    void Function(bool running)? onRunningChanged,
  ) async {
    onRunningChanged?.call(true);
    try {
      while (_pendingSoloLocal != null) {
        final soloLocal = _pendingSoloLocal!;
        _pendingSoloLocal = null;
        await write(soloLocal);
      }
    } finally {
      _active = null;
      onRunningChanged?.call(false);
    }
  }
}

class TemporaryOculumRules {
  final int extraLimit;
  final int fixedDuration;
  final int durationDie;

  const TemporaryOculumRules({
    required this.extraLimit,
    required this.fixedDuration,
    required this.durationDie,
  });
}

const Map<String, TemporaryOculumRules> temporaryOculumRules =
    <String, TemporaryOculumRules>{
      'facile': TemporaryOculumRules(
        extraLimit: 6,
        fixedDuration: 3,
        durationDie: 9,
      ),
      'normale': TemporaryOculumRules(
        extraLimit: 5,
        fixedDuration: 3,
        durationDie: 9,
      ),
      'difficile': TemporaryOculumRules(
        extraLimit: 3,
        fixedDuration: 3,
        durationDie: 6,
      ),
      'oculum': TemporaryOculumRules(
        extraLimit: 3,
        fixedDuration: 0,
        durationDie: 6,
      ),
    };

String normalizeTemporaryOculumDifficulty(String value) {
  switch (value.trim().toLowerCase()) {
    case 'facile':
    case 'easy':
      return 'facile';
    case 'difficile':
    case 'hard':
      return 'difficile';
    case 'oculum':
      return 'oculum';
    default:
      return 'normale';
  }
}

TemporaryOculumRules getTemporaryOculumRulesForDifficulty(String difficulty) {
  return temporaryOculumRules[normalizeTemporaryOculumDifficulty(difficulty)]!;
}

int getTemporaryOculumLimitForDifficulty(String difficulty) {
  return getTemporaryOculumRulesForDifficulty(difficulty).extraLimit;
}

int temporaryOculumDurationForDieRoll(String difficulty, int dieRoll) {
  final rules = getTemporaryOculumRulesForDifficulty(difficulty);
  final safeRoll = dieRoll.clamp(1, rules.durationDie).toInt();
  return rules.fixedDuration + safeRoll;
}

int rollTemporaryOculumDurationForDifficulty(
  String difficulty, {
  Random? random,
}) {
  final rules = getTemporaryOculumRulesForDifficulty(difficulty);
  final dieRoll = (random ?? Random()).nextInt(rules.durationDie) + 1;
  return rules.fixedDuration + dieRoll;
}

class TemporaryOculumState {
  final int normalCurrent;
  final int temporary;
  final int rollsRemaining;

  const TemporaryOculumState({
    required this.normalCurrent,
    required this.temporary,
    required this.rollsRemaining,
  });

  int get total => normalCurrent + temporary;

  String get visibleValue => '$total';
}

TemporaryOculumState addOculumToTemporaryState({
  required TemporaryOculumState state,
  required int normalMaximum,
  required int amount,
  required String difficulty,
  required int Function(int faces) rollDie,
  int minimumNormalCurrent = 0,
}) {
  final safeMinimum = min(minimumNormalCurrent, normalMaximum);
  final safeMaximum = max(safeMinimum, normalMaximum);
  final rules = getTemporaryOculumRulesForDifficulty(difficulty);
  final normal = state.normalCurrent.clamp(safeMinimum, safeMaximum).toInt();
  final temporary = state.temporary.clamp(0, rules.extraLimit).toInt();
  final safeAmount = max(0, amount);
  final toNormal = min(safeAmount, safeMaximum - normal);
  final overflow = safeAmount - toNormal;
  final nextTemporary = min(rules.extraLimit, temporary + overflow);
  final temporaryAdded = nextTemporary - temporary;
  var nextDuration = temporary > 0 ? max(0, state.rollsRemaining) : 0;

  if (temporaryAdded > 0) {
    final rolled = temporaryOculumDurationForDieRoll(
      difficulty,
      rollDie(rules.durationDie),
    );
    nextDuration = max(nextDuration, rolled);
  }

  return TemporaryOculumState(
    normalCurrent: normal + toNormal,
    temporary: nextTemporary,
    rollsRemaining: nextTemporary > 0 ? nextDuration : 0,
  );
}

TemporaryOculumState spendOculumFromTemporaryState({
  required TemporaryOculumState state,
  required int amount,
  int minimumNormalCurrent = 0,
}) {
  var remaining = max(0, amount);
  final temporarySpent = min(max(0, state.temporary), remaining);
  remaining -= temporarySpent;
  final nextTemporary = max(0, state.temporary - temporarySpent);
  final nextNormal = max(minimumNormalCurrent, state.normalCurrent - remaining);
  return TemporaryOculumState(
    normalCurrent: nextNormal,
    temporary: nextTemporary,
    rollsRemaining: nextTemporary > 0 ? max(0, state.rollsRemaining) : 0,
  );
}

TemporaryOculumState registerValidTemporaryOculumRoll(
  TemporaryOculumState state,
) {
  if (state.temporary <= 0 || state.rollsRemaining <= 0) return state;
  final nextDuration = state.rollsRemaining - 1;
  return TemporaryOculumState(
    normalCurrent: state.normalCurrent,
    temporary: nextDuration <= 0 ? 0 : state.temporary,
    rollsRemaining: max(0, nextDuration),
  );
}

TemporaryOculumState handleTemporaryOculumDifficultyChange({
  required TemporaryOculumState state,
  required String difficulty,
  int minimumNormalCurrent = 0,
}) {
  final limit = getTemporaryOculumLimitForDifficulty(difficulty);
  final temporary = state.temporary.clamp(0, limit).toInt();
  return TemporaryOculumState(
    normalCurrent: max(minimumNormalCurrent, state.normalCurrent),
    temporary: temporary,
    rollsRemaining: temporary > 0 ? max(0, state.rollsRemaining) : 0,
  );
}

TemporaryOculumState temporaryOculumStateFromJson({
  required Map<String, dynamic> json,
  required int normalMaximum,
  required String difficulty,
  int minimumNormalCurrent = 0,
}) {
  final safeMinimum = min(minimumNormalCurrent, normalMaximum);
  final safeMaximum = max(safeMinimum, normalMaximum);
  final hasTemporaryFields =
      json.containsKey('temporaryOculum') ||
      json.containsKey('temporaryOculumRollsRemaining') ||
      json.containsKey('normalCurrentOculum');
  final loadedTotal = readIntValue(json['currentOculum']).clamp(
    safeMinimum,
    safeMaximum + getTemporaryOculumLimitForDifficulty(difficulty),
  );
  final loadedTemporary = hasTemporaryFields
      ? readIntValue(
          json['temporaryOculum'],
        ).clamp(0, getTemporaryOculumLimitForDifficulty(difficulty)).toInt()
      : 0;
  final loadedNormal = hasTemporaryFields
      ? readIntValue(
          json['normalCurrentOculum'],
          fallback: loadedTotal - loadedTemporary,
        ).clamp(safeMinimum, safeMaximum).toInt()
      : loadedTotal.clamp(safeMinimum, safeMaximum).toInt();
  final loadedDuration = loadedTemporary > 0
      ? max(0, readIntValue(json['temporaryOculumRollsRemaining']))
      : 0;
  return TemporaryOculumState(
    normalCurrent: loadedNormal,
    temporary: loadedTemporary,
    rollsRemaining: loadedDuration,
  );
}

const int oculumTemporaryHpLimit = 20;

class OculumHpState {
  final int current;
  final int temporary;

  const OculumHpState({required this.current, required this.temporary});
}

OculumHpState healOculumHp({
  required int current,
  required int maximum,
  required int temporary,
  required int amount,
}) {
  final safeMaximum = max(1, maximum);
  final safeCurrent = current.clamp(0, safeMaximum).toInt();
  final safeTemporary = temporary.clamp(0, oculumTemporaryHpLimit).toInt();
  final safeAmount = max(0, amount);
  final toNormal = min(safeAmount, safeMaximum - safeCurrent);
  final overflow = safeAmount - toNormal;
  return OculumHpState(
    current: safeCurrent + toNormal,
    temporary: min(oculumTemporaryHpLimit, safeTemporary + overflow),
  );
}

OculumHpState damageOculumHp({
  required int current,
  required int temporary,
  required int amount,
}) {
  var remaining = max(0, amount);
  final safeTemporary = temporary.clamp(0, oculumTemporaryHpLimit).toInt();
  final absorbed = min(safeTemporary, remaining);
  remaining -= absorbed;
  return OculumHpState(
    current: max(0, current - remaining),
    temporary: safeTemporary - absorbed,
  );
}

class OculumPersistentVitalsSnapshot {
  final int normalCurrentOculum;
  final int temporaryOculum;
  final int temporaryOculumRollsRemaining;
  final int currentHp;
  final int temporaryHp;
  final String difficulty;

  const OculumPersistentVitalsSnapshot({
    required this.normalCurrentOculum,
    required this.temporaryOculum,
    required this.temporaryOculumRollsRemaining,
    required this.currentHp,
    required this.temporaryHp,
    required this.difficulty,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'normalCurrentOculum': normalCurrentOculum,
    'temporaryOculum': temporaryOculum,
    'temporaryOculumRollsRemaining': temporaryOculumRollsRemaining,
    'currentHp': '$currentHp',
    'hpTemp': '$temporaryHp',
    'campaignDifficulty': normalizeTemporaryOculumDifficulty(difficulty),
  };
}

const List<int> oculusSubtraitMasteryTargets = <int>[
  33,
  36,
  63,
  69,
  96,
  100,
  120,
  160,
  236,
  296,
  300,
  369,
  396,
  436,
  469,
  536,
  596,
  639,
  663,
  669,
  693,
  700,
  703,
  736,
  769,
  836,
  869,
  896,
  900,
  903,
  906,
  909,
];
const int _oculusSubtraitMasteryFinalTarget = 1000;
const List<int> _oculusSubtraitMasteryLateDigits = <int>[3, 6, 9];
const int _oculusSubtraitMasteryLateDecades = 9;

int oculusSubtraitMasteryTargetForValue(int value) {
  final normalizedValue = max(0, value);
  if (normalizedValue < oculusSubtraitMasteryTargets.length) {
    return oculusSubtraitMasteryTargets[normalizedValue];
  }
  final lateIndex = normalizedValue - oculusSubtraitMasteryTargets.length;
  final lateTargetCount =
      _oculusSubtraitMasteryLateDigits.length *
      _oculusSubtraitMasteryLateDecades;
  if (lateIndex < lateTargetCount) {
    final decade = 91 + lateIndex ~/ _oculusSubtraitMasteryLateDigits.length;
    final digit =
        _oculusSubtraitMasteryLateDigits[lateIndex %
            _oculusSubtraitMasteryLateDigits.length];
    return decade * 10 + digit;
  }
  return _oculusSubtraitMasteryFinalTarget;
}

int oculusSubtraitMasteryTargetForGrade(int grade) {
  return oculusSubtraitMasteryTargetForValue(grade);
}

int oculusSubtraitMasteryGainForDie(int die) {
  if (die < 15 || die > 20) return 0;
  return die == 20 ? 60 : die;
}

int oculusSubtraitMasteryApplyGain(HiddenEyeStat stat, int gain) {
  if (gain <= 0) return 0;

  stat.masteryProgress = max(0, stat.masteryProgress) + gain;
  var completedLevels = 0;
  var safety = 0;

  while (safety < 64) {
    final target = oculusSubtraitMasteryTargetForValue(stat.valore);
    if (target <= 0 || stat.masteryProgress < target) break;

    stat.masteryProgress -= target;
    stat.valore += 1;
    completedLevels += 1;
    safety += 1;
  }

  return completedLevels;
}

double oculusSubtraitMasteryFraction({
  required int progress,
  required int grade,
}) {
  final target = oculusSubtraitMasteryTargetForGrade(grade);
  if (target <= 0) return 0;
  return (max(0, progress) / target).clamp(0.0, 1.0).toDouble();
}

class ReputationEntry {
  ReputationEntry({
    required this.cityName,
    this.description = '',
    this.value = 0,
    int? baseValue,
    this.userModified = false,
    this.lastKarmaApplied = 0,
  }) : baseValue = baseValue ?? value;

  String cityName;
  String description;
  int value;
  int baseValue;
  bool userModified;
  int lastKarmaApplied;

  Map<String, dynamic> toJson() => {
    'cityName': cityName,
    'description': description,
    'value': value,
    'baseValue': baseValue,
    'userModified': userModified,
    'lastKarmaApplied': lastKarmaApplied,
  };

  factory ReputationEntry.fromJson(Map<String, dynamic> json) {
    final value = readIntValue(json['value']);
    return ReputationEntry(
      cityName: '${json['cityName'] ?? ''}',
      description: '${json['description'] ?? ''}',
      value: value,
      baseValue: json.containsKey('baseValue')
          ? readIntValue(json['baseValue'])
          : value - readIntValue(json['lastKarmaApplied']),
      userModified: readBoolValue(json['userModified']),
      lastKarmaApplied: readIntValue(json['lastKarmaApplied']),
    );
  }
}

class JournalEntry {
  JournalEntry({
    required this.title,
    required this.description,
    required this.cycleDay,
    required this.phase,
    required this.location,
    DateTime? createdAt,
    this.legacyPageIndex,
  }) : createdAt = createdAt ?? DateTime.now();

  String title;
  String description;
  int cycleDay;
  String phase;
  String location;
  DateTime createdAt;
  int? legacyPageIndex;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'cycleDay': cycleDay,
    'phase': phase,
    'location': location,
    'createdAt': createdAt.toIso8601String(),
    if (legacyPageIndex != null) 'legacyPageIndex': legacyPageIndex,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      cycleDay: readIntValue(json['cycleDay']),
      phase: '${json['phase'] ?? ''}',
      location: '${json['location'] ?? ''}',
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
      legacyPageIndex: json.containsKey('legacyPageIndex')
          ? readIntValue(json['legacyPageIndex'])
          : null,
    );
  }
}

class DraftNote {
  DraftNote({required this.text, DateTime? createdAt, this.converted = false})
    : createdAt = createdAt ?? DateTime.now();

  String text;
  DateTime createdAt;
  bool converted;

  Map<String, dynamic> toJson() => {
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'converted': converted,
  };

  factory DraftNote.fromJson(Map<String, dynamic> json) {
    return DraftNote(
      text: '${json['text'] ?? ''}',
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
      converted: readBoolValue(json['converted']),
    );
  }
}

class ConditionalBuffEntry {
  ConditionalBuffEntry({
    this.nome = '',
    this.descrizione = '',
    this.condizione = '',
    this.resilienza = 0,
    this.volonta = 0,
    this.materia = 0,
    this.oculum = 0,
    this.karma = 0,
    this.attivo = false,
  });

  String nome;
  String descrizione;
  String condizione;

  int resilienza;
  int volonta;
  int materia;
  int oculum;
  int karma;

  bool attivo;

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'descrizione': descrizione,
      'condizione': condizione,
      'resilienza': resilienza,
      'volonta': volonta,
      'materia': materia,
      'oculum': oculum,
      'karma': karma,
      'attivo': attivo,
    };
  }

  factory ConditionalBuffEntry.fromJson(Map<String, dynamic> json) {
    return ConditionalBuffEntry(
      nome: json['nome'] ?? '',
      descrizione: json['descrizione'] ?? '',
      condizione: json['condizione'] ?? '',
      resilienza: readIntValue(json['resilienza']),
      volonta: readIntValue(json['volonta']),
      materia: readIntValue(json['materia']),
      oculum: readIntValue(json['oculum']),
      karma: readIntValue(json['karma']),
      attivo: readBoolValue(json['attivo']),
    );
  }
}

class TitleOpenEntry {
  TitleOpenEntry({
    this.nome = '',
    this.descrizione = '',
    this.openBuff = '',
    this.openSkill = '',
    this.attiva = false,
    List<ConditionalBuffEntry>? conditionalBuffs,
    List<OculumStructuredEffect>? effects,
  }) {
    this.conditionalBuffs = conditionalBuffs ?? [];
    this.effects = effects ?? [];
  }

  String nome;
  String descrizione;
  String openBuff;
  String openSkill;
  bool attiva;

  late List<ConditionalBuffEntry> conditionalBuffs;
  late List<OculumStructuredEffect> effects;

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'descrizione': descrizione,
      'openBuff': openBuff,
      'openSkill': openSkill,
      'attiva': attiva,
      'conditionalBuffs': conditionalBuffs.map((x) => x.toJson()).toList(),
      if (effects.isNotEmpty)
        'effects': effects.map((effect) => effect.toJson()).toList(),
    };
  }

  factory TitleOpenEntry.fromJson(Map<String, dynamic> json) {
    return TitleOpenEntry(
      nome: json['nome'] ?? '',
      descrizione: json['descrizione'] ?? '',
      openBuff: json['openBuff'] ?? '',
      openSkill: json['openSkill'] ?? '',
      attiva: readBoolValue(json['attiva']),
      conditionalBuffs: ((json['conditionalBuffs'] ?? []) as List)
          .map(
            (x) => ConditionalBuffEntry.fromJson(Map<String, dynamic>.from(x)),
          )
          .toList(),
      effects: oculumReadStructuredEffects(
        json['effects'] ?? json['openEffects'],
      ),
    );
  }
}

class TitleExtraSkillEntry {
  TitleExtraSkillEntry({this.nome = '', this.descrizione = ''});

  String nome;
  String descrizione;

  Map<String, dynamic> toJson() {
    return {'nome': nome, 'descrizione': descrizione};
  }

  factory TitleExtraSkillEntry.fromJson(Map<String, dynamic> json) {
    return TitleExtraSkillEntry(
      nome: json['nome'] ?? '',
      descrizione: json['descrizione'] ?? '',
    );
  }
}

class OculumTitle {
  OculumTitle({
    required this.nome,
    required this.tipo,
    required this.ottenimento,
    this.leggenda = '',
    required this.buff,
    required this.puntoCieco,
    required this.skill,
    required this.richiede,
    this.resilienza = 0,
    this.volonta = 0,
    this.materia = 0,
    this.oculum = 0,
    this.karma = 0,
    this.equipaggiato = false,
    this.evoluto = false,
    this.openName = '',
    this.openDescription = '',
    this.openBuff = '',
    this.openSkill = '',
    this.openAttiva = false,
    this.chiaveSistema = '',
    this.openExperienceClaimed = 0,
    List<TitleOpenEntry>? openExtra,
    List<TitleExtraSkillEntry>? skillExtra,
    List<ConditionalBuffEntry>? titleConditionalBuffs,
    List<ConditionalBuffEntry>? openConditionalBuffs,
    List<OculumStructuredEffect>? openEffects,
  }) {
    this.openExtra = openExtra ?? [];
    this.skillExtra = skillExtra ?? [];
    this.titleConditionalBuffs = titleConditionalBuffs ?? [];
    this.openConditionalBuffs = openConditionalBuffs ?? [];
    this.openEffects = openEffects ?? [];
  }

  String nome;
  String tipo;
  String ottenimento;
  String leggenda;
  String buff;
  String puntoCieco;
  String skill;
  String richiede;

  int resilienza;
  int volonta;
  int materia;
  int oculum;
  int karma;

  bool equipaggiato;
  bool evoluto;

  String openName;
  String openDescription;
  String openBuff;
  String openSkill;
  bool openAttiva;
  String chiaveSistema;
  int openExperienceClaimed;

  late List<TitleOpenEntry> openExtra;
  late List<TitleExtraSkillEntry> skillExtra;
  late List<ConditionalBuffEntry> titleConditionalBuffs;
  late List<ConditionalBuffEntry> openConditionalBuffs;
  late List<OculumStructuredEffect> openEffects;

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'tipo': tipo,
      'ottenimento': ottenimento,
      'leggenda': leggenda,
      'buff': buff,
      'puntoCieco': puntoCieco,
      'skill': skill,
      'richiede': richiede,
      'resilienza': resilienza,
      'volonta': volonta,
      'materia': materia,
      'oculum': oculum,
      'karma': karma,
      'equipaggiato': equipaggiato,
      'evoluto': evoluto,
      'openName': openName,
      'openDescription': openDescription,
      'openBuff': openBuff,
      'openSkill': openSkill,
      'openAttiva': openAttiva,
      'chiaveSistema': chiaveSistema,
      'openExperienceClaimed': openExperienceClaimed,
      'openExtra': openExtra.map((x) => x.toJson()).toList(),
      'skillExtra': skillExtra.map((x) => x.toJson()).toList(),
      'titleConditionalBuffs': titleConditionalBuffs
          .map((x) => x.toJson())
          .toList(),
      'openConditionalBuffs': openConditionalBuffs
          .map((x) => x.toJson())
          .toList(),
      if (openEffects.isNotEmpty)
        'openEffects': openEffects.map((effect) => effect.toJson()).toList(),
    };
  }

  factory OculumTitle.fromJson(Map<String, dynamic> json) {
    return OculumTitle(
      nome: json['nome'] ?? '',
      tipo: json['tipo'] ?? '',
      ottenimento: json['ottenimento'] ?? '',
      leggenda: json['leggenda'] ?? '',
      buff: json['buff'] ?? '',
      puntoCieco: json['puntoCieco'] ?? '',
      skill: json['skill'] ?? '',
      richiede: json['richiede'] ?? '',
      resilienza: readIntValue(json['resilienza']),
      volonta: readIntValue(json['volonta']),
      materia: readIntValue(json['materia']),
      oculum: readIntValue(json['oculum']),
      karma: readIntValue(json['karma']),
      equipaggiato: readBoolValue(json['equipaggiato']),
      evoluto: readBoolValue(json['evoluto']),
      openName: json['openName'] ?? '',
      openDescription: json['openDescription'] ?? '',
      openBuff: json['openBuff'] ?? '',
      openSkill: json['openSkill'] ?? '',
      openAttiva: readBoolValue(json['openAttiva']),
      chiaveSistema: json['chiaveSistema'] ?? '',
      openExperienceClaimed: json.containsKey('openExperienceClaimed')
          ? readIntValue(json['openExperienceClaimed'])
          : oculumTitleOpenExperienceTarget(
              readBoolValue(json['evoluto'])
                  ? 1 +
                        ((json['openExtra'] ?? const <dynamic>[]) as List)
                            .length
                  : 0,
            ),
      openExtra: ((json['openExtra'] ?? []) as List)
          .map((x) => TitleOpenEntry.fromJson(Map<String, dynamic>.from(x)))
          .toList(),
      skillExtra: ((json['skillExtra'] ?? []) as List)
          .map(
            (x) => TitleExtraSkillEntry.fromJson(Map<String, dynamic>.from(x)),
          )
          .toList(),
      titleConditionalBuffs: ((json['titleConditionalBuffs'] ?? []) as List)
          .map(
            (x) => ConditionalBuffEntry.fromJson(Map<String, dynamic>.from(x)),
          )
          .toList(),
      openConditionalBuffs: ((json['openConditionalBuffs'] ?? []) as List)
          .map(
            (x) => ConditionalBuffEntry.fromJson(Map<String, dynamic>.from(x)),
          )
          .toList(),
      openEffects: oculumReadStructuredEffects(json['openEffects']),
    );
  }
}

class InventoryItem {
  InventoryItem({
    required this.nome,
    required this.peso,
    required this.quantita,
    required this.note,
    this.buff = '',
    this.arma = false,
    this.protegge = false,
    this.equipaggiata = false,
    this.bonusDanno = 0,
    this.bonusDifesa = 0,
    this.bonusScudo = 0,
    this.gradoOggetto = 0,
    this.gradoRichiesto = 0,
    this.elementoDanno = 'Fisico',
    this.putrefazioneSessioni = 0,
    this.sessioniSegnate = 0,
    this.putrefazioneGiornoInizio = 0,
    this.safeHpUsedDay = 0,
    this.saveShieldUsedDay = 0,
  });

  String nome;
  double peso;
  int quantita;
  String note;
  String buff;
  bool arma;
  bool protegge;
  bool equipaggiata;
  int bonusDanno;
  int bonusDifesa;
  int bonusScudo;
  int gradoOggetto;
  int gradoRichiesto;
  String elementoDanno;
  int putrefazioneSessioni;
  int sessioniSegnate;
  int putrefazioneGiornoInizio;
  int safeHpUsedDay;
  int saveShieldUsedDay;

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'peso': peso,
      'quantita': quantita,
      'note': note,
      'buff': buff,
      'arma': arma,
      'protegge': protegge,
      'equipaggiata': equipaggiata,
      'bonusDanno': bonusDanno,
      'bonusDifesa': bonusDifesa,
      'bonusScudo': bonusScudo,
      'gradoOggetto': gradoOggetto,
      'gradoRichiesto': gradoRichiesto,
      'elementoDanno': elementoDanno,
      'putrefazioneSessioni': putrefazioneSessioni,
      'sessioniSegnate': sessioniSegnate,
      'putrefazioneGiornoInizio': putrefazioneGiornoInizio,
      'safeHpUsedDay': safeHpUsedDay,
      'saveShieldUsedDay': saveShieldUsedDay,
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      nome: oculumCleanMojibakeText('${json['nome'] ?? ''}'),
      peso: readDoubleValue(json['peso']),
      quantita: readIntValue(json['quantita'], fallback: 1),
      note: oculumCleanMojibakeText('${json['note'] ?? ''}'),
      buff: oculumCleanMojibakeText('${json['buff'] ?? ''}'),
      arma: readBoolValue(json['arma']),
      protegge: readBoolValue(json['protegge']),
      equipaggiata: readBoolValue(json['equipaggiata']),
      bonusDanno: readIntValue(json['bonusDanno']),
      bonusDifesa: readIntValue(json['bonusDifesa']),
      bonusScudo: readIntValue(json['bonusScudo']),
      gradoOggetto: readIntValue(json['gradoOggetto']).clamp(0, 12).toInt(),
      gradoRichiesto: readIntValue(json['gradoRichiesto']).clamp(0, 12).toInt(),
      elementoDanno: oculumCleanMojibakeText(
        '${json['elementoDanno'] ?? json['tipoDanno'] ?? 'Fisico'}',
      ),
      putrefazioneSessioni: readIntValue(json['putrefazioneSessioni']),
      sessioniSegnate: readIntValue(json['sessioniSegnate']),
      putrefazioneGiornoInizio: readIntValue(json['putrefazioneGiornoInizio']),
      safeHpUsedDay: readIntValue(json['safeHpUsedDay']),
      saveShieldUsedDay: readIntValue(json['saveShieldUsedDay']),
    );
  }
}

class OculumSkillTextLimits {
  const OculumSkillTextLimits({required this.minimum, required this.maximum});

  final int minimum;
  final int maximum;
}

OculumSkillTextLimits? oculumSkillTextLimitsAtEnd(String text) {
  final match = RegExp(
    r'\(\s*(\d+)\s*(?:\/|,|;|-|\s+)\s*(\d+)\s*\)\s*$',
  ).firstMatch(text);
  if (match == null) return null;
  final minimum = int.tryParse(match.group(1)!);
  final maximum = int.tryParse(match.group(2)!);
  if (minimum == null || maximum == null || minimum > maximum) return null;
  return OculumSkillTextLimits(minimum: minimum, maximum: maximum);
}

class CharacterSkillForm {
  CharacterSkillForm({
    this.nome = '',
    this.tipo = '',
    this.livello = '',
    this.costo = '',
    this.cooldown = '',
    this.descrizione = '',
    this.effetto = '',
    this.buff = '',
    this.danni = '',
    this.cura = '',
    this.difesa = '',
    this.note = '',
    this.oculumMinimoUtilizzabile = 0,
    this.oculumMassimoUtilizzabile = 0,
    int? oculumMassimoMaestriaIniziale,
    bool? oculumLimitiConfiguratiManualmente,
    this.aumentoMassimoOculumAttivo = true,
    List<OculumStructuredEffect>? effettiStrutturati,
    this.costoStrutturato,
    this.cooldownStrutturato,
  }) : oculumMassimoMaestriaIniziale = max(
         0,
         oculumMassimoMaestriaIniziale ?? oculumMassimoUtilizzabile,
       ),
       oculumLimitiConfiguratiManualmente =
           oculumLimitiConfiguratiManualmente ??
           oculumMinimoUtilizzabile > 0 || oculumMassimoUtilizzabile > 0,
       effettiStrutturati = List<OculumStructuredEffect>.from(
         effettiStrutturati ?? const <OculumStructuredEffect>[],
       ) {
    aggiornaLimitiOculumDaDescrizione();
  }

  String nome;
  String tipo;
  String livello;
  String costo;
  String cooldown;
  String descrizione;
  String effetto;
  String buff;
  String danni;
  String cura;
  String difesa;
  String note;
  int oculumMinimoUtilizzabile;
  int oculumMassimoUtilizzabile;
  int oculumMassimoMaestriaIniziale;
  bool oculumLimitiConfiguratiManualmente;
  bool aumentoMassimoOculumAttivo;
  List<OculumStructuredEffect> effettiStrutturati;
  OculumSkillCost? costoStrutturato;
  OculumAbilityCooldown? cooldownStrutturato;

  bool get usaOculumConfigurabile =>
      oculumMinimoUtilizzabile > 0 || oculumMassimoUtilizzabile > 0;

  bool aggiornaLimitiOculumDaDescrizione() {
    if (oculumLimitiConfiguratiManualmente) return false;
    final parsed = oculumSkillTextLimitsAtEnd(descrizione);
    if (parsed == null) return false;
    final masteryGrowth = max(
      0,
      oculumMassimoUtilizzabile - oculumMassimoMaestriaIniziale,
    );
    final updatedMaximum = parsed.maximum + masteryGrowth;
    final changed =
        oculumMinimoUtilizzabile != parsed.minimum ||
        oculumMassimoUtilizzabile != updatedMaximum ||
        oculumMassimoMaestriaIniziale != parsed.maximum;
    oculumMinimoUtilizzabile = parsed.minimum;
    oculumMassimoUtilizzabile = updatedMaximum;
    oculumMassimoMaestriaIniziale = parsed.maximum;
    return changed;
  }

  Iterable<String> quickCommandTexts({
    Iterable<HiddenEyeStat> subtraits = const <HiddenEyeStat>[],
  }) sync* {
    yield nome;
    yield tipo;
    yield livello;
    yield costo;
    yield cooldown;
    yield descrizione;
    yield effetto;
    yield buff;
    yield danni;
    yield cura;
    yield difesa;
    yield note;
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'tipo': tipo,
      'livello': livello,
      'costo': costo,
      'cooldown': cooldown,
      'descrizione': descrizione,
      'effetto': effetto,
      'buff': buff,
      'danni': danni,
      'cura': cura,
      'difesa': difesa,
      'note': note,
      'oculumMinimoUtilizzabile': oculumMinimoUtilizzabile,
      'oculumMassimoUtilizzabile': oculumMassimoUtilizzabile,
      'oculumMassimoMaestriaIniziale': oculumMassimoMaestriaIniziale,
      'oculumLimitiConfiguratiManualmente': oculumLimitiConfiguratiManualmente,
      'aumentoMassimoOculumAttivo': aumentoMassimoOculumAttivo,
      if (effettiStrutturati.isNotEmpty)
        'effettiStrutturati': effettiStrutturati
            .map((effect) => effect.toJson())
            .toList(),
      if (costoStrutturato != null)
        'costoStrutturato': costoStrutturato!.toJson(),
      if (cooldownStrutturato != null)
        'cooldownStrutturato': cooldownStrutturato!.toJson(),
    };
  }

  factory CharacterSkillForm.fromLegacy({
    required String nome,
    required String tipo,
    required String costo,
    required String cooldown,
    required String descrizione,
  }) {
    return CharacterSkillForm(
      nome: nome,
      tipo: tipo,
      costo: costo,
      cooldown: cooldown,
      descrizione: descrizione,
    );
  }

  factory CharacterSkillForm.fromJson(Map<String, dynamic> json) {
    final minimum = max(
      0,
      readIntValue(
        json['oculumMinimoUtilizzabile'] ?? json['minimumUsableOculum'],
      ),
    );
    final maximum = max(
      0,
      readIntValue(
        json['oculumMassimoUtilizzabile'] ?? json['maximumUsableOculum'],
      ),
    );
    return CharacterSkillForm(
      nome: '${json['nome'] ?? json['name'] ?? ''}',
      tipo: '${json['tipo'] ?? json['type'] ?? ''}',
      livello: '${json['livello'] ?? json['level'] ?? ''}',
      costo: '${json['costo'] ?? json['cost'] ?? ''}',
      cooldown: '${json['cooldown'] ?? ''}',
      descrizione: '${json['descrizione'] ?? json['description'] ?? ''}',
      effetto: '${json['effetto'] ?? json['effect'] ?? ''}',
      buff: '${json['buff'] ?? json['comando'] ?? json['command'] ?? ''}',
      danni: '${json['danni'] ?? json['damage'] ?? ''}',
      cura: '${json['cura'] ?? json['heal'] ?? ''}',
      difesa: '${json['difesa'] ?? json['defense'] ?? ''}',
      note: '${json['note'] ?? json['notes'] ?? ''}',
      oculumMinimoUtilizzabile: minimum,
      oculumMassimoUtilizzabile: maximum,
      oculumMassimoMaestriaIniziale: max(
        0,
        readIntValue(
          json['oculumMassimoMaestriaIniziale'] ??
              json['initialMasteryMaximumOculum'],
          fallback: maximum,
        ),
      ),
      oculumLimitiConfiguratiManualmente:
          json.containsKey('oculumLimitiConfiguratiManualmente')
          ? readBoolValue(json['oculumLimitiConfiguratiManualmente'])
          : minimum > 0 || maximum > 0,
      aumentoMassimoOculumAttivo: readBoolValue(
        json['aumentoMassimoOculumAttivo'] ?? json['masteryGrowthEnabled'],
        fallback: true,
      ),
      effettiStrutturati: oculumReadStructuredEffects(
        json['effettiStrutturati'] ?? json['structuredEffects'],
      ),
      costoStrutturato:
          (json['costoStrutturato'] ?? json['structuredCost']) is Map
          ? OculumSkillCost.fromJson(
              Map<String, dynamic>.from(
                json['costoStrutturato'] ?? json['structuredCost'],
              ),
            )
          : null,
      cooldownStrutturato:
          (json['cooldownStrutturato'] ?? json['structuredCooldown']) is Map
          ? OculumAbilityCooldown.fromJson(
              Map<String, dynamic>.from(
                json['cooldownStrutturato'] ?? json['structuredCooldown'],
              ),
            )
          : null,
    );
  }

  void fillMissingFromLegacy({
    required String nome,
    required String tipo,
    required String costo,
    required String cooldown,
    required String descrizione,
  }) {
    if (this.nome.trim().isEmpty) this.nome = nome;
    if (this.tipo.trim().isEmpty) this.tipo = tipo;
    if (this.costo.trim().isEmpty) this.costo = costo;
    if (this.cooldown.trim().isEmpty) this.cooldown = cooldown;
    if (this.descrizione.trim().isEmpty) this.descrizione = descrizione;
  }
}

class OculumSkillUseLimits {
  const OculumSkillUseLimits({
    required this.minimum,
    required this.maximum,
    required this.available,
  });

  final int minimum;
  final int maximum;
  final int available;

  int get safeMinimum => max(0, minimum);
  int get safeMaximum => max(0, maximum);
  int get safeAvailable => max(0, available);
  bool get unlimited => safeMinimum == 0 && safeMaximum == 0;
  int get effectiveMaximum =>
      unlimited ? safeAvailable : min(safeMaximum, safeAvailable);
  bool get configurationValid => safeMaximum >= safeMinimum;
  bool get hasEnoughOculum => safeAvailable >= safeMinimum;

  bool accepts(int? value) {
    if (value == null || !configurationValid || !hasEnoughOculum) {
      return false;
    }
    return value >= safeMinimum && value <= effectiveMaximum;
  }
}

int? oculumParseSkillUseAmount(String raw) {
  final value = raw.trim();
  if (value.isEmpty || !RegExp(r'^\d+$').hasMatch(value)) return null;
  return int.tryParse(value);
}

class OculumSingleConfirmationGuard {
  bool _started = false;

  bool get started => _started;

  bool tryStart() {
    if (_started) return false;
    _started = true;
    return true;
  }

  void release() {
    _started = false;
  }
}

class OculumSkillMasteryPreview {
  const OculumSkillMasteryPreview({
    required this.minimum,
    required this.currentMaximum,
    required this.growthLimit,
    required this.selected,
    required this.validSelection,
  });

  final int minimum;
  final int currentMaximum;
  final int growthLimit;
  final int? selected;
  final bool validSelection;

  bool get reached => currentMaximum >= growthLimit;

  int get requestedIncrease {
    if (!validSelection ||
        selected == null ||
        selected! <= 0 ||
        reached ||
        max(0, minimum) == max(0, currentMaximum)) {
      return 0;
    }
    return selected == currentMaximum ? 2 : 1;
  }

  int get newMaximum => min(
    max(currentMaximum, 0) + requestedIncrease,
    max(growthLimit, currentMaximum),
  );

  int get appliedIncrease => max(0, newMaximum - currentMaximum);
}

class CharacterSkill {
  CharacterSkill({
    required this.nome,
    required this.tipo,
    required this.costo,
    required this.cooldown,
    required this.descrizione,
    this.resilienza = 0,
    this.volonta = 0,
    this.materia = 0,
    this.oculum = 0,
    this.danni = 0,
    this.difesa = 0,
    this.equipaggiata = false,
    List<CharacterSkillForm>? forme,
  }) : forme = (forme ?? <CharacterSkillForm>[]).toList() {
    ensureForms();
  }

  String nome;
  String tipo;
  String costo;
  String cooldown;
  String descrizione;
  int resilienza;
  int volonta;
  int materia;
  int oculum;
  int danni;
  int difesa;
  bool equipaggiata;
  List<CharacterSkillForm> forme;

  void ensureForms() {
    if (forme.isEmpty) {
      forme = [
        CharacterSkillForm.fromLegacy(
          nome: 'Forma 1',
          tipo: tipo,
          costo: costo,
          cooldown: cooldown,
          descrizione: descrizione,
        ),
      ];
    }

    if (forme.length > 12) {
      forme = forme.take(12).toList();
    }

    for (var i = 0; i < forme.length; i++) {
      if (forme[i].nome.trim().isEmpty) {
        forme[i].nome = 'Forma ${i + 1}';
      }
    }

    syncLegacyFromFirstForm();
  }

  void syncLegacyFromFirstForm() {
    if (forme.isEmpty) return;
    final first = forme.first;
    tipo = first.tipo;
    costo = first.costo;
    cooldown = first.cooldown;
    descrizione = first.descrizione;
  }

  Map<String, dynamic> toJson() {
    ensureForms();
    return {
      'nome': nome,
      'tipo': tipo,
      'costo': costo,
      'cooldown': cooldown,
      'descrizione': descrizione,
      'forme': forme.map((x) => x.toJson()).toList(),
      'resilienza': resilienza,
      'volonta': volonta,
      'materia': materia,
      'oculum': oculum,
      'danni': danni,
      'difesa': difesa,
      'equipaggiata': equipaggiata,
    };
  }

  factory CharacterSkill.fromJson(Map<String, dynamic> json) {
    final rawForms = json['forme'] ?? json['forms'];
    final forms = <CharacterSkillForm>[];
    if (rawForms is List) {
      for (final raw in rawForms) {
        if (raw is Map) {
          forms.add(
            CharacterSkillForm.fromJson(Map<String, dynamic>.from(raw)),
          );
        }
      }
    }
    if (forms.isEmpty) {
      forms.add(
        CharacterSkillForm.fromLegacy(
          nome: 'Forma 1',
          tipo: '${json['tipo'] ?? ''}',
          costo: '${json['costo'] ?? ''}',
          cooldown: '${json['cooldown'] ?? ''}',
          descrizione: '${json['descrizione'] ?? ''}',
        ),
      );
    } else {
      forms.first.fillMissingFromLegacy(
        nome: forms.first.nome,
        tipo: '${json['tipo'] ?? ''}',
        costo: '${json['costo'] ?? ''}',
        cooldown: '${json['cooldown'] ?? ''}',
        descrizione: '${json['descrizione'] ?? ''}',
      );
    }

    return CharacterSkill(
      nome: json['nome'] ?? '',
      tipo: json['tipo'] ?? '',
      costo: json['costo'] ?? '',
      cooldown: json['cooldown'] ?? '',
      descrizione: json['descrizione'] ?? '',
      resilienza: readIntValue(json['resilienza']),
      volonta: readIntValue(json['volonta']),
      materia: readIntValue(json['materia']),
      oculum: readIntValue(json['oculum']),
      danni: readIntValue(json['danni']),
      difesa: readIntValue(json['difesa']),
      equipaggiata: readBoolValue(json['equipaggiata']),
      forme: forms,
    );
  }
}

int oculumSkillMasteryGrowthLimit(CharacterSkill skill, int formIndex) {
  skill.ensureForms();
  if (formIndex < 0 || formIndex >= skill.forme.length) return 0;
  final form = skill.forme[formIndex];
  form.aggiornaLimitiOculumDaDescrizione();
  final currentMaximum = max(0, form.oculumMassimoUtilizzabile);
  final initialMaximum = max(
    0,
    form.oculumMassimoMaestriaIniziale > 0
        ? form.oculumMassimoMaestriaIniziale
        : currentMaximum,
  );
  var configuredLimit = 0;
  if (formIndex + 1 < skill.forme.length) {
    final nextForm = skill.forme[formIndex + 1];
    nextForm.aggiornaLimitiOculumDaDescrizione();
    configuredLimit = max(
      0,
      nextForm.oculumMassimoMaestriaIniziale > 0
          ? nextForm.oculumMassimoMaestriaIniziale
          : nextForm.oculumMassimoUtilizzabile,
    );
  }
  final rawLimit = configuredLimit > 0 ? configuredLimit : initialMaximum + 10;
  return max(currentMaximum, rawLimit);
}

class ArtSkill {
  ArtSkill({
    required this.nome,
    this.livello = 0,
    this.evo1 = '???',
    this.evo2 = '???',
    this.evo3 = '???',
    this.evo4 = '???',
    this.evo5 = '???',
    this.resilienza = 0,
    this.volonta = 0,
    this.materia = 0,
    this.oculum = 0,
    this.danni = 0,
    this.difesa = 0,
    List<int>? oculumMinimiPerLivello,
    List<int>? oculumMassimiPerLivello,
    List<int>? oculumMassimiInizialiPerLivello,
    List<bool>? oculumLimitiManualiPerLivello,
    List<bool>? aumentoMassimoOculumAttivoPerLivello,
    List<bool>? costoOculumDisabilitatoPerLivello,
    List<String>? risorseCostoPerLivello,
    Iterable<Iterable<OculumStructuredEffect>>? effettiPerLivello,
    Iterable<OculumAbilityCooldown>? cooldownPerLivello,
    List<String>? tipiPerLivello,
  }) : oculumMinimiPerLivello = _normalizeArtSkillOculumLevels(
         oculumMinimiPerLivello,
       ),
       oculumMassimiPerLivello = _normalizeArtSkillOculumLevels(
         oculumMassimiPerLivello,
       ),
       oculumMassimiInizialiPerLivello = oculumMassimiInizialiPerLivello == null
           ? _normalizeArtSkillOculumLevels(oculumMassimiPerLivello)
           : _normalizeArtSkillOculumLevels(oculumMassimiInizialiPerLivello),
       oculumLimitiManualiPerLivello = _normalizeArtSkillManualLevels(
         oculumLimitiManualiPerLivello,
         minimums: oculumMinimiPerLivello,
         maximums: oculumMassimiPerLivello,
       ),
       aumentoMassimoOculumAttivoPerLivello =
           _normalizeArtSkillGrowthEnabledLevels(
             aumentoMassimoOculumAttivoPerLivello,
           ),
       risorseCostoPerLivello = _normalizeArtSkillCostResourceLevels(
         risorseCostoPerLivello,
         legacyDisabled: costoOculumDisabilitatoPerLivello,
       ),
       costoOculumDisabilitatoPerLivello = _normalizeArtSkillCostDisabledLevels(
         costoOculumDisabilitatoPerLivello,
         resources: risorseCostoPerLivello,
       ),
       effettiPerLivello = oculumNormalizeArtEffectsPerLevel(effettiPerLivello),
       cooldownPerLivello = oculumNormalizeCooldownsPerLevel(
         cooldownPerLivello,
       ),
       tipiPerLivello = List<String>.generate(
         5,
         (index) => index < (tipiPerLivello?.length ?? 0)
             ? tipiPerLivello![index]
             : '',
       ) {
    for (var level = 1; level <= 5; level++) {
      aggiornaLimitiOculumDalTestoPerLivello(level, testoEvoluzione(level));
    }
  }

  String nome;

  /// Livello della singola Skill dell’Art.
  /// Serve per i Titoli del Fato:
  /// prima Skill livello 1 = primo Titolo del Fato
  /// seconda Skill livello 2 = secondo Titolo del Fato
  /// terza Skill livello 3 = terzo Titolo del Fato
  int livello;

  String evo1;
  String evo2;
  String evo3;
  String evo4;
  String evo5;
  int resilienza;
  int volonta;
  int materia;
  int oculum;
  int danni;
  int difesa;
  List<int> oculumMinimiPerLivello;
  List<int> oculumMassimiPerLivello;
  List<int> oculumMassimiInizialiPerLivello;
  List<bool> oculumLimitiManualiPerLivello;
  List<bool> aumentoMassimoOculumAttivoPerLivello;
  List<bool> costoOculumDisabilitatoPerLivello;
  List<String> risorseCostoPerLivello;
  List<List<OculumStructuredEffect>> effettiPerLivello;
  List<OculumAbilityCooldown> cooldownPerLivello;
  List<String> tipiPerLivello;

  String tipoPerLivello(int level) {
    final index = level - 1;
    return index >= 0 && index < tipiPerLivello.length
        ? tipiPerLivello[index]
        : '';
  }

  String testoEvoluzione(int level) => switch (level) {
    1 => evo1,
    2 => evo2,
    3 => evo3,
    4 => evo4,
    5 => evo5,
    _ => '',
  };

  List<OculumStructuredEffect> effettiEvoluzione(int level) {
    final index = level - 1;
    if (index < 0 || index >= effettiPerLivello.length) {
      return <OculumStructuredEffect>[];
    }
    return effettiPerLivello[index];
  }

  void copiaEffettiDaLivelloPrecedente(int level) {
    final index = level - 1;
    if (index <= 0 || index >= effettiPerLivello.length) return;
    effettiPerLivello[index] = effettiPerLivello[index - 1]
        .map((effect) => effect.copyForNextForm())
        .toList();
  }

  bool aggiornaLimitiOculumDalTestoPerLivello(int level, String text) {
    final index = level - 1;
    if (index < 0 || index >= 5 || oculumLimitiManualiPerLivello[index]) {
      return false;
    }
    final parsed = oculumSkillTextLimitsAtEnd(text);
    if (parsed == null) return false;
    final masteryGrowth = max(
      0,
      oculumMassimiPerLivello[index] - oculumMassimiInizialiPerLivello[index],
    );
    final updatedMaximum = parsed.maximum + masteryGrowth;
    final changed =
        oculumMinimiPerLivello[index] != parsed.minimum ||
        oculumMassimiPerLivello[index] != updatedMaximum ||
        oculumMassimiInizialiPerLivello[index] != parsed.maximum;
    oculumMinimiPerLivello[index] = parsed.minimum;
    oculumMassimiPerLivello[index] = updatedMaximum;
    oculumMassimiInizialiPerLivello[index] = parsed.maximum;
    return changed;
  }

  int oculumMinimoPerLivello(int level) =>
      _artSkillOculumLevelValue(oculumMinimiPerLivello, level);

  int oculumMassimoPerLivello(int level) =>
      _artSkillOculumLevelValue(oculumMassimiPerLivello, level);

  int oculumMassimoInizialePerLivello(int level) =>
      _artSkillOculumLevelValue(oculumMassimiInizialiPerLivello, level);

  bool costoOculumDisabilitato(int level) =>
      _artSkillBoolLevelValue(costoOculumDisabilitatoPerLivello, level);

  bool aumentoMassimoOculumAttivo(int level) {
    final index = level - 1;
    if (index < 0 || index >= aumentoMassimoOculumAttivoPerLivello.length) {
      return true;
    }
    return aumentoMassimoOculumAttivoPerLivello[index];
  }

  void impostaAumentoMassimoOculumAttivo(int level, bool enabled) {
    final index = level - 1;
    if (index < 0 || index >= aumentoMassimoOculumAttivoPerLivello.length) {
      return;
    }
    aumentoMassimoOculumAttivoPerLivello[index] = enabled;
  }

  String risorsaCostoPerLivello(int level) {
    final index = level - 1;
    if (index < 0 || index >= risorseCostoPerLivello.length) return 'oculum';
    return oculumNormalizeArtSkillCostResource(
      risorseCostoPerLivello[index],
      legacyOculumDisabled: costoOculumDisabilitato(level),
    );
  }

  void impostaRisorsaCostoPerLivello(int level, String resource) {
    final index = level - 1;
    if (index < 0 || index >= 5) return;
    final normalized = oculumNormalizeArtSkillCostResource(resource);
    risorseCostoPerLivello[index] = normalized;
    costoOculumDisabilitatoPerLivello[index] = normalized != 'oculum';
  }

  void impostaCostoOculumDisabilitato(int level, bool disabled) {
    final index = level - 1;
    if (index < 0 || index >= 5) return;
    costoOculumDisabilitatoPerLivello[index] = disabled;
    risorseCostoPerLivello[index] = disabled ? 'nessuna' : 'oculum';
  }

  void impostaLimitiOculumPerLivello(
    int level, {
    required int minimo,
    required int massimo,
    bool resetMassimoIniziale = true,
  }) {
    final index = level - 1;
    if (index < 0 || index >= 5) return;
    final safeMinimum = max(0, minimo);
    final safeMaximum = max(0, massimo);
    oculumMinimiPerLivello[index] = safeMinimum;
    oculumMassimiPerLivello[index] = safeMaximum;
    if (resetMassimoIniziale) {
      oculumMassimiInizialiPerLivello[index] = safeMaximum;
    }
    oculumLimitiManualiPerLivello[index] = true;
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'livello': livello,
      'evo1': evo1,
      'evo2': evo2,
      'evo3': evo3,
      'evo4': evo4,
      'evo5': evo5,
      'resilienza': resilienza,
      'volonta': volonta,
      'materia': materia,
      'oculum': oculum,
      'danni': danni,
      'difesa': difesa,
      'oculumMinimiPerLivello': List<int>.from(oculumMinimiPerLivello),
      'oculumMassimiPerLivello': List<int>.from(oculumMassimiPerLivello),
      'oculumMassimiInizialiPerLivello': List<int>.from(
        oculumMassimiInizialiPerLivello,
      ),
      'oculumLimitiManualiPerLivello': List<bool>.from(
        oculumLimitiManualiPerLivello,
      ),
      'aumentoMassimoOculumAttivoPerLivello': List<bool>.from(
        aumentoMassimoOculumAttivoPerLivello,
      ),
      'costoOculumDisabilitatoPerLivello': List<bool>.from(
        costoOculumDisabilitatoPerLivello,
      ),
      'risorseCostoPerLivello': List<String>.from(risorseCostoPerLivello),
      if (effettiPerLivello.any((effects) => effects.isNotEmpty))
        'effettiPerLivello': <List<Map<String, dynamic>>>[
          for (final effects in effettiPerLivello)
            <Map<String, dynamic>>[
              for (final effect in effects) effect.toJson(),
            ],
        ],
      if (cooldownPerLivello.any(
        (cooldown) =>
            cooldown.amount > 0 ||
            cooldown.remaining > 0 ||
            !cooldown.startsReady,
      ))
        'cooldownPerLivello': <Map<String, dynamic>>[
          for (final cooldown in cooldownPerLivello) cooldown.toJson(),
        ],
      if (tipiPerLivello.any((value) => value.trim().isNotEmpty))
        'tipiPerLivello': List<String>.from(tipiPerLivello),
    };
  }

  factory ArtSkill.fromJson(Map<String, dynamic> json) {
    final minimums = _readArtSkillOculumLevels(json['oculumMinimiPerLivello']);
    final maximums = _readArtSkillOculumLevels(json['oculumMassimiPerLivello']);
    return ArtSkill(
      nome: oculumCleanMojibakeText('${json['nome'] ?? ''}'),
      livello: readIntValue(json['livello']),
      evo1: oculumCleanMojibakeText('${json['evo1'] ?? '???'}'),
      evo2: oculumCleanMojibakeText('${json['evo2'] ?? '???'}'),
      evo3: oculumCleanMojibakeText('${json['evo3'] ?? '???'}'),
      evo4: oculumCleanMojibakeText('${json['evo4'] ?? '???'}'),
      evo5: oculumCleanMojibakeText('${json['evo5'] ?? '???'}'),
      resilienza: readIntValue(json['resilienza']),
      volonta: readIntValue(json['volonta']),
      materia: readIntValue(json['materia']),
      oculum: readIntValue(json['oculum']),
      danni: readIntValue(json['danni']),
      difesa: readIntValue(json['difesa']),
      oculumMinimiPerLivello: minimums,
      oculumMassimiPerLivello: maximums,
      oculumMassimiInizialiPerLivello:
          json.containsKey('oculumMassimiInizialiPerLivello')
          ? _readArtSkillOculumLevels(json['oculumMassimiInizialiPerLivello'])
          : null,
      oculumLimitiManualiPerLivello: _readArtSkillManualLevels(
        json['oculumLimitiManualiPerLivello'],
        minimums: minimums,
        maximums: maximums,
      ),
      aumentoMassimoOculumAttivoPerLivello: _readArtSkillBoolLevels(
        json['aumentoMassimoOculumAttivoPerLivello'] ??
            json['masteryGrowthEnabledPerLevel'],
      ),
      costoOculumDisabilitatoPerLivello: _readArtSkillBoolLevels(
        json['costoOculumDisabilitatoPerLivello'] ??
            json['oculumCostDisabledPerLevel'],
      ),
      risorseCostoPerLivello: _readArtSkillCostResourceLevels(
        json['risorseCostoPerLivello'] ?? json['costResourcesPerLevel'],
      ),
      effettiPerLivello: oculumReadArtEffectsPerLevel(
        json['effettiPerLivello'] ?? json['structuredEffectsPerLevel'],
      ),
      cooldownPerLivello: oculumReadCooldownsPerLevel(
        json['cooldownPerLivello'] ?? json['cooldownsPerLevel'],
      ),
      tipiPerLivello: readStringListValue(
        json['tipiPerLivello'] ?? json['typesPerLevel'],
      ),
    );
  }
}

const List<String> oculumArtSkillCostResourceKeys = <String>[
  'oculum',
  'materia',
  'volonta',
  'resilienza',
  'nessuna',
];

String oculumNormalizeArtSkillCostResource(
  dynamic raw, {
  bool legacyOculumDisabled = false,
}) {
  final normalized = oculumNormalizeText('$raw').replaceAll(' ', '');
  switch (normalized) {
    case 'materia':
      return 'materia';
    case 'volonta':
    case 'volontà':
      return 'volonta';
    case 'resilienza':
      return 'resilienza';
    case 'nessuna':
    case 'nessuno':
    case 'gratis':
    case 'free':
      return 'nessuna';
    case 'oculum':
      return 'oculum';
    default:
      return legacyOculumDisabled ? 'nessuna' : 'oculum';
  }
}

String oculumArtSkillCostResourceLabel(
  String resource, {
  bool english = false,
}) {
  switch (oculumNormalizeArtSkillCostResource(resource)) {
    case 'materia':
      return 'Materia';
    case 'volonta':
      return english ? 'Will' : 'Volontà';
    case 'resilienza':
      return english ? 'Resilience' : 'Resilienza';
    case 'nessuna':
      return english ? 'No cost' : 'Nessun costo';
    case 'oculum':
    default:
      return 'Oculum';
  }
}

List<int> _normalizeArtSkillOculumLevels(Iterable<int>? values) {
  final source = values?.toList(growable: false) ?? const <int>[];
  return List<int>.generate(
    5,
    (index) => index < source.length ? max(0, source[index]) : 0,
    growable: false,
  );
}

List<int>? _readArtSkillOculumLevels(dynamic raw) {
  if (raw is! List) return null;
  return <int>[for (final value in raw) max(0, readIntValue(value))];
}

List<bool> _normalizeArtSkillManualLevels(
  Iterable<bool>? values, {
  Iterable<int>? minimums,
  Iterable<int>? maximums,
}) {
  final source = values?.toList(growable: false);
  final minimumList = minimums?.toList(growable: false) ?? const <int>[];
  final maximumList = maximums?.toList(growable: false) ?? const <int>[];
  return List<bool>.generate(5, (index) {
    if (source != null && index < source.length) return source[index];
    final minimum = index < minimumList.length ? minimumList[index] : 0;
    final maximum = index < maximumList.length ? maximumList[index] : 0;
    return minimum > 0 || maximum > 0;
  }, growable: false);
}

List<bool>? _readArtSkillManualLevels(
  dynamic raw, {
  required Iterable<int>? minimums,
  required Iterable<int>? maximums,
}) {
  if (raw is! List) return null;
  return <bool>[for (final value in raw) readBoolValue(value)];
}

List<bool> _normalizeArtSkillBoolLevels(Iterable<bool>? values) {
  final source = values?.toList(growable: false) ?? const <bool>[];
  return List<bool>.generate(
    5,
    (index) => index < source.length && source[index],
    growable: false,
  );
}

List<bool> _normalizeArtSkillGrowthEnabledLevels(Iterable<bool>? values) {
  final source = values?.toList(growable: false);
  return List<bool>.generate(
    5,
    (index) => source == null || index >= source.length || source[index],
    growable: false,
  );
}

List<String> _normalizeArtSkillCostResourceLevels(
  Iterable<String>? values, {
  Iterable<bool>? legacyDisabled,
}) {
  final source = values?.toList(growable: false) ?? const <String>[];
  final disabled = legacyDisabled?.toList(growable: false) ?? const <bool>[];
  return List<String>.generate(5, (index) {
    final legacyValue = index < disabled.length && disabled[index];
    return oculumNormalizeArtSkillCostResource(
      index < source.length ? source[index] : '',
      legacyOculumDisabled: legacyValue,
    );
  }, growable: false);
}

List<bool> _normalizeArtSkillCostDisabledLevels(
  Iterable<bool>? values, {
  Iterable<String>? resources,
}) {
  final source = _normalizeArtSkillBoolLevels(values);
  final resourceList = resources?.toList(growable: false) ?? const <String>[];
  return List<bool>.generate(5, (index) {
    if (index < resourceList.length) {
      return oculumNormalizeArtSkillCostResource(resourceList[index]) !=
          'oculum';
    }
    return source[index];
  }, growable: false);
}

List<bool>? _readArtSkillBoolLevels(dynamic raw) {
  if (raw is! List) return null;
  return <bool>[for (final value in raw) readBoolValue(value)];
}

List<String>? _readArtSkillCostResourceLevels(dynamic raw) {
  if (raw is! List) return null;
  return <String>[
    for (final value in raw) oculumNormalizeArtSkillCostResource(value),
  ];
}

int _artSkillOculumLevelValue(List<int> values, int level) {
  final index = level - 1;
  if (index < 0 || index >= values.length) return 0;
  return max(0, values[index]);
}

bool _artSkillBoolLevelValue(List<bool> values, int level) {
  final index = level - 1;
  if (index < 0 || index >= values.length) return false;
  return values[index];
}

int oculumArtSkillMasteryGrowthLimit(
  ArtSkill skill,
  int level, {
  int maxLevel = 3,
}) {
  final safeMaxLevel = maxLevel.clamp(1, 5).toInt();
  if (level <= 0 || level > safeMaxLevel) return 0;
  skill.aggiornaLimitiOculumDalTestoPerLivello(
    level,
    skill.testoEvoluzione(level),
  );
  final currentMaximum = skill.oculumMassimoPerLivello(level);
  final storedInitial = skill.oculumMassimoInizialePerLivello(level);
  final initialMaximum = storedInitial > 0 ? storedInitial : currentMaximum;
  var nextInitial = 0;
  if (level < safeMaxLevel) {
    skill.aggiornaLimitiOculumDalTestoPerLivello(
      level + 1,
      skill.testoEvoluzione(level + 1),
    );
    nextInitial = skill.oculumMassimoInizialePerLivello(level + 1);
    if (nextInitial <= 0) {
      nextInitial = skill.oculumMassimoPerLivello(level + 1);
    }
  }
  final rawLimit = nextInitial > 0 ? nextInitial : initialMaximum + 10;
  return max(currentMaximum, rawLimit);
}

class OculumSkillUseDialogResult {
  const OculumSkillUseDialogResult({
    required this.selected,
    required this.minimum,
    required this.maximum,
    required this.limitsChanged,
  });

  final int selected;
  final int minimum;
  final int maximum;
  final bool limitsChanged;
}

class RuneArtCustomWord {
  RuneArtCustomWord({
    required this.id,
    required this.block,
    required this.choiceIt,
    required this.choiceEn,
    required this.effectIt,
    required this.effectEn,
    this.cost = 0,
    this.dt = 0,
  });

  String id;
  String block;
  String choiceIt;
  String choiceEn;
  String effectIt;
  String effectEn;
  int cost;
  int dt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'block': block,
      'choiceIt': choiceIt,
      'choiceEn': choiceEn,
      'effectIt': effectIt,
      'effectEn': effectEn,
      'cost': cost,
      'dt': dt,
    };
  }

  factory RuneArtCustomWord.fromJson(Map<String, dynamic> json) {
    final id = '${json['id'] ?? ''}'.trim();
    final choiceIt = '${json['choiceIt'] ?? json['choice'] ?? ''}'.trim();
    return RuneArtCustomWord(
      id: id.isEmpty ? 'custom_${DateTime.now().microsecondsSinceEpoch}' : id,
      block: '${json['block'] ?? 'CUSTOM'}'.trim(),
      choiceIt: choiceIt.isEmpty ? 'Parola custom' : choiceIt,
      choiceEn:
          '${json['choiceEn'] ?? json['choice'] ?? choiceIt}'.trim().isEmpty
          ? 'Custom word'
          : '${json['choiceEn'] ?? json['choice'] ?? choiceIt}'.trim(),
      effectIt: '${json['effectIt'] ?? json['effect'] ?? ''}'.trim(),
      effectEn: '${json['effectEn'] ?? json['effect'] ?? ''}'.trim(),
      cost: readIntValue(json['cost']),
      dt: readIntValue(json['dt']),
    );
  }
}

String? oculumNormalizePositiveGramText(String raw) {
  final normalized = raw.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(?:\.\d+)?$').hasMatch(normalized)) return null;
  if (!RegExp(r'[1-9]').hasMatch(normalized)) return null;

  final parts = normalized.split('.');
  var integerPart = parts.first;
  while (integerPart.length > 1 && integerPart.startsWith('0')) {
    integerPart = integerPart.substring(1);
  }
  return parts.length == 1 ? integerPart : '$integerPart.${parts[1]}';
}

class OculumRecipeIngredient {
  const OculumRecipeIngredient({required this.name, required this.grams});

  final String name;
  final String grams;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'grams': grams,
  };

  factory OculumRecipeIngredient.fromJson(Map<String, dynamic> json) {
    final rawGrams =
        json['grams'] ??
        json['quantityGrams'] ??
        json['quantity'] ??
        json['quantita'] ??
        '';
    return OculumRecipeIngredient(
      name: oculumCleanMojibakeText(
        '${json['name'] ?? json['nome'] ?? ''}',
      ).trim(),
      grams: oculumNormalizePositiveGramText('$rawGrams') ?? '1',
    );
  }
}

class OculumRecipe {
  const OculumRecipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.resultName,
    required this.resultDescription,
    required this.masterNotes,
    required this.visibleToPlayers,
    required this.createdAt,
    required this.updatedAt,
    this.recipeKind = 'crafting',
    this.forgeWeightMinKg = '',
    this.forgeWeightMaxKg = '',
    this.forgeDuration = '',
    this.forgeAttributes = '',
    this.forgeEffectText = '',
    this.forgeTarget = 'auto',
    this.personal = false,
    this.ownerTag = '',
    this.sourceRecipeId = '',
  });

  final String id;
  final String name;
  final List<OculumRecipeIngredient> ingredients;
  final String resultName;
  final String resultDescription;
  final String masterNotes;
  final bool visibleToPlayers;
  final String createdAt;
  final String updatedAt;
  final String recipeKind;
  final String forgeWeightMinKg;
  final String forgeWeightMaxKg;
  final String forgeDuration;
  final String forgeAttributes;
  final String forgeEffectText;
  final String forgeTarget;
  final bool personal;
  final String ownerTag;
  final String sourceRecipeId;

  OculumRecipe copyWith({
    String? id,
    String? name,
    List<OculumRecipeIngredient>? ingredients,
    String? resultName,
    String? resultDescription,
    String? masterNotes,
    bool? visibleToPlayers,
    String? createdAt,
    String? updatedAt,
    String? recipeKind,
    String? forgeWeightMinKg,
    String? forgeWeightMaxKg,
    String? forgeDuration,
    String? forgeAttributes,
    String? forgeEffectText,
    String? forgeTarget,
    bool? personal,
    String? ownerTag,
    String? sourceRecipeId,
  }) {
    return OculumRecipe(
      id: id ?? this.id,
      name: name ?? this.name,
      ingredients: ingredients ?? this.ingredients,
      resultName: resultName ?? this.resultName,
      resultDescription: resultDescription ?? this.resultDescription,
      masterNotes: masterNotes ?? this.masterNotes,
      visibleToPlayers: visibleToPlayers ?? this.visibleToPlayers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recipeKind: recipeKind ?? this.recipeKind,
      forgeWeightMinKg: forgeWeightMinKg ?? this.forgeWeightMinKg,
      forgeWeightMaxKg: forgeWeightMaxKg ?? this.forgeWeightMaxKg,
      forgeDuration: forgeDuration ?? this.forgeDuration,
      forgeAttributes: forgeAttributes ?? this.forgeAttributes,
      forgeEffectText: forgeEffectText ?? this.forgeEffectText,
      forgeTarget: forgeTarget ?? this.forgeTarget,
      personal: personal ?? this.personal,
      ownerTag: ownerTag ?? this.ownerTag,
      sourceRecipeId: sourceRecipeId ?? this.sourceRecipeId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'ingredients': ingredients.map((item) => item.toJson()).toList(),
    'resultName': resultName,
    'resultDescription': resultDescription,
    'masterNotes': masterNotes,
    'visibleToPlayers': visibleToPlayers,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'recipeKind': recipeKind,
    'forgeWeightMinKg': forgeWeightMinKg,
    'forgeWeightMaxKg': forgeWeightMaxKg,
    'forgeDuration': forgeDuration,
    'forgeAttributes': forgeAttributes,
    'forgeEffectText': forgeEffectText,
    'forgeTarget': forgeTarget,
    'personal': personal,
    'ownerTag': ownerTag,
    'sourceRecipeId': sourceRecipeId,
  };

  factory OculumRecipe.fromJson(Map<String, dynamic> json) {
    final ingredientsRaw = json['ingredients'] ?? json['ingredienti'];
    final now = DateTime.now().toIso8601String();
    final id = '${json['id'] ?? ''}'.trim();
    return OculumRecipe(
      id: id.isEmpty ? 'recipe_${DateTime.now().microsecondsSinceEpoch}' : id,
      name: oculumCleanMojibakeText(
        '${json['name'] ?? json['nome'] ?? ''}',
      ).trim(),
      ingredients: (ingredientsRaw is List ? ingredientsRaw : const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => OculumRecipeIngredient.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      resultName: oculumCleanMojibakeText(
        '${json['resultName'] ?? json['risultato'] ?? ''}',
      ).trim(),
      resultDescription: oculumCleanMojibakeText(
        '${json['resultDescription'] ?? json['descrizioneRisultato'] ?? ''}',
      ).trim(),
      masterNotes: oculumCleanMojibakeText(
        '${json['masterNotes'] ?? json['noteMaster'] ?? ''}',
      ).trim(),
      visibleToPlayers: readBoolValue(
        json['visibleToPlayers'] ?? json['visibileAiGiocatori'],
        fallback: true,
      ),
      createdAt: '${json['createdAt'] ?? now}',
      updatedAt: '${json['updatedAt'] ?? now}',
      recipeKind:
          <String>{
            'forge',
            'crafting',
            'alchemy',
          }.contains('${json['recipeKind'] ?? json['tipo'] ?? 'crafting'}')
          ? '${json['recipeKind'] ?? json['tipo'] ?? 'crafting'}'
          : 'crafting',
      forgeWeightMinKg:
          '${json['forgeWeightMinKg'] ?? json['pesoMinKg'] ?? ''}',
      forgeWeightMaxKg:
          '${json['forgeWeightMaxKg'] ?? json['pesoMaxKg'] ?? ''}',
      forgeDuration: oculumCleanMojibakeText(
        '${json['forgeDuration'] ?? json['tempoForge'] ?? ''}',
      ).trim(),
      forgeAttributes: oculumCleanMojibakeText(
        '${json['forgeAttributes'] ?? json['attributiForge'] ?? ''}',
      ).trim(),
      forgeEffectText: oculumCleanMojibakeText(
        '${json['forgeEffectText'] ?? json['effettiForge'] ?? ''}',
      ).trim(),
      forgeTarget:
          <String>{
            'auto',
            'arma',
            'protezione',
          }.contains('${json['forgeTarget'] ?? 'auto'}')
          ? '${json['forgeTarget'] ?? 'auto'}'
          : 'auto',
      personal: readBoolValue(json['personal']),
      ownerTag: '${json['ownerTag'] ?? ''}',
      sourceRecipeId: '${json['sourceRecipeId'] ?? ''}',
    );
  }
}

List<OculumRecipe> oculumVisibleRecipes({
  required Iterable<OculumRecipe> recipes,
  required bool isMaster,
  String query = '',
}) {
  final needle = query.trim().toLowerCase();
  return recipes
      .where((recipe) {
        if (!isMaster && !recipe.visibleToPlayers) return false;
        if (needle.isEmpty) return true;
        return recipe.name.toLowerCase().contains(needle) ||
            recipe.resultName.toLowerCase().contains(needle) ||
            recipe.ingredients.any(
              (ingredient) => ingredient.name.toLowerCase().contains(needle),
            );
      })
      .toList(growable: false);
}

class CharacterArt {
  CharacterArt({
    required this.nome,
    required this.tipo,
    required this.descrizione,
    required this.skills,
    this.sbloccata = true,
    this.openName = '',
    this.openDescription = '',
    this.openBuff = '',
    this.openSkill = '',
    this.openAttiva = false,
    this.openDescriptionType = '',
    this.openSkillType = '',
    this.openBuffType = '',
    List<OculumStructuredEffect>? openDescriptionEffects,
    List<OculumStructuredEffect>? openSkillEffects,
    List<OculumStructuredEffect>? openBuffEffects,
    this.openDescriptionCooldown,
    this.openSkillCooldown,
    this.openBuffCooldown,
    List<String>? runeWordsKnown,
    List<String>? runeQuickWordIds,
    List<String>? runeQuickWordIdsSlot2,
    this.runeActiveSlot = 1,
    List<RuneArtCustomWord>? runeCustomWords,
    this.runeBooksRead = 0,
    this.integritaCorrente = -1,
    this.esaurimentoCompleto = false,
  }) : runeWordsKnown = List<String>.from(runeWordsKnown ?? const <String>[]),
       runeQuickWordIds = List<String>.from(
         runeQuickWordIds ?? const <String>[],
       ),
       runeQuickWordIdsSlot2 = List<String>.from(
         runeQuickWordIdsSlot2 ?? const <String>[],
       ),
       runeCustomWords = List<RuneArtCustomWord>.from(
         runeCustomWords ?? const <RuneArtCustomWord>[],
       ),
       openDescriptionEffects = List<OculumStructuredEffect>.from(
         openDescriptionEffects ?? const <OculumStructuredEffect>[],
       ),
       openSkillEffects = List<OculumStructuredEffect>.from(
         openSkillEffects ?? const <OculumStructuredEffect>[],
       ),
       openBuffEffects = List<OculumStructuredEffect>.from(
         openBuffEffects ?? const <OculumStructuredEffect>[],
       );

  String nome;
  String tipo;
  String descrizione;
  List<ArtSkill> skills;
  bool sbloccata;
  String openName;
  String openDescription;
  String openBuff;
  String openSkill;
  bool openAttiva;
  String openDescriptionType;
  String openSkillType;
  String openBuffType;
  List<OculumStructuredEffect> openDescriptionEffects;
  List<OculumStructuredEffect> openSkillEffects;
  List<OculumStructuredEffect> openBuffEffects;
  OculumAbilityCooldown? openDescriptionCooldown;
  OculumAbilityCooldown? openSkillCooldown;
  OculumAbilityCooldown? openBuffCooldown;
  List<String> runeWordsKnown;
  List<String> runeQuickWordIds;
  List<String> runeQuickWordIdsSlot2;
  int runeActiveSlot;
  List<RuneArtCustomWord> runeCustomWords;
  int runeBooksRead;
  int integritaCorrente;
  bool esaurimentoCompleto;

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'tipo': tipo,
      'descrizione': descrizione,
      'skills': skills.map((x) => x.toJson()).toList(),
      'sbloccata': sbloccata,
      'openName': openName,
      'openDescription': openDescription,
      'openBuff': openBuff,
      'openSkill': openSkill,
      'openAttiva': openAttiva,
      if (openDescriptionType.trim().isNotEmpty)
        'openDescriptionType': openDescriptionType,
      if (openSkillType.trim().isNotEmpty) 'openSkillType': openSkillType,
      if (openBuffType.trim().isNotEmpty) 'openBuffType': openBuffType,
      if (openDescriptionEffects.isNotEmpty)
        'openDescriptionEffects': openDescriptionEffects
            .map((effect) => effect.toJson())
            .toList(),
      if (openSkillEffects.isNotEmpty)
        'openSkillEffects': openSkillEffects
            .map((effect) => effect.toJson())
            .toList(),
      if (openBuffEffects.isNotEmpty)
        'openBuffEffects': openBuffEffects
            .map((effect) => effect.toJson())
            .toList(),
      if (openDescriptionCooldown != null)
        'openDescriptionCooldown': openDescriptionCooldown!.toJson(),
      if (openSkillCooldown != null)
        'openSkillCooldown': openSkillCooldown!.toJson(),
      if (openBuffCooldown != null)
        'openBuffCooldown': openBuffCooldown!.toJson(),
      'runeWordsKnown': List<String>.from(runeWordsKnown),
      'runeQuickWordIds': List<String>.from(runeQuickWordIds),
      'runeQuickWordIdsSlot2': List<String>.from(runeQuickWordIdsSlot2),
      'runeActiveSlot': runeActiveSlot,
      'runeCustomWords': runeCustomWords.map((x) => x.toJson()).toList(),
      'runeBooksRead': runeBooksRead,
      'integritaCorrente': integritaCorrente,
      'esaurimentoCompleto': esaurimentoCompleto,
    };
  }

  factory CharacterArt.fromJson(Map<String, dynamic> json) {
    return CharacterArt(
      nome: oculumCleanMojibakeText('${json['nome'] ?? ''}'),
      tipo: oculumCleanMojibakeText('${json['tipo'] ?? ''}'),
      descrizione: oculumCleanMojibakeText('${json['descrizione'] ?? ''}'),
      skills: ((json['skills'] ?? []) as List)
          .map((x) => ArtSkill.fromJson(Map<String, dynamic>.from(x)))
          .toList(),
      sbloccata: readBoolValue(json['sbloccata'], fallback: true),
      openName: oculumCleanMojibakeText('${json['openName'] ?? ''}'),
      openDescription: oculumCleanMojibakeText(
        '${json['openDescription'] ?? ''}',
      ),
      openBuff: oculumCleanMojibakeText('${json['openBuff'] ?? ''}'),
      openSkill: oculumCleanMojibakeText('${json['openSkill'] ?? ''}'),
      openAttiva: readBoolValue(json['openAttiva']),
      openDescriptionType: '${json['openDescriptionType'] ?? ''}',
      openSkillType: '${json['openSkillType'] ?? ''}',
      openBuffType: '${json['openBuffType'] ?? ''}',
      openDescriptionEffects: oculumReadStructuredEffects(
        json['openDescriptionEffects'],
      ),
      openSkillEffects: oculumReadStructuredEffects(json['openSkillEffects']),
      openBuffEffects: oculumReadStructuredEffects(json['openBuffEffects']),
      openDescriptionCooldown: json['openDescriptionCooldown'] is Map
          ? OculumAbilityCooldown.fromJson(
              Map<String, dynamic>.from(json['openDescriptionCooldown']),
            )
          : null,
      openSkillCooldown: json['openSkillCooldown'] is Map
          ? OculumAbilityCooldown.fromJson(
              Map<String, dynamic>.from(json['openSkillCooldown']),
            )
          : null,
      openBuffCooldown: json['openBuffCooldown'] is Map
          ? OculumAbilityCooldown.fromJson(
              Map<String, dynamic>.from(json['openBuffCooldown']),
            )
          : null,
      runeWordsKnown: readStringListValue(json['runeWordsKnown']),
      runeQuickWordIds: readStringListValue(json['runeQuickWordIds']),
      runeQuickWordIdsSlot2: readStringListValue(json['runeQuickWordIdsSlot2']),
      runeActiveSlot: readIntValue(json['runeActiveSlot'], fallback: 1),
      runeCustomWords: readMapListValue(
        json['runeCustomWords'],
      ).map(RuneArtCustomWord.fromJson).toList(),
      runeBooksRead: readIntValue(json['runeBooksRead']),
      integritaCorrente: json.containsKey('integritaCorrente')
          ? readIntValue(json['integritaCorrente'])
          : -1,
      esaurimentoCompleto: readBoolValue(json['esaurimentoCompleto']),
    );
  }
}

// =====================================================
