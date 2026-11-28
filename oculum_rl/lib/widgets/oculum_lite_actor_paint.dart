part of 'oculum_lite_arena.dart';

final _nearInkGrid = _InkGrid(10);
final _farInkGrid = _InkGrid(6);
final _inkShaders = Expando<Map<FilterQuality, ui.ImageShader>>();

class _InkGrid {
  _InkGrid(this.divisions);
  final int divisions;
  int get rowLength => divisions + 1;
  final _textureCoordinates = <Rect, Float32List>{};

  late final indices = Uint16List.fromList([
    for (var row = 0; row < divisions; row++)
      for (var col = 0; col < divisions; col++) ...[
        row * rowLength + col,
        row * rowLength + col + 1,
        (row + 1) * rowLength + col,
        row * rowLength + col + 1,
        (row + 1) * rowLength + col + 1,
        (row + 1) * rowLength + col,
      ],
  ]);

  Float32List textureCoordinates(Rect source) =>
      _textureCoordinates.putIfAbsent(
        source,
        () => Float32List.fromList([
          for (var row = 0; row < rowLength; row++)
            for (var col = 0; col < rowLength; col++) ...[
              source.left + .5 + col / divisions * (source.width - 1),
              source.top + .5 + row / divisions * (source.height - 1),
            ],
        ]),
      );
}

final _inkIdentity = Float64List.fromList([
  1,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  1,
]);

/// Anchors are authored per sprite in the source cell, from top left to bottom right.
class _InkRig {
  _InkRig(this.tips, {this.reach = .23, this.strideMetres = 1.65});

  final List<Offset> tips;
  final double reach;
  final double strideMetres;

  final _weights = <_InkGrid, Float32List>{};

  Float32List weightsFor(_InkGrid grid) => _weights.putIfAbsent(
    grid,
    () => Float32List.fromList([
      for (var row = 0; row < grid.rowLength; row++)
        for (var col = 0; col < grid.rowLength; col++)
          for (final tip in tips)
            _jointWeight(col / grid.divisions, row / grid.divisions, tip),
    ]),
  );

  double _jointWeight(double x, double y, Offset tip) {
    final dx = (x - tip.dx) / reach;
    final dy = (y - tip.dy) / .31;
    final blend = (1 - dx * dx - dy * dy).clamp(0.0, 1.0);
    return blend * blend;
  }
}

final _inkHeroFeet = {
  false: [
    _InkRig([const Offset(.25, .88), const Offset(.73, .89)]),
    _InkRig([const Offset(.30, .89), const Offset(.68, .89)]),
    _InkRig([const Offset(.21, .89), const Offset(.72, .90)]),
    _InkRig([const Offset(.24, .89), const Offset(.70, .89)]),
    _InkRig([const Offset(.29, .89), const Offset(.61, .90)]),
    _InkRig([const Offset(.12, .89), const Offset(.76, .90)]),
    _InkRig([const Offset(.30, .89), const Offset(.73, .90)]),
    _InkRig([const Offset(.16, .89), const Offset(.72, .90)]),
  ],
  true: [
    _InkRig([const Offset(.08, .94), const Offset(.69, .95)]),
    _InkRig([const Offset(.21, .94), const Offset(.77, .95)]),
    _InkRig([const Offset(.15, .94), const Offset(.89, .95)]),
    _InkRig([const Offset(.17, .94), const Offset(.85, .95)]),
    _InkRig([const Offset(.18, .94), const Offset(.47, .95)]),
    _InkRig([const Offset(.14, .94), const Offset(.81, .95)]),
    _InkRig([const Offset(.24, .94), const Offset(.66, .95)]),
    _InkRig([const Offset(.18, .94), const Offset(.88, .95)]),
  ],
};

final _inkRunningFeet = _InkRig(
  [const Offset(.22, .90), const Offset(.79, .97)],
  reach: .19,
  strideMetres: 1.44,
);

