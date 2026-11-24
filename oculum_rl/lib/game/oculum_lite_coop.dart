import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'oculum_lite_run.dart';

typedef LiteCoopSend = Future<bool> Function(Map<String, dynamic> packet);

class OculumLiteCoop extends ChangeNotifier {
  OculumLiteCoop({
    required this.runId,
    required this.localAccount,
    required this.send,
    this.authority,
  }) : run = authority;

  final String runId;
  final String localAccount;
  final LiteRun? authority;
  final LiteCoopSend send;
  LiteRun? run;
  Timer? _timer;
  final _clock = Stopwatch();
  final _lastInput = <String, int>{};
  final _lastRestAction = <String, int>{};
  final _satSession = <String, String>{};
  final _watching = <String, double>{};
  final _confirmed = <String>{};
  bool _posting = false;
  bool _closed = false;
  int _counter = 0;
  int _remoteFrame = 0;
  double _timeOfStep = 0;
  double _timeOfSend = -1;
  double _timeOfFrame = -1;
  bool _fire = false;
  bool _dodge = false;
  bool _dash = false;
  bool _reload = false;
  bool _open = false;
  bool _rifleSkill = false;
  bool _weaponArt = false;
  bool _bomb = false;
  bool _blocking = false;
  bool _blockSent = false;
  bool _rescuing = false;
  bool _rescueSent = false;
  bool _rest = false;
  int _restCounter = 0;
  Map<String, Object>? _restAction;
  bool slowed = false;
  Point<double> move = const Point(0, 0);
  Point<double>? aim;
  LiteBiome? destination;
  int get readyCount => _confirmed.length;
  bool get host => authority != null;
  bool get pausedByHost =>
      !host &&
      _clock.isRunning &&
      _clock.elapsedMilliseconds / 1000 > _timeOfFrame + 3;
  bool get active => _timer != null;
  double get animationLead => host || _timeOfFrame < 0 || pausedByHost
      ? 0
      : (_clock.elapsedMilliseconds / 1000 - _timeOfFrame).clamp(0.0, .16) *
            (run?.arenaSpeed ?? 1);
  bool get canAct => host || run?.coopFighter(localAccount) != null;
  LiteCoopFighter? get localFighter => run?.coopFighter(localAccount);
  bool get canRescue => canAct && (run?.canRescueNearby(localFighter) ?? false);
  bool get canRest => canAct && (run?.canUseRest(localFighter) ?? false);
  LiteRescueStatus? get rescueStatus =>
      host ? run?.rescueStatus : localFighter?.rescueStatus;

  void start() {
    if (_closed || _timer != null) return;
    _clock.start();
    _timeOfStep = _clock.elapsedMilliseconds / 1000;
    _timer = Timer.periodic(const Duration(milliseconds: 20), (_) => _tick());
    if (!host) unawaited(_announce());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    move = const Point(0, 0);
    _fire = _dodge = _dash = _reload = _open = _rifleSkill = _bomb = _rest =
        false;
    _weaponArt = false;
    _restAction = null;
    setBlocking(false);
    setRescuing(false);
    _clock.stop();
  }

  void fire() {
    final world = authority;
    if (world != null) {
      world.attack(aim ?? world.position + const Point<double>(1, 0));
    } else if (canAct) {
      _fire = true;
    }
  }

  void talent() {
    final world = authority;
    if (world != null) {
      world.special(aim ?? world.position + const Point<double>(1, 0));
    } else if (canAct) {
      _dodge = true;
    }
  }

  void useOpen() {
    final world = authority;
    if (world != null) {
      world.useOpen(aim ?? world.position + const Point<double>(1, 0));
    } else if (canAct) {
      _open = true;
    }
  }

  void bomb() {
    final world = authority;
    if (world != null) {
      world.throwBanditBomb(aim ?? world.position + world.aim * 5);
    } else if (canAct) {
      _bomb = true;
    }
  }

  void weaponTechnique() {
    final world = authority;
    if (world != null) {
      world.useWeaponArt(aim ?? world.position + world.aim);
      notifyListeners();
    } else if (canAct) {
      _weaponArt = true;
    }
  }

