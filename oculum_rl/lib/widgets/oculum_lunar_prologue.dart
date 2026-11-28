import 'dart:async';

import 'package:flutter/material.dart';

const oculumLunarPrologue =
    "là dove prima regnava la luna con la sua bontà ora c'è solo la tirannia del sole";

Future<void> showOculumLunarPrologue(BuildContext context) =>
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => const _LunarPrologue(),
      ),
    );

class _LunarPrologue extends StatefulWidget {
  const _LunarPrologue();

  @override
  State<_LunarPrologue> createState() => _LunarPrologueState();
}

class _LunarPrologueState extends State<_LunarPrologue> {
  late final Timer _end;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _end = Timer(const Duration(seconds: 5), _continue);
  }

  void _continue() {
    if (_closed || !mounted || ModalRoute.of(context)?.isCurrent != true)
      return;
    _closed = true;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _end.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 24, 30, 86),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 660),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 660),
                  curve: Curves.easeOut,
                  builder: (_, alpha, child) =>
                      Opacity(opacity: alpha, child: child),
                  child: const Text(
                    oculumLunarPrologue,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xffe8dfeb),
                      fontFamily: 'Garamond',
                      fontSize: 31,
                      height: 1.32,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 25,
            bottom: 20,
            child: TextButton(
              onPressed: _continue,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xffc8b9d2),
              ),
              child: const Text('Continua'),
            ),
          ),
        ],
      ),
    ),
  );
}
