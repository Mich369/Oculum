import 'package:flutter/material.dart';

import '../game/oculum_lite_run.dart';

Future<LiteReysercthMod?> showLiteReysercth(BuildContext context) =>
    showDialog<LiteReysercthMod>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Officina Reysercth'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '«Posso irrobustire la tua armatura e dare più forza ai tuoi colpi.»',
              ),
              const SizedBox(height: 10),
              for (final choice in LiteReysercthMod.values)
                ListTile(
                  title: Text(choice.label),
                  subtitle: Text(
                    choice == LiteReysercthMod.propulsore
                        ? '+8% Vita massima e Danni arma. I colpi respingono fino a 3 m, fermandosi contro i ripari.'
                        : '+8% Vita massima e Danni arma.',
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => Navigator.pop(context, choice),
                ),
              const Text('Un impianto a combattente, valido per tutta la run.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Più tardi'),
          ),
        ],
      ),
    );
