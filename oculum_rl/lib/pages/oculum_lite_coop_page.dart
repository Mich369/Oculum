import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/oculum_lite_coop.dart';
import '../game/oculum_lite_run.dart';
import '../widgets/oculum_lite_arena.dart';
import '../widgets/oculum_lite_routes.dart';
import '../widgets/oculum_lite_rest_panel.dart';

class OculumLiteCoopPage extends StatefulWidget {
  const OculumLiteCoopPage({
    super.key,
    required this.session,
    this.hostAppearance,
    this.guestAppearances = const {},
  });
  final OculumLiteCoop session;
  final OculumLiteAppearance? hostAppearance;
  final Map<String, OculumLiteAppearance> guestAppearances;

  @override
  State<OculumLiteCoopPage> createState() => _OculumLiteCoopPageState();
}

class _OculumLiteCoopPageState extends State<OculumLiteCoopPage> {
  final _focus = FocusNode(debugLabel: 'Oculum RL cooperativa');
  final _held = <LogicalKeyboardKey>{};
  Point<double> _touch = const Point(0, 0);
  OculumLiteCoop get _session => widget.session;

  @override
  void initState() {
    super.initState();
    _session.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _session.stop();
    _focus.dispose();
    super.dispose();
  }

  void _setMove() {
    int held(LogicalKeyboardKey key, LogicalKeyboardKey arrow) =>
        _held.contains(key) || _held.contains(arrow) ? 1 : 0;
    _session.move = Point(
      (_touch.x +
              held(LogicalKeyboardKey.keyD, LogicalKeyboardKey.arrowRight) -
              held(LogicalKeyboardKey.keyA, LogicalKeyboardKey.arrowLeft))
          .clamp(-1.0, 1.0),
      (_touch.y +
              held(LogicalKeyboardKey.keyS, LogicalKeyboardKey.arrowDown) -
              held(LogicalKeyboardKey.keyW, LogicalKeyboardKey.arrowUp))
          .clamp(-1.0, 1.0),
    );
    _session.slowed =
        _held.contains(LogicalKeyboardKey.controlLeft) ||
        _held.contains(LogicalKeyboardKey.controlRight);
  }

  void _clear() {
    _held.clear();
    _touch = const Point(0, 0);
    _session.setBlocking(false);
    _session.setRescuing(false);
    _setMove();
  }

  LiteHero? get _localHero {
    final run = _session.run;
    return _session.host
        ? run?.hero
        : run?.coopFighter(_session.localAccount)?.hero;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyF) {
      if (event is KeyUpEvent || event is KeyDownEvent) {
        _session.setBlocking(event is KeyDownEvent && !_session.pausedByHost);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR) {
      if (event is KeyUpEvent) {
        _session.setRescuing(false);
      } else if (event is KeyDownEvent && !_session.pausedByHost) {
        if (_session.canRescue) {
          _session.setRescuing(true);
        } else {
          _interact();
        }
      }
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) _held.remove(key);
    if (event is KeyDownEvent) _held.add(key);
    _setMove();
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.space) {
      _session.useOpen();
    } else if (key == LogicalKeyboardKey.keyQ &&
        (_localHero == LiteHero.slimeBlu || _localHero == LiteHero.reGoblin)) {
      _session.rifleSkill();
    } else if (key == LogicalKeyboardKey.keyV) {
      _session.talent();
    } else if (key == LogicalKeyboardKey.keyB &&
        _localHero == LiteHero.scostubandito) {
      _session.bomb();
    } else if (key == LogicalKeyboardKey.keyG &&
        _localHero == LiteHero.scostubandito) {
      _session.rifleSkill();
    } else if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      _session.dash();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _interact() async {
    if (_session.solarInteraction() || _session.advanceActTwo()) return;
    if (_session.host && (_session.run?.canChooseActTwo ?? false)) {
      _clear();
      final realm = await chooseLiteSecondAct(context);
      if (mounted && realm != null) _session.enterSecondAct(realm);
      if (mounted) _focus.requestFocus();
      return;
    }
    if (_session.canRest) {
      _session.rest();
      return;
    }
    if (!_session.nearPortal(_session.localAccount)) {
      _session.reload();
      return;
    }
    if (!_session.host) {
      _session.confirmPortal();
      return;
    }
    final run = _session.run;
    if (run == null) return;
    if (run.awaitsRestHub) {
      _session.enterRestHub();
      return;
    }
    final next = await chooseOculumLiteRoute(context, run);
    if (!mounted || next == null) return;
    _session.confirmPortal(next);
    _focus.requestFocus();
  }

