part of '../../main.dart';

// A small multinomial text classifier for the existing summon vocabulary.
// Its training phrases contain no player data. Only the editor uses it.
const _skillSummonExamples = <String, List<String>>{
  'patalpa_compagno': [
    'evoca un patalpa',
    'richiama il compagno patalpa',
    'chiama un altro patalpa',
    'summon a patalpa companion',
  ],
  'un_vecchio_amore': [
    'evoca un vecchio amore',
    'richiama un vecchio amore',
    'chiama il tuo vecchio amore',
    'summon an old love',
  ],
  'clone_ombra': [
    'evoca un clone di ombra',
    'richiama il clone ombra',
    'crea un doppio d ombra',
    'summon a shadow clone',
  ],
  '': [
    'descrive un animale che accompagna il gruppo',
    'attacca il patalpa nemico',
    'il clone riceve danni',
    'cura un vecchio amore',
    'costa vita e dura tre turni',
    'the spell damages a shadow clone',
    'an old love appears in a story',
  ],
};

Iterable<String> _skillDraftWords(String text) => RegExp(
  r'[a-z0-9]+',
).allMatches(oculumNormalizeText(text)).map((m) => m[0]!);

final _skillSummonWordCounts = _skillSummonExamples.map((label, phrases) {
  final counts = <String, int>{};
  for (final phrase in phrases) {
    for (final word in _skillDraftWords(phrase)) {
      counts.update(word, (n) => n + 1, ifAbsent: () => 1);
    }
  }
  return MapEntry(label, counts);
});

final _skillSummonVocabulary = _skillSummonWordCounts.values
    .expand((counts) => counts.keys)
    .toSet();

String _skillDraftSummonClass(String text) {
  final words = _skillDraftWords(text).where(_skillSummonVocabulary.contains);
  final scores = <(String, double)>[];
  for (final entry in _skillSummonWordCounts.entries) {
    final count = entry.value.values.fold(0, (sum, n) => sum + n);
    final probability = words.fold<double>(
      log(_skillSummonExamples[entry.key]!.length),
      (score, word) =>
          score +
          log(
            ((entry.value[word] ?? 0) + 1) /
                (count + _skillSummonVocabulary.length),
          ),
    );
    scores.add((entry.key, probability));
  }
  scores.sort((a, b) => b.$2.compareTo(a.$2));
  return scores[0].$2 - scores[1].$2 >= log(2) ? scores[0].$1 : '';
}

OculumFreeTextEffectParseResult oculumRecognizeSkillDraft(
  String text, {
  Iterable<HiddenEyeStat> subtraits = const [],
}) {
  final parsed = oculumParseAbilityMechanics(text, subtraits: subtraits);
  final effects = [...parsed.effects];
  final remaining = <String>[];
  for (final raw in parsed.unrecognizedText.split(';')) {
    final phrase = raw.trim();
    if (phrase.isEmpty) continue;
    final normalized = _skillDraftWords(phrase).join(' ');
    final summon = RegExp(
      r'^(?:evoca|richiama|chiama|crea|summon) (?:un |una |il |a |an |the )?(patalpa(?: compagno)?|compagno patalpa|vecchio amore|old love|(?:clone (?:di |d )?ombra|doppio d ombra|shadow clone) (?:con |with )?(\d+) (?:vita|hp) (?:per |for )(\d+) (?:turn\w*))$',
    ).firstMatch(normalized);
    if (summon == null) {
      remaining.add(phrase);
      continue;
    }
    final identity = summon[1]!;
    final supported = identity.contains('patalpa')
        ? 'patalpa_compagno'
        : identity.contains('amore') || identity == 'old love'
        ? 'un_vecchio_amore'
        : 'clone_ombra';
    final hp = int.tryParse(summon[2] ?? '');
    final turns = int.tryParse(summon[3] ?? '');
    if (_skillDraftSummonClass(normalized) != supported ||
        supported == 'clone_ombra' && ((hp ?? 0) <= 0 || (turns ?? 0) <= 0)) {
      remaining.add(phrase);
      continue;
    }
    final effect = OculumStructuredEffect(
      type: 'evocazione',
      target: supported,
      valueExpression: hp?.toString() ?? '',
      duration: turns?.toString() ?? '',
      narrativeText: phrase,
    );
    final key = oculumStructuredEffectSemanticKey(effect);
    if (!effects.any(
      (entry) => oculumStructuredEffectSemanticKey(entry) == key,
    )) {
      effects.add(effect);
    }
  }
  return OculumFreeTextEffectParseResult(
    effects: effects,
    unrecognizedText: remaining.join('; '),
  );
}
