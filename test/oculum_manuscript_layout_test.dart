import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/hero_path_page.dart';
import 'support/test_output_writer.dart';

void main() {
  const captureLabel = String.fromEnvironment('OculumBenchmarkLabel');
  final capturePath = captureLabel.isEmpty
      ? 'output/ui'
      : 'output/ui/${captureLabel.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Manuscript real screen fits desktop, short windows and phone',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final regular = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      for (final family in [
        'Poppins',
        'Roboto',
        'serif',
        'Segoe UI',
        'Garamond',
        'Georgia',
      ]) {
        await (FontLoader(family)..addFont(Future.value(regular))).load();
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
      final directory = Directory(
        'build/layout-test-data-${DateTime.now().microsecondsSinceEpoch}',
      )..createSync(recursive: true);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => directory.absolute.path,
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
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final capture = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          builder: (context, child) =>
              RepaintBoundary(key: capture, child: child!),
          home: const OculumHomePage(),
        ),
      );
      final dynamic bootState = tester.state(find.byType(OculumHomePage));
      bootState.tutorialDialogPending = true;
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && !bootState.datiCaricati; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      await tester.pump(const Duration(seconds: 1));
      final dynamic state = tester.state(find.byType(OculumHomePage));
      expect(
        state.modalitaDesktop,
        defaultTargetPlatform == TargetPlatform.windows,
      );
      final portrait = base64Encode(
        (await rootBundle.load(
          'assets/icon/oculum_eye.png',
        )).buffer.asUint8List(),
      );
      state.updateOculumHomeUi(() {
        state.activeGameMod = 'manuscript_living';
        state.modalitaDesktop = true;
        state.tutorialCompletato = true;
        state.datiCaricati = true;
        state.nomeController.text = 'Viandante del Bosco';
        state.schedePersonaggio.addAll(
          List<Map<String, dynamic>>.generate(
            10,
            (i) => {
              'id': 'visual_test_$i',
              'nome': i == 0 ? 'Viandante del Bosco' : 'Custode ${i + 1}',
              'tipoScheda': 'Personaggio',
              'immagine': portrait,
              'resilienza': '10',
              'volonta': '20',
              'materia': '18',
              'oculum': '30',
              'currentHp': '100',
            },
          ),
        );
      });
      for (final size in [
        const Size(1440, 900),
        const Size(1100, 600),
        const Size(390, 844),
      ]) {
        tester.view.physicalSize = size;
        await tester.pump(const Duration(milliseconds: 400));
        await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull, reason: '$size');
        await tester.runAsync(() async {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final picture = await boundary.toImage(pixelRatio: 1);
          final bytes = await picture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          final out = Directory(capturePath)..createSync(recursive: true);
          writeTestOutputBytes(
            File(
              '${out.path}/manuscript-${defaultTargetPlatform.name}-${size.width.toInt()}.png',
            ),
            bytes!.buffer.asUint8List(),
          );
          picture.dispose();
        });
        if (size.width >= 760) {
          expect(find.text('Attacco · VC'), findsOneWidget);
          final heroPathButton = find.byKey(
            const ValueKey('desktop_hero_path'),
          );
          expect(heroPathButton, findsOneWidget);
          await tester.tap(heroPathButton);
          await tester.pumpAndSettle();
          expect(find.byType(HeroPathPage), findsOneWidget);
          expect(find.text('Nome'), findsOneWidget);
          expect(tester.takeException(), isNull);
          Navigator.of(tester.element(find.byType(HeroPathPage))).pop();
          await tester.pumpAndSettle();
        }
        expect(find.textContaining('Closure:'), findsNothing);
      }
      await tester.tap(find.text('TURNO E DADI'));
      await tester.pumpAndSettle();
      expect(find.text('DADI RAPIDI'), findsOneWidget);
      expect(tester.takeException(), isNull);
      state.updateOculumHomeUi(() {
        state.activeGameMod = '';
        state.modalitaDesktop = false;
        state.immaginePersonaggio = base64Decode(portrait);
      });
      for (final size in [
        const Size(1440, 900),
        const Size(390, 844),
        const Size(320, 640),
      ]) {
        tester.view.physicalSize = size;
        state.updateOculumHomeUi(() {
          state.modalitaDesktop = size.width >= 700;
          state.desktopSideMenuOpen = true;
        });
        await tester.pump(const Duration(milliseconds: 400));
        await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Classic $size');
        expect(find.text('Modifica'), findsWidgets);
        await tester.runAsync(() async {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final picture = await boundary.toImage(pixelRatio: 1);
          final bytes = await picture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          writeTestOutputBytes(
            File(
              '$capturePath/classic-${defaultTargetPlatform.name}-${size.width.toInt()}.png',
            ),
            bytes!.buffer.asUint8List(),
          );
          picture.dispose();
        });
      }
      tester.view.physicalSize = const Size(1440, 900);
      for (final sample in <(String, int, String)>[
        ('resources', 7, 'Personaggio'),
        ('rest', 1, 'Personaggio'),
        ('home', 17, 'Personaggio'),
        ('statistics', 0, 'Personaggio'),
        ('npc', 0, 'NPC'),
        ('monster', 0, 'Mostro'),
        ('miniboss', 0, 'Mostro Mini Boss'),
        ('boss', 0, 'Mostro Boss'),
      ]) {
        state.updateOculumHomeUi(() {
          state.modalitaDesktop = true;
          state.desktopSideMenuOpen = true;
          state.paginaCorrente = sample.$2;
          state.schedePersonaggio[state.schedaCorrente]['tipoScheda'] =
              sample.$3;
          state.referenceSheetSection = sample.$1 == 'statistics'
              ? 'statistics'
              : 'general';
        });
        await tester.pump(const Duration(milliseconds: 500));
        await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: sample.$1);
        expect(find.text('Preparazione rapida della sezione...'), findsNothing);
        await tester.runAsync(() async {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final picture = await boundary.toImage(pixelRatio: 1);
          final bytes = await picture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          writeTestOutputBytes(
            File(
              '$capturePath/reference-${sample.$1}-${defaultTargetPlatform.name}.png',
            ),
            bytes!.buffer.asUint8List(),
          );
          picture.dispose();
        });
      }
      // Capture the compact menu directly beneath the actual roll/action controls.
      await tester.ensureVisible(find.text('Turnistica').last);
      await tester.pumpAndSettle();
      expect(find.text('Prova di gruppo'), findsNothing);
      await tester.runAsync(() async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final picture = await boundary.toImage(pixelRatio: 1);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        writeTestOutputBytes(
          File(
            '$capturePath/reference-actions-${defaultTargetPlatform.name}.png',
          ),
          bytes!.buffer.asUint8List(),
        );
        picture.dispose();
      });
      state.updateOculumHomeUi(() {
        state.schedePersonaggio[state.schedaCorrente]['tipoScheda'] =
            'Personaggio';
        state.referenceSheetSection = 'general';
        state.modalitaDesktop = false;
      });
      tester.view.physicalSize = const Size(320, 640);
      await tester.pump(const Duration(milliseconds: 400));
      final turnMenu = find.text('Turnistica').last;
      await Scrollable.ensureVisible(
        tester.element(find.text('Tiri e azioni').first),
        alignment: 0,
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final picture = await boundary.toImage(pixelRatio: 1);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        writeTestOutputBytes(
          File(
            '$capturePath/reference-actions-phone-${defaultTargetPlatform.name}.png',
          ),
          bytes!.buffer.asUint8List(),
        );
        picture.dispose();
      });
      await tester.ensureVisible(turnMenu);
      await tester.tap(turnMenu);
      await tester.pumpAndSettle();
      expect(find.byType(ExpansionTile), findsNWidgets(5));
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Aggiungi PG / NPC / mostro').first);
      await tester.tap(find.text('Aggiungi PG / NPC / mostro').first);
      await tester.pumpAndSettle();
      expect(find.text('Aggiungi da scheda'), findsOneWidget);
      await tester.tap(find.text('Aggiungi').last);
      await tester.pumpAndSettle();
      expect(state.masterInitiativeTokens, isNotEmpty);
      expect(tester.takeException(), isNull);
      state.updateOculumHomeUi(() {
        state.masterInitiativeTokens.first['currentHp'] = 100;
        state.masterInitiativeTokens.first['maxHp'] = 100;
        state.masterInitiativeTokens.first['downed'] = false;
        state.masterInitiativeTokens.first['status'] = 'ready';
        state.masterInitiativeTokens.add({
          'id': 'turn_ui_fixture',
          'name': 'Sentinella dei turni',
          'type': 'NPC',
          'currentHp': 100,
          'maxHp': 100,
          'status': 'ready',
          'downed': false,
        });
        state.masterInitiativeRound = 0;
      });
      OculumPerformanceProbe(state).activateInitiative(0);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Gestisci turni').first);
      await tester.tap(find.text('Gestisci turni').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Gestione dello scontro').first);
      await tester.tap(find.text('Gestione dello scontro').first);
      await tester.pumpAndSettle();
      final nextTurn = find.textContaining(RegExp(r'^(Prossimo|Prox)$')).first;
      await tester.ensureVisible(nextTurn);
      await tester.tap(nextTurn);
      await tester.pumpAndSettle();
      expect(state.masterInitiativeActiveIndex, 1);
      expect(find.text('Turno attivo: Sentinella dei turni'), findsOneWidget);
      await tester.tap(nextTurn);
      await tester.pumpAndSettle();
      expect(state.masterInitiativeRound, 1);
      expect(find.text('Iniziativa Master - Round 1'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Turn detail refresh');
      for (final width in [320.0]) {
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Turn detail $width');
        await tester.runAsync(() async {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final picture = await boundary.toImage(pixelRatio: 1);
          final bytes = await picture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          writeTestOutputBytes(
            File(
              '$capturePath/turn-order-${defaultTargetPlatform.name}-${width.toInt()}.png',
            ),
            bytes!.buffer.asUint8List(),
          );
          picture.dispose();
        });
      }
      Navigator.of(
        tester.element(find.textContaining(RegExp(r'^(Prossimo|Prox)$')).first),
      ).pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('Turnistiche').first)).pop();
      await tester.pumpAndSettle();
      // The reference layout must still open the actual identity editor and
      // reveal its anchor rather than presenting a decorative edit button.
      await tester.ensureVisible(find.text('Modifica').first);
      await tester.tap(find.text('Modifica').first);
      await tester.pumpAndSettle();
      expect(find.text('Identità scheda'), findsWidgets);
      expect(find.text('Difficoltà'), findsWidgets);
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.text('Identità scheda').first)).pop();
      await tester.pumpAndSettle();
      final combatDetails = find.text('Attacco, difesa e bonus');
      await tester.ensureVisible(combatDetails.first);
      await tester.tap(combatDetails.first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Danni inflitti:'), findsWidgets);
      expect(find.text('Movimento'), findsWidgets);
      expect(find.text('Iniziativa'), findsWidgets);
      expect(find.text('Bonus danno'), findsWidgets);
      expect(tester.takeException(), isNull);
      Navigator.of(
        tester.element(find.textContaining('Danni inflitti:').first),
      ).pop();
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(1440, 900);
      state.updateOculumHomeUi(() => state.modalitaDesktop = true);
      await tester.pump(const Duration(milliseconds: 500));
      final healthDetails = find.text('Vita, scudi e condizioni').first;
      await tester.ensureVisible(healthDetails);
      await tester.tap(healthDetails);
      await tester.pumpAndSettle();
      expect(find.text('HP Attuali'), findsWidgets);
      expect(find.text('Mostra barra vita'), findsOneWidget);
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.text('Mostra barra vita'))).pop();
      await tester.pumpAndSettle();
      final portraitDetails = find.text('Ritratto e Occhio');
      await tester.ensureVisible(portraitDetails.first);
      await tester.tap(portraitDetails.first);
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(find.byKey(const ValueKey('reference_portrait_preview')))
            .width,
        lessThanOrEqualTo(390),
      );
      final transparentPortrait = await rootBundle.load(
        'assets/oculum/icons/oculum_npc_eye.png',
      );
      state.updateOculumHomeUi(
        () => state.immaginePersonaggio = transparentPortrait.buffer
            .asUint8List(),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text('Mantieni l’occhio dietro il ritratto'),
      );
      await tester.tap(find.text('Mantieni l’occhio dietro il ritratto'));
      await tester.pumpAndSettle();
      expect(state.portraitShowEyeBehind, isFalse);
      await tester.ensureVisible(
        find.byKey(const ValueKey('portrait_eye_choice_')),
      );
      await tester.tap(find.byKey(const ValueKey('portrait_eye_choice_')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Occhio dei morti').last);
      await tester.pumpAndSettle();
      expect(state.portraitEyeRole, 'dead');
      final portraitSnapshot = OculumPerformanceProbe(state).snapshot();
      expect(portraitSnapshot['portraitEyeRole'], 'dead');
      expect(portraitSnapshot['portraitShowEyeBehind'], isFalse);
      for (final width in [1440.0, 390.0]) {
        tester.view.physicalSize = Size(width, width > 700 ? 900 : 844);
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          writeTestOutputBytes(
            File(
              '$capturePath/portrait-eye-${defaultTargetPlatform.name}-${width.toInt()}.png',
            ),
            bytes!.buffer.asUint8List(),
          );
          image.dispose();
        });
      }
      expect(
        tester.takeException(),
        isNull,
        reason: 'Transparent portrait settings',
      );
      expect(tester.takeException(), isNull);
      Navigator.of(
        tester.element(
          find.byKey(const ValueKey('reference_portrait_preview')),
        ),
      ).pop();
      await tester.pumpAndSettle();
      state.updateOculumHomeUi(() {
        state.portraitEyeRole = '';
        state.portraitShowEyeBehind = true;
      });
      OculumPerformanceProbe(state).load(portraitSnapshot);
      expect(state.portraitEyeRole, 'dead');
      expect(state.portraitShowEyeBehind, isFalse);
      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpAndSettle();
      Future<void> keyboardSearch(String query) async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        expect(find.text('Cerca funzioni'), findsOneWidget);
        await tester.enterText(
          find
              .descendant(
                of: find.byType(AlertDialog),
                matching: find.byType(TextField),
              )
              .first,
          query,
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find
              .descendant(
                of: find.byType(AlertDialog),
                matching: find.text(query),
              )
              .last,
        );
        await tester.pumpAndSettle();
      }

      await keyboardSearch('Sottotratti');
      expect(state.referenceDetailRouteActive, isTrue);
      await keyboardSearch('Turnistica');
      expect(find.byType(ExpansionTile), findsNWidgets(5));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(state.referenceSheetSection, 'general');
      expect(state.referenceDetailRouteActive, isFalse);
      await tester.ensureVisible(find.text('Attacco, difesa e bonus').first);
      await tester.tap(find.text('Attacco, difesa e bonus').first);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(4, 200));
      await tester.pumpAndSettle();
      expect(state.referenceDetailRouteActive, isFalse);
      tester.view.physicalSize = const Size(320, 640);
      state.updateOculumHomeUi(() => state.modalitaDesktop = false);
      state.updateOculumHomeUi(() {
        state.paginaCorrente = 16;
        state.occhiCaduti.addAll(
          List<Map<String, dynamic>>.generate(
            3,
            (i) => {
              'id': 'eye_$i',
              'ownerSheetId':
                  state.schedePersonaggio[state.schedaCorrente]['sheetTag'],
              'name': 'Custode $i',
              'rarity': 'non_comune',
              'active': false,
              'originalArts': [],
              'activeArts': [],
              'sheetData': <String, dynamic>{
                'nome': 'Custode $i',
                'resilienza': '10',
                'currentHp': '100',
              },
              'integrityCurrent': 35,
              'integrityMax': 35,
            },
          ),
        );
      });
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: 'Fallen Eyes mobile');
      expect(find.textContaining('OCCHI DEI CADUTI'), findsOneWidget);
      for (final width in [1440.0, 320.0]) {
        tester.view.physicalSize = Size(width, width > 700 ? 900 : 640);
        state.updateOculumHomeUi(() => state.modalitaDesktop = width > 700);
        OculumPerformanceProbe(state).showTutorial();
        await tester.pumpAndSettle();
        expect(find.text('Rito di Creazione'), findsOneWidget);
        expect(find.text('Come giocare con questa scheda'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Tutorial $width');
        await tester.runAsync(() async {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final picture = await boundary.toImage(pixelRatio: 1);
          final bytes = await picture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          writeTestOutputBytes(
            File(
              '$capturePath/tutorial-${defaultTargetPlatform.name}-${width.toInt()}.png',
            ),
            bytes!.buffer.asUint8List(),
          );
          picture.dispose();
        });
        await tester.tap(find.text('Skippa'));
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
    variant: TargetPlatformVariant({
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.android,
    }),
  );
}