final _inkAshley = _InkRig([
  const Offset(.07, .94),
  const Offset(.87, .91),
], strideMetres: 1.55);
final _inkAshleyRun = _InkRig(
  [const Offset(.08, .94), const Offset(.66, .87)],
  reach: .19,
  strideMetres: 1.96,
);
final _inkAshleySpring = _InkRig([const Offset(.96, .23)], reach: .49);

final _ashleyGrips = [
  _InkGripRig(const Offset(.35, .52), .075, .038),
  _InkGripRig(const Offset(.28, .36), .064, .043),
];
final _spiderTail = _InkGripRig(const Offset(.513, .333), .092, .008);

bool _usesPosteaAtlas(LiteEnemyKind kind) => switch (kind) {
  LiteEnemyKind.ragnoSaldatore ||
  LiteEnemyKind.dronePostea ||
  LiteEnemyKind.miruscyrus => true,
  _ => false,
};

_InkAttackMotion? _spiderTailMotion(double? windup, double strike) {
  if (windup != null) {
    final charge = _inkEase(1 - windup / .46);
    return _InkAttackMotion(
      _spiderTail,
      Offset(.044 * charge, -.083 * charge),
      -.19 * charge,
      charge,
    );
  }
  if (strike <= 0) return null;
  final recoil = (strike / .24).clamp(0.0, 1.0);
  return _InkAttackMotion(
    _spiderTail,
    Offset(-.082 * recoil * recoil, -.043 * recoil),
    -.26 * recoil,
    recoil,
  );
}

void _paintSpiderCharge(
  Canvas canvas,
  Rect pose,
  _InkAttackMotion tail,
  bool charging,
  double time,
) {
  final anchor = tail.grip.pivot + tail.travel;
  final muzzle = Offset(
    pose.left + pose.width * anchor.dx,
    pose.top + pose.height * anchor.dy,
  );
  final strength = tail.brace;
  if (strength < .075) return;
  final radius = charging ? .05 + strength * .15 : .08 + .17 * (1 - strength);
  final cyan = const Color(0xff7bded4).withValues(alpha: strength);
  _oval(
    canvas,
    muzzle,
    radius * 1.24,
    radius,
    _ink,
    stroke: cyan,
    strokeWidth: .030,
  );
  _oval(
    canvas,
    muzzle,
    radius * .43,
    radius * .46,
    const Color(0xffe5f8cb).withValues(alpha: strength),
  );
  for (var index = 0; index < 3; index++) {
    final angle = time * (charging ? 8 : 3) + index * math.pi * 2 / 3;
    final direction = Offset(math.cos(angle), math.sin(angle));
    final root = muzzle + direction * radius;
    _inkSlash(canvas, root, root + direction * (.10 * strength), cyan, .027);
  }
}

