part of '../../main.dart';

enum OculumConditionCategory {
  physical,
  mental,
  elemental,
  oculum,
  positive,
  special,
}

enum OculumConditionPolarity { negative, positive, neutral }

enum OculumConditionStackMode {
  none,
  refreshDuration,
  increaseStage,
  increaseStacks,
  replaceIfStronger,
}

enum OculumConditionDurationType {
  turns,
  shortRest,
  longRest,
  meal,
  rolls,
  actions,
  rests,
  permanent,
  narrative,
}

enum OculumConditionTickTrigger {
  none,
  startTurn,
  endTurn,
  roll,
  action,
  damageReceived,
  damageDealt,
  shortRest,
  longRest,
  specificEvent,
}

enum OculumConditionDifficultyScaling {
  none,
  damage,
  duration,
  damageAndDuration,
  recovery,
  custom,
}

/// Granular UI/calculation channels touched by a condition.
///
/// These are declarative only: the persisted source remains
/// [OculumConditionInstance]. Widgets subscribe to the channels they render.
enum OculumConditionTarget {
  resilienza,
  volonta,
  materia,
  oculum,
  hp,
  scudo,
  scudoOculum,
  danno,
  difesa,
  vc,
  cm,
  iniziativa,
  movimento,
  tiri,
  reazioni,
  recupero,
  skill,
  art,
  titoli,
  combattimento,
}

class OculumDifficultyProfile {
  const OculumDifficultyProfile({
    required this.id,
    required this.periodicDamageMultiplier,
    required this.durationMultiplier,
    required this.healingEffectiveness,
    required this.rollPenaltyMultiplier,
    required this.rollPenaltyCap,
    required this.periodicDamageCapPercent,
    required this.naturalDecayTurns,
    required this.controlProtectionTurns,
    required this.descriptionIt,
    required this.descriptionEn,
  });

  final String id;
  final double periodicDamageMultiplier;
  final double durationMultiplier;
  final double healingEffectiveness;
  final double rollPenaltyMultiplier;
  final int rollPenaltyCap;
  final double periodicDamageCapPercent;
  final int naturalDecayTurns;
  final int controlProtectionTurns;
  final String descriptionIt;
  final String descriptionEn;
}

OculumDifficultyProfile oculumConditionDifficultyProfile(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'facile':
      return const OculumDifficultyProfile(
        id: 'facile',
        periodicDamageMultiplier: .75,
        durationMultiplier: .75,
        healingEffectiveness: 1.25,
        rollPenaltyMultiplier: 1,
        rollPenaltyCap: 6,
        periodicDamageCapPercent: 25,
        naturalDecayTurns: 1,
        controlProtectionTurns: 2,
        descriptionIt:
            'Condizioni meno persistenti, cure piu efficaci e forte protezione dal controllo ripetuto.',
        descriptionEn:
            'Less persistent conditions, stronger treatment and strong repeated-control protection.',
      );
    case 'difficile':
      return const OculumDifficultyProfile(
        id: 'difficile',
        periodicDamageMultiplier: 1.25,
        durationMultiplier: 1.25,
        healingEffectiveness: .85,
        rollPenaltyMultiplier: 1.5,
        rollPenaltyCap: 10,
        periodicDamageCapPercent: 25,
        naturalDecayTurns: 2,
        controlProtectionTurns: 1,
        descriptionIt:
            'Condizioni piu persistenti, recupero ridotto e stadi critici piu frequenti.',
        descriptionEn:
            'More persistent conditions, reduced recovery and more frequent critical stages.',
      );
    case 'oculum':
      return const OculumDifficultyProfile(
        id: 'oculum',
        periodicDamageMultiplier: 1.5,
        durationMultiplier: 1.5,
        healingEffectiveness: .70,
        rollPenaltyMultiplier: 2,
        rollPenaltyCap: 12,
        periodicDamageCapPercent: 49,
        naturalDecayTurns: 3,
        controlProtectionTurns: 1,
        descriptionIt:
            'Condizioni molto persistenti, recupero difficile e stadi avanzati estremamente pericolosi.',
        descriptionEn:
            'Very persistent conditions, difficult recovery and extremely dangerous advanced stages.',
      );
    default:
      return const OculumDifficultyProfile(
        id: 'medio',
        periodicDamageMultiplier: 1,
        durationMultiplier: 1,
        healingEffectiveness: 1,
        rollPenaltyMultiplier: 1.25,
        rollPenaltyCap: 8,
        periodicDamageCapPercent: 25,
        naturalDecayTurns: 1,
        controlProtectionTurns: 1,
        descriptionIt:
            'Esperienza standard: tutte le condizioni usano i valori base.',
        descriptionEn:
            'Standard experience: all conditions use their base values.',
      );
  }
}

