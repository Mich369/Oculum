import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'token updates retain received map, changed maps and scenes clear it',
    () {
      final previous = OculumVttScene.fromJson({
        'id': 'a',
        'imagePath': 'forest.png',
      });
      expect(
        oculumVttKeepReceivedImage(
          previous: previous,
          incoming: OculumVttScene.fromJson({
            'id': 'a',
            'imagePath': 'forest.png',
            'tokens': [
              {'id': 'hero', 'x': .4},
            ],
          }),
          preserveAsset: true,
        ),
        isTrue,
      );
      for (final incoming in [
        OculumVttScene.fromJson({'id': 'b', 'imagePath': 'forest.png'}),
        OculumVttScene.fromJson({'id': 'a', 'imagePath': 'cave.png'}),
        OculumVttScene.fromJson({
          'id': 'a',
          'imagePath': 'forest.png',
          'mapUrl': 'https://example.test/new',
        }),
      ]) {
        expect(
          oculumVttKeepReceivedImage(
            previous: previous,
            incoming: incoming,
            preserveAsset: true,
          ),
          isFalse,
        );
      }
      expect(
        oculumVttKeepReceivedImage(
          previous: previous,
          incoming: previous,
          preserveAsset: false,
        ),
        isFalse,
      );
    },
  );
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
            'currentHp': 37,
            'maxHp': 100,
            'tempHp': 8,
            'shield': 19,
            'currentOculum': 6,
            'totalPower': 70,
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
        expect(token['healthLabel'], 'Gravemente ferito');
        final private = (scene.toJson()['tokens'] as List).first as Map;
        for (final key in [
          'currentHp',
          'maxHp',
          'tempHp',
          'shield',
          'currentOculum',
          'totalPower',
        ]) {
          expect(token.containsKey(key), isFalse);
          expect(private[key], scene.tokens.first[key]);
        }
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

  testWidgets('receiving a legacy shared map keeps only coarse token health', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.modalitaMaster = false;
    final legacy = {
      'id': 'old-map',
      'tokens': [
        {
          'id': 'wounded',
          'ownerTag': 'ALLY',
          'currentHp': 25,
          'maxHp': 100,
          'tempHp': 11,
          'shield': 12,
        },
        {'id': 'downed', 'currentHp': 0, 'maxHp': 100, 'defeated': true},
      ],
    };
    probe.receiveRealtime('vtt_scene_shared', {
      'senderRole': 'master',
      'snapshot': {'scene': legacy},
    });
    final received = state.realtimeVisibleVttScene as OculumVttScene;
    expect(received.tokens.map((token) => token['healthLabel']), [
      'Morente',
      'A terra',
    ]);
    expect(received.tokens.first['ownerTag'], 'ALLY');
    expect(received.tokens.first.containsKey('currentHp'), isFalse);
    final savedSnapshot = state.realtimeVisibleVttSnapshot as Map;
    final savedToken = (savedSnapshot['scene']['tokens'] as List).first as Map;
    expect(savedToken.containsKey('maxHp'), isFalse);
    expect((legacy['tokens'] as List).first['currentHp'], 25);
    await closeFixture(tester, probe);
  });

  group('Bundled battle maps', () {
    test('six assets decode and support the existing JPEG fallback', () async {
      expect(oculumVttBundledMaps, hasLength(6));
      final ids = <String>{};
      for (final map in oculumVttBundledMaps) {
        expect(ids.add(map.id), isTrue);
        final data = await rootBundle.load(map.assetPath);
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        final image = img.decodeWebP(bytes);
        expect(image?.width, 1586, reason: map.assetPath);
        expect(image?.height, 992, reason: map.assetPath);
        final scene = map.createScene(english: false, sortOrder: 0);
        expect(scene.bundledMap, map);
        expect(scene.gridType, 'hex');
        expect(scene.snapToGrid, isTrue);
        expect(scene.distancePerCell, 2);
        expect(scene.walls, isEmpty);
        expect(scene.tokens, isEmpty);
        expect(scene.imageDataBase64, isEmpty);
        final restored = OculumVttScene.fromJson(
          jsonDecode(jsonEncode(scene.toJson(includePrivate: false))),
        );
        expect(restored.bundledMap, map);
        expect(restored.gridSizePx, 28);

        final fallback = prepareOculumVttSharedImage({
          'bytes': bytes,
          'quality': 68,
          'maxDimension': 1280,
        });
        expect(fallback['mime'], 'image/jpeg');
        final decoded = img.decodeJpg(fallback['bytes'] as Uint8List);
        expect(decoded?.width, 1280);
        expect(decoded?.height, 801);
      }
      final unknown = OculumVttScene.fromJson({
        'imagePath': 'oculum-board:../../outside',
      });
      expect(unknown.bundledMap, isNull);
      expect(unknown.toJson(includePrivate: false)['imagePath'], isEmpty);
    });

    test(
      'coordinates and token scale stay consistent across viewport sizes',
      () {
        final scene = oculumVttBundledMaps.first.createScene(
          english: false,
          sortOrder: 0,
        );
        const position = OculumVttPoint(0.41, 0.34);
        OculumVttPoint snappedIn(Size size) {
          final board = scene.boardSizeForViewport(size);
          final snapped = oculumVttSnapPoint(
            position.toOffset(board),
            gridType: scene.gridType,
            cellSize: scene.gridCellSizeForViewport(board.width),
          );
          return OculumVttPoint.fromOffset(snapped, board);
        }

        final desktop = snappedIn(const Size(980, 510));
        final phone = snappedIn(const Size(360, 260));
        expect(phone.x, closeTo(desktop.x, 0.000001));
        expect(phone.y, closeTo(desktop.y, 0.000001));
        expect(
          scene.tokenSizeForViewport(64, 360) / 360,
          closeTo(scene.tokenSizeForViewport(64, 640) / 640, 0.000001),
        );
        final oldSquare = OculumVttScene.empty()..gridType = 'square';
        expect(
          oldSquare.boardSizeForViewport(const Size(360, 260)),
          const Size(360, 260),
        );
        expect(oldSquare.gridCellSizeForViewport(360), 64);
        expect(oldSquare.tokenSizeForViewport(64, 360), 64);
      },
    );

    testWidgets('Master opens a battle map from the real scene library', (
      tester,
    ) async {
      final (state, probe) = await mountFight(tester);
      state.updateOculumHomeUi(() {
        state.datiCaricati = true;
        state.linguaInglese = false;
      });
      final navigation = state.vaiAllaFunzione(page: 10) as Future<void>;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await navigation;

      final library = find.byKey(const ValueKey('vtt-bundled-maps'));
      expect(library, findsOneWidget);
      await tester.ensureVisible(library);
      Future<void> choosePostea() async {
        await tester.tap(library);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(ListTile), findsAtLeastNWidgets(6));
        await tester.tap(
          find.byKey(const ValueKey('vtt-board-postea_discarica')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
      }

      await choosePostea();
      final vtt = state.vttState as OculumVttState;
      expect(vtt.scenes, hasLength(2));
      expect(vtt.activeScene.bundledMap?.id, 'postea_discarica');
      expect(vtt.activeScene.gridType, 'hex');
      expect(vtt.activeScene.snapToGrid, isTrue);
      expect(state.localMapTokens, isEmpty);
      final sceneId = vtt.activeScene.id;
      vtt.activeScene.drawings.add({'id': 'annotation'});
      await choosePostea();
      expect(vtt.scenes, hasLength(2));
      expect(vtt.activeScene.id, sceneId);
      expect(vtt.activeScene.drawings.single['id'], 'annotation');

      final marker = <String, dynamic>{
        'id': 'test-map-token',
        'name': 'Pedina di prova',
        'x': 0.41,
        'y': 0.42,
        'size': 64,
        'shape': 'hex',
        'visible': true,
        'movementMaxMeters': 30,
      };
      state.updateOculumHomeUi(() => state.localMapTokens.add(marker));
      await tester.pump();
      final token = find.byKey(
        const ValueKey('vtt_local_token_test-map-token'),
      );
      final mapScroll = find
          .descendant(
            of: find.byKey(state.sheetScrollKey('map') as Key),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(token, 150, scrollable: mapScroll);
      await tester.pump();
      final mapImage = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                oculumVttBundledMaps.first.assetPath,
      );
      expect(mapImage, findsOneWidget);
      final board = tester.getSize(mapImage);
      expect(board.width / board.height, closeTo(1586 / 992, 0.0001));
      expect(tester.getSize(token).width, lessThan(35));
      final startingX = marker['x'] as double;
      await tester.drag(token, const Offset(68, 22));
      await tester.pump();
      expect(marker['x'], greaterThan(startingX));
      final position = Offset(
        (marker['x'] as num).toDouble() * board.width,
        (marker['y'] as num).toDouble() * board.height,
      );
      final snapped = oculumVttSnapPoint(
        position,
        gridType: 'hex',
        cellSize: vtt.activeScene.gridCellSizeForViewport(board.width),
      );
      expect((position - snapped).distance, lessThan(0.0001));

      state.updateOculumHomeUi(() => state.modalitaMaster = false);
      await tester.pump();
      expect(library, findsNothing);
      expect(tester.takeException(), isNull);
      await closeFixture(tester, probe);
    });

    testWidgets('new and legacy scene snapshots accept the same fallback', (
      tester,
    ) async {
      final (state, probe) = await mountFight(tester);
      state.modalitaMaster = false;
      final map = oculumVttBundledMaps.first;
      final scene = map.createScene(english: true, sortOrder: 0);
      final fallback = Uint8List.fromList(
        img.encodeJpg(img.Image(width: 8, height: 5)),
      );
      final base64 = base64Encode(fallback);
      final midpoint = base64.length ~/ 2;
      for (final withBundle in [true, false]) {
        final id = 'image-$withBundle';
        final payload = scene.toJson(includePrivate: false);
        if (!withBundle) payload.remove('imagePath');
        probe.receiveRealtime('vtt_scene_shared', {
          'senderRole': 'master',
          'id': id,
          'assetId': id,
          'assetChunkCount': 2,
          'snapshot': {'scene': payload},
        });
        final received = state.realtimeVisibleVttScene as OculumVttScene;
        expect(received.bundledMap, withBundle ? map : isNull);
        expect(received.gridType, 'hex');
        for (final (index, data) in [
          (1, base64.substring(midpoint)),
          (0, base64.substring(0, midpoint)),
        ]) {
          probe.receiveRealtime('vtt_asset_chunk', {
            'senderRole': 'master',
            'id': id,
            'assetId': id,
            'chunkCount': 2,
            'chunkIndex': index,
            'data': data,
          });
        }
        expect(state.realtimeVisibleVttImageBytes, orderedEquals(fallback));
      }
      await closeFixture(tester, probe);
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

    test('hex ruler and snapping use the rendered centres on all six axes', () {
      const diameter = 28.0;
      const radius = diameter / 2;
      final horizontal = math.sqrt(3) * radius;
      final neighbours = [
        Offset(horizontal, 0),
        Offset(horizontal / 2, radius * 1.5),
        Offset(-horizontal / 2, radius * 1.5),
        Offset(-horizontal, 0),
        Offset(-horizontal / 2, -radius * 1.5),
        Offset(horizontal / 2, -radius * 1.5),
      ];
      for (final target in neighbours) {
        final snapped = oculumVttSnapPoint(
          target + const Offset(0.5, -0.4),
          gridType: 'hex',
          cellSize: diameter,
        );
        expect((snapped - target).distance, lessThan(0.000001));
        expect(
          oculumVttDistanceCells(
            Offset.zero,
            snapped,
            gridType: 'hex',
            cellSize: diameter,
          ),
          closeTo(1, 0.000001),
        );
      }
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