  void rifleSkill() {
    final world = authority;
    if (world != null) {
      if (world.hero == LiteHero.reGoblin) {
        world.royalCall();
      } else if (world.hero == LiteHero.slimeBlu) {
        world.slimeDash(aim ?? world.position + world.aim);
      } else {
        world.banditRifleSkill();
      }
    } else if (canAct) {
      _rifleSkill = true;
    }
  }

  void setBlocking(bool held) {
    _blocking = held && canAct;
    authority?.setBlocking(_blocking);
  }

  void setRescuing(bool held) {
    _rescuing = held && canRescue && !pausedByHost;
    final world = authority;
    if (world == null) return;
    if (_rescuing) {
      world.beginRescue();
    } else {
      world.endRescue();
    }
  }

  void rest() {
    if (!canRest || pausedByHost) return;
    final world = authority;
    if (world != null) {
      world.useRest();
    } else {
      _rest = true;
    }
  }

  void reload() {
    final world = authority;
    if (world != null) {
      world.beginReload();
    } else if (canAct) {
      _reload = true;
    }
  }

  void dash() {
    final world = authority;
    if (world != null) {
      world.dash(aim ?? world.position + const Point<double>(1, 0));
    } else if (canAct) {
      _dash = true;
    }
  }

  bool nearPortal(String account) {
    final world = run;
    if (world == null || !world.coopPortalOpen) return false;
    final fighter = world.coopFighter(account);
    final at = fighter == null ? world.position : fighter.position;
    return world.portalPosition.distanceTo(at) < 2.2;
  }

  void enterSecondAct(LiteRealm realm) {
    if (authority?.enterSecondAct(realm) != true) return;
    destination = null;
    _confirmed.clear();
    notifyListeners();
  }

  bool advanceActTwo() {
    if (authority?.advanceActTwo() != true) return false;
    destination = null;
    _confirmed.clear();
    notifyListeners();
    return true;
  }

  bool solarInteraction() {
    final world = authority;
    if (world == null) return false;
    if (!world.enterSolarDungeon() && !world.enterSolarBoss()) return false;
    destination = null;
    _confirmed.clear();
    notifyListeners();
    return true;
  }

  void enterRestHub() {
    if (authority?.enterRestHub() != true) return;
    destination = null;
    _confirmed.clear();
    notifyListeners();
  }

  void buyRestItem(LiteRestItem item) => _orderRest('buy', item.name);
  void rememberRestItem(LiteRestItem item) => _orderRest('remember', item.name);
  void exchangeLunarPiece() => _orderRest('exchange', '');
  void castHostScroll(int slot) {
    final world = authority;
    if (world == null || world.restHub) return;
    world.castScroll(slot, aim ?? world.position + world.aim);
  }

  void useRestScroll(LiteScroll scroll) => _orderRest('scroll', scroll.name);

  void _orderRest(String kind, String item) {
    final world = authority;
    if (world != null) {
      _applyRest(world, kind, item, null, aim ?? world.aim);
      notifyListeners();
    } else if (canAct && _restAction == null) {
      _restAction = {'kind': kind, 'item': item, 'id': ++_restCounter};
    }
  }

  void _applyRest(
    LiteRun world,
    Object? kind,
    Object? id,
    LiteCoopFighter? fighter,
    Point<double> aim,
  ) {
    if (kind == 'exchange') {
      world.exchangeLunarPiece(fighter: fighter);
      return;
    }
    if (kind == 'scroll' && fighter != null) {
      final scroll = LiteScroll.values
          .where((value) => value.name == id)
          .firstOrNull;
      if (scroll != null) world.castRestScroll(scroll, aim, fighter);
      return;
    }
    final item = LiteRestItem.values
        .where((value) => value.name == id)
        .firstOrNull;
    if (item == null) return;
    if (kind == 'buy') world.buyRestItem(item, fighter: fighter);
    if (kind == 'remember') world.rememberRestItem(item, fighter: fighter);
  }

  void confirmPortal([LiteBiome? choice]) {
    if (!nearPortal(localAccount) || !canAct) return;
    if (host) {
      if (choice != null) _setDestination(choice);
      _confirmed.add(localAccount);
      _advanceIfReady();
    } else {
      unawaited(
        _transmit({
          'kind': 'playVote',
          'stage': run!.stage,
          'arena': run!.inputArena,
          'destination': destination?.name,
        }),
      );
    }
  }

  void _setDestination(LiteBiome choice) {
    if (choice != destination) _confirmed.clear();
    destination = choice;
  }

