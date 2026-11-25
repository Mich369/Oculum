part of 'oculum_lite_arena.dart';

final _plagueSupports = [
  [
    _InkRig([
      const Offset(.37, .935),
      const Offset(.65, .935),
    ], strideMetres: 1.52),
    _InkRig([
      const Offset(.23, .92),
      const Offset(.68, .91),
    ], strideMetres: 1.76),
    _InkRig([const Offset(.25, .95), const Offset(.66, .93)]),
    _InkRig([const Offset(.21, .94), const Offset(.69, .94)]),
  ],
  [
    _InkRig([
      const Offset(.33, .93),
      const Offset(.65, .94),
    ], strideMetres: 1.95),
    _InkRig([
      const Offset(.17, .91),
      const Offset(.77, .95),
    ], strideMetres: 2.28),
    _InkRig([
      const Offset(.18, .95),
      const Offset(.57, .95),
    ], strideMetres: 2.11),
    _InkRig([
      const Offset(.19, .94),
      const Offset(.76, .95),
    ], strideMetres: 2.11),
  ],
  [
    _InkRig([
      const Offset(.27, .94),
      const Offset(.59, .94),
    ], strideMetres: 1.49),
    _InkRig([
      const Offset(.20, .90),
      const Offset(.70, .93),
    ], strideMetres: 1.76),
    _InkRig([const Offset(.18, .94), const Offset(.58, .92)]),
    _InkRig([const Offset(.18, .94), const Offset(.58, .94)]),
  ],
  [
    _InkRig([
      const Offset(.37, .93),
      const Offset(.62, .93),
    ], strideMetres: 1.38),
    _InkRig([
      const Offset(.23, .91),
      const Offset(.63, .94),
    ], strideMetres: 1.73),
    _InkRig([const Offset(.25, .94), const Offset(.63, .94)]),
    _InkRig([const Offset(.25, .94), const Offset(.65, .93)]),
  ],
];

final _plagueHands = [
  _InkGripRig(const Offset(.451, .462), .050, .052),
  _InkGripRig(const Offset(.390, .395), .055, .052),
  _InkGripRig(const Offset(.365, .79), .092, .025),
  _InkGripRig(const Offset(.333, .538), .052, .055),
];
final _corvineClaw = _InkGripRig(const Offset(.88, .31), .160, .084);
final _scytheDraw = _InkGripRig(const Offset(.40, .31), .26, .18);
final _scytheSweep = _InkGripRig(const Offset(.69, .50), .24, .18);
final _bowDraw = _InkGripRig(const Offset(.63, .44), .24, .20);
final _bowRelease = _InkGripRig(const Offset(.65, .41), .24, .20);

double _plagueGrowth(double remaining, int grade) {
  final age = LiteRun.plagueDurationFor(grade) - remaining;
  return math.min(_inkEase(age / .31), _inkEase(remaining / .26));
}

void _paintPlagueCharacter(
  Canvas canvas,
  ui.Image atlas,
  LiteWeapon weapon,
  ui.Image? gear,
  Offset aim,
  LiteStride? stride,
  double time,
  double animationLead, {
  required double growth,
  required bool fallen,
  required bool phantom,
  required bool preparing,
  required double? attackElapsed,
  required bool releasingChakram,
}) {
  final releaseAge = attackElapsed == null
      ? double.infinity
      : math.max(0.0, attackElapsed - weapon.chargeSeconds);
  final striking = !preparing && releaseAge < .26;
  final frame = _newFrame(
    stride,
    animationLead,
    preparing: preparing,
    hitting: striking,
  );
  canvas.save();
  if (fallen) {
    canvas.rotate(1.14);
    canvas.scale(.79, .82);
  }
  final opacity = phantom ? .76 : 1.0;
  if (growth < 1) {
    final hand = _plagueHands[frame];
    final motion = fallen
        ? null
        : _inkWeaponMotion(weapon, hand, attackElapsed, preparing);
    final pose = _paintPlagueSprite(
      canvas,
      atlas,
      0,
      frame,
      2.46,
      stride,
      time,
      animationLead,
      alpha: opacity * (1 - growth * .84),
      motion: motion,
      fallen: fallen,
    );
    if (!fallen && !releasingChakram && growth < .74) {
      final at = hand.pivot + (motion?.travel ?? Offset.zero);
      canvas.save();
      canvas.translate(
        pose.left + at.dx * pose.width,
        pose.top + at.dy * pose.height,
      );
      canvas.rotate(
        -.20 + aim.direction.clamp(-.42, .48) + (motion?.turn ?? 0),
      );
      canvas.scale(.68 - growth * .19);
      _holdWeapon(canvas, weapon, gear, const Color(0xffa48d73), _ink);
      canvas.restore();
    }
  }
  if (growth > 0) {
    final reach = striking ? 1 - _inkEase(releaseAge / .26) : 0.0;
    final motion = reach == 0
        ? null
        : _InkAttackMotion(
            _corvineClaw,
            Offset(.092 * reach, -.026 * reach),
            .14 * reach,
            reach,
          );
    _paintPlagueSprite(
      canvas,
      atlas,
      1,
      frame,
      2.58 + growth * 1.09,
      stride,
      time,
      animationLead,
      alpha: opacity * growth,
      motion: motion,
      fallen: fallen,
    );
  }
  canvas.restore();
}

