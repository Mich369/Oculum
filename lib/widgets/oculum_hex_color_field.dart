import 'package:flutter/material.dart';

/// Accepts pasted tags as well as the plain six-digit form used by older saves.
/// Eight-digit colours follow Flutter's explicit AARRGGBB order.
Color? oculumColorFromHex(String input) {
  var text = input.trim();
  if (text.startsWith('#')) text = text.substring(1);
  if (text.toLowerCase().startsWith('0x')) text = text.substring(2);
  if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(text)) return null;
  if (text.length == 3) text = text.split('').map((c) => '$c$c').join();
  if (text.length != 6 && text.length != 8) return null;
  final value = int.tryParse(text, radix: 16);
  return value == null
      ? null
      : Color(text.length == 6 ? 0xff000000 | value : value);
}

String oculumColorHex(Color color) {
  final raw = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  return raw.startsWith('FF') ? '#${raw.substring(2)}' : '0x$raw';
}

class OculumHexColorField extends StatefulWidget {
  const OculumHexColorField({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final Color value;
  final ValueChanged<Color> onChanged;
  @override
  State<OculumHexColorField> createState() => _OculumHexColorFieldState();
}

class _OculumHexColorFieldState extends State<OculumHexColorField> {
  late final TextEditingController text = TextEditingController(
    text: oculumColorHex(widget.value),
  );
  final FocusNode focus = FocusNode();
  String? error;
  @override
  void didUpdateWidget(covariant OculumHexColorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !focus.hasFocus) {
      text.text = oculumColorHex(widget.value);
    }
  }

  void apply() {
    final color = oculumColorFromHex(text.text);
    setState(
      () => error = color == null ? 'Usa #RRGGBB, #RGB o 0xAARRGGBB' : null,
    );
    if (color != null) {
      text.text = oculumColorHex(color);
      widget.onChanged(color);
    }
  }

  @override
  void dispose() {
    text.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: text,
    focusNode: focus,
    maxLength: 10,
    autocorrect: false,
    enableSuggestions: false,
    decoration: InputDecoration(
      labelText: 'Colore HEX',
      hintText: '#7B61FF',
      errorText: error,
      counterText: '',
      suffixIcon: IconButton(
        tooltip: 'Applica colore HEX',
        onPressed: apply,
        icon: const Icon(Icons.check),
      ),
    ),
    onChanged: (_) {
      if (error != null) setState(() => error = null);
    },
    onSubmitted: (_) => apply(),
  );
}
