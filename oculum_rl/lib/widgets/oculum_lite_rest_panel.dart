import 'package:flutter/material.dart';

import '../game/oculum_lite_run.dart';
import 'oculum_lite_merchant_greeting.dart';
import 'oculum_lite_arena.dart';
import 'oculum_rl_merchant.dart';

Future<void> showLiteRestHub(
  BuildContext context, {
  required LiteRun? Function() world,
  required ValueChanged<String> playVoice,
  required ValueChanged<LiteRestItem> buy,
  required ValueChanged<LiteRestItem> equip,
  required ValueChanged<LiteRestItem> remember,
  required VoidCallback exchange,
  LiteCoopFighter? Function()? fighter,
  Listenable? refresh,
}) async {
  final start = world();
  var station = start?.artDealerOpen == true
      ? LiteRestStation.art
      : LiteRestStation.tavern;
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
          final fixedArt = LiteLearnedArt.fixedFor(player?.hero ?? run.hero);
          final level = player?.level ?? run.level;
          final stock = station == LiteRestStation.seer
              ? supplies.receipts
              : LiteRestItem.values.where((item) => item.station == station);
          final shopkeeper = switch (station) {
            LiteRestStation.tavern => LiteShopkeeper.taverniera,
            LiteRestStation.forge => LiteShopkeeper.fabbro,
            LiteRestStation.merchant =>
              run.hubGoblin ? LiteShopkeeper.goblin : LiteShopkeeper.armaiola,
            LiteRestStation.seer ||
            LiteRestStation.art => LiteShopkeeper.veggente,
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
                    if (booth != LiteRestStation.art || run.artDealerOpen)
                      ChoiceChip(
                        label: Text(
                          booth == LiteRestStation.art && run.devilArtTutor
                              ? 'Istruttore di Art'
                              : booth.label,
                        ),
                        selected: station == booth,
                        onSelected: (_) => redraw(() => station = booth),
                      ),
                ],
              ),
              if (station == LiteRestStation.merchant)
                OculumRlMerchant(goblin: run.hubGoblin),
              if (station != LiteRestStation.art)
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
              if (station == LiteRestStation.art)
                _ArtTutor(
                  devil: run.devilArtTutor,
                  discount: run.hasTutorDiscount(player),
                  hasBook: supplies.hasGrimoire,
                  fixed: fixedArt,
                  prepared: supplies.art,
                ),
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
                      if (item == LiteRestItem.artPlasma ||
                          item == LiteRestItem.artCorruzione)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Image(
                            image: item == LiteRestItem.artPlasma
                                ? OculumLiteArena.plasmaScrollArt
                                : OculumLiteArena.redScrollArt,
                            width: 38,
                            height: 38,
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            if (item.art case final art?)
                              _ArtLesson(
                                art: art,
                                level: level,
                                prepared: supplies.art == art,
                              )
                            else
                              Text(item.effect),
                            if (item == LiteRestItem.tempra)
                              Text(
                                '${(player?.weapon ?? run.weapon).label} · Rango ${supplies.forgeRank(player?.weapon ?? run.weapon)}/12',
                              ),
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
                          : item.art != null && supplies.knowsArt(item.art!)
                          ? FilledButton.tonal(
                              onPressed:
                                  supplies.art == item.art ||
                                      (player?.hp ?? run.hp) <= 0
                                  ? null
                                  : () => redraw(() => equip(item)),
                              child: Text(
                                supplies.art == item.art
                                    ? 'Pronta'
                                    : 'Equipaggia',
                              ),
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

class _ArtTutor extends StatelessWidget {
  const _ArtTutor({
    required this.devil,
    required this.discount,
    required this.hasBook,
    required this.fixed,
    required this.prepared,
  });

  final bool devil, discount, hasBook;
  final LiteLearnedArt? fixed, prepared;

  @override
  Widget build(BuildContext context) {
    final title = devil ? 'L’Istruttore di Art' : 'L’Istruttrice di Art';
    final portrait = devil ? 'istruttore-diavolo' : 'istruttrice-arte';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Image.asset(
            'assets/oculum/lite/$portrait.webp',
            width: 85,
            height: 104,
            fit: BoxFit.contain,
            semanticLabel: title,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  devil
                      ? '«Una firma e l’inchiostro è tuo.»'
                      : '«Apri il Grimorio. Ti mostro da dove cominciare.»',
                ),
                if (discount) const Text('Affinità di stirpe · Sconto del 20%'),
                Text(
                  hasBook
                      ? 'Grimorio aperto · Le skill imparate restano nella run.'
                      : 'La prima lezione include il Grimorio (+${LiteRestHub.grimoirePrice} Obser prima dello sconto).',
                ),
                if (fixed != null) Text('E · ${fixed!.label} (innata)'),
                Text(
                  '${fixed == null ? 'E' : 'Z'} · ${prepared?.label ?? 'Skill da preparare'}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtLesson extends StatelessWidget {
  const _ArtLesson({
    required this.art,
    required this.level,
    required this.prepared,
  });

  final LiteLearnedArt art;
  final int level;
  final bool prepared;

  @override
  Widget build(BuildContext context) {
    final rank = art.rankAt(level);
    final recovery = art.cooldown.toString().replaceAll('.', ',');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${art.family} · ${art.cost.toInt()} Oculum · $recovery s'),
        Text('Forma $rank/${art.maxRank} · ${art.formEffect(rank)}'),
        if (rank < art.maxRank)
          Text(
            'Al livello ${art.levelForRank(rank + 1)} · ${art.formEffect(rank + 1)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (prepared) const Text('Equipaggiata'),
      ],
    );
  }
}
