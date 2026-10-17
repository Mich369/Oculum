import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'oculum_goth_ornaments.dart';
import 'oculum_theme_presentation.dart';
import 'oculum_theme_relic.dart';
import 'oculum_element_ambient_art.dart';
import 'oculum_theme_identity.dart';

enum OculumThemeFrameRole { panel, portrait, statistics }

/// Frames are real transparent assets. The reading and touch layer owns layout;
/// the artwork occupies existing margins and cannot change layout or hit-test.
class OculumThemeSheetFrame extends StatelessWidget {
  const OculumThemeSheetFrame({
    super.key,
    required this.child,
    this.role = OculumThemeFrameRole.panel,
  });
  final Widget child;
  final OculumThemeFrameRole role;

  @override
  Widget build(BuildContext context) {
    final spec = Theme.of(context).extension<OculumGothOrnaments>();
    if (spec == null || spec.themeId.isEmpty || spec.opacity <= 0) return child;
    return ValueListenableBuilder<OculumThemePresentation>(
      valueListenable: oculumThemePresentation,
      child: child,
      builder: (context, presentation, child) {
        final pack = oculumResolveThemeArt(spec, presentation);
        return LayoutBuilder(
          builder: (context, constraints) {
            final mobile = MediaQuery.sizeOf(context).width < 600;
            final compact = role != OculumThemeFrameRole.panel;
            final name = compact
                ? role.name
                : mobile
                ? 'mobile'
                : 'panel';
            const slice = Rect.fromLTRB(128, 64, 896, 448);
            final scale = math.max(
              compact ? 8.0 : 4.0,
              math.max(
                256 / math.max(1, constraints.maxWidth),
                128 / math.max(1, constraints.maxHeight),
              ),
            );
            final variant = presentation.variant.name;
            return Stack(
              fit: StackFit.passthrough,
              clipBehavior: Clip.none,
              children: [
                child!,
                Positioned.fill(
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: RepaintBoundary(
                        child: Opacity(
                          opacity: presentation.relicOpacity,
                          child: Image.asset(
                            pack.identityFrame,
                            key: ValueKey(
                              'theme-sheet-frame-${pack.id}-$name-$variant',
                            ),
                            scale: scale,
                            centerSlice: Rect.fromLTRB(
                              slice.left / scale,
                              slice.top / scale,
                              slice.right / scale,
                              slice.bottom / scale,
                            ),
                            fit: BoxFit.fill,
                            // Keep native pixels for nine-slice geometry. These
                            // shared small PNGs decode once in Flutter's cache.
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class OculumThemeSheetBackdrop extends StatelessWidget {
  const OculumThemeSheetBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      const Positioned.fill(
        child: IgnorePointer(
          child: Opacity(
            opacity: .30,
            child: OculumThemeSheetScene(fillArea: true),
          ),
        ),
      ),
      child,
    ],
  );
}

/// A backdrop scene adds no layout space. The loop spends most of its time
/// motionless and rebuilds only a Transform, never the functional sheet.
class OculumThemeSheetScene extends StatefulWidget {
  const OculumThemeSheetScene({super.key, this.fillArea = false});
  final bool fillArea;
  @override
  State<OculumThemeSheetScene> createState() => _OculumThemeSheetSceneState();
}

class _OculumThemeSheetSceneState extends State<OculumThemeSheetScene>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  );
  bool foreground = true;
  bool visible = true;
  ScrollPosition? scrollPosition;
  String preloadedPack = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    oculumThemePresentation.addListener(_updateMotion);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextPosition = Scrollable.maybeOf(context)?.position;
    if (nextPosition != scrollPosition) {
      scrollPosition?.removeListener(_checkVisibility);
      scrollPosition = nextPosition;
      scrollPosition?.addListener(_checkVisibility);
    }
    final spec = Theme.of(context).extension<OculumGothOrnaments>();
    if (spec != null && spec.themeId.isNotEmpty && spec.opacity > 0) {
      final pack = oculumResolveThemeArt(spec, oculumThemePresentation.value);
      final variant = oculumThemePresentation.value.variant.name;
      final preloadKey = '${pack.id}:$variant';
      if (preloadKey != preloadedPack) {
        preloadedPack = preloadKey;
        final mobile = MediaQuery.sizeOf(context).width < 600;
        for (final asset in [
          pack.frame(mobile ? 'mobile' : 'panel', variant: variant),
          pack.frame('portrait', variant: variant),
          pack.frame('statistics', variant: variant),
          pack.scene(mobile: mobile, variant: variant),
        ]) {
          precacheImage(AssetImage(asset), context);
        }
      }
    }
    _updateMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    _updateMotion();
  }

  void _updateMotion() {
    if (!mounted) return;
    final spec = Theme.of(context).extension<OculumGothOrnaments>();
    final enabled =
        spec != null &&
        spec.motion &&
        spec.opacity > 0 &&
        foreground &&
        visible &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context) &&
        oculumThemePresentation.value.motion != OculumThemeMotion.disabled;
    if (enabled && !clock.isAnimating) clock.repeat();
    if (!enabled && clock.isAnimating) clock.stop();
  }

  void _checkVisibility() {
    final box = context.findRenderObject();
    if (box is RenderBox && box.attached && box.hasSize) {
      final offset = box.localToGlobal(Offset.zero);
      final next =
          offset.dy + box.size.height > 0 &&
          offset.dy < MediaQuery.sizeOf(context).height;
      if (next != visible) {
        visible = next;
        _updateMotion();
      }
    }
  }

  @override
  void dispose() {
    scrollPosition?.removeListener(_checkVisibility);
    oculumThemePresentation.removeListener(_updateMotion);
    WidgetsBinding.instance.removeObserver(this);
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = Theme.of(context).extension<OculumGothOrnaments>();
    if (spec == null || spec.themeId.isEmpty || spec.opacity <= 0) {
      return const SizedBox(height: 8);
    }
    return ValueListenableBuilder<OculumThemePresentation>(
      valueListenable: oculumThemePresentation,
      builder: (context, presentation, _) {
        final pack = oculumResolveThemeArt(spec, presentation);
        final variant = presentation.variant.name;
        final mobile = MediaQuery.sizeOf(context).width < 600;
        final element = oculumElementForArtPack(pack.id);
        final identity = oculumThemeIdentities[pack.id];
        final animated =
            spec.motion &&
            presentation.motion != OculumThemeMotion.disabled &&
            !MediaQuery.disableAnimationsOf(context);
        final height = (mobile ? 52.0 : 96.0) * presentation.relicScale;
        return SizedBox(
          key: ValueKey('theme-sheet-scene-${pack.id}'),
          height: widget.fillArea ? double.infinity : height,
          width: double.infinity,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: ClipRect(
                child: RepaintBoundary(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Image.asset(
                          pack.frame('separator', variant: variant),
                          height: 12,
                          width: double.infinity,
                          fit: BoxFit.fill,
                          cacheWidth: 768,
                          opacity: const AlwaysStoppedAnimation(.3),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: clock,
                        child: Opacity(
                          opacity: presentation.relicOpacity,
                          child: Image.asset(
                            pack.scene(mobile: mobile, variant: variant),
                            // Wide decorative strips must never be enlarged
                            // to cover a tall sheet: that crops the artwork
                            // into a blurred block behind the reading area.
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomRight,
                            cacheWidth: mobile ? 640 : 1024,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                        builder: (context, child) {
                          _checkVisibility();
                          if (element != null) return child!;
                          final phase = clock.value < .78
                              ? 0.0
                              : math.sin((clock.value - .78) / .22 * math.pi);
                          final amount =
                              presentation.motion == OculumThemeMotion.reduced
                              ? .5
                              : 1.5;
                          return Transform.translate(
                            offset: Offset(0, -phase * amount),
                            child: child,
                          );
                        },
                      ),
                      if (animated && identity?.motion != 'none')
                        Positioned.fill(
                          child: CustomPaint(
                            key: ValueKey(
                              'element-ambient-${element ?? pack.id}',
                            ),
                            painter: OculumElementAmbientPainter(
                              clock: clock,
                              element: element ?? pack.id,
                              motion: identity?.motion,
                              color: spec.accent,
                              reduced:
                                  presentation.motion ==
                                  OculumThemeMotion.reduced,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