class OculumConditionDefinition {
  const OculumConditionDefinition({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.icon,
    required this.category,
    required this.polarity,
    required this.descriptionIt,
    required this.descriptionEn,
    this.maxStage = 1,
    this.maxStacks = 1,
    this.stackMode = OculumConditionStackMode.refreshDuration,
    this.defaultDuration = 3,
    this.durationType = OculumConditionDurationType.turns,
    this.tickTrigger = OculumConditionTickTrigger.none,
    this.removable = true,
    this.basePercentByStage = const <double>[],
    this.minimumByStage = const <int>[],
    this.durationByStage = const <int>[],
    this.rollModifierByStage = const <int>[],
    this.difficultyScaling = OculumConditionDifficultyScaling.none,
    this.control = false,
    this.contextActionIt = '',
    this.contextActionEn = '',
    this.affectedTargets = const <OculumConditionTarget>{},
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final IconData icon;
  final OculumConditionCategory category;
  final OculumConditionPolarity polarity;
  final String descriptionIt;
  final String descriptionEn;
  final int maxStage;
  final int maxStacks;
  final OculumConditionStackMode stackMode;
  final int defaultDuration;
  final OculumConditionDurationType durationType;
  final OculumConditionTickTrigger tickTrigger;
  final bool removable;
  final List<double> basePercentByStage;
  final List<int> minimumByStage;
  final List<int> durationByStage;
  final List<int> rollModifierByStage;
  final OculumConditionDifficultyScaling difficultyScaling;
  final bool control;
  final String contextActionIt;
  final String contextActionEn;
  final Set<OculumConditionTarget> affectedTargets;

  double percentForStage(int stage) => basePercentByStage.isEmpty
      ? 0
      : basePercentByStage[(stage.clamp(1, basePercentByStage.length)) - 1];
  int minimumForStage(int stage) => minimumByStage.isEmpty
      ? 0
      : minimumByStage[(stage.clamp(1, minimumByStage.length)) - 1];
  int durationForStage(int stage) => durationByStage.isEmpty
      ? defaultDuration
      : durationByStage[(stage.clamp(1, durationByStage.length)) - 1];
  int rollModifierForStage(int stage) => rollModifierByStage.isEmpty
      ? 0
      : rollModifierByStage[(stage.clamp(1, rollModifierByStage.length)) - 1];
}

class OculumConditionInstance {
  OculumConditionInstance({
    required this.id,
    required this.conditionType,
    required this.category,
    this.stage = 1,
    this.stacks = 1,
    this.duration = 0,
    this.durationType = OculumConditionDurationType.turns,
    this.tickTrigger = OculumConditionTickTrigger.none,
    this.removable = true,
    this.source = '',
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) : createdAt = createdAt ?? DateTime.now(),
       metadata = metadata ?? <String, dynamic>{};

  final String id;
  final String conditionType;
  final OculumConditionCategory category;
  int stage;
  int stacks;
  int duration;
  OculumConditionDurationType durationType;
  OculumConditionTickTrigger tickTrigger;
  bool removable;
  String source;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'conditionType': conditionType,
    'category': category.name,
    'stage': stage,
    'stacks': stacks,
    'duration': duration,
    'durationType': durationType.name,
    'tickTrigger': tickTrigger.name,
    'removable': removable,
    'source': source,
    'createdAt': createdAt.toIso8601String(),
    if (metadata.isNotEmpty) 'metadata': metadata,
  };

  factory OculumConditionInstance.fromJson(Map<String, dynamic> json) {
    T enumValue<T extends Enum>(Iterable<T> values, Object? raw, T fallback) {
      final name = '$raw';
      return values.firstWhere(
        (value) => value.name == name,
        orElse: () => fallback,
      );
    }

    return OculumConditionInstance(
      id: '${json['id'] ?? 'condition_${DateTime.now().microsecondsSinceEpoch}'}',
      conditionType: '${json['conditionType'] ?? json['type'] ?? 'custom'}',
      category: enumValue(
        OculumConditionCategory.values,
        json['category'],
        OculumConditionCategory.special,
      ),
      stage: max(1, readIntValue(json['stage'], fallback: 1)),
      stacks: max(1, readIntValue(json['stacks'], fallback: 1)),
      duration: max(0, readIntValue(json['duration'])),
      durationType: enumValue(
        OculumConditionDurationType.values,
        json['durationType'],
        OculumConditionDurationType.turns,
      ),
      tickTrigger: enumValue(
        OculumConditionTickTrigger.values,
        json['tickTrigger'],
        OculumConditionTickTrigger.none,
      ),
      removable: readBoolValue(json['removable'], fallback: true),
      source: '${json['source'] ?? ''}',
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : <String, dynamic>{},
    );
  }
}

/// Vero Bruciore dell'Anima can remain active only while its prerequisite is
/// present at the required stage. Keeping this rule here makes activation,
/// removal, imports, and turn processing agree on the same condition.
bool oculumCanMaintainTrueSoulBurn(
  Iterable<OculumConditionInstance> conditions,
) {
  return conditions.any(
    (instance) =>
        instance.conditionType == 'resilienza_in_fiamme' && instance.stage >= 2,
  );
}

bool oculumConditionIsNegative(OculumConditionInstance instance) {
  final definition = oculumConditionDefinition(instance.conditionType);
  if (definition != null) {
    return definition.polarity == OculumConditionPolarity.negative;
  }
  return '${instance.metadata['polarity']}'.trim().toLowerCase() ==
      OculumConditionPolarity.negative.name;
}

int oculumRemoveNegativeConditions(List<OculumConditionInstance> conditions) {
  final before = conditions.length;
  conditions.removeWhere(oculumConditionIsNegative);
  return before - conditions.length;
}

int oculumConditionScaledValue({
  required int referenceValue,
  required double basePercent,
  required int minimum,
  required String difficulty,
  int? maximum,
  bool scaleWithDifficulty = true,
}) {
  final multiplier = scaleWithDifficulty
      ? oculumConditionDifficultyProfile(difficulty).periodicDamageMultiplier
      : 1.0;
  final raw = (referenceValue * (basePercent / 100) * multiplier).floor();
  final value = max(minimum, raw);
  return maximum == null ? value : min(maximum, value);
}

int oculumConditionScaledDuration({
  required int base,
  required String difficulty,
  bool scale = true,
}) {
  if (!scale || base <= 0) return max(0, base);
  return max(
    1,
    (base * oculumConditionDifficultyProfile(difficulty).durationMultiplier)
        .ceil(),
  );
}

int oculumConditionStackedEffect({
  required int baseEffect,
  required int stacks,
  required int referenceValue,
  double maximumPercentPerTick = 25,
}) {
  if (baseEffect <= 0 || stacks <= 0 || referenceValue <= 0) return 0;
  final maximum = max(
    1,
    (referenceValue * maximumPercentPerTick / 100).floor(),
  );
  return min(maximum, baseEffect * stacks);
}

int oculumDifficultyRank(String raw) {
  switch (normalizeTemporaryOculumDifficulty(raw)) {
    case 'facile':
      return 0;
    case 'difficile':
      return 2;
    case 'oculum':
      return 3;
    default:
      return 1;
  }
}

/// Positive conditions are deliberately more generous on lower character
/// difficulties. Oculum remains the catalogue baseline.
double oculumPositiveConditionMultiplier(String characterDifficulty) {
  return switch (normalizeTemporaryOculumDifficulty(characterDifficulty)) {
    'facile' => 1.50,
    'normale' => 1.25,
    'difficile' => 1.10,
    _ => 1.0,
  };
}

int oculumDifficultyIncreaseStages({
  required String characterDifficulty,
  required String enemyDifficulty,
}) {
  return max(
    0,
    oculumDifficultyRank(characterDifficulty) -
        oculumDifficultyRank(enemyDifficulty),
  );
}

int oculumDifficultyIncreaseFightPenalty(int stages) => max(0, stages) * -3;

int oculumDifficultyIncreaseIncomingDamageBonus(int damage, int stages) {
  if (damage <= 0 || stages <= 0) return 0;
  return max(1, (damage * stages * 3 / 100).floor());
}

typedef OculumConditionDurationRoll = ({
  int turns,
  String formula,
  int faces,
  bool criticalOne,
  bool criticalMax,
});

typedef OculumParsedEffectCommand = ({String name, String durationFormula});

/// Reads additive effect commands without owning condition state.
///
/// Supported examples: `@effetto:Confusione`,
/// `@effetto:Confusione(1d10+2)` and
/// `@effetto:"Nome lungo" 2d6-1 turni`.
List<OculumParsedEffectCommand> oculumParseEffectCommands(String text) {
  final matches = RegExp(
    r'@effetto\s*:\s*(?:"([^"]+)"|([^@\r\n\(]+?))'
    r'(?:\s*\(\s*([^\)]+)\s*\)|\s+(\d{0,2}d\d{1,4}(?:\s*[+-]\s*\d+)?|[+-]?\d+)\s*(?:turni|turns?)?)?'
    r'(?=\s*(?:@|[,;\r\n}\]"]|$))',
    caseSensitive: false,
  ).allMatches(text);
  return <OculumParsedEffectCommand>[
    for (final match in matches)
      if ((match.group(1) ?? match.group(2) ?? '').trim().isNotEmpty)
        (
          name: (match.group(1) ?? match.group(2) ?? '').trim(),
          durationFormula: (match.group(3) ?? match.group(4) ?? '')
              .replaceAll(' ', '')
              .trim(),
        ),
  ];
}

OculumConditionDurationRoll? oculumRollConditionDuration(
  String raw, {
  required int Function(int upperBound) nextInt,
  required int Function(int roll, int faces) criticalModifier,
}) {
  final normalized = raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s*(turni|turns?)\s*$'), '')
      .replaceAll(' ', '');
  final fixed = int.tryParse(normalized);
  if (fixed != null) {
    return (
      turns: max(0, fixed),
      formula: '',
      faces: 20,
      criticalOne: false,
      criticalMax: false,
    );
  }
  final match = RegExp(
    r'^(\d{0,2})d(\d{1,4})([+-]\d+)?$',
  ).firstMatch(normalized);
  if (match == null) return null;
  final amount = (int.tryParse(match.group(1) ?? '') ?? 1).clamp(1, 20);
  final faces = (int.tryParse(match.group(2) ?? '') ?? 0).clamp(2, 1000);
  final modifier = int.tryParse(match.group(3) ?? '') ?? 0;
  final parts = <String>[];
  var total = modifier;
  var criticalOne = false;
  var criticalMax = false;
  for (var i = 0; i < amount; i++) {
    final roll = nextInt(faces) + 1;
    final critical = criticalModifier(roll, faces);
    total += roll + critical;
    parts.add(
      '$roll${critical == 0
          ? ''
          : critical > 0
          ? '+$critical'
          : '$critical'}',
    );
    criticalOne = criticalOne || roll == 1;
    criticalMax = criticalMax || roll == faces;
  }
  final modifierLabel = modifier == 0
      ? ''
      : modifier > 0
      ? '+$modifier'
      : '$modifier';
  return (
    turns: max(0, total),
    formula: '${amount}d$faces (${parts.join(' + ')})$modifierLabel',
    faces: faces,
    criticalOne: criticalOne,
    criticalMax: criticalMax,
  );
}

class OculumDifficultyIncreaseFightProfile {
  const OculumDifficultyIncreaseFightProfile({
    required this.shieldDivisor,
    required this.usesOculumShield,
    required this.beyondDefenseChance,
    required this.beyondShieldChance,
    required this.fortunaPercent,
    required this.inspirationType,
    required this.oculumDodgeBonus,
    required this.fortunaUntilHpLoss,
  });

