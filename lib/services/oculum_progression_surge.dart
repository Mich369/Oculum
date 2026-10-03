/// Earned progression rewards, kept separate from arbitrary temporary buffs.
class OculumProgressionSurge {
  int freshLevels;
  int restedLevels;
  int freshGrades;
  int restedGrades;
  int shield;

  OculumProgressionSurge({
    this.freshLevels = 0,
    this.restedLevels = 0,
    this.freshGrades = 0,
    this.restedGrades = 0,
    this.shield = 0,
  });

  int get statBonus =>
      freshLevels * 3 +
      restedLevels * 2 +
      freshGrades * 5 +
      (restedGrades * 5 ~/ 2);

  void gainLevels(int count) {
    if (count > 0) freshLevels += count;
  }

  void gainGrades(int count) {
    if (count <= 0) return;
    freshGrades += count;
    shield += count * 100;
  }

  void shortRest() {
    restedLevels += freshLevels;
    freshLevels = 0;
    restedGrades += freshGrades;
    freshGrades = 0;
  }

  void longRest() {
    freshLevels = restedLevels = freshGrades = restedGrades = 0;
    shield ~/= 2;
  }

  Map<String, dynamic> toJson() => {
    'freshLevels': freshLevels,
    'restedLevels': restedLevels,
    'freshGrades': freshGrades,
    'restedGrades': restedGrades,
    'shield': shield,
  };
  factory OculumProgressionSurge.fromJson(dynamic value) {
    final map = value is Map ? value : const {};
    int read(String key) => int.tryParse('${map[key]}')?.clamp(0, 1000000) ?? 0;
    return OculumProgressionSurge(
      freshLevels: read('freshLevels'),
      restedLevels: read('restedLevels'),
      freshGrades: read('freshGrades'),
      restedGrades: read('restedGrades'),
      shield: read('shield'),
    );
  }
}
