import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_coop.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/services/oculum_rl_cloud_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _live = bool.fromEnvironment('OculumRLLiveProof');
const _wormhole = bool.fromEnvironment('OculumRLWormholeLiveProof');
const _partySize = int.fromEnvironment(
  'OculumRLLivePartySize',
  defaultValue: 2,
);

Future<void> _until(bool Function() ready, String label) async {
  final limit = DateTime.now().add(const Duration(seconds: 18));
  while (!ready()) {
    if (DateTime.now().isAfter(limit)) throw StateError('Timeout: $label');
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  test(
    _wormhole
        ? '$_partySize authenticated clients return from the shared Desert Eye after host reconnect'
        : '$_partySize authenticated clients share authoritative combat and quests',
    () async {
      final clients = List.generate(
        _partySize,
        (_) => SupabaseClient(
          oculumDefaultSupabaseUrl,
          oculumDefaultSupabasePublishableKey,
        ),
      );
      addTearDown(() async {
        for (final client in clients) {
          await client.removeAllChannels();
          await client.dispose();
        }
      });
      await Future.wait(
        clients.map((client) => client.auth.signInAnonymously()),
      );
      final master = clients.first;
      final guest = clients.last;
      final owner = master.auth.currentUser!.id;
      final user = guest.auth.currentUser!.id;
      expect(owner, isNot(user));
      final code =
          'RLQA${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}';
      Future<Map> join(SupabaseClient client, bool host) async =>
          await client.rpc(
            'oculum_open_room',
            params: {
              'p_code': code,
              'p_name': host ? 'RL QA Master' : 'RL QA Player',
              'p_as_master': host,
            },
          ) as Map;
      final room = await join(master, true);
      expect(room['role'], 'master');
      for (final client in clients.skip(1)) {
        final pending = await join(client, false);
        expect(pending['roomId'], room['roomId']);
        if (pending['status'] != 'approved') {
          await master.rpc(
            'oculum_decide_room_member',
            params: {
              'p_room': room['roomId'],
              'p_user': client.auth.currentUser!.id,
              'p_allow': true,
              'p_role': 'player',
            },
          );
        }
      }
      for (var i = 0; i < _partySize; i++) {
        await clients[i].rpc(
          'oculum_touch_room_session',
          params: {
            'p_room': room['roomId'],
            'p_session': 'rl-qa-role-$i',
            'p_presence': {'playerName': 'RL QA $i'},
          },
        );
      }
      Future<Map?> checkpoint(
        SupabaseClient client,
        String session,
        String action, {
        int? epoch,
        Map<String, Object>? snapshot,
      }) async => await client.rpc(
        'oculum_rl_checkpoint',
        params: {
          'p_room': room['roomId'],
          'p_session': session,
          'p_action': action,
          if (epoch != null) 'p_epoch': epoch,
          if (snapshot != null) 'p_snapshot': snapshot,
        },
      ) as Map?;
      final claim = (await checkpoint(master, 'rl-qa-role-0', 'claim'))!;
      final epoch = claim['epoch'] as int;
      await expectLater(
        checkpoint(guest, 'rl-qa-role-${_partySize - 1}', 'claim'),
        throwsA(isA<PostgrestException>()),
      );
      final openInputs = <int>[];

      Future<bool> sendAs(
        SupabaseClient client,
        String session,
        Map<String, dynamic> packet,
      ) async =>
          await client.rpc(
            'oculum_rl_live',
            params: {
              'p_room': room['roomId'],
              'p_session': session,
              'p_packet': packet,
            },
          ) ==
          true;
      Future<bool> send(int i, Map<String, dynamic> packet) async {
        if (i == _partySize - 1 && packet['open'] == true) {
          openInputs.add(packet['input'] as int);
          if (openInputs.length == 1) return false;
        }
        return sendAs(clients[i], 'rl-qa-role-$i', packet);
      }

      final world = LiteRun(
        seed: _wormhole ? 130 : 711,
        explorationRoutes: _wormhole,
        biome: _wormhole ? LiteBiome.deserto : LiteBiome.campo,
        hero: LiteHero.evasore,
        weapon: LiteWeapon.arco,
        difficulty: LiteDifficulty.medio,
        playerCount: _partySize,
      );
      expect(
        world.monsterLifeMultiplier,
        closeTo(1 + .06 * (_partySize - 1), 1e-9),
      );
      for (final client in clients.skip(1)) {
        expect(
          world.addCoopFighter(
            client.auth.currentUser!.id,
            'RL QA Player',
            LiteHero.duplicatore,
            LiteWeapon.arco,
          ),
          isTrue,
        );
      }
      final foe = LiteEnemy(1000, LiteEnemyKind.slime, const Point(7.6, 11), 18)
        ..cooldown = 80;
      if (!_wormhole) {
        world.enemies
          ..clear()
          ..add(foe);
      }
      final hostSession = OculumLiteCoop(
        runId: code,
        localAccount: owner,
        authority: world,
        epoch: epoch,
        localSessionId: 'rl-qa-role-0',
        send: (packet) => send(0, packet),
      );
      final game = [
        hostSession,
        for (var i = 1; i < _partySize; i++)
          OculumLiteCoop(
            runId: code,
            localAccount: clients[i].auth.currentUser!.id,
            epoch: epoch,
            localSessionId: 'rl-qa-role-$i',
            send: (packet) => send(i, packet),
          ),
      ];
      final guestSession = game.last;
      for (final session in game) {
        addTearDown(session.dispose);
      }
      Future<void> subscribe(int i, SupabaseClient client) async {
        final ready = Completer<void>();
        client
            .channel(
              'oculum_secure_${room['roomId']}',
              opts: const RealtimeChannelConfig(private: true),
            )
            .onBroadcast(
              event: 'oculum_rl_live',
              callback: (wire) {
                final data = wire['payload'] is Map<String, dynamic>
                    ? wire['payload']
                    : wire;
                if (data['account'] is! String || data['session'] is! String)
                  return;
                if (i != 0 &&
                    data['kind'] == 'lobbySnapshot' &&
                    data['account'] == owner &&
                    data['role'] == 'master' &&
                    data['epoch'] is int) {
                  game[i].adoptAuthority(data['epoch'] as int);
                  return;
                }
                game[i].receive(
                  data,
                  account: data['account'] as String,
                  sessionId: data['session'] as String,
                  verifiedMaster:
                      data['role'] == 'master' && data['account'] == owner,
                );
              },
            )
            .subscribe((status, _) {
              if (status == RealtimeSubscribeStatus.subscribed &&
                  !ready.isCompleted)
                ready.complete();
            });
        await ready.future.timeout(const Duration(seconds: 12));
      }

      for (var i = 0; i < _partySize; i++) {
        await subscribe(i, clients[i]);
      }
      await expectLater(
        send(1, {'kind': 'playState', 'runId': code}),
        throwsA(isA<PostgrestException>()),
      );
      for (final session in game) {
        session.start();
      }
      await _until(
        () => game.every((session) => session.run != null),
        'all clients received floor 0',
      );
      expect(guestSession.run!.stage, 0);
      expect(guestSession.run!.coopFighter(user), isNotNull);
      if (_wormhole) {
        final sourceEnemyIds = world.enemies.map((enemy) => enemy.id).toList();
        final contact = world.coopFighter(user)!;
        final beforeHostLife = world.hp;
        final beforeContactLife = contact.hp;
        contact
          ..shield = 20
          ..position = world.desertEyePosition! + const Point<double>(1.4, 0);
        guestSession.move = const Point(-.7, 0);
        await _until(
          () => game.every(
            (session) => session.run?.inputArena == '0:occhio-divoratore',
          ),
          'the same Eye dimension on all clients',
        );
        for (final session in game) {
          expect(session.run!.desertEyeFortune, 10);
          expect(session.run!.desertEyeCut, 9);
          expect(session.run!.hp, beforeHostLife);
          expect(session.run!.coopFighter(user)!.hp, beforeContactLife);
          expect(session.run!.coopFighter(user)!.shield, 11);
          expect(session.run!.milestoneFloors, 0);
          expect(session.run!.obser, 0);
        }

        await checkpoint(
          master,
          'rl-qa-role-0',
          'save',
          epoch: epoch,
          snapshot: {
            'lobby': {'runId': code},
            'world': world.toJson(),
          },
        );
        hostSession.stop();
        await master.removeAllChannels();
        await _until(() => guestSession.pausedByHost, 'guest waits in Eye');

        final resumedClient = SupabaseClient(
          oculumDefaultSupabaseUrl,
          oculumDefaultSupabasePublishableKey,
        );
        addTearDown(() async {
          await resumedClient.removeAllChannels();
          await resumedClient.dispose();
        });
        await resumedClient.auth.setSession(
          master.auth.currentSession!.refreshToken!,
        );
        expect((await join(resumedClient, true))['roomId'], room['roomId']);
        const newSession = 'rl-qa-eye-recovered-master';
        await resumedClient.rpc(
          'oculum_touch_room_session',
          params: {
            'p_room': room['roomId'],
            'p_session': newSession,
            'p_presence': {'playerName': 'RL QA Master'},
          },
        );
        final taken = (await checkpoint(resumedClient, newSession, 'claim'))!;
        final resumed = LiteRun.fromJson(
          Map<String, dynamic>.from((taken['snapshot'] as Map)['world'] as Map),
        )..suspendCoopControls();
        expect(taken['epoch'], epoch + 1);
        expect(resumed.desertEyeFortune, 10);
        final resumedHost = OculumLiteCoop(
          runId: code,
          localAccount: owner,
          authority: resumed,
          localSessionId: newSession,
          epoch: epoch + 1,
          send: (data) => sendAs(resumedClient, newSession, data),
        );
        game[0] = resumedHost;
        addTearDown(resumedHost.dispose);
        await subscribe(0, resumedClient);
        resumedHost.start();
        await sendAs(resumedClient, newSession, {
          'kind': 'lobbySnapshot',
          'runId': code,
          'epoch': epoch + 1,
        });
        await _until(
          () => game
              .skip(1)
              .every(
                (session) =>
                    session.epoch == epoch + 1 &&
                    session.canAct &&
                    session.run?.desertEyeFortune == 10,
              ),
          'everyone rejoins the recovered Eye',
        );
        resumed.enemies.clear();
        resumed.position = resumed.portalPosition;
        for (final fighter in resumed.coopFighters) {
          fighter.position = resumed.portalPosition;
        }
        await _until(
          () =>
              resumed.coopFighters.every((fighter) => fighter.connected) &&
              resumedHost.nearPortal(owner) &&
              game
                  .skip(1)
                  .every((session) => session.nearPortal(session.localAccount)),
          'the return portal is open on all clients',
        );
        resumedHost.confirmPortal(resumed.biome);
        await _until(
          () => game.skip(1).every((session) => session.destination != null),
          'return vote delivered',
        );
        expect(resumed.inDesertEye, isTrue);
        for (final session in game.skip(1)) {
          session.confirmPortal();
        }
        await _until(
          () => game.every((session) => session.run?.inDesertEye == false),
          'everyone returned to the source floor',
        );
        expect(resumed.stage, 0);
        expect(resumed.stageClear, isFalse);
        expect(resumed.hp, beforeHostLife);
        expect(resumed.coopFighter(user)!.hp, beforeContactLife);
        expect(resumed.coopFighter(user)!.shield, 11);
        expect(resumed.enemies.map((enemy) => enemy.id), sourceEnemyIds);
        expect(resumed.obser, 5);
        expect(
          resumed.coopFighters.map((fighter) => fighter.obser),
          everyElement(5),
        );
        return;
      }
      guestSession.move = const Point(0, -.3);
      await _until(
        () => world.coopFighter(user)!.position.y < 11.75,
        'independent movement',
      );
      guestSession.move = const Point(0, 0);
      hostSession.aim = foe.position;
      hostSession.fire();
      await _until(() => foe.hp < foe.maxHp, 'host hit');
      expect(foe.hp, greaterThan(0));
      guestSession.aim = foe.position;
      guestSession.fire();
      await _until(() => foe.hp <= 0, 'remote hit');
      await _until(
        () => guestSession.run?.quests.first.current == 1,
        'shared kill and quest',
      );
      expect(world.enemies.any((enemy) => enemy.id == foe.id), isFalse);
      expect(guestSession.run!.coopFighter(user)!.experience, greaterThan(0));
      final guarding = world.coopFighter(user)!;
      world.obstacles.clear();
      world.fauna.clear();
      world.arenaTrial = null;
      world.position = const Point(14, 6);
      guarding.position = const Point(14, 16);
      final clockFoe = LiteEnemy(
        1551,
        LiteEnemyKind.costrutto,
        const Point(25, 11),
        500,
      )..cooldown = 100;
      world.enemies
        ..clear()
        ..add(clockFoe);
      const right = Point<double>(1, 0);
      const stopped = Point<double>(0, 0);
      hostSession.move = right;
      guestSession.move = right;
      await _until(() => guarding.movement == right, 'movement reaches Master');

      // Sample the authoritative frames after the guest's real Open input.
      // Measuring network arrival intervals would factor in Realtime latency.
      final motion =
          Completer<({double host, double guest, double foe, double clock})>();
      ({
        double remaining,
        double time,
        double hostX,
        double guestX,
        double foeTravel,
      })?
      firstOpenFrame;
      void measureOpenMotion() {
        final scene = world.openScene;
        if (motion.isCompleted ||
            scene == null ||
            scene.actorId != guarding.id) {
          return;
        }
        final first = firstOpenFrame ??= (
          remaining: scene.remaining,
          time: world.time,
          hostX: world.position.x,
          guestX: guarding.position.x,
          foeTravel: clockFoe.stride.distance,
        );
        final elapsed = (first.remaining - scene.remaining) * world.arenaSpeed;
        if (elapsed < .06) return;
        motion.complete((
          host: (world.position.x - first.hostX) / (6.5 * elapsed),
          guest: (guarding.position.x - first.guestX) / (6.5 * elapsed),
          foe:
              (clockFoe.stride.distance - first.foeTravel) /
              (clockFoe.kind.speed * elapsed),
          clock: (world.time - first.time) / elapsed,
        ));
      }

      hostSession.addListener(measureOpenMotion);
      guestSession.useOpen();
      try {
        final speed = await motion.future.timeout(const Duration(seconds: 18));
        expect(speed.host, closeTo(.26, .004), reason: 'Master movement');
        expect(speed.guest, closeTo(.26, .004), reason: 'caster movement');
        expect(speed.foe, closeTo(.24, .004), reason: 'enemy movement');
        expect(speed.clock, closeTo(.24, .004), reason: 'arena clock');
      } finally {
        hostSession.removeListener(measureOpenMotion);
        hostSession.move = stopped;
        guestSession.move = stopped;
      }
      expect(world.openProtects(guarding.id), isTrue);
      expect(world.openProtects(0), isFalse);
      final masterHp = world.hp;
      final casterHp = guarding.hp;
      LiteProjectile incoming(Point<double> at) => LiteProjectile(
        position: at - const Point(.14, 0),
        direction: right,
        speed: 24,
        remaining: 3,
        damage: 12,
        fromEnemy: true,
      );
      final casterShot = incoming(guarding.position);
      final masterShot = incoming(world.position);
      // The Open spawns two allies. Count and clear them so
      // they cannot step in front of this test's shots.
      final summonedAllies = world.clones
          .where((clone) => clone.ownerId == guarding.id)
          .toList();
      expect(summonedAllies, hasLength(2));
      world.clones.removeWhere(summonedAllies.contains);
      world.projectiles.addAll([casterShot, masterShot]);
      await _until(
        () =>
            casterShot.remaining == 0 &&
            masterShot.remaining == 0 &&
            world.hp < masterHp,
        'both Open-time shots reached their targets',
      );
      expect(world.openProtects(guarding.id), isTrue);
      expect(guarding.hp, casterHp);
      await _until(
        () =>
            guestSession.run!.coopFighter(user)!.openCooldown > 0 &&
            guestSession.run!.hp == world.hp &&
            guestSession.run!.coopFighter(user)!.hp == casterHp,
        'guest receives the Open and the selective damage',
      );
      expect(world.coopFighter(user)!.oculum, 5);
      expect(openInputs.length, greaterThanOrEqualTo(2));
      expect(openInputs.toSet(), hasLength(1));
      expect(world.oculum, world.maxOculum);
      await _until(
        () => world.openScene == null && guestSession.run?.openScene == null,
        'Open finished on both clients before guard',
      );
      guestSession.setBlocking(true);
      await _until(
        () => guestSession.run!.coopFighter(user)!.blocking,
        'remote guard held',
      );
      world.projectiles.add(
        LiteProjectile(
          position: guarding.position,
          direction: const Point(1, 0),
          speed: 10,
          remaining: 2,
          damage: 23,
          fromEnemy: true,
        ),
      );
      await _until(
        () => guestSession.run!.coopFighter(user)!.blockResistance == 77,
        'remote guard absorption broadcast',
      );
      expect(guarding.blockResistance, 77);
      guestSession.setBlocking(false);
      await _until(
        () => !guestSession.run!.coopFighter(user)!.blocking,
        'remote guard released',
      );
      world.position = guarding.position + const Point(0, 1);
      world.hp = 0;
      await _until(
        () => guestSession.canRescue,
        'guest sees the downed Master',
      );
      expect(guarding.arrows, lessThan(LiteRun.bowCapacity));
      guestSession.setRescuing(true);
      await _until(
        () => guestSession.rescueStatus?.reload == true,
        'remote hold and combined reload broadcast',
      );
      await _until(() => guestSession.run!.hp == 30, 'Master revived by guest');
      guestSession.setRescuing(false);
      expect(guarding.arrows, LiteRun.bowCapacity);

      world.enemies.clear();
      world.stageClear = true;
      guarding
        ..position = world.restPosition
        ..hp = 20
        ..oculum = 2;
      await _until(() => guestSession.canRest, 'guest sees available Ristoro');
      guestSession.rest();
      await _until(
        () => guestSession.run!.coopFighter(user)!.restUsed,
        'remote Ristoro broadcast',
      );
      expect(guarding.hp, 70);
      expect(guarding.oculum, 4.5);
      expect(world.restUsed, isFalse);
      expect(
        game.every((session) => session.run!.playerCount == _partySize),
        isTrue,
      );

      // The first transport closes; the same account creates an independent
      // Supabase client and restores the stored authoritative world.
      world.obser = 47;
      guarding.obser = 47;
      await checkpoint(
        master,
        'rl-qa-role-0',
        'save',
        epoch: epoch,
        snapshot: {
          'lobby': {'runId': code},
          'world': world.toJson(),
        },
      );
      final readAsGuest = await checkpoint(
        guest,
        'rl-qa-role-${_partySize - 1}',
        'read',
      );
      expect(readAsGuest!['snapshot'], isNull);
      hostSession.stop();
      await master.removeAllChannels();
      await _until(
        () => guestSession.pausedByHost,
        'guest pauses without Master',
      );

      final resumedClient = SupabaseClient(
        oculumDefaultSupabaseUrl,
        oculumDefaultSupabasePublishableKey,
      );
      addTearDown(() async {
        await resumedClient.removeAllChannels();
        await resumedClient.dispose();
      });
      await resumedClient.auth.setSession(
        master.auth.currentSession!.refreshToken!,
      );
      expect(resumedClient.auth.currentUser!.id, owner);
      final reopened = await join(resumedClient, true);
      expect(reopened['roomId'], room['roomId']);
      expect(reopened['role'], 'master');
      const resumedId = 'rl-qa-recovered-master';
      await resumedClient.rpc(
        'oculum_touch_room_session',
        params: {
          'p_room': room['roomId'],
          'p_session': resumedId,
          'p_presence': {'playerName': 'RL QA Master'},
        },
      );
      final taken = (await checkpoint(resumedClient, resumedId, 'claim'))!;
      expect(taken['epoch'], epoch + 1);
      final snapshot = taken['snapshot'] as Map;
      final resumed = LiteRun.fromJson(
        Map<String, dynamic>.from(snapshot['world'] as Map),
      )..suspendCoopControls();
      await expectLater(
        sendAs(master, 'rl-qa-role-0', {
          'kind': 'playState',
          'runId': code,
          'epoch': epoch,
        }),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        checkpoint(
          master,
          'rl-qa-role-0',
          'save',
          epoch: epoch,
          snapshot: {
            'lobby': {'runId': code},
            'world': world.toJson(),
          },
        ),
        throwsA(isA<PostgrestException>()),
      );
      final replacement = OculumLiteCoop(
        runId: code,
        localAccount: owner,
        authority: resumed,
        localSessionId: resumedId,
        epoch: epoch + 1,
        send: (data) => sendAs(resumedClient, resumedId, data),
      );
      game[0] = replacement;
      addTearDown(replacement.dispose);
      await subscribe(0, resumedClient);
      replacement.start();
      await sendAs(resumedClient, resumedId, {
        'kind': 'lobbySnapshot',
        'runId': code,
        'epoch': epoch + 1,
      });
      await _until(
        () => game
            .skip(1)
            .every(
              (session) => session.epoch == epoch + 1 && !session.pausedByHost,
            ),
        'same run resumes on every guest',
      );
      expect(resumed.stage, world.stage);
      expect(guestSession.run!.obser, 47);
      expect(guestSession.run!.coopFighter(user)!.obser, 47);
      expect(guestSession.run!.coopFighter(user)!.restUsed, isTrue);
      final before = resumed.coopFighter(user)!.position.x;
      guestSession.move = const Point(-1, 0);
      await _until(
        () => resumed.coopFighter(user)!.position.x < before - .2,
        'controls reach the new master',
      );
      guestSession.move = const Point(0, 0);
      expect(resumed.obser, 47);
    },
    skip: !_live && !_wormhole,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
