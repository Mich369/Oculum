import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_sheet_transfer.dart';

void main() {
  final now = DateTime(2026, 10, 1);
  final original = <String, dynamic>{
    'sheet': {'nome': 'Hoshy — Ω', 'imageBase64': 'x' * 200000},
    'deliveryId': 'receipt',
    'targetTags': ['OWNER'],
  };
  List<Map<String, dynamic>> chunks(String id) {
    final text = oculumEncodeSheetTransfer(original);
    final size = OculumSheetTransferAssembler.chunkSize;
    final count = (text.length / size).ceil();
    return List.generate(
      count,
      (i) => {
        'transferId': id,
        'chunkIndex': i,
        'chunkCount': count,
        'data': text.substring(
          i * size,
          ((i + 1) * size).clamp(0, text.length),
        ),
      },
    );
  }

  test(
    'out of order, duplicates and missing chunks preserve all sheet data',
    () {
      final assembler = OculumSheetTransferAssembler();
      final parts = chunks('one');
      for (final part in parts.skip(1).toList().reversed) {
        expect(assembler.accept(part, now), isNull);
        expect(assembler.accept(part, now), isNull);
      }
      expect(assembler.accept(parts.first, now), original);
    },
  );

  test('incomplete transfers expire and reconnect clears old fragments', () {
    final assembler = OculumSheetTransferAssembler();
    final parts = chunks('old');
    expect(assembler.accept(parts.first, now), isNull);
    for (final part in parts.skip(1)) {
      expect(
        assembler.accept(part, now.add(const Duration(minutes: 4))),
        isNull,
      );
    }
    assembler.clear();
    for (final part in parts.skip(1)) {
      expect(assembler.accept(part, now), isNull);
    }
    expect(assembler.accept(parts.first, now), original);
  });

  test(
    'conflicting duplicate, malformed data and unbounded metadata rejected',
    () {
      final assembler = OculumSheetTransferAssembler();
      final parts = chunks('bad');
      assembler.accept(parts.first, now);
      expect(
        assembler.accept({...parts.first, 'data': 'corrupt'}, now),
        isNull,
      );
      for (final part in parts.skip(1)) {
        expect(assembler.accept(part, now), isNull);
      }
      expect(
        assembler.accept({
          'transferId': 'junk',
          'chunkIndex': 0,
          'chunkCount': 1,
          'data': '!',
        }, now),
        isNull,
      );
      expect(
        assembler.accept({...parts.first, 'chunkCount': 10000000}, now),
        isNull,
      );
      expect(
        assembler.accept({
          ...parts.first,
          'data': 'x' * (OculumSheetTransferAssembler.chunkSize + 1),
        }, now),
        isNull,
      );
    },
  );
}
