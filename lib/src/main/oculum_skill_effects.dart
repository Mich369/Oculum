part of '../../main.dart';

/// Tipi base disponibili nell'editor guidato di Skill e Art.
///
/// Le stringhe sono intenzionalmente stabili: fanno parte del JSON additivo e
/// non dipendono dalla lingua visualizzata nell'interfaccia.
const List<String> oculumStructuredEffectTypes = <String>[
  'danno',
  'difesa',
  'cura',
  'modifica_statistica',
  'modifica_sottotratto',
  'velocita',
  'forza',
  'scudo',
  'hp_temporanei',
  'rimuovi_vita',
  'rimuovi_oculum',
  'rimuovi_azioni',
  'rimuovi_reazioni',
  'rimuovi_reazioni_rapide',
  'aggiungi_reazioni',
  'aggiungi_reazioni_rapide',
  'consumo_risorsa',
  'stato',
];

/// Solo queste chiavi possono rappresentare un costo strutturato.
///
/// I sottotratti non sono inclusi e [oculumIsConsumableEffectResource] non
/// accetta mai una chiave dinamica proveniente da un sottotratto.
const List<String> oculumEffectConsumableResourceKeys = <String>[
  'oculum',
  'vita',
  'azioni',
  'reazioni',
  'reazioni_rapide',
  'utilizzi_skill',
  'materia',
  'volonta',
  'resilienza',
  'nessuna',
];

int oculumAutomaticAshFreeTurns(int level) {
  return 6 + (max(0, level) ~/ 6) * 2;
}

int oculumAutomaticAshChancePercent({
  required int turn,
  required String difficulty,
  int level = 0,
  bool underStress = false,
}) {
  final freeTurns = oculumAutomaticAshFreeTurns(level);
  if (turn <= freeTurns) return 0;
  final step = turn - freeTurns - 1;
  final normalized = normalizeTemporaryOculumDifficulty(difficulty);
  final (base, increase, cap) = switch (normalized) {
    'facile' => (5, 5, 50),
    'difficile' => (15, 10, 90),
    'oculum' => (20, 12, 100),
    _ => (10, 7, 70),
  };
  return min(100, min(cap, base + step * increase) + (underStress ? 15 : 0));
}

const int oculumUnderStressAshChanceBonus = 15;
const int oculumArtIntegrityBreakAshChancePercent = 50;

class OculumStressConsumptionResult {
  const OculumStressConsumptionResult({
    required this.awards,
    required this.remainder,
  });

  final int awards;
  final int remainder;
}

OculumStressConsumptionResult oculumStressConsumptionProgress({
  required int current,
  required int consumed,
  required int level,
  required bool underStress,
}) {
  if (!underStress || consumed <= 0) {
    return OculumStressConsumptionResult(awards: 0, remainder: max(0, current));
  }
  final threshold = max(1, level + 1);
  final total = max(0, current) + consumed;
  return OculumStressConsumptionResult(
    awards: total ~/ threshold,
    remainder: total % threshold,
  );
}

List<int> oculumCrossedHpQuarterThresholds({
  required int before,
  required int after,
  required int maximum,
}) {
  if (maximum <= 0 || after >= before) return const <int>[];
  final beforePercent = (before.clamp(0, maximum) * 100) / maximum;
  final afterPercent = (after.clamp(0, maximum) * 100) / maximum;
  return <int>[
    for (final threshold in const <int>[75, 50, 25, 0])
      if (beforePercent > threshold && afterPercent <= threshold) threshold,
  ];
}

int oculumHpLossAshChancePercent({
  required int remainingPercent,
  required String difficulty,
  bool underStress = false,
}) {
  final normalized = normalizeTemporaryOculumDifficulty(difficulty);
  final base = switch (normalized) {
    'facile' => 5,
    'difficile' => 20,
    'oculum' => 30,
    _ => 10,
  };
  final safeRemaining = remainingPercent.clamp(0, 75);
  final severityBonus = ((75 - safeRemaining) ~/ 25) * 10;
  return min(
    100,
    base + severityBonus + (underStress ? oculumUnderStressAshChanceBonus : 0),
  );
}

class OculumAbilityCooldown {
  OculumAbilityCooldown({
    this.amount = 0,
    this.unit = 'turni',
    this.startsReady = true,
    int? remaining,
  }) : remaining = max(0, remaining ?? (startsReady ? 0 : amount));

  int amount;
  String unit;
  bool startsReady;
  int remaining;

  bool get ready => remaining <= 0;

  bool activate() {
    if (!ready) return false;
    remaining = max(0, amount);
    return true;
  }

  bool tick(String eventUnit) {
    if (remaining <= 0 ||
        oculumNormalizeText(eventUnit) != oculumNormalizeText(unit)) {
      return false;
    }
    remaining = max(0, remaining - 1);
    return true;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'amount': amount,
    'unit': unit,
    'startsReady': startsReady,
    'remaining': remaining,
  };

  factory OculumAbilityCooldown.fromJson(Map<String, dynamic> json) {
    return OculumAbilityCooldown(
      amount: max(0, readIntValue(json['amount'] ?? json['durata'])),
      unit: '${json['unit'] ?? json['unita'] ?? 'turni'}',
      startsReady: readBoolValue(
        json['startsReady'] ?? json['parteCarico'],
        fallback: true,
      ),
      remaining: json.containsKey('remaining') || json.containsKey('rimanente')
          ? max(0, readIntValue(json['remaining'] ?? json['rimanente']))
          : null,
    );
  }
}

