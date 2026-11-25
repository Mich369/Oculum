import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/oculum_lite_run.dart';

class OculumLiteFloorMap extends StatefulWidget {
  const OculumLiteFloorMap({
    super.key,
    required this.run,
    this.followedAccount,
    this.tiny = false,
    this.onOpen,
    this.onMark,
    this.view,
  });
  final LiteRun run;
  final String? followedAccount;
  final bool tiny;
  final ValueChanged<bool>? onOpen;
  final VoidCallback? onMark;
  final Listenable? view;

  @override
  State<OculumLiteFloorMap> createState() => _OculumLiteFloorMapState();
}

class _OculumLiteFloorMapState extends State<OculumLiteFloorMap> {
  math.Point<double>? _localPin;
  String? _pinArena;

  math.Point<double>? get _pin => widget.onMark != null
      ? widget.run.mapWaypoint
      : _pinArena == widget.run.inputArena
      ? _localPin
      : null;

  Future<void> _show() async {
    final arena = widget.run.inputArena;
    widget.onOpen?.call(true);
    try {
      await showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, refresh) => AlertDialog(
            title: const Text('Mappa del piano'),
            content: SizedBox(
              width: 480,
              child: AspectRatio(
                aspectRatio: widget.run.width / widget.run.height,
                child: LayoutBuilder(
                  builder: (context, box) => GestureDetector(
                    onTapUp: (tap) {
                      if (widget.run.inputArena != arena) return;
                      final at = math.Point(
                        tap.localPosition.dx * widget.run.width / box.maxWidth,
                        tap.localPosition.dy *
                            widget.run.height /
                            box.maxHeight,
                      );
                      if (!widget.run.floorRooms.any(
                        (room) =>
                            widget.run.hasMapped(room.sector) &&
                            room.contains(at),
                      ))
                        return;
                      refresh(() {
                        if (widget.onMark != null) {
                          widget.run.markMapPoint(at);
                          widget.onMark!();
                        } else {
                          _pinArena = arena;
                          _localPin = at;
                        }
                      });
                    },
                    child: CustomPaint(painter: _painter(showLabels: true)),
                  ),
                ),
              ),
            ),
            actions: [
              if (_pin != null)
                TextButton(
                  onPressed: () => refresh(() {
                    if (widget.onMark != null) {
                      widget.run.markMapPoint(null);
                      widget.onMark!();
                    }
                    _localPin = null;
                  }),
                  child: const Text('Togli segno'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Chiudi'),
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {});
        widget.onOpen?.call(false);
      }
    }
  }

  _FloorMapPaint _painter({bool showLabels = false}) => _FloorMapPaint(
    widget.run,
    widget.followedAccount,
    _pin,
    showLabels,
    repaint: widget.view,
  );

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xf1211923),
    shape: const RoundedRectangleBorder(
      side: BorderSide(color: Color(0xff705654)),
      borderRadius: BorderRadius.all(Radius.circular(5)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Tooltip(
      message: 'Apri mappa del piano',
      child: InkWell(
        onTap: _show,
        child: SizedBox(
          width: widget.tiny ? 98 : 128,
          height: widget.tiny ? 63 : 82,
          child: CustomPaint(painter: _painter()),
        ),
      ),
    ),
  );
}

class _FloorMapPaint extends CustomPainter {
  _FloorMapPaint(
    this.run,
    this.followedAccount,
    this.pin,
    this.labels, {
    super.repaint,
  });
  final LiteRun run;
  final String? followedAccount;
  final math.Point<double>? pin;
  final bool labels;

  static const allies = [
    Color(0xffa8d9fa),
    Color(0xffffd486),
    Color(0xffe09bd6),
    Color(0xffa8aaff),
    Color(0xfffba68f),
    Color(0xffeee7dc),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final dx = size.width / run.width, dy = size.height / run.height;
    Offset p(math.Point<double> at) => Offset(at.x * dx, at.y * dy);
    final rooms = run.floorRooms;
    const outline = Color(0xff53434e);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xff18131c),
    );
    for (final room in rooms) {
      if (!run.hasMapped(room.sector)) continue;
      final rect = Rect.fromLTRB(
        room.left * dx,
        room.top * dy,
        room.right * dx,
        room.bottom * dy,
      ).deflate(labels ? 2.6 : 1.15);
      final shade = switch (room.sector) {
        LiteMapSector.ingresso => const Color(0xff413246),
        LiteMapSector.fianco => const Color(0xff3e4549),
        LiteMapSector.cuore => const Color(0xff514047),
        LiteMapSector.retro => const Color(0xff343d4d),
        LiteMapSector.uscita => const Color(0xff423a4d),
      };
      canvas.drawRect(rect, Paint()..color = shade);
      canvas.drawRect(
        rect,
        Paint()
          ..color = outline
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );
      if (!labels || rect.width < 36) continue;
      final name = TextPainter(
        text: TextSpan(
          text: room.label,
          style: const TextStyle(fontSize: 10, color: Color(0xffe2c9ae)),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: rect.width - 6);
      name.paint(canvas, rect.center - Offset(name.width / 2, name.height / 2));
    }
    for (final wall in run.obstacles) {
      if (wall.secretGate ||
          !rooms.any(
            (room) => run.hasMapped(room.sector) && room.contains(wall.center),
          ))
        continue;
      final rect = Rect.fromLTWH(
        wall.left * dx,
        wall.top * dy,
        wall.width * dx,
        wall.height * dy,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = wall.mapShortcut
              ? const Color(0xffc2825e)
              : const Color(0xff24202a),
      );
    }
    if (run.hasMapped(LiteMapSector.uscita)) {
      final q = p(run.portalPosition);
      canvas.drawCircle(
        q,
        labels ? 5 : 2.1,
        Paint()..color = const Color(0xffb69cdd),
      );
    }
    if (run.hasMapped(LiteMapSector.ingresso) && !run.usesSubArena) {
      final q = p(run.shopPosition);
      canvas.drawRect(
        Rect.fromCenter(
          center: q,
          width: labels ? 7 : 3,
          height: labels ? 7 : 3,
        ),
        Paint()..color = const Color(0xffdcac6f),
      );
    }
    if (run.secretRoomRevealed) {
      canvas.drawCircle(
        p(LiteRun.secretCache),
        labels ? 5 : 2.25,
        Paint()..color = const Color(0xffcba2e4),
      );
    }
    if (pin case final dest?) {
      final q = p(dest);
      final r = labels ? 6.0 : 3.0;
      final pen = Paint()
        ..color = const Color(0xfff8cf84)
        ..strokeWidth = 1.1;
      canvas.drawLine(q - Offset(r, 0), q + Offset(r, 0), pen);
      canvas.drawLine(q - Offset(0, r), q + Offset(0, r), pen);
    }
    void token(math.Point<double> at, int index, bool local) {
      final center = p(at);
      final radius = labels ? 5.0 : 2.9;
      if (local)
        canvas.drawCircle(
          center,
          radius + 1.3,
          Paint()..color = Colors.white70,
        );
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = allies[index % allies.length],
      );
    }

    token(run.position, 0, followedAccount == null);
    for (final fighter in run.coopFighters) {
      token(
        fighter.position,
        run.coopPlayerSeat(fighter),
        followedAccount == fighter.account,
      );
    }
  }

  @override
  bool shouldRepaint(_FloorMapPaint oldDelegate) => true;
}
