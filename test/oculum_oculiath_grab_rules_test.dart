import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_oculiath_rules.dart';
import 'package:oculum/main.dart' show OculumAnatomicalPartsProbe;

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  for (final monsterId in [oculumOculiathId, oculumLesserOculiathId]) {
    testWidgets('$monsterId spends one action and carries a local sheet', (
      tester,
    ) async {
      final (state, probe) = await mountFight(tester);
      final carrierTag = probe.ownerTag();
      final carrierSheet = probe.snapshot()
        ..['monsterBookSourceId'] = monsterId
        ..['volonta'] = '10'
        ..['currentVolonta'] = '10';
      state.schedePersonaggio[0] = carrierSheet;
      probe.load(carrierSheet);
      final riderSheet = {
        ...carrierSheet,
        'monsterBookSourceId': '',
        'id': 'OTHER',
        'sheetTag': 'OTHER',
        'nome': 'Bersaglio',
        'volonta': '5',
        'currentVolonta': '5',
      };
      state.schedePersonaggio.add(riderSheet);
      probe.ensureSheetTags();
      final riderTag = '${state.schedePersonaggio[1]['sheetTag']}';
      final carrier =
          state.masterInitiativeTokens.first as Map<String, dynamic>;
      final rider = state.masterInitiativeTokens.last as Map<String, dynamic>;
      rider['sheetTag'] = rider['id'] = riderTag;
      rider['name'] = 'Bersaglio';
      carrier['mapTokenId'] = 'hook-carrier';
      rider['mapTokenId'] = 'hook-rider';
      expect(carrier['sheetTag'], carrierTag);
      final carrierMap = <String, dynamic>{
        'id': 'hook-carrier',
        'x': .4,
        'y': .5,
        'elevationMeters': 2.0,
      };
      final riderMap = <String, dynamic>{
        'id': 'hook-rider',
        'x': .4,
        'y': .5,
        'elevationMeters': 2.0,
      };
      state.localMapTokens.addAll([carrierMap, riderMap]);
      final picking = probe.pickOculiathTarget();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final action = find.text('Bersaglio · Azione');
      expect(action, findsOneWidget);
      await tester.tap(action);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.runAsync(() async => await picking);
      expect(carrier['actionUsed'], true);
      expect(carrier['oculiathHold'], isA<Map>());
      Map<String, dynamic> liveMap(String id) =>
          (state.localMapTokens as List<Map<String, dynamic>>).singleWhere(
            (token) => token['id'] == id,
          );
      final liveCarrier = liveMap('hook-carrier');
      final liveRider = liveMap('hook-rider');
      expect(probe.isOculiathPassenger(liveRider), true);
      liveCarrier['x'] = .6;
      liveCarrier['elevationMeters'] = 8.0;
      expect(probe.moveOculiathPassenger(liveCarrier), true);
      expect(liveRider['x'], .6);
      expect(liveRider['elevationMeters'], 8.0);
      final hookBreaks = monsterId == oculumLesserOculiathId;
      if (hookBreaks) {
        await probe.anatomicalTargetHit(
          {
            'id': 'break-oculiath-hook',
            'sourceTag': 'ENEMY',
            'targetTag': carrierTag,
            'targetBodyPart': 'hook',
            'scope': probe.permissionScope,
            'encounterId': probe.activeCombatEncounterId,
          },
          hpLost: 1000,
          critical: false,
        );
      } else {
        await probe.releaseOculiathForTest(carrier, safeLanding: true);
      }
      expect(carrier['oculiathHold'], isNull);
      expect(probe.isOculiathPassenger(liveMap('hook-rider')), false);
      expect(liveMap('hook-rider')['elevationMeters'], 2.0);
      expect(liveMap('hook-carrier')['elevationMeters'], 8.0);
      final saved = state.schedePersonaggio[1] as Map;
      expect(
        saved['logEventi'].toString(),
        contains(hookBreaks ? '[CADUTA] 6.0 m' : 'Atterri in piedi da 6.0 m'),
      );
      if (hookBreaks) {
        expect(saved['logEventi'].toString(), contains('L’uncino si rompe.'));
      }
      await closeFixture(tester, probe);
    });
  }

  test(
    'only a free intact Oculiath hook can grab a weaker target in contact',
    () {
      bool canGrab({
        String monster = oculumOculiathId,
        int carrierWill = 9,
        int targetWill = 8,
        bool inContact = true,
        bool hookIntact = true,
        bool hasPassenger = false,
      }) => oculumOculiathCanGrab(
        monsterId: monster,
        carrierCurrentWill: carrierWill,
        targetCurrentWill: targetWill,
        inContact: inContact,
        hookIntact: hookIntact,
        hasPassenger: hasPassenger,
      );

      expect(canGrab(), isTrue);
      expect(canGrab(monster: '${oculumOculiathId}_variante_errante'), isTrue);
      expect(canGrab(monster: oculumLesserOculiathId), isTrue);
      expect(
        canGrab(monster: '${oculumLesserOculiathId}_variante_errante'),
        isTrue,
      );
      expect(
        canGrab(monster: oculumLesserOculiathId, hookIntact: false),
        isFalse,
      );
      expect(canGrab(carrierWill: 1, targetWill: 0), isTrue);
      expect(canGrab(targetWill: 9), isFalse);
      expect(canGrab(targetWill: 10), isFalse);
      expect(canGrab(targetWill: -1), isFalse);
      expect(canGrab(inContact: false), isFalse);
      expect(canGrab(hookIntact: false), isFalse);
      expect(canGrab(hasPassenger: true), isFalse);
      expect(canGrab(monster: oculumGreaterOculiathId), isFalse);
      expect(canGrab(monster: 'oculiath_custom'), isFalse);
    },
  );

  test(
    'fall uses net movement and the elevation of the destination surface',
    () {
      final elevation = oculumOculiathCarriedElevation(
        initialElevationMeters: 2,
        verticalMovementMeters: [5, 3.5, 0, -2.5],
      );
      expect(elevation, 8);
      expect(
        oculumOculiathFallDistance(
          elevationMeters: elevation!,
          surfaceElevationMeters: 3,
        ),
        5,
      );
      expect(
        oculumOculiathFallDistance(
          elevationMeters: elevation,
          surfaceElevationMeters: -4,
        ),
        12,
      );
      expect(
        oculumOculiathFallDistance(
          elevationMeters: elevation,
          surfaceElevationMeters: elevation + 1,
        ),
        0,
      );
    },
  );

  test(
    'fall uses the starting height even without movement after the grab',
    () {
      expect(
        oculumOculiathCarriedElevation(
          initialElevationMeters: -2,
          verticalMovementMeters: [],
        ),
        -2,
      );
      expect(
        oculumOculiathFallDistance(
          elevationMeters: -2,
          surfaceElevationMeters: -10,
        ),
        8,
      );
    },
  );

  test('invalid or overflowing heights do not produce a fall distance', () {
    expect(
      oculumOculiathCarriedElevation(
        initialElevationMeters: double.nan,
        verticalMovementMeters: [],
      ),
      isNull,
    );
    expect(
      oculumOculiathCarriedElevation(
        initialElevationMeters: 2,
        verticalMovementMeters: [double.infinity],
      ),
      isNull,
    );
    expect(
      oculumOculiathCarriedElevation(
        initialElevationMeters: 1e308,
        verticalMovementMeters: [1e308],
      ),
      isNull,
    );
    expect(
      oculumOculiathFallDistance(
        elevationMeters: 2,
        surfaceElevationMeters: double.negativeInfinity,
      ),
      isNull,
    );
    expect(
      oculumOculiathFallDistance(
        elevationMeters: 1e308,
        surfaceElevationMeters: -1e308,
      ),
      isNull,
    );
  });
}
