import 'package:flutter/material.dart';
import '../pages/oculum_dungeon/monster_book.dart';
import 'oculum_monster_theme.dart';

/// Page artwork is a theme, never a portrait attached to the creature.
/// Contain + clipping keeps the entire illustration inside its own page.
class OculumMonsterBookPage extends StatelessWidget {
  const OculumMonsterBookPage({
    super.key,
    required this.monster,
    required this.purchased,
    required this.child,
  });
  final MonsterBookEntry monster;
  final bool purchased;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!purchased) return child;
    final theme = OculumMonsterTheme(
      monster,
      oculumMonsterColors(monster).first,
    );
    return ClipRRect(
      key: ValueKey('purchased-monster-page-${monster.id}'),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: theme.surface),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        theme.illustration ??
                            'assets/oculum/theme_stories/webp/plane_${monster.planeIds.firstOrNull ?? 'mezzano'}.webp',
                        key: ValueKey('monster-page-art-${monster.id}'),
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(color: Color(0xCF090B11)),
                      ),
                      if (theme.illustration == null)
                        Center(
                          child: Opacity(
                            opacity: .12,
                            child: SizedBox(
                              width: 220,
                              height: 260,
                              child: OculumMonsterRelic(theme: theme),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }
}
