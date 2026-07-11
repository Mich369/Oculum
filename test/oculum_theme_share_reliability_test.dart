import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('theme colors are corrected against a dark Kingi surface', () {
    const surface = Color(0xFF161B22);
    const oldKingiTertiary = Color(0xFF102B4D);

    final readable = oculumReadableThemeColor(
      oldKingiTertiary,
      surface,
      minRatio: 4.5,
    );

    expect(readable, isNot(oldKingiTertiary));
    expect(
      oculumThemeContrastRatio(readable, surface),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('already readable theme colors keep their identity', () {
    const surface = Color(0xFF161B22);
    const cyan = Color(0xFF78CFFF);

    expect(oculumReadableThemeColor(cyan, surface), cyan);
  });

  test('friend delivery hash changes when recipients change', () {
    final first = oculumRealtimeSheetDeliveryHashKey(
      'friend',
      'sheet-1',
      const <String>['b', 'a'],
    );
    final reordered = oculumRealtimeSheetDeliveryHashKey(
      'friend',
      'sheet-1',
      const <String>['A', 'B'],
    );
    final withNewFriend = oculumRealtimeSheetDeliveryHashKey(
      'friend',
      'sheet-1',
      const <String>['a', 'b', 'c'],
    );

    expect(reordered, first);
    expect(withNewFriend, isNot(first));
  });

  test('friend presence signature ignores order and duplicate tags', () {
    final first = oculumRealtimePresenceTagSignature(
      const <Map<String, dynamic>>[
        <String, dynamic>{
          'localSheetTags': <String>['beta', 'ALPHA'],
        },
        <String, dynamic>{
          'localSheetTags': <String>['alpha'],
        },
      ],
    );
    final second = oculumRealtimePresenceTagSignature(
      const <Map<String, dynamic>>[
        <String, dynamic>{
          'localSheetTags': <String>['Alpha', 'BETA'],
        },
      ],
    );

    expect(first, 'ALPHA|BETA');
    expect(second, first);
  });

  test('sheet share decoder accepts the portable Oculum code', () {
    final payload = <String, dynamic>{
      'kind': 'oculum_sheets',
      'version': 1,
      'sheets': <Map<String, dynamic>>[
        <String, dynamic>{'nome': 'Hoshy', 'currentHp': '30'},
      ],
    };
    final code =
        '$oculumSheetShareCodePrefix${base64UrlEncode(utf8.encode(jsonEncode(payload)))}';

    final decoded = oculumDecodeSheetShareText(code);

    expect(decoded, hasLength(1));
    expect(decoded.single['nome'], 'Hoshy');
    expect(decoded.single['currentHp'], '30');
  });
}
