import '../game/oculum_lite_run.dart';

export '../game/oculum_lite_run.dart'
    show LiteGrimoireAction, LiteGrimoireActionKind;

class LiteGrimoireLoadout {
  const LiteGrimoireLoadout._(this.hero, this.actions);

  final LiteHero hero;
  final List<LiteGrimoireAction?> actions;
}

class LiteProfileGrimoire {
  const LiteProfileGrimoire.empty()
    : learnedArts = const {},
      _loadouts = const {};

  LiteProfileGrimoire._(
    Set<LiteLearnedArt> learned,
    Map<String, LiteGrimoireLoadout> loadouts,
  ) : learnedArts = Set.unmodifiable(learned),
      _loadouts = Map.unmodifiable(loadouts);

  static const slotCount = 6;

  bool hasLoadout(String characterId, LiteHero hero) =>
      _loadouts[characterId]?.hero == hero;

  final Set<LiteLearnedArt> learnedArts;
  final Map<String, LiteGrimoireLoadout> _loadouts;

  bool get isEmpty => learnedArts.isEmpty && _loadouts.isEmpty;

  static bool _isInnate(LiteLearnedArt art) =>
      LiteHero.values.any((hero) => LiteLearnedArt.fixedFor(hero) == art);

  Set<LiteLearnedArt> equippableArts(LiteHero hero) => Set.unmodifiable({
    ...learnedArts,
    if (LiteLearnedArt.fixedFor(hero) case final art?) art,
  });

  LiteProfileGrimoire learn(LiteLearnedArt art) {
    if (learnedArts.contains(art) || _isInnate(art)) return this;
    return LiteProfileGrimoire._({...learnedArts, art}, _loadouts);
  }

  LiteGrimoireLoadout loadoutFor(String characterId, LiteHero hero) {
    final saved = _loadouts[characterId];
    if (saved != null && saved.hero == hero) return saved;
    return LiteGrimoireLoadout._(
      hero,
      List.unmodifiable([
        const LiteGrimoireAction.weapon(),
        const LiteGrimoireAction.talent(),
        const LiteGrimoireAction.scroll(),
        if (LiteLearnedArt.fixedFor(hero) case final innate?)
          LiteGrimoireAction.art(innate)
        else
          null,
        null,
        null,
      ]),
    );
  }

  /// Indices follow the initial mouse-left, mouse-right, Q, 1, 2, 3 preset.
  LiteProfileGrimoire equip(
    String characterId,
    LiteHero hero,
    int slot,
    LiteGrimoireAction? action,
  ) {
    if (characterId.trim().isEmpty ||
        slot < 0 ||
        slot >= slotCount ||
        !_canEquip(action, hero, learnedArts)) {
      return this;
    }
    final current = loadoutFor(characterId, hero).actions;
    if (current[slot] == action) return this;
    final updated = List<LiteGrimoireAction?>.of(current)..[slot] = action;
    return LiteProfileGrimoire._(learnedArts, {
      ..._loadouts,
      characterId: LiteGrimoireLoadout._(hero, List.unmodifiable(updated)),
    });
  }

  Map<String, Object?> toJson() => {
    'schema': 1,
    if (learnedArts.isNotEmpty)
      'learned': [
        for (final art in LiteLearnedArt.values)
          if (learnedArts.contains(art)) art.name,
      ],
    if (_loadouts.isNotEmpty)
      'characters': {
        for (final entry in _loadouts.entries)
          entry.key: {
            'hero': entry.value.hero.name,
            'slots': entry.value.actions.map((action) => action?.key).toList(),
          },
      },
  };

  static LiteProfileGrimoire fromJson(Object? value) {
    if (value is! Map || value['schema'] != 1) {
      return const LiteProfileGrimoire.empty();
    }
    final learned = <LiteLearnedArt>{
      if (value['learned'] case final List names)
        for (final name in names)
          if (_readArt(name) case final art? when !_isInnate(art)) art,
    };
    final loadouts = <String, LiteGrimoireLoadout>{};
    if (value['characters'] case final Map characters) {
      for (final entry in characters.entries) {
        final characterId = entry.key;
        final data = entry.value;
        if (characterId is! String ||
            characterId.trim().isEmpty ||
            data is! Map) {
          continue;
        }
        final hero = LiteHero.values
            .where((hero) => hero.name == data['hero'])
            .firstOrNull;
        final slots = data['slots'];
        if (hero == null || slots is! List || slots.length != slotCount)
          continue;
        final actions = slots.map(LiteGrimoireAction.tryRead);
        loadouts[characterId] = LiteGrimoireLoadout._(
          hero,
          List.unmodifiable([
            for (final action in actions)
              _canEquip(action, hero, learned) ? action : null,
          ]),
        );
      }
    }
    return LiteProfileGrimoire._(learned, loadouts);
  }

  static bool _canEquip(
    LiteGrimoireAction? action,
    LiteHero hero,
    Set<LiteLearnedArt> learned,
  ) =>
      action?.art == null ||
      learned.contains(action!.art) ||
      LiteLearnedArt.fixedFor(hero) == action.art;
}

LiteLearnedArt? _readArt(Object? name) =>
    LiteLearnedArt.values.where((art) => art.name == name).firstOrNull;
