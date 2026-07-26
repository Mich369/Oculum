part of '../../main.dart';

class OculumApp extends StatelessWidget {
  const OculumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oculum',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _OculumAdaptiveScrollBehavior(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final compactPhone = media.size.shortestSide < 600;
        final tablet =
            media.size.shortestSide >= 600 && media.size.width < 1100;
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(
              compactPhone
                  ? 0.84
                  : tablet
                  ? 0.92
                  : 0.95,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        brightness: Brightness.dark,
        visualDensity: VisualDensity.compact,
        scaffoldBackgroundColor: const Color(0xFF050408),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF09070D),
          primary: Color(0xFFE6D8BD),
          secondary: Color(0xFF9E6B2F),
          tertiary: Color(0xFF8F1D2C),
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(36, 36),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(34, 34),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(32, 32),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        chipTheme: ChipThemeData(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          side: const BorderSide(color: Color(0x669E6B2F)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        listTileTheme: const ListTileThemeData(
          dense: true,
          minLeadingWidth: 24,
          horizontalTitleGap: 8,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        ),
        expansionTileTheme: const ExpansionTileThemeData(
          tilePadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          childrenPadding: EdgeInsets.fromLTRB(10, 0, 10, 8),
        ),
      ),
      home: const OculumStartupPreloader(),
    );
  }
}

class OculumStartupPreloader extends StatefulWidget {
  const OculumStartupPreloader({super.key});

  @override
  State<OculumStartupPreloader> createState() => _OculumStartupPreloaderState();
}

class _OculumStartupPreloaderState extends State<OculumStartupPreloader> {
  double progress = 0.02;
  String label = 'Preparazione Oculum...';
  bool ready = false;
  bool preloadStarted = false;
  OculumStartupRole? selectedRole;

  @override
  void initState() {
    super.initState();
  }

  Future<void> startPreload() async {
    if (selectedRole == null || preloadStarted) return;
    preloadStarted = true;
    oculumProfileMark('startup_preload');
    try {
      await preloadOculumStartupServices(
        onProgress: (nextProgress, nextLabel) {
          if (!mounted) return;
          setState(() {
            progress = nextProgress.clamp(0.0, 1.0).toDouble();
            label = nextLabel;
          });
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Oculum startup preload recovered: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        progress = 0.94;
        label = 'Avvio in modalita locale...';
      });
    }

    if (!mounted) return;
    setState(() {
      progress = 1;
      label = 'Apertura scheda...';
    });
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    oculumProfileMark('home_initial_build');
    setState(() => ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (ready) return const OculumHomePage();
    if (selectedRole == null) return startupRoleChoice(context);

    final percent = (progress * 100).clamp(0, 100).round();
    return Scaffold(
      backgroundColor: const Color(0xFF050408),
      body: RepaintBoundary(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFF07080D),
                Color(0xFF10121A),
                Color(0xFF050408),
              ],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.remove_red_eye,
                      color: Color(0xFFE6D8BD),
                      size: 48,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'OCULUM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFE6D8BD),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(end: progress),
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          color: const Color(0xFFC9A44C),
                          backgroundColor: const Color(0xFF2A241E),
                          borderRadius: BorderRadius.circular(8),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$percent%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFC9A44C),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 140),
                      child: Text(
                        label,
                        key: ValueKey<String>(label),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFE8DCC2),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget startupRoleChoice(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050408),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF07080D),
              Color(0xFF10121A),
              Color(0xFF050408),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.remove_red_eye,
                    color: Color(0xFFE6D8BD),
                    size: 54,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'OCULUM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFE6D8BD),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedRole = OculumStartupRole.player;
                        oculumStartupRole = OculumStartupRole.player;
                      });
                      unawaited(startPreload());
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('Player'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE6D8BD),
                      foregroundColor: const Color(0xFF050408),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedRole = OculumStartupRole.master;
                        oculumStartupRole = OculumStartupRole.master;
                      });
                      unawaited(startPreload());
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Master'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE6D8BD),
                      side: const BorderSide(color: Color(0xFFE6D8BD)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OculumAdaptiveScrollBehavior extends MaterialScrollBehavior {
  const _OculumAdaptiveScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    final platform = getPlatform(context);
    if (platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux) {
      return const ClampingScrollPhysics();
    }
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

// =====================================================
