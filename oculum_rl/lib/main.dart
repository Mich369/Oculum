import 'package:flutter/material.dart';

import 'pages/oculum_lite_page.dart';
import 'pages/oculum_rl_room_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OculumRlApp());
}

class OculumRlApp extends StatelessWidget {
  const OculumRlApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Oculum RL',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xffa07954),
      fontFamily: 'Poppins',
    ),
    home: const _Launch(),
  );
}

class _Launch extends StatelessWidget {
  const _Launch();

  @override
  Widget build(BuildContext context) => OculumLitePage(
    openRoom: () async {
      await Navigator.of(
        context,
      ).push<void>(MaterialPageRoute(builder: (_) => const OculumRlRoomPage()));
    },
  );
}
