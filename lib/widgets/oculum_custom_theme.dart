import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Portable decoration data. Positions and sizes are fractions of the viewport.
final oculumCustomArtwork = ValueNotifier<Map<String, dynamic>>({});
Future<void> loadOculumCustomArtwork() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('oculum.customArtwork.v1');
  if (raw == null) return;
  try {
    oculumCustomArtwork.value = decodeOculumArtwork(raw);
  } catch (_) {
    /* Keep the last usable theme. */
  }
}

Map<String, dynamic> decodeOculumArtwork(String code) {
  if (code.length > 24000000) {
    throw const FormatException('Codice troppo grande');
  }
  final value = jsonDecode(
    utf8.decode(base64Decode(code.replaceFirst('OCULUM1:', '').trim())),
  );
  if (value is! Map ||
      value['version'] != 1 ||
      value['layers'] is! List ||
      (value['layers'] as List).length > 12) {
    throw const FormatException('Tema non valido');
  }
  for (final layer in value['layers']) {
    if (layer is! Map || layer['image'] is! String) {
      throw const FormatException('Layer non valido');
    }
    final bytes = base64Decode(layer['image']);
    if (bytes.length > 1500000) {
      throw const FormatException('Immagine troppo grande');
    }
    for (final key in ['x', 'y', 'size', 'opacity', 'rotation']) {
      if (layer[key] is! num || !(layer[key] as num).isFinite) {
        throw const FormatException('Posizione non valida');
      }
    }
  }
  final colors = value['colors'];
  if (colors != null &&
      (colors is! Map ||
          colors.values.any((v) => v is! int || v < 0 || v > 0xffffffff))) {
    throw const FormatException('Colore non valido');
  }
  return {
    ...Map<String, dynamic>.from(value),
    'enabled': value['enabled'] == true,
    'colors': colors ?? <String, dynamic>{},
  };
}

String encodeOculumArtwork(Map<String, dynamic> value) =>
    'OCULUM1:${base64Encode(utf8.encode(jsonEncode(value)))}';
Color? oculumCustomStatColor(String key) {
  final value = (oculumCustomArtwork.value['colors'] as Map?)?[key];
  return value is int ? Color(value) : null;
}

