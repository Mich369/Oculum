import 'package:flutter/material.dart';

import 'pages/oculum_lite_page.dart';
import 'pages/oculum_rl_room_page.dart';
import 'services/oculum_rl_updates.dart';

void main(List<String> arguments) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(OculumRlApp(suspendUpdates: arguments.contains('--no-update')));
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => acknowledgeOculumRlUpdate(),
  );
}

class OculumRlApp extends StatelessWidget {
  const OculumRlApp({super.key, this.suspendUpdates = false});
  final bool suspendUpdates;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Oculum RL',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xffa07954),
      fontFamily: 'Poppins',
    ),
    home: _Launch(suspendUpdates: suspendUpdates),
  );
}

class _Launch extends StatelessWidget {
  const _Launch({required this.suspendUpdates});
  final bool suspendUpdates;

  @override
  Widget build(BuildContext context) => OculumLitePage(
    suspendUpdates: suspendUpdates,
    openRoom: () async {
      await Navigator.of(
        context,
      ).push<void>(MaterialPageRoute(builder: (_) => const OculumRlRoomPage()));
    },
  );
}
