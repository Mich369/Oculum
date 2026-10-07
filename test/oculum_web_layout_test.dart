import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_web_layout.dart';

void main() {
  test(
    'Auto view follows phone and iPad orientation, manual choices override it',
    () {
      for (final size in [
        const Size(390, 844),
        const Size(834, 1194),
        const Size(1024, 1366),
      ]) {
        expect(oculumWebUsesDesktop(size, OculumWebViewMode.automatic), false);
        expect(
          oculumWebUsesDesktop(
            Size(size.height, size.width),
            OculumWebViewMode.automatic,
          ),
          true,
        );
        expect(oculumWebUsesDesktop(size, OculumWebViewMode.desktop), true);
        expect(
          oculumWebUsesDesktop(
            Size(size.height, size.width),
            OculumWebViewMode.mobile,
          ),
          false,
        );
      }
    },
  );
  testWidgets('Web layout follows width and rotation without layout errors', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(834, 1194));
    addTearDown(() async {
      oculumWebViewMode.value = OculumWebViewMode.automatic;
      await tester.binding.setSurfaceSize(null);
    });
    bool? desktop;
    Size? size;
    await tester.pumpWidget(
      MaterialApp(
        home: OculumWebLayout(
          child: Builder(
            builder: (context) {
              desktop = OculumWebLayoutScope.desktopOf(context);
              size = MediaQuery.sizeOf(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    expect(desktop, false);
    expect(size!.width, 599);
    oculumWebViewMode.value = OculumWebViewMode.desktop;
    await tester.pump();
    expect(desktop, true);
    expect(size!.width, 1100);
    await tester.binding.setSurfaceSize(const Size(1194, 834));
    oculumWebViewMode.value = OculumWebViewMode.automatic;
    await tester.pump();
    expect(desktop, true);
    expect(size!.width, 1194);
    await tester.binding.setSurfaceSize(const Size(844, 390));
    await tester.pump();
    expect(desktop, true);
    expect(size!.shortestSide, greaterThanOrEqualTo(600));
    expect(tester.takeException(), isNull);
  });
}
