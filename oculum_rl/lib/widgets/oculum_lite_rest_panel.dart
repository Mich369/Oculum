import 'package:flutter/material.dart';

import '../game/oculum_lite_run.dart';
import 'oculum_lite_merchant_greeting.dart';
import 'oculum_lite_arena.dart';
import 'oculum_rl_merchant.dart';

class OculumLiteStarterPetPicker extends StatelessWidget {
  const OculumLiteStarterPetPicker({
    super.key,
    required this.offers,
    required this.selected,
    required this.onChanged,
  });

  final List<LiteCompanion> offers;
  final LiteCompanion? selected;
  final ValueChanged<LiteCompanion?>? onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.pets_outlined),
    title: const Text('Pet iniziale'),
    subtitle: offers.isEmpty
        ? const Text(
            'Incontra e sblocca un pet per portarlo nelle prossime run.',
          )
        : Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 3,
              children: [
                for (final pet in offers)
                  ChoiceChip(
                    label: Text(pet.label),
                    selected: selected == pet,
                    onSelected: onChanged == null
                        ? null
                        : (choice) => onChanged!(choice ? pet : null),
                  ),
              ],
            ),
          ),
  );
}

Future<(int, LiteCompanion)?> showLitePetTrader(
  BuildContext context,
  LiteRun run, [
  LiteCoopFighter? fighter,
]) {
  final owned = run.tradablePets(fighter).toList();
  final offers = run.petTradeOffers(fighter);
  var outgoing = owned.firstOrNull;
  return showDialog<(int, LiteCompanion)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => AlertDialog(
        title: const Text('Bandito dei pet'),
        scrollable: true,
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                owned.isEmpty
                    ? 'Portami un pet vivo e ti farò una proposta.'
                    : offers.isEmpty
                    ? 'Per questo Ristoro abbiamo già scambiato.'
                    : 'Lascia un pet e scegline un altro. Lo scambio vale per questa run.',
              ),
              if (outgoing != null && offers.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  initialValue: outgoing!.id,
                  decoration: const InputDecoration(
                    labelText: 'Pet da scambiare',
                  ),
                  items: [
                    for (final pet in owned)
                      DropdownMenuItem(
                        value: pet.id,
                        child: Text(pet.companion!.label),
                      ),
                  ],
                  onChanged: (id) => update(() {
                    outgoing = owned.firstWhere((pet) => pet.id == id);
                  }),
                ),
                for (final offer in offers)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.pets_outlined),
                    title: Text(offer.label),
                    onTap: () => Navigator.pop(context, (outgoing!.id, offer)),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Esci'),
          ),
        ],
      ),
    ),
  );
}

Future<LiteVampirePact?> showLiteVampirePact(BuildContext context) =>
    showDialog<LiteVampirePact>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Il Patto del Vampiro'),
        scrollable: true,
        content: SizedBox(
          width: 490,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '«Dammi il 35% della tua Vita massima e scegli cosa portare con te fino alla fine della run.»',
              ),
              const SizedBox(height: 10),
              for (final pact in LiteVampirePact.values)
                ListTile(
                  title: Text(pact.label),
                  subtitle: Text(pact.description),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => Navigator.pop(context, pact),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Rifiuta'),
          ),
        ],
      ),
    );