  Future<void> _openRelics(LiteRun run) async {
    _clear();
    await showLiteActRelics(
      context,
      run,
      take: run.takeActRelic,
      move: run.moveActRelic,
    );
    if (mounted) _focus.requestFocus();
  }

  Future<void> _openBotteghe() async {
    _clear();
    await showLiteRestHub(
      context,
      world: () => _session.run,
      fighter: () => _session.localFighter,
      refresh: _session,
      buy: _session.buyRestItem,
      remember: _session.rememberRestItem,
      exchange: _session.exchangeLunarPiece,
    );
    if (mounted) _focus.requestFocus();
  }

  Widget _rescueControl(LiteRescueStatus? status) {
    final progress = ((status?.progress ?? 0) * 100).floor();
    final label = status == null
        ? 'Tieni premuto per soccorrere · R'
        : status.paused
        ? 'Soccorso interrotto · $progress%'
        : '${status.reload ? 'Soccorso e ricarica' : 'Soccorso'} · $progress%';
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _session.setRescuing(true),
      onPointerUp: (_) => _session.setRescuing(false),
      onPointerCancel: (_) => _session.setRescuing(false),
      child: Chip(
        avatar: const Icon(Icons.health_and_safety_outlined),
        label: Text(label),
      ),
    );
  }

  Future<void> _choosePower(LiteRun run) async {
    final floor = run.stage;
    _clear();
    final choice = await chooseOculumLitePower(context, run);
    if (!mounted) return;
    if (choice != null && run.stage == floor) run.choosePowerUp(choice);
    _focus.requestFocus();
  }

  Widget _movePad() => SizedBox.square(
    dimension: 110,
    child: LayoutBuilder(
      builder: (context, limits) {
        void set(Offset at) {
          final offset = at - limits.biggest.center(Offset.zero);
          _touch = Point(
            (offset.dx / 36).clamp(-1.0, 1.0),
            (offset.dy / 36).clamp(-1.0, 1.0),
          );
          _setMove();
        }

        void release() {
          _touch = const Point(0, 0);
          _setMove();
        }

        return Listener(
          onPointerDown: (event) => set(event.localPosition),
          onPointerMove: (event) => set(event.localPosition),
          onPointerUp: (_) => release(),
          onPointerCancel: (_) => release(),
          child: const Material(
            color: Color(0xac24232b),
            shape: CircleBorder(side: BorderSide(color: Color(0xff957554))),
            child: Icon(
              Icons.control_camera,
              color: Color(0xffe3c58e),
              size: 44,
            ),
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Oculum RL · Cooperativa')),
    body: Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      onFocusChange: (focused) {
        if (!focused) _clear();
      },
      child: AnimatedBuilder(
        animation: _session,
        builder: (context, _) {
          final run = _session.run;
          if (run == null) {
            return const Center(
              child: Text('Caricamento della partita del Master…'),
            );
          }
          final mine = run.coopFighter(_session.localAccount);
          final hero = _localHero;
          final openRecovery = mine?.openCooldown ?? run.openCooldown;
          final openGrade = mine?.openGrade ?? run.openGrade;
          final down = _session.host ? run.hostDown : mine?.hp == 0;
          final rescueStatus = _session.rescueStatus;
          final playing =
              _session.canAct &&
              !down &&
              !run.finished &&
              !_session.pausedByHost;
          return LayoutBuilder(
            builder: (context, limits) => Stack(
              fit: StackFit.expand,
              children: [
                OculumLiteArena(
                  run: run,
                  animationLead: _session.animationLead,
                  appearance: widget.hostAppearance,
                  guestAppearances: widget.guestAppearances,
                  focusAccount: mine?.account,
                  onAim: (at) => _session.aim = at,
                  onAttack: playing
                      ? (_) {
                          _focus.requestFocus();
                          _session.fire();
                        }
                      : null,
                  onTalent: playing
                      ? (_) {
                          _focus.requestFocus();
                          _session.talent();
                        }
                      : null,
                ),
                Positioned(
                  top: 6,
                  left: 8,
                  right: 8,
                  child: Card(
                    color: const Color(0xe6211820),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 3,
                        children: [
                          Text(
                            'Piano ${run.stage} · ${run.biome.label}'
                            '${run.arenaSpeed > 1 ? ' · Ritmo +${LiteRun.arenaSpeedBonusAt(run.stage)}%' : ''}',
                          ),
                          Text(
                            '${run.playerCount} · Vita mostri ×${run.monsterLifeMultiplier.toStringAsFixed(2)}',
                          ),
                          Text(
                            '${mine?.weapon.label ?? run.weapon.label} · Vita ${(mine?.hp ?? run.hp).ceil()}',
                          ),
                          Text('Livello ${mine?.level ?? run.level}'),
                          Text(
                            'Oculum ${(mine?.oculum ?? run.oculum).floor()}'
                            '/${(mine?.maxOculum ?? run.maxOculum).floor()}',
                          ),
                          if ((mine?.weapon ?? run.weapon) == LiteWeapon.arco)
                            Text('Frecce ${mine?.arrows ?? run.arrows}'),
                          if (hero == LiteHero.scostubandito) ...[
                            Text(
                              'Colpi infusi ${mine?.banditRounds ?? run.banditRounds}',
                            ),
                            if (mine?.banditDodgeReady ?? run.banditDodgeReady)
                              const Text('Prossimo scatto intangibile'),
                          ],
                          if (_session.destination case final next?)
                            Text('Portale · ${next.label}'),
                          for (final quest in run.missions)
                            Text(
                              '${quest.name} ${quest.current}/${quest.target}',
                            ),
                          OculumLiteCompanionStatus(run: run),
                          OculumLiteTrialStatus(run: run),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_session.pausedByHost ||
                    run.finished ||
                    !_session.canAct ||
                    down)
                  Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _session.pausedByHost
                              ? 'Partita sospesa. In attesa del Master.'
                              : !_session.canAct
                              ? 'Osservatore · Guarda lo scontro del gruppo.'
                              : down && !run.finished
                              ? 'Sei a terra. Un alleato può soccorrerti con R.'
                              : run.message,
                        ),
                      ),
                    ),
                  ),
                if (playing)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (limits.maxWidth < 720)
                          _movePad()
                        else
                          const SizedBox(),
                        Flexible(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            alignment: WrapAlignment.end,
                            children: [
                              if (limits.maxWidth < 720) ...[
                                FilledButton.tonal(
                                  onPressed: _session.fire,
                                  child: const Text('Attacca'),
                                ),
                                FilledButton.tonal(
                                  onPressed: _session.talent,
                                  child: Text(hero?.talentName ?? 'Talento'),
                                ),
                                FilledButton.tonal(
                                  onPressed: _session.dash,
                                  child: const Text('Scatto'),
                                ),
                              ],
                              if (hero != null)
                                FilledButton.tonal(
                                  onPressed:
                                      openRecovery > 0 ||
                                          (mine?.oculum ?? run.oculum) <
                                              LiteRun.granSummonCost
                                      ? null
                                      : _session.useOpen,
                                  child: Text(
                                    openRecovery > 0
                                        ? 'Open $openGrade · ${openRecovery.ceil()} s'
                                        : 'Open $openGrade · ${hero.openName}',
                                  ),
                                ),
                              if (hero == LiteHero.reGoblin)
                                FilledButton.tonal(
                                  onPressed: _session.rifleSkill,
                                  child: const Text('Richiamo reale · Q'),
                                ),
                              if (hero == LiteHero.slimeBlu)
                                FilledButton.tonal(
                                  onPressed: _session.rifleSkill,
                                  child: const Text('Scia invisibile · Q'),
                                ),
                              if (hero == LiteHero.scostubandito)
                                FilledButton.tonal(
                                  onPressed: _session.rifleSkill,
                                  child: const Text('Fucile schivata · G'),
                                ),
                              if (hero == LiteHero.reGoblin)
                                FilledButton.tonal(
                                  onPressed: _session.rifleSkill,
                                  child: const Text('Richiamo reale · Q'),
                                ),
                              if (hero == LiteHero.slimeBlu)
                                FilledButton.tonal(
                                  onPressed: _session.rifleSkill,
                                  child: const Text('Scia invisibile · Q'),
                                ),
                              if (hero == LiteHero.scostubandito)
                                FilledButton.tonal(
                                  onPressed:
                                      (mine?.bombCooldown ?? run.bombCooldown) >
                                          0
                                      ? null
                                      : _session.bomb,
                                  child: const Text('Bomba · B'),
                                ),
                              OculumLiteBlockControl(
                                resistance:
                                    mine?.blockResistance ??
                                    run.blockResistance,
                                capacity:
                                    mine?.maxBlockResistance ??
                                    run.maxBlockResistance,
                                active: mine?.blocking ?? run.blocking,
                                onHeld: _session.setBlocking,
                              ),
                              if (_session.host && run.powerOffers.isNotEmpty)
                                FilledButton.tonal(
                                  onPressed: () => _choosePower(run),
                                  child: const Text('Potenziamento squadra'),
                                ),
                              if (_session.host &&
                                  (run.canClaimActRelic ||
                                      run.actRelics.isNotEmpty))
                                FilledButton.tonal(
                                  onPressed: () => _openRelics(run),
                                  child: const Text('Reliquie'),
                                ),
                              if (run.restHub && _session.canAct)
                                FilledButton.tonal(
                                  onPressed: _openBotteghe,
                                  child: const Text('Botteghe'),
                                ),
                              if (_session.host)
                                for (final slot in [0, 1, 2, 3])
                                  if (run.scrolls[run
                                          .equippedScrolls[slot]
                                          .index] >
                                      0)
                                    FilledButton.tonal(
                                      onPressed: () =>
                                          _session.castHostScroll(slot),
                                      child: Text(
                                        run.equippedScrolls[slot].label,
                                      ),
                                    ),
                              if (mine != null)
                                for (final entry in mine.supply.scrolls.entries)
                                  if (entry.value > 0)
                                    FilledButton.tonal(
                                      onPressed: () =>
                                          _session.useRestScroll(entry.key),
                                      child: Text(entry.key.label),
                                    ),
                              if (_session.canRescue || rescueStatus != null)
                                _rescueControl(rescueStatus)
                              else
                                FilledButton(
                                  onPressed: _interact,
                                  child: Text(
                                    _session.host && run.canEnterSolarDungeon
                                        ? 'Scendi le scale d’oro · R'
                                        : _session.host &&
                                              run.solarBossWaiting &&
                                              run.hasPortalNearby
                                        ? 'Sfida il Guardiano Solare · R'
                                        : _session.canRest
                                        ? 'Ristoro · R'
                                        : _session.nearPortal(
                                            _session.localAccount,
                                          )
                                        ? (run.awaitsRestHub
                                              ? 'Sala di ristoro · R'
                                              : 'Conferma portale')
                                        : 'Ricarica · R',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