final _inkVeyrth = _InkRig([
  const Offset(.12, .53),
  const Offset(.19, .84),
  const Offset(.86, .39),
  const Offset(.91, .60),
  const Offset(.82, .79),
], reach: .20);
final _inkVeyrthEcho = _InkRig([
  const Offset(.13, .34),
  const Offset(.29, .62),
  const Offset(.49, .88),
  const Offset(.93, .78),
], reach: .21);
final _inkEnemyRigs = {
  LiteEnemyKind.scostubandito: _InkRig([
    const Offset(.23, .94),
    const Offset(.65, .92),
  ], strideMetres: 1.30),
  LiteEnemyKind.granScostumato: _InkRig([
    const Offset(.27, .94),
    const Offset(.70, .92),
  ], strideMetres: 1.95),
  LiteEnemyKind.babyForestDemon: _InkRig(
    [
      const Offset(.23, .90),
      const Offset(.47, .96),
      const Offset(.78, .89),
      const Offset(.93, .94),
    ],
    reach: .17,
    strideMetres: 1.55,
  ),
  LiteEnemyKind.forestDemon: _InkRig(
    [const Offset(.17, .89), const Offset(.48, .96), const Offset(.84, .90)],
    reach: .19,
    strideMetres: 2.05,
  ),
  LiteEnemyKind.slime: _InkRig([
    const Offset(.21, .91),
    const Offset(.69, .91),
  ], strideMetres: 1.35),
  LiteEnemyKind.costrutto: _InkRig(
    [
      const Offset(.38, .95),
      const Offset(.68, .85),
      const Offset(.10, .69),
      const Offset(.88, .73),
    ],
    reach: .18,
    strideMetres: 1.82,
  ),
  LiteEnemyKind.ragnoSaldatore: _InkRig(
    [
      const Offset(.09, .91),
      const Offset(.27, .95),
      const Offset(.45, .91),
      const Offset(.75, .95),
      const Offset(.92, .84),
    ],
    reach: .15,
    strideMetres: 1.16,
  ),
  LiteEnemyKind.dronePostea: _InkRig([
    const Offset(.24, .77),
    const Offset(.68, .76),
  ], reach: .19),
  LiteEnemyKind.miruscyrus: _InkRig(
    [
      const Offset(.09, .94),
      const Offset(.31, .91),
      const Offset(.60, .86),
      const Offset(.80, .92),
      const Offset(.96, .84),
    ],
    reach: .18,
    strideMetres: 1.61,
  ),
};

double _stridePhase(LiteStride? stride, double strideMetres, double lead) =>
    stride == null
    ? 0
    : (stride.distance + stride.speed * lead) * math.pi * 2 / strideMetres;

// Weight drops on contact and rises during the passing pose. Scale around
// the ground anchor, so the whole drawing never bobs away from its shadow.
double _stepCompression(double phase) =>
    .024 * (1 + math.cos(phase * 2 - .36)) / 2;

void _groundedMotion(
  Canvas canvas,
  LiteStride? stride,
  double animationLead, {
  double strideMetres = 1.65,
}) {
  final pace = stride?.strength ?? 0;
  if (pace <= .005) return;
  final phase = _stridePhase(stride, strideMetres, animationLead);
  canvas.scale(
    1 + _stepCompression(phase) * pace * .32,
    1 - _stepCompression(phase) * pace,
  );
}

// The weapon and its near hand articulate as one painted section. The
// supports and the customized head stay on the established sprite anchors.
final _inkGripRigs = {
  false: [
    _InkGripRig(const Offset(.74, .58), .25, .15),
    _InkGripRig(const Offset(.73, .46), .25, .24),
    _InkGripRig(const Offset(.73, .46), .18, .19),
    _InkGripRig(const Offset(.52, .61), .32, .18),
    _InkGripRig(const Offset(.73, .51), .24, .17),
    _InkGripRig(const Offset(.53, .55), .30, .24),
    _InkGripRig(const Offset(.74, .62), .20, .13),
    _InkGripRig(const Offset(.66, .53), .16, .14),
  ],
  true: [
    _InkGripRig(const Offset(.70, .52), .23, .17),
    _InkGripRig(const Offset(.80, .35), .32, .25),
    _InkGripRig(const Offset(.75, .32), .23, .23),
    _InkGripRig(const Offset(.60, .56), .36, .19),
    _InkGripRig(const Offset(.72, .49), .23, .17),
    _InkGripRig(const Offset(.55, .51), .31, .24),
    _InkGripRig(const Offset(.77, .56), .22, .16),
    _InkGripRig(const Offset(.74, .49), .16, .15),
  ],
};

double _inkEase(double value) {
  final p = value.clamp(0.0, 1.0);
  return p * p * (3 - 2 * p);
}

class _InkGripRig {
  _InkGripRig(this.pivot, this.above, this.below, {this.behind = false});
  final bool behind;
  final Offset pivot;
  final double above, below;
  final _weights = <_InkGrid, Float32List>{};

