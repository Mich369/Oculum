import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../game/oculum_portrait_gif.dart';

enum _PortraitMotion { up, sideways, diagonal, approach, reveal }

typedef OculumPortraitGifResult = ({Uint8List bytes, bool apply});

class OculumPortraitGifEditor extends StatefulWidget {
  const OculumPortraitGifEditor({
    super.key,
    required this.source,
    required this.preview,
    required this.english,
  });

  final Uint8List source;
  final ({Uint8List bytes, int width, int height}) preview;
  final bool english;

  @override
  State<OculumPortraitGifEditor> createState() =>
      _OculumPortraitGifEditorState();
}

class _OculumPortraitGifEditorState extends State<OculumPortraitGifEditor> {
  _PortraitMotion motion = _PortraitMotion.up;
  OculumPortraitPosition start = (x: 0, y: 1, zoom: 1.25);
  OculumPortraitPosition end = (x: 0, y: -1, zoom: 1.25);
  bool editEnd = false;
  bool returnTrip = true;
  bool rendering = false;
  int milliseconds = 2200;
  Uint8List? gif;
  String? error;

  String tr(String italian, String english) =>
      widget.english ? english : italian;

  String motionName(_PortraitMotion value) => switch (value) {
    _PortraitMotion.up => tr('Dal basso verso l’alto', 'Bottom to top'),
    _PortraitMotion.sideways => tr('Scorrimento laterale', 'Sideways pan'),
    _PortraitMotion.diagonal => tr('Scorrimento diagonale', 'Diagonal pan'),
    _PortraitMotion.approach => tr('Avvicinamento lento', 'Slow push in'),
    _PortraitMotion.reveal => tr('Dal dettaglio all’insieme', 'Pull back'),
  };

  void edit(VoidCallback change) {
    setState(() {
      change();
      gif = null;
      error = null;
    });
  }

  void chooseMotion(_PortraitMotion value) {
    edit(() {
      motion = value;
      final (OculumPortraitPosition, OculumPortraitPosition) positions =
          switch (motion) {
            _PortraitMotion.up => (
              (x: 0, y: 1, zoom: 1.25),
              (x: 0, y: -1, zoom: 1.25),
            ),
            _PortraitMotion.sideways => (
              (x: -1, y: 0, zoom: 1.25),
              (x: 1, y: 0, zoom: 1.25),
            ),
            _PortraitMotion.diagonal => (
              (x: -1, y: 1, zoom: 1.25),
              (x: 1, y: -1, zoom: 1.25),
            ),
            _PortraitMotion.approach => (
              (x: 0, y: 0, zoom: 1.0),
              (x: 0, y: 0, zoom: 1.7),
            ),
            _PortraitMotion.reveal => (
              (x: 0, y: -0.4, zoom: 1.7),
              (x: 0, y: 0, zoom: 1.0),
            ),
          };
      start = positions.$1;
      end = positions.$2;
    });
  }

  void changePoint(OculumPortraitPosition point) {
    edit(() {
      if (editEnd) {
        end = point;
      } else {
        start = point;
      }
    });
  }

  Future<void> render() async {
    if (rendering) return;
    setState(() {
      rendering = true;
      error = null;
    });
    final request = (
      source: widget.source,
      start: start,
      end: end,
      milliseconds: milliseconds,
      returnTrip: returnTrip,
    );
    Uint8List? result;
    try {
      result = kIsWeb
          ? await oculumRenderPortraitGif(request, yieldBetweenFrames: true)
          : await compute(oculumRenderPortraitGif, request);
    } catch (_) {
      result = null;
    }
    if (!mounted) return;
    setState(() {
      rendering = false;
      gif = result;
      if (result == null) {
        error = tr(
          'Impossibile creare la GIF. Prova con un’immagine più piccola.',
          'Could not create the GIF. Try a smaller image.',
        );
      }
    });
  }

