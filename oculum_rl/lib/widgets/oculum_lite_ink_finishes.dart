import 'package:flutter/material.dart';

import 'oculum_lite_appearance.dart';

class OculumLiteInkFinishPicker extends StatelessWidget {
  const OculumLiteInkFinishPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.assassinTacticalAvailable = false,
  });

  final LiteInkFinish selected;
  final ValueChanged<LiteInkFinish>? onChanged;
  final bool assassinTacticalAvailable;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'Finitura d’inchiostro',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 3),
      Wrap(
        spacing: 6,
        runSpacing: 3,
        children: [
          for (final finish in LiteInkFinish.values)
            if (finish != LiteInkFinish.tattica || assassinTacticalAvailable)
              ChoiceChip(
                avatar: CircleAvatar(backgroundColor: finish.color),
                label: Text(finish.label),
                selected: finish == selected,
                onSelected: onChanged == null
                    ? null
                    : (active) {
                        if (active) onChanged!(finish);
                      },
              ),
        ],
      ),
    ],
  );
}
