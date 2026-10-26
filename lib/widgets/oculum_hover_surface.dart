import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'oculum_theme_presentation.dart';

const oculumSurfaceRevealDuration = Duration(seconds: 3);

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
    this.secondaryControls = false,
    this.animationDuration = Duration.zero,
    required super.child,
  });
  final bool highlightAll;
  final bool secondaryControls;
  final Duration animationDuration;
  final void Function(Object, bool) setButtonHover;
  static OculumSurfaceScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OculumSurfaceScope>();
  @override
  bool updateShouldNotify(OculumSurfaceScope oldWidget) =>
      highlightAll != oldWidget.highlightAll ||
      secondaryControls != oldWidget.secondaryControls ||
      animationDuration != oldWidget.animationDuration;
}

Duration oculumSurfaceAnimationDurationOf(BuildContext context) =>
    OculumSurfaceScope.maybeOf(context)?.animationDuration ?? Duration.zero;

/// Supplies opacity and duration for decoration-only animations. Keep the
/// interactive child stable while AnimatedContainer/Material paints the fade.
class OculumHoverSurface extends StatefulWidget {
  const OculumHoverSurface({
    super.key,
    required this.builder,
    this.actionGroup = false,
    this.secondaryControls = false,
  });
  final Widget Function(BuildContext, double) builder;
  final bool actionGroup;
  final bool secondaryControls;
  @override
  State<OculumHoverSurface> createState() => _OculumHoverSurfaceState();
}

class _OculumHoverSurfaceState extends State<OculumHoverSurface> {
  bool hovered = false;
  bool touched = false;
  Timer? touchReveal;
  final buttons = <Object>{};
  @override
  void dispose() {
    touchReveal?.cancel();
    super.dispose();
  }

  void revealOnTouch(PointerUpEvent event) {
    if (event.kind == PointerDeviceKind.mouse) return;
    // A tap may open a popup. Wait until its route is installed, so decorative
    // feedback cannot rebuild the panel while the popup blocks its semantics.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
      touchReveal?.cancel();
      setState(() => touched = true);
      touchReveal = Timer(oculumSurfaceRevealDuration, () {
        if (!mounted) return;
        if (ModalRoute.of(context)?.isCurrent == false) {
          touched = false;
        } else {
          setState(() => touched = false);
        }
      });
    });
    WidgetsBinding.instance.scheduleFrame();
  }

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
          child: Listener(
            onPointerUp: revealOnTouch,
            child: OculumSurfaceScope(
              secondaryControls: widget.secondaryControls,
              animationDuration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : hovered || touched
                  ? oculumSurfaceRevealDuration
                  : const Duration(milliseconds: 200),
              highlightAll:
                  widget.actionGroup && (hovered || touched) && buttons.isEmpty,
              setButtonHover: buttonHover,
              child: Builder(
                builder: (context) => widget.builder(
                  context,
                  hovered || touched
                      ? 1
                      : 1 -
                            (widget.secondaryControls
                                ? value.controlTransparency
                                : value.surfaceTransparency),
                ),
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
      animationDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : oculumSurfaceRevealDuration,
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
              : 1 -
                    (scope?.secondaryControls == true
                        ? oculumThemePresentation.value.controlTransparency
                        : oculumThemePresentation.value.surfaceTransparency),
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