  final int shieldDivisor;
  final bool usesOculumShield;
  final int beyondDefenseChance;
  final int beyondShieldChance;
  final int fortunaPercent;
  final String inspirationType;
  final int oculumDodgeBonus;
  final bool fortunaUntilHpLoss;
}

OculumDifficultyIncreaseFightProfile oculumDifficultyIncreaseFightProfile(
  String difficulty,
) => switch (normalizeTemporaryOculumDifficulty(difficulty)) {
  'facile' => const OculumDifficultyIncreaseFightProfile(
    shieldDivisor: 8,
    usesOculumShield: false,
    beyondDefenseChance: 0,
    beyondShieldChance: 0,
    fortunaPercent: 6,
    inspirationType: 'base',
    oculumDodgeBonus: 0,
    fortunaUntilHpLoss: true,
  ),
  'difficile' => const OculumDifficultyIncreaseFightProfile(
    shieldDivisor: 4,
    usesOculumShield: false,
    beyondDefenseChance: 15,
    beyondShieldChance: 30,
    fortunaPercent: 10,
    inspirationType: 'super',
    oculumDodgeBonus: 0,
    fortunaUntilHpLoss: false,
  ),
  'oculum' => const OculumDifficultyIncreaseFightProfile(
    shieldDivisor: 6,
    usesOculumShield: true,
    beyondDefenseChance: 30,
    beyondShieldChance: 50,
    fortunaPercent: 15,
    inspirationType: 'oculum',
    oculumDodgeBonus: 1,
    fortunaUntilHpLoss: false,
  ),
  _ => const OculumDifficultyIncreaseFightProfile(
    shieldDivisor: 6,
    usesOculumShield: false,
    beyondDefenseChance: 5,
    beyondShieldChance: 10,
    fortunaPercent: 5,
    inspirationType: 'base',
    oculumDodgeBonus: 0,
    fortunaUntilHpLoss: false,
  ),
};

const List<OculumConditionDefinition>
oculumConditionCatalog = <OculumConditionDefinition>[
  OculumConditionDefinition(
    id: 'ricordo_vitale',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.resilienza,
      OculumConditionTarget.hp,
      OculumConditionTarget.recupero,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Ricordo Vitale',
    nameEn: 'Vital Memory',
    icon: Icons.monitor_heart_outlined,
    category: OculumConditionCategory.positive,
    polarity: OculumConditionPolarity.neutral,
    descriptionIt:
        'Subisci il 25% di danni in piu. Ogni colpo che raggiunge gli HP prepara una cura pari al 50% del danno realmente subito, ricaricata a fine turno in due quote del 25%. Un nuovo colpo sostituisce la cura residua con il nuovo Ricordo Vitale.',
    descriptionEn:
        'You take 25% more damage. Each hit that reaches HP prepares healing equal to 50% of the actual HP damage, restored at end of turn in two 25% portions. A new hit replaces the remaining healing with a new Vital Memory.',
    stackMode: OculumConditionStackMode.refreshDuration,
    defaultDuration: 0,
    durationType: OculumConditionDurationType.permanent,
    tickTrigger: OculumConditionTickTrigger.endTurn,
  ),
  OculumConditionDefinition(
    id: 'massima_potenza',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.resilienza,
      OculumConditionTarget.volonta,
      OculumConditionTarget.materia,
      OculumConditionTarget.oculum,
      OculumConditionTarget.hp,
      OculumConditionTarget.recupero,
      OculumConditionTarget.art,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Massima Potenza',
    nameEn: 'Maximum Power',
    icon: Icons.workspace_premium_outlined,
    category: OculumConditionCategory.positive,
    polarity: OculumConditionPolarity.positive,
    descriptionIt:
        'All attivazione spende una sola volta il 25% dell Oculum attuale (minimo 1) e dona lo stesso bonus temporaneo a Resilienza, Volonta e Materia per tutta la durata, piu un ulteriore +50% temporaneo a Resilienza, Volonta, Materia e Oculum. Senza Oculum, il costo diventa quattro danni HP che insieme fanno il 25% richiesto. Puoi forzare fino allo stadio VI: ogni stadio aggiuntivo ripete il costo e consuma anche il 15% dell Integrita corrente di ogni Art sbloccata (minimo 1).',
    descriptionEn:
        'On activation it spends 25% of current Oculum once (minimum 1) and grants the same temporary bonus to Resilience, Will and Matter for its whole duration, plus an additional temporary +50% to Resilience, Will, Matter and Oculum. Without Oculum, the cost becomes four HP hits whose total is the required 25%. You may force it up to stage VI: each additional stage repeats the cost and also consumes 15% of each unlocked Art current Integrity (minimum 1).',
    maxStage: 6,
    stackMode: OculumConditionStackMode.none,
    defaultDuration: 0,
    durationType: OculumConditionDurationType.permanent,
  ),
  OculumConditionDefinition(
    id: 'resilienza_in_fiamme',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.oculum,
      OculumConditionTarget.hp,
      OculumConditionTarget.recupero,
    },
    nameIt: 'Resilienza in Fiamme',
    nameEn: 'Resilience Ablaze',
    icon: Icons.local_fire_department,
    category: OculumConditionCategory.oculum,
    polarity: OculumConditionPolarity.neutral,
    descriptionIt:
        'Tre stadi: a fine turno spende 3%, 4% o 5% dell Oculum attuale (minimo 1) e cura HP pari alla spesa moltiplicata per difficolta. Agli stadi II e III ricarica anche gli HP temporanei dello stesso valore. A 15% Oculum o meno termina.',
    descriptionEn:
        'Three stages: at end of turn, spends 3%, 4% or 5% of current Oculum (minimum 1) and heals HP equal to the spent amount scaled by difficulty. At stages II and III it also restores the same amount of temporary HP. It ends at 15% Oculum or less.',
    maxStage: 3,
    stackMode: OculumConditionStackMode.increaseStage,
    basePercentByStage: <double>[3, 4, 5],
    minimumByStage: <int>[1, 1, 1],
    defaultDuration: 0,
    durationType: OculumConditionDurationType.permanent,
    tickTrigger: OculumConditionTickTrigger.endTurn,
  ),
  OculumConditionDefinition(
    id: 'oculum_in_fiamme_viola',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.hp,
      OculumConditionTarget.oculum,
      OculumConditionTarget.volonta,
      OculumConditionTarget.materia,
      OculumConditionTarget.art,
      OculumConditionTarget.recupero,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Oculum in Fiamme',
    nameEn: 'Oculum Ablaze (Violet)',
    icon: Icons.local_fire_department,
    category: OculumConditionCategory.oculum,
    polarity: OculumConditionPolarity.neutral,
    descriptionIt:
        'Tre stadi. A fine turno consuma il 3% degli HP attuali (minimo 1) e rigenera Oculum pari agli HP persi divisi per 10. Con probabilita crescente puo deviare il recupero a Volonta o Materia. Per il prossimo turno puoi scegliere di spendere il 3% di Oculum, Volonta o Materia: il recupero Oculum raddoppia e ripara della stessa quantita l Art sbloccata con meno Integrita.',
    descriptionEn:
        'Three stages. At end of turn it spends 3% of current HP (minimum 1) and regenerates Oculum equal to lost HP divided by 10. With increasing probability it can divert the recovery to Will or Matter. For the next turn you may spend 3% of Oculum, Will or Matter instead: Oculum recovery doubles and repairs the unlocked Art with the lowest Integrity by the same amount.',
    maxStage: 3,
    stackMode: OculumConditionStackMode.increaseStage,
    defaultDuration: 0,
    durationType: OculumConditionDurationType.permanent,
    tickTrigger: OculumConditionTickTrigger.endTurn,
  ),
  OculumConditionDefinition(
    id: 'volonta_in_fiamme',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.oculum,
      OculumConditionTarget.volonta,
      OculumConditionTarget.recupero,
    },
    nameIt: 'Volonta in Fiamme',
    nameEn: 'Will Ablaze',
    icon: Icons.local_fire_department,
    category: OculumConditionCategory.oculum,
    polarity: OculumConditionPolarity.neutral,
    descriptionIt:
        'Tre stadi: a fine turno spende 3%, 4% o 5% dell Oculum attuale (minimo 1), ripristina Volonta e converte l eccesso in temporanea. A 15% Oculum o meno termina.',
    descriptionEn:
        'Three stages: at end of turn, spends 3%, 4% or 5% of current Oculum (minimum 1), restores Will and converts overflow into temporary Will. It ends at 15% Oculum or less.',
    maxStage: 3,
    stackMode: OculumConditionStackMode.increaseStage,
    basePercentByStage: <double>[3, 4, 5],
    minimumByStage: <int>[1, 1, 1],
    defaultDuration: 0,
    durationType: OculumConditionDurationType.permanent,
    tickTrigger: OculumConditionTickTrigger.endTurn,
  ),
  OculumConditionDefinition(
    id: 'materia_in_fiamme',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.oculum,
      OculumConditionTarget.materia,
      OculumConditionTarget.recupero,
    },
    nameIt: 'Materia in Fiamme',
    nameEn: 'Matter Ablaze',
    icon: Icons.local_fire_department,
    category: OculumConditionCategory.oculum,
    polarity: OculumConditionPolarity.neutral,
    descriptionIt:
        'Tre stadi: a fine turno spende 3%, 4% o 5% dell Oculum attuale (minimo 1), ripristina Materia e converte l eccesso in temporanea. A 15% Oculum o meno termina.',
    descriptionEn:
        'Three stages: at end of turn, spends 3%, 4% or 5% of current Oculum (minimum 1), restores Matter and converts overflow into temporary Matter. It ends at 15% Oculum or less.',
    maxStage: 3,
    stackMode: OculumConditionStackMode.increaseStage,
    basePercentByStage: <double>[3, 4, 5],
    minimumByStage: <int>[1, 1, 1],
    defaultDuration: 0,
    durationType: OculumConditionDurationType.permanent,
    tickTrigger: OculumConditionTickTrigger.endTurn,
  ),
  OculumConditionDefinition(
    id: 'veleno_putrido',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.hp,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Veleno Putrido',
    nameEn: 'Rot Poison',
    icon: Icons.coronavirus,
    category: OculumConditionCategory.physical,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Gradi I-IX: danno e durata aumentano a ogni nuova applicazione. Cap per tick: 25% HP MAX, 49% a difficolta Oculum. Ignora Scudo e Difesa.',
    descriptionEn:
        'Ranks I-IX: damage and duration increase with every new application. Per-tick cap: 25% MAX HP, 49% on Oculum difficulty. Ignores Shield and Defense.',
    maxStage: 9,
    stackMode: OculumConditionStackMode.increaseStage,
    tickTrigger: OculumConditionTickTrigger.endTurn,
    basePercentByStage: <double>[1, 2, 4, 6, 9, 13, 18, 25, 33],
    minimumByStage: <int>[1, 1, 2, 2, 3, 4, 5, 6, 8],
    durationByStage: <int>[3, 4, 5, 6, 7, 8, 9, 10, 12],
    difficultyScaling: OculumConditionDifficultyScaling.damageAndDuration,
  ),
  OculumConditionDefinition(
    id: 'putrido',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.resilienza,
      OculumConditionTarget.volonta,
      OculumConditionTarget.materia,
      OculumConditionTarget.oculum,
      OculumConditionTarget.tiri,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Putrido',
    nameEn: 'Rot',
    icon: Icons.bug_report,
    category: OculumConditionCategory.physical,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Decomposizione progressiva: malus contestuale ai tiri normali.',
    descriptionEn: 'Progressive decay: contextual penalty to normal rolls.',
    maxStage: 5,
    stackMode: OculumConditionStackMode.increaseStage,
    tickTrigger: OculumConditionTickTrigger.startTurn,
    rollModifierByStage: <int>[-2, -3, -4, -5, -6],
    difficultyScaling: OculumConditionDifficultyScaling.recovery,
  ),
  OculumConditionDefinition(
    id: 'sanguinamento',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.hp,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Sanguinamento',
    nameEn: 'Bleeding',
    icon: Icons.bloodtype,
    category: OculumConditionCategory.physical,
    polarity: OculumConditionPolarity.negative,
    descriptionIt: 'Perdita progressiva di HP a fine turno.',
    descriptionEn: 'Progressive HP loss at end of turn.',
    maxStage: 4,
    stackMode: OculumConditionStackMode.increaseStage,
    tickTrigger: OculumConditionTickTrigger.endTurn,
    basePercentByStage: <double>[1, 2, 4, 6],
    minimumByStage: <int>[1, 1, 2, 2],
    difficultyScaling: OculumConditionDifficultyScaling.damage,
  ),
  OculumConditionDefinition(
    id: 'bruciatura',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.hp,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Bruciatura',
    nameEn: 'Burning',
    icon: Icons.local_fire_department,
    category: OculumConditionCategory.elemental,
    polarity: OculumConditionPolarity.negative,
    descriptionIt: 'Danno da fuoco progressivo a fine turno.',
    descriptionEn: 'Progressive fire damage at end of turn.',
    maxStage: 3,
    stackMode: OculumConditionStackMode.increaseStage,
    tickTrigger: OculumConditionTickTrigger.endTurn,
    basePercentByStage: <double>[1, 2, 4],
    minimumByStage: <int>[1, 1, 2],
    difficultyScaling: OculumConditionDifficultyScaling.damage,
    contextActionIt: 'Spegni',
    contextActionEn: 'Extinguish',
  ),
  OculumConditionDefinition(
    id: 'avvelenato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.resilienza,
      OculumConditionTarget.movimento,
      OculumConditionTarget.tiri,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Avvelenato',
    nameEn: 'Poisoned',
    icon: Icons.science,
    category: OculumConditionCategory.physical,
    polarity: OculumConditionPolarity.negative,
    descriptionIt: 'Malus ai tiri fisici; non causa danno automatico.',
    descriptionEn: 'Penalty to physical rolls; no automatic damage.',
    maxStage: 3,
    stackMode: OculumConditionStackMode.increaseStage,
    rollModifierByStage: <int>[-2, -4, -6],
    difficultyScaling: OculumConditionDifficultyScaling.duration,
  ),
  OculumConditionDefinition(
    id: 'gelo',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.movimento,
      OculumConditionTarget.recupero,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Gelo',
    nameEn: 'Frost',
    icon: Icons.ac_unit,
    category: OculumConditionCategory.elemental,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Movimento -10%/-25%/-50%/0. Ibernato richiede una nuova applicazione a Congelato.',
    descriptionEn:
        'Movement -10%/-25%/-50%/0. Hibernation requires another application while Frozen.',
    maxStage: 4,
    stackMode: OculumConditionStackMode.increaseStage,
    difficultyScaling: OculumConditionDifficultyScaling.recovery,
    control: true,
  ),
  OculumConditionDefinition(
    id: 'rallentato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.movimento,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Rallentato',
    nameEn: 'Slowed',
    icon: Icons.slow_motion_video,
    category: OculumConditionCategory.physical,
    polarity: OculumConditionPolarity.negative,
    descriptionIt: 'Movimento -25%.',
    descriptionEn: 'Movement -25%.',
  ),
  OculumConditionDefinition(
    id: 'stordito',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.resilienza,
      OculumConditionTarget.volonta,
      OculumConditionTarget.materia,
      OculumConditionTarget.oculum,
      OculumConditionTarget.tiri,
      OculumConditionTarget.reazioni,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Stordito',
    nameEn: 'Stunned',
    icon: Icons.flash_on,
    category: OculumConditionCategory.special,
    polarity: OculumConditionPolarity.negative,
    descriptionIt: 'Perdi 1 Reazione e -3 al prossimo tiro valido.',
    descriptionEn: 'Lose 1 Reaction and -3 to the next valid roll.',
    rollModifierByStage: <int>[-3],
    defaultDuration: 1,
    control: true,
  ),
  OculumConditionDefinition(
    id: 'accecato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.tiri,
      OculumConditionTarget.skill,
      OculumConditionTarget.art,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Accecato',
    nameEn: 'Blinded',
    icon: Icons.visibility_off,
    category: OculumConditionCategory.physical,
    polarity: OculumConditionPolarity.negative,
    descriptionIt: '-3 alle azioni che richiedono realmente la vista.',
    descriptionEn: '-3 to actions that truly require sight.',
  ),
  OculumConditionDefinition(
    id: 'assordato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.tiri,
      OculumConditionTarget.skill,
      OculumConditionTarget.art,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Assordato',
    nameEn: 'Deafened',
    icon: Icons.hearing_disabled,
    category: OculumConditionCategory.physical,
    polarity: OculumConditionPolarity.negative,
    descriptionIt: '-3 alle prove basate principalmente sull udito.',
    descriptionEn: '-3 to checks based mainly on hearing.',
  ),
  OculumConditionDefinition(
    id: 'frattura',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.resilienza,
      OculumConditionTarget.movimento,
      OculumConditionTarget.tiri,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Frattura',
    nameEn: 'Fracture',
    icon: Icons.personal_injury,
    category: OculumConditionCategory.physical,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        '-3 alle azioni compromesse dalla parte fratturata. Richiede cura appropriata.',
    descriptionEn:
        '-3 to actions impaired by the fractured body part. Requires proper treatment.',
    durationType: OculumConditionDurationType.permanent,
    removable: false,
  ),
  OculumConditionDefinition(
    id: 'esposto',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.hp,
      OculumConditionTarget.difesa,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Esposto',
    nameEn: 'Exposed',
    icon: Icons.gps_fixed,
    category: OculumConditionCategory.special,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Il prossimo danno ricevuto aumenta del 20% (min +1), poi Esposto termina.',
    descriptionEn:
        'Next incoming damage increases by 20% (min +1), then Exposed ends.',
    tickTrigger: OculumConditionTickTrigger.damageReceived,
  ),
  OculumConditionDefinition(
    id: 'indebolito',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.danno,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Indebolito',
    nameEn: 'Weakened',
    icon: Icons.trending_down,
    category: OculumConditionCategory.special,
    polarity: OculumConditionPolarity.negative,
    descriptionIt: 'Danno inflitto -20% (min -1).',
    descriptionEn: 'Damage dealt -20% (min -1).',
  ),
  OculumConditionDefinition(
    id: 'vulnerabile',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.hp,
      OculumConditionTarget.difesa,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Vulnerabile',
    nameEn: 'Vulnerable',
    icon: Icons.heart_broken,
    category: OculumConditionCategory.special,
    polarity: OculumConditionPolarity.negative,
    descriptionIt: 'Danno ricevuto +20% (min +1).',
    descriptionEn: 'Damage received +20% (min +1).',
  ),
  OculumConditionDefinition(
    id: 'paura',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.volonta,
      OculumConditionTarget.tiri,
      OculumConditionTarget.skill,
      OculumConditionTarget.art,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Paura',
    nameEn: 'Fear',
    icon: Icons.sentiment_very_dissatisfied,
    category: OculumConditionCategory.mental,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Malus contro la fonte; il giocatore mantiene sempre il controllo.',
    descriptionEn:
        'Penalty against the source; the player always retains control.',
    maxStage: 4,
    stackMode: OculumConditionStackMode.increaseStage,
    rollModifierByStage: <int>[-2, -4, -6, -8],
    control: true,
  ),
  OculumConditionDefinition(
    id: 'confusione',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.materia,
      OculumConditionTarget.oculum,
      OculumConditionTarget.tiri,
      OculumConditionTarget.skill,
      OculumConditionTarget.art,
    },
    nameIt: 'Confusione',
    nameEn: 'Confusion',
    icon: Icons.psychology_alt,
    category: OculumConditionCategory.mental,
    polarity: OculumConditionPolarity.negative,
    descriptionIt: 'Malus alle azioni mentali complesse, senza azioni casuali.',
    descriptionEn: 'Penalty to complex mental actions, without random actions.',
    maxStage: 3,
    stackMode: OculumConditionStackMode.increaseStage,
    rollModifierByStage: <int>[-2, -4, -6],
  ),
  OculumConditionDefinition(
    id: 'silenziato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.skill,
      OculumConditionTarget.art,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Silenziato',
    nameEn: 'Silenced',
    icon: Icons.volume_off,
    category: OculumConditionCategory.special,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Blocca solo capacita che richiedono esplicitamente voce, canto, suono o parola.',
    descriptionEn:
        'Blocks only abilities explicitly requiring voice, song, sound or speech.',
  ),
  OculumConditionDefinition(
    id: 'immobilizzato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.movimento,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Immobilizzato',
    nameEn: 'Immobilized',
    icon: Icons.link,
    category: OculumConditionCategory.physical,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Movimento 0; non blocca altre azioni logicamente possibili.',
    descriptionEn:
        'Movement 0; does not block other logically possible actions.',
    control: true,
  ),
  OculumConditionDefinition(
    id: 'esaurimento',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.resilienza,
      OculumConditionTarget.volonta,
      OculumConditionTarget.materia,
      OculumConditionTarget.oculum,
      OculumConditionTarget.movimento,
      OculumConditionTarget.tiri,
      OculumConditionTarget.recupero,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Esaurimento',
    nameEn: 'Exhaustion',
    icon: Icons.battery_0_bar,
    category: OculumConditionCategory.physical,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Condizione lenta e persistente, curata principalmente tramite Riposo.',
    descriptionEn: 'Slow persistent condition, treated mainly through Rest.',
    maxStage: 5,
    stackMode: OculumConditionStackMode.increaseStage,
    removable: false,
    rollModifierByStage: <int>[-2, -3, -4, -5, -6],
    difficultyScaling: OculumConditionDifficultyScaling.recovery,
  ),
  OculumConditionDefinition(
    id: 'oculum_instabile',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.oculum,
      OculumConditionTarget.tiri,
      OculumConditionTarget.skill,
      OculumConditionTarget.art,
    },
    nameIt: 'Oculum Instabile',
    nameEn: 'Unstable Oculum',
    icon: Icons.remove_red_eye,
    category: OculumConditionCategory.oculum,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Instabilita 5%/10%/15%/20%; usa un hook centrale senza conseguenze permanenti inventate.',
    descriptionEn:
        'Instability 5%/10%/15%/20%; uses a central hook without invented permanent consequences.',
    maxStage: 4,
    stackMode: OculumConditionStackMode.increaseStage,
    tickTrigger: OculumConditionTickTrigger.roll,
  ),
  OculumConditionDefinition(
    id: 'oculum_sigillato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.oculum,
      OculumConditionTarget.skill,
      OculumConditionTarget.art,
    },
    nameIt: 'Oculum Sigillato',
    nameEn: 'Sealed Oculum',
    icon: Icons.block,
    category: OculumConditionCategory.oculum,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Impedisce di spendere Oculum senza azzerare quello posseduto.',
    descriptionEn: 'Prevents spending Oculum without clearing held Oculum.',
  ),
  OculumConditionDefinition(
    id: 'vuoto',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.oculum,
      OculumConditionTarget.recupero,
    },
    nameIt: 'Vuoto',
    nameEn: 'Void',
    icon: Icons.trip_origin,
    category: OculumConditionCategory.oculum,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Impedisce di recuperare Oculum; non impedisce di spenderlo.',
    descriptionEn: 'Prevents Oculum recovery; does not prevent spending it.',
  ),
  OculumConditionDefinition(
    id: 'oculum_affamato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.oculum,
      OculumConditionTarget.skill,
      OculumConditionTarget.art,
    },
    nameIt: 'Oculum Affamato',
    nameEn: 'Hungry Oculum',
    icon: Icons.restaurant,
    category: OculumConditionCategory.oculum,
    polarity: OculumConditionPolarity.negative,
    descriptionIt: 'Costo Skill +10%/+20%/+30% con minimo +1/+1/+2.',
    descriptionEn: 'Skill cost +10%/+20%/+30% with minimum +1/+1/+2.',
    maxStage: 3,
    stackMode: OculumConditionStackMode.increaseStage,
  ),
  OculumConditionDefinition(
    id: 'sovraccarico',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.oculum,
      OculumConditionTarget.skill,
      OculumConditionTarget.art,
    },
    nameIt: 'Sovraccarico',
    nameEn: 'Overload',
    icon: Icons.bolt,
    category: OculumConditionCategory.oculum,
    polarity: OculumConditionPolarity.neutral,
    descriptionIt:
        'Struttura progressiva predisposta; non modifica le regole di overcap esistenti.',
    descriptionEn:
        'Prepared progressive structure; does not alter existing overcap rules.',
    maxStage: 4,
    stackMode: OculumConditionStackMode.increaseStage,
  ),
  OculumConditionDefinition(
    id: 'corroso',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.difesa,
      OculumConditionTarget.scudo,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Corroso',
    nameEn: 'Corroded',
    icon: Icons.water_drop_outlined,
    category: OculumConditionCategory.elemental,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Tre stadi: Difesa -10%/-20%/-30% e i danni consumano la stessa percentuale di Scudo aggiuntiva. Si rimuove con riparazione o trattamento appropriato.',
    descriptionEn:
        'Three stages: Defense -10%/-20%/-30% and damage consumes the same additional Shield percentage. Removed by proper repair or treatment.',
    maxStage: 3,
    stackMode: OculumConditionStackMode.increaseStage,
    defaultDuration: 4,
    durationType: OculumConditionDurationType.turns,
    tickTrigger: OculumConditionTickTrigger.endTurn,
  ),
  OculumConditionDefinition(
    id: 'rinsecchito',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.difesa,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Rinsecchito',
    nameEn: 'Desiccated',
    icon: Icons.dry,
    category: OculumConditionCategory.physical,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'La Difesa si riduce del 75%: resta disponibile soltanto un quarto del suo valore normale.',
    descriptionEn:
        'Defense is reduced by 75%: only one quarter of its normal value remains.',
    stackMode: OculumConditionStackMode.refreshDuration,
    defaultDuration: 3,
    durationType: OculumConditionDurationType.turns,
    tickTrigger: OculumConditionTickTrigger.endTurn,
    basePercentByStage: <double>[75],
  ),
  OculumConditionDefinition(
    id: 'bagnato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.movimento,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Bagnato',
    nameEn: 'Wet',
    icon: Icons.water,
    category: OculumConditionCategory.elemental,
    polarity: OculumConditionPolarity.neutral,
    descriptionIt:
        'Spegne Bruciatura. La prossima applicazione di Gelo avanza di uno stadio aggiuntivo; Elettrizzato mantiene il suo danno del 3%.',
    descriptionEn:
        'Extinguishes Burning. The next Frost application advances one additional stage; Electrified keeps its 3% damage.',
    stackMode: OculumConditionStackMode.refreshDuration,
    defaultDuration: 3,
    durationType: OculumConditionDurationType.turns,
    tickTrigger: OculumConditionTickTrigger.endTurn,
  ),
  OculumConditionDefinition(
    id: 'elettrizzato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.hp,
      OculumConditionTarget.iniziativa,
      OculumConditionTarget.recupero,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Elettrizzato',
    nameEn: 'Electrified',
    icon: Icons.electric_bolt,
    category: OculumConditionCategory.elemental,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'A fine turno infligge danni diretti pari al 3% degli HP massimi (minimo 1), riduce Iniziativa di 3 e impedisce le cure di Ricordo Vitale finche resta attivo.',
    descriptionEn:
        'At end of turn it deals direct damage equal to 3% maximum HP (minimum 1), reduces Initiative by 3 and prevents Vital Memory healing while active.',
    stackMode: OculumConditionStackMode.refreshDuration,
    defaultDuration: 3,
    durationType: OculumConditionDurationType.turns,
    tickTrigger: OculumConditionTickTrigger.endTurn,
  ),
  OculumConditionDefinition(
    id: 'maledetto',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.hp,
      OculumConditionTarget.recupero,
    },
    nameIt: 'Maledetto',
    nameEn: 'Cursed',
    icon: Icons.auto_fix_off,
    category: OculumConditionCategory.mental,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Tre stadi: tutte le cure HP ricevute sono ridotte del 20%/35%/50%.',
    descriptionEn:
        'Three stages: all received HP healing is reduced by 20%/35%/50%.',
    maxStage: 3,
    stackMode: OculumConditionStackMode.increaseStage,
    defaultDuration: 4,
    durationType: OculumConditionDurationType.turns,
    tickTrigger: OculumConditionTickTrigger.endTurn,
  ),
  OculumConditionDefinition(
    id: 'marchiato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.difesa,
      OculumConditionTarget.hp,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Marchiato',
    nameEn: 'Marked',
    icon: Icons.my_location,
    category: OculumConditionCategory.special,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Riduce del 20% la Difesa del bersaglio. Il Marchio viene consumato dal prossimo danno ricevuto.',
    descriptionEn:
        'Reduces the target Defense by 20%. The Mark is consumed by the next incoming damage.',
    stackMode: OculumConditionStackMode.refreshDuration,
    defaultDuration: 3,
    durationType: OculumConditionDurationType.turns,
    tickTrigger: OculumConditionTickTrigger.endTurn,
  ),
  OculumConditionDefinition(
    id: 'interferenza',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.tiri,
      OculumConditionTarget.skill,
      OculumConditionTarget.art,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Interferenza',
    nameEn: 'Interference',
    icon: Icons.waves,
    category: OculumConditionCategory.oculum,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Tre stadi: disturba Skill e Art e applica -2/-4/-6 ai tiri senza bloccarne l uso.',
    descriptionEn:
        'Three stages: disrupts Skills and Arts and applies -2/-4/-6 to rolls without blocking their use.',
    maxStage: 3,
    stackMode: OculumConditionStackMode.increaseStage,
    rollModifierByStage: <int>[-2, -4, -6],
    defaultDuration: 3,
    durationType: OculumConditionDurationType.turns,
    tickTrigger: OculumConditionTickTrigger.endTurn,
  ),
  OculumConditionDefinition(
    id: 'rigenerazione',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.hp,
      OculumConditionTarget.recupero,
    },
    nameIt: 'Rigenerazione',
    nameEn: 'Regeneration',
    icon: Icons.healing,
    category: OculumConditionCategory.positive,
    polarity: OculumConditionPolarity.positive,
    descriptionIt:
        'Tre stadi: a fine turno cura il 3%/5%/8% degli HP massimi (minimo 1). La cura e ridotta da Maledetto.',
    descriptionEn:
        'Three stages: at end of turn heals 3%/5%/8% maximum HP (minimum 1). Healing is reduced by Cursed.',
    maxStage: 3,
    stackMode: OculumConditionStackMode.increaseStage,
    basePercentByStage: <double>[3, 5, 8],
    minimumByStage: <int>[1, 1, 1],
    defaultDuration: 3,
    durationType: OculumConditionDurationType.turns,
    tickTrigger: OculumConditionTickTrigger.endTurn,
  ),
  OculumConditionDefinition(
    id: 'barriera_mentale',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.volonta,
      OculumConditionTarget.tiri,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Barriera Mentale',
    nameEn: 'Mental Barrier',
    icon: Icons.psychology,
    category: OculumConditionCategory.positive,
    polarity: OculumConditionPolarity.positive,
    descriptionIt:
        'Annulla la prossima condizione mentale negativa applicata, poi termina.',
    descriptionEn:
        'Negates the next negative mental condition applied, then ends.',
    stackMode: OculumConditionStackMode.refreshDuration,
    defaultDuration: 3,
    durationType: OculumConditionDurationType.turns,
    tickTrigger: OculumConditionTickTrigger.endTurn,
  ),
  OculumConditionDefinition(
    id: 'ancorato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.movimento,
      OculumConditionTarget.difesa,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Ancorato',
    nameEn: 'Anchored',
    icon: Icons.anchor,
    category: OculumConditionCategory.positive,
    polarity: OculumConditionPolarity.positive,
    descriptionIt:
        'Non puo essere Afferrato o Atterrato e non puo essere spostato forzatamente; Movimento -25%.',
    descriptionEn:
        'Cannot be Grappled, knocked Prone or forcibly moved; Movement -25%.',
    stackMode: OculumConditionStackMode.refreshDuration,
    defaultDuration: 3,
    durationType: OculumConditionDurationType.turns,
    tickTrigger: OculumConditionTickTrigger.endTurn,
  ),
  OculumConditionDefinition(
    id: 'fortificato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.difesa,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Fortificato',
    nameEn: 'Fortified',
    icon: Icons.shield,
    category: OculumConditionCategory.positive,
    polarity: OculumConditionPolarity.positive,
    descriptionIt: 'Difesa +15% (min +1).',
    descriptionEn: 'Defense +15% (min +1).',
  ),
  OculumConditionDefinition(
    id: 'accelerato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.movimento,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Accelerato',
    nameEn: 'Hastened',
    icon: Icons.speed,
    category: OculumConditionCategory.positive,
    polarity: OculumConditionPolarity.positive,
    descriptionIt: 'Movimento +20%.',
    descriptionEn: 'Movement +20%.',
  ),
  OculumConditionDefinition(
    id: 'concentrato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.tiri,
      OculumConditionTarget.skill,
      OculumConditionTarget.art,
    },
    nameIt: 'Concentrato',
    nameEn: 'Focused',
    icon: Icons.center_focus_strong,
    category: OculumConditionCategory.positive,
    polarity: OculumConditionPolarity.positive,
    descriptionIt: '+1 al tipo di tiro specificato dalla fonte.',
    descriptionEn: '+1 to the roll type specified by the source.',
  ),
  OculumConditionDefinition(
    id: 'potenziato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.danno,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Potenziato',
    nameEn: 'Empowered',
    icon: Icons.fitness_center,
    category: OculumConditionCategory.positive,
    polarity: OculumConditionPolarity.positive,
    descriptionIt: 'Danno +15% (min +1).',
    descriptionEn: 'Damage +15% (min +1).',
  ),
  OculumConditionDefinition(
    id: 'vigile',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.iniziativa,
      OculumConditionTarget.tiri,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Vigile',
    nameEn: 'Alert',
    icon: Icons.visibility,
    category: OculumConditionCategory.positive,
    polarity: OculumConditionPolarity.positive,
    descriptionIt: '+1 alle prove appropriate di Percezione.',
    descriptionEn: '+1 to appropriate Perception checks.',
  ),
  OculumConditionDefinition(
    id: 'atterrato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.movimento,
      OculumConditionTarget.difesa,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Atterrato',
    nameEn: 'Prone',
    icon: Icons.airline_seat_flat,
    category: OculumConditionCategory.physical,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Il personaggio e a terra e deve rialzarsi con movimento o azione appropriata.',
    descriptionEn:
        'The character is prone and must stand with appropriate movement or action.',
  ),
  OculumConditionDefinition(
    id: 'afferrato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.movimento,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Afferrato',
    nameEn: 'Grappled',
    icon: Icons.pan_tool,
    category: OculumConditionCategory.physical,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Non puoi allontanarti normalmente dalla fonte; puoi tentare di liberarti.',
    descriptionEn:
        'You cannot normally move away from the source; you may try to escape.',
  ),
  OculumConditionDefinition(
    id: 'disarmato',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.danno,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Disarmato',
    nameEn: 'Disarmed',
    icon: Icons.back_hand,
    category: OculumConditionCategory.physical,
    polarity: OculumConditionPolarity.negative,
    descriptionIt: 'L arma impugnata viene persa dalla mano.',
    descriptionEn: 'The held weapon is lost from the hand.',
  ),
  OculumConditionDefinition(
    id: 'nascosto',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.iniziativa,
      OculumConditionTarget.skill,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Nascosto',
    nameEn: 'Hidden',
    icon: Icons.hide_source,
    category: OculumConditionCategory.positive,
    polarity: OculumConditionPolarity.positive,
    descriptionIt: 'Il personaggio non e automaticamente individuabile.',
    descriptionEn: 'The character is not automatically detected.',
  ),
  OculumConditionDefinition(
    id: 'invisibile',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.difesa,
      OculumConditionTarget.skill,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Invisibile',
    nameEn: 'Invisible',
    icon: Icons.visibility_off,
    category: OculumConditionCategory.positive,
    polarity: OculumConditionPolarity.positive,
    descriptionIt:
        'Non equivale a invulnerabile: rumori, tracce e sensi alternativi possono rivelare.',
    descriptionEn:
        'Not invulnerability: noise, tracks and alternative senses may reveal.',
  ),
  OculumConditionDefinition(
    id: 'privo_reazioni',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.reazioni,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Privo di Reazioni',
    nameEn: 'No Reactions',
    icon: Icons.timer_off,
    category: OculumConditionCategory.special,
    polarity: OculumConditionPolarity.negative,
    descriptionIt: 'Reazioni disponibili 0 per la durata prevista.',
    descriptionEn: 'Available Reactions are 0 for the stated duration.',
    control: true,
  ),
  OculumConditionDefinition(
    id: 'vita_afona',
    affectedTargets: <OculumConditionTarget>{OculumConditionTarget.hp},
    nameIt: 'Vita Afona',
    nameEn: 'Voiceless Life',
    icon: Icons.warning_rounded,
    category: OculumConditionCategory.mental,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'Non puoi conoscere i tuoi HP attuali: la barra Vita diventa nera e mostra soltanto un teschio. Dura 1 turno Facile, 3 Medio, 4 Difficile, 5 Oculum; termina anche se muori o viene rimossa.',
    descriptionEn:
        'You cannot know your current HP: the health bar turns black and shows only a skull. It lasts 1 turn Easy, 3 Normal, 4 Hard, 5 Oculum; it also ends on death or removal.',
    stackMode: OculumConditionStackMode.refreshDuration,
    defaultDuration: 3,
    durationType: OculumConditionDurationType.turns,
    tickTrigger: OculumConditionTickTrigger.endTurn,
  ),
  OculumConditionDefinition(
    id: 'aumento_difficolta',
    affectedTargets: <OculumConditionTarget>{
      OculumConditionTarget.hp,
      OculumConditionTarget.difesa,
      OculumConditionTarget.vc,
      OculumConditionTarget.cm,
      OculumConditionTarget.tiri,
      OculumConditionTarget.scudo,
      OculumConditionTarget.scudoOculum,
      OculumConditionTarget.combattimento,
    },
    nameIt: 'Aumento difficolta',
    nameEn: 'Difficulty increase',
    icon: Icons.trending_up,
    category: OculumConditionCategory.special,
    polarity: OculumConditionPolarity.negative,
    descriptionIt:
        'In Fight: +3% danni ricevuti e -3 VC/-3 CM per ogni livello di differenza. La modalita del personaggio determina Oltre Difesa/Scudo e il pacchetto Scudo, Fortuna, Ispirazione e Schivata.',
    descriptionEn:
        'In Fight: +3% incoming damage and -3 VC/-3 CM per difference level. Character mode determines Beyond Defense/Shield and the Shield, Luck, Inspiration and Dodge package.',
    maxStage: 3,
    stackMode: OculumConditionStackMode.replaceIfStronger,
    durationType: OculumConditionDurationType.turns,
    tickTrigger: OculumConditionTickTrigger.endTurn,
    defaultDuration: 0,
    difficultyScaling: OculumConditionDifficultyScaling.custom,
  ),
];

