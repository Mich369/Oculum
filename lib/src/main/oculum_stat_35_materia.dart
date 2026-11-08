part of '../../main.dart';

enum OculumMateria35Attack { aimed, windStep }

const _materia35Aim = 'matter_precision';
const _materia35Wind = 'matter_wind';
const _materia35Immaterial = 'matter_immaterial';
const _materia35PreparedKey = 'materia35Immateriale';
final _materia35Preparing = Expando<bool>('Materia 35 preparation');

int oculumMateria35WindStepDamage(int damage, {int percent = 25}) =>
    (max(0, damage) * max(0, percent) + 99) ~/ 100;

int oculumMateria35ImmaterialePercent({
  required String element,
  required bool magicalAttack,
  String attackKind = '',
  int physicalPercent = 0,
  int elementalPercent = 75,
  int bypassPercent = 100,
}) {
  final type = oculumNormalizeElementId(element);
  final kind = oculumNormalizeText(attackKind);
  if (const {'oscuro', 'spirituale', 'perforanteimmateriale'}.contains(type) ||
      const {
        'perforante immateriale',
        'perforante intangibile',
        'immaterial piercing',
        'ethereal piercing',
      }.contains(kind)) {
    return bypassPercent;
  }
  return !magicalAttack &&
          const {'fisico', 'taglio', 'perforante', 'contundente'}.contains(type)
      ? physicalPercent
      : elementalPercent;
}

/// Points are normalized VTT coordinates. Distance and adjacency are measured
/// in metres to preserve the same range on rectangular maps.
Offset? oculumMateria35WindLanding({
  required Offset source,
  required Offset target,
  required double widthMeters,
  required double heightMeters,
  required double movement,
  required double adjacency,
  Iterable<Offset> occupied = const [],
}) {
  if (!widthMeters.isFinite ||
      widthMeters <= 0 ||
      !heightMeters.isFinite ||
      heightMeters <= 0 ||
      !movement.isFinite ||
      movement < 0 ||
      !adjacency.isFinite ||
      adjacency <= 0) {
    return null;
  }
  Offset metres(Offset point) =>
      Offset(point.dx * widthMeters, point.dy * heightMeters);
  bool inside(Offset point) =>
      point.dx >= 0 && point.dx <= 1 && point.dy >= 0 && point.dy <= 1;
  if (!inside(source) || !inside(target)) return null;
  final from = metres(source);
  final centre = metres(target);
  final towardSource = from - centre;
  final blockers = occupied.where(inside).map(metres).toList(growable: false);
  bool clear(Offset point) =>
      blockers.every((blocker) => (point - blocker).distance > adjacency / 2);
  if (towardSource.distance > adjacency / 2 &&
      towardSource.distance <= adjacency + .000001 &&
      clear(from)) {
    return source;
  }
  final bearings = [
    if (towardSource.distance > .000001) towardSource / towardSource.distance,
    for (var i = 0; i < 8; i++) Offset(cos(pi * i / 4), sin(pi * i / 4)),
  ];
  Offset? closest;
  var shortest = double.infinity;
  for (final bearing in bearings) {
    final candidate = centre + bearing * adjacency;
    final point = Offset(
      candidate.dx / widthMeters,
      candidate.dy / heightMeters,
    );
    final distance = (candidate - from).distance;
    if (inside(point) &&
        clear(candidate) &&
        distance <= movement + .000001 &&
        distance < shortest) {
      closest = point;
      shortest = distance;
    }
  }
  return closest;
}

extension _OculumStat35Materia on _OculumHomePageState {
  String _materia35OptionFor(OculumMateria35Attack attack) => switch (attack) {
    OculumMateria35Attack.aimed => _materia35Aim,
    OculumMateria35Attack.windStep => _materia35Wind,
  };

  String get _materia35Fight =>
      '$permissionScope:$onlineCombatEncounterId:${combatSubtraitExperienceFightId(onlineCombatEncounterId)}';

  bool get _materia35OwnActiveFight {
    if (onlineCombatEncounterId.isEmpty ||
        !currentCombatIsActive() ||
        outsideFight) {
      return false;
    }
    final source = sheetTagAt(schedaCorrente);
    return controlsOnlineCombatSheet(source) &&
        onlineCombatTokens().any(
          (token) =>
              combatTokenMatchesSheet(token, source) &&
              masterInitiativeTokenCanAct(token),
        );
  }

  bool get _materia35MapAuthority =>
      !onlineMasterApprovalRequired || realtimeIsMasterRole;

  bool materia35AttackReady(OculumMateria35Attack attack) {
    final option = _materia35OptionFor(attack);
    return _materia35OwnActiveFight &&
        hasStat35Choice('materia', option) &&
        stat35Cooldown(option) == 0 &&
        (attack != OculumMateria35Attack.windStep || _materia35MapAuthority);
  }

  int get materia35AimPrecisionBonus =>
      max(0, stat35Value(_materia35Aim, 'precisionBonus', fallback: 6));

  int get materia35WindStepHits =>
      stat35Value(_materia35Wind, 'hits', fallback: 6).clamp(1, 20).toInt();

  int materia35WindStepDamage(int damage) => oculumMateria35WindStepDamage(
    damage,
    percent: stat35Value(_materia35Wind, 'damagePercent', fallback: 25),
  );

  Future<void> activateMateria35Aim() => planOnlineAttack(
    initialChoice: 'precisione',
    materia35Attack: OculumMateria35Attack.aimed,
  );

