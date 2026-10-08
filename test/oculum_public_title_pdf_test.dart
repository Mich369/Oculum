import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';

void main() {
  test('visible title preserves zero Oculum and all awarded points', () {
    for (final grade in [0, 1, 3]) {
      for (final evolved in [false, true]) {
        final bonuses = oculumVisibleTitleStatBonus(
          grade: grade,
          evolvedFirstClaim: evolved,
          includeOculum: false,
        );
        expect(bonuses['oculum'], 0);
        expect(
          bonuses.values.reduce((a, b) => a + b),
          6 * (grade + 1) + (evolved ? 9 : 0),
        );
        expect(bonuses['resilienza'], bonuses['volonta']);
        expect(bonuses['volonta'], bonuses['materia']);
      }
    }
  });
  test(
    'visible title switches exclusively and evolved award cannot be reclaimed',
    () {
      final first = OculumTitle.fromJson({
        'nome': 'Primo',
        'equipaggiato': true,
        'evoluto': true,
      });
      final second = OculumTitle.fromJson({
        'nome': 'Secondo',
        'equipaggiato': true,
        'evoluto': true,
      });
      final normal = OculumTitle.fromJson({
        'nome': 'Normale',
        'equipaggiato': true,
      });
      final titles = [first, second, normal];
      oculumNormalizeAlwaysVisibleTitles(titles, chooseIndex: (_) => 0);
      expect(first.sempreVisibile, true);
      expect(first.evolvedVisibleBonusActive, true);
      expect(oculumTitleCanBeAlwaysVisible(normal, titles), false);
      first.sempreVisibile = false;
      second.sempreVisibile = true;
      second.visibleSelectionManual = true;
      oculumNormalizeAlwaysVisibleTitles(titles);
      expect(first.sempreVisibile, false);
      expect(first.evolvedVisibleBonusActive, false);
      expect(second.evolvedVisibleBonusActive, true);
      first.sempreVisibile = true;
      first.visibleSelectionManual = true;
      second.sempreVisibile = false;
      second.visibleSelectionManual = false;
      oculumNormalizeAlwaysVisibleTitles(titles);
      expect(first.evolvedVisibleBonusActive, false);
      expect(second.evolvedVisibleBonusActive, false);
      final reloaded = titles
          .map((x) => OculumTitle.fromJson(x.toJson()))
          .toList();
      oculumNormalizeAlwaysVisibleTitles(reloaded);
      expect(reloaded.first.evolvedVisibleBonusClaimed, true);
      expect(reloaded.first.evolvedVisibleBonusActive, false);
      expect(reloaded.where((x) => x.sempreVisibile), hasLength(1));
    },
  );

  test(
    'automatic selection prefers primary racial trait then evolved racial titles',
    () {
      final racial = OculumTitle.fromJson({
        'nome': 'Primario',
        'equipaggiato': true,
      });
      final other = OculumTitle.fromJson({
        'nome': 'Altro',
        'equipaggiato': true,
      });
      final titles = [other, racial];
      oculumNormalizeAlwaysVisibleTitles(titles, racialTraits: [racial]);
      expect(racial.sempreVisibile, true);
      other.evoluto = true;
      oculumNormalizeAlwaysVisibleTitles(titles, racialTraits: [racial]);
      expect(other.sempreVisibile, true);
      expect(racial.sempreVisibile, false);
      racial.evoluto = true;
      oculumNormalizeAlwaysVisibleTitles(titles, racialTraits: [racial]);
      expect(racial.sempreVisibile, true);
      expect(other.sempreVisibile, false);
    },
  );

  test('visible title stats scale evenly by character grade', () {
    expect(
      oculumNameWithVisibleTitle('Rose', 'Tutto pur di Salvarla'),
      'Rose | Tutto pur di Salvarla',
    );
    expect(oculumNameWithVisibleTitle('Rose', ''), 'Rose');
    expect(oculumVisibleTitleStatBonus(grade: 0, evolvedFirstClaim: false), {
      'resilienza': 2,
      'volonta': 2,
      'materia': 1,
      'oculum': 1,
    });
    expect(oculumVisibleTitleStatBonus(grade: 1, evolvedFirstClaim: false), {
      'resilienza': 3,
      'volonta': 3,
      'materia': 3,
      'oculum': 3,
    });
    expect(oculumVisibleTitleStatBonus(grade: 0, evolvedFirstClaim: true), {
      'resilienza': 5,
      'volonta': 4,
      'materia': 3,
      'oculum': 3,
    });
  });

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
      state.trattiRazziali.clear();
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
      expect(probe.visibleTitle(), same(evolved));
      expect(probe.visibleTitleBonus('resilienza'), 5);
      final oculumBeforeGrowth = probe.resourceCurrent('oculum');
      state.oculumAddormentato = true;
      probe.increaseBaseStat('oculum', 3);
      expect(probe.resourceCurrent('oculum'), oculumBeforeGrowth + 3);
      state.oculumAddormentato = false;
      for (final key in ['resilienza', 'volonta', 'materia']) {
        final before = probe.resourceCurrent(key);
        probe.increaseBaseStat(key, 2);
        expect(probe.resourceCurrent(key), before + 2, reason: key);
      }
      expect(probe.visibleTitleBonus('volonta'), 4);
      for (final key in ['resilienza', 'volonta', 'materia', 'oculum']) {
        probe.setResourceCurrent(key, 0);
      }
      state.currentHpController.text = '0';
      probe.restoreStatsAndHp();
      for (final key in ['resilienza', 'volonta', 'materia', 'oculum']) {
        expect(
          probe.visibleResourceCurrent(key),
          probe.visibleResourceMaximum(key),
          reason: key,
        );
      }
      expect(int.parse(state.currentHpController.text), probe.maximumHp());
      expect(probe.visibleTitleBonus('resilienza'), 5);
      probe.selectVisibleTitle(normal);
      expect(probe.visibleTitle(), same(evolved));
      final storedResources = {
        for (final key in ['resilienza', 'volonta', 'materia', 'oculum'])
          key: probe.resourceCurrent(key),
      };
      state.cenereController.text = '3';
      probe.changeAsh(1, checkFainting: false);
      expect(probe.fatigueRollPenalty(), -1);
      for (final key in storedResources.keys) {
        expect(probe.resourceCurrent(key), storedResources[key], reason: key);
      }
      expect(
        (state.logEventi as List).any(
          (entry) =>
              entry.toString().contains('Cenere +1: 3 → 4') &&
              entry.toString().contains('0 → -1'),
        ),
        true,
      );
      final dialog = probe.showEnemyCriticalDialog();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Difficoltà nemico'), findsOneWidget);
      expect(find.text('Livello nemico'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Livello nemico'),
        '8',
      );
      await tester.tap(find.text('Annulla'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await dialog;
      expect(evolved.volonta, 5);
      expect(probe.titleBonuses(evolved)['danni'], 26);
      evolved.equipaggiato = false;
      expect(probe.visibleTitle(), same(normal));
      expect(evolved.evolvedVisibleBonusActive, false);
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
