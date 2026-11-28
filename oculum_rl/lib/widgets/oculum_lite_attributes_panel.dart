import 'package:flutter/material.dart';

import '../game/oculum_lite_run.dart';

typedef LiteAttributePanelState = ({
  LiteAttributes scores,
  int? freePoints,
  bool canSpend,
});

class OculumLiteAttributesButton extends StatelessWidget {
  const OculumLiteAttributesButton({
    super.key,
    this.freePoints,
    required this.onPressed,
  });

  final int? freePoints;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const glyph = Icon(Icons.insights_outlined, color: Color(0xffefc48c));
    final points = freePoints ?? 0;
    return IconButton(
      tooltip: points == 0
          ? 'Caratteristiche'
          : 'Caratteristiche · $points ${points == 1 ? 'punto libero' : 'punti liberi'}',
      onPressed: onPressed,
      icon: points == 0
          ? glyph
          : Badge.count(
              count: points,
              backgroundColor: const Color(0xff914b3b),
              textColor: const Color(0xffffe9cd),
              child: glyph,
            ),
    );
  }
}

Future<void> showLiteAttributePanel(
  BuildContext context, {
  required Listenable refresh,
  required LiteAttributePanelState? Function() read,
  required ValueChanged<LiteAttribute> onSpend,
}) => showDialog<void>(
  context: context,
  builder: (context) => AnimatedBuilder(
    animation: refresh,
    builder: (context, _) {
      final sheet = read();
      return AlertDialog(
        title: const Text('Caratteristiche'),
        backgroundColor: const Color(0xff281e29),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xff68483f)),
        ),
        scrollable: true,
        content: sheet == null
            ? const Text('In attesa del personaggio.')
            : SizedBox(
                width: 456,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (sheet.freePoints case final int points)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Text(
                          '$points ${points == 1 ? 'punto libero' : 'punti liberi'}',
                          style: const TextStyle(
                            color: Color(0xffefc48c),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    for (final attribute in LiteAttribute.values)
                      _AttributeRow(
                        attribute: attribute,
                        value: sheet.scores[attribute],
                        onSpend: sheet.freePoints == null
                            ? null
                            : (sheet.freePoints! > 0 && sheet.canSpend
                                  ? () => onSpend(attribute)
                                  : null),
                        showSpend: sheet.freePoints != null,
                      ),
                  ],
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      );
    },
  ),
);

class _AttributeRow extends StatelessWidget {
  const _AttributeRow({
    required this.attribute,
    required this.value,
    required this.onSpend,
    required this.showSpend,
  });

  final LiteAttribute attribute;
  final int value;
  final VoidCallback? onSpend;
  final bool showSpend;

  @override
  Widget build(BuildContext context) {
    final (glyph, pigment) = switch (attribute) {
      LiteAttribute.resilienza => (
        Icons.favorite_border,
        const Color(0xff95c3a2),
      ),
      LiteAttribute.volonta => (
        Icons.local_fire_department_outlined,
        const Color(0xffdf987b),
      ),
      LiteAttribute.materia => (Icons.shield_outlined, const Color(0xff8eb9d5)),
      LiteAttribute.oculum => (
        Icons.visibility_outlined,
        const Color(0xffc5a1dd),
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: pigment.withValues(alpha: .68), width: 2),
          bottom: const BorderSide(color: Color(0xff463344)),
        ),
        color: const Color(0xff221a23),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          children: [
            Icon(glyph, color: pigment, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attribute.label,
                    style: TextStyle(
                      color: pigment,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    attribute.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$value',
              semanticsLabel: '${attribute.label} $value',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (showSpend)
              IconButton(
                onPressed: onSpend,
                tooltip: 'Aumenta ${attribute.label}',
                icon: const Icon(Icons.add),
              ),
          ],
        ),
      ),
    );
  }
}
