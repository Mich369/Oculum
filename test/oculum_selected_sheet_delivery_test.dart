import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test(
    'deliver selected owner and active dependants, never private archive',
    () {
      final sheets = <Map<String, dynamic>>[
        {'sheetTag': 'OWNER'},
        {'sheetTag': 'PRIVATE'},
        {'sheetTag': 'SUMMON', 'isSummon': true, 'summonerTag': 'OWNER'},
        {
          'sheetTag': 'EXPIRED',
          'isSummon': true,
          'summonerTag': 'OWNER',
          'summonExpired': true,
        },
        {'sheetTag': 'EYE', 'occhioCaduto': true},
        {
          'sheetTag': 'REMOTE',
          'isSummon': true,
          'summonerTag': 'OWNER',
          'realtimeSharedSheet': true,
        },
      ];
      final eyes = <Map<String, dynamic>>[
        {
          'id': 'eye',
          'active': true,
          'ownerSheetId': 'OWNER',
          'summonedSheetTag': 'EYE',
        },
      ];
      expect(oculumSelectedSheetDeliveryIndexes(sheets, 0, eyes), [0, 2, 4]);
      expect(oculumSelectedSheetDeliveryIndexes(sheets, 2, eyes), [2, 0, 4]);
      expect(oculumSelectedSheetDeliveryIndexes(sheets, 4, eyes), [4, 0, 2]);
      expect(oculumSelectedSheetDeliveryIndexes(sheets, 1, eyes), [1]);
      expect(oculumSelectedSheetDeliveryIndexes(sheets, 5, eyes), isEmpty);
      eyes.first['active'] = false;
      expect(oculumSelectedSheetDeliveryIndexes(sheets, 0, eyes), [0, 2]);
    },
  );
}
