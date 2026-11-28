import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/oculum_lite_run.dart';

const liteGrimoireBindings = [
  'Click sinistro',
  'Click destro',
  'Q',
  '1',
  '2',
  '3',
];

int liteGrimoireKeyboardSlot(LogicalKeyboardKey key) => switch (key) {
  LogicalKeyboardKey.keyQ => 2,
  LogicalKeyboardKey.digit1 => 3,
  LogicalKeyboardKey.digit2 => 4,
  LogicalKeyboardKey.digit3 => 5,
  _ => -1,
};

String liteGrimoireActionName(LiteGrimoireAction? action, LiteHero hero) =>
    switch (action?.kind) {
      LiteGrimoireActionKind.weapon => 'Attacco con l’arma',
      LiteGrimoireActionKind.talent => hero.talentName,
      LiteGrimoireActionKind.scroll => 'Pergamena pronta',
      LiteGrimoireActionKind.art => action!.art!.label,
      null => 'Vuoto',
    };

Future<void> showOculumLiteGrimoire(
  BuildContext context, {
  required LiteRun run,
  LiteCoopFighter? fighter,
  required void Function(int slot, LiteGrimoireAction? action) onAssign,
}) {
  final hero = fighter?.hero ?? run.hero;
  final kit = fighter?.supply ?? run.supply;
  final slots = run.grimoireSlots(fighter).toList();
  final choices = <LiteGrimoireAction?>[
    null,
    const LiteGrimoireAction.weapon(),
    const LiteGrimoireAction.talent(),
    const LiteGrimoireAction.scroll(),
    for (final art in LiteLearnedArt.values)
      if (run.grimoireArts(fighter).contains(art)) LiteGrimoireAction.art(art),
  ];
  return showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocalState) => AlertDialog(
        title: const Text('Grimorio'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Assegna una sola azione a ogni tasto. La Pittrice insegna nuove Art.',
                ),
                const SizedBox(height: 12),
                for (var index = 0; index < slots.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: slots[index]?.key ?? '-',
                      decoration: InputDecoration(
                        labelText: liteGrimoireBindings[index],
                        helperText: switch (slots[index]?.art) {
                          final art? => art.formEffect(
                            kit.artRank(art, fighter?.level ?? run.level),
                          ),
                          null => null,
                        },
                        helperMaxLines: 3,
                      ),
                      items: [
                        for (final action in choices)
                          DropdownMenuItem(
                            value: action?.key ?? '-',
                            child: Text(
                              liteGrimoireActionName(action, hero) +
                                  (switch (action?.art) {
                                    final art? =>
                                      ' · ' +
                                          art.cost.toInt().toString() +
                                          ' Oculum',
                                    null => '',
                                  }),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (key) {
                        if (key == null) return;
                        final action = LiteGrimoireAction.tryRead(key);
                        onAssign(index, action);
                        setLocalState(() => slots[index] = action);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    ),
  );
}
