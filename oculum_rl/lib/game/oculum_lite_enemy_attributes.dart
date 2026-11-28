part of 'oculum_lite_run.dart';

enum LiteEnemyRole {
  equilibrato,
  assaltatore,
  difensore,
  tiratore,
  incantatore,
}

class LiteEnemyProfile {
  const LiteEnemyProfile._(
    this.role,
    this.difficulty,
    this.originFloor,
    this.attributes,
    this.applyBalance,
  );

  final LiteEnemyRole role;
  final LiteDifficulty difficulty;
  final int originFloor;
  final LiteAttributes attributes;
  final bool applyBalance;

  static LiteEnemyProfile forKind(
    LiteEnemyKind kind,
    LiteDifficulty difficulty, {
    required int originFloor,
    bool champion = false,
    bool applyBalance = true,
  }) {
    final floor = originFloor.clamp(0, 120);
    final rank = kind.boss
        ? 10
        : kind.elite || champion
        ? 5
        : 0;
    final budget = 40 + floor ~/ 2 + 3 * difficulty.index + rank;
    final role = _roleFor(kind);
    final shares = switch (role) {
      LiteEnemyRole.equilibrato => const [10, 10, 10, 10],
      LiteEnemyRole.assaltatore => const [11, 15, 8, 6],
      LiteEnemyRole.difensore => const [15, 8, 13, 4],
      LiteEnemyRole.tiratore => const [8, 12, 12, 8],
      LiteEnemyRole.incantatore => const [7, 9, 8, 16],
    };
    var allocated = 0, consumed = 0;
    final points = <int>[];
    for (final share in shares) {
      consumed += share;
      final total = (budget * consumed + 20) ~/ 40;
      points.add(total - allocated);
      allocated = total;
    }
    return LiteEnemyProfile._(
      role,
      difficulty,
      floor,
      LiteAttributes(
        resilienza: points[0],
        volonta: points[1],
        materia: points[2],
        oculum: points[3],
      ),
      applyBalance &&
          !kind.echo &&
          kind != LiteEnemyKind.luce &&
          kind != LiteEnemyKind.ombra,
    );
  }

  static LiteEnemyRole _roleFor(LiteEnemyKind kind) => switch (kind) {
    LiteEnemyKind.costrutto ||
    LiteEnemyKind.miruscyrus ||
    LiteEnemyKind.guardianoLunare ||
    LiteEnemyKind.guardianoSolare ||
    LiteEnemyKind.custodeLunare ||
    LiteEnemyKind.aberrazioneSolare ||
    LiteEnemyKind.armadilloCorazzato ||
    LiteEnemyKind.vegliante ||
    LiteEnemyKind.sacrycrab ||
    LiteEnemyKind.gelycryn => LiteEnemyRole.difensore,
    LiteEnemyKind.veyrth ||
    LiteEnemyKind.arconte ||
    LiteEnemyKind.diavolo ||
    LiteEnemyKind.funerys ||
    LiteEnemyKind.vesanybel ||
    LiteEnemyKind.lapysrieth ||
    LiteEnemyKind.nymboryth ||
    LiteEnemyKind.aerovyr ||
    LiteEnemyKind.baghest ||
    LiteEnemyKind.bunnys => LiteEnemyRole.incantatore,
    LiteEnemyKind.scostubandito ||
    LiteEnemyKind.granScostumato ||
    LiteEnemyKind.dronePostea ||
    LiteEnemyKind.ragnoSaldatore ||
    LiteEnemyKind.goblinFango ||
    LiteEnemyKind.goblinColla => LiteEnemyRole.tiratore,
    LiteEnemyKind.forestDemon ||
    LiteEnemyKind.babyForestDemon ||
    LiteEnemyKind.rasvyr ||
    LiteEnemyKind.lupoLunare ||
    LiteEnemyKind.goblinColtello ||
    LiteEnemyKind.demoneMinore ||
    LiteEnemyKind.demoneMaggiore ||
    LiteEnemyKind.divoramitu ||
    LiteEnemyKind.divoramituBoss ||
    LiteEnemyKind.thalvyr ||
    LiteEnemyKind.corrottoRosso => LiteEnemyRole.assaltatore,
    _ => LiteEnemyRole.equilibrato,
  };

  // The encounter already scales with floor and difficulty. Relative shares
  // tune the role without applying those absolute increases a second time.
  double _scale(double stat, double strength, double limit) => applyBalance
      ? 1 + ((stat / attributes.total - .25) * strength).clamp(-limit, limit)
      : 1;

  double get lifeScale => _scale(attributes.resilienza.toDouble(), .40, .04);
  double get attackScale {
    final arcane = role == LiteEnemyRole.incantatore;
    final power =
        attributes.volonta * (arcane ? .25 : .80) +
        attributes.oculum * (arcane ? .75 : .20);
    return _scale(power, .45, .04);
  }

  double get reachScale => _scale(attributes.volonta.toDouble(), .32, .04);
  double get recoveryRate => _scale(attributes.materia.toDouble(), .32, .03);

  List<Object> get _frame => [
    role.name,
    difficulty.name,
    originFloor,
    attributes.resilienza,
    attributes.volonta,
    attributes.materia,
    attributes.oculum,
    applyBalance,
  ];

  static LiteEnemyProfile? _read(Object? frame) {
    if (frame is! List ||
        frame.length != 8 ||
        frame[2] is! int ||
        frame[7] is! bool) {
      return null;
    }
    final role = LiteEnemyRole.values
        .where((entry) => entry.name == frame[0])
        .firstOrNull;
    final difficulty = LiteDifficulty.values
        .where((entry) => entry.name == frame[1])
        .firstOrNull;
    final floor = frame[2] as int;
    final stats = frame.sublist(3, 7);
    if (role == null ||
        difficulty == null ||
        floor < 0 ||
        floor > 120 ||
        stats.any((value) => value is! int || value < 1 || value > 120)) {
      return null;
    }
    return LiteEnemyProfile._(
      role,
      difficulty,
      floor,
      LiteAttributes(
        resilienza: stats[0] as int,
        volonta: stats[1] as int,
        materia: stats[2] as int,
        oculum: stats[3] as int,
      ),
      frame[7] as bool,
    );
  }
}