List<OculumAbilityCooldown> oculumNormalizeCooldownsPerLevel(
  Iterable<OculumAbilityCooldown>? values,
) {
  final source = values?.toList(growable: false) ?? const [];
  return List<OculumAbilityCooldown>.generate(
    5,
    (index) => index < source.length
        ? OculumAbilityCooldown.fromJson(source[index].toJson())
        : OculumAbilityCooldown(),
  );
}

List<OculumAbilityCooldown> oculumReadCooldownsPerLevel(dynamic raw) {
  if (raw is! List) return oculumNormalizeCooldownsPerLevel(null);
  return oculumNormalizeCooldownsPerLevel(<OculumAbilityCooldown>[
    for (final value in raw)
      if (value is Map)
        OculumAbilityCooldown.fromJson(Map<String, dynamic>.from(value)),
  ]);
}

String oculumNormalizeEffectResource(dynamic raw) {
  final normalized = oculumNormalizeText('$raw').replaceAll(' ', '');
  switch (normalized) {
    case 'hp':
    case 'vita':
      return 'vita';
    case 'fortuna':
      return 'fortuna';
    case 'scudo':
    case 'shield':
      return 'scudo';
    case 'scudooculum':
    case 'scudo_oculum':
    case 'oculumshield':
      return 'scudo_oculum';
    case 'azione':
    case 'azioni':
      return 'azioni';
    case 'reazione':
    case 'reazioni':
      return 'reazioni';
    case 'reazionerapida':
    case 'reazionirapide':
      return 'reazioni_rapide';
    case 'utilizzo':
    case 'utilizzi':
    case 'utilizziskill':
      return 'utilizzi_skill';
    case 'materia':
    case 'mat':
      return 'materia';
    case 'volonta':
    case 'vol':
    case 'volontà':
      return 'volonta';
    case 'resilienza':
    case 'res':
      return 'resilienza';
    case 'nessuna':
    case 'nessuno':
    case 'gratis':
      return 'nessuna';
    case 'oculum':
    case 'ocu':
    default:
      return 'oculum';
  }
}

bool oculumIsConsumableEffectResource(
  String resource, {
  Iterable<HiddenEyeStat> subtraits = const <HiddenEyeStat>[],
}) {
  final dynamicKey = oculumDynamicFormulaKey(resource);
  for (final stat in subtraits) {
    if (dynamicKey == oculumDynamicFormulaKey(stat.id) ||
        dynamicKey == oculumDynamicFormulaKey(stat.nome)) {
      return false;
    }
  }
  return oculumEffectConsumableResourceKeys.contains(
    oculumNormalizeEffectResource(resource),
  );
}

class OculumSkillCost {
  OculumSkillCost({
    String resource = 'oculum',
    this.amountExpression = '0',
    this.variable = false,
    this.minimum = 0,
    this.maximum = 0,
    this.perTurn = false,
  }) : resource = _oculumKnownConsumableResource(resource)
           ? oculumNormalizeEffectResource(resource)
           : resource.trim();

  String resource;
  String amountExpression;
  bool variable;
  int minimum;
  int maximum;
  bool perTurn;

  bool isValid({Iterable<HiddenEyeStat> subtraits = const <HiddenEyeStat>[]}) {
    if (!oculumIsConsumableEffectResource(resource, subtraits: subtraits)) {
      return false;
    }
    if (resource == 'nessuna') return true;
    if (variable && maximum > 0 && maximum < max(0, minimum)) return false;
    return amountExpression.trim().isNotEmpty || variable;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'resource': resource,
    'amountExpression': amountExpression,
    'variable': variable,
    'minimum': minimum,
    'maximum': maximum,
    'perTurn': perTurn,
  };

  factory OculumSkillCost.fromJson(Map<String, dynamic> json) {
    return OculumSkillCost(
      resource: '${json['resource'] ?? json['risorsa'] ?? 'oculum'}',
      amountExpression: '${json['amountExpression'] ?? json['valore'] ?? '0'}',
      variable: readBoolValue(json['variable'] ?? json['variabile']),
      minimum: max(0, readIntValue(json['minimum'] ?? json['minimo'])),
      maximum: max(0, readIntValue(json['maximum'] ?? json['massimo'])),
      perTurn: readBoolValue(json['perTurn'] ?? json['perTurno']),
    );
  }
}

bool _oculumKnownConsumableResource(String raw) {
  final key = oculumNormalizeText(raw).replaceAll(' ', '');
  return <String>{
    'oculum',
    'fortuna',
    'hp',
    'scudo',
    'scudo_oculum',
    'vita',
    'azione',
    'azioni',
    'reazione',
    'reazioni',
    'reazionerapida',
    'reazionirapide',
    'utilizzo',
    'utilizzi',
    'utilizziskill',
    'materia',
    'scudooculum',
    'mat',
    'volonta',
    'vol',
    'resilienza',
    'res',
    'ocu',
    'nessuna',
    'nessuno',
    'gratis',
  }.contains(key);
}

