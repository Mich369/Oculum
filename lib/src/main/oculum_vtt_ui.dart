part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

List<Offset> _oculumVttCanvasPoints(dynamic raw, Size size) {
  if (raw is! List) return const <Offset>[];
  return raw
      .take(512)
      .map(OculumVttPoint.fromJson)
      .map((point) => point.toOffset(size))
      .toList(growable: false);
}

Rect _oculumVttRectFromPoints(List<Offset> points) {
  if (points.isEmpty) return Rect.zero;
  var left = points.first.dx;
  var right = points.first.dx;
  var top = points.first.dy;
  var bottom = points.first.dy;
  for (final point in points.skip(1)) {
    left = min(left, point.dx);
    right = max(right, point.dx);
    top = min(top, point.dy);
    bottom = max(bottom, point.dy);
  }
  return Rect.fromLTRB(left, top, right, bottom);
}

double _oculumVttPointSegmentDistance(Offset point, Offset a, Offset b) {
  final delta = b - a;
  final lengthSquared = delta.dx * delta.dx + delta.dy * delta.dy;
  if (lengthSquared <= 0.0000001) return (point - a).distance;
  final t =
      (((point.dx - a.dx) * delta.dx + (point.dy - a.dy) * delta.dy) /
              lengthSquared)
          .clamp(0.0, 1.0)
          .toDouble();
  return (point - Offset(a.dx + delta.dx * t, a.dy + delta.dy * t)).distance;
}

class _OculumVttBasePainter extends CustomPainter {
  const _OculumVttBasePainter({
    required this.scene,
    required this.accent,
    required this.master,
    required this.modules,
    required this.revision,
  });

