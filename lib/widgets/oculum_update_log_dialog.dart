import 'package:flutter/material.dart';
import '../services/oculum_update_log.dart';

Future<void> oculumShowVersionLogDialog(
  BuildContext context,
  String markdown,
  String version,
) => showDialog<void>(
  context: context,
  barrierDismissible: true,
  builder: (dialog) => AlertDialog(
    key: const ValueKey('oculum_version_log_dialog'),
    insetPadding: const EdgeInsets.all(16),
    title: Row(
      children: [
        const Expanded(child: Text('Novità di Oculum')),
        IconButton(
          tooltip: 'Chiudi log',
          onPressed: () => Navigator.pop(dialog),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
    content: SizedBox(
      width: 760,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(dialog).height * .68,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Versione ${version.length > 8 ? version.substring(0, 8) : version} · log completo dalla build b917217',
                style: Theme.of(dialog).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),
              SelectableText(
                oculumReadableUpdateLog(markdown),
                style: const TextStyle(height: 1.4),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialog),
        child: const Text('Chiudi'),
      ),
    ],
  ),
);