Future<void> showLiteRestHub(
  BuildContext context, {
  required LiteRun? Function() world,
  required ValueChanged<String> playVoice,
  required ValueChanged<LiteRestItem> buy,
  required ValueChanged<LiteWeapon> buySignature,
  required ValueChanged<LiteWeapon> equipWeapon,
  required void Function(LiteWeapon, LiteWeapon) fuseWeapons,
  required VoidCallback splitWeapons,
  required ValueChanged<LiteRestItem> equip,
  required ValueChanged<LiteRestItem> remember,
  required VoidCallback exchange,
  LiteCoopFighter? Function()? fighter,
  Listenable? refresh,
  LiteRestStation? initialStation,
}) async {
  final start = world();
  var station =
      initialStation ??
      (start?.artDealerOpen == true
          ? LiteRestStation.art
          : LiteRestStation.tavern);
  var shadowLessons = false;
  LiteWeapon? selectedPrimary;
  LiteWeapon? selectedSecondary;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, redraw) {
        Widget panel() {
          final run = world();
          final player = fighter?.call();
          if (run == null || !run.canUseRestStation(station, player)) {
            return const Text('Allontanati dallo scontro e torna al banco.');
          }
          final supplies = player?.supply ?? run.supply;
          final balance = player?.obser ?? run.obser;
          final fixedArt = LiteLearnedArt.fixedFor(player?.hero ?? run.hero);
          final equipped = player?.weapon ?? run.weapon;
          final owned = run.forgeInventory(player);
          final pair = run.weaponFusion(player);
          final primary = owned.contains(selectedPrimary)
              ? selectedPrimary!
              : pair?.primary ?? equipped;
          final secondary =
              owned.contains(selectedSecondary) && selectedSecondary != primary
              ? selectedSecondary
              : pair?.primary == primary
              ? pair?.secondary
              : null;
          final level = player?.level ?? run.level;
          final stock = station == LiteRestStation.seer
              ? supplies.receipts
              : LiteRestItem.values.where((item) {
                  if (item.station != station) return false;
                  if (station != LiteRestStation.art) return true;
                  return (item.art?.family == 'Oculum Art Ombra') ==
                      shadowLessons;
                });
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
                  if (run.restHub)
                    for (final booth in run.restStations)
                      ChoiceChip(
                        label: Text(run.restStationName(booth)),
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
              if (station == LiteRestStation.forge &&
                  run.hasWeaponArt(player)) ...[
                const SizedBox(height: 12),
                Text(
                  'Fusione d’armi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (pair != null)
                  Text(
                    'Fusione forgiata · ${pair.primary.label} + ${pair.secondary.label}',
                  ),
                if (owned.length > 1) ...[
                  const Text(
                    'I due attacchi partono insieme. La primaria regola il ritmo e mantiene la tecnica su G.',
                  ),
                  DropdownButtonFormField<LiteWeapon>(
                    key: ValueKey(('primaria', primary)),
                    decoration: const InputDecoration(
                      labelText: 'Arma primaria',
                    ),
                    isExpanded: true,
                    initialValue: primary,
                    items: [
                      for (final weapon in owned)
                        DropdownMenuItem(
                          value: weapon,
                          child: Text(weapon.label),
                        ),
                    ],
                    onChanged: (weapon) => redraw(() {
                      selectedPrimary = weapon;
                      if (selectedSecondary == weapon) selectedSecondary = null;
                    }),
                  ),
                  DropdownButtonFormField<LiteWeapon>(
                    key: ValueKey(('secondaria', primary, secondary)),
                    decoration: const InputDecoration(
                      labelText: 'Arma secondaria',
                    ),
                    isExpanded: true,
                    initialValue: secondary,
                    items: [
                      for (final weapon in owned.where(
                        (weapon) => weapon != primary,
                      ))
                        DropdownMenuItem(
                          value: weapon,
                          child: Text(weapon.label),
                        ),
                    ],
                    onChanged: (weapon) =>
                        redraw(() => selectedSecondary = weapon),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed:
                            secondary != null &&
                                run.canFuse(primary, secondary, player)
                            ? () =>
                                  redraw(() => fuseWeapons(primary, secondary))
                            : null,
                        child: const Text(
                          'Fondi · ${LiteForgeFusion.fusionPrice} Obser',
                        ),
                      ),
                      if (pair != null)
                        TextButton(
                          onPressed: () => redraw(splitWeapons),
                          child: const Text('Separa'),
                        ),
                    ],
                  ),
                ] else
                  const Text('Ti serve una seconda arma.'),
                ExpansionTile(
                  title: const Text('Armi dei personaggi'),
                  children: [
                    for (final weapon in {...run.signatureWeapons, ...owned})
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(weapon.label),
                        subtitle: owned.contains(weapon)
                            ? Text('Tempra ${supplies.forgeRank(weapon)}/12')
                            : null,
                        trailing: owned.contains(weapon)
                            ? TextButton(
                                onPressed: weapon == equipped
                                    ? null
                                    : () => redraw(() => equipWeapon(weapon)),
                                child: Text(
                                  weapon == equipped ? 'In uso' : 'Impugna',
                                ),
                              )
                            : FilledButton.tonal(
                                onPressed: run.canBuySignature(weapon, player)
                                    ? () => redraw(() => buySignature(weapon))
                                    : null,
                                child: Text(
                                  '${run.signaturePrice(weapon)} Obser',
                                ),
                              ),
                      ),
                  ],
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
              if (station == LiteRestStation.art)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ChoiceChip(
                        label: const Text('Altre Art'),
                        selected: !shadowLessons,
                        onSelected: (_) => redraw(() => shadowLessons = false),
                      ),
                      ChoiceChip(
                        avatar: const Icon(
                          Icons.remove_red_eye_outlined,
                          size: 17,
                        ),
                        label: const Text('Occhio d’Ombra'),
                        selected: shadowLessons,
                        onSelected: (_) => redraw(() => shadowLessons = true),
                      ),
                    ],
                  ),
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
                                supplies: supplies,
                                prepared: supplies.art == art,
                              )
                            else
                              Text(item.effect),
                            if (item.meal)
                              const Text(
                                'Compagni ed evocazioni: +20% della loro Vita massima.',
                              ),
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
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FilledButton.tonal(
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
                                ),
                                if (supplies.artTraining(item.art!) < 2)
                                  TextButton(
                                    onPressed:
                                        run.canBuyRestItem(
                                          item,
                                          fighter: player,
                                        )
                                        ? () => redraw(() => buy(item))
                                        : null,
                                    child: Text(
                                      'Allena · ${run.restPrice(item, fighter: player)} Obser',
                                    ),
                                  ),
                              ],
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
          title: Text(
            initialStation == null
                ? 'Sala di ristoro'
                : world()?.restStationName(station) ?? station.label,
          ),
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
    required this.supplies,
    required this.prepared,
  });

  final LiteLearnedArt art;
  final int level;
  final LiteRestLoadout supplies;
  final bool prepared;

  @override
  Widget build(BuildContext context) {
    final train = supplies.artTraining(art);
    final rank = supplies.artRank(art, level);
    final recovery = supplies
        .artRecovery(art)
        .toStringAsFixed(1)
        .replaceAll('.', ',');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${art.family} · ${art.cost.toInt()} Oculum · $recovery s'),
        Text('Forma $rank/${art.maxRank} · ${art.formEffect(rank)}'),
        if (supplies.knowsArt(art))
          Text(
            'Allenamento $train/2 · ogni lezione anticipa una forma e riduce il recupero del 10%.',
          ),
        if (rank < art.maxRank)
          Text(
            'Al livello ${art.levelForRank(rank + 1 - train)} · ${art.formEffect(rank + 1)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (prepared) const Text('Equipaggiata'),
      ],
    );
  }
}
