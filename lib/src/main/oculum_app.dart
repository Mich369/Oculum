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
      home: const OculumHomePage(),
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
