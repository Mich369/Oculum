import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oculum/services/oculum_campaign_directory.dart';
import 'package:oculum/services/oculum_campaign_directory_ui.dart';

final _refresh = find.byKey(const ValueKey('campaign-directory-refresh'));

OculumSharedCampaign _share({
  String ownerName = 'Master Ombra',
  String roomCode = 'approved-code',
}) => OculumSharedCampaign(
  roomId: 'room-stable-id',
  roomCode: roomCode,
  ownerId: 'master-stable-id',
  ownerName: ownerName,
  campaignId: 'shared-stable-id',
  campaignName: 'Foresta lunare',
);

Future<void> _mount(
  WidgetTester tester,
  ValueNotifier<String?> account,
  Future<OculumCampaignDirectory> Function(String) load, {
  Future<void> Function(String, OculumSharedCampaign)? openShared,
  Future<void> Function(String, OculumOtherDeviceCampaign)? openOwn,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Text('Campagna locale sempre disponibile'),
            OculumCampaignDirectoryPanel(
              accountChanges: account,
              currentAccountId: () => account.value,
              load: load,
              openOwn: openOwn ?? (_, _) async {},
              openShared: openShared ?? (_, _) async {},
              english: false,
              accent: Colors.deepOrange,
            ),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('guest has no access and sends no directory request', (
    tester,
  ) async {
    final account = ValueNotifier<String?>(null);
    var calls = 0;
    await _mount(tester, account, (_) async {
      calls++;
      return OculumCampaignDirectory(shared: [_share()]);
    });
    expect(calls, 0);
    expect(find.text('Master Ombra'), findsNothing);
    expect(find.text('Campagna locale sempre disponibile'), findsOneWidget);
    expect(find.textContaining('Accedi per vedere'), findsOneWidget);
  });

  testWidgets(
    'device folder and Master folders have stable keys and updated names',
    (tester) async {
      final account = ValueNotifier<String?>('owner');
      var name = 'Master Ombra';
      const device = OculumOtherDeviceCampaign(
        deviceId: 'a-device',
        campaignId: 'my-campaign',
        campaignName: 'Campagna del telefono',
        platform: 'android',
      );
      await _mount(
        tester,
        account,
        (_) async => OculumCampaignDirectory(
          otherDevices: [device],
          shared: [_share(ownerName: name)],
        ),
      );
      await tester.pumpAndSettle();
      final devices = tester.getTopLeft(find.text('Altri dispositivi')).dy;
      final shared = tester.getTopLeft(find.text('Master Ombra')).dy;
      expect(devices, lessThan(shared));
      await tester.tap(find.text('Altri dispositivi'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey(('a-device', 'my-campaign'))),
        findsOneWidget,
      );
      expect(find.text('Android'), findsOneWidget);
      name = 'Master Rame';
      await tester.tap(_refresh);
      await tester.pumpAndSettle();
      expect(find.text('Master Ombra'), findsNothing);
      expect(find.text('Master Rame'), findsOneWidget);
      expect(
        find.byKey(
          const PageStorageKey((
            'campaign-master',
            'owner',
            'master-stable-id',
          )),
        ),
        findsOneWidget,
      );
      expect(find.text('approved-code'), findsNothing);
    },
  );

  testWidgets('refresh removes access that has been revoked', (tester) async {
    final account = ValueNotifier<String?>('guest-with-access');
    var active = true;
    await _mount(
      tester,
      account,
      (_) async => OculumCampaignDirectory(shared: active ? [_share()] : []),
    );
    await tester.pumpAndSettle();
    expect(find.text('Master Ombra'), findsOneWidget);
    active = false;
    await tester.tap(_refresh);
    await tester.pumpAndSettle();
    expect(find.text('Master Ombra'), findsNothing);
    expect(find.text('Nessuna campagna condivisa con te.'), findsOneWidget);
  });

  testWidgets('opening a stale shared entry only uses a fresh grant', (
    tester,
  ) async {
    final account = ValueNotifier<String?>('access');
    var result = OculumCampaignDirectory(shared: [_share()]);
    final opened = <String>[];
    await _mount(
      tester,
      account,
      (_) async => result,
      openShared: (id, row) async => opened.add('$id:${row.roomCode}'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Master Ombra'));
    await tester.pumpAndSettle();
    result = OculumCampaignDirectory(shared: [_share(roomCode: 'fresh-code')]);
    await tester.tap(find.text('Foresta lunare'));
    await tester.pumpAndSettle();
    expect(opened, ['access:fresh-code']);
    result = const OculumCampaignDirectory();
    await tester.tap(find.text('Foresta lunare'));
    await tester.pumpAndSettle();
    expect(opened, ['access:fresh-code']);
    expect(
      find.text('La campagna non è più condivisa con te.'),
      findsOneWidget,
    );
  });

  testWidgets('changing accounts clears directory and rejects late responses', (
    tester,
  ) async {
    final account = ValueNotifier<String?>('first');
    final first = Completer<OculumCampaignDirectory>();
    final second = Completer<OculumCampaignDirectory>();
    await _mount(
      tester,
      account,
      (id) => id == 'first' ? first.future : second.future,
    );
    account.value = 'second';
    await tester.pump();
    second.complete(
      OculumCampaignDirectory(shared: [_share(ownerName: 'Secondo Master')]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Secondo Master'), findsOneWidget);
    first.complete(
      OculumCampaignDirectory(
        shared: [_share(ownerName: 'Nome privato primo account')],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Secondo Master'), findsOneWidget);
    expect(find.text('Nome privato primo account'), findsNothing);
    account.value = null;
    await tester.pumpAndSettle();
    expect(find.text('Secondo Master'), findsNothing);
    expect(find.text('Campagna locale sempre disponibile'), findsOneWidget);
  });
}
