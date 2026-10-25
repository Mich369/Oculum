import 'package:flutter/material.dart';
import 'oculum_theme_presentation.dart';

Color oculumSurfaceColor(Color color, double opacity) =>
    color.withValues(alpha: color.a * opacity.clamp(0, 1));

BoxDecoration oculumSurfaceDecoration(BoxDecoration value, double opacity) =>
    value.copyWith(
      color: value.color == null
          ? null
          : oculumSurfaceColor(value.color!, opacity),
      gradient: switch (value.gradient) {
        LinearGradient g => LinearGradient(
          begin: g.begin,
          end: g.end,
          stops: g.stops,
          tileMode: g.tileMode,
          transform: g.transform,
          colors: [
            for (final color in g.colors) oculumSurfaceColor(color, opacity),
          ],
        ),
        _ => value.gradient,
      },
    );

/// The scope brightens the whole action panel until a specific button is hit.
class OculumSurfaceScope extends InheritedWidget {
  const OculumSurfaceScope({
    super.key,
    required this.highlightAll,
    required this.setButtonHover,
    required super.child,
  });
  final bool highlightAll;
  final void Function(Object, bool) setButtonHover;
  static OculumSurfaceScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OculumSurfaceScope>();
  @override
  bool updateShouldNotify(OculumSurfaceScope oldWidget) =>
      highlightAll != oldWidget.highlightAll;
}

/// Fades only decorations supplied to the builder, never text or hit targets.
class OculumHoverSurface extends StatefulWidget {
  const OculumHoverSurface({
    super.key,
    required this.builder,
    this.actionGroup = false,
  });
  final Widget Function(BuildContext, double) builder;
  final bool actionGroup;
  @override
  State<OculumHoverSurface> createState() => _OculumHoverSurfaceState();
}

class _OculumHoverSurfaceState extends State<OculumHoverSurface> {
  bool hovered = false;
  final buttons = <Object>{};
  void buttonHover(Object key, bool value) {
    final changed = value ? buttons.add(key) : buttons.remove(key);
    if (changed && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<OculumThemePresentation>(
        valueListenable: oculumThemePresentation,
        builder: (context, value, _) => MouseRegion(
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() {
            hovered = false;
            buttons.clear();
          }),
          child: OculumSurfaceScope(
            highlightAll: widget.actionGroup && hovered && buttons.isEmpty,
            setButtonHover: buttonHover,
            child: Builder(
              builder: (context) => widget.builder(
                context,
                hovered ? 1 : 1 - value.surfaceTransparency,
              ),
            ),
          ),
        ),
      );
}

/// Preserves the original button callbacks and labels, including icon layouts.
/// Local attack/defense colors receive the same treatment as theme buttons.
class OculumSurfaceButton extends StatefulWidget {
  const OculumSurfaceButton({super.key, required this.child});
  final Widget child;
  @override
  State<OculumSurfaceButton> createState() => _OculumSurfaceButtonState();
}

class _OculumSurfaceButtonState extends State<OculumSurfaceButton> {
  @override
  Widget build(BuildContext context) {
    final button = widget.child;
    if (button is! ButtonStyleButton) return button;
    final scope = OculumSurfaceScope.maybeOf(context);
    final base = button.style ?? const ButtonStyle();
    final style = base.copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        final color = base.backgroundColor?.resolve(states);
        if (color == null) return null;
        final active =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed);
        return oculumSurfaceColor(
          color,
          active || scope?.highlightAll == true
              ? 1
              : 1 - oculumThemePresentation.value.surfaceTransparency,
        );
      }),
    );
    final child = button.child ?? const SizedBox.shrink();
    final Widget result;
    if (button is FilledButton) {
      result = FilledButton(
        onPressed: button.onPressed,
        onLongPress: button.onLongPress,
        onHover: button.onHover,
        onFocusChange: button.onFocusChange,
        focusNode: button.focusNode,
        autofocus: button.autofocus,
        clipBehavior: button.clipBehavior,
        statesController: button.statesController,
        style: style,
        child: child,
      );
    } else if (button is OutlinedButton) {
      result = OutlinedButton(
        onPressed: button.onPressed,
        onLongPress: button.onLongPress,
        onHover: button.onHover,
        onFocusChange: button.onFocusChange,
        focusNode: button.focusNode,
        autofocus: button.autofocus,
        clipBehavior: button.clipBehavior,
        statesController: button.statesController,
        style: style,
        child: child,
      );
    } else {
      return button;
    }
    return MouseRegion(
      onEnter: (_) => scope?.setButtonHover(this, true),
      onExit: (_) => scope?.setButtonHover(this, false),
      child: result,
    );
  }
}