  Float32List weightsFor(_InkGrid grid) => _weights.putIfAbsent(
    grid,
    () => Float32List.fromList([
      for (var row = 0; row < grid.rowLength; row++)
        for (var col = 0; col < grid.rowLength; col++)
          _weight(col / grid.divisions, row / grid.divisions),
    ]),
  );

  double _weight(double x, double y) {
    final lateral = behind ? pivot.dx - x : x - pivot.dx;
    final side = _inkEase((lateral + .20) / .20);
    final top = _inkEase((y - pivot.dy + above + .075) / .075);
    final bottom = _inkEase((pivot.dy + below + .095 - y) / .095);
    return side * top * bottom;
  }
}

class _InkAttackMotion {
  const _InkAttackMotion(this.grip, this.travel, this.turn, this.brace);
  final _InkGripRig grip;
  final Offset travel;
  final double turn, brace;
  double get strideWeight => 1 - .78 * brace;

  void attach(Canvas canvas, double cell) {
    final pivot = grip.pivot * cell;
    final shift = travel * cell;
    canvas.translate(pivot.dx + shift.dx, pivot.dy + shift.dy);
    canvas.rotate(turn);
    canvas.translate(-pivot.dx, -pivot.dy);
  }
}

_InkAttackMotion? _inkWeaponMotion(
  LiteWeapon weapon,
  _InkGripRig grip,
  double? elapsed,
  bool preparing,
) {
  if (elapsed == null || !elapsed.isFinite) return null;
  final (forward, rise, pivot, settle) = switch (weapon.moveset) {
    LiteWeapon.spadaScudo => (.083, -.008, .20, .22),
    LiteWeapon.guanti => (.101, -.017, .055, .33),
    LiteWeapon.arco => (-.045, -.013, -.048, .23),
    LiteWeapon.scettro => (.040, -.037, -.107, .28),
    LiteWeapon.boomerang => (.059, -.016, .174, .25),
    LiteWeapon.chakram => (.062, -.014, .15, .18),
    LiteWeapon.falceRunica => (.049, .025, .234, .35),
    LiteWeapon.piccaOssidiana => (.107, -.009, .035, .31),
    LiteWeapon.doppieLame => (.048, .022, .24, .19),
    LiteWeapon.carabinaImpulsi => (-.083, -.009, -.127, .37),
    LiteWeapon.balestraRunica => (-.067, -.007, -.08, .32),
    LiteWeapon.fucileScostubandito => (-.076, -.010, -.139, .29),
    _ => (.083, -.008, .20, .22),
  };
  final windup = weapon == LiteWeapon.doppieLame ? .11 : weapon.chargeSeconds;
  if (preparing) {
    final weight = _inkEase(elapsed / math.max(.095, windup));
    return _InkAttackMotion(
      grip,
      Offset(-(.018 + forward.abs() * .41) * weight, (rise + .027) * weight),
      -pivot * .51 * weight,
      .25 + weight * .59,
    );
  }
  final t = math.max(0.0, elapsed - windup);
  final recovery = (1 - t / settle).clamp(0.0, 1.0);
  if (recovery == 0) return null;
  final impact = recovery * recovery;
  final follow = _inkEase(t / settle) * recovery;
  return _InkAttackMotion(
    grip,
    Offset(forward * impact, rise * impact + forward.abs() * .34 * follow),
    pivot * (impact + follow * .54),
    math.max(.36 * recovery, impact),
  );
}

Offset _inkFootfall(double phase, bool running) {
  final cycle = (phase / (2 * math.pi)) % 1;
  final stance = running ? .53 : .67;
  final travel = running ? .18 : .13;
  if (cycle < stance) {
    // A planted shoe tracks the body during movement. Lift occurs only
    // during the return phase, which is shorter than the planted phase.
    return Offset((.5 - cycle / stance) * travel, 0);
  }
  final recovery = (cycle - stance) / (1 - stance);
  return Offset(
    (_inkEase(recovery) - .5) * travel,
    -math.sin(recovery * math.pi) * (running ? .109 : .073),
  );
}

