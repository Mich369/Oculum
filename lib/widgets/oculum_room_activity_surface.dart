import 'package:flutter/material.dart';

class OculumRoomActivitySurface extends StatelessWidget {
  const OculumRoomActivitySurface({
    super.key,
    required this.onActivity,
    required this.child,
  });
  final VoidCallback onActivity;
  final Widget child;
  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => onActivity(),
    onPointerSignal: (_) => onActivity(),
    child: MouseRegion(
      onHover: (_) => onActivity(),
      child: Focus(
        onKeyEvent: (_, _) {
          onActivity();
          return KeyEventResult.ignored;
        },
        child: child,
      ),
    ),
  );
}