class OculumStructuredEffect {
  OculumStructuredEffect({
    String? id,
    this.type = 'danno',
    this.target = '',
    this.resource = '',
    this.valueExpression = '0',
    this.mode = 'immediato',
    this.duration = '',
    this.durationUnit = 'turni',
    this.frequency = '',
    this.recipient = 'se_stesso',
    this.diceExpression = '',
    this.diceDestination = 'valore',
    this.includeLevel = false,
    this.includeGrade = false,
    this.gradeValue = 1,
    this.enabled = true,
    this.stackable = false,
    this.minimum,
    this.maximum,
    this.narrativeText = '',
    this.customDisplayText = '',
    this.elementType = '',
    this.appliedState = '',
    this.bypassDefense = false,
    this.bypassShields = false,
  }) : id = id?.trim().isNotEmpty == true
           ? id!.trim()
           : 'effect_${DateTime.now().microsecondsSinceEpoch}';

  String id;
  String type;
  String target;
  String resource;
  String valueExpression;
  String mode;
  String duration;
  String durationUnit;
  String frequency;
  String recipient;
  String diceExpression;
  String diceDestination;
  bool includeLevel;
  bool includeGrade;
  double gradeValue;
  bool enabled;
  bool stackable;
  int? minimum;
  int? maximum;
  String narrativeText;
  String customDisplayText;
  String elementType;
  String appliedState;
  bool bypassDefense;
  bool bypassShields;

  OculumStructuredEffect copyWithNewId() {
    return OculumStructuredEffect.fromJson(toJson())
      ..id = 'effect_${DateTime.now().microsecondsSinceEpoch}';
  }

  OculumStructuredEffect copyForNextForm() {
    return OculumStructuredEffect.fromJson(toJson());
  }

  bool get isEmpty =>
      type.trim().isEmpty ||
      (valueExpression.trim().isEmpty &&
          narrativeText.trim().isEmpty &&
          customDisplayText.trim().isEmpty);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'type': type,
    'target': target,
    'resource': resource,
    'valueExpression': valueExpression,
    'mode': mode,
    'duration': duration,
    'durationUnit': durationUnit,
    'frequency': frequency,
    'recipient': recipient,
    'diceExpression': diceExpression,
    'diceDestination': diceDestination,
    'includeLevel': includeLevel,
    'includeGrade': includeGrade,
    'gradeValue': gradeValue,
    'enabled': enabled,
    'stackable': stackable,
    if (minimum != null) 'minimum': minimum,
    if (maximum != null) 'maximum': maximum,
    'narrativeText': narrativeText,
    'customDisplayText': customDisplayText,
    'elementType': elementType,
    'appliedState': appliedState,
    'bypassDefense': bypassDefense,
    'bypassShields': bypassShields,
  };

  factory OculumStructuredEffect.fromJson(Map<String, dynamic> json) {
    return OculumStructuredEffect(
      id: '${json['id'] ?? ''}',
      type: '${json['type'] ?? json['tipo'] ?? 'danno'}',
      target: '${json['target'] ?? json['bersaglioValore'] ?? ''}',
      resource: '${json['resource'] ?? json['risorsa'] ?? ''}',
      valueExpression: '${json['valueExpression'] ?? json['valore'] ?? '0'}',
      mode: '${json['mode'] ?? json['modalita'] ?? 'immediato'}',
      duration: '${json['duration'] ?? json['durata'] ?? ''}',
      durationUnit: '${json['durationUnit'] ?? json['unitaDurata'] ?? 'turni'}',
      frequency: '${json['frequency'] ?? json['frequenza'] ?? ''}',
      recipient: '${json['recipient'] ?? json['bersaglio'] ?? 'se_stesso'}',
      diceExpression:
          '${json['diceExpression'] ?? json['dadiAttivazione'] ?? ''}',
      diceDestination:
          '${json['diceDestination'] ?? json['destinazioneDadi'] ?? 'valore'}',
      includeLevel: readBoolValue(
        json['includeLevel'] ?? json['aggiungiLivello'],
      ),
      includeGrade: readBoolValue(
        json['includeGrade'] ?? json['aggiungiGrado'],
      ),
      gradeValue: readDoubleValue(
        json['gradeValue'] ?? json['valoreGrado'],
        fallback: 1,
      ),
      enabled: readBoolValue(json['enabled'] ?? json['attivo'], fallback: true),
      stackable: readBoolValue(json['stackable'] ?? json['accumulabile']),
      minimum: json.containsKey('minimum') || json.containsKey('minimo')
          ? readIntValue(json['minimum'] ?? json['minimo'])
          : null,
      maximum: json.containsKey('maximum') || json.containsKey('massimo')
          ? readIntValue(json['maximum'] ?? json['massimo'])
          : null,
      narrativeText: '${json['narrativeText'] ?? json['testoNarrativo'] ?? ''}',
      customDisplayText:
          '${json['customDisplayText'] ?? json['testoPersonalizzato'] ?? ''}',
      elementType: '${json['elementType'] ?? json['tipoElemento'] ?? ''}',
      appliedState: '${json['appliedState'] ?? json['statoApplicato'] ?? ''}',
      bypassDefense: readBoolValue(
        json['bypassDefense'] ?? json['oltreDifesa'],
      ),
      bypassShields: readBoolValue(json['bypassShields'] ?? json['oltreScudi']),
    );
  }
}