OculumConditionDefinition? oculumConditionDefinition(String id) {
  for (final definition in oculumConditionCatalog) {
    if (definition.id == id) return definition;
  }
  return null;
}

/// Conversione per le tre condizioni "in Fiamme". Il livello Oculum e la
/// difficolta piu severa riducono il ritorno del sacrificio.
double oculumFlameRewardMultiplier(String difficulty) {
  switch (normalizeTemporaryOculumDifficulty(difficulty)) {
    case 'facile':
      return 2;
    case 'difficile':
      return 1.3;
    case 'oculum':
      return 1;
    case 'normale':
    default:
      return 1.5;
  }
}

double oculumFlameTurnPercent(int stage) =>
    const <double>[3, 4, 5][(stage.clamp(1, 3)) - 1];

int oculumFlameTurnCost(int currentOculum, {int stage = 1}) {
  if (currentOculum <= 0) return 0;
  return max(1, (currentOculum * oculumFlameTurnPercent(stage) / 100).floor());
}

int oculumVioletFlameThreePercentCost(int current) {
  if (current <= 0) return 0;
  return max(1, (current * .03).floor());
}

int oculumVioletFlameRegeneration(int lostHp) {
  if (lostHp <= 0) return 0;
  return max(1, lostHp ~/ 10);
}