class OculumCustomArtworkLayer extends StatelessWidget {
  const OculumCustomArtworkLayer({super.key, this.preview});
  final Map<String, dynamic>? preview;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: ValueListenableBuilder<Map<String, dynamic>>(
        valueListenable: oculumCustomArtwork,
        builder: (context, data, _) => LayoutBuilder(
          builder: (context, box) {
            final scene = preview ?? data;
            final layers = scene['enabled'] == true
                ? (scene['layers'] as List? ?? [])
                : [];
            return ClipRect(
              child: Stack(
                children: [
                  for (final layer in layers)
                    Positioned(
                      left:
                          (layer['x'] as num).toDouble().clamp(0, 1) *
                          box.maxWidth,
                      top:
                          (layer['y'] as num).toDouble().clamp(0, 1) *
                          box.maxHeight,
                      width:
                          (layer['size'] as num).toDouble().clamp(.03, 2) *
                          box.maxWidth,
                      child: FractionalTranslation(
                        translation: const Offset(-.5, -.5),
                        child: Transform.rotate(
                          angle: (layer['rotation'] as num).toDouble(),
                          child: Opacity(
                            opacity:
                                (layer['opacity'] as num).toDouble().clamp(
                                  0,
                                  .45,
                                ) /
                                layers.length,
                            child: RepaintBoundary(
                              child: Image.memory(
                                base64Decode(layer['image']),
                                gaplessPlayback: true,
                                fit: BoxFit.contain,
                                errorBuilder: (_, error, stack) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

class OculumCustomThemeEditor extends StatefulWidget {
  const OculumCustomThemeEditor({super.key});
  @override
  State<OculumCustomThemeEditor> createState() =>
      _OculumCustomThemeEditorState();
}

class _OculumCustomThemeEditorState extends State<OculumCustomThemeEditor> {
  late Map<String, dynamic> draft;
  String? error;
  @override
  void initState() {
    super.initState();
    draft = jsonDecode(
      jsonEncode({
        'version': 1,
        'enabled': true,
        'layers': [],
        'colors': {},
        ...oculumCustomArtwork.value,
      }),
    );
  }

  List get layers => draft['layers'];
  Widget slider(Map layer, String key, String label, double min, double max) =>
      Row(
        children: [
          SizedBox(width: 85, child: Text(label)),
          Expanded(
            child: Slider(
              value: (layer[key] as num).toDouble().clamp(min, max),
              min: min,
              max: max,
              onChanged: (v) => setState(() => layer[key] = v),
            ),
          ),
        ],
      );
  Future<void> upload() async {
    try {
      final images = await ImagePicker().pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
      );
      for (final image in images) {
        if (layers.length >= 12) {
          throw const FormatException('Massimo 12 immagini');
        }
        final Uint8List bytes = await image.readAsBytes();
        if (bytes.length > 1500000) {
          throw const FormatException('Ogni immagine deve essere sotto 1,5 MB');
        }
        layers.add({
          'image': base64Encode(bytes),
          'x': .5,
          'y': .5,
          'size': .3,
          'opacity': .25,
          'rotation': 0,
        });
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> addMotif(String name) async {
    if (layers.length >= 12) return;
    final data = await rootBundle.load('assets/oculum/atelier/$name.png');
    if (!mounted) return;
    setState(
      () => layers.add({
        'image': base64Encode(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        ),
        'x': .92,
        'y': .15,
        'size': .08,
        'opacity': .3,
        'rotation': 0,
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Atelier · Tema personale')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Le immagini sono decorazioni: clic e tocchi passano sempre ai comandi. Il codice include le immagini. Massimo 12 layer, 1,5 MB ciascuno.',
        ),
        SwitchListTile(
          title: const Text('Decorazioni attive'),
          value: draft['enabled'] == true,
          onChanged: (v) => setState(() => draft['enabled'] = v),
        ),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              onPressed: upload,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Carica immagini'),
            ),
            OutlinedButton(
              onPressed: () async {
                final text = TextEditingController();
                final value = await showDialog<String>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Importa codice tema'),
                    content: TextField(controller: text, maxLines: 4),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annulla'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, text.text),
                        child: const Text('Importa'),
                      ),
                    ],
                  ),
                );
                text.dispose();
                if (value != null && mounted) {
                  try {
                    final decoded = decodeOculumArtwork(value);
                    setState(() {
                      draft = decoded;
                      error = null;
                    });
                  } catch (e) {
                    setState(() => error = '$e');
                  }
                }
              },
              child: const Text('Importa codice'),
            ),
            OutlinedButton(
              onPressed: () => Clipboard.setData(
                ClipboardData(text: encodeOculumArtwork(draft)),
              ),
              child: const Text('Copia codice'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Center(
                  child: Text('Anteprima · i comandi restano utilizzabili'),
                ),
                OculumCustomArtworkLayer(preview: draft),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: () =>
              setState(() => draft['colors'] = <String, dynamic>{}),
          child: const Text('Ripristina colori originali'),
        ),

        Wrap(
          spacing: 8,
          children: [
            for (final name in ['oculo', 'cuspide', 'reliquiario'])
              OutlinedButton.icon(
                onPressed: layers.length >= 12 ? null : () => addMotif(name),
                icon: Image.asset(
                  'assets/oculum/atelier/$name.png',
                  width: 24,
                  height: 24,
                ),
                label: Text(name),
              ),
          ],
        ),
        const Text('Colori statistiche · selettore RGB e tonalità'),
        for (final entry in {
          'resilienza': '2ECC71',
          'volonta': 'E74C3C',
          'materia': '44A7FF',
          'oculum': '8B5CF6',
        }.entries)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(
                draft['colors'][entry.key] as int? ??
                    (0xff000000 | int.parse(entry.value, radix: 16)),
              ),
            ),
            title: Text(entry.key),
            subtitle: const Text('Tonalità · saturazione · RGB · HEX'),
            trailing: const Icon(Icons.palette_outlined),
            onTap: () async {
              final picked = await showDialog<Color>(
                context: context,
                builder: (_) => OculumStatColorPicker(
                  initial: Color(
                    draft['colors'][entry.key] as int? ??
                        (0xff000000 | int.parse(entry.value, radix: 16)),
                  ),
                  label: entry.key,
                ),
              );
              if (picked != null && mounted) {
                setState(() => draft['colors'][entry.key] = picked.toARGB32());
              }
            },
          ),
        for (var i = 0; i < layers.length; i++)
          Card(
            child: ExpansionTile(
              title: Text('Layer ${i + 1}'),
              leading: Image.memory(
                base64Decode(layers[i]['image']),
                width: 40,
                height: 40,
                errorBuilder: (_, error, stack) =>
                    const Icon(Icons.broken_image_outlined),
              ),
              children: [
                slider(layers[i], 'x', 'Orizzontale', 0, 1),
                slider(layers[i], 'y', 'Verticale', 0, 1),
                slider(layers[i], 'size', 'Dimensione', .03, 2),
                slider(layers[i], 'opacity', 'Opacità', 0, .45),
                slider(layers[i], 'rotation', 'Rotazione', -3.14, 3.14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Sposta sotto',
                      onPressed: i == 0
                          ? null
                          : () => setState(() {
                              final item = layers.removeAt(i);
                              layers.insert(i - 1, item);
                            }),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    IconButton(
                      tooltip: 'Sposta sopra',
                      onPressed: i == layers.length - 1
                          ? null
                          : () => setState(() {
                              final item = layers.removeAt(i);
                              layers.insert(i + 1, item);
                            }),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      tooltip: 'Rimuovi',
                      onPressed: () => setState(() => layers.removeAt(i)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        FilledButton(
          onPressed: () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              final encoded = encodeOculumArtwork(draft);
              final checked = decodeOculumArtwork(encoded);
              final saved = await prefs.setString(
                'oculum.customArtwork.v1',
                encoded,
              );
              if (!saved) {
                throw const FormatException('Salvataggio non riuscito');
              }
              oculumCustomArtwork.value = checked;
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              if (mounted) {
                setState(
                  () => error =
                      'Impossibile salvare: $e. Riduci le immagini o copia il codice.',
                );
              }
            }
          },
          child: const Text('Salva tema'),
        ),
      ],
    ),
  );
}

class OculumStatColorPicker extends StatefulWidget {
  const OculumStatColorPicker({
    super.key,
    required this.initial,
    required this.label,
  });
  final Color initial;
  final String label;
  @override
  State<OculumStatColorPicker> createState() => _OculumStatColorPickerState();
}

class _OculumStatColorPickerState extends State<OculumStatColorPicker> {
  late HSVColor hsv;
  late TextEditingController hex;
  Color get color => hsv.toColor().withValues(alpha: 1);
  String code(Color c) =>
      c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  @override
  void initState() {
    super.initState();
    hsv = HSVColor.fromColor(widget.initial);
    hex = TextEditingController(text: code(color));
  }

  @override
  void dispose() {
    hex.dispose();
    super.dispose();
  }

  void update(HSVColor next) => setState(() {
    hsv = next;
    hex.text = code(color);
  });
  Widget channel(
    String label,
    double value,
    ValueChanged<double> changed, {
    double max = 1,
  }) => Row(
    children: [
      SizedBox(width: 62, child: Text(label)),
      Expanded(
        child: Slider(
          value: value.clamp(0, max),
          max: max,
          label: '${(value * (max == 1 ? 100 : 1)).round()}',
          onChanged: changed,
        ),
      ),
      SizedBox(
        width: 36,
        child: Text('${(value * (max == 1 ? 100 : 1)).round()}'),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text('Colore · ${widget.label}'),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 160,
            child: LayoutBuilder(
              builder: (context, box) {
                void locate(Offset offset) => update(
                  hsv
                      .withSaturation((offset.dx / box.maxWidth).clamp(0, 1))
                      .withValue((1 - offset.dy / box.maxHeight).clamp(0, 1)),
                );
                return GestureDetector(
                  onPanDown: (e) => locate(e.localPosition),
                  onPanUpdate: (e) => locate(e.localPosition),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                            ],
                          ),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black],
                          ),
                        ),
                      ),
                      Positioned(
                        left: (hsv.saturation * box.maxWidth - 7).clamp(
                          0,
                          box.maxWidth - 14,
                        ),
                        top: ((1 - hsv.value) * box.maxHeight - 7).clamp(
                          0,
                          box.maxHeight - 14,
                        ),
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black, blurRadius: 2),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          channel('Tonalità', hsv.hue, (v) => update(hsv.withHue(v)), max: 360),
          channel(
            'Saturaz.',
            hsv.saturation,
            (v) => update(hsv.withSaturation(v)),
          ),
          channel('Luce', hsv.value, (v) => update(hsv.withValue(v))),
          const Divider(),
          for (final entry in [('R', color.r), ('G', color.g), ('B', color.b)])
            channel(entry.$1, entry.$2 * 255, (v) {
              final c = Color.fromARGB(
                255,
                entry.$1 == 'R' ? v.round() : (color.r * 255).round(),
                entry.$1 == 'G' ? v.round() : (color.g * 255).round(),
                entry.$1 == 'B' ? v.round() : (color.b * 255).round(),
              );
              update(HSVColor.fromColor(c));
            }, max: 255),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.initial,
                  border: Border.all(color: Colors.grey),
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: hex,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'HEX',
                    prefixText: '#',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                  ],
                  onChanged: (v) {
                    if (v.length == 6) {
                      setState(
                        () => hsv = HSVColor.fromColor(
                          Color(0xff000000 | int.parse(v, radix: 16)),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const Text('Sinistra: colore precedente · destra: anteprima'),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annulla'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, color),
        child: const Text('Usa colore'),
      ),
    ],
  );
}