int oculumStructuredEffectFrequency(dynamic raw) {
  return max(0, readIntValue(raw));
}

/// Avanza il contatore persistente di un effetto periodico.
///
/// Ritorna `true` soltanto sul tick in cui l'effetto deve agire. Le vecchie
/// mappe senza frequenza restano inalterate e non diventano periodiche.
bool oculumAdvanceStructuredEffectFrequency(
  Map<String, dynamic> state,
  String eventUnit,
) {
  final frequency = oculumStructuredEffectFrequency(state['frequency']);
  if (frequency <= 0 ||
      oculumNormalizeText('${state['unit'] ?? 'turni'}') !=
          oculumNormalizeText(eventUnit)) {
    return false;
  }
  final elapsed = max(0, readIntValue(state['frequencyElapsed'])) + 1;
  final due = elapsed >= frequency;
  state['frequencyElapsed'] = due ? 0 : elapsed;
  state['periodicActive'] = due;
  return due;
}

bool oculumShouldRestoreActiveStructuredEffect(Map<String, dynamic> state) {
  final remaining = readIntValue(state['remaining']);
  return remaining > 0 ||
      (remaining < 0 &&
          oculumStructuredEffectFrequency(state['frequency']) > 0);
}

List<OculumStructuredEffect> oculumReadStructuredEffects(dynamic raw) {
  if (raw is! List) return <OculumStructuredEffect>[];
  return <OculumStructuredEffect>[
    for (final value in raw)
      if (value is Map)
        OculumStructuredEffect.fromJson(Map<String, dynamic>.from(value)),
  ];
}

List<List<OculumStructuredEffect>> oculumNormalizeArtEffectsPerLevel(
  Iterable<Iterable<OculumStructuredEffect>>? values,
) {
  final source = values?.toList(growable: false) ?? const [];
  return List<List<OculumStructuredEffect>>.generate(
    5,
    (index) => index < source.length
        ? source[index]
              .map((effect) => OculumStructuredEffect.fromJson(effect.toJson()))
              .toList()
        : <OculumStructuredEffect>[],
  );
}

List<List<OculumStructuredEffect>> oculumReadArtEffectsPerLevel(dynamic raw) {
  if (raw is! List) return oculumNormalizeArtEffectsPerLevel(null);
  return oculumNormalizeArtEffectsPerLevel(<List<OculumStructuredEffect>>[
    for (final level in raw) oculumReadStructuredEffects(level),
  ]);
}

String oculumOfficialSubtraitName(
  String raw,
  Iterable<HiddenEyeStat> subtraits,
) {
  final needle = oculumDynamicFormulaKey(raw);
  if (needle.isEmpty) return '';
  for (final stat in subtraits) {
    if (needle == oculumDynamicFormulaKey(stat.id) ||
        needle == oculumDynamicFormulaKey(stat.nome)) {
      return stat.nome.trim().isEmpty ? stat.id : stat.nome.trim();
    }
  }
  return '';
}

/// Normalizza esclusivamente riferimenti a sottotratti conosciuti.
///
/// Esempi: `@ Res + 1`, `@res +1` e `@Res+1` diventano `@Res+1`
/// quando il nome ufficiale è `Res`.
String oculumNormalizeSubtraitReferences(
  String raw,
  Iterable<HiddenEyeStat> subtraits,
) {
  var text = raw;
  const statAliases = <String, String>{
    'res': 'Res',
    'resilienza': 'Resilienza',
    'vol': 'Vol',
    'volonta': 'Volonta',
    'mat': 'Mat',
    'materia': 'Materia',
    'ocu': 'Ocu',
    'oculum': 'Oculum',
  };
  for (final entry in statAliases.entries) {
    text = text.replaceAllMapped(
      RegExp(
        '@\\s*${RegExp.escape(entry.key)}(?![A-Za-z0-9_])\\s*(?:([+-])\\s*(\\d+))?',
        caseSensitive: false,
      ),
      (match) =>
          '@${entry.value}${match.group(1) ?? ''}${match.group(2) ?? ''}',
    );
  }
  text = text.replaceAllMapped(
    RegExp(
      r'\b(Resilienza|Volonta|Materia|Oculum)\s+(Speso|Spesa|Immesso|Immessa|Utilizzato|Utilizzata|Skill)\b',
      caseSensitive: false,
    ),
    (match) => oculumStatKey('${match.group(1)}${match.group(2)}'),
  );

  final ordered = subtraits.toList(growable: false)
    ..sort((a, b) {
      final aLength = max(a.nome.length, a.id.length);
      final bLength = max(b.nome.length, b.id.length);
      return bLength.compareTo(aLength);
    });
  for (final stat in ordered) {
    final official = stat.nome.trim().isEmpty
        ? stat.id.trim()
        : stat.nome.trim();
    if (official.isEmpty) continue;
    final aliases = <String>{stat.id.trim(), stat.nome.trim()}
      ..removeWhere((value) => value.isEmpty);
    for (final alias in aliases) {
      final words = alias
          .split(RegExp(r'[\s_]+'))
          .where((word) => word.isNotEmpty)
          .map(RegExp.escape)
          .join(r'[\s_]*');
      if (words.isEmpty) continue;
      text = text.replaceAllMapped(
        RegExp('@\\s*$words\\s*(?:([+-])\\s*(\\d+))?', caseSensitive: false),
        (match) {
          final sign = match.group(1) ?? '';
          final amount = match.group(2) ?? '';
          return '@$official$sign$amount';
        },
      );
    }
  }
  return text;
}

