import 'dart:math' as math;

const oculumFrutibushId = 'frutibush';
const oculumFrutibushHealSkill = 'frutibush_cura';
const oculumFrutibushLeafSkill = 'frutibush_foglie_lama';
const oculumFrutibushLeafCaps = [3, 6, 12];

/// Prepare one packet per leaf. Every leaf receives its share of the base
/// damage; only the first leaf assigned to each enemy carries its +10.
List<int> oculumFrutibushLeafDamage({
  required int totalDamage,
  required int grade,
  required int form,
  required List<String> enemyTags,
}) {
  if (form < 1 ||
      form > oculumFrutibushLeafCaps.length ||
      enemyTags.isEmpty ||
      enemyTags.length > oculumFrutibushLeafCaps[form - 1] ||
      enemyTags.any((tag) => tag.isEmpty)) {
    return const [];
  }
  final base = math.max(0, totalDamage) + math.max(5, grade * 25);
  final share = base ~/ enemyTags.length;
  final remainder = base % enemyTags.length;
  final firstHits = <String>{};
  return [
    for (final (index, tag) in enemyTags.indexed)
      share + (index < remainder ? 1 : 0) + (firstHits.add(tag) ? 10 : 0),
  ];
}
