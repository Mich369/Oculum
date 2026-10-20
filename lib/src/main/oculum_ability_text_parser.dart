part of '../../main.dart';

const _oculumAbilityResourcePattern =
    r'(?:Scudo\s+Oculum|Oculum|OCU|Volont[aà]|VOL|Materia|MAT|Resilienza|RES|Vita|HP|Scudo|Reazioni?|Azioni?)';

List<OculumStructuredEffect> oculumResolveAbilityEffects(
  Iterable<OculumStructuredEffect> configured,
  String text, {
  Iterable<HiddenEyeStat> subtraits = const [],
  bool investedOculum = false,
  bool legacyQuickCommands = false,
}) {
  final declared = configured.toList();
  if (declared.isNotEmpty) return declared;
  final parsed = oculumParseAbilityMechanics(
    text,
    subtraits: subtraits,
    investedOculum: investedOculum,
  ).effects;
  // Existing @stat and @damage commands are already evaluated by the legacy
  // quick-command runtime. Do not apply those same self bonuses a second time.
  return legacyQuickCommands
      ? parsed
            .where(
              (effect) =>
                  !(effect.recipient == 'se_stesso' &&
                      effect.narrativeText.contains('@') &&
                      const {
                        'danno',
                        'difesa',
                        'modifica_statistica',
                        'modifica_sottotratto',
                      }.contains(effect.type)),
            )
            .toList()
      : parsed;
}

({int minimum, int maximum, String resource})? oculumParseAbilityCost(
  String raw,
) {
  if (RegExp(
    r'\b(?:nessun\s+costo|senza\s+costo|gratuit[oa])\b',
    caseSensitive: false,
  ).hasMatch(raw)) {
    return (minimum: 0, maximum: 0, resource: 'nessuna');
  }
  final range = RegExp(
    '(?:\\b(?:costo|spendi|consumi|costa)\\s*:?\\s*|\\()\\s*(\\d+)\\s*[/–-]\\s*(\\d+)\\s*($_oculumAbilityResourcePattern)?\\s*\\)?',
    caseSensitive: false,
  ).firstMatch(raw);
  if (range != null) {
    final minimum = int.parse(range.group(1)!);
    final maximum = int.parse(range.group(2)!);
    if (maximum < minimum) return null;
    return (
      minimum: minimum,
      maximum: maximum,
      resource: oculumNormalizeEffectResource(range.group(3) ?? 'oculum'),
    );
  }
  final nakedRange = RegExp(
    '(\\d+)\\s*/\\s*(\\d+)\\s*($_oculumAbilityResourcePattern)\\b',
    caseSensitive: false,
  ).firstMatch(raw);
  if (nakedRange != null) {
    final minimum = int.parse(nakedRange.group(1)!);
    final maximum = int.parse(nakedRange.group(2)!);
    return maximum < minimum
        ? null
        : (
            minimum: minimum,
            maximum: maximum,
            resource: oculumNormalizeEffectResource(nakedRange.group(3)!),
          );
  }
  final fixed = RegExp(
    '(?:spendi|costa|costo\\s*:?|consumi)\\s*(\\d+)\\s*($_oculumAbilityResourcePattern)',
    caseSensitive: false,
  ).firstMatch(raw);
  if (fixed == null) return null;
  final amount = int.parse(fixed.group(1)!);
  return (
    minimum: amount,
    maximum: amount,
    resource: oculumNormalizeEffectResource(fixed.group(2)!),
  );
}

