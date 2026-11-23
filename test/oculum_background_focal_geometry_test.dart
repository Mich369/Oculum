import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_focal_background.dart';

void main() {
  test(
    'right and left subjects remain visible without empty edges on phones',
    () {
      for (final viewport in const [
        Size(320, 740),
        Size(390, 844),
        Size(1080, 1920),
      ]) {
        for (final subject in const [Offset(.31, .5), Offset(.66, .5)]) {
          const source = Size(1586, 992);
          final visible = applyBoxFit(BoxFit.cover, source, viewport).source;
          final crop = oculumBackgroundFocalAlignment(
            source,
            viewport,
            subject,
          ).inscribe(visible, Offset.zero & source);
          expect(crop.center.dx, closeTo(source.width * subject.dx, .01));
          expect(crop.left, greaterThanOrEqualTo(0));
          expect(crop.right, lessThanOrEqualTo(source.width));
        }
      }
    },
  );

  test('portrait source and extreme focus clamp inside the original image', () {
    const source = Size(960, 1707);
    for (final viewport in const [Size(390, 844), Size(844, 390)]) {
      for (final focus in const [Offset.zero, Offset(1, 1), Offset(.5, .5)]) {
        final visible = applyBoxFit(BoxFit.cover, source, viewport).source;
        final crop = oculumBackgroundFocalAlignment(
          source,
          viewport,
          focus,
        ).inscribe(visible, Offset.zero & source);
        expect(crop.left, greaterThanOrEqualTo(-.001));
        expect(crop.top, greaterThanOrEqualTo(-.001));
        expect(crop.right, lessThanOrEqualTo(source.width + .001));
        expect(crop.bottom, lessThanOrEqualTo(source.height + .001));
      }
    }
  });
}
