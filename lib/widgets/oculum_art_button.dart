import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'oculum_combat_theme.dart';
import 'oculum_goth_ornaments.dart';
import 'oculum_theme_presentation.dart';
import 'oculum_theme_relic.dart';
import 'oculum_hover_surface.dart';

/// A decorative layer for native Material buttons: input, semantics and sizing
/// remain owned by the original button, including its keyboard focus.
Widget oculumButtonArtwork(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) => OculumArtButtonLayer(states: states, child: child);

class OculumArtButtonLayer extends StatelessWidget {
  const OculumArtButtonLayer({super.key, required this.states, this.child});
  final Set<WidgetState> states;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec =
        theme.extension<OculumGothOrnaments>() ??
        const OculumGothOrnaments(
          family: OculumGothFamily.forged,
          ink: Color(0xFF09070D),
          accent: Color(0xFF9E6B2F),
          opacity: .7,
        );
    return ValueListenableBuilder<OculumThemePresentation>(
      valueListenable: oculumThemePresentation,
      child: child,
      builder: (context, presentation, child) =>
          ValueListenableBuilder<OculumCombatThemeState>(
            valueListenable: oculumCombatTheme,
            child: child,
            builder: (context, combat, child) {
              final family = combat.automatic ? combat.activeFamily : null;
              final artSpec = family == null
                  ? spec
                  : spec.copyWith(
                      family: family,
                      themeId: 'element_${combat.elementId}',
                    );
              final pack = oculumResolveThemeArt(
                artSpec,
                family == null
                    ? presentation
                    : OculumThemePresentation(variant: presentation.variant),
              );
              final disabled = states.contains(WidgetState.disabled);
              final active = states.contains(WidgetState.selected);
              final pressed = states.contains(WidgetState.pressed);
              final hover = states.contains(WidgetState.hovered);
              final focus = states.contains(WidgetState.focused);
              final state = disabled
                  ? 'disabled'
                  : pressed
                  ? 'pressed'
                  : active
                  ? 'selected'
                  : hover || focus
                  ? 'hover'
                  : 'normal';
              final scope = OculumSurfaceScope.maybeOf(context);
              final surfaceOpacity =
                  hover || focus || pressed || scope?.highlightAll == true
                  ? 1.0
                  : 1 - presentation.surfaceTransparency;
              return Stack(
                fit: StackFit.passthrough,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: surfaceOpacity,
                        child: ExcludeSemantics(
                          child: RepaintBoundary(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Opacity(
                                    opacity: disabled ? .035 : .10,
                                    child: Image.asset(
                                      pack.identitySurface,
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.low,
                                    ),
                                  ),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth <= 0 ||
                                          constraints.maxHeight <= 0) {
                                        return const SizedBox.shrink();
                                      }
                                      final scale = math.max(
                                        8.0,
                                        math.max(
                                          512 / constraints.maxWidth,
                                          256 / constraints.maxHeight,
                                        ),
                                      );
                                      return Image.asset(
                                        pack.buttonFrame(state),
                                        key: ValueKey(
                                          'button-art-${pack.id}-$state',
                                        ),
                                        scale: scale,
                                        centerSlice: Rect.fromLTRB(
                                          128 / scale,
                                          64 / scale,
                                          896 / scale,
                                          448 / scale,
                                        ),
                                        fit: BoxFit.fill,
                                        filterQuality: FilterQuality.medium,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ?child,
                ],
              );
            },
          ),
    );
  }
}

class _OculumButtonSurfaceColor implements WidgetStateProperty<Color?> {
  const _OculumButtonSurfaceColor(this.source, this.highlightAll);
  final WidgetStateProperty<Color?>? source;
  final bool highlightAll;
  @override
  Color? resolve(Set<WidgetState> states) {
    final color = source?.resolve(states);
    if (color == null) return null;
    final active =
        highlightAll ||
        states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused) ||
        states.contains(WidgetState.pressed);
    return oculumSurfaceColor(
      color,
      active ? 1 : 1 - oculumThemePresentation.value.surfaceTransparency,
    );
  }
}

/// Applies the shared layer without replacing local button styles or callbacks.
ThemeData oculumWithArtButtons(ThemeData theme, {bool highlightAll = false}) {
  ButtonStyle decorate(ButtonStyle? style) {
    final base = style ?? const ButtonStyle();
    final color = base.backgroundColor;
    final source = color is _OculumButtonSurfaceColor ? color.source : color;
    return base.copyWith(
      backgroundBuilder: oculumButtonArtwork,
      backgroundColor: _OculumButtonSurfaceColor(source, highlightAll),
    );
  }

  return theme.copyWith(
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: decorate(theme.elevatedButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: decorate(theme.outlinedButtonTheme.style),
    ),
    textButtonTheme: TextButtonThemeData(
      style: decorate(theme.textButtonTheme.style),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: decorate(theme.filledButtonTheme.style),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: decorate(theme.iconButtonTheme.style),
    ),
  );
}

/// The same artwork for existing InkWell navigation, with native focus/hover.
class OculumArtInkWell extends StatefulWidget {
  const OculumArtInkWell({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
  });
  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final BorderRadius? borderRadius;
  final Color? splashColor, highlightColor;

  @override
  State<OculumArtInkWell> createState() => _OculumArtInkWellState();
}

class _OculumArtInkWellState extends State<OculumArtInkWell> {
  final states = WidgetStatesController();
  @override
  void dispose() {
    states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InkWell(
    statesController: states,
    onTap: widget.onTap,
    borderRadius: widget.borderRadius,
    splashColor: widget.splashColor,
    highlightColor: widget.highlightColor,
    child: ValueListenableBuilder<Set<WidgetState>>(
      valueListenable: states,
      child: widget.child,
      builder: (context, value, child) => OculumArtButtonLayer(
        states: {
          ...value,
          if (widget.selected) WidgetState.selected,
          if (widget.onTap == null) WidgetState.disabled,
        },
        child: child,
      ),
    ),
  );
}
