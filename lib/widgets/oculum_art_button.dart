import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'oculum_combat_theme.dart';
import 'oculum_goth_ornaments.dart';
import 'oculum_theme_presentation.dart';
import 'oculum_theme_relic.dart';

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
              return Stack(
                fit: StackFit.passthrough,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
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
                                    oculumMaterialTexture(artSpec),
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
                  ?child,
                ],
              );
            },
          ),
    );
  }
}

/// Applies the shared layer without replacing local button styles or callbacks.
ThemeData oculumWithArtButtons(ThemeData theme) {
  ButtonStyle decorate(ButtonStyle? style) => (style ?? const ButtonStyle())
      .copyWith(backgroundBuilder: oculumButtonArtwork);
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
