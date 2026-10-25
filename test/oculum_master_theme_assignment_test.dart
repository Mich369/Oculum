import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:oculum/widgets/oculum_theme_relic.dart';

import 'oculum_theme_effects_portrait_test.dart' as fixtures;

class _ThemeAssignmentService extends OculumRealtimeService {
  _ThemeAssignmentService()
    : super(
        roomId: 'theme_assignment',
        playerName: 'Master',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      );

  final sent = <Map<String, dynamic>>[];

  @override
  bool get isConnected => true;

  @override
  Future<bool> sendSharedSheetConfirmed({
    required Map<String, dynamic> sheet,
    required String campaignId,
    required String campaignName,
    required String sheetId,
    required String sheetName,
    required String ownerTag,
    required String senderRole,
    required String targetAudience,
    required bool fromMaster,
    required bool masterParty,
    List<String> targetTags = const [],
    List<String> allowClearFields = const [],
    String deliveryId = '',
  }) async {
    sent.add({
      'sheet': jsonDecode(jsonEncode(sheet)),
      'campaignId': campaignId,
      'sheetId': sheetId,
      'senderRole': senderRole,
      'targetAudience': targetAudience,
      'fromMaster': fromMaster,
      'targetTags': targetTags,
    });
    return true;
  }
}

OculumMonsterTheme _nuvi(int color) {
  final monster = monsterBookEntryById('nuvi')!;
  return OculumMonsterTheme(monster, oculumMonsterColors(monster)[color]);
}

