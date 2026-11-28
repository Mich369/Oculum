import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oculum/services/oculum_campaign_directory.dart';

class _Backend implements OculumCampaignDirectoryBackend {
  final accounts = StreamController<String?>.broadcast(sync: true);
  final calls = <(String, Map<String, dynamic>)>[];
  String? current = 'master-a';
  Future<Object?> Function(String name, Map<String, dynamic> params)? handler;

  @override
  String? get verifiedAccountId => current;

  @override
  Stream<String?> get accountChanges => accounts.stream;

  void switchTo(String? id) {
    current = id;
    accounts.add(id);
  }

  @override
  Future<Object?> call(String function, Map<String, dynamic> params) async {
    calls.add((function, params));
    return handler?.call(function, params) ?? _reply;
  }
}

const _installation = 'f352c007-ebd8-4649-aeff-01d9ac4a1add';
const _reply = <String, dynamic>{
  'otherDevices': [
    {
      'deviceId': '888ea449-ada8-4b68-816b-88a0d37ab3fd',
      'campaignId': 'postea',
      'campaignName': 'Postea',
      'platform': 'windows',
    },
    {
      'deviceId': '05513b37-773b-4347-9fc1-c38400d28fb1',
      'campaignId': 'erik',
      'campaignName': 'Erik',
      'platform': 'windows',
    },
  ],
  'shared': [
    {
      'roomId': 'room-one',
      'roomCode': 'pae1',
      'ownerId': 'master-b',
      'ownerName': 'Corvo',
      'campaignId': 'pae',
      'campaignName': 'Pae',
    },
  ],
  'ownedShares': [
    {'roomId': 'room-two', 'campaignId': 'postea'},
  ],
};

