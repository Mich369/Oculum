part of 'oculum_lite_arena.dart';

bool _assassinTacticalLook(
  OculumLiteAppearance? appearance,
  LiteWeapon equipment,
) =>
    equipment == LiteWeapon.pistolaRicognitore ||
    appearance?.inkFinish == LiteInkFinish.tattica;

void _paintAssassin(
  Canvas canvas,
  ui.Image atlas,
  LiteStride? stride,
  double lead, {
  required bool moving,
  required bool dashing,
  required bool winding,
  required bool fallen,
  required bool phantom,
  required bool tactical,
  required double strike,
  required double openAge,
  double? impactAge,
}) {
  final speed = stride?.speed ?? 0;
  final running = speed > 3.8 && stride?.walking != true;
  final travel = (stride?.distance ?? 0) + speed * lead;
  final step = (travel * (running ? 2.9 : 2.35)).floor().isOdd;
  final recoiling = impactAge != null && impactAge < .14;
  final frame = switch (openAge) {
    _ when fallen => recoiling ? 9 : 10,
    >= 0 && < .045 => 6,
    >= .045 && < .185 => 7,
    >= .185 && < .31 => 8,
    _ when dashing => 5,
    _ when recoiling => 9,
    _ when strike > .06 => 11,
    _ when strike > 0 => tactical ? 0 : 8,
    _ when winding => tactical ? 11 : 6,
    _ when running => step ? 4 : 3,
    _ when moving || speed > .08 => step ? 2 : 1,
    _ => 0,
  };

  const cell = 256.0;
  const size = 2.68;
  final source = Rect.fromLTWH(
    (frame % 4) * cell,
    (frame ~/ 4) * cell,
    cell,
    cell,
  );
  const destination = Rect.fromLTWH(-size / 2, -size * 235 / cell, size, size);
  final ink = phantom
      ? (Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = const ColorFilter.mode(
            Color(0xff8e87c9),
            BlendMode.modulate,
          )
          ..color = const Color(0xdaffffff))
      : _monsterSampler;
  canvas.drawImageRect(atlas, source, destination, ink);
}
