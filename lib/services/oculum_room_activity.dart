/// Human activity, rather than network heartbeats, keeps a room alive.
class OculumRoomActivity {
  OculumRoomActivity(DateTime startedAt) : latestActivity = startedAt;
  static const idleLimit = Duration(minutes: 30);
  static const warningGrace = Duration(seconds: 60);
  DateTime latestActivity;
  DateTime? warningAt;
  final _knownSessions = <String>{};

  void record(DateTime at) {
    if (at.isAfter(latestActivity)) latestActivity = at;
    warningAt = null;
  }

  void observe(Iterable<Map<String, dynamic>> sessions, DateTime now) {
    for (final session in sessions) {
      final id = '${session['sessionId'] ?? ''}';
      final firstSeen = _knownSessions.add(id);
      final activity = DateTime.tryParse('${session['userActivityAt'] ?? ''}');
      if (activity != null &&
          !activity.isAfter(now) &&
          activity.isAfter(latestActivity)) {
        record(activity);
      } else if (activity == null && firstSeen) {
        record(now);
      }
    }
  }

  bool shouldWarn(DateTime now) =>
      warningAt == null && now.difference(latestActivity) >= idleLimit;
  void warn(DateTime now) => warningAt ??= now;
  bool shouldClose(DateTime now) =>
      warningAt != null && now.difference(warningAt!) >= warningGrace;
}
