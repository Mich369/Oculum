import 'oculum_diary_memory.dart';

const diaryLinkTypes = <String, String>{
  'character': 'personaggio',
  'creature': 'creatura',
  'npc': 'png',
  'place': 'luogo',
  'item': 'oggetto',
  'quest': 'missione',
  'event': 'evento',
};

({int start, String query})? diaryLinkQuery(String text, int cursor) {
  if (cursor < 0 || cursor > text.length) return null;
  final windowStart = (cursor - 256).clamp(0, cursor);
  final before = text.substring(windowStart, cursor);
  final bracket = before.lastIndexOf('[');
  if (bracket < 0) return null;
  final query = before.substring(bracket + 1);
  if (query.contains(']') || query.contains('\n')) return null;
  final start = windowStart + bracket;
  return (
    start: start > 0 && text[start - 1] == '[' ? start - 1 : start,
    query: query.trim().toLowerCase(),
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
  for (final entity in catalogue) {
    final type = diaryLinkTypes[entity.kind];
    if (type == null) continue;
    final typed = '$type:${entity.name}';
    final query = active.query;
    if (query.isEmpty ||
        typed.toLowerCase().contains(query) ||
        entity.aliases.any((alias) => alias.toLowerCase().contains(query))) {
      matches.add('[[$typed]]');
      if (matches.length >= limit) break;
    }
  }
  if (matches.isEmpty && active.query.isEmpty) {
    matches.addAll(diaryLinkTypes.values.take(limit).map((t) => '[[$t:]]'));
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
