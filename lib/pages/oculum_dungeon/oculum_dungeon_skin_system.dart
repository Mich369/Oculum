part of '../oculum_dungeon_game.dart';

class _DungeonSkin {
  const _DungeonSkin({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.spriteKind,
    required this.primaryColor,
    required this.eyeColor,
    this.unlockedByDefault = false,
    this.hideEquipment = false,
    this.unlockAchievementId,
    this.unlockKillKey,
    this.unlockKillGoal = 0,
    this.monsterSkin = false,
    this.assetPath,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;
  final String spriteKind;
  final Color primaryColor;
  final Color eyeColor;
  final bool unlockedByDefault;
  final bool hideEquipment;
  final String? unlockAchievementId;
  final String? unlockKillKey;
  final int unlockKillGoal;
  final bool monsterSkin;
  final String? assetPath;
}

final Expando<String> _skinSelectedIdStore = Expando<String>();
final Expando<Set<String>> _skinUnlockedIdsStore = Expando<Set<String>>();
final Expando<Map<String, int>> _skinKillCountsStore =
    Expando<Map<String, int>>();
final Expando<bool> _showSkinCodexStore = Expando<bool>();
final Expando<bool> _showTopQuickIconsStore = Expando<bool>();
final Expando<bool> _showInfoEnemyPanelStore = Expando<bool>();
final Expando<bool> _showBottomLogStore = Expando<bool>();
final Expando<bool> _showVictoryChanceStore = Expando<bool>();
final Expando<bool> _currentFightHasNullFatelessStore = Expando<bool>();
final Expando<bool> _playerWoundedByNullFatelessStore = Expando<bool>();

extension _OculumDungeonSkinSystem on _OculumDungeonGameDialogState {
  // =====================================================
  // STORAGE SICURO SENZA MODIFICARE LO STATE PRINCIPALE
  // =====================================================

  String get selectedSkinId {
    return _skinSelectedIdStore[this] ?? 'base_oculum';
  }

  set selectedSkinId(String value) {
    _skinSelectedIdStore[this] = value;
  }

  Set<String> get unlockedSkinIds {
    final saved = _skinUnlockedIdsStore[this];
    if (saved != null) return saved;

    final initial = <String>{};
    for (final skin in generateDungeonSkins()) {
      if (skin.unlockedByDefault) {
        initial.add(skin.id);
      }
    }

    _skinUnlockedIdsStore[this] = initial;
    return initial;
  }

  Map<String, int> get skinKillCounts {
    final saved = _skinKillCountsStore[this];
    if (saved != null) return saved;
    final initial = <String, int>{};
    _skinKillCountsStore[this] = initial;
    return initial;
  }

  List<_DungeonSkin> get _allSkins {
    return generateDungeonSkins();
  }

  _DungeonSkin get activeSkin {
    return getActiveDungeonSkin(_allSkins, selectedSkinId);
  }

  bool get showSkinCodexPanel {
    return _showSkinCodexStore[this] ?? false;
  }

  set showSkinCodexPanel(bool value) {
    _showSkinCodexStore[this] = value;
  }

  bool get showTopQuickIcons {
    return _showTopQuickIconsStore[this] ?? true;
  }

  set showTopQuickIcons(bool value) {
    _showTopQuickIconsStore[this] = value;
  }

  bool get showInfoEnemyPanel {
    return _showInfoEnemyPanelStore[this] ?? true;
  }

  set showInfoEnemyPanel(bool value) {
    _showInfoEnemyPanelStore[this] = value;
  }

  bool get showBottomLog {
    return _showBottomLogStore[this] ?? true;
  }

  set showBottomLog(bool value) {
    _showBottomLogStore[this] = value;
  }

  bool get showVictoryChance {
    return _showVictoryChanceStore[this] ?? true;
  }

  set showVictoryChance(bool value) {
    _showVictoryChanceStore[this] = value;
  }

  bool get currentFightHasNullFateless {
    return _currentFightHasNullFatelessStore[this] ?? false;
  }

  set currentFightHasNullFateless(bool value) {
    _currentFightHasNullFatelessStore[this] = value;
  }

  bool get playerWoundedByNullFateless {
    return _playerWoundedByNullFatelessStore[this] ?? false;
  }

  set playerWoundedByNullFateless(bool value) {
    _playerWoundedByNullFatelessStore[this] = value;
  }

  // =====================================================
  // SKIN
  // =====================================================

  String skinKillKey(String name, String elementId) {
    final raw = '${elementId}_${name.toLowerCase()}';
    return raw
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String skinKillKeyForEnemy(_EnemyInstance enemy) {
    return skinKillKey(enemy.nameIt, enemy.elementId);
  }

  String skinKillKeyForTemplate(_EnemyTemplate enemy) {
    return skinKillKey(enemy.nameIt, enemy.elementId);
  }

  int skinUnlockGoalForEnemy(_EnemyInstance enemy) {
    if (enemy.boss) return 1;
    if (enemy.elite) return 3;
    return 5;
  }

  void registerSkinKill(_EnemyInstance enemy) {
    final key = skinKillKeyForEnemy(enemy);
    skinKillCounts[key] = (skinKillCounts[key] ?? 0) + 1;

    var changed = false;
    for (final skin in generateDungeonSkins()) {
      final killCount = skinKillCounts[key] ?? 0;
      final enoughKills =
          killCount >= skin.unlockKillGoal ||
          killCount >= skinUnlockGoalForEnemy(enemy) ||
          enemy.boss;
      if (skin.unlockKillKey == key &&
          enoughKills &&
          !unlockedSkinIds.contains(skin.id)) {
        unlockedSkinIds.add(skin.id);
        changed = true;
        addLog(
          t(
            'Skin sbloccata: ${skin.nameIt}.',
            'Skin unlocked: ${skin.nameEn}.',
          ),
        );
      }
    }

    if (changed) _savePermanentProgress();
  }

  List<_DungeonSkin> generateDungeonSkins() {
    final baseSkins = <_DungeonSkin>[
      _DungeonSkin(
        id: 'base_oculum',
        nameIt: 'Base',
        nameEn: 'Base',
        descIt: 'Sprite base. Mostra arma e armatura equipaggiate.',
        descEn: 'Base sprite. Shows equipped weapon and armor.',
        spriteKind: 'humanoid',
        primaryColor: Color(0xFF8B5CF6),
        eyeColor: Color(0xFF565968),
        unlockedByDefault: true,
      ),
      _DungeonSkin(
        id: 'base_capelli_corti',
        nameIt: 'Base capelli corti',
        nameEn: 'Base short hair',
        descIt:
            'Base pulita, capelli corti, Oculum spento. Equip visivo attivo.',
        descEn: 'Clean base, short hair, dim Oculum. Visual equipment enabled.',
        spriteKind: 'human_short_hair',
        primaryColor: Color(0xFF8B5CF6),
        eyeColor: Color(0xFF565968),
        unlockedByDefault: true,
      ),
      _DungeonSkin(
        id: 'base_capelli_lunghi',
        nameIt: 'Base capelli lunghi',
        nameEn: 'Base long hair',
        descIt:
            'Base pulita, capelli lunghi, Oculum spento. Equip visivo attivo.',
        descEn: 'Clean base, long hair, dim Oculum. Visual equipment enabled.',
        spriteKind: 'human_long_hair',
        primaryColor: Color(0xFFB6A0FF),
        eyeColor: Color(0xFF565968),
        unlockedByDefault: true,
      ),
      _DungeonSkin(
        id: 'base_taglio_maschile',
        nameIt: 'Base taglio maschile',
        nameEn: 'Base masculine cut',
        descIt: 'Base simil-umana con taglio maschile. Equip visivo attivo.',
        descEn: 'Humanoid base with masculine cut. Visual equipment enabled.',
        spriteKind: 'human_masc_hair',
        primaryColor: Color(0xFFC49A5A),
        eyeColor: Color(0xFF565968),
        unlockedByDefault: true,
      ),
      _DungeonSkin(
        id: 'base_taglio_femminile',
        nameIt: 'Base taglio femminile',
        nameEn: 'Base feminine cut',
        descIt: 'Base simil-umana con taglio femminile. Equip visivo attivo.',
        descEn: 'Humanoid base with feminine cut. Visual equipment enabled.',
        spriteKind: 'human_fem_hair',
        primaryColor: Color(0xFFD7B9FF),
        eyeColor: Color(0xFF565968),
        unlockedByDefault: true,
      ),
      _DungeonSkin(
        id: 'pawn',
        nameIt: 'Pawn',
        nameEn: 'Pawn',
        descIt:
            'Skin Pedina. Gli oggetti indossati non vengono mostrati per evitare bug visivi.',
        descEn: 'Pawn skin. Equipped items are hidden to avoid visual bugs.',
        spriteKind: 'pawn',
        primaryColor: Color(0xFF9B7CFF),
        eyeColor: Color(0xFFFFFFFF),
        unlockedByDefault: true,
        hideEquipment: true,
      ),
      _DungeonSkin(
        id: 'baghest_cultist',
        nameIt: 'Cultista',
        nameEn: 'Cultist',
        descIt: 'Skin da Cultista di Baghest. Sbloccata con achievement.',
        descEn: 'Baghest Cultist skin. Unlocked by achievement.',
        spriteKind: 'cultist',
        primaryColor: Color(0xFF5A2E48),
        eyeColor: Color(0xFFFF8DD8),
        unlockAchievementId: 'defeat_baghest_boss',
      ),
      _DungeonSkin(
        id: 'oculian',
        nameIt: 'Oculiano',
        nameEn: 'Oculian',
        descIt: 'Skin dell’Oculiano. Sbloccata usando molte Skill Oculum.',
        descEn: 'Oculian skin. Unlocked by using many Oculum Skills.',
        spriteKind: 'eye',
        primaryColor: Color(0xFF8B5CF6),
        eyeColor: Color(0xFFEDE9FE),
        unlockAchievementId: 'oculum_mastery',
      ),
      _DungeonSkin(
        id: 'oculian_male_cloak',
        nameIt: 'Oculiano con mantello',
        nameEn: 'Cloaked Oculian',
        descIt: 'Sprite Oculiano maschile completo. Equip visivo attivo.',
        descEn: 'Full male Oculian sprite. Visual equipment enabled.',
        spriteKind: 'human_oculian_male',
        primaryColor: Color(0xFF8B5CF6),
        eyeColor: Color(0xFFEDE9FE),
        unlockAchievementId: 'oculum_mastery',
      ),
      _DungeonSkin(
        id: 'oculian_female_cloak',
        nameIt: 'Oculiana con mantello',
        nameEn: 'Cloaked Oculian Girl',
        descIt: 'Sprite Oculiano femminile completo. Equip visivo attivo.',
        descEn: 'Full feminine Oculian sprite. Visual equipment enabled.',
        spriteKind: 'human_oculian_female',
        primaryColor: Color(0xFFD7B9FF),
        eyeColor: Color(0xFFEDE9FE),
        unlockAchievementId: 'oculum_mastery',
      ),
      _DungeonSkin(
        id: 'oculian_female_ritual',
        nameIt: 'Oculiana rituale',
        nameEn: 'Ritual Oculian Girl',
        descIt: 'Variante rituale dello sprite Oculiano femminile.',
        descEn: 'Ritual variant of the feminine Oculian sprite.',
        spriteKind: 'human_oculian_female_ritual',
        primaryColor: Color(0xFFC49A5A),
        eyeColor: Color(0xFFEDE9FE),
        unlockAchievementId: 'oculum_mastery',
      ),
      _DungeonSkin(
        id: 'null_fateless',
        nameIt: 'Null/Fateless',
        nameEn: 'Null/Fateless',
        descIt:
            'Skin puntinata mini-boss. Non appartiene al Fato. Sblocco segreto.',
        descEn:
            'Dotted mini-boss skin. It does not belong to Fate. Secret unlock.',
        spriteKind: 'dotted_eye',
        primaryColor: Color(0xFFEDEDED),
        eyeColor: Color(0xFF050505),
        hideEquipment: true,
        unlockAchievementId: 'survive_null_fateless',
      ),
      _DungeonSkin(
        id: 'legendary_oculum',
        nameIt: 'Leggendaria',
        nameEn: 'Legendary',
        descIt: 'Skin leggendaria sbloccabile tramite achievement avanzato.',
        descEn: 'Legendary skin unlocked through an advanced achievement.',
        spriteKind: 'legendary_eye_knight',
        primaryColor: Color(0xFFFFB85C),
        eyeColor: Color(0xFFFFFFFF),
        unlockAchievementId: 'all_floor_bosses_defeated',
      ),
    ];

    const dimEye = Color(0xFF565968);
    final humanSkins = <_DungeonSkin>[
      const _DungeonSkin(
        id: 'human_lama_scudo',
        nameIt: 'Lama e Scudo',
        nameEn: 'Blade and Shield',
        descIt: 'Simil-umano con Oculum spento. Può indossare arma e armatura.',
        descEn: 'Dim-Oculum humanoid. Can wear weapon and armor safely.',
        spriteKind: 'humanoid',
        primaryColor: Color(0xFF8B5CF6),
        eyeColor: dimEye,
        unlockedByDefault: true,
      ),
      const _DungeonSkin(
        id: 'human_oculian_armor',
        nameIt: 'Armatura Oculiana',
        nameEn: 'Oculian Armor',
        descIt:
            'Simil-umano corazzato con Oculum spento e overlay equip stabile.',
        descEn: 'Armored dim-Oculum humanoid with stable equipment overlays.',
        spriteKind: 'humanoid',
        primaryColor: Color(0xFFBFB7DD),
        eyeColor: dimEye,
        unlockedByDefault: true,
      ),
      const _DungeonSkin(
        id: 'human_osso_cieco',
        nameIt: 'Osso Cieco',
        nameEn: 'Blind Bone',
        descIt: 'Forma simil-umana d’osso. Equip visivo attivo.',
        descEn: 'Bone humanoid form. Visual equipment enabled.',
        spriteKind: 'humanoid',
        primaryColor: Color(0xFFE8DEC7),
        eyeColor: dimEye,
        unlockAchievementId: 'bone_button_guard',
      ),
      const _DungeonSkin(
        id: 'human_vapium_muto',
        nameIt: 'Vapium Muto',
        nameEn: 'Mute Vapium',
        descIt: 'Corpo simil-umano grigio-vapore. Equip visivo attivo.',
        descEn: 'Grey vapor humanoid body. Visual equipment enabled.',
        spriteKind: 'humanoid',
        primaryColor: Color(0xFFA7AAB8),
        eyeColor: dimEye,
        unlockAchievementId: 'clear_elite_vault',
      ),
      const _DungeonSkin(
        id: 'human_affogato',
        nameIt: 'Affogato',
        nameEn: 'Drowned',
        descIt: 'Simil-umano blu affogato con Oculum spento.',
        descEn: 'Blue drowned humanoid with dim Oculum.',
        spriteKind: 'humanoid',
        primaryColor: Color(0xFF44A7FF),
        eyeColor: dimEye,
        unlockAchievementId: 'drowned_party',
      ),
      const _DungeonSkin(
        id: 'human_hideano',
        nameIt: 'Hideano',
        nameEn: 'Hidean',
        descIt: 'Simil-umano da brace. Equip visivo attivo.',
        descEn: 'Ember humanoid. Visual equipment enabled.',
        spriteKind: 'humanoid',
        primaryColor: Color(0xFFFF5A3C),
        eyeColor: dimEye,
        unlockAchievementId: 'hidenas_contract',
      ),
      const _DungeonSkin(
        id: 'human_lunium',
        nameIt: 'Lunium',
        nameEn: 'Lunium',
        descIt: 'Simil-umano lunare con Oculum spento.',
        descEn: 'Moon humanoid with dim Oculum.',
        spriteKind: 'humanoid',
        primaryColor: Color(0xFFD7B9FF),
        eyeColor: dimEye,
        unlockAchievementId: 'moon_second_chance',
      ),
      const _DungeonSkin(
        id: 'human_obser',
        nameIt: 'Obser',
        nameEn: 'Obser',
        descIt: 'Simil-umano da mercante oscuro. Equip visivo attivo.',
        descEn: 'Dark merchant humanoid. Visual equipment enabled.',
        spriteKind: 'humanoid',
        primaryColor: Color(0xFF9AA1AE),
        eyeColor: dimEye,
        unlockAchievementId: 'merchant_chain',
      ),
      const _DungeonSkin(
        id: 'human_sangue_nero',
        nameIt: 'Sangue Nero',
        nameEn: 'Black Blood',
        descIt: 'Simil-umano rosso cupo con Oculum spento.',
        descEn: 'Dark red humanoid with dim Oculum.',
        spriteKind: 'humanoid',
        primaryColor: Color(0xFFC5283D),
        eyeColor: dimEye,
        unlockAchievementId: 'bleed_master',
      ),
      const _DungeonSkin(
        id: 'human_cristallo_fume',
        nameIt: 'Cristallo Fumè',
        nameEn: 'Smoky Crystal',
        descIt: 'Simil-umano di cristallo spento. Equip visivo attivo.',
        descEn: 'Dim crystal humanoid. Visual equipment enabled.',
        spriteKind: 'humanoid',
        primaryColor: Color(0xFFA98BFF),
        eyeColor: dimEye,
        unlockAchievementId: 'crystal_reforge',
      ),
      const _DungeonSkin(
        id: 'human_fulmine_sepolto',
        nameIt: 'Fulmine Sepolto',
        nameEn: 'Buried Lightning',
        descIt: 'Simil-umano giallo scuro. Equip visivo attivo.',
        descEn: 'Dark yellow humanoid. Visual equipment enabled.',
        spriteKind: 'humanoid',
        primaryColor: Color(0xFFFFF06A),
        eyeColor: dimEye,
        unlockAchievementId: 'crit_chain',
      ),
      const _DungeonSkin(
        id: 'human_sogno_cattivo',
        nameIt: 'Sogno Cattivo',
        nameEn: 'Bad Dream',
        descIt: 'Simil-umano da sogno spento. Equip visivo attivo.',
        descEn: 'Dim dream humanoid. Visual equipment enabled.',
        spriteKind: 'humanoid',
        primaryColor: Color(0xFFB6A0FF),
        eyeColor: dimEye,
        unlockAchievementId: 'dream_event',
      ),
    ];

    final monsterSkins = _enemies.map((enemy) {
      final key = skinKillKeyForTemplate(enemy);
      final goal = enemy.boss ? 1 : 5;
      final matchedMonster = monsterBookEntryForTemplate(enemy);
      return _DungeonSkin(
        id: 'monster_$key',
        nameIt: enemy.nameIt,
        nameEn: enemy.nameEn,
        descIt: 'Skin mostro normale. Sblocco: uccidi questo tipo $goal volte.',
        descEn: 'Normal monster skin. Unlock: defeat this type $goal times.',
        spriteKind: spriteKindForElement(enemy.elementId, enemy.nameIt),
        primaryColor: elementColor(enemy.elementId),
        eyeColor: dimEye,
        unlockKillKey: key,
        unlockKillGoal: goal,
        monsterSkin: true,
        assetPath: monsterDungeonSpriteAsset(
          enemy.elementId,
          enemy.nameIt,
          matchedMonster?.spriteAssetPath,
        ),
      );
    });

    return [...baseSkins, ...humanSkins, ...monsterSkins];
  }

  _DungeonSkin getActiveDungeonSkin(
    List<_DungeonSkin> skins,
    String selectedSkinId,
  ) {
    return skins.firstWhere(
      (skin) => skin.id == selectedSkinId,
      orElse: () => skins.first,
    );
  }

  // =====================================================
  // SPRITE PLAYER CON EQUIP
  // =====================================================

  // ignore: unused_element
  Widget buildDefinitivePlayerSprite(double size) {
    final skin = activeSkin;
    final showEquipment =
        !skin.hideEquipment &&
        !skin.monsterSkin &&
        spriteKindSupportsEquipment(skin.spriteKind);

    return SizedBox.square(
      dimension: size,
      child: dungeonSpriteArt(
        color: skin.primaryColor,
        seed: selectedSkinId.hashCode + dungeonLevel + runCount,
        kind: skin.spriteKind,
        eyeColor: skin.eyeColor,
        layers: showEquipment ? playerAppearanceLayers : 0,
        flip: false,
        assetPath: _skinDungeonSpriteAsset(skin),
        weaponKind: showEquipment ? currentWeaponSpriteKind : '',
        weaponColor: showEquipment
            ? currentWeaponSpriteColor
            : Colors.transparent,
        weaponSeed: showEquipment ? currentWeaponSpriteSeed : 0,
        armorKind: showEquipment ? currentArmorSpriteKind : '',
        armorColor: showEquipment
            ? currentArmorSpriteColor
            : Colors.transparent,
        armorSeed: showEquipment ? currentArmorSpriteSeed : 0,
        armorAssetPath: showEquipment
            ? dungeonArmorAssetForKind(currentArmorSpriteKind)
            : null,
      ),
    );
  }

  String? _skinDungeonSpriteAsset(_DungeonSkin skin) {
    if (skin.assetPath != null) return skin.assetPath;
    if (skin.monsterSkin) {
      return monsterDungeonSpriteAsset('', skin.nameIt);
    }
    return playerDungeonSpriteAssetForKind(skin.spriteKind);
  }

  String get currentWeaponSpriteKind {
    final weapon = starterWeapon;
    if (weapon == null) return '';

    final id = weapon.id.toLowerCase();

    if (id.contains('staff')) return 'staff';
    if (id.contains('hammer') || id.contains('maul')) return 'hammer';
    if (id.contains('dagger') || id.contains('knife')) return 'dagger';
    if (id.contains('shield')) return 'shield';
    if (id.contains('boomerang')) return 'boomerang';
    if (id.contains('chakram')) return 'chakram';
    if (id.contains('scythe')) return 'scythe';
    if (id.contains('lance') || id.contains('spear')) return 'spear';
    if (id.contains('flail')) return 'flail';
    if (id.contains('hook')) return 'hook';

    return 'sword';
  }

  Color get currentWeaponSpriteColor {
    return elementColor(starterWeapon?.elementId ?? 'neutral');
  }

  int get currentWeaponSpriteSeed {
    return starterWeapon?.id.hashCode ?? 0;
  }

  String get currentArmorSpriteKind {
    final costume = activeCostume;
    if (costume == null) return '';

    final id = costume.id.toLowerCase();

    if (id.contains('plate') || id.contains('armor')) return 'plate';
    if (id.contains('cloak') || id.contains('mantle')) return 'cloak';
    if (id.contains('robe') || id.contains('gown')) return 'robe';
    if (id.contains('cultist')) return 'cultist';

    return 'armor';
  }

  Color get currentArmorSpriteColor {
    return elementColor(activeCostume?.elementId ?? 'neutral');
  }

  int get currentArmorSpriteSeed {
    return activeCostume?.id.hashCode ?? 0;
  }

  Color elementColor(String id) {
    switch (id) {
      case 'fire':
        return const Color(0xFFFF5A3C);
      case 'wind':
        return const Color(0xFF7EE7C8);
      case 'water':
        return const Color(0xFF44A7FF);
      case 'earth':
        return const Color(0xFFC49A5A);
      case 'ice':
        return const Color(0xFF9BE7FF);
      case 'sound':
        return const Color(0xFFFF8DD8);
      case 'psyche':
        return const Color(0xFFFF7CE5);
      case 'lava':
        return const Color(0xFFFF7A1A);
      case 'lightning':
        return const Color(0xFFFFF06A);
      case 'poison':
        return const Color(0xFF78D64B);
      case 'ash':
        return const Color(0xFF8D8A82);
      case 'blood':
        return const Color(0xFFC5283D);
      case 'crystal':
        return const Color(0xFFA98BFF);
      case 'shadow':
        return const Color(0xFF4C3A78);
      case 'moon':
        return const Color(0xFFD7B9FF);
      case 'sun':
        return const Color(0xFFFFD36A);
      case 'vapium':
        return const Color(0xFFA7AAB8);
      case 'bone':
        return const Color(0xFFE8DEC7);
      case 'gravity':
        return const Color(0xFF7C5CFF);
      case 'nullum':
        return const Color(0xFFEDEDED);
      case 'dream':
        return const Color(0xFFB6A0FF);
      case 'metal':
        return const Color(0xFF9AA1AE);
      case 'flora':
        return const Color(0xFF55B86B);
      case 'slime':
        return const Color(0xFF63D8FF);
      case 'oculum':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFFBFB7DD);
    }
  }

  // =====================================================
  // PROBABILITÀ VITTORIA
  // =====================================================

  double calculateVictoryChance() {
    if (!inCombat || enemyParty.isEmpty) return 1.0;

    final playerPower =
        playerHp +
        playerShield +
        totalPlayerDamage * 8 +
        totalPlayerDefense * 7 +
        dungeonResilienza * 5 +
        dungeonVolonta * 6 +
        dungeonMateria * 5 +
        dungeonOculum * 8 +
        oculumCharges * 18 +
        activeAllies.length * 35 +
        (valleyInFight ? valleyHp + valleyAttack * 6 + valleyDefense * 5 : 0) +
        activeTitlePowerBonus +
        activeOpenPowerBonus +
        activeOculumSkillPowerBonus +
        setShieldBonus +
        setCritBonus * 3 +
        setVictoryChanceBonus * 9;

    final enemiesPower = enemyParty.fold<int>(0, (sum, enemy) {
      final bossBonus = enemy.boss ? 120 : 0;
      final eliteBonus = enemy.elite ? 65 : 0;

      return sum +
          enemy.hp +
          enemy.attack * 9 +
          enemy.defense * 7 +
          bossBonus +
          eliteBonus;
    });

    final pressure =
        selectedDifficultyMultiplier * max(1.0, dungeonFloor * .18);
    final adjustedEnemyPower = enemiesPower * pressure;

    final raw = playerPower / max(1, playerPower + adjustedEnemyPower);
    return raw.clamp(0.03, 0.97);
  }

  int get totalPlayerDamage {
    return widget.playerDamage +
        runDamageBonus +
        attachedDamageBonus +
        (starterWeapon?.damageBonus ?? 0) +
        (activeCostume?.damageBonus ?? 0) +
        setDamageBonus;
  }

  int get totalPlayerDefense {
    return widget.playerDefense +
        runDefenseBonus +
        attachedDefenseBonus +
        (starterWeapon?.defenseBonus ?? 0) +
        (activeCostume?.defenseBonus ?? 0) +
        setDefenseBonus;
  }

  int get activeTitlePowerBonus {
    var total = 0;

    for (final titleId in equippedTitleIds) {
      final title = _allTitles.firstWhere(
        (x) => x.id == titleId,
        orElse: () => _allTitles.first,
      );

      total += title.res * 4;
      total += title.vol * 5;
      total += title.mat * 4;
      total += title.ocu * 7;
      total += title.damage * 8;
      total += title.defense * 7;

      if (title.strong) total += 25;
    }

    return total;
  }

  int get activeOpenPowerBonus {
    var total = 0;

    if (rebirthBlessingActive) total += 35;
    if (rareLevelUpBlessingActive) total += 25;
    if (criticalShieldActive) total += 40;
    if (moonSecondChance) total += 35;
    if (reactionAvailable) total += 18;
    if (mapRevealed) total += 8;
    if (nextEnemyWeakened) total += 14;

    return total;
  }

  int get activeOculumSkillPowerBonus {
    var total = 0;

    total += oculumCharges * 18;
    total += oculumMaxCharges * 10;
    total += oculumSkillCasts * 2;

    if (activeRelic != null) total += 25;
    if (activeArt != null) total += 30;

    return total;
  }

  // =====================================================
  // UI COMPATTA
  // =====================================================

  Widget buildCompactChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final cleanLabel = cleanDungeonText(label);
    final cleanValue = cleanDungeonText(value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D16),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Text(
            cleanLabel,
            style: TextStyle(
              color: Colors.grey.shade200,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            cleanValue,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildVictoryChanceChip() {
    final chance = (calculateVictoryChance() * 100).round();

    final color = chance >= 70
        ? Colors.greenAccent
        : chance >= 45
        ? widget.tertiaryColor
        : Colors.redAccent;

    return buildCompactChip(
      icon: Icons.star,
      label: 'Prob. vittoria',
      value: '$chance%',
      color: color,
    );
  }

  String combatWeaponLabel() {
    final weapon = starterWeapon;
    if (weapon == null) return t('Base', 'Base');
    final name = widget.linguaInglese ? weapon.nameEn : weapon.nameIt;
    final clean = cleanDungeonText(name).trim();
    if (clean.isEmpty) return t('Base', 'Base');
    return clean.length > 14 ? '${clean.substring(0, 13)}...' : clean;
  }

  String combatArmorLabel() {
    final costume = activeCostume;
    if (costume == null) return t('Base', 'Base');
    final name = widget.linguaInglese ? costume.nameEn : costume.nameIt;
    final clean = cleanDungeonText(name).trim();
    if (clean.isEmpty) return t('Base', 'Base');
    return clean.length > 14 ? '${clean.substring(0, 13)}...' : clean;
  }

  String combatSetLabel() {
    final sets = activeEquipmentSets;
    if (sets.isEmpty) return t('Nessuno', 'None');
    final name = cleanDungeonText(
      widget.linguaInglese ? sets.first.nameEn : sets.first.nameIt,
    );
    return name.length > 16 ? '${name.substring(0, 15)}...' : name;
  }

  Widget buildCombatInfoChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        buildCompactChip(
          icon: Icons.flash_on,
          label: 'Arma',
          value: combatWeaponLabel(),
          color: widget.tertiaryColor,
        ),
        buildCompactChip(
          icon: Icons.security,
          label: 'Armatura',
          value: combatArmorLabel(),
          color: widget.tertiaryColor,
        ),
        if (showVictoryChance) buildVictoryChanceChip(),
        buildCompactChip(
          icon: Icons.visibility,
          label: 'Oculum',
          value: '$oculumCharges/$oculumMaxCharges',
          color: widget.primaryColor,
        ),
        buildCompactChip(
          icon: Icons.close,
          label: t('Danno', 'Damage'),
          value: '$totalDamage',
          color: widget.tertiaryColor,
        ),
        buildCompactChip(
          icon: Icons.shield,
          label: t('Difesa', 'Defense'),
          value: '$totalDefense',
          color: Colors.lightBlueAccent,
        ),
        if (selectedSkinId != 'base_oculum')
          buildCompactChip(
            icon: Icons.palette,
            label: 'Skin',
            value: widget.linguaInglese ? activeSkin.nameEn : activeSkin.nameIt,
            color: Colors.purpleAccent,
          ),
        buildCompactChip(
          icon: Icons.health_and_safety,
          label: 'Scudo',
          value: setShieldBonus > 0
              ? '$playerShield +$setShieldBonus'
              : '$playerShield',
          color: Colors.lightBlueAccent,
        ),
        if (activeEquipmentSets.isNotEmpty)
          buildCompactChip(
            icon: Icons.auto_awesome,
            label: 'Set',
            value: combatSetLabel(),
            color: widget.tertiaryColor,
          ),
      ],
    );
  }

  Widget buildEquipmentSetPanel() {
    final sets = activeEquipmentSets;
    if (sets.isEmpty) {
      return const SizedBox.shrink();
    }

    final text = sets
        .take(3)
        .map((set) {
          final name = cleanDungeonText(
            widget.linguaInglese ? set.nameEn : set.nameIt,
          );
          return '$name: +${set.damageBonus} DAN, +${set.defenseBonus} DIF, +${set.shieldBonus} Scudo, +${set.critBonus} Crit';
        })
        .join('\n');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF080910),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.tertiaryColor.withValues(alpha: .38)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: widget.tertiaryColor, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPokemonActionBar() {
    if (!inCombat || gameOver) return const SizedBox.shrink();

    final shortcuts = <Widget>[
      buildActionShortcut(
        label: 'Attacca',
        icon: Icons.close,
        color: widget.tertiaryColor,
        highlighted: true,
        onTap: () => attack(useVc: true),
      ),
      if (reactionAvailable)
        buildActionShortcut(
          label: 'Difenditi',
          icon: Icons.shield,
          color: Colors.lightBlueAccent,
          onTap: useReactionDefense,
        ),
      if (activeArt != null ||
          selectedRunArtIds.isNotEmpty ||
          oculumCharges > 0)
        buildActionShortcut(
          label: 'Art ${maxArtSlotsLabel()}',
          icon: Icons.auto_awesome,
          color: widget.primaryColor,
          onTap: () => selectActionShortcut('art'),
        ),
      if (activeRelic != null)
        buildActionShortcut(
          label: 'Reliquia',
          icon: Icons.blur_on,
          color: const Color(0xFFA78BFA),
          onTap: () => selectActionShortcut('relic'),
        ),
      buildActionShortcut(
        label: 'Achievement e info',
        icon: Icons.menu_book,
        color: Colors.amberAccent,
        onTap: () => selectActionShortcut('info'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = MediaQuery.of(context).size.shortestSide < 600;
        final columns = constraints.maxWidth >= 720
            ? min(6, shortcuts.length)
            : min(3, shortcuts.length);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: compact ? 6 : 8,
          crossAxisSpacing: compact ? 6 : 8,
          childAspectRatio: columns == 6 ? 1.45 : (compact ? 2.35 : 2.1),
          children: shortcuts,
        );
      },
    );
  }

  Widget buildActionShortcut({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    final cleanLabel = cleanDungeonText(label);
    final compact = MediaQuery.of(context).size.shortestSide < 600;

    return InkWell(
      borderRadius: BorderRadius.circular(compact ? 14 : 18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF10121D),
          borderRadius: BorderRadius.circular(compact ? 14 : 18),
          border: Border.all(
            color: highlighted ? color : color.withValues(alpha: 0.45),
            width: highlighted ? 1.8 : 1.1,
          ),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        padding: EdgeInsets.all(compact ? 6 : 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: compact ? 19 : 22),
            SizedBox(height: compact ? 4 : 7),
            Text(
              cleanLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 10 : 11,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String maxArtSlotsLabel() {
    return hasOculianPact && oculumMaxCharges >= 2 ? '3/3' : '2/2';
  }

  void selectActionShortcut(String id) {
    switch (id) {
      case 'attack_actions':
        showAttackShortcutChoices();
        return;
      case 'defense_actions':
        showDefenseShortcutChoices();
        return;
      case 'art':
        showArtShortcutChoices();
        return;
      case 'relic':
        showRelicShortcutChoices();
        return;
      case 'info':
        showInfoShortcutChoices();
        return;
    }

    refreshDungeonUi(() {
      showCombatActions = true;
      showEventChoices = true;

      switch (id) {
        case 'attack':
          choicePanelMode = 'attack';
          addLog(t('Shortcut: Attacca.', 'Shortcut: Attack.'));
          break;
        case 'attack_actions':
          choicePanelMode = 'attack';
          addLog(t('Aperte azioni attacco.', 'Attack actions opened.'));
          break;
        case 'defend':
          choicePanelMode = 'defense';
          addLog(t('Shortcut: Difenditi.', 'Shortcut: Defend.'));
          break;
        case 'defense_actions':
          choicePanelMode = 'defense';
          addLog(t('Aperte azioni difesa.', 'Defense actions opened.'));
          break;
      }
    });
  }

  // =====================================================
  // SKIN
  // =====================================================

  Widget buildSkinCodexPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF090B13),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.primaryColor.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              buildOculumAssetIcon(size: 20, dotted: false),
              const SizedBox(width: 8),
              Text(
                'SKIN',
                style: TextStyle(
                  color: widget.primaryColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 126,
            child: Scrollbar(
              controller: _skinCodexScrollController,
              thumbVisibility: false,
              child: ListView.separated(
                controller: _skinCodexScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 18),
                itemCount: _allSkins.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return buildSkinCard(_allSkins[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSkinCard(_DungeonSkin skin) {
    final unlocked =
        unlockedSkinIds.contains(skin.id) ||
        (skin.unlockAchievementId != null &&
            completedAchievementIds.contains(skin.unlockAchievementId)) ||
        (skin.unlockKillKey != null &&
            (skinKillCounts[skin.unlockKillKey!] ?? 0) >= skin.unlockKillGoal);
    final selected = selectedSkinId == skin.id;
    final killProgress = skin.unlockKillKey == null
        ? 0
        : (skinKillCounts[skin.unlockKillKey!] ?? 0).clamp(
            0,
            skin.unlockKillGoal,
          );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: unlocked
          ? () {
              refreshDungeonUi(() {
                unlockedSkinIds.add(skin.id);
                selectedSkinId = skin.id;
              });
              _savePermanentProgress();
            }
          : null,
      child: Container(
        width: 102,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF10131E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? widget.primaryColor
                : unlocked
                ? widget.primaryColor.withValues(alpha: 0.35)
                : widget.tertiaryColor.withValues(alpha: 0.45),
            width: selected ? 1.8 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              t(skin.nameIt, skin.nameEn),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unlocked ? Colors.white : widget.tertiaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: unlocked ? 1 : 0.35,
                    child: SizedBox.square(
                      dimension: 54,
                      child: dungeonSpriteArt(
                        color: skin.primaryColor,
                        seed: skin.id.hashCode,
                        kind: skin.spriteKind,
                        eyeColor: skin.eyeColor,
                        layers: skin.spriteKind == 'legendary_eye_knight'
                            ? 1
                            : 0,
                        flip: false,
                        assetPath: _skinDungeonSpriteAsset(skin),
                      ),
                    ),
                  ),
                  if (!unlocked)
                    Icon(Icons.lock, color: widget.tertiaryColor, size: 25),
                ],
              ),
            ),
            if (skin.hideEquipment)
              Text(
                'Equip. nascosti',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              )
            else if (skin.monsterSkin && !unlocked)
              Text(
                '$killProgress/${skin.unlockKillGoal} kill',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.tertiaryColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              )
            else if (!unlocked)
              Text(
                'Achievement',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.tertiaryColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              )
            else
              const SizedBox(height: 11),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // OCCHI CANVA COME ASSET
  // =====================================================

  Widget buildOculumAssetIcon({double size = 24, bool dotted = false}) {
    if (dotted) {
      return SizedBox.square(
        dimension: size,
        child: CustomPaint(
          isComplex: true,
          willChange: false,
          painter: const _OculumSpritePainter(
            color: Color(0xFFEDEDED),
            seed: 3307,
            kind: 'dotted_eye',
            eyeColor: Color(0xFF050505),
          ),
        ),
      );
    }

    return Image.asset(
      'assets/oculum/sprites/Occhio_della_Reliquia.png',
      width: size,
      height: size,
      cacheWidth: rasterCacheDimension(size, max: 192),
      cacheHeight: rasterCacheDimension(size, max: 192),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.visibility,
          size: size,
          color: dotted ? Colors.white : widget.primaryColor,
        );
      },
    );
  }

  Widget buildNullFatelessInfoChip() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF080910),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          buildOculumAssetIcon(size: 24, dotted: true),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Null/Fateless: mini-boss molto forte. Se ti ferisce, il Fato non ricorda.',
              style: TextStyle(
                color: Colors.grey.shade200,
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // NULL/FATELESS
  // =====================================================

  // ignore: unused_element
  _EnemyInstance makeNullFatelessMiniBoss({
    required int floor,
    required int grade,
  }) {
    currentFightHasNullFateless = true;
    playerWoundedByNullFateless = false;

    final power = 80 + floor * 16 + grade * 35;
    final hp = power * 2;
    final attack = 18 + floor * 3 + grade * 6;
    final defense = 10 + floor * 2 + grade * 4;

    return _EnemyInstance(
      nameIt: 'Null/Fateless',
      nameEn: 'Null/Fateless',
      elementId: 'nullum',
      hp: hp,
      maxHp: hp,
      attack: attack,
      defense: defense,
      boss: false,
      elite: true,
      fetal: false,
      level: (floor + grade + 2).clamp(1, 999).toInt(),
      grade: grade + 1,
      originalPower: hp ~/ 9 + attack * 3 + defense * 2,
    );
  }

  void markNullFatelessWound(_EnemyInstance enemy, int damageTaken) {
    if (damageTaken <= 0) return;

    final isNullFateless =
        enemy.nameIt == 'Null/Fateless' ||
        enemy.nameEn == 'Null/Fateless' ||
        enemy.elementId == 'nullum';

    if (isNullFateless) {
      playerWoundedByNullFateless = true;
    }
  }

  void resolveEndFightSpecialMessages() {
    if (currentFightHasNullFateless && playerWoundedByNullFateless) {
      addLog('ti senti ferito, non ricordi da cosa');

      textIt = '${textIt.trim()}\n\nti senti ferito, non ricordi da cosa';
      textEn =
          '${textEn.trim()}\n\nyou feel wounded, but you do not remember by what';

      unlockedSkinIds.add('null_fateless');
      completedAchievementIds.add('survive_null_fateless');

      _savePermanentProgress();
    }

    currentFightHasNullFateless = false;
    playerWoundedByNullFateless = false;
  }

  // =====================================================
  // QUICK SETTINGS
  // =====================================================

  Widget buildQuickSettingsButton() {
    return IconButton(
      tooltip: 'Impostazioni rapide',
      icon: Icon(Icons.settings, color: widget.tertiaryColor, size: 20),
      onPressed: openQuickSettings,
    );
  }

  void openQuickSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF090B13),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            Widget toggle(
              String label,
              bool value,
              ValueChanged<bool> onChanged,
            ) {
              return SwitchListTile(
                value: value,
                onChanged: (next) {
                  modalSetState(() => onChanged(next));
                  refreshDungeonUi();
                },
                title: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                activeThumbColor: widget.primaryColor,
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: widget.tertiaryColor),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Impostazioni rapide UI',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    toggle(
                      'Icone rapide superiori',
                      showTopQuickIcons,
                      (v) => showTopQuickIcons = v,
                    ),
                    toggle(
                      'Skin',
                      showSkinCodexPanel,
                      (v) => showSkinCodexPanel = v,
                    ),
                    toggle(
                      'Pannello Null/Fateless',
                      showInfoEnemyPanel,
                      (v) => showInfoEnemyPanel = v,
                    ),
                    toggle(
                      'Log inferiore',
                      showBottomLog,
                      (v) => showBottomLog = v,
                    ),
                    toggle(
                      'Probabilità vittoria',
                      showVictoryChance,
                      (v) => showVictoryChance = v,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =====================================================
  // BLOCCO UI DEFINITIVO
  // =====================================================

  Widget buildDefinitiveCombatAddon() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final children = <Widget>[];

        if (inCombat && !gameOver) {
          children.add(buildPokemonActionBar());
        }

        final infoPanels = <Widget>[];
        if (showSkinCodexPanel) {
          infoPanels.add(buildSkinCodexPanel());
        }
        if (showInfoEnemyPanel && currentFightHasNullFateless) {
          infoPanels.add(buildNullFatelessInfoChip());
        }

        final detailChildren = <Widget>[
          buildCombatInfoChips(),
          if (activeEquipmentSets.isNotEmpty) ...[
            const SizedBox(height: 10),
            buildEquipmentSetPanel(),
          ],
        ];

        if (infoPanels.isNotEmpty) {
          detailChildren.add(const SizedBox(height: 10));
          if (wide && infoPanels.length > 1) {
            detailChildren.add(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: infoPanels[0]),
                  const SizedBox(width: 10),
                  Expanded(child: infoPanels[1]),
                ],
              ),
            );
          } else {
            for (var i = 0; i < infoPanels.length; i++) {
              if (i > 0) detailChildren.add(const SizedBox(height: 10));
              detailChildren.add(infoPanels[i]);
            }
          }
        }

        if (children.isNotEmpty) {
          children.add(const SizedBox(height: 10));
        }
        children.add(
          collapsiblePanel(
            title: t('Dettagli fight', 'Fight details'),
            icon: Icons.tune,
            expanded: showCombatHudDetails,
            trailing: showCombatHudDetails ? 'ON' : 'OFF',
            color: widget.tertiaryColor,
            onTap: toggleCombatHudDetails,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: detailChildren,
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
}