  void _advanceIfReady() {
    final world = authority;
    final next = destination;
    if (world == null || next == null || !_confirmed.contains(localAccount)) {
      return;
    }
    for (final fighter in world.coopFighters) {
      if (fighter.connected &&
          fighter.hp > 0 &&
          !_confirmed.contains(fighter.account)) {
        return;
      }
    }
    if (world.advanceCoop(next)) {
      destination = null;
      _confirmed.clear();
      _timeOfSend = -1;
    }
  }

  Future<bool> _transmit(Map<String, dynamic> packet) async {
    if (_closed) return false;
    try {
      return await send({'runId': runId, ...packet});
    } on Exception {
      return false;
    }
  }

  Future<bool> _announce() => _transmit({'kind': 'playJoin'});

  void _tick() {
    final now = _clock.elapsedMilliseconds / 1000;
    final world = authority;
    if (world != null) {
      final target = aim;
      if (target != null) world.lookAt(target);
      world.advanceFrame(
        (now - _timeOfStep).clamp(0.0, .12),
        move: move,
        walk: slowed,
      );
      _timeOfStep = now;
      _watching.removeWhere((_, at) => now - at > 4);
      if (_watching.isNotEmpty && now - _timeOfSend >= .16) {
        _timeOfSend = now;
        _publish(world);
      }
      notifyListeners();
      return;
    }

    final hasInput =
        move.magnitude > 0 ||
        _fire ||
        _dodge ||
        _dash ||
        _reload ||
        _open ||
        _rifleSkill ||
        _weaponArt ||
        _bomb ||
        _blocking ||
        _rescuing ||
        _rescuing != _rescueSent ||
        _rest ||
        _restAction != null ||
        _blocking != _blockSent;
    if (!_posting && now - _timeOfSend >= (hasInput ? .11 : .41)) {
      _timeOfSend = now;
      final state = run;
      final fighter = state?.coopFighter(localAccount);
      if (state != null && fighter != null && !state.finished) {
        final at = aim ?? fighter.position + const Point<double>(1, 0);
        final arena = state.inputArena;
        final packet = {
          'kind': 'playInput',
          'stage': state.stage,
          'arena': arena,
          'input': ++_counter,
          'move': [move.x, move.y],
          'aim': [at.x, at.y],
          'attack': _fire,
          'dodge': _dodge,
          'dash': _dash,
          'reload': _reload,
          if (_open) 'open': true,
          if (_rifleSkill) 'rifleSkill': true,
          if (_weaponArt) 'weaponArt': true,
          if (_bomb) 'bomb': true,
          'block': _blocking,
          if (_rescuing) 'rescue': true,
          if (_rest) 'rest': true,
          if (_restAction case final action?) 'restAction': action,
          'slow': slowed,
        };
        final wasFiring = _fire;
        final wasOpening = _open;
        final wasRifle = _rifleSkill;
        final wasWeaponArt = _weaponArt;
        _weaponArt = false;
        final wasBomb = _bomb;
        final wasBlocking = _blocking;
        final wasRescuing = _rescuing;
        final wasResting = _rest;
        final pendingRest = _restAction;
        _fire = _dodge = _dash = _reload = _open = _rifleSkill = _bomb = _rest =
            false;
        _posting = true;
        unawaited(
          _transmit(packet)
              .then((sent) {
                if (sent && run?.inputArena == arena) {
                  _blockSent = wasBlocking;
                  _rescueSent = wasRescuing;
                  if (identical(_restAction, pendingRest)) _restAction = null;
                }
                if (!sent && run?.inputArena == arena && active) {
                  _fire = _fire || wasFiring;
                  _open = _open || wasOpening;
                  _rifleSkill = _rifleSkill || wasRifle;
                  _weaponArt = _weaponArt || wasWeaponArt;
                  _bomb = _bomb || wasBomb;
                  _rest = _rest || wasResting;
                }
              })
              .whenComplete(() => _posting = false),
        );
      } else {
        unawaited(_announce());
      }
    }
    notifyListeners();
  }

  void _publish(LiteRun world) {
    if (_posting || _closed) return;
    _posting = true;
    unawaited(
      _transmit({
        'kind': 'playState',
        'frame': ++_counter,
        'world': world.toJson(includeEffects: true),
        'destination': destination?.name,
        'confirmed': _confirmed.length,
      }).whenComplete(() => _posting = false),
    );
  }