String oculumEffectFormulaExpression(
  String raw,
  Iterable<HiddenEyeStat> subtraits,
) {
  var text = oculumNormalizeSubtraitReferences(
    oculumCleanMojibakeText(raw),
    subtraits,
  ).trim();
  text = text
      .replaceAll('\u00D7', '*')
      .replaceAll('Ã—', '*')
      .replaceAll(RegExp(r'[xX](?=\s*\d)'), '*');
  text = text.replaceAllMapped(
    RegExp(
      r'([0-9]+(?:[,.][0-9]+)?)\s*%\s*([A-Za-zÀ-ÖØ-öø-ÿ_]+)',
      caseSensitive: false,
    ),
    (match) => '${match.group(2)}*${match.group(1)}%',
  );
  text = text.replaceAllMapped(
    RegExp(r'\b[A-Za-z_]+\b', caseSensitive: false),
    (match) {
      final rawKey = match.group(0) ?? '';
      if (oculumNormalizeText(rawKey).replaceAll(' ', '') == 'statsskill') {
        return 'stats_skill_spent';
      }
      final builtIn = oculumStatKey(rawKey);
      return builtIn.endsWith('_spent') ? builtIn : rawKey;
    },
  );

  final ordered = subtraits.toList(growable: false)
    ..sort((a, b) => b.nome.length.compareTo(a.nome.length));
  for (final stat in ordered) {
    final official = stat.nome.trim().isEmpty
        ? stat.id.trim()
        : stat.nome.trim();
    if (official.isEmpty) continue;
    final key = oculumDynamicFormulaKey(stat.id);
    text = text.replaceAllMapped(
      RegExp('@${RegExp.escape(official)}', caseSensitive: false),
      (_) => key,
    );
  }
  text = text.replaceAllMapped(RegExp(r'@([A-Za-zÀ-ÖØ-öø-ÿ_]+)'), (match) {
    final rawKey = match.group(1) ?? '';
    final builtIn = oculumStatKey(rawKey);
    return builtIn.isNotEmpty ? builtIn : oculumDynamicFormulaKey(rawKey);
  });
  return text.replaceAll(',', '.');
}

int oculumEvaluateStructuredEffectValue(
  OculumStructuredEffect effect, {
  required Map<String, num> variables,
  Iterable<HiddenEyeStat> subtraits = const <HiddenEyeStat>[],
  Map<String, num> spentResources = const <String, num>{},
}) {
  final vars = <String, num>{...variables};
  for (final entry in spentResources.entries) {
    final key = oculumDynamicFormulaKey(entry.key);
    vars['${key}_spent'] = entry.value;
    if (key == 'oculum') vars['oculum_spent'] = entry.value;
  }
  vars['stats_skill_spent'] = <String>[
    'resilienza_spent',
    'volonta_spent',
    'materia_spent',
    'oculum_spent',
  ].fold<num>(0, (sum, key) => sum + (vars[key] ?? 0));
  final expression = oculumEffectFormulaExpression(
    effect.valueExpression,
    subtraits,
  );
  var value = oculumRoundFormulaResult(oculumEvaluateFormula(expression, vars));
  if (effect.minimum != null) value = max(effect.minimum!, value);
  if (effect.maximum != null) value = min(effect.maximum!, value);
  return value;
}

class OculumDiceRollResult {
  const OculumDiceRollResult({
    required this.expression,
    required this.rolls,
    required this.modifier,
  });

  final String expression;
  final List<int> rolls;
  final int modifier;

  int get total => rolls.fold<int>(modifier, (sum, roll) => sum + roll);
}

OculumDiceRollResult oculumRollEffectDice(String raw, {Random? random}) {
  final text = raw.trim().toLowerCase().replaceAll(' ', '');
  if (text.isEmpty) {
    return const OculumDiceRollResult(
      expression: '',
      rolls: <int>[],
      modifier: 0,
    );
  }
  final match = RegExp(r'^(\d*)d(\d+)([+-]\d+)?$').firstMatch(text);
  if (match == null) {
    throw const FormatException('Dado non valido. Usa una forma come 1d6+2.');
  }
  final count = int.tryParse(match.group(1) ?? '') ?? 1;
  final faces = int.tryParse(match.group(2) ?? '') ?? 0;
  final modifier = int.tryParse(match.group(3) ?? '') ?? 0;
  if (count < 1 || count > 20 || faces < 2 || faces > 1000) {
    throw const FormatException('Dado fuori dai limiti consentiti.');
  }
  final rng = random ?? Random.secure();
  return OculumDiceRollResult(
    expression: text,
    rolls: <int>[for (var i = 0; i < count; i++) rng.nextInt(faces) + 1],
    modifier: modifier,
  );
}

class OculumStructuredEffectRoll {
  const OculumStructuredEffectRoll({
    required this.baseValue,
    required this.dice,
    required this.levelBonus,
    required this.gradeBonus,
    required this.value,
    required this.durationBonus,
  });

