import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_campaign_transfer.dart';

void main() {
  test(
    'sposta schede e dati collegati senza alterare il JSON delle schede',
    () {
      final selected = <String, dynamic>{
        'sheetTag': 'A1',
        'id': 'A1',
        'nome': 'Velmoria',
        'inventario': [
          {'nome': 'Spada', 'quantita': 2, 'note': 'personalizzata'},
        ],
        'diarioPagine': [
          {'titolo': 'Memoria', 'testo': 'Non perdere'},
        ],
        'effects': [
          {'id': 'custom', 'value': 7},
        ],
      };
      final source = <String, dynamic>{
        'id': 'source',
        'schedePersonaggio': [
          selected,
          {'sheetTag': 'B2', 'nome': 'Luca'},
        ],
        'occhiCaduti': [
          {'id': 'eye-a', 'ownerSheetId': 'A1'},
          {'id': 'eye-b', 'ownerSheetId': 'B2'},
        ],
        'localMapTokens': [
          {'id': 'map-a', 'sheetTag': 'A1'},
          {'id': 'map-b', 'sheetTag': 'B2'},
        ],
        'pawnGuardians': [
          {'id': 'pawn-a', 'ownerTag': 'A1', 'hp': 17},
          {'id': 'pawn-b', 'ownerTag': 'B2', 'hp': 21},
        ],
        'pawnDamageReceipts': {
          'receipt-a': {'sheetTag': 'A1', 'amount': 5},
          'receipt-b': {'sheetTag': 'B2', 'amount': 8},
        },
        'sheetSidebarFolders': [
          {'id': 'folder-a', 'name': 'Personaggi', 'parent': ''},
        ],
        'sheetSidebarPlacements': {
          'A1': {'folder': 'folder-a', 'order': 0},
          'B2': {'folder': '', 'order': 1},
        },
        'schedaCorrente': 0,
      };
      final destination = <String, dynamic>{
        'id': 'destination',
        'schedePersonaggio': [
          {'sheetTag': 'C3', 'nome': 'Giulio'},
        ],
        'sheetSidebarFolders': [
          {'id': 'folder-a', 'name': 'Avversari', 'parent': ''},
        ],
        'sheetSidebarPlacements': <String, dynamic>{},
      };

      final moved = moveOculumCampaignSheets(
        source: source,
        destination: destination,
        sheetTags: {'a1'},
      );
      final updatedSource = moved['source']!;
      final updatedDestination = moved['destination']!;

      expect(updatedSource['schedePersonaggio'], [
        {'sheetTag': 'B2', 'nome': 'Luca'},
      ]);
      final movedSheet = (updatedDestination['schedePersonaggio'] as List).last;
      expect(movedSheet, selected);
      expect(updatedSource['occhiCaduti'], [
        {'id': 'eye-b', 'ownerSheetId': 'B2'},
      ]);
      expect(updatedDestination['occhiCaduti'], [
        {'id': 'eye-a', 'ownerSheetId': 'A1'},
      ]);
      expect(updatedSource['localMapTokens'], [
        {'id': 'map-b', 'sheetTag': 'B2'},
      ]);
      expect(updatedDestination['localMapTokens'], [
        {'id': 'map-a', 'sheetTag': 'A1'},
      ]);
      expect(updatedSource['pawnGuardians'], [
        {'id': 'pawn-b', 'ownerTag': 'B2', 'hp': 21},
      ]);
      expect(updatedDestination['pawnGuardians'], [
        {'id': 'pawn-a', 'ownerTag': 'A1', 'hp': 17},
      ]);
      expect(updatedSource['pawnDamageReceipts'], {
        'receipt-b': {'sheetTag': 'B2', 'amount': 8},
      });
      expect(updatedDestination['pawnDamageReceipts'], {
        'receipt-a': {'sheetTag': 'A1', 'amount': 5},
      });
      expect(
        updatedDestination['sheetSidebarPlacements']['A1']['folder'],
        'folder-a_moved_1',
      );
      expect(
        (updatedDestination['sheetSidebarFolders'] as List)
            .where((folder) => folder['id'] == 'folder-a_moved_1')
            .single['name'],
        'Personaggi',
      );
      expect(source['schedePersonaggio'], hasLength(2));
      expect(destination['schedePersonaggio'], hasLength(1));
    },
  );

  test('rifiuta un doppione senza modificare alcuna campagna', () {
    final source = <String, dynamic>{
      'id': 'source',
      'schedePersonaggio': [
        {'sheetTag': 'A1', 'nome': 'Nuova copia'},
      ],
    };
    final destination = <String, dynamic>{
      'id': 'destination',
      'schedePersonaggio': [
        {'sheetTag': 'A1', 'nome': 'Originale'},
      ],
    };

    expect(
      () => moveOculumCampaignSheets(
        source: source,
        destination: destination,
        sheetTags: {'A1'},
      ),
      throwsStateError,
    );
    expect(source['schedePersonaggio'], [
      {'sheetTag': 'A1', 'nome': 'Nuova copia'},
    ]);
    expect(destination['schedePersonaggio'], [
      {'sheetTag': 'A1', 'nome': 'Originale'},
    ]);
  });
}