  Widget slider(
    String label,
    double value,
    double lower,
    double upper,
    ValueChanged<double> change, {
    int? divisions,
    String? valueLabel,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label · ${valueLabel ?? value.toStringAsFixed(2)}'),
      Semantics(
        label: label,
        child: Slider(
          value: value,
          min: lower,
          max: upper,
          divisions: divisions,
          onChanged: rendering ? null : change,
        ),
      ),
    ],
  );

  Widget preview(OculumPortraitPosition point) {
    final animation = gif;
    if (animation != null) {
      return TickerMode(
        enabled: !MediaQuery.disableAnimationsOf(context),
        child: Image.memory(animation, fit: BoxFit.cover),
      );
    }
    final source = widget.preview;
    final crop = oculumPortraitAnimationCrop(
      source.width,
      source.height,
      point,
    );
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / crop.side;
          return Stack(
            children: [
              Positioned(
                left: -crop.x * scale,
                top: -crop.y * scale,
                width: source.width * scale,
                height: source.height * scale,
                child: Image.memory(source.bytes, fit: BoxFit.fill),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final point = editEnd ? end : start;
    final animation = gif;
    return AlertDialog(
      key: const ValueKey('portrait-gif-editor'),
      title: Text(tr('Crea GIF ritratto', 'Create portrait GIF')),
      scrollable: true,
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SizedBox.square(dimension: 152, child: preview(point)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_PortraitMotion>(
              initialValue: motion,
              isExpanded: true,
              decoration: InputDecoration(labelText: tr('Movimento', 'Motion')),
              items: [
                for (final preset in _PortraitMotion.values)
                  DropdownMenuItem(
                    value: preset,
                    child: Text(motionName(preset)),
                  ),
              ],
              onChanged: rendering
                  ? null
                  : (value) {
                      if (value != null) chooseMotion(value);
                    },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(tr('Inizio', 'Start')),
                  selected: !editEnd,
                  onSelected: rendering
                      ? null
                      : (_) => setState(() {
                          editEnd = false;
                          gif = null;
                        }),
                ),
                ChoiceChip(
                  label: Text(tr('Fine', 'End')),
                  selected: editEnd,
                  onSelected: rendering
                      ? null
                      : (_) => setState(() {
                          editEnd = true;
                          gif = null;
                        }),
                ),
              ],
            ),
            slider(
              tr('Orizzontale', 'Horizontal'),
              point.x,
              -1,
              1,
              (x) => changePoint((x: x, y: point.y, zoom: point.zoom)),
            ),
            slider(
              tr('Verticale', 'Vertical'),
              point.y,
              -1,
              1,
              (y) => changePoint((x: point.x, y: y, zoom: point.zoom)),
            ),
            slider(
              'Zoom',
              point.zoom,
              1,
              3,
              (zoom) => changePoint((x: point.x, y: point.y, zoom: zoom)),
            ),
            slider(
              tr('Durata', 'Duration'),
              milliseconds.toDouble(),
              1000,
              3500,
              (value) => edit(() => milliseconds = value.round()),
              divisions: 25,
              valueLabel: '${(milliseconds / 1000).toStringAsFixed(1)} s',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr('Andata e ritorno', 'Play forward and back')),
              value: returnTrip,
              onChanged: rendering
                  ? null
                  : (value) => edit(() => returnTrip = value),
            ),
            if (rendering) const LinearProgressIndicator(),
            if (error != null) Text(error!),
            OutlinedButton.icon(
              onPressed: rendering ? null : render,
              icon: const Icon(Icons.play_arrow),
              label: Text(tr('Genera anteprima GIF', 'Generate GIF preview')),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('Annulla', 'Cancel')),
        ),
        TextButton(
          onPressed: animation == null || rendering
              ? null
              : () => Navigator.pop<OculumPortraitGifResult>(context, (
                  bytes: animation,
                  apply: false,
                )),
          child: Text(tr('Salva GIF', 'Save GIF')),
        ),
        FilledButton(
          onPressed: animation == null || rendering
              ? null
              : () => Navigator.pop<OculumPortraitGifResult>(context, (
                  bytes: animation,
                  apply: true,
                )),
          child: Text(tr('Usa come ritratto', 'Use as portrait')),
        ),
      ],
    );
  }
}