  final int baseValue;
  final OculumDiceRollResult dice;
  final int levelBonus;
  final int gradeBonus;
  final int value;
  final int durationBonus;
}

OculumStructuredEffectRoll oculumResolveStructuredEffectRoll(
  OculumStructuredEffect effect, {
  required Map<String, num> variables,
  Iterable<HiddenEyeStat> subtraits = const <HiddenEyeStat>[],
  Map<String, num> spentResources = const <String, num>{},
  int level = 0,
  int grade = 0,
  bool isTick = false,
  Random? random,
}) {
  final baseValue = oculumEvaluateStructuredEffectValue(
    effect,
    variables: variables,
    subtraits: subtraits,
    spentResources: spentResources,
  );
  final dice = isTick
      ? const OculumDiceRollResult(expression: '', rolls: <int>[], modifier: 0)
      : oculumRollEffectDice(effect.diceExpression, random: random);
  final levelBonus = effect.includeLevel ? max(0, level) : 0;
  final gradeBonus = effect.includeGrade
      ? oculumRoundFormulaResult(max(0, grade) * effect.gradeValue)
      : 0;
  final sharedBonus = levelBonus + gradeBonus;
  final diceForDuration = effect.diceDestination == 'durata';
  return OculumStructuredEffectRoll(
    baseValue: baseValue,
    dice: dice,
    levelBonus: levelBonus,
    gradeBonus: gradeBonus,
    value: baseValue + sharedBonus + (diceForDuration ? 0 : dice.total),
    durationBonus: diceForDuration ? dice.total : 0,
  );
}

String oculumStructuredEffectTargetKey(OculumStructuredEffect effect) {
  switch (effect.type) {
    case 'danno':
      return 'danni';
    case 'difesa':
      return 'difesa';
    case 'scudo':
      return 'scudo';
    case 'hp_temporanei':
      return 'hp_temp';
    case 'cura':
      return oculumNormalizeEffectResource(effect.resource) == 'oculum'
          ? 'oculum'
          : 'hp';
    case 'velocita':
    case 'forza':
    case 'modifica_statistica':
    case 'modifica_sottotratto':
      return oculumDynamicFormulaKey(effect.target);
    case 'rimuovi_reazioni':
    case 'aggiungi_reazioni':
      return 'reazioni';
    case 'rimuovi_reazioni_rapide':
    case 'aggiungi_reazioni_rapide':
      return 'reazioni_veloci';
    default:
      return '';
  }
}

String oculumStructuredEffectQuickCommand(
  OculumStructuredEffect effect, {
  Iterable<HiddenEyeStat> subtraits = const <HiddenEyeStat>[],
}) {
  if (!effect.enabled) return '';
  final key = oculumStructuredEffectTargetKey(effect);
  if (key.isEmpty) return '';
  final expression = oculumEffectFormulaExpression(
    effect.valueExpression,
    subtraits,
  );
  if (expression.trim().isEmpty) return '';
  final negative =
      effect.type.startsWith('rimuovi_') || effect.mode == 'diminuzione';
  return '@$key${negative ? '-' : '+'}$expression';
}

String oculumStructuredEffectDescription(
  OculumStructuredEffect effect, {
  Iterable<HiddenEyeStat> subtraits = const <HiddenEyeStat>[],
}) {
  final custom = effect.customDisplayText.trim();
  final frequency = oculumStructuredEffectFrequency(effect.frequency);
  final periodicText = frequency <= 0
      ? ''
      : ' ogni $frequency ${effect.durationUnit.trim().isEmpty ? 'turni' : effect.durationUnit}';
  String withPeriod(String text) {
    if (periodicText.isEmpty ||
        RegExp(r'\bogni\s+\d+', caseSensitive: false).hasMatch(text)) {
      return text;
    }
    return '$text$periodicText';
  }

  if (custom.isNotEmpty) return withPeriod(custom);
  final value = oculumNormalizeSubtraitReferences(
    effect.valueExpression,
    subtraits,
  );
  final target = effect.target.trim();
  final resource = oculumNormalizeEffectResource(effect.resource);
  final dice = effect.diceExpression.trim().isEmpty
      ? ''
      : ' + ${effect.diceExpression.trim()}';
  final progression = <String>[
    if (effect.includeLevel) 'Livello',
    if (effect.includeGrade) 'Grado×${effect.gradeValue}',
  ].join(' + ');
  final progressionText = progression.isEmpty ? '' : ' + $progression';
  final elementText = effect.elementType.trim().isEmpty
      ? ''
      : ' ${effect.elementType.trim()}';
  final bypassText = <String>[
    if (effect.bypassDefense) 'oltre Difesa',
    if (effect.bypassShields) 'oltre Scudi',
  ].join(', ');
  final damageBypassText = effect.type == 'danno' && bypassText.isNotEmpty
      ? ' ($bypassText)'
      : '';
  final displayedValue =
      '$value$dice$progressionText$elementText$damageBypassText';
  switch (effect.type) {
    case 'danno':
      return withPeriod(
        effect.mode == 'finche_attivo'
            ? 'Danni + $displayedValue finché l’effetto è attivo'
            : 'Infligge $displayedValue danni',
      );
    case 'difesa':
      return withPeriod('Difesa + $displayedValue');
    case 'cura':
      final verb = effect.mode == 'rigenerazione' ? 'Rigenera' : 'Cura';
      return withPeriod(
        '$verb $displayedValue ${resource == 'oculum' ? 'Oculum' : 'Vita'}',
      );
    case 'scudo':
      return withPeriod('Scudo + $displayedValue');
    case 'hp_temporanei':
      return withPeriod('HP temporanei + $displayedValue');
    case 'modifica_statistica':
    case 'modifica_sottotratto':
      return withPeriod(
        '$target ${effect.mode == 'diminuzione' ? '-' : '+'}$displayedValue',
      );
    case 'velocita':
      return withPeriod(
        '${target.isEmpty ? 'Velocità' : target} + $displayedValue',
      );
    case 'forza':
      return withPeriod(
        '${target.isEmpty ? 'Forza' : target} + $displayedValue',
      );
    case 'rimuovi_vita':
      return 'Rimuove $value Vita';
    case 'rimuovi_oculum':
      return 'Rimuove $value Oculum';
    case 'rimuovi_azioni':
      return 'Rimuove $value azioni';
    case 'rimuovi_reazioni':
      return 'Rimuove $value reazioni';
    case 'rimuovi_reazioni_rapide':
      return 'Rimuove $value reazioni rapide';
    case 'aggiungi_reazioni':
      return 'Aggiunge $value reazioni';
    case 'aggiungi_reazioni_rapide':
      return 'Aggiunge $value reazioni rapide';
    case 'consumo_risorsa':
      return 'Consuma $value $resource';
    case 'stato':
      return 'Applica lo stato ${effect.appliedState.isEmpty ? target : effect.appliedState}'
          '${effect.elementType.isEmpty ? '' : ' (${effect.elementType})'}';
    default:
      return value;
  }
}

