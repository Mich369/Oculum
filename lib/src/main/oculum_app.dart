part of '../../main.dart';

final ThemeData oculumBaseTheme = ThemeData(
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
  fontFamily: 'Segoe UI',
  splashFactory: NoSplash.splashFactory,
  cardTheme: const CardThemeData(
    elevation: 0,
    margin: EdgeInsets.symmetric(vertical: 6),
  ),
  dividerTheme: const DividerThemeData(
    thickness: 1,
    space: 24,
    color: Color(0xFF302D37),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF131118),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF36313D)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(36, 36),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(34, 34),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      minimumSize: const Size(32, 32),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
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
);
final ValueNotifier<ThemeData?> oculumActiveTheme = ValueNotifier(null);

class OculumThemeScope extends StatelessWidget {
  const OculumThemeScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeData?>(
    valueListenable: oculumActiveTheme,
    child: child,
    builder: (context, activeTheme, child) {
      final theme = oculumWithArtButtons(activeTheme ?? oculumBaseTheme);
      final ornaments = theme.extension<OculumGothOrnaments>();
      return Theme(
        data: theme,
        child: ValueListenableBuilder<OculumThemePresentation>(
          valueListenable: oculumThemePresentation,
          child: child,
          builder: (context, presentation, child) =>
              ValueListenableBuilder<OculumCombatThemeState>(
                valueListenable: oculumCombatTheme,
                child: child,
                builder: (context, combat, child) {
                  final combatFamily = combat.automatic
                      ? combat.activeFamily
                      : null;
                  final selectedOrnaments = ornaments?.copyWith(
                    family: combatFamily ?? ornaments.family,
                    themeId: combatFamily == null
                        ? ornaments.themeId
                        : 'element_${combat.elementId}',
                    motion:
                        ornaments.motion &&
                        presentation.motion != OculumThemeMotion.disabled,
                    variant: presentation.variant,
                  );
                  final spec =
                      selectedOrnaments ??
                      const OculumGothOrnaments(
                        family: OculumGothFamily.none,
                        ink: Colors.transparent,
                        accent: Colors.transparent,
                        opacity: 0,
                      );
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      OculumGothAmbience(
                        spec: spec,
                        child: Theme(
                          data: theme.copyWith(
                            extensions: [
                              for (final extension in theme.extensions.values)
                                if (extension is! OculumGothOrnaments)
                                  extension,
                              ?selectedOrnaments,
                            ],
                          ),
                          child: child!,
                        ),
                      ),
                      const Positioned.fill(child: OculumCustomArtworkLayer()),
                      const Positioned.fill(child: OculumCustomArtworkLayer()),
                      Positioned.fill(
                        child: OculumCombatReactionHost(
                          state: combat,
                          transitionDuration: switch (presentation.motion) {
                            OculumThemeMotion.complete => const Duration(
                              milliseconds: 120,
                            ),
                            OculumThemeMotion.reduced => const Duration(
                              milliseconds: 80,
                            ),
                            OculumThemeMotion.disabled => Duration.zero,
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
        ),
      );
    },
  );
}

final ValueNotifier<bool> oculumGraphicsEnabled = ValueNotifier(false);

Future<void> loadOculumGraphicsPreference() async {
  await loadOculumThemePresentation();
  await oculumCombatTheme.loadPreference();
  final prefs = await SharedPreferences.getInstance();
  oculumGraphicsEnabled.value =
      prefs.getBool('oculum.graphicsEnabled') ?? false;
}

Future<void> setOculumGraphicsPreference(bool enabled) async {
  oculumGraphicsEnabled.value = enabled;
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      (enabled ? 96 : 40) * 1024 * 1024;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('oculum.graphicsEnabled', enabled);
}

class OculumApp extends StatelessWidget {
  const OculumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: oculumGraphicsEnabled,
      builder: (context, graphics, _) => MaterialApp(
        title: 'Oculum',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const _OculumAdaptiveScrollBehavior(),
        builder: (context, child) {
          Widget typographyContent(BuildContext contentContext) {
            final media = MediaQuery.of(contentContext);
            final compactPhone = media.size.shortestSide < 600;
            final tablet =
                media.size.shortestSide >= 600 && media.size.width < 1100;
            return MediaQuery(
              data: media.copyWith(
                disableAnimations: media.disableAnimations || !graphics,
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
          }

          final content = kIsWeb
              ? OculumWebLayout(child: Builder(builder: typographyContent))
              : typographyContent(context);
          return OculumThemeScope(child: content);
        },
        theme: oculumWithArtButtons(oculumBaseTheme),
        home: const OculumStartupPreloader(),
      ),
    );
  }
}

class OculumStartupPreloader extends StatefulWidget {
  const OculumStartupPreloader({super.key});

  @override
  State<OculumStartupPreloader> createState() => _OculumStartupPreloaderState();
}

class _OculumStartupPreloaderState extends State<OculumStartupPreloader>
    with SingleTickerProviderStateMixin {
  double progress = 0.02;
  String label = 'Preparazione Oculum...';
  bool ready = false;
  bool preloadStarted = false;
  OculumStartupRole? selectedRole;
  late final AnimationController _homeArtworkAnimation;

  @override
  void initState() {
    super.initState();
    _homeArtworkAnimation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _homeArtworkAnimation.dispose();
    super.dispose();
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
    _homeArtworkAnimation.stop();
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            OculumWatchingEyes(animation: _homeArtworkAnimation),
            Center(
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
          ],
        ),
      ),
    );
  }

  Widget startupRoleChoice(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050408),
      body: Stack(
        fit: StackFit.expand,
        children: [
          OculumWatchingEyes(animation: _homeArtworkAnimation),
          Center(
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
        ],
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