int oculumVioletFlameDiversionChance(int stage) =>
    const <int>[10, 20, 30][(stage.clamp(1, 3)) - 1];

int oculumMaximumPowerOculumCost(int currentOculum) {
  if (currentOculum <= 0) return 0;
  return max(1, (currentOculum * .25).floor());
}

List<int> oculumMaximumPowerHpFallbackHits(int currentHp) {
  if (currentHp <= 0) return const <int>[0, 0, 0, 0];
  final total = max(1, (currentHp * .25).floor());
  final base = total ~/ 4;
  final remainder = total % 4;
  return List<int>.generate(
    4,
    (index) => base + (index < remainder ? 1 : 0),
    growable: false,
  );
}

int oculumMaximumPowerIntegrityCost(int currentIntegrity) {
  if (currentIntegrity <= 0) return 0;
  return max(1, (currentIntegrity * .15).floor());
}

bool oculumFlameEndsAtLowOculum({
  required int currentOculum,
  required int maximumOculum,
}) => currentOculum <= (max(0, maximumOculum) * .15).floor();

int oculumFlameReward(int oculumSpent, String difficulty) {
  if (oculumSpent <= 0) return 0;
  return max(
    1,
    (oculumSpent * oculumFlameRewardMultiplier(difficulty)).round(),
  );
}