void _inkActorSprite(
  Canvas canvas,
  ui.Image atlas,
  Rect source,
  Rect destination,
  Paint paint,
  _InkRig rig, {
  required double phase,
  required double strength,
  double anticipation = 0,
  double strike = 0,
  double compress = 0,
  double recoilArm = 0,
  double clothFlow = 0,
  bool grounded = true,
  bool running = false,
  _InkAttackMotion? handMotion,
  _InkAttackMotion? secondaryMotion,
}) {
  if (strength <= .005 &&
      anticipation == 0 &&
      strike == 0 &&
      compress == 0 &&
      recoilArm == 0 &&
      clothFlow == 0 &&
      handMotion == null &&
      secondaryMotion == null) {
    canvas.drawImageRect(atlas, source, destination, paint);
    return;
  }
  final transform = canvas.getTransform();
  final pixelsWide =
      destination.width * (transform[0].abs() + transform[1].abs());
  final pixelsHigh =
      destination.height * (transform[4].abs() + transform[5].abs());
  final grid = math.max(pixelsWide, pixelsHigh) >= 92
      ? _nearInkGrid
      : _farInkGrid;
  final positions = Float32List(grid.rowLength * grid.rowLength * 2);
  final weights = rig.weightsFor(grid);
  final feet =
      [
            for (var i = 0; i < rig.tips.length; i++)
              phase + (i.isOdd ? math.pi : 0) + (i ~/ 2) * .58,
          ]
          .map(
            (step) => grounded
                ? _inkFootfall(step, running) * strength
                : Offset(
                        math.sin(step) * .094,
                        -math.max(0, math.cos(step)) * .092,
                      ) *
                      strength,
          )
          .toList(growable: false);
  final motionLayers = [
    for (final motion in [handMotion, secondaryMotion])
      if (motion != null)
        (
          motion,
          motion.grip.weightsFor(grid),
          math.cos(motion.turn),
          math.sin(motion.turn),
        ),
  ];
  final clothWave = math.sin(phase * .7) * clothFlow;
  for (var row = 0, vertex = 0; row < grid.rowLength; row++) {
    final y = row / grid.divisions;
    for (var col = 0; col < grid.rowLength; col++, vertex++) {
      final x = col / grid.divisions;
      var dx = (strike * .097 - anticipation * .062) * (1 - y) * (x + .28);
      var dy = compress * (1 - y) - strike * .027 * (1 - y);
      if (clothFlow > 0) {
        final rear = (1 - x / .38).clamp(0.0, 1.0);
        final cloth =
            ((y - .34) / .22).clamp(0.0, 1.0) *
            ((.78 - y) / .16).clamp(0.0, 1.0) *
            rear;
        dx -= cloth * (.024 * clothFlow + clothWave * .035);
        dy += cloth * clothWave * .049;
      }
      if (recoilArm > 0) {
        final extended = weights[vertex * rig.tips.length];
        dx -= recoilArm * .26 * extended;
        dy += recoilArm * .018 * extended;
      }
      for (var joint = 0; joint < feet.length; joint++) {
        final weight = weights[vertex * feet.length + joint];
        dx += feet[joint].dx * weight;
        dy += feet[joint].dy * weight;
      }
      for (final (motion, weights, cosine, sine) in motionLayers) {
        final weight = weights[vertex];
        final qx = x - motion.grip.pivot.dx;
        final qy = y - motion.grip.pivot.dy;
        dx += (motion.travel.dx + qx * (cosine - 1) - qy * sine) * weight;
        dy += (motion.travel.dy + qx * sine + qy * (cosine - 1)) * weight;
      }
      final i = vertex * 2;
      positions[i] = destination.left + (x + dx) * destination.width;
      positions[i + 1] = destination.top + (y + dy) * destination.height;
    }
  }
  final vertices = ui.Vertices.raw(
    ui.VertexMode.triangles,
    positions,
    textureCoordinates: grid.textureCoordinates(source),
    indices: grid.indices,
  );
  // Use the same texture sampling as the resting pose. A coarser shader
  // turns folds and outlines into an apparent change of sprite on contact.
  final shaders = _inkShaders[atlas] ??= {};
  final shader = shaders.putIfAbsent(
    paint.filterQuality,
    () => ui.ImageShader(
      atlas,
      TileMode.clamp,
      TileMode.clamp,
      _inkIdentity,
      filterQuality: paint.filterQuality,
    ),
  );
  paint.shader = shader;
  try {
    canvas.drawVertices(vertices, BlendMode.src, paint);
  } finally {
    paint.shader = null;
    vertices.dispose();
  }
}

