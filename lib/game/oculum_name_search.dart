/// Scores a literal name match. Both arguments are already normalized.
int oculumNameMatchScore(String query, String name) {
  if (query.isEmpty || name.isEmpty) return 0;
  if (query == name) return 1000;
  if (!name.contains(query)) return 0;

  final extra = (name.length - query.length).clamp(0, 49);
  if (name.startsWith(query)) return 900 - extra;
  if ('$name '.contains(' $query ')) return 800 - extra;
  if (name.contains(' $query')) return 700 - extra;
  return 600 - extra;
}

const _projectileNames = [
  'sparo energetico',
  'spari energetici',
  'energy shot',
  'energy shots',
  'sfera',
  'sfere',
  'dardo',
  'dardi',
  'palla',
  'palle',
  'sphere',
  'spheres',
  'bolt',
  'bolts',
  'ball',
  'balls',
  'orb',
  'orbs',
];

/// Adds related terms for searching names, without altering displayed labels.
class OculumNameQuery {
  OculumNameQuery(this.normalized)
    : _qualifiers = _projectileQualifiers(normalized);

  final String normalized;
  final List<String>? _qualifiers;

  bool get hasRelatedNames => _qualifiers != null;

  int score(String normalizedName) {
    final literal = oculumNameMatchScore(normalized, normalizedName);
    final qualifiers = _qualifiers;
    if (literal > 0 || qualifiers == null || normalizedName.isEmpty) {
      return literal;
    }
    final words = ' $normalizedName ';
    return qualifiers.every(normalizedName.contains) &&
            _projectileNames.any((term) => words.contains(' $term '))
        ? 520
        : 0;
  }

  int rank(int nameScore, {required bool preferredElement}) =>
      hasRelatedNames && preferredElement && nameScore >= 520
      ? nameScore + 1000
      : nameScore;

  static List<String>? _projectileQualifiers(String query) {
    final padded = ' $query ';
    var words = padded;
    for (final term in _projectileNames) {
      words = words.replaceAll(' $term ', ' ');
    }
    if (words == padded) return null;
    return words
        .trim()
        .split(' ')
        .where(
          (word) =>
              word.isNotEmpty &&
              !const {
                'd',
                'di',
                'del',
                'della',
                'dei',
                'delle',
                'of',
                'the',
              }.contains(word),
        )
        .toList(growable: false);
  }
}
