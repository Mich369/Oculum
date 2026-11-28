part of 'oculum_lite_arena.dart';

void _paintBunnys(
  Canvas canvas,
  ui.Image reference,
  ui.Image? gait,
  LiteStride stride,
  double lead,
  double time, {
  required bool fallen,
  required bool casting,
}) {
  const bodySize = 2.9;
  final pace = stride.speed;
  if (fallen || casting || pace < .08) {
    final pose = fallen
        ? 5
        : casting
        ? 4
        : 0;
    final breath = pose == 0 ? math.sin(time * 2.6) * .023 : 0.0;
    _paintSixPose(
      canvas,
      reference,
      pose,
      Rect.fromLTRB(-bodySize / 2, -bodySize - breath, bodySize / 2, 0),
    );
    return;
  }

  final running = pace >= 3.6;
  final strideLength = running ? 1.15 : .93;
  final distance = stride.distance + pace * lead.clamp(0.0, .075);
  final cycle = (distance / strideLength) % 1;
  final pose = (cycle * 4).floor();
  // Takeoff and landing stay grounded. Only the middle of a bound lifts.
  final airProgress = ((cycle - .26) / .52).clamp(0.0, 1.0);
  final lift = running ? math.sin(airProgress * math.pi) * .26 : 0.0;
  final destination = Rect.fromLTWH(
    -bodySize / 2,
    -bodySize - lift,
    bodySize,
    bodySize,
  );
  if (gait == null) {
    const creep = [0, 1, 0, 1];
    const bound = [1, 2, 3, 0];
    _paintSixPose(
      canvas,
      reference,
      (running ? bound : creep)[pose],
      destination,
    );
    return;
  }

  final cellWidth = gait.width / 4;
  final cellHeight = gait.height / 2;
  canvas.drawImageRect(
    gait,
    Rect.fromLTWH(
      pose * cellWidth,
      running ? cellHeight : 0,
      cellWidth,
      cellHeight,
    ),
    destination,
    Paint()..filterQuality = FilterQuality.medium,
  );
}
