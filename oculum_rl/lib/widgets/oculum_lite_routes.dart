import 'package:flutter/material.dart';

import '../game/oculum_lite_run.dart';

Future<LiteBiome?> chooseOculumLiteRoute(BuildContext context, LiteRun run) {
  final routes = [
    for (final biome in run.routeBiomes) ?run.previewNextFloor(biome),
  ];
  if (routes.isEmpty) return Future.value();
  final solo = run.playerCount == 1;
  final pendingReward = run.powerOffers.isNotEmpty;
  return showDialog<LiteBiome>(
    context: context,
    builder: (dialog) => AlertDialog(
      scrollable: true,
      title: Text('Portale · Piano ${routes.first.floor}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (LiteRun.arenaSpeedBonusAt(routes.first.floor) > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Ritmo dell’arena · +${LiteRun.arenaSpeedBonusAt(routes.first.floor)}%',
                ),
              ),
            if (LiteRun.enemyLifeBonusAt(routes.first.floor) > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Nemici · +${LiteRun.enemyLifeBonusAt(routes.first.floor)}% Vita, '
                  '+${LiteRun.enemyDamageBonusAt(routes.first.floor)}% Danni',
                  style: TextStyle(color: Theme.of(dialog).colorScheme.error),
                ),
              ),
            if (pendingReward)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Puoi ancora scegliere un potenziamento di questo piano. '
                  'Se attraversi il portale, l’offerta scade.',
                  style: TextStyle(color: Theme.of(dialog).colorScheme.primary),
                ),
              ),
            for (final route in routes)
              _RouteCard(
                route: route,
                solo: solo,
                rank: route.featuredPower == null
                    ? null
                    : run.powerRank(route.featuredPower!) + 1,
                onTap: () => Navigator.pop(dialog, route.biome),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Resta qui'),
        ),
      ],
    ),
  );
}

Future<LitePowerUp?> chooseOculumLitePower(BuildContext context, LiteRun run) =>
    showDialog<LitePowerUp>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(
          run.playerCount == 1
              ? 'Scegli un potenziamento'
              : 'Potenziamento per la squadra',
        ),
        children: [
          for (final power in run.powerOffers)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, power),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  run.powerRank(power) == 2
                      ? Icons.auto_awesome
                      : Icons.diamond_outlined,
                ),
                title: Text(
                  '${power.label} · Grado ${run.powerRank(power) + 1}/3',
                ),
                subtitle: Text(power.descriptionAt(run.powerRank(power) + 1)),
              ),
            ),
        ],
      ),
    );

Future<LitePowerUp?> showOculumLiteWell(
  BuildContext context,
  LiteRun run, {
  required bool canChoose,
}) {
  final offers = run.powerWellOffers;
  final ready = canChoose && run.canClaimPowerWell;
  return showDialog<LitePowerUp>(
    context: context,
    builder: (dialog) => SimpleDialog(
      title: const Text('Pozzo delle Iride'),
      children: [
        if (offers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Il pozzo è esaurito.'),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: Text(
              !run.stageClear
                  ? 'Conquista la sala per attingere a una delle offerte.'
                  : !canChoose
                  ? 'Il Master sceglie un potenziamento per la squadra.'
                  : 'Conferma una delle offerte prima di proseguire.',
            ),
          ),
          for (final power in offers)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Icon(Icons.diamond_outlined),
              title: Text(
                '${power.label} · Grado ${run.powerRank(power) + 1}/3',
              ),
              subtitle: Text(power.descriptionAt(run.powerRank(power) + 1)),
              trailing: ready
                  ? TextButton(
                      onPressed: () => Navigator.pop(dialog, power),
                      child: const Text('Scegli'),
                    )
                  : null,
            ),
        ],
      ],
    ),
  );
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.solo,
    required this.rank,
    required this.onTap,
  });

  final LiteFloorPreview route;
  final bool solo;
  final int? rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layoutName = route.layout.label;
    final special = route.special;
    final bossLoot = special == null ? null : LiteRun.bossWeapon(special);
    final recruit = special == null ? null : LiteCompanion.unlockedBy(special);
    final challenge = special == null
        ? null
        : LiteRun.challengeBonus(route.floor, special);
    final power = route.featuredPower;
    final terrain = switch (route.biome) {
      LiteBiome.campo => Icons.flag_outlined,
      LiteBiome.foresta => Icons.park_outlined,
      LiteBiome.dungeon => Icons.architecture,
      LiteBiome.postea => Icons.precision_manufacturing_outlined,
      LiteBiome.deserto => Icons.landscape_outlined,
      LiteBiome.orea => Icons.bubble_chart_outlined,
    };
    final encounter = switch (route.encounter) {
      LiteEncounter.ordinary => 'Scontro ordinario',
      LiteEncounter.elite => 'Élite · ${special!.label}',
      LiteEncounter.boss => 'Boss · ${special!.label}',
      LiteEncounter.finalBoss => 'Boss finale · ${special!.label}',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Icon(terrain, color: theme.colorScheme.primary),
        trailing: const Icon(Icons.chevron_right),
        title: Text(route.biome.label, style: theme.textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (layoutName.isNotEmpty) Text(layoutName),
              Text(
                encounter,
                style: route.special == null
                    ? null
                    : TextStyle(color: theme.colorScheme.primary),
              ),
              if (challenge != null && challenge.life > 0)
                Text(
                  'Rinforzo speciale · +${challenge.life}% Vita, '
                  '+${challenge.damage}% Danni',
                ),
              if (bossLoot != null) Text('Arma del boss · ${bossLoot.label}'),
              if (recruit != null)
                Text('Compagno reclutabile · ${recruit.label}'),
              if (route.openingEnemies > 0)
                Text(
                  'Prima ondata · ${route.openingEnemies} nemici · '
                  '${route.enemyKinds.map((kind) => kind.label).join(', ')}',
                ),
              if (route.biome == LiteBiome.postea &&
                  route.encounter != LiteEncounter.finalBoss)
                const Text('Possibile bottino · Pergamena Raggio al plasma'),
              if (route.trial case final trial?) ...[
                Text(
                  trial.label,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                Text(
                  '${trial.risk} · Premio +${trial.obser} Obser per combattente',
                ),
              ],
              if (power != null && rank != null)
                Text('Potenziamento offerto · ${power.label} · Grado $rank'),
              if (solo && route.rest)
                const Text('Dopo la vittoria · Ristoro 50% Vita e 25% Oculum'),
            ],
          ),
        ),
      ),
    );
  }
}

