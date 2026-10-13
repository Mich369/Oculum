import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'oculum_goth_ornaments.dart';
import 'oculum_theme_asset_packs.dart';
import 'oculum_theme_presentation.dart';

OculumThemeAssetPack oculumResolveThemeArt(
  OculumGothOrnaments spec,
  OculumThemePresentation presentation,
) =>
    oculumThemeAssetPacks[presentation.artPackId] ??
    oculumThemeAssetPacks[spec.themeId] ??
    oculumThemeAssetPacks[switch (spec.family) {
      OculumGothFamily.botanical => 'vervain_gothic',
      OculumGothFamily.crystal => 'frost_chapel',
      OculumGothFamily.forged => 'bolted_black_iron',
      OculumGothFamily.astral => 'lunar_eclipse',
      OculumGothFamily.tide => 'abyssal_tide',
      OculumGothFamily.ember => 'ember_rite',
      _ => 'classic_reliquary',
    }]!;

class OculumThemePanelArtwork extends StatelessWidget {
  const OculumThemePanelArtwork({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final spec = Theme.of(context).extension<OculumGothOrnaments>();
    if (spec == null || spec.themeId.isEmpty) return child;
    return ValueListenableBuilder<OculumThemePresentation>(
      valueListenable: oculumThemePresentation,
      child: child,
      builder: (context, presentation, child) {
        final pack = oculumResolveThemeArt(spec, presentation);
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: 4,
              bottom: 4,
              width: 48,
              height: 48,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: RepaintBoundary(
                    child: Opacity(
                      opacity: presentation.relicOpacity * .025,
                      child: Image.asset(
                        pack.relic,
                        cacheWidth:
                            (48 * MediaQuery.devicePixelRatioOf(context))
                                .round()
                                .clamp(128, 384),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            child!,
          ],
        );
      },
    );
  }
}

/// Art and its animation are separate from sheet values and interactive controls.
class OculumThemeRelicBanner extends StatefulWidget {
  const OculumThemeRelicBanner({super.key, this.dense = false});
  final bool dense;
  @override
  State<OculumThemeRelicBanner> createState() => _OculumThemeRelicBannerState();
}

class _OculumThemeRelicBannerState extends State<OculumThemeRelicBanner>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );
  bool foreground = true;
  bool inViewport = true;
  ScrollableState? scrollable;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    oculumThemePresentation.addListener(syncMotion);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context);
    if (scrollable != next) {
      scrollable?.position.removeListener(syncVisibility);
      scrollable = next;
      scrollable?.position.addListener(syncVisibility);
    }
    syncMotion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) syncVisibility();
    });
  }

  void syncVisibility() {
    if (!mounted) return;
    final box = context.findRenderObject();
    final viewport = scrollable?.context.findRenderObject();
    if (box is! RenderBox ||
        viewport is! RenderBox ||
        !box.hasSize ||
        !viewport.hasSize) {
      return;
    }
    final visible = (box.localToGlobal(Offset.zero) & box.size).overlaps(
      viewport.localToGlobal(Offset.zero) & viewport.size,
    );
    if (visible != inViewport) {
      inViewport = visible;
      syncMotion();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    syncMotion();
  }

  void syncMotion() {
    if (!mounted) return;
    final spec = Theme.of(context).extension<OculumGothOrnaments>();
    final enabled =
        foreground &&
        inViewport &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context) &&
        spec?.motion == true &&
        spec?.themeId != 'classic_low_detail' &&
        oculumThemePresentation.value.motion != OculumThemeMotion.disabled;
    if (enabled && !clock.isAnimating) {
      clock.repeat();
    }
    if (!enabled && clock.isAnimating) {
      clock.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    oculumThemePresentation.removeListener(syncMotion);
    scrollable?.position.removeListener(syncVisibility);
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = Theme.of(context).extension<OculumGothOrnaments>();
    if (spec == null || spec.themeId.isEmpty) return const SizedBox.shrink();
    final defaultPack =
        oculumThemeAssetPacks[spec.themeId] ??
        oculumThemeAssetPacks[switch (spec.family) {
          OculumGothFamily.botanical => 'vervain_gothic',
          OculumGothFamily.crystal => 'frost_chapel',
          OculumGothFamily.forged => 'bolted_black_iron',
          OculumGothFamily.astral => 'lunar_eclipse',
          OculumGothFamily.tide => 'abyssal_tide',
          OculumGothFamily.ember => 'ember_rite',
          _ => 'classic_reliquary',
        }]!;
    return ValueListenableBuilder<OculumThemePresentation>(
      valueListenable: oculumThemePresentation,
      builder: (context, presentation, _) {
        final pack =
            oculumThemeAssetPacks[presentation.artPackId] ?? defaultPack;
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            final imageSize =
                (widget.dense
                    ? 46.0
                    : compact
                    ? 84.0
                    : 116.0) *
                presentation.relicScale;
            final decodeWidth =
                (imageSize * MediaQuery.devicePixelRatioOf(context))
                    .round()
                    .clamp(128, 768);
            final artwork = Image.asset(
              pack.relic,
              key: ValueKey('theme-relic-${pack.id}'),
              cacheWidth: decodeWidth,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            );
            return IgnorePointer(
              child: Padding(
                padding: widget.dense
                    ? const EdgeInsets.fromLTRB(8, 6, 8, 6)
                    : const EdgeInsets.symmetric(vertical: 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: spec.accent.withValues(alpha: .3),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: widget.dense ? 4 : 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pack.name,
                                maxLines: widget.dense ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: widget.dense
                                    ? Theme.of(context).textTheme.labelLarge
                                    : Theme.of(context).textTheme.titleMedium,
                              ),
                              if (!widget.dense) const SizedBox(height: 4),
                              if (!widget.dense)
                                Text(
                                  pack.motif,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: imageSize,
                          height: widget.dense ? imageSize : imageSize + 8,
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              Positioned(
                                top: 4,
                                bottom: 4,
                                left: 4,
                                right: 4,
                                child: RepaintBoundary(
                                  child: AnimatedBuilder(
                                    animation: clock,
                                    child: artwork,
                                    builder: (context, child) {
                                      // Three quiet seconds of movement, followed by a pause.
                                      final phase =
                                          clock.isAnimating &&
                                              clock.value < 1 / 3
                                          ? math.sin(clock.value * 3 * math.pi)
                                          : 0.0;
                                      final full =
                                          presentation.motion ==
                                          OculumThemeMotion.complete;
                                      final motion = pack.motion;
                                      final sways =
                                          motion.contains('oscill') ||
                                          motion.contains('inclina') ||
                                          motion.contains('vel') ||
                                          motion.contains('nastro');
                                      final orbits =
                                          motion.contains('orbit') ||
                                          motion.contains('rotazione');
                                      final rises =
                                          motion.contains('ascendente') ||
                                          motion.contains('spore') ||
                                          motion.contains('polvere');
                                      return Opacity(
                                        opacity:
                                            (presentation.relicOpacity *
                                                    (1 - phase * .06))
                                                .clamp(0, 1),
                                        child: Transform.translate(
                                          offset: Offset(
                                            full && sways ? phase * 1.5 : 0,
                                            full && rises ? -phase * 3 : 0,
                                          ),
                                          child: Transform.rotate(
                                            angle: full && (sways || orbits)
                                                ? phase * .02
                                                : 0,
                                            child: Transform.scale(
                                              scale: full
                                                  ? 1 + phase * .015
                                                  : 1,
                                              child: child,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
