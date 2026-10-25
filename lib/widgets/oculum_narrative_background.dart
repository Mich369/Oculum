import 'package:flutter/material.dart';
import 'oculum_goth_ornaments.dart';
import 'oculum_monster_theme.dart';
import 'oculum_theme_presentation.dart';
import 'oculum_theme_relic.dart';
import 'oculum_narrative_atmosphere.dart';

/// The entire decorative layer is excluded from input and accessibility.
/// Controls remain ordinary Flutter widgets above it on readable surfaces.
class OculumNarrativeBackground extends StatelessWidget {
  const OculumNarrativeBackground({super.key, required this.sheetId});
  final String sheetId;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      oculumThemePresentation,
      oculumSheetRelicSelections,
      oculumSheetMonsterThemes,
    ]),
    builder: (context, _) {
      final spec = Theme.of(context).extension<OculumGothOrnaments>();
      if (spec == null) return const SizedBox.shrink();
      final presentation = oculumThemePresentationForSheet(sheetId);
      final monster = oculumMonsterThemeById(presentation.artPackId);
      final pack = oculumResolveThemeArt(spec, presentation);
      final image =
          monster?.illustration ??
          (monster != null
              ? 'assets/oculum/theme_stories/webp/plane_${monster.monster.planeIds.firstOrNull ?? 'mezzano'}.webp'
              : pack.storyScene);
      return IgnorePointer(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  image,
                  key: ValueKey(
                    'narrative-background-${monster?.id ?? pack.id}',
                  ),
                  fit: BoxFit.cover,
                  alignment: monster?.illustration != null
                      ? Alignment.centerRight
                      : pack.id == 'plane_diabolico'
                      ? const Alignment(.3, 0)
                      : Alignment.center,
                  cacheWidth: MediaQuery.sizeOf(context).width < 600
                      ? 960
                      : 1920,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x99070a10),
                        Color(0x87070a10),
                        Color(0x66070a10),
                      ],
                    ),
                  ),
                ),
                if (presentation.variant == OculumThemeVariant.alive &&
                    presentation.motion != OculumThemeMotion.disabled)
                  OculumNarrativeAtmosphere(
                    themeId: monster?.monster.id ?? pack.id,
                    accent: monster?.accent ?? spec.accent,
                    presentation: presentation,
                  ),
                if (monster != null && monster.illustration == null)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Opacity(
                      opacity: .4,
                      child: SizedBox(
                        width: 210,
                        height: 250,
                        child: OculumMonsterRelic(theme: monster),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
