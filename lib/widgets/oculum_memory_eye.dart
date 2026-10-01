import 'package:flutter/material.dart';

String? oculumMemoryEyeAsset(String role) => switch (role) {
  'npc' || 'party' => 'assets/oculum/icons/oculum_npc_eye.png',
  'enemy' || 'creature' => 'assets/icon/oculum_eye.png',
  'dead' => 'assets/oculum/icons/oculum_dead_eye.png',
  'obliterated' => 'assets/oculum/icons/oculum_obliterated_eye.png',
  _ => null,
};

class OculumMemoryEye extends StatelessWidget {
  const OculumMemoryEye({super.key, required this.role, this.size = 24});
  final String role;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = oculumMemoryEyeAsset(role);
    return SizedBox.square(
      dimension: size,
      child: asset == null
          ? const Icon(Icons.visibility, color: Color(0xffc3a46b))
          : Image.asset(
              asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              semanticLabel: role,
            ),
    );
  }
}
