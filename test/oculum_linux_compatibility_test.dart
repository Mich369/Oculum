import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart' as app;

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('Linux is exposed as a supported Oculum client platform', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    expect(app.oculumClientPlatformLabel(), 'linux');
  });

  test('the distribution workflow builds and smoke-tests Linux', () {
    final workflow = File(
      '.github/workflows/build_distribution.yml',
    ).readAsStringSync();

    expect(workflow, contains('build-linux:'));
    expect(workflow, contains('flutter build linux --release'));
    expect(workflow, contains('Smoke-test Linux startup'));
    expect(workflow, contains('xvfb-run -a'));
    expect(workflow, contains('scripts/package_linux_release.sh'));
    expect(workflow, contains('Oculum-Linux-x64.tar.gz'));
  });

  test('the Linux package keeps the complete Flutter bundle', () {
    final packagingScript = File(
      'scripts/package_linux_release.sh',
    ).readAsStringSync();

    expect(packagingScript, contains(r'cp -a "${bundle_source}/."'));
    expect(packagingScript, contains('app/oculum'));
    expect(packagingScript, contains('Avvia-Oculum.sh'));
    expect(packagingScript, contains('flutter build linux --release'));
    expect(packagingScript, contains('command -v flutter'));
    expect(packagingScript, contains('build/linux/arm64/release/bundle'));
    expect(packagingScript, contains(r'Oculum-Linux-${linux_arch}.tar.gz'));
    expect(packagingScript, contains(r'tar -C "${distribution_root}"'));
  });
}