  void receive(
    Map<String, dynamic> packet, {
    required String account,
    required String sessionId,
    required bool verifiedMaster,
  }) {
    if (_closed || packet['runId'] != runId) return;
    final world = authority;
    if (world == null) {
      final frame = packet['frame'];
      final body = packet['world'];
      if (!verifiedMaster ||
          packet['kind'] != 'playState' ||
          frame is! int ||
          frame <= _remoteFrame ||
          body is! Map) {
        return;
      }
      try {
        final restored = LiteRun.fromJson(Map<String, dynamic>.from(body));
        if (restored.playerCount < 2 ||
            restored.coopFighters.length >= restored.playerCount) {
          return;
        }
        if (run?.inputArena != restored.inputArena) {
          _fire = _dodge = _dash = _reload = _open = _rifleSkill = _weaponArt =
              _bomb = false;
          _restAction = null;
          aim = null;
        }
        if (run?.inputArena != restored.inputArena ||
            (restored.coopFighter(localAccount)?.hp ?? 0) <= 0) {
          _rescuing = false;
          _rest = false;
        }
        run = restored;
        _remoteFrame = frame;
        _timeOfFrame = _clock.elapsedMilliseconds / 1000;
        destination = _biome(packet['destination']);
        notifyListeners();
      } on FormatException {
        return;
      } on TypeError {
        return;
      }
      return;
    }

    final now = _clock.elapsedMilliseconds / 1000;
    if (packet['kind'] == 'playJoin') {
      _watching[account] = now;
      if (active) _publish(world);
      return;
    }
    final fighter = world.coopFighter(account);
    if (fighter == null || packet['stage'] != world.stage) return;
    final arena = packet['arena'];
    if (arena != world.inputArena && !(arena == null && !world.usesSubArena)) {
      return;
    }
    final prior = _satSession[account];
    if (prior != sessionId) {
      if (prior != null &&
          fighter.connected &&
          now - (_watching[account] ?? -10) <= 1.1) {
        return;
      }
      _satSession[account] = sessionId;
      _lastInput.remove(account);
      _lastRestAction.remove(account);
    }
    if (packet['kind'] == 'playVote') {
      if (fighter.hp > 0 &&
          nearPortal(account) &&
          destination != null &&
          packet['destination'] == destination!.name) {
        _confirmed.add(account);
        _advanceIfReady();
        notifyListeners();
      }
      return;
    }
    final input = packet['input'];
    final direction = _vector(packet['move'], limit: 1.0);
    final target = _vector(packet['aim'], limit: 100.0);
    if (packet['kind'] != 'playInput' ||
        input is! int ||
        input <= (_lastInput[account] ?? 0) ||
        direction == null ||
        target == null) {
      return;
    }
    _lastInput[account] = input;
    _watching[account] = now;
    if (packet['restAction'] case final Map action) {
      final id = action['id'];
      if (id is int && id > (_lastRestAction[account] ?? 0)) {
        _lastRestAction[account] = id;
        _applyRest(world, action['kind'], action['item'], fighter, target);
      }
    }
    world.setCoopControls(
      account,
      direction,
      target,
      attack: packet['attack'] == true,
      dodge: packet['dodge'] == true,
      dash: packet['dash'] == true,
      reload: packet['reload'] == true,
      slow: packet['slow'] == true,
      open: packet['open'] == true,
      rifleSkill: packet['rifleSkill'] == true,
      weaponArt: packet['weaponArt'] == true,
      bomb: packet['bomb'] == true,
      block: packet['block'] == true,
      rescue: packet['rescue'] == true,
      rest: packet['rest'] == true,
    );
  }

  static Point<double>? _vector(Object? data, {required double limit}) {
    if (data is! List || data.length != 2) return null;
    final x = data[0], y = data[1];
    if (x is! num ||
        y is! num ||
        !x.isFinite ||
        !y.isFinite ||
        x.abs() > limit ||
        y.abs() > limit) {
      return null;
    }
    return Point(x.toDouble(), y.toDouble());
  }

  static LiteBiome? _biome(Object? name) =>
      LiteBiome.values.where((value) => value.name == name).firstOrNull;

  @override
  void dispose() {
    _closed = true;
    stop();
    super.dispose();
  }
}
