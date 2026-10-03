import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';

void main() {
  test('Legacy turn unit aliases use the same personal duration', () {
    for (final unit in ['turn', 'turns', 'turno', 'turni', 'TURN']) {
      expect(oculumTurnUnit(unit), 'turni');
    }
    expect(oculumTurnUnit('tiri'), 'tiri');
  });
  testWidgets(
    'Per-element saves, inventory integrity, VC, personal turns and timed force states',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final font = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      for (final family in [
        'Poppins',
        'Roboto',
        'Georgia',
        'Segoe UI',
        'serif',
      ]) {
        await (FontLoader(family)..addFont(Future.value(font))).load();
      }
      final icons = File(
        'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
      );
      if (icons.existsSync()) {
        await (FontLoader('MaterialIcons')..addFont(
              Future.value(ByteData.sublistView(icons.readAsBytesSync())),
            ))
            .load();
      }

      final data = Directory(
        'build/current-integrity-${DateTime.now().microsecondsSinceEpoch}',
      )..createSync(recursive: true);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => data.absolute.path,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (_) async => ['none'],
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
        (_) async => null,
      );
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1100);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final capture = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) =>
              RepaintBoundary(key: capture, child: child!),
          home: const OculumHomePage(),
        ),
      );
      final dynamic state = tester.state(find.byType(OculumHomePage));
      state.tutorialDialogPending = true;
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && !state.datiCaricati; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      await tester.pump(const Duration(seconds: 1));
      final probe = OculumPerformanceProbe(state);
      state.updateOculumHomeUi(() {
        state.datiCaricati = true;
        state.tutorialCompletato = true;
        state.modalitaDesktop = true;
        state.activeGameMod = '';
        state.nuovoDesignOculum = 'cattedrale';
        state.statoForzaAttivo = '';
        state.inventario.clear();
        state.arti.clear();
        state.skills.clear();
      });
      final base = {
        ...probe.snapshot(),
        'nome': 'Hoshy',
        'resilienza': '20',
        'volonta': '30',
        'materia': '18',
        'oculum': '24',
        'currentHp': '100',
        'livello': '6',
        'grado': '1',
        'vcRapido': '0',
        'incomingDamageElement': 'fuoco',
        'incomingDamagePresets': {
          'fuoco': 'Immunità',
          'ghiaccio': 'Alta Fragilità',
          'cenere_del_master': 'Rigenerazione',
        },
        'dannoSubitoPercentualePerTipo': {'fulmine': '+30%'},
        'assignableSubtraitPoints': 4,
        'inventario': [
          InventoryItem(
            nome: 'Zanna conservata',
            quantita: 7,
            peso: 1,
            note: 'Materiale',
          ).toJson(),
        ],
        'tutorialSubtraitAllocation': {
          'forza': 3,
          'riflessi': 3,
          'medicina': 3,
        },
      };
      probe.load(base);
      final inventory = probe.snapshot()['inventario'];
      final stats = probe.coreStats();
      final vc = probe.attackVc();
      final damage = probe.outgoingDamage();
      state.vcRapidoController.text = '11';
      state.updateOculumHomeUi(() {});
      expect(probe.attackVc(), vc + 11);
      expect(probe.outgoingDamage(), damage + 11);
      final saved = probe.snapshot();
      expect(saved['vcRapido'], '11');
      probe.load({
        ...probe.snapshot(),
        'nome': 'Elyra',
        'incomingDamagePresets': {},
        'assignableSubtraitPoints': 0,
      });
      expect(state.incomingDamagePresets, isEmpty);
      probe.load(saved);
      expect(probe.snapshot()['inventario'], inventory);
      expect(probe.coreStats(), stats);
      expect(state.incomingDamagePresets['fuoco'], 'Immunità');
      expect(
        state.incomingDamagePresets[oculumNormalizeElementId('ghiaccio')],
        'Alta Fragilità',
      );
      expect(
        state.incomingDamagePresets[oculumNormalizeElementId(
          'cenere_del_master',
        )],
        'Rigenerazione',
      );
      expect(state.assignableSubtraitPoints, 4);
      final hp = probe.currentHp();
      state.dannoOltreDifesa = true;
      state.dannoOltreScudi = true;
      probe.damage(10);
      expect(probe.currentHp(), hp);
      state.incomingDamageElement = 'ghiaccio';
      probe.damage(10);
      expect(probe.currentHp(), lessThan(hp));
      // The legacy armor effect used singular English "turn" and never expired.
      state.activeStructuredEffects.add({
        'source': 'Armatura del Combattente',
        'type': 'bonus',
        'target': 'danni',
        'value': 36,
        'remaining': 2,
        'unit': 'turn',
      });
      final tag = probe.ownerTag();
      state.masterInitiativeTokens.clear();
      state.masterInitiativeTokens.addAll([
        {
          'id': tag,
          'sheetTag': tag,
          'name': 'Hoshy',
          'status': 'active',
          'reportedTurn': 0,
          'hp': 100,
          'maxHp': 100,
        },
        {
          'id': 'other',
          'sheetTag': 'other',
          'name': 'Forest Demon',
          'status': 'ready',
          'reportedTurn': 0,
          'hp': 100,
          'maxHp': 100,
        },
      ]);
      state.masterInitiativeActiveIndex = 0;
      state.masterInitiativeRound = 0;
      probe.turn();
      expect(state.playerReportedTurn, 1);
      expect(
        state.activeStructuredEffects.singleWhere(
          (e) => e['source'] == 'Armatura del Combattente',
        )['remaining'],
        1,
      );
      probe.turn();
      expect(state.playerReportedTurn, 1);
      probe.turn();
      expect(state.playerReportedTurn, 2);
      expect(
        state.activeStructuredEffects.where(
          (e) => e['source'] == 'Armatura del Combattente',
        ),
        isEmpty,
      );
      probe.resetEncounter();
      expect(state.masterInitiativeRound, 0);
      expect(state.playerReportedTurn, 0);
      expect(
        state.masterInitiativeTokens.every(
          (token) => token['reportedTurn'] == 0,
        ),
        isTrue,
      );
      probe.removeParticipant(1);
      expect(state.masterInitiativeTokens.length, 1);
      expect(probe.snapshot()['inventario'], inventory);
      final before200 = probe.coreStats();
      probe.activateForce('duecento_percento');
      expect(
        probe.coreStats(),
        before200.map((key, value) => MapEntry(key, value * 2)),
      );
      probe.reportedTurn(1);
      probe.reportedTurn(2);
      expect(state.statoForzaAttivo, 'duecento_percento');
      probe.reportedTurn(3);
      expect(probe.coreStats(), before200);
      expect(state.statoForzaAttivo, '');
      state.currentHpController.text = '1';
      probe.activateForce('ricordo_vitale');
      final healed = probe.currentHp();
      expect(healed, greaterThan(1));
      expect(
        state.activeConditions.any((c) => c.conditionType == 'ricordo_vitale'),
        isTrue,
      );
      final current = state.playerReportedTurn as int;
      probe.reportedTurn(current + 8);
      expect(state.statoForzaAttivo, 'ricordo_vitale');
      probe.reportedTurn(current + 9);
      expect(state.statoForzaAttivo, '');
      expect(probe.currentHp(), greaterThanOrEqualTo(1));
      expect(probe.currentHp(), healed);
      // A buff expiring must not revive an already dead character.
      state.currentHpController.text = '0';
      probe.activateForce('duecento_percento');
      probe.endForce();
      expect(probe.currentHp(), 0);
      state.currentHpController.text = '1';
      probe.activateForce('duecento_percento');
      probe.endForce();
      expect(probe.currentHp(), 1);
      probe.loseResilienceBuff(999);
      expect(probe.currentHp(), 1);
      expect(probe.snapshot()['inventario'], inventory);
      probe.load(base);
      await tester.pump(const Duration(milliseconds: 600));
      Future<void> photo(String name) async {
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('output/ui/resistances-turns-20261003')
            ..createSync(recursive: true);
          File(
            '${dir.path}/$name.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      state.updateOculumHomeUi(() => state.referenceOculumFlames = true);
      await photo('fiammelle-desktop');
      probe.openResistances();
      await photo('resistenze-desktop');
      tester.view.physicalSize = const Size(390, 844);
      await photo('resistenze-mobile');
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pump(const Duration(milliseconds: 600));
      probe.openSubtraits();
      await photo('sottotratti-mobile');
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pump(const Duration(milliseconds: 600));
      tester.view.physicalSize = const Size(1440, 1100);
      probe.openDice();
      await photo('dadi-desktop');
      expect(find.text('d15'), findsOneWidget);
      expect(find.text('d25'), findsOneWidget);
      expect(find.text('d200'), findsOneWidget);
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox());
    },
  );
}
