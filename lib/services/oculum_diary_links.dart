import 'oculum_diary_memory.dart';

const diaryLinkTypes = <String, String>{
  'character': 'personaggio',
  'creature': 'creatura',
  'npc': 'png',
  'place': 'luogo',
  'item': 'oggetto',
  'quest': 'missione',
  'event': 'evento',
  'party': 'Party',
  'enemy': 'Nemico',
  'dead': 'Morto',
  'obliterated': 'Obliterato',
  'weapon': 'Arma',
  'armor': 'Armatura',
  'shield': 'Scudo',
  'fallen_eye': 'Occhio dei Caduti',
  'art': 'Art',
  'title': 'Titolo',
  'faction': 'Fazione',
};

const diaryCreationLinkTypes = [
  'Party',
  'Alleato',
  'Personaggio',
  'NPC',
  'Mostro',
  'Nemico',
  'Morto',
  'Obliterato',
  'Ambiente',
  'Luogo',
  'Arma',
  'Armatura',
  'Scudo',
  'Oggetto',
  'Occhio dei Caduti',
  'Art',
  'Titolo',
  'Fazione',
  'Missione',
  'Evento',
];

final _diarySavedLinks = RegExp(r'\[\[([^\]\n]+)\]\]');

List<DiaryEntity> diaryEntitiesFromLinks(Iterable<String> texts) {
  final learned = <String, DiaryEntity>{};
  for (final text in texts) {
    for (final match in _diarySavedLinks.allMatches(text)) {
      final raw = match[1]!.split('|').first.trim();
      final colon = raw.indexOf(':');
      final name = (colon < 0 ? raw : raw.substring(colon + 1)).trim();
      final type = colon < 0 ? null : raw.substring(0, colon).trim();
      if (name.isEmpty) continue;
      final kind = type == null
          ? 'unknown'
          : diaryLinkKindByType[diaryKey(type)] ?? 'unknown';
      final key = '${type?.toLowerCase() ?? ''}:${diaryKey(name)}';
      learned[key] = DiaryEntity('link:$key', name, kind, const [], type);
    }
  }
  return learned.values.toList();
}

({int start, String query})? diaryLinkQuery(String text, int cursor) {
  if (cursor < 0 || cursor > text.length) return null;
  final windowStart = (cursor - 256).clamp(0, cursor);
  final before = text.substring(windowStart, cursor);
  var bracket = before.lastIndexOf('[[');
  final singleBracket = before.lastIndexOf('[');
  if (bracket < 0 ||
      (singleBracket > bracket + 1 &&
          before.substring(bracket + 2, singleBracket).contains(']'))) {
    bracket = singleBracket;
  }
  if (bracket < 0) return null;
  var query = before.substring(
    bracket + (before.startsWith('[[', bracket) ? 2 : 1),
  );
  // Accept a completed, untyped link and the optional classification marker [].
  if (query.endsWith(']]') && !query.contains(':')) {
    query = query.substring(0, query.length - 2);
  }
  if (query.endsWith('[]')) query = query.substring(0, query.length - 2);
  if (query.endsWith('[')) query = query.substring(0, query.length - 1);
  if (query.contains(']') || query.contains('\n')) return null;
  final start = windowStart + bracket;
  return (
    start: start > 0 && text[start - 1] == '[' ? start - 1 : start,
    query: query.trim(),
  );
}

List<String> diaryLinkCompletions(
  String text,
  int cursor,
  List<DiaryEntity> catalogue, {
  int limit = 8,
}) {
  final active = diaryLinkQuery(text, cursor);
  if (active == null) return const [];
  final matches = <String>{};
  final untyped = <String>{};
  String? untypedName;
  final colon = active.query.indexOf(':');
  final requestedType = colon < 0
      ? null
      : active.query.substring(0, colon).trim();
  final requestedKind = requestedType == null
      ? null
      : diaryLinkKindByType[requestedType.toLowerCase()];
  final requestedName = colon < 0
      ? ''
      : active.query.substring(colon + 1).trim().toLowerCase();
  for (final entity in catalogue) {
    final type = entity.linkType ?? diaryLinkTypes[entity.kind];
    final typed = type == null ? entity.name : '$type:${entity.name}';
    final query = active.query.toLowerCase();
    if (query.isEmpty ||
        typed.toLowerCase().contains(query) ||
        (requestedKind != null &&
            entity.kind == requestedKind &&
            (entity.name.toLowerCase().contains(requestedName) ||
                entity.aliases.any(
                  (alias) => alias.toLowerCase().contains(requestedName),
                ))) ||
        entity.aliases.any((alias) => alias.toLowerCase().contains(query))) {
      if (type == null) {
        untyped.add('[[$typed]]');
        untypedName ??= entity.name;
        continue;
      }
      matches.add(
        requestedKind == entity.kind && requestedType != null
            ? '[[$requestedType:${entity.name}]]'
            : '[[$typed]]',
      );
      if (matches.length >= limit) break;
    }
  }
  if (matches.isEmpty && !active.query.contains(':')) {
    matches.addAll(untyped);
    matches.addAll(
      diaryCreationLinkTypes.map(
        (t) => '[[$t:${untypedName ?? active.query}]]',
      ),
    );
  }
  return matches.toList();
}

({String text, int cursor})? diaryInsertLink(
  String text,
  int cursor,
  String suggestion,
) {
  final active = diaryLinkQuery(text, cursor);
  if (active == null ||
      !suggestion.startsWith('[[') ||
      !suggestion.endsWith(']]')) {
    return null;
  }
  var end = cursor;
  // Complete an existing link without duplicating its closing brackets.
  final tail = text.substring(
    cursor,
    (cursor + 256).clamp(cursor, text.length),
  );
  final close = tail.indexOf(']');
  if (close >= 0 && !tail.substring(0, close).contains(RegExp(r'[\n\[]'))) {
    end += close + 1;
    if (end < text.length && text[end] == ']') end++;
  }
  return (
    text: text.replaceRange(active.start, end, suggestion),
    cursor: active.start + suggestion.length,
  );
}
