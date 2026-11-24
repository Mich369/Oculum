part of 'oculum_lite_run.dart';

enum LiteBurstKind { dash, phase, open, veil, clash }

/// Transient presentation of authoritative movement. No combat state reads it.
class LiteBurstTrace {
  LiteBurstTrace._(
    this.kind,
    this.startedAt,
    this._duration,
    this.direction,
    this.origin,
    this._points,
  );

  static const fadeDuration = .26;
  static const _maxPoints = 14;
  static const _sampleDistance = .21;

  final LiteBurstKind kind;
  final double startedAt;
  final double _duration;
  final Point<double> direction;
  final List<Point<double>> _points;
  double? _endedAt;

  bool get finished => _endedAt != null;
  double get fadeStart => _endedAt ?? startedAt + _duration;
  int get pointCount => _points.length;
  final Point<double> origin;
  Point<double> get end => _points.last;
  Point<double> pointAt(int index) => _points[index];

  void _record(Point<double> at, double remaining, double now) {
    if (finished) return;
    final distance = at.distanceTo(end);
    if (distance >= _sampleDistance || (remaining <= 1e-9 && distance > .01)) {
      if (_points.length == _maxPoints) _points.removeAt(0);
      _points.add(at);
    }
    if (remaining <= 1e-9) _endedAt = now;
  }

  List<Object?> _frame(int id) => [
    id,
    kind.index,
    startedAt,
    _duration,
    _savePoint(direction),
    _endedAt,
    _savePoint(origin),
    for (final point in _points) _savePoint(point),
  ];
}

extension _BurstPresentation on LiteRun {
  void _beginBurstTrace(
    LiteBurstKind kind,
    double duration, {
    LiteCoopFighter? fighter,
  }) {
    final direction = fighter?.burstDirection ?? burstDirection;
    final at = fighter?.position ?? position;
    _burstTraces[fighter?.id ?? 0] = LiteBurstTrace._(
      kind,
      time,
      duration,
      direction,
      at,
      [at],
    );
  }

  void _recordBurstTrace(int id, Point<double> at, double remaining) {
    _burstTraces[id]?._record(at, remaining, time);
  }

  void _restoreBurstTraces(Object? frames) {
    // Six fighters and the other participant in a melee clash can all be visible.
    for (final raw in _list(frames).take(7)) {
      if (raw is! List || raw.length < 8) continue;
      final kind = _int(raw[1], -1);
      final start = _num(raw[2], -1);
      final duration = _num(raw[3]);
      final end = raw[5] == null ? null : _num(raw[5], -1);
      if (kind < 0 ||
          kind >= LiteBurstKind.values.length ||
          start < 0 ||
          start > time ||
          duration <= 0 ||
          duration > 1 ||
          (end != null && (end < start || end > time)) ||
          time >= (end ?? start + duration) + LiteBurstTrace.fadeDuration) {
        continue;
      }
      _burstTraces[_int(raw[0])] = LiteBurstTrace._(
        LiteBurstKind.values[kind],
        start,
        duration,
        LiteRun._unit(_point(raw[4])),
        _point(raw[6]),
        raw.skip(7).take(LiteBurstTrace._maxPoints).map(_point).toList(),
      ).._endedAt = end;
    }
  }
}