void _paintDroneRotor(Canvas canvas, Rect pose, double time) {
  final center = Offset(
    pose.left + pose.width * .535,
    pose.top + pose.height * .456,
  );
  final ellipse = Rect.fromCenter(
    center: center,
    width: pose.width * .25,
    height: pose.height * .067,
  );
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = .025;
  for (var i = 0; i < 3; i++) {
    paint.color = (i == 1 ? const Color(0x9079c9c2) : const Color(0xa6c58145));
    canvas.drawArc(ellipse, time * 31 + i * math.pi * 2 / 3, .52, false, paint);
  }
}

final _rasvyrSupports = [
  _InkRig(
    [const Offset(.15, .88), const Offset(.32, .88), const Offset(.85, .87)],
    reach: .18,
    strideMetres: 1.85,
  ),
  _InkRig(
    [const Offset(.19, .89), const Offset(.41, .83), const Offset(.81, .87)],
    reach: .20,
    strideMetres: 1.85,
  ),
];
final _rasvyrClaw = _InkGripRig(const Offset(.78, .57), .24, .08);

void _paintRasvyrMotion(
  Canvas canvas,
  ui.Image atlas,
  Rect source,
  Rect pose,
  Paint paint,
  int frame,
  LiteStride? stride,
  double lead,
  double strike,
) {
  final rig = _rasvyrSupports[frame == 1 ? 1 : 0];
  final phase = _stridePhase(stride, rig.strideMetres, lead);
  final pace = frame < 2 ? stride?.strength ?? 0.0 : 0.0;
  final follow = (strike / .24).clamp(0.0, 1.0);
  final claw = frame == 3
      ? _InkAttackMotion(
          _rasvyrClaw,
          Offset(.074 * follow, -.026 * follow),
          -.12 * follow,
          follow,
        )
      : null;
  _inkActorSprite(
    canvas,
    atlas,
    source,
    pose,
    paint,
    rig,
    phase: phase,
    strength: pace,
    compress: _stepCompression(phase) * pace + (frame == 2 ? .037 : 0),
    handMotion: claw,
    running: (stride?.speed ?? 0) >= 3.1,
  );
}

void _paintOrbryxRoll(
  Canvas canvas,
  ui.Image atlas,
  Rect source,
  Rect pose,
  Paint paint,
  double strike,
) {
  final progress = (1.0 - strike / .24).clamp(0.0, 1.0);
  final lift = math.sin(progress * math.pi) * pose.height * .12;
  final at = Offset(pose.center.dx, pose.bottom - pose.height * .43 - lift);
  final dust = const Color(0xff98616e).withValues(alpha: 1 - progress);
  for (var i = 0; i < 3; i++) {
    final root = Offset(
      pose.left + pose.width * (.07 + .09 * i),
      pose.bottom - (.04 + .06 * i),
    );
    _inkSlash(
      canvas,
      root,
      root + Offset(-.25 - progress * .35, -.028),
      dust,
      .037,
    );
  }
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.rotate(2 * math.pi * progress);
  canvas.translate(-pose.center.dx, -(pose.bottom - pose.height * .43));
  canvas.drawImageRect(atlas, source, pose, paint);
  canvas.restore();
}
