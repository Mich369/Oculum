import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_auth_service.dart';

void main() {
  test('il callback OAuth nativo usa lo schema stabile di Oculum', () {
    final redirect = Uri.parse(oculumOAuthRedirectUrl);

    expect(redirect.scheme, 'com.mich.oculum');
    expect(redirect.host, 'login-callback');
  });

  test('Android APK abilita rete e callback Supabase', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.INTERNET'));
    expect(manifest, contains('android.permission.ACCESS_NETWORK_STATE'));
    expect(manifest, contains('android:scheme="com.mich.oculum"'));
    expect(manifest, contains('android:host="login-callback"'));
  });

  test('iOS registra il callback Supabase', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(infoPlist, contains('<key>CFBundleURLTypes</key>'));
    expect(infoPlist, contains('<string>com.mich.oculum</string>'));
  });

  test('macOS abilita rete sandbox e callback Supabase', () {
    final infoPlist = File('macos/Runner/Info.plist').readAsStringSync();
    final entitlements = File(
      'macos/Runner/Release.entitlements',
    ).readAsStringSync();
    final xcodeProject = File(
      'macos/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    expect(infoPlist, contains('<key>CFBundleURLTypes</key>'));
    expect(infoPlist, contains('<string>com.mich.oculum</string>'));
    expect(
      entitlements,
      matches(
        RegExp(r'<key>com\.apple\.security\.network\.client</key>\s*<true/>'),
      ),
    );
    expect(
      xcodeProject,
      contains('CODE_SIGN_ENTITLEMENTS = Runner/Release.entitlements;'),
    );
  });

  test('le build native usano la chiave publishable moderna', () {
    final distributionWorkflow = File(
      '.github/workflows/build_distribution.yml',
    ).readAsStringSync();
    final macosWorkflow = File(
      '.github/workflows/build_macos.yml',
    ).readAsStringSync();

    for (final workflow in [distributionWorkflow, macosWorkflow]) {
      expect(workflow, contains('OculumSupabasePublishableKey='));
      expect(
        workflow,
        contains('OculumOAuthRedirectUrl=com.mich.oculum://login-callback'),
      );
    }
  });

  test('le build macOS richiedono firma Developer ID e notarizzazione', () {
    final signingScript = File(
      'scripts/sign_and_notarize_macos.sh',
    ).readAsStringSync();
    final distributionWorkflow = File(
      '.github/workflows/build_distribution.yml',
    ).readAsStringSync();
    final macosWorkflow = File(
      '.github/workflows/build_macos.yml',
    ).readAsStringSync();

    expect(signingScript, contains('codesign'));
    expect(signingScript, contains('--options runtime'));
    expect(signingScript, contains('xcrun notarytool submit'));
    expect(signingScript, contains('xcrun stapler staple'));
    expect(signingScript, contains('spctl --assess'));

    for (final workflow in [distributionWorkflow, macosWorkflow]) {
      expect(workflow, contains('scripts/sign_and_notarize_macos.sh'));
      expect(workflow, contains('APPLE_DEVELOPER_ID_CERTIFICATE_BASE64'));
      expect(workflow, contains('APPLE_APP_SPECIFIC_PASSWORD'));
      expect(workflow, contains('APPLE_TEAM_ID'));
    }
  });
}