  Future<void> activateMateria35WindStep() => planOnlineAttack(
    initialChoice: 'vc',
    materia35Attack: OculumMateria35Attack.windStep,
  );

  ({Map<String, dynamic> token, Offset position})? _materia35WindPlan(
    String targetTag,
  ) {
    if (!_materia35MapAuthority) return null;
    final tokens = onlineCombatTokens();
    final sourceTag = sheetTagAt(schedaCorrente);
    final actor = tokens
        .where((t) => combatTokenMatchesSheet(t, sourceTag))
        .firstOrNull;
    final target = tokens
        .where((t) => combatTokenMatchesSheet(t, targetTag))
        .firstOrNull;
    if (actor == null ||
        target == null ||
        !masterInitiativeTokenCanAct(target) ||
        !oculumShieldBreakCanTarget(actor, target)) {
      return null;
    }
    final actorMap = localMapTokenForInitiativeToken(actor);
    final targetMap = localMapTokenForInitiativeToken(target);
    if (actorMap == null ||
        targetMap == null ||
        identical(actorMap, targetMap)) {
      return null;
    }
    Offset position(Map<String, dynamic> token) =>
        Offset(localMapTokenAxis(token, 'x'), localMapTokenAxis(token, 'y'));
    final landing = oculumMateria35WindLanding(
      source: position(actorMap),
      target: position(targetMap),
      widthMeters: mapWidthMetersValue(),
      heightMeters: mapHeightMetersValue(),
      movement: movimento().toDouble(),
      adjacency: activeVttScene.distancePerCell,
      occupied: localMapTokens
          .where(
            (token) =>
                !identical(token, actorMap) && !identical(token, targetMap),
          )
          .map(position),
    );
    return landing == null ? null : (token: actorMap, position: landing);
  }

  bool materia35WindStepInRange(String targetTag) =>
      _materia35WindPlan(targetTag) != null;

  bool commitMateria35Attack(OculumMateria35Attack attack, String targetTag) {
    if (!materia35AttackReady(attack)) return false;
    final option = _materia35OptionFor(attack);
    if (attack == OculumMateria35Attack.windStep) {
      final plan = _materia35WindPlan(targetTag);
      if (plan == null) {
        aggiungiLog(
          '[WIND STEP] Il bersaglio non ha una posizione adiacente raggiungibile.',
        );
        return false;
      }
      plan.token['x'] = plan.position.dx;
      plan.token['y'] = plan.position.dy;
      notifyVttCanvasChanged(save: true);
      evaluateVttTriggersForToken(plan.token);
      unawaited(sendAuthoritativeVttTokenPosition(plan.token));
    }
    setStat35Cooldown(
      option,
      stat35Value(
        option,
        'cooldown',
        fallback: attack == OculumMateria35Attack.aimed ? 2 : 5,
      ),
    );
    programmaSalvataggio();
    return true;
  }

  bool get canPrepareMateria35Immateriale {
    final prepared = planarState[_materia35PreparedKey];
    return _materia35OwnActiveFight &&
        hasStat35Choice('materia', _materia35Immaterial) &&
        stat35Cooldown(_materia35Immaterial) == 0 &&
        (prepared is! Map || prepared['fight'] != _materia35Fight) &&
        _materia35Preparing[this] != true;
  }

  Future<void> prepareMateria35Immateriale() async {
    if (!canPrepareMateria35Immateriale) return;
    final origin = currentSheetScrollId();
    final fight = _materia35Fight;
    _materia35Preparing[this] = true;
    try {
      if (!await requestUtilitySpend(
            'reazione',
            preferFreeReaction: false,
            grantFastRollBonus: false,
          ) ||
          !mounted ||
          currentSheetScrollId() != origin ||
          _materia35Fight != fight ||
          !_materia35OwnActiveFight) {
        return;
      }
      planarState[_materia35PreparedKey] = {
        'fight': fight,
        'physicalPercent': stat35Value(
          _materia35Immaterial,
          'physicalPercent',
          fallback: 0,
        ),
        'elementalPercent': stat35Value(
          _materia35Immaterial,
          'elementalPercent',
          fallback: 75,
        ),
        'bypassPercent': stat35Value(
          _materia35Immaterial,
          'bypassPercent',
          fallback: 100,
        ),
      };
      setStat35Cooldown(
        _materia35Immaterial,
        stat35Value(_materia35Immaterial, 'cooldown', fallback: 5),
      );
      aggiungiLog('[IMMATERIALE] Preparata per il prossimo colpo.');
      notifyActiveSheetSummaryChanged();
      programmaSalvataggio();
      unawaited(flushPendingCombatTurnResources());
    } finally {
      _materia35Preparing[this] = false;
    }
  }

  int consumeMateria35ImmaterialeHit({
    required String element,
    required bool magicalAttack,
    required String attackKind,
  }) {
    final ready = planarState[_materia35PreparedKey];
    if (ready is! Map ||
        !_materia35OwnActiveFight ||
        ready['fight'] != _materia35Fight) {
      return 100;
    }
    planarState.remove(_materia35PreparedKey);
    final percent = oculumMateria35ImmaterialePercent(
      element: element,
      magicalAttack: magicalAttack,
      attackKind: attackKind,
      physicalPercent: readIntValue(ready['physicalPercent']),
      elementalPercent: readIntValue(ready['elementalPercent'], fallback: 75),
      bypassPercent: readIntValue(ready['bypassPercent'], fallback: 100),
    ).clamp(0, 100).toInt();
    aggiungiLog('[IMMATERIALE] Danno del colpo al $percent%.');
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
    return percent;
  }
}
