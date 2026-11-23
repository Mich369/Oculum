import 'package:flutter/material.dart';
import 'oculum_goth_ornaments.dart';
import 'oculum_monster_theme.dart';
import 'oculum_theme_presentation.dart';
import 'oculum_theme_relic.dart';
import 'oculum_narrative_atmosphere.dart';
import 'oculum_focal_background.dart';

/// The entire decorative layer is excluded from input and accessibility.
/// Controls remain ordinary Flutter widgets above it on readable surfaces.
class OculumNarrativeBackground extends StatelessWidget {
  const OculumNarrativeBackground({
    super.key,
    required this.sheetId,
    this.senkaMaskActive = false,
  });
  final String sheetId;
  final bool senkaMaskActive;
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
      final viewport = MediaQuery.sizeOf(context);
      final portrait = viewport.height > viewport.width;
      final mobile = viewport.width < 600 || portrait;
      final storyImage =
          (senkaMaskActive ? pack.maskedStorySceneAsset : null) ??
          (mobile
              ? pack.storySceneMobileAsset ?? pack.storyScene
              : pack.storyScene);
      final image =
          (mobile
              ? monster?.illustrationMobile ?? monster?.illustration
              : monster?.illustration) ??
          (monster != null
              ? 'assets/oculum/theme_stories/webp/plane_${monster.monster.planeIds.firstOrNull ?? 'mezzano'}.webp'
              : storyImage);
      return IgnorePointer(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (portrait)
                  OculumFocalBackground(
                    image: ResizeImage.resizeIfNeeded(
                      viewport.width < 600 ? 960 : 1920,
                      null,
                      AssetImage(oculumMonsterArtworkAsset(image)!),
                    ),
                    imageKey: ValueKey(
                      'narrative-background-${monster?.id ?? pack.id}',
                    ),
                    focus: oculumNarrativeSubjectFocus(
                      monster?.illustration != null
                          ? monster?.monster.id
                          : null,
                      dedicatedMobile:
                          monster?.illustrationMobile != null ||
                          (monster == null &&
                              pack.storySceneMobileAsset != null),
                    ),
                  )
                else
                  Image.asset(
                    oculumMonsterArtworkAsset(image)!,
                    key: ValueKey(
                      'narrative-background-${monster?.id ?? pack.id}',
                    ),
                    // Page backgrounds cover the whole viewport, including the
                    // sheet's local navigation. Preview art keeps its own framing.
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
