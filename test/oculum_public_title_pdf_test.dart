import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';

void main() {
  testWidgets(
    'public title scales once, evolved wins, Oculus exports real PG',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final directory = Directory('build/public-title-test')
        ..createSync(recursive: true);
      for (final channel in [
        'plugins.flutter.io/path_provider',
        'dev.fluttercommunity.plus/connectivity',
        'dev.fluttercommunity.plus/connectivity_status',
      ]) {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          MethodChannel(channel),
          (_) async => channel.contains('path_provider')
              ? directory.absolute.path
              : channel.endsWith('connectivity')
              ? ['none']
              : null,
        );
      }
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(home: OculumHomePage(key: key)));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump(const Duration(seconds: 1));
      final dynamic state = key.currentState!;
      final probe = OculumPerformanceProbe(key.currentState!);
      final normal = OculumTitle.fromJson({
        'nome': 'Normale',
        'equipaggiato': true,
        'sempreVisibile': true,
        'volonta': 10,
        'buff': '@Danni+10 @Difesa-5',
      });
      final evolved = OculumTitle.fromJson({
        'nome': 'Evoluto',
        'equipaggiato': true,
        'evoluto': true,
        'volonta': 5,
        'buff': '@VOL+5 @Danni+20',
      });
      state.titoli
        ..clear()
        ..add(normal);
      expect(probe.titleBonuses(normal)['volonta'], 3);
      expect(probe.titleBonuses(normal)['danni'], 13);
      expect(probe.titleBonuses(normal)['difesa'], -5);
      state.titoli.add(evolved);
      expect(probe.titleBonuses(normal)['danni'], 10);
      expect(probe.titleBonuses(evolved)['volonta'], 8);
      expect(probe.titleBonuses(evolved)['danni'], 26);
      expect(evolved.volonta, 5);
      expect(probe.titleBonuses(evolved)['danni'], 26);
      evolved.equipaggiato = false;
      expect(probe.titleBonuses(normal)['danni'], 13);
      state.oculusModData = oculusDefaultCharacterData();
      state.oculusModData.addAll({
        'name': 'Alda la Custode',
        'player': 'Michele',
        'title': 'Custode del Bosco',
        'titleOpenII': 'Secondo risveglio verificato',
        'notes': List.filled(
          60,
          'Oggetto e nota lunga del personaggio.',
        ).join(' '),
        'life': 17,
        'maxLife': 24,
        'titleLevel': 6,
      });
      await tester.runAsync(() async {
        final bytes = await probe.oculusFilledPdf();
        expect(bytes.length, greaterThan(10000));
        Directory('output/pdf').createSync(recursive: true);
        File('output/pdf/Oculus_PG_verifica.pdf').writeAsBytesSync(bytes);
      });
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
