import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:oculum/widgets/oculum_hex_color_field.dart';

import 'oculum_theme_effects_portrait_test.dart' as fixtures;

class _PlayerMarketTransport extends OculumRealtimeService {
  _PlayerMarketTransport()
    : super(
        roomId: 'market-ui',
        playerName: 'Giocatore',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = 'player';
  }

  final requests = <Map<String, dynamic>>[];
  int pings = 0;

  Iterable<Map<String, dynamic>> get profileRequests => requests.where(
    (event) =>
        event['event'] == 'permission_request' &&
        event['action'] == 'personal_market' &&
        event['operation'] == 'profile',
  );

  @override
  bool get isConnected => true;

  @override
  String get authenticatedUserId => 'market-player';

  @override
  Future<void> sendPing() async {
    pings++;
  }

  @override
  Future<bool> sendPermissionEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    requests.add({'event': event, ...payload});
    return true;
  }
}

Future<void> _drawDialogs(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('market opens a player shop and sends the owner profile ping', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(392, 850),
    );
    final probe = OculumPerformanceProbe(state);
    var loaded = false;
    probe.initialSheetLoad().then((_) => loaded = true);
    for (var attempt = 0; attempt < 80 && !loaded; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
    }
    expect(loaded, isTrue, reason: 'Finish startup before seeding the market.');
    probe.cancelPendingSave();
    // Exercise the existing preferences fallback without redirecting the
    // progress and other storage paths used by this test fixture.
    final unavailable = Future<Directory>.error(
      const FileSystemException('Use the preferences save fallback in the market widget test.'),
    );
    unavailable.ignore();
    state.saveBlobDirectoryFuture = unavailable;
    state.updateOculumHomeUi(() {
      state.schedePersonaggio
        ..clear()
        ..add(<String, dynamic>{'nome': 'Giocatore del mercato'});
      state.schedaCorrente = 0;
      state.nomeController.text = 'Giocatore del mercato';
      state.activeCampaignId = 'market-ui-campaign';
    });
    probe.ensureSheetTags();
    final ownerTag = probe.ownerTag();
    expect(ownerTag, isNot(anyOf(isEmpty, '---')));
    expect(state.schedePersonaggio[state.schedaCorrente]['sheetTag'], ownerTag);
    expect(state.datiCaricati, isTrue);
    final transport = _PlayerMarketTransport();
    state.updateOculumHomeUi(() {
      state.modalitaMaster = true;
      state.linguaInglese = false;
      state.realtimeService = transport;
      state.realtimeUsers.addAll(<Map<String, dynamic>>[
        {
          'role': 'player',
          'activeSheetTag': 'PUBLICPEER',
          'playerName': 'Esploratore',
        },
        {
          'role': 'master',
          'activeSheetTag': 'PRIVATEMASTER',
          'playerName': 'Custode',
          'campaignId': 'market-ui-campaign',
        },
      ]);
    });
    final opening = showDialog<void>(
      context: state.context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: SizedBox(width: 392, height: 750, child: probe.inventory()),
      ),
    );
    await _drawDialogs(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Mercato'));
    await _drawDialogs(tester);

    expect(
      find.byKey(const ValueKey('online_market_self_sphere')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('online_market_sphere_PRIVATEMASTER')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('online_market_sales')), findsNothing);
    expect(find.text('Mercato personale del Master'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('online_market_sphere_PUBLICPEER')),
    );
    await _drawDialogs(tester);
    expect(find.text('Negozio di Esploratore'), findsOneWidget);
    expect(find.byKey(const ValueKey('online_market_list_item')), findsNothing);
    Navigator.pop(state.context);
    await _drawDialogs(tester);

    await tester.runAsync(
      () => tester.tap(find.byKey(const ValueKey('online_market_self_sphere'))),
    );
    await _drawDialogs(tester);
    expect(
      find.text('Il ping aggiorna il nome mostrato Online.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('online_market_profile_name')),
      'Nox delle Maree',
    );
    await tester.tap(
      find.byKey(const ValueKey('online_market_profile_colour')),
    );
    await _drawDialogs(tester);
    final hex = find.descendant(
      of: find.byType(OculumHexColorField),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(hex);
    await tester.enterText(hex, '#3388DD');
    await tester.tap(find.byTooltip('Applica colore HEX'));
    await tester.pump();
    await tester.tap(find.text('Usa colore'));
    await _drawDialogs(tester);
    expect(find.text('Colore RGB / HEX · #3388DD'), findsOneWidget);

    final ping = find.byKey(const ValueKey('online_market_profile_ping'));
    expect(tester.widget<OutlinedButton>(ping).onPressed, isNotNull);
    await tester.ensureVisible(ping);
    await tester.tap(ping);
    await _drawDialogs(tester);
    // This dialog's asynchronous save and transport use the real file I/O zone.
    for (var attempt = 0; attempt < 75; attempt++) {
      if (transport.profileRequests.isNotEmpty && transport.pings > 0) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 25));
    }
    await _drawDialogs(tester);
    expect(state.realtimeNameController.text, 'Nox delle Maree');
    expect(
      transport.profileRequests,
      hasLength(1),
      reason:
          'The profile request follows its verified local save. '
          'Pending: ${state.personalMarketPending.length}, '
          'save revision: ${state.salvataggioRevisione}, '
          'save error: ${state.ultimoErroreCaricamentoSalvataggio}.',
    );
    final request = transport.profileRequests.single;
    final id = request['id'] as String;
    expect(request['requesterTag'], ownerTag.toUpperCase());
    expect(request['name'], 'Nox delle Maree');
    expect(request['argb'], 0xff3388dd);
    final raw = state.ultimoRawSalvataggioConfermato as String?;
    expect(raw, isNotNull);
    final saved = jsonDecode(raw!) as Map<String, dynamic>;
    expect(saved['personalMarketPending'][id]['status'], 'pending');
    expect(saved['personalMarketPending'][id]['name'], 'Nox delle Maree');
    expect(saved['personalMarketPending'][id]['argb'], 0xff3388dd);
    expect(transport.pings, 1);
    expect(tester.takeException(), isNull);

    Navigator.pop(state.context);
    await _drawDialogs(tester);
    Navigator.pop(state.context);
    await _drawDialogs(tester);
    await opening;
    state.realtimeService = null;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
