import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OculumWebViewMode { automatic, desktop, mobile }

final oculumWebViewMode = ValueNotifier(OculumWebViewMode.automatic);

Future<void> loadOculumWebViewMode() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('oculum.webViewMode');
  oculumWebViewMode.value = OculumWebViewMode.values.firstWhere(
    (mode) => mode.name == saved,
    orElse: () => OculumWebViewMode.automatic,
  );
}

Future<void> setOculumWebViewMode(OculumWebViewMode mode) async {
  oculumWebViewMode.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('oculum.webViewMode', mode.name);
}

bool oculumWebUsesDesktop(Size size, OculumWebViewMode mode) => switch (mode) {
  OculumWebViewMode.desktop => true,
  OculumWebViewMode.mobile => false,
  OculumWebViewMode.automatic => size.width > size.height,
};

class OculumWebLayoutScope extends InheritedWidget {
  const OculumWebLayoutScope({
    super.key,
    required this.desktop,
    required super.child,
  });
  final bool desktop;
  static bool desktopOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<OculumWebLayoutScope>()
          ?.desktop ??
      false;
  @override
  bool updateShouldNotify(OculumWebLayoutScope oldWidget) =>
      desktop != oldWidget.desktop;
}

/// Use the existing desktop/mobile Flutter pages at a consistent logical width.
/// Insets are transformed too, so iPad keyboards and safe areas stay usable.
class OculumWebLayout extends StatelessWidget {
  const OculumWebLayout({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<OculumWebViewMode>(
        valueListenable: oculumWebViewMode,
        builder: (context, mode, _) => LayoutBuilder(
          builder: (context, constraints) {
            final media = MediaQuery.of(context);
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final desktop = oculumWebUsesDesktop(size, mode);
            final width =
                (desktop
                        ? size.width.clamp(1100, double.infinity)
                        : size.width.clamp(1, 599))
                    .toDouble();
            final height = desktop
                ? (size.height * width / size.width)
                      .clamp(600, double.infinity)
                      .toDouble()
                : size.height * width / size.width;
            final scale = size.width / width < size.height / height
                ? size.width / width
                : size.height / height;
            if (!scale.isFinite || scale <= 0) return child;
            final virtualSize = Size(width, height);
            return FittedBox(
              fit: BoxFit.contain,
              child: SizedBox.fromSize(
                size: virtualSize,
                child: OculumWebLayoutScope(
                  desktop: desktop,
                  child: MediaQuery(
                    data: media.copyWith(
                      size: virtualSize,
                      padding: media.padding / scale,
                      viewPadding: media.viewPadding / scale,
                      viewInsets: media.viewInsets / scale,
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
        ),
      );
}
