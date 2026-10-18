part of '../../main.dart';

({int minimum, int maximum, String resource})? oculumParseAbilityCost(
  String raw,
) {
  final range = RegExp(
    r'\(?\s*(\d+)\s*[/–-]\s*(\d+)\s*(Oculum|Volontà|Materia)?\s*\)?',
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
  final fixed = RegExp(
    r'(?:spendi|costa|costo\s*:?|consumi)\s*(\d+)\s*(Oculum|Volontà|Materia)',
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
  final effects = <OculumStructuredEffect>[];
  // Stable across platforms and reloads: different texts have distinct IDs.
  final sourceKey = raw.codeUnits
      .fold<int>(17, (hash, unit) => (hash * 31 + unit) % 2147483647)
      .toRadixString(16);
  final seen = <String>{};
  var text = oculumCleanMojibakeText(raw)
      .replaceAll('−', '-')
      .replaceAll('×', '*')
      .replaceAll(RegExp(r'\b(?:III|II|IV|V|I)/'), '')
      .replaceAll(RegExp(r'Costo\s*:[^\n.]*[.\n]?', caseSensitive: false), '')
      .replaceAll(
        RegExp(r'Richiede\s+(?:livello|lvl)\s*\d+\.?', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'\bLivello\s+\d+\s*[:,]?', caseSensitive: false), '')
      .replaceAll(
        RegExp(
          r'\(\s*\d+\s*[/–-]\s*\d+\s*(?:Oculum)?[^)]*\)',
          caseSensitive: false,
        ),
        '',
      );
  final durationMatch = RegExp(
    r'(?:per|dura(?:ta)?\s*:?|fino a)\s*(\d+|un|uno|due|tre|tutto il)\s*(turn\w*|tir\w*|azion\w*)',
    caseSensitive: false,
  ).firstMatch(text);
  final duration = switch (durationMatch?.group(1)?.toLowerCase()) {
    'un' || 'uno' || 'tutto il' => '1',
    'due' => '2',
    'tre' => '3',
    final String value => value,
    _ => '1',
  };
  final unit = durationMatch?.group(2)?.toLowerCase().startsWith('tir') == true
      ? 'tiri'
      : 'turni';
  String formula(String value) => value
      .trim()
      .replaceAll(
        RegExp(
          r'\bOculum\s+(?:immesso|speso|investito)\b',
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
  }) {
    final expression = formula(value);
    final key = '$type|$target|$expression|$recipient';
    if (!seen.add(key)) return;
    effects.add(
      OculumStructuredEffect(
        id: 'parsed_${sourceKey}_${effects.length}_${type}_${target.replaceAll(' ', '_')}',
        type: type,
        target: target,
        valueExpression: expression,
        recipient: recipient,
        resource: resource,
        mode:
            mode ??
            (type == 'danno' || type == 'danno_percentuale'
                ? durationMatch == null
                      ? 'prossima_azione'
                      : 'finche_attivo'
                : type == 'scudo' || type == 'cura'
                ? 'immediato'
                : 'aumento'),
        duration: type == 'cura' || type == 'scudo' ? '' : duration,
        durationUnit: unit,
        narrativeText: raw,
      ),
    );
  }

  // Tokens deliberately exclude costs, levels, DT and unknown identifiers.
  const atom =
      r'(?:\d+(?:[.,]\d+)?(?:d\d+)?|\d*d\d+|oculum_spent|Oculum\s+(?:immesso|speso|investito)|Oculum|OCU|Danni|Materia|Resilienza|Volontà|Medicina|Vita\s+(?:attuale|rimanente|massima))';
  const expression = '$atom(?:\\s*[+*/-]\\s*$atom)*';
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
    if (RegExp(
      r'\b(?:ti|tuo|tua|perdi|subisci)\b',
      caseSensitive: false,
    ).hasMatch(clause)) {
      return 'se_stesso';
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
  for (final match in RegExp(
    '@?($targetPattern)\\s*([+-])\\s*($expression)',
    caseSensitive: false,
  ).allMatches(text)) {
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
      recipient: match.group(2) == '-' ? recipientNear(match) : 'se_stesso',
    );
    claims.add((match.start, match.end));
  }
  for (final match in RegExp(
    '([+-]?)\\s*($expression)\\s+(dann[oi]|Difesa|Scudo)\\b',
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
    );
    claims.add((match.start, match.end));
  }
  for (final match in RegExp(
    '(?:recuperi|curi|rigeneri)\\s+($expression)\\s+(Vita|HP|Oculum)\\b',
    caseSensitive: false,
  ).allMatches(text)) {
    add(
      'cura',
      match.group(1)!,
      resource: oculumNormalizeText(match.group(2)!) == 'oculum'
          ? 'oculum'
          : 'vita',
    );
    claims.add((match.start, match.end));
  }
  for (final match in RegExp(
    r'(?:ottieni|concede?|guadagni)\s+(?:\+\s*)?(\d+|una?|due|tre)\s+(?:energia\s+)?Reazion\w*',
    caseSensitive: false,
  ).allMatches(text)) {
    add('aggiungi_reazioni', switch (match.group(1)!.toLowerCase()) {
      'una' || 'un' => '1',
      'due' => '2',
      'tre' => '3',
      final value => value,
    });
    claims.add((match.start, match.end));
  }
  for (final match in RegExp(
    r'\+(\d+)\s*%\s*(?:a[il]?\s+)?dann\w*',
    caseSensitive: false,
  ).allMatches(text)) {
    add('danno_percentuale', match.group(1)!);
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