class OculumFreeTextEffectParseResult {
  const OculumFreeTextEffectParseResult({
    required this.effects,
    required this.unrecognizedText,
  });

  final List<OculumStructuredEffect> effects;
  final String unrecognizedText;
}

OculumFreeTextEffectParseResult oculumParseStructuredEffectsFromText(
  String raw, {
  Iterable<HiddenEyeStat> subtraits = const <HiddenEyeStat>[],
}) {
  final effects = <OculumStructuredEffect>[];
  final leftovers = <String>[];
  final normalized = oculumNormalizeSubtraitReferences(
    oculumCleanMojibakeText(raw),
    subtraits,
  );
  final pieces = normalized
      .split(RegExp(r'\s+(?:e|and)\s+|[;\n]+', caseSensitive: false))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty);
  final effectPattern = RegExp(
    r'(Danni|Danno|Difesa|Scudo|Cura|Rigenera|HP\s*temporanei?)\s*(?:\+|di)?\s*(.+)$',
    caseSensitive: false,
  );
  for (final piece in pieces) {
    final lower = oculumNormalizeText(piece);
    var recognized = false;

    final isWall =
        RegExp(r'\b(muro|barriera)\b', caseSensitive: false).hasMatch(piece) &&
        (lower.contains('assorb') ||
            lower.contains('sottrae ai danni') ||
            lower.contains('riduce i danni'));
    final wallFormula = RegExp(
      r'(?:oculum\s*(?:immess\w*|spes\w*|utilizzat\w*)|oculum_spent)\s*(?:x|\*|\u00D7)\s*(\d+)\s*(?:([+-])\s*(\d+))?',
      caseSensitive: false,
    ).firstMatch(piece);
    if (isWall && wallFormula != null) {
      final multiplier = wallFormula.group(1) ?? '1';
      final sign = wallFormula.group(2) ?? '';
      final bonus = wallFormula.group(3) ?? '';
      final expression =
          'OculumSpeso*$multiplier${sign.isEmpty || bonus.isEmpty ? '' : '$sign$bonus'}';
      effects.add(
        OculumStructuredEffect(
          type: 'scudo',
          valueExpression: expression,
          narrativeText: piece,
          customDisplayText:
              'Muro: assorbe $expression danni e crolla quando esaurito',
        ),
      );
      recognized = true;
    } else if (RegExp(
      r'\b(muro|barriera)\b.*\b(crolla|svanisce|si rompe)\b',
      caseSensitive: false,
    ).hasMatch(piece)) {
      // Continuazione narrativa di un muro già riconosciuto.
      recognized = true;
    }

    final periodicDamage = RegExp(
      r'(?:\+|aument\w*\s+(?:il\s+)?(?:tuo\s+)?)?(\d+)\s*(?:a\s+)?dann\w*\s+ogni\s+(\d+)\s*turn',
      caseSensitive: false,
    ).firstMatch(piece);
    if (periodicDamage != null) {
      effects.add(
        OculumStructuredEffect(
          type: 'danno',
          valueExpression: periodicDamage.group(1) ?? '0',
          mode: 'finche_attivo',
          frequency: periodicDamage.group(2) ?? '',
          narrativeText: piece,
          customDisplayText:
              '+${periodicDamage.group(1)} danni ogni ${periodicDamage.group(2)} turni',
        ),
      );
      recognized = true;
    }

    final allStats = RegExp(
      r'\+?\s*(\d+)\s+(?:a\s+)?tutt\w*\s+(?:le\s+)?stat',
      caseSensitive: false,
    ).firstMatch(piece);
    if (allStats != null) {
      for (final target in const <String>[
        'Resilienza',
        'Volontà',
        'Materia',
        'Oculum',
      ]) {
        effects.add(
          OculumStructuredEffect(
            type: 'modifica_statistica',
            target: target,
            valueExpression: allStats.group(1) ?? '0',
            mode: 'finche_attivo',
            narrativeText: piece,
          ),
        );
      }
      recognized = true;
    }

    if (RegExp(
      r'(?:stats?|statistiche)\s*\+\s*(?:oculum\s*spes|oculum_spent)',
      caseSensitive: false,
    ).hasMatch(piece)) {
      for (final target in const <String>[
        'Resilienza',
        'Volontà',
        'Materia',
        'Oculum',
      ]) {
        effects.add(
          OculumStructuredEffect(
            type: 'modifica_statistica',
            target: target,
            valueExpression: 'OculumSpeso',
            mode: 'finche_attivo',
            narrativeText: piece,
            customDisplayText: '$target + Oculum speso',
          ),
        );
      }
      recognized = true;
    }

    final temporaryDamage = RegExp(
      r'(?:aument\w*\s+(?:il\s+)?(?:tuo\s+)?dann\w*\s+di|dann\w*\s*\+)\s*(\d+)(?:\s+per\s+(\d+|un|uno)\s+turn\w*)?',
      caseSensitive: false,
    ).firstMatch(piece);
    if (temporaryDamage != null && periodicDamage == null) {
      final rawDuration = oculumNormalizeText(temporaryDamage.group(2) ?? '');
      final duration = rawDuration == 'un' || rawDuration == 'uno'
          ? '1'
          : rawDuration;
      effects.add(
        OculumStructuredEffect(
          type: 'danno',
          valueExpression: temporaryDamage.group(1) ?? '0',
          mode: duration.isEmpty ? 'immediato' : 'finche_attivo',
          duration: duration,
          durationUnit: 'turni',
          narrativeText: piece,
        ),
      );
      recognized = true;
    }

    final nextHits = RegExp(
      r'(?:prossim\w*\s+)?(\d+)\s+colp\w*',
      caseSensitive: false,
    ).firstMatch(piece);
    if (nextHits != null &&
        (lower.contains('letale') || lower.contains('lethal'))) {
      effects.add(
        OculumStructuredEffect(
          type: 'stato',
          target: 'Danno letale',
          valueExpression: '1',
          mode: 'finche_attivo',
          duration: nextHits.group(1) ?? '',
          durationUnit: 'tiri',
          appliedState: lower.contains('anti fato')
              ? 'Danno letale contro anti-Fato'
              : 'Danno letale',
          narrativeText: piece,
          customDisplayText: piece,
        ),
      );
      recognized = true;
    }

    if (lower.contains('trasform')) {
      effects.add(
        OculumStructuredEffect(
          type: 'stato',
          target: 'Trasformazione',
          valueExpression: '1',
          mode: 'finche_attivo',
          appliedState: 'Trasformazione',
          narrativeText: piece,
          customDisplayText: piece,
        ),
      );
      recognized = true;
    }

    for (final match in effectPattern.allMatches(piece)) {
      if (isWall) continue;
      final rawType = oculumNormalizeText(match.group(1) ?? '');
      final rawValue = (match.group(2) ?? '').trim();
      final periodic = RegExp(
        r'\s+ogni\s+(\d+)\s*(turn\w*|tir\w*)\s*$',
        caseSensitive: false,
      ).firstMatch(rawValue);
      final value = periodic == null
          ? rawValue
          : rawValue.substring(0, periodic.start).trim();
      if (value.isEmpty ||
          (periodicDamage != null &&
              (rawType == 'danno' || rawType == 'danni')) ||
          (temporaryDamage != null &&
              (rawType == 'danno' || rawType == 'danni'))) {
        continue;
      }
      final type = switch (rawType.replaceAll(' ', '')) {
        'danno' || 'danni' => 'danno',
        'difesa' => 'difesa',
        'scudo' => 'scudo',
        'cura' || 'rigenera' => 'cura',
        _ => 'hp_temporanei',
      };
      effects.add(
        OculumStructuredEffect(
          type: type,
          valueExpression: value,
          mode: rawType == 'rigenera' ? 'rigenerazione' : 'immediato',
          resource: type == 'cura' ? 'vita' : '',
          frequency: periodic?.group(1) ?? '',
          durationUnit:
              oculumNormalizeText(periodic?.group(2) ?? '').startsWith('tir')
              ? 'tiri'
              : 'turni',
          narrativeText: piece,
        ),
      );
      recognized = true;
    }

    if (!recognized) {
      leftovers.add(piece);
    }
  }
  return OculumFreeTextEffectParseResult(
    effects: effects,
    unrecognizedText: leftovers.join(' e '),
  );
}

class OculumEffectApplicationGuard {
  final Set<String> _applied = <String>{};

  bool tryApply(String activationId, OculumStructuredEffect effect) {
    return _applied.add('$activationId:${effect.id}');
  }

  void clearActivation(String activationId) {
    _applied.removeWhere((key) => key.startsWith('$activationId:'));
  }
}
