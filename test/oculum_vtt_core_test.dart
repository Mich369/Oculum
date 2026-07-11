import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:oculum/main.dart';

void main() {
  group('Oculum VTT persistence', () {
    test('migrates the legacy single map without losing tokens', () {
      final state = OculumVttState.fromJson(
        null,
        legacy: <String, dynamic>{
          'mapImagePath': r'C:\maps\forest.png',
          'mapImageName': 'Foresta di Tedius',
          'mapUrl': 'https://example.test/map',
          'mapNotes': 'Ingresso a nord',
          'mapWidthMeters': '120',
          'mapHeightMeters': '80',
          'localMapTokens': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'hero', 'x': 0.2, 'y': 0.4},
          ],
        },
      );

      expect(state.scenes, hasLength(1));
      expect(state.activeScene.imageName, 'Foresta di Tedius');
      expect(state.activeScene.imagePath, r'C:\maps\forest.png');
      expect(state.activeScene.widthMeters, 120);
      expect(state.activeScene.tokens.single['id'], 'hero');
    });

    test('round trip preserves unknown forward-compatible fields', () {
      final state = OculumVttState.fromJson(<String, dynamic>{
        'version': 99,
        'activeSceneId': 'scene-a',
        'futureState': <String, dynamic>{'enabled': true},
        'scenes': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'scene-a',
            'name': 'Rovina',
            'collectionId': 'place-a',
            'collectionName': 'Citta sepolta',
            'gridType': 'square',
            'gridSizePx': 0,
            'distancePerCell': 2,
            'futureSceneField': 'kept',
          },
        ],
      });

      final encoded = state.toJson();
      expect((encoded['futureState'] as Map)['enabled'], isTrue);
      final scene = (encoded['scenes'] as List).single as Map;
      expect(scene['futureSceneField'], 'kept');
      expect(scene['gridSizePx'], 12);
    });

    test('normalization repairs duplicate scene ids', () {
      final state = OculumVttState.fromJson(<String, dynamic>{
        'activeSceneId': 'same',
        'scenes': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'same', 'name': 'A'},
          <String, dynamic>{'id': 'same', 'name': 'B'},
        ],
      });

      expect(state.scenes.map((scene) => scene.id).toSet(), hasLength(2));
      expect(state.activeScene.name, 'A');
    });

    test(
      'legacy permission maps gain new defaults without losing overrides',
      () {
        final state = OculumVttState.fromJson(<String, dynamic>{
          'activeSceneId': 'scene-a',
          'scenes': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'scene-a', 'name': 'A'},
          ],
          'permissions': <String, dynamic>{
            'player': <String, dynamic>{'tokens': false},
          },
        });

        expect(state.permissions['player']?['tokens'], isFalse);
        expect(state.permissions['player']?['ping'], isTrue);
        expect(state.permissions['player']?['map'], isFalse);
        expect(state.permissions['observer']?['tools'], isTrue);
        expect(state.permissions['master']?.values, everyElement(isTrue));
      },
    );

    test(
      'public scene snapshots remove private data but keep token ownership',
      () {
        final scene = OculumVttScene.empty()
          ..imagePath = r'C:\private\map.png'
          ..imageDataBase64 = 'private-image'
          ..notes = 'master only'
          ..tokens.add(<String, dynamic>{
            'id': 'hero',
            'ownerTag': 'OCU-PLAYER',
            'visible': true,
            'privateNotes': 'hidden',
          })
          ..tokens.addAll(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'hidden-enemy',
              'visible': true,
              'hidden': true,
            },
            <String, dynamic>{'id': 'invisible-enemy', 'visible': false},
          ])
          ..triggers.add(<String, dynamic>{'id': 'trap'});

        final public = scene.toJson(includePrivate: false);
        final token = (public['tokens'] as List).single as Map;
        expect(public['imagePath'], isEmpty);
        expect(public['imageDataBase64'], isEmpty);
        expect(public['notes'], isEmpty);
        expect(public['triggers'], isEmpty);
        expect(token['ownerTag'], 'OCU-PLAYER');
        expect(token.containsKey('privateNotes'), isFalse);
      },
    );

    test('fog layers remain isolated by party and player', () {
      final scene = OculumVttScene.empty()
        ..fogLayers['party'] = <Map<String, dynamic>>[
          <String, dynamic>{'id': 'party-reveal'},
        ]
        ..fogLayers['ocu-player'] = <Map<String, dynamic>>[
          <String, dynamic>{'id': 'player-reveal'},
        ];

      final restored = OculumVttScene.fromJson(scene.toJson());
      expect(restored.fogLayers['party']?.single['id'], 'party-reveal');
      expect(restored.fogLayers['ocu-player']?.single['id'], 'player-reveal');
    });
  });

  group('Oculum VTT geometry', () {
    const start = Offset.zero;
    const end = Offset(30, 40);

    test('supports precise square diagonal rules', () {
      expect(
        oculumVttDistanceCells(start, end, gridType: 'square', cellSize: 10),
        closeTo(5, 0.0001),
      );
      expect(
        oculumVttDistanceCells(
          start,
          end,
          gridType: 'square',
          cellSize: 10,
          diagonalRule: 'chebyshev',
        ),
        4,
      );
      expect(
        oculumVttDistanceCells(
          start,
          end,
          gridType: 'square',
          cellSize: 10,
          diagonalRule: 'manhattan',
        ),
        7,
      );
      expect(
        oculumVttDistance(
          start,
          end,
          gridType: 'square',
          cellSize: 10,
          distancePerCell: 2,
        ),
        closeTo(10, 0.0001),
      );
    });

    test('snaps square points and keeps no-grid points unchanged', () {
      expect(
        oculumVttSnapPoint(
          const Offset(24, 36),
          gridType: 'square',
          cellSize: 20,
        ),
        const Offset(20, 40),
      );
      expect(
        oculumVttSnapPoint(
          const Offset(24, 36),
          gridType: 'none',
          cellSize: 20,
        ),
        const Offset(24, 36),
      );
    });

    test('keeps group translation inside the tightest map boundary', () {
      final firstScale = oculumVttBoundaryTranslationScale(
        x: 0.8,
        y: 0.5,
        delta: const Offset(40, 0),
        canvasWidth: 100,
        canvasHeight: 100,
      );
      final secondScale = oculumVttBoundaryTranslationScale(
        x: 0.6,
        y: 0.5,
        delta: const Offset(40, 0),
        canvasWidth: 100,
        canvasHeight: 100,
      );

      expect(firstScale, closeTo(0.5, 0.0001));
      expect(secondScale, 1);
    });

    test('movement budget scales one shared pixel delta in map meters', () {
      const delta = Offset(30, 40);
      expect(
        oculumVttDistanceMetersForDelta(
          delta,
          canvasWidth: 100,
          canvasHeight: 100,
          mapWidthMeters: 100,
          mapHeightMeters: 100,
        ),
        closeTo(50, 0.0001),
      );
      expect(
        oculumVttMovementTranslationScale(
          delta,
          remainingMeters: 25,
          canvasWidth: 100,
          canvasHeight: 100,
          mapWidthMeters: 100,
          mapHeightMeters: 100,
        ),
        closeTo(0.5, 0.0001),
      );
    });

    test('closed walls block movement while open doors do not', () {
      final wall = <String, dynamic>{
        'a': <double>[0.5, 0],
        'b': <double>[0.5, 1],
        'blocksMovement': true,
        'type': 'wall',
      };
      expect(
        oculumVttMovementBlocked(
          const Offset(0.2, 0.5),
          const Offset(0.8, 0.5),
          <Map<String, dynamic>>[wall],
        ),
        isTrue,
      );

      wall['type'] = 'door';
      wall['open'] = true;
      expect(
        oculumVttMovementBlocked(
          const Offset(0.2, 0.5),
          const Offset(0.8, 0.5),
          <Map<String, dynamic>>[wall],
        ),
        isFalse,
      );
    });
  });

  group('Oculum VTT asset transfer', () {
    test('assembles out-of-order chunks exactly once', () {
      final source = Uint8List.fromList(List<int>.generate(96, (i) => i));
      final encoded = base64Encode(source);
      final chunks = <String>[
        encoded.substring(0, 32),
        encoded.substring(32, 64),
        encoded.substring(64),
      ];
      final assembler = OculumVttAssetAssembler(
        assetId: 'asset',
        chunkCount: chunks.length,
      );

      expect(assembler.addChunk(2, chunks[2]), isTrue);
      expect(assembler.addChunk(0, chunks[0]), isTrue);
      expect(assembler.addChunk(0, chunks[0]), isFalse);
      expect(assembler.addChunk(1, chunks[1]), isTrue);
      expect(assembler.isComplete, isTrue);
      expect(assembler.completeBytes(), orderedEquals(source));
    });

    test('prepares a bounded jpeg payload for online sharing', () {
      final source = img.Image(width: 8, height: 8);
      img.fill(source, color: img.ColorRgb8(32, 64, 96));
      final onePixelPng = Uint8List.fromList(img.encodePng(source));
      final prepared = prepareOculumVttSharedImage(<String, dynamic>{
        'bytes': onePixelPng,
        'maxDimension': 1024,
        'quality': 70,
      });

      expect('${prepared['assetId']}', startsWith('vtt_'));
      expect(prepared['bytes'], isA<Uint8List>());
      expect(base64Decode('${prepared['base64']}'), isNotEmpty);
    });
  });
}