class OculumLiteTrialStatus extends StatelessWidget {
  const OculumLiteTrialStatus({super.key, required this.run});
  final LiteRun run;

  @override
  Widget build(BuildContext context) {
    final trial = run.arenaTrial;
    if (trial == null || run.stageClear || run.finished)
      return const SizedBox.shrink();
    final seconds = run.trialSecondsLeft;
    return Text(switch (seconds) {
      null => '${trial.label} · ${trial.risk}',
      0 => '${trial.label} · Premio extra scaduto',
      final seconds => '${trial.label} · $seconds s',
    });
  }
}

class OculumLiteCompanionStatus extends StatelessWidget {
  const OculumLiteCompanionStatus({super.key, required this.run});

  final LiteRun run;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 3,
      children: [
        for (final ally in run.clones)
          if (ally.companion case final companion?)
            Tooltip(
              message: ally.down
                  ? 'A terra · Tieni R a contatto per soccorrerlo'
                  : ally.expiresAfter == null &&
                        companion.questHero != null &&
                        !run.achievements.contains(
                          LiteRun.heroUnlockKey(companion.questHero!),
                        )
                  ? companion.questHero!.unlockHint!
                  : '${ally.hp.ceil()}/${ally.maxHp.ceil()} Vita',
              child: Text(
                '${companion.label}${ally.down ? ' · A terra' : ''}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
      ],
    );
  }
}

Future<LiteRealm?> chooseLiteSecondAct(BuildContext context) =>
    showDialog<LiteRealm>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atto II · Il crocevia'),
        scrollable: true,
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final realm in LiteRealm.values)
                ListTile(
                  leading: Icon(switch (realm) {
                    LiteRealm.inferno => Icons.local_fire_department_outlined,
                    LiteRealm.caramella => Icons.grain,
                    LiteRealm.postea => Icons.precision_manufacturing_outlined,
                  }),
                  title: Text(realm.label),
                  subtitle: Text(realm.description),
                  onTap: () => Navigator.pop(context, realm),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Resta al ristoro'),
          ),
        ],
      ),
    );

Future<void> showLiteActRelics(
  BuildContext context,
  LiteRun run, {
  required ValueChanged<LiteActRelic> take,
  required void Function(int, int) move,
}) => showDialog<void>(
  context: context,
  builder: (context) => StatefulBuilder(
    builder: (context, redraw) => AlertDialog(
      title: const Text('Reliquie legate'),
      scrollable: true,
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (run.actRelics.isEmpty && !run.canClaimActRelic)
              const Text(
                'Conquista una sala dell’Atto II per trovare una reliquia.',
              ),
            for (final (index, relic) in run.actRelics.indexed)
              ListTile(
                title: Text(relic.label),
                subtitle: Text(relic.description),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Sposta a sinistra',
                      onPressed: run.stageClear && index > 0
                          ? () => redraw(() => move(index, -1))
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      tooltip: 'Sposta a destra',
                      onPressed:
                          run.stageClear && index + 1 < run.actRelics.length
                          ? () => redraw(() => move(index, 1))
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            if (run.canClaimActRelic)
              for (final relic in LiteActRelic.values)
                ListTile(
                  title: Text(relic.label),
                  subtitle: Text(relic.description),
                  trailing: FilledButton.tonal(
                    onPressed: () => redraw(() => take(relic)),
                    child: const Text('Prendi'),
                  ),
                ),
          ],
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
