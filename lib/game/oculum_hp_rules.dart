import 'dart:math';

/// Grade 0 gains one multiplier point per level until level 4. Higher Grades
/// retain their decade progression. A missing level preserves legacy data.
int oculumHpMultiplierForGrade(int grade, {int? level}) {
  final normalizedGrade = grade.clamp(0, 12).toInt();
  if (level == null) return 10 + 5 * normalizedGrade;
  if (normalizedGrade == 0) return min(10, 6 + max(0, level));
  final levelInGrade = max(0, level) % 10;
  final base = levelInGrade == 0
      ? 6
      : levelInGrade <= 2
      ? 9
      : 10;
  return base + 5 * normalizedGrade;
}

int oculumHpTotalPowerBonusForGrade(int grade, {int? level}) =>
    oculumHpMultiplierForGrade(grade, level: level) ~/ (grade <= 0 ? 10 : 5);
