import 'package:flutter/material.dart';

import '../game/oculum_lite_run.dart';
import 'oculum_lite_merchant_greeting.dart';
import 'oculum_rl_merchant.dart';

Future<void> showLiteRestHub(
  BuildContext context, {
  required LiteRun? Function() world,
  required ValueChanged<String> playVoice,
  required ValueChanged<LiteRestItem> buy,
  required ValueChanged<LiteRestItem> remember,
  required VoidCallback exchange,
  LiteCoopFighter? Function()? fighter,
  Listenable? refresh,
}) async {
  var station = LiteRestStation.tavern;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, redraw) {
        Widget panel() {
          final run = world();
          if (run == null || !run.restHub) {
            return const Text('La sala è chiusa.');
          }
          final player = fighter?.call();
          final supplies = player?.supply ?? run.supply;
          final balance = player?.obser ?? run.obser;
          final stock = station == LiteRestStation.seer
              ? supplies.receipts
              : LiteRestItem.values.where((item) => item.station == station);
          final shopkeeper = switch (station) {
            LiteRestStation.tavern => LiteShopkeeper.taverniera,
            LiteRestStation.forge => LiteShopkeeper.fabbro,
            LiteRestStation.merchant =>
              run.hubGoblin ? LiteShopkeeper.goblin : LiteShopkeeper.armaiola,
            LiteRestStation.seer => LiteShopkeeper.veggente,
          };
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$balance Obser',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final booth in LiteRestStation.values)
                    ChoiceChip(
                      label: Text(booth.label),
                      selected: station == booth,
                      onSelected: (_) => redraw(() => station = booth),
                    ),
                ],
              ),
              if (station == LiteRestStation.merchant)
                OculumRlMerchant(goblin: run.hubGoblin),
              LiteMerchantGreeting(
                key: ValueKey(shopkeeper),
                shopkeeper: shopkeeper,
                playVoice: playVoice,
              ),
              if (station == LiteRestStation.merchant) ...[
                if (supplies.lunarPieces > 0)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Simbolo della Luna di Vaitern'),
                    subtitle: Text(
                      '${supplies.lunarPieces} frammenti · 60 Obser ciascuno',
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () => redraw(exchange),
                      child: const Text('Scambia'),
                    ),
                  ),
              ],
              if (station == LiteRestStation.seer)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(switch (supplies.promised) {
                    final LiteRestMemory memory =>
                      'Custodito per la prossima run: ${memory.item.label}',
                    null =>
                      'Scegli un acquisto di questa visita da portare nella prossima run. Costo: ${LiteRestHub.memoryPrice} Obser.',
                  }),
                ),
              for (final item in stock)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(item.effect),
                            if (item.evolution)
                              Text('Rango ${supplies.rank(item)}/3'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      station == LiteRestStation.seer
                          ? FilledButton.tonal(
                              onPressed:
                                  supplies.promised != null ||
                                      balance < LiteRestHub.memoryPrice
                                  ? null
                                  : () => redraw(() => remember(item)),
                              child: const Text('Custodisci'),
                            )
                          : FilledButton.tonal(
                              onPressed:
                                  run.canBuyRestItem(item, fighter: player)
                                  ? () => redraw(() => buy(item))
                                  : null,
                              child: Text(
                                '${run.restPrice(item, fighter: player)} Obser',
                              ),
                            ),
                    ],
                  ),
                ),
            ],
          );
        }

        return AlertDialog(
          title: const Text('Sala di ristoro'),
          scrollable: true,
          content: SizedBox(
            width: 510,
            child: refresh == null
                ? panel()
                : ListenableBuilder(
                    listenable: refresh,
                    builder: (_, _) => panel(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Torna nella sala'),
            ),
          ],
        );
      },
    ),
  );
}
