part of 'oculum_lite_run.dart';

class LiteAlertCall {
  const LiteAlertCall._(
    this.sequence,
    this.time, {
    this.enemy,
    this.hero,
    this.fiveFlames = false,
    this.viewerId,
  });

  final int sequence;
  final double time;
  final LiteEnemyKind? enemy;
  final LiteHero? hero;
  final bool fiveFlames;
  final int? viewerId;

  List<Object?> get _frame => [
    sequence,
    time,
    enemy?.name,
    hero?.name,
    fiveFlames,
    viewerId,
  ];

  static LiteAlertCall? _read(Object? raw, double now) {
    if (raw is! List || raw.length != 6 || raw[0] is! int || raw[1] is! num) {
      return null;
    }
    final at = _num(raw[1]);
    if (at < 0 || at > now || now - at > _LiteAlertSignals.cueLifetime) {
      return null;
    }
    final enemy = LiteEnemyKind.values
        .where((kind) => kind.name == raw[2])
        .firstOrNull;
    final hero = LiteHero.values
        .where((hero) => hero.name == raw[3])
        .firstOrNull;
    if (enemy == null && hero == null) return null;
    return LiteAlertCall._(
      _int(raw[0]),
      at,
      enemy: enemy,
      hero: hero,
      fiveFlames: raw[4] == true,
      viewerId: raw[5] is int ? raw[5] as int : null,
    );
  }
}

class _LiteAlertSignals {
  static const delay = 3.0;
  static const cueLifetime = 4.0;
  static const maxCues = 16;

  String? arena;
  var sequence = 0;
  final enemyTimers = <int, double>{};
  bool groupCalled = false;
  final cues = <LiteAlertCall>[];

  void add(double at, {LiteEnemy? enemy, LiteHero? hero, int? viewerId}) {
    if (cues.length == maxCues) cues.removeAt(0);
    cues.add(
      LiteAlertCall._(
        ++sequence,
        at,
        enemy: enemy?.kind,
        hero: hero ?? enemy?.mirror?.hero,
        viewerId: viewerId,
        fiveFlames: enemy?.fiveFlames ?? false,
      ),
    );
  }

  Map<String, Object?> frame(bool includeEffects) => {
    'room': arena,
    'sequence': sequence,
    if (enemyTimers.isNotEmpty)
      'timers': {
        for (final entry in enemyTimers.entries)
          entry.key.toString(): entry.value,
      },
    if (groupCalled) 'group': true,
    if (includeEffects && cues.isNotEmpty)
      'cues': cues.map((call) => call._frame).toList(),
  };

  void restore(Object? raw, double now, String currentArena) {
    if (raw is! Map) return;
    sequence = max(0, _int(raw['sequence']));
    if (raw['room'] != currentArena) return;
    arena = currentArena;
    groupCalled = raw['group'] == true;
    if (raw['timers'] case final Map timers) {
      for (final entry in timers.entries.take(80)) {
        final id = int.tryParse(entry.key.toString());
        if (id != null) enemyTimers[id] = _num(entry.value).clamp(0, delay);
      }
    }
    for (final row in _list(raw['cues']).take(maxCues)) {
      if (LiteAlertCall._read(row, now) case final cue?) {
        cues.add(cue);
        sequence = max(sequence, cue.sequence);
      }
    }
  }
}

extension LiteAlertAudio on LiteRun {
  Iterable<LiteAlertCall> get alertCalls => _alertSignals.cues.where(
    (cue) => cue.time > time - _LiteAlertSignals.cueLifetime,
  );

  void _tickAlertCalls(double elapsed, bool sheltered) {
    final state = _alertSignals;
    final currentArena = inputArena;
    if (state.arena != currentArena) {
      state.arena = currentArena;
      state.groupCalled = false;
      state.enemyTimers.clear();
      state.cues.clear();
    }
    if (state.cues.isNotEmpty && state.cues.first.time <= time - 4) {
      state.cues.removeWhere((cue) => cue.time <= time - 4);
    }
    if (sheltered || enemies.isEmpty) return;

    var hasEnemy = false;
    var allAlert = true;
    var allCalled = true;
    for (final enemy in enemies) {
      if (enemy.hp <= 0) {
        state.enemyTimers.remove(enemy.id);
        continue;
      }
      hasEnemy = true;
      final guard = enemy.guard;
      final alert = guard != null
          ? guard.mode == LiteGuardMode.allerta
          : _immediateObserver(enemy) ||
                enemy.attacking ||
                enemy.attackTarget != null &&
                    enemy.attackTarget != enemy.position;
      if (!alert) {
        state.enemyTimers.remove(enemy.id);
        allAlert = false;
        allCalled = false;
        continue;
      }
      final special = _forgetfulBandit(enemy) && guard != null;
      final sighting = guard?._banditSighting;
      if (special && sighting == null) {
        allCalled = false;
        continue;
      }
      final delay = special && enemy.kind == LiteEnemyKind.scostubandito
          ? 2.0
          : _LiteAlertSignals.delay;
      final previous = state.enemyTimers[enemy.id] ?? 0;
      final total = min(delay, previous + elapsed + 1e-10);
      state.enemyTimers[enemy.id] = total;
      if (total == delay && previous < delay) {
        if (enemy.errato == null) state.add(time, enemy: enemy);
        if (special && sighting != null) {
          _relayBanditSighting(enemy, sighting);
        } else {
          _encounterNoise(enemy.position, 6.5, except: enemy);
        }
      }
      if (total < delay) allCalled = false;
    }
    if (!allAlert || !hasEnemy) {
      state.groupCalled = false;
      return;
    }
    if (!allCalled || state.groupCalled) return;
    state.groupCalled = true;
    if (!hostDown && _night.bat <= 0 && !inExplorationAtrium(position)) {
      state.add(time, hero: hero, viewerId: 0);
    }
    for (final fighter in coopFighters) {
      if (fighter.connected &&
          fighter.hp > 0 &&
          fighter.night.bat <= 0 &&
          !inExplorationAtrium(fighter.position)) {
        state.add(time, hero: fighter.hero, viewerId: fighter.id);
      }
    }
  }
}
