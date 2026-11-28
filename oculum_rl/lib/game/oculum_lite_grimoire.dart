part of 'oculum_lite_run.dart';

enum LiteGrimoireActionKind { weapon, talent, scroll, art }

class LiteGrimoireAction {
  const LiteGrimoireAction.weapon()
    : kind = LiteGrimoireActionKind.weapon,
      art = null;

  const LiteGrimoireAction.talent()
    : kind = LiteGrimoireActionKind.talent,
      art = null;

  const LiteGrimoireAction.scroll()
    : kind = LiteGrimoireActionKind.scroll,
      art = null;

  const LiteGrimoireAction.art(LiteLearnedArt this.art)
    : kind = LiteGrimoireActionKind.art;

  final LiteGrimoireActionKind kind;
  final LiteLearnedArt? art;

  String get key => art == null ? kind.name : 'art:${art!.name}';

  static LiteGrimoireAction? tryRead(Object? value) => switch (value) {
    'weapon' => const LiteGrimoireAction.weapon(),
    'talent' => const LiteGrimoireAction.talent(),
    'scroll' => const LiteGrimoireAction.scroll(),
    String key when key.startsWith('art:') => switch (_grimoireArtByName(
      key.substring(4),
    )) {
      final art? => LiteGrimoireAction.art(art),
      null => null,
    },
    _ => null,
  };

  @override
  bool operator ==(Object other) =>
      other is LiteGrimoireAction && kind == other.kind && art == other.art;

  @override
  int get hashCode => Object.hash(kind, art);
}

LiteLearnedArt? _grimoireArtByName(Object? name) =>
    LiteLearnedArt.values.where((art) => art.name == name).firstOrNull;

const _grimoireSlotCount = 6;

List<LiteGrimoireAction?> _defaultGrimoireSlots(LiteHero hero) => [
  const LiteGrimoireAction.weapon(),
  const LiteGrimoireAction.talent(),
  const LiteGrimoireAction.scroll(),
  if (LiteLearnedArt.fixedFor(hero) case final art?)
    LiteGrimoireAction.art(art)
  else
    null,
  null,
  null,
];

extension LiteGrimoireUse on LiteRun {
  Set<LiteLearnedArt> grimoireArts([LiteCoopFighter? fighter]) =>
      Set.unmodifiable({
        ...(fighter?.supply ?? supply).knownArts,
        if (LiteLearnedArt.fixedFor(fighter?.hero ?? hero) case final art?) art,
      });

  List<LiteGrimoireAction?> grimoireSlots([LiteCoopFighter? fighter]) =>
      List.unmodifiable(
        (fighter?.supply ?? supply)._grimoireSlots ??
            _defaultGrimoireSlots(fighter?.hero ?? hero),
      );

  bool grimoireConfigured([LiteCoopFighter? fighter]) =>
      (fighter?.supply ?? supply)._grimoireSlots != null;

  void restoreProfileGrimoire(
    Iterable<LiteLearnedArt> arts,
    List<LiteGrimoireAction?>? slots, [
    LiteCoopFighter? fighter,
  ]) {
    final kit = fighter?.supply ?? supply;
    kit._learnedArts.addAll(arts);
    if (arts.isNotEmpty) kit.hasGrimoire = true;
    if (slots == null || slots.length != _grimoireSlotCount) return;
    final known = grimoireArts(fighter);
    kit._grimoireSlots = [
      for (final action in slots)
        if (action?.art case final art? when !known.contains(art))
          null
        else
          action,
    ];
  }

  bool assignGrimoire(
    int slot,
    LiteGrimoireAction? action, [
    LiteCoopFighter? fighter,
  ]) {
    if (slot < 0 || slot >= _grimoireSlotCount) return false;
    final known = grimoireArts(fighter);
    if (action?.art case final art? when !known.contains(art)) return false;
    final kit = fighter?.supply ?? supply;
    kit._grimoireSlots ??= _defaultGrimoireSlots(fighter?.hero ?? hero);
    kit._grimoireSlots![slot] = action;
    return true;
  }

  bool useGrimoire(int slot, Point<double> target, [LiteCoopFighter? fighter]) {
    final actions = (fighter?.supply ?? supply)._grimoireSlots;
    if (actions == null ||
        slot < 0 ||
        slot >= actions.length ||
        finished ||
        restHub ||
        shopOpen ||
        soloOpenFrozen ||
        gripRemaining(fighter) > 0 ||
        banditRopes(fighter) > 0 ||
        (fighter?.hp ?? hp) <= 0 ||
        (fighter?.blocking ?? blocking) ||
        (fighter?._night ?? _night).stun > 0 ||
        (fighter?._night ?? _night).bat > 0 ||
        (fighter != null && !fighter.connected) ||
        !target.x.isFinite ||
        !target.y.isFinite) {
      return false;
    }
    final action = actions[slot];
    switch (action?.kind) {
      case LiteGrimoireActionKind.weapon:
        if (fighter == null) return attack(target);
        final direction = LiteRun._unit(target - fighter.position);
        if (direction.magnitude > 0) fighter.aim = direction;
        return _beginCoopStrike(fighter);
      case LiteGrimoireActionKind.talent:
        if (fighter == null) return special(target);
        final direction = LiteRun._unit(target - fighter.position);
        if (direction.magnitude > 0) fighter.aim = direction;
        _useCoopTalent(fighter);
        return true;
      case LiteGrimoireActionKind.scroll:
        if (fighter == null)
          return castScroll(0, target, useGrimoireSlot: true);
        final scroll = fighter.supply.scrolls.entries
            .where((entry) => entry.value > 0)
            .firstOrNull
            ?.key;
        return scroll != null && castRestScroll(scroll, target, fighter);
      case LiteGrimoireActionKind.art:
        final art = action!.art!;
        if (!grimoireArts(fighter).contains(art)) return false;
        return _castLearnedArt(art, target, fighter);
      case null:
        return false;
    }
  }
}
