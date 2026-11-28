import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../game/oculum_lite_run.dart';
import 'oculum_lite_grimoire_panel.dart';

const liteScrollKeys = ['Q', '1', '2', '3'];

bool liteShowTouchControls(double width, {required bool cooperative}) =>
    width < (cooperative ? 720 : 680) ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

Map<int, LiteScroll> liteLegacyScrollBindings(
  LiteRun run,
  LiteCoopFighter? fighter,
) {
  final hero = fighter?.hero ?? run.hero;
  final first = hero == LiteHero.reGoblin || hero == LiteHero.slimeBlu ? 1 : 0;
  if (fighter == null) {
    return {
      for (var i = first; i < liteScrollKeys.length; i++)
        if (run.scrolls[run.equippedScrolls[i].index] > 0)
          i: run.equippedScrolls[i],
    };
  }
  final ready = LiteScroll.values
      .where((scroll) => (fighter.supply.scrolls[scroll] ?? 0) > 0)
      .take(liteScrollKeys.length - first)
      .toList();
  return {for (var i = 0; i < ready.length; i++) i + first: ready[i]};
}

class OculumLiteCommandGuide extends StatelessWidget {
  const OculumLiteCommandGuide({
    super.key,
    required this.run,
    required this.cooperative,
    this.fighter,
  });

  final LiteRun run;
  final bool cooperative;
  final LiteCoopFighter? fighter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = fighter;
    final hero = player?.hero ?? run.hero;
    final configured = run.grimoireConfigured(player);
    final slots = run.grimoireSlots(player);
    final legacy = configured
        ? const <int, LiteScroll>{}
        : liteLegacyScrollBindings(run, player);
    final shortOpen = (player?.hero ?? run.hero).openName;
    final desktop = <(String, String)>[
      ('WASD / Frecce', 'Muoviti'),
      ('Ctrl', 'Cammina'),
      (
        'Clic sinistro',
        configured ? liteGrimoireActionName(slots[0], hero) : 'Attacca',
      ),
      (
        'Clic destro',
        configured ? liteGrimoireActionName(slots[1], hero) : hero.talentName,
      ),
      ('Shift', 'Scatta'),
      ('F', 'Tieni per bloccare'),
      ('Spazio', shortOpen),
      ('R', 'Interagisci o ricarica'),
      if (cooperative) ('Tieni R', 'Soccorri un alleato'),
      if (cooperative && run.banditRopes(player) > 0)
        ('Premi R', 'Sciogli le corde'),
      if (!cooperative) ('4 / Rotellina', 'Cambia arma'),
      if (!cooperative) ('Esc', 'Pausa e impostazioni'),
      ('V', hero.talentName),
      if (hero == LiteHero.assassino) ('C', 'Scatola'),
      if (hero == LiteHero.scostubandito) ('B', 'Bomba'),
      if (hero == LiteHero.lusierTre) ('B', 'Scorta solare'),
      if (hero == LiteHero.scostubandito)
        ('G', 'Fucile schivata')
      else if (run.hasWeaponArt(player))
        ('G', run.weaponArtLabel(player)),
      if (run.activeArt(player) case final art?) ('E', art.label),
      if (run.extraArt(player) case final art?) ('Z', art.label),
      if (configured) ...[
        for (var slot = 2; slot < slots.length; slot++)
          if (slots[slot] case final action?)
            (liteGrimoireBindings[slot], liteGrimoireActionName(action, hero)),
      ] else ...[
        if (hero == LiteHero.reGoblin) ('Q', 'Richiamo reale'),
        if (hero == LiteHero.slimeBlu) ('Q', 'Scia invisibile'),
        for (final entry in legacy.entries)
          (liteScrollKeys[entry.key], entry.value.label),
      ],
    ];
    const touch = <(String, String)>[
      ('Frecce a schermo', 'Muoviti'),
      ('Tocca l’arena', 'Mira e attacca'),
      ('Tieni Blocca', 'Difenditi'),
    ];
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, limits) {
            final compact = liteShowTouchControls(
              limits.maxWidth,
              cooperative: cooperative,
            );
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 3,
                children: [
                  for (final (key, action) in compact ? touch : desktop)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: key,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          TextSpan(text: ' · $action'),
                        ],
                      ),
                      style: theme.textTheme.labelMedium,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