  final OculumVttScene scene;
  final Color accent;
  final bool master;
  final Map<String, bool> modules;
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);
    if (modules['lights'] ?? false) _paintLights(canvas, size);
    if (modules['annotations'] ?? false) _paintDrawings(canvas, size);
    if (modules['walls_doors'] ?? false) _paintWalls(canvas, size);
    if (master && (modules['triggers'] ?? false)) _paintTriggers(canvas, size);
  }

  void _paintGrid(Canvas canvas, Size size) {
    final cell = scene.gridSizePx.clamp(12.0, 512.0).toDouble();
    if (scene.gridType == 'none') return;
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.30)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    if (scene.gridType == 'square') {
      for (double x = 0; x <= size.width; x += cell) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y <= size.height; y += cell) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      _paintSquareCoordinates(canvas, size, cell);
      return;
    }

    final radius = cell / 2;
    final hexWidth = sqrt(3) * radius;
    final vertical = radius * 1.5;
    for (var row = -1; row <= size.height / vertical + 1; row++) {
      final y = row * vertical;
      final shift = row.isOdd ? hexWidth / 2 : 0.0;
      for (double x = -hexWidth; x <= size.width + hexWidth; x += hexWidth) {
        final center = Offset(x + shift, y);
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final angle = (60 * i - 30) * pi / 180;
          final point = Offset(
            center.dx + radius * cos(angle),
            center.dy + radius * sin(angle),
          );
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
    _paintHexCoordinates(canvas, size, radius, hexWidth, vertical);
  }

  bool get _showGridCoordinates =>
      scene.showCoordinates && (modules['advanced_measurement'] ?? false);

  void _paintSquareCoordinates(Canvas canvas, Size size, double cell) {
    if (!_showGridCoordinates || cell < 24) return;
    final columns = min(80, (size.width / cell).ceil());
    final rows = min(80, (size.height / cell).ceil());
    for (var column = 0; column < columns; column++) {
      _paintCoordinateLabel(
        canvas,
        '${column + 1}',
        Offset(column * cell + cell / 2, 3),
      );
    }
    for (var row = 0; row < rows; row++) {
      _paintCoordinateLabel(
        canvas,
        '${row + 1}',
        Offset(3, row * cell + cell / 2),
        centerX: false,
      );
    }
  }

  void _paintHexCoordinates(
    Canvas canvas,
    Size size,
    double radius,
    double hexWidth,
    double vertical,
  ) {
    if (!_showGridCoordinates || radius < 18) return;
    final rows = min(30, (size.height / vertical).ceil() + 1);
    final columns = min(30, (size.width / hexWidth).ceil() + 1);
    if (rows * columns > 240) return;
    for (var row = 0; row < rows; row++) {
      final shift = row.isOdd ? hexWidth / 2 : 0.0;
      for (var column = 0; column < columns; column++) {
        final center = Offset(column * hexWidth + shift, row * vertical);
        if (!size.contains(center)) continue;
        _paintCoordinateLabel(canvas, '$column,$row', center);
      }
    }
  }

  void _paintCoordinateLabel(
    Canvas canvas,
    String label,
    Offset anchor, {
    bool centerX = true,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.76),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          shadows: const <Shadow>[Shadow(color: Colors.black, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        centerX ? anchor.dx - painter.width / 2 : anchor.dx,
        anchor.dy - painter.height / 2,
      ),
    );
  }

  void _paintLights(Canvas canvas, Size size) {
    for (final light in scene.lights) {
      if (!_oculumVttBool(light['enabled'], true)) continue;
      final point = OculumVttPoint.fromJson(light['point']).toOffset(size);
      final radiusMeters = max(0.1, _oculumVttDouble(light['radius'], 6));
      final radius = radiusMeters / max(1.0, scene.widthMeters) * size.width;
      final colorValue = _oculumVttInt(light['colorArgb'], 0xFFFFD27A);
      final color = Color(colorValue);
      final intensity = _oculumVttDouble(
        light['intensity'],
        0.7,
      ).clamp(0.05, 1.0).toDouble();
      final paint = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            color.withValues(alpha: intensity * 0.34),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: point, radius: radius))
        ..blendMode = BlendMode.screen;
      canvas.drawCircle(point, radius, paint);
      if (master) {
        canvas.drawCircle(
          point,
          radius,
          Paint()
            ..color = color.withValues(alpha: 0.34)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  void _paintDrawings(Canvas canvas, Size size) {
    final now = DateTime.now();
    for (final drawing in scene.drawings) {
      final expiresAt = DateTime.tryParse('${drawing['expiresAt'] ?? ''}');
      if (expiresAt != null && expiresAt.isBefore(now)) continue;
      if (!master && !_oculumVttBool(drawing['visibleToPlayers'], true)) {
        continue;
      }
      final points = _oculumVttCanvasPoints(drawing['points'], size);
      if (points.isEmpty) continue;
      final type = '${drawing['type'] ?? 'line'}';
      final color = Color(
        _oculumVttInt(drawing['colorArgb'], accent.toARGB32()),
      );
      final width = _oculumVttDouble(drawing['width'], 3).clamp(1.0, 24.0);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.88)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (type == 'rectangle' || type == 'circle') {
        final rect = _oculumVttRectFromPoints(points);
        if (_oculumVttBool(drawing['filled'])) {
          canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.18));
        }
        if (type == 'circle') {
          canvas.drawOval(rect, paint);
        } else {
          canvas.drawRect(rect, paint);
        }
      } else if (type == 'cone' && points.length >= 2) {
        final start = points.first;
        final end = points.last;
        final angle = atan2(end.dy - start.dy, end.dx - start.dx);
        final radius = (end - start).distance;
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..arcTo(
            Rect.fromCircle(center: start, radius: radius),
            angle - pi / 6,
            pi / 3,
            false,
          )
          ..close();
        canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.20));
        canvas.drawPath(path, paint);
      } else if (type == 'note') {
        final point = points.first;
        canvas.drawCircle(
          point,
          12,
          Paint()..color = color.withValues(alpha: 0.92),
        );
        final label = '${drawing['label'] ?? ''}';
        final painter = TextPainter(
          text: TextSpan(
            text: label.isEmpty ? 'i' : label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '...',
        )..layout(maxWidth: 160);
        painter.paint(canvas, point + const Offset(16, -7));
      } else if (type == 'ping') {
        final point = points.first;
        final age = expiresAt == null
            ? 0.0
            : (expiresAt.difference(now).inMilliseconds / 4000)
                  .clamp(0.0, 1.0)
                  .toDouble();
        final radius = 14 + 22 * (1 - age);
        canvas.drawCircle(
          point,
          radius,
          Paint()
            ..color = color.withValues(alpha: 0.35 + age * 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        canvas.drawCircle(point, 4, Paint()..color = color);
      } else {
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (final point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  void _paintWalls(Canvas canvas, Size size) {
    for (final wall in scene.walls) {
      final a = OculumVttPoint.fromJson(wall['a']).toOffset(size);
      final b = OculumVttPoint.fromJson(wall['b']).toOffset(size);
      final type = '${wall['type'] ?? 'wall'}';
      final open = _oculumVttBool(wall['open']);
      final secret = _oculumVttBool(wall['secret']);
      if (!master && secret) continue;
      final color = type == 'door'
          ? (open ? Colors.greenAccent : Colors.amberAccent)
          : Colors.redAccent;
      final paint = Paint()
        ..color = color.withValues(alpha: master ? 0.92 : 0.58)
        ..strokeWidth = type == 'door' ? 4 : 3
        ..strokeCap = StrokeCap.round;
      if (type == 'door' && open) {
        final middle = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
        canvas.drawLine(a, Offset.lerp(a, middle, 0.62)!, paint);
        canvas.drawLine(Offset.lerp(middle, b, 0.38)!, b, paint);
      } else {
        canvas.drawLine(a, b, paint);
      }
      if (secret && master) {
        final middle = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
        final text = TextPainter(
          text: const TextSpan(
            text: 'S',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(canvas, middle - const Offset(3, 6));
      }
    }
  }

  void _paintTriggers(Canvas canvas, Size size) {
    for (final trigger in scene.triggers) {
      final points = _oculumVttCanvasPoints(trigger['points'], size);
      if (points.isEmpty) continue;
      final rect = _oculumVttRectFromPoints(points).inflate(2);
      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OculumVttBasePainter oldDelegate) {
    return oldDelegate.revision != revision ||
        oldDelegate.scene.revision != scene.revision ||
        oldDelegate.accent != accent ||
        oldDelegate.master != master;
  }
}

class _OculumVttFogPainter extends CustomPainter {
  const _OculumVttFogPainter({
    required this.scene,
    required this.tokens,
    required this.master,
    required this.modules,
    required this.audience,
    required this.revision,
  });

  final OculumVttScene scene;
  final List<Map<String, dynamic>> tokens;
  final bool master;
  final Map<String, bool> modules;
  final String audience;
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    if (!scene.fogEnabled || !(modules['fog'] ?? false)) return;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: master ? 0.55 : 0.94),
    );
    final operations = <Map<String, dynamic>>[
      ...?scene.fogLayers['party'],
      if (audience != 'party') ...?scene.fogLayers[audience],
    ];
    for (final operation in operations) {
      _paintFogOperation(canvas, size, operation);
    }
    if (modules['dynamic_vision'] ?? false) {
      for (final token in tokens) {
        if (!_oculumVttBool(token['visible'], true)) continue;
        final radiusMeters = _oculumVttDouble(token['visionMeters']);
        if (radiusMeters <= 0) continue;
        final point = OculumVttPoint.fromJson(<String, dynamic>{
          'x': token['x'],
          'y': token['y'],
        }).toOffset(size);
        final radius = radiusMeters / max(1.0, scene.widthMeters) * size.width;
        canvas.drawCircle(
          point,
          radius,
          Paint()
            ..blendMode = BlendMode.clear
            ..color = Colors.transparent,
        );
      }
    }
    canvas.restore();
  }

  void _paintFogOperation(
    Canvas canvas,
    Size size,
    Map<String, dynamic> operation,
  ) {
    final points = _oculumVttCanvasPoints(operation['points'], size);
    if (points.isEmpty) return;
    final reveal = '${operation['mode'] ?? 'reveal'}' == 'reveal';
    final paint = Paint()
      ..blendMode = reveal ? BlendMode.clear : BlendMode.srcOver
      ..color = reveal
          ? Colors.transparent
          : Colors.black.withValues(alpha: 0.96)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final shape = '${operation['shape'] ?? 'brush'}';
    if (shape == 'circle' || shape == 'rectangle') {
      final rect = _oculumVttRectFromPoints(points);
      if (shape == 'circle') {
        canvas.drawOval(rect, paint);
      } else {
        canvas.drawRect(rect, paint);
      }
      return;
    }
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = _oculumVttDouble(
        operation['width'],
        60,
      ).clamp(8.0, 240.0);
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    if (points.length == 1) {
      canvas.drawCircle(
        points.first,
        paint.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
    } else {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OculumVttFogPainter oldDelegate) {
    return oldDelegate.revision != revision ||
        oldDelegate.scene.revision != scene.revision ||
        oldDelegate.master != master ||
        oldDelegate.audience != audience;
  }
}

class _OculumVttInteractionPainter extends CustomPainter {
  const _OculumVttInteractionPainter({
    required this.scene,
    required this.draft,
    required this.measurements,
    required this.color,
    required this.revision,
  });

  final OculumVttScene scene;
  final List<Offset> draft;
  final List<Offset> measurements;
  final Color color;
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (draft.isNotEmpty) {
      final path = Path()..moveTo(draft.first.dx, draft.first.dy);
      for (final point in draft.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
    if (measurements.length < 2) return;
    for (var i = 1; i < measurements.length; i++) {
      final a = measurements[i - 1];
      final b = measurements[i];
      canvas.drawLine(a, b, paint);
      final distance = oculumVttDistance(
        a,
        b,
        gridType: scene.gridType,
        cellSize: scene.gridSizePx,
        distancePerCell: scene.distancePerCell,
        diagonalRule: scene.diagonalRule,
      );
      final label = scene.distanceUnit == 'cells'
          ? '${oculumVttDistanceCells(a, b, gridType: scene.gridType, cellSize: scene.gridSizePx, diagonalRule: scene.diagonalRule).toStringAsFixed(1)} celle'
          : '${distance.toStringAsFixed(distance < 10 ? 1 : 0)} ${scene.distanceUnit}';
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            backgroundColor: Color(0xCC000000),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final middle = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      text.paint(canvas, middle - Offset(text.width / 2, text.height + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _OculumVttInteractionPainter oldDelegate) {
    return oldDelegate.revision != revision ||
        oldDelegate.draft != draft ||
        oldDelegate.measurements != measurements;
  }
}

extension _OculumVttCanvasUi on _OculumHomePageState {
  bool get vttShowingRemoteScene =>
      !modalitaMaster && realtimeVisibleVttSnapshot['scene'] is Map;

  OculumVttScene vttSceneForDisplay() {
    final cached = realtimeVisibleVttScene;
    if (!modalitaMaster && cached != null) return cached;
    final remote = realtimeVisibleVttSnapshot['scene'];
    if (!modalitaMaster && remote is Map) {
      final parsed = OculumVttScene.fromJson(remote);
      realtimeVisibleVttScene = parsed;
      return parsed;
    }
    return activeVttScene;
  }

  Map<String, bool> vttModulesForDisplay() {
    if (!vttShowingRemoteScene) return vttState.modules;
    final modules = OculumVttState.defaultModules();
    final remote = realtimeVisibleVttSnapshot['modules'];
    if (remote is Map) {
      for (final entry in remote.entries) {
        modules['${entry.key}'] = _oculumVttBool(entry.value);
      }
    }
    return modules;
  }

  IconData vttToolIcon(OculumVttTool tool) {
    return switch (tool) {
      OculumVttTool.pan => Icons.pan_tool_alt,
      OculumVttTool.select => Icons.near_me,
      OculumVttTool.ruler => Icons.straighten,
      OculumVttTool.line => Icons.show_chart,
      OculumVttTool.rectangle => Icons.crop_square,
      OculumVttTool.circle => Icons.circle_outlined,
      OculumVttTool.cone => Icons.change_history,
      OculumVttTool.fogReveal => Icons.visibility,
      OculumVttTool.fogHide => Icons.visibility_off,
      OculumVttTool.wall => Icons.horizontal_rule,
      OculumVttTool.door => Icons.door_front_door,
      OculumVttTool.light => Icons.lightbulb_outline,
      OculumVttTool.note => Icons.note_add_outlined,
      OculumVttTool.ping => Icons.gps_fixed,
      OculumVttTool.trigger => Icons.bolt,
      OculumVttTool.erase => Icons.auto_fix_off,
    };
  }

  String vttToolLabel(OculumVttTool tool) {
    return switch (tool) {
      OculumVttTool.pan => t('Sposta', 'Pan'),
      OculumVttTool.select => t('Seleziona', 'Select'),
      OculumVttTool.ruler => t('Righello', 'Ruler'),
      OculumVttTool.line => t('Linea', 'Line'),
      OculumVttTool.rectangle => t('Rettangolo', 'Rectangle'),
      OculumVttTool.circle => t('Cerchio', 'Circle'),
      OculumVttTool.cone => t('Cono', 'Cone'),
      OculumVttTool.fogReveal => t('Scopri', 'Reveal'),
      OculumVttTool.fogHide => t('Nascondi', 'Hide'),
      OculumVttTool.wall => t('Muro', 'Wall'),
      OculumVttTool.door => t('Porta', 'Door'),
      OculumVttTool.light => t('Luce', 'Light'),
      OculumVttTool.note => t('Nota', 'Note'),
      OculumVttTool.ping => 'Ping',
      OculumVttTool.trigger => 'Trigger',
      OculumVttTool.erase => t('Cancella', 'Erase'),
    };
  }

  bool _vttToolUsesDrag(OculumVttTool tool) {
    return const <OculumVttTool>{
      OculumVttTool.line,
      OculumVttTool.rectangle,
      OculumVttTool.circle,
      OculumVttTool.cone,
      OculumVttTool.fogReveal,
      OculumVttTool.fogHide,
      OculumVttTool.wall,
      OculumVttTool.door,
      OculumVttTool.trigger,
    }.contains(tool);
  }

  Offset _vttMaybeSnap(Offset point, OculumVttScene scene) {
    if (!scene.snapToGrid || scene.gridType == 'none') return point;
    return oculumVttSnapPoint(
      point,
      gridType: scene.gridType,
      cellSize: scene.gridSizePx,
    );
  }

  Widget vttMapCanvas({
    required double width,
    required double height,
    ImageProvider? imageProvider,
    OculumVttScene? sceneOverride,
    bool readOnly = false,
  }) {
    return ValueListenableBuilder<int>(
      valueListenable: vttCanvasRevision,
      builder: (context, revision, child) {
        final scene = sceneOverride ?? vttSceneForDisplay();
        final remote = readOnly || vttShowingRemoteScene;
        final modules = remote ? vttModulesForDisplay() : vttState.modules;
        final tokens = remote ? scene.tokens : localMapTokens;
        final canDraw = !remote && vttCanManageMap && _vttToolUsesDrag(vttTool);
        final canTap =
            vttCanSelectTool(vttTool) &&
            const <OculumVttTool>{
              OculumVttTool.ruler,
              OculumVttTool.light,
              OculumVttTool.note,
              OculumVttTool.ping,
              OculumVttTool.erase,
            }.contains(vttTool) &&
            (!remote || vttTool == OculumVttTool.ping);
        final canvas = SizedBox(
          width: width,
          height: height,
          child: RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (imageProvider != null)
                  Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) => mapEmptyState(
                      t('Immagine non leggibile.', 'Unreadable image.'),
                    ),
                  )
                else
                  ColoredBox(
                    color: const Color(0xFF090B10),
                    child: Center(
                      child: Icon(
                        Icons.grid_4x4,
                        size: 52,
                        color: primaryColor.withValues(alpha: 0.28),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _OculumVttBasePainter(
                        scene: scene,
                        accent: primaryColor,
                        master: modalitaMaster,
                        modules: modules,
                        revision: revision,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: canDraw
                        ? (details) =>
                              _vttCanvasPanStart(details.localPosition, scene)
                        : null,
                    onPanUpdate: canDraw
                        ? (details) =>
                              _vttCanvasPanUpdate(details.localPosition, scene)
                        : null,
                    onPanEnd: canDraw
                        ? (_) => _vttCanvasPanEnd(Size(width, height), scene)
                        : null,
                    onTapUp: canTap
                        ? (details) => _vttCanvasTap(
                            details.localPosition,
                            Size(width, height),
                            scene,
                          )
                        : null,
                    onSecondaryTapDown: (details) => showVttCanvasContextMenu(
                      details.globalPosition,
                      details.localPosition,
                      Size(width, height),
                    ),
                    onLongPressStart: (details) => showVttCanvasContextMenu(
                      details.globalPosition,
                      details.localPosition,
                      Size(width, height),
                    ),
                  ),
                ),
                if (remote)
                  for (final token in tokens)
                    vttReadOnlyTokenWidget(token, width, height, scene)
                else
                  for (final token in localMapTokens)
                    localMapTokenWidget(token, width, height),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _OculumVttFogPainter(
                        scene: scene,
                        tokens: tokens,
                        master: modalitaMaster,
                        modules: modules,
                        audience: vttFogAudience,
                        revision: revision,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _OculumVttInteractionPainter(
                        scene: scene,
                        draft: List<Offset>.from(vttDraftPoints),
                        measurements: List<Offset>.from(vttMeasurePoints),
                        color: tertiaryColor,
                        revision: revision,
                      ),
                    ),
                  ),
                ),
                if (remote &&
                    realtimeVisibleVttAssetId.isNotEmpty &&
                    realtimeVttAssetProgress < 1)
                  Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(
                      value: realtimeVttAssetProgress <= 0
                          ? null
                          : realtimeVttAssetProgress,
                      minHeight: 4,
                      color: tertiaryColor,
                      backgroundColor: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
        );
        return InteractiveViewer(
          transformationController: mapTransformationController,
          minScale: 0.35,
          maxScale: 10,
          panEnabled:
              remote ||
              vttTool == OculumVttTool.pan ||
              vttTool == OculumVttTool.select,
          scaleEnabled: true,
          boundaryMargin: const EdgeInsets.all(120),
          child: scene.rotationDegrees == 0
              ? canvas
              : Transform.rotate(
                  angle: scene.rotationDegrees * pi / 180,
                  child: canvas,
                ),
        );
      },
    );
  }

  Widget vttReadOnlyTokenWidget(
    Map<String, dynamic> token,
    double width,
    double height,
    OculumVttScene scene,
  ) {
    final size = _oculumVttDouble(token['size'], 64).clamp(24.0, 160.0);
    final x = _oculumVttDouble(token['x'], 0.5).clamp(0.0, 1.0);
    final y = _oculumVttDouble(token['y'], 0.5).clamp(0.0, 1.0);
    final name = '${token['name'] ?? t('Token', 'Token')}';
    final boxWidth = max(size + 40, 92).toDouble();
    const infoHeight = 45.0;
    final boxHeight = size + infoHeight + 3;
    final color = localMapTokenColor(token);
    final ownerTag = normalizeOculumFriendTag(
      '${token['ownerTag'] ?? token['sheetTag'] ?? ''}',
    );
    final canDrag =
        vttCanManageTokens &&
        ownerTag.isNotEmpty &&
        localOculumTags().map(normalizeOculumFriendTag).contains(ownerTag) &&
        (vttTool == OculumVttTool.select || vttTool == OculumVttTool.pan);
    return Positioned(
      left: (x * width - boxWidth / 2).clamp(0.0, max(0, width - boxWidth)),
      top: (y * height - boxHeight / 2).clamp(0.0, max(0, height - boxHeight)),
      width: boxWidth,
      height: boxHeight,
      child: MouseRegion(
        cursor: canDrag ? SystemMouseCursors.move : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: canDrag
              ? (details) {
                  final start = Offset(
                    localMapTokenAxis(token, 'x'),
                    localMapTokenAxis(token, 'y'),
                  );
                  final end = Offset(
                    (start.dx + details.delta.dx / max(1.0, width)).clamp(
                      0.0,
                      1.0,
                    ),
                    (start.dy + details.delta.dy / max(1.0, height)).clamp(
                      0.0,
                      1.0,
                    ),
                  );
                  if (vttModuleEnabled('walls_doors') &&
                      oculumVttMovementBlocked(start, end, scene.walls)) {
                    return;
                  }
                  token['x'] = end.dx;
                  token['y'] = end.dy;
                  vttCanvasRevision.value++;
                }
              : null,
          onPanEnd: canDrag
              ? (_) {
                  if (scene.snapToGrid && scene.gridType != 'none') {
                    final snapped = oculumVttSnapPoint(
                      Offset(
                        localMapTokenAxis(token, 'x') * width,
                        localMapTokenAxis(token, 'y') * height,
                      ),
                      gridType: scene.gridType,
                      cellSize: scene.gridSizePx,
                    );
                    token['x'] = (snapped.dx / max(1.0, width)).clamp(0.0, 1.0);
                    token['y'] = (snapped.dy / max(1.0, height)).clamp(
                      0.0,
                      1.0,
                    );
                  }
                  vttCanvasRevision.value++;
                  unawaited(sendRealtimeVttTokenPosition(token));
                }
              : null,
          child: Tooltip(
            message: canDrag
                ? t('$name\nTrascina la tua pedina.', '$name\nDrag your token.')
                : name,
            child: Column(
              children: <Widget>[
                localMapTokenStateAvatar(token, size),
                const SizedBox(height: 3),
                Container(
                  width: boxWidth,
                  height: infoHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withValues(alpha: 0.55)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          shadows: <Shadow>[Shadow(blurRadius: 4)],
                        ),
                      ),
                      localMapTokenVitals(token, boxWidth - 8, color),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _vttCanvasPanStart(Offset point, OculumVttScene scene) {
    vttPointerStart = _vttMaybeSnap(point, scene);
    vttDraftPoints
      ..clear()
      ..add(vttPointerStart!);
    vttCanvasRevision.value++;
  }

  void _vttCanvasPanUpdate(Offset point, OculumVttScene scene) {
    final next = _vttMaybeSnap(point, scene);
    if (vttTool == OculumVttTool.fogReveal ||
        vttTool == OculumVttTool.fogHide) {
      if (vttDraftPoints.isEmpty || (vttDraftPoints.last - next).distance > 4) {
        vttDraftPoints.add(next);
      }
    } else if (vttDraftPoints.length == 1) {
      vttDraftPoints.add(next);
    } else {
      vttDraftPoints[vttDraftPoints.length - 1] = next;
    }
    vttCanvasRevision.value++;
  }

  void _vttCanvasPanEnd(Size size, OculumVttScene scene) {
    final points = List<Offset>.from(vttDraftPoints);
    vttDraftPoints.clear();
    vttPointerStart = null;
    vttCanvasRevision.value++;
    if (points.isEmpty) return;
    final normalized = points
        .map((point) => OculumVttPoint.fromOffset(point, size).toJson())
        .toList(growable: false);
    if (vttTool == OculumVttTool.trigger) {
      unawaited(showVttTriggerEditor(normalized));
      return;
    }
    mutateActiveVttScene((active) {
      switch (vttTool) {
        case OculumVttTool.fogReveal:
        case OculumVttTool.fogHide:
          final layer = active.fogLayers.putIfAbsent(
            vttFogAudience,
            () => <Map<String, dynamic>>[],
          );
          layer.add(<String, dynamic>{
            'id': oculumVttGenerateId('fog'),
            'mode': vttTool == OculumVttTool.fogReveal ? 'reveal' : 'hide',
            'shape': points.length > 2 ? 'brush' : 'circle',
            'points': normalized,
            'width': 72,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          if (layer.length > oculumVttMaxFogOperations) {
            layer.removeRange(0, layer.length - oculumVttMaxFogOperations);
          }
          active.fogEnabled = true;
          break;
        case OculumVttTool.wall:
        case OculumVttTool.door:
          final safePoints = normalized.length >= 2
              ? normalized
              : <List<double>>[normalized.first, normalized.first];
          active.walls.add(<String, dynamic>{
            'id': oculumVttGenerateId('wall'),
            'type': vttTool == OculumVttTool.door ? 'door' : 'wall',
            'a': safePoints.first,
            'b': safePoints.last,
            'open': false,
            'secret': false,
            'blocksMovement': true,
            'blocksVision': true,
          });
          break;
        default:
          active.drawings.add(<String, dynamic>{
            'id': oculumVttGenerateId('draw'),
            'type': switch (vttTool) {
              OculumVttTool.rectangle => 'rectangle',
              OculumVttTool.circle => 'circle',
              OculumVttTool.cone => 'cone',
              _ => 'line',
            },
            'points': normalized,
            'colorArgb': tertiaryColor.toARGB32(),
            'width': 3,
            'filled': vttTool == OculumVttTool.cone,
            'visibleToPlayers': true,
          });
      }
    });
  }

  void _vttCanvasTap(Offset point, Size size, OculumVttScene scene) {
    final snapped = _vttMaybeSnap(point, scene);
    switch (vttTool) {
      case OculumVttTool.ruler:
        vttMeasurePoints.add(snapped);
        if (vttMeasurePoints.length > 24) vttMeasurePoints.removeAt(0);
        vttCanvasRevision.value++;
        break;
      case OculumVttTool.note:
        unawaited(showVttNoteEditor(OculumVttPoint.fromOffset(snapped, size)));
        break;
      case OculumVttTool.ping:
        addVttPing(OculumVttPoint.fromOffset(snapped, size));
        break;
      case OculumVttTool.light:
        addVttLight(OculumVttPoint.fromOffset(snapped, size));
        break;
      case OculumVttTool.erase:
        eraseVttElementAt(OculumVttPoint.fromOffset(snapped, size));
        break;
      default:
        break;
    }
  }

  void addVttPing(OculumVttPoint point) {
    if (!vttCanPing) return;
    final scene = vttShowingRemoteScene
        ? realtimeVisibleVttScene
        : activeVttScene;
    if (scene == null) return;
    final drawing = <String, dynamic>{
      'id': oculumVttGenerateId('ping'),
      'type': 'ping',
      'points': <List<double>>[point.toJson()],
      'colorArgb': tertiaryColor.toARGB32(),
      'visibleToPlayers': true,
      'expiresAt': DateTime.now()
          .add(const Duration(seconds: 4))
          .toIso8601String(),
    };
    insertVttPingDrawing(scene, drawing);
    if (realtimeService?.isConnected == true &&
        (modalitaMaster || vttShowingRemoteScene)) {
      unawaited(
        sendRealtimeVttPing(
          scene: scene,
          drawing: drawing,
          authoritative: modalitaMaster,
        ),
      );
    }
  }

  Map<String, dynamic> createVttPingDrawingFromPayload(
    Map<String, dynamic> payload,
  ) {
    return <String, dynamic>{
      'id': '${payload['pingId'] ?? oculumVttGenerateId('ping')}',
      'type': 'ping',
      'points': <List<double>>[
        <double>[
          _oculumVttDouble(payload['x'], 0.5).clamp(0.0, 1.0),
          _oculumVttDouble(payload['y'], 0.5).clamp(0.0, 1.0),
        ],
      ],
      'colorArgb': _oculumVttInt(
        payload['colorArgb'],
        tertiaryColor.toARGB32(),
      ),
      'visibleToPlayers': true,
      'expiresAt': DateTime.now()
          .add(const Duration(seconds: 4))
          .toIso8601String(),
    };
  }

  void insertVttPingDrawing(
    OculumVttScene scene,
    Map<String, dynamic> drawing,
  ) {
    final id = '${drawing['id'] ?? ''}';
    if (id.isNotEmpty &&
        scene.drawings.any((item) => '${item['id'] ?? ''}' == id)) {
      return;
    }
    scene.drawings.add(drawing);
    vttCanvasRevision.value++;
    vttPingCleanupTimer?.cancel();
    vttPingCleanupTimer = Timer(const Duration(seconds: 5), () {
      final now = DateTime.now();
      for (final target in <OculumVttScene?>[
        activeVttScene,
        realtimeVisibleVttScene,
      ]) {
        target?.drawings.removeWhere((item) {
          final expiry = DateTime.tryParse('${item['expiresAt'] ?? ''}');
          return expiry != null && expiry.isBefore(now);
        });
      }
      vttCanvasRevision.value++;
    });
  }

  void addVttLight(OculumVttPoint point) {
    mutateActiveVttScene((scene) {
      scene.lights.add(<String, dynamic>{
        'id': oculumVttGenerateId('light'),
        'point': point.toJson(),
        'radius': 6,
        'colorArgb': const Color(0xFFFFD27A).toARGB32(),
        'intensity': 0.72,
        'enabled': true,
      });
    });
  }

  Future<void> showVttNoteEditor(OculumVttPoint point) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('Nota sulla mappa', 'Map note')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 500,
          maxLines: 4,
          decoration: fieldDecoration(t('Testo', 'Text')),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('Annulla', 'Cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(t('Salva', 'Save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || text == null || text.isEmpty) return;
    mutateActiveVttScene((scene) {
      scene.drawings.add(<String, dynamic>{
        'id': oculumVttGenerateId('note'),
        'type': 'note',
        'points': <List<double>>[point.toJson()],
        'label': text,
        'colorArgb': tertiaryColor.toARGB32(),
        'visibleToPlayers': true,
      });
    });
  }

  Future<void> showVttTriggerEditor(List<List<double>> points) async {
    var action = 'message';
    var once = true;
    final payloadController = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t('Zona interattiva', 'Interactive zone')),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  initialValue: action,
                  decoration: fieldDecoration(t('Azione', 'Action')),
                  items: <DropdownMenuItem<String>>[
                    for (final entry in <String, String>{
                      'message': t('Mostra testo', 'Show text'),
                      'scene': t('Cambia scena', 'Change scene'),
                      'teleport': t('Teletrasporta', 'Teleport'),
                      'status': t('Applica stato', 'Apply status'),
                      'initiative': t('Avvia iniziativa', 'Start initiative'),
                      'reveal': t('Rivela zona', 'Reveal area'),
                    }.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => action = value ?? action),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: payloadController,
                  maxLines: 3,
                  decoration: fieldDecoration(
                    t('Testo, stato o ID scena', 'Text, status or scene ID'),
                  ),
                ),
                SwitchListTile.adaptive(
                  value: once,
                  onChanged: (value) => setDialogState(() => once = value),
                  title: Text(t('Una sola volta', 'Once only')),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, <String, dynamic>{
                'action': action,
                'payload': payloadController.text.trim(),
                'once': once,
              }),
              child: Text(t('Crea', 'Create')),
            ),
          ],
        ),
      ),
    );
    payloadController.dispose();
    if (!mounted || result == null) return;
    mutateActiveVttScene((scene) {
      scene.triggers.add(<String, dynamic>{
        'id': oculumVttGenerateId('trigger'),
        'points': points,
        ...result,
        'enabled': true,
        'firedFor': <String>[],
      });
    });
  }

  void eraseVttElementAt(OculumVttPoint point) {
    final target = Offset(point.x, point.y);
    mutateActiveVttScene((scene) {
      bool removeNearest(List<Map<String, dynamic>> items) {
        for (var i = items.length - 1; i >= 0; i--) {
          final rawPoints = items[i]['points'];
          final points = rawPoints is List
              ? rawPoints
                    .map(OculumVttPoint.fromJson)
                    .map((p) => Offset(p.x, p.y))
                    .toList()
              : <Offset>[];
          if (points.isEmpty && items[i]['point'] != null) {
            final p = OculumVttPoint.fromJson(items[i]['point']);
            points.add(Offset(p.x, p.y));
          }
          if (points.any((p) => (p - target).distance < 0.055) ||
              (points.length >= 2 &&
                  _oculumVttPointSegmentDistance(
                        target,
                        points.first,
                        points.last,
                      ) <
                      0.035)) {
            items.removeAt(i);
            return true;
          }
        }
        return false;
      }

      if (removeNearest(scene.drawings)) return;
      if (removeNearest(scene.lights)) return;
      if (removeNearest(scene.triggers)) return;
      for (var i = scene.walls.length - 1; i >= 0; i--) {
        final a = OculumVttPoint.fromJson(scene.walls[i]['a']);
        final b = OculumVttPoint.fromJson(scene.walls[i]['b']);
        if (_oculumVttPointSegmentDistance(
              target,
              Offset(a.x, a.y),
              Offset(b.x, b.y),
            ) <
            0.035) {
          scene.walls.removeAt(i);
          return;
        }
      }
      final layer = scene.fogLayers[vttFogAudience];
      if (layer != null && layer.isNotEmpty) layer.removeLast();
    });
  }

  Future<void> showVttCanvasContextMenu(
    Offset globalPosition,
    Offset localPosition,
    Size size,
  ) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final point = OculumVttPoint.fromOffset(localPosition, size);
    final contextScene = vttSceneForDisplay();
    final normalizedTarget = Offset(point.x, point.y);
    final hitRadius = max(0.012, 18 / max(1.0, min(size.width, size.height)));
    Map<String, dynamic>? nearbyWall;
    var nearbyWallDistance = double.infinity;
    for (final wall in contextScene.walls) {
      final a = OculumVttPoint.fromJson(wall['a']);
      final b = OculumVttPoint.fromJson(wall['b']);
      final distance = _oculumVttPointSegmentDistance(
        normalizedTarget,
        Offset(a.x, a.y),
        Offset(b.x, b.y),
      );
      if (distance <= hitRadius && distance < nearbyWallDistance) {
        nearbyWall = wall;
        nearbyWallDistance = distance;
      }
    }
    final nearbyIsDoor = '${nearbyWall?['type'] ?? 'wall'}' == 'door';
    final nearbyDoorOpen = _oculumVttBool(nearbyWall?['open']);
    final nearbyDoorSecret = _oculumVttBool(nearbyWall?['secret']);
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(globalPosition, globalPosition),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        if (vttCanPing)
          PopupMenuItem(
            value: 'ping',
            child: ListTile(
              leading: const Icon(Icons.gps_fixed),
              title: const Text('Ping'),
            ),
          ),
        if (vttCanManageMap) ...<PopupMenuEntry<String>>[
          PopupMenuItem(
            value: 'note',
            child: ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: Text(t('Aggiungi nota', 'Add note')),
            ),
          ),
          PopupMenuItem(
            value: 'light',
            child: ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: Text(t('Aggiungi luce', 'Add light')),
            ),
          ),
          PopupMenuItem(
            value: 'reveal',
            child: ListTile(
              leading: const Icon(Icons.visibility),
              title: Text(t('Rivela qui', 'Reveal here')),
            ),
          ),
          PopupMenuItem(
            value: 'hide',
            child: ListTile(
              leading: const Icon(Icons.visibility_off),
              title: Text(t('Nascondi qui', 'Hide here')),
            ),
          ),
          if (nearbyIsDoor) ...<PopupMenuEntry<String>>[
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'toggle_door',
              child: ListTile(
                leading: Icon(
                  nearbyDoorOpen ? Icons.door_front_door : Icons.sensor_door,
                ),
                title: Text(
                  nearbyDoorOpen
                      ? t('Chiudi porta', 'Close door')
                      : t('Apri porta', 'Open door'),
                ),
              ),
            ),
            PopupMenuItem(
              value: 'toggle_secret',
              child: ListTile(
                leading: Icon(
                  nearbyDoorSecret ? Icons.visibility : Icons.visibility_off,
                ),
                title: Text(
                  nearbyDoorSecret
                      ? t('Rendi porta visibile', 'Reveal door')
                      : t('Rendi porta segreta', 'Make door secret'),
                ),
              ),
            ),
          ],
          if (nearbyWall != null)
            PopupMenuItem(
              value: 'remove_wall',
              child: ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(
                  nearbyIsDoor
                      ? t('Rimuovi porta', 'Remove door')
                      : t('Rimuovi parete', 'Remove wall'),
                ),
              ),
            ),
          PopupMenuItem(
            value: 'paste_token',
            child: ListTile(
              leading: const Icon(Icons.content_paste),
              title: Text(t('Incolla token', 'Paste token')),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'undo',
            enabled: vttUndoHistory.isNotEmpty,
            child: ListTile(
              leading: const Icon(Icons.undo),
              title: Text(t('Annulla', 'Undo')),
            ),
          ),
          PopupMenuItem(
            value: 'redo',
            enabled: vttRedoHistory.isNotEmpty,
            child: ListTile(
              leading: const Icon(Icons.redo),
              title: Text(t('Ripristina', 'Redo')),
            ),
          ),
        ],
        if (!vttCanManageMap && vttCanOpenDoors && nearbyIsDoor)
          PopupMenuItem(
            value: 'toggle_door',
            child: ListTile(
              leading: Icon(
                nearbyDoorOpen ? Icons.door_front_door : Icons.sensor_door,
              ),
              title: Text(
                nearbyDoorOpen
                    ? t('Chiudi porta', 'Close door')
                    : t('Apri porta', 'Open door'),
              ),
            ),
          ),
        PopupMenuItem(
          value: 'reset_view',
          child: ListTile(
            leading: const Icon(Icons.center_focus_strong),
            title: Text(t('Centra vista', 'Center view')),
          ),
        ),
      ],
    );
    if (!mounted || choice == null) return;
    void mutateNearbyWall(void Function(Map<String, dynamic> wall) update) {
      final wallId = '${nearbyWall?['id'] ?? ''}';
      if (wallId.isEmpty) return;
      void apply(OculumVttScene scene) {
        final index = scene.walls.indexWhere(
          (wall) => '${wall['id'] ?? ''}' == wallId,
        );
        if (index >= 0) update(scene.walls[index]);
      }

      if (vttCanManageMap) {
        mutateActiveVttScene(apply);
      } else if (vttCanOpenDoors && vttShowingRemoteScene) {
        final scene = realtimeVisibleVttScene;
        if (scene == null) return;
        apply(scene);
        vttCanvasRevision.value++;
        final door = scene.walls.where(
          (wall) => '${wall['id'] ?? ''}' == wallId,
        );
        if (door.isNotEmpty) {
          unawaited(
            sendRealtimeVttDoorState(
              door.first,
              _oculumVttBool(door.first['open']),
            ),
          );
        }
      } else if (vttCanOpenDoors) {
        apply(activeVttScene);
        activeVttScene.touch();
        vttCanvasRevision.value++;
        programmaSalvataggio(invalidateCaches: false);
      }
    }

    switch (choice) {
      case 'ping':
        addVttPing(point);
        break;
      case 'note':
        await showVttNoteEditor(point);
        break;
      case 'light':
        addVttLight(point);
        break;
      case 'reveal':
        mutateActiveVttScene((scene) {
          scene.fogEnabled = true;
          scene.fogLayers
              .putIfAbsent(vttFogAudience, () => <Map<String, dynamic>>[])
              .add(<String, dynamic>{
                'id': oculumVttGenerateId('fog'),
                'mode': 'reveal',
                'shape': 'circle',
                'points': <List<double>>[
                  <double>[max(0, point.x - 0.06), max(0, point.y - 0.06)],
                  <double>[min(1, point.x + 0.06), min(1, point.y + 0.06)],
                ],
              });
        });
        break;
      case 'hide':
        mutateActiveVttScene((scene) {
          scene.fogEnabled = true;
          scene.fogLayers
              .putIfAbsent(vttFogAudience, () => <Map<String, dynamic>>[])
              .add(<String, dynamic>{
                'id': oculumVttGenerateId('fog'),
                'mode': 'hide',
                'shape': 'circle',
                'points': <List<double>>[
                  <double>[max(0, point.x - 0.06), max(0, point.y - 0.06)],
                  <double>[min(1, point.x + 0.06), min(1, point.y + 0.06)],
                ],
              });
        });
        break;
      case 'toggle_door':
        mutateNearbyWall((wall) => wall['open'] = !nearbyDoorOpen);
        break;
      case 'toggle_secret':
        mutateNearbyWall((wall) => wall['secret'] = !nearbyDoorSecret);
        break;
      case 'remove_wall':
        final wallId = '${nearbyWall?['id'] ?? ''}';
        if (wallId.isNotEmpty) {
          mutateActiveVttScene((scene) {
            scene.walls.removeWhere((wall) => '${wall['id'] ?? ''}' == wallId);
          });
        }
        break;
      case 'paste_token':
        await incollaTokenImmagineMappa();
        break;
      case 'undo':
        undoVttChange();
        break;
      case 'redo':
        redoVttChange();
        break;
      case 'reset_view':
        resetMapView();
        break;
    }
  }

  Offset vttConstrainTokenDelta(
    Map<String, dynamic> token,
    Offset requested,
    double width,
    double height,
  ) {
    if (!vttModuleEnabled('walls_doors') ||
        (modalitaMaster && vttState.masterBypassCollisions)) {
      return requested;
    }
    final start = Offset(
      localMapTokenAxis(token, 'x'),
      localMapTokenAxis(token, 'y'),
    );
    final end = Offset(
      (start.dx + requested.dx / max(1.0, width)).clamp(0.0, 1.0),
      (start.dy + requested.dy / max(1.0, height)).clamp(0.0, 1.0),
    );
    return oculumVttMovementBlocked(start, end, activeVttScene.walls)
        ? Offset.zero
        : requested;
  }

  void evaluateVttTriggersForToken(Map<String, dynamic> token) {
    if (!vttModuleEnabled('triggers') || activeVttScene.triggers.isEmpty) {
      return;
    }
    final position = Offset(
      localMapTokenAxis(token, 'x'),
      localMapTokenAxis(token, 'y'),
    );
    final tokenId = '${token['id'] ?? token['sheetTag'] ?? 'token'}';
    String? sceneToActivate;
    var changed = false;
    for (final trigger in activeVttScene.triggers) {
      if (!_oculumVttBool(trigger['enabled'], true)) continue;
      final points = trigger['points'] is List
          ? (trigger['points'] as List)
                .map(OculumVttPoint.fromJson)
                .map((point) => Offset(point.x, point.y))
                .toList(growable: false)
          : const <Offset>[];
      if (points.isEmpty ||
          !_oculumVttRectFromPoints(points).contains(position)) {
        continue;
      }
      final firedFor = trigger['firedFor'] is List
          ? (trigger['firedFor'] as List).map((value) => '$value').toList()
          : <String>[];
      if (_oculumVttBool(trigger['once']) && firedFor.contains(tokenId)) {
        continue;
      }
      final action = '${trigger['action'] ?? 'message'}';
      final payload = '${trigger['payload'] ?? ''}'.trim();
      switch (action) {
        case 'scene':
          final target = vttState.scenes.firstWhere(
            (scene) =>
                scene.id == payload ||
                scene.name.toLowerCase() == payload.toLowerCase(),
            orElse: () => activeVttScene,
          );
          if (target.id != activeVttScene.id) sceneToActivate = target.id;
          break;
        case 'teleport':
          final coordinates = payload
              .split(RegExp(r'[,; ]+'))
              .map((value) => double.tryParse(value.replaceAll(',', '.')))
              .whereType<double>()
              .toList();
          if (coordinates.length >= 2) {
            token['x'] = coordinates[0].clamp(0.0, 1.0).toDouble();
            token['y'] = coordinates[1].clamp(0.0, 1.0).toDouble();
          }
          break;
        case 'status':
          final conditions = token['conditions'] is List
              ? (token['conditions'] as List).map((value) => '$value').toList()
              : <String>[];
          if (payload.isNotEmpty && !conditions.contains(payload)) {
            conditions.add(payload);
            token['conditions'] = conditions;
          }
          break;
        case 'initiative':
          if (canSendLocalMapTokenToInitiative(token)) {
            sendLocalMapTokenToInitiative(token);
          }
          break;
        case 'reveal':
          activeVttScene.fogEnabled = true;
          activeVttScene.fogLayers
              .putIfAbsent(vttFogAudience, () => <Map<String, dynamic>>[])
              .add(<String, dynamic>{
                'id': oculumVttGenerateId('fog'),
                'mode': 'reveal',
                'shape': 'circle',
                'points': <List<double>>[
                  <double>[
                    max(0, position.dx - 0.05),
                    max(0, position.dy - 0.05),
                  ],
                  <double>[
                    min(1, position.dx + 0.05),
                    min(1, position.dy + 0.05),
                  ],
                ],
              });
          break;
        default:
          if (payload.isNotEmpty) {
            risultato = payload;
            aggiungiLog(payload);
          }
      }
      if (_oculumVttBool(trigger['once'])) {
        firedFor.add(tokenId);
        trigger['firedFor'] = firedFor;
      }
      changed = true;
    }
    if (!changed) return;
    activeVttScene.tokens = localMapTokens
        .map((item) => _oculumVttDeepMap(item))
        .toList(growable: true);
    activeVttScene.touch();
    notifyVttCanvasChanged(save: true, publish: true);
    if (sceneToActivate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) activateVttScene(sceneToActivate!);
      });
    }
  }
}
