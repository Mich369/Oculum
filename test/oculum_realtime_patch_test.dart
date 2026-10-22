import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('only authenticated staff owner edits can use database revisions', () {
    final owner = <String, dynamic>{'localUpdatedAt': '2099-01-01T00:00:00Z'};
    final packet = <String, dynamic>{
      'authenticatedRole': 'master',
      'serverSequence': 42,
      'sentAt': '2026-01-01T00:00:00Z',
    };
    expect(
      oculumRealtimeStaffOwnerEditSequence(
        owner,
        packet,
        'oculum_secure_room-one',
      ),
      42,
    );
    expect(
      oculumRealtimeStaffOwnerEditSequence(owner, {
        ...packet,
        'authenticatedRole': 'coMaster',
      }, 'oculum_secure_room-one'),
      42,
    );
    expect(
      oculumRealtimeStaffOwnerEditSequence(owner, {
        ...packet,
        'authenticatedRole': 'player',
        'senderRole': 'master',
      }, 'oculum_secure_room-one'),
      isNull,
    );
    expect(
      oculumRealtimeStaffOwnerEditSequence(owner, {
        ...packet,
        'serverSequence': 0,
      }, 'oculum_secure_room-one'),
      isNull,
    );
    expect(
      oculumRealtimeStaffOwnerEditSequence(owner, packet, 'oculum_room_legacy'),
      isNull,
    );
    expect(
      oculumRealtimeStaffOwnerEditSequence(
        {
          ...owner,
          'realtimeSharedSheet': true,
          'realtimeDirtyAt': '2099-01-01',
        },
        packet,
        'oculum_secure_room-one',
      ),
      isNull,
    );
  });
  test('private Eye roles never propagate through owner sheet edits', () {
    final original = <String, dynamic>{
      'currentHp': '100',
      'diaryEntityRoles': [],
      'diaryKnowledgeSync': {'privateKey': 'original'},
    };
    final edited = <String, dynamic>{
      'currentHp': '90',
      'diaryEntityRoles': [
        {'entityId': 'one', 'role': 'enemy', 'history': []},
      ],
      'diaryKnowledgeSync': {'privateKey': 'edited'},
    };
    expect(oculumRealtimeBuildSheetPatch(original, edited), {
      'currentHp': '90',
    });
    expect(
      oculumRealtimeFallbackEditablePatch(
        edited,
      ).containsKey('diaryEntityRoles'),
      isFalse,
    );
    expect(
      oculumRealtimeFallbackEditablePatch(
        edited,
      ).containsKey('diaryKnowledgeSync'),
      isFalse,
    );
    expect(
      oculumRealtimeMergeSheetPatch(edited, {
        'diaryKnowledgeSync': {'privateKey': 'remote'},
      })['diaryKnowledgeSync'],
      edited['diaryKnowledgeSync'],
    );
    expect(
      oculumRealtimeMergeSheetPatch(edited, {
        'currentHp': '80',
        'diaryEntityRoles': [],
      })['diaryEntityRoles'],
      edited['diaryEntityRoles'],
    );
  });
  test('patch realtime cambia solo il campo modificato', () {
    final original = <String, dynamic>{
      'nome': 'Hoshy',
      'currentHp': '120',
      'inventario': [
        {'nome': 'Reliquia'},
      ],
      'immaginePersonaggioBase64': 'image-data',
    };
    final edited = <String, dynamic>{...original, 'currentHp': '90'};

    final patch = oculumRealtimeBuildSheetPatch(original, edited);

    expect(patch, {'currentHp': '90'});
  });

  test(
    'online shares purchased items but keeps each merchant stock private',
    () {
      final ownerSheet = <String, dynamic>{
        'merchantStock': [
          {'id': 'owner-only-offer'},
        ],
        'merchantStockSessionId': 'owner-session',
        'merchantProfiles': [
          {
            'id': 'owner-market',
            'name': 'Mercato nero',
            'shopType': 'mercato_nero',
            'pricePercent': 115,
            'stock': [
              {'id': 'personal-offer'},
            ],
            'offerSelections': {
              'mercato_nero': ['personal-offer'],
            },
          },
        ],
        'merchantActiveProfileId': 'owner-market',
        'merchantDustPurchasedSinceLongRest': true,
        'merchantDustPurchaseCount': 2,
        'merchantHerbalEffects': [
          {'effect': 'vampirismo', 'shortRestsRemaining': 1},
        ],
        'inventario': <Map<String, dynamic>>[],
      };
      final outgoing = oculumRealtimeStripPrivateMerchantState(
        Map<String, dynamic>.from(ownerSheet),
      );

      expect(outgoing.keys, isNot(contains('merchantStock')));
      expect(outgoing['merchantProfiles'], [
        {
          'id': 'owner-market',
          'name': 'Mercato nero',
          'shopType': 'mercato_nero',
          'pricePercent': 115,
        },
      ]);
      expect(
        outgoing['merchantHerbalEffects'],
        ownerSheet['merchantHerbalEffects'],
      );
      expect(ownerSheet['merchantStock'], isNotEmpty);

      final stockOnlyChange = <String, dynamic>{
        ...ownerSheet,
        'merchantProfiles': [
          {
            ...Map<String, dynamic>.from(ownerSheet['merchantProfiles']!.first),
            'stock': [
              {'id': 'new-private-offer'},
            ],
            'offerSelections': {
              'mercato_nero': ['new-private-offer'],
            },
          },
        ],
      };
      expect(
        oculumRealtimeBuildSheetPatch(ownerSheet, stockOnlyChange),
        isEmpty,
      );

      final next = <String, dynamic>{
        ...ownerSheet,
        'merchantStock': [
          {'id': 'different-private-offer'},
        ],
        'merchantProfiles': [
          {'id': 'different-private-market'},
        ],
        'inventario': [
          {'nome': 'Arma acquistata'},
        ],
      };
      final patch = oculumRealtimeBuildSheetPatch(ownerSheet, next);
      expect(patch, {
        'merchantProfiles': [
          {
            'id': 'different-private-market',
            'name': 'Mercante di fiducia',
            'shopType': 'tutti',
            'pricePercent': 100,
          },
        ],
        'inventario': [
          {'nome': 'Arma acquistata'},
        ],
      });
    },
  );

  test('roster mercanti condiviso conserva scorte locali per profilo', () {
    final merged = oculumRealtimeMergeMerchantRoster(
      [
        {
          'id': 'market-a',
          'name': 'Banco A',
          'shopType': 'chef',
          'stock': [
            {'id': 'solo-a'},
          ],
          'offerSelections': {
            'chef': ['solo-a'],
          },
        },
      ],
      [
        {
          'id': 'market-a',
          'name': 'Banco A aggiornato',
          'shopType': 'mercato_nero',
          'pricePercent': 110,
          'stock': [
            {'id': 'must-not-copy'},
          ],
        },
        {
          'id': 'market-b',
          'name': 'Banco B',
          'shopType': 'fabbro',
          'pricePercent': 100,
        },
      ],
    );

    expect(merged, [
      {
        'id': 'market-a',
        'name': 'Banco A aggiornato',
        'shopType': 'mercato_nero',
        'stock': [
          {'id': 'solo-a'},
        ],
        'offerSelections': {
          'chef': ['solo-a'],
        },
        'pricePercent': 110,
      },
      {
        'id': 'market-b',
        'name': 'Banco B',
        'shopType': 'fabbro',
        'pricePercent': 100,
        'stock': <dynamic>[],
      },
    ]);
  });

  test('merge patch HP preserva immagine, inventario e note', () {
    final existing = <String, dynamic>{
      'nome': 'Player',
      'currentHp': '120',
      'notePersonaggio': 'nota locale',
      'inventario': [
        {'nome': 'Chiave'},
      ],
      'immaginePersonaggioBase64': 'image-data',
    };
    final patch = <String, dynamic>{
      'currentHp': '80',
      'notePersonaggio': '',
      'inventario': <Map<String, dynamic>>[],
      'immaginePersonaggioBase64': '',
    };

    final merged = oculumRealtimeMergeSheetPatch(existing, patch);

    expect(merged['currentHp'], '80');
    expect(merged['notePersonaggio'], 'nota locale');
    expect(merged['inventario'], existing['inventario']);
    expect(merged['immaginePersonaggioBase64'], 'image-data');
  });

  test('merge patch inventario applica solo inventario non vuoto', () {
    final existing = <String, dynamic>{
      'currentHp': '100',
      'inventario': [
        {'nome': 'Vecchio'},
      ],
      'immaginePersonaggioBase64': 'image-data',
    };
    final patch = <String, dynamic>{
      'inventario': [
        {'nome': 'Nuovo'},
      ],
    };

    final merged = oculumRealtimeMergeSheetPatch(existing, patch);

    expect(merged['currentHp'], '100');
    expect(merged['inventario'], [
      {'nome': 'Nuovo'},
    ]);
    expect(merged['immaginePersonaggioBase64'], 'image-data');
  });

  test('un edit esplicito può svuotare le collezioni della scheda', () {
    final existing = <String, dynamic>{
      'inventario': [
        {'nome': 'Vecchio'},
      ],
      'skills': [
        {'nome': 'Skill'},
      ],
    };
    final patch = <String, dynamic>{
      'inventario': <Map<String, dynamic>>[],
      'skills': <Map<String, dynamic>>[],
    };

    expect(oculumRealtimeMergeSheetPatch(existing, patch), existing);
    expect(
      oculumRealtimeMergeSheetPatch(
        existing,
        patch,
        allowClearFields: {'inventario', 'skills'},
      ),
      {
        'inventario': <Map<String, dynamic>>[],
        'skills': <Map<String, dynamic>>[],
      },
    );
  });

  test('fallback patch condivide i dati della scheda ma filtra i segreti', () {
    final current = <String, dynamic>{
      'currentHp': '70',
      'immaginePersonaggioBase64': 'image-data',
      'background': 'testo lungo',
      'relayServerUrl': 'server privato',
      'partyMembri': [
        {'tag': 'ALLY'},
      ],
      'skills': [
        {'name': 'Skill'},
      ],
      'arti': [
        {'name': 'Art'},
      ],
      'inventario': [
        {'name': 'Oggetto'},
      ],
    };

    final patch = oculumRealtimeFallbackEditablePatch(current);

    expect(patch['currentHp'], '70');
    expect(patch.containsKey('immaginePersonaggioBase64'), isFalse);
    expect(patch['background'], 'testo lungo');
    expect(patch['partyMembri'], current['partyMembri']);
    expect(patch['skills'], current['skills']);
    expect(patch['arti'], current['arti']);
    expect(patch['inventario'], current['inventario']);
    expect(patch.containsKey('relayServerUrl'), isFalse);
  });
}