const _ownCampaign = OculumOwnCampaignLabel(
  ownerId: 'master-a',
  campaignId: 'own',
  campaignName: 'Own campaign',
);
const _foreignCampaign = OculumOwnCampaignLabel(
  ownerId: 'master-b',
  campaignId: 'other',
  campaignName: 'Private other account',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  OculumCampaignDirectoryService fixture(_Backend backend) {
    final directory = OculumCampaignDirectoryService.withBackend(
      backend,
      installationId: () async => _installation,
      publishDelay: const Duration(milliseconds: 12),
    );
    addTearDown(() async {
      directory.dispose();
      await backend.accounts.close();
    });
    return directory;
  }

  test(
    'lists distinct same-platform devices and uses IDs for shared folders',
    () async {
      final backend = _Backend();
      final service = fixture(backend);
      final listing = await service.list(accountId: 'master-a');
      expect(listing.otherDevices, hasLength(2));
      expect(listing.otherDevices.map((row) => row.platform).toSet(), {
        'windows',
      });
      expect(
        listing.otherDevices.map((row) => row.deviceId).toSet(),
        hasLength(2),
      );
      expect(listing.shared.single.ownerId, 'master-b');
      expect(listing.shared.single.ownerName, 'Corvo');
      expect(listing.ownedShares.single.campaignId, 'postea');
      expect(backend.calls.single.$1, 'oculum_list_campaign_directory');
      expect(backend.calls.single.$2, {
        'p_expected_user_id': 'master-a',
        'p_device_id': _installation,
      });
    },
  );

  test(
    'publishes only bound campaigns, coalesces saves and deduplicates content',
    () async {
      final backend = _Backend();
      final service = fixture(backend);
      final first = service.replaceDeviceCampaigns(
        accountId: 'master-a',
        platform: 'windows',
        campaigns: [_ownCampaign],
      );
      const renamed = OculumOwnCampaignLabel(
        ownerId: 'master-a',
        campaignId: 'own',
        campaignName: 'New name',
      );
      final last = service.replaceDeviceCampaigns(
        accountId: 'master-a',
        platform: 'windows',
        campaigns: [renamed, _foreignCampaign],
      );
      await Future.wait([first, last]);
      await service.replaceDeviceCampaigns(
        accountId: 'master-a',
        platform: 'windows',
        campaigns: [_foreignCampaign, renamed],
      );
      expect(backend.calls, hasLength(1));
      expect(backend.calls.single.$1, 'oculum_replace_campaign_device_catalog');
      expect(backend.calls.single.$2, {
        'p_expected_user_id': 'master-a',
        'p_device_id': _installation,
        'p_platform': 'windows',
        'p_entries': [
          {'campaignId': 'own', 'campaignName': 'New name'},
        ],
      });
    },
  );

  test(
    'an unbound local workspace cannot clear an existing device listing',
    () async {
      final backend = _Backend();
      final service = fixture(backend);
      await service.replaceDeviceCampaigns(
        accountId: 'master-a',
        platform: 'windows',
        campaigns: [_foreignCampaign],
      );
      expect(backend.calls, isEmpty);
      await service.replaceDeviceCampaigns(
        accountId: 'master-a',
        platform: 'windows',
        campaigns: [],
        allowEmpty: true,
      );
      expect(backend.calls.single.$2['p_entries'], isEmpty);
    },
  );

  test(
    'a pending old account publication is cancelled before the network call',
    () async {
      final backend = _Backend();
      final service = fixture(backend);
      final pending = expectLater(
        service.replaceDeviceCampaigns(
          accountId: 'master-a',
          platform: 'windows',
          campaigns: [_ownCampaign],
        ),
        throwsA(isA<OculumCampaignDirectoryAccountChanged>()),
      );
      backend.switchTo('master-b');
      await pending;
      expect(backend.calls, isEmpty);
    },
  );

  test(
    'drops a late result even if the original account has signed back in',
    () async {
      final result = Completer<Object?>();
      final requestStarted = Completer<void>();
      final backend = _Backend()
        ..handler = (_, _) {
          requestStarted.complete();
          return result.future;
        };
      final service = fixture(backend);
      final stale = expectLater(
        service.list(accountId: 'master-a'),
        throwsA(isA<OculumCampaignDirectoryAccountChanged>()),
      );
      await requestStarted.future;
      backend.switchTo(null);
      backend.switchTo('master-a');
      result.complete(_reply);
      await stale;
    },
  );

  test(
    'an unverified account cannot query or change directory metadata',
    () async {
      final backend = _Backend()..current = null;
      final service = fixture(backend);
      await expectLater(
        service.list(accountId: 'guest'),
        throwsA(isA<OculumCampaignDirectoryAccountChanged>()),
      );
      await expectLater(
        service.setMasterDisplayName(accountId: 'guest', displayName: 'Guest'),
        throwsA(isA<OculumCampaignDirectoryAccountChanged>()),
      );
      expect(backend.calls, isEmpty);
    },
  );

  test(
    'rename, sharing and revocation use separate explicit operations',
    () async {
      final backend = _Backend();
      final service = fixture(backend);
      await service.setMasterDisplayName(
        accountId: 'master-a',
        displayName: '  Corvo  ',
      );
      await service.renameOwnedCampaignShare(
        accountId: 'master-a',
        campaignId: 'own',
        campaignName: '  New  ',
      );
      await service.shareCampaign(
        accountId: 'master-a',
        roomId: 'room-one',
        campaignId: 'own',
        campaignName: 'New',
        shared: false,
      );
      expect(backend.calls.map((call) => call.$1), [
        'oculum_set_campaign_master_label',
        'oculum_rename_owned_campaign_shares',
        'oculum_set_campaign_sharing',
      ]);
      expect(backend.calls[0].$2['p_display_name'], 'Corvo');
      expect(backend.calls[1].$2['p_campaign_name'], 'New');
      expect(backend.calls[1].$2.containsKey('p_shared'), isFalse);
      expect(backend.calls[2].$2['p_shared'], isFalse);
    },
  );

  test(
    'the fallback installation ID is random, reused and stored locally',
    () async {
      SharedPreferences.setMockInitialValues({});
      final backend = _Backend();
      final service = OculumCampaignDirectoryService.withBackend(backend);
      final second = OculumCampaignDirectoryService.withBackend(backend);
      addTearDown(() async {
        second.dispose();
        service.dispose();
        await backend.accounts.close();
      });
      await service.list(accountId: 'master-a');
      await second.list(accountId: 'master-a');
      final token = backend.calls.first.$2['p_device_id'] as String;
      expect(
        token,
        matches(
          r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
        ),
      );
      expect(backend.calls.last.$2['p_device_id'], token);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('oculum.campaign_directory.installation_id.v1'),
        token,
      );
    },
  );
}
