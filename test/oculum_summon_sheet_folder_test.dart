import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  testWidgets('Patalpa summons use the actual owner and survive a save', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 900),
    );
    final probe = OculumPerformanceProbe(state);
    const other = 'PatalpaOcu:3690FD5G';
    const owner = 'PatalpaOcu:3690FD5H';
    const neighbor = 'CustodeOcu:3690FD5J';
    Map<String, dynamic> sheet(String tag, String name) => {
      'id': tag,
      'sheetTag': tag,
      'nome': name,
      'tipoScheda': 'Mostro',
      'livello': '0',
      'grado': '0',
      'resilienza': '4',
      'currentHp': '30',
    };
    probe.loadCampaign({
      ...probe.campaignSnapshot(),
      'schedaCorrente': 1,
      'schedePersonaggio': [
        sheet(other, 'Patalpa'),
        sheet(owner, 'Patalpa'),
        sheet(neighbor, 'Custode'),
      ],
      'sheetSidebarFolders': [
        {'id': 'party', 'name': 'Party', 'parent': ''},
        {'id': 'party-nested', 'name': 'Compagni', 'parent': 'party'},
      ],
      'sheetSidebarPlacements': {
        other: {'folder': 'party', 'order': 0},
        owner: {'folder': 'party-nested', 'order': 8},
        neighbor: {'folder': 'party-nested', 'order': 8},
      },
    });
    state.datiCaricati = false;
    state.modalitaMaster = false;
    state.isMasterHost = false;

    void summonPatalpa() {
      probe.applyEffects([
        OculumStructuredEffect(type: 'evocazione', target: 'patalpa_compagno'),
      ], source: 'Generazione');
    }

    expect(probe.ownerTag(), owner);
    summonPatalpa();
    final first = state.schedePersonaggio.last as Map<String, dynamic>;
    final firstTag = first['sheetTag'] as String;
    expect(first['summonerTag'], owner);
    expect(probe.sheetTagsInFolder('party-nested'), [
      owner,
      firstTag,
      neighbor,
    ]);
    expect(probe.sheetTagsInFolder('party'), [other]);
    expect(state.schedaCorrente, 1);

    // Exercise the same runtime entry with a second actor as the summoner.
    probe.loadCampaign({...probe.campaignSnapshot(), 'schedaCorrente': 3});
    expect(probe.ownerTag(), firstTag);
    summonPatalpa();
    final second = state.schedePersonaggio.last as Map<String, dynamic>;
    final secondTag = second['sheetTag'] as String;
    expect(second['summonerTag'], firstTag);
    expect(secondTag, isNot(firstTag));

    final saved =
        jsonDecode(jsonEncode(probe.campaignSnapshot()))
            as Map<String, dynamic>;
    probe.loadCampaign(saved);
    expect(probe.sheetTagsInFolder('party-nested'), [
      owner,
      firstTag,
      secondTag,
      neighbor,
    ]);
    expect(probe.sheetTagsInFolder('party'), [other]);
    expect(
      (state.schedePersonaggio as List).map((sheet) => sheet['sheetTag']),
      [other, owner, neighbor, firstTag, secondTag],
    );
    probe.cancelPendingSave();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('received summons wait for the same account and campaign', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 900),
    );
    final probe = OculumPerformanceProbe(state);
    state.datiCaricati = false;
    state.modalitaMaster = true;
    state.isMasterHost = true;
    state.schedePersonaggio.clear();
    state.sheetSidebarFolders.clear();
    state.sheetSidebarPlacements.clear();
    const online = 'oculum_received_online_sheets';
    const owner = 'PatalpaOcu:3690FD5G';
    const summon = 'PatalpaOcu:3690FD5H';
    const nested = 'PatalpaOcu:3690FD5J';
    state.schedePersonaggio.add({
      'id': owner,
      'sheetTag': owner,
      'nome': 'Patalpa',
    });
    state.sheetSidebarFolders.add({
      'id': 'private',
      'name': 'Locale',
      'parent': '',
    });
    state.sheetSidebarPlacements[owner] = {'folder': 'private', 'order': 0};

    Map<String, dynamic> packet(
      String tag,
      int second, {
      String account = 'player-one',
      String campaign = 'party-one',
      String summoner = '',
      String name = 'Patalpa',
      bool legacyLink = false,
    }) => {
      'senderRole': 'player',
      'authenticatedUserId': account,
      'sheetId': tag,
      'ownerTag': tag,
      'campaignId': campaign,
      'sentAt': '2026-11-07T10:00:0$second.000Z',
      'sheetName': name,
      'sheet': {
        'id': tag,
        'sheetTag': tag,
        'nome': name,
        'tipoScheda': 'Mostro',
        if (summoner.isNotEmpty)
          (legacyLink ? 'summonerTag' : 'summonPlacementOwnerTag'): summoner,
      },
    };
    String localTagAt(int index) =>
        state.schedePersonaggio[index + 1]['sheetTag'] as String;

    expect(
      probe.receiveStaffSheet(packet(nested, 1, summoner: summon)),
      isTrue,
    );
    expect(
      probe.receiveStaffSheet(
        packet(summon, 2, summoner: owner, legacyLink: true),
      ),
      isTrue,
    );
    final nestedLocal = localTagAt(0);
    final summonLocal = localTagAt(1);
    final unresolved = Map<String, dynamic>.from(
      state.sheetSidebarPlacements[summonLocal] as Map,
    );
    expect(
      probe.receiveStaffSheet(packet(owner, 3, account: 'player-two')),
      isTrue,
    );
    final otherAccount = localTagAt(2);
    expect(
      probe.receiveStaffSheet(packet(owner, 4, campaign: 'party-two')),
      isTrue,
    );
    final otherCampaign = localTagAt(3);
    expect(state.sheetSidebarPlacements[summonLocal], unresolved);
    expect(probe.sheetTagsInFolder('private'), [owner]);
    expect(
      probe.sheetTagsInFolder(online),
      containsAll([nestedLocal, summonLocal]),
    );

    expect(probe.receiveStaffSheet(packet(owner, 5)), isTrue);
    final ownerLocal = localTagAt(4);
    expect(ownerLocal, isNot(otherAccount));
    expect(ownerLocal, isNot(otherCampaign));
    expect(probe.sheetTagsInFolder(online), [
      otherAccount,
      otherCampaign,
      ownerLocal,
      summonLocal,
      nestedLocal,
    ]);

    state.sheetSidebarFolders.add({
      'id': 'manual',
      'name': 'Manuale',
      'parent': '',
    });
    probe.moveSheetFolderEntry(summonLocal, 'manual');
    expect(
      probe.receiveStaffSheet(
        packet(summon, 6, summoner: owner, name: 'Patalpa rinominato'),
      ),
      isTrue,
    );
    expect(localTagAt(1), summonLocal);
    expect(probe.sheetTagsInFolder('manual'), [summonLocal]);
    expect(state.schedePersonaggio, hasLength(6));

    const legacyOwner = 'LegacyOcu:3690FD5G';
    const separator = 'LegacyOcu:3690FD5H';
    const legacySummon = 'LegacyOcu:3690FD5J';
    expect(
      probe.receiveStaffSheet(packet(legacyOwner, 7, account: '')),
      isTrue,
    );
    expect(probe.receiveStaffSheet(packet(separator, 8, account: '')), isTrue);
    expect(
      probe.receiveStaffSheet(
        packet(legacySummon, 9, account: '', summoner: legacyOwner),
      ),
      isTrue,
    );
    const legacyOrder = [legacyOwner, separator, legacySummon];
    expect(
      probe.sheetTagsInFolder(online).where(legacyOrder.contains),
      legacyOrder,
    );
    probe.cancelPendingSave();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