Rect _paintPlagueSprite(
  Canvas canvas,
  ui.Image atlas,
  int row,
  int frame,
  double height,
  LiteStride? stride,
  double time,
  double animationLead, {
  double alpha = 1,
  _InkAttackMotion? motion,
  bool fallen = false,
}) {
  final pose = Rect.fromLTWH(
    -height * .75,
    -height * .963,
    height * 1.5,
    height,
  );
  final source = Rect.fromLTWH(frame * 360.0, row * 240.0, 360, 240);
  final paint = Paint()
    ..color = Colors.white.withValues(alpha: alpha)
    ..filterQuality = FilterQuality.medium;
  final rig = _plagueSupports[row][frame];
  final phase = _stridePhase(stride, rig.strideMetres, animationLead);
  final pace = !fallen && frame < 2 ? stride?.strength ?? 0.0 : 0.0;
  final compression = fallen
      ? 0.0
      : frame == 2
      ? .018
      : _stepCompression(phase) * pace;
  final breath = fallen ? 0.0 : math.sin(time * 3.7 + row) * .008 * (1 - pace);
  canvas.save();
  canvas.scale(1, 1 + breath);
  _inkActorSprite(
    canvas,
    atlas,
    source,
    pose,
    paint,
    rig,
    phase: phase,
    strength: pace,
    compress: compression,
    clothFlow: row == 1 ? pace * .83 : pace * .41,
    running: (stride?.speed ?? 0) >= 3.5,
    handMotion: motion,
  );
  canvas.restore();
  return pose;
}

void _paintPlagueSkeleton(
  Canvas canvas,
  ui.Image atlas,
  LiteClone ally,
  double time,
  double animationLead,
) {
  final scythe = ally.companion == LiteCompanion.scheletroFalce;
  final release = math.max(0.0, ally.swing - animationLead);
  final burst = (release / .23).clamp(0.0, 1.0);
  final anticipation = ally.preparingPose;
  final frame = release > .075
      ? 3
      : anticipation > 0 || release > 0
      ? 2
      : _strideFrame(ally.stride, scythe ? 1.65 : 1.49, animationLead);
  final wind = _inkEase(anticipation);
  final pose = switch (frame) {
    2 => _InkAttackMotion(
      scythe ? _scytheDraw : _bowDraw,
      Offset(-(scythe ? .04 : .062) * wind, -.031 * wind),
      (scythe ? -.15 : -.065) * wind,
      wind,
    ),
    3 => _InkAttackMotion(
      scythe ? _scytheSweep : _bowRelease,
      Offset((scythe ? .093 : -.048) * burst * burst, -.018 * burst),
      (scythe ? .16 : -.055) * burst,
      burst,
    ),
    _ => null,
  };
  canvas.save();
  if (ally.down) {
    canvas.rotate(1.19);
    canvas.scale(.77, .84);
  }
  _paintPlagueSprite(
    canvas,
    atlas,
    scythe ? 2 : 3,
    frame,
    2.12,
    ally.stride,
    time,
    animationLead,
    motion: ally.down ? null : pose,
    fallen: ally.down,
  );
  if (!ally.down && release > .075) {
    final direction = Offset(ally.poseAim.x.abs(), ally.poseAim.y);
    const edge = Color(0xff9cbda4);
    if (scythe) {
      _bladeRibbon(
        canvas,
        const Offset(.24, -.92),
        direction,
        1.28,
        .23 - release,
        edge,
        -1,
      );
    } else {
      final bow = const Offset(.59, -1.17);
      _inkSlash(
        canvas,
        bow - direction * (.23 + .22 * (1 - burst)),
        bow + direction * .29,
        edge.withValues(alpha: burst),
        .045,
      );
    }
  }
  canvas.restore();
}

void _paintCorvineFeathers(
  Canvas canvas,
  Offset feet,
  double age, {
  bool closing = false,
}) {
  final duration = closing ? .26 : .58;
  if (age < 0 || age >= duration) return;
  final progress = age / duration;
  final fade = 1 - progress;
  for (var i = 0; i < 9; i++) {
    final side = i.isEven ? -1.0 : 1.0;
    final lift = closing ? fade : progress;
    final drift = .23 + i * .10;
    final root =
        feet +
        Offset(
          side * (drift + lift * .88),
          -.16 - lift * (1.12 + (i % 3) * .32),
        );
    final tip =
        root + Offset(side * (.11 + (i % 4) * .068), -.25 - (i % 3) * .07);
    final curve = Offset.lerp(root, tip, .52)!;
    final pigment = i % 3 == 0
        ? const Color(0xff99b58c)
        : const Color(0xff4d5260);
    _poly(
      canvas,
      [
        root,
        curve + Offset(.085 * side, .01),
        tip,
        curve - Offset(.055 * side, .018),
      ],
      pigment.withValues(alpha: fade * .86),
      stroke: _ink.withValues(alpha: fade),
    );
    _inkSlash(
      canvas,
      root,
      tip,
      const Color(0xffc3b593).withValues(alpha: fade * .71),
      .021,
    );
  }
  final spread = .83 + _inkEase(progress) * 1.41;
  final arc = Rect.fromCenter(
    center: feet,
    width: spread,
    height: spread * .32,
  );
  canvas.drawArc(
    arc,
    closing ? .75 : -.15,
    math.pi * 1.46,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .066 * fade
      ..color = const Color(0xff93ad82).withValues(alpha: fade * .77),
  );
}