int oculumVitalMemoryIncomingDamage(int damage) {
  if (damage <= 0) return 0;
  return damage + max(1, (damage * .25).ceil());
}

({int total, int perTick}) oculumVitalMemoryRecoveryForDamage(int hpDamage) {
  if (hpDamage <= 0) return (total: 0, perTick: 0);
  // Ricordo Vitale never recovers the condition's 25% incoming-damage cost.
  final recoverableBaseDamage = (hpDamage / 1.25).floor();
  return (
    total: max(0, (recoverableBaseDamage * .5).ceil()),
    perTick: max(0, (recoverableBaseDamage * .25).ceil()),
  );
}

int oculumPercentOfMaximum(int maximum, double percent) {
  if (maximum <= 0 || percent <= 0) return 0;
  return max(1, (maximum * percent / 100).floor());
}

int oculumElectrifiedDamage(int maximumHp) =>
    oculumPercentOfMaximum(maximumHp, 3);

int oculumRegenerationHealing(int maximumHp, int stage) {
  final percent = const <double>[3, 5, 8][(stage.clamp(1, 3)) - 1];
  return oculumPercentOfMaximum(maximumHp, percent);
}

int oculumCursedHealing(int requested, int stage) {
  if (requested <= 0) return 0;
  final reduction = const <int>[20, 35, 50][(stage.clamp(1, 3)) - 1];
  return max(0, (requested * (100 - reduction) / 100).floor());
}

int oculumCorrosionPercent(int stage) =>
    const <int>[10, 20, 30][(stage.clamp(1, 3)) - 1];

String oculumRomanStage(int stage) => const <String>[
  'I',
  'II',
  'III',
  'IV',
  'V',
  'VI',
  'VII',
  'VIII',
  'IX',
][(stage.clamp(1, 9)) - 1];
