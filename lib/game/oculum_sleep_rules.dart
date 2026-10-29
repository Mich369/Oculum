import 'dart:math';

const int oculumSleepDaySeconds = 9 * 60 * 60;
const List<String> oculumPersonalNeeds = ['food', 'water', 'sleep'];

int _sleepInt(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

/// Clock and initiative events have independent transport revisions. A delayed
/// event from either channel must not rewind the campaign's accepted clock.
bool oculumWorldClockSnapshotFollows(Map candidate, Map previous) {
  final revision = _sleepInt(candidate['revision']);
  final previousRevision = _sleepInt(previous['revision']);
  final seconds = _sleepInt(candidate['seconds']);
  final previousSeconds = _sleepInt(previous['seconds']);
  if (revision < previousRevision || seconds < previousSeconds) return false;
  return revision != previousRevision ||
      seconds != previousSeconds ||
      _sleepInt(previous['calendarOriginDay']) <= 0 ||
      _sleepInt(candidate['calendarOriginDay']) > 0;
}

/// Delegated initial balance. All percentages and step sizes survive in JSON.
class OculumSleepRecoveryRules {
  OculumSleepRecoveryRules([Map raw = const {}]) : data = Map.from(raw);
  final Map data;
  int read(String key, int fallback) => _sleepInt(data[key], fallback);
  int get minimumMinutes => 90;
  int steps(int minutes) =>
      max(0, minutes - minimumMinutes) ~/
      read('stepMinutes', 30).clamp(1, 1440);
  int hpPercent(int minutes) =>
      (read('hpBasePercent', 75) + steps(minutes) * read('hpStepPercent', 5))
          .clamp(0, read('hpCapPercent', 100).clamp(0, 100));
  int resiliencePercent(int minutes) =>
      (read('resilienceBasePercent', 50) +
              steps(minutes) * read('resilienceStepPercent', 10))
          .clamp(0, 100);
  int artPercent(int minutes, {bool exhausted = false}) =>
      (read(
                exhausted ? 'exhaustedArtBasePercent' : 'artBasePercent',
                exhausted ? 10 : 25,
              ) +
              steps(minutes) *
                  read(
                    exhausted ? 'exhaustedArtStepPercent' : 'artStepPercent',
                    exhausted ? 2 : 5,
                  ))
          .clamp(
            0,
            read(
              exhausted ? 'exhaustedArtCapPercent' : 'artCapPercent',
              exhausted ? 40 : 100,
            ).clamp(0, 100),
          );
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}

int oculumSleepDurationMinutes(
  int startSeconds,
  int requestedMinutes, {
  int minimumMinutes = 90,
}) {
  final minimum = max(90, minimumMinutes);
  final requested = max(minimum, requestedMinutes);
  final position = max(0, startSeconds) % oculumSleepDaySeconds;
  if (position < 6 * 3600) return requested;
  final untilMorning = ((oculumSleepDaySeconds - position) / 60).ceil();
  return max(requested, untilMorning);
}

int oculumSleepHpTarget(
  int current,
  int maximum,
  int minutes, {
  OculumSleepRecoveryRules? rules,
}) {
  final profile = rules ?? OculumSleepRecoveryRules();
  return max(
    max(0, current),
    (max(0, maximum) * profile.hpPercent(minutes) / 100).ceil(),
  );
}

int oculumSleepResilienceTarget(
  int current,
  int maximum,
  int minutes, {
  OculumSleepRecoveryRules? rules,
}) {
  if (current >= maximum) return current;
  final profile = rules ?? OculumSleepRecoveryRules();
  return min(
    maximum,
    max(0, current) +
        ((maximum - max(0, current)) * profile.resiliencePercent(minutes) / 100)
            .ceil(),
  );
}

int oculumSleepArtTarget(
  int current,
  int maximum,
  int minutes, {
  bool exhausted = false,
  OculumSleepRecoveryRules? rules,
}) {
  if (current >= maximum) return current;
  final profile = rules ?? OculumSleepRecoveryRules();
  return min(
    maximum,
    max(0, current) +
        (max(0, maximum) *
                profile.artPercent(minutes, exhausted: exhausted) /
                100)
            .ceil(),
  );
}

int oculumCalendarDayAt(
  int seconds, {
  required int originDay,
  required int originOrdinal,
}) =>
    ((max(1, originDay) -
            1 +
            max(0, seconds) ~/ oculumSleepDaySeconds -
            originOrdinal) %
        369) +
    1;

/// Last half hour of Night: the Sun descends from Oblivion's cover near the
/// floating islands. This does not change phase or any saved base statistic.
int oculumNightBonusAfterDawnFade(
  int fullBonus,
  int seconds, {
  int fadeSeconds = 1800,
}) {
  final remaining =
      oculumSleepDaySeconds - max(0, seconds) % oculumSleepDaySeconds;
  final fade = fadeSeconds.clamp(1, 3 * 3600);
  if (remaining >= fade) return max(0, fullBonus);
  return max(0, fullBonus) * remaining ~/ fade;
}

/// Separate clocks, one food-OR-water penalty per nine hours, source-tagged
/// modifiers. A shared episode remains until every unmet need in it is met.
class OculumPersonalNeedsProgress {
  OculumPersonalNeedsProgress.fromJson(
    Map raw, {
    required int now,
    Map physiologicalDefaults = const {},
  }) : physiologicalDefaults = Map<String, dynamic>.from(physiologicalDefaults),
       last = {
         for (final need in oculumPersonalNeeds)
           need: max(0, _sleepInt(raw['last$need'], now)),
       },
       processedThrough = _sleepInt(raw['processedThrough'], now),
       lastFoodWaterEvent = _sleepInt(raw['lastFoodWaterEvent'], -1),
       sleepEventCount = _sleepInt(raw['sleepEventCount']),
       episodes = [
         for (final entry in raw['episodes'] is List ? raw['episodes'] : [])
           if (entry is Map) Map<String, dynamic>.from(entry),
       ],
       config = Map<String, dynamic>.from(
         raw['config'] is Map ? raw['config'] : const {},
       );
  final Map<String, int> last;
  int processedThrough, lastFoodWaterEvent, sleepEventCount;
  final List<Map<String, dynamic>> episodes;
  final Map<String, dynamic> config;
  // Derived body/race defaults are effective rules, never user configuration.
  // Serializing a Construct must not permanently disable a later human body.
  final Map<String, dynamic> physiologicalDefaults;
  bool enabled(String need) {
    final key = '${need}Enabled';
    return (config.containsKey(key)
            ? config[key]
            : physiologicalDefaults[key]) !=
        false;
  }

  int get daySeconds =>
      _sleepInt(config['daySeconds'], oculumSleepDaySeconds).clamp(1, 86400);
  int daysWithout(String need, int now) =>
      enabled(need) ? max(0, now - last[need]!) ~/ daySeconds : 0;
  bool _episodeApplies(Map episode) =>
      (episode['needs'] as List? ?? []).any((need) => enabled('$need'));
  int get ash => episodes.fold(
    0,
    (sum, episode) =>
        sum +
        (_episodeApplies(episode) ? max(0, _sleepInt(episode['ash'])) : 0),
  );
  int statPenalty(String stat) => episodes.fold(0, (sum, episode) {
    if (!_episodeApplies(episode)) return sum;
    final stats = episode['stats'];
    return sum + (stats is Map ? _sleepInt(stats[stat]) : 0);
  });
  void advanceTo(int now, {Random? random}) {
    // Exempt time must not become retroactive starvation when a body changes.
    // Only clocks advance; user configuration and existing episodes survive.
    for (final need in oculumPersonalNeeds) {
      if (!enabled(need)) last[need] = max(last[need]!, now);
    }
    if (now <= processedThrough) return;
    final rng = random ?? Random.secure();
    final foodWaterDeadlines = [
      for (final need in ['food', 'water'])
        if (enabled(need)) last[need]! + daySeconds,
    ];
    if (foodWaterDeadlines.isNotEmpty) {
      var at = foodWaterDeadlines.reduce((a, b) => a < b ? a : b);
      if (lastFoodWaterEvent >= 0) {
        at = max(at, lastFoodWaterEvent + daySeconds);
      }
      for (; at <= now; at += daySeconds) {
        final missing = [
          for (final need in ['food', 'water'])
            if (enabled(need) && at - last[need]! >= daySeconds) need,
        ];
        if (missing.isEmpty) continue;
        final stat = const [
          'resilienza',
          'volonta',
          'materia',
          'oculum',
        ][rng.nextInt(4)];
        episodes.add({
          'id': 'food-water:$at',
          'needs': missing,
          'stats': {stat: -max(0, _sleepInt(config['foodWaterStatLoss'], 1))},
          'ash': max(0, _sleepInt(config['foodWaterAsh'], 3)),
        });
        lastFoodWaterEvent = at;
      }
    }
    final sleepEvery = _sleepInt(
      config['sleepPenaltyEveryDays'],
      3,
    ).clamp(1, 369);
    if (enabled('sleep')) {
      final due = daysWithout('sleep', now) ~/ sleepEvery;
      while (sleepEventCount < due) {
        sleepEventCount++;
        episodes.add({
          'id': 'sleep:${last['sleep']}:$sleepEventCount',
          'needs': ['sleep'],
          'ash': 0,
          'stats': {
            'resilienza': -max(0, _sleepInt(config['sleepResilienceLoss'], 1)),
            'oculum': -max(0, _sleepInt(config['sleepOculumLoss'], 1)),
          },
        });
      }
    }
    processedThrough = now;
  }

  void satisfy(String need, int now) {
    if (!oculumPersonalNeeds.contains(need)) return;
    last[need] = max(last[need]!, now);
    processedThrough = min(processedThrough, now);
    if (need == 'sleep') sleepEventCount = 0;
    for (final episode in episodes) {
      episode['needs'] = [
        for (final value in episode['needs'] as List? ?? [])
          if (value != need) value,
      ];
    }
    episodes.removeWhere((episode) => (episode['needs'] as List).isEmpty);
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    for (final need in oculumPersonalNeeds) 'last$need': last[need],
    'processedThrough': processedThrough,
    'lastFoodWaterEvent': lastFoodWaterEvent,
    'sleepEventCount': sleepEventCount,
    'episodes': episodes,
    'config': config,
  };
}
