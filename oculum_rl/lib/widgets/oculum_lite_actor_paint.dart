part of 'oculum_lite_arena.dart';

final _nearInkGrid = _InkGrid(10);
final _farInkGrid = _InkGrid(6);
final _inkShaders = Expando<ui.ImageShader>();

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

final _inkAshley = _InkRig([
  const Offset(.07, .94),
  const Offset(.87, .91),
], strideMetres: 1.55);
final _inkAshleySpring = _InkRig([const Offset(.98, .22)], reach: .35);
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

double _stridePhase(LiteStride stride, _InkRig rig, double lead) =>
    (stride.distance + stride.speed * lead) * math.pi * 2 / rig.strideMetres;

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
}) {
  if (strength <= .005 &&
      anticipation == 0 &&
      strike == 0 &&
      compress == 0 &&
      recoilArm == 0 &&
      clothFlow == 0) {
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
  final wave = [
    for (var i = 0; i < rig.tips.length; i++)
      math.sin(phase + (i.isOdd ? math.pi : 0) + (i ~/ 2) * .58) * strength,
  ];
  final drag = [
    for (var i = 0; i < rig.tips.length; i++)
      math.cos(phase + (i.isOdd ? math.pi : 0) + (i ~/ 2) * .58) * strength,
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
        final extended = weights[vertex];
        dx -= recoilArm * .26 * extended;
        dy += recoilArm * .018 * extended;
      }
      for (var joint = 0; joint < wave.length; joint++) {
        final w = weights[vertex * wave.length + joint];
        dx += wave[joint] * w * .105;
        dy -= math.max(0, drag[joint]) * w * .111;
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
  final shader = _inkShaders[atlas] ??= ui.ImageShader(
    atlas,
    TileMode.clamp,
    TileMode.clamp,
    _inkIdentity,
    filterQuality: FilterQuality.low,
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
