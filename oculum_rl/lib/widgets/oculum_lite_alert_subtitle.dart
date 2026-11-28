import 'package:flutter/material.dart';

import '../game/oculum_lite_alert_dialogue.dart';

class OculumLiteAlertSubtitle extends StatelessWidget {
  const OculumLiteAlertSubtitle({super.key, required this.presenter});

  final LiteAlertPresenter presenter;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: presenter,
    builder: (context, line, _) {
      if (line == null) return const SizedBox.shrink();
      final ink = line.hostile
          ? const Color(0xffffbc96)
          : const Color(0xffe7c4f5);
      return IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 9),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 530),
            child: Semantics(
              liveRegion: true,
              container: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xef211923),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ink.withValues(alpha: .55)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        line.speaker,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: ink),
                      ),
                      Text(
                        line.text,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: const Color(0xfffff2df)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