/// Parses executable clauses, never costs/requirements or arbitrary prose.
/// Unrecognized clauses remain visible to the author instead of becoming buffs.
OculumFreeTextEffectParseResult oculumParseAbilityMechanics(
  String raw, {
  Iterable<HiddenEyeStat> subtraits = const [],
  bool investedOculum = false,
}) {
  raw = raw
      .replaceAll('**', '')
      .replaceAll('__', '')
      .replaceAll('`', '')
      .replaceAll(RegExp(r'^\s*#{1,6}\s+', multiLine: true), '');
  final effects = <OculumStructuredEffect>[];
  final leftovers = <String>[];
  final seen = <String>{};
  final sourceKey = raw.codeUnits
      .fold<int>(17, (hash, unit) => (hash * 31 + unit) % 2147483647)
      .toRadixString(16);
  final clauses = <String>[];
  var start = 0;
  for (var index = 0; index < raw.length; index++) {
    final character = raw[index];
    final decimal =
        character == '.' &&
        index > 0 &&
        index + 1 < raw.length &&
        RegExp(r'\d').hasMatch(raw[index - 1]) &&
        RegExp(r'\d').hasMatch(raw[index + 1]);
    if (character == ';' || character == '\n' || character == '.' && !decimal) {
      clauses.add(raw.substring(start, index));
      start = index + 1;
    }
  }
  clauses.add(raw.substring(start));
  for (final clause
      in clauses.map((c) => c.trim()).where((c) => c.isNotEmpty)) {
    if (RegExp(
      r'\bse\s+(?!stess[oa]\b)|\b(?:quando|qualora)\b|\b(?:con|al)\s+(?:un\s+)?critico\b|\bnon\s+(?:ottieni|guadagni|ricevi|infliggi|curi|aumenta|aggiungi)\b|\bsubisc\w*\s+[^;]*danni\s+ogni\b|\bScudo\s+Oculum\b',
      caseSensitive: false,
    ).hasMatch(clause)) {
      leftovers.add(clause);
      continue;
    }
    final parsed = _oculumParseAbilityClause(
      clause,
      subtraits: subtraits,
      investedOculum: investedOculum,
    );
    for (final effect in parsed.effects) {
      final targets = oculumAttackTargetLimits(clause, 1);
      if (targets.maximum > 1) {
        effect.minimumTargets = targets.minimum;
        effect.maximumTargets = targets.maximum;
      }
      if (!seen.add(oculumStructuredEffectSemanticKey(effect))) continue;
      effect.id = 'parsed_${sourceKey}_${effects.length}';
      effects.add(effect);
    }
    if (parsed.unrecognizedText.isNotEmpty) {
      leftovers.add(parsed.unrecognizedText);
    }
  }
  return OculumFreeTextEffectParseResult(
    effects: effects,
    unrecognizedText: leftovers.join('; '),
  );
}

String oculumStructuredEffectSemanticKey(OculumStructuredEffect effect) {
  final data = effect.toJson()
    ..remove('id')
    ..remove('narrativeText')
    ..remove('enabled');
  if (effect.type != 'elemental_resistance') data.remove('customDisplayText');
  return jsonEncode(data);
}