Future<dynamic> _mountSheet(WidgetTester tester, Size size) async {
  final dynamic state = await fixtures.mountSheet(tester, size);
  if (state.schedePersonaggio.isEmpty) {
    final sheet = OculumPerformanceProbe(state).snapshot()
      ..['id'] = 'RecipientOcu:3690AAAA'
      ..['sheetTag'] = 'RecipientOcu:3690AAAA'
      ..['nome'] = 'Destinataria';
    state.schedePersonaggio.add(sheet);
    state.schedaCorrente = 0;
    OculumPerformanceProbe(state).load(sheet);
    await tester.pump();
  }
  return state;
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUp(() {
    oculumMonsterThemeUnlocks.value = {};
    oculumSheetRelicSelections.value = {};
    oculumSheetMonsterThemes.value = {};
  });
  tearDown(() {
    oculumMonsterThemeUnlocks.value = {};
    oculumSheetRelicSelections.value = {};
    oculumSheetMonsterThemes.value = {};
  });

  testWidgets(
    'Master access is temporary; exact assignments survive JSON only on their sheet',
    (tester) async {
      final dynamic state = await _mountSheet(tester, const Size(1440, 1000));
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.modalitaMaster = false;
      state.isMasterHost = false;
      state.sonoCoMaster = false;
      final first = _nuvi(0).id;
      final second = _nuvi(1).id;
      final tag =
          '${state.schedePersonaggio[state.schedaCorrente]['sheetTag']}';
      expect(probe.masterThemeAccess, isFalse);
      final secretAccessBefore = probe.colorThemeAvailable('hoshy_cosmic_cat');
      expect(await probe.selectSheetRelic(first), isFalse);
      state.modalitaMaster = true;
      expect(probe.masterThemeAccess, isTrue);
      expect(probe.colorThemeAvailable('hoshy_cosmic_cat'), isTrue);
      expect(await probe.selectSheetRelic(first), isTrue);
      final saved =
          jsonDecode(jsonEncode(probe.snapshot())) as Map<String, dynamic>;
      expect(saved['masterAssignedThemeIds'], [first]);
      expect(saved['relicArtPackId'], first);
      expect(oculumMonsterThemeUnlocks.value, isEmpty);
      expect(probe.creatureKnowledge('nuvi'), isNull);
      state.modalitaMaster = false;
      probe.load(saved);
      expect(probe.masterThemeAccess, isFalse);
      expect(probe.colorThemeAvailable('hoshy_cosmic_cat'), secretAccessBefore);
      expect(await probe.selectSheetRelic(second), isFalse);
      expect(await probe.selectSheetRelic(''), isTrue);
      expect(probe.snapshot()['masterAssignedThemeIds'], [first]);
      expect(await probe.selectSheetRelic(first), isTrue);
      probe.saveSheet();
      final assignedSheet = Map<String, dynamic>.from(
        state.schedePersonaggio[state.schedaCorrente] as Map,
      );
      final other = <String, dynamic>{
        ...saved,
        'sheetTag': 'OtherOcu:3690AAAA',
        'id': 'OtherOcu:3690AAAA',
        'masterAssignedThemeIds': <String>[],
        'relicArtPackId': '',
      };
      state.schedePersonaggio.add(other);
      state.schedaCorrente = state.schedePersonaggio.length - 1;
      probe.load(other);
      expect(probe.snapshot()['masterAssignedThemeIds'], isEmpty);
      expect(await probe.selectSheetRelic(first), isFalse);
      expect(oculumThemePresentationForSheet(tag).artPackId, first);
      expect(
        oculumThemePresentationForSheet('OtherOcu:3690AAAA').artPackId,
        isNot(first),
      );
      expect(assignedSheet['masterAssignedThemeIds'], [first]);
      await _unmount(tester);
    },
  );

  testWidgets(
    'online authenticated role overrides the local Master switch and assignment targets owner',
    (tester) async {
      final dynamic state = await _mountSheet(tester, const Size(1440, 1000));
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.modalitaMaster = true;
      final service = _ThemeAssignmentService()..authenticatedRole = 'player';
      state.realtimeService = service;
      expect(probe.masterThemeAccess, isFalse);
      expect(await probe.selectSheetRelic(_nuvi(0).id), isFalse);
      service.authenticatedRole = 'coMaster';
      expect(probe.masterThemeAccess, isFalse);
      service.authenticatedRole = 'master';
      expect(probe.masterThemeAccess, isTrue);
      final sheet = state.schedePersonaggio[state.schedaCorrente] as Map;
      final tag = '${sheet['sheetTag']}';
      sheet.addAll(<String, dynamic>{
        'realtimeSharedSheet': true,
        'realtimeSourceSheetTag': tag,
        'realtimeOwnerTag': tag,
        'realtimeCampaignId': state.activeCampaignId,
        'realtimeSourceKey': 'recipient',
      });
      state.realtimeSharedSheets.add({
        'key': 'recipient',
        'sheet': jsonDecode(jsonEncode(probe.snapshot())),
      });
      expect(await probe.selectSheetRelic(_nuvi(0).id), isTrue);
      final message = service.sent.single;
      expect(message['senderRole'], 'sheetEdit');
      expect(message['targetAudience'], 'owner');
      expect(message['targetTags'], [tag]);
      expect(message['fromMaster'], isTrue);
      expect(message['campaignId'], state.activeCampaignId);
      final patch = Map<String, dynamic>.from(message['sheet'] as Map);
      expect(patch['masterAssignedThemeIds'], [_nuvi(0).id]);
      expect(patch['relicArtPackId'], _nuvi(0).id);
      final merged = oculumRealtimeMergeSheetPatch({
        'skills': [
          {'nome': 'Personalizzata', 'costo': '@vol-3'},
        ],
        'immaginePersonaggioBase64': 'keep-portrait',
      }, patch);
      expect(merged['skills'], [
        {'nome': 'Personalizzata', 'costo': '@vol-3'},
      ]);
      expect(merged['immaginePersonaggioBase64'], 'keep-portrait');
      expect(oculumMonsterThemeUnlocks.value, isEmpty);
      sheet['realtimeReadOnlyByMaster'] = true;
      // The sheet may have been replaced during saving; mark the current copy.
      state.schedePersonaggio[state
              .schedaCorrente]['realtimeReadOnlyByMaster'] =
          true;
      expect(await probe.selectSheetRelic(_nuvi(1).id), isFalse);
      state.realtimeService = null;
      await _unmount(tester);
    },
  );

  for (final size in [const Size(1440, 1000), const Size(390, 844)]) {
    testWidgets('Master assigns through the real picker at $size', (
      tester,
    ) async {
      final dynamic state = await _mountSheet(tester, size);
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.modalitaMaster = true;
      final operation = probe.chooseSheetRelic();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Assegna tema e sfondo'), findsOneWidget);
      expect(find.textContaining('catalogo completo Master'), findsOneWidget);
      final search = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(search, 'Nuvì');
      await tester.pump();
      expect(find.text(_nuvi(0).name), findsOneWidget);
      await tester.tap(find.text(_nuvi(0).name));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await operation;
      expect(probe.snapshot()['masterAssignedThemeIds'], [_nuvi(0).id]);
      expect(probe.snapshot()['relicArtPackId'], _nuvi(0).id);
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    });
  }

  testWidgets(
    'an open privileged picker cannot grant a locked theme after role loss',
    (tester) async {
      var master = true;
      var selected = '';
      late BuildContext pickerContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                pickerContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      final operation = showOculumRelicPicker(
        pickerContext,
        sheetId: 'role-test',
        canManageAll: () => master,
        onSelected: (id) async => selected = id,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField), 'Nuvì');
      await tester.pump();
      master = false;
      await tester.tap(find.text(_nuvi(0).name));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await operation;
      expect(selected, isEmpty);
      expect(oculumSheetRelicSelections.value, isEmpty);
      expect(
        find.text('Tema non disponibile con il ruolo attuale.'),
        findsOneWidget,
      );
      await _unmount(tester);
    },
  );
}