OculumFreeTextEffectParseResult _oculumParseAbilityClause(
  String raw, {
  Iterable<HiddenEyeStat> subtraits = const [],
  bool investedOculum = false,
}) {
  final effects = <OculumStructuredEffect>[];
  // Stable across platforms and reloads: different texts have distinct IDs.
  final sourceKey = raw.codeUnits
      .fold<int>(17, (hash, unit) => (hash * 31 + unit) % 2147483647)
      .toRadixString(16);
  final seen = <String>{};
  var text = oculumCleanMojibakeText(raw)
      .replaceAll('−', '-')
      .replaceAll('×', '*')
      .replaceAll(RegExp(r'\s+x\s*', caseSensitive: false), ' * ')
      .replaceAllMapped(RegExp(r'(\d),(\d)'), (m) => '${m[1]}.${m[2]}')
      .replaceAll(RegExp(r'\b(?:III|II|IV|V|I)/'), '')
      .replaceAll(
        RegExp(
          '\\b(?:Costo\\s*:?|spendi|consumi|costa)\\s*\\d+(?:\\s*/\\s*\\d+)?\\s*(?:$_oculumAbilityResourcePattern)?',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(
        RegExp(
          r'\b(?:CD|cooldown|ricarica)\s*:?\s*\d+\s*(?:turn\w*|azion\w*|tir\w*)?',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(
        RegExp(r'Richiede\s+(?:livello|lvl)\s*\d+\.?', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'\bLivello\s+\d+\s*[:,]?', caseSensitive: false), '')
      .replaceAll(
        RegExp(
          '\\(\\s*\\d+\\s*[/–-]\\s*\\d+\\s*(?:$_oculumAbilityResourcePattern)?\\s*\\)',
          caseSensitive: false,
        ),
        '',
      );
  final durationMatches = RegExp(
    r'(?:per|dura(?:ta)?\s*:?|fino a)\s*(\d*d\d+(?:\s*[+-]\s*\d+)?|\d+|un|una|uno|due|tre|quattro|cinque|sei|tutto il|Oculum(?:\s+(?:immesso|speso|investito))?)\s*(riposi\s+lunghi|riposi\s+brevi|turn\w*|tir\w*|azion\w*)',
    caseSensitive: false,
  ).allMatches(text).toList();
  final durationMatch = durationMatches.firstOrNull;
  String durationText(RegExpMatch? match) =>
      switch (match?.group(1)?.toLowerCase()) {
        'un' || 'una' || 'uno' || 'tutto il' => '1',
        'due' => '2',
        'tre' => '3',
        'quattro' => '4',
        'cinque' => '5',
        'sei' => '6',
        final String value => value,
        _ => '1',
      };
  String durationUnit(RegExpMatch? match) =>
      switch (match?.group(2)?.toLowerCase()) {
        final String value when value.startsWith('tir') => 'tiri',
        final String value when value.startsWith('azion') => 'azioni',
        'riposi lunghi' => 'riposi_lunghi',
        'riposi brevi' => 'riposi_brevi',
        _ => 'turni',
      };
  RegExpMatch? durationAt(RegExpMatch? at) => at == null
      ? durationMatch
      : durationMatches.where((m) => m.start >= at.end).firstOrNull ??
            durationMatches.lastOrNull;
  final duration = durationText(durationMatch);
  final unit = durationUnit(durationMatch);
  String formula(String value) => value
      .trim()
      .replaceAll(
        RegExp(
          r'\bOculum\s+(?:immesso|speso|investito|messo|impiegato)\b',
          caseSensitive: false,
        ),
        'oculum_spent',
      )
      .replaceAll(
        RegExp(r'\b(?:Oculum|OCU)\b', caseSensitive: false),
        investedOculum ? 'oculum_spent' : 'oculum',
      )
      .replaceAll(
        RegExp(r'\bVita\s+(?:attuale|rimanente)\b', caseSensitive: false),
        'hp_current',
      )
      .replaceAll(RegExp(r'\bVita\s+massima\b', caseSensitive: false), 'hp')
      .replaceAll('@', '');
  void add(
    String type,
    String value, {
    String target = '',
    String recipient = 'se_stesso',
    String? mode,
    String resource = '',
    RegExpMatch? at,
  }) {
    final expression = formula(value);
    final timing = durationAt(at);
    final periodic = RegExp(
      r'ogni\s+(\d+|un|uno)?\s*(turn\w*|tir\w*|azion\w*)',
      caseSensitive: false,
    ).firstMatch(text);
    final isPeriodic =
        periodic != null &&
        const {'cura', 'scudo', 'hp_temporanei'}.contains(type);
    final key =
        '$type|$target|$expression|$recipient|${durationText(timing)}|${durationUnit(timing)}';
    if (!seen.add(key)) return;
    var element = '';
    if (type == 'danno' && at != null) {
      final aliases = <String>{
        ...oculumDefaultElementIds,
        ...oculumElementAliases.keys,
        ...oculumDefaultElementIds.map(oculumElementDisplayIt),
      }.toList()..sort((a, b) => b.length.compareTo(a.length));
      final match = RegExp(
        '^\\s*(?:(?:da|di|elemento)\\s+)?(${aliases.map(RegExp.escape).join('|')})\\b',
        caseSensitive: false,
      ).firstMatch(text.substring(at.end));
      if (match != null) element = oculumNormalizeElementId(match[1]!);
    }
    effects.add(
      OculumStructuredEffect(
        id: 'parsed_${sourceKey}_${effects.length}_${type}_${target.replaceAll(' ', '_')}',
        type: type,
        target: target,
        valueExpression: expression,
        recipient: recipient,
        resource: resource,
        mode:
            (isPeriodic && type == 'cura' ? 'rigenerazione' : mode) ??
            (type == 'danno' || type == 'danno_percentuale'
                ? durationMatch == null
                      ? 'prossima_azione'
                      : 'finche_attivo'
                : type == 'scudo' || type == 'cura'
                ? 'immediato'
                : 'aumento'),
        duration: isPeriodic && timing == null
            ? '-1'
            : !isPeriodic && (type == 'cura' || type == 'scudo')
            ? ''
            : formula(durationText(timing)),
        durationUnit: isPeriodic
            ? periodic.group(2)!.toLowerCase().startsWith('azion')
                  ? 'azioni'
                  : periodic.group(2)!.toLowerCase().startsWith('tir')
                  ? 'tiri'
                  : 'turni'
            : durationUnit(timing),
        frequency: isPeriodic
            ? '${int.tryParse(periodic.group(1) ?? '') ?? 1}'
            : '',
        elementType: element,
        narrativeText: raw,
      ),
    );
  }

  // Tokens deliberately exclude costs, levels, DT and unknown identifiers.
  const atom =
      r'(?:\d*d\d+|\d+(?:[.,]\d+)?|oculum_spent|Oculum\s+(?:immesso|speso|investito|messo|impiegato)|Oculum|OCU|Danni|Materia|Resilienza|Volontà|Medicina|Livello|Grado|Vita\s+(?:attuale|rimanente|massima))';
  const expression = '$atom(?:\\s*[+*/-]\\s*$atom)*';
  text = text
      .replaceAllMapped(
        RegExp(
          '@(?:cura|guarigione)\\s*[:=+]?\\s*($expression)(?:\\s+(Vita|HP|Oculum))?',
          caseSensitive: false,
        ),
        (match) => 'cura ${match[1]} ${match[2] ?? 'Vita'}',
      )
      .replaceAll(
        RegExp(r'@(?:stato|condizione)\s*[:=]?\s*', caseSensitive: false),
        'applica ',
      );
  final claims = <(int, int)>[];
  String recipientNear(RegExpMatch match) {
    final start =
        max(
          text.lastIndexOf('.', match.start),
          text.lastIndexOf(';', match.start),
        ) +
        1;
    final suffix = text.indexOf('.', match.end);
    final clause = text.substring(start, suffix < 0 ? text.length : suffix);
    final before = text.substring(start, match.start);
    final subjects = RegExp(
      r'\b(?:ti|te stesso|te stessa|ottieni|guadagni|ricevi|recuperi|subisci|perdi|bersaglio|avversario|nemico|alleat[oi]|compagn[oi])\b',
      caseSensitive: false,
    ).allMatches(before).toList();
    final subject = subjects.lastOrNull?.group(0)?.toLowerCase();
    if (subject != null &&
        (subject.startsWith('alleat') || subject.startsWith('compagn'))) {
      return 'alleato';
    }
    if (RegExp(
      r'\b(?:infligg\w*|caus\w*|colpisc\w*|attacc\w*|spara\w*)\b',
      caseSensitive: false,
    ).hasMatch(before)) {
      return 'bersaglio';
    }
    if (const {'bersaglio', 'avversario', 'nemico'}.contains(subject)) {
      return 'bersaglio';
    }
    if (subject != null) return 'se_stesso';
    if (RegExp(
      r'\b(?:all[’\x27]?|a|ad|ai|agli)\s*(?:(?:\d+|un|uno|una|due|tre|quattro|cinque|sei)\s+)?(?:alleat[oi]|compagn[oi])\b',
      caseSensitive: false,
    ).hasMatch(clause)) {
      return 'alleato';
    }
    return RegExp(
          r'\b(?:bersaglio|avversario|nemico)\b',
          caseSensitive: false,
        ).hasMatch(clause)
        ? 'bersaglio'
        : 'se_stesso';
  }

  bool claimed(RegExpMatch match) =>
      claims.any((span) => match.start < span.$2 && match.end > span.$1);
  for (final match in RegExp(
    r'\b(?:(?:evoca|evocare|crea|creare|convochi|convocare)\s+(?:un\s+)?(?:tuo\s+)?clone\s+d[\x27’]ombra|Ombra\s+viva)\b',
    caseSensitive: false,
  ).allMatches(text)) {
    if (claimed(match)) continue;
    final timing = durationAt(match);
    final durationValue = durationText(timing).trim();
    final durationLower = durationValue.toLowerCase();
    final durationExpression = timing == null ||
            durationLower.startsWith('oculum')
        ? 'oculum'
        : formula(durationValue);
    effects.add(
      OculumStructuredEffect(
        type: 'evocazione',
        target: 'clone_ombra',
        valueExpression: '10',
        mode: 'immediato',
        duration: durationExpression,
        durationUnit: 'turni',
        recipient: 'se_stesso',
        narrativeText: raw,
      ),
    );
    claims.add((match.start, match.end));
  }
  final targets = <String>[
    'Resilienza',
    'Volontà',
    'Materia',
    'Oculum',
    'VC',
    'CM',
    'Precisione',
    'Riflessi',
    ...subtraits.map((s) => s.nome),
  ];
  final targetPattern = targets.map(RegExp.escape).join('|');
  bool isSubtrait(String target) =>
      const {'precisione', 'riflessi'}.contains(oculumNormalizeText(target)) ||
      subtraits.any(
        (s) => oculumNormalizeText(s.nome) == oculumNormalizeText(target),
      );
  void statBonus(
    RegExpMatch match,
    String target,
    String value,
    bool negative,
  ) {
    add(
      isSubtrait(target) ? 'modifica_sottotratto' : 'modifica_statistica',
      value,
      target: target,
      mode: negative ? 'diminuzione' : 'aumento',
      recipient: recipientNear(match),
      at: match,
    );
    claims.add((match.start, match.end));
  }

  for (final match in RegExp(
    r'(?:Danni|Danno)\s*([+-])\s*(\d+)\s*%',
    caseSensitive: false,
  ).allMatches(text)) {
    add(
      'danno_percentuale',
      '${match[1] == '-' ? '-' : ''}${match[2]}',
      at: match,
    );
    claims.add((match.start, match.end));
  }
  for (final match in RegExp(
    r'([+-]?)(\d+)\s*%\s*(?:(?:dei\s+tuoi|ai|di)\s+)?dann\w*',
    caseSensitive: false,
  ).allMatches(text)) {
    if (claimed(match)) continue;
    final percentage = int.parse(match[2]!);
    add(
      'danno_percentuale',
      '${match[1] == '+'
          ? percentage
          : match[1] == '-'
          ? -percentage
          : percentage - 100}',
      at: match,
    );
    claims.add((match.start, match.end));
  }
  for (final match in RegExp(
    '([+-])\\s*($expression)\\s+($targetPattern)\\b',
    caseSensitive: false,
  ).allMatches(text)) {
    if (RegExp(
      r'(?:Danni|Danno|Difesa|Scudo)\s*$',
      caseSensitive: false,
    ).hasMatch(text.substring(0, match.start))) {
      continue;
    }
    if (!claimed(match)) {
      statBonus(match, match[3]!, match[2]!, match[1] == '-');
    }
  }
  for (final match in RegExp(
    '(?:aument\\w*|riduc\\w*|diminuisc\\w*)\\s+(?:la\\s+|il\\s+)?($targetPattern)\\s+di\\s+($expression)',
    caseSensitive: false,
  ).allMatches(text)) {
    if (claimed(match) ||
        text.substring(match.end).trimLeft().startsWith('%')) {
      continue;
    }
    statBonus(
      match,
      match[1]!,
      match[2]!,
      !oculumNormalizeText(match[0]!).startsWith('aument'),
    );
  }
  for (final match in RegExp(
    '([+-])\\s*($expression)\\s+(?:a\\s+)?tutt\\w*\\s+(?:le\\s+)?stat(?:istiche|s)?\\b',
    caseSensitive: false,
  ).allMatches(text)) {
    for (final target in const ['Resilienza', 'Volontà', 'Materia', 'Oculum']) {
      statBonus(match, target, match[2]!, match[1] == '-');
    }
  }
  for (final match in RegExp(
    '@?($targetPattern)\\s*([+-])\\s*($expression)',
    caseSensitive: false,
  ).allMatches(text)) {
    if (claimed(match) ||
        text.substring(match.end).trimLeft().startsWith('%')) {
      continue;
    }
    final target = match.group(1)!;
    add(
      oculumNormalizeText(target) == 'precisione' ||
              oculumNormalizeText(target) == 'riflessi' ||
              subtraits.any(
                (s) =>
                    oculumNormalizeText(s.nome) == oculumNormalizeText(target),
              )
          ? 'modifica_sottotratto'
          : 'modifica_statistica',
      match.group(3)!,
      target: target,
      mode: match.group(2) == '-' ? 'diminuzione' : 'aumento',
      recipient: recipientNear(match),
      at: match,
    );
    claims.add((match.start, match.end));
  }
  for (final match in RegExp(
    '([+-]?)\\s*($expression)\\s+(dann[oi]|Difesa|Scudo|Resistenza)\\b',
    caseSensitive: false,
  ).allMatches(text)) {
    if (claimed(match)) continue;
    final kind = oculumNormalizeText(match.group(3)!);
    add(
      kind.startsWith('dann')
          ? 'danno'
          : kind == 'difesa'
          ? 'difesa'
          : 'scudo',
      '${match.group(1) == '-' ? '-' : ''}${match.group(2)!}',
      recipient: recipientNear(match),
      at: match,
    );
    claims.add((match.start, match.end));
  }
  for (final match in RegExp(
    '(Danni|Danno|Difesa|Scudo)\\s*\\+\\s*($expression)',
    caseSensitive: false,
  ).allMatches(text)) {
    if (claimed(match)) continue;
    final kind = oculumNormalizeText(match.group(1)!);
    add(
      kind.startsWith('dann')
          ? 'danno'
          : kind == 'difesa'
          ? 'difesa'
          : 'scudo',
      match.group(2)!,
      recipient: recipientNear(match),
      at: match,
    );
    claims.add((match.start, match.end));
  }
  for (final match in RegExp(
    '(?:recuperi|recupera|curi|cura|rigeneri|rigenera|guarisci)\\s+($expression)\\s+(Vita|HP|Oculum)\\b',
    caseSensitive: false,
  ).allMatches(text)) {
    add(
      'cura',
      match.group(1)!,
      resource: oculumNormalizeText(match.group(2)!) == 'oculum'
          ? 'oculum'
          : 'vita',
      recipient: recipientNear(match),
      at: match,
    );
    claims.add((match.start, match.end));
  }
  for (final match in RegExp(
    '(?:ottieni|guadagni|ricevi|aggiungi|ti dai)\\s*\\+?\\s*($expression)\\s+(?:HP|Vita)\\s+temporane[io]\\b',
    caseSensitive: false,
  ).allMatches(text)) {
    if (durationMatches.isNotEmpty || claimed(match)) continue;
    add(
      'hp_temporanei',
      match[1]!,
      recipient: recipientNear(match),
      mode: 'immediato',
      at: match,
    );
    claims.add((match.start, match.end));
  }
  for (final match in RegExp(
    '\\b(?:muro|barriera)\\b[^;]*?assorb\\w*\\s+($expression)\\s+danni\\b',
    caseSensitive: false,
  ).allMatches(text)) {
    if (claims.any((span) => span.$1 < match.end && span.$2 > match.start)) {
      effects.removeWhere(
        (e) => e.type == 'danno' && e.valueExpression == formula(match[1]!),
      );
    }
    add('scudo', match[1]!, mode: 'immediato', at: match);
    claims.add((match.start, match.end));
  }
  for (final match in RegExp(
    r'\b(?:perde|perdi|rimuovi|sottrai|consuma)\s+(\d+|una?|due|tre)\s+Reazion\w*(\s+rapid\w*)?',
    caseSensitive: false,
  ).allMatches(text)) {
    final value = switch (match[1]!.toLowerCase()) {
      'un' || 'una' => '1',
      'due' => '2',
      'tre' => '3',
      final value => value,
    };
    add(
      match[2] == null ? 'rimuovi_reazioni' : 'rimuovi_reazioni_rapide',
      value,
      recipient: recipientNear(match),
      at: match,
    );
    claims.add((match.start, match.end));
  }
  final resistance = RegExp(
    r'\b(Alta\s+Resistenza|Resistenza\s+Alta|Resistenza\s+Leggera|Fragilit[aà]\s+Leggera|Alta\s+Fragilit[aà]|Fragilit[aà]|Resistenza|Immunit[aà])\s+(?:a|al|alla|ai|agli)\s+(.+?)(?=\s+per\s+|$)',
    caseSensitive: false,
  ).firstMatch(text);
  if (resistance != null) {
    final names = resistance[2]!.split(
      RegExp(r'\s+e\s+|,', caseSensitive: false),
    );
    var known = true;
    final elements = <String>[];
    for (final name in names) {
      final id = oculumNormalizeElementId(
        name.trim().replaceFirst(
          RegExp(r'^(?:danni?\s+)?(?:da\s+)?', caseSensitive: false),
          '',
        ),
      );
      if (!oculumDefaultElementIds.contains(id)) {
        known = false;
        break;
      }
      elements.add(id);
    }
    if (known && elements.isNotEmpty) {
      for (final element in elements.toSet()) {
        final effect = OculumStructuredEffect(
          type: 'elemental_resistance',
          elementType: element,
          customDisplayText: resistance[1]!,
          valueExpression: '0',
          mode: 'finche_attivo',
          duration: durationMatch == null ? '-1' : formula(duration),
          durationUnit: unit,
          recipient: recipientNear(resistance),
          narrativeText: raw,
        );
        effects.add(effect);
      }
      claims.add((resistance.start, resistance.end));
    }
  }
  final stateNames = <String, String>{
    for (final definition in oculumConditionCatalog)
      definition.nameIt: definition.id,
  };
  final statePattern = stateNames.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final match in RegExp(
    '(?:applichi|applica|infliggi|infligge|ottieni|ricevi|subisci|diventi|diventa)\\s+(?:(?:lo stato|la condizione|stato|condizione)\\s+)?(${statePattern.map(RegExp.escape).join('|')})(?:\\s+(?:(?:grado|stadio)\\s*)?(VI|IV|V|III|II|I|\\d+))?\\b',
    caseSensitive: false,
  ).allMatches(text)) {
    if (claimed(match)) continue;
    final name = stateNames.keys.firstWhere(
      (n) => n.toLowerCase() == match[1]!.toLowerCase(),
    );
    final timing = durationAt(match);
    effects.add(
      OculumStructuredEffect(
        type: 'stato',
        appliedState: stateNames[name]!,
        valueExpression:
            const {
              'I': '1',
              'II': '2',
              'III': '3',
              'IV': '4',
              'V': '5',
              'VI': '6',
            }[match[2]?.toUpperCase()] ??
            match[2] ??
            '1',
        recipient: recipientNear(match),
        duration: timing == null ? '' : formula(durationText(timing)),
        durationUnit: durationUnit(timing),
        narrativeText: raw,
      ),
    );
    claims.add((match.start, match.end));
  }
  for (final match in RegExp(
    r'(?:ottieni|concede?|guadagni)\s+(?:\+\s*)?(\d+|una?|due|tre)\s+(?:energia\s+)?Reazion\w*',
    caseSensitive: false,
  ).allMatches(text)) {
    add(
      'aggiungi_reazioni',
      switch (match.group(1)!.toLowerCase()) {
        'una' || 'un' => '1',
        'due' => '2',
        'tre' => '3',
        final value => value,
      },
      recipient: recipientNear(match),
      at: match,
    );
    claims.add((match.start, match.end));
  }
  for (final match in RegExp(
    r'\+(\d+)\s*%\s*(?:a[il]?\s+)?dann\w*',
    caseSensitive: false,
  ).allMatches(text)) {
    if (claimed(match)) continue;
    add(
      'danno_percentuale',
      match.group(1)!,
      recipient: recipientNear(match),
      at: match,
    );
    claims.add((match.start, match.end));
  }
  for (final entry in <String, String>{
    r'\b(?:immobilizzi|immobilizza|imprigioni|imprigiona)\b': 'immobilizzato',
    r'\b(?:rallenti|rallenta)\b': 'rallentato',
    r'\b(?:stordisci|stordisce)\b': 'stordito',
  }.entries) {
    final match = RegExp(entry.key, caseSensitive: false).firstMatch(text);
    if (match == null) continue;
    final context = text.substring(
      max(0, match.start - 30),
      min(text.length, match.end + 80),
    );
    if (!RegExp(
      r'\b(?:bersaglio|avversario|nemico)\b',
      caseSensitive: false,
    ).hasMatch(context)) {
      continue;
    }
    effects.add(
      OculumStructuredEffect(
        id: 'parsed_${sourceKey}_state_${entry.value}',
        type: 'stato',
        appliedState: entry.value,
        recipient: 'bersaglio',
        valueExpression: '1',
        duration: duration,
        durationUnit: unit,
        narrativeText: raw,
      ),
    );
    claims.add((match.start, match.end));
  }
  // A recognized numeric rule does not imply its entire story was understood.
  final remainder = StringBuffer();
  var cursor = 0;
  claims.sort((a, b) => a.$1.compareTo(b.$1));
  for (final span in claims) {
    if (span.$1 > cursor) remainder.write(text.substring(cursor, span.$1));
    cursor = max(cursor, span.$2);
  }
  if (cursor < text.length) remainder.write(text.substring(cursor));
  return OculumFreeTextEffectParseResult(
    effects: effects,
    unrecognizedText: remainder.toString().trim(),
  );
}
